-- ============================================================================
-- Migration: 039_sonar_bank_account_joints.sql
-- Author: AI Full Stack (BANK-FLOW.AUDIT.1) + yaboula
-- Date: 2026-05-15
-- Description:
--   Creates sonar_bank_account_joints — canonical join table for joint
--   ownership of bank accounts. Replaces the previous JSON column placeholder
--   in sonar_bank_accounts (which never existed in the real schema).
--
-- Dependencies: 003_bank_schema.sql (sonar_bank_accounts), 002_foundation_tables.sql (sonar_accounts).
--
-- Decisions:
--   D1. Separate table (vs JSON column on sonar_bank_accounts) — gives FK
--       integrity, clean reverse lookup ("on which accounts is citizen X joint?"),
--       and avoids read-modify-write race conditions when concurrent operators
--       update the joint set.
--   D2. UNIQUE(account_id, joint_citizen_id) prevents duplicates.
--   D3. ON DELETE CASCADE for account_id — when an account is hard-deleted,
--       its joint records die with it. (Closing an account is soft-delete via
--       closed_at; joints survive that.)
--   D4. joint_citizen_id is VARCHAR(64) referencing sonar_accounts.char_id —
--       NOT a hard FK because char_id is not the PK in that table. Service
--       layer enforces existence before insert.
--   D5. added_by_citizen_id captures provenance for audit trail beyond the
--       audit_ledger entry.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_account_joints (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id            CHAR(36)        NOT NULL,
  joint_citizen_id      VARCHAR(64)     NOT NULL COMMENT 'sonar_accounts.char_id',
  added_by_citizen_id   VARCHAR(64)     NOT NULL COMMENT 'primary owner who added this joint',
  added_at              INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_account_joints_pair (account_id, joint_citizen_id),
  KEY idx_sonar_bank_account_joints_citizen (joint_citizen_id),

  CONSTRAINT fk_sonar_bank_account_joints_account
    FOREIGN KEY (account_id) REFERENCES sonar_bank_accounts(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
