# Issue #002 — Phase A.GOVT + Business persistence gaps for Frontend mock→real integration

> **Tipo:** Cross-team — Backend Lead reporta gap de persistencia y solicita reactivación DB Lead.
> **Status:** ✅ DB AMENDMENT EMITTED — Backend/Security consumer review pending.
> **Severidad:** Alta — bloquea go-live real de varios nodos UI Phase A.GOVT y Business Cockpit.
> **Reporter:** Backend Lead (BANK-BE reactivation post Frontend Phase A close).
> **Owner requerido:** DB Lead (C-DB-01/C-DB-02 amendment candidate) + Backend Lead consumer.
> **Fecha apertura:** 2026-05-09.
> **Fuente trigger:** `progress/FE_BACKEND_REQUESTS.md` v0.7 — REQ-FE-006..015.

---

## 1. Resumen ejecutivo

Frontend Lead cerró Phase A UI interactiva read-only bajo Mock-Driven Development. El backlog `progress/FE_BACKEND_REQUESTS.md` v0.7 contiene 15 items; `REQ-FE-001` y `REQ-FE-002` ya fueron cubiertos por Backend R2 (`sonar:bank:bootstrap:snapshot` + `sonar:bank:transfer:recentRecipients`).

Los requests nuevos críticos (`REQ-FE-006`..`REQ-FE-015`) requieren endpoints GOVT/BUSINESS reales. La auditoría Backend sobre `resources/sonar_core/migrations/001..028` confirma que parte de la persistencia existe, pero hay gaps estructurales que no deben resolverse con código Backend improvisado.

**Conclusión:** antes de implementar completamente endpoints mock→real, DB Lead debe emitir amendment/migrations aditivas para:

1. Crear registro mercantil real `sonar_companies` + membresías/directores mínimos.
2. Crear catálogo de programas de subsidio (`sonar_bank_subsidy_programs`) separado de desembolsos.
3. Extender soporte payroll batches/lines para Business Cockpit mutations.
4. Definir persistencia de risk scoring GOVT 0-100 o mapping formal desde credit score 0-1000.
5. Añadir categorías/índices necesarios para Treasury Ledger agregados si el mapeo sobre `sonar_bank_movements` no alcanza.

---

## 2. Evidencia de schema existente

### 2.1 Ya existe y Backend puede consumir

| Área | Tablas existentes | Fuente |
|---|---|---|
| Citizen registry base | `sonar_accounts` | `resources/sonar_core/migrations/002_foundation_tables.sql` |
| Bank accounts + movements | `sonar_bank_accounts`, `sonar_bank_movements` | `resources/sonar_core/migrations/003_bank_schema.sql` + `015_bank_movements_category_extend.sql` |
| Audit / compliance | `sonar_bank_audit_ledger`, `sonar_bank_compliance_flags` | migrations `010`, `011` |
| Tax brackets/history | `sonar_bank_tax_brackets`, `sonar_bank_tax_history` | migration `016` |
| Subsidy disbursement ledger | `sonar_bank_subsidies` | migration `016` |
| Credit score snapshots | `sonar_bank_credit_scores` | migration `018` |
| Business treasury + approvals | `sonar_bank_business_treasuries`, `sonar_bank_business_treasury_signers`, `sonar_bank_business_treasury_approvals` | migration `026` |
| Idempotency | `sonar_bank_idempotency_keys` | migration `028` |

### 2.2 Persistencia insuficiente / missing

