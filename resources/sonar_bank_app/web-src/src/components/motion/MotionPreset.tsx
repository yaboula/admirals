import { motion, useReducedMotion, type HTMLMotionProps, type Transition } from 'motion/react'
import type { ReactNode } from 'react'

export type MotionPresetName =
  | 'page-enter'
  | 'page-exit'
  | 'tab-switch'
  | 'modal-open'
  | 'modal-close'
  | 'toast-enter'
  | 'toast-exit'
  | 'confirm-ripple'
  | 'wizard-step-slide'
  | 'fade-up'
  | 'scale-fade'

interface PresetSpec {
  initial?: HTMLMotionProps<'div'>['initial']
  animate?: HTMLMotionProps<'div'>['animate']
  exit?: HTMLMotionProps<'div'>['exit']
  transition: Transition
}

const SPRING_SOFT: Transition = { type: 'spring', stiffness: 180, damping: 24, mass: 1 }
const SPRING_SNAPPY: Transition = { type: 'spring', stiffness: 380, damping: 30, mass: 1 }
const SPRING_PREMIUM: Transition = { type: 'spring', stiffness: 220, damping: 18, mass: 0.9, restSpeed: 0.5 }
type CubicBezier = [number, number, number, number]
const EASE_OUT_EXPO: CubicBezier = [0.16, 1, 0.3, 1]
const EASE_OUT_QUART: CubicBezier = [0.25, 1, 0.5, 1]
const EASE_SPRING_PREMIUM: CubicBezier = [0.34, 1.56, 0.64, 1]

const PRESETS: Record<MotionPresetName, PresetSpec> = {
  'page-enter': {
    initial: { opacity: 0, y: 12 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.48, ease: EASE_OUT_EXPO },
  },
  'page-exit': {
    exit: { opacity: 0, y: -8 },
    transition: { duration: 0.32, ease: EASE_OUT_QUART },
  },
  'tab-switch': {
    initial: { opacity: 0, x: 8 },
    animate: { opacity: 1, x: 0 },
    transition: SPRING_SOFT,
  },
  'modal-open': {
    initial: { opacity: 0, scale: 0.96 },
    animate: { opacity: 1, scale: 1 },
    transition: SPRING_SNAPPY,
  },
  'modal-close': {
    exit: { opacity: 0, scale: 0.96 },
    transition: { duration: 0.2, ease: EASE_OUT_QUART },
  },
  'toast-enter': {
    initial: { opacity: 0, x: 32 },
    animate: { opacity: 1, x: 0 },
    transition: SPRING_SNAPPY,
  },
  'toast-exit': {
    exit: { opacity: 0, x: 32 },
    transition: { duration: 0.2, ease: EASE_OUT_QUART },
  },
  'confirm-ripple': {
    animate: { scale: [1, 1.04, 1] },
    transition: { duration: 0.4, ease: EASE_SPRING_PREMIUM },
  },
  'wizard-step-slide': {
    initial: { opacity: 0, x: 24 },
    animate: { opacity: 1, x: 0 },
    exit: { opacity: 0, x: -24 },
    transition: { duration: 0.32, ease: EASE_OUT_EXPO, ...SPRING_PREMIUM },
  },
  'fade-up': {
    initial: { opacity: 0, y: 8 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.32, ease: EASE_OUT_EXPO },
  },
  'scale-fade': {
    initial: { opacity: 0, scale: 0.98 },
    animate: { opacity: 1, scale: 1 },
    transition: SPRING_SOFT,
  },
}

interface MotionPresetProps extends Omit<HTMLMotionProps<'div'>, 'initial' | 'animate' | 'exit' | 'transition'> {
  preset: MotionPresetName
  children?: ReactNode
}

export function MotionPreset({ preset, children, ...rest }: MotionPresetProps) {
  const reduced = useReducedMotion()
  const spec = PRESETS[preset]
  if (reduced) {
    return (
      <motion.div
        initial={false}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0 }}
        {...rest}
      >
        {children}
      </motion.div>
    )
  }
  return (
    <motion.div
      initial={spec.initial}
      animate={spec.animate}
      exit={spec.exit}
      transition={spec.transition}
      {...rest}
    >
      {children}
    </motion.div>
  )
}
