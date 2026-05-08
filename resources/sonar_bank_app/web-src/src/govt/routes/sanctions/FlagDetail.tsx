import { useState } from 'react'
import { motion } from 'motion/react'
import { useNavigate } from 'react-router-dom'
import {
  AlertTriangle,
  ArrowUpRight,
  Banknote,
  CircleCheck,
  Gavel,
  IdCard,
  Snowflake,
  Sun,
  type LucideIcon,
} from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { maskCidDisplay } from '@/lib/privacy'
import { sfx } from '@/lib/sfx'
import { toast } from '@/stores/toast'
import { cn } from '@/lib/utils'
import { GovtCard } from '../../components/GovtCard'
import { GovtPill } from '../../components/GovtPill'
import {
  useApplyFineMutation,
  useCitizenFrozenQuery,
  useCloseFlagMutation,
  useFreezeAccountsMutation,
  useLiftFreezeMutation,
  useSanctionActionsQuery,
} from '../../data/queries/govtSanctions'
import type {
  GovtFlagQueueItem,
  GovtFlagSeverity,
  GovtFlagStatus,
  GovtSanctionAction,
  GovtSanctionActionType,
} from '../../data/contracts'
import { ActionDialog, type ActionDialogKind, type ActionDialogResult } from './ActionDialog'

interface Props {
  flag: GovtFlagQueueItem
}

const SEVERITY_TONE: Record<GovtFlagSeverity, { color: string; key: TranslationKey }> = {
  info: { color: 'oklch(0.78 0.10 215)', key: 'govt.census.flags.severity.info' },
  low: { color: 'oklch(0.65 0.18 155)', key: 'govt.census.flags.severity.low' },
  medium: { color: 'oklch(0.78 0.16 85)', key: 'govt.census.flags.severity.medium' },
  high: { color: 'oklch(0.72 0.20 35)', key: 'govt.census.flags.severity.high' },
  critical: { color: 'oklch(0.62 0.21 25)', key: 'govt.census.flags.severity.critical' },
}

const STATUS_KEY: Record<GovtFlagStatus, TranslationKey> = {
  open: 'govt.census.flags.status.open',
  reviewing: 'govt.census.flags.status.reviewing',
  resolved: 'govt.census.flags.status.resolved',
  dismissed: 'govt.census.flags.status.dismissed',
}

const ACTION_ICON: Record<GovtSanctionActionType, LucideIcon> = {
  freeze_accounts: Snowflake,
  lift_freeze: Sun,
  apply_fine: Banknote,
  close_flag: CircleCheck,
}

const ACTION_LABEL: Record<GovtSanctionActionType, TranslationKey> = {
  freeze_accounts: 'govt.sanctions.action.freezeAccounts',
  lift_freeze: 'govt.sanctions.action.liftFreeze',
  apply_fine: 'govt.sanctions.action.applyFine',
  close_flag: 'govt.sanctions.action.closeFlag',
}

