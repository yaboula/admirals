import { useEffect, useState } from 'react'
import { motion } from 'motion/react'
import {
  Palette,
  Save,
  RotateCcw,
  CheckCircle2,
  AlertTriangle,
  Lock,
  Eye,
  Building2,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  useBankerBranding,
  useBankerBrandingSet,
  useBankerBrandingReset,
} from '../data/queries'
import { formatRelative } from '../lib/format'
import type { BankerBrandingField, BankerBrandingFieldState } from '../data/contractsF4'

interface FieldDef {
  field: BankerBrandingField
  label: string
  hint: string
  type: 'text' | 'color' | 'textarea' | 'url'
  maxLength?: number
}

const FIELDS: FieldDef[] = [
  { field: 'bank_name',       label: 'Nombre del banco',  hint: 'Visible en la cabecera y dashboards (1-32 caracteres).', type: 'text',     maxLength: 32 },
  { field: 'primary_color',   label: 'Color primario',    hint: 'Utilizado para acentos, sliders y CTAs (formato #RRGGBB).', type: 'color' },
  { field: 'accent_color',    label: 'Color acento',      hint: 'Color secundario, gradientes y badges.', type: 'color' },
  { field: 'welcome_message', label: 'Mensaje de bienvenida', hint: 'Mostrado en el dashboard del banker (≤ 160 caracteres).', type: 'textarea', maxLength: 160 },
  { field: 'logo_url',        label: 'URL del logo',      hint: 'HTTPS recomendado. Vacío usa el logo default.',  type: 'url',      maxLength: 256 },
]

export function BankerBranding() {
  const branding = useBankerBranding()
  const fields = branding.data?.fields
  const canEdit = branding.data?.can_edit ?? false

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
            <Palette size={18} className="text-[var(--banker-primary)]" />
          </div>
          <div className="flex-1">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">Identidad visual</p>
            <h1 className="text-2xl font-semibold text-text-primary">Branding</h1>
            <p className="mt-1 text-sm text-text-secondary">
              Personaliza el banco con tus propios colores, nombre y mensaje. Los cambios se aplican en tiempo real.
            </p>
          </div>
          {!canEdit && (
            <span className="flex items-center gap-1.5 rounded-lg border border-white/10 bg-white/[0.03] px-3 py-1.5 text-[11px] text-text-tertiary">
              <Lock size={11} /> Solo CEO puede editar
            </span>
          )}
        </div>
      </motion.section>

      {/* Live preview */}
      {fields && (
        <BrandingPreview
          bankName={fields.bank_name.effective}
          primary={fields.primary_color.effective || '#FF6413'}
          accent={fields.accent_color.effective || '#FFB047'}
          welcome={fields.welcome_message.effective}
        />
      )}

      {/* Editor list */}
      {branding.isLoading ? (
        <ul className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <li key={i} className="h-28 animate-pulse rounded-2xl border border-white/[0.06] bg-white/[0.02]" />
          ))}
        </ul>
      ) : !fields ? (
        <div className="rounded-2xl border border-dashed border-white/10 bg-white/[0.01] p-10 text-center">
          <p className="text-sm text-text-tertiary">No se pudo cargar el branding.</p>
        </div>
      ) : (
        <ul className="space-y-3">
          {FIELDS.map((def) => (
            <BrandingField
              key={def.field}
              def={def}
              state={fields[def.field]}
              canEdit={canEdit}
            />
          ))}
        </ul>
      )}
    </div>
  )
}

// ============================ Preview ============================

function BrandingPreview({
  bankName,
  primary,
  accent,
  welcome,
}: {
  bankName: string
  primary: string
  accent: string
  welcome: string
}) {
  return (
    <div className="rounded-3xl border border-white/10 bg-black/40 p-6">
      <div className="flex items-center gap-2 mb-4">
        <Eye size={14} className="text-text-tertiary" />
        <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">Preview en vivo</p>
      </div>
      <div
        className="rounded-2xl border border-white/10 p-6"
        style={{
          background: `radial-gradient(ellipse at top right, ${primary}1F, transparent 55%), rgba(255,255,255,0.025)`,
        }}
      >
        <div className="flex items-center gap-3">
          <div
            className="flex h-12 w-12 items-center justify-center rounded-2xl border border-white/15"
            style={{ background: `linear-gradient(135deg, ${primary}, ${accent})` }}
          >
            <Building2 size={20} className="text-white" />
          </div>
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">Bank Owner</p>
            <p className="text-lg font-semibold text-text-primary">{bankName || 'SONAR Bank'}</p>
          </div>
        </div>
        <p className="mt-4 text-sm text-text-secondary">{welcome || 'Welcome to SONAR Bank.'}</p>
        <div className="mt-4 flex gap-2">
          <span
            className="rounded-full px-3 py-1 text-[10px] font-semibold uppercase tracking-wider text-black"
            style={{ background: primary }}
          >
            Primary
          </span>
          <span
            className="rounded-full px-3 py-1 text-[10px] font-semibold uppercase tracking-wider text-black"
            style={{ background: accent }}
          >
            Accent
          </span>
        </div>
      </div>
    </div>
  )
}

