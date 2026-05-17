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
  owner_type: z.enum(['personal']).default('personal'),
  account_class: z.enum(['checking', 'savings', 'business_treasury', 'shared']).default('checking'),
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
  owner_type?: Account['owner_type']
  account_class?: Account['account_class']
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

/* ============================================================================
   Joint owners (C020 / C021)

   Adds and removes joint owners on a primary-owned bank account. The optimistic
   patch updates `account.joint_owners` so the UI reflects the change before
   the BE round-trip; on error we restore the snapshot. The BE caps at three
   joints per account and rejects self / duplicates / unknown citizens with
   canonical BankErrors mapped from the registry.
   ============================================================================ */

const jointOwnerMutationSchema = z.object({
  iban: z.string().transform(normalizeIban).pipe(z.string().min(1)),
  joint_citizen_id: z.string().trim().min(1).max(64),
  reason: z.string().trim().max(140).nullable().optional(),
  correlation_id: z.string().uuid().optional(),
})

export type JointOwnerMutationArgs = z.input<typeof jointOwnerMutationSchema>

export interface JointOwnerAddResponse {
  iban: string
  joint_added: string
  total_joints?: number
}

export interface JointOwnerRemoveResponse {
  iban: string
  joint_removed: string
}

function coerceJointArray(raw: unknown): string[] {
  if (Array.isArray(raw)) return raw.filter((v): v is string => typeof v === 'string')
  if (typeof raw === 'string') {
    const trimmed = raw.trim()
    if (trimmed === '' || trimmed === '[]') return []
    try {
      const parsed = JSON.parse(trimmed) as unknown
      if (Array.isArray(parsed)) return parsed.filter((v): v is string => typeof v === 'string')
    } catch {
      /* fall through */
    }
  }
  return []
}

function patchJointOwners(
  previous: BootstrapSnapshot | undefined,
  iban: string,
  mutator: (current: string[]) => string[],
): BootstrapSnapshot | undefined {
  return patchAccount(previous, iban, (account) => {
    const current = coerceJointArray(account.joint_owners)
    const next = mutator(current)
    return { ...account, joint_owners: next.length > 0 ? next : null }
  })
}

export function useAddJointOwnerMutation() {
  const qc = useQueryClient()
  return useBankMutation<JointOwnerAddResponse, JointOwnerMutationArgs, AccountMutationContext>(
    'sonar:bank:account:addJoint',
    {
      onMutate: async (input) => {
        const parsed = jointOwnerMutationSchema.safeParse(input)
        if (!parsed.success) return {}
        await qc.cancelQueries({ queryKey: queryKeys.bootstrap() })
        const previousBootstrap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
        qc.setQueryData<BootstrapSnapshot | undefined>(
          queryKeys.bootstrap(),
          patchJointOwners(previousBootstrap, parsed.data.iban, (current) =>
            current.includes(parsed.data.joint_citizen_id)
              ? current
              : [...current, parsed.data.joint_citizen_id],
          ),
        )
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

export function useRemoveJointOwnerMutation() {
  const qc = useQueryClient()
  return useBankMutation<JointOwnerRemoveResponse, JointOwnerMutationArgs, AccountMutationContext>(
    'sonar:bank:account:removeJoint',
    {
      onMutate: async (input) => {
        const parsed = jointOwnerMutationSchema.safeParse(input)
        if (!parsed.success) return {}
        await qc.cancelQueries({ queryKey: queryKeys.bootstrap() })
        const previousBootstrap = qc.getQueryData<BootstrapSnapshot>(queryKeys.bootstrap())
        qc.setQueryData<BootstrapSnapshot | undefined>(
          queryKeys.bootstrap(),
          patchJointOwners(previousBootstrap, parsed.data.iban, (current) =>
            current.filter((id) => id !== parsed.data.joint_citizen_id),
          ),
        )
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

export function jointOwnerMutationPayload(input: JointOwnerMutationArgs): JointOwnerMutationArgs {
  const parsed = jointOwnerMutationSchema.safeParse({
    ...input,
    correlation_id: input.correlation_id ?? createBankOperationIds().correlationId,
  })
  if (!parsed.success) throwValidation('Invalid joint owner payload', parsed.error.flatten())
  return parsed.data
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