export function FlagDetail({ flag }: Props) {
  const { t, dateTime, money, relativeTime } = useI18n()
  const navigate = useNavigate()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const sev = SEVERITY_TONE[flag.severity]

  const frozenQuery = useCitizenFrozenQuery(flag.citizenCid)
  const isFrozen = frozenQuery.data === true
  const actionsQuery = useSanctionActionsQuery(flag.citizenCid)
  const recentActions = actionsQuery.data ?? []

  const closeFlagMutation = useCloseFlagMutation()
  const freezeMutation = useFreezeAccountsMutation()
  const liftMutation = useLiftFreezeMutation()
  const fineMutation = useApplyFineMutation()

  const [dialogKind, setDialogKind] = useState<ActionDialogKind | null>(null)
  const dialogBusy =
    closeFlagMutation.isPending ||
    freezeMutation.isPending ||
    liftMutation.isPending ||
    fineMutation.isPending

  const flagClosed = flag.status === 'resolved' || flag.status === 'dismissed'
  const cidDisplay = streamerMode ? maskCidDisplay(flag.citizenCid) : flag.citizenCid

  const handleConfirm = async (result: ActionDialogResult) => {
    if (!dialogKind) return
    try {
      if (dialogKind === 'close_flag' && result.verdict) {
        await closeFlagMutation.mutateAsync({
          flagId: flag.flagId,
          verdict: result.verdict,
          reason: result.reason,
          idempotencyKey: result.idempotencyKey,
        })
        toast.success(
          t('govt.sanctions.toast.closeFlagTitle'),
          t(result.verdict === 'resolved' ? 'govt.sanctions.toast.closeFlagResolvedDescription' : 'govt.sanctions.toast.closeFlagDismissedDescription'),
        )
      } else if (dialogKind === 'freeze') {
        await freezeMutation.mutateAsync({
          targetCid: flag.citizenCid,
          relatedFlagId: flag.flagId,
          reason: result.reason,
          idempotencyKey: result.idempotencyKey,
        })
        toast.warning(t('govt.sanctions.toast.freezeTitle'), `${flag.citizenAlias} — ${t('govt.sanctions.toast.freezeDescription')}`)
      } else if (dialogKind === 'lift_freeze') {
        await liftMutation.mutateAsync({
          targetCid: flag.citizenCid,
          relatedFlagId: flag.flagId,
          reason: result.reason,
          idempotencyKey: result.idempotencyKey,
        })
        toast.success(t('govt.sanctions.toast.liftTitle'), `${flag.citizenAlias} — ${t('govt.sanctions.toast.liftDescription')}`)
      } else if (dialogKind === 'apply_fine' && result.amount) {
        await fineMutation.mutateAsync({
          targetCid: flag.citizenCid,
          relatedFlagId: flag.flagId,
          amount: result.amount,
          reason: result.reason,
          idempotencyKey: result.idempotencyKey,
        })
        toast.warning(
          t('govt.sanctions.toast.fineTitle'),
          `${flag.citizenAlias} — ${money(result.amount)}`,
        )
      }
      setDialogKind(null)
    } catch {
      toast.danger(t('govt.sanctions.toast.errorTitle'), t('govt.sanctions.toast.errorDescription'))
    }
  }

  return (
    <motion.div
      key={flag.flagId}
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.22 }}
      className="flex h-full flex-col gap-3 overflow-y-auto pr-1 scrollbar-thin"
    >
      <GovtCard variant="hero" padding="lg">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="flex min-w-0 items-center gap-4">
            <div
              aria-hidden
              className="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-2xl border-2 text-white"
              style={{
                background: 'radial-gradient(circle at 50% 30%, oklch(0.22 0.05 252), oklch(0.10 0.030 252))',
                borderColor: 'var(--color-govt-border-strong)',
              }}
            >
              <IdCard size={20} strokeWidth={1.7} />
            </div>
            <div className="min-w-0">
              <p className="text-[10px] font-semibold uppercase tracking-[0.18em] text-[var(--color-govt-text-tertiary)]">
                {t('govt.sanctions.detail.target')}
              </p>
              <h2 className="truncate text-xl font-light tracking-[-0.03em] text-[var(--color-govt-text-primary)]">{flag.citizenAlias}</h2>
              <p className="mt-0.5 truncate font-mono text-[10px] uppercase tracking-[0.16em] text-[var(--color-govt-text-tertiary)]">{cidDisplay}</p>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <GovtPill tone={isFrozen ? 'danger' : flag.severity === 'critical' ? 'warning' : 'accent'} size="sm">
              {isFrozen ? t('govt.sanctions.detail.frozen') : t('govt.sanctions.detail.activeReview')}
            </GovtPill>
            <button
              type="button"
              onClick={() => {
                sfx.console_tap()
                navigate('/tesoreria/censo')
              }}
              className="inline-flex h-7 items-center gap-1 rounded-full border border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] px-2.5 text-[10px] font-semibold uppercase tracking-[0.10em] text-[var(--color-govt-text-secondary)] transition-colors hover:border-[var(--color-govt-border-strong)] hover:text-[var(--color-govt-text-primary)]"
            >
              {t('govt.sanctions.detail.viewProfile')}
              <ArrowUpRight size={11} strokeWidth={2.2} />
            </button>
          </div>
        </div>
      </GovtCard>

      <GovtCard variant="glass" padding="md">
        <div className="flex items-center gap-2">
          <span aria-hidden className="flex h-7 w-7 items-center justify-center rounded-lg" style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}>
            <AlertTriangle size={13} strokeWidth={2} />
          </span>
          <h3 className="text-[11px] font-semibold uppercase tracking-[0.16em] text-[var(--color-govt-text-secondary)]">
            {t('govt.sanctions.detail.flagTitle')}
          </h3>
        </div>
        <div
          className="mt-3 rounded-xl border p-3"
          style={{
            borderColor: `${sev.color}33`,
            background: `${sev.color.replace(')', ' / 0.06)')}`,
          }}
        >
          <p className="text-sm leading-relaxed text-[var(--color-govt-text-primary)]">{flag.summary}</p>
          <div className="mt-3 flex flex-wrap items-center gap-2 text-[10px] uppercase tracking-[0.14em]">
            <span
              className="inline-flex h-5 items-center rounded-full border px-2 font-semibold"
              style={{
                color: sev.color,
                borderColor: `${sev.color}55`,
                background: `${sev.color.replace(')', ' / 0.10)')}`,
              }}
            >
              {t(sev.key)}
            </span>
            <span className="text-[var(--color-govt-text-tertiary)]">{t(STATUS_KEY[flag.status])}</span>
            <span className="text-[var(--color-govt-text-quaternary)]">·</span>
            <span className="text-[var(--color-govt-text-tertiary)]">{relativeTime(flag.raisedAt)}</span>
            <span className="text-[var(--color-govt-text-quaternary)]">·</span>
            <span className="text-[var(--color-govt-text-tertiary)]">{dateTime(flag.raisedAt, { dateStyle: 'medium', timeStyle: 'short' })}</span>
          </div>
        </div>
      </GovtCard>

      <GovtCard variant="glass" padding="md">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h3 className="text-[11px] font-semibold uppercase tracking-[0.16em] text-[var(--color-govt-text-secondary)]">
            {t('govt.sanctions.detail.actionsTitle')}
          </h3>
          <span className="text-[10px] text-[var(--color-govt-text-tertiary)]">
            {t('govt.sanctions.detail.actionsHint')}
          </span>
        </div>
        <div className="mt-3 grid gap-2 sm:grid-cols-2">
          {!isFrozen ? (
            <ActionButton
              icon={Snowflake}
              tone="danger"
              label={t('govt.sanctions.action.freezeAccounts')}
              hint={t('govt.sanctions.action.freezeAccountsHint')}
              disabled={dialogBusy || flagClosed}
              onClick={() => setDialogKind('freeze')}
            />
          ) : (
            <ActionButton
              icon={Sun}
              tone="success"
              label={t('govt.sanctions.action.liftFreeze')}
              hint={t('govt.sanctions.action.liftFreezeHint')}
              disabled={dialogBusy}
              onClick={() => setDialogKind('lift_freeze')}
            />
          )}
          <ActionButton
            icon={Banknote}
            tone="warning"
            label={t('govt.sanctions.action.applyFine')}
            hint={t('govt.sanctions.action.applyFineHint')}
            disabled={dialogBusy}
            onClick={() => setDialogKind('apply_fine')}
          />
          <ActionButton
            icon={Gavel}
            tone="neutral"
            label={t('govt.sanctions.action.closeFlag')}
            hint={t('govt.sanctions.action.closeFlagHint')}
            disabled={dialogBusy || flagClosed}
            onClick={() => setDialogKind('close_flag')}
            spanCols
          />
        </div>
      </GovtCard>

      <GovtCard variant="glass" padding="md">
        <h3 className="text-[11px] font-semibold uppercase tracking-[0.16em] text-[var(--color-govt-text-secondary)]">
          {t('govt.sanctions.detail.historyTitle')}
        </h3>
        {recentActions.length === 0 ? (
          <p className="mt-3 text-xs text-[var(--color-govt-text-tertiary)]">
            {t('govt.sanctions.detail.historyEmpty')}
          </p>
        ) : (
          <ul className="mt-3 space-y-2">
            {recentActions.slice(0, 6).map((action) => (
              <ActionHistoryRow key={action.id} action={action} />
            ))}
          </ul>
        )}
      </GovtCard>

      <ActionDialog
        open={dialogKind !== null}
        kind={dialogKind ?? 'close_flag'}
        citizenAlias={flag.citizenAlias}
        busy={dialogBusy}
        onClose={() => {
          if (!dialogBusy) setDialogKind(null)
        }}
        onConfirm={handleConfirm}
      />
    </motion.div>
  )
}

