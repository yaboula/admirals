import { motion } from 'motion/react'
import { Star, Zap, Loader2 } from 'lucide-react'
import { Card, CardEyebrow, CardTitle } from '@/components/ui'
import { useRecentRecipients } from '@/data/queries'
import type { RecentRecipient } from '@/data/contracts'
import { sfx } from '@/lib/sfx'
import { useTransferWizard } from '@/stores/transferWizard'
import { toast } from '@/stores/toast'
import { cn, formatRelativeTime } from '@/lib/utils'
import { MagneticHover } from '@/components/vanguard/MagneticHover'
import { getMockInitialsForIban } from '@/data/mock/seed'

export function QuickTransferList() {
  const { data, isLoading, isError } = useRecentRecipients()

  const initWizard = useTransferWizard((s) => s.init)
  const setRecipient = useTransferWizard((s) => s.setRecipient)
  const setAmount = useTransferWizard((s) => s.setAmount)

  const handleQuickSend = (r: RecentRecipient, amount: number): void => {
    initWizard(true)
    setRecipient(r.counterpart_iban, r.alias)
    setAmount(amount, r.last_reason ?? '')
    sfx.coin_clink()
    toast.info(
      `Transferencia rápida iniciada`,
      `${formatEur(amount / 100)} → ${r.alias ?? formatIbanShort(r.counterpart_iban)}`,
    )
  }

  return (
    <Card variant="baseline" padding="lg" className="relative overflow-hidden">
      <div className="flex items-end justify-between mb-4">
        <div className="flex flex-col gap-1">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              <Zap size={11} strokeWidth={2.4} className="text-brand-signal-orange-light" />
              EXPRESS · 2 PASOS
            </span>
          </CardEyebrow>
          <CardTitle>Transferir rápido</CardTitle>
        </div>
        {data?.cached && (
          <span className="text-[10px] uppercase tracking-wider text-text-tertiary border border-border-subtle rounded px-1.5 py-0.5">
            cache
          </span>
        )}
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-10 text-text-tertiary">
          <Loader2 size={20} className="animate-spin" />
        </div>
      ) : isError ? (
        <div className="text-sm text-semantic-danger-deep py-6">
          No se pudieron cargar los destinatarios recientes.
        </div>
      ) : !data || data.recipients.length === 0 ? (
        <div className="text-sm text-text-tertiary py-6">
          Aún no has realizado transferencias en los últimos 90 días.
        </div>
      ) : (
        <div className="space-y-2">
          {data.recipients.slice(0, 6).map((r, i) => (
            <RecipientRow
              key={r.counterpart_iban}
              recipient={r}
              onQuickSend={handleQuickSend}
              index={i}
            />
          ))}
        </div>
      )}
    </Card>
  )
}

function RecipientRow({
  recipient,
  onQuickSend,
  index,
}: {
  recipient: RecentRecipient
  onQuickSend: (r: RecentRecipient, amount: number) => void
  index: number
}) {
  const initials =
    recipient.alias
      ?.split(' ')
      .map((s) => s[0])
      .filter(Boolean)
      .slice(0, 2)
      .join('')
      .toUpperCase() ?? getMockInitialsForIban(recipient.counterpart_iban)

  const presetAmount = recipient.preset_amounts[0] ?? 0

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.04, duration: 0.32, ease: [0.16, 1, 0.3, 1] }}
      className={cn(
        'group flex items-center gap-3 rounded-xl px-3 py-2.5',
        'border border-transparent hover:border-border-medium',
        'hover:bg-surface-card-elevated/40 transition-colors',
      )}
    >
      <div className="relative shrink-0">
        <div
          className={cn(
            'inline-flex h-10 w-10 items-center justify-center rounded-full',
            'text-sm font-semibold tactile-wght-breathing',
          )}
          style={{
            background: 'linear-gradient(135deg, oklch(0.13 0.012 270), oklch(0.18 0.014 270))',
            border: '1px solid var(--color-border-medium)',
            boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.06)',
          }}
        >
          {initials || '··'}
        </div>
        {recipient.is_favorite && (
          <span
            aria-hidden
            className="absolute -top-1 -right-1 inline-flex h-4 w-4 items-center justify-center rounded-full"
            style={{ background: 'var(--gradient-primary)', boxShadow: '0 0 8px oklch(0.65 0.22 40 / 0.6)' }}
          >
            <Star size={9} strokeWidth={2.6} fill="currentColor" className="text-text-primary" />
          </span>
        )}
      </div>

      <div className="flex-1 flex flex-col min-w-0">
        <div className="flex items-center gap-2 min-w-0">
          <span className="text-sm font-medium text-text-primary tactile-wght-breathing truncate">
            {recipient.alias ?? formatIbanShort(recipient.counterpart_iban)}
          </span>
          <span className="text-[10px] text-text-tertiary tactile-tabular-nums">
            ×{recipient.transfer_count}
          </span>
        </div>
        <div className="flex items-center gap-2 text-xs text-text-tertiary">
          <span className="tactile-tabular-nums truncate">
            {formatRelativeTime(recipient.last_transfer_ms)}
          </span>
          {recipient.last_reason && (
            <>
              <span className="h-2 w-px bg-border-medium shrink-0" />
              <span className="truncate italic">{recipient.last_reason}</span>
            </>
          )}
        </div>
      </div>

      <div className="flex items-center gap-1.5 shrink-0">
        {recipient.preset_amounts.slice(0, 2).map((amt, idx) => (
          <MagneticHover key={idx} strength={0.25}>
            <button
              type="button"
              onClick={() => onQuickSend(recipient, amt)}
              className={cn(
                'tactile-focus-ring px-2.5 h-7 rounded-md text-xs font-medium tactile-tabular-nums',
                'border border-border-medium text-text-secondary',
                'hover:text-text-primary hover:border-border-brand-strong hover:bg-brand-signal-orange-subtle',
                'transition-colors',
              )}
              aria-label={`Enviar ${formatEur(amt / 100)} a ${recipient.alias ?? recipient.counterpart_iban}`}
            >
              €{formatEur(amt / 100)}
            </button>
          </MagneticHover>
        ))}
        <button
          type="button"
          onClick={() => onQuickSend(recipient, presetAmount)}
          aria-label="Transferir ahora"
          className={cn(
            'tactile-button-primary tactile-focus-ring inline-flex items-center justify-center',
            'h-7 px-3 rounded-md text-xs font-semibold gap-1',
          )}
        >
          <Zap size={11} strokeWidth={2.6} />
          Express
        </button>
      </div>
    </motion.div>
  )
}

function formatEur(major: number): string {
  return new Intl.NumberFormat('es-ES', {
    minimumFractionDigits: major < 100 ? 2 : 0,
    maximumFractionDigits: 2,
  }).format(major)
}

function formatIbanShort(iban: string): string {
  const compact = iban.replace(/\s+/g, '')
  if (compact.length < 8) return iban
  return `${compact.slice(0, 4)}…${compact.slice(-4)}`
}
