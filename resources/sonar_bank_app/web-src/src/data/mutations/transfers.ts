import { useMutation, useQueryClient } from '@tanstack/react-query'
import { z } from 'zod'
import { queryKeys } from '@/data/queryKeys'
import type {
  BootstrapSnapshot,
  RecentRecipient,
  RecentRecipientsResponse,
  Transaction,
} from '@/data/contracts'
import { simulateLatency } from '@/data/mock/seed'
import { BankError } from '@/lib/bankError'

const SPANISH_IBAN_RE = /^ES\d{22}$/
const LARGE_TRANSFER_MINOR = 1_000_00
const MAX_TRANSFER_MINOR = 250_000_00

export const transferExecuteSchema = z.object({
  from_iban: z.string().min(1),
  to_iban: z.string().transform(normalizeIban).pipe(z.string().regex(SPANISH_IBAN_RE, 'INVALID_IBAN')),
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

const processedIdempotencyKeys = new Set<string>()

export function normalizeIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '').toUpperCase()
}

export function formatIban(value: string | undefined | null): string {
  return normalizeIban(value).replace(/(.{4})/g, '$1 ').trim()
}

export function isValidSpanishIban(value: string | undefined | null): boolean {
  return SPANISH_IBAN_RE.test(normalizeIban(value))
}

export function isLargeTransfer(amountMinor: number): boolean {
  return amountMinor >= LARGE_TRANSFER_MINOR
}

export function transferTxnId(idempotencyKey: string): string {
  return `txn-xfer-${idempotencyKey.slice(0, 8)}`
}

export function useExecuteTransfer() {
  const qc = useQueryClient()

  return useMutation<TransferReceipt, BankError, TransferExecuteArgsInput, TransferMutationContext>({
    mutationFn: async (input) => {
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

      const args = parsed.data
      await simulateLatency(760, 1_360)

      if (processedIdempotencyKeys.has(args.idempotency_key)) {
        throw new BankError({
          code: 'IDEMPOTENCY_REPLAY',
          category: 'validation',
          message: 'Esta transferencia ya fue procesada',
          retryable: false,
        })
      }

      const snap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
      const fromIban = normalizeIban(args.from_iban)
      const toIban = normalizeIban(args.to_iban)
      const account = snap?.accounts.find((a) => normalizeIban(a.iban) === fromIban)

      if (!account) {
        throw new BankError({
          code: 'ACCOUNT_NOT_FOUND',
          category: 'not_found',
          message: 'No se encontró la cuenta origen',
          retryable: false,
        })
      }

      if (normalizeIban(account.iban) === toIban) {
        throw new BankError({
          code: 'VALIDATION_FAILED',
          category: 'validation',
          message: 'No puedes transferir a la misma cuenta',
          retryable: false,
        })
      }

      if (account.status !== 'active' || account.frozen_flag === 1 || account.frozen_flag === true) {
        throw new BankError({
          code: 'COMPLIANCE_FROZEN',
          category: 'compliance',
          message: 'La cuenta origen no permite transferencias',
          retryable: false,
        })
      }

      const optimisticTxnId = transferTxnId(args.idempotency_key)
      const optimisticAlreadyApplied = snap?.recent_transactions.some((t) => t.txn_id === optimisticTxnId) === true
      const effectiveBalanceMinor = optimisticAlreadyApplied
        ? account.balance_minor + args.amount_minor
        : account.balance_minor
      const availableBalanceMinor = effectiveBalanceMinor - args.amount_minor

      if (effectiveBalanceMinor < args.amount_minor) {
        throw new BankError({
          code: 'INSUFFICIENT_FUNDS',
          category: 'validation',
          message: 'Saldo insuficiente para completar la transferencia',
          retryable: false,
        })
      }

      processedIdempotencyKeys.add(args.idempotency_key)

      return {
        transaction_id: transferTxnId(args.idempotency_key),
        status: 'committed',
        from_iban: account.iban,
        to_iban: formatIban(toIban),
        amount_minor: args.amount_minor,
        reason: args.reason,
        committed_at_ms: Date.now(),
        available_balance_minor: Math.max(0, availableBalanceMinor),
        idempotency_key: args.idempotency_key,
        correlation_id: args.correlation_id,
        large_transfer: isLargeTransfer(args.amount_minor),
      }
    },
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

      if (previousBootstrap) {
        const nextBootstrap = patchBootstrapForTransfer(previousBootstrap, args)
        qc.setQueryData<BootstrapSnapshot>(queryKeys.bootstrap(), nextBootstrap)
      }

      if (previousRecentRecipients) {
        qc.setQueryData<RecentRecipientsResponse>(queryKeys.recipients.recent(), {
          ...previousRecentRecipients,
          recipients: patchRecentRecipients(previousRecentRecipients.recipients, args),
          fetched_at_ms: Date.now(),
        })
      }

      return { previousBootstrap, previousRecentRecipients }
    },
    onError: (_err, _vars, context) => {
      if (context?.previousBootstrap) {
        qc.setQueryData(queryKeys.bootstrap(), context.previousBootstrap)
      }
      if (context?.previousRecentRecipients) {
        qc.setQueryData(queryKeys.recipients.recent(), context.previousRecentRecipients)
      }
    },
  })
}

function patchBootstrapForTransfer(snap: BootstrapSnapshot, args: TransferExecuteArgs): BootstrapSnapshot {
  const fromIban = normalizeIban(args.from_iban)
  const now = Date.now()
  const txn: Transaction = {
    txn_id: transferTxnId(args.idempotency_key),
    from_iban: args.from_iban,
    to_iban: formatIban(args.to_iban),
    amount_minor: args.amount_minor,
    reason: args.reason,
    direction: 'out',
    status: 'committed',
    timestamp_ms: now,
  }

  return {
    ...snap,
    accounts: snap.accounts.map((a) =>
      normalizeIban(a.iban) === fromIban
        ? { ...a, balance_minor: Math.max(0, a.balance_minor - args.amount_minor) }
        : a,
    ),
    recent_transactions: [txn, ...snap.recent_transactions.filter((t) => t.txn_id !== txn.txn_id)].slice(0, 64),
    recent_recipients: patchRecentRecipients(snap.recent_recipients, args),
    server_now_ms: now,
  }
}

function patchRecentRecipients(recipients: RecentRecipient[], args: TransferExecuteArgs): RecentRecipient[] {
  const toIban = normalizeIban(args.to_iban)
  const now = Date.now()
  const nextAmountPresets = (existing: number[]): number[] =>
    [args.amount_minor, ...existing.filter((amount) => amount !== args.amount_minor)].slice(0, 3)

  const existing = recipients.find((r) => normalizeIban(r.counterpart_iban) === toIban)
  if (!existing) {
    return [
      {
        counterpart_iban: formatIban(args.to_iban),
        alias: null,
        is_favorite: false,
        last_transfer_ms: now,
        transfer_count: 1,
        preset_amounts: [args.amount_minor],
        last_reason: args.reason,
      },
      ...recipients,
    ].slice(0, 8)
  }

  return [
    {
      ...existing,
      last_transfer_ms: now,
      transfer_count: existing.transfer_count + 1,
      preset_amounts: nextAmountPresets(existing.preset_amounts),
      last_reason: args.reason,
    },
    ...recipients.filter((r) => normalizeIban(r.counterpart_iban) !== toIban),
  ].slice(0, 8)
}
