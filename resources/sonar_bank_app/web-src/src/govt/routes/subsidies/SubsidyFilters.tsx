import { Search, X } from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import type { GovtSubsidyFilters, GovtSubsidyStatus, GovtSubsidyType } from '../../data/contracts'

interface Props {
  value: GovtSubsidyFilters
  onChange: (next: GovtSubsidyFilters) => void
  resultCount: number | undefined
}

const STATUS_OPTIONS: Array<{ value: GovtSubsidyStatus | 'all'; key: TranslationKey }> = [
  { value: 'all',       key: 'govt.subsidies.filters.status.all' },
  { value: 'active',    key: 'govt.subsidies.status.active' },
  { value: 'paused',    key: 'govt.subsidies.status.paused' },
  { value: 'proposed',  key: 'govt.subsidies.status.proposed' },
  { value: 'completed', key: 'govt.subsidies.status.completed' },
]

const TYPE_OPTIONS: Array<{ value: GovtSubsidyType | 'all'; key: TranslationKey }> = [
  { value: 'all',          key: 'govt.subsidies.filters.type.all' },
  { value: 'food',         key: 'govt.subsidies.type.food' },
  { value: 'housing',      key: 'govt.subsidies.type.housing' },
  { value: 'employment',   key: 'govt.subsidies.type.employment' },
  { value: 'medical',      key: 'govt.subsidies.type.medical' },
  { value: 'education',    key: 'govt.subsidies.type.education' },
  { value: 'emergency',    key: 'govt.subsidies.type.emergency' },
  { value: 'agricultural', key: 'govt.subsidies.type.agricultural' },
]

export function SubsidyFilters({ value, onChange, resultCount }: Props) {
  const { t, number } = useI18n()
  const handle = <K extends keyof GovtSubsidyFilters>(key: K, val: GovtSubsidyFilters[K]) => {
    sfx.console_tap()
    onChange({ ...value, [key]: val })
  }

  return (
    <div className="flex min-w-0 flex-wrap items-center gap-x-2 gap-y-1.5">
      <div className="relative min-w-[180px]">
        <Search size={13} strokeWidth={2} className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-[var(--color-govt-text-tertiary)]" />
        <input
          type="text"
          value={value.search}
          onChange={(e) => onChange({ ...value, search: e.target.value })}
          placeholder={t('govt.subsidies.searchPlaceholder')}
          aria-label={t('govt.subsidies.searchPlaceholder')}
          className="h-8 w-full rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.06_0.008_252/0.55)] pl-7 pr-7 text-[12px] text-[var(--color-govt-text-primary)] placeholder:text-[var(--color-govt-text-tertiary)] outline-none transition-colors focus:border-[var(--color-govt-border-active)]"
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
      <ChipGroup options={TYPE_OPTIONS} selected={value.type} onSelect={(v) => handle('type', v)} />

      {resultCount !== undefined ? (
        <span className="ml-1 text-[10px] uppercase tracking-[0.14em] text-[var(--color-govt-text-quaternary)]">
          {`${number(resultCount)} ${t('govt.subsidies.list.totalCount')}`}
        </span>
      ) : null}
    </div>
  )
}

function Divider() {
  return <span aria-hidden className="hidden h-3.5 w-px bg-[oklch(1_0_0/0.10)] sm:block" />
}

function ChipGroup<V extends string>({
  options, selected, onSelect,
}: {
  options: Array<{ value: V; key: TranslationKey }>
  selected: V
  onSelect: (v: V) => void
}) {
  const { t } = useI18n()
  return (
    <div className="flex flex-wrap gap-1">
      {options.map((opt) => {
        const active = opt.value === selected
        return (
          <button key={opt.value} type="button" onClick={() => onSelect(opt.value)}
            className={cn(
              'inline-flex h-6 items-center rounded-full border px-2 text-[10px] font-semibold uppercase tracking-[0.10em] transition-all',
              active
                ? 'border-[var(--color-govt-border-active)] bg-[var(--color-govt-accent-soft)] text-[var(--color-govt-accent-light)]'
                : 'border-[var(--color-govt-border)] bg-transparent text-[var(--color-govt-text-tertiary)] hover:border-[var(--color-govt-border-strong)] hover:text-[var(--color-govt-text-secondary)]',
            )}>
            {t(opt.key)}
          </button>
        )
      })}
    </div>
  )
}
