import { motion } from 'motion/react'
import { AlertTriangle, ShieldOff, ShieldCheck, Scale } from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { maskCidDisplay, maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import type { GovtCitizenStatus, GovtCitizenSummary, GovtRiskLevel } from '../../data/contracts'

interface Props {
  citizen: GovtCitizenSummary
  active: boolean
  onSelect: (cid: string) => void
}

const STATUS_TONE: Record<GovtCitizenStatus, { dot: string; text: string; key: TranslationKey }> = {
  active: { dot: 'bg-[rgb(0, 173, 91)]', text: 'text-[rgb(78, 213, 137)]', key: 'govt.census.status.active' },
  flagged: { dot: 'bg-[rgb(230, 173, 0)]', text: 'text-[rgb(248, 198, 85)]', key: 'govt.census.status.flagged' },
  sanctioned: { dot: 'bg-[rgb(234, 60, 63)]', text: 'text-[rgb(255, 138, 130)]', key: 'govt.census.status.sanctioned' },
  exempt: { dot: 'bg-[var(--color-govt-text-tertiary)]', text: 'text-[var(--color-govt-text-tertiary)]', key: 'govt.census.status.exempt' },
}

const RISK_BAR: Record<GovtRiskLevel, { color: string; widthClass: string }> = {
  low: { color: 'rgb(0, 173, 91)', widthClass: 'w-1/4' },
  medium: { color: 'rgb(230, 173, 0)', widthClass: 'w-2/4' },
  high: { color: 'rgb(255, 106, 67)', widthClass: 'w-3/4' },
  critical: { color: 'rgb(234, 60, 63)', widthClass: 'w-full' },
}

const STATUS_ICON: Record<GovtCitizenStatus, typeof ShieldCheck> = {
  active: ShieldCheck,
  flagged: AlertTriangle,
  sanctioned: ShieldOff,
  exempt: Scale,
}

export function CitizenRow({ citizen, active, onSelect }: Props) {
  const { t, money, relativeTime, number } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const tone = STATUS_TONE[citizen.status]
  const StatusIcon = STATUS_ICON[citizen.status]
  const risk = RISK_BAR[citizen.riskLevel]
  const cidDisplay = streamerMode ? maskCidDisplay(citizen.cid) : citizen.cid
  const holdingsDisplay = streamerMode ? maskMoneyDisplay() : money(citizen.totalHoldings)

  return (
    <motion.button
      type="button"
      onClick={() => {
        sfx.console_tap()
        onSelect(citizen.cid)
      }}
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.18 }}
      aria-pressed={active}
      className={cn(
        'group flex w-full items-center gap-3 rounded-2xl border p-3 text-left transition-all',
        active
          ? 'border-[var(--color-govt-border-active)] bg-[var(--color-govt-accent-soft)]'
          : 'border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] hover:border-[var(--color-govt-border-strong)] hover:bg-white/[0.04]',
      )}
    >
      <span
        aria-hidden
        className={cn(
          'flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-2xl border',
          active ? 'border-[var(--color-govt-border-active)]' : 'border-[var(--color-govt-border)]',
        )}
        style={{ background: 'rgba(0,1,1,0.65)' }}
      >
        <StatusIcon size={16} strokeWidth={1.9} className={tone.text} />
      </span>

      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between gap-2">
          <p className="truncate text-sm font-semibold text-[var(--color-govt-text-primary)]">{citizen.alias}</p>
          <span className={cn('inline-flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-[0.14em]', tone.text)}>
            <span className={cn('h-1.5 w-1.5 rounded-full', tone.dot)} />
            {t(tone.key)}
          </span>
        </div>
        <p className="truncate font-mono text-[10px] uppercase tracking-[0.16em] text-[var(--color-govt-text-tertiary)]">{cidDisplay}</p>

        <div className="mt-1.5 flex items-center justify-between gap-3">
          <span className="truncate text-[11px] text-[var(--color-govt-text-secondary)] tactile-tabular-nums">{holdingsDisplay}</span>
          <span className="flex items-center gap-1.5 text-[10px] uppercase tracking-[0.10em] text-[var(--color-govt-text-tertiary)]">
            <span className="tactile-tabular-nums">{number(citizen.flagCount)}</span>
            <span>{t('govt.census.row.flags')}</span>
            <span className="text-[var(--color-govt-text-quaternary)]">·</span>
            <span>{relativeTime(citizen.lastActivityAt)}</span>
          </span>
        </div>

        <div className="mt-1.5 h-[3px] w-full overflow-hidden rounded-full bg-white/[0.04]" aria-hidden>
          <span className={cn('block h-full rounded-full', risk.widthClass)} style={{ background: risk.color }} />
        </div>
      </div>
    </motion.button>
  )
}
