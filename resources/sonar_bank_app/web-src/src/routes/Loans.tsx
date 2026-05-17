import { useMemo, useState, type ReactNode } from 'react'
import { motion } from 'motion/react'
import { Area, AreaChart, ResponsiveContainer } from 'recharts'
import { AlertTriangle, ArrowRight, CalendarClock, CircleDollarSign, Fingerprint, Gauge, LockKeyhole, Orbit, ShieldCheck, Sparkles, X, type LucideIcon } from 'lucide-react'
import { useBootstrap, useLoanInstallmentsQuery, useLoanListQuery, useLoanProductsQuery } from '@/data/queries'
import type { Loan, LoanInstallment, LoanProduct } from '@/data/contracts'
import { Badge, Button, Input, Select, Spinner } from '@/components/ui'
import { useI18n } from '@/lib/i18n'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { usePrivacyMode } from '@/stores/privacy'
import { useMakeLoanPaymentMutation, useRequestLoanMutation } from '@/data/mutations'
import { toast } from '@/stores/toast'

export function Loans() {
  const { t, money, number, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const loansQuery = useLoanListQuery()
  const bootstrapQuery = useBootstrap()
  const productsQuery = useLoanProductsQuery()
  const loans: Loan[] = loansQuery.data?.items ?? []
  const [selectedLoanId, setSelectedLoanId] = useState<string | null>(null)
  const [requestOpen, setRequestOpen] = useState(false)
  const [requestPrincipal, setRequestPrincipal] = useState('5000')
  const [requestProductId, setRequestProductId] = useState('personal')
  const [requestTermDays, setRequestTermDays] = useState('180')
  const [requestAccountIban, setRequestAccountIban] = useState('')
  const [paymentLoanId, setPaymentLoanId] = useState<string | null>(null)
  const [paymentAmount, setPaymentAmount] = useState('')
  const requestLoanMutation = useRequestLoanMutation()
  const loanPaymentMutation = useMakeLoanPaymentMutation()
  const selectedLoan = useMemo(() => {
    if (loans.length === 0) return null
    return loans.find((loan) => loan.loan_id === selectedLoanId) ?? loans.find((loan) => loan.status === 'active') ?? loans[0]
  }, [loans, selectedLoanId])
  const installmentsQuery = useLoanInstallmentsQuery(selectedLoan?.loan_id ?? null)
  const installments: LoanInstallment[] = installmentsQuery.data?.items ?? []
  const activeLoans = loans.filter((loan) => loan.status === 'active')
  const totalOutstanding = activeLoans.reduce((sum, loan) => sum + loan.outstanding_minor, 0)
  const totalPrincipal = loans.reduce((sum, loan) => sum + loan.principal_minor, 0)
  const weightedRate = activeLoans.length > 0 ? activeLoans.reduce((sum, loan) => sum + loan.interest_bps, 0) / activeLoans.length / 100 : 0
  const loading = loansQuery.isLoading
  const error = loansQuery.isError
  const primaryAccount = bootstrapQuery.data?.accounts.find((account) => account.status === 'active') ?? bootstrapQuery.data?.accounts[0] ?? null

  const submitLoanRequest = async () => {
    const principal_minor = Math.round(Number(requestPrincipal) * 100)
    const term_days = Math.round(Number(requestTermDays))
    const fallbackLoanAccount = bootstrapQuery.data?.accounts.find((account, index) => account.status === 'active' && (account.account_class === 'checking' || account.account_class === 'business_treasury' || (!account.account_class && index === 0)))
    const deposit_iban = requestAccountIban || fallbackLoanAccount?.iban || ''
    try {
      await requestLoanMutation.mutateAsync({ product_id: requestProductId, principal_minor, term_days, deposit_iban })
      setRequestOpen(false)
      setRequestAccountIban('')
      toast.success('Loan requested', 'Your credit request was submitted for review.')
    } catch {
      toast.warning('Loan request failed', 'Check the amount, product, term and account before retrying.')
    }
  }

  const openPayment = (loan: Loan) => {
    setPaymentLoanId(loan.loan_id)
    setPaymentAmount(String((loan.next_payment_minor || Math.min(loan.outstanding_minor, 100_00)) / 100))
  }

  const submitLoanPayment = async () => {
    if (!paymentLoanId || !primaryAccount) return
    const amount_minor = Math.round(Number(paymentAmount) * 100)
    try {
      await loanPaymentMutation.mutateAsync({ loan_id: paymentLoanId, from_iban: primaryAccount.iban, amount_minor })
      setPaymentLoanId(null)
      toast.success('Loan payment sent', 'The installment payment was submitted.')
    } catch {
      toast.warning('Loan payment failed', 'Check balance, loan status and amount before retrying.')
    }
  }

  return (
    <main className="relative h-full min-h-0 overflow-y-auto bg-surface-abyss px-5 py-4 lg:px-6 scrollbar-thin">
      <div aria-hidden className="pointer-events-none fixed inset-0 opacity-60">
        <div className="absolute left-[10%] top-[8%] h-80 w-80 rounded-full bg-semantic-info-deep/10" style={{ filter: 'blur(105px)' }} />
        <div className="absolute bottom-[8%] right-[12%] h-72 w-72 rounded-full bg-semantic-success-deep/10" style={{ filter: 'blur(100px)' }} />
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(255,255,255,0.055)_1px,transparent_1px)] bg-[size:28px_28px] [mask-image:linear-gradient(90deg,transparent,black_18%,black_82%,transparent)]" />
      </div>

      <div className="relative mx-auto flex w-full max-w-[1220px] flex-col gap-4 pb-6">
        <motion.section initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28 }} className="relative overflow-hidden rounded-[2.25rem] border border-white/10 bg-[radial-gradient(circle_at_82%_30%,rgba(0,173,228,0.18),transparent_32%),radial-gradient(circle_at_18%_18%,rgba(0,173,91,0.14),transparent_34%),linear-gradient(135deg,rgba(2,2,5,0.92),rgba(0,0,0,0.98))] p-5 shadow-[0_28px_90px_rgba(0,0,0,0.48)] md:p-6">
          <div className="absolute right-[-10%] top-[-30%] h-80 w-80 rounded-full border border-white/10" />
          <div className="absolute bottom-[-36%] left-[30%] h-96 w-96 rounded-full border border-semantic-info-deep/10" />
          <div className="relative grid min-h-[318px] gap-6 xl:grid-cols-[minmax(0,0.86fr)_330px_minmax(300px,0.78fr)]">
            <div className="flex min-w-0 flex-col justify-between gap-6">
              <div>
                <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.055] px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.18em] text-text-secondary">
                  <Fingerprint size={13} strokeWidth={2.2} />
                  {t('loans.eyebrow')}
                </div>
                <h1 className="mt-5 max-w-[11ch] text-5xl font-light leading-[0.9] tracking-[-0.085em] text-text-primary md:text-6xl">{t('loans.title')}</h1>
                <p className="mt-4 max-w-xl text-sm leading-relaxed text-text-secondary">{t('loans.description')}</p>
              </div>
              <div className="grid gap-2 sm:grid-cols-3">
                <SignalPill icon={LockKeyhole} label={t('loans.mode')} value={t('loans.readOnly')} />
                <SignalPill icon={Gauge} label={t('loans.weightedRate')} value={`${number(weightedRate, { maximumFractionDigits: 2 })}%`} />
                <SignalPill icon={CalendarClock} label={t('loans.nextDue')} value={selectedLoan?.next_payment_due_ms ? dateTime(selectedLoan.next_payment_due_ms, { month: 'short', day: 'numeric' }) : '—'} />
              </div>
            </div>

            <CreditLens loan={selectedLoan} streamerMode={streamerMode} />

            <div className="flex min-w-0 flex-col justify-between gap-4 rounded-[1.9rem] border border-white/10 bg-black/30 p-4 backdrop-blur-xl">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-text-tertiary">{t('loans.outstanding')}</p>
                <p className="mt-2 truncate text-4xl font-semibold tracking-[-0.06em] text-text-primary tactile-tabular-nums">{streamerMode ? maskMoneyDisplay() : money(totalOutstanding / 100)}</p>
                <p className="mt-3 text-xs leading-relaxed text-text-tertiary">{t('loans.outstandingDescription')}</p>
              </div>
              <div className="grid gap-2">
                <TerminalStat label={t('loans.totalPrincipal')} value={streamerMode ? maskMoneyDisplay() : money(totalPrincipal / 100)} />
                <TerminalStat label={t('loans.activeLoans')} value={number(activeLoans.length)} />
                <TerminalStat label={t('loans.totalLoans')} value={number(loans.length)} />
              </div>
            </div>
          </div>
        </motion.section>

        {loading ? (
          <div className="flex min-h-[420px] items-center justify-center rounded-[2rem] border border-white/10 bg-white/[0.035]">
            <div className="flex flex-col items-center gap-3 text-text-secondary">
              <Spinner size="md" />
              <span className="text-sm">{t('loans.loading')}</span>
            </div>
          </div>
        ) : error ? (
          <LoansEmpty icon={AlertTriangle} title={t('loans.errorTitle')} description={t('loans.errorDescription')} />
        ) : (
          <motion.section initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28, delay: 0.05 }} className="grid gap-4 xl:grid-cols-[minmax(0,1fr)_380px]">
            <div className="overflow-hidden rounded-[2rem] border border-white/10 bg-[linear-gradient(180deg,rgba(255,255,255,0.052),rgba(255,255,255,0.023))]">
              <div className="flex flex-wrap items-center justify-between gap-3 border-b border-white/10 px-5 py-4">
                <div>
                  <p className="text-sm font-semibold text-text-primary">{t('loans.creditStack')}</p>
                  <p className="mt-0.5 text-xs text-text-tertiary">{t('loans.creditStackDescription')}</p>
                </div>
                <Button size="sm" variant="secondary" leftIcon={<ShieldCheck size={12} strokeWidth={2.2} />} onClick={() => setRequestOpen(true)}>Solicitar prestamo</Button>
              </div>
              <div className="grid gap-2 p-3">
                {loans.map((loan) => (
                  <LoanRow key={loan.loan_id} loan={loan} selected={selectedLoan?.loan_id === loan.loan_id} onSelect={() => setSelectedLoanId(loan.loan_id)} onPay={() => openPayment(loan)} paymentPending={loanPaymentMutation.isPending && paymentLoanId === loan.loan_id} />
                ))}
              </div>
            </div>

            <aside className="grid gap-4">
              <div className="overflow-hidden rounded-[2rem] border border-white/10 bg-[radial-gradient(circle_at_50%_0%,rgba(0,173,228,0.13),transparent_46%),rgba(255,255,255,0.035)]">
                <div className="border-b border-white/10 px-5 py-4">
                  <p className="text-sm font-semibold text-text-primary">{t('loans.repaymentCurve')}</p>
                  <p className="mt-0.5 text-xs text-text-tertiary">{t('loans.repaymentCurveDescription')}</p>
                </div>
                <div className="h-[220px] p-4">
                  <RepaymentCurve loan={selectedLoan} />
                </div>
              </div>

              <div className="overflow-hidden rounded-[2rem] border border-white/10 bg-white/[0.035]">
                <div className="border-b border-white/10 px-5 py-4">
                  <p className="text-sm font-semibold text-text-primary">{t('loans.installments')}</p>
                  <p className="mt-0.5 text-xs text-text-tertiary">{selectedLoan?.product_name ?? t('loans.noSelection')}</p>
                </div>
                <div className="max-h-[330px] overflow-y-auto p-3 scrollbar-thin">
                  {installmentsQuery.isLoading ? (
                    <div className="flex min-h-[220px] items-center justify-center text-text-secondary"><Spinner size="sm" /></div>
                  ) : installments.length === 0 ? (
                    <LoansEmpty icon={CircleDollarSign} title={t('loans.noInstallmentsTitle')} description={t('loans.noInstallmentsDescription')} compact />
                  ) : (
                    <div className="space-y-2">
                      {installments.map((installment) => <InstallmentRow key={installment.installment_id} installment={installment} />)}
                    </div>
                  )}
                </div>
              </div>
            </aside>
          </motion.section>
        )}
      </div>
      {requestOpen ? (
        <LoanRequestDialog
          onClose={() => setRequestOpen(false)}
          products={productsQuery.data?.items ?? []}
          requestPrincipal={requestPrincipal}
          setRequestPrincipal={setRequestPrincipal}
          requestProductId={requestProductId}
          setRequestProductId={setRequestProductId}
          requestTermDays={requestTermDays}
          setRequestTermDays={setRequestTermDays}
          requestAccountIban={requestAccountIban}
          setRequestAccountIban={setRequestAccountIban}
          onSubmit={submitLoanRequest}
          loading={requestLoanMutation.isPending}
        />
      ) : null}
      {paymentLoanId ? (
        <LoanActionDialog title="Abonar cuota" onClose={() => setPaymentLoanId(null)}>
          <Input label="Cuenta origen" value={primaryAccount?.iban ?? ''} readOnly />
          <Input label="Importe" type="number" value={paymentAmount} onChange={(e) => setPaymentAmount(e.currentTarget.value)} leftAdornment="$" />
          <Button loading={loanPaymentMutation.isPending} disabled={!primaryAccount} onClick={submitLoanPayment}>Confirmar abono</Button>
        </LoanActionDialog>
      ) : null}
    </main>
  )
}

