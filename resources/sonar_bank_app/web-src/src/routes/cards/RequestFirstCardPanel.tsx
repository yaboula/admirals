import { useEffect, useRef, useState, type KeyboardEvent, type ChangeEvent } from 'react'
import { motion, useMotionValue, useSpring, useTransform, useReducedMotion, useAnimation } from 'motion/react'
import { Check, CreditCard, Lock, ShieldCheck, Sparkles, WalletCards, X, ArrowRight, ArrowDown, Layers3 } from 'lucide-react'
import { useIssueCard } from '@/data/mutations'
import { useBootstrap, useCards } from '@/data/queries'
import { useI18n } from '@/lib/i18n'
import { maskIbanCompact } from '@/lib/privacy'
import { usePrivacyMode } from '@/stores/privacy'
import { handleBankError } from '@/lib/bankError'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { getCardDesignsForProductTier, resolveCardDesign, type CardProductTier } from './cardDesigns'
import { CARD_PRODUCT_LIMITS, CARD_TYPES, MAX_CARDS } from './cardProducts'
import { Motif, withAlpha } from './CardVisual'

const PIN_LENGTH = 4
const BRAND_ORANGE = 'rgb(246, 75, 0)'
const BRAND_ORANGE_LIGHT = 'rgb(255, 147, 42)'

export interface RequestCardPanelProps {
  isInitial?: boolean
  onClose?: () => void
}

