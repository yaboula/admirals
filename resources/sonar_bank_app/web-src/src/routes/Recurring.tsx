import { useEffect, useMemo, useState } from 'react'
import { motion } from 'motion/react'
import {
  AlertTriangle,
  CalendarClock,
  Check,
  Clock,
  Landmark,
  Pause,
  Plus,
  Receipt,
  RefreshCw,
  ShieldCheck,
  Wallet,
} from 'lucide-react'
import { Button, Card, CardEyebrow, CardTitle, Input, Spinner } from '@/components/ui'
import { BankAvatar } from '@/components/brand/BankAvatar'
import { useBootstrap } from '@/data/queries'
import type { Recurring, RecurringStatus } from '@/data/contracts'
import { getMockAliasForIban } from '@/data/mock/seed'
import { handleBankError } from '@/lib/bankError'
import { cn } from '@/lib/utils'
import { useI18n } from '@/lib/i18n'
import { maskIbanCompact, maskMoneyDisplay, revealIbanDisplay, safeAriaLabel } from '@/lib/privacy'
import { sfx } from '@/lib/sfx'
import { usePrivacyMode } from '@/stores/privacy'
import { toast } from '@/stores/toast'
import { useCancelRecurringMutation, usePauseRecurringMutation, useResumeRecurringMutation, useSubscribeRecurringMutation } from '@/data/mutations'

type RecurringTab = 'active' | 'paused' | 'history'

