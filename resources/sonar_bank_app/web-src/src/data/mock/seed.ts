import type {
  Account,
  BootstrapSnapshot,
  ClientConfigSnapshot,
  RecentRecipient,
  RecentRecipientsResponse,
  Transaction,
} from '@/data/contracts'
import { generateUuidV4 } from '@/lib/utils'

const NOW = (): number => Date.now()
const DAY_MS = 24 * 60 * 60 * 1000

export const MOCK_CITIZEN_ID = 'CIT-7F4A-9B2D-AC01'

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
  const meta = SAMPLE_RECIPIENTS_META.find((m) => m.iban === iban)
  return meta?.initials ?? '··'
}

const SAMPLE_TX_DATA: Array<{
  amount: number
  reason: string | null
  direction: Transaction['direction']
  status: Transaction['status']
  hoursAgo: number
  fromIdx: number
  toIdx: number
}> = [
  { amount: 250_00,  reason: 'Mitad alquiler abril',     direction: 'out', status: 'committed', hoursAgo: 6,    fromIdx: 0, toIdx: 1 },
  { amount: 1_250_00, reason: 'Salario mensual',         direction: 'in',  status: 'committed', hoursAgo: 18,   fromIdx: 9, toIdx: 0 },
  { amount: 38_50,   reason: 'Cena domingo',             direction: 'out', status: 'committed', hoursAgo: 36,   fromIdx: 0, toIdx: 0 },
  { amount: 120_00,  reason: 'Devolución viaje',         direction: 'in',  status: 'committed', hoursAgo: 50,   fromIdx: 5, toIdx: 0 },
  { amount: 75_00,   reason: 'Material taller',          direction: 'out', status: 'pending',   hoursAgo: 2,    fromIdx: 0, toIdx: 3 },
  { amount: 12_50,   reason: 'Cafés semana',             direction: 'out', status: 'committed', hoursAgo: 72,   fromIdx: 0, toIdx: 2 },
  { amount: 500_00,  reason: 'Cuota préstamo coche',     direction: 'out', status: 'committed', hoursAgo: 96,   fromIdx: 0, toIdx: 8 },
  { amount: 9_99,    reason: 'Suscripción mensual',      direction: 'out', status: 'committed', hoursAgo: 120,  fromIdx: 0, toIdx: 7 },
]

const ACCOUNT_IBANS = ['ES12 9999 0000 1111 2222 3333', 'ES12 9999 0000 1111 2222 4444']

export function buildMockTransactions(): Transaction[] {
  const now = NOW()
  return SAMPLE_TX_DATA.map((t, i) => {
    const fromIban =
      t.direction === 'in'
        ? SAMPLE_RECIPIENTS_META[t.fromIdx % SAMPLE_RECIPIENTS_META.length]!.iban
        : ACCOUNT_IBANS[0]!
    const toIban =
      t.direction === 'in'
        ? ACCOUNT_IBANS[0]!
        : SAMPLE_RECIPIENTS_META[t.toIdx % SAMPLE_RECIPIENTS_META.length]!.iban
    return {
      txn_id: `txn-mock-${i.toString().padStart(4, '0')}`,
      from_iban: fromIban,
      to_iban: toIban,
      amount_minor: t.amount,
      reason: t.reason,
      direction: t.direction,
      status: t.status,
      timestamp_ms: now - t.hoursAgo * 60 * 60 * 1000,
    }
  })
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

export function buildMockBootstrap(): BootstrapSnapshot {
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
    loans: [],
    recurring: [],
    portfolio: [],
    cards: [],
    outstanding_notices: [],
    pending_tx_count: 1,
    server_now_ms: NOW(),
    bootstrap_id: generateUuidV4(),
    cached: false,
    duration_ms: 42,
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
