import { useState } from 'react'
import { motion } from 'motion/react'
import { Loader2, Zap } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { generateUuidV4 } from '@/lib/utils'
import { toast } from '@/stores/toast'
import { sfx } from '@/lib/sfx'
import type { GovtTaxPolicyChange, GovtTaxTierId } from '../../data/contracts'
import { useForceCollectionMutation } from '../../data/queries/govtTax'

/* ============================================================================
   Authority Black — Policy Log + Force Collection CTA.
   The force collection button communicates weight: confirm → countdown → execute.
   ============================================================================ */

const TIER_COLORS: Record<GovtTaxTierId, string> = {
  basic: 'oklch(0.72 0.17 155)',
  standard: 'oklch(0.78 0.16 108)',
  premium: 'oklch(0.78 0.16 60)',
  elite: 'oklch(0.70 0.20 30)',
}

const TIER_LABELS: Record<GovtTaxTierId, string> = {
  basic: 'T-I',
  standard: 'T-II',
  premium: 'T-III',
  elite: 'T-IV',
}

interface Props {
  changes: GovtTaxPolicyChange[]
}

export function PolicyLog({ changes }: Props) {
  const { t } = useI18n()
  return (
    <div
      className="rounded-2xl border"
      style={{ background: 'oklch(0.07 0.010 252)', borderColor: 'oklch(0.15 0.008 252)' }}
    >
      <div className="flex flex-wrap items-center justify-between gap-3 border-b px-4 py-3" style={{ borderColor: 'oklch(0.13 0.008 252)' }}>
        <p className="text-[10px] font-semibold uppercase tracking-[0.18em]" style={{ color: 'oklch(0.42 0.008 252)' }}>
          {t('govt.tax.log.title')}
        </p>
        <ForceCollectionButton />
      </div>
      <div className="divide-y" style={{ '--tw-divide-opacity': 1 } as React.CSSProperties}>
        {changes.length === 0 ? (
          <p className="px-4 py-5 text-xs" style={{ color: 'oklch(0.42 0.008 252)' }}>{t('govt.tax.log.empty')}</p>
        ) : (
          changes.slice(0, 8).map((change, i) => (
            <PolicyChangeRow key={change.id} change={change} index={i} />
          ))
        )}
      </div>
    </div>
  )
}

function PolicyChangeRow({ change, index }: { change: GovtTaxPolicyChange; index: number }) {
  const { dateTime, relativeTime } = useI18n()
  return (
    <motion.div
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.18, delay: index * 0.04 }}
      className="px-4 py-3"
      style={{ borderColor: 'oklch(0.13 0.008 252)' }}
    >
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div className="flex flex-wrap gap-1.5">
          {change.delta.length === 0 ? (
            <span
              className="inline-flex h-5 items-center rounded-md border px-1.5 text-[10px] font-bold uppercase tracking-[0.10em]"
              style={{ borderColor: 'oklch(0.65 0.18 252 / 0.35)', background: 'oklch(0.65 0.18 252 / 0.10)', color: 'oklch(0.78 0.14 252)' }}
            >
              FORCE
            </span>
          ) : change.delta.map((d) => (
            <span
              key={d.tierId}
              className="inline-flex h-5 items-center gap-1 rounded-md border px-1.5 text-[10px] font-semibold"
              style={{
                borderColor: `${TIER_COLORS[d.tierId].replace(')', ' / 0.30)')}`,
                background: `${TIER_COLORS[d.tierId].replace(')', ' / 0.08)')}`,
                color: TIER_COLORS[d.tierId],
              }}
            >
              {TIER_LABELS[d.tierId]}
              <span style={{ color: 'oklch(0.40 0.008 252)' }}>{d.oldRate}%</span>
              <span style={{ color: 'oklch(0.55 0.008 252)' }}>→</span>
              <span>{d.newRate}%</span>
            </span>
          ))}
        </div>
        <div className="text-right">
          <p className="text-[10px]" style={{ color: 'oklch(0.55 0.008 252)' }}>
            {relativeTime(change.changedAt)}
          </p>
          <p className="text-[10px]" style={{ color: 'oklch(0.35 0.008 252)' }}>
            {dateTime(change.changedAt, { dateStyle: 'short', timeStyle: 'short' })}
          </p>
        </div>
      </div>
      <p className="mt-1.5 text-[11px] leading-relaxed" style={{ color: 'oklch(0.60 0.008 252)' }}>
        {change.reason}
      </p>
      <p className="mt-1 text-[10px] font-semibold uppercase tracking-[0.12em]" style={{ color: 'oklch(0.38 0.008 252)' }}>
        {change.operatorAlias}
      </p>
    </motion.div>
  )
}

