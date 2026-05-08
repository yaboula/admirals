import { useQuery } from '@tanstack/react-query'
import type { GovtCensusFilters, GovtCitizenDetail, GovtCitizenSummary } from '../contracts'
import { getCensusDetailMock, listCensusMock } from '../mock/govtCensus'

/* ============================================================================
   SONAR Treasury Bureau — Census query layer.
   For NODO 2, queries are mock-backed and self-contained inside the govt/
   namespace. When the backend ships, swap the inner promise for an event
   call (useBankCallback) — the public hook signature stays stable.
   ============================================================================ */

const SIMULATED_DELAY_LIST_MS = 180
const SIMULATED_DELAY_DETAIL_MS = 220

export const govtCensusKeys = {
  all: ['govt', 'census'] as const,
  list: (filters: GovtCensusFilters) =>
    ['govt', 'census', 'list', filters.search, filters.status, filters.compliance, filters.riskLevel] as const,
  detail: (cid: string) => ['govt', 'census', 'detail', cid] as const,
}

export function useGovtCensusListQuery(filters: GovtCensusFilters) {
  return useQuery<GovtCitizenSummary[]>({
    queryKey: govtCensusKeys.list(filters),
    queryFn: async () => {
      await new Promise((resolve) => setTimeout(resolve, SIMULATED_DELAY_LIST_MS))
      return listCensusMock(filters)
    },
    staleTime: 30_000,
  })
}

export function useGovtCitizenDetailQuery(cid: string | null) {
  return useQuery<GovtCitizenDetail | null>({
    queryKey: cid ? govtCensusKeys.detail(cid) : ['govt', 'census', 'detail', 'none'],
    enabled: Boolean(cid),
    queryFn: async () => {
      if (!cid) return null
      await new Promise((resolve) => setTimeout(resolve, SIMULATED_DELAY_DETAIL_MS))
      return getCensusDetailMock(cid) ?? null
    },
    staleTime: 30_000,
  })
}
