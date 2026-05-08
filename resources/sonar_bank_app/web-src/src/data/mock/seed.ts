import type {
  Account,
  AuditEvent,
  AuditQueryRequest,
  AuditQueryResponse,
  AtmSessionResponse,
  BankCardMock,
  BootstrapSnapshot,
  BusinessTreasuryQueryRequest,
  BusinessTreasurySnapshot,
  ClientConfigSnapshot,
  ComplianceFlag,
  ComplianceFlagsQueryRequest,
  ComplianceFlagsQueryResponse,
  Loan,
  LoanInstallment,
  LoanInstallmentsRequest,
  LoanInstallmentsResponse,
  LoanListResponse,
  PayrollPreviewRequest,
  PayrollPreviewResponse,
  PortfolioHolding,
  RecentRecipient,
  RecentRecipientsResponse,
  Recurring,
  StockListResponse,
  StockPortfolioResponse,
  StockQuote,
  Transaction,
} from '@/data/contracts'
import { generateUuidV4 } from '@/lib/utils'

const NOW = (): number => Date.now()
const DAY_MS = 24 * 60 * 60 * 1000

export const MOCK_CITIZEN_ID = 'CIT-7F4A-9B2D-AC01'

/* ---------------------------------------------------------------------------
   Mock player identity — Phase A stand-in until real NetEvent plugs in.
   Production pipeline: bootstrap payload → session store `displayName`.
   --------------------------------------------------------------------------- */
export const MOCK_GIVEN_NAME = 'Alex'
export const MOCK_FAMILY_NAME = 'Rivera'
export const MOCK_DISPLAY_NAME = `${MOCK_GIVEN_NAME} ${MOCK_FAMILY_NAME}`

export function getMockGivenName(): string {
  return MOCK_GIVEN_NAME
}

export function getMockDisplayName(): string {
  return MOCK_DISPLAY_NAME
}

export function getMockInitialsFromName(): string {
  return `${MOCK_GIVEN_NAME[0] ?? ''}${MOCK_FAMILY_NAME[0] ?? ''}`.toUpperCase()
}

const SAMPLE_RECIPIENTS_META: Array<{
  iban: string
  alias: string | null
  is_favorite: boolean
  preset_amounts: number[]
  last_reason: string | null
  daysAgo: number
  count: number
  initials: string
}> = [
  { iban: 'ES91 2100 0418 4502 0005 1332', alias: 'Lucía Mendoza',  is_favorite: true,  preset_amounts: [50_00, 120_00, 200_00], last_reason: 'Cena domingo',         daysAgo: 1, count: 18, initials: 'LM' },
  { iban: 'ES44 0049 1500 0512 3456 7890', alias: 'Hugo García',    is_favorite: true,  preset_amounts: [25_00, 80_00, 100_00],  last_reason: 'Mitad alquiler',      daysAgo: 2, count: 12, initials: 'HG' },
  { iban: 'ES79 0081 0123 4500 0987 6543', alias: 'Carmen Soler',   is_favorite: false, preset_amounts: [15_00, 30_00, 60_00],   last_reason: 'Cafés semana',        daysAgo: 3, count: 9,  initials: 'CS' },
  { iban: 'ES12 1465 0100 9000 1234 5678', alias: 'Andrés Pérez',   is_favorite: false, preset_amounts: [200_00, 400_00],         last_reason: 'Material taller',     daysAgo: 5, count: 4,  initials: 'AP' },
  { iban: 'ES60 2038 9876 5432 1098 7654', alias: 'María Costa',    is_favorite: false, preset_amounts: [12_50, 35_00, 75_00],   last_reason: null,                  daysAgo: 7, count: 7,  initials: 'MC' },
  { iban: 'ES53 1583 0001 9090 0011 2233', alias: null,             is_favorite: false, preset_amounts: [500_00],                  last_reason: 'Reembolso viaje',     daysAgo: 9, count: 2,  initials: '··' },
  { iban: 'ES88 0182 0024 1700 1234 5678', alias: 'Tienda Marco',   is_favorite: false, preset_amounts: [8_50, 16_00, 24_00],     last_reason: 'Pan + leche',         daysAgo: 11, count: 14, initials: 'TM' },
]

export function buildMockRecentRecipients(): RecentRecipient[] {
  const now = NOW()
  return SAMPLE_RECIPIENTS_META.map((m) => ({
    counterpart_iban: m.iban,
    alias: m.alias,
    is_favorite: m.is_favorite,
    last_transfer_ms: now - m.daysAgo * DAY_MS,
    transfer_count: m.count,
    preset_amounts: m.preset_amounts,
    last_reason: m.last_reason,
  }))
}

export function getMockInitialsForIban(iban: string): string {
  const meta = findMetaByIban(iban)
  return meta?.initials ?? '··'
}

export function getMockAliasForIban(iban: string): string | null {
  const meta = findMetaByIban(iban)
  return meta?.alias ?? null
}

function findMetaByIban(
  iban: string,
): (typeof SAMPLE_RECIPIENTS_META)[number] | undefined {
  const compact = iban.replace(/\s+/g, '')
  return SAMPLE_RECIPIENTS_META.find(
    (m) => m.iban.replace(/\s+/g, '') === compact,
  )
}

