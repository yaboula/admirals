import { useMutation, useQueryClient } from '@tanstack/react-query'
import { z } from 'zod'
import { queryKeys } from '@/data/queryKeys'
import type {
  BootstrapSnapshot,
  RecentRecipientsResponse,
} from '@/data/contracts'
import { BankError } from '@/lib/bankError'
import { bankMutation, useBankMutation } from '@/lib/bankQuery'

const SONAR_IBAN_RE = /^AD-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/
const LARGE_TRANSFER_MINOR = 1_000_00
const MAX_TRANSFER_MINOR = 250_000_00

export const transferExecuteSchema = z.object({
  from_iban: z.string().min(1),
  to_iban: z.string().transform(normalizeIban).pipe(z.string().regex(SONAR_IBAN_RE, 'INVALID_IBAN')),
  amount_minor: z.number().int().positive().max(MAX_TRANSFER_MINOR),
  reason: z.string().trim().max(140).nullable(),
  idempotency_key: z.string().uuid(),
  correlation_id: z.string().uuid(),
})

export type TransferExecuteArgsInput = z.input<typeof transferExecuteSchema>
export type TransferExecuteArgs = z.output<typeof transferExecuteSchema>

export interface TransferReceipt {
  transaction_id: string
  status: 'committed'
  from_iban: string
  to_iban: string
  amount_minor: number
  reason: string | null
  committed_at_ms: number
  available_balance_minor: number
  idempotency_key: string
  correlation_id: string
  large_transfer: boolean
}

interface TransferMutationContext {
  previousBootstrap?: BootstrapSnapshot
  previousRecentRecipients?: RecentRecipientsResponse
}

export function normalizeIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '').toUpperCase()
}

export function formatIban(value: string | undefined | null): string {
  // SONAR IBAN format: AD-XXXX-XXXX-XXXX (with dashes, not spaces)
  const normalized = normalizeIban(value)
  if (normalized.length === 17 && normalized.startsWith('AD-')) {
    return normalized // Already in SONAR format with dashes
  }
  // Fallback for other formats: insert dashes every 4 chars after prefix
  return normalized.replace(/(.{4})(?!$)/g, '$1-')
}

export function isValidSonarIban(value: string | undefined | null): boolean {
  return SONAR_IBAN_RE.test(normalizeIban(value))
}

export function isLargeTransfer(amountMinor: number): boolean {
  return amountMinor >= LARGE_TRANSFER_MINOR
}

export function transferTxnId(idempotencyKey: string): string {
  return `txn-xfer-${idempotencyKey.slice(0, 8)}`
}

export function useExecuteTransfer() {
  const qc = useQueryClient()

  const mutation = useBankMutation<TransferReceipt, TransferExecuteArgsInput, TransferMutationContext>(
    'sonar:bank:transfer:execute',
    {
      onMutate: async (input) => {
        const parsed = transferExecuteSchema.safeParse(input)
        if (!parsed.success) return {}

        const args = parsed.data
        await Promise.all([
          qc.cancelQueries({ queryKey: queryKeys.bootstrap() }),
          qc.cancelQueries({ queryKey: queryKeys.recipients.recent() }),
        ])

        const previousBootstrap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
        const previousRecentRecipients = qc.getQueryData<RecentRecipientsResponse>(queryKeys.recipients.recent())

        const fromIban = normalizeIban(args.from_iban)

        if (previousBootstrap) {
          qc.setQueryData<BootstrapSnapshot>(queryKeys.bootstrap(), {
            ...previousBootstrap,
            accounts: previousBootstrap.accounts.map((a) =>
              normalizeIban(a.iban) === fromIban
                ? { ...a, balance_minor: a.balance_minor - args.amount_minor }
                : a,
            ),
          })
        }

        return { previousBootstrap, previousRecentRecipients }
      },
      onError: (_err, _input, context) => {
        if (context?.previousBootstrap) {
          qc.setQueryData(queryKeys.bootstrap(), context.previousBootstrap)
        }
        if (context?.previousRecentRecipients) {
          qc.setQueryData(queryKeys.recipients.recent(), context.previousRecentRecipients)
        }
      },
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
        void qc.invalidateQueries({ queryKey: queryKeys.recipients.recent() })
      },
    },
  )

  return {
    ...mutation,
    mutateAsync: async (input: TransferExecuteArgsInput) => {
      const parsed = transferExecuteSchema.safeParse(input)
      if (!parsed.success) {
        throw new BankError({
          code: 'VALIDATION_FAILED',
          category: 'validation',
          message: 'La transferencia contiene campos no válidos',
          retryable: false,
          details: { issues: parsed.error.flatten() },
        })
      }

      const result = await mutation.mutateAsync(parsed.data)

      return {
        transaction_id: result.transaction_id,
        status: result.status || 'committed',
        from_iban: result.from_iban,
        to_iban: formatIban(result.to_iban),
        amount_minor: result.amount_minor,
        reason: parsed.data.reason,
        committed_at_ms: result.committed_at_ms || Date.now(),
        available_balance_minor: result.available_balance_minor,
        idempotency_key: parsed.data.idempotency_key,
        correlation_id: parsed.data.correlation_id,
        large_transfer: isLargeTransfer(parsed.data.amount_minor),
      }
    },
  }
}

