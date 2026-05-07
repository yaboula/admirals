import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { Bell, ChevronDown, Moon, RotateCcw, Search } from 'lucide-react'
import { IconButton } from '@/components/ui'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { useTransactionsFilter } from '@/stores/transactionsFilter'
import { toast } from '@/stores/toast'
import { BankAvatar } from '@/components/brand/BankAvatar'
import { StreamerModeToggle } from '@/components/security'

export interface TopbarProps {
  greeting?: string
  subtitle?: string
  /** Citizen / user identifier rendered in the profile chip. */
  userInitials?: string
  profileName?: string
  profileHandle?: string
}

/**
 * Slim topbar (56px) for the zero-scroll dashboard. No ScrollContext
 * dependency — fixed glass intensity since the shell no longer scrolls.
 */
export function Topbar({
  greeting = 'Buenos días',
  subtitle = 'SONAR Bank',
  userInitials,
  profileName,
  profileHandle,
}: TopbarProps) {
  const [query, setQuery] = useState('')
  const navigate = useNavigate()
  const setTransactionQuery = useTransactionsFilter((s) => s.setQuery)

  const submitSearch = (event: FormEvent<HTMLFormElement>): void => {
    event.preventDefault()
    const nextQuery = query.trim()
    if (!nextQuery) return
    setTransactionQuery(nextQuery)
    navigate('/transacciones')
    sfx.console_tap()
  }

  return (
    <div className="relative h-16 px-4 lg:px-6 flex items-center">
      <div
        aria-hidden
        className="absolute inset-x-4 top-0 h-16 rounded-b-[1.75rem] pointer-events-none"
        style={{
          background:
            'linear-gradient(180deg, oklch(0.10 0.018 45 / 0.56), oklch(0.055 0.010 35 / 0.18))',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.05)',
          backdropFilter: 'blur(18px) saturate(150%)',
          WebkitBackdropFilter: 'blur(18px) saturate(150%)',
        }}
      />

      <form onSubmit={submitSearch} className="relative z-10 w-[280px]">
        <div
          className="h-10 rounded-full flex items-center gap-2.5 px-3.5"
          style={{
            background: 'oklch(0.02 0.006 40 / 0.34)',
            border: '1px solid oklch(1 0 0 / 0.06)',
          }}
        >
          <Search size={15} strokeWidth={2} className="text-text-tertiary shrink-0" />
          <input
            type="search"
            placeholder="Search"
            aria-label="Buscar movimientos"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            className="w-full bg-transparent text-sm text-text-primary placeholder:text-text-tertiary outline-none"
          />
        </div>
      </form>

      <div className="absolute left-1/2 top-1/2 z-10 -translate-x-1/2 -translate-y-1/2">
        <div
          className="h-10 px-5 rounded-full inline-flex items-center justify-center text-xs font-semibold text-text-primary"
          style={{
            background: 'oklch(1 0 0 / 0.06)',
            border: '1px solid oklch(1 0 0 / 0.09)',
            boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.08)',
          }}
        >
          ⌘ + Space
        </div>
      </div>

      <div className="relative z-10 ml-auto flex items-center gap-2">
        <StreamerModeToggle />
        <IconButton
          icon={<RotateCcw size={16} strokeWidth={1.9} />}
          aria-label="Actualizar"
          variant="ghost"
          size="sm"
          onClick={() => toast.info('Vista actualizada', 'Tus datos están sincronizados.')}
        />
        <IconButton
          icon={<Bell size={16} strokeWidth={1.9} />}
          aria-label="Notificaciones"
          variant="ghost"
          size="sm"
          onClick={() => toast.info('Sin avisos pendientes', 'Tu cuenta está al día.')}
        />
        <IconButton
          icon={<Moon size={16} strokeWidth={1.9} />}
          aria-label="Cambiar tema"
          variant="ghost"
          size="sm"
          onClick={() => toast.info('Tema claro próximamente', 'Esta opción estará disponible en una próxima versión.')}
        />
        <ProfileChip
          initials={userInitials}
          name={profileName ?? greeting}
          handle={profileHandle ?? subtitle}
        />
      </div>
    </div>
  )
}

function ProfileChip({
  initials,
  name,
  handle,
}: {
  initials: string | undefined
  name: string
  handle: string
}) {
  return (
    <button
      type="button"
      aria-label="Perfil"
      className={cn(
        'tactile-focus-ring shrink-0 inline-flex items-center gap-2',
        'h-11 rounded-full pl-1.5 pr-2.5 ml-1',
        'border border-white/10 hover:border-white/18 transition-colors',
      )}
      style={{
        background: 'oklch(0.02 0.006 40 / 0.34)',
      }}
    >
      <BankAvatar name={initials ?? name} size="sm" />
      <span className="hidden xl:flex flex-col items-start leading-tight min-w-0 max-w-[130px]">
        <span className="text-xs font-semibold text-text-primary truncate max-w-full">{name}</span>
        <span className="text-[10px] text-text-tertiary truncate max-w-full">{handle}</span>
      </span>
      <ChevronDown size={13} strokeWidth={2} className="text-text-tertiary" />
    </button>
  )
}
