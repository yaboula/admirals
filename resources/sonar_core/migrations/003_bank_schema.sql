-- ============================================================================
-- Migration: 003_bank_schema.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.1)
-- Description:
--   Crea las 2 tablas core del dominio banca:
--     1. sonar_bank_accounts   (cuentas IBAN personales/empresariales)
--     2. sonar_bank_movements  (ledger inmutable, PARTITIONED mensual)
--
--   `sonar_escrows` se difiere a S1.3 (ADR — green-light founder May 2 2026).
--   Razón: el DDL canónico no existe aún en SSoT §03 §4.3, y la lógica escrow
--   se implementa en S1.3 — entrega aditiva limpia.
--
-- Dependencies:
--   - 001_schema_versions (runner tracking).
--   - 002_foundation_tables (sonar_accounts → FK target).
--
-- Reversible: sí en dev (DROP TABLE — orden inverso por FK). NO post-prod.
--
-- SSoT references:
--   docs/technical/03_db_schema.md §4.1 (sonar_bank_accounts canonical).
--   docs/technical/03_db_schema.md §4.2 (sonar_bank_movements PARTITIONED).
--   docs/technical/03_db_schema.md §15.4 (cron mensual partitioning S2+).
--   docs/economy/01_economic_model.md §2.5 (IBAN format AD-XXXX-XXXX-XXXX).
--   docs/economy/01_economic_model.md §4.1 (starter balance 2.500 €).
--
-- DECISIONES TÉCNICAS reconciliadas con SSoT (founder green-light 2026-05-02):
--
--   D1. Collation `utf8mb4_unicode_ci` (NO `utf8mb4_0900_ai_ci` SSoT) —
--       MariaDB-compat consistente con migration 002 (locked en S0.4).
--
--   D2. `updated_at ON UPDATE (UNIX_TIMESTAMP())` OMITIDO — MariaDB-illegal
--       para columnas non-TIMESTAMP. App-managed via Admirals.DB.Execute.
--       Ver migration 002 línea 42 para el mismo patrón.
--
--   D3. FK `sonar_bank_accounts.owner_company_id → sonar_companies(id)`
--       DEFERRED. La tabla `sonar_companies` no existe aún (se creará S2+).
--       Cuando S2 cree `sonar_companies`, su migration añadirá el FK via
--       ALTER TABLE ADD CONSTRAINT (non-breaking, aditivo). El comentario lo
--       deja explícito en el CREATE TABLE.
--
--   D4. CHECK constraint del tipo de owner SE MANTIENE (SSoT §4.1 lo define).
--       MariaDB 10.2+ y MySQL 8.0.16+ lo enforce nativamente. En versiones
--       previas se ignora silenciosamente — la lógica owner-type-correcta se
--       enforce además a application-layer en server/accounts.lua.
--
--   D5. Particiones bank_movements REFRESCADAS — SSoT cita p_2026_01..03 (Feb-Apr
--       2026) que ya están en el pasado. Nuevas partitions cubren May/Jun/Jul
--       2026 (sprint window) + p_future MAXVALUE catchall. Cron mensual S2+
--       hará rolling forward (per SSoT §03 §15.4 ejemplo Lua incluido).
--
--   D6. Escrow type inicial soportado en ENUM `type` aunque la tabla
--       `sonar_escrows` se difiere — esto permite a S1.3 simplemente
--       INSERT un account con type='escrow' sin necesitar nuevo ENUM ALTER.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. sonar_bank_accounts
--
-- Una cuenta bancaria con IBAN único. Puede ser personal (owner_account_id)
-- o empresarial/cooperativa/escrow (owner_company_id).
--
-- Constraints:
--   - PRIMARY KEY id (UUID v4 application-generated).
--   - UNIQUE iban (no dos cuentas con mismo IBAN).
--   - CHECK XOR ownership (personal ⊕ company-like).
--   - FK soft delete: ON DELETE RESTRICT (no permitir borrar account/company
--     con cuenta bancaria asociada — debe cerrar primero).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_bank_accounts (
  id                    CHAR(36)        NOT NULL COMMENT 'UUID v4',
  iban                  VARCHAR(20)     NOT NULL COMMENT 'AD-XXXX-XXXX-XXXX (17 chars literales)',
  type                  ENUM('personal','company','cooperative','escrow') NOT NULL,

  owner_account_id      CHAR(36)        NULL     COMMENT 'NULL si type != personal',
  owner_company_id      CHAR(36)        NULL     COMMENT 'NULL si type=personal — FK a sonar_companies se añade en S2+',

  balance               DECIMAL(14,2)   NOT NULL DEFAULT 0 COMMENT 'saldo actual (negativo = overdraft admin-only)',
  daily_limit_out       DECIMAL(12,2)   UNSIGNED NULL COMMENT 'límite saliente diario (NULL = sin límite)',
  is_frozen             TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '0=activo, 1=congelada (anti-fraude)',
  frozen_reason         VARCHAR(255)    NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  -- updated_at: app-managed (NO ON UPDATE — MariaDB-illegal en INT UNSIGNED).
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

  -- FK sonar_companies se añade S2+ via ALTER TABLE (entrega aditiva):
  --   ALTER TABLE sonar_bank_accounts
  --     ADD CONSTRAINT fk_sonar_bank_accounts_owner_company
  --     FOREIGN KEY (owner_company_id) REFERENCES sonar_companies(id)
  --     ON DELETE RESTRICT ON UPDATE CASCADE;
  --
  -- D4 reconciled (Phase 8 post-rename, MariaDB 12.2.2 fix): el CHECK XOR
  -- named constraint causa "Function or expression 'owner_account_id' cannot
  -- be used in the CHECK clause" en MariaDB 12.x parser (named CHECK + IS NULL
  -- multi-col tras FK constraint). Workaround: enforcement 100% application-layer
  -- en `server/accounts.lua` (CreateAccount valida type→owner XOR antes INSERT).
  -- Defense-in-depth DDL omitida para unblock dev boot. Re-evaluar S2+ si MariaDB
  -- bug fixed o cambio engine.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 2. sonar_bank_movements (PARTITIONED RANGE BY occurred_at)
--
-- Ledger inmutable contable. Cada transferencia genera 2 rows (debe + haber).
-- Particionado mensual permite:
--   - Pruning automático por queries con WHERE occurred_at >= ...
--   - Archival a cold storage por partition completa.
--   - DROP PARTITION rápido (vs DELETE row-by-row).
--
-- Notas SSoT §4.2:
--   - NO FK a bank_account_id intencionalmente (volumen + integrity por app).
--   - PRIMARY KEY (id, occurred_at) requerido por MySQL para particionar
--     usando occurred_at como partition key.
--   - request_nonce evita replay attacks (idempotency anti-double-spend).
--   - balance_after es snapshot — auditable sin recalcular cadena.
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
  ) NOT NULL COMMENT 'categoría contable; starter_seed añadida para 2.500€ inicial',
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
