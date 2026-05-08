import { useI18n, type TranslationKey } from '@/lib/i18n'
import { usePrivacyMode } from '@/stores/privacy'
import { maskMoneyDisplay } from '@/lib/privacy'
import type { GovtSectorRevenue } from '../../data/contracts'

interface Props {
  data: GovtSectorRevenue[]
}

const SECTOR_COLORS: Record<string, string> = {
  farming:   'oklch(0.72 0.18 135)',
  milling:   'oklch(0.75 0.15 85)',
  bakery:    'oklch(0.78 0.16 55)',
  retail:    'oklch(0.72 0.17 215)',
  logistics: 'oklch(0.72 0.15 265)',
  services:  'oklch(0.72 0.12 252)',
  finance:   'oklch(0.68 0.18 155)',
  other:     'oklch(0.60 0.08 252)',
}

const SECTOR_LABEL_KEY: Record<string, TranslationKey> = {
  farming:   'govt.business.sector.farming',
  milling:   'govt.business.sector.milling',
  bakery:    'govt.business.sector.bakery',
  retail:    'govt.business.sector.retail',
  logistics: 'govt.business.sector.logistics',
  services:  'govt.business.sector.services',
  finance:   'govt.business.sector.finance',
  other:     'govt.business.sector.other',
}

export function SectorBars({ data }: Props) {
  const { t, money, number } = useI18n()
  const streamerMode = usePrivacyMode((s) => s.streamerMode)
  const max = Math.max(...data.map((d) => d.collected))

  return (
    <ul className="space-y-3">
      {data.map((row) => {
        const pct = max > 0 ? (row.collected / max) * 100 : 0
        const color = SECTOR_COLORS[row.sector] ?? SECTOR_COLORS['other']!
        const labelKey = SECTOR_LABEL_KEY[row.sector] ?? 'govt.business.sector.other'
        const amtDisplay = streamerMode ? maskMoneyDisplay() : money(row.collected)

        return (
          <li key={row.sector}>
            <div className="flex items-center justify-between gap-3 text-[11px]">
              <span className="font-semibold uppercase tracking-[0.10em]" style={{ color }}>
                {t(labelKey)}
              </span>
              <span className="flex items-center gap-2 text-right tabular-nums text-[var(--color-govt-text-tertiary)]">
                <span>{amtDisplay}</span>
                <span className="text-[var(--color-govt-text-quaternary)]">·</span>
                <span>{`${number(row.entityCount)} ${t('govt.reports.sectorBars.entities')}`}</span>
              </span>
            </div>
            <div className="mt-1 h-[5px] w-full overflow-hidden rounded-full bg-white/[0.05]" aria-hidden>
              <span
                className="block h-full rounded-full transition-[width] duration-700"
                style={{ width: `${pct}%`, background: color }}
              />
            </div>
          </li>
        )
      })}
    </ul>
  )
}
