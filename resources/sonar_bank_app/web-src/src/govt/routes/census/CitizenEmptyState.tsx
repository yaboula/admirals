import { ScanSearch } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { GovtCard } from '../../components/GovtCard'

export function CitizenEmptyState() {
  const { t } = useI18n()
  return (
    <GovtCard variant="outline" padding="lg" className="flex h-full flex-col items-center justify-center gap-4 text-center">
      <span
        aria-hidden
        className="flex h-16 w-16 items-center justify-center rounded-full border"
        style={{
          background: 'var(--color-govt-accent-subtle)',
          borderColor: 'var(--color-govt-border-strong)',
          color: 'var(--color-govt-accent-light)',
        }}
      >
        <ScanSearch size={26} strokeWidth={1.6} />
      </span>
      <div className="max-w-sm">
        <p className="text-sm font-semibold text-[var(--color-govt-text-primary)]">
          {t('govt.census.detail.empty')}
        </p>
        <p className="mt-1.5 text-xs leading-relaxed text-[var(--color-govt-text-tertiary)]">
          {t('govt.census.detail.emptyHint')}
        </p>
      </div>
    </GovtCard>
  )
}
