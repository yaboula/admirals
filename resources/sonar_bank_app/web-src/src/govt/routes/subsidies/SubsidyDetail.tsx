import { motion } from 'motion/react'
import {
  ArrowDownToLine, HandCoins, Sprout, Users, type LucideIcon,
} from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { GovtCard } from '../../components/GovtCard'
import { GovtPill } from '../../components/GovtPill'
import type {
  GovtSubsidyProgramDetail,
  GovtSubsidyStatus,
  GovtSubsidyType,
} from '../../data/contracts'

interface Props {
  detail: GovtSubsidyProgramDetail
  isFetching?: boolean
}

const STATUS_TONE: Record<GovtSubsidyStatus, { tone: 'success' | 'warning' | 'neutral' | 'accent'; key: TranslationKey }> = {
  active:    { tone: 'success', key: 'govt.subsidies.status.active' },
  paused:    { tone: 'warning', key: 'govt.subsidies.status.paused' },
  completed: { tone: 'neutral', key: 'govt.subsidies.status.completed' },
  proposed:  { tone: 'accent',  key: 'govt.subsidies.status.proposed' },
}

const TYPE_COLOR: Record<GovtSubsidyType, string> = {
  food:         'oklch(0.72 0.18 155)',
  housing:      'oklch(0.72 0.15 215)',
  employment:   'oklch(0.78 0.16 85)',
  medical:      'oklch(0.74 0.18 10)',
  education:    'oklch(0.72 0.15 265)',
  emergency:    'oklch(0.72 0.20 35)',
  agricultural: 'oklch(0.72 0.18 135)',
}

const TYPE_KEY: Record<GovtSubsidyType, TranslationKey> = {
  food:         'govt.subsidies.type.food',
  housing:      'govt.subsidies.type.housing',
  employment:   'govt.subsidies.type.employment',
  medical:      'govt.subsidies.type.medical',
  education:    'govt.subsidies.type.education',
  emergency:    'govt.subsidies.type.emergency',
  agricultural: 'govt.subsidies.type.agricultural',
}

const DISB_STATUS_DOT: Record<string, string> = {
  confirmed: 'bg-[oklch(0.65_0.18_155)]',
  pending:   'bg-[oklch(0.78_0.16_85)]',
  reversed:  'bg-[oklch(0.72_0.20_35)]',
}
const DISB_STATUS_KEY: Record<string, TranslationKey> = {
  confirmed: 'govt.subsidies.disbursement.confirmed',
  pending:   'govt.subsidies.disbursement.pending',
  reversed:  'govt.subsidies.disbursement.reversed',
}

