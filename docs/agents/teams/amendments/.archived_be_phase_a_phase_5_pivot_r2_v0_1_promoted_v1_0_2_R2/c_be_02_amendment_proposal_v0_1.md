# AMEND C-BE-02 — API Contracts — Round 2 Phase 5 Pivot (DRAFT v0.1)

> **Tipo:** AMENDMENT formal Round 2 — Phase 5 architectural pivot. **ADDITIVE only**: existing 40+1 callbacks LOCKED v1.0.1 R1 unchanged.
> **Contract afectado:** C-BE-02 API Contracts v1.0.1 R1 LOCKED → propuesta v1.0.2 R2.
> **Status:** 🟡 **DRAFT v0.1 PENDING-SIGNOFF**.
> **Sesión emisora:** `BANK-BE.PHASE_5.1` Phase 1 — 2026-05-12.
> **Authority source:** Founder LOCK `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md` v1.0 (Q1, Q3, Q5, Q6, Q7, Q8).

---

## 0. Resumen ejecutivo

Phase 5 introduce una **NEW superficie pública server-to-server** de 22 exports
(`exports.sonar_bank_app:*`) que recursos third-party invocan para mutar
dinero, separada del canal callbacks `sonar:bank:*` LOCKED preservado intacto.

Esta amendment **NO modifica** ningún callback C001-C040 ni C001b existente
(signatures, auth tiers, error codes, rate limits, idempotency, side effects
LOCKED v1.0.1 R1 todo preservado). Únicamente **AGREGA**:

1. Nueva sección `§NEW — Server-to-Server Exports surface` con tabla canónica
   de 22 exports + signatures + error codes per export + ACE/allowlist gates
   Tier 2 + idempotency support per export + audit shape ref.
2. Extensión §3.1 error codes registry con 1 código nuevo `PLAYER_NOT_LOADED`
   (Q8 LOCKED) — backwards compatible (additive enum).
3. Extensión §1.2 NEW principle `A18 — Boundary convention split` documenta
   convención dual exports surface (INTEGER minor) vs callbacks legacy
   (DECIMAL major) per Q1 LOCKED.

**Severidad cambio:** MAJOR additive (nueva superficie pública contractual)
con ZERO breaking changes a callbacks existentes.

---

## 1. Finding traceability

| ID | Trigger | Severity | Source | Action |
|---|---|---|---|---|
| **P5-002** | Phase 5 design SSoT `04_sonar_bank_api.md` v0.2 requiere superficie pública contractual LOCKED (callbacks LOCKED son privados NUI-only; exports son public ecosystem API). | MAJOR additive | `@docs/design/04_sonar_bank_api.md` v0.2 §3 + §4 | ADD §NEW Exports surface |
| **P5-003** | Q1 LOCKED split convention requiere documentar boundary entre INTEGER minor (exports) y DECIMAL major (callbacks/DB/Frontend). | MAJOR additive | `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md:13-29` | ADD §1.2 A18 + §NEW.boundary |
| **P5-004** | Q8 LOCKED introduce error code `PLAYER_NOT_LOADED` distinto de `PLAYER_NOT_FOUND`. | MINOR additive | `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md:146-162` | ADD §3.1 row |

---

## 2. §1.2 — NEW principle A18 — **ADD**

### Inserción canónica post-A17 en §1.2

```markdown
- **A18 (Phase 5 Q1 LOCKED)** **Boundary convention split.** La superficie
  pública exports server-to-server (Tier 1/2 documentada en §NEW abajo) usa
  **INTEGER minor units** en todos los amount fields. La superficie legacy
  callbacks (C001-C040 + C001b) y DB DECIMAL columns y Frontend display
  preservan **DECIMAL major units** Phase A. Boundary helpers
  `sonar_bank_app/server/lib/units.lua` (`to_minor` / `from_minor`,
  HALF_UP rounding) **mandatory** en cada wrapper Tier 1/2 — NUNCA float
  math en service layer una vez convertido a integer.

  Phase A+1 migra DB + callbacks + Frontend end-to-end a INTEGER minor —
  roadmap `@docs/planning/roadmap_phase_a_plus_1_minor_units_migration.md`.
```

---

## 3. §3.1 — Error codes registry — **EXTEND**

### Añadir fila en tabla canonical post `PLAYER_NOT_FOUND` (si existe) o post `AUTH_ACE_DENIED`

