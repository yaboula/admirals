local EsxIdentity = {}
local _esx = nil
local _src_to_cid = {}
local _cid_to_src = {}

local function _request_esx()
  if GetResourceState('es_extended') ~= 'started' then return end
  local ok, obj = pcall(function()
    return exports['es_extended']:getSharedObject()
  end)
  if ok and type(obj) == 'table' then
    _esx = obj
    return
  end
  TriggerEvent('esx:getSharedObject', function(obj)
    if type(obj) == 'table' then _esx = obj end
  end)
end

local function _get_esx()
  if _esx then return _esx end
  _request_esx()
  return _esx
end

local function _wait_esx(timeout_ms)
  local deadline = GetGameTimer() + (timeout_ms or 1000)
  while not _esx and GetGameTimer() < deadline do
    _request_esx()
    Wait(25)
  end
  return _esx
end

CreateThread(function()
  while not _esx do
    _request_esx()
    if _esx or GetResourceState('es_extended') ~= 'started' then return end
    Wait(250)
  end
end)

local function _is_active()
  return Bridges._active and Bridges._active.identity == 'esx'
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

local function _call_esx(ESX, method, ...)
  local fn = ESX and ESX[method] or nil
  if not fn then return nil end
  local ok, result = pcall(fn, ...)
  if ok then return result end
  return nil
end

local function _get_player_by_source(src)
  local ESX = _get_esx()
  return _call_esx(ESX, 'GetPlayerFromId', tonumber(src))
end

local function _get_player_by_identifier(identifier)
  local ESX = _get_esx()
  if not ESX then return nil end
  local player = _call_esx(ESX, 'GetPlayerFromIdentifier', identifier)
  if player then return player end
  player = _call_esx(ESX, 'Player', identifier)
  if player then return player end
  return nil
end

local function _get_name_parts(player)
  local firstname = ''
  local lastname = ''
  if player and type(player.get) == 'function' then
    firstname = player.get('firstName') or player.get('firstname') or ''
    lastname = player.get('lastName') or player.get('lastname') or ''
  end
  if (firstname == '' and lastname == '') and player and type(player.getName) == 'function' then
    firstname = player.getName() or ''
  end
  return firstname, lastname
end

function EsxIdentity.GetCitizenId(source)
  source = tonumber(source)
  if not source or source <= 0 then return nil end
  if _src_to_cid[source] then return _src_to_cid[source] end
  local player = _get_player_by_source(source)
  if not player then return nil end
  local cid = player.identifier
  if cid then _cache(source, cid) end
  return cid
end

function EsxIdentity.GetSource(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  if _cid_to_src[citizenId] then
    if GetPlayerPing(_cid_to_src[citizenId]) > 0 then
      return _cid_to_src[citizenId]
    end
    _cid_to_src[citizenId] = nil
  end
  local player = _get_player_by_identifier(citizenId)
  if not player then return nil end
  local src = player.source
  if src then _cache(src, citizenId) end
  return src
end

function EsxIdentity.GetPlayerData(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  local player = _get_player_by_identifier(citizenId)
  if not player then return nil end
  local firstname, lastname = _get_name_parts(player)
  local charinfo = {
    firstname = firstname,
    lastname = lastname,
  }
  return {
    citizenId = player.identifier,
    source = player.source,
    firstname = firstname,
    lastname = lastname,
    charinfo = charinfo,
    name = firstname .. ' ' .. lastname,
  }
end

function EsxIdentity.GetJob(citizenId)
  if type(citizenId) ~= 'string' or citizenId == '' then return nil end
  local player = _get_player_by_identifier(citizenId)
  if not player then return nil end
  local job = player.job
  if not job or not job.name then return nil end
  return {
    name = job.name,
    grade = job.grade or 0,
    label = job.label or job.name,
  }
end

function EsxIdentity.IsOnline(citizenId)
  return EsxIdentity.GetSource(citizenId) ~= nil
end

function EsxIdentity.IsAvailable()
  return _wait_esx(1000) ~= nil
end

AddEventHandler('esx:playerLoaded', function(src, player)
  if not _is_active() then return end
  src = tonumber(src)
  player = player or _get_player_by_source(src)
  if not src or not player then return end
  local cid = player.identifier
  if cid then
    _cache(src, cid)
    TriggerEvent('sonar:bridge:_identityPlayerLoaded', cid, src)
  end
end)

AddEventHandler('esx:playerDropped', function(src, reason)
  if not _is_active() then return end
  src = tonumber(src)
  if not src then return end
  local cid = _src_to_cid[src]
  if cid then
    TriggerEvent('sonar:bridge:_identityPlayerDropped', cid, src, reason or 'dropped')
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

function EsxIdentity._DumpCache()
  local snap = { by_source = {}, by_citizen = {} }
  for k, v in pairs(_src_to_cid) do snap.by_source[k] = v end
  for k, v in pairs(_cid_to_src) do snap.by_citizen[k] = v end
  return snap
end

Bridges.RegisterAdapter('identity', 'esx', EsxIdentity)