export function RecurringPayments() {
  const { t } = useI18n()
  const { data, isLoading, isError, error } = useBootstrap()
  const [tab, setTab] = useState<RecurringTab>('active')
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const [createOpen, setCreateOpen] = useState(false)
  const [toIban, setToIban] = useState('')
  const [amountMajor, setAmountMajor] = useState('')
  const [intervalDays, setIntervalDays] = useState('30')
  const [firstChargeDays, setFirstChargeDays] = useState('1')
  const [reason, setReason] = useState('')
  const subscribeMutation = useSubscribeRecurringMutation()
  const pauseMutation = usePauseRecurringMutation()
  const resumeMutation = useResumeRecurringMutation()
  const cancelMutation = useCancelRecurringMutation()

  useEffect(() => {
    if (isError && error) handleBankError(error)
  }, [isError, error])

  const rules = data?.recurring ?? []
  const activeRules = rules.filter((rule) => rule.status === 'active')
  const pausedRules = rules.filter((rule) => rule.status === 'paused')
  const historyRules = rules.filter((rule) => rule.status === 'cancelled')
  const visibleRules = tab === 'active' ? activeRules : tab === 'paused' ? pausedRules : historyRules
  const stats = useMemo(() => computeRecurringStats(rules), [rules])
  const nextRule = activeRules.slice().sort((a, b) => a.next_charge_ms - b.next_charge_ms)[0]
  const primaryAccount = data?.accounts.find((account) => account.status === 'active') ?? data?.accounts[0] ?? null

  const submitCreateRule = async () => {
    if (!primaryAccount) return
    const amount_minor = Math.round(Number(amountMajor) * 100)
    const first_charge_ms = Date.now() + Math.max(1, Math.round(Number(firstChargeDays))) * 24 * 60 * 60 * 1000
    try {
      await subscribeMutation.mutateAsync({
        from_iban: primaryAccount.iban,
        to_iban: toIban,
        amount_minor,
        reason: reason.trim() || null,
        interval_days: Math.round(Number(intervalDays)),
        first_charge_ms,
      })
      setCreateOpen(false)
      toast.success(t('recurring.createRule'), t('recurring.createRuleDescription'))
    } catch {
      toast.warning(t('recurring.createRule'), t('recurring.createRuleDescription'))
    }
  }

  const runRuleAction = async (rule: Recurring, action: 'pause' | 'resume' | 'cancel') => {
    try {
      if (action === 'pause') await pauseMutation.mutateAsync({ recurring_id: rule.recurring_id })
      if (action === 'resume') await resumeMutation.mutateAsync({ recurring_id: rule.recurring_id })
      if (action === 'cancel') await cancelMutation.mutateAsync({ recurring_id: rule.recurring_id })
      toast.success(t('recurring.rules'), statusText(action === 'pause' ? 'paused' : action === 'resume' ? 'active' : 'cancelled'))
    } catch {
      toast.warning(t('recurring.rules'), t('recurring.createRuleDescription'))
    }
  }

  if (isLoading && rules.length === 0) {
    return <RecurringLoading />
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
      className="h-full w-full"
    >
      <div
        className="h-full w-full mx-auto max-w-[1500px] gap-4 2xl:gap-5"
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 0.92fr) minmax(360px, 0.48fr)',
          gridTemplateRows: '1fr',
        }}
      >
        <section className="min-h-0 flex flex-col gap-4 2xl:gap-5">
          <RecurringHero stats={stats} streamerMode={streamerMode} />
          <Card variant="glass" padding="md" className="min-h-0 flex-1 border-white/10 flex flex-col gap-4">
            <div className="flex items-center justify-between gap-3 shrink-0">
              <div>
                <CardEyebrow>{t('recurring.rules')}</CardEyebrow>
                <CardTitle className="text-base">{t('recurring.scheduledPayments')}</CardTitle>
              </div>
              <Button
                variant="secondary"
                size="sm"
                leftIcon={<Plus size={14} />}
                onClick={() => setCreateOpen(true)}
              >
                {t('recurring.create')}
              </Button>
            </div>
            <RecurringTabs tab={tab} counts={{ active: activeRules.length, paused: pausedRules.length, history: historyRules.length }} onChange={setTab} />
            <div className="min-h-0 flex-1 overflow-y-auto space-y-2 scrollbar-thin relative">
              {visibleRules.length === 0 ? (
                <EmptyRecurring tab={tab} />
              ) : (
                <>
                  {visibleRules.map((rule, index) => (
                    <RecurringRuleCard key={rule.recurring_id} rule={rule} index={index} streamerMode={streamerMode} onAction={runRuleAction} actionPending={pauseMutation.isPending || resumeMutation.isPending || cancelMutation.isPending} />
                  ))}
                  {visibleRules.length > 2 && (
                    <div className="absolute bottom-0 left-0 right-0 h-12 bg-gradient-to-t from-surface-panel to-transparent pointer-events-none" />
                  )}
                </>
              )}
            </div>
          </Card>
        </section>

        <aside className="min-h-0 flex flex-col gap-4 2xl:gap-5">
          <NextPaymentPanel rule={nextRule} streamerMode={streamerMode} />
          <RecurringBudgetPanel stats={stats} streamerMode={streamerMode} />
          <RecurringSafetyPanel />
        </aside>
      </div>
      {createOpen ? (
        <RecurringCreateDialog
          fromIban={primaryAccount?.iban ?? ''}
          toIban={toIban}
          amountMajor={amountMajor}
          intervalDays={intervalDays}
          firstChargeDays={firstChargeDays}
          reason={reason}
          loading={subscribeMutation.isPending}
          onChangeToIban={setToIban}
          onChangeAmount={setAmountMajor}
          onChangeIntervalDays={setIntervalDays}
          onChangeFirstChargeDays={setFirstChargeDays}
          onChangeReason={setReason}
          onSubmit={submitCreateRule}
          onClose={() => setCreateOpen(false)}
        />
      ) : null}
    </motion.div>
  )
}

