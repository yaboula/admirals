# 🚀 Handoff H4 — Frontend Lead → DevOps, Integration & QA Lead

> **Ceremony:** Phase A coding closure 2026-05-11.
> **Trigger:** BANK-IT.1 first-light e2e Transfer ingame VERIFIED (commit `46cb90c`).
> **Estado paquete:** 🟢 **EMITTED — PM-attested (bypass ejecutivo founder)** — Frontend Lead Phase A scope completado + BANK-IT.1 first-light evidence empírica. DevOps Lead activación inmediata autorizada.

---

## 0. Cadena handoffs previa

| Handoff | Origen → Destino | Status | Fecha |
|---|---|---|---|
| **H1** | DB Lead → Backend Lead | ✅ EMITTED | 2026-05-06 (DB v2.0 LOCKED PROVISIONAL) |
| **H2** | Backend Lead → Security Lead | ✅ EMITTED + Re-audit PASS post R1 | 2026-05-06 / 2026-05-06 |
| **H3** | Security Lead → Frontend Lead | ✅ EMITTED-SELF-ATTESTED | 2026-05-06 (BANK-FE.0 activation) |
| **H4** | **Frontend Lead → DevOps Lead** | 🟢 **THIS HANDOFF** | 2026-05-11 |
| **H5** | DevOps Lead → Founder green-light | ⏳ PENDING | — |

---

## 1. Resumen ejecutivo

Frontend Lead completó scope Phase A coding + parte sustancial Phase B (Audit Explorer V4 / Compliance Console V5 / Business Dashboard V6 / Government vertical / Loans observatory / Settings / Auth Gate / Cards premium / Transfer Wizard / ATM Access Console). **El sistema arrancó por primera vez en servidor FiveM real** con first-light e2e transfer ingame ejecutado satisfactoriamente (BANK-IT.1 commit `46cb90c` 2026-05-11):

- Player ingame ejecutó transfer balance `$2,500.00 → $2,450.00`.
- Persisted `sonar_bank_accounts` con audit ledger entry.
- NUI bridge `ox_lib callback.await` ejecutó callback C006 server-side.
- 7 bugs identificados + fixed Round 1 (debug log canonical en `docs/agents/teams/debug_logs/round_1_transfer_fix_summary.md`).

DevOps Lead recibe sistema validado end-to-end Phase A core flow + ~24 frontend routes implementadas Phase A/B. Responsabilidad DevOps Lead: **convertir first-light en production-grade Phase A release candidate** vía smoke chaos engineering + multi-framework matrix + release engineering + ops documentation.

---

## 2. Deliverables consumidos por DevOps Lead

### 2.1 Contratos Frontend canonical (Phase A delivered)

| ID | Path canonical | Estado | Scope consumo DevOps |
|---|---|---|---|
| **C-FE-01** | `docs/design/03_bank_app_ui_contracts.md` | DELIVERED Phase A | UI contracts 24+ routes — smoke test surfaces |
| **C-FE-02** | `docs/design/04_bank_app_design_system.md` | DELIVERED Phase A | Design system + orange scarcity doctrine + tactile premium — visual regression smoke |
| **C-FE-03** | `docs/design/05_bank_app_data_integration.md` | DELIVERED Phase A | TanStack Query v5 wrappers + StateBag/NetEvent managers + idempotency client + canonical error handling + 30s watchdog |

### 2.2 Contratos upstream LOCKED v1.0.1 R1 inherited (H1+H2+H3 chain)