export const savingsTransferSchema = z.object({
  iban: z.string().transform(normalizeIban).pipe(z.string().regex(SONAR_IBAN_RE, 'INVALID_IBAN')),
  amount_minor: z.number().int().positive().max(MAX_TRANSFER_MINOR),
  direction: z.enum(['to_savings', 'from_savings']),
  idempotency_key: z.string().uuid(),
  correlation_id: z.string().uuid(),
})

export type SavingsTransferArgsInput = z.input<typeof savingsTransferSchema>
export type SavingsTransferArgs = z.output<typeof savingsTransferSchema>

export interface SavingsTransferResponse {
  iban: string
  amount_minor: number
  direction: 'to_savings' | 'from_savings'
  committed_ms: number
}

interface SavingsTransferMutationContext {
  previousBootstrap?: BootstrapSnapshot
}

export function useSavingsTransferMutation() {
  const qc = useQueryClient()

  const mutation = useMutation<SavingsTransferResponse, BankError, SavingsTransferArgsInput, SavingsTransferMutationContext>({
    mutationFn: async (input) => {
      const parsed = savingsTransferSchema.safeParse(input)
      if (!parsed.success) {
        throw new BankError({
          code: 'VALIDATION_FAILED',
          category: 'validation',
          message: 'El movimiento de ahorro contiene campos no válidos',
          retryable: false,
          details: { issues: parsed.error.flatten() },
        })
      }
      const { direction, correlation_id: _correlationId, ...payload } = parsed.data
      const eventName = direction === 'to_savings' ? 'sonar:bank:transfer:toSavings' : 'sonar:bank:transfer:fromSavings'
      return bankMutation<typeof payload, SavingsTransferResponse>(eventName, payload)
    },
    retry: 0,
    onMutate: async (input) => {
      const parsed = savingsTransferSchema.safeParse(input)
      if (!parsed.success) return {}
      const args = parsed.data
      await qc.cancelQueries({ queryKey: queryKeys.bootstrap() })
      const previousBootstrap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
      if (previousBootstrap) {
        qc.setQueryData<BootstrapSnapshot>(queryKeys.bootstrap(), {
          ...previousBootstrap,
          accounts: previousBootstrap.accounts.map((account) => {
            if (normalizeIban(account.iban) !== args.iban) return account
            return args.direction === 'to_savings'
              ? { ...account, balance_minor: account.balance_minor - args.amount_minor, savings_minor: account.savings_minor + args.amount_minor }
              : { ...account, balance_minor: account.balance_minor + args.amount_minor, savings_minor: account.savings_minor - args.amount_minor }
          }),
        })
      }
      return { previousBootstrap }
    },
    onError: (_err, _input, context) => {
      if (context?.previousBootstrap) qc.setQueryData(queryKeys.bootstrap(), context.previousBootstrap)
    },
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
    },
  })

  return {
    ...mutation,
    mutateAsync: async (input: SavingsTransferArgsInput) => {
      const parsed = savingsTransferSchema.safeParse(input)
      if (!parsed.success) {
        throw new BankError({
          code: 'VALIDATION_FAILED',
          category: 'validation',
          message: 'El movimiento de ahorro contiene campos no válidos',
          retryable: false,
          details: { issues: parsed.error.flatten() },
        })
      }
      return mutation.mutateAsync(parsed.data)
    },
  }
}