import { create } from 'zustand'

/* ---------------------------------------------------------------------------
   BANK-FE.4.2 — Cards UI store

   Pure ephemeral state for the /tarjetas route. Decoupled from data so the
   store survives bootstrap refetches and route re-mounts without losing
   selection or reveal context.

   - selectedCardId  : the card currently in focus (front of the carousel).
                       null = first card (resolved at render time so the store
                       never holds a stale id when the cards list changes).
   - flippedCardIds  : per-card flip state (Set semantics → toggling N cards
                       does not bleed into the others).
   - revealedCardIds : per-card PAN-reveal state. Same set-style isolation so
                       revealing one card doesn't unmask the others.

   We use plain string arrays internally instead of `Set` because Zustand's
   shallow comparator is reference-based and a Set would force consumers to
   subscribe with custom selectors. Arrays compare by reference per `set()`.
   --------------------------------------------------------------------------- */

export interface CardsUiState {
  selectedCardId: string | null
  flippedCardIds: string[]
  revealedCardIds: string[]
  setSelected: (id: string) => void
  toggleFlip: (id: string) => void
  toggleReveal: (id: string) => void
  reset: () => void
}

const DEFAULT_STATE: Pick<
  CardsUiState,
  'selectedCardId' | 'flippedCardIds' | 'revealedCardIds'
> = {
  selectedCardId: null,
  flippedCardIds: [],
  revealedCardIds: [],
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
  toggleReveal: (id) =>
    set((s) => ({
      revealedCardIds: s.revealedCardIds.includes(id)
        ? s.revealedCardIds.filter((x) => x !== id)
        : [...s.revealedCardIds, id],
    })),
  reset: () => set({ ...DEFAULT_STATE }),
}))
