import { useEffect, useState } from 'react'
import { NavLink } from 'react-router-dom'
import { motion } from 'motion/react'
import {
  LayoutDashboard,
  ArrowLeftRight,
  CreditCard,
  PiggyBank,
  TrendingUp,
  ShieldCheck,
  Settings,
  ChevronLeft,
  ChevronRight,
  Sparkles,
  Receipt,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'

interface NavItem {
  to: string
  label: string
  icon: typeof LayoutDashboard
  end?: boolean
  disabled?: boolean
  badge?: string
}

const NAV_ITEMS: NavItem[] = [
  { to: '/', label: 'Inicio', icon: LayoutDashboard, end: true },
  { to: '/transacciones', label: 'Transacciones', icon: Receipt },
  { to: '/transferir', label: 'Transferir', icon: ArrowLeftRight },
  { to: '/tarjetas', label: 'Tarjetas', icon: CreditCard },
  { to: '/ahorro', label: 'Ahorro', icon: PiggyBank, disabled: true },
  { to: '/portfolio', label: 'Portfolio', icon: TrendingUp, disabled: true },
  { to: '/compliance', label: 'Compliance', icon: ShieldCheck, disabled: true, badge: 'admin' },
]

const FOOTER_ITEMS: NavItem[] = [
  { to: '/dev/showcase', label: 'Dev Showcase', icon: Sparkles },
  { to: '/ajustes', label: 'Ajustes', icon: Settings, disabled: true },
]

export interface SidebarProps {
  defaultCollapsed?: boolean
}

/**
 * BANK-FE.3.5 — Auto-collapse below 1280px (target tablet 1280×800 / 1024×768).
 * Manual toggle wins: once the user clicks the chevron, we stop syncing with
 * the media query so we don't bounce their preference back.
 */
const COLLAPSE_BREAKPOINT = 1280

export function Sidebar({ defaultCollapsed }: SidebarProps) {
  const [collapsed, setCollapsed] = useState<boolean>(() => {
    if (typeof defaultCollapsed === 'boolean') return defaultCollapsed
    if (typeof window === 'undefined') return false
    return window.innerWidth < COLLAPSE_BREAKPOINT
  })
  const [userOverride, setUserOverride] = useState(false)

  useEffect(() => {
    if (userOverride) return
    if (typeof window === 'undefined') return
    const mq = window.matchMedia(`(max-width: ${COLLAPSE_BREAKPOINT - 1}px)`)
    const apply = () => setCollapsed(mq.matches)
    apply()
    mq.addEventListener('change', apply)
    return () => mq.removeEventListener('change', apply)
  }, [userOverride])

  return (
    <motion.aside
      initial={false}
      animate={{ width: collapsed ? 76 : 248 }}
      transition={{ type: 'spring', stiffness: 260, damping: 30 }}
      className={cn(
        'relative h-full flex-shrink-0',
        'flex flex-col',
        'border-r border-border-subtle',
        'bg-surface-void/60',
        'backdrop-blur-md',
        'z-[var(--z-sidebar)]',
      )}
    >
      {/* Brand */}
      <div className={cn('flex items-center gap-3 px-5 py-6', collapsed && 'justify-center px-0')}>
        <div
          className="relative flex h-9 w-9 items-center justify-center rounded-xl"
          style={{
            background: 'var(--gradient-primary)',
            boxShadow: 'var(--shadow-tactile-button-primary)',
          }}
          aria-hidden
        >
          <span className="absolute inset-0 rounded-xl tactile-conic-edge pointer-events-none" />
          <span className="font-bold text-text-primary tracking-tight text-lg">S</span>
        </div>
        {!collapsed && (
          <motion.div
            initial={{ opacity: 0, x: -8 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.08 }}
            className="flex flex-col"
          >
            <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">SONAR</span>
            <span className="text-base font-semibold tracking-tight text-text-primary">Bank</span>
          </motion.div>
        )}
      </div>

      <div
        aria-hidden
        className="mx-3 h-px"
        style={{ background: 'oklch(1 0 0 / 0.04)' }}
      />

      {/* Nav primary */}
      <nav className="flex-1 overflow-y-auto px-3 py-4 flex flex-col gap-0.5">
        {NAV_ITEMS.map((item) => (
          <SidebarItem key={item.to} item={item} collapsed={collapsed} />
        ))}
      </nav>

      {/* Subtle separator before Dev Showcase footer block */}
      <div
        aria-hidden
        className="mx-4 h-px"
        style={{
          background:
            'linear-gradient(90deg, transparent 0%, oklch(1 0 0 / 0.06) 50%, transparent 100%)',
        }}
      />

      <div className="px-3 py-3 flex flex-col gap-0.5">
        {FOOTER_ITEMS.map((item) => (
          <SidebarItem key={item.to} item={item} collapsed={collapsed} />
        ))}
      </div>

      {/* Collapse toggle */}
      <button
        type="button"
        aria-label={collapsed ? 'Expandir sidebar' : 'Contraer sidebar'}
        onClick={() => {
          setCollapsed((c) => !c)
          setUserOverride(true)
          sfx.layer_dive()
        }}
        className={cn(
          'absolute top-7 -right-3 z-10 inline-flex items-center justify-center',
          'h-6 w-6 rounded-full',
          'border border-border-medium bg-surface-card-elevated text-text-tertiary',
          'hover:text-text-primary hover:border-border-strong transition-colors',
        )}
        style={{ boxShadow: 'var(--shadow-tactile-button-secondary)' }}
      >
        {collapsed ? <ChevronRight size={14} /> : <ChevronLeft size={14} />}
      </button>
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
function SidebarItem({ item, collapsed }: { item: NavItem; collapsed: boolean }) {
  const Icon = item.icon
  if (item.disabled) {
    return (
      <div
        className={cn(
          'group relative flex items-center gap-3 rounded-md px-3 py-2',
          'cursor-not-allowed opacity-50 select-none',
          collapsed && 'justify-center px-0',
        )}
        title={`${item.label} (próximamente)`}
        style={{ color: 'oklch(0.55 0.01 270 / 0.6)' }}
      >
        <Icon size={17} strokeWidth={1.7} className="shrink-0" />
        {!collapsed && (
          <span className="text-sm font-medium flex-1 truncate">{item.label}</span>
        )}
        {!collapsed && item.badge && (
          <span className="text-[9px] uppercase tracking-wider text-text-tertiary border border-border-subtle rounded px-1 py-0.5">
            {item.badge}
          </span>
        )}
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
          'sidebar-item group relative flex items-center gap-3 rounded-md px-3 py-2',
          'transition-[background-color,color] duration-180',
          collapsed && 'justify-center px-0',
          isActive && 'sidebar-item--active',
        )
      }
    >
      {({ isActive }) => (
        <>
          {isActive && !collapsed && (
            <span
              aria-hidden
              className="absolute left-0 top-1.5 bottom-1.5 w-[3px] rounded-r-full"
              style={{ background: 'var(--gradient-primary)' }}
            />
          )}
          <Icon
            size={17}
            strokeWidth={1.7}
            className="shrink-0"
            style={{ color: 'currentColor' }}
          />
          {!collapsed && (
            <span className="text-sm font-medium flex-1 truncate tactile-wght-breathing">
              {item.label}
            </span>
          )}
          {!collapsed && item.badge && (
            <span
              className="text-[9px] uppercase tracking-wider rounded px-1 py-0.5"
              style={{
                color: isActive
                  ? 'var(--color-brand-signal-orange-light)'
                  : 'oklch(0.55 0.012 270)',
                border: `1px solid ${
                  isActive
                    ? 'var(--color-border-brand-subtle)'
                    : 'var(--color-border-subtle)'
                }`,
              }}
            >
              {item.badge}
            </span>
          )}
        </>
      )}
    </NavLink>
  )
}
