-- =============================================================================
-- SONAR Bank App — boot/smoke.lua
-- =============================================================================
-- Boot-time smoke test. Runs synchronously en boot/init.lua phase 1 BEFORE
-- registering long-running workers + accepting callbacks.
--
-- Each check is a small named test that returns (ok, detail). The runner
-- aggregates results and returns a report. If any check fails AND it's marked
-- `fatal`, init.lua aborts boot.
--
-- Checks (8):
--   1. lib_modules            — all 12 lib modules loaded ✓
--   2. services_modules       — all 9 service modules loaded ✓
--   3. repos_modules          — all 8 repo modules loaded ✓
--   4. callbacks_registered   — all callback files invoked Wrap.Register ✓
--   5. hmac_loaded            — HMAC.IsLoaded() returns true (boot/init §2.1)
--   6. db_ping                — DB.QueryScalar('SELECT 1') == 1 (oxmysql up)
--   7. uuid_generates         — UUID.V4() returns valid v4 string
--   8. enums_present          — Enums.AUDIT_EVENT_TYPE has expected canonical keys
-- =============================================================================

BankApp.boot = BankApp.boot or {}
BankApp.boot.smoke = {}
local S = BankApp.boot.smoke

local Config = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. Internal check helpers
-- -----------------------------------------------------------------------------

local function check(label, fn, fatal)
  local ok, detail = pcall(fn)
  if ok and detail == nil then detail = '(no detail)' end
  return {
    label  = label,
    fatal  = fatal == true,
    passed = ok and (detail ~= false),
    detail = type(detail) == 'string' and detail or (ok and 'OK' or tostring(detail)):sub(1, 200),
  }
end

local function module_present(path)
  -- Walk dot-path on BankApp (e.g. 'lib.audit')
  local cur = BankApp
  for segment in path:gmatch('[^%.]+') do
    if type(cur) ~= 'table' then return false end
    cur = cur[segment]
  end
  return type(cur) == 'table'
end

-- -----------------------------------------------------------------------------
-- §2. Individual checks
-- -----------------------------------------------------------------------------

local LIB_MODULES = {
  'enums', 'errors', 'validators', 'db', 'uuid', 'hmac',
  'rate_limit', 'audit', 'idempotency', 'publish', 'auth', 'perf',
}

local SERVICE_MODULES = {
  'bootstrap', 'recipients', 'transfer', 'account',
  'loan', 'recurring', 'portfolio', 'card', 'admin',
}

local REPO_MODULES = {
  'accounts', 'transactions', 'recipients', 'audit_query',
  'recurring', 'loans', 'portfolio', 'cards',
}

