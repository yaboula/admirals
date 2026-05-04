-- =============================================================================
-- SONAR Tablet — server/main.lua
-- =============================================================================
-- S2.2 scope: skeleton NUI bridge server-side.
--
-- Callbacks reales (Bank getHistory, Map getNodes, etc.) llegan S2.4+.
-- Este file queda como placeholder verificador de boot + round-trip ping.
-- =============================================================================

-- Round-trip verify event (client → server → client). Useful para smoke S2.2
-- debugging si NUI bridge falla: player ejecuta /sonar_tablet_ping en chat.
RegisterNetEvent('sonar:tablet:ping', function()
  local src = source
  TriggerClientEvent('sonar:tablet:pong', src, {
    ts     = os.time(),
    server = GetCurrentResourceName(),
  })
end)

-- Admin command dev-only (no ACE gated en S2.2 placeholder; harden S2.7 polish).
RegisterCommand('sonar_tablet_open', function(source)
  if source == 0 then return end -- console no-op
  TriggerClientEvent('sonar:tablet:openExternal', source)
end, false)
