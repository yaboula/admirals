-- ============================================================================
-- Migration: 028_bank_idempotency_keys.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea tabla central Idempotency keys — vital para Reconciliación Activa
--   Backend Lead post-H1.
--
-- Dependencies: 002.
--
-- DECISIONES (founder mandate Idempotency Keys):
--   D1. Tabla central idempotency keys cross-domain (transfers + recurring +
--       crypto + stocks + escrow + business approvals). Cada operación
--       atomic genera key UUID + Backend lib check antes commit.
--
--   D2. response_payload JSON — almacena resultado completed para retry-safe.
--       Si client retry mismo idempotency_key, Backend devuelve cached response
--       sin re-ejecutar operación.
--
--   D3. TTL 7 days (mandato founder) — cron cleanup DevOps Lead post-H4
--       DELETE WHERE expires_at < UNIX_TIMESTAMP() in batches.
--
--   D4. UNIQUE(idempotency_key) — Backend lib INSERT con ON DUPLICATE KEY
--       UPDATE no-op + check existing state.
--
--   D5. state ENUM tracking ciclo:
--       - 'pending'  : operation in-flight (locked).
--       - 'completed': operation done, response cached.
--       - 'failed'   : operation failed, retry permitido (cleanup más rápido).
--
--   D6. domain ENUM canonical — clasifica origen para audit + analytics.
--
--   D7. NO partitioning Phase A — volumen TBD post-launch.
--       Si > 500K rows → migration v0.4 partitioning RANGE(expires_at).
--
--   D8. Lock optimistic via INSERT IGNORE — si race condition, segundo
--       client recibe duplicate → check state existing → wait or return cached.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_idempotency_keys (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  idempotency_key       CHAR(64)        NOT NULL COMMENT 'client-provided UUID/hash unique per logical op',
  domain                ENUM('transfer','recurring','crypto_buy','crypto_sell','stocks_buy','stocks_sell','escrow_create','escrow_release','loan_disbursement','loan_repayment','business_approval','tax_payment','subsidy_issue','custom') NOT NULL,

  state                 ENUM('pending','completed','failed') NOT NULL DEFAULT 'pending',

  -- Identidad solicitante:
  initiated_by_account_id CHAR(36)      NULL,
  bank_account_id       CHAR(36)        NULL COMMENT 'cuenta principal involucrada (opcional)',

  -- Snapshot params operación:
  request_payload       JSON            NULL COMMENT 'params operación serializados',

  -- Snapshot response (post-completion):
  response_payload      JSON            NULL COMMENT 'resultado cached retry-safe',
  response_code         VARCHAR(32)     NULL COMMENT 'success / insufficient_funds / etc',

  -- Linking:
  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,
  related_correlation_id CHAR(36)       NULL COMMENT 'CP2 correlation-id Backend Lead',

  -- Timing:
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  completed_at          INT UNSIGNED    NULL,
  expires_at            INT UNSIGNED    NOT NULL COMMENT 'TTL 7 days canonical',

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_idempotency_keys_key (idempotency_key),
  KEY idx_sonar_bank_idempotency_keys_state_expires (state, expires_at) COMMENT 'cron cleanup hot path',
  KEY idx_sonar_bank_idempotency_keys_domain_state (domain, state),
  KEY idx_sonar_bank_idempotency_keys_account (bank_account_id, created_at DESC),
  KEY idx_sonar_bank_idempotency_keys_initiator (initiated_by_account_id, created_at DESC),
  KEY idx_sonar_bank_idempotency_keys_correlation (related_correlation_id),

  CONSTRAINT fk_sonar_bank_idempotency_keys_initiator
    FOREIGN KEY (initiated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_idempotency_keys_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;


-- ============================================================================
-- POST-INSTALL Backend Lead post-H1 actions:
--   1. Implement IdempotencyKeys.Lock(key, domain, payload) lib:
--      - INSERT new row state='pending' + expires_at = NOW + 7d.
--      - On UNIQUE conflict → SELECT existing row + return state.
--      - If existing.state='completed' → return cached response_payload.
--      - If existing.state='pending' AND created_at < 60s → wait/retry.
--      - If existing.state='pending' AND created_at > 60s → assume stuck, mark failed.
--   2. Implement IdempotencyKeys.Complete(key, response, movement_id) post-success.
--   3. Implement IdempotencyKeys.Fail(key, error_code) post-error.
--
-- POST-INSTALL DevOps Lead post-H4 actions:
--   1. Cron daily cleanup:
--      DELETE FROM sonar_bank_idempotency_keys
--      WHERE expires_at < UNIX_TIMESTAMP() LIMIT 10000;
--      Repeat hasta 0 rows (batch).
-- ============================================================================
