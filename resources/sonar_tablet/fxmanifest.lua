fx_version 'cerulean'
game      'gta5'
lua54     'yes'

name        'sonar_tablet'
author      'SONAR'
description 'SONAR Tablet NUI — universal interface shell (Bridge home + Bank + Map + Companies + ...). S2.2 scope: shell + keybind TAB + NUI bridge + entrance animation.'
version     '0.1.0'

-- =============================================================================
-- S2.2 scope: Tablet shell + keybind TAB + NUI bridge bidireccional Lua↔React
--            + entrance/exit animation Framer Motion 11 GPU-only.
--
-- NO incluye (scope futuro):
--   - Bridge home 12 apps grid       → S2.3
--   - Bank app (C001/C002 consume)   → S2.4
--   - Map app (GPS + POIs)           → S2.5
--   - Motion + Sound signature       → S2.6
--
-- Perf budgets D6 (ADR-016):
--   - JS gzip ≤ 500KB  (baseline S2.1 = 59KB)
--   - CSS gzip ≤ 200KB (baseline S2.1 = 4.7KB)
-- =============================================================================

-- NUI entrypoint — Vite emite a resources/sonar_tablet/web/ (vite.config.ts build.outDir).
ui_page 'web/index.html'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

-- NUI assets: Vite hash-named assets + favicon + fonts Geist WOFF2 (@fontsource).
files {
  'web/index.html',
  'web/favicon.svg',
  'web/assets/*.js',
  'web/assets/*.css',
  'web/assets/*.woff2',
  'web/assets/*.svg',
  'web/assets/*.png',
}

dependencies {
  'sonar_core',
  -- 'sonar_bridges', -- uncomment S2.4 cuando Bank app consume C001/C002 via Bridges.
  -- 'sonar_bank',    -- uncomment S2.4.
}
