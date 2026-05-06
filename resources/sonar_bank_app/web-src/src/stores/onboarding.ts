import { create } from 'zustand'

export type OnboardingStep = 1 | 2 | 3

export interface OnboardingState {
  step: OnboardingStep
  completed: boolean
  skipped: boolean
  active: boolean

  start: () => void
  next: () => void
  skipStep: () => void
  skipAll: () => void
  finish: () => void
  reset: () => void
}

const initial: Pick<OnboardingState, 'step' | 'completed' | 'skipped' | 'active'> = {
  step: 1,
  completed: false,
  skipped: false,
  active: false,
}

export const useOnboarding = create<OnboardingState>((set) => ({
  ...initial,
  start: () => set({ step: 1, active: true, completed: false, skipped: false }),
  next: () =>
    set((s) => {
      if (s.step >= 3) return { ...s, completed: true, active: false }
      return { ...s, step: (s.step + 1) as OnboardingStep }
    }),
  skipStep: () =>
    set((s) => {
      if (s.step >= 3) return { ...s, completed: true, active: false }
      return { ...s, step: (s.step + 1) as OnboardingStep }
    }),
  skipAll: () => set({ ...initial, completed: true, skipped: true, active: false }),
  finish: () => set({ ...initial, completed: true, active: false }),
  reset: () => set(initial),
}))
