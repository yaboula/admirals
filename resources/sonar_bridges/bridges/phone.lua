-- =============================================================================
-- SONAR Bridges — bridges/phone.lua
--
-- Bridges.Phone — notifications / SMS / calls al phone script externo.
--
-- Responsabilidad (per doc §6.1):
--   Si el customer tiene phone script separado (lb-phone, qs-smartphone, etc.)
--   SONAR lo usa. Si no, fallback native al Tablet SONAR (S1+) o log.
--
-- Importante:
--   Phone es CANAL NICE-TO-HAVE, nunca crítico de negocio (per doc §6.5). El
--   canal crítico es Tablet + audit log.
--   StartCall no soportado por adapter native (per doc §6.3).
--
-- Firmas literales de doc §6.2.
-- =============================================================================

Bridges = Bridges or {}
Bridges.Phone = {}

Bridges.Phone._required_methods = {
  'SendNotification', 'SendSMS', 'StartCall', 'GetPhoneNumber', 'IsAvailable',
}

-- =============================================================================
-- Public API (per doc §6.2)
-- =============================================================================

--- Bridges.Phone.SendNotification
---@param citizenId string
---@param opts table { title, message, icon?, app?, duration? }
---@return boolean success
function Bridges.Phone.SendNotification(citizenId, opts)
  return Bridges.Dispatcher.Call('phone', 'SendNotification',
    { citizenId, opts, n = 2 })
end

--- Bridges.Phone.SendSMS
---@param citizenId_to string
---@param citizenId_from string
---@param message string
---@return boolean success
function Bridges.Phone.SendSMS(citizenId_to, citizenId_from, message)
  return Bridges.Dispatcher.Call('phone', 'SendSMS',
    { citizenId_to, citizenId_from, message, n = 3 })
end

--- Bridges.Phone.StartCall — voice call (adapter-dependent).
---@param citizenId_to string
---@param citizenId_from string
---@param opts table|nil
---@return boolean success
---@return string|nil error 'UNSUPPORTED' para native adapter.
function Bridges.Phone.StartCall(citizenId_to, citizenId_from, opts)
  return Bridges.Dispatcher.Call('phone', 'StartCall',
    { citizenId_to, citizenId_from, opts, n = 3 })
end

--- Bridges.Phone.GetPhoneNumber
---@param citizenId string
---@return string|nil phone_number
function Bridges.Phone.GetPhoneNumber(citizenId)
  return Bridges.Dispatcher.Call('phone', 'GetPhoneNumber',
    { citizenId, n = 1 })
end

--- Bridges.Phone.IsAvailable — true si phone script externo activo.
---@return boolean
function Bridges.Phone.IsAvailable()
  local active = Bridges._active and Bridges._active.phone
  return active ~= nil and active ~= 'native'
end
