-- =============================================================================
-- SONAR Bank App — callbacks/account.lua
-- =============================================================================
-- Account FSM #1 callbacks + KYC.
--
-- Callbacks (10):
--   C002  sonar:bank:account:open
--   C003  sonar:bank:account:listSelf
--   C015  sonar:bank:account:freeze            (owner self-freeze)
--   C016  sonar:bank:account:unfreeze          (owner self-unfreeze)
--   C019  sonar:bank:account:close
--   C020  sonar:bank:account:addJoint
--   C021  sonar:bank:account:removeJoint
--   C037  sonar:bank:kyc:submit
--   C038  sonar:bank:kyc:approve               (admin)
--   C039  sonar:bank:kyc:reject                (admin)
-- =============================================================================

local Wrap   = BankApp.callbacks._wrap
local Enums  = BankApp.lib.enums

local AccountService = BankApp.services.account

-- -----------------------------------------------------------------------------
-- C002 — open
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:account:open', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C002',
}, function(src, citizen_id, payload)
  return AccountService.OpenAccount({
    src              = src,
    citizen_id       = citizen_id,
    initial_balance  = payload.initial_balance,
    initial_savings  = payload.initial_savings,
  })
end)

-- -----------------------------------------------------------------------------
-- C003 — listSelf
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:account:listSelf', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'C003',
}, function(src, citizen_id, payload)
  local rows, err = AccountService.GetSelfAccounts(citizen_id)
  if err then return { ok = false, error = err } end
  return { accounts = rows or {} }
end)

-- -----------------------------------------------------------------------------
-- C015 — freeze (owner self)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:account:freeze', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C015',
}, function(src, citizen_id, payload)
  return AccountService.FreezeAccount({
    src               = src,
    actor_citizen_id  = citizen_id,
    iban              = payload.iban,
    reason            = payload.reason,
    correlation_id    = payload.correlation_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C016 — unfreeze (owner self)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:account:unfreeze', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C016',
}, function(src, citizen_id, payload)
  return AccountService.UnfreezeAccount({
    src               = src,
    actor_citizen_id  = citizen_id,
    iban              = payload.iban,
    reason            = payload.reason,
    correlation_id    = payload.correlation_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C019 — close
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:account:close', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C019',
}, function(src, citizen_id, payload)
  return AccountService.CloseAccount({
    src     = src,
    iban    = payload.iban,
    reason  = payload.reason,
  })
end)

-- -----------------------------------------------------------------------------
-- C020 — addJoint
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:account:addJoint', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C020',
}, function(src, citizen_id, payload)
  return AccountService.AddJointOwner({
    src              = src,
    iban             = payload.iban,
    joint_citizen_id = payload.joint_citizen_id,
    reason           = payload.reason,
  })
end)

-- -----------------------------------------------------------------------------
-- C021 — removeJoint
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:account:removeJoint', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C021',
}, function(src, citizen_id, payload)
  return AccountService.RemoveJointOwner({
    src              = src,
    iban             = payload.iban,
    joint_citizen_id = payload.joint_citizen_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C037 — KYC submit
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:kyc:submit', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C037',
}, function(src, citizen_id, payload)
  return AccountService.SubmitKyc({
    src        = src,
    citizen_id = citizen_id,
    doc_count  = payload.doc_count,
  })
end)

-- -----------------------------------------------------------------------------
-- C038 — KYC approve (ADMIN)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:kyc:approve', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C038',
}, function(src, citizen_id, payload)
  return AccountService.ApproveKyc({
    src               = src,
    actor_citizen_id  = citizen_id,
    target_citizen_id = payload.target_citizen_id,
    reason            = payload.reason,
  })
end)

-- -----------------------------------------------------------------------------
-- C039 — KYC reject (ADMIN)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:kyc:reject', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C039',
}, function(src, citizen_id, payload)
  return AccountService.RejectKyc({
    src               = src,
    actor_citizen_id  = citizen_id,
    target_citizen_id = payload.target_citizen_id,
    reason            = payload.reason,
  })
end)
