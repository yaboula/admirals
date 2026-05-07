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
  LockKeyhole,
  ReceiptText,
  Search,
  SendHorizontal,
  ShieldCheck,
  Sparkles,
  UserRound,
  Zap,
} from 'lucide-react'
import { Button, Card, CardContent, CardDescription, CardEyebrow, CardTitle, Input, Spinner } from '@/components/ui'
import { useExecuteTransfer, formatIban, isLargeTransfer, isValidSpanishIban, normalizeIban } from '@/data/mutations'
import type { TransferReceipt } from '@/data/mutations'
import { useBootstrap, useRecentRecipients } from '@/data/queries'
import type { Account, RecentRecipient } from '@/data/contracts'
import { getUserMessage } from '@/lib/bankError'
import { sfx } from '@/lib/sfx'
import { cn, formatCurrency } from '@/lib/utils'
import { getMockInitialsForIban } from '@/data/mock/seed'
import { toast } from '@/stores/toast'
import { useTransferWizard, type TransferWizardStep } from '@/stores/transferWizard'

const STEPS: Array<{ id: TransferWizardStep; label: string; helper: string }> = [
  { id: 'amount', label: 'Amount', helper: 'Importe' },
  { id: 'recipient', label: 'Recipient', helper: 'Destino' },
  { id: 'review', label: 'Review', helper: 'Firma' },
  { id: 'confirm', label: 'Confirm', helper: 'Recibo' },
]

const EXPRESS_STEPS: TransferWizardStep[] = ['review', 'confirm']
const HOLD_TO_CONFIRM_MS = 1500

export function Transfer() {
  const navigate = useNavigate()
  const reduced = useReducedMotion()
  const { data } = useBootstrap()
  const primaryAccount = data?.accounts[0] ?? null
  const executeTransfer = useExecuteTransfer()
  const [receipt, setReceipt] = useState<TransferReceipt | null>(null)

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

  const visibleSteps = expressMode ? STEPS.filter((s) => EXPRESS_STEPS.includes(s.id)) : STEPS
  const isReviewStep = step === 'review'

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
    } catch (err) {
      const code = err && typeof err === 'object' && 'code' in err ? String(err.code) : 'INTERNAL_ERROR'
      const message = getUserMessage(code)
      toast.danger(message.title, message.description)
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
          isReviewStep
            ? 'max-w-[1080px] grid-cols-1'
            : 'max-w-[1400px] grid-cols-[minmax(0,1fr)_320px] gap-4 2xl:gap-5',
        )}
      >
        <section className="min-h-0 flex flex-col gap-4">
          <TransferHero expressMode={expressMode} account={primaryAccount} />
          <Card variant="glass" padding="lg" className="min-h-0 flex-1 border-white/10 overflow-hidden">
            <div className="h-full min-h-0 grid grid-rows-[auto_1fr] gap-5">
              <TransferStepper step={step} steps={visibleSteps} />
              <div className="min-h-0 overflow-y-auto pr-1 scrollbar-thin">
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
        {!isReviewStep ? (
          <TransferRail
            account={primaryAccount}
            amount={amount}
            memo={memo}
            recipientAlias={recipientAlias}
            recipientIban={recipientIban}
            expressMode={expressMode}
          />
        ) : null}
      </div>
    </motion.div>
  )
}

