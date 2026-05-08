import { motion } from 'motion/react'
import {
  BadgeCheck,
  Bell,
  ChevronRight,
  CircleDollarSign,
  Eye,
  EyeOff,
  Globe2,
  LockKeyhole,
  RotateCcw,
  Settings as SettingsIcon,
  ShieldCheck,
  Smartphone,
} from 'lucide-react'
import { Button, Card, CardEyebrow, CardTitle } from '@/components/ui'
import { useBootstrap } from '@/data/queries'
import { cn } from '@/lib/utils'
import { LOCALE_NAMES, useI18n } from '@/lib/i18n'
import { maskCidDisplay, maskIbanCompact, maskIbanDisplay, revealIbanDisplay, safeAriaLabel } from '@/lib/privacy'
import { sfx } from '@/lib/sfx'
import { useBankSession, type BankCurrency, type BankLocale } from '@/stores/session'
import { useOnboarding } from '@/stores/onboarding'
import { usePrivacyMode } from '@/stores/privacy'
import { toast } from '@/stores/toast'

export function Settings() {
  const { t, relativeTime } = useI18n()
  const { data } = useBootstrap()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const setStreamerMode = usePrivacyMode((s) => s.setStreamerMode)
  const citizenId = useBankSession((s) => s.citizenId)
  const ibanMasked = useBankSession((s) => s.ibanMasked)
  const locale = useBankSession((s) => s.locale)
  const currency = useBankSession((s) => s.currency)
  const setLocale = useBankSession((s) => s.setLocale)
  const setCurrency = useBankSession((s) => s.setCurrency)
  const onboardingCompletedAt = useBankSession((s) => s.onboardingCompletedAt)
  const startOnboarding = useOnboarding((s) => s.start)
  const primaryIban = data?.accounts[0]?.iban ?? null
  const activeCards = data?.cards.filter((card) => card.status === 'active').length ?? 0
  const activeAccounts = data?.accounts.filter((account) => account.status === 'active').length ?? 0

  const togglePrivacy = (): void => {
    const next = !streamerMode
    setStreamerMode(next)
    sfx.console_tap()
    if (next) {
      toast.info(t('settings.privacyOnToastTitle'), t('settings.privacyOnToastBody'))
    } else {
      toast.warning(t('settings.privacyOffToastTitle'), t('settings.privacyOffToastBody'))
    }
  }

  const changeLocale = (next: BankLocale): void => {
    setLocale(next)
    sfx.console_tap()
    toast.info(t('settings.languageToastTitle'), LOCALE_NAMES[next])
  }

  const changeCurrency = (next: BankCurrency): void => {
    setCurrency(next)
    sfx.console_tap()
    toast.info(t('settings.currencyToastTitle'), next)
  }

  const replayOnboarding = (): void => {
    startOnboarding()
    sfx.signal_emerge()
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
      className="h-full w-full"
    >
      <div
        className="h-full w-full mx-auto max-w-[1500px] gap-4 2xl:gap-5"
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 0.92fr) minmax(360px, 0.48fr)',
          gridTemplateRows: '1fr',
        }}
      >
        <section className="min-h-0 flex flex-col gap-4 2xl:gap-5">
          <SettingsHero streamerMode={streamerMode} accounts={activeAccounts} cards={activeCards} />
          <Card variant="glass" padding="md" className="min-h-0 flex-1 border-white/10 overflow-hidden rounded-[1.75rem]">
            <div className="h-full min-h-0 grid grid-rows-[auto_1fr] gap-4">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <CardEyebrow>{t('settings.preferences')}</CardEyebrow>
                  <CardTitle className="text-base">{t('settings.appControl')}</CardTitle>
                </div>
                <span className="rounded-full border border-white/10 bg-white/[0.045] px-3 py-1.5 text-[10px] font-semibold uppercase tracking-[0.14em] text-text-tertiary">
                  {t('common.local')}
                </span>
              </div>

              <div className="min-h-0 overflow-y-auto pr-1 space-y-3 scrollbar-thin">
                <PreferenceRow
                  icon={<ShieldCheck size={17} />}
                  title={t('settings.screenPrivacy')}
                  description={t('settings.screenPrivacyDescription')}
                  meta={streamerMode ? t('common.active') : t('common.visible')}
                  active={streamerMode}
                  action={
                    <SwitchButton active={streamerMode} onClick={togglePrivacy} activeLabel={t('settings.switchOn')} inactiveLabel={t('settings.switchOff')} />
                  }
                />
                <PreferenceRow
                  icon={<Globe2 size={17} />}
                  title={t('settings.language')}
                  description={t('settings.languageDescription')}
                  meta={LOCALE_NAMES[locale]}
                  action={<LocaleSelector value={locale} onChange={changeLocale} />}
                />
                <PreferenceRow
                  icon={<CircleDollarSign size={17} />}
                  title={t('settings.currency')}
                  description={t('settings.currencyDescription')}
                  meta={currency}
                  action={<CurrencySelector value={currency} onChange={changeCurrency} />}
                />
                <PreferenceRow
                  icon={<RotateCcw size={17} />}
                  title={t('settings.replayWelcome')}
                  description={t('settings.replayWelcomeDescription')}
                  meta={onboardingCompletedAt ? relativeTime(onboardingCompletedAt) : t('common.pending')}
                  action={
                    <Button variant="secondary" size="sm" rightIcon={<ChevronRight size={14} />} onClick={replayOnboarding}>
                      {t('common.open')}
                    </Button>
                  }
                />
                <PreferenceRow
                  icon={<Bell size={17} />}
                  title={t('settings.sensitiveAlerts')}
                  description={t('settings.sensitiveAlertsDescription')}
                  meta={t('common.ready')}
                  action={<StatusPill label={t('settings.quiet')} />}
                />
              </div>
            </div>
          </Card>
        </section>

        <aside className="min-h-0 flex flex-col gap-4 2xl:gap-5">
          <IdentityPanel
            citizenId={citizenId}
            primaryIban={primaryIban}
            ibanMasked={ibanMasked}
            streamerMode={streamerMode}
          />
          <SecuritySummary streamerMode={streamerMode} />
          <DevicePanel />
        </aside>
      </div>
    </motion.div>
  )
}

