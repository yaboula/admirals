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
import { cn, formatCurrency } from '@/lib/utils'
import { toast } from '@/stores/toast'
import { useTransferWizard, type TransferWizardStep } from '@/stores/transferWizard'
import { BankAvatar } from '@/components/brand/BankAvatar'

const STEPS: Array<{ id: TransferWizardStep; label: string; helper: string }> = [
  { id: 'amount', label: 'Importe', helper: 'Saldo' },
  { id: 'recipient', label: 'Destino', helper: 'Cuenta' },
  { id: 'review', label: 'Firma', helper: 'Revisión' },
  { id: 'confirm', label: 'Recibo', helper: 'Listo' },
]

const EXPRESS_STEPS: TransferWizardStep[] = ['review', 'confirm']
const HOLD_TO_CONFIRM_MS = 1500
const POST_CONFIRM_REFETCH_MS = 3000

export function Transfer() {
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
  const reset = useTransferWizard((s) => s.reset)

  useEffect(() => {
    if (!idempotencyKey || !correlationId) init(false)
  }, [correlationId, idempotencyKey, init])

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
      toast.warning('Transferencia incompleta', 'Revisa el importe y el destinatario antes de enviar.')
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
      sfx.vault_close()
      toast.success('Transferencia enviada', `${formatCurrency(amount / 100)} → ${recipientAlias ?? formatIbanShort(recipientIban)}`)

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
  return (
    <Card variant="glass" padding="none" className="relative overflow-hidden border-white/10 shrink-0 rounded-[1.75rem]">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 12% 0%, oklch(0.70 0.22 40 / 0.13), transparent 34%), linear-gradient(180deg, oklch(1 0 0 / 0.035), transparent 54%)',
        }}
      />
      <div className="relative flex items-center justify-between gap-5 p-5 2xl:p-6">
        <div className="flex flex-col gap-2">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              {expressMode ? <Zap size={12} strokeWidth={2.4} /> : <SendHorizontal size={12} strokeWidth={2.4} />}
              {expressMode ? 'ENVÍO RÁPIDO' : 'TRANSFERENCIA SEGURA'}
            </span>
          </CardEyebrow>
          <div className="flex flex-col gap-1">
            <h1 className="text-3xl 2xl:text-4xl font-light tracking-[-0.055em] text-text-primary">Transferir dinero</h1>
            <p className="text-sm text-text-secondary max-w-[58ch] leading-relaxed">
              Envía con revisión clara, firma sostenida y recibo descargable al momento.
            </p>
          </div>
        </div>
        <div className="shrink-0 grid grid-cols-3 gap-2 min-w-[430px]">
          <HeroMetric label="Disponible" value={account ? formatCurrency(account.balance_minor / 100) : '—'} />
          <HeroMetric label="Importe" value={amount ? formatCurrency(amount / 100) : '—'} />
          <HeroMetric label="Destino" value={recipientAlias ?? (recipientIban ? formatIbanShort(recipientIban) : 'Pendiente')} />
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

