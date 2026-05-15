-- SONAR Bank Deployment Kit install.sql
-- Generated from resources/sonar_core/migrations
-- Do not edit manually; update source migrations instead.


-- ============================================================================
-- BEGIN 001_schema_versions.sql
-- ============================================================================
-- ============================================================================
-- Migration: 001_schema_versions.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02
-- Description:
--   Crea sonar_schema_versions â€” registry de migraciones aplicadas
--   + checksum SHA-256 para detectar tampering.
--
-- Dependencies: none (BOOTSTRAP table â€” la runner la usa para tracking).
-- Reversible: yes (DROP TABLE â€” pero NO se ejecuta post-prod).
--
-- SSoT: docs/technical/03_db_schema.md Â§12.2.
-- ============================================================================

CREATE TABLE IF NOT EXISTS sonar_schema_versions (
  version     INT UNSIGNED  NOT NULL COMMENT 'numÃ©rico secuencial (parseado del filename NNN_*.sql)',
  filename    VARCHAR(192)  NOT NULL COMMENT 'NNN_description.sql',
  applied_at  INT UNSIGNED  NOT NULL DEFAULT (UNIX_TIMESTAMP()) COMMENT 'unix ts aplicaciÃ³n',
  applied_by  VARCHAR(64)   NULL     COMMENT 'usuario o sistema que aplicÃ³',
  checksum    VARCHAR(64)   NOT NULL COMMENT 'SHA-256 (hex) del body del migration file',
  duration_ms INT UNSIGNED  NOT NULL DEFAULT 0 COMMENT 'cuÃ¡nto tardÃ³ el apply',
  notes       TEXT          NULL,

  PRIMARY KEY (version),
  UNIQUE KEY uq_sonar_schema_versions_filename (filename)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- END 001_schema_versions.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 002_foundation_tables.sql
-- ============================================================================
-- ============================================================================
-- Migration: 002_foundation_tables.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02
-- Description:
--   Crea las 3 tablas foundation SONAR per ADR-010 (opciÃ³n C hÃ­brido):
--     1. sonar_accounts            (minimal subset â€” SSoT Â§3.1 trimmed)
--     2. sonar_audit_log           (new operational audit â€” ADR-010)
--     3. sonar_bridge_idempotency  (DB-backed replacement de S0.2 in-memory)
--
-- Dependencies: 001_schema_versions (runner tracking).
-- Reversible: sÃ­ en dev (DROP TABLE). NO ejecutar rollback post-prod.
--
-- SSoT:
--   docs/technical/03_db_schema.md Â§3.1 (sonar_accounts canonical full).
--   docs/technical/04_api_contracts.md Â§6.4 (audit_log wrapper usage).
--   docs/planning/02_decision_log.md ADR-010 (hybrid audit_log + event_log).
--
-- NOTAS:
--   - sonar_accounts aquÃ­ es un SUBSET minimal (7 columnas core). Las
--     columnas restantes (reputation_global, preferred_locale, developer_mode,
--     meta, last_login_at) se aÃ±adirÃ¡n via ALTER TABLE aditivos en S1+.
--   - sonar_audit_log es wrapper operacional para financial/ownership/admin;
--     sonar_event_log (partitioned, cross-bus) se crea S1+ cuando EventBus
--     tenga BusAuditMode=always en prod.
--   - sonar_bridge_idempotency sustituirÃ¡ al in-memory _idem_store del
--     dispatcher vÃ­a migration path en S1 (dispatcher lee/escribe aquÃ­ si
--     Config.IdempotencyBackend='db').
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. sonar_accounts (minimal â€” 7 cols core).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_accounts (
  id                CHAR(36)      NOT NULL COMMENT 'UUID v4',
  char_id           VARCHAR(64)   NOT NULL COMMENT 'citizenId framework',
  framework_source  VARCHAR(32)   NOT NULL COMMENT 'qbox|qbcore|esx|native',
  alias             VARCHAR(64)   NOT NULL COMMENT 'nombre mostrado SONAR',
  created_at        INT UNSIGNED  NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  -- updated_at: app-managed (SONAR.DB.Execute sets on UPDATE).
  -- ON UPDATE (UNIX_TIMESTAMP()) is MariaDB-illegal for non-TIMESTAMP columns.
  updated_at        INT UNSIGNED  NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  last_login_at     INT UNSIGNED  NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_accounts_char_framework (char_id, framework_source),
  KEY idx_sonar_accounts_char_id (char_id),
  KEY idx_sonar_accounts_framework (framework_source)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 2. sonar_audit_log â€” operational wrapper audit.
--
-- Distinto de sonar_event_log (que se crea S1+, particionado mensual):
--   - audit_log: operational (financial ops, ownership changes, admin acts).
--     Append-only. Query pattern: "quiÃ©n hizo X y cuÃ¡ndo" para una entidad.
--   - event_log: bus persistence (cuando BusAuditMode=always). Structured
--     event tracing cross-subsystem. Particionado mensual.
--
-- Ambos coexisten per ADR-010.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_audit_log (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ts                INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) COMMENT 'unix sec',

  category          VARCHAR(64)     NOT NULL COMMENT 'bank_transfer, ownership_change, admin_action, ...',
  action            VARCHAR(96)     NOT NULL COMMENT 'debit, credit, spawn, hire, fire, ...',

  actor_account_id  CHAR(36)        NULL COMMENT 'quiÃ©n ejecutÃ³ la acciÃ³n (NULL si sistema)',
  actor_source      INT UNSIGNED    NULL COMMENT 'FiveM source id al momento (debug)',

  target_type       VARCHAR(32)     NULL COMMENT 'account, company, bank_account, item, ...',
  target_id         VARCHAR(64)     NULL COMMENT 'id de la entidad afectada',

  amount            DECIMAL(12,2)   NULL COMMENT 'si operaciÃ³n financiera',
  currency          VARCHAR(8)      NULL COMMENT 'EUR default',

  request_id        VARCHAR(64)     NULL COMMENT 'idempotency key asociada',
  resource          VARCHAR(64)     NOT NULL COMMENT 'resource que emitiÃ³ (sonar_core, sonar_bank, ...)',
  metadata          JSON            NULL COMMENT 'payload adicional (concept, reason, etc.)',

  ip_address        VARCHAR(45)     NULL COMMENT 'IPv4/IPv6 del actor al momento',

  PRIMARY KEY (id),
  KEY idx_sonar_audit_log_ts (ts DESC),
  KEY idx_sonar_audit_log_actor (actor_account_id, ts DESC),
  KEY idx_sonar_audit_log_target (target_type, target_id, ts DESC),
  KEY idx_sonar_audit_log_category (category, ts DESC),
  KEY idx_sonar_audit_log_request (request_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 3. sonar_bridge_idempotency â€” DB-backed replacement para S0.2 in-memory.
--
-- Sobrevive reboots (TODO en docstring dispatcher.lua lÃ­nea 27).
-- Schema: key CHAR(64) PK + JSON result + expires_at unix sec.
-- GC: purga expired rows cada N min (implementado en S1 junto con migration
-- dispatcher path).
--
-- TTL default 1h (Config.IdempotencyTTLSec).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bridge_idempotency (
  idem_key     CHAR(64)       NOT NULL COMMENT 'hash key Ãºnico per operaciÃ³n lÃ³gica',
  module       VARCHAR(32)    NOT NULL COMMENT 'bank, inventory, phone, ... (bridge module)',
  method       VARCHAR(64)    NOT NULL COMMENT 'AddMoney, RemoveMoney, Transfer, ...',
  result_json  JSON           NOT NULL COMMENT 'resultado a devolver en replays',
  created_at   INT UNSIGNED   NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  expires_at   INT UNSIGNED   NOT NULL COMMENT 'unix sec expiraciÃ³n',

  PRIMARY KEY (idem_key),
  KEY idx_sonar_bridge_idempotency_expires (expires_at),
  KEY idx_sonar_bridge_idempotency_module_method (module, method, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- END 002_foundation_tables.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 003_bank_schema.sql
-- ============================================================================
-- ============================================================================
-- Migration: 003_bank_schema.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.1)
-- Description:
--   Crea las 2 tablas core del dominio banca:
--     1. sonar_bank_accounts   (cuentas IBAN personales/empresariales)
--     2. sonar_bank_movements  (ledger inmutable, PARTITIONED mensual)
--
--   `sonar_escrows` se difiere a S1.3 (ADR â€” green-light founder May 2 2026).
--   RazÃ³n: el DDL canÃ³nico no existe aÃºn en SSoT Â§03 Â§4.3, y la lÃ³gica escrow
--   se implementa en S1.3 â€” entrega aditiva limpia.
--
-- Dependencies:
--   - 001_schema_versions (runner tracking).
--   - 002_foundation_tables (sonar_accounts â†’ FK target).
--
-- Reversible: sÃ­ en dev (DROP TABLE â€” orden inverso por FK). NO post-prod.
--
-- SSoT references:
--   docs/technical/03_db_schema.md Â§4.1 (sonar_bank_accounts canonical).
--   docs/technical/03_db_schema.md Â§4.2 (sonar_bank_movements PARTITIONED).
--   docs/technical/03_db_schema.md Â§15.4 (cron mensual partitioning S2+).
--   docs/economy/01_economic_model.md Â§2.5 (IBAN format AD-XXXX-XXXX-XXXX).
--   docs/economy/01_economic_model.md Â§4.1 (starter balance 2.500 â‚¬).
--
-- DECISIONES TÃ‰CNICAS reconciliadas con SSoT (founder green-light 2026-05-02):
--
--   D1. Collation `utf8mb4_unicode_ci` (NO `utf8mb4_0900_ai_ci` SSoT) â€”
--       MariaDB-compat consistente con migration 002 (locked en S0.4).
--
--   D2. `updated_at ON UPDATE (UNIX_TIMESTAMP())` OMITIDO â€” MariaDB-illegal
--       para columnas non-TIMESTAMP. App-managed via SONAR.DB.Execute.
--       Ver migration 002 lÃ­nea 42 para el mismo patrÃ³n.
--
--   D3. FK `sonar_bank_accounts.owner_company_id â†’ sonar_companies(id)`
--       DEFERRED. La tabla `sonar_companies` no existe aÃºn (se crearÃ¡ S2+).
--       Cuando S2 cree `sonar_companies`, su migration aÃ±adirÃ¡ el FK via
--       ALTER TABLE ADD CONSTRAINT (non-breaking, aditivo). El comentario lo
--       deja explÃ­cito en el CREATE TABLE.
--
--   D4. CHECK constraint del tipo de owner SE MANTIENE (SSoT Â§4.1 lo define).
--       MariaDB 10.2+ y MySQL 8.0.16+ lo enforce nativamente. En versiones
--       previas se ignora silenciosamente â€” la lÃ³gica owner-type-correcta se
--       enforce ademÃ¡s a application-layer en server/accounts.lua.
--
--   D5. Particiones bank_movements REFRESCADAS â€” SSoT cita p_2026_01..03 (Feb-Apr
--       2026) que ya estÃ¡n en el pasado. Nuevas partitions cubren May/Jun/Jul
--       2026 (sprint window) + p_future MAXVALUE catchall. Cron mensual S2+
--       harÃ¡ rolling forward (per SSoT Â§03 Â§15.4 ejemplo Lua incluido).
--
--   D6. Escrow type inicial soportado en ENUM `type` aunque la tabla
--       `sonar_escrows` se difiere â€” esto permite a S1.3 simplemente
--       INSERT un account con type='escrow' sin necesitar nuevo ENUM ALTER.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. sonar_bank_accounts
--
-- Una cuenta bancaria con IBAN Ãºnico. Puede ser personal (owner_account_id)
-- o empresarial/cooperativa/escrow (owner_company_id).
--
-- Constraints:
--   - PRIMARY KEY id (UUID v4 application-generated).
--   - UNIQUE iban (no dos cuentas con mismo IBAN).
--   - CHECK XOR ownership (personal âŠ• company-like).
--   - FK soft delete: ON DELETE RESTRICT (no permitir borrar account/company
--     con cuenta bancaria asociada â€” debe cerrar primero).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_accounts (
  id                    CHAR(36)        NOT NULL COMMENT 'UUID v4',
  iban                  VARCHAR(20)     NOT NULL COMMENT 'AD-XXXX-XXXX-XXXX (17 chars literales)',
  type                  ENUM('personal','company','cooperative','escrow') NOT NULL,

  owner_account_id      CHAR(36)        NULL     COMMENT 'NULL si type != personal',
  owner_company_id      CHAR(36)        NULL     COMMENT 'NULL si type=personal â€” FK a sonar_companies se aÃ±ade en S2+',

  balance               DECIMAL(14,2)   NOT NULL DEFAULT 0 COMMENT 'saldo actual (negativo = overdraft admin-only)',
  daily_limit_out       DECIMAL(12,2)   UNSIGNED NULL COMMENT 'lÃ­mite saliente diario (NULL = sin lÃ­mite)',
  is_frozen             TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '0=activo, 1=congelada (anti-fraude)',
  frozen_reason         VARCHAR(255)    NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  -- updated_at: app-managed (NO ON UPDATE â€” MariaDB-illegal en INT UNSIGNED).
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  closed_at             INT UNSIGNED    NULL     COMMENT 'cuenta cerrada (soft-delete)',

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_accounts_iban (iban),
  KEY idx_sonar_bank_accounts_owner_account (owner_account_id),
  KEY idx_sonar_bank_accounts_owner_company (owner_company_id),
  KEY idx_sonar_bank_accounts_type_active (type, closed_at),

  CONSTRAINT fk_sonar_bank_accounts_owner_account
    FOREIGN KEY (owner_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE

  -- FK sonar_companies se aÃ±ade S2+ via ALTER TABLE (entrega aditiva):
  --   ALTER TABLE sonar_bank_accounts
  --     ADD CONSTRAINT fk_sonar_bank_accounts_owner_company
  --     FOREIGN KEY (owner_company_id) REFERENCES sonar_companies(id)
  --     ON DELETE RESTRICT ON UPDATE CASCADE;
  --
  -- D4 reconciled (Phase 8 post-rename, MariaDB 12.2.2 fix): el CHECK XOR
  -- named constraint causa "Function or expression 'owner_account_id' cannot
  -- be used in the CHECK clause" en MariaDB 12.x parser (named CHECK + IS NULL
  -- multi-col tras FK constraint). Workaround: enforcement 100% application-layer
  -- en `server/accounts.lua` (CreateAccount valida typeâ†’owner XOR antes INSERT).
  -- Defense-in-depth DDL omitida para unblock dev boot. Re-evaluar S2+ si MariaDB
  -- bug fixed o cambio engine.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 2. sonar_bank_movements (PARTITIONED RANGE BY occurred_at)
--
-- Ledger inmutable contable. Cada transferencia genera 2 rows (debe + haber).
-- Particionado mensual permite:
--   - Pruning automÃ¡tico por queries con WHERE occurred_at >= ...
--   - Archival a cold storage por partition completa.
--   - DROP PARTITION rÃ¡pido (vs DELETE row-by-row).
--
-- Notas SSoT Â§4.2:
--   - NO FK a bank_account_id intencionalmente (volumen + integrity por app).
--   - PRIMARY KEY (id, occurred_at) requerido por MySQL para particionar
--     usando occurred_at como partition key.
--   - request_nonce evita replay attacks (idempotency anti-double-spend).
--   - balance_after es snapshot â€” auditable sin recalcular cadena.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_movements (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  bank_account_id       CHAR(36)        NOT NULL,
  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  amount                DECIMAL(14,2)   NOT NULL COMMENT 'positivo=ingreso, negativo=salida',
  balance_after         DECIMAL(14,2)   NOT NULL COMMENT 'saldo tras este movimiento (snapshot)',

  category              ENUM(
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
    'starter_seed'
  ) NOT NULL COMMENT 'categorÃ­a contable; starter_seed aÃ±adida para 2.500â‚¬ inicial',
  counterpart_iban      VARCHAR(20)     NULL,
  concept               VARCHAR(255)    NULL,

  related_doc_id        CHAR(36)        NULL,
  related_offer_id      CHAR(36)        NULL,
  related_job_id        CHAR(36)        NULL,
  request_nonce         CHAR(36)        NULL COMMENT 'idempotency anti-replay',

  initiated_by_account_id CHAR(36)      NULL,
  source_resource       VARCHAR(64)     NOT NULL COMMENT 'sonar_bank, sonar_market, ...',

  PRIMARY KEY (id, occurred_at),
  KEY idx_sonar_bank_movements_account (bank_account_id, occurred_at DESC),
  KEY idx_sonar_bank_movements_category (category, occurred_at DESC),
  KEY idx_sonar_bank_movements_nonce (request_nonce),
  KEY idx_sonar_bank_movements_related_doc (related_doc_id),
  KEY idx_sonar_bank_movements_related_offer (related_offer_id),
  KEY idx_sonar_bank_movements_related_job (related_job_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  PARTITION BY RANGE (occurred_at) (
    -- Partition timestamps refrescados May 2026 (SSoT D5).
    PARTITION p_2026_05 VALUES LESS THAN (1748736000),  -- < Jun 1 2026 UTC
    PARTITION p_2026_06 VALUES LESS THAN (1751328000),  -- < Jul 1 2026 UTC
    PARTITION p_2026_07 VALUES LESS THAN (1754006400),  -- < Aug 1 2026 UTC
    PARTITION p_2026_08 VALUES LESS THAN (1756684800),  -- < Sep 1 2026 UTC
    PARTITION p_future  VALUES LESS THAN MAXVALUE       -- catch-all hasta cron S2+
  );

-- ============================================================================
-- END 003_bank_schema.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 004_bank_seed_system_account.sql
-- ============================================================================
-- ============================================================================
-- Migration: 004_bank_seed_system_account.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.2)
-- Description:
--   Seed system bank account `AD-SYS0-0000-0001` con balance 10.000.000 â‚¬.
--   Esta cuenta es la treasury server-side. Investment for S1.3 (escrow fees,
--   tax retention, market fees â†’ entran a esta IBAN en sprints futuros). En
--   S1.2 NO recibe transferencias (internal transfer fee = 0 â‚¬ per SSoT
--   `economy/01_economic_model.md` Â§10.3:697).
--
-- Dependencies:
--   - 002_foundation_tables (sonar_accounts â†’ FK target).
--   - 003_bank_schema (sonar_bank_accounts + sonar_bank_movements).
--
-- Reversible: sÃ­ en dev (DELETE rows con UUIDs fijos). NO post-prod.
--
-- SSoT references:
--   docs/economy/01_economic_model.md Â§4.2 (NPC system IBAN balance 10M â‚¬).
--   docs/economy/01_economic_model.md Â§10.3 (internal transfer fee = 0 â‚¬).
--   docs/technical/03_db_schema.md Â§13.3 (system account ejemplo INSERT).
--   docs/technical/03_db_schema.md Â§4.1 (sonar_bank_accounts CHECK XOR).
--
-- DECISIONES TÃ‰CNICAS (founder green-light 2026-05-02):
--
--   D1. CHECK XOR ownership es ESTRICTO en migration 003:107-110 â€” exige
--       (type='personal' AND owner_account_id IS NOT NULL AND owner_company_id IS NULL)
--       OR (type IN ('company','cooperative','escrow') AND owner_company_id IS NOT NULL AND owner_account_id IS NULL).
--
--       Founder recomendÃ³ type='escrow' MÃS opciÃ³n (a) "sonar_accounts
--       ficticio para owner_account_id" â€” son INCOMPATIBLES entre sÃ­ (escrow
--       requiere owner_company_id, no owner_account_id).
--
--       Ãšnico path consistente con CHECK + opciÃ³n(a) sin tocar constraint:
--         type = 'personal'
--         owner_account_id = SYSTEM sonar_accounts ficticio (creado aquÃ­).
--
--       SemÃ¡nticamente raro ("system" no es realmente "personal") pero pragmÃ¡tico.
--       Technical debt anotado para S2+: ALTER ENUM 'system' + relax CHECK O
--       crear sonar_companies ficticio cuando esa tabla exista (S2 schema).
--
--   D2. UUID fijos determinÃ­sticos â€” facilita test + debugging + queries
--       analytics ("Â¿es la cuenta system?" â†’ WHERE id='b0000000-...').
--       No riesgo seguridad: UUID system es pÃºblico (visible en cualquier
--       extracto bancario que reciba pago a system).
--
--   D3. INSERT IGNORE en accounts + bank_accounts (UNIQUE iban + PK id como
--       guards). Re-arranque server NO altera balance ni duplica rows.
--
--   D4. Movement seed (categorÃ­a 'adjustment' per ENUM canÃ³nico Â§4.2:556) â€”
--       trail contable del seed inicial. request_nonce fijo permite NOT EXISTS
--       check para idempotency manual (defense-in-depth sobre runner tracking).
--
--   D5. La runner tracking (sonar_schema_versions) ya garantiza que esta
--       migration solo se aplica 1 vez. Los IGNOREs y NOT EXISTS son
--       defense-in-depth ante manual re-run accidental.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. SYSTEM sonar_accounts ficticio.
--
-- char_id = 'SYSTEM' (reservado â€” no asignable a player real porque los
-- citizenIds reales contienen 'license:' o 'license2:' o numÃ©rico, nunca
-- el literal 'SYSTEM').
-- framework_source = 'sonar_core' (no proviene de qbox/esx â€” server-managed).
-- ----------------------------------------------------------------------------
INSERT IGNORE INTO sonar_accounts
  (id, char_id, framework_source, alias, created_at, updated_at, last_login_at)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'SYSTEM',
  'sonar_core',
  'SONAR System',
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(),
  NULL
);


-- ----------------------------------------------------------------------------
-- 2. SYSTEM sonar_bank_accounts (IBAN AD-SYS0-0000-0001).
--
-- type = 'personal' por restricciÃ³n CHECK (D1 arriba). Owner = SYSTEM account.
-- balance = 10.000.000 â‚¬ per SSoT economy Â§4.2.
-- frozen=0 deliberadamente para permitir transferencias hacia/desde
-- (escrow fees S1.3+, tax retention S2+).
-- ----------------------------------------------------------------------------
INSERT IGNORE INTO sonar_bank_accounts
  (id, iban, type, owner_account_id, owner_company_id,
   balance, daily_limit_out, is_frozen, frozen_reason,
   created_at, updated_at, closed_at)
VALUES (
  'b0000000-0000-0000-0000-000000000001',
  'AD-SYS0-0000-0001',
  'personal',
  '00000000-0000-0000-0000-000000000001',
  NULL,
  10000000.00,
  NULL,
  0,
  NULL,
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(),
  NULL
);


-- ----------------------------------------------------------------------------
-- 3. SYSTEM seed movement (audit trail del seed inicial).
--
-- amount = +10.000.000 (signed amount per SSoT Â§4.2 â€” positivo=ingreso).
-- balance_after = 10.000.000 (snapshot post-movement).
-- category = 'adjustment' (categorÃ­a canÃ³nica para seeds/correcciones admin).
-- request_nonce = UUID v4 fijo para idempotency NOT EXISTS check.
-- source_resource = 'sonar_core' (originador del seed).
-- ----------------------------------------------------------------------------
INSERT INTO sonar_bank_movements
  (bank_account_id, occurred_at,
   amount, balance_after,
   category, counterpart_iban, concept,
   related_doc_id, related_offer_id, related_job_id,
   request_nonce, initiated_by_account_id, source_resource)
SELECT
  'b0000000-0000-0000-0000-000000000001', UNIX_TIMESTAMP(),
  10000000.00, 10000000.00,
  'adjustment', NULL, 'System treasury seed (10M EUR per economy Â§4.2)',
  NULL, NULL, NULL,
  'a0000000-0000-0000-0000-00000000seed', NULL, 'sonar_core'
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM sonar_bank_movements
  WHERE request_nonce = 'a0000000-0000-0000-0000-00000000seed'
);

-- ============================================================================
-- END 004_bank_seed_system_account.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 005_balance_nonneg_check.sql
-- ============================================================================
-- ============================================================================
-- Migration: 005_balance_nonneg_check.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.2 fix-and-validate)
-- Description:
--   AÃ±adir CHECK constraint `chk_sonar_bank_accounts_balance_nonneg`
--   que enforce balance >= 0 SQL-side. Resuelve race window de S1.2 transfer
--   atomicity por construcciÃ³n: si concurrent op vacÃ­a saldo entre pre-fetch
--   y UPDATE balance = balance - amount, MySQL rechaza el UPDATE (CHECK
--   violated) â†’ toda la TX rollback automÃ¡tico per oxmysql native behavior.
--   Ledger queda 100% consistente. NO requiere function-form transaction
--   (oxmysql NO lo soporta â€” verificado en doc /Functions/transaction).
--
-- Supersedes intent del comment migration 003:79 ("negativo = overdraft
-- admin-only"). S1-S3 roadmap NO incluye overdraft. Bloqueo hard via CHECK.
-- Si S2+ requiere overdraft admin-only:
--   ALTER TABLE sonar_bank_accounts DROP CHECK chk_sonar_bank_accounts_balance_nonneg;
-- + add conditional CHECK con admin_overdraft_enabled flag column (non-breaking, opt-in).
--
-- Migration inmutable: NO editar 003 post-aplicada (S0.4 design â€” checksum
-- tracked en sonar_schema_versions). Refresh comment 003 deferred S2+
-- via migration aditiva si overdraft entra roadmap.
--
-- Reversible: sÃ­ (DROP CHECK).
--
-- Dependencies:
--   - 003_bank_schema (sonar_bank_accounts table existe).
--
-- DECISIONES TÃ‰CNICAS (founder green-light 2026-05-02 fix-and-validate):
--
--   D1. CHECK > app-side defense en WHERE clause. WHERE balance >= ? era
--       silent failure (UPDATE 0 rows, TX commits) â€” no aborta. CHECK fuerza
--       SQL error â†’ MySQL.transaction.await retorna false â†’ DB.Transaction
--       returns false â†’ Transfer.Execute mapea a TX_ROLLBACK / RACE_DETECTED.
--
--   D2. MariaDB 10.2+ y MySQL 8.0.16+ enforce CHECK nativamente. Versiones
--       previas lo IGNORAN silenciosamente â€” degrade gracefully a S1.2 race
--       behavior previo. ProducciÃ³n SONAR targets MariaDB 10.6+ per
--       SSoT Â§03 Â§1.2 (a verificar â€” no es S1.2 scope confirm exact ver).
--
--   D3. Constraint name explicit (chk_sonar_bank_accounts_balance_nonneg)
--       â€” idiomatic per S0.4 + S1.1 pattern. Permite ALTER DROP/ADD
--       referenciando por nombre.
--
--   D4. ALTER TABLE ADD CONSTRAINT IF NOT EXISTS â€” defense-in-depth contra
--       manual re-run (idempotent). Runner tracking en sonar_schema_versions
--       ya garantiza single-apply, pero IF NOT EXISTS preserva el behavior
--       en case admin maintenance manual.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Pre-flight: verificar que no hay rows con balance < 0 actualmente.
--    Si existieran (no deberÃ­a en S1.2, pero defense-in-depth), el ALTER
--    fallarÃ­a con FK error â€” preferimos detectar pre-flight y abortar
--    con mensaje claro.
--
-- NOTA: SELECT statement aquÃ­ es informativo. MySQL aborta el ALTER si encuentra
-- violaciones; este SELECT solo facilita diagnostic en logs si falla.
-- ----------------------------------------------------------------------------
SELECT
  CONCAT('PRE-FLIGHT: ', COUNT(*), ' row(s) with balance < 0 (must be 0 for ALTER to succeed)') AS preflight_check
FROM sonar_bank_accounts
WHERE balance < 0;


-- ----------------------------------------------------------------------------
-- 2. ADD CHECK constraint balance >= 0.
--
-- Sintaxis MariaDB 10.2+ / MySQL 8.0.16+. Si la versiÃ³n NO soporta CHECK
-- enforcement, el ALTER se ejecuta sin error pero el CHECK es ignored â€”
-- atomicity revierte a S1.2 race behavior (ledger eventual via reconciliation).
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_bank_accounts
ADD CONSTRAINT chk_sonar_bank_accounts_balance_nonneg
CHECK (balance >= 0);

-- ============================================================================
-- END 005_balance_nonneg_check.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 006_escrow_schema.sql
-- ============================================================================
-- ============================================================================
-- Migration: 006_escrow_schema.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.3)
-- Description:
--   (a) Relaxa CHECK constraint de sonar_bank_accounts ownership para
--       permitir `type='escrow'` con ambos owner_account_id + owner_company_id
--       NULL (las cuentas escrow son server-managed, sin owner real).
--       Nombre anterior: `chk_sonar_bank_accounts_owner_xor` (migration 003).
--       Nombre nuevo:    `chk_sonar_bank_accounts_owner_xor_or_escrow`.
--
--   (b) Crea tabla `sonar_escrows` â€” holdings transaccionales entre buyer
--       y seller con fee retenido. Referenced por FSM escrow_lifecycle per
--       `docs/technical/05_state_machines.md` Â§4.1.
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_accounts existe con constraint original).
--   - 005_balance_nonneg_check.sql (chk balance >= 0 preservado, no-op aquÃ­).
--
-- Reversible: sÃ­ en dev (DROP TABLE sonar_escrows + restore constraint
-- original). NO post-prod con escrows reales.
--
-- SSoT references (gaps documented â€” ADR formal S2+):
--   docs/technical/03_db_schema.md Â§4.3 â€” **GAP SSoT**: DDL canÃ³nico inexistente.
--     Esta migration implementa DDL funcional per diseÃ±o S1.3 (founder + agent).
--   docs/technical/04_api_contracts.md Â§3.1 C004/C005 (createEscrow/releaseEscrow).
--   docs/technical/05_state_machines.md Â§4.1 (FSM escrow_lifecycle, states
--     canÃ³nicos created/locked/released/refunded/disputed).
--   docs/economy/01_economic_model.md Â§10.4.1 (lifecycle) + Â§10.4.2
--     (fee 0.5-1%, caps 2-100â‚¬).
--
-- DECISIONES TÃ‰CNICAS (founder green-light 2026-05-02 F1-F5 resoluciones):
--
--   D1. CONSTRAINT chk_sonar_bank_accounts_owner_xor_or_escrow â€”
--       3 ramas explÃ­citas, preserva strictness pre-006 para personal/company/
--       cooperative + aÃ±ade rama `type='escrow'` (ambos owner NULL permitido).
--       Aditivo puro â€” comportamiento non-escrow idÃ©ntico al pre-006.
--
--   D2. `sonar_escrows.status` ENUM 5 valores per SSoT Â§05 Â§4.1:
--       `created`, `locked`, `released`, `refunded`, `disputed`.
--       S1.3 implementa transitions `createdâ†’locked` (atomic INSERT direct
--       status='locked' en TX Create), `lockedâ†’released`, `lockedâ†’refunded`.
--       `disputed` declarado en ENUM â€” behavior NOT implementado S1.3 (deferred
--       S2+ con contract dispute callbacks). Cero breaking change al aÃ±adirlo.
--
--   D3. `expires_at INT UNSIGNED NOT NULL` â€” populated en Create como
--       `created_at + Config.EscrowDefaultExpirySeconds` (default 30 dÃ­as
--       per economy Â§19.1.2). S1.3 NO implementa cron auto-refund al expirar
--       â€” schema field existe + Ã­ndice `idx_...status_expires` soporta query
--       futuro. Timeout behavior deferred S2+.
--
--   D4. `request_nonce CHAR(36) NOT NULL UNIQUE` â€” idempotency key cliente.
--       UUID v4. Permite replay detection: 2Âª createEscrow con mismo
--       request_id â†’ DB throw `Duplicate entry for key uq_..._request_nonce`,
--       caller detecta + returns cached response via
--       `exports.sonar_bridges:IsIdemReplay` (consistency con S1.2 C002).
--
--   D5. `released_to ENUM('seller','buyer','split')` â€” 'split' declarado
--       para forward-compat S3+ (partial release). S1.3 release callbacks
--       rechazan 'split' con error_code `NOT_IMPLEMENTED` (canonical nuevo).
--
--   D6. `fee_charged DECIMAL(15,2) NOT NULL` â€” fee **retenido por system
--       treasury** al crear escrow per economy Â§10.4.2. Formula aplicaciÃ³n:
--       `fee = max(2.0, min(amount * 0.01, 100.0))`. Fee NO se devuelve al
--       buyer en caso de refund (founder decisiÃ³n S1.2 manteniendo â€” evita
--       gaming "crea-refund-crea" para cobrar fee 0 via mass disputes).
--
--   D7. FKs `ON DELETE RESTRICT` (SSoT Â§1.6 lÃ­nea 117-119 "legal integrity")
--       â€” no se puede borrar buyer/seller/escrow account con escrows activos.
--       DIVERGENCE: el DDL fue aplicado manualmente (HeidiSQL 2026-05-02)
--       sin `ON DELETE RESTRICT` explÃ­cito. InnoDB default NO ACTION â‰ˆ
--       RESTRICT comportamiento funcional (referential integrity blocked).
--       Este file declara RESTRICT explÃ­cito para fresh installs â€” tablas
--       existentes permanecen en NO ACTION implÃ­cito sin impacto operacional.
--
--   D8. CHECK `amount > 0` + `fee_charged >= 0` â€” atomicity by construction
--       (MariaDB 10.4.32+ enforce nativo, verificado 2026-05-02 VERSION()).
--       App-layer enforces ademÃ¡s (Escrow.Create valida pre-TX).
--
--   D9. Idempotent DDL pattern â€” `DROP CONSTRAINT IF EXISTS` + `CREATE TABLE
--       IF NOT EXISTS`. Permite re-apply tras HeidiSQL manual (tracking row
--       backfilled via INSERT separado con SHA-256 del body). Fresh installs
--       ejecutan todo desde cero sin error.
--
--   D10. ADR-010 inmutabilidad â€” este file NO se edita post-aplicaciÃ³n. Si
--        se necesita schema change â†’ nueva migration 007+ aditiva. Checksum
--        check en `sonar_core/server/migrations.lua:253` enforce tampering
--        detection.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Relax CHECK constraint sonar_bank_accounts â€” add `type='escrow'` branch.
--
-- Pre-006: `chk_sonar_bank_accounts_owner_xor` (migration 003 lÃ­nea 107)
--   strict XOR personalâ†”company/cooperative/escrow con owner correspondiente.
--   Problema S1.3: escrow accounts son server-managed, sin owner real.
--
-- Post-006: `chk_sonar_bank_accounts_owner_xor_or_escrow` 3-ramas:
--   - type='escrow' â†’ ambos owner_* NULL (server-managed).
--   - type='personal' â†’ owner_account_id NOT NULL AND owner_company_id IS NULL.
--   - type IN ('company','cooperative') â†’ owner_company_id NOT NULL AND owner_account_id IS NULL.
--
-- Aditivo: non-escrow rows pre-006 siguen vÃ¡lidas.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_bank_accounts
  DROP CONSTRAINT IF EXISTS chk_sonar_bank_accounts_owner_xor;

ALTER TABLE sonar_bank_accounts
  DROP CONSTRAINT IF EXISTS chk_sonar_bank_accounts_owner_xor_or_escrow;

-- Phase 8 post-rename (MariaDB 12.2.2 fix): el CHECK XOR-or-escrow named constraint
-- causa "Function or expression cannot be used in the CHECK clause" en MariaDB 12.x
-- parser (named CHECK + IS NULL multi-col + tipo enumerado). Workaround coherente con
-- 003_bank_schema.sql D4: enforcement 100% application-layer en `server/accounts.lua`
-- + `server/escrow.lua` (CreateEscrowAccount valida type='escrow' AND ambos owner_*=NULL
-- antes INSERT). Re-evaluar S2+ si MariaDB bug fixed o cambio engine.
-- ALTER TABLE sonar_bank_accounts
--   ADD CONSTRAINT chk_sonar_bank_accounts_owner_xor_or_escrow CHECK (
--     type = 'escrow'
--     OR (type = 'personal' AND owner_account_id IS NOT NULL AND owner_company_id IS NULL)
--     OR (type IN ('company','cooperative') AND owner_company_id IS NOT NULL AND owner_account_id IS NULL)
--   );


-- ----------------------------------------------------------------------------
-- 2. sonar_escrows â€” holdings transaccionales buyerâ†”seller con fee retained.
--
-- FSM escrow_lifecycle per SSoT Â§05 Â§4.1:
--   created (INSERT conceptual) â†’ locked (post-funding atomic, S1.3 happy path
--     persiste direct 'locked' en Create TX) â†’ released | refunded | disputed.
--
-- Cada row vincula:
--   - buyer_account_id    â†’ sonar_bank_accounts.id (del comprador)
--   - seller_account_id   â†’ sonar_bank_accounts.id (del vendedor)
--   - escrow_account_id   â†’ sonar_bank_accounts.id (cuenta tÃ©cnica server-
--                           managed, type='escrow', creada en la misma TX
--                           atomic que INSERT sonar_escrows).
--
-- IBAN del escrow account usa formato canonical S1.1 (AD-XXXX-XXXX-XXXX 17
-- chars via IBAN.Generate) â€” discriminaciÃ³n via type='escrow' column, NO
-- prefix especial (decisiÃ³n F5 founder S1.3).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_escrows (
  id                        CHAR(36)        NOT NULL COMMENT 'UUID v4 application-generated',
  status                    ENUM('created','locked','released','refunded','disputed') NOT NULL,

  buyer_account_id          CHAR(36)        NOT NULL COMMENT 'FK sonar_bank_accounts.id (buyer)',
  seller_account_id         CHAR(36)        NOT NULL COMMENT 'FK sonar_bank_accounts.id (seller)',
  escrow_account_id         CHAR(36)        NOT NULL COMMENT 'FK sonar_bank_accounts.id (escrow tÃ©cnico server-managed)',

  amount                    DECIMAL(15,2)   NOT NULL COMMENT 'Monto retenido (NO incluye fee)',
  fee_charged               DECIMAL(15,2)   NOT NULL COMMENT 'Fee cobrado a buyer en Create, no devuelto en refund',

  contract_id               VARCHAR(64)     NULL     COMMENT 'Ref contrato B2B (sonar_contracts S2+, NULL S1.3)',
  release_condition         ENUM('delivery_confirmed','manual','time_based') NOT NULL DEFAULT 'manual',
  release_date              INT UNSIGNED    NULL     COMMENT 'Si time_based, timestamp auto-release',

  expires_at                INT UNSIGNED    NOT NULL COMMENT 'created_at + EscrowDefaultExpirySeconds (30d S1.3)',
  request_nonce             CHAR(36)        NOT NULL COMMENT 'UUID v4 idempotency key de C004 createEscrow',

  released_to               ENUM('seller','buyer','split') NULL COMMENT 'Destino de release (NULL si locked/created)',
  released_by_account_id    CHAR(36)        NULL     COMMENT 'Account del caller de C005 (audit)',
  released_at               INT UNSIGNED    NULL     COMMENT 'Timestamp UNIX de transition â†’ released|refunded',

  created_at                INT UNSIGNED    NOT NULL,
  updated_at                INT UNSIGNED    NOT NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_escrows_request_nonce (request_nonce),

  KEY idx_sonar_escrows_buyer (buyer_account_id),
  KEY idx_sonar_escrows_seller (seller_account_id),
  KEY idx_sonar_escrows_escrow_account (escrow_account_id),
  KEY idx_sonar_escrows_status_expires (status, expires_at),
  KEY idx_sonar_escrows_contract (contract_id),

  CONSTRAINT fk_sonar_escrows_buyer
    FOREIGN KEY (buyer_account_id) REFERENCES sonar_bank_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_escrows_seller
    FOREIGN KEY (seller_account_id) REFERENCES sonar_bank_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_escrows_escrow_account
    FOREIGN KEY (escrow_account_id) REFERENCES sonar_bank_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_escrows_amount_positive CHECK (amount > 0),
  CONSTRAINT chk_sonar_escrows_fee_nonneg CHECK (fee_charged >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- FIN migration 006_escrow_schema.sql
-- ============================================================================

-- ============================================================================
-- END 006_escrow_schema.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 007_escrow_fks_to_accounts.sql
-- ============================================================================
-- ============================================================================
-- Migration: 007_escrow_fks_to_accounts.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.3 fix-forward)
-- Description:
--   Corrige FK targets de `sonar_escrows.buyer_account_id` y
--   `seller_account_id` â€” apuntaban incorrectamente a
--   `sonar_bank_accounts(id)` en migration 006 (error conceptual).
--
--   SemÃ¡ntica correcta (alineada con el cÃ³digo S1.3 ya escrito):
--     - buyer_account_id, seller_account_id â†’ sonar_accounts(id)
--       (player identity â€” permite que el buyer/seller cambie de bank account
--        en el futuro sin romper FK; auth matrix C005 hace caller_account_id
--        == stored value, chequeo a nivel identity).
--     - escrow_account_id â†’ sonar_bank_accounts(id)
--       (cuenta tÃ©cnica server-managed â€” FK correcto desde 006, no se toca).
--
-- Dependencies:
--   - 006_escrow_schema.sql (crea FKs originales a sonar_bank_accounts).
--
-- Reversible:
--   SÃ­ en dev. DROP nuevos FKs + re-ADD originales a sonar_bank_accounts(id).
--
-- Symptom pre-007:
--   INSERT INTO sonar_escrows ... VALUES (..., 'a816aa90-...', ...) â†’
--   "Cannot add or update a child row: a foreign key constraint fails
--   (sonar_escrows, CONSTRAINT fk_sonar_escrows_buyer FOREIGN KEY
--   (buyer_account_id) REFERENCES sonar_bank_accounts (id))"
--
-- DECISIONES TÃ‰CNICAS:
--
--   D1. NO modifico migration 006 in-place â€” ADR-010 immutability
--       (checksum guard). Este migration es aditivo per `003 â†’ 004 â†’ 005` pattern.
--
--   D2. SAFE en fresh install + existing DB:
--       - Fresh install: 006 crea FKs a bank_accounts, 007 los DROP+recreate a
--         sonar_accounts. Red de operaciones atomic DDL (InnoDB).
--       - Existing DB S1.3 pre-fix: 006 aplicado, 0 rows en sonar_escrows
--         (los INSERTs fallaron por FK violation, rolled back). DROP FK inocuo.
--
--   D3. `ON DELETE RESTRICT ON UPDATE CASCADE` preservado (legal integrity
--       per SSoT Â§1.6 y D7 de migration 006).
--
--   D4. Ãndices `idx_sonar_escrows_buyer`, `idx_sonar_escrows_seller`
--       NO se tocan â€” seguirÃ¡n apoyando queries by buyer/seller_account_id
--       (solo cambia la tabla a la que el valor referencia, no el Ã­ndice).
--
--   D5. S2+ extension path: cuando company pueda ser buyer/seller, aÃ±adir
--       columnas buyer_company_id + seller_company_id + CHECK XOR (mismo
--       pattern que sonar_bank_accounts.owner_account_id/owner_company_id).
--       Out of scope S1.3.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Drop FKs incorrectos de migration 006 (si existen).
--    `DROP FOREIGN KEY IF EXISTS` es MariaDB 10.4+ safe.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_buyer;

ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_seller;


-- ----------------------------------------------------------------------------
-- 2. Add FKs correctos apuntando a sonar_accounts(id).
--
-- NOTE: `ADD CONSTRAINT IF NOT EXISTS` no existe en MariaDB para FKs. Este
-- migration usa `ADD CONSTRAINT` directo â€” si ya existe un FK con el mismo
-- nombre tras drop, el previous DROP IF EXISTS lo eliminÃ³. Para re-apply
-- idempotency: el migrations runner skipea via schema_versions tracking,
-- NO re-ejecuta este file. Safe.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_escrows
  ADD CONSTRAINT fk_sonar_escrows_buyer
    FOREIGN KEY (buyer_account_id) REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE sonar_escrows
  ADD CONSTRAINT fk_sonar_escrows_seller
    FOREIGN KEY (seller_account_id) REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;


-- ============================================================================
-- FIN migration 007_escrow_fks_to_accounts.sql
-- ============================================================================

-- ============================================================================
-- END 007_escrow_fks_to_accounts.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 008_escrow_fks_revert_to_bank_accounts.sql
-- ============================================================================
-- ============================================================================
-- Migration: 008_escrow_fks_revert_to_bank_accounts.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.3 fix-forward 2/2)
-- Description:
--   Revert de migration 007 â€” los FKs `sonar_escrows.buyer_account_id` y
--   `seller_account_id` vuelven a apuntar a `sonar_bank_accounts(id)`
--   (como fueron en migration 006).
--
--   DecisiÃ³n de diseÃ±o (founder S1.3 smoke review):
--     Los escrows se linkean a **cuentas bancarias especÃ­ficas**, NO a player
--     identities. Alineado con `escrow_account_id` (ya FK bank_accounts). Los
--     tres campos buyer/seller/escrow_account_id ahora son homogÃ©neos.
--
--   Ventajas:
--     - AuditorÃ­a mÃ¡s directa: cada escrow referencia 3 bank accounts concretas.
--     - Auth robusto: resolver owner del bank_account stored via lookup SQL,
--       sin depender de caches session que pueden quedar stale.
--     - Consistencia interna: todos los "*_account_id" del schema refieren
--       bank accounts; player identity se resuelve cuando se necesita.
--
-- Dependencies:
--   - 006_escrow_schema.sql (tabla sonar_escrows).
--   - 007_escrow_fks_to_accounts.sql (FKs a revertir).
--
-- TRUNCATE safe:
--   S1.3 smoke phase â€” 0 production rows. Los escrows de test fueron creados
--   con identity values en buyer/seller_account_id que ya NO son vÃ¡lidos
--   post-revert. TRUNCATE elimina esos rows huÃ©rfanos + resetea clean slate.
--
-- DECISIONES TÃ‰CNICAS:
--
--   D1. TRUNCATE TABLE sonar_escrows PRE-DROP-FK â€” elimina rows con
--       identity stored (inconsistentes con nuevos FKs). Safe porque:
--       - 0 production escrows (S1.3 aÃºn no shipped).
--       - Todos los rows actuales son artefactos de smoke pre-fix.
--
--   D2. `ON DELETE RESTRICT ON UPDATE CASCADE` idÃ©ntico a migration 006
--       original (preserva legal integrity Â§1.6).
--
--   D3. Code en `escrow.lua` tambiÃ©n se actualiza en mismo commit para
--       almacenar bank_accounts.id (buyer_acc.id, seller_acc.id) en lugar
--       de identity (.owner_account_id). Auth resuelto vÃ­a lookup explÃ­cito.
--
--   D4. ADR-010 respected â€” 006/007 no editados. 008 es aditivo + documenta
--       la evoluciÃ³n del diseÃ±o (006 correcto â†’ 007 mistake â†’ 008 canonical).
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Truncate inconsistent smoke rows.
-- ----------------------------------------------------------------------------
TRUNCATE TABLE sonar_escrows;


-- ----------------------------------------------------------------------------
-- 2. Drop FKs de migration 007 (apuntan a sonar_accounts).
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_buyer;

ALTER TABLE sonar_escrows
  DROP FOREIGN KEY IF EXISTS fk_sonar_escrows_seller;


-- ----------------------------------------------------------------------------
-- 3. Re-add FKs apuntando a sonar_bank_accounts(id) â€” como diseÃ±o original
--    migration 006, ahora aligned con el cÃ³digo.
-- ----------------------------------------------------------------------------
ALTER TABLE sonar_escrows
  ADD CONSTRAINT fk_sonar_escrows_buyer
    FOREIGN KEY (buyer_account_id) REFERENCES sonar_bank_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE sonar_escrows
  ADD CONSTRAINT fk_sonar_escrows_seller
    FOREIGN KEY (seller_account_id) REFERENCES sonar_bank_accounts(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;


-- ============================================================================
-- FIN migration 008_escrow_fks_revert_to_bank_accounts.sql
-- ============================================================================

-- ============================================================================
-- END 008_escrow_fks_revert_to_bank_accounts.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 010_bank_audit_ledger.sql
-- ============================================================================
-- ============================================================================
-- Migration: 010_bank_audit_ledger.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.1)
-- Description:
--   Crea tabla `sonar_bank_audit_ledger` â€” append-only inmutable + triggers
--   SIGNAL SQLSTATE '45000' BEFORE UPDATE/DELETE (3-tier defense-in-depth
--   tier 1 per Q-DB-F LOCKED 2026-05-06).
--
--   Particionamiento RANGE mensual para perf chaos test 200 concurrent <500ms
--   p99 (Q16.5) + audit retention legal indefinida (cold archival post 12
--   meses gestionado por DevOps Lead post-H4 cron).
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_accounts existe â€” FK target opcional).
--   - 002_foundation_tables.sql (sonar_accounts existe â€” FK actor_account_id).
--
-- Reversible: sÃ­ en dev (DROP TRIGGER + DROP TABLE). NO post-prod (audit
--   inmutable legal regulatorio).
--
-- SSoT references:
--   docs/technical/03_db_schema.md Â§22 (NEW v1.2 DRAFT v0.1).
--   docs/agents/teams/prompts/01_database_integrity_lead.md Â§4.5 (immutability strategy).
--   docs/agents/teams/slices/slice_database.md Â§3 OQ-DB-03 (defense-in-depth).
--   docs/agents/teams/01_SHARED_BRIEF.md Â§6.2 (anti-tech-debt â€” audit ledger immutability).
--
-- DECISIONES TÃ‰CNICAS (founder Q-DB-F + Q-DB-A LOCKED 2026-05-06):
--
--   D1. Tier 1 tier defense-in-depth: triggers SIGNAL BEFORE UPDATE/DELETE.
--       MariaDB 12.x soporta SIGNAL SQLSTATE estÃ¡ndar SQL.
--
--   D2. Tier 2 (REVOKE UPDATE/DELETE en role `sonar_bank_app_user`) NO se
--       implementa en migration â€” DevOps Lead config DB role post-H4. Este
--       file documenta requirement en comentario header.
--
--   D3. Tier 3 (app-level enforcer) Backend Lead implementa post-H1 â€” todo
--       INSERT pasa por `BankAuditLedger.Append(payload)` lib que rechaza
--       UPDATE/DELETE attempts at API level.
--
--   D4. Particionamiento RANGE mensual `ts` â€” pruning automÃ¡tico queries
--       Government Console scope "Todas" + audit retention. Cron rolling
--       forward DevOps Lead post-H4 (per docs/technical/03_db_schema.md Â§17.2).
--
--   D5. SysVer (system-versioned tables MariaDB 10.6+) DESCARTADO Q-DB-F â€”
--       semÃ¡ntica wrong para append-only puro (SysVer permite UPDATE +
--       archiva versiÃ³n, no rechaza).
--
--   D6. JSON column `context_data` para metadata flexible (citizen_id deltas,
--       transaction refs, FSM transitions context). NO normalizar â€” los
--       campos varÃ­an per event_type. Queries indexed via virtual generated
--       columns si surge necesidad (deferred v0.2+).
--
--   D7. CHECK constraint `amount_delta` NULL or numeric â€” MariaDB 12.x
--       soporta CHECK simples. Multi-col IS NULL workaround app-layer.
--
--   D8. NO FK a `sonar_bank_accounts.id` â€” bank_account_iban almacenado
--       como VARCHAR(20) snapshot (cuenta puede cerrarse + audit debe
--       sobrevivir). actor_account_id sÃ­ FK ON DELETE SET NULL (auditor
--       legal trail).
--
--   D9. Idempotent DDL â€” `CREATE TABLE IF NOT EXISTS` + `DROP TRIGGER IF
--       EXISTS` patterns. Re-apply safe.
--
--   D10. Charset `utf8mb4_unicode_ci` â€” MariaDB-compat consistent migrations
--        003+006 (NO `utf8mb4_0900_ai_ci` MySQL-only).
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. sonar_bank_audit_ledger â€” append-only immutable PARTITIONED RANGE month
--
-- Cada operaciÃ³n Bank-domain genera 1+ rows audit:
--   - Money flow (transfers, deposits, withdrawals, escrow lock/release).
--   - State changes (account freeze/unfreeze, FSM transitions).
--   - Admin actions (overdraft authorization, manual reconciliation).
--   - Compliance events (autoraise patterns, threshold breaches).
--   - Government actions (tax brackets edit, subsidies issued, election lifecycle).
--   - Audit reads scope "Todas" (transparency â€” quiÃ©n consultÃ³ quÃ©).
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
  ts                    INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) COMMENT 'partition key â€” UNIX seconds UTC',

  event_type            VARCHAR(64)     NOT NULL COMMENT 'canonical event taxonomy â€” Security Lead C-SEC-01 extends',
  severity              ENUM('info','notice','warning','critical') NOT NULL DEFAULT 'info',

  bank_account_iban     VARCHAR(20)     NULL COMMENT 'snapshot IBAN (cuenta puede cerrarse â€” audit sobrevive)',
  counterpart_iban      VARCHAR(20)     NULL,

  actor_account_id      CHAR(36)        NULL COMMENT 'citizen autor acciÃ³n â€” FK SET NULL si account borrado',
  actor_role            ENUM('citizen','company','government','admin','system','watchdog') NOT NULL DEFAULT 'system',

  amount_delta          DECIMAL(14,2)   NULL COMMENT 'delta dinero si aplica (NULL si event no monetary)',
  balance_after         DECIMAL(14,2)   NULL COMMENT 'snapshot balance post-event si aplica',

  correlation_id        CHAR(36)        NULL COMMENT 'correlation-id Backend mutex CP2 â€” link audit chain',
  request_nonce         CHAR(36)        NULL COMMENT 'idempotency anti-replay link',

  related_movement_id   BIGINT UNSIGNED NULL COMMENT 'link sonar_bank_movements.id si event movement-bound',
  related_escrow_id     CHAR(36)        NULL COMMENT 'link sonar_escrows.id si event escrow-bound',
  related_loan_id       CHAR(36)        NULL COMMENT 'link sonar_bank_loans.id si event loan-bound',
  related_compliance_flag_id BIGINT UNSIGNED NULL COMMENT 'link sonar_bank_compliance_flags.id si autoraise',

  context_data          JSON            NULL COMMENT 'metadata flexible per event_type â€” schema docs/technical/08_audit_hooks.md (Security Lead)',

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
  --   idx_..._iban_ts: query "audit por cuenta Ãºltimos N dÃ­as" (Audit Explorer Mis cuentas).
  --   idx_..._actor_ts: query "audit por citizen autor" (compliance investigations).
  --   idx_..._event_ts: query "audit por event_type" (Government Console filter).
  --   idx_..._severity_ts: query "audit critical/warning recientes" (Security dashboard).
  --   idx_..._correlation: link audit chain por correlation-id (Backend mutex CP2).
  --   idx_..._movement / _escrow / _loan / _flag: lookup audit por entity-bound.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  PARTITION BY RANGE (ts) (
    -- Initial partitions cubren BANK-DB.1 â†’ end-of-year 2026.
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
-- with SQLSTATE 45000 + descriptive message. App receives error â†’ fails fast.
--
-- Tier 2 (REVOKE privilege en role `sonar_bank_app_user`): DevOps Lead
-- post-H4 â€” DB role config (NOT in this migration).
--
-- Tier 3 (app-level enforcer): Backend Lead post-H1 â€” `BankAuditLedger.Append`
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
    SET MESSAGE_TEXT = 'sonar_bank_audit_ledger is append-only â€” UPDATE rejected';
END$$

CREATE TRIGGER trg_sonar_bank_audit_ledger_no_delete
  BEFORE DELETE ON sonar_bank_audit_ledger
  FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'sonar_bank_audit_ledger is append-only â€” DELETE rejected';
END$$

DELIMITER ;


-- ============================================================================
-- FIN migration 010_bank_audit_ledger.sql
--
-- POST-INSTALL DevOps Lead actions required (post-H4):
--   1. REVOKE UPDATE, DELETE ON sonar_bank_audit_ledger FROM 'sonar_bank_app_user';
--   2. Configure cron mensual partition rolling forward (per Â§17.2 SSoT).
--   3. Configure cold archival cron post 12 meses (per Â§17.3 retention legal).
-- ============================================================================

-- ============================================================================
-- END 010_bank_audit_ledger.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 011_bank_compliance_flags.sql
-- ============================================================================
-- ============================================================================
-- Migration: 011_bank_compliance_flags.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.1)
-- Description:
--   Crea tabla `sonar_bank_compliance_flags` â€” autoraise patterns canonical
--   per Q10 founder LOCKED 2026-05-06 (5 patterns).
--
--   Sustituye approach `unusual_destination_foreign_prefix` blueprint
--   pre-Q10 (Q8 multidivisa OFF â€” single-currency global, NO prefix foreign).
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_accounts existe â€” FK target).
--   - 002_foundation_tables.sql (sonar_accounts existe â€” FK target).
--
-- Reversible: sÃ­ en dev (DROP TABLE). NO post-prod si hay flags
--   ya raised (audit retention legal).
--
-- SSoT references:
--   docs/technical/03_db_schema.md Â§22 (NEW v1.2 DRAFT v0.1).
--   docs/agents/teams/01_SHARED_BRIEF.md Â§3.10 (Q10 â€” 5 patrones autoraise canonical).
--   docs/agents/teams/prompts/01_database_integrity_lead.md Â§4.5 (Q10 ENUM).
--   docs/agents/teams/slices/slice_security.md (Security Lead C-SEC-03 autoraise rules).
--
-- DECISIONES TÃ‰CNICAS (founder Q10 + Q-DB-A LOCKED 2026-05-06):
--
--   D1. ENUM `flag_type` 5 valores canonical:
--         'structuring'                â€” N transferencias <â‚¬1k consecutivas.
--         'large_transfer'             â€” single >â‚¬10k.
--         'late_tax'                   â€” tax payment >30 dÃ­as post-due.
--         'velocity'                   â€” >50 transacciones/24h.
--         'new_account_large_deposit'  â€” >â‚¬5k en cuenta <7 dÃ­as vida.
--       NO incluir 'unusual_destination_foreign_prefix' (Q8 OFF â€” single
--       currency, no prefix foreign).
--
--   D2. Status FSM 4-state: 'open' â†’ 'investigating' â†’ 'resolved' | 'false_positive'.
--       NO 'escalated' explicit â€” escalation se modela vÃ­a severity bump +
--       audit_ledger entries.
--
--   D3. severity ENUM 4 valores per audit_ledger consistency: info / notice /
--       warning / critical.
--
--   D4. evidence JSON column â€” flexible payload per flag_type (transaction
--       refs, threshold breached, time window, comparison values). Schema
--       documentado per flag_type en docs/technical/08_audit_hooks.md
--       (Security Lead C-SEC-03 post-H2).
--
--   D5. resolved_by_account_id NULL hasta resolution. action_taken ENUM
--       open-ended para Phase A â€” admin actions canonical post-H2 Security.
--
--   D6. NO FK a sonar_companies (Q-DB-E DEFERRED â€” opaque company_id).
--       FK sonar_bank_accounts.id sÃ­ enforced.
--
--   D7. CHECK simples MariaDB 12.x compatible â€” multi-col app-layer.
--
--   D8. Index strategy:
--         (citizen_account_id, status, raised_at) â€” Audit Explorer "Mi cuenta" + "open flags".
--         (flag_type, raised_at) â€” Government Console pattern analysis.
--         (severity, status) â€” Security dashboard "critical open".
--
--   D9. raised_by ENUM 'system' (autoraise Backend) | 'admin' (manual) |
--       'watchdog' (Bridge integrity check CP4). Founder approval pendiente
--       'watchdog' como source â€” defer si surge issue scope.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. sonar_bank_compliance_flags â€” autoraise patterns canonical
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_compliance_flags (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  flag_type             ENUM(
                          'structuring',
                          'large_transfer',
                          'late_tax',
                          'velocity',
                          'new_account_large_deposit'
                        ) NOT NULL COMMENT '5 patterns canonical Q10 LOCKED 2026-05-06',

  severity              ENUM('info','notice','warning','critical') NOT NULL DEFAULT 'warning',
  status                ENUM('open','investigating','resolved','false_positive') NOT NULL DEFAULT 'open',

  citizen_account_id    CHAR(36)        NOT NULL COMMENT 'FK sonar_accounts.id â€” citizen flagged',
  bank_account_id       CHAR(36)        NULL COMMENT 'FK sonar_bank_accounts.id si flag scope cuenta-especÃ­fica',
  company_id            CHAR(36)        NULL COMMENT 'FK sonar_companies(id) DEFERRED â€” issue #001',

  raised_by             ENUM('system','admin','watchdog') NOT NULL DEFAULT 'system',
  raised_by_account_id  CHAR(36)        NULL COMMENT 'admin account si raised_by=admin',

  threshold_value       DECIMAL(14,2)   NULL COMMENT 'umbral disparado (e.g. â‚¬10000 large_transfer)',
  observed_value        DECIMAL(14,2)   NULL COMMENT 'valor observado que disparÃ³ (e.g. transferencia â‚¬15500)',
  time_window_seconds   INT UNSIGNED    NULL COMMENT 'ventana temporal aplicable (e.g. 86400 para velocity)',

  evidence              JSON            NULL COMMENT 'payload flexible per flag_type â€” schema docs/technical/08_audit_hooks.md (Security Lead)',

  related_movement_ids  JSON            NULL COMMENT 'array BIGINT IDs sonar_bank_movements vinculadas',

  resolved_by_account_id CHAR(36)       NULL COMMENT 'admin/citizen autor resolution',
  action_taken          VARCHAR(255)    NULL COMMENT 'descripciÃ³n acciÃ³n tomada (freeze, contact, dismiss, ...)',
  resolution_note       TEXT            NULL,

  raised_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  -- updated_at: app-managed (NO ON UPDATE â€” MariaDB-illegal en INT UNSIGNED).
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  resolved_at           INT UNSIGNED    NULL,

  PRIMARY KEY (id),

  KEY idx_sonar_bank_compliance_flags_citizen_status_raised (citizen_account_id, status, raised_at DESC),
  KEY idx_sonar_bank_compliance_flags_bank_account (bank_account_id),
  KEY idx_sonar_bank_compliance_flags_company (company_id),
  KEY idx_sonar_bank_compliance_flags_type_raised (flag_type, raised_at DESC),
  KEY idx_sonar_bank_compliance_flags_severity_status (severity, status),
  KEY idx_sonar_bank_compliance_flags_raised_by (raised_by, raised_by_account_id),

  CONSTRAINT fk_sonar_bank_compliance_flags_citizen
    FOREIGN KEY (citizen_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_bank_compliance_flags_bank_account
    FOREIGN KEY (bank_account_id)
    REFERENCES sonar_bank_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_bank_compliance_flags_resolved_by
    FOREIGN KEY (resolved_by_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_compliance_flags_threshold_sane
    CHECK (threshold_value IS NULL OR threshold_value >= 0),

  CONSTRAINT chk_sonar_bank_compliance_flags_observed_sane
    CHECK (observed_value IS NULL OR observed_value >= 0)

  -- NO FK company_id â†’ sonar_companies(id) â€” Q-DB-E LOCKED 2026-05-06 (issue #001).
  -- Backend Lead post-H1 enforce app-layer validation `Companies.exists(company_id)`.
  --
  -- Index rationale:
  --   idx_..._citizen_status_raised: hot path Audit Explorer "Mi cuenta open flags".
  --   idx_..._bank_account: lookup flags por cuenta.
  --   idx_..._company: lookup flags por empresa.
  --   idx_..._type_raised: Government Console pattern analysis.
  --   idx_..._severity_status: Security dashboard "critical open".
  --   idx_..._raised_by: filter system/admin/watchdog.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- FIN migration 011_bank_compliance_flags.sql
-- ============================================================================

-- ============================================================================
-- END 011_bank_compliance_flags.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 012_bank_status_fsm.sql
-- ============================================================================
-- ============================================================================
-- Migration: 012_bank_status_fsm.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.1)
-- Description:
--   Crea tabla `sonar_bank_status` â€” single-row global per-server FSM
--   tracking estado del Bridge runtime (CP8 LOCKED 2026-05-06 + Q-DB-J).
--
--   FSM 4 states canonical:
--     - 'native_full'           â€” Q16 Layer 1 happy path (QBox/QBCore native + bridges full).
--     - 'lite_mode_active'      â€” Q16 Layer 2 fallback (ESX 1.10+ Lite mode).
--     - 'compromised_load_order' â€” CP4 watchdog detected load order issue.
--     - 'framework_missing'     â€” defensive boot CP4 â€” no framework detected.
--
-- Dependencies:
--   - 002_foundation_tables.sql (base â€” sin FK direct).
--
-- Reversible: sÃ­ en dev (DROP TABLE). NO post-prod (estado runtime + UI badge
--   sonar_bank_status footer always-visible per Q16.3 â€” siempre debe leer
--   estado).
--
-- SSoT references:
--   docs/technical/03_db_schema.md Â§23 (NEW v1.2 DRAFT v0.1).
--   docs/agents/teams/01_SHARED_BRIEF.md Â§4.3 (CP8 sonar_bank_status FSM).
--   docs/agents/teams/01_SHARED_BRIEF.md Â§3.16 Q16 (hybrid 3-layer + 8 CP).
--   docs/agents/teams/slices/slice_database.md Â§3.6 + OQ-DB-05 (per-server vs per-citizen).
--   docs/agents/teams/slices/slice_frontend.md Â§3 CP8 (UI badge footer always-visible).
--
-- DECISIONES TÃ‰CNICAS (founder Q-DB-J + Q-DB-A LOCKED 2026-05-06):
--
--   D1. Single row global per-server PK fijo `id=1` (Q-DB-J LOCKED).
--       Coherencia operacional â€” el estado del Bridge runtime es del server
--       process, NO del citizen.
--
--   D2. Trigger BEFORE INSERT enforce `id=1` solamente (defense-in-depth â€”
--       app-layer Backend Lead post-H1 tambiÃ©n garantiza single row).
--
--   D3. Initial seed row state='framework_missing' insertado por migration â€”
--       primer boot pasarÃ¡ a 'native_full' o 'lite_mode_active' segÃºn
--       defensive boot detection (CP4).
--
--   D4. Columna `last_transition_reason VARCHAR(255)` documenta razÃ³n de
--       Ãºltimo state change para debugging operacional + UI badge tooltip.
--
--   D5. Columna `bridge_version VARCHAR(32)` para correlacionar status con
--       versiÃ³n bridges deployed (DevOps Lead).
--
--   D6. Columna `framework_detected ENUM('qbox','qbcore','esx_modern','esx_legacy','none')`
--       â€” esx_legacy presente para detecciÃ³n + boot fail explÃ­cito (Q-DB-A
--       cut ESX legacy spec â€” boot rechaza con error claro).
--
--   D7. updated_at app-managed (MariaDB-illegal ON UPDATE INT UNSIGNED).
--       Backend Lead post-H1 garantiza UPDATE setea updated_at via lib
--       `BankStatus.Transition(new_state, reason)`.
--
--   D8. CHECK simples â€” single-row constraint via PK fijo + trigger.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. sonar_bank_status â€” single row global per-server FSM (CP8)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_status (
  id                       TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'PK fijo â€” single row global per-server',

  state                    ENUM(
                             'native_full',
                             'lite_mode_active',
                             'compromised_load_order',
                             'framework_missing'
                           ) NOT NULL DEFAULT 'framework_missing',

  framework_detected       ENUM('qbox','qbcore','esx_modern','esx_legacy','none') NOT NULL DEFAULT 'none',

  bridge_version           VARCHAR(32)     NULL COMMENT 'sonar_bridges semver â€” correlaciÃ³n versiÃ³n deployed',

  last_transition_reason   VARCHAR(255)    NULL COMMENT 'razÃ³n legible Ãºltimo state change',
  last_transition_actor    ENUM('system','watchdog','admin') NOT NULL DEFAULT 'system',

  experimental_handlers_ok TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 si sv_experimentalStateBagsHandler + sv_experimentalNetGameEventHandler + sv_enableNetEventReassembly detectados (Q16.4 + CP7)',

  created_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  -- transition_at: snapshot UNIX seconds Ãºltimo state change.
  transitioned_at          INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),

  CONSTRAINT chk_sonar_bank_status_single_row
    CHECK (id = 1)

  -- No FKs â€” tabla self-contained per-server runtime.
  --
  -- Index rationale: PK fijo `id=1` â€” single row reads â‰ª 1ms.
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
-- 3. Initial seed row â€” state 'framework_missing' baseline
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
  'initial seed migration 012 â€” awaiting defensive boot CP4 detection',
  'system',
  0
)
ON DUPLICATE KEY UPDATE id = id;  -- no-op si ya existe (re-apply safe).


-- ============================================================================
-- FIN migration 012_bank_status_fsm.sql
-- ============================================================================

-- ============================================================================
-- END 012_bank_status_fsm.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 013_bank_movements_partitions_extend.sql
-- ============================================================================
-- ============================================================================
-- Migration: 013_bank_movements_partitions_extend.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.1)
-- Description:
--   Extiende particiones RANGE de `sonar_bank_movements` desde Sep 2026
--   hasta Dec 2027 (Q-DB-G LOCKED 2026-05-06). Migration 003 dejÃ³ partitions
--   solo May-Aug 2026 + p_future MAXVALUE catchall â€” riesgo perf chaos test
--   200 concurrent reconciliation Sept 2026+ (Q16.5).
--
--   Aplica tambiÃ©n extends idÃ©ntico a `sonar_bank_audit_ledger` (creada
--   migration 010 con partitions May-Dec 2026 + p_future) hasta Dec 2027.
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_movements particionada original).
--   - 010_bank_audit_ledger.sql (sonar_bank_audit_ledger particionada).
--
-- Reversible: parcial â€” REORGANIZE PARTITION es operaciÃ³n InnoDB cara
--   (rebuild interno). En dev OK, en prod requiere maintenance window.
--   Down equivalent: REORGANIZE PARTITION p_2026_09..p_2027_12, p_future
--   INTO (p_future MAXVALUE) â€” pierde granularidad pero data preservada.
--
-- SSoT references:
--   docs/technical/03_db_schema.md Â§17 (particionado strategy).
--   docs/agents/teams/slices/slice_database.md Â§7 OQ-DB-02 (RANGE month strategy).
--   docs/agents/teams/01_SHARED_BRIEF.md Â§3.16 Q16.5 (perf 200 concurrent <500ms p99).
--
-- DECISIONES TÃ‰CNICAS (founder Q-DB-G LOCKED 2026-05-06):
--
--   D1. REORGANIZE PARTITION p_future INTO (32 partitions mensuales 2026-09 a
--       2027-12 + nuevo p_future MAXVALUE catchall). InnoDB rebuilds physical
--       data files â€” operation atÃ³mica por partition.
--
--   D2. Cron mensual rolling forward DevOps Lead post-H4 â€” cuando llegue
--       Nov 2027 se debe extender otra vez (cron aÃ±ade siguientes 12 meses
--       proactivamente).
--
--   D3. Aplicado mismo extends a sonar_bank_audit_ledger (creada migration
--       010 con scope May-Dec 2026 + p_future) â€” extends Sep 2026 â†’ Dec 2027
--       en la misma migration por coherencia operacional.
--
--   D4. Idempotency: pre-flight check via INFORMATION_SCHEMA.PARTITIONS â€”
--       si p_2026_09 ya existe (e.g. cron ya rolled forward antes de aplicar
--       esta migration), abort gracefully con NOTICE. NO usar IF NOT EXISTS
--       (REORGANIZE PARTITION no soporta sintaxis).
--
--   D5. Timestamps UTC pre-computados en comentarios â€” fuente de verdad para
--       cron rolling DevOps Lead (formato canonical first-of-month-UTC).
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Pre-flight check sonar_bank_movements â€” abort si p_2026_09 ya existe
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
    -- Aplicar extends â€” partitions Sep 2026 â†’ Dec 2027 mensuales.
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
-- 2. Pre-flight check sonar_bank_audit_ledger â€” abort si p_2027_01 ya existe
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
    -- Migration 010 dejÃ³ partitions May-Dec 2026 + p_future. Extends 2027 mensuales.
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
-- POST-INSTALL verification queries (manual run en HeidiSQL post-aplicaciÃ³n):
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
--   1. Configurar cron mensual rolling forward (per docs/technical/03_db_schema.md Â§17.2).
--   2. Cuando partitions se acerquen a Dec 2027 (~Nov 2027), cron debe extender automÃ¡ticamente.
--   3. Sin cron, riesgo perf degraded cuando p_future empiece a recibir data.
-- ============================================================================