```markdown
| `PLAYER_NOT_LOADED` | 423 (Locked) | Player source existe pero framework PlayerData no cargada (PRE-PlayerLoaded race). | YES (event-driven) | Hint en error data: `{ retry_after_event = '<framework-specific>' }`. Caller subscribe a PlayerLoaded antes de retry. NEW Q8 R2. |
```

**Diferencia vs `PLAYER_NOT_FOUND`:** este último cubre source inexistente
(player dropped, invalid handle); `PLAYER_NOT_LOADED` cubre source válido
pero `Bridges.Identity.IsLoaded(source) == false` (Q8 LOCKED helper NEW
añadido en C-BE-04 §3.2 amendment paralelo Round 2 Tier 1 wrapper guard).

---

## 4. §NEW — Server-to-Server Exports surface — **ADD ENTIRE SECTION**

Inserción canónica post §9 (callbacks LOCKED end), pre §10 (si existe) o
end-of-file. Header `## 10. NEW — Server-to-Server Exports surface (Phase 5 R2)`.

---

### 10.1 Modelo + alcance

Recursos third-party server-side (vehicle shops, jobs, fines, taxes, ATMs,
businesses) invocan `exports.sonar_bank_app:<Op>(...)` para mutar dinero. NO
hay equivalente client-callable — los exports son **server-only** por
naturaleza FiveM.

Design SSoT: `@docs/design/04_sonar_bank_api.md` v0.2.

**Trust model:** `GetInvokingResource()` se persiste en audit (`invoker_resource`
field per C-SEC-01 §1.2 10-field shape) y se chequea contra
`sonar:admin_allowlist` convar para Tier 2 cuando `actor_src == 0` (console).
NO HMAC / NO JWT (server-side exports already privileged by FiveM runtime).

---

### 10.2 Boundary helpers `lib/units.lua` (mandatory)

```lua
-- sonar_bank_app/server/lib/units.lua (NEW Phase 5 implementation 4.1)
-- HALF_UP rounding. Float math prohibido downstream.

units.to_minor(decimal_input)   -- (string|number) -> integer cents
units.from_minor(integer_minor) -- integer cents -> string "1234.56" for DB DECIMAL
```

Every Tier 1/2 wrapper applies `to_minor` al recibir `amount_minor` desde
caller (defensive — caller debe ya pasar integer pero validation idempotente)
y `from_minor` al invocar service layer + DB insert + `publish_balance_update`.

Property tests Phase 5 validation §5.1 ST-024.1: round-trip identity, edge
cases (0, max int64 cents, negative).

---

### 10.3 Tier 1 — Public mutation exports (11)

#### 10.3.1 Tabla canónica Tier 1

