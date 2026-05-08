import type { UseQueryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/data/queryKeys'
import type { AuditQueryRequest, AuditQueryResponse } from '@/data/contracts'
import { BankError } from '@/lib/bankError'
import { useBankCallback } from '@/lib/bankQuery'

const AUDIT_QUERY_EVENT = 'sonar:bank:audit:query'

export type AuditQueryOptions = Omit<
  UseQueryOptions<AuditQueryResponse, BankError>,
  'queryKey' | 'queryFn'
>

export function useAuditQuery(request: AuditQueryRequest, options: AuditQueryOptions = {}) {
  return useBankCallback<AuditQueryResponse, Record<string, unknown>>(
    AUDIT_QUERY_EVENT,
    queryKeys.audit.query(request.scope, request.query ?? '', request.event_type ?? 'all', request.status ?? 'all'),
    { ...request },
    {
      staleTime: 20_000,
      ...options,
    },
  )
}
