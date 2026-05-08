import { NavLink } from 'react-router-dom'
import { LockKeyhole } from 'lucide-react'
import { useAceGate } from '@/components/security'
import { useI18n } from '@/lib/i18n'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { GOVT_NAV_ITEMS, type GovtNavItem } from '../lib/govtNav'

export function GovtSidebar() {
  return (
    <aside className="relative h-full w-[88px] flex-shrink-0 p-3">
      <div
        className="flex h-full w-full flex-col items-center overflow-hidden rounded-[2rem]"
        style={{
          background: 'linear-gradient(180deg, oklch(0.13 0.035 252 / 0.78), oklch(0.06 0.025 252 / 0.94))',
          border: '1px solid oklch(0.66 0.18 252 / 0.18)',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.06), 0 28px 64px -44px oklch(0 0 0 / 0.95)',
          backdropFilter: 'blur(24px) saturate(150%)',
          WebkitBackdropFilter: 'blur(24px) saturate(150%)',
        }}
      >
        <BureauSeal />

        <div
          aria-hidden
          className="h-px w-8"
          style={{ background: 'oklch(0.66 0.18 252 / 0.30)' }}
        />

        <nav className="flex flex-1 flex-col items-center gap-2.5 py-4">
          {GOVT_NAV_ITEMS.map((item) => (
            <GovtSidebarItem key={item.id} item={item} />
          ))}
        </nav>
      </div>
    </aside>
  )
}

function BureauSeal() {
  return (
    <div className="flex items-center justify-center pb-4 pt-5" aria-hidden>
      <div
        className="flex h-10 w-10 items-center justify-center rounded-2xl border"
        style={{
          background: 'var(--gradient-govt-primary)',
          borderColor: 'oklch(1 0 0 / 0.18)',
          boxShadow: '0 0 18px oklch(0.66 0.18 252 / 0.45), inset 0 1px 0 oklch(1 0 0 / 0.18)',
        }}
      >
        <span className="font-mono text-base font-bold tracking-[-0.06em] text-white">SB</span>
      </div>
    </div>
  )
}

function GovtSidebarItem({ item }: { item: GovtNavItem }) {
  const Icon = item.icon
  const { t } = useI18n()
  const granted = useAceGate({ require: item.requiredPerm })
  const label = t(item.labelKey)

  if (!granted) {
    return (
      <div
        className="flex h-11 w-11 cursor-not-allowed items-center justify-center rounded-2xl opacity-40"
        title={`${label} (${t('nav.permissionRequired')})`}
        style={{ color: 'var(--color-govt-text-tertiary)' }}
      >
        <LockKeyhole size={16} strokeWidth={1.8} />
      </div>
    )
  }

  if (item.comingSoon) {
    return (
      <div
        className="flex h-11 w-11 cursor-not-allowed items-center justify-center rounded-2xl opacity-45"
        title={`${label} (${t('nav.comingSoon')})`}
        style={{ color: 'var(--color-govt-text-tertiary)' }}
      >
        <Icon size={18} strokeWidth={1.8} />
      </div>
    )
  }

  return (
    <NavLink
      to={item.to}
      end={item.end}
      onClick={() => sfx.console_tap()}
      title={label}
      className={({ isActive }) =>
        cn(
          'group relative flex h-11 w-11 items-center justify-center rounded-2xl transition-all duration-200',
          isActive
            ? 'border border-[var(--color-govt-border-active)] bg-[var(--color-govt-accent-soft)] text-white shadow-[0_0_18px_var(--color-govt-accent-glow)]'
            : 'text-[var(--color-govt-text-tertiary)] hover:bg-white/[0.05] hover:text-[var(--color-govt-text-primary)]',
        )
      }
    >
      <Icon size={18} strokeWidth={1.8} />
    </NavLink>
  )
}