| # | Export | Args | Return tuple `(ok, error, data)` | Error codes possible | Idempotency | ACE gate |
|---|---|---|---|---|---|---|
| 1 | `AddMoney` | `(source:int, amount_minor:int, reason:string, opts?:table)` | `(boolean, string?, {new_balance_minor, iban, tx_id}?)` | `INVALID_ARGUMENT, INVALID_AMOUNT, PLAYER_NOT_FOUND, PLAYER_NOT_LOADED, ACCOUNT_NOT_FOUND, ACCOUNT_FROZEN, ACCOUNT_CLOSED, IDEMPOTENCY_REPLAY (ok=true), INTERNAL_ERROR` | `opts.idempotency_key?` | None (Tier 1) |
| 2 | `RemoveMoney` | `(source:int, amount_minor:int, reason:string, opts?:table)` | idem + `tx_id` | + `INSUFFICIENT_FUNDS` | `opts.idempotency_key?` | None |
| 3 | `CanAfford` | `(source:int, amount_minor:int)` | `(boolean, string?, {balance_minor, sufficient}?)` | `INVALID_ARGUMENT, PLAYER_NOT_FOUND, PLAYER_NOT_LOADED, ACCOUNT_NOT_FOUND` | N/A (read) | None |
| 4 | `GetBalance` | `(source:int)` | `(boolean, string?, {balance_minor, savings_minor, iban}?)` | idem | N/A | None |
| 5 | `TransferBySource` | `(from_src:int, to_src:int, amount_minor:int, reason:string, opts?:table)` | `(boolean, string?, {from_iban, to_iban, amount_minor, fee_minor, tx_id}?)` | + `INSUFFICIENT_FUNDS, LIMIT_EXCEEDED, ACCOUNT_FROZEN (either)` | `opts.idempotency_key?` | None |
| 6 | `TransferByIban` | `(from_iban:string, to_iban:string, amount_minor:int, reason:string, opts?:table)` | idem | idem + `IBAN_INVALID` | `opts.idempotency_key?` | None |
| 7 | `AddMoneyByCitizen` | `(citizen_id:string, amount_minor:int, reason:string, opts?:table)` | idem export #1 | `INVALID_ARGUMENT, INVALID_AMOUNT, CITIZEN_NOT_FOUND, ACCOUNT_NOT_FOUND, ACCOUNT_FROZEN, ACCOUNT_CLOSED, IDEMPOTENCY_REPLAY, INTERNAL_ERROR` | `opts.idempotency_key?` | None |
| 8 | `RemoveMoneyByCitizen` | `(citizen_id:string, amount_minor:int, reason:string, opts?:table)` | idem export #2 | + `INSUFFICIENT_FUNDS` | `opts.idempotency_key?` | None |
| 9 | `CanAffordByCitizen` | `(citizen_id:string, amount_minor:int)` | idem export #3 | `CITIZEN_NOT_FOUND, ACCOUNT_NOT_FOUND` | N/A | None |
| 10 | `GetBalanceByCitizen` | `(citizen_id:string)` | idem export #4 | idem | N/A | None |
| 11 | `TransferByCitizen` | `(from_cid:string, to_cid:string, amount_minor:int, reason:string, opts?:table)` | idem export #5 | + `INSUFFICIENT_FUNDS, LIMIT_EXCEEDED, ACCOUNT_FROZEN` | `opts.idempotency_key?` | None |

**Notas Tier 1:**

- `TransferByIban` (#6) NO requiere `*ByCitizen` sibling (IBAN ya
  citizen-agnostic). Total Tier 1 = **11 exports** (6 baseline + 5
  *ByCitizen) per Q6 LOCKED.
- `*ByCitizen` variants resuelven `citizen_id → IBAN primario` via
  `AccountService.GetPrimaryByCitizen(cid)`. NO requieren player online; si
  citizen offline, mutation persiste DB + audit; mirror sync deferred a
  next `PlayerLoaded` event (Q6 LOCKED offline-safe semantics).
- Tier 1 NUNCA acepta `opts.allow_overdraft` — `RemoveMoney`/`TransferBy*`
  rechazan con `INSUFFICIENT_FUNDS` si balance < amount (Q5 LOCKED).
- `CanAfford` returns ambos `balance_minor` actual y `sufficient: bool`
  para evitar double-fetch en caller pattern típico (`if CanAfford ... then
  RemoveMoney`).

#### 10.3.2 `opts` table schema canonical (Tier 1 mutations)

```lua
opts = {
  idempotency_key = string?,    -- UUIDv4 preferido; max 128 chars; persisted en sonar_bank_idem 24h TTL
  correlation_id  = string?,    -- UUIDv4 trace cross-resource; auto-generated si absent
  account_iban    = string?,    -- override target IBAN si player tiene multiple accounts; default = primary
  reason_meta     = table?,     -- key-value pairs additional audit context (max 16 keys, 256 chars each)
}
```

**Idempotency persistence:** se reusa `sonar_bank_idempotency_keys` LOCKED v1.0.1 R1 NOT — Phase 5 introduce nueva tabla más simple `sonar_bank_idem` (PRIMARY KEY `idem_key`, `result_json`, `invoker_resource`, `created_at`, 24h TTL cron purge) — migration `036_sonar_bank_idem.sql` Phase 4.2 implementation. Justificación tabla separada: callbacks LOCKED usan FSM `idempotency_lifecycle` con states (locked, completed, failed) — exports surface usa modelo más simple "INSERT IGNORE + cached result_json" sin FSM, suficiente para semantic Tier 1/2 atomic exports.

---

### 10.4 Tier 2 — Admin/operator exports (10)

#### 10.4.1 Tabla canónica Tier 2

