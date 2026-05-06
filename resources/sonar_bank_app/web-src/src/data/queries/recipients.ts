import { useQuery, useQueryClient, type UseQueryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import { nuiQuery } from '@/lib/nui'
import type { RecentRecipientsResponse } from '@/data/contracts'
import { BankError } from '@/lib/bankError'

const RECENT_EVENT = 'sonar:bank:transfer:recentRecipients'

export type RecentRecipientsOptions = Omit<
  UseQueryOptions<RecentRecipientsResponse, BankError>,
  'queryKey' | 'queryFn'
>

export function useRecentRecipients(options: RecentRecipientsOptions = {}) {
  return useQuery<RecentRecipientsResponse, BankError>({
    queryKey: queryKeys.recipients.recent(),
    queryFn: () => nuiQuery<RecentRecipientsResponse>(RECENT_EVENT, {}),
    staleTime: 30_000,
    gcTime: 5 * 60_000,
    retry: (failureCount, err) => {
      if (err instanceof BankError && err.retryable === false) return false
      return failureCount < 2
    },
    refetchOnWindowFocus: false,
    ...options,
  })
}

export function useInvalidateRecentRecipients() {
  const qc = useQueryClient()
  return () => qc.invalidateQueries({ queryKey: queryKeys.recipients.recent() })
}
