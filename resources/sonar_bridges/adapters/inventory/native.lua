-- =============================================================================
-- SONAR Bridges — adapters/inventory/native.lua
--
-- Adapter NATIVE (fallback) para Inventory.
--
-- Comportamiento:
--   In-memory carry map por citizenId. No hay UI HUD nativa (requiere Tablet
--   Inventory app — S1+). SONAR Core puede leer/escribir directamente vía
--   este bridge durante dev/testing sin depender de ox_inventory.
--
-- Persistencia:
--   S0.2: in-memory (reset en restart). Acceptable para smoke check.
--   S0.4+: persistencia en `sonar_items_carry` table si no hay adapter externo.
--
-- Capacity:
--   Peso simple. Max_weight configurable (default 50.0 unidades).
--
-- Metadata:
--   Soportada rica (misma estructura que ox_inventory metadata).
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §5.1 responsabilidad,
--     §5.3 contrato metadata, §11.2 native Inventory.
-- =============================================================================

local Logger = Bridges.Logger
local NativeInventory = {}

-- In-memory stores.
local _carry = {}          -- [citizenId] = { [item_name] = { count, metadata } }
local _registered = {}     -- [item_name] = item_spec

-- Constants.
local DEFAULT_MAX_WEIGHT = 50.0
local DEFAULT_ITEM_WEIGHT = 0.5

-- -----------------------------------------------------------------------------
-- RegisterItem — registra item SONAR para que GiveItem lo acepte.
-- -----------------------------------------------------------------------------
function NativeInventory.RegisterItem(spec)
  if type(spec) ~= 'table' or type(spec.name) ~= 'string' then
    return false
  end
  _registered[spec.name] = {
    name = spec.name,
    label = spec.label or spec.name,
    weight = spec.weight or DEFAULT_ITEM_WEIGHT,
    stack = spec.stack ~= false,
    close_on_use = spec.close_on_use ~= false,
    description = spec.description,
  }
  Logger.Debug('NativeInventory: registered item "%s"', spec.name)
  return true
end

-- -----------------------------------------------------------------------------
-- GiveItem
-- -----------------------------------------------------------------------------
function NativeInventory.GiveItem(citizenId, item_name, count, metadata)
  if type(citizenId) ~= 'string' or citizenId == '' then
    return false, 'VALIDATION_FAILED'
  end
  if not _registered[item_name] then
    return false, 'ITEM_NOT_REGISTERED'
  end
  count = count or 1
  if type(count) ~= 'number' or count <= 0 then
    return false, 'VALIDATION_FAILED'
  end

  -- Capacity check
  local current_w, max_w = NativeInventory.GetCapacity(citizenId)
  local item_weight = _registered[item_name].weight or DEFAULT_ITEM_WEIGHT
  if current_w + (item_weight * count) > max_w then
    return false, 'INVENTORY_FULL'
  end

  _carry[citizenId] = _carry[citizenId] or {}
  local bucket = _carry[citizenId][item_name]
  if bucket then
    bucket.count = bucket.count + count
    if metadata then bucket.metadata = metadata end
  else
    _carry[citizenId][item_name] = { count = count, metadata = metadata or {} }
  end

  return true, nil
end

-- -----------------------------------------------------------------------------
-- RemoveItem
-- -----------------------------------------------------------------------------
function NativeInventory.RemoveItem(citizenId, item_name, count, sonar_item_id)
  if not _carry[citizenId] or not _carry[citizenId][item_name] then
    return false, 'NOT_FOUND'
  end
  count = count or 1
  local bucket = _carry[citizenId][item_name]

  -- Si sonar_item_id specified, validar que matchea antes de remove.
  if sonar_item_id then
    local mid = bucket.metadata and bucket.metadata.sonar_item_id
    if mid ~= sonar_item_id then
      return false, 'NOT_FOUND'
    end
  end

  if bucket.count < count then
    return false, 'INSUFFICIENT_QUANTITY'
  end
  bucket.count = bucket.count - count
  if bucket.count <= 0 then
    _carry[citizenId][item_name] = nil
  end
  return true, nil
end

-- -----------------------------------------------------------------------------
-- HasItem
-- -----------------------------------------------------------------------------
function NativeInventory.HasItem(citizenId, item_name, count)
  count = count or 1
  local bucket = _carry[citizenId] and _carry[citizenId][item_name]
  local actual = bucket and bucket.count or 0
  return actual >= count, actual
end

-- -----------------------------------------------------------------------------
-- GetItems
-- -----------------------------------------------------------------------------
function NativeInventory.GetItems(citizenId, filter)
  local result = {}
  local items = _carry[citizenId]
  if not items then return result end

  filter = filter or {}
  for name, bucket in pairs(items) do
    local include = true
    if filter.item_name and filter.item_name ~= name then include = false end
    if include and filter.sonar_item_id then
      local mid = bucket.metadata and bucket.metadata.sonar_item_id
      if mid ~= filter.sonar_item_id then include = false end
    end
    if include then
      result[#result + 1] = {
        name = name,
        count = bucket.count,
        metadata = bucket.metadata,
      }
    end
  end
  return result
end

-- -----------------------------------------------------------------------------
-- GetCapacity
-- -----------------------------------------------------------------------------
function NativeInventory.GetCapacity(citizenId)
  local total_w = 0
  local items = _carry[citizenId] or {}
  for name, bucket in pairs(items) do
    local w = (_registered[name] and _registered[name].weight) or DEFAULT_ITEM_WEIGHT
    total_w = total_w + (w * bucket.count)
  end
  return total_w, DEFAULT_MAX_WEIGHT
end

-- -----------------------------------------------------------------------------
-- IsMetadataSupported — native soporta metadata rica (stored as-is).
-- -----------------------------------------------------------------------------
function NativeInventory.IsMetadataSupported()
  return true
end

-- -----------------------------------------------------------------------------
-- IsAvailable — native siempre disponible.
-- -----------------------------------------------------------------------------
function NativeInventory.IsAvailable()
  return true
end

-- -----------------------------------------------------------------------------
-- Debug helpers (útil para tests + smoke check)
-- -----------------------------------------------------------------------------

--- _DumpCarry — devuelve snapshot del carry store (read-only copy).
function NativeInventory._DumpCarry()
  local snap = {}
  for cid, items in pairs(_carry) do
    snap[cid] = {}
    for name, bucket in pairs(items) do
      snap[cid][name] = { count = bucket.count, metadata = bucket.metadata }
    end
  end
  return snap
end

--- _Reset — clear all state (tests).
function NativeInventory._Reset()
  _carry = {}
  _registered = {}
end

Bridges.RegisterAdapter('inventory', 'native', NativeInventory)
