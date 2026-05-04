/**
 * SONAR Tablet — Bridge home view (S2.3).
 *
 * App grid 4×3 (12 slots) horizontal-friendly per `02_sonar_tablet.md` §4.1
 * layout horizontal default + densidad alta. Header con wordmark + reloj local
 * (update 30s — suficiente granularidad para Tablet HUD, evita re-renders
 * innecesarios 60fps). Footer mono tiny con sprint traceability.
 *
 * Dark-only: bg-sonar-black canvas + alpha-layers sonar-white para elevación.
 * Motion: opacity + translate-Y solo (viewSwitchTransition en App.tsx wrapper).
 */
import { useEffect, useState } from 'react'
import { APP_CATALOG } from '@/apps/Bridge/appCatalog'
import type { AppTileDef } from '@/apps/Bridge/appCatalog'
import { AppTile } from '@/apps/Bridge/AppTile'
import { useTabletRouter } from '@/hooks/useTabletRouter'

function formatClock(d: Date): string {
  const hh = String(d.getHours()).padStart(2, '0')
  const mm = String(d.getMinutes()).padStart(2, '0')
  return `${hh}:${mm}`
}

export default function BridgeHome() {
  const { dispatch } = useTabletRouter()
  const [clock, setClock] = useState<string>(() => formatClock(new Date()))

  useEffect(() => {
    const id = window.setInterval(() => {
      setClock(formatClock(new Date()))
    }, 30_000)
    return () => window.clearInterval(id)
  }, [])

  function handleActivate(def: AppTileDef) {
    if (def.route === 'bank' || def.route === 'map') {
      dispatch({ type: 'OPEN_APP', view: def.route })
    }
  }

  return (
    <div className="flex h-full flex-col bg-sonar-black">
      <header className="flex items-center justify-between border-b border-sonar-white/10 px-8 py-5">
        <h1 className="text-lg font-semibold tracking-tight text-sonar-white">
          SONAR Tablet{' '}
          <span className="text-sonar-white/40">· Bridge</span>
        </h1>
        <span
          className="font-mono text-sm tabular-nums text-sonar-white/60"
          aria-label="Hora local"
        >
          {clock}
        </span>
      </header>

      <main className="flex-1 overflow-y-auto px-8 py-8">
        <div
          className="mx-auto grid max-w-5xl grid-cols-4 gap-4"
          role="grid"
          aria-label="SONAR app catalog"
        >
          {APP_CATALOG.map((def) => (
            <AppTile key={def.id} def={def} onActivate={handleActivate} />
          ))}
        </div>
      </main>

      <footer className="border-t border-sonar-white/10 px-8 py-3">
        <p className="font-mono text-[10px] uppercase tracking-widest text-sonar-white/40">
          s2.3 · bridge home · 9 apps base · 3 slots future
        </p>
      </footer>
    </div>
  )
}
