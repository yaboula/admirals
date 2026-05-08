import { useMemo, useState, type ReactNode } from 'react'
import { motion } from 'motion/react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowDownLeft,
  ArrowRight,
  ArrowUpRight,
  Banknote,
  CheckCircle2,
  ChevronRight,
  Delete,
  KeyRound,
  LogOut,
  ReceiptText,
  WalletCards,
  type LucideIcon,
} from 'lucide-react'
import { Spinner } from '@/components/ui'
import { BankAvatar } from '@/components/brand/BankAvatar'
import type { BankCard, BankCardMock, Transaction } from '@/data/contracts'
import { useAtmSessionQuery, useBootstrap } from '@/data/queries'
import { getMockDisplayName } from '@/data/mock/seed'
import { useI18n } from '@/lib/i18n'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { usePrivacyMode } from '@/stores/privacy'
import { CardVisual } from './cards/CardVisual'
import type { CardDesign } from './cards/cardDesigns'

type OperationId = 'withdraw' | 'deposit' | 'transfer'
type AtmStep = 'pin' | 'card' | 'cash'

const QUICK_AMOUNTS = [50, 100, 200, 500]
const PIN_KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'clear', '0', 'delete']

const ATM_CARD_DESIGN: CardDesign = {
  id: 'atm_cash_mode',
  name: 'ATM Cash Mode',
  tagline: 'Terminal authenticated',
  tier: 'signature',
  surface: 'linear-gradient(135deg, oklch(0.105 0.010 250) 0%, oklch(0.075 0.008 250) 58%, oklch(0.065 0.010 250) 100%)',
  accent: 'oklch(0.65 0.22 40)',
  textPrimary: 'oklch(0.98 0.004 250)',
  textTertiary: 'oklch(0.66 0.012 250 / 0.78)',
  motif: 'pinstripe',
}

export function Atm() {
  const { t, money } = useI18n()
  const navigate = useNavigate()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const sessionQuery = useAtmSessionQuery()
  const bootstrapQuery = useBootstrap()
  const session = sessionQuery.data
  const bootstrap = bootstrapQuery.data
  const cards = bootstrap?.cards ?? []
  const account = bootstrap?.accounts[0]
  const primaryCard = cards[0]
  const transactions = useMemo(() => bootstrap?.recent_transactions.slice(0, 3) ?? [], [bootstrap?.recent_transactions])
  const [step, setStep] = useState<AtmStep>('pin')
  const [pin, setPin] = useState('')
  const [selectedCardId, setSelectedCardId] = useState<string | null>(null)
  const selectedCard = cards.find((card) => card.card_id === (selectedCardIdFallback(selectedCardId, primaryCard))) ?? primaryCard
  const [operation, setOperation] = useState<OperationId>('withdraw')
  const [amount, setAmount] = useState('')

  const cashBalance = account?.balance_minor ?? session?.account.balance_minor ?? 0
  const totalBalance = cashBalance + (account?.savings_minor ?? session?.account.savings_minor ?? 0)
  const dailyLimit = session?.daily_limit_minor ?? cashBalance
  const remainingLimit = session?.remaining_limit_minor ?? cashBalance
  const terminalCash = session?.cash_available_minor ?? cashBalance
  const availableNow = Math.max(0, Math.min(cashBalance, remainingLimit, terminalCash))
  const limitRatio = dailyLimit > 0 ? Math.max(0, Math.min(1, remainingLimit / dailyLimit)) : 0
  const amountMinor = Math.round((Number.parseFloat(amount) || 0) * 100)
  const amountReady = amountMinor > 0 && amountMinor <= availableNow
  const displayName = streamerMode ? t('atm.clientFallback') : getMockDisplayName()
  const terminalId = session?.terminal_id ?? t('atm.terminalFallback')
  const online = session?.online ?? true

  if (sessionQuery.isLoading || bootstrapQuery.isLoading) {
    return (
      <main className="grid h-[100dvh] w-screen place-items-center overflow-hidden bg-surface-abyss text-text-primary">
        <div className="flex flex-col items-center gap-3 rounded-[2rem] border border-white/10 bg-white/[0.04] px-10 py-8 shadow-glass backdrop-blur-2xl">
          <Spinner size="md" />
          <span className="text-xs font-black uppercase tracking-[0.18em] text-text-tertiary">{t('atm.loading')}</span>
        </div>
      </main>
    )
  }

  return (
    <AtmSurface>
      <motion.section
        key={step}
        initial={{ opacity: 0, scale: 0.985, y: 14 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.34, ease: [0.22, 1, 0.36, 1] }}
        className="relative mx-auto h-full max-w-[1216px] p-4"
      >
        {step === 'pin' && (
          <PinGate
            name={displayName}
            location={session?.location_label}
            pin={pin}
            onPinChange={setPin}
            onExit={() => navigate('/')}
            onNext={() => {
              setSelectedCardId(cards.find((card) => card.status === 'active')?.card_id ?? primaryCard?.card_id ?? null)
              setStep('card')
            }}
          />
        )}

        {step === 'card' && (
          <CardChooser
            name={displayName}
            location={session?.location_label}
            cards={cards}
            selectedCardId={selectedCard?.card_id ?? null}
            onSelect={setSelectedCardId}
            onBack={() => setStep('pin')}
            onExit={() => navigate('/')}
            onNext={() => setStep('cash')}
          />
        )}

        {step === 'cash' && (
          <CashScreen
            name={displayName}
            location={session?.location_label}
            selectedCard={selectedCard}
            terminalId={terminalId}
            online={online}
            totalBalance={streamerMode ? maskMoneyDisplay() : money(totalBalance / 100)}
            cashBalance={streamerMode ? maskMoneyDisplay() : money(cashBalance / 100)}
            availableNow={streamerMode ? maskMoneyDisplay() : money(availableNow / 100)}
            limitLeft={streamerMode ? maskMoneyDisplay() : money(remainingLimit / 100)}
            limitRatio={limitRatio}
            transactions={transactions}
            operation={operation}
            amount={amount}
            amountReady={amountReady}
            onOperationChange={setOperation}
            onAmountChange={setAmount}
            onBack={() => setStep('card')}
            onExit={() => navigate('/')}
          />
        )}
      </motion.section>
    </AtmSurface>
  )
}