local function check_lib_modules()
  local missing = {}
  for _, m in ipairs(LIB_MODULES) do
    if not module_present('lib.' .. m) then missing[#missing + 1] = m end
  end
  if #missing > 0 then
    return false, ('missing lib modules: %s'):format(table.concat(missing, ', '))
  end
  return true, ('all %d lib modules loaded'):format(#LIB_MODULES)
end

local function check_services()
  local missing = {}
  for _, m in ipairs(SERVICE_MODULES) do
    if not module_present('services.' .. m) then missing[#missing + 1] = m end
  end
  if #missing > 0 then
    return false, ('missing services: %s'):format(table.concat(missing, ', '))
  end
  return true, ('all %d services loaded'):format(#SERVICE_MODULES)
end

local function check_repos()
  local missing = {}
  for _, m in ipairs(REPO_MODULES) do
    if not module_present('repos.' .. m) then missing[#missing + 1] = m end
  end
  if #missing > 0 then
    return false, ('missing repos: %s'):format(table.concat(missing, ', '))
  end
  return true, ('all %d repos loaded'):format(#REPO_MODULES)
end

local function check_callbacks_registered()
  if not BankApp.callbacks or not BankApp.callbacks._wrap then
    return false, 'callbacks._wrap not loaded'
  end
  local list = BankApp.callbacks._wrap.ListRegistered() or {}
  local n = 0
  for _ in pairs(list) do n = n + 1 end
  if n < 30 then
    return false, ('only %d callbacks registered (expected ≥ 30)'):format(n)
  end
  return true, ('%d callbacks registered'):format(n)
end

local function check_hmac_loaded()
  local HMAC = BankApp.lib.hmac
  if not HMAC or not HMAC.IsLoaded() then
    return false, 'HMAC secret not loaded — convar sonar_bank_atm_hmac_secret missing or invalid'
  end
  return true, 'HMAC.IsLoaded() = true'
end

local function check_db_ping()
  local DB = BankApp.lib.db
  if not DB then return false, 'lib.db not loaded' end
  -- Use Query to also confirm prepared-statement path.
  local row, err = DB.QuerySingle('SELECT 1 AS v', {})
  if err then return false, ('DB ping err: %s'):format(err.message or err.code or 'unknown') end
  if not row then return false, 'DB ping returned no row' end
  if tonumber(row.v) ~= 1 then return false, ('DB ping unexpected value: %s'):format(tostring(row.v)) end
  return true, 'DB ping OK'
end

local function check_uuid_generates()
  local UUID = BankApp.lib.uuid
  if not UUID or type(UUID.V4) ~= 'function' then
    return false, 'lib.uuid.V4 not present'
  end
  local id = UUID.V4()
  if type(id) ~= 'string' or not UUID.IsValid(id) then
    return false, ('UUID.V4 returned invalid value: %s'):format(tostring(id))
  end
  return true, ('UUID.V4 OK (sample=%s)'):format(id)
end

local function check_enums()
  local Enums = BankApp.lib.enums
  if not Enums or type(Enums.AUDIT_EVENT_TYPE) ~= 'table' then
    return false, 'Enums.AUDIT_EVENT_TYPE missing'
  end
  local required = {
    'TRANSFER_COMMITTED', 'ACCOUNT_FREEZE', 'ATM_WITHDRAW',
    'GOVT_AUDIT_REQUEST', 'AUTH_DENIED',
  }
  for _, k in ipairs(required) do
    if Enums.AUDIT_EVENT_TYPE[k] == nil then
      return false, ('missing AUDIT_EVENT_TYPE.%s'):format(k)
    end
  end
  return true, 'AUDIT_EVENT_TYPE canonical keys OK'
end

-- -----------------------------------------------------------------------------
-- §3. Public Run — invoked from boot/init.lua phase 1
-- -----------------------------------------------------------------------------

--- Run — execute all smoke checks and return aggregated report.
---@return table { ok, passed, total, fatal_failures, results, summary }
function S.Run()
  local checks = {
    check('lib_modules',          check_lib_modules,          true),
    check('services_modules',     check_services,             true),
    check('repos_modules',        check_repos,                true),
    check('callbacks_registered', check_callbacks_registered, true),
    check('hmac_loaded',          check_hmac_loaded,          true),
    check('db_ping',              check_db_ping,              true),
    check('uuid_generates',       check_uuid_generates,       true),
    check('enums_present',        check_enums,                true),
  }

  local passed, fatal_failed = 0, 0
  local fail_list = {}

  for _, c in ipairs(checks) do
    if c.passed then
      passed = passed + 1
    else
      fail_list[#fail_list + 1] = ('%s: %s'):format(c.label, c.detail)
      if c.fatal then fatal_failed = fatal_failed + 1 end
    end

    -- Per-check log line (helpful en server console)
    print(('%s[SMOKE] %-22s %s — %s'):format(
      Config.Logging.PREFIX, c.label,
      c.passed and 'PASS' or 'FAIL',
      c.detail))
  end

  local total = #checks
  local report = {
    ok              = fatal_failed == 0,
    passed          = passed,
    total           = total,
    fatal_failures  = fatal_failed,
    results         = checks,
    summary         = fatal_failed == 0
                        and ('all %d/%d smoke checks passed'):format(passed, total)
                        or  ('FATAL — %d failure(s): %s'):format(
                              fatal_failed, table.concat(fail_list, ' | '):sub(1, 400)),
  }
  return report
end

return S
