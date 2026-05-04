# 📋 SONAR — Sprint Plan S2

> **Versión:** **1.0 (firmable)** — post S2.0 planning gate review crítico DC1-DC11 + smoke ×50 + session breakdown + risks + 11 pre-flags resueltos.
> **Autor:** Founder + Cascade (S1.10.5 Item H 0.1-draft, 2026-05-04 → S2.0 finalize v1.0, 2026-05-04 mismo día).
> **Sprint:** S2 — Oleada 1 — UI Foundation (Tablet + Bank + Map).
> **Duración:** ~4 semanas (ADR-015 UI-heavy pivot, amends ADR-011 §4 Phase 12).
> **Scope refs:** ADR-015 (UI-heavy scope D1=B) + ADR-016 (identity v3 lock: D3 3-color palette + D5 Tablet stack FROZEN + D6 NUI perf budgets).
> **Dependencia crítica:** Phase 8+9 execution (code namespace `admirals_*` → `sonar_*`) + Phase 10 smoke regression ✅ DONE (tag `phase-8-9-complete`).
> **Estado:** 🟢 **FIRMABLE v1.0** — todos gates ✅, plan listo para arranque S2.1.

---

## 0. Pre-sprint gate status

| Gate | Estado | Detalles |
|---|---|---|
| B1 Phase 6 mass-purge docs | ✅ CERRADO 8/8 | NOTICE r1 pattern todos los docs técnicos |
| ADR-016 identity v3 lock docs | ✅ DONE | PRODUCT_BIBLE v1.5 + art_direction v3.0-locked + BOOTSTRAP v1.6 + sonar_tablet v1.3 + brief_logo v3 |
| Phase 8 code refactor `sonar_*` | ✅ DONE | `sonar_bridges` + `sonar_bank` + `sonar_core` + exports + events renamed. |
| Phase 9 DB migration 009 | ✅ DONE | `009_rename_admirals_to_sonar.sql` applied. 6 tablas + FKs + índices renamed. |
| Phase 10 smoke regression 30/30 | ✅ DONE | 30/30 cumulative S0+S1 pass ✅ |
| B5 tags | ✅ DONE | `sonar-identity-canonical` + `sonar-identity-v3-lock` + `phase-8-9-complete` pushed. |
| SPRINT_PLAN_S2.md v1.0 | ✅ ESTE DOC | v1.0 firmable post-S2.0 review crítico. |

**Arranque S2.1:** 🟢 DESBLOQUEADO — todos gates ✅. Próxima sesión = S2.1 Tablet scaffold setup.

---

## 1. Objetivos S2

### 1.1 North star S2

**Demostrar SONAR identity v3 en producto funcional.** El jugador abre el Tablet con TAB, ve una UI dark-only premium con identidad visual 3-color canonical, accede a su balance bancario y puede transferir. El mapa muestra dónde están los nodos SONAR. Todo con motion + sound signature canónicos.

### 1.2 Goals firmed (ADR-015 D1=B UI-heavy)

1. **Tablet shell NUI** — boot + keybind TAB + animación entrada/salida + dark-only 3-color canvas.
2. **SONAR Bank app** — balance + historial transacciones + transfer form (usando `sonar_bank` post-Phase-8).
3. **Map app** — GPS player marker + POI markers nodos SONAR (Farm/Mill/Bakery/Retail).
4. **Motion signature** — 5 animaciones entrada canonical (Framer Motion 11, GPU-only).
5. **Sound signature** — 5 SFX canonical integrados (`signal_emerge` / `depth_press` / `layer_dive` / `console_tap` / `panel_open`).

### 1.3 Deferred a S3 (ADR-015)

- T2 adapters ESX/QBCore (solo `sonar_bridges` QBox en S2).
- `sonar_companies` DDL + governance.
- C003 `getTransactions` callback (marcado DEFERRED en `04_api_contracts.md` v1.1 NOTICE r1).
- Custom icons (8 abstract — Lucide puro en S2).
- Sound brief production (in-house vs externo) — deferred hasta uso real.

---

## 2. Scope técnico firmed

### 2.1 Arquitectura Tablet NUI