function TransferStepper({ step, steps }: { step: TransferWizardStep; steps: typeof STEPS }) {
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
  const storeAmount = useTransferWizard((s) => s.amount)
  const storeMemo = useTransferWizard((s) => s.memo)
  const setAmount = useTransferWizard((s) => s.setAmount)
  const setStep = useTransferWizard((s) => s.setStep)
  const recipientIban = useTransferWizard((s) => s.recipientIban)
  const [amountText, setAmountText] = useState(() => storeAmount ? formatMajorInput(storeAmount) : '')
  const [memoText, setMemoText] = useState(storeMemo)
  const [error, setError] = useState<string | null>(null)

  const amountMinor = parseAmountMinor(amountText)
  const presets = [25_00, 50_00, 120_00, 250_00]

  const submit = (): void => {
    if (!account) {
      setError('No se pudo cargar la cuenta origen.')
      return
    }
    if (!amountMinor || amountMinor <= 0) {
      setError('Introduce un importe válido.')
      return
    }
    if (amountMinor > account.balance_minor) {
      setError('El importe supera tu saldo disponible.')
      return
    }

    setError(null)
    setAmount(amountMinor, memoText)
    setStep(expressMode && recipientIban ? 'review' : 'recipient')
  }

  return (
    <motion.div initial={{ opacity: 0, x: 8 }} animate={{ opacity: 1, x: 0 }} className="grid grid-cols-[minmax(0,1fr)_280px] gap-4 2xl:gap-5 pb-1">
      <div className="flex flex-col gap-4 2xl:gap-5">
        <StepHeader icon={<CircleDollarSign size={18} />} title="Elige el importe" description="Te mostramos el saldo final antes de continuar." />
        <div className="rounded-3xl border border-border-subtle bg-white/[0.035] p-4 2xl:p-5 flex flex-col gap-3 2xl:gap-4">
          <Input
            label="Importe"
            inputMode="decimal"
            value={amountText}
            onChange={(e) => setAmountText(e.target.value.replace(',', '.'))}
            placeholder="0.00"
            leftAdornment={<span className="text-lg font-semibold">€</span>}
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
                {formatCurrency(preset / 100)}
              </button>
            ))}
          </div>
          <Input
            label="Concepto"
            value={memoText}
            onChange={(e) => setMemoText(e.target.value.slice(0, 140))}
            placeholder="Cena, alquiler, reembolso..."
            maxLength={140}
            hint={`${memoText.length}/140`}
          />
        </div>
        <div className="flex items-center justify-end gap-2 pb-1">
          <Button variant="primary" rightIcon={<ArrowRight size={16} />} onClick={submit}>
            Continuar
          </Button>
        </div>
      </div>
      <AmountInsight account={account} amountMinor={amountMinor} />
    </motion.div>
  )
}

function AmountInsight({ account, amountMinor }: { account: Account | null; amountMinor: number | null }) {
  const remaining = account && amountMinor ? account.balance_minor - amountMinor : account?.balance_minor ?? 0
  const risk = amountMinor ? Math.min(1, amountMinor / Math.max(account?.balance_minor ?? 1, 1)) : 0

  return (
    <div className="rounded-3xl border border-border-subtle bg-white/[0.03] p-4 flex flex-col gap-3 2xl:gap-4 h-fit">
      <div className="flex items-center gap-2 text-text-secondary">
        <ShieldCheck size={16} strokeWidth={1.8} />
        <span className="text-sm font-semibold">Vista segura</span>
      </div>
      <div className="space-y-3">
        <Metric label="Disponible" value={account ? formatCurrency(account.balance_minor / 100) : '—'} />
        <Metric label="Después del envío" value={account ? formatCurrency(Math.max(0, remaining) / 100) : '—'} />
      </div>
      <div className="h-2 rounded-full bg-white/[0.06] overflow-hidden">
        <div className="h-full rounded-full bg-white/35" style={{ width: `${Math.round(risk * 100)}%` }} />
      </div>
      {amountMinor && isLargeTransfer(amountMinor) ? (
        <div className="rounded-2xl border border-amber-300/20 bg-amber-300/[0.07] p-3 text-xs text-amber-100 leading-relaxed">
          Te pediremos una confirmación más consciente por el importe elegido.
        </div>
      ) : null}
    </div>
  )
}

function RecipientStep({ account }: { account: Account | null }) {
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
      setError('Introduce un IBAN español válido.')
      return
    }
    if (account && normalizeIban(account.iban) === normalized) {
      setError('El destinatario no puede ser tu cuenta origen.')
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
      <StepHeader icon={<UserRound size={18} />} title="Elige destinatario" description="Selecciona un contacto reciente o introduce un IBAN manualmente." />
      <div className="grid grid-cols-[minmax(0,0.95fr)_minmax(0,1.05fr)] gap-4 2xl:gap-5">
        <Card variant="elevated" padding="md" className="border-white/10 min-h-[300px] 2xl:min-h-[360px]">
          <CardContent className="gap-3">
            <div className="flex items-center justify-between">
              <span className="text-sm font-semibold text-text-primary">Contactos</span>
              <span className="text-[11px] text-text-tertiary tactile-tabular-nums">{filteredRecipients.length}</span>
            </div>
            <Input
              type="search"
              aria-label="Buscar contacto o IBAN"
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              placeholder="Buscar contacto o IBAN"
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
                No encontramos coincidencias.
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
            label="IBAN destino"
            value={iban}
            onChange={(e) => setIban(formatIban(e.target.value))}
            placeholder="ES00 0000 0000 0000 0000 0000"
            error={error}
            inputSize="lg"
            className="font-mono tracking-[0.06em]"
          />
          <Input
            label="Alias opcional"
            value={alias}
            onChange={(e) => setAlias(e.target.value.slice(0, 48))}
            placeholder="Nombre visible en revisión"
          />
          <div className="mt-auto flex items-center justify-between gap-2 pt-3 2xl:pt-4">
            <Button variant="secondary" leftIcon={<ArrowLeft size={16} />} onClick={() => setStep('amount')}>
              Atrás
            </Button>
            <Button variant="primary" rightIcon={<ArrowRight size={16} />} onClick={submit}>
              Revisar
            </Button>
          </div>
        </div>
      </div>
    </motion.div>
  )
}

