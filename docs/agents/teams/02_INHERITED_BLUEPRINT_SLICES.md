# SONAR Bank — Inherited Blueprint Slices Index v1.0

> **Mapa de cherry-picks del Blueprint v1.2** organizado per dominio Tech Lead. Cada slice apunta a las secciones canonical del blueprint relevantes para el Lead correspondiente, con resumen ejecutivo + decisiones founder filtered.
>
> **Audiencia:** los 5 Tech Leads.
>
> **Fecha:** 2026-05-06.
> **Status:** 🟢 Locked.
> **Source canonical:** `@docs/design/proposals/03_bank_app_blueprint_v1.md` v1.2 (~2950 líneas).

---

## 1. Por qué slices y no copia completa

El blueprint v1.2 tiene **~2950 líneas** densas. Pedirle a cada Tech Lead que lea todo es ineficiente y rompe el principio de **aislamiento de dominio** (M4).

**Solución CDD:** cada slice (`slices/slice_<dominio>.md`) contiene:
1. **Resumen ejecutivo** del dominio (visión + qué hay que construir).
2. **Lista cherry-pick** de secciones blueprint relevantes con citas `@path:LINE`.
3. **Decisiones founder Q1-Q16 filtered** que afectan al dominio específico.
4. **Counter-proposals CP1-CP8 filtered** asignados al dominio.
5. **Open questions adicionales del dominio** (preguntas que el Lead debe responder con autonomía profesional o escalar a founder).
6. **Anti-patterns + hard constraints específicos del dominio**.

El Lead **debe** leer:
- Manifest + Brief + este index + su slice + su prompt.
- El blueprint completo es **opcional / referencia** — solo si necesita context profundo de una sección específica.

---

## 2. Mapa de slices

| # | Slice | Lead | Secciones blueprint principales |
|---|---|---|---|
| 1 | `slices/slice_database.md` | Database & Data Integrity Lead | §3 (feature taxonomy) + §5.2 (DB schema) + §5.3 (FSMs joint Backend) + §6 (roadmap data ops) + §7.2 punto 2/4/5 (scope changes Q8/Q1/Q16) + §11 (audit Q16 reconciliation perf) |
| 2 | `slices/slice_backend.md` | Backend Money & Compatibility Lead | §3 (feature taxonomy) + §5.1 (callbacks API) + §5.3 (FSMs) + §5.4 (events) + §5.5 (resources arquitectura) + §5.6 (StateBags publishers) + §5.7 (Bridges layer) + §11 (Q16 Lite mode + 8 CP) |
| 3 | `slices/slice_security.md` | Security, Compliance & Audit Lead | §3 T3 (compliance + autoraise) + §5.5.2 (govt + ACE) + §5.8 (audit ledger inmutable) + §6 phase B (compliance roadmap) + §11.2 edge cases #1+#3 (mutex + load order) + §11.4 (escrow drain + premium accounts) |
| 4 | `slices/slice_frontend.md` | Frontend & UX Premium Lead | §4 (UI/UX design) + §4.1-§4.10 (10 wireframes) + §8 (identity preserved + ADR-017 paleta) + §5.6 (StateBags consumed client-side) + §6 phase D (UI roadmap) + §7.2 punto 4 (Govt Elections UI) + §11.9.2 CP8 (UI badge sonar_bank_status) |
| 5 | `slices/slice_devops.md` | DevOps, Integration & QA Lead | §5.5 (resources + fxmanifest) + §6 (roadmap A-E + sub-tags) + §11.2 edge case #3 (load order failsafe + watchdog) + §11.3 (convars `sv_experimental*`) + §11.6 (smoke chaos test mandatory) + §11.9.5 (greenlight + 5 bloqueadores) |

---

## 3. Resumen ejecutivo por dominio (compacto)

### 3.1 Database & Data Integrity

**Misión:** schema source-of-truth premium tiers + audit ledger inmutable + perf chaos 200 concurrent.