export function RequestFirstCardPanel({ isInitial = true, onClose }: RequestCardPanelProps = {}) {
  const { t, money } = useI18n()
  const reduced = useReducedMotion()
  const { data: bootstrap } = useBootstrap()
  const { cards } = useCards()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const { mutateAsync: issueCard, isPending } = useIssueCard()
  const errorAnim = useAnimation()

  const primaryAccount = bootstrap?.accounts?.[0]
  const primaryIban = primaryAccount?.iban ?? ''

  const [digits, setDigits] = useState<string[]>(Array(PIN_LENGTH).fill(''))
  const [cardType, setCardType] = useState<CardProductTier>('classic')
  const [designId, setDesignId] = useState<string>('sonar_signature')
  const [error, setError] = useState<string | null>(null)
  const inputRefs = useRef<(HTMLInputElement | null)[]>([])

  const pin = digits.join('')
  const pinReady = pin.length === PIN_LENGTH && /^\d{4}$/.test(pin)
  const allowedDesigns = getCardDesignsForProductTier(cardType)
  const selectedDesign = resolveCardDesign(designId)
  const productLimits = CARD_PRODUCT_LIMITS[cardType]
  const availableMinor = Number(primaryAccount?.balance_minor ?? 0)
  const remainingAfterMinor = availableMinor - productLimits.issue_fee_minor
  const canAffordIssue = availableMinor >= productLimits.issue_fee_minor
  const atCardLimit = cards.length >= MAX_CARDS
  const canSubmit = pinReady && !isPending && Boolean(primaryIban) && canAffordIssue && !atCardLimit

  useEffect(() => {
    if (!allowedDesigns.some((design) => design.id === designId)) {
      setDesignId(allowedDesigns[0]?.id ?? 'noir')
    }
  }, [allowedDesigns, designId])

  function focusNext(index: number) { inputRefs.current[index + 1]?.focus() }
  function focusPrev(index: number) { inputRefs.current[index - 1]?.focus() }

  function handleChange(index: number, e: ChangeEvent<HTMLInputElement>) {
    const val = e.target.value.replace(/\D/g, '').slice(-1)
    const next = [...digits]
    next[index] = val
    setDigits(next)
    setError(null)
    if (val) focusNext(index)
  }

  function handleKeyDown(index: number, e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === 'Backspace' && !digits[index]) focusPrev(index)
  }

  function handlePaste(e: React.ClipboardEvent<HTMLInputElement>) {
    e.preventDefault()
    const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, PIN_LENGTH)
    if (pasted.length > 0) {
      const next = Array(PIN_LENGTH).fill('')
      for (let i = 0; i < pasted.length; i++) next[i] = pasted[i]
      setDigits(next)
      inputRefs.current[Math.min(pasted.length, PIN_LENGTH - 1)]?.focus()
    }
  }

  function flagError(message: string) {
    setError(message)
    if (!reduced) {
      errorAnim.start({ x: [0, -6, 6, -4, 4, -2, 2, 0], transition: { duration: 0.36 } })
    }
  }

  async function handleActivate() {
    if (!pinReady) return flagError(t('cards.activate.pinLength'))
    if (!canAffordIssue) return flagError(t('cards.activate.insufficientFee').replace('{amount}', money(productLimits.issue_fee_minor / 100)))
    if (atCardLimit) return flagError(t('cards.maxCardsBody'))
    if (!primaryIban) return
    sfx.depth_press()
    try {
      await issueCard({
        account_iban: primaryIban,
        pin,
        card_type: cardType,
        design_id: designId,
        spend_limit_minor: productLimits.daily_limit_minor,
      })
      sfx.coin_clink()
    } catch (err) {
      handleBankError(err)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
      className="w-full mx-auto"
    >
      <div
        role={onClose ? 'dialog' : undefined}
        aria-modal={onClose ? true : undefined}
        className={cn(
          'relative overflow-hidden rounded-[1.65rem] border',
          'bg-[var(--color-surface-card)]',
          'shadow-[inset_0_1px_0_rgba(255,255,255,0.05),0_36px_90px_-50px_rgba(0,0,0,0.95),0_0_0_1px_var(--color-border-brand-subtle)]',
        )}
        style={{ borderColor: 'var(--color-border-subtle)' }}
      >
        {/* Brand orange aura — anchors the panel to the SONAR identity (ADR-017) */}
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{ background: 'var(--gradient-orange-aura-strong)', opacity: 0.55 }}
        />
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{
            background:
              'radial-gradient(circle at 96% 0%, rgba(246,75,0,0.10), transparent 38%)',
          }}
        />

        <div className="relative grid gap-0 lg:grid-cols-[minmax(0,1.1fr)_minmax(380px,1fr)]">
          {/* ── HERO COLUMN ─────────────────────────────────────────── */}
          <section
            className="relative flex flex-col gap-4 border-b p-5 lg:border-b-0 lg:border-r lg:p-6"
            style={{ borderColor: 'var(--color-border-subtle)' }}
          >
            <header className="flex items-start justify-between gap-3">
              <div>
                <div
                  className="mb-2.5 inline-flex items-center gap-2 rounded-full border px-3 py-1.5"
                  style={{
                    borderColor: 'var(--color-border-brand-subtle)',
                    background: 'var(--color-brand-signal-orange-subtle)',
                  }}
                >
                  <WalletCards size={13} strokeWidth={2} style={{ color: BRAND_ORANGE_LIGHT }} />
                  <span
                    className="text-[9.5px] font-semibold uppercase tracking-[0.2em]"
                    style={{ color: BRAND_ORANGE_LIGHT }}
                  >
                    {t('cards.activate.eyebrow')}
                  </span>
                </div>
                <h2 className="text-[22px] font-semibold leading-[1.05] tracking-[-0.045em] text-text-primary">
                  {isInitial ? t('cards.activate.title') : t('cards.activate.additionalTitle')}
                </h2>
              </div>
              {onClose ? (
                <button
                  type="button"
                  onClick={onClose}
                  aria-label={t('cards.close')}
                  className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full border text-text-tertiary transition-colors hover:text-text-primary"
                  style={{
                    borderColor: 'var(--color-border-subtle)',
                    background: 'rgba(0,0,0,0.45)',
                  }}
                >
                  <X size={15} strokeWidth={2} />
                </button>
              ) : null}
            </header>

            {/* Card stage */}
            <div className="relative">
              <div
                aria-hidden
                className="absolute inset-0 rounded-[1.5rem]"
                style={{
                  background:
                    'radial-gradient(ellipse 80% 80% at 50% 38%, rgba(246,75,0,0.08), rgba(0,0,0,0.5) 70%)',
                  boxShadow: 'inset 0 0 0 1px var(--color-border-subtle)',
                }}
              />
              <motion.div
                aria-hidden
                className="pointer-events-none absolute inset-0 rounded-[1.5rem]"
                animate={{
                  background: [
                    `radial-gradient(circle at 50% 50%, ${withAlpha(selectedDesign.accent, 0.22)}, transparent 56%)`,
                    `radial-gradient(circle at 50% 50%, ${withAlpha(selectedDesign.accent, 0.32)}, transparent 60%)`,
                    `radial-gradient(circle at 50% 50%, ${withAlpha(selectedDesign.accent, 0.22)}, transparent 56%)`,
                  ],
                }}
                transition={{ duration: 5.5, repeat: Infinity, ease: 'easeInOut' }}
              />
              <div className="relative flex flex-col items-center gap-2.5 px-2 py-5 sm:py-6">
                <TiltPreview reduced={!!reduced}>
                  <div
                    className="relative aspect-[1.586/1] w-full max-w-[400px] select-none overflow-hidden rounded-[1.4rem]"
                    style={{
                      background: selectedDesign.surface,
                      border: `1px solid ${withAlpha(selectedDesign.accent, 0.35)}`,
                      boxShadow: `0 32px 80px -34px ${selectedDesign.accent}, 0 22px 56px -28px rgba(0,0,0,0.92), inset 0 1px 0 rgba(255,255,255,0.08)`,
                    }}
                  >
                    {selectedDesign.overlay ? <div className="absolute inset-0" style={{ background: selectedDesign.overlay }} /> : null}
                    <Motif motif={selectedDesign.motif} accent={selectedDesign.accent} />
                    <div className="absolute inset-0 bg-[linear-gradient(115deg,rgba(255,255,255,0.16),transparent_30%,transparent_64%,rgba(255,255,255,0.07))]" />
                    <div
                      className="absolute left-5 top-5 h-8 w-11 rounded-lg border border-white/[0.18]"
                      style={{ background: 'linear-gradient(135deg,rgba(255,255,255,0.24),rgba(255,255,255,0.06))' }}
                    />
                    <div
                      className="absolute right-5 top-5 flex items-center gap-1.5"
                      style={{ color: selectedDesign.textPrimary, opacity: 0.82 }}
                    >
                      <CreditCard size={16} strokeWidth={1.6} />
                      <span className="text-[10.5px] font-bold uppercase tracking-[0.24em]">SONAR</span>
                    </div>
                    <div
                      className="absolute bottom-[4.4rem] left-5 font-mono text-[15px] tracking-[0.28em]"
                      style={{ color: withAlpha(selectedDesign.textPrimary, 0.82) }}
                    >
                      ···· ···· ···· {pinReady ? pin : '••••'}
                    </div>
                    <div className="absolute bottom-5 left-5">
                      <div className="text-[9px] uppercase tracking-[0.22em]" style={{ color: selectedDesign.textTertiary }}>
                        {t('cards.activate.cardholderPreview')}
                      </div>
                      <div
                        className="mt-1 text-[11.5px] font-semibold uppercase tracking-[0.14em]"
                        style={{ color: selectedDesign.textPrimary }}
                      >
                        {cardType === 'premium' ? 'SONAR PREMIUM' : 'SONAR CLASSIC'}
                      </div>
                    </div>
                    <div
                      className="absolute bottom-5 right-5 inline-flex items-center gap-1.5 rounded-full border border-white/[0.16] bg-black/30 px-2.5 py-1 text-[9px] font-semibold uppercase tracking-[0.18em]"
                      style={{ color: withAlpha(selectedDesign.textPrimary, 0.7) }}
                    >
                      <Lock size={10} />
                      {pinReady ? t('cards.activate.pinReady') : 'PIN'}
                    </div>
                  </div>
                </TiltPreview>
                <div className="flex flex-col items-center gap-0.5 pt-0.5 text-center">
                  <span
                    className="text-[10px] font-semibold uppercase tracking-[0.2em]"
                    style={{ color: selectedDesign.tier === 'signature' ? BRAND_ORANGE_LIGHT : 'var(--color-text-tertiary)' }}
                  >
                    {selectedDesign.tier === 'signature'
                      ? t('cards.designSignatureTier')
                      : selectedDesign.tier === 'premium'
                        ? t('cards.designPremiumTier')
                        : t('cards.designClassicTier')}
                  </span>
                  <span className="text-[13px] font-semibold tracking-[-0.02em] text-text-primary">
                    {selectedDesign.name}
                  </span>
                </div>
              </div>
            </div>

            <CostBlock
              payToday={money(productLimits.issue_fee_minor / 100)}
              balanceBefore={money(availableMinor / 100)}
              balanceAfter={money(remainingAfterMinor / 100)}
              canAfford={canAffordIssue}
              labelPay={t('cards.activate.payTodayLabel')}
              labelFromTo={t('cards.activate.balanceTransition')}
              labelInsufficient={t('cards.activate.insufficientShort')}
            />

            <div className="grid grid-cols-2 gap-2.5">
              <InfoRow
                icon={<Layers3 size={13} className="text-text-tertiary" strokeWidth={2} />}
                label={t('cards.activate.dailyLimitShort')}
                value={money(productLimits.daily_limit_minor / 100, { maximumFractionDigits: 0, minimumFractionDigits: 0 })}
              />
              <InfoRow
                icon={<WalletCards size={13} className="text-text-tertiary" strokeWidth={2} />}
                label={t('cards.activate.cardsUsedShort')}
                value={`${cards.length}/${MAX_CARDS}`}
                muted={atCardLimit}
              />
            </div>

            {primaryIban ? (
              <div
                className="flex items-center justify-between rounded-[0.95rem] border px-3 py-2"
                style={{
                  borderColor: 'var(--color-border-subtle)',
                  background: 'rgba(0,0,0,0.35)',
                }}
              >
                <span className="text-[10px] font-semibold uppercase tracking-[0.18em] text-text-tertiary">
                  {t('cards.activate.linkedTo')}
                </span>
                <span className="font-mono text-[11.5px] text-text-secondary">
                  {streamerMode ? maskIbanCompact(primaryIban) : primaryIban}
                </span>
              </div>
            ) : null}
          </section>

          {/* ── FLOW COLUMN ─────────────────────────────────────────── */}
          <section className="flex flex-col gap-4 p-5 lg:p-6">
            <Step number="01" label={t('cards.activate.typeLabel')} value={cardType === 'premium' ? t('cards.activate.typePremium') : t('cards.activate.typeClassic')}>
              <div className="grid grid-cols-2 gap-2.5">
                {CARD_TYPES.map((type) => {
                  const selected = cardType === type
                  return (
                    <button
                      key={type}
                      type="button"
                      onClick={() => { setCardType(type); setError(null) }}
                      disabled={isPending}
                      className={cn(
                        'group relative overflow-hidden rounded-[1.05rem] border p-3.5 text-left transition-all duration-160',
                        isPending && 'cursor-not-allowed opacity-50',
                      )}
                      style={
                        selected
                          ? {
                              borderColor: 'var(--color-border-brand-strong)',
                              background:
                                'linear-gradient(135deg, rgba(246,75,0,0.16), rgba(246,75,0,0.04))',
                              boxShadow: '0 0 0 1px var(--color-border-brand-subtle), 0 18px 36px -22px rgba(246,75,0,0.5)',
                            }
                          : {
                              borderColor: 'var(--color-border-subtle)',
                              background: 'rgba(0,0,0,0.4)',
                            }
                      }
                    >
                      <div className="mb-2 flex items-center justify-between gap-2">
                        <span className="text-[14px] font-semibold tracking-[-0.02em] text-text-primary">
                          {t(type === 'classic' ? 'cards.activate.typeClassic' : 'cards.activate.typePremium')}
                        </span>
                        <span
                          className="inline-flex h-5 w-5 items-center justify-center rounded-full border"
                          style={
                            selected
                              ? {
                                  borderColor: 'var(--color-border-brand-strong)',
                                  background: 'var(--gradient-primary)',
                                  color: 'var(--color-text-primary)',
                                }
                              : {
                                  borderColor: 'var(--color-border-subtle)',
                                  color: 'var(--color-text-quaternary)',
                                }
                          }
                        >
                          {selected ? <Check size={12} strokeWidth={2.6} /> : null}
                        </span>
                      </div>
                      <p className="min-h-[2.4rem] text-[11px] leading-relaxed text-text-tertiary">
                        {t(type === 'classic' ? 'cards.activate.typeClassicDesc' : 'cards.activate.typePremiumDesc')}
                      </p>
                      <div className="mt-2 flex items-baseline justify-between gap-2">
                        <span className="text-[9.5px] font-semibold uppercase tracking-[0.16em] text-text-tertiary">
                          {t('cards.activate.issueFeeShort')}
                        </span>
                        <span
                          className="text-[12px] font-semibold tactile-tabular-nums"
                          style={{ color: selected ? BRAND_ORANGE_LIGHT : 'var(--color-text-secondary)' }}
                        >
                          {money(CARD_PRODUCT_LIMITS[type].issue_fee_minor / 100)}
                        </span>
                      </div>
                    </button>
                  )
                })}
              </div>
            </Step>

            <Step number="02" label={t('cards.activate.designLabel')} value={selectedDesign.name}>
              <div className="grid grid-cols-4 gap-2 sm:grid-cols-7">
                {allowedDesigns.map((design) => {
                  const selected = designId === design.id
                  return (
                    <button
                      key={design.id}
                      type="button"
                      onClick={() => { setDesignId(design.id); setError(null) }}
                      disabled={isPending}
                      aria-label={design.name}
                      title={design.name}
                      className={cn(
                        'relative aspect-[1.586/1] overflow-hidden rounded-[0.8rem] border transition-all duration-180',
                        isPending && 'cursor-not-allowed opacity-50',
                      )}
                      style={
                        selected
                          ? {
                              transform: 'scale(1.06)',
                              borderColor: BRAND_ORANGE,
                              boxShadow: '0 0 0 1px var(--color-border-brand-strong), 0 10px 24px -14px rgba(246,75,0,0.7)',
                              background: design.surface,
                            }
                          : {
                              borderColor: 'var(--color-border-subtle)',
                              background: design.surface,
                            }
                      }
                    >
                      {design.overlay ? <div className="absolute inset-0" style={{ background: design.overlay }} /> : null}
                      <div className="absolute inset-0 bg-[linear-gradient(115deg,rgba(255,255,255,0.13),transparent_45%,rgba(0,0,0,0.2))]" />
                      {selected ? (
                        <span
                          className="absolute right-1 top-1 inline-flex h-4 w-4 items-center justify-center rounded-full"
                          style={{ background: 'var(--gradient-primary)', color: 'var(--color-text-primary)' }}
                        >
                          <Check size={10} strokeWidth={3} />
                        </span>
                      ) : null}
                    </button>
                  )
                })}
              </div>
              <p className="mt-2 text-[10.5px] leading-relaxed text-text-tertiary">
                {cardType === 'premium' ? t('cards.activate.premiumTerms') : t('cards.activate.classicTerms')}
              </p>
            </Step>

            <Step number="03" label={t('cards.activate.pinLabel')} value={pinReady ? t('cards.activate.pinReady') : t('cards.activate.pinPending')}>
              <motion.div
                animate={errorAnim}
                className="rounded-[1.1rem] border p-3.5"
                style={{
                  borderColor: pinReady ? 'var(--color-border-brand-subtle)' : 'var(--color-border-subtle)',
                  background: pinReady
                    ? 'linear-gradient(135deg, rgba(246,75,0,0.08), rgba(0,0,0,0.5))'
                    : 'rgba(0,0,0,0.45)',
                  boxShadow: pinReady ? '0 0 0 1px var(--color-border-brand-subtle), 0 0 24px -8px rgba(246,75,0,0.45)' : 'none',
                }}
              >
                <div className="mb-2.5 flex items-center justify-between gap-3 text-[10.5px] font-semibold uppercase tracking-[0.16em] text-text-tertiary">
                  <span>{t('cards.activate.pinHint')}</span>
                  <ShieldCheck
                    size={15}
                    strokeWidth={2}
                    style={{ color: pinReady ? BRAND_ORANGE_LIGHT : 'var(--color-text-quaternary)' }}
                  />
                </div>
                <div className="flex justify-center gap-2.5">
                  {Array.from({ length: PIN_LENGTH }).map((_, i) => (
                    <input
                      key={i}
                      ref={(el) => { inputRefs.current[i] = el }}
                      type="password"
                      inputMode="numeric"
                      pattern="[0-9]"
                      maxLength={1}
                      value={digits[i]}
                      onChange={(e) => handleChange(i, e)}
                      onKeyDown={(e) => handleKeyDown(i, e)}
                      onPaste={i === 0 ? handlePaste : undefined}
                      aria-label={t('cards.activate.pinAriaDigit').replace('{n}', String(i + 1))}
                      disabled={isPending}
                      className={cn(
                        'rounded-[0.95rem] border text-center text-[19px] font-bold text-text-primary outline-none transition-all duration-180',
                        'focus:scale-[1.04]',
                        'disabled:cursor-not-allowed disabled:opacity-50',
                      )}
                      style={{
                        height: '48px',
                        width: '48px',
                        borderColor: pinReady
                          ? 'var(--color-border-brand-strong)'
                          : digits[i]
                            ? 'var(--color-border-medium)'
                            : 'var(--color-border-subtle)',
                        background: digits[i] ? 'rgba(246,75,0,0.06)' : 'rgba(0,0,0,0.55)',
                        boxShadow: pinReady
                          ? '0 0 0 1px var(--color-border-brand-strong), 0 0 18px -2px rgba(246,75,0,0.5)'
                          : digits[i]
                            ? 'inset 0 1px 0 rgba(255,255,255,0.05)'
                            : 'inset 0 1px 0 rgba(255,255,255,0.03)',
                      }}
                    />
                  ))}
                </div>
                {error ? (
                  <motion.p
                    initial={{ opacity: 0, y: -4 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="mt-2.5 text-center text-[11.5px] font-medium"
                    style={{ color: 'rgb(234, 60, 63)' }}
                  >
                    {error}
                  </motion.p>
                ) : null}
              </motion.div>
            </Step>

            <div className="mt-auto space-y-2">
              <button
                type="button"
                onClick={handleActivate}
                disabled={!canSubmit}
                className={cn(
                  'group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-[1rem] px-5 py-3 text-[14px] font-bold tracking-[-0.01em] transition-all duration-200',
                  canSubmit ? 'hover:-translate-y-0.5 active:scale-[0.985]' : 'cursor-not-allowed opacity-70',
                )}
                style={{
                  background: canSubmit ? 'var(--gradient-primary)' : 'rgba(0,0,0,0.55)',
                  color: canSubmit ? 'var(--color-text-primary)' : 'var(--color-text-tertiary)',
                  border: '1px solid',
                  borderColor: canSubmit ? 'var(--color-border-brand-strong)' : 'var(--color-border-subtle)',
                  boxShadow: canSubmit ? '0 18px 40px -22px rgba(246,75,0,0.78), inset 0 1px 0 rgba(255,255,255,0.18)' : 'none',
                }}
              >
                {canSubmit && !reduced ? (
                  <span aria-hidden className="absolute inset-0 -translate-x-full bg-[linear-gradient(115deg,transparent_30%,rgba(255,255,255,0.22)_50%,transparent_70%)] transition-transform duration-700 group-hover:translate-x-full" />
                ) : null}
                {isPending ? (
                  <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                ) : (
                  <Sparkles size={15} strokeWidth={2} />
                )}
                <span className="relative">
                  {isPending
                    ? t('cards.activate.ctaLoading')
                    : `${t('cards.activate.cta')} · ${money(productLimits.issue_fee_minor / 100)}`}
                </span>
                {!isPending && canSubmit ? <ArrowRight size={14} strokeWidth={2.2} className="relative" /> : null}
              </button>
              {!canSubmit && !isPending ? (
                <p className="text-center text-[10.5px] leading-relaxed text-text-quaternary">
                  {atCardLimit
                    ? t('cards.maxCardsBody')
                    : !canAffordIssue
                      ? t('cards.activate.insufficientFee').replace('{amount}', money(productLimits.issue_fee_minor / 100))
                      : !pinReady
                        ? t('cards.activate.ctaWaitingPin')
                        : ''}
                </p>
              ) : null}
            </div>
          </section>
        </div>
      </div>
    </motion.div>
  )
}

