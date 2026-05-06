-- =============================================================================
-- SONAR Bank App — callbacks/admin.lua
-- =============================================================================
-- Tier 3 admin/govt + ATM (signed). All require_admin = true except ATM
-- (which has its own HMAC verification path).
--
-- Callbacks (10):
--   C035  sonar:bank:audit:query             (M003 dual rate-limit recursive guard)
--   C036  sonar:bank:govt:freeze             (admin)
--   C036b sonar:bank:govt:unfreeze           (admin)
--   C031  sonar:bank:atm:withdraw            (signed payload — own auth path via HMAC)
--   C041  sonar:bank:admin:adjustBalance     (admin)
--   C042  sonar:bank:admin:govtAudit         (admin)
--   C043  sonar:bank:admin:openFraudReview   (admin)
--   C044  sonar:bank:admin:resolveFraudReview(admin)
--   C045  sonar:bank:admin:watchdogReport    (admin)
--   C046  sonar:bank:admin:reconcile         (admin)
-- =============================================================================

local Wrap   = BankApp.callbacks._wrap
local Enums  = BankApp.lib.enums

local AdminService = BankApp.services.admin

-- -----------------------------------------------------------------------------
-- C035 — audit:query (M003 dual rate-limit + recursive guard)
--   NOTE: skip_rate_limit=true because AdminService.QueryAuditLedger does its
--         own M003-specific dual rate-limit (CheckAuditQuery). The generic
--         per-tier bucket would double-count.
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:audit:query', {
  tier            = Enums.TIER.TIER_3_ADMIN,
  require_admin   = true,
  skip_rate_limit = true,
  cb_id           = 'C035',
}, function(src, citizen_id, payload)
  return AdminService.QueryAuditLedger({
    actor_citizen_id   = citizen_id,
    src                = src,
    scope              = payload.scope,
    target_citizen_id  = payload.target_citizen_id,
    event_type         = payload.event_type,
    since_ms           = payload.since_ms,
    limit              = payload.limit,
    offset             = payload.offset,
  })
end)

-- -----------------------------------------------------------------------------
-- C036 — govt:freeze
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:govt:freeze', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C036',
}, function(src, citizen_id, payload)
  return AdminService.FreezeByGovt({
    src               = src,
    actor_citizen_id  = citizen_id,
    iban              = payload.iban,
    reason            = payload.reason,
    authority         = payload.authority,
    correlation_id    = payload.correlation_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C036b — govt:unfreeze
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:govt:unfreeze', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C036b',
}, function(src, citizen_id, payload)
  return AdminService.UnfreezeByGovt({
    src               = src,
    actor_citizen_id  = citizen_id,
    iban              = payload.iban,
    reason            = payload.reason,
    authority         = payload.authority,
    correlation_id    = payload.correlation_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C031 — atm:withdraw (HMAC-signed, NOT admin)
--   Auth model: ATM hardware signs payload with shared secret. The CALLER
--   (player) is the account owner — RequireCitizen suffices. The HMAC verify
--   inside AtmWithdraw confirms request originates from a legit ATM terminal.
--   We DO want per-player rate-limit (Tier 2) — so skip_rate_limit=false.
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:atm:withdraw', {
  tier  = Enums.TIER.TIER_2_WRITE,
  cb_id = 'C031',
}, function(src, citizen_id, payload)
  return AdminService.AtmWithdraw({
    src              = src,
    actor_citizen_id = citizen_id,
    iban             = payload.iban,
    amount_minor     = payload.amount_minor,
    nonce            = payload.nonce,
    ts_ms            = payload.ts_ms,
    signature_hex    = payload.signature_hex,
    atm_id           = payload.atm_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C041 — admin:adjustBalance
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:admin:adjustBalance', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C041',
}, function(src, citizen_id, payload)
  return AdminService.AdjustBalance({
    src               = src,
    actor_citizen_id  = citizen_id,
    iban              = payload.iban,
    delta_minor       = payload.delta_minor,
    reason            = payload.reason,
    correlation_id    = payload.correlation_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C042 — admin:govtAudit
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:admin:govtAudit', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C042',
}, function(src, citizen_id, payload)
  return AdminService.GovtAudit({
    src               = src,
    actor_citizen_id  = citizen_id,
    target_citizen_id = payload.target_citizen_id,
    reason            = payload.reason,
    correlation_id    = payload.correlation_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C043 — admin:openFraudReview
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:admin:openFraudReview', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C043',
}, function(src, citizen_id, payload)
  return AdminService.OpenFraudReview({
    src               = src,
    actor_citizen_id  = citizen_id,
    target_citizen_id = payload.target_citizen_id,
    txn_id            = payload.txn_id,
    reason            = payload.reason,
    correlation_id    = payload.correlation_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C044 — admin:resolveFraudReview
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:admin:resolveFraudReview', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C044',
}, function(src, citizen_id, payload)
  return AdminService.ResolveFraudReview({
    src               = src,
    actor_citizen_id  = citizen_id,
    target_citizen_id = payload.target_citizen_id,
    original_audit_id = payload.original_audit_id,
    resolution        = payload.resolution,
    reason            = payload.reason,
    correlation_id    = payload.correlation_id,
  })
end)

-- -----------------------------------------------------------------------------
-- C045 — admin:watchdogReport (M007 metric C health snapshot)
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:admin:watchdogReport', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C045',
}, function(src, citizen_id, payload)
  return AdminService.WatchdogReport()
end)

-- -----------------------------------------------------------------------------
-- C046 — admin:reconcile
-- -----------------------------------------------------------------------------

Wrap.Register('sonar:bank:admin:reconcile', {
  tier          = Enums.TIER.TIER_3_ADMIN,
  require_admin = true,
  cb_id         = 'C046',
}, function(src, citizen_id, payload)
  return AdminService.ReconcilePipeline({
    actor_citizen_id = citizen_id,
    mode             = payload.mode,
    dry_run          = payload.dry_run,
  })
end)
