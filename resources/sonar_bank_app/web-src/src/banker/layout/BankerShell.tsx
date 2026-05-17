import { useMemo, useState } from 'react'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'motion/react'
import {
  LayoutDashboard,
  Users,
  Sliders,
  Palette,
  ShieldAlert,
  Briefcase,
  Compass,
  UserSearch,
  ChevronLeft,
  ChevronRight,
  LogOut,
  Crown,
  type LucideIcon,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { nuiControl } from '@/lib/nui'
import { useBankerBootstrap } from '../data/queries'
import type { BankerCapabilityMap } from '../data/contracts'

interface BankerModule {
  id: string
  icon: LucideIcon
  label: string
  description: string
  path: string
  capability?: keyof BankerCapabilityMap
  disabledHint?: string
}

const BANKER_MODULES: BankerModule[] = [
  {
    id: 'dashboard',
    icon: LayoutDashboard,
    label: 'Dashboard',
    description: 'KPIs, P&L y resumen ejecutivo',
    path: '/banker',
  },
  {
    id: 'operations',
    icon: Briefcase,
    label: 'Operaciones',
    description: 'KYC, préstamos y cuentas pendientes',
    path: '/banker/operations',
    capability: 'loans_approve',
  },
  {
    id: 'customers',
    icon: UserSearch,
    label: 'Clientes',
    description: 'Buscar, ver detalle, freeze/unfreeze',
    path: '/banker/customers',
    capability: 'customers_view',
  },
  {
    id: 'rates',
    icon: Sliders,
    label: 'Tasas y comisiones',
    description: 'Editor económico con bandas de seguridad',
    path: '/banker/rates',
    capability: 'rates_view',
  },
  {
    id: 'employees',
    icon: Users,
    label: 'Empleados',
    description: 'Contratar, despedir, asignar roles',
    path: '/banker/employees',
    capability: 'employees_view',
  },
  {
    id: 'branding',
    icon: Palette,
    label: 'Branding',
    description: 'Logo, colores y mensaje del banco',
    path: '/banker/branding',
    capability: 'branding_view',
  },
  {
    id: 'compliance',
    icon: ShieldAlert,
    label: 'Compliance',
    description: 'Banderas anti-fraude y resolución',
    path: '/banker/compliance',
    capability: 'fraud_review',
  },
  {
    id: 'missions',
    icon: Compass,
    label: 'Misiones',
    description: 'Despachar y aceptar trabajos',
    path: '/banker/missions',
    capability: 'panel_open',
  },
]

export function BankerShell() {
  const navigate = useNavigate()
  const location = useLocation()
  const [collapsed, setCollapsed] = useState(false)

  const bootstrap = useBankerBootstrap()
  const capabilities = bootstrap.data?.capabilities
  const employee = bootstrap.data?.employee
  const branding = bootstrap.data?.branding
  const counts = bootstrap.data?.counts

  const accessible = useMemo(
    () =>
      BANKER_MODULES.map((m) => {
        const allowed = !m.capability || (capabilities ? capabilities[m.capability] : false)
        return { ...m, allowed }
      }),
    [capabilities],
  )

  const selected = accessible.find((m) => location.pathname === m.path)?.id ?? 'dashboard'

  if (bootstrap.isLoading) {
    return <BankerLoadingScreen />
  }
  if (bootstrap.isError) {
    return <BankerErrorScreen error={bootstrap.error?.message ?? 'No se pudo cargar el panel.'} />
  }

  const totalActive = counts
    ? Object.values(counts).reduce((acc, v) => acc + (v ?? 0), 0)
    : 0

  return (
    <div
      className="flex h-full min-h-0 bg-surface-abyss"
      style={{
        // CSS custom properties so children can use the live banker brand color
        ['--banker-primary' as never]: branding?.primary_color ?? '#FF6413',
        ['--banker-accent' as never]: branding?.accent_color ?? '#FFB047',
      }}
    >
      <motion.aside
        initial={false}
        animate={{ width: collapsed ? 76 : 320 }}
        transition={{ duration: 0.3, ease: [0.4, 0, 0.2, 1] }}
        className="relative flex flex-col border-r border-white/10 bg-[linear-gradient(180deg,rgba(2,2,5,0.98),rgba(0,0,0,0.96))]"
      >
        {/* Brand header */}
        <div className="flex items-center justify-between border-b border-white/10 px-5 py-4">
          <AnimatePresence mode="wait">
            {!collapsed && (
              <motion.div
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -10 }}
                transition={{ duration: 0.18 }}
                className="flex items-center gap-3"
              >
                <div
                  className="flex h-10 w-10 items-center justify-center rounded-2xl border border-white/15"
                  style={{
                    background:
                      'radial-gradient(circle at 50% 0%, rgba(255,176,71,0.22), transparent 70%)',
                  }}
                >
                  <Crown size={18} className="text-[var(--banker-primary)]" />
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-[0.22em] text-text-tertiary">
                    Bank Owner
                  </p>
                  <p className="text-sm font-semibold text-text-primary">
                    {branding?.bank_name ?? 'SONAR Bank'}
                  </p>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
          <button
            onClick={() => setCollapsed((c) => !c)}
            className="ml-auto flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-white/10 bg-white/[0.035] text-text-secondary transition hover:bg-white/[0.07]"
          >
            {collapsed ? <ChevronRight size={14} /> : <ChevronLeft size={14} />}
          </button>
        </div>

        {/* Profile chip */}
        <AnimatePresence mode="wait">
          {!collapsed && employee && (
            <motion.div
              initial={{ opacity: 0, y: -6 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -6 }}
              transition={{ duration: 0.18 }}
              className="border-b border-white/10 px-5 py-4"
            >
              <div className="flex items-center justify-between rounded-2xl border border-white/10 bg-white/[0.03] px-3 py-2.5">
                <div className="flex items-center gap-2.5 min-w-0">
                  <div
                    className="flex h-9 w-9 items-center justify-center rounded-full text-xs font-semibold uppercase text-white"
                    style={{
                      background:
                        'linear-gradient(135deg, var(--banker-primary), var(--banker-accent))',
                    }}
                  >
                    {(employee.role_label ?? employee.role).slice(0, 2)}
                  </div>
                  <div className="min-w-0">
                    <p className="truncate text-xs font-semibold text-text-primary">
                      {employee.role_label ?? employee.role.toUpperCase()}
                    </p>
                    <p className="truncate text-[11px] text-text-tertiary font-mono">
                      {employee.citizen_id}
                    </p>
                  </div>
                </div>
                <span className="text-[10px] uppercase tracking-wider text-text-tertiary">
                  {totalActive} staff
                </span>
              </div>
              {employee.synthetic_admin && (
                <div className="mt-2 rounded-lg border border-amber-500/25 bg-amber-500/5 px-3 py-1.5 text-[11px] text-amber-300">
                  ACE override active — virtual CEO
                </div>
              )}
            </motion.div>
          )}
        </AnimatePresence>

        {/* Modules */}
        <nav className="flex-1 overflow-y-auto p-3 scrollbar-thin">
          <div className="space-y-1">
            {accessible.map((m) => (
              <BankerNavCard
                key={m.id}
                module={m}
                selected={selected === m.id}
                collapsed={collapsed}
                onSelect={() => m.allowed && navigate(m.path)}
              />
            ))}
          </div>
        </nav>

        {/* Footer */}
        <div className="border-t border-white/10 px-3 py-4">
          <button
            onClick={() => void nuiControl('close')}
            className="flex w-full items-center gap-3 rounded-xl border border-red-500/25 px-3 py-2.5 text-left transition hover:bg-red-500/10"
          >
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-red-500/20 bg-red-500/5">
              <LogOut size={14} className="text-red-300" />
            </div>
            <AnimatePresence mode="wait">
              {!collapsed && (
                <motion.span
                  initial={{ opacity: 0, x: -8 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -8 }}
                  transition={{ duration: 0.18 }}
                  className="text-xs font-medium text-red-300"
                >
                  Cerrar panel
                </motion.span>
              )}
            </AnimatePresence>
          </button>
        </div>
      </motion.aside>

      {/* Main */}
      <main className="relative flex-1 min-h-0 overflow-hidden">
        <div className="h-full overflow-y-auto scrollbar-thin">
          <Outlet />
        </div>
      </main>
    </div>
  )
}

function BankerNavCard({
  module,
  selected,
  collapsed,
  onSelect,
}: {
  module: BankerModule & { allowed: boolean }
  selected: boolean
  collapsed: boolean
  onSelect: () => void
}) {
  const Icon = module.icon
  const disabled = !module.allowed
  return (
    <motion.button
      onClick={onSelect}
      disabled={disabled}
      className={cn(
        'relative w-full overflow-hidden rounded-2xl border p-3 text-left transition-all',
        disabled
          ? 'border-white/[0.06] bg-white/[0.015] opacity-50 cursor-not-allowed'
          : selected
            ? 'border-white/20 bg-[radial-gradient(circle_at_0%_0%,rgba(255,100,19,0.14),transparent_60%),rgba(255,255,255,0.05)]'
            : 'border-white/10 bg-white/[0.02] hover:bg-white/[0.045]',
      )}
      whileHover={!disabled ? { scale: 1.005 } : undefined}
      whileTap={!disabled ? { scale: 0.995 } : undefined}
    >
      {selected && !disabled && (
        <motion.div
          layoutId="banker-active-rail"
          className="absolute left-0 top-0 h-full w-1"
          style={{
            background:
              'linear-gradient(180deg, var(--banker-primary), var(--banker-accent))',
          }}
          initial={false}
          transition={{ type: 'spring', stiffness: 320, damping: 32 }}
        />
      )}
      <div className="flex items-center gap-3">
        <div
          className={cn(
            'flex shrink-0 h-10 w-10 items-center justify-center rounded-xl border border-white/10',
            selected && !disabled ? 'bg-white/[0.06]' : 'bg-white/[0.03]',
          )}
        >
          <Icon
            size={18}
            strokeWidth={1.85}
            className={cn(
              'transition-colors',
              selected && !disabled ? 'text-[var(--banker-primary)]' : 'text-text-secondary',
            )}
          />
        </div>
        <AnimatePresence mode="wait">
          {!collapsed && (
            <motion.div
              initial={{ opacity: 0, x: -8 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -8 }}
              transition={{ duration: 0.18 }}
              className="flex-1 min-w-0"
            >
              <div className="flex items-center gap-2">
                <p className="text-sm font-semibold text-text-primary truncate">{module.label}</p>
                {disabled && (
                  <span className="rounded border border-white/10 bg-white/[0.03] px-1.5 py-0.5 text-[9px] uppercase tracking-wider text-text-tertiary">
                    Próx.
                  </span>
                )}
              </div>
              <p className="mt-0.5 truncate text-xs text-text-tertiary">
                {disabled ? module.disabledHint ?? 'Sin permisos' : module.description}
              </p>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </motion.button>
  )
}

function BankerLoadingScreen() {
  return (
    <div className="flex h-full w-full items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="h-7 w-7 animate-spin rounded-full border-2 border-white/10 border-t-[rgb(255,100,19)]" />
        <p className="text-xs uppercase tracking-[0.2em] text-text-tertiary">
          Cargando Bank Owner Panel…
        </p>
      </div>
    </div>
  )
}

function BankerErrorScreen({ error }: { error: string }) {
  return (
    <div className="flex h-full w-full items-center justify-center p-6">
      <div className="max-w-md rounded-3xl border border-red-500/30 bg-red-500/[0.04] p-6 text-center">
        <div className="mx-auto mb-4 inline-flex h-12 w-12 items-center justify-center rounded-2xl border border-red-500/30 bg-red-500/10">
          <ShieldAlert size={22} className="text-red-300" />
        </div>
        <h1 className="text-lg font-semibold text-text-primary">No tienes acceso al panel</h1>
        <p className="mt-2 text-sm text-text-tertiary">{error}</p>
        <p className="mt-4 text-[11px] text-text-tertiary opacity-70">
          Pide a un CEO que te contrate o a un admin del servidor que te promocione con
          <code className="mx-1 rounded bg-black/40 px-1.5 py-0.5 text-[10px] text-text-secondary">
            /setbankowner
          </code>
          .
        </p>
      </div>
    </div>
  )
}
