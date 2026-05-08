import { generateUuidV4 } from '@/lib/utils'
import { getCensusDetailMock, listCensusMock } from './govtCensus'
import type {
  GovtApplyFineRequest,
  GovtCloseFlagRequest,
  GovtFlagQueueFilters,
  GovtFlagQueueItem,
  GovtFreezeAccountsRequest,
  GovtLiftFreezeRequest,
  GovtSanctionAction,
} from '../contracts'

/* ============================================================================
   SONAR Treasury Bureau — Sanctions module mock store (mutable).
   Backend contract REQ-FE-009 OPEN. Until callbacks ship, mutations operate
   on this in-memory store; queryClient invalidations refresh listeners.
   When real callbacks land, swap the inner functions — public hook signatures
   stay stable.
   ============================================================================ */

const STATE = {
  flags: new Map<string, GovtFlagQueueItem>(),
  actions: [] as GovtSanctionAction[],
  frozenCitizens: new Set<string>(),
  citizenStatusOverrides: new Map<string, GovtFlagQueueItem['citizenStatus']>(),
}

function seedFromCensus() {
  if (STATE.flags.size > 0) return
  const allCitizens = listCensusMock({ search: '', status: 'all', compliance: 'all', riskLevel: 'all' })
  for (const summary of allCitizens) {
    const detail = getCensusDetailMock(summary.cid)
    if (!detail) continue
    for (const flag of detail.flags) {
      STATE.flags.set(flag.id, {
        flagId: flag.id,
        citizenCid: summary.cid,
        citizenAlias: summary.alias,
        citizenStatus: summary.status,
        citizenRiskLevel: summary.riskLevel,
        raisedAt: flag.raisedAt,
        severity: flag.severity,
        status: flag.status,
        summary: flag.summary,
      })
    }
  }
}

seedFromCensus()

const SEVERITY_RANK: Record<GovtFlagQueueItem['severity'], number> = {
  critical: 0,
  high: 1,
  medium: 2,
  low: 3,
  info: 4,
}

const STATUS_RANK: Record<GovtFlagQueueItem['status'], number> = {
  open: 0,
  reviewing: 1,
  resolved: 2,
  dismissed: 3,
}

export function listFlagQueueMock(filters: GovtFlagQueueFilters): GovtFlagQueueItem[] {
  const needle = filters.search.trim().toLowerCase()
  return Array.from(STATE.flags.values())
    .filter((flag) => {
      if (needle) {
        const haystack = `${flag.citizenAlias} ${flag.citizenCid} ${flag.summary}`.toLowerCase()
        if (!haystack.includes(needle)) return false
      }
      if (filters.severity !== 'all' && flag.severity !== filters.severity) return false
      if (filters.status !== 'all' && flag.status !== filters.status) return false
      return true
    })
    .sort((a, b) => {
      const sa = STATUS_RANK[a.status]
      const sb = STATUS_RANK[b.status]
      if (sa !== sb) return sa - sb
      const ra = SEVERITY_RANK[a.severity]
      const rb = SEVERITY_RANK[b.severity]
      if (ra !== rb) return ra - rb
      return b.raisedAt - a.raisedAt
    })
}

export function getFlagDetailMock(flagId: string): GovtFlagQueueItem | undefined {
  return STATE.flags.get(flagId)
}

export function isCitizenFrozenMock(cid: string): boolean {
  return STATE.frozenCitizens.has(cid)
}

export function listSanctionActionsMock(targetCid?: string): GovtSanctionAction[] {
  const all = STATE.actions.slice().sort((a, b) => b.performedAt - a.performedAt)
  return targetCid ? all.filter((a) => a.targetCid === targetCid) : all
}

export function getQueueKpisMock(): { open: number; critical: number; today: number; total: number } {
  const flags = Array.from(STATE.flags.values())
  const startOfDay = new Date()
  startOfDay.setHours(0, 0, 0, 0)
  const todayStart = startOfDay.getTime()
  return {
    open: flags.filter((f) => f.status === 'open').length,
    critical: flags.filter((f) => f.severity === 'critical' && f.status !== 'dismissed' && f.status !== 'resolved').length,
    today: STATE.actions.filter((a) => a.performedAt >= todayStart).length,
    total: flags.length,
  }
}

