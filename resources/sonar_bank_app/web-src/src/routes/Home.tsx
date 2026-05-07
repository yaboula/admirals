import { useEffect } from 'react'
import { motion } from 'motion/react'
import { useBootstrap } from '@/data/queries'
import { HomeBalanceGraph } from './home/HomeBalanceGraph'
import { HomePromoCarousel } from './home/HomePromoCarousel'
import { HomeMoneyActions } from './home/HomeMoneyActions'
import { HomeCardsRail } from './home/HomeCardsRail'
import { handleBankError } from '@/lib/bankError'

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
      handleBankError(error)
    }
  }, [isError, error])

  const primaryAccount = data?.accounts[0]
  const transactions = data?.recent_transactions ?? []
  const cards = data?.cards ?? []

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
      className="h-full w-full"
    >
      <div
        className="h-full w-full mx-auto max-w-[1500px] gap-4 2xl:gap-5"
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1fr) minmax(300px, 0.46fr)',
          gridTemplateRows: '1fr',
        }}
      >
        <section
          className="h-full min-h-0 gap-4 2xl:gap-5"
          style={{
            display: 'grid',
            gridTemplateRows: 'minmax(0, 1fr) minmax(190px, 0.52fr)',
          }}
        >
          <HomeBalanceGraph account={primaryAccount} transactions={transactions} />
          <div
            className="min-h-0 gap-4 2xl:gap-5"
            style={{
              display: 'grid',
              gridTemplateColumns: 'minmax(0, 1.2fr) minmax(220px, 0.8fr)',
            }}
          >
            <HomePromoCarousel />
            <HomeMoneyActions />
          </div>
        </section>

        <aside className="h-full min-h-0">
          <HomeCardsRail account={primaryAccount} cards={cards} transactions={transactions} />
        </aside>
      </div>
    </motion.div>
  )
}
