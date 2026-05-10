import { motion } from 'motion/react'
import {
  BookOpen, CheckCircle, Clock, Pause, Sprout,
  type LucideIcon,
} from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import type { GovtSubsidyProgram, GovtSubsidyStatus, GovtSubsidyType } from '../../data/contracts'

interface Props {
  program: GovtSubsidyProgram
  active: boolean
  onSelect: (id: string) => void
}

const STATUS_TONE: Record<GovtSubsidyStatus, { dot: string; text: string; key: TranslationKey }> = {
  active:    { dot: 'bg-[rgb(0, 173, 91)]', text: 'text-[rgb(78, 213, 137)]', key: 'govt.subsidies.status.active' },
  paused:    { dot: 'bg-[rgb(230, 173, 0)]',  text: 'text-[rgb(248, 198, 85)]',  key: 'govt.subsidies.status.paused' },
  completed: { dot: 'bg-[var(--color-govt-text-tertiary)]', text: 'text-[var(--color-govt-text-tertiary)]', key: 'govt.subsidies.status.completed' },
  proposed:  { dot: 'bg-[rgb(67, 202, 231)]', text: 'text-[rgb(112, 213, 237)]', key: 'govt.subsidies.status.proposed' },
}

const STATUS_ICON: Record<GovtSubsidyStatus, LucideIcon> = {
  active:    CheckCircle,
  paused:    Pause,
  completed: BookOpen,
  proposed:  Clock,
}

const TYPE_COLOR: Record<GovtSubsidyType, string> = {
  food:         'rgb(0, 196, 112)',
  housing:      'rgb(0, 187, 223)',
  employment:   'rgb(230, 173, 0)',
  medical:      'rgb(255, 115, 145)',
  education:    'rgb(118, 161, 255)',
  emergency:    'rgb(255, 106, 67)',
  agricultural: 'rgb(112, 188, 57)',
}

const TYPE_KEY: Record<GovtSubsidyType, TranslationKey> = {
  food:         'govt.subsidies.type.food',
  housing:      'govt.subsidies.type.housing',
  employment:   'govt.subsidies.type.employment',
  medical:      'govt.subsidies.type.medical',
  education:    'govt.subsidies.type.education',
  emergency:    'govt.subsidies.type.emergency',
  agricultural: 'govt.subsidies.type.agricultural',
}

export function SubsidyRow({ program, active, onSelect }: Props) {
  const { t, money, number } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const tone = STATUS_TONE[program.status]
  const StatusIcon = STATUS_ICON[program.status]
  const typeColor = TYPE_COLOR[program.type]
  const pct = program.budget > 0 ? Math.min(100, Math.round((program.disbursed / program.budget) * 100)) : 0
  const disbursedDisplay = streamerMode ? maskMoneyDisplay() : money(program.disbursed)

  return (
    <motion.button
      type="button"
      onClick={() => { sfx.console_tap(); onSelect(program.programId) }}
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.18 }}
      aria-pressed={active}
      className={cn(
        'group flex w-full items-center gap-3 rounded-2xl border p-3 text-left transition-all',
        active
          ? 'border-[var(--color-govt-border-active)] bg-[var(--color-govt-accent-soft)]'
          : 'border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] hover:border-[var(--color-govt-border-strong)] hover:bg-white/[0.04]',
      )}
    >
      <span
        aria-hidden
        className={cn(
          'flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-2xl border',
          active ? 'border-[var(--color-govt-border-active)]' : 'border-[var(--color-govt-border)]',
        )}
        style={{ background: 'rgba(0,1,1,0.65)', color: typeColor }}
      >
        <Sprout size={15} strokeWidth={1.9} />
      </span>

      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between gap-2">
          <p className="truncate text-sm font-semibold text-[var(--color-govt-text-primary)]">{program.name}</p>
          <span className={cn('inline-flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-[0.14em]', tone.text)}>
            <StatusIcon size={11} strokeWidth={2} />
            {t(tone.key)}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <p className="truncate font-mono text-[10px] uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{program.code}</p>
          <span className="text-[var(--color-govt-text-quaternary)]">·</span>
          <p className="text-[10px] uppercase tracking-[0.10em]" style={{ color: typeColor }}>{t(TYPE_KEY[program.type])}</p>
        </div>

        <div className="mt-1.5 flex items-center justify-between gap-3">
          <span className="text-[11px] tabular-nums text-[var(--color-govt-text-secondary)]">{disbursedDisplay}</span>
          <span className="text-[10px] uppercase tracking-[0.10em] text-[var(--color-govt-text-tertiary)]">
            {`${number(program.beneficiaryCount)} ${t('govt.subsidies.row.beneficiaries')} · ${pct}%`}
          </span>
        </div>

        <div className="mt-1.5 h-[3px] w-full overflow-hidden rounded-full bg-white/[0.04]" aria-label={`${pct}% utilized`}>
          <span className="block h-full rounded-full transition-[width] duration-500" style={{ width: `${pct}%`, background: typeColor }} />
        </div>
      </div>
    </motion.button>
  )
}
