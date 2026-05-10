import { motion } from 'motion/react'
import { useNavigate } from 'react-router-dom'
import { ArrowUpRight, ShieldCheck, type LucideIcon } from 'lucide-react'
import sealIrsUrl from '@/assets/branding/seal_irs.png'
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
      <div className="mx-auto flex w-full max-w-[1280px] flex-col gap-6 pt-2">
        <motion.section
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.32, ease: [0.16, 1, 0.3, 1] }}
        >
          <GovtCard variant="hero" padding="lg" className="overflow-hidden">
            <div className="grid gap-6 xl:grid-cols-[minmax(0,0.92fr)_minmax(280px,0.4fr)]">
              <div className="flex min-w-0 flex-col justify-between gap-5">
                <div>
                  <GovtPill tone="gold" leftIcon={<ShieldCheck size={11} strokeWidth={2.4} />}>
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
          <KpiTile label={t('govt.kpi.collected')} value={money(0)} hint={t('govt.kpi.collectedHint')} tone="gold" />
          <KpiTile label={t('govt.kpi.citizens')} value={number(0)} hint={t('govt.kpi.citizensHint')} />
          <KpiTile label={t('govt.kpi.businesses')} value={number(0)} hint={t('govt.kpi.businessesHint')} />
          <KpiTile label={t('govt.kpi.flags')} value={number(0)} hint={t('govt.kpi.flagsHint')} tone="warning" />
        </motion.section>

        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.32, delay: 0.10, ease: [0.16, 1, 0.3, 1] }}
        >
          <div className="mb-4 flex items-center justify-between border-b pb-3" style={{ borderColor: 'var(--color-govt-gold-ring)' }}>
            <h2 className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[var(--color-govt-text-tertiary)]">
              {t('govt.modulesTitle')}
            </h2>
            <span className="text-[10px] text-[var(--color-govt-text-quaternary)]">
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
    <div className="flex items-center justify-center py-2" aria-hidden>
      <div
        className="overflow-hidden rounded-full"
        style={{
          width: 168,
          height: 168,
          border: '3px solid var(--color-govt-gold-ring)',
          boxShadow: '0 0 28px var(--color-govt-gold-glow), 0 0 56px var(--color-govt-gold-subtle)',
          animation: 'seal-pulse-gold 4s ease-in-out infinite',
        }}
      >
        <img
          src={sealIrsUrl}
          alt=""
          className="h-full w-full object-cover"
          draggable={false}
        />
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
  tone?: 'neutral' | 'warning' | 'gold'
}) {
  return (
    <div
      className="relative overflow-hidden rounded-[1.5rem] border p-5"
      style={{
        background: 'var(--color-govt-glass)',
        borderColor: 'var(--color-govt-border)',
      }}
    >
      <div
        aria-hidden
        className="absolute left-0 top-4 h-8 w-[3px] rounded-r-full"
        style={{
          background:
            tone === 'warning' ? 'rgb(230, 173, 0)'
            : tone === 'gold'  ? 'var(--color-govt-gold)'
            : 'var(--color-govt-accent)',
          opacity: tone === 'gold' ? 0.9 : 0.6,
        }}
      />
      <span className="block text-[10px] font-semibold uppercase tracking-[0.16em] text-[var(--color-govt-text-tertiary)]">
        {label}
      </span>
      <span
        className={cn(
          'mt-3 block truncate text-3xl font-light tracking-[-0.04em] tabular-nums',
          tone === 'warning' ? 'text-[rgb(252, 209, 118)]'
          : tone === 'gold'  ? 'text-[var(--color-govt-gold)]'
          : 'text-[var(--color-govt-text-primary)]',
        )}
      >
        {value}
      </span>
      <span className="mt-2 block truncate text-[11px] text-[var(--color-govt-text-quaternary)]">
        {hint}
      </span>
    </div>
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
          ? 'cursor-not-allowed border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] opacity-50'
          : 'border-[var(--color-govt-border)] bg-[var(--color-govt-glass)] hover:-translate-y-0.5 hover:border-[var(--color-govt-gold-ring)] hover:shadow-[0_0_16px_var(--color-govt-gold-subtle)]',
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
