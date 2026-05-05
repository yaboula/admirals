-- =============================================================================
-- SONAR Tablet — client/map_gps.lua
-- =============================================================================
-- S2.5 scope: GPS poll thread player coords → SendNUIMessage
-- `sonar:tablet:map:gpsUpdate` solo cuando MapApp activa (perf R7).
--
-- Control activación: React postea `fetchNUI('sonar:tablet:map:setPollActive',
-- { active: bool })` al mount/unmount MapApp → Lua togglea `_poll_active`.
-- Thread corre en loop perpetuo pero early-return si not active — cheaper que
-- crear/destruir thread on-demand (FiveM threads tienen overhead startup).
--
-- Anti-patterns evitados:
--   - NO GetEntityCoords cuando tablet cerrada O view !== 'map'.
--   - NO SendNUIMessage si delta coords < epsilon (omitted S2 — founder puede
--     pedir optimization futuro si 4Hz satura profiler; poco probable).
-- =============================================================================

local _poll_active = false

---Toggle poll activation from React NUI callback.
---@param active boolean
local function setPollActive(active)
  _poll_active = active == true
  if Config.Debug then
    print(('[sonar_tablet] map_gps poll=%s'):format(tostring(_poll_active)))
  end
end

-- -----------------------------------------------------------------------------
-- NUI callback — React → Lua activación/desactivación poll.
-- -----------------------------------------------------------------------------
RegisterNUICallback('sonar:tablet:map:setPollActive', function(data, cb)
  setPollActive(data and data.active == true)
  cb({ ok = true, active = _poll_active })
end)

-- -----------------------------------------------------------------------------
-- Poll thread — corre perpetuo, early-return si not active.
-- Interval Config.MapGpsPollMs (default 250ms = 4Hz).
-- -----------------------------------------------------------------------------
CreateThread(function()
  local poll_ms = tonumber(Config.MapGpsPollMs) or 250
  if poll_ms < 100 then poll_ms = 100 end  -- hard floor anti-spam NUI bridge.

  while true do
    if _poll_active then
      local ped = PlayerPedId()
      if ped and ped ~= 0 and DoesEntityExist(ped) then
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        -- GetEntitySpeed m/s → km/h para display.
        local speed_kmh = GetEntitySpeed(ped) * 3.6

        SendNUIMessage({
          action  = 'sonar:tablet:map:gpsUpdate',
          payload = {
            x       = coords.x,
            y       = coords.y,
            heading = heading,
            speed   = speed_kmh,
            ts      = GetGameTimer(),
          },
        })
      end
      Wait(poll_ms)
    else
      -- Inactivo: idle 500ms (no draw, no GetEntityCoords). React togglea on
      -- vía setPollActive cuando MapApp mount.
      Wait(500)
    end
  end
end)

-- -----------------------------------------------------------------------------
-- Cleanup on resource stop — garantiza no orphan poll.
-- -----------------------------------------------------------------------------
AddEventHandler('onResourceStop', function(resource)
  if resource == GetCurrentResourceName() then
    _poll_active = false
  end
end)
