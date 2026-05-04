-- =============================================================================
-- SONAR Tablet — client/main.lua
-- =============================================================================
-- S2.2 scope:
--   - Keybind TAB abre/cierra Tablet NUI (R3 mitigation: configurable via Config).
--   - NUI focus management (SetNuiFocus) + state toggle.
--   - Bridge bidireccional Lua ↔ React:
--       Lua → NUI: SendNUIMessage({ action = 'sonar:tablet:toggle', visible })
--       NUI → Lua: RegisterNUICallback('sonar:tablet:close', ...)
--   - Cleanup focus on resource stop (evita lock gameplay si resource reinicia).
--
-- Anti-patterns evitados:
--   - NO exports['qb-*'] / ESX.* / QBCore.* directo (S2.2 no necesita; Bridges
--     activa S2.4 Bank app via exports.sonar_bridges.*).
--   - NO eventos cross-resource sin prefix `sonar:tablet:*` canonical.
-- =============================================================================

local tabletVisible = false

-- -----------------------------------------------------------------------------
-- Core toggle
-- -----------------------------------------------------------------------------

---Sets tablet visibility + syncs NUI focus + emits bridge message.
---@param visible boolean
local function setTabletVisible(visible)
  tabletVisible = visible
  SetNuiFocus(visible, visible)
  SendNUIMessage({
    action  = 'sonar:tablet:toggle',
    visible = visible,
  })

  if Config.Debug then
    print(('[sonar_tablet] visibility=%s'):format(tostring(visible)))
  end
end

local function toggleTablet()
  setTabletVisible(not tabletVisible)
end

-- -----------------------------------------------------------------------------
-- Keybind (R3 mitigation: configurable via Config.TabletKeybind)
-- -----------------------------------------------------------------------------

RegisterCommand('+sonarTablet', toggleTablet, false)
RegisterCommand('-sonarTablet', function() end, false)

RegisterKeyMapping(
  '+sonarTablet',
  'Abrir/cerrar SONAR Tablet',
  'keyboard',
  Config.TabletKeybind
)

-- -----------------------------------------------------------------------------
-- NUI callbacks (React → Lua)
-- -----------------------------------------------------------------------------

-- React cierra Tablet (ESC key en TabletFrame.tsx → fetchNUI('sonar:tablet:close')).
RegisterNUICallback('sonar:tablet:close', function(_, cb)
  setTabletVisible(false)
  cb({ ok = true })
end)

-- Health check ping (smoke DC-S2.2-6 verify round-trip NUI↔Lua).
RegisterNUICallback('sonar:tablet:ping', function(data, cb)
  if Config.Debug then
    print(('[sonar_tablet] ping received: %s'):format(json.encode(data or {})))
  end
  cb({ ok = true, ts = GetGameTimer() })
end)

-- -----------------------------------------------------------------------------
-- External programmatic open (otros resources pueden abrir Tablet)
-- Ej. admin command / phone contact tap / notification tap.
-- -----------------------------------------------------------------------------

RegisterNetEvent('sonar:tablet:openExternal', function()
  if not tabletVisible then
    setTabletVisible(true)
  end
end)

-- -----------------------------------------------------------------------------
-- Cleanup on resource stop (previene NUI focus lock si resource restart).
-- -----------------------------------------------------------------------------

AddEventHandler('onResourceStop', function(resource)
  if resource == GetCurrentResourceName() and tabletVisible then
    SetNuiFocus(false, false)
    tabletVisible = false
  end
end)
