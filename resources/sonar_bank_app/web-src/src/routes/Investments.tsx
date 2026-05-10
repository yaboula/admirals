import { motion } from 'motion/react'
import { Area, AreaChart, ResponsiveContainer } from 'recharts'
import { AlertTriangle, ArrowDownRight, ArrowUpRight, BarChart3, Fingerprint, Gauge, Gem, LineChart, LockKeyhole, Radar, type LucideIcon } from 'lucide-react'
import { useStockListQuery, useStockPortfolioQuery } from '@/data/queries'
import type { PortfolioHolding, StockQuote } from '@/data/contracts'
import { Badge, Spinner } from '@/components/ui'
import { useI18n } from '@/lib/i18n'
import { maskMoneyDisplay } from '@/lib/privacy'
import { cn } from '@/lib/utils'
import { usePrivacyMode } from '@/stores/privacy'

export function Investments() {
  const { t, money, number, dateTime } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const stocksQuery = useStockListQuery()
  const portfolioQuery = useStockPortfolioQuery()

  const quotes: StockQuote[] = stocksQuery.data?.items ?? []
  const portfolio = portfolioQuery.data
  const holdings: PortfolioHolding[] = portfolio?.holdings ?? []
  const quoteBySymbol = new Map(quotes.map((quote) => [quote.symbol, quote]))
  const loading = stocksQuery.isLoading || portfolioQuery.isLoading
  const error = stocksQuery.isError || portfolioQuery.isError
  const updatedAt = Math.max(stocksQuery.data?.fetched_at_ms ?? 0, portfolio?.fetched_at_ms ?? 0)
  const topMover = [...quotes].sort((a, b) => Math.abs(b.change_24h_pct) - Math.abs(a.change_24h_pct))[0] ?? null
  const allocation = buildAllocation(holdings, quoteBySymbol)

  return (
    <main className="relative h-full min-h-0 overflow-y-auto bg-surface-abyss px-5 py-4 lg:px-6 scrollbar-thin">
      <div aria-hidden className="pointer-events-none fixed inset-0 opacity-70">
        <div className="absolute left-[6%] top-[5%] h-72 w-72 rounded-full bg-brand-signal-orange/10" style={{ filter: 'blur(92px)' }} />
        <div className="absolute bottom-[10%] right-[8%] h-80 w-80 rounded-full bg-semantic-success-deep/10" style={{ filter: 'blur(110px)' }} />
        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.028)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:42px_42px] [mask-image:radial-gradient(circle_at_center,black,transparent_78%)]" />
      </div>

      <div className="relative mx-auto flex w-full max-w-[1220px] flex-col gap-4 pb-6">
        <motion.section initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28 }} className="relative overflow-hidden rounded-[2.3rem] border border-white/10 bg-[radial-gradient(circle_at_70%_45%,rgba(0,173,91,0.18),transparent_28%),radial-gradient(circle_at_24%_16%,rgba(246,75,0,0.2),transparent_34%),linear-gradient(135deg,rgba(3,4,7,0.82),rgba(0,0,0,0.96))] p-5 shadow-[0_28px_90px_rgba(0,0,0,0.5)] md:p-6">
          <div className="absolute right-[-8%] top-[-22%] h-64 w-64 rounded-full border border-white/10" />
          <div className="absolute bottom-[-34%] left-[18%] h-80 w-80 rounded-full border border-brand-signal-orange/10" />
          <div className="relative grid min-h-[330px] gap-6 xl:grid-cols-[minmax(0,0.95fr)_360px_minmax(300px,0.74fr)]">
            <div className="flex min-w-0 flex-col justify-between gap-6">
              <div>
                <div className="inline-flex items-center gap-2 rounded-full border border-brand-signal-orange/25 bg-brand-signal-orange-subtle px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.18em] text-brand-signal-orange-light">
                  <Fingerprint size={13} strokeWidth={2.2} />
                  {t('investments.eyebrow')}
                </div>
                <h1 className="mt-5 max-w-[10ch] text-5xl font-light leading-[0.9] tracking-[-0.085em] text-text-primary md:text-6xl">
                  {t('investments.title')}
                </h1>
                <p className="mt-4 max-w-xl text-sm leading-relaxed text-text-secondary">{t('investments.description')}</p>
              </div>
              <div className="grid gap-2 sm:grid-cols-3">
                <IdentityPill icon={LockKeyhole} label={t('investments.readOnly')} value={t('investments.executionLocked')} />
                <IdentityPill icon={Radar} label={t('investments.dataPlane')} value={updatedAt ? dateTime(updatedAt, { timeStyle: 'short' }) : '—'} />
                <IdentityPill icon={Gauge} label={t('investments.topMover')} value={topMover ? topMover.symbol : '—'} tone={topMover && topMover.change_24h_pct < 0 ? 'danger' : 'success'} />
              </div>
            </div>

            <VaultCore holdings={holdings} quotes={quoteBySymbol} streamerMode={streamerMode} />

            <div className="flex min-w-0 flex-col justify-between gap-4 rounded-[1.9rem] border border-white/10 bg-black/30 p-4 backdrop-blur-xl">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-text-tertiary">{t('investments.portfolioValue')}</p>
                <p className="mt-2 truncate text-4xl font-semibold tracking-[-0.06em] text-text-primary tactile-tabular-nums">
                  {portfolio ? streamerMode ? maskMoneyDisplay() : money(portfolio.total_market_value_minor / 100) : '—'}
                </p>
                <div className="mt-3 flex flex-wrap items-center gap-2">
                  <Badge tone={(portfolio?.total_delta_pct ?? 0) >= 0 ? 'success' : 'danger'} variant="soft">
                    {portfolio ? number(portfolio.total_delta_pct, { signDisplay: 'exceptZero', maximumFractionDigits: 1 }) : '—'}%
                  </Badge>
                  <span className="text-xs text-text-tertiary">{t('investments.totalReturn')}</span>
                </div>
              </div>
              <div className="grid gap-2">
                <TerminalStat label={t('investments.costBasis')} value={portfolio ? streamerMode ? maskMoneyDisplay() : money(portfolio.total_cost_basis_minor / 100) : '—'} />
                <TerminalStat label={t('investments.dayWatchlist')} value={number(quotes.length)} />
                <TerminalStat label={t('investments.holdings')} value={number(holdings.length)} />
              </div>
            </div>
          </div>
        </motion.section>

        {loading ? (
          <div className="flex min-h-[420px] items-center justify-center rounded-[2rem] border border-white/10 bg-white/[0.035]">
            <div className="flex flex-col items-center gap-3 text-text-secondary">
              <Spinner size="md" />
              <span className="text-sm">{t('investments.loading')}</span>
            </div>
          </div>
        ) : error || !portfolio ? (
          <InvestmentsEmpty icon={AlertTriangle} title={t('investments.errorTitle')} description={t('investments.errorDescription')} />
        ) : (
          <motion.section initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28, delay: 0.05 }} className="grid gap-4 xl:grid-cols-[minmax(0,1fr)_380px]">
            <div className="overflow-hidden rounded-[2rem] border border-white/10 bg-[linear-gradient(180deg,rgba(255,255,255,0.055),rgba(255,255,255,0.025))]">
              <div className="flex flex-wrap items-center justify-between gap-3 border-b border-white/10 px-5 py-4">
                <div>
                  <p className="text-sm font-semibold text-text-primary">{t('investments.market')}</p>
                  <p className="mt-0.5 text-xs text-text-tertiary">{t('investments.marketDescription')}</p>
                </div>
                <Badge tone="info" variant="soft" leftIcon={<LineChart size={12} strokeWidth={2.2} />}>{t('investments.marketPulse')}</Badge>
              </div>
              <div className="grid gap-2 p-3">
                {quotes.map((quote, index) => (
                  <MarketPulseRow key={quote.symbol} quote={quote} holding={holdings.find((item) => item.symbol === quote.symbol)} rank={index + 1} />
                ))}
              </div>
            </div>

            <aside className="grid gap-4">
              <div className="overflow-hidden rounded-[2rem] border border-white/10 bg-[radial-gradient(circle_at_50%_0%,rgba(246,75,0,0.13),transparent_46%),rgba(255,255,255,0.035)]">
                <div className="border-b border-white/10 px-5 py-4">
                  <p className="text-sm font-semibold text-text-primary">{t('investments.allocationMap')}</p>
                  <p className="mt-0.5 text-xs text-text-tertiary">{t('investments.allocationDescription')}</p>
                </div>
                <div className="space-y-3 p-4">
                  {allocation.length === 0 ? (
                    <InvestmentsEmpty icon={BarChart3} title={t('investments.noHoldingsTitle')} description={t('investments.noHoldingsDescription')} compact />
                  ) : (
                    allocation.map((item) => <AllocationStrip key={item.sector} item={item} />)
                  )}
                </div>
              </div>

              <div className="overflow-hidden rounded-[2rem] border border-white/10 bg-white/[0.035]">
                <div className="border-b border-white/10 px-5 py-4">
                  <p className="text-sm font-semibold text-text-primary">{t('investments.holdings')}</p>
                  <p className="mt-0.5 text-xs text-text-tertiary">{t('investments.holdingsDescription')}</p>
                </div>
                <div className="max-h-[330px] overflow-y-auto p-3 scrollbar-thin">
                  <div className="space-y-2">
                    {holdings.map((holding) => (
                      <HoldingCapsule key={holding.holding_id} holding={holding} quote={quoteBySymbol.get(holding.symbol) ?? null} />
                    ))}
                  </div>
                </div>
              </div>
            </aside>
          </motion.section>
        )}
      </div>
    </main>
  )
}

