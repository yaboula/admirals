-- =============================================================================
-- SONAR Bridges — adapters/target/native.lua
--
-- Adapter NATIVE (fallback) para Target.
--
-- Comportamiento S0.2:
--   STUB server-only. Registra zones en memoria (para RemoveZone referenciable)
--   pero NO ejecuta client-side distance-check/marker — eso requiere client
--   code scope en S0.4 con sonar_core.
--
-- Comportamiento planeado S0.4+:
--   Distance-check + keypress E + marker ground via client script mínimo
--   consumiendo estas zones registradas (sonar_core/client/target_native.lua).
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §8.2, §8.3, §11.2.
-- =============================================================================

local Logger = Bridges.Logger
local NativeTarget = {}

-- Zone registry (usado por S0.4+ client script).
local _zones = {}          -- [id] = { coords, size, heading, options }
local _entities = {}       -- entity_handle → options (S0.4+ consume)
local _models = {}         -- [model_hash] = options (S0.4+ consume)

local _WARN_ONCE_SHOWN = false
local function _warn_once()
  if _WARN_ONCE_SHOWN then return end
  _WARN_ONCE_SHOWN = true
  Logger.Warn('NativeTarget is a stub (server-only). Client-side distance-check '
    .. 'comes with sonar_core S0.4+. Install ox_target for full UX.')
end

-- -----------------------------------------------------------------------------
-- AddBoxZone
-- -----------------------------------------------------------------------------
function NativeTarget.AddBoxZone(id, coords, size, heading, options)
  _warn_once()
  if type(id) ~= 'string' or id == '' then return false end
  _zones[id] = {
    coords = coords,
    size = size,
    heading = heading,
    options = options,
    created_at = os.time(),
  }
  Logger.Debug('NativeTarget: zone "%s" registered (server-only stub)', id)
  return true
end

-- -----------------------------------------------------------------------------
-- AddEntity
-- -----------------------------------------------------------------------------
function NativeTarget.AddEntity(entity_handle, options)
  _warn_once()
  if not entity_handle then return false end
  _entities[entity_handle] = options
  return true
end

-- -----------------------------------------------------------------------------
-- AddModel
-- -----------------------------------------------------------------------------
function NativeTarget.AddModel(model_hashes, options)
  _warn_once()
  if not model_hashes then return false end
  if type(model_hashes) == 'number' then
    _models[model_hashes] = options
  elseif type(model_hashes) == 'table' then
    for _, hash in ipairs(model_hashes) do
      _models[hash] = options
    end
  end
  return true
end

-- -----------------------------------------------------------------------------
-- RemoveZone
-- -----------------------------------------------------------------------------
function NativeTarget.RemoveZone(id)
  if _zones[id] then
    _zones[id] = nil
    return true
  end
  return false
end

-- -----------------------------------------------------------------------------
-- IsAvailable — native siempre disponible (aunque no-op visual).
-- -----------------------------------------------------------------------------
function NativeTarget.IsAvailable()
  return true
end

-- -----------------------------------------------------------------------------
-- Exposure para S0.4+ client script consumer.
-- -----------------------------------------------------------------------------
function NativeTarget._GetZones() return _zones end
function NativeTarget._GetEntities() return _entities end
function NativeTarget._GetModels() return _models end
function NativeTarget._Reset()
  _zones, _entities, _models = {}, {}, {}
  _WARN_ONCE_SHOWN = false
end

Bridges.RegisterAdapter('target', 'native', NativeTarget)