function LoanActionDialog({ title, children, onClose }: { title: string; children: ReactNode; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4 backdrop-blur-md">
      <div className="w-full max-w-md rounded-[1.75rem] border border-white/10 bg-surface-panel p-5 shadow-2xl">
        <div className="mb-4 flex items-center justify-between gap-3">
          <h2 className="text-lg font-semibold text-text-primary">{title}</h2>
          <Button size="sm" variant="ghost" leftIcon={<X size={15} />} onClick={onClose}>Cerrar</Button>
        </div>
        <div className="grid gap-3">{children}</div>
      </div>
    </div>
  )
}
function CreditLens({ loan, streamerMode }: { loan: Loan | null; streamerMode: boolean }) {
  const { t, money, number } = useI18n()
  const progress = loan ? loan.paid_installments / Math.max(1, loan.total_installments) : 0
  const radius = 86
  const circumference = 2 * Math.PI * radius
  return (
    <div className="relative flex min-h-[288px] items-center justify-center">
      <div className="absolute inset-0 m-auto h-72 w-72 rounded-full border border-white/10 bg-[conic-gradient(from_180deg,rgba(0,173,228,0.28),rgba(0,173,91,0.22),transparent,rgba(0,173,228,0.28))] p-[1px] shadow-[0_0_70px_rgba(60,140,255,0.08)]"><div className="h-full w-full rounded-full bg-black/[0.82]" /></div>
      <svg viewBox="0 0 220 220" className="absolute inset-0 m-auto h-60 w-60 -rotate-90">
        <circle cx="110" cy="110" r={radius} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth="10" />
        <circle cx="110" cy="110" r={radius} fill="none" stroke="rgb(0, 173, 228)" strokeWidth="10" strokeLinecap="round" strokeDasharray={circumference} strokeDashoffset={circumference * (1 - progress)} />
      </svg>
      <div className="relative z-[1] flex h-44 w-44 flex-col items-center justify-center rounded-full border border-white/15 bg-[radial-gradient(circle_at_50%_25%,rgba(255,255,255,0.14),rgba(255,255,255,0.025)_48%,rgba(0,0,0,0.74))] text-center shadow-[inset_0_1px_24px_rgba(255,255,255,0.08)]">
        <Orbit className="text-semantic-info-deep" size={28} strokeWidth={1.8} />
        <p className="mt-3 text-[10px] font-semibold uppercase tracking-[0.18em] text-text-tertiary">{t('loans.creditLens')}</p>
        <p className="mt-1 text-2xl font-semibold text-text-primary tactile-tabular-nums">{number(progress * 100, { maximumFractionDigits: 0 })}%</p>
        <p className="mt-1 max-w-[15ch] truncate text-xs text-text-tertiary">{loan ? streamerMode ? maskMoneyDisplay() : money(loan.outstanding_minor / 100) : '—'}</p>
      </div>
    </div>
  )
}