| # | Export | Args | Return tuple | Error codes possible | Idempotency | Auth gate |
|---|---|---|---|---|---|---|
| 12 | `AdminCredit` | `(actor_src:int, target:int|string, amount_minor:int, reason:string, opts?:table)` | `(boolean, string?, {iban, new_balance_minor, tx_id}?)` | `INVALID_ARGUMENT, INVALID_AMOUNT, AUTH_ACE_DENIED, AUTH_ALLOWLIST_DENIED, PLAYER_NOT_FOUND, CITIZEN_NOT_FOUND, ACCOUNT_NOT_FOUND, ACCOUNT_CLOSED, IDEMPOTENCY_REPLAY, INTERNAL_ERROR` | `opts.idempotency_key?` | `Auth.RequireAdmin(actor_src)` OR `actor_src==0` console OR `GetInvokingResource() ∈ sonar:admin_allowlist` |
| 13 | `AdminDebit` | idem | idem | + `INSUFFICIENT_FUNDS` (si `opts.allow_overdraft != true`) | idem | idem |
| 14 | `AdminSetBalance` | `(actor_src, target, new_balance_minor, reason, opts?)` | `(boolean, string?, {iban, prev_balance_minor, new_balance_minor, delta_minor, tx_id}?)` | idem (sin INSUFFICIENT_FUNDS — overwrite total) | `opts.idempotency_key?` | idem |
| 15 | `Freeze` | `(actor_src, target_iban:string, reason)` | `(boolean, string?, {iban, previous_flag_snapshot}?)` | `INVALID_ARGUMENT, AUTH_ACE_DENIED, AUTH_ALLOWLIST_DENIED, IBAN_INVALID, ACCOUNT_NOT_FOUND, ACCOUNT_ALREADY_FROZEN` | None (state mutation idempotent natively) | idem |
| 16 | `Unfreeze` | idem | idem | + `ACCOUNT_NOT_FROZEN` | None | idem |
| 17 | `AdminCreditByCitizen` | `(actor_src, citizen_id, amount_minor, reason, opts?)` | idem #12 | idem #12 con `CITIZEN_NOT_FOUND` reemplaza `PLAYER_NOT_FOUND` | idem | idem |
| 18 | `AdminDebitByCitizen` | idem | idem #13 | idem #13 | idem | idem |
| 19 | `AdminSetBalanceByCitizen` | idem | idem #14 | idem #14 | idem | idem |
| 20 | `FreezeByCitizen` | `(actor_src, citizen_id, reason)` | resuelve citizen → IBAN primary → idem #15 | idem #15 + `CITIZEN_NOT_FOUND` | None | idem |
| 21 | `UnfreezeByCitizen` | idem | idem #16 | idem #16 + `CITIZEN_NOT_FOUND` | None | idem |

**Polymorphic note (Q6 LOCKED clarification):** PM Cascade docs original `Q6` describe `target` arg como polymorphic (`source OR citizen_id`). Decisión implementation Phase 1: exportar variantes explícitas `*ByCitizen` para Tier 2 también (10 exports en lugar de 5 polymorphic) — paridad con Tier 1 + type safety (Lua no type-checks runtime, pero contract surface más legible). Polymorphic detect-by-type queda como **patrón internal** dentro del wrapper si Founder prefiere superficie pública de 5 + auto-detect; default Phase 5 implementation = 10 explícitos.

**Founder confirma durante Phase 2 sign-off:** ¿exportar 22 explícitos (preferred) o 17 con Tier 2 polymorphic (5+5+11)? Default = 22 explícitos.

#### 10.4.2 `opts.allow_overdraft` semantic (Q5 LOCKED)

```lua
opts = {
  -- ... Tier 1 fields ...
  allow_overdraft = boolean?,    -- DEFAULT false. true → permite balance negativo post-mutation.
                                 -- Audit event_type → 'bank_overdraft' (NEW C-SEC-01 enum amendment Round 2).
                                 -- Tier 1 IGNORA este flag (siempre false). Tier 2 honra explícitamente.
}
```

#### 10.4.3 `Auth.RequireAdmin` helper canonical (cross-ref C-BE-02 §2.3.1)

`Auth.RequireAdmin(actor_src)` retorna `(true, citizen_id)` o `(false, 'AUTH_ACE_DENIED' | 'AUTH_ALLOWLIST_DENIED')`. Lookup order:

