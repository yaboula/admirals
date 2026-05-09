import { motion } from 'motion/react'
import { ArrowRight, Bitcoin, BriefcaseBusiness, Eye, EyeOff, Fingerprint, Landmark, LockKeyhole, RadioTower, ShieldCheck, Sparkles, TrendingUp, type LucideIcon } from 'lucide-react'
import { useLocation, useNavigate } from 'react-router-dom'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { cn } from '@/lib/utils'
import { useAuthGate } from '@/stores/authGate'
import { usePrivacyMode } from '@/stores/privacy'

interface AuthLocationState {
  from?: string
}

const FEATURE_CARDS: Array<{ icon: LucideIcon; title: TranslationKey; description: TranslationKey; tone: string }> = [
  { icon: TrendingUp, title: 'auth.investments', description: 'auth.investmentsDescription', tone: 'oklch(0.72 0.17 154)' },
  { icon: Bitcoin, title: 'auth.crypto', description: 'auth.cryptoDescription', tone: 'oklch(0.70 0.14 255)' },
  { icon: BriefcaseBusiness, title: 'auth.business', description: 'auth.businessDescription', tone: 'oklch(0.76 0.14 80)' },
]

const TRUST_ITEMS: Array<{ icon: LucideIcon; label: TranslationKey }> = [
  { icon: ShieldCheck, label: 'auth.secureSession' },
  { icon: LockKeyhole, label: 'auth.noSnapshot' },
  { icon: Sparkles, label: 'auth.privateByDesign' },
]

