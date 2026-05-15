import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { Bell, ChevronDown, Globe2, RotateCcw, Search } from 'lucide-react'
import { IconButton } from '@/components/ui'
import { LOCALE_NAMES, useI18n } from '@/lib/i18n'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { useTransactionsFilter } from '@/stores/transactionsFilter'
import { toast } from '@/stores/toast'
import { useNotifications } from '@/stores/notifications'
import { BankAvatar } from '@/components/brand/BankAvatar'
import { StreamerModeToggle } from '@/components/security'
import { NotificationDrawer } from './NotificationDrawer'
import { useBankSession, type BankLocale } from '@/stores/session'

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
  greeting,
  subtitle = 'SONAR Bank',
  userInitials,
  profileName,
  profileHandle,
}: TopbarProps) {
  const { t } = useI18n()
  const [query, setQuery] = useState('')
  const [notificationDrawerOpen, setNotificationDrawerOpen] = useState(false)
  const navigate = useNavigate()
  const setTransactionQuery = useTransactionsFilter((s) => s.setQuery)
  const locale = useBankSession((s) => s.locale)
  const setLocale = useBankSession((s) => s.setLocale)
  const unreadCount = useNotifications((s) => s.unreadCount())

  const submitSearch = (event: FormEvent<HTMLFormElement>): void => {
    event.preventDefault()
    const nextQuery = query.trim()
    if (!nextQuery) return
    setTransactionQuery(nextQuery)
    navigate('/transacciones')
    sfx.console_tap()
  }

  const changeLocale = (next: BankLocale): void => {
    setLocale(next)
    sfx.console_tap()
    toast.info(t('settings.languageToastTitle'), LOCALE_NAMES[next])
  }

  return (
    <>
      <div className="relative h-16 px-4 lg:px-6 flex items-center">
        <div
          aria-hidden
          className="absolute inset-x-4 top-0 h-16 rounded-b-[1.75rem] pointer-events-none"
          style={{
            background:
              'linear-gradient(180deg, rgba(7,2,1,0.56), rgba(1,0,0,0.18))',
            boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.05)',
            backdropFilter: 'blur(18px) saturate(150%)',
            WebkitBackdropFilter: 'blur(18px) saturate(150%)',
          }}
        />

        <form onSubmit={submitSearch} className="relative z-10 w-[320px]">
          <div
            className="h-10 rounded-full flex items-center gap-2.5 px-3.5"
            style={{
              background: 'rgba(0,0,0,0.34)',
              border: '1px solid rgba(255,255,255,0.06)',
            }}
          >
            <Search size={15} strokeWidth={2} className="text-text-tertiary shrink-0" />
            <input
              type="search"
              placeholder={t('common.search')}
              aria-label={t('transactions.searchAriaLabel')}
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              className="w-full bg-transparent text-sm text-text-primary placeholder:text-text-tertiary outline-none"
            />
          </div>
        </form>

        <div className="relative z-10 ml-3">
          <StreamerModeToggle />
        </div>

        <div className="relative z-10 ml-auto flex items-center gap-2">
          <div className="flex items-center gap-1 rounded-full border border-white/[0.06] bg-white/[0.025] p-1">
            <IconButton
              icon={<RotateCcw size={16} strokeWidth={1.9} />}
              aria-label={t('topbar.refreshAriaLabel')}
              variant="ghost"
              size="sm"
              onClick={() => toast.info(t('topbar.refreshToastTitle'), t('topbar.refreshToastBody'))}
            />
            <div className="relative">
              <IconButton
                icon={<Bell size={16} strokeWidth={1.9} />}
                aria-label={t('topbar.notificationsAriaLabel')}
                variant="ghost"
                size="sm"
                onClick={() => {
                  setNotificationDrawerOpen(true)
                  sfx.console_tap()
                }}
              />
              {unreadCount > 0 && (
                <span
                  className="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full text-[9px] font-bold text-white"
                  style={{
                    background: 'var(--gradient-primary)',
                    boxShadow: '0 2px 8px -2px rgba(255, 100, 19, 0.6)',
                  }}
                >
                  {unreadCount > 9 ? '9+' : unreadCount}
                </span>
              )}
            </div>
          </div>
          <TopbarLocaleSelector value={locale} onChange={changeLocale} label={t('settings.language')} />
          <ProfileChip
            initials={userInitials}
            name={profileName ?? greeting ?? t('greeting.goodMorning')}
            handle={profileHandle ?? subtitle}
            ariaLabel={t('topbar.profileAriaLabel')}
          />
        </div>
      </div>
      <NotificationDrawer open={notificationDrawerOpen} onClose={() => setNotificationDrawerOpen(false)} />
    </>
  )
}

