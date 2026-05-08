import { useQuery } from '@tanstack/react-query'
import type { GovtBusinessDetail, GovtBusinessFilters, GovtBusinessSummary } from '../contracts'
import { getBusinessDetailMock, listBusinessMock } from '../mock/govtBusiness'

const SIMULATED_DELAY_LIST_MS = 160
const SIMULATED_DELAY_DETAIL_MS = 200

export const govtBusinessKeys = {
  all: ['govt', 'business'] as const,
  list: (filters: GovtBusinessFilters) =>
    ['govt', 'business', 'list', filters.search, filters.status, filters.sector, filters.compliance] as const,
  detail: (companyId: string) => ['govt', 'business', 'detail', companyId] as const,
}

export function useGovtBusinessListQuery(filters: GovtBusinessFilters) {
  return useQuery<GovtBusinessSummary[]>({
    queryKey: govtBusinessKeys.list(filters),
    queryFn: async () => {
      await new Promise((resolve) => setTimeout(resolve, SIMULATED_DELAY_LIST_MS))
      return listBusinessMock(filters)
    },
    staleTime: 30_000,
  })
}

export function useGovtBusinessDetailQuery(companyId: string | null) {
  return useQuery<GovtBusinessDetail | null>({
    queryKey: companyId ? govtBusinessKeys.detail(companyId) : ['govt', 'business', 'detail', 'none'],
    enabled: Boolean(companyId),
    queryFn: async () => {
      if (!companyId) return null
      await new Promise((resolve) => setTimeout(resolve, SIMULATED_DELAY_DETAIL_MS))
      return getBusinessDetailMock(companyId) ?? null
    },
    staleTime: 30_000,
  })
}