/* ---------------------------------------------------------------------------
   Anchored transactions — guaranteed to appear so chart spikes / dashboard
   preview stay visually predictable across reloads.
   --------------------------------------------------------------------------- */
const ANCHORED_TX: Array<{
  amount: number
  reason: string | null
  direction: Transaction['direction']
  status: Transaction['status']
  hoursAgo: number
  partnerIdx: number
}> = [
  { amount: 250_00,   reason: 'Mitad alquiler abril',  direction: 'out', status: 'committed', hoursAgo: 6,   partnerIdx: 1 },
  { amount: 1_250_00, reason: 'Salario mensual',       direction: 'in',  status: 'committed', hoursAgo: 18,  partnerIdx: 5 },
  { amount: 38_50,    reason: 'Cena domingo',          direction: 'out', status: 'committed', hoursAgo: 36,  partnerIdx: 0 },
  { amount: 120_00,   reason: 'Devolución viaje',      direction: 'in',  status: 'committed', hoursAgo: 50,  partnerIdx: 5 },
  { amount: 75_00,    reason: 'Material taller',       direction: 'out', status: 'pending',   hoursAgo: 2,   partnerIdx: 3 },
  { amount: 12_50,    reason: 'Cafés semana',          direction: 'out', status: 'committed', hoursAgo: 72,  partnerIdx: 2 },
  { amount: 500_00,   reason: 'Cuota préstamo coche',  direction: 'out', status: 'committed', hoursAgo: 96,  partnerIdx: 6 },
  { amount: 9_99,     reason: 'Suscripción mensual',   direction: 'out', status: 'committed', hoursAgo: 120, partnerIdx: 6 },
]

/* Procedural pool — categorised reasons used to fill the rest of the 30-day
   window. Tags are kept on the entry (not in the public Transaction contract)
   so the history filter logic could later expose category chips. */
const PROCEDURAL_POOL: Array<{
  amount: [number, number]
  reason: string
  direction: Transaction['direction']
  partnerIdx: number
  weight: number
}> = [
  { amount: [3_50, 8_00],     reason: 'Café del día',          direction: 'out', partnerIdx: 2, weight: 8 },
  { amount: [12_00, 28_00],   reason: 'Comida menú',            direction: 'out', partnerIdx: 6, weight: 5 },
  { amount: [6_00, 14_00],    reason: 'Pan + leche',            direction: 'out', partnerIdx: 6, weight: 4 },
  { amount: [40_00, 90_00],   reason: 'Compra supermercado',    direction: 'out', partnerIdx: 6, weight: 3 },
  { amount: [22_00, 60_00],   reason: 'Gasolina',               direction: 'out', partnerIdx: 4, weight: 3 },
  { amount: [15_00, 35_00],   reason: 'Transporte',             direction: 'out', partnerIdx: 4, weight: 2 },
  { amount: [9_99, 19_99],    reason: 'Suscripción servicio',   direction: 'out', partnerIdx: 6, weight: 2 },
  { amount: [80_00, 240_00],  reason: 'Compra electrónica',     direction: 'out', partnerIdx: 3, weight: 1 },
  { amount: [25_00, 80_00],   reason: 'Cena con amigos',        direction: 'out', partnerIdx: 0, weight: 3 },
  { amount: [120_00, 280_00], reason: 'Reembolso pendiente',    direction: 'in',  partnerIdx: 5, weight: 2 },
  { amount: [18_00, 50_00],   reason: 'Cafés semana',           direction: 'in',  partnerIdx: 2, weight: 1 },
  { amount: [60_00, 180_00],  reason: 'Trabajo freelance',      direction: 'in',  partnerIdx: 3, weight: 2 },
  { amount: [40_00, 120_00],  reason: 'Devolución compra',      direction: 'in',  partnerIdx: 6, weight: 1 },
]

const ACCOUNT_IBANS = ['ES12 9999 0000 1111 2222 3333', 'ES12 9999 0000 1111 2222 4444']

/* Tiny deterministic LCG so the procedural mock stays stable across reloads.
   Seed pinned to a known value: changing it regenerates the dataset. */
function makeRng(seed: number): () => number {
  let s = seed >>> 0
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0
    return s / 0xffffffff
  }
}