function LoanRow({ loan, selected, onSelect, onPay, paymentPending }: { loan: Loan; selected: boolean; onSelect: () => void; onPay: () => void; paymentPending: boolean }) {
  const { t, money, number, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const progress = loan.paid_installments / Math.max(1, loan.total_installments) * 100
  return (
    <div role="button" tabIndex={0} onClick={onSelect} className={cn('grid grid-cols-[minmax(0,1fr)_150px_132px_92px_94px] items-center gap-3 rounded-[1.35rem] border px-4 py-3 text-left transition-colors max-lg:grid-cols-[minmax(0,1fr)_112px_82px]', selected ? 'border-white/18 bg-white/[0.075]' : 'border-white/10 bg-black/25 hover:bg-white/[0.045]')}>
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <p className="truncate text-sm font-semibold text-text-primary">{loan.product_name}</p>
          <Badge tone={loan.status === 'active' ? 'success' : loan.status === 'paid' ? 'neutral' : loan.status === 'defaulted' ? 'danger' : 'warning'} variant="soft" size="xs">{t(`loans.status.${loan.status}`)}</Badge>
        </div>
        <p className="mt-1 truncate text-xs text-text-tertiary">{loan.purpose} · {loan.collateral_label ?? t('loans.unsecured')}</p>
      </div>
      <div className="max-lg:hidden">
        <p className="text-right text-sm font-semibold text-text-primary tactile-tabular-nums">{streamerMode ? maskMoneyDisplay() : money(loan.outstanding_minor / 100)}</p>
        <p className="mt-1 text-right text-xs text-text-tertiary">{t('loans.outstanding')}</p>
      </div>
      <div>
        <div className="h-2 overflow-hidden rounded-full bg-white/[0.07]"><div className="h-full rounded-full bg-semantic-info-deep" style={{ width: `${Math.min(100, progress)}%` }} /></div>
        <p className="mt-1 text-right text-xs text-text-tertiary">{number(loan.paid_installments)}/{number(loan.total_installments)}</p>
      </div>
      <div className="text-right">
        <p className="text-sm font-semibold text-text-primary">{number(loan.interest_bps / 100, { maximumFractionDigits: 2 })}%</p>
        <p className="mt-1 text-xs text-text-tertiary">{loan.next_payment_due_ms ? dateTime(loan.next_payment_due_ms, { month: 'short', day: 'numeric' }) : '—'}</p>
      </div>
      <Button size="sm" variant="secondary" loading={paymentPending} disabled={loan.status !== 'active'} onClick={(event) => { event.stopPropagation(); onPay() }}>Abonar</Button>
    </div>
  )
}

function RepaymentCurve({ loan }: { loan: Loan | null }) {
  const data = useMemo(() => buildRepaymentCurve(loan), [loan])
  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart data={data} margin={{ top: 10, right: 8, bottom: 0, left: 0 }}>
        <defs>
          <linearGradient id="loan-repayment-fill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="rgb(0, 173, 228)" stopOpacity={0.34} />
            <stop offset="100%" stopColor="rgb(0, 173, 228)" stopOpacity={0} />
          </linearGradient>
        </defs>
        <Area type="monotone" dataKey="outstanding" stroke="rgb(0, 173, 228)" strokeWidth={2.4} fill="url(#loan-repayment-fill)" dot={false} activeDot={false} isAnimationActive />
      </AreaChart>
    </ResponsiveContainer>
  )
}

