---
prompt_id: 09_phase_5_manual_validation_lead
title: Phase 5 Manual Validation Lead — Adversarial Runtime Probe (QBCore live)
phase: BANK-BE.PHASE_5.5 — Manual Adversarial Validation
preceded_by: BANK-BE.PHASE_5.4 (automated GATE GO 2026-05-12 23:42 UTC)
emitted_by: PM Cascade
emitted_at: 2026-05-13 02:00 UTC+02
authority: Founder yaboula (doctrine ratified — see MEMORY[11ff0dd5] Phase GATE rule live runtime evidence mandatory)
status: ACTIVE — awaiting dev session spawn
---

# Mission — BANK-BE.PHASE_5.5 — Manual Adversarial Validation

> **Founder doctrine reaffirmed 2026-05-13 01:49 UTC+02:**
> *"el test real es muy importante, no me vale el automatico"*
>
> Phase 5.4 GATE GO fue emitido sobre evidence runtime + automated harness ST-024.1-10. **No es suficiente**. Founder yaboula exige una pasada **manual exhaustiva, adversarial, hands-on** de los 22 exports Phase 5 + auth gate + idempotency + audit shape + StateBag + edge cases sobre el servidor live QBCore antes de declarar Phase A complete.
>
> Este prompt activa al **Backend Lead (mismo dev BANK-BE.PHASE_5.3+5.4) en modo Manual Validation Co-pilot** colaborando con el founder en pruebas paralelas:
> - **Dev:** ejecuta cobertura sistemática de los 22 exports + audit trail + StateBag + auth tiers via console commands ad-hoc + SQL queries directos.
> - **Founder:** prueba adversarialmente todo lo posible + donde el sistema puede romperse (race conditions, malformed inputs, framework chaos, concurrent ops, framework restart mid-tx, disconnect mid-transfer, admin role spoofing, etc.).
>
> Objetivo: encontrar **cualquier discrepancia** entre el contract LOCKED v1.0.2 R2 y el comportamiento runtime real, o cualquier failure mode no contemplado, antes del tag `bank-phase-a` candidate.

## 1. Contexto runtime concreto

| Variable | Valor |
|---|---|
| **Workspace** | `d:\theBigProject` |
| **Branch** | `feature/bank-security-phase-a` HEAD `98b89e8` |
| **Servidor live** | `D:\FiveM_Server\Sonar\` (txAdmin) |
| **CFG activa** | `qbcore.cfg` (líneas 16-48 confirmadas: `sv_enforceGameBuild 3095`, license `cfxk_1I7wFnz9...`, `sv_maxclients 48`) |
| **Framework runtime** | **QBCore** (`setr sonar_bridge_bank=qbcore` + `sonar_bridge_identity=qbcore` + `sonar_bridge_bank_mode=standalone`) |
| **DB engine** | Laragon `D:\laragon` MySQL local |
| **DB conn QBCore** | `mysql://root@localhost/QBCore_FFAED3?charset=utf8mb4` |
| **DB conn SONAR** | host=`localhost` user=`root` password=`""` database=`sonar` |
| **Junctions runtime** | `D:\FiveM_Server\Sonar\resources\[sonar]\*` apuntan a `d:\theBigProject\resources\*` (edits live impact instant) |
| **DB tooling sugerido** | Laragon HeidiSQL o phpMyAdmin para queries directas SONAR DB durante probes |

## 2. Authority + boundary (ESTRICTO)

### ✅ Permitido

- Crear resource ad-hoc `resources/sonar_bank_qa_probe/` (server-only, dev-only, NO registrar en server.cfg permanente — solo durante session) con `RegisterCommand` wrappers que invocan los 22 exports para que founder + dev puedan probar via consola live `/qa_get_balance`, `/qa_add_money 100 reason`, etc.
- Queries SQL READ-ONLY directos contra `sonar.*` para verificar state post-mutation.
- Modificar `progress/PHASE_5_VALIDATION.md` agregando paragraph `## 5.5 Manual Adversarial Probe` con evidencia.
- Crear nuevo log `progress/PHASE_5_5_MANUAL_REPORT.md` con cobertura matrix + bug intake.
- Git commits atomic per finding o per cobertura batch.

### ❌ Prohibido sin escalation

