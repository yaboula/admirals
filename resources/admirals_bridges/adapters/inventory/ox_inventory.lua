-- =============================================================================
-- Admirals Bridges — adapters/inventory/ox_inventory.lua
--
-- Adapter ox_inventory T1 para Inventory.
--
-- Usa exports.ox_inventory per doc §5.5.1. Tier 1 oficial.
--
-- ox_inventory v3 API usada (server-side exports):
--   exports.ox_inventory:AddItem(source, item, count, metadata)  → count | false
--   exports.ox_inventory:RemoveItem(source, item, count, metadata) → count | false
--   exports.ox_inventory:Search(source, 'count', item)            → number
--   exports.ox_inventory:GetInventoryItems(source)                → table[]
--   exports.ox_inventory:RegisterItem(name, data)                 → void
--   exports.ox_inventory:GetWeight(source)                        → number
--
-- Source lookup:
--   ox_inventory requiere source (player server id). Este adapter recibe
--   citizenId → Bridges.Identity.GetSource(citizenId) para resolver vía el
--   adapter de identity activo.
--
-- RegisterItem:
--   ox_inventory items se definen típicamente en data/items.lua del resource.
--   RegisterItem vía export (v3+) lo registra en runtime. Fallo es warning,
--   no error fatal — item podría ya estar definido en el file estático.
--
-- Metadata:
--   ox_inventory soporta metadata rica nativa. IsMetadataSupported = true.
--   Campos admirals_item_id, quality, quality_score, lineage_* se almacenan
--   directamente en el metadata slot del item (per doc §5.3).
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §5.2 interface, §5.5.1 adapter,
--     §5.3 contrato metadata.
-- =============================================================================

local Logger = Bridges.Logger
local OxInventory = {}

-- Helper: citizenId → source via adapter de identity activo.
local function _get_source(citizenId)
  return Bridges.Identity.GetSource(citizenId)
end

-- -----------------------------------------------------------------------------
-- RegisterItem — registra item en ox_inventory para que aparezca en UI.
-- pcall protegido: item puede ya estar definido en data/items.lua (no es error).
-- -----------------------------------------------------------------------------
---@param spec table { name, label, weight, stack, close_on_use, description }
---@return boolean success
function OxInventory.RegisterItem(spec)
  if type(spec) ~= 'table' or type(spec.name) ~= 'string' then
    return false
  end
  local ok, err = pcall(function()
    exports.ox_inventory:RegisterItem(spec.name, {
      label       = spec.label or spec.name,
      weight      = spec.weight or 500,
      stack       = spec.stack ~= false,
      close       = spec.close_on_use ~= false,
      description = spec.description,
    })
  end)
  if not ok then
    Logger.Warn('OxInventory.RegisterItem: export call failed for "%s" — %s', spec.name, tostring(err))
    Logger.Warn('OxInventory.RegisterItem: ensure item is defined in ox_inventory/data/items.lua')
    return false
  end
  Logger.Debug('OxInventory: registered item "%s"', spec.name)
  return true
end

-- -----------------------------------------------------------------------------
-- GiveItem
-- -----------------------------------------------------------------------------
---@param citizenId string
---@param item_name string
---@param count number
---@param metadata table|nil { admirals_item_id, quality, lineage_origin, ... }
---@return boolean success
---@return string|nil error 'PLAYER_OFFLINE'|'INVENTORY_FULL'|'FAILED'
function OxInventory.GiveItem(citizenId, item_name, count, metadata)
  if type(citizenId) ~= 'string' or citizenId == '' then
    return false, 'VALIDATION_FAILED'
  end
  local source = _get_source(citizenId)
  if not source then return false, 'PLAYER_OFFLINE' end
  count = count or 1
  local result = exports.ox_inventory:AddItem(source, item_name, count, metadata)
  if not result then
    return false, 'INVENTORY_FULL'
  end
  return true, nil
end

