local EsxBank = {}
local _esx = nil

local function _request_esx()
  if GetResourceState('es_extended') ~= 'started' then return end
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

local function _with_idem(idem_key, actual_fn)
  if idem_key then
    local replay, cached = Bridges._IsIdemReplay(idem_key)
    if replay then return table.unpack(cached or { true, nil, { replay = true } }) end
  end
  local results = table.pack(actual_fn())
  if idem_key then Bridges._StoreIdem(idem_key, results) end
  return table.unpack(results, 1, results.n)
end

local function _get_player_by_identifier(identifier)
  local ESX = _get_esx()
  if not ESX or type(ESX.GetExtendedPlayers) ~= 'function' then return nil end
  for _, player in pairs(ESX.GetExtendedPlayers()) do
    if player and player.identifier == identifier then return player end
  end
  return nil
end

local function _get_account_balance(player, account_type)
  local acct = account_type or 'bank'
  if not player or type(player.getAccount) ~= 'function' then return nil end
  local account = player.getAccount(acct)
  if type(account) ~= 'table' then return nil end
  return account.money
end

function EsxBank.GetBalance(identifier, account_type)
  if type(identifier) ~= 'string' or identifier == '' then
    return nil, 'NOT_FOUND'
  end
  local player = _get_player_by_identifier(identifier)
  if not player then return nil, 'NOT_FOUND' end
  local balance = _get_account_balance(player, account_type)
  if balance == nil then return nil, 'NOT_FOUND' end
  return balance, nil
end

function EsxBank.AddMoney(identifier, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(identifier) ~= 'string' or identifier == '' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    local player = _get_player_by_identifier(identifier)
    if not player or type(player.addAccountMoney) ~= 'function' then return false, 'NOT_FOUND' end
    local ok = pcall(function()
      player.addAccountMoney('bank', amount, reason or 'sonar')
    end)
    return ok == true, ok == true and nil or 'FAILED'
  end)
end

function EsxBank.RemoveMoney(identifier, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(identifier) ~= 'string' or identifier == '' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    local player = _get_player_by_identifier(identifier)
    if not player or type(player.removeAccountMoney) ~= 'function' then return false, 'NOT_FOUND' end
    local balance = _get_account_balance(player, 'bank') or 0
    if balance < amount then return false, 'INSUFFICIENT_FUNDS' end
    local ok = pcall(function()
      player.removeAccountMoney('bank', amount, reason or 'sonar')
    end)
    return ok == true, ok == true and nil or 'FAILED'
  end)
end

function EsxBank.Transfer(from, to, amount, reason, idempotency_key)
  return _with_idem(idempotency_key, function()
    if type(from) ~= 'string' or type(to) ~= 'string' then
      return false, 'NOT_FOUND'
    end
    if type(amount) ~= 'number' or amount < 0 then
      return false, 'VALIDATION_FAILED'
    end
    local from_player = _get_player_by_identifier(from)
    local to_player = _get_player_by_identifier(to)
    if not from_player or not to_player then return false, 'NOT_FOUND' end
    if type(from_player.removeAccountMoney) ~= 'function' or type(to_player.addAccountMoney) ~= 'function' then return false, 'FAILED' end
    local balance = _get_account_balance(from_player, 'bank') or 0
    if balance < amount then return false, 'INSUFFICIENT_FUNDS' end
    local removed = pcall(function()
      from_player.removeAccountMoney('bank', amount, reason or 'sonar_transfer')
    end)
    if removed ~= true then return false, 'FAILED' end
    local added = pcall(function()
      to_player.addAccountMoney('bank', amount, reason or 'sonar_transfer')
    end)
    if added ~= true then
      pcall(function()
        from_player.addAccountMoney('bank', amount, 'sonar_transfer_rollback')
      end)
      return false, 'FAILED'
    end
    return true, nil
  end)
end

function EsxBank.IsAvailable()
  return _wait_esx(1000) ~= nil
end

Bridges.RegisterAdapter('bank', 'esx', EsxBank)
