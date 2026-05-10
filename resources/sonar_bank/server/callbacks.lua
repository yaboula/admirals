-- =============================================================================
-- SONAR Bank — server/callbacks.lua
--
-- ox_lib server callbacks per docs/technical/04_api_contracts.md §3.1.
--
-- S1.1 implementa:
--   C001 sonar:bank:getBalance     — Read-only, idempotent, 30/10s rate limit.
--
-- S1.2 añade:
--   C002 sonar:bank:transfer       — TX atomic, idempotent via request_id,
--                                    10/60s rate limit, audit obligatorio.
--
-- S1.3 añade:
--   C003 sonar:bank:getTransactions
--   C004 sonar:bank:createEscrow
--   C005 sonar:bank:releaseEscrow
--
-- Convention de respuesta (SSoT §04 §3 introducción):
--   Success: { success=true, data={ ... } }
--   Error:   { success=false, error_code='CODE', message='human readable' }
--
-- Resolución source → citizenId:
--   sonar_bridges no exporta GetCitizenId cross-resource. Mantenemos cache
--   local _src_to_cid populated en init.lua via SONAR.Identity.OnPlayerLoaded.
--   Bank.GetCitizenIdBySource() lee de ese cache (o nil si player no loaded).
--
-- Authorization (S1.1 personal-only):
--   - Personal IBAN: source.citizen_id debe matchear sonar_accounts.id que
--     es owner_account_id del IBAN.
--   - Company / cooperative / escrow: REJECTED en S1.1 (S2+ resolverá vía
--     sonar_company_members membership check).
--
-- Referencias SSoT:
--   docs/technical/04_api_contracts.md §3.1 C001 (getBalance signature).
--   docs/technical/04_api_contracts.md §3 intro (response convention).
--   docs/technical/04_api_contracts.md §7 (error codes catalog — pending).
--   docs/technical/04_api_contracts.md §8.1 (rate limits).
--   docs/technical/04_api_contracts.md §10.3 (audit logging obligatorio).
-- =============================================================================

SONAR = SONAR or {}
SONAR.Bank = SONAR.Bank or {}
SONAR.Bank.Callbacks = SONAR.Bank.Callbacks or {}

local Config = SONAR.Bank.Config
local IBAN = SONAR.Bank.IBAN
local Accounts = SONAR.Bank.Accounts
local Transfer = SONAR.Bank.Transfer
local Escrow = SONAR.Bank.Escrow
local Bank = SONAR.Bank
local Callbacks = SONAR.Bank.Callbacks

local function register_callback(name, fn)
  if _G.lib and _G.lib.callback and type(_G.lib.callback.register) == 'function' then
    _G.lib.callback.register(name, fn)
    return true
  end
  RegisterNetEvent(name, function(payload, response_event)
    local src = source
    local response = fn(src, payload)
    if response_event then
      TriggerClientEvent(response_event, src, response)
    end
  end)
  return false
