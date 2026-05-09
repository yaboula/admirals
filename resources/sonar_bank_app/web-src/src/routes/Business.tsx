import { motion } from 'motion/react'
import {
  AlertTriangle,
  ArrowDownRight,
  ArrowUpRight,
  Banknote,
  BriefcaseBusiness,
  CheckCircle2,
  CircleDollarSign,
  Clock3,
  FileText,
  Landmark,
  LockKeyhole,
  ReceiptText,
  ShieldCheck,
  Users,
  Wallet,
  type LucideIcon,
} from 'lucide-react'
import { useBusinessTreasuryQuery, usePayrollPreviewQuery } from '@/data/queries'
import type { BusinessMemberRole, BusinessMovement, BusinessPendingApproval, PayrollPreviewLine, PayrollPreviewResponse } from '@/data/contracts'
import { Badge, Card, Spinner } from '@/components/ui'
import { AceLockedState } from '@/components/security'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { isDevAccessUnlocked } from '@/lib/env'
import { usePrivacyMode } from '@/stores/privacy'
import { useBankSession } from '@/stores/session'

const MOCK_COMPANY_ID = 'vanilla-unicorn'
const FLOW_COLORS = {
  in: 'oklch(0.72 0.17 154)',
  out: 'oklch(0.66 0.20 28)',
}

