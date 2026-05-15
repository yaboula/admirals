import { motion, useReducedMotion } from 'motion/react'
import { ArrowRight, CreditCard, Layers3, ShieldCheck } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import { useCardsUi } from '@/stores/cardsUi'
import { CARD_PRODUCT_LIMITS, MAX_CARDS } from './cardProducts'

export interface RequestCardBannerProps {
  cardsCount: number
  className?: string
}

export function RequestCardBanner({ cardsCount, className }: RequestCardBannerProps) {
  const { t, money } = useI18n()
  const reduced = useReducedMotion()
  const selectedCardId = useCardsUi((s) => s.selectedCardId)
  const openDialog = useCardsUi((s) => s.openDialog)
  const ctaDisabled = cardsCount >= MAX_CARDS

  const handleStart = () => {
    if (ctaDisabled) return
    sfx.panel_open()
    openDialog('issue', selectedCardId || '__new__')
  }

  return (
    <motion.div
      initial={reduced ? false : { opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.32, delay: 0.12, ease: [0.16, 1, 0.3, 1] }}
      className={cn(
        'relative overflow-hidden rounded-[1.35rem] border border-white/10 px-3.5 py-3',
        'bg-[linear-gradient(135deg,rgba(255,255,255,0.055),rgba(255,255,255,0.025))]',
        'shadow-[inset_0_1px_0_rgba(255,255,255,0.07)]',
        className,
      )}
    >
      <div aria-hidden className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_16%_0%,rgba(255,255,255,0.09),transparent_34%)]" />
      <div className="relative flex items-center gap-3">
        <div className="hidden h-11 w-11 shrink-0 items-center justify-center rounded-[1rem] border border-white/10 bg-black/[0.18] text-white/[0.68] 2xl:flex">
          {ctaDisabled ? <ShieldCheck size={18} strokeWidth={1.9} /> : <CreditCard size={18} strokeWidth={1.9} />}
        </div>

        <div className="min-w-0 flex-1">
          <div className="mb-1 flex items-center gap-2">
            <Layers3 size={11} strokeWidth={2} className="text-white/45" />
            <span className="text-[9px] font-semibold uppercase tracking-[0.18em] text-white/[0.46]">
              {t('cards.createCardBannerEyebrow')}
            </span>
          </div>
          <div className="flex min-w-0 flex-wrap items-baseline gap-x-2 gap-y-0.5">
            <span className="text-sm font-semibold tracking-[-0.03em] text-white">
              {ctaDisabled ? t('cards.createCardLimitTitle') : t('cards.createCardBannerTitle')}
            </span>
            <span className="text-[11px] font-medium text-white/[0.42]">
              {cardsCount}/{MAX_CARDS}
            </span>
          </div>
          <p className="mt-1 hidden truncate text-[11px] text-white/50 2xl:block">
            {t('cards.createCardBannerBody')
              .replace('{count}', String(cardsCount))
              .replace('{max}', String(MAX_CARDS))
              .replace('{classic}', money(CARD_PRODUCT_LIMITS.classic.issue_fee_minor / 100))
              .replace('{premium}', money(CARD_PRODUCT_LIMITS.premium.issue_fee_minor / 100))}
          </p>
        </div>

        <button
          type="button"
          onClick={handleStart}
          disabled={ctaDisabled}
          title={ctaDisabled ? t('cards.maxCardsTitle') : undefined}
          aria-label={t('cards.createCardCta')}
          className={cn(
            'relative inline-flex shrink-0 items-center gap-1.5 rounded-[0.9rem] px-3 py-2',
            'text-xs font-semibold transition-all duration-180',
            ctaDisabled ? 'cursor-not-allowed opacity-45' : 'enabled:hover:bg-white/[0.14] enabled:active:scale-[0.98]',
          )}
          style={{
            background: ctaDisabled ? 'rgba(255,255,255,0.065)' : 'rgba(255,255,255,0.095)',
            border: '1px solid rgba(255,255,255,0.13)',
            color: 'rgb(241, 243, 247)',
          }}
        >
          <span>{t('cards.createCardCta')}</span>
          <ArrowRight size={12} strokeWidth={2} />
        </button>
      </div>
    </motion.div>
  )
}
