import { useState } from 'react'
import { motion } from 'motion/react'
import { Lock, Wallet, CalendarDays, User2, Sparkles, Snowflake, Settings2, Eye, RotateCw, Check, Loader2 } from 'lucide-react'
import type { BankCardMock } from '@/data/contracts'
import { Button, Card, Input } from '@/components/ui'
import { cn } from '@/lib/utils'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { sfx } from '@/lib/sfx'
import { toast } from '@/stores/toast'
import { handleBankError } from '@/lib/bankError'
import { maskIbanCompact, maskMoneyDisplay, revealIbanDisplay } from '@/lib/privacy'
import { usePrivacyMode } from '@/stores/privacy'
import { resolveCardDesign } from './cardDesigns'
import { useCardsUi, useCardReveal } from '@/stores/cardsUi'
import { useChangeCardPinMutation, useFreezeCard } from '@/data/mutations'

/**
 * BANK-FE.4.2 â€” CardDetails
 *
 * Right column of the /tarjetas route. Shows the focused card's metadata
 * (holder, expiry, linked IBAN, design) plus a calm preview of the daily and
 * monthly spending meters.
 *
 * Action buttons (Freeze, Limits, Reveal CVV, View transactions) are wired
 * here as DISABLED placeholders so the layout already accommodates them in
 * Phase 4.3. We keep them visible (not hidden) so the founder can review the
 * final visual rhythm during Phase 4.2 sign-off.
 *
 * The Reveal + Flip controls are wired NOW because they have no contract
 * dependency â€” they manipulate UI state only.
 */
export interface CardDetailsProps {
  card: BankCardMock | null
  className?: string
}