// ============================ Field row ============================

function BrandingField({
  def,
  state,
  canEdit,
}: {
  def: FieldDef
  state: BankerBrandingFieldState
  canEdit: boolean
}) {
  const setField = useBankerBrandingSet()
  const resetField = useBankerBrandingReset()
  const [draft, setDraft] = useState(state.effective ?? '')
  const [savedFlash, setSavedFlash] = useState(false)

  useEffect(() => setDraft(state.effective ?? ''), [state.effective])

  useEffect(() => {
    if (!savedFlash) return
    const t = window.setTimeout(() => setSavedFlash(false), 1400)
    return () => window.clearTimeout(t)
  }, [savedFlash])

  const dirty = draft !== state.effective
  const error = setField.error?.message

  return (
    <motion.li
      layout
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.18 }}
      className={cn(
        'rounded-2xl border p-5',
        state.has_override
          ? 'border-[var(--banker-primary)]/30 bg-[radial-gradient(ellipse_at_top_left,rgba(255,100,19,0.06),transparent_55%),rgba(255,255,255,0.02)]'
          : 'border-white/[0.08] bg-white/[0.02]',
      )}
    >
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <p className="text-sm font-semibold text-text-primary">{def.label}</p>
            {state.has_override && (
              <span className="rounded-full border border-[var(--banker-primary)]/30 bg-[var(--banker-primary)]/10 px-2 py-0.5 text-[9px] font-semibold uppercase tracking-wider text-[var(--banker-primary)]">
                Override
              </span>
            )}
          </div>
          <p className="mt-1 text-xs text-text-tertiary">{def.hint}</p>
          {state.updated_at_ms && (
            <p className="mt-1 text-[10px] text-text-tertiary">
              Última edición: {state.updated_by} · {state.updated_by_role} · {formatRelative(state.updated_at_ms)}
            </p>
          )}
        </div>
        {state.has_override && canEdit && (
          <button
            onClick={() => resetField.mutate({ field: def.field })}
            disabled={resetField.isPending}
            className="flex items-center gap-1.5 rounded-lg border border-white/10 bg-white/[0.03] px-3 py-1.5 text-[11px] font-medium text-text-secondary transition hover:bg-white/[0.07] disabled:opacity-40"
          >
            <RotateCcw size={11} /> Default
          </button>
        )}
      </div>

      {/* Editor */}
      <div className="mt-4 flex items-stretch gap-3">
        {def.type === 'color' ? (
          <div className="flex flex-1 items-stretch gap-2">
            <input
              type="color"
              value={draft || '#000000'}
              onChange={(e) => setDraft(e.target.value)}
              disabled={!canEdit}
              className="h-10 w-14 cursor-pointer rounded-lg border border-white/10 bg-black/30 disabled:opacity-50"
            />
            <input
              type="text"
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              disabled={!canEdit}
              maxLength={7}
              placeholder="#FF6413"
              className="flex-1 rounded-lg border border-white/10 bg-black/30 px-3 py-2 text-sm font-mono text-text-primary focus:border-[var(--banker-primary)] focus:outline-none disabled:opacity-50"
            />
          </div>
        ) : def.type === 'textarea' ? (
          <textarea
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            disabled={!canEdit}
            maxLength={def.maxLength}
            rows={2}
            className="flex-1 resize-none rounded-lg border border-white/10 bg-black/30 px-3 py-2 text-sm text-text-primary focus:border-[var(--banker-primary)] focus:outline-none disabled:opacity-50"
          />
        ) : (
          <input
            type={def.type === 'url' ? 'url' : 'text'}
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            disabled={!canEdit}
            maxLength={def.maxLength}
            placeholder={state.default}
            className="flex-1 rounded-lg border border-white/10 bg-black/30 px-3 py-2 text-sm text-text-primary focus:border-[var(--banker-primary)] focus:outline-none disabled:opacity-50"
          />
        )}
        {canEdit && (
          <button
            onClick={() => {
              setField.mutate(
                { field: def.field, value: draft },
                { onSuccess: () => setSavedFlash(true) },
              )
            }}
            disabled={!dirty || setField.isPending}
            className={cn(
              'flex items-center gap-1.5 rounded-lg border px-3 py-2 text-xs font-semibold transition disabled:opacity-40',
              dirty
                ? 'border-[var(--banker-primary)]/40 bg-[var(--banker-primary)] text-black hover:brightness-110'
                : 'border-white/10 bg-white/[0.03] text-text-tertiary',
            )}
          >
            {savedFlash ? <CheckCircle2 size={12} /> : <Save size={12} />}
            {savedFlash ? 'OK' : 'Guardar'}
          </button>
        )}
      </div>

      {error && (
        <div className="mt-3 flex items-center gap-1.5 text-[11px] text-red-300">
          <AlertTriangle size={12} /> {error}
        </div>
      )}
    </motion.li>
  )
}
