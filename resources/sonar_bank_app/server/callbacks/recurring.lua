-- =============================================================================
-- SONAR Bank App — callbacks/recurring.lua
-- =============================================================================
-- Recurring debits (subscriptions / scheduled payments).
--
-- Callbacks (5):
--   C013  sonar:bank:recurring:list
--   C014  sonar:bank:recurring:subscribe
--   C017  sonar:bank:recurring:cancel
--   C018a sonar:bank:recurring:pause
--   C018b sonar:bank:recurring:resume
-- =============================================================================

local Wrap   = BankApp.callbacks._wrap
local Enums  = BankApp.lib.enums

local RecurringService = BankApp.services.recurring

-- -----------------------------------------------------------------------------
-- C013 — list
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:recurring:list', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'C013',
}, function(src, citizen_id, payload)
  local rows, err = RecurringService.ListSelf(citizen_id)
  if err then return { ok = false, error = err } end
  return { recurring = rows or {} }
end)

-- -----------------------------------------------------------------------------
-- C014 — subscribe
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:recurring:subscribe', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C014',
}, function(src, citizen_id, payload)
  return RecurringService.Subscribe({
    src             = src,
    citizen_id      = citizen_id,
    from_iban       = payload.from_iban,
    to_iban         = payload.to_iban,
    amount_minor    = payload.amount_minor,
    reason          = payload.reason,
    interval_days   = payload.interval_days,
    first_charge_ms = payload.first_charge_ms,
  })
end)

-- -----------------------------------------------------------------------------
-- C017 — cancel
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:recurring:cancel', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C017',
}, function(src, citizen_id, payload)
  return RecurringService.Cancel({
    src          = src,
    recurring_id = payload.recurring_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C018a — pause
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:recurring:pause', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C018a',
}, function(src, citizen_id, payload)
  return RecurringService.Pause({
    src          = src,
    recurring_id = payload.recurring_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C018b — resume
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:recurring:resume', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C018b',
}, function(src, citizen_id, payload)
  return RecurringService.Resume({
    src          = src,
    recurring_id = payload.recurring_id,
  })
end)
