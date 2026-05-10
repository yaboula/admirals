-- =============================================================================
-- SONAR Bank App — client/nui_bridge.lua
-- =============================================================================
-- BANK-FE.2 client glue: bridges NUI fetch() → server lib.callback.
--
-- React app (web-src/) calls:
--   fetch(`https://sonar_bank_app/${eventName}`, { method: 'POST', body: JSON.stringify(payload) })
--
-- This script registers ONE generic NUI handler ('cb') that accepts
--   { event = 'sonar:bank:bootstrap:snapshot', payload = {...} }
-- and forwards to the server callback via lib.callback.await.
--
-- Plus 2 utility callbacks:
--   - 'open'  → toggle NUI focus on/off (called by React when ready)
--   - 'close' → release NUI focus + send message to React
-- =============================================================================

local PREFIX = '[sonar_bank_app][nui_bridge]'
local Config = BankApp.Config
local player_loaded = false

-- -----------------------------------------------------------------------------
-- §1. Allowlist — only canonical Bank callback prefixes are forwarded.
-- Defensive against arbitrary event injection from a compromised UI surface.
-- -----------------------------------------------------------------------------

local ALLOWED_PREFIXES = {
  'sonar:bank:',
}

local function is_allowed(event_name)
  if type(event_name) ~= 'string' then return false end
  for _, prefix in ipairs(ALLOWED_PREFIXES) do
    if event_name:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

local function await_server_callback(event_name, payload)
  print(('[%s] await_server_callback: event=%s'):format(PREFIX, event_name))

  if _G.lib and _G.lib.callback and type(_G.lib.callback.await) == 'function' then
    print(('[%s] Using ox_lib callback.await'):format(PREFIX))
    return _G.lib.callback.await(event_name, false, payload)
  end

  print(('[%s] WARNING: ox_lib not loaded, using fallback'):format(PREFIX))
  local token = ('%s:%s:%s'):format(GetGameTimer(), math.random(100000, 999999), event_name)
  local response_event = 'sonar:bank_app:callback:response:' .. token
  local response_promise = promise.new()
  local resolved = false
  local handler

  RegisterNetEvent(response_event)
  handler = AddEventHandler(response_event, function(response)
    if resolved then return end
    resolved = true
    if handler then RemoveEventHandler(handler) end
    print(('[%s] Fallback response received: ok=%s'):format(PREFIX, tostring(response.ok)))
    response_promise:resolve(response)
  end)

  print(('[%s] Triggering server event: %s'):format(PREFIX, event_name))
  TriggerServerEvent(event_name, payload, response_event)

  SetTimeout(15000, function()
    if resolved then return end
    resolved = true
    if handler then RemoveEventHandler(handler) end
    print(('[%s] Fallback TIMEOUT for event: %s'):format(PREFIX, event_name))
    response_promise:resolve({
      ok = false,
      error = {
        code = 'NUI_CALLBACK_TIMEOUT',
        category = 'timeout',
        message = 'Server callback timed out',
        details = { event = event_name },
      },
    })
  end)

  return Citizen.Await(response_promise)
end

-- -----------------------------------------------------------------------------
-- §2. Generic forwarder — ONE handler, N events.
-- -----------------------------------------------------------------------------

RegisterNUICallback('cb', function(data, cb)
  local event_name = data and data.event
  local payload    = data and data.payload or {}

  if not is_allowed(event_name) then
    cb({
      ok = false,
      error = {
        code     = 'NUI_FORBIDDEN_EVENT',
        category = 'security',
        message  = 'Event not in NUI allowlist',
        details  = { event = tostring(event_name) },
      },
    })
    return
  end

  -- ox_lib server callback await (timeout enforced server-side per tier)
  local ok, response = pcall(function()
    return await_server_callback(event_name, payload)
  end)

  if not ok then
    cb({
      ok = false,
      error = {
        code     = 'NUI_BRIDGE_RAISED',
        category = 'internal',
        message  = 'Client-side callback await raised',
        details  = { reason = tostring(response):sub(1, 200) },
      },
    })
    return
  end

  -- Server response is already in canonical envelope: { ok, data | error }
  cb(response or {
    ok = false,
    error = { code = 'NUI_EMPTY_RESPONSE', category = 'internal' },
  })
end)

-- -----------------------------------------------------------------------------
-- §3. Open / Close handlers
-- -----------------------------------------------------------------------------

local nui_focused = false

local function refresh_player_loaded()
  if player_loaded then return true end
  if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn == true then
    player_loaded = true
    return true
  end

  return false
end

local function open_bank_ui()
  if nui_focused then return end
  if not refresh_player_loaded() then return end
  SendNUIMessage({ type = 'BANK_OPEN' })
  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(false)
  nui_focused = true
end

local function close_bank_ui()
  SendNUIMessage({ type = 'BANK_CLOSE' })
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
  nui_focused = false
end

local function toggle_bank_ui()
  if nui_focused then
    close_bank_ui()
  else
    open_bank_ui()
  end
end

RegisterNUICallback('open', function(_, cb)
  open_bank_ui()
  cb({ ok = true, data = { focused = true } })
end)

RegisterNUICallback('close', function(_, cb)
  close_bank_ui()
  cb({ ok = true, data = { focused = false } })
end)

-- -----------------------------------------------------------------------------
-- §4. Optional: command + key mapping to toggle Bank UI (DevOps Phase E will refine)
-- -----------------------------------------------------------------------------

RegisterNetEvent(Config.ClientEvents.OPEN_UI, open_bank_ui)
RegisterNetEvent(Config.ClientEvents.CLOSE_UI, close_bank_ui)
RegisterNetEvent(Config.ClientEvents.TOGGLE_UI, toggle_bank_ui)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
  player_loaded = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
  player_loaded = false
  close_bank_ui()
end)

RegisterCommand(Config.Commands.OPEN_BANK.name, toggle_bank_ui, false)
RegisterKeyMapping(
  Config.Commands.OPEN_BANK.name,
  Config.Commands.OPEN_BANK.description,
  Config.Commands.OPEN_BANK.key_mapping.mapper,
  Config.Commands.OPEN_BANK.key_mapping.default_key
)

-- -----------------------------------------------------------------------------
-- §5. Server-broadcast NetEvents → forward to NUI as messages.
-- M004 CP1-B financial PII updates land here (server publishes via NetEvent).
-- -----------------------------------------------------------------------------

local FORWARDED_NETEVENTS = {
  'sonar:bank:balance:update',
  'sonar:bank:savings:update',
  'sonar:bank:transfer:committed',
  'sonar:bank:status:transition',
  'sonar:bank:notice:new',
}

for _, evt in ipairs(FORWARDED_NETEVENTS) do
  RegisterNetEvent(evt)
  AddEventHandler(evt, function(payload)
    SendNUIMessage({
      type    = 'NET_EVENT',
      event   = evt,
      payload = payload,
    })
  end)
end

-- -----------------------------------------------------------------------------
-- §6. Boot signal → React app can listen for resource readiness.
-- -----------------------------------------------------------------------------

AddEventHandler('onClientResourceStart', function(resource)
  if resource ~= GetCurrentResourceName() then return end
  print(('%s ready (resource=%s)'):format(PREFIX, resource))
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
  SendNUIMessage({ type = 'BANK_CLOSE' })
  SendNUIMessage({ type = 'BANK_READY' })
  refresh_player_loaded()
end)
