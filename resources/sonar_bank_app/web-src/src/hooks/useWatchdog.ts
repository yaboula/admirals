import { useEffect, useRef } from 'react'

export function useWatchdog(intervalMs: number, fallback: () => void, deps: readonly unknown[]): void {
  const fallbackRef = useRef(fallback)
  const lastUpdateRef = useRef(Date.now())

  useEffect(() => {
    fallbackRef.current = fallback
  }, [fallback])

  useEffect(() => {
    lastUpdateRef.current = Date.now()
  }, deps)

  useEffect(() => {
    if (intervalMs <= 0) return undefined

    const id = window.setInterval(() => {
      const elapsed = Date.now() - lastUpdateRef.current
      if (elapsed > intervalMs) {
        fallbackRef.current()
        lastUpdateRef.current = Date.now()
      }
    }, Math.max(1000, intervalMs / 2))

    return () => window.clearInterval(id)
  }, [intervalMs])
}
