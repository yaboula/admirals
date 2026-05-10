import { Eye, RadioTower, ShieldCheck } from 'lucide-react'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { useI18n } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { toast } from '@/stores/toast'

export function StreamerModeToggle() {
  const { t } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const setStreamerMode = usePrivacyMode((s) => s.setStreamerMode)

  const handleToggle = (): void => {
    const next = !streamerMode
    setStreamerMode(next)
    sfx.console_tap()
    if (next) {
      toast.info(t('settings.privacyOnToastTitle'), t('settings.privacyOnToastBody'))
    } else {
      toast.warning(t('settings.privacyOffToastTitle'), t('settings.privacyOffToastBody'))
    }
  }

  return (
    <button
      type="button"
      onClick={handleToggle}
      aria-pressed={streamerMode}
      aria-label={streamerMode ? t('settings.disableStreamerMode') : t('settings.enableStreamerMode')}
      className={cn(
        'tactile-focus-ring inline-flex h-8 items-center gap-2 rounded-full px-3 text-[10px] font-semibold uppercase tracking-[0.14em] transition-all duration-180',
        streamerMode ? 'text-brand-signal-orange-light' : 'text-text-primary',
      )}
      style={{
        background: streamerMode
          ? 'linear-gradient(135deg, rgba(48,15,1,0.42), rgba(7,2,1,0.32))'
          : 'rgba(255,255,255,0.08)',
        border: streamerMode ? '1px solid rgba(255,100,19,0.32)' : '1px solid rgba(255,255,255,0.12)',
        boxShadow: streamerMode
          ? 'inset 0 1px 0 rgba(255,255,255,0.08), 0 0 18px -10px rgb(255, 100, 19)'
          : 'inset 0 1px 0 rgba(255,255,255,0.08)',
      }}
    >
      {streamerMode ? <RadioTower size={13} strokeWidth={2.2} /> : <Eye size={13} strokeWidth={2.2} />}
      <span className="hidden xl:inline">{t('settings.streamerMode')}</span>
      <span
        className="inline-flex h-4 min-w-8 items-center justify-center rounded-full px-1.5 text-[9px] tracking-[0.12em]"
        style={{
          background: streamerMode ? 'rgba(255,100,19,0.14)' : 'rgba(255,255,255,0.08)',
          color: streamerMode ? 'rgb(255, 153, 87)' : 'rgb(207, 209, 213)',
        }}
      >
        {streamerMode ? t('settings.streamerModeOnLabel') : t('settings.streamerModeOffLabel')}
      </span>
      {streamerMode ? <ShieldCheck size={12} strokeWidth={2.2} className="opacity-75" /> : null}
    </button>
  )
}
