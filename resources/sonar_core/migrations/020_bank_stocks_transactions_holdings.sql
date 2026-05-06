-- ============================================================================
-- Migration: 020_bank_stocks_transactions_holdings.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 3 tablas Tier 4 — Stocks (Q-DB-I híbrido event-sourced + materialized):
--     - sonar_bank_stocks_assets       — catálogo stocks listados.
--     - sonar_bank_stocks_transactions — APPEND-ONLY event log (buy/sell/dividend).
--     - sonar_bank_stocks_holdings     — MATERIALIZED snapshot (computed view).
--
-- Dependencies: 002 + 003.
--
-- DECISIONES (Q-DB-I híbrido):
--   D1. Modelo dual:
--       - transactions = source of truth (event-sourced, append-only).
--       - holdings = derived snapshot rebuildable via SUM(qty) por asset.
--       Backend Lead post-H1 lib `Stocks.RecomputeHoldings(citizen_id)` recalcula
--       holdings desde transactions. Cron rebuild full snapshot opcional.
--
--   D2. Cantidades como DECIMAL(20,8) — fractional shares soportados (Stocks
--       moderno permite fracciones). 8 decimals safe vs floating-point loss.
--
--   D3. price_per_share + total_amount cached en transactions — snapshot
--       precio histórico inmutable. Fiat side DECIMAL(14,2).
--
--   D4. holdings.last_recomputed_at — invalidation token. Stale > 5min →
--       Backend re-trigger recompute lazy.
--
--   D5. transactions append-only triggers SIGNAL Q-DB-F tier 1.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_stocks_assets (
  id                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ticker                VARCHAR(16)     NOT NULL,
  display_name          VARCHAR(128)    NOT NULL,
  exchange              VARCHAR(32)     NULL COMMENT 'simulado: NYSE, NASDAQ, etc',
  enabled               BOOLEAN         NOT NULL DEFAULT TRUE,

  current_price         DECIMAL(14,4)   NULL COMMENT 'cached price simulado',
  price_updated_at      INT UNSIGNED    NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_stocks_assets_ticker (ticker),
  KEY idx_sonar_bank_stocks_assets_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- APPEND-ONLY event-sourced log.
CREATE TABLE IF NOT EXISTS sonar_bank_stocks_transactions (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizen_id            CHAR(36)        NOT NULL,
  asset_id              SMALLINT UNSIGNED NOT NULL,
  fiat_bank_account_id  CHAR(36)        NOT NULL COMMENT 'cuenta debit/credit fiat',

  tx_kind               ENUM('buy','sell','dividend','split_in','split_out','adjustment') NOT NULL,
  qty                   DECIMAL(20,8)   NOT NULL COMMENT 'positivo=ingreso shares, negativo=salida',
  price_per_share       DECIMAL(14,4)   NOT NULL COMMENT 'snapshot precio at tx',
  total_amount          DECIMAL(14,2)   NOT NULL COMMENT 'qty * price_per_share fiat side',
  fee_amount            DECIMAL(14,2)   NOT NULL DEFAULT 0,

  request_nonce         CHAR(36)        NULL,
  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,

  initiated_by_account_id CHAR(36)      NULL,
  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, occurred_at),
  KEY idx_sonar_bank_stocks_tx_citizen_asset (citizen_id, asset_id, occurred_at DESC),
  KEY idx_sonar_bank_stocks_tx_kind (tx_kind, occurred_at DESC),
  KEY idx_sonar_bank_stocks_tx_nonce (request_nonce),
  KEY idx_sonar_bank_stocks_tx_account (fiat_bank_account_id, occurred_at DESC),

  CONSTRAINT fk_sonar_bank_stocks_tx_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_stocks_tx_asset
    FOREIGN KEY (asset_id) REFERENCES sonar_bank_stocks_assets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_stocks_tx_account
    FOREIGN KEY (fiat_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_stocks_tx_initiator
    FOREIGN KEY (initiated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_stocks_tx_price_nonneg CHECK (price_per_share >= 0),
  CONSTRAINT chk_sonar_bank_stocks_tx_fee_nonneg CHECK (fee_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_stocks_tx_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_stocks_tx_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_stocks_tx_no_update BEFORE UPDATE ON sonar_bank_stocks_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_stocks_transactions is append-only — UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_stocks_tx_no_delete BEFORE DELETE ON sonar_bank_stocks_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_stocks_transactions is append-only — DELETE rejected'; END$$
DELIMITER ;


-- MATERIALIZED snapshot — current holdings per citizen + asset.
CREATE TABLE IF NOT EXISTS sonar_bank_stocks_holdings (
  id                    CHAR(36)        NOT NULL,
  citizen_id            CHAR(36)        NOT NULL,
  asset_id              SMALLINT UNSIGNED NOT NULL,

  qty_total             DECIMAL(20,8)   NOT NULL DEFAULT 0,
  avg_cost_basis        DECIMAL(14,4)   NULL COMMENT 'precio promedio compra (FIFO/avg method app-layer)',

  last_recomputed_at    INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) COMMENT 'staleness invalidation',
  last_tx_id            BIGINT UNSIGNED NULL COMMENT 'last transaction reflected en este snapshot',

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_stocks_holdings_citizen_asset (citizen_id, asset_id),
  KEY idx_sonar_bank_stocks_holdings_citizen (citizen_id),
  KEY idx_sonar_bank_stocks_holdings_asset (asset_id),

  CONSTRAINT fk_sonar_bank_stocks_holdings_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_stocks_holdings_asset
    FOREIGN KEY (asset_id) REFERENCES sonar_bank_stocks_assets(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
