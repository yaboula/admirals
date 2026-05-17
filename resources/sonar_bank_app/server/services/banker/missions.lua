-- =============================================================================
-- SONAR Bank App — services/banker/missions.lua
-- =============================================================================
-- Missions module (F6).
--
--   Public API:
--     - ListMissions(ctx)    — list missions filtered by state
--     - DispatchMission(ctx) — manager creates a new mission for the queue
--     - AssignMission(ctx)   — employee accepts/picks an open mission
--     - CompleteMission(ctx) — mark in_progress → completed (+ reward payout
--                              ledger entry, simplified for F6 MVP)
--
-- The mission engine is intentionally minimal (manager-driven). The auto-
-- dispatch cron based on ATM thresholds is a future iteration; the schema
-- + REST endpoints land here so the FE can already drive the loop manually.
-- =============================================================================

BankApp.services.banker = BankApp.services.banker or {}
BankApp.services.banker.missions = {}
local S = BankApp.services.banker.missions

local Config     = BankApp.Config
local DB         = BankApp.lib.db
local UUID       = BankApp.lib.uuid
local Errors     = BankApp.lib.errors
local Audit      = BankApp.lib.audit
local Enums      = BankApp.lib.enums
local BankerAuth = BankApp.lib.banker_auth
local BankerRepo = BankApp.repos.banker

local VALID_TYPES = {
  atm_refill         = true,
  card_production    = true,
  vault_audit        = true,
  loan_collection    = true,
  cash_transport_b2b = true,
  document_delivery  = true,
}

local function _config_missions()
  return (Config.Banker and Config.Banker.Missions) or {}
end

local function _default_reward_for(mission_type)
  local cfg = _config_missions()
  -- Map mission_type → CamelCase config block
  local mapping = {
    atm_refill         = 'AtmRefill',
    card_production    = 'CardProduction',
    vault_audit        = 'VaultAudit',
    loan_collection    = 'LoanCollection',
    cash_transport_b2b = 'CashTransportB2B',
    document_delivery  = 'DocumentDelivery',
  }
  local block = cfg[mapping[mission_type] or ''] or {}
  return tonumber(block.base_reward_minor) or 0
end

-- ---------------------------------------------------------------------------
-- §1. ListMissions
-- ---------------------------------------------------------------------------
local SQL_LIST = [[
SELECT m.id AS mission_id,
       m.mission_type,
       m.state,
       m.assigned_employee_id,
       m.assigned_citizen_id,
       m.reward_minor,
       m.created_at * 1000 AS created_ms,
       m.assigned_at * 1000 AS assigned_ms,
       m.completed_at * 1000 AS completed_ms,
       m.failed_at * 1000 AS failed_ms,
       m.failure_reason
FROM sonar_bank_missions m
WHERE (? = '' OR m.state = ?)
ORDER BY
  CASE m.state
    WHEN 'open' THEN 0
    WHEN 'assigned' THEN 1
    WHEN 'in_progress' THEN 2
    WHEN 'completed' THEN 3
    ELSE 4
  END,
  m.created_at DESC
LIMIT ?
]]

function S.ListMissions(ctx)
  local _, role, auth_err = BankerAuth.RequireBanker(ctx.src, 'panel_open')
  if auth_err then return { ok = false, error = auth_err } end

  local state = type(ctx.state) == 'string' and ctx.state or ''
  local limit = math.max(1, math.min(200, tonumber(ctx.limit) or 50))

  local rows, err = DB.Query(SQL_LIST, { state, state, limit })
  if err then return { ok = false, error = err } end

  local mission_catalog = {}
  for k in pairs(VALID_TYPES) do
    mission_catalog[k] = {
      base_reward_minor = _default_reward_for(k),
    }
  end

  return {
    ok = true,
    data = {
      items   = rows or {},
      catalog = mission_catalog,
      can_dispatch = BankerAuth.HasCapability(role, 'missions_dispatch'),
      can_accept   = BankerAuth.HasCapability(role, 'missions_accept'),
      role         = role,
      fetched_at_ms = os.time() * 1000,
    },
  }
end