| Gap | Impact FE request | Por qué no basta lo existente |
|---|---|---|
| `sonar_companies` no existe | REQ-FE-011, REQ-FE-015, parte de REQ-FE-010/013/014 | `company_id` es opaco por Issue #001; UI necesita name, sector, status, foundedAt, employeeCount, directors, labels. |
| Company membership/directors no existe | REQ-FE-011, REQ-FE-015 | `sonar_bank_business_treasury_signers` no equivale a registro laboral/directores; sólo modela firmantes de tesorería. |
| Subsidy programs no existen | REQ-FE-013 | `sonar_bank_subsidies` guarda desembolsos, no presupuesto/program catalog (`programId`, `code`, `name`, `type`, `status`, `budget`, `description`). |
| Payroll batches/lines no existen | REQ-FE-015 | `sonar_bank_business_treasury_approvals` puede contener JSON genérico, pero no batch ejecutable auditable por empleado/línea. |
| Risk score GOVT 0-100 no existe | REQ-FE-006, REQ-FE-007, REQ-FE-008, REQ-FE-011, REQ-FE-014 | `sonar_bank_credit_scores.score` es 0-1000 + rating crediticio; no es risk score compliance/govt 0-100. |
| Treasury movement types no están todos normalizados | REQ-FE-012, REQ-FE-014 | `sonar_bank_movements.category` cubre tax/subsidy/loan/etc, pero no todos los tipos UI (`fine_collected`, `payroll_disbursement`, `reconciliation`, `interest_accrued`) tienen semántica inequívoca o índices agregados. |

---

## 3. Requests Frontend afectados

| FE request | Backend endpoint(s) | DB status |
|---|---|---|
| REQ-FE-006 `gov.census.list` | `sonar:bank:gov:census:list` | Parcialmente cubierto con `sonar_accounts`, bank accounts, flags, movements. Risk/tax derivations requieren spec. |
| REQ-FE-007 `gov.census.detail` | `sonar:bank:gov:census:detail` | Parcialmente cubierto. Tax status/risk/activities derivables con limits. |
| REQ-FE-008 risk score contract | N/A spec + cron | Requiere DB/Security decision: nuevo table/cache o mapping formal desde credit score. |
| REQ-FE-009 sanction mutations | 4 callbacks | Puede operar sobre accounts/flags/movements existentes; fine category/status/audit mapping requiere confirmación. |
| REQ-FE-010 subsidy write | 2 callbacks | Citizen disbursement posible; business grant bloqueado por `sonar_companies`; program validation falta. |
| REQ-FE-011 business registry | 2 callbacks | **Bloqueado** por ausencia `sonar_companies` + members/directors metadata. |
| REQ-FE-012 treasury movements | 1 callback | Parcialmente cubierto; requiere categories/mapping/indexes agregación. |
| REQ-FE-013 subsidy read | 2 callbacks | **Bloqueado** por ausencia subsidy program catalog. |
| REQ-FE-014 reports analytics | 1 callback | Parcialmente cubierto; business sector + risk breakdown bloqueados por missing company/risk tables. |
| REQ-FE-015 business mutations | 3 callbacks | **Bloqueado parcial** por missing payroll batch/lines + company role registry. |

---

## 4. DB amendment solicitado

### 4.1 Migration NEW — `sonar_companies` + membership registry

Propuesta mínima aditiva:

```sql
CREATE TABLE sonar_companies (
  id CHAR(36) NOT NULL,
  name VARCHAR(96) NOT NULL,
  sector ENUM('farming','milling','bakery','retail','logistics','services','finance','other') NOT NULL DEFAULT 'other',
  status ENUM('active','frozen','liquidating','dissolved') NOT NULL DEFAULT 'active',
  founded_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  created_by_account_id CHAR(36) NULL,
  metadata JSON NULL,
  created_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  PRIMARY KEY (id),
  KEY idx_sonar_companies_status_sector (status, sector),
  KEY idx_sonar_companies_name (name)
);
```

```sql
CREATE TABLE sonar_company_members (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  account_id CHAR(36) NOT NULL,
  role ENUM('founder','co-founder','director','manager','employee') NOT NULL DEFAULT 'employee',
  active BOOLEAN NOT NULL DEFAULT TRUE,
  joined_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  left_at INT UNSIGNED NULL,
  department VARCHAR(64) NULL,
  salary_amount DECIMAL(14,2) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_company_members_company_account_active (company_id, account_id, active),
  KEY idx_sonar_company_members_account_active (account_id, active),
  KEY idx_sonar_company_members_company_role (company_id, role, active)
);
```

