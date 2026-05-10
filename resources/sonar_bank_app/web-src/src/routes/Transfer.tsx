import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, useReducedMotion } from 'motion/react'
import {
  AlertTriangle,
  ArrowLeft,
  ArrowRight,
  Check,
  CheckCircle2,
  CircleDollarSign,
  Clock3,
  Download,
  LockKeyhole,
  ReceiptText,
  Search,
  SendHorizontal,
  ShieldCheck,
  Sparkles,
  UserRound,
  Zap,
} from 'lucide-react'
import { Button, Card, CardContent, CardEyebrow, CardTitle, Input, Spinner } from '@/components/ui'
import { useExecuteTransfer, formatIban, isLargeTransfer, isValidSpanishIban, normalizeIban } from '@/data/mutations'
import type { TransferReceipt } from '@/data/mutations'
import { useBootstrap, useInvalidateBootstrap, useInvalidateRecentRecipients, useRecentRecipients } from '@/data/queries'
import type { Account, RecentRecipient } from '@/data/contracts'
import { getUserMessage, handleBankError } from '@/lib/bankError'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { maskIbanCompact, maskIbanDisplay, maskMoneyDisplay, maskOperationCode, revealIbanDisplay, revealOperationCode } from '@/lib/privacy'
import { toast } from '@/stores/toast'
import { useTransferWizard, type TransferWizardStep } from '@/stores/transferWizard'
import { usePrivacyMode } from '@/stores/privacy'
import { BankAvatar } from '@/components/brand/BankAvatar'

const EXPRESS_STEPS: TransferWizardStep[] = ['review', 'confirm']
const HOLD_TO_CONFIRM_MS = 1500
const POST_CONFIRM_REFETCH_MS = 3000

// Define STEPS as a function that gets the translated labels
function getTransferSteps(t: (key: TranslationKey) => string): Array<{ id: TransferWizardStep; label: string; helper: string }> {
  return [
    { id: 'amount', label: t('transfer.steps.amount'), helper: t('transfer.steps.amountHelper') },
    { id: 'recipient', label: t('transfer.steps.recipient'), helper: t('transfer.steps.recipientHelper') },
    { id: 'review', label: t('transfer.steps.review'), helper: t('transfer.steps.reviewHelper') },
    { id: 'confirm', label: t('transfer.steps.confirm'), helper: t('transfer.steps.confirmHelper') },
  ]
}

