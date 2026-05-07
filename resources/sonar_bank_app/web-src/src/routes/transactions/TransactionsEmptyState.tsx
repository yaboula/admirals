import { motion } from 'motion/react'
import { Inbox, SearchX, Filter } from 'lucide-react'
import { useTransactionsFilter } from '@/stores/transactionsFilter'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'

export type TransactionsEmptyVariant = 'no-data' | 'no-match'

export interface TransactionsEmptyStateProps {
  variant: TransactionsEmptyVariant
  totalCount: number
}

/**
 * BANK-FE.3 — Empty / no-match state.
 *
 * Two distinct UX paths:
 *   - no-data: backend returned zero rows — show explanatory copy + suggest
 *     making the first transfer from the dashboard.
 *   - no-match: filters narrow to nothing — surface the active filter count
 *     and offer a one-click reset that animates the chips back to defaults.
 */
export function TransactionsEmptyState({ variant, totalCount }: TransactionsEmptyStateProps) {
  const reset = useTransactionsFilter((s) => s.reset)

  const Icon = variant === 'no-data' ? Inbox : SearchX
  const title = variant === 'no-data' ? 'Sin movimientos aún' : 'Sin resultados'
  const description =
    variant === 'no-data'
      ? 'Aún no hay transacciones registradas en tu cuenta. Cuando realices o recibas un pago, aparecerá aquí en tiempo real.'
      : `Tus filtros han ocultado las ${totalCount} transacciones disponibles. Ajusta los criterios o restablece los filtros para ver todo.`

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.32, ease: [0.16, 1, 0.3, 1] }}
      className="h-full min-h-0 flex flex-col items-center justify-center text-center gap-4 px-8 py-10"
    >
      <span
        className="relative inline-flex items-center justify-center h-16 w-16 rounded-full"
        style={{
          background: 'oklch(1 0 0 / 0.025)',
          border: '1px solid oklch(1 0 0 / 0.06)',
          color: 'oklch(0.55 0.012 270 / 0.7)',
        }}
        aria-hidden
      >
        <Icon size={26} strokeWidth={1.7} />
        <span
          aria-hidden
          className="absolute inset-0 rounded-full pointer-events-none"
          style={{
            background:
              'radial-gradient(circle at 50% 40%, oklch(0.65 0.22 40 / 0.10), transparent 70%)',
          }}
        />
      </span>

      <div className="flex flex-col gap-1.5 max-w-[420px]">
        <span className="text-base font-semibold text-text-primary tracking-tight">
          {title}
        </span>
        <span className="text-xs text-text-tertiary leading-relaxed">{description}</span>
      </div>

      {variant === 'no-match' && (
        <button
          type="button"
          onClick={() => {
            reset()
            sfx.console_tap()
          }}
          className={cn(
            'mt-1 inline-flex items-center gap-2 px-4 py-2 rounded-md',
            'text-[12px] font-semibold text-text-primary',
            'tactile-action-btn--secondary tactile-focus-ring',
          )}
          style={{ width: 'auto' }}
        >
          <Filter size={13} strokeWidth={2.2} />
          Restablecer filtros
        </button>
      )}
    </motion.div>
  )
}