export function buildMockTransactions(): Transaction[] {
  const now = NOW()
  const out: Transaction[] = []

  // Anchor entries first.
  ANCHORED_TX.forEach((t, i) => {
    const partner = SAMPLE_RECIPIENTS_META[t.partnerIdx % SAMPLE_RECIPIENTS_META.length]!
    const fromIban = t.direction === 'in' ? partner.iban : ACCOUNT_IBANS[0]!
    const toIban = t.direction === 'in' ? ACCOUNT_IBANS[0]! : partner.iban
    out.push({
      txn_id: `txn-anc-${i.toString().padStart(4, '0')}`,
      from_iban: fromIban,
      to_iban: toIban,
      amount_minor: t.amount,
      reason: t.reason,
      direction: t.direction,
      status: t.status,
      timestamp_ms: now - t.hoursAgo * 60 * 60 * 1000,
    })
  })

  // Build a weighted bag once for fast pick.
  const weightedBag: number[] = []
  PROCEDURAL_POOL.forEach((p, idx) => {
    for (let i = 0; i < p.weight; i++) weightedBag.push(idx)
  })

  const rng = makeRng(0x5EED_BA15)
  const TARGET_TOTAL = 48 // 8 anchored + 40 procedural
  const WINDOW_HOURS = 30 * 24

  for (let i = 0; i < TARGET_TOTAL - ANCHORED_TX.length; i++) {
    const tpl = PROCEDURAL_POOL[weightedBag[Math.floor(rng() * weightedBag.length)]!]!
    const partner = SAMPLE_RECIPIENTS_META[tpl.partnerIdx % SAMPLE_RECIPIENTS_META.length]!
    const amount = Math.round(tpl.amount[0] + rng() * (tpl.amount[1] - tpl.amount[0]))
    // Cluster more transactions in the recent week (front-weighted).
    const hoursAgo = Math.round(Math.pow(rng(), 1.6) * WINDOW_HOURS)
    // Most committed; sprinkle a few pending / reverted for realism.
    const r = rng()
    const status: Transaction['status'] =
      r < 0.05 ? 'pending' : r < 0.07 ? 'reverted' : 'committed'

    const fromIban = tpl.direction === 'in' ? partner.iban : ACCOUNT_IBANS[0]!
    const toIban = tpl.direction === 'in' ? ACCOUNT_IBANS[0]! : partner.iban

    out.push({
      txn_id: `txn-pro-${i.toString().padStart(4, '0')}`,
      from_iban: fromIban,
      to_iban: toIban,
      amount_minor: amount,
      reason: tpl.reason,
      direction: tpl.direction,
      status,
      timestamp_ms: now - hoursAgo * 60 * 60 * 1000,
    })
  }

  // Sort newest-first so list/preview consumers work without re-sorting.
  out.sort((a, b) => b.timestamp_ms - a.timestamp_ms)
  return out
}

export function buildMockAccounts(): Account[] {
  return [
    {
      account_id: 'acc-mock-primary',
      iban: ACCOUNT_IBANS[0]!,
      owner_citizen_id: MOCK_CITIZEN_ID,
      joint_owners: null,
      balance_minor: 4_287_50,
      savings_minor: 12_840_00,
      status: 'active',
      frozen_flag: 0,
      created_ms: NOW() - 365 * DAY_MS,
    },
    {
      account_id: 'acc-mock-savings',
      iban: ACCOUNT_IBANS[1]!,
      owner_citizen_id: MOCK_CITIZEN_ID,
      joint_owners: null,
      balance_minor: 0,
      savings_minor: 35_000_00,
      status: 'active',
      frozen_flag: 0,
      created_ms: NOW() - 280 * DAY_MS,
    },
  ]
}

export function buildMockRecurring(): Recurring[] {
  const now = NOW()
  const primary = ACCOUNT_IBANS[0]!
  return [
    {
      recurring_id: 'rec-mock-rent',
      owner_citizen_id: MOCK_CITIZEN_ID,
      from_iban: primary,
      to_iban: SAMPLE_RECIPIENTS_META[1]!.iban,
      amount_minor: 650_00,
      reason: 'Alquiler piso Vespucci',
      interval_days: 30,
      status: 'active',
      next_charge_ms: now + 4 * DAY_MS,
      last_charge_ms: now - 26 * DAY_MS,
      created_ms: now - 160 * DAY_MS,
    },
    {
      recurring_id: 'rec-mock-garage',
      owner_citizen_id: MOCK_CITIZEN_ID,
      from_iban: primary,
      to_iban: SAMPLE_RECIPIENTS_META[3]!.iban,
      amount_minor: 185_00,
      reason: 'Cuota vehículo',
      interval_days: 14,
      status: 'active',
      next_charge_ms: now + 9 * DAY_MS,
      last_charge_ms: now - 5 * DAY_MS,
      created_ms: now - 74 * DAY_MS,
    },
    {
      recurring_id: 'rec-mock-market',
      owner_citizen_id: MOCK_CITIZEN_ID,
      from_iban: primary,
      to_iban: SAMPLE_RECIPIENTS_META[6]!.iban,
      amount_minor: 42_50,
      reason: 'Suministros tienda',
      interval_days: 7,
      status: 'active',
      next_charge_ms: now + 2 * DAY_MS,
      last_charge_ms: now - 5 * DAY_MS,
      created_ms: now - 42 * DAY_MS,
    },
    {
      recurring_id: 'rec-mock-paused',
      owner_citizen_id: MOCK_CITIZEN_ID,
      from_iban: primary,
      to_iban: SAMPLE_RECIPIENTS_META[4]!.iban,
      amount_minor: 75_00,
      reason: 'Seguro temporal',
      interval_days: 30,
      status: 'paused',
      next_charge_ms: now + 18 * DAY_MS,
      last_charge_ms: now - 12 * DAY_MS,
      created_ms: now - 96 * DAY_MS,
    },
    {
      recurring_id: 'rec-mock-cancelled',
      owner_citizen_id: MOCK_CITIZEN_ID,
      from_iban: primary,
      to_iban: SAMPLE_RECIPIENTS_META[2]!.iban,
      amount_minor: 19_99,
      reason: 'Club privado',
      interval_days: 30,
      status: 'cancelled',
      next_charge_ms: now - 20 * DAY_MS,
      last_charge_ms: now - 50 * DAY_MS,
      created_ms: now - 140 * DAY_MS,
    },
  ]
}