function ActionButton({
  icon: Icon,
  tone,
  label,
  hint,
  disabled,
  onClick,
  spanCols,
}: {
  icon: LucideIcon
  tone: 'neutral' | 'warning' | 'danger' | 'success'
  label: string
  hint: string
  disabled?: boolean
  onClick: () => void
  spanCols?: boolean
}) {
  const TONE_BG: Record<typeof tone, string> = {
    neutral: 'var(--color-govt-glass)',
    warning: 'oklch(0.78 0.16 85 / 0.08)',
    danger: 'oklch(0.62 0.21 25 / 0.08)',
    success: 'oklch(0.65 0.18 155 / 0.08)',
  }
  const TONE_BORDER: Record<typeof tone, string> = {
    neutral: 'var(--color-govt-border)',
    warning: 'oklch(0.78 0.16 85 / 0.30)',
    danger: 'oklch(0.62 0.21 25 / 0.30)',
    success: 'oklch(0.65 0.18 155 / 0.30)',
  }
  const TONE_FG: Record<typeof tone, string> = {
    neutral: 'var(--color-govt-text-primary)',
    warning: 'oklch(0.92 0.10 85)',
    danger: 'oklch(0.92 0.06 25)',
    success: 'oklch(0.85 0.12 155)',
  }
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={cn(
        'group flex items-start gap-3 rounded-xl border p-3 text-left transition-all disabled:cursor-not-allowed disabled:opacity-50',
        spanCols && 'sm:col-span-2',
        'hover:-translate-y-0.5',
      )}
      style={{ background: TONE_BG[tone], borderColor: TONE_BORDER[tone] }}
    >
      <span
        aria-hidden
        className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-xl"
        style={{ background: 'oklch(0.06 0.022 252 / 0.55)', color: TONE_FG[tone] }}
      >
        <Icon size={16} strokeWidth={1.9} />
      </span>
      <div className="min-w-0 flex-1">
        <p className="truncate text-[12px] font-semibold uppercase tracking-[0.10em]" style={{ color: TONE_FG[tone] }}>
          {label}
        </p>
        <p className="mt-0.5 line-clamp-2 text-[11px] leading-relaxed text-[var(--color-govt-text-tertiary)]">{hint}</p>
      </div>
    </button>
  )
}

