-- =============================================================================
-- SONAR Bank App — services/banker/employees.lua
-- =============================================================================
-- Banker employees CRUD (F1).
--
--   Operations:
--     ListEmployees(ctx)  — list active (default) or include fired
--     HireEmployee(ctx)   — add new active employee, default salary from config
--     FireEmployee(ctx)   — soft-delete (status='fired') with reason + auditor
--     SetRole(ctx)        — promote / demote (CEO-only via capability matrix)
--     SetSalary(ctx)      — change salary clamped to C.Banker.Payroll caps
--
--   All mutations are gated through BankerAuth.RequireBanker(<capability>).
--   Audit trail emitted via lib.audit with banker_employee_* event types.
-- =============================================================================

BankApp.services.banker = BankApp.services.banker or {}
BankApp.services.banker.employees = {}
local S = BankApp.services.banker.employees

local Config     = BankApp.Config
local Errors     = BankApp.lib.errors
local Audit      = BankApp.lib.audit
local Enums      = BankApp.lib.enums
local Validators = BankApp.lib.validators
local BankerAuth = BankApp.lib.banker_auth
local BankerRepo = BankApp.repos.banker

local function now_ms() return os.time() * 1000 end

local function _role_exists(role)
  return type(role) == 'string'
     and Config.Banker
     and Config.Banker.Roles
     and Config.Banker.Roles[role] ~= nil
end

local function _default_salary_for_role(role)
  local payroll = (Config.Banker and Config.Banker.Payroll) or {}
  local defs = payroll.DefaultSalaryMinor or {}
  return tonumber(defs[role]) or 0
end

local function _salary_cap_for_role(role)
  local payroll = (Config.Banker and Config.Banker.Payroll) or {}
  local caps = payroll.SalaryCapsMinor or {}
  return tonumber(caps[role]) or 0
end

local function _clamp_salary(role, salary)
  local cap = _salary_cap_for_role(role)
  local s   = tonumber(salary) or 0
  if s < 0 then s = 0 end
  if cap > 0 and s > cap then s = cap end
  return math.floor(s)
end

-- -----------------------------------------------------------------------------
-- §1. ListEmployees
-- -----------------------------------------------------------------------------
function S.ListEmployees(ctx)
  local _, _, err = BankerAuth.RequireBanker(ctx.src, 'employees_view')
  if err then return { ok = false, error = err } end

  local rows, list_err = BankerRepo.ListEmployees({
    status        = ctx.status,
    include_fired = ctx.include_fired,
    limit         = ctx.limit or 200,
  })
  if list_err then return { ok = false, error = list_err } end

  local roles = (Config.Banker and Config.Banker.Roles) or {}
  for _, row in ipairs(rows or {}) do
    row.salary_minor = tonumber(row.salary_minor) or 0
    row.hired_at     = tonumber(row.hired_at)
    row.fired_at     = tonumber(row.fired_at)
    row.role_label   = (roles[row.role] or {}).label
  end

  return { ok = true, data = { items = rows or {}, fetched_at_ms = now_ms() } }
end

-- -----------------------------------------------------------------------------
-- §2. HireEmployee
-- -----------------------------------------------------------------------------
function S.HireEmployee(ctx)
  local actor_citizen_id, actor_employee, err = BankerAuth.RequireBanker(ctx.src, 'employees_hire')
  if err then return { ok = false, error = err } end

  if not Validators.IsValidCitizenId(ctx.target_citizen_id) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end

  if not _role_exists(ctx.role) then
    return { ok = false, error = Errors.New('INVALID_ENUM', { field = 'role', value = ctx.role }) }
  end

  -- Promoting to CEO requires the employees_set_role capability (CEO-only).
  if ctx.role == 'ceo' and not BankerAuth.HasCapability(actor_employee.role, 'employees_set_role') then
    return { ok = false, error = Errors.New('AUTH_BANKER_DENIED', { reason = 'only CEO can hire as CEO' }) }
  end

  local existing, exist_err = BankerRepo.GetActiveEmployeeByCitizen(ctx.target_citizen_id)
  if exist_err then return { ok = false, error = exist_err } end
  if existing then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', {
      reason     = 'citizen already an active employee',
      employee_id= existing.id,
    }) }
  end

  local salary = _clamp_salary(ctx.role,
    ctx.salary_minor or _default_salary_for_role(ctx.role))

  local new_id, hire_err = BankerRepo.HireEmployee({
    citizen_id          = ctx.target_citizen_id,
    role                = ctx.role,
    salary_minor        = salary,
    hired_by_citizen_id = actor_citizen_id,
    notes               = Validators.SanitizeString and Validators.SanitizeString(ctx.notes, 500) or ctx.notes,
  })
  if hire_err then return { ok = false, error = hire_err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_EMPLOYEE_HIRE,
    actor_citizen_id  = actor_citizen_id,
    actor_src         = ctx.src,
    target_citizen_id = ctx.target_citizen_id,
    event_data        = {
      employee_id  = new_id,
      role         = ctx.role,
      salary_minor = salary,
      notes        = ctx.notes,
    },
  })

  return { ok = true, data = {
    employee_id     = new_id,
    citizen_id      = ctx.target_citizen_id,
    role            = ctx.role,
    salary_minor    = salary,
    committed_at_ms = now_ms(),
  } }
