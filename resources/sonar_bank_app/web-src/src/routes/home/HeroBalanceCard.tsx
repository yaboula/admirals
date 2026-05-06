import { useState } from 'react'
import { motion } from 'motion/react'
import {
  Eye,
  EyeOff,
  ArrowDownRight,
  ArrowUpRight,
  Sparkles,
  Copy,
  CheckCheck,
} from 'lucide-react'
import { Card } from '@/components/ui'
import { AnimatedNumber } from '@/components/vanguard/AnimatedNumber'
import { MagicSpotlight } from '@/components/vanguard/MagicSpotlight'
import { TactileTilt } from '@/components/vanguard/TactileTilt'
import { ConicEdge } from '@/components/vanguard/ConicEdge'
import type { Account, Transaction } from '@/data/contracts'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'

export interface HeroBalanceCardProps {
  account: Account | undefined
  transactions: Transaction[]
  loading?: boolean
}

export function HeroBalanceCard({ account, transactions, loading }: HeroBalanceCardProps) {
  const [hidden, setHidden] = useState(false)
  const [copied, setCopied] = useState(false)

  const balanceMajor = account ? account.balance_minor / 100 : 0
  const savingsMajor = account ? account.savings_minor / 100 : 0

  const monthIn = sumThisMonth(transactions, account?.iban, 'in')
  const monthOut = sumThisMonth(transactions, account?.iban, 'out')
  const delta = monthIn - monthOut
  const positive = delta >= 0

  const handleHideToggle = (): void => {
    setHidden((h) => {
      if (!h) sfx.layer_dive()
      else sfx.signal_emerge()
      return !h
    })
  }

  const handleCopyIban = async (): Promise<void> => {
    if (!account) return
    try {
      await navigator.clipboard.writeText(account.iban.replace(/\s+/g, ''))
      setCopied(true)
      sfx.coin_clink()
      window.setTimeout(() => setCopied(false), 1600)
    } catch {
      /* clipboard denied — ignore */
    }
  }

  return (
    <TactileTilt max={4} className="w-full">
      <ConicEdge>
        <MagicSpotlight intensity={1}>
          <Card
            variant="glass"
            padding="none"
            hero
            className="relative overflow-hidden rounded-2xl"
          >
            {/* Hero background gradient — diffuse top glow */}
            <div
              aria-hidden
              className="absolute inset-0 pointer-events-none opacity-90"
              style={{
                background:
                  'radial-gradient(ellipse 90% 60% at 50% -10%, oklch(0.65 0.22 40 / 0.20), transparent 60%), radial-gradient(ellipse 60% 70% at 110% 110%, oklch(0.55 0.20 350 / 0.10), transparent 70%)',
              }}
            />

            <div className="relative p-7 lg:p-9 flex flex-col gap-7 min-h-[260px]">
              {/* Header row */}
              <div className="flex items-start justify-between gap-4">
                <div className="flex flex-col gap-1.5 min-w-0">
                  <div className="flex items-center gap-2 text-[10px] uppercase tracking-[0.22em] font-medium text-text-tertiary">
                    <Sparkles size={11} strokeWidth={2} className="text-brand-signal-orange-light" />
                    Saldo disponible
                  </div>
                  <button
                    type="button"
                    onClick={handleCopyIban}
                    className={cn(
                      'group inline-flex items-center gap-2 text-xs font-mono text-text-secondary',
                      'hover:text-text-primary transition-colors w-fit',
                    )}
                    aria-label="Copiar IBAN"
                  >
                    <span className="tactile-tabular-nums tracking-tight">
                      {account ? formatIbanMask(account.iban) : '—'}
                    </span>
                    {copied ? (
                      <CheckCheck size={12} className="text-semantic-success-deep" />
                    ) : (
                      <Copy
                        size={12}
                        className="opacity-0 group-hover:opacity-100 transition-opacity"
                      />
                    )}
                  </button>
                </div>

                <button
                  type="button"
                  aria-label={hidden ? 'Mostrar saldo' : 'Ocultar saldo'}
                  onClick={handleHideToggle}
                  className={cn(
                    'tactile-button-secondary tactile-focus-ring inline-flex items-center justify-center h-10 w-10 rounded-xl',
                    'shrink-0',
                  )}
                >
                  {hidden ? <Eye size={18} /> : <EyeOff size={18} />}
                </button>
              </div>

              {/* Balance display */}
              <div className="flex flex-col gap-2">
                <div className="flex items-baseline gap-2 tactile-display-balance text-[clamp(2.5rem,6vw,4.5rem)]">
                  <span className="text-text-tertiary text-[0.55em] font-medium">€</span>
                  {hidden ? (
                    <span className="text-text-tertiary tracking-widest">••••••</span>
                  ) : loading ? (
                    <span className="tactile-skeleton h-[1em] w-64" />
                  ) : (
                    <AnimatedNumber value={balanceMajor} decimals={2} className="text-text-primary" />
                  )}
                </div>

                <div className="flex flex-wrap items-center gap-3 text-xs">
                  <span className="text-text-tertiary uppercase tracking-wider font-medium">
                    Cuenta principal
                  </span>
                  <span className="h-3 w-px bg-border-medium" />
                  <span className="text-text-tertiary">
                    Ahorro:{' '}
                    <span className="text-text-secondary tactile-tabular-nums">
                      {hidden ? '••••' : formatEur(savingsMajor)}
                    </span>
                  </span>
                </div>
              </div>

              {/* Stats row */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mt-auto">
                <StatPill
                  label="Ingresos del mes"
                  value={monthIn / 100}
                  icon={<ArrowDownRight size={14} strokeWidth={2.4} />}
                  tone="success"
                  hidden={hidden}
                />
                <StatPill
                  label="Gastos del mes"
                  value={monthOut / 100}
                  icon={<ArrowUpRight size={14} strokeWidth={2.4} />}
                  tone="danger"
                  hidden={hidden}
                />
                <StatPill
                  label="Balance neto"
                  value={delta / 100}
                  icon={
                    <motion.span
                      animate={{ rotate: positive ? 0 : 180 }}
                      transition={{ type: 'spring', stiffness: 220, damping: 20 }}
                      className="inline-flex"
                    >
                      <ArrowDownRight size={14} strokeWidth={2.4} />
                    </motion.span>
                  }
                  tone={positive ? 'success' : 'danger'}
                  hidden={hidden}
                  highlighted
                />
              </div>
            </div>
          </Card>
        </MagicSpotlight>
      </ConicEdge>
    </TactileTilt>
  )
}

interface StatPillProps {
  label: string
  value: number
  icon: React.ReactNode
  tone: 'success' | 'danger'
  hidden: boolean
  highlighted?: boolean
}

function StatPill({ label, value, icon, tone, hidden, highlighted }: StatPillProps) {
  const color = tone === 'success' ? 'oklch(0.65 0.18 155)' : 'oklch(0.62 0.21 25)'
  return (
    <div
      className={cn(
        'flex items-center gap-3 rounded-xl px-3.5 py-3',
        'border border-border-subtle',
        highlighted && 'tactile-card-elevated',
      )}
      style={{
        background: highlighted ? undefined : 'oklch(0 0 0 / 0.20)',
      }}
    >
      <span
        className="inline-flex h-7 w-7 items-center justify-center rounded-lg shrink-0"
        style={{ background: `${color} / 0.12`, color }}
      >
        {icon}
      </span>
      <div className="flex flex-col min-w-0 leading-tight">
        <span className="text-[10px] uppercase tracking-wider text-text-tertiary truncate">{label}</span>
        <span className="text-sm font-semibold text-text-primary tactile-tabular-nums">
          {hidden ? '••••' : formatEurSigned(value, tone === 'success' ? '+' : tone === 'danger' ? '−' : '')}
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

function formatEurSigned(major: number, sign: string): string {
  const abs = Math.abs(major)
  return `${sign}€${formatEur(abs)}`
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
