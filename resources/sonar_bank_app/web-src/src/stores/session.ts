import { create } from 'zustand'
import { isAceGranted } from '@/lib/ace'

const LOCALE_STORAGE_KEY = 'sonar-bank:locale'
const CURRENCY_STORAGE_KEY = 'sonar-bank:currency'

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

export type BankLocale = 'en' | 'es' | 'fr' | 'de'
export type BankCurrency = 'USD' | 'EUR'

export interface BankSessionState {
  citizenId: string | null
  ibanMasked: string | null
  isFirstSession: boolean
  acePerms: AcePerm[]
  memberships: BusinessMembership[]
  onboardingCompletedAt: number | null
  locale: BankLocale
  currency: BankCurrency

  setSession: (s: Partial<BankSessionState>) => void
  setLocale: (locale: BankLocale) => void
  setCurrency: (currency: BankCurrency) => void
  hasPerm: (perm: AcePerm) => boolean
  hasMembership: (companyId: string) => BusinessMembership | undefined
  clearSession: () => void
}

function readStoredLocale(): BankLocale {
  if (typeof window === 'undefined') return 'en'
  const stored = window.localStorage.getItem(LOCALE_STORAGE_KEY)
  return stored === 'en' || stored === 'es' || stored === 'fr' || stored === 'de' ? stored : 'en'
}

function readStoredCurrency(): BankCurrency {
  if (typeof window === 'undefined') return 'USD'
  const stored = window.localStorage.getItem(CURRENCY_STORAGE_KEY)
  return stored === 'EUR' || stored === 'USD' ? stored : 'USD'
}

const initial: Pick<
  BankSessionState,
  'citizenId' | 'ibanMasked' | 'isFirstSession' | 'acePerms' | 'memberships' | 'onboardingCompletedAt' | 'locale' | 'currency'
> = {
  citizenId: null,
  ibanMasked: null,
  isFirstSession: false,
  acePerms: [],
  memberships: [],
  onboardingCompletedAt: null,
  locale: readStoredLocale(),
  currency: readStoredCurrency(),
}

export const useBankSession = create<BankSessionState>((set, get) => ({
  ...initial,
  setSession: (s) => set(s),
  setLocale: (locale) => {
    if (typeof window !== 'undefined') window.localStorage.setItem(LOCALE_STORAGE_KEY, locale)
    set({ locale })
  },
  setCurrency: (currency) => {
    if (typeof window !== 'undefined') window.localStorage.setItem(CURRENCY_STORAGE_KEY, currency)
    set({ currency })
  },
  hasPerm: (perm) => isAceGranted(get().acePerms, perm),
  hasMembership: (companyId) => get().memberships.find((m) => m.company_id === companyId),
  clearSession: () => set(initial),
}))
