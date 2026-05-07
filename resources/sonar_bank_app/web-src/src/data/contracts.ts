/* ============================================================================
   C-FE-03 §2 — TypeScript contracts mirroring Backend C-BE-01/02 LOCKED v1.0.1 R1
   Amounts are MINOR units (cents) — atomic decimal Backend-canonical.
   Use formatAmount(minor) to display.
   ============================================================================ */

export type Iban = string

export type AccountStatus = 'active' | 'frozen' | 'closed' | 'pending'

export interface Account {
  account_id: string
  iban: Iban
  owner_citizen_id: string
  joint_owners: string[] | null
  balance_minor: number
  savings_minor: number
  status: AccountStatus
  frozen_flag: 0 | 1 | boolean
  created_ms: number
}

export type TransactionDirection = 'in' | 'out' | 'self'

export type TransactionStatus =
  | 'committed'
  | 'pending'
  | 'reconciling'
  | 'reverted'
  | 'failed'

export interface Transaction {
  txn_id: string
  from_iban: Iban
  to_iban: Iban
  amount_minor: number
  reason: string | null
  direction: TransactionDirection
  status: TransactionStatus
  timestamp_ms: number
}

export interface RecentRecipient {
  counterpart_iban: Iban
  alias: string | null
  is_favorite: boolean
  last_transfer_ms: number
  transfer_count: number
  preset_amounts: number[]
  last_reason: string | null
}

export interface SavedRecipient {
  counterpart_iban: Iban
  alias: string | null
  is_favorite: boolean
  created_ms: number
}

export type LoanStatus = 'active' | 'paid' | 'defaulted' | 'pending'

export interface Loan {
  loan_id: string
  borrower_citizen_id: string
  principal_minor: number
  interest_bps: number
  term_days: number
  status: LoanStatus
  issued_ms: number
  due_ms: number
  outstanding_minor: number
  created_ms: number
}

export type RecurringStatus = 'active' | 'paused' | 'cancelled'

export interface Recurring {
  recurring_id: string
  owner_citizen_id: string
  from_iban: Iban
  to_iban: Iban
  amount_minor: number
  reason: string | null
  interval_days: number
  status: RecurringStatus
  next_charge_ms: number
  last_charge_ms: number | null
  created_ms: number
}

export interface PortfolioHolding {
  holding_id: string
  symbol: string
  qty: number
  cost_basis_minor: number
  market_value_minor: number
  delta_pct: number
  created_ms: number
}

export type CardStatus = 'active' | 'locked' | 'expired' | 'pending'

export type CardType = 'debit' | 'virtual' | 'credit'

/**
 * REQ-FE-014 — BankCard contract.
 *
 * Canonical minimum kept for BE compatibility (Phase A / H3):
 *   card_id, owner_citizen_id, iban, status, pan_last_four, expiry_ms, created_ms.
 *
 * BANK-FE.4 additions (visual + functional, eventually persisted by BE):
 *   - card_type: product tier (debit / virtual / credit).
 *   - design_id: references @/routes/cards/cardDesigns registry.
 *   - holder_name: denormalized from citizen profile for offline display.
 *   - daily_limit_minor / daily_spent_minor: daily spending meter.
 *   - monthly_limit_minor / monthly_spent_minor: monthly spending meter.
 *
 * FULL PAN and CVV are NEVER part of the canonical contract for security.
 * The mock seed exposes them via a separate `BankCardMock` extension used
 * only when isMockMode() is true.
 */
export interface BankCard {
  card_id: string
  owner_citizen_id: string
  iban: Iban
  status: CardStatus
  pan_last_four: string
  expiry_ms: number
  created_ms: number
  card_type: CardType
  design_id: string
  holder_name: string
  daily_limit_minor: number
  daily_spent_minor: number
  monthly_limit_minor: number
  monthly_spent_minor: number
}

/**
 * Mock-only card with full PAN and CVV for local dev. Gated to isMockMode().
 * Never sent by a real BE — the production flow would return `pan_last_four`
 * only and require a dedicated, authenticated "reveal" endpoint for CVV/PAN.
 */
export interface BankCardMock extends BankCard {
  full_pan: string
  cvv: string
}

export interface OutstandingNotice {
  audit_id: string
  event_type: string
  timestamp_ms: number
  details_json: string | null
  acknowledged: boolean
}

/* ============================================================================
   REQ-FE-001 — sonar:bank:bootstrap:snapshot response (C001)
   ============================================================================ */

export interface BootstrapSnapshot {
  citizen_id: string
  accounts: Account[]
  recent_transactions: Transaction[]
  recent_recipients: RecentRecipient[]
  saved_recipients: SavedRecipient[]
  loans: Loan[]
  recurring: Recurring[]
  portfolio: PortfolioHolding[]
  cards: BankCardMock[]
  outstanding_notices: OutstandingNotice[]
  pending_tx_count: number
  server_now_ms: number
  bootstrap_id: string
  cached: boolean
  duration_ms: number
}

/* ============================================================================
   REQ-FE-001 — sonar:bank:bootstrap:balance fallback (C001b)
   ============================================================================ */

export interface BalanceSnapshot {
  balance_minor: number
  savings_minor: number
  iban: Iban
  citizen_id: string
  server_now_ms: number
}

/* ============================================================================
   REQ-FE-002 — sonar:bank:transfer:recentRecipients response (C009)
   ============================================================================ */

export interface RecentRecipientsResponse {
  recipients: RecentRecipient[]
  fetched_at_ms: number
  cached: boolean
  duration_ms?: number
}

/* ============================================================================
   sonar:bank:nui:getConfig response (NUI_CONFIG)
   ============================================================================ */

export interface ClientConfigSnapshot {
  resource_version: string
  phase: string
  bootstrap: {
    total_timeout_ms: number
    max_accounts: number
    max_recipients: number
  }
  recent_recipients: {
    window_days: number
    limit: number
    preset_amounts: number
    cache_ttl_ms: number
  }
  perf_budgets: {
    bootstrap_p99_ms: number
    recent_recipients_p99_ms: number
    tier_1_read_p99_ms: number
    tier_2_write_p99_ms: number
  }
  features: {
    bootstrap_cache: boolean
    recipients_cache: boolean
  }
}

/* ============================================================================
   Canonical wrap envelope (server _wrap.lua §2)
   ============================================================================ */

export interface BankErrorPayload {
  code: string
  category?: 'validation' | 'auth' | 'rate_limit' | 'fsm' | 'compliance' | 'internal' | 'security' | 'not_found'
  message?: string
  details?: Record<string, unknown>
  retryable?: boolean
}

export type WrapResponse<T> =
  | { ok: true; data: T }
  | { ok: false; error: BankErrorPayload }

/* ============================================================================
   NUI envelope sent to client/nui_bridge.lua via fetch('cb', {...})
   ============================================================================ */

export interface NuiCallEnvelope {
  event: string
  payload: Record<string, unknown>
}

/* ============================================================================
   NetEvent payloads forwarded by client/nui_bridge.lua via SendNUIMessage
   ============================================================================ */

export type NuiNetEventName =
  | 'sonar:bank:balance:update'
  | 'sonar:bank:savings:update'
  | 'sonar:bank:transfer:committed'
  | 'sonar:bank:status:transition'
  | 'sonar:bank:notice:new'

export interface NuiNetEventMessage {
  type: 'NET_EVENT'
  event: NuiNetEventName
  payload: unknown
}

export interface NuiSystemMessage {
  type: 'BANK_READY' | 'BANK_OPEN' | 'BANK_CLOSE'
}

export type NuiInboundMessage = NuiNetEventMessage | NuiSystemMessage
