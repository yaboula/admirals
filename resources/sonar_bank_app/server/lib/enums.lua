-- =============================================================================
-- SONAR Bank App — lib/enums.lua
-- =============================================================================
-- Canonical enums for Phase A R1.
--   §1  AUDIT_EVENT_TYPE         — C-SEC-01 §1.2 audit ledger event_type ENUM.
--   §2  AUDIT_EVENTS_REQUIRING_FLAG_SNAPSHOT — H006 enforcement table.
--   §3  SIDE_EFFECT              — C-BE-02 §6.5 taxonomy.
--   §4  TIER                     — callback tier classification.
--   §5  AUTH_LEVEL               — H001 gate matrix.
--   §6  ACCOUNT_STATUS           — FSM #1 account_lifecycle.
--   §7  TRANSACTION_STATUS       — FSM #2 transaction_lifecycle.
--   §8  IDEMPOTENCY_STATUS       — FSM #8 + M005 orphan_purged.
--   §9  TRANSFER_DIRECTION       — REQ-FE-002 + audit ledger.
--   §10 ESCROW_STATUS            — FSM #1 (sonar_bank consume) + R1 H005 guard.
--   §11 helpers (IsValid, FromString)
--
-- Sin deps. Cargado FIRST en lib chain.
-- =============================================================================

BankApp = BankApp or { lib = {}, services = {}, repos = {}, callbacks = {}, state = {}, events = {} }
BankApp.lib.enums = {}

local M = BankApp.lib.enums

-- -----------------------------------------------------------------------------
-- §1. Audit event types (C-SEC-01 §1.2 — append-only ledger schema)
-- -----------------------------------------------------------------------------
M.AUDIT_EVENT_TYPE = {
  -- Account lifecycle
  ACCOUNT_CREATE        = 'account_create',
  ACCOUNT_FREEZE        = 'account_freeze',
  ACCOUNT_UNFREEZE      = 'account_unfreeze',
  ACCOUNT_CLOSE         = 'account_close',

  -- Transactions
  TRANSFER_INIT         = 'transfer_init',
  TRANSFER_COMMITTED    = 'transfer_committed',
  TRANSFER_FAILED       = 'transfer_failed',
  TRANSFER_REVERTED     = 'transfer_reverted',

  -- Balance adjustments (admin)
  BALANCE_ADJUST_ADMIN  = 'balance_adjust_admin',
  BALANCE_RECONCILE     = 'balance_reconcile',

  -- Compliance flags (H006 — previous_flag_snapshot MANDATORY for these events)
  FLAG_SET              = 'flag_set',
  FLAG_UNSET            = 'flag_unset',
  KYC_SUBMIT            = 'kyc_submit',
  KYC_APPROVE           = 'kyc_approve',
  KYC_REJECT            = 'kyc_reject',

  -- Cards
  CARD_ISSUE            = 'card_issue',
  CARD_FREEZE           = 'card_freeze',
  CARD_UNFREEZE         = 'card_unfreeze',
  CARD_PIN_CHANGE       = 'card_pin_change',
  CARD_LIMITS_UPDATE    = 'card_limits_update',
  CARD_DESIGN_APPLIED   = 'card_design_applied',
  CARD_REVOKE           = 'card_revoked',

  -- Joint owners
  JOINT_OWNER_ADDED     = 'joint_owner_added',
  JOINT_OWNER_REMOVED   = 'joint_owner_removed',

  -- Loans
  LOAN_REQUEST          = 'loan_request',
  LOAN_APPROVE          = 'loan_approve',
  LOAN_REJECT           = 'loan_reject',
  LOAN_PAYMENT          = 'loan_payment',
  LOAN_PAYOFF           = 'loan_payoff',

  -- Recurring
  RECURRING_SUBSCRIBE   = 'recurring_subscribe',
  RECURRING_UNSUBSCRIBE = 'recurring_unsubscribe',
  RECURRING_CHARGE      = 'recurring_charge',
  RECURRING_FAILED      = 'recurring_failed',

  -- Portfolio (investments)
  PORTFOLIO_BUY         = 'portfolio_buy',
  PORTFOLIO_SELL        = 'portfolio_sell',

  -- ATM (M006 HMAC required for callsite)
  ATM_WITHDRAW          = 'atm_withdraw',
  ATM_FAILED            = 'atm_failed',

  -- Government / admin
  GOVT_AUDIT_REQUEST    = 'govt_audit_request',
  GOVT_AUDIT_RESPONSE   = 'govt_audit_response',
  GOVT_FREEZE           = 'govt_freeze',
  GOVT_UNFREEZE         = 'govt_unfreeze',
  GOVT_FINE_APPLY       = 'govt_fine_apply',
  GOVT_FLAG_CLOSE       = 'govt_flag_close',
  GOVT_TAX_BRACKETS_SAVE = 'govt_tax_brackets_save',
  GOVT_TAX_FORCE_COLLECTION = 'govt_tax_force_collection',
  GOVT_SUBSIDY_GRANT    = 'govt_subsidy_grant',

  BUSINESS_PAYROLL_REQUEST = 'business_payroll_request',
  BUSINESS_PAYROLL_EXECUTE = 'business_payroll_execute',
  BUSINESS_PAYROLL_EXECUTED = 'business_payroll_executed',
  BUSINESS_APPROVAL_DECIDE = 'business_approval_decide',
  BUSINESS_WITHDRAWAL_REQUEST = 'business_withdrawal_request',

  -- Anti-fraud
  FRAUD_REVIEW_OPEN     = 'fraud_review_open',
  FRAUD_REVIEW_RESOLVE  = 'fraud_review_resolve',

  -- System events (M005 orphan + M007 watchdog)
  IDEMPOTENCY_ORPHAN_PURGED = 'idempotency_orphan_purged',
  WATCHDOG_COMPROMISED      = 'watchdog_compromised',
  WATCHDOG_RESTORED         = 'watchdog_restored',

  -- Auth denials (H001 + H002)
  AUTH_DENIED               = 'auth_denied',
  AUTH_BRIDGE_DENIED        = 'auth_bridge_denied',  -- H002 BankStatus.Transition unauthorized
}

