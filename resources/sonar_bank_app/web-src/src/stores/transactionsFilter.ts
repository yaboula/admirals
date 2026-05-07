import { create } from 'zustand'

/* ---------------------------------------------------------------------------
   BANK-FE.3 — Transactions filter store
   Pure local UI state. Reset() restores defaults; consumers derive their list
   via a single useMemo over (transactions, filter). Decoupled from data layer
   so it survives bootstrap re-fetches without flicker.
   --------------------------------------------------------------------------- */

export type TxRange = '7d' | '30d' | '90d' | 'all'
export type TxDirection = 'all' | 'in' | 'out'
export type TxStatus = 'all' | 'committed' | 'pending' | 'reverted'

export interface TransactionsFilterState {
  range: TxRange
  direction: TxDirection
  status: TxStatus
  query: string
  setRange: (r: TxRange) => void
  setDirection: (d: TxDirection) => void
  setStatus: (s: TxStatus) => void
  setQuery: (q: string) => void
  reset: () => void
}

const DEFAULT_STATE = {
  range: '30d' as TxRange,
  direction: 'all' as TxDirection,
  status: 'all' as TxStatus,
  query: '',
}

export const useTransactionsFilter = create<TransactionsFilterState>((set) => ({
  ...DEFAULT_STATE,
  setRange: (range) => set({ range }),
  setDirection: (direction) => set({ direction }),
  setStatus: (status) => set({ status }),
  setQuery: (query) => set({ query }),
  reset: () => set({ ...DEFAULT_STATE }),
}))

/* Helper: how many filters are NON-default (used for the active count badge). */
export function countActiveFilters(s: Pick<TransactionsFilterState, 'range' | 'direction' | 'status' | 'query'>): number {
  let n = 0
  if (s.range !== DEFAULT_STATE.range) n++
  if (s.direction !== DEFAULT_STATE.direction) n++
  if (s.status !== DEFAULT_STATE.status) n++
  if (s.query.trim().length > 0) n++
  return n
}
