/* ============================================================================
   SONAR Treasury Bureau — data contracts (govt-scoped)
   Independent from consumer Bank contracts. May reference shared primitives
   (cents money) but never leaks consumer-only fields back into govt views.
   ============================================================================ */

export type GovtCitizenStatus = 'active' | 'flagged' | 'sanctioned' | 'exempt'
export type GovtTaxCompliance = 'current' | 'overdue' | 'pending' | 'exempt'
export type GovtRiskLevel = 'low' | 'medium' | 'high' | 'critical'

export type GovtActivityType =
  | 'transfer_out'
  | 'transfer_in'
  | 'card_charge'
  | 'tax_payment'
  | 'flag_raised'
  | 'sanction_applied'
  | 'subsidy_received'

export interface GovtCitizenSummary {
  cid: string
  alias: string
  status: GovtCitizenStatus
  taxCompliance: GovtTaxCompliance
  riskScore: number
  riskLevel: GovtRiskLevel
  totalHoldings: number
  accountCount: number
  flagCount: number
  lastActivityAt: number
  residencyDays: number
}

export interface GovtCitizenActivityEntry {
  id: string
  timestamp: number
  type: GovtActivityType
  amount: number
  description: string
  counterparty?: string
}

export type GovtFlagSeverity = 'info' | 'low' | 'medium' | 'high' | 'critical'
export type GovtFlagStatus = 'open' | 'reviewing' | 'resolved' | 'dismissed'

export interface GovtCitizenFlag {
  id: string
  raisedAt: number
  severity: GovtFlagSeverity
  status: GovtFlagStatus
  summary: string
}

export interface GovtCitizenTaxStatus {
  bracketCode: string
  periodObligation: number
  paid: number
  outstanding: number
}

export interface GovtCitizenDetail extends GovtCitizenSummary {
  primaryIban: string
  recentActivity: GovtCitizenActivityEntry[]
  flags: GovtCitizenFlag[]
  taxStatus: GovtCitizenTaxStatus
}

export interface GovtCensusFilters {
  search: string
  status: GovtCitizenStatus | 'all'
  compliance: GovtTaxCompliance | 'all'
  riskLevel: GovtRiskLevel | 'all'
}