/* ---------------------------------------------------------------------------
   Mock cards — three cards mapped to different designs so the Tarjetas view
   demonstrates the design registry variety from the first render.

   - Main debit: Sonar Signature (brand anchor, active)
   - Virtual:    Aurora (premium design, active, for online purchases)
   - Savings:    Noir (locked state, demonstrates freeze UI)

   Full PAN + CVV live ONLY in this mock extension. Production BE must expose
   `pan_last_four` only; a dedicated authenticated endpoint returns PAN/CVV
   when the user explicitly requests reveal.
   --------------------------------------------------------------------------- */
export function buildMockCards(): BankCardMock[] {
  const accounts = buildMockAccounts()
  const primary = accounts[0]!
  const savings = accounts[1]!
  const holder = MOCK_DISPLAY_NAME.toUpperCase()
  const issuedMainMs = NOW() - 280 * DAY_MS
  const issuedVirtualMs = NOW() - 95 * DAY_MS
  const issuedSavingsMs = NOW() - 180 * DAY_MS
  const fourYears = 4 * 365 * DAY_MS

  return [
    {
      card_id: 'card-mock-signature',
      owner_citizen_id: MOCK_CITIZEN_ID,
      iban: primary.iban,
      status: 'active',
      pan_last_four: '5614',
      full_pan: '4287 1842 0739 5614',
      cvv: '428',
      expiry_ms: issuedMainMs + fourYears,
      created_ms: issuedMainMs,
      card_type: 'debit',
      design_id: 'sonar_signature',
      holder_name: holder,
      daily_limit_minor: 2_000_00,
      daily_spent_minor: 347_82,
      monthly_limit_minor: 25_000_00,
      monthly_spent_minor: 6_284_15,
    },
    {
      card_id: 'card-mock-virtual',
      owner_citizen_id: MOCK_CITIZEN_ID,
      iban: primary.iban,
      status: 'active',
      pan_last_four: '1027',
      full_pan: '4287 2901 8834 1027',
      cvv: '019',
      expiry_ms: issuedVirtualMs + fourYears,
      created_ms: issuedVirtualMs,
      card_type: 'virtual',
      design_id: 'aurora',
      holder_name: holder,
      daily_limit_minor: 500_00,
      daily_spent_minor: 48_90,
      monthly_limit_minor: 5_000_00,
      monthly_spent_minor: 1_124_60,
    },
    {
      card_id: 'card-mock-savings',
      owner_citizen_id: MOCK_CITIZEN_ID,
      iban: savings.iban,
      status: 'locked',
      pan_last_four: '8802',
      full_pan: '4287 3728 4619 8802',
      cvv: '734',
      expiry_ms: issuedSavingsMs + fourYears,
      created_ms: issuedSavingsMs,
      card_type: 'debit',
      design_id: 'noir',
      holder_name: holder,
      daily_limit_minor: 1_000_00,
      daily_spent_minor: 0,
      monthly_limit_minor: 10_000_00,
      monthly_spent_minor: 0,
    },
  ]
}

export function buildMockBootstrap(): BootstrapSnapshot {
  const portfolio = buildMockStockPortfolio()
  return {
    citizen_id: MOCK_CITIZEN_ID,
    accounts: buildMockAccounts(),
    recent_transactions: buildMockTransactions(),
    recent_recipients: buildMockRecentRecipients(),
    saved_recipients: SAMPLE_RECIPIENTS_META.filter((m) => m.alias).map((m) => ({
      counterpart_iban: m.iban,
      alias: m.alias,
      is_favorite: m.is_favorite,
      created_ms: NOW() - 60 * DAY_MS,
    })),
    loans: buildMockLoans(),
    recurring: buildMockRecurring(),
    portfolio: portfolio.holdings,
    cards: buildMockCards(),
    outstanding_notices: [],
    pending_tx_count: 1,
    server_now_ms: NOW(),
    bootstrap_id: generateUuidV4(),
    cached: false,
    duration_ms: 42,
  }
}

export function buildMockStockQuotes(): StockQuote[] {
  const now = NOW()
  return [
    {
      symbol: 'SNR',
      name: 'SONAR Holdings',
      sector: 'Financial infrastructure',
      price_minor: 142_35,
      change_24h_pct: 2.8,
      market_cap_minor: 12_400_000_00,
      volume_24h: 483_200,
      updated_ms: now,
    },
    {
      symbol: 'NOVA',
      name: 'Nova Logistics',
      sector: 'Transport',
      price_minor: 84_10,
      change_24h_pct: -1.2,
      market_cap_minor: 6_850_000_00,
      volume_24h: 201_940,
      updated_ms: now,
    },
    {
      symbol: 'ATLAS',
      name: 'Atlas Energy',
      sector: 'Energy',
      price_minor: 219_70,
      change_24h_pct: 4.4,
      market_cap_minor: 19_100_000_00,
      volume_24h: 612_004,
      updated_ms: now,
    },
    {
      symbol: 'CIV',
      name: 'Civic Retail Group',
      sector: 'Retail',
      price_minor: 31_85,
      change_24h_pct: 0.7,
      market_cap_minor: 2_140_000_00,
      volume_24h: 91_302,
      updated_ms: now,
    },
    {
      symbol: 'MEDX',
      name: 'MedEx Supplies',
      sector: 'Healthcare',
      price_minor: 56_40,
      change_24h_pct: -0.4,
      market_cap_minor: 4_300_000_00,
      volume_24h: 122_781,
      updated_ms: now,
    },
  ]
}

