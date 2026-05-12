BankApp.api = BankApp.api or {}
BankApp.api.smoke_exports = {}

local EXPECTED_EXPORTS = {
  'AddMoney', 'RemoveMoney', 'CanAfford', 'GetBalance', 'TransferBySource', 'TransferByIban',
  'AddMoneyByCitizen', 'RemoveMoneyByCitizen', 'CanAffordByCitizen', 'GetBalanceByCitizen', 'TransferByCitizen',
  'AdminCredit', 'AdminDebit', 'AdminSetBalance', 'Freeze', 'Unfreeze',
  'AdminCreditByCitizen', 'AdminDebitByCitizen', 'AdminSetBalanceByCitizen', 'FreezeByCitizen', 'UnfreezeByCitizen',
  'GetApiVersion',
}

function BankApp.api.smoke_exports.RunStatic()
  local failures = {}
  if not BankApp.api.public then failures[#failures + 1] = 'public_api_missing' end
  if not BankApp.api.admin then failures[#failures + 1] = 'admin_api_missing' end
  if not BankApp.api.wrappers or type(BankApp.api.wrappers.publish_balance_update) ~= 'function' then failures[#failures + 1] = 'publish_wrapper_missing' end
  for _, name in ipairs(EXPECTED_EXPORTS) do
    local public_fn = BankApp.api.public and BankApp.api.public[name]
    local admin_fn = BankApp.api.admin and BankApp.api.admin[name]
    if name ~= 'GetApiVersion' and type(public_fn) ~= 'function' and type(admin_fn) ~= 'function' then
      failures[#failures + 1] = 'missing_' .. name
    end
  end
  return #failures == 0, failures
end

RegisterCommand('sonar_bank_exports_smoke', function(source)
  if source ~= 0 then return end
  local ok, failures = BankApp.api.smoke_exports.RunStatic()
  print(('[sonar_bank_app][exports-smoke] ok=%s failures=%s'):format(tostring(ok), table.concat(failures, ',')))
end, true)