export function Business() {
  const { t, money, number, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const memberships = useBankSession((s) => s.memberships)
  const companyId = memberships[0]?.company_id ?? (isDevAccessUnlocked() ? MOCK_COMPANY_ID : null)
  const allowed = Boolean(companyId)

  const treasuryQuery = useBusinessTreasuryQuery(
    { company_id: companyId ?? MOCK_COMPANY_ID },
    { enabled: allowed },
  )
  const payrollQuery = usePayrollPreviewQuery(
    { company_id: companyId ?? MOCK_COMPANY_ID },
    { enabled: allowed },
  )

  const snapshot = treasuryQuery.data
  const payrollPreview = payrollQuery.data
  const totalInMinor = snapshot?.recent_movements.filter((m) => m.direction === 'in').reduce((sum, m) => sum + m.amount_minor, 0) ?? 0
  const totalOutMinor = snapshot?.recent_movements.filter((m) => m.direction === 'out').reduce((sum, m) => sum + m.amount_minor, 0) ?? 0
  const netFlowMinor = totalInMinor - totalOutMinor
  const approvalTotalMinor = snapshot?.pending_approvals.reduce((sum, approval) => sum + approval.amount_minor, 0) ?? 0
  const payrollCoverageMonths = snapshot && snapshot.total_payroll_month_minor > 0
    ? snapshot.balance_minor / snapshot.total_payroll_month_minor
    : 0
  const readyPayroll = payrollPreview?.lines.filter((line) => line.status === 'ready').length ?? 0
  const heldPayroll = payrollPreview?.lines.filter((line) => line.status === 'held').length ?? 0
  const operationsScore = snapshot
    ? Math.max(44, Math.min(96, Math.round(74 + snapshot.delta_4w_pct - snapshot.pending_approvals.length * 4 - heldPayroll * 3 + Math.min(payrollCoverageMonths, 4) * 3)))
    : 0

  return (
    <main className="h-full min-h-0 overflow-y-auto px-5 py-4 lg:px-6 scrollbar-thin">
      <div className="mx-auto flex w-full max-w-[1220px] flex-col gap-4 pb-6">
        <motion.section initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28 }}>
          <Card variant="glass" padding="lg" className="relative overflow-hidden rounded-[1.75rem] border-white/10">
            <div className="pointer-events-none absolute -right-24 -top-28 h-72 w-72 rounded-full bg-brand-signal-orange-subtle blur-3xl" aria-hidden />
            <div className="pointer-events-none absolute bottom-0 left-12 h-px w-2/3 bg-gradient-to-r from-transparent via-white/15 to-transparent" aria-hidden />
            <div className="relative z-[1] flex flex-col gap-5 xl:flex-row xl:items-center xl:justify-between">
              <div className="flex min-w-0 gap-4">
                <CompanyMark name={snapshot?.company_name ?? t('business.title')} />
                <div className="min-w-0 max-w-3xl">
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand-signal-orange-light">{t('business.eyebrow')}</p>
                    {snapshot ? <Badge tone="neutral" variant="soft" size="sm">{roleLabel(snapshot.role, t)}</Badge> : null}
                    {snapshot ? <Badge tone="success" variant="soft" size="sm" pulse>{t('business.liveTreasury')}</Badge> : null}
                  </div>
                  <h1 className="mt-2 text-3xl font-light tracking-[-0.065em] text-text-primary md:text-5xl">{snapshot?.company_name ?? t('business.title')}</h1>
                  <p className="mt-2 max-w-2xl text-sm leading-relaxed text-text-secondary">{t('business.description')}</p>
                  {snapshot ? (
                    <div className="mt-4 flex flex-wrap items-center gap-2 text-xs text-text-tertiary">
                      <span className="inline-flex items-center gap-1.5 rounded-full border border-white/10 bg-white/[0.04] px-2.5 py-1">
                        <Landmark size={12} strokeWidth={2} />
                        {snapshot.treasury_iban_masked}
                      </span>
                      <span className="inline-flex items-center gap-1.5 rounded-full border border-white/10 bg-white/[0.04] px-2.5 py-1">
                        <Clock3 size={12} strokeWidth={2} />
                        {`${t('business.synced')} ${dateTime(snapshot.fetched_at_ms, { timeStyle: 'short' })}`}
                      </span>
                    </div>
                  ) : null}
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3 xl:min-w-[380px]">
                <HeroMetric label={t('business.employeeCount')} value={snapshot ? number(snapshot.employee_count) : '—'} />
                <HeroMetric label={t('business.operationsScore')} value={snapshot ? `${number(operationsScore)}%` : '—'} />
                <HeroMetric label={t('business.pendingApprovals')} value={snapshot ? number(snapshot.pending_approvals.length) : '—'} />
                <HeroMetric label={t('business.payrollCoverage')} value={snapshot ? `${payrollCoverageMonths.toFixed(1)}×` : '—'} />
              </div>
            </div>
          </Card>
        </motion.section>

        {!allowed ? (
          <AceLockedState className="min-h-[420px] rounded-[1.75rem]" />
        ) : treasuryQuery.isLoading ? (
          <Card variant="glass" padding="none" className="flex min-h-[420px] items-center justify-center rounded-[1.75rem] border-white/10">
            <div className="flex flex-col items-center gap-3 text-text-secondary">
              <Spinner size="md" />
              <span className="text-sm">{t('business.loading')}</span>
            </div>
          </Card>
        ) : treasuryQuery.isError || !snapshot ? (
          <BusinessEmpty icon={AlertTriangle} title={t('business.errorTitle')} description={t('business.errorDescription')} />
        ) : (
          <motion.section initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28, delay: 0.05 }} className="grid gap-4">
            <div className="grid gap-4 xl:grid-cols-[minmax(0,1fr)_minmax(280px,0.62fr)_minmax(320px,0.8fr)]">
              <Card variant="glass" padding="lg" hero className="relative overflow-hidden rounded-[1.75rem] border-white/10">
                <div className="relative z-[1]">
                  <div className="flex items-center justify-between gap-4">
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-[0.16em] text-text-tertiary">{t('business.treasuryBalance')}</p>
                      <p className="mt-2 text-4xl font-light tracking-[-0.07em] text-text-primary tactile-tabular-nums">
                        {streamerMode ? maskMoneyDisplay() : money(snapshot.balance_minor / 100)}
                      </p>
                    </div>
                    <span className="inline-flex h-14 w-14 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.05] text-brand-signal-orange-light">
                      <Wallet size={24} strokeWidth={1.9} />
                    </span>
                  </div>
                  <div className="mt-5 flex flex-wrap items-center gap-2">
                    <Badge tone="success" variant="soft" leftIcon={<ArrowUpRight size={12} strokeWidth={2.3} />}>{snapshot.delta_4w_pct.toFixed(1)}%</Badge>
                    <span className="text-xs text-text-tertiary">{t('business.delta4w')}</span>
                  </div>
                  <div className="mt-6 grid grid-cols-2 gap-2">
                    <MiniMetric label={t('business.inflow')} value={streamerMode ? maskMoneyDisplay() : money(totalInMinor / 100)} tone="success" />
                    <MiniMetric label={t('business.outflow')} value={streamerMode ? maskMoneyDisplay() : money(totalOutMinor / 100)} tone="danger" />
                  </div>
                </div>
              </Card>

              <Card variant="glass" padding="lg" className="rounded-[1.75rem] border-white/10">
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-signal-orange-light">{t('business.aggregateStats')}</p>
                <div className="mt-4 grid gap-3">
                  <StatRow icon={Users} label={t('business.employeeCount')} value={number(snapshot.employee_count)} />
                  <StatRow icon={Clock3} label={t('business.averageTenure')} value={t('business.daysValue').replace('{count}', number(snapshot.average_tenure_days))} />
                  <StatRow icon={BriefcaseBusiness} label={t('business.monthPayroll')} value={streamerMode ? maskMoneyDisplay() : money(snapshot.total_payroll_month_minor / 100)} />
                  <StatRow icon={ShieldCheck} label={t('business.payrollCoverage')} value={`${payrollCoverageMonths.toFixed(1)}×`} />
                </div>
              </Card>

              <Card variant="glass" padding="lg" className="rounded-[1.75rem] border-white/10">
                <div className="flex items-center justify-between gap-3">
                  <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-signal-orange-light">{t('business.actions')}</p>
                  <Badge tone={snapshot.role === 'employee' ? 'warning' : 'success'} variant="soft" size="sm">{snapshot.role === 'employee' ? t('business.limited') : t('business.operatorReady')}</Badge>
                </div>
                <div className="mt-4 grid gap-2">
                  <ActionPreview icon={Banknote} label={t('business.payPayroll')} description={t('business.payPayrollHint')} locked={!snapshot.pending_approvals.some((approval) => approval.type === 'payroll')} primary />
                  <ActionPreview icon={CircleDollarSign} label={t('business.withdraw')} description={t('business.withdrawHint')} locked />
                  <ActionPreview icon={ReceiptText} label={t('business.auditBusiness')} description={t('business.auditBusinessHint')} locked={snapshot.role === 'employee'} />
                </div>
              </Card>
            </div>

            <div className="grid items-stretch gap-4 xl:grid-cols-[minmax(0,1fr)_390px]">
              <div className="grid gap-4">
                <Card variant="glass" padding="none" className="overflow-hidden rounded-[1.75rem] border-white/10">
                  <div className="flex items-center justify-between gap-3 border-b border-white/10 px-5 py-4">
                    <div>
                      <p className="text-sm font-semibold text-text-primary">{t('business.cashflowPulse')}</p>
                      <p className="mt-0.5 text-xs text-text-tertiary">{t('business.cashflowPulseDescription')}</p>
                    </div>
                    <Badge tone={netFlowMinor >= 0 ? 'success' : 'danger'} variant="soft">
                      {streamerMode ? maskMoneyDisplay() : money(netFlowMinor / 100)}
                    </Badge>
                  </div>
                  <CashflowPulse movements={snapshot.recent_movements} />
                </Card>

                <Card variant="glass" padding="none" className="flex min-h-[430px] flex-col overflow-hidden rounded-[1.75rem] border-white/10">
                  <div className="flex items-center justify-between gap-3 border-b border-white/10 px-5 py-4">
                    <div>
                      <p className="text-sm font-semibold text-text-primary">{t('business.recentMovements')}</p>
                      <p className="mt-0.5 text-xs text-text-tertiary">{t('business.movementsPrivacy')}</p>
                    </div>
                    <Badge tone="info" variant="soft">{number(snapshot.recent_movements.length)}</Badge>
                  </div>
                  <div className="min-h-0 flex-1 overflow-y-auto p-2.5 scrollbar-thin">
                    <div className="space-y-2">
                      {snapshot.recent_movements.map((movement) => (
                        <MovementRow key={movement.movement_id} movement={movement} />
                      ))}
                    </div>
                  </div>
                </Card>
              </div>

              <div className="grid h-full gap-4">
                <Card variant="glass" padding="none" className="overflow-hidden rounded-[1.75rem] border-white/10">
                  <div className="border-b border-white/10 px-5 py-4">
                    <p className="text-sm font-semibold text-text-primary">{t('business.payrollPreview')}</p>
                    <p className="mt-0.5 text-xs text-text-tertiary">{t('business.payrollPreviewDescription')}</p>
                  </div>
                  <div className="p-3">
                    {payrollQuery.isLoading ? (
                      <div className="flex min-h-[150px] items-center justify-center">
                        <Spinner size="sm" />
                      </div>
                    ) : payrollPreview ? (
                      <div className="space-y-3">
                        <PayrollReadiness payroll={payrollPreview} ready={readyPayroll} held={heldPayroll} />
                        <div className="max-h-[240px] space-y-2 overflow-y-auto pr-1 scrollbar-thin">
                          {payrollPreview.lines.map((line) => (
                            <PayrollLine key={line.line_id} line={line} />
                          ))}
                        </div>
                      </div>
                    ) : (
                      <BusinessEmpty icon={AlertTriangle} title={t('business.payrollPreviewUnavailable')} description={t('business.errorDescription')} compact />
                    )}
                  </div>
                </Card>

                <Card variant="glass" padding="none" className="overflow-hidden rounded-[1.75rem] border-white/10">
                  <div className="border-b border-white/10 px-5 py-4">
                    <p className="text-sm font-semibold text-text-primary">{t('business.pendingApprovals')}</p>
                    <p className="mt-0.5 text-xs text-text-tertiary">{t('business.approvalsDescription')}</p>
                  </div>
                  <div className="max-h-[300px] overflow-y-auto p-2.5 scrollbar-thin">
                    {snapshot.pending_approvals.length === 0 ? (
                      <BusinessEmpty icon={CheckCircle2} title={t('business.noApprovalsTitle')} description={t('business.noApprovalsDescription')} compact />
                    ) : (
                      <div className="space-y-2">
                        <div className="rounded-[1rem] border border-white/10 bg-white/[0.035] px-3 py-2 text-xs text-text-secondary">
                          <div className="flex items-center justify-between gap-3">
                            <span>{t('business.approvalExposure')}</span>
                            <span className="font-semibold text-text-primary tactile-tabular-nums">{streamerMode ? maskMoneyDisplay() : money(approvalTotalMinor / 100)}</span>
                          </div>
                        </div>
                        {snapshot.pending_approvals.map((approval) => (
                          <ApprovalCard key={approval.approval_id} approval={approval} />
                        ))}
                      </div>
                    )}
                  </div>
                </Card>
              </div>
            </div>
          </motion.section>
        )}
      </div>
    </main>
  )
}