function selectedCardIdFallback(selectedCardId: string | null, primaryCard?: BankCardMock) {
  return selectedCardId ?? primaryCard?.card_id
}

function AtmSurface({ children }: { children: ReactNode }) {
  return (
    <main className="relative h-[100dvh] w-screen overflow-hidden bg-[#050202] text-text-primary">
      <div aria-hidden className="absolute inset-0 bg-[#05070a]" />
      <div aria-hidden className="absolute inset-0 bg-[radial-gradient(circle_at_82%_18%,oklch(0.65_0.22_40_/_0.22),transparent_30%),radial-gradient(circle_at_16%_78%,oklch(0.65_0.22_40_/_0.12),transparent_34%),linear-gradient(135deg,#080202_0%,#05070a_48%,#020203_100%)]" />
      <div aria-hidden className="absolute inset-0 opacity-[0.08] [background-image:linear-gradient(90deg,rgba(255,255,255,0.04)_1px,transparent_1px),linear-gradient(180deg,rgba(255,255,255,0.03)_1px,transparent_1px)] [background-size:72px_72px]" />
      <div aria-hidden className="absolute inset-x-10 top-0 h-px bg-gradient-to-r from-transparent via-[oklch(0.65_0.22_40_/_0.34)] to-transparent" />
      <div aria-hidden className="absolute inset-x-0 top-0 h-px bg-white/10" />
      {children}
    </main>
  )
}

function PinGate({
  name,
  location,
  pin,
  onPinChange,
  onExit,
  onNext,
}: {
  name: string
  location?: string
  pin: string
  onPinChange: (pin: string) => void
  onExit: () => void
  onNext: () => void
}) {
  const { t } = useI18n()
  const ready = pin.length === 4
  const handleKey = (key: string) => {
    if (key === 'clear') onPinChange('')
    else if (key === 'delete') onPinChange(pin.slice(0, -1))
    else if (pin.length < 4) onPinChange(`${pin}${key}`)
  }

  return (
    <div className="grid h-full grid-cols-[minmax(0,1fr)_390px] gap-4 rounded-[2rem] border border-white/10 bg-[radial-gradient(circle_at_88%_14%,oklch(0.65_0.22_40_/_0.16),transparent_30%),linear-gradient(135deg,rgba(8,2,2,0.92)_0%,rgba(5,7,10,0.88)_52%,rgba(2,2,3,0.96)_100%)] p-4 shadow-[0_34px_100px_rgba(0,0,0,0.62),inset_0_1px_0_rgba(255,255,255,0.06)] backdrop-blur-2xl">
      <section className="relative overflow-hidden rounded-[1.65rem] border border-white/10 bg-[linear-gradient(135deg,oklch(0.65_0.22_40_/_0.09)_0%,rgba(255,255,255,0.035)_36%,rgba(0,0,0,0.30)_100%)] p-8">
        <div className="relative grid h-full grid-rows-[auto_minmax(0,1fr)_auto]">
          <div>
            <TerminalKicker location={location} />
            <p className="mt-8 text-lg font-semibold tracking-[-0.04em] text-text-secondary">{t('atm.pinGreeting')}</p>
            <h1 className="mt-1 max-w-[620px] text-[4.2rem] font-black leading-[0.88] tracking-[-0.08em] text-text-primary">{name}</h1>
            <p className="mt-5 max-w-[520px] text-base font-medium leading-6 text-text-secondary">{t('atm.pinIntro')}</p>
          </div>

          <div className="grid place-items-center">
            <div className="relative h-[220px] w-[440px] max-w-full">
              <div className="absolute left-1/2 top-1/2 h-[170px] w-[360px] -translate-x-1/2 -translate-y-1/2 rounded-full border border-white/10 bg-black/18" />
              <div className="absolute left-1/2 top-1/2 h-[112px] w-[286px] -translate-x-1/2 -translate-y-1/2 rounded-full border border-[oklch(0.65_0.22_40_/_0.18)] bg-[oklch(0.65_0.22_40_/_0.05)]" />
              <div className="absolute left-1/2 top-1/2 grid h-[78px] w-[78px] -translate-x-1/2 -translate-y-1/2 place-items-center rounded-full border border-white/12 bg-[#080a0d] shadow-[0_18px_50px_rgba(0,0,0,0.45)]">
                <KeyRound size={26} className="text-[oklch(0.65_0.22_40)]" strokeWidth={2.2} />
              </div>
              <div className="absolute left-[42px] top-[34px] h-3 w-3 rounded-full border border-[oklch(0.65_0.22_40_/_0.36)] bg-[oklch(0.65_0.22_40_/_0.22)]" />
              <div className="absolute bottom-[42px] right-[64px] h-2 w-2 rounded-full bg-white/22" />
              <div className="absolute right-[38px] top-[52px] h-10 w-10 rounded-full border border-white/10" />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3 rounded-[1.35rem] border border-white/10 bg-black/16 p-3">
            <StageBadge index="01" label={t('atm.pinStep')} active />
            <StageBadge index="02" label={t('atm.cardStep')} />
            <StageBadge index="03" label={t('atm.cashStep')} />
          </div>
        </div>
      </section>

      <aside className="grid min-h-0 grid-rows-[auto_1fr_auto] rounded-[1.65rem] border border-white/10 bg-white/[0.035] p-5 shadow-glass backdrop-blur-2xl">
        <div className="flex items-center justify-between gap-3">
          <div className="grid h-12 w-12 place-items-center rounded-2xl border border-white/10 bg-white/[0.045] text-[oklch(0.65_0.22_40)]">
            <KeyRound size={22} strokeWidth={2.2} />
          </div>
          <button type="button" onClick={onExit} className="flex h-10 items-center gap-2 rounded-full border border-white/10 bg-white/[0.04] px-4 text-xs font-black uppercase tracking-[0.13em] text-text-secondary transition hover:bg-white/[0.075] hover:text-text-primary">
            <LogOut size={14} />
            {t('atm.exit')}
          </button>
        </div>

        <div className="flex flex-col justify-center">
          <p className="text-[11px] font-black uppercase tracking-[0.18em] text-text-tertiary">{t('atm.enterPin')}</p>
          <div className="mt-5 flex justify-center gap-3">
            {Array.from({ length: 4 }, (_, index) => (
              <span key={index} className={cn('h-4 w-4 rounded-full border transition', index < pin.length ? 'border-[oklch(0.65_0.22_40)] bg-[oklch(0.65_0.22_40)] shadow-[0_0_18px_oklch(0.65_0.22_40_/_0.26)]' : 'border-white/16 bg-white/[0.035]')} />
            ))}
          </div>

          <div className="mt-8 grid grid-cols-3 gap-3">
            {PIN_KEYS.map((key) => (
              <button key={key} type="button" onClick={() => handleKey(key)} className="grid h-14 place-items-center rounded-2xl border border-white/10 bg-black/18 text-lg font-black text-text-primary transition hover:bg-white/[0.07]">
                {key === 'delete' ? <Delete size={18} /> : key === 'clear' ? <span className="text-xs uppercase tracking-[0.12em]">{t('atm.clearPin')}</span> : key}
              </button>
            ))}
          </div>
        </div>

        <button type="button" disabled={!ready} onClick={onNext} className={cn('flex h-12 items-center justify-center gap-2 rounded-full text-sm font-black transition', ready ? 'bg-[var(--gradient-primary)] text-text-primary shadow-[0_16px_38px_oklch(0.65_0.22_40_/_0.26)] hover:bg-[var(--gradient-primary-hover)]' : 'border border-white/10 bg-white/[0.035] text-text-tertiary')}>
          {t('atm.confirmPin')}
          <ChevronRight size={16} />
        </button>
      </aside>
    </div>
  )
}

