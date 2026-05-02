-- =============================================================================
-- Admirals Core — server/init.lua
--
-- Boot orchestration. LAST script en server_scripts del fxmanifest.
--
-- Secuencia boot (deferred 1 tick para permitir que todos los subsistemas
-- hayan registrado sus globals):
--
--   1. Wait Bridges.WaitReady (Config.BridgesWaitTimeoutMs)
--      — hard-fail si timeout (admirals_bridges no arrancó correctamente).
--   2. Wait oxmysql ready via Admirals.DB.WaitReady
--      — hard-fail si timeout (DB no conecta).
--   3. Admirals.Migrations.RunAll()
--      — hard-fail si error (schema corrupto).
--   4. Mark Admirals.Core._ready = true.
--   5. Emit admirals:core:ready (TriggerEvent + Admirals.Bus.Publish).
--   6. Print boot report (versiones, migrations aplicadas, log level).
--
-- Admin commands:
--   /admirals_core_status — muestra ready state + version + migrations list.
--
-- Exports:
--   IsReady()            → boolean
--   WaitReady(timeout?)  → boolean
--   Version()            → string
--   GetMigrationReport() → migrations RunAll report o nil si aún no run.
--
-- Referencias SSoT:
--   docs/technical/03_db_schema.md §16 (migrations runner pipeline).
--   docs/technical/04_api_contracts.md §6 (DB access).
-- =============================================================================

Admirals = Admirals or {}
Admirals.Core = Admirals.Core or {}

local Config = Admirals.Config
local Log = Admirals.Log
local Metrics = Admirals.Metrics
local DB = Admirals.DB
local Bus = Admirals.Bus
local Migrations = Admirals.Migrations
local Core = Admirals.Core

-- Internal state.
local _boot_started_at = 0
local _boot_completed_at = 0
local _migration_report = nil

-- -----------------------------------------------------------------------------
-- Public — IsReady.
-- -----------------------------------------------------------------------------
function Core.IsReady()
  return Core._ready == true
end

-- -----------------------------------------------------------------------------
-- Public — WaitReady.
-- -----------------------------------------------------------------------------
function Core.WaitReady(timeout_ms)
  timeout_ms = timeout_ms or 30000
  local start = GetGameTimer()
  while not Core._ready and (GetGameTimer() - start) < timeout_ms do
    Wait(50)
  end
  return Core._ready == true
end

-- -----------------------------------------------------------------------------
-- Public — Version.
-- -----------------------------------------------------------------------------
function Core.Version()
  return Config.Version
end

-- -----------------------------------------------------------------------------
-- Public — GetMigrationReport.
-- -----------------------------------------------------------------------------
function Core.GetMigrationReport()
  return _migration_report
end

-- Register exports para que otros resources llamen:
--   exports.admirals_core:IsReady()
--   exports.admirals_core:WaitReady(10000)
exports('IsReady', Core.IsReady)
exports('WaitReady', Core.WaitReady)
exports('Version', Core.Version)
exports('GetMigrationReport', Core.GetMigrationReport)

-- =============================================================================
-- Cross-resource exports — para consumers vía lib/admirals.lua (S1.1+).
--
-- Los consumers no pueden leer _G.Admirals (Lua VMs aisladas). Estos exports
-- exponen las APIs de Logger / DB / Bus / Rate / Metrics como surface tipada
-- thin que la lib helper consume. Resource attribution se preserva mediante
-- prefijo `[<resource>]` en logs (LogInfo etc añaden el wrapper).
--
-- Naming convention: <Subsystem><Method>, e.g. DBFetchOne, BusPublish, etc.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- DB layer (6 exports — pass-through a Admirals.DB).
-- ----------------------------------------------------------------------------
exports('DBFetchOne',     function(query, params) return DB.FetchOne(query, params) end)
exports('DBFetchAll',     function(query, params) return DB.FetchAll(query, params) end)
exports('DBExecute',      function(query, params) return DB.Execute(query, params) end)
exports('DBInsert',       function(query, params) return DB.Insert(query, params) end)
exports('DBScalar',       function(query, params) return DB.Scalar(query, params) end)
exports('DBTransaction',  function(queries)        return DB.Transaction(queries) end)

