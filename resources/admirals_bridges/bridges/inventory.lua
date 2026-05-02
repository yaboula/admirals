-- =============================================================================
-- Admirals Bridges — bridges/inventory.lua
--
-- Bridges.Inventory — operaciones sobre el inventario del player (carry) y
-- containers (stashes, vehicles) via framework externo.
--
-- Responsabilidad (per doc §5.1):
--   Admirals almacena los items canónicamente en su DB (`admirals_items` —
--   S0.4+) con quality + lineage + atributos. Este bridge REFLEJA la presencia
--   del item en el inventory del framework para UI / carry mechanics.
--
-- Metadata fallback (per doc §5.4):
--   Si IsMetadataSupported()=false (qb-inventory vanilla), adapter serializa
--   metadata como JSON embedded en description field.
--
-- Firmas literales de doc §5.2.
-- =============================================================================

Bridges = Bridges or {}
Bridges.Inventory = {}

Bridges.Inventory._required_methods = {
  'GiveItem', 'RemoveItem', 'HasItem', 'GetItems',
  'RegisterItem', 'GetCapacity', 'IsMetadataSupported', 'IsAvailable',
}

-- =============================================================================
-- Public API (per doc §5.2)
-- =============================================================================

--- Bridges.Inventory.GiveItem
---@param citizenId string
---@param item_name string
---@param count number
---@param metadata table|nil { admirals_item_id, quality, lineage_origin, ... }
---@return boolean success
---@return string|nil error 'PLAYER_OFFLINE'|'INVENTORY_FULL'|'ITEM_NOT_REGISTERED'
function Bridges.Inventory.GiveItem(citizenId, item_name, count, metadata)
  return Bridges.Dispatcher.Call('inventory', 'GiveItem',
    { citizenId, item_name, count, metadata, n = 4 })
end

--- Bridges.Inventory.RemoveItem
---@param citizenId string
---@param item_name string
---@param count number
---@param admirals_item_id string|nil — remove specific item by ID (optional).
---@return boolean success
---@return string|nil error
function Bridges.Inventory.RemoveItem(citizenId, item_name, count, admirals_item_id)
  return Bridges.Dispatcher.Call('inventory', 'RemoveItem',
    { citizenId, item_name, count, admirals_item_id, n = 4 })
end

--- Bridges.Inventory.HasItem
---@param citizenId string
---@param item_name string
---@param count number
---@return boolean has
---@return number actual_count
function Bridges.Inventory.HasItem(citizenId, item_name, count)
  return Bridges.Dispatcher.Call('inventory', 'HasItem',
    { citizenId, item_name, count, n = 3 })
end

--- Bridges.Inventory.GetItems — lista items que matchean filter.
---@param citizenId string
---@param filter table|nil { item_name?, admirals_item_id? }
---@return table[] items [{ name, count, metadata }]
function Bridges.Inventory.GetItems(citizenId, filter)
  return Bridges.Dispatcher.Call('inventory', 'GetItems',
    { citizenId, filter, n = 2 })
end

--- Bridges.Inventory.RegisterItem — llamar al boot per cada item Admirals.
---@param item_spec table { name, label, weight, stack, close_on_use, description }
---@return boolean success
function Bridges.Inventory.RegisterItem(item_spec)
  return Bridges.Dispatcher.Call('inventory', 'RegisterItem',
    { item_spec, n = 1 })
end

--- Bridges.Inventory.GetCapacity
---@param citizenId string
---@return number current_weight
---@return number max_weight
function Bridges.Inventory.GetCapacity(citizenId)
  return Bridges.Dispatcher.Call('inventory', 'GetCapacity',
    { citizenId, n = 1 })
end

--- Bridges.Inventory.IsMetadataSupported
---@return boolean — true si adapter soporta metadata rica (ox_inventory sí).
function Bridges.Inventory.IsMetadataSupported()
  return Bridges.Dispatcher.Call('inventory', 'IsMetadataSupported', { n = 0 })
end

--- Bridges.Inventory.IsAvailable — true si adapter externo activo (no native).
---@return boolean
function Bridges.Inventory.IsAvailable()
  local active = Bridges._active and Bridges._active.inventory
  return active ~= nil and active ~= 'native'
end
