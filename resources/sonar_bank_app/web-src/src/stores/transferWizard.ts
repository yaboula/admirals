import { create } from 'zustand'
import { generateUuidV4 } from '@/lib/utils'

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
  setRecipient: (iban: string, alias?: string | null) => void
  reset: () => void
}

const initial: Omit<
  TransferWizardState,
  'init' | 'setStep' | 'setExpressMode' | 'setAmount' | 'setRecipient' | 'reset'
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
    set({
      step: 'amount',
      expressMode: express,
      idempotencyKey: generateUuidV4(),
      correlationId: generateUuidV4(),
      amount: null,
      memo: '',
      recipientIban: null,
      recipientAlias: null,
    }),
  setStep: (step) => set({ step }),
  setExpressMode: (v) => set({ expressMode: v }),
  setAmount: (amount, memo) => set({ amount, memo: memo ?? '' }),
  setRecipient: (iban, alias) => set({ recipientIban: iban, recipientAlias: alias ?? null }),
  reset: () => set(initial),
}))
