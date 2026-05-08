import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { motion } from 'motion/react'
import { AlertTriangle, Building2, CheckCircle2, FileSearch, Landmark, LockKeyhole, ReceiptText, Search, ShieldCheck, XCircle, type LucideIcon } from 'lucide-react'
import { useAuditQuery } from '@/data/queries'
import type { AuditEvent, AuditEventStatus, AuditScope } from '@/data/contracts'
import { Badge, Card, Input, Spinner } from '@/components/ui'
import { AceLockedState, useAceGate } from '@/components/security'
import { ACE_PERMS } from '@/lib/ace'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { maskIbanPanel, maskMoneyDisplay, maskOperationCode } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { usePrivacyMode } from '@/stores/privacy'

const SCOPE_META: Array<{
  scope: AuditScope
  labelKey: TranslationKey
  descriptionKey: TranslationKey
  icon: LucideIcon
}> = [
  { scope: 'self', labelKey: 'audit.scopeSelf', descriptionKey: 'audit.scopeSelfDescription', icon: Landmark },
  { scope: 'business', labelKey: 'audit.scopeBusiness', descriptionKey: 'audit.scopeBusinessDescription', icon: Building2 },
  { scope: 'government', labelKey: 'audit.scopeGovernment', descriptionKey: 'audit.scopeGovernmentDescription', icon: ShieldCheck },
]

const EVENT_FILTERS = [
  'all',
  'transfer.committed',
  'transfer.received',
  'compliance.flagRaised',
  'business.payroll.previewed',
] as const

type AuditEventFilter = typeof EVENT_FILTERS[number]

type AuditStatusFilter = AuditEventStatus | 'all'

export function Audit() {
  const { t } = useI18n()
  const [scope, setScope] = useState<AuditScope>('self')
  const [query, setQuery] = useState('')
  const [status, setStatus] = useState<AuditStatusFilter>('all')
  const [eventType, setEventType] = useState<AuditEventFilter>('all')
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const businessAllowed = useAceGate({ require: ACE_PERMS.P03.perm })
  const governmentAllowed = useAceGate({ require: ACE_PERMS.P04.perm })
  const scopeAllowed = scope === 'self' || (scope === 'business' && businessAllowed) || (scope === 'government' && governmentAllowed)

  const auditQuery = useAuditQuery(
    {
      scope,
      query,
      status,
      event_type: eventType,
      limit: 28,
    },
    { enabled: scopeAllowed },
  )

  const events = auditQuery.data?.items ?? []
  const selected = useMemo(
    () => events.find((event) => event.audit_id === selectedId) ?? events[0] ?? null,
    [events, selectedId],
  )

  useEffect(() => {
    if (!selectedId) return
    if (!events.some((event) => event.audit_id === selectedId)) setSelectedId(null)
  }, [events, selectedId])

  const selectScope = (next: AuditScope): void => {
    sfx.layer_dive()
    setScope(next)
    setSelectedId(null)
  }

  return (
    <div className="relative h-full w-full overflow-hidden">
      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
        className="h-full w-full"
      >
        <div className="mx-auto grid h-full w-full max-w-[1500px] gap-4 2xl:gap-5" style={{ gridTemplateRows: '1fr' }}>
          <div className="grid min-h-0 gap-4 2xl:gap-5" style={{ gridTemplateColumns: 'minmax(0, 1fr) minmax(340px, 0.42fr)' }}>
            <section className="grid min-h-0 gap-3 2xl:gap-4" style={{ gridTemplateRows: 'auto auto 1fr' }}>
              <Card variant="glass" padding="sm" className="rounded-[1.5rem] border-white/10 2xl:p-4">
                <div className="grid grid-cols-3 gap-2">
                  {SCOPE_META.map((item) => (
                    <ScopeButton
                      key={item.scope}
                      scope={item.scope}
                      active={scope === item.scope}
                      locked={!isScopeAllowed(item.scope, businessAllowed, governmentAllowed)}
                      label={t(item.labelKey)}
                      description={t(item.descriptionKey)}
                      icon={item.icon}
                      onClick={() => selectScope(item.scope)}
                    />
                  ))}
                </div>
              </Card>

              <Card variant="glass" padding="sm" className="rounded-[1.5rem] border-white/10 2xl:p-4">
                <div className="grid grid-cols-[minmax(0,1fr)_180px_190px] items-end gap-3">
                  <Input
                    label={t('audit.searchLabel')}
                    placeholder={t('audit.searchPlaceholder')}
                    value={query}
                    onChange={(event) => setQuery(event.target.value)}
                    leftAdornment={<Search size={15} strokeWidth={2} />}
                  />
                  <FilterSelect label={t('audit.statusFilter')} value={status} onChange={(value) => setStatus(value as AuditStatusFilter)}>
                    <option value="all">{t('audit.allStatuses')}</option>
                    <option value="committed">{t('audit.statusCommitted')}</option>
                    <option value="pending">{t('audit.statusPending')}</option>
                    <option value="reverted">{t('audit.statusReverted')}</option>
                    <option value="failed">{t('audit.statusFailed')}</option>
                  </FilterSelect>
                  <FilterSelect label={t('audit.typeFilter')} value={eventType} onChange={(value) => setEventType(value as AuditEventFilter)}>
                    {EVENT_FILTERS.map((value) => (
                      <option key={value} value={value}>{value === 'all' ? t('audit.allEvents') : eventTypeLabel(value, t)}</option>
                    ))}
                  </FilterSelect>
                </div>
              </Card>

              <Card variant="glass" padding="none" className="flex min-h-0 flex-col overflow-hidden rounded-[1.75rem] border-white/10">
                {!scopeAllowed ? (
                  <AceLockedState className="m-4 min-h-[320px]" />
                ) : auditQuery.isLoading ? (
                  <AuditLoading label={t('audit.loading')} />
                ) : auditQuery.isError ? (
                  <AuditEmpty icon={AlertTriangle} title={t('audit.errorTitle')} description={t('audit.errorDescription')} />
                ) : events.length === 0 ? (
                  <AuditEmpty
                    icon={FileSearch}
                    title={query || status !== 'all' || eventType !== 'all' ? t('audit.noMatchTitle') : t('audit.noEventsTitle')}
                    description={query || status !== 'all' || eventType !== 'all' ? t('audit.noMatchDescription') : t('audit.noEventsDescription')}
                  />
                ) : (
                  <div className="min-h-0 overflow-y-auto p-2">
                    <div className="grid gap-2">
                      {events.map((event) => (
                        <AuditRow
                          key={event.audit_id}
                          event={event}
                          active={selected?.audit_id === event.audit_id}
                          onClick={() => {
                            sfx.console_tap()
                            setSelectedId(event.audit_id)
                          }}
                        />
                      ))}
                    </div>
                  </div>
                )}
              </Card>
            </section>

            <AuditDetail event={selected} />
          </div>
        </div>
      </motion.div>
    </div>
  )
}

