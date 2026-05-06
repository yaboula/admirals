import { useMemo } from 'react'
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  type TooltipProps,
} from 'recharts'
import type { Transaction } from '@/data/contracts'
import { cn } from '@/lib/utils'

export interface IncomeExpenseChartProps {
  transactions: Transaction[]
  ownIban: string | undefined
  /** number of trailing days to render — default 30 */
  windowDays?: number
  className?: string
}

interface DayBucket {
  ms: number
  label: string
  income: number
  expense: number
  net: number
}

const DAY_MS = 24 * 60 * 60 * 1000

function buildBuckets(
  transactions: Transaction[],
  ownIban: string | undefined,
  windowDays: number,
): DayBucket[] {
  const ownCompact = ownIban?.replace(/\s+/g, '')
  const today = new Date()
  today.setHours(23, 59, 59, 999)
  const buckets: DayBucket[] = []

  for (let i = windowDays - 1; i >= 0; i--) {
    const d = new Date(today)
    d.setDate(d.getDate() - i)
    d.setHours(0, 0, 0, 0)
    buckets.push({
      ms: d.getTime(),
      label: d.toLocaleDateString('es-ES', { day: '2-digit', month: 'short' }),
      income: 0,
      expense: 0,
      net: 0,
    })
  }

  for (const t of transactions) {
    if (t.status !== 'committed') continue
    if (t.timestamp_ms < buckets[0]!.ms) continue
    const dayIdx = Math.floor((t.timestamp_ms - buckets[0]!.ms) / DAY_MS)
    if (dayIdx < 0 || dayIdx >= buckets.length) continue
    const bucket = buckets[dayIdx]!

    const fromCompact = t.from_iban.replace(/\s+/g, '')
    const toCompact = t.to_iban.replace(/\s+/g, '')

    if (ownCompact) {
      if (toCompact === ownCompact && fromCompact !== ownCompact) {
        bucket.income += t.amount_minor
      } else if (fromCompact === ownCompact && toCompact !== ownCompact) {
        bucket.expense += t.amount_minor
      }
    } else if (t.direction === 'in') {
      bucket.income += t.amount_minor
    } else if (t.direction === 'out') {
      bucket.expense += t.amount_minor
    }
    bucket.net = bucket.income - bucket.expense
  }

  for (const b of buckets) {
    b.income = b.income / 100
    b.expense = b.expense / 100
    b.net = b.net / 100
  }

  return buckets
}

const COLOR_INCOME = 'oklch(0.70 0.16 155)'
const COLOR_EXPENSE = 'oklch(0.65 0.20 25)'
const COLOR_GRID = 'oklch(1 0 0 / 0.04)'
const COLOR_AXIS = 'oklch(0.55 0.012 270)'

