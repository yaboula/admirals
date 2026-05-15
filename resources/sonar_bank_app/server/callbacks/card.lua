-- =============================================================================
-- SONAR Bank App — callbacks/card.lua
-- =============================================================================
-- Virtual cards (PIN HMAC-salted).
--
-- Callbacks (6):
--   C030 sonar:bank:card:list
--   C032 sonar:bank:card:issue
--   C033 sonar:bank:card:freeze
--   C034 sonar:bank:card:unfreeze
--   C035 sonar:bank:card:setLimits
--   C036 sonar:bank:card:applyDesign
--   C040 sonar:bank:card:changePin
-- =============================================================================

local Wrap   = BankApp.callbacks._wrap
local Enums  = BankApp.lib.enums

local CardService = BankApp.services.card

-- -----------------------------------------------------------------------------
-- C030 — list
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:card:list', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'C030',
}, function(src, citizen_id, payload)
  local rows, err = CardService.ListSelf(citizen_id)
  if err then return { ok = false, error = err } end
  return { cards = rows or {} }
end)

-- -----------------------------------------------------------------------------
-- C032 — issue
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:card:issue', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C032',
}, function(src, citizen_id, payload)
  return CardService.Issue({
    src                = src,
    citizen_id         = citizen_id,
    account_iban       = payload.account_iban,
    pin                = payload.pin,
    card_type          = payload.card_type,
    design_id          = payload.design_id,
    spend_limit_minor  = payload.spend_limit_minor,
  })
end)

-- -----------------------------------------------------------------------------
-- C033 — freeze
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:card:freeze', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C033',
}, function(src, citizen_id, payload)
  return CardService.Freeze({
    src     = src,
    card_id = payload.card_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C034 — unfreeze
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:card:unfreeze', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C034',
}, function(src, citizen_id, payload)
  return CardService.Unfreeze({
    src     = src,
    card_id = payload.card_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C035 — setLimits
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:card:setLimits', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C035',
}, function(src, citizen_id, payload)
  return CardService.SetLimits({
    src                  = src,
    citizen_id           = citizen_id,
    card_id              = payload.card_id,
    daily_limit_minor    = payload.daily_limit_minor,
    monthly_limit_minor  = payload.monthly_limit_minor,
  })
end)

-- -----------------------------------------------------------------------------
-- C036 — applyDesign
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:card:applyDesign', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C036',
}, function(src, citizen_id, payload)
  return CardService.ApplyDesign({
    src        = src,
    citizen_id = citizen_id,
    card_id    = payload.card_id,
    design_id  = payload.design_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C040 — changePin
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:card:changePin', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C040',
}, function(src, citizen_id, payload)
  return CardService.ChangePin({
    src      = src,
    card_id  = payload.card_id,
    old_pin  = payload.old_pin,
    new_pin  = payload.new_pin,
  })
end)
