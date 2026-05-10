import { useState } from 'react'
import { motion } from 'motion/react'
import {
  ArrowDownRight, ArrowUpRight, BarChart2, Loader2,
  ScanSearch, Shield, TrendingUp, Users,
} from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { useAceGate } from '@/components/security'
import { ACE_PERMS } from '@/lib/ace'
import { usePrivacyMode } from '@/stores/privacy'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { GovtCard } from '../components/GovtCard'
import { RevenueChart } from './reports/RevenueChart'
import { ComplianceRing } from './reports/ComplianceRing'
import { SectorBars } from './reports/SectorBars'
import { TopContributors } from './reports/TopContributors'
import { useGovtReportsQuery } from '../data/queries/govtReports'
import type { GovtReportsRange, GovtRiskBreakdown } from '../data/contracts'

const RANGE_OPTIONS: Array<{ value: GovtReportsRange; key: TranslationKey }> = [
  { value: 'month',   key: 'govt.reports.range.month' },
  { value: 'quarter', key: 'govt.reports.range.quarter' },
  { value: 'year',    key: 'govt.reports.range.year' },
]

const RISK_COLORS: Record<keyof GovtRiskBreakdown, string> = {
  low:      'rgb(0, 173, 91)',
  medium:   'rgb(230, 173, 0)',
  high:     'rgb(255, 106, 67)',
  critical: 'rgb(234, 60, 63)',
}

export function GovtReports() {
  const { t, money, number } = useI18n()
  const granted = useAceGate({ require: ACE_PERMS.P04.perm })
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const [range, setRange] = useState<GovtReportsRange>('quarter')

  const query = useGovtReportsQuery(granted ? range : 'quarter')
  const d = query.data
  const m = (v: number) => (streamerMode ? maskMoneyDisplay() : money(v))

  if (!granted) return <PermissionDenied />

  return (
    <div className="relative flex h-full flex-col gap-3 overflow-y-auto pt-2 pr-1 scrollbar-thin">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 -top-4 h-56"
        style={{ background: 'radial-gradient(ellipse 90% 55% at 50% 0%, rgba(0,113,214,0.07), transparent)', zIndex: 0 }}
      />

      <motion.header
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.25 }}
        className="relative flex flex-wrap items-center justify-between gap-3 border-b pb-3"
        style={{ borderColor: 'var(--color-govt-border)', zIndex: 1 }}
      >
        <div className="flex items-center gap-3">
          <div
            className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-2xl border"
            style={{ background: 'rgba(0,1,3,0.7)', borderColor: 'var(--color-govt-border-strong)', color: 'var(--color-govt-accent-light)' }}
            aria-hidden
          >
            <BarChart2 size={16} strokeWidth={1.8} />
          </div>
          <div>
            <h1 className="text-base font-semibold tracking-[-0.02em] text-[var(--color-govt-text-primary)]">{t('govt.reports.title')}</h1>
            <p className="text-[11px] text-[var(--color-govt-text-tertiary)]">{t('govt.reports.subtitle')}</p>
          </div>
        </div>

        <div className="flex items-center gap-1">
          {RANGE_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => { sfx.console_tap(); setRange(opt.value) }}
              className={cn(
                'h-7 rounded-full border px-3 text-[10px] font-semibold uppercase tracking-[0.12em] transition-all',
                range === opt.value
                  ? 'border-[var(--color-govt-border-active)] bg-[var(--color-govt-accent-soft)] text-[var(--color-govt-accent-light)]'
                  : 'border-[var(--color-govt-border)] bg-transparent text-[var(--color-govt-text-tertiary)] hover:text-[var(--color-govt-text-secondary)]',
              )}
            >
              {t(opt.key)}
            </button>
          ))}
          {query.isFetching ? <Loader2 size={12} className="ml-1 animate-spin text-[var(--color-govt-text-tertiary)]" /> : null}
        </div>
      </motion.header>

      {!d ? (
        <div className="flex flex-1 items-center justify-center">
          <Loader2 size={20} className="animate-spin text-[var(--color-govt-text-tertiary)]" />
        </div>
      ) : (
        <div className="space-y-3 pb-6">
          <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
            <KpiCard icon={TrendingUp} label={t('govt.reports.kpi.revenue')} value={m(d.kpis.totalRevenue)}
              sub={`${d.kpis.revenueVsPriorPct >= 0 ? '+' : ''}${d.kpis.revenueVsPriorPct}% vs prior`}
              subIcon={d.kpis.revenueVsPriorPct >= 0 ? ArrowUpRight : ArrowDownRight}
              subColor={d.kpis.revenueVsPriorPct >= 0 ? 'rgb(0, 196, 112)' : 'rgb(255, 106, 67)'} />
            <KpiCard icon={BarChart2} label={t('govt.reports.kpi.obligation')} value={m(d.kpis.totalObligation)} />
            <KpiCard icon={Shield} label={t('govt.reports.kpi.compliance')} value={`${d.kpis.complianceRate}%`}
              sub={d.kpis.complianceRate >= 80 ? t('govt.reports.kpi.complianceGood') : t('govt.reports.kpi.complianceLow')}
              subColor={d.kpis.complianceRate >= 80 ? 'rgb(0, 196, 112)' : 'rgb(255, 106, 67)'} />
            <KpiCard icon={Users} label={t('govt.reports.kpi.taxpayers')} value={number(d.kpis.activeTaxpayers)} />
          </div>

          <div className="grid gap-3 lg:grid-cols-[minmax(0,1.6fr)_minmax(0,1fr)]">
            <GovtCard variant="glass" padding="md">
              <SectionHeader icon={BarChart2} label={t('govt.reports.section.revenue')} />
              <div className="mt-4">
                <RevenueChart data={d.revenueHistory} />
              </div>
            </GovtCard>

            <GovtCard variant="glass" padding="md">
              <SectionHeader icon={Shield} label={t('govt.reports.section.compliance')} />
              <div className="mt-4">
                <ComplianceRing data={d.complianceBreakdown} />
              </div>
            </GovtCard>
          </div>

          <div className="grid gap-3 lg:grid-cols-2">
            <GovtCard variant="glass" padding="md">
              <SectionHeader icon={TrendingUp} label={t('govt.reports.section.sectors')} />
              <div className="mt-4">
                <SectorBars data={d.sectorRevenue} />
              </div>
            </GovtCard>

            <GovtCard variant="glass" padding="md">
              <SectionHeader icon={Users} label={t('govt.reports.section.topContributors')} />
              <div className="mt-4">
                <TopContributors data={d.topContributors} />
              </div>
            </GovtCard>
          </div>

          <GovtCard variant="glass" padding="md">
            <SectionHeader icon={Shield} label={t('govt.reports.section.riskDist')} />
            <div className="mt-4">
              <RiskDistribution data={d.riskBreakdown} />
            </div>
          </GovtCard>
        </div>
      )}
    </div>
  )
}

