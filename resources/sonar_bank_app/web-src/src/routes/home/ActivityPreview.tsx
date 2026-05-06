import { motion } from 'motion/react'
import { ArrowDownLeft, ArrowUpRight, RotateCw, AlertTriangle, Check } from 'lucide-react'
import { Card, CardEyebrow, CardTitle } from '@/components/ui'
import type { Account, Transaction } from '@/data/contracts'
import { cn, formatRelativeTime } from '@/lib/utils'

export interface ActivityPreviewProps {
  transactions: Transaction[]
  account: Account | undefined
  loading?: boolean
}

export function ActivityPreview({ transactions, account, loading }: ActivityPreviewProps) {
  const own = account?.iban.replace(/\s+/g, '')

  return (
    <Card variant="baseline" padding="lg">
      <div className="flex items-end justify-between mb-4">
        <div className="flex flex-col gap-1">
          <CardEyebrow>ACTIVIDAD RECIENTE</CardEyebrow>
          <CardTitle>Movimientos</CardTitle>
        </div>
        <span className="text-xs text-text-tertiary">Últimos {Math.min(transactions.length, 6)} de {transactions.length}</span>
      </div>

      {loading ? (
        <div className="space-y-2">
          {[0, 1, 2, 3].map((i) => (
            <div key={i} className="tactile-skeleton h-12 w-full" />
          ))}
        </div>
      ) : transactions.length === 0 ? (
        <div className="text-sm text-text-tertiary py-6">Sin movimientos recientes.</div>
      ) : (
        <div className="space-y-1.5">
          {transactions.slice(0, 6).map((t, i) => (
            <Row key={t.txn_id} tx={t} ownIban={own} index={i} />
          ))}
        </div>
      )}
    </Card>
  )
}

function Row({ tx, ownIban, index }: { tx: Transaction; ownIban: string | undefined; index: number }) {
  const fromCompact = tx.from_iban.replace(/\s+/g, '')
  const toCompact = tx.to_iban.replace(/\s+/g, '')
  const isOutgoing = ownIban ? fromCompact === ownIban && toCompact !== ownIban : tx.direction === 'out'
  const counterpart = isOutgoing ? tx.to_iban : tx.from_iban
  const sign = isOutgoing ? '−' : '+'
  const amountColor = isOutgoing ? 'text-text-primary' : 'oklch(0.65 0.18 155)'

  const StatusIcon = STATUS_META[tx.status].icon
  const DirIcon = isOutgoing ? ArrowUpRight : ArrowDownLeft

  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.03, duration: 0.28 }}
      className={cn(
        'flex items-center gap-3 px-2.5 py-2.5 rounded-lg',
        'hover:bg-surface-card-elevated/40 transition-colors',
      )}
    >
      <span
        className={cn(
          'inline-flex h-9 w-9 items-center justify-center rounded-lg shrink-0',
        )}
        style={{
          background: isOutgoing ? 'oklch(0.62 0.21 25 / 0.10)' : 'oklch(0.65 0.18 155 / 0.10)',
          color: isOutgoing ? 'oklch(0.62 0.21 25)' : 'oklch(0.65 0.18 155)',
        }}
        aria-hidden
      >
        <DirIcon size={16} strokeWidth={2} />
      </span>

      <div className="flex-1 flex flex-col min-w-0">
        <div className="flex items-center gap-2 min-w-0">
          <span className="text-sm text-text-primary truncate font-medium">
            {tx.reason ?? (isOutgoing ? 'Transferencia enviada' : 'Transferencia recibida')}
          </span>
          {tx.status !== 'committed' && (
            <span
              className="inline-flex items-center gap-1 text-[10px] uppercase tracking-wider px-1.5 py-0.5 rounded border"
              style={{
                color: STATUS_META[tx.status].color,
                borderColor: STATUS_META[tx.status].color,
              }}
            >
              <StatusIcon size={9} strokeWidth={2.6} />
              {STATUS_META[tx.status].label}
            </span>
          )}
        </div>
        <div className="flex items-center gap-2 text-xs text-text-tertiary">
          <span className="tactile-tabular-nums">{formatRelativeTime(tx.timestamp_ms)}</span>
          <span className="h-2 w-px bg-border-medium shrink-0" />
          <span className="font-mono truncate">{formatIbanShort(counterpart)}</span>
        </div>
      </div>

      <div
        className="text-sm font-semibold tactile-tabular-nums shrink-0"
        style={{ color: amountColor }}
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
