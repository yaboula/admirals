import { useState, useMemo } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import { Users, UserPlus, Trash2, ShieldCheck, X, ChevronDown } from 'lucide-react'
import { useBankerBootstrap, useBankerEmployees, useBankerHire, useBankerFire, useBankerSetRole } from '../data/queries'
import { BANKER_ROLE_ORDER, type BankerRole, type BankerEmployee } from '../data/contracts'

export function BankerEmployees() {
  const bootstrap = useBankerBootstrap()
  const employees = useBankerEmployees({ status: 'active' })
  const [hireOpen, setHireOpen] = useState(false)

  const caps = bootstrap.data?.capabilities
  const canHire = !!caps?.employees_hire
  const canFire = !!caps?.employees_fire
  const canSetRole = !!caps?.employees_set_role

  const items = employees.data?.items ?? []

  return (
    <div className="px-8 py-7 space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <p className="text-[11px] uppercase tracking-[0.22em] text-text-tertiary">Recursos humanos</p>
          <h1 className="mt-1 text-2xl font-semibold text-text-primary">Empleados del banco</h1>
          <p className="mt-1 text-sm text-text-tertiary">
            {items.length} activos · roles asignados según jerarquía SONAR
          </p>
        </div>
        {canHire && (
          <button
            onClick={() => setHireOpen(true)}
            className="flex items-center gap-2 rounded-xl border border-white/10 px-4 py-2.5 text-sm font-semibold text-black transition hover:opacity-95"
            style={{ background: 'var(--banker-primary)' }}
          >
            <UserPlus size={16} />
            Contratar
          </button>
        )}
      </div>

      {/* List */}
      {employees.isLoading && <SkeletonList />}
      {employees.isError && (
        <div className="rounded-2xl border border-red-500/25 bg-red-500/[0.04] p-5 text-sm text-red-300">
          {employees.error?.message ?? 'Error cargando empleados'}
        </div>
      )}

      {!employees.isLoading && !employees.isError && (
        <div className="space-y-2.5">
          <AnimatePresence initial={false}>
            {items.map((emp) => (
              <EmployeeRow
                key={emp.id}
                employee={emp}
                canFire={canFire}
                canSetRole={canSetRole}
              />
            ))}
          </AnimatePresence>
          {items.length === 0 && (
            <div className="rounded-2xl border border-white/10 bg-white/[0.025] p-10 text-center">
              <Users size={28} className="mx-auto text-text-tertiary" />
              <p className="mt-3 text-sm font-semibold text-text-primary">Sin empleados activos</p>
              <p className="mt-1 text-xs text-text-tertiary">
                Contrata el primer miembro del staff para empezar a operar.
              </p>
            </div>
          )}
        </div>
      )}

      {/* Hire dialog */}
      <AnimatePresence>
        {hireOpen && <HireDialog onClose={() => setHireOpen(false)} />}
      </AnimatePresence>
    </div>
  )
}