export function buildMockStockList(): StockListResponse {
  return {
    items: buildMockStockQuotes(),
    fetched_at_ms: NOW(),
  }
}

export function buildMockStockPortfolio(): StockPortfolioResponse {
  const now = NOW()
  const quotes = buildMockStockQuotes()
  const holdings: PortfolioHolding[] = [
    {
      holding_id: 'holding-snr-core',
      symbol: 'SNR',
      qty: 12,
      cost_basis_minor: 1_548_00,
      market_value_minor: (quotes.find((quote) => quote.symbol === 'SNR')?.price_minor ?? 0) * 12,
      delta_pct: 10.3,
      created_ms: now - 54 * DAY_MS,
    },
    {
      holding_id: 'holding-atlas-energy',
      symbol: 'ATLAS',
      qty: 4,
      cost_basis_minor: 810_00,
      market_value_minor: (quotes.find((quote) => quote.symbol === 'ATLAS')?.price_minor ?? 0) * 4,
      delta_pct: 8.5,
      created_ms: now - 31 * DAY_MS,
    },
    {
      holding_id: 'holding-nova-logistics',
      symbol: 'NOVA',
      qty: 9,
      cost_basis_minor: 801_00,
      market_value_minor: (quotes.find((quote) => quote.symbol === 'NOVA')?.price_minor ?? 0) * 9,
      delta_pct: -5.5,
      created_ms: now - 22 * DAY_MS,
    },
  ]
  const totalCostBasis = holdings.reduce((sum, holding) => sum + holding.cost_basis_minor, 0)
  const totalMarketValue = holdings.reduce((sum, holding) => sum + holding.market_value_minor, 0)
  const totalDelta = totalMarketValue - totalCostBasis
  return {
    holdings,
    total_cost_basis_minor: totalCostBasis,
    total_market_value_minor: totalMarketValue,
    total_delta_minor: totalDelta,
    total_delta_pct: totalCostBasis > 0 ? totalDelta / totalCostBasis * 100 : 0,
    fetched_at_ms: now,
  }
}

export function buildMockLoans(): Loan[] {
  const now = NOW()
  return [
    {
      loan_id: 'loan-personal-velocity',
      borrower_citizen_id: MOCK_CITIZEN_ID,
      product_name: 'Velocity Personal Credit',
      purpose: 'Personal liquidity reserve',
      principal_minor: 12_000_00,
      interest_bps: 740,
      term_days: 360,
      status: 'active',
      issued_ms: now - 126 * DAY_MS,
      due_ms: now + 234 * DAY_MS,
      outstanding_minor: 7_420_00,
      next_payment_minor: 620_00,
      next_payment_due_ms: now + 12 * DAY_MS,
      paid_installments: 5,
      total_installments: 12,
      risk_grade: 'A',
      collateral_label: null,
      created_ms: now - 128 * DAY_MS,
    },
    {
      loan_id: 'loan-vehicle-prime',
      borrower_citizen_id: MOCK_CITIZEN_ID,
      product_name: 'Vehicle Prime Financing',
      purpose: 'Vehicle purchase',
      principal_minor: 28_500_00,
      interest_bps: 590,
      term_days: 540,
      status: 'active',
      issued_ms: now - 86 * DAY_MS,
      due_ms: now + 454 * DAY_MS,
      outstanding_minor: 24_240_00,
      next_payment_minor: 1_575_00,
      next_payment_due_ms: now + 19 * DAY_MS,
      paid_installments: 2,
      total_installments: 18,
      risk_grade: 'B',
      collateral_label: 'Registered vehicle lien',
      created_ms: now - 90 * DAY_MS,
    },
    {
      loan_id: 'loan-starter-settled',
      borrower_citizen_id: MOCK_CITIZEN_ID,
      product_name: 'Starter Bridge Credit',
      purpose: 'Account opening bridge',
      principal_minor: 3_500_00,
      interest_bps: 420,
      term_days: 120,
      status: 'paid',
      issued_ms: now - 210 * DAY_MS,
      due_ms: now - 90 * DAY_MS,
      outstanding_minor: 0,
      next_payment_minor: 0,
      next_payment_due_ms: null,
      paid_installments: 4,
      total_installments: 4,
      risk_grade: 'A',
      collateral_label: null,
      created_ms: now - 212 * DAY_MS,
    },
  ]
}

export function buildMockLoanList(): LoanListResponse {
  return {
    items: buildMockLoans(),
    fetched_at_ms: NOW(),
  }
}

