import { useEffect, useState } from 'react'
import { motion } from 'motion/react'
import { ArrowRight, Check, Loader2, RotateCcw } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { generateUuidV4 } from '@/lib/utils'
import { cn } from '@/lib/utils'
import { toast } from '@/stores/toast'
import { sfx } from '@/lib/sfx'
import type { GovtTaxBracket, GovtTaxTierId } from '../../data/contracts'
import { useSaveBracketsMutation } from '../../data/queries/govtTax'

/* ============================================================================
   Authority Black: bracket editor with drag sliders.
   Design intent: monetary policy instrument, not a form.
   ============================================================================ */

const RATE_MIN = 1
const RATE_MAX = 60
const REASON_MIN = 12

const TIER_COLORS: Record<GovtTaxTierId, string> = {
  basic: 'oklch(0.72 0.17 155)',
  standard: 'oklch(0.78 0.16 108)',
  premium: 'oklch(0.78 0.16 60)',
  elite: 'oklch(0.70 0.20 30)',
}

interface Props {
  brackets: GovtTaxBracket[]
  onDraftChange?: (draft: Map<GovtTaxTierId, number>) => void
}

export function BracketEditor({ brackets, onDraftChange }: Props) {
  const { t, money } = useI18n()
  const mutation = useSaveBracketsMutation()

  const [draft, setDraft] = useState<Map<GovtTaxTierId, number>>(() =>
    new Map(brackets.map((b) => [b.id, b.rate])),
  )
  const [reason, setReason] = useState('')
  const [showReason, setShowReason] = useState(false)

  useEffect(() => {
    setDraft(new Map(brackets.map((b) => [b.id, b.rate])))
  }, [brackets])

  const dirty = brackets.some((b) => draft.get(b.id) !== b.rate)
  const reasonValid = reason.trim().length >= REASON_MIN
  const canSave = dirty && reasonValid && !mutation.isPending

  const handleRateChange = (id: GovtTaxTierId, value: number) => {
    const next = new Map(draft)
    next.set(id, value)
    setDraft(next)
    onDraftChange?.(next)
  }

  const handleSave = async () => {
    if (!canSave) return
    sfx.console_tap()
    try {
      await mutation.mutateAsync({
        brackets: brackets.map((b) => ({ id: b.id, rate: draft.get(b.id) ?? b.rate })),
        reason: reason.trim(),
        idempotencyKey: generateUuidV4(),
      })
      toast.success(t('govt.tax.toast.saveTitle'), t('govt.tax.toast.saveDescription'))
      setShowReason(false)
      setReason('')
    } catch {
      toast.danger(t('govt.tax.toast.saveError'), '')
    }
  }

  const handleRevert = () => {
    sfx.console_tap()
    setDraft(new Map(brackets.map((b) => [b.id, b.rate])))
    setShowReason(false)
    setReason('')
    onDraftChange?.(new Map(brackets.map((b) => [b.id, b.rate])))
  }

  const estimatedRevenueDelta = brackets.reduce((acc, b) => {
    const oldRate = b.rate
    const newRate = draft.get(b.id) ?? oldRate
    return acc + (newRate - oldRate) * b.affectedCount * 50_000
  }, 0)

  return (
    <div className="flex h-full flex-col">
      <div className="space-y-1">
        {brackets.map((bracket, i) => (
          <BracketRow
            key={bracket.id}
            bracket={bracket}
            currentRate={draft.get(bracket.id) ?? bracket.rate}
            color={TIER_COLORS[bracket.id]}
            index={i}
            onChange={(v) => handleRateChange(bracket.id, v)}
            disabled={mutation.isPending}
          />
        ))}
      </div>

      {dirty ? (
        <motion.div
          initial={{ opacity: 0, y: 6 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2 }}
          className="mt-4 space-y-3"
        >
          {estimatedRevenueDelta !== 0 ? (
            <div
              className="flex items-center gap-2 rounded-xl border px-3 py-2 text-xs"
              style={{
                borderColor: estimatedRevenueDelta > 0 ? 'oklch(0.72 0.17 155 / 0.30)' : 'oklch(0.70 0.20 30 / 0.30)',
                background: estimatedRevenueDelta > 0 ? 'oklch(0.72 0.17 155 / 0.06)' : 'oklch(0.70 0.20 30 / 0.06)',
              }}
            >
              <ArrowRight
                size={13}
                strokeWidth={2}
                style={{ color: estimatedRevenueDelta > 0 ? 'oklch(0.72 0.17 155)' : 'oklch(0.70 0.20 30)' }}
              />
              <span style={{ color: estimatedRevenueDelta > 0 ? 'oklch(0.85 0.12 155)' : 'oklch(0.85 0.10 30)' }}>
                {`${t('govt.tax.editor.estimatedImpact')}: ${estimatedRevenueDelta > 0 ? '+' : ''}${money(Math.abs(estimatedRevenueDelta))} / ciclo`}
              </span>
            </div>
          ) : null}

          {!showReason ? (
            <button
              type="button"
              onClick={() => { sfx.console_tap(); setShowReason(true) }}
              className="inline-flex h-9 w-full items-center justify-center gap-2 rounded-xl border border-[oklch(0.28_0.10_252)] bg-[oklch(0.65_0.18_252/0.10)] text-xs font-semibold uppercase tracking-[0.12em] text-[oklch(0.85_0.12_252)] transition-all hover:bg-[oklch(0.65_0.18_252/0.18)]"
            >
              {t('govt.tax.editor.reviewChanges')}
              <ArrowRight size={12} strokeWidth={2.4} />
            </button>
          ) : (
            <div className="space-y-2">
              <label className="block text-[10px] font-semibold uppercase tracking-[0.16em] text-[oklch(0.48_0.008_252)]">
                {t('govt.tax.editor.auditReason')}
                <span className="ml-1 text-[oklch(0.55_0.008_252)]">{`${reason.trim().length} / min ${REASON_MIN}`}</span>
              </label>
              <textarea
                value={reason}
                onChange={(e) => setReason(e.target.value.slice(0, 320))}
                placeholder={t('govt.tax.editor.reasonPlaceholder')}
                rows={2}
                className="w-full resize-none rounded-xl border bg-[oklch(0.07_0.010_252)] px-3 py-2.5 text-sm leading-relaxed text-[oklch(0.96_0.004_252)] placeholder:text-[oklch(0.38_0.008_252)] outline-none transition-colors"
                style={{ borderColor: 'oklch(0.20 0.012 252)' }}
              />
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={handleRevert}
                  disabled={mutation.isPending}
                  className="inline-flex h-9 flex-1 items-center justify-center gap-1.5 rounded-xl border bg-transparent text-xs font-semibold uppercase tracking-[0.12em] text-[oklch(0.55_0.008_252)] transition-colors disabled:opacity-50"
                  style={{ borderColor: 'oklch(0.20 0.012 252)' }}
                >
                  <RotateCcw size={12} strokeWidth={2.2} />
                  {t('govt.tax.editor.revert')}
                </button>
                <button
                  type="button"
                  onClick={handleSave}
                  disabled={!canSave}
                  className={cn(
                    'inline-flex h-9 flex-[2] items-center justify-center gap-2 rounded-xl border text-xs font-semibold uppercase tracking-[0.12em] transition-all disabled:cursor-not-allowed disabled:opacity-40',
                    canSave
                      ? 'border-[oklch(0.28_0.10_252)] bg-[oklch(0.65_0.18_252/0.14)] text-[oklch(0.88_0.10_252)] hover:bg-[oklch(0.65_0.18_252/0.22)]'
                      : 'border-[oklch(0.20_0.012_252)] text-[oklch(0.48_0.008_252)]',
                  )}
                >
                  {mutation.isPending ? <Loader2 size={13} className="animate-spin" /> : <Check size={13} strokeWidth={2.4} />}
                  {t('govt.tax.editor.savePolicy')}
                </button>
              </div>
            </div>
          )}
        </motion.div>
      ) : null}
    </div>
  )
}

