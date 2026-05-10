import { Outlet } from 'react-router-dom'
import { useEffect } from 'react'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'
import { RouteTransition } from './RouteTransition'
import { ToastContainer } from './ToastContainer'
import { OnboardingOverlay } from '@/components/onboarding/OnboardingOverlay'
import { AuroraBackground } from '@/components/vanguard/AuroraBackground'
import { useBootstrap } from '@/data/queries'
import { useBankSession } from '@/stores/session'
import { getMockDisplayName, getMockGivenName, getMockInitialsFromName } from '@/data/mock/seed'
import { isMockMode } from '@/lib/env'
import { useI18n } from '@/lib/i18n'

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
  const { t } = useI18n()
  const { data, isError, error, refetch } = useBootstrap()
  const citizenId = useBankSession((s) => s.citizenId)

  useEffect(() => {
    if (isError && error) {
      console.warn('[AppShell] bootstrap failed:', error)
    }
  }, [isError, error])

  const greetingPrefix = computeGreetingPrefix((key: string) => t(key as any))
  // Phase A (mock): derive player name from seed registry.
  // Production (H3+): read session.displayName populated by bootstrap NetEvent.
  // citizenId is kept in session for audit / permission wiring — never displayed.
  const playerGivenName = isMockMode() || citizenId ? getMockGivenName() : null
  const playerDisplayName = isMockMode() || citizenId ? getMockDisplayName() : null
  const playerInitials = isMockMode() || citizenId ? getMockInitialsFromName() : undefined

  return (
    <div
      className="relative h-full w-full overflow-hidden bg-surface-abyss text-text-primary"
      style={{
        display: 'grid',
        gridTemplateColumns: 'auto 1fr',
        gridTemplateRows: '100%',
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
          greeting={greetingPrefix}
          subtitle={playerDisplayName ?? undefined}
          userInitials={playerInitials}
          profileName={playerDisplayName ?? undefined}
          profileHandle={playerGivenName ?? undefined}
        />
        <main className="relative min-h-0 overflow-hidden px-2 sm:px-3 2xl:px-6 pb-4 2xl:pb-6 pt-1 2xl:pt-2">
          <RouteTransition>
            <Outlet />
          </RouteTransition>
          {isError && (
            <button
              type="button"
              onClick={() => refetch()}
              className="absolute bottom-4 right-6 text-xs text-semantic-danger-deep underline-offset-2 hover:underline"
            >
              {t('app.bootstrapRetry')}
            </button>
          )}
        </main>
      </div>

      <ToastContainer />
      <OnboardingOverlay citizenId={data?.citizen_id || ''} primaryIban={data?.accounts[0]?.iban} />
    </div>
  )
}

function computeGreetingPrefix(t: (key: string) => string): string {
  const h = new Date().getHours()
  if (h < 6) return t('greeting.goodNight')
  if (h < 13) return t('greeting.goodMorning')
  if (h < 21) return t('greeting.goodAfternoon')
  return t('greeting.goodEvening')
}
