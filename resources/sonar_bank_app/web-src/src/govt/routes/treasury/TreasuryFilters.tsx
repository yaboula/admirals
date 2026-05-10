import { Search, X } from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import type {
  GovtMovementEntityKind,
  GovtMovementType,
  GovtTreasuryDateRange,
  GovtTreasuryFilters,
} from '../../data/contracts'

interface Props {
  value: GovtTreasuryFilters
  onChange: (next: GovtTreasuryFilters) => void
  totalCount: number | undefined
}

const DATE_RANGE_OPTIONS: Array<{ value: GovtTreasuryDateRange; key: TranslationKey }> = [
  { value: 'today',   key: 'govt.treasury.range.today' },
  { value: 'week',    key: 'govt.treasury.range.week' },
  { value: 'month',   key: 'govt.treasury.range.month' },
  { value: 'quarter', key: 'govt.treasury.range.quarter' },
]

const TYPE_OPTIONS: Array<{ value: GovtMovementType | 'all'; key: TranslationKey }> = [
  { value: 'all',                 key: 'govt.treasury.type.all' },
  { value: 'tax_collection',      key: 'govt.treasury.type.tax_collection' },
  { value: 'fine_collected',      key: 'govt.treasury.type.fine_collected' },
  { value: 'transfer_in',         key: 'govt.treasury.type.transfer_in' },
  { value: 'transfer_out',        key: 'govt.treasury.type.transfer_out' },
  { value: 'payroll_disbursement',key: 'govt.treasury.type.payroll_disbursement' },
  { value: 'subsidy_issued',      key: 'govt.treasury.type.subsidy_issued' },
  { value: 'reconciliation',      key: 'govt.treasury.type.reconciliation' },
]

const ENTITY_OPTIONS: Array<{ value: GovtMovementEntityKind | 'all'; key: TranslationKey }> = [
  { value: 'all',     key: 'govt.treasury.entity.all' },
  { value: 'citizen', key: 'govt.treasury.entity.citizen' },
  { value: 'company', key: 'govt.treasury.entity.company' },
  { value: 'system',  key: 'govt.treasury.entity.system' },
]

const DIR_OPTIONS: Array<{ value: 'all' | 'inflow' | 'outflow'; key: TranslationKey }> = [
  { value: 'all',     key: 'govt.treasury.dir.all' },
  { value: 'inflow',  key: 'govt.treasury.dir.inflow' },
  { value: 'outflow', key: 'govt.treasury.dir.outflow' },
]

export function TreasuryFilters({ value, onChange, totalCount }: Props) {
  const { t, number } = useI18n()
  const handle = <K extends keyof GovtTreasuryFilters>(key: K, next: GovtTreasuryFilters[K]) => {
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
          placeholder={t('govt.treasury.searchPlaceholder')}
          aria-label={t('govt.treasury.searchPlaceholder')}
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
      <ChipGroup options={DATE_RANGE_OPTIONS} selected={value.dateRange} onSelect={(v) => handle('dateRange', v)} />
      <Divider />
      <ChipGroup options={TYPE_OPTIONS} selected={value.type} onSelect={(v) => handle('type', v)} />
      <Divider />
      <ChipGroup options={ENTITY_OPTIONS} selected={value.entityKind} onSelect={(v) => handle('entityKind', v)} />
      <Divider />
      <ChipGroup options={DIR_OPTIONS} selected={value.direction} onSelect={(v) => handle('direction', v)} />

      {totalCount !== undefined ? (
        <span className="ml-1 text-[10px] uppercase tracking-[0.14em] text-[var(--color-govt-text-quaternary)]">
          {`${number(totalCount)} ${t('govt.treasury.list.totalCount')}`}
        </span>
      ) : null}
    </div>
  )
}

function Divider() {
  return <span aria-hidden className="hidden h-3.5 w-px bg-[rgba(255,255,255,0.1)] lg:block" />
}

function ChipGroup<V extends string>({
  options, selected, onSelect,
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
