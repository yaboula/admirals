import { motion } from 'motion/react'
import { Lock, Wallet, CalendarDays, User2, Sparkles, Snowflake, Settings2, Eye, RotateCw, Check, Palette, Loader2 } from 'lucide-react'
import type { BankCardMock } from '@/data/contracts'
import { Card } from '@/components/ui'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { toast } from '@/stores/toast'
import { resolveCardDesign } from './cardDesigns'
import { useCardsUi, useCardReveal } from '@/stores/cardsUi'
import { useFreezeCard } from '@/data/mutations'

/**
 * BANK-FE.4.2 — CardDetails
 *
 * Right column of the /tarjetas route. Shows the focused card's metadata
 * (holder, expiry, linked IBAN, design) plus a calm preview of the daily and
 * monthly spending meters.
 *
 * Action buttons (Freeze, Limits, Reveal CVV, View transactions) are wired
 * here as DISABLED placeholders so the layout already accommodates them in
 * Phase 4.3. We keep them visible (not hidden) so the founder can review the
 * final visual rhythm during Phase 4.2 sign-off.
 *
 * The Reveal + Flip controls are wired NOW because they have no contract
 * dependency — they manipulate UI state only.
 */
export interface CardDetailsProps {
  card: BankCardMock | null
  className?: string
}

