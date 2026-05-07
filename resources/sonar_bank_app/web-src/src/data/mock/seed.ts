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
