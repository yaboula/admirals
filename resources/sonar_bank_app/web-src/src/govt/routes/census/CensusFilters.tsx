import { Search, X } from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
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
    <div className="flex min-w-0 flex-wrap items-center gap-x-2 gap-y-1.5">
      <div className="relative min-w-[180px]">
        <Search size={13} strokeWidth={2} className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-[var(--color-govt-text-tertiary)]" />
        <input
          type="text"
          value={value.search}
          onChange={(e) => onChange({ ...value, search: e.target.value })}
          placeholder={t('govt.census.searchPlaceholder')}
          aria-label={t('govt.census.searchPlaceholder')}
          className="h-8 w-full rounded-xl border border-[var(--color-govt-border)] bg-[rgba(0,1,1,0.55)] pl-7 pr-7 text-[12px] text-[var(--color-govt-text-primary)] placeholder:text-[var(--color-govt-text-tertiary)] outline-none transition-colors focus:border-[var(--color-govt-border-active)]"
        />
        {value.search.length > 0 ? (
          <button type="button" onClick={() => onChange({ ...value, search: '' })} aria-label={t('govt.census.searchClear')}
            className="absolute right-1.5 top-1/2 -translate-y-1/2 rounded-full p-0.5 text-[var(--color-govt-text-tertiary)] hover:text-[var(--color-govt-text-primary)]">
            <X size={11} strokeWidth={2.4} />
          </button>
        ) : null}
      </div>

      <Divider />

      <ChipGroup options={STATUS_OPTIONS} selected={value.status} onSelect={(v) => handle('status', v)} />

      <Divider />

      <ChipGroup options={COMPLIANCE_OPTIONS} selected={value.compliance} onSelect={(v) => handle('compliance', v)} />

      <Divider />

      <ChipGroup options={RISK_OPTIONS} selected={value.riskLevel} onSelect={(v) => handle('riskLevel', v)} />

      {resultCount !== undefined ? (
        <span className="ml-1 text-[10px] uppercase tracking-[0.14em] text-[var(--color-govt-text-quaternary)]">
          {`${number(resultCount)} ${t('govt.census.list.totalCount')}`}
        </span>
      ) : null}
    </div>
  )
}

function Divider() {
  return <span aria-hidden className="hidden h-3.5 w-px bg-[rgba(255,255,255,0.1)] sm:block" />
}

function ChipGroup<V extends string>({
  options,
  selected,
  onSelect,
}: {
  options: Array<{ value: V; key: TranslationKey }>
  selected: V
  onSelect: (next: V) => void
}) {
  const { t } = useI18n()
  return (
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
                : 'border-[var(--color-govt-border)] bg-transparent text-[var(--color-govt-text-tertiary)] hover:border-[var(--color-govt-border-strong)] hover:text-[var(--color-govt-text-secondary)]',
            )}
          >
            {t(opt.key)}
          </button>
        )
      })}
    </div>
  )
}
