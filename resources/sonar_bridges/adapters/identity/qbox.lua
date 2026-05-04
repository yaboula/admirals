-- =============================================================================
-- SONAR Bridges — adapters/identity/qbox.lua
--
-- Adapter QBox T1 para Identity.
--
-- Usa exports.qbx_core per doc §7.4. Tier 1 oficial.
--
-- QBox API usada:
--   exports.qbx_core:GetPlayer(source)               → Player | nil
--   exports.qbx_core:GetPlayerByCitizenId(citizenId)  → Player | nil
--   Player.PlayerData.citizenid                       → string
--   Player.PlayerData.source                          → number
--   Player.PlayerData.charinfo.{firstname,lastname}   → string
--   Player.PlayerData.job.{name,grade.level,label}    → table
--
-- Cache bidireccional src ↔ citizenId para evitar round-trips en hot paths.
--
-- Lifecycle hooks:
--   'QBCore:Server:PlayerLoaded'  → fires server-side con Player object al cargar
--                                     personaje (qbx_core/server/player.lua:1031).
--                                     OJO: NO confundir con 'QBCore:Server:OnPlayerLoaded'
--                                     que es un NetEvent client→server SIN payload
--                                     (qbx_core/client/character.lua:279,306,497).
--   'QBCore:Server:PlayerLogout'   → fires con src al logout de personaje.
--   'playerDropped'               → FiveM native safety-net para drops totales.
--   Guard _is_active() evita eventos duplicados si el adapter no es el activo.
--
-- Lifecycle hooks emiten: sonar:bridge:_identityPlayerLoaded / sonar:bridge:_identityPlayerDropped.
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §7.2 interface, §7.4 adapter.
-- =============================================================================

local Logger = Bridges.Logger
local QboxIdentity = {}

-- Caches bidireccionales invalidadas en playerDropped / PlayerLogout.
local _src_to_cid = {}   -- [source]    = citizenId
local _cid_to_src = {}   -- [citizenId] = source

local function _is_active()
  return Bridges._active and Bridges._active.identity == 'qbox'
end

local function _cache(src, cid)
  _src_to_cid[src] = cid
  _cid_to_src[cid] = src
end

local function _evict(src)
  local cid = _src_to_cid[src]
  if cid then _cid_to_src[cid] = nil end
  _src_to_cid[src] = nil
end

-- -----------------------------------------------------------------------------
-- GetCitizenId
-- -----------------------------------------------------------------------------
---@param source number server id
---@return string|nil citizenId
function QboxIdentity.GetCitizenId(source)
  source = tonumber(source)
  if not source or source <= 0 then return nil end
  if _src_to_cid[source] then return _src_to_cid[source] end
  local Player = exports.qbx_core:GetPlayer(source)
  if not Player then return nil end
  local cid = Player.PlayerData.citizenid
  if cid then _cache(source, cid) end
  return cid
end

