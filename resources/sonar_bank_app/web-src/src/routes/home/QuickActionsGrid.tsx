import { motion } from 'motion/react'
import { Send, Download, CreditCard, PiggyBank, type LucideIcon } from 'lucide-react'
import { sfx } from '@/lib/sfx'
import { MagneticHover } from '@/components/vanguard/MagneticHover'
import { cn } from '@/lib/utils'

interface QuickAction {
  id: string
  label: string
  hint: string
  icon: LucideIcon
  tone: 'brand' | 'success' | 'info' | 'warning'
  onClick?: () => void
  disabled?: boolean
}

const ACTIONS: QuickAction[] = [
  { id: 'send',     label: 'Transferir', hint: 'Envío express ≤€5k',    icon: Send,       tone: 'brand'   },
  { id: 'receive',  label: 'Recibir',    hint: 'Compartir IBAN/QR',     icon: Download,   tone: 'info'    },
  { id: 'cards',    label: 'Tarjetas',   hint: 'Bloqueo + PIN + límites', icon: CreditCard, tone: 'success' },
  { id: 'savings',  label: 'Ahorrar',    hint: 'Mover a cuenta ahorro', icon: PiggyBank,  tone: 'warning' },
]

const TONE_GRADIENT: Record<QuickAction['tone'], string> = {
  brand: 'linear-gradient(135deg, oklch(0.65 0.22 40 / 0.20), oklch(0.78 0.18 55 / 0.10))',
  success: 'linear-gradient(135deg, oklch(0.65 0.18 155 / 0.18), oklch(0.65 0.18 155 / 0.04))',
  info: 'linear-gradient(135deg, oklch(0.70 0.14 230 / 0.18), oklch(0.70 0.14 230 / 0.04))',
  warning: 'linear-gradient(135deg, oklch(0.78 0.16 85 / 0.18), oklch(0.78 0.16 85 / 0.04))',
}

const TONE_ICON_COLOR: Record<QuickAction['tone'], string> = {
  brand: 'oklch(0.78 0.18 55)',
  success: 'oklch(0.65 0.18 155)',
  info: 'oklch(0.70 0.14 230)',
  warning: 'oklch(0.78 0.16 85)',
}

export interface QuickActionsGridProps {
  onSend?: () => void
}

export function QuickActionsGrid({ onSend }: QuickActionsGridProps) {
  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
      {ACTIONS.map((a, i) => {
        const Icon = a.icon
        const handleClick = a.id === 'send' ? onSend : undefined
        return (
          <motion.div
            key={a.id}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 + i * 0.05, duration: 0.42, ease: [0.16, 1, 0.3, 1] }}
          >
            <MagneticHover strength={0.18}>
              <button
                type="button"
                onClick={() => {
                  if (a.disabled) return
                  sfx.depth_press()
                  handleClick?.()
                }}
                disabled={a.disabled}
                className={cn(
                  'tactile-focus-ring group relative w-full overflow-hidden',
                  'flex flex-col items-start gap-3 px-4 py-5 rounded-2xl text-left',
                  'border border-border-medium hover:border-border-strong transition-colors',
                  'tactile-card-interactive',
                )}
                style={{
                  background: 'var(--color-surface-card)',
                  boxShadow: 'var(--shadow-tactile-card)',
                }}
              >
                <div
                  aria-hidden
                  className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                  style={{ background: TONE_GRADIENT[a.tone] }}
                />
                <div
                  className="relative inline-flex h-10 w-10 items-center justify-center rounded-xl"
                  style={{
                    background: 'oklch(0 0 0 / 0.32)',
                    boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.06), inset 0 -1px 0 oklch(0 0 0 / 0.4)',
                    color: TONE_ICON_COLOR[a.tone],
                  }}
                >
                  <Icon size={20} strokeWidth={2} />
                </div>
                <div className="relative flex flex-col">
                  <span className="text-sm font-semibold tracking-tight tactile-wght-breathing">
                    {a.label}
                  </span>
                  <span className="text-xs text-text-tertiary mt-0.5">{a.hint}</span>
                </div>
              </button>
            </MagneticHover>
          </motion.div>
        )
      })}
    </div>
  )
}
