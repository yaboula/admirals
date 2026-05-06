-- ============================================================================
-- Migration: 010_bank_audit_ledger.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.1)
-- Description:
--   Crea tabla `sonar_bank_audit_ledger` — append-only inmutable + triggers
--   SIGNAL SQLSTATE '45000' BEFORE UPDATE/DELETE (3-tier defense-in-depth
--   tier 1 per Q-DB-F LOCKED 2026-05-06).
--
--   Particionamiento RANGE mensual para perf chaos test 200 concurrent <500ms
--   p99 (Q16.5) + audit retention legal indefinida (cold archival post 12
--   meses gestionado por DevOps Lead post-H4 cron).
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_accounts existe — FK target opcional).
--   - 002_foundation_tables.sql (sonar_accounts existe — FK actor_account_id).
--
-- Reversible: sí en dev (DROP TRIGGER + DROP TABLE). NO post-prod (audit
--   inmutable legal regulatorio).
--
-- SSoT references:
--   docs/technical/03_db_schema.md §22 (NEW v1.2 DRAFT v0.1).
--   docs/agents/teams/prompts/01_database_integrity_lead.md §4.5 (immutability strategy).
--   docs/agents/teams/slices/slice_database.md §3 OQ-DB-03 (defense-in-depth).
--   docs/agents/teams/01_SHARED_BRIEF.md §6.2 (anti-tech-debt — audit ledger immutability).
--
-- DECISIONES TÉCNICAS (founder Q-DB-F + Q-DB-A LOCKED 2026-05-06):
--
--   D1. Tier 1 tier defense-in-depth: triggers SIGNAL BEFORE UPDATE/DELETE.
--       MariaDB 12.x soporta SIGNAL SQLSTATE estándar SQL.
--
--   D2. Tier 2 (REVOKE UPDATE/DELETE en role `sonar_bank_app_user`) NO se
--       implementa en migration — DevOps Lead config DB role post-H4. Este
--       file documenta requirement en comentario header.
--
--   D3. Tier 3 (app-level enforcer) Backend Lead implementa post-H1 — todo
--       INSERT pasa por `BankAuditLedger.Append(payload)` lib que rechaza
--       UPDATE/DELETE attempts at API level.
--
--   D4. Particionamiento RANGE mensual `ts` — pruning automático queries
--       Government Console scope "Todas" + audit retention. Cron rolling
--       forward DevOps Lead post-H4 (per docs/technical/03_db_schema.md §17.2).
--
--   D5. SysVer (system-versioned tables MariaDB 10.6+) DESCARTADO Q-DB-F —
--       semántica wrong para append-only puro (SysVer permite UPDATE +
--       archiva versión, no rechaza).
--
--   D6. JSON column `context_data` para metadata flexible (citizen_id deltas,
--       transaction refs, FSM transitions context). NO normalizar — los
--       campos varían per event_type. Queries indexed via virtual generated
--       columns si surge necesidad (deferred v0.2+).
--
--   D7. CHECK constraint `amount_delta` NULL or numeric — MariaDB 12.x
--       soporta CHECK simples. Multi-col IS NULL workaround app-layer.
--
--   D8. NO FK a `sonar_bank_accounts.id` — bank_account_iban almacenado
--       como VARCHAR(20) snapshot (cuenta puede cerrarse + audit debe
--       sobrevivir). actor_account_id sí FK ON DELETE SET NULL (auditor
--       legal trail).
--
--   D9. Idempotent DDL — `CREATE TABLE IF NOT EXISTS` + `DROP TRIGGER IF
--       EXISTS` patterns. Re-apply safe.
--
--   D10. Charset `utf8mb4_unicode_ci` — MariaDB-compat consistent migrations
--        003+006 (NO `utf8mb4_0900_ai_ci` MySQL-only).
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. sonar_bank_audit_ledger — append-only immutable PARTITIONED RANGE month
--
-- Cada operación Bank-domain genera 1+ rows audit:
--   - Money flow (transfers, deposits, withdrawals, escrow lock/release).
--   - State changes (account freeze/unfreeze, FSM transitions).
--   - Admin actions (overdraft authorization, manual reconciliation).
--   - Compliance events (autoraise patterns, threshold breaches).
--   - Government actions (tax brackets edit, subsidies issued, election lifecycle).
--   - Audit reads scope "Todas" (transparency — quién consultó qué).
--
-- ENUM event_type canonical Phase A (Security Lead extends post-H2):
--   transfer_init, transfer_complete, transfer_rollback,
--   account_create, account_close, account_freeze, account_unfreeze,
--   reconciliation_apply, reconciliation_admin_flag,
--   compliance_raise, compliance_resolve,
--   tax_payment, subsidy_issue, tax_brackets_edit,
--   election_open, election_close, vote_cast,
--   loan_apply, loan_approve, loan_disburse, loan_repay,
--   stock_buy, stock_sell, crypto_buy, crypto_sell,
--   escrow_create, escrow_lock, escrow_release_partial, escrow_release_full,
--   escrow_refund, escrow_dispute,
--   admin_action, audit_read_scope_full.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_audit_ledger (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ts                    INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) COMMENT 'partition key — UNIX seconds UTC',

  event_type            VARCHAR(64)     NOT NULL COMMENT 'canonical event taxonomy — Security Lead C-SEC-01 extends',
  severity              ENUM('info','notice','warning','critical') NOT NULL DEFAULT 'info',

  bank_account_iban     VARCHAR(20)     NULL COMMENT 'snapshot IBAN (cuenta puede cerrarse — audit sobrevive)',
  counterpart_iban      VARCHAR(20)     NULL,

  actor_account_id      CHAR(36)        NULL COMMENT 'citizen autor acción — FK SET NULL si account borrado',
  actor_role            ENUM('citizen','company','government','admin','system','watchdog') NOT NULL DEFAULT 'system',

  amount_delta          DECIMAL(14,2)   NULL COMMENT 'delta dinero si aplica (NULL si event no monetary)',
  balance_after         DECIMAL(14,2)   NULL COMMENT 'snapshot balance post-event si aplica',

  correlation_id        CHAR(36)        NULL COMMENT 'correlation-id Backend mutex CP2 — link audit chain',
  request_nonce         CHAR(36)        NULL COMMENT 'idempotency anti-replay link',

  related_movement_id   BIGINT UNSIGNED NULL COMMENT 'link sonar_bank_movements.id si event movement-bound',
  related_escrow_id     CHAR(36)        NULL COMMENT 'link sonar_escrows.id si event escrow-bound',
  related_loan_id       CHAR(36)        NULL COMMENT 'link sonar_bank_loans.id si event loan-bound',
  related_compliance_flag_id BIGINT UNSIGNED NULL COMMENT 'link sonar_bank_compliance_flags.id si autoraise',

  context_data          JSON            NULL COMMENT 'metadata flexible per event_type — schema docs/technical/08_audit_hooks.md (Security Lead)',

  source_resource       VARCHAR(64)     NOT NULL DEFAULT 'sonar_bank' COMMENT 'sonar_bank, sonar_bank_app, sonar_bridges, sonar_core',
  server_id             VARCHAR(32)     NULL COMMENT 'multi-server fleet ID si aplica (defer Phase D)',

  PRIMARY KEY (id, ts),

  KEY idx_sonar_bank_audit_ledger_iban_ts (bank_account_iban, ts DESC),
  KEY idx_sonar_bank_audit_ledger_actor_ts (actor_account_id, ts DESC),
  KEY idx_sonar_bank_audit_ledger_event_ts (event_type, ts DESC),
  KEY idx_sonar_bank_audit_ledger_severity_ts (severity, ts DESC),
  KEY idx_sonar_bank_audit_ledger_correlation (correlation_id),
  KEY idx_sonar_bank_audit_ledger_movement (related_movement_id),
  KEY idx_sonar_bank_audit_ledger_escrow (related_escrow_id),
  KEY idx_sonar_bank_audit_ledger_loan (related_loan_id),
  KEY idx_sonar_bank_audit_ledger_flag (related_compliance_flag_id),

  CONSTRAINT chk_sonar_bank_audit_ledger_amount_delta_sane
    CHECK (amount_delta IS NULL OR (amount_delta >= -99999999999999.99 AND amount_delta <= 99999999999999.99))

  -- Index rationale:
  --   idx_..._iban_ts: query "audit por cuenta últimos N días" (Audit Explorer Mis cuentas).
  --   idx_..._actor_ts: query "audit por citizen autor" (compliance investigations).
  --   idx_..._event_ts: query "audit por event_type" (Government Console filter).
  --   idx_..._severity_ts: query "audit critical/warning recientes" (Security dashboard).
  --   idx_..._correlation: link audit chain por correlation-id (Backend mutex CP2).
  --   idx_..._movement / _escrow / _loan / _flag: lookup audit por entity-bound.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  PARTITION BY RANGE (ts) (
    -- Initial partitions cubren BANK-DB.1 → end-of-year 2026.
    -- Cron mensual rolling forward (DevOps Lead post-H4) extiende 2027+.
    PARTITION p_2026_05 VALUES LESS THAN (1748736000),  -- < Jun 1 2026 UTC
    PARTITION p_2026_06 VALUES LESS THAN (1751328000),  -- < Jul 1 2026 UTC
    PARTITION p_2026_07 VALUES LESS THAN (1754006400),  -- < Aug 1 2026 UTC
    PARTITION p_2026_08 VALUES LESS THAN (1756684800),  -- < Sep 1 2026 UTC
    PARTITION p_2026_09 VALUES LESS THAN (1759276800),  -- < Oct 1 2026 UTC
    PARTITION p_2026_10 VALUES LESS THAN (1761955200),  -- < Nov 1 2026 UTC
    PARTITION p_2026_11 VALUES LESS THAN (1764547200),  -- < Dec 1 2026 UTC
    PARTITION p_2026_12 VALUES LESS THAN (1767225600),  -- < Jan 1 2027 UTC
    PARTITION p_future  VALUES LESS THAN MAXVALUE       -- catch-all hasta cron rolling forward
  );