export function CardDetails({ card, className }: CardDetailsProps) {
  const { t } = useI18n()
  const flippedIds = useCardsUi((s) => s.flippedCardIds)
  const toggleFlip = useCardsUi((s) => s.toggleFlip)
  const openDialog = useCardsUi((s) => s.openDialog)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const setStreamerMode = usePrivacyMode((s) => s.setStreamerMode)
  const cardId = card?.card_id ?? '__none__'
  const { revealed, reveal, hide } = useCardReveal(cardId)
  const freezeMutation = useFreezeCard()
  const changePinMutation = useChangeCardPinMutation()
  const [pinDialogOpen, setPinDialogOpen] = useState(false)
  const [oldPin, setOldPin] = useState('')
  const [newPin, setNewPin] = useState('')

  if (!card) {
    return (
      <Card variant="glass" padding="md" className={cn('border-white/10 flex flex-col items-center justify-center text-center', className)}>
        <Sparkles size={20} className="text-text-tertiary mb-2" strokeWidth={1.6} />
        <p className="text-sm font-semibold text-text-primary mb-1">{t('cards.selectCardTitle')}</p>
        <p className="text-xs text-text-tertiary max-w-[28ch]">
          {t('cards.selectCardDescription')}
        </p>
      </Card>
    )
  }

  const design = resolveCardDesign(card.design_id)

  const isLocked = card.status === 'locked'
  const isExpired = card.status === 'expired'
  const freezePending = freezeMutation.isPending

  const flipped = flippedIds.includes(card.card_id)
  const effectiveRevealed = !streamerMode && (revealed || Boolean(card.full_pan))

  const handleToggleReveal = () => {
    if (effectiveRevealed) {
      hide()
      setStreamerMode(true)
      sfx.console_tap()
      toast.info(t('cards.streamerModeOnTitle'), t('cards.streamerModeOnBody'))
    } else {
      if (streamerMode) {
        setStreamerMode(false)
        toast.warning(t('cards.streamerModeOffTitle'), t('cards.streamerModeOffBody'))
      }
      reveal()
      sfx.panel_open()
    }
  }

  const handleToggleFreeze = () => {
    if (isExpired) return
    const freeze = !isLocked
    sfx.console_tap()
    freezeMutation.mutate(
      { cardId: card.card_id, freeze },
      {
        onSuccess: () => {
          toast.success(
            freeze ? t('cards.cardFrozenTitle') : t('cards.cardUnfrozenTitle'),
            freeze
              ? t('cards.cardFrozenBody')
              : t('cards.cardUnfrozenBody'),
          )
        },
        onError: (err) => {
          handleBankError(err)
        },
      },
    )
  }

  const handleChangePin = async () => {
    try {
      await changePinMutation.mutateAsync({ card_id: card.card_id, old_pin: oldPin, new_pin: newPin })
      setOldPin('')
      setNewPin('')
      setPinDialogOpen(false)
      toast.success(t('cards.pinUpdatedTitle'), t('cards.pinUpdatedBody'))
    } catch (err) {
      handleBankError(err)
    }
  }

  const expiry = new Date(card.expiry_ms)
  const expiryStr = `${String(expiry.getMonth() + 1).padStart(2, '0')}/${expiry.getFullYear()}`

  const dailyPct = card.daily_limit_minor > 0
    ? Math.min(100, (card.daily_spent_minor / card.daily_limit_minor) * 100)
    : 0
  const monthlyPct = card.monthly_limit_minor > 0
    ? Math.min(100, (card.monthly_spent_minor / card.monthly_limit_minor) * 100)
    : 0

  return (
    <Card
      variant="glass"
      padding="none"
      className={cn('relative overflow-hidden border-white/10 rounded-[1.75rem] flex flex-col', className)}
    >
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background: `radial-gradient(circle at 82% 0%, ${withAlpha(design.accent, 0.2)}, transparent 34%), linear-gradient(180deg, rgba(255,255,255,0.04), transparent 56%)`,
        }}
      />
      <div className="relative flex h-full min-h-0 flex-col gap-3 p-4 2xl:gap-4 2xl:p-5">
        <motion.div
          key={card.card_id}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.22 }}
          className="rounded-[1.35rem] border p-3.5 2xl:p-4"
          style={{
            background: 'rgba(255,255,255,0.04)',
            borderColor: 'rgba(255,255,255,0.08)',
            boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.06)',
          }}
        >
          <div className="flex items-start justify-between gap-3">
            <div className="flex min-w-0 flex-col gap-2">
              <div className="inline-flex items-center gap-2">
                <span
                  aria-hidden
                  className="h-2 w-2 rounded-full"
                  style={{
                    background: design.accent,
                    boxShadow: `0 0 14px -2px ${design.accent}`,
                  }}
                />
                <span className="text-[10px] uppercase tracking-[0.2em] text-text-tertiary font-semibold">
                  {t('cards.activeDesign')}
                </span>
              </div>
              <div className="flex min-w-0 flex-col gap-1">
                <span className="text-2xl 2xl:text-3xl font-light tracking-[-0.055em] text-text-primary truncate">
                  {design.name}
                </span>
                <span className="text-[11px] text-text-tertiary truncate">
                  {design.tagline} Â· Â·Â·Â·Â· {card.pan_last_four}
                </span>
              </div>
            </div>
            <StatusPill status={card.status} t={t} />
          </div>
        </motion.div>

      {/* Meta grid â€” holder Â· expiry Â· linked iban Â· type */}
        <dl className="grid grid-cols-2 gap-2.5">
          <MetaItem icon={User2} label={t('cards.holder')} value={card.holder_name} accent={design.accent} />
          <MetaItem icon={CalendarDays} label={t('cards.expires')} value={expiryStr} accent={design.accent} mono />
          <MetaItem icon={Wallet} label={t('cards.linked')} value={streamerMode ? maskIbanCompact(card.iban) : revealIbanDisplay(card.iban)} accent={design.accent} mono />
          <MetaItem
            icon={Sparkles}
            label={t('cards.type')}
            value={typeLabel(card.card_type, t)}
            accent={design.accent}
          />
        </dl>

      {/* Limits preview â€” soft meters; full controls land in 4.3 */}
        <div
          className="rounded-[1.35rem] p-3.5 flex flex-col gap-3 2xl:p-4"
          style={{
            background: 'rgba(255,255,255,0.04)',
            border: '1px solid rgba(255,255,255,0.08)',
            boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.05)',
          }}
        >
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-semibold">
              {t('cards.limits')}
            </span>
            <span className="rounded-full border border-white/10 bg-white/[0.04] px-2 py-0.5 text-[10px] text-text-tertiary">
              {t('cards.safeView')}
            </span>
          </div>

          <Meter
            label={t('common.today')}
            spent={card.daily_spent_minor}
            limit={card.daily_limit_minor}
            pct={dailyPct}
            accent={design.accent}
            hidden={streamerMode}
          />
          <Meter
            label={t('cards.thisMonth')}
            spent={card.monthly_spent_minor}
            limit={card.monthly_limit_minor}
            pct={monthlyPct}
            accent={design.accent}
            hidden={streamerMode}
          />
        </div>

      {/* Benefits â€” tier-driven perks bring brand storytelling into the panel
          and naturally absorb any leftover vertical real-estate. */}
        <BenefitsPanel tier={design.tier} accent={design.accent} />

      {/* Action row â€” Phase 4.3: all four actions are now LIVE.
          Reveal toggles a 30s window with countdown surfaced inline.
          Freeze/Unfreeze fires the optimistic mutation + toast feedback.
          LÃ­mites + DiseÃ±o open dialogs (LimitsModal / DesignPickerDialog). */}
        <div className="mt-auto flex flex-col gap-2">
          <div className="grid grid-cols-2 gap-2">
            <ActionButton
              icon={Eye}
              label={
                effectiveRevealed
                  ? t('cards.activateStreamer')
                  : streamerMode ? t('cards.pauseStreamer') : t('cards.hideNumber')
              }
              onClick={handleToggleReveal}
              active={effectiveRevealed}
            />
            <ActionButton
              icon={RotateCw}
              label={flipped ? t('cards.showFront') : t('cards.showBack')}
              onClick={() => toggleFlip(card.card_id)}
              active={flipped}
            />
            <ActionButton
              icon={freezePending ? Loader2 : Snowflake}
              iconClassName={freezePending ? 'animate-spin' : undefined}
              label={isLocked ? t('cards.unfreeze') : t('cards.freeze')}
              onClick={handleToggleFreeze}
              disabled={isExpired || freezePending}
              active={isLocked}
            />
            <ActionButton
              icon={Settings2}
              label={t('cards.limits')}
              onClick={() => {
                sfx.panel_open()
                openDialog('limits', card.card_id)
              }}
              disabled={isExpired}
            />
          </div>
          <ActionButton
            icon={Lock}
            label={t('cards.changePin')}
            onClick={() => {
              sfx.panel_open()
              setPinDialogOpen(true)
            }}
            disabled={isExpired || changePinMutation.isPending}
            fullWidth
          />
        </div>
      </div>
      {pinDialogOpen ? (
        <ChangePinDialog
          oldPin={oldPin}
          newPin={newPin}
          loading={changePinMutation.isPending}
          onChangeOldPin={setOldPin}
          onChangeNewPin={setNewPin}
          onSubmit={handleChangePin}
          onClose={() => setPinDialogOpen(false)}
        />
      ) : null}
    </Card>
  )
}