function EmployeeRow({
  employee,
  canFire,
  canSetRole,
}: {
  employee: BankerEmployee
  canFire: boolean
  canSetRole: boolean
}) {
  const fire = useBankerFire()
  const setRole = useBankerSetRole()
  const [confirmFire, setConfirmFire] = useState(false)
  const [roleOpen, setRoleOpen] = useState(false)

  const salaryDisplay = useMemo(
    () => `$${(employee.salary_minor / 100).toLocaleString(undefined, { minimumFractionDigits: 2 })}`,
    [employee.salary_minor],
  )
  const hiredDisplay = employee.hired_at
    ? new Date(employee.hired_at * 1000).toLocaleDateString()
    : '—'

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -6 }}
      transition={{ duration: 0.18 }}
      className="rounded-2xl border border-white/10 bg-white/[0.025] p-4 hover:bg-white/[0.04]"
    >
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-3 min-w-0">
          <div
            className="flex h-11 w-11 items-center justify-center rounded-xl text-xs font-semibold text-white uppercase"
            style={{
              background:
                'linear-gradient(135deg, var(--banker-primary), var(--banker-accent))',
            }}
          >
            {(employee.role_label ?? employee.role).slice(0, 2)}
          </div>
          <div className="min-w-0">
            <p className="text-sm font-semibold text-text-primary truncate">
              {employee.role_label ?? employee.role}
            </p>
            <p className="text-xs text-text-tertiary font-mono truncate">
              {employee.citizen_id} · contratado {hiredDisplay}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          <div className="hidden md:block text-right">
            <p className="text-[10px] uppercase tracking-wider text-text-tertiary">Salario</p>
            <p className="text-sm font-semibold text-text-primary">{salaryDisplay}/sem</p>
          </div>

          {canSetRole && (
            <div className="relative">
              <button
                onClick={() => setRoleOpen((v) => !v)}
                className="flex items-center gap-1.5 rounded-lg border border-white/10 bg-white/[0.03] px-3 py-2 text-xs text-text-secondary hover:bg-white/[0.06]"
              >
                <ShieldCheck size={13} />
                Rol
                <ChevronDown size={12} />
              </button>
              {roleOpen && (
                <div className="absolute right-0 top-full mt-1.5 z-10 w-48 rounded-xl border border-white/10 bg-[rgba(8,8,12,0.98)] p-1 shadow-2xl">
                  {BANKER_ROLE_ORDER.map((role) => (
                    <button
                      key={role}
                      onClick={() => {
                        setRoleOpen(false)
                        if (role !== employee.role) {
                          setRole.mutate({ employee_id: employee.id, new_role: role })
                        }
                      }}
                      className={`flex w-full items-center justify-between rounded-lg px-3 py-1.5 text-left text-xs hover:bg-white/[0.05] ${role === employee.role ? 'text-[var(--banker-primary)]' : 'text-text-secondary'}`}
                    >
                      <span>{role}</span>
                      {role === employee.role && <span className="text-[10px]">actual</span>}
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}

          {canFire && (
            <button
              onClick={() => setConfirmFire(true)}
              disabled={fire.isPending}
              className="flex h-9 w-9 items-center justify-center rounded-lg border border-red-500/25 bg-red-500/[0.04] text-red-300 hover:bg-red-500/[0.1] disabled:opacity-50"
            >
              <Trash2 size={14} />
            </button>
          )}
        </div>
      </div>

      <AnimatePresence>
        {confirmFire && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="mt-3 rounded-xl border border-red-500/25 bg-red-500/[0.04] p-3"
          >
            <p className="text-xs text-red-300">
              ¿Despedir a <span className="font-mono">{employee.citizen_id}</span>? El audit log
              registrará al actor.
            </p>
            <div className="mt-2 flex justify-end gap-2">
              <button
                onClick={() => setConfirmFire(false)}
                className="rounded-lg border border-white/10 px-3 py-1 text-xs text-text-secondary hover:bg-white/[0.05]"
              >
                Cancelar
              </button>
              <button
                onClick={() => {
                  fire.mutate({ employee_id: employee.id, reason: 'Despido vía panel' })
                  setConfirmFire(false)
                }}
                className="rounded-lg bg-red-500 px-3 py-1 text-xs font-semibold text-white hover:bg-red-400"
              >
                Despedir
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  )
}

function HireDialog({ onClose }: { onClose: () => void }) {
  const hire = useBankerHire()
  const [form, setForm] = useState<{ citizen: string; role: BankerRole; notes: string }>({
    citizen: '',
    role: 'teller',
    notes: '',
  })
  const [error, setError] = useState<string | null>(null)

  const submit = async () => {
    setError(null)
    if (!form.citizen.trim()) {
      setError('Citizen ID requerido')
      return
    }
    try {
      await hire.mutateAsync({
        target_citizen_id: form.citizen.trim(),
        role: form.role,
        notes: form.notes || undefined,
      })
      onClose()
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Error al contratar'
      setError(msg)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-6"
    >
      <motion.div
        initial={{ scale: 0.96, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.96, opacity: 0 }}
        className="w-full max-w-md rounded-3xl border border-white/10 bg-[rgba(10,10,14,0.98)] p-6"
      >
        <div className="flex items-center justify-between">
          <div>
            <p className="text-[11px] uppercase tracking-[0.22em] text-text-tertiary">RH</p>
            <h2 className="mt-1 text-lg font-semibold text-text-primary">Contratar empleado</h2>
          </div>
          <button
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-lg border border-white/10 text-text-secondary hover:bg-white/[0.05]"
          >
            <X size={14} />
          </button>
        </div>

        <div className="mt-5 space-y-4">
          <Field label="Citizen ID">
            <input
              autoFocus
              value={form.citizen}
              onChange={(e) => setForm((f) => ({ ...f, citizen: e.target.value }))}
              placeholder="HMC53829"
              className="w-full rounded-xl border border-white/10 bg-black/40 px-3.5 py-2.5 font-mono text-sm text-text-primary placeholder:text-text-tertiary focus:border-[var(--banker-primary)] focus:outline-none"
            />
          </Field>

          <Field label="Rol">
            <div className="grid grid-cols-3 gap-1.5">
              {BANKER_ROLE_ORDER.map((role) => (
                <button
                  key={role}
                  onClick={() => setForm((f) => ({ ...f, role }))}
                  className={`rounded-lg border px-2.5 py-2 text-xs font-medium transition ${
                    form.role === role
                      ? 'border-[var(--banker-primary)] bg-[rgba(255,100,19,0.08)] text-[var(--banker-primary)]'
                      : 'border-white/10 bg-white/[0.025] text-text-secondary hover:bg-white/[0.05]'
                  }`}
                >
                  {role}
                </button>
              ))}
            </div>
          </Field>

          <Field label="Notas (opcional)">
            <textarea
              value={form.notes}
              onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))}
              rows={2}
              className="w-full rounded-xl border border-white/10 bg-black/40 px-3.5 py-2.5 text-sm text-text-primary focus:border-[var(--banker-primary)] focus:outline-none"
            />
          </Field>

          {error && (
            <div className="rounded-lg border border-red-500/25 bg-red-500/[0.04] px-3 py-2 text-xs text-red-300">
              {error}
            </div>
          )}
        </div>

        <div className="mt-6 flex justify-end gap-2">
          <button
            onClick={onClose}
            className="rounded-xl border border-white/10 px-4 py-2 text-sm text-text-secondary hover:bg-white/[0.05]"
          >
            Cancelar
          </button>
          <button
            onClick={submit}
            disabled={hire.isPending}
            className="rounded-xl px-4 py-2 text-sm font-semibold text-black hover:opacity-95 disabled:opacity-60"
            style={{ background: 'var(--banker-primary)' }}
          >
            {hire.isPending ? 'Contratando…' : 'Contratar'}
          </button>
        </div>
      </motion.div>
    </motion.div>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="mb-1.5 block text-[11px] uppercase tracking-[0.18em] text-text-tertiary">
        {label}
      </label>
      {children}
    </div>
  )
}

function SkeletonList() {
  return (
    <div className="space-y-2.5">
      {[0, 1, 2].map((i) => (
        <div key={i} className="h-[72px] animate-pulse rounded-2xl border border-white/10 bg-white/[0.02]" />
      ))}
    </div>
  )
}
