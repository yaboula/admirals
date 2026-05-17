import { useQueryClient, type UseQueryOptions } from '@tanstack/react-query'
import type {
  AtmNuiDepositPayload,
  AtmNuiDepositResponse,
  AtmNuiWithdrawPayload,
  AtmNuiWithdrawResponse,
  AtmSessionResponse,
  AtmVerifyPinPayload,
  AtmVerifyPinResponse,
} from '@/data/contracts'
import { useBankCallback, useBankMutation } from '@/lib/bankQuery'
import { queryKeys } from '@/data/queryKeys'
import { BankError } from '@/lib/bankError'
import { useAtmTerminal } from '@/stores/atmTerminal'

const ATM_SESSION_EVENT      = 'sonar:bank:atm:session'
const ATM_VERIFY_PIN_EVENT   = 'sonar:bank:atm:verifyPin'
const ATM_NUI_WITHDRAW_EVENT = 'sonar:bank:atm:nuiWithdraw'
const ATM_NUI_DEPOSIT_EVENT  = 'sonar:bank:atm:nuiDeposit'

export type AtmSessionQueryOptions = Omit<
  UseQueryOptions<AtmSessionResponse, BankError>,
  'queryKey' | 'queryFn'
>

export function useAtmSessionQuery(options: AtmSessionQueryOptions = {}) {
  const terminal = useAtmTerminal((s) => s.terminal)
  return useBankCallback<AtmSessionResponse, Record<string, unknown>>(
    ATM_SESSION_EVENT,
    queryKeys.atm.session(),
    { terminal },
    {
      staleTime: 15_000,
      gcTime: 2 * 60_000,
      ...options,
    },
  )
}

// F06 — verifyPin mutation. On success the BE returns a 5-min grant_id that
// the FE keeps in component state and forwards into nuiWithdraw.
export function useAtmVerifyPinMutation() {
  return useBankMutation<AtmVerifyPinResponse, AtmVerifyPinPayload & Record<string, unknown>>(
    ATM_VERIFY_PIN_EVENT,
    {},
  )
}

// F06 — nuiWithdraw mutation. On success invalidate bootstrap so balances and
// card.daily_used_today refresh immediately in every screen of the app.
export function useAtmNuiWithdrawMutation() {
  const qc = useQueryClient()
  return useBankMutation<AtmNuiWithdrawResponse, AtmNuiWithdrawPayload & Record<string, unknown>>(
    ATM_NUI_WITHDRAW_EVENT,
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
  )
}

// F06 — nuiDeposit mutation. Mirror of withdraw: removes physical cash from the
// player and credits the bank balance.
export function useAtmNuiDepositMutation() {
  const qc = useQueryClient()
  return useBankMutation<AtmNuiDepositResponse, AtmNuiDepositPayload & Record<string, unknown>>(
    ATM_NUI_DEPOSIT_EVENT,
    {
      onSuccess: () => {
        void qc.invalidateQueries({ queryKey: queryKeys.bootstrap() })
      },
    },
  )
}
