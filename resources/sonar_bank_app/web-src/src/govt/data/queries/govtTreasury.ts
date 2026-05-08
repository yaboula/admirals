import { useQuery } from '@tanstack/react-query'
import type { GovtTreasuryFilters, GovtTreasuryPage } from '../contracts'
import { getTreasuryPageMock } from '../mock/govtTreasury'

const SIMULATED_DELAY_MS = 140
export const PER_PAGE = 15

export const govtTreasuryKeys = {
  all: ['govt', 'treasury'] as const,
  page: (filters: GovtTreasuryFilters, page: number) =>
    ['govt', 'treasury', 'page', filters.search, filters.type, filters.entityKind, filters.dateRange, filters.direction, page] as const,
}

export function useGovtTreasuryQuery(filters: GovtTreasuryFilters, page: number) {
  return useQuery<GovtTreasuryPage>({
    queryKey: govtTreasuryKeys.page(filters, page),
    queryFn: async () => {
      await new Promise((resolve) => setTimeout(resolve, SIMULATED_DELAY_MS))
      return getTreasuryPageMock(filters, page, PER_PAGE)
    },
    staleTime: 30_000,
    placeholderData: (prev) => prev,
  })
}
