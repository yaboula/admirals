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
import type { AuditQueryRequest, AuditQueryResponse, AtmSessionResponse, BootstrapSnapshot, BusinessTreasuryQueryRequest, BusinessTreasurySnapshot, ClientConfigSnapshot, ComplianceFlagsQueryRequest, ComplianceFlagsQueryResponse, LoanInstallmentsRequest, LoanInstallmentsResponse, LoanListResponse, PayrollPreviewRequest, PayrollPreviewResponse, RecentRecipientsResponse, StockListResponse, StockPortfolioResponse } from '@/data/contracts'
import type { BankStateBagKey } from '@/lib/bankStateBags'

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

  registerMockHandler<StockListResponse>('sonar:bank:stocks:list', async () => {
    await simulateLatency(80, 180)
    return buildMockStockList()
  })

  registerMockHandler<StockPortfolioResponse>('sonar:bank:stocks:portfolio', async () => {
    await simulateLatency(90, 210)
    return buildMockStockPortfolio()
  })

  registerMockHandler<LoanListResponse>('sonar:bank:loans:list', async () => {
    await simulateLatency(80, 180)
    return buildMockLoanList()
  })

  registerMockHandler<LoanInstallmentsResponse>('sonar:bank:loans:installments', async (payload) => {
    await simulateLatency(80, 190)
    return buildMockLoanInstallments(payload as unknown as LoanInstallmentsRequest)
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

  console.info('[mock] handlers installed (13 endpoints) — VITE_MOCK_MODE=true')
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
