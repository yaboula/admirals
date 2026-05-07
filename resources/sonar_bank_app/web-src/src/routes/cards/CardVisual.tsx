import { motion, useReducedMotion } from 'motion/react'
import { Eye, EyeOff, Wifi, Lock, Clock3 } from 'lucide-react'
import type { BankCard, BankCardMock } from '@/data/contracts'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { resolveCardDesign, type CardDesign, type CardDesignMotif } from './cardDesigns'

/**
 * BANK-FE.4.1 — CardVisual primitive.
 *
 * Renders a single bank card using a design recipe from `cardDesigns.ts`.
 * The component is intentionally presentational: it never fetches data,
 * never mutates the card. Parent routes own state (selected card, reveal
 * toggle, flip side) and drive the visual through props.
 *
 * FRONT-ONLY in Phase 4.1. The flip-to-back animation and carousel
 * orchestration land in Phase 4.2 with the /tarjetas route.
 */
export interface CardVisualProps {
  card: BankCard | BankCardMock
  /**
   * Optional override. When omitted the design is resolved from
   * `card.design_id` via the registry.
   */
  design?: CardDesign
  /**
   * Reveal the full 16-digit PAN (only meaningful when card is a BankCardMock
   * with full_pan populated — in production the reveal flow hits an
   * authenticated endpoint). When undefined the visual always shows masked.
   */
  revealed?: boolean
  onToggleReveal?: () => void
  /**
   * Compact mode: smaller paddings and typography for list/carousel contexts.
   * The hero render on /tarjetas uses the full (non-compact) variant.
   */
  compact?: boolean
  className?: string
  /**
   * Optional click handler for the whole card surface — used by the carousel
   * to focus a background card. Disabled when the card is locked.
   */
  onClick?: () => void
}

