-- ============================================================================
-- Migration: 016_tax_brackets_history_subsidies.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.2)
-- Description:
--   Crea 3 tablas Tax-domain Phase A:
--     - sonar_bank_tax_brackets    — current tax brackets editable por gov.
--     - sonar_bank_tax_history     — append-only audit todo cambio brackets.
--     - sonar_bank_subsidies       — subsidios emitidos (UBI + targeted aid).
--
-- Dependencies:
--   - 002_foundation_tables.sql (sonar_accounts existe).
--   - 003_bank_schema.sql (sonar_bank_accounts existe).
--   - 010_bank_audit_ledger.sql (audit ledger event types tax_payment +
--                                 subsidy_issue + tax_brackets_edit).
--
-- Reversible: sí dev (DROP TABLES). NO post-prod (audit retention legal +
--   tax history append-only inmutable).
--
-- SSoT references:
--   docs/technical/03_db_schema.md §24 (NEW v1.4 DRAFT v0.2 — apendeo en BANK-DB.2).
--   docs/agents/teams/01_SHARED_BRIEF.md §3.10 Q10 + §3.11 Q11 (tax flows + Government UBI).
--
-- DECISIONES TÉCNICAS (founder Q-DB-A + Q-DB-G LOCKED 2026-05-06):
--
--   D1. sonar_bank_tax_brackets — current snapshot tablebrackets editable.
--       Modelo wide (income_min/income_max + rate_pct) — N rows = N brackets.
--       Editable por Government Console (ACE `sonar.bank.govt.tax.edit`).
--       Trigger AFTER UPDATE/INSERT/DELETE sobre esta tabla → INSERT en
--       sonar_bank_tax_history (audit append-only).
--
--   D2. sonar_bank_tax_history — append-only audit todo cambio. Triggers
--       SIGNAL BEFORE UPDATE/DELETE (mismo patrón Q-DB-F audit ledger).
--       Captura snapshot completo de bracket pre/post cambio + actor.
--
--   D3. sonar_bank_subsidies — subsidios emitidos. Tipos canonical:
--       'ubi_monthly' (Q-DB UBI universal income mensual), 'unemployment'
--       (subsidio desempleo activable), 'targeted_aid' (ayudas puntuales gov),
--       'cooperative_grant' (subvenciones cooperativas).
--
--   D4. FK sonar_accounts ON DELETE RESTRICT — citizen NO se puede borrar si
--       tiene subsidies pending o tax_history como editor.
--       FK sonar_bank_accounts ON DELETE SET NULL — bank account closing
--       preserva subsidy record (audit trail).
--
--   D5. CHECK constraints simples (Q-DB-A — multi-col app-layer):
--         - income_min < income_max
--         - rate_pct BETWEEN 0 AND 100
--         - amount > 0 (subsidies)
--
--   D6. brackets editable timestamp `effective_from` + `effective_until` — NO
--       tabla particionada (volumen bajo, ~10-50 brackets max). NULL until =
--       currently active.
--
--   D7. subsidies particionado RANGE `issued_at` mensual — volumen alto
--       (UBI mensual a todos citizens activos). Initial partitions May-Dec
--       2026 + p_future. Cron rolling forward DevOps Lead post-H4.
--
--   D8. Generated column `tax_brackets.is_active` STORED indexable — query
--       hot path "brackets activos hoy" optimizado vs filter compuesto.
--       Fallback: regular column updated by Backend Lead lib si parser bug.
-- ============================================================================


START TRANSACTION;


