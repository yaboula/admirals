# `02_decision_log_part2.md` — Decision Log SONAR (continuación)

> **Este documento es la continuación directa de** `@docs/planning/02_decision_log.md` v1.5.
> El log original alcanzó ~1404 líneas tras ADR-015 + meta secciones. Para mantener navegabilidad, diff-friendly edits y reducir tiempo de búsqueda en sesiones AI, se splittea en `part2` desde **ADR-016** en adelante.
>
> **Lectura obligatoria antes de añadir ADR aquí:**
> - `@docs/planning/02_decision_log.md` §1 (formato ADR estándar).
> - `@docs/planning/02_decision_log.md` §3 (workflow add nuevo ADR).
> - `@docs/planning/02_decision_log.md` §4 (anti-patterns ADR).
>
> **NO editar `02_decision_log.md` v1.5** — append-only inviolable per ADR-007 lifecycle. Toda decisión nueva (ADR-016+) vive aquí.
>
> **Numeración continua:** ADR-016 sigue inmediatamente a ADR-015 sin reset. Cuando este `part2` alcance ~1000 líneas, splittear en `part3` análogamente.

---

## Meta

- **Versión:** 1.0 (firmado — primer ADR registrado: ADR-016).
- **Documento padre:** `@docs/planning/02_decision_log.md` v1.5.
- **Lifecycle:** living document, append-only.
- **Próxima revisión:** post-Sprint 2 close retro (re-evaluation trigger ADR-016 D3 + Tailwind v4 stable).

---

## 2. ADRs (continuación desde ADR-016)

### ADR-016 — SONAR Identity v3 firmable + doctrine palette/dark/stack/perf locked

- **ID:** ADR-016
- **Título:** SONAR Identity v3 firmable + doctrine palette/dark/stack/perf locked (amends ADR-011 + ADR-012)
- **Fecha:** 2026-05-04
- **Estado:** ✅ accepted (founder + Cascade — S1.10 EXTENDED post-commit)
- **Tags:** `identity`, `branding`, `aesthetic`, `palette`, `dark_mode`, `trend_stack`, `nui_perf`, `stack_frozen`, `amendment`, `foundational`
- **Relación:** **amends** ADR-011 (strategic identity pivot) + ADR-012 (identity refinement). NO supersede — capa adicional doctrinal sobre identity v2.

#### Context

- ADR-011 estableció el pivot estratégico Admirals → SONAR (radical rebrand + aesthetic overhaul, naval Almirantazgo → submarino nuclear / abyssal exploration).
- ADR-012 refinó la identity con 4 decisiones founder D1-D4 (abstract metaphor + hybrid theme + neutral voice + dark dominante post evaluación briefs).
- Sprint 1.10 EXTENDED (post-S1.10 commit) entregó **logo v3 firmable** (4 monogramas SVG `s_filled` / `s_outline` / `s_outline_orange` / `s_black` + 3 wordmarks SVG `mono` / `duo` / `outline_duo`), brief `@docs/art/branding/01_brief_logo.md` v2 y tooling export `@art/tools/logo_export/export.mjs`.
- Founder evaluación post-export detectó **6 decisiones doctrinales pendientes** que afectan stack Tablet UI, producción de assets futuros, y performance NUI:
  1. Tokens exactos de paleta v3 (hex codes canónicos).
  2. Política dark-mode product (¿permite light variant?).
  3. Cantidad máxima de colores en producto (¿3 strict o accents semánticos OK?).
  4. Stack tecnológico tendencia 2026 (qué adoptamos T1/T2/T3).
  5. Tablet UI stack frozen vs flexible per-sprint.
  6. NUI performance budgets concretos (FPS, paint, memoria).
- Sin ADR firmado: Sprint 2 (Tablet UI build) arrancaría con ambigüedad palette/stack/perf — riesgo decisiones improvisadas mid-sprint que contradicen identity v3 firmada.
- Founder resolvió las 6 vía decisión ejecutiva en sesión actual.

#### Decision

**6 decisiones founder D1-D6 firmadas en bloque (todas accepted):**

##### D1 — Paleta v3 locked (3 tokens canónicos)

- **Black (background base):** `#060607`
- **Orange (signal / brand primary):** `#FF5100`
- **White (foreground / pure):** `#FAFAFA`
- **SSoT canonical:** `@docs/art/branding/01_brief_logo.md` v2 §3 (palette tokens).
- **Implementación:** Tailwind v4 `@theme` directive + CSS custom properties. NO hardcodear hex en componentes — siempre via token (`bg-sonar-black`, `text-sonar-orange`, `text-sonar-white`).

##### D2 — Dark-mode-only doctrine (product)

- **Tablet UI (in-game NUI):** dark-only. NO toggle light/dark. NO media query `prefers-color-scheme: light` honor.
- **Marketing web (futuro):** dark-only consistent con product.
- **Excepción única:** `monogram_s_black.svg` permanece como variante print/external (impresión papelería, fondos blancos third-party donde dark monogram es ilegible). NO uso en product UI. Resolución per **D-S1.10E-A** (sesión actual).
- **Justificación:** identity v2 (ADR-012 D4) ya estableció dark dominante 60% canvas. v3 endurece a 100% product + excepción print única.

##### D3 — 3-color strict (no accent colors)

- **Producto NO añade** colores adicionales (no green success, no red error, no yellow warning, no blue info). Estados se comunican via:
  - Iconografía Lucide (e.g., `<CheckCircle2/>` success, `<AlertTriangle/>` warning).
  - Typography weight + opacity.
  - Layout / motion (e.g., shake on error, fade-in on success).
  - Orange como único accent semántico (CTAs, alerts críticos, signal active).
- **Re-evaluable:** post-MVP S2 close retro. Si UX research / playtesting reveals friccion semantic genuine → ADR-XXX 4ª color (probablemente red `#E63946` o similar) firmable.
- **Mitigación riesgo:** Sprint 2 design system docs explicitarán patterns no-color para estados (icon + motion).

##### D4 — Trend stack 2026 tiered (T1/T2/T3)

Stack tecnológico classification para adopción priorizada:

- **T1 (oficial, adopt now):** React 18.3 + Vite 5 + TypeScript strict + Tailwind v4 (`@theme`) + shadcn/ui (dark-only variant) + Framer Motion 11 + Lucide React + Recharts + lb-phone NUI bridge + ox_lib.
- **T2 (compat, support):** ESX legacy bridge, QBCore bridge — vía `@resources/sonar_bridges/adapters/*` (per ADR-009). NO frontend stack changes — adapters server-side only.
- **T3 (eval, defer):** React 19 stable, Tailwind 5 (cuando exista), Bun runtime, htmx — evaluar post-Oleada 1 close.

##### D5 — Tablet UI stack frozen Sprint 2 onwards

Stack **inmutable** durante Sprint 2-8 (Oleada 1 completa):

