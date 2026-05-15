import { useMemo, useState } from 'react'
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis, type TooltipProps } from 'recharts'
import type { Account, Transaction } from '@/data/contracts'
import { Card } from '@/components/ui'
import { useI18n } from '@/lib/i18n'
import { maskMoneyDisplay } from '@/lib/privacy'
import { usePrivacyMode } from '@/stores/privacy'

interface GraphPoint {
  label: string
  balance: number
}

export interface HomeBalanceGraphProps {
  account: Account | undefined
  transactions: Transaction[]
}

const ORANGE = 'var(--color-brand-signal-orange)'
const ORANGE_SOFT = 'rgb(206, 71, 20)'
const PERIODS = [
  { key: '3d', label: 'home.period3d', days: 3 },
  { key: '1w', label: 'home.period1w', days: 7 },
  { key: '2w', label: 'home.period2w', days: 14 },
  { key: '1m', label: 'home.period1m', days: 30 },
] as const

type PeriodKey = (typeof PERIODS)[number]['key']

export function HomeBalanceGraph({ account, transactions }: HomeBalanceGraphProps) {
  const { t, money, number, intlLocale } = useI18n()
  const [period, setPeriod] = useState<PeriodKey>('1m')
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const activePeriod = PERIODS.find((item) => item.key === period) ?? PERIODS[3]
  const data = useMemo(
    () => buildGraph(account, transactions, activePeriod.days, intlLocale),
    [account, activePeriod.days, transactions, intlLocale],
  )
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
            'radial-gradient(circle at 18% 0%, rgba(246,75,0,0.13), transparent 34%), linear-gradient(180deg, rgba(255,255,255,0.04), transparent 48%)',
        }}
      />
      <div className="relative h-full min-h-0 flex flex-col p-5 2xl:p-6">
        <div className="flex items-start justify-between gap-4 shrink-0">
          <div className="flex flex-col gap-1.5">
            <span className="text-sm text-text-secondary font-medium">{t('home.totalBalance')}</span>
            <div className="flex items-baseline gap-2.5">
              <span className="text-3xl 2xl:text-4xl font-light tracking-[-0.04em] tactile-tabular-nums text-text-primary">
                {streamerMode ? maskMoneyDisplay() : money(balance)}
              </span>
              <span
                className="text-xs font-semibold tactile-tabular-nums"
                style={{ color: deltaPct >= 0 ? 'rgb(95, 211, 127)' : 'rgb(255, 111, 105)' }}
              >
                {streamerMode ? '•••%' : `${deltaPct >= 0 ? '↑' : '↓'} ${number(Math.abs(deltaPct), { maximumFractionDigits: 2 })}%`}
              </span>
            </div>
          </div>
          <div className="hidden md:flex items-center gap-1.5 rounded-full p-1" style={{ background: 'rgba(255,255,255,0.05)' }}>
            {PERIODS.map((item) => {
              const active = item.key === period
              return (
              <button
                key={item.key}
                type="button"
                onClick={() => setPeriod(item.key)}
                className="h-8 rounded-full px-3 text-[11px] font-medium text-text-secondary"
                style={
                  active
                    ? { background: 'rgba(255,255,255,0.1)', color: 'var(--color-text-primary)' }
                    : undefined
                }
              >
                {t(item.label)}
              </button>
              )
            })}
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
              <CartesianGrid stroke="rgba(255,255,255,0.06)" strokeDasharray="3 5" vertical={false} />
              <XAxis
                dataKey="label"
                tick={{ fill: 'rgb(137, 140, 148)', fontSize: 10 }}
                tickLine={false}
                axisLine={false}
                interval={0}
                minTickGap={10}
              />
              <YAxis
                tick={{ fill: 'rgb(119, 122, 130)', fontSize: 10 }}
                tickLine={false}
                axisLine={false}
                width={44}
                orientation="right"
                tickFormatter={(value: number) => streamerMode ? '•••' : `${Math.round(value / 1000)}k`}
              />
              <Tooltip content={<BalanceTooltip hidden={streamerMode} />} cursor={{ stroke: 'rgba(255,255,255,0.16)', strokeDasharray: '3 4' }} />
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
                hide={streamerMode}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="shrink-0 flex items-center justify-between gap-4 pt-2 text-[11px] text-text-tertiary">
          <span>{t('home.averageAnnualRate')} · {streamerMode ? maskMoneyDisplay() : money(Math.max(balance * 0.12, 840))}</span>
          <span className="inline-flex items-center gap-3">
            <span className="inline-flex items-center gap-1.5"><i className="h-2 w-2 rounded-sm bg-white" />{t('home.actualBalance')}</span>
            <span className="inline-flex items-center gap-1.5"><i className="h-2 w-2 rounded-sm" style={{ background: ORANGE }} />{t('home.projectedFlow')}</span>
          </span>
        </div>
      </div>
    </Card>
  )
}

