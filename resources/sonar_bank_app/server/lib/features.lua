-- =============================================================================
-- SONAR Bank App — lib/features.lua
-- =============================================================================
-- Customer-facing feature flag resolver. Reads C.CustomerApp.Features and
-- exposes a single Check(name) helper. Services use this to gate themselves
-- with FEATURE_DISABLED before any expensive work.
--
--   Public API:
--     - Features.IsEnabled(name)      → boolean
--     - Features.Require(name)        → returns nil OR an Error
--     - Features.Snapshot()           → table copy (for bootstrap)
-- =============================================================================

BankApp.lib = BankApp.lib or {}
BankApp.lib.features = {}
local F = BankApp.lib.features

local Config = BankApp.Config
local Errors = BankApp.lib.errors

local function _flags()
  return (Config.CustomerApp and Config.CustomerApp.Features) or {}
end

function F.IsEnabled(name)
  local v = _flags()[name]
  return v == true
end

function F.Require(name)
  if F.IsEnabled(name) then return nil end
  return Errors.New('FEATURE_DISABLED', { feature = name })
end

function F.Snapshot()
  -- Shallow copy — keeps the bootstrap payload immune to mutation.
  local out = {}
  for k, v in pairs(_flags()) do out[k] = v == true end
  return out
end
