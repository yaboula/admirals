-- ============================================================================
-- Migration: 008_escrow_fks_revert_to_bank_accounts.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.3 fix-forward 2/2)
-- Description:
--   Revert de migration 007 — los FKs `admirals_escrows.buyer_account_id` y
--   `seller_account_id` vuelven a apuntar a `admirals_bank_accounts(id)`
--   (como fueron en migration 006).
--
--   Decisión de diseño (founder S1.3 smoke review):
--     Los escrows se linkean a **cuentas bancarias específicas**, NO a player
--     identities. Alineado con `escrow_account_id` (ya FK bank_accounts). Los
--     tres campos buyer/seller/escrow_account_id ahora son homogéneos.
--
--   Ventajas:
--     - Auditoría más directa: cada escrow referencia 3 bank accounts concretas.
--     - Auth robusto: resolver owner del bank_account stored via lookup SQL,
--       sin depender de caches session que pueden quedar stale.
--     - Consistencia interna: todos los "*_account_id" del schema refieren
--       bank accounts; player identity se resuelve cuando se necesita.
--
-- Dependencies:
--   - 006_escrow_schema.sql (tabla admirals_escrows).
--   - 007_escrow_fks_to_accounts.sql (FKs a revertir).
--
-- TRUNCATE safe:
--   S1.3 smoke phase — 0 production rows. Los escrows de test fueron creados
--   con identity values en buyer/seller_account_id que ya NO son válidos
--   post-revert. TRUNCATE elimina esos rows huérfanos + resetea clean slate.
--
-- DECISIONES TÉCNICAS:
--
--   D1. TRUNCATE TABLE admirals_escrows PRE-DROP-FK — elimina rows con
--       identity stored (inconsistentes con nuevos FKs). Safe porque:
--       - 0 production escrows (S1.3 aún no shipped).
--       - Todos los rows actuales son artefactos de smoke pre-fix.
--
--   D2. `ON DELETE RESTRICT ON UPDATE CASCADE` idéntico a migration 006
--       original (preserva legal integrity §1.6).
--
--   D3. Code en `escrow.lua` también se actualiza en mismo commit para
--       almacenar bank_accounts.id (buyer_acc.id, seller_acc.id) en lugar
--       de identity (.owner_account_id). Auth resuelto vía lookup explícito.
--
--   D4. ADR-010 respected — 006/007 no editados. 008 es aditivo + documenta
--       la evolución del diseño (006 correcto → 007 mistake → 008 canonical).
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Truncate inconsistent smoke rows.
-- ----------------------------------------------------------------------------
TRUNCATE TABLE admirals_escrows;


-- ----------------------------------------------------------------------------
-- 2. Drop FKs de migration 007 (apuntan a admirals_accounts).
-- ----------------------------------------------------------------------------
ALTER TABLE admirals_escrows
  DROP FOREIGN KEY IF EXISTS fk_admirals_escrows_buyer;

ALTER TABLE admirals_escrows
  DROP FOREIGN KEY IF EXISTS fk_admirals_escrows_seller;


-- ----------------------------------------------------------------------------
-- 3. Re-add FKs apuntando a admirals_bank_accounts(id) — como diseño original
--    migration 006, ahora aligned con el código.
-- ----------------------------------------------------------------------------
ALTER TABLE admirals_escrows
  ADD CONSTRAINT fk_admirals_escrows_buyer
    FOREIGN KEY (buyer_account_id) REFERENCES admirals_bank_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE admirals_escrows
  ADD CONSTRAINT fk_admirals_escrows_seller
    FOREIGN KEY (seller_account_id) REFERENCES admirals_bank_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;


-- ============================================================================
-- FIN migration 008_escrow_fks_revert_to_bank_accounts.sql
-- ============================================================================
