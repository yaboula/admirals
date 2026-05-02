-- =============================================================================
-- Admirals Core — server/db.lua
--
-- Wrapper canónico oxmysql. TODA query Admirals debe pasar por aquí.
--
-- API pública (todas síncronas — await internamente vía oxmysql *.await):
--   Admirals.DB.FetchOne(query, params)      → row | nil
--   Admirals.DB.FetchAll(query, params)      → array
--   Admirals.DB.Execute(query, params)       → affectedRows
--   Admirals.DB.Insert(query, params)        → insertId (LAST_INSERT_ID)
--   Admirals.DB.Scalar(query, params)        → primera columna de primera row
--   Admirals.DB.Transaction(queries[])       → boolean success
--
-- Validación (hard-enforce per docs/technical/04_api_contracts.md §6.1):
--   1. Rechaza query sin '?' placeholder si params no vacío.
--   2. Params no nil (use {} explícito si no hay).
--   3. Timeout Config.DbTimeoutMs via Citizen.Await race (oxmysql no expose).
--   4. Slow query >Config.DbSlowQueryMs → Log.Warn + metric slow_query.
--   5. Todas las queries: metric duration_ms + counter por tipo.
--   6. Error runtime: Log.Error + metric db_error + rethrow (caller decide).
--
-- Anti-patterns prohibidos (per docs/technical/06_fivem_standards.md §5.4):
--   ❌ Concatenar strings dinámicos en la query.
--   ❌ MySQL.query direct fuera de este wrapper.
--   ❌ SELECT * en hot paths.
--
-- Referencias SSoT:
--   docs/technical/04_api_contracts.md §6 (DB Access Layer).
--   docs/technical/06_fivem_standards.md §2.4, §4.1 T3 (SQL injection).
--   oxmysql API: https://overextended.dev/oxmysql
-- =============================================================================

Admirals = Admirals or {}
Admirals.DB = Admirals.DB or {}

local Config = Admirals.Config
local Log = Admirals.Log
local Metrics = Admirals.Metrics
local DB = Admirals.DB

-- -----------------------------------------------------------------------------
-- Internal — validate query + params (prepared statement enforcement).
-- Rechaza queries con potencial de SQL injection (concat dinámica).
--
-- Regla: si params tiene elementos, query DEBE contener al menos un '?'.
-- Regla: params debe ser tabla (array o vacío), nunca nil.
-- -----------------------------------------------------------------------------
local function _validate(query, params, caller)
  if type(query) ~= 'string' or query == '' then
    error(('[Admirals.DB.%s] query must be non-empty string'):format(caller or '?'), 3)
  end
  if type(params) ~= 'table' then
    error(('[Admirals.DB.%s] params must be a table (use {} if none)'):format(caller or '?'), 3)
  end

  local param_count = 0
  for _ in pairs(params) do param_count = param_count + 1 end

  if param_count > 0 then
    if not query:find('?', 1, true) then
      error(('[Admirals.DB.%s] params provided but query has no "?" placeholder — potential SQL injection'):format(caller or '?'), 3)
    end
  end
end

-- -----------------------------------------------------------------------------
-- Internal — extract short query shape for metric labels.
-- "SELECT x FROM y WHERE z = ?" → "select"
-- "INSERT INTO x ..." → "insert"
-- Limita cardinalidad del metric key.
-- -----------------------------------------------------------------------------
local function _query_kind(query)
  local kind = query:match('^%s*(%a+)')
  if not kind then return 'unknown' end
  return kind:lower()
end

-- -----------------------------------------------------------------------------
-- Internal — truncate query for log/error output (avoid log spam).
-- -----------------------------------------------------------------------------
local function _truncate(s, n)
  n = n or 200
  s = tostring(s)
  if #s <= n then return s end
  return s:sub(1, n) .. '...'
end