- Tocar contracts SSoT LOCKED v1.0.2 R2 (`docs/technical/bank_phase_a/c_be_*` + `08_audit_hooks.md`). Si encontrás divergencia → BUG INTAKE protocol §7.
- Modificar exports surface (`server/api/public_api.lua`, `admin_api.lua`, `auth.lua`, `wrappers.lua`, `units.lua`). Si encontrás bug → fix sub-commit `fix(bank-api): BANK-BE.PHASE_5.5 <slug>` con justificación + regression note.
- Ejecutar DELETE/UPDATE/TRUNCATE manual contra DB sin documentar en report.
- Registrar `sonar_bank_qa_probe` en `server.cfg` permanente. Tras session manual, `ensure` debe removerse o resource deleted.

## 3. Inputs lectura obligatoria

1. **`docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` paragraph 10** — 22 exports surface canonical (signatures + opts schema + error codes + atomic guarantees + side effects + perf budgets).
2. **`docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md` paragraph 4 prime** — Server-to-Server Integration API model.
3. **`docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md` paragraph 2.2.1.A** — wrapper consumer pattern post-COMMIT.
4. **`docs/technical/08_audit_hooks.md` paragraph 1.1 AH4 + paragraph 1.2.A** — atomic same-TX mandate + 10-field shape canonical.
5. **`progress/PHASE_5_VALIDATION.md`** — automated GATE evidence (baseline para no regresar).
6. **`resources/sonar_bank_app/server/api/public_api.lua`** + **`admin_api.lua`** + **`auth.lua`** — implementation actual.
7. **`resources/sonar_bank_app/MIGRATION.md`** — operator guide (verificar sus claims contra runtime real).
8. **MEMORY[11ff0dd5] Phase GATE rule** — doctrina founder live evidence mandatory.

## 4. Pre-flight checklist (dev antes de pasar a founder)

- [ ] Pull `feature/bank-security-phase-a` en workspace + verificar HEAD `98b89e8` o posterior.
- [ ] Verificar runtime junctions `D:\FiveM_Server\Sonar\resources\[sonar]\*` apuntan a workspace (memoria filesystem confirmada).
- [ ] Boot server txAdmin → verificar console:
  - `[sonar_core] migration 036 sonar_bank_idem applied OK`
  - `[sonar_bank_app] boot smoke PASS 8/8`
  - `[sonar_bank_app] callbacks registered: 71`
  - `[sonar_bridges] active bank=qbcore identity=qbcore mode=standalone`
- [ ] Conectarse 1 player real al servidor + `/qb logout` + `/qb login` para ciclo de carga ID válido.
- [ ] HeidiSQL conectado a `sonar` DB → tabs abiertos sobre `sonar_bank_accounts`, `sonar_bank_movements`, `sonar_audit_log`, `sonar_bank_idem`.
- [ ] Verificar account creado para player on `playerJoining`/`PlayerLoaded` event:
  ```sql
  SELECT a.id, a.iban, sa.char_id, a.balance, a.is_frozen, a.closed_at
  FROM sonar_bank_accounts a
  INNER JOIN sonar_accounts sa ON sa.id = a.owner_account_id
  WHERE sa.char_id = '<QBCore_citizenid_actual>';
  ```
- [ ] Crear resource `sonar_bank_qa_probe/` con commands wrapper para los 22 exports (template §6).
- [ ] `restart sonar_bank_qa_probe` y `/qa_help` lista todos los commands disponibles.
- [ ] Ejecutar `/sonar_scan_legacy` → verificar 0 resources flagged.

## 5. Cobertura systematic dev (matrix obligatoria)

Para **cada uno de los 22 exports**, dev ejecuta el siguiente patrón 5-step y pega evidencia en `PHASE_5_5_MANUAL_REPORT.md`:

| Step | Acción | Evidencia capturada |
|---|---|---|
| **1 Snapshot pre** | SQL `SELECT balance, is_frozen FROM sonar_bank_accounts WHERE id=?` antes de invoke | balance_before_minor |
| **2 Invoke** | Command via `/qa_<export> <args>` o consola admin live | console output stdout (return tuple ok/err/data) |
| **3 Snapshot post** | SQL idem step 1 | balance_after_minor |
| **4 Audit row** | SQL `SELECT * FROM sonar_audit_log WHERE request_nonce=? ORDER BY id DESC LIMIT 5` | audit row JSON shape (10 fields canonical AH4) |
| **5 Movement row** | SQL `SELECT * FROM sonar_bank_movements WHERE related_doc_id=? OR request_nonce=?` | movement row coherent con balance delta |