export function Transfer() {
  const { t, money } = useI18n()
  const navigate = useNavigate()
  const reduced = useReducedMotion()
  const { data } = useBootstrap()
  const invalidateBootstrap = useInvalidateBootstrap()
  const invalidateRecentRecipients = useInvalidateRecentRecipients()
  const primaryAccount = data?.accounts[0] ?? null
  const executeTransfer = useExecuteTransfer()
  const [receipt, setReceipt] = useState<TransferReceipt | null>(null)
  const fallbackRefetchTimerRef = useRef<number | null>(null)

  const step = useTransferWizard((s) => s.step)
  const expressMode = useTransferWizard((s) => s.expressMode)
  const idempotencyKey = useTransferWizard((s) => s.idempotencyKey)
  const correlationId = useTransferWizard((s) => s.correlationId)
  const amount = useTransferWizard((s) => s.amount)
  const memo = useTransferWizard((s) => s.memo)
  const recipientIban = useTransferWizard((s) => s.recipientIban)
  const recipientAlias = useTransferWizard((s) => s.recipientAlias)
  const init = useTransferWizard((s) => s.init)
  const setStep = useTransferWizard((s) => s.setStep)
  const clearOperationIds = useTransferWizard((s) => s.clearOperationIds)
  const reset = useTransferWizard((s) => s.reset)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  // Get STEPS with translations
  const STEPS = getTransferSteps(t)

  useEffect(() => {
    if (step !== 'confirm' && (!idempotencyKey || !correlationId)) init(false)
  }, [correlationId, idempotencyKey, init, step])

  useEffect(() => {
    if (expressMode && step === 'amount' && amount && recipientIban) {
      setStep('review')
    }
  }, [amount, expressMode, recipientIban, setStep, step])

  useEffect(() => {
    return () => {
      if (fallbackRefetchTimerRef.current) {
        window.clearTimeout(fallbackRefetchTimerRef.current)
      }
    }
  }, [])

  const visibleSteps = expressMode ? STEPS.filter((s) => EXPRESS_STEPS.includes(s.id)) : STEPS
  const isConfirmStep = step === 'confirm'
  const showRail = !isConfirmStep

  const canExecute = Boolean(primaryAccount && amount && recipientIban && idempotencyKey && correlationId)

  const handleExecute = async (): Promise<void> => {
    if (!primaryAccount || !amount || !recipientIban || !idempotencyKey || !correlationId) {
      toast.warning(t('transfer.incompleteTitle'), t('transfer.incompleteBody'))
      return
    }

    setReceipt(null)
    setStep('confirm')

    try {
      const nextReceipt = await executeTransfer.mutateAsync({
        from_iban: primaryAccount.iban,
        to_iban: recipientIban,
        amount_minor: amount,
        reason: memo.trim() ? memo.trim() : null,
        idempotency_key: idempotencyKey,
        correlation_id: correlationId,
      })
      setReceipt(nextReceipt)
      clearOperationIds()
      sfx.vault_close()
      toast.success(t('transfer.sentToastTitle'), `${streamerMode ? maskMoneyDisplay() : money(amount / 100)} → ${streamerMode ? t('transfer.hiddenRecipient') : recipientAlias ?? revealIbanDisplay(recipientIban)}`)

      if (fallbackRefetchTimerRef.current) {
        window.clearTimeout(fallbackRefetchTimerRef.current)
      }
      fallbackRefetchTimerRef.current = window.setTimeout(() => {
        void invalidateBootstrap()
        void invalidateRecentRecipients()
        fallbackRefetchTimerRef.current = null
      }, POST_CONFIRM_REFETCH_MS)
    } catch (err) {
      handleBankError(err)
    }
  }

  const handleDone = (): void => {
    reset()
    navigate('/')
  }

  const handleNew = (): void => {
    init(false)
    setReceipt(null)
    navigate('/transferir')
  }

  return (
    <motion.div
      initial={reduced ? false : { opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
      className="h-full w-full"
    >
      <div
        className={cn(
          'h-full w-full mx-auto grid min-h-0',
          showRail
            ? 'max-w-[1500px] grid-cols-[minmax(0,1fr)_320px] gap-4 2xl:gap-5'
            : 'max-w-[1080px] grid-cols-1',
        )}
      >
        <section className={cn('min-h-0 flex flex-col', isConfirmStep ? 'gap-0' : 'gap-4 2xl:gap-5')}>
          {!isConfirmStep ? (
            <TransferHero
              expressMode={expressMode}
              account={primaryAccount}
              amount={amount}
              recipientAlias={recipientAlias}
              recipientIban={recipientIban}
            />
          ) : null}
          <Card variant="glass" padding="md" className="min-h-0 flex-1 border-white/10 overflow-hidden rounded-[1.75rem]">
            <div className={cn('h-full min-h-0', isConfirmStep ? 'flex flex-col' : 'grid grid-rows-[auto_1fr] gap-3 2xl:gap-5')}>
              {!isConfirmStep ? <TransferStepper step={step} steps={visibleSteps} /> : null}
              <div className={cn('min-h-0', isConfirmStep ? 'h-full overflow-hidden' : 'overflow-y-auto pr-1 pb-5 scrollbar-thin')}>
                {step === 'amount' && (
                  <AmountStep account={primaryAccount} expressMode={expressMode} />
                )}
                {step === 'recipient' && (
                  <RecipientStep account={primaryAccount} />
                )}
                {step === 'review' && (
                  <ReviewStep
                    account={primaryAccount}
                    canExecute={canExecute && !executeTransfer.isPending}
                    onExecute={handleExecute}
                  />
                )}
                {step === 'confirm' && (
                  <ConfirmStep
                    amount={amount}
                    recipientAlias={recipientAlias}
                    recipientIban={recipientIban}
                    receipt={receipt}
                    error={executeTransfer.error}
                    pending={executeTransfer.isPending}
                    onBack={() => setStep('review')}
                    onDone={handleDone}
                    onNew={handleNew}
                  />
                )}
              </div>
            </div>
          </Card>
        </section>
        {showRail ? (
          <TransferRail
            account={primaryAccount}
            amount={amount}
            memo={memo}
            recipientAlias={recipientAlias}
            recipientIban={recipientIban}
          />
        ) : null}
      </div>
    </motion.div>
  )
}

function TransferHero({
  expressMode,
  account,
  amount,
  recipientAlias,
  recipientIban,
}: {
  expressMode: boolean
  account: Account | null
  amount: number | null
  recipientAlias: string | null
  recipientIban: string | null
}) {
  const { t, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const destination = recipientIban
    ? streamerMode ? maskIbanCompact(recipientIban) : revealIbanDisplay(recipientIban)
    : t('transfer.pendingDestination')
  const availableLabel = account ? streamerMode ? maskMoneyDisplay() : money(account.balance_minor / 100) : '—'
  const amountLabel = amount ? streamerMode ? maskMoneyDisplay() : money(amount / 100) : '—'

  return (
    <Card variant="glass" padding="none" className="relative overflow-hidden border-white/10 shrink-0 rounded-[1.75rem]">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 12% 0%, rgba(246,75,0,0.13), transparent 34%), linear-gradient(180deg, rgba(255,255,255,0.04), transparent 54%)',
        }}
      />
      <div className="relative flex items-center justify-between gap-5 p-5 2xl:p-6">
        <div className="flex flex-col gap-2">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              {expressMode ? <Zap size={12} strokeWidth={2.4} /> : <SendHorizontal size={12} strokeWidth={2.4} />}
              {expressMode ? t('transfer.expressQuick') : t('transfer.secureTransfer')}
            </span>
          </CardEyebrow>
          <div className="flex flex-col gap-1">
            <h1 className="text-3xl 2xl:text-4xl font-light tracking-[-0.055em] text-text-primary">{t('transfer.transferMoney')}</h1>
            <p className="text-sm text-text-secondary max-w-[58ch] leading-relaxed">
              {t('transfer.transferDescriptionFull')}
            </p>
          </div>
        </div>
        <div className="shrink-0 grid grid-cols-3 gap-2 min-w-[430px]">
          <HeroMetric label={t('transfer.available')} value={availableLabel} />
          <HeroMetric label={t('transfer.amountLabel')} value={amountLabel} />
          <HeroMetric label={t('transfer.destination')} value={streamerMode ? t('common.hidden') : recipientAlias ?? destination} />
        </div>
      </div>
    </Card>
  )
}

function HeroMetric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-border-subtle bg-white/[0.04] px-3 py-3 text-right min-w-0">
      <span className="block text-[10px] uppercase tracking-[0.16em] text-text-tertiary truncate">{label}</span>
      <span className="block text-sm 2xl:text-base font-semibold tactile-tabular-nums text-text-primary truncate">{value}</span>
    </div>
  )
}