function RecurringHero({ stats, streamerMode }: { stats: RecurringStats; streamerMode: boolean }) {
  const { t, money, relativeTime } = useI18n()
  return (
    <Card variant="glass" padding="none" className="relative overflow-hidden rounded-[1.75rem] border-white/10 shrink-0">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 14% 0%, rgba(0,173,228,0.14), transparent 34%), linear-gradient(180deg, rgba(255,255,255,0.04), transparent 56%)',
        }}
      />
      <div className="relative flex items-center justify-between gap-5 p-4 2xl:p-5">
        <div className="min-w-0 flex flex-col gap-2">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              <RefreshCw size={11} strokeWidth={2.3} />
              {t('recurring.eyebrow')}
            </span>
          </CardEyebrow>
          <div className="flex flex-col gap-1">
            <h1 className="text-3xl 2xl:text-4xl font-light tracking-[-0.055em] text-text-primary">{t('recurring.title')}</h1>
            <p className="text-sm text-text-secondary max-w-[58ch] leading-relaxed">
              {t('recurring.description')}
            </p>
          </div>
        </div>
        <div className="shrink-0 grid grid-cols-3 gap-2 min-w-[420px]">
          <HeroMetric label={t('recurring.activeCount')} value={String(stats.activeCount)} />
          <HeroMetric label={t('recurring.monthEstimate')} value={streamerMode ? maskMoneyDisplay() : money(stats.monthlyMinor / 100)} />
          <HeroMetric label={t('recurring.next')} value={stats.nextChargeMs ? relativeTime(stats.nextChargeMs) : '-'} />
        </div>
      </div>
    </Card>
  )
}

function RecurringCreateDialog({
  fromIban,
  toIban,
  amountMajor,
  intervalDays,
  firstChargeDays,
  reason,
  loading,
  onChangeToIban,
  onChangeAmount,
  onChangeIntervalDays,
  onChangeFirstChargeDays,
  onChangeReason,
  onSubmit,
  onClose,
}: {
  fromIban: string
  toIban: string
  amountMajor: string
  intervalDays: string
  firstChargeDays: string
  reason: string
  loading: boolean
  onChangeToIban: (value: string) => void
  onChangeAmount: (value: string) => void
  onChangeIntervalDays: (value: string) => void
  onChangeFirstChargeDays: (value: string) => void
  onChangeReason: (value: string) => void
  onSubmit: () => void
  onClose: () => void
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4">
      <div className="w-full max-w-md rounded-[1.75rem] border border-white/[0.08] bg-black p-6 shadow-2xl relative overflow-hidden">
        <div
          aria-hidden
          className="absolute inset-x-0 top-0 h-32 pointer-events-none"
          style={{ background: 'radial-gradient(ellipse 80% 60% at 50% 0%, rgba(255, 140, 80, 0.10), transparent)' }}
        />
        <div className="relative flex items-center justify-between gap-3 mb-5">
          <div>
            <h2 className="text-xl font-semibold text-text-primary tracking-[-0.02em]">Create recurring rule</h2>
            <p className="text-xs text-text-secondary mt-1">Set up automatic recurring payments</p>
          </div>
          <Button size="sm" variant="ghost" onClick={onClose} className="shrink-0">Close</Button>
        </div>
        <div className="relative space-y-4">
          <Input label="From" value={fromIban} readOnly />
          <Input label="Destination IBAN" value={toIban} onChange={(event) => onChangeToIban(event.currentTarget.value)} />
          <Input label="Amount" type="number" value={amountMajor} onChange={(event) => onChangeAmount(event.currentTarget.value)} leftAdornment="$" />
          <div className="grid grid-cols-2 gap-3">
            <Input label="Interval days" type="number" value={intervalDays} onChange={(event) => onChangeIntervalDays(event.currentTarget.value)} />
            <Input label="First charge in days" type="number" value={firstChargeDays} onChange={(event) => onChangeFirstChargeDays(event.currentTarget.value)} />
          </div>
          <Input label="Reason" value={reason} onChange={(event) => onChangeReason(event.currentTarget.value)} />
          <div className="pt-2">
            <Button loading={loading} onClick={onSubmit} fullWidth variant="primary" className="h-11" style={{ background: 'var(--color-brand-signal-orange)', color: 'white', border: '1px solid rgba(255, 255, 255, 0.12)', boxShadow: 'rgba(246, 75, 0, 0.9) 0px 16px 28px -20px' }}>Create rule</Button>
          </div>
        </div>
      </div>
    </div>
  )
}
function HeroMetric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-border-subtle bg-white/[0.04] px-3 py-3 text-right min-w-0">
      <span className="block text-[10px] uppercase tracking-[0.16em] text-text-tertiary truncate">{label}</span>
      <span className="block text-sm font-semibold text-text-primary tactile-tabular-nums truncate">{value}</span>
    </div>
  )
}

