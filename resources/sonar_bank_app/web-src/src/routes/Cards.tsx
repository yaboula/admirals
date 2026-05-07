import { useEffect } from 'react'
import { motion } from 'motion/react'
import { useCards, useCardById } from '@/data/queries'
import { useCardsUi } from '@/stores/cardsUi'
import { Card } from '@/components/ui'
import { CardsHero } from './cards/CardsHero'
import { CardCarousel } from './cards/CardCarousel'
import { CardDetails } from './cards/CardDetails'
import { RequestCardBanner } from './cards/RequestCardBanner'
import { LimitsModal } from './cards/LimitsModal'
import { DesignPickerDialog } from './cards/DesignPickerDialog'

/**
 * BANK-FE.4.2 — Vista Tarjetas (route /tarjetas).
 *
 * Layout (zero page-level scroll, two columns inside the AppShell):
 *
 *   ┌──────── carousel column (1.4fr) ────────┬──── details column (1fr) ────┐
 *   │ CardsHero (auto · title + counts)        │                                │
 *   ├──────────────────────────────────────────┤   CardDetails                  │
 *   │ CardCarousel (1fr)                       │   (1fr · focused card meta     │
 *   │   - 3D stack (focused + ±1 + ±2)         │    + limits preview            │
 *   │   - flip front/back on focused card      │    + reveal/flip/freeze/lim    │
 *   │   - dots + prev/next + drag commit       │    actions)                    │
 *   └──────────────────────────────────────────┴────────────────────────────────┘
 *
 * Phase 4.2 keeps Freeze and Limits as disabled placeholders inside
 * CardDetails so the layout already accommodates the action surface that
 * Phase 4.3 will wire to live mutations.
 *
 * Reduced motion is honoured by CardCarousel + CardFlip: layout positions
 * stay (otherwise neighbours collapse onto the focus) but spring is replaced
 * with a 180ms tween, and the flip becomes an instant cross-fade.
 */
export function Cards() {
  const { cards } = useCards()
  const selectedCardId = useCardsUi((s) => s.selectedCardId)
  const setSelected = useCardsUi((s) => s.setSelected)
  const dialog = useCardsUi((s) => s.dialog)
  const dialogCardId = useCardsUi((s) => s.dialogCardId)
  const closeDialog = useCardsUi((s) => s.closeDialog)

  // Bind the store to the resolved focused card, gracefully handling the
  // empty list and a stale id that no longer exists in the resolved set.
  useEffect(() => {
    if (cards.length === 0) return
    const exists = selectedCardId && cards.some((c) => c.card_id === selectedCardId)
    if (!exists && cards[0]) {
      setSelected(cards[0].card_id)
    }
  }, [cards, selectedCardId, setSelected])

  const focused =
    cards.find((c) => c.card_id === selectedCardId) ?? cards[0] ?? null
  const activeCount = cards.filter((c) => c.status === 'active').length

  // Resolve the dialog target via the cache so the modals stay in sync if
  // the cards list reorders mid-edit (e.g. status flip moves a card to the
  // front of the list while LimitsModal is open).
  const dialogCard = useCardById(dialogCardId)
  const focusedForDialog = dialogCard ?? focused

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
      className="relative h-full w-full overflow-hidden"
    >
      <div
        className="h-full w-full mx-auto max-w-[1500px] gap-3 2xl:gap-5"
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1.4fr) minmax(280px, 1fr)',
          gridTemplateRows: '1fr',
        }}
      >
        {/* ── CAROUSEL COLUMN ────────────────────────────────────────── */}
        <section
          className="h-full min-h-0 gap-3 2xl:gap-4"
          style={{
            display: 'grid',
            gridTemplateRows: 'auto 1fr',
          }}
        >
          <CardsHero totalCount={cards.length} activeCount={activeCount} />

          <Card
            variant="glass"
            padding="md"
            className="min-h-0 border-white/10 flex flex-col gap-3 2xl:gap-4 overflow-hidden"
          >
            {/* Stage — fills remaining height, carousel centred both axes. */}
            <div className="flex-1 min-h-0 flex items-center justify-center">
              <div className="w-full max-w-[480px] 2xl:max-w-[540px] mx-auto">
                <CardCarousel cards={cards} />
              </div>
            </div>

            {/* Hairline divider — visual seam between carousel and banner. */}
            <div
              aria-hidden
              className="h-px"
              style={{
                background:
                  'linear-gradient(90deg, transparent 0%, oklch(1 0 0 / 0.10) 50%, transparent 100%)',
              }}
            />

            {/* Bottom banner — discoverability for the design picker (Phase 4.4). */}
            <RequestCardBanner />
          </Card>
        </section>

        {/* ── DETAILS COLUMN ─────────────────────────────────────────── */}
        <aside className="h-full min-h-0 flex flex-col">
          <CardDetails card={focused} className="flex-1 min-h-0" />
        </aside>
      </div>

      {/* ── OVERLAYS ───────────────────────────────────────── */}
      <LimitsModal
        card={focusedForDialog}
        open={dialog === 'limits'}
        onClose={closeDialog}
      />
      <DesignPickerDialog
        card={focusedForDialog}
        open={dialog === 'design'}
        onClose={closeDialog}
      />
    </motion.div>
  )
}

/**
 * Convenience export: opens the design picker for the currently focused card.
 * Used by the RequestCardBanner CTA so the banner can stay decoupled from
 * the route's local state.
 */
export function useOpenDesignPicker(): () => void {
  const openDialog = useCardsUi((s) => s.openDialog)
  const selectedCardId = useCardsUi((s) => s.selectedCardId)
  return () => {
    if (selectedCardId) openDialog('design', selectedCardId)
  }
}