function TransferStepper({ step, steps }: { step: TransferWizardStep; steps: Array<{ id: TransferWizardStep; label: string; helper: string }> }) {
  const activeIndex = Math.max(0, steps.findIndex((s) => s.id === step))

  return (
    <div className="grid gap-2" style={{ gridTemplateColumns: `repeat(${steps.length}, minmax(0, 1fr))` }}>
      {steps.map((item, index) => {
        const active = item.id === step
        const complete = index < activeIndex
        return (
          <div
            key={item.id}
            className={cn(
              'relative rounded-2xl border px-3 py-2.5 2xl:py-3 transition-colors',
              active
                ? 'border-white/18 bg-white/[0.075] text-text-primary'
                : complete
                  ? 'border-emerald-300/20 bg-emerald-300/[0.055] text-text-secondary'
                  : 'border-border-subtle bg-white/[0.025] text-text-tertiary',
            )}
          >
            <div className="flex items-center gap-2">
              <span
                className={cn(
                  'inline-flex h-6 w-6 2xl:h-7 2xl:w-7 items-center justify-center rounded-full border text-[11px] font-semibold tactile-tabular-nums',
                  active
                    ? 'border-white/20 bg-white/[0.10]'
                    : complete
                      ? 'border-emerald-300/20 bg-emerald-300/[0.10] text-emerald-200'
                      : 'border-border-subtle bg-transparent',
                )}
              >
                {complete ? <Check size={13} strokeWidth={2.6} /> : index + 1}
              </span>
              <span className="min-w-0 flex flex-col leading-tight">
                <span className="text-sm font-semibold truncate">{item.label}</span>
                <span className="text-[10px] uppercase tracking-[0.13em] text-text-tertiary truncate">{item.helper}</span>
              </span>
            </div>
          </div>
        )
      })}
    </div>
  )
}

function AmountStep({ account, expressMode }: { account: Account | null; expressMode: boolean }) {
  const { t, money, currencySymbol } = useI18n()
  const storeAmount = useTransferWizard((s) => s.amount)
  const storeMemo = useTransferWizard((s) => s.memo)
  const setAmount = useTransferWizard((s) => s.setAmount)
  const setStep = useTransferWizard((s) => s.setStep)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const recipientIban = useTransferWizard((s) => s.recipientIban)
  const [amountText, setAmountText] = useState(() => storeAmount ? formatMajorInput(storeAmount) : '')
  const [memoText, setMemoText] = useState(storeMemo)
  const [error, setError] = useState<string | null>(null)

  const amountMinor = parseAmountMinor(amountText)
  const presets = [25_00, 50_00, 120_00, 250_00]

  const submit = (): void => {
    if (!account) {
      setError(t('transfer.sourceAccountError'))
      return
    }
    if (!amountMinor || amountMinor <= 0) {
      setError(t('transfer.validAmountError'))
      return
    }
    if (amountMinor > account.balance_minor) {
      setError(t('transfer.insufficientFundsError'))
      return
    }

    setError(null)
    setAmount(amountMinor, memoText)
    setStep(expressMode && recipientIban ? 'review' : 'recipient')
  }

  return (
    <motion.div initial={{ opacity: 0, x: 8 }} animate={{ opacity: 1, x: 0 }} className="grid grid-cols-[minmax(0,1fr)_280px] gap-4 2xl:gap-5 pb-1">
      <div className="flex flex-col gap-4 2xl:gap-5">
        <StepHeader icon={<CircleDollarSign size={18} />} title={t('transfer.amountTitle')} description={t('transfer.amountDescription')} />
        <div className="rounded-3xl border border-border-subtle bg-white/[0.035] p-4 2xl:p-5 flex flex-col gap-3 2xl:gap-4">
          <Input
            label={t('transfer.amountLabel')}
            inputMode="decimal"
            value={amountText}
            onChange={(e) => setAmountText(e.target.value.replace(',', '.'))}
            placeholder="0.00"
            leftAdornment={<span className="text-lg font-semibold">{currencySymbol}</span>}
            error={error}
            inputSize="lg"
            className="text-3xl font-semibold tracking-[-0.04em] tactile-tabular-nums"
          />
          <div className="grid grid-cols-4 gap-2">
            {presets.map((preset) => (
              <button
                key={preset}
                type="button"
                onClick={() => {
                  setAmountText(formatMajorInput(preset))
                  setError(null)
                }}
                className="rounded-xl border border-border-subtle bg-white/[0.035] px-3 py-2 text-sm font-semibold tactile-tabular-nums text-text-secondary hover:bg-white/[0.075] hover:text-text-primary transition-colors tactile-focus-ring"
              >
                {streamerMode ? maskMoneyDisplay() : money(preset / 100)}
              </button>
            ))}
          </div>
          <Input
            label={t('transfer.memoLabel')}
            value={memoText}
            onChange={(e) => setMemoText(e.target.value.slice(0, 140))}
            placeholder={t('transfer.memoPlaceholder')}
            maxLength={140}
            hint={`${memoText.length}/140`}
          />
        </div>
        <div className="flex items-center justify-end gap-2 pb-1">
          <Button variant="secondary" rightIcon={<ArrowRight size={16} />} onClick={submit}>
            {t('transfer.reviewDestination')}
          </Button>
        </div>
      </div>
      <AmountInsight account={account} amountMinor={amountMinor} />
    </motion.div>
  )
}

