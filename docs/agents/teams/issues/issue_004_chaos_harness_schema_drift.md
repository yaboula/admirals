# Issue #004 — Chaos Harness Schema Drift (BANK-DO.2.1)

- **Status:** ✅ CLOSED (2026-05-11)
- **Severity:** MEDIUM (false-fail signal, no SUT bug)
- **Owner:** DevOps Lead (PM Cascade acting)
- **Branch:** `feature/bank-security-phase-a`
- **Related:** BANK-DO.2 Fase 1 Chaos Basic, migration 014, issue #003 (schema drift backend)

## Resumen ejecutivo

Durante BANK-DO.2.1 (refactor del chaos harness con fixtures reales), el primer
run produjo **8/8 FAIL** con `Unknown column 'type'` en `sonar_bank_accounts`.
La causa NO fue un bug del SUT, sino que el código de fixtures del harness
estaba escrito contra el schema canónico documentado en `migration 003_bank_schema.sql`
mientras que la DB de runtime tiene **migration 014_bank_accounts_owner_type_split.sql**
aplicada — que dropea `type ENUM` y añade `owner_type ENUM + account_class ENUM`.

Síntoma idéntico al de issue #003 pero al revés: en aquél, el código backend
usaba alias `bank_*` legacy contra una DB con tablas canónicas `sonar_bank_*`;
aquí, el código del harness usaba la columna `type` legacy contra una DB
post-migración-014.

## Root Cause

| Capa | Estado |
|---|---|
| Migración canónica aplicada | ✅ `003_bank_schema.sql` + `014_bank_accounts_owner_type_split.sql` |
| Code path producción (`Accounts.GetByIban`) | ✅ post-014, usa alias `owner_type AS type` para back-compat |
| Code path harness (`ChaosFixtures.Setup`) | ❌ pre-014, INSERT especificaba `type` column dropped |

El harness no atravesó el code path canónico de `Accounts.Create*` —
escribía SQL crudo directo. Por eso el desfase pasó desapercibido hasta
que se invocó.

## Cadena de detección

1. Run inicial chaos: `[FIXTURES] Row N failed (acc=true bank=false)` × 20.
2. oxmysql log: `Unknown column 'type' in 'INSERT INTO'` en cada INSERT
   a `sonar_bank_accounts`.
3. Tests subsiguientes leyeron `affected_rows = 0` para todo UPDATE → 0/N en
   todos los invariantes → 100% false-fail.
4. `grep -r "ALTER TABLE sonar_bank_accounts.*DROP COLUMN type"` localizó
   migration 014 como responsable del cambio de schema.

## Remediación aplicada

**Fix puntual (1 línea):**
- `@d:/theBigProject/resources/sonar_bank/server/smoke_chaos_chaos.lua` —
  fixture INSERT actualizado a `owner_type='personal', account_class='checking'`.
- Run #2: 8/8 PASS con invariantes legítimos.

**Endurecimiento adicional (BANK-DO.2.1.b):**

1. **`ChaosFixtures.ValidateSchema()` pre-Setup** — query a
   `INFORMATION_SCHEMA.COLUMNS` para verificar presencia de
   `owner_type`, `account_class`, `last_reconciled_at` antes de cualquier
   INSERT. Aborta harness si DB está pre-014, log explícito.

2. **`ChaosFixtures.Setup()` usa `SONAR.Bank.IBAN.Generate()`** en vez de
   IBANs sintéticos `AD-CHAS-*` que fallaban validación de checksum. Esto
   permite que el harness pueda invocar `SONAR.Bank.Transfer.Execute(...)`
   completo (validación de IBAN incluida).

3. **Teardown expandido** — limpia `sonar_bank_movements` (residuos del
   ledger producidos por ST-016/017) además de `sonar_bank_accounts` y
   `sonar_accounts`. Cleanup ahora por UUID prefix `cha05000-%` / `cha05001-%`
   (estable frente a cambios de formato IBAN).

4. **Categoría de error en stats** — `ChaosConcurrency.GetStats()` ahora
   incluye `errors` map por categoría (`INSUFFICIENT_FUNDS`, `RACE_DETECTED`,
   etc.) para que ST-017 distinga races reales de pre-flight rejections.

## Prevención

Política propuesta a partir de Phase B:

| Salvaguarda | Owner | Frequency |
|---|---|---|
| `ChaosFixtures.ValidateSchema()` corre en cada `RunChaosBasicTests()` | DevOps Lead | Cada run |
| Harness usa `Accounts.Create*` / `Transfer.Execute` (code path canónico) en vez de SQL crudo cuando posible | DevOps Lead | A partir de ST-016 |
| Cada migración con `ALTER TABLE` que cambie columnas debe documentar updates required en harness | DB Lead | Por migration |
| CI/CD check: schema diff vs `expected_schema.lua` en harness | DevOps Lead | Phase C (futuro) |

## Lecciones

1. **Test harnesses son código de producción de segunda clase** — fallan
   silenciosamente cuando el schema evoluciona y nadie lo nota hasta que
   se ejecutan. Validación pre-flight no es opcional.

2. **Invariantes salvan vidas** — sin las assertions post-test que añadimos
   en BANK-DO.2.1 (money conservation, ledger row count, contention proof),
   este bug habría producido los mismos PASS/FAIL ambiguos que el run pre-1.
   Las invariantes hicieron el error inmediatamente visible (`Σ0.00→0.00`).

3. **El fix de 1 línea es la punta del iceberg** — el bug real era de
   *governance* (no había validación de schema). El fix puntual estabiliza,
   pero `ValidateSchema()` previene futuras ocurrencias en otras migraciones.

## Sign-off

- ✅ **PM Cascade** — refactor implementado, run #2 8/8 PASS, run #3 (post-b) pendiente.
- 🟡 **Founder yaboula** — pendiente validación run #3 (ST-016/017 incluidos).
- 🟡 **DevOps Lead** — pendiente adopt issue learnings en runbook smoke matrix.
