import { useState } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import {
  ShieldAlert,
  CheckCircle2,
  XCircle,
  RefreshCw,
  AlertTriangle,
  AlertOctagon,
  Info,
  Megaphone,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { useBankerComplianceList, useBankerComplianceResolve } from '../data/queries'
import { formatMinor, formatRelative } from '../lib/format'
import type {
  BankerComplianceFlag,
  ComplianceFlagSeverity,
  ComplianceFlagStatus,
} from '../data/contractsF5'

const STATUS_FILTERS: { id: ComplianceFlagStatus | ''; label: string }[] = [
  { id: '',                label: 'Todas' },
  { id: 'open',            label: 'Abiertas' },
  { id: 'investigating',   label: 'En revisión' },
  { id: 'resolved',        label: 'Resueltas' },
  { id: 'false_positive',  label: 'Falsos pos.' },
]

const SEVERITY_FILTERS: { id: ComplianceFlagSeverity | ''; label: string }[] = [
  { id: '',         label: 'Todas' },
  { id: 'critical', label: 'Crítica' },
  { id: 'warning',  label: 'Warning' },
  { id: 'notice',   label: 'Notice' },
  { id: 'info',     label: 'Info' },
]

const SEVERITY_STYLE: Record<ComplianceFlagSeverity, { ring: string; text: string; icon: typeof AlertOctagon }> = {
  critical: { ring: 'border-red-400/30 bg-red-400/[0.04]',  text: 'text-red-200', icon: AlertOctagon },
  warning:  { ring: 'border-amber-400/30 bg-amber-400/[0.04]', text: 'text-amber-200', icon: AlertTriangle },
  notice:   { ring: 'border-cyan-400/30 bg-cyan-400/[0.04]', text: 'text-cyan-200', icon: Megaphone },
  info:     { ring: 'border-white/[0.08] bg-white/[0.02]',   text: 'text-text-secondary', icon: Info },
}

export function BankerCompliance() {
  const [status, setStatus] = useState<ComplianceFlagStatus | ''>('open')
  const [severity, setSeverity] = useState<ComplianceFlagSeverity | ''>('')
  const list = useBankerComplianceList(status, severity)
  const items = list.data?.items ?? []

  return (
    <div className="px-8 py-7 space-y-6">
      <motion.section
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className="rounded-3xl border border-white/10 bg-white/[0.025] p-6"
      >
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/10 bg-white/[0.04]">
            <ShieldAlert size={18} className="text-[var(--banker-primary)]" />
          </div>
          <div className="flex-1">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">Riesgo y compliance</p>
            <h1 className="text-2xl font-semibold text-text-primary">Compliance</h1>
            <p className="mt-1 text-sm text-text-secondary">
              Revisa banderas levantadas por el motor anti-fraude del servidor y decide su resolución.
            </p>
          </div>
          <button
            onClick={() => list.refetch()}
            disabled={list.isFetching}
            className="flex items-center gap-2 rounded-xl border border-white/10 bg-white/[0.03] px-3 py-2 text-xs text-text-secondary transition hover:bg-white/[0.06] disabled:opacity-50"
          >
            <RefreshCw size={13} className={list.isFetching ? 'animate-spin' : ''} />
            Refrescar
          </button>
        </div>
      </motion.section>

      {/* Filters */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        <FilterChips
          label="Estado"
          options={STATUS_FILTERS}
          value={status}
          onChange={(v) => setStatus(v as ComplianceFlagStatus | '')}
        />
        <FilterChips
          label="Severidad"
          options={SEVERITY_FILTERS}
          value={severity}
          onChange={(v) => setSeverity(v as ComplianceFlagSeverity | '')}
        />
      </div>

      {/* List */}
      {list.isLoading ? (
        <ul className="space-y-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <li key={i} className="h-24 animate-pulse rounded-2xl border border-white/[0.06] bg-white/[0.02]" />
          ))}
        </ul>
      ) : items.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-white/10 bg-white/[0.01] p-10 text-center">
          <p className="text-sm text-text-tertiary">Sin banderas que coincidan con el filtro.</p>
        </div>
      ) : (
        <ul className="space-y-3">
          <AnimatePresence>
            {items.map((flag) => (
              <FlagCard key={flag.flag_id} flag={flag} />
            ))}
          </AnimatePresence>
        </ul>
      )}
    </div>
  )
}

// ============================ Filter chips ============================

