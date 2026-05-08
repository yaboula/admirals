import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

export type GovtCardVariant = 'glass' | 'elevated' | 'hero' | 'outline'
export type GovtCardPadding = 'none' | 'sm' | 'md' | 'lg'

interface GovtCardProps {
  variant?: GovtCardVariant
  padding?: GovtCardPadding
  className?: string
  children: ReactNode
}

const PADDING_MAP: Record<GovtCardPadding, string> = {
  none: 'p-0',
  sm: 'p-3',
  md: 'p-4',
  lg: 'p-5 md:p-6',
}

const VARIANT_MAP: Record<GovtCardVariant, string> = {
  glass: 'border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] backdrop-blur-xl',
  elevated: 'border-[var(--color-govt-border)] bg-[var(--color-govt-elevated)]',
  hero: 'border-[var(--color-govt-border-strong)] bg-[var(--gradient-govt-hero)] shadow-[0_28px_90px_rgba(0,0,0,0.48)]',
  outline: 'border-[var(--color-govt-border-strong)] bg-transparent',
}

export function GovtCard({ variant = 'glass', padding = 'md', className, children }: GovtCardProps) {
  return (
    <div className={cn('relative rounded-[1.5rem] border', VARIANT_MAP[variant], PADDING_MAP[padding], className)}>
      {children}
    </div>
  )
}