function RecipientChip({ recipient, active, onClick }: { recipient: RecentRecipient; active: boolean; onClick: () => void }) {
  const label = recipient.alias ?? formatIbanShort(recipient.counterpart_iban)
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
        <span className="text-[11px] text-text-tertiary truncate">{formatIban(recipient.counterpart_iban)}</span>
      </span>
      <span className="text-[11px] font-semibold text-text-secondary tactile-tabular-nums">×{recipient.transfer_count}</span>
    </button>
  )
}

function ReviewStep({ account, canExecute, onExecute }: { account: Account | null; canExecute: boolean; onExecute: () => void }) {
  const amount = useTransferWizard((s) => s.amount)
  const memo = useTransferWizard((s) => s.memo)
  const recipientIban = useTransferWizard((s) => s.recipientIban)
  const recipientAlias = useTransferWizard((s) => s.recipientAlias)
  const expressMode = useTransferWizard((s) => s.expressMode)
  const correlationId = useTransferWizard((s) => s.correlationId)
  const setStep = useTransferWizard((s) => s.setStep)
  const large = Boolean(amount && isLargeTransfer(amount))

  return (
    <motion.div initial={{ opacity: 0, x: 8 }} animate={{ opacity: 1, x: 0 }} className="grid grid-cols-[minmax(0,1fr)_300px] gap-4 2xl:gap-5 pb-1">
      <div className="flex flex-col gap-4 2xl:gap-5">
        <StepHeader icon={<ReceiptText size={18} />} title="Revisa y firma" description="Comprueba los datos antes de autorizar el envío." />
        <div className="rounded-3xl border border-border-subtle bg-white/[0.035] p-4 2xl:p-5 flex flex-col gap-3 2xl:gap-4">
          <div className="flex items-start justify-between gap-3 border-b border-border-subtle pb-3">
            <span className="text-[11px] uppercase tracking-[0.14em] text-text-tertiary pt-0.5">Código de seguridad</span>
            <span className="text-xs font-mono text-text-tertiary text-right break-all">{correlationId ?? '—'}</span>
          </div>
          <ReviewRow label="Desde" value={account ? formatIbanMasked(account.iban) : '—'} />
          <ReviewRow label="Para" value={recipientAlias ?? (recipientIban ? formatIbanShort(recipientIban) : '—')} helper={recipientIban ? formatIban(recipientIban) : undefined} />
          <ReviewRow label="Importe" value={amount ? formatCurrency(amount / 100) : '—'} strong />
          <ReviewRow label="Concepto" value={memo.trim() || 'Sin concepto'} />
        </div>
        <div className="flex items-center justify-between gap-2 pb-1">
          <Button variant="secondary" leftIcon={<ArrowLeft size={16} />} onClick={() => setStep(expressMode ? 'recipient' : 'recipient')}>
            Editar destino
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
              <span className="text-sm font-semibold">Protección anti-duplicados</span>
            </div>
            <p className="text-xs text-text-tertiary leading-relaxed">Si la conexión se interrumpe, evitamos repetir el envío.</p>
          </CardContent>
        </Card>
      </div>
    </motion.div>
  )
}

