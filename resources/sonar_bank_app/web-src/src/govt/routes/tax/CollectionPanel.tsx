import { useEffect, useRef, useState } from 'react'
import { useI18n } from '@/lib/i18n'
import type { GovtTaxBracket, GovtTaxCycleStats, GovtTaxTierId } from '../../data/contracts'

/* ============================================================================
   Authority Black — Collection Panel.
   Two visual elements:
     1. Bracket staircase SVG — stepped area showing effective rates.
        Distinctive / un-AI-generic. No library.
     2. Daily collection sparkline — 14-bar cycle view.
   ============================================================================ */

interface Props {
  stats: GovtTaxCycleStats
  brackets: GovtTaxBracket[]
  draftRates?: Map<GovtTaxTierId, number>
}

const TIER_COLORS: Record<GovtTaxTierId, string> = {
  basic: 'oklch(0.72 0.17 155)',
  standard: 'oklch(0.78 0.16 108)',
  premium: 'oklch(0.78 0.16 60)',
  elite: 'oklch(0.70 0.20 30)',
}

export function CollectionPanel({ stats, brackets, draftRates }: Props) {
  const coverage = stats.totalObligationCents > 0
    ? Math.min(100, (stats.totalCollectedCents / stats.totalObligationCents) * 100)
    : 0
  const daysRemaining = stats.cycleDurationDays - stats.dailySeries.filter((d) => d.collectedCents > 0).length

  return (
    <div className="flex h-full flex-col gap-4">
      <CollectionStats
        totalCollected={stats.totalCollectedCents}
        totalObligation={stats.totalObligationCents}
        todayCollected={stats.collectedTodayCents}
        coverage={coverage}
        daysRemaining={daysRemaining}
        cycleId={stats.cycleId}
      />
      <div className="flex-1">
        <BracketStaircase brackets={brackets} draftRates={draftRates} />
      </div>
      <DailySpark series={stats.dailySeries} />
    </div>
  )
}

/* ---- collection stats ---------------------------------------------------- */

function CollectionStats({
  totalCollected, totalObligation, todayCollected, coverage, daysRemaining, cycleId,
}: {
  totalCollected: number; totalObligation: number; todayCollected: number
  coverage: number; daysRemaining: number; cycleId: string
}) {
  const { t } = useI18n()
  const countRef = useRef<HTMLSpanElement>(null)
  const [rendered, setRendered] = useState(0)

  useEffect(() => {
    const target = Math.round(totalCollected)
    let start: number | null = null
    const duration = 900

    const step = (ts: number) => {
      if (!start) start = ts
      const progress = Math.min((ts - start) / duration, 1)
      const ease = 1 - (1 - progress) ** 3
      setRendered(Math.round(ease * target))
      if (progress < 1) requestAnimationFrame(step)
    }
    requestAnimationFrame(step)
  }, [totalCollected])

  const pct = Math.round(coverage)
  const arcR = 28
  const arcC = 34
  const arcCircumference = 2 * Math.PI * arcR
  const arcOffset = arcCircumference * (1 - coverage / 100)

  return (
    <div className="rounded-2xl border p-4" style={{ background: 'oklch(0.07 0.010 252)', borderColor: 'oklch(0.15 0.008 252)' }}>
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-[10px] font-semibold uppercase tracking-[0.18em]" style={{ color: 'oklch(0.42 0.008 252)' }}>
            {t('govt.tax.stats.collected')}
          </p>
          <div className="mt-0.5 flex items-baseline gap-1.5">
            <span className="text-[10px]" style={{ color: 'oklch(0.45 0.008 252)' }}>$</span>
            <span
              ref={countRef}
              className="text-[clamp(1.6rem,3.5vw,2.4rem)] font-extralight leading-none tracking-[-0.04em] tabular-nums"
              style={{ color: 'oklch(0.96 0.004 252)' }}
            >
              {(rendered / 100).toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}
            </span>
          </div>
          <p className="mt-1 text-[11px]" style={{ color: 'oklch(0.48 0.010 252)' }}>
            {`${t('govt.tax.stats.of')} ${(totalObligation / 100).toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 })} ${t('govt.tax.stats.obligation')}`}
          </p>
        </div>

        <div className="flex flex-col items-center" title={`${pct}% coverage`}>
          <svg width={68} height={68} viewBox="0 0 68 68" aria-hidden>
            <defs>
              <radialGradient id="arc-glow" cx="50%" cy="50%" r="50%">
                <stop offset="0%" stopColor="oklch(0.65 0.18 155 / 0.18)" />
                <stop offset="100%" stopColor="transparent" />
              </radialGradient>
            </defs>
            <circle fill="url(#arc-glow)" cx={arcC} cy={arcC} r={arcR + 4} />
            <circle cx={arcC} cy={arcC} r={arcR} fill="none" stroke="oklch(0.15 0.010 252)" strokeWidth={4} />
            <circle
              cx={arcC} cy={arcC} r={arcR}
              fill="none" stroke="oklch(0.72 0.17 155)" strokeWidth={4}
              strokeDasharray={arcCircumference}
              strokeDashoffset={arcOffset}
              strokeLinecap="round"
              transform={`rotate(-90 ${arcC} ${arcC})`}
              style={{ transition: 'stroke-dashoffset 1s cubic-bezier(0.16, 1, 0.3, 1)' }}
            />
            <text x={arcC} y={arcC + 1} textAnchor="middle" dominantBaseline="middle" fontSize={12} fontWeight={600} fill="oklch(0.92 0.004 252)">
              {`${pct}%`}
            </text>
          </svg>
        </div>
      </div>

      <div className="mt-3 grid grid-cols-3 gap-2 border-t pt-3" style={{ borderColor: 'oklch(0.13 0.008 252)' }}>
        <MiniStat label={t('govt.tax.stats.today')} value={`$${(todayCollected / 100).toLocaleString('en-US', { maximumFractionDigits: 0 })}`} />
        <MiniStat label={t('govt.tax.stats.daysLeft')} value={String(Math.max(0, daysRemaining))} />
        <MiniStat label={t('govt.tax.stats.cycleId')} value={cycleId} mono />
      </div>
    </div>
  )
}

