import { BriefcaseBusiness, IdCard } from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { maskMoneyDisplay } from '@/lib/privacy'
import type { GovtTaxCompliance, GovtTopContributor } from '../../data/contracts'

interface Props {
  data: GovtTopContributor[]
}

const COMPLIANCE_TONE: Record<GovtTaxCompliance, { color: string; key: TranslationKey }> = {
  current: { color: 'oklch(0.72 0.18 155)', key: 'govt.census.filters.compliance.current' },
  overdue: { color: 'oklch(0.72 0.20 35)',  key: 'govt.census.filters.compliance.overdue' },
  pending: { color: 'oklch(0.78 0.16 85)',  key: 'govt.census.filters.compliance.pending' },
  exempt:  { color: 'oklch(0.60 0.08 252)', key: 'govt.census.filters.compliance.exempt' },
}

export function TopContributors({ data }: Props) {
  const { t, money } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const max = data[0]?.taxPaid ?? 1

  return (
    <ol className="space-y-2">
      {data.map((c, i) => {
        const pct = (c.taxPaid / max) * 100
        const tone = COMPLIANCE_TONE[c.compliance]
        const amtDisplay = streamerMode ? maskMoneyDisplay() : money(c.taxPaid)
        const Icon = c.kind === 'company' ? BriefcaseBusiness : IdCard

        return (
          <li key={c.id} className="flex items-center gap-3 rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.04_0.008_252/0.60)] p-2.5">
            <span
              aria-hidden
              className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-lg text-[10px] font-semibold tabular-nums"
              style={{ background: 'var(--color-govt-accent-subtle)', color: 'var(--color-govt-accent-light)' }}
            >
              {i + 1}
            </span>
            <span
              aria-hidden
              className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-xl border border-[var(--color-govt-border)]"
              style={{ background: 'oklch(0.06 0.010 252 / 0.7)', color: tone.color }}
            >
              <Icon size={12} strokeWidth={2} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[12px] font-semibold text-[var(--color-govt-text-primary)]">{c.label}</p>
              <div className="mt-0.5 flex items-center gap-2 text-[10px] text-[var(--color-govt-text-tertiary)]">
                <span className="font-mono uppercase tracking-[0.12em]">{c.id}</span>
                <span className="text-[var(--color-govt-text-quaternary)]">·</span>
                <span>{`${t('govt.census.detail.taxBracket')} ${c.bracketCode}`}</span>
              </div>
              <div className="mt-1 h-[3px] w-full overflow-hidden rounded-full bg-white/[0.05]" aria-hidden>
                <span className="block h-full rounded-full" style={{ width: `${pct}%`, background: tone.color }} />
              </div>
            </div>
            <div className="flex flex-shrink-0 flex-col items-end gap-0.5">
              <span className="text-[12px] font-semibold tabular-nums" style={{ color: tone.color }}>{amtDisplay}</span>
              <span className="text-[9px] uppercase tracking-[0.12em]" style={{ color: tone.color }}>{t(tone.key)}</span>
            </div>
          </li>
        )
      })}
    </ol>
  )
}
