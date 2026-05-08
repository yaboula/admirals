import type {
  GovtBusinessActivity,
  GovtBusinessActivityType,
  GovtBusinessDetail,
  GovtBusinessDirector,
  GovtBusinessFilters,
  GovtBusinessSector,
  GovtBusinessStatus,
  GovtBusinessSummary,
  GovtCitizenFlag,
  GovtCitizenTaxStatus,
  GovtFlagSeverity,
  GovtFlagStatus,
  GovtRiskLevel,
  GovtTaxCompliance,
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

const COMPANY_NAMES: string[] = [
  'Granja Verdana', 'Molino Norte S.L.', 'Bakery District Co.',
  'Retail Nexus', 'LogiChain Express', 'Arcadia Services',
  'Prime Finance Group', 'Harvest Fields', 'Urban Mill Ltd.',
  'Sweet Origins Bakery', 'Corner Market Co.', 'FastTrack Logistics',
  'Meridian Services', 'Apex Capital', 'Sundry Retail House',
]

const SECTORS: GovtBusinessSector[] = [
  'farming', 'milling', 'bakery', 'retail', 'logistics',
  'services', 'finance', 'farming', 'milling', 'bakery',
  'retail', 'logistics', 'services', 'finance', 'retail',
]

const STATUS_BUCKETS: GovtBusinessStatus[] = [
  'active', 'active', 'active', 'active', 'active', 'active',
  'active', 'active', 'active',
  'frozen', 'frozen',
  'liquidating',
  'active', 'active', 'active',
]

const COMPLIANCE_BUCKETS: GovtTaxCompliance[] = [
  'current', 'current', 'current', 'current', 'current', 'current',
  'overdue', 'overdue',
  'pending',
  'current', 'overdue',
  'overdue',
  'current', 'current', 'exempt',
]

const RISK_LEVELS: GovtRiskLevel[] = [
  'low', 'low', 'low', 'medium', 'medium', 'low',
  'high', 'low', 'medium',
  'critical', 'high',
  'critical',
  'low', 'medium', 'low',
]

const NOW = Date.now()

function seedRng(companyId: string) {
  let h = 0x12345678
  for (let i = 0; i < companyId.length; i++) h = Math.imul(h ^ companyId.charCodeAt(i), 0x9e3779b9)
  return splitmix32(h)
}

function makeIban(rng: () => number): string {
  const digits = Array.from({ length: 12 }, () => Math.floor(rng() * 10)).join('')
  return `AD-${digits.slice(0, 4)}-${digits.slice(4, 8)}-${digits.slice(8, 12)}`
}

function buildSummary(idx: number): GovtBusinessSummary {
  const companyId = `CO-${String(idx + 1).padStart(4, '0')}`
  const rng = seedRng(companyId)
  const riskScore = Math.round(20 + rng() * 78)
  const treasury = Math.round((5_000 + rng() * 995_000) * 100)
  const operatingDays = Math.round(30 + rng() * 1460)
  return {
    companyId,
    name: COMPANY_NAMES[idx] ?? `Company ${idx + 1}`,
    status: STATUS_BUCKETS[idx] ?? 'active',
    sector: SECTORS[idx] ?? 'other',
    foundedAt: NOW - operatingDays * 86_400_000,
    employeeCount: Math.round(1 + rng() * 30),
    treasury,
    taxCompliance: COMPLIANCE_BUCKETS[idx] ?? 'current',
    riskLevel: RISK_LEVELS[idx] ?? 'low',
    riskScore,
    flagCount: Math.floor(rng() * 4),
    lastActivityAt: NOW - Math.round(rng() * 72 * 3_600_000),
  }
}

const SUMMARIES: GovtBusinessSummary[] = Array.from({ length: 15 }, (_, i) => buildSummary(i))

export function listBusinessMock(filters: GovtBusinessFilters): GovtBusinessSummary[] {
  return SUMMARIES.filter((c) => {
    if (filters.status !== 'all' && c.status !== filters.status) return false
    if (filters.sector !== 'all' && c.sector !== filters.sector) return false
    if (filters.compliance !== 'all' && c.taxCompliance !== filters.compliance) return false
    const q = filters.search.toLowerCase().trim()
    if (q && !c.name.toLowerCase().includes(q) && !c.companyId.toLowerCase().includes(q)) return false
    return true
  })
}

const DIRECTOR_FIRST = ['Alex', 'Marina', 'Diego', 'Noor', 'Sofia', 'Liam', 'Omar', 'Eva']
const DIRECTOR_LAST = ['Reyes', 'Volkov', 'Marin', 'Khan', 'Okafor', 'Tanaka', 'Silva', 'Bauer']
const DIRECTOR_ROLES: Array<GovtBusinessDirector['role']> = ['founder', 'director', 'co-founder', 'director']

const ACTIVITY_TYPES: GovtBusinessActivityType[] = [
  'payroll_processed', 'tax_payment', 'transfer_in',
  'transfer_out', 'employee_hired', 'employee_fired',
]

const ACTIVITY_DESCS: Record<GovtBusinessActivityType, string> = {
  payroll_processed: 'Monthly payroll disbursement',
  tax_payment: 'Corporate tax cycle payment',
  transfer_in: 'Incoming revenue transfer',
  transfer_out: 'Outgoing supplier payment',
  employee_hired: 'New employee onboarded',
  employee_fired: 'Employee contract terminated',
  flag_raised: 'Compliance flag raised',
  sanction_applied: 'Bureau sanction applied',
}

const SEV_BUCKETS: GovtFlagSeverity[] = ['info', 'low', 'medium', 'high', 'critical']
const FLAG_STATUS_BUCKETS: GovtFlagStatus[] = ['open', 'reviewing', 'resolved', 'dismissed']

export function getBusinessDetailMock(companyId: string): GovtBusinessDetail | undefined {
  const summary = SUMMARIES.find((s) => s.companyId === companyId)
  if (!summary) return undefined

  const rng = seedRng(companyId + '_detail')
  const directorCount = 1 + Math.floor(rng() * 3)
  const directors: GovtBusinessDirector[] = Array.from({ length: directorCount }, (_, i) => {
    const fn = DIRECTOR_FIRST[Math.floor(rng() * DIRECTOR_FIRST.length)] ?? 'Alex'
    const ln = DIRECTOR_LAST[Math.floor(rng() * DIRECTOR_LAST.length)] ?? 'Reyes'
    return {
      cid: `CID-${String(Math.floor(rng() * 9000 + 1000)).padStart(4, '0')}`,
      alias: `${fn} ${ln}`,
      role: DIRECTOR_ROLES[i % DIRECTOR_ROLES.length] ?? 'director',
      joinedAt: summary.foundedAt + Math.round(rng() * 30 * 86_400_000),
    }
  })

  const activity: GovtBusinessActivity[] = Array.from({ length: 8 }, (_, i) => {
    const type = ACTIVITY_TYPES[Math.floor(rng() * ACTIVITY_TYPES.length)] ?? 'transfer_in'
    const isMonetary = type === 'payroll_processed' || type === 'tax_payment' || type === 'transfer_in' || type === 'transfer_out'
    return {
      id: `ACT-${companyId}-${i}`,
      timestamp: NOW - Math.round(rng() * 30 * 86_400_000),
      type,
      amount: isMonetary ? Math.round((1_000 + rng() * 50_000) * 100) * (type === 'transfer_out' || type === 'payroll_processed' || type === 'tax_payment' ? -1 : 1) : 0,
      description: ACTIVITY_DESCS[type],
    }
  }).sort((a, b) => b.timestamp - a.timestamp)

  const flags: GovtCitizenFlag[] = summary.flagCount > 0
    ? Array.from({ length: summary.flagCount }, (_, i) => ({
        id: `FLAG-${companyId}-${i}`,
        raisedAt: NOW - Math.round(rng() * 14 * 86_400_000),
        severity: SEV_BUCKETS[Math.floor(rng() * SEV_BUCKETS.length)] ?? 'info',
        status: FLAG_STATUS_BUCKETS[Math.floor(rng() * 2)] ?? 'open',
        summary: 'Unusual transaction pattern detected in corporate account movements.',
      }))
    : []

  const operatingDays = Math.round((NOW - summary.foundedAt) / 86_400_000)
  const monthlyObligation = Math.round(summary.treasury * 0.015)
  const taxPaid = Math.round(monthlyObligation * (0.4 + rng() * 0.6))

  const taxStatus: GovtCitizenTaxStatus = {
    bracketCode: summary.sector === 'finance' ? 'CORP-B' : summary.sector === 'farming' ? 'CORP-A' : 'CORP-S',
    periodObligation: monthlyObligation,
    paid: taxPaid,
    outstanding: Math.max(0, monthlyObligation - taxPaid),
  }

  return {
    ...summary,
    ibanPrimary: makeIban(rng),
    directors,
    recentActivity: activity,
    flags,
    payrollMonthly: Math.round((2_000 + rng() * 8_000) * summary.employeeCount * 100),
    taxStatus,
    operatingDays,
  }
}
