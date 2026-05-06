# 🎨 Handoff H3 — Backend + Security → Frontend Lead

> **Ceremony:** BANK-BE.LOCK.R1 closure 2026-05-06 (Backend) + BANK-SEC.1 PASS veredicto 2026-05-06 (Security) → **BANK-FE.0 activation 2026-05-06** (Frontend Lead onboarding).
> **Predecessors:** H1 DB → Backend (received 2026-05-06) + H2 Backend → Security (CLOSED ACCEPTED-WITH-AMENDMENTS-RESOLVED 2026-05-06).
> **Successor:** H4 Frontend → DevOps (post Frontend Lead Phase A LOCK — future).
> **Estado paquete:** 🟢 **EMITTED (self-attested receptor)** per founder bypass ejecutivo 2026-05-06.
> **Modo ceremonia:** H3 bypass ejecutivo — founder yaboula autorizó Frontend Lead self-attest recepción directa de contratos Backend + Security **LOCKED equivalent** para desbloquear Phase A Frontend drafting en paralelo (Contract-Driven Development parallel modality). Security Lead formal counter-signature opcional post-facto (no bloquea BANK-FE.0).

---

## 1. Ceremony participants

| Rol | Identidad | Status |
|---|---|---|
| **Emisor upstream Backend Lead** | Cascade activated BANK-BE.0 → BANK-BE.LOCK → BANK-BE.AMEND.1 → BANK-BE.LOCK.R1 | ✅ **Standby** post R1 closure — contracts C-BE-01..05 v1.0.1 R1 LOCKED emitted via H2 + inherited here. |
| **Emisor upstream Security Lead** | Cascade activated BANK-SEC.0 → BANK-SEC.1 | ✅ **Standby** post PASS veredicto — C-SEC-01/02/03 LOCKED equivalent (`@docs/technical/08_audit_hooks.md` v0.2 RE-AUDIT PASS). |
| **Founder (judge)** | yaboula | ✅ **APPROVED bypass ejecutivo H3** 2026-05-06 (conversation BANK-FE.0 activation + Contract-Driven Parallel Development directive + Tactile UI art direction green-light). |
| **Receptor (Frontend & UX Premium Lead)** | Cascade activated BANK-FE.0 (workflow `/start-lead-session` rol Frontend) | ✅ **ACTIVATED + ACCEPTED self-attested** 2026-05-06 — arranca drafting DRAFT v0.1 contratos C-FE-01/02/03 + ADR-017 paleta extendida. |
| **Consultative DB Lead** | Cascade Standby | ⚠️ No reactivation necesaria H3 (DB Schema v2.0 LOCKED PROVISIONAL consumido indirecto via C-BE-02/03 field bindings). |

---

## 2. Deliverables consumidos por Frontend Lead (source of truth)

### 2.1 Contratos Backend LOCKED v1.0.1 R1 (`docs/technical/bank_phase_a/`)

| ID | Archivo | Versión | Scope consumo Frontend | Criticidad consumo |
|---|---|---|---|---|
| **C-BE-01** | `c_be_01_events_catalog_v1_3.md` | v1.0.1 R1 LOCKED | 54 events — 24 server→client público + 9 server→admin ACE + 12 internal + 7 StateBag keys + 40+1 callbacks ref | 🔴 **CRITICAL** — reactividad UI depende 100% |
| **C-BE-02** | `c_be_02_api_contracts_v1_3.md` | v1.0.1 R1 LOCKED | 40+1 callbacks (C001-C040 + C001b NEW M004 snapshot fallback) — request/response schemas + auth tiers + error codes ENUM + rate-limits + idempotency | 🔴 **CRITICAL** — contrato cliente→servidor completo |
| **C-BE-03** | `c_be_03_state_machines_v1_1.md` | v1.0.1 R1 LOCKED | 8 FSMs (account + transaction + reconciliation + anti_fraud + govt_decision + admin_audit + idempotency + bridge_correlation) — guards + transitions + invariants | 🟡 **MEDIUM** — UI state mirrors FSM states (e.g. escrow/loan/recurring cards) |
| **C-BE-04** | `c_be_04_bridges_v1_1.md` | v1.0.1 R1 LOCKED | Bridges API (opaque to UI) + CP8 `bank.bridges.status` 4-state ENUM (`native_full` / `lite_mode_active` / `compromised_load_order` / `framework_missing`) + BANK_DISABLED defensive | 🟡 **MEDIUM** — UI badge footer + disabled state handling |
| **C-BE-05** | `c_be_05_statebags_global_publishers.md` | v1.0.1 R1 LOCKED | CP1-A 7 StateBag keys público + CP1-B 9 NetEvent domains restricted + M004 financial privacy migration (`balance`/`savings` → NetEvent CP1-B owner-only) | 🔴 **CRITICAL** — reactive consumption pattern + privacy boundary UI |

