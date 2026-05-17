import { useState } from 'react'
import { Outlet, useNavigate, useLocation } from 'react-router-dom'
import { motion, AnimatePresence } from 'motion/react'
import {
  LayoutDashboard,
  CreditCard,
  ShieldAlert,
  Building2,
  FileSearch,
  ChevronRight,
  X,
  Bell,
  Settings,
  LogOut,
  type LucideIcon
} from 'lucide-react'
import { Button } from '@/components/ui'
import { cn } from '@/lib/utils'

interface AdminModule {
  id: string
  icon: LucideIcon
  label: string
  description: string
  badge?: number
  path: string
}

const ADMIN_MODULES: AdminModule[] = [
  {
    id: 'loans',
    icon: CreditCard,
    label: 'Loan Approvals',
    description: 'Review and decide loan applications',
    path: '/sonaradmin/loans',
  },
  {
    id: 'compliance',
    icon: ShieldAlert,
    label: 'Compliance Flags',
    description: 'Resolve security and compliance alerts',
    path: '/sonaradmin/compliance',
  },
  {
    id: 'accounts',
    icon: Building2,
    label: 'Professional Accounts',
    description: 'Review professional account requests',
    path: '/sonaradmin/accounts',
  },  {
    id: 'business',
    icon: Building2,
    label: 'Business Approvals',
    description: 'Approve payroll, withdrawals, and transfers',
    path: '/sonaradmin/business',
  },
  {
    id: 'audit',
    icon: FileSearch,
    label: 'Audit Oversight',
    description: 'Monitor ledger and transaction trails',
    path: '/sonaradmin/audit',
  },
]

export function AdminShell() {
  const navigate = useNavigate()
  const location = useLocation()
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false)

  const selectedModule = ADMIN_MODULES.find((m) => location.pathname === m.path)?.id || 'loans'
  const currentModule = ADMIN_MODULES.find((m) => m.id === selectedModule)

  return (
    <div className="flex h-full min-h-0 bg-surface-abyss">
      {/* Sidebar */}
      <motion.aside
        initial={false}
        animate={{ width: sidebarCollapsed ? 72 : 320 }}
        transition={{ duration: 0.3, ease: [0.4, 0, 0.2, 1] }}
        className="relative flex flex-col border-r border-white/10 bg-[linear-gradient(180deg,rgba(2,2,5,0.98),rgba(0,0,0,0.96))]"
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-white/10 px-5 py-4">
          <AnimatePresence mode="wait">
            {!sidebarCollapsed && (
              <motion.div
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -10 }}
                transition={{ duration: 0.2 }}
              >
                <div className="flex items-center gap-2">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full border border-white/15 bg-[radial-gradient(circle_at_50%_0%,rgba(246,75,0,0.22),transparent_70%)]">
                    <LayoutDashboard size={16} strokeWidth={2} className="text-[rgb(246,75,0)]" />
                  </div>
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-[0.18em] text-text-secondary">SONAR</p>
                    <p className="text-sm font-semibold text-text-primary">Bank Admin</p>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
          <Button
            size="sm"
            variant="ghost"
            leftIcon={sidebarCollapsed ? <ChevronRight size={14} /> : <X size={14} />}
            onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
            className="shrink-0"
          />
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto p-3 scrollbar-thin">
          <div className="space-y-1">
            {ADMIN_MODULES.map((module) => (
              <AdminNavCard
                key={module.id}
                module={module}
                selected={selectedModule === module.id}
                collapsed={sidebarCollapsed}
                onSelect={() => navigate(module.path)}
              />
            ))}
          </div>
        </nav>

        {/* Footer */}
        <div className="border-t border-white/10 px-3 py-4">
          <div className="space-y-1">
            <AdminNavAction
              icon={Bell}
              label="Notifications"
              collapsed={sidebarCollapsed}
              badge={3}
            />
            <AdminNavAction
              icon={Settings}
              label="Settings"
              collapsed={sidebarCollapsed}
            />
            <AdminNavAction
              icon={LogOut}
              label="Exit Admin"
              collapsed={sidebarCollapsed}
              tone="danger"
            />
          </div>
        </div>
      </motion.aside>

      {/* Main Content */}
      <main className="flex-1 min-h-0 overflow-hidden">
        {/* Module Header */}
        <div className="border-b border-white/10 bg-black/40 px-6 py-5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.035]">
                {currentModule && <currentModule.icon size={22} strokeWidth={1.8} className="text-text-secondary" />}
              </div>
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-text-tertiary">
                  {currentModule?.label}
                </p>
                <p className="text-sm text-text-secondary">{currentModule?.description}</p>
              </div>
            </div>
            {currentModule?.badge && currentModule.badge > 0 && (
              <div className="flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.035] px-4 py-2">
                <div className="h-2 w-2 rounded-full bg-[rgb(246,75,0)]" />
                <span className="text-sm font-semibold text-text-primary">{currentModule.badge} pending</span>
              </div>
            )}
          </div>
        </div>

        {/* Module Content */}
        <div className="h-full overflow-y-auto scrollbar-thin">
          <Outlet />
        </div>
      </main>
    </div>
  )
}

