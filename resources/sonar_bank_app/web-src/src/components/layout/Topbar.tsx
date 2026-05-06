import { useEffect, useRef } from 'react'
import { Bell, Search, Volume2, VolumeX } from 'lucide-react'
import { Input, IconButton } from '@/components/ui'
import { StatusBadge } from './StatusBadge'
import { useScrollProgress } from '@/components/vanguard/ScrollContext'
import { sfx } from '@/lib/sfx'
import { useState } from 'react'
import { cn } from '@/lib/utils'

export interface TopbarProps {
  greeting?: string
  subtitle?: string
}

export function Topbar({ greeting = 'Buenos días', subtitle = 'SONAR Bank' }: TopbarProps) {
  const progress = useScrollProgress()
  const ref = useRef<HTMLDivElement | null>(null)
  const [muted, setMuted] = useState(sfx.getMuted())

  useEffect(() => {
    if (!ref.current) return
    ref.current.style.setProperty('--tactile-scroll-progress', String(progress))
  }, [progress])

  const toggleMute = (): void => {
    const next = !muted
    sfx.setMuted(next)
    setMuted(next)
    if (!next) sfx.signal_emerge()
  }

  return (
    <div
      ref={ref}
      className={cn(
        'tactile-scroll-topbar',
        'sticky top-0 z-[var(--z-header)]',
        'flex items-center gap-4 px-6 lg:px-10 h-16',
      )}
    >
      <div className="flex flex-col leading-tight min-w-0">
        <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">{subtitle}</span>
        <span className="text-sm font-semibold text-text-primary tactile-wght-breathing truncate">{greeting}</span>
      </div>

      <div className="flex-1 flex justify-center max-w-xl mx-auto w-full">
        <Input
          inputSize="md"
          placeholder="Buscar transferencias, IBAN, beneficiario…"
          leftAdornment={<Search size={16} strokeWidth={2} />}
          aria-label="Buscar"
          fullWidth
        />
      </div>

      <div className="flex items-center gap-2">
        <StatusBadge />
        <IconButton
          icon={<Bell size={18} strokeWidth={1.9} />}
          aria-label="Notificaciones"
          variant="ghost"
          size="md"
        />
        <IconButton
          icon={muted ? <VolumeX size={18} strokeWidth={1.9} /> : <Volume2 size={18} strokeWidth={1.9} />}
          aria-label={muted ? 'Activar sonido' : 'Silenciar sonido'}
          variant="ghost"
          size="md"
          onClick={toggleMute}
        />
      </div>
    </div>
  )
}
