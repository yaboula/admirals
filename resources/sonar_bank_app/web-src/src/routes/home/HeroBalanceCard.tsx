import { useEffect, useRef, useState } from 'react'
import { animate, useMotionValue, useTransform, useReducedMotion } from 'motion/react'
import { Eye, EyeOff, Copy, CheckCheck, ArrowDownRight, ArrowUpRight } from 'lucide-react'
import { Card } from '@/components/ui'
import type { Account, Transaction } from '@/data/contracts'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'
import { useI18n } from '@/lib/i18n'
import { maskIbanPanel, revealIbanDisplay } from '@/lib/privacy'
import { usePrivacyMode } from '@/stores/privacy'

export interface HeroBalanceCardProps {
  account: Account | undefined
  transactions: Transaction[]
  loading?: boolean
}

/**
 * BANK-FE.2.2 Hero Balance — Top-tier fintech detail (Revolut Metal / Apple Card grade).
 *
 *  ▸ Balance 56px weight 300 (Light), tabular-nums.
 *  ▸ Counter animation 800ms ease-out from 0 on mount/value-change.
 *  ▸ Blur-reveal toggle (filter:blur(14px) transition) — never asterisks.
 *  ▸ € sign 24px, vertically aligned to the balance baseline.
 *  ▸ NO orange accent rule below balance (eliminated).
 *  ▸ Sub-KPIs in 3 clean columns: 12px uppercase muted titles + 18px values.
 */
export function HeroBalanceCard({ account, transactions, loading }: HeroBalanceCardProps) {
  const { t } = useI18n()
  const [hidden, setHidden] = useState(false)
  const [copied, setCopied] = useState(false)
  const streamerMode = usePrivacyMode((s) => s.streamerMode)

  const balanceMajor = account ? account.balance_minor / 100 : 0
  const savingsMajor = account ? account.savings_minor / 100 : 0
  const monthIn = sumThisMonth(transactions, account?.iban, 'in') / 100
  const monthOut = sumThisMonth(transactions, account?.iban, 'out') / 100
  const hideFinancials = hidden || streamerMode

  const handleCopyIban = async (): Promise<void> => {
    if (!account) return
    try {
      await navigator.clipboard.writeText(compactIban(account.iban))
      setCopied(true)
      sfx.coin_clink()
      window.setTimeout(() => setCopied(false), 1600)
    } catch {
      /* clipboard denied */
    }
  }

  return (
    <Card
      variant="glass"
      padding="none"
      className="relative overflow-hidden rounded-2xl flex flex-col border-white/10"
    >
      {/* Header row — eyebrow + IBAN copy + reveal toggle */}
      <div className="flex items-start justify-between px-4 pt-3.5 pb-1.5 2xl:px-6 2xl:pt-5">
        <div className="flex flex-col gap-1.5 min-w-0">
          <span className="text-[10px] uppercase tracking-[0.22em] text-text-tertiary font-medium">
            {t('home.availableBalance')}
          </span>
          <button
            type="button"
            onClick={handleCopyIban}
            className="group inline-flex items-center gap-1.5 text-xs font-mono text-text-secondary hover:text-text-primary transition-colors w-fit"
            aria-label={t('home.copyIban')}
          >
            <span style={{ fontVariantNumeric: 'tabular-nums', letterSpacing: '0.04em' }}>
              {account ? streamerMode ? maskIbanPanel(account.iban) : revealIbanDisplay(account.iban) : '—'}
            </span>
            {copied ? (
              <CheckCheck size={11} className="text-semantic-success-deep" />
            ) : (
              <Copy size={11} className="opacity-0 group-hover:opacity-100 transition-opacity" />
            )}
          </button>
        </div>

        <button
          type="button"
          aria-label={hideFinancials ? t('home.showBalance') : t('home.hideBalance')}
          aria-pressed={hideFinancials}
          onClick={() => {
            setHidden((h) => !h)
            sfx.console_tap()
          }}
          className="tactile-button-ghost tactile-focus-ring inline-flex items-center justify-center h-8 w-8 rounded-lg shrink-0"
        >
          {hideFinancials ? <Eye size={15} /> : <EyeOff size={15} />}
        </button>
      </div>

      {/* Balance — 56px Light + tabular-nums + blur-reveal */}
      <div className="px-4 pb-3.5 2xl:px-6 2xl:pb-5">
        <BalanceDisplay value={balanceMajor} hidden={hideFinancials} loading={loading} />
      </div>

      {/* Footer — 3-column sub-KPI grid (no compression) */}
      <div className="grid grid-cols-3 border-t border-border-subtle">
        <SubKpi label={t('home.savings')} value={savingsMajor} hidden={hideFinancials} tone="neutral" />
        <SubKpi
          label={t('home.incomeMonth')}
          value={monthIn}
          hidden={hideFinancials}
          tone="success"
          icon={<ArrowDownRight size={12} strokeWidth={2.4} />}
        />
        <SubKpi
          label={t('home.expenseMonth')}
          value={monthOut}
          hidden={hideFinancials}
          tone="danger"
          icon={<ArrowUpRight size={12} strokeWidth={2.4} />}
        />
      </div>
    </Card>
  )
}

/* --------------------------------------------------------------------------
   BalanceDisplay — counter (0 → value, 800ms ease-out) + blur-reveal toggle
   -------------------------------------------------------------------------- */

