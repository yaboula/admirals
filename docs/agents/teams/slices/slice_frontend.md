# Slice Frontend — Cherry-pick Blueprint v1.2

> **Cherry-pick blueprint para Frontend & UX Premium Lead.**
>
> **Audiencia:** Frontend & UX Premium Lead.
>
> **Fecha:** 2026-05-06.
> **Status:** 🟢 Locked.
> **Source canonical:** `@docs/design/proposals/03_bank_app_blueprint_v1.md` v1.2.

---

## 1. Resumen ejecutivo dominio Frontend

**Misión:** Bank app NUI premium-tech identity SONAR. 10 vistas + 12 motion presets + 5 SFX canonical + Vite Dev Page + onboarding 3-step + UI badge `sonar_bank_status` + paleta extendida ADR-017.

**Por qué el orden 4º:** consumes API contracts + ACE matrix + audit hooks LOCKED post-H2/H3 → entregas UI components + design tokens + Vite dev page a DevOps post-H4.

**Tu output principal Phase A:**
- `docs/design/03_bank_app_ui_contracts.md` v1.0 NEW LOCKED.
- `resources/sonar_bank_app/web-src/design-tokens.json` LOCKED.
- ADR-017 firma ("Extended palette Bank-app-specific").
- Vite Dev Page `/dev/components` LIVE.

---

## 2. Cherry-pick secciones blueprint relevantes

### 2.1 Lectura prioridad ALTA

- **§4 UI/UX design completo** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:700-900` (aprox).
- **§4.1-§4.10 10 wireframes** — referencias deep cada vista.
- **§8 Identity preserved + ADR-017 amendment** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2243-2330`.
- **§5.6 StateBags consumed client-side** — entender qué consume reactive.

### 2.2 Lectura prioridad MEDIA