1. `actor_src == 0` (console) → `(true, nil)` (audit `actor_account_id = NULL`, `invoker_resource = GetInvokingResource() OR 'console'`).
2. `actor_src > 0` + `IsPlayerAceAllowed(actor_src, 'sonar.bank.admin')` → `(true, Bridges.Player.GetCitizenId(actor_src))`.
3. `actor_src > 0` falla ACE pero `GetInvokingResource() ∈ split(GetConvar('sonar:admin_allowlist', ''))` → `(true, Bridges.Player.GetCitizenId(actor_src))` con audit flag `actor_via_allowlist = true`.
4. Else → `(false, 'AUTH_ACE_DENIED')` o `(false, 'AUTH_ALLOWLIST_DENIED')` según rama.

ACE permission `sonar.bank.admin` documentado en C-SEC-02 §2.1 (P-ADMIN). Convar `sonar:admin_allowlist` (comma-separated resource names) documentado en DevOps runbook H4 (NEW post-Phase 5 LOCK).

---

### 10.5 Rigid fee policy (Q7 LOCKED — NO override)

Cada `TransferBy*` Tier 1 y `AdminCredit/AdminDebit/AdminSetBalance` Tier 2
honra `Config.FeePolicies` (LOCKED Phase A `@resources/sonar_bank_app/config.lua`)
automáticamente. **NO opts.skip_fees**, **NO opts.fee_override_minor**.

Rationale Q7: matemáticas simples, reglas aplican a todos, audit shape limpio,
operator ajusta fees globales vía config.

---

### 10.6 Atomic guarantees per export

Cada Tier 1/2 mutation export ejecuta dentro de **un solo SQL transaction**
con commit atomic de:

1. Balance mutation (`sonar_bank_accounts.balance` update).
2. Movement row insert (`sonar_bank_movements` append-only).
3. Audit row insert (`sonar_audit_log` 10-field shape per C-SEC-01 §1.2,
   `event_type = bank_credit | bank_debit | bank_transfer | admin_credit |
   admin_debit | admin_set_balance | account_freeze | account_unfreeze |
   bank_overdraft`).
4. Idempotency row insert (si `opts.idempotency_key` presente) en
   `sonar_bank_idem`.

**Post-commit (best-effort, NO bloquea return):**

5. `publish_balance_update(citizen_id, balance_decimal_major, account_class,
   opts)` invocado per C-BE-05 §2.2.1 NetEvent CP1-B canonical (UNA call por
   account_class afectado: main + savings si transfer cross-account, sino una
   sola call). Path (a) Founder §9 LOCKED: signature de `publish_balance_update`
   preservada (`balance` arg en DECIMAL major) — wrapper invoca
   `units.from_minor(new_balance_minor)` antes del publish.
6. `MirrorSync.SetBalance` best-effort framework wallet (player online).

**Si pasos 1-4 fallan → rollback total + return error.** Si paso 5 falla →
log warning, NO rollback (StateBag/NetEvent eventual consistency aceptable).
Si paso 6 falla → log warning, retry on next login.

---

### 10.7 Side effects table (cross-ref §6 LOCKED)

| Side effect | Tier 1 mutations | Tier 2 mutations | Notas |
|---|---|---|---|
| `sonar_bank_accounts.balance` mutation | ✅ | ✅ | Atomic same TX. |
| `sonar_bank_movements` append | ✅ | ✅ | Append-only LOCKED Phase A. |
| `sonar_audit_log` append | ✅ | ✅ | 10-field shape C-SEC-01 §1.2. |
| `sonar_bank_idem` upsert | ✅ si `opts.idempotency_key` | ✅ idem | NEW migration 036. |
| `sonar:bank:balance:update` NetEvent (per account_class) | ✅ | ✅ | C-BE-05 §2.2.1. DECIMAL major path (a). |
| `sonar:bank:savings:update` NetEvent | ✅ si savings affected | ✅ idem | Idem. |
| Mirror to framework wallet | ✅ best-effort | ✅ best-effort | `MirrorSync.SetBalance` simplificado §C-BE-04 §4'.4. |
| Compliance autoraise hook | Mantained existing AR-P01/P02/P03 LOCKED | Mantained existing AR-P05 admin override LOCKED | C-SEC-03 §3.1 unchanged. |

---

### 10.8 GetApiVersion() informational export (NEW)

