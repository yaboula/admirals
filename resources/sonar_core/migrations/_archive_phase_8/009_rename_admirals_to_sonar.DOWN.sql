-- ============================================================================
-- DOWN: 009_rename_sonar_to_sonar.DOWN.sql
-- Revert sonar_* → sonar_* (MANUAL — solo dev/staging).
--
-- ADVERTENCIA: NO ejecutar en prod con datos reales sin backup + founder approval.
-- Este file NO está en Config.MigrationsFiles — se ejecuta manualmente desde
-- consola MySQL/HeidiSQL si se necesita rollback.
-- ============================================================================

-- STEP 1: Drop FKs sonar_*
ALTER TABLE sonar_bank_accounts
  DROP FOREIGN KEY IF EXISTS fk_sonar_bank_accounts_owner_account;

ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_buyer;

ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_seller;

ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_escrow_account;

-- STEP 2: Rename tables back (batch atómico)
RENAME TABLE
  sonar_accounts           TO sonar_accounts,
  sonar_audit_log          TO sonar_audit_log,
  sonar_bridge_idempotency TO sonar_bridge_idempotency,
  sonar_bank_accounts      TO sonar_bank_accounts,
  sonar_bank_movements     TO sonar_bank_movements,
  sonar_escrows            TO sonar_escrows;

RENAME TABLE sonar_schema_versions TO sonar_schema_versions;

-- STEP 3: Restore FKs sonar_*
ALTER TABLE sonar_bank_accounts
  ADD CONSTRAINT fk_sonar_bank_accounts_owner_account
    FOREIGN KEY (owner_account_id) REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE sonar_escrows
  ADD CONSTRAINT fk_sonar_escrows_buyer
    FOREIGN KEY (buyer_account_id) REFERENCES sonar_bank_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE sonar_escrows
  ADD CONSTRAINT fk_sonar_escrows_seller
    FOREIGN KEY (seller_account_id) REFERENCES sonar_bank_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE sonar_escrows
  ADD CONSTRAINT fk_sonar_escrows_escrow_account
    FOREIGN KEY (escrow_account_id) REFERENCES sonar_bank_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- ============================================================================
-- FIN DOWN 009
-- ============================================================================