export function Auth() {
  const { t } = useI18n()
  const navigate = useNavigate()
  const location = useLocation()
  const unlock = useAuthGate((s) => s.unlock)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const setStreamerMode = usePrivacyMode((s) => s.setStreamerMode)
  const state = location.state as AuthLocationState | null
  const target = state?.from && state.from !== '/auth' ? state.from : '/'

  const handleEnter = () => {
    unlock()
    navigate(target, { replace: true })
  }

  return (
    <main className="relative flex h-[100dvh] w-screen overflow-hidden bg-surface-abyss text-text-primary">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_18%_18%,oklch(0.65_0.22_40/0.14),transparent_30%),radial-gradient(circle_at_84%_20%,oklch(0.70_0.14_255/0.16),transparent_32%),radial-gradient(circle_at_55%_92%,oklch(0.72_0.17_154/0.12),transparent_34%)]" />
      <div className="absolute inset-0 opacity-[0.08] [background-image:linear-gradient(oklch(1_0_0/0.16)_1px,transparent_1px),linear-gradient(90deg,oklch(1_0_0/0.16)_1px,transparent_1px)] [background-size:28px_28px]" />
      <div className="absolute left-1/2 top-1/2 h-[520px] w-[520px] -translate-x-1/2 -translate-y-1/2 rounded-full border border-white/10 bg-white/[0.018] blur-3xl" />

      <section className="relative z-10 mx-auto grid h-full w-full max-w-[1180px] grid-cols-[minmax(0,1fr)_390px] items-center gap-8 px-8 py-7 max-lg:grid-cols-1 max-lg:overflow-y-auto">
        <motion.div initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.45 }} className="min-w-0 space-y-7">
          <div className="space-y-5">
            <Badge tone="brand" variant="soft" size="md" leftIcon={<RadioTower size={14} strokeWidth={2.2} />} className="w-fit">
              {t('auth.eyebrow')}
            </Badge>
            <div className="max-w-2xl space-y-4">
              <h1 className="text-5xl font-semibold leading-[0.98] tracking-[-0.055em] text-text-primary max-md:text-4xl">
                {t('auth.title')}
              </h1>
              <p className="max-w-xl text-sm leading-6 text-text-secondary">
                {t('auth.description')}
              </p>
            </div>
          </div>

          <div className="grid max-w-3xl grid-cols-3 gap-3 max-md:grid-cols-1">
            {FEATURE_CARDS.map((item) => (
              <FeatureCard key={item.title} {...item} />
            ))}
          </div>

          <div className="flex flex-wrap items-center gap-2.5">
            {TRUST_ITEMS.map((item) => (
              <TrustPill key={item.label} icon={item.icon} label={t(item.label)} />
            ))}
          </div>
        </motion.div>

        <motion.div initial={{ opacity: 0, scale: 0.98, y: 14 }} animate={{ opacity: 1, scale: 1, y: 0 }} transition={{ duration: 0.5, delay: 0.08 }} className="relative lg:justify-self-end">
          <div className="absolute -inset-10 rounded-[2.75rem] bg-[radial-gradient(circle_at_50%_16%,oklch(0.65_0.22_40/0.16),transparent_42%),radial-gradient(circle_at_80%_86%,oklch(0.72_0.17_154/0.12),transparent_34%)] blur-3xl" />
          <div className="relative overflow-hidden rounded-[2.25rem] border border-white/10 bg-[linear-gradient(145deg,oklch(0.105_0.012_270/0.92),oklch(0.045_0.006_270/0.96)_58%,oklch(0.035_0.004_270/0.98))] p-5 shadow-[0_34px_100px_-48px_rgba(0,0,0,0.9),inset_0_1px_0_rgba(255,255,255,0.11)] backdrop-blur-2xl">
            <div className="absolute inset-x-8 top-0 h-px bg-gradient-to-r from-transparent via-white/25 to-transparent" />
            <div className="absolute -right-24 -top-24 h-52 w-52 rounded-full border border-white/10 bg-white/[0.025]" />
            <div className="absolute -bottom-28 left-1/2 h-48 w-48 -translate-x-1/2 rounded-full bg-semantic-success/10 blur-3xl" />
            <div className="absolute right-5 top-5">
              <Badge tone={streamerMode ? 'success' : 'warning'} variant="soft" size="sm" pulse={streamerMode} className="border border-white/10 shadow-[0_10px_28px_-18px_currentColor]">
                {streamerMode ? t('auth.streamerOn') : t('auth.streamerOff')}
              </Badge>
            </div>

            <div className="relative pt-8">
              <div className="mx-auto flex h-40 w-40 items-center justify-center rounded-full border border-white/10 bg-[radial-gradient(circle,oklch(1_0_0/0.055),oklch(1_0_0/0.02)_52%,transparent_53%)] shadow-[inset_0_1px_0_rgba(255,255,255,0.10)]">
                <div className="absolute h-32 w-32 rounded-full border border-white/10" />
                <div className="absolute h-40 w-40 rounded-full bg-[conic-gradient(from_210deg,transparent,oklch(0.65_0.22_40/0.42),transparent_38%)] opacity-80" />
                <div className="relative flex h-24 w-24 items-center justify-center rounded-full border border-white/10 bg-surface-abyss/90 shadow-[0_18px_46px_-30px_rgba(0,0,0,0.95),inset_0_1px_0_rgba(255,255,255,0.08)]">
                  <span className="absolute inset-3 rounded-full bg-brand-signal-orange/10 blur-xl" />
                  <Fingerprint size={55} strokeWidth={1.25} className="relative text-brand-signal-orange-light drop-shadow-[0_0_18px_oklch(0.65_0.22_40/0.35)]" />
                </div>
              </div>

              <div className="mt-5 text-center">
                <p className="text-sm font-semibold text-text-primary">{t('auth.biometric')}</p>
                <p className="mt-1 text-[11px] font-medium uppercase tracking-[0.16em] text-text-quaternary">SONAR ID · M004</p>
              </div>
            </div>

            <button
              type="button"
              role="switch"
              aria-checked={streamerMode}
              onClick={() => setStreamerMode(!streamerMode)}
              className="tactile-focus-ring group mt-6 w-full rounded-[1.45rem] border border-white/10 bg-white/[0.045] p-3.5 text-left shadow-[inset_0_1px_0_rgba(255,255,255,0.07)] transition-colors hover:bg-white/[0.07]"
            >
              <div className="flex items-center gap-3">
                <div className={cn('flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl border transition-colors', streamerMode ? 'border-semantic-success-deep/40 bg-semantic-success-glow text-semantic-success-deep' : 'border-semantic-warning-deep/35 bg-semantic-warning-glow text-semantic-warning-deep')}>
                  {streamerMode ? <EyeOff size={18} strokeWidth={2.2} /> : <Eye size={18} strokeWidth={2.2} />}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-3">
                    <span className="text-sm font-semibold text-text-primary">{t('auth.streamerLabel')}</span>
                    <span className={cn('relative h-7 w-12 shrink-0 rounded-full border transition-colors', streamerMode ? 'border-semantic-success-deep/45 bg-semantic-success-glow' : 'border-white/10 bg-white/[0.08]')}>
                      <span className={cn('absolute top-1 h-5 w-5 rounded-full bg-current shadow-[0_5px_16px_-8px_currentColor] transition-transform', streamerMode ? 'translate-x-5 text-semantic-success-deep' : 'translate-x-1 text-text-tertiary')} />
                    </span>
                  </div>
                  <p className="mt-1 text-xs leading-5 text-text-tertiary">{t('auth.streamerDescription')}</p>
                </div>
              </div>
            </button>

            <Button
              size="lg"
              fullWidth
              rightIcon={<ArrowRight size={18} strokeWidth={2.3} />}
              onClick={handleEnter}
              className="mt-4 rounded-2xl"
              style={{
                background: 'linear-gradient(135deg, oklch(0.54 0.17 36), oklch(0.64 0.13 52))',
                borderColor: 'oklch(0.68 0.14 48 / 0.44)',
                boxShadow: '0 16px 38px -25px oklch(0.58 0.17 40 / 0.78), inset 0 1px 0 oklch(1 0 0 / 0.24)',
              }}
            >
              {t('auth.loginCta')}
            </Button>

            <MarketSignalPreview />
          </div>
        </motion.div>
      </section>
    </main>
  )
}