function VaultCore({ holdings, quotes, streamerMode }: { holdings: PortfolioHolding[]; quotes: Map<string, StockQuote>; streamerMode: boolean }) {
  const { t, money, number } = useI18n()
  const total = holdings.reduce((sum, holding) => sum + holding.market_value_minor, 0)
  return (
    <div className="relative flex min-h-[300px] items-center justify-center">
      <div className="absolute left-1/2 top-1/2 h-72 w-72 -translate-x-1/2 -translate-y-1/2 rounded-full border border-white/10 bg-[conic-gradient(from_120deg,rgba(246,75,0,0.34),rgba(0,173,91,0.22),transparent,rgba(246,75,0,0.34))] p-[1px] shadow-[0_0_70px_rgba(255,103,18,0.10)]">
        <div className="h-full w-full rounded-full bg-black/80" />
      </div>
      <div className="absolute left-1/2 top-1/2 h-56 w-56 -translate-x-1/2 -translate-y-1/2 rounded-full border border-white/10" />
      <div className="absolute left-1/2 top-1/2 h-40 w-40 -translate-x-1/2 -translate-y-1/2 rounded-full border border-brand-signal-orange/20" />
      <div className="relative z-[1] flex h-44 w-44 flex-col items-center justify-center rounded-full border border-white/15 bg-[radial-gradient(circle_at_50%_25%,rgba(255,255,255,0.14),rgba(255,255,255,0.025)_48%,rgba(0,0,0,0.72))] text-center shadow-[inset_0_1px_24px_rgba(255,255,255,0.08)]">
        <Gem className="text-brand-signal-orange-light" size={28} strokeWidth={1.8} />
        <p className="mt-3 text-[10px] font-semibold uppercase tracking-[0.18em] text-text-tertiary">{t('investments.assetCore')}</p>
        <p className="mt-1 text-xl font-semibold text-text-primary tactile-tabular-nums">{streamerMode ? maskMoneyDisplay() : money(total / 100)}</p>
      </div>
      {holdings.slice(0, 5).map((holding, index) => {
        const angle = -90 + index * (360 / Math.max(holdings.length, 1))
        const radius = 136
        const x = Math.cos(angle * Math.PI / 180) * radius
        const y = Math.sin(angle * Math.PI / 180) * radius
        const quote = quotes.get(holding.symbol)
        return (
          <div key={holding.holding_id} className="absolute left-1/2 top-1/2 z-[2] rounded-full border border-white/10 bg-black/70 px-3 py-1 text-[11px] font-semibold text-text-primary shadow-[0_10px_30px_rgba(0,0,0,0.45)] backdrop-blur-xl" style={{ transform: `translate(calc(-50% + ${x}px), calc(-50% + ${y}px))` }}>
            <span className="text-brand-signal-orange-light">{holding.symbol}</span>
            <span className="ml-2 text-text-tertiary">{quote ? number(quote.change_24h_pct, { signDisplay: 'exceptZero', maximumFractionDigits: 1 }) : '—'}%</span>
          </div>
        )
      })}
    </div>
  )
}

