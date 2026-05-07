import { NavLink } from 'react-router-dom'
import { motion } from 'motion/react'
import {
  LayoutDashboard,
  Landmark,
  ArrowLeftRight,
  CreditCard,
  RefreshCw,
  Settings,
  Receipt,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { useAceGate } from '@/components/security'
import { ACE_PERMS } from '@/lib/ace'
import type { AcePerm } from '@/stores/session'
import sonarMonogramUrl from '@/assets/branding/monogram_s.svg'

interface NavItem {
  to: string
  label: string
  icon: typeof LayoutDashboard
  end?: boolean
  disabled?: boolean
  badge?: string
  requiredPerm?: AcePerm
}

const NAV_ITEMS: NavItem[] = [
  { to: '/', label: 'Inicio', icon: LayoutDashboard, end: true, requiredPerm: ACE_PERMS.P01.perm },
  { to: '/cuentas', label: 'Cuentas', icon: Landmark, requiredPerm: ACE_PERMS.P01.perm },
  { to: '/transacciones', label: 'Transacciones', icon: Receipt, requiredPerm: ACE_PERMS.P01.perm },
  { to: '/transferir', label: 'Transferir', icon: ArrowLeftRight, requiredPerm: ACE_PERMS.P01.perm },
  { to: '/recurrentes', label: 'Recurrentes', icon: RefreshCw, requiredPerm: ACE_PERMS.P01.perm },
  { to: '/tarjetas', label: 'Tarjetas', icon: CreditCard, requiredPerm: ACE_PERMS.P01.perm },
]

const FOOTER_ITEMS: NavItem[] = [
  { to: '/ajustes', label: 'Ajustes', icon: Settings, requiredPerm: ACE_PERMS.P01.perm },
]

export interface SidebarProps {
  defaultCollapsed?: boolean
}

/**
 * BANK-FE.3.5 — Auto-collapse below 1280px (target tablet 1280×800 / 1024×768).
 * Manual toggle wins: once the user clicks the chevron, we stop syncing with
 * the media query so we don't bounce their preference back.
 */
export function Sidebar({ defaultCollapsed: _defaultCollapsed }: SidebarProps) {
  return (
    <motion.aside
      initial={false}
      animate={{ width: 88 }}
      transition={{ type: 'spring', stiffness: 260, damping: 30 }}
      className={cn(
        'relative h-full flex-shrink-0 p-3',
        'flex flex-col items-center',
        'z-[var(--z-sidebar)]',
      )}
    >
      <div
        className="h-full w-full rounded-[2rem] flex flex-col items-center overflow-hidden"
        style={{
          background: 'linear-gradient(180deg, oklch(0.08 0.018 45 / 0.86), oklch(0.045 0.010 40 / 0.78))',
          border: '1px solid oklch(1 0 0 / 0.07)',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.06), 0 28px 64px -44px oklch(0 0 0 / 0.95)',
          backdropFilter: 'blur(24px) saturate(150%)',
          WebkitBackdropFilter: 'blur(24px) saturate(150%)',
        }}
      >
      <div className="flex items-center justify-center pt-5 pb-4">
        <div className="relative flex h-10 w-10 items-center justify-center" aria-hidden>
          <img
            src={sonarMonogramUrl}
            alt=""
            className="h-[46px] w-[46px] max-w-none object-contain"
            style={{ filter: 'drop-shadow(0 0 14px oklch(0.72 0.22 40 / 0.66))' }}
          />
        </div>
      </div>

      <div
        aria-hidden
        className="w-8 h-px"
        style={{ background: 'oklch(1 0 0 / 0.08)' }}
      />

      <nav className="flex-1 py-4 flex flex-col items-center gap-2.5">
        {NAV_ITEMS.map((item) => (
          <SidebarItem key={item.to} item={item} />
        ))}
      </nav>

      <div className="pb-5 flex flex-col items-center gap-2.5">
        {FOOTER_ITEMS.map((item) => (
          <SidebarItem key={item.to} item={item} />
        ))}
      </div>
      </div>
    </motion.aside>
  )
}

/**
 * Sidebar nav item — premium 3-state contrast hierarchy:
 *   default → text 45% gray, no bg
 *   hover   → text 70% gray, bg 5% white
 *   active  → text 100% white, bg 6% white, 3px left orange rail indicator
 *
 * Icons: unified outline style (lucide-react), strokeWidth 1.7 across all states.
 */
function SidebarItem({ item }: { item: NavItem }) {
  const Icon = item.icon
  const granted = useAceGate({ require: item.requiredPerm })
  if (item.disabled || !granted) {
    return (
      <div
        className={cn(
          'group relative flex h-11 w-11 items-center justify-center rounded-2xl',
          'cursor-not-allowed opacity-50 select-none',
        )}
        title={item.disabled ? `${item.label} (próximamente)` : `${item.label} (permiso requerido)`}
        style={{ color: 'oklch(0.55 0.01 270 / 0.6)' }}
      >
        <Icon size={18} strokeWidth={1.8} className="shrink-0" />
      </div>
    )
  }
  return (
    <NavLink
      to={item.to}
      end={item.end}
      onClick={() => sfx.console_tap()}
      className={({ isActive }) =>
        cn(
          'group relative flex h-11 w-11 items-center justify-center rounded-2xl',
          'transition-[background-color,color,box-shadow,transform] duration-180',
          isActive && 'sidebar-item--active',
        )
      }
    >
      {({ isActive }) => (
        <>
          {isActive && <span aria-hidden className="absolute inset-0 rounded-2xl tactile-conic-edge pointer-events-none" />}
          <Icon
            size={18}
            strokeWidth={1.8}
            className="shrink-0"
            style={{ color: 'currentColor' }}
          />
        </>
      )}
    </NavLink>
  )
}
