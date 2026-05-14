import { registerMockHandler } from '@/lib/nui'
import {
  buildMockAuditQuery,
  buildMockAtmSession,
  buildMockBootstrap,
  buildMockBusinessTreasury,
  buildMockClientConfig,
  buildMockComplianceFlagsQuery,
  buildMockLoanInstallments,
  buildMockLoanList,
  buildMockPayrollPreview,
  buildMockRecentRecipientsResponse,
  buildMockStockList,
  buildMockStockPortfolio,
  simulateLatency,
} from './seed'
import type { AuditQueryRequest, AuditQueryResponse, AtmSessionResponse, BootstrapSnapshot, BusinessTreasuryQueryRequest, BusinessTreasurySnapshot, ClientConfigSnapshot, ComplianceFlagsQueryRequest, ComplianceFlagsQueryResponse, LoanInstallmentsRequest, LoanInstallmentsResponse, LoanListResponse, LoanPaymentResponse, LoanRequestResponse, PayrollPreviewRequest, PayrollPreviewResponse, RecentRecipientsResponse, StockListResponse, StockPortfolioResponse } from '@/data/contracts'
import type { BusinessApprovalDecideRequest, BusinessApprovalDecideResponse, BusinessPayrollExecuteRequest, BusinessPayrollExecuteResponse, BusinessWithdrawalRequest, BusinessWithdrawalResponse } from '@/data/contracts'
import type { IssueCardResult } from '@/data/mutations'
import type { BankStateBagKey } from '@/lib/bankStateBags'
import { getBusinessDetailMock, listBusinessMock } from '@/govt/data/mock/govtBusiness'
import { getCensusDetailMock, listCensusMock } from '@/govt/data/mock/govtCensus'
import { getReportsDataMock } from '@/govt/data/mock/govtReports'
import { forceCollectionMock, getBracketsMock, getCycleStatsMock, getPolicyLogMock, saveBracketsMock } from '@/govt/data/mock/govtTax'
import {
  applyFineMock,
  closeFlagMock,
  freezeAccountsMock,
  getFlagDetailMock,
  getQueueKpisMock,
  isCitizenFrozenMock,
  liftFreezeMock,
  listFlagQueueMock,
  listSanctionActionsMock,
} from '@/govt/data/mock/govtSanctions'
import { getSubsidyDetailMock, getSubsidyStatsMock, grantSubsidyMock, listSubsidyProgramsMock } from '@/govt/data/mock/govtSubsidies'
import { getTreasuryPageMock } from '@/govt/data/mock/govtTreasury'
import type {
  GovtApplyFineRequest,
  GovtBusinessDetail,
  GovtBusinessFilters,
  GovtBusinessSummary,
  GovtCensusFilters,
  GovtCitizenDetail,
  GovtCitizenSummary,
  GovtCloseFlagRequest,
  GovtFlagQueueFilters,
  GovtFlagQueueItem,
  GovtFreezeAccountsRequest,
  GovtLiftFreezeRequest,
  GovtReportsData,
  GovtReportsRange,
  GovtSanctionAction,
  GovtForceCollectionRequest,
  GovtGrantSubsidyRequest,
  GovtSaveBracketsRequest,
  GovtSubsidyDisbursement,
  GovtSubsidyFilters,
  GovtSubsidyProgram,
  GovtSubsidyProgramDetail,
  GovtSubsidyStats,
  GovtTaxBracket,
  GovtTaxCycleStats,
  GovtTaxPolicyChange,
  GovtTreasuryFilters,
  GovtTreasuryPage,
} from '@/govt/data/contracts'

let installed = false

