import type {
  GovtReportsData,
  GovtReportsRange,
  GovtTaxCompliance,
} from '../contracts'

const MONTH_LABELS_EN = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

const now = new Date()

function monthLabel(offset: number): string {
  const d = new Date(now.getFullYear(), now.getMonth() - offset, 1)
  return MONTH_LABELS_EN[d.getMonth()] ?? ''
}

const SECTOR_LIST = [
  { sector: 'farming',   base: 420_000_00, count: 8 },
  { sector: 'milling',   base: 310_000_00, count: 5 },
  { sector: 'bakery',    base: 180_000_00, count: 6 },
  { sector: 'retail',    base: 540_000_00, count: 12 },
  { sector: 'logistics', base: 375_000_00, count: 7 },
  { sector: 'services',  base: 290_000_00, count: 9 },
  { sector: 'finance',   base: 820_000_00, count: 4 },
  { sector: 'other',     base: 120_000_00, count: 3 },
]

const TOP_CONTRIBUTORS_DATA: Array<{
  id: string; label: string; kind: 'citizen' | 'company'; taxPaid: number; bracketCode: string; compliance: GovtTaxCompliance
}> = [
  { id: 'CO-0007', label: 'Prime Finance Group', kind: 'company', taxPaid: 184_200_00, bracketCode: 'C', compliance: 'current' },
  { id: 'CO-0001', label: 'Granja Verdana',       kind: 'company', taxPaid: 97_500_00,  bracketCode: 'B', compliance: 'current' },
  { id: 'CID-4821', label: 'Marina Volkov',        kind: 'citizen', taxPaid: 62_300_00,  bracketCode: 'B', compliance: 'current' },
  { id: 'CO-0004', label: 'Retail Nexus',          kind: 'company', taxPaid: 58_900_00,  bracketCode: 'B', compliance: 'overdue' },
  { id: 'CID-3210', label: 'Noor Khan',            kind: 'citizen', taxPaid: 44_100_00,  bracketCode: 'B', compliance: 'current' },
  { id: 'CO-0005', label: 'LogiChain Express',     kind: 'company', taxPaid: 38_700_00,  bracketCode: 'B', compliance: 'pending' },
  { id: 'CID-6645', label: 'Omar Silva',           kind: 'citizen', taxPaid: 31_200_00,  bracketCode: 'A', compliance: 'current' },
  { id: 'CID-7790', label: 'Eva Bauer',            kind: 'citizen', taxPaid: 26_400_00,  bracketCode: 'A', compliance: 'current' },
]

function scaleFactor(range: GovtReportsRange): number {
  if (range === 'month')   return 1
  if (range === 'quarter') return 3
  return 12
}

export function getReportsDataMock(range: GovtReportsRange): GovtReportsData {
  const months = range === 'month' ? 4 : range === 'quarter' ? 6 : 12
  const sf = scaleFactor(range)

  const revenueHistory = Array.from({ length: months }, (_, i) => {
    const idx = months - 1 - i
    const lbl = monthLabel(idx)
    const wave = 1 + 0.15 * Math.sin(i * 0.8)
    const obligation = Math.round(2_400_000_00 * sf / months * wave)
    const rate = 0.72 + 0.18 * (i / (months - 1))
    const collected = Math.round(obligation * rate)
    return { label: lbl, collected, obligation }
  })

  const totalRevenue = revenueHistory.reduce((s, p) => s + p.collected, 0)
  const totalObligation = revenueHistory.reduce((s, p) => s + p.obligation, 0)
  const complianceRate = Math.round((totalRevenue / totalObligation) * 100)

  const priorRevenue = Math.round(totalRevenue * 0.89)
  const revenueVsPriorPct = Math.round(((totalRevenue - priorRevenue) / priorRevenue) * 100)

  const sectorRevenue = SECTOR_LIST.map((s) => ({
    sector: s.sector,
    collected: Math.round(s.base * sf),
    entityCount: s.count,
  })).sort((a, b) => b.collected - a.collected)

  return {
    range,
    kpis: {
      totalRevenue,
      totalObligation,
      complianceRate,
      activeTaxpayers: 247,
      revenueVsPriorPct,
    },
    revenueHistory,
    sectorRevenue,
    topContributors: TOP_CONTRIBUTORS_DATA,
    complianceBreakdown: {
      current: 168,
      overdue: 34,
      pending: 28,
      exempt: 17,
    },
    riskBreakdown: {
      low: 94,
      medium: 82,
      high: 53,
      critical: 18,
    },
  }
}
