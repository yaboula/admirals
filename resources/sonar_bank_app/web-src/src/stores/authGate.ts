import { create } from 'zustand'

export interface AuthGateState {
  unlocked: boolean
  unlock: () => void
  lock: () => void
}

export const useAuthGate = create<AuthGateState>((set) => ({
  unlocked: false,
  unlock: () => set({ unlocked: true }),
  lock: () => set({ unlocked: false }),
}))
