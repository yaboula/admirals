/**
 * SONAR Tablet — Bank Overview view (S2.4).
 *
 * Carga balance real player vía C001 al mount. Target DC-S2.4.1:
 * `last_updated`→render ≤200ms (DC5). Log warning console si excede.
 *
 * Dark-only 3-color strict (ADR-016 D1+D3). Skeleton shimmer mientras carga.
 * Error boundary inline con botón Reintentar.
 */
import { useCallback, useEffect, useState } from 'react'
import { ArrowRightLeft, History, RefreshCw, Wallet } from 'lucide-react'
import { getBalance, translateError } from './bankApi'
import { BankApiError, type BankBalance } from './types'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; balance: BankBalance; elapsedMs: number }
  | { kind: 'error'; message: string }

const EUR = new Intl.NumberFormat('es-ES', {
  style: 'currency',
  currency: 'EUR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
})

function formatRelative(unixMs: number): string {
  if (!Number.isFinite(unixMs) || unixMs <= 0) return '—'
  const diffSec = Math.max(0, Math.floor((Date.now() - unixMs) / 1000))
  if (diffSec < 60) return `hace ${diffSec}s`
  if (diffSec < 3600) return `hace ${Math.floor(diffSec / 60)}min`
  if (diffSec < 86400) return `hace ${Math.floor(diffSec / 3600)}h`
  return `hace ${Math.floor(diffSec / 86400)}d`
}

export interface BankOverviewProps {
  /** Trigger counter — increment para forzar refetch (useEffect dep). */
  refreshKey: number
  onGoHistory: () => void
  onGoTransfer: () => void
}

export default function BankOverview({
  refreshKey,
  onGoHistory,
  onGoTransfer,
}: BankOverviewProps) {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    const t0 = performance.now()
    try {
      const balance = await getBalance()
      const elapsedMs = Math.round(performance.now() - t0)
      if (elapsedMs > 200) {
        // DC-S2.4.1 / DC5 SPRINT_PLAN_S2 §3 perf budget.
        // eslint-disable-next-line no-console
        console.warn(`[sonar_tablet/bank] getBalance exceeded 200ms (${elapsedMs}ms)`)
      }
      // Sound signature stub (S2.6 real integration).
      // eslint-disable-next-line no-console
      console.debug('[sound] signal_emerge (balance loaded)')
      setState({ kind: 'ready', balance, elapsedMs })
    } catch (err) {
      const code = err instanceof BankApiError ? err.error_code : 'UNKNOWN'
      const message = err instanceof BankApiError ? translateError(code) : translateError('UNKNOWN')
      setState({ kind: 'error', message })
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load, refreshKey])

  if (state.kind === 'loading') {
    return (
      <div className="flex h-full flex-col gap-6 p-8" aria-busy aria-live="polite">
        <div className="flex flex-col gap-3 rounded-2xl border border-sonar-white/10 bg-sonar-white/5 p-8">
          <div className="h-3 w-24 animate-pulse rounded bg-sonar-white/10" />
          <div className="h-8 w-72 animate-pulse rounded bg-sonar-white/10" />
          <div className="h-10 w-56 animate-pulse rounded bg-sonar-white/10" />
          <div className="h-3 w-32 animate-pulse rounded bg-sonar-white/5" />
        </div>
      </div>
    )
  }

  if (state.kind === 'error') {
    return (
      <div
        className="flex h-full flex-col items-center justify-center gap-4 p-8"
        role="alert"
      >
        <p className="text-sm text-sonar-white/80">No se pudo cargar el saldo.</p>
        <p className="text-xs text-sonar-white/40">{state.message}</p>
        <button
          type="button"
          onClick={() => void load()}
          className="inline-flex items-center gap-2 rounded-md border border-sonar-orange/40 px-3 py-1.5 text-sm text-sonar-orange transition-colors duration-150 hover:bg-sonar-orange/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40"
        >
          <RefreshCw className="h-4 w-4" strokeWidth={1.5} aria-hidden />
          Reintentar
        </button>
      </div>
    )
  }

  const { balance, elapsedMs } = state
  return (
    <div className="flex h-full flex-col gap-6 p-8">
      <section
        aria-label="Saldo cuenta personal"
        className="flex flex-col gap-2 rounded-2xl border border-sonar-white/10 bg-sonar-white/5 p-8"
      >
        <div className="flex items-center justify-between">
          <span className="font-mono text-[11px] uppercase tracking-widest text-sonar-white/40">
            Cuenta personal
          </span>
          <span className="inline-flex items-center gap-1 rounded-full border border-sonar-white/10 px-2 py-0.5 text-[10px] uppercase tracking-wider text-sonar-white/60">
            {balance.tier}
          </span>
        </div>
        <p className="font-mono text-sm text-sonar-white/80 break-all">{balance.iban}</p>
        <p className="mt-2 text-5xl font-semibold tracking-tight text-sonar-white">
          {EUR.format(balance.balance)}
        </p>
        <p className="text-xs text-sonar-white/40">
          Actualizado {formatRelative(balance.last_updated)}
          <span className="ml-2 font-mono text-[10px] text-sonar-white/30">
            · load {elapsedMs}ms
          </span>
        </p>
      </section>

      <section aria-label="Acciones banca" className="flex flex-wrap gap-3">
        <button
          type="button"
          onClick={onGoTransfer}
          className="inline-flex items-center gap-2 rounded-lg border border-sonar-orange/40 bg-sonar-orange/10 px-4 py-2 text-sm font-medium text-sonar-orange transition-colors duration-150 hover:bg-sonar-orange/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40"
        >
          <ArrowRightLeft className="h-4 w-4" strokeWidth={1.5} aria-hidden />
          Transferir
        </button>
        <button
          type="button"
          onClick={onGoHistory}
          className="inline-flex items-center gap-2 rounded-lg border border-sonar-white/10 bg-sonar-white/5 px-4 py-2 text-sm text-sonar-white/80 transition-colors duration-150 hover:border-sonar-white/20 hover:text-sonar-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40"
        >
          <History className="h-4 w-4" strokeWidth={1.5} aria-hidden />
          Ver historial
        </button>
        <button
          type="button"
          onClick={() => void load()}
          className="inline-flex items-center gap-2 rounded-lg border border-sonar-white/10 bg-transparent px-3 py-2 text-sm text-sonar-white/60 transition-colors duration-150 hover:text-sonar-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40"
          aria-label="Refrescar saldo"
        >
          <RefreshCw className="h-4 w-4" strokeWidth={1.5} aria-hidden />
        </button>
      </section>

      <section
        aria-hidden
        className="mt-auto flex items-center gap-2 text-[10px] uppercase tracking-widest text-sonar-white/30"
      >
        <Wallet className="h-3 w-3" strokeWidth={1.5} />
        sonar · banca · overview
      </section>
    </div>
  )
}
