local Wrap  = BankApp.callbacks._wrap
local Enums = BankApp.lib.enums

local TaxService = BankApp.services.tax
local Config = BankApp.Config

local GOVT_READ_ACE = Config.Permissions.GOVT_READ_ACE
local GOVT_COMPLIANCE_ACE = Config.Permissions.GOVT_COMPLIANCE_ACE

Wrap.Register('sonar:bank:govt:tax:brackets:get', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-008B',
}, function(src, citizen_id, payload)
  return TaxService.GetBrackets({
    src = src,
    actor_citizen_id = citizen_id,
  })
end)

Wrap.Register('sonar:bank:govt:tax:cycle:stats', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-008C',
}, function(src, citizen_id, payload)
  return TaxService.GetCycleStats({
    src = src,
    actor_citizen_id = citizen_id,
  })
end)

Wrap.Register('sonar:bank:govt:tax:policy:log', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-008L',
}, function(src, citizen_id, payload)
  return TaxService.GetPolicyLog({
    src = src,
    actor_citizen_id = citizen_id,
  })
end)

Wrap.Register('sonar:bank:govt:tax:brackets:save', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_COMPLIANCE_ACE,
  cb_id         = 'REQ-FE-008S',
}, function(src, citizen_id, payload)
  return TaxService.SaveBrackets({
    src = src,
    actor_citizen_id = citizen_id,
    brackets = payload.brackets,
    reason = payload.reason,
    idempotency_key = payload.idempotencyKey or payload.idempotency_key,
  })
end)

Wrap.Register('sonar:bank:govt:tax:force_collection', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_COMPLIANCE_ACE,
  cb_id         = 'REQ-FE-008F',
}, function(src, citizen_id, payload)
  return TaxService.ForceCollection({
    src = src,
    actor_citizen_id = citizen_id,
    reason = payload.reason,
    idempotency_key = payload.idempotencyKey or payload.idempotency_key,
  })
end)

return true
