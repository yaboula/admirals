import { ArrowLeftRight, SlidersHorizontal, Snowflake } from 'lucide-react'
import { sfx } from '@/lib/sfx'
import { useTransferWizard } from '@/stores/transferWizard'
import { toast } from '@/stores/toast'
import { cn } from '@/lib/utils'

export interface CardActionsRowProps {
  className?: string
  /** when card is frozen the snowflake action is highlighted */
  frozen?: boolean
  onToggleFreeze?: () => void
  onLimits?: () => void
}

/**
 * Compact card-action triplet rendered directly under the CreditCardVisual.
 * Ghost styling — no fills, no orange. Hover lifts the underlying surface only.
 *
 *   [ Transferir ] [ Límites ] [ Congelar ]
 */
export function CardActionsRow({
  className,
  frozen,
  onToggleFreeze,
  onLimits,
}: CardActionsRowProps) {
  const initWizard = useTransferWizard((s) => s.init)

  const handleTransfer = (): void => {
    initWizard(false)
    sfx.depth_press()
  }

  const handleLimits = (): void => {
    sfx.console_tap()
    if (onLimits) onLimits()
    else toast.info('Próximamente', 'La gestión de límites llegará en BANK-FE.4.')
  }

  const handleFreeze = (): void => {
    sfx.depth_press()
    if (onToggleFreeze) onToggleFreeze()
    else toast.info(
      frozen ? 'Tarjeta descongelada' : 'Tarjeta congelada',
      'La acción real se conectará al backend en BANK-FE.4.',
    )
  }

  return (
    <div
      className={cn(
        'grid grid-cols-3 gap-2',
        className,
      )}
    >
      <ActionButton
        icon={<ArrowLeftRight size={14} strokeWidth={1.9} />}
        label="Transferir"
        onClick={handleTransfer}
      />
      <ActionButton
        icon={<SlidersHorizontal size={14} strokeWidth={1.9} />}
        label="Límites"
        onClick={handleLimits}
      />
      <ActionButton
        icon={<Snowflake size={14} strokeWidth={1.9} />}
        label={frozen ? 'Descongelar' : 'Congelar'}
        onClick={handleFreeze}
        active={frozen}
      />
    </div>
  )
}

interface ActionButtonProps {
  icon: React.ReactNode
  label: string
  onClick: () => void
  active?: boolean
}

function ActionButton({ icon, label, onClick, active }: ActionButtonProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'tactile-button-ghost tactile-focus-ring',
        'inline-flex items-center justify-center gap-1.5 rounded-lg',
        'h-9 px-3 text-xs font-medium',
        'border border-border-subtle hover:border-border-medium',
        active && 'text-text-primary border-border-strong bg-surface-card-elevated',
      )}
    >
      <span className="shrink-0">{icon}</span>
      <span className="truncate">{label}</span>
    </button>
  )
}
