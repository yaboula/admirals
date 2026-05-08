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

/* ============================================================================
   Sanctions module — flag queue, actions and history.
   ============================================================================ */

export type GovtSanctionActionType =
  | 'freeze_accounts'
  | 'lift_freeze'
  | 'apply_fine'
  | 'close_flag'

export interface GovtFlagQueueItem {
  flagId: string
  citizenCid: string
  citizenAlias: string
  citizenStatus: GovtCitizenStatus
  citizenRiskLevel: GovtRiskLevel
  raisedAt: number
  severity: GovtFlagSeverity
  status: GovtFlagStatus
  summary: string
}

export interface GovtSanctionAction {
  id: string
  type: GovtSanctionActionType
  targetCid: string
  targetAlias: string
  relatedFlagId?: string
  amount?: number
  verdict?: 'resolved' | 'dismissed'
  reason: string
  operator: string
  performedAt: number
  idempotencyKey: string
}

export interface GovtFlagQueueFilters {
  search: string
  severity: GovtFlagSeverity | 'all'
  status: GovtFlagStatus | 'all'
}

export interface GovtSanctionRequestBase {
  reason: string
  idempotencyKey: string
}

export interface GovtCloseFlagRequest extends GovtSanctionRequestBase {
  flagId: string
  verdict: 'resolved' | 'dismissed'
}

export interface GovtFreezeAccountsRequest extends GovtSanctionRequestBase {
  targetCid: string
  relatedFlagId?: string
}

export interface GovtLiftFreezeRequest extends GovtSanctionRequestBase {
  targetCid: string
  relatedFlagId?: string
}

export interface GovtApplyFineRequest extends GovtSanctionRequestBase {
  targetCid: string
  relatedFlagId?: string
  amount: number
}

/* ============================================================================
   Tax Engine — brackets, cycle stats, policy log.
   ACE P11: sonar.bank.govt.tax.write.
   ============================================================================ */

export type GovtTaxTierId = 'basic' | 'standard' | 'premium' | 'elite'

export interface GovtTaxBracket {
  id: GovtTaxTierId
  code: string
  label: string
  incomeMin: number
  incomeMax: number | null
  rate: number
  populationShare: number
  affectedCount: number
}

export interface GovtTaxDayPoint {
  dayIndex: number
  collectedCents: number
  obligationCents: number
}

export interface GovtTaxCycleStats {
  cycleId: string
  cycleStartMs: number
  cycleDurationDays: number
  totalObligationCents: number
  totalCollectedCents: number
  collectedTodayCents: number
  dailySeries: GovtTaxDayPoint[]
}

export interface GovtTaxPolicyChange {
  id: string
  operatorAlias: string
  changedAt: number
  delta: Array<{ tierId: GovtTaxTierId; oldRate: number; newRate: number }>
  reason: string
}

export interface GovtSaveBracketsRequest {
  brackets: Array<{ id: GovtTaxTierId; rate: number }>
  reason: string
  idempotencyKey: string
}

export interface GovtForceCollectionRequest {
  reason: string
  idempotencyKey: string
}

/* ============================================================================
   Business Registry — company listings, detail, risk and activity.
   ACE P04: sonar.bank.govt.read (same as Census).
   ============================================================================ */

export type GovtBusinessStatus = 'active' | 'frozen' | 'liquidating' | 'dissolved'

export type GovtBusinessSector =
  | 'farming'
  | 'milling'
  | 'bakery'
  | 'retail'
  | 'logistics'
  | 'services'
  | 'finance'
  | 'other'

export type GovtBusinessActivityType =
  | 'payroll_processed'
  | 'tax_payment'
  | 'transfer_in'
  | 'transfer_out'
  | 'employee_hired'
  | 'employee_fired'
  | 'flag_raised'
  | 'sanction_applied'

export interface GovtBusinessSummary {
  companyId: string
  name: string
  status: GovtBusinessStatus
  sector: GovtBusinessSector
  foundedAt: number
  employeeCount: number
  treasury: number
  taxCompliance: GovtTaxCompliance
  riskLevel: GovtRiskLevel
  riskScore: number
  flagCount: number
  lastActivityAt: number
}

export interface GovtBusinessDirector {
  cid: string
  alias: string
  role: 'founder' | 'director' | 'co-founder'
  joinedAt: number
}

export interface GovtBusinessActivity {
  id: string
  timestamp: number
  type: GovtBusinessActivityType
  amount: number
  description: string
}

export interface GovtBusinessDetail extends GovtBusinessSummary {
  ibanPrimary: string
  directors: GovtBusinessDirector[]
  recentActivity: GovtBusinessActivity[]
  flags: GovtCitizenFlag[]
  payrollMonthly: number
  taxStatus: GovtCitizenTaxStatus
  operatingDays: number
}

