# Slice Backend — Cherry-pick Blueprint v1.2

> **Cherry-pick blueprint para Backend Money & Compatibility Lead.**
>
> **Audiencia:** Backend Money & Compatibility Lead.
>
> **Fecha:** 2026-05-06.
> **Status:** 🟢 Locked.
> **Source canonical:** `@docs/design/proposals/03_bank_app_blueprint_v1.md` v1.2.

---

## 1. Resumen ejecutivo dominio Backend

**Misión:** motor financial-grade Lua server-side. Bridges Layer extends + Core Override (QBox/QBCore) + Lite Mode Triple Capa (ESX 1.10+) + correlation-id mutex + reconciliation pipeline async + StateBags global publishers + ~40 callbacks + 9 FSMs.

**Por qué el orden 2º:** consumes schema DB LOCKED (post-H1) + entregas API contracts + FSMs + Bridges spec a Security/Frontend/DevOps Leads downstream.

**Tu output principal Phase A:**
- `docs/technical/02_events_catalog.md` v1.2 → v1.3 LOCKED.
- `docs/technical/04_api_contracts.md` v1.2 → v1.3 LOCKED.
- `docs/technical/05_state_machines.md` v1.0 → v1.1 LOCKED (joint con DB Lead).
- `docs/technical/07_bridges_compatibility.md` v1.0 → v1.1 LOCKED.
- ADR-018 sign ("Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns").

---

## 2. Cherry-pick secciones blueprint relevantes

### 2.1 Lectura prioridad ALTA

- **§3 Feature Taxonomy** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:200-700`. Tier 1-4 features. Cada feature implica callbacks + events.
- **§5.1 Callbacks API contracts proposal** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:900-1000` (aprox). C001-C035 + C058-C062.
- **§5.3 FSMs proposal** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1300-1500`. 8-9 FSMs.
- **§5.4 Events Catalog extends** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1500-1600`. NetEvents + StateBags global publishers (CP1).
- **§5.5 Resources arquitectura** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1600-1700`. `sonar_bank` extends + `sonar_bank_app` NEW + `sonar_bridges` extends.
- **§5.6 StateBags publishers proposal** — `@docs/design/proposals/03_bank_app_blueprint_v1.md` aprox. Refactor a StateBags global native (CP1).
- **§5.7 Bridges Layer spec** — `@docs/design/proposals/03_bank_app_blueprint_v1.md` aprox. Adapters + Core Override + Lite Mode.
- **§11 Q16 audit + 8 CP** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2496-2942`. **Lectura obligatoria completa**, especialmente §11.2 edge cases + §11.5 CP1-CP8 + §11.9 founder final decision.

### 2.2 Lectura prioridad MEDIA

- **§6 Roadmap Phase A** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1700-1900`.
- **§7.2 Scope changes Q1/Q8/Q10/Q12/Q16** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2209-2258`.
- **§5.8 Audit ledger inmutable spec** (Backend implementa hooks Security Lead spec post-H2).

### 2.3 Lectura prioridad BAJA (referencia opcional)

- **§4 UI/UX design** — para entender qué Frontend espera consume.
- **§8 Identity preserved + ADR-017** — naming conventions.

---

## 3. Decisiones founder Q1-Q16 filtered (Backend-relevantes)

### 3.1 Q1 — Govt mode configurable

**Impact Backend:** FSM `election_lifecycle` + 5 callbacks C058-C062 (`elections:start` / `elections:nominate` / `elections:vote` / `elections:results` / `elections:end_term`). Implementación logic per FSM.

### 3.2 Q3 — C003 unlock NOW Phase A

`bank.getTransactions` implementación Phase A (no tech debt).

### 3.3 Q11 — `transfer_complete` ACEPTAR + `compliance_alert` RECHAZAR

- `transfer_complete` → NetEvent fired post-success transfer.
- `compliance_alert` → NO event push. Visual fallback: Frontend query StateBag global `bank.compliance.<citizen_id>` derived state.

