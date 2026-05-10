import { useEffect, useMemo, useState } from 'react'
import { motion } from 'motion/react'
import { Loader2, ScanSearch, Users } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { useAceGate } from '@/components/security'
import { ACE_PERMS } from '@/lib/ace'
import { cn } from '@/lib/utils'
import { GovtCard } from '../components/GovtCard'
import { CensusFilters } from './census/CensusFilters'
import { CitizenRow } from './census/CitizenRow'
import { CitizenDetail } from './census/CitizenDetail'
import { CitizenEmptyState } from './census/CitizenEmptyState'
import {
  useGovtCensusListQuery,
  useGovtCitizenDetailQuery,
} from '../data/queries/govtCensus'
import type { GovtCensusFilters } from '../data/contracts'

const INITIAL_FILTERS: GovtCensusFilters = {
  search: '',
  status: 'all',
  compliance: 'all',
  riskLevel: 'all',
}

export function Census() {
  const { t, number } = useI18n()
  const granted = useAceGate({ require: ACE_PERMS.P04.perm })

  const [filters, setFilters] = useState<GovtCensusFilters>(INITIAL_FILTERS)
  const [selectedCid, setSelectedCid] = useState<string | null>(null)

  const listQuery = useGovtCensusListQuery(filters)
  const detailQuery = useGovtCitizenDetailQuery(granted ? selectedCid : null)
  const list = listQuery.data ?? []

  useEffect(() => {
    if (!granted) return
    if (selectedCid && list.some((c) => c.cid === selectedCid)) return
    setSelectedCid(list[0]?.cid ?? null)
  }, [granted, list, selectedCid])

  const totalsByStatus = useMemo(() => {
    const counts = { active: 0, flagged: 0, sanctioned: 0, exempt: 0 }
    for (const c of list) counts[c.status] += 1
    return counts
  }, [list])

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
        className="relative space-y-2.5 border-b pb-3"
        style={{ borderColor: 'var(--color-govt-border)', zIndex: 1 }}
      >
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div
              className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-2xl border"
              style={{ background: 'rgba(0,1,3,0.7)', borderColor: 'var(--color-govt-border-strong)', color: 'var(--color-govt-accent-light)' }}
              aria-hidden
            >
              <Users size={16} strokeWidth={1.8} />
            </div>
            <div>
              <h1 className="text-base font-semibold tracking-[-0.02em] text-[var(--color-govt-text-primary)]">{t('govt.census.title')}</h1>
              <p className="text-[11px] text-[var(--color-govt-text-tertiary)]">{t('govt.census.subtitle')}</p>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-3 text-[11px]">
            <InlineStat value={number(totalsByStatus.active)} label={t('govt.census.status.active')} color="rgb(34, 195, 115)" />
            <span aria-hidden className="text-[var(--color-govt-text-quaternary)]">·</span>
            <InlineStat value={number(totalsByStatus.flagged)} label={t('govt.census.status.flagged')} color="rgb(238, 188, 74)" />
            <span aria-hidden className="text-[var(--color-govt-text-quaternary)]">·</span>
            <InlineStat value={number(totalsByStatus.sanctioned)} label={t('govt.census.status.sanctioned')} color="rgb(255, 138, 130)" />
            <span aria-hidden className="text-[var(--color-govt-text-quaternary)]">·</span>
            <InlineStat value={number(totalsByStatus.exempt)} label={t('govt.census.status.exempt')} color="var(--color-govt-text-tertiary)" />
          </div>
        </div>
        <CensusFilters
          value={filters}
          onChange={setFilters}
          resultCount={listQuery.isLoading ? undefined : list.length}
        />
      </motion.header>

      <div className="grid min-h-0 flex-1 gap-4 lg:grid-cols-[minmax(300px,0.42fr)_minmax(0,0.58fr)]">
        <GovtCard variant="glass" padding="none" className="flex min-h-0 flex-col overflow-hidden">
          <ListHeader />
          <div className="min-h-0 flex-1 overflow-y-auto px-3 pb-3 scrollbar-thin">
            {listQuery.isLoading ? (
              <ListLoading />
            ) : list.length === 0 ? (
              <ListEmpty />
            ) : (
              <ul className="space-y-2 pt-2">
                {list.map((citizen) => (
                  <li key={citizen.cid}>
                    <CitizenRow
                      citizen={citizen}
                      active={citizen.cid === selectedCid}
                      onSelect={setSelectedCid}
                    />
                  </li>
                ))}
              </ul>
            )}
          </div>
        </GovtCard>

        <div className="min-h-0">
          {detailQuery.data ? (
            <CitizenDetail detail={detailQuery.data} isFetching={detailQuery.isFetching} />
          ) : detailQuery.isLoading && selectedCid ? (
            <DetailLoading />
          ) : (
            <CitizenEmptyState />
          )}
        </div>
      </div>
    </div>
  )
}

function ListHeader() {
  const { t } = useI18n()
  return (
    <div className="flex items-center justify-between gap-2 border-b border-[var(--color-govt-border)] px-4 py-3">
      <span className="text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
        {t('govt.census.list.header')}
      </span>
      <span className="text-[10px] uppercase tracking-[0.14em] text-[var(--color-govt-text-quaternary)]">
        {t('govt.census.list.sortHint')}
      </span>
    </div>
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
      <p className="max-w-[28ch] text-xs leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.census.list.noResults')}</p>
    </div>
  )
}

function DetailLoading() {
  return (
    <GovtCard variant="outline" padding="lg" className="flex h-full flex-col items-center justify-center gap-3 text-[var(--color-govt-text-tertiary)]" aria-busy="true">
      <Loader2 size={20} className="animate-spin" />
      <span className="text-[11px] uppercase tracking-[0.16em]">Resolving citizen…</span>
    </GovtCard>
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

function PermissionDenied() {
  const { t } = useI18n()
  return (
    <div className="flex h-full items-center justify-center p-4">
      <GovtCard variant="outline" padding="lg" className={cn('flex max-w-md flex-col items-center gap-3 text-center')}>
        <span aria-hidden className="flex h-12 w-12 items-center justify-center rounded-full" style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}>
          <ScanSearch size={20} strokeWidth={1.6} />
        </span>
        <p className="text-sm font-semibold text-[var(--color-govt-text-primary)]">{t('nav.permissionRequired')}</p>
        <p className="text-xs leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.census.permissionHint')}</p>
      </GovtCard>
    </div>
  )
}
