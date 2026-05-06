export const queryKeys = {
  all: ['bank'] as const,

  bootstrap: () => [...queryKeys.all, 'bootstrap'] as const,

  config: () => [...queryKeys.all, 'config'] as const,

  recipients: {
    all: () => [...queryKeys.all, 'recipients'] as const,
    recent: () => [...queryKeys.recipients.all(), 'recent'] as const,
    saved: () => [...queryKeys.recipients.all(), 'saved'] as const,
  },

  transactions: {
    all: () => [...queryKeys.all, 'transactions'] as const,
    recent: (limit?: number) => [...queryKeys.transactions.all(), 'recent', { limit }] as const,
    detail: (txnId: string) => [...queryKeys.transactions.all(), 'detail', txnId] as const,
  },

  account: {
    all: () => [...queryKeys.all, 'accounts'] as const,
    balance: (iban: string) => [...queryKeys.account.all(), 'balance', iban] as const,
  },
} as const
