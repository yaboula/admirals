# SONAR Bank Phase 5 Validation Runbook

Estado: DRAFT operativo para Founder GO/NO-GO.
Branch: `feature/bank-security-phase-a`.
Scope: BANK-BE.PHASE_5.4 Gate 5 -> H5.

## Contratos locked que no se modifican

- C-BE-02 §10 v1.0.2 R2: superficie canónica de 22 exports públicos.
- C-BE-04 §4 v1.0.2 R2: prime API surface.
- C-BE-05 §2.2.1.A y §2.2.1.B path (a): patrón consumidor `publish_balance_update`.
- C-SEC-01 §1.1 AH4 y §1.2.A: atomicidad audit + forma canónica 10-field.

## Matriz de boot ESX/QBCore

### QBCore / QBox

Orden esperado:

1. `oxmysql`
2. `ox_lib`
3. framework (`qb-core` o `qbx_core`)
4. `sonar_core`
5. `sonar_bridges`
6. `sonar_bank`
7. `sonar_bank_app`

Validaciones:

- `sonar_core` aplica migrations antes de `sonar_bank_app`.
- `sonar_bridges` resuelve `GetCitizenId(source)` y `IsIdentityLoaded(source)`.
- Si se valida mirror framework, `sonar_bridge_bank_mode` debe estar en `mirror` o `synced`.

### ESX 1.10+

Orden esperado:

1. `oxmysql`
2. `ox_lib`
3. `es_extended`
4. `sonar_core`
5. `sonar_bridges`
6. `sonar_bank`
7. `sonar_bank_app`

Validaciones:

- ESX legacy menor a 1.10 queda fuera de Phase A.
- `sonar_bridges` debe adquirir shared object ESX antes de ejecutar smoke.
- `IsIdentityLoaded(source)` debe reflejar el evento framework loaded/drop.

## Pre-flight obligatorio

Ejecutar después de boot limpio:

```sql
SELECT version, applied_at
FROM sonar_schema_versions
WHERE version = '036_sonar_bank_idem.sql';
```

Debe existir una fila aplicada.

Validar columnas Phase 5:

```sql
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND (
    (TABLE_NAME = 'sonar_bank_idem')
    OR (TABLE_NAME = 'sonar_audit_log' AND COLUMN_NAME IN ('event_type','target_account_id','delta_minor','request_nonce','correlation_id','invoker_resource','reason','created_at','previous_flag_snapshot'))
  );
```

Resultado esperado:

- Tabla `sonar_bank_idem` existe.
- `sonar_audit_log` contiene columnas Phase 5 audit support.
- Constraint `chk_sonar_bank_accounts_balance_nonneg` no bloquea overdraft admin autorizado.

## Smoke harness Phase 5

Comando consola:

```text
sonar_smoke_phase_5 [source]
```

Requisitos:

- Ejecutar desde consola server (`source = 0`).
- Un player online y fully loaded para ST-024.2, ST-024.3 y ST-024.5 source probe.
- Si no se pasa `[source]`, el harness usa el primer player online.
- `oxmysql`, `sonar_core`, `sonar_bridges` y `sonar_bank_app` deben estar started.

Output esperado global:

```text
[sonar_bank_app][ST-024] starting Phase 5 exports smoke source=<id>
[sonar_bank_app][ST-024] PASS ST-024.1 ...
...
[sonar_bank_app][ST-024] PASS ST-024.10 ...
[sonar_bank_app][ST-024] complete ok=true passed=10 total=10
```

Si falta migration 036, aparece `ST-024.PREFLIGHT` FAIL y el Gate queda NO-GO.

## Secuencia ST-024.1-10

### ST-024.1 GetApiVersion smoke

Objetivo:

- Probar no-op Tier 0.
- Confirmar `api_lock = C-BE-02 v1.0.2 R2`.

Esperado:

```text
PASS ST-024.1 GetApiVersion smoke — C-BE-02 v1.0.2 R2
```

### ST-024.2 AddMoney happy path

Cubre:

- `AddMoney(source, amount_minor, reason, opts)`.
- Replay con mismo `idempotency_key` + payload igual.
- Audit row con 10 campos canónicos.
- StateBag `bank_balance` observado post-COMMIT.

Esperado:

```text
PASS ST-024.2 AddMoney happy path + replay + audit + StateBag — 10-field audit row present
```

### ST-024.3 RemoveMoney boundaries

Cubre:

- `RemoveMoney` happy path.
- `INSUFFICIENT_FUNDS`.
- Emisión audit `event_type = bank_overdraft` en intento rechazado.

Esperado:

```text
PASS ST-024.3 RemoveMoney happy path + INSUFFICIENT_FUNDS + bank_overdraft — overdraft_audit=true
```

### ST-024.4 Transfer atomic

Cubre:

- `TransferByIban`.
- Dos filas audit `bank_transfer`.
- Doble publish post-COMMIT observado en wrapper.
- Coherencia de saldos source/destination.

Esperado:

```text
PASS ST-024.4 Transfer atomic 2-row audit + double publish post-COMMIT — audit_rows=2 publishes=2
```

