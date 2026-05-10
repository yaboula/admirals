import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

export type GovtPillTone = 'neutral' | 'accent' | 'seal' | 'gold' | 'success' | 'warning' | 'danger'
export type GovtPillSize = 'xs' | 'sm' | 'md'

interface GovtPillProps {
  tone?: GovtPillTone
  size?: GovtPillSize
  leftIcon?: ReactNode
  className?: string
  children: ReactNode
}

const TONE_MAP: Record<GovtPillTone, string> = {
  neutral: 'border-white/10 bg-white/[0.045] text-[var(--color-govt-text-secondary)]',
  accent: 'border-[var(--color-govt-border-strong)] bg-[var(--color-govt-accent-soft)] text-[var(--color-govt-accent-light)]',
  seal: 'border-[rgba(0,205,239,0.32)] bg-[rgba(0,205,239,0.1)] text-[var(--color-govt-seal)]',
  gold: 'border-[var(--color-govt-gold-ring)] bg-[var(--color-govt-gold-subtle)] text-[var(--color-govt-gold)]',
  success: 'border-[rgba(0,173,91,0.3)] bg-[rgba(0,173,91,0.1)] text-[rgb(78, 213, 137)]',
  warning: 'border-[rgba(230,173,0,0.3)] bg-[rgba(230,173,0,0.1)] text-[rgb(248, 198, 85)]',
  danger: 'border-[rgba(234,60,63,0.32)] bg-[rgba(234,60,63,0.1)] text-[rgb(255, 138, 130)]',
}

const SIZE_MAP: Record<GovtPillSize, string> = {
  xs: 'h-5 px-2 text-[10px] gap-1',
  sm: 'h-6 px-2.5 text-[11px] gap-1.5',
  md: 'h-7 px-3 text-xs gap-1.5',
}

export function GovtPill({ tone = 'neutral', size = 'sm', leftIcon, className, children }: GovtPillProps) {
  return (
    <span className={cn('inline-flex items-center rounded-full border font-semibold uppercase tracking-[0.14em]', TONE_MAP[tone], SIZE_MAP[size], className)}>
      {leftIcon ? <span className="flex items-center">{leftIcon}</span> : null}
      <span>{children}</span>
    </span>
  )
}
