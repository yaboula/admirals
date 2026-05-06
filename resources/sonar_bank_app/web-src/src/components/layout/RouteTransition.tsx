import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { useLocation } from 'react-router-dom'
import type { ReactNode } from 'react'

export interface RouteTransitionProps {
  children: ReactNode
}

export function RouteTransition({ children }: RouteTransitionProps) {
  const location = useLocation()
  const reduced = useReducedMotion()

  return (
    <AnimatePresence mode="wait" initial={false}>
      <motion.div
        key={location.pathname}
        initial={reduced ? false : { opacity: 0, y: 12, filter: 'blur(8px)' }}
        animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
        exit={reduced ? { opacity: 0 } : { opacity: 0, y: -8, filter: 'blur(6px)' }}
        transition={{ duration: 0.36, ease: [0.16, 1, 0.3, 1] }}
        className="will-change-transform"
      >
        {children}
      </motion.div>
    </AnimatePresence>
  )
}
