import { useQueryClient } from '@tanstack/react-query'
import { z } from 'zod'
import { queryKeys } from '@/data/queryKeys'
import { BankError } from '@/lib/bankError'
import { createBankOperationIds } from '@/lib/bankIdempotency'
import { useBankMutation } from '@/lib/bankQuery'

const PORTFOLIO_BUY_EVENT = 'sonar:bank:portfolio:buy'
const PORTFOLIO_SELL_EVENT = 'sonar:bank:portfolio:sell'
const IBAN_RE = /^[A-Z]{2}[0-9A-Z\s-]{10,34}$/

export const portfolioBuySchema = z.object({
  from_iban: z.string().trim().toUpperCase().regex(IBAN_RE, 'INVALID_IBAN'),
  asset_symbol: z.string().trim().toUpperCase().min(1).max(16),
  units: z.number().positive(),
})

export const portfolioSellSchema = z.object({
  to_iban: z.string().trim().toUpperCase().regex(IBAN_RE, 'INVALID_IBAN'),
  asset_symbol: z.string().trim().toUpperCase().min(1).max(16),
  units: z.number().positive(),
})

export type PortfolioBuyArgs = z.input<typeof portfolioBuySchema>
export type PortfolioSellArgs = z.input<typeof portfolioSellSchema>

export interface PortfolioBuyResponse {
  asset: string
  units: number
  price_minor: number
  total_cost: number
}

export interface PortfolioSellResponse {
  asset: string
  units: number
  proceeds: number
}

function validationError(message: string, error: z.ZodError) {
  return new BankError({
    code: 'VALIDATION_FAILED',
    category: 'validation',
    message,
    retryable: false,
    details: { issues: error.flatten() },
  })
}

export function useBuyAssetMutation() {
  const qc = useQueryClient()
  const mutation = useBankMutation<PortfolioBuyResponse, PortfolioBuyArgs>(
    PORTFOLIO_BUY_EVENT,
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.stocks.portfolio() })
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
    { idempotency: createBankOperationIds },
  )

  return {
    ...mutation,
    mutateAsync: async (input: PortfolioBuyArgs) => {
      const parsed = portfolioBuySchema.safeParse(input)
      if (!parsed.success) throw validationError('Asset buy request contains invalid fields', parsed.error)
      return mutation.mutateAsync(parsed.data)
    },
  }
}

export function useSellAssetMutation() {
  const qc = useQueryClient()
  const mutation = useBankMutation<PortfolioSellResponse, PortfolioSellArgs>(
    PORTFOLIO_SELL_EVENT,
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.stocks.portfolio() })
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
    { idempotency: createBankOperationIds },
  )

  return {
    ...mutation,
    mutateAsync: async (input: PortfolioSellArgs) => {
      const parsed = portfolioSellSchema.safeParse(input)
      if (!parsed.success) throw validationError('Asset sell request contains invalid fields', parsed.error)
      return mutation.mutateAsync(parsed.data)
    },
  }
}