export function buildMockLoanInstallments(request: LoanInstallmentsRequest): LoanInstallmentsResponse {
  const loan = buildMockLoans().find((item) => item.loan_id === request.loan_id) ?? buildMockLoans()[0]
  const now = NOW()
  const total = loan?.total_installments ?? 0
  const monthlyMinor = total > 0 ? Math.max(0, Math.round((loan.principal_minor + Math.round(loan.principal_minor * loan.interest_bps / 10_000)) / total)) : 0
  const items: LoanInstallment[] = Array.from({ length: total }, (_, index) => {
    const sequence = index + 1
    const paid = sequence <= (loan?.paid_installments ?? 0)
    const dueMs = (loan?.issued_ms ?? now) + sequence * 30 * DAY_MS
    const interestMinor = Math.round(monthlyMinor * ((loan?.interest_bps ?? 0) / 10_000) / 3)
    return {
      installment_id: `${loan?.loan_id ?? 'loan'}-inst-${sequence.toString().padStart(2, '0')}`,
      loan_id: loan?.loan_id ?? request.loan_id,
      sequence,
      due_ms: dueMs,
      amount_minor: monthlyMinor,
      principal_minor: Math.max(0, monthlyMinor - interestMinor),
      interest_minor: interestMinor,
      status: paid ? 'paid' : dueMs < now ? 'late' : 'scheduled',
      paid_ms: paid ? dueMs - 1 * DAY_MS : null,
    }
  })
  return {
    loan_id: loan?.loan_id ?? request.loan_id,
    items,
    fetched_at_ms: now,
  }
}

export function buildMockAtmSession(): AtmSessionResponse {
  const now = NOW()
  const account = buildMockAccounts()[0]
  const card = buildMockCards()[0]
  return {
    terminal_id: 'ATM-LSIA-04',
    location_label: 'Los Santos International — North Hall',
    mode: 'simulation',
    online: true,
    hmac_ready: false,
    camera_check: 'clear',
    cash_available_minor: 86_500_00,
    daily_limit_minor: 2_000_00,
    remaining_limit_minor: 1_250_00,
    denominations: [
      { value_minor: 100_00, available_count: 83 },
      { value_minor: 50_00, available_count: 124 },
      { value_minor: 20_00, available_count: 210 },
      { value_minor: 10_00, available_count: 96 },
    ],
    account: {
      iban_masked: maskMockIban(account.iban),
      balance_minor: account.balance_minor,
      savings_minor: account.savings_minor,
      status: account.status,
    },
    card: {
      card_id: card.card_id,
      label: card.card_type === 'credit' ? 'SONAR Credit Card' : card.card_type === 'virtual' ? 'SONAR Virtual Card' : 'SONAR Debit Card',
      pan_masked: `•••• •••• •••• ${card.pan_last_four}`,
      status: card.status === 'active' ? 'active' : card.status === 'locked' ? 'frozen' : 'lost',
    },
    events: [
      {
        event_id: 'atm-evt-handshake',
        label: 'Terminal handshake verified',
        timestamp_ms: now - 72_000,
        severity: 'success',
      },
      {
        event_id: 'atm-evt-camera',
        label: 'Camera privacy zone clear',
        timestamp_ms: now - 48_000,
        severity: 'info',
      },
      {
        event_id: 'atm-evt-hmac',
        label: 'HMAC withdraw channel locked in preview',
        timestamp_ms: now - 21_000,
        severity: 'warning',
      },
    ],
    fetched_at_ms: now,
  }
}

export function buildMockRecentRecipientsResponse(): RecentRecipientsResponse {
  return {
    recipients: buildMockRecentRecipients(),
    fetched_at_ms: NOW(),
    cached: false,
    duration_ms: 18,
  }
}

export function buildMockAuditQuery(request: AuditQueryRequest): AuditQueryResponse {
  const limit = Math.max(1, Math.min(request.limit ?? 24, 50))
  const query = (request.query ?? '').trim().toLowerCase()
  const events = buildMockAuditEvents(request.scope)
    .filter((event) => request.status && request.status !== 'all' ? event.status === request.status : true)
    .filter((event) => request.event_type && request.event_type !== 'all' ? event.event_type === request.event_type : true)
    .filter((event) => {
      if (!query) return true
      return [
        event.audit_id,
        event.event_type,
        event.actor_cid_masked,
        event.correlation_id,
        event.counterparty_iban_masked,
        event.reason,
      ].some((value) => value?.toLowerCase().includes(query))
    })

  return {
    items: events.slice(0, limit),
    cursor_next: events.length > limit ? `audit-cursor-${limit}` : null,
    has_more: events.length > limit,
    fetched_at_ms: NOW(),
  }
}

export function buildMockComplianceFlagsQuery(request: ComplianceFlagsQueryRequest): ComplianceFlagsQueryResponse {
  const limit = Math.max(1, Math.min(request.limit ?? 24, 50))
  const query = (request.query ?? '').trim().toLowerCase()
  const flags = buildMockComplianceFlags()
    .filter((flag) => request.status && request.status !== 'all' ? flag.status === request.status : true)
    .filter((flag) => request.severity && request.severity !== 'all' ? flag.severity === request.severity : true)
    .filter((flag) => {
      if (!query) return true
      return [
        flag.flag_id,
        flag.event_type,
        flag.subject_cid_masked,
        flag.account_iban_masked,
        flag.counterparty_iban_masked,
        flag.reason,
        flag.assigned_unit,
        flag.correlation_id,
      ].some((value) => value?.toLowerCase().includes(query))
    })

  return {
    items: flags.slice(0, limit),
    cursor_next: flags.length > limit ? `compliance-cursor-${limit}` : null,
    has_more: flags.length > limit,
    fetched_at_ms: NOW(),
  }
}

