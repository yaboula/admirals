-- ============================================================================
-- Migration: 015_bank_movements_category_extend.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.2)
-- Description:
--   Extiende ENUM `sonar_bank_movements.category` añadiendo 11 nuevos valores
--   canonical Phase A (Tax + Government + Tier 4 + Compliance event types).
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_movements existe).
--
-- Reversible: parcial — DOWN ALTER TABLE MODIFY COLUMN ENUM volviendo a
--   subset original es seguro SI no hay rows existing con valores nuevos.
--   Si hay rows con nuevos valores → DOWN falla por integrity.
--
-- SSoT references:
--   docs/technical/03_db_schema.md §0.1 changelog "Tablas existing extends".
--   docs/agents/teams/01_SHARED_BRIEF.md §3.10 Q10 + §3.11 Q11 (tax flows + Tier 4).
--
-- DECISIONES TÉCNICAS (founder Q-DB-A LOCKED 2026-05-06):
--
--   D1. ENUM extension via ALTER TABLE MODIFY COLUMN — MariaDB 12.x soporta
--       extending ENUM aditivamente sin rebuild de toda la tabla cuando solo
--       se añaden valores AL FINAL. Performance crítica para tabla
--       particionada con potencialmente millones de rows (Q16.5 chaos).
--
--       NOTA: añadir valores en medio del ENUM REQUIERE rebuild físico full.
--       Por eso AÑADIMOS AL FINAL preservando orden existing.
--
--   D2. 11 nuevos valores canonical agrupados por dominio:
--
--       Tax + Government (§24):
--         - 'tax_subsidy'         — subsidio gobierno emitido a citizen.
--
--       Tier 4 — Loans (§25):
--         - 'loan_disbursement'   — desembolso préstamo (positive amount).
--         - 'loan_repayment'      — repago cuota préstamo (negative amount).
--
--       Tier 4 — Crypto (§25):
--         - 'crypto_buy'          — compra crypto (negative fiat).
--         - 'crypto_sell'         — venta crypto (positive fiat).
--
--       Tier 4 — Stocks (§25):
--         - 'stock_buy'           — compra acciones.
--         - 'stock_sell'          — venta acciones.
--
--       Tier 4 — Recurring (§25):
--         - 'recurring_charge'    — cargo recurrente (suscripción, alquiler).
--
--       Tier 4 — Round-ups (§25):
--         - 'round_up'            — redondeo savings.
--
--       Tier 4 — Loyalty (§25):
--         - 'loyalty_redeem'      — canje puntos loyalty (positive).
--
--       Compliance (§22):
--         - 'compliance_freeze'   — congelación admin/watchdog (movement
--                                    técnico amount=0 + audit trail).
--
--   D3. NO 'starter_seed' renombre — conservar legacy seed migration 004
--       compat. Rows existing preservadas.
--
--   D4. Idempotency: pre-flight check INFORMATION_SCHEMA.COLUMNS para detectar
--       si nuevos valores ya en ENUM definition. Si sí → abort gracefully.
--
--   D5. Index idx_sonar_bank_movements_category sigue válido — ENUM extension
--       no afecta index B-tree (columna sigue mismo tipo lógico).
-- ============================================================================


START TRANSACTION;


-- ----------------------------------------------------------------------------
-- 1. Pre-flight idempotency check
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_apply_015_movements_category_extend;

DELIMITER $$

CREATE PROCEDURE sp_apply_015_movements_category_extend()
BEGIN
  DECLARE col_def TEXT DEFAULT '';

  SELECT COLUMN_TYPE INTO col_def
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_movements'
    AND COLUMN_NAME = 'category';

  -- Si 'tax_subsidy' ya está en ENUM → migration ya aplicada.
  IF col_def NOT LIKE '%tax_subsidy%' THEN
    -- ----------------------------------------------------------------------
    -- 2. ALTER TABLE MODIFY COLUMN — extender ENUM aditivamente
    --
    -- Preservamos orden existing (12 valores originales + 'starter_seed') y
    -- añadimos 11 nuevos AL FINAL para evitar rebuild físico (D1).
    -- ----------------------------------------------------------------------
    ALTER TABLE sonar_bank_movements
      MODIFY COLUMN category ENUM(
        -- Original 13 valores (preservados orden):
        'salary',
        'b2b_payment',
        'transfer',
        'tax',
        'refund',
        'b2c_sale',
        'expense',
        'deposit',
        'withdrawal',
        'escrow_lock',
        'escrow_release',
        'adjustment',
        'starter_seed',
        -- NEW 11 valores Phase A (orden: tax → loans → crypto → stocks → recurring → round_up → loyalty → compliance):
        'tax_subsidy',
        'loan_disbursement',
        'loan_repayment',
        'crypto_buy',
        'crypto_sell',
        'stock_buy',
        'stock_sell',
        'recurring_charge',
        'round_up',
        'loyalty_redeem',
        'compliance_freeze'
      ) NOT NULL COMMENT 'categoría contable Phase A — 24 valores canonical';
  END IF;
END$$

DELIMITER ;

CALL sp_apply_015_movements_category_extend();
DROP PROCEDURE sp_apply_015_movements_category_extend;


COMMIT;


-- ============================================================================
-- POST-INSTALL verification:
--
--   SELECT COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS
--   WHERE TABLE_SCHEMA = DATABASE()
--     AND TABLE_NAME = 'sonar_bank_movements' AND COLUMN_NAME = 'category';
--
--   Expected: ENUM con 24 valores (13 originales + 11 nuevos).
-- ============================================================================
