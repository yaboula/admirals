import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { motion } from 'motion/react'
import { AlertTriangle, CheckCircle2, FileSearch, Flag, Gauge, Search, ShieldAlert, XCircle, type LucideIcon } from 'lucide-react'
import { useComplianceFlagsQuery } from '@/data/queries'
import type { ComplianceFlag, ComplianceFlagSeverity, ComplianceFlagStatus } from '@/data/contracts'
import { Badge, Card, Input, Spinner } from '@/components/ui'
import { AceLockedState, useAceGate } from '@/components/security'
import { ACE_PERMS } from '@/lib/ace'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { maskIbanPanel, maskMoneyDisplay, maskOperationCode, revealOperationCode } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { usePrivacyMode } from '@/stores/privacy'

type ComplianceStatusFilter = ComplianceFlagStatus | 'all'
type ComplianceSeverityFilter = ComplianceFlagSeverity | 'all'

export function Compliance() {
  const { t } = useI18n()
  const [query, setQuery] = useState('')
  const [status, setStatus] = useState<ComplianceStatusFilter>('all')
  const [severity, setSeverity] = useState<ComplianceSeverityFilter>('all')
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const allowed = useAceGate({ require: ACE_PERMS.P10.perm })

  const flagsQuery = useComplianceFlagsQuery(
    { query, status, severity, limit: 24 },
    { enabled: allowed },
  )

  const flags: ComplianceFlag[] = flagsQuery.data?.items ?? []
  const selectedFlag = useMemo(() => flags.find((flag) => flag.flag_id === selectedId) ?? flags[0] ?? null, [flags, selectedId])
  const openFlags = flags.filter((flag) => flag.status === 'open' || flag.status === 'reviewing').length
  const criticalFlags = flags.filter((flag) => flag.severity === 'critical' || flag.severity === 'high').length

  useEffect(() => {
    setSelectedId(null)
  }, [query, status, severity])

  function selectFlag(flagId: string): void {
    setSelectedId(flagId)
    sfx.console_tap()
  }

  return (
    <main className="flex h-full min-h-0 flex-col gap-4 overflow-hidden px-5 py-4 lg:px-6">
      <motion.section initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28 }}>
        <Card variant="glass" padding="lg" className="rounded-[1.75rem] border-white/10">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
            <div className="max-w-3xl">
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand-signal-orange-light">{t('compliance.eyebrow')}</p>
              <h1 className="mt-2 text-3xl font-light tracking-[-0.065em] text-text-primary md:text-4xl">{t('compliance.title')}</h1>
              <p className="mt-2 max-w-2xl text-sm leading-relaxed text-text-secondary">{t('compliance.description')}</p>
            </div>
            <div className="grid grid-cols-2 gap-3 lg:min-w-[290px]">
              <HeroMetric label={t('compliance.openFlags')} value={allowed ? String(openFlags) : '—'} />
              <HeroMetric label={t('compliance.highRisk')} value={allowed ? String(criticalFlags) : '—'} />
            </div>
          </div>
        </Card>
      </motion.section>

      {!allowed ? (
        <AceLockedState className="min-h-[420px] rounded-[1.75rem]" />
      ) : (
        <motion.section initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28, delay: 0.05 }} className="grid min-h-0 flex-1 grid-cols-1 gap-4 xl:grid-cols-[minmax(0,1fr)_390px]">
          <div className="flex min-h-0 flex-col gap-4">
            <Card variant="glass" padding="sm" className="rounded-[1.5rem] border-white/10 2xl:p-4">
              <div className="grid gap-3 lg:grid-cols-[minmax(220px,1fr)_180px_180px]">
                <Input
                  label={t('compliance.searchLabel')}
                  placeholder={t('compliance.searchPlaceholder')}
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  leftAdornment={<Search size={15} strokeWidth={2} />}
                />
                <FilterSelect label={t('compliance.statusFilter')} value={status} onChange={(value) => setStatus(value as ComplianceStatusFilter)}>
                  <option value="all">{t('compliance.allStatuses')}</option>
                  <option value="open">{t('compliance.statusOpen')}</option>
                  <option value="reviewing">{t('compliance.statusReviewing')}</option>
                  <option value="resolved">{t('compliance.statusResolved')}</option>
                  <option value="dismissed">{t('compliance.statusDismissed')}</option>
                </FilterSelect>
                <FilterSelect label={t('compliance.severityFilter')} value={severity} onChange={(value) => setSeverity(value as ComplianceSeverityFilter)}>
                  <option value="all">{t('compliance.allSeverities')}</option>
                  <option value="critical">{t('compliance.severityCritical')}</option>
                  <option value="high">{t('compliance.severityHigh')}</option>
                  <option value="medium">{t('compliance.severityMedium')}</option>
                  <option value="low">{t('compliance.severityLow')}</option>
                </FilterSelect>
              </div>
            </Card>

            <Card variant="glass" padding="none" className="flex min-h-0 flex-col overflow-hidden rounded-[1.75rem] border-white/10">
              {flagsQuery.isLoading ? (
                <ComplianceLoading label={t('compliance.loading')} />
              ) : flagsQuery.isError ? (
                <ComplianceEmpty icon={AlertTriangle} title={t('compliance.errorTitle')} description={t('compliance.errorDescription')} />
              ) : flags.length === 0 ? (
                <ComplianceEmpty icon={FileSearch} title={t('compliance.noMatchTitle')} description={t('compliance.noMatchDescription')} />
              ) : (
                <div className="min-h-0 flex-1 overflow-y-auto p-2.5">
                  <div className="space-y-2">
                    {flags.map((flag) => (
                      <ComplianceRow key={flag.flag_id} flag={flag} active={selectedFlag?.flag_id === flag.flag_id} onClick={() => selectFlag(flag.flag_id)} />
                    ))}
                  </div>
                </div>
              )}
            </Card>
          </div>

          <ComplianceDetail flag={selectedFlag} />
        </motion.section>
      )}
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

