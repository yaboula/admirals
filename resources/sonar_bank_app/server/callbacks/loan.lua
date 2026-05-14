-- =============================================================================
-- SONAR Bank App — callbacks/loan.lua
-- =============================================================================
-- Loans FSM #3 callbacks.
--
-- Callbacks (5):
--   C022 sonar:bank:loan:request
--   C023 sonar:bank:loan:listSelf
--   C024 sonar:bank:loan:makePayment
--   C025 sonar:bank:loan:approve   (admin)
--   C026 sonar:bank:loan:reject    (admin)
-- =============================================================================

local Wrap   = BankApp.callbacks._wrap
local Enums  = BankApp.lib.enums

local LoanService = BankApp.services.loan

-- -----------------------------------------------------------------------------
-- C022 — request
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:loan:request', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C022',
}, function(src, citizen_id, payload)
  return LoanService.Request({
    src             = src,
    citizen_id      = citizen_id,
    principal_minor = payload.principal_minor,
    interest_bps    = payload.interest_bps,
    term_days       = payload.term_days,
    idempotency_key = payload.idempotency_key,
  })
end)

-- -----------------------------------------------------------------------------
-- C023 — listSelf
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:loan:listSelf', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'C023',
}, function(src, citizen_id, payload)
  local rows, err = LoanService.ListSelf(citizen_id)
  if err then return { ok = false, error = err } end
  return { loans = rows or {} }
end)

Wrap.Register('sonar:bank:loans:list', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'REQ-FE-LOANS-LIST',
}, function(src, citizen_id, payload)
  return LoanService.ListSelfResponse(citizen_id)
end)

Wrap.Register('sonar:bank:loans:installments', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'REQ-FE-LOANS-INSTALLMENTS',
}, function(src, citizen_id, payload)
  return LoanService.GetInstallments({
    src = src,
    citizen_id = citizen_id,
    loan_id = payload.loan_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C024 — makePayment
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:loan:makePayment', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C024',
}, function(src, citizen_id, payload)
  return LoanService.MakePayment({
    src              = src,
    citizen_id       = citizen_id,
    loan_id          = payload.loan_id,
    from_iban        = payload.from_iban,
    amount_minor     = payload.amount_minor,
    idempotency_key  = payload.idempotency_key,
  })
end)

-- -----------------------------------------------------------------------------
-- C025 — approve (ADMIN)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:loan:approve', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C025',
}, function(src, citizen_id, payload)
  return LoanService.Approve({
    src               = src,
    actor_citizen_id  = citizen_id,
    loan_id           = payload.loan_id,
    deposit_iban      = payload.deposit_iban,
  })
end)

-- -----------------------------------------------------------------------------
-- C026 — reject (ADMIN)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:loan:reject', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C026',
}, function(src, citizen_id, payload)
  return LoanService.Reject({
    src               = src,
    actor_citizen_id  = citizen_id,
    loan_id           = payload.loan_id,
    reason            = payload.reason,
  })
end)
