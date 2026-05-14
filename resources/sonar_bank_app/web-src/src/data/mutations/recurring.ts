import { z } from 'zod'
import { useInvalidateBootstrap } from '@/data/queries'
import { BankError } from '@/lib/bankError'
import { createBankOperationIds } from '@/lib/bankIdempotency'
import { useBankMutation } from '@/lib/bankQuery'

const RECURRING_SUBSCRIBE_EVENT = 'sonar:bank:recurring:subscribe'
const RECURRING_CANCEL_EVENT = 'sonar:bank:recurring:cancel'
const RECURRING_PAUSE_EVENT = 'sonar:bank:recurring:pause'
const RECURRING_RESUME_EVENT = 'sonar:bank:recurring:resume'
const IBAN_RE = /^[A-Z]{2}[0-9A-Z\s-]{10,34}$/

export const recurringSubscribeSchema = z.object({
  from_iban: z.string().trim().toUpperCase().regex(IBAN_RE, 'INVALID_IBAN'),
  to_iban: z.string().trim().toUpperCase().regex(IBAN_RE, 'INVALID_IBAN'),
  amount_minor: z.number().int().positive(),
  reason: z.string().trim().max(140).nullable().optional(),
  interval_days: z.number().int().min(1).max(365),
  first_charge_ms: z.number().int().refine((value) => value > Date.now(), 'FIRST_CHARGE_MUST_BE_FUTURE'),
})

export const recurringIdSchema = z.object({
  recurring_id: z.string().min(1),
})

export type RecurringSubscribeArgs = z.input<typeof recurringSubscribeSchema>
export type RecurringIdArgs = z.input<typeof recurringIdSchema>

export interface RecurringSubscribeResponse {
  recurring_id: string
  next_charge_ms: number
}

export interface RecurringStatusResponse {
  recurring_id: string
  status: 'active' | 'paused' | 'cancelled'
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

export function useSubscribeRecurringMutation() {
  const invalidateBootstrap = useInvalidateBootstrap()
  const mutation = useBankMutation<RecurringSubscribeResponse, RecurringSubscribeArgs>(
    RECURRING_SUBSCRIBE_EVENT,
    { onSuccess: () => { void invalidateBootstrap() } },
    { idempotency: createBankOperationIds },
  )

  return {
    ...mutation,
    mutateAsync: async (input: RecurringSubscribeArgs) => {
      const parsed = recurringSubscribeSchema.safeParse(input)
      if (!parsed.success) throw validationError('Recurring subscription contains invalid fields', parsed.error)
      return mutation.mutateAsync(parsed.data)
    },
  }
}

function useRecurringStatusMutation(eventName: string) {
  const invalidateBootstrap = useInvalidateBootstrap()
  const mutation = useBankMutation<RecurringStatusResponse, RecurringIdArgs>(
    eventName,
    { onSuccess: () => { void invalidateBootstrap() } },
    { idempotency: createBankOperationIds },
  )

  return {
    ...mutation,
    mutateAsync: async (input: RecurringIdArgs) => {
      const parsed = recurringIdSchema.safeParse(input)
      if (!parsed.success) throw validationError('Recurring action contains invalid fields', parsed.error)
      return mutation.mutateAsync(parsed.data)
    },
  }
}

export function useCancelRecurringMutation() {
  return useRecurringStatusMutation(RECURRING_CANCEL_EVENT)
}

export function usePauseRecurringMutation() {
  return useRecurringStatusMutation(RECURRING_PAUSE_EVENT)
}

export function useResumeRecurringMutation() {
  return useRecurringStatusMutation(RECURRING_RESUME_EVENT)
}
