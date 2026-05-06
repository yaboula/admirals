import { motion } from 'motion/react'
import { ArrowDownLeft, ArrowUpRight, RotateCw, AlertTriangle, Check } from 'lucide-react'
import { Card, CardEyebrow, CardTitle } from '@/components/ui'
import type { Account, Transaction } from '@/data/contracts'
import { cn, formatRelativeTime } from '@/lib/utils'

export interface ActivityPreviewProps {
  transactions: Transaction[]
  account: Account | undefined
  loading?: boolean
  /** Compact mode: tighter spacing, 3 rows max — for zero-scroll dashboard */
  compact?: boolean
}

export function ActivityPreview({ transactions, account, loading, compact }: ActivityPreviewProps) {
  const own = account?.iban.replace(/\s+/g, '')
  const limit = compact ? 3 : 6

  return (
    <Card variant="baseline" padding={compact ? 'md' : 'lg'}>
      <div className={cn('flex items-end justify-between', compact ? 'mb-2' : 'mb-4')}>
        <div className="flex flex-col gap-0.5">
          <CardEyebrow>ACTIVIDAD RECIENTE</CardEyebrow>
          <CardTitle className={compact ? 'text-sm' : undefined}>Movimientos</CardTitle>
        </div>
        <span className="text-xs text-text-tertiary">
          Últimos {Math.min(transactions.length, limit)} de {transactions.length}
        </span>
      </div>

      {loading ? (
        <div className="space-y-1.5">
          {Array.from({ length: limit }).map((_, i) => (
            <div key={i} className={cn('tactile-skeleton w-full', compact ? 'h-10' : 'h-12')} />
          ))}
        </div>
      ) : transactions.length === 0 ? (
        <div className={cn('text-sm text-text-tertiary', compact ? 'py-3' : 'py-6')}>
          Sin movimientos recientes.
        </div>
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
  const fromCompact = tx.from_iban.replace(/\s+/g, '')
  const toCompact = tx.to_iban.replace(/\s+/g, '')
  const isOutgoing = ownIban ? fromCompact === ownIban && toCompact !== ownIban : tx.direction === 'out'
  const counterpart = isOutgoing ? tx.to_iban : tx.from_iban
  const sign = isOutgoing ? '−' : '+'
  const amountColor = isOutgoing ? 'oklch(0.92 0.005 270)' : 'oklch(0.70 0.16 155)'

  const StatusIcon = STATUS_META[tx.status].icon
  const DirIcon = isOutgoing ? ArrowUpRight : ArrowDownLeft

  const iconSize = compact ? 14 : 16
  const avatarSize = compact ? 'h-7 w-7' : 'h-9 w-9'

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
          avatarSize,
        )}
        style={{
          background: isOutgoing ? 'oklch(0.62 0.21 25 / 0.10)' : 'oklch(0.65 0.18 155 / 0.10)',
          color: isOutgoing ? 'oklch(0.62 0.21 25)' : 'oklch(0.65 0.18 155)',
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
            {tx.reason ?? (isOutgoing ? 'Transferencia enviada' : 'Transferencia recibida')}
          </span>
          {tx.status !== 'committed' && (
            <span
              className="inline-flex items-center gap-1 text-[9px] uppercase tracking-wider px-1.5 py-0.5 rounded border shrink-0"
              style={{
                color: STATUS_META[tx.status].color,
                borderColor: STATUS_META[tx.status].color,
              }}
            >
              <StatusIcon size={8} strokeWidth={2.6} />
              {STATUS_META[tx.status].label}
            </span>
          )}
        </div>
        <div
          className={cn(
            'flex items-center gap-1.5 text-text-tertiary',
            compact ? 'text-[10px]' : 'text-xs',
          )}
        >
          <span style={{ fontVariantNumeric: 'tabular-nums' }}>
            {formatRelativeTime(tx.timestamp_ms)}
          </span>
          <span className="h-2 w-px bg-border-medium shrink-0" />
          <span className="font-mono truncate">{formatIbanShort(counterpart)}</span>
        </div>
      </div>

      <div
        className={cn(
          'font-semibold shrink-0',
          compact ? 'text-xs' : 'text-sm',
        )}
        style={{ color: amountColor, fontVariantNumeric: 'tabular-nums' }}
      >
        {sign}€{formatEur(tx.amount_minor / 100)}
      </div>
    </motion.div>
  )
}

const STATUS_META: Record<
  Transaction['status'],
  { icon: typeof Check; label: string; color: string }
> = {
  committed: { icon: Check, label: 'OK', color: 'oklch(0.65 0.18 155)' },
  pending: { icon: RotateCw, label: 'pendiente', color: 'oklch(0.78 0.16 85)' },
  reconciling: { icon: RotateCw, label: 'reconcil.', color: 'oklch(0.78 0.16 85)' },
  reverted: { icon: AlertTriangle, label: 'revertido', color: 'oklch(0.62 0.21 25)' },
  failed: { icon: AlertTriangle, label: 'fallida', color: 'oklch(0.62 0.21 25)' },
}

function formatEur(major: number): string {
  return new Intl.NumberFormat('es-ES', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(major)
}

function formatIbanShort(iban: string): string {
  const compact = iban.replace(/\s+/g, '')
  if (compact.length < 8) return iban
  return `${compact.slice(0, 4)}…${compact.slice(-4)}`
}
