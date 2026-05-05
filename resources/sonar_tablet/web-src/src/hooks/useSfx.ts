/**
 * SONAR Tablet — useSfx hook (S2.6).
 *
 * Thin wrapper over lib/sfx singleton. Registers AudioContext initialization
 * on first user interaction (capture-phase click) per browser autoplay policy
 * (DC-S2.6.4).
 *
 * Usage:
 *   const { play } = useSfx()
 *   play('console_tap')
 */
import { useEffect } from 'react'
import { initialize, playSfx, setMasterVolume } from '@/lib/sfx'
import type { SfxName } from '@/lib/sfx'

export function useSfx() {
  useEffect(() => {
    // Register lazy AudioContext init on first user interaction.
    // { once: true } ensures the listener auto-removes after first fire.
    document.addEventListener('click', initialize, { once: true, capture: true })
    return () => {
      document.removeEventListener('click', initialize, { capture: true })
    }
  }, [])

  return {
    play: (name: SfxName, opts?: { volume?: number }) => playSfx(name, opts),
    initialize,
    setMasterVolume,
  }
}