- **Framework:** React 18.3 (NO React 19 durante S2 aunque ship stable mid-sprint).
- **Build:** Vite 5 (pin `^5.0.0` package.json, NO Vite 6 hasta post-Oleada 1).
- **Lang:** TypeScript strict mode (`"strict": true` tsconfig) + `noUncheckedIndexedAccess: true`.
- **Styling:** Tailwind CSS v4 con `@theme` directive (NO v3 fallback). Tokens en `tailwind.config.ts` referenciando D1 paleta.
- **Components:** shadcn/ui (CLI install per-component, dark-only variant baseline).
- **Motion:** Framer Motion 11.
- **Icons:** Lucide React (NO emoji, NO custom SVG salvo brand assets `@art/branding/logo_v3/*`).
- **Charts:** Recharts (sólo si Tablet apps requieren visualización data — Bank app candidato S3).
- **State:** React Context + `useReducer` Sprint 2 (NO Zustand / Redux salvo gap real S3+).
- **NUI Bridge:** lb-phone NUI message API per `@resources/admirals_tablet/*` setup S0.

**Cambios stack durante S2-S8 → ADR firmable obligatorio.**

##### D6 — NUI performance hard constraints

Budgets de obligatorio cumplimiento cliente FiveM (60 FPS target):

- **Frame budget Tablet UI:** ≤ 4ms paint per frame (target 60 FPS = 16.67ms total budget; 75% reservado al juego).
- **Bundle size production:** ≤ 500KB JS gzipped (initial load), ≤ 200KB CSS gzipped.
- **Memory ceiling NUI:** ≤ 80MB heap (Chrome devtools profile).
- **Lazy-loading obligatorio:** rutas Tablet apps (Bank, Map, Phone) via `React.lazy()` + Suspense. Initial bundle = shell + Home only.
- **Animaciones:** GPU-only (`transform`, `opacity`). Prohibido animar `width/height/top/left/margin/padding`.
- **Re-render guard:** componentes lista (transactions, contacts) MUST `React.memo` + virtualization si >50 items (react-window).
- **Asset budget:** brand SVGs ≤ 8KB cada uno (verificable export tool `@art/tools/logo_export/export.mjs` warn threshold).
- **Performance test:** Sprint 2 setup incluye Chrome DevTools Performance profile baseline + regression check pre-merge cualquier PR Tablet UI.

#### Alternatives considered

- **A) Defer doctrine completa a Sprint 2 kickoff** — rejected. Velocity S2 sufrirá ambigüedad palette/stack/perf. Founder decisión ejecutiva ahora elimina friccion S2 día-1.
- **B) Permitir light variant Tablet UI opt-in** — rejected. Dark-only es identity core ADR-011 §4 + ADR-012 D4. Variant doblaría design system effort 2x sin payoff identidad.
- **C) Stack más conservador (Tailwind 3 + sin Framer + CSS modules)** — rejected. Founder D4 trend stack 2026 explicit requiere bleeding-edge. Conservatismo perdería competitive edge T1 servers FiveM premium.
- **D) Permitir 4ª color semantic (red error) desde S2** — deferred (NO rejected). D3 strict ahora; re-evaluable post-MVP si UX research justifica.
- **E) Dejar perf budgets soft / orientativos** — rejected. NUI bad-perf = perceptible-laggy game = identity premium broken. Hard constraints obligatorias.
- **F) React 19 + Vite 6 directo** — rejected (T3 defer per D4). Riesgo breaking changes durante sprint cost > beneficio.

#### Consequences

##### Positivas

- **Sprint 2 day-1 unblocked:** palette + stack + perf locked → setup tasks deterministas (`pnpm create vite`, `tailwind init`, shadcn CLI, install Framer/Lucide/Recharts).
- **Brief logo v2 §3 = SSoT canonical** para tokens. Refs cruzadas en Tablet `tailwind.config.ts`, design system docs, futuras marketing pages — one-source-of-truth.
- **Identity v3 → product v3 trazabilidad completa:** logo v3 firmable + paleta locked + dark-only doctrine + stack frozen → product visual ships consistent con brand.
- **NUI perf budgets D6 = guard rail S2** evita anti-patterns (paint thrash, bundle bloat, memory leaks) que históricamente killean Tablets FiveM premium en server stress test.
- **3-color strict D3 simplifica design system** — menos tokens, decisiones diseño rápidas, training nuevos contributors trivial.
- **Stack frozen D5 elimina indecision parálisis** durante S2 (no time wasted evaluating React 19 vs 18 mid-sprint).

##### Negativas

- **Tailwind v4 (`@theme` directive) es bleeding-edge** — riesgo breaking changes pre-stable release. Mitigación: pin exact version package.json S2 setup + CI dependency-lock.
- **React 18.3 frozen ahora** — si React 19 stable durante S2 con perf wins, no upgrade durante sprint. Mitigación: post-S2 close retro evaluation explicit.
- **3-color strict friccion UX semantic posible S2** — si playtesting reveals users miss colored error states. Mitigación: D3 explicit re-evaluable post-MVP S2.
- **Framer Motion 11 bundle cost** — ~30KB gzipped añadido. Mitigación: D6 budget `≤ 500KB` ya account; tree-shaking + lazy import.
- **shadcn/ui dark-only variant requiere customization manual** — cada componente install via CLI necesita override theme tokens D1. Effort upfront S2 setup.

##### Neutrales

- **`monogram_s_black.svg` preservado** (D-S1.10E-A) — print/external OK pero NO product UI. Cero impacto Tablet S2.
- **Recharts opcional D5** — solo Bank app S3 usará initial. Sprint 2 (Tablet shell + Home) NO necesita charts.

#### Risks accepted by founder

- 🟢 **R1 — Tailwind v4 inestabilidad bleeding-edge.** Probability: media. Impact: refactor `@theme` syntax si cambia pre-stable. Mitigación: pin version + monitor changelog weekly + alternativa Tailwind v3 LTS rollback path documentado en S2 setup.
- 🟢 **R2 — Framer Motion 11 bundle size cost.** Probability: alta (cost real ~30KB). Impact: bajo (D6 budget ≤500KB account). Mitigación: lazy import + tree-shaking + benchmark Sprint 2 Day 5 baseline.
- 🟡 **R3 — D3 3-color strict friccion UX semántica posible S2.** Probability: media. Impact: medio (UX confusion si users no detect error states). Mitigación: D3 explicit re-evaluable post-MVP + Sprint 2 design system docs explicitarán patterns icon+motion no-color para estados.
- 🟢 **R4 — React 19 stable durante S2 con perf wins missed.** Probability: media. Impact: bajo (S2 = 4 semanas, post-S2 retro evaluation OK). Mitigación: D5 frozen explicit + post-Oleada 1 evaluation T3 D4.
- 🟢 **R5 — D6 perf budgets too strict Sprint 2 features.** Probability: baja. Impact: medio (refactor mid-sprint si Bank app S3 requiere ≥80MB heap). Mitigación: D6 budgets revisable post-S2 retro con datos reales profile.

#### Impact

##### Docs (esta sesión)

- ✅ `@docs/planning/02_decision_log_part2.md` — ADR-016 (este archivo continuación, primer ADR registrado).
- ✅ `@docs/planning/02_decision_log.md` — pointer continuación añadido §8 + bump v1.5 → v1.5.1.
- ✅ `@progress/SESSION_LOG.md` — entry session current referencia ADR-016 (per playbook §5.3).

##### Docs (próxima sesión / Sprint 2 setup)

