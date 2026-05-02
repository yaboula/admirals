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
