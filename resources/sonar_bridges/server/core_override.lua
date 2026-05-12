Bridges = Bridges or {}

local Logger = Bridges.Logger
Bridges.CoreOverride = Bridges.CoreOverride or {}
Bridges.MirrorSync = Bridges.MirrorSync or {}
Bridges.Reconcile = Bridges.Reconcile or {}

local CoreOverride = Bridges.CoreOverride
local MirrorSync = Bridges.MirrorSync
local Reconcile = Bridges.Reconcile
local state = { active_bank = nil, qbcore_registered = false, qbox_registered = false, esx_registered = false, queue = {} }

local function framework_amount(balance_minor)
  local minor = tonumber(balance_minor)
  if not minor then return nil end
  return math.floor(minor / 100)
end
local function callable(value)
  if type(value) == 'function' then return true end
  if type(value) ~= 'table' then return false end
  local mt = getmetatable(value)
  return mt and type(mt.__call) == 'function'
end
local function qbcore()
  if GetResourceState('qb-core') ~= 'started' then return nil end
  local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
  return ok and type(core) == 'table' and core or nil
end
local function qbcore_player_by_citizen(citizen_id)
  local core = qbcore()
  if not core or not core.Functions then return nil end
  if callable(core.Functions.GetPlayerByCitizenId) then
    local ok, player = pcall(core.Functions.GetPlayerByCitizenId, citizen_id)
    if ok and player then return player end
  end
  if not callable(core.Functions.GetPlayer) then return nil end
  for _, src in ipairs(GetPlayers()) do
    local ok, player = pcall(core.Functions.GetPlayer, tonumber(src))
    if ok and player and player.PlayerData and player.PlayerData.citizenid == citizen_id then return player end
  end
  return nil
end
local function qbox_player_by_citizen(citizen_id)
  if GetResourceState('qbx_core') ~= 'started' then return nil end
  local ok, player = pcall(function() return exports.qbx_core:GetPlayerByCitizenId(citizen_id) end)
  return ok and player or nil
end
local function esx_object()
  if GetResourceState('es_extended') ~= 'started' then return nil end
  local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
  if ok and type(obj) == 'table' then return obj end
  local esx = nil
  TriggerEvent('esx:getSharedObject', function(obj) if type(obj) == 'table' then esx = obj end end)
  return esx
end
local function esx_player(identifier)
  local ESX = esx_object()
  if not ESX then return nil end
  if callable(ESX.GetPlayerFromIdentifier) then
    local ok, player = pcall(ESX.GetPlayerFromIdentifier, identifier)
    if ok and player then return player end
  end
  if callable(ESX.Player) then
    local ok, player = pcall(ESX.Player, identifier)
    if ok and player then return player end
  end
  return nil
end
local function call_player_method(player, method, ...)
  local fn = player and player[method]
  if not callable(fn) then return false end
  local ok, result = pcall(fn, player, ...)
  if ok then return result ~= false end
  ok, result = pcall(fn, ...)
  return ok and result ~= false
end

