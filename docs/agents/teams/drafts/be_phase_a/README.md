# Backend Phase A — DRAFT v0.1 deliverables index

> **Owner:** Backend Money & Compatibility Lead (Cascade Sonnet 4.6 — sesión BANK-BE.0).
> **Status:** 🟡 **DRAFT v0.1 — review window open.** Sin LOCKED hasta sign-off triple founder + Backend + consumers (Security + Frontend + DevOps consultative).
> **Fecha:** 2026-05-06 (BANK-BE.0).
> **Branch:** `feature/bank-backend-phase-a`.
> **Handoff target:** H2 Backend → Security (post LOCKED v1.0 todos los 5 contratos).

---

## 1. Por qué DRAFT directory dedicado (vs DB Lead inline pattern)

### 🟡 Deviation profesional respecto al DB Lead workflow

DB Lead extendió `docs/technical/03_db_schema.md` directamente con §22-§29 — pattern in-line consolidando 1 archivo canonical. Razón válida en su caso: **1 SSoT extendido = 1 archivo**.

Backend Lead extiende **4 archivos canonical distintos** (`02_events_catalog.md` + `04_api_contracts.md` + `05_state_machines.md` + `07_bridges_compatibility.md`) más entrega un nuevo sub-spec (StateBags Global Publishers — vive dentro de events catalog `§statebags-global-publishers`).

Aplicar pattern in-line a 4 archivos durante DRAFT v0.x review window genera:

- Polución 4 SSoTs canonical pre-LOCKED (riesgo edits parciales medio-firmados visibles a otros Leads).
- Diff-conflict potential si paralelizar review.
- Reversibilidad costosa si DRAFT iterations cambian shape estructural.

**Decisión:** durante DRAFT v0.x, los 5 contratos viven en este directorio aislado. **Promotion atómica** a paths canonical se ejecuta como una sola unidad post-LOCKED triple sign-off, en la handoff ceremony H2. Esto preserva los SSoTs canonical limpios en versión v1.2 LOCKED hasta LOCKED v1.3 promotion completion.

**Razones técnicas:**
1. **Atomicidad LOCKED:** los 5 contratos firman juntos en H2 (per §2.1 cross-team contracts matrix). Promotion atómica garantiza coherencia cross-document refs.
2. **Diff-friendly review:** founder + consumer Leads revisan 5 archivos focused vs 4 archivos polluted con secciones half-baked.
3. **Reversibilidad cero-coste:** si DRAFT v0.2 reescribe shape, simply rewrite DRAFT — canonical paths intactos.
4. **Audit trail explícito:** git log filtrable a `docs/agents/teams/drafts/be_phase_a/` muestra full evolution Backend Phase A authoring sin mezclar con SSoT pre-LOCKED histórico.

**Impact downstream:** Security Lead + Frontend Lead + DevOps Lead consultative review sobre estos paths DRAFT durante review window. Post-promotion ceremony H2, refs cross-team se actualizan a paths canonical en una sola commit atómico.

---

## 2. Deliverables Backend Phase A v1.0 LOCKED targets

| ID | Contrato | Path DRAFT v0.x | Path canonical post-promotion | Status BANK-BE.0 |
|---|---|---|---|---|
| **C-BE-01** | Events Catalog v1.3 | `c_be_01_events_catalog_v1_3.md` | `docs/technical/02_events_catalog.md` v1.3 (extends §X NEW Bank Phase A) | 🔴 **DEFERRED BANK-BE.1** |
| **C-BE-02** | API Contracts v1.3 (~40 callbacks) | `c_be_02_api_contracts_v1_3.md` | `docs/technical/04_api_contracts.md` v1.3 (extends §X NEW Bank Phase A) | 🔴 **DEFERRED BANK-BE.1** |
| **C-BE-03** | State Machines v1.1 (8 FSMs joint DB) | `c_be_03_state_machines_v1_1.md` | `docs/technical/05_state_machines.md` v1.1 (extends §X NEW Bank Phase A FSMs) | 🟡 **DRAFT v0.1 BANK-BE.0** |
| **C-BE-04** | Bridges Compatibility v1.1 | `c_be_04_bridges_v1_1.md` | `docs/technical/07_bridges_compatibility.md` v1.1 (extends §X NEW Bank Phase A) | 🟡 **DRAFT v0.1 BANK-BE.0** |
| **C-BE-05** | StateBags Global Publishers Spec | `c_be_05_statebags_global_publishers.md` | `docs/technical/02_events_catalog.md` §statebags-global-publishers (sub-section dentro v1.3) | 🟡 **DRAFT v0.1 BANK-BE.0** |
| **ADR-018** | Bank Lite mode 3-layer + 8 mitigation patterns | append a `docs/planning/02_decision_log_part2.md` | (mismo path — ADR registry canonical) | 🟡 **Proposed BANK-BE.0** |

**Razón orden:**
- C-BE-04 (Bridges) + C-BE-05 (StateBags) + C-BE-03 (FSMs) son **architectural foundation** — establecen patterns + privacy contract + state lifecycle. C-BE-01 events depende del shape final C-BE-05 (NetEvents + StateBag refs). C-BE-02 API contracts depende C-BE-03 FSMs (callbacks reference state transitions).
- C-BE-01 + C-BE-02 son los más volumétricos (~40 callbacks documentados con auth + rate-limit + idempotency + side effects + error codes + perf targets + test scenarios). Realistic scope BANK-BE.1 con foundation BANK-BE.0 estable.

---