function CompanyMark({ name }: { name: string }) {
  const initials = name.split(' ').filter(Boolean).slice(0, 2).map((part) => part[0]?.toUpperCase()).join('')
  return (
    <div
      className="relative hidden h-16 w-16 shrink-0 items-center justify-center rounded-[1.4rem] border border-white/10 bg-white/[0.045] text-xl font-semibold text-text-primary shadow-[inset_0_1px_0_rgba(255,255,255,0.10)] sm:flex"
      aria-hidden
    >
      <span className="absolute inset-1 rounded-[1.15rem] border border-brand-signal-orange/20" />
      <span className="relative tactile-tabular-nums">{initials || 'B'}</span>
    </div>
  )
}

function HeroMetric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[1.35rem] border border-white/10 bg-white/[0.045] px-4 py-3">
      <span className="block text-[10px] font-semibold uppercase tracking-[0.14em] text-text-tertiary">{label}</span>
      <span className="mt-1 block truncate text-lg font-semibold text-text-primary tactile-tabular-nums">{value}</span>
    </div>
  )
}

function MiniMetric({ label, value, tone }: { label: string; value: string; tone: 'success' | 'danger' }) {
  return (
    <div className="rounded-[1rem] border border-white/10 bg-white/[0.035] px-3 py-2">
      <span className="block text-[10px] font-semibold uppercase tracking-[0.14em] text-text-tertiary">{label}</span>
      <span className={cn('mt-1 block text-sm font-semibold tactile-tabular-nums', tone === 'success' ? 'text-semantic-success' : 'text-semantic-danger')}>{value}</span>
    </div>
  )
}

