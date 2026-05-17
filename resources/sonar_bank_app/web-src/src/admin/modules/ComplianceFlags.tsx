import { useState } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import { Check, X, AlertTriangle, Shield } from 'lucide-react'
import { useComplianceFlagsQuery } from '@/data/queries'
import { useResolveComplianceFlagMutation } from '@/data/mutations'
import { Button, Badge, Input, Spinner } from '@/components/ui'
import { useI18n } from '@/lib/i18n'
import { cn } from '@/lib/utils'
import { toast } from '@/stores/toast'

type ComplianceSeverity = 'low' | 'medium' | 'high' | 'critical'

export function ComplianceFlags() {
  const flagsQuery = useComplianceFlagsQuery({ status: 'open' })
  const flags = flagsQuery.data?.items ?? []
  const [selectedFlagId, setSelectedFlagId] = useState<string | null>(null)
  const [resolveOpen, setResolveOpen] = useState(false)
  const [resolution, setResolution] = useState<'resolved' | 'dismissed' | 'escalated'>('resolved')
  const [notes, setNotes] = useState('')
  const resolveMutation = useResolveComplianceFlagMutation()

  const selectedFlag = flags.find((flag) => flag.flag_id === selectedFlagId)

  const handleResolve = async () => {
    if (!resolution || !selectedFlag) return
    try {
      await resolveMutation.mutateAsync({
        flag_id: selectedFlag.flag_id,
        resolution,
        resolution_notes: notes,
      })
      setResolveOpen(false)
      setResolution('resolved')
      setNotes('')
      setSelectedFlagId(null)
      toast.success('Flag resolved', `Compliance flag marked as ${resolution}`)
    } catch {
      toast.warning('Resolution failed', 'Check the flag status and try again')
    }
  }

  const openResolve = (r: 'resolved' | 'dismissed' | 'escalated') => {
    setResolution(r)
    setResolveOpen(true)
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h2 className="text-2xl font-semibold text-text-primary">Compliance Flags</h2>
        <p className="mt-1 text-sm text-text-secondary">
          {flags.length} open flag{flags.length !== 1 ? 's' : ''} requiring review
        </p>
      </div>

      {flagsQuery.isLoading ? (
        <div className="flex min-h-[300px] items-center justify-center">
          <Spinner size="lg" />
        </div>
      ) : flags.length === 0 ? (
        <div className="flex min-h-[300px] flex-col items-center justify-center rounded-2xl border border-white/10 bg-white/[0.02]">
          <Shield size={48} strokeWidth={1.5} className="text-semantic-success-deep" />
          <p className="mt-4 text-lg font-semibold text-text-primary">No open flags</p>
          <p className="mt-1 text-sm text-text-secondary">All compliance flags have been resolved</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {flags.map((flag) => (
            <ComplianceFlagCard
              key={flag.flag_id}
              flag={flag}
              selected={selectedFlagId === flag.flag_id}
              onSelect={() => setSelectedFlagId(flag.flag_id)}
              onOpenResolve={(r) => {
                setSelectedFlagId(flag.flag_id)
                openResolve(r)
              }}
            />
          ))}
        </div>
      )}

      <AnimatePresence>
        {resolveOpen && selectedFlag && (
          <ResolveDialog
            flag={selectedFlag}
            resolution={resolution}
            notes={notes}
            onNotesChange={setNotes}
            onConfirm={handleResolve}
            onCancel={() => {
              setResolveOpen(false)
              setResolution('resolved')
              setNotes('')
            }}
            loading={resolveMutation.isPending}
          />
        )}
      </AnimatePresence>
    </div>
  )
}

