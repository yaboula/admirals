import { useEffect } from 'react'
import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { CheckCircle2, AlertTriangle, AlertOctagon, Info, X } from 'lucide-react'
import { useToastQueue, type Toast as ToastT, type ToastTone } from '@/stores/toast'
import { Button } from '@/components/ui'
import { cn } from '@/lib/utils'
import { useI18n } from '@/lib/i18n'

const TONE_META: Record<
  ToastTone,
  { icon: typeof CheckCircle2; bg: string; ring: string; iconColor: string }
> = {
  success: {
    icon: CheckCircle2,
    bg: 'oklch(0.65 0.18 155 / 0.16)',
    ring: 'oklch(0.65 0.18 155 / 0.4)',
    iconColor: 'oklch(0.65 0.18 155)',
  },
  warning: {
    icon: AlertTriangle,
    bg: 'oklch(0.78 0.16 85 / 0.16)',
    ring: 'oklch(0.78 0.16 85 / 0.4)',
    iconColor: 'oklch(0.78 0.16 85)',
  },
  danger: {
    icon: AlertOctagon,
    bg: 'oklch(0.62 0.21 25 / 0.16)',
    ring: 'oklch(0.62 0.21 25 / 0.4)',
    iconColor: 'oklch(0.62 0.21 25)',
  },
  info: {
    icon: Info,
    bg: 'oklch(0.70 0.14 230 / 0.16)',
    ring: 'oklch(0.70 0.14 230 / 0.4)',
    iconColor: 'oklch(0.70 0.14 230)',
  },
}

export function ToastContainer() {
  const { t } = useI18n()
  const toasts = useToastQueue((s) => s.toasts)
  const dismiss = useToastQueue((s) => s.dismiss)
  const reduced = useReducedMotion()

  return (
    <div
      role="region"
      aria-label={t('common.notifications')}
      className="fixed top-20 right-6 z-[var(--z-toast)] flex flex-col gap-3 max-w-sm w-full pointer-events-none"
    >
      <AnimatePresence initial={false}>
        {toasts.map((t) => (
          <ToastItem key={t.id} toast={t} onDismiss={() => dismiss(t.id)} reduced={!!reduced} />
        ))}
      </AnimatePresence>
    </div>
  )
}

function ToastItem({
  toast,
  onDismiss,
  reduced,
}: {
  toast: ToastT
  onDismiss: () => void
  reduced: boolean
}) {
  const { t } = useI18n()
  const meta = TONE_META[toast.tone]
  const Icon = meta.icon

  useEffect(() => {
    if (!toast.duration) return
    const id = window.setTimeout(onDismiss, toast.duration)
    return () => window.clearTimeout(id)
  }, [toast.duration, onDismiss])

  return (
    <motion.div
      initial={reduced ? false : { opacity: 0, x: 32, scale: 0.96 }}
      animate={{ opacity: 1, x: 0, scale: 1 }}
      exit={reduced ? { opacity: 0 } : { opacity: 0, x: 32, scale: 0.96 }}
      transition={{ type: 'spring', stiffness: 380, damping: 28 }}
      className={cn(
        'tactile-glass-card pointer-events-auto rounded-xl px-4 py-3',
        'flex items-start gap-3',
      )}
      style={{
        background: meta.bg,
        boxShadow: `var(--shadow-toast), 0 0 0 1px ${meta.ring}`,
      }}
      role="status"
    >
      <div
        className="shrink-0 mt-0.5 inline-flex h-8 w-8 items-center justify-center rounded-lg"
        style={{ background: 'oklch(0 0 0 / 0.32)' }}
      >
        <Icon size={18} strokeWidth={2} style={{ color: meta.iconColor }} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="text-sm font-semibold text-text-primary tactile-wght-breathing">{toast.title}</div>
        {toast.description && (
          <div className="text-xs text-text-secondary mt-0.5 leading-relaxed">{toast.description}</div>
        )}
        {toast.action && (
          <div className="mt-2">
            <Button
              size="sm"
              variant="ghost"
              silent
              onClick={() => {
                toast.action?.onClick()
                onDismiss()
              }}
            >
              {toast.action.label}
            </Button>
          </div>
        )}
      </div>
      <button
        type="button"
        aria-label={t('common.close')}
        onClick={onDismiss}
        className="shrink-0 text-text-tertiary hover:text-text-primary transition-colors mt-0.5"
      >
        <X size={14} />
      </button>
    </motion.div>
  )
}
