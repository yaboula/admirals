if GetConvarInt('sonar_dev_mode', 0) ~= 1 then return end

local function log(message)
  print('^5[ST-022 ESX]^7 ' .. tostring(message))
end

local function uuid()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return (template:gsub('[xy]', function(c)
    local v = c == 'x' and math.random(0, 15) or math.random(8, 11)
    return ('%x'):format(v)
  end))
end

local function get_esx(timeout_ms)
  local esx
  local deadline = GetGameTimer() + (timeout_ms or 3000)
  while not esx and GetGameTimer() < deadline do
    local ok, obj = pcall(function()
      return exports['es_extended']:getSharedObject()
    end)
    if ok and type(obj) == 'table' then
      esx = obj
      break
    end
    TriggerEvent('esx:getSharedObject', function(obj)
      if type(obj) == 'table' then esx = obj end
    end)
    if not esx then Wait(50) end
  end
  return esx
end

local function raw_bank_balance(player)
  local fn = player and player.getAccount or nil
  if not fn then return nil end
  local ok, account = pcall(fn, 'bank')
  if not ok then return nil end
  return type(account) == 'table' and tonumber(account.money) or nil
end

local function account_names(player)
  local fn = player and player.getAccounts or nil
  if not fn then return 'none' end
  local ok, accounts = pcall(fn)
  if not ok then return 'none' end
  local names = {}
  if type(accounts) == 'table' then
    for _, account in pairs(accounts) do
      if type(account) == 'table' then
        names[#names + 1] = tostring(account.name) .. '=' .. tostring(account.money)
      end
    end
  end
  table.sort(names)
  return #names > 0 and table.concat(names, ',') or 'empty'
end

local function get_player_by_source(ESX, source_id)
  local fn = ESX and ESX.GetPlayerFromId or nil
  if not fn then return nil end
  local ok, player = pcall(fn, tonumber(source_id))
  if ok then return player end
  return nil
end

local function wait_player_by_source(ESX, source_id, timeout_ms)
  local deadline = GetGameTimer() + (timeout_ms or 10000)
  local player = get_player_by_source(ESX, source_id)
  while not player and GetGameTimer() < deadline do
    Wait(250)
    player = get_player_by_source(ESX, source_id)
  end
  return player
end

local function record(results, id, name, passed, details)
  results[#results + 1] = {
    id = id,
    name = name,
    passed = passed == true,
    details = details or '',
  }
  log((passed and '^2PASS^7 ' or '^1FAIL^7 ') .. id .. ' - ' .. name .. ' :: ' .. (details or ''))
end

local function wait_bank_eval(source_id, citizen_id)
  local done = false
  local response = nil
  TriggerEvent('sonar:bank:dev:st022_eval', source_id, citizen_id, function(result)
    response = result
    done = true
  end)
  local deadline = GetGameTimer() + 30000
  while not done and GetGameTimer() < deadline do Wait(50) end
  return response
end

RegisterCommand('st022_esx_source1', function(src, args)
  if src ~= 0 then return end
  local source_id = tonumber(args[1]) or 1
  local results = {}

  log('Starting source evaluation for source=' .. tostring(source_id))

  if not Bridges.WaitReady(10000) then
    record(results, 'ST-022.1', 'Bridges ready', false, 'Bridges.WaitReady timeout')
  else
    local bank_active = Bridges.GetActive('bank')
    local identity_active = Bridges.GetActive('identity')
    record(results, 'ST-022.1', 'ESX adapters active', bank_active == 'esx' and identity_active == 'esx',
      'bank=' .. tostring(bank_active) .. ', identity=' .. tostring(identity_active))
  end

  local ESX = get_esx(3000)
  local player = wait_player_by_source(ESX, source_id, 10000)
  local raw_identifier = player and player.identifier or nil

  if not player or not raw_identifier then
    record(results, 'ST-022.3', 'Identity raw identifier available', false,
      'xPlayer not found for source=' .. tostring(source_id)
      .. ', esx=' .. tostring(type(ESX))
      .. ', has_GetPlayerFromId=' .. tostring(ESX and type(ESX.GetPlayerFromId) or nil))
  else
    local bridge_identifier = Bridges.Identity.GetCitizenId(source_id)
    record(results, 'ST-022.3', 'Identity raw identifier parity', bridge_identifier == raw_identifier,
      'source=' .. tostring(source_id) .. ', bridge=' .. tostring(bridge_identifier) .. ', raw=' .. tostring(raw_identifier) .. ', len=' .. tostring(#raw_identifier))
  end

  if player and raw_identifier then
    player = get_player_by_source(ESX, source_id)
    local before_bridge, before_err = Bridges.Bank.GetBalance(raw_identifier, 'bank')
    local before_raw = raw_bank_balance(player)
    local add_ok, add_err = Bridges.Bank.AddMoney(raw_identifier, 10.0, 'st022_esx_add', 'st022-add-' .. uuid())
    Wait(250)
    player = get_player_by_source(ESX, source_id)
    local after_add_bridge = Bridges.Bank.GetBalance(raw_identifier, 'bank')
    local after_add_raw = raw_bank_balance(player)
    local remove_ok, remove_err = Bridges.Bank.RemoveMoney(raw_identifier, 10.0, 'st022_esx_remove', 'st022-remove-' .. uuid())
    Wait(250)
    player = get_player_by_source(ESX, source_id)
    local after_remove_bridge = Bridges.Bank.GetBalance(raw_identifier, 'bank')
    local after_remove_raw = raw_bank_balance(player)

    local passed = add_ok == true
      and remove_ok == true
      and tonumber(before_bridge) ~= nil
      and tonumber(before_raw) ~= nil
      and tonumber(after_add_bridge) == tonumber(before_bridge) + 10.0
      and tonumber(after_add_raw) == tonumber(before_raw) + 10.0
      and tonumber(after_remove_bridge) == tonumber(before_bridge)
      and tonumber(after_remove_raw) == tonumber(before_raw)

    record(results, 'ST-022.2', 'Bank AddMoney/RemoveMoney/GetBalance ESX memory parity', passed,
      'before_bridge=' .. tostring(before_bridge)
      .. ', before_raw=' .. tostring(before_raw)
      .. ', before_err=' .. tostring(before_err)
      .. ', accounts=' .. account_names(player)
      .. ', add_ok=' .. tostring(add_ok)
      .. ', add_err=' .. tostring(add_err)
      .. ', after_add_bridge=' .. tostring(after_add_bridge)
      .. ', after_add_raw=' .. tostring(after_add_raw)
      .. ', remove_ok=' .. tostring(remove_ok)
      .. ', remove_err=' .. tostring(remove_err)
      .. ', after_remove_bridge=' .. tostring(after_remove_bridge)
      .. ', after_remove_raw=' .. tostring(after_remove_raw))
  end

  if raw_identifier then
    local bank_eval = wait_bank_eval(source_id, raw_identifier)
    if type(bank_eval) ~= 'table' then
      record(results, 'ST-022.4', 'NUI transfer payload', false, 'sonar_bank eval timeout/no response')
      record(results, 'ST-022.5', 'Lag reconciliation invariants', false, 'sonar_bank eval timeout/no response')
      record(results, 'ST-022.7', 'Latency baseline documentation', false, 'sonar_bank eval timeout/no response')
    else
      for _, item in ipairs(bank_eval.results or {}) do
        record(results, item.id, item.name, item.passed, item.details)
      end
    end
  end

  local passed = 0
  for _, item in ipairs(results) do
    if item.passed then passed = passed + 1 end
  end
  log('SUMMARY Total=' .. tostring(#results) .. ' Passed=' .. tostring(passed) .. ' Failed=' .. tostring(#results - passed))
end, true)

log('Dev command registered: st022_esx_source1 [source]')