function FilterSelect({ label, value, onChange, children }: { label: string; value: string; onChange: (value: string) => void; children: ReactNode }) {
  return (
    <label className="flex flex-col gap-1.5">
      <span className="text-sm font-medium tracking-tight text-text-secondary">{label}</span>
      <select
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="tactile-input h-10 rounded-md border-none bg-transparent px-3 text-sm text-text-primary outline-none"
      >
        {children}
      </select>
    </label>
  )
}

function ComplianceRow({ flag, active, onClick }: { flag: ComplianceFlag; active: boolean; onClick: () => void }) {
  const { t, dateTime, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const status = statusMeta(flag.status, t)
  const severity = severityMeta(flag.severity, t)
  const StatusIcon = status.icon
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'group grid w-full grid-cols-[minmax(0,1fr)_116px_116px_118px] items-center gap-3 rounded-[1.15rem] border px-3 py-3 text-left transition-all',
        active ? 'border-brand-signal-orange/70 bg-brand-signal-orange-subtle shadow-glow-orange' : 'border-white/8 bg-white/[0.025] hover:border-white/14 hover:bg-white/[0.05]',
      )}
    >
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <Badge tone={severity.tone} variant="soft" size="xs">{severity.label}</Badge>
          <span className="truncate text-sm font-semibold text-text-primary">{flag.reason}</span>
        </div>
        <p className="mt-1 truncate text-xs text-text-tertiary font-mono">{streamerMode ? maskOperationCode(flag.flag_id) : flag.flag_id}</p>
      </div>
      <span className="text-xs font-semibold text-text-secondary tactile-tabular-nums">{dateTime(flag.created_at_ms, { dateStyle: 'short', timeStyle: 'short' })}</span>
      <span className="text-right text-sm font-semibold text-text-primary tactile-tabular-nums">{flag.amount_minor == null ? '—' : streamerMode ? maskMoneyDisplay() : money(flag.amount_minor / 100)}</span>
      <Badge tone={status.tone} variant="soft" leftIcon={<StatusIcon size={13} strokeWidth={2.3} />}>{status.label}</Badge>
    </button>
  )
}

