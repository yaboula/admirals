import type { GovtTreasuryFilters, GovtTreasuryPage } from '../contracts'
import { useBankCallback } from '@/lib/bankQuery'

const TREASURY_PAGE_EVENT = 'sonar:bank:govt:treasury:page'
export const PER_PAGE = 15

export const govtTreasuryKeys = {
  all: ['govt', 'treasury'] as const,
  page: (filters: GovtTreasuryFilters, page: number) =>
    ['govt', 'treasury', 'page', filters.search, filters.type, filters.entityKind, filters.dateRange, filters.direction, page] as const,
}

export function useGovtTreasuryQuery(filters: GovtTreasuryFilters, page: number) {
  return useBankCallback<GovtTreasuryPage, Record<string, unknown>>(
    TREASURY_PAGE_EVENT,
    govtTreasuryKeys.page(filters, page),
    { filters, page, perPage: PER_PAGE },
    {
      staleTime: 30_000,
      placeholderData: (prev) => prev,
    },
  )
}