function IdentityPill({ icon: Icon, label, value, tone = 'neutral' }: { icon: LucideIcon; label: string; value: string; tone?: 'neutral' | 'success' | 'danger' }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-black/30 px-3 py-2 backdrop-blur-xl">
      <div className="flex items-center gap-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-text-tertiary">
        <Icon size={13} strokeWidth={2.1} />
        {label}
      </div>
      <p className={cn('mt-1 truncate text-sm font-semibold tactile-tabular-nums', tone === 'success' ? 'text-semantic-success' : tone === 'danger' ? 'text-semantic-danger' : 'text-text-primary')}>{value}</p>
    </div>
  )
}

function TerminalStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3 rounded-2xl border border-white/8 bg-white/[0.035] px-3 py-2">
      <span className="text-xs text-text-tertiary">{label}</span>
      <span className="text-sm font-semibold text-text-primary tactile-tabular-nums">{value}</span>
    </div>
  )
}

function MarketPulseRow({ quote, holding, rank }: { quote: StockQuote; holding?: PortfolioHolding; rank: number }) {
  const { t, money, number } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const positive = quote.change_24h_pct >= 0
  const Icon = positive ? ArrowUpRight : ArrowDownRight
  return (
    <div className="grid grid-cols-[44px_minmax(0,1fr)_156px_176px] items-center gap-3 rounded-[1.35rem] border border-white/10 bg-black/30 px-3 py-3 transition-colors hover:bg-white/[0.045] max-lg:grid-cols-[36px_minmax(0,1fr)_132px]">
      <span className="flex h-9 w-9 items-center justify-center rounded-full border border-white/10 bg-white/[0.035] text-xs font-semibold text-text-tertiary">{rank.toString().padStart(2, '0')}</span>
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <p className="truncate text-sm font-semibold text-text-primary">{quote.symbol}</p>
          {holding && <Badge tone="neutral" variant="soft" size="xs">{t('investments.inVault')}</Badge>}
        </div>
        <p className="mt-1 truncate text-xs text-text-tertiary">{quote.name} · {quote.sector}</p>
      </div>
      <MarketSparkline quote={quote} />
      <div className="grid min-w-0 grid-cols-[minmax(0,1fr)_auto] items-center gap-3">
        <span className="truncate text-right text-sm font-semibold text-text-primary tactile-tabular-nums max-sm:hidden">{streamerMode ? maskMoneyDisplay() : money(quote.price_minor / 100)}</span>
        <Badge tone={positive ? 'success' : 'danger'} variant="soft" leftIcon={<Icon size={12} strokeWidth={2.3} />}>{number(quote.change_24h_pct, { signDisplay: 'exceptZero', maximumFractionDigits: 1 })}%</Badge>
      </div>
    </div>
  )
}