```lua
exports.sonar_bank_app:GetApiVersion()
-- returns table { major=1, minor=0, patch=0, phase='5', api_lock='2026-05-12' }
```

Consumers feature-detect via `local v = exports.sonar_bank_app:GetApiVersion(); if v.major >= 1 then ... end`. NO contado en los 22 mutation exports (este es read-only informational, no audit).

---

### 10.9 Performance budgets per export

Heredan budgets de service layer LOCKED. Wrapper overhead target:

- Validation + boundary conversion + audit insert + idempotency lookup: **<5 ms p99**.
- Total wrapper latency (incluido SQL TX): **<50 ms p99** Tier 1 reads, **<150 ms p99** Tier 1/2 mutations.
- Idempotency replay (cached hit): **<10 ms p99** (single PRIMARY KEY lookup).

Validación en Phase 5 ST-024 smoke harness (`@resources/sonar_bank/server/smoke_phase_5_exports.lua`).

---

## 5. Compat existing callbacks C001-C040

| Componente | Impacto | Acción |
|---|---|---|
| Callbacks C001-C040 + C001b signatures | ZERO breaking | None — todo LOCKED v1.0.1 R1 preservado intacto. |
| Auth helpers §2.3.1 H001 R1 | ZERO breaking | None. |
| Error codes registry §3.1 | ADDITIVE (1 NEW code `PLAYER_NOT_LOADED`) | Frontend callers tienen default branch — backwards compatible. |
| ACE matrix §2.2 | ZERO breaking | None. NEW Tier 2 reuse `sonar.bank.admin` P-ADMIN existente. |
| Rate-limit infrastructure §4 | Exports NOT rate-limited Phase A (server-side trust) | DevOps Lead H4 runbook documents. |
| Idempotency lifecycle FSM #8 §9.2 + table `sonar_bank_idempotency_keys` | Mantained — callbacks siguen consumiendo este. Exports usan tabla separada `sonar_bank_idem` (migration 036). | None. |

---

## 6. Sign-off proposal Round 2

| Role | Sign-off requerido | Notas |
|---|---|---|
| Founder yaboula | ✅ Sí | LOCK promotion authority + Q1/Q5/Q6/Q7/Q8 decisions. |
| Backend Lead Phase 5 | ✅ Sí self-attest | Esta DRAFT v0.1. |
| Security Lead (BANK-SEC.2) | ✅ Sí consumer review | Foco: §NEW.10.4 auth model + §NEW.10.6 atomic guarantees + audit shape cross-ref. |
| Frontend Lead | ✅ Sí consumer ack | Confirma callbacks LOCKED unchanged Phase A (no Frontend touch). |
| PM Cascade | ✅ Sí promote ceremony | `/lock-contract` Phase 2. |

Sign-off matrix completo en `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/sign_off_matrix.md`.

---

## 7. LOCK promotion path

```
DRAFT v0.1 → REVIEW founder + Security + Frontend ack → SIGNOFF →
LOCK v1.0.2 R2 atomic in-place patch (apply ADD §1.2 A18 + §3.1 row + §NEW.10 entire) →
SESSION_LOG entry BANK-BE.PHASE_5.1 Phase 2 LOCK →
Archive este DRAFT.
```

---

## 8. References

- Founder LOCK: `@docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md`.
- Prompt: `@docs/agents/teams/prompts/08_phase_5_ecosystem_api_backend_lead.md` (§4 Phase 1.2).
- Design SSoT: `@docs/design/04_sonar_bank_api.md` v0.2 (Phase 1.8 same package).
- C-BE-02 LOCKED v1.0.1 R1: `@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md`.
- C-BE-04 R2 amendment: `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/c_be_04_amendment_proposal_v0_1.md`.
- C-SEC-01 R2 amendment (audit shape): `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/c_sec_01_amendment_proposal_v0_1.md`.
- C-BE-05 R2 amendment (NetEvent path a): `@docs/agents/teams/amendments/be_phase_a_phase_5_pivot_r2/c_be_05_amendment_proposal_v0_1.md`.
- Precedente formato: `@docs/agents/teams/amendments/.archived_be_phase_a_r1_v0_2_promoted_v1_0_1_R1/AMEND-C-BE-02-r1-v0.2.md`.

— Backend Lead Phase 5 (BANK-BE.PHASE_5.1)
2026-05-12