function Step({ number, label, value, children }: { number: string; label: string; value?: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-baseline justify-between gap-3">
        <div className="flex items-baseline gap-2.5">
          <span
            className="text-[10px] font-bold tracking-[0.18em]"
            style={{ color: BRAND_ORANGE_LIGHT, opacity: 0.85 }}
          >
            {number}
          </span>
          <span className="text-[11px] font-semibold uppercase tracking-[0.16em] text-text-secondary">{label}</span>
        </div>
        {value ? <span className="truncate text-[11px] font-medium text-text-tertiary">{value}</span> : null}
      </div>
      {children}
    </div>
  )
}

function CostBlock({
  payToday,
  balanceBefore,
  balanceAfter,
  canAfford,
  labelPay,
  labelFromTo,
  labelInsufficient,
}: {
  payToday: string
  balanceBefore: string
  balanceAfter: string
  canAfford: boolean
  labelPay: string
  labelFromTo: string
  labelInsufficient: string
}) {
  return (
    <div
      className="relative overflow-hidden rounded-[1.1rem] border p-4"
      style={
        canAfford
          ? {
              borderColor: 'var(--color-border-brand-subtle)',
              background:
                'linear-gradient(135deg, rgba(246,75,0,0.10), rgba(246,75,0,0.02) 60%, rgba(0,0,0,0.55))',
              boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04)',
            }
          : {
              borderColor: 'rgba(234,60,63,0.4)',
              background: 'linear-gradient(135deg, rgba(234,60,63,0.18), rgba(0,0,0,0.5))',
            }
      }
    >
      <div className="flex items-baseline justify-between gap-3">
        <span className="text-[10px] font-semibold uppercase tracking-[0.18em] text-text-secondary">
          {labelPay}
        </span>
        {!canAfford ? (
          <span
            className="rounded-full px-2 py-0.5 text-[9.5px] font-semibold uppercase tracking-[0.14em]"
            style={{ background: 'rgba(234,60,63,0.18)', color: 'rgb(234,120,123)' }}
          >
            {labelInsufficient}
          </span>
        ) : null}
      </div>
      <div
        className="mt-1.5 text-[26px] font-bold leading-none tracking-[-0.04em] tactile-tabular-nums"
        style={{ color: canAfford ? BRAND_ORANGE_LIGHT : 'rgb(234,120,123)' }}
      >
        {payToday}
      </div>
      <div className="mt-2.5 flex items-center gap-2 text-[11px] tactile-tabular-nums">
        <span className="text-text-tertiary">{labelFromTo}</span>
        <span className="font-medium text-text-secondary">{balanceBefore}</span>
        <ArrowDown size={12} className="-rotate-90 text-text-quaternary" strokeWidth={2.2} />
        <span
          className="font-semibold"
          style={{ color: canAfford ? 'var(--color-text-primary)' : 'rgb(234,120,123)' }}
        >
          {balanceAfter}
        </span>
      </div>
    </div>
  )
}