export function buildMockBusinessTreasury(request: BusinessTreasuryQueryRequest): BusinessTreasurySnapshot {
  const now = NOW()
  const companyId = request.company_id || 'vanilla-unicorn'
  const movements = buildMockTransactions().slice(0, 6).map((tx, index) => ({
    movement_id: `biz-mov-${index.toString().padStart(4, '0')}`,
    event_type: tx.direction === 'in' ? 'business.treasury.credit' : 'business.treasury.debit',
    amount_minor: tx.amount_minor,
    currency: 'USD' as const,
    direction: tx.direction === 'in' ? 'in' as const : 'out' as const,
    counterparty_masked: tx.direction === 'in' ? maskMockIban(tx.from_iban) : maskMockIban(tx.to_iban),
    reason: tx.reason,
    status: tx.status === 'reconciling' ? 'pending' as const : tx.status === 'committed' || tx.status === 'pending' || tx.status === 'reverted' || tx.status === 'failed' ? tx.status : 'pending' as const,
    timestamp_ms: tx.timestamp_ms,
  }))

  return {
    company_id: companyId,
    company_name: companyId === 'vanilla-unicorn' ? 'Vanilla Unicorn Logistics' : 'Registered Business',
    role: 'owner',
    treasury_iban_masked: maskMockIban('ES12 9999 0000 1111 2222 9001'),
    balance_minor: 128_450_75,
    currency: 'USD',
    delta_4w_pct: 8.4,
    employee_count: 14,
    average_tenure_days: 96,
    total_payroll_month_minor: 24_800_00,
    recent_movements: movements,
    pending_approvals: [
      {
        approval_id: 'biz-appr-payroll-0001',
        type: 'payroll',
        requested_by_alias: 'Ops Manager',
        amount_minor: 8_450_00,
        currency: 'USD',
        created_at_ms: now - 3 * 60 * 60 * 1000,
        required_perm: 'sonar.bank.business.approval.vanilla-unicorn',
        status: 'pending',
      },
      {
        approval_id: 'biz-appr-recurring-0002',
        type: 'recurring',
        requested_by_alias: 'Treasury Desk',
        amount_minor: 1_200_00,
        currency: 'USD',
        created_at_ms: now - 11 * 60 * 60 * 1000,
        required_perm: 'sonar.bank.business.approval.vanilla-unicorn',
        status: 'pending',
      },
    ],
    fetched_at_ms: now,
  }
}

export function buildMockPayrollPreview(request: PayrollPreviewRequest): PayrollPreviewResponse {
  const now = NOW()
  const companyId = request.company_id || 'vanilla-unicorn'
  const lines = [
    { line_id: 'pay-line-ops-0001', employee_alias: 'Ops Lead', department: 'Operations', net_amount_minor: 2_850_00, currency: 'USD' as const, status: 'ready' as const },
    { line_id: 'pay-line-log-0002', employee_alias: 'Logistics Desk', department: 'Logistics', net_amount_minor: 2_240_00, currency: 'USD' as const, status: 'ready' as const },
    { line_id: 'pay-line-fin-0003', employee_alias: 'Finance Clerk', department: 'Finance', net_amount_minor: 1_980_00, currency: 'USD' as const, status: 'ready' as const },
    { line_id: 'pay-line-sec-0004', employee_alias: 'Security Shift', department: 'Security', net_amount_minor: 2_120_00, currency: 'USD' as const, status: 'held' as const },
  ]

  return {
    company_id: companyId,
    batch_id: `payroll-preview-${companyId}-${now}`,
    employee_count: 14,
    total_net_minor: lines.reduce((sum, line) => sum + line.net_amount_minor, 0),
    currency: 'USD',
    requires_approvals: 2,
    scheduled_for_ms: now + 24 * 60 * 60 * 1000,
    lines,
    fetched_at_ms: now,
  }
}

function buildMockComplianceFlags(): ComplianceFlag[] {
  const now = NOW()
  const transfers = buildMockTransactions().slice(0, 6)
  const transferFlags = transfers.map((tx, index): ComplianceFlag => {
    const score = 58 + index * 6
    const severity = score >= 88 ? 'critical' : score >= 76 ? 'high' : score >= 64 ? 'medium' : 'low'
    return {
      flag_id: `cmp-transfer-${index.toString().padStart(4, '0')}`,
      event_type: tx.direction === 'in' ? 'transfer.received' : 'transfer.committed',
      subject_cid_masked: 'CID-••••-AC01',
      account_iban_masked: maskMockIban(tx.from_iban),
      counterparty_iban_masked: tx.direction === 'in' ? maskMockIban(tx.from_iban) : maskMockIban(tx.to_iban),
      amount_minor: tx.amount_minor,
      currency: 'USD',
      severity,
      status: index % 4 === 0 ? 'open' : index % 4 === 1 ? 'reviewing' : index % 4 === 2 ? 'resolved' : 'dismissed',
      created_at_ms: tx.timestamp_ms,
      updated_at_ms: tx.timestamp_ms + 22 * 60 * 1000,
      risk_score: score,
      reason: index % 2 === 0 ? 'Velocity threshold' : 'Counterparty review',
      assigned_unit: index % 2 === 0 ? 'Financial integrity' : 'Government oversight',
      evidence_count: 2 + index,
      correlation_id: `corr-compliance-${tx.txn_id}`,
      details_json: JSON.stringify({
        reduced_shape: true,
        transaction_id: tx.txn_id,
        previous_flag_snapshot: index % 3 === 0,
        employee_balances_included: false,
      }),
    }
  })

  const adminFlags: ComplianceFlag[] = [
    {
      flag_id: 'cmp-admin-0001',
      event_type: 'compliance.flagRaised',
      subject_cid_masked: 'CID-••••-71B0',
      account_iban_masked: 'ES88 **** **** 1942',
      counterparty_iban_masked: null,
      amount_minor: null,
      currency: 'USD',
      severity: 'critical',
      status: 'open',
      created_at_ms: now - 42 * 60 * 1000,
      updated_at_ms: now - 18 * 60 * 1000,
      risk_score: 94,
      reason: 'Manual escalation',
      assigned_unit: 'Compliance command',
      evidence_count: 7,
      correlation_id: 'corr-compliance-admin-0001',
      details_json: JSON.stringify({ reduced_shape: true, operator_scope: 'P10', raw_identifiers_included: false }),
    },
  ]

  return [...adminFlags, ...transferFlags].sort((a, b) => b.created_at_ms - a.created_at_ms)
}