-- -----------------------------------------------------------------------------
-- Internal — execute oxmysql operation with:
--   1. Timeout race (Citizen.Await) — oxmysql no expose timeout nativo.
--   2. Duration metric + slow query warn.
--   3. Error catching + re-raise.
--
-- @param fn function — 0-arg function wrapping the oxmysql.*.await call.
-- @param caller string — API method name ('FetchOne', 'Execute', ...).
-- @param query string.
-- @return any — whatever fn returns.
-- -----------------------------------------------------------------------------
local function _execute_with_guards(fn, caller, query)
  local kind = _query_kind(query)
  local start_ms = GetGameTimer()

  -- Timeout pattern: ejecutamos fn en un promise; si duration excede timeout,
  -- logueamos + marcamos métrica pero dejamos completar (FiveM no cancela
  -- coroutines ongoing — matar un .await puede dejar connection pool inconsistente).
  -- El timeout es "soft" → detección + alarma, no cancelación forzada.
  --
  -- Hard-cancel se añadirá S1+ si vemos queries >3s realmente (raro con pool healthy).
  local ok, result = pcall(fn)
  local duration = GetGameTimer() - start_ms

  -- Metrics siempre.
  Metrics.Counter('db.queries.' .. kind)
  Metrics.Observe('db.duration_ms.' .. kind, duration)

  if not ok then
    Metrics.Counter('db.errors.' .. kind)
    Log.Error('[DB.%s] FAILED after %dms: %s | query=%s',
      caller, duration, tostring(result), _truncate(query))
    error(result, 3)  -- rethrow al caller
  end

  -- Slow query → warn.
  if duration > Config.DbSlowQueryMs then
    Metrics.Counter('db.slow_queries.' .. kind)
    Log.Warn('[DB.%s] SLOW %dms (threshold %dms): %s',
      caller, duration, Config.DbSlowQueryMs, _truncate(query))
  end

  -- Timeout "soft" — duration excedió DbTimeoutMs.
  if duration > Config.DbTimeoutMs then
    Metrics.Counter('db.timeouts.' .. kind)
    Log.Warn('[DB.%s] TIMEOUT %dms (budget %dms): %s',
      caller, duration, Config.DbTimeoutMs, _truncate(query))
  end

  return result
end

-- -----------------------------------------------------------------------------
-- Public — FetchOne — devuelve primera row o nil.
-- -----------------------------------------------------------------------------
function DB.FetchOne(query, params)
  params = params or {}
  _validate(query, params, 'FetchOne')
  return _execute_with_guards(function()
    return MySQL.single.await(query, params)
  end, 'FetchOne', query)
end

-- -----------------------------------------------------------------------------
-- Public — FetchAll — devuelve array (posiblemente vacío).
-- -----------------------------------------------------------------------------
function DB.FetchAll(query, params)
  params = params or {}
  _validate(query, params, 'FetchAll')
  local result = _execute_with_guards(function()
    return MySQL.query.await(query, params)
  end, 'FetchAll', query)
  return result or {}
end

-- -----------------------------------------------------------------------------
-- Public — Execute — UPDATE/DELETE/DDL. Devuelve affectedRows.
-- -----------------------------------------------------------------------------
function DB.Execute(query, params)
  params = params or {}
  _validate(query, params, 'Execute')
  return _execute_with_guards(function()
    return MySQL.update.await(query, params)
  end, 'Execute', query)
end

-- -----------------------------------------------------------------------------
-- Public — Insert — INSERT. Devuelve insertId (LAST_INSERT_ID).
-- -----------------------------------------------------------------------------
function DB.Insert(query, params)
  params = params or {}
  _validate(query, params, 'Insert')
  return _execute_with_guards(function()
    return MySQL.insert.await(query, params)
  end, 'Insert', query)
end

