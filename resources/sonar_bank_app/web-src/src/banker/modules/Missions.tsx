import { useState } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import {
  Compass,
  Plus,
  Hand,
  CheckCircle2,
  RefreshCw,
  Banknote,
  Truck,
  CreditCard,
  ShieldCheck,
  FileText,
  HardHat,
  type LucideIcon,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  useBankerMissions,
  useBankerMissionDispatch,
  useBankerMissionAssign,
  useBankerMissionComplete,
} from '../data/queries'
import { formatMinor, formatRelative } from '../lib/format'
import type {
  BankerMission,
  MissionState,
  MissionType,
} from '../data/contractsF6'

const MISSION_META: Record<MissionType, { label: string; icon: LucideIcon; tint: string }> = {
  atm_refill:         { label: 'Recarga ATM',           icon: Banknote,   tint: '#22D3EE' },
  card_production:    { label: 'Producir tarjeta',     icon: CreditCard, tint: '#A78BFA' },
  vault_audit:        { label: 'Auditoría bóveda',     icon: ShieldCheck, tint: '#F472B6' },
  loan_collection:    { label: 'Cobro de préstamo',    icon: HardHat,    tint: '#FFB047' },
  cash_transport_b2b: { label: 'Transporte B2B',       icon: Truck,      tint: '#34D399' },
  document_delivery:  { label: 'Entrega documentos',   icon: FileText,   tint: '#94A3B8' },
}

const STATE_FILTERS: { id: MissionState | ''; label: string }[] = [
  { id: '',           label: 'Todas' },
  { id: 'open',       label: 'Abiertas' },
  { id: 'assigned',   label: 'Asignadas' },
  { id: 'in_progress',label: 'En curso' },
  { id: 'completed',  label: 'Completadas' },
]

export function BankerMissions() {
  const [state, setState] = useState<MissionState | ''>('')
  const list = useBankerMissions(state)
  const items = list.data?.items ?? []
  const catalog = list.data?.catalog
  const canDispatch = list.data?.can_dispatch ?? false
  const canAccept = list.data?.can_accept ?? false

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
            <Compass size={18} className="text-[var(--banker-primary)]" />
          </div>
          <div className="flex-1">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">Gameplay loop</p>
            <h1 className="text-2xl font-semibold text-text-primary">Misiones</h1>
            <p className="mt-1 text-sm text-text-secondary">
              Despacha trabajos al equipo y deja que tellers / advisors los acepten.
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

      {/* Dispatch panel */}
      {canDispatch && catalog && (
        <DispatchPanel catalog={catalog} />
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-2">
        {STATE_FILTERS.map((s) => {
          const active = s.id === state
          return (
            <button
              key={s.id || 'all'}
              onClick={() => setState(s.id)}
              className={cn(
                'rounded-full border px-3 py-1.5 text-[11px] font-medium transition',
                active
                  ? 'border-[var(--banker-primary)]/40 bg-[var(--banker-primary)]/10 text-[var(--banker-primary)]'
                  : 'border-white/10 bg-white/[0.02] text-text-secondary hover:bg-white/[0.05]',
              )}
            >
              {s.label}
            </button>
          )
        })}
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
          <p className="text-sm text-text-tertiary">No hay misiones que coincidan.</p>
        </div>
      ) : (
        <ul className="space-y-3">
          <AnimatePresence>
            {items.map((m) => (
              <MissionRow key={m.mission_id} mission={m} canAccept={canAccept} />
            ))}
          </AnimatePresence>
        </ul>
      )}
    </div>
  )
}

// ============================ Dispatch ============================