function AdminNavCard({ 
  module, 
  selected, 
  collapsed, 
  onSelect 
}: { 
  module: AdminModule
  selected: boolean
  collapsed: boolean
  onSelect: () => void 
}) {
  const Icon = module.icon
  return (
    <motion.button
      onClick={onSelect}
      className={cn(
        'relative w-full overflow-hidden rounded-2xl border p-3 text-left transition-all',
        selected
          ? 'border-white/18 bg-[radial-gradient(circle_at_0%_0%,rgba(246,75,0,0.12),transparent_60%),rgba(255,255,255,0.055)]'
          : 'border-white/10 bg-white/[0.02] hover:bg-white/[0.045]'
      )}
      whileHover={{ scale: 1.01 }}
      whileTap={{ scale: 0.99 }}
    >
      {selected && (
        <motion.div
          layoutId="active-border"
          className="absolute left-0 top-0 h-full w-1 bg-[rgb(246,75,0)]"
          initial={false}
          transition={{ type: 'spring', stiffness: 300, damping: 30 }}
        />
      )}
      <div className="flex items-center gap-3">
        <div className="flex shrink-0 h-10 w-10 items-center justify-center rounded-xl border border-white/10 bg-white/[0.035]">
          <Icon size={18} strokeWidth={1.9} className={cn('transition-colors', selected ? 'text-[rgb(246,75,0)]' : 'text-text-secondary')} />
        </div>
        <AnimatePresence mode="wait">
          {!collapsed && (
            <motion.div
              initial={{ opacity: 0, x: -8 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -8 }}
              transition={{ duration: 0.2 }}
              className="flex-1 min-w-0"
            >
              <p className="text-sm font-semibold text-text-primary">{module.label}</p>
              <p className="mt-0.5 truncate text-xs text-text-tertiary">{module.description}</p>
            </motion.div>
          )}
        </AnimatePresence>
        {module.badge && module.badge > 0 && (
          <div className="flex shrink-0 h-6 min-w-[24px] items-center justify-center rounded-full border border-white/10 bg-[rgb(246,75,0)] px-2">
            <span className="text-xs font-semibold text-white">{module.badge}</span>
          </div>
        )}
      </div>
    </motion.button>
  )
}

function AdminNavAction({ 
  icon: Icon, 
  label, 
  collapsed, 
  badge,
  tone = 'neutral'
}: { 
  icon: LucideIcon
  label: string
  collapsed: boolean
  badge?: number
  tone?: 'neutral' | 'danger'
}) {
  return (
    <button className={cn(
      'flex w-full items-center gap-3 rounded-xl border px-3 py-2.5 text-left transition-colors',
      tone === 'danger' ? 'border-red-500/20 hover:bg-red-500/10' : 'border-white/10 hover:bg-white/[0.045]'
    )}>
      <div className="flex shrink-0 h-8 w-8 items-center justify-center rounded-lg border border-white/10 bg-white/[0.035]">
        <Icon size={14} strokeWidth={2} className={tone === 'danger' ? 'text-red-400' : 'text-text-secondary'} />
      </div>
      <AnimatePresence mode="wait">
        {!collapsed && (
          <motion.div
            initial={{ opacity: 0, x: -8 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -8 }}
            transition={{ duration: 0.2 }}
            className="flex flex-1 items-center justify-between"
          >
            <span className="text-xs font-medium text-text-secondary">{label}</span>
            {badge && badge > 0 && (
              <span className="text-xs font-semibold text-[rgb(246,75,0)]">{badge}</span>
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </button>
  )
}
