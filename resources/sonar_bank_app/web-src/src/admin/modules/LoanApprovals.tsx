import { useState } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import { Check, X, FileText, ShieldCheck } from 'lucide-react'
import { useBootstrap, useLoanListQuery } from '@/data/queries'
import { useApproveLoanMutation, useRejectLoanMutation } from '@/data/mutations'
import { Button, Badge, Input, Spinner } from '@/components/ui'
import { useI18n } from '@/lib/i18n'
import { cn } from '@/lib/utils'
import { toast } from '@/stores/toast'

export function LoanApprovals() {
  const loansQuery = useLoanListQuery()
  const bootstrapQuery = useBootstrap()
  const loans = loansQuery.data?.items ?? []
  const pendingLoans = loans.filter((loan) => loan.status === 'pending')
  const [selectedLoanId, setSelectedLoanId] = useState<string | null>(null)
  const [decisionOpen, setDecisionOpen] = useState(false)
  const [decision, setDecision] = useState<'approved' | 'rejected' | 'written_off'>('approved')
  const [reason, setReason] = useState('')
  const [accountHistoryOpen, setAccountHistoryOpen] = useState(false)
  const approveMutation = useApproveLoanMutation()
  const rejectMutation = useRejectLoanMutation()

  const selectedLoan = pendingLoans.find((loan) => loan.loan_id === selectedLoanId)
  const borrowerAccounts = selectedLoan ? bootstrapQuery.data?.accounts.filter((acc) => acc.owner_citizen_id === selectedLoan.borrower_citizen_id) ?? [] : []
  // Auto-select the borrower's personal account (first active account)
  const autoDepositIban = selectedLoan?.deposit_iban ?? borrowerAccounts.find((acc) => acc.status === 'active')?.iban ?? borrowerAccounts[0]?.iban ?? ''
  // Get transactions for the borrower's account
  const borrowerTransactions = bootstrapQuery.data?.recent_transactions.filter(
    (tx) => (tx.from_iban === autoDepositIban || tx.to_iban === autoDepositIban)
  ) ?? []

  const handleApprove = async () => {
    if (!selectedLoan || !autoDepositIban) return
    try {
      await approveMutation.mutateAsync({
        loan_id: selectedLoan.loan_id,
        deposit_iban: autoDepositIban,
        reason: reason || undefined,
      })
      setDecisionOpen(false)
      setDecision('approved')
      setReason('')
      setSelectedLoanId(null)
      toast.success('Loan approved', `Loan ${selectedLoan.product_name} approved and disbursed to ${autoDepositIban}`)
    } catch {
      toast.warning('Approval failed', 'Check the loan status, IBAN, and try again')
    }
  }

  const handleReject = async () => {
    if (!selectedLoan) return
    try {
      await rejectMutation.mutateAsync({
        loan_id: selectedLoan.loan_id,
        reason: reason || undefined,
      })
      setDecisionOpen(false)
      setDecision('approved')
      setReason('')
      setSelectedLoanId(null)
      toast.success('Loan rejected', `Loan ${selectedLoan.product_name} was rejected`)
    } catch {
      toast.warning('Rejection failed', 'Check the loan status and try again')
    }
  }

  const handleDecision = async () => {
    if (!decision || !selectedLoan) return
    if (decision === 'approved') {
      await handleApprove()
    } else if (decision === 'rejected') {
      await handleReject()
    }
  }

  const openDecision = (d: 'approved' | 'rejected' | 'written_off') => {
    setDecision(d)
    setDecisionOpen(true)
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h2 className="text-2xl font-semibold text-text-primary">Pending Loan Applications</h2>
        <p className="mt-1 text-sm text-text-secondary">
          {pendingLoans.length} application{pendingLoans.length !== 1 ? 's' : ''} awaiting review
        </p>
      </div>

      {loansQuery.isLoading ? (
        <div className="flex min-h-[300px] items-center justify-center">
          <Spinner size="lg" />
        </div>
      ) : pendingLoans.length === 0 ? (
        <div className="flex min-h-[300px] flex-col items-center justify-center rounded-2xl border border-white/10 bg-white/[0.02]">
          <Check size={48} strokeWidth={1.5} className="text-semantic-success-deep" />
          <p className="mt-4 text-lg font-semibold text-text-primary">No pending applications</p>
          <p className="mt-1 text-sm text-text-secondary">All loan requests have been processed</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {pendingLoans.map((loan) => (
            <LoanApprovalCard
              key={loan.loan_id}
              loan={loan}
              selected={selectedLoanId === loan.loan_id}
              onSelect={() => setSelectedLoanId(loan.loan_id)}
              onOpenDecision={(d) => {
                setSelectedLoanId(loan.loan_id)
                openDecision(d)
              }}
            />
          ))}
        </div>
      )}

      <AnimatePresence>
        {decisionOpen && selectedLoan && (
          <DecisionDialog
            loan={selectedLoan}
            decision={decision}
            reason={reason}
            depositIban={autoDepositIban}
            borrowerAccounts={borrowerAccounts}
            borrowerTransactions={borrowerTransactions}
            onReasonChange={setReason}
            onViewHistory={() => setAccountHistoryOpen(true)}
            onConfirm={handleDecision}
            onCancel={() => {
              setDecisionOpen(false)
              setDecision('approved')
              setReason('')
            }}
            loading={approveMutation.isPending || rejectMutation.isPending}
          />
        )}
        {accountHistoryOpen && selectedLoan && (
          <AccountHistoryDialog
            loan={selectedLoan}
            depositIban={autoDepositIban}
            transactions={borrowerTransactions}
            onClose={() => setAccountHistoryOpen(false)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}

function LoanApprovalCard({
  loan,
  selected,
  onSelect,
  onOpenDecision,
}: {
  loan: any
  selected: boolean
  onSelect: () => void
  onOpenDecision: (decision: 'approved' | 'rejected' | 'written_off') => void
}) {
  const { money, number, dateTime } = useI18n()
  const riskGrade = loan.risk_grade || 'B'

  // Calculate loan payment details
  const principal = loan.principal_minor
  const termDays = loan.term_days || 30
  const baseRate = calculateRateByTerm(loan.interest_bps, termDays)
  const monthlyRate = baseRate / 100 / 12
  const months = Math.ceil(termDays / 30)
  const monthlyPayment = months > 0 && monthlyRate > 0
    ? principal * (monthlyRate * Math.pow(1 + monthlyRate, months)) / (Math.pow(1 + monthlyRate, months) - 1)
    : principal / months
  const totalCost = monthlyPayment * months

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
      onClick={onSelect}
      className={cn(
        'flex flex-col gap-3 rounded-2xl border p-4 text-left transition-all cursor-pointer',
        selected ? 'border-white/18 bg-[radial-gradient(circle_at_0%_0%,rgba(246,75,0,0.08),transparent_50%),rgba(255,255,255,0.055)]' : 'border-white/10 bg-white/[0.02] hover:bg-white/[0.045]'
      )}
    >
      <div className="grid grid-cols-[minmax(0,1.5fr)_repeat(5,minmax(0,100px))] items-center gap-3">
        <div className="min-w-0">
          <div className="flex items-center gap-2">
            <p className="truncate text-base font-semibold text-text-primary">{loan.product_name}</p>
            <Badge tone={riskGrade === 'A' ? 'success' : riskGrade === 'B' ? 'warning' : 'danger'} variant="soft" size="xs">
              Grade {riskGrade}
            </Badge>
          </div>
          <p className="mt-1 truncate text-sm text-text-tertiary">
            {loan.purpose} · {loan.collateral_label || 'Unsecured'}
          </p>
          <p className="mt-1 text-xs text-text-tertiary">
            Applied {dateTime(loan.created_ms, { month: 'short', day: 'numeric', year: 'numeric' })}
          </p>
        </div>

        <div className="text-right">
          <p className="text-sm font-semibold text-text-primary tactile-tabular-nums">{money(loan.principal_minor / 100)}</p>
          <p className="mt-1 text-[10px] text-text-tertiary">Principal</p>
        </div>

        <div className="text-right">
          <p className="text-sm font-semibold text-text-primary tactile-tabular-nums">{number(baseRate / 100, { maximumFractionDigits: 2 })}%</p>
          <p className="mt-1 text-[10px] text-text-tertiary">Rate</p>
        </div>

        <div className="text-right">
          <p className="text-sm font-semibold text-text-primary tactile-tabular-nums">{loan.term_days}d</p>
          <p className="mt-1 text-[10px] text-text-tertiary">Term</p>
        </div>

        <div className="text-right">
          <p className="text-sm font-semibold text-text-primary tactile-tabular-nums">{money(monthlyPayment / 100)}</p>
          <p className="mt-1 text-[10px] text-text-tertiary">Monthly</p>
        </div>

        <div className="text-right">
          <p className="text-sm font-semibold text-text-primary tactile-tabular-nums">{money(totalCost / 100)}</p>
          <p className="mt-1 text-[10px] text-text-tertiary">Total</p>
        </div>
      </div>

      <div className="flex items-center justify-end gap-2 pt-2 border-t" style={{ borderColor: 'rgba(255,255,255,0.08)' }}>
        <Button
          size="sm"
          variant="secondary"
          leftIcon={<Check size={14} />}
          onClick={(e) => {
            e.stopPropagation()
            onOpenDecision('approved')
          }}
        />
        <Button
          size="sm"
          variant="secondary"
          leftIcon={<X size={14} />}
          onClick={(e) => {
            e.stopPropagation()
            onOpenDecision('rejected')
          }}
        />
      </div>
    </motion.div>
  )
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

function AccountHistoryDialog({
  loan,
  depositIban,
  transactions,
  onClose,
}: {
  loan: any
  depositIban: string
  transactions: any[]
  onClose: () => void
}) {
  const { money, dateTime, t } = useI18n()

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4 backdrop-blur-md"
    >
      <motion.div
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
        transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        className="w-full max-w-2xl rounded-[1.65rem] border max-h-[80vh] flex flex-col"
        style={{
          background: 'var(--color-surface-card)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.05),0_36px_90px_-50px_rgba(0,0,0,0.95),0_0_0_1px_var(--color-border-brand-subtle)',
          borderColor: 'var(--color-border-subtle)',
        }}
      >
        <div className="flex items-center justify-between p-6 border-b" style={{ borderColor: 'var(--color-border-subtle)' }}>
          <div>
            <h3 className="text-xl font-semibold text-text-primary">Account History</h3>
            <p className="text-sm text-text-tertiary mt-1">
              {loan.borrower_citizen_id} · {depositIban}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full border text-text-tertiary transition-colors hover:text-text-primary"
            style={{
              borderColor: 'var(--color-border-subtle)',
              background: 'rgba(0,0,0,0.45)',
            }}
          >
            <X size={15} strokeWidth={2} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6">
          {transactions.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-text-tertiary">No transactions found for this account</p>
            </div>
          ) : (
            <div className="space-y-3">
              {transactions.map((tx) => (
                <div
                  key={tx.id || tx.created_ms}
                  className="flex items-center justify-between gap-4 rounded-xl border p-4"
                  style={{ borderColor: 'var(--color-border-subtle)', background: 'rgba(255,255,255,0.02)' }}
                >
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-text-primary truncate">{tx.description || tx.type || 'Transaction'}</p>
                    <p className="text-xs text-text-tertiary mt-1">
                      {tx.from_iban === depositIban ? `To: ${tx.to_iban || 'Unknown'}` : `From: ${tx.from_iban || 'Unknown'}`}
                    </p>
                    <p className="text-[10px] text-text-tertiary mt-1">
                      {tx.created_ms ? dateTime(tx.created_ms, { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : 'Unknown date'}
                    </p>
                  </div>
                  <div className="text-right">
                    <p
                      className={`text-sm font-semibold tactile-tabular-nums ${
                        tx.from_iban === depositIban ? 'text-text-primary' : 'text-semantic-success-deep'
                      }`}
                    >
                      {tx.from_iban === depositIban ? '-' : '+'}{money(tx.amount_minor / 100)}
                    </p>
                    <p className="text-xs text-text-tertiary mt-1">{tx.status || 'Unknown'}</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="p-6 border-t" style={{ borderColor: 'var(--color-border-subtle)' }}>
          <button
            type="button"
            onClick={onClose}
            className="w-full rounded-[1rem] px-5 py-3 text-[14px] font-semibold tracking-[-0.01em] transition-all duration-200"
            style={{
              background: 'rgba(0,0,0,0.45)',
              color: 'var(--color-text-tertiary)',
              border: '1px solid var(--color-border-subtle)',
            }}
          >
            {t('common.close') || 'Close'}
          </button>
        </div>
      </motion.div>
    </motion.div>
  )
}

function DecisionDialog({
  loan,
  decision,
  reason,
  depositIban,
  borrowerAccounts,
  borrowerTransactions,
  onReasonChange,
  onViewHistory,
  onConfirm,
  onCancel,
  loading,
}: {
  loan: any
  decision: 'approved' | 'rejected' | 'written_off'
  reason: string
  depositIban: string
  borrowerAccounts: any[]
  borrowerTransactions: any[]
  onReasonChange: (v: string) => void
  onViewHistory: () => void
  onConfirm: () => void
  onCancel: () => void
  loading: boolean
}) {
  const { money, number } = useI18n()
  
  // Calculate loan payment details
  const principal = loan.principal_minor
  const termDays = loan.term_days || 30
  const baseRate = calculateRateByTerm(loan.interest_bps, termDays)
  const monthlyRate = baseRate / 100 / 12
  const months = Math.ceil(termDays / 30)
  const monthlyPayment = months > 0 && monthlyRate > 0
    ? principal * (monthlyRate * Math.pow(1 + monthlyRate, months)) / (Math.pow(1 + monthlyRate, months) - 1)
    : principal / months
  const totalCost = monthlyPayment * months
  const totalInterest = totalCost - principal

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4 backdrop-blur-md"
    >
      <motion.div
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
        transition={{ type: 'spring', damping: 25, stiffness: 300 }}
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
              'radial-gradient(circle at 96% 0%, rgba(246,75,0,0.10), transparent 38%)',
          }}
        />

        <div className="relative grid gap-0 lg:grid-cols-[minmax(0,1.1fr)_minmax(380px,1fr)]">
          {/* ── HERO COLUMN ─────────────────────────────────────────── */}
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
                  {decision === 'approved' ? (
                    <Check size={13} strokeWidth={2} style={{ color: 'rgb(255, 147, 42)' }} />
                  ) : decision === 'rejected' ? (
                    <X size={13} strokeWidth={2} style={{ color: 'rgb(255, 147, 42)' }} />
                  ) : (
                    <FileText size={13} strokeWidth={2} style={{ color: 'rgb(255, 147, 42)' }} />
                  )}
                  <span
                    className="text-[9.5px] font-semibold uppercase tracking-[0.2em]"
                    style={{ color: 'rgb(255, 147, 42)' }}
                  >
                    {decision === 'approved' ? 'APPROVE LOAN' : decision === 'rejected' ? 'REJECT LOAN' : 'WRITE OFF LOAN'}
                  </span>
                </div>
                <h2 className="text-[22px] font-semibold leading-[1.05] tracking-[-0.045em] text-text-primary">
                  {decision === 'approved' ? 'Approve Credit Request' : decision === 'rejected' ? 'Reject Credit Request' : 'Write Off Credit'}
                </h2>
              </div>
              <button
                type="button"
                onClick={onCancel}
                aria-label="Cancel"
                className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full border text-text-tertiary transition-colors hover:text-text-primary"
                style={{
                  borderColor: 'var(--color-border-subtle)',
                  background: 'rgba(0,0,0,0.45)',
                }}
              >
                <X size={15} strokeWidth={2} />
              </button>
            </header>

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
                      <p className="text-sm font-semibold text-text-primary">{loan.product_name}</p>
                      <p className="mt-0.5 text-xs text-text-secondary">
                        {loan.purpose} · {loan.collateral_label || 'Unsecured'}
                      </p>
                    </div>
                    <div className="inline-flex items-center gap-1.5 rounded-full border border-white/[0.16] bg-black/30 px-2.5 py-1 text-[9px] font-semibold uppercase tracking-[0.18em] text-text-tertiary">
                      <ShieldCheck size={10} />
                      Verified
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-text-tertiary">Principal</p>
                      <p className="mt-1 text-[16px] font-bold tactile-tabular-nums" style={{ color: 'rgb(255, 147, 42)' }}>
                        {money(loan.principal_minor / 100)}
                      </p>
                    </div>
                    <div>
                      <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-text-tertiary">Term</p>
                      <p className="mt-1 text-[16px] font-bold text-text-primary tactile-tabular-nums">
                        {termDays} days
                      </p>
                    </div>
                  </div>
                  <div className="mt-4 pt-4 border-t" style={{ borderColor: 'rgba(255,255,255,0.08)' }}>
                    <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-text-tertiary mb-2">Rate</p>
                    <div className="flex items-center gap-2 text-[13px]">
                      <span className="font-semibold text-text-primary tactile-tabular-nums">{number(baseRate / 100, { maximumFractionDigits: 2 })}%</span>
                      <span className="text-text-tertiary">adjusted rate</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="rounded-[1.1rem] border p-4"
              style={{
                borderColor: 'var(--color-border-brand-subtle)',
                background:
                  'linear-gradient(135deg, rgba(246,75,0,0.10), rgba(246,75,0,0.02) 60%, rgba(0,0,0,0.55))',
                boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04)',
              }}
            >
              <span className="text-[10px] font-semibold uppercase tracking-[0.18em] text-text-secondary">
                Payment Summary
              </span>
              <div
                className="mt-1.5 text-[26px] font-bold leading-none tracking-[-0.04em] tactile-tabular-nums"
                style={{ color: 'rgb(255, 147, 42)' }}
              >
                {money(monthlyPayment / 100)}
                <span className="text-[13px] font-normal text-text-tertiary ml-1">/ month</span>
              </div>
              <div className="mt-2.5 space-y-1.5 text-[11px] tactile-tabular-nums">
                <div className="flex items-center justify-between">
                  <span className="text-text-tertiary">Total to Pay</span>
                  <span className="font-semibold text-text-primary">{money(totalCost / 100)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-text-tertiary">Total Interest</span>
                  <span className="font-semibold text-semantic-info-deep">{money(totalInterest / 100)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-text-tertiary">Installments</span>
                  <span className="font-semibold text-text-primary">{months} months</span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2.5">
              <div
                className="flex items-center justify-between gap-3 rounded-[0.95rem] border px-3 py-2"
                style={{ borderColor: 'var(--color-border-subtle)', background: 'rgba(255,255,255,0.02)' }}
              >
                <span className="text-xs text-text-tertiary">Borrower</span>
                <span className="text-xs font-semibold text-text-primary truncate">{loan.borrower_citizen_id || 'Unknown'}</span>
              </div>
              <div
                className="flex items-center justify-between gap-3 rounded-[0.95rem] border px-3 py-2"
                style={{ borderColor: 'var(--color-border-subtle)', background: 'rgba(255,255,255,0.02)' }}
              >
                <span className="text-xs text-text-tertiary">Applied</span>
                <span className="text-xs font-semibold text-text-primary tactile-tabular-nums">{new Date(loan.created_ms).toLocaleDateString()}</span>
              </div>
            </div>
          </section>

          {/* ── FLOW COLUMN ─────────────────────────────────────────── */}
          <section className="flex flex-col gap-4 p-6">
            {decision === 'approved' && (
              <>
                <div className="flex flex-col gap-2">
                  <label className="text-[11px] font-semibold uppercase tracking-[0.16em] text-text-secondary">
                    Disbursement Account (Auto-selected)
                  </label>
                  <div
                    className="flex items-center gap-3 rounded-[0.95rem] border px-3 py-2"
                    style={{ borderColor: 'var(--color-border-subtle)', background: 'rgba(255,255,255,0.02)' }}
                  >
                    <span className="text-xs font-semibold text-text-tertiary">IBAN</span>
                    <span className="text-xs font-mono text-text-primary">{depositIban || 'No account available'}</span>
                    {borrowerAccounts.length > 0 && (
                      <button
                        type="button"
                        onClick={onViewHistory}
                        className="ml-auto text-xs text-text-tertiary hover:text-text-primary transition-colors"
                      >
                        View History ({borrowerTransactions.length} transactions)
                      </button>
                    )}
                  </div>
                  {borrowerAccounts.length > 1 && (
                    <p className="text-[10px] text-text-tertiary">
                      Borrower has {borrowerAccounts.length} accounts. Personal account auto-selected.
                    </p>
                  )}
                </div>
              </>
            )}

            <div className="flex flex-col gap-2">
              <label className="text-[11px] font-semibold uppercase tracking-[0.16em] text-text-secondary">
                Reason (optional)
              </label>
              <Input
                value={reason}
                onChange={(e) => onReasonChange(e.currentTarget.value)}
                placeholder="Add a note explaining your decision"
              />
            </div>

            <div className="mt-auto space-y-2">
              <button
                type="button"
                onClick={onConfirm}
                disabled={loading}
                className="group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-[1rem] px-5 py-3 text-[14px] font-bold tracking-[-0.01em] transition-all duration-200"
                style={{
                  background: decision === 'approved' ? 'var(--gradient-primary)' : decision === 'rejected' ? 'rgba(220,38,38,0.85)' : 'rgba(100,100,100,0.85)',
                  color: 'var(--color-text-primary)',
                  border: '1px solid',
                  borderColor: decision === 'approved' ? 'var(--color-border-brand-strong)' : decision === 'rejected' ? 'rgba(220,38,38,0.5)' : 'var(--color-border-subtle)',
                  boxShadow: decision === 'approved' ? '0 18px 40px -22px rgba(246,75,0,0.78), inset 0 1px 0 rgba(255,255,255,0.18)' : 'none',
                }}
              >
                {loading ? (
                  <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                ) : decision === 'approved' ? (
                  <Check size={15} strokeWidth={2} />
                ) : (
                  <X size={15} strokeWidth={2} />
                )}
                <span className="relative">
                  {loading ? 'Processing' : decision === 'approved' ? 'Confirm Approval' : decision === 'rejected' ? 'Confirm Rejection' : 'Confirm Write Off'}
                </span>
              </button>
              <button
                type="button"
                onClick={onCancel}
                disabled={loading}
                className="group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-[1rem] px-5 py-3 text-[14px] font-semibold tracking-[-0.01em] transition-all duration-200"
                style={{
                  background: 'rgba(0,0,0,0.45)',
                  color: 'var(--color-text-tertiary)',
                  border: '1px solid var(--color-border-subtle)',
                }}
              >
                <span className="relative">Cancel</span>
              </button>
            </div>
          </section>
        </div>
      </motion.div>
    </motion.div>
  )
}
