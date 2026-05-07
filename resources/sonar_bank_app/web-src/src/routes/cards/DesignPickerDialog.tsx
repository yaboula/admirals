import { useEffect, useState } from 'react'
import { motion, AnimatePresence, useReducedMotion } from 'motion/react'
import { X, Check, Sparkles } from 'lucide-react'
import type { BankCardMock } from '@/data/contracts'
import { useApplyCardDesign } from '@/data/mutations'
import { CARD_DESIGNS, resolveCardDesign, type CardDesign } from './cardDesigns'
import { CardVisual } from './CardVisual'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { toast } from '@/stores/toast'
import { handleBankError } from '@/lib/bankError'

/**
 * BANK-FE.4.4 — DesignPickerDialog
 *
 * Wide centred dialog that lets the user audition the available designs against
 * their actual card. Layout (top → bottom):
 *
 *   1. Header — title + tagline (changes per selected design) + close
 *   2. Preview — full-size CardVisual rendered with the selected design
 *      applied to the user's card. AnimatePresence keyed on designId
 *      crossfades between recipes so changing selection feels alive.
 *   3. Gallery — mini cards, each showing the design applied to the
 *      user's data. Click selects (sets the local draft); active design
 *      gets a glowing accent ring.
 *   4. Footer — Cancel + Apply (disabled if selection equals current).
 *
 * Apply fires `useApplyCardDesign` which optimistically patches the
 * bootstrap snapshot. The carousel + CardDetails react instantly through
 * the shared cache — the dialog can close without waiting for settle.
 *
 * Reduced motion: preview crossfade falls back to instant swap; the
 * gallery still highlights the active card via a static border.
 */
export interface DesignPickerDialogProps {
  card: BankCardMock | null
  open: boolean
  onClose: () => void
}