function BalanceDisplay({
  value,
  hidden,
  loading,
}: {
  value: number
  hidden: boolean
  loading: boolean | undefined
}) {
  const { money, currencySymbol, t } = useI18n()
  const reduced = useReducedMotion()
  const motionValue = useMotionValue(0)
  const formatted = useTransform(motionValue, (latest) => String(money(latest) ?? '').replace(String(currencySymbol ?? ''), '').trim())
  const [display, setDisplay] = useState('0.00')
  const lastTargetRef = useRef<number>(0)

  useEffect(() => {
    const unsub = formatted.on('change', (v) => setDisplay(v))
    return unsub
  }, [formatted])

  useEffect(() => {
    if (loading) return
    const previous = lastTargetRef.current
    lastTargetRef.current = value

    if (reduced) {
      motionValue.set(value)
      return
    }

    // First mount → animate from 0. Subsequent updates → animate from previous.
    const from = previous === 0 && value !== 0 ? 0 : motionValue.get()
    motionValue.set(from)

    const controls = animate(motionValue, value, {
      duration: 0.8,
      ease: [0.16, 1, 0.3, 1],
    })
    return () => controls.stop()
  }, [value, loading, motionValue, reduced])

  if (loading) {
    return (
      <div className="flex items-baseline gap-2">
        <span className="text-text-tertiary font-light" style={{ fontSize: '24px' }}>
          {currencySymbol}
        </span>
        <span
          className="tactile-skeleton rounded"
          style={{ height: '56px', width: '14ch', display: 'inline-block' }}
        />
      </div>
    )
  }

  return (
    <div
      className="flex items-baseline gap-2"
      aria-live="polite"
      aria-atomic
      aria-label={hidden ? t('home.balanceHidden') : `${t('home.availableBalance')} ${money(value)}`}
    >
      <span
        className="text-text-tertiary font-light leading-none"
        style={{ fontSize: '24px', lineHeight: 1 }}
      >
        {currencySymbol}
      </span>
      <span
        className="text-text-primary leading-none"
        style={{
          fontSize: '56px',
          fontWeight: 300,
          letterSpacing: '-0.02em',
          fontVariantNumeric: 'tabular-nums lining-nums',
          fontVariationSettings: '"wght" 300, "opsz" 32',
          filter: hidden ? 'blur(14px)' : 'blur(0px)',
          transition: 'filter 360ms cubic-bezier(0.16, 1, 0.3, 1)',
          userSelect: hidden ? 'none' : 'text',
        }}
      >
        {display}
      </span>
    </div>
  )
}

/* --------------------------------------------------------------------------
   SubKpi — 3-column premium ghost cell (12px title + 18px value)
   -------------------------------------------------------------------------- */

interface SubKpiProps {
  label: string
  value: number
  hidden: boolean
  tone: 'neutral' | 'success' | 'danger'
  icon?: React.ReactNode
}

function SubKpi({ label, value, hidden, tone, icon }: SubKpiProps) {
  const { money } = useI18n()
  const color =
    tone === 'success'
      ? 'rgb(53, 193, 119)'
      : tone === 'danger'
        ? 'rgb(252, 88, 85)'
        : 'rgb(227, 228, 232)'
  const sign = tone === 'success' ? '+' : tone === 'danger' ? '−' : ''

  return (
    <div
      className={cn(
        'flex flex-col gap-1.5 px-5 py-4',
        'border-r border-border-subtle last:border-r-0',
      )}
    >
      <div className="flex items-center gap-1.5">
        {icon && (
          <span
            className="inline-flex h-4 w-4 items-center justify-center rounded shrink-0"
            style={{
              background: tone === 'success'
                ? 'rgba(53,193,119,0.1)'
                : tone === 'danger'
                  ? 'rgba(252,88,85,0.1)'
                  : 'transparent',
              color,
            }}
          >
            {icon}
          </span>
        )}
        <span
          className="uppercase font-medium text-text-tertiary"
          style={{ fontSize: '12px', letterSpacing: '0.08em' }}
        >
          {label}
        </span>
      </div>
      <span
        className="font-semibold leading-none"
        style={{
          fontSize: '18px',
          color,
          fontVariantNumeric: 'tabular-nums lining-nums',
          filter: hidden ? 'blur(8px)' : 'blur(0px)',
          transition: 'filter 320ms cubic-bezier(0.16, 1, 0.3, 1)',
          userSelect: hidden ? 'none' : 'text',
        }}
      >
        {sign}{money(Math.abs(value))}
      </span>
    </div>
  )
}

function sumThisMonth(
  transactions: Transaction[],
  iban: string | undefined,
  direction: 'in' | 'out',
): number {
  if (!iban) return 0
  const compact = compactIban(iban)
  const startMs = new Date(new Date().getFullYear(), new Date().getMonth(), 1).getTime()
  let total = 0
  for (const t of transactions) {
    if (t.timestamp_ms < startMs) continue
    if (t.status !== 'committed') continue
    const fromCompact = compactIban(t.from_iban)
    const toCompact = compactIban(t.to_iban)
    if (direction === 'in' && toCompact === compact && fromCompact !== compact) {
      total += t.amount_minor
    } else if (direction === 'out' && fromCompact === compact && toCompact !== compact) {
      total += t.amount_minor
    }
  }
  return total
}

function compactIban(value: string | undefined | null): string {
  return String(value ?? '').replace(/\s+/g, '')
}
