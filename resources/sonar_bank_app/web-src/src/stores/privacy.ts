import { create } from 'zustand'

const STORAGE_KEY = 'sonar-bank:streamer-mode'

export interface PrivacyState {
  streamerMode: boolean
  setStreamerMode: (enabled: boolean) => void
  toggleStreamerMode: () => void
}

function readInitialStreamerMode(): boolean {
  if (typeof window === 'undefined') return true
  const stored = window.localStorage.getItem(STORAGE_KEY)
  return stored === null ? true : stored !== 'off'
}

function persistStreamerMode(enabled: boolean): void {
  if (typeof window === 'undefined') return
  window.localStorage.setItem(STORAGE_KEY, enabled ? 'on' : 'off')
}

export const usePrivacyMode = create<PrivacyState>((set) => ({
  streamerMode: readInitialStreamerMode(),
  setStreamerMode: (enabled) => {
    persistStreamerMode(enabled)
    set({ streamerMode: enabled })
  },
  toggleStreamerMode: () =>
    set((state) => {
      const next = !state.streamerMode
      persistStreamerMode(next)
      return { streamerMode: next }
    }),
}))

export function canRevealSensitive(streamerMode: boolean): boolean {
  return !streamerMode
}
