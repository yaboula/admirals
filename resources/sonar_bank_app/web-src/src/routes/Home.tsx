import { useEffect } from 'react'
import { motion } from 'motion/react'
import { useBootstrap } from '@/data/queries'
import { getMockDisplayName } from '@/data/mock/seed'
import { HeroBalanceCard } from './home/HeroBalanceCard'
import { CreditCardVisual } from './home/CreditCardVisual'
import { ActionStack } from './home/ActionStack'
import { CompactQuickTransfer } from './home/CompactQuickTransfer'
import { ActivityPreview } from './home/ActivityPreview'
import { Card } from '@/components/ui'
import { IncomeExpenseChart } from '@/components/charts/IncomeExpenseChart'
import { toast } from '@/stores/toast'

/**
 * BANK-FE.2.3 Dashboard — zero-scroll, 2-column main grid (the third column
 * is the AppShell sidebar). Optimised for 1280×800 / 1024×768 in-game tablet.
 *
 *   ┌──────────────── main col 1 (data) ─────────┬─ main col 2 (action) ─┐
 *   │ HeroBalanceCard           (≈210 px)            │ CreditCardVisual      │
 *   │ ─────────────────────────────────────────────  │  + orange halo V1      │
 *   │ IncomeExpenseChart (1fr)  THE CHART IS KING    │ ───────────────────── │
 *   │   AreaChart luminous stroke + gradient fall   │ ActionStack (NFS)     │
 *   │ ───────────────────────────────────────────────  │ Transferir · Depositar│
 *   │ ActivityPreview · 4 rows · Ver todo →         │ Retirar (vertical)    │
 *   │                                                │ ───────────────────── │
 *   │                                                │ CompactQuickTransfer  │
 *   │                                                │  (1fr fills remainder)│
 *   └─────────────────────────────────────────────────┘───────────────────────┘
 */
export function Home() {
  const { data, isError, error } = useBootstrap()

  useEffect(() => {
    if (isError && error) {
      toast.danger('Bootstrap falló', error.message ?? error.code)
    }
  }, [isError, error])

  const primaryAccount = data?.accounts[0]
  const transactions = data?.recent_transactions ?? []
  // Phase A mock: display name comes from seed; H3+ session.displayName.
  const holderDisplayName = data ? getMockDisplayName().toUpperCase() : 'CITIZEN'

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
      className="h-full w-full"
    >
      <div
        className="h-full w-full mx-auto max-w-[1500px] gap-4 lg:gap-5"
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1.7fr) minmax(280px, 0.85fr)',
          gridTemplateRows: '1fr',
        }}
      >
        {/* ── DATA COLUMN ─────────────────────────────────────────────── */}
        <section
          className="h-full min-h-0 gap-4"
          style={{
            display: 'grid',
            gridTemplateRows: 'auto 1fr auto',
          }}
        >
          <div className="tactile-halo-orange tactile-halo-orange--soft">
            <HeroBalanceCard
              account={primaryAccount}
              transactions={transactions}
            />
          </div>

          <Card variant="glass" padding="md" className="min-h-0 flex border-white/10">
            <IncomeExpenseChart
              transactions={transactions}
              ownIban={primaryAccount?.iban}
              windowDays={30}
              className="h-full"
            />
          </Card>

          <ActivityPreview
            transactions={transactions}
            account={primaryAccount}
            compact
          />
        </section>

        {/* ── ACTION COLUMN ────────────────────────────── */}
        <aside
          className="h-full min-h-0 gap-4"
          style={{
            display: 'grid',
            gridTemplateRows: 'auto auto 1fr',
          }}
        >
          <div className="tactile-halo-orange">
            <CreditCardVisual
              account={primaryAccount}
              holderName={holderDisplayName}
            />
          </div>
          <ActionStack />
          <CompactQuickTransfer />
        </aside>
      </div>
    </motion.div>
  )
}
