# 🌊 SONAR — Art Direction (Studio + Ecosystem)

> **Versión:** **3.0-locked** (post-ADR-016 — palette tokens canónicos + dark-only doctrine + 3-color strict + trend stack tiered + Tablet UI stack frozen + NUI perf budgets).
> **Documento padre:** `00_PRODUCT_BIBLE.md` (post v1.5 bump pendiente Item E).
> **Documentos hermanos:** `02_sonar_tablet.md` v1.3 (post bump Item D) · `01_node_farm.md` (purge pendiente Phase 7).
> **ADR origen:** `planning/02_decision_log.md` ADR-011 (rebrand foundational) **+ ADR-012 (refinement amendment) + ADR-016 (identity v3 doctrine — `02_decision_log_part2.md` v1.0)**. Lectura conjunta obligatoria.
> **SSoT canonical palette:** `@docs/art/branding/01_brief_logo.md` v3 §4.1 (3 tokens canonical Black/Orange/White).
> **Reemplaza:** `docs/_archive/01_art_direction_v1_admirals.md` (v1.0 Admirals/Almirantazgo, archivado 2026-05-03).
> **Estado:** 🟢 **FIRMABLE** — palette + dark-only + stack frozen + perf budgets locked post-ADR-016. Phase 4.5 v2 briefs (icons/sound/motion/marketing) y Phase 5+ rewrites quedan post-MVP S2.

> **Lectura previa obligatoria:** ADR-011 + ADR-012 + **ADR-016 D1+D2+D3+D4+D5+D6**. **NO leer `_archive/01_art_direction_v1_admirals.md` para implementación SONAR — está deprecated.**

---

## 🟢 IDENTITY V3 LOCK NOTICE (per ADR-016, 2026-05-04)

**Este NOTICE es la capa canónica más reciente.** Supersedes NOTICE r6 (ADR-012) + scaffold-r1..r7 inline §1-§20 en cualquier conflicto. Lectura obligatoria ANTES de cualquier implementación visual product UI.

### Precedencia (top → bottom)

1. **🟢 IDENTITY V3 LOCK NOTICE** (este — post-ADR-016 D1-D6).
2. **🔄 REFINEMENT NOTICE r6** (post-ADR-012 — preservada para contexto histórico voice/metaphor/iconografía/sound naming).
3. **§1-§20 inline scaffold-r1..r7** (legacy contenido — referencia técnica tokens motion/typography/storybook/shaders preservados; pero palette + theme + stack + perf override por v3.0).

### NEW CANONICAL v3.0 — vigente desde 2026-05-04

#### Palette tokens — 3 colores canónicos LOCKED (ADR-016 D1)

> **SSoT:** `@docs/art/branding/01_brief_logo.md` v3 §4.1. Esta tabla replica el SSoT — si conflicto, gana brief v3.

| Token | Hex | Rol | Uso |
|---|---|---|---|
| `--sonar-black` | `#060607` | **CANVAS BASE** dark-only product | Background TODA superficie product (Tablet NUI, marketing web, hero, splash). |
| `--sonar-orange` | `#FF5100` | **SIGNAL / BRAND PRIMARY** | Logo identity, CTAs primary, focus rings, alerts críticos, signal active states, marketing accent único. |
| `--sonar-white` | `#FAFAFA` | **FOREGROUND / PURE** | Texto primario sobre Black, iconografía Lucide, surfaces alpha layers high-emphasis. |

**Implementación:** Tailwind v4 `@theme` directive (per D5 stack) + CSS custom properties. **NUNCA hardcodear hex** — siempre via token.

