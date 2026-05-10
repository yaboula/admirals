import { useI18n } from '@/lib/i18n'
import type { GovtComplianceBreakdown } from '../../data/contracts'

interface Props {
  data: GovtComplianceBreakdown
}

const SEGMENTS = [
  { key: 'current' as const, color: 'rgb(0, 173, 91)', labelKey: 'govt.census.filters.compliance.current' as const },
  { key: 'overdue' as const, color: 'rgb(255, 106, 67)',  labelKey: 'govt.census.filters.compliance.overdue' as const },
  { key: 'pending' as const, color: 'rgb(230, 173, 0)',  labelKey: 'govt.census.filters.compliance.pending' as const },
  { key: 'exempt'  as const, color: 'rgb(92, 131, 175)', labelKey: 'govt.census.filters.compliance.exempt' as const },
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
  const cx = 86
  const cy = 86
  const r = 64
  const stroke = 16
  const gap = 2.5

  let angle = 0
  const arcs = SEGMENTS.map((seg) => {
    const val = data[seg.key]
    const pct = total > 0 ? Math.round((val / total) * 100) : 0
    const sweep = total > 0 ? (val / total) * (360 - gap * SEGMENTS.length) : 0
    const start = angle + gap / 2
    const end   = angle + gap / 2 + sweep
    angle += sweep + gap
    return { ...seg, val, pct, start, end, sweep }
  })

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center justify-center gap-6">
        <div className="relative flex-shrink-0" style={{ width: 172, height: 172 }}>
          <svg width="172" height="172" viewBox="0 0 172 172" aria-hidden>
            <circle cx={cx} cy={cy} r={r + stroke / 2 + 1} fill="rgba(0,0,1,0.8)" />
            {arcs.map((arc) =>
              arc.sweep > 1 ? (
                <path
                  key={arc.key}
                  d={arcPath(cx, cy, r, arc.start, arc.end)}
                  fill="none"
                  stroke={arc.color}
                  strokeWidth={stroke}
                  strokeLinecap="round"
                  style={{ filter: `drop-shadow(0 0 6px ${arc.color}55)` }}
                />
              ) : null,
            )}
          </svg>
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-3xl font-semibold tabular-nums leading-none tracking-[-0.04em] text-[var(--color-govt-text-primary)]">{number(total)}</span>
            <span className="mt-1 text-[9px] font-semibold uppercase tracking-[0.16em] text-[var(--color-govt-text-tertiary)]">{t('govt.reports.compliance.total')}</span>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-3">
          {arcs.map((arc) => (
            <div key={arc.key} className="min-w-[110px]">
              <div className="flex items-center justify-between gap-3 mb-1">
                <span className="flex items-center gap-1.5 text-[11px] font-medium text-[var(--color-govt-text-secondary)]">
                  <span className="h-2 w-2 flex-shrink-0 rounded-full" style={{ background: arc.color }} aria-hidden />
                  {t(arc.labelKey)}
                </span>
                <span className="flex items-baseline gap-1.5 tabular-nums">
                  <span className="text-[13px] font-semibold" style={{ color: arc.color }}>{number(arc.val)}</span>
                  <span className="text-[10px] text-[var(--color-govt-text-quaternary)]">{`${arc.pct}%`}</span>
                </span>
              </div>
              <div className="h-[3px] w-full overflow-hidden rounded-full bg-white/[0.06]" aria-hidden>
                <span
                  className="block h-full rounded-full transition-[width] duration-700"
                  style={{ width: `${arc.pct}%`, background: arc.color, boxShadow: `0 0 4px ${arc.color}66` }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="space-y-1">
        <p className="text-[9px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-quaternary)]">{t('govt.reports.compliance.distribution')}</p>
        <div className="flex h-[7px] w-full overflow-hidden rounded-full" aria-hidden>
          {arcs.map((arc) =>
            arc.pct > 0 ? (
              <span
                key={arc.key}
                className="block h-full transition-[width] duration-700"
                style={{ width: `${arc.pct}%`, background: arc.color }}
                title={`${t(arc.labelKey)}: ${arc.pct}%`}
              />
            ) : null,
          )}
        </div>
      </div>
    </div>
  )
}