function InstallmentRow({ installment }: { installment: LoanInstallment }) {
  const { t, money, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  return (
    <div className="grid grid-cols-[36px_minmax(0,1fr)_auto] items-center gap-3 rounded-[1.15rem] border border-white/10 bg-black/25 p-3">
      <span className="flex h-9 w-9 items-center justify-center rounded-full border border-white/10 bg-white/[0.035] text-xs font-semibold text-text-tertiary">{installment.sequence.toString().padStart(2, '0')}</span>
      <div className="min-w-0">
        <p className="truncate text-sm font-semibold text-text-primary">{dateTime(installment.due_ms, { month: 'short', day: 'numeric' })}</p>
        <p className="mt-1 truncate text-xs text-text-tertiary">{t(`loans.installment.${installment.status}`)}</p>
      </div>
      <p className="text-right text-sm font-semibold text-text-primary tactile-tabular-nums">{streamerMode ? maskMoneyDisplay() : money(installment.amount_minor / 100)}</p>
    </div>
  )
}

function SignalPill({ icon: Icon, label, value }: { icon: LucideIcon; label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-black/30 px-3 py-2 backdrop-blur-xl">
      <div className="flex items-center gap-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-text-tertiary"><Icon size={13} strokeWidth={2.1} />{label}</div>
      <p className="mt-1 truncate text-sm font-semibold text-text-primary tactile-tabular-nums">{value}</p>
    </div>
  )
}

function TerminalStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3 rounded-2xl border border-white/8 bg-white/[0.035] px-3 py-2">
      <span className="text-xs text-text-tertiary">{label}</span>
      <span className="text-sm font-semibold text-text-primary tactile-tabular-nums">{value}</span>
    </div>
  )
}

