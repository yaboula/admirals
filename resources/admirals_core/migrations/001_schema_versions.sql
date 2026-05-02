-- ============================================================================
-- Migration: 001_schema_versions.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02
-- Description:
--   Crea admirals_schema_versions — registry de migraciones aplicadas
--   + checksum SHA-256 para detectar tampering.
--
-- Dependencies: none (BOOTSTRAP table — la runner la usa para tracking).
-- Reversible: yes (DROP TABLE — pero NO se ejecuta post-prod).
--
-- SSoT: docs/technical/03_db_schema.md §12.2.
-- ============================================================================

CREATE TABLE IF NOT EXISTS admirals_schema_versions (
  version     INT UNSIGNED  NOT NULL COMMENT 'numérico secuencial (parseado del filename NNN_*.sql)',
  filename    VARCHAR(192)  NOT NULL COMMENT 'NNN_description.sql',
  applied_at  INT UNSIGNED  NOT NULL DEFAULT (UNIX_TIMESTAMP()) COMMENT 'unix ts aplicación',
  applied_by  VARCHAR(64)   NULL     COMMENT 'usuario o sistema que aplicó',
  checksum    VARCHAR(64)   NOT NULL COMMENT 'SHA-256 (hex) del body del migration file',
  duration_ms INT UNSIGNED  NOT NULL DEFAULT 0 COMMENT 'cuánto tardó el apply',
  notes       TEXT          NULL,

  PRIMARY KEY (version),
  UNIQUE KEY uq_admirals_schema_versions_filename (filename)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
