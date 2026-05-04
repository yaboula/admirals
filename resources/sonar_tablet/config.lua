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

return Config
