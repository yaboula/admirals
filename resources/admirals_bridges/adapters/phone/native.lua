-- =============================================================================
-- Admirals Bridges — adapters/phone/native.lua
--
-- Adapter NATIVE (fallback) para Phone.
--
-- Comportamiento (per doc §6.3 + §11.2):
--   SendNotification → log + StateBag `admirals:phone:lastNotification:<citizenId>`
--                      (cuando Tablet S1+ lo consumirá).
--   SendSMS          → log + StateBag `admirals:phone:lastSMS:<citizenId>`.
--   StartCall        → UNSUPPORTED (voice requires dedicated script).
--   GetPhoneNumber   → número sintético derivado de hash(citizenId).
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §6.2, §6.3, §11.2.
-- =============================================================================

local Logger = Bridges.Logger
local NativePhone = {}

-- -----------------------------------------------------------------------------
-- Helper — sintetizar phone number determinístico de un citizenId.
-- Formato: 555-XXXX (hash simple). Garantiza mismo number entre restarts.
-- -----------------------------------------------------------------------------
local function _synth_number(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  local sum = 0
  for i = 1, #citizenId do
    sum = (sum * 31 + citizenId:byte(i)) % 10000
  end
  return string.format('555-%04d', sum)
end

-- -----------------------------------------------------------------------------
-- SendNotification
-- -----------------------------------------------------------------------------
function NativePhone.SendNotification(citizenId, opts)
  if type(citizenId) ~= 'string' or type(opts) ~= 'table' then
    return false
  end
  opts.title = opts.title or '[Admirals]'
  opts.message = opts.message or ''

  Logger.Info('Phone(native) notify → %s: %s — %s',
    citizenId, opts.title, opts.message)

  -- StateBag global (Tablet S1+ consumirá esto).
  -- Nota: native no tiene acceso a `source` desde citizenId sin Identity bridge,
  -- así que usamos global bag con citizenId key.
  GlobalState[('admirals:phone:lastNotification:%s'):format(citizenId)] = {
    title = opts.title,
    message = opts.message,
    icon = opts.icon,
    app = opts.app,
    ts = os.time(),
  }
  return true
end

-- -----------------------------------------------------------------------------
-- SendSMS
-- -----------------------------------------------------------------------------
function NativePhone.SendSMS(citizenId_to, citizenId_from, message)
  if type(citizenId_to) ~= 'string' or type(message) ~= 'string' then
    return false
  end

  Logger.Info('Phone(native) SMS %s → %s: %s',
    tostring(citizenId_from), citizenId_to, message)

  GlobalState[('admirals:phone:lastSMS:%s'):format(citizenId_to)] = {
    from = citizenId_from,
    message = message,
    ts = os.time(),
  }
  return true
end

-- -----------------------------------------------------------------------------
-- StartCall — UNSUPPORTED en native (voice requires script dedicado).
-- -----------------------------------------------------------------------------
function NativePhone.StartCall(citizenId_to, citizenId_from, opts)
  Logger.Warn('Phone(native) StartCall unsupported — install lb-phone or equivalent')
  return false, 'UNSUPPORTED'
end

-- -----------------------------------------------------------------------------
-- GetPhoneNumber — sintético determinístico.
-- -----------------------------------------------------------------------------
function NativePhone.GetPhoneNumber(citizenId)
  return _synth_number(citizenId)
end

-- -----------------------------------------------------------------------------
-- IsAvailable — native siempre disponible.
-- -----------------------------------------------------------------------------
function NativePhone.IsAvailable()
  return true
end

Bridges.RegisterAdapter('phone', 'native', NativePhone)