end

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
-- C001 — sonar:bank:getBalance
--
-- Request:  { iban?: string }   — opcional; default = IBAN personal del source.
-- Response: { success, data: { iban, balance, currency='EUR', tier, last_updated } }
--           | { success=false, error_code, message }
--
-- Rate limit: bucket 'bank.read' (30/10s) ya registered en
--             sonar_core/config.lua:122-126 (no re-register here).
-- =============================================================================
register_callback('sonar:bank:getBalance', function(source, request)
  request = request or {}
  local start_ms = GetGameTimer()

  -- ---------------------------------------------------------------------------
  -- 1. Resolve citizen_id desde source via cache populated en init.lua.
  -- ---------------------------------------------------------------------------
  local citizen_id = Bank.GetCitizenIdBySource and Bank.GetCitizenIdBySource(source)
  if not citizen_id then
    SONAR.Metrics.Counter('bank.callbacks.get_balance.not_authenticated')
    return _err('NOT_AUTHENTICATED', 'Player session not loaded')
  end

  -- ---------------------------------------------------------------------------
  -- 2. Rate limit (bucket 'bank.read' = 30 calls/10s per citizen — §04 §8.1).
  -- ---------------------------------------------------------------------------
  if not SONAR.Rate.Check(citizen_id, 'bank.read') then
    SONAR.Metrics.Counter('bank.callbacks.get_balance.rate_limited')
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
      SONAR.Metrics.Counter('bank.callbacks.get_balance.invalid_iban')
      return _err('INVALID_IBAN', err_v or 'IBAN format invalid')
    end

    target_row = Accounts.GetByIban(target_iban)
    if not target_row then
      SONAR.Metrics.Counter('bank.callbacks.get_balance.iban_not_found')
      return _err('INVALID_IBAN', 'IBAN not found')
    end
  else
    -- Default a IBAN personal del source player.
    if not Config.GetBalanceDefaultPersonalIban then
      SONAR.Metrics.Counter('bank.callbacks.get_balance.iban_required')
      return _err('IBAN_REQUIRED', 'iban field is required')
    end

    target_row = Accounts.GetPersonalByCitizenId(citizen_id)
    if not target_row then
      SONAR.Metrics.Counter('bank.callbacks.get_balance.no_account')
      return _err('NO_ACCOUNT', 'No personal account exists for this player')
    end
  end

  -- ---------------------------------------------------------------------------
  -- 4. Authorization.
  --    Personal: source.citizen_id maps to sonar_accounts.id == owner_account_id.
  --    Otros tipos (company/coop/escrow): rejected en S1.1.
  -- ---------------------------------------------------------------------------
  local authorized = false
  if target_row.type == 'personal' then
    local caller_account_id = Accounts.GetAccountIdByCitizenId(citizen_id)
    authorized = (caller_account_id ~= nil)
              and (target_row.owner_account_id == caller_account_id)
  else
    -- S2+: check membership via sonar_company_members.
    authorized = false
  end

  if not authorized then
    SONAR.Metrics.Counter('bank.callbacks.get_balance.unauthorized')
    SONAR.Log.Warn('getBalance unauthorized: citizen=%s requested iban=%s (type=%s)',
      citizen_id, target_row.iban, target_row.type)
    return _err('NOT_AUTHORIZED', 'You are not the owner of this account')
  end

  -- ---------------------------------------------------------------------------
  -- 5. Optional audit (Config.AuditReads — default false: muy ruidoso).
  -- ---------------------------------------------------------------------------
  if Config.AuditReads then
    SONAR.Log.Audit({
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
  SONAR.Metrics.Counter('bank.callbacks.get_balance.ok')
  SONAR.Metrics.Observe('bank.callbacks.get_balance.duration_ms', duration_ms)

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
-- C002 — sonar:bank:transfer
--
-- Request:  { from_iban, to_iban, amount, concept, request_id } per SSoT §3.1.
-- Response: { success=true, data: { transaction_id, timestamp, new_balance_from, fee_retained } }
--           | { success=false, error_code, message }
--
-- Idempotency:
--   request_id (UUID v4 client-side) sirve como key cross-restart via
--   sonar_bridge_idempotency table (DB-backed swap S1.2 — backend instalado
--   por sonar_core/server/init.lua post-DB-ready).
--   2ª llamada con mismo request_id → retorna response cached del 1º +
--   audit log 'idempotency_replay'.
--
-- Atomicity:
--   Delegated a Transfer.Execute → SONAR.DB.Transaction (4 queries).
--
-- Rate limit:
--   bucket 'bank.write' (10/60s per citizen) registered en
--   sonar_core/config.lua:126 (no re-register here).
-- =============================================================================
register_callback('sonar:bank:transfer', function(source, request)
  request = request or {}
  local start_ms = GetGameTimer()

  -- ---------------------------------------------------------------------------
  -- 1. Resolve citizen_id from cache.
  -- ---------------------------------------------------------------------------
  local citizen_id = Bank.GetCitizenIdBySource and Bank.GetCitizenIdBySource(source)
  if not citizen_id then
    SONAR.Metrics.Counter('bank.callbacks.transfer.not_authenticated')
    return _err('NOT_AUTHENTICATED', 'Player session not loaded')
  end

  -- ---------------------------------------------------------------------------
  -- 2. Shape validation request_id PRIMERO (idempotency lookup needs it).
  -- ---------------------------------------------------------------------------
  local request_id = request.request_id
  if type(request_id) ~= 'string' or #request_id < 8 or #request_id > 64 then
    SONAR.Metrics.Counter('bank.callbacks.transfer.missing_request_id')
    return _err('MISSING_FIELD', 'request_id required (UUID v4 string)')
  end

  -- ---------------------------------------------------------------------------
  -- 3. Idempotency check via Bridges export (S1.2 DB-backed).
  --    Si replay: log audit + return cached SIN re-ejecutar TX.
  --    Fail-closed: si export falla, NO permitir re-ejecutar (devuelve error
  --    transitorio para que cliente reintente más tarde con backoff).
  -- ---------------------------------------------------------------------------
  local idem_ok, idem_ret = pcall(function()
    return exports.sonar_bridges:IsIdemReplay(request_id)
  end)
  if not idem_ok then
    SONAR.Log.Warn('Bridges:IsIdemReplay export failed: %s', tostring(idem_ret))
    -- No FAIL-CLOSED estricto: el callback proceeds (best-effort) — el riesgo
    -- de double-execute con request_id duplicate cubierto por:
    --   (a) UNIQUE iban + balance check en TX,
    --   (b) admin reconciliation post-incidente via Movements.RecalcBalance.
    -- Si en producción este path se observa frecuente, escalate a fail-closed.
    SONAR.Metrics.Counter('bank.callbacks.transfer.idem_lookup_failed')
  elseif type(idem_ret) == 'table' and idem_ret.is_replay == true then
    SONAR.Metrics.Counter('bank.callbacks.transfer.idempotency_replay')
    SONAR.Log.Audit({
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
  --    Fail-closed: si SONAR.Rate.Check excepción, treat as blocked
  --    (anti-fraude: si el sistema rate-limit no responde, prefer reject).
  -- ---------------------------------------------------------------------------
  local rate_ok, rate_allowed = pcall(SONAR.Rate.Check, citizen_id, 'bank.write')
  if not rate_ok or rate_allowed ~= true then
    if not rate_ok then
      SONAR.Log.Warn('SONAR.Rate.Check threw: %s — fail-closed', tostring(rate_allowed))
    end
    SONAR.Metrics.Counter('bank.callbacks.transfer.rate_limited')
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
    SONAR.Metrics.Counter('bank.callbacks.transfer.missing_field_from')
    return _err('MISSING_FIELD', 'from_iban required')
  end
  if type(to_iban) ~= 'string' or to_iban == '' then
    SONAR.Metrics.Counter('bank.callbacks.transfer.missing_field_to')
    return _err('MISSING_FIELD', 'to_iban required')
  end
  if not amount then
    SONAR.Metrics.Counter('bank.callbacks.transfer.missing_field_amount')
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
    return exports.sonar_bridges:StoreIdem(request_id, response)
  end)
  if not store_ok then
    SONAR.Log.Warn('Bridges:StoreIdem failed for %s: %s — replay protection degraded',
      request_id, tostring(store_err))
    SONAR.Metrics.Counter('bank.callbacks.transfer.idem_store_failed')
  end

  -- ---------------------------------------------------------------------------
  -- 9. Metrics observation.
  -- ---------------------------------------------------------------------------
  local duration_ms = GetGameTimer() - start_ms
  SONAR.Metrics.Observe('bank.callbacks.transfer.duration_ms', duration_ms)

  return response
end)

-- =============================================================================
-- C003 reserved for sonar:bank:getTransactions (S2+ — Tablet history view per §3.1).
-- =============================================================================

-- =============================================================================
-- C004 — sonar:bank:createEscrow
--
-- Request (per SSoT §3.1 C004):
--   { buyer_iban, seller_iban, amount, contract_id?, release_condition,
--     release_date?, request_id }
-- Response (success): { success, data: { escrow_id, fee_charged, expires_at } }
-- Error codes per SSoT §7 + S1.3 extensions.
--
-- Authorization: only buyer (caller citizen_id === owner_account_id of buyer_iban).
-- Rate limit: bucket 'bank.write' (10/60s) — same as C002 (registered en
-- sonar_core/config.lua:126).
-- Idempotency: request_id via Bridges DB-backed sonar_bridge_idempotency table.
-- =============================================================================
register_callback('sonar:bank:createEscrow', function(source, request)
  request = request or {}
  local start_ms = GetGameTimer()

  -- 1. Resolve citizen_id from cache.
  local citizen_id = Bank.GetCitizenIdBySource and Bank.GetCitizenIdBySource(source)
  if not citizen_id then
    SONAR.Metrics.Counter('bank.callbacks.create_escrow.not_authenticated')
    return _err('NOT_AUTHENTICATED', 'Player session not loaded')
  end

  -- 2. Shape validation request_id first.
  local request_id = request.request_id
  if type(request_id) ~= 'string' or #request_id < 8 or #request_id > 64 then
    SONAR.Metrics.Counter('bank.callbacks.create_escrow.missing_request_id')
    return _err('MISSING_FIELD', 'request_id required (UUID v4 string)')
  end

  -- 3. Idempotency check (best-effort; failures proceed per S1.2 pattern).
  local idem_ok, idem_ret = pcall(function()
    return exports.sonar_bridges:IsIdemReplay(request_id)
  end)
  if not idem_ok then
    SONAR.Log.Warn('Bridges:IsIdemReplay failed (create_escrow): %s', tostring(idem_ret))
    SONAR.Metrics.Counter('bank.callbacks.create_escrow.idem_lookup_failed')
  elseif type(idem_ret) == 'table' and idem_ret.is_replay == true then
    SONAR.Metrics.Counter('bank.callbacks.create_escrow.idempotency_replay')
    SONAR.Log.Audit({
      category = Config.AuditCategories.EscrowCreated,
      action   = 'idempotency_replay',
      actor    = citizen_id,
      target   = request_id,
      payload  = { request_id = request_id },
    })
    return idem_ret.cached
  end

  -- 4. Rate limit (bucket 'bank.write' — fail-closed).
  local rate_ok, rate_allowed = pcall(SONAR.Rate.Check, citizen_id, 'bank.write')
  if not rate_ok or rate_allowed ~= true then
    if not rate_ok then
      SONAR.Log.Warn('SONAR.Rate.Check threw (create_escrow): %s — fail-closed', tostring(rate_allowed))
    end
    SONAR.Metrics.Counter('bank.callbacks.create_escrow.rate_limited')
    return _err('RATE_LIMITED', 'Demasiadas operaciones. Espera un momento.')
  end

  -- 5. Shape validation basic fields (Escrow.Create does deep validation).
  local buyer_iban = request.buyer_iban
  local seller_iban = request.seller_iban
  local amount = tonumber(request.amount)
  local contract_id = request.contract_id
  local release_condition = request.release_condition
  local release_date = tonumber(request.release_date)

  if type(buyer_iban) ~= 'string' or buyer_iban == '' then
    return _err('MISSING_FIELD', 'buyer_iban required')
  end
  if type(seller_iban) ~= 'string' or seller_iban == '' then
    return _err('MISSING_FIELD', 'seller_iban required')
  end
  if not amount then
    return _err('MISSING_FIELD', 'amount required (number)')
  end
  if type(contract_id) ~= 'string' then contract_id = nil end
  if type(release_condition) ~= 'string' then release_condition = 'manual' end

  -- 6. Delegate to Escrow.Create.
  local ok, data, error_code = Escrow.Create(
    citizen_id, buyer_iban, seller_iban, amount,
    contract_id, release_condition, release_date, request_id
  )

  -- 7. Build response + error mapping.
  local response
  if ok and data then
    response = { success = true, data = data }
  else
    local message_map = {
      AMOUNT_OUT_OF_RANGE      = 'Importe fuera de rango permitido.',
      INVALID_IBAN             = 'IBAN inválido o cuenta inexistente.',
      SELF_ESCROW              = 'No puedes crear un escrow contigo mismo.',
      NOT_AUTHORIZED           = 'No estás autorizado para esta operación.',
      ACCOUNT_FROZEN           = 'Una de las cuentas está congelada o cerrada.',
      INSUFFICIENT_FUNDS       = 'Saldo insuficiente (monto + comisión).',
      INVALID_RELEASE_CONDITION = 'Condición de liberación no válida.',
      INVALID_REQUEST          = 'Parámetros de solicitud incorrectos.',
      SYSTEM_ACCOUNT_NOT_FOUND = 'Cuenta de tesorería no disponible. Contacta admin.',
      RACE_DETECTED            = 'Operación cancelada por concurrencia. Reintenta.',
      TX_CRASH                 = 'Error transitorio del sistema. Reintenta.',
      TX_ROLLBACK              = 'Operación abortada por integridad. Reintenta.',
    }
    response = _err(error_code or 'FAILED', message_map[error_code] or 'Creación de escrow fallida.')
  end

  -- 8. Persist idempotency (success OR error — PUT semantics).
  local store_ok, store_err = pcall(function()
    return exports.sonar_bridges:StoreIdem(request_id, response)
  end)
  if not store_ok then
    SONAR.Log.Warn('Bridges:StoreIdem failed (create_escrow) %s: %s', request_id, tostring(store_err))
    SONAR.Metrics.Counter('bank.callbacks.create_escrow.idem_store_failed')
  end

  -- 9. Metrics.
  local duration_ms = GetGameTimer() - start_ms
  SONAR.Metrics.Observe('bank.callbacks.create_escrow.duration_ms', duration_ms)

  return response
end)

-- =============================================================================
-- C005 — sonar:bank:releaseEscrow
--
-- Request (per SSoT §3.1 C005):
--   { escrow_id, release_to, split_ratio?, request_id }
--     release_to: 'seller' | 'buyer' | 'split'
--     split_ratio: 0..1 (required if release_to='split' — NOT_IMPLEMENTED S1.3)
--
-- Response (success): { success, data: { released_amount_seller,
--                       released_amount_buyer, timestamp } }
--
-- Auth matrix (F3 SSoT gap resolved S1.3):
--   caller==seller + release_to='seller' → allowed (release)
--   caller==buyer  + release_to='buyer'  → allowed (refund)
--   any other combo                       → NOT_AUTHORIZED
--   release_to='split'                    → NOT_IMPLEMENTED (deferred S3+)
-- =============================================================================
register_callback('sonar:bank:releaseEscrow', function(source, request)
  request = request or {}
  local start_ms = GetGameTimer()

  local citizen_id = Bank.GetCitizenIdBySource and Bank.GetCitizenIdBySource(source)
  if not citizen_id then
    SONAR.Metrics.Counter('bank.callbacks.release_escrow.not_authenticated')
    return _err('NOT_AUTHENTICATED', 'Player session not loaded')
  end

  local request_id = request.request_id
  if type(request_id) ~= 'string' or #request_id < 8 or #request_id > 64 then
    SONAR.Metrics.Counter('bank.callbacks.release_escrow.missing_request_id')
    return _err('MISSING_FIELD', 'request_id required (UUID v4 string)')
  end

  -- Idempotency.
  local idem_ok, idem_ret = pcall(function()
    return exports.sonar_bridges:IsIdemReplay(request_id)
  end)
  if not idem_ok then
    SONAR.Log.Warn('Bridges:IsIdemReplay failed (release_escrow): %s', tostring(idem_ret))
    SONAR.Metrics.Counter('bank.callbacks.release_escrow.idem_lookup_failed')
  elseif type(idem_ret) == 'table' and idem_ret.is_replay == true then
    SONAR.Metrics.Counter('bank.callbacks.release_escrow.idempotency_replay')
    SONAR.Log.Audit({
      category = Config.AuditCategories.EscrowReleased,
      action   = 'idempotency_replay',
      actor    = citizen_id,
      target   = request_id,
      payload  = { request_id = request_id },
    })
    return idem_ret.cached
  end

  -- Rate limit (fail-closed).
  local rate_ok, rate_allowed = pcall(SONAR.Rate.Check, citizen_id, 'bank.write')
  if not rate_ok or rate_allowed ~= true then
    if not rate_ok then
      SONAR.Log.Warn('SONAR.Rate.Check threw (release_escrow): %s — fail-closed', tostring(rate_allowed))
    end
    SONAR.Metrics.Counter('bank.callbacks.release_escrow.rate_limited')
    return _err('RATE_LIMITED', 'Demasiadas operaciones. Espera un momento.')
  end

  -- Shape validation.
  local escrow_id = request.escrow_id
  local release_to = request.release_to
  local split_ratio = tonumber(request.split_ratio)
  if type(escrow_id) ~= 'string' or escrow_id == '' then
    return _err('MISSING_FIELD', 'escrow_id required')
  end
  if type(release_to) ~= 'string' or release_to == '' then
    return _err('MISSING_FIELD', 'release_to required')
  end

  -- Delegate.
  local ok, data, error_code = Escrow.Release(
    citizen_id, escrow_id, release_to, split_ratio, request_id
  )

  local response
  if ok and data then
    response = { success = true, data = data }
  else
    local message_map = {
      NOT_AUTHENTICATED  = 'Sesión no iniciada.',
      NOT_AUTHORIZED     = 'No estás autorizado para esta liberación.',
      ESCROW_NOT_FOUND   = 'Escrow no encontrado.',
      INVALID_STATE      = 'Escrow no está en estado liberable (locked requerido).',
      NOT_IMPLEMENTED    = 'Modo split aún no implementado (S3+).',
      INVALID_REQUEST    = 'Parámetros de solicitud incorrectos.',
      ACCOUNT_FROZEN     = 'Cuenta destinataria congelada o cerrada.',
      TX_CRASH           = 'Error transitorio del sistema. Reintenta.',
      TX_ROLLBACK        = 'Operación abortada por integridad. Reintenta.',
    }
    response = _err(error_code or 'FAILED', message_map[error_code] or 'Liberación de escrow fallida.')
  end

  -- Persist idempotency.
  local store_ok, store_err = pcall(function()
    return exports.sonar_bridges:StoreIdem(request_id, response)
  end)
  if not store_ok then
    SONAR.Log.Warn('Bridges:StoreIdem failed (release_escrow) %s: %s', request_id, tostring(store_err))
    SONAR.Metrics.Counter('bank.callbacks.release_escrow.idem_store_failed')
  end

  local duration_ms = GetGameTimer() - start_ms
  SONAR.Metrics.Observe('bank.callbacks.release_escrow.duration_ms', duration_ms)

  return response
end)

-- =============================================================================
-- Boot announce.
-- =============================================================================
SONAR.Log.Info('Callbacks registered: getBalance (C001), transfer (C002), createEscrow (C004), releaseEscrow (C005)')
