import { motion } from 'motion/react'
import {
  ArrowDownLeft,
  ArrowUpRight,
  ArrowRight,
  RotateCw,
  AlertTriangle,
  Check,
  ScrollText,
} from 'lucide-react'
import { Card, CardEyebrow, CardTitle } from '@/components/ui'
import type { Account, Transaction } from '@/data/contracts'
import { cn } from '@/lib/utils'
import { useI18n } from '@/lib/i18n'
import { useNavigate } from 'react-router-dom'
import { useTransferWizard } from '@/stores/transferWizard'
import { usePrivacyMode } from '@/stores/privacy'
import { sfx } from '@/lib/sfx'
import { getMockAliasForIban } from '@/data/mock/seed'
import { maskSignedMoneyDisplay } from '@/lib/privacy'

export interface ActivityPreviewProps {
  transactions: Transaction[]
  account: Account | undefined
  loading?: boolean
  /** Compact mode: tight spacing, 5 rows max — for zero-scroll dashboard */
  compact?: boolean
}

/**
 * BANK-FE.2.3 — Top 4 movements with counterpart NAME ONLY (IBAN hidden by
 * design, lives in the detail drawer). Real empty-state for zero data.
 * Header exposes a 'Ver todo' CTA with an elegant arrow chevron that routes
 * to the transactions history view (Phase A: toast placeholder).
 */
export function ActivityPreview({ transactions, account, loading, compact }: ActivityPreviewProps) {
  const { t } = useI18n()
  const own = compactIban(account?.iban)
  // BANK-FE.3.5: 3 rows in compact mode releases ~50px vertical for the chart
  // at 1280×800 / 1024×768. Full-screen 2xl users see 4 rows via prop override.
  const limit = compact ? 3 : 8
  const hasMore = transactions.length > 0

  const navigate = useNavigate()
  const handleViewAll = (): void => {
    sfx.console_tap()
    navigate('/transacciones')
  }

  return (
    <Card variant="glass" padding={compact ? 'md' : 'lg'} className="border-white/10">
      <div className={cn('flex items-end justify-between', compact ? 'mb-2' : 'mb-4')}>
        <div className="flex flex-col gap-0.5">
          <CardEyebrow>{t('home.recentActivity')}</CardEyebrow>
          <CardTitle className={compact ? 'text-sm' : undefined}>{t('home.movements')}</CardTitle>
        </div>
        {hasMore && (
          <button
            type="button"
            onClick={handleViewAll}
            className={cn(
              'group inline-flex items-center gap-1.5 px-2 py-1 rounded-md',
              'text-[10px] font-semibold uppercase tracking-[0.14em] text-text-tertiary',
              'hover:text-text-primary hover:bg-surface-card-elevated/60 transition-colors',
              'tactile-focus-ring',
            )}
            aria-label={String(t('home.viewAllMovements') ?? '').replace('{count}', String(transactions.length))}
          >
            {t('home.viewAll')}
            <ArrowRight
              size={12}
              strokeWidth={2}
              className="transition-transform duration-200 ease-out group-hover:translate-x-0.5"
            />
          </button>
        )}
      </div>

      {loading ? (
        <div className="space-y-1.5">
          {Array.from({ length: limit }).map((_, i) => (
            <div key={i} className={cn('tactile-skeleton w-full', compact ? 'h-9' : 'h-12')} />
          ))}
        </div>
      ) : transactions.length === 0 ? (
        <ActivityEmptyState compact={compact} />
      ) : (
        <div className={compact ? 'space-y-0.5' : 'space-y-1.5'}>
          {transactions.slice(0, limit).map((t, i) => (
            <Row key={t.txn_id} tx={t} ownIban={own} index={i} compact={compact} />
          ))}
        </div>
      )}
    </Card>
  )
}

/* --------------------------------------------------------------------------
   Empty state — opaque icon + label + micro-CTA
   -------------------------------------------------------------------------- */

function ActivityEmptyState({ compact }: { compact: boolean | undefined }) {
  const { t } = useI18n()
  const initWizard = useTransferWizard((s) => s.init)
  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center text-center gap-2',
        compact ? 'py-5' : 'py-10',
      )}
    >
      <div
        className="inline-flex h-10 w-10 items-center justify-center rounded-full"
        style={{
          background: 'rgba(255,255,255,0.04)',
          border: '1px solid var(--color-border-subtle)',
          color: 'rgba(111,113,121,0.7)',
        }}
        aria-hidden
      >
        <ScrollText size={18} strokeWidth={1.7} />
      </div>
      <div className="flex flex-col gap-0.5">
        <span className="text-sm font-medium text-text-secondary">{t('home.noActivity')}</span>
        <span className="text-[11px] text-text-tertiary">{t('home.noActivityDescription')}</span>
      </div>
      <button
        type="button"
        onClick={() => {
          initWizard(false)
          sfx.depth_press()
        }}
        className="mt-1 text-[11px] font-semibold uppercase tracking-wider text-brand-signal-orange-light hover:text-text-primary transition-colors"
      >
        + {t('home.startTransfer')}
      </button>
    </div>
  )
}

