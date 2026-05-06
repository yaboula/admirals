import { useState } from 'react'
import { Bell, Search, Volume2, VolumeX } from 'lucide-react'
import { Input, IconButton } from '@/components/ui'
import { StatusBadge } from './StatusBadge'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'

export interface TopbarProps {
  greeting?: string
  subtitle?: string
}

/**
 * Slim topbar (56px) for the zero-scroll dashboard. No ScrollContext
 * dependency — fixed glass intensity since the shell no longer scrolls.
 */
export function Topbar({ greeting = 'Buenos días', subtitle = 'SONAR Bank' }: TopbarProps) {
  const [muted, setMuted] = useState(sfx.getMuted())

  const toggleMute = (): void => {
    const next = !muted
    sfx.setMuted(next)
    setMuted(next)
    if (!next) sfx.signal_emerge()
  }

  return (
    <div
      className={cn(
        'flex items-center gap-3 px-5 lg:px-7 h-14',
        'border-b border-border-subtle',
      )}
      style={{
        background: 'oklch(0.04 0.005 270 / 0.6)',
        backdropFilter: 'blur(20px) saturate(180%)',
        WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      }}
    >
      <div className="flex flex-col leading-tight min-w-0 max-w-[180px]">
        <span className="text-[9px] uppercase tracking-[0.20em] text-text-tertiary font-medium truncate">
          {subtitle}
        </span>
        <span className="text-sm font-semibold text-text-primary tactile-wght-breathing truncate">
          {greeting}
        </span>
      </div>

      <div className="flex-1 flex justify-center max-w-md mx-auto w-full">
        <Input
          inputSize="sm"
          placeholder="Buscar transferencias, IBAN, beneficiario…"
          leftAdornment={<Search size={14} strokeWidth={2} />}
          aria-label="Buscar"
          fullWidth
        />
      </div>

      <div className="flex items-center gap-1.5">
        <StatusBadge />
        <IconButton
          icon={<Bell size={16} strokeWidth={1.9} />}
          aria-label="Notificaciones"
          variant="ghost"
          size="sm"
        />
        <IconButton
          icon={muted ? <VolumeX size={16} strokeWidth={1.9} /> : <Volume2 size={16} strokeWidth={1.9} />}
          aria-label={muted ? 'Activar sonido' : 'Silenciar sonido'}
          variant="ghost"
          size="sm"
          onClick={toggleMute}
        />
      </div>
    </div>
  )
}