function MiniStat({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div>
      <p className="text-[10px] font-semibold uppercase tracking-[0.14em]" style={{ color: 'oklch(0.40 0.008 252)' }}>{label}</p>
      <p
        className={`mt-0.5 truncate text-sm font-semibold ${mono ? 'font-mono text-[11px]' : ''}`}
        style={{ color: 'oklch(0.82 0.008 252)' }}
      >
        {value}
      </p>
    </div>
  )
}

/* ---- bracket staircase --------------------------------------------------- */

function BracketStaircase({ brackets, draftRates }: { brackets: GovtTaxBracket[]; draftRates?: Map<GovtTaxTierId, number> }) {
  const { t } = useI18n()
  if (!brackets.length) return null

  const W = 320
  const H = 120
  const PAD_L = 36
  const PAD_B = 28
  const PAD_T = 12
  const PAD_R = 12
  const chartW = W - PAD_L - PAD_R
  const chartH = H - PAD_T - PAD_B
  const MAX_RATE = 60

  const effectiveRate = (b: GovtTaxBracket) => draftRates?.get(b.id) ?? b.rate
  const xOf = (i: number) => PAD_L + (i / brackets.length) * chartW
  const yOf = (rate: number) => PAD_T + chartH - (rate / MAX_RATE) * chartH

  const staircasePath = brackets.reduce((acc, b, i) => {
    const x0 = xOf(i)
    const x1 = xOf(i + 1)
    const y = yOf(effectiveRate(b))
    if (i === 0) return `M ${x0} ${H - PAD_B} L ${x0} ${y} L ${x1} ${y}`
    return `${acc} L ${x1} ${y}`
  }, '') + ` L ${xOf(brackets.length)} ${H - PAD_B} Z`

  const staircasePathOriginal = brackets.reduce((acc, b, i) => {
    const x0 = xOf(i)
    const x1 = xOf(i + 1)
    const y = yOf(b.rate)
    if (i === 0) return `M ${x0} ${H - PAD_B} L ${x0} ${y} L ${x1} ${y}`
    return `${acc} L ${x1} ${y}`
  }, '') + ` L ${xOf(brackets.length)} ${H - PAD_B} Z`

  const isDraft = brackets.some((b) => (draftRates?.get(b.id) ?? b.rate) !== b.rate)

  return (
    <div className="rounded-2xl border p-4" style={{ background: 'oklch(0.07 0.010 252)', borderColor: 'oklch(0.15 0.008 252)' }}>
      <p className="text-[10px] font-semibold uppercase tracking-[0.18em]" style={{ color: 'oklch(0.42 0.008 252)' }}>
        {t('govt.tax.staircase.title')}
      </p>
      <div className="mt-2 overflow-hidden rounded-xl" style={{ background: 'oklch(0.05 0.008 252)' }}>
        <svg viewBox={`0 0 ${W} ${H}`} className="w-full" style={{ maxHeight: 130 }} aria-hidden>
          <defs>
            <radialGradient id="staircase-atm" cx="50%" cy="30%" r="70%">
              <stop offset="0%" stopColor="oklch(0.65 0.18 252 / 0.20)" />
              <stop offset="100%" stopColor="transparent" />
            </radialGradient>
            <linearGradient id="staircase-fill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="oklch(0.65 0.18 252 / 0.22)" />
              <stop offset="100%" stopColor="oklch(0.65 0.18 252 / 0.04)" />
            </linearGradient>
          </defs>

          <rect width={W} height={H} fill="url(#staircase-atm)" />

          {[10, 20, 30, 40, 50].map((rate) => (
            <g key={rate}>
              <line
                x1={PAD_L} y1={yOf(rate)} x2={W - PAD_R} y2={yOf(rate)}
                stroke="oklch(0.18 0.010 252)" strokeWidth={0.5} strokeDasharray="2 4"
              />
              <text x={PAD_L - 4} y={yOf(rate)} textAnchor="end" dominantBaseline="middle" fontSize={8} fill="oklch(0.38 0.008 252)">
                {`${rate}%`}
              </text>
            </g>
          ))}

          {isDraft ? (
            <path d={staircasePathOriginal} fill="oklch(0.65 0.18 252 / 0.06)" stroke="oklch(0.65 0.18 252 / 0.25)" strokeWidth={1} strokeDasharray="3 3" />
          ) : null}

          <path d={staircasePath} fill="url(#staircase-fill)" stroke="oklch(0.65 0.18 252)" strokeWidth={1.5} strokeLinejoin="round" style={{ transition: 'd 0.4s ease' }} />

          {brackets.map((b, i) => {
            const midX = xOf(i) + ((xOf(i + 1) - xOf(i)) / 2)
            const rate = effectiveRate(b)
            const isDirtyTier = rate !== b.rate
            return (
              <g key={b.id}>
                <circle cx={xOf(i + 1)} cy={yOf(rate)} r={3} fill={isDirtyTier ? TIER_COLORS[b.id] : 'oklch(0.65 0.18 252)'} />
                <text x={midX} y={H - PAD_B + 10} textAnchor="middle" fontSize={8.5} fontWeight="600" fill="oklch(0.55 0.008 252)">
                  {b.code}
                </text>
                <text x={midX} y={H - PAD_B + 20} textAnchor="middle" fontSize={7} fill="oklch(0.38 0.008 252)">
                  {`${rate}%`}
                </text>
              </g>
            )
          })}
        </svg>
      </div>
      {isDraft ? (
        <p className="mt-2 text-center text-[10px]" style={{ color: 'oklch(0.65 0.18 252 / 0.70)' }}>
          {t('govt.tax.staircase.previewMode')}
        </p>
      ) : null}
    </div>
  )
}

