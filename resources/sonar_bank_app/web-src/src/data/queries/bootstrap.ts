import { useQuery, useQueryClient, type UseQueryOptions } from '@tanstack/react-query'
import { useEffect } from 'react'
import { queryKeys } from '@/data/queryKeys'
import { nuiQuery } from '@/lib/nui'
import type { BalanceSnapshot, BootstrapSnapshot } from '@/data/contracts'
import { useBankSession } from '@/stores/session'
import { BankError } from '@/lib/bankError'
import { useWatchdog } from '@/hooks/useWatchdog'

const BOOTSTRAP_EVENT = 'sonar:bank:bootstrap:snapshot'
const BALANCE_EVENT = 'sonar:bank:bootstrap:balance'

export type BootstrapQueryOptions = Omit<
  UseQueryOptions<BootstrapSnapshot, BankError>,
  'queryKey' | 'queryFn'
>

export function useBootstrap(options: BootstrapQueryOptions = {}) {
  const setSession = useBankSession((s) => s.setSession)

  const query = useQuery<BootstrapSnapshot, BankError>({
    queryKey: queryKeys.bootstrap(),
    queryFn: async () => {
      const snap = await nuiQuery<BootstrapSnapshot>(BOOTSTRAP_EVENT, {})
      return snap
    },
    staleTime: 25_000,
    gcTime: 5 * 60_000,
    retry: (failureCount, err) => {
      if (err instanceof BankError && err.retryable === false) return false
      return failureCount < 2
    },
    refetchOnWindowFocus: false,
    ...options,
  })

  useEffect(() => {
    const data = query.data
    if (!data) return
    const primary = data.accounts[0]
    setSession({
      citizenId: data.citizen_id,
      ibanMasked: primary ? maskIban(primary.iban) : null,
    })
  }, [query.data, setSession])

  useWatchdog(30_000, () => {
    void query.refetch()
  }, [query.data?.server_now_ms, query.data?.bootstrap_id])

  return query
}

function maskIban(iban: string): string {
  const compact = iban.replace(/\s+/g, '')
  if (compact.length < 8) return iban
  return `${compact.slice(0, 4)} ···· ···· ···· ${compact.slice(-4)}`
}

export interface UseBalanceFallbackArgs {
  iban: string
  enabled?: boolean
}

export function useBalanceFallback({ iban, enabled = true }: UseBalanceFallbackArgs) {
  return useQuery<BalanceSnapshot, BankError>({
    queryKey: queryKeys.account.balance(iban),
    queryFn: () => nuiQuery<BalanceSnapshot>(BALANCE_EVENT, { iban }),
    enabled: enabled && Boolean(iban),
    staleTime: 10_000,
    refetchOnWindowFocus: false,
  })
}

export function useInvalidateBootstrap() {
  const qc = useQueryClient()
  return () => qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
}

export function useRefetchBootstrap() {
  const qc = useQueryClient()
  return () => qc.refetchQueries({ queryKey: queryKeys.bootstrap() })
}
