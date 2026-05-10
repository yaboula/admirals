-- =============================================================================
-- SONAR Bridges — adapters/bank/qbcore.lua
--
-- Adapter QBCore T2 para Bank.
--
-- Usa exports['qb-core']:GetCoreObject() per doc §4.4.2. Tier 2 compat.
-- =============================================================================

local QbcoreBank = {}
local _core = nil

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

local function _with_idem(idem_key, actual_fn)
  if idem_key then
    local replay, cached = Bridges._IsIdemReplay(idem_key)
    if replay then return table.unpack(cached or { true, nil, { replay = true } }) end
  end
  local results = table.pack(actual_fn())
  if idem_key then Bridges._StoreIdem(idem_key, results) end
  return table.unpack(results, 1, results.n)
end

function QbcoreBank.GetBalance(identifier, account_type)
  if type(identifier) ~= 'string' or identifier == '' then
    return nil, 'NOT_FOUND'
  end
  local player = _get_player_by_citizen_id(identifier)
  if not player or not player.PlayerData then return nil, 'NOT_FOUND' end
  local acct = account_type or 'bank'
  local balance = player.PlayerData.money and player.PlayerData.money[acct]
  if balance == nil then return nil, 'NOT_FOUND' end
  return balance, nil
end

function QbcoreBank.AddMoney(identifier, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(identifier) ~= 'string' or identifier == '' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    local player = _get_player_by_citizen_id(identifier)
    if not player or not player.Functions then return false, 'NOT_FOUND' end
    local ok = player.Functions.AddMoney('bank', amount, reason or 'sonar')
    return ok == true, ok == true and nil or 'FAILED'
  end)
end

function QbcoreBank.RemoveMoney(identifier, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(identifier) ~= 'string' or identifier == '' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    local player = _get_player_by_citizen_id(identifier)
    if not player or not player.Functions or not player.PlayerData then return false, 'NOT_FOUND' end
    local balance = player.PlayerData.money and player.PlayerData.money.bank or 0
    if balance < amount then return false, 'INSUFFICIENT_FUNDS' end
    local ok = player.Functions.RemoveMoney('bank', amount, reason or 'sonar')
    return ok == true, ok == true and nil or 'FAILED'
  end)
end

function QbcoreBank.Transfer(from, to, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(from) ~= 'string' or type(to) ~= 'string' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    local from_player = _get_player_by_citizen_id(from)
    local to_player = _get_player_by_citizen_id(to)
    if not from_player or not to_player then return false, 'NOT_FOUND' end
    if not from_player.Functions or not to_player.Functions then return false, 'FAILED' end
    local balance = from_player.PlayerData.money and from_player.PlayerData.money.bank or 0
    if balance < amount then return false, 'INSUFFICIENT_FUNDS' end
    local removed = from_player.Functions.RemoveMoney('bank', amount, reason or 'sonar_transfer')
    if removed ~= true then return false, 'FAILED' end
    local added = to_player.Functions.AddMoney('bank', amount, reason or 'sonar_transfer')
    if added ~= true then
      from_player.Functions.AddMoney('bank', amount, 'sonar_transfer_rollback')
      return false, 'FAILED'
    end
    return true, nil
  end)
end

function QbcoreBank.IsAvailable()
  return _get_core() ~= nil
end

Bridges.RegisterAdapter('bank', 'qbcore', QbcoreBank)
