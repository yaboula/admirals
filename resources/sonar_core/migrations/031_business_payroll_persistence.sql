-- ============================================================================
-- Migration: 031_business_payroll_persistence.sql
-- Author: DB Lead (Cascade) + yaboula
-- Date: 2026-05-09 (BANK-DB.AMEND.1)
-- Description:
--   Adds durable payroll execution persistence required by Issue #002 REQ-FE-015.
--   Business treasury approvals remain the approval queue; payroll batches/lines
--   are the executable, auditable unit of work.
--
-- Dependencies:
--   - 029_company_registry.sql (sonar_companies exists).
--   - 026_bank_business_treasuries.sql (treasury approvals exist).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_business_payroll_batches (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,
  treasury_id           CHAR(36)        NOT NULL,

  state                 ENUM('draft','pending_approval','queued','executed','held','failed','cancelled') NOT NULL DEFAULT 'draft',
  total_net_amount      DECIMAL(14,2)   NOT NULL DEFAULT 0,
  line_count            INT UNSIGNED    NOT NULL DEFAULT 0,
  held_line_count       INT UNSIGNED    NOT NULL DEFAULT 0,
  failed_line_count     INT UNSIGNED    NOT NULL DEFAULT 0,

  requested_by_account_id CHAR(36)      NOT NULL,
  executed_by_account_id  CHAR(36)      NULL,

  scheduled_for         INT UNSIGNED    NULL,
  executed_at           INT UNSIGNED    NULL,

  related_approval_id   CHAR(36)        NULL,
  related_audit_id      BIGINT UNSIGNED NULL,
  idempotency_key       CHAR(64)        NULL,

  failure_code          VARCHAR(64)     NULL,
  failure_message       VARCHAR(255)    NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_business_payroll_batches_idempotency (idempotency_key),
  KEY idx_sonar_bank_business_payroll_batches_company_state (company_id, state, created_at DESC),
  KEY idx_sonar_bank_business_payroll_batches_treasury_state (treasury_id, state),
  KEY idx_sonar_bank_business_payroll_batches_approval (related_approval_id),
  KEY idx_sonar_bank_business_payroll_batches_schedule (state, scheduled_for),

  CONSTRAINT fk_sonar_bank_business_payroll_batches_company
    FOREIGN KEY (company_id) REFERENCES sonar_companies(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_batches_treasury
    FOREIGN KEY (treasury_id) REFERENCES sonar_bank_business_treasuries(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_batches_requested_by
    FOREIGN KEY (requested_by_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_batches_executed_by
    FOREIGN KEY (executed_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_batches_approval
    FOREIGN KEY (related_approval_id) REFERENCES sonar_bank_business_treasury_approvals(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_business_payroll_batches_total_nonneg CHECK (total_net_amount >= 0),
  CONSTRAINT chk_sonar_bank_business_payroll_batches_line_count CHECK (line_count >= held_line_count + failed_line_count)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sonar_bank_business_payroll_lines (
  id                    CHAR(36)        NOT NULL,
  batch_id              CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,

  employee_account_id   CHAR(36)        NOT NULL,
  destination_bank_account_id CHAR(36)  NOT NULL,

  net_amount            DECIMAL(14,2)   NOT NULL,
  state                 ENUM('ready','held','paid','failed','cancelled') NOT NULL DEFAULT 'ready',
  failure_code          VARCHAR(64)     NULL,
  failure_message       VARCHAR(255)    NULL,

  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,

  paid_at               INT UNSIGNED    NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_bank_business_payroll_lines_batch_state (batch_id, state),
  KEY idx_sonar_bank_business_payroll_lines_employee (employee_account_id, created_at DESC),
  KEY idx_sonar_bank_business_payroll_lines_company_state (company_id, state, created_at DESC),
  KEY idx_sonar_bank_business_payroll_lines_destination (destination_bank_account_id),

  CONSTRAINT fk_sonar_bank_business_payroll_lines_batch
    FOREIGN KEY (batch_id) REFERENCES sonar_bank_business_payroll_batches(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_lines_company
    FOREIGN KEY (company_id) REFERENCES sonar_companies(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_lines_employee
    FOREIGN KEY (employee_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_lines_destination
    FOREIGN KEY (destination_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_business_payroll_lines_amount_positive CHECK (net_amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- Backend Lead follow-up:
--   1. PayrollExecute must lock idempotency first, then batch row, then lines.
--   2. related_movement_id remains a logical link because sonar_bank_movements
--      has a composite partitioned primary key (id, occurred_at).
-- ============================================================================
