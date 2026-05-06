import { Outlet } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useEffect, useState } from 'react'
import { onNuiMessage } from './lib/nui'
import { useBankStatus } from './stores/status'
import { toast } from './stores/toast'
import { useInvalidateBootstrap } from './data/queries'
import type { NuiInboundMessage } from './data/contracts'

export function App() {
  const setStatus = useBankStatus((s) => s.setStatus)
  const invalidateBootstrap = useInvalidateBootstrap()
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

  useEffect(() => {
    const unsub = onNuiMessage((data: unknown) => {
      const msg = data as NuiInboundMessage
      if (!msg || typeof msg !== 'object' || !('type' in msg)) return
      if (msg.type === 'NET_EVENT') {
        if (msg.event === 'sonar:bank:status:transition') {
          const payload = msg.payload as { to?: string } | undefined
          if (payload?.to) {
            setStatus({ bridgesStatus: payload.to as never, lastTransitionAt: Date.now() })
          }
        } else if (
          msg.event === 'sonar:bank:balance:update' ||
          msg.event === 'sonar:bank:savings:update' ||
          msg.event === 'sonar:bank:transfer:committed'
        ) {
          invalidateBootstrap()
          if (msg.event === 'sonar:bank:transfer:committed') {
            toast.success('Transferencia confirmada', 'Tu saldo se ha actualizado.')
          }
        } else if (msg.event === 'sonar:bank:notice:new') {
          toast.warning('Nuevo aviso', 'Revisa la sección de avisos pendientes.')
        }
      }
    })
    return unsub
  }, [setStatus, invalidateBootstrap])

  return (
    <QueryClientProvider client={queryClient}>
      <Outlet />
    </QueryClientProvider>
  )
}

