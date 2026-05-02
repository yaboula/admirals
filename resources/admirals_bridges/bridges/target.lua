-- =============================================================================
-- Admirals Bridges — bridges/target.lua
--
-- Bridges.Target — registrar puntos de interacción (zones, entities, modelos)
-- que el player ve con ox_target o equivalente.
--
-- Responsabilidad (per doc §8.1):
--   Admirals registra interactions para plots granja, mixer bakery, POS
--   retail, hornos, silos, etc. Todos via este bridge.
--
-- Nota S0.2:
--   Native adapter es stub server-only (no client code scope S0.2). Client-
--   side distance-check + marker se implementa S0.4 con admirals_core / Tablet.
--
-- Firmas literales de doc §8.2.
-- =============================================================================

Bridges = Bridges or {}
Bridges.Target = {}

Bridges.Target._required_methods = {
  'AddBoxZone', 'AddEntity', 'AddModel', 'RemoveZone', 'IsAvailable',
}

-- =============================================================================
-- Public API (per doc §8.2)
-- =============================================================================

--- Bridges.Target.AddBoxZone
---@param id string identificador único para RemoveZone posterior.
---@param coords table { x, y, z }
---@param size table { x, y, z } dimensiones del box.
---@param heading number
---@param options table[] [{ name, label, icon, action=function(entity), distance?, canInteract? }]
---@return boolean success
function Bridges.Target.AddBoxZone(id, coords, size, heading, options)
  return Bridges.Dispatcher.Call('target', 'AddBoxZone',
    { id, coords, size, heading, options, n = 5 })
end

--- Bridges.Target.AddEntity — interaction en entity específica (vehicle, ped, object).
---@param entity_handle number
---@param options table[]
---@return boolean success
function Bridges.Target.AddEntity(entity_handle, options)
  return Bridges.Dispatcher.Call('target', 'AddEntity',
    { entity_handle, options, n = 2 })
end

--- Bridges.Target.AddModel — interaction en todos los entities con model dado.
---@param model_hashes number[]|number
---@param options table[]
---@return boolean success
function Bridges.Target.AddModel(model_hashes, options)
  return Bridges.Dispatcher.Call('target', 'AddModel',
    { model_hashes, options, n = 2 })
end

--- Bridges.Target.RemoveZone
---@param id string
---@return boolean success
function Bridges.Target.RemoveZone(id)
  return Bridges.Dispatcher.Call('target', 'RemoveZone',
    { id, n = 1 })
end

--- Bridges.Target.IsAvailable — true si target script externo activo.
---@return boolean
function Bridges.Target.IsAvailable()
  local active = Bridges._active and Bridges._active.target
  return active ~= nil and active ~= 'native'
end