function SectionHeader({ icon: Icon, label }: { icon: typeof BarChart2; label: string }) {
  return (
    <div className="flex items-center gap-2">
      <span
        aria-hidden
        className="flex h-7 w-7 items-center justify-center rounded-lg"
        style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}
      >
        <Icon size={13} strokeWidth={2} />
      </span>
      <h3 className="text-[11px] font-semibold uppercase tracking-[0.16em] text-[var(--color-govt-text-secondary)]">{label}</h3>
    </div>
  )
}

function KpiCard({
  icon: Icon, label, value, sub, subIcon: SubIcon, subColor,
}: {
  icon: typeof BarChart2
  label: string
  value: string
  sub?: string
  subIcon?: typeof ArrowUpRight
  subColor?: string
}) {
  return (
    <GovtCard variant="glass" padding="md" className="flex flex-col gap-2">
      <div className="flex items-center gap-2">
        <span
          aria-hidden
          className="flex h-7 w-7 items-center justify-center rounded-lg"
          style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}
        >
          <Icon size={13} strokeWidth={2} />
        </span>
        <span className="text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{label}</span>
      </div>
      <p className="truncate text-2xl font-semibold tabular-nums leading-tight tracking-[-0.03em] text-[var(--color-govt-text-primary)]">{value}</p>
      {sub ? (
        <p className="flex items-center gap-1 text-[10px]" style={{ color: subColor ?? 'var(--color-govt-text-tertiary)' }}>
          {SubIcon ? <SubIcon size={11} strokeWidth={2.2} /> : null}
          <span>{sub}</span>
        </p>
      ) : null}
    </GovtCard>
  )
}

function RiskDistribution({ data }: { data: GovtRiskBreakdown }) {
  const { t, number } = useI18n()
  const total = data.low + data.medium + data.high + data.critical
  const entries = [
    { key: 'low' as const,      labelKey: 'govt.census.risk.low' as const },
    { key: 'medium' as const,   labelKey: 'govt.census.risk.medium' as const },
    { key: 'high' as const,     labelKey: 'govt.census.risk.high' as const },
    { key: 'critical' as const, labelKey: 'govt.census.risk.critical' as const },
  ]

  return (
    <div className="space-y-2">
      {entries.map((e) => {
        const val = data[e.key]
        const pct = total > 0 ? Math.round((val / total) * 100) : 0
        const color = RISK_COLORS[e.key]
        return (
          <div key={e.key}>
            <div className="flex items-center justify-between text-[10px] mb-1">
              <span className="font-semibold uppercase tracking-[0.12em]" style={{ color }}>{t(e.labelKey)}</span>
              <span className="tabular-nums" style={{ color }}>{`${number(val)} (${pct}%)`}</span>
            </div>
            <div className="h-[5px] w-full overflow-hidden rounded-full bg-white/[0.05]" aria-hidden>
              <span className="block h-full rounded-full transition-[width] duration-700" style={{ width: `${pct}%`, background: color }} />
            </div>
          </div>
        )
      })}
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
        <p className="text-xs leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.reports.permissionHint')}</p>
      </GovtCard>
    </div>
  )
}
