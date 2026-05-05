/**
 * SONAR Tablet — useGpsStream hook (S2.5).
 *
 * Suscribe a NUI messages `sonar:tablet:map:gpsUpdate` + expone `GpsState`
 * reactivo throttled a ≤30fps via requestAnimationFrame (DC7a: marker smooth
 * sin saturar React render loop).
 *
 * Stale detection: si no hay updates >3s → status 'stale' (UI badge + opacity
 * per spec).
 *
 * Cleanup listeners + rAF + timer al unmount (strict mode + resource stop
 * safe).
 */
import { useEffect, useRef, useState } from 'react'
import { useNUIBridge } from '@/hooks/useNUIBridge'
import type { NUIMapGpsUpdateMessage } from '@/types/nui'
import type { GpsState } from '../types'

const STALE_MS = 3000
const STALE_CHECK_INTERVAL_MS = 500

export type GpsStatus = 'idle' | 'live' | 'stale'

export interface UseGpsStreamResult {
  gps: GpsState | null
  status: GpsStatus
}

export function useGpsStream(): UseGpsStreamResult {
  const [gps, setGps] = useState<GpsState | null>(null)
  const [status, setStatus] = useState<GpsStatus>('idle')

  // Último payload recibido pending commit via rAF (throttle 1 render/frame).
  const pendingRef = useRef<GpsState | null>(null)
  const rafRef = useRef<number | null>(null)
  const lastUpdateRef = useRef<number>(0)

  // Suscripción NUI — ignora messages que no sean gpsUpdate.
  useNUIBridge<NUIMapGpsUpdateMessage>((msg) => {
    if (msg.action !== 'sonar:tablet:map:gpsUpdate') return
    const p = msg.payload
    if (!p || typeof p.x !== 'number' || typeof p.y !== 'number') return

    const now = Date.now()
    pendingRef.current = {
      world_x:    p.x,
      world_y:    p.y,
      heading:    p.heading,
      speed:      p.speed,
      ts:         p.ts,
      updated_at: now,
    }
    lastUpdateRef.current = now

    // Si ya hay rAF scheduled, deja que éste consuma pending — coalesces
    // múltiples updates dentro del mismo frame (DC7a ≥30fps hard cap).
    if (rafRef.current != null) return
    rafRef.current = requestAnimationFrame(() => {
      rafRef.current = null
      if (pendingRef.current) {
        setGps(pendingRef.current)
        setStatus('live')
      }
    })
  })

  // Stale watchdog — revisa cada 500ms si last update >3s atrás.
  useEffect(() => {
    const id = window.setInterval(() => {
      if (lastUpdateRef.current === 0) return
      const gap = Date.now() - lastUpdateRef.current
      if (gap > STALE_MS) {
        setStatus((prev) => (prev === 'stale' ? prev : 'stale'))
      }
    }, STALE_CHECK_INTERVAL_MS)
    return () => window.clearInterval(id)
  }, [])

  // Cleanup rAF al unmount.
  useEffect(() => {
    return () => {
      if (rafRef.current != null) {
        cancelAnimationFrame(rafRef.current)
        rafRef.current = null
      }
    }
  }, [])

  return { gps, status }
}
