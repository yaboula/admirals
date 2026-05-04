-- ============================================================================
-- Migration: 004_bank_seed_system_account.sql
-- Author: Cascade + yaboula
-- Date: 2026-05-02 (S1.2)
-- Description:
--   Seed system bank account `AD-SYS0-0000-0001` con balance 10.000.000 €.
--   Esta cuenta es la treasury server-side. Investment for S1.3 (escrow fees,
--   tax retention, market fees → entran a esta IBAN en sprints futuros). En
--   S1.2 NO recibe transferencias (internal transfer fee = 0 € per SSoT
--   `economy/01_economic_model.md` §10.3:697).
--
-- Dependencies:
--   - 002_foundation_tables (sonar_accounts → FK target).
--   - 003_bank_schema (sonar_bank_accounts + sonar_bank_movements).
--
-- Reversible: sí en dev (DELETE rows con UUIDs fijos). NO post-prod.
--
-- SSoT references:
--   docs/economy/01_economic_model.md §4.2 (NPC system IBAN balance 10M €).
--   docs/economy/01_economic_model.md §10.3 (internal transfer fee = 0 €).
--   docs/technical/03_db_schema.md §13.3 (system account ejemplo INSERT).
--   docs/technical/03_db_schema.md §4.1 (sonar_bank_accounts CHECK XOR).
--
-- DECISIONES TÉCNICAS (founder green-light 2026-05-02):
--
--   D1. CHECK XOR ownership es ESTRICTO en migration 003:107-110 — exige
--       (type='personal' AND owner_account_id IS NOT NULL AND owner_company_id IS NULL)
--       OR (type IN ('company','cooperative','escrow') AND owner_company_id IS NOT NULL AND owner_account_id IS NULL).
--
--       Founder recomendó type='escrow' MÁS opción (a) "sonar_accounts
--       ficticio para owner_account_id" — son INCOMPATIBLES entre sí (escrow
--       requiere owner_company_id, no owner_account_id).
--
--       Único path consistente con CHECK + opción(a) sin tocar constraint:
--         type = 'personal'
--         owner_account_id = SYSTEM sonar_accounts ficticio (creado aquí).
--
--       Semánticamente raro ("system" no es realmente "personal") pero pragmático.
--       Technical debt anotado para S2+: ALTER ENUM 'system' + relax CHECK O
--       crear sonar_companies ficticio cuando esa tabla exista (S2 schema).
--
--   D2. UUID fijos determinísticos — facilita test + debugging + queries
--       analytics ("¿es la cuenta system?" → WHERE id='b0000000-...').
--       No riesgo seguridad: UUID system es público (visible en cualquier
--       extracto bancario que reciba pago a system).
--
--   D3. INSERT IGNORE en accounts + bank_accounts (UNIQUE iban + PK id como
--       guards). Re-arranque server NO altera balance ni duplica rows.
--
--   D4. Movement seed (categoría 'adjustment' per ENUM canónico §4.2:556) —
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
-- char_id = 'SYSTEM' (reservado — no asignable a player real porque los
-- citizenIds reales contienen 'license:' o 'license2:' o numérico, nunca
-- el literal 'SYSTEM').
-- framework_source = 'sonar_core' (no proviene de qbox/esx — server-managed).
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
-- type = 'personal' por restricción CHECK (D1 arriba). Owner = SYSTEM account.
-- balance = 10.000.000 € per SSoT economy §4.2.
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
-- amount = +10.000.000 (signed amount per SSoT §4.2 — positivo=ingreso).
-- balance_after = 10.000.000 (snapshot post-movement).
-- category = 'adjustment' (categoría canónica para seeds/correcciones admin).
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
  'adjustment', NULL, 'System treasury seed (10M EUR per economy §4.2)',
  NULL, NULL, NULL,
  'a0000000-0000-0000-0000-00000000seed', NULL, 'sonar_core'
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM sonar_bank_movements
  WHERE request_nonce = 'a0000000-0000-0000-0000-00000000seed'
);
