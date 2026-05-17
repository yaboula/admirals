-- =============================================================================
-- SONAR Bank App — boot/init.lua
-- =============================================================================
-- Resource lifecycle orchestrator. Runs in 4 phases:
--
--   Phase 1 — defensive_abort gates:
--     - HMAC secret load (M006 mandatory en producción)
--     - HMAC self-test (RFC 4231 SHA256 vector)
--     - Smoke test invocation (boot/smoke.lua)
--     If ANY phase 1 step fails → resource refuses to register callbacks +
--     emits AUTH_DENIED audit + prints fatal banner. The rest of boot is
--     skipped to prevent an unsafe partial-boot state.
--
--   Phase 2 — long-lived workers:
--     - Audit.StartFlushTicker  (batched audit ledger flush every 1s)
--     - boot/cron.lua starts cron loops
--
--   Phase 3 — event/state hooks:
--     - state/statebags.Init        (playerJoining → publish CP1-B)
--     - events/netevents.RegisterServerListeners (defensive C2S NetEvent listeners)
--     - nui/bridge.Init
--
--   Phase 4 — startup banner + diagnostics dump.
--
-- This file is loaded LAST in fxmanifest (after all callbacks/* + boot/cron +
-- boot/smoke) to guarantee everything is wired before workers start.
-- =============================================================================

BankApp.boot = BankApp.boot or {}
local B = BankApp.boot

local Config = BankApp.Config
local HMAC   = BankApp.lib.hmac
local Audit  = BankApp.lib.audit
local DB     = BankApp.lib.db

local STARTED_AT_MS = os.time() * 1000

-- -----------------------------------------------------------------------------
-- §1. Logging helpers
-- -----------------------------------------------------------------------------

local function log(level, msg)
  print(('%s[%s] %s'):format(Config.Logging.PREFIX, level, msg))
end

local function banner(line)
  print(('%s %s'):format(Config.Logging.PREFIX, line))
end

-- -----------------------------------------------------------------------------
-- §2. Phase 1 — defensive_abort gates
-- -----------------------------------------------------------------------------

local _boot_status = {
  phase             = 'init',
  hmac_loaded       = false,
  hmac_selftest     = false,
  smoke_ok          = false,
  callbacks_count   = 0,
  workers_started   = false,
  fatal_abort       = false,
  fatal_reason      = nil,
  started_at_ms     = STARTED_AT_MS,
}

local function fatal_abort(reason)
  _boot_status.fatal_abort  = true
  _boot_status.fatal_reason = reason
  banner('================================================================')
  banner('  ⛔ FATAL BOOT ABORT — sonar_bank_app refusing to start')
  banner('  Reason: ' .. tostring(reason))
  banner('  Callbacks WILL NOT be registered. State remains uninitialized.')
  banner('  Fix the underlying issue and restart this resource.')
  banner('================================================================')
end

local function phase1_defensive_abort()
  _boot_status.phase = 'phase_1_defensive'

  -- §2.1 HMAC secret load
  local hmac_ok, hmac_err = HMAC.LoadSecret()
  if not hmac_ok then
    fatal_abort(('HMAC secret load failed: %s'):format(hmac_err and hmac_err.message or 'unknown'))
    return false
  end
  _boot_status.hmac_loaded = true
  log('INFO', 'HMAC secret loaded (convar OK, length validated).')

  -- §2.2 HMAC self-test (RFC 4231 SHA256)
  local st_ok, st_err = HMAC.SelfTest()
  if not st_ok then
    fatal_abort(('HMAC self-test failed: %s'):format(st_err or 'unknown'))
    return false
  end
  _boot_status.hmac_selftest = true
  log('INFO', 'HMAC self-test passed (RFC 4231 vector verified).')

  -- §2.3 Smoke test (boot/smoke.lua wired separately)
  if BankApp.boot.smoke and type(BankApp.boot.smoke.Run) == 'function' then
    local report = BankApp.boot.smoke.Run()
    _boot_status.smoke_ok = report.ok
    if not report.ok then
      fatal_abort(('Smoke test failed: %s'):format(report.summary or 'unknown'))
      return false
    end
    log('INFO', ('Smoke test passed (%d/%d checks).'):format(report.passed, report.total))
  else
    log('WARN', 'boot/smoke.lua not loaded — skipping smoke test (defensive degraded).')
  end

  return true
end

-- -----------------------------------------------------------------------------
-- §3. Phase 2 — long-lived workers
-- -----------------------------------------------------------------------------

local function phase2_workers()
  _boot_status.phase = 'phase_2_workers'

  -- Audit ticker (1s batched flush)
  Audit.StartFlushTicker()
  log('INFO', ('Audit flush ticker started (interval=%dms, batch_max=%d).'):format(
    Config.Audit.BATCH_FLUSH_INTERVAL_MS, Config.Audit.BATCH_MAX_SIZE))

  -- Cron loops
  if BankApp.boot.cron and type(BankApp.boot.cron.Start) == 'function' then
    BankApp.boot.cron.Start()
    log('INFO', 'Cron loops started (idempotency purge + recurring charge).')
  else
    log('WARN', 'boot/cron.lua not loaded — cron loops disabled (degraded).')
  end

  _boot_status.workers_started = true
end

-- -----------------------------------------------------------------------------
-- §4. Phase 3 — event/state hooks
-- -----------------------------------------------------------------------------

local function phase3_hooks()
  _boot_status.phase = 'phase_3_hooks'

  -- M004 §2.2.2 — playerJoining lazy publish
  if BankApp.state and BankApp.state.statebags and BankApp.state.statebags.Init then
    BankApp.state.statebags.Init()
    log('INFO', 'StateBags hook bound (playerJoining → CP1-B publish).')
  end

  -- Defensive C2S NetEvent listeners (audit-on-abuse)
  if BankApp.events and BankApp.events.netevents and BankApp.events.netevents.RegisterServerListeners then
    BankApp.events.netevents.RegisterServerListeners()
    log('INFO', 'NetEvents defensive C2S listeners registered.')
  end

  -- NUI bridge
  if BankApp.nui and BankApp.nui.bridge and BankApp.nui.bridge.Init then
    BankApp.nui.bridge.Init()
    log('INFO', 'NUI bridge initialized (client config snapshot ready).')
  end

  -- Banker (Bank Owner Panel) — bootstrap initial CEO if employees table empty
  if BankApp.services
     and BankApp.services.banker
     and BankApp.services.banker.employees
     and type(BankApp.services.banker.employees.EnsureInitialCEO) == 'function'
     and Config.Banker and Config.Banker.Enabled then
    local ok, msg = BankApp.services.banker.employees.EnsureInitialCEO()
    if ok then
      log('INFO', 'Banker: initial CEO bootstrapped from convar/config.')
    else
      log('INFO', ('Banker: initial CEO bootstrap skipped (%s).'):format(tostring(msg)))
    end
  end
end

-- -----------------------------------------------------------------------------
-- §5. Phase 4 — banner + diagnostics
-- -----------------------------------------------------------------------------

local function count_callbacks()
  if not BankApp.callbacks or not BankApp.callbacks._wrap then return 0 end
  local list = BankApp.callbacks._wrap.ListRegistered() or {}
  local n = 0
  for _ in pairs(list) do n = n + 1 end
  return n
end

local function phase4_banner()
  _boot_status.phase = 'ready'
  _boot_status.callbacks_count = count_callbacks()

  banner('================================================================')
  banner('  ✅ sonar_bank_app — booted successfully')
  banner(('  version          %s'):format(Config.RESOURCE_VERSION))
  banner(('  phase            %s'):format(Config.PHASE))
  banner(('  callbacks        %d registered'):format(_boot_status.callbacks_count))
  banner(('  HMAC loaded      %s'):format(_boot_status.hmac_loaded and 'yes' or 'NO'))
  banner(('  HMAC self-test   %s'):format(_boot_status.hmac_selftest and 'PASS' or 'FAIL'))
  banner(('  smoke test       %s'):format(_boot_status.smoke_ok and 'PASS' or 'FAIL'))
  banner(('  workers started  %s'):format(_boot_status.workers_started and 'yes' or 'NO'))
  banner(('  ready in         %d ms'):format((os.time() * 1000) - STARTED_AT_MS))
  banner('================================================================')
end

-- -----------------------------------------------------------------------------
-- §6. Boot orchestration
-- -----------------------------------------------------------------------------

--- Run — main boot entry. Wired to onResourceStart (current resource).
function B.Run()
  banner('Booting sonar_bank_app … (R1-hardened Phase A)')

  if not phase1_defensive_abort() then return end
  phase2_workers()
  phase3_hooks()
  phase4_banner()
end

--- GetStatus — diagnostic accessor.
function B.GetStatus()
  return _boot_status
end

--- Shutdown — graceful stop on resource stop.
function B.Shutdown()
  log('INFO', 'Shutting down — draining audit queue + stopping cron.')

  if BankApp.boot.cron and type(BankApp.boot.cron.Stop) == 'function' then
    BankApp.boot.cron.Stop()
  end

  -- Drain audit queue (best-effort)
  if Audit.StopFlushTicker then Audit.StopFlushTicker() end

  banner('sonar_bank_app stopped — audit drained, cron halted.')
end

-- -----------------------------------------------------------------------------
-- §7. Wire to FiveM resource lifecycle
-- -----------------------------------------------------------------------------

AddEventHandler('onResourceStart', function(resource_name)
  if resource_name ~= GetCurrentResourceName() then return end
  -- Brief delay para que ox_lib + sonar_core + bridges binden completamente.
  Citizen.SetTimeout(500, function()
    B.Run()
  end)
end)

AddEventHandler('onResourceStop', function(resource_name)
  if resource_name ~= GetCurrentResourceName() then return end
  B.Shutdown()
end)

return B
