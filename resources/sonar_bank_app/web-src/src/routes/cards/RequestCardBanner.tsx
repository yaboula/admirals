import { motion, useReducedMotion } from 'motion/react'
import { ArrowRight, Sparkles } from 'lucide-react'
import { CARD_DESIGNS } from './cardDesigns'
import { cn } from '@/lib/utils'

/**
 * BANK-FE.4.2 — RequestCardBanner
 *
 * Compact CTA strip placed below the carousel that introduces the design
 * picker (Phase 4.4) without committing to it. Uses the existing 4 design
 * recipes as live swatches — the user understands at a glance that the
 * picker exists and what variety is on offer.
 *
 * Phase 4.2 leaves the CTA as a disabled placeholder (Phase 4.4 wires the
 * design-picker route + apply mutation). The disabled state keeps the
 * affordance visible so the layout already accommodates the eventual click
 * target — no relayout when the feature lights up.
 */
export interface RequestCardBannerProps {
  className?: string
}

export function RequestCardBanner({ className }: RequestCardBannerProps) {
  const reduced = useReducedMotion()

  return (
    <motion.div
      initial={reduced ? false : { opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.32, delay: 0.12, ease: [0.16, 1, 0.3, 1] }}
      className={cn(
        'relative flex items-center gap-3 2xl:gap-4 rounded-xl px-3 py-2.5 2xl:px-4 2xl:py-3',
        className,
      )}
      style={{
        background: 'oklch(1 0 0 / 0.025)',
        border: '1px solid oklch(1 0 0 / 0.07)',
        boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.04)',
      }}
    >
      {/* ── Swatch column — 4 mini cards stacked horizontally ── */}
      <div className="flex items-center -space-x-1.5 shrink-0">
        {CARD_DESIGNS.map((design, i) => (
          <DesignSwatch key={design.id} surface={design.surface} index={i} />
        ))}
      </div>

      {/* ── Copy column ── */}
      <div className="flex flex-col leading-tight min-w-0 flex-1">
        <div className="inline-flex items-center gap-1.5">
          <Sparkles size={10} strokeWidth={2} className="text-text-tertiary opacity-70" />
          <span className="text-[9px] uppercase tracking-[0.18em] text-text-tertiary font-semibold">
            Pide tu próxima tarjeta
          </span>
        </div>
        <p className="text-xs 2xl:text-sm font-semibold text-text-primary tactile-wght-breathing tracking-tight truncate">
          Diseña, elige límites y recíbela en segundos
        </p>
        <p className="hidden 2xl:block text-[11px] text-text-tertiary mt-0.5">
          4 diseños disponibles · débito, virtual o crédito
        </p>
      </div>

      {/* ── CTA — disabled placeholder for Phase 4.4 ── */}
      <button
        type="button"
        disabled
        title="Disponible próximamente"
        className={cn(
          'inline-flex items-center gap-1.5 px-3 py-2 rounded-lg shrink-0',
          'text-xs font-semibold cursor-not-allowed opacity-60',
          'transition-colors duration-180',
        )}
        style={{
          background: 'oklch(1 0 0 / 0.05)',
          border: '1px solid oklch(1 0 0 / 0.10)',
          color: 'oklch(0.85 0.012 270)',
        }}
      >
        <span>Empezar</span>
        <ArrowRight size={12} strokeWidth={2} />
      </button>
    </motion.div>
  )
}

/* --------------------------------------------------------------------------
   Sub-components
   -------------------------------------------------------------------------- */

/**
 * Mini horizontal card swatch (16x10 px) showing a design's surface gradient.
 * Slight overlap (-space-x-1.5 on parent) creates the stacked-cards aesthetic
 * that hints at the variety available behind the CTA.
 */
function DesignSwatch({ surface, index }: { surface: string; index: number }) {
  return (
    <motion.div
      initial={false}
      animate={{ rotate: (index - 1.5) * 4 }}
      transition={{ type: 'spring', stiffness: 200, damping: 22 }}
      className="relative h-7 w-11 rounded-md overflow-hidden"
      style={{
        background: surface,
        border: '1px solid oklch(1 0 0 / 0.18)',
        boxShadow: '0 2px 6px -2px oklch(0 0 0 / 0.6), inset 0 1px 0 oklch(1 0 0 / 0.08)',
      }}
      aria-hidden
    >
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'linear-gradient(115deg, transparent 30%, oklch(1 0 0 / 0.12) 50%, transparent 70%)',
          mixBlendMode: 'overlay',
        }}
      />
    </motion.div>
  )
}
