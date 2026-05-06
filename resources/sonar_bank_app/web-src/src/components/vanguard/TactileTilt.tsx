import { useCallback, useRef, type HTMLAttributes, type ReactNode } from 'react'
import { cn } from '@/lib/utils'

export interface TactileTiltProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode
  /** Maximum rotation in degrees (default 6°) */
  max?: number
  disabled?: boolean
  innerClassName?: string
}

export function TactileTilt({
  children,
  max = 6,
  disabled = false,
  className,
  innerClassName,
  onMouseMove,
  onMouseLeave,
  ...rest
}: TactileTiltProps) {
  const targetRef = useRef<HTMLDivElement | null>(null)
  const rafRef = useRef<number | null>(null)

  const handleMove = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      const target = targetRef.current
      if (!target || disabled) return
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current)
      const rect = target.getBoundingClientRect()
      const xRel = (e.clientX - rect.left) / rect.width - 0.5
      const yRel = (e.clientY - rect.top) / rect.height - 0.5
      rafRef.current = requestAnimationFrame(() => {
        target.style.setProperty('--tactile-tilt-y', `${(xRel * max).toFixed(2)}deg`)
        target.style.setProperty('--tactile-tilt-x', `${(-yRel * max).toFixed(2)}deg`)
      })
      onMouseMove?.(e)
    },
    [disabled, max, onMouseMove],
  )

  const handleLeave = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      const target = targetRef.current
      if (!target) return
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current)
      target.style.setProperty('--tactile-tilt-x', '0deg')
      target.style.setProperty('--tactile-tilt-y', '0deg')
      onMouseLeave?.(e)
    },
    [onMouseLeave],
  )

  return (
    <div
      onMouseMove={handleMove}
      onMouseLeave={handleLeave}
      className={cn('tactile-tilt-perspective', className)}
      {...rest}
    >
      <div ref={targetRef} className={cn('tactile-tilt-target', innerClassName)}>
        {children}
      </div>
    </div>
  )
}