-- ============================================================================
-- END 013_bank_movements_partitions_extend.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 014_bank_accounts_owner_type_split.sql
-- ============================================================================
-- ============================================================================
-- Migration: 014_bank_accounts_owner_type_split.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.2)
-- Description:
--   Refactoriza `sonar_bank_accounts.type` ENUM monolÃ­tico en 2 columnas
--   conceptualmente correctas (Q-DB-D LOCKED 2026-05-06):
--     - owner_type    ENUM tipo de propietario.
--     - account_class ENUM clase de cuenta (funciÃ³n contable).
--
--   Sustituye semÃ¡ntica mezclada (`type` mixaba ambos conceptos) por
--   modelado normalizado. Backfill data existente preservando integridad.
--
--   AÃ±ade ademÃ¡s `last_reconciled_at INT UNSIGNED NULL` (CP3 trust window
--   - Backend Lead reconciliation pipeline).
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_accounts.type existe).
--
-- Reversible: parcial â€” DOWN restaurarÃ­a `type` ENUM monolÃ­tico via UPDATE
--   reverse mapping + DROP nuevas columnas. OperaciÃ³n cara post-prod (rebuild
--   InnoDB rows). Documented en post-install notes.
--
-- SSoT references:
--   docs/technical/03_db_schema.md Â§29 Deviation Q-DB-D (NEW v1.3 DRAFT v0.1).
--   docs/agents/teams/01_SHARED_BRIEF.md Â§3 Q-DB-D (founder LOCKED 2026-05-06).
--
-- DECISIONES TÃ‰CNICAS (founder Q-DB-D + Q-DB-A LOCKED 2026-05-06):
--
--   D1. Split en 2 columns:
--       - owner_type ENUM('personal','company','cooperative','government','escrow_managed')
--           â–¸ describe QUIÃ‰N es el propietario.
--           â–¸ 'government' NEW para cuentas tesorerÃ­a gobierno (SYS treasury).
--           â–¸ 'escrow_managed' renombra 'escrow' clarificando que es cuenta
--             tÃ©cnica gestionada por sistema, NO propiedad de un actor.
--
--       - account_class ENUM('checking','savings','business_treasury','govt_treasury','escrow','crypto_wallet')
--           â–¸ describe FUNCIÃ“N CONTABLE de la cuenta.
--           â–¸ 'checking' default para personal/company. Soporta 'savings'
--             tier 4 future-proof.
--           â–¸ 'business_treasury' para cooperativas + empresas multi-signer.
--           â–¸ 'govt_treasury' para tesorerÃ­a gobierno (SYS treasury).
--           â–¸ 'escrow' para cuentas tÃ©cnicas escrow (FSM 6-states).
--           â–¸ 'crypto_wallet' future-proof Tier 4 (Q-DB-B BIGINT atomic).
--
--   D2. Backfill mapping data existente:
--       type='personal'    â†’ owner_type='personal',       account_class='checking'
--       type='company'     â†’ owner_type='company',        account_class='checking'
--       type='cooperative' â†’ owner_type='cooperative',    account_class='business_treasury'
--       type='escrow'      â†’ owner_type='escrow_managed', account_class='escrow'
--
--       NOTA: SYS treasury (`AD-SYS0-0000-0001`) seed migration 004 tiene
--       `type='company'`. Backfill genÃ©rico producirÃ­a owner_type='company'
--       account_class='checking', SEMÃNTICAMENTE INCORRECTO. Post-backfill
--       UPDATE explÃ­cito SYS treasury â†’ owner_type='government' +
--       account_class='govt_treasury' por IBAN match.
--
--   D3. ADD last_reconciled_at INT UNSIGNED NULL â€” CP3 trust window
--       reconciliation. NULL = nunca reconciliada. Backend Lead post-H1
--       lib `BankReconciliation.Apply()` actualiza este campo on-success.
--
--   D4. DROP index idx_sonar_bank_accounts_type_active (type, closed_at) â€” el
--       campo `type` desaparece. ADD index nuevo idx_sonar_bank_accounts_owner_type_class
--       (owner_type, account_class, closed_at) preservando coverage queries.
--
--   D5. NO modify CHECK constraint â€” D4 migration 003 ya documentÃ³ que CHECK
--       XOR estÃ¡ app-layer enforced (parser bug MariaDB 12.2.2). Sin cambio.
--
--   D6. ALTER TABLE sequence en transaction (START TRANSACTION + COMMIT).
--       MariaDB 12.x InnoDB DDL atomic â€” rollback completo si cualquier paso
--       falla.
--
--   D7. Column ordering: `owner_type` + `account_class` AFTER `iban` (mismo
--       lugar conceptual donde estaba `type`). MariaDB 12.x soporta `AFTER`
--       en ADD COLUMN.
--
--   D8. Idempotency: pre-flight check via INFORMATION_SCHEMA.COLUMNS â€” si
--       owner_type ya existe, abort gracefully (re-apply safe).
-- ============================================================================


