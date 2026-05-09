import type { GovtBusinessDetail, GovtBusinessFilters, GovtBusinessSummary } from '../contracts'
import { useBankCallback } from '@/lib/bankQuery'

const GOVT_BUSINESS_LIST_EVENT = 'sonar:bank:govt:business:list'
const GOVT_BUSINESS_DETAIL_EVENT = 'sonar:bank:govt:business:detail'

export const govtBusinessKeys = {
  all: ['govt', 'business'] as const,
  list: (filters: GovtBusinessFilters) =>
    ['govt', 'business', 'list', filters.search, filters.status, filters.sector, filters.compliance] as const,
  detail: (companyId: string) => ['govt', 'business', 'detail', companyId] as const,
}

export function useGovtBusinessListQuery(filters: GovtBusinessFilters) {
  return useBankCallback<GovtBusinessSummary[], Record<string, unknown>>(
    GOVT_BUSINESS_LIST_EVENT,
    govtBusinessKeys.list(filters),
    { filters },
    { staleTime: 30_000 },
  )
}

export function useGovtBusinessDetailQuery(companyId: string | null) {
  return useBankCallback<GovtBusinessDetail | null, Record<string, unknown>>(
    GOVT_BUSINESS_DETAIL_EVENT,
    companyId ? govtBusinessKeys.detail(companyId) : ['govt', 'business', 'detail', 'none'],
    { companyId: companyId ?? '' },
    {
      enabled: Boolean(companyId),
      staleTime: 30_000,
    },
  )
}
