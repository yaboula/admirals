import { useEffect, useMemo, useState } from 'react'
import { motion } from 'motion/react'
import { useBootstrap } from '@/data/queries'
import type { Transaction } from '@/data/contracts'
import { Card } from '@/components/ui'
import { useTransactionsFilter } from '@/stores/transactionsFilter'
import { getMockAliasForIban } from '@/data/mock/seed'
import { sfx } from '@/lib/sfx'
import { TransactionsHero } from './transactions/TransactionsHero'
import { TransactionsFilters } from './transactions/TransactionsFilters'
import { TransactionsList } from './transactions/TransactionsList'
import { TransactionDetailDrawer } from './transactions/TransactionDetailDrawer'

/**
 * BANK-FE.3 — Vista Transacciones (route /transacciones).
 *
 * Layout (zero-scroll at the page level — only the list pane scrolls):
 *
 *   ┌──────────────────────────────────────────────────────────────────┐
 *   │ TransactionsHero  (auto · stats glass card)                      │
 *   ├──────────────────────────────────────────────────────────────────┤
 *   │ TransactionsFilters  (auto · chips + search)                     │
 *   ├──────────────────────────────────────────────────────────────────┤
 *   │ TransactionsList  (1fr · day-grouped scrollable list)            │
 *   └──────────────────────────────────────────────────────────────────┘
 *
 * Drawer overlays the page from the right when a row is selected.
 *
 * Filtering pipeline (memoised, single-pass):
 *   range  → time window (ms cutoff)
 *   direction → 'in' / 'out'
 *   status → committed / pending / reverted
 *   query  → fuzzy match against counterpart name + reason
 */
export function Transactions() {
  const { data } = useBootstrap()
  const range = useTransactionsFilter((s) => s.range)
  const direction = useTransactionsFilter((s) => s.direction)
  const status = useTransactionsFilter((s) => s.status)
  const query = useTransactionsFilter((s) => s.query)

  const [selected, setSelected] = useState<Transaction | null>(null)

  const primaryAccount = data?.accounts[0]
  const ownIban = primaryAccount?.iban.replace(/\s+/g, '')
  const allTransactions = data?.recent_transactions ?? []

  const filtered = useMemo(
    () => filterTransactions(allTransactions, ownIban, { range, direction, status, query }),
    [allTransactions, ownIban, range, direction, status, query],
  )

  // Close drawer if its tx vanishes from the filtered set (UX consistency).
  useEffect(() => {
    if (!selected) return
    if (!filtered.some((t) => t.txn_id === selected.txn_id)) {
      setSelected(null)
    }
  }, [filtered, selected])

  const handleSelect = (tx: Transaction): void => {
    sfx.panel_open()
    setSelected(tx)
  }
  const handleClose = (): void => {
    sfx.console_tap()
    setSelected(null)
  }

  return (
    <div className="relative h-full w-full overflow-hidden">
      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
        className="h-full w-full"
      >
        <div
          className="h-full w-full mx-auto max-w-[1500px] gap-3 2xl:gap-4"
          style={{
            display: 'grid',
            gridTemplateRows: 'auto auto 1fr',
          }}
        >
          <TransactionsHero
            transactions={filtered}
            account={primaryAccount}
            totalCount={allTransactions.length}
            filteredCount={filtered.length}
          />

          <Card variant="glass" padding="sm" className="border-white/10 2xl:p-4">
            <TransactionsFilters />
          </Card>

          <Card
            variant="glass"
            padding="sm"
            className="min-h-0 border-white/10 flex flex-col"
          >
            <TransactionsList
              transactions={filtered}
              ownIban={ownIban}
              selectedTxnId={selected?.txn_id ?? null}
              onSelect={handleSelect}
              emptyVariant={allTransactions.length === 0 ? 'no-data' : 'no-match'}
              totalCount={allTransactions.length}
            />
          </Card>
        </div>
      </motion.div>

      <TransactionDetailDrawer tx={selected} ownIban={ownIban} onClose={handleClose} />
    </div>
  )
}

/* -------------------------------------------------------------------------- */

interface FilterArgs {
  range: 'all' | '7d' | '30d' | '90d'
  direction: 'all' | 'in' | 'out'
  status: 'all' | 'committed' | 'pending' | 'reverted'
  query: string
}

function filterTransactions(
  txs: Transaction[],
  ownIban: string | undefined,
  args: FilterArgs,
): Transaction[] {
  const now = Date.now()
  const dayMs = 24 * 60 * 60 * 1000
  const cutoffMs =
    args.range === 'all'
      ? -Infinity
      : now - (args.range === '7d' ? 7 : args.range === '30d' ? 30 : 90) * dayMs

  const q = normalizeSearch(args.query)

  return txs.filter((t) => {
    if (t.timestamp_ms < cutoffMs) return false

    if (args.direction !== 'all') {
      const fromCompact = t.from_iban.replace(/\s+/g, '')
      const toCompact = t.to_iban.replace(/\s+/g, '')
      const isOut = ownIban
        ? fromCompact === ownIban && toCompact !== ownIban
        : t.direction === 'out'
      if (args.direction === 'out' && !isOut) return false
      if (args.direction === 'in' && isOut) return false
    }

    if (args.status !== 'all' && t.status !== args.status) return false

    if (q) {
      const isOut = ownIban
        ? t.from_iban.replace(/\s+/g, '') === ownIban
        : t.direction === 'out'
      const counterpartIban = isOut ? t.to_iban : t.from_iban
      const counterpartName = normalizeSearch(getMockAliasForIban(counterpartIban) ?? '')
      const reason = normalizeSearch(t.reason ?? '')
      const ibanCompact = normalizeSearch(counterpartIban.replace(/\s+/g, ''))
      const ibanFormatted = normalizeSearch(counterpartIban)
      if (!counterpartName.includes(q) && !reason.includes(q) && !ibanCompact.includes(q) && !ibanFormatted.includes(q)) {
        return false
      }
    }

    return true
  })
}

function normalizeSearch(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
}
