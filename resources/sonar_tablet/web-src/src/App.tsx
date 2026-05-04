import { Layers } from 'lucide-react'
import { Button } from '@/components/ui/button'

/**
 * SONAR Tablet — S2.1 scaffold baseline.
 *
 * Render mínimo verificador de identity v3:
 *   - Canvas dark-only (`bg-sonar-black`) + foreground (`text-sonar-white`).
 *   - Signal orange accent (`text-sonar-orange`) — único color brand.
 *   - Tokens via Tailwind v4 @theme (globals.css), NO hexes hardcoded.
 *   - Lucide icon canonical abstract (`<Layers>`) — NO submarine/sonar-ping legacy.
 *   - shadcn Button default variant → `bg-primary` bridged a `--color-sonar-orange`
 *     (R1 spike verify: shadcn semantic tokens mapean a sonar canonical).
 *
 * Shell real (router + keybind TAB + NUI bridge + Bridge home grid) arranca S2.2.
 */
function App() {
  return (
    <main className="relative flex min-h-screen flex-col items-center justify-center gap-6 bg-sonar-black px-6 text-sonar-white">
      <div className="flex items-center gap-3 text-sonar-orange">
        <Layers className="h-8 w-8" strokeWidth={1.5} aria-hidden />
        <span className="font-mono text-xs uppercase tracking-widest text-sonar-white/60">
          sonar · tablet · s2.1 baseline
        </span>
      </div>

      <h1 className="text-center text-4xl font-semibold tracking-tight text-sonar-white">
        Identity v3 — dark-only canvas
      </h1>

      <p className="max-w-md text-center text-sm text-sonar-white/60">
        Tokens canónicos activos:{' '}
        <code className="font-mono text-sonar-orange">--sonar-black</code> ·{' '}
        <code className="font-mono text-sonar-orange">--sonar-orange</code> ·{' '}
        <code className="font-mono text-sonar-orange">--sonar-white</code>.
      </p>

      <div className="mt-4 flex items-center gap-3">
        <Button size="lg">Signal active</Button>
        <Button size="lg" variant="outline">
          Secondary
        </Button>
      </div>

      <footer className="absolute bottom-6 font-mono text-[10px] uppercase tracking-widest text-sonar-white/30">
        strict typecheck · tailwind v4 · framer 11 · shadcn base-nova
      </footer>
    </main>
  )
}

export default App
