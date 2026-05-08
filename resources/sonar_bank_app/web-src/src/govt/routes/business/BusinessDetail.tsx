import { motion } from 'motion/react'
import {
  ArrowDownRight, ArrowUpRight, Banknote, BriefcaseBusiness,
  Flag, Gavel, HandCoins, Receipt, ScanLine, Shield, Users, Wallet,
  type LucideIcon,
} from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { maskIbanPanel, maskMoneyDisplay, maskSignedMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { GovtCard } from '../../components/GovtCard'
import { GovtPill } from '../../components/GovtPill'
import type {
  GovtBusinessActivityType,
  GovtBusinessDetail,
  GovtBusinessStatus,
  GovtFlagSeverity,
  GovtFlagStatus,
  GovtRiskLevel,
} from '../../data/contracts'

interface Props {
  detail: GovtBusinessDetail
  isFetching?: boolean
}

const STATUS_TONE: Record<GovtBusinessStatus, { tone: 'success' | 'warning' | 'danger' | 'neutral'; key: TranslationKey }> = {
  active:      { tone: 'success', key: 'govt.business.status.active' },
  frozen:      { tone: 'warning', key: 'govt.business.status.frozen' },
  liquidating: { tone: 'warning', key: 'govt.business.status.liquidating' },
  dissolved:   { tone: 'neutral', key: 'govt.business.status.dissolved' },
}

const RISK_TONE: Record<GovtRiskLevel, { color: string; key: TranslationKey }> = {
  low:      { color: 'oklch(0.65 0.18 155)', key: 'govt.census.risk.low' },
  medium:   { color: 'oklch(0.78 0.16 85)',  key: 'govt.census.risk.medium' },
  high:     { color: 'oklch(0.72 0.20 35)',  key: 'govt.census.risk.high' },
  critical: { color: 'oklch(0.62 0.21 25)',  key: 'govt.census.risk.critical' },
}

const RISK_SEGS = [
  { color: 'oklch(0.65 0.18 155)', min: 0, max: 25 },
  { color: 'oklch(0.78 0.16 85)',  min: 26, max: 50 },
  { color: 'oklch(0.72 0.20 35)',  min: 51, max: 75 },
  { color: 'oklch(0.62 0.21 25)',  min: 76, max: 100 },
] as const

const ACTIVITY_ICON: Record<GovtBusinessActivityType, LucideIcon> = {
  payroll_processed: HandCoins,
  tax_payment:       Receipt,
  transfer_in:       ArrowDownRight,
  transfer_out:      ArrowUpRight,
  employee_hired:    Users,
  employee_fired:    Users,
  flag_raised:       Flag,
  sanction_applied:  Shield,
}

const ACTIVITY_LABEL: Record<GovtBusinessActivityType, TranslationKey> = {
  payroll_processed: 'govt.business.activity.payroll_processed',
  tax_payment:       'govt.business.activity.tax_payment',
  transfer_in:       'govt.business.activity.transfer_in',
  transfer_out:      'govt.business.activity.transfer_out',
  employee_hired:    'govt.business.activity.employee_hired',
  employee_fired:    'govt.business.activity.employee_fired',
  flag_raised:       'govt.business.activity.flag_raised',
  sanction_applied:  'govt.business.activity.sanction_applied',
}

const FLAG_SEVERITY_TONE: Record<GovtFlagSeverity, { color: string; key: TranslationKey }> = {
  info:     { color: 'oklch(0.78 0.10 215)', key: 'govt.census.flags.severity.info' },
  low:      { color: 'oklch(0.65 0.18 155)', key: 'govt.census.flags.severity.low' },
  medium:   { color: 'oklch(0.78 0.16 85)',  key: 'govt.census.flags.severity.medium' },
  high:     { color: 'oklch(0.72 0.20 35)',  key: 'govt.census.flags.severity.high' },
  critical: { color: 'oklch(0.62 0.21 25)',  key: 'govt.census.flags.severity.critical' },
}

const FLAG_STATUS_LABEL: Record<GovtFlagStatus, TranslationKey> = {
  open:       'govt.census.flags.status.open',
  reviewing:  'govt.census.flags.status.reviewing',
  resolved:   'govt.census.flags.status.resolved',
  dismissed:  'govt.census.flags.status.dismissed',
}

const SECTOR_LABEL_KEY: Record<string, TranslationKey> = {
  farming:   'govt.business.sector.farming',
  milling:   'govt.business.sector.milling',
  bakery:    'govt.business.sector.bakery',
  retail:    'govt.business.sector.retail',
  logistics: 'govt.business.sector.logistics',
  services:  'govt.business.sector.services',
  finance:   'govt.business.sector.finance',
  other:     'govt.business.sector.other',
}

export function BusinessDetail({ detail, isFetching }: Props) {
  const { t, money, signedMoney, number, dateTime, relativeTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const status = STATUS_TONE[detail.status]
  const risk = RISK_TONE[detail.riskLevel]

  const ibanDisplay = streamerMode ? maskIbanPanel(detail.ibanPrimary) : detail.ibanPrimary
  const treasuryDisplay = streamerMode ? maskMoneyDisplay() : money(detail.treasury)

  const taxPaidPct =
    detail.taxStatus.periodObligation > 0
      ? Math.min(100, Math.round((detail.taxStatus.paid / detail.taxStatus.periodObligation) * 100))
      : 0

  const sectorKey = SECTOR_LABEL_KEY[detail.sector] ?? 'govt.business.sector.other'

  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.22 }}
      className={cn('flex h-full flex-col gap-3 overflow-y-auto pr-1 scrollbar-thin', isFetching && 'opacity-80')}
    >
      <GovtCard variant="hero" padding="lg" className="overflow-hidden">
        <div className="flex items-center gap-4">
          <div
            aria-hidden
            className="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-2xl border-2 text-white"
            style={{
              background: 'radial-gradient(circle at 50% 30%, oklch(0.18 0.018 252), oklch(0.08 0.010 252))',
              borderColor: 'var(--color-govt-border-strong)',
            }}
          >
            <BriefcaseBusiness size={22} strokeWidth={1.7} />
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="truncate text-2xl font-light leading-tight tracking-[-0.04em] text-[var(--color-govt-text-primary)]">{detail.name}</h2>
            <p className="mt-0.5 truncate font-mono text-[11px] uppercase tracking-[0.18em] text-[var(--color-govt-text-tertiary)]">{detail.companyId}</p>
          </div>
        </div>
        <div className="mt-3 flex flex-wrap items-center gap-2">
          <GovtPill tone={status.tone} size="md">{t(status.key)}</GovtPill>
          <GovtPill tone="neutral" size="md">{t(sectorKey)}</GovtPill>
          <GovtPill tone="seal" size="md">{`${t('govt.business.detail.founded')}: ${number(detail.operatingDays)}d`}</GovtPill>
        </div>
      </GovtCard>

      <div className="grid gap-3 lg:grid-cols-[minmax(0,1.1fr)_minmax(0,0.9fr)]">
        <GovtCard variant="glass" padding="md">
          <SectionHeader icon={Wallet} label={t('govt.business.detail.treasuryTitle')} />
          <div className="mt-3 space-y-3">
            <Stat label={t('govt.business.detail.treasuryTotal')} value={treasuryDisplay} prominent />
            <div className="grid gap-3 sm:grid-cols-2">
              <Stat label={t('govt.business.detail.employeeCount')} value={number(detail.employeeCount)} />
              <Stat label={t('govt.business.detail.flagsCount')} value={number(detail.flagCount)} tone={detail.flagCount > 0 ? 'warning' : 'neutral'} />
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <Stat label={t('govt.business.detail.payrollMonthly')} value={streamerMode ? maskMoneyDisplay() : money(detail.payrollMonthly)} />
            </div>
          </div>
          <div className="mt-3 rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.04_0.008_252/0.60)] p-3">
            <span className="block text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
              {t('govt.business.detail.primaryIban')}
            </span>
            <span className="mt-1 block truncate font-mono text-[12px] tracking-[0.10em] text-[var(--color-govt-text-secondary)]">{ibanDisplay}</span>
          </div>
        </GovtCard>

        <GovtCard variant="glass" padding="md">
          <SectionHeader icon={Shield} label={t('govt.census.detail.riskTitle')} />
          <RiskGauge score={detail.riskScore} color={risk.color} levelLabel={t(risk.key)} />
        </GovtCard>
      </div>

      <GovtCard variant="glass" padding="md">
        <SectionHeader icon={Receipt} label={t('govt.census.detail.taxTitle')} />
        <div className="mt-3 grid grid-cols-2 gap-3 lg:grid-cols-4">
          <Stat label={t('govt.census.detail.taxBracket')} value={detail.taxStatus.bracketCode} />
          <Stat label={t('govt.census.detail.taxObligation')} value={streamerMode ? maskMoneyDisplay() : money(detail.taxStatus.periodObligation)} />
          <Stat label={t('govt.census.detail.taxPaid')} value={streamerMode ? maskMoneyDisplay() : money(detail.taxStatus.paid)} tone="success" />
          <Stat
            label={t('govt.census.detail.taxOutstanding')}
            value={streamerMode ? maskMoneyDisplay() : money(detail.taxStatus.outstanding)}
            tone={detail.taxStatus.outstanding > 0 ? 'warning' : 'success'}
          />
        </div>
        <div className="mt-3 h-1.5 w-full overflow-hidden rounded-full bg-white/[0.05]" aria-hidden>
          <span
            className="block h-full rounded-full transition-[width] duration-500"
            style={{
              width: `${taxPaidPct}%`,
              background: taxPaidPct >= 100 ? 'oklch(0.65 0.18 155)' : taxPaidPct >= 50 ? 'oklch(0.78 0.16 85)' : 'oklch(0.72 0.20 35)',
            }}
          />
        </div>
      </GovtCard>

      <GovtCard variant="glass" padding="md">
        <SectionHeader icon={Users} label={t('govt.business.detail.directorsTitle')} />
        {detail.directors.length === 0 ? (
          <p className="mt-3 text-xs text-[var(--color-govt-text-tertiary)]">{t('govt.business.detail.directorsEmpty')}</p>
        ) : (
          <ul className="mt-3 grid gap-2 sm:grid-cols-2">
            {detail.directors.map((dir) => (
              <li
                key={dir.cid}
                className="flex items-center gap-3 rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.04_0.008_252/0.60)] p-2.5"
              >
                <span
                  aria-hidden
                  className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-xl text-[var(--color-govt-accent-light)]"
                  style={{ background: 'var(--color-govt-accent-subtle)' }}
                >
                  <BriefcaseBusiness size={13} strokeWidth={2} />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[12px] font-semibold text-[var(--color-govt-text-primary)]">{dir.alias}</p>
                  <p className="text-[10px] uppercase tracking-[0.12em] text-[var(--color-govt-text-tertiary)]">
                    {`${t((`govt.business.director.${dir.role}`) as TranslationKey)} · ${dateTime(dir.joinedAt, { dateStyle: 'short' })}`}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        )}
      </GovtCard>

      <div className="grid gap-3 lg:grid-cols-[minmax(0,1.1fr)_minmax(0,0.9fr)]">
        <GovtCard variant="glass" padding="md" className="min-w-0">
          <SectionHeader icon={ScanLine} label={t('govt.census.detail.activityTitle')} />
          {detail.recentActivity.length === 0 ? (
            <p className="mt-3 text-xs text-[var(--color-govt-text-tertiary)]">{t('govt.census.detail.activityEmpty')}</p>
          ) : (
            <ul className="mt-3 space-y-2">
              {detail.recentActivity.slice(0, 8).map((entry) => {
                const Icon = ACTIVITY_ICON[entry.type]
                const isMonetary = entry.amount !== 0
                const isPositive = entry.amount > 0
                const valueDisplay = !isMonetary ? '—' : streamerMode ? maskSignedMoneyDisplay() : signedMoney(entry.amount)
                return (
                  <li
                    key={entry.id}
                    className="flex items-center gap-3 rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.04_0.008_252/0.60)] p-2.5"
                  >
                    <span
                      aria-hidden
                      className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-xl"
                      style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}
                    >
                      <Icon size={14} strokeWidth={1.9} />
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-[12px] font-medium text-[var(--color-govt-text-primary)]">{entry.description}</p>
                      <p className="text-[10px] uppercase tracking-[0.12em] text-[var(--color-govt-text-tertiary)]">
                        {`${t(ACTIVITY_LABEL[entry.type])} · ${dateTime(entry.timestamp, { dateStyle: 'short', timeStyle: 'short' })}`}
                      </p>
                    </div>
                    {isMonetary ? (
                      <span
                        className={cn(
                          'flex-shrink-0 text-[12px] font-semibold tactile-tabular-nums',
                          isPositive ? 'text-[oklch(0.78_0.16_155)]' : 'text-[var(--color-govt-text-secondary)]',
                        )}
                      >
                        {valueDisplay}
                      </span>
                    ) : null}
                  </li>
                )
              })}
            </ul>
          )}
        </GovtCard>

        <GovtCard variant="glass" padding="md" className="min-w-0">
          <SectionHeader icon={Flag} label={t('govt.census.detail.flagsTitle')} />
          {detail.flags.length === 0 ? (
            <p className="mt-3 text-xs text-[var(--color-govt-text-tertiary)]">{t('govt.census.detail.flagsEmpty')}</p>
          ) : (
            <ul className="mt-3 space-y-2">
              {detail.flags.slice(0, 6).map((flag) => {
                const sev = FLAG_SEVERITY_TONE[flag.severity]
                return (
                  <li
                    key={flag.id}
                    className="rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.04_0.008_252/0.60)] p-2.5"
                  >
                    <div className="flex items-start gap-2">
                      <span aria-hidden className="mt-1 h-2 w-2 flex-shrink-0 rounded-full" style={{ background: sev.color }} />
                      <div className="min-w-0 flex-1">
                        <p className="line-clamp-2 text-[12px] text-[var(--color-govt-text-primary)]">{flag.summary}</p>
                        <p className="mt-1 flex flex-wrap items-center gap-2 text-[10px] uppercase tracking-[0.12em] text-[var(--color-govt-text-tertiary)]">
                          <span style={{ color: sev.color }}>{t(sev.key)}</span>
                          <span className="text-[var(--color-govt-text-quaternary)]">·</span>
                          <span>{t(FLAG_STATUS_LABEL[flag.status])}</span>
                          <span className="text-[var(--color-govt-text-quaternary)]">·</span>
                          <span>{relativeTime(flag.raisedAt)}</span>
                        </p>
                      </div>
                    </div>
                  </li>
                )
              })}
            </ul>
          )}
        </GovtCard>
      </div>

      <GovtCard variant="outline" padding="md" className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
            {t('govt.census.detail.actionsTitle')}
          </p>
          <p className="mt-1 text-xs text-[var(--color-govt-text-secondary)]">{t('govt.business.detail.actionsHint')}</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <ActionButton icon={Gavel} label={t('govt.business.detail.openInvestigate')} />
          <ActionButton icon={Banknote} label={t('govt.business.detail.openFreeze')} />
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

function Stat({
  label,
  value,
  prominent = false,
  tone = 'neutral',
}: {
  label: string
  value: string
  prominent?: boolean
  tone?: 'neutral' | 'success' | 'warning'
}) {
  const toneClass =
    tone === 'success'
      ? 'text-[oklch(0.78_0.16_155)]'
      : tone === 'warning'
        ? 'text-[oklch(0.85_0.14_85)]'
        : 'text-[var(--color-govt-text-primary)]'
  return (
    <div className="rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.04_0.008_252/0.60)] p-3">
      <span className="block text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{label}</span>
      <span className={cn('mt-1 block truncate tactile-tabular-nums', prominent ? 'text-2xl font-semibold tracking-[-0.02em]' : 'text-sm font-medium', toneClass)}>
        {value}
      </span>
    </div>
  )
}

function RiskGauge({ score, color, levelLabel }: { score: number; color: string; levelLabel: string }) {
  const { t, number } = useI18n()
  const pct = Math.max(0, Math.min(100, score))
  const r = 36
  const cx = 48
  const cy = 48
  const circ = 2 * Math.PI * r
  const sweepArc = (270 / 360) * circ
  const fillArc = (pct / 100) * sweepArc
  return (
    <div className="mt-3 flex items-center gap-4">
      <div className="relative flex-shrink-0" style={{ width: 96, height: 96 }}>
        <svg width="96" height="96" viewBox="0 0 96 96" aria-hidden>
          <circle
            cx={cx} cy={cy} r={r}
            fill="none"
            stroke="oklch(1 0 0 / 0.07)"
            strokeWidth="8"
            strokeLinecap="round"
            strokeDasharray={`${sweepArc} ${circ - sweepArc}`}
            transform={`rotate(135 ${cx} ${cy})`}
          />
          {pct > 0 ? (
            <circle
              cx={cx} cy={cy} r={r}
              fill="none"
              stroke={color}
              strokeWidth="8"
              strokeLinecap="round"
              strokeDasharray={`${fillArc} ${circ - fillArc}`}
              transform={`rotate(135 ${cx} ${cy})`}
              style={{ filter: `drop-shadow(0 0 5px ${color}55)`, transition: 'stroke-dasharray 0.6s ease' }}
            />
          ) : null}
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center" aria-label={`${t('govt.census.detail.riskScoreLabel')}: ${pct}`}>
          <span className="text-xl font-semibold tabular-nums leading-none tracking-[-0.03em]" style={{ color }}>{number(score)}</span>
          <span className="mt-0.5 text-[8px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{t('govt.census.detail.riskScoreLabel')}</span>
        </div>
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold uppercase tracking-[0.06em]" style={{ color }}>{levelLabel}</p>
        <p className="mt-1 text-[11px] leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.census.detail.riskHint')}</p>
        <div className="mt-3 flex gap-1" aria-hidden>
          {RISK_SEGS.map((seg) => (
            <div
              key={seg.min}
              className="h-1.5 flex-1 rounded-full transition-colors duration-300"
              style={{ background: pct >= seg.min && pct <= seg.max ? seg.color : 'oklch(1 0 0 / 0.07)' }}
            />
          ))}
        </div>
      </div>
    </div>
  )
}

function ActionButton({ icon: Icon, label }: { icon: LucideIcon; label: string }) {
  const { t } = useI18n()
  return (
    <button
      type="button"
      disabled
      className="inline-flex h-9 cursor-not-allowed items-center gap-2 rounded-full border border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] px-3.5 text-[11px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]"
      title={`${label} (${t('nav.comingSoon')})`}
    >
      <Icon size={13} strokeWidth={2} />
      <span>{label}</span>
      <span className="ml-1 rounded-full bg-white/[0.05] px-1.5 py-0.5 text-[9px] tracking-[0.10em]">{t('nav.comingSoon')}</span>
    </button>
  )
}
