import { motion } from 'motion/react'
import { Star, Zap, Loader2 } from 'lucide-react'
import { Card, CardEyebrow, CardTitle } from '@/components/ui'
import { useRecentRecipients } from '@/data/queries'
import type { RecentRecipient } from '@/data/contracts'
import { sfx } from '@/lib/sfx'
import { useTransferWizard } from '@/stores/transferWizard'
import { toast } from '@/stores/toast'
import { cn, formatRelativeTime } from '@/lib/utils'
import { getMockInitialsForIban } from '@/data/mock/seed'

/**
 * Right-rail compact recipients list. Designed to fill remaining vertical
 * space below the credit-card visual without scrolling on 800-748px viewports.
 *
 * Express CTA uses ghost/outline styling — orange ONLY appears on hover.
 */
export function CompactQuickTransfer() {
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
      'Transferencia iniciada',
      `${formatEur(amount / 100)} → ${r.alias ?? formatIbanShort(r.counterpart_iban)}`,
    )
  }

  const handleNew = (): void => {
    initWizard(false)
    sfx.depth_press()
  }

  return (
    <Card
      variant="baseline"
      padding="md"
      className="relative overflow-hidden flex flex-col h-full min-h-0"
    >
      <div className="flex items-end justify-between mb-3 shrink-0">
        <div className="flex flex-col gap-0.5">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              <Zap size={10} strokeWidth={2.4} />
              EXPRESS · 2 PASOS
            </span>
          </CardEyebrow>
          <CardTitle className="text-sm">Transferir</CardTitle>
        </div>
        <button
          type="button"
          onClick={handleNew}
          className="tactile-button-accent-outline tactile-focus-ring h-7 px-3 rounded-md text-[11px] font-semibold uppercase tracking-wider"
        >
          + Nuevo
        </button>
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center text-text-tertiary">
          <Loader2 size={18} className="animate-spin" />
        </div>
      ) : isError ? (
        <div className="text-xs text-semantic-danger-deep py-4">
          No se pudieron cargar destinatarios.
        </div>
      ) : !data || data.recipients.length === 0 ? (
        <div className="text-xs text-text-tertiary py-4">Sin transferencias en 90d.</div>
      ) : (
        <div className="flex-1 min-h-0 overflow-y-auto -mx-1 px-1 space-y-1.5 scrollbar-thin">
          {data.recipients.slice(0, 5).map((r, i) => (
            <CompactRow
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

function CompactRow({
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
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.03, duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
      className={cn(
        'group flex items-center gap-2.5 rounded-lg px-2 py-2',
        'border border-transparent hover:border-border-medium hover:bg-surface-card-elevated/40',
        'transition-colors',
      )}
    >
      <div className="relative shrink-0">
        <div
          className={cn(
            'inline-flex h-8 w-8 items-center justify-center rounded-full',
            'text-[11px] font-semibold tactile-wght-breathing',
          )}
          style={{
            background: 'linear-gradient(135deg, oklch(0.13 0.012 270), oklch(0.18 0.014 270))',
            border: '1px solid var(--color-border-medium)',
          }}
        >
          {initials || '··'}
        </div>
        {recipient.is_favorite && (
          <span
            aria-hidden
            className="absolute -top-0.5 -right-0.5 inline-flex h-3 w-3 items-center justify-center rounded-full text-text-primary"
            style={{ background: 'var(--gradient-primary)' }}
          >
            <Star size={7} strokeWidth={3} fill="currentColor" />
          </span>
        )}
      </div>

      <div className="flex-1 flex flex-col min-w-0 leading-tight">
        <span className="text-xs font-medium text-text-primary tactile-wght-breathing truncate">
          {recipient.alias ?? formatIbanShort(recipient.counterpart_iban)}
        </span>
        <span className="text-[10px] text-text-tertiary tactile-tabular-nums truncate">
          {formatRelativeTime(recipient.last_transfer_ms)} · ×{recipient.transfer_count}
        </span>
      </div>

      <button
        type="button"
        onClick={() => onQuickSend(recipient, presetAmount)}
        aria-label={`Enviar ${formatEur(presetAmount / 100)} a ${recipient.alias ?? recipient.counterpart_iban}`}
        className="tactile-button-accent-outline tactile-focus-ring shrink-0 h-7 px-2.5 rounded-md text-[10px] font-semibold tactile-tabular-nums"
      >
        €{formatEur(presetAmount / 100)}
      </button>
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
