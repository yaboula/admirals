import { motion } from 'motion/react'
import { Search, X } from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { GovtCard } from '../../components/GovtCard'
import type {
  GovtFlagQueueFilters,
  GovtFlagQueueItem,
  GovtFlagSeverity,
  GovtFlagStatus,
} from '../../data/contracts'

interface Props {
  filters: GovtFlagQueueFilters
  onFiltersChange: (next: GovtFlagQueueFilters) => void
  flags: GovtFlagQueueItem[]
  selectedFlagId: string | null
  onSelect: (flagId: string) => void
  isLoading: boolean
}

const SEVERITY_TONE: Record<GovtFlagSeverity, { color: string; key: TranslationKey }> = {
  info: { color: 'oklch(0.78 0.10 215)', key: 'govt.census.flags.severity.info' },
  low: { color: 'oklch(0.65 0.18 155)', key: 'govt.census.flags.severity.low' },
  medium: { color: 'oklch(0.78 0.16 85)', key: 'govt.census.flags.severity.medium' },
  high: { color: 'oklch(0.72 0.20 35)', key: 'govt.census.flags.severity.high' },
  critical: { color: 'oklch(0.62 0.21 25)', key: 'govt.census.flags.severity.critical' },
}

const STATUS_TONE: Record<GovtFlagStatus, { fg: string; bg: string; key: TranslationKey }> = {
  open: {
    fg: 'oklch(0.85 0.14 85)',
    bg: 'oklch(0.78 0.16 85 / 0.10)',
    key: 'govt.census.flags.status.open',
  },
  reviewing: {
    fg: 'var(--color-govt-accent-light)',
    bg: 'var(--color-govt-accent-soft)',
    key: 'govt.census.flags.status.reviewing',
  },
  resolved: {
    fg: 'oklch(0.78 0.16 155)',
    bg: 'oklch(0.65 0.18 155 / 0.10)',
    key: 'govt.census.flags.status.resolved',
  },
  dismissed: {
    fg: 'var(--color-govt-text-tertiary)',
    bg: 'oklch(1 0 0 / 0.04)',
    key: 'govt.census.flags.status.dismissed',
  },
}

const SEVERITY_OPTS: Array<{ value: GovtFlagSeverity | 'all'; key: TranslationKey }> = [
  { value: 'all', key: 'govt.sanctions.filters.allSeverity' },
  { value: 'critical', key: 'govt.census.flags.severity.critical' },
  { value: 'high', key: 'govt.census.flags.severity.high' },
  { value: 'medium', key: 'govt.census.flags.severity.medium' },
  { value: 'low', key: 'govt.census.flags.severity.low' },
]

const STATUS_OPTS: Array<{ value: GovtFlagStatus | 'all'; key: TranslationKey }> = [
  { value: 'all', key: 'govt.sanctions.filters.allStatus' },
  { value: 'open', key: 'govt.census.flags.status.open' },
  { value: 'reviewing', key: 'govt.census.flags.status.reviewing' },
  { value: 'resolved', key: 'govt.census.flags.status.resolved' },
  { value: 'dismissed', key: 'govt.census.flags.status.dismissed' },
]

export function FlagQueue({ filters, onFiltersChange, flags, selectedFlagId, onSelect, isLoading }: Props) {
  const { t, number } = useI18n()
  const handle = <K extends keyof GovtFlagQueueFilters>(key: K, value: GovtFlagQueueFilters[K]) => {
    sfx.console_tap()
    onFiltersChange({ ...filters, [key]: value })
  }

  return (
    <GovtCard variant="glass" padding="none" className="flex min-h-0 flex-col overflow-hidden">
      <div className="space-y-3 border-b border-[var(--color-govt-border)] p-3">
        <div className="relative">
          <Search size={14} strokeWidth={2} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-govt-text-tertiary)]" />
          <input
            type="text"
            value={filters.search}
            onChange={(e) => onFiltersChange({ ...filters, search: e.target.value })}
            placeholder={t('govt.sanctions.searchPlaceholder')}
            aria-label={t('govt.sanctions.searchPlaceholder')}
            className="h-9 w-full rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.06_0.022_252/0.50)] pl-9 pr-9 text-sm text-[var(--color-govt-text-primary)] placeholder:text-[var(--color-govt-text-tertiary)] outline-none transition-colors focus:border-[var(--color-govt-border-active)]"
          />
          {filters.search ? (
            <button
              type="button"
              onClick={() => onFiltersChange({ ...filters, search: '' })}
              aria-label={t('govt.census.searchClear')}
              className="absolute right-2 top-1/2 -translate-y-1/2 rounded-full p-1 text-[var(--color-govt-text-tertiary)] hover:bg-white/[0.06] hover:text-[var(--color-govt-text-primary)]"
            >
              <X size={12} strokeWidth={2.2} />
            </button>
          ) : null}
        </div>

        <ChipRow
          label={t('govt.sanctions.filters.severityLabel')}
          options={SEVERITY_OPTS}
          selected={filters.severity}
          onSelect={(v) => handle('severity', v)}
        />
        <ChipRow
          label={t('govt.sanctions.filters.statusLabel')}
          options={STATUS_OPTS}
          selected={filters.status}
          onSelect={(v) => handle('status', v)}
        />
      </div>

      <div className="flex items-center justify-between gap-2 border-b border-[var(--color-govt-border)] px-3 py-2">
        <span className="text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
          {t('govt.sanctions.queueHeader')}
        </span>
        <span className="text-[10px] uppercase tracking-[0.14em] text-[var(--color-govt-text-quaternary)]">
          {`${number(flags.length)} ${t('govt.sanctions.queueResults')}`}
        </span>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto p-2 scrollbar-thin">
        {isLoading ? (
          <div className="flex h-32 items-center justify-center text-[10px] uppercase tracking-[0.16em] text-[var(--color-govt-text-tertiary)]">
            Loading…
          </div>
        ) : flags.length === 0 ? (
          <div className="flex h-32 items-center justify-center px-4 text-center text-[11px] leading-relaxed text-[var(--color-govt-text-tertiary)]">
            {t('govt.sanctions.queueEmpty')}
          </div>
        ) : (
          <ul className="space-y-1.5">
            {flags.map((flag) => (
              <li key={flag.flagId}>
                <FlagRow
                  flag={flag}
                  active={flag.flagId === selectedFlagId}
                  onSelect={onSelect}
                />
              </li>
            ))}
          </ul>
        )}
      </div>
    </GovtCard>
  )
}

