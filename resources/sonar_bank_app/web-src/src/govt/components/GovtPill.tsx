import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

export type GovtPillTone = 'neutral' | 'accent' | 'seal' | 'success' | 'warning' | 'danger'
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
  seal: 'border-[oklch(0.78_0.14_215/0.32)] bg-[oklch(0.78_0.14_215/0.10)] text-[var(--color-govt-seal)]',
  success: 'border-[oklch(0.65_0.18_155/0.30)] bg-[oklch(0.65_0.18_155/0.10)] text-[oklch(0.78_0.16_155)]',
  warning: 'border-[oklch(0.78_0.16_85/0.30)] bg-[oklch(0.78_0.16_85/0.10)] text-[oklch(0.85_0.14_85)]',
  danger: 'border-[oklch(0.62_0.21_25/0.32)] bg-[oklch(0.62_0.21_25/0.10)] text-[oklch(0.78_0.16_25)]',
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
