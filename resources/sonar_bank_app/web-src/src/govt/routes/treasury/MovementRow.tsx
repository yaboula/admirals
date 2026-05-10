import {
  ArrowDownLeft, ArrowUpRight, BarChart2, Coins, HandCoins,
  RefreshCcw, Scale, TrendingUp, type LucideIcon,
} from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import type { GovtMovement, GovtMovementStatus, GovtMovementType } from '../../data/contracts'

interface Props {
  movement: GovtMovement
  index: number
}

const TYPE_ICON: Record<GovtMovementType, LucideIcon> = {
  tax_collection:       Coins,
  transfer_in:          ArrowDownLeft,
  transfer_out:         ArrowUpRight,
  payroll_disbursement: HandCoins,
  fine_collected:       Scale,
  subsidy_issued:       TrendingUp,
  reconciliation:       RefreshCcw,
  interest_accrued:     BarChart2,
}

const TYPE_COLOR: Record<GovtMovementType, string> = {
  tax_collection:       'rgb(34, 195, 115)',
  transfer_in:          'rgb(34, 195, 115)',
  transfer_out:         'rgb(67, 202, 231)',
  payroll_disbursement: 'rgb(230, 173, 0)',
  fine_collected:       'rgb(255, 125, 90)',
  subsidy_issued:       'rgb(230, 173, 0)',
  reconciliation:       'var(--color-govt-accent-light)',
  interest_accrued:     'rgb(34, 195, 115)',
}

const TYPE_LABEL: Record<GovtMovementType, TranslationKey> = {
  tax_collection:       'govt.treasury.type.tax_collection',
  transfer_in:          'govt.treasury.type.transfer_in',
  transfer_out:         'govt.treasury.type.transfer_out',
  payroll_disbursement: 'govt.treasury.type.payroll_disbursement',
  fine_collected:       'govt.treasury.type.fine_collected',
  subsidy_issued:       'govt.treasury.type.subsidy_issued',
  reconciliation:       'govt.treasury.type.reconciliation',
  interest_accrued:     'govt.treasury.type.interest_accrued',
}

const STATUS_LABEL: Record<GovtMovementStatus, TranslationKey> = {
  settled:  'govt.treasury.status.settled',
  pending:  'govt.treasury.status.pending',
  reversed: 'govt.treasury.status.reversed',
}

const STATUS_DOT: Record<GovtMovementStatus, string> = {
  settled:  'bg-[rgb(0, 173, 91)]',
  pending:  'bg-[rgb(230, 173, 0)]',
  reversed: 'bg-[rgb(255, 106, 67)]',
}

export function MovementRow({ movement, index }: Props) {
  const { t, money, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const Icon = TYPE_ICON[movement.type]
  const iconColor = TYPE_COLOR[movement.type]
  const isInflow = movement.direction === 'inflow'
  const amountDisplay = streamerMode ? maskMoneyDisplay() : money(movement.amount)

  return (
    <tr
      className={cn(
        'group transition-colors',
        index % 2 === 0 ? 'bg-transparent' : 'bg-white/[0.015]',
        'hover:bg-[var(--color-govt-accent-soft)]',
      )}
    >
      <td className="py-2.5 pl-4 pr-2">
        <div className="flex items-center gap-2.5">
          <span
            aria-hidden
            className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-xl"
            style={{ background: 'rgba(0,1,3,0.8)', color: iconColor }}
          >
            <Icon size={13} strokeWidth={2} />
          </span>
          <div className="min-w-0">
            <p className="truncate text-[12px] font-medium text-[var(--color-govt-text-primary)]">{t(TYPE_LABEL[movement.type])}</p>
            <p className="truncate font-mono text-[10px] uppercase tracking-[0.12em] text-[var(--color-govt-text-quaternary)]">{movement.referenceCode}</p>
          </div>
        </div>
      </td>
      <td className="px-2 py-2.5">
        <div className="min-w-0">
          <p className="truncate text-[12px] text-[var(--color-govt-text-secondary)]">{movement.entityLabel}</p>
          <p className="truncate font-mono text-[10px] uppercase tracking-[0.12em] text-[var(--color-govt-text-quaternary)]">{movement.entityId}</p>
        </div>
      </td>
      <td className="px-2 py-2.5 text-[11px] text-[var(--color-govt-text-tertiary)]">
        {dateTime(movement.timestamp, { dateStyle: 'short', timeStyle: 'short' })}
      </td>
      <td className="px-2 py-2.5">
        <span className="flex items-center gap-1.5 text-[10px] uppercase tracking-[0.12em] text-[var(--color-govt-text-tertiary)]">
          <span className={cn('h-1.5 w-1.5 flex-shrink-0 rounded-full', STATUS_DOT[movement.status])} aria-hidden />
          {t(STATUS_LABEL[movement.status])}
        </span>
      </td>
      <td className="py-2.5 pl-2 pr-4 text-right">
        <span
          className={cn('text-[13px] font-semibold tabular-nums', isInflow ? 'text-[rgb(51, 204, 125)]' : 'text-[var(--color-govt-text-secondary)]')}
        >
          {isInflow ? '+' : '−'}{amountDisplay}
        </span>
      </td>
    </tr>
  )
}
