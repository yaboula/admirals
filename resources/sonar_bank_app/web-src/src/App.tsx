import { Outlet, useLocation } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Component, type ErrorInfo, type ReactNode, useEffect, useState } from 'react'
import { AlertTriangle } from 'lucide-react'
import { isDev, isInsideFiveMNui, isMockMode } from '@/lib/env'
import { nuiControl, onNuiMessage } from '@/lib/nui'
import { BankDeviceFrame } from '@/components/layout/BankDeviceFrame'
import { useBankNetEvent } from './lib/bankEvents'
import { useBankStatus } from './stores/status'
import { toast } from './stores/toast'
import { useInvalidateBootstrap } from './data/queries'
import { useI18n } from './lib/i18n'

export function App() {
  const location = useLocation()
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

  const [visible, setVisible] = useState(isMockMode() || (!isInsideFiveMNui() && isDev()))

  useEffect(() => {
    document.documentElement.classList.toggle('bank-nui-visible', visible)
    document.body.classList.toggle('bank-nui-visible', visible)
  }, [visible])

  return (
    <QueryClientProvider client={queryClient}>
      {/* NuiControlBridge listens to FiveM messages — wrap defensively so a
          malformed payload from Lua cannot kill the whole tree. */}
      <AppErrorBoundary locationKey={`nui-${location.key}`} fallback={null}>
        <NuiControlBridge onVisibilityChange={setVisible} />
      </AppErrorBoundary>
      {visible && (
        <BankDeviceFrame>
          {/* NetEventBridge mounts hooks (useBankNetEvent, useI18n, etc.)
              outside the route Outlet. A throw here previously cascaded up
              past the route boundary and unmounted the entire app. */}
          <AppErrorBoundary locationKey={`net-${location.key}`} fallback={null}>
            <NetEventBridge />
          </AppErrorBoundary>
          <AppErrorBoundary locationKey={location.key}>
            <Outlet />
          </AppErrorBoundary>
        </BankDeviceFrame>
      )}
    </QueryClientProvider>
  )
}

class AppErrorBoundary extends Component<
  { children: ReactNode; locationKey: string; fallback?: ReactNode },
  { hasError: boolean }
> {
  state = { hasError: false }

  static getDerivedStateFromError(): { hasError: boolean } {
    return { hasError: true }
  }

  componentDidCatch(error: unknown, errorInfo: ErrorInfo): void {
    console.error('[SONAR Bank] Subtree render failed', {
      locationKey: this.props.locationKey,
      error,
      componentStack: errorInfo?.componentStack,
    })
  }

  componentDidUpdate(prevProps: { locationKey: string }): void {
    if (this.state.hasError && prevProps.locationKey !== this.props.locationKey) {
      this.setState({ hasError: false })
    }
  }

  render(): ReactNode {
    if (this.state.hasError) {
      // Allow caller to opt out of the visible fallback (e.g. for headless
      // bridge components that normally render null — showing a panel where
      // none existed would itself be a regression).
      return this.props.fallback !== undefined ? this.props.fallback : <RouteErrorFallback />
    }
    return this.props.children
  }
}

function RouteErrorFallback() {
  return (
    <div className="flex h-full w-full items-center justify-center p-6">
      <div
        className="max-w-md rounded-[1.75rem] px-7 py-6 text-center"
        style={{
          background: 'rgba(18, 12, 8, 0.96)',
          border: '1.5px solid rgba(255, 100, 19, 0.55)',
          boxShadow: '0 24px 80px -40px rgba(0, 0, 0, 0.9), inset 0 1px 0 rgba(255, 255, 255, 0.08), 0 0 40px -12px rgba(255, 100, 19, 0.18)',
        }}
      >
        <div className="mx-auto mb-4 inline-flex h-12 w-12 items-center justify-center rounded-2xl" style={{ background: 'rgba(255, 100, 19, 0.12)', border: '1px solid rgba(255, 100, 19, 0.25)' }}>
          <AlertTriangle size={24} style={{ color: 'rgb(255, 100, 19)' }} />
        </div>
        <h1 className="text-lg font-semibold text-text-primary">Error cargando esta vista</h1>
        <p className="mt-2 text-sm text-text-tertiary">
          El resto de la interfaz sigue activa. Navega a otra sección y vuelve para reintentar.
        </p>
        <p className="mt-3 text-[11px] text-text-tertiary opacity-70">
          Si el error persiste, reinicia el recurso bancario para limpiar caché.
        </p>
      </div>
    </div>
  )
}

function NuiControlBridge({ onVisibilityChange }: { onVisibilityChange: (visible: boolean) => void }) {
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return
      event.preventDefault()
      void nuiControl('close').catch(() => undefined)
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [])

  useEffect(() => {
    return onNuiMessage((data: unknown) => {
      if (!data || typeof data !== 'object' || !('type' in data)) return
      const msg = data as { type: string }
      if (msg.type === 'BANK_OPEN') {
        onVisibilityChange(true)
      } else if (msg.type === 'BANK_CLOSE') {
        onVisibilityChange(false)
      }
    })
  }, [onVisibilityChange])

  return null
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

