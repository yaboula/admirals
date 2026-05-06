-- ============================================================================
-- Migration: 025_bank_round_ups.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 2 tablas Tier 4 — Round-ups (savings micro-redondeo):
--     - sonar_bank_round_up_configs     — settings per citizen (opt-in + dest).
--     - sonar_bank_round_up_transactions — append-only round-up log.
--
-- Dependencies: 002 + 003.
--
-- DECISIONES:
--   D1. config 1:1 citizen — UNIQUE PRIMARY (citizen_id).
--   D2. multiplier permite 1x, 2x, 5x boost — incentiva savings.
--   D3. tx append-only triggers SIGNAL Q-DB-F.
--   D4. trigger_movement_id link al movement original que disparó el round-up.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_round_up_configs (
  citizen_id            CHAR(36)        NOT NULL,
  source_bank_account_id CHAR(36)       NOT NULL COMMENT 'cuenta debit redondeo',
  destination_bank_account_id CHAR(36)  NOT NULL COMMENT 'cuenta savings credit',

  enabled               BOOLEAN         NOT NULL DEFAULT TRUE,
  multiplier            TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1x, 2x, 5x boost',
  round_up_to           DECIMAL(6,2)    NOT NULL DEFAULT 1.00 COMMENT 'redondear hacia múltiplo (e.g. 1.00 = nearest euro)',

  total_rounded_eur     DECIMAL(14,2)   NOT NULL DEFAULT 0 COMMENT 'lifetime total saved',

  enabled_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (citizen_id),

  CONSTRAINT fk_sonar_bank_round_up_configs_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_round_up_configs_source
    FOREIGN KEY (source_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_round_up_configs_destination
    FOREIGN KEY (destination_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_round_up_multiplier CHECK (multiplier >= 1 AND multiplier <= 10),
  CONSTRAINT chk_sonar_bank_round_up_to_positive CHECK (round_up_to > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_round_up_transactions (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizen_id            CHAR(36)        NOT NULL,

  trigger_movement_id   BIGINT UNSIGNED NOT NULL COMMENT 'movement original que disparó round-up',
  original_amount       DECIMAL(14,2)   NOT NULL,
  rounded_to            DECIMAL(14,2)   NOT NULL,
  round_up_amount       DECIMAL(14,2)   NOT NULL COMMENT 'amount transferred to savings (incl multiplier)',
  multiplier_applied    TINYINT UNSIGNED NOT NULL,

  savings_movement_id   BIGINT UNSIGNED NULL COMMENT 'movement crédito a savings account',

  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, occurred_at),
  KEY idx_sonar_bank_round_up_tx_citizen (citizen_id, occurred_at DESC),
  KEY idx_sonar_bank_round_up_tx_trigger (trigger_movement_id),

  CONSTRAINT fk_sonar_bank_round_up_tx_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_round_up_tx_amount_positive CHECK (round_up_amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_round_up_tx_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_round_up_tx_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_round_up_tx_no_update BEFORE UPDATE ON sonar_bank_round_up_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_round_up_transactions is append-only — UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_round_up_tx_no_delete BEFORE DELETE ON sonar_bank_round_up_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_round_up_transactions is append-only — DELETE rejected'; END$$
DELIMITER ;

COMMIT;
