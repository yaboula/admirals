fx_version 'cerulean'
game      'gta5'
lua54     'yes'

author      'SONAR'
version     '1.0.1-r1-step-f'
description 'SONAR Bank App — Phase A financial-grade callbacks resource (R1 hardened). BOOTABLE: lib + repos + services + events + state + nui + 49 callbacks + boot orchestration + cron + smoke test.'

-- =============================================================================
-- BANK-BE-CODE.0 — Steps A→F COMPLETE — BOOTABLE
-- =============================================================================
-- Resource bootable: YES.
--
-- Boot sequence (orchestrated by server/boot/init.lua, fired on onResourceStart):
--   Phase 1 — defensive_abort:
--     - HMAC.LoadSecret (refuses to boot if convar invalid)
--     - HMAC.SelfTest    (RFC 4231 SHA256)
--     - boot/smoke.lua Run (8 checks, fatal if any fails)
--   Phase 2 — workers:
--     - Audit.StartFlushTicker
--     - boot/cron.lua Start (idempotency purge + recurring sweep + watchdog)
--   Phase 3 — hooks:
--     - state/statebags.Init (M004 §2.2.2 playerJoining publish)
--     - events/netevents.RegisterServerListeners (defensive C2S abuse audit)
--     - nui/bridge.Init
--   Phase 4 — startup banner.
--
-- Dependencies direction (no cycles):
--   sonar_bank_app → sonar_bank → sonar_bridges → sonar_core
--                              → ox_lib (lib.callback server-side)
-- =============================================================================

dependencies {
  'oxmysql',
  'ox_lib',
  'sonar_core',
  'sonar_bridges',
  'sonar_bank',
}

shared_scripts {
  'config.lua',
}

