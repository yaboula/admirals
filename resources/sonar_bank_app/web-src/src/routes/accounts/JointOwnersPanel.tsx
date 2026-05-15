import { useState } from 'react'
import { motion, AnimatePresence, useReducedMotion } from 'motion/react'
import { Users, Plus, X, ShieldCheck, AlertTriangle } from 'lucide-react'
import { Card, CardEyebrow, CardTitle, Input, Button } from '@/components/ui'
import { useI18n } from '@/lib/i18n'
import { useAddJointOwnerMutation, useRemoveJointOwnerMutation, jointOwnerMutationPayload } from '@/data/mutations'
import type { Account } from '@/data/contracts'
import { handleBankError } from '@/lib/bankError'
import { toast } from '@/stores/toast'
import { sfx } from '@/lib/sfx'
import { cn } from '@/lib/utils'

/**
 * JointOwnersPanel — manages secondary holders on the selected bank account.
 *
 * Renders the live list of joint owners (chips with inline remove), an "Add"
 * CTA that opens an inline form, and a confirmation dialog when the operator
 * removes someone. Optimistic patches happen in the mutation layer; this
 * component focuses on UX feedback (loading, success toasts, error mapping)
 * and on never permitting destructive moves without explicit confirmation.
 *
 * The BE caps the joint set at three holders per account; we mirror the limit
 * locally to disable the CTA before the user even tries.
 */

const MAX_JOINTS = 3

/**
 * Coerce the wire-format `joint_owners` value to a `string[]`.
 *
 * Defensive against three shapes we have seen historically:
 *   - `null` (the canonical empty)
 *   - `string[]` (the canonical populated)
 *   - `string` containing a JSON-encoded array (legacy from MySQL JSON_ARRAYAGG
 *     that was not decoded server-side). The bootstrap service decodes today,
 *     but we keep this guard as a belt-and-braces measure so a regression
 *     never blanks the Accounts route again.
 */
function normaliseJoints(raw: unknown): string[] {
  if (raw == null) return []
  if (Array.isArray(raw)) return raw.filter((v): v is string => typeof v === 'string')
  if (typeof raw === 'string') {
    const trimmed = raw.trim()
    if (trimmed === '' || trimmed === '[]') return []
    try {
      const parsed = JSON.parse(trimmed) as unknown
      if (Array.isArray(parsed)) return parsed.filter((v): v is string => typeof v === 'string')
    } catch {
      /* fall through */
    }
  }
  return []
}

export interface JointOwnersPanelProps {
  account: Account | undefined
  isPrimaryOwner: boolean
}

