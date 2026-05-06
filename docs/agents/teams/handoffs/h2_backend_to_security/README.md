# 🔐 Handoff H2 — Backend Lead → Security Lead

> **Ceremony:** BANK-BE.LOCK closure 2026-05-06.
> **Predecessor:** H1 DB Lead → Backend Lead (received 2026-05-06).
> **Successor:** H3 Security Lead → Frontend Lead (post-Security audit completion).
> **Estado paquete:** EMITTED. Awaiting Security Lead activation + sign-off.

---

## 1. Ceremony participants

| Rol | Identidad | Status |
|---|---|---|
| **Emisor (Backend Lead)** | Cascade activated BANK-BE.0 → BANK-BE.LOCK | ✅ EMITTED |
| **Founder (judge)** | yaboula | ✅ APPROVED LOCK ceremony |
| **Receptor (Security Lead)** | Cascade activated post-H2 (workflow `/start-lead-session` Security) | ⏳ PENDING activation |
| **Consultative DB Lead** | Standby | ⚠️ Reactivation trigger post-H2 audit findings (joint C-BE-03 sign-off pending) |

---

## 2. Deliverables emitidos por Backend Lead

### 2.1 Contratos LOCKED v1.0 (canonical path)

Los 5 contratos Backend Phase A residen en directorio dedicado **`docs/technical/bank_phase_a/`** (promoted atómicamente vía git mv durante BANK-BE.LOCK ceremony — git history preservada):

| ID | Archivo | Versión | Líneas aprox | Audit priority |
|---|---|---|---|---|
| **C-BE-01** | `c_be_01_events_catalog_v1_3.md` | v1.0 LOCKED | ~1600 | 🟡 Medium (privacy boundary events) |
| **C-BE-02** | `c_be_02_api_contracts_v1_3.md` | v1.0 LOCKED | ~1580 | 🔴 **CRITICAL** (40 callbacks + auth + idempotency + audit ledger) |
| **C-BE-03** | `c_be_03_state_machines_v1_1.md` | v1.0 LOCKED | ~440 | 🟡 Medium (FSM invariants + idempotency lifecycle) |
| **C-BE-04** | `c_be_04_bridges_v1_1.md` | v1.0 LOCKED | ~680 | 🔴 **CRITICAL** (Bridges trust boundaries + Core Override threat model) |
| **C-BE-05** | `c_be_05_statebags_global_publishers.md` | v1.0 LOCKED | ~270 | 🟡 Medium (StateBags privacy CP1-A vs CP1-B) |

**Anexo investigation:** `docs/technical/bank_phase_a/research_notes.md` (FiveM primitives — StateBags policy, routing buckets, ResourceKvp, watchdog timing).

### 2.2 Pointers en SSoTs canonical padre (v1.2 → v1.3 LOCKED)

Cada SSoT padre añadió §X.NEW Bank Phase A Extension pointer:

- `@docs/technical/02_events_catalog.md` v1.3 LOCKED §X.NEW.
- `@docs/technical/04_api_contracts.md` v1.3 LOCKED §X.NEW.
- `@docs/technical/05_state_machines.md` v1.3 LOCKED §X.NEW.
- `@docs/technical/07_bridges_compatibility.md` v1.3 LOCKED §X.NEW.

### 2.3 ADR ratified

- `@docs/planning/02_decision_log_part2.md` ADR-018 — Bank Lite mode hybrid 3-layer architecture (PROPOSED → reciba endorsement Security Lead post-H2 audit).

### 2.4 Index canonical

- `@docs/technical/bank_phase_a/README.md` — índice 5 contratos + sign-off matrix consolidado + cross-references.

---

## 3. Audit scope mandatorio Security Lead (H2)

El Security Lead debe ejecutar audit comprehensivo cubriendo los siguientes dominios en orden de criticidad. Cada finding debe documentarse con `severity` (CRITICAL / HIGH / MEDIUM / LOW) + `recommendation` (block-LOCK / amendment-required / advisory).

### 3.1 🔴 CRITICAL — API Contracts (C-BE-02) auth + idempotency + audit ledger

