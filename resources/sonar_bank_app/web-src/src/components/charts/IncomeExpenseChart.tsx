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
import { useI18n } from '@/lib/i18n'

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
  dateTime: (timestamp: number, options?: Intl.DateTimeFormatOptions) => string,
): DayBucket[] {
  const ownCompact = compactIban(ownIban)
  const today = new Date()
  today.setHours(23, 59, 59, 999)
  const buckets: DayBucket[] = []

  for (let i = windowDays - 1; i >= 0; i--) {
    const d = new Date(today)
    d.setDate(d.getDate() - i)
    d.setHours(0, 0, 0, 0)
    buckets.push({
      ms: d.getTime(),
      label: dateTime(d.getTime(), { day: '2-digit', month: 'short' }),
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

    const fromCompact = compactIban(t.from_iban)
    const toCompact = compactIban(t.to_iban)

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

function compactIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '')
}

const COLOR_INCOME = 'rgb(53, 193, 119)'
const COLOR_INCOME_STROKE = 'rgb(59, 223, 137)'
const COLOR_EXPENSE = 'rgb(252, 88, 85)'
const COLOR_EXPENSE_STROKE = 'rgb(255, 105, 101)'
const COLOR_GRID = 'rgba(255,255,255,0.04)'
const COLOR_AXIS = 'rgb(111, 113, 121)'

/**
 * BANK-FE.2.3 — dual AreaChart (income vs expense per day) with illuminated
 * monotone strokes and gradient fill cascading to the X-axis. SQRT scale
 * preserved to prevent a single spike from flattening the rest of the dataset.
 * This is the V1 aesthetic restored, but hardened against pathological data.
 */
export function IncomeExpenseChart({
  transactions,
  ownIban,
  windowDays = 30,
  className,
}: IncomeExpenseChartProps) {
  const { money, dateTime } = useI18n()
  const data = useMemo(
    () => buildBuckets(transactions, ownIban, windowDays, dateTime),
    [dateTime, transactions, ownIban, windowDays],
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
      <div className="flex items-end justify-between gap-4 mb-3 shrink-0">
        <div className="flex flex-col gap-0.5">
          <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">
            Ingresos · Gastos · {windowDays}D
          </span>
          <h3 className="text-base font-semibold text-text-primary tactile-wght-breathing">
            Flujo del periodo
          </h3>
        </div>
        <div className="flex items-center gap-5">
          <Stat label="Ingresos" value={totals.income} color={COLOR_INCOME} money={money} dot />
          <Stat label="Gastos" value={totals.expense} color={COLOR_EXPENSE} money={money} dot />
          <Stat
            label="Neto"
            value={totals.net}
            color={totals.net >= 0 ? COLOR_INCOME : COLOR_EXPENSE}
            money={money}
            highlighted
          />
        </div>
      </div>

      <div className="flex-1 min-h-0 -mx-1">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart
            data={data}
            margin={{ top: 10, right: 8, left: 0, bottom: 0 }}
          >
            <defs>
              {/* —— Income fill — luminous green cascading to x-axis —— */}
              <linearGradient id="bk-area-income" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%"  stopColor={COLOR_INCOME} stopOpacity={0.42} />
                <stop offset="55%" stopColor={COLOR_INCOME} stopOpacity={0.16} />
                <stop offset="100%" stopColor={COLOR_INCOME} stopOpacity={0} />
              </linearGradient>
              {/* —— Expense fill — warm red cascading to x-axis —— */}
              <linearGradient id="bk-area-expense" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%"  stopColor={COLOR_EXPENSE} stopOpacity={0.38} />
                <stop offset="55%" stopColor={COLOR_EXPENSE} stopOpacity={0.14} />
                <stop offset="100%" stopColor={COLOR_EXPENSE} stopOpacity={0} />
              </linearGradient>
              {/* —— Halo filters: the strokes glow, not the fill —— */}
              <filter id="bk-glow-income" x="-20%" y="-20%" width="140%" height="140%">
                <feGaussianBlur stdDeviation="2.4" result="blur" />
                <feMerge>
                  <feMergeNode in="blur" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
              <filter id="bk-glow-expense" x="-20%" y="-20%" width="140%" height="140%">
                <feGaussianBlur stdDeviation="2.4" result="blur" />
                <feMerge>
                  <feMergeNode in="blur" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
            </defs>
            <CartesianGrid stroke={COLOR_GRID} strokeDasharray="2 4" vertical={false} />
            <XAxis
              dataKey="label"
              stroke={COLOR_AXIS}
              tick={{ fill: COLOR_AXIS, fontSize: 10, style: { fontVariantNumeric: 'tabular-nums' } }}
              tickLine={false}
              axisLine={false}
              minTickGap={28}
              interval="preserveStartEnd"
            />
            <YAxis
              stroke={COLOR_AXIS}
              tick={{ fill: COLOR_AXIS, fontSize: 10, style: { fontVariantNumeric: 'tabular-nums' } }}
              tickLine={false}
              axisLine={false}
              tickFormatter={(v: number) => formatCompact(v)}
              width={42}
              scale="sqrt"
            />
            <Tooltip
              cursor={{ stroke: 'rgba(255,255,255,0.14)', strokeWidth: 1, strokeDasharray: '3 4' }}
              content={<CustomTooltip money={money} />}
              animationDuration={120}
            />
            {/* Expense first so income line draws on top */}
            <Area
              type="monotone"
              dataKey="expense"
              stroke={COLOR_EXPENSE_STROKE}
              strokeWidth={2}
              strokeOpacity={0.95}
              fill="url(#bk-area-expense)"
              fillOpacity={1}
              activeDot={{ r: 4, stroke: COLOR_EXPENSE_STROKE, strokeWidth: 2, fill: 'rgb(3, 1, 1)' }}
              dot={false}
              animationDuration={640}
              filter="url(#bk-glow-expense)"
              isAnimationActive
            />
            <Area
              type="monotone"
              dataKey="income"
              stroke={COLOR_INCOME_STROKE}
              strokeWidth={2}
              strokeOpacity={0.95}
              fill="url(#bk-area-income)"
              fillOpacity={1}
              activeDot={{ r: 4, stroke: COLOR_INCOME_STROKE, strokeWidth: 2, fill: 'rgb(1, 2, 1)' }}
              dot={false}
              animationDuration={640}
              filter="url(#bk-glow-income)"
              isAnimationActive
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
  dot,
  money,
}: {
  label: string
  value: number
  color: string
  money: (value: number, options?: Intl.NumberFormatOptions) => string
  highlighted?: boolean
  dot?: boolean
}) {
  return (
    <div className="flex flex-col items-end leading-none gap-0.5">
      <span className="text-[10px] uppercase tracking-wider text-text-tertiary font-medium inline-flex items-center gap-1.5">
        {dot && (
          <span
            aria-hidden
            className="inline-block w-1.5 h-1.5 rounded-full"
            style={{ background: color }}
          />
        )}
        {label}
      </span>
      <span
        className={cn('font-semibold', highlighted ? 'text-base' : 'text-sm')}
        style={{ color, fontVariantNumeric: 'tabular-nums lining-nums' }}
      >
        {money(value)}
      </span>
    </div>
  )
}

function CustomTooltip({ active, payload, label, money }: TooltipProps<number, string> & { money: (value: number, options?: Intl.NumberFormatOptions) => string }) {
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
        background: 'rgba(3,3,6,0.94)',
        backdropFilter: 'blur(12px)',
        WebkitBackdropFilter: 'blur(12px)',
        border: '1px solid var(--color-border-medium)',
        boxShadow: 'var(--shadow-tooltip)',
      }}
    >
      <div className="text-[10px] uppercase tracking-wider text-text-tertiary mb-1">{label}</div>
      <div className="space-y-0.5">
        <Row label="Ingresos" value={income} color={COLOR_INCOME} money={money} />
        <Row label="Gastos" value={expense} color={COLOR_EXPENSE} money={money} />
        <div className="h-px my-1 bg-border-subtle" />
        <Row label="Neto" value={net} color={net >= 0 ? COLOR_INCOME : COLOR_EXPENSE} money={money} bold />
      </div>
    </div>
  )
}

function Row({
  label,
  value,
  color,
  money,
  bold,
}: {
  label: string
  value: number
  color: string
  money: (value: number, options?: Intl.NumberFormatOptions) => string
  bold?: boolean
}) {
  return (
    <div className="flex items-center justify-between gap-4">
      <span className="text-text-tertiary">{label}</span>
      <span
        style={{
          color,
          fontWeight: bold ? 700 : 500,
          fontVariantNumeric: 'tabular-nums lining-nums',
        }}
      >
        {money(value)}
      </span>
    </div>
  )
}

function formatCompact(value: number): string {
  if (Math.abs(value) >= 1000) return `${(value / 1000).toFixed(1)}k`
  return value.toFixed(0)
}
