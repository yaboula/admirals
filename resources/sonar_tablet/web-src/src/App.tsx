import { Layers } from 'lucide-react'
import { TabletFrame } from '@/components/shell/TabletFrame'
import { useTabletVisibility } from '@/hooks/useTabletVisibility'

/**
 * SONAR Tablet — S2.2 shell.
 *
 * Scope S2.2: frame container + visibility bridge (keybind F2 ↔ NUI).
 * Bridge home grid (12 apps) arranca S2.3. Bank app S2.4. Map app S2.5.
 *
 * Dev-mode (npm run dev fuera de FiveM): visible default false — sin keybind
 * Lua el shell permanece cerrado. Para UX testing browser ver prop drilling
 * temporal o expose `window.__sonar_debug_open__` en S2.7 polish.
 */
function App() {
  const { visible, requestClose } = useTabletVisibility()

  return (
    <TabletFrame visible={visible} onClose={requestClose}>
      <div className="flex h-full flex-col items-center justify-center gap-4 bg-sonar-black p-8">
        <Layers
          className="h-12 w-12 text-sonar-orange"
          strokeWidth={1.5}
          aria-hidden
        />
        <h1 className="text-3xl font-semibold tracking-tight text-sonar-white">
          SONAR Tablet
        </h1>
        <p className="font-mono text-xs uppercase tracking-widest text-sonar-white/60">
          s2.2 · shell · keybind f2 · nui bridge · framer motion 11
        </p>
        <p className="text-sm text-sonar-white/40">
          Press{' '}
          <kbd className="rounded border border-sonar-white/20 bg-sonar-white/5 px-2 py-0.5 font-mono text-xs text-sonar-white/80">
            ESC
          </kbd>{' '}
          to close
        </p>
      </div>
    </TabletFrame>
  )
}

export default App
