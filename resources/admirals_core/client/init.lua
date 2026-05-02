-- =============================================================================
-- Admirals Core — client/init.lua
--
-- Stub cliente S0.4 — solo:
--   1. Announce boot al console client.
--   2. Listen al evento server 'admirals:core:ready' (emitido por Bus.Publish
--      con broadcast_client = -1 en server/init.lua) → set Admirals.Ready = true.
--
-- Lógica client real (Tablet NUI, callbacks, state bags) llega S1+.
--
-- Referencias SSoT:
--   docs/technical/04_api_contracts.md §5 (NUI bridges — S1+).
--   docs/technical/06_fivem_standards.md §3 (State Bags vs Events).
-- =============================================================================

Admirals = Admirals or {}
Admirals.Ready = false
Admirals.Version = nil

-- Listen al ready event del server.
RegisterNetEvent('admirals:core:ready', function(payload)
  Admirals.Ready = true
  Admirals.Version = payload and payload.version or '?'
  print(string.format('^5[admirals_core] client: server ready (v%s, migrations=%d)^7',
    Admirals.Version, payload and payload.migrations_applied or 0))
end)

-- Boot announce.
print('^5[admirals_core] client booted — waiting for server ready event^7')
