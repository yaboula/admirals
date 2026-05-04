/**
 * SONAR Tablet — Bank app (S2.4 real).
 *
 * 3 sub-vistas (Overview / History / Transfer) + tab bar lucide + header con
 * botón "← Volver" que dispatcha BACK_TO_HOME al router global (ESC reutiliza
 * handler S2.3 en App.tsx → RouterSwitch). Sub-router interno via useState
 * (NO Zustand/Redux per ADR-016 D5 stack frozen).
 *
 * Integra:
 *   - C001 `sonar:bank:getBalance` → `BankOverview` (DC-S2.4.1).
 *   - Bridge ad-hoc §2.2.3 `sonar:tablet:bank:getHistory` → `BankHistory` (DC-S2.4.2).
 *   - C002 `sonar:bank:transfer` → `BankTransfer` (DC-S2.4.3/4/5).
 *
 * Dark-only 3-color strict (ADR-016 D1+D3). Motion canonical reutiliza
 * `lib/motion.ts` eases (consistency S2.3 pattern) — GPU-only transform+opacity.
 *
 * Lazy-loaded chunk via `React.lazy()` en App.tsx (respeta D6 ≤500KB main gzip).
 */
import { useCallback, useEffect, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { ArrowLeft, ArrowRightLeft, History, Wallet } from 'lucide-react'
import { useTabletRouter } from '@/hooks/useTabletRouter'
import {
  viewSwitchAnimate,
  viewSwitchExit,
  viewSwitchInitial,
  viewSwitchTransition,
} from '@/lib/motion'
import BankOverview from './BankOverview'
import BankHistory from './BankHistory'
import BankTransfer from './BankTransfer'
import { getBalance } from './bankApi'
import type { BankBalance } from './types'

type BankView = 'overview' | 'history' | 'transfer'

interface TabDef {
  id: BankView
  label: string
  icon: typeof Wallet
}

const TABS: readonly TabDef[] = [
  { id: 'overview', label: 'Resumen', icon: Wallet },
  { id: 'history', label: 'Historial', icon: History },
  { id: 'transfer', label: 'Transferir', icon: ArrowRightLeft },
]

export default function BankApp() {
  const { dispatch } = useTabletRouter()
  const [view, setView] = useState<BankView>('overview')
  // Counter usado como useEffect dep para forzar refetch de balance tras
  // transfer exitosa o click "Refrescar" en overview.
  const [refreshKey, setRefreshKey] = useState(0)
  // Balance cached — alimenta BankTransfer.from_iban + saldo preview.
  const [balance, setBalance] = useState<BankBalance | null>(null)

  // Fetch balance propietario del shell (BankOverview también fetch, pero
  // shell-level cache sirve a BankTransfer sin double-request). Refetch en
  // refreshKey bump.
  useEffect(() => {
    let cancelled = false
    void (async () => {
      try {
        const b = await getBalance()
        if (!cancelled) setBalance(b)
      } catch {
        if (!cancelled) setBalance(null)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [refreshKey])

  const handleTransferSuccess = useCallback(() => {
    setRefreshKey((k) => k + 1)
    setView('overview')
  }, [])

  return (
    <div className="flex h-full flex-col bg-sonar-black">
      <header className="flex items-center justify-between border-b border-sonar-white/10 px-6 py-3">
        <div className="flex items-center gap-3">
          <h1 className="text-sm font-semibold tracking-tight text-sonar-white">Banca</h1>
          <span className="font-mono text-[10px] uppercase tracking-widest text-sonar-white/40">
            sonar · banca
          </span>
        </div>
        <button
          type="button"
          onClick={() => dispatch({ type: 'BACK_TO_HOME' })}
          className="inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-xs text-sonar-white/60 transition-colors duration-150 hover:text-sonar-orange focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40"
          aria-label="Volver al Bridge home"
        >
          <ArrowLeft className="h-3.5 w-3.5" strokeWidth={1.5} aria-hidden />
          <span>Volver</span>
        </button>
      </header>

      <nav
        role="tablist"
        aria-label="Secciones banca"
        className="flex gap-1 border-b border-sonar-white/10 px-4"
      >
        {TABS.map((t) => {
          const Icon = t.icon
          const active = view === t.id
          return (
            <button
              key={t.id}
              type="button"
              role="tab"
              aria-selected={active}
              aria-controls={`bank-panel-${t.id}`}
              onClick={() => setView(t.id)}
              className={
                'relative inline-flex items-center gap-2 px-3 py-2.5 text-xs transition-colors duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40 ' +
                (active
                  ? 'text-sonar-orange'
                  : 'text-sonar-white/60 hover:text-sonar-white')
              }
            >
              <Icon className="h-3.5 w-3.5" strokeWidth={1.5} aria-hidden />
              {t.label}
              {active ? (
                <span
                  aria-hidden
                  className="absolute inset-x-2 -bottom-px h-[2px] rounded-full bg-sonar-orange"
                />
              ) : null}
            </button>
          )
        })}
      </nav>

      <main className="flex-1 overflow-hidden">
        <AnimatePresence mode="wait" initial={false}>
          <motion.div
            key={view}
            id={`bank-panel-${view}`}
            role="tabpanel"
            className="h-full w-full"
            initial={viewSwitchInitial}
            animate={viewSwitchAnimate}
            exit={viewSwitchExit}
            transition={viewSwitchTransition}
          >
            {view === 'overview' ? (
              <BankOverview
                refreshKey={refreshKey}
                onGoHistory={() => setView('history')}
                onGoTransfer={() => setView('transfer')}
              />
            ) : null}
            {view === 'history' ? <BankHistory /> : null}
            {view === 'transfer' ? (
              <BankTransfer
                balance={balance}
                onSuccessBack={handleTransferSuccess}
              />
            ) : null}
          </motion.div>
        </AnimatePresence>
      </main>
    </div>
  )
}