function AmountInsight({ account, amountMinor }: { account: Account | null; amountMinor: number | null }) {
  const { t, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const remaining = account && amountMinor ? account.balance_minor - amountMinor : account?.balance_minor ?? 0
  const risk = amountMinor ? Math.min(1, amountMinor / Math.max(account?.balance_minor ?? 1, 1)) : 0

  return (
    <div className="rounded-3xl border border-border-subtle bg-white/[0.03] p-4 flex flex-col gap-3 2xl:gap-4 h-fit">
      <div className="flex items-center gap-2 text-text-secondary">
        <ShieldCheck size={16} strokeWidth={1.8} />
        <span className="text-sm font-semibold">{t('transfer.safeView')}</span>
      </div>
      <div className="space-y-3">
        <Metric label={t('transfer.available')} value={account ? streamerMode ? maskMoneyDisplay() : money(account.balance_minor / 100) : '—'} />
        <Metric label={t('transfer.afterSend')} value={account ? streamerMode ? maskMoneyDisplay() : money(Math.max(0, remaining) / 100) : '—'} />
      </div>
      <div className="h-2 rounded-full bg-white/[0.06] overflow-hidden">
        <div className="h-full rounded-full bg-white/35" style={{ width: `${Math.round(risk * 100)}%` }} />
      </div>
      {amountMinor && isLargeTransfer(amountMinor) ? (
        <div className="rounded-2xl border border-[var(--color-semantic-warning-deep)] bg-[var(--color-semantic-warning-glow)] p-3 text-xs text-[var(--color-semantic-warning-deep)] leading-relaxed">
          {t('transfer.largeAmountWarning')}
        </div>
      ) : null}
    </div>
  )
}

function RecipientStep({ account }: { account: Account | null }) {
  const { t } = useI18n()
  const { data, isLoading } = useRecentRecipients()
  const storeIban = useTransferWizard((s) => s.recipientIban)
  const storeAlias = useTransferWizard((s) => s.recipientAlias)
  const setRecipient = useTransferWizard((s) => s.setRecipient)
  const setStep = useTransferWizard((s) => s.setStep)
  const [iban, setIban] = useState(() => storeIban ? formatIban(storeIban) : '')
  const [alias, setAlias] = useState(storeAlias ?? '')
  const [searchText, setSearchText] = useState('')
  const [error, setError] = useState<string | null>(null)
  const normalized = normalizeIban(iban)
  const searchQuery = normalizeRecipientSearch(searchText)
  const filteredRecipients = (data?.recipients ?? []).filter((recipient) => {
    if (!searchQuery) return true
    const haystack = normalizeRecipientSearch([
      recipient.alias ?? '',
      recipient.counterpart_iban,
      formatIban(recipient.counterpart_iban),
      recipient.last_reason ?? '',
    ].join(' '))
    return haystack.includes(searchQuery)
  })

  const submit = (): void => {
    if (!isValidSpanishIban(iban)) {
      setError(t('transfer.validSpanishIban'))
      return
    }
    if (account && normalizeIban(account.iban) === normalized) {
      setError(t('transfer.cannotBeSameAccount'))
      return
    }
    setRecipient(formatIban(iban), alias.trim() || null)
    setError(null)
    setStep('review')
  }

  const selectRecipient = (recipient: RecentRecipient): void => {
    setIban(formatIban(recipient.counterpart_iban))
    setAlias(recipient.alias ?? '')
    setRecipient(recipient.counterpart_iban, recipient.alias)
    setError(null)
    sfx.console_tap()
  }

  return (
    <motion.div initial={{ opacity: 0, x: 8 }} animate={{ opacity: 1, x: 0 }} className="flex flex-col gap-4 2xl:gap-5 pb-1">
      <StepHeader icon={<UserRound size={18} />} title={t('transfer.recipientStepTitle')} description={t('transfer.recipientStepDescription')} />
      <div className="grid grid-cols-[minmax(0,0.95fr)_minmax(0,1.05fr)] gap-4 2xl:gap-5">
        <Card variant="elevated" padding="md" className="border-white/10 min-h-[300px] 2xl:min-h-[360px]">
          <CardContent className="gap-3">
            <div className="flex items-center justify-between">
              <span className="text-sm font-semibold text-text-primary">{t('transfer.contacts')}</span>
              <span className="text-[11px] text-text-tertiary tactile-tabular-nums">{filteredRecipients.length}</span>
            </div>
            <Input
              type="search"
              aria-label={t('transfer.searchAriaLabel')}
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              placeholder={t('transfer.searchPlaceholder')}
              inputSize="sm"
              leftAdornment={<Search size={15} />}
              autoComplete="off"
            />
            {isLoading ? (
              <div className="flex h-56 items-center justify-center text-text-tertiary">
                <Spinner size="sm" />
              </div>
            ) : filteredRecipients.length === 0 ? (
              <div className="flex min-h-[180px] items-center justify-center rounded-3xl border border-border-subtle bg-white/[0.025] px-4 text-center text-sm text-text-tertiary">
                {t('transfer.noMatches')}
              </div>
            ) : (
              <div className="max-h-[300px] overflow-y-auto pr-1 space-y-2 scrollbar-thin">
                {filteredRecipients.map((recipient) => (
                  <RecipientChip
                    key={recipient.counterpart_iban}
                    recipient={recipient}
                    active={normalizeIban(recipient.counterpart_iban) === normalized}
                    onClick={() => selectRecipient(recipient)}
                  />
                ))}
              </div>
            )}
          </CardContent>
        </Card>
        <div className="rounded-3xl border border-border-subtle bg-white/[0.035] p-4 2xl:p-5 flex flex-col gap-4">
          <Input
            label={t('transfer.destinationLabel')}
            value={iban}
            onChange={(e) => setIban(formatIban(e.target.value))}
            placeholder={t('transfer.ibanPlaceholder')}
            error={error}
            inputSize="lg"
            className="font-mono tracking-[0.06em]"
          />
          <Input
            label={t('transfer.aliasLabel')}
            value={alias}
            onChange={(e) => setAlias(e.target.value.slice(0, 48))}
            placeholder={t('transfer.aliasPlaceholder')}
          />
          <div className="mt-auto flex items-center justify-between gap-2 pt-3 2xl:pt-4">
            <Button variant="secondary" leftIcon={<ArrowLeft size={16} />} onClick={() => setStep('amount')}>
              {t('transfer.back')}
            </Button>
            <Button variant="primary" rightIcon={<ArrowRight size={16} />} onClick={submit}>
              {t('transfer.review')}
            </Button>
          </div>
        </div>
      </div>
    </motion.div>
  )
}

function RecipientChip({ recipient, active, onClick }: { recipient: RecentRecipient; active: boolean; onClick: () => void }) {
  const { t } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const ibanLabel = streamerMode ? maskIbanCompact(recipient.counterpart_iban) : revealIbanDisplay(recipient.counterpart_iban)
  const label = streamerMode ? t('transfer.hiddenRecipientChip') : recipient.alias ?? ibanLabel
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'w-full rounded-2xl border px-3 py-3 flex items-center gap-3 text-left transition-colors tactile-focus-ring',
        active
          ? 'border-white/18 bg-white/[0.075]'
          : 'border-border-subtle bg-white/[0.025] hover:bg-white/[0.055]',
      )}
    >
      <BankAvatar name={label} size="md" />
      <span className="min-w-0 flex-1 flex flex-col gap-0.5">
        <span className="text-sm font-semibold text-text-primary truncate">{label}</span>
        <span className="text-[11px] text-text-tertiary truncate">{streamerMode ? maskIbanDisplay(recipient.counterpart_iban) : revealIbanDisplay(recipient.counterpart_iban)}</span>
      </span>
      <span className="text-[11px] font-semibold text-text-secondary tactile-tabular-nums">×{recipient.transfer_count}</span>
    </button>
  )
}

