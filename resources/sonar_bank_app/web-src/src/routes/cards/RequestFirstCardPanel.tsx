import { useRef, useState, type KeyboardEvent, type ChangeEvent } from 'react'
import { motion } from 'motion/react'
import { ShieldCheck, CreditCard, Lock, CreditCard as CardIcon } from 'lucide-react'
import { useIssueCard } from '@/data/mutations'
import { useBootstrap, useCards } from '@/data/queries'
import { useI18n } from '@/lib/i18n'
import { maskIbanCompact } from '@/lib/privacy'
import { usePrivacyMode } from '@/stores/privacy'
import { handleBankError } from '@/lib/bankError'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'

const PIN_LENGTH = 4
const MAX_CARDS = 3
const CARD_TYPES = ['debit', 'virtual'] as const
type CardType = (typeof CARD_TYPES)[number]

export function RequestFirstCardPanel() {
  const { t } = useI18n()
  const { data: bootstrap } = useBootstrap()
  const { cards } = useCards()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const { mutateAsync: issueCard, isPending } = useIssueCard()

  const primaryIban = bootstrap?.accounts?.[0]?.iban ?? ''

  const [digits, setDigits] = useState<string[]>(Array(PIN_LENGTH).fill(''))
  const [cardType, setCardType] = useState<CardType>('debit')
  const [error, setError] = useState<string | null>(null)
  const inputRefs = useRef<(HTMLInputElement | null)[]>([])

  const pin = digits.join('')
  const pinReady = pin.length === PIN_LENGTH && /^\d{4}$/.test(pin)

  function focusNext(index: number) {
    const next = inputRefs.current[index + 1]
    if (next) next.focus()
  }

  function focusPrev(index: number) {
    const prev = inputRefs.current[index - 1]
    if (prev) prev.focus()
  }

  function handleChange(index: number, e: ChangeEvent<HTMLInputElement>) {
    const val = e.target.value.replace(/\D/g, '').slice(-1)
    const next = [...digits]
    next[index] = val
    setDigits(next)
    setError(null)
    if (val) focusNext(index)
  }

  function handleKeyDown(index: number, e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === 'Backspace' && !digits[index]) {
      focusPrev(index)
    }
  }

  function handlePaste(e: React.ClipboardEvent<HTMLInputElement>) {
    e.preventDefault()
    const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, PIN_LENGTH)
    if (pasted.length > 0) {
      const next = Array(PIN_LENGTH).fill('')
      for (let i = 0; i < pasted.length; i++) next[i] = pasted[i]
      setDigits(next)
      const focusIdx = Math.min(pasted.length, PIN_LENGTH - 1)
      inputRefs.current[focusIdx]?.focus()
    }
  }

  async function handleActivate() {
    if (!pinReady) {
      setError(t('cards.activate.pinLength'))
      return
    }
    if (!primaryIban) return
    if (cards.length >= MAX_CARDS) {
      setError(t('cards.maxCardsBody'))
      return
    }
    sfx.depth_press()
    try {
      await issueCard({ account_iban: primaryIban, pin, card_type: cardType })
      sfx.coin_clink()
    } catch (err) {
      handleBankError(err)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.38, ease: [0.16, 1, 0.3, 1] }}
      className="w-full max-w-[400px] mx-auto flex flex-col gap-5"
    >
      {/* ── Card placeholder ── */}
      <div className="relative mx-auto w-full max-w-[320px] aspect-[1.586/1] rounded-2xl overflow-hidden select-none"
        style={{
          background: 'linear-gradient(135deg, oklch(0.14 0.04 40) 0%, oklch(0.08 0.02 250) 60%, oklch(0.06 0.015 260) 100%)',
          boxShadow: '0 28px 56px -20px oklch(0.65 0.22 40 / 0.45), 0 8px 24px -8px rgba(0,0,0,0.7)',
          border: '1px solid rgba(255,255,255,0.1)',
        }}
      >
        <div className="absolute inset-0 pointer-events-none"
          style={{
            background: 'radial-gradient(circle at 20% 20%, oklch(0.65 0.22 40 / 0.22) 0%, transparent 55%), radial-gradient(circle at 80% 80%, rgba(255,255,255,0.06) 0%, transparent 40%)',
          }}
        />
        {/* Chip placeholder */}
        <div className="absolute top-5 left-5 w-9 h-6 rounded-md"
          style={{
            background: 'linear-gradient(135deg, rgba(255,255,255,0.18), rgba(255,255,255,0.08))',
            border: '1px solid rgba(255,255,255,0.18)',
          }}
        />
        {/* SONAR logotype */}
        <div className="absolute top-5 right-5 flex items-center gap-1.5 opacity-60">
          <CreditCard size={14} className="text-white" strokeWidth={1.5} />
          <span className="text-[10px] font-bold tracking-[0.2em] text-white uppercase">Sonar</span>
        </div>
        {/* Masked number placeholder */}
        <div className="absolute bottom-10 left-5 text-xs font-mono tracking-[0.22em] text-white/40">
          ···· ···· ···· ····
        </div>
        {/* Cardholder placeholder */}
        <div className="absolute bottom-4 left-5 text-[10px] tracking-[0.14em] text-white/30 uppercase">
          {'SONAR BANK'}
        </div>
        {/* Lock badge */}
        <div className="absolute bottom-4 right-5 flex items-center gap-1 opacity-40">
          <Lock size={10} className="text-white" />
          <span className="text-[9px] font-semibold tracking-wider text-white">SONAR</span>
        </div>
      </div>

      {/* ── Form surface ── */}
      <div
        className="rounded-2xl px-5 py-5 flex flex-col gap-4 overflow-visible"
        style={{
          background: 'linear-gradient(160deg, rgba(30,8,3,0.72), rgba(4,5,14,0.68))',
          border: '1px solid rgba(255,255,255,0.08)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.07)',
        }}
      >
        {/* Header */}
        <div className="flex flex-col gap-0.5">
          <span className="text-[9px] uppercase tracking-[0.22em] font-semibold"
            style={{ color: 'oklch(0.65 0.22 40)' }}>
            {t('cards.activate.eyebrow')}
          </span>
          <h2 className="text-base font-bold text-white leading-snug tracking-tight">
            {t('cards.activate.title')}
          </h2>
          <p className="text-xs text-white/50 leading-relaxed mt-0.5">
            {t('cards.activate.subtitle')}
          </p>
        </div>

        {/* Card type selector */}
        <div className="flex flex-col gap-2">
          <label className="text-[10px] uppercase tracking-[0.16em] font-semibold text-white/50">
            {t('cards.activate.typeLabel')}
          </label>
          <div className="grid grid-cols-2 gap-2">
            {CARD_TYPES.map((type) => (
              <button
                key={type}
                type="button"
                onClick={() => { setCardType(type); setError(null) }}
                disabled={isPending}
                className={cn(
                  'p-3 rounded-xl text-left transition-all duration-150',
                  'flex flex-col gap-1.5',
                  cardType === type
                    ? 'border-2 oklch(0.65 0.22 40 / 0.6) bg-oklch(0.65 0.22 40 / 0.12)'
                    : 'border border-white/10 bg-white/5 hover:bg-white/8',
                  isPending && 'opacity-50 cursor-not-allowed'
                )}
              >
                <div className="flex items-center gap-2">
                  <CardIcon size={14} className={cn(
                    cardType === type ? 'text-white' : 'text-white/40'
                  )} />
                  <span className="text-xs font-semibold text-white">
                    {t(type === 'debit' ? 'cards.activate.typeDebit' : 'cards.activate.typeVirtual')}
                  </span>
                </div>
                <span className="text-[10px] text-white/50 leading-tight">
                  {t(type === 'debit' ? 'cards.activate.typeDebitDesc' : 'cards.activate.typeVirtualDesc')}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* PIN input */}
        <div className="flex flex-col gap-2">
          <label className="text-[10px] uppercase tracking-[0.16em] font-semibold text-white/50">
            {t('cards.activate.pinLabel')}
          </label>
          <div className="flex gap-2.5 justify-start">
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
                  'w-11 h-12 rounded-xl text-center text-lg font-bold caret-transparent',
                  'transition-all duration-150 outline-none',
                  digits[i]
                    ? 'text-white'
                    : 'text-white/20',
                )}
                style={{
                  background: digits[i]
                    ? 'rgba(255,255,255,0.1)'
                    : 'rgba(255,255,255,0.05)',
                  border: digits[i]
                    ? '1px solid oklch(0.65 0.22 40 / 0.6)'
                    : '1px solid rgba(255,255,255,0.1)',
                  boxShadow: digits[i]
                    ? 'inset 0 1px 0 rgba(255,255,255,0.08), 0 0 0 2px oklch(0.65 0.22 40 / 0.12)'
                    : 'inset 0 1px 0 rgba(255,255,255,0.04)',
                }}
              />
            ))}
          </div>
          {error && (
            <motion.p
              initial={{ opacity: 0, y: -4 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-[11px] font-medium"
              style={{ color: 'oklch(0.7 0.22 25)' }}
            >
              {error}
            </motion.p>
          )}
        </div>

        {/* CTA */}
        <button
          type="button"
          onClick={handleActivate}
          disabled={!pinReady || isPending || !primaryIban}
          className={cn(
            'w-full py-3 rounded-xl text-sm font-bold tracking-wide transition-all duration-180',
            'flex items-center justify-center gap-2',
            (!pinReady || isPending || !primaryIban)
              ? 'opacity-70 cursor-not-allowed'
              : 'hover:-translate-y-0.5 active:scale-[0.98]',
          )}
          style={{
            background: (!pinReady || isPending)
              ? 'rgba(255,255,255,0.12)'
              : 'var(--gradient-primary)',
            color: (!pinReady || isPending) ? 'rgba(255,255,255,0.7)' : 'var(--text-primary)',
            boxShadow: (!pinReady || isPending) ? 'none' : '0 10px 28px -14px oklch(0.65 0.22 40 / 0.7)',
          }}
        >
          <ShieldCheck size={14} strokeWidth={2} />
          {isPending ? t('cards.activate.ctaLoading') : t('cards.activate.cta')}
        </button>

        {/* IBAN info */}
        {primaryIban && (
          <p className="text-[10px] text-white/30 text-center leading-relaxed">
            {t('cards.activate.linkedTo')}{' '}
            <span className="font-mono text-white/50">
              {streamerMode ? maskIbanCompact(primaryIban) : primaryIban}
            </span>
          </p>
        )}
      </div>
    </motion.div>
  )
}
