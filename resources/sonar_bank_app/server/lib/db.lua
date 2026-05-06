-- =============================================================================
-- SONAR Bank App — lib/db.lua
-- =============================================================================
-- DB access wrapper with H004 AP-SQL-1 enforcement (prepared statements only).
-- Built sobre oxmysql `MySQL` global (provided by '@oxmysql/lib/MySQL.lua' or
-- by oxmysql resource start). Caller siempre provee `params` table — SQL string
-- with `?` placeholders único patrón permitido.
--
-- Functions:
--   §1  AP-SQL-1 runtime detector (H004)
--   §2  Query primitives: Query, QuerySingle, QueryScalar
--   §3  Mutation primitives: Execute, Insert
--   §4  Transaction wrapper con deadlock retry (exponential backoff)
--   §5  Parallel query helper (REQ-FE-001 bootstrap aggregator)
--   §6  Convenience: ToBool, ToInt
--
-- Deps: lib/errors.lua.
-- Pre-condition: oxmysql resource started + MySQL global available.
-- =============================================================================

BankApp.lib.db = {}
local M = BankApp.lib.db

local Errors = BankApp.lib.errors
local Config = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. H004 — AP-SQL-1 runtime detector
--
--   Detects string concatenation in SQL strings (e.g. "SELECT ... " .. var).
--   En Lua we cannot detect concat at runtime once string is built, BUT we
--   can detect telltale patterns of *post-concat* SQL by looking for known
--   suspicious sequences (string interpolation residue, multiple consecutive
--   quotes, etc.). This is a defense-in-depth tripwire — primary defense is
--   developer discipline (always pass params table separately).
--
--   Strict mode (dev_mode=1): aborts caller via error().
--   Permissive mode (production): logs WARN + executes (avoid breaking prod).
-- -----------------------------------------------------------------------------

-- Patterns que indican probable SQL injection / concat residue:
--   - %.%. seguido de identifier (Lua concat operator literally appears in source — but at runtime string is final, so this only triggers if someone passes raw source)
--   - %%s o %%d (Lua format placeholders left unfilled by mistake)
--   - Multiple ' o " consecutivos sospechosos
--   - SQL fragments common en injected payloads (--; UNION SELECT; OR 1=1)
local AP_SQL_1_RUNTIME_PATTERNS = {
  '%-%-',                      -- SQL comment marker (suspicious in user input ending in --)
  ';%s*DROP%s+TABLE',          -- classic injection
  ';%s*DELETE%s+FROM',
  'UNION%s+SELECT',
  'OR%s+1%s*=%s*1',
  'OR%s+\'1\'%s*=%s*\'1\'',
  '%%s%s*$',                   -- format placeholder unfilled at end
  '%%d%s*$',
}

local function detect_ap_sql_1(sql)
  if type(sql) ~= 'string' then return false, 'sql is not a string' end
  if not Config.Features.ENABLE_AP_SQL_1_RUNTIME_DETECT then return true, nil end

  for _, pat in ipairs(AP_SQL_1_RUNTIME_PATTERNS) do
    if sql:upper():find(pat) then
      return false, 'AP-SQL-1 pattern matched: ' .. pat
    end
  end
  return true, nil
end

local function get_dev_mode()
  local v = GetConvar(Config.Convars.DEV_MODE.name, '0')
  return v == '1' or v == 'true'
end

-- Guard runs before every query. Returns true if safe; false + abort/warn if not.
local function ap_sql_1_guard(sql)
  local ok, reason = detect_ap_sql_1(sql)
  if ok then return true end

  local msg = ('[%s] AP-SQL-1 violation detected (H004): %s | sql=%q'):format(
    Config.Logging.PREFIX, reason, sql:sub(1, 200))

  if get_dev_mode() and Config.DB.AP_SQL_1_STRICT_DEV then
    error(msg, 2)
  else
    print('[WARN] ' .. msg)
  end
  return false
end

-- -----------------------------------------------------------------------------
-- §2. Query primitives (SELECT — return rows)
-- -----------------------------------------------------------------------------

--- Query: SELECT returning multiple rows.
---@param sql string SQL with `?` placeholders
---@param params table positional params (default {})
---@return table|nil rows (array of row tables) or nil on error
---@return table|nil err standardized error tuple
function M.Query(sql, params)
  if not ap_sql_1_guard(sql) then
    return nil, Errors.New('DB_AP_SQL_1_VIOLATION', { sql = sql:sub(1, 100) })
  end
  params = params or {}

  local ok, result = pcall(function()
    return MySQL.query.await(sql, params)
  end)

  if not ok then
    return nil, Errors.New('DB_TRANSACTION_FAILED', { raw = tostring(result), sql = sql:sub(1, 100) })
  end
  return result or {}, nil