function ComplianceDetail({ flag }: { flag: ComplianceFlag | null }) {
  const { t, dateTime, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  if (!flag) {
    return (
      <Card variant="glass" padding="none" className="min-h-0 overflow-hidden rounded-[1.75rem] border-white/10">
        <ComplianceEmpty icon={Flag} title={t('compliance.noSelectionTitle')} description={t('compliance.noSelectionDescription')} />
      </Card>
    )
  }

  const status = statusMeta(flag.status, t)
  const severity = severityMeta(flag.severity, t)
  const StatusIcon = status.icon
  return (
    <Card variant="glass" padding="none" className="relative min-h-0 overflow-hidden rounded-[1.75rem] border-white/10">
      <div className="relative flex h-full min-h-0 flex-col overflow-y-auto p-5 2xl:p-6">
        <div className="flex items-center justify-between gap-3">
          <div className="min-w-0">
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-signal-orange-light">{t('compliance.detailEyebrow')}</p>
            <h2 className="mt-1 truncate text-lg font-semibold text-text-primary">{flag.reason}</h2>
          </div>
          <Badge tone={status.tone} variant="soft" leftIcon={<StatusIcon size={13} strokeWidth={2.3} />}>{status.label}</Badge>
        </div>

        <div className="mt-5 grid grid-cols-[1fr_auto] items-center gap-3 rounded-[1.45rem] border border-white/10 bg-white/[0.04] p-4">
          <div>
            <span className="block text-[11px] uppercase tracking-[0.14em] text-text-tertiary">{t('compliance.riskScore')}</span>
            <span className="mt-1 block text-3xl font-light tracking-[-0.055em] text-text-primary tactile-tabular-nums">{flag.risk_score}</span>
          </div>
          <Badge tone={severity.tone} variant="solid" leftIcon={<Gauge size={13} strokeWidth={2.3} />}>{severity.label}</Badge>
        </div>

        <div className="mt-4 space-y-2">
          <DetailRow label={t('common.date')} value={dateTime(flag.created_at_ms, { dateStyle: 'medium', timeStyle: 'short' })} />
          <DetailRow label={t('compliance.subject')} value={flag.subject_cid_masked} mono />
          <DetailRow label={t('compliance.account')} value={streamerMode ? maskIbanPanel(flag.account_iban_masked) : flag.account_iban_masked} mono />
          <DetailRow label={t('compliance.counterparty')} value={flag.counterparty_iban_masked ? streamerMode ? maskIbanPanel(flag.counterparty_iban_masked) : flag.counterparty_iban_masked : '—'} mono />
          <DetailRow label={t('compliance.amount')} value={flag.amount_minor == null ? '—' : streamerMode ? maskMoneyDisplay() : money(flag.amount_minor / 100)} />
          <DetailRow label={t('compliance.assignedUnit')} value={flag.assigned_unit} />
          <DetailRow label={t('compliance.evidence')} value={String(flag.evidence_count)} />
          <DetailRow label={t('compliance.reference')} value={streamerMode ? maskOperationCode(flag.correlation_id) : revealOperationCode(flag.correlation_id)} mono />
        </div>

        <div className="mt-4 min-h-[140px] overflow-hidden rounded-[1.25rem] border border-white/10 bg-black/15 p-3">
          <div className="mb-2 flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.14em] text-text-tertiary">
            <FileSearch size={13} strokeWidth={2.2} />
            {t('compliance.details')}
          </div>
          <pre className="max-h-full overflow-auto whitespace-pre-wrap break-words text-xs leading-relaxed text-text-secondary tactile-tabular-nums">
            {formatDetails(flag.details_json)}
          </pre>
        </div>

        <div className="mt-4 rounded-[1.1rem] border border-semantic-warning-deep/25 bg-semantic-warning-glow px-3 py-2 text-xs leading-relaxed text-text-secondary">
          {t('compliance.privacyNote')}
        </div>
      </div>
    </Card>
  )
}

function DetailRow({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex items-center justify-between gap-3 rounded-[1rem] border border-white/8 bg-white/[0.035] px-3 py-2">
      <span className="text-xs text-text-tertiary">{label}</span>
      <span className={cn('min-w-0 truncate text-right text-sm text-text-primary', mono && 'font-mono text-xs')}>{value}</span>
    </div>
  )
}

function ComplianceLoading({ label }: { label: string }) {
  return (
    <div className="flex min-h-[360px] flex-col items-center justify-center gap-3 text-text-secondary">
      <Spinner size="md" />
      <span className="text-sm">{label}</span>
    </div>
  )
}

function ComplianceEmpty({ icon: Icon, title, description }: { icon: LucideIcon; title: string; description: string }) {
  return (
    <div className="flex min-h-[360px] flex-col items-center justify-center gap-3 p-6 text-center">
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

function statusMeta(status: ComplianceFlagStatus, t: (key: TranslationKey) => string) {
  const meta = {
    open: { label: t('compliance.statusOpen'), tone: 'danger' as const, icon: ShieldAlert },
    reviewing: { label: t('compliance.statusReviewing'), tone: 'warning' as const, icon: AlertTriangle },
    resolved: { label: t('compliance.statusResolved'), tone: 'success' as const, icon: CheckCircle2 },
    dismissed: { label: t('compliance.statusDismissed'), tone: 'neutral' as const, icon: XCircle },
  }
  return meta[status]
}

function severityMeta(severity: ComplianceFlagSeverity, t: (key: TranslationKey) => string) {
  const meta = {
    critical: { label: t('compliance.severityCritical'), tone: 'danger' as const },
    high: { label: t('compliance.severityHigh'), tone: 'warning' as const },
    medium: { label: t('compliance.severityMedium'), tone: 'info' as const },
    low: { label: t('compliance.severityLow'), tone: 'neutral' as const },
  }
  return meta[severity]
}

function formatDetails(value: string | null): string {
  if (!value) return '—'
  try {
    return JSON.stringify(JSON.parse(value), null, 2)
  } catch {
    return value
  }
}