function SettingsHero({ streamerMode, accounts, cards }: { streamerMode: boolean; accounts: number; cards: number }) {
  const { t } = useI18n()
  return (
    <Card variant="glass" padding="none" className="relative overflow-hidden rounded-[1.75rem] border-white/10 shrink-0">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 14% 0%, oklch(0.70 0.14 230 / 0.13), transparent 34%), linear-gradient(180deg, oklch(1 0 0 / 0.035), transparent 56%)',
        }}
      />
      <div className="relative grid grid-cols-[minmax(300px,1fr)_minmax(300px,0.95fr)] items-center gap-5 p-4 2xl:p-5">
        <div className="min-w-0 max-w-[430px] flex flex-col gap-2">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              <SettingsIcon size={11} strokeWidth={2.3} />
              {t('settings.eyebrow')}
            </span>
          </CardEyebrow>
          <div className="flex flex-col gap-1">
            <h1 className="max-w-[13ch] text-3xl 2xl:text-4xl font-light leading-[0.98] tracking-[-0.055em] text-text-primary [text-wrap:balance]">{t('settings.title')}</h1>
            <p className="text-sm text-text-secondary max-w-[40ch] leading-relaxed">
              {t('settings.description')}
            </p>
          </div>
        </div>
        <div className="min-w-0 grid grid-cols-[minmax(0,1.15fr)_repeat(2,minmax(0,0.72fr))] gap-2">
          <HeroMetric label={t('settings.screenPrivacy')} value={streamerMode ? t('common.active') : t('common.visible')} />
          <HeroMetric label={t('common.accounts')} value={String(accounts)} />
          <HeroMetric label={t('common.cards')} value={String(cards)} />
        </div>
      </div>
    </Card>
  )
}

function HeroMetric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-border-subtle bg-white/[0.04] px-3 py-3 text-right min-w-0">
      <span className="block text-[10px] uppercase tracking-[0.16em] text-text-tertiary truncate">{label}</span>
      <span className="block text-sm font-semibold text-text-primary tactile-tabular-nums truncate">{value}</span>
    </div>
  )
}

