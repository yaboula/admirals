import { queryKeys } from '@/data/queryKeys'
import type { ProfessionalAccountApprovalsResponse } from '@/data/contracts'
import { useBankCallback } from '@/lib/bankQuery'

const ACCOUNT_PROFESSIONAL_APPROVALS_EVENT = 'sonar:bank:account:professional:listApprovals'

export interface ProfessionalAccountApprovalsQueryOptions {
  limit?: number
}

export function useProfessionalAccountApprovalsQuery(options: ProfessionalAccountApprovalsQueryOptions = {}) {
  const limit = options.limit ?? 50
  return useBankCallback<ProfessionalAccountApprovalsResponse, { limit: number }>(
    ACCOUNT_PROFESSIONAL_APPROVALS_EVENT,
    queryKeys.account.professionalApprovals(limit),
    { limit },
  )
}