- 🟡 `@docs/art/01_art_direction.md` — verificar gap vs identity v3 doctrine D1+D2+D3 (si menciona paleta vieja Admirals naval → update con SSoT brief logo v2 §3).
- 🟡 `@progress/SPRINT_PLAN_S2.md` — Sprint 2 setup tasks deben incluir D5 stack install + D6 perf budgets en done criteria + design system D3 patterns docs.
- 🟡 `@docs/agents/00_BOOTSTRAP.md` — añadir referencia ADR-016 §SSoTs canónicos para que AI sessions futuras carguen doctrina v3 día-1.
- 🟡 `@docs/technical/06_fivem_standards.md` — cross-link D6 NUI perf budgets como standard FiveM client-side.

##### Code (Sprint 2)

- 🟡 `@resources/admirals_tablet/web-src/package.json` — pin versions per D5 (React 18.3, Vite 5.x, Tailwind v4, Framer 11, Lucide React latest).
- 🟡 `@resources/admirals_tablet/web-src/tailwind.config.ts` — `@theme` directive con tokens D1 paleta.
- 🟡 `@resources/admirals_tablet/web-src/src/styles/globals.css` — CSS custom properties + dark-only baseline.

#### Re-evaluation trigger

- **Post-MVP S2 close retro:** D3 3-color strict friccion observed durante playtesting? Si sí → ADR-XXX 4ª color semantic (probable red `#E63946`).
- **Tailwind v4 stable release:** si breaking changes pre-stable afectan `@theme` directive → ADR-XXX hotfix path (downgrade v3 LTS o adapt syntax).
- **React 19 stable + S2 close:** evaluate upgrade post-sprint con benchmarks (no during S2 per D5).
- **Sprint 2 Day 5 perf baseline:** si D6 budgets unrealistic vs primer feature ship → ADR-XXX revisable budgets con datos profile reales.
- **Marketing web build (post-Oleada 1):** validar dark-only doctrine D2 sostenible vs SEO/landing conversion (si data muestra friccion → potential ADR future allowing light variant marketing solo, NO product).

---

## 5. Búsqueda ADRs (delta part2)

### 5.1 Tags nuevos introducidos en part2

Tags introducidos por primera vez en `part2` (no presentes en `02_decision_log.md` v1.5):

| Tag | ADRs | Notas |
|---|---|---|
| `palette` | ADR-016 | Tokens hex canónicos (D1). |
| `dark_mode` | ADR-016 | Doctrine product (D2). |
| `trend_stack` | ADR-016 | Tier system T1/T2/T3 (D4). |
| `nui_perf` | ADR-016 | Performance budgets (D6). |
| `stack_frozen` | ADR-016 | Tablet UI stack inmutable (D5). |

Tags reutilizados desde `02_decision_log.md` v1.5:

| Tag | ADRs (part2) | ADRs (padre v1.5) |
|---|---|---|
| `identity` | ADR-016 | ADR-011, ADR-012, ADR-013 |
| `branding` | ADR-016 | ADR-011, ADR-012 |
| `aesthetic` | ADR-016 | ADR-011, ADR-012 |
| `amendment` | ADR-016 | ADR-012, ADR-015 |
| `foundational` | ADR-016 | ADR-002, ADR-003, ADR-009, ADR-010, ADR-011, ADR-013 |

### 5.2 Estado ADRs part2

| Estado | ADRs (part2) |
|---|---|
| accepted | ADR-016 |
| proposed | — |
| deprecated | — |
| superseded | — |

---

## 6. Estado documento

### 6.1 Roadmap part2

- 🔄 Continúa filosofía ADR del documento padre.
- 🔄 Cada decisión importante = nuevo ADR aquí (ADR-016+).
- 🔄 Splittear `part3` cuando supere ~1000 líneas.

### 6.2 Changelog part2

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-04 | Founder + Cascade (S1.10 EXTENDED post-commit) | Creación archivo continuación. **+1 ADR** ADR-016 (SONAR Identity v3 firmable + doctrine palette/dark/stack/perf locked, amends ADR-011 + ADR-012). 6 decisiones founder D1-D6 firmadas. Pointer cruzado añadido al padre `02_decision_log.md` v1.5 → v1.5.1. |

---

## 7. TL;DR — ADRs registrados en part2

| ID | Título | Estado | Tags |
|---|---|---|---|
| **ADR-016** | SONAR Identity v3 firmable + doctrine palette/dark/stack/perf locked (amends ADR-011 + ADR-012) | ✅ accepted | identity, branding, aesthetic, palette, dark_mode, trend_stack, nui_perf, stack_frozen, amendment, foundational |
| **ADR-017** | SONAR Bank paleta extendida + Tactile UI pseudo-3D doctrine + oklch() + premium glassmorphism + stack 2026 absolute (extends ADR-016) | 🟡 proposed (BANK-FE.0 redactado) | identity, bank, palette_extended, tactile_ui, pseudo_3d, oklch, glassmorphism, react_19, vite_6, tailwind_v4, motion_12, no_size_limit, foundational |
| **ADR-018** | Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns (CP1-CP8) | 🟡 proposed (BANK-BE.0 redactado) | bank, compatibility, lite_mode, mutex, statebags, reconciliation, watchdog, cut_esx_legacy, foundational |

---

### ADR-018 — Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns

- **ID:** ADR-018
- **Título:** Bank Lite mode hybrid 3-layer + correlation-id mutex + cut ESX legacy + 8 mitigation patterns (CP1-CP8)
- **Fecha:** 2026-05-06 (BANK-BE.0 redactado canonical post Q-BE-pre-09 founder green-light)
- **Estado:** 🟡 **proposed** — sign-off triple target H2 ceremony Backend Lead → Security Lead.
- **Tags:** bank, compatibility, lite_mode, mutex, statebags, reconciliation, watchdog, cut_esx_legacy, foundational, amendment_anti_techdebt
- **Author:** Backend Money & Compatibility Lead (Cascade Sonnet 4.6 — sesión BANK-BE.0).

#### Contexto

El blueprint Bank app v1.2 (`@docs/design/proposals/03_bank_app_blueprint_v1.md`) §11 documentó audit Q16 sobre estrategia de compatibilidad multi-framework FiveM (QBox / QBCore / ESX) para SONAR Bank. Founder yaboula ratificó decisiones canonical 2026-05-06 (Q16 LOCKED + 8 Counter-Proposals CP1-CP8 accepted).

El handoff H1 (DB Lead → Backend Lead 2026-05-06 founder APPROVED) entregó schema v2.0 LOCKED PROVISIONAL incorporando 8 CP a nivel DDL (audit ledger inmutable + compliance flags + status FSM + idempotency keys + reconciliation index). Backend Lead sesión BANK-BE.0 compila este ADR-018 redactado canonical para registrar **decisión arquitectónica formal** sobre el approach Lite Mode + correlation-id mutex + cut ESX legacy + 8 CP, con sign-off target en handoff H2 Backend → Security.

#### Decisión

SONAR Bank Phase A adopta como arquitectura compatibility **definitiva**:

##### A. Frameworks Modernos (QBox / QBCore) → "Core Override"

