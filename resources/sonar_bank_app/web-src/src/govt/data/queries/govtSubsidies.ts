import { useQuery } from '@tanstack/react-query'
import type { GovtSubsidyFilters, GovtSubsidyProgram, GovtSubsidyProgramDetail, GovtSubsidyStats } from '../contracts'
import { getSubsidyDetailMock, getSubsidyStatsMock, listSubsidyProgramsMock } from '../mock/govtSubsidies'

const DELAY_LIST = 130
const DELAY_DETAIL = 180

export const govtSubsidyKeys = {
  stats: ['govt', 'subsidy', 'stats'] as const,
  list: (filters: GovtSubsidyFilters) => ['govt', 'subsidy', 'list', filters.search, filters.type, filters.status] as const,
  detail: (id: string) => ['govt', 'subsidy', 'detail', id] as const,
}

export function useGovtSubsidyStatsQuery() {
  return useQuery<GovtSubsidyStats>({
    queryKey: govtSubsidyKeys.stats,
    queryFn: async () => {
      await new Promise((r) => setTimeout(r, DELAY_LIST))
      return getSubsidyStatsMock()
    },
    staleTime: 60_000,
  })
}

export function useGovtSubsidyListQuery(filters: GovtSubsidyFilters) {
  return useQuery<GovtSubsidyProgram[]>({
    queryKey: govtSubsidyKeys.list(filters),
    queryFn: async () => {
      await new Promise((r) => setTimeout(r, DELAY_LIST))
      return listSubsidyProgramsMock(filters)
    },
    staleTime: 30_000,
  })
}

export function useGovtSubsidyDetailQuery(programId: string | null) {
  return useQuery<GovtSubsidyProgramDetail | null>({
    queryKey: programId ? govtSubsidyKeys.detail(programId) : ['govt', 'subsidy', 'detail', 'none'],
    enabled: Boolean(programId),
    queryFn: async () => {
      if (!programId) return null
      await new Promise((r) => setTimeout(r, DELAY_DETAIL))
      return getSubsidyDetailMock(programId) ?? null
    },
    staleTime: 30_000,
  })
}
