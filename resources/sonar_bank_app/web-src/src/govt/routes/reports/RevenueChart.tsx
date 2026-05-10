import { useI18n } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { maskMoneyDisplay } from '@/lib/privacy'
import type { GovtRevenueDataPoint } from '../../data/contracts'

interface Props {
  data: GovtRevenueDataPoint[]
}

const COLOR_COLLECTED  = 'rgb(0, 183, 100)'
const COLOR_OBLIGATION = 'rgb(78, 116, 159)'

export function RevenueChart({ data }: Props) {
  const { t, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  if (data.length === 0) return null

  const maxVal = Math.max(...data.flatMap((d) => [d.collected, d.obligation])) * 1.08
  const W = 520
  const H = 160
  const padL = 0
  const padR = 4
  const padT = 12
  const padB = 28
  const chartW = W - padL - padR
  const chartH = H - padT - padB
  const n = data.length
  const groupW = chartW / n
  const barW = Math.min(18, groupW * 0.35)
  const gap = 4

  return (
    <div className="w-full">
      <div className="mb-3 flex items-center gap-4">
        <LegendDot color={COLOR_COLLECTED} label={t('govt.reports.chart.collected')} />
        <LegendDot color={COLOR_OBLIGATION} label={t('govt.reports.chart.obligation')} />
      </div>
      <svg
        viewBox={`0 0 ${W} ${H}`}
        className="w-full overflow-visible"
        aria-label={t('govt.reports.chart.ariaLabel')}
        role="img"
      >
        {[0.25, 0.5, 0.75, 1].map((frac) => {
          const y = padT + chartH * (1 - frac)
          return (
            <line
              key={frac}
              x1={padL}
              x2={W - padR}
              y1={y}
              y2={y}
              stroke="rgba(255,255,255,0.06)"
              strokeWidth="1"
            />
          )
        })}

        {data.map((d, i) => {
          const cx = padL + i * groupW + groupW / 2
          const hC = (d.collected / maxVal) * chartH
          const hO = (d.obligation / maxVal) * chartH
          const yC = padT + chartH - hC
          const yO = padT + chartH - hO
          const xO = cx - barW - gap / 2
          const xC = cx + gap / 2

          return (
            <g key={d.label}>
              <rect x={xO} y={yO} width={barW} height={hO} rx="3" ry="3" fill={COLOR_OBLIGATION} opacity="0.55" />
              <rect x={xC} y={yC} width={barW} height={hC} rx="3" ry="3" fill={COLOR_COLLECTED} />
            </g>
          )
        })}

        {data.map((d, i) => {
          const cx = padL + i * groupW + groupW / 2
          return (
            <text
              key={d.label}
              x={cx}
              y={H - 6}
              textAnchor="middle"
              fontSize="9"
              fill="rgba(255,255,255,0.35)"
              fontFamily="inherit"
            >
              {d.label}
            </text>
          )
        })}

        <line x1={padL} x2={W - padR} y1={padT + chartH} y2={padT + chartH} stroke="rgba(255,255,255,0.1)" strokeWidth="1" />
      </svg>

      {!streamerMode ? (
        <div className="mt-2 flex flex-wrap justify-end gap-4 text-[10px] tabular-nums text-[var(--color-govt-text-tertiary)]">
          <span>
            <span className="uppercase tracking-[0.12em]">{t('govt.reports.chart.lastCollected')}: </span>
            <span style={{ color: COLOR_COLLECTED }}>{money(data[data.length - 1]?.collected ?? 0)}</span>
          </span>
          <span>
            <span className="uppercase tracking-[0.12em]">{t('govt.reports.chart.lastObligation')}: </span>
            <span style={{ color: COLOR_OBLIGATION }}>{money(data[data.length - 1]?.obligation ?? 0)}</span>
          </span>
        </div>
      ) : (
        <div className="mt-2 flex flex-wrap justify-end gap-4 text-[10px] tabular-nums text-[var(--color-govt-text-tertiary)]">
          <span>{maskMoneyDisplay()} / {maskMoneyDisplay()}</span>
        </div>
      )}
    </div>
  )
}

function LegendDot({ color, label }: { color: string; label: string }) {
  return (
    <span className="flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-[0.12em] text-[var(--color-govt-text-tertiary)]">
      <span className="h-2 w-2 rounded-full" style={{ background: color }} aria-hidden />
      {label}
    </span>
  )
}
