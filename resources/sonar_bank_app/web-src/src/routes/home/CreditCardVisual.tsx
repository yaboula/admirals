import { useState } from 'react'
import { motion, useReducedMotion } from 'motion/react'
import { Eye, EyeOff, Wifi } from 'lucide-react'
import { cn } from '@/lib/utils'
import { sfx } from '@/lib/sfx'
import type { Account } from '@/data/contracts'

export interface CreditCardVisualProps {
  account: Account | undefined
  holderName?: string
  brand?: 'sonar' | 'visa' | 'mastercard'
  className?: string
}

/**
 * Premium credit-card visual — glassmorphism, animated chip + contactless,
 * masked PAN derived from IBAN tail, holder name, expiry placeholder.
 *
 * Strict palette discipline: no orange in baseline state. Card surface uses
 * a graphite gradient with brand chrome accents only.
 */
export function CreditCardVisual({
  account,
  holderName = 'CITIZEN',
  brand = 'sonar',
  className,
}: CreditCardVisualProps) {
  const reduced = useReducedMotion()
  const [revealed, setRevealed] = useState(false)

  const tail = account ? account.iban.replace(/\s+/g, '').slice(-4) : '0000'
  const mid = account ? account.iban.replace(/\s+/g, '').slice(-8, -4) : '0000'
  const masked = revealed ? `4287 ${mid} ${tail}` : `4287 ···· ···· ${tail}`

  const issuedDate = account ? new Date(account.created_ms) : new Date()
  const expiry = new Date(issuedDate)
  expiry.setFullYear(expiry.getFullYear() + 4)
  const expiryStr = `${String(expiry.getMonth() + 1).padStart(2, '0')}/${String(expiry.getFullYear()).slice(-2)}`

  return (
    <div className={cn('relative w-full', className)}>
      <motion.div
        initial={reduced ? false : { opacity: 0, y: 12, rotateX: -6 }}
        animate={{ opacity: 1, y: 0, rotateX: 0 }}
        transition={{ type: 'spring', stiffness: 220, damping: 22, mass: 0.9 }}
        className="relative aspect-[1.586/1] w-full overflow-hidden rounded-2xl text-text-primary"
        style={{
          background:
            'linear-gradient(135deg, oklch(0.16 0.012 270) 0%, oklch(0.10 0.010 270) 50%, oklch(0.06 0.008 270) 100%)',
          border: '1px solid oklch(1 0 0 / 0.08)',
          boxShadow:
            '0 24px 48px -16px oklch(0 0 0 / 0.6), 0 8px 16px -4px oklch(0 0 0 / 0.4), inset 0 1px 0 oklch(1 0 0 / 0.06), inset 0 -1px 0 oklch(0 0 0 / 0.4)',
        }}
      >
        {/* Holographic ribbon — diagonal sweep */}
        <div
          aria-hidden
          className="absolute inset-0 pointer-events-none opacity-40"
          style={{
            background:
              'linear-gradient(115deg, transparent 0%, transparent 35%, oklch(1 0 0 / 0.07) 50%, transparent 65%, transparent 100%)',
          }}
        />

        {/* V1 aesthetic — warm orange corner luminary (founder mandate FE.2.3).
           Creates the Revolut Metal "black card with orange heartbeat" feel. */}
        <div
          aria-hidden
          className="absolute pointer-events-none"
          style={{
            top: '-25%',
            right: '-15%',
            width: '80%',
            height: '130%',
            background:
              'radial-gradient(circle at 60% 50%, oklch(0.65 0.22 40 / 0.26), transparent 60%)',
            filter: 'blur(22px)',
          }}
        />
        {/* Bottom-left cool counter-orb for subtle chromatic balance */}
        <div
          aria-hidden
          className="absolute pointer-events-none"
          style={{
            bottom: '-20%',
            left: '-10%',
            width: '55%',
            height: '80%',
            background:
              'radial-gradient(circle at 40% 50%, oklch(0.50 0.06 240 / 0.10), transparent 65%)',
            filter: 'blur(24px)',
          }}
        />

        <div className="relative h-full flex flex-col justify-between p-4 lg:p-5">
          {/* Top row — brand mark + contactless */}
          <div className="flex items-start justify-between">
            <div className="flex flex-col leading-none">
              <span className="text-[8px] uppercase tracking-[0.32em] text-text-tertiary font-semibold">
                SONAR
              </span>
              <span className="text-base font-bold tracking-tight tactile-wght-breathing">
                Bank
              </span>
            </div>
            <Wifi
              size={18}
              strokeWidth={2}
              className="text-text-secondary rotate-90 opacity-80"
            />
          </div>

          {/* Center — chip + brand network */}
          <div className="flex items-center gap-3">
            <Chip />
            <BrandMark brand={brand} />
          </div>

          {/* Bottom — masked PAN, holder, expiry */}
          <div className="flex items-end justify-between gap-3">
            <div className="flex flex-col gap-1.5 min-w-0 flex-1">
              <button
                type="button"
                onClick={() => {
                  setRevealed((r) => !r)
                  sfx.console_tap()
                }}
                className="group flex items-center gap-2 text-text-primary"
                aria-label={revealed ? 'Ocultar número de tarjeta' : 'Revelar número de tarjeta'}
              >
                <span
                  className="text-base lg:text-lg font-mono font-medium tracking-wider tactile-tabular-nums"
                  style={{ fontVariantNumeric: 'tabular-nums', letterSpacing: '0.08em' }}
                >
                  {masked}
                </span>
                {revealed ? (
                  <EyeOff size={12} className="text-text-tertiary opacity-0 group-hover:opacity-100 transition-opacity" />
                ) : (
                  <Eye size={12} className="text-text-tertiary opacity-0 group-hover:opacity-100 transition-opacity" />
                )}
              </button>
              <div className="flex items-end gap-4 leading-none">
                <div className="flex flex-col gap-0.5">
                  <span className="text-[8px] uppercase tracking-wider text-text-tertiary">
                    Titular
                  </span>
                  <span className="text-xs font-semibold tracking-wide truncate max-w-[18ch]">
                    {holderName}
                  </span>
                </div>
                <div className="flex flex-col gap-0.5">
                  <span className="text-[8px] uppercase tracking-wider text-text-tertiary">
                    Caduca
                  </span>
                  <span className="text-xs font-semibold tracking-wide tactile-tabular-nums">
                    {expiryStr}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  )
}