/* ----- mutations ---------------------------------------------------------- */

const MUTATION_DELAY_MS = 520
const MOCK_OPERATOR = 'Bureau-Op-001'

function deriveAlias(cid: string): string {
  const fromFlag = Array.from(STATE.flags.values()).find((f) => f.citizenCid === cid)
  if (fromFlag) return fromFlag.citizenAlias
  const detail = getCensusDetailMock(cid)
  return detail?.alias ?? cid
}

function rebroadcastCitizenStatus(cid: string, status: GovtFlagQueueItem['citizenStatus']) {
  STATE.citizenStatusOverrides.set(cid, status)
  for (const flag of STATE.flags.values()) {
    if (flag.citizenCid === cid) flag.citizenStatus = status
  }
}

export async function closeFlagMock(req: GovtCloseFlagRequest): Promise<GovtSanctionAction> {
  await new Promise((r) => setTimeout(r, MUTATION_DELAY_MS))
  const flag = STATE.flags.get(req.flagId)
  if (!flag) throw new Error('FLAG_NOT_FOUND')
  flag.status = req.verdict
  const action: GovtSanctionAction = {
    id: generateUuidV4(),
    type: 'close_flag',
    targetCid: flag.citizenCid,
    targetAlias: flag.citizenAlias,
    relatedFlagId: flag.flagId,
    verdict: req.verdict,
    reason: req.reason,
    operator: MOCK_OPERATOR,
    performedAt: Date.now(),
    idempotencyKey: req.idempotencyKey,
  }
  STATE.actions.unshift(action)
  return action
}

export async function freezeAccountsMock(req: GovtFreezeAccountsRequest): Promise<GovtSanctionAction> {
  await new Promise((r) => setTimeout(r, MUTATION_DELAY_MS))
  STATE.frozenCitizens.add(req.targetCid)
  rebroadcastCitizenStatus(req.targetCid, 'sanctioned')
  if (req.relatedFlagId) {
    const flag = STATE.flags.get(req.relatedFlagId)
    if (flag && flag.status === 'open') flag.status = 'reviewing'
  }
  const action: GovtSanctionAction = {
    id: generateUuidV4(),
    type: 'freeze_accounts',
    targetCid: req.targetCid,
    targetAlias: deriveAlias(req.targetCid),
    relatedFlagId: req.relatedFlagId,
    reason: req.reason,
    operator: MOCK_OPERATOR,
    performedAt: Date.now(),
    idempotencyKey: req.idempotencyKey,
  }
  STATE.actions.unshift(action)
  return action
}

export async function liftFreezeMock(req: GovtLiftFreezeRequest): Promise<GovtSanctionAction> {
  await new Promise((r) => setTimeout(r, MUTATION_DELAY_MS))
  STATE.frozenCitizens.delete(req.targetCid)
  rebroadcastCitizenStatus(req.targetCid, 'flagged')
  const action: GovtSanctionAction = {
    id: generateUuidV4(),
    type: 'lift_freeze',
    targetCid: req.targetCid,
    targetAlias: deriveAlias(req.targetCid),
    relatedFlagId: req.relatedFlagId,
    reason: req.reason,
    operator: MOCK_OPERATOR,
    performedAt: Date.now(),
    idempotencyKey: req.idempotencyKey,
  }
  STATE.actions.unshift(action)
  return action
}

export async function applyFineMock(req: GovtApplyFineRequest): Promise<GovtSanctionAction> {
  await new Promise((r) => setTimeout(r, MUTATION_DELAY_MS))
  if (req.amount <= 0) throw new Error('INVALID_AMOUNT')
  if (req.relatedFlagId) {
    const flag = STATE.flags.get(req.relatedFlagId)
    if (flag && flag.status === 'open') flag.status = 'reviewing'
  }
  const action: GovtSanctionAction = {
    id: generateUuidV4(),
    type: 'apply_fine',
    targetCid: req.targetCid,
    targetAlias: deriveAlias(req.targetCid),
    relatedFlagId: req.relatedFlagId,
    amount: req.amount,
    reason: req.reason,
    operator: MOCK_OPERATOR,
    performedAt: Date.now(),
    idempotencyKey: req.idempotencyKey,
  }
  STATE.actions.unshift(action)
  return action
}
