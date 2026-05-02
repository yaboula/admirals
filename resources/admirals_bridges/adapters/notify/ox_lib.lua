-- =============================================================================
-- Admirals Bridges — adapters/notify/ox_lib.lua
--
-- Adapter ox_lib T1 para Notify.
--
-- Usa el evento client-side de ox_lib per doc §9.3. Tier 1 oficial.
--
-- ox_lib API usada:
--   TriggerClientEvent('ox_lib:notify', source, opts)
--   opts = { type, title?, description, duration?, position? }
--
-- Nota implementación:
--   ox_lib registra el handler 'ox_lib:notify' en el client de cada player.
--   Desde server, TriggerClientEvent es el mecanismo más robusto cross-versión
--   (funciona desde ox_lib v2.x en adelante). El export server-side
--   exports.ox_lib:notify también existe en v3+ y lo usamos si disponible,
--   con fallback al TriggerClientEvent directo.
--
-- Mapeo de tipos Admirals → ox_lib:
--   'info'    → 'inform'  (ox_lib usa 'inform' para info-level)
--   'success' → 'success'
--   'warning' → 'warning'
--   'error'   → 'error'
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §9.2 interface, §9.3 adapter.
-- =============================================================================

local Logger = Bridges.Logger
local OxLibNotify = {}

-- Tipo Admirals → tipo ox_lib.
local _type_map = {
  info    = 'inform',
  success = 'success',
  warning = 'warning',
  error   = 'error',
}

-- Helper: normaliza opts para ox_lib + emite al source dado.
-- Intenta export server-side (v3+), fallback a TriggerClientEvent (v2+).
local function _emit(source, opts)
  opts = opts or {}
  local notify_opts = {
    type        = _type_map[opts.type or 'info'] or 'inform',
    title       = opts.title,
    description = opts.message or opts.description or '',
    duration    = opts.duration or 5000,
    position    = opts.position or 'top-right',
  }

  local ok = pcall(function()
    exports.ox_lib:notify(source, notify_opts)
  end)

  if not ok then
    TriggerClientEvent('ox_lib:notify', source, notify_opts)
  end
end

-- -----------------------------------------------------------------------------
-- Show — notificación a un player específico.
-- -----------------------------------------------------------------------------
---@param source number server id del player
---@param opts table { type, title?, message, duration? }
---@return boolean success
function OxLibNotify.Show(source, opts)
  if type(source) ~= 'number' then return false end
  _emit(source, opts)
  return true
end

-- -----------------------------------------------------------------------------
-- Broadcast — notificación a todos los players conectados.
-- Loop sobre GetPlayers() para TriggerClientEvent individual (garantizado
-- cross-versión ox_lib; -1 source no siempre funciona con exports).
-- -----------------------------------------------------------------------------
---@param opts table
---@return boolean success
function OxLibNotify.Broadcast(opts)
  for _, src_str in ipairs(GetPlayers()) do
    local src = tonumber(src_str)
    if src then _emit(src, opts) end
  end
  return true
end

-- -----------------------------------------------------------------------------
-- IsAvailable
-- -----------------------------------------------------------------------------
function OxLibNotify.IsAvailable()
  return GetResourceState('ox_lib') == 'started'
end

Bridges.RegisterAdapter('notify', 'ox_lib', OxLibNotify)