function DispatchPanel({ catalog }: { catalog: Record<MissionType, { base_reward_minor: number }> }) {
  const dispatch = useBankerMissionDispatch()
  const [selected, setSelected] = useState<MissionType>('atm_refill')
  const baseReward = catalog[selected]?.base_reward_minor ?? 0
  const [reward, setReward] = useState<number>(baseReward)

  // Sync default reward when catalog/selected changes
  if (catalog[selected]?.base_reward_minor != null && reward === 0 && baseReward > 0) {
    // bootstrap initial value once
    setReward(baseReward)
  }

  const types = Object.keys(catalog) as MissionType[]

  return (
    <div className="rounded-3xl border border-white/10 bg-[radial-gradient(ellipse_at_top_right,rgba(255,100,19,0.08),transparent_55%),rgba(255,255,255,0.025)] p-6">
      <p className="mb-4 text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">
        Despachar nueva misión
      </p>
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        {types.map((t) => {
          const meta = MISSION_META[t]
          const Icon = meta.icon
          const active = selected === t
          return (
            <button
              key={t}
              onClick={() => {
                setSelected(t)
                setReward(catalog[t]?.base_reward_minor ?? 0)
              }}
              className={cn(
                'rounded-2xl border p-3 text-left transition',
                active
                  ? 'border-[var(--banker-primary)]/40 bg-white/[0.05]'
                  : 'border-white/10 bg-white/[0.02] hover:bg-white/[0.04]',
              )}
            >
              <Icon size={16} style={{ color: active ? 'var(--banker-primary)' : meta.tint }} />
              <p className="mt-2 text-xs font-semibold text-text-primary">{meta.label}</p>
              <p className="text-[10px] text-text-tertiary">{formatMinor(catalog[t].base_reward_minor)}</p>
            </button>
          )
        })}
      </div>
      <div className="mt-5 flex items-center gap-3">
        <div>
          <p className="text-[10px] uppercase text-text-tertiary">Recompensa (céntimos)</p>
          <input
            type="number"
            min={0}
            step={100}
            value={reward}
            onChange={(e) => setReward(Number(e.target.value))}
            className="mt-1 w-40 rounded-lg border border-white/10 bg-black/30 px-3 py-2 font-mono text-sm text-text-primary focus:border-[var(--banker-primary)] focus:outline-none"
          />
        </div>
        <p className="text-xs text-text-secondary">
          = <span className="font-semibold text-text-primary">{formatMinor(reward)}</span>
        </p>
        <div className="flex-1" />
        <button
          onClick={() => dispatch.mutate({ mission_type: selected, reward_minor: reward })}
          disabled={dispatch.isPending || reward < 0}
          className="flex items-center gap-1.5 rounded-lg border border-[var(--banker-primary)]/40 bg-[var(--banker-primary)] px-4 py-2 text-xs font-semibold text-black transition hover:brightness-110 disabled:opacity-40"
        >
          <Plus size={13} /> Despachar
        </button>
      </div>
    </div>
  )
}

// ============================ Mission row ============================

function MissionRow({ mission, canAccept }: { mission: BankerMission; canAccept: boolean }) {
  const assign = useBankerMissionAssign()
  const complete = useBankerMissionComplete()
  const meta = MISSION_META[mission.mission_type] ?? MISSION_META.atm_refill
  const Icon = meta.icon

  return (
    <motion.li
      layout
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.97 }}
      transition={{ duration: 0.18 }}
      className="rounded-2xl border border-white/[0.08] bg-white/[0.02] p-5"
    >
      <div className="grid grid-cols-1 md:grid-cols-[auto_2fr_1fr_1fr_auto] gap-4 items-center">
        <div
          className="flex h-9 w-9 items-center justify-center rounded-xl border border-white/10 bg-black/30"
          style={{ color: meta.tint }}
        >
          <Icon size={16} />
        </div>
        <div>
          <p className="text-sm font-semibold text-text-primary">{meta.label}</p>
          <p className="font-mono text-[10px] text-text-tertiary">{mission.mission_id.slice(0, 12)}…</p>
          <p className="mt-1 text-[11px] text-text-tertiary">
            Estado: <span className="font-semibold text-text-secondary">{mission.state}</span>
            {mission.assigned_citizen_id && ` · ${mission.assigned_citizen_id}`}
          </p>
        </div>
        <div>
          <p className="text-[10px] uppercase text-text-tertiary">Recompensa</p>
          <p className="text-sm font-semibold text-text-primary">{formatMinor(mission.reward_minor)}</p>
        </div>
        <div>
          <p className="text-[10px] uppercase text-text-tertiary">Creada</p>
          <p className="text-xs text-text-secondary">{formatRelative(mission.created_ms)}</p>
        </div>
        <div className="flex justify-end gap-2">
          {mission.state === 'open' && canAccept && (
            <button
              onClick={() => assign.mutate({ mission_id: mission.mission_id })}
              disabled={assign.isPending}
              className="flex items-center gap-1.5 rounded-lg border border-cyan-400/30 bg-cyan-400/10 px-3 py-2 text-xs font-semibold text-cyan-200 transition hover:bg-cyan-400/20 disabled:opacity-40"
            >
              <Hand size={12} /> Aceptar
            </button>
          )}
          {(mission.state === 'assigned' || mission.state === 'in_progress') && canAccept && (
            <button
              onClick={() => complete.mutate({ mission_id: mission.mission_id })}
              disabled={complete.isPending}
              className="flex items-center gap-1.5 rounded-lg border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-xs font-semibold text-emerald-200 transition hover:bg-emerald-400/20 disabled:opacity-40"
            >
              <CheckCircle2 size={12} /> Completar
            </button>
          )}
          {mission.state === 'completed' && (
            <span className="text-[11px] italic text-emerald-300">
              Completada {mission.completed_ms ? formatRelative(mission.completed_ms) : ''}
            </span>
          )}
        </div>
      </div>
    </motion.li>
  )
}
