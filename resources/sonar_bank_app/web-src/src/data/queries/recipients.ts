import { useQueryClient, type UseQueryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import type { RecentRecipientsResponse } from '@/data/contracts'
import { BankError } from '@/lib/bankError'
import { useBankCallback } from '@/lib/bankQuery'

const RECENT_EVENT = 'sonar:bank:transfer:recentRecipients'

export type RecentRecipientsOptions = Omit<
  UseQueryOptions<RecentRecipientsResponse, BankError>,
  'queryKey' | 'queryFn'
>

export function useRecentRecipients(options: RecentRecipientsOptions = {}) {
  return useBankCallback<RecentRecipientsResponse>(
    RECENT_EVENT,
    queryKeys.recipients.recent(),
    {},
    {
      staleTime: 30_000,
      gcTime: 5 * 60_000,
      ...options,
    },
  )
}

export function useInvalidateRecentRecipients() {
  const qc = useQueryClient()
  return () => qc.invalidateQueries({ queryKey: queryKeys.recipients.recent() })
}
