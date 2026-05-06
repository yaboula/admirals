-- =============================================================================
-- SONAR Bank App — boot/cron.lua
-- =============================================================================
-- Long-running background tasks:
--
--   1. Idempotency orphan purge — every Config.Idempotency.CRON_PURGE_INTERVAL_MS
--      (default 5 min). Calls Idempotency.PurgeOrphans which deletes rows
--      stuck in 'in_flight' for > ORPHAN_PURGE_AGE_MIN (30 min). M005 mandate.
--
--   2. Recurring charge sweep — every RECURRING_INTERVAL_MS (default 60 s).
--      Calls RecurringService.ChargeDue which uses TransferService.ExecuteAsSystem
--      (privileged path src=0). Bug fix per Founder directive — recurring
--      subscriptions charge even when borrower is offline.
--
--   3. Watchdog snapshot heartbeat — every WATCHDOG_INTERVAL_MS (default 5 min).
--      Logs Perf.CheckBootstrapHealth + Audit.GetStats for DevOps observability.
--
-- Each loop is independently startable + stoppable. Stop() cancels the running
-- flag — current iteration completes, next iteration sees stopped flag + exits.
-- =============================================================================

BankApp.boot = BankApp.boot or {}
BankApp.boot.cron = {}
local C = BankApp.boot.cron

local Config = BankApp.Config

local Idempotency       = BankApp.lib.idempotency
local Perf              = BankApp.lib.perf
local Audit             = BankApp.lib.audit
local Errors            = BankApp.lib.errors

local RecurringService  = BankApp.services.recurring

-- -----------------------------------------------------------------------------
-- §1. Tunables (per BANK-BE.LOCK.R2)
-- -----------------------------------------------------------------------------

local INTERVAL_IDEMPOTENCY_PURGE_MS = Config.Idempotency.CRON_PURGE_INTERVAL_MS or (5 * 60 * 1000)
local INTERVAL_RECURRING_MS         = 60 * 1000           -- 60 s sweep cadence
local INTERVAL_WATCHDOG_MS          = 5 * 60 * 1000       -- 5 min heartbeat
local RECURRING_BATCH_LIMIT         = 50

-- -----------------------------------------------------------------------------
-- §2. State
-- -----------------------------------------------------------------------------

local _running    = false
local _stats = {
  idempotency_purges  = 0,
  idempotency_purged_rows = 0,
  recurring_runs      = 0,
  recurring_charged   = 0,
  recurring_failed    = 0,
  watchdog_heartbeats = 0,
  last_started_ms     = 0,
  last_stopped_ms     = 0,
}

local function log(level, msg)
  print(('%s[CRON][%s] %s'):format(Config.Logging.PREFIX, level, msg))
end

-- -----------------------------------------------------------------------------
-- §3. Loop builders (Citizen.CreateThread)
-- -----------------------------------------------------------------------------

local function loop_idempotency_purge()
  Citizen.CreateThread(function()
    while _running do
      Citizen.Wait(INTERVAL_IDEMPOTENCY_PURGE_MS)
      if not _running then break end
      local ok, purged_or_err = pcall(Idempotency.PurgeOrphans)
      if ok then
        local n = tonumber(purged_or_err) or 0
        _stats.idempotency_purges = _stats.idempotency_purges + 1
        _stats.idempotency_purged_rows = _stats.idempotency_purged_rows + n
        if n > 0 then
          log('INFO', ('idempotency purged %d orphan(s).'):format(n))
        end
      else
        log('WARN', ('idempotency purge raised: %s'):format(tostring(purged_or_err):sub(1, 200)))
      end
    end
  end)
end

local function loop_recurring()
  Citizen.CreateThread(function()
    while _running do
      Citizen.Wait(INTERVAL_RECURRING_MS)
      if not _running then break end
      local ok, charged, failed = pcall(RecurringService.ChargeDue, RECURRING_BATCH_LIMIT)
      if ok then
        _stats.recurring_runs = _stats.recurring_runs + 1
        if (charged or 0) > 0 or (failed or 0) > 0 then
          _stats.recurring_charged = _stats.recurring_charged + (charged or 0)
          _stats.recurring_failed  = _stats.recurring_failed + (failed or 0)
          log('INFO', ('recurring sweep: charged=%d failed=%d'):format(charged or 0, failed or 0))
        end
      else
        log('WARN', ('recurring sweep raised: %s'):format(tostring(charged):sub(1, 200)))
      end
    end
  end)
end

local function loop_watchdog()
  Citizen.CreateThread(function()
    while _running do
      Citizen.Wait(INTERVAL_WATCHDOG_MS)
      if not _running then break end
      local boot_health = Perf.CheckBootstrapHealth()
      local audit_stats = Audit.GetStats()
      _stats.watchdog_heartbeats = _stats.watchdog_heartbeats + 1
      log('INFO', ('watchdog: bootstrap p99=%.1fms (budget=%dms, healthy=%s, breaches=%d) audit q=%d written=%d dropped=%d'):format(
        boot_health.p99_ms or 0,
        boot_health.budget_ms or 0,
        tostring(boot_health.healthy),
        boot_health.breaches or 0,
        audit_stats.queue_size or 0,
        audit_stats.written or 0,
        audit_stats.dropped or 0
      ))
    end
  end)
end

-- -----------------------------------------------------------------------------
-- §4. Public API
-- -----------------------------------------------------------------------------

--- Start — invoked by boot/init.lua phase 2.
function C.Start()
  if _running then return end
  _running = true
  _stats.last_started_ms = os.time() * 1000

  loop_idempotency_purge()
  loop_recurring()
  loop_watchdog()

  log('INFO', ('cron loops started (idempotency=%dms, recurring=%dms, watchdog=%dms).'):format(
    INTERVAL_IDEMPOTENCY_PURGE_MS, INTERVAL_RECURRING_MS, INTERVAL_WATCHDOG_MS))
end

--- Stop — graceful shutdown (current iterations complete naturally).
function C.Stop()
  if not _running then return end
  _running = false
  _stats.last_stopped_ms = os.time() * 1000
  log('INFO', 'cron loops stopping (running flag = false).')
end

--- GetStats — diagnostic accessor.
function C.GetStats()
  return {
    running = _running,
    intervals_ms = {
      idempotency_purge = INTERVAL_IDEMPOTENCY_PURGE_MS,
      recurring         = INTERVAL_RECURRING_MS,
      watchdog          = INTERVAL_WATCHDOG_MS,
    },
    counters = _stats,
  }
end

return C