## 3. Cuestionamientos founder LOCKED pre-DRAFT (Q-BE-pre 1-12)

Resueltos en BANK-BE.0 onboarding handshake:

| Q | Resolución founder 2026-05-06 |
|---|---|
| Q-BE-pre-01 FSMs count | ✅ **8 FSMs LOCKED**. credit_score_recompute + audit_archive **DEFERRED Phase B**. |
| Q-BE-pre-02 compliance StateBag privacy | ✅ **Reduced public bag** `{ has_active_flags: bool, count: number }` + admin NetEvents detail. |
| Q-BE-pre-03 escrow StateBag privacy | ✅ **NO StateBag global**. Discrete NetEvents directos a participantes + admin. |
| Q-BE-pre-04 callback granularity | ✅ **Granular (~40)** mantenido. |
| Q-BE-pre-05 watchdog approach | ✅ **B + C combinados** — Sentinel Attribute + Métrica Indirecta. |
| Q-BE-pre-06 idempotency storage | ✅ **DB persistent + result_payload JSON cached** (replay devuelve mismo payload). |
| Q-BE-pre-07 sonar_companies workaround | ✅ **`Companies.exists()` passthrough + warn log Phase A**. |
| Q-BE-pre-08 benchmark execution | ✅ **Opción C** — standalone Lua + mock oxmysql + estimación fundada flagged. |
| Q-BE-pre-09 ADR-018 sign-off | ✅ Compilar canonical en `02_decision_log_part2.md` BANK-BE.0 + firmar H2. |
| Q-BE-pre-10 git branch | ✅ `feature/bank-backend-phase-a` + stash frontend WIP. |
| Q-BE-pre-11 Bridges API extends | ✅ Extender existing API sin breaking. |
| Q-BE-pre-12 resource scope split | ✅ Callbacks NEW → `sonar_bank_app/server/`. Libs core → `sonar_bridges/`. |

---

## 4. Sign-off matrix targets (5 contratos LOCKED v1.0)

Per `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` §RACI matrix:

| Contrato | Founder | Backend (owner) | DB (joint FSMs) | Security | Frontend | DevOps |
|---|---|---|---|---|---|---|
| C-BE-01 Events | A (sign) | RA | C | C | C | I |
| C-BE-02 API | A (sign) | RA | C | C | C | I |
| C-BE-03 FSMs | A (sign) | RA (joint) | RA (joint) | C | C | I |
| C-BE-04 Bridges | A (sign) | RA | I | C | I | C |
| C-BE-05 StateBags | A (sign) | RA | C | I | C | I |
| ADR-018 | A (sign) | proposer | I | C | I | C |

**LOCKED v1.0 ceremony:** founder ✅ + Backend Lead ✅ + DB Lead ✅ (joint FSMs) + Security Lead ✅ (consultative) + Frontend Lead ✅ (consultative) + DevOps Lead ✅ (consultative). Triple sign-off mínimo: founder + owner + 1 consumer per contrato.

---

## 5. Estado promoción canonical paths post-LOCKED H2

Cuando los 5 contratos pasen LOCKED v1.0:

1. **Atomic promotion commit** — un solo commit `BANK-A.X promote backend phase A drafts to canonical` aplica:
   - `docs/technical/02_events_catalog.md` v1.2 → v1.3 con §X NEW Bank Phase A appended (incluye §statebags-global-publishers sub-section).
   - `docs/technical/04_api_contracts.md` v1.2 → v1.3 con §X NEW Bank Phase A appended.
   - `docs/technical/05_state_machines.md` v1.2 → v1.3 (joint con DB Lead) con §X NEW Bank Phase A FSMs appended.
   - `docs/technical/07_bridges_compatibility.md` v1.2 → v1.3 con §X NEW Bank Phase A appended.
2. **Drafts directory archive** — este directorio renombra a `docs/agents/teams/drafts/be_phase_a_archive/` (preserva audit trail histórico).
3. **Handoff package H2** — `docs/agents/teams/handoffs/h2_backend_to_security/README.md` + `sign_off.md` creados análogos H1 pattern.
4. **SESSION_LOG entry** HANDOFF-H2 triple sign-off marcado.

---

## 6. Referencias

- Prompt activación: `@docs/agents/teams/prompts/02_backend_money_compatibility_lead.md`.
- Slice Backend: `@docs/agents/teams/slices/slice_backend.md` v1.0 LOCKED.
- Manifest: `@docs/agents/teams/00_HANDOFF_MANIFEST.md` v1.0 LOCKED.
- Brief: `@docs/agents/teams/01_SHARED_BRIEF.md` v1.0 LOCKED.
- Cross-team contracts: `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` v1.0 LOCKED.
- Handoff H1 package: `@docs/agents/teams/handoffs/h1_db_to_backend/README.md` (DB → Backend, Founder APPROVED 2026-05-06).
- Schema DB v2.0 LOCKED PROVISIONAL: `@docs/technical/03_db_schema.md`.
- Issue #001 sonar_companies: `@docs/agents/teams/issues/issue_001_sonar_companies_pending.md`.
- Workspace rules: `@.windsurf/rules/bank.md`.

---

## 7. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v0.1 DRAFT** | 2026-05-06 | BANK-BE.0 — DRAFT v0.1 inicial 3/5 contratos (C-BE-03 + C-BE-04 + C-BE-05) + ADR-018 redactado. C-BE-01 + C-BE-02 deferred BANK-BE.1. |

— **Backend Phase A DRAFT v0.1 abierto** review window 24h post BANK-BE.0 close.