### 5.1 Tier 1 happy paths (11 exports)

| # | Export | Test args sugeridos | Esperado |
|---|---|---|---|
| 1 | `GetBalance(src)` | `src` = player online | tuple `(true, nil, {balance_minor, savings_minor, iban})` |
| 2 | `GetBalanceByCitizen(cid)` | cid offline + cid online | idem; offline PASS si account existe |
| 3 | `CanAfford(src, 100000)` | amount=100000 (1000.00€) | `sufficient=true/false` según balance |
| 4 | `CanAffordByCitizen(cid, 100000)` | idem | idem |
| 5 | `AddMoney(src, 1250, 'qa_credit', {})` | +12.50€ | balance +1250 minor + audit `bank_credit` + StateBag publish observado |
| 6 | `AddMoneyByCitizen(cid, 500, 'qa_credit_offline', {})` | +5.00€ offline | idem; StateBag publish lazy on next playerJoining (verificar log line) |
| 7 | `RemoveMoney(src, 500, 'qa_debit', {})` | -5.00€ | balance -500 + audit `bank_debit` |
| 8 | `RemoveMoneyByCitizen(cid, 200, 'qa_debit_offline', {})` | -2.00€ | idem |
| 9 | `TransferBySource(src1, src2, 1000, 'qa_xfer', {})` | 2 players online | 2 movement rows (debit + credit) + 2 audit rows + 2 StateBag publishes |
| 10 | `TransferByIban(ib1, ib2, 1000, 'qa_xfer_iban', {})` | iban-based | idem |
| 11 | `TransferByCitizen(cid1, cid2, 1000, 'qa_xfer_cid', {})` | cid-based | idem |
| 12 | `GetApiVersion()` | no args | `{major=1, minor=0, patch=2, phase='Phase 5', api_lock='C-BE-02 v1.0.2 R2'}` |

### 5.2 Tier 2 admin happy paths (10 exports)

Pre-requisito: dev session debe tener resource `sonar_bank_qa_probe` agregado a allowlist `sonar:admin_allowlist` para que `Auth.RequireAdmin` PASS. Documentar el setup convar exacto.

| # | Export | Test args | Esperado |
|---|---|---|---|
| 13 | `AdminCredit(target_src, 5000, 'qa_admin_credit', {actor_src=admin_src})` | +50€ admin path | audit event_type `admin_credit` + invoker_resource = `sonar_bank_qa_probe` |
| 14 | `AdminDebit(target_src, 5000, 'qa_admin_debit', {actor_src})` | -50€ | audit `admin_debit` |
| 15 | `AdminSetBalance(target_src, 100000, 'qa_admin_set', {actor_src})` | balance=1000€ absoluto | audit `admin_set_balance` con delta_minor = (after - before) |
| 16 | `Freeze(target_src, 'qa_freeze', {actor_src})` | freeze account | `is_frozen=1` + audit `account_freeze` + previous_flag_snapshot JSON |
| 17 | `Unfreeze(target_src, 'qa_unfreeze', {actor_src})` | unfreeze | `is_frozen=0` + audit `account_unfreeze` |
| 18-22 | `*ByCitizen` siblings | offline cid path | idem above |

### 5.3 Cross-checks contract-vs-runtime

- [ ] **AH4 atomic mandate** → Forzar fallo SQL middle-tx (ej: target account `closed_at` set entre snapshot y invoke). Verificar rollback total: 0 audit rows + 0 movements + 0 balance change + tuple `(false, error_code)` consistente.
- [ ] **10-field canonical shape** → Para CADA event_type emitido, abrir audit row en HeidiSQL y verificar las 10 columnas pobladas (actor_account_id, target_account_id, event_type, delta_minor, previous_flag_snapshot, request_nonce, correlation_id, invoker_resource, reason, created_at). Falta de cualquier campo = BUG.
- [ ] **CP1-B StateBag publish** → Listener client-side dev (RegisterNetEvent + AddStateBagChangeHandler) verificar que `bank.balance.<cid>` se actualiza post-COMMIT con valor DECIMAL major (path (a) Phase A).
- [ ] **bank_overdraft event_type** → Forzar `RemoveMoney` con amount > balance. Verificar:
  - tuple `(false, 'INSUFFICIENT_FUNDS')`
  - audit row event_type=`bank_overdraft` con delta_minor signo negativo + previous_flag_snapshot.balance_before_minor
  - **NO** balance change + **NO** movement row.