-- -----------------------------------------------------------------------------
-- §2. Events requiring previous_flag_snapshot (H006 enforcement table)
--
--   audit.lua writer fuerza presence de campo `previous_flag_snapshot` cuando
--   event_type ∈ this table. Missing snapshot → audit.Write rechaza con
--   ERR_AUDIT_SHAPE_INCOMPLETE.
-- -----------------------------------------------------------------------------
M.AUDIT_EVENTS_REQUIRING_FLAG_SNAPSHOT = {
  [M.AUDIT_EVENT_TYPE.FLAG_SET]         = true,
  [M.AUDIT_EVENT_TYPE.FLAG_UNSET]       = true,
  [M.AUDIT_EVENT_TYPE.ACCOUNT_FREEZE]   = true,
  [M.AUDIT_EVENT_TYPE.ACCOUNT_UNFREEZE] = true,
  [M.AUDIT_EVENT_TYPE.GOVT_FREEZE]      = true,
  [M.AUDIT_EVENT_TYPE.GOVT_UNFREEZE]    = true,
  [M.AUDIT_EVENT_TYPE.GOVT_FLAG_CLOSE]  = true,
  [M.AUDIT_EVENT_TYPE.KYC_APPROVE]      = true,
  [M.AUDIT_EVENT_TYPE.KYC_REJECT]       = true,
}

-- -----------------------------------------------------------------------------
-- §3. Side effect taxonomy (C-BE-02 §6.5)
-- -----------------------------------------------------------------------------
M.SIDE_EFFECT = {
  WRITE_ACCOUNT        = 'write_account',
  WRITE_TRANSACTION    = 'write_transaction',
  WRITE_AUDIT          = 'write_audit',
  WRITE_IDEMPOTENCY    = 'write_idempotency',
  PUBLISH_BALANCE      = 'publish_balance',     -- M004 CP1-B publish
  EMIT_EVENT           = 'emit_event',
  EXTERNAL_BRIDGE_CALL = 'external_bridge_call',
  NOTHING              = 'nothing',             -- pure read callbacks
}