function RecurringTabs({ tab, counts, onChange }: { tab: RecurringTab; counts: Record<RecurringTab, number>; onChange: (tab: RecurringTab) => void }) {
  const { t } = useI18n()
  const tabs: Array<{ id: RecurringTab; label: string }> = [
    { id: 'active', label: t('recurring.active') },
    { id: 'paused', label: t('recurring.paused') },
    { id: 'history', label: t('recurring.history') },
  ]

  return (
    <div className="grid grid-cols-3 gap-2 shrink-0" role="tablist" aria-label={t('recurring.filterRecurring')}>
      {tabs.map((item) => (
        <button
          key={item.id}
          type="button"
          role="tab"
          aria-selected={tab === item.id}
          onClick={() => {
            onChange(item.id)
            sfx.console_tap()
          }}
          className={cn(
            'rounded-2xl border px-3 py-2.5 text-sm font-semibold transition-colors tactile-focus-ring',
            tab === item.id ? 'border-white/16 bg-white/[0.08] text-text-primary' : 'border-border-subtle bg-white/[0.025] text-text-tertiary hover:text-text-secondary hover:bg-white/[0.055]',
          )}
        >
          <span>{item.label}</span>
          <span className="ml-2 text-[10px] tactile-tabular-nums text-text-tertiary">{counts[item.id]}</span>
        </button>
      ))}
    </div>
  )
}

function RecurringRuleCard({ rule, index, streamerMode, onAction, actionPending }: { rule: Recurring; index: number; streamerMode: boolean; onAction: (rule: Recurring, action: 'pause' | 'resume' | 'cancel') => void; actionPending: boolean }) {
  const { t, money, relativeTime } = useI18n()
  const meta = getRecurringMeta(rule)
  const alias = streamerMode ? t('recurring.hiddenDestination') : getMockAliasForIban(rule.to_iban) ?? t('recurring.beneficiary')
  const reason = streamerMode ? t('recurring.hiddenConcept') : rule.reason ?? t('recurring.recurringPayment')
  const amount = streamerMode ? maskMoneyDisplay() : money(rule.amount_minor / 100)
  const fromIban = streamerMode ? maskIbanCompact(rule.from_iban) : revealIbanDisplay(rule.from_iban)
  const Icon = meta.icon

  return (
    <motion.article
      initial={{ opacity: 0, y: 5 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: Math.min(index, 8) * 0.025, duration: 0.24 }}
      aria-label={safeAriaLabel(`${reason} - ${alias} - ${amount} - ${fromIban}`)}
      className="rounded-[1.35rem] border border-white/[0.075] bg-white/[0.035] p-3.5 hover:bg-white/[0.055] transition-colors"
    >
      <div className="flex items-start gap-3">
        <span className="relative shrink-0" aria-hidden>
          <BankAvatar name={alias} size="lg" />
          <span
            className="absolute -bottom-1 -right-1 inline-flex h-6 w-6 items-center justify-center rounded-full border border-white/10 bg-black/70"
            style={{ color: meta.color }}
          >
            <Icon size={13} strokeWidth={2.2} />
          </span>
        </span>
        <div className="min-w-0 flex-1 flex flex-col gap-2">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <h2 className="text-sm font-semibold text-text-primary truncate">{reason}</h2>
        <p className="text-xs text-text-tertiary truncate">{alias}</p>
            </div>
            <div className="shrink-0 text-right">
              <p className="text-base font-semibold text-text-primary tactile-tabular-nums">{amount}</p>
              <p className="text-[10px] uppercase tracking-[0.13em] text-text-tertiary">{intervalLabel(rule.interval_days)}</p>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-2">
            <RuleMetric label={t('recurring.next')} value={rule.status === 'cancelled' ? t('recurring.finished') : relativeTime(rule.next_charge_ms)} />
            <RuleMetric label={t('recurring.last')} value={rule.last_charge_ms ? relativeTime(rule.last_charge_ms) : '-'} />
            <RuleMetric label={t('common.status')} value={statusText(rule.status)} tone={meta.color} />
          </div>
          <div className="flex flex-wrap gap-2">
            {rule.status === 'active' ? <Button size="sm" variant="secondary" loading={actionPending} onClick={() => onAction(rule, 'pause')}>Pause</Button> : null}
            {rule.status === 'paused' ? <Button size="sm" variant="secondary" loading={actionPending} onClick={() => onAction(rule, 'resume')}>Resume</Button> : null}
            {rule.status !== 'cancelled' ? <Button size="sm" variant="secondary" loading={actionPending} onClick={() => onAction(rule, 'cancel')}>Cancel</Button> : null}
          </div>
        </div>
      </div>
    </motion.article>
  )
}

