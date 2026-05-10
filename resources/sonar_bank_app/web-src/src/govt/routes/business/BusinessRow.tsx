import { motion } from 'motion/react'
import {
  CheckCircle, Snowflake, TrendingDown, Archive,
  type LucideIcon,
} from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import type { GovtBusinessStatus, GovtBusinessSummary, GovtRiskLevel } from '../../data/contracts'

interface Props {
  company: GovtBusinessSummary
  active: boolean
  onSelect: (companyId: string) => void
}

const STATUS_TONE: Record<GovtBusinessStatus, { dot: string; text: string; key: TranslationKey }> = {
  active:      { dot: 'bg-[rgb(0, 173, 91)]', text: 'text-[rgb(78, 213, 137)]', key: 'govt.business.status.active' },
  frozen:      { dot: 'bg-[rgb(0, 185, 219)]', text: 'text-[rgb(76, 209, 238)]', key: 'govt.business.status.frozen' },
  liquidating: { dot: 'bg-[rgb(230, 173, 0)]',  text: 'text-[rgb(248, 198, 85)]',  key: 'govt.business.status.liquidating' },
  dissolved:   { dot: 'bg-[var(--color-govt-text-tertiary)]', text: 'text-[var(--color-govt-text-tertiary)]', key: 'govt.business.status.dissolved' },
}

const STATUS_ICON: Record<GovtBusinessStatus, LucideIcon> = {
  active:      CheckCircle,
  frozen:      Snowflake,
  liquidating: TrendingDown,
  dissolved:   Archive,
}

const RISK_BAR: Record<GovtRiskLevel, { color: string; widthClass: string }> = {
  low:      { color: 'rgb(0, 173, 91)', widthClass: 'w-1/4' },
  medium:   { color: 'rgb(230, 173, 0)',  widthClass: 'w-2/4' },
  high:     { color: 'rgb(255, 106, 67)',  widthClass: 'w-3/4' },
  critical: { color: 'rgb(234, 60, 63)',  widthClass: 'w-full' },
}

const SECTOR_LABEL_KEY: Record<string, TranslationKey> = {
  farming:   'govt.business.sector.farming',
  milling:   'govt.business.sector.milling',
  bakery:    'govt.business.sector.bakery',
  retail:    'govt.business.sector.retail',
  logistics: 'govt.business.sector.logistics',
  services:  'govt.business.sector.services',
  finance:   'govt.business.sector.finance',
  other:     'govt.business.sector.other',
}

export function BusinessRow({ company, active, onSelect }: Props) {
  const { t, money, relativeTime, number } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const tone = STATUS_TONE[company.status]
  const StatusIcon = STATUS_ICON[company.status]
  const risk = RISK_BAR[company.riskLevel]
  const treasuryDisplay = streamerMode ? maskMoneyDisplay() : money(company.treasury)
  const sectorKey = SECTOR_LABEL_KEY[company.sector] ?? 'govt.business.sector.other'

  return (
    <motion.button
      type="button"
      onClick={() => {
        sfx.console_tap()
        onSelect(company.companyId)
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
        <StatusIcon size={15} strokeWidth={1.9} className={tone.text} />
      </span>

      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between gap-2">
          <p className="truncate text-sm font-semibold text-[var(--color-govt-text-primary)]">{company.name}</p>
          <span className={cn('inline-flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-[0.14em]', tone.text)}>
            <span className={cn('h-1.5 w-1.5 rounded-full', tone.dot)} />
            {t(tone.key)}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <p className="truncate font-mono text-[10px] uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{company.companyId}</p>
          <span className="text-[var(--color-govt-text-quaternary)]">·</span>
          <p className="text-[10px] uppercase tracking-[0.10em] text-[var(--color-govt-text-tertiary)]">{t(sectorKey)}</p>
        </div>

        <div className="mt-1.5 flex items-center justify-between gap-3">
          <span className="truncate text-[11px] text-[var(--color-govt-text-secondary)] tactile-tabular-nums">{treasuryDisplay}</span>
          <span className="flex items-center gap-1.5 text-[10px] uppercase tracking-[0.10em] text-[var(--color-govt-text-tertiary)]">
            <span className="tactile-tabular-nums">{number(company.employeeCount)}</span>
            <span>{t('govt.business.row.employees')}</span>
            <span className="text-[var(--color-govt-text-quaternary)]">·</span>
            <span>{relativeTime(company.lastActivityAt)}</span>
          </span>
        </div>

        <div className="mt-1.5 h-[3px] w-full overflow-hidden rounded-full bg-white/[0.04]" aria-hidden>
          <span className={cn('block h-full rounded-full', risk.widthClass)} style={{ background: risk.color }} />
        </div>
      </div>
    </motion.button>
  )
}
