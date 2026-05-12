BankApp.api = BankApp.api or {}
BankApp.api.wrappers = {}
local W = BankApp.api.wrappers

local Units = BankApp.lib.units
local Publish = BankApp.lib.publish

local function resolve_source(citizen_id)
  if BankApp.lib.auth and BankApp.lib.auth.ResolveCitizenSrc then
    return BankApp.lib.auth.ResolveCitizenSrc(citizen_id)
  end
  return nil
end

function W.publish_balance_update(citizen_id, balance_major_decimal, account_class, opts)
  opts = opts or {}
  if type(citizen_id) ~= 'string' or citizen_id == '' then return end
  local src = resolve_source(citizen_id)
  if not src then return end
  local minor = Units.to_minor(balance_major_decimal)
  if type(minor) ~= 'number' then return end
  Publish.PublishBalanceUpdate(src, citizen_id, minor, 0, {
    reason = opts.reason,
    correlation = opts.correlation_id,
  })
end

function W.publish_account_balance(account, new_balance_minor, opts)
  opts = opts or {}
  if type(account) ~= 'table' then return end
  local decimal = Units.from_minor(new_balance_minor)
  if type(decimal) ~= 'string' then return end
  W.publish_balance_update(account.citizen_id, decimal, opts.account_class or 'main', opts)
end

return W
