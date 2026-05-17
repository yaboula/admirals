import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import {
  Search,
  UserSearch,
  ArrowLeft,
  Snowflake,
  Sun,
  ShieldAlert,
  Wallet,
  PiggyBank,
  AlertTriangle,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  useBankerCustomerSearch,
  useBankerCustomerDetail,
  useBankerFreezeAccount,
  useBankerUnfreezeAccount,
} from '../data/queries'
import { formatMinor, formatRelative, formatDayMs } from '../lib/format'
import type {
  BankerCustomerRow,
  BankerCustomerAccount,
} from '../data/contractsF2'

export function BankerCustomers() {
  const [query, setQuery] = useState('')
  const [selected, setSelected] = useState<string | null>(null)

  // Light debounce — 250ms
  const debounced = useDebounce(query, 250)
  const search = useBankerCustomerSearch(debounced, !selected)

  return (
    <div className="px-8 py-7 space-y-6">
      {/* Header */}
      <motion.section
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className="rounded-3xl border border-white/10 bg-white/[0.025] p-6"
      >
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/10 bg-white/[0.04]">
            <UserSearch size={18} className="text-[var(--banker-primary)]" />
          </div>
          <div className="flex-1">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">CRM</p>
            <h1 className="text-2xl font-semibold text-text-primary">Clientes</h1>
            <p className="mt-1 text-sm text-text-secondary">
              Busca por <span className="font-mono text-text-primary">citizen_id</span>, revisa cuentas y aplica freeze/unfreeze.
            </p>
          </div>
        </div>

        {/* Search bar */}
        <div className="mt-5 relative">
          <Search size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-text-tertiary" />
          <input
            value={query}
            onChange={(e) => {
              setQuery(e.target.value)
              setSelected(null)
            }}
            placeholder="Buscar por citizen_id (mín. 2 caracteres)…"
            className="w-full rounded-xl border border-white/10 bg-black/30 pl-10 pr-4 py-3 text-sm text-text-primary placeholder:text-text-tertiary focus:border-[var(--banker-primary)] focus:outline-none"
          />
        </div>
      </motion.section>

      {/* Body */}
      <AnimatePresence mode="wait">
        {selected ? (
          <motion.div
            key="detail"
            initial={{ opacity: 0, x: 12 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -12 }}
            transition={{ duration: 0.2 }}
          >
            <CustomerDetail
              citizenId={selected}
              onBack={() => setSelected(null)}
            />
          </motion.div>
        ) : (
          <motion.div
            key="list"
            initial={{ opacity: 0, x: -12 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 12 }}
            transition={{ duration: 0.2 }}
          >
            <SearchResults
              loading={search.isLoading}
              query={debounced}
              items={search.data?.items ?? []}
              onSelect={(c) => setSelected(c.citizen_id)}
            />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

// ============================ Search Results ============================

function SearchResults({
  loading,
  query,
  items,
  onSelect,
}: {
  loading: boolean
  query: string
  items: BankerCustomerRow[]
  onSelect: (c: BankerCustomerRow) => void
}) {
  if (query.length < 2) {
    return (
      <div className="rounded-2xl border border-dashed border-white/10 bg-white/[0.01] p-10 text-center">
        <p className="text-sm text-text-tertiary">Escribe al menos 2 caracteres para buscar.</p>
      </div>
    )
  }
  if (loading) {
    return (
      <ul className="space-y-3">
        {Array.from({ length: 4 }).map((_, i) => (
          <li
            key={i}
            className="h-20 animate-pulse rounded-2xl border border-white/[0.06] bg-white/[0.02]"
          />
        ))}
      </ul>
    )
  }
  if (items.length === 0) {
    return (
      <div className="rounded-2xl border border-dashed border-white/10 bg-white/[0.01] p-10 text-center">
        <p className="text-sm text-text-tertiary">Sin resultados para "{query}".</p>
      </div>
    )
  }
  return (
    <ul className="space-y-3">
      {items.map((c) => (
        <motion.li
          key={c.citizen_id}
          whileHover={{ scale: 1.005 }}
          onClick={() => onSelect(c)}
          className="cursor-pointer rounded-2xl border border-white/[0.08] bg-white/[0.02] p-4 transition hover:border-white/15 hover:bg-white/[0.04]"
        >
          <div className="grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr_1fr_auto] gap-4 items-center">
            <div>
              <p className="text-sm font-semibold text-text-primary">{c.citizen_id}</p>
              <p className="mt-0.5 text-[11px] text-text-tertiary">
                Última actividad · {formatRelative(c.last_activity_ms)}
              </p>
            </div>
            <Stat label="Cuentas" value={c.account_count.toString()} />
            <Stat label="Saldo total" value={formatMinor(c.total_balance_minor)} />
            <Stat label="Ahorros" value={formatMinor(c.total_savings_minor)} />
            <div className="flex items-center justify-end">
              {c.frozen_count > 0 && (
                <span className="rounded-full border border-cyan-400/30 bg-cyan-400/10 px-2.5 py-1 text-[10px] font-semibold uppercase text-cyan-200">
                  <Snowflake size={11} className="mr-1 inline-block" /> {c.frozen_count} congel.
                </span>
              )}
            </div>
          </div>
        </motion.li>
      ))}
    </ul>
  )
}

// ============================ Detail ============================

function CustomerDetail({ citizenId, onBack }: { citizenId: string; onBack: () => void }) {
  const detail = useBankerCustomerDetail(citizenId)
  const freeze = useBankerFreezeAccount()
  const unfreeze = useBankerUnfreezeAccount()

  const data = detail.data

  return (
    <div className="space-y-6">
      <button
        onClick={onBack}
        className="flex items-center gap-2 text-xs text-text-secondary transition hover:text-text-primary"
      >
        <ArrowLeft size={13} /> Volver al listado
      </button>

      {/* Summary */}
      <div className="rounded-3xl border border-white/10 bg-[radial-gradient(ellipse_at_top_left,rgba(255,100,19,0.08),transparent_55%),rgba(255,255,255,0.025)] p-6">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">Cliente</p>
            <h2 className="mt-1 text-2xl font-semibold text-text-primary font-mono">{citizenId}</h2>
          </div>
          {data?.frozen_count ? (
            <span className="rounded-full border border-cyan-400/30 bg-cyan-400/10 px-3 py-1.5 text-[11px] font-semibold uppercase text-cyan-200">
              {data.frozen_count} congeladas
            </span>
          ) : null}
        </div>
        <div className="mt-5 grid grid-cols-2 md:grid-cols-4 gap-3">
          <SummaryCard
            icon={Wallet}
            label="Saldo total"
            value={formatMinor(data?.total_balance_minor ?? 0)}
            loading={detail.isLoading}
          />
          <SummaryCard
            icon={PiggyBank}
            label="Ahorros"
            value={formatMinor(data?.total_savings_minor ?? 0)}
            loading={detail.isLoading}
          />
          <SummaryCard
            label="Cuentas"
            value={(data?.account_count ?? 0).toString()}
            loading={detail.isLoading}
          />
          <SummaryCard
            icon={Snowflake}
            label="Congeladas"
            value={(data?.frozen_count ?? 0).toString()}
            loading={detail.isLoading}
          />
        </div>
      </div>

      {/* Accounts */}
      <div>
        <p className="mb-3 text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">
          Cuentas ({data?.accounts.length ?? 0})
        </p>
        {detail.isLoading ? (
          <ul className="space-y-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <li key={i} className="h-24 animate-pulse rounded-2xl border border-white/[0.06] bg-white/[0.02]" />
            ))}
          </ul>
        ) : (data?.accounts ?? []).length === 0 ? (
          <div className="rounded-2xl border border-dashed border-white/10 bg-white/[0.01] p-10 text-center">
            <p className="text-sm text-text-tertiary">Este cliente no tiene cuentas activas.</p>
          </div>
        ) : (
          <ul className="space-y-3">
            {data!.accounts.map((acc) => (
              <AccountRow
                key={acc.account_id}
                acc={acc}
                onFreeze={() => {
                  const reason = window.prompt('Motivo del congelamiento:') ?? ''
                  if (!reason) return
                  freeze.mutate({ iban: acc.iban, reason })
                }}
                onUnfreeze={() => {
                  const reason = window.prompt('Motivo del desbloqueo:') ?? ''
                  if (!reason) return
                  unfreeze.mutate({ iban: acc.iban, reason })
                }}
                pending={freeze.isPending || unfreeze.isPending}
              />
            ))}
          </ul>
        )}
      </div>

      {(freeze.isError || unfreeze.isError) && (
        <div className="rounded-2xl border border-red-400/30 bg-red-400/[0.05] p-4 text-xs text-red-200">
          <div className="flex items-center gap-2">
            <AlertTriangle size={13} />
            <span>
              {freeze.error?.message ?? unfreeze.error?.message ?? 'No se pudo aplicar la operación.'}
            </span>
          </div>
        </div>
      )}
    </div>
  )
}

function AccountRow({
  acc,
  onFreeze,
  onUnfreeze,
  pending,
}: {
  acc: BankerCustomerAccount
  onFreeze: () => void
  onUnfreeze: () => void
  pending?: boolean
}) {
  return (
    <motion.li
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.15 }}
      className={cn(
        'rounded-2xl border p-4',
        acc.is_frozen
          ? 'border-cyan-400/25 bg-cyan-400/[0.03]'
          : 'border-white/[0.08] bg-white/[0.02]',
      )}
    >
      <div className="grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr_1fr_auto] gap-4 items-center">
        <div>
          <p className="font-mono text-sm font-semibold text-text-primary">{acc.iban}</p>
          <p className="mt-0.5 text-[11px] text-text-tertiary">
            {prettyClass(acc.account_class)} · {acc.owner_type} · creada {formatDayMs(acc.created_ms)}
          </p>
        </div>
        <Stat label="Saldo" value={formatMinor(acc.balance_minor)} />
        <Stat label="Ahorros" value={formatMinor(acc.savings_minor)} />
        <div>
          <p className="text-[10px] uppercase text-text-tertiary">Estado</p>
          <p className={cn(
            'text-sm font-semibold',
            acc.is_frozen ? 'text-cyan-200' : 'text-emerald-200',
          )}>
            {acc.is_frozen ? 'Congelada' : 'Activa'}
          </p>
        </div>
        <div className="flex justify-end">
          {acc.is_frozen ? (
            <button
              onClick={onUnfreeze}
              disabled={pending}
              className="flex items-center gap-1.5 rounded-lg border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-xs font-semibold text-emerald-200 transition hover:bg-emerald-400/20 disabled:opacity-40"
            >
              <Sun size={13} /> Descongelar
            </button>
          ) : (
            <button
              onClick={onFreeze}
              disabled={pending}
              className="flex items-center gap-1.5 rounded-lg border border-cyan-400/30 bg-cyan-400/10 px-3 py-2 text-xs font-semibold text-cyan-200 transition hover:bg-cyan-400/20 disabled:opacity-40"
            >
              <Snowflake size={13} /> Congelar
            </button>
          )}
        </div>
      </div>
    </motion.li>
  )
}