export function JointOwnersPanel({ account, isPrimaryOwner }: JointOwnersPanelProps) {
  const { t } = useI18n()
  const reduced = useReducedMotion()
  const addJoint = useAddJointOwnerMutation()
  const removeJoint = useRemoveJointOwnerMutation()

  const [draftOpen, setDraftOpen] = useState(false)
  const [draftCitizen, setDraftCitizen] = useState('')
  const [pendingRemoval, setPendingRemoval] = useState<string | null>(null)

  const joints = normaliseJoints(account?.joint_owners)
  const isFrozen = account?.status === 'frozen' || account?.frozen_flag === true || account?.frozen_flag === 1
  const canManage = Boolean(account) && isPrimaryOwner && !isFrozen
  const atCap = joints.length >= MAX_JOINTS

  const submitAdd = async (): Promise<void> => {
    if (!account) return
    const trimmed = draftCitizen.trim()
    if (trimmed.length === 0) return
    try {
      const payload = jointOwnerMutationPayload({ iban: account.iban, joint_citizen_id: trimmed })
      sfx.console_tap()
      await addJoint.mutateAsync(payload)
      toast.success(
        t('accounts.joints.added'),
        t('accounts.joints.addedBody').replace('{citizen}', trimmed),
      )
      setDraftOpen(false)
      setDraftCitizen('')
    } catch (err) {
      handleBankError(err)
    }
  }

  const submitRemove = async (citizen: string): Promise<void> => {
    if (!account) return
    try {
      const payload = jointOwnerMutationPayload({ iban: account.iban, joint_citizen_id: citizen })
      sfx.console_tap()
      await removeJoint.mutateAsync(payload)
      toast.success(
        t('accounts.joints.removed'),
        t('accounts.joints.removedBody').replace('{citizen}', citizen),
      )
      setPendingRemoval(null)
    } catch (err) {
      handleBankError(err)
      setPendingRemoval(null)
    }
  }

  return (
    <Card variant="glass" padding="md" className="border-white/10 flex flex-col gap-3 shrink-0">
      <header className="flex items-center justify-between gap-3">
        <div className="min-w-0">
          <CardEyebrow>{t('accounts.joints.eyebrow')}</CardEyebrow>
          <CardTitle className="text-base">{t('accounts.joints.title')}</CardTitle>
        </div>
        <span className="inline-flex h-8 w-8 items-center justify-center rounded-xl border border-white/10 bg-white/[0.045] text-text-secondary">
          <Users size={15} strokeWidth={2} />
        </span>
      </header>

      <p className="text-[11px] leading-snug text-text-tertiary">
        {t('accounts.joints.description')}
      </p>

      {!isPrimaryOwner && account && (
        <div className="flex items-start gap-2 rounded-lg border border-white/[0.08] bg-white/[0.025] px-3 py-2 text-[11px] text-text-secondary/85">
          <ShieldCheck size={12} strokeWidth={2} className="mt-0.5 shrink-0 text-text-tertiary" />
          <span>{t('accounts.joints.notOwner')}</span>
        </div>
      )}

      {isFrozen && isPrimaryOwner && (
        <div className="flex items-start gap-2 rounded-lg border border-amber-300/15 bg-amber-300/[0.05] px-3 py-2 text-[11px] text-amber-200/90">
          <AlertTriangle size={12} strokeWidth={2} className="mt-0.5 shrink-0" />
          <span>{t('accounts.joints.savingsLocked')}</span>
        </div>
      )}

      <ul className="flex flex-col gap-2" aria-label={t('accounts.joints.title')}>
        {joints.length === 0 ? (
          <li className="rounded-lg border border-white/[0.06] bg-black/[0.12] px-3 py-2.5 text-[11px] text-text-tertiary text-center">
            {t('accounts.joints.empty')}
          </li>
        ) : joints.map((citizen) => {
          const removing = removeJoint.isPending && pendingRemoval === citizen
          return (
            <li
              key={citizen}
              className={cn(
                'group flex items-center justify-between gap-2 rounded-lg border border-white/[0.08] bg-white/[0.025] px-3 py-2 transition-colors',
                removing && 'opacity-60',
              )}
            >
              <span className="min-w-0 flex items-center gap-2">
                <span className="inline-flex h-6 w-6 items-center justify-center rounded-md bg-white/[0.06] text-text-secondary">
                  <ShieldCheck size={12} strokeWidth={2} />
                </span>
                <span className="font-mono text-xs text-text-primary truncate" title={citizen}>
                  {citizen}
                </span>
              </span>
              {canManage && (
                <button
                  type="button"
                  onClick={() => setPendingRemoval(citizen)}
                  disabled={removing}
                  aria-label={`${t('accounts.joints.removeTitle')}: ${citizen}`}
                  className={cn(
                    'inline-flex h-6 w-6 items-center justify-center rounded-md text-text-tertiary transition-colors',
                    'hover:text-[rgb(255,175,159)] hover:bg-[rgba(232,90,72,0.1)]',
                    'disabled:opacity-40 disabled:cursor-not-allowed',
                  )}
                >
                  <X size={12} strokeWidth={2.4} />
                </button>
              )}
            </li>
          )
        })}
      </ul>

      {canManage && !draftOpen && (
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setDraftOpen(true)}
          disabled={atCap}
          className="self-stretch justify-center"
        >
          <Plus size={13} strokeWidth={2.4} />
          <span>{atCap ? t('accounts.joints.maxReached') : t('accounts.joints.addCta')}</span>
        </Button>
      )}

      <AnimatePresence>
        {draftOpen && canManage && (
          <motion.div
            key="add-form"
            initial={reduced ? { opacity: 0 } : { opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={reduced ? { opacity: 0 } : { opacity: 0, height: 0 }}
            transition={{ duration: reduced ? 0.18 : 0.22, ease: [0.16, 1, 0.3, 1] }}
            className="overflow-hidden"
          >
            <div className="flex flex-col gap-2 rounded-lg border border-white/[0.08] bg-black/[0.18] p-3">
              <span className="text-[10px] uppercase tracking-[0.16em] text-text-tertiary font-semibold">
                {t('accounts.joints.addTitle')}
              </span>
              <p className="text-[11px] leading-snug text-text-tertiary">
                {t('accounts.joints.addHelper')}
              </p>
              <Input
                value={draftCitizen}
                onChange={(e) => setDraftCitizen(e.target.value)}
                placeholder={t('accounts.joints.placeholder')}
                autoFocus
                autoCapitalize="characters"
                spellCheck={false}
                aria-label={t('accounts.joints.placeholder')}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault()
                    void submitAdd()
                  } else if (e.key === 'Escape') {
                    e.preventDefault()
                    setDraftOpen(false)
                    setDraftCitizen('')
                  }
                }}
              />
              <div className="flex items-center justify-end gap-2">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => {
                    setDraftOpen(false)
                    setDraftCitizen('')
                  }}
                  disabled={addJoint.isPending}
                >
                  {t('accounts.joints.cancel')}
                </Button>
                <Button
                  variant="primary"
                  size="sm"
                  onClick={() => void submitAdd()}
                  disabled={addJoint.isPending || draftCitizen.trim().length === 0}
                >
                  {t('accounts.joints.confirmAdd')}
                </Button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {pendingRemoval && (
          <RemovalDialog
            citizen={pendingRemoval}
            busy={removeJoint.isPending}
            onCancel={() => setPendingRemoval(null)}
            onConfirm={() => void submitRemove(pendingRemoval)}
          />
        )}
      </AnimatePresence>
    </Card>
  )
}

