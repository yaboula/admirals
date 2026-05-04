-- =============================================================================
-- SONAR Core — config.lua
--
-- Constantes, convars parseados al boot, y mapas estáticos consumidos por
-- todos los server scripts del resource. NO contiene lógica runtime — solo
-- datos leídos por logger / metrics / db / event_bus / rate_limiter /
-- migrations / init.
--
-- Referencias SSoT:
--   docs/technical/01_architecture.md §5 (EventBus).
--   docs/technical/02_events_catalog.md §1.4 (payload shape).
--   docs/technical/03_db_schema.md §16 (migrations).
--   docs/technical/04_api_contracts.md §6 (DB layer), §8 (rate limits).
--   docs/technical/06_fivem_standards.md §2 (performance budgets).
-- =============================================================================

SONAR = SONAR or {}
SONAR.Config = SONAR.Config or {}

local Config = SONAR.Config

-- -----------------------------------------------------------------------------
-- Version — SEMVER de la API pública SONAR.Core.
-- Bump MAJOR si breaking change en firma. MINOR si añade método.
-- -----------------------------------------------------------------------------
Config.Version = '0.4.2'

-- -----------------------------------------------------------------------------
-- Environment — convar `sonar_env` (development|staging|production).
-- Affecta defaults de LogLevel + Metrics verbosity.
-- -----------------------------------------------------------------------------
Config.Env = GetConvar('sonar_env', 'development')

-- =============================================================================
-- Logger
-- =============================================================================

-- Numeric log level para filtering (higher = more verbose).
Config.LogLevelNumeric = {
  error = 1, warn = 2, info = 3, debug = 4,
}

-- Default: info en dev, warn en production.
local _default_log = Config.Env == 'production' and 'warn' or 'info'
Config.LogLevel = GetConvar('sonar_core_log_level', _default_log)

-- Ring buffer size — sonar_log_dump devuelve las últimas N entries.
-- Memory: ~300 bytes/entry * 1000 ≈ 300 KB total. Safe per §06 §2.1.
Config.LogRingBufferSize = 1000

-- ANSI color codes para console server (FiveM built-in: ^1-^9, ^0).
Config.LogColors = {
  debug = '^8',  -- gris
  info  = '^7',  -- blanco
  warn  = '^3',  -- amarillo
  error = '^1',  -- rojo
  audit = '^5',  -- cyan
  reset = '^7',
}

-- =============================================================================
-- Metrics
-- =============================================================================

-- Histogram sliding window — últimas N samples per metric key.
-- 500 samples suficientes para p99 estable sin memoria excesiva.
Config.MetricsHistogramWindow = 500

-- =============================================================================
-- Database layer (per docs/technical/04_api_contracts.md §6)
-- =============================================================================

-- Timeout default para queries individuales (race con SetTimeout).
-- oxmysql no expone timeout nativo; implementamos via Citizen.Await race.
Config.DbTimeoutMs = 3000

-- Slow query threshold — queries que superen esto log Warn + metric.
Config.DbSlowQueryMs = 500

-- Max connections advisory — oxmysql pool controlado por MYSQL_CONNECTION_STRING.
-- Este número se usa solo para boot report / metrics labels.
Config.DbMaxConnectionsAdvisory = 10

-- =============================================================================
-- EventBus (per docs/technical/01_architecture.md §5, §02 §1.4)
-- =============================================================================

-- Audit log del bus — cuántos niveles de verbosity.
--   always   — persistir TODO evento a sonar_event_log (muy caro, dev only).
--   config   — persistir solo eventos marcados audit=always en su schema.
--   off      — no persistir (ring buffer Logger queda como trail in-memory).
Config.BusAuditMode = GetConvar('sonar_core_bus_audit', 'config')

-- Async threshold — si un handler pcall tarda > N ms sincronamente, flag a
-- async en próxima invocación (protege el bus de bloqueo — per §01 §5.6).
Config.BusAsyncThresholdMs = 50

-- Subscription wildcard — permitir Subscribe('sonar:*') / ('sonar:bank:*').
-- Default off en S0.4 (added en S1+ cuando haya demand real).
Config.BusWildcardEnabled = false

-- Tracing payload keys (auto-decorated por Bus.Publish — per §02 §1.4).
-- Estos NO deben aparecer en payloads de callers; Publish los añade.
Config.BusTracingKeys = { '_event_name', '_event_id', '_emitted_at', '_schema_version' }

-- =============================================================================
-- RateLimiter (per docs/technical/04_api_contracts.md §8.1)
-- =============================================================================

