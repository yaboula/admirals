import { useEffect, useState } from 'react'
import { create } from 'zustand'

/* ---------------------------------------------------------------------------
   BANK-FE.4.2 + 4.3 — Cards UI store

   Pure ephemeral state for the /tarjetas route. Decoupled from data so the
   store survives bootstrap refetches and route re-mounts without losing
   selection, reveal context or open dialogs.

   - selectedCardId       : focused card in the carousel.
   - flippedCardIds       : per-card flip state (Set semantics via array).
   - revealedUntil        : per-card PAN reveal expiry timestamp (ms epoch).
                             A card is considered revealed iff
                             revealedUntil[cardId] > Date.now(). Phase 4.3 sets
                             this to Date.now() + 30_000 — the front auto-hides
                             after 30s without persisting the secret.
   - dialog               : which modal is currently open ('limits' | 'design'
                             | null) plus the cardId it operates on.

   Decision deviation: we expose isRevealed() as a getState-aware helper but
   consumers should subscribe to `revealedUntil[cardId]` directly to react to
   the countdown ticking down to zero. A 1-Hz heartbeat in CardDetails forces
   re-evaluation as the timestamp passes.
   --------------------------------------------------------------------------- */

export type CardDialog = 'limits' | 'design' | null

export interface CardsUiState {
  selectedCardId: string | null
  flippedCardIds: string[]
  revealedUntil: Record<string, number>
  dialog: CardDialog
  dialogCardId: string | null

  setSelected: (id: string) => void
  toggleFlip: (id: string) => void

  /** Reveal a card's PAN for `ttlMs` (default 30s). */
  revealCard: (id: string, ttlMs?: number) => void
  /** Force-hide reveal regardless of remaining TTL. */
  hideReveal: (id: string) => void

  /** Open a dialog for a specific card. */
  openDialog: (dialog: Exclude<CardDialog, null>, cardId: string) => void
  closeDialog: () => void

  reset: () => void
}

const REVEAL_TTL_MS = 30_000

const DEFAULT_STATE: Pick<
  CardsUiState,
  'selectedCardId' | 'flippedCardIds' | 'revealedUntil' | 'dialog' | 'dialogCardId'
> = {
  selectedCardId: null,
  flippedCardIds: [],
  revealedUntil: {},
  dialog: null,
  dialogCardId: null,
}

export const useCardsUi = create<CardsUiState>((set) => ({
  ...DEFAULT_STATE,
  setSelected: (id) => set({ selectedCardId: id }),
  toggleFlip: (id) =>
    set((s) => ({
      flippedCardIds: s.flippedCardIds.includes(id)
        ? s.flippedCardIds.filter((x) => x !== id)
        : [...s.flippedCardIds, id],
    })),
  revealCard: (id, ttlMs = REVEAL_TTL_MS) =>
    set((s) => ({
      revealedUntil: { ...s.revealedUntil, [id]: Date.now() + ttlMs },
    })),
  hideReveal: (id) =>
    set((s) => {
      if (!(id in s.revealedUntil)) return s
      const next = { ...s.revealedUntil }
      delete next[id]
      return { revealedUntil: next }
    }),
  openDialog: (dialog, cardId) => set({ dialog, dialogCardId: cardId }),
  closeDialog: () => set({ dialog: null, dialogCardId: null }),
  reset: () => set({ ...DEFAULT_STATE }),
}))

/** Pure check — does NOT subscribe; consumers should subscribe to revealedUntil[id]. */
export function isCardRevealed(state: CardsUiState, cardId: string): boolean {
  const expiry = state.revealedUntil[cardId]
  if (typeof expiry !== 'number') return false
  return expiry > Date.now()
}

/* ---------------------------------------------------------------------------
   useCardReveal — subscribe-and-tick hook bundled here because reveal state
   is tightly coupled to the store. Returns:
     - revealed     : boolean derived from the expiry timestamp
     - remainingMs  : milliseconds until auto-hide (0 when not revealed)
     - reveal()     : start a fresh 30s window
     - hide()       : force-hide the PAN immediately
   The 1Hz interval only runs while a card is revealed → no idle CPU cost.
   --------------------------------------------------------------------------- */

export interface UseCardRevealResult {
  revealed: boolean
  remainingMs: number
  reveal: (ttlMs?: number) => void
  hide: () => void
}

export function useCardReveal(cardId: string): UseCardRevealResult {
  const expiry = useCardsUi((s) => s.revealedUntil[cardId])
  const revealCard = useCardsUi((s) => s.revealCard)
  const hideReveal = useCardsUi((s) => s.hideReveal)

  // Heartbeat: when an expiry is set in the future, tick every 1s so the
  // derived `revealed` flag flips off as soon as the deadline passes.
  const [, setTick] = useState(0)
  useEffect(() => {
    if (typeof expiry !== 'number') return
    const remaining = expiry - Date.now()
    if (remaining <= 0) {
      // Already expired — schedule a final state cleanup next tick.
      hideReveal(cardId)
      return
    }
    const interval = window.setInterval(() => setTick((n) => n + 1), 1000)
    const finalTimeout = window.setTimeout(() => {
      hideReveal(cardId)
    }, remaining + 50)
    return () => {
      window.clearInterval(interval)
      window.clearTimeout(finalTimeout)
    }
  }, [expiry, cardId, hideReveal])

  const remainingMs = typeof expiry === 'number' ? Math.max(0, expiry - Date.now()) : 0
  const revealed = remainingMs > 0

  return {
    revealed,
    remainingMs,
    reveal: (ttlMs) => revealCard(cardId, ttlMs),
    hide: () => hideReveal(cardId),
  }
}
