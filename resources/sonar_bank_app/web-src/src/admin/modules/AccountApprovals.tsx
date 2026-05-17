import { useState } from 'react'
import { Building2, Check, Clock, X } from 'lucide-react'
import { Button, Badge, Input, Spinner } from '@/components/ui'
import { useProfessionalAccountApprovalsQuery } from '@/data/queries'
import { useDecideProfessionalAccountMutation } from '@/data/mutations'
import type { ProfessionalAccountApproval } from '@/data/contracts'
import { useI18n } from '@/lib/i18n'
import { toast } from '@/stores/toast'

export function AccountApprovals() {
  const { dateTime } = useI18n()
  const approvalsQuery = useProfessionalAccountApprovalsQuery({ limit: 50 })
  const decideMutation = useDecideProfessionalAccountMutation()
  const approvals = approvalsQuery.data?.items ?? []
  const [selectedApproval, setSelectedApproval] = useState<ProfessionalAccountApproval | null>(null)
  const [decision, setDecision] = useState<'approve' | 'reject'>('approve')
  const [note, setNote] = useState('')

  const submitDecision = async () => {
    if (!selectedApproval) return
    try {
      await decideMutation.mutateAsync({ approval_id: selectedApproval.approval_id, decision, note: note || undefined })
      toast.success('Decision recorded', decision === 'approve' ? 'Professional account approved' : 'Request rejected')
      setSelectedApproval(null)
      setDecision('approve')
      setNote('')
      await approvalsQuery.refetch()
    } catch {
      toast.warning('Decision failed', 'Check the request status and try again')
    }
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h2 className="text-2xl font-semibold text-text-primary">Professional Accounts</h2>
        <p className="mt-1 text-sm text-text-secondary">{approvals.length} pending request{approvals.length !== 1 ? 's' : ''} awaiting review</p>
      </div>

      {approvalsQuery.isLoading ? (
        <div className="flex min-h-[300px] items-center justify-center"><Spinner size="lg" /></div>
      ) : approvals.length === 0 ? (
        <div className="flex min-h-[300px] flex-col items-center justify-center rounded-2xl border border-white/10 bg-white/[0.02]">
          <Check size={48} strokeWidth={1.5} className="text-semantic-success-deep" />
          <p className="mt-4 text-lg font-semibold text-text-primary">No pending requests</p>
          <p className="mt-1 text-sm text-text-secondary">Professional account requests have been processed</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {approvals.map((approval) => (
            <div key={approval.approval_id} className="grid grid-cols-[minmax(0,1fr)_160px_180px] items-center gap-4 rounded-2xl border border-white/10 bg-white/[0.02] p-5">
              <div className="min-w-0">
                <div className="flex items-center gap-2">
                  <Building2 size={16} strokeWidth={2} className="text-semantic-info-deep" />
                  <p className="truncate text-base font-semibold text-text-primary">Professional account</p>
                  <Badge tone="warning" variant="soft" size="xs">{approval.state}</Badge>
                </div>
                <p className="mt-1 truncate text-sm text-text-tertiary">Requested by {approval.citizen_id}</p>
                <p className="mt-1 text-xs text-text-tertiary">{dateTime(approval.requested_ms, { month: 'short', day: 'numeric', year: 'numeric' })}</p>
                {approval.note ? <p className="mt-2 text-xs text-text-secondary">{approval.note}</p> : null}
              </div>
              <div className="text-right">
                <p className="text-sm font-semibold text-text-primary">Business Treasury</p>
                <p className="mt-1 text-xs text-text-tertiary">Account class</p>
              </div>
              <div className="flex items-center justify-end gap-2">
                <Button size="sm" variant="secondary" leftIcon={<Check size={14} />} onClick={() => { setSelectedApproval(approval); setDecision('approve') }}>Approve</Button>
                <Button size="sm" variant="secondary" leftIcon={<X size={14} />} onClick={() => { setSelectedApproval(approval); setDecision('reject') }}>Reject</Button>
              </div>
            </div>
          ))}
        </div>
      )}

      {selectedApproval ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4 backdrop-blur-md">
          <div className="w-full max-w-lg rounded-2xl border border-white/10 bg-surface-panel p-6 shadow-2xl">
            <div className="mb-5 flex items-center justify-between">
              <h3 className="text-xl font-semibold text-text-primary">{decision === 'approve' ? 'Approve Request' : 'Reject Request'}</h3>
              <Button size="sm" variant="ghost" leftIcon={<X size={16} />} onClick={() => setSelectedApproval(null)}>Cancel</Button>
            </div>
            <div className="mb-5 space-y-3 rounded-xl border border-white/10 bg-white/[0.02] p-4">
              <div className="flex justify-between"><span className="text-sm text-text-tertiary">Citizen</span><span className="text-sm font-semibold text-text-primary">{selectedApproval.citizen_id}</span></div>
              <div className="flex justify-between"><span className="text-sm text-text-tertiary">Class</span><span className="text-sm font-semibold text-text-primary">{selectedApproval.account_class}</span></div>
              <div className="flex justify-between"><span className="text-sm text-text-tertiary">Requested</span><span className="text-sm font-semibold text-text-primary">{dateTime(selectedApproval.requested_ms, { month: 'short', day: 'numeric' })}</span></div>
            </div>
            <div className="space-y-4">
              <Input label="Decision note" value={note} onChange={(e) => setNote(e.currentTarget.value)} placeholder="Add context to this decision" />
              <div className="flex gap-3">
                <Button size="md" variant="primary" loading={decideMutation.isPending} onClick={submitDecision} className="flex-1" leftIcon={<Clock size={14} />}>{decision === 'approve' ? 'Approve' : 'Reject'}</Button>
                <Button size="md" variant="secondary" onClick={() => setSelectedApproval(null)} className="flex-1">Cancel</Button>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  )
}
