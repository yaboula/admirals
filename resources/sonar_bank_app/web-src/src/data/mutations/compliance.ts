import { useQueryClient } from '@tanstack/react-query'
import { z } from 'zod'
import { queryKeys } from '@/data/queryKeys'
import { BankError } from '@/lib/bankError'
import { createBankOperationIds } from '@/lib/bankIdempotency'
import { useBankMutation } from '@/lib/bankQuery'

const COMPLIANCE_RESOLVE_EVENT = 'sonar:bank:compliance:resolveFlag'

export const complianceResolveSchema = z.object({
  flag_id: z.string().uuid(),
  resolution: z.enum(['resolved', 'dismissed', 'escalated']),
  resolution_notes: z.string().min(1, 'Resolution notes are required'),
})

export type ComplianceResolveArgs = z.input<typeof complianceResolveSchema>

function validationError(message: string, error: z.ZodError) {
  return new BankError({
    code: 'VALIDATION_FAILED',
    category: 'validation',
    message,
    retryable: false,
    details: { issues: error.flatten() },
  })
}

export function useResolveComplianceFlagMutation() {
  const qc = useQueryClient()
  const mutation = useBankMutation<unknown, ComplianceResolveArgs>(
    COMPLIANCE_RESOLVE_EVENT,
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.compliance.flags('', 'all', 'all') })
      },
    },
    { idempotency: createBankOperationIds },
  )

  return {
    ...mutation,
    mutateAsync: async (input: ComplianceResolveArgs) => {
      const parsed = complianceResolveSchema.safeParse(input)
      if (!parsed.success) throw validationError('Compliance resolution contains invalid fields', parsed.error)
      return mutation.mutateAsync(parsed.data)
    },
  }
}
