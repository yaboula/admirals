import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { Bell, Search, Volume2, VolumeX, User } from 'lucide-react'
import { Input, IconButton } from '@/components/ui'
import { StatusBadge } from './StatusBadge'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { useTransactionsFilter } from '@/stores/transactionsFilter'
import { toast } from '@/stores/toast'

export interface TopbarProps {
  greeting?: string
  subtitle?: string
  /** Citizen / user identifier rendered in the profile chip. */
  userInitials?: string
}

/**
 * Slim topbar (56px) for the zero-scroll dashboard. No ScrollContext
 * dependency — fixed glass intensity since the shell no longer scrolls.
 */
export function Topbar({
  greeting = 'Buenos días',
  subtitle = 'SONAR Bank',
  userInitials,
}: TopbarProps) {
  const [muted, setMuted] = useState(sfx.getMuted())
  const [query, setQuery] = useState('')
  const navigate = useNavigate()
  const setTransactionQuery = useTransactionsFilter((s) => s.setQuery)

  const toggleMute = (): void => {
    const next = !muted
    sfx.setMuted(next)
    setMuted(next)
    if (!next) sfx.signal_emerge()
  }

  const submitSearch = (event: FormEvent<HTMLFormElement>): void => {
    event.preventDefault()
    const nextQuery = query.trim()
    if (!nextQuery) return
    setTransactionQuery(nextQuery)
    navigate('/transacciones')
    sfx.console_tap()
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

      <form onSubmit={submitSearch} className="flex-1 flex justify-center max-w-md mx-auto w-full">
        <Input
          type="search"
          inputSize="sm"
          placeholder="Buscar movimientos, IBAN o beneficiario…"
          leftAdornment={<Search size={14} strokeWidth={2} />}
          aria-label="Buscar movimientos"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          fullWidth
        />
      </form>

      <div className="flex items-center gap-1.5">
        <StatusBadge />
        <IconButton
          icon={<Bell size={16} strokeWidth={1.9} />}
          aria-label="Notificaciones"
          variant="ghost"
          size="sm"
          onClick={() => toast.info('Sin avisos pendientes', 'Tu cuenta está al día.')}
        />
        <IconButton
          icon={muted ? <VolumeX size={16} strokeWidth={1.9} /> : <Volume2 size={16} strokeWidth={1.9} />}
          aria-label={muted ? 'Activar sonido' : 'Silenciar sonido'}
          variant="ghost"
          size="sm"
          onClick={toggleMute}
        />
        <ProfileAvatar initials={userInitials} />
      </div>
    </div>
  )
}

function ProfileAvatar({ initials }: { initials: string | undefined }) {
  return (
    <button
      type="button"
      aria-label="Perfil"
      className={cn(
        'tactile-focus-ring shrink-0 inline-flex items-center justify-center',
        'h-8 w-8 rounded-full ml-1',
        'border border-border-medium hover:border-border-strong transition-colors',
      )}
      style={{
        background:
          'linear-gradient(135deg, oklch(0.16 0.012 270), oklch(0.10 0.010 270))',
      }}
    >
      {initials ? (
        <span
          className="text-[10px] font-semibold text-text-primary tactile-wght-breathing"
          style={{ letterSpacing: '0.02em' }}
        >
          {initials.slice(0, 2).toUpperCase()}
        </span>
      ) : (
        <User size={14} strokeWidth={1.9} className="text-text-secondary" />
      )}
    </button>
  )
}
