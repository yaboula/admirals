-- ============================================================================
-- Migration: 023_bank_physical_cards.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea tabla Tier 4 — Physical cards (tokens linked to bank_accounts).
--
-- Dependencies: 002 + 003.
--
-- DECISIONES:
--   D1. card_token CHAR(64) — opaque token (NO real PAN). Display PAN solo
--       last_4_digits VARCHAR(4). Backend Lead lib generate token + last4.
--   D2. FSM 4-state: 'active', 'frozen', 'expired', 'lost'.
--   D3. PIN encrypted/hashed: pin_hash CHAR(64) SHA-256(pin || card_token salt).
--       Backend Lead post-H1 enforce hash + verify. NO plain PIN en DB.
--   D4. daily_limit DECIMAL(14,2) — overrides bank_account.daily_limit_out
--       cuando card-based txn.
--   D5. UNIQUE(card_token) — token unique global. UNIQUE(bank_account_id) NO
--       — citizen puede tener N cards mismo account.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_physical_cards (
  id                    CHAR(36)        NOT NULL,
  bank_account_id       CHAR(36)        NOT NULL,
  holder_account_id     CHAR(36)        NOT NULL COMMENT 'citizen titular card',

  card_token            CHAR(64)        NOT NULL COMMENT 'opaque token Backend-generated',
  last_4_digits         CHAR(4)         NOT NULL COMMENT 'display only',
  card_kind             ENUM('debit','credit','prepaid') NOT NULL DEFAULT 'debit',

  state                 ENUM('active','frozen','expired','lost') NOT NULL DEFAULT 'active',

  pin_hash              CHAR(64)        NULL COMMENT 'SHA-256(pin || token_salt) — Backend lib enforce',
  pin_salt              CHAR(32)        NULL,
  pin_attempts_failed   TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'auto-freeze si > 3',

  daily_limit           DECIMAL(14,2)   NULL COMMENT 'NULL = inherit bank_account.daily_limit_out',
  daily_used_today      DECIMAL(14,2)   NOT NULL DEFAULT 0,
  daily_reset_at        INT UNSIGNED    NULL,

  issued_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  expires_at            INT UNSIGNED    NULL,
  frozen_at             INT UNSIGNED    NULL,
  frozen_reason         VARCHAR(128)    NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_physical_cards_token (card_token),
  KEY idx_sonar_bank_physical_cards_account (bank_account_id, state),
  KEY idx_sonar_bank_physical_cards_holder (holder_account_id, state),
  KEY idx_sonar_bank_physical_cards_state_expires (state, expires_at),

  CONSTRAINT fk_sonar_bank_physical_cards_bank_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_physical_cards_holder
    FOREIGN KEY (holder_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_physical_cards_daily_limit_nonneg CHECK (daily_limit IS NULL OR daily_limit >= 0),
  CONSTRAINT chk_sonar_bank_physical_cards_daily_used_nonneg CHECK (daily_used_today >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
