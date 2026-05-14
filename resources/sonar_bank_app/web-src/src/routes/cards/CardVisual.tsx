import { motion, AnimatePresence, useReducedMotion } from 'motion/react'
import { Eye, EyeOff, Wifi, Lock, Clock3 } from 'lucide-react'
import type { BankCard, BankCardMock } from '@/data/contracts'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { maskPanDisplay, revealPanDisplay } from '@/lib/privacy'
import { useI18n } from '@/lib/i18n'
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
  const { t } = useI18n()
  const reduced = useReducedMotion()
  const design = designOverride ?? resolveCardDesign(card.design_id)

  const locked = card.status === 'locked' || card.status === 'expired'
  const expiryDate = new Date(card.expiry_ms)
  const expiryStr = `${String(expiryDate.getMonth() + 1).padStart(2, '0')}/${String(expiryDate.getFullYear()).slice(-2)}`

  const pan = revealed ? revealPanDisplay((card as BankCardMock).full_pan, card.pan_last_four) : maskPanDisplay(undefined, card.pan_last_four)

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
        border: '1px solid rgba(255,255,255,0.08)',
        boxShadow:
          '0 24px 48px -16px rgba(0,0,0,0.65), 0 8px 16px -4px rgba(0,0,0,0.45), inset 0 1px 0 rgba(255,255,255,0.06), inset 0 -1px 0 rgba(0,0,0,0.4)',
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
            'linear-gradient(115deg, transparent 0%, transparent 35%, rgba(255,255,255,0.06) 50%, transparent 65%, transparent 100%)',
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
              aria-label={revealed ? t('cards.hideNumber') : t('cards.revealNumber')}
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
                  {t('cards.holder')}
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
                  {t('cards.expires')}
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

      {/* Frozen / expired overlay — premium icy effect (motion-presence) */}
      <AnimatePresence>
        {locked && (
          <FrostOverlay
            key={card.status}
            status={card.status === 'expired' ? 'expired' : 'locked'}
            textPrimary={design.textPrimary}
            reduced={!!reduced}
          />
        )}
      </AnimatePresence>
    </motion.div>
  )
}

/* --------------------------------------------------------------------------
   FrostOverlay — premium frozen-card effect.

   Layers (back → front):
     1. Icy gradient (cool teal-blue tint @ 40-55% opacity)
     2. SVG snowflake crystals (8 randomly-rotated marks scattered across)
     3. Frosted glass blur (backdrop-blur)
     4. Pulsing Lock badge centered with subtle ring halo

   Animation: 360ms ease-out spread from centre on enter; 240ms fade on exit.
   Reduced motion → instant cross-fade with no scale/blur sweep.

   The expired variant uses the same scaffolding but with a Clock icon and
   warmer dim-grey tint instead of icy blue.
   -------------------------------------------------------------------------- */
function FrostOverlay({
  status,
  textPrimary,
  reduced,
}: {
  status: 'locked' | 'expired'
  textPrimary: string
  reduced: boolean
}) {
  const { t } = useI18n()
  const isFrozen = status === 'locked'
  return (
    <motion.div
      aria-hidden
      initial={reduced ? { opacity: 0 } : { opacity: 0, scale: 1.04 }}
      animate={reduced ? { opacity: 1 } : { opacity: 1, scale: 1 }}
      exit={reduced ? { opacity: 0 } : { opacity: 0, scale: 1.02 }}
      transition={
        reduced
          ? { duration: 0.18 }
          : { duration: 0.36, ease: [0.16, 1, 0.3, 1] }
      }
      className="absolute inset-0 flex items-center justify-center"
      style={{
        background: isFrozen
          ? 'radial-gradient(circle at 50% 50%, rgba(72,146,168,0.42) 0%, rgba(0,20,32,0.62) 80%)'
          : 'rgba(0,0,0,0.55)',
        backdropFilter: 'blur(3px) saturate(0.7)',
        WebkitBackdropFilter: 'blur(3px) saturate(0.7)',
      }}
    >
      {/* Crystal field — 8 ice marks scattered across the surface */}
      {isFrozen && <CrystalField reduced={reduced} />}

      {/* Centre badge — pulsing ring around a Lock / Clock glyph */}
      <div className="relative flex items-center justify-center">
        {isFrozen && !reduced && (
          <motion.span
            aria-hidden
            className="absolute rounded-full"
            initial={{ scale: 0.8, opacity: 0.6 }}
            animate={{ scale: [0.9, 1.25, 0.9], opacity: [0.55, 0.0, 0.55] }}
            transition={{ duration: 2.4, ease: 'easeInOut', repeat: Infinity }}
            style={{
              width: 64,
              height: 64,
              border: '1px solid rgba(185,239,255,0.55)',
            }}
          />
        )}
        <motion.div
          initial={reduced ? false : { y: 4, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.12, duration: 0.32, ease: [0.16, 1, 0.3, 1] }}
          className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-[11px] font-semibold uppercase tracking-[0.18em]"
          style={{
            background: isFrozen
              ? 'rgba(0,20,32,0.85)'
              : 'rgba(0,0,0,0.7)',
            border: isFrozen
              ? '1px solid rgba(148,222,245,0.45)'
              : '1px solid rgba(255,255,255,0.12)',
            color: textPrimary,
            boxShadow: isFrozen
              ? '0 0 24px -4px rgba(74,173,201,0.55), inset 0 1px 0 rgba(255,255,255,0.1)'
              : 'inset 0 1px 0 rgba(255,255,255,0.06)',
          }}
        >
          {isFrozen ? (
            <>
              <Lock size={12} strokeWidth={2.6} />
              {t('cards.frozen')}
            </>
          ) : (
            <>
              <Clock3 size={12} strokeWidth={2.4} />
              {t('cards.expired')}
            </>
          )}
        </motion.div>
      </div>
    </motion.div>
  )
}

