local Wrap  = BankApp.callbacks._wrap
local Enums = BankApp.lib.enums

local GovtService = BankApp.services.govt
local Config = BankApp.Config

local GOVT_READ_ACE = Config.Permissions.GOVT_READ_ACE
local GOVT_COMPLIANCE_ACE = Config.Permissions.GOVT_COMPLIANCE_ACE

Wrap.Register('sonar:bank:govt:census:list', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-006',
}, function(src, citizen_id, payload)
  return GovtService.ListCensus({
    src = src,
    actor_citizen_id = citizen_id,
    filters = payload.filters or payload,
  })
end)

Wrap.Register('sonar:bank:govt:census:detail', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-007',
}, function(src, citizen_id, payload)
  return GovtService.GetCitizenDetail({
    src = src,
    actor_citizen_id = citizen_id,
    cid = payload.cid or payload.targetCid,
  })
end)

Wrap.Register('sonar:bank:govt:sanctions:queue', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-009Q',
}, function(src, citizen_id, payload)
  return GovtService.ListFlagQueue({
    src = src,
    actor_citizen_id = citizen_id,
    filters = payload.filters or payload,
  })
end)

Wrap.Register('sonar:bank:govt:sanctions:flagDetail', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-009D',
}, function(src, citizen_id, payload)
  return GovtService.GetFlagDetail({
    src = src,
    actor_citizen_id = citizen_id,
    flag_id = payload.flagId or payload.flag_id,
  })
end)

Wrap.Register('sonar:bank:govt:sanctions:frozen', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-009F',
}, function(src, citizen_id, payload)
  return GovtService.IsCitizenFrozen({
    src = src,
    actor_citizen_id = citizen_id,
    target_cid = payload.cid or payload.targetCid,
  })
end)

Wrap.Register('sonar:bank:govt:sanctions:actions', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-009A',
}, function(src, citizen_id, payload)
  return GovtService.ListSanctionActions({
    src = src,
    actor_citizen_id = citizen_id,
    target_cid = payload.targetCid or payload.target_cid,
  })
end)

Wrap.Register('sonar:bank:govt:sanctions:kpis', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-009K',
}, function(src, citizen_id, payload)
  return GovtService.GetSanctionKpis({
    src = src,
    actor_citizen_id = citizen_id,
  })
end)

Wrap.Register('sonar:bank:govt:sanctions:closeFlag', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_COMPLIANCE_ACE,
  cb_id         = 'REQ-FE-009C',
}, function(src, citizen_id, payload)
  return GovtService.CloseFlag({
    src = src,
    actor_citizen_id = citizen_id,
    flag_id = payload.flagId or payload.flag_id,
    verdict = payload.verdict,
    reason = payload.reason,
    idempotency_key = payload.idempotencyKey or payload.idempotency_key,
  })
end)

Wrap.Register('sonar:bank:govt:sanctions:freezeAccounts', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_COMPLIANCE_ACE,
  cb_id         = 'REQ-FE-009FR',
}, function(src, citizen_id, payload)
  return GovtService.FreezeAccounts({
    src = src,
    actor_citizen_id = citizen_id,
    target_cid = payload.targetCid or payload.target_cid,
    related_flag_id = payload.relatedFlagId or payload.related_flag_id,
    reason = payload.reason,
    idempotency_key = payload.idempotencyKey or payload.idempotency_key,
  })
end)

Wrap.Register('sonar:bank:govt:sanctions:liftFreeze', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_COMPLIANCE_ACE,
  cb_id         = 'REQ-FE-009LF',
}, function(src, citizen_id, payload)
  return GovtService.LiftFreeze({
    src = src,
    actor_citizen_id = citizen_id,
    target_cid = payload.targetCid or payload.target_cid,
    related_flag_id = payload.relatedFlagId or payload.related_flag_id,
    reason = payload.reason,
    idempotency_key = payload.idempotencyKey or payload.idempotency_key,
  })
end)

Wrap.Register('sonar:bank:govt:sanctions:applyFine', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_COMPLIANCE_ACE,
  cb_id         = 'REQ-FE-009AF',
}, function(src, citizen_id, payload)
  return GovtService.ApplyFine({
    src = src,
    actor_citizen_id = citizen_id,
    target_cid = payload.targetCid or payload.target_cid,
    related_flag_id = payload.relatedFlagId or payload.related_flag_id,
    amount = payload.amount,
    reason = payload.reason,
    idempotency_key = payload.idempotencyKey or payload.idempotency_key,
  })
end)

Wrap.Register('sonar:bank:govt:treasury:page', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-012',
}, function(src, citizen_id, payload)
  return GovtService.GetTreasuryPage({
    src = src,
    actor_citizen_id = citizen_id,
    filters = payload.filters or {},
    page = payload.page,
    per_page = payload.perPage or payload.per_page,
  })
end)

Wrap.Register('sonar:bank:govt:subsidies:stats', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-013S',
}, function(src, citizen_id, payload)
  return GovtService.GetSubsidyStats({ src = src, actor_citizen_id = citizen_id })
end)

Wrap.Register('sonar:bank:govt:subsidies:list', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-013L',
}, function(src, citizen_id, payload)
  return GovtService.ListSubsidyPrograms({
    src = src,
    actor_citizen_id = citizen_id,
    filters = payload.filters or payload,
  })
end)

Wrap.Register('sonar:bank:govt:subsidies:detail', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-013D',
}, function(src, citizen_id, payload)
  return GovtService.GetSubsidyDetail({
    src = src,
    actor_citizen_id = citizen_id,
    program_id = payload.programId or payload.program_id,
  })
end)

Wrap.Register('sonar:bank:govt:reports:data', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  admin_ace     = GOVT_READ_ACE,
  cb_id         = 'REQ-FE-014',
}, function(src, citizen_id, payload)
  return GovtService.GetReports({
    src = src,
    actor_citizen_id = citizen_id,
    range = payload.range,
  })
end)
