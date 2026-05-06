-- ============================================================================
-- Migration: 019_bank_crypto_wallets.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 2 tablas Tier 4 — Crypto wallets:
--     - sonar_bank_crypto_assets       — catálogo assets soportados (reference data).
--     - sonar_bank_crypto_wallets      — wallets per citizen + asset.
--     - sonar_bank_crypto_transactions — append-only transaction log.
--
-- Dependencies: 002 + 003.
--
-- DECISIONES (Q-DB-B BIGINT atomic + decimals):
--   D1. Política split atomic units / decimals — crypto NO sufre rounding
--       errors DECIMAL: amount_atomic BIGINT UNSIGNED + decimals stored en
--       sonar_bank_crypto_assets (e.g. 8 decimals BTC, 18 ETH).
--       Display = amount_atomic / 10^decimals (computación app-layer).
--   D2. Fiat exchange rate cached en transactions table (price_eur_atomic
--       BIGINT centavos EUR snapshot at tx time) — historial inmutable.
--   D3. UNIQUE(citizen_id, asset_id) — una wallet por citizen + asset (no
--       multi-wallet por simplicidad Phase A).
--   D4. transactions append-only triggers SIGNAL Q-DB-F tier 1.
--   D5. Bank account link FK — crypto buy/sell debit/credit fiat account.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_crypto_assets (
  id                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  symbol                VARCHAR(16)     NOT NULL COMMENT 'BTC, ETH, etc',
  display_name          VARCHAR(64)     NOT NULL,
  decimals              TINYINT UNSIGNED NOT NULL COMMENT 'BTC=8, ETH=18',
  enabled               BOOLEAN         NOT NULL DEFAULT TRUE,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_crypto_assets_symbol (symbol),
  KEY idx_sonar_bank_crypto_assets_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_crypto_wallets (
  id                    CHAR(36)        NOT NULL,
  citizen_id            CHAR(36)        NOT NULL,
  asset_id              SMALLINT UNSIGNED NOT NULL,

  balance_atomic        BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'amount_atomic = balance / 10^decimals',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_crypto_wallets_citizen_asset (citizen_id, asset_id),
  KEY idx_sonar_bank_crypto_wallets_asset (asset_id),

  CONSTRAINT fk_sonar_bank_crypto_wallets_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_crypto_wallets_asset
    FOREIGN KEY (asset_id) REFERENCES sonar_bank_crypto_assets(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_crypto_transactions (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  wallet_id             CHAR(36)        NOT NULL,
  citizen_id            CHAR(36)        NOT NULL,
  asset_id              SMALLINT UNSIGNED NOT NULL,

  tx_kind               ENUM('buy','sell','transfer_in','transfer_out','adjustment') NOT NULL,
  amount_atomic         BIGINT          NOT NULL COMMENT 'positivo=ingreso, negativo=salida',
  balance_atomic_after  BIGINT UNSIGNED NOT NULL COMMENT 'snapshot post-tx',

  -- Fiat-side snapshot (buy/sell):
  fiat_amount           DECIMAL(14,2)   NULL COMMENT 'fiat counterpart EUR',
  fiat_bank_account_id  CHAR(36)        NULL,
  related_movement_id   BIGINT UNSIGNED NULL COMMENT 'sonar_bank_movements link',
  exchange_rate_atomic  BIGINT UNSIGNED NULL COMMENT 'price snapshot (centavos EUR per atomic unit)',

  -- Idempotency + audit:
  request_nonce         CHAR(36)        NULL,
  related_audit_id      BIGINT UNSIGNED NULL,
  initiated_by_account_id CHAR(36)      NULL,

  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, occurred_at),
  KEY idx_sonar_bank_crypto_transactions_wallet (wallet_id, occurred_at DESC),
  KEY idx_sonar_bank_crypto_transactions_citizen_asset (citizen_id, asset_id, occurred_at DESC),
  KEY idx_sonar_bank_crypto_transactions_kind (tx_kind, occurred_at DESC),
  KEY idx_sonar_bank_crypto_transactions_nonce (request_nonce),

  CONSTRAINT fk_sonar_bank_crypto_transactions_wallet
    FOREIGN KEY (wallet_id) REFERENCES sonar_bank_crypto_wallets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_crypto_transactions_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_crypto_transactions_asset
    FOREIGN KEY (asset_id) REFERENCES sonar_bank_crypto_assets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_crypto_transactions_fiat_account
    FOREIGN KEY (fiat_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_crypto_transactions_initiator
    FOREIGN KEY (initiated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_crypto_transactions_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_crypto_transactions_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_crypto_transactions_no_update BEFORE UPDATE ON sonar_bank_crypto_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_crypto_transactions is append-only — UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_crypto_transactions_no_delete BEFORE DELETE ON sonar_bank_crypto_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_crypto_transactions is append-only — DELETE rejected'; END$$
DELIMITER ;

-- Seed reference data crypto assets canonical:
INSERT IGNORE INTO sonar_bank_crypto_assets (symbol, display_name, decimals, enabled) VALUES
  ('BTC',  'Bitcoin',  8,  TRUE),
  ('ETH',  'Ethereum', 18, TRUE),
  ('USDT', 'Tether',   6,  TRUE);

COMMIT;
