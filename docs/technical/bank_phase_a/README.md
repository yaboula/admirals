# 🏦 SONAR Bank — Phase A Backend Contracts (LOCKED)

> **Estado:** Bank Phase A Backend Contracts v1.0 LOCKED.
> **Sesión promotion:** BANK-BE.LOCK 2026-05-06.
> **Backend Lead AI:** Cascade activated as Backend Money & Compatibility Lead (sessions BANK-BE.0 → BANK-BE.1 → BANK-BE.LOCK).
> **Founder:** yaboula APPROVED (sign-off triple ratified).

---

## 0. Propósito

Esta carpeta contiene los **5 contratos canonical Backend Phase A** del proyecto SONAR Bank, promovidos atómicamente desde `docs/agents/teams/drafts/be_phase_a/` (now removed) durante la ceremonia **BANK-BE.LOCK** del 2026-05-06.

Estos contratos extienden los SSoTs canonical SONAR existentes (`02_events_catalog.md`, `04_api_contracts.md`, `05_state_machines.md`, `07_bridges_compatibility.md`) con la **especificación financial-grade Bank-specific** sin tocar el contenido foundational pivot-agnostic de los SSoTs padre. Cada SSoT padre v1.2 → v1.3 LOCKED añade un §X.NEW pointer apuntando a este directorio.

---

## 1. Inventario de contratos LOCKED

| ID | Título | Archivo canonical | Versión | Owner | Consumers |
|---|---|---|---|---|---|
| **C-BE-01** | Events Catalog Bank Phase A | `c_be_01_events_catalog_v1_3.md` | **v1.0 LOCKED** | Backend Lead | Frontend (H4) + Security (H2) |
| **C-BE-02** | API Contracts Bank Phase A | `c_be_02_api_contracts_v1_3.md` | **v1.0 LOCKED** | Backend Lead | Security (H2) + Frontend (H4) |
| **C-BE-03** | State Machines Bank Phase A | `c_be_03_state_machines_v1_1.md` | **v1.0 LOCKED** | Backend + DB joint | Frontend (H4) + Security (H2) |
| **C-BE-04** | Bridges Compatibility Bank Phase A | `c_be_04_bridges_v1_1.md` | **v1.0 LOCKED** | Backend Lead | Security (H2) + DevOps (H4) |
| **C-BE-05** | StateBags Global Publishers | `c_be_05_statebags_global_publishers.md` | **v1.0 LOCKED** | Backend Lead | Frontend (H4) + Security (H2) |

**Anexo:** `research_notes.md` — notas FiveM primitives modernos (StateBags, routing buckets, ResourceKvp, watchdog timing) usadas durante drafting BANK-BE.0/BANK-BE.1.

---

## 2. Sumario contenido por contrato

### C-BE-01 — Events Catalog v1.3 (51 events catalogados)
- 22 server→client público + 8 server→admin ACE-checked + 12 resource-internal + 9 StateBag keys consumed.
- Tier classification (T0/T1/T2/T3) + privacy classification (public/restricted/admin-only) + naming conventions canonical `sonar_bank:*` post-Phase-8.
- Schema versioning + cross-references C-BE-02 callbacks + audit observability hooks.

### C-BE-02 — API Contracts v1.3 (40 callbacks C001-C040)
- Framework §1-§7: philosophy + 4 auth tiers + ACE permission matrix + error codes registry (~30 codes) + rate-limit token bucket + idempotency keys persistent + side effects taxonomy + perf budgets.
- 40 callbacks fully specified §9.1-§9.40 con auth/rate-limit/idempotency/side-effects/error-codes/perf/test-scenarios per callback.

### C-BE-03 — State Machines v1.1 (8 FSMs joint Backend+DB)
- account_lifecycle + transaction_lifecycle + reconciliation_correlation + anti_fraud_review + government_decision + admin_audit_action + api_idempotency_lifecycle + bridge_correlation_mutex.
- States + transitions + guards + actions + persistence patterns + recovery strategies + testing matrix + anti-patterns.

### C-BE-04 — Bridges Compatibility Layer v1.1
- Architectural principles (Bridges trust boundary + Core Override QBox/QBCore + Lite Mode ESX 1.10+ triple-layer hybrid).
- Resource topology + boot sequence (CP4 defensive boot + watchdog) + Bridges API extensions + correlation-id mutex lib (CP2) + reconciliation pipeline async (CP3) + cut ESX legacy.
- ADR-018 anchor reference.

