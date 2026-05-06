-- ============================================================================
-- Migration: 014_bank_accounts_owner_type_split.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.2)
-- Description:
--   Refactoriza `sonar_bank_accounts.type` ENUM monolítico en 2 columnas
--   conceptualmente correctas (Q-DB-D LOCKED 2026-05-06):
--     - owner_type    ENUM tipo de propietario.
--     - account_class ENUM clase de cuenta (función contable).
--
--   Sustituye semántica mezclada (`type` mixaba ambos conceptos) por
--   modelado normalizado. Backfill data existente preservando integridad.
--
--   Añade además `last_reconciled_at INT UNSIGNED NULL` (CP3 trust window
--   - Backend Lead reconciliation pipeline).
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_accounts.type existe).
--
-- Reversible: parcial — DOWN restauraría `type` ENUM monolítico via UPDATE
--   reverse mapping + DROP nuevas columnas. Operación cara post-prod (rebuild
--   InnoDB rows). Documented en post-install notes.
--
-- SSoT references:
--   docs/technical/03_db_schema.md §29 Deviation Q-DB-D (NEW v1.3 DRAFT v0.1).
--   docs/agents/teams/01_SHARED_BRIEF.md §3 Q-DB-D (founder LOCKED 2026-05-06).
--
-- DECISIONES TÉCNICAS (founder Q-DB-D + Q-DB-A LOCKED 2026-05-06):
--
--   D1. Split en 2 columns:
--       - owner_type ENUM('personal','company','cooperative','government','escrow_managed')
--           ▸ describe QUIÉN es el propietario.
--           ▸ 'government' NEW para cuentas tesorería gobierno (SYS treasury).
--           ▸ 'escrow_managed' renombra 'escrow' clarificando que es cuenta
--             técnica gestionada por sistema, NO propiedad de un actor.
--
--       - account_class ENUM('checking','savings','business_treasury','govt_treasury','escrow','crypto_wallet')
--           ▸ describe FUNCIÓN CONTABLE de la cuenta.
--           ▸ 'checking' default para personal/company. Soporta 'savings'
--             tier 4 future-proof.
--           ▸ 'business_treasury' para cooperativas + empresas multi-signer.
--           ▸ 'govt_treasury' para tesorería gobierno (SYS treasury).
--           ▸ 'escrow' para cuentas técnicas escrow (FSM 6-states).
--           ▸ 'crypto_wallet' future-proof Tier 4 (Q-DB-B BIGINT atomic).
--
--   D2. Backfill mapping data existente:
--       type='personal'    → owner_type='personal',       account_class='checking'
--       type='company'     → owner_type='company',        account_class='checking'
--       type='cooperative' → owner_type='cooperative',    account_class='business_treasury'
--       type='escrow'      → owner_type='escrow_managed', account_class='escrow'
--
--       NOTA: SYS treasury (`AD-SYS0-0000-0001`) seed migration 004 tiene
--       `type='company'`. Backfill genérico produciría owner_type='company'
--       account_class='checking', SEMÁNTICAMENTE INCORRECTO. Post-backfill
--       UPDATE explícito SYS treasury → owner_type='government' +
--       account_class='govt_treasury' por IBAN match.
--
--   D3. ADD last_reconciled_at INT UNSIGNED NULL — CP3 trust window
--       reconciliation. NULL = nunca reconciliada. Backend Lead post-H1
--       lib `BankReconciliation.Apply()` actualiza este campo on-success.
--
--   D4. DROP index idx_sonar_bank_accounts_type_active (type, closed_at) — el
--       campo `type` desaparece. ADD index nuevo idx_sonar_bank_accounts_owner_type_class
--       (owner_type, account_class, closed_at) preservando coverage queries.
--
--   D5. NO modify CHECK constraint — D4 migration 003 ya documentó que CHECK
--       XOR está app-layer enforced (parser bug MariaDB 12.2.2). Sin cambio.
--
--   D6. ALTER TABLE sequence en transaction (START TRANSACTION + COMMIT).
--       MariaDB 12.x InnoDB DDL atomic — rollback completo si cualquier paso
--       falla.
--
--   D7. Column ordering: `owner_type` + `account_class` AFTER `iban` (mismo
--       lugar conceptual donde estaba `type`). MariaDB 12.x soporta `AFTER`
--       en ADD COLUMN.
--
--   D8. Idempotency: pre-flight check via INFORMATION_SCHEMA.COLUMNS — si
--       owner_type ya existe, abort gracefully (re-apply safe).
-- ============================================================================


START TRANSACTION;


-- ----------------------------------------------------------------------------
-- 1. Pre-flight idempotency check
--
-- Si owner_type ya existe → migration ya aplicada, abort gracefully.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_apply_014_bank_accounts_split;

