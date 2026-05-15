import { useEffect, useMemo } from 'react'
import { motion, useReducedMotion } from 'motion/react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import type { BankCardMock } from '@/data/contracts'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { useCardsUi } from '@/stores/cardsUi'
import { usePrivacyMode } from '@/stores/privacy'
import { useI18n } from '@/lib/i18n'
import { CardFlip } from './CardFlip'

/**
 * BANK-FE.4.2 — CardCarousel
 *
 * Renders the cards as a 3D stack with the focused card centered and the
 * neighbouring cards peeking from behind, rotated and dimmed.
 *
 * Visual design (centre → outer):
 *     index   x-offset    y-offset   rotateY    rotateZ    scale     opacity   blur
 *      0      0           0          0          0          1.00      1.00      0
 *     ±1     ±56%        +12px      ∓18°       ∓6°         0.86      0.55      4px
 *     ±2     ±90%        +20px      ∓28°       ∓10°        0.74      0.22      8px
 *
 * Anything beyond ±2 is clipped (hidden) so the DOM stays minimal.
 *
 * Interaction:
 *   - Click prev / next button → step ±1
 *   - Click a background card → focus that card (calls setSelected)
 *   - Keyboard ArrowLeft / ArrowRight on the carousel → step ±1
 *   - Drag the focused card horizontally with > 80px commit → step ±1
 *
 * Reduced motion: layout offsets remain (otherwise neighbours collapse onto
 * the focused card) but the spring is replaced with `tween` 180ms.
 */
export interface CardCarouselProps {
  cards: BankCardMock[]
  className?: string
}

const TRANSITION_SPRING = { type: 'spring' as const, stiffness: 220, damping: 26, mass: 1.05 }
const TRANSITION_TWEEN = { type: 'tween' as const, duration: 0.18, ease: [0.32, 0.72, 0, 1] as const }

export function CardCarousel({ cards, className }: CardCarouselProps) {
  const { t } = useI18n()
  const reduced = useReducedMotion()
  const selectedCardId = useCardsUi((s) => s.selectedCardId)
  const flippedIds = useCardsUi((s) => s.flippedCardIds)
  const revealedUntil = useCardsUi((s) => s.revealedUntil)
  const setSelected = useCardsUi((s) => s.setSelected)
  const toggleFlip = useCardsUi((s) => s.toggleFlip)
  const revealCard = useCardsUi((s) => s.revealCard)
  const hideReveal = useCardsUi((s) => s.hideReveal)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const setStreamerMode = usePrivacyMode((s) => s.setStreamerMode)
  const now = Date.now()

  // Resolve the focused card index. Default = 0 (first active card per
  // useCards sort). Falls back gracefully when selectedCardId points to a
  // card that no longer exists (e.g. removed mid-session).
  const focusedIndex = useMemo(() => {
    if (cards.length === 0) return 0
    if (!selectedCardId) return 0
    const idx = cards.findIndex((c) => c.card_id === selectedCardId)
    return idx >= 0 ? idx : 0
  }, [cards, selectedCardId])

  // Initialise the store with the first card on first render so downstream
  // consumers (right column / mini-list) can rely on a non-null id.
  useEffect(() => {
    if (!selectedCardId && cards.length > 0 && cards[0]) {
      setSelected(cards[0].card_id)
    }
  }, [cards, selectedCardId, setSelected])

  const step = (delta: number) => {
    if (cards.length === 0) return
    const next = focusedIndex + delta
    if (next < 0 || next >= cards.length) return
    const target = cards[next]
    if (!target) return
    setSelected(target.card_id)
    sfx.console_tap()
  }

  const transition = reduced ? TRANSITION_TWEEN : TRANSITION_SPRING

  if (cards.length === 0) {
    return <CarouselEmpty className={className} />
  }

  return (
    <div
      className={cn('relative w-full flex flex-col items-center select-none', className)}
      role="region"
      aria-label={t('cards.carouselAriaLabel')}
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === 'ArrowLeft') {
          e.preventDefault()
          step(-1)
        } else if (e.key === 'ArrowRight') {
          e.preventDefault()
          step(1)
        }
      }}
    >
      {/* Stage — fixed aspect window so the absolutely-positioned cards have
          a deterministic layout box. Width is bounded by the parent column. */}
      <div
        className="relative w-full mx-auto"
        style={{ perspective: '1800px' }}
      >
        <div className="relative w-full" style={{ aspectRatio: '1.586 / 1' }}>
          {cards.map((card, i) => {
            const offset = i - focusedIndex
            // Hide any card beyond ±2 from the focus
            const hidden = Math.abs(offset) > 2
            if (hidden) return null

            const isFocused = offset === 0
            const sign = Math.sign(offset)
            const dist = Math.abs(offset)

            const xPercent = sign * (dist === 1 ? 56 : 90)
            const yPx = dist === 0 ? 0 : dist === 1 ? 12 : 20
            const rotateY = -sign * (dist === 1 ? 18 : 28)
            const rotateZ = -sign * (dist === 1 ? 6 : 10)
            const scale = dist === 0 ? 1 : dist === 1 ? 0.86 : 0.74
            const opacity = dist === 0 ? 1 : dist === 1 ? 0.55 : 0.22
            const blurPx = dist === 0 ? 0 : dist === 1 ? 4 : 8
            const z = 30 - dist // focused on top

            return (
              <motion.div
                key={card.card_id}
                className="absolute inset-0 flex items-center justify-center"
                animate={{
                  x: `${xPercent}%`,
                  y: yPx,
                  rotateY,
                  rotateZ,
                  scale,
                  opacity,
                  filter: `blur(${blurPx}px)`,
                }}
                transition={transition}
                style={{
                  transformStyle: 'preserve-3d',
                  zIndex: z,
                  pointerEvents: dist > 0 ? 'auto' : 'auto',
                }}
                drag={isFocused ? 'x' : false}
                dragConstraints={{ left: 0, right: 0 }}
                dragElastic={0.25}
                onDragEnd={(_, info) => {
                  if (Math.abs(info.offset.x) > 80) {
                    step(info.offset.x < 0 ? 1 : -1)
                  }
                }}
              >
                <div className="w-full">
                  <CardFlip
                    card={card}
                    flipped={flippedIds.includes(card.card_id)}
                    onFlip={() => toggleFlip(card.card_id)}
                    revealed={!streamerMode && ((revealedUntil[card.card_id] ?? 0) > now || Boolean(card.full_pan))}
                    onToggleReveal={() => {
                      const expiry = revealedUntil[card.card_id] ?? 0
                      if (!streamerMode && (expiry > now || Boolean(card.full_pan))) {
                        hideReveal(card.card_id)
                        setStreamerMode(true)
                      } else {
                        if (streamerMode) setStreamerMode(false)
                        revealCard(card.card_id)
                      }
                    }}
                    interactive={isFocused}
                    className={cn(!isFocused && 'cursor-pointer')}
                  />
                </div>
                {/* Background-card click target — focuses without flipping. */}
                {!isFocused && (
                  <button
                    type="button"
                    className="absolute inset-0"
                    aria-label={t('cards.focusCard').replace('{lastFour}', card.pan_last_four)}
                    onClick={(e) => {
                      e.stopPropagation()
                      setSelected(card.card_id)
                      sfx.console_tap()
                    }}
                    style={{ background: 'transparent' }}
                  />
                )}
              </motion.div>
            )
          })}
        </div>
      </div>

      {/* Controls row — prev / dots / next */}
      <div className="mt-4 2xl:mt-5 flex items-center gap-3">
        <CarouselButton
          direction="prev"
          disabled={focusedIndex === 0}
          onClick={() => step(-1)}
        />
        <Dots count={cards.length} active={focusedIndex} onSelect={(i) => {
          const target = cards[i]
          if (target) {
            setSelected(target.card_id)
            sfx.console_tap()
          }
        }} />
        <CarouselButton
          direction="next"
          disabled={focusedIndex === cards.length - 1}
          onClick={() => step(1)}
        />
      </div>
    </div>
  )
}

