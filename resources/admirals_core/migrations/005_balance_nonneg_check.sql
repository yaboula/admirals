-- ============================================================================
-- Migration: 005_balance_nonneg_check.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.2 fix-and-validate)
-- Description:
--   Añadir CHECK constraint `chk_admirals_bank_accounts_balance_nonneg`
--   que enforce balance >= 0 SQL-side. Resuelve race window de S1.2 transfer
--   atomicity por construcción: si concurrent op vacía saldo entre pre-fetch
--   y UPDATE balance = balance - amount, MySQL rechaza el UPDATE (CHECK
--   violated) → toda la TX rollback automático per oxmysql native behavior.
--   Ledger queda 100% consistente. NO requiere function-form transaction
--   (oxmysql NO lo soporta — verificado en doc /Functions/transaction).
--
-- Supersedes intent del comment migration 003:79 ("negativo = overdraft
-- admin-only"). S1-S3 roadmap NO incluye overdraft. Bloqueo hard via CHECK.
-- Si S2+ requiere overdraft admin-only:
--   ALTER TABLE admirals_bank_accounts DROP CHECK chk_admirals_bank_accounts_balance_nonneg;
-- + add conditional CHECK con admin_overdraft_enabled flag column (non-breaking, opt-in).
--
-- Migration inmutable: NO editar 003 post-aplicada (S0.4 design — checksum
-- tracked en admirals_schema_versions). Refresh comment 003 deferred S2+
-- via migration aditiva si overdraft entra roadmap.
--
-- Reversible: sí (DROP CHECK).
--
-- Dependencies:
--   - 003_bank_schema (admirals_bank_accounts table existe).
--
-- DECISIONES TÉCNICAS (founder green-light 2026-05-02 fix-and-validate):
--
--   D1. CHECK > app-side defense en WHERE clause. WHERE balance >= ? era
--       silent failure (UPDATE 0 rows, TX commits) — no aborta. CHECK fuerza
--       SQL error → MySQL.transaction.await retorna false → DB.Transaction
--       returns false → Transfer.Execute mapea a TX_ROLLBACK / RACE_DETECTED.
--
--   D2. MariaDB 10.2+ y MySQL 8.0.16+ enforce CHECK nativamente. Versiones
--       previas lo IGNORAN silenciosamente — degrade gracefully a S1.2 race
--       behavior previo. Producción Admirals targets MariaDB 10.6+ per
--       SSoT §03 §1.2 (a verificar — no es S1.2 scope confirm exact ver).
--
--   D3. Constraint name explicit (chk_admirals_bank_accounts_balance_nonneg)
--       — idiomatic per S0.4 + S1.1 pattern. Permite ALTER DROP/ADD
--       referenciando por nombre.
--
--   D4. ALTER TABLE ADD CONSTRAINT IF NOT EXISTS — defense-in-depth contra
--       manual re-run (idempotent). Runner tracking en admirals_schema_versions
--       ya garantiza single-apply, pero IF NOT EXISTS preserva el behavior
--       en case admin maintenance manual.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Pre-flight: verificar que no hay rows con balance < 0 actualmente.
--    Si existieran (no debería en S1.2, pero defense-in-depth), el ALTER
--    fallaría con FK error — preferimos detectar pre-flight y abortar
--    con mensaje claro.
--
-- NOTA: SELECT statement aquí es informativo. MySQL aborta el ALTER si encuentra
-- violaciones; este SELECT solo facilita diagnostic en logs si falla.
-- ----------------------------------------------------------------------------
SELECT
  CONCAT('PRE-FLIGHT: ', COUNT(*), ' row(s) with balance < 0 (must be 0 for ALTER to succeed)') AS preflight_check
FROM admirals_bank_accounts
WHERE balance < 0;


-- ----------------------------------------------------------------------------
-- 2. ADD CHECK constraint balance >= 0.
--
-- Sintaxis MariaDB 10.2+ / MySQL 8.0.16+. Si la versión NO soporta CHECK
-- enforcement, el ALTER se ejecuta sin error pero el CHECK es ignored —
-- atomicity revierte a S1.2 race behavior (ledger eventual via reconciliation).
-- ----------------------------------------------------------------------------
ALTER TABLE admirals_bank_accounts
ADD CONSTRAINT chk_admirals_bank_accounts_balance_nonneg
CHECK (balance >= 0);
