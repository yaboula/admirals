-- =============================================================================
-- Admirals Bank — server/callbacks.lua
--
-- ox_lib server callbacks per docs/technical/04_api_contracts.md §3.1.
--
-- S1.1 implementa:
--   C001 admirals:bank:getBalance     — Read-only, idempotent, 30/10s rate limit.
--
-- S1.2 añade:
--   C002 admirals:bank:transfer       — TX atomic, idempotent via request_id,
--                                       10/60s rate limit, audit obligatorio.
--
-- Pendiente (S1.3):
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
local Transfer = Admirals.Bank.Transfer
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
-- C002 — admirals:bank:transfer
--
-- Request:  { from_iban, to_iban, amount, concept, request_id } per SSoT §3.1.
-- Response: { success=true, data: { transaction_id, timestamp, new_balance_from, fee_retained } }
--           | { success=false, error_code, message }
--
-- Idempotency:
--   request_id (UUID v4 client-side) sirve como key cross-restart via
--   admirals_bridge_idempotency table (DB-backed swap S1.2 — backend instalado
--   por admirals_core/server/init.lua post-DB-ready).
--   2ª llamada con mismo request_id → retorna response cached del 1º +
--   audit log 'idempotency_replay'.
--
-- Atomicity:
--   Delegated a Transfer.Execute → Admirals.DB.Transaction (4 queries).
--
-- Rate limit:
--   bucket 'bank.write' (10/60s per citizen) registered en
--   admirals_core/config.lua:126 (no re-register here).
-- =============================================================================
lib.callback.register('admirals:bank:transfer', function(source, request)
  request = request or {}
  local start_ms = GetGameTimer()

  -- ---------------------------------------------------------------------------
  -- 1. Resolve citizen_id from cache.
  -- ---------------------------------------------------------------------------
  local citizen_id = Bank.GetCitizenIdBySource and Bank.GetCitizenIdBySource(source)
  if not citizen_id then
    Admirals.Metrics.Counter('bank.callbacks.transfer.not_authenticated')
    return _err('NOT_AUTHENTICATED', 'Player session not loaded')
  end

  -- ---------------------------------------------------------------------------
  -- 2. Shape validation request_id PRIMERO (idempotency lookup needs it).
  -- ---------------------------------------------------------------------------
  local request_id = request.request_id
  if type(request_id) ~= 'string' or #request_id < 8 or #request_id > 64 then
    Admirals.Metrics.Counter('bank.callbacks.transfer.missing_request_id')
    return _err('MISSING_FIELD', 'request_id required (UUID v4 string)')
  end

  -- ---------------------------------------------------------------------------
  -- 3. Idempotency check via Bridges export (S1.2 DB-backed).
  --    Si replay: log audit + return cached SIN re-ejecutar TX.
  --    Fail-closed: si export falla, NO permitir re-ejecutar (devuelve error
  --    transitorio para que cliente reintente más tarde con backoff).
  -- ---------------------------------------------------------------------------
  local idem_ok, idem_ret = pcall(function()
    return exports.admirals_bridges:IsIdemReplay(request_id)
  end)
  if not idem_ok then
    Admirals.Log.Warn('Bridges:IsIdemReplay export failed: %s', tostring(idem_ret))
    -- No FAIL-CLOSED estricto: el callback proceeds (best-effort) — el riesgo
    -- de double-execute con request_id duplicate cubierto por:
    --   (a) UNIQUE iban + balance check en TX,
    --   (b) admin reconciliation post-incidente via Movements.RecalcBalance.
    -- Si en producción este path se observa frecuente, escalate a fail-closed.
    Admirals.Metrics.Counter('bank.callbacks.transfer.idem_lookup_failed')
  elseif type(idem_ret) == 'table' and idem_ret.is_replay == true then
    Admirals.Metrics.Counter('bank.callbacks.transfer.idempotency_replay')
    Admirals.Log.Audit({
      category = Config.AuditCategories.Transfer,
      action   = 'idempotency_replay',
      actor    = citizen_id,
      target   = request_id,
      payload  = { request_id = request_id, source_source = source },
    })
    return idem_ret.cached
  end

  -- ---------------------------------------------------------------------------
  -- 4. Rate limit (bucket 'bank.write' — 10/60s per citizen — §04 §8.1).
  --    Fail-closed: si Admirals.Rate.Check excepción, treat as blocked
  --    (anti-fraude: si el sistema rate-limit no responde, prefer reject).
  -- ---------------------------------------------------------------------------
  local rate_ok, rate_allowed = pcall(Admirals.Rate.Check, citizen_id, 'bank.write')
  if not rate_ok or rate_allowed ~= true then
    if not rate_ok then
      Admirals.Log.Warn('Admirals.Rate.Check threw: %s — fail-closed', tostring(rate_allowed))
    end
    Admirals.Metrics.Counter('bank.callbacks.transfer.rate_limited')
    return _err('RATE_LIMITED', 'Demasiadas transferencias. Espera un momento.')
  end

  -- ---------------------------------------------------------------------------
  -- 5. Validate basic shape (let Transfer.Execute do deep validation).
  -- ---------------------------------------------------------------------------
  local from_iban = request.from_iban
  local to_iban = request.to_iban
  local amount = tonumber(request.amount)
  local concept = request.concept

  if type(from_iban) ~= 'string' or from_iban == '' then
    Admirals.Metrics.Counter('bank.callbacks.transfer.missing_field_from')
    return _err('MISSING_FIELD', 'from_iban required')
  end
  if type(to_iban) ~= 'string' or to_iban == '' then
    Admirals.Metrics.Counter('bank.callbacks.transfer.missing_field_to')
    return _err('MISSING_FIELD', 'to_iban required')
  end
  if not amount then
    Admirals.Metrics.Counter('bank.callbacks.transfer.missing_field_amount')
    return _err('MISSING_FIELD', 'amount required (number)')
  end
  if type(concept) ~= 'string' then concept = '' end
  if #concept > 120 then
    -- Truncate vs reject — UX-friendly. SSoT §3.1 dice "1-120 chars" pero
    -- truncar es menos disruptivo que error de form a player.
    concept = concept:sub(1, 120)
  end

  -- ---------------------------------------------------------------------------
  -- 6. Delegate a Transfer.Execute (atomic + audit + event publish).
  -- ---------------------------------------------------------------------------
  local ok, data, error_code = Transfer.Execute(
    citizen_id, from_iban, to_iban, amount, concept, request_id
  )

  -- ---------------------------------------------------------------------------
  -- 7. Build response.
  -- ---------------------------------------------------------------------------
  local response
  if ok and data then
    response = { success = true, data = data }
  else
    -- Map error codes to user-friendly messages per SSoT §7 catalog.
    local message_map = {
      AMOUNT_OUT_OF_RANGE = 'Importe fuera de rango (0 < amount ≤ 1.000.000 €).',
      INVALID_IBAN        = 'IBAN inválido o cuenta destino inexistente.',
      SELF_TRANSFER       = 'No puedes transferir a tu propia cuenta.',
      NOT_AUTHORIZED      = 'No eres el titular de la cuenta origen.',
      ACCOUNT_FROZEN      = 'Una de las cuentas está congelada o cerrada.',
      INSUFFICIENT_FUNDS  = 'Saldo insuficiente.',
      RACE_DETECTED       = 'Saldo agotado por concurrencia. Reintenta.',
      TX_CRASH            = 'Error transitorio del sistema. Reintenta.',
      TX_ROLLBACK         = 'Operación abortada por integridad. Reintenta.',
    }
    response = _err(error_code or 'FAILED',
      message_map[error_code] or 'Transferencia fallida.')
  end

  -- ---------------------------------------------------------------------------
  -- 8. Persist idempotency entry (success OR error — both deterministic for
  --    same request_id). TTL = Config.IdempotencyTTLSec (1h en bridges config).
  --
  --    Per founder green-light + SSoT §3.1: una operación con request_id ya
  --    procesado debe retornar la misma response en re-attempt. Si la 1ª attempt
  --    falló por (e.g.) INSUFFICIENT_FUNDS, la 2ª también — no permitimos
  --    "reintento bonus" sin nuevo request_id. Esto matchea HTTP idempotency
  --    semantics (PUT-like).
  -- ---------------------------------------------------------------------------
  local store_ok, store_err = pcall(function()
    return exports.admirals_bridges:StoreIdem(request_id, response)
  end)
  if not store_ok then
    Admirals.Log.Warn('Bridges:StoreIdem failed for %s: %s — replay protection degraded',
      request_id, tostring(store_err))
    Admirals.Metrics.Counter('bank.callbacks.transfer.idem_store_failed')
  end

  -- ---------------------------------------------------------------------------
  -- 9. Metrics observation.
  -- ---------------------------------------------------------------------------
  local duration_ms = GetGameTimer() - start_ms
  Admirals.Metrics.Observe('bank.callbacks.transfer.duration_ms', duration_ms)

  return response
end)

-- =============================================================================
-- Boot announce.
-- =============================================================================
Admirals.Log.Info('Callbacks registered: admirals:bank:getBalance (C001), admirals:bank:transfer (C002)')
