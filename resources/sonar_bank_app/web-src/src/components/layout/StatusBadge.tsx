import { useState } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import { ShieldCheck, ShieldAlert, ShieldOff, ShieldQuestion } from 'lucide-react'
import { Badge } from '@/components/ui'
import type { BadgeTone } from '@/components/ui/Badge'
import { useBankStatus, type BridgeStatus } from '@/stores/status'
import { useBankStateBag } from '@/lib/bankStateBags'

const STATUS_META: Record<
  BridgeStatus,
  {
    tone: BadgeTone
    icon: typeof ShieldCheck
    label: string
    tooltip: string
  }
> = {
  native_full: {
    tone: 'native_full',
    icon: ShieldCheck,
    label: 'Native Full',
    tooltip: 'Bridges al 100%. Framework nativo activo y operativo.',
  },
  lite_mode_active: {
    tone: 'lite_mode_active',
    icon: ShieldAlert,
    label: 'Lite Mode',
    tooltip: 'Bridges en modo Lite. Funcionalidad reducida sin pérdida de datos.',
  },
  compromised_load_order: {
    tone: 'compromised',
    icon: ShieldOff,
    label: 'Comprometido',
    tooltip: 'Orden de carga comprometido. Operativa restringida — contacta soporte.',
  },
  framework_missing: {
    tone: 'framework_missing',
    icon: ShieldQuestion,
    label: 'Sin framework',
    tooltip: 'Framework no detectado. Bank operará en modo standalone.',
  },
}

export function StatusBadge() {
  const storedStatus = useBankStatus((s) => s.bridgesStatus)
  const stateBagStatus = useBankStateBag<BridgeStatus>('bank.bridges.status')
  const status = stateBagStatus ?? storedStatus
  const meta = STATUS_META[status]
  const Icon = meta.icon
  const [hovering, setHovering] = useState(false)

  return (
    <div
      className="relative inline-flex"
      onMouseEnter={() => setHovering(true)}
      onMouseLeave={() => setHovering(false)}
    >
      <Badge tone={meta.tone} variant="soft" size="sm" pulse leftIcon={<Icon size={12} strokeWidth={2.4} />}>
        {meta.label}
      </Badge>

      <AnimatePresence>
        {hovering && (
          <motion.div
            initial={{ opacity: 0, y: -6, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -6, scale: 0.96 }}
            transition={{ duration: 0.18, ease: [0.16, 1, 0.3, 1] }}
            role="tooltip"
            className="absolute right-0 top-[calc(100%+8px)] z-[60] w-64 rounded-lg p-3 text-xs text-text-secondary"
            style={{
              background: 'oklch(0.18 0.014 270)',
              border: '1px solid var(--color-border-medium)',
              boxShadow: 'var(--shadow-tooltip)',
            }}
          >
            <div className="font-medium text-text-primary mb-1">{meta.label}</div>
            {meta.tooltip}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
