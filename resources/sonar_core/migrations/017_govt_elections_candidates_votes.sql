-- ============================================================================
-- Migration: 017_govt_elections_candidates_votes.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.2)
-- Description:
--   Crea 4 tablas Government-domain Phase A (elections + dual-layer privacy
--   per Q-DB-H LOCKED 2026-05-06):
--     - sonar_govt_elections           — elecciones FSM 4-state.
--     - sonar_govt_election_candidates — candidatos por elección.
--     - sonar_govt_votes               — votos públicos hasheados (privacy).
--     - sonar_govt_votes_audit         — votos raw admin-only ACE-gated.
--
-- Dependencies:
--   - 002_foundation_tables.sql (sonar_accounts existe).
--   - 010_bank_audit_ledger.sql (event types election_open + election_close +
--                                 vote_cast).
--
-- Reversible: sí dev. NO post-prod (election_history audit retention legal +
--   votes_audit ACE-gated).
--
-- SSoT references:
--   docs/technical/03_db_schema.md §24 (NEW v1.4 DRAFT v0.2).
--   docs/technical/03_db_schema.md §29 Deviation Q-DB-H (dual-layer privacy).
--   docs/agents/teams/01_SHARED_BRIEF.md §3.10 Q10 (gov flows).
--
-- DECISIONES TÉCNICAS (founder Q-DB-H + Q-DB-A LOCKED 2026-05-06):
--
--   D1. sonar_govt_elections — FSM 4 states canonical:
--         'draft'    — admin gov drafting, NO visible públicamente.
--         'open'     — period activo voting (citizens pueden cast vote).
--         'closed'   — voting cerrado, count ongoing.
--         'finalized' — results publicados + winner declared.
--
--       Transitions: draft → open → closed → finalized. Reverse NO permitido
--       (audit integrity). Backend Lead post-H1 enforce app-layer.
--
--   D2. election_kind ENUM:
--         'mayor' (alcalde gobierno servidor),
--         'cooperative_board' (junta cooperativa),
--         'referendum' (sí/no proposiciones gov).
--
--   D3. **DUAL-LAYER PRIVACY (Q-DB-H)** — diseño crítico:
--
--       sonar_govt_votes (PÚBLICO) — readable por cualquier citizen via
--       Government Console UI, sin ACE check. Almacena solo:
--         - voter_hash CHAR(64) — SHA-256(citizen_id || election_id || server_salt).
--         - candidate_id (voto al candidato X).
--         - cast_at timestamp.
--
--       Properties:
--         ▸ Misma persona votando 2 veces en misma elección genera mismo hash
--           → UNIQUE constraint detecta + rechaza.
--         ▸ NO se puede inferir citizen_id desde voter_hash (server_salt secreto).
--         ▸ Counts públicos por candidato accesibles (transparencia electoral).
--
--       sonar_govt_votes_audit (ADMIN-ONLY) — ACE gated `sonar.bank.govt.audit.full`
--       (Backend Lead post-H1 + Security Lead post-H2 enforce). Almacena raw:
--         - citizen_id CHAR(36) — voter real.
--         - election_id + candidate_id.
--         - cast_at + ip_address + actor_role.
--
--       Use cases:
--         ▸ Investigación impugnación electoral.
--         ▸ Detección fraude (votos múltiples desde mismo IP, etc.).
--         ▸ Auditoría legal solo por Government con ACE.
--
--       INSERT atómico: Backend Lead post-H1 lib `Vote.Cast()` inserta en
--       AMBAS tablas en single transaction. Si fail → rollback ambas.
--
--   D4. server_salt — secreto generado por DevOps Lead via convar
--       `sonar_bank_govt_vote_salt` (cadena random 64 chars). NO almacenar
--       en DB. Sin server_salt, attacker con dump DB no puede reverse-engineer
--       hash→citizen_id.
--
--       NOTA crítica: server_salt MUST be stable across server restarts
--       (sino votos pre-restart no matchearían). DevOps Lead post-H4 documenta
--       almacenamiento secret en server.cfg.example + warning rotation.
--
--   D5. UNIQUE constraint en sonar_govt_votes (voter_hash, election_id) —
--       enforces "1 person 1 vote per election" sin exposure citizen_id.
--
--   D6. Triggers SIGNAL append-only sonar_govt_votes + sonar_govt_votes_audit
--       (Q-DB-F tier 1 pattern). Votos NO modificables post-cast.
--
--   D7. FK sonar_govt_election_candidates.election_id → sonar_govt_elections(id)
--       ON DELETE CASCADE — borrar elección draft borra candidatos. Post-FSM
--       'open' app-layer rechaza DELETE elections.
--
--   D8. CHECK constraints simples (Q-DB-A — multi-col app-layer):
--         - sonar_govt_elections.opens_at < closes_at
--         - sonar_govt_election_candidates.display_order >= 0
--
--   D9. Index strategy:
--         votes (voter_hash, election_id) UNIQUE — enforce 1-vote rule.
--         votes (election_id, candidate_id) — count results queries.
--         votes_audit (citizen_id, election_id) — admin investigation.
--         votes_audit (election_id, cast_at DESC) — chronological audit.
-- ============================================================================


