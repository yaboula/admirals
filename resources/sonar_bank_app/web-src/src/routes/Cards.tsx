import { useEffect } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import { useCards, useCardById } from '@/data/queries'
import { useCardsUi } from '@/stores/cardsUi'
import { Card } from '@/components/ui'
import { CardsHero } from './cards/CardsHero'
import { CardCarousel } from './cards/CardCarousel'
import { CardDetails } from './cards/CardDetails'
import { RequestCardBanner } from './cards/RequestCardBanner'
import { RequestFirstCardPanel } from './cards/RequestFirstCardPanel'
import { LimitsModal } from './cards/LimitsModal'

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

  // ESC closes the issue dialog (limits dialog handles its own key listener).
  useEffect(() => {
    if (dialog !== 'issue') return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        closeDialog()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [dialog, closeDialog])

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
      <div aria-hidden className="pointer-events-none absolute inset-0 opacity-70">
        <div className="absolute left-[18%] top-[2%] h-72 w-72 rounded-full bg-[oklch(0.65_0.22_40_/_0.10)] blur-[96px]" />
        <div className="absolute bottom-[4%] right-[8%] h-80 w-80 rounded-full bg-[rgba(89,137,255,0.10)] blur-[104px]" />
        <div className="absolute inset-0 bg-[linear-gradient(135deg,rgba(255,255,255,0.035),transparent_32%,rgba(255,255,255,0.025))]" />
      </div>
      <div
        className="relative h-full w-full mx-auto max-w-[1500px] gap-3 2xl:gap-5"
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
          <div className="flex items-center justify-between gap-3">
            <CardsHero totalCount={cards.length} activeCount={activeCount} />
          </div>

          <Card
            variant="glass"
            padding="md"
            className="min-h-0 border-white/10 flex flex-col gap-3 2xl:gap-4 overflow-hidden"
          >
            <div className="flex-1 min-h-0 flex items-center justify-center overflow-visible">
              {cards.length === 0 ? (
                <div className="w-full mx-auto py-2">
                  <RequestFirstCardPanel />
                </div>
              ) : (
                <div className="w-full max-w-[480px] 2xl:max-w-[540px] mx-auto py-2">
                  <CardCarousel cards={cards} />
                </div>
              )}
            </div>
            {cards.length > 0 && <RequestCardBanner cardsCount={cards.length} />}
          </Card>
        </section>

        {/* ── DETAILS COLUMN ─────────────────────────────────────────── */}
        <aside className="h-full min-h-0 flex flex-col">
          <CardDetails card={focused} className="flex-1 min-h-0" />
        </aside>
      </div>

      {/* ── OVERLAYS ───────────────────────────────────────── */}
      <AnimatePresence>
      {dialog === 'issue' && (
        <>
          <motion.div
            key="issue-backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={closeDialog}
            className="fixed inset-0 z-[var(--z-modal-scrim)] bg-surface-modal-scrim backdrop-blur-md"
            aria-hidden
          />
          <motion.div
            key="issue-panel"
            initial={{ scale: 0.96, opacity: 0, y: 12 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.97, opacity: 0, y: 8 }}
            transition={{ duration: 0.26, ease: [0.16, 1, 0.3, 1] }}
            className="fixed inset-0 z-[var(--z-modal)] flex items-center justify-center p-3 sm:p-5 lg:p-8"
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="relative w-full max-w-[1100px] scrollbar-thin"
              style={{ maxHeight: 'calc(100vh - 2rem)', overflowY: 'auto', borderRadius: '1.65rem' }}
            >
              <RequestFirstCardPanel isInitial={false} onClose={closeDialog} />
            </div>
          </motion.div>
        </>
      )}
      </AnimatePresence>
      <LimitsModal
        card={focusedForDialog}
        open={dialog === 'limits'}
        onClose={closeDialog}
      />
    </motion.div>
  )
}