function PayrollReadiness({ payroll, ready, held }: { payroll: PayrollPreviewResponse; ready: number; held: number }) {
  const { t, money, number, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const readyPct = payroll.lines.length > 0 ? Math.round((ready / payroll.lines.length) * 100) : 0
  return (
    <div className="grid grid-cols-[92px_minmax(0,1fr)] gap-3 rounded-[1.25rem] border border-white/10 bg-white/[0.035] p-3">
      <ReadinessRing pct={readyPct} />
      <div className="min-w-0">
        <div className="flex items-start justify-between gap-2">
          <div>
            <p className="text-sm font-semibold text-text-primary">{t('business.payrollReadiness')}</p>
            <p className="mt-0.5 text-xs text-text-tertiary">{dateTime(payroll.scheduled_for_ms, { dateStyle: 'short', timeStyle: 'short' })}</p>
          </div>
          <Badge tone={held > 0 ? 'warning' : 'success'} variant="soft">{held > 0 ? t('business.reviewNeeded') : t('business.readyToExecute')}</Badge>
        </div>
        <div className="mt-3 grid grid-cols-3 gap-2">
          <HeroMetric label={t('business.totalNet')} value={streamerMode ? maskMoneyDisplay() : money(payroll.total_net_minor / 100)} />
          <HeroMetric label={t('business.readyLines')} value={number(ready)} />
          <HeroMetric label={t('business.heldLines')} value={number(held)} />
        </div>
      </div>
    </div>
  )
}

function ReadinessRing({ pct }: { pct: number }) {
  const radius = 34
  const circumference = 2 * Math.PI * radius
  const offset = circumference - (pct / 100) * circumference
  return (
    <div className="relative flex h-[92px] w-[92px] items-center justify-center">
      <svg width="92" height="92" viewBox="0 0 92 92" aria-hidden>
        <circle cx="46" cy="46" r={radius} fill="none" stroke="oklch(1 0 0 / 0.08)" strokeWidth="8" />
        <circle
          cx="46"
          cy="46"
          r={radius}
          fill="none"
          stroke="oklch(0.72 0.17 154)"
          strokeWidth="8"
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          transform="rotate(-90 46 46)"
        />
      </svg>
      <span className="absolute text-lg font-semibold text-text-primary tactile-tabular-nums">{pct}%</span>
    </div>
  )
}

function PayrollLine({ line }: { line: PayrollPreviewLine }) {
  const { t, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  return (
    <div className="flex items-center justify-between gap-3 rounded-[1rem] border border-white/10 bg-white/[0.03] px-3 py-2.5">
      <div className="min-w-0">
        <p className="truncate text-sm font-semibold text-text-primary">{line.employee_alias}</p>
        <p className="mt-0.5 truncate text-xs text-text-tertiary">{line.department}</p>
      </div>
      <div className="shrink-0 text-right">
        <p className="text-sm font-semibold text-text-primary tactile-tabular-nums">{streamerMode ? maskMoneyDisplay() : money(line.net_amount_minor / 100)}</p>
        <Badge tone={line.status === 'ready' ? 'success' : 'warning'} variant="soft" size="sm">{line.status === 'ready' ? t('business.payrollReady') : t('business.payrollHeld')}</Badge>
      </div>
    </div>
  )
}

function StatRow({ icon: Icon, label, value }: { icon: LucideIcon; label: string; value: string }) {
  return (
    <div className="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-3 rounded-[1rem] border border-white/8 bg-white/[0.035] px-3 py-2">
      <span className="flex min-w-0 items-center gap-2 text-xs leading-tight text-text-tertiary"><Icon size={14} strokeWidth={2} className="shrink-0" />{label}</span>
      <span className="text-right text-sm font-semibold text-text-primary tactile-tabular-nums">{value}</span>
    </div>
  )
}

function CashflowPulse({ movements }: { movements: BusinessMovement[] }) {
  const { t, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const max = Math.max(...movements.map((movement) => movement.amount_minor), 1)
  return (
    <div className="p-5">
      <div className="flex h-36 items-end gap-2">
        {movements.slice().reverse().map((movement) => {
          const height = Math.max(18, Math.round((movement.amount_minor / max) * 100))
          const color = movement.direction === 'in' ? FLOW_COLORS.in : FLOW_COLORS.out
          return (
            <div key={movement.movement_id} className="flex min-w-0 flex-1 flex-col items-center gap-2">
              <div className="flex h-28 w-full items-end rounded-full bg-white/[0.035] px-1.5 py-1">
                <div
                  className="w-full rounded-full"
                  style={{
                    height: `${height}%`,
                    background: color,
                    opacity: 0.8,
                  }}
                  title={streamerMode ? maskMoneyDisplay() : money(movement.amount_minor / 100)}
                />
              </div>
              <span className="text-[10px] font-semibold uppercase tracking-[0.12em] text-text-quaternary">{movement.direction === 'in' ? t('business.in') : t('business.out')}</span>
            </div>
          )
        })}
      </div>
      <div className="mt-4 flex items-center justify-center gap-4 text-xs text-text-tertiary">
        <span className="inline-flex items-center gap-1.5"><span className="h-2 w-2 rounded-full" style={{ background: FLOW_COLORS.in }} />{t('business.inflow')}</span>
        <span className="inline-flex items-center gap-1.5"><span className="h-2 w-2 rounded-full" style={{ background: FLOW_COLORS.out }} />{t('business.outflow')}</span>
      </div>
    </div>
  )
}

function MovementRow({ movement }: { movement: BusinessMovement }) {
  const { t, money, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const outgoing = movement.direction === 'out'
  const Icon = outgoing ? ArrowDownRight : ArrowUpRight
  return (
    <div className="grid grid-cols-[minmax(0,1fr)_minmax(104px,auto)_auto] items-center gap-3 rounded-[1.1rem] border border-white/10 bg-white/[0.03] px-3 py-3 max-md:grid-cols-[minmax(0,1fr)_auto]">
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <span className={cn('inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-xl border', outgoing ? 'border-semantic-danger-deep/25 bg-semantic-danger-glow text-semantic-danger' : 'border-semantic-success-deep/25 bg-semantic-success-glow text-semantic-success')}>
            <Icon size={15} strokeWidth={2.2} />
          </span>
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold text-text-primary">{movement.reason ?? t('business.movement')}</p>
            <p className="mt-0.5 truncate text-xs text-text-tertiary">{movement.counterparty_masked}</p>
          </div>
        </div>
      </div>
      <span className="text-xs text-text-secondary tactile-tabular-nums max-md:hidden">{dateTime(movement.timestamp_ms, { dateStyle: 'short', timeStyle: 'short' })}</span>
      <span className={cn('text-right text-sm font-semibold tactile-tabular-nums', outgoing ? 'text-text-primary' : 'text-semantic-success')}>{streamerMode ? maskMoneyDisplay() : money(movement.amount_minor / 100)}</span>
    </div>
  )
}

function ApprovalCard({ approval }: { approval: BusinessPendingApproval }) {
  const { t, money, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  return (
    <div className="rounded-[1.1rem] border border-white/10 bg-white/[0.035] p-3">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="truncate text-sm font-semibold text-text-primary">{approvalTypeLabel(approval.type, t)}</p>
          <p className="mt-1 truncate text-xs text-text-tertiary">{approval.requested_by_alias}</p>
        </div>
        <Badge tone="warning" variant="soft">{t('common.pending')}</Badge>
      </div>
      <div className="mt-3 flex items-center justify-between gap-3 text-xs text-text-secondary">
        <span className="tactile-tabular-nums">{dateTime(approval.created_at_ms, { dateStyle: 'short', timeStyle: 'short' })}</span>
        <span className="font-semibold text-text-primary tactile-tabular-nums">{streamerMode ? maskMoneyDisplay() : money(approval.amount_minor / 100)}</span>
      </div>
      <div className="mt-3 grid grid-cols-2 gap-2">
        <button type="button" disabled className="h-8 rounded-xl border border-white/8 bg-white/[0.025] text-xs font-semibold text-text-quaternary">
          {t('business.reject')}
        </button>
        <button type="button" disabled className="h-8 rounded-xl border border-white/8 bg-white/[0.025] text-xs font-semibold text-text-quaternary">
          {t('business.approve')}
        </button>
      </div>
    </div>
  )
}

function ActionPreview({
  icon: Icon,
  label,
  description,
  locked,
  primary,
}: {
  icon: LucideIcon
  label: string
  description: string
  locked?: boolean
  primary?: boolean
}) {
  return (
    <div className={cn('flex items-center justify-between gap-3 rounded-[1.1rem] border px-3 py-3', locked ? 'border-white/8 bg-white/[0.025] text-text-tertiary' : primary ? 'border-border-brand-strong bg-brand-signal-orange-subtle text-text-primary' : 'border-white/10 bg-white/[0.045] text-text-primary')}>
      <span className="flex min-w-0 items-center gap-3">
        <span className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-white/10 bg-white/[0.045]">
          <Icon size={16} strokeWidth={2} />
        </span>
        <span className="min-w-0">
          <span className="block truncate text-sm font-semibold">{label}</span>
          <span className="mt-0.5 block truncate text-xs font-normal opacity-70">{description}</span>
        </span>
      </span>
      {locked ? <LockKeyhole size={15} strokeWidth={2} /> : <FileText size={15} strokeWidth={2} />}
    </div>
  )
}

function BusinessEmpty({ icon: Icon, title, description, compact }: { icon: LucideIcon; title: string; description: string; compact?: boolean }) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-3 p-6 text-center', compact ? 'min-h-[220px]' : 'min-h-[420px] rounded-[1.75rem] border border-white/10 bg-white/[0.035]')}>
      <span className="inline-flex h-14 w-14 items-center justify-center rounded-full border border-white/10 bg-white/[0.04] text-text-secondary">
        <Icon size={24} strokeWidth={1.8} />
      </span>
      <div className="flex max-w-[34ch] flex-col gap-1">
        <h2 className="text-base font-semibold text-text-primary">{title}</h2>
        <p className="text-sm leading-relaxed text-text-tertiary">{description}</p>
      </div>
    </div>
  )
}

function approvalTypeLabel(type: BusinessPendingApproval['type'], t: (key: TranslationKey) => string): string {
  const labels: Record<BusinessPendingApproval['type'], TranslationKey> = {
    payroll: 'business.approvalPayroll',
    withdrawal: 'business.approvalWithdrawal',
    recurring: 'business.approvalRecurring',
    loan: 'business.approvalLoan',
  }
  return t(labels[type])
}

function roleLabel(role: BusinessMemberRole, t: (key: TranslationKey) => string): string {
  const labels: Record<BusinessMemberRole, TranslationKey> = {
    owner: 'business.role.owner',
    manager: 'business.role.manager',
    employee: 'business.role.employee',
  }
  return t(labels[role])
}
