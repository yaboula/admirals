import { motion } from 'motion/react'
import {
  BadgeCheck,
  Bell,
  ChevronRight,
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
import { cn, formatRelativeTime } from '@/lib/utils'
import { maskCidDisplay, maskIbanCompact, maskIbanDisplay, revealIbanDisplay, safeAriaLabel } from '@/lib/privacy'
import { sfx } from '@/lib/sfx'
import { useBankSession, type BankSessionState } from '@/stores/session'
import { useOnboarding } from '@/stores/onboarding'
import { usePrivacyMode } from '@/stores/privacy'
import { toast } from '@/stores/toast'

type LocaleOption = BankSessionState['locale']

const LOCALE_LABELS: Record<LocaleOption, string> = {
  es: 'Español',
  en: 'English',
  fr: 'Français',
  de: 'Deutsch',
}

export function Settings() {
  const { data } = useBootstrap()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const setStreamerMode = usePrivacyMode((s) => s.setStreamerMode)
  const citizenId = useBankSession((s) => s.citizenId)
  const ibanMasked = useBankSession((s) => s.ibanMasked)
  const locale = useBankSession((s) => s.locale)
  const setLocale = useBankSession((s) => s.setLocale)
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
      toast.info('Privacidad activa', 'Importes, IBANs y datos sensibles quedan ocultos en pantalla.')
    } else {
      toast.warning('Datos visibles', 'La información sensible vuelve a mostrarse en esta sesión.')
    }
  }

  const changeLocale = (next: LocaleOption): void => {
    setLocale(next)
    sfx.console_tap()
    toast.info('Idioma actualizado', LOCALE_LABELS[next])
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
                  <CardEyebrow>Preferencias</CardEyebrow>
                  <CardTitle className="text-base">Control de la app</CardTitle>
                </div>
                <span className="rounded-full border border-white/10 bg-white/[0.045] px-3 py-1.5 text-[10px] font-semibold uppercase tracking-[0.14em] text-text-tertiary">
                  Local
                </span>
              </div>

              <div className="min-h-0 overflow-y-auto pr-1 space-y-3 scrollbar-thin">
                <PreferenceRow
                  icon={<ShieldCheck size={17} />}
                  title="Privacidad en pantalla"
                  description="Oculta importes, IBANs, identificadores y detalles sensibles cuando necesites compartir la vista."
                  meta={streamerMode ? 'Activa' : 'Visible'}
                  active={streamerMode}
                  action={
                    <SwitchButton active={streamerMode} onClick={togglePrivacy} activeLabel="ON" inactiveLabel="OFF" />
                  }
                />
                <PreferenceRow
                  icon={<Globe2 size={17} />}
                  title="Idioma"
                  description="Preferencia local de interfaz. Los textos bancarios se mantienen claros y discretos."
                  meta={LOCALE_LABELS[locale]}
                  action={<LocaleSelector value={locale} onChange={changeLocale} />}
                />
                <PreferenceRow
                  icon={<RotateCcw size={17} />}
                  title="Volver a ver bienvenida"
                  description="Reabre la introducción con tu IBAN y accesos iniciales sin modificar tus datos."
                  meta={onboardingCompletedAt ? formatRelativeTime(onboardingCompletedAt) : 'Pendiente'}
                  action={
                    <Button variant="secondary" size="sm" rightIcon={<ChevronRight size={14} />} onClick={replayOnboarding}>
                      Abrir
                    </Button>
                  }
                />
                <PreferenceRow
                  icon={<Bell size={17} />}
                  title="Avisos sensibles"
                  description="Los avisos críticos se mostrarán solo cuando exista una acción que requiera atención."
                  meta="Preparado"
                  action={<StatusPill label="Silencioso" />}
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
      <div className="relative flex items-center justify-between gap-5 p-4 2xl:p-5">
        <div className="min-w-0 flex flex-col gap-2">
          <CardEyebrow>
            <span className="inline-flex items-center gap-1.5">
              <SettingsIcon size={11} strokeWidth={2.3} />
              AJUSTES
            </span>
          </CardEyebrow>
          <div className="flex flex-col gap-1">
            <h1 className="text-3xl 2xl:text-4xl font-light tracking-[-0.055em] text-text-primary">Tu entorno, bajo control</h1>
            <p className="text-sm text-text-secondary max-w-[58ch] leading-relaxed">
              Configura privacidad, preferencias y datos visibles desde un espacio claro y discreto.
            </p>
          </div>
        </div>
        <div className="shrink-0 grid grid-cols-3 gap-2 min-w-[420px]">
          <HeroMetric label="Privacidad" value={streamerMode ? 'Activa' : 'Visible'} />
          <HeroMetric label="Cuentas" value={String(accounts)} />
          <HeroMetric label="Tarjetas" value={String(cards)} />
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

function LocaleSelector({ value, onChange }: { value: LocaleOption; onChange: (locale: LocaleOption) => void }) {
  const locales: LocaleOption[] = ['es', 'en', 'fr', 'de']
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

function StatusPill({ label }: { label: string }) {
  return (
    <span className="inline-flex h-8 items-center rounded-xl border border-white/10 bg-white/[0.035] px-3 text-xs font-semibold text-text-secondary">
      {label}
    </span>
  )
}

function IdentityPanel({ citizenId, primaryIban, ibanMasked, streamerMode }: { citizenId: string | null; primaryIban: string | null; ibanMasked: string | null; streamerMode: boolean }) {
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
          <CardEyebrow>Identidad</CardEyebrow>
          <CardTitle className="text-base">Datos de acceso</CardTitle>
        </div>
        <span className="inline-flex h-9 w-9 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.045] text-text-primary">
          <BadgeCheck size={17} strokeWidth={2} />
        </span>
      </div>
      <div className="relative mt-4 space-y-2">
        <PanelRow label="Cliente" value={streamerMode ? maskCidDisplay(citizenId) : citizenId ?? '—'} />
        <PanelRow label="IBAN principal" value={compactIban} title={safeAriaLabel(ibanLabel)} mono />
      </div>
    </Card>
  )
}

function SecuritySummary({ streamerMode }: { streamerMode: boolean }) {
  return (
    <Card variant="glass" padding="md" className="border-white/10 shrink-0">
      <div className="flex items-start justify-between gap-3">
        <div>
          <CardEyebrow>Protección</CardEyebrow>
          <CardTitle className="text-base">Estado visible</CardTitle>
        </div>
        <LockKeyhole size={18} className="text-text-secondary" strokeWidth={2} />
      </div>
      <div className="mt-4 grid grid-cols-2 gap-2">
        <ProtectionTile label="Importes" locked={streamerMode} />
        <ProtectionTile label="IBANs" locked={streamerMode} />
        <ProtectionTile label="Tarjetas" locked={streamerMode} />
        <ProtectionTile label="Movimientos" locked={streamerMode} />
      </div>
    </Card>
  )
}

function ProtectionTile({ label, locked }: { label: string; locked: boolean }) {
  return (
    <div className="rounded-2xl border border-border-subtle bg-white/[0.03] px-3 py-2.5">
      <span className="block text-[10px] uppercase tracking-[0.13em] text-text-tertiary">{label}</span>
      <span className={cn('mt-1 inline-flex items-center gap-1.5 text-xs font-semibold', locked ? 'text-brand-signal-orange-light' : 'text-text-secondary')}>
        {locked ? <EyeOff size={12} /> : <Eye size={12} />}
        {locked ? 'Oculto' : 'Visible'}
      </span>
    </div>
  )
}

function DevicePanel() {
  return (
    <Card variant="glass" padding="md" className="border-white/10 min-h-0 flex-1">
      <div className="flex items-center gap-2 text-text-secondary mb-3">
        <Smartphone size={15} strokeWidth={2} />
        <span className="text-sm font-semibold">Este dispositivo</span>
      </div>
      <div className="space-y-2 text-xs text-text-tertiary leading-relaxed">
        <p>Las preferencias se guardan localmente para mantener la experiencia rápida y estable.</p>
        <p>Los datos financieros siguen viniendo del snapshot bancario y de las actualizaciones en vivo.</p>
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
