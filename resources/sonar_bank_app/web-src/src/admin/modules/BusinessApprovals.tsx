import { useState } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import { Check, X, Building2, Users, DollarSign, Clock, type LucideIcon } from 'lucide-react'
import { useBusinessTreasuryQuery } from '@/data/queries'
import { useDecideBusinessApprovalMutation } from '@/data/mutations'
import { Button, Badge, Input, Spinner } from '@/components/ui'
import { useI18n } from '@/lib/i18n'
import { cn } from '@/lib/utils'
import { toast } from '@/stores/toast'

type ApprovalType = 'payroll' | 'withdrawal' | 'recurring' | 'loan'

export function BusinessApprovals() {
  const selectedCompanyId = 'demo-company-001'
  const treasuryQuery = useBusinessTreasuryQuery({ company_id: selectedCompanyId })
  const treasury = treasuryQuery.data
  const pendingApprovals = treasury?.pending_approvals ?? []
  const [selectedApprovalId, setSelectedApprovalId] = useState<string | null>(null)
  const [decisionOpen, setDecisionOpen] = useState(false)
  const [decision, setDecision] = useState<'approve' | 'reject'>('approve')
  const [note, setNote] = useState('')
  const decideMutation = useDecideBusinessApprovalMutation(selectedCompanyId)

  const selectedApproval = pendingApprovals.find((a) => a.approval_id === selectedApprovalId)

  const handleDecision = async () => {
    if (!decision || !selectedApproval) return
    try {
      await decideMutation.mutateAsync({
        approval_id: selectedApproval.approval_id,
        decision,
        note: note || undefined,
      })
      setDecisionOpen(false)
      setDecision('approve')
      setNote('')
      setSelectedApprovalId(null)
      toast.success('Decision recorded', `Approval marked as ${decision}`)
    } catch {
      toast.warning('Decision failed', 'Check the approval status and try again')
    }
  }

  const openDecision = (d: 'approve' | 'reject') => {
    setDecision(d)
    setDecisionOpen(true)
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h2 className="text-2xl font-semibold text-text-primary">Business Approvals</h2>
        <p className="mt-1 text-sm text-text-secondary">
          {pendingApprovals.length} pending approval{pendingApprovals.length !== 1 ? 's' : ''} requiring sign-off
        </p>
      </div>

      {treasuryQuery.isLoading ? (
        <div className="flex min-h-[300px] items-center justify-center">
          <Spinner size="lg" />
        </div>
      ) : pendingApprovals.length === 0 ? (
        <div className="flex min-h-[300px] flex-col items-center justify-center rounded-2xl border border-white/10 bg-white/[0.02]">
          <Check size={48} strokeWidth={1.5} className="text-semantic-success-deep" />
          <p className="mt-4 text-lg font-semibold text-text-primary">No pending approvals</p>
          <p className="mt-1 text-sm text-text-secondary">All business approvals have been processed</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {pendingApprovals.map((approval) => (
            <BusinessApprovalCard
              key={approval.approval_id}
              approval={approval}
              selected={selectedApprovalId === approval.approval_id}
              onSelect={() => setSelectedApprovalId(approval.approval_id)}
              onOpenDecision={(d) => {
                setSelectedApprovalId(approval.approval_id)
                openDecision(d)
              }}
            />
          ))}
        </div>
      )}

      <AnimatePresence>
        {decisionOpen && selectedApproval && (
          <DecisionDialog
            approval={selectedApproval}
            decision={decision}
            note={note}
            onNoteChange={setNote}
            onConfirm={handleDecision}
            onCancel={() => {
              setDecisionOpen(false)
              setDecision('approve')
              setNote('')
            }}
            loading={decideMutation.isPending}
          />
        )}
      </AnimatePresence>
    </div>
  )
}

