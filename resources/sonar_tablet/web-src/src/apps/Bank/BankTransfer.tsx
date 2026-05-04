/**
 * SONAR Tablet — Bank Transfer view (S2.4).
 *
 * Form controlled (React state, NO libs externas) → C002 `sonar:bank:transfer`
 * vía forwarder NUI. Anti-double-submit: botón disabled durante request +
 * request_id UUID v4 cliente (idempotency garantizada DB-backed server-side).
 *
 * Errors mapeados human-readable vía `translateError()` (SSoT §3.2 codes +
 * callbacks.lua:317-327 — DC-S2.4.4).
 */
import { useMemo, useState } from 'react'
import { AlertTriangle, ArrowLeft, CheckCircle2, Loader2 } from 'lucide-react'
import { transfer, translateError, uuidv4 } from './bankApi'
import {
  BankApiError,
  type BankBalance,
  type BankErrorCode,
  type TransferResponseData,
} from './types'

const EUR = new Intl.NumberFormat('es-ES', {
  style: 'currency',
  currency: 'EUR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
})

const MAX_CONCEPT = 120
const MIN_AMOUNT = 0.01
const MAX_AMOUNT = 1_000_000

type SubmitState =
  | { kind: 'idle' }
  | { kind: 'submitting' }
  | { kind: 'success'; data: TransferResponseData }
  | { kind: 'error'; error_code: BankErrorCode; message: string }

export interface BankTransferProps {
  /** Balance actual del player — usado para from_iban + preview del remaining. */
  balance: BankBalance | null
  /** Invoked al completar exitosamente — parent refresca overview balance. */
  onSuccessBack: () => void
}

