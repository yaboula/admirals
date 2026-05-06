import { Outlet } from 'react-router-dom'
import { useEffect } from 'react'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'
import { RouteTransition } from './RouteTransition'
import { ToastContainer } from './ToastContainer'
import { AuroraBackground } from '@/components/vanguard/AuroraBackground'
import { useBootstrap } from '@/data/queries'
import { useBankSession } from '@/stores/session'

/**
 * BANK-FE.2.1 — Tablet-first 3-column zero-scroll shell.
 *
 *   ┌─────────┬─────────────────────────────────────┐
 *   │ Sidebar │ Topbar (slim, 56-64px)              │
 *   │ FULL-H  ├─────────────────────────────────────┤
 *   │         │ <Outlet/> route owns inner grid     │
 *   └─────────┴─────────────────────────────────────┘
 *
 * Viewport: 1280×800 / 1024×768 in-game tablet.
 * Hard rule: Dashboard must NOT scroll. Routes that legitimately need
 * overflow declare inner scroll containers explicitly.
 */
export function AppShell() {
  const { isError, error, refetch } = useBootstrap()
  const citizenId = useBankSession((s) => s.citizenId)

  useEffect(() => {
    if (isError && error) {
      console.warn('[AppShell] bootstrap failed:', error)
    }
  }, [isError, error])

  const greeting = computeGreeting()

  return (
    <div
      className="relative h-[100dvh] w-screen overflow-hidden bg-surface-abyss text-text-primary"
      style={{
        display: 'grid',
        gridTemplateColumns: 'auto 1fr',
        gridTemplateRows: '100dvh',
      }}
    >
      <AuroraBackground />

      {/* Column 1 — full-height sidebar */}
      <div className="relative z-[var(--z-sidebar)] h-full">
        <Sidebar />
      </div>

      {/* Column 2 — topbar + main outlet stacked, no outer scroll */}
      <div
        className="relative z-[1] h-full min-w-0 overflow-hidden"
        style={{ display: 'grid', gridTemplateRows: 'auto 1fr' }}
      >
        <Topbar
          greeting={greeting}
          subtitle={citizenId ? `Hola, ${citizenId.slice(0, 14)}…` : 'SONAR Bank'}
        />
        <main className="relative min-h-0 overflow-hidden px-5 lg:px-7 pb-5 pt-3">
          <RouteTransition>
            <Outlet />
          </RouteTransition>
          {isError && (
            <button
              type="button"
              onClick={() => refetch()}
              className="absolute bottom-4 right-6 text-xs text-semantic-danger-deep underline-offset-2 hover:underline"
            >
              Bootstrap falló — reintentar
            </button>
          )}
        </main>
      </div>

      <ToastContainer />
    </div>
  )
}

function computeGreeting(): string {
  const h = new Date().getHours()
  if (h < 6) return 'Buenas noches'
  if (h < 13) return 'Buenos días'
  if (h < 21) return 'Buenas tardes'
  return 'Buenas noches'
}
