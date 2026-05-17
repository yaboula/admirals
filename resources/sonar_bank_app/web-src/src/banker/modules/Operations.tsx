import { useState } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import {
  Briefcase,
  HandCoins,
  ShieldCheck,
  FileBadge,
  CheckCircle2,
  XCircle,
  RefreshCw,
  AlertTriangle,
  type LucideIcon,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  useBankerQueues,
  useBankerDecideLoan,
  useBankerDecideProAccount,
  useBankerDecideKyc,
} from '../data/queries'
import { formatMinor, formatBps, formatRelative } from '../lib/format'
import type {
  BankerPendingLoan,
  BankerPendingProAccount,
  BankerPendingKyc,
} from '../data/contractsF2'

type Tab = 'loans' | 'pro_accounts' | 'kyc'

const TABS: { id: Tab; label: string; icon: LucideIcon }[] = [
  { id: 'loans',        label: 'Préstamos',     icon: HandCoins },
  { id: 'pro_accounts', label: 'Cuentas Pro',   icon: FileBadge },
  { id: 'kyc',          label: 'KYC',           icon: ShieldCheck },
]

export function BankerOperations() {
  const [tab, setTab] = useState<Tab>('loans')
  const queues = useBankerQueues(50)

  const data = queues.data
  const loans = data?.loans_pending ?? []
  const pros  = data?.pro_accounts_pending ?? []
  const kyc   = data?.kyc_pending ?? []

  const counts = {
    loans: loans.length,
    pro_accounts: pros.length,
    kyc: kyc.length,
  }

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
            <Briefcase size={18} className="text-[var(--banker-primary)]" />
          </div>
          <div className="flex-1">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">Aprobaciones</p>
            <h1 className="text-2xl font-semibold text-text-primary">Operaciones</h1>
            <p className="mt-1 text-sm text-text-secondary">
              Revisa y decide solicitudes de préstamos, cuentas profesionales y verificaciones KYC.
            </p>
          </div>
          <button
            onClick={() => queues.refetch()}
            disabled={queues.isFetching}
            className="flex items-center gap-2 rounded-xl border border-white/10 bg-white/[0.03] px-3 py-2 text-xs text-text-secondary transition hover:bg-white/[0.06] disabled:opacity-50"
          >
            <RefreshCw size={13} className={queues.isFetching ? 'animate-spin' : ''} />
            Refrescar
          </button>
        </div>
      </motion.section>

      {/* Tabs */}
      <div className="flex gap-2 rounded-2xl border border-white/10 bg-white/[0.02] p-1.5">
        {TABS.map((t) => {
          const Icon = t.icon
          const active = tab === t.id
          const count = counts[t.id]
          return (
            <button
              key={t.id}
              onClick={() => setTab(t.id)}
              className={cn(
                'flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition',
                active
                  ? 'bg-[radial-gradient(circle_at_0%_0%,rgba(255,100,19,0.18),transparent_60%),rgba(255,255,255,0.06)] text-text-primary'
                  : 'text-text-secondary hover:text-text-primary hover:bg-white/[0.025]',
              )}
            >
              <Icon size={15} className={active ? 'text-[var(--banker-primary)]' : ''} />
              {t.label}
              <span
                className={cn(
                  'ml-1 rounded-full px-2 py-0.5 text-[10px] font-semibold',
                  count > 0
                    ? 'bg-[var(--banker-primary)] text-black'
                    : 'bg-white/[0.06] text-text-tertiary',
                )}
              >
                {count}
              </span>
            </button>
          )
        })}
      </div>

      {/* Body */}
      <AnimatePresence mode="wait">
        <motion.div
          key={tab}
          initial={{ opacity: 0, y: 6 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -6 }}
          transition={{ duration: 0.2 }}
        >
          {queues.isLoading && <SkeletonList />}
          {!queues.isLoading && tab === 'loans'        && <LoansList items={loans} />}
          {!queues.isLoading && tab === 'pro_accounts' && <ProAccountsList items={pros} />}
          {!queues.isLoading && tab === 'kyc'          && <KycList items={kyc} />}
        </motion.div>
      </AnimatePresence>

      {data?.partial_errors && Object.values(data.partial_errors).some(Boolean) && (
        <div className="rounded-2xl border border-amber-500/25 bg-amber-500/[0.04] p-4 text-xs text-amber-200">
          <div className="flex items-center gap-2 font-semibold mb-1">
            <AlertTriangle size={13} /> Algunos datos no se pudieron cargar
          </div>
          <ul className="ml-4 list-disc space-y-0.5">
            {Object.entries(data.partial_errors).map(([k, v]) =>
              v ? <li key={k}><span className="font-mono">{k}</span>: {v}</li> : null,
            )}
          </ul>
        </div>
      )}
    </div>
  )
}

