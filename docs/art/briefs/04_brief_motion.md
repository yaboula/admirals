# Brief — Motion design SONAR (patterns + signature animations)

- **ID:** BRIEF-MOTION-001 v1 (post-ADR-012)
- **Versión:** v1.0 (2026-05-03)
- **Status:** 🟡 Draft firmable — pending founder green-light + motion designer assignment
- **Owner:** Founder yaboula · Motion designer TBD
- **Reviewer:** Founder (final sign-off)
- **Source SSoT:** ADR-011 + **ADR-012** + `01_art_direction.md` v2.0-scaffold-r6 NOTICE + §16 Motion specs (scaffold-r2 detail-pass)
- **Deadline sugerido:** ~2 semanas post-kickoff (3 rondas review).
- **Dependency:** logo R4 firm + icons R3 firm cerrados (signature animations dependen de assets).

---

## 1. Contexto + filosofía motion SONAR (post-ADR-012)

**Filosofía Pilar S6 art_direction:** *"Motion como agua profunda — silenciosa, deliberada, con masa. Spring physics damping. Cero rebote tipo web JS portfolio."*

Post-ADR-012 refinement: motion sigue spring-physics-with-mass pero **con metáfora abstracta de profundidad** (depth-descent / layer-reveal patterns), NO sonar-ping animation literal radio.

**Lo que SONAR motion ES:**
- ✅ Deliberate, masa, peso visual.
- ✅ Spring physics con damping alto (NO rebote bouncy gen-Z).
- ✅ Patterns repetibles cross-app (consistency).
- ✅ Premium-tech feel (Apple Pro / Linear / Vercel / Notion class).
- ✅ A11y aware (`prefers-reduced-motion` honored siempre).
- ✅ Performance budget strict (NUI <16ms frame, GTA V parent context preserved).

**Lo que SONAR motion NO ES:**
- ❌ NO sonar ping concentric expanding animation (radio/freq literal — purga ADR-012).
- ❌ NO submarine periscope rotate animation (literal militar).
- ❌ NO bouncy spring rebote portfolio JS hipster.
- ❌ NO parallax scroll efectista.
- ❌ NO wipe transitions cinematográficas.
- ❌ NO confetti / particle explosions celebración.
- ❌ NO loading spinners genéricos rotating.
- ❌ NO animation gratuita por moverse — cada motion tiene función.

---

## 2. Deliverables exactos

### 2.1 Motion tokens canonical (12 tokens preserved scaffold-r2)

> Designer entrega **`sonar_motion_tokens.ts`** TypeScript file con tokens duration + easing + spring configs. Lock alignment con scaffold-r2 §16.

| Token | Duration | Easing/Spring | Uso |
|---|---|---|---|
| `motion-instant` | 100ms | `ease-out` | Hover state changes, color shifts |
| `motion-quick` | 150ms | `cubic-bezier(0.4, 0, 0.2, 1)` | Button press feedback, focus ring |
| `motion-snappy` | 200ms | spring `{ damping: 30, stiffness: 350 }` | Tab switch, dropdown open |
| `motion-smooth` | 300ms | spring `{ damping: 28, stiffness: 280 }` | Modal open, drawer slide |
| `motion-deliberate` | 450ms | spring `{ damping: 26, stiffness: 220 }` | Page transition, layer dive |
| `motion-flow` | 600ms | spring `{ damping: 24, stiffness: 180 }` | Splash reveal, hero animation |
| `motion-decision` | 800ms | spring `{ damping: 22, stiffness: 140 }` | Premium reveal, signature confirm |
| `motion-arrival` | 1000ms | spring `{ damping: 20, stiffness: 110 }` | Boot sequence, splash |
| `ease-depth-descent` | varies | `cubic-bezier(0.32, 0.72, 0, 1)` | Drill-down navigation |
| `ease-layer-reveal` | varies | `cubic-bezier(0.16, 1, 0.3, 1)` | Modal/drawer reveal smooth |
| `ease-surface-emerge` | varies | `cubic-bezier(0.22, 1, 0.36, 1)` | Element entry from below |
| `ease-quick-exit` | varies | `cubic-bezier(0.4, 0, 1, 1)` | Element dismiss/close |

### 2.2 Signature animations (5 patterns canónicos NEW v2)