-- ----------------------------------------------------------------------------
-- Bus layer (4 exports).
--
-- BusPublish: dispatch a subscribers locales en admirals_core's VM + fanout
--   server-wide via TriggerEvent('admirals_lib:dispatch', event, payload) para
--   que consumers que cargan lib/admirals.lua reciban en sus AddEventHandler.
--   Wrap del Bus.Publish original installed below (line ~155).
--
-- BusRegisterConsumerInterest: tracking ligero metric "qué resources subscriben
--   a qué evento" — informativo (no bloquea dispatch).
--
-- BusRegisterSchemaByName: hook futuro S2+ para validators by name (no-op S1.1).
--
-- Bus.Subscribe / Unsubscribe NO se exportan — function refs cross-VM frágil.
-- En su lugar, lib/admirals.lua mantiene _local_subs en VM consumer + escucha
-- TriggerEvent fanout que Bus.Publish dispara below.
-- ----------------------------------------------------------------------------
exports('BusPublish',                  function(event_name, payload, opts) return Bus.Publish(event_name, payload, opts) end)
exports('BusStats',                    function() return Bus.Stats() end)
exports('BusRegisterConsumerInterest', function(event_name, resource_name)
  -- Solo metric tracking — no impacta dispatch (que va via TriggerEvent fanout).
  Metrics.Counter('bus.consumer_interest_registered')
  Log.Debug('Bus consumer interest: %s ← %s', event_name, tostring(resource_name))
end)
exports('BusRegisterSchemaByName', function(event_name, validator_name)
  -- Phase 1 no-op — S2+ implementará schema registry by name.
  Log.Debug('BusRegisterSchemaByName ignored (no-op S1.1): %s ← %s',
    event_name, tostring(validator_name))
end)

-- ----------------------------------------------------------------------------
-- Rate limiter (4 exports).
-- ----------------------------------------------------------------------------
exports('RateCheck',          function(identity, bucket_key) return Admirals.Rate.Check(identity, bucket_key) end)
exports('RateRegisterBucket', function(key, def)              return Admirals.Rate.RegisterBucket(key, def) end)
exports('RateReset',          function(identity, bucket_key) return Admirals.Rate.Reset(identity, bucket_key) end)
exports('RateStats',          function() return Admirals.Rate.Stats() end)

-- ----------------------------------------------------------------------------
-- Logger (8 exports).
--
-- Wrap añade prefijo [resource] para preservar atribución cross-VM. La lib
-- helper pre-formatea con string.format y pasa msg literal — los exports NO
-- aceptan varargs (FiveM Lua exports cross-VM no preservan vararg semántica
-- de forma 100% fiable; mejor pasar string ya formateado).
--
-- Si el caller usa el _G.Log directo dentro de admirals_core, mantiene la
-- API original con varargs (no afectado por estos wrappers).
-- ----------------------------------------------------------------------------
local function _log_wrap(level_fn)
  return function(resource, msg)
    level_fn('[%s] %s', tostring(resource or '?'), tostring(msg or ''))
  end
end
exports('LogDebug', _log_wrap(Log.Debug))
exports('LogInfo',  _log_wrap(Log.Info))
exports('LogWarn',  _log_wrap(Log.Warn))
exports('LogError', _log_wrap(Log.Error))

-- LogAudit recibe un table {category, action, actor?, target?, payload?, resource?}
-- Pass-through directo (la lib helper ya decora entry.resource).
exports('LogAudit',    function(entry) return Log.Audit(entry) end)
exports('LogSetLevel', function(level) return Log.SetLevel(level) end)
exports('LogGetLevel', function() return Log.GetLevel() end)
exports('LogSize',     function() return Log.Size() end)

-- ----------------------------------------------------------------------------
-- Metrics (6 exports).
-- ----------------------------------------------------------------------------
exports('MetricsCounter',  function(key, delta)  return Metrics.Counter(key, delta) end)
exports('MetricsGauge',    function(key, value)  return Metrics.Gauge(key, value) end)
exports('MetricsObserve',  function(key, value)  return Metrics.Observe(key, value) end)
exports('MetricsGet',      function(key) return Metrics.Get(key) end)
exports('MetricsSnapshot', function() return Metrics.Snapshot() end)
exports('MetricsReset',    function() return Metrics.Reset() end)

