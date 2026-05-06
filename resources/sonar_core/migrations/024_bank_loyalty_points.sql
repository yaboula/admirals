-- ============================================================================
-- Migration: 024_bank_loyalty_points.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 2 tablas Tier 4 — Loyalty program:
--     - sonar_bank_loyalty_balances     — current points snapshot per citizen.
--     - sonar_bank_loyalty_transactions — append-only earn/redeem log.
--
-- Dependencies: 002.
--
-- DECISIONES:
--   D1. Points como INT UNSIGNED (no fractional). 1 point = 0.01 EUR cashback.
--   D2. Earn/redeem append-only triggers SIGNAL (Q-DB-F).
--   D3. balance materialized — Backend lib increment/decrement on tx.
--       Recompute lazy desde transactions (event-sourced fallback).
--   D4. tier ENUM 'bronze','silver','gold','platinum' — based on lifetime_earned.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_loyalty_balances (
  citizen_id            CHAR(36)        NOT NULL,
  current_points        INT UNSIGNED    NOT NULL DEFAULT 0,
  lifetime_earned       INT UNSIGNED    NOT NULL DEFAULT 0,
  lifetime_redeemed     INT UNSIGNED    NOT NULL DEFAULT 0,
  tier                  ENUM('bronze','silver','gold','platinum') NOT NULL DEFAULT 'bronze',

  last_activity_at      INT UNSIGNED    NULL,
  last_recomputed_at    INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (citizen_id),
  KEY idx_sonar_bank_loyalty_balances_tier (tier),

  CONSTRAINT fk_sonar_bank_loyalty_balances_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_loyalty_transactions (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizen_id            CHAR(36)        NOT NULL,

  tx_kind               ENUM('earn_purchase','earn_referral','earn_bonus','redeem_cashback','redeem_giftcard','adjustment_admin','expiration') NOT NULL,
  points_delta          INT             NOT NULL COMMENT 'positivo=earn, negativo=redeem',
  balance_after         INT UNSIGNED    NOT NULL,

  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,
  reason_note           VARCHAR(255)    NULL,
  initiated_by_account_id CHAR(36)      NULL,

  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, occurred_at),
  KEY idx_sonar_bank_loyalty_tx_citizen (citizen_id, occurred_at DESC),
  KEY idx_sonar_bank_loyalty_tx_kind (tx_kind, occurred_at DESC),

  CONSTRAINT fk_sonar_bank_loyalty_tx_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_loyalty_tx_initiator
    FOREIGN KEY (initiated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_loyalty_tx_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_loyalty_tx_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_loyalty_tx_no_update BEFORE UPDATE ON sonar_bank_loyalty_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_loyalty_transactions is append-only — UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_loyalty_tx_no_delete BEFORE DELETE ON sonar_bank_loyalty_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_loyalty_transactions is append-only — DELETE rejected'; END$$
DELIMITER ;

COMMIT;
