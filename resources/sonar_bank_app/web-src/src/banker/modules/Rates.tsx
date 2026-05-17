import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import {
  Sliders,
  RotateCcw,
  Save,
  AlertTriangle,
  CheckCircle2,
  Lock,
  Sparkles,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  useBankerRatesCatalog,
  useBankerSetRate,
  useBankerResetRate,
} from '../data/queries'
import { formatRelative } from '../lib/format'
import type { BankerRateItem } from '../data/contractsF3'

// Friendly labels + units for known keys
const KEY_META: Record<string, { label: string; unit: 'bps' | 'minor' | 'pct' | 'count' | 'minor_flat'; description: string }> = {
  savings_interest_rate_bps: {
    label: 'Tasa de interés en ahorros',
    unit: 'bps',
    description: 'APR pagado sobre saldos en cuentas savings.',
  },
  loan_rate_spread_bps: {
    label: 'Spread sobre tasa de préstamos',
    unit: 'bps',
    description: 'Se suma al base_rate de cada producto. Negativo = descuento.',
  },
  transfer_fee_bps: {
    label: 'Comisión por transferencia',
    unit: 'bps',
    description: 'Bps cobrados sobre el monto de cada transferencia.',
  },
  atm_fee_minor_flat: {
    label: 'Comisión fija por ATM',
    unit: 'minor_flat',
    description: 'Cobrada en céntimos por retiro en cajero.',
  },
  card_issue_fee_minor: {
    label: 'Coste de emisión de tarjeta',
    unit: 'minor_flat',
    description: 'Pago único al emitir una tarjeta nueva.',
  },
  daily_transfer_limit_minor: {
    label: 'Límite diario de transferencia',
    unit: 'minor_flat',
    description: 'Máximo por cuenta y por día.',
  },
  shared_account_min_minor: {
    label: 'Saldo mínimo cuenta shared',
    unit: 'minor_flat',
    description: 'Reserva exigida para abrir una cuenta compartida.',
  },
}

function formatValue(value: number, unit: string): string {
  if (unit === 'bps') return (value / 100).toFixed(2) + '%'
  if (unit === 'pct') return value.toFixed(2) + '%'
  if (unit === 'minor_flat' || unit === 'minor') return '€' + (value / 100).toFixed(2)
  return value.toString()
}

export function BankerRates() {
  const catalog = useBankerRatesCatalog()
  const items = catalog.data?.items ?? []
  const canEdit = catalog.data?.can_edit ?? false

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
            <Sliders size={18} className="text-[var(--banker-primary)]" />
          </div>
          <div className="flex-1">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">Política económica</p>
            <h1 className="text-2xl font-semibold text-text-primary">Tasas y comisiones</h1>
            <p className="mt-1 text-sm text-text-secondary">
              Ajusta el motor económico dentro de las bandas configuradas por el servidor.
              Los cambios entran en efecto inmediatamente.
            </p>
          </div>
          {!canEdit && (
            <span className="flex items-center gap-1.5 rounded-lg border border-white/10 bg-white/[0.03] px-3 py-1.5 text-[11px] text-text-tertiary">
              <Lock size={11} /> Solo lectura
            </span>
          )}
        </div>
      </motion.section>

      {/* List */}
      {catalog.isLoading ? (
        <ul className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <li key={i} className="h-32 animate-pulse rounded-2xl border border-white/[0.06] bg-white/[0.02]" />
          ))}
        </ul>
      ) : items.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-white/10 bg-white/[0.01] p-10 text-center">
          <p className="text-sm text-text-tertiary">No hay parámetros configurables.</p>
        </div>
      ) : (
        <ul className="space-y-3">
          {items.map((item) => (
            <RateCard key={item.key} item={item} canEdit={canEdit} />
          ))}
        </ul>
      )}
    </div>
  )
}

// ============================ Rate Card ============================

