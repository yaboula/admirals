import { useEffect, useMemo, useState } from 'react'
import { motion } from 'motion/react'
import { AlertTriangle, ArrowDownLeft, ArrowUpRight, Check, Copy, ReceiptText, RotateCw, ShieldCheck, X } from 'lucide-react'
import { useBootstrap } from '@/data/queries'
import type { Transaction } from '@/data/contracts'
import { Card } from '@/components/ui'
import { useTransactionsFilter } from '@/stores/transactionsFilter'
import { getMockAliasForIban } from '@/data/mock/seed'
import { sfx } from '@/lib/sfx'
import { formatCurrency } from '@/lib/utils'
import { maskIbanPanel, maskOperationCode, revealIbanDisplay, revealOperationCode } from '@/lib/privacy'
import { usePrivacyMode } from '@/stores/privacy'
import { toast } from '@/stores/toast'
import { BankAvatar } from '@/components/brand/BankAvatar'
import { TransactionsHero } from './transactions/TransactionsHero'
import { TransactionsFilters } from './transactions/TransactionsFilters'
import { TransactionsList } from './transactions/TransactionsList'

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
  const panelTx = selected ?? filtered[0] ?? null

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
          className="h-full w-full mx-auto max-w-[1500px] gap-4 2xl:gap-5"
          style={{
            display: 'grid',
            gridTemplateRows: 'auto 1fr',
          }}
        >
          <TransactionsHero
            transactions={filtered}
            account={primaryAccount}
            totalCount={allTransactions.length}
            filteredCount={filtered.length}
          />

          <div
            className="min-h-0 grid gap-4 2xl:gap-5"
            style={{ gridTemplateColumns: 'minmax(0, 1fr) minmax(320px, 0.46fr)' }}
          >
            <section
              className="min-h-0 grid gap-3 2xl:gap-4"
              style={{ gridTemplateRows: 'auto 1fr' }}
            >
              <Card variant="glass" padding="sm" className="border-white/10 rounded-[1.5rem] 2xl:p-4">
                <TransactionsFilters />
              </Card>

              <Card
                variant="glass"
                padding="sm"
                className="min-h-0 border-white/10 flex flex-col rounded-[1.75rem]"
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
            </section>

            <TransactionInsightPanel tx={panelTx} ownIban={ownIban} selected={Boolean(selected)} onClose={handleClose} />
          </div>
        </div>
      </motion.div>
    </div>
  )
}