end

-- -----------------------------------------------------------------------------
-- §3. FireEmployee
-- -----------------------------------------------------------------------------
function S.FireEmployee(ctx)
  local actor_citizen_id, actor_employee, err = BankerAuth.RequireBanker(ctx.src, 'employees_fire')
  if err then return { ok = false, error = err } end

  if type(ctx.employee_id) ~= 'string' or ctx.employee_id == '' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'employee_id' }) }
  end

  local target, get_err = BankerRepo.GetEmployeeById(ctx.employee_id)
  if get_err then return { ok = false, error = get_err } end
  if not target or target.status ~= 'active' then
    return { ok = false, error = Errors.New('RESOURCE_NOT_FOUND', { field = 'employee_id' }) }
  end

  -- Self-fire guard for CEO (admin override bypasses)
  if target.citizen_id == actor_citizen_id and target.role == 'ceo' and not actor_employee.synthetic_admin then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'CEO cannot self-fire; promote a successor first' }) }
  end

  -- Firing a CEO requires CEO authority (or admin override)
  if target.role == 'ceo' and not BankerAuth.HasCapability(actor_employee.role, 'employees_set_role') then
    return { ok = false, error = Errors.New('AUTH_BANKER_DENIED', { reason = 'only CEO can fire a CEO' }) }
  end

  local _, fire_err = BankerRepo.FireEmployee(
    ctx.employee_id,
    actor_citizen_id,
    Validators.SanitizeString and Validators.SanitizeString(ctx.reason, 255) or ctx.reason
  )
  if fire_err then return { ok = false, error = fire_err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_EMPLOYEE_FIRE,
    actor_citizen_id  = actor_citizen_id,
    actor_src         = ctx.src,
    target_citizen_id = target.citizen_id,
    event_data        = {
      employee_id   = ctx.employee_id,
      role_at_fire  = target.role,
      reason        = ctx.reason,
    },
  })

  return { ok = true, data = {
    employee_id     = ctx.employee_id,
    fired_at_ms     = now_ms(),
  } }
end

-- -----------------------------------------------------------------------------
-- §4. SetRole
-- -----------------------------------------------------------------------------
function S.SetRole(ctx)
  local actor_citizen_id, _, err = BankerAuth.RequireBanker(ctx.src, 'employees_set_role')
  if err then return { ok = false, error = err } end

  if type(ctx.employee_id) ~= 'string' or ctx.employee_id == '' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'employee_id' }) }
  end
  if not _role_exists(ctx.new_role) then
    return { ok = false, error = Errors.New('INVALID_ENUM', { field = 'new_role', value = ctx.new_role }) }
  end

  local target, get_err = BankerRepo.GetEmployeeById(ctx.employee_id)
  if get_err then return { ok = false, error = get_err } end
  if not target or target.status ~= 'active' then
    return { ok = false, error = Errors.New('RESOURCE_NOT_FOUND', { field = 'employee_id' }) }
  end
  if target.role == ctx.new_role then
    return { ok = true, data = { employee_id = ctx.employee_id, role = ctx.new_role, no_op = true } }
  end

  local _, role_err = BankerRepo.SetEmployeeRole(ctx.employee_id, ctx.new_role)
  if role_err then return { ok = false, error = role_err } end

  -- Optional: re-clamp salary to new role's cap
  local new_salary = _clamp_salary(ctx.new_role, target.salary_minor)
  if new_salary ~= tonumber(target.salary_minor) then
    BankerRepo.SetEmployeeSalary(ctx.employee_id, new_salary)
  end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_EMPLOYEE_SET_ROLE,
    actor_citizen_id  = actor_citizen_id,
    actor_src         = ctx.src,
    target_citizen_id = target.citizen_id,
    event_data        = {
      employee_id  = ctx.employee_id,
      old_role     = target.role,
      new_role     = ctx.new_role,
      old_salary   = tonumber(target.salary_minor) or 0,
      new_salary   = new_salary,
    },
  })

  return { ok = true, data = {
    employee_id     = ctx.employee_id,
    new_role        = ctx.new_role,
    new_salary_minor= new_salary,
    committed_at_ms = now_ms(),
  } }