/* --------------------------------------------------------------------------
   Row — counterpart NAME (no IBAN), amount, relative date
   -------------------------------------------------------------------------- */

function Row({
  tx,
  ownIban,
  index,
  compact,
}: {
  tx: Transaction
  ownIban: string | undefined
  index: number
  compact?: boolean
}) {
  const { t, signedMoney, relativeTime } = useI18n()
  const statusMeta = getStatusMeta((key: string) => t(key as any))
  const fromCompact = compactIban(tx.from_iban)
  const toCompact = compactIban(tx.to_iban)
  const isOutgoing = ownIban
    ? fromCompact === ownIban && toCompact !== ownIban
    : tx.direction === 'out'
  const counterpartIban = isOutgoing ? tx.to_iban : tx.from_iban
  const counterpartName = getMockAliasForIban(counterpartIban) ?? (isOutgoing ? t('transactions.beneficiary') : t('transactions.sender'))
  const amountColor = isOutgoing ? 'rgb(227, 228, 232)' : 'rgb(53, 193, 119)'
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const displayName = streamerMode ? t('transactions.hiddenMovement') : counterpartName
  const displayReason = streamerMode ? t('transactions.hiddenDetail') : tx.reason ?? (isOutgoing ? t('transactions.transfer') : t('transactions.received'))

  const StatusIcon = statusMeta[tx.status].icon
  const DirIcon = isOutgoing ? ArrowUpRight : ArrowDownLeft
  const iconSize = compact ? 14 : 16

  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.03, duration: 0.28 }}
      className={cn(
        'flex items-center rounded-lg transition-colors',
        compact ? 'gap-2.5 px-2 py-1.5' : 'gap-3 px-2.5 py-2.5',
        'hover:bg-surface-card-elevated/40',
      )}
    >
      <span
        className={cn(
          'inline-flex items-center justify-center rounded-lg shrink-0',
          compact ? 'h-7 w-7' : 'h-9 w-9',
        )}
        style={{
          background: isOutgoing ? 'rgba(252,88,85,0.1)' : 'rgba(53,193,119,0.1)',
          color: isOutgoing ? 'rgb(252, 88, 85)' : 'rgb(53, 193, 119)',
        }}
        aria-hidden
      >
        <DirIcon size={iconSize} strokeWidth={2} />
      </span>

      <div className="flex-1 flex flex-col min-w-0 leading-tight">
        <div className="flex items-center gap-2 min-w-0">
          <span
            className={cn(
              'truncate font-medium text-text-primary',
              compact ? 'text-xs' : 'text-sm',
            )}
          >
            {displayName}
          </span>
          {tx.status !== 'committed' && (
            <span
              className="inline-flex items-center gap-1 text-[9px] uppercase tracking-wider px-1.5 py-0.5 rounded border shrink-0"
              style={{
                color: statusMeta[tx.status].color,
                borderColor: statusMeta[tx.status].color,
              }}
            >
              <StatusIcon size={8} strokeWidth={2.6} />
              {statusMeta[tx.status].label}
            </span>
          )}
        </div>
        <span
          className={cn(
            'truncate text-text-tertiary',
            compact ? 'text-[10px]' : 'text-xs',
          )}
          style={{ fontVariantNumeric: 'tabular-nums' }}
        >
          {displayReason} ·{' '}
          {relativeTime(tx.timestamp_ms)}
        </span>
      </div>

      <div
        className={cn('font-semibold shrink-0', compact ? 'text-xs' : 'text-sm')}
        style={{ color: amountColor, fontVariantNumeric: 'tabular-nums lining-nums' }}
      >
        {streamerMode ? maskSignedMoneyDisplay() : signedMoney((isOutgoing ? -1 : 1) * tx.amount_minor / 100)}
      </div>
    </motion.div>
  )
}

function getStatusMeta(t: (key: string) => string): Record<
  Transaction['status'],
  { icon: typeof Check; label: string; color: string }
> {
  return {
    committed: { icon: Check, label: t('transactions.statusCommitted'), color: 'rgb(53, 193, 119)' },
    pending: { icon: RotateCw, label: t('transactions.statusPending'), color: 'rgb(230, 173, 0)' },
    reconciling: { icon: RotateCw, label: t('transactions.statusReconciling'), color: 'rgb(230, 173, 0)' },
    reverted: { icon: AlertTriangle, label: t('transactions.statusReverted'), color: 'rgb(252, 88, 85)' },
    failed: { icon: AlertTriangle, label: t('transactions.statusFailed'), color: 'rgb(252, 88, 85)' },
  }
}

function compactIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '')
}
