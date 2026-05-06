-- =============================================================================
-- SONAR Bank App — lib/perf.lua
-- =============================================================================
-- Performance budget tracker per callback / operation.
--
-- Goals:
--   1. Measure latency (ms) of every callback handler invocation.
--   2. Compute rolling p50 / p95 / p99 per callback_id.
--   3. Emit WARN log si latency exceeds tier budget (Config.PerfBudgets).
--   4. Emit metrics for DevOps observability (REQ-FE-001 bootstrap p99 < 80ms
--      enforcement).
--   5. Ring buffer (last 1000 samples per callback) — bounded memory.
--
-- API:
--   StartTimer()       → opaque timer handle
--   EndTimer(handle, callback_id, opts)
--                      → records sample + checks budget + returns elapsed_ms
--   Wrap(callback_id, fn) → returns wrapped fn that auto-times
--   GetStats(callback_id) → { count, mean_ms, p50, p95, p99, breaches }
--   GetAllStats()      → table of all callback_id stats
--   ResetStats(callback_id|nil)
--
-- Deps: lib/enums + config (no DB / no errors / no audit).
-- =============================================================================

BankApp.lib.perf = {}
local M = BankApp.lib.perf

local Enums  = BankApp.lib.enums
local Config = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. Internal storage (ring buffers per callback_id)
-- -----------------------------------------------------------------------------

local RING_CAPACITY = 1000  -- samples per callback (bounded memory)

-- Stats[callback_id] = {
--   samples = { ms1, ms2, ... },   -- ring buffer
--   write_idx = 1,                  -- next write position
--   count = 0,                      -- total observations (may exceed RING_CAPACITY)
--   sum_ms = 0,                     -- running sum (for mean)
--   max_ms = 0,                     -- all-time max
--   breaches = 0,                   -- budget violations
--   tier = string|nil,              -- cached tier of this callback
-- }
local _stats = {}

local function ensure_bucket(callback_id)
  local b = _stats[callback_id]
  if b then return b end
  b = {
    samples = {},
    write_idx = 1,
    count = 0,
    sum_ms = 0,
    max_ms = 0,
    breaches = 0,
    tier = nil,
  }
  _stats[callback_id] = b
  return b
end

-- High-resolution monotonic timestamp in milliseconds.
-- GetGameTimer() returns uptime ms (integer); os.clock() fractional seconds.
-- Use os.clock() for sub-ms resolution.
local function hrtime_ms()
  return os.clock() * 1000.0
end

-- -----------------------------------------------------------------------------
-- §2. Tier → budget resolution
-- -----------------------------------------------------------------------------

local function tier_budget_ms(tier, callback_id)
  -- Special-case bootstrap snapshot (REQ-FE-001 strict p99 < 80ms)
  if callback_id == 'C001b' or callback_id == 'sonar:bank:bootstrap:snapshot' then
    return Config.PerfBudgets.BOOTSTRAP_P99_MS or 80
  end
  -- Special-case recent recipients
  if callback_id == 'sonar:bank:transfer:recentRecipients' then
    return Config.PerfBudgets.RECENT_RECIPIENTS_P99_MS or 30
  end

  if tier == Enums.TIER.TIER_1_READ then
    return Config.PerfBudgets.TIER_1_READ_P99_MS
  elseif tier == Enums.TIER.TIER_2_WRITE then
    return Config.PerfBudgets.TIER_2_WRITE_P99_MS
  elseif tier == Enums.TIER.TIER_3_ADMIN then
    return Config.PerfBudgets.TIER_3_ADMIN_P99_MS
  end
  return Config.PerfBudgets.TIER_2_WRITE_P99_MS or 200
end

-- -----------------------------------------------------------------------------
-- §3. Public timing API
-- -----------------------------------------------------------------------------

--- StartTimer: returns opaque handle.
---@return table { start_ms = number }
function M.StartTimer()
  return { start_ms = hrtime_ms() }
end

