Bridges = Bridges or {}

local Logger = Bridges.Logger

Bridges.Watchdog = Bridges.Watchdog or {}

local running = false
local active_bank = nil

local function check(reason)
  if not Bridges.CoreOverride or type(Bridges.CoreOverride.GetHealth) ~= 'function' then return false end
  local health = Bridges.CoreOverride.GetHealth()
  local bank = health.active_bank or active_bank or 'native'
  local ok = true
  if bank == 'qbcore' then ok = health.qbcore_registered == true end
  if bank == 'qbox' then ok = health.qbox_registered == true end
  if bank == 'esx' then ok = health.esx_registered == true end
  if not ok and Logger and Logger.Error then
    Logger.Error('Money authority watchdog failed framework=%s reason=%s', tostring(bank), tostring(reason))
  elseif Logger and Logger.Debug then
    Logger.Debug('Money authority watchdog ok framework=%s reason=%s', tostring(bank), tostring(reason))
  end
  return ok
end

function Bridges.Watchdog.Check(reason)
  return check(reason or 'manual')
end

function Bridges.Watchdog.Start(bank)
  if running then return true end
  running = true
  active_bank = bank
  Citizen.SetTimeout(5000, function() check('boot_t5s') end)
  Citizen.SetTimeout(30000, function() check('boot_t30s') end)
  Citizen.SetTimeout(300000, function() check('boot_t5m') end)
  CreateThread(function()
    while running do
      Wait(300000)
      check('periodic')
    end
  end)
  AddEventHandler('playerJoining', function()
    local joining_src = source
    Citizen.SetTimeout(10000, function()
      if Bridges.CoreOverride and type(Bridges.CoreOverride.InstallForPlayer) == 'function' then
        Bridges.CoreOverride.InstallForPlayer(joining_src)
      end
      check('first_join')
    end)
  end)
  return true
end

exports('WatchdogCheck', function(reason)
  return Bridges.Watchdog.Check(reason)
end)
