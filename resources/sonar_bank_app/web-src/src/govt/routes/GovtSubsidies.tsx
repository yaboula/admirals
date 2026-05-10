import { useEffect, useState } from 'react'
import { motion } from 'motion/react'
import { HandCoins, Loader2, ScanSearch, Sprout } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { useAceGate } from '@/components/security'
import { ACE_PERMS } from '@/lib/ace'
import { usePrivacyMode } from '@/stores/privacy'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { GovtCard } from '../components/GovtCard'
import { SubsidyFilters } from './subsidies/SubsidyFilters'
import { SubsidyRow } from './subsidies/SubsidyRow'
import { SubsidyDetail } from './subsidies/SubsidyDetail'
import {
  useGovtSubsidyDetailQuery,
  useGovtSubsidyListQuery,
  useGovtSubsidyStatsQuery,
} from '../data/queries/govtSubsidies'
import type { GovtSubsidyFilters } from '../data/contracts'

const INITIAL_FILTERS: GovtSubsidyFilters = {
  search: '',
  type: 'all',
  status: 'all',
}

export function GovtSubsidies() {
  const { t, money, number } = useI18n()
  const granted = useAceGate({ require: ACE_PERMS.P04.perm })
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  const [filters, setFilters] = useState<GovtSubsidyFilters>(INITIAL_FILTERS)
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const statsQuery = useGovtSubsidyStatsQuery()
  const listQuery = useGovtSubsidyListQuery(granted ? filters : INITIAL_FILTERS)
  const detailQuery = useGovtSubsidyDetailQuery(granted ? selectedId : null)

  const list = listQuery.data ?? []
  const stats = statsQuery.data

  useEffect(() => {
    if (!granted) return
    if (selectedId && list.some((p) => p.programId === selectedId)) return
    setSelectedId(list[0]?.programId ?? null)
  }, [granted, list, selectedId])

  const m = (v: number) => (streamerMode ? maskMoneyDisplay() : money(v))

  if (!granted) return <PermissionDenied />

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
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div
              className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-2xl border"
              style={{ background: 'rgba(0,1,3,0.7)', borderColor: 'var(--color-govt-border-strong)', color: 'var(--color-govt-accent-light)' }}
              aria-hidden
            >
              <Sprout size={16} strokeWidth={1.8} />
            </div>
            <div>
              <h1 className="text-base font-semibold tracking-[-0.02em] text-[var(--color-govt-text-primary)]">{t('govt.subsidies.title')}</h1>
              <p className="text-[11px] text-[var(--color-govt-text-tertiary)]">{t('govt.subsidies.subtitle')}</p>
            </div>
          </div>

          {stats ? (
            <div className="flex flex-wrap items-center gap-3 text-[11px]">
              <InlineStat value={number(stats.activeProgramCount)} label={t('govt.subsidies.stats.activePrograms')} color="rgb(51, 204, 125)" />
              <span aria-hidden className="text-[var(--color-govt-text-quaternary)]">·</span>
              <InlineStat value={m(stats.totalDisbursed)} label={t('govt.subsidies.stats.totalDisbursed')} color="rgb(76, 209, 238)" />
              <span aria-hidden className="text-[var(--color-govt-text-quaternary)]">·</span>
              <InlineStat value={number(stats.totalBeneficiaries)} label={t('govt.subsidies.stats.beneficiaries')} color="var(--color-govt-text-secondary)" />
              {stats.pendingDisbursements > 0 ? (
                <>
                  <span aria-hidden className="text-[var(--color-govt-text-quaternary)]">·</span>
                  <InlineStat value={number(stats.pendingDisbursements)} label={t('govt.subsidies.stats.pending')} color="rgb(248, 198, 85)" />
                </>
              ) : null}
            </div>
          ) : null}
        </div>

        <SubsidyFilters
          value={filters}
          onChange={(next) => { setFilters(next); setSelectedId(null) }}
          resultCount={listQuery.isLoading ? undefined : list.length}
        />
      </motion.header>

      <div className="grid min-h-0 flex-1 gap-4 lg:grid-cols-[minmax(280px,0.40fr)_minmax(0,0.60fr)]">
        <GovtCard variant="glass" padding="none" className="flex min-h-0 flex-col overflow-hidden">
          <div className="flex items-center justify-between border-b border-[var(--color-govt-border)] px-4 py-2.5">
            <span className="text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
              {t('govt.subsidies.list.header')}
            </span>
            <span className="text-[10px] uppercase tracking-[0.10em] text-[var(--color-govt-text-quaternary)]">
              {t('govt.subsidies.list.sortHint')}
            </span>
          </div>

          <div className="min-h-0 flex-1 overflow-y-auto px-3 pb-3 scrollbar-thin">
            {listQuery.isLoading ? (
              <ListLoading />
            ) : list.length === 0 ? (
              <ListEmpty />
            ) : (
              <ul className="space-y-2 pt-2">
                {list.map((program) => (
                  <li key={program.programId}>
                    <SubsidyRow
                      program={program}
                      active={program.programId === selectedId}
                      onSelect={setSelectedId}
                    />
                  </li>
                ))}
              </ul>
            )}
          </div>
        </GovtCard>

        <div className="min-h-0">
          {detailQuery.data ? (
            <SubsidyDetail detail={detailQuery.data} isFetching={detailQuery.isFetching} />
          ) : detailQuery.isLoading && selectedId ? (
            <GovtCard variant="outline" padding="lg" className="flex h-full flex-col items-center justify-center gap-3 text-[var(--color-govt-text-tertiary)]" aria-busy="true">
              <Loader2 size={20} className="animate-spin" />
              <span className="text-[11px] uppercase tracking-[0.16em]">Loading program…</span>
            </GovtCard>
          ) : (
            <EmptyDetail />
          )}
        </div>
      </div>
    </div>
  )
}

