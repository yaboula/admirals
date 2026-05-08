import { useState } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import { ShieldCheck, ShieldAlert, ShieldOff, ShieldQuestion } from 'lucide-react'
import { Badge } from '@/components/ui'
import type { BadgeTone } from '@/components/ui/Badge'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { useBankStatus, type BridgeStatus } from '@/stores/status'
import { useBankStateBag } from '@/lib/bankStateBags'

const STATUS_META: Record<
  BridgeStatus,
  {
    tone: BadgeTone
    icon: typeof ShieldCheck
    labelKey: TranslationKey
    tooltipKey: TranslationKey
  }
> = {
  native_full: {
    tone: 'native_full',
    icon: ShieldCheck,
    labelKey: 'status.nativeFullLabel',
    tooltipKey: 'status.nativeFullTooltip',
  },
  lite_mode_active: {
    tone: 'lite_mode_active',
    icon: ShieldAlert,
    labelKey: 'status.liteModeLabel',
    tooltipKey: 'status.liteModeTooltip',
  },
  compromised_load_order: {
    tone: 'compromised',
    icon: ShieldOff,
    labelKey: 'status.compromisedLabel',
    tooltipKey: 'status.compromisedTooltip',
  },
  framework_missing: {
    tone: 'framework_missing',
    icon: ShieldQuestion,
    labelKey: 'status.frameworkMissingLabel',
    tooltipKey: 'status.frameworkMissingTooltip',
  },
}

export function StatusBadge() {
  const { t } = useI18n()
  const storedStatus = useBankStatus((s) => s.bridgesStatus)
  const stateBagStatus = useBankStateBag<BridgeStatus>('bank.bridges.status')
  const status = stateBagStatus ?? storedStatus
  const meta = STATUS_META[status]
  const Icon = meta.icon
  const label = t(meta.labelKey)
  const tooltip = t(meta.tooltipKey)
  const [hovering, setHovering] = useState(false)

  return (
    <div
      className="relative inline-flex"
      onMouseEnter={() => setHovering(true)}
      onMouseLeave={() => setHovering(false)}
    >
      <Badge tone={meta.tone} variant="soft" size="sm" pulse leftIcon={<Icon size={12} strokeWidth={2.4} />}>
        {label}
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
            <div className="font-medium text-text-primary mb-1">{label}</div>
            {tooltip}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