function MarketSparkline({ quote }: { quote: StockQuote }) {
  const positive = quote.change_24h_pct >= 0
  const data = buildSparklineData(quote)
  const color = positive ? 'rgb(0, 173, 91)' : 'rgb(234, 60, 63)'
  const gradientId = `market-spark-${quote.symbol.replace(/[^a-zA-Z0-9_-]/g, '')}`
  return (
    <div className="h-14 w-[156px] overflow-hidden max-lg:hidden">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 6, right: 4, bottom: 6, left: 4 }}>
          <defs>
            <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={color} stopOpacity={0.28} />
              <stop offset="100%" stopColor={color} stopOpacity={0} />
            </linearGradient>
          </defs>
          <Area
            type="monotone"
            dataKey="value"
            stroke={color}
            strokeWidth={2.2}
            fill={`url(#${gradientId})`}
            dot={false}
            activeDot={false}
            isAnimationActive={false}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  )
}

interface SparklinePoint {
  index: number
  value: number
}

function buildSparklineData(quote: StockQuote): SparklinePoint[] {
  const seed = quote.symbol.split('').reduce((sum, char) => sum + char.charCodeAt(0), 0)
  const trend = Math.max(-1, Math.min(1, quote.change_24h_pct / 6))
  return Array.from({ length: 24 }, (_, index) => {
    const progress = index / 23
    const waveA = Math.sin(seed * 0.17 + index * 0.72) * 8
    const waveB = Math.cos(seed * 0.11 + index * 0.39) * 5
    return {
      index,
      value: 50 + waveA + waveB + trend * progress * 24,
    }
  })
}

