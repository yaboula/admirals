import { Eye, RadioTower, ShieldCheck } from 'lucide-react'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { usePrivacyMode } from '@/stores/privacy'
import { toast } from '@/stores/toast'

export function StreamerModeToggle() {
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const setStreamerMode = usePrivacyMode((s) => s.setStreamerMode)

  const handleToggle = (): void => {
    const next = !streamerMode
    setStreamerMode(next)
    sfx.console_tap()
    if (next) {
      toast.info('Streamer Mode activo', 'Tus datos sensibles vuelven a estar protegidos en pantalla.')
    } else {
      toast.warning('Datos revelados', 'Streamer Mode pausado. Vuelve a activarlo antes de compartir pantalla.')
    }
  }

  return (
    <button
      type="button"
      onClick={handleToggle}
      aria-pressed={streamerMode}
      aria-label={streamerMode ? 'Desactivar Streamer Mode y revelar datos' : 'Activar Streamer Mode y ocultar datos'}
      className={cn(
        'tactile-focus-ring inline-flex h-8 items-center gap-2 rounded-full px-3 text-[10px] font-semibold uppercase tracking-[0.14em] transition-all duration-180',
        streamerMode ? 'text-brand-signal-orange-light' : 'text-text-primary',
      )}
      style={{
        background: streamerMode
          ? 'linear-gradient(135deg, oklch(0.22 0.060 45 / 0.42), oklch(0.10 0.018 45 / 0.32))'
          : 'oklch(1 0 0 / 0.075)',
        border: streamerMode ? '1px solid oklch(0.72 0.22 40 / 0.32)' : '1px solid oklch(1 0 0 / 0.12)',
        boxShadow: streamerMode
          ? 'inset 0 1px 0 oklch(1 0 0 / 0.08), 0 0 18px -10px oklch(0.72 0.22 40)'
          : 'inset 0 1px 0 oklch(1 0 0 / 0.08)',
      }}
    >
      {streamerMode ? <RadioTower size={13} strokeWidth={2.2} /> : <Eye size={13} strokeWidth={2.2} />}
      <span className="hidden xl:inline">Streamer</span>
      <span
        className="inline-flex h-4 min-w-8 items-center justify-center rounded-full px-1.5 text-[9px] tracking-[0.12em]"
        style={{
          background: streamerMode ? 'oklch(0.72 0.22 40 / 0.14)' : 'oklch(1 0 0 / 0.08)',
          color: streamerMode ? 'oklch(0.82 0.18 45)' : 'oklch(0.86 0.006 270)',
        }}
      >
        {streamerMode ? 'ON' : 'OFF'}
      </span>
      {streamerMode ? <ShieldCheck size={12} strokeWidth={2.2} className="opacity-75" /> : null}
    </button>
  )
}
