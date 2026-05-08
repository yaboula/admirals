import type { ReactNode } from 'react'
import { LockKeyhole } from 'lucide-react'
import { Card, CardContent, CardEyebrow, CardTitle } from '@/components/ui'
import { areAllAceGranted, isAnyAceGranted } from '@/lib/ace'
import { isDevAccessUnlocked } from '@/lib/env'
import { useI18n } from '@/lib/i18n'
import { cn } from '@/lib/utils'
import { useBankSession, type AcePerm } from '@/stores/session'

export interface UseAceGateArgs {
  require?: AcePerm | AcePerm[]
  mode?: 'all' | 'any'
}

export function useAceGate({ require, mode = 'all' }: UseAceGateArgs): boolean {
  const acePerms = useBankSession((s) => s.acePerms)
  if (isDevAccessUnlocked()) return true
  if (!require) return true
  const required = Array.isArray(require) ? require : [require]
  if (required.length === 0) return true
  return mode === 'any'
    ? isAnyAceGranted(acePerms, required)
    : areAllAceGranted(acePerms, required)
}

export interface AceGateProps extends UseAceGateArgs {
  children: ReactNode
  fallback?: ReactNode
}

export function AceGate({ require, mode = 'all', children, fallback = null }: AceGateProps) {
  const granted = useAceGate({ require, mode })
  return granted ? <>{children}</> : <>{fallback}</>
}

export interface AceLockedStateProps {
  title?: string
  description?: string
  className?: string
}

export function AceLockedState({
  title,
  description,
  className,
}: AceLockedStateProps) {
  const { t } = useI18n()

  return (
    <Card variant="glass" padding="lg" className={cn('border-white/10 text-center', className)}>
      <CardContent className="items-center gap-3">
        <div className="flex h-11 w-11 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.04] text-text-tertiary">
          <LockKeyhole size={18} strokeWidth={1.8} />
        </div>
        <div className="space-y-1">
          <CardEyebrow>{t('ace.gate')}</CardEyebrow>
          <CardTitle className="text-base">{title ?? t('ace.permissionRequired')}</CardTitle>
          <p className="mx-auto max-w-[36ch] text-sm leading-relaxed text-text-tertiary">{description ?? t('ace.permissionRequiredDescription')}</p>
        </div>
      </CardContent>
    </Card>
  )
}
