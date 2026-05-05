/**
 * SONAR Tablet — SFX engine (S2.6 rev3 — Web Audio API, premium sine).
 *
 * Design philosophy: Apple / Tesla UI sound class.
 *   - Pure sine oscillators only (no triangle/square — sine = clean, premium).
 *   - Very short durations (≤120ms) except panel_open (swell, ~400ms).
 *   - High fundamental frequencies (≥1000Hz) for clarity on small speakers.
 *   - Minimal gain — subtle, not intrusive.
 *   - Two-tone pairs where appropriate (Apple "double chirp" class).
 *
 * DC-S2.6.4: AudioContext lazy init on first user gesture.
 * DC-S2.6.7: Anti-spam debounce 30ms per SFX name.
 *
 * canon:
 *   console_tap   — Apple UIKeyClick class. Single sine 1400Hz, 55ms.
 *   layer_dive    — Apple page-flip class. Sine pair 1000→700Hz glide, 90ms.
 *   depth_press   — Tesla confirm class. Sine pair 1200Hz+600Hz, 120ms swell.
 *   signal_emerge — Apple Mail-send class. Two quick sines 880+1320Hz, 160ms.
 *   panel_open    — Apple Notification reveal. Sine swell 600→900Hz, 360ms.
 */

export type SfxName =
  | 'signal_emerge'
  | 'depth_press'
  | 'layer_dive'
  | 'console_tap'
  | 'panel_open'

let _ctx: AudioContext | null = null
let _masterVolume = 0.55
const _lastPlayed = new Map<SfxName, number>()
const DEBOUNCE_MS = 30

/**
 * Initialize AudioContext singleton. Call from first user gesture.
 * Idempotent — safe to call multiple times.
 */
export function initialize(): void {
  if (_ctx) return
  try {
    _ctx = new AudioContext()
  } catch {
    _ctx = null
  }
}

/**
 * Set master volume [0–1]. Default 0.55 (subtle — Apple level).
 */
export function setMasterVolume(v: number): void {
  _masterVolume = Math.max(0, Math.min(1, v))
}

function getCtx(): AudioContext | null {
  if (!_ctx) return null
  if (_ctx.state === 'suspended') void _ctx.resume()
  return _ctx
}

function debounceAllow(name: SfxName): boolean {
  const now = performance.now()
  const last = _lastPlayed.get(name) ?? 0
  if (now - last < DEBOUNCE_MS) return false
  _lastPlayed.set(name, now)
  return true
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** One sine oscillator with a simple gain envelope. Auto-stops. */
function sine(
  ctx: AudioContext,
  t: number,
  freq: number,
  peakGain: number,
  attackSec: number,
  decaySec: number,
  freqEndHz?: number,
): void {
  const g = ctx.createGain()
  g.connect(ctx.destination)
  g.gain.setValueAtTime(0, t)
  g.gain.linearRampToValueAtTime(peakGain, t + attackSec)
  g.gain.exponentialRampToValueAtTime(0.0001, t + attackSec + decaySec)

  const osc = ctx.createOscillator()
  osc.type = 'sine'
  osc.frequency.setValueAtTime(freq, t)
  if (freqEndHz !== undefined) {
    osc.frequency.exponentialRampToValueAtTime(freqEndHz, t + attackSec + decaySec)
  }
  osc.connect(g)
  osc.start(t)
  osc.stop(t + attackSec + decaySec + 0.01)
}

// ---------------------------------------------------------------------------
// 5 canonical SFX — Apple / Tesla premium sine class
// ---------------------------------------------------------------------------

/**
 * console_tap — Apple UIKeyClick class.
 * Single sine 1400Hz. Attack 2ms, decay 50ms. Total ~52ms.
 * Crisp, clean, barely-there premium tap.
 */
function playConsoleTap(ctx: AudioContext, t: number, vol: number): void {
  sine(ctx, t, 1400, 0.18 * vol, 0.002, 0.05)
}

/**
 * layer_dive — Apple page-flip class.
 * Sine glide 1000Hz → 660Hz over 80ms. Attack 5ms, decay 75ms.
 * Smooth descending tone = "diving into a layer".
 */
function playLayerDive(ctx: AudioContext, t: number, vol: number): void {
  sine(ctx, t, 1000, 0.20 * vol, 0.005, 0.075, 660)
}

/**
 * depth_press — Tesla confirm class.
 * Two simultaneous sines: 1200Hz (fundamental) + 600Hz (sub octave).
 * Attack 5ms, decay 110ms. Harmonically rich but still pure-sine premium.
 */
function playDepthPress(ctx: AudioContext, t: number, vol: number): void {
  sine(ctx, t, 1200, 0.20 * vol, 0.005, 0.11)
  sine(ctx, t, 600,  0.12 * vol, 0.005, 0.11)
}

/**
 * signal_emerge — Apple Mail-send class.
 * Two quick sequential sines: 880Hz then 1320Hz (perfect fifth up), 70ms each.
 * Second sine starts 60ms after first — "double chirp" confirm feeling.
 */
function playSignalEmerge(ctx: AudioContext, t: number, vol: number): void {
  sine(ctx, t,        880,  0.18 * vol, 0.005, 0.065)
  sine(ctx, t + 0.06, 1320, 0.18 * vol, 0.005, 0.065)
}

/**
 * panel_open — Apple Notification reveal class.
 * Sine swell 600Hz → 900Hz (rising = "opening"). Attack 35ms, decay 280ms.
 * Slightly longer and warmer — marks a significant UI moment.
 */
function playPanelOpen(ctx: AudioContext, t: number, vol: number): void {
  sine(ctx, t, 600, 0.22 * vol, 0.035, 0.28, 900)
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Play a canonical SFX. No-op if AudioContext unavailable or debounce active.
 * opts.volume: per-call multiplier [0–1] on top of master volume.
 */
export function playSfx(name: SfxName, opts?: { volume?: number }): void {
  const ctx = getCtx()
  if (!ctx) return
  if (!debounceAllow(name)) return

  const vol = (opts?.volume ?? 1) * _masterVolume
  const t = ctx.currentTime

  switch (name) {
    case 'console_tap':    playConsoleTap(ctx, t, vol);    break
    case 'layer_dive':     playLayerDive(ctx, t, vol);     break
    case 'depth_press':    playDepthPress(ctx, t, vol);    break
    case 'signal_emerge':  playSignalEmerge(ctx, t, vol);  break
    case 'panel_open':     playPanelOpen(ctx, t, vol);     break
  }
}