export interface GovtBusinessFilters {
  search: string
  status: GovtBusinessStatus | 'all'
  sector: GovtBusinessSector | 'all'
  compliance: GovtTaxCompliance | 'all'
}

/* ============================================================================
   Treasury Movement Ledger — all government-level financial flows.
   ACE P04: sonar.bank.govt.read.
   ============================================================================ */

export type GovtMovementType =
  | 'tax_collection'
  | 'transfer_in'
  | 'transfer_out'
  | 'payroll_disbursement'
  | 'fine_collected'
  | 'subsidy_issued'
  | 'reconciliation'
  | 'interest_accrued'

export type GovtMovementStatus = 'settled' | 'pending' | 'reversed'

export type GovtMovementEntityKind = 'citizen' | 'company' | 'system'

export type GovtTreasuryDateRange = 'today' | 'week' | 'month' | 'quarter'

export interface GovtMovement {
  id: string
  referenceCode: string
  timestamp: number
  type: GovtMovementType
  status: GovtMovementStatus
  entityKind: GovtMovementEntityKind
  entityId: string
  entityLabel: string
  description: string
  amount: number
  direction: 'inflow' | 'outflow'
}

export interface GovtTreasuryStats {
  totalInflow: number
  totalOutflow: number
  netBalance: number
  movementCount: number
  taxCollected: number
  finesCollected: number
  subsidiesIssued: number
}

export interface GovtTreasuryFilters {
  search: string
  type: GovtMovementType | 'all'
  entityKind: GovtMovementEntityKind | 'all'
  dateRange: GovtTreasuryDateRange
  direction: 'inflow' | 'outflow' | 'all'
}

export interface GovtTreasuryPage {
  items: GovtMovement[]
  totalCount: number
  stats: GovtTreasuryStats
}

/* ============================================================================
   Subsidy Programs — state-issued disbursements to citizens and companies.
   ACE P04: sonar.bank.govt.read (read) / P04: sonar.bank.govt.subsidy.write (mutations — stub).
   ============================================================================ */

export type GovtSubsidyType =
  | 'food'
  | 'housing'
  | 'employment'
  | 'medical'
  | 'education'
  | 'emergency'
  | 'agricultural'

export type GovtSubsidyStatus = 'active' | 'paused' | 'completed' | 'proposed'

export type GovtSubsidyRecipientKind = 'citizen' | 'company'

export interface GovtSubsidyProgram {
  programId: string
  code: string
  name: string
  type: GovtSubsidyType
  status: GovtSubsidyStatus
  budget: number
  disbursed: number
  beneficiaryCount: number
  startDate: number
  endDate: number | null
  description: string
}

export interface GovtSubsidyDisbursement {
  id: string
  programCode: string
  recipientId: string
  recipientLabel: string
  recipientKind: GovtSubsidyRecipientKind
  amount: number
  disbursedAt: number
  note: string
  status: 'confirmed' | 'pending' | 'reversed'
}

export interface GovtSubsidyProgramDetail extends GovtSubsidyProgram {
  recentDisbursements: GovtSubsidyDisbursement[]
}

export interface GovtSubsidyFilters {
  search: string
  type: GovtSubsidyType | 'all'
  status: GovtSubsidyStatus | 'all'
}

export interface GovtSubsidyStats {
  totalDisbursed: number
  totalBudget: number
  activeProgramCount: number
  totalBeneficiaries: number
  pendingDisbursements: number
}

/* ============================================================================
   Reports & Analytics — aggregated fiscal executive dashboard.
   ACE P04: sonar.bank.govt.read.
   ============================================================================ */

export type GovtReportsRange = 'month' | 'quarter' | 'year'

export interface GovtRevenueDataPoint {
  label: string
  collected: number
  obligation: number
}

export interface GovtSectorRevenue {
  sector: string
  collected: number
  entityCount: number
}

export interface GovtTopContributor {
  id: string
  label: string
  kind: 'citizen' | 'company'
  taxPaid: number
  bracketCode: string
  compliance: GovtTaxCompliance
}

export interface GovtComplianceBreakdown {
  current: number
  overdue: number
  pending: number
  exempt: number
}

export interface GovtRiskBreakdown {
  low: number
  medium: number
  high: number
  critical: number
}

export interface GovtReportsKpis {
  totalRevenue: number
  totalObligation: number
  complianceRate: number
  activeTaxpayers: number
  revenueVsPriorPct: number
}

export interface GovtReportsData {
  range: GovtReportsRange
  kpis: GovtReportsKpis
  revenueHistory: GovtRevenueDataPoint[]
  sectorRevenue: GovtSectorRevenue[]
  topContributors: GovtTopContributor[]
  complianceBreakdown: GovtComplianceBreakdown
  riskBreakdown: GovtRiskBreakdown
}
