import { forwardRef, type HTMLAttributes, type ReactNode } from 'react'
import { cn } from '@/lib/utils'

export type CardVariant = 'baseline' | 'elevated' | 'glass'
export type CardPadding = 'none' | 'sm' | 'md' | 'lg' | 'xl'

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: CardVariant
  padding?: CardPadding
  hero?: boolean
  heroLight?: boolean
  interactive?: boolean
  innerLift?: boolean
  asChild?: boolean
  children?: ReactNode
}

const PADDING_CLASSES: Record<CardPadding, string> = {
  none: 'p-0',
  sm: 'p-3',
  md: 'p-4',
  lg: 'p-6',
  xl: 'p-8',
}

const VARIANT_CLASSES: Record<CardVariant, string> = {
  baseline: 'tactile-card',
  elevated: 'tactile-card-elevated',
  glass: 'tactile-glass-card',
}

export const Card = forwardRef<HTMLDivElement, CardProps>(function Card(
  {
    variant = 'baseline',
    padding = 'md',
    hero = false,
    heroLight = false,
    interactive = false,
    innerLift = false,
    children,
    className,
    ...rest
  },
  ref,
) {
  return (
    <div
      ref={ref}
      className={cn(
        VARIANT_CLASSES[variant],
        PADDING_CLASSES[padding],
        interactive && 'tactile-card-interactive',
        hero && 'tactile-card-hero-glow',
        heroLight && 'tactile-vista-hero-light',
        innerLift && 'tactile-inner-lift',
        className,
      )}
      {...rest}
    >
      {children}
    </div>
  )
})

export interface CardSectionProps extends HTMLAttributes<HTMLDivElement> {
  divided?: boolean
  children?: ReactNode
}

export const CardHeader = forwardRef<HTMLDivElement, CardSectionProps>(function CardHeader(
  { divided = false, className, children, ...rest },
  ref,
) {
  return (
    <div
      ref={ref}
      className={cn(
        'flex flex-col gap-1',
        divided && 'pb-4 mb-4 border-b border-border-subtle',
        className,
      )}
      {...rest}
    >
      {children}
    </div>
  )
})

export const CardTitle = forwardRef<HTMLHeadingElement, HTMLAttributes<HTMLHeadingElement>>(
  function CardTitle({ className, children, ...rest }, ref) {
    return (
      <h3
        ref={ref}
        className={cn('text-lg font-semibold text-text-primary tracking-tight', className)}
        {...rest}
      >
        {children}
      </h3>
    )
  },
)

export const CardEyebrow = forwardRef<HTMLSpanElement, HTMLAttributes<HTMLSpanElement>>(
  function CardEyebrow({ className, children, ...rest }, ref) {
    return (
      <span
        ref={ref}
        className={cn(
          'text-xs uppercase tracking-widest font-medium text-text-tertiary',
          className,
        )}
        {...rest}
      >
        {children}
      </span>
    )
  },
)

export const CardDescription = forwardRef<HTMLParagraphElement, HTMLAttributes<HTMLParagraphElement>>(
  function CardDescription({ className, children, ...rest }, ref) {
    return (
      <p ref={ref} className={cn('text-sm text-text-secondary leading-relaxed', className)} {...rest}>
        {children}
      </p>
    )
  },
)

export const CardContent = forwardRef<HTMLDivElement, CardSectionProps>(function CardContent(
  { className, children, ...rest },
  ref,
) {
  return (
    <div ref={ref} className={cn('flex flex-col gap-3', className)} {...rest}>
      {children}
    </div>
  )
})

export const CardFooter = forwardRef<HTMLDivElement, CardSectionProps>(function CardFooter(
  { divided = false, className, children, ...rest },
  ref,
) {
  return (
    <div
      ref={ref}
      className={cn(
        'flex items-center justify-end gap-2',
        divided && 'pt-4 mt-4 border-t border-border-subtle',
        className,
      )}
      {...rest}
    >
      {children}
    </div>
  )
})