function InfoRow({ icon, label, value, muted = false }: { icon: React.ReactNode; label: string; value: string; muted?: boolean }) {
  return (
    <div
      className={cn('flex items-center justify-between gap-3 rounded-[0.95rem] border px-3 py-2', muted && 'opacity-70')}
      style={{
        borderColor: 'var(--color-border-subtle)',
        background: 'rgba(0,0,0,0.35)',
      }}
    >
      <div className="flex items-center gap-2">
        {icon}
        <span className="text-[10px] font-semibold uppercase tracking-[0.16em] text-text-tertiary">{label}</span>
      </div>
      <span
        className={cn('text-[12px] font-semibold tactile-tabular-nums', muted ? 'text-text-tertiary' : 'text-text-primary')}
      >
        {value}
      </span>
    </div>
  )
}

function TiltPreview({ reduced, children }: { reduced: boolean; children: React.ReactNode }) {
  const x = useMotionValue(0)
  const y = useMotionValue(0)
  const rx = useSpring(useTransform(y, [-1, 1], [9, -9]), { stiffness: 220, damping: 22 })
  const ry = useSpring(useTransform(x, [-1, 1], [-11, 11]), { stiffness: 220, damping: 22 })

  function handleMove(e: React.MouseEvent<HTMLDivElement>) {
    if (reduced) return
    const rect = e.currentTarget.getBoundingClientRect()
    const nx = ((e.clientX - rect.left) / rect.width) * 2 - 1
    const ny = ((e.clientY - rect.top) / rect.height) * 2 - 1
    x.set(nx)
    y.set(ny)
  }

  function handleLeave() {
    x.set(0)
    y.set(0)
  }

  return (
    <div
      className="relative flex w-full items-center justify-center"
      style={{ perspective: 1200 }}
      onMouseMove={handleMove}
      onMouseLeave={handleLeave}
    >
      <motion.div
        style={reduced ? undefined : { rotateX: rx, rotateY: ry, transformStyle: 'preserve-3d' }}
        className="relative w-full will-change-transform flex justify-center"
      >
        {children}
      </motion.div>
    </div>
  )
}
