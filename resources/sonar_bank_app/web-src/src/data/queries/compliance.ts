import type { UseQueryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import type { ComplianceFlagsQueryRequest, ComplianceFlagsQueryResponse } from '@/data/contracts'
import { BankError } from '@/lib/bankError'
import { useBankCallback } from '@/lib/bankQuery'

const COMPLIANCE_FLAGS_EVENT = 'sonar:bank:compliance:flags'

export type ComplianceFlagsQueryOptions = Omit<
  UseQueryOptions<ComplianceFlagsQueryResponse, BankError>,
  'queryKey' | 'queryFn'
>

export function useComplianceFlagsQuery(request: ComplianceFlagsQueryRequest, options: ComplianceFlagsQueryOptions = {}) {
  return useBankCallback<ComplianceFlagsQueryResponse, Record<string, unknown>>(
    COMPLIANCE_FLAGS_EVENT,
    queryKeys.compliance.flags(request.query ?? '', request.status ?? 'all', request.severity ?? 'all'),
    { ...request },
    {
      staleTime: 20_000,
      ...options,
    },
  )
}