function TopbarLocaleSelector({
  value,
  onChange,
  label,
}: {
  value: BankLocale
  onChange: (value: BankLocale) => void
  label: string
}) {
  const [open, setOpen] = useState(false)
  const options = Object.keys(LOCALE_NAMES) as BankLocale[]

  const selectLocale = (next: BankLocale): void => {
    onChange(next)
    setOpen(false)
  }

  return (
    <div
      className="relative shrink-0"
      onBlur={(event) => {
        const nextFocus = event.relatedTarget
        if (!(nextFocus instanceof Node) || !event.currentTarget.contains(nextFocus)) setOpen(false)
      }}
    >
      <button
        type="button"
        className={cn(
          'tactile-focus-ring inline-flex h-8 items-center gap-1.5 rounded-full pl-2.5 pr-2',
          'border border-white/10 bg-white/[0.065] text-[10px] font-semibold uppercase tracking-[0.14em] text-text-primary',
          'transition-colors hover:border-white/18 hover:bg-white/[0.09]',
        )}
        aria-label={label}
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((current) => !current)}
      >
        <Globe2 size={13} strokeWidth={2.1} className="text-text-tertiary" />
        <span>{value.toUpperCase()}</span>
        <ChevronDown size={12} strokeWidth={2} className={cn('text-text-tertiary transition-transform', open && 'rotate-180')} />
      </button>

      {open ? (
        <div
          className="absolute right-0 top-[calc(100%+0.5rem)] z-50 w-40 overflow-hidden rounded-2xl border border-white/10 bg-[#0d0908]/95 p-1 shadow-2xl shadow-black/40 backdrop-blur-xl"
          role="menu"
        >
          {options.map((locale) => {
            const active = locale === value
            return (
              <button
                key={locale}
                type="button"
                role="menuitemradio"
                aria-checked={active}
                className={cn(
                  'flex w-full items-center justify-between rounded-xl px-3 py-2 text-left text-xs font-medium transition-colors',
                  active ? 'bg-white/10 text-text-primary' : 'text-text-secondary hover:bg-white/[0.07] hover:text-text-primary',
                )}
                onClick={() => selectLocale(locale)}
              >
                <span>{LOCALE_NAMES[locale]}</span>
                <span className={cn('text-[10px] font-semibold uppercase tracking-[0.14em]', active ? 'text-brand-orange' : 'text-text-tertiary')}>
                  {locale}
                </span>
              </button>
            )
          })}
        </div>
      ) : null}
    </div>
  )
}

function ProfileChip({
  initials,
  name,
  handle,
  ariaLabel,
}: {
  initials: string | undefined
  name: string
  handle: string
  ariaLabel: string
}) {
  return (
    <button
      type="button"
      aria-label={ariaLabel}
      className={cn(
        'tactile-focus-ring shrink-0 inline-flex items-center gap-2',
        'h-11 rounded-full pl-1.5 pr-2.5 ml-1',
        'border border-white/10 hover:border-white/18 transition-colors',
      )}
      style={{
        background: 'rgba(0,0,0,0.34)',
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