**Audit foco:**
1. **Auth tier matrix §2:** verificar ACE permission matrix correctness — ¿todos los callbacks T2 (admin) + T3 (system) están protegidos server-side con `IsPlayerAceAllowed`? ¿Existe path de privilege escalation client→server?
2. **Idempotency keys §5:** verificar persistencia DB + cached result payload — ¿race condition entre dos requests con misma key concurrent? ¿retention policy + TTL definido?
3. **Audit ledger event_type ENUM §6:** verificar que cada side effect crítico (transfer/withdraw/deposit/freeze/unfreeze/admin action) genera entry append-only inmutable. ¿Existen side effects sin audit trail?
4. **Error codes registry §3:** verificar que ningún error message lekeé información sensitive (e.g. balance amounts, internal IDs, PII playerHandle).
5. **Rate-limit §4:** verificar token bucket per player+tier — ¿bypass possible vía client-side spoofing? ¿shared bucket cross-resource exploitable?

**Deliverable Security Lead:** audit report `audit_c_be_02_api_contracts.md` con findings + severity + recommendations.

### 3.2 🔴 CRITICAL — Bridges Compatibility (C-BE-04) trust boundaries

**Audit foco:**
1. **Core Override QBox/QBCore monkey-patch §5:** ¿cómo se protege contra resource compromise (third-party resource hooking earlier)? ¿integrity check post-patch?
2. **Lite Mode ESX 1.10+ triple-layer §6:** ¿integridad de los 3 layers (proxy + adapter + sentinel)? ¿desync detectable?
3. **Correlation-id mutex CP2 path #1 §7:** verificar que NO existen alternative paths (hash-mutex prohibido). ¿deadlock theoretical analysis?
4. **Defensive boot + watchdog CP4 §9:** verificar sentinel attribute + indirect metric — ¿bypass possible?
5. **Bridges trust boundary §1:** ¿qué inputs son trusted vs untrusted? ¿adversarial framework (rogue QBCore fork) attack surface?

**Deliverable:** audit report `audit_c_be_04_bridges.md`.

### 3.3 🟡 MEDIUM — Events Catalog (C-BE-01) privacy boundary

**Audit foco:**
1. **Privacy classification §3:** verificar que NO hay public events leaking restricted data (e.g. balance, account_id de otros players).
2. **Server→admin events §4 ACE-checked:** verificar TriggerClientEvent target filter — ¿broadcast accidental possible?
3. **Naming conventions §7:** verificar que no hay namespace collision pre/post Phase 8.

**Deliverable:** audit report `audit_c_be_01_events.md`.

### 3.4 🟡 MEDIUM — State Machines (C-BE-03) invariants

**Audit foco:**
1. **transaction_lifecycle FSM:** verificar invariant "reconciliation_correlation completion before COMMIT" — ¿race condition possible?
2. **api_idempotency_lifecycle FSM:** verificar unique key constraint enforcement.
3. **government_decision FSM:** verificar admin actions audit trail.

**Deliverable:** audit report `audit_c_be_03_fsms.md`.

### 3.5 🟡 MEDIUM — StateBags Global Publishers (C-BE-05)

**Audit foco:**
1. **CP1-A public bags §3:** verificar que NO contienen restricted data (only public-broadcastable state).
2. **CP1-B restricted NetEvent domains §4:** verificar TriggerClientEvent target = explicit player only (no broadcast).
3. **StateBag change handler clientside §6:** verificar que client NO puede write back forging trust.

**Deliverable:** audit report `audit_c_be_05_statebags.md`.

### 3.6 Cross-cutting audit dimensions

