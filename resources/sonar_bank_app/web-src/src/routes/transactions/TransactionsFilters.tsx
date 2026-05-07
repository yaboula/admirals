import { useEffect, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import { Search, X, RotateCcw } from 'lucide-react'
import {
  countActiveFilters,
  useTransactionsFilter,
  type TxDirection,
  type TxRange,
  type TxStatus,
} from '@/stores/transactionsFilter'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'

/**
 * BANK-FE.3 — Filter chips bar.
 *
 * Three chip groups (Range · Direction · Status) + debounced search input.
 * Active chips lift with orange whisper border + tactile depth shadow.
 * The whole row collapses gracefully on narrow viewports (chips wrap).
 */
const RANGE_OPTIONS: Array<{ value: TxRange; label: string }> = [
  { value: '7d', label: '7 días' },
  { value: '30d', label: '30 días' },
  { value: '90d', label: '90 días' },
  { value: 'all', label: 'Todo' },
]

const DIRECTION_OPTIONS: Array<{ value: TxDirection; label: string }> = [
  { value: 'all', label: 'Ambos' },
  { value: 'in', label: 'Entradas' },
  { value: 'out', label: 'Salidas' },
]

const STATUS_OPTIONS: Array<{ value: TxStatus; label: string }> = [
  { value: 'all', label: 'Todos' },
  { value: 'committed', label: 'Confirmadas' },
  { value: 'pending', label: 'Pendientes' },
  { value: 'reverted', label: 'Revertidas' },
]

export function TransactionsFilters() {
  const range = useTransactionsFilter((s) => s.range)
  const direction = useTransactionsFilter((s) => s.direction)
  const status = useTransactionsFilter((s) => s.status)
  const query = useTransactionsFilter((s) => s.query)
  const setRange = useTransactionsFilter((s) => s.setRange)
  const setDirection = useTransactionsFilter((s) => s.setDirection)
  const setStatus = useTransactionsFilter((s) => s.setStatus)
  const setQuery = useTransactionsFilter((s) => s.setQuery)
  const reset = useTransactionsFilter((s) => s.reset)

  const activeCount = countActiveFilters({ range, direction, status, query })

  return (
    <div className="flex flex-wrap items-center gap-2.5">
      <ChipGroup
        label="Periodo"
        options={RANGE_OPTIONS}
        value={range}
        onChange={(v) => setRange(v as TxRange)}
      />
      <Divider />
      <ChipGroup
        label="Tipo"
        options={DIRECTION_OPTIONS}
        value={direction}
        onChange={(v) => setDirection(v as TxDirection)}
      />
      <Divider />
      <ChipGroup
        label="Estado"
        options={STATUS_OPTIONS}
        value={status}
        onChange={(v) => setStatus(v as TxStatus)}
      />

      <div className="flex-1 min-w-[180px] flex items-center justify-end gap-2">
        <SearchInput value={query} onChange={setQuery} />
        <AnimatePresence>
          {activeCount > 0 && (
            <motion.button
              key="reset"
              type="button"
              onClick={() => {
                reset()
                sfx.console_tap()
              }}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              transition={{ duration: 0.18 }}
              className={cn(
                'inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-md',
                'text-[11px] font-semibold text-text-secondary',
                'border border-border-subtle hover:border-border-medium',
                'hover:text-text-primary transition-colors',
                'tactile-focus-ring',
              )}
              aria-label={`Restablecer ${activeCount} filtros activos`}
            >
              <RotateCcw size={12} strokeWidth={2.2} />
              Reset
              <span
                className="ml-0.5 inline-flex items-center justify-center min-w-[16px] h-4 px-1 rounded-full text-[9px] tactile-tabular-nums"
                style={{
                  background: 'var(--gradient-primary)',
                  color: 'oklch(0.10 0.010 270)',
                }}
              >
                {activeCount}
              </span>
            </motion.button>
          )}
        </AnimatePresence>
      </div>
    </div>
  )
}

/* -------------------------------------------------------------------------- */

interface ChipGroupProps<T extends string> {
  label: string
  options: Array<{ value: T; label: string }>
  value: T
  onChange: (v: T) => void
}

function ChipGroup<T extends string>({ label, options, value, onChange }: ChipGroupProps<T>) {
  return (
    <div className="flex items-center gap-2">
      <span className="text-[10px] uppercase tracking-[0.14em] text-text-tertiary font-medium">
        {label}
      </span>
      <div className="flex items-center gap-1">
        {options.map((opt) => {
          const active = opt.value === value
          return (
            <button
              key={opt.value}
              type="button"
              onClick={() => {
                if (!active) {
                  onChange(opt.value)
                  sfx.console_tap()
                }
              }}
              aria-pressed={active}
              className={cn(
                'relative inline-flex items-center px-3 py-1.5 rounded-full',
                'text-[11px] font-medium tracking-tight transition-[color,border-color,background] duration-200',
                'tactile-focus-ring',
                active
                  ? 'text-text-primary'
                  : 'text-text-secondary hover:text-text-primary',
              )}
              style={
                active
                  ? {
                      background:
                        'linear-gradient(135deg, oklch(0.65 0.22 40 / 0.18), oklch(0.65 0.22 40 / 0.06))',
                      border: '1px solid oklch(0.65 0.22 40 / 0.42)',
                      boxShadow:
                        'inset 0 1px 0 oklch(1 0 0 / 0.06), 0 0 0 1px oklch(0 0 0 / 0.4), 0 0 12px -2px oklch(0.65 0.22 40 / 0.32)',
                    }
                  : {
                      background: 'oklch(1 0 0 / 0.02)',
                      border: '1px solid var(--color-border-subtle)',
                    }
              }
            >
              {opt.label}
            </button>
          )
        })}
      </div>
    </div>
  )
}

function Divider() {
  return (
    <span
      aria-hidden
      className="hidden md:inline-block h-5 w-px"
      style={{ background: 'oklch(1 0 0 / 0.06)' }}
    />
  )
}

/* -------------------------------------------------------------------------- */

function SearchInput({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  // Debounce so typing doesn't thrash the filter selector + chart re-renders.
  const [local, setLocal] = useState(value)
  const timer = useRef<number | null>(null)

  useEffect(() => {
    if (value !== local) setLocal(value)
    // Intentional: we only want to sync EXTERNAL resets, not echo our own typing.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value])

  useEffect(() => {
    if (timer.current) window.clearTimeout(timer.current)
    timer.current = window.setTimeout(() => {
      if (local !== value) onChange(local)
    }, 220)
    return () => {
      if (timer.current) window.clearTimeout(timer.current)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [local])

  return (
    <div className="relative flex items-center">
      <Search
        size={13}
        strokeWidth={2}
        className="absolute left-2.5 text-text-tertiary pointer-events-none"
      />
      <input
        type="text"
        value={local}
        onChange={(e) => setLocal(e.target.value)}
        placeholder="Buscar nombre o concepto…"
        aria-label="Buscar transacciones"
        className={cn(
          'tactile-input tactile-focus-ring',
          'pl-7 pr-7 py-1.5 text-[12px] w-[220px]',
          'placeholder:text-text-tertiary',
        )}
      />
      {local.length > 0 && (
        <button
          type="button"
          onClick={() => setLocal('')}
          aria-label="Borrar búsqueda"
          className="absolute right-2 inline-flex items-center justify-center h-4 w-4 rounded-full text-text-tertiary hover:text-text-primary transition-colors"
        >
          <X size={12} strokeWidth={2.2} />
        </button>
      )}
    </div>
  )
}