export function installMockHandlers(): void {
  if (installed) return
  installed = true

  registerMockHandler<BootstrapSnapshot>('sonar:bank:bootstrap:snapshot', async () => {
    await simulateLatency(140, 360)
    return buildMockBootstrap()
  })

  registerMockHandler<RecentRecipientsResponse>('sonar:bank:transfer:recentRecipients', async () => {
    await simulateLatency(60, 180)
    return buildMockRecentRecipientsResponse()
  })

  registerMockHandler<ClientConfigSnapshot>('sonar:bank:nui:getConfig', async () => {
    await simulateLatency(40, 120)
    return buildMockClientConfig()
  })

  registerMockHandler<AuditQueryResponse>('sonar:bank:audit:query', async (payload) => {
    await simulateLatency(90, 220)
    return buildMockAuditQuery(payload as unknown as AuditQueryRequest)
  })

  registerMockHandler<ComplianceFlagsQueryResponse>('sonar:bank:compliance:flags', async (payload) => {
    await simulateLatency(110, 260)
    return buildMockComplianceFlagsQuery(payload as unknown as ComplianceFlagsQueryRequest)
  })

  registerMockHandler<BusinessTreasurySnapshot>('sonar:bank:business:treasury', async (payload) => {
    await simulateLatency(90, 220)
    return buildMockBusinessTreasury(payload as unknown as BusinessTreasuryQueryRequest)
  })

  registerMockHandler<PayrollPreviewResponse>('sonar:bank:business:payroll:preview', async (payload) => {
    await simulateLatency(80, 180)
    return buildMockPayrollPreview(payload as unknown as PayrollPreviewRequest)
  })

  registerMockHandler<BusinessPayrollExecuteResponse>('sonar:bank:business:payroll:execute', async (payload) => {
    await simulateLatency(120, 260)
    const request = payload as unknown as BusinessPayrollExecuteRequest
    const now = Date.now()
    return {
      company_id: request.company_id,
      batch_id: `mock-payroll-${now}`,
      approval_id: `mock-approval-${now}`,
      status: 'pending_approval',
      total_net_minor: 1_240_000,
      employee_count: 12,
      requires_approvals: 2,
      cross_ref_audit_id: `mock-audit-${now}`,
      committed_at_ms: now,
    }
  })

  registerMockHandler<BusinessWithdrawalResponse>('sonar:bank:business:withdrawal:request', async (payload) => {
    await simulateLatency(120, 260)
    const request = payload as unknown as BusinessWithdrawalRequest
    const now = Date.now()
    return {
      company_id: request.company_id,
      approval_id: `mock-withdrawal-${now}`,
      status: 'pending',
      amount_minor: request.amount_minor,
      requires_approvals: 2,
      cross_ref_audit_id: `mock-audit-${now}`,
      committed_at_ms: now,
    }
  })

  registerMockHandler<BusinessApprovalDecideResponse>('sonar:bank:business:approval:decide', async (payload) => {
    await simulateLatency(120, 260)
    const request = payload as unknown as BusinessApprovalDecideRequest
    const now = Date.now()
    return {
      company_id: 'vanilla-unicorn',
      approval_id: request.approval_id,
      batch_id: `mock-batch-${request.approval_id}`,
      status: request.decision === 'approve' ? 'executed' : 'cancelled',
      signers_approved: request.decision === 'approve' ? 2 : 1,
      signers_required: 2,
      paid_total_minor: request.decision === 'approve' ? 1_240_000 : 0,
      cross_ref_audit_id: `mock-audit-${now}`,
      committed_at_ms: now,
    }
  })

  registerMockHandler<StockListResponse>('sonar:bank:stocks:list', async () => {
    await simulateLatency(80, 180)
    return buildMockStockList()
  })

  registerMockHandler<StockPortfolioResponse>('sonar:bank:stocks:portfolio', async () => {
    await simulateLatency(90, 210)
    return buildMockStockPortfolio()
  })

  registerMockHandler<{ asset: string; units: number; price_minor: number; total_cost: number }>('sonar:bank:portfolio:buy', async (payload) => {
    await simulateLatency(120, 260)
    const request = payload as unknown as { asset_symbol: string; units: number }
    return { asset: request.asset_symbol, units: request.units, price_minor: 250_00, total_cost: Math.max(1, Math.floor(request.units * 250_00)) }
  })

  registerMockHandler<{ asset: string; units: number; proceeds: number }>('sonar:bank:portfolio:sell', async (payload) => {
    await simulateLatency(120, 260)
    const request = payload as unknown as { asset_symbol: string; units: number }
    return { asset: request.asset_symbol, units: request.units, proceeds: Math.max(1, Math.floor(request.units * 250_00)) }
  })

  registerMockHandler<LoanListResponse>('sonar:bank:loans:list', async () => {
    await simulateLatency(80, 180)
    return buildMockLoanList()
  })

  registerMockHandler<LoanInstallmentsResponse>('sonar:bank:loans:installments', async (payload) => {
    await simulateLatency(80, 190)
    return buildMockLoanInstallments(payload as unknown as LoanInstallmentsRequest)
  })

  registerMockHandler<LoanRequestResponse>('sonar:bank:loan:request', async () => {
    await simulateLatency(140, 260)
    return {
      loan_id: `mock-loan-${Date.now()}`,
      status: 'requested',
    }
  })

  registerMockHandler<LoanPaymentResponse>('sonar:bank:loan:makePayment', async (payload) => {
    await simulateLatency(140, 260)
    const request = payload as unknown as { loan_id: string; amount_minor: number }
    return {
      loan_id: request.loan_id,
      amount_minor: request.amount_minor,
      payment_ms: Date.now(),
      paid_off: false,
    }
  })

  registerMockHandler<{ recurring_id: string; next_charge_ms: number }>('sonar:bank:recurring:subscribe', async (payload) => {
    await simulateLatency(120, 260)
    const request = payload as unknown as { interval_days: number; first_charge_ms?: number }
    return {
      recurring_id: `mock-recurring-${Date.now()}`,
      next_charge_ms: request.first_charge_ms ?? Date.now() + Math.max(1, request.interval_days) * 24 * 60 * 60 * 1000,
    }
  })

  registerMockHandler<{ recurring_id: string; status: 'cancelled' }>('sonar:bank:recurring:cancel', async (payload) => {
    await simulateLatency(100, 220)
    return { recurring_id: String(payload.recurring_id ?? ''), status: 'cancelled' }
  })

  registerMockHandler<{ recurring_id: string; status: 'paused' }>('sonar:bank:recurring:pause', async (payload) => {
    await simulateLatency(100, 220)
    return { recurring_id: String(payload.recurring_id ?? ''), status: 'paused' }
  })

  registerMockHandler<{ recurring_id: string; status: 'active' }>('sonar:bank:recurring:resume', async (payload) => {
    await simulateLatency(100, 220)
    return { recurring_id: String(payload.recurring_id ?? ''), status: 'active' }
  })
  registerMockHandler<AtmSessionResponse>('sonar:bank:atm:session', async () => {
    await simulateLatency(70, 160)
    return buildMockAtmSession()
  })

  registerMockHandler<{ key: BankStateBagKey; value: unknown; fetched_at_ms: number }>('sonar:bank:statebag:get', async (payload) => {
    await simulateLatency(30, 90)
    return {
      key: payload.key as BankStateBagKey,
      value: resolveMockStateBag(payload.key as BankStateBagKey),
      fetched_at_ms: Date.now(),
    }
  })

  registerMockHandler<GovtCitizenSummary[]>('sonar:bank:govt:census:list', async (payload) => {
    await simulateLatency(120, 240)
    return listCensusMock((payload.filters ?? payload) as GovtCensusFilters)
  })

  registerMockHandler<GovtCitizenDetail | null>('sonar:bank:govt:census:detail', async (payload) => {
    await simulateLatency(120, 260)
    return getCensusDetailMock(String(payload.cid ?? '')) ?? null
  })

  registerMockHandler<GovtFlagQueueItem[]>('sonar:bank:govt:sanctions:queue', async (payload) => {
    await simulateLatency(100, 220)
    return listFlagQueueMock((payload.filters ?? payload) as GovtFlagQueueFilters)
  })

  registerMockHandler<GovtFlagQueueItem | null>('sonar:bank:govt:sanctions:flagDetail', async (payload) => {
    await simulateLatency(100, 220)
    return getFlagDetailMock(String(payload.flagId ?? payload.flag_id ?? '')) ?? null
  })

  registerMockHandler<boolean>('sonar:bank:govt:sanctions:frozen', async (payload) => {
    await simulateLatency(60, 140)
    return isCitizenFrozenMock(String(payload.cid ?? payload.targetCid ?? ''))
  })

  registerMockHandler<GovtSanctionAction[]>('sonar:bank:govt:sanctions:actions', async (payload) => {
    await simulateLatency(80, 180)
    return listSanctionActionsMock(payload.targetCid ? String(payload.targetCid) : undefined)
  })

  registerMockHandler<ReturnType<typeof getQueueKpisMock>>('sonar:bank:govt:sanctions:kpis', async () => {
    await simulateLatency(60, 140)
    return getQueueKpisMock()
  })

  registerMockHandler<GovtSanctionAction>('sonar:bank:govt:sanctions:closeFlag', async (payload) => {
    return closeFlagMock(payload as unknown as GovtCloseFlagRequest)
  })

  registerMockHandler<GovtSanctionAction>('sonar:bank:govt:sanctions:freezeAccounts', async (payload) => {
    return freezeAccountsMock(payload as unknown as GovtFreezeAccountsRequest)
  })

  registerMockHandler<GovtSanctionAction>('sonar:bank:govt:sanctions:liftFreeze', async (payload) => {
    return liftFreezeMock(payload as unknown as GovtLiftFreezeRequest)
  })

  registerMockHandler<GovtSanctionAction>('sonar:bank:govt:sanctions:applyFine', async (payload) => {
    return applyFineMock(payload as unknown as GovtApplyFineRequest)
  })

  registerMockHandler<GovtTreasuryPage>('sonar:bank:govt:treasury:page', async (payload) => {
    await simulateLatency(100, 220)
    return getTreasuryPageMock((payload.filters ?? {}) as GovtTreasuryFilters, Number(payload.page ?? 1), Number(payload.perPage ?? payload.per_page ?? 15))
  })

  registerMockHandler<GovtSubsidyStats>('sonar:bank:govt:subsidies:stats', async () => {
    await simulateLatency(90, 180)
    return getSubsidyStatsMock()
  })

  registerMockHandler<GovtSubsidyProgram[]>('sonar:bank:govt:subsidies:list', async (payload) => {
    await simulateLatency(90, 180)
    return listSubsidyProgramsMock((payload.filters ?? payload) as GovtSubsidyFilters)
  })

  registerMockHandler<GovtSubsidyProgramDetail | null>('sonar:bank:govt:subsidies:detail', async (payload) => {
    await simulateLatency(100, 220)
    return getSubsidyDetailMock(String(payload.programId ?? payload.program_id ?? '')) ?? null
  })

  registerMockHandler<GovtSubsidyDisbursement>('sonar:bank:govt:subsidies:grant', async (payload) => {
    return grantSubsidyMock(payload as unknown as GovtGrantSubsidyRequest)
  })

  registerMockHandler<GovtReportsData>('sonar:bank:govt:reports:data', async (payload) => {
    await simulateLatency(120, 240)
    return getReportsDataMock((payload.range ?? 'month') as GovtReportsRange)
  })

  registerMockHandler<GovtBusinessSummary[]>('sonar:bank:govt:business:list', async (payload) => {
    await simulateLatency(120, 240)
    return listBusinessMock((payload.filters ?? payload) as GovtBusinessFilters)
  })

  registerMockHandler<GovtBusinessDetail | null>('sonar:bank:govt:business:detail', async (payload) => {
    await simulateLatency(120, 260)
    return getBusinessDetailMock(String(payload.companyId ?? payload.company_id ?? '')) ?? null
  })

  registerMockHandler<GovtTaxBracket[]>('sonar:bank:govt:tax:brackets:get', async () => {
    await simulateLatency(90, 180)
    return getBracketsMock()
  })

  registerMockHandler<GovtTaxCycleStats>('sonar:bank:govt:tax:cycle:stats', async () => {
    await simulateLatency(90, 180)
    return getCycleStatsMock()
  })

  registerMockHandler<GovtTaxPolicyChange[]>('sonar:bank:govt:tax:policy:log', async () => {
    await simulateLatency(80, 160)
    return getPolicyLogMock()
  })

  registerMockHandler<void>('sonar:bank:govt:tax:brackets:save', async (payload) => {
    await saveBracketsMock(payload as unknown as GovtSaveBracketsRequest)
  })

  registerMockHandler<void>('sonar:bank:govt:tax:force_collection', async (payload) => {
    await forceCollectionMock(payload as unknown as GovtForceCollectionRequest)
  })

  registerMockHandler<IssueCardResult>('sonar:bank:card:issue', async (_payload) => {
    await simulateLatency(200, 420)
    const last4 = String(Math.floor(Math.random() * 9000) + 1000)
    const card_type = _payload.card_type ?? 'debit'
    return {
      card_id: `mock-card-${Date.now()}`,
      masked_number: `**** **** **** ${last4}`,
      card_type: card_type as 'debit' | 'virtual',
    }
  })

  console.info('[mock] handlers installed (49 endpoints) - VITE_MOCK_MODE=true')
}

function resolveMockStateBag(key: BankStateBagKey): unknown {
  if (key === 'bank.bridges.status') return 'native_full'
  if (key === 'bank.tax.brackets') return []
  if (key === 'bank.elections.state') return { phase: 'inactive', next_phase_at: null }
  if (key === 'bank.global.health') return { all_systems_operational: true }
  if (key.startsWith('bank.compliance.')) return { count: 0, has_active: false }
  if (key.startsWith('bank.subsidy.public.')) return { count_active: 0 }
  if (key.startsWith('bank.business_treasury.')) return { balance_minor: 0, last_update_ms: Date.now() }
  return null
}
