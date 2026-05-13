import { useQueryClient } from '@tanstack/react-query'
import type { GovtForceCollectionRequest, GovtSaveBracketsRequest, GovtTaxBracket, GovtTaxCycleStats, GovtTaxPolicyChange } from '../contracts'
import { useBankCallback, useBankMutation } from '@/lib/bankQuery'

const TAX_BRACKETS_EVENT = 'sonar:bank:govt:tax:brackets:get'
const TAX_CYCLE_EVENT = 'sonar:bank:govt:tax:cycle:stats'
const TAX_POLICY_EVENT = 'sonar:bank:govt:tax:policy:log'
const TAX_SAVE_EVENT = 'sonar:bank:govt:tax:brackets:save'
const TAX_FORCE_EVENT = 'sonar:bank:govt:tax:force_collection'

export const govtTaxKeys = {
  all: ['govt', 'tax'] as const,
  brackets: ['govt', 'tax', 'brackets'] as const,
  cycle: ['govt', 'tax', 'cycle'] as const,
  policyLog: ['govt', 'tax', 'policyLog'] as const,
}

export function useTaxBracketsQuery() {
  return useBankCallback<GovtTaxBracket[], Record<string, unknown>>(
    TAX_BRACKETS_EVENT,
    govtTaxKeys.brackets,
    {},
    { staleTime: 30_000 },
  )
}

export function useTaxCycleQuery() {
  return useBankCallback<GovtTaxCycleStats, Record<string, unknown>>(
    TAX_CYCLE_EVENT,
    govtTaxKeys.cycle,
    {},
    { staleTime: 15_000 },
  )
}

export function usePolicyLogQuery() {
  return useBankCallback<GovtTaxPolicyChange[], Record<string, unknown>>(
    TAX_POLICY_EVENT,
    govtTaxKeys.policyLog,
    {},
    { staleTime: 20_000 },
  )
}

export function useSaveBracketsMutation() {
  const qc = useQueryClient()
  return useBankMutation<void, GovtSaveBracketsRequest & Record<string, unknown>>(
    TAX_SAVE_EVENT,
    { onSuccess: () => qc.invalidateQueries({ queryKey: govtTaxKeys.all }) },
  )
}

export function useForceCollectionMutation() {
  const qc = useQueryClient()
  return useBankMutation<void, GovtForceCollectionRequest & Record<string, unknown>>(
    TAX_FORCE_EVENT,
    { onSuccess: () => qc.invalidateQueries({ queryKey: govtTaxKeys.all }) },
  )
}