function CardChooser({
  name,
  location,
  cards,
  selectedCardId,
  onSelect,
  onBack,
  onExit,
  onNext,
}: {
  name: string
  location?: string
  cards: BankCardMock[]
  selectedCardId: string | null
  onSelect: (cardId: string) => void
  onBack: () => void
  onExit: () => void
  onNext: () => void
}) {
  const { t, money } = useI18n()
  const selectedCard = cards.find((card) => card.card_id === selectedCardId) ?? cards[0]
  const canContinue = selectedCard?.status === 'active'
  const focusedIndex = Math.max(0, cards.findIndex((card) => card.card_id === selectedCard?.card_id))
  const stepCard = (delta: number) => {
    const target = cards[focusedIndex + delta]
    if (target) onSelect(target.card_id)
  }

  return (
    <div className="grid h-full grid-rows-[auto_minmax(0,1fr)] gap-4 rounded-[2rem] border border-white/10 bg-[#080a0d]/88 p-4 shadow-[0_34px_100px_rgba(0,0,0,0.58),inset_0_1px_0_rgba(255,255,255,0.06)] backdrop-blur-2xl">
      <FlowHeader name={name} location={location} stepLabel={t('atm.cardStep')} onBack={onBack} onExit={onExit} />

      <section className="grid min-h-0 grid-cols-[minmax(0,1fr)_350px] gap-4">
        <div className="relative min-h-0 overflow-hidden rounded-[1.55rem] border border-white/10 bg-white/[0.035] p-6">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-[10px] font-black uppercase tracking-[0.18em] text-text-tertiary">{t('atm.pocketCards')}</p>
              <h2 className="mt-1 text-[2.4rem] font-black leading-none tracking-[-0.07em] text-text-primary">{t('atm.chooseCard')}</h2>
            </div>
            <div className="rounded-full border border-white/10 bg-black/18 px-3 py-1.5 text-xs font-black text-text-secondary">
              {focusedIndex + 1}/{Math.max(cards.length, 1)}
            </div>
          </div>

          <div className="relative mx-auto mt-10 h-[360px] max-w-[660px]" style={{ perspective: '1800px' }}>
            {cards.map((card, index) => {
              const offset = index - focusedIndex
              const hidden = Math.abs(offset) > 2
              if (hidden) return null
              const distance = Math.abs(offset)
              const selected = offset === 0
              const sign = Math.sign(offset)
              return (
                <motion.div
                  key={card.card_id}
                  className="absolute inset-x-0 top-0 mx-auto w-[520px] max-w-[78%]"
                  animate={{
                    x: `${sign * (distance === 1 ? 42 : 72)}%`,
                    y: distance === 0 ? 20 : distance === 1 ? 42 : 58,
                    rotateY: -sign * (distance === 1 ? 18 : 30),
                    rotateZ: -sign * (distance === 1 ? 5 : 8),
                    scale: distance === 0 ? 1 : distance === 1 ? 0.86 : 0.74,
                    opacity: distance === 0 ? 1 : distance === 1 ? 0.54 : 0.22,
                    filter: `blur(${distance === 0 ? 0 : distance === 1 ? 2 : 6}px)`,
                  }}
                  transition={{ type: 'spring', stiffness: 220, damping: 26, mass: 1.05 }}
                  style={{ zIndex: 20 - distance, transformStyle: 'preserve-3d' }}
                >
                  <CardVisual card={card} design={ATM_CARD_DESIGN} className="rounded-[1.55rem]" />
                  {!selected && <button type="button" className="absolute inset-0" onClick={() => onSelect(card.card_id)} aria-label={t('atm.selectCard')} />}
                </motion.div>
              )
            })}
          </div>

          <div className="absolute inset-x-6 bottom-5 flex items-center justify-center gap-3">
            <button type="button" disabled={focusedIndex === 0} onClick={() => stepCard(-1)} className="h-10 rounded-full border border-white/10 bg-white/[0.04] px-5 text-xs font-black uppercase tracking-[0.13em] text-text-secondary transition hover:bg-white/[0.075] disabled:opacity-30">
              {t('atm.previousCard')}
            </button>
            <div className="flex items-center gap-1.5">
              {cards.map((card, index) => (
                <button
                  key={card.card_id}
                  type="button"
                  onClick={() => onSelect(card.card_id)}
                  className={cn('h-1.5 rounded-full transition-all', index === focusedIndex ? 'w-6 bg-white/72' : 'w-1.5 bg-white/20')}
                  aria-label={t('atm.selectCard')}
                />
              ))}
            </div>
            <button type="button" disabled={focusedIndex >= cards.length - 1} onClick={() => stepCard(1)} className="h-10 rounded-full border border-white/10 bg-white/[0.04] px-5 text-xs font-black uppercase tracking-[0.13em] text-text-secondary transition hover:bg-white/[0.075] disabled:opacity-30">
              {t('atm.nextCard')}
            </button>
          </div>
        </div>

        <aside className="grid min-h-0 grid-rows-[auto_auto_1fr_auto] gap-3 rounded-[1.55rem] border border-white/10 bg-white/[0.035] p-5 shadow-glass backdrop-blur-2xl">
          <div className="flex items-center gap-3">
            <div className="grid h-11 w-11 place-items-center rounded-2xl border border-white/10 bg-black/18 text-[oklch(0.65_0.22_40)]">
              <WalletCards size={21} />
            </div>
            <div>
              <p className="text-[11px] font-black uppercase tracking-[0.16em] text-text-tertiary">{t('atm.selectedCard')}</p>
              <h2 className="text-2xl font-black tracking-[-0.055em] text-text-primary">•••• {selectedCard?.pan_last_four ?? '----'}</h2>
            </div>
          </div>

          <p className="text-sm font-medium leading-5 text-text-secondary">{t('atm.chooseCardHint')}</p>

          {selectedCard && (
            <div className="grid content-start gap-3 rounded-[1.35rem] border border-white/10 bg-black/18 p-4">
              <MiniLine label={t('atm.dailyLimit')} value={money(selectedCard.daily_limit_minor / 100)} />
              <MiniLine label={t('atm.availableToday')} value={money(Math.max(0, selectedCard.daily_limit_minor - selectedCard.daily_spent_minor) / 100)} />
              <MiniLine label={t('atm.cardHolder')} value={selectedCard.holder_name} />
              <MiniLine label={t('atm.cardStatus')} value={selectedCard.status === 'active' ? t('atm.cardReady') : t('atm.cardLimited')} />
            </div>
          )}

          <button type="button" disabled={!canContinue} onClick={onNext} className={cn('flex h-12 items-center justify-center gap-2 rounded-full text-sm font-black transition', canContinue ? 'bg-[var(--gradient-primary)] text-text-primary shadow-[0_16px_38px_oklch(0.65_0.22_40_/_0.26)] hover:bg-[var(--gradient-primary-hover)]' : 'border border-white/10 bg-white/[0.035] text-text-tertiary')}>
            {t('atm.useThisCard')}
            <ChevronRight size={16} />
          </button>
        </aside>
      </section>
    </div>
  )
}

