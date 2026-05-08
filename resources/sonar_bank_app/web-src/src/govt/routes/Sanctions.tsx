import { useEffect, useState } from 'react'
import { motion } from 'motion/react'
import { Loader2, Scale, ScanSearch } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { useAceGate } from '@/components/security'
import { ACE_PERMS } from '@/lib/ace'
import { GovtCard } from '../components/GovtCard'
import { GovtPill } from '../components/GovtPill'
import { FlagQueue } from './sanctions/FlagQueue'
import { FlagDetail } from './sanctions/FlagDetail'
import {
  useFlagDetailQuery,
  useFlagQueueQuery,
  useSanctionKpisQuery,
} from '../data/queries/govtSanctions'
import type { GovtFlagQueueFilters } from '../data/contracts'

const INITIAL_FILTERS: GovtFlagQueueFilters = {
  search: '',
  severity: 'all',
  status: 'all',
}

export function Sanctions() {
  const { t, number } = useI18n()
  const granted = useAceGate({ require: ACE_PERMS.P10.perm })

  const [filters, setFilters] = useState<GovtFlagQueueFilters>(INITIAL_FILTERS)
  const [selectedFlagId, setSelectedFlagId] = useState<string | null>(null)

  const queueQuery = useFlagQueueQuery(filters)
  const detailQuery = useFlagDetailQuery(granted ? selectedFlagId : null)
  const kpisQuery = useSanctionKpisQuery()
  const flags = queueQuery.data ?? []

  useEffect(() => {
    if (!granted) return
    if (selectedFlagId && flags.some((f) => f.flagId === selectedFlagId)) return
    setSelectedFlagId(flags[0]?.flagId ?? null)
  }, [granted, flags, selectedFlagId])

  if (!granted) {
    return <PermissionDenied />
  }

  return (
    <div className="flex h-full flex-col gap-3 pt-1">
      <motion.header
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.25 }}
        className="flex flex-wrap items-center justify-between gap-3"
      >
        <div className="flex items-center gap-3">
          <span
            aria-hidden
            className="flex h-9 w-9 items-center justify-center rounded-2xl"
            style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}
          >
            <Scale size={16} strokeWidth={1.9} />
          </span>
          <div>
            <h1 className="text-lg font-semibold tracking-[-0.02em] text-[var(--color-govt-text-primary)]">{t('govt.sanctions.title')}</h1>
            <p className="text-xs text-[var(--color-govt-text-tertiary)]">{t('govt.sanctions.subtitle')}</p>
          </div>
        </div>
        <div className="flex flex-wrap items-center gap-1.5">
          {kpisQuery.data ? (
            <>
              <GovtPill tone="warning" size="xs">{`${number(kpisQuery.data.open)} ${t('govt.sanctions.kpi.open')}`}</GovtPill>
              <GovtPill tone="danger" size="xs">{`${number(kpisQuery.data.critical)} ${t('govt.sanctions.kpi.critical')}`}</GovtPill>
              <GovtPill tone="accent" size="xs">{`${number(kpisQuery.data.today)} ${t('govt.sanctions.kpi.today')}`}</GovtPill>
              <GovtPill tone="neutral" size="xs">{`${number(kpisQuery.data.total)} ${t('govt.sanctions.kpi.total')}`}</GovtPill>
            </>
          ) : null}
        </div>
      </motion.header>

      <div className="grid min-h-0 flex-1 gap-3 lg:grid-cols-[minmax(320px,0.4fr)_minmax(0,0.6fr)]">
        <FlagQueue
          filters={filters}
          onFiltersChange={setFilters}
          flags={flags}
          selectedFlagId={selectedFlagId}
          onSelect={setSelectedFlagId}
          isLoading={queueQuery.isLoading}
        />

        <div className="min-h-0">
          {detailQuery.data ? (
            <FlagDetail flag={detailQuery.data} />
          ) : detailQuery.isLoading && selectedFlagId ? (
            <DetailLoading />
          ) : (
            <FlagEmptyState />
          )}
        </div>
      </div>
    </div>
  )
}

function FlagEmptyState() {
  const { t } = useI18n()
  return (
    <GovtCard variant="outline" padding="lg" className="flex h-full flex-col items-center justify-center gap-4 text-center">
      <span
        aria-hidden
        className="flex h-16 w-16 items-center justify-center rounded-full border"
        style={{
          background: 'var(--color-govt-accent-subtle)',
          borderColor: 'var(--color-govt-border-strong)',
          color: 'var(--color-govt-accent-light)',
        }}
      >
        <Scale size={26} strokeWidth={1.6} />
      </span>
      <div className="max-w-sm">
        <p className="text-sm font-semibold text-[var(--color-govt-text-primary)]">{t('govt.sanctions.empty.title')}</p>
        <p className="mt-1.5 text-xs leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.sanctions.empty.hint')}</p>
      </div>
    </GovtCard>
  )
}

function DetailLoading() {
  return (
    <GovtCard variant="outline" padding="lg" className="flex h-full flex-col items-center justify-center gap-3 text-[var(--color-govt-text-tertiary)]" aria-busy="true">
      <Loader2 size={20} className="animate-spin" />
      <span className="text-[11px] uppercase tracking-[0.16em]">Resolving flag…</span>
    </GovtCard>
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
        <p className="text-xs leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.sanctions.permissionHint')}</p>
      </GovtCard>
    </div>
  )
}
