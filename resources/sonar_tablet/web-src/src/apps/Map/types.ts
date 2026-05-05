/**
 * SONAR Tablet — Map app canonical types (S2.5).
 *
 * Shapes matchean:
 *   - Bridge ad-hoc §2.2.3 `sonar:tablet:map:getNodes` response per
 *     `resources/sonar_tablet/server/map_nodes.lua` getNodesDirect.
 *   - GPS stream `sonar:tablet:map:gpsUpdate` payload per
 *     `resources/sonar_tablet/client/map_gps.lua` SendNUIMessage body.
 */

/** Coordenada world GTA5 (metros, +X Este, +Y Norte). */
export interface WorldCoord {
  x: number
  y: number
}

/** Estado GPS del player — propagado por useGpsStream hook. */
export interface GpsState {
  world_x: number
  world_y: number
  /** Heading en grados (0 = North, clockwise). */
  heading: number
  /** Velocidad km/h. */
  speed: number
  /** Timestamp Lua GetGameTimer() del sample (ms). */
  ts: number
  /** Cuándo lo recibió el cliente React (Date.now() ms). */
  updated_at: number
}

/** POI canonical — alineado con Config.MapPOIs Lua + map_nodes.lua response. */
export interface MapPOI {
  id: string
  label: string
  category: MapPOICategory
  world_x: number
  world_y: number
  visible: boolean
}

/** Categorías S2 admin-seed. Extensible cuando DB table ship S3+. */
export type MapPOICategory =
  | 'farm'
  | 'mill'
  | 'bakery'
  | 'retail'
  | 'depot'
  | 'generic'

/** Bridge §2.2.3 response data payload. */
export interface MapNodesData {
  nodes: MapPOI[]
  count: number
  seed_version: string
}

/** Error codes posibles desde bridge + forwarder. */
export type MapErrorCode =
  | 'NOT_AUTHENTICATED'
  | 'RATE_LIMITED'
  | 'CALLBACK_FAILED'
  | 'UNKNOWN'

/** Typed error thrown por `mapApi.*`. */
export class MapApiError extends Error {
  readonly error_code: MapErrorCode
  constructor(error_code: MapErrorCode, message: string) {
    super(message)
    this.name = 'MapApiError'
    this.error_code = error_code
  }
}

/** World bounds para proyección. Debe matchear Config.MapWorldBounds Lua. */
export interface WorldBounds {
  min_x: number
  max_x: number
  min_y: number
  max_y: number
}
