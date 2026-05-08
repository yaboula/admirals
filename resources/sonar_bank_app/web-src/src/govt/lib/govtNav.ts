import {
  Building2,
  Users,
  BriefcaseBusiness,
  Coins,
  Banknote,
  Scale,
  HandCoins,
  LineChart,
  type LucideIcon,
} from 'lucide-react'
import { ACE_PERMS } from '@/lib/ace'
import type { AcePerm } from '@/stores/session'
import type { TranslationKey } from '@/lib/i18n'

export interface GovtNavItem {
  id: string
  to: string
  end?: boolean
  labelKey: TranslationKey
  descriptionKey: TranslationKey
  icon: LucideIcon
  requiredPerm: AcePerm
  comingSoon?: boolean
}

export const GOVT_NAV_ITEMS: GovtNavItem[] = [
  {
    id: 'overview',
    to: '/tesoreria',
    end: true,
    labelKey: 'govt.nav.overview',
    descriptionKey: 'govt.nav.overviewDescription',
    icon: Building2,
    requiredPerm: ACE_PERMS.P04.perm,
  },
  {
    id: 'census',
    to: '/tesoreria/censo',
    labelKey: 'govt.nav.census',
    descriptionKey: 'govt.nav.censusDescription',
    icon: Users,
    requiredPerm: ACE_PERMS.P04.perm,
  },
  {
    id: 'business',
    to: '/tesoreria/empresas',
    labelKey: 'govt.nav.business',
    descriptionKey: 'govt.nav.businessDescription',
    icon: BriefcaseBusiness,
    requiredPerm: ACE_PERMS.P04.perm,
    comingSoon: true,
  },
  {
    id: 'tax',
    to: '/tesoreria/fiscal',
    labelKey: 'govt.nav.tax',
    descriptionKey: 'govt.nav.taxDescription',
    icon: Coins,
    requiredPerm: ACE_PERMS.P11.perm,
    comingSoon: true,
  },
  {
    id: 'treasury',
    to: '/tesoreria/movimientos',
    labelKey: 'govt.nav.treasury',
    descriptionKey: 'govt.nav.treasuryDescription',
    icon: Banknote,
    requiredPerm: ACE_PERMS.P04.perm,
    comingSoon: true,
  },
  {
    id: 'sanctions',
    to: '/tesoreria/sanciones',
    labelKey: 'govt.nav.sanctions',
    descriptionKey: 'govt.nav.sanctionsDescription',
    icon: Scale,
    requiredPerm: ACE_PERMS.P10.perm,
    comingSoon: true,
  },
  {
    id: 'subsidies',
    to: '/tesoreria/subsidios',
    labelKey: 'govt.nav.subsidies',
    descriptionKey: 'govt.nav.subsidiesDescription',
    icon: HandCoins,
    requiredPerm: ACE_PERMS.P04.perm,
    comingSoon: true,
  },
  {
    id: 'reports',
    to: '/tesoreria/informes',
    labelKey: 'govt.nav.reports',
    descriptionKey: 'govt.nav.reportsDescription',
    icon: LineChart,
    requiredPerm: ACE_PERMS.P04.perm,
    comingSoon: true,
  },
]