function FilterChips<T extends string>({
  label,
  options,
  value,
  onChange,
}: {
  label: string
  options: { id: T; label: string }[]
  value: T
  onChange: (v: T) => void
}) {
  return (
    <div className="rounded-2xl border border-white/[0.06] bg-white/[0.02] p-3">
      <p className="mb-2 text-[10px] uppercase tracking-[0.18em] text-text-tertiary">{label}</p>
      <div className="flex flex-wrap gap-2">
        {options.map((o) => {
          const active = o.id === value
          return (
            <button
              key={o.id || 'all'}
              onClick={() => onChange(o.id)}
              className={cn(
                'rounded-full border px-3 py-1 text-[11px] font-medium transition',
                active
                  ? 'border-[var(--banker-primary)]/40 bg-[var(--banker-primary)]/10 text-[var(--banker-primary)]'
                  : 'border-white/10 bg-white/[0.02] text-text-secondary hover:bg-white/[0.05]',
              )}
            >
              {o.label}
            </button>
          )
        })}
      </div>
    </div>
  )
}

// ============================ Flag card ============================

function FlagCard({ flag }: { flag: BankerComplianceFlag }) {
  const resolve = useBankerComplianceResolve()
  const style = SEVERITY_STYLE[flag.severity] ?? SEVERITY_STYLE.info
  const Icon = style.icon
  const closed = flag.status === 'resolved' || flag.status === 'false_positive'

  return (
    <motion.li
      layout
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.97 }}
      transition={{ duration: 0.2 }}
      className={cn('rounded-2xl border p-5', style.ring, closed && 'opacity-70')}
    >
      <div className="grid grid-cols-1 md:grid-cols-[auto_2fr_1fr_1fr_auto] gap-4 items-center">
        <div className={cn('flex h-9 w-9 items-center justify-center rounded-xl border border-white/10 bg-black/30', style.text)}>
          <Icon size={16} />
        </div>
        <div>
          <div className="flex items-center gap-2">
            <span className={cn('text-sm font-semibold', style.text)}>
              {flag.flag_type.replace(/_/g, ' ')}
            </span>
            <span className="rounded-full border border-white/10 bg-white/[0.03] px-2 py-0.5 text-[9px] font-semibold uppercase tracking-wider text-text-tertiary">
              {flag.status.replace(/_/g, ' ')}
            </span>
          </div>
          <p className="mt-0.5 text-[11px] text-text-tertiary">
            {flag.citizen_id ? `Cliente ${flag.citizen_id}` : 'Cliente anónimo'}
            {flag.iban ? ` · ${flag.iban}` : ''}
          </p>
          <p className="mt-1 text-[10px] text-text-tertiary">
            {flag.raised_by ?? 'system'} · {formatRelative(flag.raised_ms)}
          </p>
        </div>
        <div>
          <p className="text-[10px] uppercase text-text-tertiary">Observado</p>
          <p className="text-sm font-semibold text-text-primary">
            {flag.observed_value_minor != null ? formatMinor(flag.observed_value_minor) : '—'}
          </p>
        </div>
        <div>
          <p className="text-[10px] uppercase text-text-tertiary">Umbral</p>
          <p className="text-sm font-semibold text-text-primary">
            {flag.threshold_minor != null ? formatMinor(flag.threshold_minor) : '—'}
          </p>
        </div>
        <div className="flex justify-end gap-2">
          {!closed ? (
            <>
              <button
                onClick={() => {
                  const note = window.prompt('Acción tomada (opcional):') ?? ''
                  resolve.mutate({ flag_id: flag.flag_id, decision: 'resolved', note: note || undefined })
                }}
                disabled={resolve.isPending}
                className="flex items-center gap-1.5 rounded-lg border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-xs font-semibold text-emerald-200 transition hover:bg-emerald-400/20 disabled:opacity-40"
              >
                <CheckCircle2 size={12} /> Resolver
              </button>
              <button
                onClick={() => {
                  const note = window.prompt('Motivo (false positive):') ?? ''
                  if (!note) return
                  resolve.mutate({ flag_id: flag.flag_id, decision: 'false_positive', note })
                }}
                disabled={resolve.isPending}
                className="flex items-center gap-1.5 rounded-lg border border-white/15 bg-white/[0.03] px-3 py-2 text-xs font-semibold text-text-secondary transition hover:bg-white/[0.07] disabled:opacity-40"
              >
                <XCircle size={12} /> False pos.
              </button>
            </>
          ) : (
            <span className="text-[11px] text-text-tertiary italic">
              Cerrada · {flag.resolved_ms ? formatRelative(flag.resolved_ms) : ''}
            </span>
          )}
        </div>
      </div>
    </motion.li>
  )
}