/**
 * CrystalField — 8 hand-positioned snowflake glyphs scattered across the
 * card with staggered fade-in. Positions are deterministic so the field
 * looks the same on every render (no jitter on re-mount).
 */
const CRYSTAL_POSITIONS = [
  { x: '12%', y: '18%', size: 14, rot: 12, opacity: 0.55 },
  { x: '78%', y: '22%', size: 10, rot: -22, opacity: 0.5 },
  { x: '32%', y: '70%', size: 12, rot: 38, opacity: 0.45 },
  { x: '88%', y: '64%', size: 11, rot: 6, opacity: 0.55 },
  { x: '54%', y: '14%', size: 8, rot: -14, opacity: 0.4 },
  { x: '20%', y: '50%', size: 9, rot: 24, opacity: 0.4 },
  { x: '66%', y: '46%', size: 13, rot: -32, opacity: 0.5 },
  { x: '46%', y: '82%', size: 10, rot: 18, opacity: 0.45 },
] as const

function CrystalField({ reduced }: { reduced: boolean }) {
  return (
    <>
      {CRYSTAL_POSITIONS.map((c, i) => (
        <motion.svg
          key={i}
          aria-hidden
          width={c.size}
          height={c.size}
          viewBox="0 0 24 24"
          className="absolute pointer-events-none"
          style={{
            left: c.x,
            top: c.y,
            color: 'rgb(228, 245, 251)',
            opacity: c.opacity,
            transform: `translate(-50%, -50%) rotate(${c.rot}deg)`,
          }}
          initial={reduced ? { opacity: 0 } : { opacity: 0, scale: 0.5 }}
          animate={{ opacity: c.opacity, scale: 1 }}
          transition={
            reduced
              ? { duration: 0.18, delay: i * 0.02 }
              : { duration: 0.42, ease: [0.16, 1, 0.3, 1], delay: 0.08 + i * 0.04 }
          }
        >
          {/* Six-pointed snowflake — three crossed lines with little branches */}
          <g
            fill="none"
            stroke="currentColor"
            strokeWidth="1.4"
            strokeLinecap="round"
          >
            <line x1="12" y1="2" x2="12" y2="22" />
            <line x1="3.34" y1="7" x2="20.66" y2="17" />
            <line x1="3.34" y1="17" x2="20.66" y2="7" />
            <path d="M9 4 L12 6 L15 4" />
            <path d="M9 20 L12 18 L15 20" />
          </g>
        </motion.svg>
      ))}
    </>
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
  const { t } = useI18n()
  const label = type === 'debit' ? t('cards.debit') : type === 'virtual' ? t('cards.virtual') : t('cards.credit')
  return (
    <span
      className="inline-flex items-center px-1.5 py-0.5 rounded-md text-[8px] uppercase tracking-[0.18em] font-semibold"
      style={{
        background: 'rgba(255,255,255,0.08)',
        border: '1px solid rgba(255,255,255,0.1)',
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
          'linear-gradient(135deg, rgb(219, 177, 85) 0%, rgb(169, 125, 58) 50%, rgb(107, 79, 47) 100%)',
        boxShadow:
          'inset 0 1px 0 rgba(255,255,255,0.4), inset 0 -1px 0 rgba(0,0,0,0.4), 0 2px 4px rgba(0,0,0,0.4)',
      }}
    >
      <div className="absolute inset-1 grid grid-cols-2 grid-rows-3 gap-px">
        {Array.from({ length: 6 }).map((_, i) => (
          <div
            key={i}
            style={{ background: 'rgba(59,42,23,0.55)', borderRadius: '1px' }}
          />
        ))}
      </div>
      <div
        className="absolute left-0 right-0"
        style={{ top: '50%', height: '1px', background: 'rgba(59,42,23,0.7)' }}
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
            'repeating-linear-gradient(135deg, rgba(255,255,255,0.6) 0 1px, transparent 1px 18px)',
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
            'linear-gradient(0deg, rgba(255,255,255,0.4) 0 1px, transparent 1px 28px)',
            'linear-gradient(90deg, rgba(255,255,255,0.4) 0 1px, transparent 1px 28px)',
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
          background: `radial-gradient(circle at 40% 50%, ${withAlpha(accent, 0.18)}, transparent 60%)`,
          filter: 'blur(22px)',
        }}
      />
    )
  }

  return null
}

function withAlpha(color: string | undefined | null, alpha: number): string {
  const value = String(color ?? '')
  const rgb = value.match(/^rgb\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\)$/)
  if (rgb) return `rgba(${rgb[1]}, ${rgb[2]}, ${rgb[3]}, ${alpha})`

  const rgba = value.match(/^rgba\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*[0-9.]+\s*\)$/)
  if (rgba) return `rgba(${rgba[1]}, ${rgba[2]}, ${rgba[3]}, ${alpha})`

  return 'rgba(255,255,255,0)'
}
