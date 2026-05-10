import { useEffect, useMemo, useState } from 'react'
import { motion, AnimatePresence, useReducedMotion } from 'motion/react'
import { X, Check, AlertTriangle } from 'lucide-react'
import type { BankCardMock } from '@/data/contracts'
import { useI18n } from '@/lib/i18n'
import { useUpdateCardLimits } from '@/data/mutations'
import { resolveCardDesign } from './cardDesigns'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { toast } from '@/stores/toast'
import { handleBankError } from '@/lib/bankError'

/**
 * BANK-FE.4.3 — LimitsModal
 *
 * Centred dialog for editing a card's daily and monthly spending ceilings.
 * Two custom sliders bound to local state preview the change in real time,
 * then commit via `useUpdateCardLimits` on Save.
 *
 * UX rationale:
 *   - The two sliders share a hue (the focused card's accent) so the modal
 *     reads as part of the card's identity, not a generic settings panel.
 *   - We surface a calm validation hint when the user drags monthly below
 *     daily — same rule as the BE mutation guard so the experience is
 *     deterministic when the optimistic update later fails the assertion.
 *   - Esc closes; backdrop click closes; saving while invalid is blocked.
 *
 * Phase 4.3 wires this dialog as a controlled component driven by the
 * `useCardsUi` store (open/close), so opening from CardDetails or any
 * future shortcut surface keeps a single source of truth.
 */
export interface LimitsModalProps {
  card: BankCardMock | null
  open: boolean
  onClose: () => void
}

const STEP_MINOR = 1000 // 10 €
const DAILY_MIN = 0
const DAILY_MAX = 1_000_000 // 10 000 € in minor units (cents)
const MONTHLY_MIN = 0
const MONTHLY_MAX = 10_000_000 // 100 000 €

