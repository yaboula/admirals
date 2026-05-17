/**
 * SONAR Bank App — banker/data/contractsF2.ts
 * --------------------------------------------------------------------------
 * Phase 2 contracts: dashboard KPIs + operations queues + customers.
 */

// ===================== Dashboard =====================

export interface BankerDashboardKpis {
  total_accounts: number
  total_customers: number
  total_balance_minor: number
  total_savings_minor: number
  frozen_accounts: number
  loans_active: number
  loans_outstanding_minor: number
  loans_pending: number
  pro_accounts_pending: number
  employees_active: number
}

export interface BankerAccountClassRow {
  account_class: string
  n: number
  sum_balance_minor: number
}

export interface BankerTimeseriesRow {
  day: string
  n: number
  volume_minor: number
}

export interface BankerLoanPortfolioRow {
  product_id: string
  n: number
  outstanding_minor: number
}

export interface BankerDashboardResponse {
  kpis: BankerDashboardKpis
  accounts_by_class: BankerAccountClassRow[]
  transfers_timeseries: BankerTimeseriesRow[]
  loan_portfolio: BankerLoanPortfolioRow[]
  partial_errors: Record<string, string | null>
  fetched_at_ms: number
}

// ===================== Operations =====================

export interface BankerPendingLoan {
  loan_id: string
  borrower_citizen_id: string
  product_id: string
  principal_minor: number
  interest_bps: number
  term_days: number
  deposit_iban: string | null
  requested_ms: number
}

export interface BankerPendingProAccount {
  approval_id: string
  citizen_id: string
  account_class: 'business_treasury'
  state: 'pending' | 'approved' | 'rejected'
  note: string | null
  requested_ms: number
}

export interface BankerPendingKyc {
  citizen_id: string
  submitted_ms: number
  doc_count: string | number | null
}

export interface BankerOperationsQueuesResponse {
  loans_pending: BankerPendingLoan[]
  pro_accounts_pending: BankerPendingProAccount[]
  kyc_pending: BankerPendingKyc[]
  partial_errors: Record<string, string | null>
  fetched_at_ms: number
}

export type BankerLoanDecideRequest = {
  loan_id: string
  decision: 'approve' | 'reject'
  deposit_iban?: string
  reason?: string
} & Record<string, unknown>

export type BankerProAccountDecideRequest = {
  approval_id: string
  decision: 'approve' | 'reject'
  note?: string
} & Record<string, unknown>

export type BankerKycDecideRequest = {
  target_citizen_id: string
  decision: 'approve' | 'reject'
  reason?: string
} & Record<string, unknown>

export interface BankerDecideResponse {
  // Each underlying service returns its own shape, so this is a loose envelope.
  // The FE only checks `ok` and uses the response to refresh queues.
  [key: string]: unknown
}

// ===================== Customers =====================

export interface BankerCustomerRow {
  citizen_id: string
  account_count: number
  total_balance_minor: number
  total_savings_minor: number
  last_activity_ms: number | null
  frozen_count: number
}

export interface BankerCustomerSearchResponse {
  items: BankerCustomerRow[]
  query: string
  fetched_at_ms: number
}

export interface BankerCustomerAccount {
  account_id: string
  iban: string
  owner_type: string
  account_class: string
  balance_minor: number
  savings_minor: number
  is_frozen: boolean
  created_ms: number | null
  updated_ms: number | null
}

export interface BankerCustomerDetailResponse {
  citizen_id: string
  accounts: BankerCustomerAccount[]
  account_count: number
  frozen_count: number
  total_balance_minor: number
  total_savings_minor: number
  fetched_at_ms: number
}

export type BankerFreezeRequest = {
  iban: string
  reason?: string
} & Record<string, unknown>

export interface BankerFreezeResponse {
  iban: string
  frozen: boolean
  no_op?: boolean
  committed_at_ms?: number
}
