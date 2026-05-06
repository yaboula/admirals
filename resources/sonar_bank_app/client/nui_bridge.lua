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
    return lib.callback.await(event_name, false, payload)
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

RegisterNUICallback('open', function(_, cb)
  if not nui_focused then
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    nui_focused = true
  end
  cb({ ok = true, data = { focused = true } })
end)

RegisterNUICallback('close', function(_, cb)
  if nui_focused then
    SetNuiFocus(false, false)
    nui_focused = false
  end
  cb({ ok = true, data = { focused = false } })
end)

-- -----------------------------------------------------------------------------
-- §4. Optional: command + key mapping to toggle Bank UI (DevOps Phase E will refine)
-- -----------------------------------------------------------------------------

RegisterCommand('bank', function()
  if nui_focused then
    SendNUIMessage({ type = 'BANK_CLOSE' })
    SetNuiFocus(false, false)
    nui_focused = false
  else
    SendNUIMessage({ type = 'BANK_OPEN' })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    nui_focused = true
  end
end, false)

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
  SendNUIMessage({ type = 'BANK_READY' })
end)
