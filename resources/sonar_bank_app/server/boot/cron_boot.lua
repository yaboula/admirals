-- =============================================================================
-- SONAR Bank App — boot/cron_boot.lua
-- =============================================================================
-- Bootstraps all periodic background tasks. Each cron has its own enabled
-- flag in C.Cron; this file just kicks heartbeats once the resource is up.
-- =============================================================================

AddEventHandler('onResourceStart', function(resourceName)
  if resourceName ~= GetCurrentResourceName() then return end

  -- Savings interest accrual heartbeat
  if BankApp.services.cron and BankApp.services.cron.savings_interest then
    local _, err = pcall(BankApp.services.cron.savings_interest.StartHeartbeat)
    if err then
      local prefix = (BankApp.Config.Logging and BankApp.Config.Logging.PREFIX) or '[sonar_bank_app]'
      print(prefix .. ' [cron_boot] savings_interest heartbeat failed: ' .. tostring(err))
    end
  end
end)

-- =============================================================================
-- Admin command: force a run (debug / one-off accrual)
-- =============================================================================
RegisterCommand('sonarbank_savings_interest_now', function(src, _args)
  -- ACE: console always allowed; players need sonar.bank.admin
  if src ~= 0 and not IsPlayerAceAllowed(src, 'sonar.bank.admin') then
    return
  end
  local prefix = (BankApp.Config.Logging and BankApp.Config.Logging.PREFIX) or '[sonar_bank_app]'
  if not (BankApp.services.cron and BankApp.services.cron.savings_interest) then
    print(prefix .. ' [savings_interest] service not loaded')
    return
  end
  local result = BankApp.services.cron.savings_interest.RunOnce({ force = true })
  if result.ok then
    print(prefix .. ' [savings_interest] manual run OK ' .. json.encode(result.data or {}))
  else
    print(prefix .. ' [savings_interest] manual run ERR ' .. json.encode(result.error or {}))
  end
end, true)
