/**
 * SONAR Tablet — POILayer (S2.5).
 *
 * Renderiza array MapPOI → <circle> + <text> label con focus ring keyboard-nav.
 * Cada POI tabIndex=0 → Tab natural DOM order + Enter dispara onPoiClick.
 *
 * Colors: brand identity 3-color strict (D1/D3). Usamos currentColor + Tailwind
 * text-sonar-orange para que fill herede la token palette sin hex literales.
 */
import type { KeyboardEvent } from 'react'
import type { MapPOI, WorldBounds } from './types'
import { worldToViewport, type ViewportSize } from './lib/projection'

interface POILayerProps {
  pois: MapPOI[]
  bounds: WorldBounds
  viewport: ViewportSize
  onPoiClick?: (poi: MapPOI) => void
}

export default function POILayer({ pois, bounds, viewport, onPoiClick }: POILayerProps) {
  return (
    <g data-slot="poi-layer" className="text-sonar-orange">
      {pois.map((poi) => {
        const { vx, vy } = worldToViewport(
          { x: poi.world_x, y: poi.world_y },
          bounds,
          viewport,
        )

        // Guard viewport out-of-bounds: aún así renderizamos clipped (SVG
        // clipa natural), sirve para debugging placeholder bounds mismatch.

        const handleKey = (e: KeyboardEvent<SVGGElement>) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault()
            onPoiClick?.(poi)
          }
        }

        return (
          <g
            key={poi.id}
            transform={`translate(${vx}, ${vy})`}
            tabIndex={0}
            role="button"
            aria-label={`${poi.label} (${poi.category})`}
            onClick={() => onPoiClick?.(poi)}
            onKeyDown={handleKey}
            className="cursor-pointer outline-none focus-visible:[&>rect.focus-ring]:opacity-100"
            style={{ transformOrigin: 'center' }}
          >
            {/* Focus ring rect — keyboard-nav affordance. */}
            <rect
              className="focus-ring"
              x={-16}
              y={-16}
              width={32}
              height={32}
              rx={10}
              fill="none"
              stroke="currentColor"
              strokeWidth={1.5}
              strokeDasharray="3 3"
              opacity={0}
              style={{ transition: 'opacity 120ms' }}
            />
            {/* POI outer halo — drawn below dot for glow. */}
            <circle r={12} fill="currentColor" opacity={0.18} />
            {/* POI dot. */}
            <circle r={6} fill="currentColor" />
            {/* POI dot core (sonar-black via token — contrast on atlas bg). */}
            <circle r={2} style={{ fill: 'var(--sonar-black)' }} />
            {/* Label — offset abajo-derecha, monospace pequeño. */}
            <text
              x={10}
              y={4}
              fill="currentColor"
              fontFamily="ui-monospace, SFMono-Regular, monospace"
              fontSize={11}
              className="select-none"
              style={{ paintOrder: 'stroke', stroke: 'var(--sonar-black)', strokeWidth: 3 }}
            >
              {poi.label}
            </text>
          </g>
        )
      })}
    </g>
  )
}