### C-BE-05 — StateBags Global Publishers
- CP1 redefinido sub-tracks A (public StateBags global native) + B (restricted via discrete NetEvents).
- 7 public bags + 7 restricted NetEvent domains + lifecycle management + performance budgets + security threat mitigations + naming conventions.

---

## 3. Sign-off matrix consolidado

| Contrato | Founder | Backend Lead | Consumer Lead 1 | Consumer Lead 2 |
|---|---|---|---|---|
| C-BE-01 | ✅ APPROVED | ✅ self-attested | ⏳ Frontend H4 future | ⏳ Security H2 cycling |
| C-BE-02 | ✅ APPROVED | ✅ self-attested | ⏳ Security H2 cycling | ⏳ Frontend H4 future |
| C-BE-03 | ✅ APPROVED | ✅ self-attested | ⚠️ DB Lead deferred (Standby reactivation post-H2) | ⏳ Frontend H4 future |
| C-BE-04 | ✅ APPROVED | ✅ self-attested | ⏳ Security H2 cycling | ⏳ DevOps H4 future |
| C-BE-05 | ✅ APPROVED | ✅ self-attested | ⏳ Frontend H4 future | ⏳ Security H2 cycling |

**Nota:** Los contratos están LOCKED v1.0 con sign-off founder + Backend Lead suficiente para promotion. Consumer Leads endorse vía handoffs futuros (H2 Security primero, H3-H4 Frontend/DevOps después). Amendments post-LOCKED requieren formal Round 1/2/3 protocol per `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` §amendments.

---

## 4. Cross-references upstream

- **Pivot SSoTs canonical (v1.2 → v1.3 LOCKED):**
  - `@docs/technical/02_events_catalog.md` → §X.NEW Bank Phase A pointer.
  - `@docs/technical/04_api_contracts.md` → §X.NEW Bank Phase A pointer.
  - `@docs/technical/05_state_machines.md` → §X.NEW Bank Phase A pointer.
  - `@docs/technical/07_bridges_compatibility.md` → §X.NEW Bank Phase A pointer.

- **DB Schema upstream:** `@docs/technical/03_db_schema.md` v2.0 LOCKED PROVISIONAL (DB Lead Phase A delivered via H1).
- **ADR anchor:** `@docs/planning/02_decision_log_part2.md` ADR-018 (Bank Lite mode hybrid 3-layer architecture).
- **Cross-team contracts matrix:** `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md`.
- **Handoffs:**
  - `@docs/agents/teams/handoffs/h1_db_to_backend/` (H1 received 2026-05-06).
  - `@docs/agents/teams/handoffs/h2_backend_to_security/` (H2 emitted 2026-05-06 — see this package for audit scope).

---

## 5. Promotion lineage (audit trail)

```
2026-05-06 BANK-BE.0 onboarding + research + drafts skeleton (5 contratos drafted).
2026-05-06 BANK-BE.1 drafts completion (51 events + 40 callbacks fully specified).
2026-05-06 BANK-BE.LOCK ceremony promotion atomic:
            drafts/be_phase_a/c_be_*  →  technical/bank_phase_a/c_be_*  (git mv, history preserved)
            v0.1 DRAFT  →  v1.0 LOCKED (sign-off triple ratified founder + Backend Lead)
            §X.NEW pointers appended a 4 SSoTs canonical (v1.2 → v1.3 LOCKED)
            H2 handoff package emitted to Security Lead.
```

---

## 6. Backend Lead Standby reactivation triggers

Post-LOCK, Backend Lead transitiona a **Standby**. Reactivation triggers formal:

1. **Security Lead post-H2 audit concern** → audit findings require contract amendment.
2. **Frontend Lead post-H4 implementación** → API gap discovered durante UI integration.
3. **DevOps Lead post-H4** → observability/boot order issue affecting Bridges.
4. **Founder Phase B scope expansion** → new Bank features require contract extension.
5. **Cross-team conflict no resuelto Round 1/2** → escalation Round 3 founder.

---

**FIN README `docs/technical/bank_phase_a/`** — Bank Phase A Backend Contracts v1.0 LOCKED.
