import { motion, useReducedMotion, type HTMLMotionProps } from 'motion/react'
import { forwardRef, type ReactNode } from 'react'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'

export type IconButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger'
export type IconButtonSize = 'xs' | 'sm' | 'md' | 'lg'
export type IconButtonShape = 'square' | 'circle'

export interface IconButtonProps
  extends Omit<HTMLMotionProps<'button'>, 'children' | 'onClick'> {
  icon: ReactNode
  variant?: IconButtonVariant
  size?: IconButtonSize
  shape?: IconButtonShape
  loading?: boolean
  disabled?: boolean
  silent?: boolean
  'aria-label': string
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void
}

const SIZE_CLASSES: Record<IconButtonSize, string> = {
  xs: 'h-7 w-7',
  sm: 'h-8 w-8',
  md: 'h-10 w-10',
  lg: 'h-12 w-12',
}

const VARIANT_CLASSES: Record<IconButtonVariant, string> = {
  primary: 'tactile-button-primary',
  secondary: 'tactile-button-secondary',
  ghost: 'tactile-button-ghost',
  danger: 'tactile-button-danger',
}

export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(function IconButton(
  {
    icon,
    variant = 'secondary',
    size = 'md',
    shape = 'square',
    loading = false,
    disabled = false,
    silent = false,
    onClick,
    className,
    type = 'button',
    'aria-label': ariaLabel,
    ...rest
  },
  ref,
) {
  const reduced = useReducedMotion()
  const isInactive = disabled || loading

  const handleClick = (e: React.MouseEvent<HTMLButtonElement>): void => {
    if (isInactive) return
    if (!silent) sfx.console_tap()
    onClick?.(e)
  }

  return (
    <motion.button
      ref={ref}
      type={type}
      onClick={handleClick}
      disabled={isInactive}
      aria-label={ariaLabel}
      aria-busy={loading || undefined}
      aria-disabled={isInactive || undefined}
      whileTap={!isInactive && !reduced ? { scale: 0.94 } : undefined}
      whileHover={!isInactive && !reduced ? { scale: 1.04 } : undefined}
      transition={{ type: 'spring', stiffness: 600, damping: 25, mass: 0.6 }}
      className={cn(
        'tactile-focus-ring inline-flex items-center justify-center select-none',
        VARIANT_CLASSES[variant],
        SIZE_CLASSES[size],
        shape === 'circle' ? 'rounded-full' : 'rounded-lg',
        isInactive && 'opacity-60 pointer-events-none',
        className,
      )}
      {...rest}
    >
      <span className="inline-flex items-center justify-center">{icon}</span>
    </motion.button>
  )
})
