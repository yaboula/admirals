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

  audit: {
    all: () => [...queryKeys.all, 'audit'] as const,
    query: (scope: string, query: string, eventType: string, status: string) => [...queryKeys.audit.all(), 'query', { scope, query, eventType, status }] as const,
  },

  compliance: {
    all: () => [...queryKeys.all, 'compliance'] as const,
    flags: (query: string, status: string, severity: string) => [...queryKeys.compliance.all(), 'flags', { query, status, severity }] as const,
  },

  business: {
    all: () => [...queryKeys.all, 'business'] as const,
    treasury: (companyId: string) => [...queryKeys.business.all(), 'treasury', companyId] as const,
    payrollPreview: (companyId: string) => [...queryKeys.business.all(), 'payrollPreview', companyId] as const,
  },

  stocks: {
    all: () => [...queryKeys.all, 'stocks'] as const,
    list: () => [...queryKeys.stocks.all(), 'list'] as const,
    portfolio: () => [...queryKeys.stocks.all(), 'portfolio'] as const,
  },

  loans: {
    all: () => [...queryKeys.all, 'loans'] as const,
    list: () => [...queryKeys.loans.all(), 'list'] as const,
    installments: (loanId: string) => [...queryKeys.loans.all(), 'installments', loanId] as const,
  },

  atm: {
    all: () => [...queryKeys.all, 'atm'] as const,
    session: () => [...queryKeys.atm.all(), 'session'] as const,
  },

  account: {
    all: () => [...queryKeys.all, 'accounts'] as const,
    balance: (iban: string) => [...queryKeys.account.all(), 'balance', iban] as const,
    professionalApprovals: (limit?: number) => [...queryKeys.account.all(), 'professionalApprovals', { limit }] as const,
  },

  cards: {
    all: () => [...queryKeys.all, 'cards'] as const,
    detail: (cardId: string) => [...queryKeys.cards.all(), 'detail', cardId] as const,
  },
} as const