function CashScreen({
  name,
  location,
  selectedCard,
  terminalId,
  online,
  totalBalance,
  cashBalance,
  availableNow,
  limitLeft,
  limitRatio,
  transactions,
  operation,
  amount,
  amountReady,
  onOperationChange,
  onAmountChange,
  onBack,
  onExit,
}: {
  name: string
  location?: string
  selectedCard?: BankCard | BankCardMock
  terminalId: string
  online: boolean
  totalBalance: string
  cashBalance: string
  availableNow: string
  limitLeft: string
  limitRatio: number
  transactions: Transaction[]
  operation: OperationId
  amount: string
  amountReady: boolean
  onOperationChange: (operation: OperationId) => void
  onAmountChange: (amount: string) => void
  onBack: () => void
  onExit: () => void
}) {
  return (
    <div className="grid h-full grid-cols-[minmax(0,1fr)_336px] gap-4 rounded-[2rem] border border-white/10 bg-[radial-gradient(circle_at_88%_14%,oklch(0.65_0.22_40_/_0.18),transparent_30%),linear-gradient(135deg,rgba(8,2,2,0.92)_0%,rgba(5,7,10,0.88)_52%,rgba(2,2,3,0.96)_100%)] p-4 shadow-[0_34px_100px_rgba(0,0,0,0.62),inset_0_1px_0_rgba(255,255,255,0.06)] backdrop-blur-2xl">
      <section className="grid min-h-0 grid-rows-[76px_minmax(0,1fr)_132px] gap-3">
        <FlowHeader name={name} location={location} stepLabel="ATM" onBack={onBack} onExit={onExit} />
        <CashGateway card={selectedCard} availableNow={availableNow} totalBalance={totalBalance} cashBalance={cashBalance} limitLeft={limitLeft} limitRatio={limitRatio} terminalId={terminalId} online={online} />
        <RecentPanel clientName={name} transactions={transactions} />
      </section>

      <aside className="grid min-h-0 grid-rows-[224px_minmax(0,1fr)] gap-3">
        <OperationDock active={operation} onChange={onOperationChange} />
        <AmountComposer operation={operation} amount={amount} onAmountChange={onAmountChange} amountReady={amountReady} />
      </aside>
    </div>
  )
}

