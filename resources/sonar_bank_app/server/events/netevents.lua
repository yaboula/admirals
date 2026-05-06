-- =============================================================================
-- SONAR Bank App — events/netevents.lua
-- =============================================================================
-- Catalog (and registration) of NetEvents emitted by sonar_bank_app per
-- C-BE-01 v1.0.1 R1 LOCKED (54 events).
--
-- Strategy:
--   - Server emits NetEvents via TriggerClientEvent(name, target_src, payload).
--     Privacy boundary (CP1-B per M004): server-side filtering by src — never
--     broadcast financial PII.
--   - Client-bound NetEvents are NOT registered server-side via RegisterNetEvent
--     (only client registers them). This module exposes EMITTER helpers that
--     wrap TriggerClientEvent + canonical payload shape.
--   - Client→Server NetEvents (rare in Bank — Bank uses callbacks, not events,
--     for request/response) ARE registered here defensively to refuse unknown
--     senders + emit audit on attempted abuse.
--
-- This module exposes:
--   M.Emitters         — typed emitter helpers (Bank → client[s])
--   M.RegisterServerListeners  — attach defensive listeners for any C2S events
--
-- All event NAMES are documented inline matching c_be_01_events_catalog_v1_3.md.
-- =============================================================================

BankApp.events.netevents = {}
local M = BankApp.events.netevents

local Validators = BankApp.lib.validators
local Audit      = BankApp.lib.audit
local Enums      = BankApp.lib.enums

-- -----------------------------------------------------------------------------
-- §1. Canonical event names (catalog mirror)
-- -----------------------------------------------------------------------------

M.NAMES = {
  -- Balance / savings (M004 R1 NEW)
  BALANCE_UPDATE        = 'sonar:bank:balance:update',          -- per-player CP1-B publish
  SAVINGS_UPDATE        = 'sonar:bank:savings:update',          -- per-player savings-only delta
  BALANCE_ADMIN_AUDIT   = 'sonar:bank:balance:adminAudit',      -- admin-targeted on-demand snapshot

  -- Transfer lifecycle
  TRANSFER_COMMITTED    = 'sonar:bank:transfer:committed',
  TRANSFER_FAILED       = 'sonar:bank:transfer:failed',
  TRANSFER_REVERTED     = 'sonar:bank:transfer:reverted',

  -- Account lifecycle
  ACCOUNT_OPENED        = 'sonar:bank:account:opened',
  ACCOUNT_CLOSED        = 'sonar:bank:account:closed',
  ACCOUNT_FROZEN        = 'sonar:bank:account:frozen',
  ACCOUNT_UNFROZEN      = 'sonar:bank:account:unfrozen',

  -- Cards
  CARD_ISSUED           = 'sonar:bank:card:issued',
  CARD_FROZEN           = 'sonar:bank:card:frozen',
  CARD_UNFROZEN         = 'sonar:bank:card:unfrozen',

  -- Loans
  LOAN_APPROVED         = 'sonar:bank:loan:approved',
  LOAN_REJECTED         = 'sonar:bank:loan:rejected',
  LOAN_PAYMENT          = 'sonar:bank:loan:payment',
  LOAN_PAID_OFF         = 'sonar:bank:loan:paidOff',

  -- Recurring
  RECURRING_CHARGED     = 'sonar:bank:recurring:charged',
  RECURRING_FAILED      = 'sonar:bank:recurring:failed',

  -- Portfolio
  PORTFOLIO_BUY         = 'sonar:bank:portfolio:buy',
  PORTFOLIO_SELL        = 'sonar:bank:portfolio:sell',

  -- ATM
  ATM_WITHDRAW          = 'sonar:bank:atm:withdraw',

  -- Compliance / fraud
  COMPLIANCE_FLAG_SET   = 'sonar:bank:compliance:flagSet',
  COMPLIANCE_FLAG_UNSET = 'sonar:bank:compliance:flagUnset',
  KYC_DECISION          = 'sonar:bank:kyc:decision',
  FRAUD_REVIEW_OPEN     = 'sonar:bank:fraud:reviewOpen',
  FRAUD_REVIEW_RESOLVE  = 'sonar:bank:fraud:reviewResolve',

  -- Govt
  GOVT_AUDIT_REQUEST    = 'sonar:bank:govt:auditRequest',
  GOVT_AUDIT_RESPONSE   = 'sonar:bank:govt:auditResponse',
  GOVT_FREEZE           = 'sonar:bank:govt:freeze',
  GOVT_UNFREEZE         = 'sonar:bank:govt:unfreeze',

  -- System / watchdog
  WATCHDOG_COMPROMISED  = 'sonar:bank:watchdog:compromised',
  WATCHDOG_RESTORED     = 'sonar:bank:watchdog:restored',
  PERF_ALERT            = 'sonar:bank:metrics:perfAlert',
}

