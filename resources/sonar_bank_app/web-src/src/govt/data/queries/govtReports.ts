import { useQuery } from '@tanstack/react-query'
import type { GovtReportsData, GovtReportsRange } from '../contracts'
import { getReportsDataMock } from '../mock/govtReports'

export const govtReportsKeys = {
  data: (range: GovtReportsRange) => ['govt', 'reports', 'data', range] as const,
}

export function useGovtReportsQuery(range: GovtReportsRange) {
  return useQuery<GovtReportsData>({
    queryKey: govtReportsKeys.data(range),
    queryFn: async () => {
      await new Promise((r) => setTimeout(r, 180))
      return getReportsDataMock(range)
    },
    staleTime: 60_000,
    placeholderData: (prev) => prev,
  })
}