START TRANSACTION;


-- ----------------------------------------------------------------------------
-- 1. sonar_govt_elections — elecciones FSM 4-state
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_govt_elections (
  id                    CHAR(36)        NOT NULL COMMENT 'UUID v4 application-generated',

  election_kind         ENUM('mayor','cooperative_board','referendum') NOT NULL,
  title                 VARCHAR(192)    NOT NULL,
  description           TEXT            NULL,

  state                 ENUM('draft','open','closed','finalized') NOT NULL DEFAULT 'draft',

  scope_company_id      CHAR(36)        NULL COMMENT 'cooperative_board scope — FK Q-DB-E DEFERRED',

  opens_at              INT UNSIGNED    NULL COMMENT 'NULL hasta state=open',
  closes_at             INT UNSIGNED    NULL COMMENT 'NULL hasta state=open',
  finalized_at          INT UNSIGNED    NULL,

  winner_candidate_id   CHAR(36)        NULL COMMENT 'set en transition to finalized',
  total_votes_count     INT UNSIGNED    NOT NULL DEFAULT 0,

  created_by_account_id CHAR(36)        NULL COMMENT 'admin gov autor draft',
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_govt_elections_state_kind (state, election_kind),
  KEY idx_sonar_govt_elections_scope_company (scope_company_id),
  KEY idx_sonar_govt_elections_opens (opens_at),
  KEY idx_sonar_govt_elections_closes (closes_at),

  CONSTRAINT fk_sonar_govt_elections_created_by
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_govt_elections_window
    CHECK (opens_at IS NULL OR closes_at IS NULL OR opens_at < closes_at)

  -- NO FK scope_company_id → sonar_companies(id) — Q-DB-E DEFERRED issue #001.
  -- NO FK winner_candidate_id (self-ref deferred — set post-finalization).
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 2. sonar_govt_election_candidates — candidatos por elección
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_govt_election_candidates (
  id                    CHAR(36)        NOT NULL COMMENT 'UUID v4',
  election_id           CHAR(36)        NOT NULL,

  candidate_account_id  CHAR(36)        NULL COMMENT 'citizen candidato (NULL si referendum yes/no)',
  display_label         VARCHAR(128)    NOT NULL COMMENT 'p.e. "Yes" / "No" (referendum) o nombre candidato',
  manifesto             TEXT            NULL,

  display_order         INT UNSIGNED    NOT NULL DEFAULT 0,

  votes_count           INT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'cached count — refresh on-finalize por Backend Lead',

  registered_at         INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_govt_election_candidates_election_account (election_id, candidate_account_id),
  KEY idx_sonar_govt_election_candidates_election_order (election_id, display_order),

  CONSTRAINT fk_sonar_govt_election_candidates_election
    FOREIGN KEY (election_id) REFERENCES sonar_govt_elections(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_govt_election_candidates_account
    FOREIGN KEY (candidate_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_govt_election_candidates_order_nonneg CHECK (display_order >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 3. sonar_govt_votes — votos PÚBLICOS hasheados (privacy layer)
--
-- Lectura pública (Government Console UI). Inserción dual-atomic con
-- sonar_govt_votes_audit por Backend Lead lib `Vote.Cast()`.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_govt_votes (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  election_id           CHAR(36)        NOT NULL,
  candidate_id          CHAR(36)        NOT NULL,

  voter_hash            CHAR(64)        NOT NULL COMMENT 'SHA-256(citizen_id || election_id || server_salt)',

  cast_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_govt_votes_voter_election (voter_hash, election_id),
  KEY idx_sonar_govt_votes_election_candidate (election_id, candidate_id),
  KEY idx_sonar_govt_votes_election_cast (election_id, cast_at DESC),

  CONSTRAINT fk_sonar_govt_votes_election
    FOREIGN KEY (election_id) REFERENCES sonar_govt_elections(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_govt_votes_candidate
    FOREIGN KEY (candidate_id) REFERENCES sonar_govt_election_candidates(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Triggers SIGNAL append-only.
DROP TRIGGER IF EXISTS trg_sonar_govt_votes_no_update;
DROP TRIGGER IF EXISTS trg_sonar_govt_votes_no_delete;

DELIMITER $$

CREATE TRIGGER trg_sonar_govt_votes_no_update
  BEFORE UPDATE ON sonar_govt_votes FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes is append-only — UPDATE rejected';
END$$

CREATE TRIGGER trg_sonar_govt_votes_no_delete
  BEFORE DELETE ON sonar_govt_votes FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes is append-only — DELETE rejected';
END$$

DELIMITER ;


-- ----------------------------------------------------------------------------
-- 4. sonar_govt_votes_audit — votos RAW admin-only (ACE-gated)
--
-- Acceso ACE `sonar.bank.govt.audit.full` enforced por Backend Lead post-H1
-- + Security Lead post-H2. Tabla NO leíble por citizen normal.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_govt_votes_audit (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  election_id           CHAR(36)        NOT NULL,
  candidate_id          CHAR(36)        NOT NULL,

  citizen_id            CHAR(36)        NOT NULL COMMENT 'voter REAL — admin-only access',

  cast_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  ip_address            VARCHAR(45)     NULL COMMENT 'fraud detection — IPv4 or IPv6',
  actor_role            ENUM('citizen','admin','system') NOT NULL DEFAULT 'citizen',

  -- Link al row gemelo en sonar_govt_votes (mismo voter, mismo cast).
  related_public_vote_id BIGINT UNSIGNED NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_govt_votes_audit_citizen_election (citizen_id, election_id),
  KEY idx_sonar_govt_votes_audit_election_cast (election_id, cast_at DESC),
  KEY idx_sonar_govt_votes_audit_election_candidate (election_id, candidate_id),
  KEY idx_sonar_govt_votes_audit_ip (ip_address, cast_at DESC),
  KEY idx_sonar_govt_votes_audit_related (related_public_vote_id),

  CONSTRAINT fk_sonar_govt_votes_audit_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_govt_votes_audit_election
    FOREIGN KEY (election_id) REFERENCES sonar_govt_elections(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_govt_votes_audit_candidate
    FOREIGN KEY (candidate_id) REFERENCES sonar_govt_election_candidates(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_govt_votes_audit_public_vote
    FOREIGN KEY (related_public_vote_id) REFERENCES sonar_govt_votes(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Triggers SIGNAL append-only audit.
DROP TRIGGER IF EXISTS trg_sonar_govt_votes_audit_no_update;
DROP TRIGGER IF EXISTS trg_sonar_govt_votes_audit_no_delete;

DELIMITER $$

CREATE TRIGGER trg_sonar_govt_votes_audit_no_update
  BEFORE UPDATE ON sonar_govt_votes_audit FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes_audit is append-only — UPDATE rejected';
END$$

CREATE TRIGGER trg_sonar_govt_votes_audit_no_delete
  BEFORE DELETE ON sonar_govt_votes_audit FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes_audit is append-only — DELETE rejected';
END$$

DELIMITER ;


COMMIT;


-- ============================================================================
-- POST-INSTALL critical actions:
--
-- BACKEND LEAD post-H1:
--   1. Implement Vote.Cast(election_id, candidate_id, citizen_id) library:
--      - Compute voter_hash = SHA256(citizen_id || election_id || server_salt).
--      - Single transaction: INSERT sonar_govt_votes + INSERT sonar_govt_votes_audit.
--      - On UNIQUE constraint violation → return error "already_voted".
--      - Append audit_ledger event 'vote_cast'.
--   2. Enforce ACE check `sonar.bank.govt.audit.full` on ANY query/read of
--      sonar_govt_votes_audit. NO citizen normal query path.
--
-- SECURITY LEAD post-H2:
--   1. Audit policy: queries sobre votes_audit deben generar audit_ledger entry
--      'audit_read_scope_full' con citizen_id consultado (meta-audit).
--   2. Test: simular dump DB sin server_salt → verify hash NO reversible.
--
-- DEVOPS LEAD post-H4:
--   1. Generar server_salt 64-char random + persistir en server.cfg.example
--      con `setr sonar_bank_govt_vote_salt "<64-char-random>"`.
--   2. Documentar warning: NO rotar salt sin migration data — invalidaría
--      todos hashes existentes. Si rotation requerida, migration aditiva
--      con dual-hash window.
-- ============================================================================
