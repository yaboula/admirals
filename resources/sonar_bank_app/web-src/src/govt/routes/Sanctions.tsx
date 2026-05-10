import { useEffect, useState } from 'react'
import { motion } from 'motion/react'
import { Loader2, Scale, ScanSearch } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { useAceGate } from '@/components/security'
import { ACE_PERMS } from '@/lib/ace'
import { GovtCard } from '../components/GovtCard'
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
    <div className="relative flex h-full flex-col gap-4 pt-2">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 -top-4 h-56"
        style={{ background: 'radial-gradient(ellipse 90% 55% at 50% 0%, rgba(0,113,214,0.07), transparent)', zIndex: 0 }}
      />
      <motion.header
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.25 }}
        className="space-y-3 border-b pb-4"
        style={{ borderColor: 'var(--color-govt-border)' }}
      >
        <div className="flex items-center gap-3">
          <div
            className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-2xl border"
            style={{ background: 'var(--color-govt-glass)', borderColor: 'var(--color-govt-border-strong)', color: 'var(--color-govt-accent-light)' }}
            aria-hidden
          >
            <Scale size={17} strokeWidth={1.8} />
          </div>
          <div>
            <h1 className="text-base font-semibold tracking-[-0.02em] text-[var(--color-govt-text-primary)]">{t('govt.sanctions.title')}</h1>
            <p className="text-[11px] text-[var(--color-govt-text-tertiary)]">{t('govt.sanctions.subtitle')}</p>
          </div>
        </div>
        {kpisQuery.data ? (
          <div className="flex flex-wrap items-center gap-2">
            <KpiStrip label={t('govt.sanctions.kpi.open')} value={number(kpisQuery.data.open)} tone="warning" />
            <KpiStrip label={t('govt.sanctions.kpi.critical')} value={number(kpisQuery.data.critical)} tone="danger" />
            <KpiStrip label={t('govt.sanctions.kpi.today')} value={number(kpisQuery.data.today)} tone="accent" />
            <KpiStrip label={t('govt.sanctions.kpi.total')} value={number(kpisQuery.data.total)} tone="neutral" />
          </div>
        ) : null}
      </motion.header>

      <div className="grid min-h-0 flex-1 gap-4 lg:grid-cols-[minmax(300px,0.4fr)_minmax(0,0.6fr)]">
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

const KPI_STRIP_TONE: Record<string, { bg: string; border: string; fg: string }> = {
  warning: { bg: 'rgba(230,173,0,0.08)', border: 'rgba(230,173,0,0.22)', fg: 'rgb(252, 209, 118)' },
  danger:  { bg: 'rgba(234,60,63,0.08)',  border: 'rgba(234,60,63,0.22)',  fg: 'rgb(255, 190, 182)' },
  accent:  { bg: 'var(--color-govt-accent-subtle)', border: 'var(--color-govt-border-active)', fg: 'var(--color-govt-accent-light)' },
  neutral: { bg: 'rgba(255,255,255,0.04)', border: 'var(--color-govt-border)', fg: 'var(--color-govt-text-secondary)' },
}

function KpiStrip({ label, value, tone }: { label: string; value: string; tone: string }) {
  const c = KPI_STRIP_TONE[tone] ?? KPI_STRIP_TONE.neutral
  return (
    <div
      className="flex items-baseline gap-2 rounded-xl border px-3 py-1.5"
      style={{ background: c.bg, borderColor: c.border }}
    >
      <span className="text-lg font-light tabular-nums leading-none tracking-[-0.04em]" style={{ color: c.fg }}>{value}</span>
      <span className="text-[10px] font-semibold uppercase tracking-[0.14em]" style={{ color: 'var(--color-govt-text-tertiary)' }}>{label}</span>
    </div>
  )
}