START TRANSACTION;


-- ----------------------------------------------------------------------------
-- 1. Pre-flight idempotency check
--
-- Si owner_type ya existe â†’ migration ya aplicada, abort gracefully.
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
    -- 2. ADD nuevas columnas NULL initially (backfill despuÃ©s)
    -- ------------------------------------------------------------------------
    ALTER TABLE sonar_bank_accounts
      ADD COLUMN owner_type    ENUM('personal','company','cooperative','government','escrow_managed') NULL AFTER iban,
      ADD COLUMN account_class ENUM('checking','savings','business_treasury','govt_treasury','escrow','crypto_wallet') NULL AFTER owner_type,
      ADD COLUMN last_reconciled_at INT UNSIGNED NULL COMMENT 'CP3 trust window â€” Backend Lead reconciliation pipeline' AFTER closed_at;

    -- ------------------------------------------------------------------------
    -- 3. Backfill data existing â†’ mapping per D2
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
    -- 4. Override SYS treasury seed (migration 004) â€” correcciÃ³n semÃ¡ntica
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
--   2. Update queries SELECT/UPDATE references `type` â†’ use new columns.
--   3. Update repos + libs Bank-domain consuming `type`.
-- ============================================================================

-- ============================================================================
-- END 014_bank_accounts_owner_type_split.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 015_bank_movements_category_extend.sql
-- ============================================================================
-- ============================================================================
-- Migration: 015_bank_movements_category_extend.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.2)
-- Description:
--   Extiende ENUM `sonar_bank_movements.category` aÃ±adiendo 11 nuevos valores
--   canonical Phase A (Tax + Government + Tier 4 + Compliance event types).
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_movements existe).
--
-- Reversible: parcial â€” DOWN ALTER TABLE MODIFY COLUMN ENUM volviendo a
--   subset original es seguro SI no hay rows existing con valores nuevos.
--   Si hay rows con nuevos valores â†’ DOWN falla por integrity.
--
-- SSoT references:
--   docs/technical/03_db_schema.md Â§0.1 changelog "Tablas existing extends".
--   docs/agents/teams/01_SHARED_BRIEF.md Â§3.10 Q10 + Â§3.11 Q11 (tax flows + Tier 4).
--
-- DECISIONES TÃ‰CNICAS (founder Q-DB-A LOCKED 2026-05-06):
--
--   D1. ENUM extension via ALTER TABLE MODIFY COLUMN â€” MariaDB 12.x soporta
--       extending ENUM aditivamente sin rebuild de toda la tabla cuando solo
--       se aÃ±aden valores AL FINAL. Performance crÃ­tica para tabla
--       particionada con potencialmente millones de rows (Q16.5 chaos).
--
--       NOTA: aÃ±adir valores en medio del ENUM REQUIERE rebuild fÃ­sico full.
--       Por eso AÃ‘ADIMOS AL FINAL preservando orden existing.
--
--   D2. 11 nuevos valores canonical agrupados por dominio:
--
--       Tax + Government (Â§24):
--         - 'tax_subsidy'         â€” subsidio gobierno emitido a citizen.
--
--       Tier 4 â€” Loans (Â§25):
--         - 'loan_disbursement'   â€” desembolso prÃ©stamo (positive amount).
--         - 'loan_repayment'      â€” repago cuota prÃ©stamo (negative amount).
--
--       Tier 4 â€” Crypto (Â§25):
--         - 'crypto_buy'          â€” compra crypto (negative fiat).
--         - 'crypto_sell'         â€” venta crypto (positive fiat).
--
--       Tier 4 â€” Stocks (Â§25):
--         - 'stock_buy'           â€” compra acciones.
--         - 'stock_sell'          â€” venta acciones.
--
--       Tier 4 â€” Recurring (Â§25):
--         - 'recurring_charge'    â€” cargo recurrente (suscripciÃ³n, alquiler).
--
--       Tier 4 â€” Round-ups (Â§25):
--         - 'round_up'            â€” redondeo savings.
--
--       Tier 4 â€” Loyalty (Â§25):
--         - 'loyalty_redeem'      â€” canje puntos loyalty (positive).
--
--       Compliance (Â§22):
--         - 'compliance_freeze'   â€” congelaciÃ³n admin/watchdog (movement
--                                    tÃ©cnico amount=0 + audit trail).
--
--   D3. NO 'starter_seed' renombre â€” conservar legacy seed migration 004
--       compat. Rows existing preservadas.
--
--   D4. Idempotency: pre-flight check INFORMATION_SCHEMA.COLUMNS para detectar
--       si nuevos valores ya en ENUM definition. Si sÃ­ â†’ abort gracefully.
--
--   D5. Index idx_sonar_bank_movements_category sigue vÃ¡lido â€” ENUM extension
--       no afecta index B-tree (columna sigue mismo tipo lÃ³gico).
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

  -- Si 'tax_subsidy' ya estÃ¡ en ENUM â†’ migration ya aplicada.
  IF col_def NOT LIKE '%tax_subsidy%' THEN
    -- ----------------------------------------------------------------------
    -- 2. ALTER TABLE MODIFY COLUMN â€” extender ENUM aditivamente
    --
    -- Preservamos orden existing (12 valores originales + 'starter_seed') y
    -- aÃ±adimos 11 nuevos AL FINAL para evitar rebuild fÃ­sico (D1).
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
        -- NEW 11 valores Phase A (orden: tax â†’ loans â†’ crypto â†’ stocks â†’ recurring â†’ round_up â†’ loyalty â†’ compliance):
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
      ) NOT NULL COMMENT 'categorÃ­a contable Phase A â€” 24 valores canonical';
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

