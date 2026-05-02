-- =============================================================================
-- Admirals Bridges — adapters/target/ox_target.lua
--
-- Adapter ox_target T1 para Target.
--
-- ox_target es un resource client-side. Desde server solo podemos triggerear
-- eventos en clientes conectados para que registren zones localmente.
--
-- Comportamiento S0.3 (server-only scope):
--   1. Almacena zones/entities/models en registry server-side (mismo store que
--      native — consumido por S0.4+ client sync al reconectar).
--   2. TriggerClientEvent(-1, 'admirals:bridge:target:*') a clientes conectados
--      para que client code llame exports.ox_target localmente.
--
-- Comportamiento S0.4+:
--   admirals_bridges/client/target_ox_consumer.lua escucha:
--     'admirals:bridge:target:addBoxZone'  → exports.ox_target:addBoxZone(...)
--     'admirals:bridge:target:addEntity'   → exports.ox_target:addEntity(...)
--     'admirals:bridge:target:addModel'    → exports.ox_target:addModel(...)
--     'admirals:bridge:target:removeZone'  → exports.ox_target:removeZone(...)
--   Al playerSpawned → re-sync todas las zones del store server-side.
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §8.2 interface, §8.3 adapter.
-- =============================================================================

local Logger = Bridges.Logger
local OxTarget = {}

-- Store server-side (idéntico al native — consumido por client consumer S0.4+).
local _zones    = {}   -- [id]           = { coords, size, heading, options, created_at }
local _entities = {}   -- [entity_handle] = options
local _models   = {}   -- [model_hash]   = options

-- -----------------------------------------------------------------------------
-- AddBoxZone
-- Registra en store + notifica clientes conectados para ox_target client-side.
-- -----------------------------------------------------------------------------
---@param id string identificador único (usado por RemoveZone posterior)
---@param coords table { x, y, z }
---@param size table { x, y, z }
---@param heading number
---@param options table[] [{ name, label, icon, action, distance?, canInteract? }]
---@return boolean success
function OxTarget.AddBoxZone(id, coords, size, heading, options)
  if type(id) ~= 'string' or id == '' then return false end
  _zones[id] = {
    coords     = coords,
    size       = size,
    heading    = heading,
    options    = options,
    created_at = os.time(),
  }
  TriggerClientEvent('admirals:bridge:target:addBoxZone', -1, id, coords, size, heading, options)
  Logger.Debug('OxTarget: AddBoxZone "%s" stored + client sync triggered', id)
  return true
end

-- -----------------------------------------------------------------------------
-- AddEntity
-- -----------------------------------------------------------------------------
---@param entity_handle number
---@param options table[]
---@return boolean success
function OxTarget.AddEntity(entity_handle, options)
  if not entity_handle then return false end
  _entities[entity_handle] = options
  TriggerClientEvent('admirals:bridge:target:addEntity', -1, entity_handle, options)
  Logger.Debug('OxTarget: AddEntity handle=%s stored + client sync triggered', tostring(entity_handle))
  return true
end

-- -----------------------------------------------------------------------------
-- AddModel
-- -----------------------------------------------------------------------------
---@param model_hashes number|number[]
---@param options table[]
---@return boolean success
function OxTarget.AddModel(model_hashes, options)
  if not model_hashes then return false end
  if type(model_hashes) == 'number' then
    _models[model_hashes] = options
  elseif type(model_hashes) == 'table' then
    for _, hash in ipairs(model_hashes) do
      _models[hash] = options
    end
  end
  TriggerClientEvent('admirals:bridge:target:addModel', -1, model_hashes, options)
  Logger.Debug('OxTarget: AddModel stored + client sync triggered')
  return true
end

-- -----------------------------------------------------------------------------
-- RemoveZone
-- -----------------------------------------------------------------------------
---@param id string
---@return boolean success
function OxTarget.RemoveZone(id)
  if _zones[id] then
    _zones[id] = nil
    TriggerClientEvent('admirals:bridge:target:removeZone', -1, id)
    Logger.Debug('OxTarget: RemoveZone "%s"', id)
    return true
  end
  return false
end

-- -----------------------------------------------------------------------------
-- IsAvailable
-- -----------------------------------------------------------------------------
function OxTarget.IsAvailable()
  return GetResourceState('ox_target') == 'started'
end

-- -----------------------------------------------------------------------------
-- Exposure para S0.4+ client consumer (mismo API que native).
-- -----------------------------------------------------------------------------
function OxTarget._GetZones()    return _zones    end
function OxTarget._GetEntities() return _entities end
function OxTarget._GetModels()   return _models   end
function OxTarget._Reset()
  _zones, _entities, _models = {}, {}, {}
end

Bridges.RegisterAdapter('target', 'ox_target', OxTarget)
