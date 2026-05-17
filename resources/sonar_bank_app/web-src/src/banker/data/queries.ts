import { useQueryClient } from '@tanstack/react-query'
import { useBankCallback, useBankMutation } from '@/lib/bankQuery'
import type {
  BankerBootstrapResponse,
  BankerEmployeesListResponse,
  BankerHireRequest,
  BankerHireResponse,
  BankerFireRequest,
  BankerFireResponse,
  BankerSetRoleRequest,
  BankerSetRoleResponse,
  BankerSetSalaryRequest,
  BankerSetSalaryResponse,
} from './contracts'
import type {
  BankerDashboardResponse,
  BankerOperationsQueuesResponse,
  BankerLoanDecideRequest,
  BankerProAccountDecideRequest,
  BankerKycDecideRequest,
  BankerDecideResponse,
  BankerCustomerSearchResponse,
  BankerCustomerDetailResponse,
  BankerFreezeRequest,
  BankerFreezeResponse,
} from './contractsF2'
import type {
  BankerRatesCatalogResponse,
  BankerRateSetRequest,
  BankerRateResetRequest,
  BankerRateMutationResponse,
} from './contractsF3'
import type {
  BankerBrandingSnapshotResponse,
  BankerBrandingSetRequest,
  BankerBrandingResetRequest,
  BankerBrandingMutationResponse,
} from './contractsF4'
import type {
  BankerComplianceListResponse,
  BankerComplianceResolveRequest,
  BankerComplianceResolveResponse,
} from './contractsF5'
import type {
  BankerMissionsListResponse,
  BankerMissionDispatchRequest,
  BankerMissionMutationRequest,
  BankerMissionMutationResponse,
} from './contractsF6'

export const BANKER_QK = {
  bootstrap: ['banker', 'bootstrap'] as const,
  employees: (status: string, includeFired: boolean) =>
    ['banker', 'employees', status, includeFired] as const,
  dashboard: (windowDays: number) => ['banker', 'dashboard', windowDays] as const,
  queues: (limit: number) => ['banker', 'queues', limit] as const,
  customerSearch: (query: string) => ['banker', 'customers', 'search', query] as const,
  customerDetail: (citizenId: string) => ['banker', 'customers', 'detail', citizenId] as const,
  rates: ['banker', 'rates'] as const,
  branding: ['banker', 'branding'] as const,
  compliance: (status: string, severity: string) =>
    ['banker', 'compliance', status, severity] as const,
  missions: (state: string) => ['banker', 'missions', state] as const,
}

export function useBankerBootstrap() {
  return useBankCallback<BankerBootstrapResponse>(
    'sonar:bank:banker:bootstrap',
    BANKER_QK.bootstrap,
    {},
    { staleTime: 30_000 },
  )
}

export function useBankerEmployees(opts: { status?: string; include_fired?: boolean } = {}) {
  const status = opts.status ?? 'active'
  const includeFired = opts.include_fired ?? false
  return useBankCallback<BankerEmployeesListResponse>(
    'sonar:bank:banker:employees:list',
    BANKER_QK.employees(status, includeFired),
    { status, include_fired: includeFired },
  )
}

export function useBankerHire() {
  const qc = useQueryClient()
  return useBankMutation<BankerHireResponse, BankerHireRequest>('sonar:bank:banker:employees:hire', {
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['banker', 'employees'] })
      qc.invalidateQueries({ queryKey: BANKER_QK.bootstrap })
    },
  })
}

export function useBankerFire() {
  const qc = useQueryClient()
  return useBankMutation<BankerFireResponse, BankerFireRequest>('sonar:bank:banker:employees:fire', {
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['banker', 'employees'] })
      qc.invalidateQueries({ queryKey: BANKER_QK.bootstrap })
    },
  })
}

export function useBankerSetRole() {
  const qc = useQueryClient()
  return useBankMutation<BankerSetRoleResponse, BankerSetRoleRequest>(
    'sonar:bank:banker:employees:setRole',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: ['banker', 'employees'] })
        qc.invalidateQueries({ queryKey: BANKER_QK.bootstrap })
      },
    },
  )
}

export function useBankerSetSalary() {
  const qc = useQueryClient()
  return useBankMutation<BankerSetSalaryResponse, BankerSetSalaryRequest>(
    'sonar:bank:banker:employees:setSalary',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: ['banker', 'employees'] })
      },
    },
  )
}

// ===================== F2 Dashboard =====================

export function useBankerDashboard(windowDays = 14) {
  return useBankCallback<BankerDashboardResponse>(
    'sonar:bank:banker:dashboard:snapshot',
    BANKER_QK.dashboard(windowDays),
    { window_days: windowDays },
    { staleTime: 30_000, refetchInterval: 60_000 },
  )
}

// ===================== F2 Operations =====================

export function useBankerQueues(limit = 25) {
  return useBankCallback<BankerOperationsQueuesResponse>(
    'sonar:bank:banker:operations:queues',
    BANKER_QK.queues(limit),
    { limit },
    { staleTime: 15_000, refetchInterval: 30_000 },
  )
}

function _invalidateOps(qc: ReturnType<typeof useQueryClient>) {
  qc.invalidateQueries({ queryKey: ['banker', 'queues'] })
  qc.invalidateQueries({ queryKey: ['banker', 'dashboard'] })
  qc.invalidateQueries({ queryKey: BANKER_QK.bootstrap })
}

export function useBankerDecideLoan() {
  const qc = useQueryClient()
  return useBankMutation<BankerDecideResponse, BankerLoanDecideRequest>(
    'sonar:bank:banker:operations:loan:decide',
    { onSuccess: () => _invalidateOps(qc) },
  )
}

