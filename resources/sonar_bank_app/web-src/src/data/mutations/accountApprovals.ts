import { useQueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import type { ProfessionalAccountDecisionRequest, ProfessionalAccountDecisionResponse, ProfessionalAccountRequestArgs, ProfessionalAccountRequestResponse } from '@/data/contracts'
import { createBankOperationIds } from '@/lib/bankIdempotency'
import { useBankMutation } from '@/lib/bankQuery'

const ACCOUNT_PROFESSIONAL_REQUEST_EVENT = 'sonar:bank:account:professional:request'
const ACCOUNT_PROFESSIONAL_DECIDE_EVENT = 'sonar:bank:account:professional:decide'
type ProfessionalAccountRequestPayload = ProfessionalAccountRequestArgs & Record<string, unknown>
type ProfessionalAccountDecisionPayload = ProfessionalAccountDecisionRequest & Record<string, unknown>

export function useRequestProfessionalAccountMutation() {
  const qc = useQueryClient()
  return useBankMutation<ProfessionalAccountRequestResponse, ProfessionalAccountRequestPayload>(
    ACCOUNT_PROFESSIONAL_REQUEST_EVENT,
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
        void qc.invalidateQueries({ queryKey: queryKeys.account.all() })
      },
    },
    { idempotency: createBankOperationIds },
  )
}

export function useDecideProfessionalAccountMutation() {
  const qc = useQueryClient()
  return useBankMutation<ProfessionalAccountDecisionResponse, ProfessionalAccountDecisionPayload>(
    ACCOUNT_PROFESSIONAL_DECIDE_EVENT,
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
        void qc.invalidateQueries({ queryKey: queryKeys.account.all() })
      },
    },
    { idempotency: createBankOperationIds },
  )
}
