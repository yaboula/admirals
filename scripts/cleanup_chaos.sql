-- Cleanup solo de registros de chaos (no destruye tablas completas)
SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM sonar_bank_movements WHERE bank_account_id LIKE 'cha05001-%';
DELETE FROM sonar_bank_accounts WHERE owner_account_id LIKE 'cha05000-%';
DELETE FROM sonar_accounts WHERE char_id LIKE 'CHAOS_PLAYER_%';

SET FOREIGN_KEY_CHECKS = 1;

SELECT 'Chaos cleanup completed' AS status;