| ID | Path | Versión | Scope DevOps |
|---|---|---|---|
| **C-DB-*** | `docs/technical/03_db_schema.md` + migrations 001-034 | v2.0 LOCKED PROVISIONAL + 034 collation fix Round 1 | Verify migrations idempotency on server restart + benchmark |
| **C-BE-01** | `docs/technical/bank_phase_a/c_be_01_events_catalog_v1_3.md` | v1.0.1 R1 LOCKED | 54 events + 7 StateBag keys reactive smoke |
| **C-BE-02** | `docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md` | v1.0.1 R1 LOCKED | 40+1 callbacks integration smoke |
| **C-BE-03** | `docs/technical/bank_phase_a/c_be_03_state_machines_v1_1.md` | v1.0.1 R1 LOCKED | 8 FSMs + idempotency orphan cron PurgeOrphans 5min smoke |
| **C-BE-04** | `docs/technical/bank_phase_a/c_be_04_bridges_v1_1.md` | v1.0.1 R1 LOCKED | Bridges Core Override + Lite Mode multi-framework matrix |
| **C-BE-05** | `docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md` | v1.0.1 R1 LOCKED | CP1-A + CP1-B M004 privacy reactive smoke |
| **C-SEC-01** | `docs/technical/08_audit_hooks.md` | v0.2 RE-AUDIT PASS | 12 audit hooks runtime verification |
| **C-SEC-02** | `docs/technical/08_audit_hooks.md` §ACE | LOCKED | 12 ACE perms P01-P12 multi-role smoke |
| **C-SEC-03** | `docs/technical/08_audit_hooks.md` §autoraise | LOCKED | 5 autoraise rules AR-P01..05 smoke |

### 2.3 BANK-IT.1 first-light validation evidence

- **Debug log canonical:** `docs/agents/teams/debug_logs/round_1_transfer_fix_summary.md`.
- **Commits relevantes:**
  - `9975b30 fix(bank-app): resolve silent transfer failure` — 7 bugs Round 1 fixed.
  - `46cb90c BANK-IT.1 first-light e2e transfer milestone` — sign-off canonical.
- **Done criteria empirically verified:** FL-B01..06 (boot) + FL-N01..05 (NUI open) + FL-D01..05 (dashboard real data) + FL-T01..10 (transfer wizard e2e) per prompt #06 §4.

### 2.4 Frontend code delivered (resources/sonar_bank_app/web-src)

Routes implementadas Phase A + B:

- `/` Premium Home Dashboard (HomeBalanceGraph + HomePromoCarousel + HomeMoneyActions + HomeCardsRail).
- `/auth` Privacy Auth Gate (M004 toggle + biometric visual).
- `/cuentas` Accounts & Savings.
- `/transferir` Transfer Wizard 4-step + Express 2-step.
- `/transacciones` Transactions History with insight panel.
- `/tarjetas` Cards premium (7 designs + request banner).
- `/atm` ATM Access Console (PIN + card selector + cash gateway).
- `/recurring` Recurring transfers.
- `/creditos` Loans/Credit Observatory (read-only).
- `/auditoria` Audit Explorer V4 (ACE P03/P04 scoped).
- `/cumplimiento` Compliance Console V5 (ACE P10).
- `/empresas` Business Dashboard V6 (membership/signer auth) + Payroll Preview.
- `/tesoreria` Government Treasury.
- `/ajustes` Privacy Settings.
- Plus Government nested: census / sanctions / treasury / subsidies / reports.

### 2.5 Resources Lua delivered

- `resources/sonar_bank_app/` — server callbacks (40+ registered via `_wrap.lua` ox_lib integration), client NUI bridge, services (bootstrap / business / govt / transfer / risk_engine / tax_engine), repos (accounts / business / govt / transactions / etc), lib (auth / db / hmac / audit / idempotency).
- `resources/sonar_bridges/` — Bridges Layer adapters (bank/qbcore + identity/qbcore + notify/qb new commits Round 1).
- `resources/sonar_core/` — migrations runner + 34 migrations applied (001-034 including Round 1 collation fix).

---

## 3. DevOps Lead deliverables scope (mandate oficial)

El DevOps Lead activado vía prompt `@docs/agents/teams/prompts/05_devops_integration_qa_lead.md` emite durante sesiones BANK-DO.0 → BANK-DO.1 → BANK-DO.LOCK los siguientes artefactos canonical:

### 3.1 🧪 Smoke Chaos Matrix Phase A

Path canonical: `progress/SMOKE_BANK_PHASE_A_v1.md` v1.0 NEW.

Scope:
- ST-001..ST-055 ~50 smoke tests categorizados (boot + NUI + dashboard + transfer + audit + compliance + business + govt + ATM + recurring + cards + privacy + idempotency + chaos).
- Chaos engineering: lag spike injection, 200 concurrent transfers, framework swap mid-session, server restart mid-transaction, idempotency orphan accumulation, CP1-B StateBag race condition.
- BANK-IT.1 first-light tests ya CUMPLIDOS — DevOps Lead marca como PASS baseline + expande.

