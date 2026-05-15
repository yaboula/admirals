import type { CardProductTier } from './cardDesigns'

export const MAX_CARDS = 3

export const CARD_TYPES = ['classic', 'premium'] as const

export const CARD_PRODUCT_LIMITS = {
  classic: {
    daily_limit_minor: 200000,
    monthly_limit_minor: 2500000,
    cash_limit_minor: 50000,
    interest_bps: 0,
    issue_fee_minor: 2500,
  },
  premium: {
    daily_limit_minor: 1000000,
    monthly_limit_minor: 10000000,
    cash_limit_minor: 250000,
    interest_bps: 850,
    issue_fee_minor: 15000,
  },
} satisfies Record<CardProductTier, {
  daily_limit_minor: number
  monthly_limit_minor: number
  cash_limit_minor: number
  interest_bps: number
  issue_fee_minor: number
}>