-- -----------------------------------------------------------------------------
-- §2. Emitter helpers (server → specific player src)
-- -----------------------------------------------------------------------------

M.Emitters = {}

--- to_player — defensive emit to a specific online src.
local function to_player(src, name, payload)
  if type(src) ~= 'number' or src <= 0 then return false end
  if GetPlayerName(src) == nil then return false end  -- offline
  TriggerClientEvent(name, src, payload)
  return true
end

function M.Emitters.TransferCommitted(src, data)
  return to_player(src, M.NAMES.TRANSFER_COMMITTED, data)
end

function M.Emitters.TransferFailed(src, data)
  return to_player(src, M.NAMES.TRANSFER_FAILED, data)
end

function M.Emitters.AccountOpened(src, data)
  return to_player(src, M.NAMES.ACCOUNT_OPENED, data)
end

function M.Emitters.AccountFrozen(src, data)
  return to_player(src, M.NAMES.ACCOUNT_FROZEN, data)
end

function M.Emitters.AccountUnfrozen(src, data)
  return to_player(src, M.NAMES.ACCOUNT_UNFROZEN, data)
end

function M.Emitters.CardIssued(src, data)
  return to_player(src, M.NAMES.CARD_ISSUED, data)
end

function M.Emitters.LoanApproved(src, data)
  return to_player(src, M.NAMES.LOAN_APPROVED, data)
end

function M.Emitters.LoanRejected(src, data)
  return to_player(src, M.NAMES.LOAN_REJECTED, data)
end

function M.Emitters.RecurringCharged(src, data)
  return to_player(src, M.NAMES.RECURRING_CHARGED, data)
end

function M.Emitters.RecurringFailed(src, data)
  return to_player(src, M.NAMES.RECURRING_FAILED, data)
end

function M.Emitters.AtmWithdraw(src, data)
  return to_player(src, M.NAMES.ATM_WITHDRAW, data)
end

function M.Emitters.ComplianceFlagSet(src, data)
  return to_player(src, M.NAMES.COMPLIANCE_FLAG_SET, data)
end

function M.Emitters.GovtFreeze(src, data)
  return to_player(src, M.NAMES.GOVT_FREEZE, data)
end

function M.Emitters.PerfAlert(src, data)
  return to_player(src, M.NAMES.PERF_ALERT, data)
end

-- -----------------------------------------------------------------------------
-- §3. Defensive C2S listener registration
--
--   Bank protocol is callback-based. Any client→server event with bank: prefix
--   that lands here is suspicious. We log + audit + drop. This catches:
--     - Modded clients sending crafted events
--     - Mistaken integrations from other resources
-- -----------------------------------------------------------------------------

local SUSPICIOUS_C2S_PATTERN = '^sonar:bank:'

local function defensive_listener(event_name, payload)
  local src = source
  if type(src) ~= 'number' or src <= 0 then return end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.AUTH_DENIED,
    actor_src        = src,
    event_data       = {
      reason     = 'unsolicited_c2s_netevent',
      event_name = event_name,
      payload_summary = type(payload) == 'table' and 'table' or tostring(payload):sub(1, 64),
    },
  })

  -- Optional: kick the player if abuse rate exceeds threshold (Phase B).
end

--- RegisterServerListeners — must be called once at boot.
function M.RegisterServerListeners()
  -- We do NOT register every catalog name (cost). Instead we register a single
  -- catch-all on the most likely C2S abuse vectors.
  local abuse_targets = {
    M.NAMES.BALANCE_UPDATE,
    M.NAMES.TRANSFER_COMMITTED,
    M.NAMES.ACCOUNT_OPENED,
    M.NAMES.ATM_WITHDRAW,
  }
  for _, name in ipairs(abuse_targets) do
    RegisterNetEvent(name, function(payload)
      defensive_listener(name, payload)
    end)
  end
end

return M