**Entregables esperables:**
- 15+ tablas nuevas Bank-domain (`sonar_bank_*` + `sonar_govt_*` + escrow + savings + business_treasury + crypto_wallet + audit_ledger + compliance_flags + tax_history + subsidies + loans + credit_score + recurring + sonar_bank_status).
- Partitioning strategy `sonar_bank_movements` (existing) + nuevas si > 10M rows projected.
- Indexes optimization queries reconciliation + audit + Government Console.
- Migrations files `migrations/<NNN>_*.sql` numerados secuenciales.
- Perf benchmarks doc — 200 concurrent reconciliation < 500ms p99.
- Schema doc canonical promoted `docs/technical/03_db_schema.md` v1.1 → v1.2.

### 3.2 Backend Money & Compatibility

**Misión:** Lua server-side motor financial-grade. Bridges Layer + Core Override + Lite Mode + callbacks + FSMs + StateBags global.

**Entregables esperables:**
- ~40 callbacks Bank-domain (C006-C0XX nuevos + C058-C062 elections + extends C001-C005 existentes).
- 9 FSMs (escrow + contract + dispute + loan + credit_score + election_lifecycle + recurring + sonar_bank_status + audit_status).
- Bridges Layer extends `resources/sonar_bridges/` — Core Override module (QBox/QBCore) + Lite Mode module (ESX 1.10+) + correlation-id mutex lib + reconciliation pipeline async lib.
- Resource `sonar_bank_app/` (NEW separated) — server-side business logic Bank app specific.
- Events Catalog v1.2 → v1.3 (eventos elections + transfer_complete + StateBags global publishers).
- API Contracts v1.2 → v1.3 (con auth + rate limits + idempotency + side effects detallados).
- State Machines v1.0 → v1.1 (joint con DB Lead).
- Bridges Compatibility v1.0 → v1.1 (Lite Mode + Core Override + cut ESX legacy spec).

### 3.3 Security, Compliance & Audit

**Misión:** mindset adversarial + audit ledger immutability + ACE permissions + autoraise compliance + exploit prevention.

**Entregables esperables:**
- Audit Hooks SSoT NEW `docs/technical/08_audit_hooks.md` v1.0 — todas las llamadas Backend que escriben al audit ledger documentadas.
- ACE permissions matrix — `sonar.bank.govt`, `sonar.bank.empresas.<id>`, `sonar.bank.audit.full`, `sonar.bank.admin`, etc.
- Autoraise rules canonical (5 patrones — structuring + large_transfer + late_tax + velocity + new_account_large_deposit) con thresholds + intervalos + actions.
- Exploit prevention checklist — rate limits + idempotency keys + replay attack prevention + injection sanitization + ACE checks server-side todas mutaciones.
- Audit del Backend Lead deliverables — review API contracts + FSMs por vulnerabilidades.
- Audit del DB Lead deliverables — review schema por integrity gaps + missing constraints + missing indexes audit-related.
- Watchdog Core Override compromise detection logic spec.

### 3.4 Frontend & UX Premium

**Misión:** UI/UX premium-tech identity SONAR + 10 vistas Bank app + motion 12 presets + sound canonical + ADR-017 paleta extendida.

**Entregables esperables:**
- UI Component Contracts NEW `docs/design/03_bank_app_ui_contracts.md` v1.0 — todos los component contracts (props + events + state) firmados.
- Design Tokens JSON canonical Bank app — paleta extendida ADR-017 + spacing + typography + motion + sound.
- 10 vistas wireframes refined → high-fidelity React components.
- Vite Dev Page `/dev/components` LIVE.
- Resource `sonar_bank_app/web-src/` (NEW) — React app NUI standalone.
- Storybook ALTERNATIVE descartado (Q15) → Vite dev page implementation.
- UI badge sonar_bank_status footer always visible.
- Onboarding 3-step wizard skippable.
- ADR-017 amendment proposal sign — extended palette firmada.

