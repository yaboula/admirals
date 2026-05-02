-- =============================================================================
-- Admirals Bank — server/callbacks.lua
--
-- ox_lib server callbacks per docs/technical/04_api_contracts.md §3.1.
--
-- S1.1 implementa:
--   C001 admirals:bank:getBalance     — Read-only, idempotent, 30/10s rate limit.
--
-- Pendiente (S1.2 / S1.3):
--   C002 admirals:bank:transfer
--   C003 admirals:bank:getTransactions
--   C004 admirals:bank:createEscrow
--   C005 admirals:bank:releaseEscrow
--
-- Convention de respuesta (SSoT §04 §3 introducción):
--   Success: { success=true, data={ ... } }
--   Error:   { success=false, error_code='CODE', message='human readable' }
--
-- Resolución source → citizenId:
--   admirals_bridges no exporta GetCitizenId cross-resource. Mantenemos cache
--   local _src_to_cid populated en init.lua via Admirals.Identity.OnPlayerLoaded.
--   Bank.GetCitizenIdBySource() lee de ese cache (o nil si player no loaded).
--
-- Authorization (S1.1 personal-only):
--   - Personal IBAN: source.citizen_id debe matchear admirals_accounts.id que
--     es owner_account_id del IBAN.
--   - Company / cooperative / escrow: REJECTED en S1.1 (S2+ resolverá vía
--     admirals_company_members membership check).
--
-- Referencias SSoT:
--   docs/technical/04_api_contracts.md §3.1 C001 (getBalance signature).
--   docs/technical/04_api_contracts.md §3 intro (response convention).
--   docs/technical/04_api_contracts.md §7 (error codes catalog — pending).
--   docs/technical/04_api_contracts.md §8.1 (rate limits).
--   docs/technical/04_api_contracts.md §10.3 (audit logging obligatorio).
-- =============================================================================

Admirals = Admirals or {}
Admirals.Bank = Admirals.Bank or {}
Admirals.Bank.Callbacks = Admirals.Bank.Callbacks or {}

local Config = Admirals.Bank.Config
local IBAN = Admirals.Bank.IBAN
local Accounts = Admirals.Bank.Accounts
local Bank = Admirals.Bank
local Callbacks = Admirals.Bank.Callbacks

-- =============================================================================
-- Internal — error response helper.
-- =============================================================================
local function _err(code, message)
  return { success = false, error_code = code, message = message }
end

-- =============================================================================
-- Internal — tier mapping per SSoT §3.1 response shape.
-- DB ENUM (4 values) → response tier (2 values).
-- =============================================================================
local function _tier_from_type(type_str)
  if type_str == 'personal' then return 'personal' end
  return 'empresa'  -- company / cooperative / escrow → empresa canonical
end

