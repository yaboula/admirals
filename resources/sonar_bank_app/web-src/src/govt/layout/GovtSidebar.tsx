import { NavLink } from 'react-router-dom'
import { LockKeyhole } from 'lucide-react'
import { SonarBureauSeal } from '../components/SonarBureauSeal'
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
          background: 'linear-gradient(180deg, oklch(0.10 0.010 252 / 0.88), oklch(0.05 0.008 252 / 0.96))',
          border: '1px solid oklch(1 0 0 / 0.09)',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.05), 0 28px 64px -44px oklch(0 0 0 / 0.95)',
          backdropFilter: 'blur(24px) saturate(150%)',
          WebkitBackdropFilter: 'blur(24px) saturate(150%)',
        }}
      >
        <BureauSeal />

        <div
          aria-hidden
          className="h-px w-8"
          style={{ background: 'var(--color-govt-gold-ring)' }}
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
        style={{
          filter: 'drop-shadow(0 0 8px oklch(0.76 0.14 82 / 0.50))',
          animation: 'seal-pulse-gold 3.6s ease-in-out infinite',
        }}
      >
        <SonarBureauSeal size={54} showText={false} />
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
            ? 'border border-[var(--color-govt-gold-ring)] bg-[var(--color-govt-accent-soft)] text-white shadow-[0_0_18px_var(--color-govt-gold-glow)]'
            : 'text-[var(--color-govt-text-tertiary)] hover:bg-white/[0.05] hover:text-[var(--color-govt-text-primary)]',
        )
      }
    >
      <Icon size={18} strokeWidth={1.8} />
    </NavLink>
  )
}
