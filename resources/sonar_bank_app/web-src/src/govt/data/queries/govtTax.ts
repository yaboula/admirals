import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type { GovtForceCollectionRequest, GovtSaveBracketsRequest } from '../contracts'
import {
  forceCollectionMock,
  getBracketsMock,
  getCycleStatsMock,
  getPolicyLogMock,
  saveBracketsMock,
} from '../mock/govtTax'

export const govtTaxKeys = {
  all: ['govt', 'tax'] as const,
  brackets: ['govt', 'tax', 'brackets'] as const,
  cycle: ['govt', 'tax', 'cycle'] as const,
  policyLog: ['govt', 'tax', 'policyLog'] as const,
}

export function useTaxBracketsQuery() {
  return useQuery({
    queryKey: govtTaxKeys.brackets,
    queryFn: async () => {
      await new Promise((r) => setTimeout(r, 120))
      return getBracketsMock()
    },
    staleTime: 30_000,
  })
}

export function useTaxCycleQuery() {
  return useQuery({
    queryKey: govtTaxKeys.cycle,
    queryFn: async () => {
      await new Promise((r) => setTimeout(r, 140))
      return getCycleStatsMock()
    },
    staleTime: 15_000,
  })
}

export function usePolicyLogQuery() {
  return useQuery({
    queryKey: govtTaxKeys.policyLog,
    queryFn: async () => {
      await new Promise((r) => setTimeout(r, 100))
      return getPolicyLogMock()
    },
    staleTime: 20_000,
  })
}

export function useSaveBracketsMutation() {
  const qc = useQueryClient()
  return useMutation<void, Error, GovtSaveBracketsRequest>({
    mutationFn: saveBracketsMock,
    onSuccess: () => qc.invalidateQueries({ queryKey: govtTaxKeys.all }),
  })
}

export function useForceCollectionMutation() {
  const qc = useQueryClient()
  return useMutation<void, Error, GovtForceCollectionRequest>({
    mutationFn: forceCollectionMock,
    onSuccess: () => qc.invalidateQueries({ queryKey: govtTaxKeys.all }),
  })
}
