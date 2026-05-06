import { useQuery, type UseQueryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import { nuiQuery } from '@/lib/nui'
import type { ClientConfigSnapshot } from '@/data/contracts'
import { BankError } from '@/lib/bankError'

const CONFIG_EVENT = 'sonar:bank:nui:getConfig'

export type ClientConfigOptions = Omit<
  UseQueryOptions<ClientConfigSnapshot, BankError>,
  'queryKey' | 'queryFn'
>

export function useClientConfig(options: ClientConfigOptions = {}) {
  return useQuery<ClientConfigSnapshot, BankError>({
    queryKey: queryKeys.config(),
    queryFn: () => nuiQuery<ClientConfigSnapshot>(CONFIG_EVENT, {}),
    staleTime: 5 * 60_000,
    gcTime: 30 * 60_000,
    retry: 1,
    refetchOnWindowFocus: false,
    ...options,
  })
}