```
resources/sonar_tablet/          (post-Phase-8 rename)
├── web-src/                     React app fuente
│   ├── src/
│   │   ├── App.tsx              Shell router + keybind listener
│   │   ├── apps/
│   │   │   ├── Bridge/          Home view (app grid 12 apps)
│   │   │   ├── Bank/            Balance + historial + transfer
│   │   │   └── Map/             GPS + POIs
│   │   ├── context/             React Context + useReducer (NO Zustand)
│   │   ├── components/          shadcn/ui dark-only + custom
│   │   └── styles/              Tailwind v4 @theme tokens
│   ├── package.json             SSoT stack FROZEN (ver §4)
│   └── vite.config.ts
├── client.lua                   keybind TAB + NUI toggle
├── server.lua                   NUI bridge events
└── fxmanifest.lua
```

### 2.2 Comunicación cliente↔server S2 (3 categorías separadas)

> **Importante:** §2.2 NO es "eventos NUI" genéricos. Hay 3 categorías distintas con SSoTs distintos. NO promover items a `02_events_catalog.md` v1.2 sin ADR firmable.

#### 2.2.1 Keybinds cliente puros (in-process — sin bus event)

| Identifier | Dirección | Propósito | SSoT |
|---|---|---|---|
| `sonar:tablet:toggle` | client→client (Lua handler) | TAB key abre/cierra Tablet NUI vía `RegisterCommand` + `SendNUIMessage` | `client.lua` S2.2 |

#### 2.2.2 Callbacks shipped S1 (consumir vía NUI bridge)

| Callback | Origen | Propósito | SSoT |
|---|---|---|---|
| C001 `sonar:bank:getBalance` | shipped S1.1 | Request saldo IBAN player | `04_api_contracts.md` v1.2 §3.1 |
| C002 `sonar:bank:transfer` | shipped S1.2 | Transfer player→player atomic | `04_api_contracts.md` v1.2 §3.2 |

#### 2.2.3 NUI bridges S2 ad-hoc — consumer pattern temporal (DEFERRED catalog promotion S3)

> **Pattern temporal per ADR-015 línea 1162:** Bank app S2 puede consumir DB query directa hasta C003 ship S3. Map POIs admin-defined. **NO documentar en `02_events_catalog.md` v1.2** — bridge específico del Tablet, sin promoción canónica hasta S3.

| NUI bridge | Dirección | Propósito | Status canonical |
|---|---|---|---|
| `sonar:tablet:bank:getHistory:request/response` | client→server (NUI) | últimas N transacciones cliente vía `SELECT FROM sonar_bank_movements WHERE account_id=? ORDER BY created_at DESC LIMIT N` | 🟡 ad-hoc S2 — promote C003 S3 |
| `sonar:tablet:map:getNodes:request/response` | client→server (NUI) | POIs admin-defined visibles player (Granja/Mill/Bakery/Retail placeholders S2) | 🟡 ad-hoc S2 — promote callback firmable S3+ |

---

## 3. Done criteria (×12)

| # | Criterio | Verificación |
|---|---|---|
| DC1 | Tablet NUI boots sin errores console en FiveM Chromium | DevTools console clean |
| DC2 | Keybind TAB abre/cierra Tablet con animación entrada (`panel_open` sound + motion) | Manual test |
| DC3 | Dark-only doctrine 100% — cero surfaces blancas/off-white en producto | Visual audit + CSS grep |
| DC4 | 3-color canonical: solo `--sonar-black` / `--sonar-orange` / `--sonar-white` en UI product | CSS token audit |
| DC5 | Bank app: balance real player carga en ≤200ms via C001 (post-Phase-8 `sonar_bank`) | Performance tab |
| DC6 | Bank app: transfer A→B exitoso (C002), balances actualizados ambos sides, historial muestra entry vía consumer pattern temporal §2.2.3 (DB directo hasta C003 S3) | Smoke test S2.8 |
| DC7a | Map app: marker GPS player se renderiza ≥30 fps cliente (sin lag perceptible movement local) | Manual test in-server + DevTools profiler |
| DC7b | Map app: POI nodos response `sonar:tablet:map:getNodes` ≤500ms desde request | Network tab DevTools |
| DC8 | Motion signature: 5 animaciones Framer Motion 11 GPU-only sin jank (≥55fps) | Performance profiler |
| DC9 | Sound signature: 5 SFX canonical disparan en evento correcto sin overlap (close = silent per S2.0 decision) | Audio test manual |
| DC10 | NUI perf budgets: JS ≤500KB gzip, CSS ≤200KB gzip, heap ≤80MB, paint ≤4ms | Lighthouse + DevTools (ver §5) |
| DC11 | Smoke regression 30/30 cumulative S0+S1 pass + 20/20 S2-specific = 50/50 | Smoke protocol §8 |
| DC12 | Tag `sprint-2-complete` pusheado con todos DC1-DC11 ✅ confirmados | Git log |

