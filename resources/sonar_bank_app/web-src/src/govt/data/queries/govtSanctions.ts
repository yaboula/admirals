import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type {
  GovtApplyFineRequest,
  GovtCloseFlagRequest,
  GovtFlagQueueFilters,
  GovtFlagQueueItem,
  GovtFreezeAccountsRequest,
  GovtLiftFreezeRequest,
  GovtSanctionAction,
} from '../contracts'
import {
  applyFineMock,
  closeFlagMock,
  freezeAccountsMock,
  getFlagDetailMock,
  getQueueKpisMock,
  isCitizenFrozenMock,
  liftFreezeMock,
  listFlagQueueMock,
  listSanctionActionsMock,
} from '../mock/govtSanctions'
import { govtCensusKeys } from './govtCensus'

/* ============================================================================
   SONAR Treasury Bureau — Sanctions queries + mutations.
   Mock-backed until REQ-FE-009 callbacks ship.
   ============================================================================ */

const SIMULATED_LIST_DELAY_MS = 160
const SIMULATED_DETAIL_DELAY_MS = 180

export const govtSanctionsKeys = {
  all: ['govt', 'sanctions'] as const,
  queue: (filters: GovtFlagQueueFilters) =>
    ['govt', 'sanctions', 'queue', filters.search, filters.severity, filters.status] as const,
  flagDetail: (flagId: string) => ['govt', 'sanctions', 'flag', flagId] as const,
  citizenFrozen: (cid: string) => ['govt', 'sanctions', 'frozen', cid] as const,
  actions: (targetCid?: string) => ['govt', 'sanctions', 'actions', targetCid ?? 'all'] as const,
  kpis: ['govt', 'sanctions', 'kpis'] as const,
}

export function useFlagQueueQuery(filters: GovtFlagQueueFilters) {
  return useQuery<GovtFlagQueueItem[]>({
    queryKey: govtSanctionsKeys.queue(filters),
    queryFn: async () => {
      await new Promise((r) => setTimeout(r, SIMULATED_LIST_DELAY_MS))
      return listFlagQueueMock(filters)
    },
    staleTime: 15_000,
  })
}

export function useFlagDetailQuery(flagId: string | null) {
  return useQuery<GovtFlagQueueItem | null>({
    queryKey: flagId ? govtSanctionsKeys.flagDetail(flagId) : ['govt', 'sanctions', 'flag', 'none'],
    enabled: Boolean(flagId),
    queryFn: async () => {
      if (!flagId) return null
      await new Promise((r) => setTimeout(r, SIMULATED_DETAIL_DELAY_MS))
      return getFlagDetailMock(flagId) ?? null
    },
    staleTime: 15_000,
  })
}

export function useCitizenFrozenQuery(cid: string | null) {
  return useQuery<boolean>({
    queryKey: cid ? govtSanctionsKeys.citizenFrozen(cid) : ['govt', 'sanctions', 'frozen', 'none'],
    enabled: Boolean(cid),
    queryFn: async () => (cid ? isCitizenFrozenMock(cid) : false),
    staleTime: 5_000,
  })
}

export function useSanctionActionsQuery(targetCid?: string | null) {
  return useQuery<GovtSanctionAction[]>({
    queryKey: govtSanctionsKeys.actions(targetCid ?? undefined),
    queryFn: async () => {
      await new Promise((r) => setTimeout(r, 100))
      return listSanctionActionsMock(targetCid ?? undefined)
    },
    staleTime: 10_000,
  })
}

export function useSanctionKpisQuery() {
  return useQuery({
    queryKey: govtSanctionsKeys.kpis,
    queryFn: async () => getQueueKpisMock(),
    staleTime: 8_000,
  })
}

/* ----- mutations ---------------------------------------------------------- */

function useInvalidateSanctions() {
  const qc = useQueryClient()
  return () => {
    qc.invalidateQueries({ queryKey: govtSanctionsKeys.all })
    qc.invalidateQueries({ queryKey: govtCensusKeys.all })
  }
}

export function useCloseFlagMutation() {
  const invalidate = useInvalidateSanctions()
  return useMutation<GovtSanctionAction, Error, GovtCloseFlagRequest>({
    mutationFn: closeFlagMock,
    onSuccess: invalidate,
  })
}

export function useFreezeAccountsMutation() {
  const invalidate = useInvalidateSanctions()
  return useMutation<GovtSanctionAction, Error, GovtFreezeAccountsRequest>({
    mutationFn: freezeAccountsMock,
    onSuccess: invalidate,
  })
}

export function useLiftFreezeMutation() {
  const invalidate = useInvalidateSanctions()
  return useMutation<GovtSanctionAction, Error, GovtLiftFreezeRequest>({
    mutationFn: liftFreezeMock,
    onSuccess: invalidate,
  })
}

export function useApplyFineMutation() {
  const invalidate = useInvalidateSanctions()
  return useMutation<GovtSanctionAction, Error, GovtApplyFineRequest>({
    mutationFn: applyFineMock,
    onSuccess: invalidate,
  })
}
