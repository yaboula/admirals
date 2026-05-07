import { useEffect } from 'react'
import { motion, AnimatePresence, useReducedMotion } from 'motion/react'
import {
  X,
  Copy,
  RotateCw,
  ArrowDownLeft,
  ArrowUpRight,
  Check,
  AlertTriangle,
  Repeat,
  Flag,
  Receipt,
} from 'lucide-react'
import type { Transaction } from '@/data/contracts'
import { cn, formatRelativeTime } from '@/lib/utils'
import { getMockAliasForIban, getMockInitialsForIban } from '@/data/mock/seed'
import { sfx } from '@/lib/sfx'
import { toast } from '@/stores/toast'

/**
 * BANK-FE.3 — Transaction detail drawer.
 *
 * Slides in from the right edge over a backdrop scrim. Renders the FULL
 * counterpart IBAN (hidden from the dashboard preview by design), an animated
 * status timeline, and three placeholder action buttons that surface a toast
 * pending real backend wiring (Repetir / Reportar / Compartir recibo).
 *
 * Closes on: Escape · backdrop click · X button.
 */
export interface TransactionDetailDrawerProps {
  tx: Transaction | null
  ownIban: string | undefined
  onClose: () => void
}

export function TransactionDetailDrawer({ tx, ownIban, onClose }: TransactionDetailDrawerProps) {
  const reduced = useReducedMotion()

  // Esc to close.
  useEffect(() => {
    if (!tx) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        onClose()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [tx, onClose])

  return (
    <AnimatePresence>
      {tx && (
        <>
          {/* Backdrop */}
          <motion.div
            key="backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: reduced ? 0 : 0.22 }}
            onClick={onClose}
            className="absolute inset-0 z-[var(--z-drawer-scrim)] bg-surface-modal-scrim backdrop-blur-sm"
            aria-hidden
          />
          {/* Panel */}
          <motion.aside
            key="panel"
            role="dialog"
            aria-modal="true"
            aria-label="Detalle de transacción"
            initial={reduced ? { opacity: 0 } : { x: '100%', opacity: 0.85 }}
            animate={{ x: 0, opacity: 1 }}
            exit={reduced ? { opacity: 0 } : { x: '100%', opacity: 0 }}
            transition={
              reduced
                ? { duration: 0.18 }
                : { type: 'spring', stiffness: 320, damping: 34, mass: 0.85 }
            }
            className={cn(
              'absolute top-0 right-0 bottom-0 z-[var(--z-drawer)]',
              'w-full sm:w-[440px] lg:w-[480px]',
              'flex flex-col',
              'border-l border-white/10',
            )}
            style={{
              background: 'linear-gradient(180deg, oklch(0.06 0.008 270) 0%, oklch(0.02 0 0) 100%)',
              boxShadow:
                '-12px 0 48px -12px oklch(0 0 0 / 0.7), inset 1px 0 0 oklch(1 0 0 / 0.04)',
            }}
          >
            <DrawerBody tx={tx} ownIban={ownIban} onClose={onClose} />
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  )
}

/* -------------------------------------------------------------------------- */

function DrawerBody({
  tx,
  ownIban,
  onClose,
}: {
  tx: Transaction
  ownIban: string | undefined
  onClose: () => void
}) {
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

  const handleCopyIban = async (): Promise<void> => {
    try {
      await navigator.clipboard.writeText(counterpartIban.replace(/\s+/g, ''))
      sfx.coin_clink()
      toast.success('IBAN copiado', counterpartName)
    } catch {
      toast.warning('No se pudo copiar', 'Permiso de portapapeles denegado.')
    }
  }

  const handleAction = (label: string) => () => {
    sfx.console_tap()
    toast.info(label, 'Disponible cuando el backend BANK-BE.3 esté operativo.')
  }

  return (
    <>
      {/* Header */}
      <div className="flex items-start justify-between px-6 pt-6 pb-4">
        <div className="flex items-center gap-3 min-w-0">
          <span
            className="relative inline-flex items-center justify-center h-12 w-12 rounded-full shrink-0"
            style={{
              background: isOutgoing
                ? 'linear-gradient(135deg, oklch(0.20 0.020 25 / 0.7), oklch(0.10 0.010 25 / 0.5))'
                : 'linear-gradient(135deg, oklch(0.20 0.020 155 / 0.7), oklch(0.10 0.010 155 / 0.5))',
              border: `1px solid ${isOutgoing ? 'oklch(0.68 0.20 25 / 0.32)' : 'oklch(0.72 0.16 155 / 0.32)'}`,
              color: isOutgoing ? 'oklch(0.78 0.18 25)' : 'oklch(0.80 0.18 155)',
              boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.08), inset 0 -1px 0 oklch(0 0 0 / 0.34)',
            }}
            aria-hidden
          >
            <span className="text-sm font-semibold tactile-tabular-nums">{initials}</span>
          </span>
          <div className="flex flex-col min-w-0">
            <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">
              {isOutgoing ? 'Enviado a' : 'Recibido de'}
            </span>
            <span className="text-base font-semibold text-text-primary truncate tactile-wght-breathing">
              {counterpartName}
            </span>
          </div>
        </div>
        <button
          type="button"
          onClick={onClose}
          aria-label="Cerrar detalle"
          className="inline-flex items-center justify-center h-9 w-9 rounded-full text-text-tertiary hover:text-text-primary hover:bg-surface-card-elevated/50 transition-colors tactile-focus-ring"
        >
          <X size={16} strokeWidth={2} />
        </button>
      </div>

      {/* Hero amount */}
      <div className="px-6 pb-5">
        <div
          className="relative rounded-2xl px-6 py-5 overflow-hidden"
          style={{
            background:
              'linear-gradient(135deg, oklch(0.10 0.010 270 / 0.7) 0%, oklch(0.06 0.008 270 / 0.4) 100%)',
            border: '1px solid oklch(1 0 0 / 0.08)',
            boxShadow:
              'inset 0 1px 0 oklch(1 0 0 / 0.06), 0 8px 24px -8px oklch(0 0 0 / 0.5)',
          }}
        >
          {/* Subtle direction-tinted aura */}
          <div
            aria-hidden
            className="absolute pointer-events-none"
            style={{
              top: '-30%',
              right: '-20%',
              width: '90%',
              height: '160%',
              background: isOutgoing
                ? 'radial-gradient(circle at 50% 50%, oklch(0.68 0.20 25 / 0.10), transparent 60%)'
                : 'radial-gradient(circle at 50% 50%, oklch(0.72 0.16 155 / 0.10), transparent 60%)',
              filter: 'blur(20px)',
            }}
          />
          <div className="relative flex items-end justify-between gap-4">
            <div className="flex flex-col gap-1">
              <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">
                Importe
              </span>
              <span
                className="text-3xl font-semibold tracking-tight tactile-display-balance"
                style={{ color: amountColor }}
              >
                {sign}€{formatEur(tx.amount_minor / 100)}
              </span>
            </div>
            <span
              className="inline-flex items-center justify-center h-10 w-10 rounded-full"
              style={{
                background: 'oklch(0 0 0 / 0.4)',
                border: '1px solid oklch(1 0 0 / 0.08)',
                color: amountColor,
              }}
              aria-hidden
            >
              <DirIcon size={18} strokeWidth={2.2} />
            </span>
          </div>
        </div>
      </div>

      {/* Body grid */}
      <div className="flex-1 min-h-0 overflow-y-auto px-6 pb-6 flex flex-col gap-5">
        <DetailRow
          label="Concepto"
          value={tx.reason ?? (isOutgoing ? 'Transferencia' : 'Pago recibido')}
        />

        <div className="flex flex-col gap-1.5">
          <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">
            IBAN del {isOutgoing ? 'beneficiario' : 'remitente'}
          </span>
          <button
            type="button"
            onClick={handleCopyIban}
            className="group flex items-center gap-2 text-left"
            aria-label={`Copiar IBAN ${counterpartIban}`}
          >
            <span className="text-sm font-mono font-medium text-text-primary tracking-wider tactile-tabular-nums">
              {counterpartIban}
            </span>
            <Copy
              size={12}
              strokeWidth={2}
              className="text-text-tertiary opacity-50 group-hover:opacity-100 transition-opacity"
            />
          </button>
        </div>

        <DetailRow
          label="Fecha"
          value={`${new Date(tx.timestamp_ms).toLocaleString('es-ES', {
            day: '2-digit',
            month: 'long',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
          })} · ${formatRelativeTime(tx.timestamp_ms)}`}
        />

        <DetailRow label="ID transacción" mono value={tx.txn_id} />

        {/* Status timeline */}
        <div className="flex flex-col gap-2">
          <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">
            Estado
          </span>
          <StatusTimeline status={tx.status} timestampMs={tx.timestamp_ms} />
        </div>
      </div>

      {/* Footer actions */}
      <div className="px-6 pb-6 pt-4 border-t border-white/06 flex flex-col gap-2">
        <ActionButton
          icon={<Repeat size={14} strokeWidth={2.2} />}
          label="Repetir transferencia"
          tone="primary"
          onClick={handleAction('Repetir transferencia')}
        />
        <div className="grid grid-cols-2 gap-2">
          <ActionButton
            icon={<Receipt size={14} strokeWidth={2.2} />}
            label="Recibo"
            tone="secondary"
            onClick={handleAction('Compartir recibo')}
          />
          <ActionButton
            icon={<Flag size={14} strokeWidth={2.2} />}
            label="Reportar"
            tone="ghost"
            onClick={handleAction('Reportar transacción')}
          />
        </div>
      </div>
    </>
  )
}

/* -------------------------------------------------------------------------- */

function DetailRow({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex flex-col gap-1">
      <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">
        {label}
      </span>
      <span
        className={cn(
          'text-sm text-text-primary',
          mono && 'font-mono tactile-tabular-nums tracking-wider text-[12px]',
        )}
      >
        {value}
      </span>
    </div>
  )
}

/* -------------------------------------------------------------------------- */

function StatusTimeline({
  status,
  timestampMs,
}: {
  status: Transaction['status']
  timestampMs: number
}) {
  const steps: Array<{
    key: string
    label: string
    state: 'done' | 'current' | 'pending' | 'failed'
    icon: typeof Check
  }> = [
    { key: 'init', label: 'Iniciada', state: 'done', icon: Check },
    {
      key: 'process',
      label: 'En proceso',
      state:
        status === 'pending' || status === 'reconciling'
          ? 'current'
          : status === 'failed' || status === 'reverted'
            ? 'failed'
            : 'done',
      icon: status === 'pending' || status === 'reconciling' ? RotateCw : Check,
    },
    {
      key: 'final',
      label:
        status === 'committed'
          ? 'Confirmada'
          : status === 'pending'
            ? 'Pendiente confirmación'
            : status === 'reverted'
              ? 'Revertida'
              : status === 'failed'
                ? 'Fallida'
                : 'Reconciliando',
      state:
        status === 'committed'
          ? 'done'
          : status === 'failed' || status === 'reverted'
            ? 'failed'
            : 'pending',
      icon: status === 'failed' || status === 'reverted' ? AlertTriangle : Check,
    },
  ]

  return (
    <div className="flex flex-col gap-2.5">
      {steps.map((s, i) => {
        const Icon = s.icon
        const color =
          s.state === 'done'
            ? 'oklch(0.72 0.16 155)'
            : s.state === 'current'
              ? 'oklch(0.78 0.16 85)'
              : s.state === 'failed'
                ? 'oklch(0.68 0.20 25)'
                : 'oklch(0.55 0.012 270 / 0.6)'
        return (
          <div key={s.key} className="flex items-center gap-3 relative">
            <span
              className="inline-flex items-center justify-center h-7 w-7 rounded-full shrink-0"
              style={{
                background: `${color.replace(')', ' / 0.10)')}`,
                color,
                border: `1px solid ${color.replace(')', ' / 0.32)')}`,
              }}
              aria-hidden
            >
              <Icon
                size={11}
                strokeWidth={2.4}
                className={s.state === 'current' ? 'animate-spin' : ''}
              />
            </span>
            <div className="flex-1 flex items-center justify-between min-w-0">
              <span
                className="text-[12px] font-medium"
                style={{ color: s.state === 'pending' ? 'var(--color-text-tertiary)' : 'var(--color-text-primary)' }}
              >
                {s.label}
              </span>
              {i === 0 && (
                <span className="text-[10px] text-text-tertiary tactile-tabular-nums">
                  {formatRelativeTime(timestampMs)}
                </span>
              )}
            </div>
            {/* Connecting line */}
            {i < steps.length - 1 && (
              <span
                aria-hidden
                className="absolute left-[13px] top-7 w-px h-3"
                style={{ background: 'oklch(1 0 0 / 0.06)' }}
              />
            )}
          </div>
        )
      })}
    </div>
  )
}

/* -------------------------------------------------------------------------- */

function ActionButton({
  icon,
  label,
  tone,
  onClick,
}: {
  icon: React.ReactNode
  label: string
  tone: 'primary' | 'secondary' | 'ghost'
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'tactile-action-btn tactile-focus-ring',
        `tactile-action-btn--${tone}`,
        'justify-center',
      )}
      style={{ paddingTop: 12, paddingBottom: 12 }}
    >
      <span className="tactile-action-icon" aria-hidden>
        {icon}
      </span>
      <span className="tactile-action-label">
        <span className="text-[13px] font-semibold">{label}</span>
      </span>
    </button>
  )
}

function formatEur(major: number): string {
  return new Intl.NumberFormat('es-ES', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(major)
}
