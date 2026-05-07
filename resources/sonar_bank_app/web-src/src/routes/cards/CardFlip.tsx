import { motion, useReducedMotion } from 'motion/react'
import type { BankCardMock } from '@/data/contracts'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { CardVisual } from './CardVisual'
import { CardBack } from './CardBack'
import { resolveCardDesign } from './cardDesigns'

/**
 * BANK-FE.4.2 — CardFlip
 *
 * Composes CardVisual (front) + CardBack on a 3D-flipping container. The
 * parent owns the flipped + revealed state via `useCardsUi` and passes
 * `flipped` + `onFlip` here so the store stays single-source-of-truth.
 *
 * Implementation notes:
 *   - `transformStyle: preserve-3d` on the container so children keep their
 *     own perspective during the rotation.
 *   - `backfaceVisibility: hidden` on each face so the off-screen one is not
 *     visible when partially rotated.
 *   - The back is pre-rotated 180° on Y so it lands face-up at the half-flip.
 *   - Reduced-motion users get an instant cross-fade (no rotation).
 *
 * Tap-to-flip is wired on the whole container; the inner CardVisual reveal
 * button stops propagation so revealing the PAN does not also flip the card.
 */
export interface CardFlipProps {
  card: BankCardMock
  flipped: boolean
  onFlip: () => void
  revealed: boolean
  onToggleReveal: () => void
  compact?: boolean
  className?: string
  /** When false the card is in the carousel background — disable interactions. */
  interactive?: boolean
}

export function CardFlip({
  card,
  flipped,
  onFlip,
  revealed,
  onToggleReveal,
  compact = false,
  className,
  interactive = true,
}: CardFlipProps) {
  const reduced = useReducedMotion()
  const design = resolveCardDesign(card.design_id)

  const handleFlip = () => {
    if (!interactive) return
    onFlip()
    sfx.layer_dive()
  }

  // Reduced-motion fallback: render whichever face is currently up.
  if (reduced) {
    return (
      <div
        className={cn('relative w-full', className)}
        onClick={handleFlip}
        role={interactive ? 'button' : undefined}
        aria-label={interactive ? (flipped ? 'Mostrar frente de la tarjeta' : 'Mostrar reverso de la tarjeta') : undefined}
        tabIndex={interactive ? 0 : -1}
        onKeyDown={(e) => {
          if (!interactive) return
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault()
            handleFlip()
          }
        }}
        style={{ cursor: interactive ? 'pointer' : 'default' }}
      >
        {flipped ? (
          <CardBack card={card} design={design} compact={compact} />
        ) : (
          <CardVisual
            card={card}
            design={design}
            revealed={revealed}
            onToggleReveal={interactive ? onToggleReveal : undefined}
            compact={compact}
          />
        )}
      </div>
    )
  }

  return (
    <div
      className={cn('relative w-full', className)}
      style={{ perspective: '1400px', cursor: interactive ? 'pointer' : 'default' }}
      onClick={handleFlip}
      role={interactive ? 'button' : undefined}
      aria-label={interactive ? (flipped ? 'Mostrar frente de la tarjeta' : 'Mostrar reverso de la tarjeta') : undefined}
      aria-pressed={flipped}
      tabIndex={interactive ? 0 : -1}
      onKeyDown={(e) => {
        if (!interactive) return
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          handleFlip()
        }
      }}
    >
      <motion.div
        className="relative aspect-[1.586/1] w-full"
        animate={{ rotateY: flipped ? 180 : 0 }}
        transition={{ type: 'spring', stiffness: 200, damping: 26, mass: 1.05 }}
        style={{ transformStyle: 'preserve-3d' }}
      >
        {/* Front face */}
        <div
          className="absolute inset-0"
          style={{ backfaceVisibility: 'hidden', WebkitBackfaceVisibility: 'hidden' }}
        >
          <CardVisual
            card={card}
            design={design}
            revealed={revealed}
            onToggleReveal={interactive ? onToggleReveal : undefined}
            compact={compact}
          />
        </div>

        {/* Back face — pre-rotated so it reads correctly at flipped state */}
        <div
          className="absolute inset-0"
          style={{
            backfaceVisibility: 'hidden',
            WebkitBackfaceVisibility: 'hidden',
            transform: 'rotateY(180deg)',
          }}
        >
          <CardBack card={card} design={design} compact={compact} />
        </div>
      </motion.div>
    </div>
  )
}