export function CardDetails({ card, className }: CardDetailsProps) {
  if (!card) {
    return (
      <Card variant="glass" padding="md" className={cn('border-white/10 flex flex-col items-center justify-center text-center', className)}>
        <Sparkles size={20} className="text-text-tertiary mb-2" strokeWidth={1.6} />
        <p className="text-sm font-semibold text-text-primary mb-1">Selecciona una tarjeta</p>
        <p className="text-xs text-text-tertiary max-w-[28ch]">
          Toca una tarjeta del carrusel para ver sus detalles.
        </p>
      </Card>
    )
  }

  const design = resolveCardDesign(card.design_id)
  const flippedIds = useCardsUi((s) => s.flippedCardIds)
  const toggleFlip = useCardsUi((s) => s.toggleFlip)
  const openDialog = useCardsUi((s) => s.openDialog)

  const { revealed, remainingMs, reveal, hide } = useCardReveal(card.card_id)
  const remainingSec = Math.ceil(remainingMs / 1000)

  const freezeMutation = useFreezeCard()
  const isLocked = card.status === 'locked'
  const isExpired = card.status === 'expired'
  const freezePending = freezeMutation.isPending

  const flipped = flippedIds.includes(card.card_id)

  const handleToggleReveal = () => {
    if (revealed) {
      hide()
      sfx.console_tap()
    } else {
      reveal()
      sfx.panel_open()
    }
  }

  const handleToggleFreeze = () => {
    if (isExpired) return
    const freeze = !isLocked
    sfx.console_tap()
    freezeMutation.mutate(
      { cardId: card.card_id, freeze },
      {
        onSuccess: () => {
          toast.success(
            freeze ? 'Tarjeta congelada' : 'Tarjeta reactivada',
            freeze
              ? 'Hemos bloqueado todos los pagos. Puedes descongelarla cuando quieras.'
              : 'Tu tarjeta vuelve a estar operativa.',
          )
        },
        onError: (err) => {
          toast.danger('No se pudo cambiar el estado', err.message)
        },
      },
    )
  }

  const expiry = new Date(card.expiry_ms)
  const expiryStr = `${String(expiry.getMonth() + 1).padStart(2, '0')}/${expiry.getFullYear()}`

  const dailyPct = card.daily_limit_minor > 0
    ? Math.min(100, (card.daily_spent_minor / card.daily_limit_minor) * 100)
    : 0
  const monthlyPct = card.monthly_limit_minor > 0
    ? Math.min(100, (card.monthly_spent_minor / card.monthly_limit_minor) * 100)
    : 0

  return (
    <Card variant="glass" padding="md" className={cn('border-white/10 flex flex-col gap-3 2xl:gap-4', className)}>
      {/* Header — design name + tier + status pill */}
      <motion.div
        key={card.card_id}
        initial={{ opacity: 0, y: 4 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.22 }}
        className="flex items-start justify-between gap-3"
      >
        <div className="flex flex-col leading-tight min-w-0">
          <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">
            Diseño
          </span>
          <span className="text-sm font-semibold text-text-primary tactile-wght-breathing tracking-tight truncate">
            {design.name}
          </span>
        </div>
        <StatusPill status={card.status} />
      </motion.div>

      {/* Meta grid — holder · expiry · linked iban · type */}
      <dl className="grid grid-cols-2 gap-x-3 gap-y-2.5">
        <MetaItem icon={User2} label="Titular" value={card.holder_name} />
        <MetaItem icon={CalendarDays} label="Caduca" value={expiryStr} mono />
        <MetaItem icon={Wallet} label="Vinculada" value={maskIbanShort(card.iban)} mono />
        <MetaItem
          icon={Sparkles}
          label="Tipo"
          value={typeLabel(card.card_type)}
        />
      </dl>

      {/* Limits preview — soft meters; full controls land in 4.3 */}
      <div
        className="rounded-xl p-3 flex flex-col gap-2.5"
        style={{
          background: 'oklch(1 0 0 / 0.025)',
          border: '1px solid oklch(1 0 0 / 0.07)',
        }}
      >
        <div className="flex items-center justify-between">
          <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-semibold">
            Límites
          </span>
          <span className="text-[10px] text-text-tertiary opacity-70">
            preview
          </span>
        </div>

        <Meter
          label="Hoy"
          spent={card.daily_spent_minor}
          limit={card.daily_limit_minor}
          pct={dailyPct}
          accent={design.accent}
        />
        <Meter
          label="Este mes"
          spent={card.monthly_spent_minor}
          limit={card.monthly_limit_minor}
          pct={monthlyPct}
          accent={design.accent}
        />
      </div>

      {/* Benefits — tier-driven perks bring brand storytelling into the panel
          and naturally absorb any leftover vertical real-estate. */}
      <BenefitsPanel tier={design.tier} accent={design.accent} className="flex-1 min-h-0" />

      {/* Action row — Phase 4.3: all four actions are now LIVE.
          Reveal toggles a 30s window with countdown surfaced inline.
          Freeze/Unfreeze fires the optimistic mutation + toast feedback.
          Límites + Diseño open dialogs (LimitsModal / DesignPickerDialog). */}
      <div className="flex flex-col gap-2">
        <div className="grid grid-cols-2 gap-2">
          <ActionButton
            icon={Eye}
            label={
              revealed
                ? `Ocultar PAN · ${String(remainingSec).padStart(2, '0')}s`
                : 'Revelar PAN'
            }
            onClick={handleToggleReveal}
            active={revealed}
          />
          <ActionButton
            icon={RotateCw}
            label={flipped ? 'Ver frente' : 'Ver reverso'}
            onClick={() => toggleFlip(card.card_id)}
            active={flipped}
          />
          <ActionButton
            icon={freezePending ? Loader2 : Snowflake}
            iconClassName={freezePending ? 'animate-spin' : undefined}
            label={isLocked ? 'Descongelar' : 'Congelar'}
            onClick={handleToggleFreeze}
            disabled={isExpired || freezePending}
            active={isLocked}
          />
          <ActionButton
            icon={Settings2}
            label="Límites"
            onClick={() => {
              sfx.panel_open()
              openDialog('limits', card.card_id)
            }}
            disabled={isExpired}
          />
        </div>
        <ActionButton
          icon={Palette}
          label="Cambiar diseño"
          onClick={() => {
            sfx.panel_open()
            openDialog('design', card.card_id)
          }}
          disabled={isExpired}
          fullWidth
        />
      </div>
    </Card>
  )
}

/* --------------------------------------------------------------------------
   BenefitsPanel — tier-aware perk list driven by design.tier.
   - default   → 3 baseline perks
   - premium   → +1 cashback / +1 priority support
   - signature → premium set + concierge / early access
   The accent colour ties the check marks to the focused card's chromatic
   identity so the panel reads as part of the same visual story.
   -------------------------------------------------------------------------- */

