import { useEffect, useMemo, useState } from 'react'
import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { AlertTriangle, Check, Loader2, X } from 'lucide-react'
import { useI18n, type TranslationKey } from '@/lib/i18n'
import { sfx } from '@/lib/sfx'
import { generateUuidV4 } from '@/lib/utils'
import { cn } from '@/lib/utils'

export type ActionDialogKind = 'close_flag' | 'freeze' | 'lift_freeze' | 'apply_fine'

export interface ActionDialogResult {
  reason: string
  idempotencyKey: string
  verdict?: 'resolved' | 'dismissed'
  amount?: number
}

interface ActionDialogProps {
  open: boolean
  kind: ActionDialogKind
  citizenAlias: string
  busy?: boolean
  onClose: () => void
  onConfirm: (result: ActionDialogResult) => Promise<void> | void
}

const TITLE_KEY: Record<ActionDialogKind, TranslationKey> = {
  close_flag: 'govt.sanctions.dialog.closeFlagTitle',
  freeze: 'govt.sanctions.dialog.freezeTitle',
  lift_freeze: 'govt.sanctions.dialog.liftFreezeTitle',
  apply_fine: 'govt.sanctions.dialog.applyFineTitle',
}

const WARNING_KEY: Record<ActionDialogKind, TranslationKey> = {
  close_flag: 'govt.sanctions.dialog.closeFlagWarning',
  freeze: 'govt.sanctions.dialog.freezeWarning',
  lift_freeze: 'govt.sanctions.dialog.liftFreezeWarning',
  apply_fine: 'govt.sanctions.dialog.applyFineWarning',
}

const CTA_KEY: Record<ActionDialogKind, TranslationKey> = {
  close_flag: 'govt.sanctions.dialog.confirmClose',
  freeze: 'govt.sanctions.dialog.confirmFreeze',
  lift_freeze: 'govt.sanctions.dialog.confirmLift',
  apply_fine: 'govt.sanctions.dialog.confirmFine',
}

const DESTRUCTIVE: Record<ActionDialogKind, boolean> = {
  close_flag: false,
  freeze: true,
  lift_freeze: false,
  apply_fine: true,
}

const REASON_MIN = 12
const REASON_MAX = 320
const FINE_MAX_CENTS = 5_000_000_00 // $5M ceiling

