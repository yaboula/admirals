import type { UseQueryOptions } from '@tanstack/react-query'
import type { LoanInstallmentsResponse, LoanListResponse, LoanProductsResponse } from '@/data/contracts'
import { useBankCallback } from '@/lib/bankQuery'
import { queryKeys } from '@/data/queryKeys'
import { BankError } from '@/lib/bankError'

const LOANS_LIST_EVENT = 'sonar:bank:loans:list'
const LOANS_INSTALLMENTS_EVENT = 'sonar:bank:loans:installments'
const LOAN_PRODUCTS_EVENT = 'sonar:bank:loan:products'

export type LoanListQueryOptions = Omit<
  UseQueryOptions<LoanListResponse, BankError>,
  'queryKey' | 'queryFn'
>

export type LoanInstallmentsQueryOptions = Omit<
  UseQueryOptions<LoanInstallmentsResponse, BankError>,
  'queryKey' | 'queryFn'
>

export type LoanProductsQueryOptions = Omit<
  UseQueryOptions<LoanProductsResponse, BankError>,
  'queryKey' | 'queryFn'
>

export function useLoanListQuery(options: LoanListQueryOptions = {}) {
  return useBankCallback<LoanListResponse, Record<string, unknown>>(
    LOANS_LIST_EVENT,
    queryKeys.loans.list(),
    {},
    {
      staleTime: 30_000,
      gcTime: 5 * 60_000,
      ...options,
    },
  )
}

export function useLoanInstallmentsQuery(loanId: string | null, options: LoanInstallmentsQueryOptions = {}) {
  const payload: Record<string, unknown> = { loan_id: loanId ?? '' }
  return useBankCallback<LoanInstallmentsResponse, Record<string, unknown>>(
    LOANS_INSTALLMENTS_EVENT,
    queryKeys.loans.installments(loanId ?? 'none'),
    payload,
    {
      enabled: Boolean(loanId),
      staleTime: 30_000,
      gcTime: 5 * 60_000,
      ...options,
    },
  )
}

export function useLoanProductsQuery(options: LoanProductsQueryOptions = {}) {
  return useBankCallback<LoanProductsResponse, Record<string, unknown>>(
    LOAN_PRODUCTS_EVENT,
    [...queryKeys.loans.all(), 'products'],
    {},
    {
      staleTime: 5 * 60_000,
      gcTime: 10 * 60_000,
      ...options,
    },
  )
}
