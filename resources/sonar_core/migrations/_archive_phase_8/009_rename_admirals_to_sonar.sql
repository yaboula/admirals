-- ============================================================================
-- Migration: 009_rename_sonar_to_sonar.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-04 (Phase 9 — ADR-013 namespace migration)
-- Description:
--   Renombra las 6 tablas del namespace `sonar_*` al namespace `sonar_*`
--   y actualiza coherentemente todos los índices, constraints y FKs.
--
--   Tablas renombradas:
--     sonar_schema_versions      → sonar_schema_versions
--     sonar_accounts             → sonar_accounts
--     sonar_audit_log            → sonar_audit_log
--     sonar_bridge_idempotency   → sonar_bridge_idempotency
--     sonar_bank_accounts        → sonar_bank_accounts
--     sonar_bank_movements       → sonar_bank_movements
--     sonar_escrows              → sonar_escrows
--
--   Orden de rename: FK-safe (constraints dropped antes de RENAME donde
--   necesario; re-added con nombres sonar_* post-RENAME).
--
-- Dependencies:
--   - 001 → 008 aplicados (todas las tablas existen en namespace sonar_*).
--
-- Reversible:
--   Sí. Ver sección DOWN al final del file (comentada — ejecutar manual).
--   NO ejecutar DOWN post-prod con datos reales sin backup + founder approval.
--
-- Idempotency:
--   RENAME TABLE es atómica en InnoDB. Si la tabla destino ya existe (post
--   partial apply), MySQL retorna error. El runner de migrations tracking
--   garantiza single-apply vía sonar_schema_versions (bootstrapped aquí mismo).
--
-- NOTA BOOTSTRAP:
--   Esta migration es especial: renombra la propia tabla de tracking.
--   El runner (migrations.lua) verifica en sonar_schema_versions tras el apply.
--   Secuencia segura:
--     1. RENAME sonar_schema_versions → sonar_schema_versions.
--     2. Aplicar resto de renames.
--     3. El runner ya lee sonar_schema_versions en el verify step (por código
--        post-Phase 8 refactor que usa 'sonar_schema_versions' hardcoded).
--
-- SSoT references:
--   docs/technical/03_db_schema.md §12.2 (schema_versions).
--   docs/planning/02_decision_log.md ADR-013 (Phase 9 DB migration).
-- ============================================================================


-- ============================================================================
-- UP — Rename sonar_* → sonar_*
-- ============================================================================


-- ----------------------------------------------------------------------------
-- STEP 0: Rename tracking table (idempotente).
-- El pre-step en init.lua puede haberla renombrado ya en upgrade path.
-- Si sonar_schema_versions ya no existe (fresh install o pre-step aplicado)
-- este statement es no-op via IF EXISTS guard.
-- MariaDB 10.5+ soporta RENAME TABLE ... IF EXISTS. Para compat universal
-- usamos el patrón condicional vía stored procedure inline.
-- En la práctica: el pre-step en init.lua garantiza que esta rename ya
-- ocurrió antes de que el runner ejecute este file. Por tanto este statement
-- es ALWAYS a no-op aquí. Se mantiene como documentación + safety net.
-- ----------------------------------------------------------------------------
RENAME TABLE IF EXISTS sonar_schema_versions TO sonar_schema_versions;


-- ----------------------------------------------------------------------------
-- STEP 1: Drop FKs que referencian sonar_accounts desde sonar_escrows.
-- Necesario antes del RENAME de sonar_accounts (FK target change).
-- Los FKs de sonar_bank_accounts → sonar_accounts también se dropan
-- aquí para evitar issues durante el chain rename.
-- ----------------------------------------------------------------------------

-- FK: sonar_bank_accounts → sonar_accounts
ALTER TABLE sonar_bank_accounts
  DROP FOREIGN KEY IF EXISTS fk_sonar_bank_accounts_owner_account;

-- FK: sonar_escrows → sonar_bank_accounts (buyer + seller + escrow_account)
ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_buyer;

ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_seller;

ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_escrow_account;


-- ----------------------------------------------------------------------------
-- STEP 2: Rename las 6 tablas de datos (atómico por batch).
-- MySQL RENAME TABLE batch es atómico — all-or-nothing.
-- ----------------------------------------------------------------------------
RENAME TABLE
  sonar_accounts           TO sonar_accounts,
  sonar_audit_log          TO sonar_audit_log,
  sonar_bridge_idempotency TO sonar_bridge_idempotency,
  sonar_bank_accounts      TO sonar_bank_accounts,
  sonar_bank_movements     TO sonar_bank_movements,
  sonar_escrows            TO sonar_escrows;