function ChangePinDialog({ oldPin, newPin, loading, onChangeOldPin, onChangeNewPin, onSubmit, onClose }: { oldPin: string; newPin: string; loading: boolean; onChangeOldPin: (value: string) => void; onChangeNewPin: (value: string) => void; onSubmit: () => void; onClose: () => void }) {
  const { t } = useI18n()
  return (
    <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/72 px-4 backdrop-blur-md">
      <div className="w-full max-w-sm rounded-[1.5rem] border border-white/10 bg-surface-panel p-4 shadow-2xl">
        <div className="mb-4 flex items-center justify-between gap-3">
          <h2 className="text-base font-semibold text-text-primary">{t('cards.changePin')}</h2>
          <Button size="sm" variant="ghost" onClick={onClose}>{t('cards.close')}</Button>
        </div>
        <div className="grid gap-3">
          <Input label={t('cards.currentPin')} type="password" inputMode="numeric" maxLength={8} value={oldPin} onChange={(event) => onChangeOldPin(event.currentTarget.value)} />
          <Input label={t('cards.newPin')} type="password" inputMode="numeric" maxLength={8} value={newPin} onChange={(event) => onChangeNewPin(event.currentTarget.value)} />
          <Button loading={loading} disabled={!/^\d{4,8}$/.test(oldPin) || !/^\d{4,8}$/.test(newPin)} onClick={onSubmit}>{t('cards.updatePin')}</Button>
        </div>
      </div>
    </div>
  )
}
/* --------------------------------------------------------------------------
   BenefitsPanel â€” tier-aware perk list driven by design.tier.
   - default   â†’ 3 baseline perks
   - premium   â†’ +1 cashback / +1 priority support
   - signature â†’ premium set + concierge / early access
   The accent colour ties the check marks to the focused card's chromatic
   identity so the panel reads as part of the same visual story.
   -------------------------------------------------------------------------- */

