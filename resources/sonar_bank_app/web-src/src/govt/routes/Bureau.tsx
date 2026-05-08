import { motion } from 'motion/react'
import { useNavigate } from 'react-router-dom'
import { ArrowUpRight, ShieldCheck, type LucideIcon } from 'lucide-react'
import { GovtCard } from '../components/GovtCard'
import { GovtPill } from '../components/GovtPill'
import { GOVT_NAV_ITEMS } from '../lib/govtNav'
import { useAceGate } from '@/components/security'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import type { AcePerm } from '@/stores/session'

export function Bureau() {
  const { t, dateTime, money, number } = useI18n()
  const now = new Date()
  const fiscalQuarter = `${now.getFullYear()}-Q${Math.floor(now.getMonth() / 3) + 1}`

  return (
    <div className="relative h-full w-full overflow-y-auto pb-6 scrollbar-thin">
      <div className="mx-auto flex w-full max-w-[1280px] flex-col gap-4 pt-2">
        <motion.section
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.32, ease: [0.16, 1, 0.3, 1] }}
        >
          <GovtCard variant="hero" padding="lg" className="overflow-hidden">
            <div className="grid gap-6 xl:grid-cols-[minmax(0,0.92fr)_minmax(280px,0.4fr)]">
              <div className="flex min-w-0 flex-col justify-between gap-5">
                <div>
                  <GovtPill tone="seal" leftIcon={<ShieldCheck size={11} strokeWidth={2.4} />}>
                    {t('govt.identityEyebrow')}
                  </GovtPill>
                  <h1 className="mt-4 max-w-[20ch] text-4xl font-light leading-[0.92] tracking-[-0.06em] text-[var(--color-govt-text-primary)] md:text-5xl">
                    {t('govt.welcomeTitle')}
                  </h1>
                  <p className="mt-3 max-w-2xl text-sm leading-relaxed text-[var(--color-govt-text-secondary)]">
                    {t('govt.welcomeDescription')}
                  </p>
                </div>
                <div className="flex flex-wrap items-center gap-3">
                  <GovtPill tone="accent">{`${t('govt.fiscalPeriod')} ${fiscalQuarter}`}</GovtPill>
                  <span className="text-xs text-[var(--color-govt-text-tertiary)]">
                    {`${t('govt.lastSync')}: ${dateTime(now.getTime(), { dateStyle: 'medium', timeStyle: 'short' })}`}
                  </span>
                </div>
              </div>
              <BureauSealLarge />
            </div>
          </GovtCard>
        </motion.section>

        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.32, delay: 0.05, ease: [0.16, 1, 0.3, 1] }}
          className="grid gap-3 lg:grid-cols-4"
        >
          <KpiTile label={t('govt.kpi.collected')} value={money(0)} hint={t('govt.kpi.collectedHint')} />
          <KpiTile label={t('govt.kpi.citizens')} value={number(0)} hint={t('govt.kpi.citizensHint')} />
          <KpiTile label={t('govt.kpi.businesses')} value={number(0)} hint={t('govt.kpi.businessesHint')} />
          <KpiTile label={t('govt.kpi.flags')} value={number(0)} hint={t('govt.kpi.flagsHint')} tone="warning" />
        </motion.section>

        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.32, delay: 0.10, ease: [0.16, 1, 0.3, 1] }}
        >
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-sm font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-secondary)]">
              {t('govt.modulesTitle')}
            </h2>
            <span className="text-xs text-[var(--color-govt-text-tertiary)]">
              {t('govt.modulesHint')}
            </span>
          </div>
          <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {GOVT_NAV_ITEMS.filter((item) => item.id !== 'overview').map((item) => (
              <ModuleCard
                key={item.id}
                icon={item.icon}
                title={t(item.labelKey)}
                description={t(item.descriptionKey)}
                to={item.to}
                requiredPerm={item.requiredPerm}
                comingSoon={item.comingSoon}
              />
            ))}
          </div>
        </motion.section>
      </div>
    </div>
  )
}

