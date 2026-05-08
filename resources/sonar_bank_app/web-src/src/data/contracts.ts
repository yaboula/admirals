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

export type AtmSessionMode = 'read_only' | 'simulation'

export interface AtmDenomination {
  value_minor: number
  available_count: number
}

export interface AtmSessionAccount {
  iban_masked: string
  balance_minor: number
  savings_minor: number
  status: AccountStatus
}

export interface AtmSessionCard {
  card_id: string
  label: string
  pan_masked: string
  status: 'active' | 'frozen' | 'lost'
}

export interface AtmSessionEvent {
  event_id: string
  label: string
  timestamp_ms: number
  severity: 'info' | 'warning' | 'success'
}

export interface AtmSessionResponse {
  terminal_id: string
  location_label: string
  mode: AtmSessionMode
  online: boolean
  hmac_ready: boolean
  camera_check: 'clear' | 'blocked'
  cash_available_minor: number
  daily_limit_minor: number
  remaining_limit_minor: number
  denominations: AtmDenomination[]
  account: AtmSessionAccount
  card: AtmSessionCard
  events: AtmSessionEvent[]
  fetched_at_ms: number
}

export type LoanStatus = 'active' | 'paid' | 'defaulted' | 'pending'

export interface Loan {
  loan_id: string
  borrower_citizen_id: string
  product_name: string
  purpose: string
  principal_minor: number
  interest_bps: number
  term_days: number
  status: LoanStatus
  issued_ms: number
  due_ms: number
  outstanding_minor: number
  next_payment_minor: number
  next_payment_due_ms: number | null
  paid_installments: number
  total_installments: number
  risk_grade: 'A' | 'B' | 'C' | 'D'
  collateral_label: string | null
  created_ms: number
}

export type LoanInstallmentStatus = 'paid' | 'scheduled' | 'late'

export interface LoanInstallment {
  installment_id: string
  loan_id: string
  sequence: number
  due_ms: number
  amount_minor: number
  principal_minor: number
  interest_minor: number
  status: LoanInstallmentStatus
  paid_ms: number | null
}

export interface LoanListResponse {
  items: Loan[]
  fetched_at_ms: number
}

export interface LoanInstallmentsRequest {
  loan_id: string
}

export interface LoanInstallmentsResponse {
  loan_id: string
  items: LoanInstallment[]
  fetched_at_ms: number
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

export interface StockQuote {
  symbol: string
  name: string
  sector: string
  price_minor: number
  change_24h_pct: number
  market_cap_minor: number
  volume_24h: number
  updated_ms: number
}

export interface StockListResponse {
  items: StockQuote[]
  fetched_at_ms: number
}

export interface StockPortfolioResponse {
  holdings: PortfolioHolding[]
  total_cost_basis_minor: number
  total_market_value_minor: number
  total_delta_minor: number
  total_delta_pct: number
  fetched_at_ms: number
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

export type AuditScope = 'self' | 'business' | 'government'

export type AuditEventStatus = 'committed' | 'pending' | 'reverted' | 'failed'

export interface AuditEvent {
  audit_id: string
  event_type: string
  timestamp_ms: number
  actor_cid_masked: string
  amount_minor: number | null
  currency: 'USD' | 'EUR'
  correlation_id: string
  counterparty_iban_masked: string | null
  status: AuditEventStatus
  ace_perm: string | null
  reason: string | null
  scope_tag: AuditScope
  details_json: string | null
}

export interface AuditQueryRequest {
  scope: AuditScope
  query?: string
  event_type?: string
  status?: AuditEventStatus | 'all'
  cursor?: string | null
  limit?: number
}

export interface AuditQueryResponse {
  items: AuditEvent[]
  cursor_next: string | null
  has_more: boolean
  fetched_at_ms: number
}

export type ComplianceFlagStatus = 'open' | 'reviewing' | 'resolved' | 'dismissed'

export type ComplianceFlagSeverity = 'low' | 'medium' | 'high' | 'critical'

export interface ComplianceFlag {
  flag_id: string
  event_type: string
  subject_cid_masked: string
  account_iban_masked: string
  counterparty_iban_masked: string | null
  amount_minor: number | null
  currency: 'USD' | 'EUR'
  severity: ComplianceFlagSeverity
  status: ComplianceFlagStatus
  created_at_ms: number
  updated_at_ms: number
  risk_score: number
  reason: string
  assigned_unit: string
  evidence_count: number
  correlation_id: string
  details_json: string | null
}

export interface ComplianceFlagsQueryRequest {
  query?: string
  status?: ComplianceFlagStatus | 'all'
  severity?: ComplianceFlagSeverity | 'all'
  cursor?: string | null
  limit?: number
}

export interface ComplianceFlagsQueryResponse {
  items: ComplianceFlag[]
  cursor_next: string | null
  has_more: boolean
  fetched_at_ms: number
}

export type BusinessMemberRole = 'owner' | 'manager' | 'employee'

export interface BusinessMovement {
  movement_id: string
  event_type: string
  amount_minor: number
  currency: 'USD' | 'EUR'
  direction: 'in' | 'out'
  counterparty_masked: string
  reason: string | null
  status: AuditEventStatus
  timestamp_ms: number
}

export interface BusinessPendingApproval {
  approval_id: string
  type: 'payroll' | 'withdrawal' | 'recurring' | 'loan'
  requested_by_alias: string
  amount_minor: number
  currency: 'USD' | 'EUR'
  created_at_ms: number
  required_perm: string
  status: 'pending' | 'approved' | 'rejected'
}

export interface BusinessTreasurySnapshot {
  company_id: string
  company_name: string
  role: BusinessMemberRole
  treasury_iban_masked: string
  balance_minor: number
  currency: 'USD' | 'EUR'
  delta_4w_pct: number
  employee_count: number
  average_tenure_days: number
  total_payroll_month_minor: number
  recent_movements: BusinessMovement[]
  pending_approvals: BusinessPendingApproval[]
  fetched_at_ms: number
}

export interface BusinessTreasuryQueryRequest {
  company_id: string
}

export interface PayrollPreviewLine {
  line_id: string
  employee_alias: string
  department: string
  net_amount_minor: number
  currency: 'USD' | 'EUR'
  status: 'ready' | 'held'
}

export interface PayrollPreviewRequest {
  company_id: string
}

export interface PayrollPreviewResponse {
  company_id: string
  batch_id: string
  employee_count: number
  total_net_minor: number
  currency: 'USD' | 'EUR'
  requires_approvals: number
  scheduled_for_ms: number
  lines: PayrollPreviewLine[]
  fetched_at_ms: number
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
