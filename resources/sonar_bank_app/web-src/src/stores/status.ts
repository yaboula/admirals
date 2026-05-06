import { create } from 'zustand'

export type BridgeStatus =
  | 'native_full'
  | 'lite_mode_active'
  | 'compromised_load_order'
  | 'framework_missing'

export interface BankStatusState {
  bridgesStatus: BridgeStatus
  reasonKvp: Record<string, string>
  lastTransitionAt: number | null
  bankDisabled: boolean
  bankDisabledReason: string | null

  setStatus: (s: Partial<BankStatusState>) => void
  reset: () => void
}

const initial: Pick<
  BankStatusState,
  'bridgesStatus' | 'reasonKvp' | 'lastTransitionAt' | 'bankDisabled' | 'bankDisabledReason'
> = {
  bridgesStatus: 'native_full',
  reasonKvp: {},
  lastTransitionAt: null,
  bankDisabled: false,
  bankDisabledReason: null,
}

export const useBankStatus = create<BankStatusState>((set) => ({
  ...initial,
  setStatus: (s) => set(s),
  reset: () => set(initial),
}))
