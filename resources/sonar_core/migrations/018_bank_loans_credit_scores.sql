-- ============================================================================
-- Migration: 018_bank_loans_credit_scores.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 2 tablas Tier 4 — Loans:
--     - sonar_bank_loans          — préstamos FSM 6-state.
--     - sonar_bank_credit_scores  — credit score por citizen (rolling history).
--
-- Dependencies: 002 + 003 (sonar_accounts + sonar_bank_accounts).
--
-- DECISIONES:
--   D1. Loans FSM 6-state: 'requested', 'approved', 'disbursed', 'active',
--       'paid_off', 'defaulted'. Reverse transitions PROHIBITED app-layer.
--   D2. amount_principal + amount_outstanding DECIMAL(14,2) (Q-DB-B fiat).
--   D3. interest_rate_pct DECIMAL(5,2) — anual %. Computation app-layer Backend.
--   D4. credit_scores rolling — N rows por citizen, last row = current snapshot.
--       PK auto + UNIQUE(citizen_id, computed_at) prevent duplicate computes.
--   D5. FK ON DELETE RESTRICT loans.borrower (auditoría legal) + ON DELETE
--       SET NULL credit_scores.computed_by (admin actor optional).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_loans (
  id                    CHAR(36)        NOT NULL,
  borrower_account_id   CHAR(36)        NOT NULL,
  bank_account_id       CHAR(36)        NOT NULL COMMENT 'cuenta destino disbursement + origen repayments',
  company_id            CHAR(36)        NULL COMMENT 'business loan — opaque Q-DB-E',

  state                 ENUM('requested','approved','disbursed','active','paid_off','defaulted') NOT NULL DEFAULT 'requested',
  loan_kind             ENUM('personal','business','mortgage','microloan') NOT NULL DEFAULT 'personal',

  amount_principal      DECIMAL(14,2)   NOT NULL,
  amount_outstanding    DECIMAL(14,2)   NOT NULL DEFAULT 0,
  interest_rate_pct     DECIMAL(5,2)    NOT NULL,
  term_months           SMALLINT UNSIGNED NOT NULL,
  monthly_payment       DECIMAL(14,2)   NULL COMMENT 'computed app-layer al transition disbursed',

  approved_by_account_id CHAR(36)       NULL,
  approved_at           INT UNSIGNED    NULL,
  disbursed_at          INT UNSIGNED    NULL,
  next_payment_due_at   INT UNSIGNED    NULL,
  paid_off_at           INT UNSIGNED    NULL,
  defaulted_at          INT UNSIGNED    NULL,

  reason_note           VARCHAR(255)    NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_bank_loans_borrower_state (borrower_account_id, state),
  KEY idx_sonar_bank_loans_state_due (state, next_payment_due_at),
  KEY idx_sonar_bank_loans_company (company_id),
  KEY idx_sonar_bank_loans_kind_state (loan_kind, state),

  CONSTRAINT fk_sonar_bank_loans_borrower
    FOREIGN KEY (borrower_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_loans_bank_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_loans_approved_by
    FOREIGN KEY (approved_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_loans_principal_positive CHECK (amount_principal > 0),
  CONSTRAINT chk_sonar_bank_loans_outstanding_nonneg CHECK (amount_outstanding >= 0),
  CONSTRAINT chk_sonar_bank_loans_rate_pct CHECK (interest_rate_pct >= 0 AND interest_rate_pct <= 100),
  CONSTRAINT chk_sonar_bank_loans_term_positive CHECK (term_months > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_credit_scores (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizen_id            CHAR(36)        NOT NULL,

  score                 SMALLINT UNSIGNED NOT NULL COMMENT '0-1000 escala canonical',
  rating                ENUM('excellent','good','fair','poor','no_history') NOT NULL,

  -- Componentes score (Q-DB-A simple float):
  payment_history_pct   DECIMAL(5,2)    NULL COMMENT '% pagos on-time',
  active_loans_count    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  defaulted_loans_count SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  total_outstanding     DECIMAL(14,2)   NOT NULL DEFAULT 0,

  computed_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  computed_by_account_id CHAR(36)       NULL COMMENT 'admin manual override (NULL = sistema cron)',
  computation_method    ENUM('automatic','manual_override') NOT NULL DEFAULT 'automatic',

  reason_note           VARCHAR(255)    NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_credit_scores_citizen_computed (citizen_id, computed_at),
  KEY idx_sonar_bank_credit_scores_citizen_score (citizen_id, computed_at DESC),
  KEY idx_sonar_bank_credit_scores_rating (rating, computed_at DESC),

  CONSTRAINT fk_sonar_bank_credit_scores_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_credit_scores_computed_by
    FOREIGN KEY (computed_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_credit_scores_score_range CHECK (score <= 1000),
  CONSTRAINT chk_sonar_bank_credit_scores_payment_pct CHECK (payment_history_pct IS NULL OR (payment_history_pct >= 0 AND payment_history_pct <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
