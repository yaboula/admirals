import { useEffect, useMemo, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { ArrowRight, Check, Copy, Landmark, Send, ShieldCheck, Wallet, X } from 'lucide-react'
import { Button } from '@/components/ui'
import { useI18n } from '@/lib/i18n'
import { cn } from '@/lib/utils'
import { maskIbanDisplay, revealIbanDisplay, safeAriaLabel } from '@/lib/privacy'
import { sfx } from '@/lib/sfx'
import { useBankSession } from '@/stores/session'
import { useOnboarding, type OnboardingStep } from '@/stores/onboarding'
import { usePrivacyMode } from '@/stores/privacy'
import { toast } from '@/stores/toast'

const STORAGE_PREFIX = 'sonar-bank:onboarding-completed:'

export interface OnboardingOverlayProps {
  citizenId: string
  primaryIban?: string | null
}

export function OnboardingOverlay({ citizenId, primaryIban }: OnboardingOverlayProps) {
  const { t } = useI18n()
  const navigate = useNavigate()
  const reduced = useReducedMotion()
  const { active, start: startOnboarding, next, skipStep, skipAll, finish } = useOnboarding()
  const { setSession } = useBankSession()
  const { onboardingCompletedAt } = useBankSession((s) => s)
  const completed = useOnboarding((s) => s.completed)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const step = useOnboarding((s) => s.step)

  const storageKey = citizenId ? `${STORAGE_PREFIX}${citizenId}` : null

  useEffect(() => {
    if (!citizenId || onboardingCompletedAt || active || completed || !storageKey) return
    if (window.localStorage.getItem(storageKey) === 'done') return
    startOnboarding()
    sfx.signal_emerge()
  }, [active, citizenId, completed, onboardingCompletedAt, startOnboarding, storageKey])

  useEffect(() => {
    if (!storageKey || !completed) return
    window.localStorage.setItem(storageKey, 'done')
    setSession({ onboardingCompletedAt: Date.now() })
  }, [completed, setSession, storageKey])

  const displayIban = useMemo(() => {
    if (!primaryIban) return 'ES•• •••• •••• ••••'
    return streamerMode ? maskIbanDisplay(primaryIban) : revealIbanDisplay(primaryIban)
  }, [primaryIban, streamerMode])

  const copyIban = async (): Promise<void> => {
    if (!primaryIban) return
    try {
      await navigator.clipboard.writeText(primaryIban.replace(/\s+/g, ''))
      sfx.coin_clink()
      toast.success(t('onboarding.copyIban'), streamerMode ? maskIbanDisplay(primaryIban) : revealIbanDisplay(primaryIban))
    } catch {
      toast.warning(t('onboarding.clipboardDenied'), '')
    }
  }

  const completeAndGo = (path?: string): void => {
    finish()
    sfx.vault_close()
    if (path) navigate(path)
  }

  const handlePrimary = (): void => {
    if (step < 3) {
      next()
      sfx.layer_dive()
      return
    }
    completeAndGo()
  }

  const handleSkipStep = (): void => {
    skipStep()
    sfx.console_tap()
  }

  const handleSkipAll = (): void => {
    skipAll()
    sfx.console_tap()
  }

  return (
    <AnimatePresence>
      {active && (
        <motion.div
          role="dialog"
          aria-modal="true"
          aria-labelledby="bank-onboarding-title"
          className="fixed inset-0 z-[110] flex items-center justify-center bg-black/72 backdrop-blur-2xl px-6"
          initial={reduced ? false : { opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={reduced ? { opacity: 0 } : { opacity: 0 }}
          transition={{ duration: reduced ? 0 : 0.24 }}
        >
          <motion.section
            className="relative w-full max-w-[880px] overflow-hidden rounded-[2rem] border border-white/12 bg-surface-card/95 p-5 2xl:p-6 tactile-glass-card"
            initial={reduced ? false : { opacity: 0, y: 18, scale: 0.985 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduced ? { opacity: 0 } : { opacity: 0, y: 10, scale: 0.985 }}
            transition={reduced ? { duration: 0 } : { duration: 0.42, ease: [0.16, 1, 0.3, 1] }}
          >
            <div
              aria-hidden
              className="absolute inset-0 pointer-events-none"
              style={{
                background:
                  'radial-gradient(circle at 50% -18%, oklch(0.65 0.22 40 / 0.22), transparent 46%), radial-gradient(circle at 86% 14%, oklch(0.70 0.14 230 / 0.14), transparent 34%)',
              }}
            />
            <button
              type="button"
              onClick={handleSkipAll}
              aria-label={t('onboarding.skipWelcome')}
              className="absolute right-5 top-5 z-10 inline-flex h-9 w-9 items-center justify-center rounded-full border border-white/10 bg-white/[0.045] text-text-tertiary hover:text-text-primary hover:bg-white/[0.075] tactile-focus-ring"
            >
              <X size={16} strokeWidth={2} />
            </button>

            <div className="relative grid grid-cols-[0.86fr_1.14fr] gap-6 min-h-[470px]">
              <OnboardingVisual step={step} displayIban={displayIban} onCopyIban={copyIban} />
              <div className="min-w-0 flex flex-col justify-between gap-5 pt-3 pr-9 pb-1">
                <div className="space-y-5">
                  <ProgressPips step={step} />
                  <OnboardingCopy step={step} />
                </div>
                <div className="space-y-3">
                  {step === 3 && (
                    <div className="grid grid-cols-3 gap-2">
                      <MiniAction icon={<Send size={14} />} label={t('onboarding.transfer')} onClick={() => completeAndGo('/transferir')} />
                      <MiniAction icon={<Wallet size={14} />} label={t('onboarding.accounts')} onClick={() => completeAndGo('/cuentas')} />
                      <MiniAction icon={<ShieldCheck size={14} />} label={t('onboarding.privacy')} onClick={() => completeAndGo()} />
                    </div>
                  )}
                  <div className="flex items-center justify-between gap-3">
                    <button
                      type="button"
                      onClick={step === 1 ? handleSkipAll : handleSkipStep}
                      className="text-xs font-semibold text-text-tertiary hover:text-text-secondary underline-offset-4 hover:underline tactile-focus-ring rounded-md px-1 py-1"
                    >
                      {step === 1 ? t('onboarding.skipAll') : t('onboarding.skipStep')}
                    </button>
                    <Button
                      variant="secondary"
                      size="md"
                      rightIcon={step < 3 ? <ArrowRight size={15} /> : <Check size={15} />}
                      onClick={handlePrimary}
                    >
                      {step === 1 ? t('onboarding.viewMyIban') : step === 2 ? t('onboarding.exploreOptions') : t('onboarding.enter')}
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          </motion.section>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

function OnboardingVisual({ step, displayIban, onCopyIban }: { step: OnboardingStep; displayIban: string; onCopyIban: () => void }) {
  return (
    <div className="relative overflow-hidden rounded-[1.6rem] border border-white/10 bg-black/20 p-5 flex flex-col justify-between">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{ background: 'linear-gradient(150deg, oklch(1 0 0 / 0.08), transparent 46%), radial-gradient(circle at 20% 20%, oklch(0.65 0.22 40 / 0.16), transparent 44%)' }}
      />
      <div className="relative flex items-center justify-between">
        <span className="inline-flex h-12 w-12 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.055] text-text-primary">
          {step === 1 ? <Wallet size={21} /> : step === 2 ? <Landmark size={21} /> : <ShieldCheck size={21} />}
        </span>
        <span className="rounded-full border border-white/10 bg-white/[0.045] px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.14em] text-text-tertiary">
          Paso {step}/3
        </span>
      </div>

      <div className="relative flex flex-col items-center justify-center text-center gap-4 py-7">
        {step === 2 ? (
          <button
            type="button"
            onClick={onCopyIban}
            aria-label={safeAriaLabel(`Copiar IBAN ${displayIban}`)}
            className="group relative w-full overflow-hidden rounded-[1.45rem] border border-white/12 bg-white/[0.045] px-[1.125rem] py-5 text-left hover:bg-white/[0.07] transition-colors tactile-focus-ring"
          >
            <span
              aria-hidden
              className="absolute inset-x-4 top-0 h-px bg-gradient-to-r from-transparent via-white/24 to-transparent opacity-70"
            />
            <span className="flex items-center justify-between gap-3">
              <span className="text-[10px] uppercase tracking-[0.16em] text-text-tertiary">Tu IBAN</span>
              <span className="inline-flex h-7 w-7 items-center justify-center rounded-full border border-white/10 bg-white/[0.045] text-text-tertiary group-hover:text-text-primary">
                <Copy size={12} />
              </span>
            </span>
            <span className="mt-3 block font-mono text-[15px] 2xl:text-base font-semibold text-text-primary tracking-[0.11em] tactile-tabular-nums whitespace-normal leading-relaxed">
              {displayIban}
            </span>
            <span className="mt-4 block h-px bg-white/[0.07]" />
            <span className="mt-3 block text-xs font-semibold text-text-secondary">
              Toca para copiar y recibir pagos
            </span>
          </button>
        ) : (
          <div className="relative h-52 w-52 rounded-full border border-white/10 bg-white/[0.035] flex items-center justify-center">
            <div className="absolute inset-7 rounded-full border border-white/10 bg-black/20" />
            <div className="relative h-24 w-24 rounded-[2rem] border border-white/12 bg-white/[0.07] flex items-center justify-center text-text-primary shadow-2xl">
              {step === 1 ? <Landmark size={42} strokeWidth={1.5} /> : <Wallet size={42} strokeWidth={1.5} />}
            </div>
          </div>
        )}
      </div>

      <ProgressPips step={step} />
    </div>
  )
}

function ProgressPips({ step }: { step: OnboardingStep }) {
  const { t } = useI18n()
  return (
    <div className="relative grid grid-cols-3 gap-2">
      {t('onboarding.transferControlSave').split(',').map((label: string, index: number) => (
          <div key={label} className={cn('rounded-2xl border px-2.5 py-2 text-center text-[10px] font-semibold uppercase tracking-[0.12em]', index + 1 <= step ? 'border-white/14 bg-white/[0.06] text-text-secondary' : 'border-white/[0.055] bg-white/[0.02] text-text-tertiary')}>
            {label}
          </div>
        ))}
    </div>
  )
}

function OnboardingCopy({ step }: { step: OnboardingStep }) {
  const { t } = useI18n()
  const copy = {
    1: {
      eyebrow: t('onboarding.step1Eyebrow'),
      title: t('onboarding.step1Title'),
      description: t('onboarding.step1Description'),
    },
    2: {
      eyebrow: t('onboarding.step2Eyebrow'),
      title: t('onboarding.step2Title'),
      description: t('onboarding.step2Description'),
    },
    3: {
      eyebrow: t('onboarding.step3Eyebrow'),
      title: t('onboarding.step3Title'),
      description: t('onboarding.step3Description'),
    },
  }[step]

  return (
    <div>
      <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-text-tertiary">{copy.eyebrow}</p>
      <h1 id="bank-onboarding-title" className="mt-3 text-4xl 2xl:text-5xl font-light tracking-[-0.06em] leading-[0.98] text-text-primary">
        {copy.title}
      </h1>
      <p className="mt-4 text-sm text-text-secondary leading-relaxed max-w-[44ch]">{copy.description}</p>
    </div>
  )
}

function MiniAction({ icon, label, onClick }: { icon: ReactNode; label: string; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="rounded-2xl border border-white/10 bg-white/[0.035] px-3 py-3 text-left text-xs font-semibold text-text-secondary hover:text-text-primary hover:bg-white/[0.065] transition-colors tactile-focus-ring"
    >
      <span className="mb-2 inline-flex h-8 w-8 items-center justify-center rounded-xl border border-white/10 bg-black/20 text-text-primary">{icon}</span>
      <span className="block truncate">{label}</span>
    </button>
  )
}