function RemovalDialog({
  citizen,
  busy,
  onCancel,
  onConfirm,
}: {
  citizen: string
  busy: boolean
  onCancel: () => void
  onConfirm: () => void
}) {
  const { t } = useI18n()
  const reduced = useReducedMotion()
  return (
    <>
      <motion.div
        key="joint-remove-scrim"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: reduced ? 0 : 0.18 }}
        onClick={busy ? undefined : onCancel}
        className="fixed inset-0 z-[var(--z-drawer-scrim)] bg-surface-modal-scrim backdrop-blur-sm"
        aria-hidden
      />
      <motion.div
        key="joint-remove-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-label={t('accounts.joints.removeTitle')}
        initial={reduced ? { opacity: 0 } : { opacity: 0, y: 8, scale: 0.97 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={reduced ? { opacity: 0 } : { opacity: 0, y: 6, scale: 0.98 }}
        transition={reduced ? { duration: 0.18 } : { type: 'spring', stiffness: 320, damping: 30, mass: 0.85 }}
        className="fixed left-1/2 top-1/2 z-[var(--z-drawer)] w-[min(420px,calc(100vw-32px))] -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-white/10 p-5"
        style={{
          background: 'linear-gradient(180deg, rgb(2, 3, 6) 0%, rgb(0, 0, 0) 100%)',
          boxShadow:
            '0 24px 64px -16px rgba(0,0,0,0.7), 0 4px 12px -4px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.06)',
        }}
      >
        <div className="flex items-start gap-3 mb-4">
          <span className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-[rgba(232,90,72,0.3)] bg-[rgba(144,0,0,0.1)] text-[rgb(255,175,159)]">
            <AlertTriangle size={16} strokeWidth={2.2} />
          </span>
          <div className="flex flex-col gap-1 min-w-0">
            <h2 className="text-sm font-semibold text-text-primary">{t('accounts.joints.removeTitle')}</h2>
            <p className="text-[12px] leading-snug text-text-secondary">
              {t('accounts.joints.removeBody').replace('{citizen}', citizen)}
            </p>
          </div>
        </div>
        <div className="flex items-center justify-end gap-2">
          <Button variant="ghost" size="sm" onClick={onCancel} disabled={busy}>
            {t('accounts.joints.cancel')}
          </Button>
          <Button variant="danger" size="sm" onClick={onConfirm} disabled={busy}>
            {t('accounts.joints.confirmRemove')}
          </Button>
        </div>
      </motion.div>
    </>
  )
}