function LoansEmpty({ icon: Icon, title, description, compact }: { icon: LucideIcon; title: string; description: string; compact?: boolean }) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-3 p-6 text-center', compact ? 'min-h-[220px]' : 'min-h-[420px] rounded-[2rem] border border-white/10 bg-white/[0.035]')}>
      <span className="inline-flex h-14 w-14 items-center justify-center rounded-full border border-white/10 bg-white/[0.04] text-text-secondary"><Icon size={24} strokeWidth={1.8} /></span>
      <div className="flex max-w-[34ch] flex-col gap-1">
        <h2 className="text-base font-semibold text-text-primary">{title}</h2>
        <p className="text-sm leading-relaxed text-text-tertiary">{description}</p>
      </div>
    </div>
  )
}

function buildRepaymentCurve(loan: Loan | null) {
  if (!loan) return []
  const total = Math.max(1, loan.total_installments)
  return Array.from({ length: total + 1 }, (_, index) => {
    const progress = index / total
    const outstanding = loan.principal_minor * Math.pow(1 - progress, 1.08)
    return { index, outstanding }
  })
}

function LoanRequestDialog({
  onClose,
  products,
  requestPrincipal,
  setRequestPrincipal,
  requestProductId,
  setRequestProductId,
  requestTermDays,
  setRequestTermDays,
  requestAccountIban,
  setRequestAccountIban,
  onSubmit,
  loading,
}: {
  onClose: () => void
  products: LoanProduct[]
  requestPrincipal: string
  setRequestPrincipal: (v: string) => void
  requestProductId: string
  setRequestProductId: (v: string) => void
  requestTermDays: string
  setRequestTermDays: (v: string) => void
  requestAccountIban: string
  setRequestAccountIban: (v: string) => void
  onSubmit: () => void
  loading: boolean
}) {
  const { t, money, number } = useI18n()
  const bootstrapQuery = useBootstrap()
  const accounts = bootstrapQuery.data?.accounts.filter((acc, index) => acc.status === 'active' && (acc.account_class === 'checking' || acc.account_class === 'business_treasury' || (!acc.account_class && index === 0))) ?? []

  // Auto-select first account if none selected
  const selectedAccountIban = requestAccountIban || (accounts.length > 0 ? accounts[0].iban : '')

  const selectedProduct = products.find((p) => p.id === requestProductId)
  const principal = Number(requestPrincipal) * 100
  const termDays = Number(requestTermDays)

  // Calculate base rate based on term (shorter terms = lower rates)
  const baseRate = selectedProduct ? calculateRateByTerm(selectedProduct.base_rate_bps, termDays) : 0
  const monthlyRate = baseRate / 100 / 12
  const months = Math.ceil(termDays / 30)
  const monthlyPayment = months > 0 && monthlyRate > 0
    ? principal * (monthlyRate * Math.pow(1 + monthlyRate, months)) / (Math.pow(1 + monthlyRate, months) - 1)
    : principal / months
  const totalCost = monthlyPayment * months
  const totalInterest = totalCost - principal
  const isTermValid = !selectedProduct || (termDays > 0 && termDays <= selectedProduct.max_term_days)
  const isPrincipalValid = !selectedProduct || (principal >= selectedProduct.min_principal && principal <= selectedProduct.max_principal)
  const canSubmit = selectedProduct && principal > 0 && termDays > 0 && isTermValid && isPrincipalValid && selectedAccountIban

  // Generate term options based on product max_term_days
  const termOptions = selectedProduct ? generateTermOptions(selectedProduct.max_term_days) : []

  // Convert products to Select options
  const productOptions = products.map((p) => ({
    value: p.id,
    label: `${p.name} — ${number(p.base_rate_bps / 100, { maximumFractionDigits: 2 })}% ${t('loans.request.tae')}`,
  }))

  // Convert accounts to Select options
  const accountOptions = accounts.map((acc) => ({
    value: acc.iban,
    label: `${acc.account_class === 'business_treasury' ? 'Profesional' : 'Personal'} — ${acc.iban} - ${money(acc.balance_minor / 100)}`,
  }))

  // Convert term options to Select options
  const termSelectOptions = termOptions.map((term) => ({
    value: String(term),
    label: `${term} ${t('loans.request.days')}`,
  }))

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4 backdrop-blur-md">
      <div
        className="w-full max-w-4xl rounded-[1.65rem] border"
        style={{
          background: 'var(--color-surface-card)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.05),0_36px_90px_-50px_rgba(0,0,0,0.95),0_0_0_1px_var(--color-border-brand-subtle)',
          borderColor: 'var(--color-border-subtle)',
        }}
      >
        {/* Brand orange aura */}
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{ background: 'var(--gradient-orange-aura-strong)', opacity: 0.55 }}
        />
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{
            background:
              'radial-gradient(circle at 96% 0%, rgba(246,75,0,0.08), transparent 38%)',
          }}
        />

        <div className="relative grid gap-0 lg:grid-cols-[minmax(0,1.1fr)_minmax(380px,1fr)]">
          {/* ——— HERO COLUMN ———————————————————————————————————————————————————————— */}
          <section
            className="relative flex flex-col gap-4 border-b p-6 lg:border-b-0 lg:border-r lg:p-6"
            style={{ borderColor: 'var(--color-border-subtle)' }}
          >
            <header className="flex items-start justify-between gap-3">
              <div>
                <div
                  className="mb-2.5 inline-flex items-center gap-2 rounded-full border px-3 py-1.5"
                  style={{
                    borderColor: 'var(--color-border-brand-subtle)',
                    background: 'var(--color-brand-signal-orange-subtle)',
                  }}
                >
                  <CircleDollarSign size={13} strokeWidth={2} style={{ color: 'rgb(255, 147, 42)' }} />
                  <span
                    className="text-[9.5px] font-semibold uppercase tracking-[0.2em]"
                    style={{ color: 'rgb(255, 147, 42)' }}
                  >
                    {t('loans.request.eyebrow')}
                  </span>
                </div>
                <h2 className="text-[22px] font-semibold leading-[1.05] tracking-[-0.045em] text-text-primary">
                  {t('loans.request.title')}
                </h2>
              </div>
              <button
                type="button"
                onClick={onClose}
                aria-label={t('loans.request.close')}
                className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full border text-text-tertiary transition-colors hover:text-text-primary"
                style={{
                  borderColor: 'var(--color-border-subtle)',
                  background: 'rgba(0,0,0,0.45)',
                }}
              >
                <X size={15} strokeWidth={2} />
              </button>
            </header>

            {selectedProduct && (
              <>
                <div className="relative">
                  <div
                    aria-hidden
                    className="absolute inset-0 rounded-[1.5rem]"
                    style={{
                      background:
                        'radial-gradient(ellipse 80% 80% at 50% 38%, rgba(246,75,0,0.08), rgba(0,0,0,0.5) 70%)',
                      boxShadow: 'inset 0 0 0 1px var(--color-border-subtle)',
                    }}
                  />
                  <div className="relative flex flex-col gap-2.5 px-2 py-5">
                    <div className="rounded-[1.4rem] border bg-white/[0.02] p-6" style={{ borderColor: 'var(--color-border-subtle)' }}>
                      <div className="flex items-start justify-between mb-4">
                        <div>
                          <p className="text-sm font-semibold text-text-primary">{selectedProduct.name}</p>
                          <p className="mt-0.5 text-xs text-text-secondary">
                            {selectedProduct.collateral_required ? t('loans.request.collateralRequired') : t('loans.request.noCollateral')}
                          </p>
                        </div>
                        <div className="inline-flex items-center gap-1.5 rounded-full border border-white/[0.16] bg-black/30 px-2.5 py-1 text-[9px] font-semibold uppercase tracking-[0.18em] text-text-tertiary">
                          <ShieldCheck size={10} />
                          {t('loans.request.verified')}
                        </div>
                      </div>
                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-text-tertiary">{t('loans.request.baseRate')}</p>
                          <p className="mt-1 text-[16px] font-bold tactile-tabular-nums" style={{ color: 'rgb(255, 147, 42)' }}>
                            {number(selectedProduct.base_rate_bps / 100, { maximumFractionDigits: 2 })}%
                          </p>
                        </div>
                        <div>
                          <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-text-tertiary">{t('loans.request.maxTerm')}</p>
                          <p className="mt-1 text-[16px] font-bold text-text-primary tactile-tabular-nums">
                            {selectedProduct.max_term_days} {t('loans.request.days')}
                          </p>
                        </div>
                      </div>
                      <div className="mt-4 pt-4 border-t" style={{ borderColor: 'rgba(255,255,255,0.08)' }}>
                        <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-text-tertiary mb-2">{t('loans.request.amountRange')}</p>
                        <div className="flex items-center gap-2 text-[13px]">
                          <span className="font-semibold text-text-primary tactile-tabular-nums">{money(selectedProduct.min_principal / 100)}</span>
                          <ArrowRight size={12} className="text-text-quaternary" />
                          <span className="font-semibold text-text-primary tactile-tabular-nums">{money(selectedProduct.max_principal / 100)}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {canSubmit && (
                  <CostBlock
                    monthlyPayment={money(monthlyPayment / 100)}
                    totalCost={money(totalCost / 100)}
                    totalInterest={money(totalInterest / 100)}
                    months={months}
                  />
                )}

                <div className="grid grid-cols-2 gap-2.5">
                  <InfoRow
                    icon={<Gauge size={13} className="text-text-tertiary" strokeWidth={2} />}
                    label={t('loans.request.estimatedRate')}
                    value={`${number(baseRate / 100, { maximumFractionDigits: 2 })}%`}
                  />
                  <InfoRow
                    icon={<CalendarClock size={13} className="text-text-tertiary" strokeWidth={2} />}
                    label={t('loans.request.term')}
                    value={`${termDays} ${t('loans.request.days')}`}
                  />
                </div>
              </>
            )}
          </section>

          {/* ——— FLOW COLUMN ——————————————————————————————————————————————————————— */}
          <section className="flex flex-col gap-4 p-6">
            <Step number="01" label={t('loans.request.step01')} value={selectedProduct?.name}>
              <Select
                value={requestProductId}
                onChange={(value) => setRequestProductId(value)}
                selectSize="md"
                options={productOptions}
                placeholder={t('loans.request.selectProduct')}
              />
            </Step>

            <Step number="02" label={t('loans.request.step02')} value={principal > 0 ? money(principal / 100) : undefined}>
              <Input
                type="number"
                value={requestPrincipal}
                onChange={(e) => setRequestPrincipal(e.currentTarget.value)}
                leftAdornment="$"
                hint={selectedProduct ? `${money(selectedProduct.min_principal / 100)} - ${money(selectedProduct.max_principal / 100)}` : undefined}
                error={!isPrincipalValid ? t('loans.request.outOfRange') : undefined}
              />
            </Step>

            <Step number="03" label="Select Account" value={selectedAccountIban ? selectedAccountIban.substring(0, 8) + '...' : undefined}>
              <Select
                value={selectedAccountIban}
                onChange={(value) => setRequestAccountIban(value)}
                selectSize="md"
                options={accountOptions}
                placeholder="Select account"
              />
            </Step>

            <Step number="04" label="Term" value={termDays > 0 ? `${termDays} days` : undefined}>
              <Select
                value={requestTermDays}
                onChange={(value) => setRequestTermDays(value)}
                selectSize="md"
                options={termSelectOptions}
                placeholder={t('loans.request.enterTerm')}
              />
            </Step>

            <div className="mt-auto space-y-2">
              <button
                type="button"
                onClick={onSubmit}
                disabled={!canSubmit || loading}
                className="group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-[1rem] px-5 py-3 text-[14px] font-bold tracking-[-0.01em] transition-all duration-200"
                style={{
                  background: canSubmit ? 'var(--gradient-primary)' : 'rgba(0,0,0,0.55)',
                  color: canSubmit ? 'var(--color-text-primary)' : 'var(--color-text-tertiary)',
                  border: '1px solid',
                  borderColor: canSubmit ? 'var(--color-border-brand-strong)' : 'var(--color-border-subtle)',
                  boxShadow: canSubmit ? '0 18px 40px -22px rgba(246,75,0,0.78), inset 0 1px 0 rgba(255,255,255,0.18)' : 'none',
                }}
              >
                {canSubmit ? (
                  <span aria-hidden className="absolute inset-0 -translate-x-full bg-[linear-gradient(115deg,transparent_30%,rgba(255,255,255,0.22)_50%,transparent_70%)] transition-transform duration-700 group-hover:translate-x-full" />
                ) : null}
                {loading ? (
                  <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                ) : (
                  <Sparkles size={15} strokeWidth={2} />
                )}
                <span className="relative">
                  {loading ? t('loans.request.processing') : t('loans.request.submit')}
                </span>
                {!loading && canSubmit ? <ArrowRight size={14} strokeWidth={2.2} className="relative" /> : null}
              </button>
              {!canSubmit && !loading && (
                <p className="text-center text-[10.5px] leading-relaxed text-text-quaternary">
                  {t('loans.request.completeFields')}
                </p>
              )}
            </div>
          </section>
        </div>
      </div>
    </div>
  )
}

