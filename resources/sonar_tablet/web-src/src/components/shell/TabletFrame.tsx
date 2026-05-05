/**
 * SONAR Tablet — TabletFrame.
 *
 * Shell container S2.2: backdrop + frame + entrance/exit animation.
 *
 * R4 mitigation (Framer Motion jank en FiveM Chromium):
 *   - Animación GPU-only: SOLO `opacity` + `scale` (transform layer).
 *   - NO `height`/`width`/`margin`/`padding`/`top`/`left`/`right`/`bottom`.
 *   - Duración 280ms cubic ease-out premium `[0.2, 0.8, 0.2, 1]`
 *     (Apple Pro apps / Linear class — NO bouncy junior 0.8→1).
 *
 * ESC key → `onClose` (NUI→Lua via requestClose → fetchNUI('sonar:tablet:close')).
 * Keyboard listener solo activo cuando `visible` true (cleanup strict).
 */
import { AnimatePresence, motion } from 'framer-motion'
import { useEffect } from 'react'
import type { ReactNode } from 'react'
import { tabletEntrance, tabletExit } from '@/lib/motion'
import { useSfx } from '@/hooks/useSfx'

export interface TabletFrameProps {
  visible: boolean
  onClose: () => void
  children: ReactNode
}

export function TabletFrame({ visible, onClose, children }: TabletFrameProps) {
  const { play } = useSfx()

  // ESC key listener — active only when visible.
  useEffect(() => {
    if (!visible) return
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        e.preventDefault()
        onClose()
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [visible, onClose])

  // panel_open SFX on mount (DC-S2.6.6): fires when visible flips true.
  useEffect(() => {
    if (!visible) return
    play('panel_open')
  }, [visible, play])

  return (
    <AnimatePresence mode="wait">
      {visible && (
        <motion.div
          key="sonar-tablet-backdrop"
          role="dialog"
          aria-modal="true"
          aria-label="SONAR Tablet"
          className="fixed inset-0 z-50 flex items-center justify-center bg-sonar-black/80 backdrop-blur-sm"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.16, ease: 'easeOut' }}
        >
          <motion.div
            key="sonar-tablet-frame"
            className="relative h-[min(86vh,900px)] w-[min(92vw,1400px)] overflow-hidden rounded-2xl border border-sonar-white/10 bg-sonar-black shadow-2xl"
            {...tabletEntrance}
            exit={tabletExit.exit}
          >
            {children}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