// ============================ Loans ============================

function LoansList({ items }: { items: BankerPendingLoan[] }) {
  const decide = useBankerDecideLoan()
  if (items.length === 0) return <EmptyState text="No hay préstamos pendientes." />

  return (
    <ul className="space-y-3">
      {items.map((loan) => (
        <RowCard key={loan.loan_id}>
          <div className="grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr_1fr_auto] gap-4 items-center">
            <div>
              <p className="font-mono text-xs text-text-tertiary">{loan.loan_id.slice(0, 12)}…</p>
              <p className="mt-0.5 text-sm font-semibold text-text-primary">
                {loan.borrower_citizen_id}
              </p>
              <p className="text-[11px] text-text-tertiary">Producto · {loan.product_id}</p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-text-tertiary">Capital</p>
              <p className="text-sm font-semibold text-text-primary">
                {formatMinor(loan.principal_minor)}
              </p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-text-tertiary">Tasa · Plazo</p>
              <p className="text-sm font-semibold text-text-primary">
                {formatBps(loan.interest_bps)} · {loan.term_days}d
              </p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-text-tertiary">Solicitado</p>
              <p className="text-sm text-text-secondary">{formatRelative(loan.requested_ms)}</p>
            </div>
            <div className="flex gap-2 justify-end">
              <ApproveBtn
                loading={decide.isPending}
                onClick={() =>
                  decide.mutate({
                    loan_id: loan.loan_id,
                    decision: 'approve',
                    deposit_iban: loan.deposit_iban ?? undefined,
                  })
                }
              />
              <RejectBtn
                loading={decide.isPending}
                onClick={() => {
                  const reason = window.prompt('Motivo del rechazo:') ?? ''
                  if (!reason) return
                  decide.mutate({ loan_id: loan.loan_id, decision: 'reject', reason })
                }}
              />
            </div>
          </div>
        </RowCard>
      ))}
    </ul>
  )
}

// ============================ Pro Accounts ============================

function ProAccountsList({ items }: { items: BankerPendingProAccount[] }) {
  const decide = useBankerDecideProAccount()
  if (items.length === 0) return <EmptyState text="No hay cuentas profesionales pendientes." />

  return (
    <ul className="space-y-3">
      {items.map((req) => (
        <RowCard key={req.approval_id}>
          <div className="grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr_auto] gap-4 items-center">
            <div>
              <p className="font-mono text-xs text-text-tertiary">{req.approval_id.slice(0, 12)}…</p>
              <p className="mt-0.5 text-sm font-semibold text-text-primary">{req.citizen_id}</p>
              <p className="text-[11px] text-text-tertiary">{req.account_class}</p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-text-tertiary">Estado</p>
              <p className="text-sm font-semibold text-amber-300">{req.state}</p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-text-tertiary">Solicitado</p>
              <p className="text-sm text-text-secondary">{formatRelative(req.requested_ms)}</p>
            </div>
            <div className="flex gap-2 justify-end">
              <ApproveBtn
                loading={decide.isPending}
                onClick={() => {
                  const note = window.prompt('Nota (opcional):') ?? ''
                  decide.mutate({
                    approval_id: req.approval_id,
                    decision: 'approve',
                    note: note || undefined,
                  })
                }}
              />
              <RejectBtn
                loading={decide.isPending}
                onClick={() => {
                  const note = window.prompt('Motivo del rechazo:') ?? ''
                  if (!note) return
                  decide.mutate({ approval_id: req.approval_id, decision: 'reject', note })
                }}
              />
            </div>
          </div>
          {req.note && (
            <p className="mt-3 rounded-lg border border-white/[0.05] bg-white/[0.02] px-3 py-2 text-xs text-text-secondary">
              {req.note}
            </p>
          )}
        </RowCard>
      ))}
    </ul>
  )
}

