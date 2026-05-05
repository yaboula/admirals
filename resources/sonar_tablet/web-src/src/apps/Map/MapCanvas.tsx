/**
 * SONAR Tablet — MapCanvas (S2.5).
 *
 * Container que renderiza textura GTA5 + SVG layers (POIs + player marker).
 * ResizeObserver → viewportSize reactivo → proyección worldToViewport recalcula
 * en cualquier cambio dimensional (rotation tablet / window resize dev-mode).
 *
 * R4 mitigation: SVG transform-only (GPU-layer). img bg es CSS object-cover
 * + pointer-events-none (no layout thrash).
 */
import { useEffect, useMemo, useRef, useState } from 'react'
import POILayer from './POILayer'
import PlayerMarker from './PlayerMarker'
import type { GpsState, MapPOI, WorldBounds } from './types'
import type { GpsStatus } from './hooks/useGpsStream'
import { DEFAULT_BOUNDS } from './lib/projection'

interface MapCanvasProps {
  gps: GpsState | null
  gpsStatus: GpsStatus
  pois: MapPOI[]
  bounds?: WorldBounds
  onPoiClick?: (poi: MapPOI) => void
}

const DEFAULT_VIEWPORT = { width: 1024, height: 576 }

export default function MapCanvas({
  gps,
  gpsStatus,
  pois,
  bounds = DEFAULT_BOUNDS,
  onPoiClick,
}: MapCanvasProps) {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const [viewport, setViewport] = useState(DEFAULT_VIEWPORT)

  // ResizeObserver debounced rAF — evita layout thrash en resize continuo.
  useEffect(() => {
    const el = containerRef.current
    if (!el) return
    let raf: number | null = null

    const ro = new ResizeObserver((entries) => {
      const entry = entries[0]
      if (!entry) return
      const rect = entry.contentRect
      if (raf != null) cancelAnimationFrame(raf)
      raf = requestAnimationFrame(() => {
        setViewport({
          width:  Math.max(100, Math.round(rect.width)),
          height: Math.max(100, Math.round(rect.height)),
        })
      })
    })
    ro.observe(el)

    // Kick-off inicial.
    const rect = el.getBoundingClientRect()
    setViewport({
      width:  Math.max(100, Math.round(rect.width)),
      height: Math.max(100, Math.round(rect.height)),
    })

    return () => {
      if (raf != null) cancelAnimationFrame(raf)
      ro.disconnect()
    }
  }, [])

  const viewBox = useMemo(
    () => `0 0 ${viewport.width} ${viewport.height}`,
    [viewport.width, viewport.height],
  )

  return (
    <div
      ref={containerRef}
      className="relative h-full w-full overflow-hidden bg-sonar-black"
      data-slot="map-canvas"
    >
      {/*
        Textura GTA5 atlas real (929KB JPG, founder-provided S2.5).
        `object-fill`: stretch exact-match al viewport → misma transformación
        que el SVG overlay (preserveAspectRatio="none") → POIs + player marker
        píxel-aligned con el terreno. `object-cover` causaría mismatch porque
        el SVG no recorta pero la imagen sí, descalibrando las coords.
      */}
      <img
        src="./map/world.jpg"
        alt=""
        aria-hidden
        draggable={false}
        className="pointer-events-none absolute inset-0 h-full w-full select-none object-fill opacity-90"
      />

      {/* Overlay tint leve para unificar con dark canvas sin perder legibilidad. */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-sonar-black/30"
      />

      <svg
        viewBox={viewBox}
        preserveAspectRatio="none"
        className="absolute inset-0 h-full w-full"
        role="img"
        aria-label="Mapa SONAR con POIs y posición del jugador"
      >
        <POILayer
          pois={pois}
          bounds={bounds}
          viewport={viewport}
          onPoiClick={onPoiClick}
        />
        {gps ? (
          <PlayerMarker
            gps={gps}
            status={gpsStatus}
            bounds={bounds}
            viewport={viewport}
          />
        ) : null}
      </svg>
    </div>
  )
}
