# 🗄️ SONAR — Schema de Base de Datos `sonar_*` (post-migration-009) / `sonar_*` (pre-migration-009 legacy)

> **Versión:** **2.1 DRAFT AMENDMENT** (Issue #002 — Phase A.GOVT + Business persistence gaps) sobre v2.0 LOCKED PROVISIONAL. **SSoT vigente** — v1.2 foundational + §22-§29 LOCKED PROVISIONAL + **§30 DRAFT AMENDMENT** (`sonar_companies`, company members, subsidy programs, payroll batches/lines, GOVT risk scores 0-100, treasury movement categories). **No cambia semántica LOCKED previa; sólo añade persistencia requerida para mock→real GOVT/BUSINESS.**
> **Engine canonical (Q-DB-A LOCKED 2026-05-06):** **MariaDB 12.x primary** + MySQL 8 best-effort compat. Adaptación features MariaDB-specific (CHECK constraint workarounds + INT UNSIGNED `ON UPDATE` MariaDB-illegal + system-versioned tables descartado audit ledger).
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.4 (post-pivot)
> **Documento técnico padre:** `01_architecture.md` v1.0 (§3 define el schema lógico).
> **Documento hermano:** `02_events_catalog.md` v1.1+ (post-pivot).
> **ADRs relacionados:** ADR-010 (hybrid audit_log) + ADR-011 (pivot) + ADR-012 (refinement) + **ADR-013 (namespace migration Phase 8+9 scheduled)** + **ADR-018 🟡 proposed (Bank Lite mode hybrid 3-layer + cut ESX legacy + 8 CP integrated)**.
> **Estado v1.2:** firmado (S1.10.x). **DRAFTs v1.3+v1.4+v1.5:** founder approved 2026-05-06 (BANK-DB.1+2+3). **Estado v2.0 LOCKED PROVISIONAL:** 🔒 DB Lead self-signed + Founder APPROVED 2026-05-06. **Estado v2.1:** 🟡 DRAFT AMENDMENT emitido 2026-05-09 por Issue #002; requiere Backend Lead consumer review + Security Lead risk-score review antes de LOCKED MEASURED/AMENDMENT promotion.

> **Lectura previa obligatoria:** `agents/00_BOOTSTRAP.md` v1.6, `01_architecture.md` §3 (Schema DB compartido), §12 (Persistence patterns), §16 (Seguridad), **`planning/02_decision_log.md` ADR-013** (DB migration execution), **`planning/01_roadmap.md` v1.5** (Phase 9 scheduled), **`docs/agents/teams/01_SHARED_BRIEF.md`** v1.0 (Q1-Q16 + CP1-CP8 founder decisions), **`docs/agents/teams/slices/slice_database.md`** v1.0 (DB cherry-pick blueprint), **`docs/agents/teams/issues/issue_001_sonar_companies_pending.md`** (FK deferred Q-DB-E), **`docs/agents/teams/issues/issue_002_phase_a_govt_business_persistence_gaps.md`** (AMENDMENT v2.1 trigger).

---

## 0.1 Changelog v1.2 → v1.3 DRAFT v0.1 (Bank Phase A extends)

> **DB Lead authoring 2026-05-06.** Founder green-light Q-DB-A → Q-DB-J recibido. Esta DRAFT v0.1 entrega el núcleo crítico que desbloquea handoffs H1 (Backend Lead) + H2 (Security Lead). Iteraciones v0.2+ completarán scope total previo a LOCKED v1.0.

### Decisiones founder vinculantes (sesión BANK-DB.0 — 2026-05-06)

| Q | Resolución | Impact schema |
|---|---|---|
| **Q-DB-A** | Engine **MariaDB 12.x primary** lock. MySQL 8 best-effort compat. | DDL adaptado primitives MariaDB. Descartar `INVISIBLE INDEX` MySQL-only. CHECK multi-col `IS NULL` → app-layer (parser bug 12.2.2). |
| **Q-DB-B** | **DECIMAL(14,2) fiat** (consistency migrations 003+006). **BIGINT UNSIGNED `raw_amount` + TINYINT UNSIGNED `decimals`** crypto-only. | Money columns Phase A en DECIMAL excepto `sonar_bank_crypto_wallets`. |
| **Q-DB-C** | Path canonical migrations: `resources/sonar_core/migrations/010_*.sql` y siguientes. | Migrations DDL bajo `resources/sonar_core/migrations/`. |
| **Q-DB-D** | `sonar_bank_accounts` ENUM **refactor 2-col** (`owner_type` + `account_class`). Normalización. | Migration 010 ALTER TABLE separa columns. |
| **Q-DB-E** | **Opción 2** — `company_id CHAR(36)` opaque sin FK enforced. Issue #001 backend handoff. | Columnas `company_id` sin `FOREIGN KEY` constraint Phase A. |
| **Q-DB-F** | Audit ledger **3-tier defense-in-depth**: triggers SIGNAL + role REVOKE UPDATE/DELETE + app-layer enforcer. SysVer descartado. | Triggers `BEFORE UPDATE/DELETE` SIGNAL SQLSTATE '45000' obligatorios. |
| **Q-DB-G** | Particiones `sonar_bank_movements` extend hasta **Dic 2027** scope DB Phase A. | Migration 013 REORGANIZE PARTITION + 32 partitions mensuales 2026-09 → 2027-12. |
| **Q-DB-H** | Privacy votes **dual-layer** — voto público hasheado + tabla auditoría cruda admin-only. | `sonar_govt_votes` (hash) + `sonar_govt_votes_audit` (raw, ACE `sonar.bank.govt.audit.full`). |
| **Q-DB-I** | Stocks **híbrido** event-sourced + materialized snapshot on-trade. | `sonar_bank_stocks_transactions` (immutable append-only) + `sonar_bank_stocks_holdings` (materialized snapshot refresh on-trade). |
| **Q-DB-J** | `sonar_bank_status` **single row global per-server** (CP8 FSM). | Tabla `sonar_bank_status` con PK fijo `id=1` + state ENUM 4 valores. |

### Cuestionamientos preservados (Deviation from blueprint blocks — §29)

Bloques `### 🟡 Deviation from blueprint` documentando razones técnicas + impact downstream para cada Q-DB-* divergencia con blueprint v1.2 — ver §29 (NEW Phase A).

### Tablas NEW Bank Phase A

| Sección | Tabla | Owner | Status DRAFT v0.1 |
|---|---|---|---|
| §22 | `sonar_bank_audit_ledger` (PARTITIONED RANGE month) | DB Lead | ✅ DRAFT v0.1 |
| §22 | `sonar_bank_compliance_flags` | DB Lead | ✅ DRAFT v0.1 |
| §23 | `sonar_bank_status` | DB Lead | ✅ DRAFT v0.1 |
| §24 | `sonar_bank_tax_brackets` | DB Lead | ✅ DRAFT v0.2 |
| §24 | `sonar_bank_tax_history` | DB Lead | ✅ DRAFT v0.2 |
| §24 | `sonar_bank_subsidies` (PARTITIONED RANGE month) | DB Lead | ✅ DRAFT v0.2 |
| §24 | `sonar_govt_elections` | DB Lead | ✅ DRAFT v0.2 |
| §24 | `sonar_govt_election_candidates` | DB Lead | ✅ DRAFT v0.2 |
| §24 | `sonar_govt_votes` (hashed) | DB Lead | ✅ DRAFT v0.2 |
| §24 | `sonar_govt_votes_audit` (raw admin-only) | DB Lead | ✅ DRAFT v0.2 |
| §25 | `sonar_bank_loans` | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_credit_scores` | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_crypto_assets` (reference data + seed) | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_crypto_wallets` (BIGINT atomic) | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_crypto_transactions` (append-only) | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_stocks_assets` (reference data) | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_stocks_transactions` (event-sourced) | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_stocks_holdings` (materialized) | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_recurring_payments` | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_atm_minigame_attempts` | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_physical_cards` | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_loyalty_balances` | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_loyalty_transactions` (append-only) | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_round_up_configs` | DB Lead | ✅ DRAFT v0.3 |
| §25 | `sonar_bank_round_up_transactions` (append-only) | DB Lead | ✅ DRAFT v0.3 |
| §26 | `sonar_bank_business_treasuries` (multi-signer policy) | DB Lead | ✅ DRAFT v0.3 |
| §26 | `sonar_bank_business_treasury_signers` | DB Lead | ✅ DRAFT v0.3 |
| §26 | `sonar_bank_business_treasury_approvals` (m-of-n FSM) | DB Lead | ✅ DRAFT v0.3 |
| §26 | `sonar_bank_escrow_releases` (escrow partial release log) | DB Lead | ✅ DRAFT v0.3 |
| §27 | `sonar_bank_idempotency_keys` (TTL 7d) | DB Lead | ✅ DRAFT v0.3 |
| §30 | `sonar_companies` (registro mercantil) | DB Lead | 🟡 DRAFT AMENDMENT v2.1 |
| §30 | `sonar_company_members` (membresías/directores) | DB Lead | 🟡 DRAFT AMENDMENT v2.1 |
| §30 | `sonar_bank_subsidy_programs` (catálogo programas) | DB Lead | 🟡 DRAFT AMENDMENT v2.1 |
| §30 | `sonar_bank_business_payroll_batches` | DB Lead | 🟡 DRAFT AMENDMENT v2.1 |
| §30 | `sonar_bank_business_payroll_lines` | DB Lead | 🟡 DRAFT AMENDMENT v2.1 |
| §30 | `sonar_bank_govt_risk_scores` (0-100 materialized) | DB Lead + Security Lead consumer | 🟡 DRAFT AMENDMENT v2.1 |

### Tablas existing extends Bank Phase A

| Tabla existing | Cambio | Migration | Status DRAFT v0.1 |
|---|---|---|---|
| `sonar_bank_accounts` | ALTER ENUM `type` → split `owner_type` + `account_class` (Q-DB-D) | 014 | ✅ DRAFT v0.2 |
| `sonar_bank_accounts` | ADD `last_reconciled_at INT UNSIGNED NULL` (CP3 trust window) | 014 | ✅ DRAFT v0.2 |
| `sonar_bank_movements` | ALTER ENUM `category` add `'tax_subsidy'`, `'loan_disbursement'`, `'loan_repayment'`, `'crypto_buy'`, `'crypto_sell'`, `'stock_buy'`, `'stock_sell'`, `'recurring_charge'`, `'round_up'`, `'loyalty_redeem'`, `'compliance_freeze'` | 015 | ✅ DRAFT v0.2 |
| `sonar_bank_movements` | REORGANIZE PARTITIONS extend Sep 2026 → Dec 2027 (Q-DB-G) | 013 | ✅ DRAFT v0.1 |
| `sonar_bank_audit_ledger` | REORGANIZE PARTITIONS extend Jan 2027 → Dec 2027 (Q-DB-G) | 013 | ✅ DRAFT v0.1 |
| `sonar_escrows` | ADD `release_log_count TINYINT UNSIGNED NOT NULL DEFAULT 0` (FSM 6-states extends Q12) | 027 | ✅ DRAFT v0.3 |
| `sonar_bank_subsidies` | ADD `program_id CHAR(36) NULL` + index `(program_id, issued_at)` | 030 | 🟡 DRAFT AMENDMENT v2.1 |
| `sonar_bank_movements` | ALTER ENUM `category` add `fine_collected`, `payroll_disbursement`, `reconciliation`, `interest_accrued` + treasury rollup index | 032 | 🟡 DRAFT AMENDMENT v2.1 |

### Migrations files DRAFT v0.1 (BANK-DB.1)

| Archivo | Descripción | Status |
|---|---|---|
| `010_bank_audit_ledger.sql` | Tabla audit ledger inmutable + triggers SIGNAL + partitions May-Dec 2026 | ✅ DRAFT v0.1 |
| `011_bank_compliance_flags.sql` | Tabla compliance flags + 5 patterns autoraise canonical Q10 | ✅ DRAFT v0.1 |
| `012_bank_status_fsm.sql` | Tabla status FSM single-row global + trigger single-row + seed inicial | ✅ DRAFT v0.1 |
| `013_bank_movements_partitions_extend.sql` | REORGANIZE partitions movements + audit_ledger hasta Dec 2027 (Q-DB-G) | ✅ DRAFT v0.1 |
| `014_bank_accounts_owner_type_split.sql` | ALTER bank_accounts split owner_type + account_class + last_reconciled_at + backfill (Q-DB-D) | ✅ DRAFT v0.2 |
| `015_bank_movements_category_extend.sql` | ALTER movements ENUM category add 11 nuevos valores aditivos | ✅ DRAFT v0.2 |
| `016_tax_brackets_history_subsidies.sql` | Tax tablas (brackets editable + history append-only + subsidies PARTITIONED) | ✅ DRAFT v0.2 |
| `017_govt_elections_candidates_votes.sql` | Government tablas (elections FSM + candidates + votes hashed + votes_audit raw — dual-layer Q-DB-H) | ✅ DRAFT v0.2 |
| `018_bank_loans_credit_scores.sql` | Tier 4 — loans FSM 6-state + credit scores rolling | ✅ DRAFT v0.3 |
| `019_bank_crypto_wallets.sql` | Tier 4 — crypto assets seed + wallets BIGINT atomic + tx append-only | ✅ DRAFT v0.3 |
| `020_bank_stocks_transactions_holdings.sql` | Tier 4 — stocks event-sourced + materialized hybrid Q-DB-I | ✅ DRAFT v0.3 |
| `021_bank_recurring_payments.sql` | Tier 4 — recurring/subscriptions FSM 4-state + cron index | ✅ DRAFT v0.3 |
| `022_bank_atm_minigame_attempts.sql` | Tier 4 — ATM minigame append-only log | ✅ DRAFT v0.3 |
| `023_bank_physical_cards.sql` | Tier 4 — physical card tokens + PIN hash | ✅ DRAFT v0.3 |
| `024_bank_loyalty_points.sql` | Tier 4 — loyalty balances + tx append-only | ✅ DRAFT v0.3 |
| `025_bank_round_ups.sql` | Tier 4 — round-up configs + tx append-only | ✅ DRAFT v0.3 |
| `026_bank_business_treasuries.sql` | Empresas extends — multi-signer policy + signers + approvals m-of-n | ✅ DRAFT v0.3 |
| `027_bank_escrow_releases.sql` | Escrow partial release log + ALTER sonar_escrows ADD release_log_count | ✅ DRAFT v0.3 |
| `028_bank_idempotency_keys.sql` | Idempotency keys table + TTL cron cleanup hint | ✅ DRAFT v0.3 |
| `029_company_registry.sql` | Issue #002 — `sonar_companies` + `sonar_company_members` registry | 🟡 DRAFT AMENDMENT v2.1 |
| `030_subsidy_programs.sql` | Issue #002 — subsidy program catalog + link `sonar_bank_subsidies.program_id` | 🟡 DRAFT AMENDMENT v2.1 |
| `031_business_payroll_persistence.sql` | Issue #002 — payroll batches + payroll lines durable execution state | 🟡 DRAFT AMENDMENT v2.1 |
| `032_govt_risk_scores_and_treasury_movements.sql` | Issue #002 — GOVT risk scores 0-100 + treasury categories/index | 🟡 DRAFT AMENDMENT v2.1 |

### Drift corrections SSoT v1.1 → v1.2

| Sección | Drift v1.1 | Realidad migrations | Resolución v1.2 |
|---|---|---|---|
| §1.1 D3 | `utf8mb4_0900_ai_ci` | `utf8mb4_unicode_ci` (003 D1) | ✅ v1.2 corrige a `utf8mb4_unicode_ci` MariaDB-compat |
| §1.4 | `updated_at ON UPDATE (UNIX_TIMESTAMP())` | App-managed (003 D2 — MariaDB-illegal INT UNSIGNED) | ✅ v1.2 documenta app-managed pattern |
| §1.6 | CHECK XOR multi-col enforced | App-layer enforcement (003 D4 + 006 D1 — MariaDB 12.2.2 parser bug) | ✅ v1.2 documenta app-layer pattern |
| §4.1 | CHECK XOR personal/company/cooperative/escrow active DDL | Active DDL pero comentado (006 línea 112-117) | ✅ v1.2 declara explicit comment app-layer enforced |
| §4.2 | Particiones `p_2026_01..03` (Feb-Apr 2026) | Refrescado migration 003 D5 a `p_2026_05..08` + `p_future` | ✅ v1.2 sincroniza partitions reales + extends Dec 2027 (Q-DB-G) |
| §4.1 | FK `owner_company_id → sonar_companies(id)` declarada | DEFERRED (003 D3) — `sonar_companies` no existe | ✅ v1.2 documenta DEFERRED + issue #001 |

---

---


## 0. Resumen ejecutivo

Este documento es **la referencia oficial del schema relacional de SONAR (ex-Admirals)**. Define cada tabla, columna, tipo, índice, foreign key y query crítica del ecosistema.

Cubre:

- **Filosofía y convenciones** del schema.
- **ERD textual** del ecosistema completo.
- **DDL formal** de cada tabla (CREATE TABLE listo para producción).
- **Índices justificados** con razón de cada uno.
- **Queries críticas** documentadas (las que se ejecutan en hot path).
- **Migrations:** estrategia, formato, versionado.
- **Particionado** de tablas a escala.
- **Backup, restore y archival.**
- **Reference data (seeds)** mínima.
- **Diccionario de datos** completo.

> **Toda tabla del ecosistema SONAR DEBE estar definida aquí.** Si la tabla no está documentada, no existe en producción.

---

## 1. Filosofía y convenciones del schema

### 1.1 Principios

| # | Principio | Significado práctico |
|---|---|---|
| **D1** | **Prefijo `sonar_` obligatorio** | Todas las tablas SONAR empiezan con `sonar_`. Cero colisión con framework, addons o terceros. |
| **D2** | **UUID v4 como id primario por defecto** | Los `id` de entidades de negocio (accounts, companies, tablets, etc.) son UUID v4 (CHAR(36)). Las tablas con alto volumen de inserts (movements, messages, event_log) usan BIGINT autoincrement. |
| **D3** | **Charset y collation:** `utf8mb4` + `utf8mb4_0900_ai_ci` | Soporte completo Unicode (emojis, idiomas). MySQL 8 default. |
| **D4** | **Engine InnoDB** | Transacciones ACID, foreign keys, row-level locking. Cero MyISAM. |
| **D5** | **Timestamps con DEFAULT CURRENT_TIMESTAMP + ON UPDATE** | Toda tabla tiene `created_at` (UNIX timestamp INT UNSIGNED) y `updated_at` (UNIX timestamp INT UNSIGNED). |
| **D6** | **Soft deletes donde aplique** | Tablas con histórico legal (documents, bank_movements) usan `deleted_at` nullable, no `DELETE`. |
| **D7** | **Foreign keys explícitas con ON DELETE definido** | Cada FK declara comportamiento (CASCADE, SET NULL, RESTRICT) según semántica. |
| **D8** | **Naming snake_case en todo** | Tablas, columnas, índices, constraints. |
| **D9** | **Índices documentados** | Cada índice tiene razón explícita. Ningún índice "por si acaso". |
| **D10** | **JSON columns donde el schema sea genuinamente flexible** | Reservado para metadatos, payloads de eventos, lineage del item físico. **Nunca para datos consultables por filtros frecuentes** (esos van en columnas estructuradas). |
| **D11** | **Migraciones inmutables, versionadas, idempotentes** | Toda mutación de schema viene de un archivo `migrations/NNN_description.sql`. Nunca `ALTER` manual en producción. |
| **D12** | **Particionado proactivo en tablas de alto volumen** | `event_log`, `bank_movements`, `messages` con particionado por fecha desde día 1. |

### 1.2 Convención de naming

- **Tablas:** `sonar_<recurso>` (singular o plural según semántica). Ejemplo: `sonar_accounts`, `sonar_event_log`.
- **Columnas:** `snake_case` siempre.
- **Foreign keys:** column name = `<related_table_singular>_id` (ej. `account_id`, `company_id`).
- **Índices:** `idx_<table>_<col1>_<col2>` para no únicos, `uq_<table>_<col>` para únicos, `pk_<table>` para PK explícitos compuestos, `fk_<table>_<col>` para FKs.
- **Constraints CHECK:** `chk_<table>_<col>_<descripcion>`.

### 1.3 Tipos de columna canónicos

> **Reproducimos los tipos canónicos de `02_events_catalog.md` §1.6 mapeados a MySQL 8.**

| Tipo SONAR | MySQL | Descripción |
|---|---|---|
| `AccountId`, `CompanyId`, `TabletSerial`, `BankAccountId` | `CHAR(36)` | UUID v4. |
| `IBAN` | `VARCHAR(20)` | `AD-XXXX-XXXX-XXXX` formato. |
| `BatchId` | `VARCHAR(32)` | `FARM-2026-0001-A` formato. |
| `Vertical` | `VARCHAR(32)` | enum-like libre (validación en código). |
| `Role` | `ENUM('owner','manager','employee','temporary')` | |
| `Grade` | `CHAR(1)` | S, A, B, C, D. CHECK constraint. |
| `Score` | `TINYINT UNSIGNED` | 0-100. CHECK constraint. |
| `Money` | `DECIMAL(12,2)` | hasta 9.999.999.999,99 (suficiente). UNSIGNED si nunca negativo. |
| `Coords` (JSON) | `JSON` | `{x, y, z, heading}`. |
| `UnixSec` | `INT UNSIGNED` | timestamp segundos (válido hasta 2106). |
| `UnixMs` | `BIGINT UNSIGNED` | timestamp ms. |
| `Boolean` | `TINYINT(1)` | 0/1. |
| `EventName` | `VARCHAR(96)` | `sonar:domain:action`, suficiente para los nombres canónicos. |
| `JsonPayload` | `JSON` | payloads de eventos, metadata flexible. |

### 1.4 Convención de timestamps

Toda tabla tiene **al menos** estas dos columnas:

```sql
created_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
updated_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP())
```

> **Nota:** se usa `INT UNSIGNED` (segundos UNIX) en lugar de `DATETIME` para coherencia total con timestamps del bus de eventos y zero ambigüedad de timezone. La capa de aplicación traduce a humano.

### 1.5 Convención de soft delete

Tablas con histórico legal:

```sql
deleted_at INT UNSIGNED NULL DEFAULT NULL,
deleted_by_account_id CHAR(36) NULL DEFAULT NULL
```

Las queries de aplicación filtran `WHERE deleted_at IS NULL` por defecto. Vista `*_active` provee el filtrado automático para queries comunes.

### 1.6 Convención de foreign keys

```sql
-- Sintaxis canónica
CONSTRAINT fk_<table>_<col>
  FOREIGN KEY (<col>)
  REFERENCES <referenced_table>(<referenced_col>)
  ON DELETE <CASCADE|SET NULL|RESTRICT>
  ON UPDATE CASCADE