### 3.2 📋 Sprint Plan Phase A Bank closure

Path canonical: `progress/SPRINT_PLAN_BANK_PHASE_A.md` v1.0 NEW.

Scope:
- Sub-tags `bank-phase-a` candidate + version bumps + commits structured.
- Done criteria final Phase A: 100% smoke matrix PASS + multi-framework PASS + ops runbook complete + Security Lead re-audit final PASS.
- Dependency graph Phase A → Phase B planning.

### 3.3 🌐 Multi-framework matrix verification

Frameworks target:
- **QBox** (T1 native — primary platform first-light verified).
- **QBCore** (T1 — Core Override path).
- **ESX 1.10+** (T2 — Lite Mode hooks).
- **ESX legacy <1.10** (intentional FAIL — defensive abort boot CP4 verification).

DevOps Lead instala cada framework + ejecuta smoke matrix + documenta gaps.

### 3.4 📖 Documentation install + ops

- `resources/sonar_bank_app/README.md` install instructions + dependencies + convars.
- `resources/sonar_bridges/README.md` framework support matrix + adapters status.
- `docs/technical/06_fivem_standards.md` extends fxmanifest reviews per-resource.
- Troubleshooting guide common errors Round 1 patterns.

### 3.5 ⚙️ Convars runbook obligation (7 canonical post-R1)

DevOps Lead documenta + valida cada convar en server.cfg.example:

R1 hardening convars (BANK-BE.LOCK.R1):
- `sonar_status_transition_whitelist` (H002 ACE gate triple-path).
- `sonar_bank_watchdog_compromise_ratio_threshold` (M007 watchdog metric C).
- `sonar_bank_watchdog_min_sample_size` (M007 watchdog statistical floor).
- `sonar_bank_atm_hmac_secret` (M006 dual-secret rotation — min 64 hex chars mandatory — first-light Round 1 BUG 1 verified).

Pre-existing convars referenced:
- `sv_maxRateLimitResetGraceSeconds=300` (M001 rate-limit grace).
- `sonar_bank_audit_query_per_citizen_per_min=1` (M003 audit query rate-limit per CID).
- `sonar_bank_audit_query_global_per_min=10` (M003 audit query rate-limit global).

Plus mandatory FiveM convars per CP1/CP4:
- `sv_experimentalStateBagsHandler 1` (CP1 mandatory).
- `sv_experimentalNetGameEventHandler 1`.
- `sv_enableNetEventReassembly 1`.

### 3.6 🔄 CI/CD pipeline integration tests

(scope opcional Phase A — recomendado Phase B):
- GitHub Actions workflow: lint + typecheck + build NUI + Lua syntax check + migration validation.
- Integration tests automated subset smoke matrix.

---

## 4. Done criteria H4 — Bank Phase A release candidate

DevOps Lead firma sign-off Phase A cuando:

- [ ] 100% smoke matrix ST-001..ST-055 PASS o documented WAIVE con rationale.
- [ ] 3 frameworks T1 (QBox + QBCore + ESX 1.10+) PASS smoke crítico.
- [ ] ESX legacy <1.10 confirmed FAIL defensive boot (negative test).
- [ ] 7 convars runbook documented + validated.
- [ ] Install README operacional verified standalone (founder pueda follow para new server install).
- [ ] Sprint plan Phase A closure firmado.
- [ ] Sub-tag `bank-phase-a-candidate` released.
- [ ] Security Lead re-audit final pass-through PASS (consultative).
- [ ] DB Lead consultative confirmation no schema regression (migrations 001-034 idempotent).

Sign-off triple: founder + DevOps Lead + ALL Leads consultative.

---

## 5. Pre-handoff checklist (Frontend Lead responsibilities — verified)

