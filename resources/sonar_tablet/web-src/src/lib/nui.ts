/**
 * SONAR Tablet — NUI bridge helper (NUI → Lua).
 *
 * FiveM NUI expone `window.GetParentResourceName()` runtime. Usamos `fetch`
 * contra `https://<resourceName>/<endpoint>` — FiveM intercepta y enruta a
 * `RegisterNUICallback(endpoint, ...)` en `client/main.lua`.
 *
 * Dev-mode (vite dev server fuera de FiveM): `isInFiveM` false → callers deben
 * gracefully no-op o usar `mockFetchNUI` para UX testing browser.
 */
import type { NUIEndpoint, NUIResponse } from '@/types/nui'

declare global {
  interface Window {
    GetParentResourceName?: () => string
  }
}

/** True si runtime es FiveM Chromium (expone GetParentResourceName). */
export const isInFiveM: boolean =
  typeof window !== 'undefined' && typeof window.GetParentResourceName === 'function'

/**
 * POST JSON a un endpoint NUI Lua-side.
 *
 * @param endpoint naming canonical `sonar:tablet:*`.
 * @param payload JSON-serializable body (default `{}`).
 * @returns response tipada desde `RegisterNUICallback` (Lua).
 * @throws si HTTP status no-ok o response no es JSON válido.
 */
export async function fetchNUI<TRequest = unknown, TResponse extends NUIResponse = NUIResponse>(
  endpoint: NUIEndpoint,
  payload?: TRequest,
): Promise<TResponse> {
  const resourceName = window.GetParentResourceName?.() ?? 'sonar_tablet'
  const res = await fetch(`https://${resourceName}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload ?? {}),
  })
  if (!res.ok) {
    throw new Error(`NUI fetch failed: ${endpoint} (status ${res.status})`)
  }
  return (await res.json()) as TResponse
}

/**
 * Dev-mode stub para browser `npm run dev` fuera de FiveM.
 * Loggea endpoint y resuelve `{ ok: true }` default.
 */
export async function mockFetchNUI<T extends NUIResponse = NUIResponse>(
  endpoint: NUIEndpoint,
): Promise<T> {
  // eslint-disable-next-line no-console
  console.info(`[mock NUI] ${endpoint}`)
  return { ok: true } as T
}