-- ----------------------------------------------------------------------------
-- STEP 3: Rename índices en sonar_bank_accounts.
--
-- MySQL no tiene RENAME INDEX directo pre-8.0. Usamos ALTER TABLE DROP + ADD.
-- Los índices de tipo UNIQUE KEY y KEY se recrean con nombres sonar_*.
-- PRIMARY KEY no se toca (no tiene nombre canónico dependiente del prefix).
-- ----------------------------------------------------------------------------

-- sonar_bank_accounts: UNIQUE KEY + KEYs + CHECKs
ALTER TABLE sonar_bank_accounts
  DROP INDEX IF EXISTS uq_sonar_bank_accounts_iban,
  ADD  UNIQUE KEY uq_sonar_bank_accounts_iban (iban);

ALTER TABLE sonar_bank_accounts
  DROP INDEX IF EXISTS idx_sonar_bank_accounts_owner_account,
  ADD  KEY idx_sonar_bank_accounts_owner_account (owner_account_id);

ALTER TABLE sonar_bank_accounts
  DROP INDEX IF EXISTS idx_sonar_bank_accounts_owner_company,
  ADD  KEY idx_sonar_bank_accounts_owner_company (owner_company_id);

ALTER TABLE sonar_bank_accounts
  DROP INDEX IF EXISTS idx_sonar_bank_accounts_type_active,
  ADD  KEY idx_sonar_bank_accounts_type_active (type, closed_at);

-- CHECK constraints en sonar_bank_accounts (renombrar vía DROP + ADD)
ALTER TABLE sonar_bank_accounts
  DROP CONSTRAINT IF EXISTS chk_sonar_bank_accounts_owner_xor_or_escrow,
  ADD  CONSTRAINT chk_sonar_bank_accounts_owner_xor_or_escrow CHECK (
    type = 'escrow'
    OR (type = 'personal' AND owner_account_id IS NOT NULL AND owner_company_id IS NULL)
    OR (type IN ('company','cooperative') AND owner_company_id IS NOT NULL AND owner_account_id IS NULL)
  );

ALTER TABLE sonar_bank_accounts
  DROP CONSTRAINT IF EXISTS chk_sonar_bank_accounts_balance_nonneg,
  ADD  CONSTRAINT chk_sonar_bank_accounts_balance_nonneg CHECK (balance >= 0);


-- ----------------------------------------------------------------------------
-- STEP 4: Rename índices en sonar_accounts.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_accounts
  DROP INDEX IF EXISTS uq_sonar_accounts_char_framework,
  ADD  UNIQUE KEY uq_sonar_accounts_char_framework (char_id, framework_source);

ALTER TABLE sonar_accounts
  DROP INDEX IF EXISTS idx_sonar_accounts_char_id,
  ADD  KEY idx_sonar_accounts_char_id (char_id);

ALTER TABLE sonar_accounts
  DROP INDEX IF EXISTS idx_sonar_accounts_framework,
  ADD  KEY idx_sonar_accounts_framework (framework_source);


-- ----------------------------------------------------------------------------
-- STEP 5: Rename índices en sonar_audit_log.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_audit_log
  DROP INDEX IF EXISTS idx_sonar_audit_log_ts,
  ADD  KEY idx_sonar_audit_log_ts (ts DESC);

ALTER TABLE sonar_audit_log
  DROP INDEX IF EXISTS idx_sonar_audit_log_actor,
  ADD  KEY idx_sonar_audit_log_actor (actor_account_id, ts DESC);

ALTER TABLE sonar_audit_log
  DROP INDEX IF EXISTS idx_sonar_audit_log_target,
  ADD  KEY idx_sonar_audit_log_target (target_type, target_id, ts DESC);

ALTER TABLE sonar_audit_log
  DROP INDEX IF EXISTS idx_sonar_audit_log_category,
  ADD  KEY idx_sonar_audit_log_category (category, ts DESC);

ALTER TABLE sonar_audit_log
  DROP INDEX IF EXISTS idx_sonar_audit_log_request,
  ADD  KEY idx_sonar_audit_log_request (request_id);


-- ----------------------------------------------------------------------------
-- STEP 6: Rename índices en sonar_bridge_idempotency.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_bridge_idempotency
  DROP INDEX IF EXISTS idx_sonar_bridge_idempotency_expires,
  ADD  KEY idx_sonar_bridge_idempotency_expires (expires_at);