- [x] **C-FE-01** UI Contracts delivered Phase A (24+ routes implementadas).
- [x] **C-FE-02** Design System delivered (orange scarcity doctrine ratified founder).
- [x] **C-FE-03** Data Integration delivered (TanStack Query + StateBag + NetEvent + idempotency client + watchdog).
- [x] **Privacy boundary M004** enforced (streamer mode toggle + masking helpers `src/lib/privacy.ts`).
- [x] **i18n** EN/ES bundles + helpers `useI18n()`.
- [x] **Error handling canonical** 20-code `CanonicalBankErrorCode` + `handleBankError`.
- [x] **First-light e2e Transfer ingame VERIFIED** — BANK-IT.1 commit `46cb90c`.
- [x] **7 bugs Round 1 RESOLVED** — debug log canonical archived.
- [x] **Multi-resource boot OK** — sonar_core + sonar_bridges + sonar_bank_app + sonar_tablet operational.
- [x] **ox_lib integration confirmed** — client + server fxmanifest dependencies + server.cfg.
- [x] **DB migrations 001-034 applied** — verified runtime.
- [x] **Issue #001 sonar_companies** — deferred Phase B documented.
- [x] **Issue #002 GOVT/business persistence** — ✅ closed BANK-DB.AMEND.1.
- [x] **Issue #003 backend schema drift** — ✅ closed BANK-BE.NORMALIZE.1/2.
- [x] **Workspace rule** `.windsurf/rules/bank.md` LOCKED.
- [x] **Trabajo huérfano agentes previos** committed (BANK-IT.0 catch-up `ebee39c`).

---

## 6. Open items / WAIVED para DevOps Lead awareness

| Item | Owner | Status | Notes |
|---|---|---|---|
| **M001** KVP persistence rate-limit | Backend Lead | DEFERRED Phase B | Founder + DevOps convar `sv_maxRateLimitResetGraceSeconds=300` accepted Phase A. |
| **M002 Phase B** FFI native crypto UUID | Backend Lead | DEFERRED Phase B | Multi-entropy UUID v4 actual sufficient Phase A. |
| **L001** EventSchema.validate gate | Backend Lead | DEFERRED Phase B | Low priority lint-grade. |
| **L002** Persistent admin event queue | Backend Lead | DEFERRED Phase B | Low priority. |
| **M006 Phase B** Dual-secret HMAC rotation | Security Lead | DEFERRED Phase B | Single-secret 64 hex Phase A sufficient. |
| **Issue #001** sonar_companies | DB Lead | DEFERRED Phase B | Opaque `company_id` Phase A sufficient. |
| **Cron PurgeOrphans 5min** idempotency | Backend Lead | LOCKED Phase A | DevOps verify cron schedules correctly post-restart. |
| **Multi-currency Q8** | Founder | OFF Phase A | Single currency global per founder Q8 decision. |
| **ESX legacy <1.10** | Bridges | CUT per Q16 | Defensive abort boot mandatory smoke test. |

---

## 7. Activation siguiente paso

DevOps Lead se activa en nueva sesión Cascade con:

```
Lee tu prompt activación canonical:
@d:/theBigProject/docs/agents/teams/prompts/05_devops_integration_qa_lead.md

Lee handoff package recepción H4:
@d:/theBigProject/docs/agents/teams/handoffs/h4_frontend_to_devops/README.md
@d:/theBigProject/docs/agents/teams/handoffs/h4_frontend_to_devops/sign_off.md

Aplica workflow /start-lead-session.

Modelo recomendado: Sonnet 4.6 (continuidad consistencia decisiones blueprint Bank Phase A).
```

DevOps Lead ejecutará:
1. Onboarding 10-step canonical (~60-90 min).
2. Lectura H4 + BANK-IT.1 debug log + 7 convars runbook awareness.
3. Confirmation handshake + cuestionamientos preliminares.
4. Esperar green-light founder para drafting smoke matrix + sprint plan.
5. Iterar BANK-DO.0 → BANK-DO.1 → BANK-DO.LOCK hasta Phase A done.
6. Cuando todo PASS → preparar H5 sign-off founder green-light Phase A release.

---

**EMITTED 2026-05-11 — PM-attested via Cascade Sonnet 4.6 on behalf of completed Frontend Lead Phase A scope + BANK-IT.1 first-light empirical validation. Founder yaboula green-light implícito vía decisión Handoff a DevOps Lead 2026-05-11 chat.**
