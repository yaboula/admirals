-- =============================================================================
-- SONAR Tablet — server/bank_history.lua
-- =============================================================================
-- S2.4 scope: NUI bridge ad-hoc `sonar:tablet:bank:getHistory` (consumer
-- pattern temporal per SPRINT_PLAN_S2 §2.2.3 + ADR-015 línea 1162).
--
-- ⚠️  R5 mitigation (SPRINT_PLAN_S2 §9):
--   Este callback es TECH DEBT documentado hasta ship C003 `sonar:bank:getTransactions`
--   en S3. Wrapper `getHistoryDirect(cid, limit)` mantendrá NUI contract estable —
--   al shippear C003 solo se intercambia implementación interna.
--
-- ⚠️  DEFERRED catalog promotion (SPRINT_PLAN_S2 §2.2.3):
--   NO documentar en `docs/technical/02_events_catalog.md` v1.2. Bridge
--   específico del Tablet hasta promoción canónica S3+.
--
-- Flow:
--   1. Resolve source → citizen_id via cache local (SONAR.Identity hooks).
--   2. Rate-limit bucket 'bank.read' (30/10s — registered en sonar_core/config.lua
--      :122-126 — NO re-register).
--   3. Resolve personal bank account (type='personal', closed_at IS NULL).
--   4. Query sonar_bank_movements ORDER BY occurred_at DESC LIMIT N (default 50,
--      hard cap 200 per Movements.GetByAccount pattern).
--   5. Audit log category 'bank.read' action 'tablet_history' (informativo —
--      Config.AuditReads en sonar_bank es off default, pero este path siempre
--      audita porque es user-initiated con historial exposure).
--   6. Return { success, data: { movements, total, account_id, iban } } | error.
--
-- Referencias SSoT:
--   docs/technical/03_db_schema.md §4.2 (sonar_bank_movements canonical).
--   docs/technical/04_api_contracts.md §3.1 C001 (auth pattern source→cid).
--   progress/SPRINT_PLAN_S2.md §2.2.3 (NUI bridge ad-hoc DEFERRED).
--   progress/SPRINT_PLAN_S2.md §9 R5 (consumer pattern tech debt mitigation).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Cache source ↔ citizen_id — mismo pattern que sonar_bank/server/init.lua:47-54.
-- Populated via SONAR.Identity.OnPlayerLoaded/Dropped (sonar_core lib).
-- Necesario aquí porque Bank.GetCitizenIdBySource vive en VM sonar_bank (not
-- exported cross-resource). Mantener cache local is cheaper que crear nuevo export.
-- -----------------------------------------------------------------------------
local _src_to_cid = {}

SONAR.Identity.OnPlayerLoaded(function(citizenId, source)
  if type(source) == 'number' and source > 0 and type(citizenId) == 'string' then
    _src_to_cid[source] = citizenId
  end
end)

SONAR.Identity.OnPlayerDropped(function(_, source)
  if type(source) == 'number' then
    _src_to_cid[source] = nil
  end
end)

---Resolve FiveM source to citizen_id via local cache.
---@param source number
---@return string|nil citizen_id
local function _get_citizen_id(source)
  return _src_to_cid[tonumber(source) or -1]
end

-- -----------------------------------------------------------------------------
-- Error response helper — shape canónica alineada con sonar_bank/server/callbacks.lua:56-58.
-- -----------------------------------------------------------------------------
local function _err(code, message)
  return { success = false, error_code = code, message = message }
end