-- ============================================================================
-- END 015_bank_movements_category_extend.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 016_tax_brackets_history_subsidies.sql
-- ============================================================================
-- ============================================================================
-- Migration: 016_tax_brackets_history_subsidies.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.2)
-- Description:
--   Crea 3 tablas Tax-domain Phase A:
--     - sonar_bank_tax_brackets    â€” current tax brackets editable por gov.
--     - sonar_bank_tax_history     â€” append-only audit todo cambio brackets.
--     - sonar_bank_subsidies       â€” subsidios emitidos (UBI + targeted aid).
--
-- Dependencies:
--   - 002_foundation_tables.sql (sonar_accounts existe).
--   - 003_bank_schema.sql (sonar_bank_accounts existe).
--   - 010_bank_audit_ledger.sql (audit ledger event types tax_payment +
--                                 subsidy_issue + tax_brackets_edit).
--
-- Reversible: sÃ­ dev (DROP TABLES). NO post-prod (audit retention legal +
--   tax history append-only inmutable).
--
-- SSoT references:
--   docs/technical/03_db_schema.md Â§24 (NEW v1.4 DRAFT v0.2 â€” apendeo en BANK-DB.2).
--   docs/agents/teams/01_SHARED_BRIEF.md Â§3.10 Q10 + Â§3.11 Q11 (tax flows + Government UBI).
--
-- DECISIONES TÃ‰CNICAS (founder Q-DB-A + Q-DB-G LOCKED 2026-05-06):
--
--   D1. sonar_bank_tax_brackets â€” current snapshot tablebrackets editable.
--       Modelo wide (income_min/income_max + rate_pct) â€” N rows = N brackets.
--       Editable por Government Console (ACE `sonar.bank.govt.tax.edit`).
--       Trigger AFTER UPDATE/INSERT/DELETE sobre esta tabla â†’ INSERT en
--       sonar_bank_tax_history (audit append-only).
--
--   D2. sonar_bank_tax_history â€” append-only audit todo cambio. Triggers
--       SIGNAL BEFORE UPDATE/DELETE (mismo patrÃ³n Q-DB-F audit ledger).
--       Captura snapshot completo de bracket pre/post cambio + actor.
--
--   D3. sonar_bank_subsidies â€” subsidios emitidos. Tipos canonical:
--       'ubi_monthly' (Q-DB UBI universal income mensual), 'unemployment'
--       (subsidio desempleo activable), 'targeted_aid' (ayudas puntuales gov),
--       'cooperative_grant' (subvenciones cooperativas).
--
--   D4. FK sonar_accounts ON DELETE RESTRICT â€” citizen NO se puede borrar si
--       tiene subsidies pending o tax_history como editor.
--       FK sonar_bank_accounts ON DELETE SET NULL â€” bank account closing
--       preserva subsidy record (audit trail).
--
--   D5. CHECK constraints simples (Q-DB-A â€” multi-col app-layer):
--         - income_min < income_max
--         - rate_pct BETWEEN 0 AND 100
--         - amount > 0 (subsidies)
--
--   D6. brackets editable timestamp `effective_from` + `effective_until` â€” NO
--       tabla particionada (volumen bajo, ~10-50 brackets max). NULL until =
--       currently active.
--
--   D7. subsidies particionado RANGE `issued_at` mensual â€” volumen alto
--       (UBI mensual a todos citizens activos). Initial partitions May-Dec
--       2026 + p_future. Cron rolling forward DevOps Lead post-H4.
--
--   D8. Generated column `tax_brackets.is_active` STORED indexable â€” query
--       hot path "brackets activos hoy" optimizado vs filter compuesto.
--       Fallback: regular column updated by Backend Lead lib si parser bug.
-- ============================================================================