function TransactionInsightPanel({
  tx,
  ownIban,
  selected,
  onClose,
}: {
  tx: Transaction | null
  ownIban: string | undefined
  selected: boolean
  onClose: () => void
}) {
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  if (!tx) {
    return (
      <Card variant="glass" padding="none" className="relative min-h-0 overflow-hidden rounded-[1.75rem] border-white/10">
        <div className="h-full flex flex-col items-center justify-center gap-3 p-6 text-center">
          <span className="inline-flex h-14 w-14 items-center justify-center rounded-full border border-white/10 bg-white/[0.04] text-text-secondary">
            <ReceiptText size={24} strokeWidth={1.8} />
          </span>
          <div className="flex flex-col gap-1">
            <h2 className="text-base font-semibold text-text-primary">Sin movimiento seleccionado</h2>
            <p className="text-sm text-text-tertiary">Elige una transacción para ver su ficha segura.</p>
          </div>
        </div>
      </Card>
    )
  }

  const meta = getTransactionMeta(tx, ownIban)
  const StatusIcon = STATUS_PANEL[tx.status].icon

  const copyIban = async (): Promise<void> => {
    try {
      await navigator.clipboard.writeText(meta.counterpartIban.replace(/\s+/g, ''))
      sfx.coin_clink()
      toast.success('IBAN copiado', meta.name)
    } catch {
      toast.warning('No se pudo copiar', 'Permiso de portapapeles denegado.')
    }
  }

  return (
    <Card variant="glass" padding="none" className="relative min-h-0 overflow-hidden rounded-[1.75rem] border-white/10">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 78% 0%, oklch(1 0 0 / 0.08), transparent 34%), linear-gradient(180deg, oklch(0.085 0.014 40 / 0.78), oklch(0.032 0.008 35 / 0.92))',
        }}
      />
      <div className="relative h-full min-h-0 flex flex-col p-5 2xl:p-6">
        <div className="flex items-center justify-between shrink-0">
          <div className="flex items-center gap-2">
            <ShieldCheck size={16} className="text-white/70" />
            <h2 className="text-base font-semibold text-white">Detalle seguro</h2>
          </div>
          {selected ? (
            <button
              type="button"
              onClick={onClose}
              className="inline-flex h-8 w-8 items-center justify-center rounded-full text-white/52 hover:text-white hover:bg-white/[0.08]"
              aria-label="Cerrar selección"
            >
              <X size={15} strokeWidth={2} />
            </button>
          ) : (
            <span className="rounded-full px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.13em] text-white/54" style={{ background: 'oklch(1 0 0 / 0.08)' }}>
              Reciente
            </span>
          )}
        </div>

        <div className="mt-5 flex flex-col items-center text-center gap-3">
          <div className="relative">
            <BankAvatar name={meta.name} size="lg" className="h-16 w-16" />
            <span
              className="absolute -bottom-1 -right-1 inline-flex h-6 w-6 items-center justify-center rounded-full"
              style={{
                background: 'oklch(0.05 0.006 35)',
                border: '1px solid oklch(1 0 0 / 0.10)',
                color: meta.outgoing ? 'oklch(0.74 0.16 25)' : 'oklch(0.78 0.16 155)',
              }}
            >
              {meta.outgoing ? <ArrowUpRight size={14} strokeWidth={2.4} /> : <ArrowDownLeft size={14} strokeWidth={2.4} />}
            </span>
          </div>
          <div className="min-w-0">
            <h3 className="text-lg font-semibold text-white truncate">{meta.name}</h3>
            <p className="text-xs text-white/46 truncate">{tx.reason ?? (meta.outgoing ? 'Transferencia enviada' : 'Transferencia recibida')}</p>
          </div>
        </div>

        <div className="mt-5 rounded-[1.55rem] border border-white/10 bg-white/[0.045] px-4 py-4 text-center">
          <span className="block text-[11px] uppercase tracking-[0.14em] text-white/46">Importe</span>
          <span
            className="block text-3xl font-light tracking-[-0.055em] tactile-tabular-nums"
            style={{ color: meta.outgoing ? 'white' : 'oklch(0.78 0.16 155)' }}
          >
            {meta.outgoing ? '−' : '+'}{formatCurrency(tx.amount_minor / 100)}
          </span>
        </div>

        <div className="mt-4 space-y-2">
          <PanelRow label="Estado" value={STATUS_PANEL[tx.status].label} icon={<StatusIcon size={14} strokeWidth={2.3} />} />
          <PanelRow label="Hora" value={formatPanelTime(tx.timestamp_ms)} />
          <PanelRow label="IBAN" value={streamerMode ? maskIbanPanel(meta.counterpartIban) : revealIbanDisplay(meta.counterpartIban)} mono action={<button type="button" onClick={copyIban} className="text-white/44 hover:text-white"><Copy size={13} /></button>} />
          <PanelRow label="Recibo" value={streamerMode ? maskOperationCode(tx.txn_id) : revealOperationCode(tx.txn_id)} mono />
        </div>
      </div>
    </Card>
  )
}

function PanelRow({
  label,
  value,
  icon,
  mono,
  action,
}: {
  label: string
  value: string
  icon?: React.ReactNode
  mono?: boolean
  action?: React.ReactNode
}) {
  return (
    <div className="flex items-center justify-between gap-3 rounded-2xl border border-white/8 bg-black/16 px-3 py-2.5">
      <span className="inline-flex items-center gap-2 text-[11px] uppercase tracking-[0.13em] text-white/44">
        {icon}
        {label}
      </span>
      <span className="min-w-0 flex items-center gap-2">
        <span className={mono ? 'truncate text-right text-[11px] font-mono text-white/72' : 'truncate text-right text-sm font-semibold text-white/78'}>
          {value}
        </span>
        {action}
      </span>
    </div>
  )
}

function getTransactionMeta(tx: Transaction, ownIban: string | undefined) {
  const fromCompact = tx.from_iban.replace(/\s+/g, '')
  const toCompact = tx.to_iban.replace(/\s+/g, '')
  const outgoing = ownIban
    ? fromCompact === ownIban && toCompact !== ownIban
    : tx.direction === 'out'
  const counterpartIban = outgoing ? tx.to_iban : tx.from_iban
  const name = getMockAliasForIban(counterpartIban) ?? (outgoing ? 'Beneficiario' : 'Remitente')
  return { outgoing, counterpartIban, name }
}

const STATUS_PANEL: Record<Transaction['status'], { label: string; icon: typeof Check }> = {
  committed: { label: 'Confirmada', icon: Check },
  pending: { label: 'Pendiente', icon: RotateCw },
  reconciling: { label: 'Reconciliando', icon: RotateCw },
  reverted: { label: 'Revertida', icon: AlertTriangle },
  failed: { label: 'Fallida', icon: AlertTriangle },
}

function formatPanelTime(timestampMs: number): string {
  return new Intl.DateTimeFormat('es-ES', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(timestampMs))
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