/* ---- daily sparkline ----------------------------------------------------- */

function DailySpark({ series }: { series: { dayIndex: number; collectedCents: number; obligationCents: number }[] }) {
  const { t } = useI18n()
  if (!series.length) return null

  const W = 300
  const H = 48
  const maxObl = Math.max(...series.map((d) => d.obligationCents))
  const barW = Math.floor((W - series.length) / series.length)

  return (
    <div className="rounded-2xl border p-4" style={{ background: 'oklch(0.07 0.010 252)', borderColor: 'oklch(0.15 0.008 252)' }}>
      <p className="text-[10px] font-semibold uppercase tracking-[0.18em]" style={{ color: 'oklch(0.42 0.008 252)' }}>
        {t('govt.tax.spark.title')}
      </p>
      <svg viewBox={`0 0 ${W} ${H}`} className="mt-2 w-full" style={{ maxHeight: 52 }} aria-hidden>
        {series.map((d, i) => {
          const x = i * (barW + 1)
          const oblH = (d.obligationCents / maxObl) * (H - 4)
          const colH = d.collectedCents > 0 ? (d.collectedCents / maxObl) * (H - 4) : 0
          const isToday = d.collectedCents > 0 && (series[i + 1]?.collectedCents ?? 0) === 0
          return (
            <g key={d.dayIndex}>
              <rect x={x} y={H - oblH} width={barW} height={oblH} fill="oklch(0.14 0.010 252)" rx={1} />
              {colH > 0 ? (
                <rect
                  x={x} y={H - colH} width={barW} height={colH}
                  fill={isToday ? 'oklch(0.65 0.18 252)' : 'oklch(0.55 0.18 155)'}
                  rx={1}
                  style={{ transition: 'height 0.4s ease, y 0.4s ease' }}
                />
              ) : null}
            </g>
          )
        })}
      </svg>
      <div className="mt-1.5 flex items-center gap-4 text-[10px]" style={{ color: 'oklch(0.40 0.008 252)' }}>
        <LegendDot color="oklch(0.55 0.18 155)" label={t('govt.tax.spark.collected')} />
        <LegendDot color="oklch(0.65 0.18 252)" label={t('govt.tax.spark.today')} />
        <LegendDot color="oklch(0.14 0.010 252)" label={t('govt.tax.spark.obligation')} />
      </div>
    </div>
  )
}

function LegendDot({ color, label }: { color: string; label: string }) {
  return (
    <span className="flex items-center gap-1.5">
      <span aria-hidden className="inline-block h-2 w-2 rounded-sm" style={{ background: color }} />
      {label}
    </span>
  )
}
