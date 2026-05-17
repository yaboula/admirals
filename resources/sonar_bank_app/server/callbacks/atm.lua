-- =============================================================================
-- SONAR Bank App — server/callbacks/atm.lua
-- =============================================================================
-- F06 — In-game NUI ATM endpoints.
--
--   C_ATM_SESSION       sonar:bank:atm:session       (Tier 1 read)
--   C_ATM_VERIFY_PIN    sonar:bank:atm:verifyPin     (Tier 2 write)
--   C_ATM_NUI_WITHDRAW  sonar:bank:atm:nuiWithdraw   (Tier 2 write)
--
--   The legacy `sonar:bank:atm:withdraw` (C031, HMAC-signed) remains in
--   `callbacks/admin.lua` for the OUT-OF-BAND atm hardware contract.
-- =============================================================================

local Wrap   = BankApp.callbacks._wrap
local Enums  = BankApp.lib.enums
local AtmSvc = BankApp.services.atm

-- -----------------------------------------------------------------------------
-- C_ATM_SESSION — read terminal info + balance pre-fill
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:atm:session', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'C_ATM_SESSION',
}, function(src, citizen_id, payload)
  return AtmSvc.Session({
    src              = src,
    actor_citizen_id = citizen_id,
    terminal         = payload and payload.terminal,
    terminal_id      = payload and payload.terminal_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C_ATM_VERIFY_PIN — per-card PIN check, grants 5-min token on success
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:atm:verifyPin', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C_ATM_VERIFY_PIN',
}, function(src, citizen_id, payload)
  return AtmSvc.VerifyPin({
    src              = src,
    actor_citizen_id = citizen_id,
    card_id          = payload and payload.card_id,
    pin              = payload and payload.pin,
    terminal         = payload and payload.terminal,
    terminal_id      = payload and payload.terminal_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C_ATM_NUI_WITHDRAW — debit balance using a valid grant
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:atm:nuiWithdraw', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C_ATM_NUI_WITHDRAW',
}, function(src, citizen_id, payload)
  return AtmSvc.NuiWithdraw({
    src              = src,
    actor_citizen_id = citizen_id,
    card_id          = payload and payload.card_id,
    grant_id         = payload and payload.grant_id,
    amount_minor     = payload and payload.amount_minor,
    terminal         = payload and payload.terminal,
    terminal_id      = payload and payload.terminal_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C_ATM_NUI_DEPOSIT — credit balance using physical cash + a valid grant
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:atm:nuiDeposit', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C_ATM_NUI_DEPOSIT',
}, function(src, citizen_id, payload)
  return AtmSvc.NuiDeposit({
    src              = src,
    actor_citizen_id = citizen_id,
    card_id          = payload and payload.card_id,
    grant_id         = payload and payload.grant_id,
    amount_minor     = payload and payload.amount_minor,
    terminal         = payload and payload.terminal,
    terminal_id      = payload and payload.terminal_id,
  })
end)
