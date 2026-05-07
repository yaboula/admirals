import { useMemo } from 'react'
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis, type TooltipProps } from 'recharts'
import type { Account, Transaction } from '@/data/contracts'
import { Card } from '@/components/ui'
import { formatCurrency } from '@/lib/utils'

interface GraphPoint {
  label: string
  balance: number
}

export interface HomeBalanceGraphProps {
  account: Account | undefined
  transactions: Transaction[]
}

const ORANGE = 'oklch(0.70 0.22 40)'
const ORANGE_SOFT = 'oklch(0.58 0.18 38)'

export function HomeBalanceGraph({ account, transactions }: HomeBalanceGraphProps) {
  const data = useMemo(() => buildGraph(account, transactions), [account, transactions])
  const balance = account ? account.balance_minor / 100 : 0
  const monthDelta = computeMonthDelta(transactions, account?.iban)
  const deltaPct = balance > 0 ? (monthDelta / balance) * 100 : 0

  return (
    <Card variant="glass" padding="none" className="relative h-full min-h-0 overflow-hidden rounded-[1.65rem] border-white/10">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 18% 0%, oklch(0.72 0.22 40 / 0.13), transparent 34%), linear-gradient(180deg, oklch(1 0 0 / 0.035), transparent 48%)',
        }}
      />
      <div className="relative h-full min-h-0 flex flex-col p-5 2xl:p-6">
        <div className="flex items-start justify-between gap-4 shrink-0">
          <div className="flex flex-col gap-1.5">
            <span className="text-sm text-text-secondary font-medium">Total Balance</span>
            <div className="flex items-baseline gap-2.5">
              <span className="text-3xl 2xl:text-4xl font-light tracking-[-0.04em] tactile-tabular-nums text-text-primary">
                {formatCurrency(balance)}
              </span>
              <span
                className="text-xs font-semibold tactile-tabular-nums"
                style={{ color: deltaPct >= 0 ? 'oklch(0.78 0.16 150)' : 'oklch(0.72 0.18 25)' }}
              >
                {deltaPct >= 0 ? '↑' : '↓'} {Math.abs(deltaPct).toLocaleString('es-ES', { maximumFractionDigits: 2 })}%
              </span>
            </div>
          </div>
          <div className="hidden md:flex items-center gap-1.5 rounded-full p-1" style={{ background: 'oklch(1 0 0 / 0.045)' }}>
            {['1 year', '6 month', '3 month', '1 month'].map((label) => (
              <button
                key={label}
                type="button"
                className="h-8 rounded-full px-3 text-[11px] font-medium text-text-secondary"
                style={
                  label === '6 month'
                    ? { background: 'oklch(1 0 0 / 0.10)', color: 'var(--color-text-primary)' }
                    : undefined
                }
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <div className="relative flex-1 min-h-0 mt-2 -mx-1">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data} margin={{ top: 18, right: 8, bottom: 0, left: 0 }}>
              <defs>
                <linearGradient id="home-balance-fill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor={ORANGE} stopOpacity={0.52} />
                  <stop offset="52%" stopColor={ORANGE_SOFT} stopOpacity={0.20} />
                  <stop offset="100%" stopColor={ORANGE_SOFT} stopOpacity={0} />
                </linearGradient>
                <filter id="home-balance-glow" x="-20%" y="-20%" width="140%" height="140%">
                  <feGaussianBlur stdDeviation="2.2" result="blur" />
                  <feMerge>
                    <feMergeNode in="blur" />
                    <feMergeNode in="SourceGraphic" />
                  </feMerge>
                </filter>
              </defs>
              <CartesianGrid stroke="oklch(1 0 0 / 0.055)" strokeDasharray="3 5" vertical={false} />
              <XAxis
                dataKey="label"
                tick={{ fill: 'oklch(0.64 0.012 270)', fontSize: 10 }}
                tickLine={false}
                axisLine={false}
                interval={0}
                minTickGap={10}
              />
              <YAxis
                tick={{ fill: 'oklch(0.58 0.012 270)', fontSize: 10 }}
                tickLine={false}
                axisLine={false}
                width={44}
                orientation="right"
                tickFormatter={(value: number) => `${Math.round(value / 1000)}k`}
              />
              <Tooltip content={<BalanceTooltip />} cursor={{ stroke: 'oklch(1 0 0 / 0.16)', strokeDasharray: '3 4' }} />
              <Area
                type="monotone"
                dataKey="balance"
                stroke={ORANGE}
                strokeWidth={2.3}
                fill="url(#home-balance-fill)"
                activeDot={{ r: 4, stroke: 'white', strokeWidth: 2, fill: ORANGE }}
                dot={false}
                filter="url(#home-balance-glow)"
                animationDuration={720}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="shrink-0 flex items-center justify-between gap-4 pt-2 text-[11px] text-text-tertiary">
          <span>Average annual rate · {formatCurrency(Math.max(balance * 0.12, 840))}</span>
          <span className="inline-flex items-center gap-3">
            <span className="inline-flex items-center gap-1.5"><i className="h-2 w-2 rounded-sm bg-white" />Actual balance</span>
            <span className="inline-flex items-center gap-1.5"><i className="h-2 w-2 rounded-sm" style={{ background: ORANGE }} />Projected flow</span>
          </span>
        </div>
      </div>
    </Card>
  )
}