function BalanceTooltip({ active, payload, label, hidden }: TooltipProps<number, string> & { hidden: boolean }) {
  const { money } = useI18n()
  if (!active || !payload?.length) return null
  const value = payload[0]?.value ?? 0
  return (
    <div className="rounded-2xl px-4 py-3 text-center" style={{ background: 'rgb(248, 248, 248)', color: 'rgb(1, 2, 3)', boxShadow: '0 18px 34px -20px rgba(0,0,0,0.8)' }}>
      <div className="text-xs font-semibold">{label}</div>
      <div className="text-sm font-bold tactile-tabular-nums">{hidden ? maskMoneyDisplay() : money(Number(value))}</div>
    </div>
  )
}

function compactIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '')
}

function buildGraph(account: Account | undefined, transactions: Transaction[], periodDays: number, locale: string): GraphPoint[] {
  const balance = account ? account.balance_minor / 100 : 0
  const own = compactIban(account?.iban)
  const end = new Date()
  end.setHours(23, 59, 59, 999)
  const start = new Date(end)
  start.setDate(start.getDate() - (periodDays - 1))
  start.setHours(0, 0, 0, 0)
  const bucketStepDays = periodDays <= 7 ? 1 : periodDays <= 14 ? 2 : 7
  const buckets = []
  for (let cursor = new Date(start); cursor.getTime() <= end.getTime(); cursor.setDate(cursor.getDate() + bucketStepDays)) {
    const from = new Date(cursor)
    from.setHours(0, 0, 0, 0)
    const to = new Date(cursor)
    to.setDate(to.getDate() + bucketStepDays - 1)
    to.setHours(23, 59, 59, 999)
    buckets.push({ from: from.getTime(), to: Math.min(to.getTime(), end.getTime()), date: new Date(Math.min(to.getTime(), end.getTime())) })
  }
  const bucketNet = buckets.map((bucket) => {
    return transactions.reduce((sum, tx) => {
      if (tx.timestamp_ms < bucket.from || tx.timestamp_ms > bucket.to || tx.status !== 'committed') return sum
      const fromOwn = own ? compactIban(tx.from_iban) === own : tx.direction === 'out'
      const toOwn = own ? compactIban(tx.to_iban) === own : tx.direction === 'in'
      if (toOwn && !fromOwn) return sum + tx.amount_minor / 100
      if (fromOwn && !toOwn) return sum - tx.amount_minor / 100
      return sum
    }, 0)
  })
  const points: GraphPoint[] = []
  let rolling = balance - bucketNet.reduce((sum, value) => sum + value, 0)
  buckets.forEach((bucket, index) => {
    rolling += bucketNet[index] ?? 0
    points.push({
      label: String(bucket.date.toLocaleDateString(locale, { day: '2-digit', month: 'short' }) ?? '').replace('.', ''),
      balance: Math.max(0, rolling),
    })
  })
  return points
}

function computeMonthDelta(transactions: Transaction[], ownIban: string | undefined): number {
  const own = compactIban(ownIban)
  const cutoff = Date.now() - 30 * 24 * 60 * 60 * 1000
  return transactions.reduce((sum, tx) => {
    if (tx.timestamp_ms < cutoff || tx.status !== 'committed') return sum
    const fromOwn = own ? compactIban(tx.from_iban) === own : tx.direction === 'out'
    const toOwn = own ? compactIban(tx.to_iban) === own : tx.direction === 'in'
    if (toOwn && !fromOwn) return sum + tx.amount_minor / 100
    if (fromOwn && !toOwn) return sum - tx.amount_minor / 100
    return sum
  }, 0)
}