function RuleMetric({ label, value, tone }: { label: string; value: string; tone?: string }) {
  return (
    <div className="rounded-2xl border border-border-subtle bg-black/[0.12] px-2.5 py-2 min-w-0">
      <span className="block text-[9px] uppercase tracking-[0.13em] text-text-tertiary truncate">{label}</span>
      <span className="block text-xs font-semibold text-text-secondary tactile-tabular-nums truncate" style={tone ? { color: tone } : undefined}>{value}</span>
    </div>
  )
}

function NextPaymentPanel({ rule, streamerMode }: { rule: Recurring | undefined; streamerMode: boolean }) {
  const { t, money, relativeTime } = useI18n()
  if (!rule) {
    return (
      <Card variant="glass" padding="md" className="border-white/10 shrink-0">
        <EmptyRecurring tab="active" compact />
      </Card>
    )
  }

  const alias = streamerMode ? t('recurring.hiddenDestination') : getMockAliasForIban(rule.to_iban) ?? t('recurring.beneficiary')
  const amount = streamerMode ? maskMoneyDisplay() : money(rule.amount_minor / 100)
  const reason = streamerMode ? t('recurring.hiddenConcept') : rule.reason ?? t('recurring.recurringPayment')

  return (
    <Card variant="glass" padding="md" className="relative overflow-hidden border-white/10 shrink-0">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{ background: 'radial-gradient(circle at 86% 0%, rgba(0,173,228,0.14), transparent 38%)' }}
      />
      <div className="relative flex items-start justify-between gap-3">
        <div>
          <CardEyebrow>{t('recurring.nextPayment')}</CardEyebrow>
          <CardTitle className="text-base">{relativeTime(rule.next_charge_ms)}</CardTitle>
        </div>
        <span className="inline-flex h-9 w-9 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.045] text-text-primary">
          <CalendarClock size={17} strokeWidth={2} />
        </span>
      </div>
      <div className="relative mt-4 rounded-[1.35rem] border border-white/10 bg-white/[0.045] p-4">
        <p className="text-3xl font-light tracking-[-0.055em] text-text-primary tactile-tabular-nums">{amount}</p>
        <p className="mt-1 text-sm font-semibold text-text-primary truncate">{reason}</p>
        <p className="text-xs text-text-tertiary truncate">{alias}</p>
      </div>
    </Card>
  )
}

function RecurringBudgetPanel({ stats, streamerMode }: { stats: RecurringStats; streamerMode: boolean }) {
  const { t, money } = useI18n()
  return (
    <Card variant="glass" padding="md" className="border-white/10 shrink-0">
      <div className="flex items-start justify-between gap-3">
        <div>
          <CardEyebrow>{t('recurring.budget')}</CardEyebrow>
          <CardTitle className="text-base">{t('recurring.monthlyLoad')}</CardTitle>
        </div>
        <Wallet size={18} className="text-text-secondary" strokeWidth={2} />
      </div>
      <div className="mt-4 grid grid-cols-2 gap-2">
        <RuleMetric label={t('recurring.estimated')} value={streamerMode ? maskMoneyDisplay() : money(stats.monthlyMinor / 100)} />
        <RuleMetric label={t('recurring.rules')} value={`${stats.activeCount} ${t('recurring.activeRules')}`} />
      </div>
      <p className="mt-3 text-xs text-text-tertiary leading-relaxed">
        {t('recurring.budgetDescription')}
      </p>
    </Card>
  )
}

