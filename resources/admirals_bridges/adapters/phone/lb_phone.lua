-- =============================================================================
-- Admirals Bridges — adapters/phone/lb_phone.lua
--
-- Adapter lb-phone T1 para Phone.
--
-- Usa exports['lb-phone'] per doc §6.4. Tier 1 oficial.
--
-- lb-phone v2.x API usada:
--   exports['lb-phone']:SendNotification(source, data)
--     data = { title, content, icon?, app?, duration?, type? }
--
-- SendSMS:
--   lb-phone no expone una API pública de "enviar SMS servidor→número" en todos
--   builds v2.x. Implementado como notificación enriquecida con app='messages'
--   como mejor aproximación (player ve la notificación en el app de mensajes).
--   Si lb-phone expone API de mensajes en tu build, extiende esta función.
--
-- StartCall:
--   lb-phone llama voice requiere inicialización en client side. Este adapter
--   no implementa StartCall (retorna 'UNSUPPORTED') hasta que lb-phone exponga
--   un export server-side estable y documentado para iniciar calls.
--   [FLAG para founder: si tu build de lb-phone tiene exports.['lb-phone']:StartCall,
--   implementar aquí con la firma documentada en tu versión].
--
-- GetPhoneNumber:
--   Número de teléfono almacenado en Player.PlayerData.charinfo.phone (QBox).
--   Se obtiene via Bridges.Identity.GetPlayerData(citizenId).charinfo.phone.
--   Fallback: export exports['lb-phone']:GetPlayerInfo(source) si disponible.
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §6.2 interface, §6.4 adapter.
-- =============================================================================

local Logger = Bridges.Logger
local LbPhone = {}

-- Helper: citizenId → source via adapter de identity activo.
local function _get_source(citizenId)
  return Bridges.Identity.GetSource(citizenId)
end

-- -----------------------------------------------------------------------------
-- SendNotification
-- -----------------------------------------------------------------------------
---@param citizenId string
---@param opts table { title, message, icon?, app?, duration? }
---@return boolean success
function LbPhone.SendNotification(citizenId, opts)
  if type(citizenId) ~= 'string' or type(opts) ~= 'table' then return false end
  local source = _get_source(citizenId)
  if not source then
    Logger.Warn('LbPhone.SendNotification: player offline cid=%s', citizenId)
    return false
  end
  exports['lb-phone']:SendNotification(source, {
    title    = opts.title   or '[Admirals]',
    content  = opts.message or opts.content or '',
    icon     = opts.icon,
    app      = opts.app,
    duration = opts.duration,
  })
  return true
end

-- -----------------------------------------------------------------------------
-- SendSMS
-- Implementado como notificación lb-phone con app='messages'.
-- Player verá la notificación en el teléfono como mensaje entrante.
-- -----------------------------------------------------------------------------
---@param citizenId_to string
---@param citizenId_from string
---@param message string
---@return boolean success
function LbPhone.SendSMS(citizenId_to, citizenId_from, message)
  if type(citizenId_to) ~= 'string' or type(message) ~= 'string' then
    return false
  end
  local source_to = _get_source(citizenId_to)
  if not source_to then
    Logger.Warn('LbPhone.SendSMS: recipient offline cid=%s', citizenId_to)
    return false
  end
  -- Resolución del nombre del remitente si disponible.
  local from_label = citizenId_from or 'Admirals'
  local pd_from = citizenId_from and Bridges.Identity.GetPlayerData(citizenId_from)
  if pd_from then
    from_label = pd_from.name or citizenId_from
  end

  exports['lb-phone']:SendNotification(source_to, {
    title   = from_label,
    content = message,
    app     = 'messages',
    icon    = 'sms',
  })
  Logger.Debug('LbPhone.SendSMS: %s → %s: %s', tostring(citizenId_from), citizenId_to, message)
  return true
end

-- -----------------------------------------------------------------------------
-- StartCall — UNSUPPORTED en S0.3.
-- lb-phone no expone export server-side documentado para iniciar voice calls.
-- [FLAG: implementar si tu build expone exports['lb-phone']:StartCall(src_to, src_from)].
-- -----------------------------------------------------------------------------
---@param citizenId_to string
---@param citizenId_from string
---@param opts table|nil
---@return boolean success
---@return string error 'UNSUPPORTED'
function LbPhone.StartCall(citizenId_to, citizenId_from, opts)
  Logger.Warn('LbPhone.StartCall: not implemented — lb-phone server-side call API not exposed. '
    .. 'Use client-side lb-phone call UI.')
  return false, 'UNSUPPORTED'
end

-- -----------------------------------------------------------------------------
-- GetPhoneNumber
-- Prioridad: charinfo.phone (QBox playerdata) → exports lb-phone GetPlayerInfo
-- → fallback nil con warning.
-- -----------------------------------------------------------------------------
---@param citizenId string
---@return string|nil phone_number
function LbPhone.GetPhoneNumber(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end

  -- Prioridad 1: QBox charinfo (más ligero — no requiere call extra a lb-phone).
  local pd = Bridges.Identity.GetPlayerData(citizenId)
  if pd and pd.charinfo and type(pd.charinfo.phone) == 'string' and pd.charinfo.phone ~= '' then
    return pd.charinfo.phone
  end

  -- Prioridad 2: export lb-phone:GetPlayerInfo si disponible en este build.
  local source = _get_source(citizenId)
  if source then
    local ok, info = pcall(function()
      return exports['lb-phone']:GetPlayerInfo(source)
    end)
    if ok and type(info) == 'table' and info.phone_number then
      return info.phone_number
    end
  end

  Logger.Debug('LbPhone.GetPhoneNumber: no phone number found for cid=%s', citizenId)
  return nil
end

-- -----------------------------------------------------------------------------
-- IsAvailable
-- -----------------------------------------------------------------------------
function LbPhone.IsAvailable()
  return GetResourceState('lb-phone') == 'started'
end

Bridges.RegisterAdapter('phone', 'lb_phone', LbPhone)