function ScopeButton({ active, locked, label, description, icon: Icon, onClick }: { scope: AuditScope; active: boolean; locked: boolean; label: string; description: string; icon: LucideIcon; onClick: () => void }) {
  return (
    <button
      type="button"
      disabled={locked}
      onClick={onClick}
      className={cn(
        'group flex min-h-[72px] items-center gap-3 rounded-[1.2rem] border px-3 text-left transition-all',
        active ? 'border-border-brand-strong bg-brand-signal-orange-subtle text-text-primary' : 'border-white/10 bg-white/[0.035] text-text-secondary hover:border-white/20 hover:bg-white/[0.06]',
        locked && 'cursor-not-allowed opacity-45',
      )}
      aria-pressed={active}
    >
      <span className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.05]">
        {locked ? <LockKeyhole size={17} strokeWidth={2} /> : <Icon size={17} strokeWidth={2} />}
      </span>
      <span className="min-w-0">
        <span className="block text-sm font-semibold text-text-primary">{label}</span>
        <span className="mt-0.5 line-clamp-2 block text-[11px] leading-snug text-text-tertiary">{description}</span>
      </span>
    </button>
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

function AuditRow({ event, active, onClick }: { event: AuditEvent; active: boolean; onClick: () => void }) {
  const { t, dateTime, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const status = statusMeta(event.status, t)
  const StatusIcon = status.icon
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'grid grid-cols-[minmax(190px,1.3fr)_120px_130px_120px] items-center gap-3 rounded-[1.15rem] border px-3 py-3 text-left transition-all',
        active ? 'border-border-brand-strong bg-brand-signal-orange-subtle' : 'border-white/10 bg-white/[0.03] hover:border-white/18 hover:bg-white/[0.055]',
      )}
    >
      <span className="min-w-0">
        <span className="block truncate text-sm font-semibold text-text-primary">{eventTypeLabel(event.event_type, t)}</span>
        <span className="mt-1 block truncate text-xs text-text-tertiary">{maskOperationCode(event.correlation_id)}</span>
      </span>
      <span className="text-xs text-text-secondary tactile-tabular-nums">{dateTime(event.timestamp_ms, { dateStyle: 'short', timeStyle: 'short' })}</span>
      <span className="text-sm font-semibold text-text-primary tactile-tabular-nums">{event.amount_minor == null ? '—' : streamerMode ? maskMoneyDisplay() : money(event.amount_minor / 100)}</span>
      <Badge tone={status.tone} variant="soft" size="sm" leftIcon={<StatusIcon size={12} strokeWidth={2.3} />}>
        {status.label}
      </Badge>
    </button>
  )
}

