/**
 * SONAR Bank App — banker/data/contracts.ts
 * --------------------------------------------------------------------------
 * TypeScript contracts mirroring the Lua services in
 *   server/services/banker/{bootstrap,employees}.lua
 *
 * Keep these shapes IN SYNC with the server — any drift causes runtime
 * envelope errors. When adding a new banker endpoint, update both layers
 * in the same commit (BANK-FE.LOCK).
 */

export type BankerRole =
  | 'ceo'
  | 'manager'
  | 'compliance_officer'
  | 'advisor'
  | 'teller'

export const BANKER_ROLE_ORDER: BankerRole[] = [
  'ceo',
  'manager',
  'compliance_officer',
  'advisor',
  'teller',
]

export interface BankerEmployee {
  id: string
  citizen_id: string
  role: BankerRole
  role_label?: string
  status: 'active' | 'suspended' | 'fired'
  salary_minor: number
  hired_at: number | null
  hired_by_citizen_id?: string | null
  fired_at?: number | null
  fired_by_citizen_id?: string | null
  fired_reason?: string | null
  notes?: string | null
}

export interface BankerActiveEmployee {
  id: string
  citizen_id: string
  role: BankerRole
  role_label?: string
  role_weight: number
  status: 'active' | 'suspended' | 'fired'
  salary_minor: number
  hired_at: number | null
  synthetic_admin: boolean
}

export interface BankerCapabilityMap {
  panel_open: boolean
  employees_view: boolean
  employees_hire: boolean
  employees_fire: boolean
  employees_set_role: boolean
  rates_view: boolean
  rates_edit: boolean
  branding_view: boolean
  branding_edit: boolean
  customers_view: boolean
  customers_freeze: boolean
  loans_approve: boolean
  kyc_approve: boolean
  pro_account_approve: boolean
  fraud_review: boolean
  audit_query: boolean
  marketing_create: boolean
  missions_dispatch: boolean
  missions_accept: boolean
}

export interface BankerLimitBand {
  default: number
  min: number
  max: number
  step: number
}

export interface BankerLimitsCatalog {
  savings_interest_rate_bps: BankerLimitBand
  loan_rate_spread_bps: BankerLimitBand
  transfer_fee_bps: BankerLimitBand
  atm_fee_minor_flat: BankerLimitBand
  card_issue_fee_minor: BankerLimitBand
  daily_transfer_limit_minor: BankerLimitBand
  shared_account_min_minor: BankerLimitBand
}

export interface BankerBranding {
  bank_name: string
  primary_color: string
  accent_color: string
  welcome_message: string
  logo_url: string
}

export interface BankerOverrideEntry {
  value: unknown
  updated_at: number
  updated_by_citizen_id?: string | null
  updated_by_role?: string | null
}

export interface BankerRoleDef {
  weight: number
  label: string
}

export interface BankerBootstrapResponse {
  employee: BankerActiveEmployee
  capabilities: BankerCapabilityMap
  roles_catalog: Record<BankerRole, BankerRoleDef>
  limits_catalog: BankerLimitsCatalog
  missions_catalog: Record<string, unknown>
  branding: BankerBranding
  overrides: Record<string, BankerOverrideEntry>
  counts: Partial<Record<BankerRole, number>>
  fetched_at_ms: number
}

export interface BankerEmployeesListResponse {
  items: BankerEmployee[]
  fetched_at_ms: number
}

export type BankerHireRequest = {
  target_citizen_id: string
  role: BankerRole
  salary_minor?: number
  notes?: string
} & Record<string, unknown>

export interface BankerHireResponse {
  employee_id: string
  citizen_id: string
  role: BankerRole
  salary_minor: number
  committed_at_ms: number
}

export type BankerFireRequest = {
  employee_id: string
  reason?: string
} & Record<string, unknown>

export interface BankerFireResponse {
  employee_id: string
  fired_at_ms: number
}

export type BankerSetRoleRequest = {
  employee_id: string
  new_role: BankerRole
} & Record<string, unknown>

export interface BankerSetRoleResponse {
  employee_id: string
  new_role: BankerRole
  new_salary_minor: number
  committed_at_ms: number
}

export type BankerSetSalaryRequest = {
  employee_id: string
  salary_minor: number
} & Record<string, unknown>

export interface BankerSetSalaryResponse {
  employee_id: string
  new_salary_minor: number
  committed_at_ms: number
}
