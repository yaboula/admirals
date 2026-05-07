import { useEffect, useMemo, useState } from 'react'
import { motion, AnimatePresence, useReducedMotion } from 'motion/react'
import { ArrowRight, Bitcoin, ChartNoAxesColumnIncreasing, Gem } from 'lucide-react'
import { Card } from '@/components/ui'
import { BankAvatar } from '@/components/brand/BankAvatar'
import { sfx } from '@/lib/sfx'
import { toast } from '@/stores/toast'
import { cn } from '@/lib/utils'

const SLIDES = [
  {
    title: 'Crypto custody',
    text: 'Custodia segura y compras recurrentes cuando activemos inversión digital.',
    cta: 'Ver plan',
    icon: Bitcoin,
    accent: 'oklch(0.72 0.22 40)',
  },
  {
    title: 'Investment vaults',
    text: 'Cestas de inversión simples para objetivos a medio plazo.',
    cta: 'Explorar',
    icon: ChartNoAxesColumnIncreasing,
    accent: 'oklch(0.74 0.15 150)',
  },
  {
    title: 'Premium benefits',
    text: 'Ventajas de tarjeta, límites inteligentes y recompensas en camino.',
    cta: 'Solicitar',
    icon: Gem,
    accent: 'oklch(0.78 0.14 75)',
  },
]

export function HomePromoCarousel() {
  const reduced = useReducedMotion()
  const [index, setIndex] = useState(0)
  const slide = SLIDES[index] ?? SLIDES[0]
  const avatars = useMemo(() => ['Lucía Mendoza', 'Hugo García', 'Carmen Soler'], [])

  useEffect(() => {
    if (reduced) return
    const timer = window.setInterval(() => setIndex((current) => (current + 1) % SLIDES.length), 4200)
    return () => window.clearInterval(timer)
  }, [reduced])

  const Icon = slide.icon

  return (
    <Card variant="glass" padding="none" className="relative h-full min-h-0 overflow-hidden rounded-[1.55rem] border-white/10">
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 82% 50%, oklch(0.72 0.22 40 / 0.38), transparent 38%), linear-gradient(135deg, oklch(0.20 0.07 40), oklch(0.08 0.018 35) 62%, oklch(0.045 0.010 270))',
        }}
      />
      <div
        aria-hidden
        className="absolute -right-10 bottom-[-22%] h-40 w-40 rounded-full"
        style={{
          background: 'radial-gradient(circle at 40% 35%, oklch(1 0 0 / 0.14), oklch(0.18 0.06 35 / 0.58) 44%, transparent 70%)',
          filter: 'blur(1px)',
        }}
      />
      <div className="relative h-full flex flex-col justify-between p-5">
        <AnimatePresence mode="wait">
          <motion.div
            key={slide.title}
            initial={reduced ? false : { opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={reduced ? undefined : { opacity: 0, y: -8 }}
            transition={{ duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
            className="flex flex-col gap-2"
          >
            <span
              className="inline-flex h-9 w-9 items-center justify-center rounded-2xl"
              style={{ background: 'oklch(1 0 0 / 0.10)', border: '1px solid oklch(1 0 0 / 0.14)', color: slide.accent }}
            >
              <Icon size={18} strokeWidth={2} />
            </span>
            <h3 className="max-w-[15ch] text-xl 2xl:text-2xl font-semibold leading-tight tracking-[-0.04em] text-white">
              {slide.title}
            </h3>
            <p className="max-w-[25ch] text-xs 2xl:text-sm leading-snug text-white/72">
              {slide.text}
            </p>
          </motion.div>
        </AnimatePresence>

        <div className="flex items-end justify-between gap-3">
          <div className="flex items-center -space-x-2">
            {avatars.map((name, avatarIndex) => (
              <BankAvatar key={name} name={name} size="sm" seed={avatarIndex} className="ring-2 ring-black/40" />
            ))}
            <span
              className="inline-flex h-8 w-8 items-center justify-center rounded-full text-xs font-semibold text-white ring-2 ring-black/40"
              style={{ background: 'oklch(0.72 0.22 40)' }}
            >
              +
            </span>
          </div>
          <button
            type="button"
            onClick={() => {
              sfx.console_tap()
              toast.info(slide.title, 'Esta experiencia llegará en una próxima fase.')
            }}
            className={cn(
              'inline-flex h-10 items-center justify-center gap-2 rounded-full px-5',
              'text-sm font-semibold transition-transform hover:-translate-y-0.5 active:scale-[0.98]',
            )}
            style={{ background: 'oklch(1 0 0 / 0.92)', color: 'oklch(0.08 0.01 270)' }}
          >
            {slide.cta}
            <ArrowRight size={14} strokeWidth={2} />
          </button>
        </div>
      </div>
    </Card>
  )
}
