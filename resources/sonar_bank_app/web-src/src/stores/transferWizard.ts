import { create } from 'zustand'
import { createBankOperationIds } from '@/lib/bankIdempotency'

export type TransferWizardStep = 'amount' | 'recipient' | 'review' | 'confirm'

export interface TransferWizardState {
  step: TransferWizardStep
  expressMode: boolean
  idempotencyKey: string | null
  correlationId: string | null
  amount: number | null
  memo: string
  recipientIban: string | null
  recipientAlias: string | null

  init: (express?: boolean) => void
  setStep: (step: TransferWizardStep) => void
  setExpressMode: (v: boolean) => void
  setAmount: (amount: number, memo?: string) => void
  setDraftAmount: (amount: number | null) => void
  setMemo: (memo: string) => void
  setRecipient: (iban: string, alias?: string | null) => void
  clearOperationIds: () => void
  reset: () => void
}

const initial: Omit<
  TransferWizardState,
  'init' | 'setStep' | 'setExpressMode' | 'setAmount' | 'setDraftAmount' | 'setMemo' | 'setRecipient' | 'clearOperationIds' | 'reset'
> = {
  step: 'amount',
  expressMode: false,
  idempotencyKey: null,
  correlationId: null,
  amount: null,
  memo: '',
  recipientIban: null,
  recipientAlias: null,
}

export const useTransferWizard = create<TransferWizardState>((set) => ({
  ...initial,
  init: (express = false) =>
    set(() => {
      const ids = createBankOperationIds()
      return {
        step: 'amount',
        expressMode: express,
        idempotencyKey: ids.idempotencyKey,
        correlationId: ids.correlationId,
        amount: null,
        memo: '',
        recipientIban: null,
        recipientAlias: null,
      }
    }),
  setStep: (step) => set({ step }),
  setExpressMode: (v) => set({ expressMode: v }),
  setAmount: (amount, memo) => set({ amount, memo: memo ?? '' }),
  setDraftAmount: (amount) => set({ amount }),
  setMemo: (memo) => set({ memo }),
  setRecipient: (iban, alias) => set({ recipientIban: iban, recipientAlias: alias ?? null }),
  clearOperationIds: () => set({ idempotencyKey: null, correlationId: null }),
  reset: () => set(initial),
}))
