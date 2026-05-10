local Wrap  = BankApp.callbacks._wrap
local Enums = BankApp.lib.enums

local BusinessService = BankApp.services.business
local Config = BankApp.Config

local GOVT_READ_ACE = Config.Permissions.GOVT_READ_ACE

Wrap.Register('sonar:bank:govt:business:list', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-011L',
}, function(src, citizen_id, payload)
  return BusinessService.ListGovtBusinesses({
    src = src,
    actor_citizen_id = citizen_id,
    filters = payload.filters or payload,
  })
end)

Wrap.Register('sonar:bank:govt:business:detail', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-011D',
}, function(src, citizen_id, payload)
  return BusinessService.GetGovtBusinessDetail({
    src = src,
    actor_citizen_id = citizen_id,
    company_id = payload.companyId or payload.company_id,
  })
end)

Wrap.Register('sonar:bank:business:treasury', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'REQ-FE-015T',
}, function(src, citizen_id, payload)
  return BusinessService.GetTreasurySnapshot({
    src = src,
    actor_citizen_id = citizen_id,
    company_id = payload.company_id,
  })
end)

Wrap.Register('sonar:bank:business:payroll:preview', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'REQ-FE-015P',
}, function(src, citizen_id, payload)
  return BusinessService.GetPayrollPreview({
    src = src,
    actor_citizen_id = citizen_id,
    company_id = payload.company_id,
  })
end)

Wrap.Register('sonar:bank:business:payroll:execute', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'REQ-FE-015E',
}, function(src, citizen_id, payload)
  return BusinessService.RequestPayrollExecution({
    src = src,
    actor_citizen_id = citizen_id,
    company_id = payload.company_id,
    idempotency_key = payload.idempotency_key,
    correlation_id = payload.correlation_id,
  })
end)

Wrap.Register('sonar:bank:business:approval:decide', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'REQ-FE-015A',
}, function(src, citizen_id, payload)
  return BusinessService.DecideApproval({
    src = src,
    actor_citizen_id = citizen_id,
    approval_id = payload.approval_id,
    decision = payload.decision,
    note = payload.note,
    idempotency_key = payload.idempotency_key,
    correlation_id = payload.correlation_id,
  })
end)
