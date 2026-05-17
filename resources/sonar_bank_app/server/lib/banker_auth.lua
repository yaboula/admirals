-- =============================================================================
-- SONAR Bank App — lib/banker_auth.lua
-- =============================================================================
-- Bank Owner Panel auth (F1).
--
--   The Banker Panel is independent of Auth.RequireAdmin (server ACE) and
--   independent of Auth.RequireOwnership (account FK). It validates the caller
--   citizen against the sonar_bank_employees table and resolves the role +
--   capability set declared in C.Banker.
--
-- Public API:
--   M.GetActiveEmployee(citizen_id)        → row or nil, err
--   M.RequireBanker(src, capability)       → citizen_id, employee, nil  |  nil, nil, err
--   M.HasCapability(role, capability)      → bool
--   M.IsAdminOverride(src)                 → bool  (sonar.bank.admin ACE bypass)
--
-- The capability check follows weight semantics:
--   employee_role.weight >= C.Banker.Capabilities[capability]
-- where the capability value is itself a weight threshold.
-- =============================================================================

BankApp.lib.banker_auth = {}
local M = BankApp.lib.banker_auth

local Auth   = BankApp.lib.auth
local Errors = BankApp.lib.errors
local DB     = BankApp.lib.db
local Config = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. SQL helpers
-- -----------------------------------------------------------------------------
local SQL_SELECT_ACTIVE_EMPLOYEE = [[
SELECT id, citizen_id, role, status, salary_minor,
       hired_at, hired_by_citizen_id, notes
FROM sonar_bank_employees
WHERE citizen_id = ? AND status = 'active'
LIMIT 1
]]

local function _select_active_employee(citizen_id)
  return DB.QuerySingle(SQL_SELECT_ACTIVE_EMPLOYEE, { citizen_id })
end

-- -----------------------------------------------------------------------------
-- §2. GetActiveEmployee — public read helper
-- -----------------------------------------------------------------------------
function M.GetActiveEmployee(citizen_id)
  if type(citizen_id) ~= 'string' or citizen_id == '' then
    return nil, Errors.New('INVALID_CITIZEN_ID')
  end
  local row = _select_active_employee(citizen_id)
  return row, nil
end

-- -----------------------------------------------------------------------------
-- §3. HasCapability — pure function (role string × capability string)
-- -----------------------------------------------------------------------------
function M.HasCapability(role, capability)
  if type(role) ~= 'string' or type(capability) ~= 'string' then
    return false
  end
  local roles = Config.Banker and Config.Banker.Roles or {}
  local caps  = Config.Banker and Config.Banker.Capabilities or {}
  local role_def = roles[role]
  local needed   = caps[capability]
  if not role_def or not needed then return false end
  return (role_def.weight or 0) >= needed
end

-- -----------------------------------------------------------------------------
-- §4. IsAdminOverride — sonar.bank.admin ACE allows panel access regardless
--   of employee status. Used so server admins can always recover access if
--   the employee table gets corrupted.
-- -----------------------------------------------------------------------------
function M.IsAdminOverride(src)
  if type(src) ~= 'number' then return false end
  local ace = (Config.Banker and Config.Banker.ADMIN_ACE_OVERRIDE)
              or 'sonar.bank.admin'
  return IsPlayerAceAllowed(src, ace) == true
end

-- -----------------------------------------------------------------------------
-- §5. RequireBanker — gate for banker callbacks
--
--   capability: optional. If provided, the employee must satisfy it.
--               If nil, only "panel_open" is enforced.
--
--   Admin override: a player with the override ACE is treated as a virtual
--   CEO (synthetic employee row) so the panel always works for sysadmins.
-- -----------------------------------------------------------------------------
function M.RequireBanker(src, capability)
  if Config.Banker and Config.Banker.Enabled == false then
    return nil, nil, Errors.New('FEATURE_DISABLED', { feature = 'banker_panel' })
  end

  local citizen_id, citizen_err = Auth.RequireCitizen(src)
  if citizen_err then return nil, nil, citizen_err end

  local cap = capability or 'panel_open'

  if M.IsAdminOverride(src) then
    -- Synthetic CEO row — admin can do anything regardless of employees table.
    local synth = {
      id              = 'admin-override',
      citizen_id      = citizen_id,
      role            = 'ceo',
      status          = 'active',
      salary_minor    = 0,
      synthetic_admin = true,
    }
    return citizen_id, synth, nil
  end

  local employee, lookup_err = _select_active_employee(citizen_id)
  if lookup_err then return nil, nil, lookup_err end
  if not employee then
    return nil, nil, Errors.New('AUTH_BANKER_DENIED', {
      reason     = 'no active employee record for citizen',
      citizen_id = citizen_id,
    })
  end

  if not M.HasCapability(employee.role, cap) then
    return nil, nil, Errors.New('AUTH_BANKER_DENIED', {
      reason     = 'capability denied',
      role       = employee.role,
      capability = cap,
    })
  end

  return citizen_id, employee, nil
end

-- -----------------------------------------------------------------------------
-- §6. ListCapabilitiesForRole — utility for FE bootstrap response
-- -----------------------------------------------------------------------------
function M.ListCapabilitiesForRole(role)
  local out = {}
  local caps = Config.Banker and Config.Banker.Capabilities or {}
  for cap, _ in pairs(caps) do
    out[cap] = M.HasCapability(role, cap)
  end
  return out
end
