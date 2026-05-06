-- ============================================================================
-- Migration: 021_bank_recurring_payments.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea tabla Tier 4 — Recurring payments (suscripciones, alquiler, utilities).
--
-- Dependencies: 002 + 003.
--
-- DECISIONES:
--   D1. FSM 4-state: 'active', 'paused', 'cancelled', 'completed'.
--   D2. interval_kind ENUM canonical (daily/weekly/monthly/yearly).
--   D3. next_charge_at INT UNSIGNED — cron Backend Lead post-H1 query
--       WHERE state='active' AND next_charge_at <= UNIX_TIMESTAMP() ORDER ASC.
--   D4. Companies opaque (Q-DB-E) — payee_company_id sin FK.
--   D5. last_charge_status ENUM tracking failure mode (insufficient_funds, etc).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_recurring_payments (
  id                    CHAR(36)        NOT NULL,

  payer_account_id      CHAR(36)        NOT NULL,
  payer_bank_account_id CHAR(36)        NOT NULL COMMENT 'cuenta debit',

  payee_kind            ENUM('citizen','company','government') NOT NULL,
  payee_account_id      CHAR(36)        NULL COMMENT 'NULL si payee_kind != citizen',
  payee_company_id      CHAR(36)        NULL COMMENT 'opaque Q-DB-E',
  payee_iban            VARCHAR(20)     NOT NULL COMMENT 'destination always set',

  state                 ENUM('active','paused','cancelled','completed') NOT NULL DEFAULT 'active',
  payment_kind          ENUM('subscription','rent','utility','loan_repayment','custom') NOT NULL DEFAULT 'subscription',

  amount                DECIMAL(14,2)   NOT NULL,
  currency              CHAR(3)         NOT NULL DEFAULT 'EUR',
  interval_kind         ENUM('daily','weekly','monthly','yearly') NOT NULL,
  interval_count        SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'e.g. interval_kind=monthly + count=3 = trimestral',

  description           VARCHAR(255)    NULL,

  starts_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  ends_at               INT UNSIGNED    NULL COMMENT 'NULL = indefinido',

  next_charge_at        INT UNSIGNED    NOT NULL,
  last_charged_at       INT UNSIGNED    NULL,
  last_charge_status    ENUM('success','insufficient_funds','frozen','error') NULL,

  total_charges_count   INT UNSIGNED    NOT NULL DEFAULT 0,
  consecutive_failures  TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'auto-pause si > 3',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  cancelled_at          INT UNSIGNED    NULL,

  PRIMARY KEY (id),
  KEY idx_sonar_bank_recurring_payer (payer_account_id, state),
  KEY idx_sonar_bank_recurring_state_next (state, next_charge_at) COMMENT 'cron hot path',
  KEY idx_sonar_bank_recurring_payee_iban (payee_iban),
  KEY idx_sonar_bank_recurring_payee_company (payee_company_id),

  CONSTRAINT fk_sonar_bank_recurring_payer
    FOREIGN KEY (payer_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_recurring_payer_bank
    FOREIGN KEY (payer_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_recurring_payee_account
    FOREIGN KEY (payee_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_recurring_amount_positive CHECK (amount > 0),
  CONSTRAINT chk_sonar_bank_recurring_interval_count CHECK (interval_count > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