function FlowHeader({ name, location, stepLabel, onBack, onExit }: { name: string; location?: string; stepLabel: string; onBack: () => void; onExit: () => void }) {
  const { t } = useI18n()
  return (
    <header className="flex min-h-0 items-start justify-between gap-4">
      <div className="flex min-w-0 items-start gap-3">
        <BankAvatar name={name} size="lg" className="mt-1 ring-2 ring-[oklch(0.65_0.22_40_/_0.20)] shadow-[0_0_32px_oklch(0.65_0.22_40_/_0.18)]" />
        <div className="min-w-0">
          <TerminalKicker location={location} />
          <div className="mt-2 flex items-end gap-3">
            <h1 className="truncate text-[2.8rem] font-black leading-[0.9] tracking-[-0.075em] text-text-primary">{name}</h1>
            <span className="mb-1 rounded-full border border-white/10 bg-white/[0.045] px-3 py-1 text-[11px] font-black uppercase tracking-[0.14em] text-text-tertiary">{stepLabel}</span>
          </div>
        </div>
      </div>
      <div className="flex shrink-0 items-center gap-2">
        <button type="button" onClick={onBack} className="flex h-10 items-center gap-2 rounded-full border border-white/10 bg-white/[0.04] px-4 text-xs font-black uppercase tracking-[0.13em] text-text-secondary transition hover:bg-white/[0.075] hover:text-text-primary">
          {t('atm.back')}
        </button>
        <button type="button" onClick={onExit} className="flex h-10 items-center gap-2 rounded-full border border-white/10 bg-white/[0.04] px-4 text-xs font-black uppercase tracking-[0.13em] text-text-secondary transition hover:bg-white/[0.075] hover:text-text-primary">
          <LogOut size={14} />
          {t('atm.exit')}
        </button>
      </div>
    </header>
  )
}

function TerminalKicker({ location }: { location?: string }) {
  const { t } = useI18n()
  return (
    <div className="flex min-w-0 items-center gap-2 text-[10px] font-black uppercase tracking-[0.18em] text-text-tertiary">
      <span>{t('atm.brandKicker')}</span>
      <span className="h-1 w-1 rounded-full bg-[oklch(0.65_0.22_40)]" />
      <span className="truncate">{location ?? t('atm.locationFallback')}</span>
    </div>
  )
}

function StageBadge({ index, label, active = false }: { index: string; label: string; active?: boolean }) {
  return (
    <div className={cn('rounded-[1.2rem] border p-3', active ? 'border-[oklch(0.65_0.22_40_/_0.20)] bg-[oklch(0.65_0.22_40_/_0.07)]' : 'border-white/10 bg-white/[0.035]')}>
      <p className="text-[10px] font-black uppercase tracking-[0.16em] text-text-tertiary">{index}</p>
      <p className="mt-1 text-sm font-black text-text-primary">{label}</p>
    </div>
  )
}

