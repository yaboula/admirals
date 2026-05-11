local EsxBank = {}
local _esx = nil

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

local function _with_idem(idem_key, actual_fn)
  if idem_key then
    local replay, cached = Bridges._IsIdemReplay(idem_key)
    if replay then return table.unpack(cached or { true, nil, { replay = true } }) end
  end
  local results = table.pack(actual_fn())
  if idem_key then Bridges._StoreIdem(idem_key, results) end
  return table.unpack(results, 1, results.n)
end

local function _call_esx(ESX, method, ...)
  local fn = ESX and ESX[method] or nil
  if not fn then return nil end
  local ok, result = pcall(fn, ...)
  if ok then return result end
  return nil
end

local function _call_player(player, method, ...)
  local fn = player and player[method] or nil
  if not fn then return false, nil end
  local ok, result = pcall(fn, ...)
  if ok then return true, result end
  return false, nil
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

local function _get_account_balance(player, account_type)
  local acct = account_type or 'bank'
  local ok, account = _call_player(player, 'getAccount', acct)
  if not ok then return nil end
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
    if not player then return false, 'NOT_FOUND' end
    local ok = _call_player(player, 'addAccountMoney', 'bank', amount, reason or 'sonar')
    if ok == true then return true, nil end
    return false, 'FAILED'
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
    if not player then return false, 'NOT_FOUND' end
    local balance = _get_account_balance(player, 'bank') or 0
    if balance < amount then return false, 'INSUFFICIENT_FUNDS' end
    local ok = _call_player(player, 'removeAccountMoney', 'bank', amount, reason or 'sonar')
    if ok == true then return true, nil end
    return false, 'FAILED'
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
    local balance = _get_account_balance(from_player, 'bank') or 0
    if balance < amount then return false, 'INSUFFICIENT_FUNDS' end
    local removed = _call_player(from_player, 'removeAccountMoney', 'bank', amount, reason or 'sonar_transfer')
    if removed ~= true then return false, 'FAILED' end
    local added = _call_player(to_player, 'addAccountMoney', 'bank', amount, reason or 'sonar_transfer')
    if added ~= true then
      _call_player(from_player, 'addAccountMoney', 'bank', amount, 'sonar_transfer_rollback')
      return false, 'FAILED'
    end
    return true, nil
  end)
end

function EsxBank.IsAvailable()
  return _wait_esx(1000) ~= nil
end

Bridges.RegisterAdapter('bank', 'esx', EsxBank)