interface BracketRowProps {
  bracket: GovtTaxBracket
  currentRate: number
  color: string
  index: number
  onChange: (v: number) => void
  disabled?: boolean
}

function BracketRow({ bracket, currentRate, color, index, onChange, disabled }: BracketRowProps) {
  const { money, number } = useI18n()
  const isDirty = currentRate !== bracket.rate
  const pct = ((currentRate - RATE_MIN) / (RATE_MAX - RATE_MIN)) * 100

  return (
    <motion.div
      initial={{ opacity: 0, x: -8 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.2, delay: index * 0.05 }}
      className="group relative overflow-hidden rounded-xl border p-3 transition-colors"
      style={{
        borderColor: isDirty ? `${color.replace(')', ' / 0.35)')}` : 'oklch(0.15 0.008 252)',
        background: isDirty ? `${color.replace(')', ' / 0.05)')}` : 'oklch(0.08 0.010 252)',
      }}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-2.5">
          <span
            aria-hidden
            className="inline-flex h-6 items-center rounded-md px-1.5 text-[10px] font-black tracking-[0.08em]"
            style={{ background: `${color.replace(')', ' / 0.15)')}`, color }}
          >
            {bracket.code}
          </span>
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em]" style={{ color: 'oklch(0.78 0.008 252)' }}>
              {bracket.label}
            </p>
            <p className="text-[10px]" style={{ color: 'oklch(0.45 0.008 252)' }}>
              {bracket.incomeMax
                ? `${money(bracket.incomeMin)} — ${money(bracket.incomeMax)}`
                : `${money(bracket.incomeMin)}+`}
            </p>
          </div>
        </div>
        <div className="text-right">
          <div className="flex items-baseline gap-1">
            {isDirty ? (
              <span className="text-[11px] line-through" style={{ color: 'oklch(0.40 0.008 252)' }}>{bracket.rate}%</span>
            ) : null}
            <span className="text-2xl font-light tracking-[-0.04em]" style={{ color: isDirty ? color : 'oklch(0.92 0.004 252)' }}>
              {currentRate}
            </span>
            <span className="text-xs" style={{ color: 'oklch(0.55 0.008 252)' }}>%</span>
          </div>
          <p className="text-[10px]" style={{ color: 'oklch(0.42 0.008 252)' }}>
            {`${number(bracket.affectedCount)} ${bracket.affectedCount === 1 ? 'citizen' : 'citizens'}`}
          </p>
        </div>
      </div>

      <div className="mt-3 relative h-5 flex items-center">
        <div className="pointer-events-none absolute left-0 right-0 h-[2px] rounded-full" style={{ background: 'oklch(0.16 0.010 252)' }} />
        <div
          className="pointer-events-none absolute left-0 h-[2px] rounded-full transition-all"
          style={{ width: `${pct}%`, background: color }}
        />
        <input
          type="range"
          min={RATE_MIN}
          max={RATE_MAX}
          step={1}
          value={currentRate}
          disabled={disabled}
          onChange={(e) => onChange(Number(e.target.value))}
          aria-label={`${bracket.label} tax rate`}
          className="absolute inset-0 w-full opacity-0 cursor-pointer disabled:cursor-not-allowed"
        />
        <div
          aria-hidden
          className="pointer-events-none absolute h-4 w-4 rounded-full border-2 border-white/90 transition-all"
          style={{
            left: `calc(${pct}% - 8px)`,
            background: color,
            boxShadow: isDirty ? `0 0 10px ${color.replace(')', ' / 0.50)')}` : 'none',
          }}
        />
      </div>
    </motion.div>
  )
}
