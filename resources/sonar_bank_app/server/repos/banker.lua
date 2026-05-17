-- =============================================================================
-- SONAR Bank App — repos/banker.lua
-- =============================================================================
-- DAO for Bank Owner Panel (F1+).
--
--   Tables:
--     - sonar_bank_employees           (CRUD employees, status FSM)
--     - sonar_bank_config_overrides    (mutable config bag)
--     - sonar_bank_missions            (gameplay loop, schema only in F1)
--     - sonar_bank_atm_inventory       (gameplay loop, schema only in F1)
--
--   Pure SQL — no business validation; that lives in services/banker/*.
-- =============================================================================

BankApp.repos.banker = {}
local R = BankApp.repos.banker

local DB   = BankApp.lib.db
local UUID = BankApp.lib.uuid

-- -----------------------------------------------------------------------------
-- §1. Employees
-- -----------------------------------------------------------------------------
local SQL_INSERT_EMPLOYEE = [[
INSERT INTO sonar_bank_employees
  (id, citizen_id, role, status, salary_minor,
   hired_at, hired_by_citizen_id, notes)
VALUES (?, ?, ?, 'active', ?, UNIX_TIMESTAMP(), ?, ?)
]]

local SQL_LIST_EMPLOYEES = [[
SELECT id, citizen_id, role, status, salary_minor,
       hired_at, hired_by_citizen_id,
       fired_at, fired_by_citizen_id, fired_reason, notes
FROM sonar_bank_employees
WHERE status = ?
ORDER BY
  CASE role
    WHEN 'ceo'                THEN 1
    WHEN 'manager'            THEN 2
    WHEN 'compliance_officer' THEN 3
    WHEN 'advisor'            THEN 4
    WHEN 'teller'             THEN 5
    ELSE 99
  END,
  hired_at ASC
LIMIT ?
]]

local SQL_LIST_ALL_EMPLOYEES = [[
SELECT id, citizen_id, role, status, salary_minor,
       hired_at, hired_by_citizen_id,
       fired_at, fired_by_citizen_id, fired_reason, notes
FROM sonar_bank_employees
ORDER BY
  CASE status WHEN 'active' THEN 1 WHEN 'suspended' THEN 2 ELSE 3 END,
  CASE role
    WHEN 'ceo'                THEN 1
    WHEN 'manager'            THEN 2
    WHEN 'compliance_officer' THEN 3
    WHEN 'advisor'            THEN 4
    WHEN 'teller'             THEN 5
    ELSE 99
  END,
  hired_at ASC
LIMIT ?
]]

local SQL_GET_EMPLOYEE_BY_ID = [[
SELECT id, citizen_id, role, status, salary_minor,
       hired_at, hired_by_citizen_id,
       fired_at, fired_by_citizen_id, fired_reason, notes
FROM sonar_bank_employees
WHERE id = ?
LIMIT 1
]]

local SQL_GET_ACTIVE_BY_CITIZEN = [[
SELECT id, citizen_id, role, status, salary_minor, hired_at, notes
FROM sonar_bank_employees
WHERE citizen_id = ? AND status = 'active'
LIMIT 1
]]

local SQL_FIRE_EMPLOYEE = [[
UPDATE sonar_bank_employees
SET status = 'fired',
    fired_at = UNIX_TIMESTAMP(),
    fired_by_citizen_id = ?,
    fired_reason = ?
WHERE id = ? AND status = 'active'
]]

local SQL_SET_ROLE = [[
UPDATE sonar_bank_employees
SET role = ?
WHERE id = ? AND status = 'active'
]]

local SQL_SET_SALARY = [[
UPDATE sonar_bank_employees
SET salary_minor = ?
WHERE id = ? AND status = 'active'
]]

local SQL_COUNT_ACTIVE_BY_ROLE = [[
SELECT role, COUNT(*) AS n
FROM sonar_bank_employees
WHERE status = 'active'
GROUP BY role
]]

local SQL_COUNT_ANY_EMPLOYEE = [[
SELECT COUNT(*) AS n FROM sonar_bank_employees
]]

function R.HireEmployee(opts)
  local id = UUID.V4()
  local _, err = DB.Execute(SQL_INSERT_EMPLOYEE, {
    id,
    opts.citizen_id,
    opts.role,
    tonumber(opts.salary_minor) or 0,
    opts.hired_by_citizen_id,
    opts.notes,
  })
  if err then return nil, err end
  return id, nil
end

function R.ListEmployees(opts)
  opts = opts or {}
  local limit = tonumber(opts.limit) or 100
  if opts.include_fired then
    return DB.Query(SQL_LIST_ALL_EMPLOYEES, { limit })
  end
  local status = opts.status or 'active'
  return DB.Query(SQL_LIST_EMPLOYEES, { status, limit })
end

function R.GetEmployeeById(id)
  return DB.QuerySingle(SQL_GET_EMPLOYEE_BY_ID, { id })
end

function R.GetActiveEmployeeByCitizen(citizen_id)
  return DB.QuerySingle(SQL_GET_ACTIVE_BY_CITIZEN, { citizen_id })
end

function R.FireEmployee(id, fired_by_citizen_id, reason)
  return DB.Execute(SQL_FIRE_EMPLOYEE, { fired_by_citizen_id, reason, id })
end

function R.SetEmployeeRole(id, new_role)
  return DB.Execute(SQL_SET_ROLE, { new_role, id })
end

function R.SetEmployeeSalary(id, salary_minor)
  return DB.Execute(SQL_SET_SALARY, { tonumber(salary_minor) or 0, id })
end

function R.CountActiveByRole()
  local rows, err = DB.Query(SQL_COUNT_ACTIVE_BY_ROLE, {})
  if err then return nil, err end
  local out = {}
  for _, row in ipairs(rows or {}) do
    out[row.role] = tonumber(row.n) or 0
  end
  return out, nil
end

function R.CountAnyEmployee()
  local row, err = DB.QuerySingle(SQL_COUNT_ANY_EMPLOYEE, {})
  if err then return 0, err end
  return tonumber(row and row.n) or 0, nil
end

-- -----------------------------------------------------------------------------
-- §2. Config overrides
-- -----------------------------------------------------------------------------
local SQL_GET_OVERRIDE = [[
SELECT config_key, value_json, updated_at, updated_by_citizen_id, updated_by_role
FROM sonar_bank_config_overrides
WHERE config_key = ?
LIMIT 1
]]

local SQL_LIST_OVERRIDES = [[
SELECT config_key, value_json, updated_at, updated_by_citizen_id, updated_by_role
FROM sonar_bank_config_overrides
ORDER BY config_key ASC
]]

local SQL_UPSERT_OVERRIDE = [[
INSERT INTO sonar_bank_config_overrides
  (config_key, value_json, updated_at, updated_by_citizen_id, updated_by_role)
VALUES (?, ?, UNIX_TIMESTAMP(), ?, ?)
ON DUPLICATE KEY UPDATE
  value_json            = VALUES(value_json),
  updated_at            = VALUES(updated_at),
  updated_by_citizen_id = VALUES(updated_by_citizen_id),
  updated_by_role       = VALUES(updated_by_role)
]]

local SQL_DELETE_OVERRIDE = [[
DELETE FROM sonar_bank_config_overrides WHERE config_key = ?
]]

function R.GetConfigOverride(key)
  return DB.QuerySingle(SQL_GET_OVERRIDE, { key })
end

function R.ListConfigOverrides()
  return DB.Query(SQL_LIST_OVERRIDES, {})
end

function R.UpsertConfigOverride(opts)
  return DB.Execute(SQL_UPSERT_OVERRIDE, {
    opts.config_key,
    opts.value_json,
    opts.updated_by_citizen_id,
    opts.updated_by_role,
  })
end

function R.DeleteConfigOverride(key)
  return DB.Execute(SQL_DELETE_OVERRIDE, { key })
end
