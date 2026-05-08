import type { UseQueryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import type { BusinessTreasuryQueryRequest, BusinessTreasurySnapshot, PayrollPreviewRequest, PayrollPreviewResponse } from '@/data/contracts'
import { BankError } from '@/lib/bankError'
import { useBankCallback } from '@/lib/bankQuery'

const BUSINESS_TREASURY_EVENT = 'sonar:bank:business:treasury'
const PAYROLL_PREVIEW_EVENT = 'sonar:bank:business:payroll:preview'

export type BusinessTreasuryQueryOptions = Omit<
  UseQueryOptions<BusinessTreasurySnapshot, BankError>,
  'queryKey' | 'queryFn'
>

export type PayrollPreviewQueryOptions = Omit<
  UseQueryOptions<PayrollPreviewResponse, BankError>,
  'queryKey' | 'queryFn'
>

export function useBusinessTreasuryQuery(request: BusinessTreasuryQueryRequest, options: BusinessTreasuryQueryOptions = {}) {
  return useBankCallback<BusinessTreasurySnapshot, Record<string, unknown>>(
    BUSINESS_TREASURY_EVENT,
    queryKeys.business.treasury(request.company_id),
    { ...request },
    {
      staleTime: 20_000,
      ...options,
    },
  )
}

export function usePayrollPreviewQuery(request: PayrollPreviewRequest, options: PayrollPreviewQueryOptions = {}) {
  return useBankCallback<PayrollPreviewResponse, Record<string, unknown>>(
    PAYROLL_PREVIEW_EVENT,
    queryKeys.business.payrollPreview(request.company_id),
    { ...request },
    {
      staleTime: 20_000,
      ...options,
    },
  )
}