-- -----------------------------------------------------------------------------
-- RemoveItem
-- Si admirals_item_id especificado, filtra por metadata para remover el item
-- específico (permite remover instancia exacta con lineage preservado).
-- -----------------------------------------------------------------------------
---@param citizenId string
---@param item_name string
---@param count number
---@param admirals_item_id string|nil
---@return boolean success
---@return string|nil error 'PLAYER_OFFLINE'|'INSUFFICIENT_QUANTITY'|'FAILED'
function OxInventory.RemoveItem(citizenId, item_name, count, admirals_item_id)
  if type(citizenId) ~= 'string' or citizenId == '' then
    return false, 'VALIDATION_FAILED'
  end
  local source = _get_source(citizenId)
  if not source then return false, 'PLAYER_OFFLINE' end
  count = count or 1
  local metadata = admirals_item_id and { admirals_item_id = admirals_item_id } or nil
  local result = exports.ox_inventory:RemoveItem(source, item_name, count, metadata)
  if not result then
    return false, 'INSUFFICIENT_QUANTITY'
  end
  return true, nil
end

-- -----------------------------------------------------------------------------
-- HasItem
-- -----------------------------------------------------------------------------
---@param citizenId string
---@param item_name string
---@param count number
---@return boolean has
---@return number actual_count
function OxInventory.HasItem(citizenId, item_name, count)
  count = count or 1
  if type(citizenId) ~= 'string' or citizenId == '' then return false, 0 end
  local source = _get_source(citizenId)
  if not source then return false, 0 end
  local actual = exports.ox_inventory:Search(source, 'count', item_name) or 0
  return actual >= count, actual
end

-- -----------------------------------------------------------------------------
-- GetItems
-- -----------------------------------------------------------------------------
---@param citizenId string
---@param filter table|nil { item_name?, admirals_item_id? }
---@return table[] [{ name, count, metadata }]
function OxInventory.GetItems(citizenId, filter)
  if type(citizenId) ~= 'string' or citizenId == '' then return {} end
  local source = _get_source(citizenId)
  if not source then return {} end
  local raw = exports.ox_inventory:GetInventoryItems(source) or {}
  filter = filter or {}
  local result = {}
  for _, item in ipairs(raw) do
    if not item.name then goto continue end
    local include = true
    if filter.item_name and filter.item_name ~= item.name then include = false end
    if include and filter.admirals_item_id then
      local mid = item.metadata and item.metadata.admirals_item_id
      if mid ~= filter.admirals_item_id then include = false end
    end
    if include then
      result[#result + 1] = {
        name     = item.name,
        count    = item.count or 1,
        metadata = item.metadata,
      }
    end
    ::continue::
  end
  return result
end

-- -----------------------------------------------------------------------------
-- GetCapacity
-- ox_inventory almacena max_weight por inventory en DB (default ~30,000g
-- configurado en ox_inventory/config.lua). GetWeight devuelve peso actual.
-- GetMaxWeight intentado vía pcall (export disponible en v3.x+).
-- -----------------------------------------------------------------------------
---@param citizenId string
---@return number current_weight
---@return number max_weight
function OxInventory.GetCapacity(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return 0, 0 end
  local source = _get_source(citizenId)
  if not source then return 0, 0 end
  local current = exports.ox_inventory:GetWeight(source) or 0
  local max = 30000
  local ok, val = pcall(function()
    return exports.ox_inventory:GetMaxWeight(source)
  end)
  if ok and type(val) == 'number' and val > 0 then max = val end
  return current, max
end

-- -----------------------------------------------------------------------------
-- IsMetadataSupported — ox_inventory soporta metadata rica nativa (per §5.5.1).
-- -----------------------------------------------------------------------------
function OxInventory.IsMetadataSupported()
  return true
end

-- -----------------------------------------------------------------------------
-- IsAvailable
-- -----------------------------------------------------------------------------
function OxInventory.IsAvailable()
  return GetResourceState('ox_inventory') == 'started'
end

Bridges.RegisterAdapter('inventory', 'ox_inventory', OxInventory)