export function SubsidyDetail({ detail, isFetching }: Props) {
  const { t, money, number, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const status = STATUS_TONE[detail.status]
  const typeColor = TYPE_COLOR[detail.type]
  const pct = detail.budget > 0 ? Math.min(100, Math.round((detail.disbursed / detail.budget) * 100)) : 0
  const remaining = detail.budget - detail.disbursed
  const isActive = detail.status === 'active'

  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.22 }}
      className={cn('flex h-full flex-col gap-3 overflow-y-auto pr-1 scrollbar-thin', isFetching && 'opacity-80')}
    >
      <GovtCard variant="hero" padding="lg">
        <div className="flex items-center gap-4">
          <div
            aria-hidden
            className="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-2xl border-2"
            style={{
              background: 'radial-gradient(circle at 50% 30%, oklch(0.18 0.018 252), oklch(0.08 0.010 252))',
              borderColor: 'var(--color-govt-border-strong)',
              color: typeColor,
            }}
          >
            <Sprout size={22} strokeWidth={1.7} />
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="truncate text-2xl font-light leading-tight tracking-[-0.04em] text-[var(--color-govt-text-primary)]">{detail.name}</h2>
            <p className="mt-0.5 truncate font-mono text-[11px] uppercase tracking-[0.18em] text-[var(--color-govt-text-tertiary)]">{detail.code}</p>
          </div>
        </div>
        <div className="mt-3 flex flex-wrap items-center gap-2">
          <GovtPill tone={status.tone} size="md">{t(status.key)}</GovtPill>
          <GovtPill tone="neutral" size="md">{t(TYPE_KEY[detail.type])}</GovtPill>
          {detail.endDate ? (
            <GovtPill tone="seal" size="md">{`${t('govt.subsidies.detail.ends')}: ${dateTime(detail.endDate, { dateStyle: 'short' })}`}</GovtPill>
          ) : (
            <GovtPill tone="seal" size="md">{t('govt.subsidies.detail.openEnded')}</GovtPill>
          )}
        </div>
      </GovtCard>

      <GovtCard variant="glass" padding="md">
        <SectionHeader icon={HandCoins} label={t('govt.subsidies.detail.budgetTitle')} />
        <div className="mt-3 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <Stat label={t('govt.subsidies.detail.budget')} value={streamerMode ? maskMoneyDisplay() : money(detail.budget)} />
          <Stat label={t('govt.subsidies.detail.disbursed')} value={streamerMode ? maskMoneyDisplay() : money(detail.disbursed)} tone="success" />
          <Stat label={t('govt.subsidies.detail.remaining')} value={streamerMode ? maskMoneyDisplay() : money(remaining)} tone={remaining < detail.budget * 0.1 ? 'warning' : 'neutral'} />
          <Stat label={t('govt.subsidies.detail.utilization')} value={`${pct}%`} tone={pct >= 90 ? 'warning' : 'neutral'} />
        </div>
        <div className="mt-3">
          <div className="flex items-center justify-between text-[10px] text-[var(--color-govt-text-tertiary)] mb-1.5">
            <span className="font-semibold uppercase tracking-[0.14em]">{t('govt.subsidies.detail.utilizationBar')}</span>
            <span className="tabular-nums" style={{ color: typeColor }}>{pct}%</span>
          </div>
          <div className="h-2 w-full overflow-hidden rounded-full bg-white/[0.05]" aria-hidden>
            <span
              className="block h-full rounded-full transition-[width] duration-700"
              style={{ width: `${pct}%`, background: typeColor }}
            />
          </div>
        </div>
      </GovtCard>

      <GovtCard variant="glass" padding="md">
        <SectionHeader icon={Users} label={t('govt.subsidies.detail.beneficiariesTitle')} />
        <div className="mt-3 grid grid-cols-2 gap-3">
          <Stat label={t('govt.subsidies.detail.beneficiaryCount')} value={number(detail.beneficiaryCount)} />
          <Stat label={t('govt.subsidies.detail.startDate')} value={dateTime(detail.startDate, { dateStyle: 'medium' })} />
        </div>
        {detail.description ? (
          <p className="mt-3 rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.04_0.008_252/0.60)] p-3 text-[12px] leading-relaxed text-[var(--color-govt-text-secondary)]">
            {detail.description}
          </p>
        ) : null}
      </GovtCard>

      <GovtCard variant="glass" padding="md" className="min-w-0 flex-1">
        <SectionHeader icon={ArrowDownToLine} label={t('govt.subsidies.detail.disbursementsTitle')} />
        {detail.recentDisbursements.length === 0 ? (
          <p className="mt-3 text-xs text-[var(--color-govt-text-tertiary)]">{t('govt.subsidies.detail.disbursementsEmpty')}</p>
        ) : (
          <ul className="mt-3 space-y-2">
            {detail.recentDisbursements.map((d) => {
              const amtDisplay = streamerMode ? maskMoneyDisplay() : money(d.amount)
              return (
                <li
                  key={d.id}
                  className="flex items-center gap-3 rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.04_0.008_252/0.60)] p-2.5"
                >
                  <span
                    aria-hidden
                    className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-xl"
                    style={{ background: 'var(--color-govt-accent-subtle)', color: typeColor }}
                  >
                    <HandCoins size={13} strokeWidth={2} />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[12px] font-medium text-[var(--color-govt-text-primary)]">{d.recipientLabel}</p>
                    <p className="text-[10px] uppercase tracking-[0.12em] text-[var(--color-govt-text-tertiary)]">
                      {`${d.recipientId} · ${dateTime(d.disbursedAt, { dateStyle: 'short', timeStyle: 'short' })}`}
                    </p>
                  </div>
                  <div className="flex flex-shrink-0 flex-col items-end gap-1">
                    <span className="text-[12px] font-semibold tabular-nums text-[oklch(0.75_0.17_155)]">{amtDisplay}</span>
                    <span className="flex items-center gap-1 text-[9px] uppercase tracking-[0.12em] text-[var(--color-govt-text-tertiary)]">
                      <span className={cn('h-1.5 w-1.5 rounded-full', DISB_STATUS_DOT[d.status])} aria-hidden />
                      {t(DISB_STATUS_KEY[d.status] ?? 'govt.subsidies.disbursement.confirmed')}
                    </span>
                  </div>
                </li>
              )
            })}
          </ul>
        )}
      </GovtCard>

      <GovtCard variant="outline" padding="md" className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
            {t('govt.subsidies.detail.actionsTitle')}
          </p>
          <p className="mt-1 text-xs text-[var(--color-govt-text-secondary)]">
            {isActive ? t('govt.subsidies.detail.actionsHint') : t('govt.subsidies.detail.actionsInactive')}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <ActionButton icon={HandCoins} label={t('govt.subsidies.detail.disburseToCitizen')} disabled />
          <ActionButton icon={Sprout} label={t('govt.subsidies.detail.grantToCompany')} disabled />
        </div>
      </GovtCard>
    </motion.div>
  )
}

function SectionHeader({ icon: Icon, label }: { icon: LucideIcon; label: string }) {
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

function Stat({ label, value, tone = 'neutral' }: { label: string; value: string; tone?: 'neutral' | 'success' | 'warning' }) {
  const colorClass =
    tone === 'success' ? 'text-[oklch(0.78_0.16_155)]' : tone === 'warning' ? 'text-[oklch(0.85_0.14_85)]' : 'text-[var(--color-govt-text-primary)]'
  return (
    <div className="rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.04_0.008_252/0.60)] p-3">
      <span className="block text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{label}</span>
      <span className={cn('mt-1 block truncate text-sm font-semibold tabular-nums', colorClass)}>{value}</span>
    </div>
  )
}

function ActionButton({ icon: Icon, label, disabled }: { icon: LucideIcon; label: string; disabled: boolean }) {
  const { t } = useI18n()
  return (
    <button
      type="button"
      disabled={disabled}
      className="inline-flex h-9 cursor-not-allowed items-center gap-2 rounded-full border border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] px-3.5 text-[11px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]"
      title={`${label} (${t('nav.comingSoon')})`}
    >
      <Icon size={13} strokeWidth={2} />
      <span>{label}</span>
      <span className="ml-1 rounded-full bg-white/[0.05] px-1.5 py-0.5 text-[9px] tracking-[0.10em]">{t('nav.comingSoon')}</span>
    </button>
  )
}