function ReviewStep({ account, canExecute, onExecute }: { account: Account | null; canExecute: boolean; onExecute: () => void }) {
  const { t, money } = useI18n()
  const amount = useTransferWizard((s) => s.amount)
  const memo = useTransferWizard((s) => s.memo)
  const recipientIban = useTransferWizard((s) => s.recipientIban)
  const recipientAlias = useTransferWizard((s) => s.recipientAlias)
  const expressMode = useTransferWizard((s) => s.expressMode)
  const correlationId = useTransferWizard((s) => s.correlationId)
  const setStep = useTransferWizard((s) => s.setStep)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const large = Boolean(amount && isLargeTransfer(amount))
  const fromIban = account ? streamerMode ? maskIbanDisplay(account.iban) : revealIbanDisplay(account.iban) : '—'
  const toIban = recipientIban ? streamerMode ? maskIbanDisplay(recipientIban) : revealIbanDisplay(recipientIban) : undefined
  const recipientLabel = streamerMode ? t('transfer.hiddenRecipient') : recipientAlias ?? (recipientIban ? revealIbanDisplay(recipientIban) : '—')
  const amountLabel = amount ? streamerMode ? maskMoneyDisplay() : money(amount / 100) : '—'

  return (
    <motion.div initial={{ opacity: 0, x: 8 }} animate={{ opacity: 1, x: 0 }} className="grid grid-cols-[minmax(0,1fr)_300px] gap-4 2xl:gap-5 pb-1">
      <div className="flex flex-col gap-4 2xl:gap-5">
        <StepHeader icon={<ReceiptText size={18} />} title={t('transfer.reviewStepTitle')} description={t('transfer.reviewStepDescription')} />
        <div className="rounded-3xl border border-border-subtle bg-white/[0.035] p-4 2xl:p-5 flex flex-col gap-3 2xl:gap-4">
          <div className="flex items-start justify-between gap-3 border-b border-border-subtle pb-3">
            <span className="text-[11px] uppercase tracking-[0.14em] text-text-tertiary pt-0.5">{t('transfer.securityCode')}</span>
            <span className="text-xs font-mono text-text-tertiary text-right">{streamerMode ? maskOperationCode(correlationId) : revealOperationCode(correlationId)}</span>
          </div>
          <ReviewRow label={t('common.from')} value={fromIban} />
          <ReviewRow label={t('common.to')} value={recipientLabel} helper={toIban} />
          <ReviewRow label={t('transfer.amountLabel')} value={amountLabel} strong />
          <ReviewRow label={t('transfer.concept')} value={streamerMode ? t('transfer.hiddenConcept') : memo.trim() || t('transfer.noConcept')} />
        </div>
        <div className="flex items-center justify-between gap-2 pb-1">
          <Button variant="secondary" leftIcon={<ArrowLeft size={16} />} onClick={() => setStep(expressMode ? 'recipient' : 'recipient')}>
            {t('transfer.editDestination')}
          </Button>
          <HoldToConfirmButton disabled={!canExecute} onConfirm={onExecute} />
        </div>
      </div>
      <div className="flex flex-col gap-3">
        {large ? <LargeTransferWarning amount={amount ?? 0} /> : <SecurityPanel />}
        <Card variant="elevated" padding="md" className="border-white/10">
          <CardContent className="gap-2">
            <div className="flex items-center gap-2 text-text-secondary">
              <Clock3 size={15} />
              <span className="text-sm font-semibold">{t('transfer.duplicateProtection')}</span>
            </div>
            <p className="text-xs text-text-tertiary leading-relaxed">{t('transfer.duplicateProtectionDescription')}</p>
          </CardContent>
        </Card>
      </div>
    </motion.div>
  )
}

