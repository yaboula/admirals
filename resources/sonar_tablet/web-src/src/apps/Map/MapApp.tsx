/**
 * SONAR Tablet — Map app STUB (S2.5 ship = backend only).
 *
 * Decisión founder (2026-05-05): la UI visual del Map con JPG estático +
 * projection lineal tiene techo técnico bajo (aspect mismatch, bounds
 * calibration manual, no tile-system). El approach híbrido entregaba un
 * resultado con distorsión visible que no matchea la identidad pro SONAR.
 *
 * S2.5 ship = **infraestructura backend** validada + lista para consumo
 * S2.6+ cuando se rediseñe la UI visual con approach correcto (candidatos:
 * Leaflet.js tile-pyramid, natives FiveM DrawSprite + minimap engine, o
 * atlas oficial Rockstar calibrado con bounds exactos).
 *
 * Preservado en repo para S2.6+ (NO borrar, tree-shakeable):
 *   - `server/map_nodes.lua`                → callback POIs admin-seed.
 *   - `client/map_gps.lua`                  → GPS poll 4Hz gated R7.
 *   - `Config.MapPOIs`, `Config.MapWorldBounds`, `Config.MapGpsPollMs`.
 *   - `apps/Map/types.ts`                   → canonical shapes (MapPOI, GpsState).
 *   - `apps/Map/mapApi.ts`                  → bridge §2.2.3 getNodes + setPollActive.
 *   - `apps/Map/lib/projection.ts`          → worldToViewport helpers.
 *   - `apps/Map/hooks/useGpsStream.ts`      → rAF throttle + stale watchdog.
 *   - `apps/Map/MapCanvas|POILayer|PlayerMarker.tsx` → componentes S2.5 (ref).
 *   - `public/map/world.jpg`                → atlas founder-provided (929KB).
 *
 * Tree-shake: este stub NO importa los módulos arriba → no entran al bundle
 * hasta que MapApp real vuelva a importarlos en S2.6+.
 */
import { useEffect, useRef } from 'react'
import { ArrowLeft, MapPin } from 'lucide-react'
import { useTabletRouter } from '@/hooks/useTabletRouter'
import { useSfx } from '@/hooks/useSfx'

export default function MapApp() {
  const { dispatch } = useTabletRouter()
  const { play } = useSfx()
  const mountedRef = useRef(false)

  // signal_emerge SFX on Map app mount — once, parity con Bank app open (DC-S2.6.6).
  useEffect(() => {
    if (mountedRef.current) return
    mountedRef.current = true
    play('signal_emerge')
  }, [play])

  return (
    <div className="flex h-full flex-col bg-sonar-black">
      <header className="flex items-center justify-between border-b border-sonar-white/10 px-6 py-3">
        <div className="flex items-center gap-3">
          <h1 className="text-sm font-semibold tracking-tight text-sonar-white">Mapa</h1>
          <span className="font-mono text-[10px] uppercase tracking-widest text-sonar-white/40">
            sonar · mapa
          </span>
        </div>
        <button
          type="button"
          onClick={() => dispatch({ type: 'BACK_TO_HOME' })}
          className="inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-xs text-sonar-white/60 transition-colors duration-150 hover:text-sonar-orange focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40"
          aria-label="Volver al Bridge home"
        >
          <ArrowLeft className="h-3.5 w-3.5" strokeWidth={1.5} aria-hidden />
          <span>Volver</span>
        </button>
      </header>

      <main className="flex flex-1 flex-col items-center justify-center gap-4 px-8">
        <div
          className="flex h-14 w-14 items-center justify-center rounded-full border border-sonar-orange/30 text-sonar-orange"
          aria-hidden
        >
          <MapPin className="h-6 w-6" strokeWidth={1.5} />
        </div>
        <h2 className="text-2xl font-semibold tracking-tight text-sonar-white">
          Mapa en desarrollo
        </h2>
        <p className="max-w-md text-center text-sm text-sonar-white/60">
          Estamos rediseñando la capa visual con un enfoque pro (tile system +
          calibración precisa). La infraestructura backend (GPS live + POIs)
          ya está lista y se activará en la próxima iteración.
        </p>
        <p className="font-mono text-[10px] uppercase tracking-widest text-sonar-white/30">
          available · S2.6+
        </p>
      </main>
    </div>
  )
}
