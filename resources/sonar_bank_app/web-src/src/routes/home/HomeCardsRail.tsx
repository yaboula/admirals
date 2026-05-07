import type { ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowDownLeft, ArrowUpRight, Plus } from 'lucide-react'
import type { Account, BankCardMock, Transaction } from '@/data/contracts'
import { Card } from '@/components/ui'
import { BankAvatar } from '@/components/brand/BankAvatar'
import { formatCurrency, formatRelativeTime } from '@/lib/utils'
import { getMockAliasForIban } from '@/data/mock/seed'
import { useTransferWizard } from '@/stores/transferWizard'
import { sfx } from '@/lib/sfx'

export interface HomeCardsRailProps {
  account: Account | undefined
  cards: BankCardMock[]
  transactions: Transaction[]
}

export function HomeCardsRail({ account, cards, transactions }: HomeCardsRailProps) {
  const navigate = useNavigate()
  const initWizard = useTransferWizard((s) => s.init)
  const activeCards = cards.filter((card) => card.status === 'active')
  const primaryCard = activeCards[0] ?? cards[0]

  const openTransfer = () => {
    initWizard(false)
    sfx.depth_press()
    navigate('/transferir')
  }

  return (
    <Card variant="glass" padding="none" className="relative h-full min-h-0 overflow-hidden rounded-[1.75rem] border-white/10">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'linear-gradient(180deg, oklch(0.70 0.22 40 / 0.76), oklch(0.19 0.06 34 / 0.86) 34%, oklch(0.055 0.012 35 / 0.92))',
        }}
      />
      <div
        aria-hidden
        className="absolute inset-x-0 top-0 h-44 pointer-events-none"
        style={{ background: 'radial-gradient(circle at 78% 4%, oklch(1 0 0 / 0.26), transparent 46%)' }}
      />
      <div className="relative h-full min-h-0 flex flex-col p-5 2xl:p-6">
        <div className="flex items-center justify-between shrink-0">
          <h2 className="text-lg font-semibold text-white tracking-tight">My cards</h2>
          <button
            type="button"
            onClick={() => navigate('/tarjetas')}
            className="inline-flex h-9 items-center gap-1.5 rounded-full px-3 text-xs font-semibold text-white/86"
            style={{ background: 'oklch(1 0 0 / 0.13)', border: '1px solid oklch(1 0 0 / 0.14)' }}
          >
            <Plus size={13} strokeWidth={2} />
            Add new
          </button>
        </div>

        <div className="relative mt-4 h-[205px] shrink-0">
          <div className="absolute left-[14%] right-[4%] top-0 h-[78px] rounded-[1.35rem]" style={{ background: 'oklch(0.32 0.09 38 / 0.72)', border: '1px solid oklch(1 0 0 / 0.10)' }} />
          <div className="absolute left-[8%] right-[2%] top-8 h-[88px] rounded-[1.45rem]" style={{ background: 'oklch(0.24 0.065 35 / 0.86)', border: '1px solid oklch(1 0 0 / 0.11)' }} />
          <div
            className="absolute inset-x-0 bottom-0 h-[154px] rounded-[1.55rem] p-5 flex flex-col justify-between"
            style={{
              background: 'linear-gradient(135deg, oklch(0.16 0.018 35), oklch(0.08 0.012 270))',
              border: '1px solid oklch(1 0 0 / 0.13)',
              boxShadow: '0 26px 46px -26px oklch(0 0 0 / 0.95), inset 0 1px 0 oklch(1 0 0 / 0.08)',
            }}
          >
            <div className="flex items-start justify-between">
              <span className="text-xl font-bold tracking-tight text-white">VISA</span>
              <span className="h-9 w-11 rounded-lg" style={{ background: 'linear-gradient(135deg, oklch(0.86 0.03 85), oklch(0.62 0.02 85))', border: '1px solid oklch(1 0 0 / 0.22)' }} />
            </div>
            <div className="flex items-end justify-between gap-3">
              <div className="flex flex-col gap-1">
                <span className="text-xs text-white/64">Balance</span>
                <span className="text-2xl font-light tracking-[-0.035em] text-white tactile-tabular-nums">
                  {formatCurrency(account ? account.balance_minor / 100 : 0)}
                </span>
              </div>
              <span className="rounded-lg px-2 py-1 text-xs font-semibold text-emerald-300" style={{ background: 'oklch(0.48 0.16 150 / 0.18)' }}>
                ↑ 3.52%
              </span>
            </div>
          </div>
          {primaryCard && (
            <span className="absolute right-6 top-[14px] text-xs text-white/42 tactile-tabular-nums">
              ···· {primaryCard.pan_last_four}
            </span>
          )}
        </div>

        <div className="grid grid-cols-2 gap-3 mt-4 shrink-0">
          <RailAction label="Request" icon={<ArrowDownLeft size={15} strokeWidth={2} />} onClick={openTransfer} muted />
          <RailAction label="Transfer" icon={<ArrowUpRight size={15} strokeWidth={2} />} onClick={openTransfer} />
        </div>

        <div className="mt-4 flex items-center justify-between shrink-0">
          <h3 className="text-base font-semibold text-white tracking-tight">Recent Transactions</h3>
          <button type="button" onClick={() => navigate('/transacciones')} className="text-xs font-medium text-white/72 hover:text-white">
            View All
          </button>
        </div>

        <div className="mt-3 flex-1 min-h-0 space-y-2 overflow-hidden">
          {transactions.slice(0, 3).map((tx, index) => (
            <RailTransaction key={tx.txn_id} tx={tx} ownIban={account?.iban} index={index} />
          ))}
        </div>
      </div>
    </Card>
  )
}

function RailAction({ label, icon, onClick, muted }: { label: string; icon: ReactNode; onClick: () => void; muted?: boolean }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl text-sm font-semibold transition-transform hover:-translate-y-0.5 active:scale-[0.98]"
      style={{
        background: muted ? 'oklch(1 0 0 / 0.18)' : 'oklch(0.70 0.22 40)',
        color: 'white',
        border: '1px solid oklch(1 0 0 / 0.12)',
        boxShadow: muted ? 'none' : '0 16px 28px -20px oklch(0.70 0.22 40 / 0.9)',
      }}
    >
      {icon}
      {label}
    </button>
  )
}

function RailTransaction({ tx, ownIban, index }: { tx: Transaction; ownIban: string | undefined; index: number }) {
  const own = ownIban?.replace(/\s+/g, '')
  const outgoing = own ? tx.from_iban.replace(/\s+/g, '') === own : tx.direction === 'out'
  const counterpart = outgoing ? tx.to_iban : tx.from_iban
  const name = getMockAliasForIban(counterpart) ?? tx.reason ?? 'Movimiento'
  const amount = tx.amount_minor / 100

  return (
    <div
      className="flex items-center gap-3 rounded-2xl px-3 py-2.5"
      style={{
        background: 'oklch(0.02 0.006 35 / 0.34)',
        border: '1px solid oklch(1 0 0 / 0.06)',
      }}
    >
      <BankAvatar name={name} size="md" seed={index} />
      <div className="min-w-0 flex-1 flex flex-col leading-tight">
        <span className="text-sm font-semibold text-white truncate">{name}</span>
        <span className="text-[11px] text-white/46 truncate">{formatRelativeTime(tx.timestamp_ms)}</span>
      </div>
      <span className="text-sm font-semibold tactile-tabular-nums" style={{ color: outgoing ? 'oklch(0.72 0.16 25)' : 'oklch(0.78 0.16 150)' }}>
        {outgoing ? '-' : '+'}{formatCurrency(amount)}
      </span>
    </div>
  )
}