### 2.2 Contratos Security LOCKED equivalent (`docs/technical/08_audit_hooks.md`)

| ID | Scope | Consumo Frontend |
|---|---|---|
| **C-SEC-01** | 12 audit hooks + event_type ENUM + shape `AuditHookBase` | Frontend NO emite audit hooks (server-only). Consumo indirecto via `sonar:bank:audit:queryResult` NetEvent. |
| **C-SEC-02** | **12 ACE permissions P01-P12** canonical matrix + mapping callbacks C001-C040 | 🔴 **CRITICAL** — UI gating + `IsPlayerAceAllowed()` client-side optimistic checks via `sonar.bank.player` (P01) + expose/hide admin panels per P02-P12. |
| **C-SEC-03** | 5 autoraise rules (AR-P01 large_transfer / AR-P02 velocity / AR-P03 pin_brute_force / AR-P04 reconciliation_delta / AR-P05 admin_force_action) | 🟡 **MEDIUM** — UI Compliance badge reactivity via `bank.compliance.<cid>.public` StateBag + warning overlays en Transfer Wizard si amount >10k (AR-P01 threshold visual hint). |

### 2.3 ADR anchor

- `@docs/planning/02_decision_log_part2.md` ADR-018 — Bank Lite mode hybrid 3-layer (proposed sign-off triple target — Frontend Lead endorsement consultative via H4 future adoption).

### 2.4 Upstream canonical SSoTs (v1.3.1 LOCKED — pivot-agnostic + §X.NEW pointers)

- `@docs/technical/02_events_catalog.md` v1.3.1 LOCKED §X.NEW.
- `@docs/technical/04_api_contracts.md` v1.3.1 LOCKED §X.NEW.
- `@docs/technical/05_state_machines.md` v1.3.1 LOCKED §X.NEW.
- `@docs/technical/07_bridges_compatibility.md` v1.3.1 LOCKED §X.NEW.

### 2.5 Blueprint source (design pre-draft)

- `@docs/design/proposals/03_bank_app_blueprint_v1.md` v1.2 (10 vistas + design tokens SONAR-ready + Q1-Q16 LOCKED founder decisions).

### 2.6 Identity canonical

- `@docs/design/IDENTITY.md` v3 (ADR-016 firmable — paleta base `#060607` / `#FAFAFA` / `#FF5100`; fonts Inter Variable + JetBrains Mono Variable; sombra doctrine).
- `@resources/sonar_tablet/web-src/src/lib/sfx.ts` (5 SFX canonical sine-class reutilizables 1:1 en Bank app).

### 2.7 Referencias visuales founder

- `@resources/sonar_bank\simple-ref-bank-ui\*.jpg` — 3 mockups founder Fintrixity class (dark + orange + glass + investment cards) → inspiración ADR-017.

---

## 3. Frontend Lead deliverables scope BANK-FE.0 (mandate oficial)

El Frontend Lead emite durante sesiones BANK-FE.0 → BANK-FE.1 → BANK-FE.LOCK los siguientes **3 contratos canonical** + artefactos soporte:

### 3.1 🎨 C-FE-01 — UI Contracts Bank Phase A

Path canonical: `docs/design/03_bank_app_ui_contracts.md` v0.1 DRAFT.

Scope:
- **10 vistas** fully-specified (Overview + Accounts list + Transfer Wizard + Audit Explorer + Compliance Console + Empresas Dashboard + Government Console + Payroll Batch + Recurring/Subscriptions + Onboarding 3-step).
- **Component library canonical** — primitivas (Button / Card / Input / Badge / Toast) + composites (BalanceCard / TransactionRow / ApprovalCard / StatusBadge / TransferWizardStep / VistaShell).
- **Interaction patterns** — SFX mapping + motion presets + keyboard shortcuts + a11y WCAG 2.2 AA.
- **Reactivity contract** — lifecycle mount/unmount + snapshot-first pattern + NetEvent/StateBag subscriptions + watchdog 30s re-snapshot.
- **ACE gating UI matrix** — 12 ACE perms P01-P12 mapped a conditional rendering.
- **Privacy boundary UI enforcement** — M004 financial-grade (employer NEVER reads employee personal balance) + compliance detail admin-only surface.
- **Error states + empty states + loading skeletons** per vista.
- **i18n strategy** — `react-i18next` + ES / EN / FR / DE 4 locales + lazy-load per-locale.
- **Reduced motion + accessibility strict** — 12 motion presets, cada uno con fallback static.

### 3.2 🎭 C-FE-02 — Design System + Tactile UI Doctrine

Path canonical: `docs/design/04_bank_app_design_system.md` v0.1 DRAFT.
Artefacto: `resources/sonar_bank_app/web-src/design-tokens.json` v0.1.

