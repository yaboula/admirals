# AMEND-C-BE-03-r1-v0.2 — Surgical Patches DRAFT

> **Target contract:** `@docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md` v1.0 LOCKED → v1.0.1 R1 PENDING-LOCK.
> **Round:** 1 (BANK-BE.AMEND.1).
> **Status:** 🟡 DRAFT v0.2 — review founder + Security Lead.
> **Findings addressed:** H005 (HIGH) + M005 (MEDIUM AMEND).

---

## §1 — H005 fix · FSM #1 escrow zero-amount release guard

**Severity:** HIGH
**Spec ref:** `@docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md:67` (FSM #1 escrow_lifecycle, transition `funded → released_partial`).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:157-163`.

### Root cause analysis

Current guard `release_amount < escrow_amount` permite `release_amount=0` (válido aritméticamente: 0 < N siempre true para N>0). Esto causa:
1. **Zero-value movements spam** — INSERT `sonar_bank_movements` con amount=0 → ledger pollution.
2. **Audit ledger noise** — each zero-release emit `audit_event_type='escrow_released'` with delta=0 → forensics noise.
3. **StateBag updates inútiles** — re-broadcast a Frontend with same balance.
4. **Idempotency key consumption** — un attacker malicioso (o bug client) podría drenar token bucket rate-limit con calls release_amount=0 que técnicamente succeed.

Adicionalmente, transition adyacente `funded → released_full` con guard `release_amount == escrow_amount` también necesita strengthening: si `escrow_amount=0` (caso degenerate post-data-corruption), `release_amount=0` igualaría → false-success on broken state.

### 1.1 BEFORE (LOCKED v1.0) — §2.2 transitions table rows

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md:67-69
| `funded` | `released_partial` | C010 `bank.escrow.release` callback (partial mode) | release_amount < escrow_amount, payer/payee/admin permission | INSERT releases, UPDATE escrows.balance + state, UPDATE accounts, audit |
| `funded` | `released_full` | C010 `bank.escrow.release` callback (full mode) | release_amount == escrow_amount | INSERT release row terminal, UPDATE state, audit |
| `released_partial` | `released_full` | C010 final release | release_amount == remaining_balance | INSERT release final, audit |
```

### 1.1 AFTER (DRAFT v0.2)

```markdown
| `funded` | `released_partial` | C010 `bank.escrow.release` callback (partial mode) | **`release_amount > 0` AND `release_amount < escrow_amount`** AND payer/payee/admin permission AND `escrow_amount > 0` (defensive) | INSERT releases, UPDATE escrows.balance + state, UPDATE accounts, audit |
| `funded` | `released_full` | C010 `bank.escrow.release` callback (full mode) | **`release_amount > 0` AND `release_amount == escrow_amount`** AND `escrow_amount > 0` | INSERT release row terminal, UPDATE state, audit |
| `released_partial` | `released_full` | C010 final release | **`release_amount > 0` AND `release_amount == remaining_balance`** AND `remaining_balance > 0` | INSERT release final, audit |
```

### 1.2 ADD NEW — §2.3 invariants reinforcement

After current §2.3 invariants list (post-line `:80`), append new bullet:

```markdown
- **NEW v0.2 R1 (H005 fix):** Todos los release transitions del FSM #1 escrow_lifecycle DEBEN guardar `release_amount > 0` explícito + `escrow_amount > 0` o `remaining_balance > 0` defensive check. Zero-value releases prohibidos — error code `INVALID_PAYLOAD` con field=`release_amount` y reason `must_be_positive`. Esto previene movement spam + audit noise + token bucket drainage attack.
```

### 1.3 ADD NEW — §2.4 side effect note

After current §2.4 side effects list, add:

```markdown
**R1 H005 callback-level enforcement:** C010 `bank.escrow.release` (`@docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` §9.10) DEBE validar `payload.release_amount > 0` ANTES del FSM transition attempt. FSM guard es defensive secondary line. Validation order:
1. Schema validation (`release_amount` is number).
2. Positive check (`release_amount > 0`).
3. Auth check (payer/payee/admin per AUTH-OWNER_OR_PARTICIPANT or AUTH-ROLE_OR_OWNER).
4. FSM guard re-validates positive (defensive double-check) + boundary check vs `remaining_balance`.
5. Atomic transaction execute.
```

### 1.4 Test scenarios (Security Lead validation)

- [ ] **T-AMEND-H005.1** — C010 con `release_amount=0` y `escrow_amount=100` → return `{ status='error', error={ code='INVALID_PAYLOAD', field='release_amount', reason='must_be_positive' } }`. NO movement INSERT. NO audit. NO StateBag update.
- [ ] **T-AMEND-H005.2** — C010 con `release_amount=-50` → return same INVALID_PAYLOAD (negative also rejected).
- [ ] **T-AMEND-H005.3** — C010 con `release_amount=100`, `escrow_amount=0` (degenerate corruption) → return INVALID_PAYLOAD reason=`escrow_balance_zero` (defensive).
- [ ] **T-AMEND-H005.4** — C010 con `release_amount=50`, `escrow_amount=100`, `remaining_balance=100` → success transition `funded → released_partial`.
- [ ] **T-AMEND-H005.5** — Stress test: 1000 calls C010 release_amount=0 paralelo → 0 movements INSERT, 0 audit entries `escrow_released` (only `validation_failed` audit hook entries).

---

## §2 — M005 fix · FSM #8 idempotency `locked` orphan keys

**Severity:** MEDIUM
**Spec ref:** `@docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md:300-329` (§9 FSM #8 idempotency_lifecycle).
**Recommendation source:** `@docs/technical/08_audit_hooks.md:205-211`.

### Root cause

Current FSM #8 spec §9.3:
- TTL purge 7d para `completed` + `failed` keys (cron daily).
- **NO TTL** para state `locked` → si server crashea entre `IdempotencyKeys.Lock(key)` y `IdempotencyKeys.Complete(key)` (e.g. host machine reboot, FiveM crash, exception unhandled mid-callback), la key queda **PERMANENTLY orphan** en state `locked`.

Consecuencias:
1. **Replay attempts del mismo key bloqueados** indefinidamente: caller recibe `IDEMPOTENCY_INFLIGHT` forever (callback §5.3 wait short + recheck → siempre `locked` → reject).
2. **DB pollution acumulada** — orphan keys se acumulan resource crash a crash sin reclaim.
3. **Forensics ambigua** — admin queries audit ledger no pueden distinguir "in-flight legitimate" vs "orphaned post-crash".

### 2.1 BEFORE — §9.1 states table

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md:303-305
| `locked` | Key inserted con `INSERT IGNORE`. Operation in flight. | NO |
| `completed` | Operation finished success. `result_payload` JSON cached. | **YES** (until TTL 7d expiry purge). |
| `failed` | Operation finished error. `result_payload` JSON contains error details. | **YES** (until TTL 7d expiry purge). |
```

### 2.1 AFTER

```markdown
| `locked` | Key inserted con `INSERT IGNORE`. Operation in flight. **NEW v0.2 R1 (M005):** TTL 10min `locked_ttl_expires_at` defensive — orphan keys post-crash reclaimable via cron. | NO (transient — debe transit a `completed`/`failed` o ser orphan-cleaned). |
| `completed` | Operation finished success. `result_payload` JSON cached. | **YES** (until TTL 7d expiry purge). |
| `failed` | Operation finished error. `result_payload` JSON contains error details. | **YES** (until TTL 7d expiry purge). |
| `orphan_purged` | **NEW v0.2 R1 (M005):** transient marker for keys que estuvieron en `locked` past TTL → cron cleanup transition. Logged + audited. Row eligible for reuse with same key (rare scenario — fresh `INSERT IGNORE` succeeds). | **YES** (immediately purged). |
```

### 2.2 BEFORE — §9.2 transitions table

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md:309-313
| From | To | Trigger | Guard |
|---|---|---|---|
| (insert) | `locked` | `IdempotencyKeys.Lock(key, domain, payload_hash)` | INSERT IGNORE (key not exist) |
| `locked` | `completed` | `IdempotencyKeys.Complete(key, result_payload)` | operation success path |
| `locked` | `failed` | `IdempotencyKeys.Fail(key, error_payload)` | operation error path |
```

### 2.2 AFTER

```markdown
| From | To | Trigger | Guard |
|---|---|---|---|
| (insert) | `locked` | `IdempotencyKeys.Lock(key, domain, payload_hash)` | INSERT IGNORE (key not exist) — **set `locked_ttl_expires_at = NOW() + 10min`** (R1 M005) |
| `locked` | `completed` | `IdempotencyKeys.Complete(key, result_payload)` | operation success path — clear `locked_ttl_expires_at`, set `ttl_expires_at = NOW() + 7d` |
| `locked` | `failed` | `IdempotencyKeys.Fail(key, error_payload)` | operation error path — clear `locked_ttl_expires_at`, set `ttl_expires_at = NOW() + 7d` |
| `locked` | `orphan_purged` | **NEW v0.2 R1 (M005):** Cron `IdempotencyKeys.PurgeOrphans()` tick — query `WHERE state='locked' AND locked_ttl_expires_at < NOW()` → delete rows + audit entry per row | `locked_ttl_expires_at < NOW()` (10min stale) |
```

### 2.3 BEFORE — §9.3 side effects (cron note)

```@/d/theBigProject/docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md:328
- Cron: TTL purge 7d cron tick (DevOps Lead H4 deploy).
```

### 2.3 AFTER

```markdown
- Cron:
  - **TTL purge 7d** (existing): `WHERE state IN ('completed','failed') AND ttl_expires_at < NOW()` daily tick.
  - **NEW v0.2 R1 (M005) Orphan purge 10min:** cron tick **frequency 5min** runs `IdempotencyKeys.PurgeOrphans()`:
    - Query `WHERE state='locked' AND locked_ttl_expires_at < NOW()`.
    - For each orphan: DELETE row + INSERT audit ledger entry `event_type='idempotency_key_orphan_purged'` con shape `{key, domain, payload_hash, locked_at, locked_ttl_expires_at, purged_at, source_resource}`.
    - Log warn `idempotency: purged N orphan keys (post-crash recovery)`.
  - DevOps Lead H4 deploy schedule both crons.
- **NEW v0.2 R1 (M005) Audit ledger event_type addition:** `idempotency_key_orphan_purged` (forensics).
```

### 2.4 ADD NEW — §9.4 schema migration note

After §9.3 side effects, append:

```markdown
### 9.4 Schema impact (NEW v0.2 R1 — M005)

**DB Schema v2.0 LOCKED PROVISIONAL** `sonar_bank_idempotency_keys` (migration 028) ya tiene column `ttl_expires_at` — reusable. Patch v1.0.1 R1 reusa columna existente sin migration adicional:

- `state='locked'` rows: `ttl_expires_at = NOW() + 10min` (overload semantic — column purpose extends para locked TTL también).
- `state='completed'/'failed'` rows: `ttl_expires_at = NOW() + 7d` (existing).

**OR** alternativa cleaner (founder decision opcional): introducir column NEW `locked_ttl_expires_at` separada via amendment migration 029. Backend Lead recommendation default = **reuse existing column** (zero-migration impact, semantic OK porque cron query distingue por `state`).

**DB Lead consultative confirmation:** column `ttl_expires_at` schema permits both semantics ✅. No DB Lead reactivation needed. Si founder prefiere migration 029 NEW column → DB Lead reactiva.
```

### 2.5 ADD NEW — §6.2 audit ledger ENUM addition (cross-ref to C-BE-02)

> Cross-cutting note: §6.2 audit ledger ENUM en `c_be_02_api_contracts_v1_3.md` MUST add new entry `idempotency_key_orphan_purged`. Patch in `AMEND-C-BE-02-r1-v0.2.md` §2.2 already mentions canonical shape extension — **add extra patch §2.4 here noting cross-edit:**

**Cross-amendment requirement:** `AMEND-C-BE-02-r1-v0.2.md` §6.2 audit ENUM add entry:
```
idempotency_key_orphan_purged   -- Cron orphan reclaim post-crash recovery (NEW v0.2 R1 M005)
```

(Backend Lead apply at LOCK time — not separate AMEND file needed since trivial ENUM addition.)

### 2.6 Test scenarios

- [ ] **T-AMEND-M005.1** — Mock crash scenario: `IdempotencyKeys.Lock(key)` succeeds, server crash before `Complete()` → next boot, cron `PurgeOrphans()` runs at 5min → key purged + audit entry inserted.
- [ ] **T-AMEND-M005.2** — `Lock(key=K1)`, wait 11min (no Complete), retry `Lock(key=K1)` after orphan purge → succeeds (fresh `INSERT IGNORE` since K1 row gone).
- [ ] **T-AMEND-M005.3** — `Lock(key=K2)`, `Complete(K2)` within 10s → row state=`completed`, `locked_ttl_expires_at` cleared (NULL or NOW()), `ttl_expires_at = NOW()+7d`. Cron `PurgeOrphans()` does NOT touch this row (state filter).
- [ ] **T-AMEND-M005.4** — Audit query for `event_type='idempotency_key_orphan_purged'` returns rows post-cron-tick with full shape `{key, domain, payload_hash, locked_at, locked_ttl_expires_at, purged_at, source_resource}`.
- [ ] **T-AMEND-M005.5** — Cron freq verification: `IdempotencyKeys.PurgeOrphans()` runs every 5min ± 30s window (DevOps Lead H4 schedule).

---

## §3 — Versioning + sign-off

### 3.1 Versioning entry (post-LOCK promotion)

Append a §17 Versioning C-BE-03 row pendiente:

```markdown
| **v1.0.1 R1 LOCKED** | TBD post-founder approval | BANK-BE.AMEND.1 surgical patches Round 1 reactive a Security Lead audit C-SEC-01/02/03 v0.1: H005 (FSM #1 escrow zero-amount release guard `release_amount > 0` + defensive `escrow_amount > 0` boundary checks across 3 transitions) + M005 (FSM #8 idempotency_lifecycle `locked` orphan TTL 10min + cron `PurgeOrphans` 5min frequency + new state `orphan_purged` + audit ENUM `idempotency_key_orphan_purged`). Sin schema migration impact (column `ttl_expires_at` reuse — DB Lead consultative confirmed). DB Lead joint endorsement deferred trigger Standby reactivation post-H2 audit completion (existing per v1.0). Sign-off founder + Backend + Security re-audit. |
```

### 3.2 Sign-off (this AMEND file)

| Rol | Status |
|---|---|
| Backend Lead (Cascade) | ✅ self-attested DRAFT v0.2 emitted |
| Founder yaboula | ⏳ PENDING review |
| Security Lead (Cascade) | ⏳ PENDING re-audit closure H005 + M005 |
| DB Lead | ⚠️ CONSULTATIVE confirmed `ttl_expires_at` column reuse OK (NO reactivation needed) |

---

**FIN AMEND-C-BE-03-r1-v0.2 DRAFT** — 2 patches surgical (H005 + M005).