function LargeTransferWarning({ amount }: { amount: number }) {
  const { t, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  return (
    <Card variant="elevated" padding="md" className="border-[var(--color-semantic-warning-deep)] bg-[var(--color-semantic-warning-glow)]">
      <CardContent className="gap-3">
        <div className="flex items-center gap-2 text-[var(--color-semantic-warning-deep)]">
          <AlertTriangle size={17} strokeWidth={2} />
          <span className="text-sm font-semibold">{t('transfer.confirmationReinforced')}</span>
        </div>
        <p className="text-xs text-[var(--color-text-primary)] leading-relaxed">
          {t('transfer.confirmationDescription').replace('{amount}', streamerMode ? maskMoneyDisplay() : money(amount / 100))}
        </p>
      </CardContent>
    </Card>
  )
}

function SecurityPanel() {
  const { t } = useI18n()
  return (
    <Card variant="elevated" padding="md" className="border-emerald-300/20 bg-emerald-300/[0.045]">
      <CardContent className="gap-3">
        <div className="flex items-center gap-2 text-emerald-100">
          <ShieldCheck size={17} strokeWidth={2} />
          <span className="text-sm font-semibold">{t('transfer.operationProtected')}</span>
        </div>
        <p className="text-xs text-emerald-100/75 leading-relaxed">{t('transfer.operationDescription')}</p>
      </CardContent>
    </Card>
  )
}

function HoldToConfirmButton({ disabled, onConfirm }: { disabled: boolean; onConfirm: () => void }) {
  const { t } = useI18n()
  const [holding, setHolding] = useState(false)
  const [progress, setProgress] = useState(0)
  const timerRef = useRef<number | null>(null)
  const intervalRef = useRef<number | null>(null)
  const startRef = useRef(0)

  const clear = (): void => {
    if (timerRef.current) window.clearTimeout(timerRef.current)
    if (intervalRef.current) window.clearInterval(intervalRef.current)
    timerRef.current = null
    intervalRef.current = null
    setHolding(false)
    setProgress(0)
  }

  const start = (): void => {
    if (disabled || holding) return
    sfx.depth_press()
    startRef.current = performance.now()
    setHolding(true)
    intervalRef.current = window.setInterval(() => {
      setProgress(Math.min(1, (performance.now() - startRef.current) / HOLD_TO_CONFIRM_MS))
    }, 16)
    timerRef.current = window.setTimeout(() => {
      clear()
      onConfirm()
    }, HOLD_TO_CONFIRM_MS)
  }

  useEffect(() => clear, [])

  return (
    <button
      type="button"
      disabled={disabled}
      onPointerDown={start}
      onPointerUp={clear}
      onPointerLeave={clear}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') start()
      }}
      onKeyUp={clear}
      className={cn(
        'relative h-12 min-w-[230px] overflow-hidden rounded-xl tactile-focus-ring border border-transparent px-5 font-semibold text-text-primary',
        'tactile-button-primary disabled:opacity-55 disabled:pointer-events-none',
      )}
    >
      <span className="absolute inset-y-0 left-0 bg-white/20" style={{ width: `${Math.round(progress * 100)}%` }} />
      <span className="relative inline-flex items-center justify-center gap-2">
        <LockKeyhole size={16} />
        {holding ? t('transfer.holding') : t('transfer.holdToSend')}
      </span>
    </button>
  )
}

function ConfirmStep({
  amount,
  recipientAlias,
  recipientIban,
  receipt,
  error,
  pending,
  onBack,
  onDone,
  onNew,
}: {
  amount: number | null
  recipientAlias: string | null
  recipientIban: string | null
  receipt: TransferReceipt | null
  error: Error | null
  pending: boolean
  onBack: () => void
  onDone: () => void
  onNew: () => void
}) {
  const { t, money, dateTime } = useI18n()
  const [pdfPending, setPdfPending] = useState(false)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  const handleDownloadReceiptPdf = async (): Promise<void> => {
    if (!receipt || pdfPending) return

    setPdfPending(true)
    try {
      const { downloadTransferReceiptPdf } = await import('./transfer/receipt-pdf')
      await downloadTransferReceiptPdf({
        receipt,
        recipientLabel: streamerMode ? t('transfer.hiddenRecipient') : recipientAlias ?? (recipientIban
          ? streamerMode ? maskIbanCompact(recipientIban) : revealIbanDisplay(recipientIban)
          : streamerMode ? maskIbanCompact(receipt.to_iban) : revealIbanDisplay(receipt.to_iban)),
        amountLabel: streamerMode ? maskMoneyDisplay() : money((amount ?? receipt.amount_minor) / 100),
        availableBalanceLabel: streamerMode ? maskMoneyDisplay() : money(receipt.available_balance_minor / 100),
        fromIbanMasked: streamerMode ? maskIbanDisplay(receipt.from_iban) : revealIbanDisplay(receipt.from_iban),
        toIbanMasked: streamerMode ? maskIbanDisplay(receipt.to_iban) : revealIbanDisplay(receipt.to_iban),
        timestampLabel: dateTime(receipt.committed_at_ms, { dateStyle: 'medium', timeStyle: 'short' }),
        streamerMode,
        labels: {
          receiptTitle: t('transfer.pdfReceiptTitle'),
          sentAmount: t('transfer.pdfSentAmount'),
          receiptNumber: t('transfer.pdfReceiptNumber'),
          securityCode: t('transfer.pdfSecurityCode'),
          from: t('common.from'),
          to: t('common.to'),
          memo: t('transfer.concept'),
          hiddenMemo: t('transfer.hiddenConcept'),
          noMemo: t('transfer.noConcept'),
          date: t('common.date'),
          availableBalance: t('transfer.availableBalance'),
          bankReference: t('transfer.pdfBankReference'),
          receiptWatermark: t('common.receipt').toUpperCase(),
          footerLine1: t('transfer.pdfFooterLine1'),
          footerLine2: t('transfer.pdfFooterLine2'),
          committedStatus: t('transfer.pdfCommittedStatus'),
          pendingStatus: t('common.pending').toUpperCase(),
          revertedStatus: t('transactions.reverted').toUpperCase(),
          failedStatus: t('transactions.failed').toUpperCase(),
        },
      })
      sfx.coin_clink()
      toast.success(t('transfer.receiptPdfGenerated'), streamerMode ? maskOperationCode(receipt.transaction_id) : revealOperationCode(receipt.transaction_id))
    } catch {
      toast.warning(t('transfer.pdfErrorTitle'), t('transfer.pdfErrorDescription'))
    } finally {
      setPdfPending(false)
    }
  }

  if (pending) {
    return (
      <ResultShell tone="pending" icon={<Spinner size="lg" variant="brand" />} title={t('transfer.sendingTransfer')} description={t('transfer.sendingDescription')} />
    )
  }

  if (error) {
    const code = 'code' in error ? String(error.code) : 'INTERNAL_ERROR'
    const message = getUserMessage(code)
    return (
      <ResultShell tone="error" icon={<AlertTriangle size={38} />} title={message.title} description={message.description}>
        <div className="flex justify-center gap-2">
          <Button variant="secondary" leftIcon={<ArrowLeft size={16} />} onClick={onBack}>{t('transfer.back')}</Button>
          <Button variant="primary" onClick={onBack}>{t('transfer.reviewData')}</Button>
        </div>
      </ResultShell>
    )
  }

  if (!receipt) {
    return <ResultShell tone="pending" icon={<Spinner size="lg" variant="brand" />} title={t('transfer.preparingReceipt')} description={t('transfer.momentDescription')} />
  }

  return (
    <ResultShell
      tone="success"
      icon={<CheckCircle2 size={38} strokeWidth={1.8} />}
      title={t('transfer.completedTitle')}
      description={`${streamerMode ? maskMoneyDisplay() : money((amount ?? receipt.amount_minor) / 100)} → ${streamerMode ? t('transfer.hiddenRecipient') : recipientAlias ?? (recipientIban ? revealIbanDisplay(recipientIban) : t('transfer.hiddenRecipient'))}.`}
    >
      <div className="mx-auto w-full max-w-md rounded-3xl border border-border-subtle bg-white/[0.035] p-3.5 text-left">
        <ReceiptRow label={t('common.receipt')} value={streamerMode ? maskOperationCode(receipt.transaction_id) : revealOperationCode(receipt.transaction_id)} mono />
        <ReceiptRow label={t('transfer.securityCode')} value={streamerMode ? maskOperationCode(receipt.correlation_id) : revealOperationCode(receipt.correlation_id)} mono />
        <ReceiptRow label={t('common.from')} value={streamerMode ? maskIbanDisplay(receipt.from_iban) : revealIbanDisplay(receipt.from_iban)} />
        <ReceiptRow label={t('common.to')} value={streamerMode ? maskIbanDisplay(receipt.to_iban) : revealIbanDisplay(receipt.to_iban)} helper={streamerMode ? undefined : recipientAlias ?? undefined} />
        <ReceiptRow label={t('transfer.concept')} value={streamerMode ? t('common.hidden') : receipt.reason?.trim() || t('transfer.noConcept')} />
        <ReceiptRow label={t('common.date')} value={dateTime(receipt.committed_at_ms, { dateStyle: 'medium', timeStyle: 'short' })} />
        <ReceiptRow label={t('transfer.availableBalance')} value={streamerMode ? maskMoneyDisplay() : money(receipt.available_balance_minor / 100)} />
        <ReceiptRow label={t('common.status')} value={t('transfer.confirmed')} />
      </div>
      <div className="flex flex-wrap justify-center gap-2">
        <Button
          variant="secondary"
          leftIcon={pdfPending ? <Spinner size="sm" /> : <Download size={16} />}
          disabled={pdfPending}
          onClick={handleDownloadReceiptPdf}
        >
          {pdfPending ? 'Generating PDF' : t('transfer.pdf')}
        </Button>
        <Button variant="secondary" onClick={onNew}>{t('transfer.newTransfer')}</Button>
        <Button variant="primary" rightIcon={<ArrowRight size={16} />} onClick={onDone}>Volver a inicio</Button>
      </div>
    </ResultShell>
  )
}