ALTER TABLE sonar_bridge_idempotency
  DROP INDEX IF EXISTS idx_sonar_bridge_idempotency_module_method,
  ADD  KEY idx_sonar_bridge_idempotency_module_method (module, method, created_at DESC);


-- ----------------------------------------------------------------------------
-- STEP 7: Rename índices en sonar_bank_movements.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_bank_movements
  DROP INDEX IF EXISTS idx_sonar_bank_movements_account,
  ADD  KEY idx_sonar_bank_movements_account (bank_account_id, occurred_at DESC);

ALTER TABLE sonar_bank_movements
  DROP INDEX IF EXISTS idx_sonar_bank_movements_category,
  ADD  KEY idx_sonar_bank_movements_category (category, occurred_at DESC);

ALTER TABLE sonar_bank_movements
  DROP INDEX IF EXISTS idx_sonar_bank_movements_nonce,
  ADD  KEY idx_sonar_bank_movements_nonce (request_nonce);

ALTER TABLE sonar_bank_movements
  DROP INDEX IF EXISTS idx_sonar_bank_movements_related_doc,
  ADD  KEY idx_sonar_bank_movements_related_doc (related_doc_id);

ALTER TABLE sonar_bank_movements
  DROP INDEX IF EXISTS idx_sonar_bank_movements_related_offer,
  ADD  KEY idx_sonar_bank_movements_related_offer (related_offer_id);

ALTER TABLE sonar_bank_movements
  DROP INDEX IF EXISTS idx_sonar_bank_movements_related_job,
  ADD  KEY idx_sonar_bank_movements_related_job (related_job_id);


-- ----------------------------------------------------------------------------
-- STEP 8: Rename índices y constraints en sonar_escrows.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_escrows
  DROP INDEX IF EXISTS uq_sonar_escrows_request_nonce,
  ADD  UNIQUE KEY uq_sonar_escrows_request_nonce (request_nonce);

ALTER TABLE sonar_escrows
  DROP INDEX IF EXISTS idx_sonar_escrows_buyer,
  ADD  KEY idx_sonar_escrows_buyer (buyer_account_id);

ALTER TABLE sonar_escrows
  DROP INDEX IF EXISTS idx_sonar_escrows_seller,
  ADD  KEY idx_sonar_escrows_seller (seller_account_id);

ALTER TABLE sonar_escrows
  DROP INDEX IF EXISTS idx_sonar_escrows_escrow_account,
  ADD  KEY idx_sonar_escrows_escrow_account (escrow_account_id);

ALTER TABLE sonar_escrows
  DROP INDEX IF EXISTS idx_sonar_escrows_status_expires,
  ADD  KEY idx_sonar_escrows_status_expires (status, expires_at);

ALTER TABLE sonar_escrows
  DROP INDEX IF EXISTS idx_sonar_escrows_contract,
  ADD  KEY idx_sonar_escrows_contract (contract_id);

ALTER TABLE sonar_escrows
  DROP CONSTRAINT IF EXISTS chk_sonar_escrows_amount_positive,
  ADD  CONSTRAINT chk_sonar_escrows_amount_positive CHECK (amount > 0);

ALTER TABLE sonar_escrows
  DROP CONSTRAINT IF EXISTS chk_sonar_escrows_fee_nonneg,
  ADD  CONSTRAINT chk_sonar_escrows_fee_nonneg CHECK (fee_charged >= 0);


-- ----------------------------------------------------------------------------
-- STEP 9: Re-add FKs con nombres sonar_* apuntando a tablas sonar_*.
-- ----------------------------------------------------------------------------

-- FK: sonar_bank_accounts → sonar_accounts
ALTER TABLE sonar_bank_accounts
  ADD CONSTRAINT fk_sonar_bank_accounts_owner_account
    FOREIGN KEY (owner_account_id) REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- FKs: sonar_escrows → sonar_bank_accounts
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


-- ----------------------------------------------------------------------------
-- STEP 10: Rename sonar_schema_versions UNIQUE KEY.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_schema_versions
  DROP INDEX IF EXISTS uq_sonar_schema_versions_filename,
  ADD  UNIQUE KEY uq_sonar_schema_versions_filename (filename);


-- ============================================================================
-- FIN UP — 009_rename_sonar_to_sonar.sql
-- ============================================================================


-- ============================================================================
-- DOWN — ver 009_rename_sonar_to_sonar.DOWN.sql (script manual separado).
-- NO incluido aquí para evitar que el splitter del runner lo parsee.
-- ============================================================================

-- ============================================================================
-- FIN 009_rename_sonar_to_sonar.sql
-- ============================================================================
