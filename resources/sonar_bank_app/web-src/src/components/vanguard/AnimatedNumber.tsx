import { useEffect, useRef } from 'react'
import { useMotionValue, useReducedMotion, useSpring, useTransform } from 'motion/react'
import { motion } from 'motion/react'
import { cn } from '@/lib/utils'

export interface AnimatedNumberProps {
  value: number
  decimals?: number
  locale?: string
  prefix?: string
  suffix?: string
  className?: string
  stiffness?: number
  damping?: number
}

export function AnimatedNumber({
  value,
  decimals = 2,
  locale = 'en-US',
  prefix = '',
  suffix = '',
  className,
  stiffness = 80,
  damping = 22,
}: AnimatedNumberProps) {
  const reduced = useReducedMotion()
  const motionValue = useMotionValue(value)
  const spring = useSpring(motionValue, { stiffness, damping, mass: 1, restDelta: 0.01 })
  const formatter = useRef(
    new Intl.NumberFormat(locale, {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    }),
  )
  const display = useTransform(spring, (v) => `${prefix}${formatter.current.format(v)}${suffix}`)

  useEffect(() => {
    formatter.current = new Intl.NumberFormat(locale, {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    })
  }, [locale, decimals])

  useEffect(() => {
    if (reduced) {
      motionValue.jump(value)
    } else {
      motionValue.set(value)
    }
  }, [value, motionValue, reduced])

  return (
    <motion.span className={cn('tactile-tabular-nums', className)} aria-live="polite">
      {display}
    </motion.span>
  )
}