function ResultShell({ tone, icon, title, description, children }: { tone: 'pending' | 'success' | 'error'; icon: React.ReactNode; title: string; description: string; children?: React.ReactNode }) {
  const toneClass = tone === 'success' ? 'text-emerald-100 border-emerald-300/20 bg-emerald-300/[0.055]' : tone === 'error' ? 'text-red-100 border-red-300/20 bg-red-300/[0.055]' : 'text-text-primary border-border-subtle bg-white/[0.035]'

  return (
    <div className="h-full min-h-0 flex items-center justify-center py-1">
      <motion.div
        initial={{ opacity: 0, scale: 0.96, y: 10 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.36, ease: [0.16, 1, 0.3, 1] }}
        className="w-full max-w-xl text-center flex flex-col items-center gap-3 2xl:gap-4"
      >
        <motion.div
          initial={{ scale: 0.82 }}
          animate={{ scale: tone === 'success' ? [0.86, 1.08, 1] : 1 }}
          transition={{ duration: 0.52, ease: [0.16, 1, 0.3, 1] }}
          className={cn('inline-flex h-16 w-16 2xl:h-20 2xl:w-20 items-center justify-center rounded-full border', toneClass)}
        >
          {icon}
        </motion.div>
        <div className="flex flex-col gap-1.5">
          <h2 className="text-2xl 2xl:text-3xl font-semibold tracking-[-0.04em] text-text-primary">{title}</h2>
          <p className="text-sm text-text-secondary leading-relaxed max-w-[52ch]">{description}</p>
        </div>
        {children}
      </motion.div>
    </div>
  )
}