function AllocationStrip({ item }: { item: AllocationItem }) {
  const { number } = useI18n()
  return (
    <div className="rounded-[1.2rem] border border-white/10 bg-black/25 p-3">
      <div className="flex items-center justify-between gap-3">
        <span className="truncate text-sm font-semibold text-text-primary">{item.sector}</span>
        <span className="text-xs font-semibold text-brand-signal-orange-light tactile-tabular-nums">{number(item.weight, { maximumFractionDigits: 1 })}%</span>
      </div>
      <div className="mt-3 h-2 overflow-hidden rounded-full bg-white/[0.06]">
        <div className="h-full rounded-full bg-[linear-gradient(90deg,rgb(246, 75, 0),rgb(0, 173, 91))]" style={{ width: `${Math.max(4, item.weight)}%` }} />
      </div>
    </div>
  )
}

function HoldingCapsule({ holding, quote }: { holding: PortfolioHolding; quote: StockQuote | null }) {
  const { t, money, number } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const positive = holding.delta_pct >= 0
  return (
    <div className="rounded-[1.2rem] border border-white/10 bg-black/25 p-3">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="truncate text-sm font-semibold text-text-primary">{quote?.name ?? holding.symbol}</p>
          <p className="mt-1 truncate text-xs text-text-tertiary">{holding.symbol} · {t('investments.sharesInPortfolio').replace('{count}', number(holding.qty))}</p>
        </div>
        <Badge tone={positive ? 'success' : 'danger'} variant="soft">{number(holding.delta_pct, { signDisplay: 'exceptZero', maximumFractionDigits: 1 })}%</Badge>
      </div>
      <div className="mt-3 flex items-center justify-between gap-3 text-xs text-text-secondary">
        <span>{streamerMode ? maskMoneyDisplay() : money(holding.cost_basis_minor / 100)}</span>
        <span className="font-semibold text-text-primary tactile-tabular-nums">{streamerMode ? maskMoneyDisplay() : money(holding.market_value_minor / 100)}</span>
      </div>
    </div>
  )
}

function InvestmentsEmpty({ icon: Icon, title, description, compact }: { icon: LucideIcon; title: string; description: string; compact?: boolean }) {
  return (
    <div className={cn('flex flex-col items-center justify-center gap-3 p-6 text-center', compact ? 'min-h-[220px]' : 'min-h-[420px] rounded-[2rem] border border-white/10 bg-white/[0.035]')}>
      <span className="inline-flex h-14 w-14 items-center justify-center rounded-full border border-white/10 bg-white/[0.04] text-text-secondary">
        <Icon size={24} strokeWidth={1.8} />
      </span>
      <div className="flex max-w-[34ch] flex-col gap-1">
        <h2 className="text-base font-semibold text-text-primary">{title}</h2>
        <p className="text-sm leading-relaxed text-text-tertiary">{description}</p>
      </div>
    </div>
  )
}

interface AllocationItem {
  sector: string
  weight: number
}

function buildAllocation(holdings: PortfolioHolding[], quotes: Map<string, StockQuote>): AllocationItem[] {
  const total = holdings.reduce((sum, holding) => sum + holding.market_value_minor, 0)
  if (total <= 0) return []
  const bySector = holdings.reduce<Record<string, number>>((acc, holding) => {
    const sector = quotes.get(holding.symbol)?.sector ?? 'Unclassified'
    acc[sector] = (acc[sector] ?? 0) + holding.market_value_minor
    return acc
  }, {})
  return Object.entries(bySector)
    .map(([sector, value]) => ({ sector, weight: value / total * 100 }))
    .sort((a, b) => b.weight - a.weight)
}
