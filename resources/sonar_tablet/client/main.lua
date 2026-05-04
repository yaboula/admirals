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
-- S2.4 Bank app — NUI → server forwarders (React fetchNUI → lib.callback.await).
--
-- Justificación ampliación "1 listener extra" prompt → 3 listeners:
--   Los 3 callbacks backend (C001 balance, C002 transfer, bridge ad-hoc §2.2.3
--   getHistory) son lib.callback server-side. NUI no los invoca directo; este
--   client actúa como forwarder estricto — un contrato NUI ↔ server explícito
--   por operación (vs forwarder genérico rechazado por founder por seguridad
--   anti-inyección NUI y contratos API strict).
-- -----------------------------------------------------------------------------

-- Fallback response si server devuelve nil (defensive — no debería pasar).
local function _err_unknown()
  return { success = false, error_code = 'UNKNOWN', message = 'Respuesta vacía del servidor.' }
end

---Forward NUI request to server callback, return shape canónica al React.
---Errores transitorios (timeout/network) se mapean a `{ success=false,
---error_code='CALLBACK_FAILED' }` para que React los trate como error de UI.
---@param callback_name string ej. 'sonar:bank:getBalance'
---@param data table payload
---@param cb fun(response: table) NUI callback.
local function _forwardCallback(callback_name, data, cb)
  -- lib.callback.await blocks coroutine hasta server response. Client-side OK
  -- (NUI callback runs en coroutine thread).
  local ok, response = pcall(lib.callback.await, callback_name, false, data or {})
  if not ok then
    if Config.Debug then
      print(('[sonar_tablet] callback %s failed: %s'):format(callback_name, tostring(response)))
    end
    cb({
      success    = false,
      error_code = 'CALLBACK_FAILED',
      message    = 'El servidor no respondió. Reintenta.',
    })
    return
  end
  cb(response or _err_unknown())
end

-- C001 — balance real player. Request opcional `{ iban? }`, default personal IBAN.
RegisterNUICallback('sonar:tablet:bank:getBalance', function(data, cb)
  _forwardCallback('sonar:bank:getBalance', data, cb)
end)

-- C002 — transfer player→player atomic. Request `{ from_iban, to_iban, amount,
-- concept, request_id }` per SSoT §3.1 C002.
RegisterNUICallback('sonar:tablet:bank:transfer', function(data, cb)
  _forwardCallback('sonar:bank:transfer', data, cb)
end)

-- Bridge ad-hoc §2.2.3 — historial movements (consumer pattern temporal hasta
-- C003 ship S3 — R5 tech debt documented en server/bank_history.lua).
RegisterNUICallback('sonar:tablet:bank:getHistory', function(data, cb)
  _forwardCallback('sonar:tablet:bank:getHistory', data, cb)
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