Estrategia **runtime monkey-patch** RAM de las funciones nativas de dinero del framework (`Player.Functions.AddMoney/RemoveMoney/GetMoney/SetMoney`). Implementación vía **metatable proxy** + **sentinel attribute** (`QBCore.__sonar_patched = { applied_at, version, sentinel_signature }`) detectable por watchdog para integrity verification post-boot.

Resultado:
- SONAR es motor nativo del dinero bancario.
- Performance perfecto (zero overhead vs framework directo).
- Dominio total de la base de datos (DB authoritative source).
- Re-direction transparente para consumer code que use API native framework.

##### B. Framework Clásico (ESX 1.10+ ONLY) → "Modo Lite Triple Capa"

**Capa A — Event Hooking + Correlation-ID Mutex (path #1 ONLY):**
- Listener `esx:setAccountMoney` server-side.
- Inyección UUID v4 en metadata `reason` field cada mutación SONAR-initiated (`reason|sonar_correlation:<uuid>`).
- Listener detecta echo propio vía `MutexEcho.is_pending_echo(correlation_id)` + drop sin reconciliation.
- **NO TTL-based mutex.** **NO hash-fallback.**

**Capa B — Mapeo Híbrido Estricto:**
- `account_class = 'main'` → ESX `users.accounts` (anchor) + SONAR `sonar_bank_accounts` espejo.
- `account_class ∈ {'savings', 'escrow', 'business_treasury', 'crypto_wallet'}` → SONAR-only (premium tiers exclusivos `sonar_bank_accounts`).

**Capa C — Reconciliación Activa Async:**
- Queue async + batch SQL multi-row + cache LRU + trust window 5min.
- Performance target 200 concurrent <500ms p99 (Q16.5 + CP3).
- Threshold auto-apply €1000 (CP5). Sobre threshold → admin flag queue (`sonar_bank_compliance_flags`).
- Scope `account_class = 'main'` only (CP6) — premium tiers excluidos.

##### C. Cut ESX Legacy <1.10 OFICIAL

Defensive boot abort si detected. KVP `sonar_bank_disabled = 'unsupported_esx_legacy'` set + console banner crítico. Fundamento técnico: ESX <1.10 no soporta metadata en transferencias (forzaría hash-based mutex + código espagueti). Fundamento negocio: ~5% mercado mercado obsoleto pre-2019, reducción tickets soporte + cero bugs fantasma + código limpio premium.

##### D. 8 Counter-Proposals integradas (CP1-CP8)

| CP | Mecanismo | Owner |
|---|---|---|
| **CP1** State Bags global | Bank state mutations emit `GlobalState[bank.<domain>.<id>] = value` (CP1-A público) o discrete NetEvent ACE-checked (CP1-B admin/participant only — privacy refinement Q-BE-pre-02/03). | Backend Lead |
| **CP2** Correlation-ID Mutex | Path #1 only — UUID v4 metadata. NO hash-fallback. NO TTL. | Backend Lead |
| **CP3** Reconciliation Async Pipeline | Queue + batch SQL + cache LRU + trust window 5min. <500ms p99 200 concurrent. | Backend Lead + DB Lead joint |
| **CP4** Defensive Boot + Watchdog | 3-method framework detect + watchdog progressive (B+C combined: sentinel attribute + métrica indirecta) + KVP graceful disable + console banner crítico. | Backend Lead + DevOps Lead |
| **CP5** Reconciliation Threshold | €1000 default auto-apply. Sobre threshold → admin flag queue. | Backend Lead |
| **CP6** Reconciliation Scope | Solo `account_class = 'main'`. Premium tiers SONAR-only. | Backend Lead |
| **CP7** README + convars | `sv_experimentalStateBagsHandler` + `sv_experimentalNetGameEventHandler` + `sv_enableNetEventReassembly` defaults TRUE. | DevOps Lead |
| **CP8** Lite mode FSM + UI badge | FSM `sonar_bank_status` 4 states (`native_full` / `lite_mode_active` / `compromised_load_order` / `framework_missing`) + UI badge always visible Bank app sidebar footer. | Backend Lead (FSM) + Frontend Lead (UI) |

##### E. Privacy refinement (Q-BE-pre-02/03 founder LOCKED 2026-05-06)

CP1 redefinido sub-tracks A/B per privacy boundary:
- **CP1-A público:** balance + counts + status flags-bool → GlobalState aceptable (read-side broadcast all clients OK).
- **CP1-B admin/participant only:** detalle compliance flags + escrow state + audit ledger raw queries → discrete NetEvents `TriggerLatentClientEvent(target_source, payload)` + ACE check server-side ANTES de fire.

Justificación: docs.fivem.net confirma read-side global state es **broadcast a todos los clients sin filtrado nativo**. Datos sensibles en GlobalState = leak. Spec C-BE-05 implementa contract.

#### Alternativas consideradas + rechazadas

##### Alt 1 — Hash-based mutex code path (CP2 path #2)

- **Por qué se consideró:** ESX legacy <1.10 no soporta metadata → mutex via hash signature `sha256(player_id + amount + timestamp_floor_to_1s)` para detectar echo events.
- **Por qué rechazado:** code path complex + tech debt + brittle (1s timestamp floor genera false positives). Cut ESX legacy elimina necesidad. Q16 LOCKED founder approved cut.

##### Alt 2 — TTL-based mutex (5s window)

- **Por qué se consideró:** simpler semantic — block events 5s post mutación.
- **Por qué rechazado:** false positives en bursts payroll (50 employees simultaneous) + falla durante lag spikes. Correlation-id metadata es deterministic + zero false positives.

##### Alt 3 — Single resource monolithic (sin Bridges Layer)

- **Por qué se consideró:** simpler boot.
- **Por qué rechazado:** rompe ADR-009 Bridges Layer foundational principle. Acopla SONAR a 1 framework. Refactor cost masivo Phase B+. Inviable comercialmente (multi-framework support es selling point premium).

##### Alt 4 — TriggerClientEvent manual publishers Bank state (pre-CP1 approach)

- **Por qué se consideró:** familiar pattern.
- **Por qué rechazado:** CP1 mandatory — StateBags global native superior (engine-managed serialization + native auth + lower bandwidth + reactive client side). Q16 LOCKED.

##### Alt 5 — Reconciliation auto-apply unbounded

- **Por qué se consideró:** "trust the framework".
- **Por qué rechazado:** silent evaporation risk if external resource bug emit large erroneous mutation. CP5 threshold €1000 + admin flag queue protege player money + audit trail trust.

#### Consecuencias

##### Positivas

- **Performance perfecto QBox/QBCore** via Core Override (zero overhead vs native framework).
- **Compatibilidad ESX 1.10+** sin sacrificar features Bank premium (savings + escrow + business + crypto).
- **Eliminación tech debt** — sin code paths legacy ESX <1.10 + sin hash mutex + sin TTL mutex.
- **Privacy by design** — CP1-A/B split protege detalle compliance + escrow shared state.
- **Defense in depth** — 4 layers (defensive boot + correlation-id mutex + reconciliation pipeline + watchdog progressive) anti silent corruption.
- **Transparencia UX** — UI badge `sonar_bank_status` always visible + admin flag queue visible compliance flags page.
- **CDD compliance** — 18 contratos LOCKED firma garantiza interfaces estables.

##### Negativas

- **~5% mercado pérdida** (servidores ESX <1.10 obsoleto pre-2019). Founder accept Q16.1.
- **Boot complexity** — 3-method framework detect + watchdog progressive + KVP graceful disable add code surface (mitigated por testing matrix C-DO-01 DevOps).
- **Backend code surface** — 4 NEW libs canonical (`sonar_bridges/lib/` mutex_echo + reconciliation + idempotency_keys + audit_ledger) + 4 module servers (core_override + lite_mode + watchdog + bank_status_publisher). Risk under-test or boot failure (mitigated CP4 defensive + smoke chaos test C-DO-01).
- **DB pressure** — reconciliation queue + audit ledger append-only + idempotency keys table grow. Mitigations: partitioning (DB Lead Q-DB-G partitions Dec 2027) + cron TTL purge idempotency 7d (DevOps).

##### Re-evaluation triggers

- Backend Lead post-H1 reporta benchmark fail Q-BE-pre-08 Opción C — AMENDMENT v2.1 schema (DB Lead Standby reactivation per condicional clauses).
- Security Lead H2 audit detecta vulnerability watchdog logic — propose AMD_ADR-018_<date>.md.
- Founder Phase B requires re-enable ESX <1.10 (improbable) — major amendment con full impact analysis.
- New FiveM primitive published que mejora correlation-id mechanism (e.g. native event metadata standardization) — minor amendment.

#### Impact downstream

| Lead | Impact |
|---|---|
| **DB Lead (Standby)** | Schema v2.0 LOCKED PROVISIONAL ya entregado supports ADR-018 (audit ledger + compliance flags + status FSM + idempotency keys + reconciliation indexes). Reactivation triggers per H1 §6 condicional clauses. |
| **Backend Lead (this)** | Implementa C-BE-04 Bridges spec + C-BE-05 StateBags + C-BE-03 FSMs + libs canonical + boot sequence. |
| **Security Lead (post-H2)** | Audit watchdog logic + ACE matrix Core Override compromise scenarios + autoraise rules canonical (5 patrones Q10) + audit hooks integration. |
| **Frontend Lead (post-H3)** | Consume `bank.bridges.status` StateBag + UI badge always visible CP8 + Q16.3 + ADR-017 paleta extendida. |
| **DevOps Lead (post-H4)** | fxmanifest dependencies + load order + smoke chaos test multi-framework matrix (QBox + QBCore + ESX 1.10+ + ESX legacy intentional FAIL boot expected) + README install convars + sub-tag `bank-phase-a`. |

#### Sign-off target H2

- ☐ **Founder yaboula** — final approval ADR-018 + ratify Q-BE-pre-* decisions LOCKED.
- ☐ **Backend Lead (proposer)** — already self-attested via DRAFT v0.1 BANK-BE.0.
- ☐ **Security Lead** — accept watchdog logic + ACE checks + threat model.
- ☐ **DevOps Lead** — accept fxmanifest + load order + boot sequence + convars CP7.

#### Cross-references

- Blueprint v1.2 Q16 audit completo: `@docs/design/proposals/03_bank_app_blueprint_v1.md:2496-2942`.
- Brief §3.2-3.4: `@docs/agents/teams/01_SHARED_BRIEF.md` (decisiones Q16 + sub-questions Q16.1-Q16.6 + 8 CP table).
- C-BE-04 Bridges Compatibility v1.1 DRAFT: `@docs/agents/teams/drafts/be_phase_a/c_be_04_bridges_v1_1.md`.
- C-BE-05 StateBags Global Publishers DRAFT: `@docs/agents/teams/drafts/be_phase_a/c_be_05_statebags_global_publishers.md`.
- C-BE-03 State Machines v1.1 DRAFT (CP8 FSM): `@docs/agents/teams/drafts/be_phase_a/c_be_03_state_machines_v1_1.md`.
- Research notes FiveM primitives: `@docs/agents/teams/drafts/be_phase_a/research_notes.md`.
- Schema DB v2.0 LOCKED PROVISIONAL `@docs/technical/03_db_schema.md` §22-§29 (CP support DDL).
- ADR-009 (Bridges Layer foundational): `@docs/planning/02_decision_log.md` ADR-009.
- ADR-013 (namespace migration `sonar_*`): `@docs/planning/02_decision_log.md` ADR-013.

---

### ADR-017 — SONAR Bank paleta extendida + Tactile UI pseudo-3D doctrine + oklch() + premium glassmorphism (extends ADR-016)

- **ID:** ADR-017
- **Título:** SONAR Bank paleta extendida (12 surface tiers + 4 semantic deep + signature gradient) + Tactile UI 2D-simulating-3D doctrine canonical (pseudo-3D depth via multi-layer box-shadow + radial diffuse light + premium smoked glass) + oklch() color space mandatory + stack 2026 absolute (React 19.2 + Vite 6 + Tailwind v4 + Motion v12)
- **Fecha:** 2026-05-06 (BANK-FE.0 redactado canonical post founder Q9 Tactile UI green-light + Q10 no-size-limit + ADR-016 amendment scope Bank-app-specific extension)
- **Estado:** 🟡 **proposed** — sign-off triple target BANK-FE.LOCK ceremony Frontend Lead → Founder + consultative Backend Lead Standby (no impacto contracts) + DevOps Lead H4 future (build pipeline implications).

#### Contexto

ADR-016 (firmado v1.0 accepted en este `02_decision_log_part2.md`) estableció **SONAR Identity v3** firmable + doctrine palette/dark/stack/perf locked: paleta base 3-color strict (`#060607` Abyss / `#FAFAFA` Surface / `#FF5100` Signal Orange) + dark-only + Inter Variable + JetBrains Mono Variable + sombra doctrine + GPU-only motion + 300KB gz performance budget + stack frozen Tablet S2.

El **Bank app** (mandate BANK-FE.0 + slice §4.5-§4.7 + blueprint v1.2 + 3 imágenes referencia founder Fintrixity-class) requiere extender ADR-016 con:

1. **Paleta extendida Bank-specific** — 3-color base ADR-016 insuficiente para representar 5 estados financieros (saldo positivo + saldo negativo + advertencia compliance + flag crítico + neutral text scale 4 tiers) + 12 surface tiers para depth ladder Tactile UI.
2. **Tactile UI doctrine pseudo-3D** — founder Q9 BANK-FE.0 explicit directive: *"No quiero diseños planos. Exijo 2D simulando 3D (Tactile UI). Tus componentes deben implementar obligatoriamente: profundidad táctil (box-shadow inset biseles + iluminación superior bordes), glows y gradientes ricos (luz difusa detrás paneles principales radial-gradient + oklch espacio color), glassmorphism (cristal premium ahumado backdrop-blur intensos sobre bg-black/40 con bordes ultrafinos)."*
3. **oklch() color space mandatory** — superior a HSL/RGB en perceptual uniformity + wide-gamut P3 modern displays + supported Tailwind v4 native + Chromium 111+ (FiveM CEF runtime compatible). Founder directiva explícita.
4. **Performance budget eliminado Phase A Bank** — founder Q10 BANK-FE.0: *"SIN LÍMITE DE TAMAÑO. Quiero la última generación absoluta del stack en 2026. Tu prioridad número 1 es conseguir la mejor UI/UX posible del mercado para asegurar 5 años de superioridad frente a la competencia. Usa las herramientas más potentes disponibles, sin escatimar en peso si eso garantiza fluidez y espectacularidad."* — amendment ADR-016 D6 (300KB gz cap) **eliminado scope Bank app** (Tablet shell mantiene D6).

#### Decisión

Adopta **ADR-017 SONAR Bank paleta extendida + Tactile UI doctrine canonical** que extiende ADR-016 con los siguientes 8 sub-decisiones firmables:

##### D1 — Paleta extendida 12 surface + 4 semantic + signature gradient (oklch)

**Surface ladder dark (12 tiers — Tactile UI depth simulation):**

| Tier | Token | oklch() | Hex equiv (sRGB approx) | Use case |
|---|---|---|---|---|
| **0 Abyss** | `--surface-abyss` | `oklch(0.04 0.005 270)` | `#060607` | App canvas root (ADR-016 D1 inherited) |
| **1 Void** | `--surface-void` | `oklch(0.06 0.008 270)` | `#0A0A0B` | Sidebar nav background |
| **2 Card** | `--surface-card` | `oklch(0.10 0.010 270)` | `#111114` | Card baseline (NO glass) |
| **3 Card-elevated** | `--surface-card-elevated` | `oklch(0.13 0.012 270)` | `#18181C` | Card hover + selected |
| **4 Card-glass** | `--surface-card-glass` | `oklch(0.10 0.010 270 / 0.48)` | `rgba(17,17,20,0.48)` | Glass cards (backdrop-blur) |
| **5 Modal-scrim** | `--surface-modal-scrim` | `oklch(0.04 0.005 270 / 0.72)` | `rgba(6,6,7,0.72)` | Modal overlay base |
| **6 Modal-surface** | `--surface-modal` | `oklch(0.13 0.012 270)` | `#1F1F25` | Modal content card |
| **7 Input-rest** | `--surface-input` | `oklch(0.08 0.008 270)` | `#0F0F12` | Input baseline |
| **8 Input-focus** | `--surface-input-focus` | `oklch(0.13 0.014 270)` | `#1A1A1F` | Input focused |
| **9 Tooltip** | `--surface-tooltip` | `oklch(0.18 0.014 270)` | `#26262C` | Tooltip + popover |
| **10 Toast** | `--surface-toast` | `oklch(0.13 0.012 270)` | `#1F1F25` | Toast notification |
| **11 Premium-glow** | `--surface-glow` | `oklch(0.65 0.22 40 / 0.06)` | `rgba(255,109,28,0.06)` | Radial diffuse light source backdrop |

**Semantic deep tiers (4 — financial state colors):**

| Token | oklch() | Hex equiv | Use case |
|---|---|---|---|
| `--semantic-success-deep` | `oklch(0.65 0.18 155)` | `#10B77A` | Saldo positivo + `+€` deltas + transaction success |
| `--semantic-success-glow` | `oklch(0.65 0.18 155 / 0.18)` | `rgba(16,183,122,0.18)` | Card success glow halo |
| `--semantic-warning-deep` | `oklch(0.78 0.16 85)` | `#F4B400` | Compliance flag low/medium severity + tax bracket warnings |
| `--semantic-warning-glow` | `oklch(0.78 0.16 85 / 0.16)` | `rgba(244,180,0,0.16)` | Warning surface glow |
| `--semantic-danger-deep` | `oklch(0.62 0.21 25)` | `#E63946` | Compliance flag HIGH+CRITICAL + `-€` deltas grandes + insufficient_funds |
| `--semantic-danger-glow` | `oklch(0.62 0.21 25 / 0.18)` | `rgba(230,57,70,0.18)` | Danger surface glow halo |
| `--semantic-info-deep` | `oklch(0.70 0.14 230)` | `#4A9EFF` | Info/neutral notifications + recurring next-payment hints |
| `--semantic-info-glow` | `oklch(0.70 0.14 230 / 0.14)` | `rgba(74,158,255,0.14)` | Info surface glow |

**Neutral text scale (4 tiers — derived Surface Light ADR-016):**

| Token | oklch() | Hex equiv | Use case |
|---|---|---|---|
| `--text-primary` | `oklch(0.98 0.005 270)` | `#FAFAFA` | Headings + balance amounts hero |
| `--text-secondary` | `oklch(0.98 0.005 270 / 0.72)` | `rgba(250,250,250,0.72)` | Body text + secondary labels |
| `--text-tertiary` | `oklch(0.98 0.005 270 / 0.48)` | `rgba(250,250,250,0.48)` | Captions + metadata + timestamps |
| `--text-quaternary` | `oklch(0.98 0.005 270 / 0.24)` | `rgba(250,250,250,0.24)` | Disabled + dividers + subtle borders |

**Signature gradient (Bank-specific brand):**

| Token | Definition | Use case |
|---|---|---|
| `--gradient-primary` | `linear-gradient(135deg, oklch(0.65 0.22 40), oklch(0.78 0.18 55))` | CTA primario fill (Transfer + Confirm + Submit) |
| `--gradient-primary-glow` | `radial-gradient(ellipse 60% 80% at 50% 0%, oklch(0.65 0.22 40 / 0.18), transparent 70%)` | Card hero radial diffuse light (top-glow signature) |
| `--gradient-orange-shimmer` | `linear-gradient(135deg, oklch(0.65 0.22 40), oklch(0.85 0.15 65), oklch(0.65 0.22 40))` background-size 200% animated | Premium loading skeleton + featured card highlight |
| `--gradient-glass-edge` | `linear-gradient(135deg, oklch(1 0 0 / 0.12), oklch(1 0 0 / 0.02), oklch(1 0 0 / 0.08))` | Glass card edge highlight (mask-composite border) |

##### D2 — Tactile UI multi-layer box-shadow ladder canonical

**Cada componente "tactile" implementa obligatoriamente combinación shadow:**

```css
/* Tier baseline tactile-card (Card, BalanceCard, EntityCard) */
.tactile-card {
  /* (1) Edge highlight superior — simulates light source from top */
  box-shadow:
    inset 0 1px 0 oklch(1 0 0 / 0.08),
    /* (2) Edge shadow inferior — simulates depth from below */
    inset 0 -1px 0 oklch(0 0 0 / 0.6),
    /* (3) Outer ambient soft shadow — simulates floating */
    0 8px 24px -8px oklch(0 0 0 / 0.5),
    /* (4) Brand glow halo (only on hero/focus) */
    0 24px 64px -16px oklch(0.65 0.22 40 / 0.12);
}

/* Tier elevated tactile-card-elevated (hover + selected state) */
.tactile-card-elevated {
  box-shadow:
    inset 0 1px 0 oklch(1 0 0 / 0.12),
    inset 0 -1px 0 oklch(0 0 0 / 0.7),
    0 12px 32px -8px oklch(0 0 0 / 0.6),
    0 32px 80px -16px oklch(0.65 0.22 40 / 0.18);
}

/* Tier button-primary (CTA — pressable feel) */
.tactile-button-primary {
  background: var(--gradient-primary);
  box-shadow:
    inset 0 1px 0 oklch(1 0 0 / 0.32),  /* Top bevel highlight (light from above) */
    inset 0 -1px 0 oklch(0 0 0 / 0.32), /* Bottom bevel shadow */
    0 4px 12px -2px oklch(0.65 0.22 40 / 0.40),  /* Outer glow brand */
    0 8px 24px -4px oklch(0 0 0 / 0.32);  /* Ambient depth */
}

.tactile-button-primary:active {
  /* On press — invert bevels to simulate "pushed in" */
  box-shadow:
    inset 0 1px 0 oklch(0 0 0 / 0.24),
    inset 0 -1px 0 oklch(1 0 0 / 0.10),
    inset 0 4px 8px -2px oklch(0 0 0 / 0.24),
    0 2px 6px -1px oklch(0.65 0.22 40 / 0.32);
  transform: translateY(1px);
}

/* Tier glass-card (Hero overview balance + Floating panels premium) */
.tactile-glass-card {
  background: oklch(0.10 0.010 270 / 0.40);
  backdrop-filter: blur(24px) saturate(180%);
  border: 1px solid transparent;
  background-clip: padding-box;
  box-shadow:
    inset 0 1px 0 oklch(1 0 0 / 0.12),
    inset 0 0 0 1px oklch(1 0 0 / 0.04),
    0 24px 48px -16px oklch(0 0 0 / 0.6),
    0 48px 96px -32px oklch(0.65 0.22 40 / 0.10);
  /* Edge highlight via gradient border (mask composite trick) */
  position: relative;
}
.tactile-glass-card::before {
  content: '';
  position: absolute;
  inset: 0;
  padding: 1px;
  border-radius: inherit;
  background: var(--gradient-glass-edge);
  -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  pointer-events: none;
}
```

##### D3 — Radial diffuse light sources canonical

Cada vista "hero" (Overview, Empresas Dashboard, Government Console) implementa **al menos una fuente luz difusa radial** detrás de panel principal:

```css
.vista-hero-light {
  position: relative;
}
.vista-hero-light::before {
  content: '';
  position: absolute;
  inset: 0;
  background: var(--gradient-primary-glow);  /* radial 0.18 alpha orange top-center */
  pointer-events: none;
  z-index: -1;
  filter: blur(40px);
}
```

##### D4 — Premium glassmorphism — smoked glass spec

Glass cards canonical (Floating panels Hero + Modals + Tooltips premium):

- `background: oklch(0.10 0.010 270 / 0.40)` (smoked dark base, ~40% opacity)
- `backdrop-filter: blur(24px) saturate(180%)` (intense blur + super-saturated for vivid glass effect on Chromium 111+)
- Edge highlight ultra-thin via `::before` mask composite (gradient border 1px imperceptible solid color, gradient instead).
- NO transparency on text (`color: oklch(0.98 0.005 270)` 100% opacity always for legibility WCAG AA).

##### D5 — Stack 2026 absolute (extends ADR-016 D5 stack frozen Tablet S2 — Bank-specific extension)

| Layer | Package | Versión | Razón inclusión |
|---|---|---|---|
| **Framework** | React | 19.2.4+ | Latest stable Q1 2026 — `use()` hook + Actions API + concurrent + RSC stable |
| **Build** | Vite | 6.x (Rolldown stable) | 10x cold start vs v5, native ESM, Rust bundler perf |
| **Lang** | TypeScript | 5.7+ | Latest decorators stage 3, inferred predicates |
| **Styling** | Tailwind CSS | v4.x | OKLCH native, CSS-first `@theme`, P3 wide-gamut, 5x faster builds |
| **Primitives UI** | Radix UI Primitives | latest | Accessibility-first React 19 compat |
| **Components base** | shadcn/ui | v2 (Tailwind v4 adapted) | Cherry-pick copy-paste — no npm baggage |
| **Motion** | motion (ex Framer Motion) | 12.x | `motion/react` import path, spring physics real, layout/exit |
| **State client** | Zustand | 5.x | 1KB, React 19 concurrent-safe |
| **State server** | TanStack Query | v5 | Suspense + use() integration React 19 |
| **Forms** | React Hook Form | 7.x | Uncontrolled, Zod v4 resolver |
| **Validation** | Zod | v4 | Shared client/server schemas |
| **Charts** | Recharts | 2.13+ | Composable SVG React-first (Overview sparkline + Treasury cash-flow + Stocks portfolio) |
| **PDF** | @react-pdf/renderer | 4.x | Declarative React JSX-like API (Transfer receipt + Statement export) |
| **i18n** | react-i18next | 15.x | JSON resources per-locale, lazy-load |
| **Icons** | Lucide React | latest | Match existing Tablet (ADR-016 inherited) |
| **Fonts** | Inter Variable + JetBrains Mono Variable | canonical | ADR-016 D2 inherited |
| **Test unit** | Vitest + @testing-library/react | latest | Vite-native, React 19 compat |
| **Test E2E** | Playwright | 1.50+ | Chromium-parity NUI integration |

**Stack Tablet S2 (`sonar_tablet`) sigue ADR-016 D5 frozen** — NO upgrade automático. Bank app (`sonar_bank_app`) opera en stack 2026 absolute como **resource separado** con su propio `web-src/` build pipeline.

##### D6 — Performance budget Bank-specific eliminado (amendment ADR-016 D6 scope-restricted)

ADR-016 D6 (300KB gz main bundle cap + 60fps motion + lazy-load codepath) **scope-restricted a Tablet shell** post ADR-017. Bank app (`sonar_bank_app/web-src/`) opera **sin cap bundle size** per founder directiva BANK-FE.0 Q10. Prioridad 1: UI/UX superioridad mercado 2026+. Charts + PDF + premium animations + glass shaders aceptados sin restriction.

**Tier B observability (no enforcement Phase A):** profile bundle size + paint metrics post-LOCK. Si degradation observed (>2s FCP en hardware bajo en QA real users), reactivación budget Phase B targeted.

##### D7 — Dark-only strict (inherited ADR-016 D3 inquebrantable)

Bank app implementa **dark-only strict**. NO light mode Phase A. NO theme switcher UI. ADR-016 D3 firmable inherited sin amendment.

##### D8 — Reduced motion + a11y WCAG 2.2 AA mandatory

`prefers-reduced-motion: reduce` honor estricto. Cada motion preset (12 presets canonical en C-FE-02 §motion) tiene **fallback static documentado**. Contrast ratios mandatory:
- Text primary sobre Card baseline (Tier 2): **15.8:1** (WCAG AAA exceeds).
- Text secondary sobre Card baseline: **11.3:1** (WCAG AAA).
- Signal Orange `oklch(0.65 0.22 40)` sobre Abyss (Tier 0): **4.7:1** (WCAG AA pass for ≥18px text).
- Border quaternary `oklch(0.98 0.005 270 / 0.24)` sobre Card baseline: NO text use case — decorative only, no contrast req.

Focus visible mandatory: ring 2px `oklch(0.65 0.22 40 / 0.6)` + offset 2px sobre fondo.

#### Consecuencias

**Beneficios:**
1. Identidad visual SONAR Bank **diferenciada y premium** vs competencia FiveM (Quasar Bank class) y banca real (Apple Card class).
2. Tactile UI doctrine **transferible** a futuras apps SONAR (Phone, Inventory, Empresas Premium) post Phase B → identidad SONAR ecosystem cohesiva.
3. Stack 2026 absolute **future-proof 5+ años** — React 19 + Tailwind v4 + Motion v12 son baseline mainstream entrante 2026-2030.
4. oklch() **gama-wide P3** displays modernos (iPhone Pro / MacBook 2021+ / OLED gaming monitors 2024+) renderiza colores **vibrantes** vs sRGB sufrida cap en Tailwind v3 baseline.
5. Performance budget eliminado libera **expressiveness máxima** — animaciones premium 60fps, glass shaders avanzados, chart interactions ricas.

**Coste / tradeoffs:**
1. **Bundle size Bank app** será 800-1500KB gz (estimación: React 19 ~45KB + Motion 12 ~35KB + Recharts ~80KB + react-pdf ~250KB + Tailwind v4 generated CSS ~100KB + react-i18next + Radix + lucide + 10 vistas chunks lazy 80KB each). NUI CEF en máquinas low-end FiveM puede experienciar carga inicial 2-4s — aceptable per founder Q10. Mitigations: aggressive lazy-load per-vista + service worker cache (Phase B).
2. **Browser compatibility:** oklch() requiere Chromium 111+ (FiveM CEF runtime ~ Chromium 118 actual 2026 → NO issue). Mask composite (glass edge) requiere Chromium 120+ (NO issue). `backdrop-filter: blur(24px)` requiere GPU compositing — máquinas iGPU integradas degradan ~10-15% FPS, mitigation `prefers-reduced-transparency` fallback opaque.
3. **Build time:** Vite 6 Rolldown ~5s cold (vs ~12s Vite 5). Acceptable.
4. **Designer onboarding cost:** doctrine Tactile UI requiere disciplina box-shadow ladder strict — documented exhaustivo en C-FE-02 v0.1 + dev page `/dev/components` showcase.
5. **Maintenance:** React 19 concurrent rendering require disciplina `use()` hook + Actions API patterns — Frontend Lead documenta pitfalls + best practices en C-FE-03 §react-19-pitfalls.

#### Alternativas rechazadas

- **Mantener ADR-016 strict (3-color + flat dark + 300KB gz cap):** rejected — founder Q9 + Q10 explicit directive Tactile UI + no-size-limit. Flat design contradice premium fintech 2026.
- **Neumorphism puro (sin glass + sin gradients):** rejected — neumorphism solo es minimalist class (smart home / wellness apps per Zignuts research) — Bank requires high-energy data-rich glassmorphism (Inverness Design Studio research fintech sector).
- **Skeuomorphism realistic (textures + photographic):** rejected — outdated 2026, increases bundle size sin valor UX premium.
- **HSL color space (vs oklch):** rejected — gama sRGB capped, perceptual non-uniformity, Tailwind v4 default oklch superior.
- **Storybook component gallery:** rejected — Q15 founder LOCKED Vite Dev Page minimal `/dev/components` (single Vite app, tree-shake prod).

#### Sign-off target BANK-FE.LOCK

- ☐ **Founder yaboula** — final approval ADR-017 paleta + Tactile UI doctrine + stack absolute + budget elimination Bank-specific.
- ☐ **Frontend Lead (proposer)** — already self-attested via DRAFT v0.1 BANK-FE.0.
- ☐ **Backend Lead (consultative Standby)** — endorsement no impacto contracts (tokens/style separados de C-BE-01..05 LOCKED).
- ☐ **DevOps Lead (post-H4 future)** — accept build pipeline implications + Vite 6 Rolldown adoption + bundle observability tier B.
- ☐ **Security Lead (consultative)** — endorsement glassmorphism backdrop-filter no impacta C-SEC-01..03 (UI rendering only, no data privacy implications — privacy ya enforced server-side per M004).

##### Re-evaluation triggers

- Founder Phase B feedback rechazo Tactile UI por degradation perf en máquinas low-end → AMEND_ADR-017_<date>.md amendment subset doctrine (e.g. simplificar shadow ladders).
- Browser compatibility issue oklch() / backdrop-filter en CEF runtime FiveM update → AMEND scope.
- Bundle size > 3MB gz observed real users → reactivación budget tier B → minor amendment lazy-load más agresivo.
- React 20 / Tailwind v5 release stable Phase C+ → minor amendment stack upgrade.

#### Cross-team impact

| Lead | Impact |
|---|---|
| **Backend Lead (Standby)** | NO impacto contracts C-BE-01..05 v1.0.1 R1 LOCKED. Endorsement consultative confirmando paleta + tactile doctrine son scope Frontend exclusivo. |
| **Security Lead (Standby)** | NO impacto C-SEC-01..03 LOCKED equivalent. Privacy boundary M004 ya enforced server-side — UI rendering glassmorphism no leak data. Consultative endorsement opcional. |
| **DB Lead (Standby)** | NO impacto schema. |
| **Frontend Lead (this)** | Implementa C-FE-01 (UI Contracts 10 vistas) + C-FE-02 (Design System Tactile UI) + C-FE-03 (Data Integration Mock Layer) consumiendo ADR-017 doctrine canonical. |
| **DevOps Lead (post-H4)** | fxmanifest `sonar_bank_app` web-src build pipeline (Vite 6 Rolldown) + observability tier B bundle profile + smoke chaos test multi-device matrix (P3 wide-gamut display + sRGB legacy) + README install. |

#### Cross-references

- ADR-016 (firmable v1.0 accepted): identidad SONAR base — `@docs/planning/02_decision_log_part2.md` ADR-016. **Inherited:** D1 (3-color base) + D2 (fonts) + D3 (dark-only) + D4 (sombra doctrine) + D7 (anti-patterns 4-color/light-mode/Storybook).
- C-BE-05 v1.0.1 R1 LOCKED — privacy boundary M004 financial-grade upstream consumed.
- C-SEC-02 LOCKED equivalent — 12 ACE perms P01-P12 consumed para UI gating.
- Blueprint v1.2 §3 (palette tokens initial) + §4 (10 vistas wireframes) — extended por ADR-017.
- Slice Frontend `@docs/agents/teams/slices/slice_frontend.md` §4.5-§4.7 (10 vistas inventory) + §4.9 (i18n + tooling).
- Imágenes referencia founder Fintrixity-class — `@resources/sonar_bank/simple-ref-bank-ui/*.jpg`.
- Tailwind CSS v4 official release notes (oklch native + `@theme` config).
- Motion v12 docs (`@motion.dev/docs/react`).
- React 19 stable docs (`@react.dev/blog/2024/12/05/react-19`).
- IxDF Glassmorphism research 2026.
- Zignuts Neumorphism vs Glassmorphism trade-off 2026.

---

*"Decisiones sin registro son decisiones perdidas. Continuidad mantiene la memoria viva."*

**FIN DEL DOCUMENTO `02_decision_log_part2.md` v1.2** (post ADR-017 proposed BANK-FE.0 + ADR-018 proposed BANK-BE.0)
