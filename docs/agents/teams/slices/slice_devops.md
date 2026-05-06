# Slice DevOps — Cherry-pick Blueprint v1.2

> **Cherry-pick blueprint para DevOps, Integration & QA Lead.**
>
> **Audiencia:** DevOps, Integration & QA Lead.
>
> **Fecha:** 2026-05-06.
> **Status:** 🟢 Locked.
> **Source canonical:** `@docs/design/proposals/03_bank_app_blueprint_v1.md` v1.2.

---

## 1. Resumen ejecutivo dominio DevOps

**Misión:** gatekeeper final Phase A. Smoke chaos engineering + multi-framework matrix testing + fxmanifest + load order spec + README install + Sprint Plan + release sub-tags + CI/CD.

**Por qué el orden 5º (último):** consumes ALL contracts LOCKED post-H1+H2+H3+H4 → ejecutas chaos test final → green-light Phase A done.

**Tu output principal Phase A:**
- `progress/SMOKE_BANK_PHASE_A_v1.md` v1.0 NEW LOCKED.
- `progress/SPRINT_PLAN_BANK_PHASE_A.md` v1.0 NEW LOCKED.
- `resources/sonar_bank_app/README.md` + `resources/sonar_bridges/README.md` extends LOCKED.
- `docs/technical/06_fivem_standards.md` extends.
- Chaos test reports + tag candidate `bank-phase-a`.

---

## 2. Cherry-pick secciones blueprint relevantes

### 2.1 Lectura prioridad ALTA

- **§5.5 Resources arquitectura + fxmanifest** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1600-1700`.
- **§6 Roadmap Phase A-E + sub-tags** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:1700-1900`.
- **§11.2 Edge Case #3 Load Order failsafe + watchdog** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2599-2664`.
- **§11.3 Convars `sv_experimental*`** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2666-2741`.
- **§11.6 Smoke chaos test mandatory** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2803-2826`.
- **§11.9.5 Greenlight + 5 bloqueadores** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2931-2942`.

### 2.2 Lectura prioridad MEDIA

- **§7.2 Scope changes Q4/Q16** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2209-2258`.
- **§5.7 Bridges Layer spec** — Core Override + Lite Mode load order críticos.

### 2.3 Lectura prioridad BAJA

- **§4 UI/UX design** — solo para entender Vite build config Frontend output.

---

## 3. Decisiones founder Q1-Q16 filtered (DevOps-relevantes)

### 3.1 Q4 — Resource separado `sonar_bank_app`

fxmanifest + load order separato. Resources ecosystem:

- `sonar_core` (existing).
- `sonar_bridges` (existing — extends).
- `sonar_bank` (existing — extends).
- `sonar_bank_app` (NEW Phase A).
- `sonar_tablet` (existing — embed Bank app icon Q6).

### 3.2 Q16 — CP4 Defensive boot pattern

3-method framework detect + watchdog 30s + KVP graceful disable + console banner. **Joint con Backend Lead.**

### 3.3 Q16 + CP7 — README install + convars

- `sv_experimentalStateBagsHandler 1`.
- `sv_experimentalNetGameEventHandler 1`.
- `sv_enableNetEventReassembly 1`.

### 3.4 Q16.4 — `sv_experimentalStateBagsHandler` mandatory recommended

Documentar README install Phase A.

### 3.5 Q16.5 — Smoke chaos test mandatory Phase A

Done criteria: lag spike injection 200ms-1s + 200 concurrent reconciliations + multi-framework matrix.

### 3.6 Q16.6 — Defer Discord webhook Phase D

Phase A: KVP + console banner suficiente.

### 3.7 Q1 — Govt mode configurable

DevOps role: validate fxmanifest dependencies + smoke test elections flow ambos modes (NPC + player elected).

---

## 4. Counter-proposals CP-relevantes filtered

| CP | DevOps Lead role |
|---|---|
| **CP1** State Bags global | **Verificar convars `sv_experimentalStateBagsHandler 1` documented README + smoke test.** |
| **CP2** Correlation-ID Mutex | **Smoke test mutex resilient lag spike injection.** |
| **CP3** Reconciliation pipeline async | **Smoke test 200 concurrent <500ms p99.** |
| **CP4** Defensive boot + watchdog | **Joint con Backend.** Smoke test 6 escenarios load order matrix (correcto / incorrecto / framework missing / ESX legacy / etc.). |
| **CP5** Threshold auto-apply | **Smoke test threshold €1000 + admin flag queue.** |
| **CP6** Reconciliation scope main only | **Smoke test premium tiers no reconciliation false positives.** |
| **CP7** README + convars | **Mandatory tu output.** README install Phase A canonical. |
| **CP8** sonar_bank_status FSM + UI badge | **Smoke test FSM transitions per scenario.** |

---

## 5. Anti-patterns DevOps-específicos prohibidos

(Per prompt §9.)

- ❌ Smoke test sin pass criteria explícit.
- ❌ Skip chaos test "porque dev test passes".
- ❌ Push tag `bank-phase-a` sin founder sign-off.
- ❌ Smoke pass con error logs critical.
- ❌ Manual testing sin scripts repeatable.
- ❌ Performance budget breach acceptance sin retest.
- ❌ fxmanifest dependencies fuzzy.
- ❌ Convars recommended sin mandatory enforce (donde aplica).
- ❌ README install incompleto.
- ❌ Sub-tag granularity collapsed (A.1-A.8 discreto).

