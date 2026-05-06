-- =============================================================================
-- SONAR Bank App — events/audit_emit.lua
-- =============================================================================
-- High-level domain audit emit helpers. Wraps lib/audit.lua Write() with
-- canonical event_type + standardized event_data shapes per C-SEC-01 §1.2.
--
-- This file does NOT bypass lib/audit.lua — it ENCODES the canonical patterns
-- so callers don't accidentally drop required fields (especially H006
-- previous_flag_snapshot).
--
-- Each helper returns audit_id (UUID v4) for cross_ref chaining.
-- =============================================================================

BankApp.events.audit_emit = {}
local M = BankApp.events.audit_emit

local Audit = BankApp.lib.audit
local Enums = BankApp.lib.enums

local function now_ms() return os.time() * 1000 end

-- -----------------------------------------------------------------------------
-- §1. Account lifecycle
-- -----------------------------------------------------------------------------

function M.AccountCreated(actor_src, owner_cid, account_id, iban, initial_balance, initial_savings)
  return Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.ACCOUNT_CREATE,
    actor_citizen_id = owner_cid,
    actor_src        = actor_src,
    target_account_id= account_id,
    target_iban      = iban,
    event_data       = {
      initial_balance = initial_balance,
      initial_savings = initial_savings,
    },
  })
end

function M.AccountClosed(actor_src, owner_cid, account_id, iban, reason)
  return Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.ACCOUNT_CLOSE,
    actor_citizen_id = owner_cid,
    actor_src        = actor_src,
    target_account_id= account_id,
    target_iban      = iban,
    event_data       = { reason = reason },
  })
end

-- -----------------------------------------------------------------------------
-- §2. Account freeze (H006 — flag snapshot mandatory)
-- -----------------------------------------------------------------------------

function M.AccountFrozen(actor_src, actor_cid, target_cid, iban, account_id, prev_snapshot, reason)
  return Audit.Write({
    event_type             = Enums.AUDIT_EVENT_TYPE.ACCOUNT_FREEZE,
    actor_citizen_id       = actor_cid,
    actor_src              = actor_src,
    target_citizen_id      = target_cid,
    target_iban            = iban,
    target_account_id      = account_id,
    previous_flag_snapshot = prev_snapshot,
    event_data             = { reason = reason },
  })
end

function M.AccountUnfrozen(actor_src, actor_cid, target_cid, iban, account_id, prev_snapshot, reason)
  return Audit.Write({
    event_type             = Enums.AUDIT_EVENT_TYPE.ACCOUNT_UNFREEZE,
    actor_citizen_id       = actor_cid,
    actor_src              = actor_src,
    target_citizen_id      = target_cid,
    target_iban            = iban,
    target_account_id      = account_id,
    previous_flag_snapshot = prev_snapshot,
    event_data             = { reason = reason },
  })
end

-- -----------------------------------------------------------------------------
-- §3. Transfers
-- -----------------------------------------------------------------------------

function M.TransferCommitted(actor_src, actor_cid, txn_id, from_iban, to_iban, amount_minor, reason, correlation)
  return Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.TRANSFER_COMMITTED,
    actor_citizen_id = actor_cid,
    actor_src        = actor_src,
    target_iban      = to_iban,
    event_data       = {
      txn_id       = txn_id,
      from_iban    = from_iban,
      to_iban      = to_iban,
      amount_minor = amount_minor,
      reason       = reason,
      committed_ms = now_ms(),
    },
    correlation_id   = correlation,
  })
end

function M.TransferFailed(actor_src, actor_cid, txn_id, from_iban, to_iban, amount_minor, fail_reason, correlation)
  return Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.TRANSFER_FAILED,
    actor_citizen_id = actor_cid,
    actor_src        = actor_src,
    target_iban      = to_iban,
    event_data       = {
      txn_id       = txn_id,
      from_iban    = from_iban,
      to_iban      = to_iban,
      amount_minor = amount_minor,
      reason       = fail_reason,
    },
    correlation_id   = correlation,
  })
end

-- -----------------------------------------------------------------------------
-- §4. Govt / admin
-- -----------------------------------------------------------------------------

function M.GovtAuditRequest(actor_src, actor_cid, target_cid, reason, correlation)
  return Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.GOVT_AUDIT_REQUEST,
    actor_citizen_id = actor_cid,
    actor_src        = actor_src,
    target_citizen_id= target_cid,
    event_data       = { reason = reason, requested_ms = now_ms() },
    correlation_id   = correlation,
  })
end

function M.AdminBalanceAdjust(actor_src, actor_cid, target_cid, iban, account_id, delta_minor, reason, correlation)
  return Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.BALANCE_ADJUST_ADMIN,
    actor_citizen_id = actor_cid,
    actor_src        = actor_src,
    target_citizen_id= target_cid,
    target_iban      = iban,
    target_account_id= account_id,
    event_data       = { delta_minor = delta_minor, reason = reason },
    correlation_id   = correlation,
  })
end

-- -----------------------------------------------------------------------------
-- §5. Watchdog / system
-- -----------------------------------------------------------------------------

function M.WatchdogCompromised(actor_cid, metric, sample_n, ratio)
  return Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.WATCHDOG_COMPROMISED,
    actor_citizen_id = actor_cid,
    event_data       = {
      metric    = metric,
      sample_n  = sample_n,
      ratio     = ratio,
      detected_ms = now_ms(),
    },
  })
end

function M.WatchdogRestored(actor_cid, metric, sample_n, ratio)
  return Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.WATCHDOG_RESTORED,
    actor_citizen_id = actor_cid,
    event_data       = {
      metric   = metric,
      sample_n = sample_n,
      ratio    = ratio,
      restored_ms = now_ms(),
    },
  })
end

return M
