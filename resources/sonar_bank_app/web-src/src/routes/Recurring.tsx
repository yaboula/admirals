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
import { Button, Card, CardEyebrow, CardTitle, Spinner } from '@/components/ui'
import { BankAvatar } from '@/components/brand/BankAvatar'
import { useBootstrap } from '@/data/queries'
import type { Recurring, RecurringStatus } from '@/data/contracts'
import { getMockAliasForIban } from '@/data/mock/seed'
import { handleBankError } from '@/lib/bankError'
import { cn, formatCurrency, formatRelativeTime } from '@/lib/utils'
import { maskIbanCompact, maskMoneyDisplay, revealIbanDisplay, safeAriaLabel } from '@/lib/privacy'
import { sfx } from '@/lib/sfx'
import { usePrivacyMode } from '@/stores/privacy'
import { toast } from '@/stores/toast'

type RecurringTab = 'active' | 'paused' | 'history'

export function RecurringPayments() {
  const { data, isLoading, isError, error } = useBootstrap()
  const [tab, setTab] = useState<RecurringTab>('active')
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

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
                <CardEyebrow>Reglas</CardEyebrow>
                <CardTitle className="text-base">Pagos programados</CardTitle>
              </div>
              <Button
                variant="secondary"
                size="sm"
                leftIcon={<Plus size={14} />}
                onClick={() => toast.info('Crear regla', 'Disponible cuando el callback C028 esté conectado.')}
              >
                Crear
              </Button>
            </div>
            <RecurringTabs tab={tab} counts={{ active: activeRules.length, paused: pausedRules.length, history: historyRules.length }} onChange={setTab} />
            <div className="min-h-0 flex-1 overflow-y-auto space-y-2 scrollbar-thin">
              {visibleRules.length === 0 ? (
                <EmptyRecurring tab={tab} />
              ) : visibleRules.map((rule, index) => (
                <RecurringRuleCard key={rule.recurring_id} rule={rule} index={index} streamerMode={streamerMode} />
              ))}
            </div>
          </Card>
        </section>

        <aside className="min-h-0 flex flex-col gap-4 2xl:gap-5">
          <NextPaymentPanel rule={nextRule} streamerMode={streamerMode} />
          <RecurringBudgetPanel stats={stats} streamerMode={streamerMode} />
          <RecurringSafetyPanel />
        </aside>
      </div>
    </motion.div>
  )
}

