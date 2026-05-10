-- =============================================================================
-- SONAR Bank App — callbacks/bootstrap.lua
-- =============================================================================
-- REQ-FE-001 — Consolidated bootstrap + lightweight balance fallback.
--
-- Callbacks:
--   sonar:bank:bootstrap:snapshot      (C001)  — full UI bootstrap (cached LRU 30s)
--   sonar:bank:bootstrap:balance       (C001b) — single-account balance fallback
--   sonar:bank:nui:getConfig                   — UI runtime config snapshot
-- =============================================================================

local Wrap   = BankApp.callbacks._wrap
local Enums  = BankApp.lib.enums
local Errors = BankApp.lib.errors

local BootstrapService = BankApp.services.bootstrap
local NuiBridge        = BankApp.nui.bridge

-- -----------------------------------------------------------------------------
-- C001 — sonar:bank:bootstrap:snapshot
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:bootstrap:snapshot', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'C001',
}, function(src, citizen_id, payload)
  local snapshot, err = BootstrapService.BuildSnapshot(citizen_id)
  if err then return { ok = false, error = err } end
  return snapshot
end)

-- Preflight ligero sin wrapper — NO requiere citizen_id, solo verifica player online.
-- Evita acoplar la apertura NUI a identidad; auth real ocurre en callbacks wrapped.
if _G.lib and _G.lib.callback and type(_G.lib.callback.register) == 'function' then
  _G.lib.callback.register('sonar:bank:nui:canOpen', function(src, payload)
    if type(src) ~= 'number' or src <= 0 then
      return { ok = false, error = { code = 'INVALID_SRC', message = 'Invalid player source' } }
    end
    local name = GetPlayerName(src)
    if not name or name == '' then
      return { ok = false, error = { code = 'PLAYER_OFFLINE', message = 'Player not online' } }
    end
    return { ok = true, ready = true }
  end)
else
  RegisterNetEvent('sonar:bank:nui:canOpen', function(payload, cb)
    local src = source
    if type(src) ~= 'number' or src <= 0 then
      cb({ ok = false, error = { code = 'INVALID_SRC', message = 'Invalid player source' } })
      return
    end
    local name = GetPlayerName(src)
    if not name or name == '' then
      cb({ ok = false, error = { code = 'PLAYER_OFFLINE', message = 'Player not online' } })
      return
    end
    cb({ ok = true, ready = true })
  end)
end

-- -----------------------------------------------------------------------------
-- C001b — sonar:bank:bootstrap:balance (lightweight fallback for legacy paths)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:bootstrap:balance', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'C001b',
}, function(src, citizen_id, payload)
  if type(payload.iban) ~= 'string' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'iban' }) }
  end
  local snap, err = BootstrapService.GetBalanceSnapshot(citizen_id, payload.iban)
  if err then return { ok = false, error = err } end
  return snap
end)

-- -----------------------------------------------------------------------------
-- sonar:bank:nui:getConfig — UI runtime config snapshot
--   Returned config is whitelisted (NO secrets). Tier 1 read.
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:nui:getConfig', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'NUI_CONFIG',
}, function(src, citizen_id, payload)
  return NuiBridge.GetClientConfigSnapshot()
end)