### 3.5 DevOps, Integration & QA

**Misión:** orchestration multi-resource + smoke chaos engineering + CI/CD + release engineering + multi-framework matrix.

**Entregables esperables:**
- Smoke Bank Phase A NEW `progress/SMOKE_BANK_PHASE_A_v1.md` — chaos test plan completo.
- fxmanifest reviews per resource — load order + dependencies + version constraints.
- README install Phase A — convars `sv_experimental*` + framework support matrix + troubleshooting.
- Sprint Plan Bank Phase A NEW `progress/SPRINT_PLAN_BANK_PHASE_A.md` v1.0 — breakdown + sub-tags + done criteria + dependencies.
- Smoke chaos test execution Phase A done criteria — lag spike injection + 200 concurrent reconciliations + multi-framework matrix (QBox + QBCore + ESX 1.10+ + ESX legacy intencional FAIL boot expected).
- Release sub-tags engineering — `bank-phase-a` candidate post H5.
- CI/CD pipeline reviews + extends si necesario.

---

## 4. Decisiones founder Q1-Q16 filtered per dominio

### 4.1 Database

- **Q1** (Govt mode) — implica 3 tablas elections (`sonar_govt_elections` + `sonar_govt_election_candidates` + `sonar_govt_votes`).
- **Q8** (Multidivisa OFF) — **eliminar** tabla `sonar_bank_currencies` propuesta + columnas `currency_code` / `fx_rate` de `sonar_bank_movements`. Single currency global.
- **Q10** (5 patrones autoraise) — `sonar_bank_compliance_flags.flag_type` ENUM con 5 valores canonical + eliminar `unusual_destination_foreign_prefix`.
- **Q12** (T4 100% in-scope) — tablas `sonar_bank_crypto_wallets` + `sonar_bank_stocks_holdings` + `sonar_bank_loans` + `sonar_bank_credit_scores` + `sonar_bank_atm_minigame_attempts` + `sonar_bank_physical_cards` + `sonar_bank_loyalty_points` + `sonar_bank_recurring_payments`.
- **Q14** (defaults agresivos config tax) — schema soporta `sonar_bank_tax_brackets` configurable.
- **CP3** (reconciliation pipeline async) — joint con Backend. Performance target 200 concurrent <500ms p99.
- **CP6** (reconciliation scope main only) — query queries excluyen `account_type IN ('savings', 'escrow', 'business_treasury', 'crypto_wallet')`.

### 4.2 Backend