function generateTermOptions(maxTermDays: number): number[] {
  const options: number[] = []
  const step = maxTermDays >= 360 ? 90 : maxTermDays >= 180 ? 60 : 30

  for (let term = 30; term <= maxTermDays; term += step) {
    options.push(term)
  }

  // Always include the max_term_days as the last option
  if (options[options.length - 1] !== maxTermDays) {
    options.push(maxTermDays)
  }

  return options
}

// Calculate rate based on term: shorter terms get lower rates, longer terms get higher rates
function calculateRateByTerm(baseRateBps: number, termDays: number): number {
  if (termDays <= 0) return baseRateBps

  // Rate adjustment: -0.5% for 30 days, 0% for 60-90 days, +0.5% for 180 days, +1% for 360 days
  let adjustment = 0
  if (termDays <= 30) {
    adjustment = -50 // -0.5%
  } else if (termDays <= 90) {
    adjustment = 0 // base rate
  } else if (termDays <= 180) {
    adjustment = 50 // +0.5%
  } else {
    adjustment = 100 // +1%
  }

  return Math.max(100, baseRateBps + adjustment) // Minimum 1% rate
}

function Step({ number, label, value, children }: { number: string; label: string; value?: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-baseline justify-between gap-3">
        <div className="flex items-baseline gap-2.5">
          <span
            className="text-[10px] font-bold tracking-[0.18em]"
            style={{ color: 'rgb(255, 147, 42)', opacity: 0.85 }}
          >
            {number}
          </span>
          <span className="text-[11px] font-semibold uppercase tracking-[0.16em] text-text-secondary">{label}</span>
        </div>
        {value ? <span className="truncate text-[11px] font-medium text-text-tertiary">{value}</span> : null}
      </div>
      {children}
    </div>
  )
}

