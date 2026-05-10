import { motion } from 'motion/react'
import { ArrowDownLeft, ArrowUpRight, RotateCw, AlertTriangle, Check, ChevronRight } from 'lucide-react'
import type { Transaction } from '@/data/contracts'
import { cn } from '@/lib/utils'
import { useI18n } from '@/lib/i18n'
import { getMockAliasForIban } from '@/data/mock/seed'
import { BankAvatar } from '@/components/brand/BankAvatar'
import { maskSignedMoneyDisplay } from '@/lib/privacy'
import { usePrivacyMode } from '@/stores/privacy'

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
  const { t, signedMoney, relativeTime, dateTime } = useI18n()
  const fromCompact = compactIban(tx.from_iban)
  const toCompact = compactIban(tx.to_iban)
  const isOutgoing = ownIban
    ? fromCompact === ownIban && toCompact !== ownIban
    : tx.direction === 'out'
  const counterpartIban = String((isOutgoing ? tx.to_iban : tx.from_iban) ?? '')
  const counterpartName =
    getMockAliasForIban(counterpartIban) ?? (isOutgoing ? 'Beneficiario' : 'Remitente')

  const amountColor = isOutgoing ? 'rgb(227, 228, 232)' : 'rgb(78, 213, 137)'
  const DirIcon = isOutgoing ? ArrowUpRight : ArrowDownLeft
  const StatusIcon = STATUS_META[tx.status].icon
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const amountLabel = streamerMode ? maskSignedMoneyDisplay() : signedMoney((isOutgoing ? -1 : 1) * tx.amount_minor / 100)
  const displayName = streamerMode ? t('transactions.hiddenMovement') : counterpartName
  const displayReason = streamerMode ? t('transactions.hiddenDetail') : tx.reason ?? (isOutgoing ? t('transactions.transfer') : t('transactions.received'))

  return (
    <motion.button
      type="button"
      onClick={() => onSelect(tx)}
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: Math.min(index, 12) * 0.018, duration: 0.26 }}
      aria-pressed={selected}
      aria-label={`${displayName} · ${streamerMode ? t('transfer.hiddenAmount') : amountLabel} · ${relativeTime(tx.timestamp_ms)}`}
      className={cn(
        'group w-full flex items-center gap-2.5 px-2.5 py-2 2xl:gap-3 2xl:px-3 2xl:py-2.5 rounded-xl text-left',
        'transition-[box-shadow,background,border-color] duration-180',
        'tactile-focus-ring',
      )}
      style={{
        background: selected
          ? 'rgba(255,255,255,0.07)'
          : 'transparent',
        border: `1px solid ${selected ? 'rgba(255,255,255,0.16)' : 'transparent'}`,
        boxShadow: selected
          ? 'inset 0 1px 0 rgba(255,255,255,0.08), 0 10px 22px -18px rgba(0,0,0,0.8)'
          : undefined,
      }}
      onMouseEnter={(e) => {
        if (!selected) {
          e.currentTarget.style.background = 'rgba(255,255,255,0.03)'
        }
      }}
      onMouseLeave={(e) => {
        if (!selected) {
          e.currentTarget.style.background = 'transparent'
        }
      }}
    >
      <span className="relative shrink-0" aria-hidden>
        <BankAvatar name={displayName} size="md" />
        <span
          className="absolute -bottom-0.5 -right-0.5 inline-flex items-center justify-center h-4 w-4 rounded-full"
          style={{
            background: 'rgb(0, 0, 1)',
            border: '1px solid rgba(255,255,255,0.08)',
            color: isOutgoing ? 'rgb(255, 130, 123)' : 'rgb(59, 223, 137)',
          }}
        >
          <DirIcon size={10} strokeWidth={2.4} />
        </span>
      </span>

      {/* Body */}
      <div className="flex-1 flex flex-col min-w-0 leading-tight">
        <div className="flex items-center gap-2 min-w-0">
          <span className="truncate font-medium text-sm text-text-primary tactile-wght-breathing">
            {displayName}
          </span>
          {tx.status !== 'committed' && (
            <span
              className="inline-flex items-center gap-1 text-[9px] uppercase tracking-wider px-1.5 py-0.5 rounded shrink-0"
              style={{
                color: STATUS_META[tx.status].color,
                borderColor: STATUS_META[tx.status].color,
                border: `1px solid ${STATUS_META[tx.status].color}`,
                background: withAlpha(STATUS_META[tx.status].color, 0.06),
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
          {displayReason} · {relativeTime(tx.timestamp_ms)}
        </span>
      </div>

      {/* Amount + chevron */}
      <div className="flex flex-col items-end gap-0.5 shrink-0">
        <span
          className="text-sm font-semibold tactile-tabular-nums"
          style={{ color: amountColor, fontVariantNumeric: 'tabular-nums lining-nums' }}
        >
          {amountLabel}
        </span>
        <span className="text-[9px] uppercase tracking-wider text-text-tertiary tactile-tabular-nums">
          {dateTime(tx.timestamp_ms, { hour: '2-digit', minute: '2-digit' })}
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
  committed: { icon: Check, label: 'OK', color: 'rgb(53, 193, 119)' },
  pending: { icon: RotateCw, label: 'pendiente', color: 'rgb(230, 173, 0)' },
  reconciling: { icon: RotateCw, label: 'reconcil.', color: 'rgb(230, 173, 0)' },
  reverted: { icon: AlertTriangle, label: 'revertida', color: 'rgb(252, 88, 85)' },
  failed: { icon: AlertTriangle, label: 'fallida', color: 'rgb(252, 88, 85)' },
}

function compactIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '')
}

function withAlpha(color: string | undefined | null, alpha: number): string {
  const value = String(color ?? '')
  const rgb = value.match(/^rgb\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\)$/)
  if (rgb) return `rgba(${rgb[1]}, ${rgb[2]}, ${rgb[3]}, ${alpha})`
  return 'rgba(255,255,255,0)'
}