// ============================ shared ============================

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[10px] uppercase text-text-tertiary">{label}</p>
      <p className="text-sm font-semibold text-text-primary">{value}</p>
    </div>
  )
}

function SummaryCard({
  icon: Icon,
  label,
  value,
  loading,
}: {
  icon?: typeof Wallet
  label: string
  value: string
  loading?: boolean
}) {
  return (
    <div className="rounded-2xl border border-white/[0.06] bg-white/[0.02] p-4">
      <div className="flex items-center gap-2 text-text-tertiary">
        {Icon && <Icon size={13} />}
        <span className="text-[10px] uppercase tracking-[0.18em]">{label}</span>
      </div>
      {loading ? (
        <div className="mt-2 h-6 w-20 animate-pulse rounded bg-white/5" />
      ) : (
        <p className="mt-2 text-lg font-semibold text-text-primary">{value}</p>
      )}
    </div>
  )
}

function prettyClass(c: string): string {
  switch (c) {
    case 'checking': return 'Corriente'
    case 'savings': return 'Ahorros'
    case 'business_treasury': return 'Profesional'
    case 'shared': return 'Compartida'
    case 'govt_treasury': return 'Tesoro'
    case 'escrow': return 'Escrow'
    case 'crypto_wallet': return 'Cripto'
    default: return c
  }
}

// Tiny inline debounce hook (no extra dep).
function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value)
  useEffect(() => {
    const id = window.setTimeout(() => setDebounced(value), delay)
    return () => window.clearTimeout(id)
  }, [value, delay])
  return debounced
}

void ShieldAlert // keep import for future use
