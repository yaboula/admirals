import { lazy, Suspense, useEffect } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { TabletFrame } from '@/components/shell/TabletFrame'
import { useTabletVisibility } from '@/hooks/useTabletVisibility'
import { TabletRouterProvider } from '@/context/TabletRouter'
import { useTabletRouter } from '@/hooks/useTabletRouter'
import BridgeHome from '@/apps/Bridge/BridgeHome'
import {
  viewSwitchAnimate,
  viewSwitchExit,
  viewSwitchInitial,
  viewSwitchTransition,
} from '@/lib/motion'

/**
 * SONAR Tablet — S2.3 shell + router.
 *
 * Scope S2.3: Bridge home view (SonarOS app grid) + router state machine
 * home↔app + lazy-load Bank/Map stubs + motion entrance GPU-only.
 *
 * Bank app real S2.4. Map app real S2.5. Motion + sound signature S2.6.
 *
 * Dev-mode (npm run dev fuera de FiveM): `window.__sonar_debug_open__()` TBD
 * S2.7 polish. Sin FiveM keybind el shell permanece cerrado.
 */

// Lazy-loaded apps — separate chunks per D6 NUI budget (main ≤500KB gzip).
// Vite bundle output debe mostrar 2 chunks diferenciados post `npm run build`.
const BankApp = lazy(() => import('@/apps/Bank/BankApp'))
const MapApp = lazy(() => import('@/apps/Map/MapApp'))

function AppSkeleton() {
  return (
    <div
      className="flex h-full flex-col gap-3 bg-sonar-black p-8"
      aria-hidden
      data-slot="app-skeleton"
    >
      <div className="h-6 w-40 animate-pulse rounded-md bg-sonar-white/5" />
      <div className="h-4 w-64 animate-pulse rounded-md bg-sonar-white/5" />
      <div className="h-4 w-52 animate-pulse rounded-md bg-sonar-white/5" />
    </div>
  )
}

/**
 * Router view switcher — mounted dentro de TabletFrame (solo vivo cuando
 * tablet visible). AnimatePresence mode="wait" garantiza que el nodo saliente
 * completa exit antes de mount del entrante (zero overlap, predictable).
 *
 * ESC interceptor (capture phase):
 *   - view !== 'home' → preventDefault + stopImmediatePropagation + BACK_TO_HOME.
 *   - view === 'home' → no-op, bubble → TabletFrame window listener → onClose.
 */
function RouterSwitch() {
  const { state, dispatch } = useTabletRouter()

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key !== 'Escape') return
      if (state.view === 'home') return
      e.preventDefault()
      e.stopImmediatePropagation()
      dispatch({ type: 'BACK_TO_HOME' })
    }
    // Capture phase garantiza que corremos ANTES de TabletFrame window listener.
    document.addEventListener('keydown', onKeyDown, true)
    return () => document.removeEventListener('keydown', onKeyDown, true)
  }, [state.view, dispatch])

  return (
    <AnimatePresence mode="wait" initial={false}>
      <motion.div
        key={state.view}
        className="h-full w-full"
        initial={viewSwitchInitial}
        animate={viewSwitchAnimate}
        exit={viewSwitchExit}
        transition={viewSwitchTransition}
      >
        <Suspense fallback={<AppSkeleton />}>
          {state.view === 'home' && <BridgeHome />}
          {state.view === 'bank' && <BankApp />}
          {state.view === 'map' && <MapApp />}
        </Suspense>
      </motion.div>
    </AnimatePresence>
  )
}

function App() {
  const { visible, requestClose } = useTabletVisibility()

  return (
    <TabletRouterProvider>
      <TabletFrame visible={visible} onClose={requestClose}>
        <RouterSwitch />
      </TabletFrame>
    </TabletRouterProvider>
  )
}

export default App