-- ----------------------------------------------------------------------------
-- Bus.Publish wrap — añade fanout server-wide cross-resource via TriggerEvent.
--
-- Comportamiento:
--   1. Llama Bus.Publish original (dispatch local + audit + metrics + decoración).
--   2. Si OK, dispara TriggerEvent('admirals_lib:dispatch', event_name, payload)
--      → todos los resources con lib/admirals.lua cargada reciben el dispatch
--      en su AddEventHandler local y filtran por _local_subs[event_name].
--
-- Esto desacopla la pub/sub cross-resource del paso de function refs cross-VM
-- (que es frágil en FiveM Lua). El payload está garantizado JSON-serializable
-- per §02 §1.4 — TriggerEvent lo cruza VMs sin issues.
-- ----------------------------------------------------------------------------
local _bus_publish_original = Bus.Publish
Bus.Publish = function(event_name, payload, opts)
  local ok = _bus_publish_original(event_name, payload, opts)
  if ok then
    -- Server-wide fanout — atómico per FiveM event dispatch. Errors en handlers
    -- consumer son contained en sus pcalls (lib/admirals.lua _local_subs handler).
    TriggerEvent('admirals_lib:dispatch', event_name, payload)
  end
  return ok
end

-- -----------------------------------------------------------------------------
-- Boot report — ASCII panel de cierre, coherente con admirals_bridges §10.4.
-- -----------------------------------------------------------------------------
local function _print_boot_report()
  local applied = Migrations.ListApplied()
  local divider = '^5═══════════════════════════════════════════════════════════^7'
  local thin    = '^5───────────────────────────────────────────────────────────^7'
  local boot_ms = _boot_completed_at - _boot_started_at

  print('')
  print(divider)
  print(string.format('^5  Admirals Core v%s — Boot Report^7', Config.Version))
  print(divider)
  print(string.format('  Env        : %s', Config.Env))
  print(string.format('  Log level  : %s  (ring=%d)',
    Log.GetLevel(), Config.LogRingBufferSize))
  print(string.format('  DB         : oxmysql ready, timeout=%dms, slow_q=%dms',
    Config.DbTimeoutMs, Config.DbSlowQueryMs))
  print(string.format('  Bus        : audit=%s, async_threshold=%dms',
    Config.BusAuditMode, Config.BusAsyncThresholdMs))
  print(string.format('  Boot time  : %dms', boot_ms))
  print(thin)
  print(string.format('  Migrations : %d applied', #applied))
  for _, m in ipairs(applied) do
    print(string.format('    ^2✓^7 %03d %s  (%dms, %s)',
      m.version, m.filename, m.duration_ms or 0,
      os.date('%Y-%m-%d %H:%M:%S', m.applied_at)))
  end
  print(divider)
  print('^2  admirals_core is READY^7')
  print(divider)
  print('')
end

-- -----------------------------------------------------------------------------
-- Admin command — /admirals_core_status.
-- -----------------------------------------------------------------------------
local function _is_admin(source)
  if source == 0 then return true end
  return IsPlayerAceAllowed(source, Config.AdminAcePrefix .. 'core_status')
end

RegisterCommand('admirals_core_status', function(source)
  if not _is_admin(source) then return end
  print(string.format('^5[Admirals Core] v%s | ready=%s | boot_ms=%d^7',
    Config.Version, tostring(Core._ready),
    (_boot_completed_at > 0) and (_boot_completed_at - _boot_started_at) or 0))
  if _migration_report then
    print(string.format('  Migrations: %d applied, %d skipped, %d errors',
      #_migration_report.applied, #_migration_report.skipped,
      #_migration_report.errors))
  end
  local bus_stats = Bus.Stats()
  print(string.format('  Bus: %d events, %d subscribers, %d schemas',
    bus_stats.distinct_events, bus_stats.total_subscribers, bus_stats.registered_schemas))
  local rate_stats = Admirals.Rate.Stats()
  print(string.format('  Rate: %d buckets, %d active identity-bucket pairs',
    rate_stats.registered_buckets, rate_stats.tracked_identity_bucket_pairs))
  print(string.format('  Log ring: %d entries', Log.Size()))
end, true)

-- =============================================================================
-- Boot sequence.
-- =============================================================================
CreateThread(function()
  Wait(0)  -- yield to allow all script_server_scripts to finish load.
  _boot_started_at = GetGameTimer()

  Log.Info('admirals_core v%s booting...', Config.Version)

  -- -------------------------------------------------------------------------
  -- 1. Wait Bridges ready.
  -- -------------------------------------------------------------------------
  Log.Debug('Waiting for admirals_bridges...')
  local bridges_exports_ok, bridges = pcall(function()
    return exports.admirals_bridges
  end)
  if not bridges_exports_ok then
    Log.Error('admirals_bridges exports not available — dependency broken')
    error('[admirals_core] admirals_bridges not started', 0)
  end

  -- Cross-resource: each FiveM resource has its own Lua VM, so _G.Bridges
  -- is NOT shared. Consumers MUST go through exports.admirals_bridges.
  local br_ready = false
  local wait_ok, wait_err = pcall(function()
    br_ready = exports.admirals_bridges:WaitReady(Config.BridgesWaitTimeoutMs) == true
  end)
  if not wait_ok then
    Log.Error('exports.admirals_bridges:WaitReady call failed: %s', tostring(wait_err))
    error('[admirals_core] Bridges export call failed', 0)
  end

  if not br_ready then
    Log.Error('admirals_bridges not ready after %dms — aborting boot',
      Config.BridgesWaitTimeoutMs)
    error('[admirals_core] Bridges not ready', 0)
  end

  -- Snapshot active adapters for boot report.
  local active_ok, active_snap = pcall(function()
    return exports.admirals_bridges:GetActive()
  end)
  if active_ok and type(active_snap) == 'table' then
    local parts = {}
    for k, v in pairs(active_snap) do parts[#parts + 1] = k .. '=' .. tostring(v) end
    Log.Info('admirals_bridges ready. Active: %s', table.concat(parts, ', '))
  else
    Log.Info('admirals_bridges ready')
  end

  -- -------------------------------------------------------------------------
  -- 2. Wait DB ready (oxmysql conectado).
  -- -------------------------------------------------------------------------
  Log.Debug('Waiting for oxmysql...')
  local db_ok, db_reason = DB.WaitReady(Config.BridgesWaitTimeoutMs)
  if not db_ok then
    Log.Error('DB not reachable after %dms: %s', Config.BridgesWaitTimeoutMs,
      tostring(db_reason))
    error('[admirals_core] DB not ready: ' .. tostring(db_reason), 0)
  end
  Log.Info('DB ready (oxmysql ping OK)')

  -- -------------------------------------------------------------------------
  -- 3. Run migrations.
  -- -------------------------------------------------------------------------
  local ok_mig, mig_or_err = pcall(Migrations.RunAll)
  if not ok_mig then
    Log.Error('Migrations failed: %s', tostring(mig_or_err))
    error('[admirals_core] Migrations failed', 0)
  end
  _migration_report = mig_or_err

  if #_migration_report.errors > 0 then
    Log.Error('Migrations run finished with %d errors', #_migration_report.errors)
    if Config.MigrationsFailFast then
      error('[admirals_core] Migrations reported errors', 0)
    end
  end

  -- -------------------------------------------------------------------------
  -- 4. Mark ready.
  -- -------------------------------------------------------------------------
  Core._ready = true
  _boot_completed_at = GetGameTimer()

  Metrics.Counter('core.boot_success')
  Metrics.Gauge('core.boot_duration_ms', _boot_completed_at - _boot_started_at)

  -- -------------------------------------------------------------------------
  -- 5. Emit ready event — 2 canales:
  --    a) TriggerEvent nativo FiveM para otros resources cross-resource.
  --    b) Admirals.Bus.Publish para sub interno Admirals.
  -- -------------------------------------------------------------------------
  TriggerEvent(Config.CoreReadyEventName, {
    version = Config.Version,
    boot_duration_ms = _boot_completed_at - _boot_started_at,
    migrations_applied = #_migration_report.applied,
  })
  Bus.Publish(Config.CoreReadyEventName, {
    version = Config.Version,
    boot_duration_ms = _boot_completed_at - _boot_started_at,
    migrations_applied = #_migration_report.applied,
  }, { broadcast_client = -1 })

  -- -------------------------------------------------------------------------
  -- 6. Boot report.
  -- -------------------------------------------------------------------------
  _print_boot_report()
end)
