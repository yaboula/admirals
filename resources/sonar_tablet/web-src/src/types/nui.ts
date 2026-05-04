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

/** Generic response envelope retornado por RegisterNUICallback. */
export interface NUIResponse {
  ok: boolean
  [key: string]: unknown
}
