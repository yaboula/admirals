-- ============================================================================
-- Migration: 032_govt_risk_scores_and_treasury_movements.sql
-- Author: DB Lead (Cascade) + yaboula
-- Date: 2026-05-09 (BANK-DB.AMEND.1)
-- Description:
--   Adds authoritative GOVT risk score materialization (0-100) and extends
--   treasury movement categories required by Issue #002 REQ-FE-006/007/012/014.
--
-- Dependencies:
--   - 003_bank_schema.sql + 015_bank_movements_category_extend.sql.
--   - 029_company_registry.sql.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_govt_risk_scores (
  subject_type          ENUM('citizen','company') NOT NULL,
  subject_id            CHAR(36)        NOT NULL,

  score                 TINYINT UNSIGNED NOT NULL,
  risk_level            ENUM('low','medium','high','critical') NOT NULL,

  velocity_score        TINYINT UNSIGNED NOT NULL DEFAULT 0,
  compliance_score      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  exposure_score        TINYINT UNSIGNED NOT NULL DEFAULT 0,
  flag_score            TINYINT UNSIGNED NOT NULL DEFAULT 0,
  dormancy_score        TINYINT UNSIGNED NOT NULL DEFAULT 0,

  components_json       JSON            NULL,
  formula_version       VARCHAR(32)     NOT NULL DEFAULT 'govt-risk-v1',
  computed_by           ENUM('system','government','admin') NOT NULL DEFAULT 'system',
  computed_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  expires_at            INT UNSIGNED    NULL,

  related_audit_id      BIGINT UNSIGNED NULL,

  PRIMARY KEY (subject_type, subject_id),
  KEY idx_sonar_bank_govt_risk_scores_level_score (subject_type, risk_level, score DESC),
  KEY idx_sonar_bank_govt_risk_scores_computed (computed_at DESC),
  KEY idx_sonar_bank_govt_risk_scores_expires (expires_at),

  CONSTRAINT chk_sonar_bank_govt_risk_scores_score CHECK (score <= 100),
  CONSTRAINT chk_sonar_bank_govt_risk_scores_velocity CHECK (velocity_score <= 100),
  CONSTRAINT chk_sonar_bank_govt_risk_scores_compliance CHECK (compliance_score <= 100),
  CONSTRAINT chk_sonar_bank_govt_risk_scores_exposure CHECK (exposure_score <= 100),
  CONSTRAINT chk_sonar_bank_govt_risk_scores_flag CHECK (flag_score <= 100),
  CONSTRAINT chk_sonar_bank_govt_risk_scores_dormancy CHECK (dormancy_score <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS sp_apply_032_movements_treasury_extend;

DELIMITER $$

CREATE PROCEDURE sp_apply_032_movements_treasury_extend()
BEGIN
  DECLARE col_def TEXT DEFAULT '';
  DECLARE idx_count INT DEFAULT 0;

  SELECT COLUMN_TYPE INTO col_def
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_movements'
    AND COLUMN_NAME = 'category';

  IF col_def NOT LIKE '%fine_collected%' THEN
    ALTER TABLE sonar_bank_movements
      MODIFY COLUMN category ENUM(
        'salary',
        'b2b_payment',
        'transfer',
        'tax',
        'refund',
        'b2c_sale',
        'expense',
        'deposit',
        'withdrawal',
        'escrow_lock',
        'escrow_release',
        'adjustment',
        'starter_seed',
        'tax_subsidy',
        'loan_disbursement',
        'loan_repayment',
        'crypto_buy',
        'crypto_sell',
        'stock_buy',
        'stock_sell',
        'recurring_charge',
        'round_up',
        'loyalty_redeem',
        'compliance_freeze',
        'fine_collected',
        'payroll_disbursement',
        'reconciliation',
        'interest_accrued'
      ) NOT NULL COMMENT 'accounting category Phase A amendment — 28 canonical values';
  END IF;

  SELECT COUNT(*) INTO idx_count
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_movements'
    AND INDEX_NAME = 'idx_sonar_bank_movements_treasury_rollup';

  IF idx_count = 0 THEN
    ALTER TABLE sonar_bank_movements
      ADD KEY idx_sonar_bank_movements_treasury_rollup (category, occurred_at DESC, bank_account_id);
  END IF;
END$$

DELIMITER ;

CALL sp_apply_032_movements_treasury_extend();
DROP PROCEDURE sp_apply_032_movements_treasury_extend;

COMMIT;

-- ============================================================================
-- Risk score contract:
--   score: 0-100 authoritative Backend/Security computed materialized snapshot.
--   low: 0-24, medium: 25-54, high: 55-79, critical: 80-100.
--   Backend Lead refresh cadence target: every 5 minutes for active citizens and
--   active companies, plus on-demand recompute after sanctions or critical flags.
-- ============================================================================