function CashGateway({
  card,
  availableNow,
  totalBalance,
  cashBalance,
  limitLeft,
  limitRatio,
  terminalId,
  online,
}: {
  card?: BankCard | BankCardMock
  availableNow: string
  totalBalance: string
  cashBalance: string
  limitLeft: string
  limitRatio: number
  terminalId: string
  online: boolean
}) {
  const { t } = useI18n()
  return (
    <section className="relative grid min-h-0 grid-cols-[minmax(0,1fr)_196px] gap-4 overflow-hidden rounded-[1.65rem] border border-white/10 bg-[linear-gradient(135deg,oklch(0.65_0.22_40_/_0.105)_0%,rgba(255,255,255,0.035)_34%,rgba(0,0,0,0.30)_100%)] p-5 shadow-[inset_0_1px_0_rgba(255,255,255,0.08)]">
      <div aria-hidden className="absolute -right-24 -top-28 h-72 w-72 rounded-full bg-[oklch(0.65_0.22_40_/_0.14)] blur-3xl" />
      <div aria-hidden className="absolute bottom-0 left-8 h-px w-2/3 bg-gradient-to-r from-[oklch(0.65_0.22_40_/_0)] via-[oklch(0.65_0.22_40_/_0.22)] to-[oklch(0.65_0.22_40_/_0)]" />
      <div className="relative grid min-h-0 grid-rows-[auto_minmax(0,1fr)] gap-4">
        <div className="grid grid-cols-[minmax(0,1fr)_170px] gap-4">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-black/18 px-3 py-1.5 text-[10px] font-black uppercase tracking-[0.14em] text-text-primary">
              <span className="relative flex h-2.5 w-2.5">
                <motion.span className="absolute inline-flex h-full w-full rounded-full bg-[oklch(0.65_0.22_40_/_0.45)]" animate={{ scale: [1, 1.9, 1], opacity: [0.45, 0, 0.45] }} transition={{ duration: 1.8, repeat: Infinity, ease: 'easeOut' }} />
                <span className="relative inline-flex h-2.5 w-2.5 rounded-full bg-[oklch(0.65_0.22_40)]" />
              </span>
              {online ? t('atm.terminalOnline') : t('atm.terminalOffline')}
            </div>
            <p className="mt-4 text-[11px] font-black uppercase tracking-[0.18em] text-text-tertiary">{t('atm.availableNow')}</p>
            <p className="mt-1 text-[3.4rem] font-black leading-none tracking-[-0.085em] text-text-primary">{availableNow}</p>
            <p className="mt-1 max-w-[440px] text-xs font-medium leading-5 text-text-secondary">{t('atm.availableHintShort')}</p>
          </div>

          <div className="rounded-[1.25rem] border border-white/10 bg-black/18 p-3">
            <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.16em] text-text-tertiary">
              <CheckCircle2 size={12} className="text-[oklch(0.65_0.22_40)]" />
              {terminalId}
            </div>
            <div className="mt-4 grid gap-3">
              <MiniLine label={t('atm.totalBalance')} value={totalBalance} />
              <MiniLine label={t('atm.cashBalance')} value={cashBalance} />
              <MiniLine label={t('atm.terminalStock')} value={online ? t('atm.online') : t('atm.pending')} />
            </div>
          </div>
        </div>

        <div className="grid min-h-0 items-end px-4 pb-3">
          <div className="mx-auto w-full max-w-[500px]" style={{ perspective: '1400px' }}>
            {card ? (
              <motion.div className="group relative rounded-[1.45rem]" animate={{ rotateX: 6, rotateY: -7, y: 0 }} whileHover={{ y: -5, rotateX: 4, rotateY: -5, scale: 1.01 }} transition={{ type: 'spring', stiffness: 160, damping: 18 }} style={{ transformStyle: 'preserve-3d' }}>
                <CardVisual card={card} design={ATM_CARD_DESIGN} className="rounded-[1.45rem] shadow-[0_38px_80px_rgba(0,0,0,0.62)]" />
                <div aria-hidden className="pointer-events-none absolute inset-0 rounded-[1.45rem] border border-transparent transition duration-300 group-hover:border-[oklch(0.65_0.22_40_/_0.28)] group-hover:shadow-[0_0_34px_oklch(0.65_0.22_40_/_0.12)]" />
              </motion.div>
            ) : (
              <FallbackAtmCard />
            )}
          </div>
        </div>
      </div>

      <LimitPillar value={limitLeft} ratio={limitRatio} />
    </section>
  )
}

function LimitPillar({ value, ratio }: { value: string; ratio: number }) {
  const { t } = useI18n()
  const cells = Array.from({ length: 10 }, (_, index) => index < Math.round(ratio * 10))
  return (
    <div className="relative grid min-h-0 grid-rows-[auto_auto_minmax(0,1fr)_auto] rounded-[1.35rem] border border-white/10 bg-black/22 p-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] backdrop-blur-xl">
      <div className="flex items-start justify-between gap-2">
        <div>
          <p className="text-[10px] font-black uppercase tracking-[0.15em] text-text-tertiary">{t('atm.dailyCapacity')}</p>
          <p className="mt-1 text-xl font-black tracking-[-0.05em] text-text-primary">{value}</p>
        </div>
        <Banknote size={16} className="text-[oklch(0.65_0.22_40)]" />
      </div>
      <p className="mt-3 text-[11px] font-semibold leading-4 text-text-secondary">{t('atm.limitHintShort')}</p>
      <div className="mt-4 grid content-end gap-2">
        {cells.map((active, index) => (
          <div key={index} className={cn('h-4 rounded-full border transition', active ? 'border-[oklch(0.65_0.22_40_/_0.18)] bg-[oklch(0.65_0.22_40_/_0.18)]' : 'border-white/10 bg-white/[0.035]')} />
        ))}
      </div>
      <div className="mt-4 flex items-center justify-between rounded-full border border-white/10 bg-white/[0.035] px-3 py-2">
        <span className="text-[10px] font-black uppercase tracking-[0.14em] text-text-tertiary">{t('atm.capacity')}</span>
        <span className="text-xs font-black text-text-primary">{Math.round(ratio * 100)}%</span>
      </div>
    </div>
  )
}

