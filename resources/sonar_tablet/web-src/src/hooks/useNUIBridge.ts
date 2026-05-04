/**
 * SONAR Tablet — useNUIBridge hook.
 *
 * Primitive más bajo del NUI bridge (Lua → NUI side). FiveM inyecta mensajes
 * vía `SendNUIMessage(...)` que llegan al React runtime como
 * `window.addEventListener('message', ...)`.
 *
 * Composable: `useTabletVisibility`, `useNUINotifications` (S2.6+), etc.
 * construyen sobre este hook filtrando por `action`.
 */
import { useEffect } from 'react'
import type { NUIMessage } from '@/types/nui'

/**
 * Suscribe `handler` a mensajes NUI entrantes (Lua → NUI).
 *
 * @param handler callback invocado con el evento tipado. Ignora mensajes sin
 *                forma `{ action: string }` (defensivo contra postMessage
 *                cross-origin u otras sources).
 */
export function useNUIBridge<T extends NUIMessage>(
  handler: (message: T) => void,
): void {
  useEffect(() => {
    function onMessage(event: MessageEvent<T>) {
      const data = event.data
      if (!data || typeof data !== 'object' || typeof data.action !== 'string') return
      handler(data)
    }
    window.addEventListener('message', onMessage)
    return () => window.removeEventListener('message', onMessage)
  }, [handler])
}
