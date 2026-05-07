import { motion } from 'motion/react'
import { ArrowDownLeft, ArrowUpRight, RotateCw, AlertTriangle, Check, ChevronRight } from 'lucide-react'
import type { Transaction } from '@/data/contracts'
import { cn, formatRelativeTime } from '@/lib/utils'
import { getMockAliasForIban, getMockInitialsForIban } from '@/data/mock/seed'

/**
 * BANK-FE.3 — Single transaction row.
 *
 * Differs from the dashboard ActivityPreview row in three ways:
 *   1. Larger height + initials avatar instead of plain icon (counterpart identity)
 *   2. Hover state lifts via tactile shadow + reveals chevron
 *   3. Click invokes the detail drawer via parent onSelect
 *
 * Selected row gets an orange whisper outline so it stays anchored visually
 * while the drawer is open.
 */
export interface TransactionRowProps {
  tx: Transaction
  ownIban: string | undefined
  index: number
  selected?: boolean
  onSelect: (tx: Transaction) => void
}

export function TransactionRow({ tx, ownIban, index, selected, onSelect }: TransactionRowProps) {
  const fromCompact = tx.from_iban.replace(/\s+/g, '')
  const toCompact = tx.to_iban.replace(/\s+/g, '')
  const isOutgoing = ownIban
    ? fromCompact === ownIban && toCompact !== ownIban
    : tx.direction === 'out'
  const counterpartIban = isOutgoing ? tx.to_iban : tx.from_iban
  const counterpartName =
    getMockAliasForIban(counterpartIban) ?? (isOutgoing ? 'Beneficiario' : 'Remitente')
  const initials = getMockInitialsForIban(counterpartIban)

  const sign = isOutgoing ? '−' : '+'
  const amountColor = isOutgoing ? 'oklch(0.92 0.005 270)' : 'oklch(0.78 0.16 155)'
  const DirIcon = isOutgoing ? ArrowUpRight : ArrowDownLeft
  const StatusIcon = STATUS_META[tx.status].icon

  return (
    <motion.button
      type="button"
      onClick={() => onSelect(tx)}
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: Math.min(index, 12) * 0.018, duration: 0.26 }}
      aria-pressed={selected}
      aria-label={`${counterpartName} · ${sign}€${formatEur(tx.amount_minor / 100)} · ${formatRelativeTime(tx.timestamp_ms)}`}
      className={cn(
        'group w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-left',
        'transition-[box-shadow,background,border-color] duration-180',
        'tactile-focus-ring',
      )}
      style={{
        background: selected
          ? 'linear-gradient(135deg, oklch(0.65 0.22 40 / 0.06), oklch(1 0 0 / 0.02))'
          : 'transparent',
        border: `1px solid ${selected ? 'oklch(0.65 0.22 40 / 0.32)' : 'transparent'}`,
        boxShadow: selected
          ? 'inset 0 1px 0 oklch(1 0 0 / 0.05), 0 0 0 1px oklch(0 0 0 / 0.4), 0 6px 16px -8px oklch(0.65 0.22 40 / 0.28)'
          : undefined,
      }}
      onMouseEnter={(e) => {
        if (!selected) {
          e.currentTarget.style.background = 'oklch(1 0 0 / 0.025)'
        }
      }}
      onMouseLeave={(e) => {
        if (!selected) {
          e.currentTarget.style.background = 'transparent'
        }
      }}
    >
      {/* Avatar pill — initials over direction-tinted background */}
      <span
        className="relative inline-flex items-center justify-center h-10 w-10 rounded-full shrink-0"
        style={{
          background: isOutgoing
            ? 'linear-gradient(135deg, oklch(0.18 0.014 25 / 0.6), oklch(0.10 0.010 25 / 0.4))'
            : 'linear-gradient(135deg, oklch(0.18 0.014 155 / 0.6), oklch(0.10 0.010 155 / 0.4))',
          border: `1px solid ${isOutgoing ? 'oklch(0.68 0.20 25 / 0.24)' : 'oklch(0.72 0.16 155 / 0.24)'}`,
          color: isOutgoing ? 'oklch(0.78 0.18 25)' : 'oklch(0.80 0.18 155)',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.06), inset 0 -1px 0 oklch(0 0 0 / 0.32)',
        }}
        aria-hidden
      >
        <span className="text-[11px] font-semibold tracking-wide tactile-tabular-nums">
          {initials}
        </span>
        <span
          className="absolute -bottom-0.5 -right-0.5 inline-flex items-center justify-center h-4 w-4 rounded-full"
          style={{
            background: 'oklch(0.05 0.005 270)',
            border: '1px solid oklch(1 0 0 / 0.08)',
            color: isOutgoing ? 'oklch(0.78 0.18 25)' : 'oklch(0.80 0.18 155)',
          }}
        >
          <DirIcon size={10} strokeWidth={2.4} />
        </span>
      </span>

      {/* Body */}
      <div className="flex-1 flex flex-col min-w-0 leading-tight">
        <div className="flex items-center gap-2 min-w-0">
          <span className="truncate font-medium text-sm text-text-primary tactile-wght-breathing">
            {counterpartName}
          </span>
          {tx.status !== 'committed' && (
            <span
              className="inline-flex items-center gap-1 text-[9px] uppercase tracking-wider px-1.5 py-0.5 rounded shrink-0"
              style={{
                color: STATUS_META[tx.status].color,
                borderColor: STATUS_META[tx.status].color,
                border: `1px solid ${STATUS_META[tx.status].color}`,
                background: `${STATUS_META[tx.status].color.replace(')', ' / 0.06)')}`,
              }}
            >
              <StatusIcon size={9} strokeWidth={2.6} />
              {STATUS_META[tx.status].label}
            </span>
          )}
        </div>
        <span
          className="truncate text-[11px] text-text-tertiary tactile-tabular-nums"
        >
          {tx.reason ?? (isOutgoing ? 'Transferencia' : 'Recibida')} · {formatRelativeTime(tx.timestamp_ms)}
        </span>
      </div>

      {/* Amount + chevron */}
      <div className="flex flex-col items-end gap-0.5 shrink-0">
        <span
          className="text-sm font-semibold tactile-tabular-nums"
          style={{ color: amountColor, fontVariantNumeric: 'tabular-nums lining-nums' }}
        >
          {sign}€{formatEur(tx.amount_minor / 100)}
        </span>
        <span className="text-[9px] uppercase tracking-wider text-text-tertiary tactile-tabular-nums">
          {formatTime(tx.timestamp_ms)}
        </span>
      </div>
      <ChevronRight
        size={14}
        strokeWidth={2}
        aria-hidden
        className="shrink-0 text-text-tertiary opacity-40 group-hover:opacity-90 group-hover:translate-x-0.5 transition-all duration-180"
      />
    </motion.button>
  )
}

const STATUS_META: Record<
  Transaction['status'],
  { icon: typeof Check; label: string; color: string }
> = {
  committed: { icon: Check, label: 'OK', color: 'oklch(0.72 0.16 155)' },
  pending: { icon: RotateCw, label: 'pendiente', color: 'oklch(0.78 0.16 85)' },
  reconciling: { icon: RotateCw, label: 'reconcil.', color: 'oklch(0.78 0.16 85)' },
  reverted: { icon: AlertTriangle, label: 'revertida', color: 'oklch(0.68 0.20 25)' },
  failed: { icon: AlertTriangle, label: 'fallida', color: 'oklch(0.68 0.20 25)' },
}

function formatEur(major: number): string {
  return new Intl.NumberFormat('es-ES', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(major)
}

function formatTime(ms: number): string {
  return new Date(ms).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })
}
