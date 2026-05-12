# C-SEC-01 / 02 / 03 — Audit Hooks + ACE Matrix + Autoraise Rules v0.3 R2 LOCKED

> **Owner:** Security, Compliance & Audit Lead.
> **Consumers:** Backend Lead (amendment hooks + ACE + autoraise) + Frontend Lead (UI gating) + DevOps Lead (watchdog deploy).
> **Status:** � **C-SEC-01 v0.3 R2 LOCKED 2026-05-12** (BANK-BE.PHASE_5.1 Phase 2 ceremony — Round 2 amendment Phase 5 pivot Founder LOCK Q3 + Q5 + Q8 + cross-decision #2). C-SEC-02/03 unchanged from v0.2 RE-AUDIT.
> **Fecha:** 2026-05-12 (BANK-SEC.0 → BANK-SEC.1 → BANK-BE.PHASE_5.1.LOCK.R2 para C-SEC-01 only).

---

## 0. Resumen ejecutivo

Consolida 3 entregables Phase A: C-SEC-01 Audit Hooks, C-SEC-02 ACE Matrix, C-SEC-03 Autoraise Rules. Incluye §4 Audit Findings contra C-BE-01..05, §5 Exploit Prevention, §6 Watchdog Spec. Hallazgos HIGH+ bloquean aceptacion formal y disparan reactivacion Backend Lead.

---

## 1. C-SEC-01 — Audit Hooks Catalog

### 1.1 Principios
- **AH1** Todo hook append-only. Nunca UPDATE/DELETE `sonar_bank_audit_ledger`.
- **AH2** Hooks criticos persisten antes de NetEvent/StateBag emit.
- **AH3** Cada hook incluye `correlation_id`, `event_type` ENUM, `occurred_at`.
- **AH4 (Phase 5 R2 — NEW v0.3 R2)** **Atomic same-TX mandate.** El audit insert vive **dentro del mismo SQL transaction** que la balance mutation + movement append + idempotency upsert. Si cualquier paso falla, rollback total. NO `audit_complete` async path para superficie Tier 1/2 exports (cross-ref C-BE-02 §9 R1 LOCKED — mismo pattern para callbacks C001-C040). Post-COMMIT side effects (`publish_balance_update` NetEvent CP1-B + MirrorSync) son best-effort fire-and-forget — sus fallos NO rollbacken el audit. Cross-decision Founder #2 (`@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md:170`) ratifica.

### 1.2 Tabla hooks canonicos (13 — NEW v0.3 R2)

| Hook name | Trigger | Event type | Shape minimo | Severity si fail |
|---|---|---|---|---|
| `audit_hook_movement_recorded` | Post INSERT movement | `movement_recorded` | `{movement_id, citizen_id, amount, category, balance_after, correlation_id}` | HIGH |
| `audit_hook_fsm_transition` | Post `<FSM>.Transition` | `fsm_transition` | `{fsm_name, entity_id, state_from, state_to, triggered_by, correlation_id}` | HIGH |
| `audit_hook_auth_fail` | Auth tier rechaza | `auth_failed` | `{callback_id, source, citizen_id_attempted, reason, ace_perm?, timestamp}` | MEDIUM |
| `audit_hook_rate_limit_violation` | RateLimiter rechaza | `rate_limit_violation` | `{callback_id, source, citizen_id, tier, limit_config, timestamp}` | MEDIUM |
| `audit_hook_compliance_flag_raised` | Autoraise match | `compliance_flag_raised` | `{flag_id, citizen_id, flag_type, severity, evidence_json, correlation_id}` | HIGH |
| `audit_hook_compliance_flag_resolved` | Admin resuelve flag | `compliance_flag_resolved` | `{flag_id, resolver_id, resolution, resolution_notes, resolved_at, previous_flag_snapshot}` | HIGH |
| `audit_hook_idempotency_collision` | Key mismatch | `idempotency_collision` | `{key, domain, expected_hash, received_hash, source, correlation_id}` | HIGH |
| `audit_hook_reconciliation_delta` | Delta > threshold | `reconciliation_delta_above_threshold` | `{citizen_id, delta, sonar_balance, esx_balance, threshold, batch_id}` | HIGH |
| `audit_hook_watchdog_status_change` | Status transition | `status_transition` | `{state_from, state_to, reason, watchdog_metrics, triggered_by}` | CRITICAL |
| `audit_hook_pin_failure` | PIN fail | `pin_failure` | `{card_id_masked, citizen_id, fail_count, context, correlation_id}` | MEDIUM |
| `audit_hook_admin_override` | Admin force action | `admin_force_action` | `{admin_id, action_type, target_citizen_id, justification, previous_state_snapshot}` | HIGH |
| `audit_hook_bridge_echo_dropped` | Echo dropped | `bridge_echo_dropped` | `{correlation_id, source_framework, reason}` | MEDIUM |
| `audit_hook_exports_mutation` (NEW v0.3 R2) | Tier 1/2 export mutation commit | `bank_credit` / `bank_debit` / `bank_transfer` / `admin_credit` / `admin_debit` / `admin_set_balance` / `account_freeze` / `account_unfreeze` / `bank_overdraft` | 10-field canonical §1.2.A | MEDIUM (TX rollback si fail) |

### 1.2.A Tier 1/2 exports audit shape (NEW v0.3 R2 — Phase 5)

La nueva superficie Tier 1/2 exports server-to-server (C-BE-02 §10 v1.0.2 R2 — 22 públicos = 21 mutation/read + 1 GetApiVersion informational) emite **uno y solo un audit row por mutation commit**, dentro del mismo SQL TX. Shape canonical 10-field (alineado Q3 LOCKED + AH4 atomic mandate):

| Field | Type | Nullable | Semantic |
|---|---|---|---|
| `actor_account_id` | VARCHAR(64) | YES | Resolved del actor_src (Tier 2) o source (Tier 1). NULL si console (`actor_src == 0`). Para `*ByCitizen` variants Tier 1 cuando se invoca offline-scheduled (cron payroll, taxes), actor_account_id = `system` literal OR resolved del invoker_resource si el resource declara actor explícito. |
| `target_account_id` | VARCHAR(64) | NO | Target citizen/IBAN UUID afectado. MANDATORY. |
| `event_type` | ENUM | NO | Uno de: `bank_credit` (Tier 1 AddMoney/*ByCitizen), `bank_debit` (Tier 1 RemoveMoney/*ByCitizen), `bank_transfer` (Tier 1 TransferBy*), `admin_credit` (Tier 2 AdminCredit), `admin_debit` (Tier 2 AdminDebit), `admin_set_balance` (Tier 2 AdminSetBalance), `account_freeze` (Tier 2 Freeze), `account_unfreeze` (Tier 2 Unfreeze), `bank_overdraft` (Tier 2 AdminDebit/SetBalance + `opts.allow_overdraft=true`). |
| `delta_minor` | BIGINT | NO | Signed minor units. Positivo = credit, negativo = debit. Para `bank_transfer` se inserta 2 rows (1 debit en payer + 1 credit en payee) con mismo `correlation_id`. Para `account_freeze/unfreeze` delta = 0. **DB column type:** Founder Decision #2 LOCKED 2026-05-12 = diferir migration DECIMAL→BIGINT a Phase A+1 holistic (`@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`). Phase A wrapper escribe int signed; columna actual sin breaking. |
| `previous_flag_snapshot` | JSON | YES | `{frozen, closed, overdraft_authorized, ...}` ANTES del cambio. NULL para `bank_credit/bank_debit/bank_transfer` puros. MANDATORY para `account_freeze/account_unfreeze/admin_set_balance/bank_overdraft`. Idem H006 R1 fix para shape completa. |
| `request_nonce` | VARCHAR(36) | NO | `opts.idempotency_key` del caller OR `Bridges.UUID.v4()` generado si absent. Persistido también en `sonar_bank_idem.idem_key` (Phase 5 migration 036). |
| `correlation_id` | VARCHAR(36) | NO | `opts.correlation_id` del caller OR mismo valor que `request_nonce` si absent. Cross-resource trace ID. |
| `invoker_resource` | VARCHAR(64) | NO | `GetInvokingResource()` retornado dentro del wrapper export. `'console'` literal si Tier 2 invocado por console (`actor_src == 0`). |
| `reason` | VARCHAR(255) | NO | Free-text sanitized server-side (strip control chars + cap 255 + collapse whitespace). MANDATORY non-empty. |
| `created_at` | INT (epoch sec) OR TIMESTAMP | NO | Server timestamp commit moment. Aligned con LOCKED schema column type per `@docs/technical/03_db_schema.md` v2.1. |

**Atomic insert ordering dentro del wrapper Tier 1/2 SQL TX:**

```lua
-- sonar_bank_app/server/exports/public_api.lua (Phase 5 implementation)
MySQL.transaction.await({
  -- 1. Balance mutation
  { 'UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_id = ? AND account_class = ?',
    { units.from_minor(amount_minor_signed), citizen_id, 'main' } },
  -- 2. Movement append-only
  { 'INSERT INTO sonar_bank_movements (...) VALUES (...)', { ... } },
  -- 3. Audit row 10-field shape (this section)
  { 'INSERT INTO sonar_audit_log (actor_account_id, target_account_id, event_type, delta_minor, previous_flag_snapshot, request_nonce, correlation_id, invoker_resource, reason, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    { actor_cid, target_cid, event_type, amount_minor_signed, prev_flag_json or nil, request_nonce, correlation_id, invoker_resource, reason_sanitized, now_epoch } },
  -- 4. Idempotency upsert (si opts.idempotency_key)
  { 'INSERT IGNORE INTO sonar_bank_idem (idem_key, result_json, invoker_resource, created_at) VALUES (?, ?, ?, ?)',
    { opts.idempotency_key, json.encode(result), invoker_resource, now_epoch } },
})
-- TX COMMIT atomic. Post-commit side effects (publish_balance_update + MirrorSync) fire-and-forget.
```

**Si cualquier paso 1-4 falla → rollback total + return error code apropiado al caller.** Eventual consistency `publish_balance_update` y `MirrorSync` viven post-COMMIT — sus fallos NO afectan el audit (eventual reconcile path).

**Notas:**

- Para `bank_transfer` el wrapper inserta **2 audit rows** (1 debit payer + 1 credit payee) mismo `correlation_id` mismo `request_nonce` mismo `created_at`. Permite reconstruir P2P transfer auditing single-key.
- `previous_flag_snapshot` JSON shape canonical para freeze/unfreeze: `{"frozen": false, "frozen_reason": null, "frozen_at": null}` ANTES del cambio. Para `bank_overdraft`: `{"balance_before_minor": <int>, "overdraft_authorized_by": "<actor_cid|console>"}`.
- `bank_overdraft` event_type dispara AR-P05 admin override existing (§3 C-SEC-03) — autoraise infrastructure unchanged.

### 1.3 Shape base
```typescript
interface AuditHookBase {
  event_type: string;
  occurred_at: number;
  correlation_id: string;
  source_resource?: string; // whitelist: sonar_bank, sonar_bank_app, sonar_bridges, sonar_core
}
```

---

## 2. C-SEC-02 — ACE Permissions Matrix

### 2.1 12 permisos canonicos Phase A

| # | Permiso ACE | Descripcion | Variable | Default |
|---|---|---|---|---|
| P01 | `sonar.bank.player` | Cuenta personal | — | Auto-granted `source>0` |
| P02 | `sonar.bank.empresas.<id>.employee` | Acceso empresa basico | `<id>` company_id | Deny |
| P03 | `sonar.bank.empresas.<id>.manager` | Gestion dept | `<id>` company_id | Deny |
| P04 | `sonar.bank.empresas.<id>.initiate_approval` | Crear approval | `<id>` company_id | Deny |
| P05 | `sonar.bank.empresas.<id>.sign` | Firmar approval | `<id>` company_id | Deny |
| P06 | `sonar.bank.govt.escrow.admin` | Force escrow | — | Deny |
| P07 | `sonar.bank.govt.loan.admin` | Gestion prestamos | — | Deny |
| P08 | `sonar.bank.govt.tax.write` | Modificar brackets | — | Deny |
| P09 | `sonar.bank.govt.subsidy.write` | Grant subsidies | — | Deny |
| P10 | `sonar.bank.govt.compliance.admin` | Resolver flags | — | Deny |
| P11 | `sonar.bank.govt.audit.full` | Query full audit | — | Deny |
| P12 | `sonar.devops.bank.diagnostics` | Cron + watchdog | — | Deny |

### 2.2 Mapeo callbacks C001-C040 -> permisos

| Callback | Auth tier | Permiso(s) exacto |
|---|---|---|
| C001-C006, C009, C014, C018-C021, C023-C028, C030-C034, C036, C039 | AUTH-OWNER | P01 |
| C008, C010, C011 | AUTH-OWNER_OR_PARTICIPANT | P01 + match escrow |
| C012 | AUTH-ROLE | P06 |
| C015 | AUTH-ROLE | P08 |
| C016 | AUTH-ROLE | P09 |
| C020 | AUTH-ROLE | P07 |
| C026 | AUTH-ROLE / cron | P12 |
| C035 | AUTH-ROLE_OR_OWNER | P01(self) / P11(govt) / P02/P03(empresa) |
| C037-C038 | AUTH-ROLE | P10 |
| C040 | AUTH-OWNER | P04 |

> **AP5:** P01 es implicito en AUTH-OWNER/OWNER_OR_PARTICIPANT. Frontend Lead puede leer `IsPlayerAceAllowed(source, 'sonar.bank.player')` para gating UI.

---

## 3. C-SEC-03 — Autoraise Rules Canonical

### 3.1 5 patrones Phase A (per Q10)

| ID | Patron | Trigger | Severity | Auto-action | Suppression |
|---|---|---|---|---|---|
| AR-P01 | `large_transfer` | C001 amount > 10000 | medium | Ninguna | 1 por correlation_id, TTL 30d |
| AR-P02 | `velocity` | >5 transfers en 60min AND sum > 25000 | high | Ninguna Phase A | Sliding window, TTL 7d |
| AR-P03 | `pin_brute_force` | C034 fail_count >= 3 en 24h | high | FSM freeze | 1 por tarjeta, indefinido |
| AR-P04 | `reconciliation_delta_above_threshold` | CP5 delta > 1000 | critical | Queue admin review | 1 por citizen_id, indefinido |
| AR-P05 | `admin_force_action` | Admin override cuenta ajena | medium | Audit + flag | 1 por admin+target+dia, TTL 90d |

### 3.2 Shape flag DB
```typescript
interface ComplianceFlag {
  flag_id: number;
  citizen_id: string;
  flag_type: 'large_transfer' | 'velocity' | 'pin_brute_force' | 'reconciliation_delta_above_threshold' | 'admin_force_action' | 'suspicious_audit_emitter';
  severity: 'low' | 'medium' | 'high' | 'critical';
  evidence_json: object;
  status: 'active' | 'resolved' | 'escalated';
  raised_at: number;
  resolved_at?: number;
  resolver_id?: string;
  resolution_notes?: string;
  correlation_id: string;
}
```

---

## 4. Audit Findings

> **Accion requerida:** CRITICAL/HIGH -> AMEND (Backend Lead reactivation trigger #1/#2). MEDIUM/LOW -> ADVISORY.

### H001 — `source.citizen_id` nil bypass
- **Severidad:** HIGH
- **Contrato:** C-BE-02
- **Ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:82-88`
- **Descripcion:** Boilerplate usa `source.citizen_id == resource.owner_id`. `source` es number en FiveM, `source.citizen_id` = nil. `nil == nil` es true en Lua -> bypass auth.
- **Recomendacion:** Especificar `local citizen_id = Bridges.Player.GetCitizenId(source)` antes de comparar. Nunca `source.citizen_id`.
- **Accion:** AMEND C-BE-02 §2.3.

### H002 — `Bridges.BankStatus.Transition()` sin auth gate
- **Severidad:** HIGH
- **Contrato:** C-BE-04
- **Ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:168`
- **Descripcion:** Export publico permite forzar `compromised_load_order` o `framework_missing` desde cualquier resource. DoS global.
- **Recomendacion:** Requerir P12 (`sonar.devops.bank.diagnostics`) o source=0 (console) para mutar estado. Documentar en spec.
- **Accion:** AMEND C-BE-04 §5.1.

### H003 — Core Override sentinel `__sonar_patched` mutable
- **Severidad:** HIGH
- **Contrato:** C-BE-04
- **Ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:247-252`
- **Descripcion:** Atributo publico en tabla global QBCore. Resource cheat puede nil-izarlo y bypassar Core Override.
- **Recomendacion:** (a) Upvalue closure-local sentinel; (b) Watchdog checksum function-level; (c) `GlobalState` read-only sentinel con `replicated=false`.
- **Accion:** AMEND C-BE-04 §4.2/§4.3.

### H004 — Reconciliation pipeline SQL injection
- **Severidad:** HIGH
- **Contrato:** C-BE-04
- **Ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:459-462`
- **Descripcion:** `string.format` con `citizen_ids_str` en SQL batch UPDATE sin prepared statements. Cheat resource que reemplace ESX puede inyectar payload malicioso.
- **Recomendacion:** Refactorizar a prepared statement con placeholders posicionales. Nunca concatenar variables en SQL.
- **Accion:** AMEND C-BE-04 §7.1.

### H005 — FSM #1 escrow zero-amount release sin guard
- **Severidad:** HIGH
- **Contrato:** C-BE-03
- **Ref:** `@docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md:67`
- **Descripcion:** Guard `release_amount < escrow_amount` no incluye `> 0`. Release zero genera movimientos vacios + spam.
- **Recomendacion:** Añadir `release_amount > 0 AND release_amount < escrow_amount`.
- **Accion:** AMEND C-BE-03 §2.2.

### H006 — C038 resolveFlag audit double-entry incompleta
- **Severidad:** HIGH
- **Contrato:** C-BE-02
- **Ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:1463`
- **Descripcion:** Side effects no documentan shape completa de audit entry `compliance_flag_resolved`. Falta `flag_id`, `resolver_id`, `previous_flag_snapshot` obligatorios.
- **Recomendacion:** Extender §6.1 + §9.38 con shape completa C-SEC-01 `audit_hook_compliance_flag_resolved`.
- **Accion:** AMEND C-BE-02 §9.38 + §6.1.

### M001 — Rate-limit buckets RAM-only reset
- **Severidad:** MEDIUM
- **Contrato:** C-BE-02
- **Ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:211-212`
- **Descripcion:** In-memory only. Resource restart = reset buckets. Bypass parcial en escenario de reinicio.
- **Recomendacion:** Persistir buckets HIGH/CRITICAL en KVP/DB con TTL 1h. Convar `sv_maxRateLimitResetGraceSeconds` default 300s.
- **Accion:** ADVISORY C-BE-02 §4.3.

### M002 — UUID v4 entropia insuficiente
- **Severidad:** MEDIUM
- **Contrato:** C-BE-02 / C-BE-04
- **Ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:96`
- **Descripcion:** No se especifica PRNG. `math.random` compartido en FiveM puede ser predecible. Colision correlation-id = bypass CP2 mutex.
- **Recomendacion:** Especificar CSPRNG via `os.clock()` + `GetGameTimer()` + `GetPlayerPing(source)` hash combinado, o FFI crypto nativo.
- **Accion:** AMEND C-BE-02 §5.2 + C-BE-04 §3.3.

### M003 — C035 audit query recursive DDoS
- **Severidad:** MEDIUM
- **Contrato:** C-BE-02
- **Ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:1420`
- **Descripcion:** Cada query audit genera INSERT `audit_query_executed`. Llamadas masivas crean explosion logaritmica recursiva.
- **Recomendacion:** Rate-limit especial para audit queries recursivas: max 1/min per citizen_id, max 10/min global.
- **Accion:** AMEND C-BE-02 §9.35.7.

### M004 — StateBag `bank.balance.<cid>` expone balances globalmente
- **Severidad:** MEDIUM
- **Contrato:** C-BE-05
- **Ref:** `@docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md`
- **Descripcion:** GlobalState con key `bank.balance.<citizen_id>` permite a cualquier cliente leer balance de otro si conoce el citizen_id. Contradice privacidad financiera.
- **Recomendacion:** Considerar CP1-B para balances: emit via `TriggerLatentClientEvent` target especifico + ACE check en server. Solo publicar scalar agregado o deltas cifrados en StateBag.
- **Accion:** ADVISORY C-BE-05 §2.1. Requiere founder decision arquitectonica.

### M005 — FSM #8 idempotency `locked` orphan keys
- **Severidad:** MEDIUM
- **Contrato:** C-BE-03
- **Ref:** `@docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md:315`
- **Descripcion:** Solo `completed`/`failed` tienen purge TTL 7d. `locked` orphan (server crash entre Lock y Complete) bloquea key para siempre.
- **Recomendacion:** TTL 10min para `locked` keys + cron cleanup de orphans.
- **Accion:** AMEND C-BE-03 §9.2.

### M006 — ATM HMAC secret management indefinido
- **Severidad:** MEDIUM
- **Contrato:** C-BE-02
- **Ref:** `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md:1253`
- **Descripcion:** C031 usa `HMAC(action+amount+session_id+server_secret)` pero no se especifica storage, rotacion o provenance de `server_secret`. Hardcoded en resource file = leakable.
- **Recomendacion:** `server_secret` via convar `sonar_bank_atm_hmac_secret` (server.cfg only, nunca en repo). Rotacion manual on-demand. Minimum 32 bytes entropy.
- **Accion:** AMEND C-BE-02 §9.31.

### M007 — Watchdog metrica C no aborta en Lite Mode
- **Severidad:** MEDIUM
- **Contrato:** C-BE-04
- **Ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:599-611`
- **Descripcion:** Metrica C ratio < 0.3 solo loggea. No dispara transicion a `compromised_load_order`. Estado comprometido persiste sin accion.
- **Recomendacion:** Añadir threshold de accion: si `ratio < 0.1` AND `total > 50` en ventana 5min -> transicion `compromised_load_order`. Log-only solo para `0.1 <= ratio < 0.3`.
- **Accion:** AMEND C-BE-04 §8.3.

### M008 — MutexEcho delimiter collision
- **Severidad:** MEDIUM
- **Contrato:** C-BE-04
- **Ref:** `@docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md:383-391`
- **Descripcion:** `encode_correlation_id` usa pipe `|` separator. Si `reason_string` contiene `|sonar_correlation:`, regex match falla o extrae correlation incorrecto.
- **Recomendacion:** Escape `reason_string` reemplazando `|` con `\|` antes de concatenar, o usar prefixed length encoding (e.g. base64 JSON append).
- **Accion:** AMEND C-BE-04 §6.1.

### L001 — schema_version enforcement ausente
- **Severidad:** LOW
- **Contrato:** C-BE-01
- **Ref:** `@docs/technical/bank_phase_a/c_be_01_events_catalog_v1_3.md:295-299`
- **Descripcion:** OQ-CBE01-03 acepta `schema_version` mandatory pero no hay mecanismo de enforcement ni reject si payload omite campo.
- **Accion:** ADVISORY C-BE-01 §10.1.

### L002 — Event loss admin disconnect
- **Severidad:** LOW
- **Contrato:** C-BE-01
- **Ref:** `@docs/technical/bank_phase_a/c_be_01_events_catalog_v1_3.md:96-105`
- **Descripcion:** Admin events se determinan por `GetPlayers()` + ACE check en momento de fire. Admin desconectado = event perdido sin queue.
- **Accion:** ADVISORY. Phase B: queue persistente para admin events tier 1-2.

---

## 5. Exploit Prevention Checklist

Code review obligatorio pre-merge para Frontend + Backend Leads:

### Server-side (Lua)
- [ ] **No `source.citizen_id`**. Usar `Bridges.Player.GetCitizenId(source)` siempre.
- [ ] **No `TriggerClientEvent` manual para bank state**. StateBags global obligatorio CP1.
- [ ] **Prepared statements en TODO query oxmysql**. Zero concatenacion dinamica.
- [ ] **Rate-limit aplicado en todo callback mutacion**. RAM-only aceptable Phase A con advisory M001.
- [ ] **Idempotency key persistida DB** (C1). No cache-only.
- [ ] **Audit ledger append-only** (C2). Ningun UPDATE/DELETE.
- [ ] **ACE check en callbacks admin** (P06-P12). No fallback a role table sin licencia.
- [ ] **HMAC secret via convar**, nunca hardcoded en .lua file.
- [ ] **Server secret rotacion** documentada en runbook DevOps.

### Client-side (NUI / Lua)
- [ ] **StateBag consume read-only**. Client NUNCA escribe GlobalState bank keys.
- [ ] **NUI callbacks validan origin** + token server-side.
- [ ] **PIN input sanitizado** (4 digits numeric only, max length enforced client + server).
- [ ] **No client-side balance validation**. Server es SSoT siempre.

### FiveM hardening
- [ ] `sv_scriptHookAllowed 0` en server.cfg.
- [ ] `sv_pureLevel` minimo 1 para scripts client.
- [ ] Resource `sonar_bridges` name reservado en server.cfg (evita replacement attack).
- [ ] File integrity monitor en `resources/sonar_*` (DevOps H4).

---

## 6. Watchdog Core Override Compromise Detection Spec

### 6.1 Arquitectura dual-tier

| Tier | Intervalo | Check | Accion si fail |
|---|---|---|---|
| T1 | Boot T+30s | Sentinel attribute presente + checksum function OK | PASS -> `native_full`. FAIL -> `compromised_load_order` |
| T2 | Continuo T+5min | Sentinel + metrica C (correlation-id ratio) | FAIL -> `compromised_load_order`. Auto-reverify T+30min |
| T3 | Recovery | Manual `sonar_bank reset_status` console OR auto-reverify OK | `compromised_load_order` -> `native_full` si B+C pass |

### 6.2 Metrica C concreta (Lite Mode)

- **Emitted:** contador de correlation-ids generados por SONAR en ventana 5min (`sonar_bridges/lib/mutex_echo.lua`).
- **Received:** contador de correlation-ids extraidos de ESX events `addAccountMoney` reason string en misma ventana.
- **Ratio:** `received / emitted`.
- **Thresholds:**
  - `ratio >= 0.7` -> HEALTHY (esperado: algunos events externos sin correlation-id)
  - `0.1 <= ratio < 0.7` -> DEGRADED (log warn, metrica DevOps)
  - `ratio < 0.1` AND `emitted > 50` -> COMPROMISED (transicion a `compromised_load_order`)
  - `emitted < 50` -> INSUFFICIENT_SAMPLE (skip decision, log only)

### 6.3 Sentinel B (Core Override)

- Check 1: `QBCore.__sonar_patched == true` (actual) -> futuro: checksum SHA256 de la funcion patcheada almacenado en `GlobalState['sonar_bridges.patch_checksum']` (server-only, replicated=false).
- Check 2: Llamada probe a funcion patcheada (`AddMoney` dummy call con amount=0) retorna expected sentinel value (e.g. `{__sonar_probe=true}`) antes de llegar a framework.
- Check 3: Framework original function NO fue restaurada (comparar via `debug.getinfo` arity / name).

### 6.4 Transiciones permitidas

```
(native_full) --[T1 boot OK]--> native_full
(native_full) --[T2 sentinel fail]--> compromised_load_order
(native_full) --[T2 metric C < 0.1]--> compromised_load_order
(lite_mode_active) --[T2 metric C < 0.1]--> compromised_load_order
(compromised_load_order) --[T3 manual OR auto-reverify B+C pass]--> native_full
(compromised_load_order) --[T3 reverify fail persistido > 3 intentos]--> framework_missing (defensive abort)
```

### 6.5 Acciones en compromised_load_order
1. **Freeze:** Todos los callbacks Bank retornan `BANK_DISABLED` code.
2. **Alert:** Admin event `sonar:bank:status:transition` a todos P12 + console print.
3. **Audit:** Hook `audit_hook_watchdog_status_change` con CRITICAL severity + full metrics snapshot.
4. **Persist:** KVP `sonar_bank_disabled = 'watchdog_compromised_load_order_<timestamp>'`.
5. **Log:** `log_security_alert` con stack trace del momento de deteccion.

---

## 7. Cross-references + version

- C-BE-01..05 v1.0 LOCKED (audited).
- `03_db_schema.md` v2.0 PROVISIONAL (flags table + audit ledger).
- `06_fivem_standards.md` v1.2 (T1-T15 threat model).
- ADR-018 (Lite Mode hybrid 3-layer).

| Version | Fecha | Cambios |
|---|---|---|
| v0.1 DRAFT | 2026-05-06 | BANK-SEC.0. C-SEC-01/02/03 + 6 HIGH + 8 MEDIUM + 2 LOW findings + exploit checklist + watchdog spec. |
| v0.2 RE-AUDIT | 2026-05-06 | BANK-SEC.1. Re-audit Amendment Round 1 DRAFT v0.2 (Backend Lead BANK-BE.AMEND.1). 6 HIGH + 6 MEDIUM AMEND findings RESOLVED. M004 APPROVED architectural. M001 + L001 + L002 ratified. Veredicto PASS — Green-Light LOCK v1.0.1 R1. |
| **C-SEC-01 v0.3 R2 LOCKED** | 2026-05-12 (BANK-BE.PHASE_5.1.LOCK.R2) | Phase 5 ecosystem pivot amendment Round 2 reactive a Founder LOCK Q3 + Q5 + Q8 + cross-decision #2. **NEW §1.1 AH4** atomic same-TX mandate (audit insert dentro mismo SQL TX que balance + movement + idem; rollback total si paso 1-4 falla; NO audit_complete async para Tier 1/2 exports). **NEW §1.2 audit_hook_exports_mutation row** event_types: bank_credit/bank_debit/bank_transfer/admin_credit/admin_debit/admin_set_balance/account_freeze/account_unfreeze/`bank_overdraft` NEW Q5 LOCKED. **NEW §1.2.A 10-field shape canonical Tier 1/2** (actor_account_id + target_account_id + event_type + delta_minor + previous_flag_snapshot + request_nonce + correlation_id + invoker_resource + reason + created_at) + atomic insert ordering boilerplate + bank_transfer 2-row pattern + previous_flag_snapshot JSON shape canonical para freeze/unfreeze/overdraft. **DB column type delta_minor** Founder Decision #2 LOCKED — diferir migration DECIMAL→BIGINT a Phase A+1 holistic. Cross-cutting LOCK-time impacts: C-BE-04 v1.0.2 R2 + C-BE-02 v1.0.2 R2 + C-BE-05 v1.0.2 R2 atomic in-place patches. C-SEC-02/03 unchanged. Security consumer review absorbed by PM Cascade per Founder Decision #3 — BANK-SEC.2 deuda técnica re-audit pending Phase B con scope agregado (Phase 4 artifacts archived + Phase 5 implementation completa). Sign-off ratificado: founder yaboula APPROVED + Backend Lead self-attested DRAFT proposal + Security consumer PM Cascade absorbed + PM Cascade promote ceremony. **C-SEC-01 v0.3 R2 LOCKED 2026-05-12.** |

---

## 8. Re-audit findings closure — BANK-SEC.1

> **Session:** BANK-SEC.1 — Security Lead re-audit Backend Lead Amendment Round 1 (BANK-BE.AMEND.1).
> **Date:** 2026-05-06.
> **Source package:** `docs/agents/teams/amendments/be_phase_a_r1/` (4 AMEND files + README).
> **Veredicto:** ✅ **PASS** — Green-Light para LOCK v1.0.1 R1.

### 8.1 HIGH findings — RESOLVED PENDING-LOCK

| ID | Contrato | Patch ref | Veredicto | Notas Security Lead |
|---|---|---|---|---|
| **H001** | C-BE-02 | `AMEND-C-BE-02-r1-v0.2.md` §1 | ✅ RESOLVED | Auth helpers canonical lib (`sonar_bridges/lib/auth_helpers.lua`) con `resolve_citizen(source)` type-safe + nil-safe. Anti-pattern AP-AUTH-1 prohibido explícito. Notational disclaimer §2.3.2 elimina ambigüedad `source.citizen_id`. Boilperplate refactor a helper invocations. No residual bypass surface. |
| **H002** | C-BE-04 | `AMEND-C-BE-04-r1-v0.2.md` §1 | ✅ RESOLVED | Triple-path auth gate (`internal_call`+whitelist, `source=0` console, P12 ACE) con `opts.caller_source` mandatory. Unauthorized attempts loggean + audit hook. `GetInvokingResource()` whitelist contra convar `sonar_status_transition_whitelist`. DoS surface cerrada. |
| **H003** | C-BE-04 | `AMEND-C-BE-04-r1-v0.2.md` §2 | ✅ RESOLVED | Triple-defense robusta: (1) closure-local upvalue invisible externo, (2) `GlobalState` server-only `replicated=false`, (3) SHA256 checksum bytecode `string.dump`. Probe fn `_G._sonar_core_override_probe` monitoreada — su delección dispara `compromised_load_order`. `QBCore.__sonar_patched` eliminado por completo. Resistente a reasignación, wrapper injection y attribute nil-ization. |
| **H004** | C-BE-04 | `AMEND-C-BE-04-r1-v0.2.md` §3 | ✅ RESOLVED | Prepared statements posicionales `?` en lectura (`IN (?)`) y UPDATE (`CASE WHEN ? THEN ? END`). Zero concatenación de datos usuario en string SQL. oxmysql driver sanitiza bindings. Anti-pattern AP-SQL-1 documentado. Inyección cerrada. |
| **H005** | C-BE-03 | `AMEND-C-BE-03-r1-v0.2.md` §1 | ✅ RESOLVED | Guard `release_amount > 0` añadido a 3 transitions escrow + `escrow_amount > 0` / `remaining_balance > 0` defensive. Callback C010 valida positividad pre-FSM. Previene zero-value movement spam, audit noise y token bucket drainage attack. |
| **H006** | C-BE-02 | `AMEND-C-BE-02-r1-v0.2.md` §2 | ✅ RESOLVED | Audit shape completa: `flag_id`, `resolver_id`, `resolution`, `resolution_notes`, `resolved_at`, `previous_flag_snapshot` (JSON pre-update row), `source_resource`. Doble-entry forensics con `cross_ref_audit_id` admin_force_action cross-reference. Atomic transaction UPDATE+INSERT. |

### 8.2 MEDIUM AMEND findings — RESOLVED PENDING-LOCK

| ID | Contrato | Patch ref | Veredicto | Notas Security Lead |
|---|---|---|---|---|
| **M002** | C-BE-02 / C-BE-04 | `AMEND-C-BE-02-r1-v0.2.md` §3 + `AMEND-C-BE-04-r1-v0.2.md` §4 | ✅ RESOLVED | Multi-entropy PRNG mix: `os.clock()` + `GetGameTimer()` + `os.time()*1000` + `math.random` re-seed per-call + optional `GetPlayerPing(source)`. SHA256 blob → RFC 4122 v4 format. 122-bit target entropy. Phase A acceptable; Phase B target FFI crypto. 1M collision test + concurrency test propuestos. |
| **M003** | C-BE-02 | `AMEND-C-BE-02-r1-v0.2.md` §4 | ✅ RESOLVED | Dual rate-limit: standard token bucket + recursive guard independiente. 1 query/min per citizen + 10/min global. Bypass exception single-row `scope='self'` drill-down. `AUDIT_QUERY_THROTTLED` con `retry_after_ms`. Audit hook generado en reject. DoS recursivo cerrado. |
| **M004** ⚠️ | C-BE-05 (+ cross-cutting) | `AMEND-C-BE-05-r1-v0.2.md` §1 | ✅ RESOLVED ARCHITECTURAL | CP1-A → CP1-B migration: `bank.balance.<cid>` + `bank.savings.<cid>` eliminados de GlobalState. `TriggerLatentClientEvent` owner-only con ownership check server-side. `publish_balance_update()` helper defensive. `playerJoining` lazy publish. Bandwidth O(N²)→O(1). Admin audit vía evento separado P11. Cross-cutting impacts documentados (C-BE-01 +3 events, C-BE-02 ~15 callbacks refactor + C001b, C-BE-04 reconciliation emit refactor). Founder APPROVED 2026-05-06. |
| **M005** | C-BE-03 | `AMEND-C-BE-03-r1-v0.2.md` §2 | ✅ RESOLVED | `locked` TTL 10min vía columna `ttl_expires_at` reutilizada (zero migration). Cron `PurgeOrphans()` 5min. Estado `orphan_purged` transitorio. Audit entry `idempotency_key_orphan_purged` per row. Reuse post-purge vía `INSERT IGNORE`. DB Lead consultative confirmed column reuse OK. |
| **M006** | C-BE-02 | `AMEND-C-BE-02-r1-v0.2.md` §5 | ✅ RESOLVED | Convar exclusiva `sonar_bank_atm_hmac_secret` en `server.cfg` (nunca repo/git/logs). Boot valida `#secret >= 64` o `defensive_abort`. Generación `openssl rand -hex 32`. Rotation manual on-demand. Phase B dual-secret window deferred. DevOps Lead H4 runbook obligation documentada. |
| **M007** | C-BE-04 | `AMEND-C-BE-04-r1-v0.2.md` §5 | ✅ RESOLVED | Thresholds canónicos C-SEC-03 §6.2 implementados: HEALTHY ≥0.7, DEGRADED 0.1-0.7, COMPROMISED <0.1 con `emitted >= 50`, INSUFFICIENT_SAMPLE skip. Contadores instrumentados en `MutexEcho.encode/extract`. Transición a `compromised_load_order` con auth gate H002. Convars configurables. |
| **M008** | C-BE-04 | `AMEND-C-BE-04-r1-v0.2.md` §6 | ✅ RESOLVED | Escape `|` → `\|` en `reason_string`. Terminal sentinel `|END` + regex anclado `$` extrae ÚLTIMO marker. Validación UUID shape pre-encode. Falsos positivos/negativos eliminados. Round-trip property test propuesto. |

### 8.3 Advisories ratificados — no re-audit required

| ID | Contrato | Decision founder 2026-05-06 | Status |
|---|---|---|---|
| **M001** | C-BE-02 | ACCEPTED Phase A as-is + convar `sv_maxRateLimitResetGraceSeconds=300` | ✅ Ratified. DevOps H4 runbook obligation. Phase B KVP persistence target. |
| **L001** | C-BE-01 | DEFERRED Phase B | ✅ Ratified. Phase B `EventSchema.validate` gate. |
| **L002** | C-BE-01 | DEFERRED Phase B | ✅ Ratified. Phase B persistent admin event queue. |

### 8.4 New findings post-amendment

**Ninguno.** Re-audit adversarial exhaustivo de 4 AMEND files (1515+ líneas) + cross-cutting impacts §4 no reveló vulnerabilidades nuevas ni parches incompletos. Patches quirúrgicos son mínimos, bien delimitados y no introducen superficies de ataque adicionales.

### 8.5 Recommendation Security Lead

> **Emito dictamen PASS formal.** Los 6 hallazgos HIGH están cerrados con parches robustos y probables de implementación correcta. Los 6 MEDIUM AMEND (incluido M004 arquitectónico founder-approved) satisfacen las recomendaciones originales. Cross-cutting impacts están correctamente documentados para aplicación atómica en LOCK v1.0.1 R1.
>
> **Green-Light otorgado** para que el Backend Lead aplique patches in-place a `docs/technical/bank_phase_a/` + cross-cutting edits + version bump v1.0.1 R1 LOCKED.
>
> **Condición LOCK:** Todos los test scenarios T-AMEND-*.X deben ejecutarse y PASS durante implementación Phase A code (pre-merge CI). Static lint rules propuestas (AP-AUTH-1, AP-UUID-1, AP-SQL-1, AP-HMAC-1, AP-CP1-1) deben integrarse en runbook DevOps Lead H4.

---

FIN C-SEC-01/02/03 v0.2 RE-AUDIT — PASS — Green-Light LOCK v1.0.1 R1
