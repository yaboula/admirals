import { useState } from 'react'
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
  { to: '/transferir', label: 'Transferir', icon: ArrowLeftRight, disabled: true },
  { to: '/tarjetas', label: 'Tarjetas', icon: CreditCard, disabled: true },
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

export function Sidebar({ defaultCollapsed = false }: SidebarProps) {
  const [collapsed, setCollapsed] = useState(defaultCollapsed)

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

      <div className="tactile-divider-shimmer mx-3" />

      {/* Nav primary */}
      <nav className="flex-1 overflow-y-auto px-3 py-4 flex flex-col gap-1">
        {NAV_ITEMS.map((item) => (
          <SidebarItem key={item.to} item={item} collapsed={collapsed} />
        ))}
      </nav>

      <div className="tactile-divider-shimmer mx-3" />

      <div className="px-3 py-3 flex flex-col gap-1">
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

function SidebarItem({ item, collapsed }: { item: NavItem; collapsed: boolean }) {
  const Icon = item.icon
  if (item.disabled) {
    return (
      <div
        className={cn(
          'group relative flex items-center gap-3 rounded-lg px-3 py-2.5',
          'text-text-quaternary cursor-not-allowed opacity-60 select-none',
          collapsed && 'justify-center px-0',
        )}
        title={`${item.label} (próximamente)`}
      >
        <Icon size={18} strokeWidth={1.8} />
        {!collapsed && (
          <span className="text-sm font-medium tactile-wght-breathing flex-1">{item.label}</span>
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
          'group relative flex items-center gap-3 rounded-lg px-3 py-2.5',
          'text-text-secondary hover:text-text-primary',
          'transition-colors duration-200',
          collapsed && 'justify-center px-0',
          isActive && 'tactile-rail-active text-text-primary bg-surface-card/60',
        )
      }
    >
      <Icon size={18} strokeWidth={1.9} className="shrink-0" />
      {!collapsed && (
        <span className="text-sm font-medium tactile-wght-breathing flex-1">{item.label}</span>
      )}
      {!collapsed && item.badge && (
        <span className="text-[9px] uppercase tracking-wider text-brand-signal-orange-light border border-border-brand-subtle rounded px-1 py-0.5">
          {item.badge}
        </span>
      )}
    </NavLink>
  )
}
