/**
 * SONAR Tablet — motion canonical eases + durations + 5 presets LOCKED (S2.3→S2.6).
 *
 * DC8 ≥55fps GPU-only: Animar SOLO `transform` (translate/scale/rotate) + `opacity`.
 * R4 mitigation (Framer Motion jank FiveM Chromium embebido):
 *   ✅ GPU-only: `transform` (translate/scale/rotate) + `opacity`.
 *   ❌ NO animar `width` / `height` / `top` / `left` / `margin` / `padding`
 *      — triggers layout reflow per-frame, rompe budget D6 ≤4ms/frame.
 *
 * Eases:
 *   - `easeDepthDescent`: entrada premium Apple Pro / Linear class.
 *   - `easeDeliberate`: ease-in-out pausado (hover emphasis).
 *
 * 5 presets LOCKED (S2.6 canonical — consumen TabletFrame, App.tsx, BankApp, BridgeHome):
 *   tabletEntrance — 280ms Apple notification center reveal class §5.2.
 *   tabletExit     — 180ms silent close per F8 S2.0 (NO SFX).
 *   viewSwitch     — 220ms home↔app AnimatePresence mode="wait".
 *   tabSwitch      — 180ms sub-view within Bank tabs.
 *   listStagger    — container + child stagger 35ms Bridge tiles / Bank history rows.
 */
type CubicBezier = [number, number, number, number]

export const easeDepthDescent: CubicBezier = [0.2, 0.8, 0.2, 1]
export const easeDeliberate: CubicBezier = [0.4, 0, 0.2, 1]

export const durationFast = 0.15
export const durationBase = 0.24
export const durationSlow = 0.36

// ---------------------------------------------------------------------------
// Legacy named exports — preserved for backward compat (App.tsx S2.3 imports).
// These are superseded by `viewSwitch` preset below; consumers should migrate.
// ---------------------------------------------------------------------------

/** @deprecated Use `viewSwitch` preset spread instead. */
export const viewSwitchTransition = {
  duration: durationBase,
  ease: easeDepthDescent,
}

/** @deprecated Use `viewSwitch` preset spread instead. */
export const viewSwitchInitial = { opacity: 0, y: 8 }
/** @deprecated Use `viewSwitch` preset spread instead. */
export const viewSwitchAnimate = { opacity: 1, y: 0 }
/** @deprecated Use `viewSwitch` preset spread instead. */
export const viewSwitchExit = { opacity: 0, y: -8 }

// ---------------------------------------------------------------------------
// 5 PRESETS LOCKED — canonical S2.6 (DC-S2.6.1)
// Spread these directly onto <motion.div {...preset}>
// ---------------------------------------------------------------------------

/**
 * tabletEntrance — Tablet frame mount.
 * 280ms opacity+scale+y. "Apple notification center reveal" class per §5.2.
 * SFX: panel_open plays on mount (TabletFrame).
 */
export const tabletEntrance = {
  initial: { opacity: 0, scale: 0.96, y: 16 },
  animate: { opacity: 1, scale: 1, y: 0 },
  transition: { duration: 0.28, ease: easeDepthDescent },
} as const

/**
 * tabletExit — Tablet frame unmount.
 * 180ms silent close per F8 S2.0 decision.
 * SFX: SILENT (no close sound).
 */
export const tabletExit = {
  exit: { opacity: 0, scale: 0.98, y: 8 },
  transition: { duration: 0.18, ease: easeDepthDescent },
} as const

/**
 * viewSwitch — Home ↔ app router transition.
 * AnimatePresence mode="wait". 220ms GPU-only opacity+y.
 * SFX: SILENT (design "contenidas" §4.1).
 */
export const viewSwitch = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -4 },
  transition: { duration: 0.22, ease: easeDepthDescent },
} as const

/**
 * tabSwitch — Sub-view within Bank tabs (overview/history/transfer).
 * 180ms GPU-only opacity+x. AnimatePresence mode="wait".
 * SFX: layer_dive plays on tab click (BankApp).
 */
export const tabSwitch = {
  initial: { opacity: 0, x: 8 },
  animate: { opacity: 1, x: 0 },
  exit: { opacity: 0, x: -8 },
  transition: { duration: 0.18, ease: easeDepthDescent },
} as const

/**
 * listStagger — Container + child variants for Bridge tiles reveal.
 * Uses Framer Motion variants API: container propagates staggerChildren 35ms
 * to child nodes. Child: 200ms opacity+y GPU-only.
 * SFX: none per-child (console_tap on AppTile click separately).
 *
 * Usage:
 *   <motion.div variants={listStagger.container} initial="hidden" animate="show">
 *     <motion.div variants={listStagger.child}> ... </motion.div>
 *   </motion.div>
 */
export const listStagger = {
  container: {
    hidden: {},
    show: { transition: { staggerChildren: 0.035 } },
  },
  child: {
    hidden: { opacity: 0, y: 6 },
    show: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.2, ease: easeDepthDescent },
    },
  },
} as const

// ---------------------------------------------------------------------------
// MotionPreset union type (DC-S2.6.1)
// ---------------------------------------------------------------------------

export type MotionPreset =
  | typeof tabletEntrance
  | typeof tabletExit
  | typeof viewSwitch
  | typeof tabSwitch
  | typeof listStagger
