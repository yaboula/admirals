import { motion } from 'motion/react'
import { AlertTriangle, ArrowDownRight, ArrowUpRight, BriefcaseBusiness, CheckCircle2, Clock3, FileText, Users, Wallet, type LucideIcon } from 'lucide-react'
import { useBusinessTreasuryQuery, usePayrollPreviewQuery } from '@/data/queries'
import type { BusinessMovement, BusinessPendingApproval, PayrollPreviewLine } from '@/data/contracts'
import { Badge, Card, Spinner } from '@/components/ui'
import { AceLockedState } from '@/components/security'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { isDevAccessUnlocked } from '@/lib/env'
import { usePrivacyMode } from '@/stores/privacy'
import { useBankSession } from '@/stores/session'

const MOCK_COMPANY_ID = 'vanilla-unicorn'

export function Business() {
  const { t, money, number } = useI18n()
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

  return (
    <main className="h-full min-h-0 overflow-y-auto px-5 py-4 lg:px-6 scrollbar-thin">
      <div className="mx-auto flex w-full max-w-[1180px] flex-col gap-4 pb-6">
        <motion.section initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28 }}>
          <Card variant="glass" padding="lg" className="rounded-[1.75rem] border-white/10">
            <div className="flex flex-col gap-5 xl:flex-row xl:items-center xl:justify-between">
              <div className="min-w-0 max-w-3xl">
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand-signal-orange-light">{t('business.eyebrow')}</p>
                <h1 className="mt-2 text-3xl font-light tracking-[-0.065em] text-text-primary md:text-4xl">{snapshot?.company_name ?? t('business.title')}</h1>
                <p className="mt-2 max-w-2xl text-sm leading-relaxed text-text-secondary">{t('business.description')}</p>
              </div>
              <div className="grid grid-cols-2 gap-3 xl:min-w-[340px]">
                <HeroMetric label={t('business.employeeCount')} value={snapshot ? number(snapshot.employee_count) : '—'} />
                <HeroMetric label={t('business.pendingApprovals')} value={snapshot ? number(snapshot.pending_approvals.length) : '—'} />
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
            <div className="grid gap-4 xl:grid-cols-[minmax(0,1fr)_minmax(260px,0.62fr)_minmax(300px,0.8fr)]">
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
                </div>
              </Card>

              <Card variant="glass" padding="lg" className="rounded-[1.75rem] border-white/10">
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-signal-orange-light">{t('business.aggregateStats')}</p>
                <div className="mt-4 grid gap-3">
                  <StatRow icon={Users} label={t('business.employeeCount')} value={number(snapshot.employee_count)} />
                  <StatRow icon={Clock3} label={t('business.averageTenure')} value={t('business.daysValue').replace('{count}', number(snapshot.average_tenure_days))} />
                  <StatRow icon={BriefcaseBusiness} label={t('business.monthPayroll')} value={streamerMode ? maskMoneyDisplay() : money(snapshot.total_payroll_month_minor / 100)} />
                </div>
              </Card>

              <Card variant="glass" padding="lg" className="rounded-[1.75rem] border-white/10">
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-signal-orange-light">{t('business.actions')}</p>
                <div className="mt-4 grid gap-2">
                  <ActionPreview label={t('business.payPayroll')} locked={!snapshot.pending_approvals.some((approval) => approval.type === 'payroll')} />
                  <ActionPreview label={t('business.withdraw')} locked />
                  <ActionPreview label={t('business.auditBusiness')} locked={snapshot.role === 'employee'} />
                </div>
              </Card>
            </div>

            <div className="grid items-stretch gap-4 xl:grid-cols-[minmax(0,1fr)_390px]">
              <Card variant="glass" padding="none" className="flex min-h-[460px] flex-col overflow-hidden rounded-[1.75rem] border-white/10">
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
                        <div className="grid grid-cols-2 gap-2">
                          <HeroMetric label={t('business.totalNet')} value={streamerMode ? maskMoneyDisplay() : money(payrollPreview.total_net_minor / 100)} />
                          <HeroMetric label={t('business.requiresApprovals')} value={number(payrollPreview.requires_approvals)} />
                        </div>
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

function HeroMetric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[1.35rem] border border-white/10 bg-white/[0.045] px-4 py-3">
      <span className="block text-[10px] font-semibold uppercase tracking-[0.14em] text-text-tertiary">{label}</span>
      <span className="mt-1 block truncate text-lg font-semibold text-text-primary tactile-tabular-nums">{value}</span>
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
    </div>
  )
}

function ActionPreview({ label, locked }: { label: string; locked?: boolean }) {
  return (
    <div className={cn('flex items-center justify-between gap-3 rounded-[1rem] border px-3 py-2.5', locked ? 'border-white/8 bg-white/[0.025] text-text-tertiary' : 'border-border-brand-strong bg-brand-signal-orange-subtle text-text-primary')}>
      <span className="text-sm font-semibold">{label}</span>
      <FileText size={15} strokeWidth={2} />
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
