ALTER TABLE sonar_bank_accounts
  MODIFY COLUMN account_class ENUM('checking','savings','business_treasury','shared','govt_treasury','escrow','crypto_wallet') NOT NULL;

ALTER TABLE sonar_bank_accounts
  ADD COLUMN IF NOT EXISTS active_owner_class_key VARCHAR(160)
    AS (CASE WHEN closed_at IS NULL AND owner_account_id IS NOT NULL THEN CONCAT(owner_account_id, ':', owner_type, ':', account_class) ELSE NULL END) PERSISTENT;

CREATE UNIQUE INDEX IF NOT EXISTS uq_sonar_bank_accounts_owner_class_active
  ON sonar_bank_accounts (active_owner_class_key);

CREATE TABLE IF NOT EXISTS sonar_bank_account_approvals (
  id CHAR(36) NOT NULL,
  citizen_id VARCHAR(64) NOT NULL,
  account_class ENUM('business_treasury') NOT NULL,
  state ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  note VARCHAR(255) NULL,
  decision_note VARCHAR(255) NULL,
  decided_by_citizen_id VARCHAR(64) NULL,
  created_account_id CHAR(36) NULL,
  created_iban VARCHAR(34) NULL,
  requested_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  decided_at INT UNSIGNED NULL,
  PRIMARY KEY (id),
  KEY idx_sonar_bank_account_approvals_citizen_state (citizen_id, state),
  KEY idx_sonar_bank_account_approvals_state_requested (state, requested_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