**Post-CP1:** todo Bank state changes (balance / accounts / status) via StateBags global native, no `TriggerClientEvent`.

### 3.4 Q12 — T4 100% in-scope

Callbacks T4 — crypto + stocks + loans + ATM + physical card + loyalty + recurring + round-ups.

### 3.5 Q16 — Hybrid 3-layer + 8 CP + cut ESX legacy

**Impact Backend mayor:**

- **Core Override** (QBox/QBCore) — runtime monkey-patch `Player.Functions.AddMoney/RemoveMoney`.
- **Lite Mode Triple Capa** (ESX 1.10+) — Event Hooking + Correlation-ID Mutex + Reconciliation Activa.
- **Cut ESX <1.10 OFICIAL** — defensive abort boot + console banner.
- **CP1** State Bags global mandatory.
- **CP2** Correlation-ID Mutex (path #1 ONLY, NO hash-fallback).
- **CP3** Reconciliation pipeline async (joint con DB).
- **CP4** Defensive boot + watchdog (joint con DevOps).
- **CP5** Threshold auto-apply €1000.
- **CP6** Reconciliation scope main only.
- **CP8** FSM `sonar_bank_status` (4 states).

---

## 4. Counter-proposals CP-relevantes filtered

| CP | Backend Lead role |
|---|---|
| **CP1** State Bags global | **Mandatory.** Refactor §5.6 publishers Bank balance/state. `GlobalState[bank.balance.<citizen_id>] = value` server-side writes + client-side `AddStateBagChangeHandler` reactive. |
| **CP2** Correlation-ID Mutex | **Mandatory.** Lib module `lib/mutex_echo.lua`. UUID v4 metadata `reason.sonar_correlation`. Hash-fallback DESCARTADO (cut ESX legacy). |
| **CP3** Reconciliation pipeline async | **Mandatory.** Lib module `lib/reconciliation.lua`. Queue + batch SQL multi-row + cache LRU + trust window 5min. Performance target 200 concurrent <500ms p99. |
| **CP4** Defensive boot + watchdog | **Mandatory.** 3-method framework detect + watchdog 30s + KVP graceful disable + console banner. Joint con DevOps. |
| **CP5** Threshold auto-apply €1000 | **Mandatory.** Backend implements threshold logic + admin flag queue para deltas >€1000. |
| **CP6** Reconciliation scope main only | **Mandatory.** Excluye savings/escrow/business_treasury/crypto del query. |
| **CP7** README + convars | NOT direct Backend. DevOps documenta. |
| **CP8** sonar_bank_status FSM | **Mandatory Backend (FSM logic) + Frontend (UI badge).** 4 states transitions logic. |

---

## 5. Anti-patterns Backend-específicos prohibidos

(Per prompt §9. Re-enumerados aquí brief.)

- ❌ Lua direct calls a framework fuera Bridges (`exports['qb-core']:...`).
- ❌ TriggerClientEvent manual para Bank state publishing (CP1 mandatory).
- ❌ Idempotency key sin storage persistente (replay attack post-restart).
- ❌ Mutex TTL-based (CP2 path #1 only).
- ❌ Reconciliation sync inline (CP3 async mandatory).
- ❌ Auto-apply delta > €1000 sin admin flag (CP5).
- ❌ Reconciliation scope premium tiers (CP6).
- ❌ Server boot sin defensive check (CP4).
- ❌ `print()` con datos sensibles.
- ❌ Callbacks sin auth check server-side.

---

## 6. Research recomendado primitivas modernas

(Per prompt §6.1.)

- State Bags global verificado.
- `experimentalStateBagsHandler` convar.
- Routing buckets — defer Phase D, pero confirma scope Phase A.
- ResourceKvp persistence.
- Infinity sync vs OneSync legacy.
- `Citizen.CreateThreadNow` vs `CreateThread`.
- `sv_enableNetEventReassembly`.
- Lazy resource start patterns.
- `onResourceStart` ordering + dependency declarations multi-fallback.

---

## 7. Open questions del dominio

| OQ | Pregunta | Recommendation Cascade PM |
|---|---|---|
| **OQ-BE-01** | Core Override approach exacto (monkey-patch vs metatable proxy vs hook event-based) | Recommend monkey-patch RAM (simplest + works runtime). Cuestiona alternatives. |
| **OQ-BE-02** | `compliance.<citizen_id>` StateBag privacy | Recommend reduced shape `{ has_active_flags: bool, count: number }` (no details leak). Details via direct event admin clients only. |
| **OQ-BE-03** | `bank.escrow.<escrow_id>` StateBag access | Recommend NOT broadcast StateBag global. Direct events to participants + admin. |
| **OQ-BE-04** | 9 FSMs es number correcto? | Cuestiona. Quizá merge `contract` con `escrow`. Quizá `audit_archive_lifecycle` defer Phase B. |
| **OQ-BE-05** | Callback granularity ~40 | Cuestiona. Quizá 30-35 con CRUD-like single endpoints `op` field para reducir surface. |
| **OQ-BE-06** | Idempotency keys storage | Recommend tabla DB persistent + cron prune 7 days TTL. (DB Lead schema.) |
| **OQ-BE-07** | Watchdog 30s vs longer + progressive | Cuestiona. Quizá dual-tier 30s + 5min + 30min progressive. |
| **OQ-BE-08** | Per-citizen vs global server `sonar_bank_status` | Recommend global server (CP8 4 states aplica server-wide). |
| **OQ-BE-09** | Correlation-id format | Recommend UUID v4 random (ox_lib has uuid helper). |
| **OQ-BE-10** | Reconciliation trust window adaptive | Cuestiona. Quizá idle players window larger. Phase A static 5min OK. |

---

## 8. Entregables esperados v1.0 LOCKED

### 8.1 SSoTs principales

- `docs/technical/02_events_catalog.md` v1.3.
- `docs/technical/04_api_contracts.md` v1.3 — todos callbacks documentados con auth + rate limit + idempotency + side effects + error codes + edge cases + perf target + test scenarios.
- `docs/technical/05_state_machines.md` v1.1 (joint con DB Lead) — 9 FSMs + transitions + invariants + side effects + persistence.
- `docs/technical/07_bridges_compatibility.md` v1.1 — Core Override + Lite Mode + correlation-id mutex + reconciliation pipeline + cut ESX legacy + Bridges API canonical + defensive boot.

### 8.2 ADR-018 firma

`docs/planning/02_decision_log.md` ADR-018 LOCKED ("Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns").

### 8.3 Sign-off

- founder ✅
- Backend Lead ✅ (tú)
- DB Lead ✅ (joint FSMs)
- Security Lead ✅ (review consultative)
- Frontend Lead ✅ (review consultative)
- DevOps Lead ✅ (review consultative)

---

## 9. Cross-team contracts

### 9.1 QUÉ EXIGES

- DB Lead: C-DB-01 v1.2 + migrations + perf benchmarks (post-H1).
- Founder: ADR-018 sign pre-handoff H2.

### 9.2 QUÉ ENTREGAS

- Security Lead: C-BE-01/02/03/04/05 LOCKED → audit surface (post-H2).
- Frontend Lead: API contracts + StateBag publishers spec (consume via Security audit).
- DevOps Lead: Bridges spec + fxmanifest dependencies + Core Override + Lite Mode modules.

---

## 10. Citas blueprint canonical

- Callbacks API: `@docs/design/proposals/03_bank_app_blueprint_v1.md:900-1000`.
- FSMs: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1300-1500`.
- Events catalog: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1500-1600`.
- Resources arquitectura: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1600-1700`.
- Q16 audit completo: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2496-2942`.
- §11.9 founder decision: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2876-2942`.

---

## 11. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v1.0** | 2026-05-06 | Initial release. Cherry-pick + Q1-Q16 + CP1-CP8 + 10 OQs filtered. |

— **Slice Backend LOCKED** post founder green-light 2026-05-06.
