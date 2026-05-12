-- ============================================================================
-- Migration: 036_sonar_bank_idem.sql
-- Description: Phase 5 Tier 1/2 exports idempotency + audit shape support.
-- ============================================================================

CREATE TABLE IF NOT EXISTS sonar_bank_idem (
  idem_key          VARCHAR(36)  NOT NULL,
  payload_hash      VARCHAR(64)  NOT NULL,
  state             ENUM('locked','completed','failed') NOT NULL DEFAULT 'locked',
  result_json       JSON         NULL,
  invoker_resource  VARCHAR(64)  NOT NULL,
  event_type        VARCHAR(64)  NULL,
  target_account_id VARCHAR(64)  NULL,
  correlation_id    VARCHAR(36)  NOT NULL,
  created_at        INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  completed_at      INT UNSIGNED NULL,
  expires_at        INT UNSIGNED NOT NULL,
  PRIMARY KEY (idem_key),
  KEY idx_sonar_bank_idem_state_expires (state, expires_at),
  KEY idx_sonar_bank_idem_invoker_created (invoker_resource, created_at),
  KEY idx_sonar_bank_idem_correlation (correlation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE sonar_audit_log
  ADD COLUMN IF NOT EXISTS target_account_id VARCHAR(64) NULL AFTER actor_account_id,
  ADD COLUMN IF NOT EXISTS event_type VARCHAR(64) NULL AFTER action,
  ADD COLUMN IF NOT EXISTS delta_minor BIGINT NULL AFTER amount,
  ADD COLUMN IF NOT EXISTS previous_flag_snapshot JSON NULL AFTER metadata,
  ADD COLUMN IF NOT EXISTS request_nonce VARCHAR(36) NULL AFTER request_id,
  ADD COLUMN IF NOT EXISTS correlation_id VARCHAR(36) NULL AFTER request_nonce,
  ADD COLUMN IF NOT EXISTS invoker_resource VARCHAR(64) NULL AFTER resource,
  ADD COLUMN IF NOT EXISTS reason VARCHAR(255) NULL AFTER invoker_resource,
  ADD COLUMN IF NOT EXISTS created_at INT UNSIGNED NULL AFTER reason;

ALTER TABLE sonar_audit_log
  ADD INDEX IF NOT EXISTS idx_sonar_audit_log_event_created (event_type, created_at),
  ADD INDEX IF NOT EXISTS idx_sonar_audit_log_target_account_created (target_account_id, created_at),
  ADD INDEX IF NOT EXISTS idx_sonar_audit_log_correlation (correlation_id),
  ADD INDEX IF NOT EXISTS idx_sonar_audit_log_request_nonce (request_nonce);

ALTER TABLE sonar_bank_accounts
  DROP CONSTRAINT IF EXISTS chk_sonar_bank_accounts_balance_nonneg;
