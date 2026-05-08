import { motion, useReducedMotion, type HTMLMotionProps } from 'motion/react'
import { forwardRef, type ReactNode } from 'react'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { Spinner } from './Spinner'

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger'
export type ButtonSize = 'sm' | 'md' | 'lg'

export interface ButtonProps
  extends Omit<HTMLMotionProps<'button'>, 'children' | 'onClick'> {
  variant?: ButtonVariant
  size?: ButtonSize
  loading?: boolean
  disabled?: boolean
  leftIcon?: ReactNode
  rightIcon?: ReactNode
  fullWidth?: boolean
  silent?: boolean
  children?: ReactNode
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void
}

const SIZE_CLASSES: Record<ButtonSize, string> = {
  sm: 'h-8 px-3 text-sm gap-1.5',
  md: 'h-10 px-4 text-base gap-2',
  lg: 'h-12 px-6 text-md gap-2.5',
}

const VARIANT_CLASSES: Record<ButtonVariant, string> = {
  primary: 'tactile-button-primary',
  secondary: 'tactile-button-secondary',
  ghost: 'tactile-button-ghost',
  danger: 'tactile-button-danger',
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  {
    variant = 'primary',
    size = 'md',
    loading = false,
    disabled = false,
    leftIcon,
    rightIcon,
    fullWidth = false,
    silent = false,
    type = 'button',
    children,
    onClick,
    className,
    ...rest
  },
  ref,
) {
  const reduced = useReducedMotion()
  const isInactive = disabled || loading

  const handleClick = (e: React.MouseEvent<HTMLButtonElement>): void => {
    if (isInactive) return
    if (!silent) {
      if (variant === 'primary' || variant === 'danger') sfx.depth_press()
      else sfx.console_tap()
    }
    onClick?.(e)
  }

  return (
    <motion.button
      ref={ref}
      type={type}
      onClick={handleClick}
      disabled={isInactive}
      aria-busy={loading || undefined}
      aria-disabled={isInactive || undefined}
      whileTap={!isInactive && !reduced ? { scale: 0.98 } : undefined}
      transition={{ type: 'spring', stiffness: 600, damping: 25, mass: 0.6 }}
      className={cn(
        'tactile-focus-ring inline-flex items-center justify-center font-medium select-none rounded-lg',
        'whitespace-nowrap',
        VARIANT_CLASSES[variant],
        SIZE_CLASSES[size],
        fullWidth && 'w-full',
        isInactive && 'opacity-60 pointer-events-none',
        className,
      )}
      {...rest}
    >
      {loading ? (
        <Spinner
          size={size === 'lg' ? 'md' : size === 'md' ? 'sm' : 'xs'}
          variant={variant === 'primary' || variant === 'danger' ? 'inverse' : 'brand'}
        />
      ) : (
        leftIcon && <span className="inline-flex items-center justify-center">{leftIcon}</span>
      )}
      {children}
      {!loading && rightIcon && (
        <span className="inline-flex items-center justify-center">{rightIcon}</span>
      )}
    </motion.button>
  )
})