- [ ] **boundary INTEGER↔DECIMAL** → Invoke `AddMoney(src, 12345)` y verificar `sonar_bank_accounts.balance` columna refleja `+123.45` exacto (no float drift). Probar valores boundary: 1, 99, 100, 12345, 999999, max int32.
- [ ] **PLAYER_NOT_LOADED** → Conectar player + fire export en ventana ANTES de QBCore PlayerLoaded event. Esperado tuple `(false, 'PLAYER_NOT_LOADED')`. Validar `Bridges.Identity.IsLoaded(src)` returns false en ese estado.

## 6. Cobertura adversarial founder (where can it break)

Founder ejecuta paralelo al dev. Cada finding documentado en `PHASE_5_5_MANUAL_REPORT.md` paragraph "Founder Adversarial Findings" con severity (BLOCKER / HIGH / MEDIUM / LOW / COSMETIC).

### 6.1 Input fuzzing

- [ ] `AddMoney(src, -100, 'neg_amount', {})` → esperado `INVALID_AMOUNT` no negative leak.
- [ ] `AddMoney(src, 0, 'zero', {})` → esperado `INVALID_AMOUNT` (allow_zero=false default).
- [ ] `AddMoney(src, 1.5, 'float', {})` → esperado `INVALID_AMOUNT` (Units.normalize_minor rechaza float).
- [ ] `AddMoney(src, 9999999999999, 'overflow', {})` → comportamiento bigint limit + DECIMAL column overflow.
- [ ] `AddMoney(src, '100', 'string', {})` → esperado normalize tolera string numeric o rechaza.
- [ ] `AddMoney(src, nil, 'nil', {})` → esperado `INVALID_AMOUNT` no crash.
- [ ] `Transfer*` con `from == to` (same iban / same src / same cid) → esperado `VALIDATION_FAIL` no self-transfer leak.
- [ ] `TransferByIban('XX00 INVALID', ib2, 100, ...)` → esperado `IBAN_INVALID` no crash.
- [ ] Reason field: 1000 chars / SQL injection patterns / unicode emoji / null → esperado sanitización 255 char limit + escape.
- [ ] `opts.idempotency_key = 'not-a-uuid'` → esperado `INVALID_UUID`.
- [ ] `opts.idempotency_key = nil` → auto-genera UUID v4 + audit row tiene UUID válido.
- [ ] `opts.correlation_id` distinto al idem_key → ambos persisten separados en audit.

### 6.2 Idempotency stress

- [ ] Invoke `AddMoney` con MISMO `idempotency_key` 2 veces → 2nd call returns `(true, 'IDEMPOTENCY_REPLAY', cached_result)` SIN duplicar audit/movement/balance.
- [ ] Invoke con MISMO key + payload DISTINTO (ej: cambiar amount) → esperado `IDEMPOTENCY_KEY_REUSED` con tuple `(false, ...)`.
- [ ] Invoke 5x concurrent (mismo key + mismo payload, fired en mismo frame) → esperado 1 success + 4 replay (no double-spend race). Usar 5 threads `Citizen.CreateThread` simultaneous para reproducir.
- [ ] TTL expire: query `sonar_bank_idem` row + manual UPDATE `expires_at = UNIX_TIMESTAMP() - 3600` → próxima invocación con mismo key debe behave como nuevo (post-TTL purge cron).

### 6.3 Auth.RequireAdmin 4-tier stress

- [ ] Invoke `AdminCredit` desde resource NO en `sonar:admin_allowlist` → esperado tuple `(false, 'AUTH_DENIED')` + audit row event_type denied.
- [ ] Invoke desde resource en allowlist pero `actor_src` no tiene ACE `sonar.bank.admin` → esperado denied.
- [ ] Invoke desde resource allowlist + ACE válido + role mismatch → esperado denied (cubre tier 3).
- [ ] Invoke desde server console (no resource invoker) → comportamiento documentado (esperado FAIL salvo si `actor_src=0` ACE bypass coded).
- [ ] Verificar `invoker_resource` audit field captura el caller real via `GetInvokingResource()` no spoofeable.
- [ ] Probar fake invocation desde NUI client side (esperado export server-only no expuesto).

### 6.4 Account state edge cases