export function DesignPickerDialog({ card, open, onClose }: DesignPickerDialogProps) {
  const reduced = useReducedMotion()
  const mutation = useApplyCardDesign()

  const [selectedId, setSelectedId] = useState<string>('')

  // Hydrate the local selection from the card whenever the dialog (re)opens.
  useEffect(() => {
    if (open && card) {
      setSelectedId(card.design_id || CARD_DESIGNS[0]?.id || '')
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

  if (!card) {
    return null
  }

  const selectedDesign = resolveCardDesign(selectedId)
  const dirty = selectedId !== card.design_id

  const handleApply = () => {
    if (!dirty) return
    sfx.console_tap()
    mutation.mutate(
      { cardId: card.card_id, designId: selectedId },
      {
        onSuccess: () => {
          toast.success(
            'Diseño aplicado',
            `Tu tarjeta ahora luce el diseño ${selectedDesign.name}.`,
          )
          onClose()
        },
        onError: (err) => {
          handleBankError(err)
        },
      },
    )
  }

  const handleSelect = (designId: string) => {
    if (designId === selectedId) return
    sfx.console_tap()
    setSelectedId(designId)
  }

  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Backdrop */}
          <motion.div
            key="design-backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: reduced ? 0 : 0.20 }}
            onClick={onClose}
            className="absolute inset-0 z-[var(--z-drawer-scrim)] bg-surface-modal-scrim backdrop-blur-sm"
            aria-hidden
          />

          {/* Panel — wider centred dialog (gallery needs horizontal room) */}
          <motion.div
            key="design-panel"
            role="dialog"
            aria-modal="true"
            aria-label="Elegir diseño de tarjeta"
            initial={reduced ? { opacity: 0 } : { opacity: 0, y: 16, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduced ? { opacity: 0 } : { opacity: 0, y: 8, scale: 0.98 }}
            transition={
              reduced
                ? { duration: 0.18 }
                : { type: 'spring', stiffness: 280, damping: 28, mass: 0.9 }
            }
            className={cn(
              'absolute left-1/2 top-1/2 z-[var(--z-drawer)]',
              '-translate-x-1/2 -translate-y-1/2',
              'w-[min(720px,calc(100vw-32px))]',
              'max-h-[calc(100vh-32px)]',
              'rounded-2xl border border-white/10 overflow-hidden',
              'flex flex-col',
            )}
            style={{
              background: 'linear-gradient(180deg, oklch(0.10 0.012 270) 0%, oklch(0.04 0.006 270) 100%)',
              boxShadow:
                '0 24px 64px -16px oklch(0 0 0 / 0.7), 0 4px 12px -4px oklch(0 0 0 / 0.5), inset 0 1px 0 oklch(1 0 0 / 0.06)',
            }}
          >
            {/* Header */}
            <div className="flex items-start justify-between gap-3 px-5 pt-5 pb-3">
              <div className="flex flex-col leading-tight min-w-0">
                <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">
                  Diseño · ···· {card.pan_last_four}
                </span>
                <AnimatePresence mode="wait">
                  <motion.h2
                    key={selectedDesign.id}
                    initial={reduced ? false : { opacity: 0, y: 4 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={reduced ? { opacity: 0 } : { opacity: 0, y: -4 }}
                    transition={{ duration: 0.20 }}
                    className="text-base font-semibold text-text-primary tactile-wght-breathing tracking-tight truncate"
                  >
                    {selectedDesign.name}
                    <span className="ml-2 text-xs font-normal text-text-tertiary">
                      · {selectedDesign.tagline}
                    </span>
                  </motion.h2>
                </AnimatePresence>
              </div>
              <button
                type="button"
                onClick={onClose}
                aria-label="Cerrar"
                className="inline-flex items-center justify-center h-7 w-7 rounded-full text-text-tertiary hover:text-text-primary hover:bg-white/5 transition-colors shrink-0"
              >
                <X size={14} strokeWidth={2} />
              </button>
            </div>

            {/* Preview stage — large card with crossfade between designs */}
            <div className="px-5 pb-4">
              <div
                className="relative w-full mx-auto rounded-2xl"
                style={{ maxWidth: 360 }}
              >
                <AnimatePresence mode="wait">
                  <motion.div
                    key={selectedDesign.id}
                    initial={reduced ? false : { opacity: 0, scale: 0.96, rotateY: -6 }}
                    animate={{ opacity: 1, scale: 1, rotateY: 0 }}
                    exit={reduced ? { opacity: 0 } : { opacity: 0, scale: 0.97, rotateY: 6 }}
                    transition={
                      reduced
                        ? { duration: 0.18 }
                        : { type: 'spring', stiffness: 240, damping: 24, mass: 0.95 }
                    }
                    style={{ perspective: 1400 }}
                  >
                    <CardVisual card={card} design={selectedDesign} />
                  </motion.div>
                </AnimatePresence>

                {/* Halo glow that inherits the selected design accent */}
                <motion.div
                  aria-hidden
                  className="absolute inset-0 -z-10 rounded-2xl pointer-events-none"
                  animate={{
                    boxShadow: `0 30px 70px -20px ${selectedDesign.accent}, 0 0 80px -20px ${selectedDesign.accent}`,
                  }}
                  transition={{ duration: 0.4 }}
                />
              </div>
            </div>

            {/* Gallery */}
            <div className="px-5 pb-3 grid grid-cols-2 lg:grid-cols-3 gap-3 overflow-y-auto scrollbar-thin max-h-[240px]">
              {CARD_DESIGNS.map((d) => (
                <DesignTile
                  key={d.id}
                  design={d}
                  card={card}
                  selected={selectedId === d.id}
                  current={card.design_id === d.id}
                  onSelect={() => handleSelect(d.id)}
                />
              ))}
            </div>

            {/* Footer */}
            <div
              className="flex items-center justify-between gap-2 px-5 pt-3 pb-5 border-t mt-auto"
              style={{ borderColor: 'oklch(1 0 0 / 0.06)' }}
            >
              <div className="flex items-center gap-1.5 text-[11px] text-text-tertiary min-w-0">
                <Sparkles size={10} strokeWidth={1.8} className="shrink-0" />
                <span className="truncate">
                  Cambiar el diseño no afecta a tus saldos ni tus operaciones.
                </span>
              </div>
              <div className="flex items-center gap-2 shrink-0">
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
                  Cancelar
                </button>
                <button
                  type="button"
                  onClick={handleApply}
                  disabled={!dirty || mutation.isPending}
                  className={cn(
                    'inline-flex items-center gap-1.5 px-3 h-8 rounded-lg text-xs font-semibold',
                    'transition-all duration-180',
                    'disabled:opacity-40 disabled:cursor-not-allowed',
                    'enabled:hover:brightness-110 enabled:active:scale-[0.98]',
                  )}
                  style={{
                    background: !dirty ? 'oklch(1 0 0 / 0.06)' : selectedDesign.accent,
                    color: !dirty ? 'oklch(0.78 0.012 270)' : 'oklch(0.10 0.012 270)',
                    border: '1px solid oklch(1 0 0 / 0.10)',
                    boxShadow: !dirty ? 'none' : `0 0 18px -4px ${selectedDesign.accent}`,
                  }}
                >
                  <Check size={12} strokeWidth={2.4} />
                  {mutation.isPending ? 'Aplicando…' : 'Aplicar diseño'}
                </button>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}

/* --------------------------------------------------------------------------
   DesignTile — gallery item.
   Hover: lift + border glow.  Selected: accent border + check badge.
   "Actual" pill marks the card's currently-applied design so the user can
   tell at a glance which one they're moving away from.
   -------------------------------------------------------------------------- */
function DesignTile({
  design,
  card,
  selected,
  current,
  onSelect,
}: {
  design: CardDesign
  card: BankCardMock
  selected: boolean
  current: boolean
  onSelect: () => void
}) {
  return (
    <button
      type="button"
      onClick={onSelect}
      aria-pressed={selected}
      aria-label={`Diseño ${design.name}`}
      className={cn(
        'relative flex flex-col gap-2 p-2 rounded-xl text-left',
        'transition-all duration-200',
        'hover:-translate-y-0.5 active:scale-[0.98]',
      )}
      style={{
        background: selected ? 'oklch(1 0 0 / 0.05)' : 'oklch(1 0 0 / 0.02)',
        border: `1px solid ${
          selected ? design.accent : 'oklch(1 0 0 / 0.08)'
        }`,
        boxShadow: selected ? `0 0 16px -4px ${design.accent}` : 'none',
      }}
    >
      {/* Compact card preview */}
      <div className="relative">
        <CardVisual card={card} design={design} compact />
        {selected && (
          <motion.span
            initial={{ scale: 0, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ type: 'spring', stiffness: 380, damping: 22 }}
            className="absolute top-1.5 right-1.5 inline-flex items-center justify-center h-5 w-5 rounded-full"
            style={{
              background: design.accent,
              color: 'oklch(0.10 0.012 270)',
              boxShadow: `0 0 10px -1px ${design.accent}`,
            }}
            aria-hidden
          >
            <Check size={11} strokeWidth={3} />
          </motion.span>
        )}
      </div>

      {/* Caption */}
      <div className="flex items-center justify-between gap-1.5 px-0.5">
        <div className="flex flex-col leading-tight min-w-0">
          <span
            className={cn(
              'text-xs font-semibold truncate',
              selected ? 'text-text-primary' : 'text-text-secondary',
            )}
          >
            {design.name}
          </span>
          <span className="text-[9px] uppercase tracking-[0.16em] text-text-tertiary font-medium">
            {tierLabel(design.tier)}
          </span>
        </div>
        {current && (
          <span
            className="text-[8px] uppercase tracking-[0.16em] font-semibold px-1.5 py-0.5 rounded shrink-0"
            style={{
              color: 'oklch(0.78 0.012 270)',
              background: 'oklch(1 0 0 / 0.05)',
              border: '1px solid oklch(1 0 0 / 0.10)',
            }}
          >
            Actual
          </span>
        )}
      </div>
    </button>
  )
}

function tierLabel(tier: CardDesign['tier']): string {
  return tier === 'signature' ? 'Signature' : tier === 'premium' ? 'Premium' : 'Estándar'
}
