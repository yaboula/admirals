import { useCallback, useRef, type HTMLAttributes, type ReactNode } from 'react'
import { cn } from '@/lib/utils'

export interface MagicSpotlightProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode
  intensity?: number
  disabled?: boolean
}

export function MagicSpotlight({
  children,
  intensity = 1,
  disabled = false,
  className,
  onMouseMove,
  onMouseEnter,
  onMouseLeave,
  ...rest
}: MagicSpotlightProps) {
  const hostRef = useRef<HTMLDivElement | null>(null)

  const handleMove = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      const host = hostRef.current
      if (!host || disabled) return
      const rect = host.getBoundingClientRect()
      const x = ((e.clientX - rect.left) / rect.width) * 100
      const y = ((e.clientY - rect.top) / rect.height) * 100
      host.style.setProperty('--tactile-spotlight-x', `${x}%`)
      host.style.setProperty('--tactile-spotlight-y', `${y}%`)
      onMouseMove?.(e)
    },
    [disabled, onMouseMove],
  )

  const handleEnter = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      if (disabled) return
      hostRef.current?.style.setProperty('--tactile-spotlight-opacity', String(intensity))
      onMouseEnter?.(e)
    },
    [disabled, intensity, onMouseEnter],
  )

  const handleLeave = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      hostRef.current?.style.setProperty('--tactile-spotlight-opacity', '0')
      onMouseLeave?.(e)
    },
    [onMouseLeave],
  )

  return (
    <div
      ref={hostRef}
      onMouseMove={handleMove}
      onMouseEnter={handleEnter}
      onMouseLeave={handleLeave}
      className={cn('tactile-spotlight-host', className)}
      {...rest}
    >
      {children}
    </div>
  )
}