end

-- -----------------------------------------------------------------------------
-- §5. SetSalary
-- -----------------------------------------------------------------------------
function S.SetSalary(ctx)
  local actor_citizen_id, _, err = BankerAuth.RequireBanker(ctx.src, 'employees_hire')
  if err then return { ok = false, error = err } end

  if type(ctx.employee_id) ~= 'string' or ctx.employee_id == '' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'employee_id' }) }
  end
  if type(ctx.salary_minor) ~= 'number' then
    return { ok = false, error = Errors.New('INVALID_AMOUNT', { field = 'salary_minor' }) }
  end

  local target, get_err = BankerRepo.GetEmployeeById(ctx.employee_id)
  if get_err then return { ok = false, error = get_err } end
  if not target or target.status ~= 'active' then
    return { ok = false, error = Errors.New('RESOURCE_NOT_FOUND', { field = 'employee_id' }) }
  end

  local clamped = _clamp_salary(target.role, ctx.salary_minor)
  local _, sal_err = BankerRepo.SetEmployeeSalary(ctx.employee_id, clamped)
  if sal_err then return { ok = false, error = sal_err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_EMPLOYEE_SET_ROLE,
    actor_citizen_id  = actor_citizen_id,
    actor_src         = ctx.src,
    target_citizen_id = target.citizen_id,
    event_data        = {
      employee_id     = ctx.employee_id,
      role            = target.role,
      old_salary      = tonumber(target.salary_minor) or 0,
      new_salary      = clamped,
      requested_salary= ctx.salary_minor,
    },
  })

  return { ok = true, data = {
    employee_id      = ctx.employee_id,
    new_salary_minor = clamped,
    committed_at_ms  = now_ms(),
  } }
end

-- -----------------------------------------------------------------------------
-- §6. EnsureInitialCEO — boot-time idempotent helper
--
--   If no employees exist, promote the configured initial CEO citizen_id.
--   Convar overrides config default. Idempotent: silently no-ops if employees
--   table already populated.
-- -----------------------------------------------------------------------------
function S.EnsureInitialCEO()
  local cfg = (Config.Banker and Config.Banker.InitialCEO) or {}
  local convar_id = cfg.convar_name and GetConvar(cfg.convar_name, '') or ''
  local citizen_id = (convar_id ~= '' and convar_id) or cfg.citizen_id_default or ''
  if citizen_id == '' then return false, 'no initial ceo configured' end

  local total, count_err = BankerRepo.CountAnyEmployee()
  if count_err then return false, count_err end
  if total > 0 then return false, 'employees table not empty' end

  local id, hire_err = BankerRepo.HireEmployee({
    citizen_id          = citizen_id,
    role                = 'ceo',
    salary_minor        = _default_salary_for_role('ceo'),
    hired_by_citizen_id = nil,
    notes               = 'Initial CEO bootstrapped at server start.',
  })
  if hire_err then return false, hire_err end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_EMPLOYEE_HIRE,
    actor_citizen_id  = nil,
    target_citizen_id = citizen_id,
    event_data        = {
      employee_id   = id,
      role          = 'ceo',
      salary_minor  = _default_salary_for_role('ceo'),
      bootstrap     = true,
    },
  })

  return true, nil
end
