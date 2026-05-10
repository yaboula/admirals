-- =============================================================================
-- SONAR Bridges — adapters/identity/qbcore.lua
--
-- Adapter QBCore T2 para Identity.
-- =============================================================================

local QbcoreIdentity = {}
local _core = nil
local _src_to_cid = {}
local _cid_to_src = {}

local function _get_core()
  if _core then return _core end
  if GetResourceState('qb-core') ~= 'started' then return nil end
  local ok, core = pcall(function()
    return exports['qb-core']:GetCoreObject()
  end)
  if not ok or type(core) ~= 'table' then return nil end
  _core = core
  return _core
end

local function _is_active()
  return Bridges._active and Bridges._active.identity == 'qbcore'
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

local function _get_player_by_source(src)
  local core = _get_core()
  if not core or not core.Functions then return nil end
  return core.Functions.GetPlayer(tonumber(src))
end

local function _get_player_by_citizen_id(citizen_id)
  local core = _get_core()
  if not core or not core.Functions then return nil end
  if type(core.Functions.GetPlayerByCitizenId) == 'function' then
    return core.Functions.GetPlayerByCitizenId(citizen_id)
  end
  for _, src in ipairs(GetPlayers()) do
    local player = core.Functions.GetPlayer(tonumber(src))
    if player and player.PlayerData and player.PlayerData.citizenid == citizen_id then
      return player
    end
  end
  return nil
end

function QbcoreIdentity.GetCitizenId(source)
  source = tonumber(source)
  if not source or source <= 0 then return nil end
  if _src_to_cid[source] then return _src_to_cid[source] end
  local player = _get_player_by_source(source)
  if not player or not player.PlayerData then return nil end
  local cid = player.PlayerData.citizenid
  if cid then _cache(source, cid) end
  return cid
end

function QbcoreIdentity.GetSource(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  if _cid_to_src[citizenId] then
    if GetPlayerPing(_cid_to_src[citizenId]) > 0 then
      return _cid_to_src[citizenId]
    end
    _cid_to_src[citizenId] = nil
  end
  local player = _get_player_by_citizen_id(citizenId)
  if not player or not player.PlayerData then return nil end
  local src = player.PlayerData.source
  if src then _cache(src, citizenId) end
  return src
end

function QbcoreIdentity.GetPlayerData(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  local player = _get_player_by_citizen_id(citizenId)
  if not player or not player.PlayerData then return nil end
  local pd = player.PlayerData
  local ci = pd.charinfo or {}
  return {
    citizenId = pd.citizenid,
    source = pd.source,
    firstname = ci.firstname or '',
    lastname = ci.lastname or '',
    charinfo = ci,
    name = (ci.firstname or '') .. ' ' .. (ci.lastname or ''),
  }
end

function QbcoreIdentity.GetJob(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  local player = _get_player_by_citizen_id(citizenId)
  if not player or not player.PlayerData then return nil end
  local job = player.PlayerData.job
  if not job or not job.name then return nil end
  return {
    name = job.name,
    grade = job.grade and (job.grade.level or job.grade) or 0,
    label = job.label or job.name,
  }
end

function QbcoreIdentity.IsOnline(citizenId)
  return QbcoreIdentity.GetSource(citizenId) ~= nil
end

function QbcoreIdentity.IsAvailable()
  return _get_core() ~= nil
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
  if not _is_active() then return end
  local pd = player and player.PlayerData
  if not pd then return end
  local src = pd.source
  local cid = pd.citizenid
  if src and cid then
    _cache(src, cid)
    TriggerEvent('sonar:bridge:_identityPlayerLoaded', cid, src)
  end
end)

AddEventHandler('QBCore:Server:PlayerLogout', function(src)
  if not _is_active() then return end
  src = tonumber(src)
  if not src then return end
  local cid = _src_to_cid[src]
  if cid then
    TriggerEvent('sonar:bridge:_identityPlayerDropped', cid, src, 'logout')
    _evict(src)
  end
end)

AddEventHandler('playerDropped', function(reason)
  if not _is_active() then return end
  local src = source
  local cid = _src_to_cid[src]
  if cid then
    TriggerEvent('sonar:bridge:_identityPlayerDropped', cid, src, reason or 'dropped')
    _evict(src)
  end
end)

function QbcoreIdentity._DumpCache()
  local snap = { by_source = {}, by_citizen = {} }
  for k, v in pairs(_src_to_cid) do snap.by_source[k] = v end
  for k, v in pairs(_cid_to_src) do snap.by_citizen[k] = v end
  return snap
end

Bridges.RegisterAdapter('identity', 'qbcore', QbcoreIdentity)
