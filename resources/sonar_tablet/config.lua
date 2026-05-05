-- =============================================================================
-- SONAR Tablet — shared config
-- =============================================================================
-- S2.2 scope: keybind F2 + NUI bridge. R3 mitigation (keybind conflict):
--   - `Config.TabletKeybind` configurable.
--   - Player puede remap via F8 → settings → keybindings (RegisterKeyMapping).
--   - F2 elegido por evitar conflicto con ox_inventory (TAB) y lb-phone (UP).
--
-- SSoT keybinding canonical: este file.
-- SSoT naming eventos: `sonar:tablet:*` per 02_events_catalog.md v1.2.
-- =============================================================================

Config = Config or {}

-- Tecla por defecto para abrir/cerrar Tablet NUI. FiveM key names:
--   https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
Config.TabletKeybind = 'F2'

-- Si true, impide que jugador remap vía F8 settings (force keybind locked).
-- Default false = player puede customizar (política UX amigable).
Config.DisableKeybindOverride = false

-- Debug: print NUI bridge messages en F8 console. Disable en producción.
Config.Debug = false

-- =============================================================================
-- S2.5 Map app config.
-- =============================================================================

-- Intervalo poll GPS cliente (ms). 250ms = 4Hz, suficiente para marker smooth
-- ≥30fps render-side (React rAF interpola entre updates via Framer motion
-- transition 120ms). Bajar a <200ms no aporta visual y satura NUI bridge.
-- SSoT: SPRINT_PLAN_S2 §3 DC7a.
Config.MapGpsPollMs = 250

-- World bounds GTA5 San Andreas (aprox canonical). Usado por proyección
-- worldToViewport() en React. Si founder exporta atlas con bounds distintos,
-- actualizar aquí + `src/apps/Map/lib/projection.ts` DEFAULT_BOUNDS.
Config.MapWorldBounds = {
  min_x = -4000.0,
  max_x =  4500.0,
  min_y = -4000.0,
  max_y =  8000.0,
}

-- POIs admin-seed S2 — DB table `sonar_map_pois` + callback firmable S3+
-- cuando ADR promote bridge §2.2.3 a canónico. TODO R8 §9 SPRINT_PLAN_S2.
-- Shape canónica alineada con React `MapPOI` type (apps/Map/types.ts):
--   { id, label, category, world_x, world_y, visible }.
Config.MapPOIs = {
  { id = 'granja-001',  label = 'Granja Alamo',    category = 'farm',    world_x =  2120.0, world_y =  4870.0, visible = true },
  { id = 'mill-001',    label = 'Molino Paleto',   category = 'mill',    world_x = -340.0,  world_y =  6470.0, visible = true },
  { id = 'bakery-001',  label = 'Panadería LS',    category = 'bakery',  world_x =  130.0,  world_y = -1290.0, visible = true },
  { id = 'retail-001',  label = 'Tienda Vinewood', category = 'retail',  world_x =  380.0,  world_y =   330.0, visible = true },
  { id = 'depot-001',   label = 'Depósito Sandy',  category = 'depot',   world_x =  1710.0, world_y =  3290.0, visible = true },
}

return Config