function buildMockAuditEvents(scope: AuditQueryRequest['scope']): AuditEvent[] {
  const base = buildMockTransactions().map((tx, index): AuditEvent => ({
    audit_id: `audit-transfer-${index.toString().padStart(4, '0')}`,
    event_type: tx.direction === 'in' ? 'transfer.received' : 'transfer.committed',
    timestamp_ms: tx.timestamp_ms,
    actor_cid_masked: 'CID-••••-AC01',
    amount_minor: tx.amount_minor,
    currency: 'USD',
    correlation_id: `corr-${tx.txn_id}`,
    counterparty_iban_masked: tx.direction === 'in' ? maskMockIban(tx.from_iban) : maskMockIban(tx.to_iban),
    status: tx.status === 'reconciling' ? 'pending' : tx.status,
    ace_perm: scope === 'government' ? 'sonar.bank.govt.audit.full' : scope === 'business' ? 'sonar.bank.empresas.vanilla-unicorn' : 'sonar.bank.audit.self',
    reason: tx.reason,
    scope_tag: scope,
    details_json: JSON.stringify({
      source: 'bank-ledger',
      transaction_id: tx.txn_id,
      privacy_scope: scope,
    }),
  }))

  const now = NOW()
  const extras: AuditEvent[] = [
    {
      audit_id: 'audit-compliance-self-0001',
      event_type: 'compliance.flagRaised',
      timestamp_ms: now - 3 * 60 * 60 * 1000,
      actor_cid_masked: 'CID-••••-AC01',
      amount_minor: null,
      currency: 'USD',
      correlation_id: 'corr-compliance-self-0001',
      counterparty_iban_masked: null,
      status: 'pending',
      ace_perm: scope === 'government' ? 'sonar.bank.govt.compliance.admin' : null,
      reason: 'Automated review marker',
      scope_tag: scope,
      details_json: JSON.stringify({ severity: 'low', reduced_shape: true }),
    },
    {
      audit_id: 'audit-business-payroll-0001',
      event_type: 'business.payroll.previewed',
      timestamp_ms: now - 28 * 60 * 60 * 1000,
      actor_cid_masked: 'CID-••••-71B0',
      amount_minor: 2_850_00,
      currency: 'USD',
      correlation_id: 'corr-business-payroll-0001',
      counterparty_iban_masked: null,
      status: 'committed',
      ace_perm: 'sonar.bank.empresas.vanilla-unicorn',
      reason: 'Payroll batch preview',
      scope_tag: scope,
      details_json: JSON.stringify({ company_id: 'vanilla-unicorn', employee_balances_included: false }),
    },
  ]

  return [...extras, ...base]
    .filter((event) => scope !== 'self' || event.scope_tag === 'self')
    .sort((a, b) => b.timestamp_ms - a.timestamp_ms)
}

function maskMockIban(iban: string): string {
  const compact = iban.replace(/\s+/g, '').toUpperCase()
  if (compact.length < 8) return '••••'
  return `${compact.slice(0, 4)} **** **** ${compact.slice(-4)}`
}

export function buildMockClientConfig(): ClientConfigSnapshot {
  return {
    resource_version: '1.0.1-r1-step-f',
    phase: 'A',
    bootstrap: { total_timeout_ms: 1500, max_accounts: 8, max_recipients: 8 },
    recent_recipients: { window_days: 90, limit: 8, preset_amounts: 3, cache_ttl_ms: 30_000 },
    perf_budgets: {
      bootstrap_p99_ms: 80,
      recent_recipients_p99_ms: 30,
      tier_1_read_p99_ms: 50,
      tier_2_write_p99_ms: 200,
    },
    features: { bootstrap_cache: true, recipients_cache: true },
  }
}

export async function simulateLatency(minMs = 120, maxMs = 320): Promise<void> {
  const ms = minMs + Math.random() * (maxMs - minMs)
  return new Promise((resolve) => window.setTimeout(resolve, ms))
}
