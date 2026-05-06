-- ============================================================================
-- Migration: 027_bank_escrow_releases.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea tabla Empresas extends — escrow partial release log + ALTER
--   sonar_escrows ADD release_log_count.
--
-- Dependencies: 002 + 003 + 006 (sonar_escrows existe).
--
-- DECISIONES (Q12 escrow FSM 6-states):
--   D1. sonar_escrows existing FSM extends — partial releases permiten
--       liberar tramos del escrow (e.g. milestones contractuales).
--   D2. release_log append-only triggers SIGNAL Q-DB-F.
--   D3. ALTER sonar_escrows ADD release_log_count TINYINT UNSIGNED denormalized
--       counter (avoid COUNT(*) hot path on UI escrow detail page).
--   D4. Idempotency check antes de ALTER (re-apply safe).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_escrow_releases (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  escrow_id             CHAR(36)        NOT NULL,

  release_kind          ENUM('milestone','partial','full','refund_partial') NOT NULL,
  amount_released       DECIMAL(14,2)   NOT NULL,
  amount_remaining      DECIMAL(14,2)   NOT NULL COMMENT 'snapshot post-release',

  released_by_account_id CHAR(36)       NULL COMMENT 'admin or counterparty triggering release',
  released_to_iban      VARCHAR(20)     NOT NULL,
  reason_note           VARCHAR(255)    NULL,
  milestone_label       VARCHAR(64)     NULL COMMENT 'e.g. "milestone_2_delivery"',

  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,
  request_nonce         CHAR(36)        NULL,

  released_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, released_at),
  KEY idx_sonar_bank_escrow_releases_escrow (escrow_id, released_at DESC),
  KEY idx_sonar_bank_escrow_releases_kind (release_kind, released_at DESC),
  KEY idx_sonar_bank_escrow_releases_actor (released_by_account_id, released_at DESC),
  KEY idx_sonar_bank_escrow_releases_nonce (request_nonce),

  CONSTRAINT fk_sonar_bank_escrow_releases_actor
    FOREIGN KEY (released_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_escrow_releases_amount_positive CHECK (amount_released > 0),
  CONSTRAINT chk_sonar_bank_escrow_releases_remaining_nonneg CHECK (amount_remaining >= 0)

  -- NO FK escrow_id → sonar_escrows(id) directo — escrow puede tener estado
  -- 'closed' permanente, releases sobreviven (audit retention legal).
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_escrow_releases_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_escrow_releases_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_escrow_releases_no_update BEFORE UPDATE ON sonar_bank_escrow_releases FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_escrow_releases is append-only — UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_escrow_releases_no_delete BEFORE DELETE ON sonar_bank_escrow_releases FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_escrow_releases is append-only — DELETE rejected'; END$$
DELIMITER ;


-- ALTER sonar_escrows ADD release_log_count (idempotent).
DROP PROCEDURE IF EXISTS sp_apply_027_escrow_release_count;

DELIMITER $$
CREATE PROCEDURE sp_apply_027_escrow_release_count()
BEGIN
  DECLARE col_count INT DEFAULT 0;
  SELECT COUNT(*) INTO col_count
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_escrows'
    AND COLUMN_NAME = 'release_log_count';

  IF col_count = 0 THEN
    ALTER TABLE sonar_escrows
      ADD COLUMN release_log_count TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'denormalized count releases (FSM 6-states extends Q12)';
  END IF;
END$$
DELIMITER ;

CALL sp_apply_027_escrow_release_count();
DROP PROCEDURE sp_apply_027_escrow_release_count;

COMMIT;
