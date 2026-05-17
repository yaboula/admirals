import { useQueryClient, type UseQueryOptions } from '@tanstack/react-query'
import { useEffect } from 'react'
import { queryKeys } from '@/data/queryKeys'
import type {
  BalanceSnapshot,
  BankAppBranding,
  BankAppEconomy,
  BankAppFeatures,
  BankAppLimits,
  BankAppMeta,
  BootstrapSnapshot,
} from '@/data/contracts'
import { useBankSession } from '@/stores/session'
import { BankError } from '@/lib/bankError'
import { useWatchdog } from '@/hooks/useWatchdog'
import { useBankCallback } from '@/lib/bankQuery'
import { ACE_PERMS, acePermForCompany } from '@/lib/ace'
import { isInsideFiveMNui, isMockMode } from '@/lib/env'

const BOOTSTRAP_EVENT = 'sonar:bank:bootstrap:snapshot'
const BALANCE_EVENT = 'sonar:bank:bootstrap:balance'

export type BootstrapQueryOptions = Omit<
  UseQueryOptions<BootstrapSnapshot, BankError>,
  'queryKey' | 'queryFn'
>

export function useBootstrap(options: BootstrapQueryOptions = {}) {
  const setSession = useBankSession((s) => s.setSession)

  const query = useBankCallback<BootstrapSnapshot>(
    BOOTSTRAP_EVENT,
    queryKeys.bootstrap(),
    {},
    {
      staleTime: 25_000,
      gcTime: 5 * 60_000,
      ...options,
    },
  )

  useEffect(() => {
    const data = query.data
    if (!data) return
    const primary = data.accounts[0]
    const mockCompanyId = 'vanilla-unicorn'
    const unlockDevAccess = isMockMode() || !isInsideFiveMNui()
    setSession({
      citizenId: data.citizen_id,
      ibanMasked: primary ? maskIban(primary.iban) : null,
      ...(unlockDevAccess
        ? {
            acePerms: [
              ACE_PERMS.P01.perm,
              ACE_PERMS.P02.perm,
              ACE_PERMS.P03.perm,
              acePermForCompany('P03', mockCompanyId),
              ACE_PERMS.P04.perm,
              ACE_PERMS.P05.perm,
              acePermForCompany('P05', mockCompanyId),
              ACE_PERMS.P06.perm,
              acePermForCompany('P06', mockCompanyId),
              ACE_PERMS.P07.perm,
              ACE_PERMS.P08.perm,
              ACE_PERMS.P09.perm,
              ACE_PERMS.P10.perm,
              ACE_PERMS.P11.perm,
              ACE_PERMS.P12.perm,
            ],
            memberships: [{ company_id: mockCompanyId, role: 'owner' as const }],
          }
        : {}),
    })
  }, [query.data, setSession])

  useWatchdog(30_000, () => {
    void query.refetch()
  }, [query.data?.server_now_ms, query.data?.bootstrap_id])

  return query
}

function maskIban(iban: string | undefined | null): string {
  const compact = String(iban ?? '').replace(/\s+/g, '')
  if (compact.length < 8) return String(iban ?? '')
  return `${compact.slice(0, 4)} ···· ···· ···· ${compact.slice(-4)}`
}

export interface UseBalanceFallbackArgs {
  iban: string
  enabled?: boolean
}

export function useBalanceFallback({ iban, enabled = true }: UseBalanceFallbackArgs) {
  return useBankCallback<BalanceSnapshot, { iban: string }>(
    BALANCE_EVENT,
    queryKeys.account.balance(iban),
    { iban },
    {
      enabled: enabled && Boolean(iban),
      staleTime: 10_000,
    },
  )
}

export function useInvalidateBootstrap() {
  const qc = useQueryClient()
  return () => qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
}

export function useRefetchBootstrap() {
  const qc = useQueryClient()
  return () => qc.refetchQueries({ queryKey: queryKeys.bootstrap() })
}

// ---------------------------------------------------------------------------
// App-level meta — branding, feature flags, effective economy, hard limits.
//
// These hooks pull from bootstrap.app and fall back to sane defaults so the
// rest of the FE never has to guard against `undefined`. Backend defaults
// from Config.CustomerApp drive the values; banker overrides (if any) are
// already applied server-side.
// ---------------------------------------------------------------------------

const DEFAULT_BRANDING: BankAppBranding = {
  bank_name: 'SONAR Bank',
  short_name: 'SONAR',
  primary_color: '#FF6413',
  accent_color: '#FFB047',
  welcome_message: '',
  logo_url: '',
  support_email: '',
  support_url: '',
}

const DEFAULT_FEATURES: BankAppFeatures = {
  accounts_open: true,
  accounts_close: true,
  accounts_freeze_self: true,
  accounts_joint_owners: true,
  savings: true,
  cards_issue: true,
  cards_freeze: true,
  cards_set_limits: true,
  cards_change_pin: true,
  transfers_p2p: true,
  transfers_express: true,
  recurring: true,
  loans: true,
  investments: true,
  kyc: true,
  business_treasury: true,
  notifications: true,
  onboarding_first_run: true,
}

const DEFAULT_ECONOMY: BankAppEconomy = {
  transfer_fee_bps: null,
  daily_transfer_limit_minor: null,
  atm_fee_minor_flat: null,
  card_issue_fee_minor: null,
  savings_interest_rate_bps: null,
  loan_rate_spread_bps: null,
  shared_account_min_minor: null,
}

const DEFAULT_LIMITS: BankAppLimits = {
  transfer_min_minor: 1,
  transfer_max_minor: 999_999_999_900,
  max_recipients_saved: 50,
  max_recurring_per_account: 16,
  pin_attempts_max: 5,
  pin_attempts_window_sec: 300,
}

/** Returns the merged app meta (server data + defaults). */
export function useAppMeta(): BankAppMeta {
  const { data } = useBootstrap()
  const app = data?.app
  return {
    branding: { ...DEFAULT_BRANDING, ...(app?.branding ?? {}) },
    features: { ...DEFAULT_FEATURES, ...(app?.features ?? {}) },
    economy:  { ...DEFAULT_ECONOMY,  ...(app?.economy  ?? {}) },
    limits:   { ...DEFAULT_LIMITS,   ...(app?.limits   ?? {}) },
    resource_version: app?.resource_version ?? '',
  }
}

/** Cheap accessor: is a specific customer feature enabled? */
export function useFeatureFlag(name: keyof BankAppFeatures): boolean {
  return useAppMeta().features[name]
}