DELIMITER $$

CREATE PROCEDURE sp_apply_014_bank_accounts_split()
BEGIN
  DECLARE col_count INT DEFAULT 0;

  SELECT COUNT(*) INTO col_count
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_accounts'
    AND COLUMN_NAME = 'owner_type';

  IF col_count = 0 THEN
    -- ------------------------------------------------------------------------
    -- 2. ADD nuevas columnas NULL initially (backfill después)
    -- ------------------------------------------------------------------------
    ALTER TABLE sonar_bank_accounts
      ADD COLUMN owner_type    ENUM('personal','company','cooperative','government','escrow_managed') NULL AFTER iban,
      ADD COLUMN account_class ENUM('checking','savings','business_treasury','govt_treasury','escrow','crypto_wallet') NULL AFTER owner_type,
      ADD COLUMN last_reconciled_at INT UNSIGNED NULL COMMENT 'CP3 trust window — Backend Lead reconciliation pipeline' AFTER closed_at;

    -- ------------------------------------------------------------------------
    -- 3. Backfill data existing → mapping per D2
    -- ------------------------------------------------------------------------
    UPDATE sonar_bank_accounts SET
      owner_type    = 'personal',
      account_class = 'checking'
    WHERE type = 'personal';

    UPDATE sonar_bank_accounts SET
      owner_type    = 'company',
      account_class = 'checking'
    WHERE type = 'company';

    UPDATE sonar_bank_accounts SET
      owner_type    = 'cooperative',
      account_class = 'business_treasury'
    WHERE type = 'cooperative';

    UPDATE sonar_bank_accounts SET
      owner_type    = 'escrow_managed',
      account_class = 'escrow'
    WHERE type = 'escrow';

    -- ------------------------------------------------------------------------
    -- 4. Override SYS treasury seed (migration 004) — corrección semántica
    --    SYS treasury es 'government' + 'govt_treasury' (NO 'company'+'checking').
    -- ------------------------------------------------------------------------
    UPDATE sonar_bank_accounts SET
      owner_type    = 'government',
      account_class = 'govt_treasury'
    WHERE iban = 'AD-SYS0-0000-0001';

    -- ------------------------------------------------------------------------
    -- 5. ALTER columns NOT NULL post-backfill
    -- ------------------------------------------------------------------------
    ALTER TABLE sonar_bank_accounts
      MODIFY COLUMN owner_type    ENUM('personal','company','cooperative','government','escrow_managed') NOT NULL,
      MODIFY COLUMN account_class ENUM('checking','savings','business_treasury','govt_treasury','escrow','crypto_wallet') NOT NULL;

    -- ------------------------------------------------------------------------
    -- 6. DROP index obsoleto + ADD index nuevo coverage
    -- ------------------------------------------------------------------------
    ALTER TABLE sonar_bank_accounts
      DROP KEY idx_sonar_bank_accounts_type_active,
      ADD KEY idx_sonar_bank_accounts_owner_type_class (owner_type, account_class, closed_at);

    -- ------------------------------------------------------------------------
    -- 7. DROP column `type` legacy
    --    NOTA: app-layer enforcement (server/accounts.lua) debe actualizarse
    --    a leer/escribir owner_type + account_class. Backend Lead post-H1
    --    handoff scope.
    -- ------------------------------------------------------------------------
    ALTER TABLE sonar_bank_accounts
      DROP COLUMN type;
  END IF;
END$$

DELIMITER ;

CALL sp_apply_014_bank_accounts_split();
DROP PROCEDURE sp_apply_014_bank_accounts_split;


COMMIT;


-- ============================================================================
-- POST-INSTALL verification queries (manual run en HeidiSQL):
--
--   SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE
--   FROM INFORMATION_SCHEMA.COLUMNS
--   WHERE TABLE_SCHEMA = DATABASE()
--     AND TABLE_NAME = 'sonar_bank_accounts'
--     AND COLUMN_NAME IN ('owner_type','account_class','last_reconciled_at','type')
--   ORDER BY ORDINAL_POSITION;
--
--   Expected: 3 rows (owner_type NOT NULL ENUM, account_class NOT NULL ENUM,
--   last_reconciled_at NULLABLE INT UNSIGNED). NO row for 'type' (dropped).
--
--   SELECT iban, owner_type, account_class FROM sonar_bank_accounts WHERE iban='AD-SYS0-0000-0001';
--   Expected: ('AD-SYS0-0000-0001', 'government', 'govt_treasury').
--
-- BACKEND LEAD post-H1 actions required:
--   1. Update server/accounts.lua CreateAccount() to receive owner_type + account_class params.
--   2. Update queries SELECT/UPDATE references `type` → use new columns.
--   3. Update repos + libs Bank-domain consuming `type`.
-- ============================================================================
