import type {
  GovtMovement,
  GovtMovementEntityKind,
  GovtMovementStatus,
  GovtMovementType,
  GovtTreasuryFilters,
  GovtTreasuryPage,
  GovtTreasuryStats,
} from '../contracts'

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

const rng = splitmix32(0xdeadbeef)

const CITIZEN_LABELS = [
  'Alex Reyes', 'Marina Volkov', 'Diego Marin', 'Noor Khan', 'Sofia Okafor',
  'Liam Tanaka', 'Omar Silva', 'Eva Bauer', 'Mateo Morales', 'Iris Park',
  'Theo Holm', 'Yara Vargas', 'Cleo Strand', 'Reza Caro', 'Maya Halloran',
]

const COMPANY_LABELS = [
  'Granja Verdana', 'Molino Norte S.L.', 'Bakery District Co.', 'Retail Nexus',
  'LogiChain Express', 'Arcadia Services', 'Prime Finance Group', 'Urban Mill Ltd.',
  'Sweet Origins Bakery', 'Corner Market Co.',
]

const TYPE_POOL: Array<{ type: GovtMovementType; dir: 'inflow' | 'outflow'; entity: GovtMovementEntityKind }> = [
  { type: 'tax_collection',      dir: 'inflow',  entity: 'citizen' },
  { type: 'tax_collection',      dir: 'inflow',  entity: 'company' },
  { type: 'fine_collected',      dir: 'inflow',  entity: 'citizen' },
  { type: 'transfer_in',         dir: 'inflow',  entity: 'citizen' },
  { type: 'transfer_out',        dir: 'outflow', entity: 'citizen' },
  { type: 'payroll_disbursement',dir: 'outflow', entity: 'company' },
  { type: 'subsidy_issued',      dir: 'outflow', entity: 'citizen' },
  { type: 'reconciliation',      dir: 'inflow',  entity: 'system' },
  { type: 'interest_accrued',    dir: 'inflow',  entity: 'system' },
]

const TYPE_DESCS: Record<GovtMovementType, string> = {
  tax_collection:       'Tax cycle collection settled',
  transfer_in:          'Incoming transfer credited to treasury',
  transfer_out:         'Outgoing transfer from treasury reserves',
  payroll_disbursement: 'Company payroll batch disbursement',
  fine_collected:       'Regulatory fine collected and settled',
  subsidy_issued:       'Citizen subsidy disbursement issued',
  reconciliation:       'Automated balance reconciliation',
  interest_accrued:     'Reserve interest accrued',
}

const STATUS_POOL: GovtMovementStatus[] = ['settled', 'settled', 'settled', 'settled', 'pending', 'reversed']

const NOW = Date.now()
const QUARTER_MS = 90 * 86_400_000

function pad(n: number, len: number) {
  return String(n).padStart(len, '0')
}

const ALL_MOVEMENTS: GovtMovement[] = Array.from({ length: 60 }, (_, i) => {
  const slot = TYPE_POOL[Math.floor(rng() * TYPE_POOL.length)] ?? TYPE_POOL[0]!
  const ageMs = Math.round(rng() * QUARTER_MS)
  const timestamp = NOW - ageMs
  const baseAmount = Math.round((500 + rng() * 49500) * 100)
  const entityPool = slot.entity === 'citizen' ? CITIZEN_LABELS : slot.entity === 'company' ? COMPANY_LABELS : ['System']
  const entityLabel = entityPool[Math.floor(rng() * entityPool.length)] ?? entityPool[0]!
  const entityId = slot.entity === 'citizen'
    ? `CID-${pad(Math.floor(rng() * 9000 + 1000), 4)}`
    : slot.entity === 'company'
      ? `CO-${pad(Math.floor(rng() * 15 + 1), 4)}`
      : 'SYS-001'

  return {
    id: `MOV-${pad(i + 1, 4)}`,
    referenceCode: `TRX-${String(Math.floor(rng() * 0xffffff + 0x100000)).toUpperCase().slice(0, 8)}`,
    timestamp,
    type: slot.type,
    status: STATUS_POOL[Math.floor(rng() * STATUS_POOL.length)] ?? 'settled',
    entityKind: slot.entity,
    entityId,
    entityLabel,
    description: TYPE_DESCS[slot.type],
    amount: baseAmount,
    direction: slot.dir,
  }
}).sort((a, b) => b.timestamp - a.timestamp)

const DATE_RANGE_MS: Record<string, number> = {
  today:   86_400_000,
  week:    7 * 86_400_000,
  month:   30 * 86_400_000,
  quarter: 90 * 86_400_000,
}

export function getTreasuryPageMock(filters: GovtTreasuryFilters, page: number, perPage: number): GovtTreasuryPage {
  const cutoff = NOW - (DATE_RANGE_MS[filters.dateRange] ?? QUARTER_MS)
  const q = filters.search.toLowerCase().trim()

  const filtered = ALL_MOVEMENTS.filter((m) => {
    if (m.timestamp < cutoff) return false
    if (filters.type !== 'all' && m.type !== filters.type) return false
    if (filters.entityKind !== 'all' && m.entityKind !== filters.entityKind) return false
    if (filters.direction !== 'all' && m.direction !== filters.direction) return false
    if (q && !m.entityLabel.toLowerCase().includes(q) && !m.referenceCode.toLowerCase().includes(q) && !m.entityId.toLowerCase().includes(q)) return false
    return true
  })

  let totalInflow = 0
  let totalOutflow = 0
  let taxCollected = 0
  let finesCollected = 0
  let subsidiesIssued = 0
  for (const m of filtered) {
    if (m.direction === 'inflow') totalInflow += m.amount
    else totalOutflow += m.amount
    if (m.type === 'tax_collection') taxCollected += m.amount
    if (m.type === 'fine_collected') finesCollected += m.amount
    if (m.type === 'subsidy_issued') subsidiesIssued += m.amount
  }

  const stats: GovtTreasuryStats = {
    totalInflow,
    totalOutflow,
    netBalance: totalInflow - totalOutflow,
    movementCount: filtered.length,
    taxCollected,
    finesCollected,
    subsidiesIssued,
  }

  const start = page * perPage
  const items = filtered.slice(start, start + perPage)

  return { items, totalCount: filtered.length, stats }
}
