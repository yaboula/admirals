import type { ReactNode } from 'react'
import { ArrowDownToLine, ArrowUpFromLine } from 'lucide-react'
import { Card } from '@/components/ui'
import { sfx } from '@/lib/sfx'
import { useI18n } from '@/lib/i18n'
import { toast } from '@/stores/toast'

export function HomeMoneyActions() {
  const { t } = useI18n()
  return (
    <Card variant="glass" padding="md" className="h-full min-h-0 rounded-[1.55rem] border-white/10 flex flex-col gap-3 justify-center">
      <MoneyAction
        title={t('home.depositTitle')}
        helper={t('home.depositHelper')}
        icon={<ArrowDownToLine size={18} strokeWidth={2.1} />}
        tone="in"
        onClick={() => {
          sfx.console_tap()
          toast.info(t('home.depositToastTitle'), t('home.depositToastBody'))
        }}
      />
      <MoneyAction
        title={t('home.withdrawTitle')}
        helper={t('home.withdrawHelper')}
        icon={<ArrowUpFromLine size={18} strokeWidth={2.1} />}
        tone="out"
        onClick={() => {
          sfx.console_tap()
          toast.info(t('home.withdrawToastTitle'), t('home.withdrawToastBody'))
        }}
      />
    </Card>
  )
}

function MoneyAction({
  title,
  helper,
  icon,
  tone,
  onClick,
}: {
  title: string
  helper: string
  icon: ReactNode
  tone: 'in' | 'out'
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="group flex flex-1 items-center gap-3 rounded-2xl px-3 text-left transition-transform hover:-translate-y-0.5 active:scale-[0.99]"
      style={{
        background: tone === 'in' ? 'oklch(1 0 0 / 0.065)' : 'oklch(1 0 0 / 0.035)',
        border: '1px solid oklch(1 0 0 / 0.08)',
      }}
    >
      <span
        className="inline-flex h-10 w-10 items-center justify-center rounded-2xl shrink-0"
        style={{
          background: tone === 'in' ? 'oklch(0.74 0.15 150 / 0.18)' : 'oklch(0.72 0.22 40 / 0.16)',
          color: tone === 'in' ? 'oklch(0.80 0.16 150)' : 'oklch(0.78 0.20 40)',
          border: '1px solid oklch(1 0 0 / 0.09)',
        }}
      >
        {icon}
      </span>
      <span className="min-w-0 flex flex-col leading-tight">
        <span className="text-sm font-semibold text-text-primary">{title}</span>
        <span className="text-[11px] text-text-tertiary truncate">{helper}</span>
      </span>
    </button>
  )
}
