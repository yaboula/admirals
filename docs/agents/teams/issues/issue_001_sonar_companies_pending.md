# Issue #001 — `sonar_companies` table pending — opaque `company_id` deferred FK

> **Tipo:** Cross-team — DB Lead reporta + Backend Lead acción.
> **Status:** 🟡 Partially resolved — `sonar_companies` created by Issue #002 amendment; FK promotion still deferred pending orphan audit.
> **Severidad:** Media (no blocker DB Phase A pero blocker referential integrity post Phase A coding).
> **Reporter:** DB Lead (BANK-DB.0).
> **Owner pendiente:** Backend Lead (post-H1 onboarding).
> **Fecha apertura:** 2026-05-06.
> **Founder green-light decisión:** Q-DB-E aprobado — Opción 2 (column opaco + FK deferred + cero scope creep DB Lead).

---

## 1. Descripción del problema

El blueprint v1.2 §5.2 + slice DB §3.4 + prompt §4.2.4 referencian operaciones B2B sobre entidades empresa:

- `sonar_bank_business_treasuries` (sub-cuentas tesorería empresa multi-signer).
- `sonar_bank_escrows` con `contract_id VARCHAR(64)` (ya implementado migration 006).
- `sonar_bank_stocks_holdings` con `company_id` (acciones empresas player-driven Tier 4).
- `sonar_bank_movements.related_doc_id` futuras facturas B2B.

**La tabla canónica `sonar_companies` no existía en migrations 001-028.** Issue #002 la materializa en `resources/sonar_core/migrations/029_company_registry.sql`, pero la promoción de FKs desde columnas opacas existentes sigue diferida hasta orphan audit real.

`@resources/sonar_core/migrations/003_bank_schema.sql:36-40` documenta D3:

```
D3. FK sonar_bank_accounts.owner_company_id → sonar_companies(id) DEFERRED.
    La tabla sonar_companies no existe aún (se creará S2+).
    Cuando S2 cree sonar_companies, su migration añadirá el FK via
    ALTER TABLE ADD CONSTRAINT (non-breaking, aditivo).
```

El "S2+" mencionado nunca se materializó — la transition Admirals → Bank-only (BANK.0 cleanup) reorientó el proyecto y `sonar_companies` quedó pendiente sin owner asignado.

---

## 2. Decisión founder Q-DB-E (2026-05-06)

> "Aprobada la Opción 2. Usa un `company_id CHAR(36)` opaco sin FK enforced (deferred). Crea el issue `issues/issue_001_sonar_companies_pending.md` para el Backend Lead. Cero scope creep; el registro mercantil se hará en otro momento, el banco usará IDs opacos por ahora."

**Implicaciones:**

- DB Lead **NO** creó `sonar_companies` en Phase A inicial; Issue #002 habilita AMENDMENT v2.1 para crearla de forma aditiva por necesidad mock→real GOVT/BUSINESS.
- Todas las columnas que referenciarían `sonar_companies(id)` se declaran como `company_id CHAR(36) NULL` (o `NOT NULL` según semántica) **sin FOREIGN KEY constraint**.
- Validación application-layer obligatoria en Backend Lead — UUID v4 well-formed + existence check si Backend mantiene cache empresas en memoria.
- Migration aditiva futura post-Phase A añadirá FKs vía `ALTER TABLE ADD CONSTRAINT` cuando `sonar_companies` se cree.

---

## 3. Tablas DB Phase A afectadas

| Tabla | Columna | Tipo | Nullable | FK enforced Phase A | FK enforced post-issue resolved |
|---|---|---|---|---|---|
| `sonar_bank_accounts` (existing extends) | `owner_company_id` | `CHAR(36)` | `YES` | ❌ NO (D3 003_bank_schema) | ✅ `→ sonar_companies(id) ON DELETE RESTRICT` |
| `sonar_bank_business_treasuries` (NEW) | `company_id` | `CHAR(36)` | `NO` | ❌ NO | ✅ `→ sonar_companies(id) ON DELETE RESTRICT` |
| `sonar_bank_stocks_holdings` (NEW) | `company_id` | `CHAR(36)` | `NO` | ❌ NO | ✅ `→ sonar_companies(id) ON DELETE RESTRICT` |
| `sonar_bank_stocks_transactions` (NEW) | `company_id` | `CHAR(36)` | `NO` | ❌ NO | ✅ `→ sonar_companies(id) ON DELETE RESTRICT` |
| `sonar_bank_escrows` (existing) | `contract_id` | `VARCHAR(64)` | `YES` | ❌ N/A (`sonar_contracts` también pendiente) | (out-of-scope este issue) |

**Indexes preserved Phase A:**