**FK promotion follow-up:** resolve Issue #001 by adding FKs from bank tables once orphan audit passes.

### 4.2 Migration NEW — subsidy program catalog

```sql
CREATE TABLE sonar_bank_subsidy_programs (
  id CHAR(36) NOT NULL,
  code VARCHAR(32) NOT NULL,
  name VARCHAR(96) NOT NULL,
  program_type ENUM('food','housing','employment','medical','education','emergency','agricultural') NOT NULL,
  status ENUM('active','paused','completed','proposed') NOT NULL DEFAULT 'proposed',
  budget_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  starts_at INT UNSIGNED NOT NULL,
  ends_at INT UNSIGNED NULL,
  description VARCHAR(255) NULL,
  created_by_account_id CHAR(36) NULL,
  created_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  PRIMARY KEY (id),
  UNIQUE KEY uq_sonar_bank_subsidy_programs_code (code),
  KEY idx_sonar_bank_subsidy_programs_status_type (status, program_type)
);
```

Add nullable `program_id CHAR(36) NULL` to `sonar_bank_subsidies` + index `(program_id, issued_at DESC)`.

### 4.3 Migration NEW — payroll execution persistence

```sql
CREATE TABLE sonar_bank_business_payroll_batches (
  id CHAR(36) NOT NULL,
  company_id CHAR(36) NOT NULL,
  treasury_id CHAR(36) NOT NULL,
  state ENUM('draft','pending_approval','queued','executed','held','failed','cancelled') NOT NULL DEFAULT 'draft',
  total_net_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  line_count INT UNSIGNED NOT NULL DEFAULT 0,
  requested_by_account_id CHAR(36) NOT NULL,
  executed_by_account_id CHAR(36) NULL,
  scheduled_for INT UNSIGNED NULL,
  executed_at INT UNSIGNED NULL,
  related_approval_id CHAR(36) NULL,
  related_audit_id BIGINT UNSIGNED NULL,
  created_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  PRIMARY KEY (id),
  KEY idx_sonar_bank_business_payroll_batches_company_state (company_id, state, created_at DESC),
  KEY idx_sonar_bank_business_payroll_batches_treasury_state (treasury_id, state)
);
```

```sql
CREATE TABLE sonar_bank_business_payroll_lines (
  id CHAR(36) NOT NULL,
  batch_id CHAR(36) NOT NULL,
  employee_account_id CHAR(36) NOT NULL,
  destination_bank_account_id CHAR(36) NOT NULL,
  net_amount DECIMAL(14,2) NOT NULL,
  state ENUM('ready','held','paid','failed') NOT NULL DEFAULT 'ready',
  failure_code VARCHAR(64) NULL,
  related_movement_id BIGINT UNSIGNED NULL,
  created_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  updated_at INT UNSIGNED NOT NULL DEFAULT (UNIX_TIMESTAMP()),
  PRIMARY KEY (id),
  KEY idx_sonar_bank_business_payroll_lines_batch_state (batch_id, state),
  KEY idx_sonar_bank_business_payroll_lines_employee (employee_account_id, created_at DESC)
);
```

### 4.4 Risk score materialization decision

DB/Security/Backend joint decision required:

- **Option A:** new `sonar_bank_govt_risk_scores` table with score 0-100 + level + components + recompute cadence.
- **Option B:** derive on read from compliance flags + movement velocity + tax history + credit score and cache in service LRU only.

Backend recommendation: **Option A** if `REQ-FE-006/007/014` are expected to support 5k+ citizens with p99 targets. Read-heavy GOVT dashboard should not recompute risk ad hoc per row.

---

## 5. Backend implementation gating

### 5.1 Can implement before DB amendment

