import { create } from 'zustand'

export interface AtmTerminalInfo {
  entity_net_id?: number
  model_hash?: number
  coords?: { x: number; y: number; z: number }
}

interface AtmTerminalState {
  terminal: AtmTerminalInfo | null
  setTerminal: (t: AtmTerminalInfo | null) => void
}

export const useAtmTerminal = create<AtmTerminalState>((set) => ({
  terminal: null,
  setTerminal: (terminal) => set({ terminal }),
}))