-- -----------------------------------------------------------------------------
-- GetSource
-- -----------------------------------------------------------------------------
---@param citizenId string
---@return number|nil source (nil si offline)
function QboxIdentity.GetSource(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  if _cid_to_src[citizenId] then
    if GetPlayerPing(_cid_to_src[citizenId]) > 0 then
      return _cid_to_src[citizenId]
    end
    _cid_to_src[citizenId] = nil
  end
  local Player = exports.qbx_core:GetPlayerByCitizenId(citizenId)
  if not Player then return nil end
  local src = Player.PlayerData.source
  if src then _cache(src, citizenId) end
  return src
end

-- -----------------------------------------------------------------------------
-- GetPlayerData — shape canónico per doc §7.2.
-- -----------------------------------------------------------------------------
---@param citizenId string
---@return table|nil { citizenId, source, firstname, lastname, charinfo, name }
function QboxIdentity.GetPlayerData(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  local Player = exports.qbx_core:GetPlayerByCitizenId(citizenId)
  if not Player then return nil end
  local pd = Player.PlayerData
  local ci = pd.charinfo or {}
  return {
    citizenId = pd.citizenid,
    source    = pd.source,
    firstname = ci.firstname or '',
    lastname  = ci.lastname  or '',
    charinfo  = ci,
    name      = (ci.firstname or '') .. ' ' .. (ci.lastname or ''),
  }
end

-- -----------------------------------------------------------------------------
-- GetJob — job framework SOLO (NO empresa SONAR per doc §7.3).
-- -----------------------------------------------------------------------------
---@param citizenId string
---@return table|nil { name, grade, label }
function QboxIdentity.GetJob(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  local Player = exports.qbx_core:GetPlayerByCitizenId(citizenId)
  if not Player then return nil end
  local job = Player.PlayerData.job
  if not job or not job.name then return nil end
  return {
    name  = job.name,
    grade = job.grade and job.grade.level or 0,
    label = job.label or job.name,
  }
end

-- -----------------------------------------------------------------------------
-- IsOnline
-- -----------------------------------------------------------------------------
---@param citizenId string
---@return boolean
function QboxIdentity.IsOnline(citizenId)
  return QboxIdentity.GetSource(citizenId) ~= nil
end

-- -----------------------------------------------------------------------------
-- IsAvailable
-- -----------------------------------------------------------------------------
function QboxIdentity.IsAvailable()
  return GetResourceState('qbx_core') == 'started'
end

-- =============================================================================
-- Lifecycle hooks — QBox events → eventos internos sonar:bridge:_identity*.
-- Solo activos cuando este adapter es el seleccionado (_is_active guard).
-- =============================================================================

-- QBox: personaje cargado (character selected por el player).
-- Evento canónico SERVER-SIDE per qbx_core/server/player.lua:1031 — recibe el
-- Player object como argumento. NO usar 'QBCore:Server:OnPlayerLoaded' (NetEvent
-- client→server sin payload, qbx_core/client/character.lua + server/events.lua:185).
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
  if not _is_active() then return end
  local pd = Player and Player.PlayerData
  if not pd then return end
  local src = pd.source
  local cid = pd.citizenid
  if src and cid then
    _cache(src, cid)
    TriggerEvent('sonar:bridge:_identityPlayerLoaded', cid, src)
    Logger.Debug('QboxIdentity: player loaded src=%d cid=%s', src, cid)
  end
end)

-- QBox: logout de personaje (player sigue conectado — solo abandona personaje).
AddEventHandler('QBCore:Server:PlayerLogout', function(src)
  if not _is_active() then return end
  src = tonumber(src)
  if not src then return end
  local cid = _src_to_cid[src]
  if cid then
    TriggerEvent('sonar:bridge:_identityPlayerDropped', cid, src, 'logout')
    Logger.Debug('QboxIdentity: player logout src=%d cid=%s', src, cid)
    _evict(src)
  end
end)

-- FiveM native: desconexión total (safety-net para drops sin QBCore:PlayerLogout).
AddEventHandler('playerDropped', function(reason)
  if not _is_active() then return end
  local src = source
  local cid = _src_to_cid[src]
  if cid then
    TriggerEvent('sonar:bridge:_identityPlayerDropped', cid, src, reason or 'dropped')
    Logger.Debug('QboxIdentity: player dropped src=%d cid=%s', src, cid)
    _evict(src)
  end
end)

-- =============================================================================
-- Debug helpers
-- =============================================================================

---@return table { by_source, by_citizen }
function QboxIdentity._DumpCache()
  local snap = { by_source = {}, by_citizen = {} }
  for k, v in pairs(_src_to_cid) do snap.by_source[k]  = v end
  for k, v in pairs(_cid_to_src) do snap.by_citizen[k] = v end
  return snap
end

function QboxIdentity._Reset()
  _src_to_cid = {}
  _cid_to_src = {}
end

Bridges.RegisterAdapter('identity', 'qbox', QboxIdentity)
