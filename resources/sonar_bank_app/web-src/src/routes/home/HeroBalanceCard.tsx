import { useState } from 'react'
import { Eye, EyeOff, Copy, CheckCheck, ArrowDownRight, ArrowUpRight } from 'lucide-react'
import { Card } from '@/components/ui'
import { AnimatedNumber } from '@/components/vanguard/AnimatedNumber'
import type { Account, Transaction } from '@/data/contracts'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'

export interface HeroBalanceCardProps {
  account: Account | undefined
  transactions: Transaction[]
  loading?: boolean
}

/**
 * BANK-FE.2.1 hero balance card — compact, monochrome surface, balance
 * typography dominates (clamp 48-72px, tabular-nums). Orange forbidden
 * in baseline — appears only as 1px accent rule below balance.
 */
export function HeroBalanceCard({ account, transactions, loading }: HeroBalanceCardProps) {
  const [hidden, setHidden] = useState(false)
  const [copied, setCopied] = useState(false)

  const balanceMajor = account ? account.balance_minor / 100 : 0
  const savingsMajor = account ? account.savings_minor / 100 : 0

  const monthIn = sumThisMonth(transactions, account?.iban, 'in') / 100
  const monthOut = sumThisMonth(transactions, account?.iban, 'out') / 100

  const handleCopyIban = async (): Promise<void> => {
    if (!account) return
    try {
      await navigator.clipboard.writeText(account.iban.replace(/\s+/g, ''))
      setCopied(true)
      sfx.coin_clink()
      window.setTimeout(() => setCopied(false), 1600)
    } catch {
      /* clipboard denied */
    }
  }

  return (
    <Card
      variant="baseline"
      padding="none"
      className="relative overflow-hidden rounded-2xl flex flex-col"
    >
      {/* Top row — eyebrow + IBAN + reveal toggle */}
      <div className="flex items-start justify-between px-5 pt-4 pb-2">
        <div className="flex flex-col gap-1 min-w-0">
          <span className="text-[9px] uppercase tracking-[0.22em] text-text-tertiary font-medium">
            Saldo disponible
          </span>
          <button
            type="button"
            onClick={handleCopyIban}
            className="group inline-flex items-center gap-1.5 text-xs font-mono text-text-secondary hover:text-text-primary transition-colors w-fit"
            aria-label="Copiar IBAN"
          >
            <span style={{ fontVariantNumeric: 'tabular-nums', letterSpacing: '0.04em' }}>
              {account ? formatIbanMask(account.iban) : '—'}
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
          aria-label={hidden ? 'Mostrar saldo' : 'Ocultar saldo'}
          onClick={() => {
            setHidden((h) => !h)
            sfx.console_tap()
          }}
          className="tactile-button-ghost tactile-focus-ring inline-flex items-center justify-center h-8 w-8 rounded-lg shrink-0"
        >
          {hidden ? <Eye size={15} /> : <EyeOff size={15} />}
        </button>
      </div>

      {/* Balance — dominant typography */}
      <div className="px-5 pb-3 flex items-baseline gap-2">
        <span
          className="text-text-tertiary font-medium"
          style={{ fontSize: 'clamp(1.5rem, 3vw, 2rem)', lineHeight: 1 }}
        >
          €
        </span>
        {hidden ? (
          <span
            className="text-text-tertiary tracking-widest tactile-display-balance"
            style={{ fontSize: 'clamp(2.75rem, 6vw, 4.25rem)' }}
          >
            ••••••
          </span>
        ) : loading ? (
          <span
            className="tactile-skeleton h-[1em] w-56"
            style={{ height: 'clamp(2.75rem, 6vw, 4.25rem)' }}
          />
        ) : (
          <AnimatedNumber
            value={balanceMajor}
            decimals={2}
            className="tactile-display-balance text-text-primary"
            stiffness={90}
            damping={24}
          />
        )}
      </div>

      {/* Accent rule — single orange hairline (the only allowed orange touch) */}
      <div className="mx-5 h-px" style={{ background: 'var(--gradient-primary)', opacity: 0.55 }} />

      {/* Footer stats row — tight 3-column ghost pills */}
      <div className="grid grid-cols-3 gap-px bg-border-subtle/30 mt-3">
        <FooterStat
          label="Ahorro"
          value={savingsMajor}
          hidden={hidden}
          neutral
        />
        <FooterStat
          label="Ingresos · mes"
          value={monthIn}
          icon={<ArrowDownRight size={11} strokeWidth={2.6} />}
          tone="success"
          hidden={hidden}
        />
        <FooterStat
          label="Gastos · mes"
          value={monthOut}
          icon={<ArrowUpRight size={11} strokeWidth={2.6} />}
          tone="danger"
          hidden={hidden}
        />
      </div>
    </Card>
  )
}

interface FooterStatProps {
  label: string
  value: number
  icon?: React.ReactNode
  tone?: 'success' | 'danger'
  hidden: boolean
  neutral?: boolean
}

function FooterStat({ label, value, icon, tone, hidden, neutral }: FooterStatProps) {
  const color =
    neutral
      ? 'oklch(0.78 0.01 270)'
      : tone === 'success'
        ? 'oklch(0.70 0.16 155)'
        : 'oklch(0.65 0.20 25)'
  const sign = tone === 'success' ? '+' : tone === 'danger' ? '−' : ''
  return (
    <div
      className={cn(
        'flex items-center gap-2 px-4 py-2.5',
        'bg-surface-card',
      )}
    >
      {icon && (
        <span
          className="inline-flex h-5 w-5 items-center justify-center rounded shrink-0"
          style={{ background: `${color.slice(0, -1)} / 0.08)`, color }}
        >
          {icon}
        </span>
      )}
      <div className="flex flex-col leading-none gap-0.5 min-w-0">
        <span className="text-[9px] uppercase tracking-wider text-text-tertiary truncate">
          {label}
        </span>
        <span
          className="text-xs font-semibold tactile-tabular-nums truncate"
          style={{ color, fontVariantNumeric: 'tabular-nums' }}
        >
          {hidden ? '••••' : `${sign}€${formatEur(Math.abs(value))}`}
        </span>
      </div>
    </div>
  )
}

function formatEur(major: number): string {
  return new Intl.NumberFormat('es-ES', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(major)
}

function formatIbanMask(iban: string): string {
  const compact = iban.replace(/\s+/g, '')
  if (compact.length < 8) return iban
  return `${compact.slice(0, 4)} ···· ···· ${compact.slice(-4)}`
}

function sumThisMonth(
  transactions: Transaction[],
  iban: string | undefined,
  direction: 'in' | 'out',
): number {
  if (!iban) return 0
  const compact = iban.replace(/\s+/g, '')
  const startMs = new Date(new Date().getFullYear(), new Date().getMonth(), 1).getTime()
  let total = 0
  for (const t of transactions) {
    if (t.timestamp_ms < startMs) continue
    if (t.status !== 'committed') continue
    const fromCompact = t.from_iban.replace(/\s+/g, '')
    const toCompact = t.to_iban.replace(/\s+/g, '')
    if (direction === 'in' && toCompact === compact && fromCompact !== compact) {
      total += t.amount_minor
    } else if (direction === 'out' && fromCompact === compact && toCompact !== compact) {
      total += t.amount_minor
    }
  }
  return total
}