function FeatureCard({ icon: Icon, title, description, tone }: { icon: LucideIcon; title: TranslationKey; description: TranslationKey; tone: string }) {
  const { t } = useI18n()
  return (
    <div className="rounded-[1.5rem] border border-white/10 bg-white/[0.035] p-4 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] backdrop-blur-xl">
      <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/10 bg-white/[0.045]" style={{ color: tone }}>
        <Icon size={19} strokeWidth={2.1} />
      </div>
      <p className="mt-4 text-sm font-semibold text-text-primary">{t(title)}</p>
      <p className="mt-1.5 text-xs leading-5 text-text-tertiary">{t(description)}</p>
    </div>
  )
}

function MarketSignalPreview() {
  const { t } = useI18n()
  const bars = [24, 40, 22, 58, 44, 70, 50, 82, 66, 88, 78, 92]

  return (
    <div className="mt-5 overflow-hidden rounded-[1.35rem] border border-white/10 bg-[radial-gradient(circle_at_84%_74%,oklch(0.72_0.17_154/0.10),transparent_36%),linear-gradient(180deg,oklch(1_0_0/0.046),oklch(1_0_0/0.018))] p-3.5 shadow-[inset_0_1px_0_rgba(255,255,255,0.07)]">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <span className="inline-flex items-center gap-2 text-xs font-semibold text-text-secondary">
            <Landmark size={14} className="text-text-tertiary" />
            {t('auth.signal')}
          </span>
          <div className="mt-1 h-px w-24 bg-gradient-to-r from-white/18 to-transparent" />
        </div>
        <span className="rounded-full border border-semantic-success-deep/25 bg-semantic-success-glow px-2.5 py-1 text-xs font-semibold text-semantic-success-deep shadow-[0_10px_24px_-18px_currentColor] tactile-tabular-nums">+2.8%</span>
      </div>

      <div className="relative mt-4 h-14">
        <div className="absolute inset-x-0 bottom-1.5 h-px bg-gradient-to-r from-white/[0.04] via-white/[0.11] to-white/[0.04]" />
        <div className="absolute inset-x-0 bottom-1.5 grid h-12 grid-cols-12 items-end gap-1.5">
          {bars.map((height, index) => {
            const active = index > 8
            return (
              <span key={index} className="flex h-full items-end justify-center">
                <span
                  className={cn('block w-full max-w-[17px] rounded-t-full rounded-b-md transition-colors', active ? 'shadow-[0_12px_24px_-14px_oklch(0.72_0.17_154)]' : '')}
                  style={{
                    height: `${height}%`,
                    background: active
                      ? 'linear-gradient(180deg, oklch(0.76 0.17 154), oklch(0.52 0.14 154))'
                      : 'linear-gradient(180deg, oklch(1 0 0 / 0.15), oklch(1 0 0 / 0.055))',
                  }}
                />
              </span>
            )
          })}
        </div>
        <div className="absolute bottom-1.5 right-0 h-12 w-24 bg-gradient-to-l from-semantic-success/10 to-transparent blur-xl" />
      </div>
    </div>
  )
}

function TrustPill({ icon: Icon, label }: { icon: LucideIcon; label: string }) {
  return (
    <span className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.035] px-3 py-2 text-xs font-medium text-text-secondary">
      <Icon size={14} strokeWidth={2.1} className="text-text-tertiary" />
      {label}
    </span>
  )
}
