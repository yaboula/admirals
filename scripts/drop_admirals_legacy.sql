-- Drop legacy admirals_* tables (S0+S1 dev data, no production)
-- FK-safe: drop child tables first
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS admirals_escrows;
DROP TABLE IF EXISTS admirals_bank_movements;
DROP TABLE IF EXISTS admirals_bank_accounts;
DROP TABLE IF EXISTS admirals_audit_log;
DROP TABLE IF EXISTS admirals_bridge_idempotency;
DROP TABLE IF EXISTS admirals_accounts;
DROP TABLE IF EXISTS admirals_schema_versions;
SET FOREIGN_KEY_CHECKS = 1;
SELECT 'admirals_* tables dropped — fresh sonar_* migrations ready' AS status;