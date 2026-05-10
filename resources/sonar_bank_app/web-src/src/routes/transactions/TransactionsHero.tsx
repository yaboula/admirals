import { useMemo, useEffect, useRef } from 'react'
import { motion, useReducedMotion } from 'motion/react'
import { TrendingUp, TrendingDown, Sigma } from 'lucide-react'
import type { Transaction, Account } from '@/data/contracts'
import { useI18n } from '@/lib/i18n'
import { Card } from '@/components/ui'
import { cn } from '@/lib/utils'
import { maskMoneyDisplay } from '@/lib/privacy'
import { usePrivacyMode } from '@/stores/privacy'

/**
 * BANK-FE.3 — Transactions Hero stats card.
 *
 * Shows three high-impact tabular figures derived from the currently-filtered
 * dataset: ingresos · gastos · neto. Each value animates from previous to new
 * value when filters mutate, providing a continuous-feel counter.
 */
export interface TransactionsHeroProps {
  transactions: Transaction[]
  account: Account | undefined
  totalCount: number
  filteredCount: number
}

export function TransactionsHero({
  transactions,
  account,
  totalCount,
  filteredCount,
}: TransactionsHeroProps) {
  const { signedMoney, t } = useI18n()
  const own = compactIban(account?.iban)
  const totals = useMemo(() => computeTotals(transactions, own), [transactions, own])
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  return (
    <Card
      variant="glass"
      padding="none"
      className="relative overflow-hidden border-white/10 rounded-[1.75rem]"
    >
      <div
        aria-hidden
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            'radial-gradient(circle at 12% 0%, rgba(255,255,255,0.06), transparent 34%), linear-gradient(180deg, rgba(255,255,255,0.03), transparent 60%)',
        }}
      />
      <div className="relative grid grid-cols-[220px_minmax(0,1fr)] gap-4 p-4 2xl:grid-cols-[260px_minmax(0,1fr)] 2xl:p-5">
        <div className="flex min-w-0 flex-col justify-between gap-4">
          <div className="flex flex-col gap-1">
            <span className="text-[10px] uppercase tracking-[0.22em] text-text-tertiary font-medium">
              Resumen del periodo
            </span>
            <h1 className="text-2xl 2xl:text-3xl font-light tracking-[-0.055em] text-text-primary">
              Transacciones
            </h1>
          </div>
          <div className="inline-flex w-fit items-center gap-2 rounded-full border border-white/10 bg-white/[0.045] px-3 py-1.5">
            <span className="text-[10px] uppercase tracking-[0.14em] text-text-tertiary">Mostrando</span>
            <span className="text-xs font-semibold text-text-primary tactile-tabular-nums">
              {filteredCount}<span className="text-text-tertiary font-normal">/{totalCount}</span>
            </span>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-3 2xl:gap-4">
          <Stat
            label={t('transactions.income')}
            icon={<TrendingUp size={14} strokeWidth={2.2} />}
            value={totals.income}
            hidden={streamerMode}
            color="rgb(78, 213, 137)"
            accentBg="rgba(53,193,119,0.1)"
            tone="positive"
            signedMoney={signedMoney}
          />
          <Stat
            label={t('transactions.expense')}
            icon={<TrendingDown size={14} strokeWidth={2.2} />}
            value={totals.expense}
            hidden={streamerMode}
            color="rgb(255, 108, 103)"
            accentBg="rgba(252,88,85,0.1)"
            tone="negative"
            signedMoney={signedMoney}
          />
          <Stat
            label={t('transactions.net')}
            icon={<Sigma size={14} strokeWidth={2.2} />}
            value={totals.net}
            hidden={streamerMode}
            color={totals.net >= 0 ? 'rgb(78, 213, 137)' : 'rgb(255, 108, 103)'}
            accentBg="rgba(255,255,255,0.06)"
            tone={totals.net >= 0 ? 'positive' : 'negative'}
            signedMoney={signedMoney}
            highlighted
          />
        </div>
      </div>
    </Card>
  )
}

interface StatProps {
  label: string
  icon: React.ReactNode
  value: number
  hidden: boolean
  color: string
  accentBg: string
  tone: 'positive' | 'negative'
  signedMoney: (value: number, options?: Intl.NumberFormatOptions) => string
  highlighted?: boolean
}

function Stat({ label, icon, value, hidden, color, accentBg, tone, signedMoney, highlighted }: StatProps) {
  const displayValue = tone === 'negative' && value > 0 ? -value : value
  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.32, ease: [0.16, 1, 0.3, 1] }}
      className={cn(
        'relative flex min-w-0 flex-col justify-between gap-3 rounded-[1.35rem] border p-3.5 2xl:p-4',
        highlighted && 'tactile-card',
      )}
      style={{
        background: highlighted ? 'rgba(255,255,255,0.06)' : 'rgba(255,255,255,0.03)',
        borderColor: highlighted ? 'rgba(255,255,255,0.12)' : 'rgba(255,255,255,0.07)',
        boxShadow: highlighted ? 'inset 0 1px 0 rgba(255,255,255,0.08)' : undefined,
      }}
    >
      <div className="flex items-center gap-2">
        <span
          className="inline-flex items-center justify-center h-7 w-7 rounded-xl"
          style={{ background: accentBg, color }}
          aria-hidden
        >
          {icon}
        </span>
        <span className="text-[10px] uppercase tracking-[0.15em] text-text-tertiary font-semibold">
          {label}
        </span>
      </div>
      <div
        className="truncate text-xl 2xl:text-2xl font-semibold tracking-[-0.045em] tactile-tabular-nums"
        style={{ color }}
      >
        {hidden ? maskMoneyDisplay() : <AnimatedAmount value={displayValue} formatter={signedMoney} />}
      </div>
    </motion.div>
  )
}

/* Smooth counter — interpolates between the previous render and the new one. */
function AnimatedAmount({ value, formatter }: { value: number; formatter: (value: number, options?: Intl.NumberFormatOptions) => string }) {
  const reduced = useReducedMotion()
  const elRef = useRef<HTMLSpanElement | null>(null)
  const prevRef = useRef<number>(value)

  useEffect(() => {
    const el = elRef.current
    if (!el) return
    if (reduced) {
      el.textContent = formatter(value)
      prevRef.current = value
      return
    }
    const start = prevRef.current
    const delta = value - start
    if (Math.abs(delta) < 0.005) {
      el.textContent = formatter(value)
      return
    }
    const duration = 480
    const t0 = performance.now()
    let raf = 0
    const tick = (t: number) => {
      const k = Math.min(1, (t - t0) / duration)
      const eased = 1 - Math.pow(1 - k, 3)
      const cur = start + delta * eased
      el.textContent = formatter(cur)
      if (k < 1) raf = requestAnimationFrame(tick)
      else prevRef.current = value
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [formatter, value, reduced])

  return (
    <>
      <span ref={elRef}>{formatter(value)}</span>
    </>
  )
}

function computeTotals(
  transactions: Transaction[],
  ownIban: string | undefined,
): { income: number; expense: number; net: number } {
  let income = 0
  let expense = 0
  for (const t of transactions) {
    if (t.status !== 'committed' && t.status !== 'pending') continue
    const fromCompact = compactIban(t.from_iban)
    const toCompact = compactIban(t.to_iban)
    const isOutgoing = ownIban
      ? fromCompact === ownIban && toCompact !== ownIban
      : t.direction === 'out'
    if (isOutgoing) expense += t.amount_minor / 100
    else income += t.amount_minor / 100
  }
  return { income, expense, net: income - expense }
}

function compactIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '')
}