function RateCard({ item, canEdit }: { item: BankerRateItem; canEdit: boolean }) {
  const meta = KEY_META[item.key] ?? { label: item.key, unit: 'count' as const, description: '' }
  const setRate = useBankerSetRate()
  const resetRate = useBankerResetRate()

  const [draft, setDraft] = useState(item.effective)
  const [savedFlash, setSavedFlash] = useState(false)

  // Sync local draft when server pushes a fresh value
  useEffect(() => {
    setDraft(item.effective)
  }, [item.effective])

  // Snapshot on flash
  useEffect(() => {
    if (!savedFlash) return
    const t = window.setTimeout(() => setSavedFlash(false), 1400)
    return () => window.clearTimeout(t)
  }, [savedFlash])

  const dirty = draft !== item.effective
  const error = setRate.error?.message

  const handleApply = () => {
    setRate.mutate(
      { key: item.key, value: draft },
      { onSuccess: () => setSavedFlash(true) },
    )
  }

  const handleReset = () => {
    if (!item.has_override) return
    resetRate.mutate({ key: item.key })
  }

  return (
    <motion.li
      layout
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.18 }}
      className={cn(
        'rounded-2xl border p-5 transition-colors',
        item.has_override
          ? 'border-[var(--banker-primary)]/30 bg-[radial-gradient(ellipse_at_top_left,rgba(255,100,19,0.08),transparent_55%),rgba(255,255,255,0.02)]'
          : 'border-white/[0.08] bg-white/[0.02]',
      )}
    >
      <div className="flex items-start justify-between gap-6">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <p className="text-sm font-semibold text-text-primary">{meta.label}</p>
            {item.has_override && (
              <span className="rounded-full border border-[var(--banker-primary)]/30 bg-[var(--banker-primary)]/10 px-2 py-0.5 text-[9px] font-semibold uppercase tracking-wider text-[var(--banker-primary)]">
                Override
              </span>
            )}
          </div>
          <p className="mt-1 text-xs text-text-tertiary">{meta.description}</p>
          <p className="mt-1 font-mono text-[10px] text-text-tertiary">{item.key}</p>
        </div>

        <div className="text-right">
          <p className="text-[10px] uppercase tracking-wider text-text-tertiary">Valor activo</p>
          <p className="text-2xl font-semibold text-text-primary">
            {formatValue(item.effective, meta.unit)}
          </p>
          {item.has_override && (
            <p className="text-[11px] text-text-tertiary">
              Default: {formatValue(item.default, meta.unit)}
            </p>
          )}
        </div>
      </div>

      {/* Slider */}
      {canEdit && (
        <div className="mt-5 space-y-3">
          <div className="flex items-center gap-3">
            <span className="font-mono text-[11px] text-text-tertiary w-20">
              {formatValue(item.min, meta.unit)}
            </span>
            <input
              type="range"
              min={item.min}
              max={item.max}
              step={item.step}
              value={draft}
              onChange={(e) => setDraft(Number(e.target.value))}
              className="banker-slider flex-1"
              style={{
                background: `linear-gradient(to right, var(--banker-primary) 0%, var(--banker-primary) ${
                  ((draft - item.min) / (item.max - item.min)) * 100
                }%, rgba(255,255,255,0.08) ${
                  ((draft - item.min) / (item.max - item.min)) * 100
                }%, rgba(255,255,255,0.08) 100%)`,
              }}
            />
            <span className="font-mono text-[11px] text-text-tertiary w-20 text-right">
              {formatValue(item.max, meta.unit)}
            </span>
          </div>

          <div className="flex items-center justify-between gap-3">
            <input
              type="number"
              value={draft}
              min={item.min}
              max={item.max}
              step={item.step}
              onChange={(e) => setDraft(Number(e.target.value))}
              className="w-32 rounded-lg border border-white/10 bg-black/30 px-3 py-1.5 text-sm font-mono text-text-primary focus:border-[var(--banker-primary)] focus:outline-none"
            />
            <p className="text-xs text-text-secondary">
              <span className="text-text-tertiary">Borrador:</span>{' '}
              <span className="font-semibold text-text-primary">
                {formatValue(draft, meta.unit)}
              </span>
            </p>
            <div className="flex gap-2">
              <button
                onClick={handleReset}
                disabled={!item.has_override || resetRate.isPending}
                className="flex items-center gap-1.5 rounded-lg border border-white/10 bg-white/[0.03] px-3 py-2 text-xs font-medium text-text-secondary transition hover:bg-white/[0.07] disabled:opacity-40"
              >
                <RotateCcw size={12} /> Resetear
              </button>
              <button
                onClick={handleApply}
                disabled={!dirty || setRate.isPending}
                className={cn(
                  'flex items-center gap-1.5 rounded-lg border px-3 py-2 text-xs font-semibold transition disabled:opacity-40',
                  dirty
                    ? 'border-[var(--banker-primary)]/40 bg-[var(--banker-primary)] text-black hover:brightness-110'
                    : 'border-white/10 bg-white/[0.03] text-text-tertiary',
                )}
              >
                {savedFlash ? <CheckCircle2 size={12} /> : <Save size={12} />}
                {savedFlash ? 'Aplicado' : 'Aplicar'}
              </button>
            </div>
          </div>

          {/* Footer info */}
          <AnimatePresence>
            {(item.updated_at_ms || error) && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="flex items-center justify-between gap-2 pt-2"
              >
                {error ? (
                  <div className="flex items-center gap-1.5 text-[11px] text-red-300">
                    <AlertTriangle size={12} /> {error}
                  </div>
                ) : (
                  <p className="text-[10px] text-text-tertiary">
                    <Sparkles size={10} className="inline-block mr-1 opacity-60" />
                    {item.updated_by} · {item.updated_by_role} · {formatRelative(item.updated_at_ms)}
                  </p>
                )}
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      )}
    </motion.li>
  )
}
