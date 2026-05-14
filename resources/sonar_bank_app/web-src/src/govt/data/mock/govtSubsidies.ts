import type {
  GovtGrantSubsidyRequest,
  GovtSubsidyDisbursement,
  GovtSubsidyFilters,
  GovtSubsidyProgram,
  GovtSubsidyProgramDetail,
  GovtSubsidyRecipientKind,
  GovtSubsidyStats,
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

const rng = splitmix32(0xcafebabe)
const NOW = Date.now()

const CITIZEN_LABELS = [
  'Alex Reyes', 'Marina Volkov', 'Diego Marin', 'Noor Khan', 'Sofia Okafor',
  'Liam Tanaka', 'Omar Silva', 'Eva Bauer', 'Mateo Morales', 'Iris Park',
]
const COMPANY_LABELS = [
  'Granja Verdana', 'Molino Norte S.L.', 'Bakery District Co.', 'Urban Mill Ltd.',
  'Sweet Origins Bakery',
]

const PROGRAMS: GovtSubsidyProgram[] = [
  {
    programId: 'PRG-001',
    code: 'FOOD-BASIC-01',
    name: 'Basic Food Support',
    type: 'food',
    status: 'active',
    budget: 500_000_00,
    disbursed: 312_400_00,
    beneficiaryCount: 87,
    startDate: NOW - 120 * 86400000,
    endDate: NOW + 60 * 86400000,
    description: 'Monthly food basket subsidy for low-income households registered in the census.',
  },
  {
    programId: 'PRG-002',
    code: 'AGRI-SEED-02',
    name: 'Agricultural Seed Grant',
    type: 'agricultural',
    status: 'active',
    budget: 800_000_00,
    disbursed: 245_000_00,
    beneficiaryCount: 14,
    startDate: NOW - 90 * 86400000,
    endDate: NOW + 180 * 86400000,
    description: 'Seed and fertilizer grants for registered farming sector businesses to boost local production.',
  },
  {
    programId: 'PRG-003',
    code: 'EMRG-FLOOD-03',
    name: 'Emergency Flood Relief',
    type: 'emergency',
    status: 'completed',
    budget: 300_000_00,
    disbursed: 298_500_00,
    beneficiaryCount: 52,
    startDate: NOW - 200 * 86400000,
    endDate: NOW - 30 * 86400000,
    description: 'One-time emergency disbursement to citizens and businesses affected by the eastern district flooding.',
  },
  {
    programId: 'PRG-004',
    code: 'HLTH-ACCESS-04',
    name: 'Healthcare Access Fund',
    type: 'medical',
    status: 'active',
    budget: 1_200_000_00,
    disbursed: 634_200_00,
    beneficiaryCount: 118,
    startDate: NOW - 60 * 86400000,
    endDate: null,
    description: 'Ongoing medical cost offset for census-registered citizens with flagged health compliance gaps.',
  },
  {
    programId: 'PRG-005',
    code: 'EDU-YOUTH-05',
    name: 'Youth Education Boost',
    type: 'education',
    status: 'proposed',
    budget: 600_000_00,
    disbursed: 0,
    beneficiaryCount: 0,
    startDate: NOW + 14 * 86400000,
    endDate: NOW + 180 * 86400000,
    description: 'Proposed scholarship program for youth citizens — pending founder ratification before disbursement.',
  },
  {
    programId: 'PRG-006',
    code: 'EMPL-RESTART-06',
    name: 'Employment Restart Grants',
    type: 'employment',
    status: 'paused',
    budget: 400_000_00,
    disbursed: 98_000_00,
    beneficiaryCount: 22,
    startDate: NOW - 150 * 86400000,
    endDate: null,
    description: 'Grants to recently unemployed citizens for retraining. Paused pending budget review.',
  },
  {
    programId: 'PRG-007',
    code: 'HOUS-RENT-07',
    name: 'Rental Assistance Scheme',
    type: 'housing',
    status: 'active',
    budget: 900_000_00,
    disbursed: 521_800_00,
    beneficiaryCount: 63,
    startDate: NOW - 45 * 86400000,
    endDate: NOW + 90 * 86400000,
    description: 'Monthly rental offset for census citizens in the lower income bracket.',
  },
]

function makeDisbursements(program: GovtSubsidyProgram, count: number): GovtSubsidyDisbursement[] {
  return Array.from({ length: count }, (_, i) => {
    const isCompany = program.type === 'agricultural' && rng() > 0.5
    const pool = isCompany ? COMPANY_LABELS : CITIZEN_LABELS
    const label = pool[Math.floor(rng() * pool.length)] ?? pool[0]!
    const id = isCompany
      ? `CO-${String(Math.floor(rng() * 15 + 1)).padStart(4, '0')}`
      : `CID-${String(Math.floor(rng() * 9000 + 1000)).padStart(4, '0')}`
    const amount = Math.round((500 + rng() * 9500) * 100)
    const ageMs = Math.round(rng() * 90 * 86400000)
    const sPool: GovtSubsidyDisbursement['status'][] = ['confirmed', 'confirmed', 'confirmed', 'pending', 'reversed']
    return {
      id: `DSB-${program.code}-${String(i + 1).padStart(3, '0')}`,
      programCode: program.code,
      recipientId: id,
      recipientLabel: label,
      recipientKind: (isCompany ? 'company' : 'citizen') as GovtSubsidyRecipientKind,
      amount,
      disbursedAt: NOW - ageMs,
      note: `${program.name} disbursement #${i + 1}`,
      status: sPool[Math.floor(rng() * sPool.length)] ?? 'confirmed',
    }
  }).sort((a, b) => b.disbursedAt - a.disbursedAt)
}

const DISBURSEMENTS_MAP: Record<string, GovtSubsidyDisbursement[]> = {}
for (const p of PROGRAMS) {
  const count = p.status === 'proposed' ? 0 : Math.max(1, Math.floor(p.beneficiaryCount * 0.3))
  DISBURSEMENTS_MAP[p.programId] = makeDisbursements(p, Math.min(count, 12))
}

export function listSubsidyProgramsMock(filters: GovtSubsidyFilters): GovtSubsidyProgram[] {
  const q = filters.search.toLowerCase().trim()
  return PROGRAMS.filter((p) => {
    if (filters.type !== 'all' && p.type !== filters.type) return false
    if (filters.status !== 'all' && p.status !== filters.status) return false
    if (q && !p.name.toLowerCase().includes(q) && !p.code.toLowerCase().includes(q)) return false
    return true
  })
}

export function getSubsidyDetailMock(programId: string): GovtSubsidyProgramDetail | undefined {
  const prog = PROGRAMS.find((p) => p.programId === programId)
  if (!prog) return undefined
  return {
    ...prog,
    recentDisbursements: DISBURSEMENTS_MAP[programId] ?? [],
  }
}

export function getSubsidyStatsMock(): GovtSubsidyStats {
  let totalDisbursed = 0
  let totalBudget = 0
  let activeProgramCount = 0
  let totalBeneficiaries = 0
  let pendingDisbursements = 0
  for (const p of PROGRAMS) {
    totalBudget += p.budget
    totalDisbursed += p.disbursed
    if (p.status === 'active') {
      activeProgramCount++
      totalBeneficiaries += p.beneficiaryCount
    }
  }
  for (const list of Object.values(DISBURSEMENTS_MAP)) {
    for (const d of list) {
      if (d.status === 'pending') pendingDisbursements++
    }
  }
  return { totalDisbursed, totalBudget, activeProgramCount, totalBeneficiaries, pendingDisbursements }
}

export async function grantSubsidyMock(req: GovtGrantSubsidyRequest): Promise<GovtSubsidyDisbursement> {
  await new Promise((r) => setTimeout(r, 520))
  const program = PROGRAMS.find((p) => p.programId === req.programId)
  if (!program || program.status !== 'active') throw new Error('PROGRAM_NOT_ACTIVE')
  if (req.amount <= 0 || program.disbursed + req.amount > program.budget) throw new Error('INVALID_AMOUNT')
  const disbursement: GovtSubsidyDisbursement = {
    id: req.idempotencyKey,
    programCode: program.code,
    recipientId: req.recipientId,
    recipientLabel: req.recipientId,
    recipientKind: req.recipientKind,
    amount: req.amount,
    disbursedAt: Date.now(),
    note: req.note,
    status: 'confirmed',
  }
  program.disbursed += req.amount
  program.beneficiaryCount += 1
  DISBURSEMENTS_MAP[program.programId] = [disbursement, ...(DISBURSEMENTS_MAP[program.programId] ?? [])].slice(0, 12)
  return disbursement
}
