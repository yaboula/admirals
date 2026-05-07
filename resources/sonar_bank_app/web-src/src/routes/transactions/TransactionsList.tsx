import { useMemo } from 'react'
import type { Transaction } from '@/data/contracts'
import { TransactionRow } from './TransactionRow'
import { TransactionsEmptyState, type TransactionsEmptyVariant } from './TransactionsEmptyState'

/**
 * BANK-FE.3 — Filtered list with sticky day separators.
 *
 * Groups transactions by calendar day (Spanish locale) and renders each group
 * with a subtle gradient separator above. The container OWNS its own scroll
 * (overflow-y-auto) so the page stays zero-scroll at the route level — only
 * the list pane scrolls.
 *
 * Empty / no-match states are rendered inline (not as a separate sibling) so
 * the parent layout grid keeps its 1fr center allocation steady.
 */
export interface TransactionsListProps {
  transactions: Transaction[]
  ownIban: string | undefined
  selectedTxnId: string | null
  onSelect: (tx: Transaction) => void
  emptyVariant: TransactionsEmptyVariant
  totalCount: number
}

export function TransactionsList({
  transactions,
  ownIban,
  selectedTxnId,
  onSelect,
  emptyVariant,
  totalCount,
}: TransactionsListProps) {
  const groups = useMemo(() => groupByDay(transactions), [transactions])

  if (transactions.length === 0) {
    return <TransactionsEmptyState variant={emptyVariant} totalCount={totalCount} />
  }

  let runningIndex = 0
  return (
    <div className="relative h-full min-h-0 overflow-y-auto pr-1 -mr-1">
      <div className="flex flex-col gap-3 pb-2">
        {groups.map((group) => (
          <section key={group.dayKey} className="flex flex-col gap-1">
            <DaySeparator label={group.label} count={group.items.length} totalAmount={group.netLabel} />
            <div className="flex flex-col gap-0.5">
              {group.items.map((tx) => {
                const idx = runningIndex++
                return (
                  <TransactionRow
                    key={tx.txn_id}
                    tx={tx}
                    ownIban={ownIban}
                    index={idx}
                    selected={tx.txn_id === selectedTxnId}
                    onSelect={onSelect}
                  />
                )
              })}
            </div>
          </section>
        ))}
      </div>
    </div>
  )
}

/* -------------------------------------------------------------------------- */

function DaySeparator({
  label,
  count,
  totalAmount,
}: {
  label: string
  count: number
  totalAmount: string
}) {
  return (
    <div className="sticky top-0 z-10 flex items-center gap-3 px-3 pt-2 pb-1.5 backdrop-blur-md bg-surface-abyss/65">
      <span className="text-[10px] uppercase tracking-[0.18em] text-text-secondary font-semibold">
        {label}
      </span>
      <span
        aria-hidden
        className="flex-1 h-px"
        style={{
          background:
            'linear-gradient(90deg, oklch(1 0 0 / 0.06) 0%, oklch(1 0 0 / 0.02) 50%, transparent 100%)',
        }}
      />
      <span className="text-[10px] text-text-tertiary tactile-tabular-nums">
        {count} mov.
      </span>
      <span className="text-[10px] font-medium text-text-tertiary tactile-tabular-nums">
        {totalAmount}
      </span>
    </div>
  )
}

/* -------------------------------------------------------------------------- */

interface DayGroup {
  dayKey: string
  label: string
  items: Transaction[]
  netLabel: string
}

function groupByDay(transactions: Transaction[]): DayGroup[] {
  const map = new Map<string, Transaction[]>()
  for (const t of transactions) {
    const d = new Date(t.timestamp_ms)
    const key = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`
    if (!map.has(key)) map.set(key, [])
    map.get(key)!.push(t)
  }
  const today = new Date()
  const todayKey = `${today.getFullYear()}-${today.getMonth()}-${today.getDate()}`
  const yesterday = new Date(today)
  yesterday.setDate(yesterday.getDate() - 1)
  const yesterdayKey = `${yesterday.getFullYear()}-${yesterday.getMonth()}-${yesterday.getDate()}`

  const result: DayGroup[] = []
  for (const [key, items] of map) {
    items.sort((a, b) => b.timestamp_ms - a.timestamp_ms)
    const first = items[0]!
    const d = new Date(first.timestamp_ms)
    let label: string
    if (key === todayKey) label = 'Hoy'
    else if (key === yesterdayKey) label = 'Ayer'
    else
      label = d.toLocaleDateString('es-ES', {
        weekday: 'long',
        day: 'numeric',
        month: 'short',
      })

    // Net label per day (small UX tooltip-like cue).
    let netMinor = 0
    for (const t of items) {
      if (t.status !== 'committed' && t.status !== 'pending') continue
      netMinor += t.direction === 'in' ? t.amount_minor : -t.amount_minor
    }
    const sign = netMinor >= 0 ? '+' : '−'
    const netLabel = `${sign}€${formatEur(Math.abs(netMinor) / 100)}`

    result.push({ dayKey: key, label, items, netLabel })
  }
  // Newest day first.
  result.sort((a, b) => b.items[0]!.timestamp_ms - a.items[0]!.timestamp_ms)
  return result
}

function formatEur(major: number): string {
  return new Intl.NumberFormat('es-ES', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(major)
}