const BENEFITS_BY_TIER: Record<'default' | 'premium' | 'signature', string[]> = {
  default: [
    'Sin comisiones de mantenimiento',
    'Pagos contactless y por móvil',
    'Notificaciones de gasto en tiempo real',
  ],
  premium: [
    'Cashback 0.5% en compras del día a día',
    'Atención prioritaria 24/7',
    'Sin comisiones de mantenimiento',
    'Pagos contactless y por móvil',
  ],
  signature: [
    'Cashback 1% global · sin tope mensual',
    'Concierge bancario dedicado',
    'Acceso anticipado a nuevas features',
    'Atención prioritaria 24/7',
    'Sin comisiones de mantenimiento',
  ],
}

function BenefitsPanel({
  tier,
  accent,
  className,
}: {
  tier: 'default' | 'premium' | 'signature'
  accent: string
  className?: string
}) {
  const items = BENEFITS_BY_TIER[tier]
  return (
    <div
      className={cn(
        'rounded-xl p-3 flex flex-col gap-2 overflow-hidden',
        className,
      )}
      style={{
        background: 'oklch(1 0 0 / 0.025)',
        border: '1px solid oklch(1 0 0 / 0.07)',
      }}
    >
      <div className="flex items-center justify-between shrink-0">
        <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-semibold">
          Beneficios
        </span>
        <TierBadge tier={tier} />
      </div>
      <ul className="flex flex-col gap-1.5 min-h-0 overflow-y-auto" role="list">
        {items.map((label) => (
          <li
            key={label}
            className="flex items-start gap-2 text-[11px] leading-snug text-text-secondary"
          >
            <Check
              size={11}
              strokeWidth={2.4}
              className="shrink-0 mt-0.5"
              style={{ color: accent, opacity: 0.85 }}
            />
            <span className="truncate">{label}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}

function TierBadge({ tier }: { tier: 'default' | 'premium' | 'signature' }) {
  const label = tier === 'signature' ? 'Signature' : tier === 'premium' ? 'Premium' : 'Estándar'
  return (
    <span
      className="text-[9px] uppercase tracking-[0.16em] font-semibold px-1.5 py-0.5 rounded"
      style={{
        color: 'oklch(0.78 0.012 270)',
        background: 'oklch(1 0 0 / 0.05)',
        border: '1px solid oklch(1 0 0 / 0.10)',
      }}
    >
      {label}
    </span>
  )
}

/* --------------------------------------------------------------------------
   Sub-components
   -------------------------------------------------------------------------- */

function StatusPill({ status }: { status: BankCardMock['status'] }) {
  const config = STATUS_CONFIG[status]
  const Icon = config.icon
  return (
    <span
      className="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-[10px] uppercase tracking-[0.14em] font-semibold shrink-0"
      style={{
        color: config.color,
        background: 'oklch(1 0 0 / 0.04)',
        border: `1px solid ${config.borderColor}`,
      }}
    >
      {Icon && <Icon size={10} strokeWidth={2.4} />}
      {config.label}
    </span>
  )
}

const STATUS_CONFIG: Record<BankCardMock['status'], { label: string; color: string; borderColor: string; icon: typeof Lock | null }> = {
  active: { label: 'Activa', color: 'oklch(0.85 0.14 150)', borderColor: 'oklch(0.85 0.14 150 / 0.25)', icon: null },
  locked: { label: 'Congelada', color: 'oklch(0.78 0.10 230)', borderColor: 'oklch(0.78 0.10 230 / 0.25)', icon: Lock },
  expired: { label: 'Caducada', color: 'oklch(0.65 0.01 270)', borderColor: 'oklch(0.65 0.01 270 / 0.20)', icon: null },
  pending: { label: 'Emitiendo', color: 'oklch(0.78 0.10 70)', borderColor: 'oklch(0.78 0.10 70 / 0.25)', icon: null },
}

function MetaItem({
  icon: Icon,
  label,
  value,
  mono = false,
}: {
  icon: typeof User2
  label: string
  value: string
  mono?: boolean
}) {
  return (
    <div className="flex flex-col gap-0.5 min-w-0">
      <div className="inline-flex items-center gap-1.5">
        <Icon size={10} strokeWidth={1.8} className="text-text-tertiary opacity-70" />
        <span className="text-[9px] uppercase tracking-[0.16em] text-text-tertiary font-semibold">
          {label}
        </span>
      </div>
      <span
        className={cn(
          'text-xs font-semibold text-text-primary truncate',
          mono && 'font-mono tracking-wide tactile-tabular-nums',
        )}
        style={mono ? { fontVariantNumeric: 'tabular-nums' } : undefined}
      >
        {value}
      </span>
    </div>
  )
}

function Meter({
  label,
  spent,
  limit,
  pct,
  accent,
}: {
  label: string
  spent: number
  limit: number
  pct: number
  accent: string
}) {
  const isAlarm = pct > 80
  // Use color-mix to derive a softer entry stop in the same hue family. The
  // bar therefore always speaks the focused card's chromatic language; the
  // alarm state adds an accent halo + brighter mix instead of swapping hue.
  const softStop = `color-mix(in oklch, ${accent} 55%, transparent)`
  return (
    <div className="flex flex-col gap-1.5">
      <div className="flex items-baseline justify-between gap-2">
        <span className="text-[10px] uppercase tracking-[0.14em] text-text-tertiary font-medium">
          {label}
        </span>
        <span
          className="text-[10px] text-text-secondary tactile-tabular-nums"
          style={{ fontVariantNumeric: 'tabular-nums' }}
        >
          {formatMinor(spent)} / {formatMinor(limit)}
        </span>
      </div>
      <div
        className="h-1 w-full rounded-full overflow-hidden"
        style={{ background: 'oklch(1 0 0 / 0.06)' }}
      >
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${pct}%` }}
          transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
          className="h-full rounded-full"
          style={{
            background: `linear-gradient(90deg, ${softStop} 0%, ${accent} 100%)`,
            boxShadow: isAlarm
              ? `0 0 8px ${accent}, 0 0 2px ${accent}`
              : 'none',
          }}
        />
      </div>
    </div>
  )
}

function ActionButton({
  icon: Icon,
  iconClassName,
  label,
  onClick,
  disabled = false,
  active = false,
  fullWidth = false,
}: {
  icon: typeof Eye
  iconClassName?: string
  label: string
  onClick?: () => void
  disabled?: boolean
  active?: boolean
  fullWidth?: boolean
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={cn(
        'inline-flex items-center gap-2 rounded-lg px-2.5 py-2',
        'text-xs font-medium transition-colors duration-180',
        fullWidth ? 'w-full justify-center' : '',
        disabled
          ? 'cursor-not-allowed opacity-40'
          : 'hover:bg-surface-card-elevated active:scale-[0.98]',
        active && !disabled && 'tactile-wght-breathing',
      )}
      style={{
        background: active ? 'oklch(1 0 0 / 0.08)' : 'oklch(1 0 0 / 0.03)',
        border: `1px solid ${active ? 'oklch(1 0 0 / 0.16)' : 'oklch(1 0 0 / 0.07)'}`,
        color: active ? 'oklch(0.96 0 0)' : 'oklch(0.78 0.012 270)',
      }}
      title={disabled && !onClick ? 'Disponible próximamente' : undefined}
    >
      <Icon size={12} strokeWidth={1.8} className={cn('shrink-0', iconClassName)} />
      <span className="truncate">{label}</span>
    </button>
  )
}

/* --------------------------------------------------------------------------
   Helpers
   -------------------------------------------------------------------------- */

function typeLabel(t: BankCardMock['card_type']): string {
  return t === 'debit' ? 'Débito' : t === 'virtual' ? 'Virtual' : 'Crédito'
}

function maskIbanShort(iban: string): string {
  const compact = iban.replace(/\s+/g, '')
  if (compact.length < 8) return iban
  return `${compact.slice(0, 4)} ··· ${compact.slice(-4)}`
}

function formatMinor(minor: number): string {
  return (minor / 100).toLocaleString('es-ES', {
    style: 'currency',
    currency: 'EUR',
    maximumFractionDigits: 0,
  })
}