function RecurringHero({ stats, streamerMode }: { stats: RecurringStats; streamerMode: boolean }) {
  return (
    <Card variant="glass" padding="none" className="relative overflow-hidden rounded-[1.75rem] border-white/10 shrink-0">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 14% 0%, oklch(0.70 0.14 230 / 0.14), transparent 34%), linear-gradient(180deg, oklch(1 0 0 / 0.035), transparent 56%)',
        }}
      />
      <div className="relative flex items-center justify-between gap-5 p-4 2xl:p-5">
        <div className="min-w-0 flex flex-col gap-2">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              <RefreshCw size={11} strokeWidth={2.3} />
              RECURRENTES
            </span>
          </CardEyebrow>
          <div className="flex flex-col gap-1">
            <h1 className="text-3xl 2xl:text-4xl font-light tracking-[-0.055em] text-text-primary">Pagos bajo control</h1>
            <p className="text-sm text-text-secondary max-w-[58ch] leading-relaxed">
              Revisa alquileres, cuotas y servicios antes de que salgan de tu cuenta.
            </p>
          </div>
        </div>
        <div className="shrink-0 grid grid-cols-3 gap-2 min-w-[420px]">
          <HeroMetric label="Activos" value={String(stats.activeCount)} />
          <HeroMetric label="Mes estimado" value={streamerMode ? maskMoneyDisplay() : formatCurrency(stats.monthlyMinor / 100)} />
          <HeroMetric label="Próximo" value={stats.nextChargeMs ? formatRelativeTime(stats.nextChargeMs) : '—'} />
        </div>
      </div>
    </Card>
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
  const tabs: Array<{ id: RecurringTab; label: string }> = [
    { id: 'active', label: 'Activos' },
    { id: 'paused', label: 'Pausados' },
    { id: 'history', label: 'Historial' },
  ]

  return (
    <div className="grid grid-cols-3 gap-2 shrink-0" role="tablist" aria-label="Filtrar pagos recurrentes">
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

function RecurringRuleCard({ rule, index, streamerMode }: { rule: Recurring; index: number; streamerMode: boolean }) {
  const meta = getRecurringMeta(rule)
  const alias = streamerMode ? 'Destino oculto' : getMockAliasForIban(rule.to_iban) ?? 'Beneficiario'
  const reason = streamerMode ? 'Concepto oculto' : rule.reason ?? 'Pago recurrente'
  const amount = streamerMode ? maskMoneyDisplay() : formatCurrency(rule.amount_minor / 100)
  const fromIban = streamerMode ? maskIbanCompact(rule.from_iban) : revealIbanDisplay(rule.from_iban)
  const Icon = meta.icon

  return (
    <motion.article
      initial={{ opacity: 0, y: 5 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: Math.min(index, 8) * 0.025, duration: 0.24 }}
      aria-label={safeAriaLabel(`${reason} · ${alias} · ${amount} · ${fromIban}`)}
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
              <p className="text-xs text-text-tertiary truncate">{alias} · {fromIban}</p>
            </div>
            <div className="shrink-0 text-right">
              <p className="text-base font-semibold text-text-primary tactile-tabular-nums">{amount}</p>
              <p className="text-[10px] uppercase tracking-[0.13em] text-text-tertiary">{intervalLabel(rule.interval_days)}</p>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-2">
            <RuleMetric label="Próximo" value={rule.status === 'cancelled' ? 'Finalizado' : formatRelativeTime(rule.next_charge_ms)} />
            <RuleMetric label="Último" value={rule.last_charge_ms ? formatRelativeTime(rule.last_charge_ms) : '—'} />
            <RuleMetric label="Estado" value={statusText(rule.status)} tone={meta.color} />
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
  if (!rule) {
    return (
      <Card variant="glass" padding="md" className="border-white/10 shrink-0">
        <EmptyRecurring tab="active" compact />
      </Card>
    )
  }

  const alias = streamerMode ? 'Destino oculto' : getMockAliasForIban(rule.to_iban) ?? 'Beneficiario'
  const amount = streamerMode ? maskMoneyDisplay() : formatCurrency(rule.amount_minor / 100)
  const reason = streamerMode ? 'Concepto oculto' : rule.reason ?? 'Pago recurrente'

  return (
    <Card variant="glass" padding="md" className="relative overflow-hidden border-white/10 shrink-0">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{ background: 'radial-gradient(circle at 86% 0%, oklch(0.70 0.14 230 / 0.14), transparent 38%)' }}
      />
      <div className="relative flex items-start justify-between gap-3">
        <div>
          <CardEyebrow>Próxima salida</CardEyebrow>
          <CardTitle className="text-base">{formatRelativeTime(rule.next_charge_ms)}</CardTitle>
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
  return (
    <Card variant="glass" padding="md" className="border-white/10 shrink-0">
      <div className="flex items-start justify-between gap-3">
        <div>
          <CardEyebrow>Presupuesto</CardEyebrow>
          <CardTitle className="text-base">Carga mensual</CardTitle>
        </div>
        <Wallet size={18} className="text-text-secondary" strokeWidth={2} />
      </div>
      <div className="mt-4 grid grid-cols-2 gap-2">
        <RuleMetric label="Estimado" value={streamerMode ? maskMoneyDisplay() : formatCurrency(stats.monthlyMinor / 100)} />
        <RuleMetric label="Reglas" value={`${stats.activeCount} activas`} />
      </div>
      <p className="mt-3 text-xs text-text-tertiary leading-relaxed">
        Ideal para alquileres, cuotas de coches, negocios o servicios que no quieres olvidar durante el rol.
      </p>
    </Card>
  )
}

function RecurringSafetyPanel() {
  return (
    <Card variant="glass" padding="md" className="border-white/10 min-h-0 flex-1">
      <div className="flex items-center gap-2 text-text-secondary mb-3">
        <ShieldCheck size={15} strokeWidth={2} />
        <span className="text-sm font-semibold">Control del jugador</span>
      </div>
      <div className="space-y-2 text-xs text-text-tertiary leading-relaxed">
        <p>Los pagos se revisan desde tu cuenta, con estado visible antes del siguiente cargo.</p>
        <p>Las acciones de crear, pausar o borrar quedan preparadas para C027-C031 cuando backend las exponga.</p>
      </div>
    </Card>
  )
}

function EmptyRecurring({ tab, compact }: { tab: RecurringTab; compact?: boolean }) {
  const copy = tab === 'active'
    ? { title: 'Sin pagos activos', description: 'Cuando programes alquileres o cuotas aparecerán aquí.' }
    : tab === 'paused'
      ? { title: 'Nada pausado', description: 'Las reglas detenidas temporalmente vivirán en esta pestaña.' }
      : { title: 'Sin historial', description: 'Las reglas finalizadas quedarán archivadas aquí.' }

  return (
    <div className={cn('flex flex-col items-center justify-center text-center rounded-2xl border border-white/[0.06] bg-white/[0.025]', compact ? 'px-4 py-5' : 'h-full min-h-[220px] px-5 py-8')}>
      <CalendarClock size={compact ? 16 : 24} className="text-text-tertiary mb-2" strokeWidth={1.7} />
      <p className="text-sm font-semibold text-text-primary">{copy.title}</p>
      <p className="text-xs text-text-tertiary max-w-[30ch] leading-relaxed">{copy.description}</p>
    </div>
  )
}

function RecurringLoading() {
  return (
    <div className="h-full w-full flex items-center justify-center text-text-tertiary">
      <div className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/[0.035] px-5 py-4">
        <Spinner size="sm" />
        <span className="text-sm font-medium">Cargando recurrentes</span>
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
  if (days === 7) return 'Semanal'
  if (days === 14) return 'Quincenal'
  if (days >= 28 && days <= 31) return 'Mensual'
  return `Cada ${days}d`
}

function statusText(status: RecurringStatus): string {
  switch (status) {
    case 'active':
      return 'Activo'
    case 'paused':
      return 'Pausado'
    case 'cancelled':
      return 'Archivado'
  }
}

function getRecurringMeta(rule: Recurring): { icon: typeof RefreshCw; color: string } {
  if (rule.status === 'paused') return { icon: Pause, color: 'oklch(0.78 0.16 85)' }
  if (rule.status === 'cancelled') return { icon: Receipt, color: 'oklch(0.98 0.005 270 / 0.48)' }
  if (rule.next_charge_ms - Date.now() < 3 * 24 * 60 * 60 * 1000) return { icon: AlertTriangle, color: 'oklch(0.78 0.16 85)' }
  if (rule.interval_days <= 7) return { icon: Clock, color: 'oklch(0.70 0.14 230)' }
  if (rule.amount_minor >= 500_00) return { icon: Landmark, color: 'oklch(0.70 0.22 40)' }
  return { icon: Check, color: 'oklch(0.72 0.16 155)' }
}