function BureauSealLarge() {
  return (
    <div className="flex items-center justify-center">
      <div className="relative">
        <div
          aria-hidden
          className="absolute inset-0 -z-[1] rounded-full blur-3xl"
          style={{ background: 'var(--color-govt-accent-glow)' }}
        />
        <div
          aria-hidden
          className="flex h-44 w-44 flex-col items-center justify-center rounded-full border-2 text-center"
          style={{
            background:
              'radial-gradient(circle at 50% 25%, oklch(0.20 0.05 252 / 0.85), oklch(0.07 0.025 250 / 0.95))',
            borderColor: 'oklch(0.66 0.18 252 / 0.50)',
            boxShadow:
              'inset 0 1px 24px oklch(1 0 0 / 0.10), 0 0 60px oklch(0.66 0.18 252 / 0.30)',
          }}
        >
          <span className="font-mono text-3xl font-bold tracking-[-0.05em] text-white">SB</span>
          <span className="mt-1 text-[9px] font-semibold uppercase tracking-[0.24em] text-[var(--color-govt-seal)]">
            SONAR
          </span>
          <span className="text-[9px] font-semibold uppercase tracking-[0.24em] text-[var(--color-govt-text-tertiary)]">
            Treasury Bureau
          </span>
        </div>
      </div>
    </div>
  )
}

function KpiTile({
  label,
  value,
  hint,
  tone = 'neutral',
}: {
  label: string
  value: string
  hint: string
  tone?: 'neutral' | 'warning'
}) {
  return (
    <GovtCard variant="glass" padding="md">
      <span className="block text-[10px] font-semibold uppercase tracking-[0.14em] text-[var(--color-govt-text-tertiary)]">
        {label}
      </span>
      <span
        className={cn(
          'mt-2 block truncate text-2xl font-semibold tactile-tabular-nums',
          tone === 'warning' ? 'text-[oklch(0.85_0.14_85)]' : 'text-[var(--color-govt-text-primary)]',
        )}
      >
        {value}
      </span>
      <span className="mt-2 block truncate text-[11px] text-[var(--color-govt-text-tertiary)]">
        {hint}
      </span>
    </GovtCard>
  )
}

interface ModuleCardProps {
  icon: LucideIcon
  title: string
  description: string
  to: string
  requiredPerm: AcePerm
  comingSoon?: boolean
}

function ModuleCard({ icon: Icon, title, description, to, requiredPerm, comingSoon }: ModuleCardProps) {
  const { t } = useI18n()
  const granted = useAceGate({ require: requiredPerm })
  const navigate = useNavigate()
  const locked = !granted || Boolean(comingSoon)

  const handleClick = () => {
    if (locked) return
    sfx.console_tap()
    navigate(to)
  }

  let statusKey: TranslationKey | null = null
  if (comingSoon) statusKey = 'nav.comingSoon'
  else if (!granted) statusKey = 'nav.permissionRequired'

  return (
    <button
      type="button"
      disabled={locked}
      onClick={handleClick}
      className={cn(
        'group flex flex-col items-start gap-3 rounded-[1.5rem] border p-4 text-left transition-all',
        locked
          ? 'cursor-not-allowed border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] opacity-60'
          : 'border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] hover:-translate-y-0.5 hover:border-[var(--color-govt-border-strong)] hover:bg-[var(--color-govt-accent-subtle)]',
      )}
    >
      <div className="flex w-full items-center justify-between">
        <span
          className="flex h-10 w-10 items-center justify-center rounded-2xl border"
          style={{
            background: 'var(--color-govt-accent-soft)',
            borderColor: 'var(--color-govt-border-strong)',
            color: 'var(--color-govt-accent-light)',
          }}
        >
          <Icon size={18} strokeWidth={1.9} />
        </span>
        {statusKey ? (
          <GovtPill tone={comingSoon ? 'seal' : 'warning'} size="xs">{t(statusKey)}</GovtPill>
        ) : (
          <ArrowUpRight
            size={16}
            strokeWidth={2}
            className="text-[var(--color-govt-text-tertiary)] transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5 group-hover:text-[var(--color-govt-accent-light)]"
          />
        )}
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-semibold text-[var(--color-govt-text-primary)]">
          {title}
        </p>
        <p className="mt-1 line-clamp-2 text-xs leading-relaxed text-[var(--color-govt-text-tertiary)]">
          {description}
        </p>
      </div>
    </button>
  )
}