function InlineStat({ value, label, color }: { value: string; label: string; color: string }) {
  return (
    <span>
      <span className="font-semibold tabular-nums" style={{ color }}>{value}</span>
      {' '}
      <span className="uppercase tracking-[0.12em] text-[var(--color-govt-text-tertiary)]">{label}</span>
    </span>
  )
}

function ListLoading() {
  return (
    <div className="flex h-full flex-col items-center justify-center gap-3 py-10 text-[var(--color-govt-text-tertiary)]" aria-busy="true">
      <Loader2 size={18} className="animate-spin" />
      <span className="text-[11px] uppercase tracking-[0.16em]">Loading…</span>
    </div>
  )
}

function ListEmpty() {
  const { t } = useI18n()
  return (
    <div className="flex h-full flex-col items-center justify-center gap-3 py-10 text-center">
      <span aria-hidden className="flex h-12 w-12 items-center justify-center rounded-full" style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}>
        <ScanSearch size={20} strokeWidth={1.6} />
      </span>
      <p className="max-w-[28ch] text-xs leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.subsidies.list.noResults')}</p>
    </div>
  )
}

function EmptyDetail() {
  const { t } = useI18n()
  return (
    <GovtCard variant="outline" padding="lg" className="flex h-full flex-col items-center justify-center gap-4 text-center">
      <span aria-hidden className="flex h-14 w-14 items-center justify-center rounded-full border" style={{ background: 'var(--color-govt-accent-subtle)', borderColor: 'var(--color-govt-border-strong)', color: 'var(--color-govt-accent-light)' }}>
        <HandCoins size={22} strokeWidth={1.6} />
      </span>
      <div className="max-w-[28ch]">
        <p className="text-sm font-semibold text-[var(--color-govt-text-primary)]">{t('govt.subsidies.detail.empty')}</p>
        <p className="mt-1.5 text-[11px] leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.subsidies.detail.emptyHint')}</p>
      </div>
    </GovtCard>
  )
}

function PermissionDenied() {
  const { t } = useI18n()
  return (
    <div className="flex h-full items-center justify-center p-4">
      <GovtCard variant="outline" padding="lg" className={cn('flex max-w-md flex-col items-center gap-3 text-center')}>
        <span aria-hidden className="flex h-12 w-12 items-center justify-center rounded-full" style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}>
          <ScanSearch size={20} strokeWidth={1.6} />
        </span>
        <p className="text-sm font-semibold text-[var(--color-govt-text-primary)]">{t('nav.permissionRequired')}</p>
        <p className="text-xs leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.subsidies.permissionHint')}</p>
      </GovtCard>
    </div>
  )
}
