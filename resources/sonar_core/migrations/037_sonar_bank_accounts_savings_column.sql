-- ============================================================================
-- Migration: 037_sonar_bank_accounts_savings_column.sql
-- Author: Lead Dev (Cascade) + yaboula
-- Date: 2026-05-13 (Phase consumer-side closeout 2.2)
-- Description:
--   Añade columna `savings` a `sonar_bank_accounts` para soportar el flujo
--   real de Savings (Phase 2.2 consumer-side closeout). El frontend +
--   bootstrap snapshot (C001) leen `COALESCE(a.savings, 0)` para exponer
--   `savings_minor` al cliente NUI.
--
-- Idempotente: ADD COLUMN IF NOT EXISTS — reapply safe.
-- Charset/collation: heredados de la tabla (utf8mb4_unicode_ci).
-- Default 0 + NOT NULL: evita nulls en queries existentes y mantiene
-- semántica consistente con balance.
--
-- SSoT: progress/PHASE_1_6_TO_2_3_CLOSEOUT.md (Lead Dev Phase 2.2 evidence)
-- Origen archivo: era resources/sonar_bank_app/server/migrations/037_sonar_bank_savings.sql
-- pero el runner sonar_core solo registra desde resources/sonar_core/migrations/.
-- Trasladado aquí para ejecución automática en boot.
-- ============================================================================

ALTER TABLE sonar_bank_accounts
  ADD COLUMN IF NOT EXISTS savings DECIMAL(14,2) NOT NULL DEFAULT 0 AFTER balance;