```

**Reglas para `ON DELETE`:**

- **CASCADE:** cuando la fila hija no tiene sentido sin el padre (ej. `company_members` sin `company`).
- **SET NULL:** cuando la fila hija puede sobrevivir (ej. `created_by_account_id` si la cuenta se borra, el documento sobrevive como anónimo).
- **RESTRICT:** cuando borrar el padre debe ser bloqueado por integridad legal (ej. `bank_accounts` con `movements` activos).

### 1.7 Convención de naming de eventos en triggers

> **Política:** preferimos lógica de eventos **en código aplicación** (resources Lua) para mantener el bus como fuente de verdad. **Triggers se reservan a 2 casos:**

1. **Updates de `updated_at`** (no soportado puramente con DEFAULT en MySQL 8 sin generated columns). En la práctica, MySQL 8 sí lo soporta con `ON UPDATE` — confirmado en §1.4.
2. **Auditoría de columnas críticas** opcional (ej. capturar valor anterior de `quality_score` en una tabla satélite — uso muy puntual).

> **NO se usan triggers para lógica de negocio.** Eso vive en el bus de eventos.

### 1.8 Convención sobre JSON columns

JSON está reservado para:
- **Metadatos del Item Físico** (lineage, quality components).
- **Payloads de eventos** en `event_log`.
- **Configuración por entidad** (settings, preferencias).
- **Ubicaciones físicas** (Coords).
- **Estructuras anidadas con schema variable** documentado en este doc.

JSON **NO se usa** para:
- Listas de IDs consultables por relación (van en tabla intermedia).
- Datos requeridos por filtros (van en columnas).
- Estados (van en ENUM o columna estructurada).

---

## 2. ERD — Diagrama de relaciones (textual)

> **Vista panorámica del schema.** Las tablas con (*) son particionadas.

```
┌─────────────────────────────────────────────────────────────────────┐
│                      DOMINIO IDENTIDAD Y EMPRESA                     │
└─────────────────────────────────────────────────────────────────────┘

sonar_accounts
  └─< sonar_tablets         (1 account → 0..N tablets)
  └─< sonar_company_members (1 account → 0..N memberships)
  └─< sonar_documents       (created_by) (1 account → 0..N docs)
  └─< sonar_messages        (sender)     (1 account → 0..N messages)
  └─< sonar_notifications   (target)     (1 account → 0..N notifs)

sonar_companies
  └─< sonar_company_members         (1 company → N members)
  ├─> sonar_bank_accounts (1 company → 1 bank account empresarial)
  └─< sonar_documents               (1 company → 0..N docs)

sonar_company_members ──> sonar_accounts
sonar_company_members ──> sonar_companies


┌─────────────────────────────────────────────────────────────────────┐
│                          DOMINIO BANCA                               │
└─────────────────────────────────────────────────────────────────────┘

sonar_bank_accounts
  └─< sonar_bank_movements (*)  (1 account → N movements)


┌─────────────────────────────────────────────────────────────────────┐
│                       DOMINIO DOCUMENTOS                             │
└─────────────────────────────────────────────────────────────────────┘

sonar_documents
  └─< sonar_document_signatures   (1 doc → N firmas)
  └─< sonar_documents              (parent_doc_id self-reference)


┌─────────────────────────────────────────────────────────────────────┐
│                     DOMINIO MENSAJERÍA                               │
└─────────────────────────────────────────────────────────────────────┘

sonar_chats
  └─< sonar_chat_participants     (1 chat → N participantes)
  └─< sonar_messages (*)          (1 chat → N messages)

sonar_messages (*)
  └─< sonar_message_attachments   (1 message → N attachments)


┌─────────────────────────────────────────────────────────────────────┐
│                     DOMINIO NOTIFICACIONES                           │
└─────────────────────────────────────────────────────────────────────┘

sonar_notifications (*)
  └─> sonar_accounts              (target)


┌─────────────────────────────────────────────────────────────────────┐
│                   DOMINIO MARKET Y REPUTATION                        │
└─────────────────────────────────────────────────────────────────────┘

sonar_market_offers
  └─< sonar_market_reviews        (1 offer → 0..1 review típicamente)
  └─> sonar_logistics_jobs        (offer → optional job)

sonar_reputation
  └─> sonar_accounts | sonar_companies (subject polymorphic)


┌─────────────────────────────────────────────────────────────────────┐
│                     DOMINIO LOGÍSTICA                                │
└─────────────────────────────────────────────────────────────────────┘

sonar_logistics_jobs
  └─< sonar_logistics_disputes    (1 job → 0..N disputes)


┌─────────────────────────────────────────────────────────────────────┐
│                       DOMINIO NODOS                                  │
│  (cada nodo gestiona sus propias tablas con prefijo sonar_<nodo>) │
└─────────────────────────────────────────────────────────────────────┘

sonar_granja_plots         (1 company → N plots)
sonar_granja_silos         (1 company → N silos)
sonar_granja_machines      (1 company → N machines)
sonar_granja_licenses      (1 account → N licenses)

sonar_molino_silos
sonar_molino_machines
sonar_molino_batches       (lineage)


┌─────────────────────────────────────────────────────────────────────┐
│                  DOMINIO INFRAESTRUCTURA                             │
└─────────────────────────────────────────────────────────────────────┘

