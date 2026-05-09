import { create } from 'zustand'

const ONBOARDING_STORAGE_PREFIX = 'sonar-bank:onboarding-completed:'

export interface AuthGateState {
  unlocked: boolean
  unlock: () => void
  lock: () => void
}

function shouldBypassAuthOnFirstOpen(): boolean {
  if (typeof window === 'undefined') return false

  return !Array.from({ length: window.localStorage.length }, (_, index) => window.localStorage.key(index)).some(
    (key) => key?.startsWith(ONBOARDING_STORAGE_PREFIX) && window.localStorage.getItem(key) === 'done',
  )
}

export const useAuthGate = create<AuthGateState>((set) => ({
  unlocked: shouldBypassAuthOnFirstOpen(),
  unlock: () => set({ unlocked: true }),
  lock: () => set({ unlocked: false }),
}))
