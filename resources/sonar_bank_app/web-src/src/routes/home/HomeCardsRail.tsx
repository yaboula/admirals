import type { ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowDownLeft, ArrowUpRight, Plus } from 'lucide-react'
import type { Account, BankCardMock, Transaction } from '@/data/contracts'
import { Card } from '@/components/ui'
import { BankAvatar } from '@/components/brand/BankAvatar'
import { useI18n } from '@/lib/i18n'
import { getMockAliasForIban } from '@/data/mock/seed'
import { useTransferWizard } from '@/stores/transferWizard'
import { usePrivacyMode } from '@/stores/privacy'
import { sfx } from '@/lib/sfx'
import { maskSignedMoneyDisplay } from '@/lib/privacy'
import { CardVisual } from '../cards/CardVisual'

export interface HomeCardsRailProps {
  account: Account | undefined
  cards: BankCardMock[]
  transactions: Transaction[]
}

export function HomeCardsRail({ account, cards, transactions }: HomeCardsRailProps) {
  const { t } = useI18n()
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
            'linear-gradient(180deg, rgba(246,75,0,0.76), rgba(41,6,2,0.86) 34%, rgba(1,0,0,0.92))',
        }}
      />
      <div
        aria-hidden
        className="absolute inset-x-0 top-0 h-44 pointer-events-none"
        style={{ background: 'radial-gradient(circle at 78% 4%, rgba(255,255,255,0.26), transparent 46%)' }}
      />
      <div className="relative h-full min-h-0 flex flex-col p-5 2xl:p-6">
        <div className="flex items-center justify-between shrink-0">
          <h2 className="text-lg font-semibold text-white tracking-tight">{t('common.cards')}</h2>
          <button
            type="button"
            onClick={() => navigate('/tarjetas')}
            className="inline-flex h-9 items-center gap-1.5 rounded-full px-3 text-xs font-semibold text-white/86"
            style={{ background: 'rgba(255,255,255,0.13)', border: '1px solid rgba(255,255,255,0.14)' }}
          >
            <Plus size={13} strokeWidth={2} />
            {t('home.new')}
          </button>
        </div>

        {/* Cards stack — symmetric 3D depth ladder.
            All three cards share inset-x-0 + bottom-0 so they are perfectly
            centered horizontally. Back cards recede only via uniform scale,
            an upward translateY (so they peek above the front) and a small
            rotateX (perspective tilt). No off-axis Z rotation, no horizontal
            offset → the stack reads as one card seen from above in 3D. */}
        <div
          className="relative mt-4 h-[244px] shrink-0 overflow-visible"
          style={{ perspective: '1400px', perspectiveOrigin: '50% 25%' }}
        >
          {cards[2] && (
            <div
              className="absolute inset-x-0 bottom-0 z-0"
              style={{
                transform: 'translateY(-50px) scale(0.88) rotateX(10deg)',
                transformOrigin: 'center top',
                filter: 'drop-shadow(0 18px 26px rgba(0,0,0,0.55)) brightness(0.78)',
              }}
            >
              <CardVisual card={cards[2]} compact className="shadow-none" />
            </div>
          )}
          {cards[1] && (
            <div
              className="absolute inset-x-0 bottom-0 z-10"
              style={{
                transform: 'translateY(-26px) scale(0.94) rotateX(5deg)',
                transformOrigin: 'center top',
                filter: 'drop-shadow(0 14px 20px rgba(0,0,0,0.5)) brightness(0.9)',
              }}
            >
              <CardVisual card={cards[1]} compact className="shadow-none" />
            </div>
          )}
          {primaryCard && (
            <div className="absolute inset-x-0 bottom-0 z-20">
              <CardVisual card={primaryCard} compact />
            </div>
          )}
        </div>

        <div className="grid grid-cols-2 gap-3 mt-4 shrink-0">
          <RailAction label={t('home.railRequest')} icon={<ArrowDownLeft size={15} strokeWidth={2} />} onClick={openTransfer} muted />
          <RailAction label={t('nav.transfer')} icon={<ArrowUpRight size={15} strokeWidth={2} />} onClick={openTransfer} />
        </div>

        <div className="mt-4 flex items-center justify-between shrink-0">
          <h3 className="text-base font-semibold text-white tracking-tight">{t('home.recentActivity')}</h3>
          <button type="button" onClick={() => navigate('/transacciones')} className="text-xs font-medium text-white/72 hover:text-white">
            {t('home.viewAll')}
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
        background: muted ? 'rgba(255,255,255,0.18)' : 'var(--color-brand-signal-orange)',
        color: 'white',
        border: '1px solid rgba(255,255,255,0.12)',
        boxShadow: muted ? 'none' : '0 16px 28px -20px rgba(246,75,0,0.9)',
      }}
    >
      {icon}
      {label}
    </button>
  )
}

function RailTransaction({ tx, ownIban, index }: { tx: Transaction; ownIban: string | undefined; index: number }) {
  const { t, signedMoney, relativeTime } = useI18n()
  const own = compactIban(ownIban)
  const outgoing = own ? compactIban(tx.from_iban) === own : tx.direction === 'out'
  const counterpart = outgoing ? tx.to_iban : tx.from_iban
  const name = getMockAliasForIban(counterpart) ?? tx.reason ?? t('home.movements')
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const displayName = streamerMode ? t('transactions.hiddenMovement') : name

  return (
    <div
      className="flex items-center gap-3 rounded-2xl px-3 py-2.5"
      style={{
        background: 'rgba(0,0,0,0.34)',
        border: '1px solid rgba(255,255,255,0.06)',
      }}
    >
      <BankAvatar name={displayName} size="md" seed={index} />
      <div className="min-w-0 flex-1 flex flex-col leading-tight">
        <span className="text-sm font-semibold text-white truncate">{displayName}</span>
        <span className="text-[11px] text-white/46 truncate">{relativeTime(tx.timestamp_ms)}</span>
      </div>
      <span className="text-sm font-semibold tactile-tabular-nums" style={{ color: outgoing ? 'rgb(249, 119, 112)' : 'rgb(95, 211, 127)' }}>
        {streamerMode ? maskSignedMoneyDisplay() : signedMoney((outgoing ? -1 : 1) * tx.amount_minor / 100)}
      </span>
    </div>
  )
}

function compactIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '')
}
