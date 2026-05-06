-- ============================================================================
-- Migration: 011_bank_compliance_flags.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.1)
-- Description:
--   Crea tabla `sonar_bank_compliance_flags` — autoraise patterns canonical
--   per Q10 founder LOCKED 2026-05-06 (5 patterns).
--
--   Sustituye approach `unusual_destination_foreign_prefix` blueprint
--   pre-Q10 (Q8 multidivisa OFF — single-currency global, NO prefix foreign).
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_accounts existe — FK target).
--   - 002_foundation_tables.sql (sonar_accounts existe — FK target).
--
-- Reversible: sí en dev (DROP TABLE). NO post-prod si hay flags
--   ya raised (audit retention legal).
--
-- SSoT references:
--   docs/technical/03_db_schema.md §22 (NEW v1.2 DRAFT v0.1).
--   docs/agents/teams/01_SHARED_BRIEF.md §3.10 (Q10 — 5 patrones autoraise canonical).
--   docs/agents/teams/prompts/01_database_integrity_lead.md §4.5 (Q10 ENUM).
--   docs/agents/teams/slices/slice_security.md (Security Lead C-SEC-03 autoraise rules).
--
-- DECISIONES TÉCNICAS (founder Q10 + Q-DB-A LOCKED 2026-05-06):
--
--   D1. ENUM `flag_type` 5 valores canonical:
--         'structuring'                — N transferencias <€1k consecutivas.
--         'large_transfer'             — single >€10k.
--         'late_tax'                   — tax payment >30 días post-due.
--         'velocity'                   — >50 transacciones/24h.
--         'new_account_large_deposit'  — >€5k en cuenta <7 días vida.
--       NO incluir 'unusual_destination_foreign_prefix' (Q8 OFF — single
--       currency, no prefix foreign).
--
--   D2. Status FSM 4-state: 'open' → 'investigating' → 'resolved' | 'false_positive'.
--       NO 'escalated' explicit — escalation se modela vía severity bump +
--       audit_ledger entries.
--
--   D3. severity ENUM 4 valores per audit_ledger consistency: info / notice /
--       warning / critical.
--
--   D4. evidence JSON column — flexible payload per flag_type (transaction
--       refs, threshold breached, time window, comparison values). Schema
--       documentado per flag_type en docs/technical/08_audit_hooks.md
--       (Security Lead C-SEC-03 post-H2).
--
--   D5. resolved_by_account_id NULL hasta resolution. action_taken ENUM
--       open-ended para Phase A — admin actions canonical post-H2 Security.
--
--   D6. NO FK a sonar_companies (Q-DB-E DEFERRED — opaque company_id).
--       FK sonar_bank_accounts.id sí enforced.
--
--   D7. CHECK simples MariaDB 12.x compatible — multi-col app-layer.
--
--   D8. Index strategy:
--         (citizen_account_id, status, raised_at) — Audit Explorer "Mi cuenta" + "open flags".
--         (flag_type, raised_at) — Government Console pattern analysis.
--         (severity, status) — Security dashboard "critical open".
--
--   D9. raised_by ENUM 'system' (autoraise Backend) | 'admin' (manual) |
--       'watchdog' (Bridge integrity check CP4). Founder approval pendiente
--       'watchdog' como source — defer si surge issue scope.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. sonar_bank_compliance_flags — autoraise patterns canonical
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_compliance_flags (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  flag_type             ENUM(
                          'structuring',
                          'large_transfer',
                          'late_tax',
                          'velocity',
                          'new_account_large_deposit'
                        ) NOT NULL COMMENT '5 patterns canonical Q10 LOCKED 2026-05-06',

  severity              ENUM('info','notice','warning','critical') NOT NULL DEFAULT 'warning',
  status                ENUM('open','investigating','resolved','false_positive') NOT NULL DEFAULT 'open',

  citizen_account_id    CHAR(36)        NOT NULL COMMENT 'FK sonar_accounts.id — citizen flagged',
  bank_account_id       CHAR(36)        NULL COMMENT 'FK sonar_bank_accounts.id si flag scope cuenta-específica',
  company_id            CHAR(36)        NULL COMMENT 'FK sonar_companies(id) DEFERRED — issue #001',

  raised_by             ENUM('system','admin','watchdog') NOT NULL DEFAULT 'system',
  raised_by_account_id  CHAR(36)        NULL COMMENT 'admin account si raised_by=admin',

  threshold_value       DECIMAL(14,2)   NULL COMMENT 'umbral disparado (e.g. €10000 large_transfer)',
  observed_value        DECIMAL(14,2)   NULL COMMENT 'valor observado que disparó (e.g. transferencia €15500)',
  time_window_seconds   INT UNSIGNED    NULL COMMENT 'ventana temporal aplicable (e.g. 86400 para velocity)',

  evidence              JSON            NULL COMMENT 'payload flexible per flag_type — schema docs/technical/08_audit_hooks.md (Security Lead)',

  related_movement_ids  JSON            NULL COMMENT 'array BIGINT IDs sonar_bank_movements vinculadas',

  resolved_by_account_id CHAR(36)       NULL COMMENT 'admin/citizen autor resolution',
  action_taken          VARCHAR(255)    NULL COMMENT 'descripción acción tomada (freeze, contact, dismiss, ...)',
  resolution_note       TEXT            NULL,

  raised_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  -- updated_at: app-managed (NO ON UPDATE — MariaDB-illegal en INT UNSIGNED).
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  resolved_at           INT UNSIGNED    NULL,

  PRIMARY KEY (id),

  KEY idx_sonar_bank_compliance_flags_citizen_status_raised (citizen_account_id, status, raised_at DESC),
  KEY idx_sonar_bank_compliance_flags_bank_account (bank_account_id),
  KEY idx_sonar_bank_compliance_flags_company (company_id),
  KEY idx_sonar_bank_compliance_flags_type_raised (flag_type, raised_at DESC),
  KEY idx_sonar_bank_compliance_flags_severity_status (severity, status),
  KEY idx_sonar_bank_compliance_flags_raised_by (raised_by, raised_by_account_id),

  CONSTRAINT fk_sonar_bank_compliance_flags_citizen
    FOREIGN KEY (citizen_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_bank_compliance_flags_bank_account
    FOREIGN KEY (bank_account_id)
    REFERENCES sonar_bank_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_bank_compliance_flags_resolved_by
    FOREIGN KEY (resolved_by_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_compliance_flags_threshold_sane
    CHECK (threshold_value IS NULL OR threshold_value >= 0),

  CONSTRAINT chk_sonar_bank_compliance_flags_observed_sane
    CHECK (observed_value IS NULL OR observed_value >= 0),

  CONSTRAINT chk_sonar_bank_compliance_flags_resolved_consistency
    CHECK (
      (status IN ('open','investigating') AND resolved_at IS NULL AND resolved_by_account_id IS NULL)
      OR (status IN ('resolved','false_positive') AND resolved_at IS NOT NULL)
    )

  -- NO FK company_id → sonar_companies(id) — Q-DB-E LOCKED 2026-05-06 (issue #001).
  -- Backend Lead post-H1 enforce app-layer validation `Companies.exists(company_id)`.
  --
  -- Index rationale:
  --   idx_..._citizen_status_raised: hot path Audit Explorer "Mi cuenta open flags".
  --   idx_..._bank_account: lookup flags por cuenta.
  --   idx_..._company: lookup flags por empresa.
  --   idx_..._type_raised: Government Console pattern analysis.
  --   idx_..._severity_status: Security dashboard "critical open".
  --   idx_..._raised_by: filter system/admin/watchdog.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- FIN migration 011_bank_compliance_flags.sql
-- ============================================================================
