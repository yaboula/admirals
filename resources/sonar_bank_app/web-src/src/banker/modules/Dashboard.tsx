import { motion } from 'motion/react'
import {
  Users,
  Wallet,
  HandCoins,
  PiggyBank,
  Activity,
  CircleDollarSign,
  ChartNoAxesColumn,
  TrendingUp,
  type LucideIcon,
} from 'lucide-react'
import {
  AreaChart,
  Area,
  ResponsiveContainer,
  XAxis,
  YAxis,
  Tooltip,
  PieChart,
  Pie,
  Cell,
  Legend,
  BarChart,
  Bar,
} from 'recharts'
import { useBankerBootstrap, useBankerDashboard } from '../data/queries'
import { formatMinorCompact, formatMinor, compactNumber } from '../lib/format'
import type { BankerAccountClassRow, BankerLoanPortfolioRow, BankerTimeseriesRow } from '../data/contractsF2'

const PIE_COLORS = ['#FF6413', '#FFB047', '#22D3EE', '#34D399', '#A78BFA', '#F472B6']

export function BankerDashboard() {
  const bootstrap = useBankerBootstrap()
  const dashboard = useBankerDashboard(14)

  const employee = bootstrap.data?.employee
  const branding = bootstrap.data?.branding
  const k = dashboard.data?.kpis
  const byClass = dashboard.data?.accounts_by_class ?? []
  const ts = dashboard.data?.transfers_timeseries ?? []
  const portfolio = dashboard.data?.loan_portfolio ?? []

  return (
    <div className="px-8 py-7 space-y-7">
      {/* Welcome strip */}
      <motion.section
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className="rounded-3xl border border-white/10 bg-[radial-gradient(ellipse_at_top_right,rgba(255,100,19,0.12),transparent_55%),rgba(255,255,255,0.025)] p-7"
      >
        <div className="flex items-start justify-between gap-6">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">
              Sala de mando · {employee?.role_label ?? employee?.role}
            </p>
            <h1 className="mt-2 text-3xl font-semibold text-text-primary">
              {branding?.bank_name ?? 'SONAR Bank'}
            </h1>
            <p className="mt-2 max-w-xl text-sm text-text-secondary">
              {branding?.welcome_message ?? 'Resumen ejecutivo del banco. Tasas, depósitos, cartera y empleados — todo en tiempo real.'}
            </p>
          </div>
          <div className="text-right">
            <span
              className="rounded-full px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wider text-black"
              style={{ background: 'var(--banker-primary)' }}
            >
              {employee?.role_label ?? employee?.role}
            </span>
            <p className="mt-2 font-mono text-xs text-text-tertiary">
              {employee?.citizen_id}
            </p>
          </div>
        </div>
      </motion.section>

      {/* KPI grid */}
      <section className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
        <KpiCard
          icon={Users}
          label="Clientes"
          value={compactNumber(k?.total_customers)}
          hint={`${compactNumber(k?.total_accounts)} cuentas activas`}
          loading={dashboard.isLoading}
        />
        <KpiCard
          icon={Wallet}
          label="Depósitos totales"
          value={formatMinorCompact(k?.total_balance_minor)}
          hint={`+ ahorros ${formatMinorCompact(k?.total_savings_minor)}`}
          loading={dashboard.isLoading}
          accent
        />
        <KpiCard
          icon={HandCoins}
          label="Cartera de préstamos"
          value={formatMinorCompact(k?.loans_outstanding_minor)}
          hint={`${k?.loans_active ?? 0} activos · ${k?.loans_pending ?? 0} pendientes`}
          loading={dashboard.isLoading}
        />
        <KpiCard
          icon={PiggyBank}
          label="Empleados activos"
          value={compactNumber(k?.employees_active)}
          hint={`${k?.frozen_accounts ?? 0} cuentas congeladas`}
          loading={dashboard.isLoading}
        />
      </section>

      {/* Charts row */}
      <section className="grid grid-cols-1 gap-5 xl:grid-cols-3">
        {/* Transfers timeseries */}
        <Card icon={ChartNoAxesColumn} title="Volumen de transferencias" subtitle="Últimos 14 días" className="xl:col-span-2">
          <div className="h-64 mt-2">
            {dashboard.isLoading ? (
              <Skeleton />
            ) : ts.length === 0 ? (
              <Empty hint="Sin transferencias en este periodo" />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={ts.map(normalizeTs)}>
                  <defs>
                    <linearGradient id="vol" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="var(--banker-primary)" stopOpacity={0.5} />
                      <stop offset="100%" stopColor="var(--banker-primary)" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <XAxis dataKey="day" tick={{ fontSize: 10, fill: 'rgba(255,255,255,0.5)' }} stroke="rgba(255,255,255,0.1)" />
                  <YAxis tick={{ fontSize: 10, fill: 'rgba(255,255,255,0.5)' }} stroke="rgba(255,255,255,0.1)" tickFormatter={(v) => formatMinorCompact(v as number)} />
                  <Tooltip
                    contentStyle={{ background: 'rgba(8,8,12,0.95)', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 12, fontSize: 12 }}
                    labelStyle={{ color: 'rgba(255,255,255,0.7)' }}
                    formatter={(value: number, name) =>
                      name === 'volume_minor' ? [formatMinor(value), 'Volumen'] : [value, name]
                    }
                  />
                  <Area type="monotone" dataKey="volume_minor" stroke="var(--banker-primary)" strokeWidth={2} fill="url(#vol)" />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </div>
        </Card>

        {/* Account class pie */}
        <Card icon={CircleDollarSign} title="Cuentas por clase" subtitle="Distribución actual">
          <div className="h-64">
            {dashboard.isLoading ? (
              <Skeleton />
            ) : byClass.length === 0 ? (
              <Empty hint="Sin cuentas activas" />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={byClass.map((row, i) => ({ name: prettyClass(row.account_class), value: row.n, color: PIE_COLORS[i % PIE_COLORS.length] }))}
                    dataKey="value"
                    cx="50%"
                    cy="50%"
                    innerRadius={45}
                    outerRadius={75}
                    paddingAngle={2}
                  >
                    {byClass.map((_row, i) => (
                      <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} stroke="rgba(0,0,0,0.4)" strokeWidth={1} />
                    ))}
                  </Pie>
                  <Legend
                    iconType="circle"
                    wrapperStyle={{ fontSize: 11, color: 'rgba(255,255,255,0.65)' }}
                  />
                  <Tooltip
                    contentStyle={{ background: 'rgba(8,8,12,0.95)', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 12, fontSize: 12 }}
                  />
                </PieChart>
              </ResponsiveContainer>
            )}
          </div>
        </Card>
      </section>

      {/* Loan portfolio bar */}
      <section>
        <Card icon={TrendingUp} title="Cartera de préstamos por producto" subtitle="Sólo préstamos activos">
          <div className="h-56 mt-2">
            {dashboard.isLoading ? (
              <Skeleton />
            ) : portfolio.length === 0 ? (
              <Empty hint="Sin préstamos activos" />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={portfolio.map(normalizePortfolio)}>
                  <XAxis dataKey="product_id" tick={{ fontSize: 11, fill: 'rgba(255,255,255,0.55)' }} stroke="rgba(255,255,255,0.1)" />
                  <YAxis tick={{ fontSize: 10, fill: 'rgba(255,255,255,0.5)' }} stroke="rgba(255,255,255,0.1)" tickFormatter={(v) => formatMinorCompact(v as number)} />
                  <Tooltip
                    contentStyle={{ background: 'rgba(8,8,12,0.95)', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 12, fontSize: 12 }}
                    formatter={(value: number) => [formatMinor(value), 'Outstanding']}
                  />
                  <Bar dataKey="outstanding_minor" fill="var(--banker-primary)" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </Card>
      </section>

      {/* Footer info */}
      <section className="rounded-2xl border border-white/[0.06] bg-white/[0.015] p-5 text-xs text-text-tertiary">
        <div className="flex items-center gap-2">
          <Activity size={14} className="text-text-tertiary" />
          <span>
            Snapshot {dashboard.data?.fetched_at_ms ? new Date(dashboard.data.fetched_at_ms).toLocaleTimeString() : '—'}
            {' · refrescado cada 60s · ventana 14 días'}
          </span>
        </div>
      </section>
    </div>
  )
}

// ---------------------- helpers ----------------------

function normalizeTs(row: BankerTimeseriesRow): BankerTimeseriesRow {
  return {
    day: row.day?.slice(5) ?? '—',
    n: Number(row.n) || 0,
    volume_minor: Number(row.volume_minor) || 0,
  }
}

function normalizePortfolio(row: BankerLoanPortfolioRow) {
  return {
    product_id: row.product_id ?? '—',
    n: Number(row.n) || 0,
    outstanding_minor: Number(row.outstanding_minor) || 0,
  }
}

function prettyClass(c: string): string {
  switch (c) {
    case 'checking': return 'Corriente'
    case 'savings': return 'Ahorros'
    case 'business_treasury': return 'Profesional'
    case 'shared': return 'Compartida'
    case 'govt_treasury': return 'Tesoro'
    case 'escrow': return 'Escrow'
    case 'crypto_wallet': return 'Cripto'
    default: return c
  }
}

void ([] as BankerAccountClassRow[]) // keep type imported

function KpiCard({
  icon: Icon,
  label,
  value,
  hint,
  loading,
  accent,
}: {
  icon: LucideIcon
  label: string
  value: string
  hint: string
  loading?: boolean
  accent?: boolean
}) {
  return (
    <motion.div
      whileHover={{ y: -2 }}
      className="relative overflow-hidden rounded-2xl border border-white/10 p-5"
      style={{
        background: accent
          ? 'linear-gradient(135deg, rgba(255,100,19,0.1), rgba(255,176,71,0.04))'
          : 'rgba(255,255,255,0.025)',
      }}
    >
      <div className="flex items-center gap-2 text-text-tertiary">
        <Icon size={14} className="opacity-80" />
        <span className="text-[11px] uppercase tracking-[0.18em]">{label}</span>
      </div>
      {loading ? (
        <div className="mt-3 h-9 w-24 animate-pulse rounded-md bg-white/5" />
      ) : (
        <p className="mt-3 text-3xl font-semibold text-text-primary">{value}</p>
      )}
      <p className="mt-1 text-xs text-text-tertiary">{hint}</p>
    </motion.div>
  )
}

function Card({
  icon: Icon,
  title,
  subtitle,
  children,
  className,
}: {
  icon: LucideIcon
  title: string
  subtitle: string
  children: React.ReactNode
  className?: string
}) {
  return (
    <div className={`rounded-3xl border border-white/10 bg-white/[0.025] p-5 ${className ?? ''}`}>
      <div className="flex items-center gap-3">
        <div className="flex h-9 w-9 items-center justify-center rounded-xl border border-white/10 bg-white/[0.04]">
          <Icon size={16} className="text-[var(--banker-primary)]" />
        </div>
        <div>
          <p className="text-sm font-semibold text-text-primary">{title}</p>
          <p className="text-[11px] text-text-tertiary">{subtitle}</p>
        </div>
      </div>
      {children}
    </div>
  )
}

function Skeleton() {
  return <div className="h-full w-full animate-pulse rounded-xl bg-white/[0.015]" />
}

function Empty({ hint }: { hint: string }) {
  return (
    <div className="flex h-full w-full items-center justify-center rounded-xl border border-dashed border-white/10 bg-white/[0.01]">
      <p className="text-xs text-text-tertiary">{hint}</p>
    </div>
  )
}