function useBenefitsByTier(t: (key: TranslationKey) => string): Record<'default' | 'premium' | 'signature', string[]> {
  return {
    default: [
      t('cards.benefitNoMaintenance'),
      t('cards.benefitContactless'),
      t('cards.benefitRealtime'),
    ],
    premium: [
      t('cards.benefitCashback05'),
      t('cards.benefitPriority247'),
      t('cards.benefitNoMaintenance'),
      t('cards.benefitContactless'),
    ],
    signature: [
      t('cards.benefitCashback1'),
      t('cards.benefitConcierge'),
      t('cards.benefitEarlyAccess'),
      t('cards.benefitPriority247'),
      t('cards.benefitNoMaintenance'),
    ],
  }
}

function BenefitsPanel({
  tier,
  accent,
  className,
}: {
  tier: 'default' | 'premium' | 'signature'
  accent: string
  className?: string
}) {
  const { t } = useI18n()
  const benefitsMap = useBenefitsByTier(t)
  const items = benefitsMap[tier]
  return (
    <div
      className={cn(
        'rounded-[1.35rem] p-3.5 flex flex-col gap-3 overflow-hidden 2xl:p-4',
        className,
      )}
      style={{
        background: 'rgba(255,255,255,0.04)',
        border: '1px solid rgba(255,255,255,0.08)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.05)',
      }}
    >
      <div className="flex items-center justify-between shrink-0">
        <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-semibold">
          {t('cards.benefits')}
        </span>
        <TierBadge tier={tier} />
      </div>
      <ul className="grid gap-1.5 min-h-0 overflow-y-auto" role="list">
        {items.map((label) => (
          <li
            key={label}
            className="flex items-start gap-2 rounded-xl border border-white/[0.055] bg-white/[0.025] px-2.5 py-2 text-[11px] leading-snug text-text-secondary"
          >
            <Check
              size={11}
              strokeWidth={2.4}
              className="shrink-0 mt-0.5"
              style={{ color: accent, opacity: 0.85 }}
            />
            <span className="truncate">{label}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}

function TierBadge({ tier }: { tier: 'default' | 'premium' | 'signature' }) {
  const { t } = useI18n()
  const label = tier === 'signature' ? t('cards.signature') : tier === 'premium' ? t('cards.premium') : t('cards.standard')
  return (
    <span
      className="text-[9px] uppercase tracking-[0.16em] font-semibold px-1.5 py-0.5 rounded"
      style={{
        color: 'rgb(180, 183, 191)',
        background: 'rgba(255,255,255,0.05)',
        border: '1px solid rgba(255,255,255,0.1)',
      }}
    >
      {label}
    </span>
  )
}

/* --------------------------------------------------------------------------
   Sub-components
   -------------------------------------------------------------------------- */

function StatusPill({ status, t }: { status: BankCardMock['status']; t: (key: TranslationKey) => string }) {
  const config = useStatusConfig(t)[status]
  const Icon = config.icon
  return (
    <span
      className="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-[10px] uppercase tracking-[0.14em] font-semibold shrink-0"
      style={{
        color: config.color,
        background: 'rgba(255,255,255,0.04)',
        border: `1px solid ${config.borderColor}`,
      }}
    >
      {Icon && <Icon size={10} strokeWidth={2.4} />}
      {config.label}
    </span>
  )
}

function useStatusConfig(t: (key: TranslationKey) => string): Record<BankCardMock['status'], { label: string; color: string; borderColor: string; icon: typeof Lock | null }> {
  return {
    active: { label: t('cards.statusActive'), color: 'rgb(134, 231, 156)', borderColor: 'rgba(134,231,156,0.25)', icon: null },
    locked: { label: t('cards.statusFrozen'), color: 'rgb(110, 195, 235)', borderColor: 'rgba(110,195,235,0.25)', icon: Lock },
    expired: { label: t('cards.statusExpired'), color: 'rgb(141, 143, 149)', borderColor: 'rgba(141,143,149,0.2)', icon: null },
    pending: { label: t('cards.statusPending'), color: 'rgb(225, 172, 110)', borderColor: 'rgba(225,172,110,0.25)', icon: null },
  }
}

function MetaItem({
  icon: Icon,
  label,
  value,
  accent,
  mono = false,
}: {
  icon: typeof User2
  label: string
  value: string
  accent: string
  mono?: boolean
}) {
  return (
    <div
      className="flex min-w-0 flex-col gap-1.5 rounded-[1.1rem] border p-3"
      style={{
        background: 'rgba(255,255,255,0.03)',
        borderColor: 'rgba(255,255,255,0.07)',
      }}
    >
      <div className="inline-flex items-center gap-1.5">
        <Icon size={10} strokeWidth={1.8} style={{ color: accent, opacity: 0.75 }} />
        <span className="text-[9px] uppercase tracking-[0.16em] text-text-tertiary font-semibold">
          {label}
        </span>
      </div>
      <span
        className={cn(
          'text-xs font-semibold text-text-primary truncate',
          mono && 'font-mono tracking-wide tactile-tabular-nums',
        )}
        style={mono ? { fontVariantNumeric: 'tabular-nums' } : undefined}
      >
        {value}
      </span>
    </div>
  )
}

function Meter({
  label,
  spent,
  limit,
  pct,
  accent,
  hidden,
}: {
  label: string
  spent: number
  limit: number
  pct: number
  accent: string
  hidden: boolean
}) {
  const { money } = useI18n()
  const isAlarm = pct > 80
  // Use an alpha-derived entry stop in the same hue family. The
  // bar therefore always speaks the focused card's chromatic language; the
  // alarm state adds an accent halo + brighter mix instead of swapping hue.
  const softStop = withAlpha(accent, 0.55)
  return (
    <div className="flex flex-col gap-2 rounded-xl border border-white/[0.055] bg-black/[0.10] px-2.5 py-2">
      <div className="flex items-baseline justify-between gap-2">
        <span className="text-[10px] uppercase tracking-[0.14em] text-text-tertiary font-medium">
          {label}
        </span>
        <span
          className="text-[10px] text-text-secondary tactile-tabular-nums"
          style={{ fontVariantNumeric: 'tabular-nums' }}
        >
          {hidden ? `${maskMoneyDisplay()} / ${maskMoneyDisplay()}` : `${money(spent / 100, { maximumFractionDigits: 0, minimumFractionDigits: 0 })} / ${money(limit / 100, { maximumFractionDigits: 0, minimumFractionDigits: 0 })}`}
        </span>
      </div>
      <div
        className="h-1.5 w-full rounded-full overflow-hidden"
        style={{ background: 'rgba(255,255,255,0.06)' }}
      >
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${pct}%` }}
          transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
          className="h-full rounded-full"
          style={{
            background: `linear-gradient(90deg, ${softStop} 0%, ${accent} 100%)`,
            boxShadow: isAlarm
              ? `0 0 8px ${accent}, 0 0 2px ${accent}`
              : 'none',
          }}
        />
      </div>
    </div>
  )
}

function ActionButton({
  icon: Icon,
  iconClassName,
  label,
  onClick,
  disabled = false,
  active = false,
  fullWidth = false,
}: {
  icon: typeof Eye
  iconClassName?: string
  label: string
  onClick?: () => void
  disabled?: boolean
  active?: boolean
  fullWidth?: boolean
}) {
  const { t } = useI18n()
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={cn(
        'inline-flex h-9 items-center gap-2 rounded-xl px-3',
        'text-xs font-semibold transition-all duration-180',
        fullWidth ? 'w-full justify-center' : '',
        disabled
          ? 'cursor-not-allowed opacity-40'
          : 'hover:bg-surface-card-elevated active:scale-[0.98]',
        active && !disabled && 'tactile-wght-breathing',
      )}
      style={{
        background: active ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.03)',
        border: `1px solid ${active ? 'rgba(255,255,255,0.16)' : 'rgba(255,255,255,0.07)'}`,
        color: active ? 'rgb(242, 242, 242)' : 'rgb(180, 183, 191)',
      }}
      title={disabled && !onClick ? t('cards.comingSoon') : undefined}
    >
      <Icon size={12} strokeWidth={1.8} className={cn('shrink-0', iconClassName)} />
      <span className="truncate">{label}</span>
    </button>
  )
}

/* --------------------------------------------------------------------------
   Helpers
   -------------------------------------------------------------------------- */

function typeLabel(cardType: BankCardMock['card_type'], t: (key: TranslationKey) => string): string {
  return cardType === 'premium' || cardType === 'credit' ? t('cards.premium') : t('cards.classic')
}

function withAlpha(color: string, alpha: number): string {
  const rgb = color.match(/^rgb\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\)$/)
  if (rgb) return `rgba(${rgb[1]}, ${rgb[2]}, ${rgb[3]}, ${alpha})`

  const rgba = color.match(/^rgba\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*[0-9.]+\s*\)$/)
  if (rgba) return `rgba(${rgba[1]}, ${rgba[2]}, ${rgba[3]}, ${alpha})`

  return color
}
