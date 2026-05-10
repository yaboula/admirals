import { useState } from 'react'
import { motion } from 'motion/react'
import { ArrowDownLeft, ArrowUpRight, Banknote, ChevronLeft, ChevronRight, Coins, Loader2, ScanSearch, TrendingUp } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { useAceGate } from '@/components/security'
import { ACE_PERMS } from '@/lib/ace'
import { usePrivacyMode } from '@/stores/privacy'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { GovtCard } from '../components/GovtCard'
import { TreasuryFilters } from './treasury/TreasuryFilters'
import { MovementRow } from './treasury/MovementRow'
import { useGovtTreasuryQuery, PER_PAGE } from '../data/queries/govtTreasury'
import type { GovtTreasuryFilters } from '../data/contracts'

const INITIAL_FILTERS: GovtTreasuryFilters = {
  search: '',
  type: 'all',
  entityKind: 'all',
  dateRange: 'month',
  direction: 'all',
}

export function GovtTreasury() {
  const { t, money, number } = useI18n()
  const granted = useAceGate({ require: ACE_PERMS.P04.perm })
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  const [filters, setFilters] = useState<GovtTreasuryFilters>(INITIAL_FILTERS)
  const [page, setPage] = useState(0)

  const handleFilterChange = (next: GovtTreasuryFilters) => {
    setFilters(next)
    setPage(0)
  }

  const query = useGovtTreasuryQuery(granted ? filters : INITIAL_FILTERS, page)
  const data = query.data
  const stats = data?.stats
  const totalPages = data ? Math.ceil(data.totalCount / PER_PAGE) : 0

  const m = (val: number) => streamerMode ? maskMoneyDisplay() : money(val)

  if (!granted) {
    return <PermissionDenied />
  }

  return (
    <div className="relative flex h-full flex-col gap-3 pt-2">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 -top-4 h-56"
        style={{ background: 'radial-gradient(ellipse 90% 55% at 50% 0%, rgba(0,113,214,0.07), transparent)', zIndex: 0 }}
      />

      <motion.header
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.25 }}
        className="relative space-y-3 border-b pb-3"
        style={{ borderColor: 'var(--color-govt-border)', zIndex: 1 }}
      >
        <div className="flex items-center gap-3">
          <div
            className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-2xl border"
            style={{ background: 'rgba(0,1,3,0.7)', borderColor: 'var(--color-govt-border-strong)', color: 'var(--color-govt-accent-light)' }}
            aria-hidden
          >
            <Banknote size={16} strokeWidth={1.8} />
          </div>
          <div>
            <h1 className="text-base font-semibold tracking-[-0.02em] text-[var(--color-govt-text-primary)]">{t('govt.treasury.title')}</h1>
            <p className="text-[11px] text-[var(--color-govt-text-tertiary)]">{t('govt.treasury.subtitle')}</p>
          </div>
        </div>

        {stats ? (
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-7">
            <StatPill icon={ArrowDownLeft} label={t('govt.treasury.stats.inflow')} value={m(stats.totalInflow)} tone="inflow" />
            <StatPill icon={ArrowUpRight} label={t('govt.treasury.stats.outflow')} value={m(stats.totalOutflow)} tone="outflow" />
            <StatPill icon={Banknote} label={t('govt.treasury.stats.netBalance')} value={m(stats.netBalance)} tone={stats.netBalance >= 0 ? 'inflow' : 'outflow'} />
            <StatPill icon={TrendingUp} label={t('govt.treasury.stats.count')} value={number(stats.movementCount)} tone="neutral" />
            <StatPill icon={Coins} label={t('govt.treasury.stats.taxCollected')} value={m(stats.taxCollected)} tone="neutral" />
            <StatPill icon={ScanSearch} label={t('govt.treasury.stats.fines')} value={m(stats.finesCollected)} tone="neutral" />
            <StatPill icon={TrendingUp} label={t('govt.treasury.stats.subsidies')} value={m(stats.subsidiesIssued)} tone="neutral" />
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-7">
            {Array.from({ length: 7 }, (_, i) => (
              <div key={i} className="h-14 animate-pulse rounded-xl bg-white/[0.04]" />
            ))}
          </div>
        )}

        <TreasuryFilters
          value={filters}
          onChange={handleFilterChange}
          totalCount={data?.totalCount}
        />
      </motion.header>

      <GovtCard variant="glass" padding="none" className="flex min-h-0 flex-1 flex-col overflow-hidden">
        <div className="flex items-center justify-between border-b border-[var(--color-govt-border)] px-4 py-2.5">
          <span className="text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
            {t('govt.treasury.list.header')}
          </span>
          {query.isFetching ? (
            <Loader2 size={12} className="animate-spin text-[var(--color-govt-text-tertiary)]" />
          ) : null}
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto scrollbar-thin">
          {query.isLoading ? (
            <TableLoading />
          ) : !data || data.items.length === 0 ? (
            <TableEmpty />
          ) : (
            <table className="w-full min-w-[640px] border-collapse text-left">
              <thead className="sticky top-0 z-10" style={{ background: 'rgba(0,0,1,0.95)' }}>
                <tr className="border-b border-[var(--color-govt-border)]">
                  <th className="py-2 pl-4 pr-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{t('govt.treasury.col.type')}</th>
                  <th className="px-2 py-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{t('govt.treasury.col.entity')}</th>
                  <th className="px-2 py-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{t('govt.treasury.col.timestamp')}</th>
                  <th className="px-2 py-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{t('govt.treasury.col.status')}</th>
                  <th className="py-2 pl-2 pr-4 text-right text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{t('govt.treasury.col.amount')}</th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((movement, i) => (
                  <MovementRow key={movement.id} movement={movement} index={i} />
                ))}
              </tbody>
            </table>
          )}
        </div>

        {totalPages > 1 ? (
          <div className="flex items-center justify-between border-t border-[var(--color-govt-border)] px-4 py-2.5">
            <span className="text-[11px] text-[var(--color-govt-text-tertiary)]">
              {`${t('govt.treasury.pagination.page')} ${number(page + 1)} / ${number(totalPages)}`}
            </span>
            <div className="flex gap-1">
              <PagBtn onClick={() => { sfx.console_tap(); setPage((p) => Math.max(0, p - 1)) }} disabled={page === 0} icon={ChevronLeft} label="Previous" />
              <PagBtn onClick={() => { sfx.console_tap(); setPage((p) => Math.min(totalPages - 1, p + 1)) }} disabled={page >= totalPages - 1} icon={ChevronRight} label="Next" />
            </div>
          </div>
        ) : null}
      </GovtCard>
    </div>
  )
}

