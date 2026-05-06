-- ============================================================================
-- Migration: 022_bank_atm_minigame_attempts.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea tabla Tier 4 — ATM minigame attempts log (anti-abuse + analytics).
--
-- Dependencies: 002 + 003.
--
-- DECISIONES:
--   D1. Append-only log (triggers SIGNAL Q-DB-F tier 1) — fraud detection.
--   D2. result ENUM: 'success' / 'failure' / 'timeout'.
--   D3. Rate limiting app-layer Backend lib (e.g. max 3 fails / 10min lockout).
--   D4. ip_address VARCHAR(45) IPv4/IPv6 — fraud pattern detection geolocal.
--   D5. amount_attempted DECIMAL(14,2) si éxito → genera movement separate.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_atm_minigame_attempts (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizen_id            CHAR(36)        NOT NULL,
  bank_account_id       CHAR(36)        NOT NULL,

  attempt_kind          ENUM('withdraw','deposit') NOT NULL DEFAULT 'withdraw',
  amount_attempted      DECIMAL(14,2)   NOT NULL,
  result                ENUM('success','failure','timeout') NOT NULL,
  failure_reason        VARCHAR(64)     NULL COMMENT 'wrong_pin, wrong_pattern, rate_limited, etc',

  duration_ms           INT UNSIGNED    NULL COMMENT 'tiempo respuesta minigame',
  ip_address            VARCHAR(45)     NULL,
  atm_location          VARCHAR(64)     NULL COMMENT 'ATM identifier in-game',

  related_movement_id   BIGINT UNSIGNED NULL COMMENT 'NULL si result != success',
  related_audit_id      BIGINT UNSIGNED NULL,

  attempted_at          INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, attempted_at),
  KEY idx_sonar_bank_atm_citizen_attempted (citizen_id, attempted_at DESC),
  KEY idx_sonar_bank_atm_account_attempted (bank_account_id, attempted_at DESC),
  KEY idx_sonar_bank_atm_result_attempted (result, attempted_at DESC) COMMENT 'fraud detection failures',
  KEY idx_sonar_bank_atm_ip_attempted (ip_address, attempted_at DESC),

  CONSTRAINT fk_sonar_bank_atm_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_atm_bank_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_atm_amount_positive CHECK (amount_attempted > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_atm_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_atm_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_atm_no_update BEFORE UPDATE ON sonar_bank_atm_minigame_attempts FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_atm_minigame_attempts is append-only — UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_atm_no_delete BEFORE DELETE ON sonar_bank_atm_minigame_attempts FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_atm_minigame_attempts is append-only — DELETE rejected'; END$$
DELIMITER ;

COMMIT;