--- EndTimer: record sample, check budget, return elapsed_ms.
---@param handle table from StartTimer
---@param callback_id string e.g. 'C001b'
---@param opts table|nil { tier=string, suppress_warn=boolean }
---@return number elapsed_ms
---@return boolean budget_ok (false si breach)
function M.EndTimer(handle, callback_id, opts)
  if type(handle) ~= 'table' or type(handle.start_ms) ~= 'number' then
    return 0, true
  end
  opts = opts or {}

  local elapsed_ms = hrtime_ms() - handle.start_ms
  if elapsed_ms < 0 then elapsed_ms = 0 end

  local b = ensure_bucket(callback_id)
  if opts.tier then b.tier = opts.tier end

  -- Ring buffer write
  b.samples[b.write_idx] = elapsed_ms
  b.write_idx = (b.write_idx % RING_CAPACITY) + 1
  b.count = b.count + 1
  b.sum_ms = b.sum_ms + elapsed_ms
  if elapsed_ms > b.max_ms then b.max_ms = elapsed_ms end

  -- Budget check
  local budget = tier_budget_ms(b.tier, callback_id)
  local ok = elapsed_ms <= budget
  if not ok then
    b.breaches = b.breaches + 1
    if not opts.suppress_warn and Config.Features.ENABLE_PERF_ALERTS then
      print(('[%s][PERF] budget breach: callback=%s elapsed=%.2fms budget=%dms tier=%s'):format(
        Config.Logging.PREFIX, callback_id, elapsed_ms, budget, tostring(b.tier)))
    end
  end

  return elapsed_ms, ok
end

--- Wrap: decorator. Returns wrapped fn that auto-measures.
---@param callback_id string
---@param tier string|nil Enums.TIER value
---@param fn function the handler
---@return function wrapped fn
function M.Wrap(callback_id, tier, fn)
  return function(...)
    local handle = M.StartTimer()
    local results = { fn(...) }
    M.EndTimer(handle, callback_id, { tier = tier })
    return table.unpack(results)
  end
end

-- -----------------------------------------------------------------------------
-- §4. Stats — percentile computation
-- -----------------------------------------------------------------------------

local function percentile(sorted, pct)
  local n = #sorted
  if n == 0 then return 0 end
  local idx = math.ceil(n * pct / 100)
  if idx < 1 then idx = 1 end
  if idx > n then idx = n end
  return sorted[idx]
end

--- GetStats: rolling stats para callback_id.
---@param callback_id string
---@return table|nil
function M.GetStats(callback_id)
  local b = _stats[callback_id]
  if not b then return nil end

  -- Snapshot samples (ring buffer → linear array)
  local sorted = {}
  for i = 1, #b.samples do
    sorted[i] = b.samples[i]
  end
  table.sort(sorted)

  local mean_ms = b.count > 0 and (b.sum_ms / b.count) or 0
  local sample_n = #sorted

  return {
    callback_id = callback_id,
    tier        = b.tier,
    count       = b.count,
    sample_n    = sample_n,
    mean_ms     = mean_ms,
    max_ms      = b.max_ms,
    p50_ms      = percentile(sorted, 50),
    p95_ms      = percentile(sorted, 95),
    p99_ms      = percentile(sorted, 99),
    breaches    = b.breaches,
    budget_ms   = tier_budget_ms(b.tier, callback_id),
  }
end

--- GetAllStats: full snapshot of all tracked callbacks.
---@return table array of stat tables
function M.GetAllStats()
  local out = {}
  for cb_id in pairs(_stats) do
    out[#out + 1] = M.GetStats(cb_id)
  end
  return out
end

--- ResetStats: clear (one or all).
---@param callback_id string|nil if nil, reset all.
function M.ResetStats(callback_id)
  if callback_id then
    _stats[callback_id] = nil
  else
    _stats = {}
  end
end

-- -----------------------------------------------------------------------------
-- §5. Bootstrap-specific helper (REQ-FE-001 strict enforcement)
-- -----------------------------------------------------------------------------

--- CheckBootstrapHealth: returns whether bootstrap snapshot p99 is within budget.
--- Used by health endpoint / DevOps watchdog (M007 metric).
---@return table { healthy=boolean, p99_ms, budget_ms, breaches, sample_n }
function M.CheckBootstrapHealth()
  local stats = M.GetStats('C001b') or M.GetStats('sonar:bank:bootstrap:snapshot')
  if not stats then
    return { healthy = true, p99_ms = 0, budget_ms = Config.PerfBudgets.BOOTSTRAP_P99_MS, breaches = 0, sample_n = 0 }
  end
  return {
    healthy   = stats.p99_ms <= stats.budget_ms,
    p99_ms    = stats.p99_ms,
    budget_ms = stats.budget_ms,
    breaches  = stats.breaches,
    sample_n  = stats.sample_n,
  }
end

return M