-- -----------------------------------------------------------------------------
-- §4. Callback tier classification (C-BE-02 §4)
-- -----------------------------------------------------------------------------
M.TIER = {
  TIER_1_READ  = 'tier_1_read',
  TIER_2_WRITE = 'tier_2_write',
  TIER_3_ADMIN = 'tier_3_admin',
}

-- -----------------------------------------------------------------------------
-- §5. Auth level (H001 — gate matrix)
-- -----------------------------------------------------------------------------
M.AUTH_LEVEL = {
  AUTH_PLAYER     = 'auth_player',     -- any authenticated player
  AUTH_OWNER      = 'auth_owner',      -- specific account ownership required
  AUTH_ADMIN_ACE  = 'auth_admin_ace',  -- ACE 'sonar.bank.admin'
  AUTH_GOVT_ACE   = 'auth_govt_ace',   -- ACE 'sonar.bank.govt'
  AUTH_CONSOLE    = 'auth_console',    -- server console only (src=0)
}

-- -----------------------------------------------------------------------------
-- §6. Account FSM states (FSM #1 — account_lifecycle)
-- -----------------------------------------------------------------------------
M.ACCOUNT_STATUS = {
  PENDING  = 'pending',
  ACTIVE   = 'active',
  FROZEN   = 'frozen',
  CLOSED   = 'closed',
  ARCHIVED = 'archived',
}

-- -----------------------------------------------------------------------------
-- §7. Transaction FSM states (FSM #2 — transaction_lifecycle)
-- -----------------------------------------------------------------------------
M.TRANSACTION_STATUS = {
  PENDING     = 'pending',
  RECONCILING = 'reconciling',
  COMMITTED   = 'committed',
  REVERTED    = 'reverted',
  FAILED      = 'failed',
}

-- -----------------------------------------------------------------------------
-- §8. Idempotency FSM states (FSM #8 — api_idempotency_lifecycle + M005 orphan)
-- -----------------------------------------------------------------------------
M.IDEMPOTENCY_STATUS = {
  IN_FLIGHT     = 'in_flight',
  COMMITTED     = 'committed',
  ORPHAN        = 'orphan',
  ORPHAN_PURGED = 'orphan_purged',  -- M005 NEW state post-cron purge
}

-- -----------------------------------------------------------------------------
-- §9. Transfer direction (REQ-FE-002 recent recipients + audit ledger)
-- -----------------------------------------------------------------------------
M.TRANSFER_DIRECTION = {
  IN  = 'in',
  OUT = 'out',
}

-- -----------------------------------------------------------------------------
-- §10. Escrow lifecycle (FSM #1 sonar_bank consume + R1 H005 boundary guard)
-- -----------------------------------------------------------------------------
M.ESCROW_STATUS = {
  HELD      = 'held',
  PARTIAL   = 'partial',
  RELEASED  = 'released',
  CANCELLED = 'cancelled',
  EXPIRED   = 'expired',
}

-- -----------------------------------------------------------------------------
-- §11. Helpers
-- -----------------------------------------------------------------------------

--- IsValid: check if value is a valid member of an enum table.
---@param enum_table table  one of M.AUDIT_EVENT_TYPE / M.TIER / etc.
---@param value any
---@return boolean
function M.IsValid(enum_table, value)
  if type(enum_table) ~= 'table' or value == nil then return false end
  for _, v in pairs(enum_table) do
    if v == value then return true end
  end
  return false
end

--- FromString: alias for IsValid (semantic helper).
---@param enum_table table
---@param str string
---@return string|nil canonical_value if valid, else nil
function M.FromString(enum_table, str)
  if type(enum_table) ~= 'table' or type(str) ~= 'string' then return nil end
  for _, v in pairs(enum_table) do
    if v == str then return v end
  end
  return nil
end

--- RequiresFlagSnapshot: H006 helper — is event_type one that mandates snapshot?
---@param event_type string
---@return boolean
function M.RequiresFlagSnapshot(event_type)
  return M.AUDIT_EVENTS_REQUIRING_FLAG_SNAPSHOT[event_type] == true
end

return M
