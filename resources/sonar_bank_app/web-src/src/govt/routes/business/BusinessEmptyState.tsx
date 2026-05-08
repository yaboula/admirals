import { BriefcaseBusiness } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { GovtCard } from '../../components/GovtCard'

export function BusinessEmptyState() {
  const { t } = useI18n()
  return (
    <GovtCard variant="outline" padding="lg" className="flex h-full flex-col items-center justify-center gap-4 text-center">
      <span
        aria-hidden
        className="flex h-14 w-14 items-center justify-center rounded-full border"
        style={{
          background: 'var(--color-govt-accent-subtle)',
          borderColor: 'var(--color-govt-border-strong)',
          color: 'var(--color-govt-accent-light)',
        }}
      >
        <BriefcaseBusiness size={22} strokeWidth={1.6} />
      </span>
      <div className="max-w-[28ch]">
        <p className="text-sm font-semibold text-[var(--color-govt-text-primary)]">{t('govt.business.detail.empty')}</p>
        <p className="mt-1.5 text-[11px] leading-relaxed text-[var(--color-govt-text-tertiary)]">{t('govt.business.detail.emptyHint')}</p>
      </div>
    </GovtCard>
  )
}