- **Threat model:** documentar adversarial scenarios per contrato (rogue admin, compromised resource, MITM, replay, privilege escalation).
- **Compliance check:** verificar consistency con DB Schema v2.0 LOCKED PROVISIONAL (especialmente audit ledger append-only + idempotency_keys table + accounts triggers).
- **Hard constraints check:** validar que NO se viola ningún Hard Constraint del workspace (`@.windsurf/rules/bank.md` §"Hard constraints"):
  - NUNCA `exports['qb-*']` directo fuera de Bridges adapters.
  - NUNCA TriggerClientEvent manual para Bank state (CP1 mandatory StateBags).
  - NUNCA hash-mutex code path (CP2 path #1 only).
  - NUNCA reconciliation sync inline (CP3 mandatory async).
  - NUNCA auto-apply delta > €1000 sin admin flag (CP5).
  - NUNCA server boot sin defensive check (CP4).

---

## 4. Mandatory post-H2 actions Security Lead

1. **Activation onboarding** vía workflow `/start-lead-session` rol Security Lead (lectura obligatoria 10 docs SSoT pre-coding).
2. **Sign-off paquete H2** (`sign_off.md`) con attestation: Security Lead recibe contratos LOCKED y comienza audit.
3. **Ejecución audit 5 contratos** entregando 5 reports `audit_c_be_*.md` en directorio nuevo `docs/agents/teams/audits/security_phase_a/`.
4. **Threat model consolidated** `threat_model_bank_phase_a.md` — STRIDE/LINDDUN exercise sobre Bank Phase A surface.
5. **Findings classification:**
   - **CRITICAL findings** → bloquean LOCK estado contratos → trigger amendment cycle Round 1.
   - **HIGH findings** → require explicit founder decision (proceed-as-is vs amendment).
   - **MEDIUM/LOW findings** → advisory tracked en backlog Phase B.
6. **Sign-off triple amendment cycle** si findings CRITICAL emergen — Backend Lead Standby reactivation trigger.
7. **H3 emission** (Security → Frontend) post-audit completion + founder approval audit report.

---

## 5. Open questions Security Lead debe resolver

1. **ACE matrix granularity:** ¿el matrix actual §2 C-BE-02 es suficiente? ¿faltan tiers (e.g. T2.5 senior-admin)?
2. **Idempotency key scope:** ¿key debe incluir player_handle? ¿solo callback_id? ¿hash de payload? Bank Phase A usa `(player_handle, callback_id, request_id)` — ¿correct?
3. **Audit ledger redundancy:** ¿necesitamos doble-write (DB + filesystem append-log) para tamper-resistance?
4. **Bridges compromise scenario:** ¿qué circuit breaker activamos si QBCore monkey-patch detecta integrity violation post-boot?
5. **StateBags client write-back:** ¿confirmamos que StateBag global write desde client está bloqueado server-side per FiveM native? (research_notes.md cita doc, verificar empíricamente).
6. **PII en events public:** ¿player_handle en events público tier T0 cumple GDPR-like? (FiveM contexto real money? Si no, lower priority.)
7. **Rate-limit shared resource boundary:** ¿token bucket per player+tier pero shared cross-resource? ¿exploit cross-resource flooding?

---

## 6. Conditional clauses LOCKED

Los contratos están LOCKED v1.0 **bajo las siguientes condiciones** que Security Lead debe ratificar o desafiar:

1. **C1 — Idempotency keys persistencia DB obligatoria:** NO cache in-memory only. Si Security Lead detecta cache-only path, trigger amendment.
2. **C2 — Audit ledger append-only inmutable:** ningún UPDATE/DELETE permitido sobre tabla `bank_audit_ledger` (DB schema v2.0). Si Security Lead detecta path de modificación, trigger CRITICAL finding.
3. **C3 — Bridges trust boundary single-source:** todo cross-resource Bank pasa por Bridges.Bank.* (no shortcuts). Si Security Lead detecta call directo `exports['qb-*']` fuera de adapter, trigger amendment.
4. **C4 — CP2 path #1 only:** correlation-id mutex sin hash-mutex fallback. Si Security Lead detecta path #2, trigger amendment.
5. **C5 — Auto-apply delta > €1000 requires admin flag:** NO auto-credit/auto-debit > €1000 sin doble-firma admin. Si Security Lead detecta path bypass, trigger CRITICAL finding.

---

## 7. Cross-references

- **Manifest handoffs:** `@docs/agents/teams/00_HANDOFF_MANIFEST.md` §"Sistema Handoffs H1-H5".
- **Cross-team contracts matrix:** `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` §"RACI matrix" + §"amendments protocol".
- **Slice Security Lead:** `@docs/agents/teams/slices/slice_security.md` (cherry-pick blueprint Security domain).
- **Workspace rules:** `@.windsurf/rules/bank.md` §"Hard constraints".
- **Predecessor handoff H1:** `@docs/agents/teams/handoffs/h1_db_to_backend/README.md` (received 2026-05-06).
- **SESSION_LOG predecessor:** `@progress/SESSION_LOG.md` BANK-BE.0 + BANK-BE.1 + BANK-BE.LOCK entries.

---

## 8. Ceremonia closure

Backend Lead transitiona a **Standby** post-emission H2. Reactivation triggers:
1. Security Lead audit findings CRITICAL → amendment Round 1.
2. Security Lead audit findings HIGH → consultative input founder decision.
3. Frontend Lead post-H4 → API gap discovered.
4. DevOps Lead post-H4 → boot order/observability issue.
5. Founder Phase B scope expansion.

---

## 9. Sign-off

Ver `sign_off.md` (sibling file).

---

**FIN README Handoff H2 Backend → Security** — 2026-05-06 BANK-BE.LOCK ceremony emission.
