import { useQueryClient } from '@tanstack/react-query'
import { z } from 'zod'
import { queryKeys } from '@/data/queryKeys'
import type { Account, BootstrapSnapshot } from '@/data/contracts'
import { BankError } from '@/lib/bankError'
import { useBankMutation } from '@/lib/bankQuery'
import { createBankOperationIds } from '@/lib/bankIdempotency'
import { normalizeIban } from './transfers'

const accountOpenSchema = z.object({
  initial_balance: z.number().int().nonnegative().default(0),
  initial_savings: z.number().int().nonnegative().default(0),
})

const accountIbanMutationSchema = z.object({
  iban: z.string().transform(normalizeIban).pipe(z.string().min(1)),
  reason: z.string().trim().max(140).nullable().optional(),
  correlation_id: z.string().uuid().optional(),
})

const kycSubmitSchema = z.object({
  doc_count: z.number().int().positive().max(12),
})

export type AccountOpenArgs = z.input<typeof accountOpenSchema>
export type AccountIbanMutationArgs = z.input<typeof accountIbanMutationSchema>
export type KycSubmitArgs = z.input<typeof kycSubmitSchema>

export interface AccountOpenResponse {
  account_id: string
  iban: string
  citizen_id: string
}

export interface AccountStatusResponse {
  iban: string
  status?: Account['status']
  frozen?: boolean
}

export interface KycSubmitResponse {
  submitted_ms: number
}

interface AccountMutationContext {
  previousBootstrap?: BootstrapSnapshot
}

function throwValidation(message: string, details?: Record<string, unknown>): never {
  throw new BankError({
    code: 'VALIDATION_FAILED',
    category: 'validation',
    message,
    retryable: false,
    details,
  })
}

function patchAccount(
  previous: BootstrapSnapshot | undefined,
  iban: string,
  patcher: (account: Account) => Account,
): BootstrapSnapshot | undefined {
  if (!previous) return previous
  return {
    ...previous,
    accounts: previous.accounts.map((account) => (
      normalizeIban(account.iban) === iban ? patcher(account) : account
    )),
  }
}

export function useOpenAccountMutation() {
  const qc = useQueryClient()
  return useBankMutation<AccountOpenResponse, AccountOpenArgs>(
    'sonar:bank:account:open',
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
  )
}

export function useFreezeAccountMutation() {
  const qc = useQueryClient()
  return useBankMutation<AccountStatusResponse, AccountIbanMutationArgs, AccountMutationContext>(
    'sonar:bank:account:freeze',
    {
      onMutate: async (input) => {
        const parsed = accountIbanMutationSchema.safeParse(input)
        if (!parsed.success) return {}
        await qc.cancelQueries({ queryKey: queryKeys.bootstrap() })
        const previousBootstrap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
        qc.setQueryData<BootstrapSnapshot | undefined>(queryKeys.bootstrap(), patchAccount(previousBootstrap, parsed.data.iban, (account) => ({
          ...account,
          status: 'frozen',
          frozen_flag: true,
        })))
        return { previousBootstrap }
      },
      onError: (_err, _input, context) => {
        if (context?.previousBootstrap) qc.setQueryData(queryKeys.bootstrap(), context.previousBootstrap)
      },
      onSettled: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
  )
}

export function useUnfreezeAccountMutation() {
  const qc = useQueryClient()
  return useBankMutation<AccountStatusResponse, AccountIbanMutationArgs, AccountMutationContext>(
    'sonar:bank:account:unfreeze',
    {
      onMutate: async (input) => {
        const parsed = accountIbanMutationSchema.safeParse(input)
        if (!parsed.success) return {}
        await qc.cancelQueries({ queryKey: queryKeys.bootstrap() })
        const previousBootstrap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
        qc.setQueryData<BootstrapSnapshot | undefined>(queryKeys.bootstrap(), patchAccount(previousBootstrap, parsed.data.iban, (account) => ({
          ...account,
          status: 'active',
          frozen_flag: false,
        })))
        return { previousBootstrap }
      },
      onError: (_err, _input, context) => {
        if (context?.previousBootstrap) qc.setQueryData(queryKeys.bootstrap(), context.previousBootstrap)
      },
      onSettled: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
  )
}

export function useCloseAccountMutation() {
  const qc = useQueryClient()
  return useBankMutation<AccountStatusResponse, AccountIbanMutationArgs, AccountMutationContext>(
    'sonar:bank:account:close',
    {
      onMutate: async (input) => {
        const parsed = accountIbanMutationSchema.safeParse(input)
        if (!parsed.success) return {}
        await qc.cancelQueries({ queryKey: queryKeys.bootstrap() })
        const previousBootstrap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
        qc.setQueryData<BootstrapSnapshot | undefined>(queryKeys.bootstrap(), previousBootstrap ? {
          ...previousBootstrap,
          accounts: previousBootstrap.accounts.filter((account) => normalizeIban(account.iban) !== parsed.data.iban),
        } : previousBootstrap)
        return { previousBootstrap }
      },
      onError: (_err, _input, context) => {
        if (context?.previousBootstrap) qc.setQueryData(queryKeys.bootstrap(), context.previousBootstrap)
      },
      onSettled: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
  )
}

export function useSubmitKycMutation() {
  return useBankMutation<KycSubmitResponse, KycSubmitArgs>('sonar:bank:kyc:submit')
}

export async function openAccountPayload(input: AccountOpenArgs): Promise<AccountOpenArgs> {
  const parsed = accountOpenSchema.safeParse(input)
  if (!parsed.success) throwValidation('Invalid account opening payload', parsed.error.flatten())
  return parsed.data
}

export function accountMutationPayload(input: AccountIbanMutationArgs): AccountIbanMutationArgs {
  const parsed = accountIbanMutationSchema.safeParse({ ...input, correlation_id: input.correlation_id ?? createBankOperationIds().correlationId })
  if (!parsed.success) throwValidation('Invalid account mutation payload', parsed.error.flatten())
  return parsed.data
}

export function kycSubmitPayload(input: KycSubmitArgs): KycSubmitArgs {
  const parsed = kycSubmitSchema.safeParse(input)
  if (!parsed.success) throwValidation('Invalid KYC payload', parsed.error.flatten())
  return parsed.data
}
