import { useCallback, useRef, type HTMLAttributes, type ReactNode } from 'react'
import { cn } from '@/lib/utils'

export interface MagneticHoverProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode
  strength?: number
  disabled?: boolean
  innerClassName?: string
}

export function MagneticHover({
  children,
  strength = 0.25,
  disabled = false,
  className,
  innerClassName,
  onMouseMove,
  onMouseLeave,
  ...rest
}: MagneticHoverProps) {
  const hostRef = useRef<HTMLDivElement | null>(null)
  const targetRef = useRef<HTMLDivElement | null>(null)

  const handleMove = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      const host = hostRef.current
      const target = targetRef.current
      if (!host || !target || disabled) return
      const rect = host.getBoundingClientRect()
      const cx = rect.left + rect.width / 2
      const cy = rect.top + rect.height / 2
      const dx = (e.clientX - cx) * strength
      const dy = (e.clientY - cy) * strength
      target.style.setProperty('--tactile-mag-x', `${dx.toFixed(1)}px`)
      target.style.setProperty('--tactile-mag-y', `${dy.toFixed(1)}px`)
      onMouseMove?.(e)
    },
    [disabled, strength, onMouseMove],
  )

  const handleLeave = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      const target = targetRef.current
      if (target) {
        target.style.setProperty('--tactile-mag-x', '0px')
        target.style.setProperty('--tactile-mag-y', '0px')
      }
      onMouseLeave?.(e)
    },
    [onMouseLeave],
  )

  return (
    <div
      ref={hostRef}
      onMouseMove={handleMove}
      onMouseLeave={handleLeave}
      className={cn('tactile-magnetic-host', className)}
      {...rest}
    >
      <div ref={targetRef} className={cn('tactile-magnetic-target', innerClassName)}>
        {children}
      </div>
    </div>
  )
}
