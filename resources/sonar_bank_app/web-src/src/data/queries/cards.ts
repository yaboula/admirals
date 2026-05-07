import { useMemo } from 'react'
import type { BankCardMock } from '@/data/contracts'
import { useBootstrap } from './bootstrap'

/* ---------------------------------------------------------------------------
   BANK-FE.4.2 — Cards selector

   Phase A reads cards from the bootstrap snapshot (REQ-FE-001 already includes
   the `cards: BankCardMock[]` array). When BE delivers a dedicated, paginated
   cards endpoint (likely C012 in the contract roadmap) we'll swap the
   internals here without touching consumers.

   Sort order is stable: active cards first, then locked, then expired. Within
   each bucket we preserve original index so the carousel doesn't jump if the
   user switches accounts mid-session.
   --------------------------------------------------------------------------- */

export interface UseCardsResult {
  cards: BankCardMock[]
  isLoading: boolean
  isError: boolean
}

const STATUS_RANK: Record<BankCardMock['status'], number> = {
  active: 0,
  pending: 1,
  locked: 2,
  expired: 3,
}

export function useCards(): UseCardsResult {
  const { data, isLoading, isError } = useBootstrap()

  const cards = useMemo<BankCardMock[]>(() => {
    if (!data) return []
    const indexed = data.cards.map((c, i) => ({ c, i }))
    indexed.sort((a, b) => {
      const ra = STATUS_RANK[a.c.status] ?? 9
      const rb = STATUS_RANK[b.c.status] ?? 9
      if (ra !== rb) return ra - rb
      return a.i - b.i
    })
    return indexed.map((x) => x.c)
  }, [data])

  return { cards, isLoading, isError }
}

/** Resolve a single card by id (memoised). Returns null when not found. */
export function useCardById(id: string | null | undefined): BankCardMock | null {
  const { cards } = useCards()
  return useMemo(() => {
    if (!id) return null
    return cards.find((c) => c.card_id === id) ?? null
  }, [cards, id])
}
