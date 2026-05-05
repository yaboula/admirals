/**
 * SONAR Tablet — Bank History view (S2.4).
 *
 * Consumer pattern temporal §2.2.3: carga vía bridge ad-hoc
 * `sonar:tablet:bank:getHistory` (DEFERRED catalog promotion C003 S3 per
 * SPRINT_PLAN_S2 §9 R5).
 *
 * Virtualización: `react-window` FixedSizeList — activa siempre para eliminar
 * jank en listas de 50 rows default (consistente ≥55fps per DC8/D6 §5). Dep ya
 * pin en `package.json:23` (react-window ^1.8.10).
 */
import { useCallback, useEffect, useMemo, useState } from 'react'
import { FixedSizeList, type ListChildComponentProps } from 'react-window'
import { Inbox, RefreshCw } from 'lucide-react'
import { getHistory, translateError } from './bankApi'
import { BankApiError, type BankMovement } from './types'

const ROW_HEIGHT = 64
const LIST_MAX_HEIGHT = 520
const FETCH_LIMIT = 50

const EUR = new Intl.NumberFormat('es-ES', {
  style: 'currency',
  currency: 'EUR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
  signDisplay: 'exceptZero',
})

function formatDate(unixMs: number): string {
  if (!Number.isFinite(unixMs) || unixMs <= 0) return '—'
  const d = new Date(unixMs)
  const pad = (n: number) => n.toString().padStart(2, '0')
  return `${pad(d.getDate())}/${pad(d.getMonth() + 1)} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; movements: BankMovement[] }
  | { kind: 'error'; message: string }

interface RowProps extends ListChildComponentProps {
  data: BankMovement[]
}

function MovementRow({ index, style, data }: RowProps) {
  const mv = data[index]
  if (!mv) return null
  const isPositive = mv.amount >= 0
  return (
    <div
      style={style}
      className="flex items-center gap-4 border-b border-sonar-white/5 px-4"
      role="row"
    >
      <div className="flex w-20 flex-col font-mono text-[10px] uppercase tracking-widest text-sonar-white/40">
        <span>{formatDate(mv.created_at)}</span>
        <span className="text-sonar-white/30">{mv.category}</span>
      </div>
      <div className="flex min-w-0 flex-1 flex-col">
        <span className="truncate text-sm text-sonar-white/80">
          {mv.concept || '—'}
        </span>
        {mv.counterpart_iban ? (
          <span className="truncate font-mono text-[10px] text-sonar-white/40">
            {mv.counterpart_iban}
          </span>
        ) : null}
      </div>
      <div className="flex w-40 flex-col items-end">
        <span
          className={
            isPositive
              ? 'font-mono text-sm text-sonar-white'
              : 'font-mono text-sm text-sonar-orange'
          }
        >
          {EUR.format(mv.amount)}
        </span>
        <span className="font-mono text-[10px] text-sonar-white/40">
          {EUR.format(mv.balance_after).replace('+', '')}
        </span>
      </div>
    </div>
  )
}

export default function BankHistory() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const movements = await getHistory(FETCH_LIMIT)
      setState({ kind: 'ready', movements })
    } catch (err) {
      const code = err instanceof BankApiError ? err.error_code : 'UNKNOWN'
      setState({ kind: 'error', message: translateError(code) })
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const listHeight = useMemo(() => {
    if (state.kind !== 'ready') return LIST_MAX_HEIGHT
    return Math.min(LIST_MAX_HEIGHT, Math.max(ROW_HEIGHT, state.movements.length * ROW_HEIGHT))
  }, [state])

  return (
    <div className="flex h-full flex-col p-6">
      <header className="flex items-center justify-between pb-4">
        <div className="flex flex-col">
          <h2 className="text-sm font-semibold text-sonar-white">
            Últimos {FETCH_LIMIT} movimientos
          </h2>
          <p className="font-mono text-[10px] uppercase tracking-widest text-sonar-white/40">
            consumer pattern · bridge §2.2.3
          </p>
        </div>
        <button
          type="button"
          onClick={() => void load()}
          className="inline-flex items-center gap-2 rounded-md border border-sonar-white/10 px-3 py-1.5 text-xs text-sonar-white/60 transition-colors duration-150 hover:text-sonar-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40"
        >
          <RefreshCw className="h-3.5 w-3.5" strokeWidth={1.5} aria-hidden />
          Refrescar
        </button>
      </header>

      {state.kind === 'loading' ? (
        <div className="flex flex-col gap-2 rounded-xl border border-sonar-white/10 bg-sonar-white/5 p-3" aria-busy>
          {[0, 1, 2, 3, 4].map((i) => (
            <div key={i} className="h-12 animate-pulse rounded bg-sonar-white/5" />
          ))}
        </div>
      ) : null}

      {state.kind === 'error' ? (
        <div className="flex flex-col items-center justify-center gap-3 rounded-xl border border-sonar-white/10 p-8" role="alert">
          <p className="text-sm text-sonar-white/80">No se pudo cargar el historial.</p>
          <p className="text-xs text-sonar-white/40">{state.message}</p>
        </div>
      ) : null}

      {state.kind === 'ready' && state.movements.length === 0 ? (
        <div className="flex flex-col items-center justify-center gap-3 rounded-xl border border-sonar-white/10 p-10 text-sonar-white/60">
          <Inbox className="h-8 w-8" strokeWidth={1.25} aria-hidden />
          <p className="text-sm">Sin movimientos todavía.</p>
        </div>
      ) : null}

      {state.kind === 'ready' && state.movements.length > 0 ? (
        <div className="overflow-hidden rounded-xl border border-sonar-white/10" role="table">
          <FixedSizeList<BankMovement[]>
            height={listHeight}
            width="100%"
            itemCount={state.movements.length}
            itemSize={ROW_HEIGHT}
            itemData={state.movements}
          >
            {MovementRow}
          </FixedSizeList>
        </div>
      ) : null}
    </div>
  )
}