- [ ] Account `is_frozen=1` → `AddMoney` esperado `ACCOUNT_FROZEN`. Mismo para Remove + Transfer (from frozen, to frozen).
- [ ] Account `closed_at IS NOT NULL` → esperado `ACCOUNT_CLOSED`.
- [ ] Citizen sin account creado → `*ByCitizen` esperado `ACCOUNT_NOT_FOUND` no crash.
- [ ] Citizen ID malformed (longitud < expected, special chars) → `INVALID_CITIZEN_ID`.
- [ ] IBAN con espacios extra / lowercase / país inválido → IBAN.Normalize cubre o rechaza coherente.

### 6.5 Concurrency + framework chaos

- [ ] 2 admin commands `AdminSetBalance` simultáneos sobre mismo account con valores distintos → esperado serialización SQL TX (último gana, primero rollback o ambos applied secuencial). Documentar comportamiento real.
- [ ] Player mid-transfer → disconnect (`/quit`) en milliseconds entre `BEGIN TX` y `COMMIT`. Verificar TX completa o rollback total (no balance partial mutation).
- [ ] Server `restart sonar_bank_app` durante transfer pending → verificar idem store recovery: idem row state=`locked` debe poder retomar o expire.
- [ ] `restart sonar_bridges` → `Bridges.Identity.IsLoaded` falla mientras restart → exports retornan `PLAYER_NOT_LOADED` o `INTERNAL_ERROR` graceful, no crash sonar_bank_app.
- [ ] DB Laragon STOP mysql service mid-tx → exports retornan `INTERNAL_ERROR` + sonar_bank_app no crash + tras restart Laragon, próxima invocación PASS.
- [ ] QBCore `/qb logout` mid-export → exports en flight terminan o abortan limpio.

### 6.6 Audit trail forensic

- [ ] Tras 30+ ops mixed (credits/debits/transfers/admin/freeze/unfreeze) → query `SELECT event_type, COUNT(*) FROM sonar_audit_log WHERE created_at > UNIX_TIMESTAMP() - 600 GROUP BY event_type` → conteos coinciden con ops ejecutadas.
- [ ] Verificar **chain integrity**: cada `bank_transfer` produce 2 rows (debit-side + credit-side) con MISMO `request_nonce` + `correlation_id`.
- [ ] Verificar `actor_account_id` poblado correctamente en ops src-based vs ByCitizen vs admin (distinguir actor real vs target).
- [ ] Buscar `previous_flag_snapshot` non-NULL en `account_freeze` / `account_unfreeze` events. Otros events pueden ser NULL (acceptable).
- [ ] Forzar audit row con SQL injection en `reason` field → verificar sanitize escape (no SQL leak en metadata JSON).

### 6.7 Migration + scan probe

- [ ] Manual rollback migration 036 + restart server → comportamiento detect missing table + boot fail graceful.
- [ ] Crear resource fake `legacy_test_resource` con call legacy `xPlayer.addMoney(100)` → `/sonar_scan_legacy` debe flagear ese resource. Validar detección.
- [ ] Operator MIGRATION.md walkthrough completo: leer en orden + ejecutar cada step + verificar claims (paths existen, comandos funcionan, troubleshooting tips reales).

## 7. Bug intake protocol (cuando algo falla)

Al detectar discrepancia o failure mode no contemplado:

1. **NO fix inmediato.** Documentar primero en `PHASE_5_5_MANUAL_REPORT.md` paragraph "Findings" con:
   - **ID**: F-PH5.5-001 ascending
   - **Severity**: BLOCKER / HIGH / MEDIUM / LOW / COSMETIC
   - **Reproducer**: pasos exactos + console output + SQL state pre/post
   - **Expected vs Actual**: contract reference (paragraph + line)
   - **Suggested fix area**: file + function (sin patch aún)
2. Si **BLOCKER** → escalation founder INMEDIATA + STOP testing hasta resolución.
3. Si **HIGH/MEDIUM** → continuar testing pero crear issue tracking + fix plan posterior batch.
4. Si **LOW/COSMETIC** → registrar y continuar.
5. Founder + dev consensúan fix scope. Backend Lead ejecuta sub-commit `fix(bank-api): BANK-BE.PHASE_5.5 <slug>` con regression note linking finding ID.
6. Tras fix, **re-test full export afectado** + re-grep residue + re-run `/sonar_scan_legacy`.

## 8. Evidence gathering format

`progress/PHASE_5_5_MANUAL_REPORT.md` template:

