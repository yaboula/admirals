import { useQueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import type {
  BusinessApprovalDecideRequest,
  BusinessApprovalDecideResponse,
  BusinessPayrollExecuteRequest,
  BusinessPayrollExecuteResponse,
} from '@/data/contracts'
import { createBankOperationIds } from '@/lib/bankIdempotency'
import { useBankMutation } from '@/lib/bankQuery'

const BUSINESS_PAYROLL_EXECUTE_EVENT = 'sonar:bank:business:payroll:execute'
const BUSINESS_APPROVAL_DECIDE_EVENT = 'sonar:bank:business:approval:decide'

type BusinessPayrollExecutePayload = BusinessPayrollExecuteRequest & Record<string, unknown>
type BusinessApprovalDecidePayload = BusinessApprovalDecideRequest & Record<string, unknown>

function useInvalidateBusiness(companyId?: string) {
  const qc = useQueryClient()
  return () => {
    if (companyId) {
      void qc.invalidateQueries({ queryKey: queryKeys.business.treasury(companyId) })
      void qc.invalidateQueries({ queryKey: queryKeys.business.payrollPreview(companyId) })
      return
    }
    void qc.invalidateQueries({ queryKey: queryKeys.business.all() })
  }
}

export function useExecuteBusinessPayrollMutation(companyId?: string) {
  const invalidate = useInvalidateBusiness(companyId)
  return useBankMutation<BusinessPayrollExecuteResponse, BusinessPayrollExecutePayload>(
    BUSINESS_PAYROLL_EXECUTE_EVENT,
    { onSuccess: invalidate },
    { idempotency: createBankOperationIds },
  )
}

export function useDecideBusinessApprovalMutation(companyId?: string) {
  const invalidate = useInvalidateBusiness(companyId)
  return useBankMutation<BusinessApprovalDecideResponse, BusinessApprovalDecidePayload>(
    BUSINESS_APPROVAL_DECIDE_EVENT,
    { onSuccess: invalidate },
    { idempotency: createBankOperationIds },
  )
}
