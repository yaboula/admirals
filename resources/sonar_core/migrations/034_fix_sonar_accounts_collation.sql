-- ============================================================================
-- Migration: 034_fix_sonar_accounts_collation.sql
-- Author: Cascade (Bug fix R1.B)
-- Date: 2026-05-10
-- Description:
--   Fix collation mismatch between sonar_accounts.char_id (utf8mb4_uca1400_ai_ci)
--   and QBCore.players.citizenid (utf8mb4_unicode_ci).
--
-- Root cause:
--   MariaDB 10.6+ default collation is utf8mb4_uca1400_ai_ci, but QBCore
--   players table uses utf8mb4_unicode_ci. INNER JOIN fails silently with
--   "Illegal mix of collations (utf8mb4_uca1400_ai_ci,IMPLICIT) and
--   (utf8mb4_unicode_ci,IMPLICIT) for operation '='", returning empty set
--   and forcing UI to show starter_balance (2500) instead of real balance.
--
-- Fix:
--   ALTER sonar_accounts.char_id to utf8mb4_unicode_ci to match QBCore.
--   This is safe because char_id contains only ASCII citizen IDs.
--
-- Impact:
--   - Fixes balance mismatch issue
--   - Enables correct citizen account lookup
--   - No data loss (collation change only affects comparison, not storage)
-- ============================================================================

ALTER TABLE sonar_accounts
MODIFY COLUMN char_id VARCHAR(64) NOT NULL
COLLATE utf8mb4_unicode_ci
COMMENT 'citizenId framework (collation fixed to match QBCore utf8mb4_unicode_ci)';
