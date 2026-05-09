import type { GovtReportsData, GovtReportsRange } from '../contracts'
import { useBankCallback } from '@/lib/bankQuery'

const REPORTS_DATA_EVENT = 'sonar:bank:govt:reports:data'

export const govtReportsKeys = {
  data: (range: GovtReportsRange) => ['govt', 'reports', 'data', range] as const,
}

export function useGovtReportsQuery(range: GovtReportsRange) {
  return useBankCallback<GovtReportsData, Record<string, unknown>>(
    REPORTS_DATA_EVENT,
    govtReportsKeys.data(range),
    { range },
    {
      staleTime: 60_000,
      placeholderData: (prev) => prev,
    },
  )
}
