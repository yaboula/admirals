-- =============================================================================
-- SONAR Bank App — callbacks/transfer.lua
-- =============================================================================
-- Money-movement callbacks (P2P + savings + recent history).
--
-- Callbacks (4):
--   C005 sonar:bank:transfer:listRecent
--   C006 sonar:bank:transfer:execute      — P2P (idempotent)
--   C007 sonar:bank:transfer:toSavings    — own balance → savings
--   C008 sonar:bank:transfer:fromSavings  — own savings → balance
-- =============================================================================

local Wrap   = BankApp.callbacks._wrap
local Enums  = BankApp.lib.enums
local Errors = BankApp.lib.errors

local TransferService  = BankApp.services.transfer
local TransactionsRepo = BankApp.repos.transactions

-- -----------------------------------------------------------------------------
-- C005 — listRecent
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:transfer:listRecent', {
  tier  = Enums.TIER.TIER_1_READ,
  cb_id = 'C005',
}, function(src, citizen_id, payload)
  local limit = payload.limit
  if type(limit) ~= 'number' or limit < 1 or limit > 200 then limit = 50 end
  local rows, err = TransactionsRepo.ListByCitizen(citizen_id, limit)
  if err then return { ok = false, error = err } end
  return { transactions = rows or {} }
end)

-- -----------------------------------------------------------------------------
-- C006 — execute (P2P transfer, idempotent)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:transfer:execute', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C006',
}, function(src, citizen_id, payload)
  return TransferService.Execute({
    src              = src,
    citizen_id       = citizen_id,
    from_iban        = payload.from_iban,
    to_iban          = payload.to_iban,
    amount_minor     = payload.amount_minor,
    reason           = payload.reason,
    idempotency_key  = payload.idempotency_key,
    correlation_id   = payload.correlation_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C007 — toSavings
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:transfer:toSavings', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C007',
}, function(src, citizen_id, payload)
  return TransferService.ExecuteToSavings({
    src              = src,
    citizen_id       = citizen_id,
    from_iban        = payload.iban,
    amount_minor     = payload.amount_minor,
    idempotency_key  = payload.idempotency_key,
  })
end)

-- -----------------------------------------------------------------------------
-- C008 — fromSavings
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:transfer:fromSavings', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C008',
}, function(src, citizen_id, payload)
  return TransferService.ExecuteFromSavings({
    src              = src,
    citizen_id       = citizen_id,
    from_iban        = payload.iban,
    amount_minor     = payload.amount_minor,
    idempotency_key  = payload.idempotency_key,
  })
end)