- **Q1** (Govt mode configurable) — FSM `election_lifecycle` (6 states) + 5 callbacks C058-C062.
- **Q3** (C003 unlock) — implementación `getTransactions` Phase A.
- **Q11** (`transfer_complete` ACEPTAR + `compliance_alert` RECHAZAR) — pre-CP1 era TriggerClientEvent. **Post-CP1 todo migra a StateBags global native.**
- **Q12** (T4 100%) — callbacks T4 — crypto + stocks + loans + ATM + physical card + loyalty.
- **Q16** (Hybrid 3-layer) — Core Override + Lite Mode + 8 CP.
- **CP1** State Bags global mandatory.
- **CP2** Correlation-ID Mutex (path #1 only, NO hash-fallback).
- **CP3** Reconciliation pipeline async (joint con DB).
- **CP4** Defensive boot + watchdog (joint con DevOps).
- **CP5** Threshold auto-apply €1000.
- **CP6** Reconciliation scope main only.
- **CP8** FSM `sonar_bank_status` (4 states).

### 4.3 Security

- **Q10** (5 patrones autoraise) — define rules canonical + thresholds + actions + audit log entries.
- **Q11** (`compliance_alert` RECHAZAR como evento → visual fallback only) — UI no recibe push event, sino badge derivado de query estado compliance flags.
- **Q13** (Audit Explorer 3 scopes) — define ACE permissions matrix.
- **Q14** (defaults config tax) — review thresholds compliance no colisionen con tax brackets.
- **CP4** Defensive boot + watchdog (audit del watchdog logic by Security).
- **CP5** Threshold auto-apply €1000 (define audit log entries para deltas + admin flag queue).
- **Q16.6** Defer Discord webhook Phase D.

### 4.4 Frontend

- **Q2** (ADR-017 paleta extendida) — sign amendment + design tokens.
- **Q5** (1440×900 centered) — viewport + responsive constraints.
- **Q6** (Multidisparo) — keybind `M` + `/bank` + Tablet embed icon.
- **Q7** (DOM dialog 2D) — descarta Three.js. Sólo CSS animations.
- **Q9** (Onboarding 3-step skippable) — wizard component.
- **Q12** (T4 100%) — 10 vistas Bank app + extends Phase B/C.
- **Q13** (Audit Explorer 3 scopes) — UI scoping.
- **Q15** (Vite Dev Page) — `/dev/components` route.
- **CP8** UI badge `sonar_bank_status` (4 states visual representations).
- **Q16.3** UI status badge **always visible** footer mini Bank app sidebar.

### 4.5 DevOps

- **Q4** (Resource separado `sonar_bank_app`) — fxmanifest + load order separato.
- **CP4** Defensive boot pattern (joint con Backend) — 3-method framework detect.
- **CP7** README install + convars `sv_experimentalStateBagsHandler 1` + `sv_experimentalNetGameEventHandler 1` + `sv_enableNetEventReassembly 1`.
- **Q16.4** `sv_experimentalStateBagsHandler` mandatory recommended README.
- **Q16.5** Smoke chaos test mandatory Phase A done criteria — lag spike injection 200ms-1s + 200 concurrent + multi-framework matrix.
- **Q16.6** Defer Discord webhook Phase D.

---

## 5. Cómo navegar tu slice

Cada slice tiene esta estructura estándar:

```markdown
# Slice [DOMINIO] — Cherry-pick Blueprint v1.2

## 1. Resumen ejecutivo dominio
## 2. Cherry-pick secciones blueprint
## 3. Decisiones founder Q-relevantes filtered
## 4. Counter-proposals CP-relevantes filtered
## 5. Anti-patterns + hard constraints específicos
## 6. Research recomendado primitivas modernas FiveM
## 7. Open questions del dominio (responder con autonomía o escalar)
## 8. Entregables esperados v1.0 LOCKED
## 9. Cross-team contracts (qué exiges + qué entregas)
## 10. Citas blueprint canonical
```

**Tip de productividad:** lee tu slice **2 veces** antes de tocar nada. La primera vez para overview. La segunda vez con mindset crítico — buscando qué cuestionar (M2 mandato Autonomía).

---

## 6. Referencias compartidas (todos los Leads consultan)

- `@docs/design/proposals/03_bank_app_blueprint_v1.md` — blueprint v1.2 source canonical.
- `@docs/agents/teams/00_HANDOFF_MANIFEST.md` — manifest v1.0.
- `@docs/agents/teams/01_SHARED_BRIEF.md` — brief compartido v1.0.
- `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` — matriz contratos cruzados + RACI.
- `@docs/00_PRODUCT_BIBLE.md` — filosofía proyecto.
- `@docs/economy/01_economic_model.md` — números económicos canonical.
- `@docs/planning/02_decision_log.md` — ADRs históricos.
- `@MEMORY[admirals.md]` — workspace rules.
- `@progress/SESSION_LOG.md` — últimas 5 entries (BANK-DESIGN.0 → BANK-DESIGN.2 + handoffs).

---

## 7. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v1.0** | 2026-05-06 | Initial release. 5 slices indexed + Q1-Q16 filtered per dominio. |

— **Slices Index LOCKED** post founder green-light 2026-05-06.
