-- ============================================================================
-- Migration: 038_sonar_bank_physical_cards_monthly_limit.sql
-- Author: AI Full Stack (BANK-FLOW.AUDIT.1) + yaboula
-- Date: 2026-05-15
-- Description:
--   Adds monthly limit + monthly usage columns to sonar_bank_physical_cards
--   so the C035 sonar:bank:card:setLimits flow can persist both daily and
--   monthly ceilings, and the bootstrap snapshot can return real spend
--   counters instead of hardcoded zeros.
--
-- Dependencies: 023_bank_physical_cards.sql.
--
-- Notes:
--   - DECIMAL(14,2) keeps the existing major-unit storage convention;
--     server code converts to/from minor units (× 100) at the boundary.
--   - Idempotent ALTER (IF NOT EXISTS) so re-runs are safe.
--   - Non-negative check mirrors daily_limit_nonneg.
-- ============================================================================

START TRANSACTION;

ALTER TABLE sonar_bank_physical_cards
  ADD COLUMN IF NOT EXISTS monthly_limit DECIMAL(14,2) NULL
    COMMENT 'NULL = no monthly cap; otherwise overrides bank_account monthly cap',
  ADD COLUMN IF NOT EXISTS monthly_used DECIMAL(14,2) NOT NULL DEFAULT 0
    COMMENT 'Rolling monthly spend used; reset by daily_reset job logic',
  ADD COLUMN IF NOT EXISTS monthly_reset_at INT UNSIGNED NULL
    COMMENT 'UNIX_TIMESTAMP() of next monthly counter reset';

-- Non-negative guards (best-effort: fail silently if already present).
-- MySQL 8 / MariaDB 10.6+ both support ADD CONSTRAINT IF NOT EXISTS.
ALTER TABLE sonar_bank_physical_cards
  ADD CONSTRAINT IF NOT EXISTS chk_sonar_bank_physical_cards_monthly_limit_nonneg
    CHECK (monthly_limit IS NULL OR monthly_limit >= 0),
  ADD CONSTRAINT IF NOT EXISTS chk_sonar_bank_physical_cards_monthly_used_nonneg
    CHECK (monthly_used >= 0);

COMMIT;
