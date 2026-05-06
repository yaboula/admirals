-- ============================================================================
-- Migration: 012_bank_status_fsm.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.1)
-- Description:
--   Crea tabla `sonar_bank_status` — single-row global per-server FSM
--   tracking estado del Bridge runtime (CP8 LOCKED 2026-05-06 + Q-DB-J).
--
--   FSM 4 states canonical:
--     - 'native_full'           — Q16 Layer 1 happy path (QBox/QBCore native + bridges full).
--     - 'lite_mode_active'      — Q16 Layer 2 fallback (ESX 1.10+ Lite mode).
--     - 'compromised_load_order' — CP4 watchdog detected load order issue.
--     - 'framework_missing'     — defensive boot CP4 — no framework detected.
--
-- Dependencies:
--   - 002_foundation_tables.sql (base — sin FK direct).
--
-- Reversible: sí en dev (DROP TABLE). NO post-prod (estado runtime + UI badge
--   sonar_bank_status footer always-visible per Q16.3 — siempre debe leer
--   estado).
--
-- SSoT references:
--   docs/technical/03_db_schema.md §23 (NEW v1.2 DRAFT v0.1).
--   docs/agents/teams/01_SHARED_BRIEF.md §4.3 (CP8 sonar_bank_status FSM).
--   docs/agents/teams/01_SHARED_BRIEF.md §3.16 Q16 (hybrid 3-layer + 8 CP).
--   docs/agents/teams/slices/slice_database.md §3.6 + OQ-DB-05 (per-server vs per-citizen).
--   docs/agents/teams/slices/slice_frontend.md §3 CP8 (UI badge footer always-visible).
--
-- DECISIONES TÉCNICAS (founder Q-DB-J + Q-DB-A LOCKED 2026-05-06):
--
--   D1. Single row global per-server PK fijo `id=1` (Q-DB-J LOCKED).
--       Coherencia operacional — el estado del Bridge runtime es del server
--       process, NO del citizen.
--
--   D2. Trigger BEFORE INSERT enforce `id=1` solamente (defense-in-depth —
--       app-layer Backend Lead post-H1 también garantiza single row).
--
--   D3. Initial seed row state='framework_missing' insertado por migration —
--       primer boot pasará a 'native_full' o 'lite_mode_active' según
--       defensive boot detection (CP4).
--
--   D4. Columna `last_transition_reason VARCHAR(255)` documenta razón de
--       último state change para debugging operacional + UI badge tooltip.
--
--   D5. Columna `bridge_version VARCHAR(32)` para correlacionar status con
--       versión bridges deployed (DevOps Lead).
--
--   D6. Columna `framework_detected ENUM('qbox','qbcore','esx_modern','esx_legacy','none')`
--       — esx_legacy presente para detección + boot fail explícito (Q-DB-A
--       cut ESX legacy spec — boot rechaza con error claro).
--
--   D7. updated_at app-managed (MariaDB-illegal ON UPDATE INT UNSIGNED).
--       Backend Lead post-H1 garantiza UPDATE setea updated_at via lib
--       `BankStatus.Transition(new_state, reason)`.
--
--   D8. CHECK simples — single-row constraint via PK fijo + trigger.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. sonar_bank_status — single row global per-server FSM (CP8)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_status (
  id                       TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'PK fijo — single row global per-server',

  state                    ENUM(
                             'native_full',
                             'lite_mode_active',
                             'compromised_load_order',
                             'framework_missing'
                           ) NOT NULL DEFAULT 'framework_missing',

  framework_detected       ENUM('qbox','qbcore','esx_modern','esx_legacy','none') NOT NULL DEFAULT 'none',

  bridge_version           VARCHAR(32)     NULL COMMENT 'sonar_bridges semver — correlación versión deployed',

  last_transition_reason   VARCHAR(255)    NULL COMMENT 'razón legible último state change',
  last_transition_actor    ENUM('system','watchdog','admin') NOT NULL DEFAULT 'system',

  experimental_handlers_ok TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 si sv_experimentalStateBagsHandler + sv_experimentalNetGameEventHandler + sv_enableNetEventReassembly detectados (Q16.4 + CP7)',

  created_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  -- transition_at: snapshot UNIX seconds último state change.
  transitioned_at          INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),

  CONSTRAINT chk_sonar_bank_status_single_row
    CHECK (id = 1)

  -- No FKs — tabla self-contained per-server runtime.
  --
  -- Index rationale: PK fijo `id=1` — single row reads ≪ 1ms.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 2. Trigger BEFORE INSERT enforce single-row (defense-in-depth)
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_sonar_bank_status_single_row;

DELIMITER $$

CREATE TRIGGER trg_sonar_bank_status_single_row
  BEFORE INSERT ON sonar_bank_status
  FOR EACH ROW
BEGIN
  IF NEW.id <> 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'sonar_bank_status is single-row global per-server (id must be 1)';
  END IF;
END$$

DELIMITER ;


-- ----------------------------------------------------------------------------
-- 3. Initial seed row — state 'framework_missing' baseline
--
-- Primer boot defensive (CP4) Backend Lead post-H1 detecta framework + UPDATE:
--   UPDATE sonar_bank_status SET
--     state = 'native_full' | 'lite_mode_active',
--     framework_detected = 'qbox' | 'qbcore' | 'esx_modern',
--     bridge_version = '<semver>',
--     last_transition_reason = 'boot detection complete',
--     last_transition_actor = 'system',
--     experimental_handlers_ok = 0|1,
--     updated_at = UNIX_TIMESTAMP(),
--     transitioned_at = UNIX_TIMESTAMP()
--   WHERE id = 1;
-- ----------------------------------------------------------------------------
INSERT INTO sonar_bank_status (
  id, state, framework_detected, bridge_version,
  last_transition_reason, last_transition_actor,
  experimental_handlers_ok
)
VALUES (
  1, 'framework_missing', 'none', NULL,
  'initial seed migration 012 — awaiting defensive boot CP4 detection',
  'system',
  0
)
ON DUPLICATE KEY UPDATE id = id;  -- no-op si ya existe (re-apply safe).


-- ============================================================================
-- FIN migration 012_bank_status_fsm.sql
-- ============================================================================
