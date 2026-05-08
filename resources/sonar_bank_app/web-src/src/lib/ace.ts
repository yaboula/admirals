import type { AcePerm } from '@/stores/session'

export type AcePermCode =
  | 'P01'
  | 'P02'
  | 'P03'
  | 'P04'
  | 'P05'
  | 'P06'
  | 'P07'
  | 'P08'
  | 'P09'
  | 'P10'
  | 'P11'
  | 'P12'

export interface AcePermDefinition {
  code: AcePermCode
  perm: AcePerm
  description: string
  surfaces: string[]
}

export const ACE_PERMS = {
  P01: {
    code: 'P01',
    perm: 'sonar.bank.player',
    description: 'Baseline bank player access',
    surfaces: ['Bank app launch'],
  },
  P02: {
    code: 'P02',
    perm: 'sonar.bank.audit.self',
    description: 'Own audit access',
    surfaces: ['Audit V4 Mis cuentas'],
  },
  P03: {
    code: 'P03',
    perm: 'sonar.bank.empresas.*',
    description: 'Business audit access by company',
    surfaces: ['Audit V4 Mis empresas', 'Empresas audit panel'],
  },
  P04: {
    code: 'P04',
    perm: 'sonar.bank.govt.audit.full',
    description: 'Government full audit access',
    surfaces: ['Audit V4 Todas govt', 'Government Audit Full'],
  },
  P05: {
    code: 'P05',
    perm: 'sonar.bank.business.payroll.*',
    description: 'Business payroll execution by company',
    surfaces: ['Empresas payroll CTA', 'Payroll Batch'],
  },
  P06: {
    code: 'P06',
    perm: 'sonar.bank.business.approval.*',
    description: 'Business approvals by company',
    surfaces: ['Empresas pending approvals', 'Approval actions'],
  },
  P07: {
    code: 'P07',
    perm: 'sonar.bank.govt.loan.admin',
    description: 'Government loan administration',
    surfaces: ['Government loan write-off'],
  },
  P08: {
    code: 'P08',
    perm: 'sonar.bank.govt.elections.admin',
    description: 'Government election administration',
    surfaces: ['Government election phase controls'],
  },
  P09: {
    code: 'P09',
    perm: 'sonar.bank.govt.escrow.admin',
    description: 'Government escrow administration',
    surfaces: ['Government escrow refund', 'Government escrow dispute'],
  },
  P10: {
    code: 'P10',
    perm: 'sonar.bank.govt.compliance.admin',
    description: 'Compliance administration',
    surfaces: ['Compliance admin tab', 'Resolve flag', 'Manual raise'],
  },
  P11: {
    code: 'P11',
    perm: 'sonar.bank.govt.tax.write',
    description: 'Government tax write access',
    surfaces: ['Government tax edit', 'Government tax save'],
  },
  P12: {
    code: 'P12',
    perm: 'sonar.bank.govt.physical_card.admin',
    description: 'Government physical card administration',
    surfaces: ['Government card freeze'],
  },
} satisfies Record<AcePermCode, AcePermDefinition>

export function acePermForCompany(code: 'P03' | 'P05' | 'P06', companyId: string): AcePerm {
  if (code === 'P03') return `sonar.bank.empresas.${companyId}`
  if (code === 'P05') return `sonar.bank.business.payroll.${companyId}`
  return `sonar.bank.business.approval.${companyId}`
}

export function isAceGranted(ownedPerms: readonly AcePerm[], required: AcePerm): boolean {
  if (required === ACE_PERMS.P01.perm) return true
  return ownedPerms.some((owned) => owned === required || aceWildcardMatches(owned, required))
}

function aceWildcardMatches(owned: AcePerm, required: AcePerm): boolean {
  if (owned.endsWith('.*') && required.startsWith(owned.slice(0, -1))) return true
  if (required.endsWith('.*') && owned.startsWith(required.slice(0, -1))) return true
  return false
}

export function areAllAceGranted(ownedPerms: readonly AcePerm[], required: readonly AcePerm[]): boolean {
  return required.every((perm) => isAceGranted(ownedPerms, perm))
}

export function isAnyAceGranted(ownedPerms: readonly AcePerm[], required: readonly AcePerm[]): boolean {
  return required.some((perm) => isAceGranted(ownedPerms, perm))
}