export function LimitsModal({ card, open, onClose }: LimitsModalProps) {
  const { t, money } = useI18n()
  const reduced = useReducedMotion()
  const mutation = useUpdateCardLimits()

  // Local draft state, hydrated from the card whenever the modal (re)opens.
  const [daily, setDaily] = useState<number>(0)
  const [monthly, setMonthly] = useState<number>(0)

  useEffect(() => {
    if (open && card) {
      setDaily(card.daily_limit_minor)
      setMonthly(card.monthly_limit_minor)
    }
  }, [open, card])

  // Esc closes.
  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        onClose()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open, onClose])

  const design = useMemo(
    () => (card ? resolveCardDesign(card.design_id) : null),
    [card],
  )

  const invalid = monthly < daily
  const dirty = card !== null && (daily !== card.daily_limit_minor || monthly !== card.monthly_limit_minor)
  const formatLimit = (minor: number) => money(minor / 100, { maximumFractionDigits: 0, minimumFractionDigits: 0 })

  const handleSave = () => {
    if (!card || invalid || !dirty) return
    sfx.console_tap()
    mutation.mutate(
      { cardId: card.card_id, daily_limit_minor: daily, monthly_limit_minor: monthly },
      {
        onSuccess: () => {
          toast.success(
            t('cards.limitsUpdated'),
            t('cards.limitsUpdatedDescription').replace('{daily}', formatLimit(daily)).replace('{monthly}', formatLimit(monthly))
          )
          onClose()
        },
        onError: (err) => {
          handleBankError(err)
        },
      },
    )
  }

  const dailyPct = card && card.daily_limit_minor > 0 ? Math.min(100, (card.daily_spent_minor / daily) * 100) : 0
  const monthlyPct = card && card.monthly_limit_minor > 0 ? Math.min(100, (card.monthly_spent_minor / monthly) * 100) : 0

  return (
    <AnimatePresence>
      {open && card && design && (
        <>
          {/* Backdrop */}
          <motion.div
            key="limits-backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: reduced ? 0 : 0.18 }}
            onClick={onClose}
            className="absolute inset-0 z-[var(--z-drawer-scrim)] bg-surface-modal-scrim backdrop-blur-sm"
            aria-hidden
          />

          {/* Panel — centred dialog */}
          <motion.div
            key="limits-panel"
            role="dialog"
            aria-modal="true"
            aria-label={t('cards.editCardLimits')}
            initial={reduced ? { opacity: 0 } : { opacity: 0, y: 12, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduced ? { opacity: 0 } : { opacity: 0, y: 8, scale: 0.97 }}
            transition={
              reduced
                ? { duration: 0.18 }
                : { type: 'spring', stiffness: 320, damping: 30, mass: 0.85 }
            }
            className={cn(
              'absolute left-1/2 top-1/2 z-[var(--z-drawer)]',
              '-translate-x-1/2 -translate-y-1/2',
              'w-[min(440px,calc(100vw-32px))]',
              'rounded-2xl border border-white/10',
              'flex flex-col',
            )}
            style={{
              background: 'linear-gradient(180deg, rgb(2, 3, 6) 0%, rgb(0, 0, 0) 100%)',
              boxShadow:
                '0 24px 64px -16px rgba(0,0,0,0.7), 0 4px 12px -4px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.06)',
            }}
          >
            {/* Header */}
            <div className="flex items-start justify-between gap-3 px-5 pt-5 pb-3">
              <div className="flex flex-col leading-tight min-w-0">
                <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">
                  {t('cards.spendingLimits')}
                </span>
                <h2 className="text-base font-semibold text-text-primary tactile-wght-breathing tracking-tight truncate">
                  {design.name} · ···· {card.pan_last_four}
                </h2>
              </div>
              <button
                type="button"
                onClick={onClose}
                aria-label={t('cards.close')}
                className="inline-flex items-center justify-center h-7 w-7 rounded-full text-text-tertiary hover:text-text-primary hover:bg-white/5 transition-colors"
              >
                <X size={14} strokeWidth={2} />
              </button>
            </div>

            {/* Body */}
            <div className="px-5 pb-3 flex flex-col gap-4">
              <LimitSlider
                label={t('cards.daily')}
                helper={t('cards.dailyHelper').replace('{spent}', formatLimit(card.daily_spent_minor)).replace('{pct}', dailyPct.toFixed(0))}
                value={daily}
                min={DAILY_MIN}
                max={DAILY_MAX}
                step={STEP_MINOR}
                accent={design.accent}
                pct={dailyPct}
                formatValue={formatLimit}
                onChange={setDaily}
              />
              <LimitSlider
                label={t('cards.monthly')}
                helper={t('cards.monthlyHelper').replace('{spent}', formatLimit(card.monthly_spent_minor)).replace('{pct}', monthlyPct.toFixed(0))}
                value={monthly}
                min={MONTHLY_MIN}
                max={MONTHLY_MAX}
                step={STEP_MINOR * 10}
                accent={design.accent}
                pct={monthlyPct}
                formatValue={formatLimit}
                onChange={setMonthly}
                invalid={invalid}
              />

              {invalid && (
                <motion.div
                  initial={{ opacity: 0, y: -4 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="flex items-start gap-2 rounded-lg px-3 py-2 text-[11px] leading-snug"
                  style={{
                    background: 'rgba(144,0,0,0.1)',
                    border: '1px solid rgba(232,90,72,0.3)',
                    color: 'rgb(255, 175, 159)',
                  }}
                >
                  <AlertTriangle size={12} strokeWidth={2} className="shrink-0 mt-0.5" />
                  <span>{t('cards.monthlyBelowDailyError')}</span>
                </motion.div>
              )}
            </div>

            {/* Footer */}
            <div
              className="flex items-center justify-end gap-2 px-5 pt-3 pb-5 border-t"
              style={{ borderColor: 'rgba(255,255,255,0.06)' }}
            >
              <button
                type="button"
                onClick={onClose}
                disabled={mutation.isPending}
                className={cn(
                  'inline-flex items-center justify-center px-3 h-8 rounded-lg text-xs font-semibold',
                  'text-text-secondary hover:text-text-primary hover:bg-white/5',
                  'transition-colors disabled:opacity-50',
                )}
              >
                {t('cards.cancel')}
              </button>
              <button
                type="button"
                onClick={handleSave}
                disabled={!dirty || invalid || mutation.isPending}
                className={cn(
                  'inline-flex items-center gap-1.5 px-3 h-8 rounded-lg text-xs font-semibold',
                  'transition-all duration-180',
                  'disabled:opacity-40 disabled:cursor-not-allowed',
                  'enabled:hover:brightness-110 enabled:active:scale-[0.98]',
                )}
                style={{
                  background: !dirty || invalid ? 'rgba(255,255,255,0.06)' : design.accent,
                  color: !dirty || invalid ? 'rgb(180, 183, 191)' : 'rgb(2, 3, 6)',
                  border: '1px solid rgba(255,255,255,0.1)',
                  boxShadow: !dirty || invalid ? 'none' : `0 0 18px -4px ${design.accent}`,
                }}
              >
                <Check size={12} strokeWidth={2.4} />
                {mutation.isPending ? t('cards.saving') : t('cards.save')}
              </button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}

/* --------------------------------------------------------------------------
   LimitSlider — single slider row with label, value, helper, accent track.

   Implementation notes:
     - Native <input type="range"> for keyboard + touch correctness.
     - We paint the filled portion of the track via a CSS gradient computed
       from the current value, so the bar visually inherits the card accent.
     - The thumb is styled via WebKit + standard pseudo-elements through a
       scoped <style> tag — Tailwind cannot target ::-webkit-slider-thumb.
   -------------------------------------------------------------------------- */
function LimitSlider({
  label,
  helper,
  value,
  min,
  max,
  step,
  accent,
  pct,
  formatValue,
  onChange,
  invalid = false,
}: {
  label: string
  helper: string
  value: number
  min: number
  max: number
  step: number
  accent: string
  pct: number
  formatValue: (minor: number) => string
  onChange: (v: number) => void
  invalid?: boolean
}) {
  const { t } = useI18n()
  const fillPct = max > min ? ((value - min) / (max - min)) * 100 : 0
  const sliderId = `slider-${label.toLowerCase()}`
  const usagePct = Math.min(100, Math.max(0, pct))

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-baseline justify-between gap-2">
        <label htmlFor={sliderId} className="text-xs font-semibold text-text-primary tracking-tight">
          {label}
        </label>
        <span
          className={cn(
            'text-sm font-mono font-semibold tactile-tabular-nums',
            invalid ? 'text-[rgb(255, 175, 159)]' : 'text-text-primary',
          )}
          style={{ fontVariantNumeric: 'tabular-nums' }}
        >
          {formatValue(value)}
        </span>
      </div>

      <div className="relative">
        <input
          id={sliderId}
          type="range"
          min={min}
          max={max}
          step={step}
          value={value}
          onChange={(e) => onChange(Number(e.target.value))}
          className="sonar-slider w-full"
          style={
            {
              '--slider-fill': `${fillPct}%`,
              '--slider-accent': accent,
            } as React.CSSProperties
          }
          aria-valuetext={formatValue(value)}
        />
      </div>

      <div className="flex items-center justify-between gap-2">
        <span className="text-[10px] text-text-tertiary leading-snug truncate">
          {helper}
        </span>
        {usagePct > 80 && (
          <span
            className="text-[9px] uppercase tracking-[0.16em] font-semibold px-1.5 py-0.5 rounded"
            style={{
              color: accent,
              background: 'rgba(255,255,255,0.04)',
              border: `1px solid ${accent}`,
            }}
          >
            {t('cards.nearLimit')}
          </span>
        )}
      </div>
    </div>
  )
}