/* ---- force collection ---------------------------------------------------- */

type FCState = 'idle' | 'confirming' | 'countdown' | 'executing'

function ForceCollectionButton() {
  const { t } = useI18n()
  const mutation = useForceCollectionMutation()
  const [state, setState] = useState<FCState>('idle')
  const [countdown, setCountdown] = useState(3)
  const [reason, setReason] = useState('')

  const startConfirm = () => {
    sfx.console_tap()
    setState('confirming')
    setReason('')
  }

  const startCountdown = () => {
    if (reason.trim().length < 8) return
    sfx.console_tap()
    setState('countdown')
    setCountdown(3)
    let n = 3
    const interval = setInterval(() => {
      n--
      if (n <= 0) {
        clearInterval(interval)
        handleExecute()
      } else {
        setCountdown(n)
      }
    }, 800)
  }

  const handleExecute = async () => {
    setState('executing')
    try {
      await mutation.mutateAsync({ reason: reason.trim(), idempotencyKey: generateUuidV4() })
      toast.success(t('govt.tax.force.toastTitle'), t('govt.tax.force.toastDescription'))
    } catch {
      toast.danger(t('govt.tax.force.toastError'), '')
    } finally {
      setState('idle')
      setReason('')
      setCountdown(3)
    }
  }

  if (state === 'idle') {
    return (
      <button
        type="button"
        onClick={startConfirm}
        className="inline-flex h-8 items-center gap-2 rounded-xl border border-[oklch(0.65_0.18_252/0.25)] bg-[oklch(0.65_0.18_252/0.08)] px-3 text-[11px] font-semibold uppercase tracking-[0.12em] text-[oklch(0.72_0.14_252)] transition-all hover:border-[oklch(0.65_0.18_252/0.45)] hover:bg-[oklch(0.65_0.18_252/0.16)]"
      >
        <Zap size={12} strokeWidth={2.4} />
        {t('govt.tax.force.button')}
      </button>
    )
  }

  if (state === 'confirming') {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.96 }}
        animate={{ opacity: 1, scale: 1 }}
        className="flex flex-wrap items-center gap-2"
      >
        <input
          type="text"
          value={reason}
          onChange={(e) => setReason(e.target.value.slice(0, 120))}
          placeholder={t('govt.tax.force.reasonPlaceholder')}
          autoFocus
          className="h-8 rounded-xl border bg-[oklch(0.06_0.008_252)] px-3 text-xs text-[oklch(0.88_0.004_252)] placeholder:text-[oklch(0.32_0.008_252)] outline-none"
          style={{ borderColor: 'oklch(0.20 0.012 252)', width: 180 }}
        />
        <button
          type="button"
          onClick={startCountdown}
          disabled={reason.trim().length < 8}
          className="inline-flex h-8 items-center gap-1.5 rounded-xl border border-[oklch(0.65_0.18_252/0.35)] bg-[oklch(0.65_0.18_252/0.12)] px-3 text-[11px] font-semibold uppercase tracking-[0.12em] text-[oklch(0.82_0.14_252)] transition-all disabled:cursor-not-allowed disabled:opacity-40 hover:bg-[oklch(0.65_0.18_252/0.22)]"
        >
          {t('govt.tax.force.confirm')}
        </button>
        <button
          type="button"
          onClick={() => setState('idle')}
          className="inline-flex h-8 items-center rounded-xl border px-3 text-[11px] uppercase tracking-[0.12em]"
          style={{ borderColor: 'oklch(0.18 0.008 252)', color: 'oklch(0.45 0.008 252)' }}
        >
          {t('govt.tax.force.cancel')}
        </button>
      </motion.div>
    )
  }

  if (state === 'countdown') {
    return (
      <div className="inline-flex h-8 items-center gap-2 rounded-xl border border-[oklch(0.65_0.18_252/0.40)] bg-[oklch(0.65_0.18_252/0.12)] px-4 text-sm font-mono font-bold text-[oklch(0.85_0.14_252)]">
        <span className="animate-pulse" aria-live="polite">{countdown}</span>
        <span className="text-[10px] font-normal uppercase tracking-[0.14em]">{t('govt.tax.force.executing')}</span>
      </div>
    )
  }

  return (
    <div className="inline-flex h-8 items-center gap-2 rounded-xl border border-[oklch(0.65_0.18_252/0.40)] px-4">
      <Loader2 size={13} className="animate-spin" style={{ color: 'oklch(0.65 0.18 252)' }} />
      <span className="text-[10px] uppercase tracking-[0.14em]" style={{ color: 'oklch(0.65 0.18 252)' }}>
        {t('govt.tax.force.executingLabel')}
      </span>
    </div>
  )
}
