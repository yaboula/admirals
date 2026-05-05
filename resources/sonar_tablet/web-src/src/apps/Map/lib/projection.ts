/**
 * SONAR Tablet — Map projection helpers (S2.5).
 *
 * Convierte world coords GTA5 ↔ viewport SVG px. Pure functions — no side
 * effects, no React deps, trivialmente testable.
 *
 * Ejes GTA5 San Andreas:
 *   - X: crece hacia Este (+X = East, -X = West).
 *   - Y: crece hacia Norte (+Y = North, -Y = South).
 *
 * Ejes SVG viewport:
 *   - X: crece hacia la derecha.
 *   - Y: crece hacia ABAJO (flipped vs cartesiano matemático).
 *
 * Proyección normal: world_y mayor → viewport vy menor (norte "arriba").
 * Fórmula canónica: vy = (max_y - world_y) / (max_y - min_y) * viewport_h.
 */
import type { WorldBounds, WorldCoord } from '../types'

/** Default bounds GTA5 San Andreas — debe matchear Config.MapWorldBounds Lua. */
export const DEFAULT_BOUNDS: WorldBounds = {
  min_x: -4000,
  max_x:  4500,
  min_y: -4000,
  max_y:  8000,
}

export interface ViewportSize {
  width: number
  height: number
}

export interface ViewportCoord {
  vx: number
  vy: number
}

/**
 * World (GTA5 m) → viewport (SVG px).
 *
 * @param coord world coord.
 * @param bounds world bounds rectangle.
 * @param viewport viewport size en px.
 * @returns viewport coord (clamped a [0..size] si out-of-bounds).
 */
export function worldToViewport(
  coord: WorldCoord,
  bounds: WorldBounds,
  viewport: ViewportSize,
): ViewportCoord {
  const spanX = bounds.max_x - bounds.min_x
  const spanY = bounds.max_y - bounds.min_y
  if (spanX <= 0 || spanY <= 0) {
    return { vx: viewport.width / 2, vy: viewport.height / 2 }
  }
  const nx = (coord.x - bounds.min_x) / spanX
  // Y-flip: norte "arriba" en viewport.
  const ny = (bounds.max_y - coord.y) / spanY
  return {
    vx: nx * viewport.width,
    vy: ny * viewport.height,
  }
}

/**
 * Viewport → world (inverse). Útil para tooltip coords al hover S3+ (no usado
 * directo S2 pero incluido por simetría + unit-test friendly).
 */
export function viewportToWorld(
  coord: ViewportCoord,
  bounds: WorldBounds,
  viewport: ViewportSize,
): WorldCoord {
  if (viewport.width <= 0 || viewport.height <= 0) {
    return { x: 0, y: 0 }
  }
  const nx = coord.vx / viewport.width
  const ny = coord.vy / viewport.height
  return {
    x: bounds.min_x + nx * (bounds.max_x - bounds.min_x),
    y: bounds.max_y - ny * (bounds.max_y - bounds.min_y),
  }
}

/** Clamp viewport coord dentro de viewport (útil para marker off-screen). */
export function clampViewport(
  coord: ViewportCoord,
  viewport: ViewportSize,
  padding = 12,
): ViewportCoord {
  return {
    vx: Math.min(Math.max(coord.vx, padding), viewport.width - padding),
    vy: Math.min(Math.max(coord.vy, padding), viewport.height - padding),
  }
}