function ActionHistoryRow({ action }: { action: GovtSanctionAction }) {
  const { t, dateTime, money } = useI18n()
  const Icon = ACTION_ICON[action.type]
  return (
    <li className="flex items-start gap-2.5 rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.06_0.022_252/0.50)] p-2.5">
      <span aria-hidden className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-xl" style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}>
        <Icon size={13} strokeWidth={1.9} />
      </span>
      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between gap-2">
          <p className="truncate text-[12px] font-semibold text-[var(--color-govt-text-primary)]">
            {t(ACTION_LABEL[action.type])}
            {action.amount ? ` · ${money(action.amount)}` : ''}
            {action.verdict ? ` · ${t(action.verdict === 'resolved' ? 'govt.census.flags.status.resolved' : 'govt.census.flags.status.dismissed')}` : ''}
          </p>
          <span className="flex-shrink-0 text-[10px] uppercase tracking-[0.10em] text-[var(--color-govt-text-tertiary)]">
            {dateTime(action.performedAt, { timeStyle: 'short' })}
          </span>
        </div>
        <p className="mt-0.5 line-clamp-2 text-[11px] leading-snug text-[var(--color-govt-text-secondary)]">{action.reason}</p>
        <p className="mt-1 text-[10px] uppercase tracking-[0.12em] text-[var(--color-govt-text-quaternary)]">
          {`${t('govt.sanctions.detail.operator')}: ${action.operator}`}
        </p>
      </div>
    </li>
  )
}
