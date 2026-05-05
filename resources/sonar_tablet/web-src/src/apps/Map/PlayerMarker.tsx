/**
 * SONAR Tablet — PlayerMarker (S2.5).
 *
 * GPU-only: transform translate+rotate ONLY (R4 FiveM Chromium). Framer Motion
 * transition entre updates 4Hz interpola sin jank — duration 120ms ease
 * easeDepthDescent consistent con motion signature S2.3.
 *
 * Stale state (>3s sin updates): opacity 0.4 + skip heading rotation (mantiene
 * última orientación congelada).
 */
import { motion } from 'framer-motion'
import type { GpsState, WorldBounds } from './types'
import type { GpsStatus } from './hooks/useGpsStream'
import {
  clampViewport,
  worldToViewport,
  type ViewportSize,
} from './lib/projection'
import { easeDepthDescent } from '@/lib/motion'

interface PlayerMarkerProps {
  gps: GpsState
  status: GpsStatus
  bounds: WorldBounds
  viewport: ViewportSize
}

export default function PlayerMarker({ gps, status, bounds, viewport }: PlayerMarkerProps) {
  const raw = worldToViewport(
    { x: gps.world_x, y: gps.world_y },
    bounds,
    viewport,
  )
  const { vx, vy } = clampViewport(raw, viewport, 16)

  const stale = status === 'stale'
  // SVG rotation en grados, clockwise desde 12-o'clock. GTA5 heading: 0=North,
  // counter-clockwise positive (game convention). Convertimos a SVG clockwise
  // negando heading.
  const rotDeg = stale ? 0 : -gps.heading

  return (
    <motion.g
      data-slot="player-marker"
      className="text-sonar-orange"
      initial={false}
      animate={{ x: vx, y: vy, rotate: rotDeg, opacity: stale ? 0.4 : 1 }}
      transition={{ duration: 0.12, ease: easeDepthDescent }}
      style={{ willChange: 'transform' }}
    >
      {/* Outer ring glow (brand identity — currentColor herencia text-sonar-orange). */}
      <circle r={14} fill="none" stroke="currentColor" strokeWidth={1.2} opacity={0.35} />
      <circle r={9} fill="none" stroke="currentColor" strokeWidth={1.8} opacity={0.7} />
      {/* Heading arrow — triangle apuntando hacia heading dir (pre-rotation Y-negative). */}
      <polygon
        points="0,-9 5,4 0,2 -5,4"
        fill="currentColor"
        strokeWidth={0.8}
        strokeLinejoin="round"
        style={{ stroke: 'var(--sonar-black)' }}
      />
      {/* Core dot (sonar-white via token). */}
      <circle r={2.5} style={{ fill: 'var(--sonar-white)' }} />
    </motion.g>
  )
}
