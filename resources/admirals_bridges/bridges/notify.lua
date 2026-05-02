-- =============================================================================
-- Admirals Bridges — bridges/notify.lua
--
-- Bridges.Notify — notifications in-game (top-right corner típicamente).
--
-- Distinto de Bridges.Phone (que va al device del player). Notify es el
-- "toast" del HUD del player.
--
-- Firmas literales de doc §9.2.
-- =============================================================================

Bridges = Bridges or {}
Bridges.Notify = {}

Bridges.Notify._required_methods = {
  'Show', 'Broadcast', 'IsAvailable',
}

-- =============================================================================
-- Public API (per doc §9.2)
-- =============================================================================

--- Bridges.Notify.Show
---@param source number server id del player target.
---@param opts table { type='info'|'success'|'warning'|'error', title?, message, duration?=5000 }
---@return boolean success
function Bridges.Notify.Show(source, opts)
  return Bridges.Dispatcher.Call('notify', 'Show',
    { source, opts, n = 2 })
end

--- Bridges.Notify.Broadcast — a todos los players conectados.
---@param opts table
---@return boolean success
function Bridges.Notify.Broadcast(opts)
  return Bridges.Dispatcher.Call('notify', 'Broadcast',
    { opts, n = 1 })
end

--- Bridges.Notify.IsAvailable — true si notify script externo activo.
---@return boolean
function Bridges.Notify.IsAvailable()
  local active = Bridges._active and Bridges._active.notify
  return active ~= nil and active ~= 'native'
end