function CostBlock({
  monthlyPayment,
  totalCost,
  totalInterest,
  months,
}: {
  monthlyPayment: string
  totalCost: string
  totalInterest: string
  months: number
}) {
  const { t } = useI18n()

  return (
    <div
      className="relative overflow-hidden rounded-[1.1rem] border p-4"
      style={{
        borderColor: 'var(--color-border-brand-subtle)',
        background:
          'linear-gradient(135deg, rgba(246,75,0,0.10), rgba(246,75,0,0.02) 60%, rgba(0,0,0,0.55))',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04)',
      }}
    >
      <span className="text-[10px] font-semibold uppercase tracking-[0.18em] text-text-secondary">
        {t('loans.request.installments')}
      </span>
      <div
        className="mt-1.5 text-[26px] font-bold leading-none tracking-[-0.04em] tactile-tabular-nums"
        style={{ color: 'rgb(255, 147, 42)' }}
      >
        {monthlyPayment}
        <span className="text-[13px] font-normal text-text-tertiary ml-1">{t('loans.request.month')}</span>
      </div>
      <div className="mt-2.5 space-y-1.5 text-[11px] tactile-tabular-nums">
        <div className="flex items-center justify-between">
          <span className="text-text-tertiary">{t('loans.request.totalCost')}</span>
          <span className="font-semibold text-text-primary">{totalCost}</span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-text-tertiary">{t('loans.request.totalInterest')}</span>
          <span className="font-semibold text-text-semantic-info-deep">{totalInterest}</span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-text-tertiary">{t('loans.request.installments')}</span>
          <span className="font-semibold text-text-primary">{months} {t('loans.request.months')}</span>
        </div>
      </div>
    </div>
  )
}

function InfoRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div
      className="flex items-center justify-between gap-3 rounded-[0.95rem] border px-3 py-2"
      style={{
        borderColor: 'var(--color-border-subtle)',
        background: 'rgba(0,0,0,0.35)',
      }}
    >
      <div className="flex items-center gap-2">
        {icon}
        <span className="text-[10px] font-semibold uppercase tracking-[0.16em] text-text-tertiary">{label}</span>
      </div>
      <span className="text-[12px] font-semibold tactile-tabular-nums text-text-primary">
        {value}
      </span>
    </div>
  )
}
