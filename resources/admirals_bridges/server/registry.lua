-- =============================================================================
-- Admirals Bridges — server/registry.lua
--
-- Almacén central de adapters + estado activo per módulo.
--
-- API pública:
--   Bridges.RegisterAdapter(module, name, impl)  — registra adapter al boot.
--   Bridges.GetAdapter(module, name)             — lookup adapter específico.
--   Bridges.ListAdapters(module)                 — lista nombres registrados.
--   Bridges.SetActive(map)                       — activa adapter per módulo.
--   Bridges.GetActive(module)                    — {name, impl} del activo.
--
-- Validación:
--   RegisterAdapter valida que `impl` contenga TODOS los métodos declarados
--   en `Bridges.<Module>._required_methods`. Fallo = error() boot-time.
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §2.2 (resource layout),
--     §4-§9 (interfaces per bridge).
-- =============================================================================

Bridges = Bridges or {}

local Logger = Bridges.Logger

-- Estado interno (privado). Expuesto read-only via getters.
local _registry = {}  -- [module] = { [adapter_name] = impl }
local _active = {}    -- [module] = adapter_name

-- Inicializar buckets vacíos per módulo conocido.
for _, module in ipairs(Config.Modules) do
  _registry[module] = {}
end

-- -----------------------------------------------------------------------------
-- Helper — PascalCase module name ("bank" → "Bank") para lookup Bridges.X.
-- -----------------------------------------------------------------------------
local function _module_pascal(module)
  return module:sub(1, 1):upper() .. module:sub(2)
end

-- -----------------------------------------------------------------------------
-- Helper — validate module name canonical.
-- -----------------------------------------------------------------------------
local function _is_valid_module(module)
  for _, m in ipairs(Config.Modules) do
    if m == module then return true end
  end
  return false
end

-- -----------------------------------------------------------------------------
-- Helper — validate adapter impl implements all required methods for bridge.
-- Lee `Bridges.<Module>._required_methods` (declarado per bridge file).
--
-- @return boolean ok, string|nil missing_method
-- -----------------------------------------------------------------------------
local function _validate_impl(module, impl)
  local bridge = Bridges[_module_pascal(module)]
  if not bridge then
    return false, string.format('Bridge interface "%s" not loaded', module)
  end
  local required = bridge._required_methods
  if type(required) ~= 'table' then
    return false, string.format('Bridge "%s" missing _required_methods', module)
  end
  for _, method in ipairs(required) do
    if type(impl[method]) ~= 'function' then
      return false, method
    end
  end
  return true, nil
end

-- -----------------------------------------------------------------------------
-- Bridges.RegisterAdapter — registra adapter implementation per módulo.
--
-- @param module string — uno de Config.Modules.
-- @param name string — identificador único per módulo (ej. 'qbox', 'native').
-- @param impl table — tabla con funciones implementando todos _required_methods.
--
-- Throws error() si validation falla (boot-time hard fail intencional).
-- -----------------------------------------------------------------------------
function Bridges.RegisterAdapter(module, name, impl)
  if type(module) ~= 'string' or not _is_valid_module(module) then
    error(string.format('[registry] Invalid module "%s". Valid: %s',
      tostring(module), table.concat(Config.Modules, ', ')), 2)
  end
  if type(name) ~= 'string' or name == '' then
    error('[registry] Adapter name must be non-empty string', 2)
  end
  if type(impl) ~= 'table' then
    error(string.format('[registry] Adapter "%s/%s" impl must be table, got %s',
      module, name, type(impl)), 2)
  end

  if _registry[module][name] then
    error(string.format('[registry] Adapter "%s/%s" already registered',
      module, name), 2)
  end

  local ok, missing = _validate_impl(module, impl)
  if not ok then
    error(string.format('[registry] Adapter "%s/%s" missing required method: %s',
      module, name, tostring(missing)), 2)
  end

  _registry[module][name] = impl
  Logger.Debug('Registered adapter %s/%s', module, name)
end

-- -----------------------------------------------------------------------------
-- Bridges.GetAdapter — lookup adapter impl.
--
-- @return table|nil impl
-- -----------------------------------------------------------------------------
function Bridges.GetAdapter(module, name)
  if not _registry[module] then return nil end
  return _registry[module][name]
end

-- -----------------------------------------------------------------------------
-- Bridges.ListAdapters — lista nombres de adapters registrados per módulo.
--
-- @return string[] names
-- -----------------------------------------------------------------------------
function Bridges.ListAdapters(module)
  local names = {}
  if not _registry[module] then return names end
  for name in pairs(_registry[module]) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

-- -----------------------------------------------------------------------------
-- Bridges.SetActive — marca adapter activo per módulo.
--
-- @param map table { [module] = adapter_name }
-- -----------------------------------------------------------------------------
function Bridges.SetActive(map)
  for module, name in pairs(map) do
    if not _is_valid_module(module) then
      Logger.Warn('SetActive: unknown module "%s" ignored', module)
    elseif not _registry[module][name] then
      Logger.Error('SetActive: adapter %s/%s not registered, keeping "%s"',
        module, name, _active[module] or 'none')
    else
      _active[module] = name
    end
  end
end

-- -----------------------------------------------------------------------------
-- Bridges.GetActive — devuelve adapter activo per módulo.
--
-- @return string|nil name, table|nil impl
-- -----------------------------------------------------------------------------
function Bridges.GetActive(module)
  local name = _active[module]
  if not name then return nil, nil end
  return name, _registry[module][name]
end

-- -----------------------------------------------------------------------------
-- Exposición read-only del estado para debug / boot report.
-- -----------------------------------------------------------------------------
Bridges._registry = _registry
Bridges._active = _active