function BalanceTooltip({ active, payload, label }: TooltipProps<number, string>) {
  if (!active || !payload?.length) return null
  const value = payload[0]?.value ?? 0
  return (
    <div className="rounded-2xl px-4 py-3 text-center" style={{ background: 'oklch(0.98 0 0)', color: 'oklch(0.08 0.01 270)', boxShadow: '0 18px 34px -20px oklch(0 0 0 / 0.8)' }}>
      <div className="text-xs font-semibold">{label}</div>
      <div className="text-sm font-bold tactile-tabular-nums">{formatCurrency(Number(value))}</div>
    </div>
  )
}

function buildGraph(account: Account | undefined, transactions: Transaction[]): GraphPoint[] {
  const balance = account ? account.balance_minor / 100 : 0
  const own = account?.iban.replace(/\s+/g, '')
  const months = Array.from({ length: 6 }, (_, index) => {
    const date = new Date()
    date.setMonth(date.getMonth() - (5 - index), 1)
    date.setHours(0, 0, 0, 0)
    return date
  })
  const monthlyNet = months.map((month) => {
    const monthIndex = month.getMonth()
    const year = month.getFullYear()
    return transactions.reduce((sum, tx) => {
      const date = new Date(tx.timestamp_ms)
      if (date.getMonth() !== monthIndex || date.getFullYear() !== year || tx.status !== 'committed') return sum
      const fromOwn = own ? tx.from_iban.replace(/\s+/g, '') === own : tx.direction === 'out'
      const toOwn = own ? tx.to_iban.replace(/\s+/g, '') === own : tx.direction === 'in'
      if (toOwn && !fromOwn) return sum + tx.amount_minor / 100
      if (fromOwn && !toOwn) return sum - tx.amount_minor / 100
      return sum
    }, 0)
  })
  const points: GraphPoint[] = []
  let rolling = balance - monthlyNet.reduce((sum, value) => sum + value, 0)
  months.forEach((month, index) => {
    rolling += monthlyNet[index] ?? 0
    points.push({
      label: month.toLocaleDateString('es-ES', { month: 'short' }).replace('.', ''),
      balance: Math.max(0, rolling),
    })
  })
  return points
}

function computeMonthDelta(transactions: Transaction[], ownIban: string | undefined): number {
  const own = ownIban?.replace(/\s+/g, '')
  const cutoff = Date.now() - 30 * 24 * 60 * 60 * 1000
  return transactions.reduce((sum, tx) => {
    if (tx.timestamp_ms < cutoff || tx.status !== 'committed') return sum
    const fromOwn = own ? tx.from_iban.replace(/\s+/g, '') === own : tx.direction === 'out'
    const toOwn = own ? tx.to_iban.replace(/\s+/g, '') === own : tx.direction === 'in'
    if (toOwn && !fromOwn) return sum + tx.amount_minor / 100
    if (fromOwn && !toOwn) return sum - tx.amount_minor / 100
    return sum
  }, 0)
}