function OperationDock({ active, onChange }: { active: OperationId; onChange: (operation: OperationId) => void }) {
  const { t } = useI18n()
  const operations: Array<{ id: OperationId; label: string; hint: string; rail: string; icon: LucideIcon }> = [
    { id: 'withdraw', label: t('atm.withdraw'), hint: t('atm.withdrawHintShort'), rail: t('atm.cashOutRail'), icon: ArrowUpRight },
    { id: 'deposit', label: t('atm.deposit'), hint: t('atm.depositHintShort'), rail: t('atm.cashInRail'), icon: ArrowDownLeft },
    { id: 'transfer', label: t('atm.transfer'), hint: t('atm.transferHintShort'), rail: t('atm.moveRail'), icon: ArrowRight },
  ]
  return (
    <section className="rounded-[1.45rem] border border-white/10 bg-[linear-gradient(135deg,oklch(0.65_0.22_40_/_0.12)_0%,rgba(255,255,255,0.04)_40%,rgba(0,0,0,0.32)_100%)] p-4 shadow-glass backdrop-blur-2xl">
      <div className="flex items-center gap-2">
        <ReceiptText size={18} strokeWidth={2.2} className="text-text-secondary" />
        <h2 className="text-xl font-black tracking-[-0.055em] text-text-primary">{t('atm.chooseOperation')}</h2>
      </div>
      <div className="mt-3 grid gap-2">
        {operations.map((operation) => {
          const Icon = operation.icon
          const selected = active === operation.id
          return (
            <button key={operation.id} type="button" onClick={() => onChange(operation.id)} className={cn('group grid h-[48px] grid-cols-[1fr_auto] items-center gap-3 rounded-[1rem] border px-3 text-left transition', selected ? 'border-white/24 bg-white/[0.08] shadow-[inset_0_1px_0_rgba(255,255,255,0.08)]' : 'border-white/10 bg-black/10 hover:bg-white/[0.045]')}>
              <span className="min-w-0">
                <span className="block truncate text-sm font-black text-text-primary">{operation.label}</span>
                <span className="mt-0.5 block truncate text-[11px] font-medium text-text-tertiary">{operation.hint}</span>
              </span>
              <span className="flex items-center gap-2">
                <span className={cn('hidden rounded-full border px-2 py-1 text-[9px] font-black uppercase tracking-[0.12em] xl:inline', selected ? 'border-white/16 bg-white/[0.08] text-text-primary' : 'border-white/10 bg-white/[0.035] text-text-tertiary')}>
                  {operation.rail}
                </span>
                <span className={cn('grid h-8 w-8 place-items-center rounded-full border transition', selected ? 'border-[oklch(0.65_0.22_40_/_0.24)] bg-[oklch(0.65_0.22_40_/_0.10)] text-[oklch(0.65_0.22_40)]' : 'border-white/10 bg-white/[0.035] text-text-secondary group-hover:text-text-primary')}>
                  <Icon size={15} strokeWidth={2.3} />
                </span>
              </span>
            </button>
          )
        })}
      </div>
    </section>
  )
}

function AmountComposer({
  operation,
  amount,
  onAmountChange,
  amountReady,
}: {
  operation: OperationId
  amount: string
  onAmountChange: (value: string) => void
  amountReady: boolean
}) {
  const { t, money } = useI18n()
  const title = operation === 'withdraw' ? t('atm.withdrawAmount') : operation === 'deposit' ? t('atm.depositAmount') : t('atm.transferAmount')
  return (
    <section className="relative min-h-0 overflow-hidden rounded-[1.45rem] border border-white/10 bg-[linear-gradient(135deg,oklch(0.65_0.22_40_/_0.09)_0%,rgba(255,255,255,0.035)_42%,rgba(0,0,0,0.34)_100%)] p-4 shadow-glass backdrop-blur-2xl">
      <div aria-hidden className="absolute -right-20 bottom-0 h-40 w-40 rounded-full bg-[oklch(0.65_0.22_40_/_0.12)] blur-3xl" />
      <div className="relative grid h-full grid-rows-[auto_auto_auto_auto_1fr_auto]">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-[10px] font-black uppercase tracking-[0.18em] text-text-tertiary">{t('atm.amount')}</p>
            <h2 className="mt-0.5 text-2xl font-black tracking-[-0.055em] text-text-primary">{title}</h2>
          </div>
          <ReceiptText size={17} className="text-text-secondary" />
        </div>
        <p className="mt-2 text-xs font-medium leading-5 text-text-secondary">{t('atm.amountHintShort')}</p>

        <div className="mt-3 grid grid-cols-4 gap-2">
          {QUICK_AMOUNTS.map((quickAmount) => (
            <button key={quickAmount} type="button" onClick={() => onAmountChange(String(quickAmount))} className={cn('relative h-9 overflow-hidden rounded-full border text-[11px] font-black transition hover:scale-[1.03]', amount === String(quickAmount) ? 'border-[oklch(0.65_0.22_40_/_0.28)] bg-[oklch(0.65_0.22_40_/_0.10)] text-text-primary' : 'border-white/10 bg-black/12 text-text-secondary hover:bg-white/[0.045] hover:text-text-primary')}>
              {amount === String(quickAmount) && <motion.span layoutId="atm-quick-amount-fill" className="absolute inset-y-0 left-0 w-full rounded-full bg-[oklch(0.65_0.22_40_/_0.055)]" transition={{ type: 'spring', stiffness: 280, damping: 26 }} />}
              <span className="relative">{money(quickAmount)}</span>
            </button>
          ))}
        </div>

        <label className="mt-3 block">
          <span className="text-xs font-bold text-text-secondary">{t('atm.enterAmount')}</span>
          <div className="mt-2 flex h-11 items-center gap-3 rounded-[1rem] border border-white/10 bg-black/20 px-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.05)]">
            <Banknote size={16} className="text-text-tertiary" />
            <input value={amount} onChange={(event) => onAmountChange(event.target.value.replace(/[^0-9.]/g, '').slice(0, 8))} inputMode="decimal" placeholder={t('atm.amountPlaceholder')} className="min-w-0 flex-1 bg-transparent text-base font-black text-text-primary outline-none placeholder:text-text-tertiary" />
          </div>
        </label>

        <div className="mt-3 rounded-[1rem] border border-white/10 bg-black/14 p-3">
          <p className="text-[10px] font-black uppercase tracking-[0.16em] text-text-tertiary">{t('atm.sessionNote')}</p>
          <p className="mt-2 text-xs font-semibold leading-5 text-text-secondary">{amountReady ? t('atm.readyNote') : t('atm.waitingNote')}</p>
        </div>

        <button type="button" disabled={!amountReady} className={cn('mt-3 flex h-11 w-full items-center justify-center gap-2 self-end rounded-full text-sm font-black transition', amountReady ? 'bg-[var(--gradient-primary)] text-text-primary shadow-[0_16px_38px_oklch(0.65_0.22_40_/_0.26)] hover:bg-[var(--gradient-primary-hover)]' : 'border border-white/10 bg-white/[0.035] text-text-tertiary')}>
          {t('atm.reviewCash')}
          <ChevronRight size={16} />
        </button>
      </div>
    </section>
  )
}