- `gov.census.list/detail` minimal read-only using existing tables, with risk mapped conservatively from flags count + credit rating.
- `gov.sanction.freeze/lift/close_flag` using accounts + compliance_flags + audit.
- `gov.treasury.movements` over `sonar_bank_movements` with explicit category mapping.

### 5.2 Should wait for DB amendment

- `gov.business.list/detail` production-grade.
- `gov.subsidy.list/detail` production-grade program view.
- `gov.subsidy.grant_to_business` production-grade company validation.
- `business.payroll.execute` production-grade batch persistence.
- `business.approval.decide` if resulting operation is payroll/withdrawal requiring durable line-level state.

---

## 6. Acceptance criteria DB Lead

- [x] Migration(s) aditivas created under `resources/sonar_core/migrations/029+`.
- [x] `sonar_companies` + `sonar_company_members` created or explicit alternative table names documented.
- [x] Issue #001 FK promotion path either executed or explicitly deferred with updated blocker rationale.
- [x] `sonar_bank_subsidy_programs` created + `sonar_bank_subsidies.program_id` linked/indexed.
- [x] Payroll batch/line persistence created or explicit rejection with Backend alternative approved by founder.
- [x] Risk score storage decision documented (DB + Security + Backend joint).
- [x] Hot-path indexes for FE requests documented (`census list`, `business list`, `subsidy list`, `treasury movements`, `reports analytics`).
- [x] SESSION_LOG entry DB amendment handoff back to Backend Lead.

---

## 7. Cross-references

- `progress/FE_BACKEND_REQUESTS.md` v0.7 — REQ-FE-006..015.
- `resources/sonar_bank_app/web-src/src/govt/data/contracts.ts` — canonical UI contracts for GOVT mock layer.
- `resources/sonar_bank_app/web-src/src/data/contracts.ts` — Business cockpit contracts.
- `resources/sonar_core/migrations/002_foundation_tables.sql` — `sonar_accounts` base.
- `resources/sonar_core/migrations/003_bank_schema.sql` — `sonar_bank_accounts`, `sonar_bank_movements`, Issue #001 deferred FK note.
- `resources/sonar_core/migrations/011_bank_compliance_flags.sql` — compliance flags.
- `resources/sonar_core/migrations/016_tax_brackets_history_subsidies.sql` — tax/subsidy disbursements.
- `resources/sonar_core/migrations/018_bank_loans_credit_scores.sql` — credit score 0-1000, not govt risk 0-100.
- `resources/sonar_core/migrations/026_bank_business_treasuries.sql` — business treasury + approvals, insufficient for registry/payroll.
- `docs/agents/teams/issues/issue_001_sonar_companies_pending.md` — original company registry/FK blocker.

---

## 8. Estado

| Fecha | Acción | Por |
|---|---|---|
| 2026-05-09 | Issue creado tras auditoría Backend de FE_BACKEND_REQUESTS v0.7 + migrations 001-028 | Backend Lead |
| 2026-05-09 | DB Lead review + amendment plan accepted as additive v2.1 DRAFT | DB Lead |
| 2026-05-09 | Migrations 029-032 emitidas (`company_registry`, `subsidy_programs`, `business_payroll_persistence`, `govt_risk_scores_and_treasury_movements`) | DB Lead |
| 2026-05-09 | SSoT `03_db_schema.md` §30 v2.1 DRAFT AMENDMENT actualizado | DB Lead |
| TBD | Backend Lead consumer review + endpoint implementation REQ-FE-006..015 | Backend Lead |
| TBD | Security Lead review risk formula before LOCKED promotion | Security Lead |

— **Issue #002 DB AMENDMENT EMITTED.** Persistencia requerida para Business/Subsidy/Payroll/GOVT risk emitida como migrations 029-032 + SSoT §30. Pendiente Backend Lead consumer review + Security Lead risk-score review antes de promover v2.1 a LOCKED.
