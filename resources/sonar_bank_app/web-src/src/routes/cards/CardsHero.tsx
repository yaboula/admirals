import { motion } from 'motion/react'
import { CreditCard } from 'lucide-react'
import { useI18n } from '@/lib/i18n'

/**
 * BANK-FE.4.2 — CardsHero
 *
 * Top strip of the /tarjetas route. Mirrors the visual rhythm of
 * TransactionsHero but pares the content down: title + total count + small
 * supportive caption. The list/CTA actions land in Phase 4.3 alongside the
 * action buttons; for Phase 4.2 we keep this surface intentionally calm so
 * the carousel underneath gets the spotlight.
 */
export interface CardsHeroProps {
  totalCount: number
  activeCount: number
}

export function CardsHero({ totalCount, activeCount }: CardsHeroProps) {
  const { t } = useI18n()
  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.34, ease: [0.16, 1, 0.3, 1] }}
      className="flex items-center justify-between gap-4 px-1 py-1"
    >
      <div className="flex items-center gap-3 min-w-0">
        <div
          className="inline-flex items-center justify-center h-9 w-9 rounded-xl shrink-0"
          style={{
            background: 'oklch(1 0 0 / 0.04)',
            border: '1px solid oklch(1 0 0 / 0.10)',
          }}
        >
          <CreditCard size={16} strokeWidth={1.7} className="text-text-secondary" />
        </div>
        <div className="flex flex-col leading-tight min-w-0">
          <span className="text-[10px] uppercase tracking-[0.18em] text-text-tertiary font-medium">
            {t('cards.myCards')}
          </span>
          <h1 className="text-base 2xl:text-lg font-semibold text-text-primary tactile-wght-breathing tracking-tight truncate">
            {totalCount > 0 ? labelFor(totalCount, activeCount, (key: string) => t(key as any)) : t('cards.requestFirstCard')}
          </h1>
        </div>
      </div>

      {totalCount > 0 && (
        <div className="hidden sm:flex items-center gap-2 shrink-0">
          <Pill label={`${activeCount} ${t('cards.active')}`} tone="active" />
          {totalCount - activeCount > 0 && (
            <Pill label={`${totalCount - activeCount} ${t('cards.frozen')}`} tone="muted" />
          )}
        </div>
      )}
    </motion.div>
  )
}

function labelFor(total: number, active: number, t: (key: string) => string): string {
  if (total === 1) return active === 1 ? t('cards.oneActiveCard') : t('cards.oneCard')
  return t('cards.multipleCards').replace('{count}', String(total))
}

function Pill({ label, tone }: { label: string; tone: 'active' | 'muted' }) {
  return (
    <span
      className="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-[10px] uppercase tracking-[0.14em] font-semibold"
      style={{
        color: tone === 'active' ? 'oklch(0.92 0.01 270)' : 'oklch(0.65 0.01 270)',
        background: 'oklch(1 0 0 / 0.04)',
        border: '1px solid oklch(1 0 0 / 0.10)',
      }}
    >
      <span
        aria-hidden
        className="h-1.5 w-1.5 rounded-full"
        style={{
          background:
            tone === 'active'
              ? 'oklch(0.78 0.16 150)'
              : 'oklch(0.55 0.01 270)',
        }}
      />
      {label}
    </span>
  )
}
