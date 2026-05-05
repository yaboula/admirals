/**
 * SONAR Tablet — NUI message protocol (TypeScript types).
 *
 * Canonical naming: `sonar:tablet:*` per `docs/technical/02_events_catalog.md` v1.2.
 * Consistency guard: este file + `resources/sonar_tablet/client/main.lua` deben
 * evolucionar en paralelo (acciones nuevas → bump ambos sides en misma PR).
 */

/** Acciones válidas Lua → NUI (via `SendNUIMessage`). */
export type NUIMessageAction =
  | 'sonar:tablet:toggle'
  // S2.5 Map app — GPS stream one-way client→NUI (4Hz default, guarded por
  // `sonar:tablet:map:setPollActive` que togglea poll thread Lua-side R7).
  | 'sonar:tablet:map:gpsUpdate'

/** Base envelope shape. Action requerido; payload opcional per action. */
export interface NUIMessage<T = unknown> {
  action: NUIMessageAction
  payload?: T
  [key: string]: unknown
}

/** Toggle open/close (Lua → NUI). `visible` refleja focus state nuevo. */
export interface NUITabletToggleMessage extends NUIMessage {
  action: 'sonar:tablet:toggle'
  visible: boolean
}

/** S2.5 GPS update (Lua → NUI, one-way, 4Hz when MapApp mounted). */
export interface NUIMapGpsUpdateMessage extends NUIMessage {
  action: 'sonar:tablet:map:gpsUpdate'
  payload: {
    x: number
    y: number
    heading: number
    speed: number
    ts: number
  }
}

/** Endpoints NUI → Lua (via `fetchNUI`). */
export type NUIEndpoint =
  | 'sonar:tablet:close'
  | 'sonar:tablet:ping'
  // S2.4 Bank app — forwarders NUI → server callbacks (consumer pattern).
  | 'sonar:tablet:bank:getBalance'   // C001 sonar:bank:getBalance wrapper.
  | 'sonar:tablet:bank:transfer'     // C002 sonar:bank:transfer wrapper.
  | 'sonar:tablet:bank:getHistory'   // Bridge ad-hoc §2.2.3 (DEFERRED catalog S3).
  // S2.5 Map app.
  | 'sonar:tablet:map:getNodes'      // Bridge ad-hoc §2.2.3 (DEFERRED catalog S3+).
  | 'sonar:tablet:map:setPollActive' // Cliente-local: togglea GPS poll thread (R7).

/**
 * Generic response envelope retornado por RegisterNUICallback.
 *
 * Shapes esperadas per endpoint:
 *   - `sonar:tablet:close` / `sonar:tablet:ping`: `{ ok: boolean, ... }`.
 *   - `sonar:tablet:bank:*`: `{ success: boolean, data?|error_code? }` canonical
 *      per SSoT §3.1. `ok` no aplica — por eso ambos fields opcionales.
 *
 * Callers deben narrow via discriminated union propio (ej. `BackendEnvelope`
 * en `apps/Bank/bankApi.ts`).
 */
export interface NUIResponse {
  ok?: boolean
  success?: boolean
  [key: string]: unknown
}