---

## 4. Tablet UI implementation stack (D5 FROZEN — ADR-016)

> **FROZEN S2-S8. Cambio de stack → ADR obligatorio antes de implementar.**
> SSoT: `resources/sonar_tablet/web-src/package.json`

| Componente | Versión locked | Rol |
|---|---|---|
| **React** | 18.3 | UI framework core |
| **Vite** | 5.x | Build tool + HMR |
| **TypeScript** | strict mode | Type safety |
| **Tailwind CSS** | v4 `@theme` | Utility tokens |
| **shadcn/ui** | dark-only preset | Component primitives |
| **Framer Motion** | 11 | Motion signature animations |
| **Lucide React** | latest | Iconografía (S2 — custom icons S3+) |
| **Recharts** | latest | Charts (Bank historial gráfico) |
| **React Context + useReducer** | built-in | State management (NO Zustand) |

**Anti-patterns stack:**
- ❌ NO Zustand, NO Redux, NO Jotai — Context+useReducer ONLY.
- ❌ NO CSS-in-JS runtime (styled-components/emotion) — Tailwind ONLY.
- ❌ NO Tailwind v3 `theme.extend` — usar Tailwind v4 `@theme` CSS-native.
- ❌ NO light mode components — shadcn/ui dark preset ONLY.
- ❌ NO `@tailwind base/components/utilities` deprecated — v4 `@import "tailwindcss"`.

**Pinning policy (decisión S2.0 founder-AI):** caret-minor (`^X.Y.Z`) aceptable — `package-lock.json` garantiza reproducibilidad lockfile. Major version bump (e.g., React 18→19, Vite 5→6, Tailwind 4→5) requiere ADR firmable obligatorio. Minor security updates auto-aplicables vía `npm audit fix`.

**TypeScript strict mandatory (S2.1 setup task — ADR-016 D5):**

```jsonc
// resources/sonar_tablet/web-src/tsconfig.app.json — REQUIERE bump S2.1
{
  "compilerOptions": {
    "strict": true,                    // ← AÑADIR
    "noUncheckedIndexedAccess": true,  // ← AÑADIR
    "noUnusedLocals": true,            // ya presente
    "noUnusedParameters": true,        // ya presente
    "noFallthroughCasesInSwitch": true // ya presente
  }
}
```

**Estado actual scaffold (verify pre-S2.1):** `tsconfig.app.json` actual NO tiene `strict` ni `noUncheckedIndexedAccess` — habilitar como primera task S2.1 ANTES de cualquier `.ts/.tsx` de app code.

**shadcn/ui CLI install pattern (S2.1):** `npx shadcn@latest init` con preset `--base-color=neutral --css-variables` + override post-init en `globals.css` referenciando tokens D1 (`--sonar-black`/`--sonar-orange`/`--sonar-white`). Components installer per-componente: `npx shadcn@latest add button dialog dropdown-menu` etc.

---

## 5. NUI performance budgets (D6 — ADR-016)

> **Límites hard. Si se supera cualquiera → blocker para DC10.**
> Referencia completa: `docs/design/02_sonar_tablet.md` v1.3 IDENTITY V3 LOCK NOTICE §NUI performance.

| Métrica | Budget hard | Herramienta verificación |
|---|---|---|
| **Frame paint time** | ≤4ms / frame (60fps target) | Chrome DevTools Performance tab |
| **JS bundle** | ≤500KB gzipped | Network tab / Vite build output |
| **CSS bundle** | ≤200KB gzipped | Network tab / Vite build output |
| **Heap memory** | ≤80MB peak | Chrome DevTools Memory tab |
| **App load lazy** | Obligatorio per app (Bridge/Bank/Map cargan on-demand) | Bundle analyzer |
| **Animaciones** | GPU-only (`transform`, `opacity`) — NO `layout` properties | DevTools Layers panel |
| **Listas largas** | `react-window` virtualization si >50 items | Código review |
| **Brand SVGs** | ≤8KB per SVG | File size check |
| **Bundle analyzer** | inspección visual chunks | `vite-bundle-visualizer` (devDep S2.1) |

