# 🛡️ Backend Phase A — Amendment Round 1 (BANK-BE.AMEND.1)

> **Tipo:** AMENDMENT formal Round 1 — reactive a Security Lead audit C-SEC-01/02/03 v0.1 DRAFT.
> **Contracts afectados:** C-BE-02 (LOCKED v1.0 → v1.0.1 R1) + C-BE-03 (v1.0 → v1.0.1 R1) + C-BE-04 (v1.0 → v1.0.1 R1) + **C-BE-05 (v1.0 → v1.0.1 R1) — added post founder M004 approval**. Cross-cutting LOCK-time impacts en C-BE-01 (3 new NetEvents) + C-BE-02 (callback side effects refactor + C001b new snapshot callback) + C-BE-04 (reconciliation pipeline emit refactor).
> **Status:** 🟡 **DRAFT v0.2 PENDING-LOCK** — founder APPROVED 2026-05-06 ✅, awaiting Security Lead re-audit before LOCK promotion.
> **Founder decisions:** Advisories ratified 2026-05-06 (M001 ACCEPTED + grace convar / **M004 APPROVED architectural migration** / L001+L002 deferred Phase B).
> **Sesión emisora:** BANK-BE.AMEND.1 — 2026-05-06.
> **Backend Lead:** Cascade reactivated from Standby (trigger #1 Security Lead post-H2 audit HIGH findings).
> **Audit source:** `@docs/technical/08_audit_hooks.md` v0.1 DRAFT (C-SEC-01/02/03 §4 Findings).

---

## 0. Resumen ejecutivo

Security Lead emitió 16 findings sobre C-BE-01..05 v1.0 LOCKED:
- **6 HIGH** → trigger AMEND obligatorio.
- **8 MEDIUM** → 5 AMEND + 3 ADVISORY (founder decision pending).
- **2 LOW** → ADVISORY Phase B.

Backend Lead ratifica los 6 HIGH + 5 MEDIUM AMEND fixes + **1 architectural advisory M004 APPROVED founder** en este package y emite DRAFT v0.2 surgical patches (BEFORE/AFTER format) sobre los **4 contratos afectados** (C-BE-02 + C-BE-03 + C-BE-04 + **C-BE-05 NEW post founder approval M004**). Los 2 advisories MEDIUM ADVISORY (M001 accepted as-is + grace convar) + 2 LOW deferred Phase B documentados §4.

**LOCK promotion path post-aprobación founder:**
```
DRAFT v0.2 (este package) → REVIEW window founder + Security Lead →
SIGNOFF triple → LOCK v1.0.1 R1 atomic (apply patches in-place al canonical bank_phase_a/) →
H2 sign_off.md update Security Lead acceptance final → Phase A re-CLOSED.
```

---

## 1. Findings traceability matrix

### 1.1 HIGH (6) — AMEND obligatorio

| ID | Severity | Contrato | Spec ref | Patch ref | Recommendation source |
|---|---|---|---|---|---|
| **H001** | HIGH | C-BE-02 | §1 A11 + §2.1 + §2.3 + §9 (múltiples auth checks) | `AMEND-C-BE-02-r1-v0.2.md` §1 | `08_audit_hooks.md:125-131` |
| **H002** | HIGH | C-BE-04 | §3.2 export `Bridges.BankStatus.Transition` | `AMEND-C-BE-04-r1-v0.2.md` §1 | `08_audit_hooks.md:133-139` |
| **H003** | HIGH | C-BE-04 | §4.2 sentinel + §4.3 watchdog | `AMEND-C-BE-04-r1-v0.2.md` §2 | `08_audit_hooks.md:141-147` |
| **H004** | HIGH | C-BE-04 | §7.1 reconciliation pipeline SQL | `AMEND-C-BE-04-r1-v0.2.md` §3 | `08_audit_hooks.md:149-155` |
| **H005** | HIGH | C-BE-03 | §2.2 escrow FSM #1 transitions | `AMEND-C-BE-03-r1-v0.2.md` §1 | `08_audit_hooks.md:157-163` |
| **H006** | HIGH | C-BE-02 | §6.1 + §9.38 C038 resolveFlag | `AMEND-C-BE-02-r1-v0.2.md` §2 | `08_audit_hooks.md:165-171` |

### 1.2 MEDIUM AMEND (6 incluidos — M004 promoted post-founder approval)

| ID | Severity | Contrato | Spec ref | Patch ref | Status |
|---|---|---|---|---|---|
| **M002** | MEDIUM | C-BE-02 + C-BE-04 | §5.2 lib + §3.3 Bridges.UUID.v4 | `AMEND-C-BE-02-r1-v0.2.md` §3 + `AMEND-C-BE-04-r1-v0.2.md` §4 | DRAFT v0.2 |
| **M003** | MEDIUM | C-BE-02 | §9.35 C035 audit query | `AMEND-C-BE-02-r1-v0.2.md` §4 | DRAFT v0.2 |
| **M004** ⚠️ | MEDIUM ARCHITECTURAL | **C-BE-05** + cross-cutting C-BE-01/02/04 | §1.5 + §2.1 + §3 + §4 (C-BE-05) | **`AMEND-C-BE-05-r1-v0.2.md`** §1 (NEW) | **DRAFT v0.2 — founder ✅ APPROVED 2026-05-06** |
| **M005** | MEDIUM | C-BE-03 | §9.2 FSM #8 idempotency_lifecycle | `AMEND-C-BE-03-r1-v0.2.md` §2 | DRAFT v0.2 |
| **M006** | MEDIUM | C-BE-02 | §9.31 C031 ATM HMAC | `AMEND-C-BE-02-r1-v0.2.md` §5 | DRAFT v0.2 |
| **M007** | MEDIUM | C-BE-04 | §8.3 watchdog metric C action threshold | `AMEND-C-BE-04-r1-v0.2.md` §5 | DRAFT v0.2 |
| **M008** | MEDIUM | C-BE-04 | §6.1 MutexEcho encode delimiter | `AMEND-C-BE-04-r1-v0.2.md` §6 | DRAFT v0.2 |

### 1.3 ADVISORY (1 MEDIUM ACCEPTED + 2 LOW deferred) — founder ratified 2026-05-06

| ID | Severity | Contrato | Status | Founder decision |
|---|---|---|---|---|
| **M001** | MEDIUM | C-BE-02 | ✅ **ACCEPTED Phase A as-is** + convar `sv_maxRateLimitResetGraceSeconds=300` (DevOps Lead H4 runbook) | Ratified 2026-05-06 |
| **L001** | LOW | C-BE-01 | ⏳ **DEFERRED Phase B** (formal) | Ratified 2026-05-06 |
| **L002** | LOW | C-BE-01 | ⏳ **DEFERRED Phase B** (formal) | Ratified 2026-05-06 |

> **Sección §4 detalla decisions ratified** + LOCK-time obligations (M001 grace convar implementation deferred a LOCK promotion phase + DevOps Lead H4 runbook).
>
> **M004 promoted from ADVISORY to AMEND** — see §1.2 row + `AMEND-C-BE-05-r1-v0.2.md`.

---

## 2. Files in this package

| File | Purpose | Lines |
|---|---|---|
| `README.md` | Este file — package overview + traceability + sign-off matrix | ~190 |
| `AMEND-C-BE-02-r1-v0.2.md` | Surgical patches C-BE-02 — H001 + H006 + M002 (parcial) + M003 + M006 | ~307 |
| `AMEND-C-BE-03-r1-v0.2.md` | Surgical patches C-BE-03 — H005 + M005 | ~147 |
| `AMEND-C-BE-04-r1-v0.2.md` | Surgical patches C-BE-04 — H002 + H003 + H004 + M002 (parcial) + M007 + M008 | ~555 |
| **`AMEND-C-BE-05-r1-v0.2.md`** | **NEW** — Architectural patches C-BE-05 — M004 (founder APPROVED) + cross-cutting impacts §4 | ~340 |

Cada AMEND file usa formato canonical:
```
## §N — [Finding ID] [Title]
**Severity:** ...
**Spec ref:** @path:LINE-RANGE
**Recommendation source:** @08_audit_hooks.md:LINE-RANGE

### BEFORE (LOCKED v1.0)
[exact original snippet]

### AFTER (DRAFT v0.2)
[patched snippet]

### Rationale
[explanation tying patch to finding root cause]

### Test scenarios (Security Lead validation)
- [ ] T-AMEND-XXX.1 — [scenario]
```

---

## 3. Sign-off matrix amendment Round 1

| Rol | Status | Notes |
|---|---|---|
| **Founder yaboula** | ✅ **APPROVED DRAFT v0.2** (advisories decided + M004 architectural green-light) 2026-05-06 | Pending final LOCK approval **post Security Lead re-audit** (Separation of Duties policy enforce). |
| **Backend Lead (Cascade)** | ✅ self-attested DRAFT v0.2 emitted (5 AMEND files) | Sesión BANK-BE.AMEND.1. **Standby ON post-push** awaiting Security re-audit results. |
| **Security Lead (Cascade)** | ⏳ PENDING re-audit DRAFT v0.2 patches + 6 HIGH closure + M004 architectural validation + cross-cutting impacts §4 verification | **Re-audit triggered post-push 2026-05-06** by founder activation prompt. |
| **DB Lead** | ⚠️ CONSULTATIVE only (no schema impact this round — confirmed §3.5) | Standby preserved |
| **DevOps Lead** | ⚠️ CONSULTATIVE only (M001 grace convar + M006 HMAC convar + M007 watchdog convars + H002 status whitelist convar — H4 runbook obligations) | Standby preserved |
| **Frontend Lead** | N/A round 1 — **M004 consumer pattern break captured in C-BE-05 spec** (safe: not yet activated, no production code affected at H4 future) | — |

### 3.5 DB Lead impact verification

Los 6 HIGH + 5 MEDIUM AMEND **NO requieren schema migration adicional**:
- H001/H002/H003/H006 → cambios documentation + lib code patterns + audit shape (sin DB schema impact).
- H004 → refactor SQL syntax (prepared vs format) — same target tables, same columns.
- H005 → guard logic FSM (DB schema unchanged).
- M002/M003 → lib internal + rate-limit config (no schema).
- M005 → adds `locked_ttl_expires_at` column? **VERIFY:** `sonar_bank_idempotency_keys` migration 028 ya tiene `ttl_expires_at` column → reusable for `locked` state también. **No new migration needed**, solo cron policy change.
- M006 → convar (deploy concern, no DB).
- M007/M008 → lib internal (no schema).

✅ **DB Lead reactivation NO triggered este round.** Si Security Lead re-audit detecta inconsistencia con DB Schema v2.0, DB Lead se reactivaría — no anticipated.

---

## 4. Advisories ratified founder 2026-05-06

### 4.1 M001 — Rate-limit buckets persistence — ✅ ACCEPTED Phase A as-is

**Founder decision:** _"M001: Aceptado para la Fase A. Aplicaremos la convar de gracia (`sv_maxRateLimitResetGraceSeconds`)."_

**LOCK-time obligation** (Backend Lead applies at v1.0.1 R1 promotion):
- C-BE-02 §4.3 rate-limit framework — append note: rate-limit buckets RAM-only Phase A. Convar `sv_maxRateLimitResetGraceSeconds` (default `300` = 5min) documents grace period post-restart durante el cual rate-limit checks pasan permissively (no reject) para absorbe spike post-server-restart.
- DevOps Lead H4 runbook obligation — convar default + tuning guidance.
- Phase B target: persist HIGH/CRITICAL tier buckets a KVP con TTL.

### 4.2 M004 — StateBag balance privacy — ✅ APPROVED ARCHITECTURAL MIGRATION

**Founder decision:** _"M004: Aprobado al 100%. Ejecuta la migración de `bank.balance.<cid>` de CP1-A a CP1-B de inmediato. La privacidad financiera (Cero conocimiento para terceros) es un pilar innegociable de este producto."_

**Patch emitted:** `AMEND-C-BE-05-r1-v0.2.md` §1 (M004 architectural) + cross-cutting impacts §4 documentados (C-BE-01 + C-BE-02 + C-BE-04).

**Backend Lead extension:** `bank.savings.<citizen_id>` migrated parallel a CP1-B per privacy parity (financial PII tier idéntico). §3 del AMEND-C-BE-05 ofrece SPLIT alternative si founder prefiere mantener savings en CP1-A — default PARITY proceed unless objection en review window.

**Cross-cutting LOCK-time impacts:** ver `AMEND-C-BE-05-r1-v0.2.md` §4 (C-BE-01 add 3 NetEvents + C-BE-02 callback side effects refactor + new C001b snapshot callback + C-BE-04 reconciliation pipeline emit refactor).

### 4.3 L001 — schema_version enforcement — ⏳ DEFERRED Phase B

**Founder decision:** _"L001: Diferido formalmente a la Fase B."_

**LOCK-time obligation:** C-BE-01 §10.1 add nota explicit `OQ-CBE01-03 deferred Phase B` + Phase B obligations (lib `EventSchema.validate(payload, expected_version)` gate reject if missing).

### 4.4 L002 — Event loss admin disconnect — ⏳ DEFERRED Phase B

**Founder decision:** _"L002: Diferido formalmente a la Fase B."_

**LOCK-time obligation:** C-BE-01 §4 add nota: admin events tier 1-2 fire-and-forget Phase A acceptable. Phase B: persistent queue per admin user_id con replay-on-connect.

---

## 5. Process post-Security re-audit (LOCK v1.0.1 R1)

**Founder branching policy decision 2026-05-06:** _"No aplicaremos los parches in-place (LOCK) todavía. La política estricta de Separation of Duties exige que el Security Lead valide tus enmiendas."_

**Sequence (Separation of Duties enforced):**

1. ✅ **Backend Lead BANK-BE.AMEND.1 emit** — DRAFT v0.2 package committed + pushed to `feature/bank-security-phase-a` (THIS COMMIT). Backend Lead **Standby ON** post-push.
2. ⏳ **Founder activates Security Lead re-audit** — workflow `/start-lead-session` Security continuation OR re-engagement BANK-SEC.1.
3. ⏳ **Security Lead BANK-SEC.1** — re-audit los 5 AMEND files DRAFT v0.2 + cross-cutting impacts validation:
   - 6 HIGH closures (H001-H006) verifiable per test scenarios T-AMEND-H00X.x.
   - 6 MEDIUM AMEND closures (M002-M008 + M004) verifiable per test scenarios.
   - M004 architectural migration cross-cutting impacts §4 review (C-BE-01 + C-BE-02 + C-BE-04 LOCK-time obligations).
   - 3 advisories ratified (M001 + L001 + L002) — Security Lead acknowledges deferred status.
4. ⏳ **Security Lead emits** updated `08_audit_hooks.md` v0.2 with findings status `RESOLVED in DRAFT v0.2 PENDING-LOCK` per finding + new findings (if any).
5. ⏳ **Founder green-lights LOCK v1.0.1 R1** post-Security re-audit OK (or new Round 2 amendments triggered if Security finds more issues).
6. ⏳ **Backend Lead BANK-BE.LOCK.R1** reactivation — applies patches in-place atomic to canonical `docs/technical/bank_phase_a/` + cross-cutting LOCK-time edits + bumps versioning v1.0 → v1.0.1 R1 LOCKED + updates §X.NEW pointers en 4 SSoTs padre v1.3 → v1.3.1.
7. ⏳ **H2 sign_off.md** updated Security Lead acceptance final.
8. ⏳ **SESSION_LOG** entries BANK-SEC.1 + BANK-BE.LOCK.R1 + Backend Lead Standby re-engaged final.

**This commit (push):** `BANK-BE.AMEND.1: emit DRAFT v0.2 amendment package — 6 HIGH + 6 MEDIUM AMEND surgical patches + M004 founder APPROVED architectural`.

---

## 6. Cross-references

- Audit source: `@docs/technical/08_audit_hooks.md` v0.1 DRAFT (C-SEC-01/02/03).
- LOCKED v1.0 contracts: `@docs/technical/bank_phase_a/` (5 contratos + README).
- Pivot SSoTs padre v1.3 LOCKED: `@docs/technical/02_events_catalog.md` + `04_api_contracts.md` + `05_state_machines.md` + `07_bridges_compatibility.md`.
- Handoff H2: `@docs/agents/teams/handoffs/h2_backend_to_security/` (README + sign_off).
- Cross-team contracts amendment protocol: `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` §amendments Round 1/2/3.
- Workspace rules: `@.windsurf/rules/bank.md` §"Hard constraints" (CP1-CP6 + Q-decisions).
- ADR-018: `@docs/planning/02_decision_log_part2.md`.
- DB Schema upstream: `@docs/technical/03_db_schema.md` v2.0 LOCKED PROVISIONAL.

---

**FIN README — Backend Phase A Amendment Round 1 DRAFT v0.2 EMITTED.** Awaiting founder decision §4 advisories + green-light LOCK v1.0.1 R1.