function StatPill({ icon: Icon, label, value, tone }: { icon: typeof Banknote; label: string; value: string; tone: 'inflow' | 'outflow' | 'neutral' }) {
  const color = tone === 'inflow' ? 'rgb(51, 204, 125)' : tone === 'outflow' ? 'rgb(76, 209, 238)' : 'var(--color-govt-text-secondary)'
  return (
    <div className="flex flex-col gap-1 rounded-xl border border-[var(--color-govt-border)] bg-[rgba(0,0,1,0.7)] p-2.5">
      <div className="flex items-center gap-1.5">
        <Icon size={10} strokeWidth={2} style={{ color }} aria-hidden />
        <span className="text-[9px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{label}</span>
      </div>
      <span className="truncate text-sm font-semibold tabular-nums tracking-[-0.02em]" style={{ color }}>{value}</span>
    </div>
  )
}

function PagBtn({ onClick, disabled, icon: Icon, label }: { onClick: () => void; disabled: boolean; icon: typeof ChevronLeft; label: string }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-label={label}
      className={cn(
        'flex h-7 w-7 items-center justify-center rounded-xl border transition-colors',
        disabled
          ? 'cursor-not-allowed border-[var(--color-govt-border)] text-[var(--color-govt-text-quaternary)]'
          : 'border-[var(--color-govt-border-strong)] text-[var(--color-govt-text-secondary)] hover:bg-[var(--color-govt-accent-soft)]',
      )}
    >
      <Icon size={13} strokeWidth={2} />
    </button>
  )
}

function TableLoading() {
  return (
    <div className="flex h-40 flex-col items-center justify-center gap-3 text-[var(--color-govt-text-tertiary)]" aria-busy="true">
      <Loader2 size={18} className="animate-spin" />
      <span className="text-[11px] uppercase tracking-[0.16em]">Loading ledger…</span>
    </div>
  )
}

function TableEmpty() {
  const { t } = useI18n()
  return (
    <div className="flex h-40 flex-col items-center justify-center gap-3 text-center text-[var(--color-govt-text-tertiary)]">
      <span aria-hidden className="flex h-12 w-12 items-center justify-center rounded-full" style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}>
        <ScanSearch size={20} strokeWidth={1.6} />
      </span>
      <p className="max-w-[32ch] text-xs leading-relaxed">{t('govt.treasury.list.noResults')}</p>
    </div>
  )
}

function PermissionDenied() {
  const { t } = useI18n()
  return (
    <div className="flex h-full items-center justify-center p-4">
      <GovtCard variant="outline" padding="lg" className="flex max-w-md flex-col items-center gap-3 text-center">
        <span aria-hidden className="flex h-12 w-12 items-center justify-center rounded-full" style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}>
          <ScanSearch size={20} strokeWidth={1.6} />
        </span>
        <p className="text-sm font-semibold text-[var(--color-govt-text-primary)]">{t('nav.permissionRequired')}</p>
        <p className="text-xs leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.treasury.permissionHint')}</p>
      </GovtCard>
    </div>
  )
}
