import type { UseQueryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import type { ClientConfigSnapshot } from '@/data/contracts'
import { BankError } from '@/lib/bankError'
import { useBankCallback } from '@/lib/bankQuery'

const CONFIG_EVENT = 'sonar:bank:nui:getConfig'

export type ClientConfigOptions = Omit<
  UseQueryOptions<ClientConfigSnapshot, BankError>,
  'queryKey' | 'queryFn'
>

export function useClientConfig(options: ClientConfigOptions = {}) {
  return useBankCallback<ClientConfigSnapshot>(
    CONFIG_EVENT,
    queryKeys.config(),
    {},
    {
      staleTime: 5 * 60_000,
      gcTime: 30 * 60_000,
      retry: 1,
      ...options,
    },
  )
}
