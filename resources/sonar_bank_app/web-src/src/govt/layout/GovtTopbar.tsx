import { Bell, Search, UserCog } from 'lucide-react'
import { useI18n } from '@/lib/i18n'

export function GovtTopbar() {
  const { t } = useI18n()

  return (
    <header
      className="flex h-[68px] flex-shrink-0 items-center gap-4 px-4"
      style={{ borderBottom: '1px solid var(--color-govt-gold-ring)', boxShadow: '0 1px 0 var(--color-govt-gold-subtle)' }}
    >
      <div className="flex flex-col leading-tight">
        <span className="text-[10px] font-semibold uppercase tracking-[0.18em]" style={{ color: 'var(--color-govt-gold)' }}>
          {t('govt.identityEyebrow')}
        </span>
        <span className="text-sm font-semibold text-[var(--color-govt-text-primary)]">
          {t('govt.bureauName')}
        </span>
      </div>

      <div className="flex flex-1 items-center justify-center">
        <div className="relative w-full max-w-[480px]">
          <Search
            size={15}
            strokeWidth={2}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-govt-text-tertiary)]"
          />
          <input
            type="text"
            placeholder={t('govt.searchPlaceholder')}
            aria-label={t('govt.searchPlaceholder')}
            className="h-10 w-full rounded-2xl border border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] pl-9 pr-4 text-sm text-[var(--color-govt-text-primary)] placeholder:text-[var(--color-govt-text-tertiary)] outline-none transition-colors focus:border-[var(--color-govt-border-active)]"
          />
        </div>
      </div>

      <div className="flex items-center gap-2">
        <StatusChip />
        <IconButton label={t('govt.notifications')}>
          <Bell size={15} strokeWidth={2} />
        </IconButton>
        <ProfileChip role={t('govt.operatorRole')} />
      </div>
    </header>
  )
}

function StatusChip() {
  const { t } = useI18n()
  return (
    <span className="inline-flex h-9 items-center gap-2 rounded-full border border-[oklch(0.65_0.18_155/0.30)] bg-[oklch(0.65_0.18_155/0.08)] px-3 text-[11px] font-semibold uppercase tracking-[0.14em] text-[oklch(0.78_0.16_155)]">
      <span className="h-1.5 w-1.5 rounded-full bg-[oklch(0.65_0.18_155)]" />
      {t('govt.statusOperational')}
    </span>
  )
}

function IconButton({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <button
      type="button"
      aria-label={label}
      className="flex h-9 w-9 items-center justify-center rounded-full border border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] text-[var(--color-govt-text-secondary)] transition-colors hover:bg-white/[0.06] hover:text-[var(--color-govt-text-primary)]"
    >
      {children}
    </button>
  )
}

function ProfileChip({ role }: { role: string }) {
  const { t } = useI18n()
  return (
    <div className="flex items-center gap-2 rounded-full border border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] py-1 pl-1 pr-3">
      <span
        className="flex h-7 w-7 items-center justify-center rounded-full text-white"
        style={{ background: 'var(--gradient-govt-primary)', border: '1px solid var(--color-govt-gold-ring)', boxShadow: '0 0 8px var(--color-govt-gold-glow)' }}
      >
        <UserCog size={14} strokeWidth={2} />
      </span>
      <div className="flex min-w-0 flex-col leading-tight">
        <span className="truncate text-xs font-semibold text-[var(--color-govt-text-primary)]">
          {t('govt.operatorName')}
        </span>
        <span className="text-[10px] uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
          {role}
        </span>
      </div>
    </div>
  )
}