-- ----------------------------------------------------------------------------
-- 2. Triggers SIGNAL SQLSTATE '45000' BEFORE UPDATE/DELETE (Q-DB-F tier 1)
--
-- Defense-in-depth tier 1: any UPDATE/DELETE attempt rejected at DB level
-- with SQLSTATE 45000 + descriptive message. App receives error → fails fast.
--
-- Tier 2 (REVOKE privilege en role `sonar_bank_app_user`): DevOps Lead
-- post-H4 — DB role config (NOT in this migration).
--
-- Tier 3 (app-level enforcer): Backend Lead post-H1 — `BankAuditLedger.Append`
-- lib only exposes INSERT, no Update/Delete API.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_sonar_bank_audit_ledger_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_audit_ledger_no_delete;

DELIMITER $$

CREATE TRIGGER trg_sonar_bank_audit_ledger_no_update
  BEFORE UPDATE ON sonar_bank_audit_ledger
  FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'sonar_bank_audit_ledger is append-only — UPDATE rejected';
END$$

CREATE TRIGGER trg_sonar_bank_audit_ledger_no_delete
  BEFORE DELETE ON sonar_bank_audit_ledger
  FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'sonar_bank_audit_ledger is append-only — DELETE rejected';
END$$

DELIMITER ;


-- ============================================================================
-- FIN migration 010_bank_audit_ledger.sql
--
-- POST-INSTALL DevOps Lead actions required (post-H4):
--   1. REVOKE UPDATE, DELETE ON sonar_bank_audit_ledger FROM 'sonar_bank_app_user';
--   2. Configure cron mensual partition rolling forward (per §17.2 SSoT).
--   3. Configure cold archival cron post 12 meses (per §17.3 retention legal).
-- ============================================================================
