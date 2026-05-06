-- ============================================================================
-- Migration: 026_bank_business_treasuries.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 2 tablas Empresas extends — multi-signer business treasuries:
--     - sonar_bank_business_treasuries        — config policy per company.
--     - sonar_bank_business_treasury_signers  — N firmantes con role + signing_threshold.
--     - sonar_bank_business_treasury_approvals — pending approvals (m-of-n approval flow).
--
-- Dependencies: 002 + 003.
--
-- DECISIONES (Q-DB-E opaque company_id):
--   D1. company_id CHAR(36) opaque NO FK — Issue #001.
--   D2. signing_threshold = N firmantes mínimos required para approve TX
--       above amount_threshold. UI Tablet permite drag/configure.
--   D3. signers role canonical: 'owner', 'manager', 'employee_authorized'.
--   D4. approvals FSM: 'pending', 'approved', 'rejected', 'expired'.
--   D5. Backend lib post-H1 enforce m-of-n logic (count approvals con state='approved'
--       >= signing_threshold).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_business_treasuries (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL COMMENT 'opaque Q-DB-E',
  bank_account_id       CHAR(36)        NOT NULL COMMENT 'treasury account',

  signing_threshold     TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'm-of-n minimum signers',
  amount_threshold      DECIMAL(14,2)   NOT NULL DEFAULT 0 COMMENT 'tx > threshold requires multi-sign',

  policy_note           VARCHAR(255)    NULL,

  created_by_account_id CHAR(36)        NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_business_treasuries_company (company_id),
  UNIQUE KEY uq_sonar_bank_business_treasuries_account (bank_account_id),

  CONSTRAINT fk_sonar_bank_business_treasuries_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_treasuries_creator
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_business_treasuries_threshold CHECK (signing_threshold >= 1 AND signing_threshold <= 20),
  CONSTRAINT chk_sonar_bank_business_treasuries_amount CHECK (amount_threshold >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_business_treasury_signers (
  id                    CHAR(36)        NOT NULL,
  treasury_id           CHAR(36)        NOT NULL,
  signer_account_id     CHAR(36)        NOT NULL,

  signer_role           ENUM('owner','manager','employee_authorized') NOT NULL DEFAULT 'manager',
  active                BOOLEAN         NOT NULL DEFAULT TRUE,

  added_at              INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  removed_at            INT UNSIGNED    NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_business_treasury_signers_treasury_signer (treasury_id, signer_account_id, active),
  KEY idx_sonar_bank_business_treasury_signers_signer_active (signer_account_id, active),

  CONSTRAINT fk_sonar_bank_business_treasury_signers_treasury
    FOREIGN KEY (treasury_id) REFERENCES sonar_bank_business_treasuries(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_treasury_signers_signer
    FOREIGN KEY (signer_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_business_treasury_approvals (
  id                    CHAR(36)        NOT NULL,
  treasury_id           CHAR(36)        NOT NULL,

  -- Operation pending approval:
  operation_kind        ENUM('transfer_out','escrow_create','recurring_setup','large_withdraw','custom') NOT NULL,
  operation_payload     JSON            NOT NULL COMMENT 'serialized op params Backend lib parses',
  operation_amount      DECIMAL(14,2)   NOT NULL,
  operation_target_iban VARCHAR(20)     NULL,
  operation_description VARCHAR(255)    NULL,

  state                 ENUM('pending','approved','rejected','expired','executed') NOT NULL DEFAULT 'pending',

  signers_required      TINYINT UNSIGNED NOT NULL,
  signers_approved      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  approvals_json        JSON            NULL COMMENT '[{signer_account_id, decision, decided_at, note}]',

  initiated_by_account_id CHAR(36)      NOT NULL,
  initiated_at          INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  expires_at            INT UNSIGNED    NOT NULL COMMENT '24-72h TTL configurable',
  finalized_at          INT UNSIGNED    NULL,

  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,

  PRIMARY KEY (id),
  KEY idx_sonar_bank_business_approvals_treasury_state (treasury_id, state, expires_at),
  KEY idx_sonar_bank_business_approvals_state_expires (state, expires_at) COMMENT 'cron expire pending',
  KEY idx_sonar_bank_business_approvals_initiator (initiated_by_account_id, initiated_at DESC),

  CONSTRAINT fk_sonar_bank_business_approvals_treasury
    FOREIGN KEY (treasury_id) REFERENCES sonar_bank_business_treasuries(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_approvals_initiator
    FOREIGN KEY (initiated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_business_approvals_amount_positive CHECK (operation_amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