export function IncomeExpenseChart({
  transactions,
  ownIban,
  windowDays = 30,
  className,
}: IncomeExpenseChartProps) {
  const data = useMemo(
    () => buildBuckets(transactions, ownIban, windowDays),
    [transactions, ownIban, windowDays],
  )

  const totals = useMemo(() => {
    let income = 0
    let expense = 0
    for (const b of data) {
      income += b.income
      expense += b.expense
    }
    return { income, expense, net: income - expense }
  }, [data])

  return (
    <div className={cn('relative h-full w-full flex flex-col', className)}>
      {/* Header summary */}
      <div className="flex items-end justify-between gap-4 mb-3 shrink-0">
        <div className="flex flex-col gap-0.5">
          <span className="text-[9px] uppercase tracking-[0.20em] text-text-tertiary font-medium">
            INGRESOS · GASTOS · {windowDays}D
          </span>
          <h3 className="text-base font-semibold text-text-primary tactile-wght-breathing">
            Flujo del periodo
          </h3>
        </div>
        <div className="flex items-center gap-4">
          <Stat label="Ingresos" value={totals.income} color={COLOR_INCOME} />
          <Stat label="Gastos" value={totals.expense} color={COLOR_EXPENSE} />
          <Stat
            label="Neto"
            value={totals.net}
            color={totals.net >= 0 ? COLOR_INCOME : COLOR_EXPENSE}
            highlighted
          />
        </div>
      </div>

      {/* Chart canvas — flex-1 so it fills the card */}
      <div className="flex-1 min-h-0 -mx-2">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data} margin={{ top: 4, right: 8, left: 0, bottom: 0 }}>
            <defs>
              <linearGradient id="bk-income-grad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={COLOR_INCOME} stopOpacity={0.45} />
                <stop offset="100%" stopColor={COLOR_INCOME} stopOpacity={0.02} />
              </linearGradient>
              <linearGradient id="bk-expense-grad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={COLOR_EXPENSE} stopOpacity={0.40} />
                <stop offset="100%" stopColor={COLOR_EXPENSE} stopOpacity={0.02} />
              </linearGradient>
            </defs>
            <CartesianGrid stroke={COLOR_GRID} strokeDasharray="2 4" vertical={false} />
            <XAxis
              dataKey="label"
              stroke={COLOR_AXIS}
              tick={{ fill: COLOR_AXIS, fontSize: 10, style: { fontVariantNumeric: 'tabular-nums' } }}
              tickLine={false}
              axisLine={false}
              minTickGap={32}
              interval="preserveStartEnd"
            />
            <YAxis
              stroke={COLOR_AXIS}
              tick={{ fill: COLOR_AXIS, fontSize: 10, style: { fontVariantNumeric: 'tabular-nums' } }}
              tickLine={false}
              axisLine={false}
              tickFormatter={(v: number) => formatCompact(v)}
              width={42}
            />
            <Tooltip
              cursor={{ stroke: 'oklch(1 0 0 / 0.10)', strokeWidth: 1 }}
              content={<CustomTooltip />}
            />
            <Area
              type="monotone"
              dataKey="income"
              stroke={COLOR_INCOME}
              strokeWidth={1.8}
              fill="url(#bk-income-grad)"
              animationDuration={620}
              isAnimationActive
              activeDot={{ r: 4, strokeWidth: 0, fill: COLOR_INCOME }}
            />
            <Area
              type="monotone"
              dataKey="expense"
              stroke={COLOR_EXPENSE}
              strokeWidth={1.8}
              fill="url(#bk-expense-grad)"
              animationDuration={620}
              isAnimationActive
              activeDot={{ r: 4, strokeWidth: 0, fill: COLOR_EXPENSE }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

function Stat({
  label,
  value,
  color,
  highlighted,
}: {
  label: string
  value: number
  color: string
  highlighted?: boolean
}) {
  return (
    <div className="flex flex-col items-end leading-none">
      <span className="text-[9px] uppercase tracking-wider text-text-tertiary font-medium">
        {label}
      </span>
      <span
        className={cn(
          'tactile-tabular-nums font-semibold',
          highlighted ? 'text-base' : 'text-sm',
        )}
        style={{ color, fontVariantNumeric: 'tabular-nums' }}
      >
        €{formatEur(value)}
      </span>
    </div>
  )
}

function CustomTooltip({ active, payload, label }: TooltipProps<number, string>) {
  if (!active || !payload || payload.length === 0) return null

  const incomeEntry = payload.find((p) => p.dataKey === 'income')
  const expenseEntry = payload.find((p) => p.dataKey === 'expense')
  const income = (incomeEntry?.value as number | undefined) ?? 0
  const expense = (expenseEntry?.value as number | undefined) ?? 0
  const net = income - expense

  return (
    <div
      className="rounded-lg px-3 py-2 text-xs"
      style={{
        background: 'oklch(0.10 0.010 270 / 0.92)',
        backdropFilter: 'blur(12px)',
        WebkitBackdropFilter: 'blur(12px)',
        border: '1px solid var(--color-border-medium)',
        boxShadow: 'var(--shadow-tooltip)',
      }}
    >
      <div className="text-[10px] uppercase tracking-wider text-text-tertiary mb-1">{label}</div>
      <div className="space-y-0.5 tactile-tabular-nums">
        <Row label="Ingresos" value={income} color={COLOR_INCOME} />
        <Row label="Gastos" value={expense} color={COLOR_EXPENSE} />
        <div className="h-px my-1 bg-border-subtle" />
        <Row label="Neto" value={net} color={net >= 0 ? COLOR_INCOME : COLOR_EXPENSE} bold />
      </div>
    </div>
  )
}

function Row({
  label,
  value,
  color,
  bold,
}: {
  label: string
  value: number
  color: string
  bold?: boolean
}) {
  return (
    <div className="flex items-center justify-between gap-4">
      <span className="text-text-tertiary">{label}</span>
      <span
        style={{ color, fontWeight: bold ? 700 : 500, fontVariantNumeric: 'tabular-nums' }}
      >
        €{formatEur(value)}
      </span>
    </div>
  )
}

function formatEur(value: number): string {
  return new Intl.NumberFormat('es-ES', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value)
}

function formatCompact(value: number): string {
  if (Math.abs(value) >= 1000) return `${(value / 1000).toFixed(1)}k`
  return value.toFixed(0)
}