| # | Animation | Reemplaza | Concepto post-ADR-012 |
|---|---|---|---|
| 1 | **`logo_descent_reveal`** | sonar-ping radial expand (deprecated) | Logo monogram emerge desde abajo con leve fade-in capas (descent-layers metaphor). Splash + hero marketing. |
| 2 | **`layer_reveal`** | hatch-open animation (deprecated) | Modal/drawer reveal smooth desde dirección context (top/bottom/side) con backdrop dim hybrid theme aware. |
| 3 | **`depth_drill_down`** | sub diving animation (deprecated) | Navigation drill-down: current view fade-out + next view emerge from below with leve scale-up. |
| 4 | **`signal_emerge_pulse`** | sonar ping concentric (deprecated) | Notification new arrival: dot pulse + leve scale-bounce subtle (NO concentric expanding waves). Sutil — pulse 1-2 ciclos máximo. |
| 5 | **`bioluminescence_breathe`** | submarine running lights (deprecated) | Active state ambient: opacity breathing 0.85↔1.0 con period 2.5-3s, subtle glow shift. Cero animation cuando NOT focused. |

### 2.3 Archivos finales

| # | Archivo | Formato | Uso |
|---|---|---|---|
| 1 | `sonar_motion_tokens.ts` | TypeScript file | Importable cross-app: `import { motionTokens } from '@sonar/motion'` |
| 2 | `sonar_motion_specs.json` | JSON tokens | Tokens Studio Figma sync source |
| 3 | `sonar_motion_framer_examples.tsx` | React + Framer Motion examples | Reference implementation per pattern |
| 4 | `sonar_motion_lottie/{1..5}.json` | Lottie JSON | 5 signature animations standalone |
| 5 | `sonar_motion_videos/{1..5}.mp4` | MP4 1080p60 | Video demos cada animation 4s loop |
| 6 | `sonar_motion_guidelines.pdf` | PDF 8-12 páginas | Specs + a11y + performance budgets + use cases |

**Repo destino:** `art/motion/sonar_motion_v1/` + integración React `resources/sonar_tablet/nui/src/motion/`.

---

## 3. Specs técnicos vinculantes

### 3.1 Performance budgets (NUI inherits scaffold-r4 §19 shaders)

- **NUI animation frame:** <16ms (60fps target sostenido).
- **GTA V parent FPS impact:** ≤2% reduction durante animation playback.
- **CPU GPU profile:** designer entrega Chromium DevTools Performance recording per animation, demuestra zero jank.
- **Animation count concurrent:** máximo 3 animaciones simultáneas en NUI (más → batch o defer).
- **Long-running animations (>2s):** SOLO si user-initiated (boot, splash). Background ambient: low-frequency only (`bioluminescence_breathe` 2.5s period).

### 3.2 Accessibility (`prefers-reduced-motion` strict)

- **TODOS los patterns** deben respect `@media (prefers-reduced-motion: reduce)`:
  - Spring physics → `instant` transition.
  - Long durations (>300ms) → cap at 200ms.
  - Signature ambient (`bioluminescence_breathe`) → disabled.
  - `signal_emerge_pulse` → fade-in only, no scale-bounce.
- **Designer entrega:** screenshot/video showing `prefers-reduced-motion` enabled vs disabled per animation.

### 3.3 Hybrid theme awareness (NEW v2)

- Animations deben funcionar **paridad sobre dark + white surfaces**.
- Backdrops dim para modals: `rgba(3, 7, 10, 0.6)` sobre dark canvas, `rgba(11, 29, 36, 0.4)` sobre white surfaces.
- Glow effects (`signal_emerge_pulse`) tinted Sonar Bright `#2DD4BF` con opacity ajustada per surface (más visible sobre dark, más sutil sobre white).
- Designer entrega **video demos en ambos surfaces** (dark + white) per signature animation.

### 3.4 Spring physics integration (Framer Motion + framer-motion-3d)

- **Default library:** Framer Motion (React-friendly, performant, well-maintained 2026).
- **Alternativa CSS @starting-style + transition-behavior** para patterns simple (Chrome 117+).
- **NO usar:** GSAP (overkill + license), animejs (legacy), CSS keyframes para spring (limited).

---

## 4. Animation specs detalladas

### 4.1 `logo_descent_reveal` (signature most-important)

**Trigger:** Tablet boot sequence + Marketing hero reveal + Splash screen.

**Spec:**
- Duración total: **1200ms** (boot exception — solo allowed >800ms).
- 4 fases:
  1. **0-300ms:** logo monogram fade-in opacity 0→0.3 from bottom (translateY +12px → 0).
  2. **300-700ms:** monogram fully visible, leve scale 0.95→1.0 spring deliberate.
  3. **700-1000ms:** wordmark "SONAR" emerge sliding from left with stagger 50ms per letter.
  4. **1000-1200ms:** tagline "Hear the depth." fade-in con 200ms delay.
- Easing: `ease-depth-descent` cubic-bezier(0.32, 0.72, 0, 1).
- Sound trigger: `signal_emerge` synchronized at 700ms (wordmark reveal moment).