-- Buckets canónicos — se añaden desde callers via RegisterBucket.
-- Estos son los defaults pre-seteados al boot para tener baseline.
--
-- Format: bucket_key = { max = N, window_sec = S }
--   max         — máximo calls permitidos en window.
--   window_sec  — ventana sliding en segundos.
--
-- Sliding window algorithm: array de timestamps, purga al Check.
Config.RateBuckets = {
  -- Tablet UI queries (§04 §8.1 "Tablet UI queries: 60/10s")
  ['tablet.query']          = { max = 60, window_sec = 10 },

  -- Read bank (§04 C001 "30/10s")
  ['bank.read']             = { max = 30, window_sec = 10 },

  -- Write bank (§04 C002 "10/60s")
  ['bank.write']            = { max = 10, window_sec = 60 },

  -- Found empresa (§04 C010 "1/24h")
  ['empresa.found']         = { max = 1,  window_sec = 86400 },

  -- Disputes (§04 C033 "3/24h")
  ['contract.dispute']      = { max = 3,  window_sec = 86400 },

  -- Inventory transfer (§04 C021 "20/60s")
  ['item.transfer']         = { max = 20, window_sec = 60 },

  -- Mercado create (§04 §3.7 "10/60s")
  ['market.create']         = { max = 10, window_sec = 60 },
}

-- GC interval — cada N segundos purga buckets inactivos de citizens offline.
Config.RateGcIntervalSec = 300

-- =============================================================================
-- Migrations (per docs/technical/03_db_schema.md §16)
-- =============================================================================

-- Directorio relativo dentro del resource donde viven los NNN_*.sql files.
Config.MigrationsDir = 'migrations'

-- Pattern filename: 3 dígitos + '_' + description + '.sql'.
Config.MigrationsFilenamePattern = '^(%d%d%d)_(.+)%.sql$'

-- Si true, hard-stop server boot si una migration falla. Production: true.
-- En dev, mantener true también — migration fail = schema corrupto.
Config.MigrationsFailFast = true

-- Si true, verifica checksum SHA-256 de migrations ya aplicadas contra
-- el fichero actual en disco. Mismatch = WARN (posible tampering).
-- TEMP false — ejecutar `sonar_repair_checksums` desde consola y volver a true.
Config.MigrationsChecksumCheck = false

-- Lista explícita de migrations a aplicar en orden. Esto es más robusto que
-- listar el directorio (FiveM no tiene ls reliable cross-platform via NUI).
-- Cada nueva migration se añade AQUÍ explícitamente.
-- Phase 8+9 (ADR-013) — post-rename `sonar_*` → `sonar_*` directo en 001-008.
-- 009_rename_sonar_to_sonar.sql obsoleto post Phase 8 (era para preserve S0+S1 data;
-- en dev path fresh start, 001-008 crean `sonar_*` desde cero).
Config.MigrationsFiles = {
  '001_schema_versions.sql',
  '002_foundation_tables.sql',
  '003_bank_schema.sql',
  '004_bank_seed_system_account.sql',
  '005_balance_nonneg_check.sql',
  '006_escrow_schema.sql',
  '007_escrow_fks_to_accounts.sql',
  '008_escrow_fks_revert_to_bank_accounts.sql',
}

-- =============================================================================
-- Boot orchestration
-- =============================================================================

-- Timeout esperando que Bridges._ready = true antes de migrations.
-- Si excede → hard-fail (server no puede arrancar sin bridges).
Config.BridgesWaitTimeoutMs = 30000

-- Tras migrations OK, emitir sonar:core:ready → consumers arrancan.
Config.CoreReadyEventName = 'sonar:core:ready'

-- =============================================================================
-- Admin commands ACL
-- =============================================================================

-- Principal ACE requerido para los comandos sonar_* admin-only.
-- Registered en server.cfg:
--   add_ace group.admin command.sonar_log_dump allow
--   add_ace group.admin command.sonar_log_level allow
--   add_ace group.admin command.sonar_metrics allow
--   ...
Config.AdminAcePrefix = 'command.sonar_'

-- Commands registrados por logger / metrics / init.
Config.AdminCommands = {
  'sonar_log_dump',      -- últimas N entries ring buffer.
  'sonar_log_level',     -- cambia LogLevel runtime.
  'sonar_log_clear',     -- limpia ring buffer.
  'sonar_metrics',       -- dump counters + histograms.
  'sonar_metrics_reset', -- reset all metrics a 0.
  'sonar_core_status',   -- muestra ready state + version + migrations.
}