**Note D6 vs `06_fivem_standards.md` §2.3:** ADR-016 D6 budgets son **STRICTER** que `06_fivem_standards.md` §2.3 NUI table actual (paint <16ms, heap <150MB, bundle <1MB). ADR-016 supersedes per `02_decision_log_part2.md` §Impact "🟡 cross-link D6 NUI perf budgets como standard FiveM client-side". **Sync rewrite `06_fivem_standards.md` §2.3 deferred a próximo docs cycle post-S2** (out of scope this session).

---

## 6. Dark-only UI patterns (ADR-016 D3)

> **3-color strict. Sin excepciones en producto.**
> SSoT: `docs/art/branding/01_brief_logo.md` v3 §4.1.

```css
/* Tailwind v4 @theme tokens — ÚNICO origen colores producto */
@theme {
  --sonar-black:  #060607;  /* Canvas base TODA superficie producto */
  --sonar-orange: #FF5100;  /* Brand signal: logo CTAs focus rings alerts */
  --sonar-white:  #FAFAFA;  /* Foreground: texto icons labels */
}
```

**Reglas implementación:**
- `bg-sonar-black` = TODA superficie producto (canvas, cards, modales, drawers).
- `text-sonar-white` = TODA tipografía + iconografía UI.
- `text-sonar-orange` / `border-sonar-orange` / `ring-sonar-orange` = brand accent (CTAs, focus rings, active states, alerts críticos).
- ❌ NO `bg-white`, `bg-gray-*`, `bg-slate-*` en ningún componente producto.
- ❌ NO teal `#2DD4BF` / `#175A5F` en product surfaces (deprecated post-ADR-016 D1).
- Glassmorphism: `backdrop-filter: blur(16px)` + `border: 1px solid rgba(250,250,250,0.08)` en modales SOLO.
- Excepción única: `monogram_s_black.svg` en contexto print/external NON-product.

**❌ Tailwind classes prohibidas en producto (CI grep blocker S2.7):**

- `bg-white`, `bg-black`, `bg-slate-*`, `bg-zinc-*`, `bg-gray-*`, `bg-neutral-*`, `bg-stone-*`.
- `text-gray-*`, `text-slate-*`, `text-zinc-*`, `text-neutral-*` — usar `text-sonar-white/60` (alpha opacity para emphasis semantic).
- `dark:` prefix — NO existe light mode → modificador no-op + ruido visual code review.
- Hexes literales `#fff` / `#000` / `rgb(...)` en `style=` props — siempre via token.
- `from-*-via-*-to-*` gradients multi-color (T3 prohibited per ADR-016 D4).

**✅ Permitidos (alpha layers semánticos):**

- `bg-sonar-white/5`, `bg-sonar-white/10`, `bg-sonar-white/15` — surface elevation tonal sin nuevo color.
- `border-sonar-white/10`, `border-sonar-white/20` — divisores sutiles.
- `text-sonar-white/40`, `text-sonar-white/60`, `text-sonar-white/80` — emphasis hierarchy via opacity.
- `ring-sonar-orange/40` — focus rings glow.

**Audit S2.7 spec:** smoke S2.16 verifica computed `background-color` de cada elemento renderizado matchea uno de los 3 hexes canonical o alpha-layer de uno de ellos. NO matches arbitrarios.

---

## 7. Session breakdown S2