function AuditDetail({ event }: { event: AuditEvent | null }) {
  const { t, dateTime, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const scrollRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: 0, behavior: 'instant' })
  }, [event?.audit_id])

  if (!event) {
    return (
      <Card variant="glass" padding="none" className="min-h-0 overflow-hidden rounded-[1.75rem] border-white/10">
        <AuditEmpty icon={ReceiptText} title={t('audit.noSelectionTitle')} description={t('audit.noSelectionDescription')} />
      </Card>
    )
  }

  const status = statusMeta(event.status, t)
  const StatusIcon = status.icon
  return (
    <Card variant="glass" padding="none" className="relative min-h-0 overflow-hidden rounded-[1.75rem] border-white/10">
      <div ref={scrollRef} className="relative flex h-full min-h-0 flex-col overflow-y-auto p-5 pr-4 scrollbar-thin 2xl:p-6 2xl:pr-5">
        <div className="flex items-center justify-between gap-3">
          <div className="min-w-0">
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-signal-orange-light">{t('audit.detailEyebrow')}</p>
            <h2 className="mt-1 truncate text-lg font-semibold text-text-primary">{eventTypeLabel(event.event_type, t)}</h2>
          </div>
          <Badge tone={status.tone} variant="soft" leftIcon={<StatusIcon size={13} strokeWidth={2.3} />}>{status.label}</Badge>
        </div>

        <div className="mt-5 rounded-[1.45rem] border border-white/10 bg-white/[0.04] p-4 text-center">
          <span className="block text-[11px] uppercase tracking-[0.14em] text-text-tertiary">{t('audit.amount')}</span>
          <span className="mt-1 block text-3xl font-light tracking-[-0.055em] text-text-primary tactile-tabular-nums">
            {event.amount_minor == null ? '—' : streamerMode ? maskMoneyDisplay() : money(event.amount_minor / 100)}
          </span>
        </div>

        <div className="mt-4 space-y-2">
          <DetailRow label={t('common.date')} value={dateTime(event.timestamp_ms, { dateStyle: 'medium', timeStyle: 'short' })} />
          <DetailRow label={t('audit.actor')} value={event.actor_cid_masked} mono />
          <DetailRow label={t('audit.counterparty')} value={event.counterparty_iban_masked ? streamerMode ? maskIbanPanel(event.counterparty_iban_masked) : event.counterparty_iban_masked : '—'} mono />
          <DetailRow label={t('audit.reference')} value={maskOperationCode(event.correlation_id)} mono />
          <DetailRow label={t('audit.reason')} value={event.reason ?? '—'} />
        </div>

        <div className="mt-4 rounded-[1.1rem] border border-semantic-info-deep/30 bg-semantic-info-glow px-3 py-2 text-xs leading-relaxed text-text-secondary">
          {t('audit.privacyNote')}
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

function AuditLoading({ label }: { label: string }) {
  return (
    <div className="flex min-h-[360px] flex-col items-center justify-center gap-3 text-text-secondary">
      <Spinner size="md" />
      <span className="text-sm">{label}</span>
    </div>
  )
}

function AuditEmpty({ icon: Icon, title, description }: { icon: LucideIcon; title: string; description: string }) {
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

function isScopeAllowed(scope: AuditScope, businessAllowed: boolean, governmentAllowed: boolean): boolean {
  if (scope === 'self') return true
  if (scope === 'business') return businessAllowed
  return governmentAllowed
}

function eventTypeLabel(type: string, t: (key: TranslationKey) => string): string {
  const labels: Record<string, TranslationKey> = {
    'transfer.committed': 'audit.typeTransferCommitted',
    'transfer.received': 'audit.typeTransferReceived',
    'compliance.flagRaised': 'audit.typeComplianceFlagRaised',
    'business.payroll.previewed': 'audit.typeBusinessPayrollPreviewed',
  }
  return labels[type] ? t(labels[type]) : type
}

function statusMeta(status: AuditEventStatus, t: (key: TranslationKey) => string) {
  const meta = {
    committed: { label: t('audit.statusCommitted'), tone: 'success' as const, icon: CheckCircle2 },
    pending: { label: t('audit.statusPending'), tone: 'warning' as const, icon: AlertTriangle },
    reverted: { label: t('audit.statusReverted'), tone: 'info' as const, icon: XCircle },
    failed: { label: t('audit.statusFailed'), tone: 'danger' as const, icon: XCircle },
  }
  return meta[status]
}

