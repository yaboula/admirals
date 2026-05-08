import type { UseQueryOptions } from '@tanstack/react-query'
import type { StockListResponse, StockPortfolioResponse } from '@/data/contracts'
import { useBankCallback } from '@/lib/bankQuery'
import { queryKeys } from '@/data/queryKeys'
import { BankError } from '@/lib/bankError'

const STOCKS_LIST_EVENT = 'sonar:bank:stocks:list'
const STOCKS_PORTFOLIO_EVENT = 'sonar:bank:stocks:portfolio'

export type StockListQueryOptions = Omit<
  UseQueryOptions<StockListResponse, BankError>,
  'queryKey' | 'queryFn'
>

export type StockPortfolioQueryOptions = Omit<
  UseQueryOptions<StockPortfolioResponse, BankError>,
  'queryKey' | 'queryFn'
>

export function useStockListQuery(options: StockListQueryOptions = {}) {
  return useBankCallback<StockListResponse, Record<string, unknown>>(
    STOCKS_LIST_EVENT,
    queryKeys.stocks.list(),
    {},
    {
      staleTime: 30_000,
      gcTime: 5 * 60_000,
      ...options,
    },
  )
}

export function useStockPortfolioQuery(options: StockPortfolioQueryOptions = {}) {
  return useBankCallback<StockPortfolioResponse, Record<string, unknown>>(
    STOCKS_PORTFOLIO_EVENT,
    queryKeys.stocks.portfolio(),
    {},
    {
      staleTime: 30_000,
      gcTime: 5 * 60_000,
      ...options,
    },
  )
}
