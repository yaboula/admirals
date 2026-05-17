-- =============================================================================
-- SONAR Bank App — services/banker/compliance.lua
-- =============================================================================
-- Compliance flags review (F5).
--
--   Public API:
--     - ListFlags(ctx)   — list compliance flags filtered by status / severity
--     - Resolve(ctx)     — flag → resolved | false_positive (status FSM)
--
-- The compliance flags table is shared between admin/govt panels; the banker
-- can view + resolve flags involving the bank's own customer base under the
-- `fraud_review` capability.
-- =============================================================================

BankApp.services.banker = BankApp.services.banker or {}
BankApp.services.banker.compliance = {}
local S = BankApp.services.banker.compliance

local DB         = BankApp.lib.db
local Errors     = BankApp.lib.errors
local Audit      = BankApp.lib.audit
local Enums      = BankApp.lib.enums
local BankerAuth = BankApp.lib.banker_auth

local SQL_LIST = [[
SELECT cf.id AS flag_id,
       cf.flag_type,
       cf.severity,
       cf.status,
       sa.char_id AS citizen_id,
       cf.bank_account_id,
       ba.iban AS iban,
       cf.raised_by,
       cf.raised_at * 1000 AS raised_ms,
       CAST(cf.threshold_value * 100 AS SIGNED) AS threshold_minor,
       CAST(cf.observed_value * 100 AS SIGNED) AS observed_value_minor,
       cf.time_window_seconds,
       cf.action_taken,
       cf.resolution_note,
       cf.resolved_at * 1000 AS resolved_ms
FROM sonar_bank_compliance_flags cf
LEFT JOIN sonar_accounts sa ON sa.id = cf.citizen_account_id
LEFT JOIN sonar_bank_accounts ba ON ba.id = cf.bank_account_id
WHERE (? = '' OR cf.status = ?)
  AND (? = '' OR cf.severity = ?)
ORDER BY cf.raised_at DESC
LIMIT ?
]]

local SQL_GET = [[
SELECT cf.id AS flag_id, cf.flag_type, cf.severity, cf.status,
       cf.citizen_account_id, sa.char_id AS citizen_id,
       cf.bank_account_id, ba.iban AS iban
FROM sonar_bank_compliance_flags cf
LEFT JOIN sonar_accounts sa ON sa.id = cf.citizen_account_id
LEFT JOIN sonar_bank_accounts ba ON ba.id = cf.bank_account_id
WHERE cf.id = ?
LIMIT 1
]]

local SQL_RESOLVE = [[
UPDATE sonar_bank_compliance_flags
SET status               = ?,
    action_taken         = ?,
    resolution_note      = ?,
    resolved_at          = UNIX_TIMESTAMP(),
    updated_at           = UNIX_TIMESTAMP(),
    resolved_by_account_id = (SELECT id FROM sonar_accounts WHERE char_id = ? LIMIT 1)
WHERE id = ?
  AND status IN ('open','investigating')
]]

-- ---------------------------------------------------------------------------
-- §1. ListFlags
-- ---------------------------------------------------------------------------
function S.ListFlags(ctx)
  local _, _, auth_err = BankerAuth.RequireBanker(ctx.src, 'fraud_review')
  if auth_err then return { ok = false, error = auth_err } end

  local status   = type(ctx.status)   == 'string' and ctx.status   or ''
  local severity = type(ctx.severity) == 'string' and ctx.severity or ''
  local limit    = math.max(1, math.min(200, tonumber(ctx.limit) or 50))

  local rows, err = DB.Query(SQL_LIST, { status, status, severity, severity, limit })
  if err then return { ok = false, error = err } end

  for _, r in ipairs(rows or {}) do
    r.observed_value_minor = tonumber(r.observed_value_minor)
    r.raised_ms            = tonumber(r.raised_ms)
    r.resolved_ms          = tonumber(r.resolved_ms)
    r.time_window_seconds  = tonumber(r.time_window_seconds)
    r.threshold_minor      = tonumber(r.threshold_minor)
  end

  return {
    ok = true,
    data = {
      items = rows or {},
      filters = { status = status, severity = severity, limit = limit },
      fetched_at_ms = os.time() * 1000,
    },
  }
end

-- ---------------------------------------------------------------------------
-- §2. Resolve a flag (status: resolved | false_positive)
-- ---------------------------------------------------------------------------
function S.Resolve(ctx)
  local actor_id, role, auth_err = BankerAuth.RequireBanker(ctx.src, 'fraud_review')
  if auth_err then return { ok = false, error = auth_err } end

  local decision = ctx.decision
  if decision ~= 'resolved' and decision ~= 'false_positive' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'decision' }) }
  end
  local flag_id = tonumber(ctx.flag_id)
  if not flag_id then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'flag_id' }) }
  end

  local row = DB.QuerySingle(SQL_GET, { flag_id })
  if not row then
    return { ok = false, error = Errors.New('RESOURCE_NOT_FOUND', { entity = 'compliance_flag', id = flag_id }) }
  end

  local action_taken = (decision == 'resolved') and 'banker_resolved' or 'banker_false_positive'
  local note = (type(ctx.note) == 'string' and #ctx.note > 0) and ctx.note:sub(1, 240) or nil

  local _, exec_err = DB.Execute(SQL_RESOLVE, {
    decision, action_taken, note, actor_id, flag_id,
  })
  if exec_err then return { ok = false, error = exec_err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_CONFIG_CHANGE, -- generic banker action
    actor_citizen_id  = actor_id,
    actor_src         = ctx.src,
    actor_role        = role,
    target_citizen_id = row.citizen_id,
    target_iban       = row.iban,
    event_data        = {
      compliance_flag_id = flag_id,
      flag_type          = row.flag_type,
      severity           = row.severity,
      decision           = decision,
      note               = note,
      via                = 'banker',
    },
  })

  return {
    ok = true,
    data = { flag_id = flag_id, decision = decision, applied_at_ms = os.time() * 1000 },
  }
end
