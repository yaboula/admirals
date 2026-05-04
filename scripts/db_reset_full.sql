-- ============================================================================
-- db_reset_full.sql
-- DROP completo de todas las tablas sonar_* y admirals_* (legacy + new).
-- Ejecutar MANUALMENTE desde consola MySQL/HeidiSQL ANTES de arrancar server.
-- Server aplicará migrations 001-009 from scratch en el next boot.
--
-- ADVERTENCIA: DESTRUYE TODOS LOS DATOS. Solo para dev/staging.
-- Founder approval requerido. NO ejecutar en prod.
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- Tablas sonar_* (post-migration 009 o fresh install)
DROP TABLE IF EXISTS sonar_escrows;
DROP TABLE IF EXISTS sonar_bank_movements;
DROP TABLE IF EXISTS sonar_bank_accounts;
DROP TABLE IF EXISTS sonar_bridge_idempotency;
DROP TABLE IF EXISTS sonar_audit_log;
DROP TABLE IF EXISTS sonar_accounts;
DROP TABLE IF EXISTS sonar_schema_versions;

-- Tablas admirals_* (legacy — por si 009 no se aplicó aún)
DROP TABLE IF EXISTS admirals_escrows;
DROP TABLE IF EXISTS admirals_bank_movements;
DROP TABLE IF EXISTS admirals_bank_accounts;
DROP TABLE IF EXISTS admirals_bridge_idempotency;
DROP TABLE IF EXISTS admirals_audit_log;
DROP TABLE IF EXISTS admirals_accounts;
DROP TABLE IF EXISTS admirals_schema_versions;

SET FOREIGN_KEY_CHECKS = 1;

-- Verificar limpieza:
SELECT table_name
  FROM information_schema.tables
  WHERE table_schema = DATABASE()
    AND (table_name LIKE 'sonar_%' OR table_name LIKE 'admirals_%');
-- → debe devolver 0 rows.

-- ============================================================================
-- FIN db_reset_full.sql
-- Próximo paso: arrancar server → migrations 001-009 se aplican automáticamente.
-- ============================================================================