| Sesión | Label | Contenido principal | Modelo sugerido (founder decide swap) |
|---|---|---|---|
| S2.0 | Planning gate | Finalizar este doc v1.0 post Phase 10 ✅ + DC1-DC11 review + 11 pre-flags resueltos + smoke ×50 protocol + risks refined | Opus 4.x ✅ DONE |
| S2.1 | Tablet scaffold setup | tsconfig strict + noUncheckedIndexedAccess enable + Vite config verify + shadcn CLI init dark-only + tokens `globals.css` (`--sonar-black/--sonar-orange/--sonar-white`) + Lucide install + Framer install + index.html boot + dark canvas baseline + bundle-analyzer devDep | Cascade Sonnet |
| S2.2 | Tablet shell + keybind | React shell App.tsx router skeleton + keybind TAB `client.lua` + NUI bridge events Lua↔NUI + open/close animation Framer Motion | Cascade Sonnet |
| S2.3 | Bridge home + routing | App grid 12 apps + lazy-load router + motion entrance Framer Motion | Cascade Sonnet |
| S2.4 | Bank app | Balance display + historial + transfer form + `sonar:bank:*` events integration | Cascade Sonnet |
| S2.5 | Map app | GPS marker render frame-rate + POI nodes admin-defined + bridge ad-hoc `sonar:tablet:map:getNodes` (DEFERRED catalog promotion S3) | Cascade Sonnet |
| S2.6 | Motion + Sound | 5 Framer Motion animations locked + 5 SFX canonical integration + perf audit | Cascade |
| S2.7 | Polish + perf | NUI budget verification (DC10) + CSS token audit (DC3/DC4) + regression | Cascade |
| S2.8 | Smoke regression | 30/30 cumulative + 15-20 S2-specific pasos (§8 protocol) + DC review | Founder local + Cascade debug |
| S2.9 | Close + retro | Tag `sprint-2-complete` + SESSION_LOG + SPRINT_RETRO_S2 + next sprint seed | Cascade |

**Duración estimada:** 10 sesiones × ~3-4h = ~30-40h total. ~4 semanas calendario (1 sesión/día pace).

**Model swap policy (regla permanente founder S1.10.4):** AI no cambia modelo unilateralmente. "Modelo sugerido" = sugerencia AI, founder decide trigger swap. Recomendaciones AI post-session OK, no auto-swap.

---

## 8. Smoke check protocol S2 (×20)

> **Gate de cierre S2.** Todos deben pasar antes de `sprint-2-complete` tag. Cumulative includes S0+S1 30 steps.

### 8.1 Regression S0+S1 (30 pasos — unchanged from sprint-1-complete tag)

Ver `docs/qa/01_testing_protocol.md` + `progress/SPRINT_RETRO_S1.md` §smoke steps. Ejecutar todos 30/30 post-Phase-8+9 con nuevo namespace `sonar_bank`/`sonar_core`/`sonar_bridges`.

### 8.2 S2-specific smoke (20 pasos nuevos)

| # | Test | Expected result |
|---|---|---|
| S2.1 | Boot fxserver clean post-Phase-8+9 | Console clean, 0 errors |
| S2.2 | `sonar_tablet` resource loads | `[sonar_tablet] Started` en console |
| S2.3 | Player joins server | Tablet NOT visible (closed default) |
| S2.4 | Press TAB | Tablet opens, `panel_open` SFX plays, entrance animation plays |
| S2.5 | Press TAB again | Tablet closes silent (decisión S2.0: NO close SFX dedicated — Apple Pro pattern), no SFX double-trigger, exit animation plays |
| S2.6 | Open Tablet → Bridge home visible | App grid renders, dark canvas only |
| S2.7 | Click Bank app icon | Bank app opens con lazy-load, `layer_dive` SFX |
| S2.8 | Bank balance loads | IBAN + saldo real player correcto |
| S2.9 | Bank historial loads | ≥1 transaction visible (from S1 smoke transfers) |
| S2.10 | Bank: transfer 100€ A→B | Form submit → `depth_press` SFX → success state |
| S2.11 | Bank: verify B received | Login B, check balance +100€ |
| S2.12 | Open Map app | Map renders, player marker visible |
| S2.13a | Move player | GPS marker updates frame-rate cliente ≥30 fps (sin lag perceptible local) |
| S2.13b | Open Map after spawn | POI nodes response `sonar:tablet:map:getNodes` ≤500ms request→render |
| S2.14 | POI placeholder admin-defined visible | Marker "Granja" placeholder admin-seed visible vicinity (real `sonar_granja` node S7+ roadmap) |
| S2.15 | CSS audit: no white | Inspect DOM + grep src: 0 ocurrencias `bg-white`/`bg-gray-*`/`bg-slate-*`/`bg-zinc-*`/`bg-neutral-*`/`bg-stone-*`/`dark:` prefix |
| S2.16 | Color audit: 3-color | Computed `background-color` opaque values matchean solo `#060607`/`#FF5100`/`#FAFAFA`; alpha-layers permitidos solo si base color es uno de los 3 |
| S2.17 | JS bundle size | Network tab: main chunk ≤500KB gzip |
| S2.18 | Frame rate | Performance profiler: ≥55fps during animation (no jank) |
| S2.19 | Memory | DevTools Memory: heap ≤80MB peak after 5min gameplay |
| S2.20 | Full round-trip | IBAN transfer A→B→A: balances zero-sum, historial 2 entries each |