function TransferRail({
  account,
  amount,
  memo,
  recipientAlias,
  recipientIban,
}: {
  account: Account | null
  amount: number | null
  memo: string
  recipientAlias: string | null
  recipientIban: string | null
}) {
  const { t, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const destinationLabel = streamerMode ? t('transfer.hiddenRecipient') : recipientAlias ?? (recipientIban ? revealIbanDisplay(recipientIban) : t('transfer.selectDestination'))
  const hasDestination = Boolean(recipientAlias || recipientIban)
  const hasAmount = Boolean(amount)
  return (
    <aside className="min-h-0 flex flex-col gap-4 2xl:gap-5">
      <Card variant="glass" padding="none" className="relative min-h-0 overflow-hidden rounded-[1.75rem] border-white/10 flex-1">
        <div
          aria-hidden
          className="absolute inset-0 pointer-events-none"
          style={{
            background:
              'radial-gradient(circle at 84% 0%, rgba(255,255,255,0.08), transparent 34%), linear-gradient(180deg, rgba(4,1,1,0.86), rgba(0,0,0,0.92))',
          }}
        />
        <div className="relative h-full min-h-0 flex flex-col p-5 2xl:p-6">
          <div className="flex items-center justify-between shrink-0">
            <div className="flex items-center gap-2">
              <Sparkles size={16} className="text-white/72" />
              <CardTitle className="text-base text-white">{t('transfer.railTitle')}</CardTitle>
            </div>
            <span className="rounded-full px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.13em] text-white/68" style={{ background: 'rgba(255,255,255,0.1)' }}>
              {t('transfer.secureBadge')}
            </span>
          </div>

          <div className="mt-5 rounded-[1.55rem] border border-white/10 bg-white/[0.045] px-4 py-4">
            <span className="block text-[11px] uppercase tracking-[0.14em] text-white/46">{t('transfer.amountLabel')}</span>
            <span className="block text-3xl font-light tracking-[-0.055em] tactile-tabular-nums text-white">
              {amount ? streamerMode ? maskMoneyDisplay() : money(amount / 100) : '—'}
            </span>
          </div>

          <div className="mt-4 rounded-[1.55rem] border border-white/10 bg-white/[0.035] p-3.5">
            <span className="block text-[11px] uppercase tracking-[0.14em] text-white/46 mb-3">{t('transfer.destination')}</span>
            <div className="flex items-center gap-3">
              <BankAvatar name={destinationLabel} size="lg" />
              <span className="min-w-0 flex flex-col">
                <span className="text-sm font-semibold text-white truncate">{destinationLabel}</span>
                <span className="text-[11px] text-white/46 truncate">{recipientIban ? streamerMode ? maskIbanDisplay(recipientIban) : revealIbanDisplay(recipientIban) : t('transfer.destinationPending')}</span>
              </span>
            </div>
          </div>

          <div className="mt-4 space-y-2">
            <RailCheck done={hasAmount} label={t('transfer.amountSelected')} />
            <RailCheck done={hasDestination} label={t('transfer.destinationVerified')} />
            <RailCheck done={hasAmount && hasDestination} label={t('transfer.readyForReview')} />
          </div>

          <div className="mt-auto pt-4 space-y-2">
            <Metric label={t('common.from')} value={account ? streamerMode ? maskIbanCompact(account.iban) : revealIbanDisplay(account.iban) : '—'} />
            {memo.trim() ? <Metric label={t('transfer.concept')} value={streamerMode ? t('transfer.hiddenConcept') : memo.trim()} /> : null}
          </div>
        </div>
      </Card>
    </aside>
  )
}

function RailCheck({ done, label }: { done: boolean; label: string }) {
  return (
    <div className="flex items-center gap-2 rounded-2xl border border-white/8 bg-black/16 px-3 py-2.5">
      <span
        className="inline-flex h-5 w-5 items-center justify-center rounded-full border text-[10px]"
        style={{
          borderColor: done ? 'rgba(95,211,127,0.42)' : 'rgba(255,255,255,0.12)',
          background: done ? 'rgba(95,211,127,0.12)' : 'transparent',
          color: done ? 'rgb(143, 225, 161)' : 'rgba(255,255,255,0.36)',
        }}
      >
        {done ? <Check size={12} strokeWidth={2.6} /> : '·'}
      </span>
      <span className="text-sm font-medium text-white/72">{label}</span>
    </div>
  )
}

function StepHeader({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
  return (
    <div className="flex items-start gap-3">
      <div className="inline-flex h-10 w-10 items-center justify-center rounded-2xl border border-border-subtle bg-white/[0.05] text-text-secondary">
        {icon}
      </div>
      <div className="flex flex-col gap-1">
        <h2 className="text-2xl font-semibold tracking-[-0.04em] text-text-primary">{title}</h2>
        <p className="text-sm text-text-secondary leading-relaxed">{description}</p>
      </div>
    </div>
  )
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-start justify-between gap-3 rounded-2xl border border-border-subtle bg-white/[0.025] px-3 py-2.5">
      <span className="text-[11px] uppercase tracking-[0.13em] text-text-tertiary">{label}</span>
      <span className="text-sm font-semibold text-text-primary text-right break-all">{value}</span>
    </div>
  )
}

function ReviewRow({ label, value, helper, strong, mono }: { label: string; value: string; helper?: string; strong?: boolean; mono?: boolean }) {
  return (
    <div className="flex items-start justify-between gap-4 border-b border-border-subtle pb-3 last:border-b-0 last:pb-0">
      <span className="text-[11px] uppercase tracking-[0.14em] text-text-tertiary pt-1">{label}</span>
      <span className="text-right flex flex-col gap-0.5 min-w-0">
        <span className={cn('text-text-primary break-all', strong ? 'text-2xl font-semibold tracking-[-0.04em] tactile-tabular-nums' : 'text-sm font-semibold', mono ? 'font-mono text-xs text-text-secondary' : undefined)}>{value}</span>
        {helper ? <span className="text-[11px] text-text-tertiary font-mono tracking-[0.04em] break-all">{helper}</span> : null}
      </span>
    </div>
  )
}

function ReceiptRow({ label, value, helper, mono }: { label: string; value: string; helper?: string; mono?: boolean }) {
  return (
    <div className="flex items-start justify-between gap-4 border-b border-border-subtle py-2 first:pt-0 last:border-b-0 last:pb-0">
      <span className="text-[10px] uppercase tracking-[0.14em] text-text-tertiary pt-1">{label}</span>
      <span className="text-right flex flex-col gap-0.5 min-w-0">
        <span className={cn('text-sm font-semibold text-text-primary break-all', mono ? 'font-mono text-xs text-text-secondary' : undefined)}>{value}</span>
        {helper ? <span className="text-[11px] text-text-tertiary tracking-[0.02em] break-all">{helper}</span> : null}
      </span>
    </div>
  )
}

function parseAmountMinor(value: string): number | null {
  const normalized = value.trim().replace(',', '.')
  if (!normalized) return null
  if (!/^\d+(\.\d{0,2})?$/.test(normalized)) return null
  const [eurosRaw, centsRaw = ''] = normalized.split('.')
  const euros = Number(eurosRaw)
  if (!Number.isFinite(euros)) return null
  const cents = Number(centsRaw.padEnd(2, '0').slice(0, 2))
  return euros * 100 + cents
}

function formatMajorInput(amountMinor: number): string {
  return (amountMinor / 100).toFixed(2)
}


function normalizeRecipientSearch(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
}
