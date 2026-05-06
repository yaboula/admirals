-- =============================================================================
-- SONAR Bank App — nui/bridge.lua
-- =============================================================================
-- Server-side stub of the NUI bridge.
--
-- The Bank App UI (web-src React app) lives client-side. Server's role:
--   1. Provide the data via callbacks (Step E) + NetEvents (events/netevents).
--   2. Provide a CONFIG snapshot the client can fetch on UI mount to align
--      runtime parameters (caps, TTLs, feature flags) with server reality.
--
-- This module exposes:
--   M.GetClientConfigSnapshot(citizen_id) → safe-to-share subset of Config
--
-- IMPORTANT: never expose convars containing secrets (HMAC, status whitelist,
-- etc.) to client. Snapshot below is whitelisted explicitly.
-- =============================================================================

BankApp.nui = BankApp.nui or {}
BankApp.nui.bridge = {}
local M = BankApp.nui.bridge

local Config = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. Whitelist of client-safe config keys
-- -----------------------------------------------------------------------------

--- GetClientConfigSnapshot — returns a sanitized read-only config view.
---@return table
function M.GetClientConfigSnapshot()
  return {
    resource_version = Config.RESOURCE_VERSION,
    phase            = Config.PHASE,

    -- UI tunables
    bootstrap = {
      total_timeout_ms = Config.Bootstrap.TOTAL_TIMEOUT_MS,
      max_accounts     = Config.Bootstrap.MAX_ACCOUNTS,
      max_recipients   = Config.RecentRecipients.LIMIT,
    },

    recent_recipients = {
      window_days     = Config.RecentRecipients.WINDOW_DAYS,
      limit           = Config.RecentRecipients.LIMIT,
      preset_amounts  = Config.RecentRecipients.PRESET_AMOUNTS,
      cache_ttl_ms    = Config.Cache.RECENT_RECIPIENTS_TTL_MS,
    },

    perf_budgets = {
      bootstrap_p99_ms        = Config.PerfBudgets.BOOTSTRAP_P99_MS,
      recent_recipients_p99_ms= Config.PerfBudgets.RECENT_RECIPIENTS_P99_MS,
      tier_1_read_p99_ms      = Config.PerfBudgets.TIER_1_READ_P99_MS,
      tier_2_write_p99_ms     = Config.PerfBudgets.TIER_2_WRITE_P99_MS,
    },

    features = {
      bootstrap_cache       = Config.Features.ENABLE_BOOTSTRAP_CACHE_LRU,
      recipients_cache      = Config.Features.ENABLE_RECENT_RECIPIENTS_CACHE,
    },
  }
end

-- -----------------------------------------------------------------------------
-- §2. Init — placeholder for future server-side NUI hooks
-- -----------------------------------------------------------------------------

function M.Init()
  -- Reserved for future use (e.g. server-side NUI URL routing per dev_mode).
end

return M
