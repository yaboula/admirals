/**
 * SONAR Tablet — Map API (S2.5).
 *
 * Thin wrapper sobre `fetchNUI` → forwarder Lua → `lib.callback.await`
 * `sonar:tablet:map:getNodes` (bridge ad-hoc §2.2.3, R8 tech debt hasta DB+
 * callback firmable S3+).
 *
 * Pattern idéntico a `apps/Bank/bankApi.ts` — ver refs allí para rationale.
 */
import { fetchNUI, isInFiveM } from '@/lib/nui'
import {
  MapApiError,
  type MapErrorCode,
  type MapNodesData,
  type MapPOI,
} from './types'

type BackendEnvelope<TData> =
  | { success: true; data: TData }
  | { success: false; error_code: MapErrorCode; message?: string }

function _unwrap<TData>(env: BackendEnvelope<TData>): TData {
  if (env.success) return env.data
  throw new MapApiError(env.error_code, env.message ?? env.error_code)
}

/**
 * Bridge ad-hoc §2.2.3 — carga POIs admin-seed.
 *
 * @throws MapApiError con códigos map + forwarder.
 */
export async function getNodes(): Promise<MapNodesData> {
  const env = await fetchNUI<Record<string, never>, BackendEnvelope<MapNodesData>>(
    'sonar:tablet:map:getNodes',
    {},
  )
  return _unwrap(env)
}

/**
 * Togglea el GPS poll thread Lua-side (R7 perf mitigation — NO poll cuando
 * MapApp unmounted). Fire-and-forget (no bloquea UI si fetch falla).
 */
export async function setPollActive(active: boolean): Promise<void> {
  if (!isInFiveM) return  // dev-mode browser: no-op.
  try {
    await fetchNUI<{ active: boolean }, { ok?: boolean }>(
      'sonar:tablet:map:setPollActive',
      { active },
    )
  } catch {
    // Silent: si falla, Lua-side cleanup vía onResourceStop cubre worst-case.
  }
}

/** Spanish human-readable mapping. */
export function translateMapError(code: MapErrorCode): string {
  const map: Record<MapErrorCode, string> = {
    NOT_AUTHENTICATED: 'Sesión no iniciada.',
    RATE_LIMITED:      'Demasiadas peticiones. Espera un momento.',
    CALLBACK_FAILED:   'El servidor no respondió. Reintenta.',
    UNKNOWN:           'Error desconocido.',
  }
  return map[code] ?? 'Operación fallida.'
}

export type { MapPOI }