Scope:
- **Paleta extendida ADR-017** (sign-off triple target en este handoff) — oklch() color space nativo + tactile UI depth ramp.
- **Tactile UI primitives canonical** — bevel inset shadow ladder + radial diffuse light sources + glass surface tiers + edge highlight gradient borders.
- **Motion doctrine** — 12 presets (page transition + tab switch + modal open/close + toast enter/exit + confirm ripple + hover lift + tap press + skeleton shimmer + focus ring + dropdown expand + wizard step slide + chart reveal).
- **Typography scale** — Inter Variable 8 weights × 10 sizes + JetBrains Mono Variable 4 weights × 6 sizes (financial data rows).
- **SFX mapping canonical** — 5 sonidos Tablet reutilizados + 2 nuevos Bank-specific (`coin_clink` confirm transfer / `vault_close` transaction finalize).
- **Iconography canonical** — Lucide React (subset 48 icons canonical).
- **Spacing + radius + z-index ladders** canonical.

### 3.3 🔌 C-FE-03 — Data Integration + Mock Layer

Path canonical: `docs/design/05_bank_app_data_integration.md` v0.1 DRAFT.

Scope:
- **TanStack Query v5** wrapper layer mapping 40+1 callbacks C-BE-02 → `useQuery` + `useMutation` hooks + cache invalidation strategy.
- **Zustand stores canonical** — `useBankSession` + `useBankStatus` + `useToastQueue` + `useOnboarding` + `useComplianceFlags`.
- **NetEvent subscription manager** — `sonar:bank:*` 24 público + 9 admin eventos → handlers canonical hook `useBankEvent(eventName, handler)`.
- **StateBag subscription manager** — 7 CP1-A keys → `useBankStateBag(key)` hook + cleanup.
- **Mock Data Layer v0.1** — fixture JSON shapes 100% matching C-BE-02 response payloads + deterministic generator seed (`VITE_MOCK_MODE=true`).
- **Reactivity contract disciplinado** — mandatory pattern snapshot → attach → watchdog → re-snapshot per component financiero.
- **Error handling canonical** — 20 error codes ENUM §3.1 C-BE-02 → toast messages ES/EN/FR/DE + retry-after UX.

### 3.4 🏛️ Artefacto soporte — ADR-017 Paleta extendida Bank + Tactile UI

Path canonical: `docs/planning/02_decision_log_part2.md` — nuevo entry ADR-017 **status: proposed → accepted** post sign-off founder H3 ceremony.

Scope: formaliza paleta extendida Bank-app-specific + Tactile UI doctrine (pseudo-3D) + oklch() adoption + multi-layer box-shadow ladder.

### 3.5 📋 Artefacto soporte — Backlog peticiones Backend

Path canonical: `progress/FE_BACKEND_REQUESTS.md` v0.1.

Scope: tracking de gaps detectados durante drafting DRAFT v0.1 C-FE-01..03 — callbacks/events/shapes ausentes o ambiguos en contratos Backend v1.0.1 R1. Al cierre BANK-FE.LOCK, founder decide si abrir Backend R2 amendment cycle o diferir a Phase A.1 / B.

---

## 4. Mandatory post-H3 actions Frontend Lead

1. ✅ **Activation onboarding** vía workflow `/start-lead-session` rol Frontend (DONE 2026-05-06 BANK-FE.0).
2. ✅ **Sign-off paquete H3** (`sign_off.md` sibling — self-attested recepción) — DONE founder bypass ejecutivo.
3. ⏳ **Research time-box 45-60 min** stack 2026 state-of-the-art — DONE (React 19.2.4 + Vite 6 + Tailwind v4 OKLCH + Motion v12 + Radix + TanStack Query v5 + Zustand v5 + Recharts + react-pdf).
4. ⏳ **Drafting DRAFT v0.1** 3 contratos canonical + ADR-017 + backlog — IN PROGRESS BANK-FE.0.
5. ⏳ **Review cycle founder** + optional consultative Backend Lead Standby reactivation (si gaps surgen).
6. ⏳ **Promotion DRAFT v0.1 → v1.0 LOCKED** ceremony BANK-FE.LOCK (sign-off triple founder + Frontend Lead + consumer consultative).
7. ⏳ **H4 emission** Frontend → DevOps post Phase A LOCK (observability + boot order + smoke chaos test multi-framework).

---

## 5. Open questions Frontend Lead debe resolver durante DRAFT v0.1