-- ----------------------------------------------------------------------------
-- 1. sonar_bank_tax_brackets — current brackets editable
--
-- Modelo: cada row = un bracket. Government Console UI permite CRUD.
-- Trigger AFTER → audit a sonar_bank_tax_history.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_tax_brackets (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  bracket_name          VARCHAR(64)     NOT NULL COMMENT 'p.e. "low_income", "middle_class", "wealth_tax_high"',
  bracket_kind          ENUM('income_personal','income_business','wealth','transaction') NOT NULL DEFAULT 'income_personal',

  income_min            DECIMAL(14,2)   NOT NULL DEFAULT 0       COMMENT 'umbral mínimo (inclusive)',
  income_max            DECIMAL(14,2)   NULL                     COMMENT 'umbral máximo (exclusive). NULL = sin límite superior',
  rate_pct              DECIMAL(5,2)    NOT NULL                 COMMENT 'tasa % (e.g. 22.50 = 22.5%)',

  effective_from        INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  effective_until       INT UNSIGNED    NULL COMMENT 'NULL = bracket activo',

  created_by_account_id CHAR(36)        NULL COMMENT 'admin gov account autor creación',
  updated_by_account_id CHAR(36)        NULL COMMENT 'admin gov account autor último update',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_tax_brackets_name_active (bracket_name, effective_until),
  KEY idx_sonar_bank_tax_brackets_kind_active (bracket_kind, effective_from, effective_until),

  CONSTRAINT fk_sonar_bank_tax_brackets_created_by
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_tax_brackets_updated_by
    FOREIGN KEY (updated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_tax_brackets_income_range
    CHECK (income_max IS NULL OR income_min < income_max),
  CONSTRAINT chk_sonar_bank_tax_brackets_rate_pct
    CHECK (rate_pct >= 0 AND rate_pct <= 100),
  CONSTRAINT chk_sonar_bank_tax_brackets_income_min
    CHECK (income_min >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 2. sonar_bank_tax_history — append-only audit todo cambio bracket
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_tax_history (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  bracket_id            BIGINT UNSIGNED NOT NULL COMMENT 'FK lógico — NO enforced (bracket puede borrarse, history sobrevive)',

  change_type           ENUM('create','update','delete') NOT NULL,
  actor_account_id      CHAR(36)        NULL,
  actor_role            ENUM('admin','government','system') NOT NULL DEFAULT 'admin',

  -- Snapshot ANTES del cambio (NULL si change_type='create').
  before_bracket_name   VARCHAR(64)     NULL,
  before_bracket_kind   ENUM('income_personal','income_business','wealth','transaction') NULL,
  before_income_min     DECIMAL(14,2)   NULL,
  before_income_max     DECIMAL(14,2)   NULL,
  before_rate_pct       DECIMAL(5,2)    NULL,

  -- Snapshot DESPUÉS del cambio (NULL si change_type='delete').
  after_bracket_name    VARCHAR(64)     NULL,
  after_bracket_kind    ENUM('income_personal','income_business','wealth','transaction') NULL,
  after_income_min      DECIMAL(14,2)   NULL,
  after_income_max      DECIMAL(14,2)   NULL,
  after_rate_pct        DECIMAL(5,2)    NULL,

  reason_note           TEXT            NULL COMMENT 'razón del cambio documentada por admin',

  changed_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_bank_tax_history_bracket (bracket_id, changed_at DESC),
  KEY idx_sonar_bank_tax_history_actor (actor_account_id, changed_at DESC),
  KEY idx_sonar_bank_tax_history_change_type (change_type, changed_at DESC),

  CONSTRAINT fk_sonar_bank_tax_history_actor
    FOREIGN KEY (actor_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Triggers SIGNAL append-only (Q-DB-F tier 1 pattern).
DROP TRIGGER IF EXISTS trg_sonar_bank_tax_history_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_tax_history_no_delete;

DELIMITER $$

CREATE TRIGGER trg_sonar_bank_tax_history_no_update
  BEFORE UPDATE ON sonar_bank_tax_history FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_tax_history is append-only — UPDATE rejected';
END$$

CREATE TRIGGER trg_sonar_bank_tax_history_no_delete
  BEFORE DELETE ON sonar_bank_tax_history FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_tax_history is append-only — DELETE rejected';
END$$

DELIMITER ;


-- ----------------------------------------------------------------------------
-- 3. sonar_bank_subsidies — subsidios emitidos (UBI + targeted aid)
--
-- Particionado RANGE issued_at mensual — UBI mensual a citizens activos
-- genera volumen alto.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_subsidies (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  subsidy_kind          ENUM('ubi_monthly','unemployment','targeted_aid','cooperative_grant') NOT NULL,

  beneficiary_account_id CHAR(36)       NOT NULL COMMENT 'citizen receiving subsidy',
  bank_account_id       CHAR(36)        NOT NULL COMMENT 'cuenta destino del subsidio',
  company_id            CHAR(36)        NULL COMMENT 'empresa beneficiaria (cooperative_grant) — opaque Q-DB-E',

  amount                DECIMAL(14,2)   NOT NULL,
  currency              CHAR(3)         NOT NULL DEFAULT 'EUR' COMMENT 'Q8 single-currency global',

  issued_by_account_id  CHAR(36)        NULL COMMENT 'admin gov autor (NULL si sistema UBI auto)',
  issued_by_role        ENUM('government','admin','system') NOT NULL DEFAULT 'system',

  related_movement_id   BIGINT UNSIGNED NULL COMMENT 'link sonar_bank_movements.id (category=tax_subsidy)',
  related_audit_id      BIGINT UNSIGNED NULL COMMENT 'link sonar_bank_audit_ledger.id',

  reason_note           VARCHAR(255)    NULL,
  reference_period      VARCHAR(32)     NULL COMMENT 'p.e. "2026-05" para UBI mensual',

  issued_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, issued_at),
  KEY idx_sonar_bank_subsidies_beneficiary_issued (beneficiary_account_id, issued_at DESC),
  KEY idx_sonar_bank_subsidies_kind_issued (subsidy_kind, issued_at DESC),
  KEY idx_sonar_bank_subsidies_period (subsidy_kind, reference_period),
  KEY idx_sonar_bank_subsidies_company (company_id),
  KEY idx_sonar_bank_subsidies_issued_by (issued_by_account_id, issued_at DESC),

  CONSTRAINT fk_sonar_bank_subsidies_beneficiary
    FOREIGN KEY (beneficiary_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_subsidies_bank_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_subsidies_issued_by
    FOREIGN KEY (issued_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_subsidies_amount_positive CHECK (amount > 0)

  -- NO FK company_id → sonar_companies(id) — Q-DB-E DEFERRED issue #001.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  PARTITION BY RANGE (issued_at) (
    PARTITION p_2026_05 VALUES LESS THAN (1748736000),  -- < Jun 1 2026 UTC
    PARTITION p_2026_06 VALUES LESS THAN (1751328000),
    PARTITION p_2026_07 VALUES LESS THAN (1754006400),
    PARTITION p_2026_08 VALUES LESS THAN (1756684800),
    PARTITION p_2026_09 VALUES LESS THAN (1759276800),
    PARTITION p_2026_10 VALUES LESS THAN (1761955200),
    PARTITION p_2026_11 VALUES LESS THAN (1764547200),
    PARTITION p_2026_12 VALUES LESS THAN (1767225600),
    PARTITION p_future  VALUES LESS THAN MAXVALUE
  );


COMMIT;


-- ============================================================================
-- POST-INSTALL DevOps Lead actions required (post-H4):
--   1. Cron mensual rolling forward partitions sonar_bank_subsidies.
--   2. Cron mensual UBI batch issuance (Backend Lead post-H1 implementa).
-- ============================================================================
