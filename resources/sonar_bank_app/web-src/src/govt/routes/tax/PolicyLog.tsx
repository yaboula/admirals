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
  basic: 'rgb(34, 195, 115)',
  standard: 'rgb(194, 190, 35)',
  premium: 'rgb(255, 156, 59)',
  elite: 'rgb(255, 97, 77)',
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
      style={{ background: 'rgb(1, 1, 2)', borderColor: 'rgb(9, 11, 14)' }}
    >
      <div className="flex flex-wrap items-center justify-between gap-3 border-b px-4 py-3" style={{ borderColor: 'rgb(5, 7, 10)' }}>
        <p className="text-[10px] font-semibold uppercase tracking-[0.18em]" style={{ color: 'rgb(74, 77, 81)' }}>
          {t('govt.tax.log.title')}
        </p>
        <ForceCollectionButton />
      </div>
      <div className="divide-y" style={{ '--tw-divide-opacity': 1 } as React.CSSProperties}>
        {changes.length === 0 ? (
          <p className="px-4 py-5 text-xs" style={{ color: 'rgb(74, 77, 81)' }}>{t('govt.tax.log.empty')}</p>
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
      style={{ borderColor: 'rgb(5, 7, 10)' }}
    >
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div className="flex flex-wrap gap-1.5">
          {change.delta.length === 0 ? (
            <span
              className="inline-flex h-5 items-center rounded-md border px-1.5 text-[10px] font-bold uppercase tracking-[0.10em]"
              style={{ borderColor: 'rgba(34,145,248,0.35)', background: 'rgba(34,145,248,0.1)', color: 'rgb(113, 188, 255)' }}
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
              <span style={{ color: 'rgb(69, 72, 76)' }}>{d.oldRate}%</span>
              <span style={{ color: 'rgb(110, 114, 118)' }}>→</span>
              <span>{d.newRate}%</span>
            </span>
          ))}
        </div>
        <div className="text-right">
          <p className="text-[10px]" style={{ color: 'rgb(110, 114, 118)' }}>
            {relativeTime(change.changedAt)}
          </p>
          <p className="text-[10px]" style={{ color: 'rgb(56, 59, 63)' }}>
            {dateTime(change.changedAt, { dateStyle: 'short', timeStyle: 'short' })}
          </p>
        </div>
      </div>
      <p className="mt-1.5 text-[11px] leading-relaxed" style={{ color: 'rgb(125, 129, 133)' }}>
        {change.reason}
      </p>
      <p className="mt-1 text-[10px] font-semibold uppercase tracking-[0.12em]" style={{ color: 'rgb(63, 67, 71)' }}>
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
        className="inline-flex h-8 items-center gap-2 rounded-xl border border-[rgba(34,145,248,0.25)] bg-[rgba(34,145,248,0.08)] px-3 text-[11px] font-semibold uppercase tracking-[0.12em] text-[rgb(94, 168, 249)] transition-all hover:border-[rgba(34,145,248,0.45)] hover:bg-[rgba(34,145,248,0.16)]"
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
          className="h-8 rounded-xl border bg-[rgb(0, 1, 1)] px-3 text-xs text-[rgb(214, 216, 218)] placeholder:text-[rgb(48, 51, 55)] outline-none"
          style={{ borderColor: 'rgb(18, 22, 27)', width: 180 }}
        />
        <button
          type="button"
          onClick={startCountdown}
          disabled={reason.trim().length < 8}
          className="inline-flex h-8 items-center gap-1.5 rounded-xl border border-[rgba(34,145,248,0.35)] bg-[rgba(34,145,248,0.12)] px-3 text-[11px] font-semibold uppercase tracking-[0.12em] text-[rgb(126, 201, 255)] transition-all disabled:cursor-not-allowed disabled:opacity-40 hover:bg-[rgba(34,145,248,0.22)]"
        >
          {t('govt.tax.force.confirm')}
        </button>
        <button
          type="button"
          onClick={() => setState('idle')}
          className="inline-flex h-8 items-center rounded-xl border px-3 text-[11px] uppercase tracking-[0.12em]"
          style={{ borderColor: 'rgb(15, 18, 21)', color: 'rgb(82, 86, 90)' }}
        >
          {t('govt.tax.force.cancel')}
        </button>
      </motion.div>
    )
  }

  if (state === 'countdown') {
    return (
      <div className="inline-flex h-8 items-center gap-2 rounded-xl border border-[rgba(34,145,248,0.4)] bg-[rgba(34,145,248,0.12)] px-4 text-sm font-mono font-bold text-[rgb(135, 211, 255)]">
        <span className="animate-pulse" aria-live="polite">{countdown}</span>
        <span className="text-[10px] font-normal uppercase tracking-[0.14em]">{t('govt.tax.force.executing')}</span>
      </div>
    )
  }

  return (
    <div className="inline-flex h-8 items-center gap-2 rounded-xl border border-[rgba(34,145,248,0.4)] px-4">
      <Loader2 size={13} className="animate-spin" style={{ color: 'rgb(34, 145, 248)' }} />
      <span className="text-[10px] uppercase tracking-[0.14em]" style={{ color: 'rgb(34, 145, 248)' }}>
        {t('govt.tax.force.executingLabel')}
      </span>
    </div>
  )
}