function PreferenceRow({ icon, title, description, meta, active, action }: { icon: React.ReactNode; title: string; description: string; meta: string; active?: boolean; action: React.ReactNode }) {
  return (
    <article className="rounded-[1.35rem] border border-white/[0.075] bg-white/[0.035] p-3.5 hover:bg-white/[0.055] transition-colors">
      <div className="flex items-center gap-3">
        <span
          className={cn(
            'inline-flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl border',
            active ? 'border-brand-signal-orange/25 bg-brand-signal-orange/10 text-brand-signal-orange-light' : 'border-white/10 bg-white/[0.04] text-text-secondary',
          )}
        >
          {icon}
        </span>
        <span className="min-w-0 flex-1">
          <span className="flex items-center gap-2">
            <span className="text-sm font-semibold text-text-primary truncate">{title}</span>
            <span className="rounded-full border border-white/10 bg-black/[0.16] px-2 py-0.5 text-[9px] font-semibold uppercase tracking-[0.12em] text-text-tertiary">
              {meta}
            </span>
          </span>
          <span className="mt-1 block text-xs text-text-tertiary leading-relaxed max-w-[62ch]">{description}</span>
        </span>
        <span className="shrink-0">{action}</span>
      </div>
    </article>
  )
}

function SwitchButton({ active, onClick, activeLabel, inactiveLabel }: { active: boolean; onClick: () => void; activeLabel: string; inactiveLabel: string }) {
  return (
    <button
      type="button"
      aria-pressed={active}
      onClick={onClick}
      className={cn(
        'relative inline-flex h-8 w-16 items-center rounded-full border px-1 transition-colors tactile-focus-ring',
        active ? 'border-brand-signal-orange/28 bg-brand-signal-orange/14' : 'border-white/10 bg-white/[0.045]',
      )}
    >
      <span
        className={cn(
          'inline-flex h-6 w-6 items-center justify-center rounded-full bg-white/90 text-black transition-transform',
          active ? 'translate-x-8' : 'translate-x-0',
        )}
      >
        {active ? <EyeOff size={12} strokeWidth={2.4} /> : <Eye size={12} strokeWidth={2.4} />}
      </span>
      <span className="sr-only">{active ? activeLabel : inactiveLabel}</span>
    </button>
  )
}

function LocaleSelector({ value, onChange }: { value: BankLocale; onChange: (locale: BankLocale) => void }) {
  const locales: BankLocale[] = ['en', 'es', 'fr', 'de']
  return (
    <div className="flex items-center gap-1 rounded-2xl border border-white/10 bg-white/[0.035] p-1">
      {locales.map((locale) => (
        <button
          key={locale}
          type="button"
          aria-pressed={value === locale}
          onClick={() => onChange(locale)}
          className={cn(
            'h-7 rounded-xl px-2 text-[10px] font-semibold uppercase tracking-[0.13em] transition-colors tactile-focus-ring',
            value === locale ? 'bg-white/[0.11] text-text-primary' : 'text-text-tertiary hover:text-text-secondary',
          )}
        >
          {locale}
        </button>
      ))}
    </div>
  )
}

function CurrencySelector({ value, onChange }: { value: BankCurrency; onChange: (currency: BankCurrency) => void }) {
  const currencies: BankCurrency[] = ['USD', 'EUR']
  return (
    <div className="flex items-center gap-1 rounded-2xl border border-white/10 bg-white/[0.035] p-1">
      {currencies.map((currency) => (
        <button
          key={currency}
          type="button"
          aria-pressed={value === currency}
          onClick={() => onChange(currency)}
          className={cn(
            'h-7 rounded-xl px-2 text-[10px] font-semibold uppercase tracking-[0.13em] transition-colors tactile-focus-ring',
            value === currency ? 'bg-white/[0.11] text-text-primary' : 'text-text-tertiary hover:text-text-secondary',
          )}
        >
          {currency}
        </button>
      ))}
    </div>
  )
}

function StatusPill({ label }: { label: string }) {
  return (
    <span className="inline-flex h-8 items-center rounded-xl border border-white/10 bg-white/[0.035] px-3 text-xs font-semibold text-text-secondary">
      {label}
    </span>
  )
}