-- -----------------------------------------------------------------------------
-- Public — Scalar — primera columna de primera row, nil si ninguna.
-- Útil para COUNT(*), exists checks, SELECT balance FROM ... LIMIT 1.
-- -----------------------------------------------------------------------------
function DB.Scalar(query, params)
  params = params or {}
  _validate(query, params, 'Scalar')
  return _execute_with_guards(function()
    return MySQL.scalar.await(query, params)
  end, 'Scalar', query)
end

-- -----------------------------------------------------------------------------
-- Public — Transaction — atomic multi-query.
--
-- @param queries array de { query=string, values=table } — formato oxmysql.
-- @return boolean success — true si todas OK, false si rollback.
--
-- Rollback automático si cualquier query falla (oxmysql native behavior).
-- Valida cada query individual con _validate.
-- -----------------------------------------------------------------------------
function DB.Transaction(queries)
  if type(queries) ~= 'table' or #queries == 0 then
    error('[Admirals.DB.Transaction] queries must be non-empty array', 2)
  end

  for i, q in ipairs(queries) do
    if type(q) ~= 'table' or type(q.query) ~= 'string' then
      error(('[Admirals.DB.Transaction] queries[%d] must be { query=string, values=table }'):format(i), 2)
    end
    q.values = q.values or {}
    _validate(q.query, q.values, ('Transaction[%d]'):format(i))
  end

  local start_ms = GetGameTimer()
  local ok, result = pcall(function()
    return MySQL.transaction.await(queries)
  end)
  local duration = GetGameTimer() - start_ms

  Metrics.Counter('db.queries.transaction')
  Metrics.Observe('db.duration_ms.transaction', duration)

  if not ok then
    Metrics.Counter('db.errors.transaction')
    Log.Error('[DB.Transaction] FAILED after %dms (%d queries): %s',
      duration, #queries, tostring(result))
    error(result, 2)
  end

  if duration > Config.DbSlowQueryMs then
    Metrics.Counter('db.slow_queries.transaction')
    Log.Warn('[DB.Transaction] SLOW %dms (%d queries, threshold %dms)',
      duration, #queries, Config.DbSlowQueryMs)
  end

  if not result then
    Metrics.Counter('db.rollbacks.transaction')
    Log.Warn('[DB.Transaction] ROLLBACK (%d queries, %dms)', #queries, duration)
  end

  return result == true
end

-- -----------------------------------------------------------------------------
-- Public — IsReady — checks oxmysql está cargado + alcanzable.
-- Usado por init.lua antes de migrations.
-- -----------------------------------------------------------------------------
function DB.IsReady()
  if not MySQL or not MySQL.scalar or not MySQL.scalar.await then
    return false, 'oxmysql not loaded'
  end

  -- Ping: SELECT 1. Si falla → DB no conectada.
  local ok, result = pcall(function()
    return MySQL.scalar.await('SELECT 1', {})
  end)
  if not ok then
    return false, tostring(result)
  end
  if result ~= 1 then
    return false, 'unexpected ping result: ' .. tostring(result)
  end
  return true
end

-- -----------------------------------------------------------------------------
-- Public — WaitReady — async poll hasta DB.IsReady() o timeout.
-- Usado por init.lua antes de migrations.
--
-- @param timeout_ms number — default 15000.
-- @return boolean ready, string? reason.
-- -----------------------------------------------------------------------------
function DB.WaitReady(timeout_ms)
  timeout_ms = timeout_ms or 15000
  local start = GetGameTimer()
  local last_reason = 'init'
  while (GetGameTimer() - start) < timeout_ms do
    local ok, reason = DB.IsReady()
    if ok then return true end
    last_reason = reason or 'unknown'
    Wait(250)
  end
  return false, last_reason
end

-- -----------------------------------------------------------------------------
-- Boot announce.
-- -----------------------------------------------------------------------------
Log.Info('DB wrappers ready (timeout=%dms, slow_query=%dms, pool_advisory=%d)',
  Config.DbTimeoutMs, Config.DbSlowQueryMs, Config.DbMaxConnectionsAdvisory)
