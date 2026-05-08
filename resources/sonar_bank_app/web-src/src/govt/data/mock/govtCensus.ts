import type {
  GovtActivityType,
  GovtCensusFilters,
  GovtCitizenActivityEntry,
  GovtCitizenDetail,
  GovtCitizenFlag,
  GovtCitizenStatus,
  GovtCitizenSummary,
  GovtCitizenTaxStatus,
  GovtFlagSeverity,
  GovtFlagStatus,
  GovtRiskLevel,
  GovtTaxCompliance,
} from '../contracts'

/* ============================================================================
   Deterministic seed — same inputs always produce the same census so the
   panel feels stable across reloads. Splitmix32 is overkill for game mocks
   but keeps statuses, balances and timestamps reproducible.
   ============================================================================ */

function splitmix32(seed: number) {
  let s = seed >>> 0
  return () => {
    s = (s + 0x9e3779b9) >>> 0
    let t = s
    t = Math.imul(t ^ (t >>> 16), 0x21f0aaad)
    t = Math.imul(t ^ (t >>> 15), 0x735a2d97)
    return ((t ^ (t >>> 15)) >>> 0) / 4294967296
  }
}

const FIRST_NAMES = [
  'Alex', 'Marina', 'Noor', 'Diego', 'Sofia', 'Liam', 'Hana', 'Ezra',
  'Yara', 'Mateo', 'Iris', 'Theo', 'Lila', 'Omar', 'Eva', 'Kai',
  'Aria', 'Nico', 'Zara', 'Leo', 'Maya', 'Soren', 'Cleo', 'Reza',
]
const LAST_NAMES = [
  'Reyes', 'Volkov', 'Khan', 'Marin', 'Okafor', 'Tanaka', 'Silva', 'Bauer',
  'Fontaine', 'Castellanos', 'Park', 'Holm', 'Vargas', 'Eriksen', 'Morales', 'Adler',
  'Yusupov', 'Strand', 'Caro', 'Halloran',
]

const STATUS_BUCKETS: GovtCitizenStatus[] = [
  'active', 'active', 'active', 'active', 'active', 'active',
  'flagged', 'flagged',
  'sanctioned',
  'exempt',
]

const COMPLIANCE_BY_STATUS: Record<GovtCitizenStatus, GovtTaxCompliance[]> = {
  active: ['current', 'current', 'current', 'pending'],
  flagged: ['overdue', 'pending', 'overdue'],
  sanctioned: ['overdue', 'overdue'],
  exempt: ['exempt'],
}

const TAX_BRACKETS = ['T-A1', 'T-A2', 'T-B1', 'T-B2', 'T-C1', 'T-EX']

const ACTIVITY_TYPES: GovtActivityType[] = [
  'transfer_out',
  'transfer_in',
  'card_charge',
  'tax_payment',
  'flag_raised',
  'sanction_applied',
  'subsidy_received',
]

const FLAG_SUMMARIES = [
  'Unusual transfer velocity (24h window)',
  'Inbound flow above declared income',
  'Repeated cross-border counterparties',
  'Cash-equivalent ATM cycle',
  'Dormant account reactivated with high inflow',
  'Pattern matches historic structuring case',
]

const FLAG_SEVERITIES: GovtFlagSeverity[] = ['info', 'low', 'medium', 'high', 'critical']
const FLAG_STATUSES: GovtFlagStatus[] = ['open', 'reviewing', 'resolved', 'dismissed']

function pick<T>(rng: () => number, list: readonly T[]): T {
  return list[Math.floor(rng() * list.length)]!
}

function makeCid(rng: () => number): string {
  const hex = '0123456789ABCDEF'
  let out = 'CID-'
  for (let i = 0; i < 8; i++) out += hex[Math.floor(rng() * 16)]
  return out
}

function riskLevelFromScore(score: number): GovtRiskLevel {
  if (score < 25) return 'low'
  if (score < 55) return 'medium'
  if (score < 80) return 'high'
  return 'critical'
}

function buildSummary(index: number): GovtCitizenSummary {
  const rng = splitmix32(0xa11ce + index * 0x9e37)
  const status = pick(rng, STATUS_BUCKETS)
  const compliance = pick(rng, COMPLIANCE_BY_STATUS[status])
  const baseScore =
    status === 'sanctioned' ? 70 + Math.floor(rng() * 28)
    : status === 'flagged' ? 45 + Math.floor(rng() * 35)
    : status === 'exempt' ? Math.floor(rng() * 18)
    : 10 + Math.floor(rng() * 35)
  const flagCount =
    status === 'sanctioned' ? 2 + Math.floor(rng() * 4)
    : status === 'flagged' ? 1 + Math.floor(rng() * 3)
    : Math.floor(rng() * 1.6)
  const totalHoldings =
    status === 'exempt' ? 0
    : status === 'sanctioned' ? Math.floor(rng() * 250_00)
    : 50_00 + Math.floor(rng() * 480_000_00)
  const accountCount = 1 + Math.floor(rng() * 4)
  const lastActivityAt = Date.now() - Math.floor(rng() * 1000 * 60 * 60 * 24 * 14)
  const residencyDays = 30 + Math.floor(rng() * 1100)
  return {
    cid: makeCid(rng),
    alias: `${pick(rng, FIRST_NAMES)} ${pick(rng, LAST_NAMES)}`,
    status,
    taxCompliance: compliance,
    riskScore: baseScore,
    riskLevel: riskLevelFromScore(baseScore),
    totalHoldings,
    accountCount,
    flagCount,
    lastActivityAt,
    residencyDays,
  }
}

