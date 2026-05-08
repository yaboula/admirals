import { useMemo, useState } from 'react'
import { motion } from 'motion/react'
import { Area, AreaChart, ResponsiveContainer } from 'recharts'
import { AlertTriangle, CalendarClock, CircleDollarSign, Fingerprint, Gauge, LockKeyhole, Orbit, ShieldCheck, type LucideIcon } from 'lucide-react'
import { useLoanInstallmentsQuery, useLoanListQuery } from '@/data/queries'
import type { Loan, LoanInstallment } from '@/data/contracts'
import { Badge, Spinner } from '@/components/ui'
import { useI18n } from '@/lib/i18n'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { usePrivacyMode } from '@/stores/privacy'

export function Loans() {
  const { t, money, number, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const loansQuery = useLoanListQuery()
  const loans: Loan[] = loansQuery.data?.items ?? []
  const [selectedLoanId, setSelectedLoanId] = useState<string | null>(null)
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

  return (
    <main className="relative h-full min-h-0 overflow-y-auto bg-surface-abyss px-5 py-4 lg:px-6 scrollbar-thin">
      <div aria-hidden className="pointer-events-none fixed inset-0 opacity-60">
        <div className="absolute left-[10%] top-[8%] h-80 w-80 rounded-full bg-semantic-info-deep/10 blur-[105px]" />
        <div className="absolute bottom-[8%] right-[12%] h-72 w-72 rounded-full bg-semantic-success-deep/10 blur-[100px]" />
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(255,255,255,0.055)_1px,transparent_1px)] bg-[size:28px_28px] [mask-image:linear-gradient(90deg,transparent,black_18%,black_82%,transparent)]" />
      </div>

      <div className="relative mx-auto flex w-full max-w-[1220px] flex-col gap-4 pb-6">
        <motion.section initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28 }} className="relative overflow-hidden rounded-[2.25rem] border border-white/10 bg-[radial-gradient(circle_at_82%_30%,oklch(0.70_0.14_230/0.18),transparent_32%),radial-gradient(circle_at_18%_18%,oklch(0.65_0.18_155/0.14),transparent_34%),linear-gradient(135deg,oklch(0.09_0.012_270/0.92),oklch(0.025_0_0/0.98))] p-5 shadow-[0_28px_90px_rgba(0,0,0,0.48)] md:p-6">
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
                <Badge tone="info" variant="soft" leftIcon={<ShieldCheck size={12} strokeWidth={2.2} />}>{t('loans.nonExecutable')}</Badge>
              </div>
              <div className="grid gap-2 p-3">
                {loans.map((loan) => (
                  <LoanRow key={loan.loan_id} loan={loan} selected={selectedLoan?.loan_id === loan.loan_id} onSelect={() => setSelectedLoanId(loan.loan_id)} />
                ))}
              </div>
            </div>

            <aside className="grid gap-4">
              <div className="overflow-hidden rounded-[2rem] border border-white/10 bg-[radial-gradient(circle_at_50%_0%,oklch(0.70_0.14_230/0.13),transparent_46%),rgba(255,255,255,0.035)]">
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
    </main>
  )
}

function CreditLens({ loan, streamerMode }: { loan: Loan | null; streamerMode: boolean }) {
  const { t, money, number } = useI18n()
  const progress = loan ? loan.paid_installments / Math.max(1, loan.total_installments) : 0
  const radius = 86
  const circumference = 2 * Math.PI * radius
  return (
    <div className="relative flex min-h-[288px] items-center justify-center">
      <div className="absolute h-72 w-72 rounded-full border border-white/10 bg-[conic-gradient(from_180deg,oklch(0.70_0.14_230/0.28),oklch(0.65_0.18_155/0.22),transparent,oklch(0.70_0.14_230/0.28))] p-[1px] shadow-[0_0_70px_rgba(60,140,255,0.08)]"><div className="h-full w-full rounded-full bg-black/[0.82]" /></div>
      <svg viewBox="0 0 220 220" className="absolute h-60 w-60 -rotate-90">
        <circle cx="110" cy="110" r={radius} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth="10" />
        <circle cx="110" cy="110" r={radius} fill="none" stroke="oklch(0.70 0.14 230)" strokeWidth="10" strokeLinecap="round" strokeDasharray={circumference} strokeDashoffset={circumference * (1 - progress)} />
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

function LoanRow({ loan, selected, onSelect }: { loan: Loan; selected: boolean; onSelect: () => void }) {
  const { t, money, number, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const progress = loan.paid_installments / Math.max(1, loan.total_installments) * 100
  return (
    <button type="button" onClick={onSelect} className={cn('grid grid-cols-[minmax(0,1fr)_150px_132px_92px] items-center gap-3 rounded-[1.35rem] border px-4 py-3 text-left transition-colors max-lg:grid-cols-[minmax(0,1fr)_112px_82px]', selected ? 'border-white/18 bg-white/[0.075]' : 'border-white/10 bg-black/25 hover:bg-white/[0.045]')}>
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
    </button>
  )
}

function RepaymentCurve({ loan }: { loan: Loan | null }) {
  const data = useMemo(() => buildRepaymentCurve(loan), [loan])
  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart data={data} margin={{ top: 10, right: 8, bottom: 0, left: 0 }}>
        <defs>
          <linearGradient id="loan-repayment-fill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="oklch(0.70 0.14 230)" stopOpacity={0.34} />
            <stop offset="100%" stopColor="oklch(0.70 0.14 230)" stopOpacity={0} />
          </linearGradient>
        </defs>
        <Area type="monotone" dataKey="outstanding" stroke="oklch(0.70 0.14 230)" strokeWidth={2.4} fill="url(#loan-repayment-fill)" dot={false} activeDot={false} isAnimationActive />
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
