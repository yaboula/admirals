-- =============================================================================
-- SONAR Bank App — state/statebags.lua
-- =============================================================================
-- M004 §2.2.2 — Lazy publish on `playerJoining` event.
-- Hooks the FiveM lifecycle: when a player connects, we look up their citizen_id
-- via Bridges + their primary account balance/savings → publish CP1-B Player
-- StateBag (`bank_balance`).
--
-- Hooks:
--   playerJoining       — register player session, publish initial bank_balance
--   playerDropped       — invalidate caches + clear StateBag
--   onResourceStart('sonar_bank_app') — replay snapshot for already-connected
--                                       players (resource hot-restart support)
-- =============================================================================

BankApp.state.statebags = {}
local M = BankApp.state.statebags

local Publish      = BankApp.lib.publish
local Auth         = BankApp.lib.auth
local Validators   = BankApp.lib.validators
local AccountsRepo = BankApp.repos.accounts

-- -----------------------------------------------------------------------------
-- §1. Helper — fetch primary account + publish
-- -----------------------------------------------------------------------------

--- publish_for_player — internal helper.
---@param src integer
---@param citizen_id string
---@return boolean published
local function publish_for_player(src, citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then return false end

  local accounts, err = AccountsRepo.ListByCitizen(citizen_id, 32)
  if err or not accounts or #accounts == 0 then
    -- No accounts yet (player never opened one) — publish zero-state to unblock UI
    Publish.PublishOnPlayerJoining(src, citizen_id, 0, 0)
    return true
  end

  -- Pick first active account as primary; sum across all owned accounts for state aggregation.
  -- For Phase A we publish ONLY the primary account snapshot. UI iterates accounts
  -- list from bootstrap snapshot for multi-account view.
  local primary_balance = tonumber(accounts[1].balance_minor) or 0
  local primary_savings = tonumber(accounts[1].savings_minor) or 0

  Publish.PublishOnPlayerJoining(src, citizen_id, primary_balance, primary_savings)
  return true
end

--- Publish — public façade for other modules to force-publish current state.
---@param src integer
---@param citizen_id string|nil if nil, resolve via Auth.RequireCitizen
function M.Publish(src, citizen_id)
  if not citizen_id then
    citizen_id = Auth.RequireCitizen(src)
  end
  if citizen_id then publish_for_player(src, citizen_id) end
end

-- -----------------------------------------------------------------------------
-- §2. Lifecycle hooks
-- -----------------------------------------------------------------------------

local _initialized = false

--- Init — bind FiveM events. Called by boot/init.lua at resource start.
function M.Init()
  if _initialized then return end
  _initialized = true

  -- playerJoining (server-side) — fires before player connection completes.
  -- citizen_id may not yet be bound; try with small grace period.
  AddEventHandler('playerJoining', function(_, _)
    local src = source
    if type(src) ~= 'number' or src <= 0 then return end

    -- Defensive delay: allow Bridges/Core to bind citizen_id (some frameworks
    -- bind on first heartbeat, not at playerJoining).
    Citizen.SetTimeout(2000, function()
      local citizen_id = Auth.RequireCitizen(src)
      if citizen_id then publish_for_player(src, citizen_id) end
    end)
  end)

  -- playerDropped — invalidate caches + clear state.
  AddEventHandler('playerDropped', function(_)
    local src = source
    if type(src) ~= 'number' or src <= 0 then return end

    -- Clear bank_balance StateBag
    Publish.InvalidatePlayerState(src)

    -- Best-effort cache invalidation (we may not have citizen_id post-drop, but
    -- the bootstrap cache TTL is short anyway).
  end)

  -- Hot-restart support — replay snapshot for already-connected players.
  AddEventHandler('onResourceStart', function(resource_name)
    if resource_name ~= GetCurrentResourceName() then return end
    Citizen.SetTimeout(3000, function()
      for _, src_str in ipairs(GetPlayers()) do
        local src = tonumber(src_str)
        if src then
          local citizen_id = Auth.RequireCitizen(src)
          if citizen_id then publish_for_player(src, citizen_id) end
        end
      end
    end)
  end)
end

return M
