-- =============================================================================
-- Admirals Bank — config.lua
--
-- Constantes runtime + convars del dominio banca. NO contiene lógica
-- (eso vive en server/iban.lua, accounts.lua, callbacks.lua).
--
-- Referencias SSoT:
--   docs/economy/01_economic_model.md §2.5 (IBAN format).
--   docs/economy/01_economic_model.md §4.1 (starter balance 2.500 €).
--   docs/economy/01_economic_model.md §10.5 (fees — S1.2+).
--   docs/technical/03_db_schema.md §4.1 (admirals_bank_accounts).
--   docs/technical/04_api_contracts.md §3.1 C001 (getBalance signature).
--   docs/technical/04_api_contracts.md §8.1 (rate limits 30/10s read, 10/60s write).
-- =============================================================================

Admirals = Admirals or {}
Admirals.Bank = Admirals.Bank or {}
Admirals.Bank.Config = Admirals.Bank.Config or {}

local Config = Admirals.Bank.Config

-- -----------------------------------------------------------------------------
-- Version — SEMVER de admirals_bank. Bump MINOR si nueva callback, MAJOR si
-- breaking change en firma C001-C005.
-- -----------------------------------------------------------------------------
Config.Version = '0.1.0'

-- =============================================================================
-- IBAN generation (per docs/economy/01_economic_model.md §2.5)
-- =============================================================================

-- Format literal: AD-XXXX-XXXX-XXXX (17 chars total: 2 prefix + 3 dashes +
-- 11 random alphanumeric uppercase + 1 checksum char).
--
-- DB column: VARCHAR(20) — headroom para futuras evoluciones (e.g., AD2-XXXX).
Config.IbanPrefix = 'AD-'

-- Charset random — alphanumeric uppercase. 26 letters + 10 digits = 36 chars
-- → 36^11 ≈ 1.31e17 random space ≈ 2^57. Colisión negligible para volumen
-- esperado (<20K accounts per SSoT §03 §11.3).
Config.IbanCharset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

-- Posición del checksum char en el string final — último char del último
-- grupo. Por ej: AD-1A2B-3C4D-5E6FX donde X es checksum.
-- Al validar, recomputamos checksum y comparamos.
Config.IbanChecksumPosition = 'last'

-- Max retries al generar IBAN si colisiona con existente (UNIQUE iban).
-- 36^11 ≈ 1.3e17 → con 20K accounts probabilidad colisión por intento ≈
-- 1.5e-13 → 5 retries es overkill pero seguro.
Config.IbanGenerateMaxRetries = 5

-- Reserved prefixes — IBANs especiales no asignables a players normales.
-- Server seed account: 'AD-SYS0-0000-0001' (per SSoT §03 §13.3).
-- Si IBAN.Generate sale algo que matchea uno de estos, retry.
Config.IbanReservedPrefixes = {
  'AD-SYS',  -- system accounts
  'AD-NPC',  -- NPC supplier seeds (futuro S2+)
}

-- =============================================================================
-- Starter account (per docs/economy/01_economic_model.md §4.1)
-- =============================================================================

-- Balance inicial al crear cuenta personal first-time.
-- 2.500 € permite empezar como empleado sin grind extremo, NO permite fundar
-- empresa inmediatamente (founding fee 5.000 €). Forces gameplay loop.
Config.StarterBalanceEur = 2500.00

-- Concepto del movimiento contable inicial (visible en extracto bancario).
Config.StarterMovementConcept = 'Saldo inicial Admirals'

-- Categoría del movimiento — usa enum valor canónico admirals_bank_movements.category.
-- 'starter_seed' añadida en migration 003 ENUM (no exists in SSoT but technically aditive).
Config.StarterMovementCategory = 'starter_seed'

-- Nonce/idempotency: UUID v4 (36 chars) para request_nonce — encaja en
-- admirals_bank_movements.request_nonce CHAR(36). El prefijo 'starter_' fue
-- considered y descartado (citizen_id en frameworks esx/native puede exceder
-- 28 chars → overflow CHAR(36)). Idempotency real vive en step 2 de
-- EnsureStarterAccount (GetPersonalByCitizenId existing check).
-- Config.StarterNoncePrefix REMOVED — usamos _uuid_v4() en accounts.lua.

-- =============================================================================
-- Audit categories (per docs/technical/04_api_contracts.md §10.3 +
--                    docs/technical/06_fivem_standards.md §4.4)
-- =============================================================================

-- Categorías canónicas escritas a admirals_audit_log via Admirals.Log.Audit.
-- TODA operación de dinero o cambio de ownership PASA por Audit obligatoriamente.
Config.AuditCategories = {
  StarterSeed   = 'bank.starter_seed',     -- creación cuenta + 2.500€ inicial
  AccountCreate = 'bank.account_create',   -- creación cuenta sin starter (escrow, company...)
  BalanceRead   = 'bank.balance_read',     -- C001 getBalance (solo si Config.AuditReads=true)
  Transfer      = 'bank.transfer',         -- C002 (S1.2)
  Deposit       = 'bank.deposit',          -- ingreso cash (S1.2+)
  Withdrawal    = 'bank.withdrawal',       -- retirada cash (S1.2+)
  Freeze        = 'bank.freeze',           -- congelar cuenta (admin)
  Unfreeze      = 'bank.unfreeze',         -- descongelar (admin)
}

-- Si true, cada C001 getBalance escribe a admirals_audit_log. Default false
-- (alto volumen — 30/10s per player → ruido). Activar solo en investigation
-- forense temporal.
Config.AuditReads = false

-- =============================================================================
-- C001 getBalance behavior
-- =============================================================================

-- Si true y request iba sin `iban` field, server resuelve al IBAN personal
-- del player source via accounts.GetByOwnerCitizenId. Si false, requiere iban
-- explícito (rechaza request).
Config.GetBalanceDefaultPersonalIban = true

-- Timeout duro del callback (per SSoT §3.1 C001 "Timeout: 2s").
Config.GetBalanceTimeoutMs = 2000

-- =============================================================================
-- Boot orchestration
-- =============================================================================

-- Timeout esperando admirals_core ready antes de registrar callbacks/identity hook.
Config.CoreWaitTimeoutMs = 30000

-- Evento ready que admirals_bank emite cuando ya está operativo.
Config.BankReadyEventName = 'admirals:bank:ready'

-- Eventos canónicos que admirals_bank emite (publica al Bus admirals_core):
Config.Events = {
  AccountCreated         = 'admirals:bank:account_created',
  StarterBalanceCredited = 'admirals:bank:starter_balance_credited',
  -- S1.2+:
  -- TransferCompleted = 'admirals:bank:transfer_completed',
  -- EscrowCreated     = 'admirals:bank:escrow_created',
}