-- ---------------------------------------------------------------------------
-- §2. DispatchMission
-- ---------------------------------------------------------------------------
local SQL_INSERT = [[
INSERT INTO sonar_bank_missions
  (id, mission_type, state, reward_minor, payload_json, created_at)
VALUES
  (?, ?, 'open', ?, ?, UNIX_TIMESTAMP())
]]

function S.DispatchMission(ctx)
  local actor_id, role, auth_err = BankerAuth.RequireBanker(ctx.src, 'missions_dispatch')
  if auth_err then return { ok = false, error = auth_err } end

  local mtype = ctx.mission_type
  if not VALID_TYPES[mtype] then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'mission_type' }) }
  end

  local reward = tonumber(ctx.reward_minor) or _default_reward_for(mtype)
  if reward < 0 then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'reward_minor' }) }
  end

  local mission_id = UUID.V4()
  local payload_json = type(ctx.payload) == 'table' and json.encode(ctx.payload) or nil

  local _, err = DB.Execute(SQL_INSERT, { mission_id, mtype, reward, payload_json })
  if err then return { ok = false, error = err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_MISSION_DISPATCH,
    actor_citizen_id  = actor_id,
    actor_src         = ctx.src,
    actor_role        = role,
    event_data        = { mission_id = mission_id, mission_type = mtype, reward_minor = reward },
  })

  return { ok = true, data = { mission_id = mission_id, mission_type = mtype, reward_minor = reward } }
end

-- ---------------------------------------------------------------------------
-- §3. AssignMission (self-assignment by an employee)
-- ---------------------------------------------------------------------------
local SQL_ASSIGN = [[
UPDATE sonar_bank_missions
SET state                = 'assigned',
    assigned_employee_id = ?,
    assigned_citizen_id  = ?,
    assigned_at          = UNIX_TIMESTAMP()
WHERE id = ?
  AND state = 'open'
]]

local SQL_GET_EMPLOYEE_ID = [[
SELECT id FROM sonar_bank_employees
WHERE citizen_id = ? AND status = 'active'
LIMIT 1
]]

function S.AssignMission(ctx)
  local actor_id, _, auth_err = BankerAuth.RequireBanker(ctx.src, 'missions_accept')
  if auth_err then return { ok = false, error = auth_err } end

  local mission_id = ctx.mission_id
  if type(mission_id) ~= 'string' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'mission_id' }) }
  end

  local emp = DB.QuerySingle(SQL_GET_EMPLOYEE_ID, { actor_id })
  if not emp then
    return { ok = false, error = Errors.New('AUTH_BANKER_DENIED', { reason = 'no_active_employee' }) }
  end

  local _, err = DB.Execute(SQL_ASSIGN, { emp.id, actor_id, mission_id })
  if err then return { ok = false, error = err } end

  return { ok = true, data = { mission_id = mission_id, assigned_to = actor_id } }
end

-- ---------------------------------------------------------------------------
-- §4. CompleteMission (assigned/in_progress → completed)
-- ---------------------------------------------------------------------------
local SQL_COMPLETE = [[
UPDATE sonar_bank_missions
SET state        = 'completed',
    completed_at = UNIX_TIMESTAMP()
WHERE id = ?
  AND state IN ('assigned','in_progress')
  AND assigned_citizen_id = ?
]]

function S.CompleteMission(ctx)
  local actor_id, role, auth_err = BankerAuth.RequireBanker(ctx.src, 'missions_accept')
  if auth_err then return { ok = false, error = auth_err } end

  local mission_id = ctx.mission_id
  if type(mission_id) ~= 'string' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'mission_id' }) }
  end

  local _, err = DB.Execute(SQL_COMPLETE, { mission_id, actor_id })
  if err then return { ok = false, error = err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_MISSION_COMPLETE,
    actor_citizen_id  = actor_id,
    actor_src         = ctx.src,
    actor_role        = role,
    event_data        = { mission_id = mission_id, completed_by = actor_id },
  })

  -- NOTE: actual reward payout to the citizen wallet is deferred to F6.5
  -- once the bank treasury → employee payroll service is wired. For now we
  -- record the audit event so the FE can show "completed" with the badge.

  return { ok = true, data = { mission_id = mission_id, completed_at_ms = os.time() * 1000 } }
end
