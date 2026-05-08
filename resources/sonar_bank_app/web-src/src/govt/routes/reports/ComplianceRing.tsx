import { useI18n } from '@/lib/i18n'
import type { GovtComplianceBreakdown } from '../../data/contracts'

interface Props {
  data: GovtComplianceBreakdown
}

const SEGMENTS = [
  { key: 'current' as const, color: 'oklch(0.65 0.18 155)', labelKey: 'govt.census.filters.compliance.current' as const },
  { key: 'overdue' as const, color: 'oklch(0.72 0.20 35)',  labelKey: 'govt.census.filters.compliance.overdue' as const },
  { key: 'pending' as const, color: 'oklch(0.78 0.16 85)',  labelKey: 'govt.census.filters.compliance.pending' as const },
  { key: 'exempt'  as const, color: 'oklch(0.60 0.08 252)', labelKey: 'govt.census.filters.compliance.exempt' as const },
] as const

function polarToXY(cx: number, cy: number, r: number, angle: number) {
  const rad = (angle - 90) * (Math.PI / 180)
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) }
}

function arcPath(cx: number, cy: number, r: number, startAngle: number, endAngle: number) {
  const start = polarToXY(cx, cy, r, startAngle)
  const end   = polarToXY(cx, cy, r, endAngle)
  const large = endAngle - startAngle > 180 ? 1 : 0
  return `M ${start.x} ${start.y} A ${r} ${r} 0 ${large} 1 ${end.x} ${end.y}`
}

export function ComplianceRing({ data }: Props) {
  const { t, number } = useI18n()
  const total = data.current + data.overdue + data.pending + data.exempt
  const cx = 72
  const cy = 72
  const r = 52
  const stroke = 14
  const gap = 3

  let angle = 0
  const arcs = SEGMENTS.map((seg) => {
    const val = data[seg.key]
    const sweep = total > 0 ? (val / total) * (360 - gap * SEGMENTS.length) : 0
    const start = angle + gap / 2
    const end   = angle + gap / 2 + sweep
    angle += sweep + gap
    return { ...seg, val, start, end, sweep }
  })

  return (
    <div className="flex flex-col items-center gap-4 sm:flex-row sm:items-start">
      <div className="relative flex-shrink-0" style={{ width: 144, height: 144 }}>
        <svg width="144" height="144" viewBox="0 0 144 144" aria-hidden>
          {arcs.map((arc) =>
            arc.sweep > 1 ? (
              <path
                key={arc.key}
                d={arcPath(cx, cy, r, arc.start, arc.end)}
                fill="none"
                stroke={arc.color}
                strokeWidth={stroke}
                strokeLinecap="round"
                style={{ filter: `drop-shadow(0 0 4px ${arc.color}44)` }}
              />
            ) : null,
          )}
          <circle cx={cx} cy={cy} r={r - stroke / 2 - 6} fill="oklch(0.05 0.010 252 / 0.95)" />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-2xl font-semibold tabular-nums leading-none tracking-[-0.03em] text-[var(--color-govt-text-primary)]">{number(total)}</span>
          <span className="mt-0.5 text-[9px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">{t('govt.reports.compliance.total')}</span>
        </div>
      </div>

      <ul className="flex flex-col gap-2">
        {arcs.map((arc) => (
          <li key={arc.key} className="flex items-center justify-between gap-6">
            <span className="flex items-center gap-2 text-[11px] text-[var(--color-govt-text-secondary)]">
              <span className="h-2 w-2 flex-shrink-0 rounded-full" style={{ background: arc.color }} aria-hidden />
              {t(arc.labelKey)}
            </span>
            <span className="text-[12px] font-semibold tabular-nums" style={{ color: arc.color }}>{number(arc.val)}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}