---

## 6. Research recomendado primitivas modernas FiveM ops

(Per prompt §6.1.)

- `sv_pureLevel` — bloquea client-side mod injection.
- `sv_scriptHookAllowed 0`.
- txAdmin recovery procedures.
- Cron scheduler patterns + `sv_lan` impacts perf testing.
- Resource manager APIs runtime start/stop.
- `onResourceStart` event ordering + dependency multi-fallback.
- Network throttle simulation (tc netem / Clumsy / Network Link Conditioner).
- Infinity vs legacy OneSync.
- `mh-cpu` + `monitor` resources perf counters.

---

## 7. Open questions del dominio

| OQ | Pregunta | Recommendation Cascade PM |
|---|---|---|
| **OQ-DO-01** | Smoke matrix completeness | Cuestiona. Quizá `network_partition` + `db_outage_recovery` + `txAdmin restart`. |
| **OQ-DO-02** | Multi-framework matrix execution | Recommend Docker Compose orchestrating 4 servers diferentes (QBox / QBCore / ESX 1.10+ / ESX legacy). |
| **OQ-DO-03** | Lag spike injection tooling | Recommend `tc netem` Linux. Clumsy Windows alt. |
| **OQ-DO-04** | Watchdog 30s window adequate? | Cuestiona dual-tier 30s + 5min + 30min progressive (Security Lead OQ-SEC-07). |
| **OQ-DO-05** | Chaos test automated vs manual | Recommend automated harness Lua server-side + capture metrics. Manual sign-off final. |
| **OQ-DO-06** | CI/CD pipeline existing scope | Cuestiona. Review extends needed para Lua + JS/TS dual stack. |
| **OQ-DO-07** | Release sub-tags strategy | Recommend A.1-A.8 granularity. NO collapse. |
| **OQ-DO-08** | Discord webhook Q16.6 defer | Phase A placeholder structure README install. Phase D implements. |
| **OQ-DO-09** | Migration rollback procedure | DB Lead provided down scripts. Test rollback in chaos. |

---

## 8. Entregables esperados v1.0 LOCKED

### 8.1 SSoTs principales

- `progress/SMOKE_BANK_PHASE_A_v1.md` v1.0:
  - Smoke matrix completa (~50 tests organized en categorías Boot / Money flow / Reconciliation / Chaos / Audit / Compliance / UI).
  - Pass / Fail criteria explicit per test.
  - Performance targets explicit.
  - Multi-framework matrix scope.
  - Chaos engineering test plan (lag spike + 200 concurrent + watchdog tampering).

- `progress/SPRINT_PLAN_BANK_PHASE_A.md` v1.0:
  - Sub-tags milestones A.1-A.8.
  - Done criteria Phase A.
  - Dependencies cross-team DAG.
  - Risks + mitigations.

- README install Phase A:
  - `resources/sonar_bank_app/README.md` (NEW).
  - `resources/sonar_bridges/README.md` extends.
  - Pre-requisitos + framework matrix + cut ESX legacy + convars + load order critical + migrations apply + troubleshooting.

- `docs/technical/06_fivem_standards.md` extends — per-resource fxmanifest reviews.

### 8.2 Chaos test execution + reports

- `progress/SMOKE_BANK_PHASE_A_REPORTS_<date>.md`:
  - Multi-framework matrix results.
  - 200 concurrent reconciliation perf metrics.
  - Lag spike injection results.
  - Watchdog detection verification.

### 8.3 Release engineering

- Sub-tag `bank-phase-a` candidate + commits format `BANK-A.{M} {imperative}`.

### 8.4 Sign-off

- founder ✅
- DevOps Lead ✅ (tú)
- DB Lead ✅
- Backend Lead ✅
- Security Lead ✅
- Frontend Lead ✅

(Final cross-team validation antes Phase A done.)

---

## 9. Cross-team contracts

### 9.1 QUÉ EXIGES

- DB Lead: C-DB-01/02/03 (post-H1).
- Backend Lead: C-BE-01/02/03/04/05 (post-H2).
- Security Lead: C-SEC-01/02/03 (post-H3).
- Frontend Lead: C-FE-01/02/03 (post-H4).
- Founder: sign-off Phase A done H5 ceremony + green-light tag `bank-phase-a` candidate.

### 9.2 QUÉ ENTREGAS

- Founder: C-DO-01/02/03/04 LOCKED + chaos reports + tag candidate (post-H5).
- All Leads (post-H5): final integration validation feedback.

---

## 10. Citas blueprint canonical

- Resources arquitectura: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1600-1700`.
- Roadmap Phase A-E: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1700-1900`.
- Edge Case #3 load order: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2599-2664`.
- Convars: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2666-2741`.
- Smoke chaos mandatory: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2803-2826`.
- §11.9.5 greenlight: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2931-2942`.

---

## 11. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v1.0** | 2026-05-06 | Initial release. Cherry-pick + Q1-Q16 + CP1-CP8 + 9 OQs filtered. |

— **Slice DevOps LOCKED** post founder green-light 2026-05-06.
