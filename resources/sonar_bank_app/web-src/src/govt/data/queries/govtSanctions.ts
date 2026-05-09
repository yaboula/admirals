import { useQueryClient } from '@tanstack/react-query'
import type {
  GovtApplyFineRequest,
  GovtCloseFlagRequest,
  GovtFlagQueueFilters,
  GovtFlagQueueItem,
  GovtFreezeAccountsRequest,
  GovtLiftFreezeRequest,
  GovtSanctionAction,
} from '../contracts'
import { useBankCallback, useBankMutation } from '@/lib/bankQuery'
import { govtCensusKeys } from './govtCensus'

/* ============================================================================
   SONAR Treasury Bureau — Sanctions queries + mutations.
   Mock-backed until REQ-FE-009 callbacks ship.
   ============================================================================ */

const FLAG_QUEUE_EVENT = 'sonar:bank:govt:sanctions:queue'
const FLAG_DETAIL_EVENT = 'sonar:bank:govt:sanctions:flagDetail'
const CITIZEN_FROZEN_EVENT = 'sonar:bank:govt:sanctions:frozen'
const SANCTION_ACTIONS_EVENT = 'sonar:bank:govt:sanctions:actions'
const SANCTION_KPIS_EVENT = 'sonar:bank:govt:sanctions:kpis'
const CLOSE_FLAG_EVENT = 'sonar:bank:govt:sanctions:closeFlag'
const FREEZE_ACCOUNTS_EVENT = 'sonar:bank:govt:sanctions:freezeAccounts'
const LIFT_FREEZE_EVENT = 'sonar:bank:govt:sanctions:liftFreeze'
const APPLY_FINE_EVENT = 'sonar:bank:govt:sanctions:applyFine'

export interface GovtSanctionKpis {
  open: number
  critical: number
  today: number
  total: number
}

type CloseFlagPayload = GovtCloseFlagRequest & Record<string, unknown>
type FreezeAccountsPayload = GovtFreezeAccountsRequest & Record<string, unknown>
type LiftFreezePayload = GovtLiftFreezeRequest & Record<string, unknown>
type ApplyFinePayload = GovtApplyFineRequest & Record<string, unknown>

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
  return useBankCallback<GovtFlagQueueItem[], Record<string, unknown>>(
    FLAG_QUEUE_EVENT,
    govtSanctionsKeys.queue(filters),
    { filters },
    { staleTime: 15_000 },
  )
}

export function useFlagDetailQuery(flagId: string | null) {
  return useBankCallback<GovtFlagQueueItem | null, Record<string, unknown>>(
    FLAG_DETAIL_EVENT,
    flagId ? govtSanctionsKeys.flagDetail(flagId) : ['govt', 'sanctions', 'flag', 'none'],
    { flagId: flagId ?? '' },
    {
      enabled: Boolean(flagId),
      staleTime: 15_000,
    },
  )
}

export function useCitizenFrozenQuery(cid: string | null) {
  return useBankCallback<boolean, Record<string, unknown>>(
    CITIZEN_FROZEN_EVENT,
    cid ? govtSanctionsKeys.citizenFrozen(cid) : ['govt', 'sanctions', 'frozen', 'none'],
    { cid: cid ?? '' },
    {
      enabled: Boolean(cid),
      staleTime: 5_000,
    },
  )
}

export function useSanctionActionsQuery(targetCid?: string | null) {
  return useBankCallback<GovtSanctionAction[], Record<string, unknown>>(
    SANCTION_ACTIONS_EVENT,
    govtSanctionsKeys.actions(targetCid ?? undefined),
    { targetCid: targetCid ?? '' },
    { staleTime: 10_000 },
  )
}

export function useSanctionKpisQuery() {
  return useBankCallback<GovtSanctionKpis, Record<string, unknown>>(
    SANCTION_KPIS_EVENT,
    govtSanctionsKeys.kpis,
    {},
    { staleTime: 8_000 },
  )
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
  return useBankMutation<GovtSanctionAction, CloseFlagPayload>(CLOSE_FLAG_EVENT, { onSuccess: invalidate })
}

export function useFreezeAccountsMutation() {
  const invalidate = useInvalidateSanctions()
  return useBankMutation<GovtSanctionAction, FreezeAccountsPayload>(FREEZE_ACCOUNTS_EVENT, { onSuccess: invalidate })
}

export function useLiftFreezeMutation() {
  const invalidate = useInvalidateSanctions()
  return useBankMutation<GovtSanctionAction, LiftFreezePayload>(LIFT_FREEZE_EVENT, { onSuccess: invalidate })
}

export function useApplyFineMutation() {
  const invalidate = useInvalidateSanctions()
  return useBankMutation<GovtSanctionAction, ApplyFinePayload>(APPLY_FINE_EVENT, { onSuccess: invalidate })
}