function IdentityPanel({ citizenId, primaryIban, ibanMasked, streamerMode }: { citizenId: string | null; primaryIban: string | null; ibanMasked: string | null; streamerMode: boolean }) {
  const { t } = useI18n()
  const ibanLabel = primaryIban
    ? streamerMode ? maskIbanDisplay(primaryIban) : revealIbanDisplay(primaryIban)
    : ibanMasked ?? '—'
  const compactIban = primaryIban
    ? streamerMode ? maskIbanCompact(primaryIban) : revealIbanDisplay(primaryIban)
    : ibanMasked ?? '—'

  return (
    <Card variant="glass" padding="md" className="relative overflow-hidden border-white/10 shrink-0">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{ background: 'radial-gradient(circle at 86% 0%, oklch(0.70 0.14 230 / 0.13), transparent 38%)' }}
      />
      <div className="relative flex items-start justify-between gap-3">
        <div>
          <CardEyebrow>{t('settings.identity')}</CardEyebrow>
          <CardTitle className="text-base">{t('settings.accessData')}</CardTitle>
        </div>
        <span className="inline-flex h-9 w-9 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.045] text-text-primary">
          <BadgeCheck size={17} strokeWidth={2} />
        </span>
      </div>
      <div className="relative mt-4 space-y-2">
        <PanelRow label={t('settings.client')} value={streamerMode ? maskCidDisplay(citizenId) : citizenId ?? '—'} />
        <PanelRow label={t('settings.primaryIban')} value={compactIban} title={safeAriaLabel(ibanLabel)} mono />
      </div>
    </Card>
  )
}

function SecuritySummary({ streamerMode }: { streamerMode: boolean }) {
  const { t } = useI18n()
  return (
    <Card variant="glass" padding="md" className="border-white/10 shrink-0">
      <div className="flex items-start justify-between gap-3">
        <div>
          <CardEyebrow>{t('settings.protection')}</CardEyebrow>
          <CardTitle className="text-base">{t('settings.visibleState')}</CardTitle>
        </div>
        <LockKeyhole size={18} className="text-text-secondary" strokeWidth={2} />
      </div>
      <div className="mt-4 grid grid-cols-2 gap-2">
        <ProtectionTile label={t('settings.amounts')} locked={streamerMode} />
        <ProtectionTile label={t('settings.ibans')} locked={streamerMode} />
        <ProtectionTile label={t('common.cards')} locked={streamerMode} />
        <ProtectionTile label={t('settings.movements')} locked={streamerMode} />
      </div>
    </Card>
  )
}

function ProtectionTile({ label, locked }: { label: string; locked: boolean }) {
  const { t } = useI18n()
  return (
    <div className="rounded-2xl border border-border-subtle bg-white/[0.03] px-3 py-2.5">
      <span className="block text-[10px] uppercase tracking-[0.13em] text-text-tertiary">{label}</span>
      <span className={cn('mt-1 inline-flex items-center gap-1.5 text-xs font-semibold', locked ? 'text-brand-signal-orange-light' : 'text-text-secondary')}>
        {locked ? <EyeOff size={12} /> : <Eye size={12} />}
        {locked ? t('common.hidden') : t('common.visible')}
      </span>
    </div>
  )
}

function DevicePanel() {
  const { t } = useI18n()
  return (
    <Card variant="glass" padding="md" className="border-white/10 min-h-0 flex-1">
      <div className="flex items-center gap-2 text-text-secondary mb-3">
        <Smartphone size={15} strokeWidth={2} />
        <span className="text-sm font-semibold">{t('settings.thisDevice')}</span>
      </div>
      <div className="space-y-2 text-xs text-text-tertiary leading-relaxed">
        <p>{t('settings.deviceLine1')}</p>
        <p>{t('settings.deviceLine2')}</p>
      </div>
    </Card>
  )
}

function PanelRow({ label, value, title, mono }: { label: string; value: string; title?: string; mono?: boolean }) {
  return (
    <div className="flex items-start justify-between gap-3 rounded-2xl border border-border-subtle bg-white/[0.03] px-3 py-2.5">
      <span className="text-[10px] uppercase tracking-[0.13em] text-text-tertiary pt-1">{label}</span>
      <span title={title} className={cn('text-right text-sm font-semibold text-text-primary min-w-0 break-all', mono ? 'font-mono text-xs text-text-secondary' : undefined)}>
        {value}
      </span>
    </div>
  )
}