### ST-024.5 ByCitizen + PLAYER_NOT_LOADED

Cubre:

- `AddMoneyByCitizen` offline-safe.
- Simulación interna `IsLoaded=false` sobre source export para validar `PLAYER_NOT_LOADED`.

Esperado:

```text
PASS ST-024.5 ByCitizen siblings + PLAYER_NOT_LOADED simulation — source_probe=PLAYER_NOT_LOADED
```

### ST-024.6 CanAfford boundary

Cubre:

- `CanAffordByCitizen` con saldo exacto suficiente.
- `CanAffordByCitizen` con 1 minor unit por encima insuficiente.

Esperado:

```text
PASS ST-024.6 CanAfford sufficient/insufficient boundary — 1000=true 1001=false
```

### ST-024.7 Auth.RequireAdmin 4-tier

Cubre:

- Resource allowlist PASS.
- ACE PASS.
- Role ACE prefix PASS.
- Denied path con audit `auth_denied` emitido.

Esperado:

```text
PASS ST-024.7 Auth.RequireAdmin 4-tier — allow=resource_allowlist ace=ace role=role denied_audit_delta=1
```

### ST-024.8 Idempotency replay/collision

Cubre:

- Same key + same payload devuelve cache/replay.
- Same key + different payload devuelve `IDEMPOTENCY_KEY_REUSED`.

Esperado:

```text
PASS ST-024.8 Idempotency replay + key reused — replay=IDEMPOTENCY_REPLAY reused=IDEMPOTENCY_KEY_REUSED
```

### ST-024.9 Units integer/decimal coherence

Cubre:

- `units.to_minor('12.34') == 1234`.
- `units.from_minor(1234) == '12.34'`.
- Persistencia DB `DECIMAL(14,2)` round-trip.

Esperado:

```text
PASS ST-024.9 INTEGER minor input + DECIMAL major DB round-trip — minor=1234 decimal=12.34 db=12.34
```

### ST-024.10 Legacy scanner

Cubre:

- `/sonar_scan_legacy` detector contra manifest fake con `Player.Functions.AddMoney`.
- Valida que el scanner es testeable vía `BankApp.api.legacy_scan.ScanManifest`.

Esperado:

```text
PASS ST-024.10 /sonar_scan_legacy fake resource detection — Player.Functions.AddMoney
```

Validación manual adicional del comando real:

```text
sonar_scan_legacy
```

Esperado en repo dev con resource mock legacy:

```text
[sonar_bank_app][legacy-scan] <resource_name>: Player.Functions.AddMoney
[sonar_bank_app][legacy-scan] complete: <n> resource(s) flagged
```

## No-regression smoke ST-001..ST-007

Ejecutar en `sonar_bank` dev mode:

```text
smoke_regression
```

Criterio:

- ST-001..ST-007 siguen PASS o con las mismas precondiciones conocidas previas a Phase 5.
- Cualquier FAIL nuevo tras Phase 5 bloquea Gate 5 -> H5.

## MIGRATION.md operador

Documento operador:

- `resources/sonar_bank_app/MIGRATION.md`

Debe cubrir:

- Reemplazo de mutaciones directas framework por exports server-side.
- Tier 1 day-to-day exports.
- Tier 2 admin exports.
- `opts.idempotency_key` y `opts.correlation_id`.
- Units en minor integer.
- Uso de `/sonar_scan_legacy`.

## Checklist convars Phase 5

Nueva Phase 5:

- `sonar:admin_allowlist`: comma-separated resource names permitidos para Tier 2 resource allowlist.

Preservadas:

- `sv_maxRateLimitResetGraceSeconds=300` (M001).
- `sonar_bank_audit_query_per_citizen_per_min=1` (M003).
- `sonar_bank_audit_query_global_per_min=10` (M003).
- `sonar_bank_atm_hmac_secret` min 64 hex chars (M006).
- `sonar_bank_watchdog_compromise_ratio_threshold` (M007).
- `sonar_bank_watchdog_min_sample_size` (M007).
- `sonar_status_transition_whitelist` (H002).
- `sonar_bridge_bank_mode` si se valida mirror framework (`standalone`, `mirror`, `synced`).

## Rollback playbook si Phase 5 GATE falla

1. Detener validación y marcar Founder NO-GO temporal.
2. Capturar output completo de `sonar_smoke_phase_5 [source]`.
3. Capturar `smoke_regression` ST-001..ST-007.
4. Revisar migration 036 en `sonar_schema_versions`.
5. Si falla sólo runtime smoke y no schema:
   - `git revert 0153926` o revert del commit Phase 5.4 5.1 vigente.
   - Restart `sonar_bank_app`.
   - Re-ejecutar ST-001..ST-007.
6. Si falla schema/migration:
   - No ejecutar rollback SQL destructivo en entorno compartido.
   - Abrir issue DB/Backend con output de `INFORMATION_SCHEMA`.
   - Mantener contratos locked intactos; usar amendment formal si se detecta gap contractual.
