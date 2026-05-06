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

*"Decisiones sin registro son decisiones perdidas. Continuidad mantiene la memoria viva."*

**FIN DEL DOCUMENTO `02_decision_log_part2.md` v1.1** (post ADR-018 proposed BANK-BE.0)