// ============================ KYC ============================

function KycList({ items }: { items: BankerPendingKyc[] }) {
  const decide = useBankerDecideKyc()
  if (items.length === 0) return <EmptyState text="No hay verificaciones KYC pendientes." />

  return (
    <ul className="space-y-3">
      {items.map((row) => (
        <RowCard key={row.citizen_id}>
          <div className="grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr_auto] gap-4 items-center">
            <div>
              <p className="text-sm font-semibold text-text-primary">{row.citizen_id}</p>
              <p className="text-[11px] text-text-tertiary">Solicitud KYC</p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-text-tertiary">Documentos</p>
              <p className="text-sm font-semibold text-text-primary">{row.doc_count ?? '—'}</p>
            </div>
            <div>
              <p className="text-[10px] uppercase text-text-tertiary">Enviado</p>
              <p className="text-sm text-text-secondary">{formatRelative(row.submitted_ms)}</p>
            </div>
            <div className="flex gap-2 justify-end">
              <ApproveBtn
                loading={decide.isPending}
                onClick={() =>
                  decide.mutate({
                    target_citizen_id: row.citizen_id,
                    decision: 'approve',
                  })
                }
              />
              <RejectBtn
                loading={decide.isPending}
                onClick={() => {
                  const reason = window.prompt('Motivo del rechazo:') ?? ''
                  if (!reason) return
                  decide.mutate({
                    target_citizen_id: row.citizen_id,
                    decision: 'reject',
                    reason,
                  })
                }}
              />
            </div>
          </div>
        </RowCard>
      ))}
    </ul>
  )
}

// ============================ shared ============================

function RowCard({ children }: { children: React.ReactNode }) {
  return (
    <motion.li
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.18 }}
      className="rounded-2xl border border-white/[0.08] bg-white/[0.02] p-4"
    >
      {children}
    </motion.li>
  )
}

function ApproveBtn({ onClick, loading }: { onClick: () => void; loading?: boolean }) {
  return (
    <button
      onClick={onClick}
      disabled={loading}
      className="flex items-center gap-1.5 rounded-lg border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-xs font-semibold text-emerald-200 transition hover:bg-emerald-400/20 disabled:opacity-40"
    >
      <CheckCircle2 size={13} /> Aprobar
    </button>
  )
}

function RejectBtn({ onClick, loading }: { onClick: () => void; loading?: boolean }) {
  return (
    <button
      onClick={onClick}
      disabled={loading}
      className="flex items-center gap-1.5 rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-xs font-semibold text-red-200 transition hover:bg-red-400/20 disabled:opacity-40"
    >
      <XCircle size={13} /> Rechazar
    </button>
  )
}

function EmptyState({ text }: { text: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-white/10 bg-white/[0.01] p-10 text-center">
      <p className="text-sm text-text-tertiary">{text}</p>
    </div>
  )
}

function SkeletonList() {
  return (
    <ul className="space-y-3">
      {Array.from({ length: 3 }).map((_, i) => (
        <li
          key={i}
          className="h-20 animate-pulse rounded-2xl border border-white/[0.06] bg-white/[0.02]"
        />
      ))}
    </ul>
  )
}
