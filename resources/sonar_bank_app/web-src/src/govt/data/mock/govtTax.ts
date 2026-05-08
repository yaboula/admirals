import { generateUuidV4 } from '@/lib/utils'
import type {
  GovtForceCollectionRequest,
  GovtSaveBracketsRequest,
  GovtTaxBracket,
  GovtTaxCycleStats,
  GovtTaxPolicyChange,
} from '../contracts'

/* ============================================================================
   SONAR Treasury Bureau — Tax Engine mock store.
   Backend contract REQ-FE-014 OPEN. Mock mirrors Backend contract shape.
   ============================================================================ */

const TOTAL_CITIZENS = 56
const CYCLE_DURATION_DAYS = 14
const CYCLE_START_OFFSET_DAYS = 11
const NOW = Date.now()
const CYCLE_START_MS = NOW - CYCLE_START_OFFSET_DAYS * 86_400_000

const INITIAL_BRACKETS: GovtTaxBracket[] = [
  { id: 'basic', code: 'T-I', label: 'BÁSICO', incomeMin: 0, incomeMax: 1_500_000, rate: 8, populationShare: 0.35, affectedCount: Math.round(TOTAL_CITIZENS * 0.35) },
  { id: 'standard', code: 'T-II', label: 'ESTÁNDAR', incomeMin: 1_500_000, incomeMax: 5_000_000, rate: 18, populationShare: 0.45, affectedCount: Math.round(TOTAL_CITIZENS * 0.45) },
  { id: 'premium', code: 'T-III', label: 'PREMIUM', incomeMin: 5_000_000, incomeMax: 15_000_000, rate: 28, populationShare: 0.15, affectedCount: Math.round(TOTAL_CITIZENS * 0.15) },
  { id: 'elite', code: 'T-IV', label: 'ÉLITE', incomeMin: 15_000_000, incomeMax: null, rate: 38, populationShare: 0.05, affectedCount: Math.round(TOTAL_CITIZENS * 0.05) },
]

const STATE = {
  brackets: INITIAL_BRACKETS.map((b) => ({ ...b })),
  policyLog: [] as GovtTaxPolicyChange[],
  forcedCollectionCount: 0,
}

STATE.policyLog.push(
  {
    id: generateUuidV4(),
    operatorAlias: 'Min-Eco-001',
    changedAt: CYCLE_START_MS - 8 * 86_400_000,
    delta: [{ tierId: 'elite', oldRate: 36, newRate: 38 }],
    reason: 'Ajuste techo élite por resolución presupuestaria 2026-Q2. Aprobado en sesión plenaria.',
  },
  {
    id: generateUuidV4(),
    operatorAlias: 'Min-Eco-001',
    changedAt: CYCLE_START_MS - 22 * 86_400_000,
    delta: [
      { tierId: 'basic', oldRate: 7, newRate: 8 },
      { tierId: 'standard', oldRate: 16, newRate: 18 },
    ],
    reason: 'Revisión trimestral T1-2026. Incremento mínimo para cubrir déficit infraestructura.',
  },
  {
    id: generateUuidV4(),
    operatorAlias: 'Min-Eco-002',
    changedAt: CYCLE_START_MS - 45 * 86_400_000,
    delta: [{ tierId: 'premium', oldRate: 25, newRate: 28 }],
    reason: 'Armonización franja premium con índice IPC Q4-2025. Efectivo próximo ciclo.',
  },
)

/* ---- collection data ---------------------------------------------------- */

function buildCycleStats(): GovtTaxCycleStats {
  const obligationPerDay = 84_000_00 // ~$84k/day aggregate

  const dailySeries = Array.from({ length: CYCLE_DURATION_DAYS }, (_, i) => {
    const obligationCents = obligationPerDay + ((i * 1237 + 3) % 7) * 2_000_00
    if (i >= CYCLE_START_OFFSET_DAYS) {
      return { dayIndex: i, collectedCents: 0, obligationCents }
    }
    const variance = ((i * 1019 + 7) % 15) * 1_000_00
    const collected = obligationCents * 0.92 + variance - 3_000_00
    return { dayIndex: i, collectedCents: Math.max(0, collected), obligationCents }
  })

  const totalObligationCents = dailySeries.reduce((s, d) => s + d.obligationCents, 0)
  const totalCollectedCents = dailySeries.reduce((s, d) => s + d.collectedCents, 0)
  const collectedTodayCents = dailySeries.find((d) => d.dayIndex === CYCLE_START_OFFSET_DAYS - 1)?.collectedCents ?? 0

  return {
    cycleId: `CYC-2026-NOV-A`,
    cycleStartMs: CYCLE_START_MS,
    cycleDurationDays: CYCLE_DURATION_DAYS,
    totalObligationCents,
    totalCollectedCents,
    collectedTodayCents,
    dailySeries,
  }
}

/* ---- public API ---------------------------------------------------------- */

export function getBracketsMock(): GovtTaxBracket[] {
  return STATE.brackets.map((b) => ({ ...b }))
}

export function getCycleStatsMock(): GovtTaxCycleStats {
  return buildCycleStats()
}

export function getPolicyLogMock(): GovtTaxPolicyChange[] {
  return STATE.policyLog.slice().sort((a, b) => b.changedAt - a.changedAt)
}

export async function saveBracketsMock(req: GovtSaveBracketsRequest): Promise<void> {
  await new Promise((r) => setTimeout(r, 640))
  const delta: GovtTaxPolicyChange['delta'] = []
  for (const update of req.brackets) {
    const existing = STATE.brackets.find((b) => b.id === update.id)
    if (existing && existing.rate !== update.rate) {
      delta.push({ tierId: update.id, oldRate: existing.rate, newRate: update.rate })
      existing.rate = update.rate
    }
  }
  if (delta.length > 0) {
    STATE.policyLog.unshift({
      id: req.idempotencyKey,
      operatorAlias: 'Bureau-Op-001',
      changedAt: Date.now(),
      delta,
      reason: req.reason,
    })
  }
}

export async function forceCollectionMock(req: GovtForceCollectionRequest): Promise<void> {
  await new Promise((r) => setTimeout(r, 900))
  STATE.forcedCollectionCount++
  STATE.policyLog.unshift({
    id: req.idempotencyKey,
    operatorAlias: 'Bureau-Op-001',
    changedAt: Date.now(),
    delta: [],
    reason: `[FORZADO] ${req.reason}`,
  })
}
