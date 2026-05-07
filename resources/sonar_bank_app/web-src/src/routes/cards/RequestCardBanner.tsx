import { motion, useReducedMotion } from 'motion/react'
import { ArrowRight, Sparkles } from 'lucide-react'
import { CARD_DESIGNS } from './cardDesigns'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { useCardsUi } from '@/stores/cardsUi'

export interface RequestCardBannerProps {
  className?: string
}

export function RequestCardBanner({ className }: RequestCardBannerProps) {
  const reduced = useReducedMotion()
  const selectedCardId = useCardsUi((s) => s.selectedCardId)
  const openDialog = useCardsUi((s) => s.openDialog)
  const ctaDisabled = !selectedCardId

  const handleStart = () => {
    if (!selectedCardId) return
    sfx.panel_open()
    openDialog('design', selectedCardId)
  }

  return (
    <motion.div
      initial={reduced ? false : { opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.32, delay: 0.12, ease: [0.16, 1, 0.3, 1] }}
      className={cn(
        'relative flex items-center gap-3 2xl:gap-4 rounded-xl px-3 py-2.5 2xl:px-4 2xl:py-3 overflow-hidden',
        className,
      )}
      style={{
        background:
          'linear-gradient(135deg, oklch(0.18 0.05 35 / 0.80), oklch(0.08 0.018 270 / 0.72))',
        border: '1px solid oklch(1 0 0 / 0.09)',
        boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.08), 0 18px 42px -30px oklch(0.70 0.22 40 / 0.55)',
      }}
    >
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 18% 10%, oklch(0.72 0.22 40 / 0.34), transparent 38%), radial-gradient(circle at 88% 20%, oklch(1 0 0 / 0.10), transparent 32%)',
        }}
      />
      <div className="relative flex items-center -space-x-1.5 shrink-0">
        {CARD_DESIGNS.map((design, i) => (
          <DesignSwatch key={design.id} surface={design.surface} index={i} />
        ))}
      </div>
      <div className="relative flex flex-col leading-tight min-w-0 flex-1">
        <div className="inline-flex items-center gap-1.5">
          <Sparkles size={10} strokeWidth={2} className="text-white/70" />
          <span className="text-[9px] uppercase tracking-[0.18em] text-white/70 font-semibold">
            Personaliza tu tarjeta
          </span>
        </div>
        <p className="text-xs 2xl:text-sm font-semibold text-white tactile-wght-breathing tracking-tight truncate">
          Elige un diseño con la misma seguridad
        </p>
        <p className="hidden 2xl:block text-[11px] text-white/60 mt-0.5">
          4 acabados disponibles para tu tarjeta activa
        </p>
      </div>
      <button
        type="button"
        onClick={handleStart}
        disabled={ctaDisabled}
        title={ctaDisabled ? 'Selecciona una tarjeta primero' : undefined}
        aria-label="Abrir selector de diseño"
        className={cn(
          'relative inline-flex items-center gap-1.5 px-3 py-2 rounded-lg shrink-0',
          'text-xs font-semibold transition-all duration-180',
          ctaDisabled
            ? 'cursor-not-allowed opacity-50'
            : 'enabled:hover:-translate-y-0.5 enabled:active:scale-[0.98]',
        )}
        style={{
          background: ctaDisabled ? 'oklch(1 0 0 / 0.08)' : 'oklch(1 0 0 / 0.92)',
          border: '1px solid oklch(1 0 0 / 0.18)',
          color: ctaDisabled ? 'oklch(0.85 0.012 270)' : 'oklch(0.08 0.01 270)',
          boxShadow: ctaDisabled ? 'none' : '0 14px 24px -18px oklch(0 0 0 / 0.85)',
        }}
      >
        <span>Diseñar</span>
        <ArrowRight size={12} strokeWidth={2} />
      </button>
    </motion.div>
  )
}

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