function RecentPanel({ clientName, transactions }: { clientName: string; transactions: Transaction[] }) {
  const { t, money, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  return (
    <section className="min-h-0 overflow-hidden rounded-[1.45rem] border border-white/10 bg-[linear-gradient(135deg,oklch(0.65_0.22_40_/_0.10)_0%,rgba(255,255,255,0.04)_34%,rgba(0,0,0,0.22)_100%)] p-3 shadow-glass backdrop-blur-2xl">
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <div className="flex -space-x-2">
            <BankAvatar name={clientName} size="sm" className="ring-2 ring-[#100704]" />
            <BankAvatar name={transactions[0]?.reason ?? clientName} seed={1} size="sm" className="ring-2 ring-[#100704]" />
          </div>
          <h2 className="text-xl font-black tracking-[-0.055em] text-text-primary">{t('atm.lastActivity')}</h2>
        </div>
        <span className="text-[11px] font-bold text-text-tertiary">{t('atm.lastActivityHintShort')}</span>
      </div>
      <div className="mt-2 grid grid-cols-3 gap-2">
        {transactions.map((transaction, index) => {
          const incoming = transaction.direction === 'in'
          const outgoing = transaction.direction === 'out'
          const Icon = incoming ? ArrowDownLeft : outgoing ? ArrowUpRight : ArrowRight
          const label = streamerMode ? t('transactions.hiddenMovement') : transaction.reason ?? (incoming ? t('atm.deposit') : t('atm.transfer'))
          const amount = streamerMode ? maskMoneyDisplay() : money(transaction.amount_minor / 100)
          const avatarName = streamerMode ? clientName : label
          return (
            <div key={transaction.txn_id} className="grid h-[62px] grid-cols-[34px_minmax(0,1fr)] grid-rows-[1fr_auto] gap-x-2 rounded-[1rem] border border-white/[0.065] bg-black/18 px-3 py-2 transition hover:border-[oklch(0.65_0.22_40_/_0.18)] hover:bg-black/28">
              <span className="relative row-span-2 self-center">
                <BankAvatar name={avatarName} seed={transaction.txn_id.length + index} size="sm" className="h-8 w-8 ring-1 ring-white/10" />
                <span className={cn('absolute -bottom-1 -right-1 grid h-4 w-4 place-items-center rounded-full border border-black bg-[#120805]', incoming ? 'text-[oklch(0.65_0.22_40)]' : 'text-text-secondary')}>
                  <Icon size={10} strokeWidth={2.6} />
                </span>
              </span>
              <p className="truncate text-xs font-black text-text-primary">{label}</p>
              <div className="flex min-w-0 items-center justify-between gap-2">
                <p className="truncate text-[10px] font-semibold text-text-tertiary">{dateTime(transaction.timestamp_ms, { dateStyle: 'short' })}</p>
                <p className="truncate text-xs font-black text-text-primary">{amount}</p>
              </div>
            </div>
          )
        })}
      </div>
    </section>
  )
}

function MiniLine({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <span className="truncate text-[11px] font-semibold text-text-tertiary">{label}</span>
      <span className="truncate text-xs font-black text-text-primary">{value}</span>
    </div>
  )
}

function FallbackAtmCard() {
  const { t } = useI18n()
  return (
    <div className="relative aspect-[1.586/1] w-full overflow-hidden rounded-[1.45rem] border border-white/10 bg-[linear-gradient(135deg,#10131f,oklch(0.20_0.09_40)_48%,#090a10)] p-6 shadow-[0_38px_80px_rgba(0,0,0,0.62)]">
      <div aria-hidden className="absolute -right-12 top-0 h-full w-1/2 rounded-full bg-[oklch(0.65_0.22_40_/_0.16)] blur-2xl" />
      <WalletCards className="relative text-white/80" size={34} />
      <p className="relative mt-20 font-mono text-xl font-black tracking-[0.16em] text-white">•••• •••• •••• 5614</p>
      <p className="relative mt-4 text-sm font-black uppercase tracking-[0.12em] text-white/80">{t('atm.clientFallback')}</p>
    </div>
  )
}
