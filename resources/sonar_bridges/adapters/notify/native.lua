-- =============================================================================
-- SONAR Bridges — adapters/notify/native.lua
--
-- Adapter NATIVE (fallback) para Notify.
--
-- Comportamiento (per doc §11.2):
--   `chat:addMessage` simple con color según type (info/success/warning/error).
--   Sin iconos rich (eso lo provee ox_lib).
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §9.2, §11.2.
-- =============================================================================

local Logger = Bridges.Logger
local NativeNotify = {}

-- RGB color per type (usado por chat:addMessage).
local _type_colors = {
  info    = { 100, 150, 255 },  -- azul claro
  success = { 100, 220, 100 },  -- verde
  warning = { 255, 200,  80 },  -- amarillo
  error   = { 255, 100, 100 },  -- rojo
}

-- Prefix bracket per type (texto plano en chat).
local _type_prefix = {
  info    = '[SONAR]',
  success = '[SONAR ✓]',
  warning = '[SONAR !]',
  error   = '[SONAR ✗]',
}

-- -----------------------------------------------------------------------------
-- Helper — normaliza opts + emite chat:addMessage.
-- -----------------------------------------------------------------------------
local function _emit(source, opts)
  opts = opts or {}
  local ntype = opts.type or 'info'
  local color = _type_colors[ntype] or _type_colors.info
  local prefix = _type_prefix[ntype] or _type_prefix.info
  local title = opts.title and (opts.title .. ': ') or ''
  local message = opts.message or ''

  TriggerClientEvent('chat:addMessage', source, {
    color = color,
    multiline = true,
    args = { prefix, title .. message },
  })
end

-- -----------------------------------------------------------------------------
-- Show
-- -----------------------------------------------------------------------------
function NativeNotify.Show(source, opts)
  if type(source) ~= 'number' then return false end
  _emit(source, opts)
  return true
end

-- -----------------------------------------------------------------------------
-- Broadcast — -1 source en chat:addMessage.
-- -----------------------------------------------------------------------------
function NativeNotify.Broadcast(opts)
  _emit(-1, opts)
  return true
end

-- -----------------------------------------------------------------------------
-- IsAvailable — native siempre disponible.
-- -----------------------------------------------------------------------------
function NativeNotify.IsAvailable()
  return true
end

Bridges.RegisterAdapter('notify', 'native', NativeNotify)
