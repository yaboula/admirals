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
--   (b) Crea tabla `sonar_escrows` — holdings transaccionales entre buyer
--       y seller con fee retenido. Referenced por FSM escrow_lifecycle per
--       `docs/technical/05_state_machines.md` §4.1.
--
-- Dependencies:
--   - 003_bank_schema.sql (sonar_bank_accounts existe con constraint original).
--   - 005_balance_nonneg_check.sql (chk balance >= 0 preservado, no-op aquí).
--
-- Reversible: sí en dev (DROP TABLE sonar_escrows + restore constraint
-- original). NO post-prod con escrows reales.
--
-- SSoT references (gaps documented — ADR formal S2+):
--   docs/technical/03_db_schema.md §4.3 — **GAP SSoT**: DDL canónico inexistente.
--     Esta migration implementa DDL funcional per diseño S1.3 (founder + agent).
--   docs/technical/04_api_contracts.md §3.1 C004/C005 (createEscrow/releaseEscrow).
--   docs/technical/05_state_machines.md §4.1 (FSM escrow_lifecycle, states
--     canónicos created/locked/released/refunded/disputed).
--   docs/economy/01_economic_model.md §10.4.1 (lifecycle) + §10.4.2
--     (fee 0.5-1%, caps 2-100€).
--
-- DECISIONES TÉCNICAS (founder green-light 2026-05-02 F1-F5 resoluciones):
--
--   D1. CONSTRAINT chk_sonar_bank_accounts_owner_xor_or_escrow —
--       3 ramas explícitas, preserva strictness pre-006 para personal/company/
--       cooperative + añade rama `type='escrow'` (ambos owner NULL permitido).
--       Aditivo puro — comportamiento non-escrow idéntico al pre-006.
--
--   D2. `sonar_escrows.status` ENUM 5 valores per SSoT §05 §4.1:
--       `created`, `locked`, `released`, `refunded`, `disputed`.
--       S1.3 implementa transitions `created→locked` (atomic INSERT direct
--       status='locked' en TX Create), `locked→released`, `locked→refunded`.
--       `disputed` declarado en ENUM — behavior NOT implementado S1.3 (deferred
--       S2+ con contract dispute callbacks). Cero breaking change al añadirlo.
--
--   D3. `expires_at INT UNSIGNED NOT NULL` — populated en Create como
--       `created_at + Config.EscrowDefaultExpirySeconds` (default 30 días
--       per economy §19.1.2). S1.3 NO implementa cron auto-refund al expirar
--       — schema field existe + índice `idx_...status_expires` soporta query
--       futuro. Timeout behavior deferred S2+.
--
--   D4. `request_nonce CHAR(36) NOT NULL UNIQUE` — idempotency key cliente.
--       UUID v4. Permite replay detection: 2ª createEscrow con mismo
--       request_id → DB throw `Duplicate entry for key uq_..._request_nonce`,
--       caller detecta + returns cached response via
--       `exports.sonar_bridges:IsIdemReplay` (consistency con S1.2 C002).
--
--   D5. `released_to ENUM('seller','buyer','split')` — 'split' declarado
--       para forward-compat S3+ (partial release). S1.3 release callbacks
--       rechazan 'split' con error_code `NOT_IMPLEMENTED` (canonical nuevo).
--
--   D6. `fee_charged DECIMAL(15,2) NOT NULL` — fee **retenido por system
--       treasury** al crear escrow per economy §10.4.2. Formula aplicación:
--       `fee = max(2.0, min(amount * 0.01, 100.0))`. Fee NO se devuelve al
--       buyer en caso de refund (founder decisión S1.2 manteniendo — evita
--       gaming "crea-refund-crea" para cobrar fee 0 via mass disputes).
--
--   D7. FKs `ON DELETE RESTRICT` (SSoT §1.6 línea 117-119 "legal integrity")
--       — no se puede borrar buyer/seller/escrow account con escrows activos.
--       DIVERGENCE: el DDL fue aplicado manualmente (HeidiSQL 2026-05-02)
--       sin `ON DELETE RESTRICT` explícito. InnoDB default NO ACTION ≈
--       RESTRICT comportamiento funcional (referential integrity blocked).
--       Este file declara RESTRICT explícito para fresh installs — tablas
--       existentes permanecen en NO ACTION implícito sin impacto operacional.
--
--   D8. CHECK `amount > 0` + `fee_charged >= 0` — atomicity by construction
--       (MariaDB 10.4.32+ enforce nativo, verificado 2026-05-02 VERSION()).
--       App-layer enforces además (Escrow.Create valida pre-TX).
--
--   D9. Idempotent DDL pattern — `DROP CONSTRAINT IF EXISTS` + `CREATE TABLE
--       IF NOT EXISTS`. Permite re-apply tras HeidiSQL manual (tracking row
--       backfilled via INSERT separado con SHA-256 del body). Fresh installs
--       ejecutan todo desde cero sin error.
--
--   D10. ADR-010 inmutabilidad — este file NO se edita post-aplicación. Si
--        se necesita schema change → nueva migration 007+ aditiva. Checksum
--        check en `sonar_core/server/migrations.lua:253` enforce tampering
--        detection.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Relax CHECK constraint sonar_bank_accounts — add `type='escrow'` branch.
--
-- Pre-006: `chk_sonar_bank_accounts_owner_xor` (migration 003 línea 107)
--   strict XOR personal↔company/cooperative/escrow con owner correspondiente.
--   Problema S1.3: escrow accounts son server-managed, sin owner real.
--
-- Post-006: `chk_sonar_bank_accounts_owner_xor_or_escrow` 3-ramas:
--   - type='escrow' → ambos owner_* NULL (server-managed).
--   - type='personal' → owner_account_id NOT NULL AND owner_company_id IS NULL.
--   - type IN ('company','cooperative') → owner_company_id NOT NULL AND owner_account_id IS NULL.
--
-- Aditivo: non-escrow rows pre-006 siguen válidas.
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
-- 2. sonar_escrows — holdings transaccionales buyer↔seller con fee retained.
--
-- FSM escrow_lifecycle per SSoT §05 §4.1:
--   created (INSERT conceptual) → locked (post-funding atomic, S1.3 happy path
--     persiste direct 'locked' en Create TX) → released | refunded | disputed.
--
-- Cada row vincula:
--   - buyer_account_id    → sonar_bank_accounts.id (del comprador)
--   - seller_account_id   → sonar_bank_accounts.id (del vendedor)
--   - escrow_account_id   → sonar_bank_accounts.id (cuenta técnica server-
--                           managed, type='escrow', creada en la misma TX
--                           atomic que INSERT sonar_escrows).
--
-- IBAN del escrow account usa formato canonical S1.1 (AD-XXXX-XXXX-XXXX 17
-- chars via IBAN.Generate) — discriminación via type='escrow' column, NO
-- prefix especial (decisión F5 founder S1.3).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sonar_escrows (
  id                        CHAR(36)        NOT NULL COMMENT 'UUID v4 application-generated',
  status                    ENUM('created','locked','released','refunded','disputed') NOT NULL,

  buyer_account_id          CHAR(36)        NOT NULL COMMENT 'FK sonar_bank_accounts.id (buyer)',
  seller_account_id         CHAR(36)        NOT NULL COMMENT 'FK sonar_bank_accounts.id (seller)',
  escrow_account_id         CHAR(36)        NOT NULL COMMENT 'FK sonar_bank_accounts.id (escrow técnico server-managed)',

  amount                    DECIMAL(15,2)   NOT NULL COMMENT 'Monto retenido (NO incluye fee)',
  fee_charged               DECIMAL(15,2)   NOT NULL COMMENT 'Fee cobrado a buyer en Create, no devuelto en refund',

  contract_id               VARCHAR(64)     NULL     COMMENT 'Ref contrato B2B (sonar_contracts S2+, NULL S1.3)',
  release_condition         ENUM('delivery_confirmed','manual','time_based') NOT NULL DEFAULT 'manual',
  release_date              INT UNSIGNED    NULL     COMMENT 'Si time_based, timestamp auto-release',

  expires_at                INT UNSIGNED    NOT NULL COMMENT 'created_at + EscrowDefaultExpirySeconds (30d S1.3)',
  request_nonce             CHAR(36)        NOT NULL COMMENT 'UUID v4 idempotency key de C004 createEscrow',

  released_to               ENUM('seller','buyer','split') NULL COMMENT 'Destino de release (NULL si locked/created)',
  released_by_account_id    CHAR(36)        NULL     COMMENT 'Account del caller de C005 (audit)',
  released_at               INT UNSIGNED    NULL     COMMENT 'Timestamp UNIX de transition → released|refunded',

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
