-- ============================================================================
-- Migration: 002_foundation_tables.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02
-- Description:
--   Crea las 3 tablas foundation Admirals per ADR-010 (opción C híbrido):
--     1. admirals_accounts            (minimal subset — SSoT §3.1 trimmed)
--     2. admirals_audit_log           (new operational audit — ADR-010)
--     3. admirals_bridge_idempotency  (DB-backed replacement de S0.2 in-memory)
--
-- Dependencies: 001_schema_versions (runner tracking).
-- Reversible: sí en dev (DROP TABLE). NO ejecutar rollback post-prod.
--
-- SSoT:
--   docs/technical/03_db_schema.md §3.1 (admirals_accounts canonical full).
--   docs/technical/04_api_contracts.md §6.4 (audit_log wrapper usage).
--   docs/planning/02_decision_log.md ADR-010 (hybrid audit_log + event_log).
--
-- NOTAS:
--   - admirals_accounts aquí es un SUBSET minimal (7 columnas core). Las
--     columnas restantes (reputation_global, preferred_locale, developer_mode,
--     meta, last_login_at) se añadirán via ALTER TABLE aditivos en S1+.
--   - admirals_audit_log es wrapper operacional para financial/ownership/admin;
--     admirals_event_log (partitioned, cross-bus) se crea S1+ cuando EventBus
--     tenga BusAuditMode=always en prod.
--   - admirals_bridge_idempotency sustituirá al in-memory _idem_store del
--     dispatcher vía migration path en S1 (dispatcher lee/escribe aquí si
--     Config.IdempotencyBackend='db').
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. admirals_accounts (minimal — 7 cols core).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admirals_accounts (
  id                CHAR(36)      NOT NULL COMMENT 'UUID v4',
  char_id           VARCHAR(64)   NOT NULL COMMENT 'citizenId framework',
  framework_source  VARCHAR(32)   NOT NULL COMMENT 'qbox|qbcore|esx|native',
  alias             VARCHAR(64)   NOT NULL COMMENT 'nombre mostrado Admirals',
  created_at        INT UNSIGNED  NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  -- updated_at: app-managed (Admirals.DB.Execute sets on UPDATE).
  -- ON UPDATE (UNIX_TIMESTAMP()) is MariaDB-illegal for non-TIMESTAMP columns.
  updated_at        INT UNSIGNED  NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  last_login_at     INT UNSIGNED  NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_admirals_accounts_char_framework (char_id, framework_source),
  KEY idx_admirals_accounts_char_id (char_id),
  KEY idx_admirals_accounts_framework (framework_source)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 2. admirals_audit_log — operational wrapper audit.
--
-- Distinto de admirals_event_log (que se crea S1+, particionado mensual):
--   - audit_log: operational (financial ops, ownership changes, admin acts).
--     Append-only. Query pattern: "quién hizo X y cuándo" para una entidad.
--   - event_log: bus persistence (cuando BusAuditMode=always). Structured
--     event tracing cross-subsystem. Particionado mensual.
--
-- Ambos coexisten per ADR-010.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admirals_audit_log (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ts                INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) COMMENT 'unix sec',

  category          VARCHAR(64)     NOT NULL COMMENT 'bank_transfer, ownership_change, admin_action, ...',
  action            VARCHAR(96)     NOT NULL COMMENT 'debit, credit, spawn, hire, fire, ...',

  actor_account_id  CHAR(36)        NULL COMMENT 'quién ejecutó la acción (NULL si sistema)',
  actor_source      INT UNSIGNED    NULL COMMENT 'FiveM source id al momento (debug)',

  target_type       VARCHAR(32)     NULL COMMENT 'account, company, bank_account, item, ...',
  target_id         VARCHAR(64)     NULL COMMENT 'id de la entidad afectada',

  amount            DECIMAL(12,2)   NULL COMMENT 'si operación financiera',
  currency          VARCHAR(8)      NULL COMMENT 'EUR default',

  request_id        VARCHAR(64)     NULL COMMENT 'idempotency key asociada',
  resource          VARCHAR(64)     NOT NULL COMMENT 'resource que emitió (admirals_core, admirals_bank, ...)',
  metadata          JSON            NULL COMMENT 'payload adicional (concept, reason, etc.)',

  ip_address        VARCHAR(45)     NULL COMMENT 'IPv4/IPv6 del actor al momento',

  PRIMARY KEY (id),
  KEY idx_admirals_audit_log_ts (ts DESC),
  KEY idx_admirals_audit_log_actor (actor_account_id, ts DESC),
  KEY idx_admirals_audit_log_target (target_type, target_id, ts DESC),
  KEY idx_admirals_audit_log_category (category, ts DESC),
  KEY idx_admirals_audit_log_request (request_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 3. admirals_bridge_idempotency — DB-backed replacement para S0.2 in-memory.
--
-- Sobrevive reboots (TODO en docstring dispatcher.lua línea 27).
-- Schema: key CHAR(64) PK + JSON result + expires_at unix sec.
-- GC: purga expired rows cada N min (implementado en S1 junto con migration
-- dispatcher path).
--
-- TTL default 1h (Config.IdempotencyTTLSec).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admirals_bridge_idempotency (
  idem_key     CHAR(64)       NOT NULL COMMENT 'hash key único per operación lógica',
  module       VARCHAR(32)    NOT NULL COMMENT 'bank, inventory, phone, ... (bridge module)',
  method       VARCHAR(64)    NOT NULL COMMENT 'AddMoney, RemoveMoney, Transfer, ...',
  result_json  JSON           NOT NULL COMMENT 'resultado a devolver en replays',
  created_at   INT UNSIGNED   NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  expires_at   INT UNSIGNED   NOT NULL COMMENT 'unix sec expiración',

  PRIMARY KEY (idem_key),
  KEY idx_admirals_bridge_idempotency_expires (expires_at),
  KEY idx_admirals_bridge_idempotency_module_method (module, method, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