/* --------------------------------------------------------------------------
   Sub-components
   -------------------------------------------------------------------------- */

function CarouselButton({
  direction,
  disabled,
  onClick,
}: {
  direction: 'prev' | 'next'
  disabled: boolean
  onClick: () => void
}) {
  const { t } = useI18n()
  const Icon = direction === 'prev' ? ChevronLeft : ChevronRight
  const label = direction === 'prev' ? t('cards.previousCard') : t('cards.nextCard')
  return (
    <button
      type="button"
      aria-label={label}
      onClick={onClick}
      disabled={disabled}
      className={cn(
        'inline-flex items-center justify-center h-9 w-9 rounded-full',
        'text-text-secondary',
        'transition-[background-color,color,opacity] duration-180',
        'hover:bg-surface-card-elevated hover:text-text-primary',
        'disabled:opacity-30 disabled:cursor-not-allowed disabled:hover:bg-transparent disabled:hover:text-text-secondary',
      )}
      style={{
        background: 'rgba(255,255,255,0.04)',
        border: '1px solid rgba(255,255,255,0.08)',
      }}
    >
      <Icon size={16} strokeWidth={2} />
    </button>
  )
}

function Dots({
  count,
  active,
  onSelect,
}: {
  count: number
  active: number
  onSelect: (i: number) => void
}) {
  const { t } = useI18n()
  return (
    <div className="flex items-center gap-1.5" role="tablist" aria-label={t('cards.cardSelector')}>
      {Array.from({ length: count }).map((_, i) => {
        const isActive = i === active
        return (
          <button
            key={i}
            role="tab"
            aria-selected={isActive}
            aria-label={t('cards.cardN').replace('{n}', String(i + 1))}
            onClick={() => onSelect(i)}
            className={cn(
              'rounded-full transition-all duration-200',
              isActive ? 'h-1.5 w-5' : 'h-1.5 w-1.5 hover:opacity-80',
            )}
            style={{
              background: isActive
                ? 'var(--gradient-primary)'
                : 'rgba(255,255,255,0.18)',
            }}
          />
        )
      })}
    </div>
  )
}

function CarouselEmpty({ className }: { className?: string }) {
  const { t } = useI18n()
  return (
    <div
      className={cn(
        'w-full mx-auto rounded-2xl flex flex-col items-center justify-center text-center px-6',
        className,
      )}
      style={{
        aspectRatio: '1.586 / 1',
        background: 'rgba(255,255,255,0.02)',
        border: '1px dashed rgba(255,255,255,0.1)',
      }}
    >
      <p className="text-sm font-semibold text-text-primary mb-1">
        {t('cards.noCardsTitle')}
      </p>
      <p className="text-xs text-text-tertiary max-w-[36ch]">
        {t('cards.noCardsDescription')}
      </p>
    </div>
  )
}
