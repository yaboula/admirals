import type { UseQueryOptions } from '@tanstack/react-query'
import type { AtmSessionResponse } from '@/data/contracts'
import { useBankCallback } from '@/lib/bankQuery'
import { queryKeys } from '@/data/queryKeys'
import { BankError } from '@/lib/bankError'

const ATM_SESSION_EVENT = 'sonar:bank:atm:session'

export type AtmSessionQueryOptions = Omit<
  UseQueryOptions<AtmSessionResponse, BankError>,
  'queryKey' | 'queryFn'
>

export function useAtmSessionQuery(options: AtmSessionQueryOptions = {}) {
  return useBankCallback<AtmSessionResponse, Record<string, unknown>>(
    ATM_SESSION_EVENT,
    queryKeys.atm.session(),
    {},
    {
      staleTime: 15_000,
      gcTime: 2 * 60_000,
      ...options,
    },
  )
}