- `KEY idx_sonar_bank_accounts_owner_company (owner_company_id)` — ya existe migration 003.
- Indexes equivalentes en cada NEW table per columna `company_id`.

Esto garantiza que cuando `sonar_companies` se cree y se añada el FK, los queries hot path (lookup por company) ya tienen el index correcto sin necesidad de rebuild.

---

## 4. Riesgos del workaround

### 4.1 Referential integrity gap

Sin FK, INSERT con `company_id` apuntando a UUID inexistente **no** se rechaza por la DB. Backend Lead debe enforce application-layer:

```lua
-- pseudo-code Backend Lead post-H1
local function validateCompanyExists(company_id)
  -- check cache RAM o query opcional
  if not Companies.exists(company_id) then
    error('INVALID_COMPANY_ID', { company_id = company_id })
  end
end
```

### 4.2 Orphan rows risk

Si una entidad company se elimina (cuando `sonar_companies` exista) sin `ON DELETE RESTRICT`, las rows hijas en `sonar_bank_*` quedarán huérfanas. Mitigation: cuando se promueva FK enforced, **previo `ALTER TABLE ADD CONSTRAINT`** ejecutar query auditor:

```sql
-- Detect orphan rows pre-FK promotion
SELECT id, company_id FROM sonar_bank_business_treasuries
WHERE company_id NOT IN (SELECT id FROM sonar_companies);
```

Si retorna rows → triage manual antes del ALTER.

### 4.3 Documentation drift

Schema doc `03_db_schema.md` v1.2 declara columnas `company_id` con comentario explícito:

```sql
company_id CHAR(36) NOT NULL COMMENT 'FK sonar_companies(id) DEFERRED — issue #001'
```

---

## 5. Acción requerida Backend Lead (post-H1)

Cuando `sonar_companies` se cree (sea Phase B o Phase C — fuera del scope DB Phase A):

1. ✅ **Crear migration aditiva** `migrations/029_company_registry.sql` con:
   - DDL `sonar_companies` table.
   - DDL `sonar_company_members` registry.
2. 🟡 **Crear migration aditiva futura** `migrations/0NN_promote_company_fks.sql` con:
   - Pre-flight orphan rows audit query.
   - `ALTER TABLE sonar_bank_accounts ADD CONSTRAINT fk_sonar_bank_accounts_owner_company FOREIGN KEY (owner_company_id) REFERENCES sonar_companies(id) ON DELETE RESTRICT ON UPDATE CASCADE;`
   - Equivalente para cada tabla §3 de este issue.
3. **Cerrar este issue** con resolution note + cita migration paths.
4. **Notify DB Lead** via SESSION_LOG entry para lessons-learned + close.

---

## 6. Acción requerida DB Lead (Phase A — DRAFT v0.1)

- ✅ Documentar columnas `company_id` con comentario `FK DEFERRED — issue #001` en cada tabla afectada.
- ✅ Crear indexes secundarios per `company_id` (perf future-proof).
- ✅ Bloque `### 🟡 Deviation from blueprint` en `03_db_schema.md` v1.2 referenciando este issue.
- ✅ NO crear `sonar_companies` (cero scope creep).

---

## 7. Cross-references

- `@resources/sonar_core/migrations/003_bank_schema.sql:36-40` (D3 deferred original).
- `@docs/agents/teams/prompts/01_database_integrity_lead.md` §4.2.4 (Empresas + escrow scope DB Phase A).
- `@docs/agents/teams/slices/slice_database.md` §3.4 (Q12 Tier 4 features).
- `@docs/design/proposals/03_bank_app_blueprint_v1.md` §5.2 (DB schema Bank-domain).

---

## 8. Sign-off

- **Founder yaboula:** ✅ green-light Q-DB-E (2026-05-06, conversation BANK-DB.0).
- **DB Lead:** ✅ accept + apply workaround DRAFT v0.1.
- **Backend Lead:** ☐ pending H1 onboarding — accept ownership resolution.

---

## 9. Estado

| Fecha | Acción | Por |
|---|---|---|
| 2026-05-06 | Issue creado post Q-DB-E founder green-light | DB Lead |
| 2026-05-09 | Issue #002 abre AMENDMENT v2.1 por gaps GOVT/BUSINESS | Backend Lead |
| 2026-05-09 | `sonar_companies` + `sonar_company_members` migration creada (`029_company_registry.sql`) | DB Lead |
| TBD | FK promotion migration ejecutada tras orphan audit | Backend Lead + DB Lead |
| TBD | Issue cerrado full | Backend Lead + DB Lead |

— **Issue #001 PARTIALLY RESOLVED** post Issue #002. Tabla `sonar_companies` existe vía AMENDMENT v2.1 DRAFT; FK promotion sigue OPEN hasta orphan audit + Backend/Security consumer review.