export function ActionDialog({ open, kind, citizenAlias, busy, onClose, onConfirm }: ActionDialogProps) {
  const { t, money } = useI18n()
  const reduced = useReducedMotion()

  const [reason, setReason] = useState('')
  const [verdict, setVerdict] = useState<'resolved' | 'dismissed'>('resolved')
  const [fineAmountInput, setFineAmountInput] = useState('')

  const fineAmountCents = useMemo(() => {
    const parsed = Number.parseFloat(fineAmountInput.replace(',', '.'))
    if (Number.isNaN(parsed) || parsed <= 0) return 0
    return Math.round(parsed * 100)
  }, [fineAmountInput])

  useEffect(() => {
    if (open) {
      setReason('')
      setVerdict('resolved')
      setFineAmountInput('')
    }
  }, [open, kind])

  useEffect(() => {
    if (!open) return
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !busy) onClose()
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [open, busy, onClose])

  const reasonValid = reason.trim().length >= REASON_MIN && reason.trim().length <= REASON_MAX
  const fineValid = kind !== 'apply_fine' || (fineAmountCents > 0 && fineAmountCents <= FINE_MAX_CENTS)
  const canSubmit = reasonValid && fineValid && !busy

  const handleSubmit = async () => {
    if (!canSubmit) return
    sfx.console_tap()
    const result: ActionDialogResult = {
      reason: reason.trim(),
      idempotencyKey: generateUuidV4(),
    }
    if (kind === 'close_flag') result.verdict = verdict
    if (kind === 'apply_fine') result.amount = fineAmountCents
    await onConfirm(result)
  }

  return (
    <AnimatePresence>
      {open ? (
        <motion.div
          key="govt-action-dialog"
          role="dialog"
          aria-modal="true"
          aria-labelledby="govt-action-dialog-title"
          className="fixed inset-0 z-[120] flex items-center justify-center p-6"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: reduced ? 0 : 0.18 }}
        >
          <button
            type="button"
            tabIndex={-1}
            aria-label={t('govt.sanctions.dialog.dismiss')}
            className="absolute inset-0 cursor-default bg-black/70 backdrop-blur-md"
            onClick={() => {
              if (!busy) onClose()
            }}
          />

          <motion.div
            initial={{ opacity: 0, y: 14, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 8, scale: 0.97 }}
            transition={{ duration: reduced ? 0 : 0.22, ease: [0.16, 1, 0.3, 1] }}
            className="relative w-full max-w-lg overflow-hidden rounded-[1.75rem] border border-[var(--color-govt-border-strong)]"
            style={{
              background:
                'radial-gradient(circle at 50% 0%, oklch(0.18 0.045 252 / 0.96), oklch(0.07 0.025 252 / 0.98))',
              boxShadow: '0 40px 90px -32px oklch(0 0 0 / 0.85), 0 0 80px -20px var(--color-govt-accent-glow)',
            }}
          >
            <div className="flex items-start justify-between gap-3 px-6 pt-5">
              <div className="flex items-center gap-3">
                <span
                  aria-hidden
                  className={cn(
                    'flex h-10 w-10 items-center justify-center rounded-2xl border',
                    DESTRUCTIVE[kind]
                      ? 'border-[oklch(0.62_0.21_25/0.40)] text-[oklch(0.78_0.16_25)]'
                      : 'border-[var(--color-govt-border-strong)] text-[var(--color-govt-accent-light)]',
                  )}
                  style={{
                    background: DESTRUCTIVE[kind] ? 'oklch(0.62 0.21 25 / 0.10)' : 'var(--color-govt-accent-subtle)',
                  }}
                >
                  <AlertTriangle size={18} strokeWidth={2} />
                </span>
                <div>
                  <h2 id="govt-action-dialog-title" className="text-base font-semibold tracking-[-0.01em] text-[var(--color-govt-text-primary)]">
                    {t(TITLE_KEY[kind])}
                  </h2>
                  <p className="mt-0.5 text-xs text-[var(--color-govt-text-tertiary)]">
                    {`${t('govt.sanctions.dialog.target')}: ${citizenAlias}`}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => {
                  if (!busy) onClose()
                }}
                aria-label={t('govt.sanctions.dialog.dismiss')}
                className="rounded-full p-1.5 text-[var(--color-govt-text-tertiary)] transition-colors hover:bg-white/[0.06] hover:text-[var(--color-govt-text-primary)] disabled:cursor-not-allowed"
                disabled={busy}
              >
                <X size={15} strokeWidth={2.2} />
              </button>
            </div>

            <div className="px-6 pb-5 pt-3">
              <div
                className="mb-4 rounded-xl border px-3 py-2.5 text-[12px] leading-relaxed"
                style={{
                  borderColor: DESTRUCTIVE[kind] ? 'oklch(0.62 0.21 25 / 0.32)' : 'var(--color-govt-border-strong)',
                  background: DESTRUCTIVE[kind] ? 'oklch(0.62 0.21 25 / 0.08)' : 'var(--color-govt-accent-subtle)',
                  color: DESTRUCTIVE[kind] ? 'oklch(0.85 0.10 25)' : 'var(--color-govt-text-secondary)',
                }}
              >
                {t(WARNING_KEY[kind])}
              </div>

              {kind === 'close_flag' ? (
                <FieldRow label={t('govt.sanctions.dialog.verdictLabel')}>
                  <div className="flex gap-2">
                    {(['resolved', 'dismissed'] as const).map((v) => (
                      <button
                        key={v}
                        type="button"
                        onClick={() => setVerdict(v)}
                        className={cn(
                          'flex-1 rounded-xl border px-3 py-2 text-xs font-semibold uppercase tracking-[0.10em] transition-all',
                          verdict === v
                            ? 'border-[var(--color-govt-border-active)] bg-[var(--color-govt-accent-soft)] text-[var(--color-govt-accent-light)]'
                            : 'border-[var(--color-govt-border)] bg-white/[0.03] text-[var(--color-govt-text-tertiary)] hover:border-[var(--color-govt-border-strong)] hover:text-[var(--color-govt-text-secondary)]',
                        )}
                      >
                        {t(v === 'resolved' ? 'govt.census.flags.status.resolved' : 'govt.census.flags.status.dismissed')}
                      </button>
                    ))}
                  </div>
                </FieldRow>
              ) : null}

              {kind === 'apply_fine' ? (
                <FieldRow label={t('govt.sanctions.dialog.amountLabel')} hint={t('govt.sanctions.dialog.amountHint')}>
                  <div className="relative">
                    <span aria-hidden className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-[var(--color-govt-text-tertiary)]">$</span>
                    <input
                      type="text"
                      inputMode="decimal"
                      value={fineAmountInput}
                      onChange={(e) => setFineAmountInput(e.target.value.replace(/[^0-9.,]/g, ''))}
                      placeholder="0.00"
                      className="h-11 w-full rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.06_0.022_252/0.50)] pl-7 pr-3 text-sm text-[var(--color-govt-text-primary)] placeholder:text-[var(--color-govt-text-quaternary)] outline-none transition-colors focus:border-[var(--color-govt-border-active)] tactile-tabular-nums"
                    />
                  </div>
                  {fineAmountCents > 0 ? (
                    <p className="mt-1.5 text-[11px] text-[var(--color-govt-text-tertiary)]">{`= ${money(fineAmountCents)}`}</p>
                  ) : null}
                </FieldRow>
              ) : null}

              <FieldRow label={t('govt.sanctions.dialog.reasonLabel')} hint={`${reason.trim().length}/${REASON_MAX} · min ${REASON_MIN}`}>
                <textarea
                  value={reason}
                  onChange={(e) => setReason(e.target.value.slice(0, REASON_MAX))}
                  placeholder={t('govt.sanctions.dialog.reasonPlaceholder')}
                  rows={3}
                  className="w-full resize-none rounded-xl border border-[var(--color-govt-border)] bg-[oklch(0.06_0.022_252/0.50)] px-3 py-2.5 text-sm leading-relaxed text-[var(--color-govt-text-primary)] placeholder:text-[var(--color-govt-text-quaternary)] outline-none transition-colors focus:border-[var(--color-govt-border-active)]"
                />
              </FieldRow>
            </div>

            <div className="flex items-center justify-end gap-2 border-t border-[var(--color-govt-border)] bg-[oklch(0.05_0.022_252/0.85)] px-6 py-3">
              <button
                type="button"
                onClick={onClose}
                disabled={busy}
                className="inline-flex h-9 items-center gap-2 rounded-full border border-[var(--color-govt-border)] bg-white/[0.03] px-4 text-xs font-semibold uppercase tracking-[0.12em] text-[var(--color-govt-text-secondary)] transition-colors hover:bg-white/[0.06] hover:text-[var(--color-govt-text-primary)] disabled:cursor-not-allowed disabled:opacity-50"
              >
                {t('govt.sanctions.dialog.cancel')}
              </button>
              <button
                type="button"
                onClick={handleSubmit}
                disabled={!canSubmit}
                className={cn(
                  'inline-flex h-9 items-center gap-2 rounded-full border px-4 text-xs font-semibold uppercase tracking-[0.12em] transition-all disabled:cursor-not-allowed disabled:opacity-50',
                  DESTRUCTIVE[kind]
                    ? 'border-[oklch(0.62_0.21_25/0.50)] bg-[oklch(0.62_0.21_25/0.18)] text-[oklch(0.92_0.06_25)] hover:bg-[oklch(0.62_0.21_25/0.30)]'
                    : 'border-[var(--color-govt-border-active)] bg-[var(--color-govt-accent-soft)] text-[var(--color-govt-accent-light)] hover:bg-[var(--color-govt-accent-glow)]',
                )}
              >
                {busy ? <Loader2 size={13} className="animate-spin" /> : <Check size={13} strokeWidth={2.4} />}
                <span>{t(CTA_KEY[kind])}</span>
              </button>
            </div>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  )
}

function FieldRow({ label, hint, children }: { label: string; hint?: string; children: React.ReactNode }) {
  return (
    <div className="mb-3">
      <div className="mb-1 flex items-center justify-between gap-2">
        <span className="text-[10px] font-semibold uppercase tracking-[0.16em] text-[var(--color-govt-text-tertiary)]">{label}</span>
        {hint ? <span className="text-[10px] text-[var(--color-govt-text-quaternary)]">{hint}</span> : null}
      </div>
      {children}
    </div>
  )
}