- **§3 Feature taxonomy** — para entender scope T4 100% in-scope.
- **§6 Phase D UI roadmap** — post Phase A continuation.
- **§7.2 Scope changes Q2/Q5/Q6/Q7/Q9/Q12/Q13/Q15** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2209-2258`.
- **§11.9 Founder final decision Q16 → CP8 UI badge** — `@docs/design/proposals/03_bank_app_blueprint_v1.md:2876-2942`.

### 2.3 Lectura prioridad BAJA

- **§5.1 API contracts** — solo signature consume.
- **§5.5 Resources arquitectura** — solo `sonar_bank_app/`.

---

## 3. Decisiones founder Q1-Q16 filtered (Frontend-relevantes)

### 3.1 Q1 — Govt mode configurable → Elections UI tab

UI views Phase C: Government Console adquiere "Elections tab" con candidate list + vote button + results display + term countdown.

### 3.2 Q2 — ADR-017 paleta extendida sign

Aceptar full — extended palette + gradients premium Bank-app-specific. **Tu propones spec final + sign founder.**

### 3.3 Q5 — 1440×900 centered + backdrop oscuro

Viewport + responsive constraints. NO fullscreen.

### 3.4 Q6 — Multidisparo

- Keybind `M` (configurable convar).
- `/bank` command.
- Tablet embed icon.

### 3.5 Q7 — DOM dialog 2D + CSS animations

Descarta Three.js. Visualizaciones 2D only.

### 3.6 Q9 — Onboarding 3-step skippable

- Saludo + welcome SONAR identity.
- Saldo inicial reveal.
- IBAN + QR reveal.

### 3.7 Q12 — T4 100% in-scope

10 vistas + extends Phase B/C.

### 3.8 Q13 — Audit Explorer 3 scopes UI

- Mis cuentas / Mis empresas / Todas (gated `sonar.bank.govt.audit_full` ACE).

### 3.9 Q15 — Vite Dev Page `/dev/components`

Reemplaza Storybook. Lean, no extra deps.

### 3.10 Q16.3 + CP8 — UI badge `sonar_bank_status` always visible

Footer mini Bank app sidebar. 4 states:

- 🟢 `Native` (`native_full` — Core Override active).
- 🟡 `Lite` (`lite_mode_active` — ESX 1.10+).
- 🔴 `Compromised` (`compromised_load_order` — watchdog detected).
- ⚫ `Disabled` (`framework_missing`).

Tooltip + link docs admin.

---

## 4. Counter-proposals CP-relevantes filtered

| CP | Frontend Lead role |
|---|---|
| **CP1** State Bags global | **Consumer.** Client-side `AddStateBagChangeHandler` reactive. Reemplaza `onNet` listeners para Bank state. |
| **CP2** Correlation-ID Mutex | NOT direct Frontend (Backend internal). |
| **CP3** Reconciliation pipeline async | NOT direct Frontend. UI muestra resultado via StateBag balance update. |
| **CP4** Defensive boot + watchdog | NOT direct Frontend. UI muestra status via badge CP8. |
| **CP5** Threshold auto-apply | NOT direct Frontend. Admin notification UI Phase B/C. |
| **CP6** Reconciliation scope | NOT direct Frontend. |
| **CP7** README + convars | NOT direct Frontend. |
| **CP8** sonar_bank_status FSM + UI badge | **Mandatory Frontend.** UI badge always visible 4 states + tooltip + link docs admin. |

---

## 5. Anti-patterns Frontend-específicos prohibidos

(Per prompt §9.)

- ❌ Inline styles en código React.
- ❌ Hex colors hardcoded.
- ❌ Server-side validation skipped.
- ❌ Sound calls sin debounce.
- ❌ Motion sin `prefers-reduced-motion`.
- ❌ NUI focus sin manage explícito.
- ❌ Components sin TypeScript strict types.
- ❌ `dangerouslySetInnerHTML`.
- ❌ Bundle size unbudgeted.
- ❌ i18n strings inline.
- ❌ Light mode toggle Phase A.
- ❌ Iconos custom inline SVG (Lucide bridge canonical).

---

## 6. Research recomendado primitivas modernas

(Per prompt §6.1.)

- React 18 — Suspense + transitions + useDeferredValue.
- TanStack Query.
- Zustand vs Redux.
- Framer Motion 11.
- shadcn/ui composition.
- Radix UI primitives a11y.
- Vite SWC vs Babel.
- react-window / TanStack Virtual.
- Cypress / Playwright Component testing.
- Recharts / Visx / Apache ECharts.
- PDF generation client-side (react-pdf vs html2pdf).

---

## 7. Open questions del dominio

| OQ | Pregunta | Recommendation Cascade PM |
|---|---|---|
| **OQ-FE-01** | 10 vistas o agrupar/split? | Cuestiona. Quizá Audit Explorer sub-tab History. Quizá Govt + Empresas comparten layout shell. |
| **OQ-FE-02** | Wizard 4-step Transfer fricción | Cuestiona express mode trusted destinations. |
| **OQ-FE-03** | Q11 compliance_alert visual fallback solution | Recommend StateBag privacy-safe shape (Backend Lead OQ-BE-02). |
| **OQ-FE-04** | CP8 4 states UI tooltip | Recommend `compromised` + `disabled` con CTA "Contact server admin". |
| **OQ-FE-05** | Onboarding Q9 3-step vs 4-step | Cuestiona. Quizá add "first transfer demo seguro". |
| **OQ-FE-06** | ADR-017 paleta extendida specifics | Tu spec. Sign founder. |
| **OQ-FE-07** | Performance budget bundle size | Recommend <300kb gzipped target. Code splitting per vista. |
| **OQ-FE-08** | Real-time updates StateBags vs polling | Recommend StateBags (CP1). Edge cases stale offline N/A NUI. |
| **OQ-FE-09** | Dark-only confirmation | Confirma 100% (ADR-016). |
| **OQ-FE-10** | i18n library choice | Cuestiona react-intl vs lingui vs i18next. |

---

## 8. Entregables esperados v1.0 LOCKED

### 8.1 SSoT principal

- `docs/design/03_bank_app_ui_contracts.md` v1.0 NEW:
  - Header con changelog.
  - Tabla resumen all components + paths + scope.
  - Per componente: props (TS types) + events + state + callbacks consumed + StateBags + sound + motion + a11y + edge cases + i18n + test scenarios.
  - **§inventory** — exhaustivo lista components + paths + dependencies.

### 8.2 Design Tokens

- `resources/sonar_bank_app/web-src/design-tokens.json`:
  - Color (canonical + extended ADR-017).
  - Typography.
  - Spacing.
  - Radius.
  - Motion presets (12).
  - Sound canonical (5 SFX).

### 8.3 ADR-017 firma

`docs/planning/02_decision_log.md` ADR-017 LOCKED ("Extended palette Bank-app-specific sobre ADR-016 base").

### 8.4 Vite Dev Page LIVE

`/dev/components` route Vite-served + screenshot evidence.

### 8.5 Sign-off

- founder ✅
- Frontend Lead ✅ (tú)
- Backend Lead ✅
- Security Lead ✅
- DevOps Lead ✅ (review consultative)

---

## 9. Cross-team contracts

### 9.1 QUÉ EXIGES

- Backend Lead: C-BE-01/02/05 (events + API + StateBags publishers) (post-H2).
- Security Lead: C-SEC-02 ACE matrix UI gating (post-H3).
- Founder: ADR-017 sign.

### 9.2 QUÉ ENTREGAS

- DevOps Lead: C-FE-01/02/03 + Vite build config + deploy strategy NUI (post-H4).
- Backend Lead (consumer indirect): UI feedback callback signatures gaps (review consultative DRAFT v0.1).
- Security Lead (consumer indirect): UI gating implementation feedback (review consultative).

---

## 10. Citas blueprint canonical

- UI/UX design: `@docs/design/proposals/03_bank_app_blueprint_v1.md:700-900`.
- 10 wireframes: `@docs/design/proposals/03_bank_app_blueprint_v1.md:701-895` (aprox).
- Identity + ADR-017: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2243-2330`.
- StateBags consumed: `@docs/design/proposals/03_bank_app_blueprint_v1.md:1750-1800` (aprox).
- §11.9 CP8 UI badge: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2789-2801`.

---

## 11. Versioning

| Version | Fecha | Cambios |
|---|---|---|
| **v1.0** | 2026-05-06 | Initial release. Cherry-pick + Q1-Q16 + CP1-CP8 + 10 OQs filtered. |

— **Slice Frontend LOCKED** post founder green-light 2026-05-06.
