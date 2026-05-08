import { useNavigate } from 'react-router-dom'
import { motion, useReducedMotion } from 'motion/react'
import { ArrowDownToLine, ArrowLeftRight, ArrowUpFromLine, ChevronRight } from 'lucide-react'
import { sfx } from '@/lib/sfx'
import { useI18n } from '@/lib/i18n'
import { toast } from '@/stores/toast'
import { useTransferWizard } from '@/stores/transferWizard'
import { cn } from '@/lib/utils'

/**
 * BANK-FE.2.3 — NFS-inspired vertical action stack.
 *
 * Three full-width tactile buttons below the CreditCardVisual:
 *   1. Transferir (tier 1 · primary · orange aura tactile)
 *   2. Depositar (tier 2 · secondary · graphite glass with green accent)
 *   3. Retirar   (tier 3 · ghost · subtle border + hover orange whisper)
 *
 * Typography ladder: 14px semibold label + 10px uppercase helper subtitle.
 * Each row: [icon-pill 32×32] [label + helper] [→ chevron].
 *
 * Interactions:
 * - Transferir → open wizard (SFX depth_press).
 * - Depositar / Retirar → toast placeholder until ATM endpoints ship.
 */
export function ActionStack() {
  const { t } = useI18n()
  const reduced = useReducedMotion()
  const navigate = useNavigate()
  const initWizard = useTransferWizard((s) => s.init)

  const handleTransferir = (): void => {
    sfx.depth_press()
    initWizard(false)
    navigate('/transferir')
  }

  const handleDepositar = (): void => {
    sfx.console_tap()
    toast.info(t('home.depositToastTitle'), t('home.depositToastBody'))
  }

  const handleRetirar = (): void => {
    sfx.console_tap()
    toast.info(t('home.withdrawToastTitle'), t('home.withdrawToastBody'))
  }

  return (
    <motion.div
      initial={reduced ? false : { opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.38, ease: [0.16, 1, 0.3, 1], delay: 0.08 }}
      className="flex flex-col gap-1.5 2xl:gap-2"
    >
      <ActionRow
        tier="primary"
        icon={<ArrowLeftRight size={16} strokeWidth={2.1} />}
        title={t('home.transferTitle')}
        helper={t('home.transferHelper')}
        onClick={handleTransferir}
      />
      <ActionRow
        tier="secondary"
        icon={<ArrowDownToLine size={16} strokeWidth={2.1} />}
        title={t('home.depositTitle')}
        helper={t('home.depositActionHelper')}
        onClick={handleDepositar}
      />
      <ActionRow
        tier="ghost"
        icon={<ArrowUpFromLine size={16} strokeWidth={2.1} />}
        title={t('home.withdrawTitle')}
        helper={t('home.withdrawActionHelper')}
        onClick={handleRetirar}
      />
    </motion.div>
  )
}

interface ActionRowProps {
  tier: 'primary' | 'secondary' | 'ghost'
  icon: React.ReactNode
  title: string
  helper: string
  onClick: () => void
}

function ActionRow({ tier, icon, title, helper, onClick }: ActionRowProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'tactile-action-btn tactile-focus-ring',
        `tactile-action-btn--${tier}`,
      )}
    >
      <span className="tactile-action-icon" aria-hidden>
        {icon}
      </span>
      <span className="tactile-action-label">
        <span className="text-[14px] font-semibold tracking-tight tactile-wght-breathing">
          {title}
        </span>
        <span className="text-[10px] uppercase tracking-[0.12em] font-medium text-text-tertiary">
          {helper}
        </span>
      </span>
      <ChevronRight
        size={16}
        strokeWidth={2}
        className="tactile-action-chev text-text-tertiary"
        aria-hidden
      />
    </button>
  )
}
