/**
 * SONAR Tablet — Bank app stub (S2.3).
 *
 * Placeholder hasta S2.4 donde se implementa balance + historial + transfer
 * con integración callbacks C001 (`sonar:bank:getBalance`) + C002
 * (`sonar:bank:transfer`). Ver SPRINT_PLAN_S2 §2.2.2 + DC5/DC6.
 *
 * Lazy-loaded chunk via React.lazy en App.tsx — respeta D6 budget (main
 * ≤500KB gzip). Stub ligero (<1KB) no impacta budget.
 */
import { ArrowLeft } from 'lucide-react'
import { useTabletRouter } from '@/hooks/useTabletRouter'

export default function BankApp() {
  const { dispatch } = useTabletRouter()

  return (
    <div className="flex h-full flex-col bg-sonar-black">
      <header className="flex items-center gap-3 border-b border-sonar-white/10 px-6 py-4">
        <button
          type="button"
          onClick={() => dispatch({ type: 'BACK_TO_HOME' })}
          className="inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-sm text-sonar-white/60 transition-colors duration-150 hover:text-sonar-orange focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sonar-orange/40"
          aria-label="Volver al Bridge home"
        >
          <ArrowLeft className="h-4 w-4" strokeWidth={1.5} aria-hidden />
          <span>Volver</span>
        </button>
        <span className="font-mono text-[11px] uppercase tracking-widest text-sonar-white/40">
          sonar · banca
        </span>
      </header>

      <main className="flex flex-1 flex-col items-center justify-center gap-3 px-8">
        <h1 className="text-3xl font-semibold tracking-tight text-sonar-white">
          Banca
        </h1>
        <p className="text-sm text-sonar-white/60">Coming S2.4</p>
        <p className="max-w-md text-center text-xs text-sonar-white/40">
          Balance · Historial · Transfer
        </p>
      </main>
    </div>
  )
}