**Total cumulative S2 close:** 30 (S0+S1 regression) + 20 (S2-specific) = **50 pasos**.

---

## 9. Risk register S2 (refined post-S2.0)

| # | Riesgo | Probabilidad | Impacto | Mitigación | Owner mitigation |
|---|---|---|---|---|---|
| R1 | Tailwind v4 `@theme` + shadcn/ui dark-only override conflict (CSS variables collision o preset incompatibility) | Media | Medio | S2.1 spike pre-app-code: scaffold básico → `npx shadcn add button` → verify dark canvas + tokens override OK; rollback a Tailwind v3 LTS path documentado fallback. | Cascade S2.1 |
| R2 | NUI bundle >500KB (deps pesadas Framer + Recharts + shadcn) | Media | Medio | Tree-shake imports puntuales (NO `import * as X`); lazy-load apps via `React.lazy()`; `vite-bundle-visualizer` pre-merge cualquier PR S2.2+. | Cascade per-PR |
| R3 | TAB keybind conflicto otro resource (lb-phone u oxinventory) | Baja | Bajo | Configurable keybind `Config.TabletKeybind` en `config.lua` + `disable-override` flag + grep `RegisterKeyMapping` cross-resource pre-S2.2. | Cascade S2.2 |
| R4 | Framer Motion jank FiveM Chromium embebido (CEF version old) | Media | Medio | GPU-only `transform`/`opacity` ONLY; nunca animar `height`/`width`/`margin`/`padding`/`top`/`left`; test in-server FiveM real S2.6 antes merge motion signature. | Cascade S2.6 + founder local |
| R5 | Consumer pattern temporal Bank historial (DB query directo §2.2.3) crea tech debt al ship C003 S3 | Media | Bajo | Wrapper function `getHistoryDirect()` en NUI bridge S2 — al ship C003 S3, swap implementation interno sin cambiar NUI contract; documented TODO en código. | Cascade S2.4 |
| R6 | TypeScript strict habilitado tarde rompe app code S2.4-S2.6 ya escrito | Baja | Medio | S2.1 task #1 obligatoria: `strict: true` + `noUncheckedIndexedAccess: true` ANTES cualquier `.tsx`. CI tsc check pre-merge. | Cascade S2.1 |
| R7 | NUI heap >80MB durante 5min gameplay (memory leak React subscriptions / event listeners no cleanup) | Baja | Medio | Strict mode React + `useEffect` cleanup discipline + DevTools Memory snapshot S2.7 perf audit + smoke S2.19. | Cascade S2.7 |
| R8 | `02_events_catalog.md` v1.2 quita C003 sin reflejar bridge §2.2.3 ad-hoc — confusion AI agents futuras | Baja | Bajo | NOTICE explícita en `04_api_contracts.md` C003 entry indicando bridge `sonar:tablet:bank:getHistory` consumer pattern temporal hasta S3 ship — sync docs cycle post-S2. | Founder docs cycle post-S2 |

**Escalation triggers (founder notify si):**

- R1 fallback Tailwind v3 LTS necesario → ADR firmable hotfix path.
- R2 bundle exceed 500KB irreducible post tree-shake → ADR negociar D6 budget revisable.
- R4 Framer jank irrecuperable en motion signature → ADR negociar motion library swap (CSS-only fallback).
- R6 strict mode habilitado tarde + breakage masivo → rollback strict + ADR firmable defer post-MVP.

---

## 10. Model allocation