function ComplianceFlagCard({
  flag,
  selected,
  onSelect,
  onOpenResolve,
}: {
  flag: any
  selected: boolean
  onSelect: () => void
  onOpenResolve: (resolution: 'resolved' | 'dismissed' | 'escalated') => void
}) {
  const { dateTime } = useI18n()
  const severity: ComplianceSeverity = flag.severity || 'medium'

  const severityConfig = {
    low: { color: 'text-semantic-success-deep', bg: 'bg-semantic-success/10', border: 'border-semantic-success/20' },
    medium: { color: 'text-semantic-warning-deep', bg: 'bg-semantic-warning/10', border: 'border-semantic-warning/20' },
    high: { color: 'text-semantic-danger-deep', bg: 'bg-semantic-danger/10', border: 'border-semantic-danger/20' },
    critical: { color: 'text-semantic-danger-deep', bg: 'bg-semantic-danger/15', border: 'border-semantic-danger/30' },
  }[severity]

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
      onClick={onSelect}
      className={cn(
        'grid grid-cols-[minmax(0,1.5fr)_140px_120px_120px_140px_180px] items-center gap-4 rounded-2xl border p-5 text-left transition-all cursor-pointer',
        selected ? 'border-white/18 bg-[radial-gradient(circle_at_0%_0%,rgba(246,75,0,0.08),transparent_50%),rgba(255,255,255,0.055)]' : 'border-white/10 bg-white/[0.02] hover:bg-white/[0.045]'
      )}
    >
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <p className="truncate text-base font-semibold text-text-primary">{flag.event_type}</p>
          <Badge tone={severity === 'critical' ? 'danger' : severity === 'high' ? 'danger' : severity === 'medium' ? 'warning' : 'success'} variant="soft" size="xs">
            {severity.toUpperCase()}
          </Badge>
        </div>
        <p className="mt-1 truncate text-sm text-text-tertiary">
          Subject: {flag.subject_cid_masked} · {flag.account_iban_masked || 'N/A'}
        </p>
        <p className="mt-1 text-xs text-text-tertiary">
          Raised {dateTime(flag.created_at_ms, { month: 'short', day: 'numeric', year: 'numeric' })}
        </p>
      </div>

      <div className={cn('flex items-center gap-2 rounded-lg border px-3 py-2', severityConfig.border, severityConfig.bg)}>
        <AlertTriangle size={16} strokeWidth={2} className={severityConfig.color} />
        <span className={cn('text-xs font-semibold uppercase', severityConfig.color)}>Risk {flag.risk_score}</span>
      </div>

      <div className="text-right">
        <p className="text-base font-semibold text-text-primary tactile-tabular-nums">{flag.evidence_count}</p>
        <p className="mt-1 text-xs text-text-tertiary">Evidence</p>
      </div>

      <div className="text-right">
        <p className="text-base font-semibold text-text-primary">{flag.assigned_unit}</p>
        <p className="mt-1 text-xs text-text-tertiary">Unit</p>
      </div>

      <div className="text-right">
        <p className="text-sm font-semibold text-text-primary truncate max-w-[140px]">{flag.correlation_id}</p>
        <p className="mt-1 text-xs text-text-tertiary">Ref ID</p>
      </div>

      <div className="flex items-center gap-2">
        <Button
          size="sm"
          variant="secondary"
          leftIcon={<Check size={14} />}
          onClick={(e) => {
            e.stopPropagation()
            onOpenResolve('resolved')
          }}
        >
          Resolve
        </Button>
        <Button
          size="sm"
          variant="secondary"
          leftIcon={<X size={14} />}
          onClick={(e) => {
            e.stopPropagation()
            onOpenResolve('dismissed')
          }}
        >
          Dismiss
        </Button>
      </div>
    </motion.div>
  )
}

function ResolveDialog({
  flag,
  resolution,
  notes,
  onNotesChange,
  onConfirm,
  onCancel,
  loading,
}: {
  flag: any
  resolution: 'resolved' | 'dismissed' | 'escalated'
  notes: string
  onNotesChange: (v: string) => void
  onConfirm: () => void
  onCancel: () => void
  loading: boolean
}) {

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4 backdrop-blur-md"
    >
      <motion.div
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
        transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        className="w-full max-w-lg rounded-2xl border border-white/10 bg-surface-panel p-6 shadow-2xl"
      >
        <div className="mb-5 flex items-center justify-between">
          <h3 className="text-xl font-semibold text-text-primary">
            {resolution === 'resolved' ? 'Resolve Flag' : resolution === 'dismissed' ? 'Dismiss Flag' : 'Escalate Flag'}
          </h3>
          <Button size="sm" variant="ghost" leftIcon={<X size={16} />} onClick={onCancel}>
            Cancel
          </Button>
        </div>

        <div className="mb-5 space-y-3 rounded-xl border border-white/10 bg-white/[0.02] p-4">
          <div className="flex justify-between">
            <span className="text-sm text-text-tertiary">Event Type</span>
            <span className="text-sm font-semibold text-text-primary">{flag.event_type}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-text-tertiary">Subject</span>
            <span className="text-sm font-semibold text-text-primary">{flag.subject_cid_masked}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-text-tertiary">Risk Score</span>
            <span className="text-sm font-semibold text-text-primary tactile-tabular-nums">{flag.risk_score}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-text-tertiary">Evidence Count</span>
            <span className="text-sm font-semibold text-text-primary tactile-tabular-nums">{flag.evidence_count}</span>
          </div>
        </div>

        <div className="space-y-4">
          <Input
            label="Resolution Notes"
            value={notes}
            onChange={(e) => onNotesChange(e.currentTarget.value)}
            placeholder="Explain the resolution decision..."
            required
          />
          <div className="flex gap-3">
            <Button
              size="md"
              variant="primary"
              loading={loading}
              onClick={onConfirm}
              className="flex-1"
            >
              {resolution === 'resolved' ? 'Resolve' : resolution === 'dismissed' ? 'Dismiss' : 'Escalate'}
            </Button>
            <Button size="md" variant="secondary" onClick={onCancel} className="flex-1">
              Cancel
            </Button>
          </div>
        </div>
      </motion.div>
    </motion.div>
  )
}
