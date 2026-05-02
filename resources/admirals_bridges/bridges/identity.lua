-- =============================================================================
-- Admirals Bridges — bridges/identity.lua
--
-- Bridges.Identity — resolver identidad del player:
--   source (server id efímero) ↔ citizenId (stable SSoT Admirals) ↔ data.
--
-- Responsabilidad (per doc §7.1):
--   Admirals usa `citizenId` como SSoT en toda su DB. Este bridge es el ÚNICO
--   que sabe obtenerlo del framework externo.
--
-- Diferenciación jobs (per doc §7.3):
--   GetJob() devuelve SOLO el job framework (police, mechanic). Los empresa
--   Admirals se consultan via admirals_core APIs (S1+).
--
-- Lifecycle callbacks (OnPlayerLoaded / OnPlayerDropped):
--   Los callbacks NO se pasan al adapter vía Dispatcher.Call (no fit con
--   pattern request/response). En su lugar, bridge-level mantiene arrays de
--   callbacks, y adapters disparan eventos internos FiveM:
--     'admirals:bridge:_identityPlayerLoaded'(citizenId, source)
--     'admirals:bridge:_identityPlayerDropped'(citizenId, source, reason)
--   Bridge layer fans out a todos los callbacks registrados.
--
-- Firmas literales de doc §7.2.
-- =============================================================================

Bridges = Bridges or {}
Bridges.Identity = {}

-- OnPlayerLoaded / OnPlayerDropped NO son adapter-level methods (bridge-level).
-- Adapter debe disparar eventos internos FiveM en su lifecycle hook.
Bridges.Identity._required_methods = {
  'GetCitizenId', 'GetSource', 'GetPlayerData', 'GetJob', 'IsOnline', 'IsAvailable',
}

-- =============================================================================
-- Lifecycle callbacks (bridge-level fan-out)
-- =============================================================================

local _loaded_callbacks = {}
local _dropped_callbacks = {}

--- Bridges.Identity.OnPlayerLoaded — registra listener global.
---@param callback fun(citizenId: string, source: number)
function Bridges.Identity.OnPlayerLoaded(callback)
  if type(callback) ~= 'function' then
    error('Bridges.Identity.OnPlayerLoaded requires function callback', 2)
  end
  _loaded_callbacks[#_loaded_callbacks + 1] = callback
end

--- Bridges.Identity.OnPlayerDropped — registra listener global.
---@param callback fun(citizenId: string, source: number, reason: string)
function Bridges.Identity.OnPlayerDropped(callback)
  if type(callback) ~= 'function' then
    error('Bridges.Identity.OnPlayerDropped requires function callback', 2)
  end
  _dropped_callbacks[#_dropped_callbacks + 1] = callback
end

-- Internal event fan-out. Adapters TriggerEvent con estos nombres.
AddEventHandler('admirals:bridge:_identityPlayerLoaded', function(citizenId, source)
  for _, fn in ipairs(_loaded_callbacks) do
    local ok, err = pcall(fn, citizenId, source)
    if not ok then
      (Bridges.Logger and Bridges.Logger.Error or print)(
        'OnPlayerLoaded callback threw: ' .. tostring(err))
    end
  end
end)

AddEventHandler('admirals:bridge:_identityPlayerDropped', function(citizenId, source, reason)
  for _, fn in ipairs(_dropped_callbacks) do
    local ok, err = pcall(fn, citizenId, source, reason)
    if not ok then
      (Bridges.Logger and Bridges.Logger.Error or print)(
        'OnPlayerDropped callback threw: ' .. tostring(err))
    end
  end
end)

-- =============================================================================
-- Public API (per doc §7.2)
-- =============================================================================

--- Bridges.Identity.GetCitizenId
---@param source number server id.
---@return string|nil citizenId
function Bridges.Identity.GetCitizenId(source)
  return Bridges.Dispatcher.Call('identity', 'GetCitizenId',
    { source, n = 1 })
end

--- Bridges.Identity.GetSource
---@param citizenId string
---@return number|nil source (nil si offline)
function Bridges.Identity.GetSource(citizenId)
  return Bridges.Dispatcher.Call('identity', 'GetSource',
    { citizenId, n = 1 })
end

--- Bridges.Identity.GetPlayerData
---@param citizenId string
---@return table|nil { citizenId, firstname, lastname, charinfo?, ... }
function Bridges.Identity.GetPlayerData(citizenId)
  return Bridges.Dispatcher.Call('identity', 'GetPlayerData',
    { citizenId, n = 1 })
end

--- Bridges.Identity.GetJob — job framework (NO empresa Admirals).
---@param citizenId string
---@return table|nil { name, grade, label }
function Bridges.Identity.GetJob(citizenId)
  return Bridges.Dispatcher.Call('identity', 'GetJob',
    { citizenId, n = 1 })
end

--- Bridges.Identity.IsOnline
---@param citizenId string
---@return boolean
function Bridges.Identity.IsOnline(citizenId)
  return Bridges.Dispatcher.Call('identity', 'IsOnline',
    { citizenId, n = 1 })
end

--- Bridges.Identity.IsAvailable — true si framework externo activo (no native).
---@return boolean
function Bridges.Identity.IsAvailable()
  local active = Bridges._active and Bridges._active.identity
  return active ~= nil and active ~= 'native'
end

-- =============================================================================
-- Test helpers
-- =============================================================================

--- Bridges.Identity._ClearCallbacks — reset listeners (para tests).
function Bridges.Identity._ClearCallbacks()
  _loaded_callbacks = {}
  _dropped_callbacks = {}
end

--- Bridges.Identity._CallbackCounts — diagnostic.
---@return number loaded, number dropped
function Bridges.Identity._CallbackCounts()
  return #_loaded_callbacks, #_dropped_callbacks
end