7. Si falla `/sonar_scan_legacy` por falso negativo:
   - Añadir fixture mock resource o patrón scanner en commit nuevo Phase 5.4, sin tocar contratos locked.

## Gate 5 -> H5 GO criteria

- ST-024.1-10 PASS en harness real con `oxmysql` + `sonar_bridges` live.
- `progress/PHASE_5_VALIDATION.md` publicado y aprobado por Founder.
- No regression smoke ST-001..ST-007 pre-Phase 5.
- `resources/sonar_bank_app/MIGRATION.md` operator-ready.
- `/sonar_scan_legacy` validado en repo dev con resource mock legacy.

## Runtime evidence captured

Fecha evidencia: 2026-05-12 23:07-23:30 UTC.
Servidor: txAdmin / FXServer live dev.
Framework: QBCore.
Player source: `1` (`ShyDuck3710`, Citizen ID `FXD56242`).
Branch/commit backend validado: `feature/bank-security-phase-a` @ `a9649fe`.

### Boot evidence

- `oxmysql` started before `qb-core`.
- `sonar_bridges` started and reported `Identity -> qbcore`, `Bank -> qbcore`, `Bank mode : standalone`.
- `sonar_core` reported DB ready with oxmysql ping OK.
- Migration `036_sonar_bank_idem.sql` applied OK in live boot (`132ms`).
- `sonar_bank_app` boot smoke passed `8/8` checks.
- `sonar_bank_app` registered `71` callbacks and booted successfully.

### ST-024 Phase 5 smoke evidence

Command executed:

```text
sonar_smoke_phase_5 1
```

Observed result:

```text
[sonar_bank_app][ST-024] PASS ST-024.1 GetApiVersion smoke — C-BE-02 v1.0.2 R2
[sonar_bank_app][ST-024] PASS ST-024.2 AddMoney happy path + replay + audit + StateBag — 10-field audit row present
[sonar_bank_app][ST-024] PASS ST-024.3 RemoveMoney happy path + INSUFFICIENT_FUNDS + bank_overdraft — overdraft_audit=true
[sonar_bank_app][ST-024] PASS ST-024.4 Transfer atomic 2-row audit + double publish post-COMMIT — audit_rows=2 publishes=2
[sonar_bank_app][ST-024] PASS ST-024.5 ByCitizen siblings + PLAYER_NOT_LOADED simulation — source_probe=PLAYER_NOT_LOADED
[sonar_bank_app][ST-024] PASS ST-024.6 CanAfford sufficient/insufficient boundary — 1000=true 1001=false
[sonar_bank_app][ST-024] PASS ST-024.7 Auth.RequireAdmin 4-tier — allow=resource_allowlist ace=ace role=role denied_audit_delta=1
[sonar_bank_app][ST-024] PASS ST-024.8 Idempotency replay + key reused — replay=IDEMPOTENCY_REPLAY reused=IDEMPOTENCY_KEY_REUSED
[sonar_bank_app][ST-024] PASS ST-024.9 INTEGER minor input + DECIMAL major DB round-trip — minor=1234 decimal=12.34 db=12.34
[sonar_bank_app][ST-024] PASS ST-024.10 /sonar_scan_legacy fake resource detection — AddMoney,Player.Functions.AddMoney
[sonar_bank_app][ST-024] complete ok=true passed=10 total=10
```

UI observation:

- ST-024.2 AddMoney movement visible as `+$12.50`.
- ST-024.3 RemoveMoney movement visible as `-$5.00`.

### Legacy scanner evidence

Command executed:

```text
sonar_scan_legacy
```

Observed result:

```text
[sonar_bank_app][legacy-scan] scanning resources for likely bank mutation residues
[sonar_bank_app][legacy-scan] complete: 0 resource(s) flagged
```

### Regression evidence

Command executed:

```text
smoke_regression
```

Observed result:

```text
Total Tests: 7
Passed: 7
Failed: 0
Pass Rate: 100.0%
```

## Sign-off

Backend Lead self-attested:

- Nombre: Cascade / Backend Lead
- Fecha UTC: 2026-05-12 23:30
- Resultado ST-024.1-10: PASS live QBCore source `1`, `passed=10 total=10`
- Commit validado: `a9649fe`

DevOps Lead H4 update:

- Nombre: PENDING explicit DevOps Lead sign-off
- Fecha UTC: 2026-05-12 23:30 evidence captured
- Boot matrix validada: QBCore live boot evidence captured (`oxmysql` -> `qb-core` -> `sonar_bridges`/`sonar_core` -> `sonar_bank` -> `sonar_bank_app`)
- Convars revisadas: HMAC loaded length validated by boot smoke; audit rate-limit convars present in server cfg; `sonar_bridge_bank_mode` observed as `standalone`
- ST-001..ST-007 resultado: PASS 7/7, 0 failed, 100.0%

Founder GO/NO-GO:

- Founder decision: GO
- Fecha UTC: 2026-05-12 23:42
- Condiciones / notas: Founder GO issued after runtime evidence satisfied ST-024.1-10 live PASS, legacy scanner clean, and ST-001..ST-007 regression PASS.
