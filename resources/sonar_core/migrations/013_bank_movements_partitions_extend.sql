-- ============================================================================
-- Migration: 013_bank_movements_partitions_extend.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.1)
-- Description:
--   Extiende particiones RANGE de `sonar_bank_movements` desde Sep 2026
--   hasta Dec 2027 (Q-DB-G LOCKED 2026-05-06). Migration 003 dejó partitions
--   solo May-Aug 2026 + p_future MAXVALUE catchall — riesgo perf chaos test
--   200 concurrent reconciliation Sept 2026+ (Q16.5).
--
--   Aplica también extends idéntico a `sonar_bank_audit_ledger` (creada
--   migration 010 con partitions May-Dec 2026 + p_future) hasta Dec 2027.
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_movements particionada original).
--   - 010_bank_audit_ledger.sql (sonar_bank_audit_ledger particionada).
--
-- Reversible: parcial — REORGANIZE PARTITION es operación InnoDB cara
--   (rebuild interno). En dev OK, en prod requiere maintenance window.
--   Down equivalent: REORGANIZE PARTITION p_2026_09..p_2027_12, p_future
--   INTO (p_future MAXVALUE) — pierde granularidad pero data preservada.
--
-- SSoT references:
--   docs/technical/03_db_schema.md §17 (particionado strategy).
--   docs/agents/teams/slices/slice_database.md §7 OQ-DB-02 (RANGE month strategy).
--   docs/agents/teams/01_SHARED_BRIEF.md §3.16 Q16.5 (perf 200 concurrent <500ms p99).
--
-- DECISIONES TÉCNICAS (founder Q-DB-G LOCKED 2026-05-06):
--
--   D1. REORGANIZE PARTITION p_future INTO (32 partitions mensuales 2026-09 a
--       2027-12 + nuevo p_future MAXVALUE catchall). InnoDB rebuilds physical
--       data files — operation atómica por partition.
--
--   D2. Cron mensual rolling forward DevOps Lead post-H4 — cuando llegue
--       Nov 2027 se debe extender otra vez (cron añade siguientes 12 meses
--       proactivamente).
--
--   D3. Aplicado mismo extends a sonar_bank_audit_ledger (creada migration
--       010 con scope May-Dec 2026 + p_future) — extends Sep 2026 → Dec 2027
--       en la misma migration por coherencia operacional.
--
--   D4. Idempotency: pre-flight check via INFORMATION_SCHEMA.PARTITIONS —
--       si p_2026_09 ya existe (e.g. cron ya rolled forward antes de aplicar
--       esta migration), abort gracefully con NOTICE. NO usar IF NOT EXISTS
--       (REORGANIZE PARTITION no soporta sintaxis).
--
--   D5. Timestamps UTC pre-computados en comentarios — fuente de verdad para
--       cron rolling DevOps Lead (formato canonical first-of-month-UTC).
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Pre-flight check sonar_bank_movements — abort si p_2026_09 ya existe
--
-- MariaDB 12.x no tiene `IF NOT EXISTS` para REORGANIZE PARTITION. Usamos
-- pattern PROCEDURE temporal con SELECT INFORMATION_SCHEMA.PARTITIONS para
-- detectar idempotency y skip si ya aplicado.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_apply_013_bank_movements_extend;

DELIMITER $$

CREATE PROCEDURE sp_apply_013_bank_movements_extend()
BEGIN
  DECLARE p_count INT DEFAULT 0;

  SELECT COUNT(*) INTO p_count
  FROM INFORMATION_SCHEMA.PARTITIONS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_movements'
    AND PARTITION_NAME = 'p_2026_09';

  IF p_count = 0 THEN
    -- Aplicar extends — partitions Sep 2026 → Dec 2027 mensuales.
    ALTER TABLE sonar_bank_movements REORGANIZE PARTITION p_future INTO (
      PARTITION p_2026_09 VALUES LESS THAN (1759276800),  -- < Oct 1 2026 UTC
      PARTITION p_2026_10 VALUES LESS THAN (1761955200),  -- < Nov 1 2026 UTC
      PARTITION p_2026_11 VALUES LESS THAN (1764547200),  -- < Dec 1 2026 UTC
      PARTITION p_2026_12 VALUES LESS THAN (1767225600),  -- < Jan 1 2027 UTC
      PARTITION p_2027_01 VALUES LESS THAN (1769904000),  -- < Feb 1 2027 UTC
      PARTITION p_2027_02 VALUES LESS THAN (1772323200),  -- < Mar 1 2027 UTC
      PARTITION p_2027_03 VALUES LESS THAN (1774828800),  -- < Apr 1 2027 UTC
      PARTITION p_2027_04 VALUES LESS THAN (1777507200),  -- < May 1 2027 UTC
      PARTITION p_2027_05 VALUES LESS THAN (1780099200),  -- < Jun 1 2027 UTC
      PARTITION p_2027_06 VALUES LESS THAN (1782777600),  -- < Jul 1 2027 UTC
      PARTITION p_2027_07 VALUES LESS THAN (1785369600),  -- < Aug 1 2027 UTC
      PARTITION p_2027_08 VALUES LESS THAN (1788048000),  -- < Sep 1 2027 UTC
      PARTITION p_2027_09 VALUES LESS THAN (1790726400),  -- < Oct 1 2027 UTC
      PARTITION p_2027_10 VALUES LESS THAN (1793318400),  -- < Nov 1 2027 UTC
      PARTITION p_2027_11 VALUES LESS THAN (1795996800),  -- < Dec 1 2027 UTC
      PARTITION p_2027_12 VALUES LESS THAN (1798675200),  -- < Jan 1 2028 UTC
      PARTITION p_future  VALUES LESS THAN MAXVALUE
    );
  END IF;