function BusinessApprovalCard({
  approval,
  selected,
  onSelect,
  onOpenDecision,
}: {
  approval: any
  selected: boolean
  onSelect: () => void
  onOpenDecision: (decision: 'approve' | 'reject') => void
}) {
  const { money, dateTime } = useI18n()
  const typeConfig: Record<ApprovalType, { icon: LucideIcon; color: string; label: string }> = {
    payroll: { icon: Users, color: 'text-semantic-info-deep', label: 'Payroll' },
    withdrawal: { icon: DollarSign, color: 'text-semantic-warning-deep', label: 'Withdrawal' },
    recurring: { icon: Clock, color: 'text-semantic-success-deep', label: 'Recurring' },
    loan: { icon: Building2, color: 'text-semantic-danger-deep', label: 'Loan' },
  }
  const config = typeConfig[approval.type as ApprovalType] || typeConfig.payroll
  const Icon = config.icon

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
          <Icon size={16} strokeWidth={2} className={config.color} />
          <p className="truncate text-base font-semibold text-text-primary">{config.label}</p>
          <Badge tone={approval.status === 'pending' ? 'warning' : approval.status === 'approved' ? 'success' : 'danger'} variant="soft" size="xs">
            {approval.status}
          </Badge>
        </div>
        <p className="mt-1 truncate text-sm text-text-tertiary">
          Requested by {approval.requested_by_alias} · {approval.required_perm}
        </p>
        <p className="mt-1 text-xs text-text-tertiary">
          {dateTime(approval.created_at_ms, { month: 'short', day: 'numeric', year: 'numeric' })}
        </p>
      </div>

      <div className="text-right">
        <p className="text-base font-semibold text-text-primary tactile-tabular-nums">{money(approval.amount_minor / 100)}</p>
        <p className="mt-1 text-xs text-text-tertiary">Amount</p>
      </div>

      <div className="text-right">
        <p className="text-base font-semibold text-text-primary tactile-tabular-nums">{approval.requires_approvals}</p>
        <p className="mt-1 text-xs text-text-tertiary">Signers</p>
      </div>

      <div className="text-right">
        <p className="text-sm font-semibold text-text-primary truncate max-w-[140px]">{approval.approval_id}</p>
        <p className="mt-1 text-xs text-text-tertiary">Approval ID</p>
      </div>

      <div className="text-right">
        <p className="text-sm font-semibold text-text-primary">{approval.currency}</p>
        <p className="mt-1 text-xs text-text-tertiary">Currency</p>
      </div>

      <div className="flex items-center gap-2">
        <Button
          size="sm"
          variant="secondary"
          leftIcon={<Check size={14} />}
          onClick={(e) => {
            e.stopPropagation()
            onOpenDecision('approve')
          }}
        >
          Approve
        </Button>
        <Button
          size="sm"
          variant="secondary"
          leftIcon={<X size={14} />}
          onClick={(e) => {
            e.stopPropagation()
            onOpenDecision('reject')
          }}
        >
          Reject
        </Button>
      </div>
    </motion.div>
  )
}

function DecisionDialog({
  approval,
  decision,
  note,
  onNoteChange,
  onConfirm,
  onCancel,
  loading,
}: {
  approval: any
  decision: 'approve' | 'reject'
  note: string
  onNoteChange: (v: string) => void
  onConfirm: () => void
  onCancel: () => void
  loading: boolean
}) {
  const { money } = useI18n()

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
            {decision === 'approve' ? 'Approve Request' : 'Reject Request'}
          </h3>
          <Button size="sm" variant="ghost" leftIcon={<X size={16} />} onClick={onCancel}>
            Cancel
          </Button>
        </div>

        <div className="mb-5 space-y-3 rounded-xl border border-white/10 bg-white/[0.02] p-4">
          <div className="flex justify-between">
            <span className="text-sm text-text-tertiary">Type</span>
            <span className="text-sm font-semibold text-text-primary">{approval.type}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-text-tertiary">Amount</span>
            <span className="text-sm font-semibold text-text-primary tactile-tabular-nums">{money(approval.amount_minor / 100)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-text-tertiary">Requested by</span>
            <span className="text-sm font-semibold text-text-primary">{approval.requested_by_alias}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-text-tertiary">Required signers</span>
            <span className="text-sm font-semibold text-text-primary tactile-tabular-nums">{approval.requires_approvals}</span>
          </div>
        </div>

        <div className="space-y-4">
          <Input
            label="Decision Note (optional)"
            value={note}
            onChange={(e) => onNoteChange(e.currentTarget.value)}
            placeholder="Add context to this decision..."
          />
          <div className="flex gap-3">
            <Button
              size="md"
              variant="primary"
              loading={loading}
              onClick={onConfirm}
              className="flex-1"
            >
              {decision === 'approve' ? 'Approve' : 'Reject'}
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