const SUMMARIES: GovtCitizenSummary[] = Array.from({ length: 56 }, (_, i) => buildSummary(i))

function buildActivity(rng: () => number, count: number): GovtCitizenActivityEntry[] {
  const out: GovtCitizenActivityEntry[] = []
  for (let i = 0; i < count; i++) {
    const type = pick(rng, ACTIVITY_TYPES)
    const sign =
      type === 'transfer_in' || type === 'subsidy_received' ? 1
      : type === 'flag_raised' || type === 'sanction_applied' ? 0
      : -1
    const amount = sign === 0 ? 0 : sign * (5_00 + Math.floor(rng() * 12_000_00))
    const counterparty =
      type === 'transfer_in' ? `CID-····-${(0x1000 + Math.floor(rng() * 0xefff)).toString(16).toUpperCase()}`
      : type === 'transfer_out' ? `CID-····-${(0x1000 + Math.floor(rng() * 0xefff)).toString(16).toUpperCase()}`
      : type === 'card_charge' ? pick(rng, ['Davis Auto', 'Vinewood Bites', 'Galaxy Towers', 'Pump-N-Go', 'Civic Pharmacy'])
      : undefined
    out.push({
      id: `act-${i}-${Math.floor(rng() * 0xffffff).toString(16)}`,
      timestamp: Date.now() - Math.floor(rng() * 1000 * 60 * 60 * 24 * 12),
      type,
      amount,
      description: type === 'tax_payment' ? `Quarterly tax — ${pick(rng, TAX_BRACKETS)}`
        : type === 'flag_raised' ? pick(rng, FLAG_SUMMARIES)
        : type === 'sanction_applied' ? 'Bureau sanction action'
        : type === 'subsidy_received' ? 'State subsidy disbursement'
        : type === 'card_charge' ? `Card charge — ${counterparty}`
        : type === 'transfer_in' ? `Inbound from ${counterparty}`
        : `Outbound to ${counterparty}`,
      counterparty,
    })
  }
  return out.sort((a, b) => b.timestamp - a.timestamp)
}

function buildFlags(rng: () => number, count: number): GovtCitizenFlag[] {
  return Array.from({ length: count }, (_, i) => ({
    id: `flg-${i}-${Math.floor(rng() * 0xffffff).toString(16)}`,
    raisedAt: Date.now() - Math.floor(rng() * 1000 * 60 * 60 * 24 * 30),
    severity: pick(rng, FLAG_SEVERITIES),
    status: pick(rng, FLAG_STATUSES),
    summary: pick(rng, FLAG_SUMMARIES),
  })).sort((a, b) => b.raisedAt - a.raisedAt)
}

function buildTax(rng: () => number, summary: GovtCitizenSummary): GovtCitizenTaxStatus {
  const obligation =
    summary.status === 'exempt' ? 0
    : Math.max(50_00, Math.floor(summary.totalHoldings * (0.04 + rng() * 0.06)))
  const paidPct =
    summary.taxCompliance === 'current' ? 1
    : summary.taxCompliance === 'pending' ? 0.4 + rng() * 0.4
    : summary.taxCompliance === 'exempt' ? 0
    : rng() * 0.35
  const paid = Math.floor(obligation * paidPct)
  return {
    bracketCode: pick(rng, TAX_BRACKETS),
    periodObligation: obligation,
    paid,
    outstanding: Math.max(0, obligation - paid),
  }
}

function buildDetail(summary: GovtCitizenSummary, index: number): GovtCitizenDetail {
  const rng = splitmix32(0xbeef + index * 0x1234)
  const activityCount = 6 + Math.floor(rng() * 8)
  return {
    ...summary,
    primaryIban: `SO${(20 + index).toString().padStart(2, '0')}SONAR${(1000 + index * 7).toString().padStart(4, '0')}${(50000 + index * 13).toString().padStart(8, '0')}`,
    recentActivity: buildActivity(rng, activityCount),
    flags: buildFlags(rng, summary.flagCount),
    taxStatus: buildTax(rng, summary),
  }
}

const DETAILS = new Map<string, GovtCitizenDetail>()
SUMMARIES.forEach((summary, i) => {
  DETAILS.set(summary.cid, buildDetail(summary, i))
})

/* ============================================================================
   Filtering helpers — pure functions consumed by the query layer.
   ============================================================================ */

export function listCensusMock(filters: GovtCensusFilters): GovtCitizenSummary[] {
  const needle = filters.search.trim().toLowerCase()
  return SUMMARIES.filter((summary) => {
    if (needle) {
      const haystack = `${summary.cid} ${summary.alias}`.toLowerCase()
      if (!haystack.includes(needle)) return false
    }
    if (filters.status !== 'all' && summary.status !== filters.status) return false
    if (filters.compliance !== 'all' && summary.taxCompliance !== filters.compliance) return false
    if (filters.riskLevel !== 'all' && summary.riskLevel !== filters.riskLevel) return false
    return true
  }).sort((a, b) => {
    const statusRank: Record<GovtCitizenStatus, number> = { sanctioned: 0, flagged: 1, active: 2, exempt: 3 }
    const ra = statusRank[a.status]
    const rb = statusRank[b.status]
    if (ra !== rb) return ra - rb
    return b.riskScore - a.riskScore
  })
}

export function getCensusDetailMock(cid: string): GovtCitizenDetail | undefined {
  return DETAILS.get(cid)
}