/**
 * Chip — multi-pad EMV-style. Uses CSS gradient + rounded sub-shapes
 * to evoke the gold pad layout without bitmap assets.
 */
function Chip() {
  return (
    <div
      aria-hidden
      className="relative h-7 w-9 rounded-md overflow-hidden shrink-0"
      style={{
        background:
          'linear-gradient(135deg, oklch(0.78 0.12 85) 0%, oklch(0.62 0.10 75) 50%, oklch(0.45 0.06 70) 100%)',
        boxShadow:
          'inset 0 1px 0 oklch(1 0 0 / 0.4), inset 0 -1px 0 oklch(0 0 0 / 0.4), 0 2px 4px oklch(0 0 0 / 0.4)',
      }}
    >
      {/* contact pads grid */}
      <div className="absolute inset-1 grid grid-cols-2 grid-rows-3 gap-px">
        {Array.from({ length: 6 }).map((_, i) => (
          <div
            key={i}
            style={{
              background: 'oklch(0.30 0.04 70 / 0.55)',
              borderRadius: '1px',
            }}
          />
        ))}
      </div>
      {/* central horizontal bar */}
      <div
        className="absolute left-0 right-0"
        style={{
          top: '50%',
          height: '1px',
          background: 'oklch(0.30 0.04 70 / 0.7)',
        }}
      />
    </div>
  )
}

function BrandMark({ brand }: { brand: 'sonar' | 'visa' | 'mastercard' }) {
  if (brand === 'sonar') {
    return (
      <div className="flex items-center gap-1 leading-none">
        <span className="text-[10px] uppercase tracking-[0.3em] text-text-tertiary font-semibold">
          SNR
        </span>
        <span className="inline-block w-1 h-1 rounded-full bg-brand-signal-orange-light opacity-70" />
      </div>
    )
  }
  return null
}