server_scripts {
  -- 0. External helpers (loaded into sonar_bank_app VM context):
  '@oxmysql/lib/MySQL.lua',
  '@ox_lib/init.lua',                   -- ox_lib server-side for callbacks
  '@sonar_core/lib/sonar.lua',          -- exposes SONAR.{Core,DB,Bus,Rate,Log,Metrics,Identity}

  -- 1. Foundation lib — R1 hardened canonical helpers.
  --    Load order strict: each file depends only on lower-numbered files.
  'server/lib/enums.lua',               -- 1.  no deps — canonical enums
  'server/lib/errors.lua',              -- 2.  depends enums — error codes registry
  'server/lib/validators.lua',          -- 3.  depends errors — input sanitization
  'server/lib/units.lua',               -- 4.  depends errors — Phase 5 minor/major boundary
  'server/lib/db.lua',                  -- 5.  depends errors — H004 AP-SQL-1 prepared statements
  'server/lib/uuid.lua',                -- 6.  depends errors — M002 multi-entropy
  'server/lib/hmac.lua',                -- 7.  depends errors — M006 ATM HMAC convar enforce
  'server/lib/rate_limit.lua',          -- 8.  depends enums, errors — M003 dual rate-limit recursive guard
  'server/lib/audit.lua',               -- 9.  depends enums, errors, db, uuid — C-SEC-01 §1.2 + H006
  'server/lib/idempotency.lua',         -- 10. depends enums, errors, db, uuid, audit, hmac — M005
  'server/lib/publish.lua',             -- 11. depends enums, validators — M004 CP1-B
  'server/lib/auth.lua',                -- 12. depends enums, errors, db — H001 + AP-AUTH-1
  'server/lib/perf.lua',                -- 13. depends enums — perf budget tracker

  -- 2. State primitive (no domain deps — generic LRU class).
  'server/state/cache.lua',             -- 14. generic LRU primitive

  -- 3. Repositories (DAOs — pure SQL, depends only on lib/db).
  'server/repos/accounts.lua',          -- 15.
  'server/repos/transactions.lua',      -- 16. REQ-FE-002 GetRecentRecipients indexed query
  'server/repos/recipients.lua',        -- 17.
  'server/repos/audit_query.lua',       -- 18.
  'server/repos/recurring.lua',         -- 19.
  'server/repos/loans.lua',             -- 20.
  'server/repos/portfolio.lua',         -- 21.
  'server/repos/cards.lua',             -- 22.
  'server/repos/govt.lua',              -- 23.
  'server/repos/business.lua',          -- 24.

  -- 4. State (statebags hook — depends on repos.accounts).
  'server/state/statebags.lua',         -- 24. M004 §2.2.2 playerJoining lazy publish hook

  -- 5. Services (business logic + FSM orchestration — depends repos + lib).
  'server/services/bootstrap_service.lua',   -- 25. REQ-FE-001 (must load BEFORE other services that invalidate it)
  'server/services/recipients_service.lua',  -- 26. REQ-FE-002
  'server/services/transfer_service.lua',    -- 27.
  'server/services/account_service.lua',     -- 28.
  'server/services/loan_service.lua',        -- 29.
  'server/services/recurring_service.lua',   -- 30.
  'server/services/portfolio_service.lua',   -- 31.
  'server/services/card_service.lua',        -- 32.
  'server/services/admin_service.lua',       -- 33.
  'server/services/risk_engine.lua',         -- 34. REQ-FE-006/009 MVP risk rules
  'server/services/govt_service.lua',        -- 35. REQ-FE-006..014 GOVT data layer
  'server/services/business_service.lua',    -- 36. REQ-FE-011/015 Business data layer

  -- 6. Events (NetEvent emitters + audit emit helpers — depends lib + Enums).
  'server/events/netevents.lua',        -- 37.
  'server/events/audit_emit.lua',       -- 38.

  -- 7. NUI bridge (server stub for client config snapshot).
  'server/nui/bridge.lua',              -- 39.

  -- 8. Callbacks (Step E — canonical endpoints).
  --    _wrap.lua MUST load first (all callback files depend on Wrap.Register).
  'server/callbacks/_wrap.lua',         -- 40.
  'server/callbacks/bootstrap.lua',     -- 41. C001, C001b, NUI_CONFIG       (3)
  'server/callbacks/account.lua',       -- 42. C002, C003, C015, C016, C019,
                                        --      C020, C021, C037, C038, C039 (10)
  'server/callbacks/transfer.lua',      -- 43. C005, C006, C007, C008        (4)
  'server/callbacks/recipients.lua',    -- 44. C009, C010, C011, C012        (4)
  'server/callbacks/loan.lua',          -- 45. C022, C023, C024, C025, C026  (5)
  'server/callbacks/recurring.lua',     -- 46. C013, C014, C017, C018a/b     (5)
  'server/callbacks/portfolio.lua',     -- 47. C027, C028, C029              (3)
  'server/callbacks/card.lua',          -- 48. C030, C032, C033, C034, C040  (5)
  'server/callbacks/admin.lua',         -- 49. C035, C036, C036b, C031, C041,
                                        --      C042, C043, C044, C045, C046  (10)
  'server/callbacks/govt.lua',          -- 50. REQ-FE-006..014 GOVT callbacks
  'server/callbacks/business.lua',      -- 51. REQ-FE-011/015 Business callbacks

  -- 9. Boot orchestration (Step F).
  --    smoke + cron must load BEFORE init (init references them in phase 1/2).
  'server/boot/smoke.lua',              -- 52.
  'server/boot/cron.lua',               -- 53.
  'server/boot/init.lua',               -- 54. wires onResourceStart → Run()

  -- 10. Public cross-resource exports (loaded last — depends on repos).
  --     Consumers: sonar_bridges MirrorSync login sync +
  --     third-party resources querying canonical SONAR balance.
  'server/api/wrappers.lua',           -- 55. Phase 5 publish wrappers
  'server/api/public_api.lua',          -- 56. Phase 5 Tier 1 exports + GetApiVersion
  'server/api/auth.lua',                -- 57. Phase 5 Tier 2 admin auth gate
  'server/api/admin_api.lua',           -- 58. Phase 5 Tier 2 admin exports
  'server/api/legacy_scan.lua',         -- 59. Phase 5 migration scanner
  'server/api/smoke_exports.lua',       -- 60. Phase 5 exports smoke
  'server/smoke/st_024_phase_5_exports.lua', -- 61. ST-024 Phase 5 exports harness
  'server/boot/exports.lua',            -- 62. GetPrimaryBalanceMinor

}

-- =============================================================================
-- BANK-FE.2 — Client-side NUI bridge (React fetch ↔ server lib.callback)
-- =============================================================================

client_scripts {
  '@ox_lib/init.lua',                  -- ox_lib client-side for callbacks
  'client/nui_bridge.lua',              -- BANK-FE.2 NUI ↔ server proxy + NetEvent forwarder
}

-- =============================================================================
-- BANK-FE.1 — NUI bundle (built from web-src/ → web/)
-- =============================================================================
-- Frontend pipeline:
--   web-src/  (React 19 + Vite 6 + TS strict + Tailwind v4)
--      ↓  npm run build  (Vite → web/)
--   web/index.html  (NUI entry, hash-routed for FiveM compatibility)
--
-- Build commands (DevOps Phase E):
--   cd resources/sonar_bank_app/web-src && npm install && npm run build
-- =============================================================================

ui_page 'web/index.html'

files {
  'web/index.html',
  'web/assets/**/*.js',
  'web/assets/**/*.css',
  'web/assets/**/*.woff2',
  'web/assets/**/*.png',
}
