import { useQueryClient } from '@tanstack/react-query'
import { z } from 'zod'
import { queryKeys } from '@/data/queryKeys'
import type { BootstrapSnapshot, LoanListResponse, LoanPaymentResponse, LoanRequestResponse } from '@/data/contracts'
import { BankError } from '@/lib/bankError'
import { createBankOperationIds } from '@/lib/bankIdempotency'
import { useBankMutation } from '@/lib/bankQuery'

const LOAN_REQUEST_EVENT = 'sonar:bank:loan:request'
const LOAN_PAYMENT_EVENT = 'sonar:bank:loan:makePayment'
const LOAN_APPROVE_EVENT = 'sonar:bank:loan:approve'
const LOAN_REJECT_EVENT = 'sonar:bank:loan:reject'
const IBAN_RE = /^[A-Z]{2}[0-9A-Z\s-]{10,34}$/

export const loanRequestSchema = z.object({
  product_id: z.string().min(1),
  principal_minor: z.number().int().positive(),
  term_days: z.number().int().min(1).max(3_650),
  deposit_iban: z.string().trim().toUpperCase().regex(IBAN_RE, 'INVALID_IBAN'),
})

export const loanPaymentSchema = z.object({
  loan_id: z.string().uuid(),
  from_iban: z.string().trim().toUpperCase().regex(IBAN_RE, 'INVALID_IBAN'),
  amount_minor: z.number().int().positive(),
})

export const loanApproveSchema = z.object({
  loan_id: z.string().uuid(),
  deposit_iban: z.string().trim().toUpperCase().regex(IBAN_RE, 'INVALID_IBAN'),
  reason: z.string().optional(),
})

export const loanRejectSchema = z.object({
  loan_id: z.string().uuid(),
  reason: z.string().optional(),
})

export type LoanRequestArgs = z.input<typeof loanRequestSchema>
export type LoanPaymentArgs = z.input<typeof loanPaymentSchema>
export type LoanApproveArgs = z.input<typeof loanApproveSchema>
export type LoanRejectArgs = z.input<typeof loanRejectSchema>

type LoanPaymentContext = {
  previousLoans?: LoanListResponse
  previousBootstrap?: BootstrapSnapshot
}

function validationError(message: string, error: z.ZodError) {
  return new BankError({
    code: 'VALIDATION_FAILED',
    category: 'validation',
    message,
    retryable: false,
    details: { issues: error.flatten() },
  })
}

export function useRequestLoanMutation() {
  const qc = useQueryClient()
  const mutation = useBankMutation<LoanRequestResponse, LoanRequestArgs>(
    LOAN_REQUEST_EVENT,
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.loans.list() })
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
    { idempotency: createBankOperationIds },
  )

  return {
    ...mutation,
    mutateAsync: async (input: LoanRequestArgs) => {
      const parsed = loanRequestSchema.safeParse(input)
      if (!parsed.success) throw validationError('Loan request contains invalid fields', parsed.error)
      return mutation.mutateAsync(parsed.data)
    },
  }
}

export function useMakeLoanPaymentMutation() {
  const qc = useQueryClient()
  const mutation = useBankMutation<LoanPaymentResponse, LoanPaymentArgs, LoanPaymentContext>(
    LOAN_PAYMENT_EVENT,
    {
      onMutate: async (input) => {
        const parsed = loanPaymentSchema.safeParse(input)
        if (!parsed.success) return {}
        await Promise.all([
          qc.cancelQueries({ queryKey: queryKeys.loans.list() }),
          qc.cancelQueries({ queryKey: queryKeys.bootstrap() }),
        ])
        const previousLoans = qc.getQueryData<LoanListResponse>(queryKeys.loans.list())
        const previousBootstrap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
        const args = parsed.data
        if (previousLoans) {
          qc.setQueryData<LoanListResponse>(queryKeys.loans.list(), {
            ...previousLoans,
            items: previousLoans.items.map((loan) => loan.loan_id === args.loan_id
              ? { ...loan, outstanding_minor: Math.max(0, loan.outstanding_minor - args.amount_minor) }
              : loan,
            ),
          })
        }
        return { previousLoans, previousBootstrap }
      },
      onError: (_err, _input, context) => {
        if (context?.previousLoans) qc.setQueryData(queryKeys.loans.list(), context.previousLoans)
        if (context?.previousBootstrap) qc.setQueryData(queryKeys.bootstrap(), context.previousBootstrap)
      },
      onSuccess: (_data, variables) => {
        void qc.invalidateQueries({ queryKey: queryKeys.loans.list() })
        void qc.invalidateQueries({ queryKey: queryKeys.loans.installments(variables.loan_id) })
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
    { idempotency: createBankOperationIds },
  )

  return {
    ...mutation,
    mutateAsync: async (input: LoanPaymentArgs) => {
      const parsed = loanPaymentSchema.safeParse(input)
      if (!parsed.success) throw validationError('Loan payment contains invalid fields', parsed.error)
      return mutation.mutateAsync(parsed.data)
    },
  }
}

export function useApproveLoanMutation() {
  const qc = useQueryClient()
  const mutation = useBankMutation<unknown, LoanApproveArgs>(
    LOAN_APPROVE_EVENT,
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.loans.list() })
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
    { idempotency: createBankOperationIds },
  )

  return {
    ...mutation,
    mutateAsync: async (input: LoanApproveArgs) => {
      const parsed = loanApproveSchema.safeParse(input)
      if (!parsed.success) throw validationError('Loan approve contains invalid fields', parsed.error)
      return mutation.mutateAsync(parsed.data)
    },
  }
}

export function useRejectLoanMutation() {
  const qc = useQueryClient()
  const mutation = useBankMutation<unknown, LoanRejectArgs>(
    LOAN_REJECT_EVENT,
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.loans.list() })
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
    { idempotency: createBankOperationIds },
  )

  return {
    ...mutation,
    mutateAsync: async (input: LoanRejectArgs) => {
      const parsed = loanRejectSchema.safeParse(input)
      if (!parsed.success) throw validationError('Loan reject contains invalid fields', parsed.error)
      return mutation.mutateAsync(parsed.data)
    },
  }
}
