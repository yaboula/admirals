import { forwardRef, type HTMLAttributes, type ReactNode } from 'react'
import { cn } from '@/lib/utils'

export type BadgeTone =
  | 'neutral'
  | 'brand'
  | 'success'
  | 'warning'
  | 'danger'
  | 'info'
  | 'native_full'
  | 'lite_mode_active'
  | 'compromised'
  | 'framework_missing'

export type BadgeVariant = 'solid' | 'soft' | 'outline'
export type BadgeSize = 'xs' | 'sm' | 'md'

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  tone?: BadgeTone
  variant?: BadgeVariant
  size?: BadgeSize
  leftIcon?: ReactNode
  rightIcon?: ReactNode
  pulse?: boolean
  children?: ReactNode
}

const SIZE_CLASSES: Record<BadgeSize, string> = {
  xs: 'h-5 px-1.5 text-[10px] gap-1',
  sm: 'h-6 px-2 text-xs gap-1',
  md: 'h-7 px-2.5 text-sm gap-1.5',
}

const TONE_SOLID: Record<BadgeTone, string> = {
  neutral: 'bg-surface-card-elevated text-text-primary',
  brand: 'bg-brand-signal-orange text-text-primary',
  success: 'bg-semantic-success-deep text-text-primary',
  warning: 'bg-semantic-warning-deep text-surface-abyss',
  danger: 'bg-semantic-danger-deep text-text-primary',
  info: 'bg-semantic-info-deep text-text-primary',
  native_full: 'bg-status-native-full text-text-primary',
  lite_mode_active: 'bg-status-lite-mode-active text-surface-abyss',
  compromised: 'bg-status-compromised text-text-primary',
  framework_missing: 'bg-status-framework-missing text-text-primary',
}

const TONE_SOFT: Record<BadgeTone, string> = {
  neutral: 'bg-surface-card text-text-secondary',
  brand: 'bg-brand-signal-orange-subtle text-brand-signal-orange-light',
  success: 'bg-semantic-success-glow text-semantic-success-deep',
  warning: 'bg-semantic-warning-glow text-semantic-warning-deep',
  danger: 'bg-semantic-danger-glow text-semantic-danger-deep',
  info: 'bg-semantic-info-glow text-semantic-info-deep',
  native_full: 'bg-semantic-success-glow text-status-native-full',
  lite_mode_active: 'bg-semantic-warning-glow text-status-lite-mode-active',
  compromised: 'bg-semantic-danger-glow text-status-compromised',
  framework_missing: 'bg-surface-card-elevated text-status-framework-missing',
}

const TONE_OUTLINE: Record<BadgeTone, string> = {
  neutral: 'border-border-medium text-text-secondary',
  brand: 'border-border-brand-strong text-brand-signal-orange-light',
  success: 'border-semantic-success-deep text-semantic-success-deep',
  warning: 'border-semantic-warning-deep text-semantic-warning-deep',
  danger: 'border-semantic-danger-deep text-semantic-danger-deep',
  info: 'border-semantic-info-deep text-semantic-info-deep',
  native_full: 'border-status-native-full text-status-native-full',
  lite_mode_active: 'border-status-lite-mode-active text-status-lite-mode-active',
  compromised: 'border-status-compromised text-status-compromised',
  framework_missing: 'border-status-framework-missing text-status-framework-missing',
}

export const Badge = forwardRef<HTMLSpanElement, BadgeProps>(function Badge(
  {
    tone = 'neutral',
    variant = 'soft',
    size = 'sm',
    leftIcon,
    rightIcon,
    pulse = false,
    className,
    children,
    ...rest
  },
  ref,
) {
  const variantClass =
    variant === 'solid'
      ? TONE_SOLID[tone]
      : variant === 'outline'
        ? `bg-transparent border ${TONE_OUTLINE[tone]}`
        : TONE_SOFT[tone]

  return (
    <span
      ref={ref}
      className={cn(
        'tactile-badge inline-flex items-center font-medium tracking-tight',
        SIZE_CLASSES[size],
        variantClass,
        className,
      )}
      {...rest}
    >
      {pulse && (
        <span
          aria-hidden="true"
          className="relative inline-flex h-1.5 w-1.5 mr-1"
        >
          <span className="absolute inline-flex h-full w-full rounded-full opacity-60 bg-current animate-ping" />
          <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-current" />
        </span>
      )}
      {leftIcon && <span className="inline-flex shrink-0">{leftIcon}</span>}
      {children}
      {rightIcon && <span className="inline-flex shrink-0">{rightIcon}</span>}
    </span>
  )
})