interface FlagRowProps {
  flag: GovtFlagQueueItem
  active: boolean
  onSelect: (flagId: string) => void
}

function FlagRow({ flag, active, onSelect }: FlagRowProps) {
  const { t, relativeTime } = useI18n()
  const sev = SEVERITY_TONE[flag.severity]
  const stat = STATUS_TONE[flag.status]

  return (
    <motion.button
      type="button"
      onClick={() => {
        sfx.console_tap()
        onSelect(flag.flagId)
      }}
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.16 }}
      aria-pressed={active}
      className={cn(
        'group flex w-full items-start gap-2.5 rounded-xl border p-2.5 text-left transition-all',
        active
          ? 'border-[var(--color-govt-border-active)] bg-[var(--color-govt-accent-soft)] shadow-[0_0_18px_var(--color-govt-accent-glow)]'
          : 'border-[var(--color-govt-border)] bg-[oklch(0.06_0.022_252/0.45)] hover:border-[var(--color-govt-border-strong)] hover:bg-[oklch(0.10_0.030_252/0.55)]',
      )}
    >
      <span aria-hidden className="mt-1 h-2 w-2 flex-shrink-0 rounded-full" style={{ background: sev.color, boxShadow: `0 0 8px ${sev.color}` }} />

      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between gap-2">
          <p className="truncate text-[12px] font-semibold text-[var(--color-govt-text-primary)]">{flag.citizenAlias}</p>
          <span
            className="flex-shrink-0 rounded-full border px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-[0.12em]"
            style={{ color: stat.fg, background: stat.bg, borderColor: 'transparent' }}
          >
            {t(stat.key)}
          </span>
        </div>
        <p className="line-clamp-2 text-[11px] leading-snug text-[var(--color-govt-text-secondary)]">{flag.summary}</p>
        <div className="mt-1 flex items-center gap-2 text-[10px] uppercase tracking-[0.10em] text-[var(--color-govt-text-tertiary)]">
          <span style={{ color: sev.color }}>{t(sev.key)}</span>
          <span className="text-[var(--color-govt-text-quaternary)]">·</span>
          <span>{relativeTime(flag.raisedAt)}</span>
        </div>
      </div>
    </motion.button>
  )
}

function ChipRow<V extends string>({
  label,
  options,
  selected,
  onSelect,
}: {
  label: string
  options: Array<{ value: V; key: TranslationKey }>
  selected: V
  onSelect: (next: V) => void
}) {
  const { t } = useI18n()
  return (
    <div className="space-y-1">
      <span className="block text-[9px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{label}</span>
      <div className="flex flex-wrap gap-1">
        {options.map((opt) => {
          const active = opt.value === selected
          return (
            <button
              key={opt.value}
              type="button"
              onClick={() => onSelect(opt.value)}
              className={cn(
                'inline-flex h-6 items-center rounded-full border px-2 text-[10px] font-semibold uppercase tracking-[0.10em] transition-all',
                active
                  ? 'border-[var(--color-govt-border-active)] bg-[var(--color-govt-accent-soft)] text-[var(--color-govt-accent-light)]'
                  : 'border-[var(--color-govt-border)] bg-white/[0.03] text-[var(--color-govt-text-tertiary)] hover:border-[var(--color-govt-border-strong)] hover:text-[var(--color-govt-text-secondary)]',
              )}
            >
              {t(opt.key)}
            </button>
          )
        })}
      </div>
    </div>
  )
}
