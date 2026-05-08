import { Outlet } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useState } from 'react'
import { useBankNetEvent } from './lib/bankEvents'
import { useBankStatus } from './stores/status'
import { toast } from './stores/toast'
import { useInvalidateBootstrap } from './data/queries'
import { useI18n } from './lib/i18n'

export function App() {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30_000,
            gcTime: 5 * 60_000,
            retry: 1,
            refetchOnWindowFocus: false,
          },
          mutations: {
            retry: 0,
          },
        },
      }),
  )

  return (
    <QueryClientProvider client={queryClient}>
      <NetEventBridge />
      <Outlet />
    </QueryClientProvider>
  )
}

/**
 * Lives INSIDE QueryClientProvider so useQueryClient() (called by
 * useInvalidateBootstrap) resolves correctly. Mounting this above the
 * provider would throw "No QueryClient set".
 */
function NetEventBridge() {
  const { t } = useI18n()
  const setStatus = useBankStatus((s) => s.setStatus)
  const invalidateBootstrap = useInvalidateBootstrap()

  useBankNetEvent<{ to?: string }>('sonar:bank:status:transition', (payload) => {
    if (payload?.to) {
      setStatus({ bridgesStatus: payload.to as never, lastTransitionAt: Date.now() })
    }
  })

  useBankNetEvent('sonar:bank:balance:update', () => {
    invalidateBootstrap()
  })

  useBankNetEvent('sonar:bank:savings:update', () => {
    invalidateBootstrap()
  })

  useBankNetEvent('sonar:bank:transfer:committed', () => {
    invalidateBootstrap()
    toast.success(t('app.transferCommittedToastTitle'), t('app.transferCommittedToastBody'))
  })

  useBankNetEvent('sonar:bank:notice:new', () => {
    toast.warning(t('app.newNoticeToastTitle'), t('app.newNoticeToastBody'))
  })


  return null
}