export function CardVisual({
  card,
  design: designOverride,
  revealed = false,
  onToggleReveal,
  compact = false,
  className,
  onClick,
}: CardVisualProps) {
  const reduced = useReducedMotion()
  const design = designOverride ?? resolveCardDesign(card.design_id)

  const locked = card.status === 'locked' || card.status === 'expired'
  const expiryDate = new Date(card.expiry_ms)
  const expiryStr = `${String(expiryDate.getMonth() + 1).padStart(2, '0')}/${String(expiryDate.getFullYear()).slice(-2)}`

  const maskedMid = '···· ····'
  const fullPan = (card as BankCardMock).full_pan
  const pan = revealed && fullPan ? fullPan : `4287 ${maskedMid} ${card.pan_last_four}`

  return (
    <motion.div
      initial={reduced ? false : { opacity: 0, y: 10, rotateX: -4 }}
      animate={{ opacity: 1, y: 0, rotateX: 0 }}
      transition={{ type: 'spring', stiffness: 220, damping: 22, mass: 0.9 }}
      className={cn(
        'relative aspect-[1.586/1] w-full overflow-hidden rounded-2xl',
        'select-none',
        onClick && !locked && 'cursor-pointer',
        className,
      )}
      style={{
        background: design.surface,
        color: design.textPrimary,
        border: '1px solid oklch(1 0 0 / 0.08)',
        boxShadow:
          '0 24px 48px -16px oklch(0 0 0 / 0.65), 0 8px 16px -4px oklch(0 0 0 / 0.45), inset 0 1px 0 oklch(1 0 0 / 0.06), inset 0 -1px 0 oklch(0 0 0 / 0.4)',
      }}
      onClick={onClick}
    >
      {/* Decorative motif — background pattern specific to the design */}
      <Motif motif={design.motif} accent={design.accent} />

      {/* Holographic sweep — subtle diagonal light across every design */}
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'linear-gradient(115deg, transparent 0%, transparent 35%, oklch(1 0 0 / 0.06) 50%, transparent 65%, transparent 100%)',
          mixBlendMode: 'overlay',
        }}
      />

      {/* Design overlay — radial aura when declared */}
      {design.overlay && (
        <div
          aria-hidden
          className="absolute inset-0 pointer-events-none"
          style={{ background: design.overlay, filter: 'blur(14px)' }}
        />
      )}

      {/* Content — padded layout, top / middle / bottom rows */}
      <div
        className={cn(
          'relative h-full flex flex-col justify-between',
          compact ? 'p-3.5' : 'p-4 2xl:p-5',
        )}
      >
        {/* ── TOP ROW: SONAR lockup + card-type badge + contactless ── */}
        <div className="flex items-start justify-between gap-3">
          <SonarLockup
            accent={design.accent}
            textPrimary={design.textPrimary}
            textTertiary={design.textTertiary}
          />
          <div className="flex items-center gap-2">
            <CardTypeBadge
              type={card.card_type}
              textTertiary={design.textTertiary}
            />
            <Wifi
              size={compact ? 14 : 16}
              strokeWidth={2}
              className="rotate-90 opacity-70"
              style={{ color: design.textTertiary }}
            />
          </div>
        </div>

        {/* ── MIDDLE ROW: EMV chip + brand mark ── */}
        <div className="flex items-center gap-3">
          <Chip />
          <SonarMonogram accent={design.accent} size={compact ? 18 : 20} />
        </div>

        {/* ── BOTTOM ROW: PAN + holder + expiry ── */}
        <div className="flex items-end justify-between gap-3">
          <div className="flex flex-col gap-1.5 min-w-0 flex-1">
            <button
              type="button"
              disabled={!onToggleReveal}
              onClick={(e) => {
                e.stopPropagation()
                if (onToggleReveal) {
                  onToggleReveal()
                  sfx.console_tap()
                }
              }}
              className={cn(
                'group flex items-center gap-2 text-left',
                !onToggleReveal && 'cursor-default',
              )}
              aria-label={revealed ? 'Ocultar número de tarjeta' : 'Revelar número de tarjeta'}
            >
              <span
                className={cn(
                  'font-mono font-medium tracking-wider tactile-tabular-nums',
                  compact ? 'text-sm' : 'text-base 2xl:text-lg',
                )}
                style={{
                  color: design.textPrimary,
                  fontVariantNumeric: 'tabular-nums',
                  letterSpacing: '0.08em',
                }}
              >
                {pan}
              </span>
              {onToggleReveal && (
                revealed ? (
                  <EyeOff
                    size={12}
                    className="opacity-0 group-hover:opacity-80 transition-opacity"
                    style={{ color: design.textTertiary }}
                  />
                ) : (
                  <Eye
                    size={12}
                    className="opacity-0 group-hover:opacity-80 transition-opacity"
                    style={{ color: design.textTertiary }}
                  />
                )
              )}
            </button>

            <div className="flex items-end gap-4 leading-none">
              <div className="flex flex-col gap-0.5 min-w-0">
                <span
                  className="text-[8px] uppercase tracking-[0.18em] font-semibold"
                  style={{ color: design.textTertiary }}
                >
                  Titular
                </span>
                <span
                  className="text-[11px] font-semibold tracking-wide truncate max-w-[18ch]"
                  style={{ color: design.textPrimary }}
                >
                  {card.holder_name}
                </span>
              </div>
              <div className="flex flex-col gap-0.5">
                <span
                  className="text-[8px] uppercase tracking-[0.18em] font-semibold"
                  style={{ color: design.textTertiary }}
                >
                  Caduca
                </span>
                <span
                  className="text-[11px] font-semibold tracking-wide tactile-tabular-nums"
                  style={{ color: design.textPrimary }}
                >
                  {expiryStr}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Frozen / expired overlay — dims the card and surfaces the reason */}
      {locked && (
        <div
          aria-hidden
          className="absolute inset-0 flex items-center justify-center backdrop-blur-[2px]"
          style={{ background: 'oklch(0 0 0 / 0.45)' }}
        >
          <div
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-[11px] font-semibold uppercase tracking-[0.16em]"
            style={{
              background: 'oklch(0 0 0 / 0.6)',
              border: '1px solid oklch(1 0 0 / 0.12)',
              color: design.textPrimary,
            }}
          >
            {card.status === 'expired' ? (
              <>
                <Clock3 size={12} strokeWidth={2.4} />
                Caducada
              </>
            ) : (
              <>
                <Lock size={12} strokeWidth={2.4} />
                Congelada
              </>
            )}
          </div>
        </div>
      )}
    </motion.div>
  )
}

/* --------------------------------------------------------------------------
   Visual sub-components
   -------------------------------------------------------------------------- */

/** Top-left lockup: SONAR wordmark + Bank subtitle, using design colours. */
function SonarLockup({
  accent,
  textPrimary,
  textTertiary,
}: {
  accent: string
  textPrimary: string
  textTertiary: string
}) {
  return (
    <div className="flex flex-col leading-none gap-0.5">
      <span
        className="text-[8px] uppercase tracking-[0.34em] font-semibold"
        style={{ color: textTertiary }}
      >
        SONAR
      </span>
      <div className="flex items-center gap-1.5">
        <span
          className="text-[14px] font-bold tracking-tight tactile-wght-breathing"
          style={{ color: textPrimary }}
        >
          Bank
        </span>
        <span
          aria-hidden
          className="inline-block h-1 w-1 rounded-full"
          style={{ background: accent, opacity: 0.7 }}
        />
      </div>
    </div>
  )
}

/** Compact card-type pill (DEBIT / VIRTUAL / CREDIT). */
function CardTypeBadge({
  type,
  textTertiary,
}: {
  type: BankCard['card_type']
  textTertiary: string
}) {
  const label = type === 'debit' ? 'DEBIT' : type === 'virtual' ? 'VIRTUAL' : 'CREDIT'
  return (
    <span
      className="inline-flex items-center px-1.5 py-0.5 rounded-md text-[8px] uppercase tracking-[0.18em] font-semibold"
      style={{
        background: 'oklch(1 0 0 / 0.08)',
        border: '1px solid oklch(1 0 0 / 0.10)',
        color: textTertiary,
      }}
    >
      {label}
    </span>
  )
}

