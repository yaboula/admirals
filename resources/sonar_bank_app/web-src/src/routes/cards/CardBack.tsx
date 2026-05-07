import type { BankCardMock } from '@/data/contracts'
import { cn } from '@/lib/utils'
import { resolveCardDesign, type CardDesign } from './cardDesigns'

/**
 * BANK-FE.4.2 — CardBack
 *
 * Back side of a card, mirroring the design recipe of the front so a flip
 * feels continuous. Layout (top → bottom):
 *
 *   1. Magnetic stripe (full-bleed black band)
 *   2. Signature panel + CVV box (white with diagonal hatching)
 *   3. Footer disclaimer + last4 echo
 *
 * Front-and-back share the same surface gradient + shadow envelope; only the
 * inner content differs. The motif on the back is intentionally muted so the
 * stripe and CVV stay legible.
 */
export interface CardBackProps {
  card: BankCardMock
  design?: CardDesign
  compact?: boolean
  className?: string
}

export function CardBack({ card, design: designOverride, compact = false, className }: CardBackProps) {
  const design = designOverride ?? resolveCardDesign(card.design_id)

  return (
    <div
      className={cn(
        'relative aspect-[1.586/1] w-full overflow-hidden rounded-2xl select-none',
        className,
      )}
      style={{
        background: design.surface,
        color: design.textPrimary,
        border: '1px solid oklch(1 0 0 / 0.08)',
        boxShadow:
          '0 24px 48px -16px oklch(0 0 0 / 0.65), 0 8px 16px -4px oklch(0 0 0 / 0.45), inset 0 1px 0 oklch(1 0 0 / 0.06), inset 0 -1px 0 oklch(0 0 0 / 0.4)',
      }}
    >
      {/* Subtle holographic sweep echoing the front, kept dim for legibility */}
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'linear-gradient(115deg, transparent 0%, transparent 35%, oklch(1 0 0 / 0.04) 50%, transparent 65%, transparent 100%)',
          mixBlendMode: 'overlay',
        }}
      />

      {/* Magnetic stripe — pure black band, ~22% of card height */}
      <div
        aria-hidden
        className={cn(
          'absolute left-0 right-0',
          compact ? 'top-3.5 h-[22%]' : 'top-4 h-[22%] 2xl:top-5',
        )}
        style={{
          background:
            'linear-gradient(180deg, oklch(0 0 0) 0%, oklch(0 0 0) 60%, oklch(0.10 0 0) 100%)',
          boxShadow: 'inset 0 1px 0 oklch(0 0 0 / 0.6), inset 0 -1px 0 oklch(0 0 0 / 0.6)',
        }}
      />

      {/* Content — placed below the magstripe */}
      <div
        className={cn(
          'relative h-full flex flex-col justify-end',
          compact ? 'p-3.5' : 'p-4 2xl:p-5',
        )}
      >
        {/* Signature panel + CVV row */}
        <div className="flex items-stretch gap-2 mb-2.5">
          <SignaturePanel holder={card.holder_name} compact={compact} />
          <CvvBox cvv={card.cvv} compact={compact} />
        </div>

        {/* Footer row: disclaimer + last4 echo */}
        <div className="flex items-end justify-between gap-3">
          <p
            className={cn(
              'leading-snug max-w-[60%]',
              compact ? 'text-[7.5px]' : 'text-[8px]',
            )}
            style={{ color: design.textTertiary, opacity: 0.85 }}
          >
            Esta tarjeta es propiedad de SONAR Bank. Su uso está sujeto a los términos
            del contrato del titular. En caso de pérdida, congele desde la app.
          </p>
          <div className="flex flex-col items-end gap-0.5 leading-none shrink-0">
            <span
              className="text-[8px] uppercase tracking-[0.18em] font-semibold"
              style={{ color: design.textTertiary }}
            >
              Tarjeta
            </span>
            <span
              className={cn(
                'font-mono font-semibold tactile-tabular-nums',
                compact ? 'text-xs' : 'text-sm',
              )}
              style={{
                color: design.textPrimary,
                fontVariantNumeric: 'tabular-nums',
                letterSpacing: '0.06em',
              }}
            >
              ···· {card.pan_last_four}
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

/* --------------------------------------------------------------------------
   Sub-components
   -------------------------------------------------------------------------- */

/**
 * White signature strip with subtle diagonal hatching, holder name printed
 * in a script-like styling (we use system italic — no webfont budget for a
 * single decorative element).
 */
function SignaturePanel({ holder, compact }: { holder: string; compact: boolean }) {
  return (
    <div
      className={cn(
        'flex-1 relative rounded-sm overflow-hidden',
        compact ? 'h-7' : 'h-8 2xl:h-9',
      )}
      style={{
        background: 'linear-gradient(180deg, oklch(0.96 0 0) 0%, oklch(0.92 0 0) 100%)',
        boxShadow: 'inset 0 1px 2px oklch(0 0 0 / 0.25), inset 0 -1px 0 oklch(1 0 0 / 0.6)',
      }}
    >
      {/* Diagonal hatching pattern — security-paper feel */}
      <div
        aria-hidden
        className="absolute inset-0 opacity-30"
        style={{
          backgroundImage:
            'repeating-linear-gradient(45deg, oklch(0.65 0.10 250 / 0.5) 0 1px, transparent 1px 5px)',
        }}
      />
      <div className="relative h-full flex items-center px-2.5">
        <span
          className={cn(
            'italic font-semibold truncate',
            compact ? 'text-[10px]' : 'text-[11px]',
          )}
          style={{
            color: 'oklch(0.20 0.02 270)',
            fontFamily: '"Brush Script MT", "Apple Chancery", cursive',
            letterSpacing: '0.02em',
          }}
        >
          {holder}
        </span>
      </div>
    </div>
  )
}

/** White inline box showing CVV2 with a "CVV" caption above it. */
function CvvBox({ cvv, compact }: { cvv: string; compact: boolean }) {
  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center px-2.5 rounded-sm shrink-0',
        compact ? 'h-7 min-w-[44px]' : 'h-8 min-w-[48px] 2xl:h-9 2xl:min-w-[52px]',
      )}
      style={{
        background: 'linear-gradient(180deg, oklch(0.96 0 0) 0%, oklch(0.92 0 0) 100%)',
        boxShadow: 'inset 0 1px 2px oklch(0 0 0 / 0.25), inset 0 -1px 0 oklch(1 0 0 / 0.6)',
      }}
    >
      <span
        className={cn(
          'font-mono font-bold tactile-tabular-nums leading-none',
          compact ? 'text-[11px]' : 'text-xs',
        )}
        style={{
          color: 'oklch(0.20 0.02 270)',
          fontVariantNumeric: 'tabular-nums',
          letterSpacing: '0.08em',
        }}
      >
        {cvv}
      </span>
    </div>
  )
}
