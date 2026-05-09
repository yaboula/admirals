import type { GovtSubsidyFilters, GovtSubsidyProgram, GovtSubsidyProgramDetail, GovtSubsidyStats } from '../contracts'
import { useBankCallback } from '@/lib/bankQuery'

const SUBSIDY_STATS_EVENT = 'sonar:bank:govt:subsidies:stats'
const SUBSIDY_LIST_EVENT = 'sonar:bank:govt:subsidies:list'
const SUBSIDY_DETAIL_EVENT = 'sonar:bank:govt:subsidies:detail'

export const govtSubsidyKeys = {
  stats: ['govt', 'subsidy', 'stats'] as const,
  list: (filters: GovtSubsidyFilters) => ['govt', 'subsidy', 'list', filters.search, filters.type, filters.status] as const,
  detail: (id: string) => ['govt', 'subsidy', 'detail', id] as const,
}

export function useGovtSubsidyStatsQuery() {
  return useBankCallback<GovtSubsidyStats, Record<string, unknown>>(
    SUBSIDY_STATS_EVENT,
    govtSubsidyKeys.stats,
    {},
    { staleTime: 60_000 },
  )
}

export function useGovtSubsidyListQuery(filters: GovtSubsidyFilters) {
  return useBankCallback<GovtSubsidyProgram[], Record<string, unknown>>(
    SUBSIDY_LIST_EVENT,
    govtSubsidyKeys.list(filters),
    { filters },
    { staleTime: 30_000 },
  )
}

export function useGovtSubsidyDetailQuery(programId: string | null) {
  return useBankCallback<GovtSubsidyProgramDetail | null, Record<string, unknown>>(
    SUBSIDY_DETAIL_EVENT,
    programId ? govtSubsidyKeys.detail(programId) : ['govt', 'subsidy', 'detail', 'none'],
    { programId: programId ?? '' },
    {
      enabled: Boolean(programId),
      staleTime: 30_000,
    },
  )
}