```markdown
# Phase 5.5 Manual Adversarial Validation Report

## Session metadata
- Date: YYYY-MM-DD HH:MM UTC
- Server: D:\FiveM_Server\Sonar (QBCore)
- Branch HEAD: <commit>
- Dev: <handle> | Founder: yaboula
- Duration: Xh Ym

## Coverage matrix dev (5.1 + 5.2)
| Export | Status | Audit OK | StateBag OK | Movement OK | Balance OK | Notes |
|---|---|---|---|---|---|---|
| GetBalance | ✅ | n/a | n/a | n/a | ✅ | ... |
| AddMoney | ✅ | ✅ | ✅ | ✅ | ✅ | console output below |
| ... 22 rows ... |

## Cross-checks (5.3)
- AH4 atomic: ✅ / ❌
- 10-field shape: ✅ / ❌
- CP1-B StateBag: ✅ / ❌
- bank_overdraft: ✅ / ❌
- INTEGER↔DECIMAL boundary: ✅ / ❌
- PLAYER_NOT_LOADED: ✅ / ❌

## Founder adversarial findings (6.1-6.7)
- F-PH5.5-001 [SEVERITY] <title> — <reproducer> — <expected vs actual>
- ...

## Bugs filed + status
| ID | Severity | Status | Fix commit | Re-test |
|---|---|---|---|---|
| F-PH5.5-001 | HIGH | RESOLVED | abc1234 | ✅ |

## Sign-off
- Backend Lead: ✅ self-attested coverage 22/22 + cross-checks PASS post-fix
- Founder yaboula: 🟢 GO MANUAL (or 🔴 BLOCKED reason)
- PM Cascade: ✅ promote ceremony close (post founder GO)
```

## 9. Activation checklist (founder spawn dev session)

```
Spawn Backend Lead BANK-BE.PHASE_5.5 with this prompt context:

Branch: feature/bank-security-phase-a HEAD 98b89e8 (pull antes start)
Server runtime: D:\FiveM_Server\Sonar (QBCore active)
DB: D:\laragon → mysql://root@localhost (sonar DB + QBCore_FFAED3 reference)
Bridge: qbcore + qbcore + standalone

Pre-flight (paragraph 4):
- Pull + verificar HEAD
- Boot server + verificar console boot smoke + callbacks 71 + bridges qbcore active
- HeidiSQL connect sonar DB
- Crear sonar_bank_qa_probe ad-hoc resource con 22 commands wrapper (template inline en prompt)
- Setup convar sonar:admin_allowlist incluyendo sonar_bank_qa_probe
- /sonar_scan_legacy → 0 flagged baseline

Cobertura systematic (paragraph 5):
- Tier 1 happy paths 12 exports (5.1)
- Tier 2 admin happy paths 10 exports (5.2)
- Cross-checks contract-vs-runtime 6 items (5.3)

Founder paralelo adversarial (paragraph 6):
- Input fuzzing (6.1)
- Idempotency stress (6.2)
- Auth tier stress (6.3)
- Account state edges (6.4)
- Concurrency + framework chaos (6.5)
- Audit forensic (6.6)
- Migration + scan probe (6.7)

Bug intake (paragraph 7) + evidence format (paragraph 8).

GATE 5.5 → H5 criteria:
- 22/22 exports cobertura PASS dev
- 0 BLOCKER findings open founder
- HIGH/MEDIUM findings RESOLVED + re-test PASS
- LOW/COSMETIC documented + accepted (or deferred Phase B)
- progress/PHASE_5_5_MANUAL_REPORT.md publicado
- Founder 🟢 GO MANUAL formal

ETA estimada: 3-5h sesión continua (puede partirse en 2 sub-sessions si fatiga).

GO.
```

## 10. Boundary recordatorio final

- **Contracts LOCKED v1.0.2 R2 NO TOUCH** salvo descubrimiento divergencia → escalation founder amendment Round 3.
- **Test resource `sonar_bank_qa_probe` ES TEMPORAL** → tras Phase 5.5 close, eliminar o mover a `dev_tools/` con README warning "DO NOT USE PROD".
- **DB tooling read-only por defecto** → cualquier UPDATE/DELETE manual founder/dev debe documentarse en report como "manual state injection for test X".
- **Founder trumps dev en cualquier disputa** sobre severity o pass/fail.

---

**PM Cascade emitió este prompt 2026-05-13 02:00 UTC+02 bajo doctrina founder ratificada.**
**Siguiente sesión: BANK-BE.PHASE_5.5 — awaiting founder spawn.**
