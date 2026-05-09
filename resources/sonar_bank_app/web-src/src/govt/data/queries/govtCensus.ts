import type { GovtCensusFilters, GovtCitizenDetail, GovtCitizenSummary } from '../contracts'
import { useBankCallback } from '@/lib/bankQuery'

/* ============================================================================
   SONAR Treasury Bureau — Census query layer.
   For NODO 2, queries are mock-backed and self-contained inside the govt/
   namespace. When the backend ships, swap the inner promise for an event
   call (useBankCallback) — the public hook signature stays stable.
   ============================================================================ */

const CENSUS_LIST_EVENT = 'sonar:bank:govt:census:list'
const CENSUS_DETAIL_EVENT = 'sonar:bank:govt:census:detail'

export const govtCensusKeys = {
  all: ['govt', 'census'] as const,
  list: (filters: GovtCensusFilters) =>
    ['govt', 'census', 'list', filters.search, filters.status, filters.compliance, filters.riskLevel] as const,
  detail: (cid: string) => ['govt', 'census', 'detail', cid] as const,
}

export function useGovtCensusListQuery(filters: GovtCensusFilters) {
  return useBankCallback<GovtCitizenSummary[], Record<string, unknown>>(
    CENSUS_LIST_EVENT,
    govtCensusKeys.list(filters),
    { filters },
    { staleTime: 30_000 },
  )
}

export function useGovtCitizenDetailQuery(cid: string | null) {
  return useBankCallback<GovtCitizenDetail | null, Record<string, unknown>>(
    CENSUS_DETAIL_EVENT,
    cid ? govtCensusKeys.detail(cid) : ['govt', 'census', 'detail', 'none'],
    { cid: cid ?? '' },
    {
      enabled: Boolean(cid),
      staleTime: 30_000,
    },
  )
}
