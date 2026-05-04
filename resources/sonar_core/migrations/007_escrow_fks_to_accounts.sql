-- ============================================================================
-- Migration: 007_escrow_fks_to_accounts.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.3 fix-forward)
-- Description:
--   Corrige FK targets de `sonar_escrows.buyer_account_id` y
--   `seller_account_id` — apuntaban incorrectamente a
--   `sonar_bank_accounts(id)` en migration 006 (error conceptual).
--
--   Semántica correcta (alineada con el código S1.3 ya escrito):
--     - buyer_account_id, seller_account_id → sonar_accounts(id)
--       (player identity — permite que el buyer/seller cambie de bank account
--        en el futuro sin romper FK; auth matrix C005 hace caller_account_id
--        == stored value, chequeo a nivel identity).
--     - escrow_account_id → sonar_bank_accounts(id)
--       (cuenta técnica server-managed — FK correcto desde 006, no se toca).
--
-- Dependencies:
--   - 006_escrow_schema.sql (crea FKs originales a sonar_bank_accounts).
--
-- Reversible:
--   Sí en dev. DROP nuevos FKs + re-ADD originales a sonar_bank_accounts(id).
--
-- Symptom pre-007:
--   INSERT INTO sonar_escrows ... VALUES (..., 'a816aa90-...', ...) →
--   "Cannot add or update a child row: a foreign key constraint fails
--   (sonar_escrows, CONSTRAINT fk_sonar_escrows_buyer FOREIGN KEY
--   (buyer_account_id) REFERENCES sonar_bank_accounts (id))"
--
-- DECISIONES TÉCNICAS:
--
--   D1. NO modifico migration 006 in-place — ADR-010 immutability
--       (checksum guard). Este migration es aditivo per `003 → 004 → 005` pattern.
--
--   D2. SAFE en fresh install + existing DB:
--       - Fresh install: 006 crea FKs a bank_accounts, 007 los DROP+recreate a
--         sonar_accounts. Red de operaciones atomic DDL (InnoDB).
--       - Existing DB S1.3 pre-fix: 006 aplicado, 0 rows en sonar_escrows
--         (los INSERTs fallaron por FK violation, rolled back). DROP FK inocuo.
--
--   D3. `ON DELETE RESTRICT ON UPDATE CASCADE` preservado (legal integrity
--       per SSoT §1.6 y D7 de migration 006).
--
--   D4. Índices `idx_sonar_escrows_buyer`, `idx_sonar_escrows_seller`
--       NO se tocan — seguirán apoyando queries by buyer/seller_account_id
--       (solo cambia la tabla a la que el valor referencia, no el índice).
--
--   D5. S2+ extension path: cuando company pueda ser buyer/seller, añadir
--       columnas buyer_company_id + seller_company_id + CHECK XOR (mismo
--       pattern que sonar_bank_accounts.owner_account_id/owner_company_id).
--       Out of scope S1.3.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Drop FKs incorrectos de migration 006 (si existen).
--    `DROP FOREIGN KEY IF EXISTS` es MariaDB 10.4+ safe.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_buyer;

ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_seller;


-- ----------------------------------------------------------------------------
-- 2. Add FKs correctos apuntando a sonar_accounts(id).
--
-- NOTE: `ADD CONSTRAINT IF NOT EXISTS` no existe en MariaDB para FKs. Este
-- migration usa `ADD CONSTRAINT` directo — si ya existe un FK con el mismo
-- nombre tras drop, el previous DROP IF EXISTS lo eliminó. Para re-apply
-- idempotency: el migrations runner skipea via schema_versions tracking,
-- NO re-ejecuta este file. Safe.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_escrows
  ADD CONSTRAINT fk_sonar_escrows_buyer
    FOREIGN KEY (buyer_account_id) REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE sonar_escrows
  ADD CONSTRAINT fk_sonar_escrows_seller
    FOREIGN KEY (seller_account_id) REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;


-- ============================================================================
-- FIN migration 007_escrow_fks_to_accounts.sql
-- ============================================================================