START TRANSACTION;


-- ----------------------------------------------------------------------------
-- 1. sonar_bank_tax_brackets â€” current brackets editable
--
-- Modelo: cada row = un bracket. Government Console UI permite CRUD.
-- Trigger AFTER â†’ audit a sonar_bank_tax_history.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_tax_brackets (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  bracket_name          VARCHAR(64)     NOT NULL COMMENT 'p.e. "low_income", "middle_class", "wealth_tax_high"',
  bracket_kind          ENUM('income_personal','income_business','wealth','transaction') NOT NULL DEFAULT 'income_personal',

  income_min            DECIMAL(14,2)   NOT NULL DEFAULT 0       COMMENT 'umbral mÃ­nimo (inclusive)',
  income_max            DECIMAL(14,2)   NULL                     COMMENT 'umbral mÃ¡ximo (exclusive). NULL = sin lÃ­mite superior',
  rate_pct              DECIMAL(5,2)    NOT NULL                 COMMENT 'tasa % (e.g. 22.50 = 22.5%)',

  effective_from        INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  effective_until       INT UNSIGNED    NULL COMMENT 'NULL = bracket activo',

  created_by_account_id CHAR(36)        NULL COMMENT 'admin gov account autor creaciÃ³n',
  updated_by_account_id CHAR(36)        NULL COMMENT 'admin gov account autor Ãºltimo update',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_tax_brackets_name_active (bracket_name, effective_until),
  KEY idx_sonar_bank_tax_brackets_kind_active (bracket_kind, effective_from, effective_until),

  CONSTRAINT fk_sonar_bank_tax_brackets_created_by
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_tax_brackets_updated_by
    FOREIGN KEY (updated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_tax_brackets_rate_pct
    CHECK (rate_pct >= 0 AND rate_pct <= 100),
  CONSTRAINT chk_sonar_bank_tax_brackets_income_min
    CHECK (income_min >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 2. sonar_bank_tax_history â€” append-only audit todo cambio bracket
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_tax_history (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  bracket_id            BIGINT UNSIGNED NOT NULL COMMENT 'FK lÃ³gico â€” NO enforced (bracket puede borrarse, history sobrevive)',

  change_type           ENUM('create','update','delete') NOT NULL,
  actor_account_id      CHAR(36)        NULL,
  actor_role            ENUM('admin','government','system') NOT NULL DEFAULT 'admin',

  -- Snapshot ANTES del cambio (NULL si change_type='create').
  before_bracket_name   VARCHAR(64)     NULL,
  before_bracket_kind   ENUM('income_personal','income_business','wealth','transaction') NULL,
  before_income_min     DECIMAL(14,2)   NULL,
  before_income_max     DECIMAL(14,2)   NULL,
  before_rate_pct       DECIMAL(5,2)    NULL,

  -- Snapshot DESPUÃ‰S del cambio (NULL si change_type='delete').
  after_bracket_name    VARCHAR(64)     NULL,
  after_bracket_kind    ENUM('income_personal','income_business','wealth','transaction') NULL,
  after_income_min      DECIMAL(14,2)   NULL,
  after_income_max      DECIMAL(14,2)   NULL,
  after_rate_pct        DECIMAL(5,2)    NULL,

  reason_note           TEXT            NULL COMMENT 'razÃ³n del cambio documentada por admin',

  changed_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_bank_tax_history_bracket (bracket_id, changed_at DESC),
  KEY idx_sonar_bank_tax_history_actor (actor_account_id, changed_at DESC),
  KEY idx_sonar_bank_tax_history_change_type (change_type, changed_at DESC),

  CONSTRAINT fk_sonar_bank_tax_history_actor
    FOREIGN KEY (actor_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Triggers SIGNAL append-only (Q-DB-F tier 1 pattern).
DROP TRIGGER IF EXISTS trg_sonar_bank_tax_history_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_tax_history_no_delete;

DELIMITER $$

CREATE TRIGGER trg_sonar_bank_tax_history_no_update
  BEFORE UPDATE ON sonar_bank_tax_history FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_tax_history is append-only â€” UPDATE rejected';
END$$

CREATE TRIGGER trg_sonar_bank_tax_history_no_delete
  BEFORE DELETE ON sonar_bank_tax_history FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_tax_history is append-only â€” DELETE rejected';
END$$

DELIMITER ;


-- ----------------------------------------------------------------------------
-- 3. sonar_bank_subsidies â€” subsidios emitidos (UBI + targeted aid)
--
-- Particionado RANGE issued_at mensual â€” UBI mensual a citizens activos
-- genera volumen alto.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_subsidies (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  subsidy_kind          ENUM('ubi_monthly','unemployment','targeted_aid','cooperative_grant') NOT NULL,

  beneficiary_account_id CHAR(36)       NOT NULL COMMENT 'citizen receiving subsidy',
  bank_account_id       CHAR(36)        NOT NULL COMMENT 'cuenta destino del subsidio',
  company_id            CHAR(36)        NULL COMMENT 'empresa beneficiaria (cooperative_grant) â€” opaque Q-DB-E',

  amount                DECIMAL(14,2)   NOT NULL,
  currency              CHAR(3)         NOT NULL DEFAULT 'EUR' COMMENT 'Q8 single-currency global',

  issued_by_account_id  CHAR(36)        NULL COMMENT 'admin gov autor (NULL si sistema UBI auto)',
  issued_by_role        ENUM('government','admin','system') NOT NULL DEFAULT 'system',

  related_movement_id   BIGINT UNSIGNED NULL COMMENT 'link sonar_bank_movements.id (category=tax_subsidy)',
  related_audit_id      BIGINT UNSIGNED NULL COMMENT 'link sonar_bank_audit_ledger.id',

  reason_note           VARCHAR(255)    NULL,
  reference_period      VARCHAR(32)     NULL COMMENT 'p.e. "2026-05" para UBI mensual',

  issued_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, issued_at),
  KEY idx_sonar_bank_subsidies_beneficiary_issued (beneficiary_account_id, issued_at DESC),
  KEY idx_sonar_bank_subsidies_kind_issued (subsidy_kind, issued_at DESC),
  KEY idx_sonar_bank_subsidies_period (subsidy_kind, reference_period),
  KEY idx_sonar_bank_subsidies_company (company_id),
  KEY idx_sonar_bank_subsidies_issued_by (issued_by_account_id, issued_at DESC),

  CONSTRAINT chk_sonar_bank_subsidies_amount_positive CHECK (amount > 0)

  -- NO FK company_id â†’ sonar_companies(id) â€” Q-DB-E DEFERRED issue #001.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  PARTITION BY RANGE (issued_at) (
    PARTITION p_2026_05 VALUES LESS THAN (1748736000),  -- < Jun 1 2026 UTC
    PARTITION p_2026_06 VALUES LESS THAN (1751328000),
    PARTITION p_2026_07 VALUES LESS THAN (1754006400),
    PARTITION p_2026_08 VALUES LESS THAN (1756684800),
    PARTITION p_2026_09 VALUES LESS THAN (1759276800),
    PARTITION p_2026_10 VALUES LESS THAN (1761955200),
    PARTITION p_2026_11 VALUES LESS THAN (1764547200),
    PARTITION p_2026_12 VALUES LESS THAN (1767225600),
    PARTITION p_future  VALUES LESS THAN MAXVALUE
  );


COMMIT;


-- ============================================================================
-- POST-INSTALL DevOps Lead actions required (post-H4):
--   1. Cron mensual rolling forward partitions sonar_bank_subsidies.
--   2. Cron mensual UBI batch issuance (Backend Lead post-H1 implementa).
-- ============================================================================

-- ============================================================================
-- END 016_tax_brackets_history_subsidies.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 017_govt_elections_candidates_votes.sql
-- ============================================================================
-- ============================================================================
-- Migration: 017_govt_elections_candidates_votes.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.2)
-- Description:
--   Crea 4 tablas Government-domain Phase A (elections + dual-layer privacy
--   per Q-DB-H LOCKED 2026-05-06):
--     - sonar_govt_elections           â€” elecciones FSM 4-state.
--     - sonar_govt_election_candidates â€” candidatos por elecciÃ³n.
--     - sonar_govt_votes               â€” votos pÃºblicos hasheados (privacy).
--     - sonar_govt_votes_audit         â€” votos raw admin-only ACE-gated.
--
-- Dependencies:
--   - 002_foundation_tables.sql (sonar_accounts existe).
--   - 010_bank_audit_ledger.sql (event types election_open + election_close +
--                                 vote_cast).
--
-- Reversible: sÃ­ dev. NO post-prod (election_history audit retention legal +
--   votes_audit ACE-gated).
--
-- SSoT references:
--   docs/technical/03_db_schema.md Â§24 (NEW v1.4 DRAFT v0.2).
--   docs/technical/03_db_schema.md Â§29 Deviation Q-DB-H (dual-layer privacy).
--   docs/agents/teams/01_SHARED_BRIEF.md Â§3.10 Q10 (gov flows).
--
-- DECISIONES TÃ‰CNICAS (founder Q-DB-H + Q-DB-A LOCKED 2026-05-06):
--
--   D1. sonar_govt_elections â€” FSM 4 states canonical:
--         'draft'    â€” admin gov drafting, NO visible pÃºblicamente.
--         'open'     â€” period activo voting (citizens pueden cast vote).
--         'closed'   â€” voting cerrado, count ongoing.
--         'finalized' â€” results publicados + winner declared.
--
--       Transitions: draft â†’ open â†’ closed â†’ finalized. Reverse NO permitido
--       (audit integrity). Backend Lead post-H1 enforce app-layer.
--
--   D2. election_kind ENUM:
--         'mayor' (alcalde gobierno servidor),
--         'cooperative_board' (junta cooperativa),
--         'referendum' (sÃ­/no proposiciones gov).
--
--   D3. **DUAL-LAYER PRIVACY (Q-DB-H)** â€” diseÃ±o crÃ­tico:
--
--       sonar_govt_votes (PÃšBLICO) â€” readable por cualquier citizen via
--       Government Console UI, sin ACE check. Almacena solo:
--         - voter_hash CHAR(64) â€” SHA-256(citizen_id || election_id || server_salt).
--         - candidate_id (voto al candidato X).
--         - cast_at timestamp.
--
--       Properties:
--         â–¸ Misma persona votando 2 veces en misma elecciÃ³n genera mismo hash
--           â†’ UNIQUE constraint detecta + rechaza.
--         â–¸ NO se puede inferir citizen_id desde voter_hash (server_salt secreto).
--         â–¸ Counts pÃºblicos por candidato accesibles (transparencia electoral).
--
--       sonar_govt_votes_audit (ADMIN-ONLY) â€” ACE gated `sonar.bank.govt.audit.full`
--       (Backend Lead post-H1 + Security Lead post-H2 enforce). Almacena raw:
--         - citizen_id CHAR(36) â€” voter real.
--         - election_id + candidate_id.
--         - cast_at + ip_address + actor_role.
--
--       Use cases:
--         â–¸ InvestigaciÃ³n impugnaciÃ³n electoral.
--         â–¸ DetecciÃ³n fraude (votos mÃºltiples desde mismo IP, etc.).
--         â–¸ AuditorÃ­a legal solo por Government con ACE.
--
--       INSERT atÃ³mico: Backend Lead post-H1 lib `Vote.Cast()` inserta en
--       AMBAS tablas en single transaction. Si fail â†’ rollback ambas.
--
--   D4. server_salt â€” secreto generado por DevOps Lead via convar
--       `sonar_bank_govt_vote_salt` (cadena random 64 chars). NO almacenar
--       en DB. Sin server_salt, attacker con dump DB no puede reverse-engineer
--       hashâ†’citizen_id.
--
--       NOTA crÃ­tica: server_salt MUST be stable across server restarts
--       (sino votos pre-restart no matchearÃ­an). DevOps Lead post-H4 documenta
--       almacenamiento secret en server.cfg.example + warning rotation.
--
--   D5. UNIQUE constraint en sonar_govt_votes (voter_hash, election_id) â€”
--       enforces "1 person 1 vote per election" sin exposure citizen_id.
--
--   D6. Triggers SIGNAL append-only sonar_govt_votes + sonar_govt_votes_audit
--       (Q-DB-F tier 1 pattern). Votos NO modificables post-cast.
--
--   D7. FK sonar_govt_election_candidates.election_id â†’ sonar_govt_elections(id)
--       ON DELETE CASCADE â€” borrar elecciÃ³n draft borra candidatos. Post-FSM
--       'open' app-layer rechaza DELETE elections.
--
--   D8. CHECK constraints simples (Q-DB-A â€” multi-col app-layer):
--         - sonar_govt_elections.opens_at < closes_at
--         - sonar_govt_election_candidates.display_order >= 0
--
--   D9. Index strategy:
--         votes (voter_hash, election_id) UNIQUE â€” enforce 1-vote rule.
--         votes (election_id, candidate_id) â€” count results queries.
--         votes_audit (citizen_id, election_id) â€” admin investigation.
--         votes_audit (election_id, cast_at DESC) â€” chronological audit.
-- ============================================================================


START TRANSACTION;


-- ----------------------------------------------------------------------------
-- 1. sonar_govt_elections â€” elecciones FSM 4-state
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_govt_elections (
  id                    CHAR(36)        NOT NULL COMMENT 'UUID v4 application-generated',

  election_kind         ENUM('mayor','cooperative_board','referendum') NOT NULL,
  title                 VARCHAR(192)    NOT NULL,
  description           TEXT            NULL,

  state                 ENUM('draft','open','closed','finalized') NOT NULL DEFAULT 'draft',

  scope_company_id      CHAR(36)        NULL COMMENT 'cooperative_board scope â€” FK Q-DB-E DEFERRED',

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
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE

  -- NO FK scope_company_id â†’ sonar_companies(id) â€” Q-DB-E DEFERRED issue #001.
  -- NO FK winner_candidate_id (self-ref deferred â€” set post-finalization).
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 2. sonar_govt_election_candidates â€” candidatos por elecciÃ³n
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_govt_election_candidates (
  id                    CHAR(36)        NOT NULL COMMENT 'UUID v4',
  election_id           CHAR(36)        NOT NULL,

  candidate_account_id  CHAR(36)        NULL COMMENT 'citizen candidato (NULL si referendum yes/no)',
  display_label         VARCHAR(128)    NOT NULL COMMENT 'p.e. "Yes" / "No" (referendum) o nombre candidato',
  manifesto             TEXT            NULL,

  display_order         INT UNSIGNED    NOT NULL DEFAULT 0,

  votes_count           INT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'cached count â€” refresh on-finalize por Backend Lead',

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
-- 3. sonar_govt_votes â€” votos PÃšBLICOS hasheados (privacy layer)
--
-- Lectura pÃºblica (Government Console UI). InserciÃ³n dual-atomic con
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
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes is append-only â€” UPDATE rejected';
END$$

CREATE TRIGGER trg_sonar_govt_votes_no_delete
  BEFORE DELETE ON sonar_govt_votes FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes is append-only â€” DELETE rejected';
END$$

DELIMITER ;


-- ----------------------------------------------------------------------------
-- 4. sonar_govt_votes_audit â€” votos RAW admin-only (ACE-gated)
--
-- Acceso ACE `sonar.bank.govt.audit.full` enforced por Backend Lead post-H1
-- + Security Lead post-H2. Tabla NO leÃ­ble por citizen normal.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_govt_votes_audit (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  election_id           CHAR(36)        NOT NULL,
  candidate_id          CHAR(36)        NOT NULL,

  citizen_id            CHAR(36)        NOT NULL COMMENT 'voter REAL â€” admin-only access',

  cast_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  ip_address            VARCHAR(45)     NULL COMMENT 'fraud detection â€” IPv4 or IPv6',
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
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes_audit is append-only â€” UPDATE rejected';
END$$

CREATE TRIGGER trg_sonar_govt_votes_audit_no_delete
  BEFORE DELETE ON sonar_govt_votes_audit FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes_audit is append-only â€” DELETE rejected';
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
--      - On UNIQUE constraint violation â†’ return error "already_voted".
--      - Append audit_ledger event 'vote_cast'.
--   2. Enforce ACE check `sonar.bank.govt.audit.full` on ANY query/read of
--      sonar_govt_votes_audit. NO citizen normal query path.
--
-- SECURITY LEAD post-H2:
--   1. Audit policy: queries sobre votes_audit deben generar audit_ledger entry
--      'audit_read_scope_full' con citizen_id consultado (meta-audit).
--   2. Test: simular dump DB sin server_salt â†’ verify hash NO reversible.
--
-- DEVOPS LEAD post-H4:
--   1. Generar server_salt 64-char random + persistir en server.cfg.example
--      con `setr sonar_bank_govt_vote_salt "<64-char-random>"`.
--   2. Documentar warning: NO rotar salt sin migration data â€” invalidarÃ­a
--      todos hashes existentes. Si rotation requerida, migration aditiva
--      con dual-hash window.
-- ============================================================================

-- ============================================================================
-- END 017_govt_elections_candidates_votes.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 018_bank_loans_credit_scores.sql
-- ============================================================================
-- ============================================================================
-- Migration: 018_bank_loans_credit_scores.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 2 tablas Tier 4 â€” Loans:
--     - sonar_bank_loans          â€” prÃ©stamos FSM 6-state.
--     - sonar_bank_credit_scores  â€” credit score por citizen (rolling history).
--
-- Dependencies: 002 + 003 (sonar_accounts + sonar_bank_accounts).
--
-- DECISIONES:
--   D1. Loans FSM 6-state: 'requested', 'approved', 'disbursed', 'active',
--       'paid_off', 'defaulted'. Reverse transitions PROHIBITED app-layer.
--   D2. amount_principal + amount_outstanding DECIMAL(14,2) (Q-DB-B fiat).
--   D3. interest_rate_pct DECIMAL(5,2) â€” anual %. Computation app-layer Backend.
--   D4. credit_scores rolling â€” N rows por citizen, last row = current snapshot.
--       PK auto + UNIQUE(citizen_id, computed_at) prevent duplicate computes.
--   D5. FK ON DELETE RESTRICT loans.borrower (auditorÃ­a legal) + ON DELETE
--       SET NULL credit_scores.computed_by (admin actor optional).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_loans (
  id                    CHAR(36)        NOT NULL,
  borrower_account_id   CHAR(36)        NOT NULL,
  bank_account_id       CHAR(36)        NOT NULL COMMENT 'cuenta destino disbursement + origen repayments',
  company_id            CHAR(36)        NULL COMMENT 'business loan â€” opaque Q-DB-E',

  state                 ENUM('requested','approved','disbursed','active','paid_off','defaulted') NOT NULL DEFAULT 'requested',
  loan_kind             ENUM('personal','business','mortgage','microloan') NOT NULL DEFAULT 'personal',

  amount_principal      DECIMAL(14,2)   NOT NULL,
  amount_outstanding    DECIMAL(14,2)   NOT NULL DEFAULT 0,
  interest_rate_pct     DECIMAL(5,2)    NOT NULL,
  term_months           SMALLINT UNSIGNED NOT NULL,
  monthly_payment       DECIMAL(14,2)   NULL COMMENT 'computed app-layer al transition disbursed',

  approved_by_account_id CHAR(36)       NULL,
  approved_at           INT UNSIGNED    NULL,
  disbursed_at          INT UNSIGNED    NULL,
  next_payment_due_at   INT UNSIGNED    NULL,
  paid_off_at           INT UNSIGNED    NULL,
  defaulted_at          INT UNSIGNED    NULL,

  reason_note           VARCHAR(255)    NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_bank_loans_borrower_state (borrower_account_id, state),
  KEY idx_sonar_bank_loans_state_due (state, next_payment_due_at),
  KEY idx_sonar_bank_loans_company (company_id),
  KEY idx_sonar_bank_loans_kind_state (loan_kind, state),

  CONSTRAINT fk_sonar_bank_loans_borrower
    FOREIGN KEY (borrower_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_loans_bank_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_loans_approved_by
    FOREIGN KEY (approved_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_loans_principal_positive CHECK (amount_principal > 0),
  CONSTRAINT chk_sonar_bank_loans_outstanding_nonneg CHECK (amount_outstanding >= 0),
  CONSTRAINT chk_sonar_bank_loans_rate_pct CHECK (interest_rate_pct >= 0 AND interest_rate_pct <= 100),
  CONSTRAINT chk_sonar_bank_loans_term_positive CHECK (term_months > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_credit_scores (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizen_id            CHAR(36)        NOT NULL,

  score                 SMALLINT UNSIGNED NOT NULL COMMENT '0-1000 escala canonical',
  rating                ENUM('excellent','good','fair','poor','no_history') NOT NULL,

  -- Componentes score (Q-DB-A simple float):
  payment_history_pct   DECIMAL(5,2)    NULL COMMENT '% pagos on-time',
  active_loans_count    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  defaulted_loans_count SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  total_outstanding     DECIMAL(14,2)   NOT NULL DEFAULT 0,

  computed_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  computed_by_account_id CHAR(36)       NULL COMMENT 'admin manual override (NULL = sistema cron)',
  computation_method    ENUM('automatic','manual_override') NOT NULL DEFAULT 'automatic',

  reason_note           VARCHAR(255)    NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_credit_scores_citizen_computed (citizen_id, computed_at),
  KEY idx_sonar_bank_credit_scores_citizen_score (citizen_id, computed_at DESC),
  KEY idx_sonar_bank_credit_scores_rating (rating, computed_at DESC),

  CONSTRAINT fk_sonar_bank_credit_scores_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_credit_scores_computed_by
    FOREIGN KEY (computed_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_credit_scores_score_range CHECK (score <= 1000),
  CONSTRAINT chk_sonar_bank_credit_scores_payment_pct CHECK (payment_history_pct IS NULL OR (payment_history_pct >= 0 AND payment_history_pct <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- END 018_bank_loans_credit_scores.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 019_bank_crypto_wallets.sql
-- ============================================================================
-- ============================================================================
-- Migration: 019_bank_crypto_wallets.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 2 tablas Tier 4 â€” Crypto wallets:
--     - sonar_bank_crypto_assets       â€” catÃ¡logo assets soportados (reference data).
--     - sonar_bank_crypto_wallets      â€” wallets per citizen + asset.
--     - sonar_bank_crypto_transactions â€” append-only transaction log.
--
-- Dependencies: 002 + 003.
--
-- DECISIONES (Q-DB-B BIGINT atomic + decimals):
--   D1. PolÃ­tica split atomic units / decimals â€” crypto NO sufre rounding
--       errors DECIMAL: amount_atomic BIGINT UNSIGNED + decimals stored en
--       sonar_bank_crypto_assets (e.g. 8 decimals BTC, 18 ETH).
--       Display = amount_atomic / 10^decimals (computaciÃ³n app-layer).
--   D2. Fiat exchange rate cached en transactions table (price_eur_atomic
--       BIGINT centavos EUR snapshot at tx time) â€” historial inmutable.
--   D3. UNIQUE(citizen_id, asset_id) â€” una wallet por citizen + asset (no
--       multi-wallet por simplicidad Phase A).
--   D4. transactions append-only triggers SIGNAL Q-DB-F tier 1.
--   D5. Bank account link FK â€” crypto buy/sell debit/credit fiat account.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_crypto_assets (
  id                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  symbol                VARCHAR(16)     NOT NULL COMMENT 'BTC, ETH, etc',
  display_name          VARCHAR(64)     NOT NULL,
  decimals              TINYINT UNSIGNED NOT NULL COMMENT 'BTC=8, ETH=18',
  enabled               BOOLEAN         NOT NULL DEFAULT TRUE,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_crypto_assets_symbol (symbol),
  KEY idx_sonar_bank_crypto_assets_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_crypto_wallets (
  id                    CHAR(36)        NOT NULL,
  citizen_id            CHAR(36)        NOT NULL,
  asset_id              SMALLINT UNSIGNED NOT NULL,

  balance_atomic        BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'amount_atomic = balance / 10^decimals',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_crypto_wallets_citizen_asset (citizen_id, asset_id),
  KEY idx_sonar_bank_crypto_wallets_asset (asset_id),

  CONSTRAINT fk_sonar_bank_crypto_wallets_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_crypto_wallets_asset
    FOREIGN KEY (asset_id) REFERENCES sonar_bank_crypto_assets(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_crypto_transactions (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  wallet_id             CHAR(36)        NOT NULL,
  citizen_id            CHAR(36)        NOT NULL,
  asset_id              SMALLINT UNSIGNED NOT NULL,

  tx_kind               ENUM('buy','sell','transfer_in','transfer_out','adjustment') NOT NULL,
  amount_atomic         BIGINT          NOT NULL COMMENT 'positivo=ingreso, negativo=salida',
  balance_atomic_after  BIGINT UNSIGNED NOT NULL COMMENT 'snapshot post-tx',

  -- Fiat-side snapshot (buy/sell):
  fiat_amount           DECIMAL(14,2)   NULL COMMENT 'fiat counterpart EUR',
  fiat_bank_account_id  CHAR(36)        NULL,
  related_movement_id   BIGINT UNSIGNED NULL COMMENT 'sonar_bank_movements link',
  exchange_rate_atomic  BIGINT UNSIGNED NULL COMMENT 'price snapshot (centavos EUR per atomic unit)',

  -- Idempotency + audit:
  request_nonce         CHAR(36)        NULL,
  related_audit_id      BIGINT UNSIGNED NULL,
  initiated_by_account_id CHAR(36)      NULL,

  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, occurred_at),
  KEY idx_sonar_bank_crypto_transactions_wallet (wallet_id, occurred_at DESC),
  KEY idx_sonar_bank_crypto_transactions_citizen_asset (citizen_id, asset_id, occurred_at DESC),
  KEY idx_sonar_bank_crypto_transactions_kind (tx_kind, occurred_at DESC),
  KEY idx_sonar_bank_crypto_transactions_nonce (request_nonce),

  CONSTRAINT fk_sonar_bank_crypto_transactions_wallet
    FOREIGN KEY (wallet_id) REFERENCES sonar_bank_crypto_wallets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_crypto_transactions_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_crypto_transactions_asset
    FOREIGN KEY (asset_id) REFERENCES sonar_bank_crypto_assets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_crypto_transactions_fiat_account
    FOREIGN KEY (fiat_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_crypto_transactions_initiator
    FOREIGN KEY (initiated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_crypto_transactions_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_crypto_transactions_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_crypto_transactions_no_update BEFORE UPDATE ON sonar_bank_crypto_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_crypto_transactions is append-only â€” UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_crypto_transactions_no_delete BEFORE DELETE ON sonar_bank_crypto_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_crypto_transactions is append-only â€” DELETE rejected'; END$$
DELIMITER ;

-- Seed reference data crypto assets canonical:
INSERT IGNORE INTO sonar_bank_crypto_assets (symbol, display_name, decimals, enabled) VALUES
  ('BTC',  'Bitcoin',  8,  TRUE),
  ('ETH',  'Ethereum', 18, TRUE),
  ('USDT', 'Tether',   6,  TRUE);

COMMIT;

-- ============================================================================
-- END 019_bank_crypto_wallets.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 020_bank_stocks_transactions_holdings.sql
-- ============================================================================
-- ============================================================================
-- Migration: 020_bank_stocks_transactions_holdings.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 3 tablas Tier 4 â€” Stocks (Q-DB-I hÃ­brido event-sourced + materialized):
--     - sonar_bank_stocks_assets       â€” catÃ¡logo stocks listados.
--     - sonar_bank_stocks_transactions â€” APPEND-ONLY event log (buy/sell/dividend).
--     - sonar_bank_stocks_holdings     â€” MATERIALIZED snapshot (computed view).
--
-- Dependencies: 002 + 003.
--
-- DECISIONES (Q-DB-I hÃ­brido):
--   D1. Modelo dual:
--       - transactions = source of truth (event-sourced, append-only).
--       - holdings = derived snapshot rebuildable via SUM(qty) por asset.
--       Backend Lead post-H1 lib `Stocks.RecomputeHoldings(citizen_id)` recalcula
--       holdings desde transactions. Cron rebuild full snapshot opcional.
--
--   D2. Cantidades como DECIMAL(20,8) â€” fractional shares soportados (Stocks
--       moderno permite fracciones). 8 decimals safe vs floating-point loss.
--
--   D3. price_per_share + total_amount cached en transactions â€” snapshot
--       precio histÃ³rico inmutable. Fiat side DECIMAL(14,2).
--
--   D4. holdings.last_recomputed_at â€” invalidation token. Stale > 5min â†’
--       Backend re-trigger recompute lazy.
--
--   D5. transactions append-only triggers SIGNAL Q-DB-F tier 1.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_stocks_assets (
  id                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ticker                VARCHAR(16)     NOT NULL,
  display_name          VARCHAR(128)    NOT NULL,
  exchange              VARCHAR(32)     NULL COMMENT 'simulado: NYSE, NASDAQ, etc',
  enabled               BOOLEAN         NOT NULL DEFAULT TRUE,

  current_price         DECIMAL(14,4)   NULL COMMENT 'cached price simulado',
  price_updated_at      INT UNSIGNED    NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_stocks_assets_ticker (ticker),
  KEY idx_sonar_bank_stocks_assets_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- APPEND-ONLY event-sourced log.
CREATE TABLE IF NOT EXISTS sonar_bank_stocks_transactions (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizen_id            CHAR(36)        NOT NULL,
  asset_id              SMALLINT UNSIGNED NOT NULL,
  fiat_bank_account_id  CHAR(36)        NOT NULL COMMENT 'cuenta debit/credit fiat',

  tx_kind               ENUM('buy','sell','dividend','split_in','split_out','adjustment') NOT NULL,
  qty                   DECIMAL(20,8)   NOT NULL COMMENT 'positivo=ingreso shares, negativo=salida',
  price_per_share       DECIMAL(14,4)   NOT NULL COMMENT 'snapshot precio at tx',
  total_amount          DECIMAL(14,2)   NOT NULL COMMENT 'qty * price_per_share fiat side',
  fee_amount            DECIMAL(14,2)   NOT NULL DEFAULT 0,

  request_nonce         CHAR(36)        NULL,
  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,

  initiated_by_account_id CHAR(36)      NULL,
  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, occurred_at),
  KEY idx_sonar_bank_stocks_tx_citizen_asset (citizen_id, asset_id, occurred_at DESC),
  KEY idx_sonar_bank_stocks_tx_kind (tx_kind, occurred_at DESC),
  KEY idx_sonar_bank_stocks_tx_nonce (request_nonce),
  KEY idx_sonar_bank_stocks_tx_account (fiat_bank_account_id, occurred_at DESC),

  CONSTRAINT fk_sonar_bank_stocks_tx_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_stocks_tx_asset
    FOREIGN KEY (asset_id) REFERENCES sonar_bank_stocks_assets(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_stocks_tx_account
    FOREIGN KEY (fiat_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_stocks_tx_initiator
    FOREIGN KEY (initiated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_stocks_tx_price_nonneg CHECK (price_per_share >= 0),
  CONSTRAINT chk_sonar_bank_stocks_tx_fee_nonneg CHECK (fee_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_stocks_tx_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_stocks_tx_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_stocks_tx_no_update BEFORE UPDATE ON sonar_bank_stocks_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_stocks_transactions is append-only â€” UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_stocks_tx_no_delete BEFORE DELETE ON sonar_bank_stocks_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_stocks_transactions is append-only â€” DELETE rejected'; END$$
DELIMITER ;


-- MATERIALIZED snapshot â€” current holdings per citizen + asset.
CREATE TABLE IF NOT EXISTS sonar_bank_stocks_holdings (
  id                    CHAR(36)        NOT NULL,
  citizen_id            CHAR(36)        NOT NULL,
  asset_id              SMALLINT UNSIGNED NOT NULL,

  qty_total             DECIMAL(20,8)   NOT NULL DEFAULT 0,
  avg_cost_basis        DECIMAL(14,4)   NULL COMMENT 'precio promedio compra (FIFO/avg method app-layer)',

  last_recomputed_at    INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) COMMENT 'staleness invalidation',
  last_tx_id            BIGINT UNSIGNED NULL COMMENT 'last transaction reflected en este snapshot',

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_stocks_holdings_citizen_asset (citizen_id, asset_id),
  KEY idx_sonar_bank_stocks_holdings_citizen (citizen_id),
  KEY idx_sonar_bank_stocks_holdings_asset (asset_id),

  CONSTRAINT fk_sonar_bank_stocks_holdings_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_stocks_holdings_asset
    FOREIGN KEY (asset_id) REFERENCES sonar_bank_stocks_assets(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- END 020_bank_stocks_transactions_holdings.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 021_bank_recurring_payments.sql
-- ============================================================================
-- ============================================================================
-- Migration: 021_bank_recurring_payments.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea tabla Tier 4 â€” Recurring payments (suscripciones, alquiler, utilities).
--
-- Dependencies: 002 + 003.
--
-- DECISIONES:
--   D1. FSM 4-state: 'active', 'paused', 'cancelled', 'completed'.
--   D2. interval_kind ENUM canonical (daily/weekly/monthly/yearly).
--   D3. next_charge_at INT UNSIGNED â€” cron Backend Lead post-H1 query
--       WHERE state='active' AND next_charge_at <= UNIX_TIMESTAMP() ORDER ASC.
--   D4. Companies opaque (Q-DB-E) â€” payee_company_id sin FK.
--   D5. last_charge_status ENUM tracking failure mode (insufficient_funds, etc).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_recurring_payments (
  id                    CHAR(36)        NOT NULL,

  payer_account_id      CHAR(36)        NOT NULL,
  payer_bank_account_id CHAR(36)        NOT NULL COMMENT 'cuenta debit',

  payee_kind            ENUM('citizen','company','government') NOT NULL,
  payee_account_id      CHAR(36)        NULL COMMENT 'NULL si payee_kind != citizen',
  payee_company_id      CHAR(36)        NULL COMMENT 'opaque Q-DB-E',
  payee_iban            VARCHAR(20)     NOT NULL COMMENT 'destination always set',

  state                 ENUM('active','paused','cancelled','completed') NOT NULL DEFAULT 'active',
  payment_kind          ENUM('subscription','rent','utility','loan_repayment','custom') NOT NULL DEFAULT 'subscription',

  amount                DECIMAL(14,2)   NOT NULL,
  currency              CHAR(3)         NOT NULL DEFAULT 'EUR',
  interval_kind         ENUM('daily','weekly','monthly','yearly') NOT NULL,
  interval_count        SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'e.g. interval_kind=monthly + count=3 = trimestral',

  description           VARCHAR(255)    NULL,

  starts_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  ends_at               INT UNSIGNED    NULL COMMENT 'NULL = indefinido',

  next_charge_at        INT UNSIGNED    NOT NULL,
  last_charged_at       INT UNSIGNED    NULL,
  last_charge_status    ENUM('success','insufficient_funds','frozen','error') NULL,

  total_charges_count   INT UNSIGNED    NOT NULL DEFAULT 0,
  consecutive_failures  TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'auto-pause si > 3',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  cancelled_at          INT UNSIGNED    NULL,

  PRIMARY KEY (id),
  KEY idx_sonar_bank_recurring_payer (payer_account_id, state),
  KEY idx_sonar_bank_recurring_state_next (state, next_charge_at) COMMENT 'cron hot path',
  KEY idx_sonar_bank_recurring_payee_iban (payee_iban),
  KEY idx_sonar_bank_recurring_payee_company (payee_company_id),

  CONSTRAINT fk_sonar_bank_recurring_payer
    FOREIGN KEY (payer_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_recurring_payer_bank
    FOREIGN KEY (payer_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_recurring_payee_account
    FOREIGN KEY (payee_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_recurring_amount_positive CHECK (amount > 0),
  CONSTRAINT chk_sonar_bank_recurring_interval_count CHECK (interval_count > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- END 021_bank_recurring_payments.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 022_bank_atm_minigame_attempts.sql
-- ============================================================================
-- ============================================================================
-- Migration: 022_bank_atm_minigame_attempts.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea tabla Tier 4 â€” ATM minigame attempts log (anti-abuse + analytics).
--
-- Dependencies: 002 + 003.
--
-- DECISIONES:
--   D1. Append-only log (triggers SIGNAL Q-DB-F tier 1) â€” fraud detection.
--   D2. result ENUM: 'success' / 'failure' / 'timeout'.
--   D3. Rate limiting app-layer Backend lib (e.g. max 3 fails / 10min lockout).
--   D4. ip_address VARCHAR(45) IPv4/IPv6 â€” fraud pattern detection geolocal.
--   D5. amount_attempted DECIMAL(14,2) si Ã©xito â†’ genera movement separate.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_atm_minigame_attempts (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizen_id            CHAR(36)        NOT NULL,
  bank_account_id       CHAR(36)        NOT NULL,

  attempt_kind          ENUM('withdraw','deposit') NOT NULL DEFAULT 'withdraw',
  amount_attempted      DECIMAL(14,2)   NOT NULL,
  result                ENUM('success','failure','timeout') NOT NULL,
  failure_reason        VARCHAR(64)     NULL COMMENT 'wrong_pin, wrong_pattern, rate_limited, etc',

  duration_ms           INT UNSIGNED    NULL COMMENT 'tiempo respuesta minigame',
  ip_address            VARCHAR(45)     NULL,
  atm_location          VARCHAR(64)     NULL COMMENT 'ATM identifier in-game',

  related_movement_id   BIGINT UNSIGNED NULL COMMENT 'NULL si result != success',
  related_audit_id      BIGINT UNSIGNED NULL,

  attempted_at          INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, attempted_at),
  KEY idx_sonar_bank_atm_citizen_attempted (citizen_id, attempted_at DESC),
  KEY idx_sonar_bank_atm_account_attempted (bank_account_id, attempted_at DESC),
  KEY idx_sonar_bank_atm_result_attempted (result, attempted_at DESC) COMMENT 'fraud detection failures',
  KEY idx_sonar_bank_atm_ip_attempted (ip_address, attempted_at DESC),

  CONSTRAINT fk_sonar_bank_atm_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_atm_bank_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_atm_amount_positive CHECK (amount_attempted > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_atm_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_atm_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_atm_no_update BEFORE UPDATE ON sonar_bank_atm_minigame_attempts FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_atm_minigame_attempts is append-only â€” UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_atm_no_delete BEFORE DELETE ON sonar_bank_atm_minigame_attempts FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_atm_minigame_attempts is append-only â€” DELETE rejected'; END$$
DELIMITER ;

COMMIT;

-- ============================================================================
-- END 022_bank_atm_minigame_attempts.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 023_bank_physical_cards.sql
-- ============================================================================
-- ============================================================================
-- Migration: 023_bank_physical_cards.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea tabla Tier 4 â€” Physical cards (tokens linked to bank_accounts).
--
-- Dependencies: 002 + 003.
--
-- DECISIONES:
--   D1. card_token CHAR(64) â€” opaque token (NO real PAN). Display PAN solo
--       last_4_digits VARCHAR(4). Backend Lead lib generate token + last4.
--   D2. FSM 4-state: 'active', 'frozen', 'expired', 'lost'.
--   D3. PIN encrypted/hashed: pin_hash CHAR(64) SHA-256(pin || card_token salt).
--       Backend Lead post-H1 enforce hash + verify. NO plain PIN en DB.
--   D4. daily_limit DECIMAL(14,2) â€” overrides bank_account.daily_limit_out
--       cuando card-based txn.
--   D5. UNIQUE(card_token) â€” token unique global. UNIQUE(bank_account_id) NO
--       â€” citizen puede tener N cards mismo account.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_physical_cards (
  id                    CHAR(36)        NOT NULL,
  bank_account_id       CHAR(36)        NOT NULL,
  holder_account_id     CHAR(36)        NOT NULL COMMENT 'citizen titular card',

  card_token            CHAR(64)        NOT NULL COMMENT 'opaque token Backend-generated',
  last_4_digits         CHAR(4)         NOT NULL COMMENT 'display only',
  card_kind             ENUM('debit','credit','prepaid') NOT NULL DEFAULT 'debit',

  state                 ENUM('active','frozen','expired','lost') NOT NULL DEFAULT 'active',

  pin_hash              CHAR(64)        NULL COMMENT 'SHA-256(pin || token_salt) â€” Backend lib enforce',
  pin_salt              CHAR(32)        NULL,
  pin_attempts_failed   TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'auto-freeze si > 3',

  daily_limit           DECIMAL(14,2)   NULL COMMENT 'NULL = inherit bank_account.daily_limit_out',
  daily_used_today      DECIMAL(14,2)   NOT NULL DEFAULT 0,
  daily_reset_at        INT UNSIGNED    NULL,

  monthly_limit         DECIMAL(14,2)   NULL COMMENT 'NULL = no monthly cap (mig 038)',
  monthly_used          DECIMAL(14,2)   NOT NULL DEFAULT 0,
  monthly_reset_at      INT UNSIGNED    NULL,

  issued_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  expires_at            INT UNSIGNED    NULL,
  frozen_at             INT UNSIGNED    NULL,
  frozen_reason         VARCHAR(128)    NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_physical_cards_token (card_token),
  KEY idx_sonar_bank_physical_cards_account (bank_account_id, state),
  KEY idx_sonar_bank_physical_cards_holder (holder_account_id, state),
  KEY idx_sonar_bank_physical_cards_state_expires (state, expires_at),

  CONSTRAINT fk_sonar_bank_physical_cards_bank_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_physical_cards_holder
    FOREIGN KEY (holder_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_physical_cards_daily_limit_nonneg CHECK (daily_limit IS NULL OR daily_limit >= 0),
  CONSTRAINT chk_sonar_bank_physical_cards_daily_used_nonneg CHECK (daily_used_today >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- END 023_bank_physical_cards.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 024_bank_loyalty_points.sql
-- ============================================================================
-- ============================================================================
-- Migration: 024_bank_loyalty_points.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 2 tablas Tier 4 â€” Loyalty program:
--     - sonar_bank_loyalty_balances     â€” current points snapshot per citizen.
--     - sonar_bank_loyalty_transactions â€” append-only earn/redeem log.
--
-- Dependencies: 002.
--
-- DECISIONES:
--   D1. Points como INT UNSIGNED (no fractional). 1 point = 0.01 EUR cashback.
--   D2. Earn/redeem append-only triggers SIGNAL (Q-DB-F).
--   D3. balance materialized â€” Backend lib increment/decrement on tx.
--       Recompute lazy desde transactions (event-sourced fallback).
--   D4. tier ENUM 'bronze','silver','gold','platinum' â€” based on lifetime_earned.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_loyalty_balances (
  citizen_id            CHAR(36)        NOT NULL,
  current_points        INT UNSIGNED    NOT NULL DEFAULT 0,
  lifetime_earned       INT UNSIGNED    NOT NULL DEFAULT 0,
  lifetime_redeemed     INT UNSIGNED    NOT NULL DEFAULT 0,
  tier                  ENUM('bronze','silver','gold','platinum') NOT NULL DEFAULT 'bronze',

  last_activity_at      INT UNSIGNED    NULL,
  last_recomputed_at    INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (citizen_id),
  KEY idx_sonar_bank_loyalty_balances_tier (tier),

  CONSTRAINT fk_sonar_bank_loyalty_balances_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_loyalty_transactions (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizen_id            CHAR(36)        NOT NULL,

  tx_kind               ENUM('earn_purchase','earn_referral','earn_bonus','redeem_cashback','redeem_giftcard','adjustment_admin','expiration') NOT NULL,
  points_delta          INT             NOT NULL COMMENT 'positivo=earn, negativo=redeem',
  balance_after         INT UNSIGNED    NOT NULL,

  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,
  reason_note           VARCHAR(255)    NULL,
  initiated_by_account_id CHAR(36)      NULL,

  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, occurred_at),
  KEY idx_sonar_bank_loyalty_tx_citizen (citizen_id, occurred_at DESC),
  KEY idx_sonar_bank_loyalty_tx_kind (tx_kind, occurred_at DESC),

  CONSTRAINT fk_sonar_bank_loyalty_tx_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_loyalty_tx_initiator
    FOREIGN KEY (initiated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_loyalty_tx_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_loyalty_tx_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_loyalty_tx_no_update BEFORE UPDATE ON sonar_bank_loyalty_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_loyalty_transactions is append-only â€” UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_loyalty_tx_no_delete BEFORE DELETE ON sonar_bank_loyalty_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_loyalty_transactions is append-only â€” DELETE rejected'; END$$
DELIMITER ;

COMMIT;

-- ============================================================================
-- END 024_bank_loyalty_points.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 025_bank_round_ups.sql
-- ============================================================================
-- ============================================================================
-- Migration: 025_bank_round_ups.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 2 tablas Tier 4 â€” Round-ups (savings micro-redondeo):
--     - sonar_bank_round_up_configs     â€” settings per citizen (opt-in + dest).
--     - sonar_bank_round_up_transactions â€” append-only round-up log.
--
-- Dependencies: 002 + 003.
--
-- DECISIONES:
--   D1. config 1:1 citizen â€” UNIQUE PRIMARY (citizen_id).
--   D2. multiplier permite 1x, 2x, 5x boost â€” incentiva savings.
--   D3. tx append-only triggers SIGNAL Q-DB-F.
--   D4. trigger_movement_id link al movement original que disparÃ³ el round-up.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_round_up_configs (
  citizen_id            CHAR(36)        NOT NULL,
  source_bank_account_id CHAR(36)       NOT NULL COMMENT 'cuenta debit redondeo',
  destination_bank_account_id CHAR(36)  NOT NULL COMMENT 'cuenta savings credit',

  enabled               BOOLEAN         NOT NULL DEFAULT TRUE,
  multiplier            TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1x, 2x, 5x boost',
  round_up_to           DECIMAL(6,2)    NOT NULL DEFAULT 1.00 COMMENT 'redondear hacia mÃºltiplo (e.g. 1.00 = nearest euro)',

  total_rounded_eur     DECIMAL(14,2)   NOT NULL DEFAULT 0 COMMENT 'lifetime total saved',

  enabled_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (citizen_id),

  CONSTRAINT fk_sonar_bank_round_up_configs_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_round_up_configs_source
    FOREIGN KEY (source_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_round_up_configs_destination
    FOREIGN KEY (destination_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_round_up_multiplier CHECK (multiplier >= 1 AND multiplier <= 10),
  CONSTRAINT chk_sonar_bank_round_up_to_positive CHECK (round_up_to > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_round_up_transactions (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  citizen_id            CHAR(36)        NOT NULL,

  trigger_movement_id   BIGINT UNSIGNED NOT NULL COMMENT 'movement original que disparÃ³ round-up',
  original_amount       DECIMAL(14,2)   NOT NULL,
  rounded_to            DECIMAL(14,2)   NOT NULL,
  round_up_amount       DECIMAL(14,2)   NOT NULL COMMENT 'amount transferred to savings (incl multiplier)',
  multiplier_applied    TINYINT UNSIGNED NOT NULL,

  savings_movement_id   BIGINT UNSIGNED NULL COMMENT 'movement crÃ©dito a savings account',

  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, occurred_at),
  KEY idx_sonar_bank_round_up_tx_citizen (citizen_id, occurred_at DESC),
  KEY idx_sonar_bank_round_up_tx_trigger (trigger_movement_id),

  CONSTRAINT fk_sonar_bank_round_up_tx_citizen
    FOREIGN KEY (citizen_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_round_up_tx_amount_positive CHECK (round_up_amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_round_up_tx_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_round_up_tx_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_round_up_tx_no_update BEFORE UPDATE ON sonar_bank_round_up_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_round_up_transactions is append-only â€” UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_round_up_tx_no_delete BEFORE DELETE ON sonar_bank_round_up_transactions FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_round_up_transactions is append-only â€” DELETE rejected'; END$$
DELIMITER ;

COMMIT;

-- ============================================================================
-- END 025_bank_round_ups.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 026_bank_business_treasuries.sql
-- ============================================================================
-- ============================================================================
-- Migration: 026_bank_business_treasuries.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea 2 tablas Empresas extends â€” multi-signer business treasuries:
--     - sonar_bank_business_treasuries        â€” config policy per company.
--     - sonar_bank_business_treasury_signers  â€” N firmantes con role + signing_threshold.
--     - sonar_bank_business_treasury_approvals â€” pending approvals (m-of-n approval flow).
--
-- Dependencies: 002 + 003.
--
-- DECISIONES (Q-DB-E opaque company_id):
--   D1. company_id CHAR(36) opaque NO FK â€” Issue #001.
--   D2. signing_threshold = N firmantes mÃ­nimos required para approve TX
--       above amount_threshold. UI Tablet permite drag/configure.
--   D3. signers role canonical: 'owner', 'manager', 'employee_authorized'.
--   D4. approvals FSM: 'pending', 'approved', 'rejected', 'expired'.
--   D5. Backend lib post-H1 enforce m-of-n logic (count approvals con state='approved'
--       >= signing_threshold).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_business_treasuries (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL COMMENT 'opaque Q-DB-E',
  bank_account_id       CHAR(36)        NOT NULL COMMENT 'treasury account',

  signing_threshold     TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'm-of-n minimum signers',
  amount_threshold      DECIMAL(14,2)   NOT NULL DEFAULT 0 COMMENT 'tx > threshold requires multi-sign',

  policy_note           VARCHAR(255)    NULL,

  created_by_account_id CHAR(36)        NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_business_treasuries_company (company_id),
  UNIQUE KEY uq_sonar_bank_business_treasuries_account (bank_account_id),

  CONSTRAINT fk_sonar_bank_business_treasuries_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_treasuries_creator
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_business_treasuries_threshold CHECK (signing_threshold >= 1 AND signing_threshold <= 20),
  CONSTRAINT chk_sonar_bank_business_treasuries_amount CHECK (amount_threshold >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_business_treasury_signers (
  id                    CHAR(36)        NOT NULL,
  treasury_id           CHAR(36)        NOT NULL,
  signer_account_id     CHAR(36)        NOT NULL,

  signer_role           ENUM('owner','manager','employee_authorized') NOT NULL DEFAULT 'manager',
  active                BOOLEAN         NOT NULL DEFAULT TRUE,

  added_at              INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  removed_at            INT UNSIGNED    NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_business_treasury_signers_treasury_signer (treasury_id, signer_account_id, active),
  KEY idx_sonar_bank_business_treasury_signers_signer_active (signer_account_id, active),

  CONSTRAINT fk_sonar_bank_business_treasury_signers_treasury
    FOREIGN KEY (treasury_id) REFERENCES sonar_bank_business_treasuries(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_treasury_signers_signer
    FOREIGN KEY (signer_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS sonar_bank_business_treasury_approvals (
  id                    CHAR(36)        NOT NULL,
  treasury_id           CHAR(36)        NOT NULL,

  -- Operation pending approval:
  operation_kind        ENUM('transfer_out','escrow_create','recurring_setup','large_withdraw','custom') NOT NULL,
  operation_payload     JSON            NOT NULL COMMENT 'serialized op params Backend lib parses',
  operation_amount      DECIMAL(14,2)   NOT NULL,
  operation_target_iban VARCHAR(20)     NULL,
  operation_description VARCHAR(255)    NULL,

  state                 ENUM('pending','approved','rejected','expired','executed') NOT NULL DEFAULT 'pending',

  signers_required      TINYINT UNSIGNED NOT NULL,
  signers_approved      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  approvals_json        JSON            NULL COMMENT '[{signer_account_id, decision, decided_at, note}]',

  initiated_by_account_id CHAR(36)      NOT NULL,
  initiated_at          INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  expires_at            INT UNSIGNED    NOT NULL COMMENT '24-72h TTL configurable',
  finalized_at          INT UNSIGNED    NULL,

  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,

  PRIMARY KEY (id),
  KEY idx_sonar_bank_business_approvals_treasury_state (treasury_id, state, expires_at),
  KEY idx_sonar_bank_business_approvals_state_expires (state, expires_at) COMMENT 'cron expire pending',
  KEY idx_sonar_bank_business_approvals_initiator (initiated_by_account_id, initiated_at DESC),

  CONSTRAINT fk_sonar_bank_business_approvals_treasury
    FOREIGN KEY (treasury_id) REFERENCES sonar_bank_business_treasuries(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_approvals_initiator
    FOREIGN KEY (initiated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_business_approvals_amount_positive CHECK (operation_amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- END 026_bank_business_treasuries.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 027_bank_escrow_releases.sql
-- ============================================================================
-- ============================================================================
-- Migration: 027_bank_escrow_releases.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea tabla Empresas extends â€” escrow partial release log + ALTER
--   sonar_escrows ADD release_log_count.
--
-- Dependencies: 002 + 003 + 006 (sonar_escrows existe).
--
-- DECISIONES (Q12 escrow FSM 6-states):
--   D1. sonar_escrows existing FSM extends â€” partial releases permiten
--       liberar tramos del escrow (e.g. milestones contractuales).
--   D2. release_log append-only triggers SIGNAL Q-DB-F.
--   D3. ALTER sonar_escrows ADD release_log_count TINYINT UNSIGNED denormalized
--       counter (avoid COUNT(*) hot path on UI escrow detail page).
--   D4. Idempotency check antes de ALTER (re-apply safe).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_escrow_releases (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  escrow_id             CHAR(36)        NOT NULL,

  release_kind          ENUM('milestone','partial','full','refund_partial') NOT NULL,
  amount_released       DECIMAL(14,2)   NOT NULL,
  amount_remaining      DECIMAL(14,2)   NOT NULL COMMENT 'snapshot post-release',

  released_by_account_id CHAR(36)       NULL COMMENT 'admin or counterparty triggering release',
  released_to_iban      VARCHAR(20)     NOT NULL,
  reason_note           VARCHAR(255)    NULL,
  milestone_label       VARCHAR(64)     NULL COMMENT 'e.g. "milestone_2_delivery"',

  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,
  request_nonce         CHAR(36)        NULL,

  released_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, released_at),
  KEY idx_sonar_bank_escrow_releases_escrow (escrow_id, released_at DESC),
  KEY idx_sonar_bank_escrow_releases_kind (release_kind, released_at DESC),
  KEY idx_sonar_bank_escrow_releases_actor (released_by_account_id, released_at DESC),
  KEY idx_sonar_bank_escrow_releases_nonce (request_nonce),

  CONSTRAINT fk_sonar_bank_escrow_releases_actor
    FOREIGN KEY (released_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_escrow_releases_amount_positive CHECK (amount_released > 0),
  CONSTRAINT chk_sonar_bank_escrow_releases_remaining_nonneg CHECK (amount_remaining >= 0)

  -- NO FK escrow_id â†’ sonar_escrows(id) directo â€” escrow puede tener estado
  -- 'closed' permanente, releases sobreviven (audit retention legal).
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_sonar_bank_escrow_releases_no_update;
DROP TRIGGER IF EXISTS trg_sonar_bank_escrow_releases_no_delete;

DELIMITER $$
CREATE TRIGGER trg_sonar_bank_escrow_releases_no_update BEFORE UPDATE ON sonar_bank_escrow_releases FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_escrow_releases is append-only â€” UPDATE rejected'; END$$
CREATE TRIGGER trg_sonar_bank_escrow_releases_no_delete BEFORE DELETE ON sonar_bank_escrow_releases FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_escrow_releases is append-only â€” DELETE rejected'; END$$
DELIMITER ;


-- ALTER sonar_escrows ADD release_log_count (idempotent).
DROP PROCEDURE IF EXISTS sp_apply_027_escrow_release_count;

DELIMITER $$
CREATE PROCEDURE sp_apply_027_escrow_release_count()
BEGIN
  DECLARE col_count INT DEFAULT 0;
  SELECT COUNT(*) INTO col_count
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_escrows'
    AND COLUMN_NAME = 'release_log_count';

  IF col_count = 0 THEN
    ALTER TABLE sonar_escrows
      ADD COLUMN release_log_count TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'denormalized count releases (FSM 6-states extends Q12)';
  END IF;
END$$
DELIMITER ;

CALL sp_apply_027_escrow_release_count();
DROP PROCEDURE sp_apply_027_escrow_release_count;

COMMIT;

-- ============================================================================
-- END 027_bank_escrow_releases.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 028_bank_idempotency_keys.sql
-- ============================================================================
-- ============================================================================
-- Migration: 028_bank_idempotency_keys.sql
-- Author: DB Lead (Cascade Sonnet 4.6) + yaboula
-- Date: 2026-05-06 (BANK-DB.3)
-- Description:
--   Crea tabla central Idempotency keys â€” vital para ReconciliaciÃ³n Activa
--   Backend Lead post-H1.
--
-- Dependencies: 002.
--
-- DECISIONES (founder mandate Idempotency Keys):
--   D1. Tabla central idempotency keys cross-domain (transfers + recurring +
--       crypto + stocks + escrow + business approvals). Cada operaciÃ³n
--       atomic genera key UUID + Backend lib check antes commit.
--
--   D2. response_payload JSON â€” almacena resultado completed para retry-safe.
--       Si client retry mismo idempotency_key, Backend devuelve cached response
--       sin re-ejecutar operaciÃ³n.
--
--   D3. TTL 7 days (mandato founder) â€” cron cleanup DevOps Lead post-H4
--       DELETE WHERE expires_at < UNIX_TIMESTAMP() in batches.
--
--   D4. UNIQUE(idempotency_key) â€” Backend lib INSERT con ON DUPLICATE KEY
--       UPDATE no-op + check existing state.
--
--   D5. state ENUM tracking ciclo:
--       - 'pending'  : operation in-flight (locked).
--       - 'completed': operation done, response cached.
--       - 'failed'   : operation failed, retry permitido (cleanup mÃ¡s rÃ¡pido).
--
--   D6. domain ENUM canonical â€” clasifica origen para audit + analytics.
--
--   D7. NO partitioning Phase A â€” volumen TBD post-launch.
--       Si > 500K rows â†’ migration v0.4 partitioning RANGE(expires_at).
--
--   D8. Lock optimistic via INSERT IGNORE â€” si race condition, segundo
--       client recibe duplicate â†’ check state existing â†’ wait or return cached.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_idempotency_keys (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  idempotency_key       CHAR(64)        NOT NULL COMMENT 'client-provided UUID/hash unique per logical op',
  domain                ENUM('transfer','recurring','crypto_buy','crypto_sell','stocks_buy','stocks_sell','escrow_create','escrow_release','loan_disbursement','loan_repayment','business_approval','tax_payment','subsidy_issue','custom') NOT NULL,

  state                 ENUM('pending','completed','failed') NOT NULL DEFAULT 'pending',

  -- Identidad solicitante:
  initiated_by_account_id CHAR(36)      NULL,
  bank_account_id       CHAR(36)        NULL COMMENT 'cuenta principal involucrada (opcional)',

  -- Snapshot params operaciÃ³n:
  request_payload       JSON            NULL COMMENT 'params operaciÃ³n serializados',

  -- Snapshot response (post-completion):
  response_payload      JSON            NULL COMMENT 'resultado cached retry-safe',
  response_code         VARCHAR(32)     NULL COMMENT 'success / insufficient_funds / etc',

  -- Linking:
  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,
  related_correlation_id CHAR(36)       NULL COMMENT 'CP2 correlation-id Backend Lead',

  -- Timing:
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  completed_at          INT UNSIGNED    NULL,
  expires_at            INT UNSIGNED    NOT NULL COMMENT 'TTL 7 days canonical',

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_idempotency_keys_key (idempotency_key),
  KEY idx_sonar_bank_idempotency_keys_state_expires (state, expires_at) COMMENT 'cron cleanup hot path',
  KEY idx_sonar_bank_idempotency_keys_domain_state (domain, state),
  KEY idx_sonar_bank_idempotency_keys_account (bank_account_id, created_at DESC),
  KEY idx_sonar_bank_idempotency_keys_initiator (initiated_by_account_id, created_at DESC),
  KEY idx_sonar_bank_idempotency_keys_correlation (related_correlation_id),

  CONSTRAINT fk_sonar_bank_idempotency_keys_initiator
    FOREIGN KEY (initiated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_idempotency_keys_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;


-- ============================================================================
-- POST-INSTALL Backend Lead post-H1 actions:
--   1. Implement IdempotencyKeys.Lock(key, domain, payload) lib:
--      - INSERT new row state='pending' + expires_at = NOW + 7d.
--      - On UNIQUE conflict â†’ SELECT existing row + return state.
--      - If existing.state='completed' â†’ return cached response_payload.
--      - If existing.state='pending' AND created_at < 60s â†’ wait/retry.
--      - If existing.state='pending' AND created_at > 60s â†’ assume stuck, mark failed.
--   2. Implement IdempotencyKeys.Complete(key, response, movement_id) post-success.
--   3. Implement IdempotencyKeys.Fail(key, error_code) post-error.
--
-- POST-INSTALL DevOps Lead post-H4 actions:
--   1. Cron daily cleanup:
--      DELETE FROM sonar_bank_idempotency_keys
--      WHERE expires_at < UNIX_TIMESTAMP() LIMIT 10000;
--      Repeat hasta 0 rows (batch).
-- ============================================================================

-- ============================================================================
-- END 028_bank_idempotency_keys.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 029_company_registry.sql
-- ============================================================================
-- ============================================================================
-- Migration: 029_company_registry.sql
-- Author: DB Lead (Cascade) + yaboula
-- Date: 2026-05-09 (BANK-DB.AMEND.1)
-- Description:
--   Adds the minimum company registry required by Issue #002 for GOVT and
--   Business Cockpit mock-to-real integration.
--
-- Dependencies:
--   - 002_foundation_tables.sql (sonar_accounts exists).
--   - 003_bank_schema.sql (legacy opaque company_id references exist).
--
-- Amendment scope:
--   - Resolves Issue #001 at registry-table level by creating sonar_companies.
--   - Keeps FK promotion from legacy bank tables deferred until an orphan audit
--     runs against existing opaque company_id values.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_companies (
  id                    CHAR(36)        NOT NULL,
  name                  VARCHAR(96)     NOT NULL,
  sector                ENUM('farming','milling','bakery','retail','logistics','services','finance','other') NOT NULL DEFAULT 'other',
  status                ENUM('active','frozen','liquidating','dissolved') NOT NULL DEFAULT 'active',
  founded_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  created_by_account_id CHAR(36)        NULL,

  employee_count_cached INT UNSIGNED    NOT NULL DEFAULT 0,
  director_count_cached INT UNSIGNED    NOT NULL DEFAULT 0,
  metadata              JSON            NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_companies_status_sector (status, sector),
  KEY idx_sonar_companies_name (name),
  KEY idx_sonar_companies_founded (founded_at),
  KEY idx_sonar_companies_created_by (created_by_account_id),

  CONSTRAINT fk_sonar_companies_created_by
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_companies_employee_count CHECK (employee_count_cached >= 0),
  CONSTRAINT chk_sonar_companies_director_count CHECK (director_count_cached >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sonar_company_members (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,
  account_id            CHAR(36)        NOT NULL,

  role                  ENUM('founder','co-founder','director','manager','employee') NOT NULL DEFAULT 'employee',
  active                BOOLEAN         NOT NULL DEFAULT TRUE,
  joined_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  left_at               INT UNSIGNED    NULL,

  department            VARCHAR(64)     NULL,
  title                 VARCHAR(64)     NULL,
  salary_amount         DECIMAL(14,2)   NULL,
  metadata              JSON            NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_company_members_company_account_active (company_id, account_id, active),
  KEY idx_sonar_company_members_account_active (account_id, active),
  KEY idx_sonar_company_members_company_role (company_id, role, active),
  KEY idx_sonar_company_members_company_joined (company_id, joined_at DESC),

  CONSTRAINT fk_sonar_company_members_company
    FOREIGN KEY (company_id) REFERENCES sonar_companies(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_company_members_account
    FOREIGN KEY (account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_company_members_salary_nonneg CHECK (salary_amount IS NULL OR salary_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- Backend Lead follow-up:
--   1. Create CompanyRegistry.Exists(company_id) and CompanyRegistry.List/Detail.
--   2. Maintain employee_count_cached and director_count_cached after member
--      changes, or recompute nightly before enabling large GOVT lists.
--   3. Run orphan audit before FK promotion from legacy opaque company_id columns.
-- ============================================================================

-- ============================================================================
-- END 029_company_registry.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 030_subsidy_programs.sql
-- ============================================================================
-- ============================================================================
-- Migration: 030_subsidy_programs.sql
-- Author: DB Lead (Cascade) + yaboula
-- Date: 2026-05-09 (BANK-DB.AMEND.1)
-- Description:
--   Adds subsidy program catalog persistence required by Issue #002 REQ-FE-010
--   and REQ-FE-013, then links subsidy disbursement ledger rows to programs.
--
-- Dependencies:
--   - 016_tax_brackets_history_subsidies.sql (sonar_bank_subsidies exists).
--   - 029_company_registry.sql (company grants can validate company_id).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_subsidy_programs (
  id                    CHAR(36)        NOT NULL,
  code                  VARCHAR(32)     NOT NULL,
  name                  VARCHAR(96)     NOT NULL,
  program_type          ENUM('food','housing','employment','medical','education','emergency','agricultural') NOT NULL,
  status                ENUM('active','paused','completed','proposed') NOT NULL DEFAULT 'proposed',

  budget_amount         DECIMAL(14,2)   NOT NULL DEFAULT 0,
  disbursed_amount      DECIMAL(14,2)   NOT NULL DEFAULT 0,
  beneficiary_count_cached INT UNSIGNED NOT NULL DEFAULT 0,

  starts_at             INT UNSIGNED    NOT NULL,
  ends_at               INT UNSIGNED    NULL,
  description           VARCHAR(255)    NULL,

  created_by_account_id CHAR(36)        NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_subsidy_programs_code (code),
  KEY idx_sonar_bank_subsidy_programs_status_type (status, program_type),
  KEY idx_sonar_bank_subsidy_programs_window (starts_at, ends_at),
  KEY idx_sonar_bank_subsidy_programs_created_by (created_by_account_id),

  CONSTRAINT fk_sonar_bank_subsidy_programs_created_by
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_subsidy_programs_budget_nonneg CHECK (budget_amount >= 0),
  CONSTRAINT chk_sonar_bank_subsidy_programs_disbursed_nonneg CHECK (disbursed_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS sp_apply_030_subsidy_programs;

DELIMITER $$

CREATE PROCEDURE sp_apply_030_subsidy_programs()
BEGIN
  DECLARE col_count INT DEFAULT 0;
  DECLARE idx_count INT DEFAULT 0;

  SELECT COUNT(*) INTO col_count
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_subsidies'
    AND COLUMN_NAME = 'program_id';

  IF col_count = 0 THEN
    ALTER TABLE sonar_bank_subsidies
      ADD COLUMN program_id CHAR(36) NULL AFTER subsidy_kind;
  END IF;

  SELECT COUNT(*) INTO idx_count
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_subsidies'
    AND INDEX_NAME = 'idx_sonar_bank_subsidies_program_issued';

  IF idx_count = 0 THEN
    ALTER TABLE sonar_bank_subsidies
      ADD KEY idx_sonar_bank_subsidies_program_issued (program_id, issued_at DESC);
  END IF;
END$$

DELIMITER ;

CALL sp_apply_030_subsidy_programs();
DROP PROCEDURE sp_apply_030_subsidy_programs;

COMMIT;

-- ============================================================================
-- Note:
--   No enforced FK from sonar_bank_subsidies.program_id to programs is added in
--   this migration because sonar_bank_subsidies is partitioned by issued_at.
--   Backend Lead must validate program_id/code app-side before disbursement.
-- ============================================================================

-- ============================================================================
-- END 030_subsidy_programs.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 031_business_payroll_persistence.sql
-- ============================================================================
-- ============================================================================
-- Migration: 031_business_payroll_persistence.sql
-- Author: DB Lead (Cascade) + yaboula
-- Date: 2026-05-09 (BANK-DB.AMEND.1)
-- Description:
--   Adds durable payroll execution persistence required by Issue #002 REQ-FE-015.
--   Business treasury approvals remain the approval queue; payroll batches/lines
--   are the executable, auditable unit of work.
--
-- Dependencies:
--   - 029_company_registry.sql (sonar_companies exists).
--   - 026_bank_business_treasuries.sql (treasury approvals exist).
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_business_payroll_batches (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,
  treasury_id           CHAR(36)        NOT NULL,

  state                 ENUM('draft','pending_approval','queued','executed','held','failed','cancelled') NOT NULL DEFAULT 'draft',
  total_net_amount      DECIMAL(14,2)   NOT NULL DEFAULT 0,
  line_count            INT UNSIGNED    NOT NULL DEFAULT 0,
  held_line_count       INT UNSIGNED    NOT NULL DEFAULT 0,
  failed_line_count     INT UNSIGNED    NOT NULL DEFAULT 0,

  requested_by_account_id CHAR(36)      NOT NULL,
  executed_by_account_id  CHAR(36)      NULL,

  scheduled_for         INT UNSIGNED    NULL,
  executed_at           INT UNSIGNED    NULL,

  related_approval_id   CHAR(36)        NULL,
  related_audit_id      BIGINT UNSIGNED NULL,
  idempotency_key       CHAR(64)        NULL,

  failure_code          VARCHAR(64)     NULL,
  failure_message       VARCHAR(255)    NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_business_payroll_batches_idempotency (idempotency_key),
  KEY idx_sonar_bank_business_payroll_batches_company_state (company_id, state, created_at DESC),
  KEY idx_sonar_bank_business_payroll_batches_treasury_state (treasury_id, state),
  KEY idx_sonar_bank_business_payroll_batches_approval (related_approval_id),
  KEY idx_sonar_bank_business_payroll_batches_schedule (state, scheduled_for),

  CONSTRAINT fk_sonar_bank_business_payroll_batches_company
    FOREIGN KEY (company_id) REFERENCES sonar_companies(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_batches_treasury
    FOREIGN KEY (treasury_id) REFERENCES sonar_bank_business_treasuries(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_batches_requested_by
    FOREIGN KEY (requested_by_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_batches_executed_by
    FOREIGN KEY (executed_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_batches_approval
    FOREIGN KEY (related_approval_id) REFERENCES sonar_bank_business_treasury_approvals(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_business_payroll_batches_total_nonneg CHECK (total_net_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sonar_bank_business_payroll_lines (
  id                    CHAR(36)        NOT NULL,
  batch_id              CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,

  employee_account_id   CHAR(36)        NOT NULL,
  destination_bank_account_id CHAR(36)  NOT NULL,

  net_amount            DECIMAL(14,2)   NOT NULL,
  state                 ENUM('ready','held','paid','failed','cancelled') NOT NULL DEFAULT 'ready',
  failure_code          VARCHAR(64)     NULL,
  failure_message       VARCHAR(255)    NULL,

  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,

  paid_at               INT UNSIGNED    NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_bank_business_payroll_lines_batch_state (batch_id, state),
  KEY idx_sonar_bank_business_payroll_lines_employee (employee_account_id, created_at DESC),
  KEY idx_sonar_bank_business_payroll_lines_company_state (company_id, state, created_at DESC),
  KEY idx_sonar_bank_business_payroll_lines_destination (destination_bank_account_id),

  CONSTRAINT fk_sonar_bank_business_payroll_lines_batch
    FOREIGN KEY (batch_id) REFERENCES sonar_bank_business_payroll_batches(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_lines_company
    FOREIGN KEY (company_id) REFERENCES sonar_companies(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_lines_employee
    FOREIGN KEY (employee_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_business_payroll_lines_destination
    FOREIGN KEY (destination_bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_business_payroll_lines_amount_positive CHECK (net_amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- Backend Lead follow-up:
--   1. PayrollExecute must lock idempotency first, then batch row, then lines.
--   2. related_movement_id remains a logical link because sonar_bank_movements
--      has a composite partitioned primary key (id, occurred_at).
-- ============================================================================

-- ============================================================================
-- END 031_business_payroll_persistence.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 032_govt_risk_scores_and_treasury_movements.sql
-- ============================================================================
-- ============================================================================
-- Migration: 032_govt_risk_scores_and_treasury_movements.sql
-- Author: DB Lead (Cascade) + yaboula
-- Date: 2026-05-09 (BANK-DB.AMEND.1)
-- Description:
--   Adds authoritative GOVT risk score materialization (0-100) and extends
--   treasury movement categories required by Issue #002 REQ-FE-006/007/012/014.
--
-- Dependencies:
--   - 003_bank_schema.sql + 015_bank_movements_category_extend.sql.
--   - 029_company_registry.sql.
-- ============================================================================

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_govt_risk_scores (
  subject_type          ENUM('citizen','company') NOT NULL,
  subject_id            CHAR(36)        NOT NULL,

  score                 TINYINT UNSIGNED NOT NULL,
  risk_level            ENUM('low','medium','high','critical') NOT NULL,

  velocity_score        TINYINT UNSIGNED NOT NULL DEFAULT 0,
  compliance_score      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  exposure_score        TINYINT UNSIGNED NOT NULL DEFAULT 0,
  flag_score            TINYINT UNSIGNED NOT NULL DEFAULT 0,
  dormancy_score        TINYINT UNSIGNED NOT NULL DEFAULT 0,

  components_json       JSON            NULL,
  formula_version       VARCHAR(32)     NOT NULL DEFAULT 'govt-risk-v1',
  computed_by           ENUM('system','government','admin') NOT NULL DEFAULT 'system',
  computed_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  expires_at            INT UNSIGNED    NULL,

  related_audit_id      BIGINT UNSIGNED NULL,

  PRIMARY KEY (subject_type, subject_id),
  KEY idx_sonar_bank_govt_risk_scores_level_score (subject_type, risk_level, score DESC),
  KEY idx_sonar_bank_govt_risk_scores_computed (computed_at DESC),
  KEY idx_sonar_bank_govt_risk_scores_expires (expires_at),

  CONSTRAINT chk_sonar_bank_govt_risk_scores_score CHECK (score <= 100),
  CONSTRAINT chk_sonar_bank_govt_risk_scores_velocity CHECK (velocity_score <= 100),
  CONSTRAINT chk_sonar_bank_govt_risk_scores_compliance CHECK (compliance_score <= 100),
  CONSTRAINT chk_sonar_bank_govt_risk_scores_exposure CHECK (exposure_score <= 100),
  CONSTRAINT chk_sonar_bank_govt_risk_scores_flag CHECK (flag_score <= 100),
  CONSTRAINT chk_sonar_bank_govt_risk_scores_dormancy CHECK (dormancy_score <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS sp_apply_032_movements_treasury_extend;

DELIMITER $$

CREATE PROCEDURE sp_apply_032_movements_treasury_extend()
BEGIN
  DECLARE col_def TEXT DEFAULT '';
  DECLARE idx_count INT DEFAULT 0;

  SELECT COLUMN_TYPE INTO col_def
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_movements'
    AND COLUMN_NAME = 'category';

  IF col_def NOT LIKE '%fine_collected%' THEN
    ALTER TABLE sonar_bank_movements
      MODIFY COLUMN category ENUM(
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
        'compliance_freeze',
        'fine_collected',
        'payroll_disbursement',
        'reconciliation',
        'interest_accrued'
      ) NOT NULL COMMENT 'accounting category Phase A amendment â€” 28 canonical values';
  END IF;

  SELECT COUNT(*) INTO idx_count
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sonar_bank_movements'
    AND INDEX_NAME = 'idx_sonar_bank_movements_treasury_rollup';

  IF idx_count = 0 THEN
    ALTER TABLE sonar_bank_movements
      ADD KEY idx_sonar_bank_movements_treasury_rollup (category, occurred_at DESC, bank_account_id);
  END IF;
END$$

DELIMITER ;

CALL sp_apply_032_movements_treasury_extend();
DROP PROCEDURE sp_apply_032_movements_treasury_extend;

COMMIT;

-- ============================================================================
-- Risk score contract:
--   score: 0-100 authoritative Backend/Security computed materialized snapshot.
--   low: 0-24, medium: 25-54, high: 55-79, critical: 80-100.
--   Backend Lead refresh cadence target: every 5 minutes for active citizens and
--   active companies, plus on-demand recompute after sanctions or critical flags.
-- ============================================================================

-- ============================================================================
-- END 032_govt_risk_scores_and_treasury_movements.sql
-- ============================================================================

-- ============================================================================
-- BEGIN 033_bank_saved_recipients.sql
-- ============================================================================
START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_saved_recipients (
  id                    CHAR(36)        NOT NULL,
  owner_account_id      CHAR(36)        NOT NULL,
  counterpart_iban      VARCHAR(20)     NOT NULL,
  alias                 VARCHAR(64)     NULL,
  is_favorite           BOOLEAN         NOT NULL DEFAULT FALSE,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_saved_recipients_owner_iban (owner_account_id, counterpart_iban),
  KEY idx_sonar_bank_saved_recipients_owner_fav (owner_account_id, is_favorite, updated_at),
  KEY idx_sonar_bank_saved_recipients_iban (counterpart_iban),

  CONSTRAINT fk_sonar_bank_saved_recipients_owner
    FOREIGN KEY (owner_account_id) REFERENCES sonar_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- END 033_bank_saved_recipients.sql
-- ============================================================================

ALTER TABLE sonar_bank_accounts
  ADD COLUMN IF NOT EXISTS savings DECIMAL(14,2) NOT NULL DEFAULT 0 AFTER balance;

-- ============================================================================
-- 039_sonar_bank_account_joints.sql
-- ============================================================================
START TRANSACTION;

CREATE TABLE IF NOT EXISTS sonar_bank_account_joints (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id            CHAR(36)        NOT NULL,
  joint_citizen_id      VARCHAR(64)     NOT NULL COMMENT 'sonar_accounts.char_id',
  added_by_citizen_id   VARCHAR(64)     NOT NULL,
  added_at              INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_account_joints_pair (account_id, joint_citizen_id),
  KEY idx_sonar_bank_account_joints_citizen (joint_citizen_id),

  CONSTRAINT fk_sonar_bank_account_joints_account
    FOREIGN KEY (account_id) REFERENCES sonar_bank_accounts(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;

-- ============================================================================
-- END 039_sonar_bank_account_joints.sql
-- ============================================================================