| Sesión | Tarea | Modelo recomendado | Razón |
|---|---|---|---|
| S2.0 | Planning finalization | Opus 4.x | Strategic reasoning + critical review long context (✅ done this session) |
| S2.1 | Tablet scaffold setup | Sonnet 4.6 | Setup deterministic + tooling install |
| S2.2-S2.5 | Feature dev (NUI) | Sonnet 4.6 | Code velocity + JS/React precision |
| S2.6 | Motion + Sound | Sonnet 4.6 ó Opus 4.x | Creative precision + Framer Motion patterns |
| S2.7 | Perf audit | Opus 4.x ó Sonnet 4.6 | Análisis profile + fixes targeted |
| S2.8 | Smoke debug | Sonnet 4.6 + founder local | Founder local execution + AI debug pair |
| S2.9 | Close + retro | Sonnet 4.6 | Docs precision + SESSION_LOG entry |

**Reminder regla permanente founder:** AI no cambia modelo unilateralmente. Sugerencia AI post-session OK, decisión swap = founder.

---

## 11. Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 0.1-draft | 2026-05-04 | Founder + Cascade (S1.10.5 Item H) | Documento creado PRE-DRAFT. Scope ADR-015 UI-heavy (DC×12) + stack D5 FROZEN (ADR-016) + perf budgets D6 + dark-only patterns D3 + session breakdown S2.0-S2.9 + smoke protocol ×50 cumulative + risk register R1-R6 + model allocation. Pendiente finalizar a v1.0 post Phase 8+9+10 execution + smoke ✅. |
| **1.0 (firmable)** | 2026-05-04 | Founder + Cascade (S2.0 planning gate review crítico) | **🟢 FIRMABLE.** S2.0 review crítico DC1-DC11 + smoke ×50 + 11 pre-flags resueltos. Cambios principales: (a) §0 status table — todos gates ✅ post-Phase-8+9+10 + B5 tags pushed. (b) §2.2 split en 3 categorías (keybinds cliente / callbacks shipped S1 / NUI bridges ad-hoc DEFERRED catalog promotion S3) — alinea ADR-015 línea 1162 consumer pattern temporal Bank historial; ya no mezcla conceptos events/callbacks/keybind. (c) §3 DC table refine: DC6 explicita consumer pattern temporal C003-deferred-S3, DC7 split en DC7a (frame-rate cliente ≥30 fps) + DC7b (POI backend ≤500ms), DC9 close = silent decision. (d) §4 stack — añadida pinning policy caret-minor + tsconfig strict mandatory task explícita S2.1 con diff jsonc + shadcn CLI install pattern. (e) §5 perf budgets — añadida `vite-bundle-visualizer` row + nota D6 supersedes `06_fivem_standards.md` §2.3 (sync deferred post-S2). (f) §6 dark-only — añadida blacklist Tailwind classes explícita (CI grep blocker) + permitidos alpha-layers `text-sonar-white/N`. (g) §7 S2.1 re-purpose `Phase 8+9 execution` (obsoleto, ya done) → `Tablet scaffold setup` con setup tasks claras. (h) §8.2 smoke refine: S2.5 close silent, S2.13 split S2.13a+b (GPS local vs POI backend), S2.14 POI placeholder admin, S2.15 grep blacklist explícita, S2.16 alpha-layers permitidos. (i) §9 risk register full rewrite R1-R8 (R1 obsoleto removed → R1' Tailwind+shadcn override; +R5 consumer pattern tech debt; +R6 TS strict mode timing; +R7 NUI heap leak; +R8 docs sync C003) + escalation triggers founder. (j) §10 model allocation refined + reminder regla permanente founder no AI auto-swap. **11 pre-flags resueltos via founder "lo más recomendable, tú sabes mejor que yo" delegation:** F1 consumer pattern, F2 S2.1 re-purpose, F3 R1 replace, F4 §2.2 split, F5 caret-minor pinning, F6 D6 supersedes nota, F7 DC7 split, F8 close silent, F9 Tailwind blacklist, F10 tsconfig strict task, F11 NEW tsconfig task explícita. **🟢 v1.0 firmable, S2.1 desbloqueado.** |

---

*"La señal emerge cuando el sistema está listo."*

**FIN DEL DOCUMENTO `progress/SPRINT_PLAN_S2.md` v1.0 (firmable — S2.0 planning gate complete, S2.1 desbloqueado)**
