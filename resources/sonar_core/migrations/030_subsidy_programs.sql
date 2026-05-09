-- ============================================================================
-- Migration: 030_subsidy_programs.sql
-- Author: DB Lead (Cascade) + yaboula
-- Date: 2026-05-09 (BANK-DB.AMEND.1)
-- Description:
--   Adds subsidy program catalog persistence required by Issue #002 REQ-FE-010
--   and REQ-FE-013, then links subsidy disbursement ledger rows to programs.
--
-- Dependencies:
--   - 016_tax_brackets_history_subsidies.sql (sonar_bank_subsidies exists).
--   - 029_company_registry.sql (company grants can validate company_id).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_subsidy_programs (
  id                    CHAR(36)        NOT NULL,
  code                  VARCHAR(32)     NOT NULL,
  name                  VARCHAR(96)     NOT NULL,
  program_type          ENUM('food','housing','employment','medical','education','emergency','agricultural') NOT NULL,
  status                ENUM('active','paused','completed','proposed') NOT NULL DEFAULT 'proposed',

  budget_amount         DECIMAL(14,2)   NOT NULL DEFAULT 0,
  disbursed_amount      DECIMAL(14,2)   NOT NULL DEFAULT 0,
  beneficiary_count_cached INT UNSIGNED NOT NULL DEFAULT 0,

  starts_at             INT UNSIGNED    NOT NULL,
  ends_at               INT UNSIGNED    NULL,
  description           VARCHAR(255)    NULL,

  created_by_account_id CHAR(36)        NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_subsidy_programs_code (code),
  KEY idx_sonar_bank_subsidy_programs_status_type (status, program_type),
  KEY idx_sonar_bank_subsidy_programs_window (starts_at, ends_at),
  KEY idx_sonar_bank_subsidy_programs_created_by (created_by_account_id),

  CONSTRAINT fk_sonar_bank_subsidy_programs_created_by
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_subsidy_programs_budget_nonneg CHECK (budget_amount >= 0),
  CONSTRAINT chk_sonar_bank_subsidy_programs_disbursed_nonneg CHECK (disbursed_amount >= 0),
  CONSTRAINT chk_sonar_bank_subsidy_programs_window CHECK (ends_at IS NULL OR starts_at < ends_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS sp_apply_030_subsidy_programs;

DELIMITER $$

CREATE PROCEDURE sp_apply_030_subsidy_programs()
BEGIN
  DECLARE col_count INT DEFAULT 0;
  DECLARE idx_count INT DEFAULT 0;

  SELECT COUNT(*) INTO col_count
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_subsidies'
    AND COLUMN_NAME = 'program_id';

  IF col_count = 0 THEN
    ALTER TABLE sonar_bank_subsidies
      ADD COLUMN program_id CHAR(36) NULL AFTER subsidy_kind;
  END IF;

  SELECT COUNT(*) INTO idx_count
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_subsidies'
    AND INDEX_NAME = 'idx_sonar_bank_subsidies_program_issued';

  IF idx_count = 0 THEN
    ALTER TABLE sonar_bank_subsidies
      ADD KEY idx_sonar_bank_subsidies_program_issued (program_id, issued_at DESC);
  END IF;
END$$

DELIMITER ;

CALL sp_apply_030_subsidy_programs();
DROP PROCEDURE sp_apply_030_subsidy_programs;

COMMIT;

-- ============================================================================
-- Note:
--   No enforced FK from sonar_bank_subsidies.program_id to programs is added in
--   this migration because sonar_bank_subsidies is partitioned by issued_at.
--   Backend Lead must validate program_id/code app-side before disbursement.
-- ============================================================================