export function useBankerDecideProAccount() {
  const qc = useQueryClient()
  return useBankMutation<BankerDecideResponse, BankerProAccountDecideRequest>(
    'sonar:bank:banker:operations:proAccount:decide',
    { onSuccess: () => _invalidateOps(qc) },
  )
}

export function useBankerDecideKyc() {
  const qc = useQueryClient()
  return useBankMutation<BankerDecideResponse, BankerKycDecideRequest>(
    'sonar:bank:banker:operations:kyc:decide',
    { onSuccess: () => _invalidateOps(qc) },
  )
}

// ===================== F2 Customers =====================

export function useBankerCustomerSearch(query: string, enabled = true) {
  return useBankCallback<BankerCustomerSearchResponse>(
    'sonar:bank:banker:customers:search',
    BANKER_QK.customerSearch(query),
    { query },
    {
      enabled: enabled && query.length >= 2,
      staleTime: 10_000,
    },
  )
}

export function useBankerCustomerDetail(citizenId: string, enabled = true) {
  return useBankCallback<BankerCustomerDetailResponse>(
    'sonar:bank:banker:customers:detail',
    BANKER_QK.customerDetail(citizenId),
    { citizen_id: citizenId },
    {
      enabled: enabled && citizenId.length > 0,
      staleTime: 5_000,
    },
  )
}

export function useBankerFreezeAccount() {
  const qc = useQueryClient()
  return useBankMutation<BankerFreezeResponse, BankerFreezeRequest>(
    'sonar:bank:banker:customers:freeze',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: ['banker', 'customers'] })
        qc.invalidateQueries({ queryKey: ['banker', 'dashboard'] })
      },
    },
  )
}

export function useBankerUnfreezeAccount() {
  const qc = useQueryClient()
  return useBankMutation<BankerFreezeResponse, BankerFreezeRequest>(
    'sonar:bank:banker:customers:unfreeze',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: ['banker', 'customers'] })
        qc.invalidateQueries({ queryKey: ['banker', 'dashboard'] })
      },
    },
  )
}

// ===================== F3 Rates / Fees / Limits =====================

export function useBankerRatesCatalog() {
  return useBankCallback<BankerRatesCatalogResponse>(
    'sonar:bank:banker:rates:catalog',
    BANKER_QK.rates,
    {},
    { staleTime: 30_000 },
  )
}

export function useBankerSetRate() {
  const qc = useQueryClient()
  return useBankMutation<BankerRateMutationResponse, BankerRateSetRequest>(
    'sonar:bank:banker:rates:set',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: BANKER_QK.rates })
        qc.invalidateQueries({ queryKey: BANKER_QK.bootstrap })
      },
    },
  )
}

export function useBankerResetRate() {
  const qc = useQueryClient()
  return useBankMutation<BankerRateMutationResponse, BankerRateResetRequest>(
    'sonar:bank:banker:rates:reset',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: BANKER_QK.rates })
        qc.invalidateQueries({ queryKey: BANKER_QK.bootstrap })
      },
    },
  )
}

// ===================== F4 Branding =====================

export function useBankerBranding() {
  return useBankCallback<BankerBrandingSnapshotResponse>(
    'sonar:bank:banker:branding:get',
    BANKER_QK.branding,
    {},
    { staleTime: 60_000 },
  )
}

export function useBankerBrandingSet() {
  const qc = useQueryClient()
  return useBankMutation<BankerBrandingMutationResponse, BankerBrandingSetRequest>(
    'sonar:bank:banker:branding:set',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: BANKER_QK.branding })
        qc.invalidateQueries({ queryKey: BANKER_QK.bootstrap })
      },
    },
  )
}

export function useBankerBrandingReset() {
  const qc = useQueryClient()
  return useBankMutation<BankerBrandingMutationResponse, BankerBrandingResetRequest>(
    'sonar:bank:banker:branding:reset',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: BANKER_QK.branding })
        qc.invalidateQueries({ queryKey: BANKER_QK.bootstrap })
      },
    },
  )
}

// ===================== F5 Compliance =====================

export function useBankerComplianceList(status = '', severity = '') {
  return useBankCallback<BankerComplianceListResponse>(
    'sonar:bank:banker:compliance:list',
    BANKER_QK.compliance(status, severity),
    { status, severity, limit: 80 },
    { staleTime: 15_000, refetchInterval: 60_000 },
  )
}

export function useBankerComplianceResolve() {
  const qc = useQueryClient()
  return useBankMutation<BankerComplianceResolveResponse, BankerComplianceResolveRequest>(
    'sonar:bank:banker:compliance:resolve',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: ['banker', 'compliance'] })
      },
    },
  )
}

// ===================== F6 Missions =====================

export function useBankerMissions(state = '') {
  return useBankCallback<BankerMissionsListResponse>(
    'sonar:bank:banker:missions:list',
    BANKER_QK.missions(state),
    { state, limit: 80 },
    { staleTime: 15_000, refetchInterval: 30_000 },
  )
}

export function useBankerMissionDispatch() {
  const qc = useQueryClient()
  return useBankMutation<BankerMissionMutationResponse, BankerMissionDispatchRequest>(
    'sonar:bank:banker:missions:dispatch',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: ['banker', 'missions'] })
      },
    },
  )
}

export function useBankerMissionAssign() {
  const qc = useQueryClient()
  return useBankMutation<BankerMissionMutationResponse, BankerMissionMutationRequest>(
    'sonar:bank:banker:missions:assign',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: ['banker', 'missions'] })
      },
    },
  )
}

export function useBankerMissionComplete() {
  const qc = useQueryClient()
  return useBankMutation<BankerMissionMutationResponse, BankerMissionMutationRequest>(
    'sonar:bank:banker:missions:complete',
    {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: ['banker', 'missions'] })
      },
    },
  )
}