-- =============================================================================
-- getHistoryDirect(citizen_id, limit) — internal wrapper.
--
-- TODO R5 (SPRINT_PLAN_S2 §9): swap internal implementation a
--   `lib.callback.await('sonar:bank:getTransactions', false, { limit })` cuando
--   C003 ship S3. NUI contract `sonar:tablet:bank:getHistory` se mantiene
--   estable — Bank app S2.4 no requiere cambio consumer.
--
-- @param citizen_id string
-- @param limit number (1..200)
-- @return table response (success=true/false)
-- =============================================================================
local function getHistoryDirect(citizen_id, limit)
  -- Resolve personal bank_account via JOIN sonar_accounts (mismo query shape que
  -- sonar_bank Accounts.GetPersonalByCitizenId en accounts.lua:109-122).
  local account_row = SONAR.DB.FetchOne([[
    SELECT bk.id, bk.iban, bk.balance
    FROM sonar_bank_accounts bk
    JOIN sonar_accounts a ON a.id = bk.owner_account_id
    WHERE a.char_id = ?
      AND bk.owner_type = 'personal'
      AND bk.account_class = 'checking'
      AND bk.closed_at IS NULL
    LIMIT 1
  ]], { citizen_id })

  if not account_row then
    SONAR.Metrics.Counter('tablet.bank_history.no_account')
    return _err('NO_ACCOUNT', 'No personal account exists for this player')
  end

  -- Bound limit: default 50, hard cap 200 (matches sonar_bank Movements.GetByAccount
  -- movements.lua:113 defensive cap).
  local lim = tonumber(limit) or 50
  if lim < 1 then lim = 1 end
  if lim > 200 then lim = 200 end

  -- Query movements (mismo shape que Movements.GetByAccount movements.lua:117-126,
  -- inline aquí porque vive en VM sonar_bank, no cross-resource-callable).
  local rows = SONAR.DB.FetchAll([[
    SELECT id, amount, balance_after, category, counterpart_iban, concept,
           occurred_at, request_nonce
    FROM sonar_bank_movements
    WHERE bank_account_id = ?
    ORDER BY occurred_at DESC, id DESC
    LIMIT ?
  ]], { account_row.id, lim }) or {}

  -- Normalize response shape canónica para React consumer.
  -- created_at: convert seconds → ms (consistente con C001 response shape
  -- callbacks.lua:184 — last_updated en ms).
  local movements = {}
  for i = 1, #rows do
    local r = rows[i]
    movements[i] = {
      id               = tonumber(r.id),
      amount           = tonumber(r.amount) or 0.0,
      balance_after    = tonumber(r.balance_after) or 0.0,
      category         = r.category,
      counterpart_iban = r.counterpart_iban,
      concept          = r.concept,
      created_at       = (tonumber(r.occurred_at) or 0) * 1000,  -- ms
    }
  end

  return {
    success = true,
    data = {
      movements  = movements,
      total      = #movements,
      account_id = account_row.id,
      iban       = account_row.iban,
    },
  }
end

-- =============================================================================
-- lib.callback.register — `sonar:tablet:bank:getHistory`.
--
-- Invoked desde client/main.lua via lib.callback.await (forwarded desde React
-- fetchNUI('sonar:tablet:bank:getHistory')).
--
-- Request:  { limit?: number }  (default 50, max 200)
-- Response: { success=true, data: { movements, total, account_id, iban } }
--           | { success=false, error_code, message }
-- =============================================================================
lib.callback.register('sonar:tablet:bank:getHistory', function(source, request)
  request = request or {}
  local start_ms = GetGameTimer()

  -- 1. Auth: resolve source → citizen_id.
  local citizen_id = _get_citizen_id(source)
  if not citizen_id then
    SONAR.Metrics.Counter('tablet.bank_history.not_authenticated')
    return _err('NOT_AUTHENTICATED', 'Player session not loaded')
  end

  -- 2. Rate limit (bucket 'bank.read' — 30/10s per citizen, §04 §8.1).
  --    Fail-closed: Rate.Check pcall guard matches sonar_bank pattern
  --    callbacks.lua:266-273.
  local rate_ok, rate_allowed = pcall(SONAR.Rate.Check, citizen_id, 'bank.read')
  if not rate_ok or rate_allowed ~= true then
    if not rate_ok then
      SONAR.Log.Warn('SONAR.Rate.Check threw (tablet bank_history): %s — fail-closed',
        tostring(rate_allowed))
    end
    SONAR.Metrics.Counter('tablet.bank_history.rate_limited')
    return _err('RATE_LIMITED', 'Demasiadas consultas. Espera un momento.')
  end

  -- 3. Delegate to wrapper (R5 mitigation point).
  local response = getHistoryDirect(citizen_id, request.limit)

  -- 4. Audit log (category 'bank.read' action 'tablet_history').
  --    Siempre log, independiente de Config.AuditReads (user-initiated flow).
  SONAR.Log.Audit({
    category = 'bank.read',
    action   = 'tablet_history',
    actor    = citizen_id,
    target   = (response.success and response.data and response.data.account_id) or nil,
    payload  = {
      source    = source,
      limit     = tonumber(request.limit) or 50,
      returned  = (response.success and response.data and response.data.total) or 0,
      success   = response.success,
      err       = response.error_code,
    },
  })

  -- 5. Metrics.
  local duration_ms = GetGameTimer() - start_ms
  SONAR.Metrics.Observe('tablet.bank_history.duration_ms', duration_ms)
  if response.success then
    SONAR.Metrics.Counter('tablet.bank_history.ok')
  end

  return response
end)

-- =============================================================================
-- Boot announce.
-- =============================================================================
print('[sonar_tablet] bank_history callback registered (sonar:tablet:bank:getHistory — consumer pattern temporal §2.2.3, R5 tech debt until C003 S3)')
