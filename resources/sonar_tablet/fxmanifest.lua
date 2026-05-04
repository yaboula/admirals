fx_version 'cerulean'
game      'gta5'
lua54     'yes'

name        'sonar_tablet'
author      'SONAR'
description 'SONAR Tablet NUI — universal interface shell (Bridge home + Bank + Map + Companies + ...). S2.2 scope: shell + keybind TAB + NUI bridge + entrance animation.'
version     '0.1.0'

-- =============================================================================
-- S2.4 scope: Bank app real — balance (C001) + transfer (C002) + historial
--            (NUI bridge ad-hoc §2.2.3 consumer pattern DEFERRED catalog S3).
--
-- S2.2 shipped: shell + keybind F2 + NUI bridge bidireccional Lua↔React.
-- S2.3 shipped: Bridge home (SonarOS app grid 12) + router + lazy-load.
--
-- NO incluye (scope futuro):
--   - Map app (GPS + POIs)           → S2.5
--   - Motion + Sound signature       → S2.6
--
-- Perf budgets D6 (ADR-016):
--   - JS gzip ≤ 500KB  (baseline S2.1 = 59KB, S2.3 = 88KB)
--   - CSS gzip ≤ 200KB (baseline S2.1 = 4.7KB)
-- =============================================================================

-- NUI entrypoint — Vite emite a resources/sonar_tablet/web/ (vite.config.ts build.outDir).
ui_page 'web/index.html'

shared_script 'config.lua'

client_scripts {
  -- ox_lib client-side: lib.callback.await para invocar callbacks C001/C002
  -- (Bank) + bridge NUI ad-hoc §2.2.3 getHistory desde client/main.lua.
  '@ox_lib/init.lua',
  'client/main.lua',
}

server_scripts {
  -- Helper lib sonar_core (cargada en VM sonar_tablet) — expone SONAR.{DB,Rate,
  -- Log,Metrics,Identity,Bus} consumido por server/bank_history.lua.
  '@sonar_core/lib/sonar.lua',
  -- ox_lib server-side: lib.callback.register para `sonar:tablet:bank:getHistory`.
  '@ox_lib/init.lua',
  'server/main.lua',
  'server/bank_history.lua',  -- S2.4 NUI bridge ad-hoc §2.2.3 Bank historial.
}

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
  'sonar_bridges',  -- S2.4: idempotency/bridges layer (C002 transfer consumer).
  'sonar_bank',     -- S2.4: C001 getBalance + C002 transfer + sonar_bank_* tables.
}
