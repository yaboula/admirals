import { Outlet } from 'react-router-dom'
import { useEffect } from 'react'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'
import { RouteTransition } from './RouteTransition'
import { ToastContainer } from './ToastContainer'
import { AuroraBackground } from '@/components/vanguard/AuroraBackground'
import { ScrollProvider } from '@/components/vanguard/ScrollContext'
import { useBootstrap } from '@/data/queries'
import { useBankSession } from '@/stores/session'

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
    <div className="relative min-h-screen flex bg-surface-abyss text-text-primary overflow-hidden">
      <AuroraBackground />
      <Sidebar />
      <ScrollProvider
        saturationPx={140}
        className="relative flex-1 z-[1] h-screen overflow-y-auto"
      >
        <Topbar
          greeting={greeting}
          subtitle={citizenId ? `Hola, ${citizenId.slice(0, 14)}…` : 'SONAR Bank'}
        />
        <main className="relative px-6 lg:px-10 pb-16 pt-6">
          <RouteTransition>
            <Outlet />
          </RouteTransition>
          {isError && (
            <button
              type="button"
              onClick={() => refetch()}
              className="mt-4 text-xs text-semantic-danger-deep underline-offset-2 hover:underline"
            >
              Bootstrap falló — reintentar
            </button>
          )}
        </main>
      </ScrollProvider>
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