function Reconcile.Enqueue(item)
  if type(item) ~= 'table' then return false end
  item.enqueued_at = item.enqueued_at or GetGameTimer()
  state.queue[#state.queue + 1] = item
  if Logger and Logger.Warn then Logger.Warn('Money authority reconcile queued framework=%s reason=%s', tostring(item.framework), tostring(item.reason)) end
  return true
end
function Reconcile.GetQueueStats()
  return { pending = #state.queue }
end
function Reconcile.Run(opts)
  opts = opts or {}
  local applied, failed = 0, 0
  local balance_minor = opts.balance_minor or opts.target_balance_minor
  if type(opts.citizen_id) == 'string' and type(balance_minor) == 'number' then
    local result = MirrorSync.SetBalance(opts.citizen_id, balance_minor, opts)
    if result.ok then applied = applied + 1 else failed = failed + 1 end
  end
  local pending = #state.queue
  if opts.drain == true then state.queue = {} end
  return { summary = { mode = opts.mode or 'admin_triggered', applied = applied, failed = failed, pending = pending, drained = opts.drain == true } }
end

local function mirror_qbcore(citizen_id, balance_minor)
  local amount = framework_amount(balance_minor)
  if not amount then return { ok = false, error = 'INVALID_AMOUNT', framework = 'qbcore' } end
  local player = qbcore_player_by_citizen(citizen_id)
  local set = player and player.Functions and player.Functions.SetMoney
  if not callable(set) then return { ok = false, error = 'SET_UNAVAILABLE', framework = 'qbcore' } end
  local ok, result = pcall(set, 'bank', amount, 'sonar_mirror_sync')
  if not ok then ok, result = pcall(set, player, 'bank', amount, 'sonar_mirror_sync') end
  return ok and result ~= false and { ok = true, framework = 'qbcore', balance = amount } or { ok = false, error = 'FAILED', framework = 'qbcore' }
end
local function mirror_qbox(citizen_id, balance_minor)
  local amount = framework_amount(balance_minor)
  if not amount then return { ok = false, error = 'INVALID_AMOUNT', framework = 'qbox' } end
  local player = qbox_player_by_citizen(citizen_id)
  local set = player and player.Functions and player.Functions.SetMoney
  if not callable(set) then return { ok = false, error = 'SET_UNAVAILABLE', framework = 'qbox' } end
  local ok, result = pcall(set, 'bank', amount, 'sonar_mirror_sync')
  if not ok then ok, result = pcall(set, player, 'bank', amount, 'sonar_mirror_sync') end
  return ok and result ~= false and { ok = true, framework = 'qbox', balance = amount } or { ok = false, error = 'FAILED', framework = 'qbox' }
end
local function mirror_esx(citizen_id, balance_minor)
  local amount = framework_amount(balance_minor)
  if not amount then return { ok = false, error = 'INVALID_AMOUNT', framework = 'esx' } end
  local player = esx_player(citizen_id)
  if not player then return { ok = false, error = 'NOT_FOUND', framework = 'esx' } end
  return call_player_method(player, 'setAccountMoney', 'bank', amount, 'sonar_mirror_sync') and { ok = true, framework = 'esx', balance = amount } or { ok = false, error = 'FAILED', framework = 'esx' }
end
function MirrorSync.SetBalance(citizen_id, balance_minor, opts)
  opts = opts or {}
  if type(citizen_id) ~= 'string' or citizen_id == '' then return { ok = false, error = 'INVALID_CITIZEN_ID' } end
  local active = opts.framework or state.active_bank or (Bridges._active and Bridges._active.bank) or 'native'
  if active == 'native' then return { ok = true, framework = 'native', noop = true } end
  if active == 'qbcore' then return mirror_qbcore(citizen_id, balance_minor) end
  if active == 'qbox' then return mirror_qbox(citizen_id, balance_minor) end
  if active == 'esx' then return mirror_esx(citizen_id, balance_minor) end
  return { ok = false, error = 'UNSUPPORTED_FRAMEWORK', framework = active }
end

local function mirror_mode()
  local mode = GetConvar('sonar_bridge_bank_mode', 'standalone')
  return mode == 'mirror' or mode == 'synced'
end
local function login_mirror_sync(citizen_id, src)
  if not mirror_mode() or type(citizen_id) ~= 'string' or citizen_id == '' then return end
  if GetResourceState('sonar_bank_app') ~= 'started' then return end
  local ok, balance_minor = pcall(function() return exports.sonar_bank_app:GetPrimaryBalanceMinor(citizen_id) end)
  if not ok or type(balance_minor) ~= 'number' then return end
  local result = MirrorSync.SetBalance(citizen_id, balance_minor, { reason = 'login_sync', correlation_id = ('login|%s|%s'):format(tostring(src or '?'), tostring(GetGameTimer())) })
  if Logger and Logger.Info then Logger.Info('login_mirror_sync cid=%s src=%s sonar_minor=%d ok=%s err=%s', tostring(citizen_id), tostring(src or '?'), balance_minor, tostring(type(result) == 'table' and result.ok == true), tostring(type(result) == 'table' and result.error or 'nil')) end
end
local function register_qbcore_login()
  if state.qbcore_registered then return true end
  AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local data = player and player.PlayerData or nil
    login_mirror_sync(data and data.citizenid, data and data.source)
  end)
  state.qbcore_registered = true
  return true
end
local function register_qbox_login()
  if state.qbox_registered then return true end
  AddEventHandler('qbx_core:server:playerLoaded', function(player)
    local data = player and player.PlayerData or nil
    login_mirror_sync(data and data.citizenid, data and data.source)
  end)
  state.qbox_registered = true
  return true
end
local function register_esx_login()
  if state.esx_registered then return true end
  AddEventHandler('esx:playerLoaded', function(player_id, xPlayer)
    local citizen_id = xPlayer and (xPlayer.identifier or (xPlayer.getIdentifier and xPlayer.getIdentifier()))
    login_mirror_sync(citizen_id, player_id)
  end)
  state.esx_registered = true
  return true
end
function CoreOverride.Boot(active_bank)
  state.active_bank = active_bank or (Bridges._active and Bridges._active.bank) or 'native'
  if state.active_bank == 'qbcore' then return register_qbcore_login() end
  if state.active_bank == 'qbox' then return register_qbox_login() end
  if state.active_bank == 'esx' then return register_esx_login() end
  return true
end
function CoreOverride.GetHealth()
  return { active_bank = state.active_bank, qbcore_registered = state.qbcore_registered, qbox_registered = state.qbox_registered, esx_registered = state.esx_registered, reconcile = Reconcile.GetQueueStats() }
end

exports('MirrorSyncBalance', function(citizen_id, balance_minor, opts)
  opts = opts or {}
  local result = MirrorSync.SetBalance(citizen_id, balance_minor, opts)
  if type(result) == 'table' and result.ok == false then Reconcile.Enqueue({ framework = result.framework or state.active_bank or 'native', operation = 'mirror_failed', citizen_id = citizen_id, target_balance_minor = balance_minor, reason = opts.reason or 'mirror_sync_failed', correlation_id = opts.correlation_id, idempotency_key = opts.idempotency_key, error = result.error }) end
  return result
end)
exports('ReconcileRun', function(opts) return Reconcile.Run(opts or {}) end)
exports('ReconcileEnqueue', function(item) return Reconcile.Enqueue(item or {}) end)