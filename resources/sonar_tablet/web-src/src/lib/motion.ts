/**
 * SONAR Tablet — motion canonical eases + durations (S2.3).
 *
 * R4 mitigation (Framer Motion jank FiveM Chromium embebido):
 *   ✅ Animar SOLO `transform` (translate/scale/rotate) + `opacity`.
 *   ❌ NO animar `width` / `height` / `top` / `left` / `margin` / `padding`
 *      — triggers layout reflow per-frame, rompe budget D6 ≤4ms/frame.
 *
 * Signature canonical (preliminar — motion signature completa S2.6):
 *   - `easeDepthDescent`: entrada premium Apple Pro / Linear class. Usado para
 *      entrance transitions (app → app, modal open).
 *   - `easeDeliberate`: ease-in-out pausado. Usado para gestures calmos
 *     (home breathing, hover emphasis).
 *
 * Duraciones (tokens prelim — finalizan en BRIEF-MOTION-001 v1 integration S2.6):
 *   - fast   150ms  — micro-interactions (hover, tap)
 *   - base   240ms  — default transitions (view switch, tile expand)
 *   - slow   360ms  — entrance pesada (home mount, app lazy-load)
 */
type CubicBezier = [number, number, number, number]

export const easeDepthDescent: CubicBezier = [0.2, 0.8, 0.2, 1]
export const easeDeliberate: CubicBezier = [0.4, 0, 0.2, 1]

export const durationFast = 0.15
export const durationBase = 0.24
export const durationSlow = 0.36

/**
 * View switch transition (home ↔ app) — AnimatePresence mode="wait".
 * GPU-only: opacity + translate Y (transform). Nunca height/top.
 */
export const viewSwitchTransition = {
  duration: durationBase,
  ease: easeDepthDescent,
}

export const viewSwitchInitial = { opacity: 0, y: 8 }
export const viewSwitchAnimate = { opacity: 1, y: 0 }
export const viewSwitchExit = { opacity: 0, y: -8 }