/**
 * Sonar isotipo — 3 concentric arcs mirroring the `logo_v3/monogram_s.svg`
 * design system deliverable. Uses the design accent so the mark inherits
 * the card's chromatic story (orange on sonar_signature, teal on aurora…).
 */
function SonarMonogram({ accent, size = 20 }: { accent: string; size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      aria-hidden
      style={{ color: accent }}
    >
      <g fill="none" stroke="currentColor" strokeLinecap="round">
        <path d="M5 17 A 8 8 0 0 1 19 17" strokeWidth="1.6" opacity="1" />
        <path d="M7.5 14.5 A 5 5 0 0 1 16.5 14.5" strokeWidth="1.4" opacity="0.65" />
        <path d="M10 12 A 2.2 2.2 0 0 1 14 12" strokeWidth="1.2" opacity="0.35" />
      </g>
    </svg>
  )
}

/**
 * EMV-style gold chip — gradient + contact pad grid. Purely CSS, no bitmap.
 * Identical to the legacy CreditCardVisual chip; kept here to decouple
 * CardVisual from the old Home-specific component as we migrate.
 */
function Chip() {
  return (
    <div
      aria-hidden
      className="relative h-6 w-8 rounded-md overflow-hidden shrink-0"
      style={{
        background:
          'linear-gradient(135deg, oklch(0.78 0.12 85) 0%, oklch(0.62 0.10 75) 50%, oklch(0.45 0.06 70) 100%)',
        boxShadow:
          'inset 0 1px 0 oklch(1 0 0 / 0.4), inset 0 -1px 0 oklch(0 0 0 / 0.4), 0 2px 4px oklch(0 0 0 / 0.4)',
      }}
    >
      <div className="absolute inset-1 grid grid-cols-2 grid-rows-3 gap-px">
        {Array.from({ length: 6 }).map((_, i) => (
          <div
            key={i}
            style={{ background: 'oklch(0.30 0.04 70 / 0.55)', borderRadius: '1px' }}
          />
        ))}
      </div>
      <div
        className="absolute left-0 right-0"
        style={{ top: '50%', height: '1px', background: 'oklch(0.30 0.04 70 / 0.7)' }}
      />
    </div>
  )
}

/**
 * Decorative motif — background pattern layer per design identity.
 *   - pinstripe:    diagonal hairlines (noir)
 *   - sonar_waves:  concentric arcs evoking the isotipo (sonar_signature)
 *   - geometric:    light grid (aurora)
 *   - fluid:        soft blob highlight (sunset)
 *   - none:         no-op
 */
function Motif({ motif, accent }: { motif: CardDesignMotif; accent: string }) {
  if (motif === 'none') return null

  if (motif === 'pinstripe') {
    return (
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none opacity-[0.045]"
        style={{
          backgroundImage:
            'repeating-linear-gradient(135deg, oklch(1 0 0 / 0.6) 0 1px, transparent 1px 18px)',
        }}
      />
    )
  }

  if (motif === 'sonar_waves') {
    return (
      <svg
        aria-hidden
        viewBox="0 0 400 240"
        preserveAspectRatio="xMaxYMid slice"
        className="absolute inset-0 h-full w-full pointer-events-none"
        style={{ color: accent, opacity: 0.22 }}
      >
        <g fill="none" stroke="currentColor" strokeLinecap="round">
          <path d="M 290 255 A 80 80 0 0 1 450 255" strokeWidth="2" opacity="1" />
          <path d="M 305 255 A 60 60 0 0 1 435 255" strokeWidth="1.6" opacity="0.7" />
          <path d="M 320 255 A 40 40 0 0 1 420 255" strokeWidth="1.3" opacity="0.45" />
          <path d="M 335 255 A 22 22 0 0 1 405 255" strokeWidth="1" opacity="0.25" />
        </g>
      </svg>
    )
  }

  if (motif === 'geometric') {
    return (
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none opacity-[0.06]"
        style={{
          backgroundImage: [
            'linear-gradient(0deg, oklch(1 0 0 / 0.4) 0 1px, transparent 1px 28px)',
            'linear-gradient(90deg, oklch(1 0 0 / 0.4) 0 1px, transparent 1px 28px)',
          ].join(', '),
        }}
      />
    )
  }

  if (motif === 'fluid') {
    return (
      <div
        aria-hidden
        className="absolute pointer-events-none"
        style={{
          bottom: '-30%',
          left: '-10%',
          width: '70%',
          height: '130%',
          background: `radial-gradient(circle at 40% 50%, ${accent.replace(')', ' / 0.18)')}, transparent 60%)`,
          filter: 'blur(22px)',
        }}
      />
    )
  }

  return null
}
