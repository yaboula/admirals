import { motion } from 'motion/react'
import { useBootstrap } from '@/data/queries'
import { HeroBalanceCard } from './home/HeroBalanceCard'
import { QuickActionsGrid } from './home/QuickActionsGrid'
import { QuickTransferList } from './home/QuickTransferList'
import { ActivityPreview } from './home/ActivityPreview'
import { Card, CardEyebrow, CardTitle, CardDescription, Badge } from '@/components/ui'
import { ArrowUpRight } from 'lucide-react'
import { useTransferWizard } from '@/stores/transferWizard'
import { toast } from '@/stores/toast'
import { useEffect } from 'react'

export function Home() {
  const { data, isLoading, isError, error } = useBootstrap()

  const initWizard = useTransferWizard((s) => s.init)

  useEffect(() => {
    if (isError && error) {
      toast.danger('Bootstrap falló', error.message ?? error.code)
    }
  }, [isError, error])

  const primaryAccount = data?.accounts[0]
  const transactions = data?.recent_transactions ?? []
  const portfolioSize = data?.portfolio.length ?? 0
  const cardsCount = data?.cards.length ?? 0
  const recurringCount = data?.recurring.length ?? 0
  const noticesCount = data?.outstanding_notices.length ?? 0

  return (
    <div className="mx-auto w-full max-w-7xl flex flex-col gap-6">
      {/* Page header */}
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.42, ease: [0.16, 1, 0.3, 1] }}
        className="flex items-end justify-between gap-4 flex-wrap mt-2"
      >
        <div className="flex flex-col gap-1.5">
          <span className="text-[10px] uppercase tracking-[0.22em] text-text-tertiary font-medium">
            Inicio · Resumen
          </span>
          <h1 className="text-3xl lg:text-4xl font-semibold tracking-tight tactile-wght-breathing">
            Tu actividad financiera
          </h1>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          {data?.cached && <Badge tone="info" variant="soft" size="sm">cache LRU</Badge>}
          <Badge tone="brand" variant="soft" size="sm" pulse>
            BANK-FE.2 · Vanguardia 2026
          </Badge>
        </div>
      </motion.div>

      {/* Hero + side stats */}
      <div className="grid grid-cols-1 lg:grid-cols-[2fr_1fr] gap-6 items-start">
        <HeroBalanceCard
          account={primaryAccount}
          transactions={transactions}
          loading={isLoading}
        />
        <div className="flex flex-col gap-4">
          <SideStatCard
            label="Tarjetas activas"
            value={cardsCount}
            sub={cardsCount === 0 ? 'Sin tarjetas emitidas' : `${cardsCount} en circulación`}
          />
          <SideStatCard
            label="Transferencias recurrentes"
            value={recurringCount}
            sub={recurringCount === 0 ? 'Ninguna programada' : 'Próximo cargo en…'}
          />
          <SideStatCard
            label="Avisos pendientes"
            value={noticesCount}
            sub={noticesCount === 0 ? 'Todo en orden' : 'Requiere tu atención'}
            tone={noticesCount > 0 ? 'warning' : 'neutral'}
          />
          <SideStatCard
            label="Posiciones en cartera"
            value={portfolioSize}
            sub={portfolioSize === 0 ? 'Aún no inviertes' : `${portfolioSize} activos`}
          />
        </div>
      </div>

      {/* Quick actions */}
      <QuickActionsGrid onSend={() => initWizard(true)} />

      {/* Express + activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <QuickTransferList />
        <ActivityPreview transactions={transactions} account={primaryAccount} loading={isLoading} />
      </div>

      {/* Footer disclaimer */}
      <div className="tactile-divider-shimmer mt-2" />
      <Card variant="glass" padding="md" className="text-xs text-text-tertiary">
        <div className="flex items-start gap-3">
          <ArrowUpRight size={14} className="mt-0.5 text-brand-signal-orange-light" />
          <div className="leading-relaxed">
            <strong className="text-text-secondary">Vista 1 — Bank Home (BANK-FE.2).</strong>{' '}
            Datos consumidos vía REQ-FE-001 (bootstrap consolidado) + REQ-FE-002 (recipients
            recientes) con TanStack Query v5 cache LRU 25-30s. Mock layer activo si{' '}
            <code className="text-text-secondary font-mono">VITE_MOCK_MODE=true</code>. Privacy boundary
            M004 aplicado: ningún saldo de empleados o flag de compliance ajeno expuesto.
          </div>
        </div>
      </Card>
    </div>
  )
}

function SideStatCard({
  label,
  value,
  sub,
  tone = 'neutral',
}: {
  label: string
  value: number
  sub: string
  tone?: 'neutral' | 'warning'
}) {
  return (
    <Card variant="baseline" padding="md" innerLift className="overflow-hidden">
      <CardEyebrow>{label}</CardEyebrow>
      <div className="flex items-baseline gap-2 mt-1">
        <span
          className="text-2xl font-semibold tactile-display-balance"
          style={{ color: tone === 'warning' ? 'oklch(0.78 0.16 85)' : undefined }}
        >
          {value}
        </span>
        <CardTitle className="text-xs text-text-tertiary uppercase tracking-wider mb-0">
          {value === 1 ? 'item' : 'items'}
        </CardTitle>
      </div>
      <CardDescription className="text-xs mt-1">{sub}</CardDescription>
    </Card>
  )
}