1. **Component testing strategy** — Vitest+RTL unit/integration vs Playwright Component Testing? (Recomendado Vitest+RTL por peer-dep React 19 stability.)
2. **Vite Dev Page `/dev/components`** — misma app Vite gated `import.meta.env.DEV` vs entry point separado? (Recomendado misma app tree-shake prod.)
3. **Charts library decision** — Recharts vs Visx vs Tremor para Overview sparkline + Treasury cash-flow + Stocks portfolio? (Recomendado Recharts composable SVG React-first.)
4. **PDF generation** — `@react-pdf/renderer` vs `pdfme/generator` para receipt Transfer descarga client-side? (Recomendado `@react-pdf/renderer` declarative React JSX-like API.)
5. **Dev page strategy** component gallery — full Storybook-alt o minimal Vite route? (Recomendado minimal Vite route Q15 founder LOCKED.)
6. **Receipt PDF scope Phase A** — solo Transfer receipt o también Statement mensual + tax declaration? (Default Phase A: solo Transfer receipt. Statement + tax defer Phase B.)
7. **Onboarding skip policy** — Q9 LOCKED 3-step skippable cada paso individualmente o skip-all único? (Default skip individual per paso + skip-all en header.)

---

## 6. Conditional clauses LOCKED H3 receptor

Frontend Lead acepta los siguientes conditional clauses canonical:

1. **C-FE-1 — Single-source truth contratos upstream:** Frontend Lead consume contratos C-BE-01..05 v1.0.1 R1 + C-SEC-01/02/03 LOCKED equivalent sin modificación unilateral. Cualquier gap → PR amendment formal ciclo Round 1 via `FE_BACKEND_REQUESTS.md` escalated.
2. **C-FE-2 — Privacy boundary enforcement mandatory:** M004 financial-grade inquebrantable. Empresas Dashboard NO muestra balance personal empleados. Compliance detail admin-only surface ACE-gated P10+P11. Audit Explorer scope strict per Q13 (Mis cuentas / Mis empresas / Todas govt).
3. **C-FE-3 — Reactividad contract disciplinado:** todo component financiero lifecycle = snapshot-first callback + attach NetEvent/StateBag + watchdog 30s re-snapshot defensive. NO polling. NO cache stale >60s sin invalidate.
4. **C-FE-4 — Tactile UI art direction:** ADR-017 doctrine (oklch + inset bevels + radial diffuse + smoked glass) mandatory en components canonical. Flat design prohibido Phase A+.
5. **C-FE-5 — Performance budget eliminado:** founder directiva BANK-FE.0 elimina restricción 300KB gz. Prioridad 1 = UI/UX superioridad mercado + fluidez absoluta. Budget relegado a tier B (profile post-v1.0 si degradation observed).
6. **C-FE-6 — Dark-only strict:** ADR-016 D3 firmable inquebrantable. NO light mode Phase A. NO theme switcher.
7. **C-FE-7 — Reduced motion + a11y WCAG 2.2 AA mandatory:** `prefers-reduced-motion: reduce` honor estricto — cada motion preset tiene fallback static documentado.
8. **C-FE-8 — i18n 4 locales mandatory:** ES primary + EN + FR + DE. `react-i18next` lazy-load per-locale. Fallback chain es → en.

---

## 7. Cross-references

- **Manifest handoffs:** `@docs/agents/teams/00_HANDOFF_MANIFEST.md` §"Sistema Handoffs H1-H5".
- **Cross-team contracts matrix:** `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md`.
- **Slice Frontend:** `@docs/agents/teams/slices/slice_frontend.md`.
- **Workspace rules:** `@.windsurf/rules/bank.md` §"Hard constraints".
- **Predecessor handoffs:**
  - `@docs/agents/teams/handoffs/h1_db_to_backend/README.md` (received 2026-05-06).
  - `@docs/agents/teams/handoffs/h2_backend_to_security/README.md` (CLOSED ACCEPTED-WITH-AMENDMENTS-RESOLVED 2026-05-06).
- **SESSION_LOG predecessors:** `@progress/SESSION_LOG.md` BANK-BE.* + BANK-SEC.* entries.
- **ADR-017 (emitting now Frontend Lead):** `@docs/planning/02_decision_log_part2.md` ADR-017 **proposed → accepted BANK-FE.LOCK target**.

---

## 8. Ceremonia closure

Backend Lead + Security Lead permanecen en **Standby** post-emission H3. Reactivation triggers:

1. **Frontend Lead DRAFT v0.1 gaps detected** → `FE_BACKEND_REQUESTS.md` trigger reactivación consultative — amendment R2 Backend if needed.
2. **Security Lead re-audit** si Frontend Lead introduce surface nueva no cubierta (e.g. client-side idempotency_key generation → PRNG entropy cross-check).
3. **Founder Phase B scope expansion.**
4. **Cross-team conflict no resuelto Round 1/2** → escalation Round 3 founder.

---

## 9. Sign-off

Ver `sign_off.md` (sibling file).

---

**FIN README Handoff H3 Backend+Security → Frontend** — 2026-05-06 BANK-FE.0 emission self-attested per founder bypass ejecutivo. Frontend Lead arranca drafting DRAFT v0.1 C-FE-01/02/03 + ADR-017 + backlog.