function TransferHero({ expressMode, account }: { expressMode: boolean; account: Account | null }) {
  return (
    <Card variant="glass" padding="lg" heroLight className="relative overflow-hidden border-white/10 shrink-0">
      <div className="flex items-start justify-between gap-4">
        <div className="flex flex-col gap-2">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              {expressMode ? <Zap size={12} strokeWidth={2.4} /> : <SendHorizontal size={12} strokeWidth={2.4} />}
              {expressMode ? 'EXPRESS TRANSFER' : 'TRANSFER WIZARD V3'}
            </span>
          </CardEyebrow>
          <div className="flex flex-col gap-1">
            <h1 className="text-3xl 2xl:text-4xl font-semibold tracking-[-0.045em] text-text-primary">Transferir dinero</h1>
            <p className="text-sm text-text-secondary max-w-[58ch] leading-relaxed">
              Envía fondos con validación local, aviso AR-P01 para importes altos y confirmación por presión sostenida.
            </p>
          </div>
        </div>
        <div className="shrink-0 rounded-2xl border border-border-subtle bg-white/[0.04] px-4 py-3 text-right">
          <span className="block text-[10px] uppercase tracking-[0.16em] text-text-tertiary">Saldo disponible</span>
          <span className="block text-xl font-semibold tactile-tabular-nums text-text-primary">
            {account ? formatCurrency(account.balance_minor / 100) : '—'}
          </span>
        </div>
      </div>
    </Card>
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
              'relative rounded-2xl border px-3 py-3 transition-colors',
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
                  'inline-flex h-7 w-7 items-center justify-center rounded-full border text-[11px] font-semibold tactile-tabular-nums',
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
    <motion.div initial={{ opacity: 0, x: 8 }} animate={{ opacity: 1, x: 0 }} className="grid grid-cols-[minmax(0,1fr)_280px] gap-5">
      <div className="flex flex-col gap-5">
        <StepHeader icon={<CircleDollarSign size={18} />} title="Elige el importe" description="Los importes se validan en céntimos y se comparan con tu saldo disponible antes de avanzar." />
        <div className="rounded-3xl border border-border-subtle bg-white/[0.035] p-5 flex flex-col gap-4">
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
        <div className="flex items-center justify-end gap-2">
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
    <div className="rounded-3xl border border-border-subtle bg-white/[0.03] p-4 flex flex-col gap-4 h-fit">
      <div className="flex items-center gap-2 text-text-secondary">
        <ShieldCheck size={16} strokeWidth={1.8} />
        <span className="text-sm font-semibold">Pre-check</span>
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
          AR-P01 se activará en revisión por importe alto.
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
  const [error, setError] = useState<string | null>(null)
  const normalized = normalizeIban(iban)

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
    <motion.div initial={{ opacity: 0, x: 8 }} animate={{ opacity: 1, x: 0 }} className="flex flex-col gap-5">
      <StepHeader icon={<UserRound size={18} />} title="Elige destinatario" description="Selecciona un contacto reciente o introduce un IBAN manualmente." />
      <div className="grid grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)] gap-5">
        <Card variant="elevated" padding="md" className="border-white/10 min-h-[360px]">
          <CardContent className="gap-3">
            <div className="flex items-center justify-between">
              <span className="text-sm font-semibold text-text-primary">Recientes</span>
              <Search size={15} className="text-text-tertiary" />
            </div>
            {isLoading ? (
              <div className="flex h-56 items-center justify-center text-text-tertiary">
                <Spinner size="sm" />
              </div>
            ) : (
              <div className="space-y-2">
                {(data?.recipients ?? []).slice(0, 7).map((recipient) => (
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
        <div className="rounded-3xl border border-border-subtle bg-white/[0.035] p-5 flex flex-col gap-4">
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
          <div className="mt-auto flex items-center justify-between gap-2 pt-4">
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
  const initials = recipient.alias
    ?.split(' ')
    .map((part) => part[0])
    .filter(Boolean)
    .slice(0, 2)
    .join('')
    .toUpperCase() ?? getMockInitialsForIban(recipient.counterpart_iban)

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
      <span className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-border-medium bg-white/[0.04] text-xs font-semibold">
        {initials || '··'}
      </span>
      <span className="min-w-0 flex-1 flex flex-col gap-0.5">
        <span className="text-sm font-semibold text-text-primary truncate">{recipient.alias ?? formatIbanShort(recipient.counterpart_iban)}</span>
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
    <motion.div initial={{ opacity: 0, x: 8 }} animate={{ opacity: 1, x: 0 }} className="grid grid-cols-[minmax(0,1fr)_300px] gap-5">
      <div className="flex flex-col gap-5">
        <StepHeader icon={<ReceiptText size={18} />} title="Revisa y firma" description="Comprueba cada dato antes de mantener pulsado para enviar." />
        <div className="rounded-3xl border border-border-subtle bg-white/[0.035] p-5 flex flex-col gap-4">
          <div className="flex items-start justify-between gap-3 border-b border-border-subtle pb-3">
            <span className="text-[11px] uppercase tracking-[0.14em] text-text-tertiary pt-0.5">Metadatos</span>
            <span className="text-xs font-mono text-text-tertiary text-right break-all">correlation_id · {correlationId ?? '—'}</span>
          </div>
          <ReviewRow label="Desde" value={account ? formatIbanMasked(account.iban) : '—'} />
          <ReviewRow label="Para" value={recipientAlias ?? (recipientIban ? formatIbanShort(recipientIban) : '—')} helper={recipientIban ? formatIban(recipientIban) : undefined} />
          <ReviewRow label="Importe" value={amount ? formatCurrency(amount / 100) : '—'} strong />
          <ReviewRow label="Concepto" value={memo.trim() || 'Sin concepto'} />
        </div>
        <div className="flex items-center justify-between gap-2">
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
              <span className="text-sm font-semibold">Idempotencia</span>
            </div>
            <p className="text-xs text-text-tertiary leading-relaxed">Cada intento usa una clave única para evitar duplicados en reintentos o latencia NUI.</p>
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
          <span className="text-sm font-semibold">AR-P01 · importe alto</span>
        </div>
        <p className="text-xs text-amber-100/80 leading-relaxed">
          Vas a enviar {formatCurrency(amount / 100)}. Mantén pulsado para confirmar conscientemente esta operación.
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
          <span className="text-sm font-semibold">Riesgo normal</span>
        </div>
        <p className="text-xs text-emerald-100/75 leading-relaxed">Importe dentro de umbral estándar. La firma sostenida sigue siendo obligatoria.</p>
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
  if (pending) {
    return (
      <ResultShell tone="pending" icon={<Spinner size="lg" variant="brand" />} title="Enviando transferencia" description="Aplicando operación optimista y esperando confirmación mock." />
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
      icon={<CheckCircle2 size={46} strokeWidth={1.8} />}
      title="Transferencia completada"
      description={`${formatCurrency((amount ?? receipt.amount_minor) / 100)} enviado a ${recipientAlias ?? (recipientIban ? formatIbanShort(recipientIban) : 'destinatario')}.`}
    >
      <div className="mx-auto w-full max-w-md rounded-3xl border border-border-subtle bg-white/[0.035] p-4 text-left space-y-3">
        <ReviewRow label="Recibo" value={receipt.transaction_id} />
        <ReviewRow label="Balance disponible" value={formatCurrency(receipt.available_balance_minor / 100)} />
        <ReviewRow label="Estado" value="Committed" />
      </div>
      <div className="flex justify-center gap-2">
        <Button variant="secondary" onClick={onNew}>Nueva transferencia</Button>
        <Button variant="primary" rightIcon={<ArrowRight size={16} />} onClick={onDone}>Volver a inicio</Button>
      </div>
    </ResultShell>
  )
}

function ResultShell({ tone, icon, title, description, children }: { tone: 'pending' | 'success' | 'error'; icon: React.ReactNode; title: string; description: string; children?: React.ReactNode }) {
  const toneClass = tone === 'success' ? 'text-emerald-100 border-emerald-300/20 bg-emerald-300/[0.055]' : tone === 'error' ? 'text-red-100 border-red-300/20 bg-red-300/[0.055]' : 'text-text-primary border-border-subtle bg-white/[0.035]'

  return (
    <div className="h-full min-h-[440px] flex items-center justify-center">
      <motion.div
        initial={{ opacity: 0, scale: 0.96, y: 10 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.36, ease: [0.16, 1, 0.3, 1] }}
        className="w-full max-w-xl text-center flex flex-col items-center gap-5"
      >
        <motion.div
          initial={{ scale: 0.82 }}
          animate={{ scale: tone === 'success' ? [0.86, 1.08, 1] : 1 }}
          transition={{ duration: 0.52, ease: [0.16, 1, 0.3, 1] }}
          className={cn('inline-flex h-24 w-24 items-center justify-center rounded-full border', toneClass)}
        >
          {icon}
        </motion.div>
        <div className="flex flex-col gap-2">
          <h2 className="text-3xl font-semibold tracking-[-0.04em] text-text-primary">{title}</h2>
          <p className="text-sm text-text-secondary leading-relaxed max-w-[52ch]">{description}</p>
        </div>
        {children}
      </motion.div>
    </div>
  )
}

function TransferRail({ account, amount, memo, recipientAlias, recipientIban, expressMode }: { account: Account | null; amount: number | null; memo: string; recipientAlias: string | null; recipientIban: string | null; expressMode: boolean }) {
  return (
    <aside className="min-h-0 flex flex-col gap-4">
      <Card variant="glass" padding="lg" className="border-white/10">
        <CardContent className="gap-4">
          <div className="flex items-center gap-2">
            <Sparkles size={16} className="text-text-secondary" />
            <CardTitle className="text-base">Resumen vivo</CardTitle>
          </div>
          <div className="space-y-3">
            <Metric label="Modo" value={expressMode ? 'Express · 2 pasos' : 'Wizard · 4 pasos'} />
            <Metric label="Origen" value={account ? formatIbanShort(account.iban) : '—'} />
            <Metric label="Destino" value={recipientAlias ?? (recipientIban ? formatIbanShort(recipientIban) : 'Pendiente')} />
            <Metric label="Importe" value={amount ? formatCurrency(amount / 100) : 'Pendiente'} />
            <Metric label="Concepto" value={memo.trim() || 'Sin concepto'} />
          </div>
        </CardContent>
      </Card>
      <Card variant="glass" padding="md" className="border-white/10">
        <CardContent className="gap-3">
          <div className="flex items-center gap-2 text-text-secondary">
            <LockKeyhole size={15} />
            <span className="text-sm font-semibold">Firma táctil</span>
          </div>
          <CardDescription className="text-xs">El envío final requiere presión sostenida. Esto reduce errores accidentales en tablet NUI.</CardDescription>
        </CardContent>
      </Card>
    </aside>
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

function ReviewRow({ label, value, helper, strong }: { label: string; value: string; helper?: string; strong?: boolean }) {
  return (
    <div className="flex items-start justify-between gap-4 border-b border-border-subtle pb-3 last:border-b-0 last:pb-0">
      <span className="text-[11px] uppercase tracking-[0.14em] text-text-tertiary pt-1">{label}</span>
      <span className="text-right flex flex-col gap-0.5 min-w-0">
        <span className={cn('text-text-primary break-all', strong ? 'text-2xl font-semibold tracking-[-0.04em] tactile-tabular-nums' : 'text-sm font-semibold')}>{value}</span>
        {helper ? <span className="text-[11px] text-text-tertiary font-mono tracking-[0.04em] break-all">{helper}</span> : null}
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