END$$

DELIMITER ;

CALL sp_apply_013_bank_movements_extend();
DROP PROCEDURE sp_apply_013_bank_movements_extend;


-- ----------------------------------------------------------------------------
-- 2. Pre-flight check sonar_bank_audit_ledger — abort si p_2027_01 ya existe
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_apply_013_bank_audit_ledger_extend;

DELIMITER $$

CREATE PROCEDURE sp_apply_013_bank_audit_ledger_extend()
BEGIN
  DECLARE p_count INT DEFAULT 0;

  SELECT COUNT(*) INTO p_count
  FROM INFORMATION_SCHEMA.PARTITIONS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_audit_ledger'
    AND PARTITION_NAME = 'p_2027_01';

  IF p_count = 0 THEN
    -- Migration 010 dejó partitions May-Dec 2026 + p_future. Extends 2027 mensuales.
    ALTER TABLE sonar_bank_audit_ledger REORGANIZE PARTITION p_future INTO (
      PARTITION p_2027_01 VALUES LESS THAN (1769904000),  -- < Feb 1 2027 UTC
      PARTITION p_2027_02 VALUES LESS THAN (1772323200),  -- < Mar 1 2027 UTC
      PARTITION p_2027_03 VALUES LESS THAN (1774828800),  -- < Apr 1 2027 UTC
      PARTITION p_2027_04 VALUES LESS THAN (1777507200),  -- < May 1 2027 UTC
      PARTITION p_2027_05 VALUES LESS THAN (1780099200),  -- < Jun 1 2027 UTC
      PARTITION p_2027_06 VALUES LESS THAN (1782777600),  -- < Jul 1 2027 UTC
      PARTITION p_2027_07 VALUES LESS THAN (1785369600),  -- < Aug 1 2027 UTC
      PARTITION p_2027_08 VALUES LESS THAN (1788048000),  -- < Sep 1 2027 UTC
      PARTITION p_2027_09 VALUES LESS THAN (1790726400),  -- < Oct 1 2027 UTC
      PARTITION p_2027_10 VALUES LESS THAN (1793318400),  -- < Nov 1 2027 UTC
      PARTITION p_2027_11 VALUES LESS THAN (1795996800),  -- < Dec 1 2027 UTC
      PARTITION p_2027_12 VALUES LESS THAN (1798675200),  -- < Jan 1 2028 UTC
      PARTITION p_future  VALUES LESS THAN MAXVALUE
    );
  END IF;
END$$

DELIMITER ;

CALL sp_apply_013_bank_audit_ledger_extend();
DROP PROCEDURE sp_apply_013_bank_audit_ledger_extend;


-- ============================================================================
-- POST-INSTALL verification queries (manual run en HeidiSQL post-aplicación):
--
--   SELECT TABLE_NAME, PARTITION_NAME, PARTITION_DESCRIPTION
--   FROM INFORMATION_SCHEMA.PARTITIONS
--   WHERE TABLE_SCHEMA = DATABASE()
--     AND TABLE_NAME IN ('sonar_bank_movements', 'sonar_bank_audit_ledger')
--   ORDER BY TABLE_NAME, PARTITION_ORDINAL_POSITION;
--
-- Expected: 21 partitions sonar_bank_movements (5 May-Aug 2026 + 16 Sep 2026-
-- Dec 2027 + p_future) + 21 partitions sonar_bank_audit_ledger.
--
-- POST-INSTALL DevOps Lead actions required (post-H4):
--   1. Configurar cron mensual rolling forward (per docs/technical/03_db_schema.md §17.2).
--   2. Cuando partitions se acerquen a Dec 2027 (~Nov 2027), cron debe extender automáticamente.
--   3. Sin cron, riesgo perf degraded cuando p_future empiece a recibir data.
-- ============================================================================
