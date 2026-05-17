-- =============================================================================
-- SONAR Bank App — boot/banker_commands.lua
-- =============================================================================
-- Server admin commands for the Bank Owner Panel (F1).
--
--   /setbankowner <citizen_id> [role]
--     ACE: sonar.bank.admin
--     Description: Force-promote a citizen to a banker role (default 'ceo').
--     Use cases:
--       - Initial setup if you don't want to use the convar.
--       - Recover when the active CEO leaves the server.
--       - Demote / fire then re-hire a citizen with a different role.
--
--   /sonarbank_employees
--     ACE: sonar.bank.admin
--     Description: Dump active employees to the server console.
-- =============================================================================

local Config     = BankApp.Config
local BankerRepo = BankApp.repos.banker
local Employees  = BankApp.services.banker and BankApp.services.banker.employees
local Audit      = BankApp.lib.audit
local Enums      = BankApp.lib.enums

local PREFIX = Config.Logging.PREFIX

--- ace_check: permite consola, ACE específica del banco, o admins globales.
--- También loguea el motivo del deny para facilitar debugging.
local function ace_check(src)
  if src == 0 then return true end -- console always allowed
  if IsPlayerAceAllowed(src, 'sonar.bank.admin') then return true end
  if IsPlayerAceAllowed(src, 'command') then return true end -- group.admin fallback
  if IsPlayerAceAllowed(src, 'qbcore.admin') then return true end
  if IsPlayerAceAllowed(src, 'qbcore.god') then return true end
  -- Diagnóstico — muestra los identificadores reales para facilitar el fix de cfg.
  local ids = {}
  for i = 0, GetNumPlayerIdentifiers(src) - 1 do
    ids[#ids + 1] = GetPlayerIdentifier(src, i)
  end
  print(('%s[ace_check] DENY src=%s name=%s identifiers=[%s]'):format(
    PREFIX, tostring(src), GetPlayerName(src) or '?', table.concat(ids, ', ')))
  return false
end

-- ---------------------------------------------------------------------------
-- /setbankowner
-- ---------------------------------------------------------------------------
RegisterCommand('setbankowner', function(src, args)
  if not ace_check(src) then
    if src ~= 0 then
      print(('%s[setbankowner] denied for src=%s (no ACE).'):format(PREFIX, tostring(src)))
    end
    return
  end

  local citizen_id = args and args[1] or nil
  local role       = args and args[2] or 'ceo'

  if type(citizen_id) ~= 'string' or citizen_id == '' then
    print(('%s[setbankowner] usage: /setbankowner <citizen_id> [role]'):format(PREFIX))
    return
  end

  if not (Config.Banker and Config.Banker.Roles and Config.Banker.Roles[role]) then
    print(('%s[setbankowner] invalid role "%s". Valid: ceo, manager, compliance_officer, advisor, teller.'):format(PREFIX, role))
    return
  end

  -- Idempotent: if citizen already an active employee, fire then re-hire with new role.
  local existing = BankerRepo.GetActiveEmployeeByCitizen(citizen_id)
  if existing then
    BankerRepo.FireEmployee(existing.id, 'console', 'Replaced via /setbankowner')
    print(('%s[setbankowner] existing employee %s fired (was %s).'):format(PREFIX, existing.id, existing.role))
  end

  local default_salary = ((Config.Banker.Payroll or {}).DefaultSalaryMinor or {})[role] or 0
  local new_id, err = BankerRepo.HireEmployee({
    citizen_id          = citizen_id,
    role                = role,
    salary_minor        = default_salary,
    hired_by_citizen_id = src == 0 and 'console' or nil,
    notes               = 'Promoted via /setbankowner',
  })
  if err then
    print(('%s[setbankowner] FAILED: %s'):format(PREFIX, tostring(err.message or err.code)))
    return
  end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_EMPLOYEE_HIRE,
    actor_citizen_id  = nil,
    actor_src         = src ~= 0 and src or nil,
    target_citizen_id = citizen_id,
    event_data        = {
      employee_id = new_id,
      role        = role,
      via_command = 'setbankowner',
    },
  })

  print(('%s[setbankowner] ✅ citizen=%s role=%s employee_id=%s salary=%d'):format(
    PREFIX, citizen_id, role, new_id, default_salary))
end, true)

-- ---------------------------------------------------------------------------
-- /sonarbank_employees — list active staff
-- ---------------------------------------------------------------------------
RegisterCommand('sonarbank_employees', function(src, args)
  if not ace_check(src) then return end

  local rows, err = BankerRepo.ListEmployees({ limit = 200 })
  if err then
    print(('%s[employees] error: %s'):format(PREFIX, tostring(err.message or err.code)))
    return
  end

  print(('%s[employees] -------- active employees (%d) --------'):format(PREFIX, #(rows or {})))
  for _, row in ipairs(rows or {}) do
    print(('%s[employees]  %-12s | %s | citizen=%s | salary=%d | hired=%s'):format(
      PREFIX, row.role, row.id, row.citizen_id,
      tonumber(row.salary_minor) or 0,
      tostring(row.hired_at)))
  end
  print(('%s[employees] -----------------------------------'):format(PREFIX))
end, true)
