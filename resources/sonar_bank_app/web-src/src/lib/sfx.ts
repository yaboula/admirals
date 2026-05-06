/* ============================================================================
   SFX library — ADR-017 §6 + C-FE-02 §6 — 7 SFX canonical
   5 Tablet inherited (S-01..S-05) + 2 Bank-specific NEW (S-06 coin_clink + S-07 vault_close)
   Concurrency cap 5 simultaneous. Mute toggle persisted localStorage.
   prefers-reduced-motion → 50% volume reduction (informational beep retained).
   ============================================================================ */

type SfxName =
  | 'console_tap'
  | 'layer_dive'
  | 'depth_press'
  | 'signal_emerge'
  | 'panel_open'
  | 'coin_clink'
  | 'vault_close'

interface SfxOptions {
  volume?: number
  delayMs?: number
}

const STORAGE_KEY_MUTED = 'sonar_bank_sfx_muted'
const CONCURRENCY_CAP = 5
const DEBOUNCE_MS = 30

let audioCtx: AudioContext | null = null
let activeNodes = 0
const lastTriggerByName = new Map<SfxName, number>()

const isReducedMotion = (): boolean => {
  if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return false
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

const isMuted = (): boolean => {
  try {
    return typeof localStorage !== 'undefined' && localStorage.getItem(STORAGE_KEY_MUTED) === 'true'
  } catch {
    return false
  }
}

const getCtx = (): AudioContext | null => {
  if (audioCtx) return audioCtx
  if (typeof window === 'undefined') return null
  const Ctor: typeof AudioContext | undefined =
    window.AudioContext ??
    (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext
  if (!Ctor) return null
  try {
    audioCtx = new Ctor()
    return audioCtx
  } catch {
    return null
  }
}

const resolveVolume = (base: number, override?: number): number => {
  let v = override ?? base
  if (isReducedMotion()) v *= 0.5
  return v
}

const releaseSlot = (): void => {
  activeNodes = Math.max(0, activeNodes - 1)
}

const playTone = (params: {
  freq: number
  duration: number
  volume: number
  attackMs?: number
  decayCurve?: 'linear' | 'exp'
  startAt?: number
}): boolean => {
  const ctx = getCtx()
  if (!ctx) return false
  if (activeNodes >= CONCURRENCY_CAP) return false

  const start = ctx.currentTime + (params.startAt ?? 0)
  const osc = ctx.createOscillator()
  const gain = ctx.createGain()
  osc.type = 'sine'
  osc.frequency.value = params.freq
  osc.connect(gain)
  gain.connect(ctx.destination)

  const attackS = (params.attackMs ?? 5) / 1000
  const durationS = params.duration / 1000

  gain.gain.setValueAtTime(0.00001, start)
  gain.gain.linearRampToValueAtTime(params.volume, start + attackS)
  if (params.decayCurve === 'linear') {
    gain.gain.linearRampToValueAtTime(0.00001, start + durationS)
  } else {
    gain.gain.exponentialRampToValueAtTime(0.00001, start + durationS)
  }

  activeNodes++
  osc.start(start)
  osc.stop(start + durationS + 0.05)
  osc.onended = releaseSlot
  return true
}

const playGlide = (params: {
  fromFreq: number
  toFreq: number
  duration: number
  volume: number
  attackMs?: number
  startAt?: number
}): boolean => {
  const ctx = getCtx()
  if (!ctx) return false
  if (activeNodes >= CONCURRENCY_CAP) return false

  const start = ctx.currentTime + (params.startAt ?? 0)
  const osc = ctx.createOscillator()
  const gain = ctx.createGain()
  osc.type = 'sine'
  osc.frequency.setValueAtTime(params.fromFreq, start)
  osc.frequency.exponentialRampToValueAtTime(params.toFreq, start + params.duration / 1000)
  osc.connect(gain)
  gain.connect(ctx.destination)

  const attackS = (params.attackMs ?? 5) / 1000
  const durationS = params.duration / 1000
  gain.gain.setValueAtTime(0.00001, start)
  gain.gain.linearRampToValueAtTime(params.volume, start + attackS)
  gain.gain.exponentialRampToValueAtTime(0.00001, start + durationS)

  activeNodes++
  osc.start(start)
  osc.stop(start + durationS + 0.05)
  osc.onended = releaseSlot
  return true
}

const tryFire = (name: SfxName, fn: () => void, options?: SfxOptions): void => {
  if (isMuted()) return

  const now = performance.now()
  const last = lastTriggerByName.get(name) ?? 0
  if (now - last < DEBOUNCE_MS) return
  lastTriggerByName.set(name, now)

  if (options?.delayMs && options.delayMs > 0) {
    window.setTimeout(fn, options.delayMs)
  } else {
    fn()
  }
}

const sfxImpl = {
  console_tap: (opts?: SfxOptions): void => {
    tryFire('console_tap', () => {
      playTone({
        freq: 1400,
        duration: 55,
        volume: resolveVolume(0.10, opts?.volume),
        attackMs: 5,
        decayCurve: 'exp',
      })
    }, opts)
  },

  layer_dive: (opts?: SfxOptions): void => {
    tryFire('layer_dive', () => {
      playGlide({
        fromFreq: 1000,
        toFreq: 660,
        duration: 90,
        volume: resolveVolume(0.10, opts?.volume),
        attackMs: 8,
      })
    }, opts)
  },

  depth_press: (opts?: SfxOptions): void => {
    tryFire('depth_press', () => {
      const v = resolveVolume(0.12, opts?.volume)
      playTone({ freq: 1200, duration: 120, volume: v, attackMs: 8, decayCurve: 'exp' })
      playTone({ freq: 600, duration: 120, volume: v * 0.7, attackMs: 10, decayCurve: 'exp' })
    }, opts)
  },

  signal_emerge: (opts?: SfxOptions): void => {
    tryFire('signal_emerge', () => {
      const v = resolveVolume(0.12, opts?.volume)
      playTone({ freq: 880, duration: 80, volume: v, attackMs: 6, decayCurve: 'exp' })
      playTone({ freq: 1320, duration: 100, volume: v * 0.8, attackMs: 6, decayCurve: 'exp', startAt: 0.06 })
    }, opts)
  },

  panel_open: (opts?: SfxOptions): void => {
    tryFire('panel_open', () => {
      playGlide({
        fromFreq: 600,
        toFreq: 900,
        duration: 360,
        volume: resolveVolume(0.10, opts?.volume),
        attackMs: 20,
      })
    }, opts)
  },

  coin_clink: (opts?: SfxOptions): void => {
    tryFire('coin_clink', () => {
      const v = resolveVolume(0.13, opts?.volume)
      playTone({ freq: 2000, duration: 75, volume: v, attackMs: 2, decayCurve: 'exp' })
      playTone({ freq: 2400, duration: 70, volume: v * 0.85, attackMs: 2, decayCurve: 'exp', startAt: 0.015 })
    }, opts)
  },

  vault_close: (opts?: SfxOptions): void => {
    tryFire('vault_close', () => {
      const v = resolveVolume(0.13, opts?.volume)
      playGlide({
        fromFreq: 800,
        toFreq: 400,
        duration: 200,
        volume: v,
        attackMs: 10,
      })
      playTone({ freq: 200, duration: 220, volume: v * 0.6, attackMs: 15, decayCurve: 'exp' })
    }, opts)
  },

  setMuted: (muted: boolean): void => {
    try {
      if (typeof localStorage !== 'undefined') {
        if (muted) localStorage.setItem(STORAGE_KEY_MUTED, 'true')
        else localStorage.removeItem(STORAGE_KEY_MUTED)
      }
    } catch {
      /* swallow storage errors */
    }
  },

  getMuted: (): boolean => isMuted(),
}

export const sfx = sfxImpl
export type { SfxName, SfxOptions }
