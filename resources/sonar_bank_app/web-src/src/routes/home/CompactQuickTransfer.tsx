import { useNavigate } from 'react-router-dom'
import { motion } from 'motion/react'
import { Star, Zap, Loader2, UserPlus, Users2 } from 'lucide-react'
import { Card, CardEyebrow, CardTitle } from '@/components/ui'
import { useRecentRecipients } from '@/data/queries'
import type { RecentRecipient } from '@/data/contracts'
import { sfx } from '@/lib/sfx'
import { useTransferWizard } from '@/stores/transferWizard'
import { toast } from '@/stores/toast'
import { cn } from '@/lib/utils'
import { useI18n } from '@/lib/i18n'
import { maskMoneyDisplay, revealIbanDisplay } from '@/lib/privacy'
import { usePrivacyMode } from '@/stores/privacy'
import { getMockInitialsForIban } from '@/data/mock/seed'

/**
 * Right-rail compact recipients list. Designed to fill remaining vertical
 * space below the credit-card visual without scrolling on 800-748px viewports.
 *
 * Express CTA uses ghost/outline styling — orange ONLY appears on hover.
 */
export function CompactQuickTransfer() {
  const { t, money } = useI18n()
  const navigate = useNavigate()
  const { data, isLoading, isError } = useRecentRecipients()
  const initWizard = useTransferWizard((s) => s.init)
  const setRecipient = useTransferWizard((s) => s.setRecipient)
  const setAmount = useTransferWizard((s) => s.setAmount)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  const handleQuickSend = (r: RecentRecipient, amount: number): void => {
    initWizard(true)
    setRecipient(r.counterpart_iban, r.alias)
    setAmount(amount, r.last_reason ?? '')
    sfx.coin_clink()
    toast.info(
      t('transfer.sentToastTitle'),
      `${streamerMode ? maskMoneyDisplay() : money(amount / 100)} → ${streamerMode ? t('transfer.hiddenRecipient') : r.alias ?? revealIbanDisplay(r.counterpart_iban)}`,
    )
    navigate('/transferir')
  }

  const handleNew = (): void => {
    initWizard(false)
    sfx.depth_press()
    navigate('/transferir')
  }

  return (
    <Card
      variant="glass"
      padding="md"
      className="relative overflow-hidden flex flex-col h-full min-h-0 border-white/10"
    >
      <div className="flex items-end justify-between mb-3 shrink-0">
        <div className="flex flex-col gap-0.5">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              <Zap size={10} strokeWidth={2.4} />
              {t('home.quickSend')}
            </span>
          </CardEyebrow>
          <CardTitle className="text-sm">{t('home.frequentContacts')}</CardTitle>
        </div>
        <button
          type="button"
          onClick={handleNew}
          className="tactile-button-accent-outline tactile-focus-ring h-7 px-3 rounded-md text-[11px] font-semibold uppercase tracking-wider"
        >
          + {t('home.new')}
        </button>
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center text-text-tertiary">
          <Loader2 size={18} className="animate-spin" />
        </div>
      ) : isError ? (
        <RecipientsEmptyState
          variant="error"
          onAction={handleNew}
        />
      ) : !data || data.recipients.length === 0 ? (
        <RecipientsEmptyState
          variant="empty"
          onAction={handleNew}
        />
      ) : (
        <div className="flex-1 min-h-0 overflow-y-auto -mx-1 px-1 space-y-1.5 scrollbar-thin">
          {data.recipients.slice(0, 4).map((r, i) => (
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
  const { t, money, relativeTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const displayLabel = streamerMode
    ? t('transfer.hiddenRecipient')
    : recipient.alias ?? revealIbanDisplay(recipient.counterpart_iban)
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
            background: 'linear-gradient(135deg, rgb(6, 7, 12), rgb(15, 17, 24))',
            border: '1px solid var(--color-border-medium)',
          }}
        >
          {initials || '··'}
        </div>
        {recipient.is_favorite && (
          <span
            aria-hidden
            className="absolute -top-0.5 -right-0.5 inline-flex h-3 w-3 items-center justify-center rounded-full text-text-primary"
            style={{
              background: 'rgba(255,255,255,0.12)',
              border: '1px solid rgba(255,255,255,0.18)',
            }}
          >
            <Star size={7} strokeWidth={3} fill="currentColor" />
          </span>
        )}
      </div>

      <div className="flex-1 flex flex-col min-w-0 leading-tight">
        <span className="text-xs font-medium text-text-primary tactile-wght-breathing truncate">
          {displayLabel}
        </span>
        <span className="text-[10px] text-text-tertiary tactile-tabular-nums truncate">
          {relativeTime(recipient.last_transfer_ms)} · ×{recipient.transfer_count}
        </span>
      </div>

      <button
        type="button"
        onClick={() => onQuickSend(recipient, presetAmount)}
        aria-label={`Enviar ${streamerMode ? t('transfer.hiddenAmount') : money(presetAmount / 100)} a ${streamerMode ? t('transfer.hiddenRecipient') : recipient.alias ?? t('transfer.hiddenRecipient')}`}
        className="tactile-button-accent-outline tactile-focus-ring shrink-0 h-7 px-2.5 rounded-md text-[10px] font-semibold tactile-tabular-nums"
      >
        {streamerMode ? maskMoneyDisplay() : money(presetAmount / 100)}
      </button>
    </motion.div>
  )
}

function RecipientsEmptyState({
  variant,
  onAction,
}: {
  variant: 'empty' | 'error'
  onAction: () => void
}) {
  const { t } = useI18n()
  const isError = variant === 'error'
  return (
    <div className="flex-1 flex flex-col items-center justify-center text-center gap-2 px-4 py-6">
      <div
        className="inline-flex h-10 w-10 items-center justify-center rounded-full"
        style={{
          background: isError ? 'rgba(252,88,85,0.08)' : 'rgba(255,255,255,0.04)',
          border: `1px solid ${
            isError ? 'rgba(252,88,85,0.3)' : 'var(--color-border-subtle)'
          }`,
          color: isError ? 'rgb(252, 88, 85)' : 'rgba(111,113,121,0.7)',
        }}
        aria-hidden
      >
        <Users2 size={18} strokeWidth={1.7} />
      </div>
      <div className="flex flex-col gap-0.5">
        <span className="text-sm font-medium text-text-secondary">
          {isError ? t('home.noConnection') : t('home.noActivity')}
        </span>
        <span className="text-[11px] text-text-tertiary leading-snug max-w-[22ch]">
          {isError
            ? t('home.recipientsLoadError')
            : t('home.noQuickTransfers')}
        </span>
      </div>
      <button
        type="button"
        onClick={onAction}
        className="mt-1 inline-flex items-center gap-1 text-[11px] font-semibold uppercase tracking-wider text-brand-signal-orange-light hover:text-text-primary transition-colors"
      >
        <UserPlus size={11} strokeWidth={2.4} />
        {isError ? t('home.retry') : t('home.addRecipient')}
      </button>
    </div>
  )
}
