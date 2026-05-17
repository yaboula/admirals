/**
 * SONAR Bank App — banker/data/contractsF5.ts
 * --------------------------------------------------------------------------
 * Phase 5: compliance flags review.
 */

export type ComplianceFlagStatus = 'open' | 'investigating' | 'resolved' | 'false_positive'
export type ComplianceFlagSeverity = 'info' | 'notice' | 'warning' | 'critical'
export type ComplianceFlagType =
  | 'structuring'
  | 'large_transfer'
  | 'late_tax'
  | 'velocity_high'
  | 'new_account_large_deposit'

export interface BankerComplianceFlag {
  flag_id: number
  flag_type: ComplianceFlagType
  severity: ComplianceFlagSeverity
  status: ComplianceFlagStatus
  citizen_id: string | null
  bank_account_id: string | null
  iban: string | null
  raised_by: 'system' | 'admin' | 'watchdog' | null
  raised_ms: number
  threshold_minor: number | null
  observed_value_minor: number | null
  time_window_seconds: number | null
  action_taken: string | null
  resolution_note: string | null
  resolved_ms: number | null
}

export interface BankerComplianceListResponse {
  items: BankerComplianceFlag[]
  filters: { status: string; severity: string; limit: number }
  fetched_at_ms: number
}

export type BankerComplianceResolveRequest = {
  flag_id: number
  decision: 'resolved' | 'false_positive'
  note?: string
} & Record<string, unknown>

export interface BankerComplianceResolveResponse {
  flag_id: number
  decision: 'resolved' | 'false_positive'
  applied_at_ms: number
}