**Anti-pattern:** ❌ NO concentric waves expanding desde monogram. NO sonar-ping radial.

### 4.2 `layer_reveal` (modal/drawer)

**Trigger:** Modal `panel_open` + Drawer slide-in + Notification panel reveal.

**Spec:**
- Duración: **300ms** (`motion-smooth`).
- Backdrop: opacity 0→0.6 cubic-bezier(0.4, 0, 0.2, 1) 300ms.
- Panel: slide-in from context direction (top/bottom/side) + scale 0.96→1.0 spring `{ damping: 28, stiffness: 280 }`.
- Glassmorphism backdrop-filter activated AFTER panel reaches 90% position (avoid janky filter recompute mid-animation).
- Sound trigger: `panel_open` synchronized at 0ms.

### 4.3 `depth_drill_down` (navigation)

**Trigger:** Drill-down navigation (Bridge → squadron details → empleado record).

**Spec:**
- Duración: **450ms** (`motion-deliberate`).
- Current view: fade-out opacity 1→0 + scale 1.0→0.96 + translateY 0→-8px.
- Next view: fade-in opacity 0→1 + scale 1.04→1.0 + translateY +12px→0 con 100ms delay.
- Easing: `ease-depth-descent` ambos.
- Sound trigger: `layer_dive` synchronized at 0ms.
- **Anti-pattern:** ❌ NO horizontal slide (eso es para tab switch). ❌ NO 3D flip rotation.

### 4.4 `signal_emerge_pulse` (notification)

**Trigger:** New notification arrival, real-time signal alert.

**Spec:**
- Duración: **800ms** total.
- Notification dot:
  1. **0-200ms:** scale 0→1.2 spring quick + opacity 0→1.
  2. **200-400ms:** scale 1.2→1.0 settle + glow Sonar Bright box-shadow 0px→8px → 4px.
  3. **400-800ms:** opacity 1→0.85 breathing + glow stable.
- After 800ms: enters `bioluminescence_breathe` ambient pattern.
- Sound trigger: `signal_emerge` synchronized at 0ms.
- **Anti-pattern:** ❌ NO concentric expanding waves (sonar-ping deprecated). ❌ NO 3+ pulse loops (1-2 max).

### 4.5 `bioluminescence_breathe` (ambient active)

**Trigger:** Active state indicator, real-time live data, focused element.

**Spec:**
- Duración loop: **2500-3000ms** (low frequency).
- Opacity: 0.85↔1.0 ease-in-out.
- Glow box-shadow: 4px↔8px Sonar Bright.
- Loop: infinite mientras element focused/active.
- **`prefers-reduced-motion`:** opacity static 1.0, no animation.
- **Anti-pattern:** ❌ NO scale change (solo opacity + glow). ❌ NO color shift. ❌ NO RGB rainbow.

---

## 5. Do ✅ / Don't ❌

### 5.1 ✅ Hacer

- Usar Framer Motion como default library (React-friendly, performant 2026).
- Spring physics damping alto (24-30) para weight + decisive feel.
- Test cada animation en **dark + white surfaces** (NEW v2 hybrid theme awareness).
- Test `prefers-reduced-motion` per pattern + entregar screenshots ambos states.
- Profile DevTools Performance per animation: zero jank confirmed.
- Sync animations con sound triggers (BRIEF-SOUND-001 per-SFX timing).
- Documentar use cases per pattern en guidelines PDF.
- Entregar Lottie JSON standalone para cada signature animation (5 files).

### 5.2 ❌ No hacer

- ❌ **Sonar ping concentric expanding** (deprecated — purga ADR-012).
- ❌ **Submarine animation literal** (periscope rotate, sub diving).
- ❌ Bouncy springs damping <20 (gen-Z portfolio feel).
- ❌ Parallax scroll efectista.
- ❌ Wipe transitions cinematográficas.
- ❌ Confetti / particle explosions celebración.
- ❌ Loading spinners rotating genéricos.
- ❌ 3D flip rotation transitions.
- ❌ Animation gratuita sin función.
- ❌ Long-running animations (>2s) en background sin user-trigger.
- ❌ Animations que ignoran `prefers-reduced-motion`.

---

## 6. Referencias visuales motion (estudiar obsesivamente)

### 6.1 Convergir (premium-tech motion class)

- **Apple Pro apps:** Final Cut export panel reveal, Logic Pro mixer scroll, iCloud transition between accounts.
- **Linear:** project switcher, command palette open, task drag-drop snap.
- **Vercel Dashboard:** deploy success celebration (subtle, not confetti), project switch.
- **Stripe Dashboard:** charts animate-in on load, drawer open, payment success state.
- **Notion:** page navigation transition, drag-drop snap, command menu reveal.
- **Arc Browser:** space switcher, command bar open, profile change.

