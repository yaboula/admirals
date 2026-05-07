import { useEffect, useMemo, useRef, useState } from 'react'
import type { Transaction } from '@/data/contracts'
import { TransactionRow } from './TransactionRow'
import { TransactionsEmptyState, type TransactionsEmptyVariant } from './TransactionsEmptyState'
import { cn } from '@/lib/utils'
import { maskSignedMoneyDisplay } from '@/lib/privacy'
import { usePrivacyMode } from '@/stores/privacy'

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
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  if (transactions.length === 0) {
    return <TransactionsEmptyState variant={emptyVariant} totalCount={totalCount} />
  }

  let runningIndex = 0
  return (
    <ScrollPane totalVisible={transactions.length}>
      <div className="flex flex-col gap-3 pb-2">
        {groups.map((group) => (
          <section key={group.dayKey} className="flex flex-col gap-1">
            <DaySeparator label={group.label} count={group.items.length} totalAmount={streamerMode ? maskSignedMoneyDisplay() : group.netLabel} />
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
    </ScrollPane>
  )
}

/* --------------------------------------------------------------------------
   ScrollPane — adds three professional scroll affordances:
   1. Top fade gradient:    fades content into card surface when scrolled down
   2. Bottom fade gradient: fades content into card surface when content remains
   3. Position pill:        bottom-right "N de Y" updating as user scrolls
   All three only render when content actually overflows the container.
   -------------------------------------------------------------------------- */

function ScrollPane({
  children,
  totalVisible,
}: {
  children: React.ReactNode
  totalVisible: number
}) {
  const scrollRef = useRef<HTMLDivElement | null>(null)
  const [overflowing, setOverflowing] = useState(false)
  const [atTop, setAtTop] = useState(true)
  const [atBottom, setAtBottom] = useState(false)
  const [scrolledIndex, setScrolledIndex] = useState(0)

  useEffect(() => {
    const el = scrollRef.current
    if (!el) return

    const compute = () => {
      const overflow = el.scrollHeight > el.clientHeight + 1
      setOverflowing(overflow)
      const top = el.scrollTop <= 2
      const bottom = el.scrollTop + el.clientHeight >= el.scrollHeight - 2
      setAtTop(top)
      setAtBottom(bottom)

      if (overflow && totalVisible > 0) {
        const ratio = el.scrollTop / Math.max(1, el.scrollHeight - el.clientHeight)
        const approxIndex = Math.min(
          totalVisible,
          Math.max(1, Math.round(ratio * (totalVisible - 1)) + 1),
        )
        setScrolledIndex(approxIndex)
      }
    }
    compute()
    el.addEventListener('scroll', compute, { passive: true })
    const ro = new ResizeObserver(compute)
    ro.observe(el)
    if (el.firstElementChild) ro.observe(el.firstElementChild as Element)
    return () => {
      el.removeEventListener('scroll', compute)
      ro.disconnect()
    }
  }, [totalVisible])

  return (
    <div className="relative h-full min-h-0">
      <div
        ref={scrollRef}
        className="relative h-full min-h-0 overflow-y-auto pr-1 -mr-1"
      >
        {children}
      </div>

      {/* Top fade — appears once user scrolls down */}
      <div
        aria-hidden
        className={cn(
          'pointer-events-none absolute left-0 right-0 top-0 h-6 transition-opacity duration-200',
          overflowing && !atTop ? 'opacity-100' : 'opacity-0',
        )}
        style={{
          background:
            'linear-gradient(180deg, oklch(0.04 0.005 270 / 0.85) 0%, oklch(0.04 0.005 270 / 0) 100%)',
        }}
      />

      {/* Bottom fade — appears whenever content remains below the fold */}
      <div
        aria-hidden
        className={cn(
          'pointer-events-none absolute left-0 right-0 bottom-0 h-8 transition-opacity duration-200',
          overflowing && !atBottom ? 'opacity-100' : 'opacity-0',
        )}
        style={{
          background:
            'linear-gradient(0deg, oklch(0.04 0.005 270 / 0.92) 0%, oklch(0.04 0.005 270 / 0) 100%)',
        }}
      />

      {/* Position pill — discreet 'N de Y' indicator anchored bottom-right */}
      {overflowing && totalVisible > 0 && (
        <div
          aria-hidden
          className={cn(
            'pointer-events-none absolute bottom-2 right-3 flex items-center gap-1.5',
            'px-2 py-1 rounded-full text-[10px] font-semibold tactile-tabular-nums',
            'transition-opacity duration-200',
            atBottom ? 'opacity-50' : 'opacity-90',
          )}
          style={{
            background: 'oklch(0.06 0.008 270 / 0.85)',
            border: '1px solid oklch(1 0 0 / 0.08)',
            color: 'var(--color-text-secondary)',
            backdropFilter: 'blur(8px)',
            boxShadow: '0 4px 12px -4px oklch(0 0 0 / 0.5)',
          }}
        >
          <span className="text-text-primary">{scrolledIndex}</span>
          <span className="text-text-tertiary">de</span>
          <span>{totalVisible}</span>
        </div>
      )}
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