function RecurringSafetyPanel() {
  const { t } = useI18n()
  return (
    <Card variant="glass" padding="md" className="border-white/10 min-h-0 flex-1 flex flex-col">
      <div className="flex items-center gap-2 text-text-secondary mb-3">
        <ShieldCheck size={15} strokeWidth={2} />
        <span className="text-sm font-semibold">{t('recurring.accountControl')}</span>
      </div>
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center">
          <ShieldCheck size={24} className="text-text-tertiary mx-auto mb-2" strokeWidth={1.5} />
          <p className="text-xs text-text-tertiary leading-relaxed max-w-[28ch]">
            {t('recurring.accountControlLine1')} {t('recurring.accountControlLine2')}
          </p>
        </div>
      </div>
    </Card>
  )
}

function EmptyRecurring({ tab, compact }: { tab: RecurringTab; compact?: boolean }) {
  const { t } = useI18n()
  const copy = tab === 'active'
    ? { title: t('recurring.noActivePayments'), description: t('recurring.noActiveDescription') }
    : tab === 'paused'
      ? { title: t('recurring.noPaused'), description: t('recurring.noPausedDescription') }
      : { title: t('recurring.noHistory'), description: t('recurring.noHistoryDescription') }

  return (
    <div className={cn('flex flex-col items-center justify-center text-center rounded-2xl border border-white/[0.06] bg-white/[0.025]', compact ? 'px-4 py-5' : 'h-full min-h-[220px] px-5 py-8')}>
      <CalendarClock size={compact ? 16 : 24} className="text-text-tertiary mb-2" strokeWidth={1.7} />
      <p className="text-sm font-semibold text-text-primary">{copy.title}</p>
      <p className="text-xs text-text-tertiary max-w-[30ch] leading-relaxed">{copy.description}</p>
    </div>
  )
}

function RecurringLoading() {
  const { t } = useI18n()
  return (
    <div className="h-full w-full flex items-center justify-center text-text-tertiary">
      <div className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/[0.035] px-5 py-4">
        <Spinner size="sm" />
        <span className="text-sm font-medium">{t('recurring.loading')}</span>
      </div>
    </div>
  )
}

interface RecurringStats {
  activeCount: number
  monthlyMinor: number
  nextChargeMs: number | null
}

function computeRecurringStats(rules: Recurring[]): RecurringStats {
  const active = rules.filter((rule) => rule.status === 'active')
  const monthlyMinor = active.reduce((sum, rule) => sum + estimateMonthlyMinor(rule), 0)
  const nextChargeMs = active.length > 0 ? Math.min(...active.map((rule) => rule.next_charge_ms)) : null
  return { activeCount: active.length, monthlyMinor, nextChargeMs }
}

function estimateMonthlyMinor(rule: Recurring): number {
  if (rule.interval_days <= 0) return rule.amount_minor
  return Math.round(rule.amount_minor * (30 / rule.interval_days))
}

function intervalLabel(days: number): string {
  const { t } = useI18n()
  if (days === 7) return t('recurring.weekly')
  if (days === 14) return t('recurring.biweekly')
  if (days >= 28 && days <= 31) return t('recurring.monthly')
  return t('recurring.everyDays').replace('{days}', String(days))
}

function statusText(status: RecurringStatus): string {
  const { t } = useI18n()
  switch (status) {
    case 'active':
      return t('recurring.activeStatus')
    case 'paused':
      return t('recurring.pausedStatus')
    case 'cancelled':
      return t('recurring.cancelledStatus')
  }
}

function getRecurringMeta(rule: Recurring): { icon: typeof RefreshCw; color: string } {
  if (rule.status === 'paused') return { icon: Pause, color: 'rgb(230, 173, 0)' }
  if (rule.status === 'cancelled') return { icon: Receipt, color: 'rgba(247,248,252,0.48)' }
  if (rule.next_charge_ms - Date.now() < 3 * 24 * 60 * 60 * 1000) return { icon: AlertTriangle, color: 'rgb(230, 173, 0)' }
  if (rule.interval_days <= 7) return { icon: Clock, color: 'rgb(0, 173, 228)' }
  if (rule.amount_minor >= 500_00) return { icon: Landmark, color: 'rgb(255, 140, 80)' }
  return { icon: Check, color: 'rgb(53, 193, 119)' }
}
