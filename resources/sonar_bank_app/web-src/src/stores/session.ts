import { create } from 'zustand'

export type AcePerm =
  | 'sonar.bank.player'
  | 'sonar.bank.audit.self'
  | `sonar.bank.empresas.${string}`
  | 'sonar.bank.govt.audit.full'
  | `sonar.bank.business.payroll.${string}`
  | `sonar.bank.business.approval.${string}`
  | 'sonar.bank.govt.loan.admin'
  | 'sonar.bank.govt.elections.admin'
  | 'sonar.bank.govt.escrow.admin'
  | 'sonar.bank.govt.compliance.admin'
  | 'sonar.bank.govt.tax.write'
  | 'sonar.bank.govt.physical_card.admin'

export interface BusinessMembership {
  company_id: string
  role: 'owner' | 'manager' | 'employee'
}

export interface BankSessionState {
  citizenId: string | null
  ibanMasked: string | null
  isFirstSession: boolean
  acePerms: AcePerm[]
  memberships: BusinessMembership[]
  onboardingCompletedAt: number | null
  locale: 'es' | 'en' | 'fr' | 'de'

  setSession: (s: Partial<BankSessionState>) => void
  setLocale: (locale: BankSessionState['locale']) => void
  hasPerm: (perm: AcePerm) => boolean
  hasMembership: (companyId: string) => BusinessMembership | undefined
  clearSession: () => void
}

const initial: Pick<
  BankSessionState,
  'citizenId' | 'ibanMasked' | 'isFirstSession' | 'acePerms' | 'memberships' | 'onboardingCompletedAt' | 'locale'
> = {
  citizenId: null,
  ibanMasked: null,
  isFirstSession: false,
  acePerms: [],
  memberships: [],
  onboardingCompletedAt: null,
  locale: 'es',
}

export const useBankSession = create<BankSessionState>((set, get) => ({
  ...initial,
  setSession: (s) => set(s),
  setLocale: (locale) => set({ locale }),
  hasPerm: (perm) => get().acePerms.includes(perm),
  hasMembership: (companyId) => get().memberships.find((m) => m.company_id === companyId),
  clearSession: () => set(initial),
}))