end

--- QuerySingle: SELECT returning single row (or nil).
---@param sql string
---@param params table
---@return table|nil row
---@return table|nil err
function M.QuerySingle(sql, params)
  if not ap_sql_1_guard(sql) then
    return nil, Errors.New('DB_AP_SQL_1_VIOLATION', { sql = sql:sub(1, 100) })
  end
  params = params or {}

  local ok, result = pcall(function()
    return MySQL.single.await(sql, params)
  end)

  if not ok then
    return nil, Errors.New('DB_TRANSACTION_FAILED', { raw = tostring(result), sql = sql:sub(1, 100) })
  end
  return result, nil  -- result may be nil (no row matched) — caller checks
end

--- QueryScalar: SELECT returning single scalar value (1st column of 1st row).
---@param sql string
---@param params table
---@return any value
---@return table|nil err
function M.QueryScalar(sql, params)
  if not ap_sql_1_guard(sql) then
    return nil, Errors.New('DB_AP_SQL_1_VIOLATION', { sql = sql:sub(1, 100) })
  end
  params = params or {}

  local ok, result = pcall(function()
    return MySQL.scalar.await(sql, params)
  end)

  if not ok then
    return nil, Errors.New('DB_TRANSACTION_FAILED', { raw = tostring(result), sql = sql:sub(1, 100) })
  end
  return result, nil
end

-- -----------------------------------------------------------------------------
-- §3. Mutation primitives (INSERT/UPDATE/DELETE)
-- -----------------------------------------------------------------------------

--- Execute: UPDATE/DELETE returning affectedRows count.
---@param sql string
---@param params table
---@return integer|nil affected_rows
---@return table|nil err
function M.Execute(sql, params)
  if not ap_sql_1_guard(sql) then
    return nil, Errors.New('DB_AP_SQL_1_VIOLATION', { sql = sql:sub(1, 100) })
  end
  params = params or {}

  local ok, result = pcall(function()
    return MySQL.update.await(sql, params)
  end)

  if not ok then
    return nil, Errors.New('DB_TRANSACTION_FAILED', { raw = tostring(result), sql = sql:sub(1, 100) })
  end
  return result or 0, nil
end

--- Insert: INSERT returning insertId.
---@param sql string
---@param params table
---@return integer|nil insert_id
---@return table|nil err
function M.Insert(sql, params)
  if not ap_sql_1_guard(sql) then
    return nil, Errors.New('DB_AP_SQL_1_VIOLATION', { sql = sql:sub(1, 100) })
  end
  params = params or {}

  local ok, result = pcall(function()
    return MySQL.insert.await(sql, params)
  end)

  if not ok then
    return nil, Errors.New('DB_TRANSACTION_FAILED', { raw = tostring(result), sql = sql:sub(1, 100) })
  end
  return result, nil
end

-- -----------------------------------------------------------------------------
-- §4. Transaction wrapper (deadlock retry exponential backoff)
--
--   Pattern: Transaction(queries_array) where queries_array is
--     { { query = 'SQL ?', values = { ... } }, ... }
--   oxmysql's MySQL.transaction.await runs all in a single TX.
-- -----------------------------------------------------------------------------

--- Transaction: atomic batch of queries con retry en deadlock.
---@param queries table array of { query=string, values=table }
---@param opts table|nil { max_retries=integer, base_ms=integer }
---@return boolean ok
---@return table|nil err
function M.Transaction(queries, opts)
  opts = opts or {}
  local max_retries = opts.max_retries or Config.DB.TRANSACTION_RETRY_MAX
  local base_ms     = opts.base_ms or Config.DB.TRANSACTION_RETRY_BASE_MS

  if type(queries) ~= 'table' or #queries == 0 then
    return false, Errors.New('VALIDATION_FAILED', { reason = 'queries must be non-empty array' })
  end

  -- AP-SQL-1 guard each query
  for i, q in ipairs(queries) do
    if type(q) ~= 'table' or type(q.query) ~= 'string' then
      return false, Errors.New('VALIDATION_FAILED', { reason = 'query[i] missing query field', i = i })
    end
    if not ap_sql_1_guard(q.query) then
      return false, Errors.New('DB_AP_SQL_1_VIOLATION', { i = i, sql = q.query:sub(1, 100) })
    end
  end

  local attempt = 0
  while attempt <= max_retries do
    local ok, result = pcall(function()
      return MySQL.transaction.await(queries)
    end)

    if ok and result then
      return true, nil
    end

    -- Detect deadlock pattern in error string (MariaDB error 1213)
    local raw = tostring(result or 'unknown')
    local is_deadlock = raw:find('1213') or raw:find('Deadlock') or raw:find('deadlock')

    if not is_deadlock or attempt == max_retries then
      return false, Errors.New(
        is_deadlock and 'DB_DEADLOCK' or 'DB_TRANSACTION_FAILED',
        { raw = raw, attempts = attempt + 1 }
      )
    end

    -- Exponential backoff: 50ms, 100ms, 200ms ...
    local sleep_ms = base_ms * (2 ^ attempt)
    Citizen.Wait(sleep_ms)
    attempt = attempt + 1
  end

  return false, Errors.New('DB_TRANSACTION_FAILED', { reason = 'max retries exhausted' })