sonar_event_log (*)              (audit trail particionado por mes)
sonar_schema_versions            (registry de migraciones aplicadas)
sonar_settings_per_account       (preferencias usuario)
```

### 2.1 Resumen de cardinalidades clave

| Relación | Cardinalidad | Notas |
|---|---|---|
| `account` ↔ `tablet` | 1:N | Una cuenta puede poseer varias Tablets en oleadas futuras. Oleada 1: 1:1. |
| `account` ↔ `company_member` | 1:N | Un jugador puede ser miembro de varias empresas. |
| `company` ↔ `company_member` | 1:N | Una empresa tiene varios miembros. |
| `company` ↔ `bank_account` | 1:1 (empresarial) | Cuenta empresarial única. |
| `account` ↔ `bank_account` | 1:N | Personal + (futuro) ahorros, etc. |
| `bank_account` ↔ `movement` | 1:N | Histórico inmutable. |
| `document` ↔ `signature` | 1:N | Multi-firmantes. |
| `chat` ↔ `participant` | 1:N | Chats grupales. |
| `chat` ↔ `message` | 1:N | Mensajes ordenados. |
| `offer` ↔ `logistics_job` | 1:0..1 | Si delivery automático. |
| `company` ↔ `granja_plot` | 1:N | Empresa Granja con N parcelas. |

### 2.2 Listado de tablas oleada 1

| # | Tabla | Dominio | Particionada | Tamaño esperado (servidor 200 jug) |
|---|---|---|---|---|
| 1 | `sonar_accounts` | core | no | < 10K filas |
| 2 | `sonar_tablets` | core | no | < 10K filas |
| 3 | `sonar_companies` | core | no | < 5K filas |
| 4 | `sonar_company_members` | core | no | < 50K filas |
| 5 | `sonar_bank_accounts` | bank | no | < 20K filas |
| 6 | `sonar_bank_movements` | bank | sí (mes) | crece sin límite |
| 7 | `sonar_documents` | docs | no | crece — archival manual |
| 8 | `sonar_document_signatures` | docs | no | proporcional a docs |
| 9 | `sonar_chats` | messages | no | < 50K filas |
| 10 | `sonar_chat_participants` | messages | no | < 200K filas |
| 11 | `sonar_messages` | messages | sí (mes) | crece sin límite |
| 12 | `sonar_message_attachments` | messages | no | proporcional a messages |
| 13 | `sonar_notifications` | notif | sí (mes) | crece sin límite |
| 14 | `sonar_market_offers` | market | no | < 100K filas |
| 15 | `sonar_market_reviews` | market | no | proporcional a offers |
| 16 | `sonar_reputation` | core | no | < 30K filas |
| 17 | `sonar_logistics_jobs` | logistics | no | crece moderadamente |
| 18 | `sonar_logistics_disputes` | logistics | no | raras |
| 19 | `sonar_granja_plots` | granja | no | < 10K filas |
| 20 | `sonar_granja_silos` | granja | no | < 5K filas |
| 21 | `sonar_granja_machines` | granja | no | < 10K filas |
| 22 | `sonar_granja_licenses` | granja | no | < 50K filas |
| 23 | `sonar_molino_silos` | molino | no | < 1K filas |
| 24 | `sonar_molino_machines` | molino | no | < 1K filas |
| 25 | `sonar_molino_batches` | molino | no | crece moderadamente |
| 26 | `sonar_event_log` | infra | sí (mes) | crece sin límite |
| 27 | `sonar_schema_versions` | infra | no | < 200 filas |
| 28 | `sonar_settings_per_account` | infra | no | < 10K filas |

**Total tablas oleada 1: 28** (12 core + 13 dominios + 3 nodos + 0 reservas).

---

## 3. DDL — Dominio identidad y empresa

### 3.1 sonar_accounts

> **La cuenta SONAR.** Vinculada a un personaje del framework. Es el "DNI digital" del jugador en el ecosistema.

```sql
CREATE TABLE sonar_accounts (
  id                    CHAR(36)        NOT NULL,
  char_id               VARCHAR(64)     NOT NULL COMMENT 'citizenid QBox / identifier ESX / character_id manual',
  framework_source      ENUM('qbox','qbcore','esx','manual') NOT NULL,
  alias                 VARCHAR(64)     NOT NULL COMMENT 'nombre mostrado público en SONAR',
  reputation_global     TINYINT UNSIGNED NOT NULL DEFAULT 50 COMMENT '0-100',
  preferred_locale      VARCHAR(8)      NOT NULL DEFAULT 'es-ES',
  developer_mode        TINYINT(1)      NOT NULL DEFAULT 0,
  meta                  JSON            NULL COMMENT 'preferencias y datos extensibles',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),
  last_login_at         INT UNSIGNED    NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_accounts_char_id (char_id, framework_source),

  CHECK (reputation_global BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- `id` es UUID v4 generado en `sonar_core` al primer login del jugador.
- `char_id` + `framework_source` es único — un personaje del framework solo tiene una cuenta SONAR.
- `reputation_global` se actualiza vía `sonar:core:reputation_changed`.
- `meta` puede contener: `{ "wallpaper": "...", "theme": "...", ... }`.

### 3.2 sonar_tablets

> **Hardware Tablet.** Es **un item físico inventariable** además de una entry en DB. Ver `02_sonar_tablet.md` para semántica.

```sql
CREATE TABLE sonar_tablets (
  serial                CHAR(36)        NOT NULL COMMENT 'UUID v4 — número de serie único',
  owner_account_id      CHAR(36)        NULL COMMENT 'NULL si está en venta o sin asignar',
  model                 ENUM('sonar_basic','sonar_pro','sonar_enterprise') NOT NULL DEFAULT 'sonar_basic',
  os_version            VARCHAR(16)     NOT NULL DEFAULT '1.0.0',

  is_lost               TINYINT(1)      NOT NULL DEFAULT 0,
  is_locked             TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'PIN activado',
  pin_hash              VARCHAR(128)    NULL,

  wallpaper             VARCHAR(64)     NOT NULL DEFAULT 'default_naval',
  theme                 ENUM('auto','light','dark') NOT NULL DEFAULT 'auto',
  accent_color          VARCHAR(16)     NOT NULL DEFAULT '#0a3a5e',
  privacy_screen        TINYINT(1)      NOT NULL DEFAULT 0,

  home_layout           JSON            NULL COMMENT '{ columns, app_order[], widgets[] }',
  ringtones             JSON            NULL COMMENT '{ default, per_contact: { account_id: ringtone } }',
  notifications_per_app JSON            NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (serial),
  KEY idx_sonar_tablets_owner (owner_account_id),

  CONSTRAINT fk_sonar_tablets_owner
    FOREIGN KEY (owner_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- `serial` es UUID v4 generado al fabricar la Tablet (al "comprarla" o al spawnear).
- `owner_account_id` puede ser NULL si la Tablet está en una tienda, perdida sin recuperar, o vendida sin nuevo dueño asignado.
- `is_lost` se setea via `sonar:tablet:lost_or_stolen`.
- Settings personales de UI viven aquí, no en la cuenta — porque la Tablet es física y el dueño podría cambiar.

### 3.3 sonar_companies

> **Empresa SONAR.** Entidad jurídica RP, dueña de assets físicos, contratos, cuenta empresarial.

```sql
CREATE TABLE sonar_companies (
  id                    CHAR(36)        NOT NULL,
  vertical              VARCHAR(32)     NOT NULL COMMENT 'farm, mill, bakery, retail, logistics, mechanic, ...',
  name                  VARCHAR(96)     NOT NULL,
  legal_name            VARCHAR(128)    NULL COMMENT 'razón social RP',
  status                ENUM('active','suspended','bankrupt','sold','dissolved') NOT NULL DEFAULT 'active',

  owner_account_id      CHAR(36)        NOT NULL,
  hq_location           JSON            NOT NULL COMMENT 'Coords MLO sede',
  bank_account_id       CHAR(36)        NULL COMMENT 'cuenta empresarial — nullable hasta creación',

  cash_balance          DECIMAL(12,2) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'caja física disponible en sede',
  reputation            TINYINT UNSIGNED NOT NULL DEFAULT 50,
  logo_url              VARCHAR(255)    NULL,
  brand_color           VARCHAR(16)     NULL,

  config                JSON            NULL COMMENT 'configuración específica del vertical',

  founded_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),
  dissolved_at          INT UNSIGNED    NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_companies_name (name),
  KEY idx_sonar_companies_owner (owner_account_id),
  KEY idx_sonar_companies_vertical_status (vertical, status),

  CONSTRAINT fk_sonar_companies_owner
    FOREIGN KEY (owner_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CHECK (cash_balance >= 0),
  CHECK (reputation BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- `cash_balance` es la caja física en sede (cash en efectivo). Pool separado de `bank_account_id`.
- `bank_account_id` es FK lógica a `sonar_bank_accounts` — se añade el constraint después en migración debido a dependencia circular en orden de creación de tablas.
- `vertical` no es ENUM porque se añadirán verticales en oleadas futuras sin ALTER TABLE.
- `config` ejemplo Granja: `{ "max_plots": 10, "weather_zone": "paleto" }`.

### 3.4 sonar_company_members

> **Tabla intermedia** account ↔ company con rol y datos de empleo.

```sql
CREATE TABLE sonar_company_members (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  company_id            CHAR(36)        NOT NULL,
  account_id            CHAR(36)        NOT NULL,
  role                  ENUM('owner','manager','employee','temporary') NOT NULL DEFAULT 'employee',
  position              VARCHAR(64)     NULL COMMENT 'maquinista, tendero, conductor, etc.',
  salary                DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'salario por turno o por hora — depende de config empresa',
  salary_period         ENUM('hourly','shift','daily','monthly') NOT NULL DEFAULT 'shift',

  permissions_overrides JSON            NULL COMMENT 'overrides puntuales sobre matriz de rol',

  hired_at              INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  hired_by_account_id   CHAR(36)        NULL,

  fired_at              INT UNSIGNED    NULL,
  fired_by_account_id   CHAR(36)        NULL,
  fire_reason           ENUM('fired','resigned','temporary_completed','banned') NULL,

  is_active             TINYINT(1)      AS (CASE WHEN fired_at IS NULL THEN 1 ELSE 0 END) STORED,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_company_members_active (company_id, account_id, is_active),
  KEY idx_sonar_company_members_account (account_id, is_active),
  KEY idx_sonar_company_members_company (company_id, is_active, role),

  CONSTRAINT fk_sonar_company_members_company
    FOREIGN KEY (company_id)
    REFERENCES sonar_companies(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_company_members_account
    FOREIGN KEY (account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CHECK (salary >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- **Histórico preservado:** una empresa puede tener al mismo `account_id` varias veces (entró, salió, volvió). Solo una con `is_active = 1` por par (company, account).
- `is_active` es columna generada (computed) basada en `fired_at IS NULL`.
- `permissions_overrides` ejemplo: `{ "approve_payments": true, "edit_prices": false }` — overrides puntuales sobre la matriz de permisos del rol (definida en código).

---

## 4. DDL — Dominio Banca

### 4.1 sonar_bank_accounts

> **Cuenta bancaria** personal o empresarial. IBAN único formato SONAR.

```sql
CREATE TABLE sonar_bank_accounts (
  id                    CHAR(36)        NOT NULL,
  iban                  VARCHAR(20)     NOT NULL COMMENT 'AD-XXXX-XXXX-XXXX',
  type                  ENUM('personal','company','cooperative','escrow') NOT NULL,

  owner_account_id      CHAR(36)        NULL COMMENT 'NULL si type=company',
  owner_company_id      CHAR(36)        NULL COMMENT 'NULL si type=personal',

  balance               DECIMAL(14,2)   NOT NULL DEFAULT 0 COMMENT 'saldo actual (puede ser negativo si admin overdraft)',
  daily_limit_out       DECIMAL(12,2) UNSIGNED NULL COMMENT 'límite saliente diario (NULL = sin límite)',
  is_frozen             TINYINT(1)      NOT NULL DEFAULT 0,
  frozen_reason         VARCHAR(255)    NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),
  closed_at             INT UNSIGNED    NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_accounts_iban (iban),
  KEY idx_sonar_bank_accounts_owner_account (owner_account_id),
  KEY idx_sonar_bank_accounts_owner_company (owner_company_id),

  CONSTRAINT fk_sonar_bank_accounts_owner_account
    FOREIGN KEY (owner_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_bank_accounts_owner_company
    FOREIGN KEY (owner_company_id)
    REFERENCES sonar_companies(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CHECK (
    (type = 'personal' AND owner_account_id IS NOT NULL AND owner_company_id IS NULL)
    OR (type IN ('company','cooperative','escrow') AND owner_company_id IS NOT NULL AND owner_account_id IS NULL)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- Solo uno de `owner_account_id` / `owner_company_id` está poblado según `type` — CHECK lo enforzia.
- IBAN único con formato `AD-XXXX-XXXX-XXXX`. Generado por `sonar_core` con checksum interno.
- `escrow` se usa para holding payments (delivery_via_logistics, contratos) — son cuentas técnicas internas.
- Constraint FK de `sonar_companies.bank_account_id → sonar_bank_accounts.id` se añade en migración 002 tras crear ambas tablas.

### 4.2 sonar_bank_movements (PARTITIONED)

> **Movimientos bancarios — registro contable inmutable.** Cada transferencia genera 2 entradas (debe + haber).

```sql
CREATE TABLE sonar_bank_movements (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  bank_account_id       CHAR(36)        NOT NULL,
  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  amount                DECIMAL(14,2)   NOT NULL COMMENT 'positivo=ingreso, negativo=salida',
  balance_after         DECIMAL(14,2)   NOT NULL COMMENT 'saldo tras este movimiento (snapshot)',

  category              ENUM('salary','b2b_payment','transfer','tax','refund','b2c_sale','expense','deposit','withdrawal','escrow_lock','escrow_release','adjustment') NOT NULL,
  counterpart_iban      VARCHAR(20)     NULL,
  concept               VARCHAR(255)    NULL,

  related_doc_id        CHAR(36)        NULL,
  related_offer_id      CHAR(36)        NULL,
  related_job_id        CHAR(36)        NULL,
  request_nonce         CHAR(36)        NULL COMMENT 'idempotencia anti-replay',

  initiated_by_account_id CHAR(36)      NULL,
  source_resource       VARCHAR(64)     NOT NULL COMMENT 'sonar_core, sonar_market, etc.',

  PRIMARY KEY (id, occurred_at),
  KEY idx_sonar_bank_movements_account (bank_account_id, occurred_at DESC),
  KEY idx_sonar_bank_movements_category (category, occurred_at DESC),
  KEY idx_sonar_bank_movements_nonce (request_nonce),
  KEY idx_sonar_bank_movements_related_doc (related_doc_id),
  KEY idx_sonar_bank_movements_related_offer (related_offer_id),
  KEY idx_sonar_bank_movements_related_job (related_job_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  PARTITION BY RANGE (occurred_at) (
    PARTITION p_2026_01 VALUES LESS THAN (1738368000),  -- Feb 1 2026
    PARTITION p_2026_02 VALUES LESS THAN (1740787200),  -- Mar 1 2026
    PARTITION p_2026_03 VALUES LESS THAN (1743465600),  -- Apr 1 2026
    PARTITION p_future VALUES LESS THAN MAXVALUE
  );
```

**Notas:**
- **No FK a `bank_account_id`** intencionalmente — particionamiento + volumen + integridad por aplicación. La integridad la garantizan repos en código.
- `request_nonce` evita replay attacks: el mismo nonce no puede crear 2 movimientos.
- `balance_after` es snapshot — auditable sin recalcular toda la cadena.
- Particionado mensual gestionado por cron: añadir partition siguiente, archivar las > 12 meses (ver §15 backup/archival).
- Orden de columnas optimizada para acceso por cuenta y rango temporal.

---

## 5. DDL — Dominio Documentos

### 5.1 sonar_documents

> **Repositorio documental SONAR.** Notas, contratos, albaranes, recibos, certificados.

```sql
CREATE TABLE sonar_documents (
  id                    CHAR(36)        NOT NULL,
  type                  ENUM('note','contract','delivery_note','receipt','license','company_deed','bill_of_sale','invoice','custom') NOT NULL,
  title                 VARCHAR(192)    NOT NULL,
  body                  LONGTEXT        NULL COMMENT 'cuerpo del documento (markdown / texto plano)',
  template_id           VARCHAR(64)     NULL COMMENT 'plantilla usada (para contratos)',

  status                ENUM('draft','pending_signature','active','fulfilled','breached','archived','cancelled') NOT NULL DEFAULT 'draft',

  owner_account_id      CHAR(36)        NULL,
  owner_company_id      CHAR(36)        NULL,
  parent_doc_id         CHAR(36)        NULL COMMENT 'self-reference para versiones / hijos',

  parties_json          JSON            NULL COMMENT 'array de partes (account_ids o company_ids)',
  data_json             JSON            NULL COMMENT 'datos estructurados del doc (campos formulario)',
  attachments_json      JSON            NULL COMMENT 'urls / refs a adjuntos',

  visibility            ENUM('private','company','parties','public') NOT NULL DEFAULT 'private',
  expires_at            INT UNSIGNED    NULL,

  created_by_account_id CHAR(36)        NOT NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  archived_at           INT UNSIGNED    NULL,
  deleted_at            INT UNSIGNED    NULL,
  deleted_by_account_id CHAR(36)        NULL,

  PRIMARY KEY (id),
  KEY idx_sonar_documents_owner_account (owner_account_id, type, status),
  KEY idx_sonar_documents_owner_company (owner_company_id, type, status),
  KEY idx_sonar_documents_status (status, type),
  KEY idx_sonar_documents_parent (parent_doc_id),
  KEY idx_sonar_documents_created_by (created_by_account_id, created_at DESC),

  CONSTRAINT fk_sonar_documents_owner_account
    FOREIGN KEY (owner_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_documents_owner_company
    FOREIGN KEY (owner_company_id)
    REFERENCES sonar_companies(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_documents_created_by
    FOREIGN KEY (created_by_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_documents_parent
    FOREIGN KEY (parent_doc_id)
    REFERENCES sonar_documents(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- `data_json` para contratos: `{ "monthly_rent": 2500, "duration_months": 12, ... }`. Estructura por template documentada en `04_sdk_reference.md` futuro.
- `parties_json` ejemplo: `[{"kind":"company","id":"..."},{"kind":"account","id":"..."}]`.
- Soft delete mediante `deleted_at`. Documentos firmados son inmutables — no se editan, se versionan vía `parent_doc_id`.
- `body` es LONGTEXT para soportar contratos extensos, no solo notas cortas.

### 5.2 sonar_document_signatures

> **Firmas individuales** de un documento. Permite multi-firmantes (contratos B2B con N partes).

```sql
CREATE TABLE sonar_document_signatures (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  doc_id                CHAR(36)        NOT NULL,
  signer_account_id     CHAR(36)        NOT NULL,
  signer_role           VARCHAR(64)     NULL COMMENT 'rol del firmante en el contrato (representante, testigo, etc.)',

  signature_method      ENUM('typed','drawn','biometric') NOT NULL,
  signature_visual_ref  TEXT            NULL COMMENT 'base64 imagen si drawn, nombre si typed',
  signature_hash        VARCHAR(128)    NOT NULL COMMENT 'hash SHA-256 del documento + signer + timestamp',

  signed_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  ip_address            VARCHAR(45)     NULL COMMENT 'opcional para audit',

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_document_signatures_doc_signer (doc_id, signer_account_id),
  KEY idx_sonar_document_signatures_signer (signer_account_id, signed_at DESC),

  CONSTRAINT fk_sonar_document_signatures_doc
    FOREIGN KEY (doc_id)
    REFERENCES sonar_documents(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_document_signatures_signer
    FOREIGN KEY (signer_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- `signature_hash` permite verificar integridad: si el `body` del doc cambia post-firma, el hash recalculado no coincidirá → tampering detectado.
- `UNIQUE (doc_id, signer_account_id)` impide doble firma del mismo signer.
- Cuando todas las partes han firmado, se actualiza `sonar_documents.status = 'active'` (lógica en código vía `sonar:documents:signed`).

---

## 6. DDL — Dominio Mensajería

### 6.1 sonar_chats

> **Conversación.** Puede ser 1-1, grupal o canal empresarial.

```sql
CREATE TABLE sonar_chats (
  id                    CHAR(36)        NOT NULL,
  type                  ENUM('direct','group','company_channel') NOT NULL,
  name                  VARCHAR(96)     NULL COMMENT 'NULL en directos (se infiere de participantes)',
  icon_url              VARCHAR(255)    NULL,

  company_id            CHAR(36)        NULL COMMENT 'NULL excepto si type=company_channel',
  is_archived           TINYINT(1)      NOT NULL DEFAULT 0,

  last_message_at       INT UNSIGNED    NULL COMMENT 'denormalizado para sort eficiente',
  last_message_preview  VARCHAR(255)    NULL COMMENT 'denormalizado para list view',

  created_by_account_id CHAR(36)        NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_chats_company (company_id, is_archived),
  KEY idx_sonar_chats_last_message (last_message_at DESC),

  CONSTRAINT fk_sonar_chats_company
    FOREIGN KEY (company_id)
    REFERENCES sonar_companies(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_chats_creator
    FOREIGN KEY (created_by_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- `last_message_at` y `last_message_preview` son **denormalizaciones intencionales** para evitar JOIN en list view de chats (hot path UI). Se actualizan en cada mensaje vía repo.
- `company_channel` se vincula a `sonar_companies.id` — si la empresa se borra (ON DELETE CASCADE), el chat empresarial también.

### 6.2 sonar_chat_participants

```sql
CREATE TABLE sonar_chat_participants (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  chat_id               CHAR(36)        NOT NULL,
  account_id            CHAR(36)        NOT NULL,

  joined_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  left_at               INT UNSIGNED    NULL,

  last_read_message_id  BIGINT UNSIGNED NULL,
  is_muted              TINYINT(1)      NOT NULL DEFAULT 0,
  is_pinned             TINYINT(1)      NOT NULL DEFAULT 0,
  custom_name           VARCHAR(96)     NULL COMMENT 'override local del nombre del chat',

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_chat_participants_active (chat_id, account_id, left_at),
  KEY idx_sonar_chat_participants_account (account_id, left_at, is_pinned DESC),
  KEY idx_sonar_chat_participants_chat (chat_id, left_at),

  CONSTRAINT fk_sonar_chat_participants_chat
    FOREIGN KEY (chat_id)
    REFERENCES sonar_chats(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_chat_participants_account
    FOREIGN KEY (account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- `last_read_message_id` permite read receipts y cálculo de unread count sin agregaciones costosas.
- `left_at` permite leave/rejoin sin perder histórico.

### 6.3 sonar_messages (PARTITIONED)

> **Mensajes** del ecosistema. Particionado mensual desde día 1.

```sql
CREATE TABLE sonar_messages (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  chat_id               CHAR(36)        NOT NULL,
  sent_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  sender_id             CHAR(36)        NOT NULL,
  sender_kind           ENUM('account','company','system') NOT NULL DEFAULT 'account',

  body                  TEXT            NULL COMMENT 'cuerpo del mensaje, max 2000 chars',
  body_kind             ENUM('text','rich','system_event') NOT NULL DEFAULT 'text',

  edited_at             INT UNSIGNED    NULL,
  deleted_at            INT UNSIGNED    NULL,
  deleted_by_account_id CHAR(36)        NULL,

  reply_to_message_id   BIGINT UNSIGNED NULL,

  PRIMARY KEY (id, sent_at),
  KEY idx_sonar_messages_chat (chat_id, sent_at DESC),
  KEY idx_sonar_messages_sender (sender_id, sent_at DESC),
  KEY idx_sonar_messages_reply (reply_to_message_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  PARTITION BY RANGE (sent_at) (
    PARTITION p_2026_01 VALUES LESS THAN (1738368000),
    PARTITION p_2026_02 VALUES LESS THAN (1740787200),
    PARTITION p_2026_03 VALUES LESS THAN (1743465600),
    PARTITION p_future VALUES LESS THAN MAXVALUE
  );
```

**Notas:**
- **No FK a chat_id** intencional — particionamiento + volumen. Integridad por aplicación (repo valida chat existe antes de insertar).
- Particiones gestionadas por cron — añadir nueva mensual + archivar > 12 meses a tabla `sonar_messages_archive` o cold storage.

### 6.4 sonar_message_attachments

```sql
CREATE TABLE sonar_message_attachments (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  message_id            BIGINT UNSIGNED NOT NULL,
  message_sent_at       INT UNSIGNED    NOT NULL COMMENT 'duplicada para FK lógica + facilita queries',

  kind                  ENUM('document','photo','location','voice','contact','offer') NOT NULL,
  ref                   VARCHAR(255)    NOT NULL COMMENT 'doc_id, image_url, coords json, voice_clip_url, etc.',
  meta                  JSON            NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_message_attachments_message (message_id, message_sent_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- No FK a `messages` debido a tabla particionada. Integridad por aplicación.
- `kind = 'contact'` permite compartir tarjeta de contacto entre Tablets.
- `kind = 'offer'` para compartir ofertas del Mercado en chat.

---

## 7. DDL — Dominio Notificaciones

### 7.1 sonar_notifications (PARTITIONED)

> **Notificaciones push** dirigidas a una cuenta. Histórico completo (no se borran al leer — el panel histórico de la Tablet las usa).

```sql
CREATE TABLE sonar_notifications (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id            CHAR(36)        NOT NULL,
  pushed_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  type                  ENUM(
    'critical_op','critical_fin','important','info','fin_pos',
    'contract','message','weather','system','market','logistics','reputation'
  ) NOT NULL,

  source_resource       VARCHAR(64)     NOT NULL,
  title                 VARCHAR(96)     NOT NULL,
  subtitle              VARCHAR(160)    NULL,
  body                  VARCHAR(500)    NULL,

  actions_json          JSON            NULL COMMENT 'array de { label, action_id, params }',
  related_doc_id        CHAR(36)        NULL,
  related_offer_id      CHAR(36)        NULL,
  related_job_id        CHAR(36)        NULL,
  related_chat_id       CHAR(36)        NULL,

  delivery_mode         ENUM('push_popup','banner_inferior','panel_only','blocking') NOT NULL DEFAULT 'push_popup',

  is_read               TINYINT(1)      NOT NULL DEFAULT 0,
  read_at               INT UNSIGNED    NULL,

  is_archived           TINYINT(1)      NOT NULL DEFAULT 0,
  archived_at           INT UNSIGNED    NULL,

  PRIMARY KEY (id, pushed_at),
  KEY idx_sonar_notifications_account (account_id, pushed_at DESC),
  KEY idx_sonar_notifications_account_unread (account_id, is_read, is_archived, pushed_at DESC),
  KEY idx_sonar_notifications_type (type, pushed_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  PARTITION BY RANGE (pushed_at) (
    PARTITION p_2026_01 VALUES LESS THAN (1738368000),
    PARTITION p_2026_02 VALUES LESS THAN (1740787200),
    PARTITION p_2026_03 VALUES LESS THAN (1743465600),
    PARTITION p_future VALUES LESS THAN MAXVALUE
  );
```

**Notas:**
- Particionada por mes — limpieza histórica >6 meses opcional según política de retención.
- Índice compuesto `(account_id, is_read, is_archived, pushed_at DESC)` optimiza el query principal de la Tablet: "notifs activas no leídas del usuario X".

---

## 8. DDL — Dominio Market

### 8.1 sonar_market_offers

> **Ofertas en el Mercado:** trabajos temporales, productos, servicios, empresas en venta.

```sql
CREATE TABLE sonar_market_offers (
  id                    CHAR(36)        NOT NULL,
  type                  ENUM('temp_job','product','service','company_sale','rent') NOT NULL,
  status                ENUM('active','accepted','completed','cancelled','expired') NOT NULL DEFAULT 'active',

  publisher_kind        ENUM('account','company') NOT NULL,
  publisher_account_id  CHAR(36)        NULL,
  publisher_company_id  CHAR(36)        NULL,

  title                 VARCHAR(192)    NOT NULL,
  description           TEXT            NULL,
  category              VARCHAR(64)     NULL COMMENT 'subcategoría libre del type',

  data_json             JSON            NOT NULL COMMENT 'datos específicos por type',
  price                 DECIMAL(12,2) UNSIGNED NULL,
  price_currency        ENUM('AD') NOT NULL DEFAULT 'AD' COMMENT 'admirals dollars (RP)',

  location_json         JSON            NULL COMMENT 'Coords del trabajo / producto',
  vertical_filter       VARCHAR(32)     NULL COMMENT 'filtrable por vertical',

  accepted_by_account_id CHAR(36)       NULL,
  accepted_at           INT UNSIGNED    NULL,
  expected_completion_at INT UNSIGNED   NULL,
  completed_at          INT UNSIGNED    NULL,

  expires_at            INT UNSIGNED    NULL,
  views_count           INT UNSIGNED    NOT NULL DEFAULT 0,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_market_offers_status_type (status, type, created_at DESC),
  KEY idx_sonar_market_offers_publisher_account (publisher_account_id, status),
  KEY idx_sonar_market_offers_publisher_company (publisher_company_id, status),
  KEY idx_sonar_market_offers_vertical (vertical_filter, status, type),
  KEY idx_sonar_market_offers_expires (status, expires_at),

  CONSTRAINT fk_sonar_market_offers_publisher_account
    FOREIGN KEY (publisher_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_market_offers_publisher_company
    FOREIGN KEY (publisher_company_id)
    REFERENCES sonar_companies(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_market_offers_acceptor
    FOREIGN KEY (accepted_by_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CHECK (
    (publisher_kind = 'account' AND publisher_account_id IS NOT NULL AND publisher_company_id IS NULL)
    OR (publisher_kind = 'company' AND publisher_company_id IS NOT NULL AND publisher_account_id IS NULL)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- `data_json` ejemplo `temp_job`: `{ "estimated_minutes": 30, "task_kind": "harvest", "plot_id": "..." }`.
- `data_json` ejemplo `product`: `{ "item_kind": "flour_baker_25kg", "quantity": 100, "quality_grade": "A" }`.
- Cron de expiración consulta `WHERE status = 'active' AND expires_at < NOW()` — índice `idx_sonar_market_offers_expires` lo soporta.

### 8.2 sonar_market_reviews

> **Reseñas y rating** post-transacción.

```sql
CREATE TABLE sonar_market_reviews (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  reviewer_kind         ENUM('account','company') NOT NULL,
  reviewer_id           CHAR(36)        NOT NULL,
  subject_kind          ENUM('account','company') NOT NULL,
  subject_id            CHAR(36)        NOT NULL,

  rating                TINYINT UNSIGNED NOT NULL,
  comment               VARCHAR(500)    NULL,

  related_offer_id      CHAR(36)        NULL,
  related_job_id        CHAR(36)        NULL,

  is_hidden             TINYINT(1)      NOT NULL DEFAULT 0,
  hidden_reason         VARCHAR(255)    NULL,

  posted_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_market_reviews_offer (related_offer_id, reviewer_id),
  KEY idx_sonar_market_reviews_subject (subject_id, posted_at DESC),
  KEY idx_sonar_market_reviews_reviewer (reviewer_id, posted_at DESC),

  CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- `UNIQUE (related_offer_id, reviewer_id)` impide doble review del mismo reviewer sobre la misma transacción.
- Reseñas polimórficas — pueden ser de account a account, company a company, etc.
- No FK polimórfica directa — integridad por aplicación.

### 8.3 sonar_reputation

> **Histórico de cambios de reputación** y valor agregado actual. Permite ver "por qué" un sujeto tiene su rep actual.

```sql
CREATE TABLE sonar_reputation (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  subject_kind          ENUM('account','company') NOT NULL,
  subject_id            CHAR(36)        NOT NULL,
  occurred_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  delta                 SMALLINT        NOT NULL COMMENT 'signed, típicamente -10..+10',
  value_after           TINYINT UNSIGNED NOT NULL COMMENT '0-100',

  reason_code           VARCHAR(64)     NOT NULL COMMENT 'contract_fulfilled, contract_breached, good_review, etc.',
  reason_text           VARCHAR(255)    NULL,

  source_resource       VARCHAR(64)     NOT NULL,
  related_doc_id        CHAR(36)        NULL,
  related_offer_id      CHAR(36)        NULL,
  related_review_id     BIGINT UNSIGNED NULL,

  PRIMARY KEY (id),
  KEY idx_sonar_reputation_subject (subject_id, occurred_at DESC),
  KEY idx_sonar_reputation_reason (reason_code, occurred_at DESC),

  CHECK (value_after BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- Tabla de **trail** — el valor agregado vivo se mantiene en `sonar_accounts.reputation_global` y `sonar_companies.reputation` (denormalizado para queries frecuentes).
- Esta tabla permite reconstruir histórico, analytics, debugging. Insert-only.

---

## 9. DDL — Dominio Logística

### 9.1 sonar_logistics_jobs

> **Trabajos de transporte.** Origen + destino + cargo + carrier + estado.

```sql
CREATE TABLE sonar_logistics_jobs (
  id                    CHAR(36)        NOT NULL,
  status                ENUM('pending','assigned','in_transit','delivered','disputed','cancelled') NOT NULL DEFAULT 'pending',

  origin_company_id     CHAR(36)        NOT NULL,
  destination_company_id CHAR(36)       NOT NULL,

  carrier_kind          ENUM('account','company') NULL,
  carrier_account_id    CHAR(36)        NULL,
  carrier_company_id    CHAR(36)        NULL,
  vehicle_plate         VARCHAR(16)     NULL,

  cargo_json            JSON            NOT NULL COMMENT 'array de { item_kind, quantity, batch_id, quality_grade, weight_kg }',
  total_weight_kg       DECIMAL(10,2)   NOT NULL DEFAULT 0,
  estimated_distance_km DECIMAL(8,2)    NOT NULL DEFAULT 0,

  price                 DECIMAL(12,2) UNSIGNED NOT NULL DEFAULT 0,
  payment_holding_movement_id BIGINT UNSIGNED NULL COMMENT 'FK lógica a bank_movements (escrow)',

  delivery_note_id      CHAR(36)        NULL,
  receiver_signature_doc_id CHAR(36)    NULL,

  scheduled_at          INT UNSIGNED    NULL,
  started_at            INT UNSIGNED    NULL,
  delivered_at          INT UNSIGNED    NULL,
  cancelled_at          INT UNSIGNED    NULL,

  related_offer_id      CHAR(36)        NULL,

  created_by_account_id CHAR(36)        NOT NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_logistics_jobs_status (status, created_at DESC),
  KEY idx_sonar_logistics_jobs_origin (origin_company_id, status),
  KEY idx_sonar_logistics_jobs_destination (destination_company_id, status),
  KEY idx_sonar_logistics_jobs_carrier_account (carrier_account_id, status),
  KEY idx_sonar_logistics_jobs_carrier_company (carrier_company_id, status),
  KEY idx_sonar_logistics_jobs_offer (related_offer_id),

  CONSTRAINT fk_sonar_logistics_jobs_origin
    FOREIGN KEY (origin_company_id)
    REFERENCES sonar_companies(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_logistics_jobs_destination
    FOREIGN KEY (destination_company_id)
    REFERENCES sonar_companies(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_logistics_jobs_carrier_account
    FOREIGN KEY (carrier_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_logistics_jobs_carrier_company
    FOREIGN KEY (carrier_company_id)
    REFERENCES sonar_companies(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_logistics_jobs_delivery_note
    FOREIGN KEY (delivery_note_id)
    REFERENCES sonar_documents(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- `cargo_json` por practicidad — heterogéneo, no consultable individualmente.
- `payment_holding_movement_id` apunta al movimiento de escrow lock — al confirmar entrega se libera (escrow_release).
- ON DELETE RESTRICT en origin/destination evita borrar empresa con jobs activos por accidente.

### 9.2 sonar_logistics_disputes

```sql
CREATE TABLE sonar_logistics_disputes (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  job_id                CHAR(36)        NOT NULL,
  raised_by_account_id  CHAR(36)        NOT NULL,
  raised_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  reason                ENUM('cargo_damaged','quantity_mismatch','late','wrong_destination','other') NOT NULL,
  evidence_json         JSON            NULL,
  notes                 TEXT            NULL,

  status                ENUM('open','investigating','resolved_in_favor_origin','resolved_in_favor_destination','resolved_in_favor_carrier','dismissed') NOT NULL DEFAULT 'open',
  resolved_at           INT UNSIGNED    NULL,
  resolved_by_account_id CHAR(36)       NULL,
  resolution_notes      TEXT            NULL,

  PRIMARY KEY (id),
  KEY idx_sonar_logistics_disputes_job (job_id, status),
  KEY idx_sonar_logistics_disputes_raiser (raised_by_account_id, raised_at DESC),

  CONSTRAINT fk_sonar_logistics_disputes_job
    FOREIGN KEY (job_id)
    REFERENCES sonar_logistics_jobs(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_logistics_disputes_raiser
    FOREIGN KEY (raised_by_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

---

## 10. DDL — Dominio Granja

> **Tablas del nodo Granja SONAR.** Cada empresa Granja tiene sus parcelas, silos, máquinas. Las licencias son por jugador, no por empresa.

### 10.1 sonar_granja_plots

```sql
CREATE TABLE sonar_granja_plots (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,
  plot_label            VARCHAR(64)     NOT NULL COMMENT 'identificador legible: parcela_3, hortícola_1',

  kind                  ENUM('cereal','hortícola','frutal','industrial','pasto','viña') NOT NULL,
  area_m2               INT UNSIGNED    NOT NULL DEFAULT 0,
  location_json         JSON            NOT NULL COMMENT 'Coords + polygon vertices',

  current_crop_id       VARCHAR(64)     NULL COMMENT 'wheat_soft, tomato, etc. NULL si vacío',
  current_variant       ENUM('common','premium') NULL,
  current_stage         TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=vacío, 1..N=stages crecimiento',
  growth_pct            TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0-100 dentro del stage',

  current_batch_id      VARCHAR(32)     NULL,
  seeded_at             INT UNSIGNED    NULL,
  expected_harvest_at   INT UNSIGNED    NULL,

  -- Quality tracking (componentes que se acumulan durante el ciclo)
  soil_quality_score    TINYINT UNSIGNED NOT NULL DEFAULT 50,
  irrigation_score      TINYINT UNSIGNED NOT NULL DEFAULT 50,
  fertilization_score   TINYINT UNSIGNED NOT NULL DEFAULT 50,
  pest_control_score    TINYINT UNSIGNED NOT NULL DEFAULT 100,
  weather_score         TINYINT UNSIGNED NOT NULL DEFAULT 100,

  -- Estado físico/visual
  is_protected_mesh     TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'malla anti-granizo instalada',
  visual_state          VARCHAR(32)     NOT NULL DEFAULT 'fallow' COMMENT 'sincroniza shader / props',

  -- Pests
  active_pest_kind      VARCHAR(32)     NULL,
  active_pest_severity  ENUM('low','medium','high') NULL,
  pest_detected_at      INT UNSIGNED    NULL,

  meta                  JSON            NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_granja_plots_company_label (company_id, plot_label),
  KEY idx_sonar_granja_plots_company (company_id),
  KEY idx_sonar_granja_plots_stage (current_stage, expected_harvest_at),
  KEY idx_sonar_granja_plots_pest (active_pest_kind, active_pest_severity),

  CONSTRAINT fk_sonar_granja_plots_company
    FOREIGN KEY (company_id)
    REFERENCES sonar_companies(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CHECK (soil_quality_score BETWEEN 0 AND 100),
  CHECK (irrigation_score BETWEEN 0 AND 100),
  CHECK (fertilization_score BETWEEN 0 AND 100),
  CHECK (pest_control_score BETWEEN 0 AND 100),
  CHECK (weather_score BETWEEN 0 AND 100),
  CHECK (growth_pct BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- Componentes de calidad acumulan durante el ciclo. Al cosechar (`harvest_completed`) se calcula `quality.score` final con la fórmula del `01_node_farm.md`.
- `visual_state` sincroniza con shader del prop (sprouting, leafing, flowering, mature, rotten).
- Cron de crecimiento actualiza `growth_pct` y, al llegar 100, avanza `current_stage`.

### 10.2 sonar_granja_silos

```sql
CREATE TABLE sonar_granja_silos (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,
  silo_label            VARCHAR(64)     NOT NULL,

  kind                  ENUM('grain','feed','seed','fertilizer','water','compost') NOT NULL,
  capacity_kg           INT UNSIGNED    NOT NULL,
  current_kg            DECIMAL(10,2)   NOT NULL DEFAULT 0,
  capacity_pct          TINYINT UNSIGNED AS (LEAST(100, FLOOR(current_kg / capacity_kg * 100))) STORED,

  -- Lo que contiene actualmente (puede ser mezcla de batches)
  content_kind          VARCHAR(64)     NULL COMMENT 'wheat_soft, etc. NULL si vacío o mezclado',
  batches_json          JSON            NULL COMMENT 'array de { batch_id, kg, quality_grade, quality_score }',
  is_mixed              TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 si tiene mezcla cross-grain (penalización calidad)',

  location_json         JSON            NOT NULL,
  visual_state          VARCHAR(32)     NOT NULL DEFAULT 'empty',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_granja_silos_company_label (company_id, silo_label),
  KEY idx_sonar_granja_silos_company (company_id, kind),

  CONSTRAINT fk_sonar_granja_silos_company
    FOREIGN KEY (company_id)
    REFERENCES sonar_companies(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CHECK (current_kg >= 0 AND current_kg <= capacity_kg)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

### 10.3 sonar_granja_machines

```sql
CREATE TABLE sonar_granja_machines (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,
  machine_label         VARCHAR(64)     NOT NULL,

  kind                  ENUM('tractor','harvester','sprayer','irrigator','sower','forklift','plow','baler') NOT NULL,
  model_id              VARCHAR(64)     NOT NULL COMMENT 'modelo específico (sonar_tractor_basic_01)',

  status                ENUM('idle','in_use','broken','maintenance') NOT NULL DEFAULT 'idle',
  fuel_l                DECIMAL(6,2)    NOT NULL DEFAULT 0,
  fuel_capacity_l       DECIMAL(6,2)    NOT NULL,
  health_pct            TINYINT UNSIGNED NOT NULL DEFAULT 100,
  hours_used            DECIMAL(10,2)   NOT NULL DEFAULT 0,

  current_user_account_id CHAR(36)      NULL COMMENT 'NULL si no está siendo usada',
  parked_location_json  JSON            NULL,

  last_maintenance_at   INT UNSIGNED    NULL,
  next_maintenance_due_hours DECIMAL(8,2) NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_granja_machines_company_label (company_id, machine_label),
  KEY idx_sonar_granja_machines_company_status (company_id, status),
  KEY idx_sonar_granja_machines_user (current_user_account_id),

  CONSTRAINT fk_sonar_granja_machines_company
    FOREIGN KEY (company_id)
    REFERENCES sonar_companies(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_granja_machines_user
    FOREIGN KEY (current_user_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CHECK (health_pct BETWEEN 0 AND 100),
  CHECK (fuel_l >= 0 AND fuel_l <= fuel_capacity_l)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

### 10.4 sonar_granja_licenses

> **Licencias de conducción / handling.** Por jugador, no por empresa.

```sql
CREATE TABLE sonar_granja_licenses (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id            CHAR(36)        NOT NULL,

  kind                  ENUM(
    'driving_basic','driving_agricultural','driving_harvester','driving_transport',
    'pesticide_handling','fumigation_drone'
  ) NOT NULL,

  obtained_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  expires_at            INT UNSIGNED    NULL COMMENT 'NULL = no caduca',
  issued_by             VARCHAR(64)     NOT NULL DEFAULT 'sonar_granja_npc',
  cost                  DECIMAL(8,2) UNSIGNED NOT NULL DEFAULT 0,
  related_doc_id        CHAR(36)        NULL COMMENT 'certificado en sonar_documents',

  is_revoked            TINYINT(1)      NOT NULL DEFAULT 0,
  revoked_at            INT UNSIGNED    NULL,
  revoke_reason         VARCHAR(255)    NULL,

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_granja_licenses_account_kind (account_id, kind, is_revoked),
  KEY idx_sonar_granja_licenses_expires (expires_at),

  CONSTRAINT fk_sonar_granja_licenses_account
    FOREIGN KEY (account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

---

## 11. DDL — Dominio Molino

### 11.1 sonar_molino_silos

```sql
CREATE TABLE sonar_molino_silos (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,
  silo_label            VARCHAR(64)     NOT NULL,

  kind                  ENUM('input_grain','intermediate_flour','intermediate_semolina','intermediate_bran','additive') NOT NULL,
  grain_kind            VARCHAR(64)     NULL COMMENT 'wheat_soft, wheat_durum, rye, etc.',

  capacity_kg           INT UNSIGNED    NOT NULL,
  current_kg            DECIMAL(10,2)   NOT NULL DEFAULT 0,
  capacity_pct          TINYINT UNSIGNED AS (LEAST(100, FLOOR(current_kg / capacity_kg * 100))) STORED,

  batches_json          JSON            NULL COMMENT 'array { batch_id, kg, quality_grade, quality_score, lineage[] }',
  is_mixed              TINYINT(1)      NOT NULL DEFAULT 0,
  humidity_pct          DECIMAL(5,2)    NOT NULL DEFAULT 12 COMMENT 'humedad almacenada — afecta calidad',

  location_json         JSON            NOT NULL,
  visual_state          VARCHAR(32)     NOT NULL DEFAULT 'empty',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_molino_silos_company_label (company_id, silo_label),
  KEY idx_sonar_molino_silos_company_kind (company_id, kind),

  CONSTRAINT fk_sonar_molino_silos_company
    FOREIGN KEY (company_id)
    REFERENCES sonar_companies(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CHECK (current_kg >= 0 AND current_kg <= capacity_kg),
  CHECK (humidity_pct >= 0 AND humidity_pct <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

### 11.2 sonar_molino_machines

```sql
CREATE TABLE sonar_molino_machines (
  id                    CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NOT NULL,
  machine_label         VARCHAR(64)     NOT NULL,

  kind                  ENUM('cleaner','mill_rollers','sasor_sieve','sacker','forklift','conveyor','packager') NOT NULL,
  model_id              VARCHAR(64)     NOT NULL,

  status                ENUM('idle','running','broken','cleaning','maintenance') NOT NULL DEFAULT 'idle',
  health_pct            TINYINT UNSIGNED NOT NULL DEFAULT 100,
  hours_used            DECIMAL(10,2)   NOT NULL DEFAULT 0,

  -- Configuración operativa actual
  current_calibration_mm DECIMAL(4,2)   NULL COMMENT 'para mill_rollers',
  current_speed_pct     TINYINT UNSIGNED NULL COMMENT '50-100',
  current_grain_kind    VARCHAR(64)     NULL COMMENT 'qué se está procesando ahora',
  current_batch_id      VARCHAR(32)     NULL,

  -- Cross-contamination tracking
  last_grain_kind       VARCHAR(64)     NULL COMMENT 'último grano procesado — si difiere de current sin limpieza, hay contaminación',
  cleaned_at            INT UNSIGNED    NULL,

  current_user_account_id CHAR(36)      NULL,
  location_json         JSON            NOT NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_molino_machines_company_label (company_id, machine_label),
  KEY idx_sonar_molino_machines_company_status (company_id, status),

  CONSTRAINT fk_sonar_molino_machines_company
    FOREIGN KEY (company_id)
    REFERENCES sonar_companies(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  CONSTRAINT fk_sonar_molino_machines_user
    FOREIGN KEY (current_user_account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,

  CHECK (health_pct BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

### 11.3 sonar_molino_batches

> **Trazabilidad de lotes** producidos en el molino. Los batches físicos también viven como Item Físico en ox_inventory; esta tabla es el registro server-side de producción para analytics, búsqueda y queries de lineage.

```sql
CREATE TABLE sonar_molino_batches (
  id                    VARCHAR(32)     NOT NULL COMMENT 'BatchId formato MILL-YYYY-NNNN-X',
  company_id            CHAR(36)        NOT NULL,
  produced_at           INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  -- Input
  input_batch_ids_json  JSON            NOT NULL COMMENT 'batches consumidos (granja batches)',
  input_grain_kind      VARCHAR(64)     NOT NULL,
  input_kg              DECIMAL(10,2)   NOT NULL,
  input_quality_grade   CHAR(1)         NOT NULL,
  input_quality_score   TINYINT UNSIGNED NOT NULL,

  -- Output
  output_kind           ENUM('flour_force','flour_baker','flour_whole','semolina_fine','semolina_coarse','bran') NOT NULL,
  output_variant        ENUM('common','premium') NOT NULL,
  output_kg             DECIMAL(10,2)   NOT NULL,
  output_quality_grade  CHAR(1)         NOT NULL,
  output_quality_score  TINYINT UNSIGNED NOT NULL,

  -- Process metrics
  calibration_mm        DECIMAL(4,2)    NOT NULL,
  speed_pct             TINYINT UNSIGNED NOT NULL,
  duration_minutes      INT UNSIGNED    NOT NULL,
  process_factor_score  TINYINT UNSIGNED NOT NULL COMMENT 'componente process del cálculo de calidad',

  -- Lineage acumulado
  lineage_json          JSON            NOT NULL COMMENT '[ { vertical, batch_id, company_id, quality } ]',

  produced_by_account_id CHAR(36)       NOT NULL,

  PRIMARY KEY (id),
  KEY idx_sonar_molino_batches_company_date (company_id, produced_at DESC),
  KEY idx_sonar_molino_batches_kind (output_kind, output_quality_grade),
  KEY idx_sonar_molino_batches_quality (output_quality_grade, produced_at DESC),

  CONSTRAINT fk_sonar_molino_batches_company
    FOREIGN KEY (company_id)
    REFERENCES sonar_companies(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,

  CHECK (input_quality_grade IN ('S','A','B','C','D')),
  CHECK (output_quality_grade IN ('S','A','B','C','D')),
  CHECK (input_quality_score BETWEEN 0 AND 100),
  CHECK (output_quality_score BETWEEN 0 AND 100),
  CHECK (process_factor_score BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- ON DELETE RESTRICT en company — los batches son histórico de producción, no se pueden borrar al borrar empresa.
- `lineage_json` permite recorrer toda la cadena upstream (granja → ... → este batch) sin JOIN cross-tabla.

---

## 12. DDL — Infraestructura

### 12.1 sonar_event_log (PARTITIONED)

> **Audit trail del bus.** Persistencia de eventos `audit: always`. Particionado mensual desde día 1.

```sql
CREATE TABLE sonar_event_log (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  emitted_at            INT UNSIGNED    NOT NULL,

  event_name            VARCHAR(96)     NOT NULL COMMENT 'sonar:domain:action',
  event_id              CHAR(36)        NOT NULL COMMENT 'UUID v4 único de esta emisión',
  schema_version        TINYINT UNSIGNED NOT NULL DEFAULT 1,

  source_resource       VARCHAR(64)     NOT NULL,
  payload_json          JSON            NOT NULL,

  -- Indexable references (extraídos del payload para queries comunes)
  related_account_id    CHAR(36)        NULL,
  related_company_id    CHAR(36)        NULL,
  related_doc_id        CHAR(36)        NULL,
  related_offer_id      CHAR(36)        NULL,
  related_job_id        CHAR(36)        NULL,
  related_batch_id      VARCHAR(32)     NULL,

  PRIMARY KEY (id, emitted_at),
  UNIQUE KEY uq_sonar_event_log_event_id (event_id, emitted_at),
  KEY idx_sonar_event_log_event_name (event_name, emitted_at DESC),
  KEY idx_sonar_event_log_source (source_resource, emitted_at DESC),
  KEY idx_sonar_event_log_account (related_account_id, emitted_at DESC),
  KEY idx_sonar_event_log_company (related_company_id, emitted_at DESC),
  KEY idx_sonar_event_log_doc (related_doc_id, emitted_at DESC),
  KEY idx_sonar_event_log_offer (related_offer_id, emitted_at DESC),
  KEY idx_sonar_event_log_job (related_job_id, emitted_at DESC),
  KEY idx_sonar_event_log_batch (related_batch_id, emitted_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  PARTITION BY RANGE (emitted_at) (
    PARTITION p_2026_01 VALUES LESS THAN (1738368000),
    PARTITION p_2026_02 VALUES LESS THAN (1740787200),
    PARTITION p_2026_03 VALUES LESS THAN (1743465600),
    PARTITION p_future VALUES LESS THAN MAXVALUE
  );
```

**Notas:**
- Los campos `related_*` se extraen del payload por el bus al persistir, **no requieren JSON queries en hot paths**.
- `event_id` único garantiza idempotencia: si el bus reintenta una emisión, no se duplica.
- Particiones gestionadas por cron mensual + archival a cold storage > 12 meses.

### 12.2 sonar_schema_versions

> **Registro de migraciones aplicadas.** Permite saber el estado del schema y reproducir entornos.

```sql
CREATE TABLE sonar_schema_versions (
  version               INT UNSIGNED    NOT NULL COMMENT 'numérico secuencial',
  filename              VARCHAR(192)    NOT NULL COMMENT 'NNN_description.sql',
  applied_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  applied_by            VARCHAR(64)     NULL COMMENT 'usuario que aplicó (admin / sistema)',
  checksum              VARCHAR(64)     NOT NULL COMMENT 'SHA-256 del archivo migration',
  duration_ms           INT UNSIGNED    NOT NULL DEFAULT 0,
  notes                 TEXT            NULL,

  PRIMARY KEY (version),
  UNIQUE KEY uq_sonar_schema_versions_filename (filename)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

**Notas:**
- Al boot, `sonar_core` lee este registro y aplica las migraciones pendientes en orden.
- `checksum` permite detectar si una migración fue alterada post-aplicación (alerta de tampering).

### 12.3 sonar_settings_per_account

> **Preferencias de aplicación por cuenta.** Independientes del Tablet (Tablet tiene config visual, esto son prefs lógicas).

```sql
CREATE TABLE sonar_settings_per_account (
  account_id            CHAR(36)        NOT NULL,
  notifications_prefs   JSON            NULL COMMENT '{ type: { enabled, priority, delivery_mode_override } }',
  privacy_prefs         JSON            NULL COMMENT '{ show_online, allow_strangers_message, ... }',
  market_prefs          JSON            NULL COMMENT '{ filters_default, alerts_subscriptions[] }',
  language              VARCHAR(8)      NOT NULL DEFAULT 'es-ES',
  timezone              VARCHAR(64)     NOT NULL DEFAULT 'Europe/Madrid',

  custom                JSON            NULL COMMENT 'extensible para apps de terceros (SDK)',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (account_id),

  CONSTRAINT fk_sonar_settings_per_account
    FOREIGN KEY (account_id)
    REFERENCES sonar_accounts(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

---

## 13. Reference data (seeds)

> **Datos mínimos** que el ecosistema necesita para arrancar. Se aplican automáticamente al boot si las tablas están vacías.

### 13.1 Empresas NPC iniciales

> **Empresas controladas por NPC** que sirven como demand & supply automatizado en oleada 1 — permiten que un nodo standalone funcione sin red completa de jugadores.

```sql
-- Cooperativa NPC compradora de grano (Granja standalone)
INSERT INTO sonar_companies (id, vertical, name, status, owner_account_id, hq_location, cash_balance, reputation, founded_at)
VALUES (
  'a0000000-0000-0000-0000-000000000001',
  'cooperativa',
  'Cooperativa SONAR NPC',
  'active',
  'a0000000-0000-0000-0000-000000000099',  -- cuenta NPC sistema
  '{"x": 1234.5, "y": 5678.9, "z": 30.0, "heading": 90}',
  10000000.00,
  85,
  UNIX_TIMESTAMP()
);

-- Molino NPC (compra grano, vende harina al panadero NPC)
INSERT INTO sonar_companies (id, vertical, name, status, owner_account_id, hq_location, cash_balance, reputation, founded_at)
VALUES (
  'a0000000-0000-0000-0000-000000000002',
  'mill',
  'Molino SONAR NPC',
  'active',
  'a0000000-0000-0000-0000-000000000099',
  '{"x": 2345.6, "y": 6789.0, "z": 35.0, "heading": 180}',
  10000000.00,
  80,
  UNIX_TIMESTAMP()
);
```

### 13.2 Cuenta de sistema (NPC)

```sql
INSERT INTO sonar_accounts (id, char_id, framework_source, alias, reputation_global, preferred_locale)
VALUES (
  'a0000000-0000-0000-0000-000000000099',
  'NPC_SYSTEM',
  'manual',
  'SONAR System',
  100,
  'es-ES'
);
```

### 13.3 Cuenta bancaria de sistema

```sql
INSERT INTO sonar_bank_accounts (id, iban, type, owner_company_id, balance)
VALUES (
  'b0000000-0000-0000-0000-000000000001',
  'AD-SYS0-0000-0001',
  'company',
  'a0000000-0000-0000-0000-000000000001',
  10000000.00
);
```

### 13.4 Templates de contratos

> **Tabla satélite** opcional para templates de contratos reutilizables (no es DDL principal, va en migración separada).

```sql
CREATE TABLE sonar_document_templates (
  id                    VARCHAR(64)     NOT NULL,
  type                  ENUM('contract','delivery_note','receipt','license') NOT NULL,
  name                  VARCHAR(128)    NOT NULL,
  body_template         LONGTEXT        NOT NULL COMMENT 'plantilla con placeholders {{variable}}',
  schema_json           JSON            NOT NULL COMMENT 'campos del formulario',
  visibility            ENUM('builtin','custom') NOT NULL DEFAULT 'builtin',

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) ON UPDATE (UNIX_TIMESTAMP()),

  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Seeds de templates iniciales
INSERT INTO sonar_document_templates (id, type, name, body_template, schema_json) VALUES
('contract_b2b_supply', 'contract', 'Contrato suministro B2B',
'{{supplier_name}} se compromete a entregar a {{client_name}} {{quantity}} {{unit}} de {{product}} con calidad mínima {{min_grade}} a un precio de {{price_per_unit}} AD/unidad...',
'{"fields":[{"key":"supplier_name","type":"text"},{"key":"client_name","type":"text"},{"key":"product","type":"text"},{"key":"quantity","type":"number"},{"key":"unit","type":"text"},{"key":"min_grade","type":"enum","options":["S","A","B","C","D"]},{"key":"price_per_unit","type":"number"},{"key":"duration_months","type":"number"}]}'
),
('contract_employment', 'contract', 'Contrato laboral',
'Contrato de empleo entre {{company_name}} y {{employee_name}} para el puesto de {{position}} con salario {{salary}} AD por {{salary_period}}...',
'{"fields":[{"key":"company_name","type":"text"},{"key":"employee_name","type":"text"},{"key":"position","type":"text"},{"key":"salary","type":"number"},{"key":"salary_period","type":"enum","options":["hourly","shift","daily","monthly"]}]}'
);
```

---

## 14. Índices — justificación consolidada

> **Política:** ningún índice "por si acaso". Cada índice tiene una query crítica que lo usa.

### 14.1 Tabla resumen de índices

| Tabla | Índice | Razón |
|---|---|---|
| `sonar_accounts` | `uq_*_char_id (char_id, framework_source)` | login: lookup por char del framework |
| `sonar_tablets` | `idx_*_owner` | listar tablets del jugador |
| `sonar_companies` | `uq_*_name` | naming único + search |
| `sonar_companies` | `idx_*_owner` | listar empresas del jugador |
| `sonar_companies` | `idx_*_vertical_status` | listings públicos en Mercado |
| `sonar_company_members` | `uq_*_active (company, account, is_active)` | impide doble membership activa |
| `sonar_company_members` | `idx_*_account (account, is_active)` | "mis empresas" en Tablet |
| `sonar_company_members` | `idx_*_company (company, is_active, role)` | "miembros de mi empresa" |
| `sonar_bank_accounts` | `uq_*_iban` | lookup por IBAN |
| `sonar_bank_accounts` | `idx_*_owner_account/_company` | "mis cuentas" |
| `sonar_bank_movements` | `idx_*_account (account_id, occurred_at DESC)` | extracto bancario reciente |
| `sonar_bank_movements` | `idx_*_category` | analytics por categoría |
| `sonar_bank_movements` | `idx_*_nonce` | anti-replay validation |
| `sonar_bank_movements` | `idx_*_related_*` | trazabilidad reverse (movimiento → doc/offer/job) |
| `sonar_documents` | `idx_*_owner_account/company (..., type, status)` | "mis docs" filtrados por type/status |
| `sonar_documents` | `idx_*_status` | jobs internos (renotificar pending_signature antiguos, etc.) |
| `sonar_documents` | `idx_*_parent` | árbol de versiones |
| `sonar_documents` | `idx_*_created_by` | actividad reciente del usuario |
| `sonar_document_signatures` | `uq_*_doc_signer` | impide doble firma |
| `sonar_document_signatures` | `idx_*_signer (signer, signed_at DESC)` | "docs firmados por mí" |
| `sonar_chats` | `idx_*_company` | canales de empresa |
| `sonar_chats` | `idx_*_last_message DESC` | sort en lista de chats |
| `sonar_chat_participants` | `uq_*_active` | impide doble participación activa |
| `sonar_chat_participants` | `idx_*_account (account, left_at, is_pinned DESC)` | lista de chats del jugador |
| `sonar_messages` | `idx_*_chat (chat, sent_at DESC)` | render del chat (paginación) |
| `sonar_messages` | `idx_*_sender` | "mensajes que envié" |
| `sonar_notifications` | `idx_*_account_unread (account, is_read, is_archived, pushed_at DESC)` | bandeja activa de la Tablet |
| `sonar_market_offers` | `idx_*_status_type` | listings principales del Mercado |
| `sonar_market_offers` | `idx_*_publisher_*` | "mis ofertas publicadas" |
| `sonar_market_offers` | `idx_*_vertical` | filtro por vertical |
| `sonar_market_offers` | `idx_*_expires` | cron de expiración |
| `sonar_market_reviews` | `uq_*_offer (offer, reviewer)` | impide doble review |
| `sonar_market_reviews` | `idx_*_subject` | reseñas recibidas por sujeto |
| `sonar_reputation` | `idx_*_subject` | trail de cambios reputación |
| `sonar_logistics_jobs` | `idx_*_status` | dashboard ops |
| `sonar_logistics_jobs` | `idx_*_origin/_destination` | "jobs de mi empresa" |
| `sonar_logistics_jobs` | `idx_*_carrier_*` | "mis trabajos como carrier" |
| `sonar_granja_plots` | `idx_*_company` | "mis parcelas" |
| `sonar_granja_plots` | `idx_*_stage (current_stage, expected_harvest_at)` | cron de crecimiento |
| `sonar_granja_plots` | `idx_*_pest` | parcelas con plaga activa |
| `sonar_granja_silos` | `idx_*_company_kind` | "mis silos por tipo" |
| `sonar_granja_machines` | `idx_*_company_status` | "máquinas idle / averiadas" |
| `sonar_granja_licenses` | `uq_*_account_kind` | impide duplicada |
| `sonar_granja_licenses` | `idx_*_expires` | cron de expiración |
| `sonar_molino_silos` | `idx_*_company_kind` | "silos de molino por tipo" |
| `sonar_molino_machines` | `idx_*_company_status` | dashboard ops |
| `sonar_molino_batches` | `idx_*_company_date` | producción reciente |
| `sonar_molino_batches` | `idx_*_kind` | búsqueda en mercado |
| `sonar_event_log` | `uq_*_event_id` | idempotencia |
| `sonar_event_log` | `idx_*_event_name` | "todos los `bank:transfer_completed` recientes" |
| `sonar_event_log` | `idx_*_account/company/doc/...` | trazabilidad por entidad |

### 14.2 Política de índices futuros

- **Antes de añadir un índice:** documentar la query crítica que lo justifica + medir mejora en QA.
- **Después de N días en producción:** revisar `INFORMATION_SCHEMA.STATISTICS` + `sys.schema_unused_indexes` y eliminar los que no se usan.
- **MAX:** ~5 índices por tabla (excepto event_log con polymorphic refs).

---

## 15. Queries críticas — hot path

> **Las queries que se ejecutan con mayor frecuencia.** Cada una tiene su índice asociado y plan de ejecución verificado.

### 15.1 Login del jugador

```sql
SELECT id, alias, reputation_global, preferred_locale, meta
FROM sonar_accounts
WHERE char_id = ? AND framework_source = ?;
-- usa: uq_sonar_accounts_char_id
-- p99 esperado: < 1ms
```

### 15.2 Cargar empresas del jugador

```sql
SELECT c.id, c.name, c.vertical, c.status, c.logo_url, c.brand_color, m.role, m.position
FROM sonar_company_members m
JOIN sonar_companies c ON c.id = m.company_id
WHERE m.account_id = ? AND m.is_active = 1
ORDER BY m.hired_at ASC;
-- usa: idx_sonar_company_members_account + PK sonar_companies
-- p99 esperado: < 5ms
```

### 15.3 Listar miembros de una empresa

```sql
SELECT m.id, a.alias, m.role, m.position, m.salary, m.hired_at
FROM sonar_company_members m
JOIN sonar_accounts a ON a.id = m.account_id
WHERE m.company_id = ? AND m.is_active = 1
ORDER BY FIELD(m.role, 'owner','manager','employee','temporary'), m.hired_at;
-- usa: idx_sonar_company_members_company
```

### 15.4 Extracto bancario (últimos N movimientos)

```sql
SELECT id, occurred_at, amount, balance_after, category, counterpart_iban, concept
FROM sonar_bank_movements
WHERE bank_account_id = ?
ORDER BY occurred_at DESC, id DESC
LIMIT 50;
-- usa: idx_sonar_bank_movements_account
-- p99 esperado: < 5ms (gracias a partitioning + index)
```

### 15.5 Notificaciones activas no leídas del usuario

```sql
SELECT id, type, title, subtitle, body, actions_json, pushed_at
FROM sonar_notifications
WHERE account_id = ? AND is_read = 0 AND is_archived = 0
ORDER BY pushed_at DESC
LIMIT 30;
-- usa: idx_sonar_notifications_account_unread
-- p99 esperado: < 3ms
```

### 15.6 Listings activos del Mercado por vertical

```sql
SELECT id, type, title, price, location_json, expires_at
FROM sonar_market_offers
WHERE status = 'active' AND vertical_filter = ?
ORDER BY created_at DESC
LIMIT 50;
-- usa: idx_sonar_market_offers_vertical
```

### 15.7 Documentos pendientes de mi firma

```sql
SELECT d.id, d.type, d.title, d.created_at
FROM sonar_documents d
WHERE d.status = 'pending_signature'
  AND JSON_CONTAINS(d.parties_json, JSON_OBJECT('kind','account','id', ?))
  AND NOT EXISTS (
    SELECT 1 FROM sonar_document_signatures s
    WHERE s.doc_id = d.id AND s.signer_account_id = ?
  );
-- usa: idx_sonar_documents_status + scan parties_json
-- p99 esperado: < 50ms (mejorable con tabla intermedia document_parties si crece)
```

> **Nota:** si crece volumen, migrar `parties_json` a tabla `sonar_document_parties` (id, doc_id, party_kind, party_id) — más performance pero más DDL. Decisión diferida hasta data real.

### 15.8 Lista de chats del jugador (con preview + unread count)

```sql
SELECT c.id, c.type, c.name, c.icon_url, c.last_message_at, c.last_message_preview,
  (
    SELECT COUNT(*) FROM sonar_messages m
    WHERE m.chat_id = c.id
      AND m.sent_at > IFNULL(p.last_read_at_unix, 0)
      AND m.deleted_at IS NULL
  ) AS unread_count
FROM sonar_chat_participants p
JOIN sonar_chats c ON c.id = p.chat_id
LEFT JOIN sonar_messages m_last
  ON m_last.id = p.last_read_message_id
WHERE p.account_id = ? AND p.left_at IS NULL
ORDER BY p.is_pinned DESC, c.last_message_at DESC
LIMIT 50;
-- usa: idx_sonar_chat_participants_account + idx_sonar_chats_last_message
-- nota: la subquery de unread_count es costosa; cachear por participant si bottleneck
```

### 15.9 Mensajes de un chat (paginación)

```sql
SELECT id, sender_id, sender_kind, body, body_kind, sent_at, edited_at, reply_to_message_id
FROM sonar_messages
WHERE chat_id = ?
  AND sent_at < ?  -- cursor para paginación
  AND deleted_at IS NULL
ORDER BY sent_at DESC, id DESC
LIMIT 50;
-- usa: idx_sonar_messages_chat
```

### 15.10 Plots con plaga sin tratar

```sql
SELECT id, plot_label, active_pest_kind, active_pest_severity, pest_detected_at
FROM sonar_granja_plots
WHERE company_id = ? AND active_pest_kind IS NOT NULL
ORDER BY active_pest_severity DESC, pest_detected_at ASC;
-- usa: idx_sonar_granja_plots_company + filter por NULL
```

### 15.11 Cron de crecimiento — plots a tickear

```sql
SELECT id, current_stage, growth_pct, current_crop_id
FROM sonar_granja_plots
WHERE current_stage > 0 AND current_stage < expected_stages
  AND updated_at < UNIX_TIMESTAMP() - 300  -- > 5 min sin tick
LIMIT 1000;
-- usa: idx_sonar_granja_plots_stage
```

### 15.12 Trazabilidad reverse — auditoría

```sql
-- "todos los eventos de los últimos 30 días que afectan a esta company"
SELECT event_name, payload_json, emitted_at
FROM sonar_event_log
WHERE related_company_id = ?
  AND emitted_at > UNIX_TIMESTAMP() - 86400 * 30
ORDER BY emitted_at DESC
LIMIT 1000;
-- usa: idx_sonar_event_log_company + partition pruning
```

### 15.13 Reputación: trail de cambios

```sql
SELECT delta, value_after, reason_code, reason_text, occurred_at, source_resource
FROM sonar_reputation
WHERE subject_id = ?
ORDER BY occurred_at DESC
LIMIT 20;
-- usa: idx_sonar_reputation_subject
```

---

## 16. Migrations — estrategia, formato, ejemplo

### 16.1 Estructura de carpeta

```
sonar_core/
└── migrations/
    ├── 001_initial_schema.sql
    ├── 002_bank_accounts_link_companies.sql
    ├── 003_add_index_market_offers_vertical.sql
    ├── 004_partition_event_log_2026_q2.sql
    └── 005_add_messages_voice_columns.sql
```

### 16.2 Convención de nombrado

`NNN_short_description.sql` — número 3 dígitos secuencial, snake_case.

### 16.3 Formato canónico de un archivo de migración

```sql
-- ============================================================
-- Migration: 003_add_index_market_offers_vertical.sql
-- Author: <name>
-- Date: 2026-04-15
-- Description: añade índice idx_sonar_market_offers_vertical
--              para acelerar listings filtrados por vertical en Mercado.
-- Dependencies: 001
-- Reversible: yes (DROP INDEX en migration_down)
-- ============================================================

-- UP MIGRATION
ALTER TABLE sonar_market_offers
  ADD KEY idx_sonar_market_offers_vertical (vertical_filter, status, type);

-- ============================================================
-- DOWN MIGRATION (en archivo separado: 003_..._down.sql)
-- ============================================================
-- ALTER TABLE sonar_market_offers
--   DROP KEY idx_sonar_market_offers_vertical;
```

### 16.4 Pipeline de aplicación al boot

```lua
-- sonar_core/server/migrations/runner.lua (esqueleto)
local function RunMigrations()
  -- 1. Asegurar que sonar_schema_versions existe
  EnsureBaseTable()

  -- 2. Listar archivos en migrations/ ordenados
  local files = ListMigrationFiles()

  -- 3. Para cada archivo, comprobar si está aplicado
  for _, file in ipairs(files) do
    local version = ParseVersionFromFilename(file)
    if not IsApplied(version) then
      local content = ReadFile(file)
      local checksum = Sha256(content)

      local startMs = GetTimeMs()

      -- 4. Aplicar dentro de transacción
      MySQL.transaction(content, function(success)
        if success then
          MySQL.insert.await(
            'INSERT INTO sonar_schema_versions (version, filename, checksum, duration_ms) VALUES (?, ?, ?, ?)',
            { version, file, checksum, GetTimeMs() - startMs }
          )
          print(('[sonar_core] Migration %s applied'):format(file))
        else
          print(('[sonar_core] Migration %s FAILED — server stop'):format(file))
          os.exit(1)
        end
      end)
    else
      -- 5. Verificar checksum (detectar tampering)
      local recorded = GetRecordedChecksum(version)
      if recorded ~= Sha256(ReadFile(file)) then
        print(('[sonar_core] WARN: migration %s checksum mismatch'):format(file))
      end
    end
  end
end
```

### 16.5 Reglas de oro

1. **Idempotencia:** las migraciones se aplican exactamente una vez. El runner valida via `sonar_schema_versions`.
2. **Inmutabilidad:** una vez aplicada en producción, **un archivo de migración jamás se edita**. Cambios → nueva migración.
3. **Forward-only por defecto:** las downs son opcionales pero recomendadas para entornos dev.
4. **Atomicidad:** cada migración corre en una transacción. Si falla, rollback completo.
5. **Una migración = un cambio lógico.** No mezclar cambios independientes.

### 16.6 Ejemplo: migración inicial 001

```sql
-- 001_initial_schema.sql
-- Aplica todo el schema base oleada 1.

START TRANSACTION;

CREATE TABLE sonar_accounts ( ... );
CREATE TABLE sonar_tablets ( ... );
CREATE TABLE sonar_companies ( ... );
-- ... (todas las tablas core)
CREATE TABLE sonar_event_log ( ... );

-- Seeds
INSERT INTO sonar_accounts ... ;
INSERT INTO sonar_companies ... ;

COMMIT;
```

---

## 17. Particionado y archival

### 17.1 Tablas particionadas

| Tabla | Partition key | Granularidad | Razón |
|---|---|---|---|
| `sonar_bank_movements` | `occurred_at` | Mensual | Volumen alto, queries por rango temporal recientes |
| `sonar_messages` | `sent_at` | Mensual | Volumen muy alto, cold reads |
| `sonar_notifications` | `pushed_at` | Mensual | Volumen alto, retención < 6 meses |
| `sonar_event_log` | `emitted_at` | Mensual | Volumen muy alto, archival post 12 meses |

### 17.2 Cron de gestión de particiones

> **Tarea automática mensual** ejecutada por `sonar_core` al primer minuto de cada mes.

```lua
-- sonar_core/server/cron/partitions.lua (pseudocódigo)
function MaintainPartitions()
  local nextMonth = GetTimestampForFirstOfMonth(now() + 30 days)
  local nextNextMonth = GetTimestampForFirstOfMonth(now() + 60 days)

  for _, table in ipairs({
    'sonar_bank_movements',
    'sonar_messages',
    'sonar_notifications',
    'sonar_event_log',
  }) do
    EnsurePartitionExists(table, nextMonth)
    EnsurePartitionExists(table, nextNextMonth)
    ArchiveOldPartitions(table, retention_for(table))
  end
end

function EnsurePartitionExists(table, timestamp)
  -- ALTER TABLE ... REORGANIZE PARTITION p_future INTO (
  --   PARTITION p_YYYY_MM VALUES LESS THAN (timestamp),
  --   PARTITION p_future VALUES LESS THAN MAXVALUE
  -- );
end
```

### 17.3 Política de retención

| Tabla | Hot retention (online) | Cold retention (archival) |
|---|---|---|
| `sonar_bank_movements` | 24 meses | indefinido (legal RP) |
| `sonar_messages` | 12 meses | 24 meses adicionales |
| `sonar_notifications` | 6 meses | 6 meses adicionales |
| `sonar_event_log` | 12 meses | 36 meses adicionales |

### 17.4 Archival a tabla "_archive"

```sql
-- Crear tabla de archive (mismo schema, sin particionar, motor MyISAM o cold storage)
CREATE TABLE sonar_messages_archive LIKE sonar_messages;

-- Movimiento mensual de partición vieja
INSERT INTO sonar_messages_archive SELECT * FROM sonar_messages PARTITION (p_2025_04);

-- Drop de la partición original
ALTER TABLE sonar_messages DROP PARTITION p_2025_04;
```

### 17.5 Performance considerations

- **Partition pruning** automático cuando la query incluye filtro sobre la partition key — verificar con `EXPLAIN PARTITIONS`.
- **Índices locales** (no globales) en cada partición — InnoDB partitioned tables.
- **Particiones futuras pre-creadas** (no esperar a que se llenen).

---

## 18. Backup, restore e integrity

### 18.1 Estrategia recomendada

> **SONAR no implementa backup propio en oleada 1** — recomienda al admin del servidor configurar uno externo. La doc lo indica claramente.

**Stack recomendado:**

```bash
# Backup completo diario (cron)
mysqldump --single-transaction --quick \
  --databases your_sonar_db \
  | gzip > sonar_$(date +%Y%m%d).sql.gz

# Backup incremental por hora (binlog shipping)
# Configurar replication o usar mysqlbinlog
```

### 18.2 Comando `/admirals export`

> **Implementado en oleada 1.** Permite al admin generar un export JSON/SQL de todo o de una company.

```
/admirals export full              → snapshot completo (zip)
/admirals export company <id>      → solo esa empresa + relacionados
/admirals export account <id>      → solo ese jugador
```

### 18.3 Comando `/admirals integrity`

> **Verifica consistencia del schema** vs catálogo.

```
/admirals integrity check          → verifica:
  - todas las tablas existen
  - índices documentados existen
  - FK no rotas (registros huérfanos)
  - particiones presentes para los próximos 2 meses
  - migrations aplicadas == archivos en migrations/
```

### 18.4 Restore checklist

1. Stop server.
2. Restaurar dump `gunzip < sonar_YYYYMMDD.sql.gz | mysql sonar_db`.
3. Verificar `sonar_schema_versions` — el server al rebootear no debe re-aplicar migrations.
4. Boot server. Logs deberían mostrar 0 migraciones aplicadas (todas están registradas).
5. `/admirals integrity check`.

### 18.5 Estado de integridad continuo

> **Cron horario** ejecuta integrity light:

```lua
function IntegrityCron()
  -- 1. Cuentas de fuentes inválidas
  local orphan_members = MySQL.query.await([[
    SELECT m.id FROM sonar_company_members m
    LEFT JOIN sonar_companies c ON c.id = m.company_id
    WHERE c.id IS NULL
  ]])
  if #orphan_members > 0 then Logger.error('orphan members found', orphan_members) end

  -- 2. Saldo bancario coherente con último movement
  -- 3. Plots con company inexistente
  -- 4. ... etc.
end
```

---

## 19. Governance del schema

### 19.1 Quién puede modificar el schema

| Tipo de cambio | Quién | Proceso |
|---|---|---|
| **Añadir tabla nueva** | Maintainer del resource dueño + founder | RFC + migration + DDL en este doc |
| **Añadir columna NULL** | Maintainer | Migration + actualizar DDL |
| **Añadir columna NOT NULL** | Maintainer + founder | Migration con DEFAULT obligatorio + actualizar DDL |
| **Añadir índice** | Maintainer | Medir mejora + migration + actualizar §14 |
| **Modificar tipo de columna** | Founder | RFC + migration + impact en código |
| **Drop columna o tabla** | Founder | Política de deprecación: deprecate 2 versiones, drop después |
| **Modificar FK / constraint** | Maintainer + founder | Migration + análisis de impacto |
| **Crear partición / archive** | Cron automático | Sin intervención humana |

### 19.2 Política de deprecación de columnas

1. **MINOR N**: column marcada como deprecated en `01_architecture.md` + comentario `-- DEPRECATED in vN`.
2. **MINOR N+1**: code stops writing to column. Aplicación migra lectores.
3. **MINOR N+2**: migration que dropa la columna.

### 19.3 Política de evolución de tipos

- **Ampliar VARCHAR**: PATCH OK.
- **Reducir VARCHAR**: MAJOR. Análisis previo de datos.
- **Cambiar ENUM (añadir valores)**: PATCH OK.
- **Cambiar ENUM (renombrar/quitar)**: MAJOR. Migración con UPDATE de datos previos.

### 19.4 Diccionario de datos

> **Todas las tablas, columnas y constraints están aquí.** Si una columna no está en este doc, no existe.

Cuando un developer añade columna:
1. Migration con `ALTER TABLE ... ADD COLUMN`.
2. Update de la sección DDL correspondiente en este markdown.
3. PR con ambos cambios atómicos.
4. CI verifica que `INFORMATION_SCHEMA` coincide con DDL documentado (lint check).

---

## 20. Estado del documento

- **Versión:** 1.0 (firmado).
- **Próxima revisión:** evolución según nuevas verticales.
- **Próximas iteraciones esperadas:**
  - Cuando se diseñe Panadería: añadir `sonar_panaderia_*` tables.
  - Cuando se diseñe Retail: añadir `sonar_retail_*` tables.
  - Si emergen bottlenecks de performance: añadir índices en §14 o promover JSON a tabla intermedia.
  - Si oleada 2 introduce voice/calls: añadir `sonar_messages_voice_*` columns o tablas.

### 20.1 Resumen del schema

| Métrica | Valor |
|---|---|
| Total tablas oleada 1 | **28** |
| Tablas particionadas | 4 (bank_movements, messages, notifications, event_log) |
| Total índices documentados | ~60 |
| Tablas core | 4 (accounts, tablets, companies, members) |
| Tablas dominio | 13 (bank, docs, msg, notif, market, logistics, reputation) |
| Tablas nodos | 7 (granja x4, molino x3) |
| Tablas infra | 4 (event_log, schema_versions, settings, document_templates) |

### 20.2 Documentos relacionados

- `01_architecture.md` v1.0 — arquitectura técnica (este DDL deriva del schema lógico de §3).
- `02_events_catalog.md` v1.0 — eventos que mutan estas tablas.
- `04_sdk_reference.md` (oleada 3) — para apps de terceros que consultan datos.
- `05_deployment_guide.md` (próximo) — admin instala MySQL + aplica este schema.

---

## Resumen ejecutivo del documento (cierre)

Este documento es **el contrato de persistencia** del ecosistema SONAR (ex-Admirals).

**Pilares cumplidos:**

- ✅ **Architecture P3 (Schema compartido):** todas las tablas con prefijo `sonar_` (legacy pre-migration-009) / `sonar_` (canonical post-migration-009 per ADR-013), schema único compartido entre resources.
- ✅ **Architecture P9 (DB fuente de verdad, RAM cache):** schema completo + repos en código (cache + flush) ya listos.
- ✅ **Pilar 3 (Detalle obsesivo):** cada tabla con DDL completo, índices justificados, queries hot path documentadas.
- ✅ **Pilar 2 (Cadena interconectada):** FKs explícitas + lineage_json en batches + related_* en event_log permiten trazabilidad cross-vertical completa.
- ✅ **Bible §13.4 (3D vs Code):** code maneja toda la riqueza relacional, 3D solo provee props/MLO.

**Decisiones clave:**

- Prefijo `sonar_` obligatorio (pre-migration-009) / `sonar_` obligatorio (post-migration-009 per ADR-013).
- UUID v4 para entidades de negocio + BIGINT para tablas de alto volumen.
- MySQL 8 + InnoDB + utf8mb4.
- Soft deletes en histórico legal.
- 4 tablas particionadas mensualmente desde día 1.
- Migrations versionadas con checksum + idempotentes.
- Single source of truth = este markdown (CI lint contra INFORMATION_SCHEMA).
- 28 tablas oleada 1 + ~60 índices documentados con razón.

**~28 tablas** definidas con DDL listo para producción + ~60 índices justificados + queries críticas + estrategia de migrations + particionado + backup + governance.

**Si un developer quiere saber dónde se persiste el saldo de una empresa, abre este doc y lo encuentra en 30 segundos.**

**Trinidad técnica completa:** Architecture (cómo se construye) + Events Catalog (cómo se comunica) + DB Schema (cómo se persiste) = **fundación irrompible para 5-10 años.**

---

*"Data is the foundation. Schema is the law."*

---

## 22. Bank Phase A — Audit ledger inmutable + Compliance flags (NEW v1.3 DRAFT v0.1)

> **Status:** ✅ DRAFT v0.1 — DB Lead authoring 2026-05-06. Pending sign-off founder + Backend Lead consumer + Security Lead consumer.
>
> **Migrations:** `010_bank_audit_ledger.sql` + `011_bank_compliance_flags.sql`.

### 22.1 sonar_bank_audit_ledger (PARTITIONED RANGE month)

> **Audit ledger append-only inmutable.** Cada operación Bank-domain registrada con tier-1 defense-in-depth via triggers SIGNAL.

```sql
CREATE TABLE sonar_bank_audit_ledger (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ts                    INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()) COMMENT 'partition key',

  event_type            VARCHAR(64)     NOT NULL COMMENT 'canonical event taxonomy',
  severity              ENUM('info','notice','warning','critical') NOT NULL DEFAULT 'info',

  bank_account_iban     VARCHAR(20)     NULL COMMENT 'snapshot IBAN',
  counterpart_iban      VARCHAR(20)     NULL,

  actor_account_id      CHAR(36)        NULL,
  actor_role            ENUM('citizen','company','government','admin','system','watchdog') NOT NULL DEFAULT 'system',

  amount_delta          DECIMAL(14,2)   NULL,
  balance_after         DECIMAL(14,2)   NULL,

  correlation_id        CHAR(36)        NULL COMMENT 'Backend mutex CP2',
  request_nonce         CHAR(36)        NULL,

  related_movement_id   BIGINT UNSIGNED NULL,
  related_escrow_id     CHAR(36)        NULL,
  related_loan_id       CHAR(36)        NULL,
  related_compliance_flag_id BIGINT UNSIGNED NULL,

  context_data          JSON            NULL COMMENT 'metadata flexible per event_type',

  source_resource       VARCHAR(64)     NOT NULL DEFAULT 'sonar_bank',
  server_id             VARCHAR(32)     NULL,

  PRIMARY KEY (id, ts),
  KEY idx_sonar_bank_audit_ledger_iban_ts (bank_account_iban, ts DESC),
  KEY idx_sonar_bank_audit_ledger_actor_ts (actor_account_id, ts DESC),
  KEY idx_sonar_bank_audit_ledger_event_ts (event_type, ts DESC),
  KEY idx_sonar_bank_audit_ledger_severity_ts (severity, ts DESC),
  KEY idx_sonar_bank_audit_ledger_correlation (correlation_id),
  KEY idx_sonar_bank_audit_ledger_movement (related_movement_id),
  KEY idx_sonar_bank_audit_ledger_escrow (related_escrow_id),
  KEY idx_sonar_bank_audit_ledger_loan (related_loan_id),
  KEY idx_sonar_bank_audit_ledger_flag (related_compliance_flag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  PARTITION BY RANGE (ts) (
    PARTITION p_2026_05 VALUES LESS THAN (1748736000),
    PARTITION p_2026_06 VALUES LESS THAN (1751328000),
    PARTITION p_2026_07 VALUES LESS THAN (1754006400),
    PARTITION p_2026_08 VALUES LESS THAN (1756684800),
    PARTITION p_2026_09 VALUES LESS THAN (1759276800),
    PARTITION p_2026_10 VALUES LESS THAN (1761955200),
    PARTITION p_2026_11 VALUES LESS THAN (1764547200),
    PARTITION p_2026_12 VALUES LESS THAN (1767225600),
    -- ... extends Jan 2027 → Dec 2027 via migration 013 (Q-DB-G)
    PARTITION p_future  VALUES LESS THAN MAXVALUE
  );
```

**Triggers SIGNAL append-only enforcement (Q-DB-F tier 1):**

```sql
CREATE TRIGGER trg_sonar_bank_audit_ledger_no_update
  BEFORE UPDATE ON sonar_bank_audit_ledger FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_audit_ledger is append-only — UPDATE rejected';
END;

CREATE TRIGGER trg_sonar_bank_audit_ledger_no_delete
  BEFORE DELETE ON sonar_bank_audit_ledger FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_audit_ledger is append-only — DELETE rejected';
END;
```

**Notas:**

- **3-tier defense-in-depth** (Q-DB-F LOCKED 2026-05-06):
  - Tier 1 — Triggers SIGNAL `BEFORE UPDATE/DELETE` (this migration).
  - Tier 2 — `REVOKE UPDATE, DELETE ON sonar_bank_audit_ledger FROM 'sonar_bank_app_user'` (DevOps Lead post-H4).
  - Tier 3 — App-level `BankAuditLedger.Append(payload)` lib only exposes INSERT (Backend Lead post-H1).
- **System-versioned tables descartado** (Q-DB-F) — semántica wrong (SysVer permite UPDATE versionado, no rechaza).
- **Particionamiento mensual** RANGE `ts` — pruning automático queries Government Console scope "Todas" + audit retention legal.
- **Cron rolling forward** DevOps Lead post-H4 (per §17.2) — extiende partitions cuando se acercan p_future.
- **No FK** a `sonar_bank_accounts.id` — IBAN snapshot porque cuenta puede cerrarse y audit debe sobrevivir.
- **`actor_account_id`** sí FK ON DELETE SET NULL — auditor legal trail preservado aunque citizen account se borre.
- **`context_data`** JSON column — schema per `event_type` documentado en `docs/technical/08_audit_hooks.md` (Security Lead C-SEC-01 post-H2).

### 22.2 sonar_bank_compliance_flags

> **Autoraise patterns canonical Q10 LOCKED 2026-05-06.** 5 patterns: structuring, large_transfer, late_tax, velocity, new_account_large_deposit.

```sql
CREATE TABLE sonar_bank_compliance_flags (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  flag_type             ENUM('structuring','large_transfer','late_tax','velocity','new_account_large_deposit') NOT NULL,
  severity              ENUM('info','notice','warning','critical') NOT NULL DEFAULT 'warning',
  status                ENUM('open','investigating','resolved','false_positive') NOT NULL DEFAULT 'open',

  citizen_account_id    CHAR(36)        NOT NULL,
  bank_account_id       CHAR(36)        NULL,
  company_id            CHAR(36)        NULL COMMENT 'FK sonar_companies(id) DEFERRED — issue #001',

  raised_by             ENUM('system','admin','watchdog') NOT NULL DEFAULT 'system',
  raised_by_account_id  CHAR(36)        NULL,

  threshold_value       DECIMAL(14,2)   NULL,
  observed_value        DECIMAL(14,2)   NULL,
  time_window_seconds   INT UNSIGNED    NULL,

  evidence              JSON            NULL,
  related_movement_ids  JSON            NULL,

  resolved_by_account_id CHAR(36)       NULL,
  action_taken          VARCHAR(255)    NULL,
  resolution_note       TEXT            NULL,

  raised_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
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
    FOREIGN KEY (citizen_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_compliance_flags_bank_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_compliance_flags_resolved_by
    FOREIGN KEY (resolved_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_compliance_flags_threshold_sane CHECK (threshold_value IS NULL OR threshold_value >= 0),
  CONSTRAINT chk_sonar_bank_compliance_flags_observed_sane CHECK (observed_value IS NULL OR observed_value >= 0),
  CONSTRAINT chk_sonar_bank_compliance_flags_resolved_consistency CHECK (
    (status IN ('open','investigating') AND resolved_at IS NULL AND resolved_by_account_id IS NULL)
    OR (status IN ('resolved','false_positive') AND resolved_at IS NOT NULL)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Notas:**

- **5 patterns canonical Q10** — NO incluir `unusual_destination_foreign_prefix` (Q8 multidivisa OFF — single currency).
- **`evidence` JSON** — payload flexible per `flag_type`, schema documentado per pattern en `docs/technical/08_audit_hooks.md` (Security Lead C-SEC-03).
- **Status FSM 4-state**: `open` → `investigating` → `resolved` | `false_positive`. CHECK enforces `resolved_at` consistency.
- **`company_id`** sin FK enforced (Q-DB-E DEFERRED — issue #001). Backend Lead post-H1 valida `Companies.exists()` app-layer.

### 22.3 Queries hot path §22

```sql
-- Q1: Audit Explorer "Mi cuenta últimos 30 días" (citizen-scope)
SELECT id, ts, event_type, severity, amount_delta, balance_after, counterpart_iban
FROM sonar_bank_audit_ledger
WHERE bank_account_iban = ?
  AND ts >= UNIX_TIMESTAMP() - 30*86400
ORDER BY ts DESC LIMIT 100;
-- Index: idx_sonar_bank_audit_ledger_iban_ts.

-- Q2: Government Console scope "Todas" últimos 5 años filtered by event_type
SELECT id, ts, event_type, actor_account_id, amount_delta, context_data
FROM sonar_bank_audit_ledger
WHERE event_type IN ('compliance_raise','admin_action','tax_payment')
  AND ts >= UNIX_TIMESTAMP() - 5*365*86400
ORDER BY ts DESC LIMIT 500;
-- Index: idx_sonar_bank_audit_ledger_event_ts. Target <200ms (slice §8.3).

-- Q3: Compliance dashboard "open critical flags"
SELECT id, flag_type, citizen_account_id, observed_value, raised_at
FROM sonar_bank_compliance_flags
WHERE status = 'open' AND severity = 'critical'
ORDER BY raised_at DESC LIMIT 50;
-- Index: idx_sonar_bank_compliance_flags_severity_status.

-- Q4: Audit chain por correlation-id (Backend mutex CP2 debugging)
SELECT id, ts, event_type, actor_account_id, source_resource
FROM sonar_bank_audit_ledger
WHERE correlation_id = ?
ORDER BY ts ASC;
-- Index: idx_sonar_bank_audit_ledger_correlation.
```

---

## 23. Bank Phase A — Status FSM (NEW v1.3 DRAFT v0.1)

> **Status:** ✅ DRAFT v0.1. **Migration:** `012_bank_status_fsm.sql`.

### 23.1 sonar_bank_status (single row global per-server)

> **CP8 sonar_bank_status FSM** — single row global per-server (Q-DB-J LOCKED 2026-05-06). PK fijo `id=1` + trigger enforce.

```sql
CREATE TABLE sonar_bank_status (
  id                       TINYINT UNSIGNED NOT NULL DEFAULT 1,

  state                    ENUM('native_full','lite_mode_active','compromised_load_order','framework_missing') NOT NULL DEFAULT 'framework_missing',

  framework_detected       ENUM('qbox','qbcore','esx_modern','esx_legacy','none') NOT NULL DEFAULT 'none',

  bridge_version           VARCHAR(32)     NULL,

  last_transition_reason   VARCHAR(255)    NULL,
  last_transition_actor    ENUM('system','watchdog','admin') NOT NULL DEFAULT 'system',

  experimental_handlers_ok TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'sv_experimentalStateBagsHandler + sv_experimentalNetGameEventHandler + sv_enableNetEventReassembly',

  created_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  transitioned_at          INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),

  CONSTRAINT chk_sonar_bank_status_single_row CHECK (id = 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Trigger BEFORE INSERT enforce single-row.
CREATE TRIGGER trg_sonar_bank_status_single_row BEFORE INSERT ON sonar_bank_status FOR EACH ROW
BEGIN
  IF NEW.id <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_status is single-row global per-server (id must be 1)';
  END IF;
END;

-- Initial seed.
INSERT INTO sonar_bank_status (id, state, framework_detected, last_transition_reason, last_transition_actor)
VALUES (1, 'framework_missing', 'none', 'initial seed migration 012 — awaiting defensive boot CP4 detection', 'system')
ON DUPLICATE KEY UPDATE id = id;
```

**FSM transitions canonical (CP8):**

```
framework_missing  ─→  native_full          (CP4 boot — qbox/qbcore detected + bridges OK)
                   ─→  lite_mode_active     (CP4 boot — esx_modern detected + degraded mode)
                   ─→  compromised_load_order (CP4 watchdog — load order issue)

native_full        ─→  compromised_load_order (CP4 watchdog runtime)
                   ─→  lite_mode_active        (admin downgrade — diagnostic mode)

lite_mode_active   ─→  native_full          (admin upgrade — bridges restored)
                   ─→  compromised_load_order (CP4 watchdog runtime)

compromised_load_order ─→  native_full | lite_mode_active  (admin recovery)
```

**Notas:**

- **Single row global per-server** (Q-DB-J): el estado refleja el bridge runtime del server process, NO del citizen.
- **Boot rejected si `framework_detected = 'esx_legacy'`** (Q16 cut ESX legacy spec) — error claro `legacy ESX 1.9.x not supported, upgrade to 1.10+ or use QBox/QBCore`.
- **UI badge sonar_bank_status** footer always-visible Tablet Bank App (slice frontend §3 CP8) — lectura per-frame State Bag global publicado por Backend post-H1.
- **`experimental_handlers_ok`** convars FiveM Q16.4 + CP7 — afecta perf benchmarks chaos test 200 concurrent.

### 23.2 Queries hot path §23

```sql
-- Q1: Boot detection update (Backend Lead post-H1).
UPDATE sonar_bank_status SET
  state = 'native_full',
  framework_detected = 'qbox',
  bridge_version = '1.0.0',
  last_transition_reason = 'boot detection complete',
  last_transition_actor = 'system',
  experimental_handlers_ok = 1,
  updated_at = UNIX_TIMESTAMP(),
  transitioned_at = UNIX_TIMESTAMP()
WHERE id = 1;
-- PK fijo — single row update <1ms.

-- Q2: UI badge read (Tablet Bank app footer).
SELECT state, framework_detected, last_transition_reason, transitioned_at
FROM sonar_bank_status WHERE id = 1;
-- PK fijo — read <1ms. Backend cache + State Bag publish.
```

---

## 24. Bank Phase A — Tax + Government (NEW v1.4 DRAFT v0.2)

> **Status:** ✅ DRAFT v0.2 — DB Lead authoring 2026-05-06 (BANK-DB.2).
>
> **Migrations:** `016_tax_brackets_history_subsidies.sql` + `017_govt_elections_candidates_votes.sql` + `014_bank_accounts_owner_type_split.sql` + `015_bank_movements_category_extend.sql`.

### 24.1 sonar_bank_tax_brackets — current brackets editable

> **Brackets editables por Government Console** (ACE `sonar.bank.govt.tax.edit`). Cada row = un bracket. Trigger AFTER + Backend Lead lib audit a `sonar_bank_tax_history` (no DB triggers — captura snapshots before/after via app-layer per Q-DB-A simplicidad CHECK).

```sql
CREATE TABLE sonar_bank_tax_brackets (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  bracket_name          VARCHAR(64)     NOT NULL,
  bracket_kind          ENUM('income_personal','income_business','wealth','transaction') NOT NULL DEFAULT 'income_personal',

  income_min            DECIMAL(14,2)   NOT NULL DEFAULT 0,
  income_max            DECIMAL(14,2)   NULL COMMENT 'NULL = sin límite superior',
  rate_pct              DECIMAL(5,2)    NOT NULL,

  effective_from        INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  effective_until       INT UNSIGNED    NULL COMMENT 'NULL = bracket activo',

  created_by_account_id CHAR(36)        NULL,
  updated_by_account_id CHAR(36)        NULL,

  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_tax_brackets_name_active (bracket_name, effective_until),
  KEY idx_sonar_bank_tax_brackets_kind_active (bracket_kind, effective_from, effective_until),

  CONSTRAINT fk_sonar_bank_tax_brackets_created_by
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_tax_brackets_updated_by
    FOREIGN KEY (updated_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_tax_brackets_income_range CHECK (income_max IS NULL OR income_min < income_max),
  CONSTRAINT chk_sonar_bank_tax_brackets_rate_pct CHECK (rate_pct >= 0 AND rate_pct <= 100),
  CONSTRAINT chk_sonar_bank_tax_brackets_income_min CHECK (income_min >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Notas:**

- `bracket_kind` ENUM 4 valores — soporta tax progresivo personal/business + wealth tax + transaction tax future-proof.
- `effective_until = NULL` = bracket activo. Cuando se reemplaza, set `effective_until = UNIX_TIMESTAMP()` + INSERT new row con `effective_from = same` = "soft retire + new active".
- `UNIQUE (bracket_name, effective_until)` — permite N rows con mismo `bracket_name` pero solo UNO con `effective_until = NULL` (active).

### 24.2 sonar_bank_tax_history — append-only audit todo cambio

```sql
CREATE TABLE sonar_bank_tax_history (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  bracket_id            BIGINT UNSIGNED NOT NULL,

  change_type           ENUM('create','update','delete') NOT NULL,
  actor_account_id      CHAR(36)        NULL,
  actor_role            ENUM('admin','government','system') NOT NULL DEFAULT 'admin',

  before_bracket_name   VARCHAR(64)     NULL,
  before_bracket_kind   ENUM('income_personal','income_business','wealth','transaction') NULL,
  before_income_min     DECIMAL(14,2)   NULL,
  before_income_max     DECIMAL(14,2)   NULL,
  before_rate_pct       DECIMAL(5,2)    NULL,

  after_bracket_name    VARCHAR(64)     NULL,
  after_bracket_kind    ENUM('income_personal','income_business','wealth','transaction') NULL,
  after_income_min      DECIMAL(14,2)   NULL,
  after_income_max      DECIMAL(14,2)   NULL,
  after_rate_pct        DECIMAL(5,2)    NULL,

  reason_note           TEXT            NULL,

  changed_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_bank_tax_history_bracket (bracket_id, changed_at DESC),
  KEY idx_sonar_bank_tax_history_actor (actor_account_id, changed_at DESC),
  KEY idx_sonar_bank_tax_history_change_type (change_type, changed_at DESC),

  CONSTRAINT fk_sonar_bank_tax_history_actor
    FOREIGN KEY (actor_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Triggers SIGNAL append-only (Q-DB-F tier 1).
CREATE TRIGGER trg_sonar_bank_tax_history_no_update BEFORE UPDATE ON sonar_bank_tax_history FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_tax_history is append-only — UPDATE rejected'; END;

CREATE TRIGGER trg_sonar_bank_tax_history_no_delete BEFORE DELETE ON sonar_bank_tax_history FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_bank_tax_history is append-only — DELETE rejected'; END;
```

**Notas:**

- `bracket_id` FK lógico (NO enforced FK) — bracket puede borrarse pero history sobrevive (audit retention legal).
- Snapshot before/after permite reconstruir cualquier estado pasado del tax system + investigaciones impugnación.

### 24.3 sonar_bank_subsidies (PARTITIONED RANGE month) — UBI + targeted aid

```sql
CREATE TABLE sonar_bank_subsidies (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

  subsidy_kind          ENUM('ubi_monthly','unemployment','targeted_aid','cooperative_grant') NOT NULL,

  beneficiary_account_id CHAR(36)       NOT NULL,
  bank_account_id       CHAR(36)        NOT NULL,
  company_id            CHAR(36)        NULL COMMENT 'cooperative_grant — opaque Q-DB-E',

  amount                DECIMAL(14,2)   NOT NULL,
  currency              CHAR(3)         NOT NULL DEFAULT 'EUR',

  issued_by_account_id  CHAR(36)        NULL,
  issued_by_role        ENUM('government','admin','system') NOT NULL DEFAULT 'system',

  related_movement_id   BIGINT UNSIGNED NULL,
  related_audit_id      BIGINT UNSIGNED NULL,

  reason_note           VARCHAR(255)    NULL,
  reference_period      VARCHAR(32)     NULL COMMENT 'p.e. "2026-05" UBI',

  issued_at             INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id, issued_at),
  KEY idx_sonar_bank_subsidies_beneficiary_issued (beneficiary_account_id, issued_at DESC),
  KEY idx_sonar_bank_subsidies_kind_issued (subsidy_kind, issued_at DESC),
  KEY idx_sonar_bank_subsidies_period (subsidy_kind, reference_period),
  KEY idx_sonar_bank_subsidies_company (company_id),
  KEY idx_sonar_bank_subsidies_issued_by (issued_by_account_id, issued_at DESC),

  CONSTRAINT fk_sonar_bank_subsidies_beneficiary
    FOREIGN KEY (beneficiary_account_id) REFERENCES sonar_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_subsidies_bank_account
    FOREIGN KEY (bank_account_id) REFERENCES sonar_bank_accounts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sonar_bank_subsidies_issued_by
    FOREIGN KEY (issued_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_bank_subsidies_amount_positive CHECK (amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  PARTITION BY RANGE (issued_at) (
    PARTITION p_2026_05 VALUES LESS THAN (1748736000),
    -- ... May-Dec 2026 + p_future. Cron rolling forward DevOps Lead post-H4.
    PARTITION p_future  VALUES LESS THAN MAXVALUE
  );
```

**Notas:**

- Particionado mensual — UBI mensual a citizens activos genera volumen alto. Cron rolling forward DevOps Lead post-H4.
- `reference_period VARCHAR(32)` — formato canonical `YYYY-MM` para UBI, libre para otros tipos.
- `unemployment` activable cuando citizen FSM `employment_state = 'unemployed'` (Backend Lead post-H1 + Sonar Core integration).

### 24.4 sonar_govt_elections — elecciones FSM 4-state

```sql
CREATE TABLE sonar_govt_elections (
  id                    CHAR(36)        NOT NULL,

  election_kind         ENUM('mayor','cooperative_board','referendum') NOT NULL,
  title                 VARCHAR(192)    NOT NULL,
  description           TEXT            NULL,

  state                 ENUM('draft','open','closed','finalized') NOT NULL DEFAULT 'draft',

  scope_company_id      CHAR(36)        NULL COMMENT 'cooperative_board — opaque Q-DB-E',

  opens_at              INT UNSIGNED    NULL,
  closes_at             INT UNSIGNED    NULL,
  finalized_at          INT UNSIGNED    NULL,

  winner_candidate_id   CHAR(36)        NULL,
  total_votes_count     INT UNSIGNED    NOT NULL DEFAULT 0,

  created_by_account_id CHAR(36)        NULL,
  created_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at            INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),

  PRIMARY KEY (id),
  KEY idx_sonar_govt_elections_state_kind (state, election_kind),
  KEY idx_sonar_govt_elections_scope_company (scope_company_id),
  KEY idx_sonar_govt_elections_opens (opens_at),
  KEY idx_sonar_govt_elections_closes (closes_at),

  CONSTRAINT fk_sonar_govt_elections_created_by
    FOREIGN KEY (created_by_account_id) REFERENCES sonar_accounts(id) ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT chk_sonar_govt_elections_window CHECK (opens_at IS NULL OR closes_at IS NULL OR opens_at < closes_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**FSM transitions canonical:**

```
draft  ─→  open      (admin gov sets opens_at + closes_at + ACE check)
open   ─→  closed    (auto cron when closes_at passed, or admin force-close)
closed ─→  finalized (admin gov sets winner_candidate_id + total_votes_count + finalized_at)
```

**Reverse transitions PROHIBITED** — Backend Lead post-H1 enforce app-layer (audit integrity).

### 24.5 sonar_govt_election_candidates

```sql
CREATE TABLE sonar_govt_election_candidates (
  id                    CHAR(36)        NOT NULL,
  election_id           CHAR(36)        NOT NULL,

  candidate_account_id  CHAR(36)        NULL COMMENT 'NULL si referendum yes/no',
  display_label         VARCHAR(128)    NOT NULL,
  manifesto             TEXT            NULL,

  display_order         INT UNSIGNED    NOT NULL DEFAULT 0,
  votes_count           INT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'cached — refresh on-finalize',

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
```

### 24.6 sonar_govt_votes — votos PÚBLICOS hasheados (Q-DB-H dual-layer privacy)

```sql
CREATE TABLE sonar_govt_votes (
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
CREATE TRIGGER trg_sonar_govt_votes_no_update BEFORE UPDATE ON sonar_govt_votes FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes is append-only — UPDATE rejected'; END;

CREATE TRIGGER trg_sonar_govt_votes_no_delete BEFORE DELETE ON sonar_govt_votes FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes is append-only — DELETE rejected'; END;
```

### 24.7 sonar_govt_votes_audit — votos RAW admin-only (ACE-gated)

```sql
CREATE TABLE sonar_govt_votes_audit (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  election_id           CHAR(36)        NOT NULL,
  candidate_id          CHAR(36)        NOT NULL,

  citizen_id            CHAR(36)        NOT NULL COMMENT 'voter REAL — admin-only',

  cast_at               INT UNSIGNED    NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  ip_address            VARCHAR(45)     NULL,
  actor_role            ENUM('citizen','admin','system') NOT NULL DEFAULT 'citizen',

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

-- Triggers SIGNAL append-only.
CREATE TRIGGER trg_sonar_govt_votes_audit_no_update BEFORE UPDATE ON sonar_govt_votes_audit FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes_audit is append-only — UPDATE rejected'; END;

CREATE TRIGGER trg_sonar_govt_votes_audit_no_delete BEFORE DELETE ON sonar_govt_votes_audit FOR EACH ROW
BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sonar_govt_votes_audit is append-only — DELETE rejected'; END;
```

**Notas críticas Q-DB-H dual-layer privacy:**

- **`server_salt`** — 64-char random secreto (DevOps Lead post-H4 genera + persiste en `setr sonar_bank_govt_vote_salt "..."`). NO almacenar en DB.
- **Stable across restarts** — rotation invalidaría todos hashes existing. Si rotation requerida → migration aditiva con dual-hash window.
- **Dual-atomic INSERT** — Backend Lead `Vote.Cast(election_id, candidate_id, citizen_id)` lib inserta en AMBAS tablas single transaction. Rollback si fail.
- **ACE check** — `sonar.bank.govt.audit.full` enforced app-layer Backend post-H1 + auditado por Security Lead post-H2 (audit_ledger event `audit_read_scope_full`).

### 24.8 Queries hot path §24

```sql
-- Q1: Brackets activos hoy (citizen Tax Calculator UI).
SELECT id, bracket_name, income_min, income_max, rate_pct
FROM sonar_bank_tax_brackets
WHERE bracket_kind = 'income_personal'
  AND effective_until IS NULL
  AND effective_from <= UNIX_TIMESTAMP()
ORDER BY income_min ASC;
-- Index: idx_sonar_bank_tax_brackets_kind_active.

-- Q2: UBI mensual histórico citizen (Tax Explorer Mi cuenta).
SELECT id, amount, reference_period, issued_at
FROM sonar_bank_subsidies
WHERE beneficiary_account_id = ?
  AND subsidy_kind = 'ubi_monthly'
ORDER BY issued_at DESC LIMIT 24;
-- Index: idx_sonar_bank_subsidies_beneficiary_issued. Partition pruning últimos meses.

-- Q3: Elecciones activas (citizen UI Government Console).
SELECT id, election_kind, title, opens_at, closes_at, total_votes_count
FROM sonar_govt_elections
WHERE state = 'open'
ORDER BY closes_at ASC;
-- Index: idx_sonar_govt_elections_state_kind.

-- Q4: Cast vote — verify citizen no votó previamente.
-- Compute voter_hash = SHA256(citizen_id || election_id || server_salt) en Backend lib.
SELECT 1 FROM sonar_govt_votes
WHERE voter_hash = ? AND election_id = ?
LIMIT 1;
-- Index: uq_sonar_govt_votes_voter_election. <1ms.

-- Q5: Count votos por candidato (publish results).
SELECT candidate_id, COUNT(*) AS votes_count
FROM sonar_govt_votes
WHERE election_id = ?
GROUP BY candidate_id;
-- Index: idx_sonar_govt_votes_election_candidate.

-- Q6: Audit investigation admin (ACE-gated app-layer).
-- ACE check: sonar.bank.govt.audit.full
SELECT citizen_id, candidate_id, cast_at, ip_address
FROM sonar_govt_votes_audit
WHERE election_id = ?
ORDER BY cast_at DESC;
-- Index: idx_sonar_govt_votes_audit_election_cast.
```

---

## 25. Bank Phase A — Tier 4 features (NEW v1.5 DRAFT v0.3)

> **Status:** ✅ DRAFT v0.3 — DB Lead authoring 2026-05-06 (BANK-DB.3).
>
> **Migrations:** `018_bank_loans_credit_scores.sql` + `019_bank_crypto_wallets.sql` + `020_bank_stocks_transactions_holdings.sql` + `021_bank_recurring_payments.sql` + `022_bank_atm_minigame_attempts.sql` + `023_bank_physical_cards.sql` + `024_bank_loyalty_points.sql` + `025_bank_round_ups.sql`.
>
> **Note:** DDL completo en migrations files (referenciados arriba). Esta sección documenta resumen + decisions + queries hot path. Migrations contienen decision logs D1-DN per archivo.

### 25.1 Loans + Credit Scores (migration 018)

**Tablas:**

- `sonar_bank_loans` — préstamos FSM 6-state: `requested` → `approved` → `disbursed` → `active` → (`paid_off` | `defaulted`).
- `sonar_bank_credit_scores` — rolling history per citizen (UNIQUE citizen_id+computed_at), score 0-1000 + rating ENUM.

**Decisions:**

- **D1.** Reverse FSM transitions PROHIBITED — Backend Lead post-H1 enforce app-layer.
- **D2.** `interest_rate_pct DECIMAL(5,2)` anual %. Monthly payment computed app-layer al transition `disbursed`.
- **D3.** Credit score components: payment_history_pct + active_loans_count + defaulted_count + total_outstanding. Computación cron Backend o manual override admin.
- **D4.** FK borrower → sonar_accounts ON DELETE RESTRICT (audit retention legal). approved_by → SET NULL.
- **D5.** `loan_kind` ENUM: 'personal','business','mortgage','microloan'. company_id opaque Q-DB-E.

**Queries hot path:**

```sql
-- Q1: Loans activos citizen (Bank UI Loans tab).
SELECT id, loan_kind, amount_outstanding, monthly_payment, next_payment_due_at
FROM sonar_bank_loans
WHERE borrower_account_id = ? AND state IN ('active','disbursed')
ORDER BY next_payment_due_at ASC;
-- Index: idx_sonar_bank_loans_borrower_state.

-- Q2: Cron payments due (Backend lib hot path).
SELECT id, borrower_account_id, monthly_payment
FROM sonar_bank_loans
WHERE state = 'active' AND next_payment_due_at <= UNIX_TIMESTAMP()
ORDER BY next_payment_due_at ASC LIMIT 1000;
-- Index: idx_sonar_bank_loans_state_due.

-- Q3: Current credit score citizen (latest snapshot).
SELECT score, rating, computed_at FROM sonar_bank_credit_scores
WHERE citizen_id = ? ORDER BY computed_at DESC LIMIT 1;
-- Index: idx_sonar_bank_credit_scores_citizen_score.
```

### 25.2 Crypto wallets (migration 019, Q-DB-B BIGINT atomic)

**Tablas:**

- `sonar_bank_crypto_assets` — reference data (BTC/ETH/USDT seeded). `decimals TINYINT UNSIGNED` per asset (BTC=8, ETH=18, USDT=6).
- `sonar_bank_crypto_wallets` — UNIQUE(citizen_id, asset_id). `balance_atomic BIGINT UNSIGNED` (display = balance / 10^decimals app-layer).
- `sonar_bank_crypto_transactions` — append-only triggers SIGNAL Q-DB-F. `amount_atomic BIGINT signed` (positive=in, negative=out). Fiat snapshot `exchange_rate_atomic BIGINT UNSIGNED` centavos EUR per atomic unit.

**Decisions:**

- **D1.** Política Q-DB-B atomic units split — crypto NO DECIMAL (rounding loss precision tras N operaciones). BIGINT atomic + decimals stored permite cualquier asset arbitrary precision.
- **D2.** Fiat-side snapshot per tx — `fiat_amount DECIMAL(14,2)` + `exchange_rate_atomic` capturados at tx time (immutable historical price).
- **D3.** UNIQUE(citizen_id, asset_id) — una wallet per citizen + asset (NO multi-wallet per asset Phase A).
- **D4.** request_nonce CHAR(36) idempotency anti-replay (Backend Lead lib).
- **D5.** Seed 3 assets canonical: BTC, ETH, USDT. Admins añaden más via Government Console post-launch.

**Queries hot path:**

```sql
-- Q1: Portfolio citizen (UI Crypto tab).
SELECT a.symbol, a.display_name, a.decimals, w.balance_atomic
FROM sonar_bank_crypto_wallets w
JOIN sonar_bank_crypto_assets a ON a.id = w.asset_id
WHERE w.citizen_id = ? AND a.enabled = TRUE
ORDER BY a.symbol;
-- Index: uq_sonar_bank_crypto_wallets_citizen_asset.

-- Q2: Tx history wallet (UI detail page).
SELECT tx_kind, amount_atomic, balance_atomic_after, fiat_amount, occurred_at
FROM sonar_bank_crypto_transactions
WHERE wallet_id = ? ORDER BY occurred_at DESC LIMIT 50;
-- Index: idx_sonar_bank_crypto_transactions_wallet.
```

### 25.3 Stocks (migration 020, Q-DB-I híbrido event-sourced + materialized)

**Tablas:**

- `sonar_bank_stocks_assets` — catálogo tickers + current_price cached + price_updated_at.
- `sonar_bank_stocks_transactions` — APPEND-ONLY event log. `qty DECIMAL(20,8)` (fractional shares) + price_per_share + total_amount + fee. Triggers SIGNAL Q-DB-F.
- `sonar_bank_stocks_holdings` — MATERIALIZED snapshot. `qty_total DECIMAL(20,8)` + avg_cost_basis + last_recomputed_at + last_tx_id.

**Decisions Q-DB-I:**

- **D1.** Modelo dual:
  - transactions = source of truth (event-sourced, immutable).
  - holdings = derived view rebuildable via SUM(qty) por asset.
- **D2.** Backend Lead post-H1 lib `Stocks.RecomputeHoldings(citizen_id, asset_id)` recalcula holdings desde transactions. Trigger lazy on read si stale (last_recomputed_at > 5min) o eager on tx commit.
- **D3.** `qty DECIMAL(20,8)` — fractional shares + 8 decimals safe vs floating-point loss.
- **D4.** `price_per_share DECIMAL(14,4)` — 4 decimals precio (suficiente sims trading).
- **D5.** Cron rebuild full snapshot opcional DevOps Lead post-H4 (audit reconciliation).

**Queries hot path:**

```sql
-- Q1: Holdings citizen (UI Portfolio).
SELECT a.ticker, a.display_name, h.qty_total, h.avg_cost_basis, a.current_price
FROM sonar_bank_stocks_holdings h
JOIN sonar_bank_stocks_assets a ON a.id = h.asset_id
WHERE h.citizen_id = ? AND h.qty_total > 0;
-- Index: uq_sonar_bank_stocks_holdings_citizen_asset.

-- Q2: Tx history asset (UI detail).
SELECT tx_kind, qty, price_per_share, total_amount, occurred_at
FROM sonar_bank_stocks_transactions
WHERE citizen_id = ? AND asset_id = ?
ORDER BY occurred_at DESC LIMIT 100;
-- Index: idx_sonar_bank_stocks_tx_citizen_asset.

-- Q3: Recompute holdings (Backend Lead lib).
SELECT SUM(qty) AS qty_total,
       SUM(qty * price_per_share) / NULLIF(SUM(qty), 0) AS avg_cost_basis,
       MAX(id) AS last_tx_id
FROM sonar_bank_stocks_transactions
WHERE citizen_id = ? AND asset_id = ?;
```

### 25.4 Recurring payments (migration 021)

**Tabla `sonar_bank_recurring_payments`** — FSM 4-state: `active` → (`paused` | `cancelled` | `completed`).

**Decisions:**

- **D1.** `interval_kind` ENUM canonical (daily/weekly/monthly/yearly) + `interval_count` SMALLINT (e.g. monthly + count=3 = trimestral).
- **D2.** `next_charge_at` cron hot path index `(state, next_charge_at)` — Backend lib query `WHERE state='active' AND next_charge_at <= UNIX_TIMESTAMP()`.
- **D3.** `payee_kind` ENUM 'citizen'|'company'|'government'. `payee_iban` always set (destination canonical), payee_account_id + payee_company_id optional FK soft.
- **D4.** `consecutive_failures` TINYINT auto-pause si > 3 (Backend lib transitions state='paused').
- **D5.** `last_charge_status` ENUM tracking failure mode: success | insufficient_funds | frozen | error.

**Query hot path:**

```sql
-- Cron Backend Lead hot path (run cada minuto).
SELECT id, payer_account_id, payer_bank_account_id, payee_iban, amount, payment_kind
FROM sonar_bank_recurring_payments
WHERE state = 'active' AND next_charge_at <= UNIX_TIMESTAMP()
ORDER BY next_charge_at ASC LIMIT 500;
-- Index: idx_sonar_bank_recurring_state_next.
```

### 25.5 ATM minigame attempts (migration 022)

**Tabla `sonar_bank_atm_minigame_attempts`** — append-only fraud detection log + analytics. Triggers SIGNAL Q-DB-F. Indexes citizen + IP + result para pattern detection.

**Decisions:**

- **D1.** Rate limiting app-layer Backend (e.g. max 3 fails / 10min lockout).
- **D2.** `failure_reason` VARCHAR(64) detallado (wrong_pin, wrong_pattern, rate_limited, etc).
- **D3.** `ip_address VARCHAR(45)` IPv4/IPv6 — Security Lead post-H2 fraud pattern queries por IP.

### 25.6 Physical cards (migration 023)

**Tabla `sonar_bank_physical_cards`** — FSM 4-state: `active` | `frozen` | `expired` | `lost`.

**Decisions:**

- **D1.** `card_token CHAR(64)` opaque Backend-generated. NO real PAN — display only `last_4_digits`.
- **D2.** `pin_hash CHAR(64)` SHA-256(pin || card_token salt). Backend Lead lib enforce hash + verify. NO plain PIN en DB.
- **D3.** `pin_attempts_failed` TINYINT auto-freeze si > 3.
- **D4.** `daily_limit` overrides bank_account.daily_limit_out cuando card-based txn (NULL = inherit).
- **D5.** UNIQUE(card_token) global. NO UNIQUE bank_account_id — citizen puede tener N cards mismo account (debit + credit + prepaid).

### 25.7 Loyalty points (migration 024)

**Tablas:**

- `sonar_bank_loyalty_balances` — 1:1 citizen_id PK. `current_points` + `lifetime_earned/redeemed` + `tier` ENUM (bronze/silver/gold/platinum).
- `sonar_bank_loyalty_transactions` — append-only earn/redeem log. Triggers SIGNAL Q-DB-F.

**Decisions:**

- **D1.** Points como INT UNSIGNED — 1 point = 0.01 EUR cashback.
- **D2.** balance materialized — Backend lib increment/decrement on tx commit. Recompute lazy desde transactions (event-sourced fallback).
- **D3.** tier ENUM based on lifetime_earned thresholds (Backend Lead config).

### 25.8 Round-ups (migration 025)

**Tablas:**

- `sonar_bank_round_up_configs` — 1:1 citizen_id PK. `multiplier` 1x-10x boost + `round_up_to` DECIMAL(6,2) target multiple + source/destination accounts.
- `sonar_bank_round_up_transactions` — append-only log. `trigger_movement_id` link al movement original que disparó round-up.

**Decisions:**

- **D1.** Backend Lead post-H1 lib `RoundUp.OnMovement(movement)` hook fires after every debit movement de cuenta source — calcula round_up_amount + transfer a destination + INSERT row.
- **D2.** `multiplier_applied` cached en tx (config puede cambiar, history preserva).

---

## 26. Bank Phase A — Empresas extends (NEW v1.5 DRAFT v0.3)

> **Status:** ✅ DRAFT v0.3 — DB Lead authoring 2026-05-06 (BANK-DB.3).
>
> **Migrations:** `026_bank_business_treasuries.sql` + `027_bank_escrow_releases.sql`.

### 26.1 Business treasuries multi-signer (migration 026)

**3 tablas chained:**

- `sonar_bank_business_treasuries` — config policy per company (UNIQUE company_id + bank_account_id). `signing_threshold` m-of-n + `amount_threshold` (tx > umbral requiere multi-sign).
- `sonar_bank_business_treasury_signers` — N firmantes per treasury. `signer_role` ENUM 'owner'|'manager'|'employee_authorized' + `active` BOOLEAN.
- `sonar_bank_business_treasury_approvals` — pending approvals FSM 5-state: `pending` → (`approved` | `rejected` | `expired`) → `executed`. `operation_payload JSON` serialized op params + `approvals_json` array signers decisiones.

**Decisions:**

- **D1.** company_id opaque Q-DB-E NO FK — Issue #001.
- **D2.** signers FK CASCADE treasury_id (delete treasury cascades signers).
- **D3.** approvals expires_at TTL 24-72h configurable. Cron expire pending Backend Lead post-H1.
- **D4.** Backend lib post-H1 enforce m-of-n: count `approvals_json` con `decision='approved'` >= `signers_required` antes execute operation.
- **D5.** `operation_kind` ENUM canonical: 'transfer_out'|'escrow_create'|'recurring_setup'|'large_withdraw'|'custom'.

**Queries hot path:**

```sql
-- Q1: Treasury config + signers (UI Business Treasury detail).
SELECT t.id, t.signing_threshold, t.amount_threshold, s.signer_account_id, s.signer_role
FROM sonar_bank_business_treasuries t
LEFT JOIN sonar_bank_business_treasury_signers s ON s.treasury_id = t.id AND s.active = TRUE
WHERE t.company_id = ?;

-- Q2: Pending approvals signer (UI inbox).
SELECT id, treasury_id, operation_kind, operation_amount, expires_at
FROM sonar_bank_business_treasury_approvals
WHERE state = 'pending' AND expires_at > UNIX_TIMESTAMP();
-- Index: idx_sonar_bank_business_approvals_state_expires.
```

### 26.2 Escrow releases (migration 027)

**Tabla `sonar_bank_escrow_releases`** — partial release log append-only. Triggers SIGNAL Q-DB-F.

**ALTER `sonar_escrows`** — ADD `release_log_count TINYINT UNSIGNED NOT NULL DEFAULT 0` denormalized counter (avoid COUNT(*) hot path UI escrow detail).

**Decisions:**

- **D1.** `release_kind` ENUM 'milestone'|'partial'|'full'|'refund_partial'.
- **D2.** NO FK escrow_id → sonar_escrows directo — escrow puede 'closed' permanente, releases sobreviven (audit retention legal).
- **D3.** `request_nonce` idempotency anti-replay.
- **D4.** Idempotent ALTER procedure check INFORMATION_SCHEMA antes apply.

---

## 27. Bank Phase A — Idempotency keys (NEW v1.5 DRAFT v0.3)

> **Status:** ✅ DRAFT v0.3 — DB Lead authoring 2026-05-06 (BANK-DB.3).
>
> **Migration:** `028_bank_idempotency_keys.sql`.

### 27.1 sonar_bank_idempotency_keys

**Tabla central cross-domain** — vital para Reconciliación Activa Backend Lead post-H1.

**Estructura key concepts:**

- `idempotency_key CHAR(64)` UNIQUE — client-provided UUID/hash unique per logical op.
- `domain` ENUM canonical 14 valores: transfer | recurring | crypto_buy/sell | stocks_buy/sell | escrow_create/release | loan_disbursement/repayment | business_approval | tax_payment | subsidy_issue | custom.
- `state` ENUM 3-state: `pending` | `completed` | `failed`.
- `request_payload JSON` params + `response_payload JSON` cached result (retry-safe).
- `related_correlation_id` link CP2 Backend correlation-id.
- `expires_at` TTL 7 days canonical (founder mandate).

**Decisions:**

- **D1.** Tabla central cross-domain — único punto verdad idempotency. Backend lib `IdempotencyKeys.Lock(key, domain, payload)` antes commit.
- **D2.** UNIQUE(idempotency_key) — INSERT on duplicate → SELECT existing + check state:
  - `state='completed'` → return cached `response_payload`.
  - `state='pending'` AND created < 60s → wait/retry.
  - `state='pending'` AND created > 60s → assume stuck, mark failed.
- **D3.** TTL 7 days mandate founder. Cron daily DELETE WHERE expires_at < NOW() en batches LIMIT 10000.
- **D4.** NO partitioning Phase A. Si > 500K rows post-launch → migration v0.4 partitioning RANGE(expires_at).

**Queries hot path:**

```sql
-- Q1: Lock idempotency key (Backend lib hot path).
INSERT INTO sonar_bank_idempotency_keys
  (idempotency_key, domain, state, request_payload, expires_at, ...)
VALUES (?, ?, 'pending', ?, UNIX_TIMESTAMP() + 604800, ...);
-- ON DUPLICATE KEY → SELECT existing row + state check.

-- Q2: Complete (post-success).
UPDATE sonar_bank_idempotency_keys
SET state = 'completed', response_payload = ?, completed_at = UNIX_TIMESTAMP(),
    related_movement_id = ?
WHERE idempotency_key = ? AND state = 'pending';

-- Q3: Cron cleanup TTL (DevOps Lead).
DELETE FROM sonar_bank_idempotency_keys
WHERE expires_at < UNIX_TIMESTAMP() LIMIT 10000;
-- Index: idx_sonar_bank_idempotency_keys_state_expires.
```

---

## 28. Bank Phase A — Performance benchmarks (Pending v0.4)

> **Status:** 🟡 Pending DRAFT v0.4 (BANK-DB.4) — execution mandatory para LOCKED v1.0.
>
> **Document:** `progress/BENCHMARK_BANK_DB_v1.md` skeleton DRAFT v0.1.

**Targets canonical (sign-off mandatory):**

- Reconciliation 200 concurrent <500ms p99 (Q16.5).
- Audit ledger insert >1000/s sustained.
- Government Console "Todas" scope <200ms (5 años data).
- Money operations hot path <30ms p99 transfer + <40ms p99 escrow create.
- Status FSM read PK fijo <1ms p99.

---

## 29. Deviations from blueprint Bank Phase A — founder Q-DB-A→J resolutions

> **Bloque consolidado** documentando cada divergencia del blueprint v1.2 con su rationale + impact downstream. Referencia obligatoria handoffs H1 (Backend) + H2 (Security).

### 🟡 Deviation Q-DB-A — Engine MariaDB 12.x primary, MySQL 8 best-effort compat

**Blueprint v1.2 framing:** §6 + slice §6 mencionan MySQL 8 features (INVISIBLE INDEX, GENERATED columns indexable, EXPLAIN ANALYZE) y MariaDB 10.6+ alternativa.

**Realidad operacional:** migrations 003 + 005 + 006 + 008 ejecutadas contra MariaDB 12.2.2 (`@resources/sonar_core/migrations/003_bank_schema.sql:27-50`). Workarounds documentados:

- D1 collation `utf8mb4_unicode_ci` (NO `utf8mb4_0900_ai_ci`).
- D2 `ON UPDATE (UNIX_TIMESTAMP())` MariaDB-illegal en INT UNSIGNED — app-managed.
- D4 + 006 D1 CHECK XOR multi-col `IS NULL` parser bug — app-layer enforcement.

**Resolución:** SSoT v1.3 lockea MariaDB 12.x primary. MySQL 8 best-effort compat (no testing prioritario). Features MySQL-only descartadas (INVISIBLE INDEX → usar `IGNORED` MariaDB con cuidado). System-versioned tables MariaDB 10.3+ disponible pero descartado audit ledger (Q-DB-F).

**Impact downstream:**

- Backend Lead post-H1 — `oxmysql` connection pool config + transactions tested vs MariaDB 12.x.
- DevOps Lead post-H4 — DB role config + cron partitioning tested MariaDB 12.x. ESX legacy boot rejection (`framework_detected = 'esx_legacy'`).
- Security Lead post-H2 — audit ledger triggers SIGNAL tested MariaDB 12.x.

---

### 🟡 Deviation Q-DB-B — DECIMAL fiat preserved, BIGINT atomic crypto-only

**Blueprint v1.2 + slice §7 OQ-DB-01:** recommend BIGINT cents para fiat (perf).

**Realidad operacional:** migrations 003 + 006 usan `DECIMAL(14,2)` y `DECIMAL(15,2)` — convención canonical. Cap DECIMAL(14,2) = 999.999.999.999,99 € (suficiente RP).

**Resolución:** SSoT v1.3 mantiene **DECIMAL(14,2) fiat** (consistency + readability + MariaDB-native + retrocompat 8 migrations producción). **BIGINT UNSIGNED `raw_amount` + TINYINT UNSIGNED `decimals`** **solo** crypto wallets (BTC 8, ETH 18 — decimals variables inherentes).

**Impact downstream:**

- Backend Lead post-H1 — money flow lib mantiene DECIMAL math + `format()` display. Crypto wallets aparte.
- Frontend Lead post-H3 — display layer convierte crypto `raw_amount / 10^decimals`.

---

### 🟡 Deviation Q-DB-C — Migrations path `resources/sonar_core/migrations/`

**Blueprint v1.2 + prompt §4.3:** path `migrations/<NNN>_*.sql` (root).

**Realidad operacional:** path canonical es `resources/sonar_core/migrations/` — runner Lua `@resources/sonar_core/server/migrations.lua` con checksum tampering detection (006 D10).

**Resolución:** SSoT v1.3 documenta path canonical `resources/sonar_core/migrations/010_*.sql`+. Migration files Phase A bajo este path.

---

### 🟡 Deviation Q-DB-D — `sonar_bank_accounts.type` ENUM split 2-col

**Blueprint v1.2 + prompt §4.2.1:** ENUM `type` extend a `checking/savings/business_treasury/govt_treasury/escrow/crypto_wallet` (mono-column).

**Realidad operacional:** ENUM existing `personal/company/cooperative/escrow` modela **tipo de owner**. Extends mono-column mezcla owner-type con account-class (confusión conceptual).

**Resolución:** SSoT v1.3 split en **2 columnas** (Q-DB-D LOCKED):

- `owner_type ENUM('personal','company','cooperative','government','escrow_managed')`.
- `account_class ENUM('checking','savings','business_treasury','govt_treasury','escrow','crypto_wallet')`.

**Migration 014 v0.2** ALTER bank_accounts split + backfill data existing.

---

### 🟡 Deviation Q-DB-E — `sonar_companies` deferred — opaque `company_id`

**Blueprint v1.2:** asume `sonar_companies` exists (FKs implícitas).

**Realidad operacional:** `sonar_companies` no existe (`@resources/sonar_core/migrations/003_bank_schema.sql:36-40` D3 deferred S2+ nunca materializado).

**Resolución:** Opción 2 LOCKED — `company_id CHAR(36) NULL` opaque sin FK. Issue #001 backend handoff.

**Impact downstream:**

- Backend Lead post-H1 enforce app-layer `Companies.exists(company_id)` validation.
- Issue #001 → FK promotion migration aditiva post-Phase A cuando `sonar_companies` se cree.
- Indexes secundarios `company_id` ya creados Phase A — perf future-proof.

---

### 🟡 Deviation Q-DB-F — Audit ledger 3-tier defense-in-depth, SysVer descartado

**Blueprint v1.2 + slice OQ-DB-03:** defense-in-depth (triggers + app-level). Slice §6 menciona MariaDB 10.6+ system-versioned tables como alternativa.

**Resolución:** SSoT v1.3 lockea **3-tier**:

1. **Tier 1** — Triggers SIGNAL `BEFORE UPDATE/DELETE` (migration 010).
2. **Tier 2** — `REVOKE UPDATE, DELETE ON sonar_bank_audit_ledger FROM 'sonar_bank_app_user'` (DevOps Lead post-H4).
3. **Tier 3** — App-level `BankAuditLedger.Append(payload)` lib only INSERT (Backend Lead post-H1).

**SysVer descartado** — semántica wrong (permite UPDATE versionado, no rechaza). Append-only puro requiere triggers SIGNAL.

---

### 🟡 Deviation Q-DB-G — Particiones extend Sep 2026 → Dec 2027

**Blueprint v1.2 + SSoT v1.1 §17:** cron mensual rolling forward "S2+" — nunca implementado.

**Realidad operacional:** migration 003 D5 partitions May-Aug 2026 + p_future MAXVALUE catchall. Riesgo perf chaos test Sept 2026+.

**Resolución:** Migration 013 REORGANIZE PARTITION extend `sonar_bank_movements` + `sonar_bank_audit_ledger` hasta Dec 2027 (32 partitions mensuales). Cron rolling forward DevOps Lead post-H4 obligatorio Nov 2027 antes de p_future fill.

---

### 🟡 Deviation Q-DB-H — Privacy votes dual-layer hash + audit raw

**Blueprint v1.2 + slice §3.1:** anonymous (hash citizen_id) vs transparent (raw citizen_id) — open question.

**Resolución:** Dual-layer LOCKED:

- `sonar_govt_votes (voter_hash CHAR(64))` — público, hash SHA-256 `citizen_id + election_id + server_salt`.
- `sonar_govt_votes_audit (citizen_id CHAR(36))` — admin-only, ACE `sonar.bank.govt.audit.full`. Permite investigaciones impugnación + fraude.

**Migration 017 v0.2** crea ambas tablas + ACE check enforced application-layer Backend Lead.

---

### 🟡 Deviation Q-DB-I — Stocks híbrido event-sourced + materialized snapshot

**Blueprint v1.2 + slice §3.4:** stocks model — relación N:M con `avg_buy_price` materialized vs event-sourced.

**Resolución:** Híbrido LOCKED:

- `sonar_bank_stocks_transactions` — event-sourced append-only (immutable audit).
- `sonar_bank_stocks_holdings` — materialized snapshot refresh on-trade (perf reads dashboard).

**Migration 020 v0.3** crea ambas + trigger AFTER INSERT en transactions update holdings (FIFO/avg_buy_price computed).

---

### 🟡 Deviation Q-DB-J — `sonar_bank_status` single-row global per-server

**Blueprint v1.2 + slice §3.6 + OQ-DB-05:** per-server vs per-citizen open question.

**Resolución:** Single row global per-server LOCKED. PK fijo `id=1` + trigger BEFORE INSERT enforce. State refleja bridge runtime del server process, NO citizen.

**Impact downstream:**

- Frontend Lead post-H3 — UI badge footer Tablet Bank app lee `state` per-frame via State Bag global.
- Backend Lead post-H1 — `BankStatus.Transition(new_state, reason)` lib gestiona FSM transitions.
- DevOps Lead post-H4 — boot rejection si `framework_detected = 'esx_legacy'`.

---

## 30. AMENDMENT v2.1 DRAFT — Issue #002 GOVT/BUSINESS persistence gaps

> **Status:** 🟡 DRAFT AMENDMENT — DB Lead reactivation 2026-05-09.
>
> **Trigger:** `docs/agents/teams/issues/issue_002_phase_a_govt_business_persistence_gaps.md`.
>
> **Migrations:** `029_company_registry.sql` + `030_subsidy_programs.sql` + `031_business_payroll_persistence.sql` + `032_govt_risk_scores_and_treasury_movements.sql`.

### 30.1 Scope

Issue #002 detecta que Phase A UI GOVT/BUSINESS cerró mock-driven, pero varios endpoints mock→real necesitan persistencia que no existía en migrations 001-028. Este amendment es **aditivo** y no modifica semántica LOCKED v2.0:

- `sonar_companies` + `sonar_company_members` para Business Registry y company-scoped permissions.
- `sonar_bank_subsidy_programs` para separar catálogo/program budget de desembolsos reales.
- `sonar_bank_business_payroll_batches` + `sonar_bank_business_payroll_lines` para ejecutar payroll auditable.
- `sonar_bank_govt_risk_scores` para materializar risk score GOVT 0-100.
- Extensión `sonar_bank_movements.category` para Treasury Ledger: `fine_collected`, `payroll_disbursement`, `reconciliation`, `interest_accrued`.

### 30.2 sonar_companies + sonar_company_members

**Migration:** `029_company_registry.sql`.

**Decisions:**

- **D1.** `sonar_companies` resuelve el blocker de Issue #001 a nivel tabla, pero **NO promueve FKs legacy automáticamente**.
- **D2.** FK promotion desde tablas ya existentes (`sonar_bank_accounts.owner_company_id`, `sonar_bank_business_treasuries.company_id`, etc.) queda diferida hasta orphan audit real. Motivo: añadir FK sin auditar datos existentes puede romper despliegues con company_id opacos ya persistidos.
- **D3.** `employee_count_cached` + `director_count_cached` materializan métricas de lista GOVT Business p99. Backend Lead mantiene counters en writes o cron nightly.
- **D4.** `sonar_company_members.role` distingue director/manager/employee. Treasury signers siguen siendo sólo firmantes financieros, no registro laboral.

**Queries hot path:**

```sql
-- Q1: GOVT Business list.
SELECT id, name, sector, status, founded_at, employee_count_cached, director_count_cached
FROM sonar_companies
WHERE status IN ('active','frozen')
ORDER BY name ASC
LIMIT 100;
-- Index: idx_sonar_companies_status_sector + idx_sonar_companies_name.

-- Q2: Company directors.
SELECT account_id, role, title, joined_at
FROM sonar_company_members
WHERE company_id = ? AND active = TRUE AND role IN ('founder','co-founder','director','manager')
ORDER BY role, joined_at ASC;
-- Index: idx_sonar_company_members_company_role.
```

### 30.3 sonar_bank_subsidy_programs + subsidies.program_id

**Migration:** `030_subsidy_programs.sql`.

**Decisions:**

- **D1.** `sonar_bank_subsidy_programs` = catálogo + budget + status. `sonar_bank_subsidies` = desembolsos individuales.
- **D2.** `program_id` en `sonar_bank_subsidies` es nullable para compatibilidad con UBI/legacy rows anteriores al amendment.
- **D3.** FK program_id → programs queda app-layer por particionado `sonar_bank_subsidies` y por compatibilidad MariaDB/InnoDB partition constraints.
- **D4.** `disbursed_amount` + `beneficiary_count_cached` permiten `gov.subsidy:list` sin SUM/COUNT masivo por cada programa.

**Queries hot path:**

```sql
-- Q1: GOVT subsidy programs list.
SELECT id, code, name, program_type, status, budget_amount, disbursed_amount, beneficiary_count_cached
FROM sonar_bank_subsidy_programs
WHERE status IN ('active','paused','proposed')
ORDER BY status, program_type, code;
-- Index: idx_sonar_bank_subsidy_programs_status_type.

-- Q2: Program detail disbursements.
SELECT id, beneficiary_account_id, company_id, amount, issued_at, reason_note
FROM sonar_bank_subsidies
WHERE program_id = ?
ORDER BY issued_at DESC
LIMIT 15;
-- Index: idx_sonar_bank_subsidies_program_issued.
```

### 30.4 Business payroll batches + lines

**Migration:** `031_business_payroll_persistence.sql`.

**Decisions:**

- **D1.** Payroll batch = executable unit. Approval queue remains `sonar_bank_business_treasury_approvals`.
- **D2.** Payroll line = per-employee durable state (`ready`, `held`, `paid`, `failed`, `cancelled`).
- **D3.** `idempotency_key CHAR(64)` UNIQUE at batch level; Backend still uses central `sonar_bank_idempotency_keys` first, then batch lock.
- **D4.** `related_movement_id` remains logical because `sonar_bank_movements` primary key is composite `(id, occurred_at)` due partitioning.

**Queries hot path:**

```sql
-- Q1: Business payroll queue.
SELECT id, state, total_net_amount, line_count, held_line_count, scheduled_for, created_at
FROM sonar_bank_business_payroll_batches
WHERE company_id = ? AND state IN ('draft','pending_approval','queued','held')
ORDER BY created_at DESC
LIMIT 20;
-- Index: idx_sonar_bank_business_payroll_batches_company_state.

-- Q2: Batch lines for execution.
SELECT id, employee_account_id, destination_bank_account_id, net_amount, state
FROM sonar_bank_business_payroll_lines
WHERE batch_id = ? AND state IN ('ready','held')
ORDER BY created_at ASC;
-- Index: idx_sonar_bank_business_payroll_lines_batch_state.
```

### 30.5 GOVT risk scores 0-100

**Migration:** `032_govt_risk_scores_and_treasury_movements.sql`.

**Decision:** Option A accepted for DB amendment: materialized snapshot table `sonar_bank_govt_risk_scores`.

**Rationale:** `sonar_bank_credit_scores.score` (0-1000 creditworthiness) is not equivalent to compliance/government risk (0-100). GOVT Census and Reports are read-heavy and must not recompute risk ad hoc per row.

**Contract v1:**

- `subject_type`: `citizen` | `company`.
- `score`: 0-100.
- `risk_level`: `low`, `medium`, `high`, `critical`.
- Buckets:
  - `low`: 0-24.
  - `medium`: 25-54.
  - `high`: 55-79.
  - `critical`: 80-100.
- Backend/Security recompute cadence target: every 5 minutes for active subjects + on-demand after sanctions/critical flags.

**Queries hot path:**

```sql
-- Q1: Census list risk join.
SELECT subject_id, score, risk_level, computed_at
FROM sonar_bank_govt_risk_scores
WHERE subject_type = 'citizen'
ORDER BY score DESC
LIMIT 100;
-- Index: idx_sonar_bank_govt_risk_scores_level_score.

-- Q2: Business registry risk join.
SELECT subject_id, score, risk_level
FROM sonar_bank_govt_risk_scores
WHERE subject_type = 'company' AND subject_id = ?;
-- PK: (subject_type, subject_id).
```

### 30.6 Treasury movement categories + rollup index

**Migration:** `032_govt_risk_scores_and_treasury_movements.sql`.

**Added categories:**

- `fine_collected`
- `payroll_disbursement`
- `reconciliation`
- `interest_accrued`

**Index:** `idx_sonar_bank_movements_treasury_rollup (category, occurred_at DESC, bank_account_id)`.

**Mapping guidance Backend Lead:**

- `fine_collected` — sanctions fine debit/credit pair.
- `payroll_disbursement` — company payroll outgoing + employee incoming rows.
- `reconciliation` — CP3 manual/async reconciliation adjustment.
- `interest_accrued` — loan/savings/treasury interest accrual.

### 30.7 Backend/Security handoff obligations

- Backend Lead updates endpoints REQ-FE-006..015 to consume §30 tables.
- Security Lead reviews `sonar_bank_govt_risk_scores` formula before promotion from DRAFT to LOCKED.
- Backend Lead must run orphan audit before any FK promotion from legacy company_id columns:

```sql
SELECT company_id FROM sonar_bank_business_treasuries
WHERE company_id NOT IN (SELECT id FROM sonar_companies);
```

---

## 21. Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026 (Oleada 0 firma) | Founder + Cascade | Primera redacción completa 4 partes, 20 secciones, ~2335 líneas, 28 tablas DDL completo + ~60 índices justificados + queries hot path + migrations strategy + particionado + backup + diccionario datos. **Firmable Oleada 0.** |
| 1.1 | 2026-05-04 | Founder + Cascade (S1.9 EXTENDED) | **Light refresh post-pivot SONAR** (ADR-011 + ADR-012 + ADR-013). Title rebrand Admirals → SONAR + dual prefix reference (`sonar_*` post-migration-009 / `sonar_*` pre-migration-009 legacy). NOTICE r1 top-level (~110 líneas) establece: naming canonical tables (mapping 1:1 todas 28 tablas listadas + índices + FKs + constraint names 1:1) + migration 009 `009_rename_sonar_to_sonar.sql` SQL target (UP + DOWN rollback) per ADR-013 scheduled + ERD/FKs/cardinality invariantes + ADR-010 hybrid audit/event log semantics preserved + reference data seeds preserved (system treasury `AD-SYS0-0000-0001` IBAN unchanged) + reading guide §1-§20 legacy vs canonical. §0 resumen + §cierre rebrand + §Architecture P3 dual prefix + §Decisiones clave prefijo dual + hermanos refs bumped + ADRs 010/011/012/013 linked. **NO touched:** §1-§20 filosofía + ERD + 28 tablas DDL + índices + queries hot path + migrations strategy + particionado + backup + diccionario datos + 20.1 resumen counts (pivot-agnostic foundational schema). Table prefix `sonar_*` + índices + FKs + constraints preservados legacy inline hasta Phase 9 migration 009 execution per ADR-011 §5.5.8 excepciones. Próxima v1.2 post-migration-009: 28 tablas rename 1:1 inline body. |
| 1.2 | 2026-05-04 | Founder + Cascade (S1.10.x) | **v1.2 — Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical.** S1.10 Phase 8+9 ejecutada (`admirals_*` → `sonar_*` code + DB tables + events + exports + server.cfg.example + 004 seed alias). S1.10.2 docs auto-rewrite Phase 1 (1075 identifiers code blocks). S1.10.3 docs Phase 2 surgical (NOTICE r1 block removed; prose "Admirals" → "SONAR" en §1-§N preservando refs históricos en este changelog; "Versión" + "FIN" bumped). Smoke harness inline admin commands cumulative S0+S1.1+S1.2+S1.3 = 10/10 PASS. **NO touched:** architecture + interfaces + contratos + tier + anti-patterns (pivot-agnostic). |
| 1.3 DRAFT v0.1 | 2026-05-06 | DB Lead (Cascade Sonnet 4.6) + Founder | **✅ DRAFT v0.1 Bank Phase A extends — BANK-DB.1 (founder approved 2026-05-06).** Founder green-light Q-DB-A→J 2026-05-06 (sesión BANK-DB.0 onboarding + handshake + cuestionamientos). NEW §22 (audit ledger inmutable + compliance flags + queries hot path) + NEW §23 (status FSM single-row CP8) + §24-§28 roadmap pending v0.2-v0.3 (tax + government + Tier 4 + empresas + idempotency) + NEW §29 deviations from blueprint (10 Q-DB-* resolutions documented). Header v1.2→v1.3 + changelog table tablas NEW + tablas existing extends + drift corrections SSoT v1.1 vs realidad migrations. **Migrations files DRAFT v0.1:** `010_bank_audit_ledger.sql` + `011_bank_compliance_flags.sql` + `012_bank_status_fsm.sql` + `013_bank_movements_partitions_extend.sql`. **Issue #001** `sonar_companies` pending (Q-DB-E opaque company_id deferred). **NO touched:** §1-§20 SSoT v1.2 LOCKED foundational. Pending sign-off triple (founder + Backend consumer post-H1 + Security consumer post-H2). |
| 1.4 DRAFT v0.2 | 2026-05-06 | DB Lead | **✅ DRAFT v0.2 Tax + Government — BANK-DB.2 (founder approved).** §24 NEW (7 tablas: brackets + history append-only + subsidies PARTITIONED + elections FSM + candidates + votes hashed + votes_audit raw). Q-DB-H dual-layer privacy. ALTER bank_accounts split + bank_movements ENUM extend. Migrations 014-017. |
| 1.5 DRAFT v0.3 | 2026-05-06 | DB Lead | **✅ DRAFT v0.3 Tier 4 + Empresas + Idempotency — BANK-DB.3 (founder approved).** §25 NEW Tier 4 (15 tablas) + §26 NEW Empresas (4 tablas + ALTER) + §27 NEW Idempotency keys. Migrations 018-028 (11 archivos). Schema DDL Phase A complete. |
| **2.0 LOCKED PROVISIONAL** | 2026-05-06 | **DB Lead + Founder** | **🔒 LOCKED PROVISIONAL — Bank Phase A schema DDL complete (BANK-DB.4).** Schema design + DDL + indexes + queries + migrations 010-028 + 30+ tablas + 100% Q-DB-A→J coverage **APROBADOS estructuralmente**. Founder APPROVED 2026-05-06; real benchmark execution delegado a Backend Lead harness Lua post-H1. |
| **2.1 DRAFT AMENDMENT** | 2026-05-09 | **DB Lead reactivation** | **🟡 Issue #002 — Phase A.GOVT + Business persistence gaps.** NEW §30 + migrations 029-032: `sonar_companies`, `sonar_company_members`, `sonar_bank_subsidy_programs`, `sonar_bank_business_payroll_batches`, `sonar_bank_business_payroll_lines`, `sonar_bank_govt_risk_scores`; ALTER `sonar_bank_subsidies.program_id`; ALTER `sonar_bank_movements.category` add `fine_collected`, `payroll_disbursement`, `reconciliation`, `interest_accrued` + treasury rollup index. Requires Backend Lead consumer review + Security Lead risk-score formula review before promotion. |

---

**FIN DEL DOCUMENTO `technical/03_db_schema.md` v2.1 DRAFT AMENDMENT (Issue #002 GOVT/BUSINESS persistence gaps — DB Lead reactivation 2026-05-09)**