export default function BankTransfer({ balance, onSuccessBack }: BankTransferProps) {
  const [toIban, setToIban] = useState('')
  const [amount, setAmount] = useState('')
  const [concept, setConcept] = useState('')
  const [state, setState] = useState<SubmitState>({ kind: 'idle' })

  const amountNum = useMemo(() => Number.parseFloat(amount.replace(',', '.')), [amount])
  const isValid = useMemo(() => {
    if (!balance) return false
    if (!toIban.trim()) return false
    if (toIban.trim() === balance.iban) return false
    if (!Number.isFinite(amountNum)) return false
    if (amountNum < MIN_AMOUNT || amountNum > MAX_AMOUNT) return false
    return true
  }, [balance, toIban, amountNum])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!balance || state.kind === 'submitting' || !isValid) return

    setState({ kind: 'submitting' })
    // Sound stub (S2.6 real integration).
    // eslint-disable-next-line no-console
    console.debug('[sound] depth_press (transfer submit)')

    try {
      const data = await transfer({
        from_iban: balance.iban,
        to_iban: toIban.trim(),
        amount: amountNum,
        concept: concept.slice(0, MAX_CONCEPT),
        request_id: uuidv4(),
      })
      setState({ kind: 'success', data })
    } catch (err) {
      const code = err instanceof BankApiError ? err.error_code : 'UNKNOWN'
      setState({
        kind: 'error',
        error_code: code,
        message: translateError(code),
      })
    }
  }

  function resetForm() {
    setToIban('')
    setAmount('')
    setConcept('')
    setState({ kind: 'idle' })
  }

  // Success screen — muestra transaction_id + new_balance + CTA back.
  if (state.kind === 'success') {
    return (
      <div className="flex h-full flex-col items-center justify-center gap-5 p-8 text-center" role="status">
        <div className="flex h-16 w-16 items-center justify-center rounded-full border border-sonar-orange/40 bg-sonar-orange/10">
          <CheckCircle2 className="h-8 w-8 text-sonar-orange" strokeWidth={1.5} aria-hidden />
        </div>
        <h3 className="text-lg font-semibold text-sonar-white">Transferencia completada</h3>
        <div className="flex flex-col gap-1 text-xs text-sonar-white/60">
          <span className="font-mono">{state.data.transaction_id}</span>
          <span>
            Nuevo saldo: <span className="font-semibold text-sonar-white">{EUR.format(state.data.new_balance_from)}</span>
          </span>
        </div>
        <button
          type="button"
          onClick={() => {
            resetForm()
            onSuccessBack()
          }}
          className="inline-flex items-center gap-2 rounded-lg border border-sonar-white/10 bg-sonar-white/5 px-4 py-2 text-sm text-sonar-white/80 transition-colors duration-150 hover:text-sonar-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40"
        >
          <ArrowLeft className="h-4 w-4" strokeWidth={1.5} aria-hidden />
          Volver al resumen
        </button>
      </div>
    )
  }

  return (
    <form onSubmit={handleSubmit} className="flex h-full flex-col gap-4 p-6">
      <header className="flex flex-col pb-2">
        <h2 className="text-sm font-semibold text-sonar-white">Nueva transferencia</h2>
        <p className="font-mono text-[10px] uppercase tracking-widest text-sonar-white/40">
          C002 · sonar:bank:transfer
        </p>
      </header>

      {balance ? (
        <p className="text-xs text-sonar-white/40">
          Desde <span className="font-mono text-sonar-white/80">{balance.iban}</span>
          <span className="ml-2">· Saldo {EUR.format(balance.balance)}</span>
        </p>
      ) : (
        <p className="text-xs text-sonar-orange">Balance no disponible. Vuelve al resumen y reintenta.</p>
      )}

      <div className="flex flex-col gap-1.5">
        <label htmlFor="transfer-iban" className="text-xs text-sonar-white/60">
          IBAN destino
        </label>
        <input
          id="transfer-iban"
          type="text"
          value={toIban}
          onChange={(e) => setToIban(e.target.value.toUpperCase())}
          placeholder="SN-XXXX-XXXX-XXXX"
          autoComplete="off"
          spellCheck={false}
          className="rounded-md border border-sonar-white/10 bg-sonar-white/5 px-3 py-2 font-mono text-sm text-sonar-white placeholder:text-sonar-white/30 focus:border-sonar-orange/40 focus:outline-none focus:ring-2 focus:ring-sonar-orange/40"
        />
      </div>

      <div className="flex flex-col gap-1.5">
        <label htmlFor="transfer-amount" className="text-xs text-sonar-white/60">
          Importe (€)
        </label>
        <input
          id="transfer-amount"
          type="number"
          inputMode="decimal"
          step="0.01"
          min={MIN_AMOUNT}
          max={MAX_AMOUNT}
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="0,00"
          className="rounded-md border border-sonar-white/10 bg-sonar-white/5 px-3 py-2 text-sm text-sonar-white placeholder:text-sonar-white/30 focus:border-sonar-orange/40 focus:outline-none focus:ring-2 focus:ring-sonar-orange/40"
        />
      </div>

      <div className="flex flex-col gap-1.5">
        <label htmlFor="transfer-concept" className="flex items-center justify-between text-xs text-sonar-white/60">
          <span>Concepto</span>
          <span className="font-mono text-[10px] text-sonar-white/40">
            {concept.length}/{MAX_CONCEPT}
          </span>
        </label>
        <input
          id="transfer-concept"
          type="text"
          value={concept}
          onChange={(e) => setConcept(e.target.value.slice(0, MAX_CONCEPT))}
          maxLength={MAX_CONCEPT}
          placeholder="Motivo (opcional)"
          className="rounded-md border border-sonar-white/10 bg-sonar-white/5 px-3 py-2 text-sm text-sonar-white placeholder:text-sonar-white/30 focus:border-sonar-orange/40 focus:outline-none focus:ring-2 focus:ring-sonar-orange/40"
        />
      </div>

      {state.kind === 'error' ? (
        <div
          role="alert"
          className="flex items-start gap-2 rounded-md border border-sonar-orange/40 bg-sonar-orange/10 p-3"
        >
          <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-sonar-orange" strokeWidth={1.5} aria-hidden />
          <div className="flex flex-col">
            <span className="text-sm text-sonar-orange">{state.message}</span>
            <span className="font-mono text-[10px] uppercase tracking-widest text-sonar-orange/60">
              {state.error_code}
            </span>
          </div>
        </div>
      ) : null}

      <div className="mt-auto flex items-center gap-3 pt-2">
        <button
          type="submit"
          disabled={!isValid || state.kind === 'submitting'}
          className="inline-flex items-center gap-2 rounded-lg border border-sonar-orange/40 bg-sonar-orange/10 px-5 py-2 text-sm font-medium text-sonar-orange transition-colors duration-150 hover:bg-sonar-orange/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40 disabled:cursor-not-allowed disabled:opacity-40"
        >
          {state.kind === 'submitting' ? (
            <>
              <Loader2 className="h-4 w-4 animate-spin" strokeWidth={1.5} aria-hidden />
              Procesando…
            </>
          ) : (
            'Enviar'
          )}
        </button>
        {Number.isFinite(amountNum) && amountNum > 0 && balance ? (
          <span className="text-xs text-sonar-white/40">
            Saldo tras envío: {EUR.format(balance.balance - amountNum)}
          </span>
        ) : null}
      </div>
    </form>
  )
}
