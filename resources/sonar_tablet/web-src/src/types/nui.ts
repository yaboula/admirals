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
// Future S2.3+: 'sonar:tablet:openApp' | 'sonar:tablet:navigate' | 'sonar:tablet:notify'

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

/** Endpoints NUI → Lua (via `fetchNUI`). */
export type NUIEndpoint =
  | 'sonar:tablet:close'
  | 'sonar:tablet:ping'
  // S2.4 Bank app — forwarders NUI → server callbacks (consumer pattern).
  | 'sonar:tablet:bank:getBalance'   // C001 sonar:bank:getBalance wrapper.
  | 'sonar:tablet:bank:transfer'     // C002 sonar:bank:transfer wrapper.
  | 'sonar:tablet:bank:getHistory'   // Bridge ad-hoc §2.2.3 (DEFERRED catalog S3).

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