### 6.2 Inspiración profundidad abstracta motion

- Topographic depth maps animate (capas reveal sequentially).
- Geological strata layered reveals.
- Parallax layered minimalist (NOT efectista).
- Material Design "container transform" pattern (M3 — convergent class).
- Apple "fluid morph" between hierarchy levels.

### 6.3 Anti-referencias

- ❌ Hunt: Showdown / military shooter UI motion.
- ❌ Cyberpunk 2077 holographic glitch transitions.
- ❌ Gaming RGB animations.
- ❌ JS portfolio bouncy springs (Awwwards 2018-2022 era).
- ❌ Webflow templates parallax efectista.
- ❌ **Submarino documental** sub diving / periscope literal.
- ❌ **Sonar ping radio** concentric expanding.

**Bibliography moodboard:** designer entrega `sonar_motion_bibliography.md` con specific timestamps + URLs per ref convergente.

---

## 7. Proceso review (gates)

| Ronda | Deliverable | Founder review | Outcome |
|---|---|---|---|
| **R0 — Kickoff** | Bibliography moodboard + tools confirmation (Framer Motion lock) | Sync 30 min | Green-light dirección |
| **R1 — Tokens + Sketches** | `sonar_motion_tokens.ts` draft + 5 signature animations rough Figma/Principle/After Effects + 5 preview MP4 | Async 48h | Ajustes per-animation + lock direction |
| **R2 — Refinamiento** | 5 animations refined + Framer Motion examples React + Lottie exports + a11y screenshots + performance profile | Async 48h | Ajustes finos + sign-off carácter |
| **R3 — Delivery** | Package completo (tokens TS + JSON + framer examples + 5 Lottie + 5 MP4 demos dark+white + guidelines PDF) | Sync 30 min | Sign-off final |

---

## 8. Licensing + entrega

- **Cesión rights:** full transfer of all IP rights + copyrights to yaboula / SONAR. Unlimited perpetual worldwide commercial use.
- **Code samples:** Framer Motion examples MIT-permissive embeddable en SONAR codebase.
- **Lottie JSON:** raw outputs sin watermark / branding terceros.
- **NDA:** Motion confidential hasta reveal oficial SONAR.
- **Source files:** Figma/Principle/After Effects source preserved entregable.

---

## 9. Presupuesto + timeline

- **Scope motion designer:** mid-senior UI motion designer specialized premium-tech, 30-45 horas totales 2 semanas.
- **Presupuesto orientativo:** €1,400-€3,200 EUR freelance EU.
- **Specialty:** preferencia portfolio premium-tech apps motion (NO film-only, NO ads-only background).
- **Alternativa AI:** Runway / Pika para sketches inspiracionales R0; humano OBLIGATORIO para tokens TS + Framer Motion code + a11y validation.

---

## 10. Checklist founder pre-kickoff

- [ ] BRIEF-LOGO-001 v2 R4 firm + BRIEF-ICONS-001 v2 R3 firm cerrados.
- [ ] Re-read ADR-012 + art_direction r6 NOTICE + scaffold-r2 §16 motion specs.
- [ ] 12 motion tokens preserved.
- [ ] 5 signature animations canónicos locked: `logo_descent_reveal`, `layer_reveal`, `depth_drill_down`, `signal_emerge_pulse`, `bioluminescence_breathe`.
- [ ] Anti-patterns ADR-012 enforced (NO sonar-ping concentric, NO submarino literal).
- [ ] Hybrid theme dark+white paridad obligatorio.
- [ ] `prefers-reduced-motion` validation obligatorio.
- [ ] Performance budgets enforced (NUI <16ms, GTA V ≤2% impact).
- [ ] Presupuesto asignado.
- [ ] Motion designer contratado portfolio premium-tech.
- [ ] Deadline R3 firm.

---

## 11. Changelog

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| v1.0 | 2026-05-03 | Cascade (Sonnet 4.5) | Initial brief — 12 motion tokens preserved scaffold-r2 + 5 signature animations canonical post-ADR-012: `logo_descent_reveal`/`layer_reveal`/`depth_drill_down`/`signal_emerge_pulse`/`bioluminescence_breathe`. NO sonar-ping concentric, NO submarino literal. Refs Apple/Linear/Vercel/Stripe/Notion/Arc premium-tech. Hybrid theme + a11y + performance enforced. |

---

**FIN DEL BRIEF — MOTION SONAR v1 (post-ADR-012)**
