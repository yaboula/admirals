import { Search, X } from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { GovtCard } from '../../components/GovtCard'
import type {
  GovtCensusFilters,
  GovtCitizenStatus,
  GovtRiskLevel,
  GovtTaxCompliance,
} from '../../data/contracts'

interface Props {
  value: GovtCensusFilters
  onChange: (next: GovtCensusFilters) => void
  resultCount: number | undefined
}

const STATUS_OPTIONS: Array<{ value: GovtCitizenStatus | 'all'; key: TranslationKey }> = [
  { value: 'all', key: 'govt.census.filters.status.all' },
  { value: 'active', key: 'govt.census.filters.status.active' },
  { value: 'flagged', key: 'govt.census.filters.status.flagged' },
  { value: 'sanctioned', key: 'govt.census.filters.status.sanctioned' },
  { value: 'exempt', key: 'govt.census.filters.status.exempt' },
]

const COMPLIANCE_OPTIONS: Array<{ value: GovtTaxCompliance | 'all'; key: TranslationKey }> = [
  { value: 'all', key: 'govt.census.filters.compliance.all' },
  { value: 'current', key: 'govt.census.filters.compliance.current' },
  { value: 'overdue', key: 'govt.census.filters.compliance.overdue' },
  { value: 'pending', key: 'govt.census.filters.compliance.pending' },
  { value: 'exempt', key: 'govt.census.filters.compliance.exempt' },
]

const RISK_OPTIONS: Array<{ value: GovtRiskLevel | 'all'; key: TranslationKey }> = [
  { value: 'all', key: 'govt.census.filters.risk.all' },
  { value: 'low', key: 'govt.census.filters.risk.low' },
  { value: 'medium', key: 'govt.census.filters.risk.medium' },
  { value: 'high', key: 'govt.census.filters.risk.high' },
  { value: 'critical', key: 'govt.census.filters.risk.critical' },
]

export function CensusFilters({ value, onChange, resultCount }: Props) {
  const { t, number } = useI18n()
  const handle = <K extends keyof GovtCensusFilters>(key: K, next: GovtCensusFilters[K]) => {
    sfx.console_tap()
    onChange({ ...value, [key]: next })
  }

  return (
    <GovtCard variant="glass" padding="md" className="space-y-3">
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative min-w-[260px] flex-1">
          <Search
            size={15}
            strokeWidth={2}
            className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-govt-text-tertiary)]"
          />
          <input
            type="text"
            value={value.search}
            onChange={(e) => onChange({ ...value, search: e.target.value })}
            placeholder={t('govt.census.searchPlaceholder')}
            aria-label={t('govt.census.searchPlaceholder')}
            className="h-10 w-full rounded-2xl border border-[var(--color-govt-border)] bg-[oklch(0.06_0.008_252/0.55)] pl-9 pr-9 text-sm text-[var(--color-govt-text-primary)] placeholder:text-[var(--color-govt-text-tertiary)] outline-none transition-colors focus:border-[var(--color-govt-border-active)]"
          />
          {value.search.length > 0 ? (
            <button
              type="button"
              onClick={() => onChange({ ...value, search: '' })}
              aria-label={t('govt.census.searchClear')}
              className="absolute right-2 top-1/2 -translate-y-1/2 rounded-full p-1 text-[var(--color-govt-text-tertiary)] transition-colors hover:bg-white/[0.06] hover:text-[var(--color-govt-text-primary)]"
            >
              <X size={13} strokeWidth={2.2} />
            </button>
          ) : null}
        </div>
        <span className="text-xs uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
          {resultCount === undefined ? '—' : `${number(resultCount)} ${t('govt.census.list.totalCount')}`}
        </span>
      </div>

      <div className="grid gap-2 md:grid-cols-3">
        <ChipRow
          label={t('govt.census.filters.statusLabel')}
          options={STATUS_OPTIONS}
          selected={value.status}
          onSelect={(v) => handle('status', v)}
        />
        <ChipRow
          label={t('govt.census.filters.complianceLabel')}
          options={COMPLIANCE_OPTIONS}
          selected={value.compliance}
          onSelect={(v) => handle('compliance', v)}
        />
        <ChipRow
          label={t('govt.census.filters.riskLabel')}
          options={RISK_OPTIONS}
          selected={value.riskLevel}
          onSelect={(v) => handle('riskLevel', v)}
        />
      </div>
    </GovtCard>
  )
}

interface ChipRowProps<V extends string> {
  label: string
  options: Array<{ value: V; key: TranslationKey }>
  selected: V
  onSelect: (next: V) => void
}

function ChipRow<V extends string>({ label, options, selected, onSelect }: ChipRowProps<V>) {
  const { t } = useI18n()
  return (
    <div className="space-y-1.5">
      <span className="block text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
        {label}
      </span>
      <div className="flex flex-wrap gap-1.5">
        {options.map((opt) => {
          const active = opt.value === selected
          return (
            <button
              key={opt.value}
              type="button"
              onClick={() => onSelect(opt.value)}
              className={cn(
                'inline-flex h-7 items-center rounded-full border px-2.5 text-[11px] font-semibold uppercase tracking-[0.10em] transition-all',
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