function LargeTransferWarning({ amount }: { amount: number }) {
  return (
    <Card variant="elevated" padding="md" className="border-amber-300/20 bg-amber-300/[0.06]">
      <CardContent className="gap-3">
        <div className="flex items-center gap-2 text-amber-100">
          <AlertTriangle size={17} strokeWidth={2} />
          <span className="text-sm font-semibold">Confirmación reforzada</span>
        </div>
        <p className="text-xs text-amber-100/80 leading-relaxed">
          Vas a enviar {formatCurrency(amount / 100)}. Revisa el destino con calma antes de firmar.
        </p>
      </CardContent>
    </Card>
  )
}

function SecurityPanel() {
  return (
    <Card variant="elevated" padding="md" className="border-emerald-300/20 bg-emerald-300/[0.045]">
      <CardContent className="gap-3">
        <div className="flex items-center gap-2 text-emerald-100">
          <ShieldCheck size={17} strokeWidth={2} />
          <span className="text-sm font-semibold">Operación protegida</span>
        </div>
        <p className="text-xs text-emerald-100/75 leading-relaxed">Todo listo para confirmar con firma sostenida.</p>
      </CardContent>
    </Card>
  )
}

function HoldToConfirmButton({ disabled, onConfirm }: { disabled: boolean; onConfirm: () => void }) {
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
        {holding ? 'Mantén...' : 'Mantén para enviar'}
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
  const [pdfPending, setPdfPending] = useState(false)

  const handleDownloadReceiptPdf = async (): Promise<void> => {
    if (!receipt || pdfPending) return

    setPdfPending(true)
    try {
      const { downloadTransferReceiptPdf } = await import('./transfer/receipt-pdf')
      await downloadTransferReceiptPdf({
        receipt,
        recipientLabel: recipientAlias ?? (recipientIban ? formatIbanShort(recipientIban) : formatIbanShort(receipt.to_iban)),
        amountLabel: formatCurrency((amount ?? receipt.amount_minor) / 100),
        fromIbanMasked: formatIbanMasked(receipt.from_iban),
        toIbanMasked: formatIbanMasked(receipt.to_iban),
        timestampLabel: formatReceiptTime(receipt.committed_at_ms),
      })
      sfx.coin_clink()
      toast.success('Recibo PDF generado', receipt.transaction_id)
    } catch {
      toast.warning('No se pudo generar el PDF', 'Inténtalo de nuevo en unos segundos.')
    } finally {
      setPdfPending(false)
    }
  }

  if (pending) {
    return (
      <ResultShell tone="pending" icon={<Spinner size="lg" variant="brand" />} title="Enviando transferencia" description="Estamos verificando la operación." />
    )
  }

  if (error) {
    const code = 'code' in error ? String(error.code) : 'INTERNAL_ERROR'
    const message = getUserMessage(code)
    return (
      <ResultShell tone="error" icon={<AlertTriangle size={38} />} title={message.title} description={message.description}>
        <div className="flex justify-center gap-2">
          <Button variant="secondary" leftIcon={<ArrowLeft size={16} />} onClick={onBack}>Volver</Button>
          <Button variant="primary" onClick={onBack}>Revisar datos</Button>
        </div>
      </ResultShell>
    )
  }

  if (!receipt) {
    return <ResultShell tone="pending" icon={<Spinner size="lg" variant="brand" />} title="Preparando recibo" description="Un momento." />
  }

  return (
    <ResultShell
      tone="success"
      icon={<CheckCircle2 size={38} strokeWidth={1.8} />}
      title="Transferencia completada"
      description={`${formatCurrency((amount ?? receipt.amount_minor) / 100)} enviado a ${recipientAlias ?? (recipientIban ? formatIbanShort(recipientIban) : 'destinatario')}.`}
    >
      <div className="mx-auto w-full max-w-md rounded-3xl border border-border-subtle bg-white/[0.035] p-3.5 text-left">
        <ReceiptRow label="Recibo" value={receipt.transaction_id} mono />
        <ReceiptRow label="Código de seguridad" value={receipt.correlation_id} mono />
        <ReceiptRow label="Origen" value={formatIbanMasked(receipt.from_iban)} />
        <ReceiptRow label="Destino" value={formatIbanMasked(receipt.to_iban)} helper={recipientAlias ?? undefined} />
        <ReceiptRow label="Concepto" value={receipt.reason?.trim() || 'Sin concepto'} />
        <ReceiptRow label="Fecha" value={formatReceiptTime(receipt.committed_at_ms)} />
        <ReceiptRow label="Balance disponible" value={formatCurrency(receipt.available_balance_minor / 100)} />
        <ReceiptRow label="Estado" value="Confirmada" />
      </div>
      <div className="flex flex-wrap justify-center gap-2">
        <Button
          variant="secondary"
          leftIcon={pdfPending ? <Spinner size="sm" /> : <Download size={16} />}
          disabled={pdfPending}
          onClick={handleDownloadReceiptPdf}
        >
          {pdfPending ? 'Generando PDF' : 'Descargar PDF'}
        </Button>
        <Button variant="secondary" onClick={onNew}>Nueva transferencia</Button>
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
  const destinationLabel = recipientAlias ?? (recipientIban ? formatIbanShort(recipientIban) : 'Selecciona destino')
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
              'radial-gradient(circle at 84% 0%, oklch(1 0 0 / 0.08), transparent 34%), linear-gradient(180deg, oklch(0.085 0.014 40 / 0.86), oklch(0.035 0.008 35 / 0.92))',
          }}
        />
        <div className="relative h-full min-h-0 flex flex-col p-5 2xl:p-6">
          <div className="flex items-center justify-between shrink-0">
            <div className="flex items-center gap-2">
              <Sparkles size={16} className="text-white/72" />
              <CardTitle className="text-base text-white">Tu envío</CardTitle>
            </div>
            <span className="rounded-full px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.13em] text-white/68" style={{ background: 'oklch(1 0 0 / 0.10)' }}>
              Secure
            </span>
          </div>

          <div className="mt-5 rounded-[1.55rem] border border-white/10 bg-white/[0.045] px-4 py-4">
            <span className="block text-[11px] uppercase tracking-[0.14em] text-white/46">Importe</span>
            <span className="block text-3xl font-light tracking-[-0.055em] tactile-tabular-nums text-white">
              {amount ? formatCurrency(amount / 100) : '—'}
            </span>
          </div>

          <div className="mt-4 rounded-[1.55rem] border border-white/10 bg-white/[0.035] p-3.5">
            <span className="block text-[11px] uppercase tracking-[0.14em] text-white/46 mb-3">Destino</span>
            <div className="flex items-center gap-3">
              <BankAvatar name={destinationLabel} size="lg" />
              <span className="min-w-0 flex flex-col">
                <span className="text-sm font-semibold text-white truncate">{destinationLabel}</span>
                <span className="text-[11px] text-white/46 truncate">{recipientIban ? formatIban(recipientIban) : 'Pendiente de seleccionar'}</span>
              </span>
            </div>
          </div>

          <div className="mt-4 space-y-2">
            <RailCheck done={hasAmount} label="Importe elegido" />
            <RailCheck done={hasDestination} label="Destino verificado" />
            <RailCheck done={hasAmount && hasDestination} label="Listo para revisión" />
          </div>

          <div className="mt-auto pt-4 space-y-2">
            <Metric label="Origen" value={account ? formatIbanShort(account.iban) : '—'} />
            {memo.trim() ? <Metric label="Concepto" value={memo.trim()} /> : null}
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
          borderColor: done ? 'oklch(0.78 0.16 150 / 0.42)' : 'oklch(1 0 0 / 0.12)',
          background: done ? 'oklch(0.78 0.16 150 / 0.12)' : 'transparent',
          color: done ? 'oklch(0.84 0.12 150)' : 'oklch(1 0 0 / 0.36)',
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

function formatReceiptTime(timestampMs: number): string {
  return new Intl.DateTimeFormat('es-ES', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(timestampMs))
}

function formatIbanMasked(iban: string): string {
  const compact = normalizeIban(iban)
  if (compact.length < 8) return formatIbanShort(iban)
  return `${compact.slice(0, 4)} **** **** ${compact.slice(-4)}`
}

function formatIbanShort(iban: string): string {
  const compact = normalizeIban(iban)
  if (compact.length < 8) return iban
  return `${compact.slice(0, 4)}…${compact.slice(-4)}`
}

function normalizeRecipientSearch(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
}