end

-- -----------------------------------------------------------------------------
-- §5. Parallel query helper (REQ-FE-001 bootstrap aggregator)
--
--   Executes N independent queries via oxmysql's underlying connection pool.
--   oxmysql does NOT expose explicit promise.all, BUT consecutive .await calls
--   in the same coroutine block execute sequentially — to truly parallelize
--   we need to dispatch each query in its own coroutine + Citizen.Await on
--   collection.
--
--   Implementation: spawn N coroutines with Citizen.CreateThread, each writing
--   its result to a shared results array via mutex-free single-writer pattern,
--   parent thread polls until all done OR overall timeout.
-- -----------------------------------------------------------------------------

--- Parallel: execute N queries concurrently, return results array indexed identically.
---@param queries table array of { sql=string, params=table, kind='query'|'single'|'scalar' }
---@param opts table|nil { timeout_ms=integer }
---@return table|nil results array (same order as input). nil if timeout.
---@return table|nil err
function M.Parallel(queries, opts)
  opts = opts or {}
  local timeout_ms = opts.timeout_ms or Config.Bootstrap.TOTAL_TIMEOUT_MS

  if type(queries) ~= 'table' or #queries == 0 then
    return nil, Errors.New('VALIDATION_FAILED', { reason = 'queries must be non-empty array' })
  end

  local n = #queries
  local results = {}
  local errs = {}
  local done_count = 0

  for i = 1, n do
    local q = queries[i]
    if not ap_sql_1_guard(q.sql) then
      return nil, Errors.New('DB_AP_SQL_1_VIOLATION', { i = i, sql = q.sql:sub(1, 100) })
    end

    Citizen.CreateThread(function()
      local kind = q.kind or 'query'
      local ok, result
      if kind == 'query' then
        ok, result = pcall(function() return MySQL.query.await(q.sql, q.params or {}) end)
      elseif kind == 'single' then
        ok, result = pcall(function() return MySQL.single.await(q.sql, q.params or {}) end)
      elseif kind == 'scalar' then
        ok, result = pcall(function() return MySQL.scalar.await(q.sql, q.params or {}) end)
      else
        ok, result = false, 'unknown query kind: ' .. tostring(kind)
      end

      if ok then
        results[i] = result
      else
        errs[i] = tostring(result)
      end
      done_count = done_count + 1
    end)
  end

  -- Poll for completion or timeout
  local elapsed = 0
  local poll_interval = 5  -- ms
  while done_count < n and elapsed < timeout_ms do
    Citizen.Wait(poll_interval)
    elapsed = elapsed + poll_interval
  end

  if done_count < n then
    return nil, Errors.New('DB_TIMEOUT', {
      reason = 'parallel queries timeout',
      timeout_ms = timeout_ms,
      completed = done_count,
      total = n,
    })
  end

  -- Check for individual query errors
  for i = 1, n do
    if errs[i] then
      return nil, Errors.New('DB_TRANSACTION_FAILED', { i = i, raw = errs[i] })
    end
  end

  return results, nil
end

-- -----------------------------------------------------------------------------
-- §6. Convenience helpers
-- -----------------------------------------------------------------------------

--- ToBool: TINYINT(1) → boolean (MySQL returns 0/1 as numbers).
---@param v any
---@return boolean
function M.ToBool(v)
  if type(v) == 'boolean' then return v end
  if type(v) == 'number' then return v ~= 0 end
  if type(v) == 'string' then return v == '1' or v:lower() == 'true' end
  return false
end

--- ToInt: number/string → integer (or nil).
---@param v any
---@return integer|nil
function M.ToInt(v)
  if type(v) == 'number' then return math.floor(v) end
  if type(v) == 'string' then
    local n = tonumber(v)
    if n then return math.floor(n) end
  end
  return nil
end

return M