**Tokens DEPRECATED v2 (purgados v3.0 — ignorar ocurrencias §1-§20 + NOTICE r6):**
- ❌ `--sonar-bright` `#2DD4BF` (teal Tier B v2) — ELIMINADO post ADR-016 D1.
- ❌ `--sonar-pulse` `#14E5DD` — ELIMINADO.
- ❌ `--sonar-glow` `#5EEAD4` — ELIMINADO.
- ❌ `--abyss-black` `#03070A` — REPLACED por `--sonar-black` `#060607`.
- ❌ `--crew-100` `#F0F4F4` — ELIMINADO (no light canvas product).
- ❌ Crew neutrals tier (#B8C5C5 / #6B7878 / #2A3438) — ELIMINADOS.
- ❌ `--coloro-support` `#175A5F` — ELIMINADO (Tier C structural support v2 obsoleto).
- ❌ Signal functional tier (Critical #F87171 / Warn #FBBF24 / OK #34D399 / Info #60A5FA) — ELIMINADOS post ADR-016 D3 3-color strict. Estados se comunican via Lucide icons + typography weight + motion (no via color).

#### Theme — DARK-ONLY DOCTRINE PRODUCT (ADR-016 D2)

- **Tablet UI (in-game NUI):** **dark-only**. NO toggle light/dark. NO media query `prefers-color-scheme: light` honor.
- **Marketing web (futuro):** dark-only consistent con product.
- **Excepción única:** `monogram_s_black.svg` permanece como variante print/external (impresión papelería formal, fondos blancos third-party donde dark monogram es ilegible). **NO uso product UI** (resolución D-S1.10E-A).
- **Justificación:** identity v2 (ADR-012 D2) hybrid theme dark+white surfaces DEPRECATED. v3 endurece a 100% product Black canvas + excepción print única.
- **Reemplaza ratios scaffold + NOTICE r6:**
  - ❌ DEPRECATED `~30-40% dark + ~30-40% white surfaces + ~10-15% Sonar Bright + ~10% Coloro + <5% signals` (NOTICE r6 hybrid).
  - ❌ DEPRECATED `60% canvas abyss + 25% crew + 10% coloro + 5% signals` (scaffold-r1).
  - ✅ CANONICAL v3.0: **100% dark-only product** + Orange brand identity siempre + White foreground texto.

#### Color count — 3-COLOR STRICT (ADR-016 D3)

- Producto NO añade colores adicionales (NO green success, NO red error, NO yellow warning, NO blue info).
- Estados se comunican via:
  - **Iconografía Lucide** (`<CheckCircle2/>` success, `<AlertTriangle/>` warning, `<XCircle/>` error, `<Info/>` info).
  - **Typography weight + opacity** (semantic emphasis sin color).
  - **Layout / motion** (shake on error, fade-in on success, pulse on alert).
  - **Orange como único accent semántico** (CTAs primary, alerts críticos, signal active).
- **Re-evaluable post-MVP S2** si UX research / playtesting reveals friccion semantic genuine → ADR-XXX 4ª color (probable red `#E63946`).
- Esta restricción endurece NOTICE r6 hybrid 5-tier — todas las demás "tiers" eliminadas.

#### Trend stack 2026 — TIERED T1/T2/T3 (ADR-016 D4)

Stack tecnológico classification para adopción priorizada visual + technical:

- **T1 (oficial — adopt heavy):** Bento Grid layout, Microinteractions Framer Motion, Glassmorphism selectivo (chrome layer only — NO content cards), Focus glows orange (a11y + brand), Smooth springs, Animated data viz (sparklines + counters Recharts), Geist Sans + Inter Tight + Geist Mono typography.
- **T2 (selective — case-by-case approval):** Aurora gradients (hero/transitions only — NO product UI), Kinetic type (marketing only), Cmd+K palette (post-MVP S3+), Spatial depth shadows (low-emphasis only).
- **T3 (prohibited — DO NOT use):** Skeuomorphism, Brutalist Y2K, Multi-color gradient overload, Heavy Lottie animations, Heavy parallax scroll, Neon glow excess, Backdrop-blur en cards content (chrome only), Multiple accents simultáneos, Material Design 2 raised buttons.

#### Tablet UI implementation stack — FROZEN S2-S8 (ADR-016 D5)

> **SSoT:** `@resources/sonar_tablet/web-src/package.json` (downgraded post S1.10.5 Item A para reflejar D5 spec exacto).

Stack inmutable durante Sprint 2-8 (Oleada 1 completa):

- **Framework:** React 18.3 (NO React 19 durante S2 aunque ship stable mid-sprint).
- **Build:** Vite 5.x (pin `^5.4.0` package.json, NO Vite 6+ hasta post-Oleada 1).
- **Lang:** TypeScript strict (`"strict": true` tsconfig + `noUncheckedIndexedAccess: true`).
- **Styling:** Tailwind CSS v4 con `@theme` directive (NO v3 fallback). Tokens en `tailwind.config.ts` referenciando D1 paleta canonical.
- **Components:** shadcn/ui (CLI install per-component, dark-only variant baseline).
- **Motion:** Framer Motion 11.
- **Icons:** Lucide React (NO emoji, NO custom SVG salvo brand assets `@art/branding/logo_v3/*`).
- **Charts:** Recharts (sólo si Tablet apps requieren visualización data — Bank app candidato S3).
- **State:** React Context + `useReducer` Sprint 2 (NO Zustand / Redux salvo gap real S3+).
- **NUI Bridge:** lb-phone NUI message API per `@resources/sonar_tablet/*` setup S0.

**Cambios stack durante S2-S8 → ADR firmable obligatorio.**

#### NUI performance — HARD CONSTRAINTS (ADR-016 D6)

Budgets de obligatorio cumplimiento cliente FiveM (60 FPS target):

- **Frame budget Tablet UI:** ≤ 4ms paint per frame (target 60 FPS = 16.67ms total budget; 75% reservado al juego).
- **Bundle size production:** ≤ 500KB JS gzipped (initial load), ≤ 200KB CSS gzipped.
- **Memory ceiling NUI:** ≤ 80MB heap (Chrome devtools profile).
- **Lazy-loading obligatorio:** rutas Tablet apps (Bank, Map, Phone) via `React.lazy()` + Suspense. Initial bundle = shell + Home only.
- **Animaciones:** GPU-only (`transform`, `opacity`). Prohibido animar `width/height/top/left/margin/padding`.
- **Re-render guard:** componentes lista (transactions, contacts) MUST `React.memo` + virtualization si >50 items (react-window).
- **Asset budget:** brand SVGs ≤ 8KB cada uno (verificable export tool `@art/tools/logo_export/export.mjs` warn threshold).
- **Performance test:** Sprint 2 setup incluye Chrome DevTools Performance profile baseline + regression check pre-merge cualquier PR Tablet UI.

#### Logo system v3 — FIRMABLE (`@art/branding/logo_v3/`)

- **Inventario firmado:** 4 monogramas SVG (`monogram_s.svg` + `_solid` + `_white` + `_light`) + 1 excepción print (`_black`) + wordmark Geist + 2 lockups + preview HTML + export pipeline.
- **Pipeline export:** `@art/tools/logo_export/export.mjs` (Node.js + Puppeteer) genera PNG @1x/@2x/@3x multi-density (16-1024px).
- **Brief firmable:** `@docs/art/branding/01_brief_logo.md` v3 (post Item B bump S1.10.5).
- **Excepción print/external:** `monogram_s_black.svg` Black sobre fondos blancos third-party (NON-product). Resolución D-S1.10E-A.

### Cómo leer el resto del documento (post-v3.0)

1. **Lee primero IDENTITY V3 LOCK NOTICE (este) + ADR-016.**
2. **Lee NOTICE r6 (debajo) para context histórico** voice/metaphor/iconografía/sound naming canonical (preservado vigente, NO supersedido por v3.0 en esos aspectos).
3. **§1-§20 inline scaffold:** tokens técnicos siguen válidos para motion specs ms-precise, type scale, storybook, shaders, governance. **Override v3.0:** palette + theme + stack + perf budgets — gana esta NOTICE.
4. **Si hay duda interpretación → ADR-016 manda.**

---

## 🔄 REFINEMENT NOTICE r6 (per ADR-012, 2026-05-03)

**Este documento contiene scaffold-r1..r5 escrito interpretando SONAR con metáfora literal-submarino-militar + dark-extremo + voz capitán. ADR-012 refina esa interpretación.** Las secciones NO han sido reescritas surgicalmente todavía (Phase 4.5 v2 hará rewrite full); en lugar de eso, **este aviso top-level establece la interpretación canónica vigente**. En cualquier conflicto entre lo siguiente y el contenido §1-§20 abajo, **gana este aviso + ADR-012**.

### NEW CANONICAL — vigente desde 2026-05-03

#### Metáfora — ABSTRACTA PURA (ADR-012 §D1)

- **SONAR ES:** profundidad como fuerza simbólica. Valor oculto bajo capas. Calma metódica al descender. Exploración paciente. Patterns que emergen al observar con atención. Claridad bajo presión. Acrónimo SOund Navigation And Ranging interpretado **metafórico, no literal**: el producto "ve escuchando" la economía, no es hardware acústico.
- **SONAR NO ES** (purga explícita — ignorar ocurrencias en §1-§20):
  - Submarino militar literal (silhouettes/perfiles).
  - Hardware de señal acústica: hydrophones, sonar pings (radio/frecuencia), waveforms, oscilloscope, instrument-panels concretos.
  - Armamento submarino: torpedos, depth charges, missile bays.
  - Equipo de cubierta literal: periscopios, bridge-as-command-center militar, hatches, casco con remaches, crew submarino.
  - Voz/personaje militar: "silent service", "capitán submarino nuclear", "comandante", "almirante", "a bordo", "tripulación", "tactical".

#### Theme — SINGLE HYBRID DARK + WHITE SURFACES (ADR-012 §D2)

- **NO dark-mode-extremo 60% canvas abyss.** Reemplaza ratio scaffold-r1.
- **Single hybrid theme** (un solo theme, balance interior): canvas oscuro principal + paneles/cards/surfaces blancos o off-white selectivos.
- **Nuevas proporciones meta:**
  - **~30-40%** deep surfaces (canvas dark — Abyss/Depths Tier A reduced).
  - **~30-40%** white/off-white surfaces (panels, cards, content areas — **NEW Tier**).
  - **~10-15%** Sonar Bright `#2DD4BF` identity (Tier B preserved — funciona AAA dark + AA+ light).
  - **~10%** structural support Coloro `#175A5F` (Tier C preserved).
  - **<5%** signal functional (preserved).
- **Refs convergentes:** Notion (dark canvas + white content panes), Arc Browser (dark chrome + light content), Stripe Dashboard (dark sidebar + white workspace), Linear (dark canvas + white modal/cards selectivos), GitHub dark mode mixed surfaces.
- **Glassmorphism preserved** signature pero pierde exclusividad dark — puede aplicar tinte sutil sobre surfaces blancos también.

#### Voz — NEUTRAL PREMIUM-TECH (ADR-012 §D3)

- **Eliminar TODO arquetipo militar/submarino.** Cero "silent service", "capitán", "comandante", "almirante", "a bordo", "tripulación", "tactical", "operación naval".
- **Tono retenido:** preciso, confiado, terse, calmo, professional, atemporal.
- **Estilo referencia copy:** Vercel docs, Linear copy, Stripe docs, Apple Pro apps. Premium-tech moderno sin personaje fictício.
- **Ejemplos voz canónica r6:**
  - ✅ *"SONAR maps your economy. Every transaction logged."*
  - ✅ *"Hear the depth. Understand the patterns."*
  - ✅ *"Console activated. Ready."*
  - ✅ *"Transfer received: 1,240€ — entry FARM-2026-0042."*
  - ❌ *"Console SONAR activada. Profundidad operativa."* (era voz capitán scaffold-r1..r5).
  - ❌ *"Contacto detectado: transferencia recibida en eco SONAR."* (literal sub-acoustic — superseded).

#### Iconografía — ABSTRACT-PROFUNDIDAD (ADR-012 §D1)

- **Conservados de scaffold-r5 (3/8):**
  - `depth-gauge` (medidor profundidad — concept abstract OK).
  - `pressure-hull` **reconceptualizado**: ya NO casco submarino con remaches. Ahora = **capas de profundidad concéntricas / contención abstract** (estilo geological strata, NOT metal hull).
  - `bioluminescence` (luz bajo presión, valor emergiendo — abstract).
- **Purgados de scaffold-r5 (5/8 — DEPRECATED, NO usar):**
  - ❌ DEPRECATED `sonar-ping` (ondas concéntricas radio/frecuencia).
  - ❌ DEPRECATED `submarine` (silueta literal).
  - ❌ DEPRECATED `hydrophone` (mic acústico militar).
  - ❌ DEPRECATED `periscope` (equipo sub literal).
  - ❌ DEPRECATED `torpedo-bay` (armamento militar).
- **Nuevos a definir Phase 4.5 v2 (5 candidatos preliminares):**
  - `descent-layers` (capas descendiendo).
  - `signal-clarity` (patrón emergiendo de ruido).
  - `depth-grid` (grid profundidad isométrica).
  - `observation-field` (campo observación — sustituye periscope para "view/monitor").
  - `lineage-trace` (línea uniendo nodos — sustituye torpedo-bay para "logística/dispatch").

#### Sound naming — neutral (ADR-012 §D3 spillover)

- Todos los SFX `sonar_*` scaffold-r1 nombres deprecated → renamed neutral (mapping canonical post-ADR-012):
  - **DEPRECATED `sonar_ping`** → **CANONICAL `signal_emerge`** (notif primaria — sonido patrón emergiendo, no ping radio).
  - **DEPRECATED `sonar_pressure`** → **CANONICAL `depth_press`** (firma/confirm — peso descendiendo).
  - **DEPRECATED `sonar_depth`** → **CANONICAL `layer_dive`** (escritura/dive UI).
  - **DEPRECATED `sonar_console`** → **CANONICAL `console_tap`** (premium click).
  - **DEPRECATED `sonar_hatch`** → **CANONICAL `panel_open`** (open modal — sin "hatch" submarino).
- Nombres finales lock Phase 4.5 BRIEF-SOUND-001 v1 (ya delivered).

#### Glossary cleanup (ADR-012 spillover §15)

- **Términos canonical r6** (cross-ref Bible v1.4 §15):
  - **Console** ✅ (genérico tech, no militar).
  - **Bridge** ❌ deprecated en sentido "command center militar" → re-interpretar como **"Tablet home view"** abstract genérico.
  - **Depth / Eco / Manifiesto / Bitácora / Signal / Lineage / Patrón** ✅ todos abstractos OK.
  - **Periscope / Hatch / Hydrophone / Ping / Sweep / Sumersión** ❌ deprecated literal. Sustituir cuando aparezca uso operativo.

### Cómo leer el resto del documento (§1-§20)

1. **Lee primero esta NOTICE r6 + ADR-012.**
2. **Tokens técnicos (paleta hex, tipografía, motion specs ms-precise, type scale, storybook, shaders, governance) siguen válidos** — lo que cambia es el "wrapping" metafórico/lingüístico, no los tokens medibles.
3. **Cuando encuentres referencias literales submarino-militar (DEPRECATED `sonar-ping` icon, "capitán submarino", "silent service", DEPRECATED `periscope`, DEPRECATED `torpedo`, DEPRECATED `hydrophone`), considéralas SUPERSEDED por esta NOTICE.** Phase 4.5 v2 + Phase 4 surgical full hará el surgical rewrite final.
4. **Si hay duda interpretación → ADR-012 manda.**

---

## ⚠️ Estado de este documento (transparencia)

Este es **foundational scaffolding** post-pivot SONAR (per ADR-011). Contiene:

- ✅ **Decisiones foundational firmes** (paleta hex, tipografía elegida, voz, sound naming, iconografía nombres).
- 🚧 **Detalle pendiente Phase 4**: nodo identity, marketing specs, governance, glossary completo, type scale tokens detallados, motion specs.
- ❌ **NO firmado** todavía. Firma requiere Phase 4 complete.

---

## 0. Resumen ejecutivo

Este documento es **la dirección artística oficial de SONAR**. Define cómo el ecosistema SE VE, SE SIENTE y SE OYE.

> **Tesis central (post-ADR-012):** SONAR no es un script. SONAR es **infrastructure premium-tech** que mapea, registra y coordina toda la actividad económica del ecosistema con la precisión de un instrumento que *"ve escuchando"* — metáfora simbólica de profundidad, NO submarino militar literal. Cuando un jugador abre el Tablet, encuentra una **command surface premium** — hybrid theme dark + white surfaces, identity bioluminescent teal Sonar Bright como firma. **Profundidad simbólica, calma metódica, claridad bajo presión.**

> **Lema:** *"Hear the depth."*

---

## 1. Filosofía SONAR — 10 principios S1-S10

| # | Principio | Significado práctico |
|---|---|---|
| **S1** | **La precisión es la nueva opulencia** | El lujo SONAR no se mide en oro — se mide en datos perfectos, alineamiento al píxel, tiempos al ms. |
| **S2** | **Identidad por nodo, coherencia por meta-brand** | Cada vertical es su mundo cultural. Meta-brand SONAR los une vía hub elements (Tablet OS, signal protocols). |
| **S3** | **Premium se siente en la precisión, no en el grito** | Bioluminescencia funcional permitida. Neón decorativo sin función prohibido. |
| **S4** | **3D rinde el sólido, el código rinde la magia** (Bible §13.4 preserved) | Modelos 3D = idea geométrica. Shaders/partículas/lighting/post-FX/motion → 100% código. |
| **S5** | **Bioluminescencia funcional, gradients holográficos jamás** | Glow OK como instrumento (sonar ping, focus ring). Glow decorativo / gradient holográfico → prohibido. |
| **S6** | **Motion como agua profunda — silenciosa, deliberada, con masa** | Spring physics damping. Cero rebote tipo web JS portfolio. |
| **S7** | **El silencio es diseño** | Sound intencional. SONAR habla poco; cuando habla, importa. |
| **S8** | **Tipografía como instrumento** | Geist Sans + Inter Tight + Geist Mono. Precisa como un sonar. |
| **S9** | **Estilo coherente cross-touchpoint** | Logo Tebex = Tablet juego = website = trailer. Una sola voz. |
| **S10** | **Detalle obsesivo siempre** (Bible Pillar 3 preserved) | Micro-interacciones, contextual loading, empty states con personalidad. |

### 1.2 Anti-references SONAR (lo que NO somos)

> **NOTE crítico:** anti-references **completamente diferentes** a v1.0 Admirals (que fueron invertidos por ADR-011).

| ❌ NO somos | Por qué |
|---|---|
| **Heritage retro-Almirantazgo XVII-XIX** | v1.0 deprecated por ADR-011. |
| **Submarino militar literal (silhouettes / periscopios / torpedos / hydrophones / sonar pings radio)** | DEPRECATED por ADR-012. SONAR es metáfora abstracta de profundidad, NO hardware submarino militar. |
| **Voz arquetipo militar ("silent service", "capitán submarino", "tactical-grade", "a bordo")** | DEPRECATED por ADR-012. Voz canonical = neutral premium-tech (Vercel/Linear/Stripe). |
| **Theme dark-extremo 60% canvas** | DEPRECATED scaffold-r1. Canonical hybrid theme: ~30-40% dark + ~30-40% white surfaces. |
| **Cyberpunk neón saturado loud** | Saturado FiveM. SONAR = precisión calmada. |
| **Material Design 2 plano genérico** | Sin alma, drop-shadows raised buttons feos. |
| **Skeumorphism RPG medieval** | Cuero sintético, scrolls. Tackier. |
| **Friendly cartoon flat illustrations** | SONAR es premium-tech infrastructure, no Notion-playful. |
| **Apple iOS clone literal** | Glassmorphism OK como signature selectivo pero stripped-down. |
| **Tactical operator masculino agresivo (CoD UI)** | Diferencia: neutral premium-tech vs tacticool loud. |
| **Gamer RGB neon backlit** | Lime gamer chillón, magenta, RGB rainbow → cero. |

### 1.3 Comparativa competidores FiveM 2026

| Aspecto | Prism | NoPixel-clones | 17 Movement | 0Resmon | **SONAR (post-ADR-012)** |
|---|---|---|---|---|---|
| Paleta | Lime + black + glow | Neón variado | Tactical orange + black | Off-white + soft blue | **Hybrid theme dark + white surfaces + Sonar Bright bioluminescent teal `#2DD4BF` (identity) + Coloro `#175A5F` structural support + glassmorphism panes selectivos** ⭐ |
| Mood | Tactical loud | RP serious dark | Ops urgent | Productivity | **Neutral premium-tech precision (Vercel/Linear/Stripe class)** ⭐ |
| Diferenciación | Genérico tactical | Variable | Genérico | Tool única | **Premium-tech infrastructure FiveM. Profundidad simbólica + hybrid theme + voz neutral. Cero arquetipo militar.** ⭐ |

---

## 2. La metáfora central — Profundidad simbólica abstracta (post-ADR-012)

### 2.1 ¿Por qué "profundidad"?

> **Profundidad como fuerza simbólica.** Metáfora abstracta inspirada en exploración abisal pero **NO submarino militar literal**. Combina **precisión tecnológica extrema** + **calma metódica al descender** + **autoridad por precisión del registro** + **claridad bajo presión** + **patterns que emergen al observar con atención**.

**¿Por qué encaja SONAR?**

- ✅ **Coordinación de información** — el sonar **simbólicamente ve escuchando**; SONAR ve la economía RP registrando cada eco transaccional con discreción y exhaustividad.
- ✅ **Registro meticuloso** — DB schema, audit trail, contratos, lineage = las **bitácoras del ecosystem**.
- ✅ **Autoridad por precisión** — somos infraestructura premium-tech neutral. Otorgamos credenciales precisas (IBANs, contratos, signal protocols).
- ✅ **Estética atemporal** — premium-tech moderno (Vercel/Linear/Stripe class) envejece bien. Cyberpunk neón no.
- ✅ **Diferenciación radical** — nadie en FiveM usa metáfora abstracta de profundidad simbólica con hybrid theme premium-tech.

> **Anti:** NO submarino militar literal, NO hardware acústico, NO armamento, NO equipo cubierta literal, NO voz/personaje militar. Ver §1.2 anti-references + ADR-012 D1.

### 2.2 Elementos del lenguaje "Profundidad simbólica" (post-ADR-012)

> **Refactor v1.0→r6:** elementos literal-submarino DEPRECATED. Reemplazos abstract-profundidad canonical.

| Elemento (canonical r6) | Uso visual | Ejemplos | Reemplaza (deprecated) |
|---|---|---|---|
| **Descent layers (capas descendiendo)** | Logo concept candidate, drill-down nav, app icons | Logo monogram exploration, lineage visualization | DEPRECATED "Sonar ping concentric waves" |
| **Depth strata (cross-section)** | Iconografía profundidad, separators visuales | Layer transitions, depth indicators | DEPRECATED "Submarine silhouette" |
| **Depth gauge abstract** | Decoración técnica + iconografía | Loading, progress, depth indicators | preserved (concept abstract) |
| **Signal clarity (pattern emergiendo de ruido)** | Audio/comms, filter results | Sound notifications, search clarity | DEPRECATED "Hydrophone / acoustic" |
| **Bioluminescence (puntos brillantes orgánicos)** | Notificaciones nuevas, activos | Notification badges, real-time indicators | preserved (concept abstract) |
| **Pressure hull RECONCEPTUALIZADO** = capas concéntricas/contención abstract | Privacy, security, encrypted | PIN screens, security settings | reconceptualizado (NO casco metal) |
| **Observation field (área observada abstract)** | View, monitor, spectator | Map view, observation | DEPRECATED "Periscope" |
| **Glassmorphism panes signature selectivos** | Modal/drawer signature | Notification drawer, modals | preserved (sin connotación submarino) |
| **Depth grid isométrico** | Background subtle, premium tier | Premium tier surfaces, Tablet wallpaper accent | preserved (concept abstract) |
| **Brushed steel tech accent (frame)** | Premium device frame | Tablet Pro/Enterprise frame | preserved (premium-tech generic, NO submarino) |

### 2.3 El "ecosystem grid" (re-frased post-ADR-012)

Cada vertical es un **node en la profundidad del ecosystem**:

- **Granja** = node agrícola. Signals: soil quality, harvest emerge.
- **Molino** = node industrial. Signals: production throughput.
- **Banca** = command surface central del ecosystem (NO "bridge command center militar").
- **Mercado** = signal exchange. Bid/offer signals cross-ecosystem.
- **Logística** = transit signals tracked node-to-node + lineage trace.
- **Futuras** = nuevos nodes en el ecosystem.

> **Toda decisión de identidad por nodo deriva de "qué tipo de signal somos en el ecosystem profundidad".**

---

## 3. Identidad de Studio SONAR

### 3.1 La marca

- **Nombre:** SONAR
- **Origen:** SOund Navigation And Ranging — instrumento que "ve por escuchar".
- **Tagline principal:** *"Hear the depth."*
- **Tagline secundario español:** *"La economía RP que escucha cada movimiento."*
- **Tagline operacional:** *"Production-grade roleplay infrastructure."* (post-ADR-012; deprecated *"Tactical-grade"* militar).

**Naming hierarchy:**

```
SONAR                     (Studio + paragua)
├── SONAR OS              (Tablet operating system)
├── SONAR Bank            (banking sub-marca)
├── SONAR Market          (mercado público sub-marca)
├── SONAR Granja          (vertical node)
├── SONAR Molino          (vertical node)
└── SONAR <Vertical>      (futuros)
```

### 3.2 Voz de marca (post-ADR-012)

> **Refactor:** voz arquetipo militar/submarino DEPRECATED. Voz canonical = neutral premium-tech.

| Aspecto | Dirección canonical r6 |
|---|---|
| **Tono** | Neutral premium-tech. Preciso, terse, calmo, professional, atemporal. Estilo Vercel/Linear/Stripe/Apple Pro apps copy. |
| **Persona** | NO arquetipo personaje. Autoridad por precisión del registro + claridad técnica, no por personaje fictício militar. |
| **Vocabulario canonical** | Console, Bitácora, Depth (simbólico), Eco, Manifiesto, Signal, Lineage, Patrón, profundidad (simbólica abstracta), claridad, precisión. |
| **Vocabulario DEPRECATED** | Periscope, Hatch (submarino), Hydrophone, Ping (radio), Sweep, Sumersión, Bridge-as-command-center militar, "silent service", "capitán", "comandante", "almirante", "a bordo", "tripulación", "tactical-grade". |
| **Length** | Frases cortas. Datos primero. Ornamento prohibido. |
| **Humor** | Casi cero. Cuando aparece, seco — sin referencias marítimas literales. |
| **NO hacemos** | Exclamaciones, "amigo", "vibes", gen-Z, cálido emocional, hyperbole, comparaciones competidores explícitas, **arquetipo militar/submarino**. |

**Ejemplos canonical r6:**

- ✅ *"Console activated. Ready."*
- ✅ *"Transfer received: 1,240€ — entry FARM-2026-0042."*
- ✅ *"Cosecha registrada. Calidad: A. Eco: FARM-2026-0042."*
- ✅ *"Manifesto signed. Both parties may invoke arbitration."*
- ✅ *"Hear the depth. Understand the patterns."* (marketing hero).
- ❌ *"Console SONAR activada. Profundidad operativa."* (era voz capitán scaffold-r1..r5 — DEPRECATED).
- ❌ *"Contacto detectado: transferencia 1,240€ recibida en eco SONAR."* (literal sub-acoustic — DEPRECATED).
- ❌ *"Bienvenido a bordo, almirante."* (heritage v1.0 + arquetipo militar — DEPRECATED).
- ❌ *"¡Hey, listo para tu aventura RP?!"* (gen-Z exclamaciones).

### 3.3 Logo SONAR (post-ADR-012)

> **Concepto NO-LOCKED post-ADR-012:** monograma "S" estilizado con metáfora abstracta de profundidad simbólica. **DEPRECATED v1**: "S como onda sonar concéntrica" (radio/freq literal). **Candidatos preliminares Phase 4.5 v2** (designer explora 4-5 direcciones): descent-layers (capas descendiendo), prisma profundidad (3D minimalist), gradient depth, geometric depth-grid, geometric S-descent. Inspiración: Linear, Stripe, Apple Pro apps, Vercel, Arc Browser, Notion.
> **Brief operacional:** ver `docs/art/briefs/01_brief_logo.md` v2 (BRIEF-LOGO-001 v2) — paquete encargo completo con deliverables, lockups, review gates, licensing. **Briefs v1 descartados** (locked en metáfora literal-militar).

**TODO Phase 4:** Detail visual construction + designer collaboration. Preliminary spec:

| Variante | Uso |
|---|---|
| Logo completo (monograma + wordmark "SONAR" + opcional tagline) | Website hero, packaging, splash |
| Solo monograma (S abstract concept TBD Phase 4.5 v2) | Favicon, app icon Tablet, watermark |
| Wordmark solo | Footers, créditos |
| Lockup vertical/horizontal | Aspect ratio variantes |
| Reverso oscuro/claro | **Sonar Bright `#2DD4BF` sobre abyss-black `#03070A`** (canónico) + abyss-black sobre crew-100 `#F0F4F4` (reverse contraste-forced) |

**Reglas:**
1. Espacio libre: ancho de la "S".
2. Tamaño mínimo: 24px alto pantalla, 8mm print.
3. **Color de identidad principal:** `#2DD4BF` (Sonar Bright) — el logo SONAR es **siempre bioluminescent teal**, esta es la firma de la marca en mercado.
4. **Reverse permitido (cuando contraste lo exige):** `#03070A` (abyss-black) sobre `#F0F4F4` (off-white crew-100) o viceversa. Coloro `#175A5F` **NO permitido en logo** — Coloro es soporte estructural, no identidad.
5. Cero rainbow/gradient/efecto. Cero versiones rojas/amarillas/verdes del logo.
6. Prohibido: stretch, rotate, drop-shadow gamer, outline.
7. Glow signature OPCIONAL (solo marketing hero, NO favicon/UI): radial **Sonar Bright `#2DD4BF`** 12% opacity behind logo. Test del 50% aplica.

### 3.4 Paleta META-BRAND SONAR

#### 3.4.1 Institucionales (reorganizadas en 3 tiers de jerarquía)

> **Filosofía de la paleta SONAR:** la firma en mercado es el **brillo bioluminescente**, no la oscuridad. El abyss-black es **canvas que protege la vista del jugador** (sesiones largas, dark-mode-first), pero el **identity-pop es siempre teal brillante**. La marca SONAR **brilla**.

##### Tier A — Canvas & Surfaces (oscuros, **~30-40% pantalla post-ADR-012 hybrid theme** — deprecated scaffold-r1 60%)

> **Función:** soporte visual oscuro que descansa la vista en sesiones largas y permite al brillo destacar. **No representan la marca** — son el lienzo.

| Nombre | Hex | Uso |
|---|---|---|
| **Abyss Black** | `#03070A` | Canvas absoluto. Más profundo que `#000` puro — microscopic blue tint. |
| **Depth 900** | `#061116` | Surface base level 1 (cards principales). |
| **Depth 800** | `#0B1D24` | Surface elevated level 2 (modal interiors). |
| **Depth 700** | `#122B33` | Surface elevated level 3 (sub-modals, hover). |

##### Tier B — IDENTITY POP (primary brand — ~10% pantalla)

> **🟢 Esta es la identidad de SONAR.** Logo, naming, branding marketing, CTAs principales, focus rings, app-icon Tablet, watermarks, Tebex hero, store packaging, trailer reveals, splash. Es el color con el que el mercado nos reconocerá.

| Nombre | Hex | Uso |
|---|---|---|
| **Sonar Bright** | `#2DD4BF` | **🌟 PRIMARY BRAND IDENTITY.** Logo SONAR. Wordmark. CTA primary. App-icon Tablet. Active states. Focus rings. Marketing hero accent. **Esta es la marca.** |
| **Sonar Glow** | `#5EEAD4` | Bioluminescent highlight (lighter sister of Bright). `signal_emerge_pulse` animation soft-glow (NO concentric expanding waves — ver §16.5), key data emphasis, hover states sobre Sonar Bright, notification active dots. |
| **Sonar Pulse** | `#14E5DD` | Pure brilliance saturated (deeper sister of Bright). Critical real-time signals, sweep animation, signal alerts urgentes. **Reservado para momentos de máxima atención** — overuse lo desgasta. |

##### Tier C — Structural Support (deep teal — ~5% pantalla)

> **🔵 Coloro 092-37-14 es soporte estructural, NO la identidad.** Su rol es dar **profundidad tonal coherente** al ecosystema teal sin competir con el brillo identity. **NO aparece en logo, NO aparece en branding marketing, NO aparece como CTA primary.**

| Nombre | Hex | Uso |
|---|---|---|
| **Coloro Support** | `#175A5F` | **Coloro 092-37-14** — soporte estructural deep-teal. Tintes sutiles backgrounds glassmorphism (mezclado con Depth 800), inactive borders, deep-tier UI elements (dividers premium, table headers Tablet, badge backgrounds inactivos), modo dim de instrument indicators no-activos. **Cero uso en surfaces protagonistas o branding identity.** |

#### 3.4.2 Crew (neutrals)

| Nombre | Hex | Uso |
|---|---|---|
| **Crew 100** | `#F0F4F4` | Primary text. Off-white cool, **never pure white**. |
| **Crew 300** | `#B8C5C5` | Secondary text, labels. |
| **Crew 500** | `#6B7878` | Tertiary text, muted, disabled. |
| **Crew 700** | `#2A3438` | Borders, dividers, faint UI lines. |

#### 3.4.3 Functional signals

| Nombre | Hex | Uso |
|---|---|---|
| **Signal Critical** | `#F87171` | Errores críticos. Soft red, **NEVER `#FF0000` saturated**. |
| **Signal Warn** | `#FBBF24` | Warnings amber soft. |
| **Signal OK** | `#34D399` | Success. **Teal-aligned green** (no pure forest). |
| **Signal Info** | `#60A5FA` | Info neutral cool blue. |

#### 3.4.4 Reglas de uso (60/25/10/5/<3)

> **Crítico anti-pattern:** SONAR es **dark canvas + brilliant teal pop**, NO "teal everywhere". El brillo es **firma escasa** que se gana respeto por su rareza, no por su omnipresencia.

**Ratios CANONICAL post-ADR-012 (hybrid theme):**

1. **~30-40% deep surfaces (Tier A canvas dark)** — Abyss Black + Depths reduced (sidebar, hero dark sections, splash, modal backdrops). Descanso visual sesiones largas.
2. **~30-40% white/off-white surfaces (NEW Tier post-ADR-012 hybrid)** — Crew 100 `#F0F4F4` para paneles, cards, content areas, drawer interiors, dashboard workspaces. Refs convergentes: Notion (white content panes), Stripe Dashboard (white workspace), Linear (white modal/cards selectivos), Arc Browser (light content). **NEW — reemplaza ~25% Crew text-only.**
3. **~10-15% IDENTITY POP — Sonar Bright + Sonar Glow + Sonar Pulse** (Tier B — logo, CTAs primary, active states, focus rings, branding marketing). **Esta es la firma de la marca.**
4. **~10% Coloro Support** (Tier C — tintes glassmorphism, inactive borders, dim instruments, deep-tier UI).
5. **<5% Signal functional** (Critical/Warn/OK/Info — reservado momentos atención).

**DEPRECATED scaffold-r1 ratios (60% dark + 25% Crew + 10% Bright + 5% Coloro):** purgados por ADR-012. NO usar.

**Jerarquía visual clara:**
- Cuando el ojo recorre una pantalla SONAR, lo primero que registra es el **brillo teal Tier B** sobre el canvas oscuro Tier A. **Eso es la marca.**
- El Coloro Tier C aparece solo cuando se mira de cerca (tintes sutiles glassmorphism, bordes inactivos) — soporta sin competir.
- Si una pantalla tiene más Coloro deep-teal que Sonar Bright, **invertimos jerarquía sin querer**. Anti-pattern.

**Adicionales:**
- Cero gradients lineales visibles.
- Contraste WCAG AA mínimo siempre. **Sonar Bright `#2DD4BF` sobre Abyss Black `#03070A` = ratio 9.8:1** — AAA compliant, brillo confortable lectura larga.
- **Dark mode = default** (canon SONAR). Light mode = cortesía opcional diseñada (no auto-inverted). En light mode, Sonar Bright **se preserva como identity** — solo se ajusta saturación si exhibe halation issues.

#### 3.4.5 Glassmorphism rules (SIGNATURE)

- **Permitido:** modales, drawers, overlays, notification panel.
  - `backdrop-filter: blur(16-24px)`
  - **Background base:** `rgba(11,29,36,0.6)` (Depth 800 con 60-70% opacity).
  - **Tinte estructural opcional:** mix sutil con Coloro Support `rgba(23,90,95,0.12)` overlay (Tier C aplicación canónica — da profundidad tonal teal-coherent sin gritar identity).
  - **Border accent:** `1px solid rgba(45,212,191,0.15)` — Sonar Bright sutil (Tier B identity en bordes de superficies tech-glass).
- **Prohibido:** surfaces principales (cards, panels, sidebars). Reservado para porthole/instrument feel.

#### 3.4.6 Glow rules (SIGNATURE)

- **Permitido (instrument glow — TODO Sonar Bright Tier B identity):**
  - Active CTA primary: `box-shadow: 0 0 24px rgba(45,212,191,0.25)` (Sonar Bright halo).
  - Focus rings: `box-shadow: 0 0 0 3px rgba(45,212,191,0.4)` (Sonar Bright ring).
  - `signal_emerge_pulse` animation (canonical post-ADR-012, ver §16.5 + BRIEF-MOTION-001 v1 §4.4): glow soft pulse Sonar Bright `#2DD4BF` con scale-bounce subtle 1-2 ciclos, **NO concentric waves expanding** (deprecated `sonar-ping` radio). Pure identity moment.
  - High-priority signals pulse: glow `#14E5DD` Sonar Pulse, faster decay (sin concentric expanding).
  - Critical alert pulsing: `box-shadow: 0 0 32px rgba(248,113,113,0.3)` (Signal Critical, no Tier B).
- **Prohibido:** outer glow gamer en surfaces estáticas, glow en text, RGB rainbow, neón saturado pure.

> **Test del 50%:** if you reduce glow to 50% and visual hierarchy still clear → perfect. If element unrecognizable without glow → using glow as crutch, wrong.

---

## 4. Sistema tipográfico

### 4.1 Las dos familias

#### 4.1.1 Display — Geist Sans (Vercel)

> Replaces Cormorant Garamond serif heritage v1.0. Geometric tech precision. Variable font, free.

- **Pesos:** Light (300), Regular (400), SemiBold (600), Bold (700).
- **Aplicación:** logos, headlines, headers Tablet h1/h2, splash, branding institutional.
- **Anti-uso:** body long-form, UI controls densos.

#### 4.1.2 Body / UI — Inter Tight (Rasmus Andersson)

> Replaces Inter regular v1.0. Tight letterforms = tech precision sin sacrificar legibilidad.

- **Pesos:** Regular (400), Medium (500), SemiBold (600), Bold (700). **Cero light en UI**.
- **Aplicación:** body text Tablet/website/docs, UI controls, labels, microcopia.

#### 4.1.3 Mono — Geist Mono / JetBrains Mono fallback

- **Aplicación:** IBANs, batch IDs, audit trail, console, code snippets docs.

### 4.2 Type scale (modular 1.250 — Major Third)

> **Full spec (Phase 4 detail-pass).** Tokens incluyen tamaño, line-height (ratio + px absoluto), letter-spacing, familia + peso. Ajustados para **lectura confortable en abyss canvas** (long-session).

#### 4.2.1 Tokens canónicos desktop (base = Tablet in-game 1920×1080 equivalent, websites ≥1280px)

| Token | Size | Line-height | Tracking | Familia + Peso | Uso |
|---|---|---|---|---|---|
| `display-xl` | 64px | 72px (1.125) | -0.03em | Geist SemiBold | Hero website, splash Tablet |
| `display-lg` | 48px | 56px (1.167) | -0.03em | Geist SemiBold | Section heros, grandes headlines |
| `display-md` | 36px | 44px (1.222) | -0.02em | Geist Medium | h1 docs, page titles Tablet, modal hero |
| `display-sm` | 28px | 36px (1.286) | -0.02em | Geist Medium | h2, modal titles, card hero |
| `body-xl` | 22px | 32px (1.455) | -0.005em | Inter Tight Regular | Lead paragraphs, intro sections |
| `body-lg` | 18px | 28px (1.556) | 0 | Inter Tight Regular | Body web, paragraphs cómodos |
| `body-md` | 16px | 24px (1.500) | 0 | Inter Tight Regular | Body Tablet default, body docs, prosa |
| `body-sm` | 14px | 20px (1.429) | 0 | Inter Tight Regular | Secondary text, captions, helper text |
| `body-xs` | 12px | 18px (1.500) | +0.01em | Inter Tight Medium | Labels, badges, micro-data (peso Medium compensa tamaño) |
| `mono-md` | 14px | 22px (1.571) | 0 | Geist Mono | Datos técnicos (IBANs, ecos, batch IDs) |
| `mono-sm` | 12px | 18px (1.500) | +0.005em | Geist Mono | Audit trails, console, dev mode |
| `caps-md` | 14px | 20px (1.429) | +0.05em | Inter Tight Medium ALL CAPS | Status indicators principales (`ACTIVE`, `DIVE`) |
| `caps-sm` | 12px | 16px (1.333) | +0.08em | Inter Tight Medium ALL CAPS | Micro-status, badges discretos (`OFFLINE`, `STANDBY`) |

#### 4.2.2 Responsive breakpoints (website)

> **Principio:** Tablet in-game siempre renderiza tokens desktop canónicos (fixed resolution). **Solo website público tiene responsive scaling.**

| Breakpoint | Viewport | Escala display | Escala body |
|---|---|---|---|
| `xs` | <480px | ×0.60 | ×0.90 (min 14px) |
| `sm` | 480-767px | ×0.75 | ×0.95 |
| `md` | 768-1023px | ×0.85 | ×1.00 |
| `lg` | 1024-1279px | ×0.95 | ×1.00 |
| `xl` | ≥1280px | ×1.00 (canónico) | ×1.00 |

**Ejemplo aplicado:** `display-xl` (64px canónico) → renderiza 38px en mobile xs, 48px en sm, 54px en md, 61px en lg, 64px ≥1280px.

**Cero responsive en Tablet in-game** — siempre desktop canónico porque la resolución del juego es fija.

#### 4.2.3 Reglas de aplicación

1. **Línea de prosa ≥ body-md (16px):** cualquier texto prose-like (párrafos, descripciones, body docs) NUNCA por debajo de 16px — accesibilidad + long-session comfort sobre abyss canvas.
2. **Display siempre Geist Medium o SemiBold:** cero Display weight Light en UI real (solo marketing hero opcional).
3. **Body Regular default, Medium para enfasis ligero, SemiBold para héros inline:** cero Body Bold salvo keyword puntual (1-2 palabras máx).
4. **Tabular numbers obligatorio:** `font-feature-settings: 'tnum' 1` en todas las columnas de números (extractos Bank, tablas cosechas, ledgers).
5. **Max line-length body:** ≤ 72 caracteres por línea (≈65ch CSS) — lecturas largas confortables.
6. **Max line-length display:** ≤ 30 caracteres por línea — los héros no lloran.

### 4.3 Reglas tipográficas

1. **ALL CAPS** permitido en status indicators (`ACTIVE`, `OFFLINE`, `READY`, `PROCESSING`) tracking +0.05em — premium-tech precision (Vercel/Linear/Stripe class). DEPRECATED v1: `DIVE`/`SURFACE` (literal sub-acoustic).
2. Tabular nums obligatorio en columnas numéricas.
3. Tracking display: -0.03em (tighter than v1 -0.02em — tech precision).
4. Italic prohibido excepto enfasis técnico puntual.
5. Cero italic-bold combinado.

---

## 5. Iconografía

### 5.1 Familia primaria — Lucide

- **Stroke width:** 1.5px (between default 2 and fina 1).
- **Stroke linecap/linejoin:** round.
- **Sizes:** 16, 20, 24, 32px.

### 5.2 Custom SONAR icon set (8-10 essentials)

> Replaces 20 navales heritage v1.0. Stripped-down minimalist sub/sonar themed.
> **Brief operacional:** ver `docs/art/briefs/02_brief_icons.md` (BRIEF-ICONS-001) — paquete encargo completo con specs, deliverables, review gates, licensing.
> **Pendiente Phase 4 ejecución creativa:** SVG construction + Figma component library + repo location `art/icons/sonar_icons_v1/` (post-designer assignment).

| Icono | Concepto | Uso |
|---|---|---|
| `signal-emerge` | Ondas concéntricas pulsando | Logo monogram, splash, notification primary |
| `submarine` | Silueta sub minimalist | Loading states, brand watermark |
| `depth-gauge` | Indicator profundidad | Loading, progress, depth context |
| `signal-clarity` | Mic submarino | Audio/comms |
| `bioluminescence` | Constelación puntos brillantes | Notifications nuevas, activos |
| `pressure-hull` | Casco con líneas presión | Privacy, security, encrypted |
| `observation-field` | Periscopio extending | View, monitor |
| `lineage-trace` | Tubo lanzamiento | Logística futura (Oleada 2+) |

### 5.3 Iconos por estado

| Estado | Color | Icono |
|---|---|---|
| Success | Signal OK | `check-circle` Lucide |
| Warning | Signal Warn | `alert-triangle` Lucide |
| Error | Signal Critical | `x-circle` Lucide |
| Info | Signal Info | `info` Lucide |
| Pending | Coloro Identity | `depth-gauge` (custom, animated pulsing) |
| Active/live | Sonar Bright | `bioluminescence` (custom, animated) |

---

## 6. Texturas y materiales

### 6.1 Filosofía: "subtle physical OUT, clean tech IN"

Heritage materiales (parchment/brass/oak/wax) deprecated. Reemplazados por tech-clean surfaces.

### 6.2 Texturas SONAR (3, replaces 5 v1)

| Textura | Aplicación | Cómo |
|---|---|---|
| **Sonar Mesh Grid** | Background canvas premium tier (subtle) | SVG dotted/line grid + opacity 0.04 |
| **Glassmorphism Pane** | Modal/drawer surfaces (signature SONAR) | `backdrop-filter: blur(16-24px)` + `bg-rgba(11,29,36,0.6)` |
| **Brushed Steel Tech** | Premium device frame, instrument bezels | Linear gradient horizontal sutil + noise SVG fine |

### 6.3 Anti-textura SONAR

- ❌ Parchment, oak, brass v1 (deprecated).
- ❌ Wax seal embossed (deprecated).
- ❌ Gradients holográficos / iridescent.
- ❌ Glassmorphism heavy en surfaces principales (only modal/drawer).
- ❌ Glow neon outer gamer-style (cero — pero sonar instrument glow es OK como signature, ver §3.4.6).

> **TODO Phase 4:** SVG textures repo + CSS class library + 3D texture maps for Tablet device model frame.

---

## 7. Sound design META-BRAND SONAR

### 7.1 Filosofía (post-ADR-012)

> **El silencio es diseño.** Volumen base muy bajo (-15dB, more silenced than v1's -12dB). Cada acción importante tiene su sonido firma. El silencio entre sonidos también está diseñado. **DEPRECATED v1**: "silent service" arquetipo militar — voz/concept canonical post-ADR-012 = neutral premium-tech.

### 7.2 Sound library Studio (5 SFX firma)

| Sound | Reemplaza | Uso | Carácter |
|---|---|---|---|
| `signal_emerge` | `admirals_chime` (legacy) + DEPRECATED v1 `sonar_ping` | Notificación crítica primaria | Mid-tone clarity con leve pitch-rise sugiriendo "algo emergiendo" (400-800ms). Premium-tech tonal Apple Mail/Vercel deploy class. **NO ping radio waveform**. Ver BRIEF-SOUND-001 v1 §2.1.1. |
| `depth_press` | `admirals_seal` (legacy) + DEPRECATED v1 `sonar_pressure` | Firma documento, confirmación | Low-mid press con weight + leve settle decay (200-400ms). Sugiere peso descendiendo confirmado. Apple Touch ID success class. |
| `layer_dive` | `admirals_quill` (legacy) + DEPRECATED v1 `sonar_depth` | Submit / escritura / drill-down | Quick mid-tone descent suave (150-300ms). Smooth transitional frictionless. Notion page transition class. |
| `console_tap` | `admirals_brass_click` (legacy) + DEPRECATED v1 `sonar_console` | Confirmación premium click | Brief high-mid click con leve "pop" tonal (50-150ms). Crisp precise. Apple trackpad haptic-equivalent class. |
| `panel_open` | `admirals_parchment` (legacy) + DEPRECATED v1 `sonar_hatch` | Abrir modal / drawer / panel | Soft rise + breath-like reveal (200-400ms). Sugiere panel emerging. Apple notification center reveal class. **NO door creak ni hatch literal**. |

### 7.3 Reglas

1. Volumen base -15dB.
2. Spatialized cuando aplica.
3. Frecuencia limitada (debounce 200ms).
4. Mute completo siempre disponible en Tablet settings.

> **TODO Phase 4:** sound bibliography sourcing (proveedores curados o foley custom), audio asset format specs, license documentation, sonification specs por nodo.

### 7.4 Música oleada futura

- **Oleada 1: solo SFX. Cero música.**
- **Oleada 2 / SDK: música ambient opcional por nodo** (Tablet con player propio + Music API SDK).

---

## 8. Principios identidad por nodo

> **Framework preserved from v1.0** (only metaphor changes, not framework).

### 8.1 Anatomía identidad nodo (7 dimensiones)

Cada nodo se define en 7 dimensiones:

| # | Dimensión | Qué define |
|---|---|---|
| 1 | **Concept statement** | 1-2 frases capturando esencia cultural del node. |
| 2 | **Sub-paleta del node** | 5-7 colores propios + relación con meta-paleta SONAR. |
| 3 | **Type display propio** (opcional) | Familia adicional usada SOLO en branding del node (signage in-world). UI Tablet siempre Geist + Inter Tight. |
| 4 | **Iconografía firma** | 5-10 iconos custom propios del node. |
| 5 | **Texturas y materiales** | Materiales firma (madera, metal, telas) y aplicación 3D + NUI. |
| 6 | **Sound signature** | 3-5 sonidos firma del node (ambient + acciones específicas). |
| 7 | **Motion signature** | Cómo se mueven elementos visuales del node. |

### 8.2 Regla: meta-brand vs identidad de nodo

| Surface | Identidad |
|---|---|
| **Tablet OS chrome** (status bar, dock, switcher, settings, notif tray) | **100% SONAR OS** (abyss-black + Coloro identity + sonar bright) |
| **Apps SONAR** (Bank, Market, Empresa, Mensajes, Documentos, Notificaciones, Settings) | **100% SONAR OS** |
| **Apps de nodo** (Granja, Molino, futuras) — vista principal Tablet | **80% SONAR OS chrome + 20% acentos del node** |
| **Mundo 3D del nodo** (sede, props, signage, MLO, vehículos) | **100% identidad del nodo** |
| **Documentos oficiales** (contratos, recibos, certificados) | **SONAR OS — sello + branding meta** + opcional logo node emisor en esquina |
| **Signage in-world del nodo** (cartel sede, uniformes, packaging producto físico) | **100% identidad nodo** + pequeño SONAR wordmark abajo (sello calidad) |

### 8.3 3D vs Código (Bible §13.4 preserved)

| Asset | Quién lo construye |
|---|---|
| Modelos 3D (props, MLOs, vehículos) | **Equipo 3D externo** — geometría wow IDEA + texturas base PBR |
| **Shaders custom** (post-FX, color grading, vignettes, depth-of-field) | **CÓDIGO** vía FiveM `SetTimecycleModifier`, scaleforms, NUI overlays |
| **Lighting dinámica** (golden hour Granja, fluo Molino, sub-bridge dim) | **CÓDIGO** vía timecycles, light entities |
| **Partículas** (polvo harina, polvo sub bridge tech) | **CÓDIGO** particle FX + NUI overlays |
| **Motion / animación UI** (Framer Motion springs) | **CÓDIGO** specs §11 (TODO Phase 4) |
| **Sound design** | **CÓDIGO + audio assets curados** |
| **Iconografía** (Lucide + custom set) | **CÓDIGO + Figma diseño** |
| **Tipografía** | **CÓDIGO** carga `@font-face` NUI |

---

## 9. Granja — Earth & Harvest (post-pivot recontextualizado)

> **Estado:** preserved with light SONAR contextualization. **Full re-detail TODO Phase 7** durante node docs purge.

### 9.1 Concept statement (revised post-pivot)

> *"Surface node agrícola en el sonar grid SONAR. Tierra que conoce el ciclo del año. Madera vieja, telas crudas, aire caliente al mediodía y frío al amanecer. La cosecha es un signal trackeable en eco SONAR — cada saco emite su ping de calidad y origen."*

**Mood reference:** preserved from v1 (Days of Heaven, Tree of Life, First Cow, Andrew Wyeth).

### 9.2 Sub-paleta Granja

> **TODO Phase 7:** detail completo. Preserved from v1.0:

| Nombre | Hex | Uso |
|---|---|---|
| **Wheat Gold** | `#C9A85B` | Acento principal. Harvested wheat. |
| **Terracotta** | `#A85A3F` | Tejas sede, alerta plaga suave. |
| ... (resto pendiente Phase 7) |

### 9.3 Integración SONAR meta-brand

- App "Granja" en Tablet: 80% SONAR OS chrome (abyss + Coloro) + 20% acentos terracota/wheat-gold.
- Signal protocol Granja: cada cosecha emite `harvest_ping` event con `quality + lineage_origin + producer_id` payload.
- Sound signature Granja: ambient earth/wind + integrated `signal_emerge` cuando cosecha se registra en bitácora.

---

## 10. Molino, Banca, Mercado, etc.

> **TODO Phase 7:** detalle completo. Placeholders preserved from v1.0 estructura, naval refs purged, contextualizados en SONAR ecosystem grid.

---

## 11. SONAR OS Tablet

> **Doc dedicado:** `02_sonar_tablet.md` (renamed from `02_admirals_tablet.md`, rewrite pendiente Phase 5).

Decisiones foundational SONAR OS:

- **Layout:** horizontal default (preserved).
- **Density:** ajustable, productividad-first.
- **Boot:** 1.8s, sonar-themed (logo SONAR + onda sonar pingeando + tipografía Geist fina + decay con `signal_emerge` audio).
- **Lock screen:** abyss-black canvas + Sonar Bright instrument dots (depth gauge + clock) + glassmorphism PIN entry modal.
- **Home:** grid apps con bioluminescent active state.
- **App switcher:** glassmorphism cards.
- **Notification panel:** glassmorphism drawer + sonar mesh grid background subtle.

---

## 12. Marketing materials, store pages, trailer

> **TODO Phase 4 detail-pass:** moodboard completo, video specs, Tebex page layout, screenshot guidelines, trailer storyboard.

Direcciones foundational:

- **Trailer:** abyss-black opening + sonar ping reveals SONAR logo + cuts cinematográficos (no gamer cuts rápidos) + `signal_emerge` audio firma.
- **Tebex page:** dark canvas, bioluminescent CTA buttons, screenshot grid 4-cols, pricing table glassmorphism.
- **Website:** Geist Sans hero massive, Inter Tight body, abyss canvas + **Sonar Bright hero accent** (logo + CTAs + key data pop) + Coloro Support solo en glassmorphism panes opcionales.

---

## 13. Plan de assets

> **Full spec (Phase 4 detail-pass).** Plan ejecutable de todos los assets que requiere SONAR, por categoría + oleada + prioridad. **Esta es la lista operativa para briefing del equipo 3D + audio + diseñador + marketing.**

### 13.1 Asset catalog completo

#### 13.1.1 Assets 3D (mundo FiveM)

| Asset | Tipo | Oleada | Prioridad | Notas |
|---|---|---|---|---|
| **Tablet device model** | Prop handheld | 1 | 🔴 P0 | Portable tablet frame + pantalla + botón power + speaker grill. Brushed steel tech accent frame. Aprox 0.3m ancho. |
| **Tablet Pro tier frame** | Prop handheld variant | 2 | 🟡 P1 | Variante premium con bezel más fino + detalles metálicos adicionales. |
| **Granja MLO admin building** | MLO interior + exterior | 1 | 🔴 P0 | Sede administrativa + oficina + zona recepción operadores. Materialidad wood+metal+window. |
| **Granja parcelas (3 variantes)** | Terreno + props | 1 | 🔴 P0 | Parcela seca / húmeda / cosechada. Textura variable por estado. |
| **Silo granja** | Prop grande | 1 | 🔴 P0 | Silo metálico exterior con depth gauge LCD visible. Audio changes por llenado. |
| **Herramientas granja** | Props handheld | 1 | 🟡 P1 | Hoz, saco, pala, carretilla. Wear+tear visible. |
| **Saco de grano (variantes calidad)** | Prop carryable | 1 | 🔴 P0 | 3 variantes tela por grade (A/B/C). Tag sellado con eco visible. |
| **Molino MLO** | MLO interior + exterior | 1 | 🟡 P1 | Industrial interior con rodillos + belts + output packaging station. |
| **Batch flour packaging** | Prop | 1 | 🟡 P1 | Bolsas packaging con tag lineage. |
| **Vehículo reparto granja** | Vehículo | 2 | 🟡 P1 | Camioneta vintage modificable cargo capacity. |
| **Uniforme Granja** | Ropa jugador | 2 | 🟢 P2 | Overall marrón + botas + gorra logo SONAR Granja discreto. |
| **Uniforme Molino** | Ropa jugador | 2 | 🟢 P2 | Delantal blanco manchado + gorra + máscara polvo. |
| **SONAR Bank sede edificio** | MLO | 2 | 🟡 P1 | Interior command center aesthetic + exterior marker discreto. |
| **Market plaza exterior** | Mapa área | 2 | 🟡 P1 | Espacio público para bid/offer boards + meetings operadores. |

#### 13.1.2 Assets 2D (UI + iconografía + marketing)

| Asset | Tipo | Oleada | Prioridad | Notas |
|---|---|---|---|---|
| **Logo SONAR completo** | SVG vectorial | 1 | 🔴 P0 | Monograma + wordmark + lockup variants (vertical/horizontal/reverse). 5 variantes. |
| **Favicon SONAR** | ICO + SVG | 1 | 🔴 P0 | 16/32/48/64/128/256 sizes + dark/light variants. |
| **App icon Tablet** | PNG + SVG | 1 | 🔴 P0 | 512×512 iOS-style rounded square con monograma sobre abyss-black. |
| **Custom SONAR icon set v1** | SVG library | 1 | 🔴 P0 | 8 custom icons (sonar-ping, submarine, depth-gauge, hydrophone, bioluminescence, pressure-hull, periscope, torpedo-bay). SVG + Figma components. |
| **Lucide icon subset** | SVG references | 1 | 🔴 P0 | Curated list Lucide icons usados + stroke 1.5px + consistencia visual. |
| **Texturas background** | PNG + SVG tiled | 1 | 🟡 P1 | Sonar mesh grid + glassmorphism fallback + brushed steel. |
| **UI mockups Figma** | Figma file | 1 | 🔴 P0 | Tablet OS shell + apps principales (Bank, Home, Settings, Notif tray). Source of truth UI. |
| **Design system Figma** | Figma library | 1 | 🔴 P0 | Components + tokens (color, type, motion, spacing). Referenced from UI mockups. |
| **Storybook components** | Code library | 2 | 🟡 P1 | Componentes React live documentation (cross-ref `04_storybook_guide.md`). |
| **Website templates** | Figma + HTML | 2 | 🟡 P1 | Landing hero + pricing + docs + store + changelog. |
| **Tebex page mockups** | Figma | 2 | 🟡 P1 | Product pages layout + pricing table + screenshot grids. |
| **Press kit** | PDF + assets ZIP | 2 | 🟢 P2 | Logos variantes + bio + screenshots + quotes founder. |

#### 13.1.3 Assets audio / sound

| Asset | Tipo | Oleada | Prioridad | Notas |
|---|---|---|---|---|
| **5 SFX firma SONAR** | OGG mono | 1 | 🔴 P0 | `signal_emerge`, `depth_press`, `layer_dive`, `console_tap`, `panel_open`. -15dB normalized. |
| **Ambient Granja** | OGG stereo loop | 1 | 🟡 P1 | Viento + pájaros sutiles + crujido madera + lejano tractor. Loopable seamless. |
| **Ambient Molino** | OGG stereo loop | 2 | 🟡 P1 | Rodillos industriales + belts + polvo aéreo sonoro. |
| **Ambient SONAR OS (Tablet)** | OGG stereo loop | 2 | 🟢 P2 | Sub bridge very-low drone + sonar ping intervals ambient. Activo solo focus mode. |
| **Trailer music** | WAV master | 2 | 🟢 P2 | Track custom cinematografic con sonar ping hits sincronizados. |
| **Boot sound Tablet** | OGG mono | 1 | 🔴 P0 | Chord deliberate 1.8s acompañando splash. |

#### 13.1.4 Branding + marketing materials

| Asset | Tipo | Oleada | Prioridad | Notas |
|---|---|---|---|---|
| **Brand book PDF** | PDF completo | 2 | 🟡 P1 | Logo rules + palette + tipografía + voz + do/dont + 40-60 páginas. Referenciable externo. |
| **Trailer reveal Oleada 1** | MP4 master | 2 | 🟡 P1 | 60-90s hero reveal style cinematográfico. Script + storyboard §12. |
| **Screenshots in-game curated** | PNG library | 2 | 🟡 P1 | 20-30 screenshots para Tebex + website + social + press. Composed intentionally (lighting, framing, UI state). |
| **Website copy spanish + english** | MD/txt files | 2 | 🟡 P1 | Hero + features + pricing + docs + changelog + about. SEO-optimized. |
| **Social media templates** | PSD/Figma | 2 | 🟢 P2 | Twitter/X + Discord + Instagram/TikTok announcement templates. |
| **Launch announcement video** | MP4 short | 2 | 🟢 P2 | 30s teaser para social/discord. |

### 13.2 Briefing template equipo 3D (externo)

> Cada asset 3D handoff a equipo externo requiere brief en este formato:

```markdown
# Brief 3D — [Asset Name]

## Objetivo
[1-2 frases: qué es, para qué sirve en producto]

## References visuales
- [3-5 references moodboard]
- Anti-references (opcional): [qué NO queremos]

## Specs técnicos
- Polycount target: [low/mid/high + rango triangles]
- Texture resolution: [1K/2K/4K]
- PBR materials: [diffuse/normal/roughness/metallic]
- LODs: [número de LODs]
- Rig/animation: [sí/no]
- FiveM compatibility: [ydr/ytyp/ymap formato]

## Aesthetic SONAR
- Materialidad: [wood aged / brushed steel / glass / organic]
- Wear+tear: [nuevo / usado / muy usado]
- Glow elements integrados: [LCDs instrument visible emit]
- Color accents: [si el asset tiene superficies Coloro Support / Sonar Bright]

## Entregables esperados
- Formato files: [.blend, .fbx, .ydr]
- Timeline: [estimate]
- Review checkpoints: [milestones intermediates]
```

### 13.3 Prioridades por oleada

| Oleada | Scope | Assets P0 obligatorios |
|---|---|---|
| **0 (foundation)** | ADR + docs + arquitectura | — (cero assets, solo docs) |
| **1 (MVP Granja + Tablet)** | Banco core + Tablet OS + Granja loop | Tablet device + Granja MLO + Granja parcelas + Silo + Saco grano + Logo SONAR + Favicon + App icon + Custom icon set + 5 SFX firma + Boot sound + UI mockups Figma |
| **2 (Molino + Bank app + Mercado)** | Expansión cadena + Tablet apps | Molino MLO + Batch flour + Vehículo reparto + SONAR Bank sede + Market plaza + Ambient loops + Brand book + Trailer Oleada 1 |
| **3+ (verticales extendidos)** | Panadería, Retail, Cervecería, Mecánico | TBD per §17 stubs |

### 13.4 Repo structure assets

```
/assets/
├── branding/
│   ├── logos/                     # SVG master + exports PNG/ICO
│   ├── brand-book/                # PDF + source
│   └── press-kit/                 # ZIPs curados
├── ui/
│   ├── figma-source/              # Links a Figma files (no store en git)
│   ├── icons/
│   │   ├── sonar-custom-v1/       # 8 custom icons SVG
│   │   └── lucide-subset.md       # Curated list referenced
│   └── textures/
│       ├── sonar-mesh-grid.svg
│       ├── glassmorphism-fallback.png
│       └── brushed-steel.png
├── audio/
│   ├── sfx/
│   │   ├── sonar_ping.ogg
│   │   ├── sonar_pressure.ogg
│   │   └── …
│   ├── ambient/
│   │   ├── granja-loop.ogg
│   │   └── …
│   └── boot/
│       └── tablet-boot.ogg
├── 3d/
│   ├── source/                    # .blend master files
│   ├── fivem-exports/             # .ydr / .ytyp ready-to-stream
│   └── briefs/                    # Markdown briefs por asset
└── marketing/
    ├── screenshots/               # Curated game screenshots
    ├── trailer/                   # Video masters + storyboards
    └── social/                    # Templates sized per platform
```

### 13.5 Licensing + rights

- **Todos los assets creados para SONAR:** copyright Studio SONAR, uso exclusivo producto + marketing.
- **Terceros (licencias):**
  - Tipografía Geist Sans/Mono: SIL Open Font License (free commercial).
  - Tipografía Inter Tight: SIL OFL (free commercial).
  - Lucide icons: ISC license (free commercial + modification OK).
  - Stock audio (si se usa como base foley): license comercial obligatorio documentar en repo.
- **Outsourced 3D:** contratos con work-for-hire clause — copyright transfiere a SONAR al entregar + pagar. Source files (.blend) obligatorio entrega.
- **Prohibido en repo:** assets stock sin licencia documentada, modelos ripped de juegos (NoPixel fork assets, GTA Online clones, etc.), música con copyright sin autorización.

---

## 14. Governance del arte

> **Full spec (Phase 4 detail-pass).** Cómo se toman decisiones de arte, quién aprueba qué, cómo se firman documentos visuales, cómo colabora el equipo con designers externos. **Si este doc no define un workflow para algo, la decisión default es founder review.**

### 14.1 Review process — quién aprueba qué

| Decisión | Reviewer primario | Trigger ADR |
|---|---|---|
| **Paleta color** (añadir/quitar/mover tier) | Founder + Cascade architect | ✅ ADR obligatorio |
| **Tipografía** (cambio familia principal) | Founder + Cascade architect | ✅ ADR obligatorio |
| **Voz de marca** (tono, vocabulario, personas) | Founder | ✅ ADR obligatorio |
| **Logo design final** | Founder + designer externo | ✅ ADR obligatorio |
| **Iconografía custom set** | Founder + designer | 🟡 ADR recomendado |
| **Sound design SFX firma** | Founder + sound designer | 🟡 ADR recomendado |
| **Motion patterns principales** | Cascade + Founder review | 🟢 No ADR (salvo cambio filosofía) |
| **UI mockup Figma** | Cascade + Founder review | 🟢 No ADR |
| **Storybook components** | Cascade | 🟢 No ADR (implementation detail) |
| **Marketing copy individual** | Founder + writer | 🟢 No ADR |
| **Trailer script + storyboard** | Founder + video producer | 🟡 ADR si define género/tono |
| **Assets 3D outsourced** | Founder + 3D lead | 🟢 No ADR (operational) |

**Regla base:** si una decisión **invalida** algo firmado en SSoT docs (este incluido), ADR obligatorio antes de ejecutar (per workspace rules §red_flags).

### 14.2 Signing protocol v2.0 firmable

> Este doc (`01_art_direction.md`) pasa de `scaffold` a `firmable` cuando cumple los siguientes criterios:

**Checklist v2.0 firmable (all must pass):**

- [ ] §1 Filosofía S1-S10 completa + antirefs + comparativa competidores.
- [ ] §2 Metáfora central completamente articulada.
- [ ] §3 Identidad Studio: marca + voz + logo (con visual construction spec + designer lock) + paleta (3 tiers tokens finales).
- [ ] §4 Sistema tipográfico: familias + scale tokens con line-height exact + reglas aplicación. ✅ **(done v2.0-scaffold-r2)**
- [ ] §5 Iconografía: Lucide + custom set 8 con SVG construction specs + Figma library live.
- [ ] §6 Texturas: 3 texturas con source files + CSS class library.
- [ ] §7 Sound design: 5 SFX firma con sourcing docs + format specs + license. Ambient bibliography preliminar.
- [ ] §8 Principios identidad por nodo: framework + 3D vs código completo.
- [ ] §9 Granja: concept statement + sub-paleta detalle + props 3D lineup + sound signature + motion.
- [ ] §10 Molino / Banca / Mercado: placeholders con detalle mínimo Phase 7.
- [ ] §11 SONAR OS Tablet: decisiones foundational + cross-ref `02_sonar_tablet.md`.
- [ ] §12 Marketing materials: moodboard completo + trailer storyboard + Tebex layout + website copy directions.
- [ ] §13 Plan de assets: catalog + briefing + prioridades + repo structure + licensing. ✅ **(done v2.0-scaffold-r3)**
- [ ] §14 Governance: este section. ✅ **(done v2.0-scaffold-r3)**
- [ ] §15 Glossary: 40+ términos canónicos. ✅ **(done 55+ v2.0-scaffold-r2)**
- [ ] §16 Motion specs: duration tokens + easing + springs + pattern catalog + a11y. ✅ **(done v2.0-scaffold-r2)**
- [ ] §17 Verticales placeholder: stubs Panadería/Retail/Cervecería/Mecánico. ✅ **(done v2.0-scaffold-r3)**
- [ ] §18 Storybook integration: cross-ref con file live. ✅ **(design-side done v2.0-scaffold-r4 — pending `docs/technical/04_storybook_guide.md` live file cross-ref bump)**
- [ ] §19 Shader contracts: cross-ref con file live. ✅ **(design-side done v2.0-scaffold-r4 — pending `docs/technical/02_shader_contracts.md` post-pivot update cross-ref bump)**
- [x] §20 Roadmap art direction iterations: v2.1/v2.2/v3.0 triggers. ✅ **(done v2.0-scaffold-r4)**

**Firma protocol:**
1. Cuando checklist completo, founder hace review full doc (1-2 sesiones dedicadas).
2. Founder green-light + Cascade bump versión `v2.0-scaffold-rN` → `v2.0` firmable.
3. Header doc actualizado a "Estado: firmado".
4. Commit `docs: sign 01_art_direction.md v2.0` + tag `art-direction-v2.0` (opcional).
5. Post-firma, cambios = new ADR + version bump (v2.1+). Living document per ADR-007.

### 14.3 Version control assets repo

- **Git LFS obligatorio** para binaries (PSD, AI, .blend, ydr, PNGs grandes, videos). Texto (SVG, MD) normal git.
- **Source files obligatorio tracked:** `.blend`, `.fig` (via figma-export API), `.ai` master logo, WAV sources audio.
- **Exports cached tracked:** FiveM .ydr / .ytyp, PNG exports logo sized, OGG exports audio normalized. Regenerables pero preservados.
- **Branches:** `main` canonical. `feature/<asset-name>` work-in-progress. NO commits directos main para assets outsourced.
- **Tagging releases:** al cerrar oleada, tag `assets-oleada-<N>` — freeze de assets usados en producto en ese momento.
- **Figma files:** referenced via URL en MD files. NO attempted sync bidireccional (Figma es SSoT Figma-side).

### 14.4 Designer collaboration workflow (externo)

> Para cada engagement con designer externo (logo, custom icons, 3D artist):

**Fase 1 — Briefing (founder + Cascade):**
1. Cascade redacta brief markdown con template §13.2 (para 3D) o equivalente (para 2D/audio).
2. Founder review + ajustes.
3. Send a designer + kickoff call (si aplica).

**Fase 2 — Iteration (~2-4 weeks per asset significant):**
1. Designer entrega primer draft con 2-3 variantes.
2. Founder + Cascade review síncrono (30-60 min).
3. Feedback estructurado: qué funciona (preserve), qué no (iterate), qué falta (add).
4. Designer entrega v2 con ajustes.
5. Repetir hasta v3-v4 (máx).

**Fase 3 — Delivery:**
1. Designer entrega final: source files (.blend/.ai/.fig) + exports (FiveM-ready / web-ready) + documentación cambios.
2. Cascade review técnico: specs cumplidos, naming convention, repo structure match.
3. Founder firma off.
4. Commit a repo con tag release + payment release (si paid engagement).
5. Post-mortem breve: qué funcionó, qué mejorar next engagement.

**Red flags designer workflow:**
- 🚩 Designer solicita cambios constantes de scope sin re-briefing formal.
- 🚩 Entregas sin source files (only exports) — rechazar, no es contract-compliant.
- 🚩 Designer usa paleta distinta a Tier A/B/C sin ADR approval.
- 🚩 Asset rompe principios S1-S10 sin justificación — re-work.
- 🚩 Designer no puede entregar variants (logo color/size) — incomplete delivery.

### 14.5 Anti-patterns governance

> **Qué NO hacemos en decisiones de arte:**

- ❌ **Changes bypass review** — merge directo main sin founder review asset cambio.
- ❌ **Rogue assets** — asset added al producto sin que pase por catalog §13.1 + brief §13.2.
- ❌ **Unauthorized palette changes** — dev/designer usa color custom fuera Tier A/B/C + Crew + Signal. Si necesita nuevo color → ADR primero.
- ❌ **Mix stack inconsistent** — usar paleta Admirals v1.0 deprecated (`_archive/`) en new work.
- ❌ **Voice drift** — copy escrito con voz friendly/playful violando glossary §15.
- ❌ **Unaccounted assets** — files en repo que no están en catalog §13.1 ni justificados en brief.
- ❌ **License untracked** — asset terceros añadido sin documentar licencia + ubicación repo.
- ❌ **Skip a11y** — animations sin `prefers-reduced-motion` handling, contrastes sin WCAG check.

---

## 15. Glossary SONAR vocabulary (meta-brand internal lexicon)

> **Vocabulario canónico SONAR** — SSoT léxico para toda doc rewrite Phases 5-7 + voice de marca + UI copy + marketing materials. **Cuando el dev/AI escribe copy SONAR, estos son los términos correctos.**

> **Origen léxico (post-ADR-012):** premium-tech infrastructure + abstracción profundidad simbólica + neutral voice (Vercel/Linear/Stripe class). **DEPRECATED v1**: submarine tech + naval silent service + acoustic instrumentation literal. Preservado consistency cross-touchpoint (logo a Tablet a website a trailer a docs).

### 15.A Meta-brand core (9 términos)

| Término | Definición | Traducción técnica |
|---|---|---|
| **SONAR** | Nombre del proyecto + Studio + paragua marca. Acrónimo SOund Navigation And Ranging. | Product name |
| **Bridge** (re-interpretado post-ADR-012) | **"Tablet home view"** abstract. Vista principal del Tablet donde el operador opera. **DEPRECATED v1**: "command center militar" — connotación submarino purgada. | Main Tablet dashboard / home view |
| **Bitácora** | Audit trail / log forense. Registro inmutable de acciones. | `admirals_bank_audit_log` + eventos event_log |
| **Console** | UI activa del Tablet en uso. Lo que el operador está mirando ahora. | Current foreground app |
| **Depth** | Nivel de profundidad operacional (metáfora — no literal). Indicador de tier/role/acceso. | User permission level / tier |
| **Operador** | El jugador. Sustituye "player" / "user" en copy player-facing. | Player / user |
| **Pressure hull** | Cerramiento seguro de datos sensibles. Indicador visual privacy/encrypted. | Security/privacy boundary |
| ~~**Silent service**~~ DEPRECATED post-ADR-012 → use **Neutral premium-tech** | DEPRECATED arquetipo militar. Voz canonical r6 = neutral premium-tech (Vercel/Linear/Stripe). Disciplina preservada (terse + precisión) sin connotación militar. | Brand voice discipline (neutral premium-tech) |
| **Sub-brand** | Verticales (SONAR Bank, SONAR Market, SONAR Granja). Parte del ecosistema. | Product vertical |

### 15.B UI elements (11 términos)

| Término | Definición | Traducción técnica |
|---|---|---|
| **Dock** | Barra inferior de apps anchadas del Tablet. | App dock / taskbar |
| ~~**Hatch**~~ DEPRECATED post-ADR-012 → use **Panel open** | DEPRECATED literal submarino. Reemplazo canonical: **Panel open / Panel close** (abrir/cerrar modal o drawer). | Modal/app open-close |
| **Home** | Launcher grid del Tablet. Vista de apps. | Launcher screen |
| **Lock screen** | Pantalla inactiva del Tablet con entrada PIN/auth. | Lock screen |
| ~~**Periscope**~~ DEPRECATED post-ADR-012 → use **Observation field / view** | DEPRECATED literal submarino. Reemplazo canonical: **Observation field / view** (mapa, dashboard, monitor abstract). | Observation view / map |
| ~~**Porthole**~~ DEPRECATED post-ADR-012 → use **Glass panel** | DEPRECATED "ojo de buey submarino" literal. Reemplazo canonical: **Glass panel** (modal/drawer glassmorphism abstract). | Glassmorphism modal/drawer |
| **Sonar grid** | Background pattern dotted/line sutil en surfaces premium. | Background texture |
| **Splash** | Boot screen del Tablet con logo animation + `signal_emerge`. | Boot splash |
| **Switcher** | Vista de apps abiertas en multitask (glassmorphism cards). | App switcher |
| **Tray** | Notification panel glassmorphism drawer. | Notification panel |
| **Status bar** | Top bar del Tablet con clock + depth gauge + signal strength. | Top status bar |

### 15.C Actions & operations (10 términos)

| Término | Definición | Traducción técnica |
|---|---|---|
| **Dive** | Entrar en profundidad: focus mode, modal full-screen, sesión intensiva. | Focus / deep mode |
| **Emersión** | Salir del Tablet a world (close session). | Tablet close |
| **Handshake** | Pareado de contratos firmados entre dos contactos (mutual commit). | Contract bilateral sign |
| **Invocar** | Llamar a un servicio: "invocar arbitraje", "invocar garantía". | Invoke service/procedure |
| **Ping** | Notification atómica individual. Evento puntual. | Single notification event |
| **Signal** | Evento del bus / data update detectado. Continuo o puntual. | EventBus event |
| **Submersión** | Entrar en el Tablet (open session). | Tablet open |
| **Sweep** | Búsqueda / scan de datos. Barrido filtrado. | Search / filter scan |
| **Surface** | Salir a vista amplia: zoom out, panoramic, overview mode. | Overview / zoom out |
| **Standby** | Estado inactivo pero alerta. El Tablet está "en standby". | Idle listening state |

### 15.D Data & tracking (9 términos)

| Término | Definición | Traducción técnica |
|---|---|---|
| **Eco** | Identifier inmutable de transacción/evento. Ej. `Eco: TXN-2026-0042`. | Transaction ID (IBAN-like format) |
| **Lineage** | Trail origen→destino de un batch (granja→molino→panadería→retail). | Supply chain traceability |
| **Manifiesto** | Contrato firmado entre dos contactos con cláusulas y eco de registro. | Signed contract / agreement |
| **Ping registry** | Log histórico de notificaciones del operador. | Notifications history |
| **Signature** | Firma digital criptágica sobre manifiesto. Bilateral + timestamp. | Digital signature |
| **Trace** | Investigación retrospectiva de un eco — sigue el trail. | Audit trace/investigation |
| **Waypoint** | Marcador espacial en mapa (periscope view). | Map marker |
| **Batch** | Lote de bienes con propiedades (calidad, cantidad, lineage). | Product batch |
| **Depth gauge** | Indicador visual de profundidad/tier/progreso. | Progress/tier indicator |

### 15.E Social & contracts (8 términos)

| Término | Definición | Traducción técnica |
|---|---|---|
| **Arbitraje** | Resolución de disputa por un tercero. | Dispute resolution |
| **Cargo** | Payload de un contrato (bienes, dinero, servicio). | Contract payload |
| **Contacto** | Otro operador detectado (player o NPC). Vocabulario player-facing. | Other player / NPC |
| **Convoy** | Agrupación de transportes (logística futura Oleada 2+). | Transport convoy |
| **Escort** | Acompañamiento de protección a convoy. | Protection escort |
| **Escrow** | Fondos en custodia entre handshake y liberación. | Escrow funds |
| **Squadron** | Empresa / grupo organizado de operadores. | Company / crew |
| **Alliance** | Federación entre squadrons (futuro). | Company alliance |

### 15.F Status & signals (8 términos ALL CAPS)

> **Convención:** status indicators siempre en `caps-md` o `caps-sm` (ALL CAPS tracking +0.05em / +0.08em).

| Término | Significado | Color indicador |
|---|---|---|
| **ACTIVE** | Operador en sesión, Tablet abierto. | Sonar Bright |
| **DIVE** | Focus mode, no-interrupciones. | Sonar Pulse |
| **ECHO** | Transacción registrada en bitácora. | Signal OK |
| **IDLE** | Operador conectado pero inactivo. | Crew 500 |
| **OFFLINE** | Operador desconectado. | Crew 700 |
| **SONAR-LOCK** | Estado read-only, sin mutaciones permitidas. | Coloro Support |
| **STANDBY** | Proceso esperando input. | Crew 300 |
| **SURFACE** | Operador en world, Tablet cerrado. | Crew 300 |

### 15.G Términos DEPRECATED (v1.0 Admirals — NO usar en new work)

> **Hard rule:** estos términos solo pueden aparecer en `_archive/`, ADRs históricos, SESSION_LOG entries históricas, o Phase 8 code refactor (renaming activamente). **Cero uso en new copy player-facing, new docs, new marketing.**

| Deprecated | Reemplazado por |
|---|---|
| Almirante / Almirantazgo | Operador / SONAR |
| Bienvenido a bordo | Console SONAR activada |
| Capitán / tripulación | Operador / squadron |
| Puerto | Node |
| Bahía / dique | Surface / Bridge |
| Pergamino / bitácora brass | Bitácora (preserved, pero sin materiales brass) |
| Brújula / sextante | Depth gauge (abstract) / Observation field (DEPRECATED v1 periscope) |
| Llave de latón | Layer-protection key (DEPRECATED v1 "pressure hull key" — hull reconceptualizado capas) |
| Sello de cera | Signature (digital) |

### 15.H Uso léxico cross-language

| Context | Español (primary) | Inglés (secondary) |
|---|---|---|
| UI player-facing | **Preferir castellano** con términos SONAR (ej. "Transferencia recibida", "Manifiesto firmado") | Inglés OK en términos muy técnicos — premium-tech feel (DEPRECATED Sweep/Dive sub-acoustic literal) |
| Marketing hero | Castellano brand-voice + taglines mixtos | Taglines inglés OK ("Hear the depth.") |
| Docs técnicos | Mixto — cada doc tiene convention declarada | Mayoría inglés en código, castellano en prosa |
| Sound naming (audio files) | N/A | Siempre inglés snake_case canonical post-ADR-012 (`signal_emerge.ogg`, `depth_press.ogg`, etc. — ver BRIEF-SOUND-001 v1). DEPRECATED v1 `sonar_*.ogg`. |

> **Meta-regla:** si un dev/AI duda entre dos palabras para nombrar algo nuevo, consulta este glossary PRIMERO. Si no existe término, **propone candidato + submite via PR/ADR** para consolidar vocabulario cross-touchpoint. **El léxico coherente es parte de la marca.**

---

## 16. Motion specs (ms-precise)

> **Full spec (Phase 4 detail-pass).** Principio base **S6 — Motion como agua profunda**: silenciosa, deliberada, con masa. Cero rebote excesivo, cero nervios, cero easings-default de librería.

### 16.1 Filosofía motion SONAR

- **Peso:** cada elemento animado tiene masa perceptible. Motion con física de agua profunda — hay resistencia antes de que se asiente.
- **Deliberación:** Motion breve pero nunca instantáneo. El operador percibe la causa-efecto.
- **Silent:** Motion no llama atención sobre sí mismo. Acompaña el flujo mental del operador.
- **Cero playful bounce:** springs con stiffness >400 + damping <20 están PROHIBIDOS (anti-pattern gen-Z portfolio bounce).

### 16.2 Duration tokens

| Token | ms | Uso |
|---|---|---|
| `motion-instant` | 80ms | Acknowledgments (button press recoil, hover on/off, focus state) |
| `motion-fast` | 150ms | Micro-interactions (tooltip appear, status change, tab underline slide) |
| `motion-base` | 200ms | Standard transitions (modal open, tab content switch, dropdown) |
| `motion-slow` | 320ms | Deliberate (page transition, card expand, drawer open) |
| `motion-deliberate` | 480ms | Rare ceremonial (boot splash fade, `signal_emerge_pulse` full cycle, login success) |
| `motion-signal-emerge` | 1200ms | `signal_emerge_pulse` animation glow soft pulse + scale-bounce subtle (canonical post-ADR-012, NO concentric waves — ver BRIEF-MOTION-001 v1 §4.4). DEPRECATED v1 `motion-sonar-ping`. |

**Regla:** nunca usar duraciones > 480ms salvo excepciones signature (`signal_emerge_pulse`, `logo_descent_reveal` boot). Motion prolongado aburre al operador en sesiones largas.

### 16.3 Easing curves (cubic-bezier)

| Token | Curve | Carácter | Uso |
|---|---|---|---|
| `ease-depth-descent` (DEPRECATED v1 `submarine-ease-out`) | `cubic-bezier(0.33, 1, 0.68, 1)` | Settling abstract | Default exit-to-rest (modal open, element appear) |
| `ease-depth-enter` (DEPRECATED v1 `submarine-ease-in`) | `cubic-bezier(0.32, 0, 0.67, 0)` | Compressing toward depth abstract | Entering, building presence (modal close, element disappear) |
| `ease-deliberate` (DEPRECATED v1 `submarine-ease-in-out`) | `cubic-bezier(0.65, 0, 0.35, 1)` | Balanced deliberate | Position transitions, tab switches |
| `ease-snap` (DEPRECATED v1 `submarine-snap`) | `cubic-bezier(0.17, 0.67, 0.33, 1.2)` | Microscopic overshoot (tactile) | Button press feedback, confirmation |
| `ease-signal-emerge` (DEPRECATED v1 `sonar-pulse`) | `cubic-bezier(0.4, 0, 0.2, 1)` | Smooth signal propagation | `signal_emerge_pulse` animations (NO concentric expanding waves) |

> **Default:** cuando un dev no sabe cuál usar, `ease-depth-descent` (DEPRECATED v1 `submarine-ease-out`) en `motion-base` (200ms) es la combinación universal segura.

### 16.4 Spring physics (Framer Motion config)

> **Cuando el motion necesita física real (no sólo curve), preferir springs sobre cubic-bezier largos.**

| Token | `stiffness` | `damping` | `mass` | Carácter | Uso |
|---|---|---|---|---|---|
| `springs.gentle` | 120 | 26 | 1 | Suave, sin overshoot | Modal enter, drawer open |
| `springs.default` | 170 | 28 | 1 | Equilibrado, pequeño settle | Card expand, accordion |
| `springs.precise` | 240 | 32 | 0.8 | Rápido y firme | Micro-interactions, UI controls |
| `springs.deliberate` | 80 | 30 | 1.2 | Peso alto, settle lento | Boot splash, ceremonial reveals |

**PROHIBIDO:** `springs.bouncy` (stiffness >400, damping <20) — anti-pattern "playful bounce" portfolio JS.

### 16.5 Motion pattern catalog

| Patrón | Especificación | Uso |
|---|---|---|
| **Modal enter** | `opacity: 0 → 1` + `translateY: +8px → 0`, `springs.gentle` | Todo modal, drawer, overlay |
| **Modal exit** | `opacity: 1 → 0` + `translateY: 0 → +4px`, `submarine-ease-out motion-fast` | Closing modales |
| **Tab switch** | Underline slide `submarine-ease-in-out motion-base` + content crossfade `motion-fast` | Tab navigation |
| **Sonar ping** | Radial gradient `scale: 0 → 1` + `opacity: 1 → 0`, `sonar-pulse motion-sonar-ping` | Notificaciones primarias, logo animado, splash |
| **List stagger** | Item enter delay 40ms each, `springs.precise` | Listas que aparecen (ledger, contacts) |
| **Button press** | `scale: 1 → 0.97 → 1`, `submarine-snap` 120ms | CTAs, tactile feedback |
| **Depth gauge load** | Arc `stroke-dashoffset` desde full → 0, `submarine-ease-in-out motion-deliberate` | Loading progress |
| **Notification badge** | `scale: 0 → 1` + `opacity: 0 → 1`, `springs.gentle motion-base` | Badge counter appear |
| **Focus ring** | Sonar Bright ring `box-shadow` appear instant-fade, `motion-instant` | Input focus, keyboard nav |
| **Page transition** | `opacity + translateY` cross `submarine-ease-in-out motion-slow` | Full page route change |
| **Hatch open** | Stage 1 seal-break `motion-fast` + Stage 2 content reveal `motion-slow` | App launch (tablet), premium modal |
| **Sweep scan** | Horizontal gradient sweep `motion-deliberate`, loop | Loading/scanning states |

### 16.6 Accessibility — `prefers-reduced-motion`

> **Crítico:** TODAS las animaciones deben respetar `@media (prefers-reduced-motion: reduce)`.

Replace patterns:
- **Springs y easings** → `opacity-only` transitions en `motion-instant` (80ms linear).
- **Sonar ping concentric** → **DESACTIVADO** (sin expansion). Badge estático + color.
- **Pulse animations** → color estático enfatizado, sin motion.
- **Stagger delays** → eliminados, todo aparece simultáneo.
- **Scale transforms** → eliminados (no button press, no modal scale).
- **Translate transforms** → eliminados (no slide-in patterns).

Test obligatorio: con `prefers-reduced-motion: reduce` activo, el Tablet debe seguir siendo **100% funcional y visualmente claro** — solo más quieto.

### 16.7 Performance budgets motion

- **FPS target:** 60fps constantes en animations. 120fps nice-to-have para monitores high-refresh.
- **GPU-accelerated props:** priorizar `transform` + `opacity` (compositor-only). Evitar animar `width/height/top/left` (layout thrashing).
- **Concurrent animations max:** 3 simultáneas en una misma surface (más = ruido visual + perf).
- **Frame budget NUI:** < 8ms per frame (target 60fps = 16.7ms, dejar margen).

---

## 17. Verticales placeholder (stubs futuros Oleada 2+)

> **Scope:** stubs de identidad por vertical futuro. Cada vertical tendrá su **doc dedicado** detallado (e.g., `docs/design/<NN>_node_<name>.md`) durante Phase 7 doc purge. Aquí documentamos solo concept statement + sub-paleta preliminar + ícono + sound + signal integration SONAR.

> **Principio cross-vertical:** todos respiran bajo meta-brand SONAR (Tier B identity pop + abyss canvas). Cada vertical aporta **un acento cultural de 1-2 colores** en tier vertical (no en Tier A/B/C meta-brand).

### 17.1 Panadería — "Surface node manufactura fina"

**Concept statement:**
> *"Surface node de manufactura fina. Calor seco del horno, harina en el aire, aroma que viaja. El tiempo aquí se mide en fermentaciones y ciclos de horno — cada batch lleva su eco de calidad escalada."*

**Mood reference:** Chef's Table bread episodes, artisan wood-fired bakery aesthetic, cobblestone alley mornings.

**Sub-paleta preliminar (acento vertical):**
| Nombre | Hex | Uso |
|---|---|---|
| **Bread Gold** | `#C9A566` | Acento cultural primario (signage, uniformes, packaging). |
| **Flour White** | `#F5EDDF` | Packaging clean + dust texture surfaces. |
| **Oven Glow** | `#E67E43` | Warmth accent interior (fire signal). Rare decorative use only. |

**Icon signature:** `bread-loaf` + `wheat-sheaf-processed` (stylized crust pattern).

**Sound signature:**
- `bakery_oven_open` — puerta horno + calor escapando (200ms).
- `bakery_knead` — amasado rítmico (loopable).
- Ambient panadería: horno crackling + aromas (implicit) + llenado tranvias.

**Signal protocol SONAR:**
- `bake_ping` event — batch de pan listo para recoger (payload: `batch_id`, `quality`, `lineage_molino_origin`, `baker_operator`).
- `fermentation_timer_ping` — masa lista próxima fase.
- Integra con `SONAR OS Granja` (origin lineage) + `SONAR OS Molino` (flour input).

---

### 17.2 Retail — "Surface node transacción consumer-facing"

**Concept statement:**
> *"Surface node de punto de venta. Consumer-facing, transacciones rápidas, receipts impresos, escaparates organizados. Donde el operador meets the NPC public demand — cada venta es un eco en el ledger SONAR."*

**Mood reference:** Parisian concept stores, clean minimal boutique (Aesop, Muji), fluorescent-but-tasteful lighting.

**Sub-paleta preliminar:**
| Nombre | Hex | Uso |
|---|---|---|
| **Retail Cream** | `#EFE8DD` | Surfaces clínicas (counters, walls). |
| **Receipt Paper** | `#F9F5EC` | Printed materials, receipts in-world. |
| **POS Green** | `#4A8A6B` | Confirmation accent (transaction OK). Desaturated forest. |

**Icon signature:** `shopping-bag` + `receipt-printer` + `barcode-scan`.

**Sound signature:**
- `retail_pos_confirm` — print receipt + drawer open (600ms).
- `retail_bell_entry` — campanita entrada NPC cliente (200ms).
- Ambient: conversación ambiental baja + música ambiente lounge.

**Signal protocol SONAR:**
- `sale_ping` — venta consumer-NPC ejecutada (payload: `items[]`, `total`, `operator`, `timestamp`).
- `stock_low_ping` — inventario crítico bajo.
- Integra con cualquier vertical upstream (Panadería, Granja direct, etc.) via lineage.

---

### 17.3 Cervecería — "Surface node fermentación artesanal"

**Concept statement:**
> *"Surface node de fermentación artística lenta. Cobre pulido, vapor aromatizado, paciencia obligatoria — cada lote fermenta en su tiempo biológico. El cobre **no se pule para brillar**; se pule para no-corroerse. La diferencia importa."*

**Mood reference:** Craft brewery modern (Brewdog, Stone Brewing visual), steampunk-light touch, industrial lighting.

**Sub-paleta preliminar:**
| Nombre | Hex | Uso |
|---|---|---|
| **Copper Vessel** | `#B97B45` | Acento principal (tanks, instruments, packaging emboss). |
| **Hop Green** | `#7A9464` | Secondary natural (ingredient iconography). |
| **Amber Ale** | `#C78B3A` | Product color reference (fills en UI, liquid renders 3D). |

**Icon signature:** `brewery-tank` + `hop-flower` + `tap-dispenser`.

**Sound signature:**
- `brewery_ferment_bubble` — burbujeo lento tanque (loopable subtle).
- `brewery_tap_pour` — pour cerveza en vaso (1s con foam hiss).
- `brewery_steam_release` — válvula steam venting (400ms).
- Ambient: bubbles + máquinas pressure + distant radio.

**Signal protocol SONAR:**
- `ferment_ping` — lote alcanza fase fermentación clave (day N, gravity reading).
- `tap_ping` — nueva cerveza lista servir en tap público.
- `batch_ready_ping` — ciclo fermentación completo, stock disponible.

---

### 17.4 Mecánico — "Surface node reparación + modificación"

**Concept statement:**
> *"Surface node de reparación y mod tuning. Grease, soldadura, suspensión de piezas colgantes, tools organized by frequency-of-use. Precision industrial — aquí se restauran vehículos con la misma precisión con la que SONAR registra transacciones."*

**Mood reference:** High-end custom garage (Singer Porsche, ICON 4x4 aesthetic), tool boards + diamond-plate floors.

**Sub-paleta preliminar:**
| Nombre | Hex | Uso |
|---|---|---|
| **Grease Black** | `#1A1612` | Surfaces industrial sucio (pisos, herramientas). Diferente de abyss-black, tinte warmer. |
| **Safety Yellow** | `#E8B733` | Acento safety (lines on floor, high-vis). Rare strategic use. |
| **Steel Blue** | `#4A5A6B` | Tools + bolts + hardware accent. |

**Icon signature:** `wrench` + `engine-block` + `welding-torch`.

**Sound signature:**
- `mechanic_wrench_tighten` — torque ratchet (300ms).
- `mechanic_weld_arc` — soldadura arc (loopable + sparkle hits).
- `mechanic_engine_rev` — test rev vehículo (1s, configurable pitch).
- Ambient: metal clanking + compressor + radio AM tuner.

**Signal protocol SONAR:**
- `repair_ping` — reparación completada (payload: `vehicle_id`, `parts_used[]`, `cost`, `mechanic_operator`).
- `invoice_ping` — invoice generado hacia cliente operador.
- `mod_install_ping` — mod/tune instalado (tier upgrade tracked).

---

### 17.5 Cross-vertical integration patterns

> **Principio:** cada signal protocol de vertical genera un `Eco` trackeable en SONAR Bank. Los `lineage` cadenas cross-vertical (Granja → Molino → Panadería → Retail) son el corazón economico del ecosystem.

**Ejemplo lineage end-to-end:**

```
farmer harvests wheat (harvest_ping)
    ↓ eco FARM-2026-0042
miller processes batch (mill_ping)
    ↓ eco MILL-2026-0018 + lineage: [FARM-2026-0042]
baker produces bread batch (bake_ping)
    ↓ eco BAKE-2026-0007 + lineage: [MILL-2026-0018, FARM-2026-0042]
retailer sells to NPC (sale_ping)
    ↓ eco SALE-2026-2148 + lineage: [BAKE-2026-0007, MILL-2026-0018, FARM-2026-0042]
SONAR records complete chain in bitácora
```

**Cada vertical preserva su identidad cultural (color + sound + ícono)**, pero **comparte protocolo SONAR** (eco IDs + lineage + signals). Esta es la **coherencia meta-brand** que nos diferencia radicalmente en el mercado.

---

## 18. Storybook integration specs

> **Full spec (Phase 4 detail-pass).** Storybook es la **documentation live de components React** del Tablet NUI. Cross-ref canonical: `docs/technical/04_storybook_guide.md` (doc técnico dedicado). Esta sección define **contratos design-side** con Storybook.

### 18.1 Purpose & scope

- **Propósito:** cada componente del Tablet SONAR renderizado aislado + todas sus variants + stories que ejercitan los casos de uso (active/inactive/loading/error/empty).
- **Audience:** dev frontend (implementation reference) + designer (visual verification) + founder (review visual sin booting FiveM completo).
- **Scope:** solo components React del Tablet NUI. No cubre Lua server nor 3D assets.

### 18.2 Component organization (carpeta estructura)

```
/stories/
├── primitives/              # Atomic (Button, Input, Badge, Icon)
├── components/              # Molecules (Card, Modal, TabBar, NotificationDrawer)
├── patterns/                # Organisms (LedgerTable, ContractSigner, DashboardBridge)
├── screens/                 # Full screens (BankHome, MarketPlaza, GranjaAdmin)
└── tokens/                  # Design tokens visualizers (colors, type, motion, spacing)
```

### 18.3 Design tokens pipeline (Figma → code)

- **Source of truth:** Design system Figma library (§13.1.2).
- **Pipeline:**
  1. Designer actualiza tokens en Figma (via Tokens Studio plugin o similar).
  2. Export JSON via figma-export API → `tokens/` folder en repo.
  3. Script TypeScript `tokens.ts` genera constantes typed (`colors.sonarBright`, `motion.base`, `type.displayLg`).
  4. Storybook theme consume `tokens.ts` → 100% parity Figma ↔ Storybook ↔ código producción.
- **Regla crítica:** **ningún código hardcodea valores** (color hex, duración ms, px). Todo vía tokens. Si falta token, abrir issue a Figma primero.

### 18.4 Stories obligatorias por component

Cada component debe tener **mínimo 4 stories**:

1. **`Default`** — estado canónico nominal.
2. **`AllVariants`** — grid visual de todas las variants (size, color, state).
3. **`Interactive`** — with actions/state toggles + play-function Testing Library.
4. **`EdgeCases`** — empty state, loading, error, overflow, truncation, long text, a11y reduced-motion simulation.

**Opcional per caso:** `DarkMode`, `LightMode`, `ResponsiveBreakpoints`, `PerformanceStressTest` (muchas instancias simultáneas).

### 18.5 Naming convention

- **Stories directorio:** PascalCase reflejando component (`Button.stories.tsx`).
- **Story names:** sentence case describing scenario (`"Primary with icon"`, `"Loading state"`, `"Empty ledger message"`).
- **Vocabulario:** siempre per Glossary §15 (e.g., `Operador profile card`, `Manifiesto signer modal`, `Ping notification tray`). **Cero drift a v1.0 Admirals lexicon.**

### 18.6 Visual regression testing

- **Tool target:** Chromatic o Percy (decisión Phase 6 + ADR si significativa).
- **Baseline:** firmar baseline al cerrar cada oleada (tag `storybook-oleada-<N>-baseline`).
- **CI integration:** fail PR si snapshot diff >0.1% sin approval explícito founder/Cascade.

### 18.7 Performance budgets NUI components

- **Single component mount:** <16ms render (under 1 frame).
- **Full screen cold start:** <200ms (sin `signal_emerge` audio; con audio, +100ms overhead acceptable).
- **Storybook interaction tests:** <5s per story CI time.

---

## 19. Shader contracts specs (FiveM integration)

> **Full spec (Phase 4 detail-pass).** Shader contracts definen cómo los shaders custom integran con la aesthetic SONAR (abyss canvas, bioluminescent glow, glassmorphism instruments). Cross-ref canonical: `docs/technical/02_shader_contracts.md` (post-pivot update pendiente). Esta sección define **contratos visuales**, el file técnico define **parámetros exactos GTA V engine + HLSL**.

### 19.1 Shaders SONAR catalog

| Shader | Uso | Target | Prioridad |
|---|---|---|---|
| **sonar-mesh-grid-shader** | Background pattern sutil en surfaces premium (Tablet Pro+, Bank sede MLO). | NUI HTML + 3D world | 🟡 P1 Oleada 2 |
| **abyss-fog-shader** | Depth fog post-process FiveM world en zonas interior MLO SONAR (Bank, Granja admin). Desaturación + tinte Depth 800. | 3D world | 🟢 P2 Oleada 3 |
| **bioluminescence-particle-shader** | Ping expansions + data highlight particles (Tablet NUI + 3D world overlays). | NUI + 3D | 🟡 P1 Oleada 2 |
| **glassmorphism-fallback-shader** | Simulación glassmorphism en contextos sin `backdrop-filter` support (fallback FiveM older builds). | NUI HTML canvas | 🟢 P2 |
| **depth-gauge-lcd-shader** | Simulación LCD retroiluminado en instruments 3D (silo, tank, depth indicators). | 3D prop | 🟢 P2 |
| **sonar-pulse-wave-shader** | Onda concéntrica sonar expandiéndose (signal beacon 3D world). | 3D world | 🟢 P2 |

### 19.2 Performance contracts

> **Principio base:** shaders custom son optimizaciones visuales, NUNCA degradan la experiencia base.

- **FPS target preserved:** adición de shaders NUNCA reduce FPS baseline >5% en hardware mid-tier (RX 5600 / RTX 3060 / equivalents).
- **Per-pixel operations budget:** <4 texture samples + <8 ALU operations per pixel para shaders NUI.
- **LOD-aware:** shaders 3D degradan progresivamente con distancia camera (full effect <20m, half <50m, off >100m).
- **Fallback obligatorio:** todo shader tiene fallback sin shader (plain texture + shadow) si flag `shaders_enabled = false`.

### 19.3 Integration points

- **NUI shaders:** CSS filters + WebGL canvas overlays (fallback `backdrop-filter` → gradient emulation).
- **3D world shaders:** `.fxc` compiled via OpenIV pipeline; `ytd` texture dictionaries + `sps` shader presets.
- **Hybrid (NUI overlay 3D world):** sonar ping 3D beacon sincronizado con NUI notification via `lib-gtamp` or custom React Three Fiber bridge (TBD Phase 6 ADR).

### 19.4 Aesthetic contracts

- **Color palette compliance:** shaders usan SOLO colores Tier A/B/C + Crew + Signal + verticales sub-paletas. Cero colores custom hardcoded in shaders.
- **Tinting parametrizable:** shaders aceptan uniform `u_tint_color` para adaptación por contexto (e.g., silo verde eco OK, silo rojo alert).
- **Motion rules inheritance:** shaders animados respetan §16 motion filosofía (cero bounce excesivo, durations tokens, reduced-motion disabled).

### 19.5 Anti-patterns shader

- ❌ Bloom/glow excesivo "portfolio cyberpunk style" → mata la aesthetic premium-tech neutral (DEPRECATED v1 "silent service").
- ❌ Color cycling rainbow → inmediate disqualify (viola palette Tier governance).
- ❌ Particle emission ilimitada → performance killer.
- ❌ Post-process full-screen constantly-on (solo activar per-zone MLO o per-event).
- ❌ Shaders sin fallback → rompe experiencia hardware antiguo.

---

## 20. Roadmap art direction iterations

> **Full spec (Phase 4 detail-pass).** Cómo evoluciona este doc en el tiempo + triggers para version bumps + cadence de review.

### 20.1 Living document policy (per ADR-007)

Este doc es **living document** — se actualiza continuamente post-firma v2.0 según evolución producto. Versiones siguen semver-like:

- **Patch (v2.0.X):** correcciones tipográficas, aclaraciones, typos, enlaces rotos. **NO requiere ADR.**
- **Minor (v2.X):** adiciones incrementales (nuevo vertical stub, nueva texture, refinement token). **ADR recomendado si invalida pattern previo.**
- **Major (vX.0):** refactor significativo (palette rework, tipografía change, rebranding). **ADR obligatorio + founder approval formal.**

### 20.2 v2.1 trigger conditions

> *Cuándo activar bump minor v2.0 → v2.1:*

- ✅ Primer vertical Oleada 3 (Panadería MVP) llega a production → promote su stub §17.1 a sección dedicada full-detail + doc `docs/design/03_node_bakery.md`.
- ✅ Usability feedback NUI tras launch Oleada 1 genera insights visuales concretos (ajustes tokens type scale, spacing, contrasts específicos).
- ✅ Sound design real-world testing revela que SFX firma necesita tuning (volumen, EQ, decay times).
- ✅ Logo final post-designer entregado → bump §3.3 a "firmable designer-locked".
- ✅ Custom icon set 8 post-designer entregado → bump §5.2 a "firmable designer-locked".

**Target fecha estimada:** Q2 2026 (post-Oleada 1 launch + 1 oleada-de-vida feedback).

### 20.3 v2.2 trigger conditions

> *Cuándo activar bump minor v2.1 → v2.2:*

- ✅ Palette refinement tras production real: tintas específicas emergen (e.g., Depth 750 intermedia, nueva Signal sub-level).
- ✅ Integration patterns inter-vertical más maduros revelan nuevos cross-patterns que ameritan sección dedicada (ej. §17.6 Interoperability patterns).
- ✅ Community feedback positivo acumulado valida identidad core + señala micro-ajustes en voice/tone.
- ✅ Marketing assets iteración 2 (trailer Oleada 2, rebrand website, new screenshots curated) consolidados.

**Target fecha estimada:** Q4 2026 - Q1 2027.

### 20.4 v3.0 trigger conditions

> *Cuándo activar bump major v2.X → v3.0:*

- 🚨 Major product pivot (nuevo paradigma operativo, plataforma adicional, second-brand).
- 🚨 Rebranding ejecutivo (SONAR name/logo change — extreme case).
- 🚨 Palette core change approved por founder (ej. shift de teal a cyan puro, o adición de brand hero color).
- 🚨 Tipografía familia principal swap (ej. Geist → custom-designed typeface post-funding).
- 🚨 Art direction refactor post-5 años producto-living (natural refresh cycle).

**Target fecha estimada:** ≥ 2028 o trigger-based sin ETA.

### 20.5 Review cadence

- **Cada cierre de oleada:** review rápido this doc (~30 min) — detectar drift + typos + inconsistencies acumuladas + update §14.2 checklist tickmarks.
- **Cada 6 meses (Q2 + Q4):** review formal founder + Cascade architect — evaluar si triggers v2.X conditions met + planning bump.
- **Cada major release producto (Oleada complete):** review completo + SESSION_LOG entry documentando decisiones arte → update history.
- **Ad-hoc cuando red flag detectado:** si dev/AI encuentra contradicción doc vs code o doc vs doc, reporta immediate + resolve.

### 20.6 Changelog discipline

- Cada bump **requiere entry en changelog footer** (este doc §Changelog).
- Entry format: `| vX.Y.Z | date | author | cambios concretos + razón + secciones tocadas + cross-refs ADR |`.
- Entries **nunca se editan retroactivamente** (append-only, igual SESSION_LOG).
- Si error en entry pasada → nueva entry correctiva referenciando original.

---

## Estado del documento

- **Versión:** **3.0-locked** (post-ADR-016 — palette tokens canónicos + dark-only doctrine + 3-color strict + trend stack tiered + Tablet UI stack frozen + NUI perf budgets locked via IDENTITY V3 LOCK NOTICE top-level).
- **Próxima revisión:** v3.1 minor bump si Phase 4.5 v2 briefs (icons/sound/motion/marketing) entregados en S2 prep, o post-MVP S2 retro si D3 3-color re-evaluación trigger fire.
- **Briefs operacionales:**
  - ✅ Brief logo v3 firmable `@docs/art/branding/01_brief_logo.md` (post Item B S1.10.5).
  - 🟡 Briefs v2 icons/sound/motion/marketing delivered S1 — pendientes update v3 para identity v3 doctrine alignment (post Sprint 2 prep).
- **Logo system v3 firmable:** `@art/branding/logo_v3/` (4 monogramas + wordmark + 2 lockups + preview + export pipeline).
- **Stack Tablet UI:** `@resources/sonar_tablet/web-src/package.json` (downgrade D5 spec post Item A S1.10.5).
- **Reemplaza:** `_archive/01_art_direction_v1_admirals.md` v1.0 (deprecated).
- **ADR origen:** ADR-011 + ADR-012 + **ADR-016** (`planning/02_decision_log.md` §11 + `02_decision_log_part2.md` v1.0 ADR-016).

### Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026 (varias) | Founder + Cascade | v1.0 firmada Admirals/Almirantazgo (2678 líneas). Archivada por ADR-011. |
| 2.0-scaffold | 2026-05-03 | Founder + Cascade | **Foundational scaffolding post-pivot SONAR**. Estructura completa 20 secciones + decisiones foundational firmes (paleta hex, tipografía, voz, sound, iconografía nombres). Detalle pendiente Phase 4 detail-pass dedicada. |
| 2.0-scaffold-r1 | 2026-05-03 | Founder + Cascade | **Inversión jerarquía paleta meta-brand** (founder strategic correction pre-Phase 4): `Sonar Bright #2DD4BF` promovido a **PRIMARY BRAND IDENTITY** (Tier B — logo, CTAs, branding marketing, app-icon, focus rings). `Coloro 092-37-14 #175A5F` desciende a **structural support tier** (Tier C — glassmorphism tints, inactive borders, deep-tier UI; cero uso en logo/branding identity). Razón founder: marca SONAR percibida como **bioluminescencia + energía tecnológica**, firma en mercado = brillo, no oscuridad. Abyss Black canvas preservado para descanso visual sesiones largas (dark-mode-first). Reorganización §3.4.1 en 3 tiers (A canvas, B identity pop, C structural support) + §3.4.4 60/25/10/5/<3 ratios + §3.3 logo rules updated + §3.4.6 ping color = Sonar Bright. |
| 2.0-scaffold-r2 | 2026-05-03 | Founder + Cascade | **Phase 4 partial attack (Sonnet-compatible slices)** post-commit checkpoint 6d3d96c: (a) **§4.2 Type scale detail-pass** — tokens canónicos completos con line-height (ratio + px absoluto), letter-spacing, familia+peso; responsive breakpoints website xs/sm/md/lg/xl; 6 reglas de aplicación tipográfica. (b) **§15 Glossary expandido** de 13 a 55+ términos organizados en 7 categorías (A meta-brand core ×9, B UI elements ×11, C actions/ops ×10, D data/tracking ×9, E social/contracts ×8, F status signals ALL CAPS ×8, G deprecated v1.0 Admirals ×9 + H uso cross-language). Canonical SSoT léxico para Phases 5-7. (c) **§16 Motion specs detalladas** — filosofía S6, duration tokens ×6 ms-precise, easing curves cubic-bezier ×5 submarine-themed, spring physics Framer Motion ×4 configs, motion pattern catalog ×12 patrones, a11y prefers-reduced-motion, performance budgets NUI. (d) Residuals fix: §11 lock screen + §12 website — Coloro identity refs → Sonar Bright per r1 hierarchy. Secciones pendientes Opus: §3.3 logo construction, §5.2 custom icon SVG, §12 marketing moodboard, §13 plan assets, §14 governance, §17-20 verticales/storybook/shader/roadmap. |
| 2.0-scaffold-r3 | 2026-05-03 | Founder + Cascade | **Phase 4 partial continuation (Sonnet-compatible administrative + stubs)** post-commit 0b2b47e: (a) **§13 Plan de assets completo** — catalog 3D+2D+sound+branding con priority per-oleada, briefing template markdown equipo 3D externo, prioridades oleadas 1-3+, repo structure assets (git LFS strategy), licensing + rights clauses. (b) **§14 Governance del arte completo** — review process matrix qué requiere ADR, signing protocol v2.0 firmable checklist ×20 criterios, version control assets repo, designer collaboration workflow (3 phases briefing/iteration/delivery + red flags), anti-patterns governance. (c) **§17 Verticales placeholder stubs** — Panadería (concept + sub-paleta + sound + signal bake_ping), Retail (concept + sub-paleta + signal sale_ping), Cervecería (concept + sub-paleta + signal ferment_ping/tap_ping), Mecánico (concept + sub-paleta + signal repair_ping/invoice_ping) + cross-vertical integration pattern con ejemplo lineage end-to-end Granja→Molino→Panadería→Retail. Secciones pendientes Opus: §3.3 logo visual, §5.2 icons SVG, §6 textures repo, §7.3 sound bibliography, §9-§10 nodes detail, §11 Tablet cross-ref, §12 marketing, §18-20 storybook/shader/roadmap. |
| 2.0-scaffold-r4 | 2026-05-03 | Founder + Cascade | **Phase 4 Sonnet scaffold 100% complete** post-commit d0ecfeb: (a) **§18 Storybook integration specs** — purpose/scope, component organization `/stories/` (primitives/components/patterns/screens/tokens), design tokens pipeline Figma → code (Tokens Studio → JSON → TS typed), stories obligatorias por component ×4 (Default/AllVariants/Interactive/EdgeCases), naming convention (Glossary §15 aligned), visual regression testing (Chromatic/Percy), perf budgets NUI (<16ms mount, <200ms cold start, <5s CI). (b) **§19 Shader contracts specs** — catalog ×6 shaders SONAR (mesh-grid, abyss-fog, bioluminescence-particle, glassmorphism-fallback, depth-gauge-LCD, sonar-pulse-wave) con target + prioridad, performance contracts (FPS <5% reduction, LOD-aware, fallback obligatorio), integration points NUI/3D/hybrid, aesthetic contracts (palette compliance + tint parametrizable + motion inheritance), anti-patterns ×5. (c) **§20 Roadmap art direction iterations** — living document policy per ADR-007 (patch/minor/major semver), v2.1 trigger conditions (×5 Q2 2026), v2.2 triggers (×4 Q4 2026-Q1 2027), v3.0 triggers (×5, ≥2028), review cadence (cierre oleada + Q2/Q4 + major release + ad-hoc), changelog discipline append-only. (d) Cleanup: unicode escapes literales fixed (`\u2014` → —, `\u2265` → ≥), duplicate separator removed, §14.2 checklist ticks updated. **Sonnet-doable scaffold 100% terminado** — remaining slices requieren designer/Opus creative density. |
| 2.0-scaffold-r5 | 2026-05-03 | Founder + Cascade | **Phase 4.5 partial — Specialist briefs delivered (Sonnet)** post-commit b480af5: (a) Created `docs/art/briefs/` directory + README index. (b) **BRIEF-LOGO-001** — paquete encargo completo logo SONAR (~270 líneas): contexto proyecto, 10 deliverables (SVGs + PNGs + lockups + glow variants + guidelines PDF + Figma source), specs técnicos vinculantes (concepto S-onda locked, color tokens Tier B, tipografía wordmark Geist Sans, geometry 12×12 grid, 5 lockups), do/don't ✅×6 ❌×11, referencias visuales (5 convergir + 5 anti), 5 review gates R0-R4, licensing + NDA + presupuesto orientativo €1.5-3.5k, founder pre-kickoff checklist ×6. (c) **BRIEF-ICONS-001** — paquete encargo iconografía custom 8 esenciales (~280 líneas): los 8 iconos locked (sonar-ping/submarine/depth-gauge/hydrophone/bioluminescence/pressure-hull/periscope/torpedo-bay) + 2 stretch (manifiesto/bitacora), 32 SVG files target + React TS lib + Figma + guidelines PDF + showcase PNG, specs canvas 24×24 stroke 1.5px round Lucide-compatible, guidance per-icon individual ×8, do/don't, 4 review gates R0-R3, licensing + presupuesto €1.2-2.8k. (d) Cross-refs §3.3 + §5.2 → briefs/. Pendiente Phase 4.5: BRIEF-SOUND-001 + BRIEF-MOTION-001 + BRIEF-MARKETING-001. |
| 2.0-scaffold-r6 | 2026-05-03 | Founder + Cascade | **REFINEMENT NOTICE r6 (per ADR-012)** post-commit d0712cc: top-level NOTICE establece NEW CANONICAL vigente desde hoy: (a) **Metáfora abstracta pura** (profundidad + exploración simbólica, NO submarino militar literal NO radios/freq) — explicit purga `sonar-ping`/`submarine`/`hydrophone`/`periscope`/`torpedo-bay` icons + voz capitán submarino + sound names sub-acoustic. (b) **Hybrid theme dark+white surfaces** (Notion/Arc/Stripe Dashboard ratio ~30-40% dark + ~30-40% white surfaces + ~10-15% Sonar Bright + ~10% structural + <5% signals) reemplaza dark-extremo 60% scaffold-r1. (c) **Voz neutral premium-tech** (Vercel/Linear/Stripe copy style) elimina arquetipo militar. (d) **Iconografía 3/8 conservados** (depth-gauge + pressure-hull reconceptualizado capas + bioluminescence) + 5 candidatos abstractos a definir Phase 4.5 v2. (e) **Sound naming refactored** sin radio/freq. (f) **Glossary cleanup** Console/Bridge/Depth/Eco OK; Periscope/Hatch/Hydrophone/Ping/Sweep deprecated. §1-§20 NO surgical rewrite todavía — NOTICE supersedes en cualquier conflicto, Phase 4.5 v2 hará surgical full. Briefs v1 (logo + icons + README) descartados. |
| 2.0-scaffold-r7 | 2026-05-03 | Founder + Cascade | **Phase 4 surgical full inline cleanup post-ADR-012** post-commits `5838a79` (briefs v2) + `a879c45` (BOOTSTRAP v1.5). Surgical inline rewrite §1-§20 alineado NOTICE r6 + ADR-012 (NOTICE r6 sigue vigente como top-level canonical, pero ahora contenido inline también purged). **Cambios secciones:** (a) **§0.1 Tesis central** rewrite ("infrastructure premium-tech... metáfora simbólica de profundidad NO submarino militar literal"; lema canonical "Hear the depth."). (b) **§1.2 Anti-references table**: 4 NEW deprecated rows (submarino militar literal + voz arquetipo militar + theme dark-extremo 60% + tactical operator). (c) **§1.3 Comparativa competidores**: SONAR row purged ("Hybrid theme + neutral premium-tech + Cero arquetipo militar"). (d) **§2 Metáfora central** full rewrite: "Profundidad simbólica abstracta" (§2.1 razón abstract + §2.2 elements canonical/deprecated table 10 rows + §2.3 ecosystem grid re-frased). (e) **§3.1 Tagline operacional** "Production-grade" (deprecated "Tactical-grade"). (f) **§3.2 Voz de marca** full rewrite (neutral premium-tech + vocabulario canonical + DEPRECATED + 5 ejemplos canonical r6 + 4 anti-ejemplos). (g) **§3.3 Logo** concepto NO-LOCKED (5 candidatos preliminares Phase 4.5 v2; deprecated S-onda concéntrica). (h) **§3.4 Paleta**: Tier A heading ratios actualizado (~30-40% pantalla post-ADR-012); ratios CANONICAL hybrid theme (5 buckets: dark ~30-40% + white ~30-40% + Sonar Bright ~10-15% + Coloro ~10% + signals <5%); deprecated scaffold-r1 60% explícito. Sonar Glow + glow rules updated `signal_emerge_pulse` (no concentric expanding). (i) **§4.3 Type rules** ALL CAPS examples premium-tech (deprecated DIVE/SURFACE sub-acoustic). (j) **§7.1-§7.2 Sound** filosofía "El silencio es diseño" (deprecated "silent service"); 5 SFX descriptions canonical r6 + DEPRECATED v1 mapping + character refs Apple/Vercel/Notion/Stripe. (k) **§15 Glossary**: Origen léxico re-frased; §15.A Bridge re-interpretado + Silent service deprecated; §15.B Hatch/Periscope/Porthole deprecated entries; §15.G/§15.H deprecated mappings updated. (l) **§16 Motion**: easing curves rebrand (`ease-depth-descent`/`ease-depth-enter`/`ease-deliberate`/`ease-snap`/`ease-signal-emerge` con DEPRECATED v1 submarine-* names); duration token `motion-signal-emerge`; default reference updated. (m) **§19.5 Anti-pattern shader** "premium-tech neutral" (deprecated "silent service"). **PowerShell bulk-replace step:** ejecutado para `sonar_ping/pressure/depth/console/hatch` SFX + `sonar-ping`/`hydrophone`/`periscope`/`torpedo-bay` icons → canonical post-ADR-012 names; restoración manual NOTICE r6 mapping table + r6 changelog entry afectados (corrupción contained, fix in-session). **Footer state + tagline + FIN line** actualizados v2.0-scaffold-r7. Cross-refs: ADR-012 + BRIEF-LOGO-001 v2 + BRIEF-ICONS-001 v2 + BRIEF-SOUND-001 v1 + BRIEF-MOTION-001 v1 + BRIEF-MARKETING-001 v1. **Pendiente Phase 4 ejecución creativa**: logo SVG real + icons set real + sound files real + motion patterns real + marketing assets real → bump v2.0 firmable. |
| **3.0-locked** | 2026-05-04 | Founder + Cascade (Sonnet 4.5, S1.10.5 Item C) | **🟢 IDENTITY V3 LOCK NOTICE inserted top-level** post-ADR-016 (`@docs/planning/02_decision_log_part2.md` v1.0). Capa canónica más reciente — supersedes NOTICE r6 + scaffold-r1..r7 inline en cualquier conflicto palette/theme/stack/perf. **6 doctrines locked:** (D1) Palette tokens canónicos `--sonar-black` `#060607` + `--sonar-orange` `#FF5100` + `--sonar-white` `#FAFAFA` (REPLACES Sonar Bright teal `#2DD4BF` + Coloro `#175A5F` + hybrid 5-tier). Tokens DEPRECATED v2 explicit (8 tokens purged). (D2) Dark-only doctrine product (REPLACES hybrid theme dark+white surfaces NOTICE r6). Excepción única `monogram_s_black.svg` print/external (D-S1.10E-A). (D3) 3-color strict — no green/red/yellow/blue accents. Estados via Lucide icons + typography weight + motion. Re-evaluable post-MVP S2. (D4) Trend stack 2026 tiered T1 adopt heavy / T2 selective / T3 prohibited. (D5) Tablet UI stack frozen S2-S8: React 18.3 + Vite 5.x + TS strict + Tailwind v4 `@theme` + shadcn dark-only + Framer Motion 11 + Lucide React + Recharts + React Context+useReducer (NO Zustand). (D6) NUI perf hard constraints: ≤4ms paint, ≤500KB JS gzipped, ≤80MB heap, GPU-only animations, react-window virtualization >50 items. **Logo system v3 firmable** `@art/branding/logo_v3/` referenced. **Brief logo v3 firmable** `@docs/art/branding/01_brief_logo.md` v3 cross-link. **Cómo leer post-v3.0**: NOTICE v3 → NOTICE r6 (histórico voice/metaphor/iconografía/sound) → §1-§20 inline (motion/typography/storybook/shaders válidos; palette+theme+stack+perf override por v3.0). Header version + estado + ADR origen + reemplaza + FIN line bumped a v3.0-locked. |

---

*"Hear the depth. Understand the patterns."*

**FIN DEL DOCUMENTO `art/01_art_direction.md` v3.0-locked (post-ADR-016 IDENTITY V3 LOCK — palette + dark-only + 3-color strict + trend stack tiered + Tablet UI stack frozen + NUI perf budgets canonical).**