-- =============================================================================
-- C001 — admirals:bank:getBalance
--
-- Request:  { iban?: string }   — opcional; default = IBAN personal del source.
-- Response: { success, data: { iban, balance, currency='EUR', tier, last_updated } }
--           | { success=false, error_code, message }
--
-- Rate limit: bucket 'bank.read' (30/10s) ya registered en
--             admirals_core/config.lua:122-126 (no re-register here).
-- =============================================================================
lib.callback.register('admirals:bank:getBalance', function(source, request)
  request = request or {}
  local start_ms = GetGameTimer()

  -- ---------------------------------------------------------------------------
  -- 1. Resolve citizen_id desde source via cache populated en init.lua.
  -- ---------------------------------------------------------------------------
  local citizen_id = Bank.GetCitizenIdBySource and Bank.GetCitizenIdBySource(source)
  if not citizen_id then
    Admirals.Metrics.Counter('bank.callbacks.get_balance.not_authenticated')
    return _err('NOT_AUTHENTICATED', 'Player session not loaded')
  end

  -- ---------------------------------------------------------------------------
  -- 2. Rate limit (bucket 'bank.read' = 30 calls/10s per citizen — §04 §8.1).
  -- ---------------------------------------------------------------------------
  if not Admirals.Rate.Check(citizen_id, 'bank.read') then
    Admirals.Metrics.Counter('bank.callbacks.get_balance.rate_limited')
    return _err('RATE_LIMITED', 'Too many requests, slow down')
  end

  -- ---------------------------------------------------------------------------
  -- 3. Resolve target row (request.iban or default personal).
  -- ---------------------------------------------------------------------------
  local target_iban = request.iban
  local target_row

  if type(target_iban) == 'string' and target_iban ~= '' then
    -- IBAN provided — validate format (defense-in-depth, evita SQL probe vía
    -- IBANs random).
    local ok_v, err_v = IBAN.Validate(target_iban)
    if not ok_v then
      -- Permitir RESERVED_PREFIX solo si admin (no implementado S1.1 → reject).
      Admirals.Metrics.Counter('bank.callbacks.get_balance.invalid_iban')
      return _err('INVALID_IBAN', err_v or 'IBAN format invalid')
    end

    target_row = Accounts.GetByIban(target_iban)
    if not target_row then
      Admirals.Metrics.Counter('bank.callbacks.get_balance.iban_not_found')
      return _err('INVALID_IBAN', 'IBAN not found')
    end
  else
    -- Default a IBAN personal del source player.
    if not Config.GetBalanceDefaultPersonalIban then
      Admirals.Metrics.Counter('bank.callbacks.get_balance.iban_required')
      return _err('IBAN_REQUIRED', 'iban field is required')
    end

    target_row = Accounts.GetPersonalByCitizenId(citizen_id)
    if not target_row then
      Admirals.Metrics.Counter('bank.callbacks.get_balance.no_account')
      return _err('NO_ACCOUNT', 'No personal account exists for this player')
    end
  end

  -- ---------------------------------------------------------------------------
  -- 4. Authorization.
  --    Personal: source.citizen_id maps to admirals_accounts.id == owner_account_id.
  --    Otros tipos (company/coop/escrow): rejected en S1.1.
  -- ---------------------------------------------------------------------------
  local authorized = false
  if target_row.type == 'personal' then
    local caller_account_id = Accounts.GetAccountIdByCitizenId(citizen_id)
    authorized = (caller_account_id ~= nil)
              and (target_row.owner_account_id == caller_account_id)
  else
    -- S2+: check membership via admirals_company_members.
    authorized = false
  end

  if not authorized then
    Admirals.Metrics.Counter('bank.callbacks.get_balance.unauthorized')
    Admirals.Log.Warn('getBalance unauthorized: citizen=%s requested iban=%s (type=%s)',
      citizen_id, target_row.iban, target_row.type)
    return _err('NOT_AUTHORIZED', 'You are not the owner of this account')
  end

  -- ---------------------------------------------------------------------------
  -- 5. Optional audit (Config.AuditReads — default false: muy ruidoso).
  -- ---------------------------------------------------------------------------
  if Config.AuditReads then
    Admirals.Log.Audit({
      category = Config.AuditCategories.BalanceRead,
      action = 'read',
      actor = citizen_id,
      target = target_row.id,
      payload = { iban = target_row.iban },
    })
  end

  -- ---------------------------------------------------------------------------
  -- 6. Compose response per SSoT §3.1 shape canónico.
  -- ---------------------------------------------------------------------------
  local duration_ms = GetGameTimer() - start_ms
  Admirals.Metrics.Counter('bank.callbacks.get_balance.ok')
  Admirals.Metrics.Observe('bank.callbacks.get_balance.duration_ms', duration_ms)

  return {
    success = true,
    data = {
      iban = target_row.iban,
      balance = tonumber(target_row.balance) or 0.0,
      currency = 'EUR',
      tier = _tier_from_type(target_row.type),
      last_updated = (tonumber(target_row.updated_at) or 0) * 1000,  -- ms per §3.1
    },
  }
end)

-- =============================================================================
-- Boot announce.
-- =============================================================================
Admirals.Log.Info('Callbacks registered: admirals:bank:getBalance (C001)')
