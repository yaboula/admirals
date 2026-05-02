fx_version 'cerulean'
game      'gta5'
lua54     'yes'

author      'Admirals'
version     '0.1.0'
description 'Admirals Core — EventBus + DB wrappers + RateLimiter + Logger + Metrics + Migrations runner'

dependencies {
  'oxmysql',
  'admirals_bridges',
}

-- =============================================================================
-- Load order rationale (per docs/technical/04_api_contracts.md §6,
-- docs/technical/01_architecture.md §5.5, docs/technical/03_db_schema.md §16):
--
--   shared:
--     1. config.lua             — constants + convars (LogLevel, DB pool,
--                                 rate caps, event throttles).
--
--   server (strict order):
--     2. server/logger.lua      — Admirals.Log.{Debug,Info,Warn,Error,Audit}
--                                 + ring buffer (1000 entries) + level filter.
--     3. server/metrics.lua     — Admirals.Metrics counters + histograms
--                                 (p50/p95/p99 sliding window).
--     4. server/db.lua          — Admirals.DB.{FetchOne,FetchAll,Execute,
--                                 Insert,Scalar,Transaction} — prepared-only
--                                 (§04 §6.1), timeout 3s, slow-query >500ms.
--     5. server/event_bus.lua   — Admirals.Bus.{Subscribe,Publish} with
--                                 _event_id/_emitted_at/_schema_version auto-
--                                 decoration (§02 §1.4) + schema validation.
--     6. server/rate_limiter.lua — Admirals.Rate.Check token bucket
--                                 per-citizenId per-bucket (§04 §8.1-§8.2).
--     7. server/migrations.lua  — Admirals.Migrations.RunAll idempotent,
--                                 SHA-256 checksum, admirals_schema_versions
--                                 tracking (§03 §12.2, §16.4).
--     8. server/init.lua        — Boot orchestration (LAST): wait Bridges
--                                 ready → migrations → emit admirals:core:ready.
--
--   client:
--     - client/init.lua         — Stub: boot flag + listen core:ready (S1+).
--
--   admin commands registered by logger/metrics at load time:
--     admirals_log_dump, admirals_log_level, admirals_log_clear,
--     admirals_metrics, admirals_metrics_reset.
-- =============================================================================

shared_scripts {
  'config.lua',
}

server_scripts {
  -- oxmysql MySQL global helper — MUST be first; injects `MySQL.scalar/.query/.insert/.transaction.await`
  -- (oxmysql does NOT expose this global cross-resource without including this file).
  '@oxmysql/lib/MySQL.lua',

  -- Foundation (no cross-deps)
  'server/logger.lua',
  'server/metrics.lua',

  -- Data layer (depends on logger + metrics)
  'server/db.lua',

  -- Business primitives (depend on logger + metrics + db)
  'server/event_bus.lua',
  'server/rate_limiter.lua',
  'server/migrations.lua',

  -- Boot orchestration (LAST — depends on all above + Bridges.WaitReady)
  'server/init.lua',
}

client_scripts {
  'client/init.lua',
}

-- SQL migration files are read by server/migrations.lua via LoadResourceFile.
-- Declared here so fxmanifest tracks them as resource files.
files {
  'migrations/001_schema_versions.sql',
  'migrations/002_foundation_tables.sql',
}
