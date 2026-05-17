/* ============================================================================
   C-FE-03 Â§2 â€” TypeScript contracts mirroring Backend C-BE-01/02 LOCKED v1.0.1 R1
   Amounts are MINOR units (cents) â€” atomic decimal Backend-canonical.
   Use formatAmount(minor) to display.
   ============================================================================ */

export type Iban = string

export type AccountStatus = 'active' | 'frozen' | 'closed' | 'pending'

export interface Account {
  account_id: string
  iban: Iban
  owner_type?: 'personal' | 'company' | 'cooperative' | 'government' | 'escrow_managed'
  account_class?: 'checking' | 'savings' | 'business_treasury' | 'shared' | 'govt_treasury' | 'escrow' | 'crypto_wallet'
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

// F06 — NUI ATM PIN verify + withdraw payloads/responses.
export interface AtmVerifyPinPayload {
  card_id: string
  pin: string
  terminal_id?: string
}

export interface AtmVerifyPinResponse {
  grant_id: string
  expires_at_ms: number
  card_id: string
}

export interface AtmNuiWithdrawPayload {
  card_id: string
  grant_id: string
  amount_minor: number
  terminal_id?: string
}

export interface AtmNuiWithdrawResponse {
  iban: string
  amount_minor: number
  new_balance: number | null
  terminal_id: string
}

export interface AtmNuiDepositPayload {
  card_id: string
  grant_id: string
  amount_minor: number
  terminal_id?: string
}

export interface AtmNuiDepositResponse {
  iban: string
  amount_minor: number
  new_balance: number | null
  terminal_id: string
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

export interface LoanProduct {
  id: string
  name: string
  min_principal: number
  max_principal: number
  base_rate_bps: number
  max_rate_bps: number
  max_term_days: number
  collateral_required: boolean
}

export interface LoanProductsResponse {
  items: LoanProduct[]
  fetched_at_ms: number
}

export interface Loan {
  loan_id: string
  borrower_citizen_id: string
  deposit_iban?: string
  product_id: string
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

export interface LoanRequestResponse {
  loan_id: string
  status: 'requested' | 'pending'
}

export interface LoanPaymentResponse {
  loan_id: string
  amount_minor: number
  payment_ms: number
  paid_off: boolean
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

export type CardStatus = 'active' | 'locked' | 'expired' | 'pending' | 'revoked'

export type CardType = 'debit' | 'virtual' | 'credit' | 'classic' | 'premium'

/**
 * REQ-FE-014 â€” BankCard contract.
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
 * Never sent by a real BE â€” the production flow would return `pan_last_four`
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

export interface BusinessPayrollExecuteRequest {
  company_id: string
}

export interface BusinessPayrollExecuteResponse {
  company_id: string
  batch_id: string
  approval_id: string | null
  status: 'pending_approval' | 'queued' | 'executed'
  total_net_minor: number
  employee_count: number
  requires_approvals: number
  cross_ref_audit_id?: string
  committed_at_ms: number
}

export interface BusinessWithdrawalRequest {
  company_id: string
  amount_minor: number
  note?: string
}

export interface BusinessWithdrawalResponse {
  company_id: string
  approval_id: string
  status: 'pending'
  amount_minor: number
  requires_approvals: number
  cross_ref_audit_id?: string
  committed_at_ms: number
}

export interface BusinessApprovalDecideRequest {
  approval_id: string
  decision: 'approve' | 'reject'
  note?: string
}

export interface BusinessApprovalDecideResponse {
  company_id: string
  approval_id: string
  batch_id: string
  status: 'pending_approval' | 'executed' | 'cancelled'
  signers_approved: number
  signers_required: number
  paid_total_minor: number
  cross_ref_audit_id?: string
  committed_at_ms: number
}

/* ============================================================================
   REQ-FE-001 â€” sonar:bank:bootstrap:snapshot response (C001)
   ============================================================================ */

/**
 * Customer-facing branding, exposed to the FE via bootstrap.app.branding.
 * Defaults come from `Config.CustomerApp.Branding`; banker overrides
 * (`branding_*` keys in `sonar_bank_config_overrides`) replace per-field
 * values at read time.
 */
export interface BankAppBranding {
  bank_name: string
  short_name: string
  primary_color: string
  accent_color: string
  welcome_message: string
  logo_url: string
  support_email: string
  support_url: string
}

/**
 * Customer-facing feature flags. Each key gates a high-level capability
 * on both UI and backend (services return FEATURE_DISABLED if hit).
 * Server admins control these via `Config.CustomerApp.Features`.
 */
export interface BankAppFeatures {
  accounts_open: boolean
  accounts_close: boolean
  accounts_freeze_self: boolean
  accounts_joint_owners: boolean
  savings: boolean
  cards_issue: boolean
  cards_freeze: boolean
  cards_set_limits: boolean
  cards_change_pin: boolean
  transfers_p2p: boolean
  transfers_express: boolean
  recurring: boolean
  loans: boolean
  investments: boolean
  kyc: boolean
  business_treasury: boolean
  notifications: boolean
  onboarding_first_run: boolean
}

/**
 * Effective economic parameters (after banker overrides + clamping).
 * Null indicates the parameter has no configured band (FE should treat
 * as disabled / no-op).
 */
export interface BankAppEconomy {
  transfer_fee_bps: number | null
  daily_transfer_limit_minor: number | null
  atm_fee_minor_flat: number | null
  card_issue_fee_minor: number | null
  savings_interest_rate_bps: number | null
  loan_rate_spread_bps: number | null
  shared_account_min_minor: number | null
}

/**
 * Hard customer-side guardrails (constants, never overridable).
 */
export interface BankAppLimits {
  transfer_min_minor: number
  transfer_max_minor: number
  max_recipients_saved: number
  max_recurring_per_account: number
  pin_attempts_max: number
  pin_attempts_window_sec: number
}

/** Bootstrap.app — global app-level metadata (branding + features + economy). */
export interface BankAppMeta {
  branding: BankAppBranding
  features: BankAppFeatures
  economy: BankAppEconomy
  limits: BankAppLimits
  resource_version: string
}

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
  /** App-level meta (branding, feature flags, effective economy) — always fresh. */
  app?: BankAppMeta
  server_now_ms: number
  bootstrap_id: string
  cached: boolean
  duration_ms: number
}

/* ============================================================================
   REQ-FE-001 â€” sonar:bank:bootstrap:balance fallback (C001b)
   ============================================================================ */

export interface BalanceSnapshot {
  balance_minor: number
  savings_minor: number
  iban: Iban
  citizen_id: string
  server_now_ms: number
}

/* ============================================================================
   REQ-FE-002 â€” sonar:bank:transfer:recentRecipients response (C009)
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
   Canonical wrap envelope (server _wrap.lua Â§2)
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
  | 'sonar:bank:notification:push'

export interface NuiNetEventMessage {
  type: 'NET_EVENT'
  event: NuiNetEventName
  payload: unknown
}

export interface NuiSystemMessage {
  type: 'BANK_READY' | 'BANK_OPEN' | 'BANK_CLOSE'
}

export type NuiInboundMessage = NuiNetEventMessage | NuiSystemMessage
export interface ProfessionalAccountApproval {
  approval_id: string
  citizen_id: string
  account_class: 'business_treasury'
  state: 'pending' | 'approved' | 'rejected'
  note?: string | null
  decision_note?: string | null
  decided_by_citizen_id?: string | null
  created_account_id?: string | null
  created_iban?: string | null
  requested_ms: number
  decided_ms?: number | null
}

export interface ProfessionalAccountApprovalsResponse {
  items: ProfessionalAccountApproval[]
  fetched_at_ms: number
}

export interface ProfessionalAccountRequestArgs {
  note?: string
}

export interface ProfessionalAccountRequestResponse {
  approval_id?: string
  status: 'pending' | 'approved'
  requested_ms?: number
  committed_at_ms?: number
  replayed?: boolean
  account?: Account
}

export interface ProfessionalAccountDecisionRequest {
  approval_id: string
  decision: 'approve' | 'reject'
  note?: string
}

export interface ProfessionalAccountDecisionResponse {
  approval_id: string
  status: 'approved' | 'rejected'
  account?: Account
  committed_at_ms: number
}
