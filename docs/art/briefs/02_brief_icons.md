# Brief — Iconografía custom SONAR (8 abstract v2)

- **ID:** BRIEF-ICONS-001 v2 (post-ADR-012)
- **Versión:** v2.0 (2026-05-03)
- **Status:** 🟡 Draft firmable — pending founder green-light + designer assignment
- **Owner:** Founder yaboula · Designer TBD (puede ser mismo del logo)
- **Reviewer:** Founder (final sign-off)
- **Source SSoT:** ADR-011 + **ADR-012** + `01_art_direction.md` v2.0-scaffold-r6 NOTICE §Iconografía + BRIEF-LOGO-001 v2 (coherencia stroke con logo)
- **Reemplaza:** BRIEF-ICONS-001 v1 (descartado — 5 de 8 iconos eran literal-militar/radio).
- **Deadline sugerido:** ~2 semanas post-kickoff (3 rondas review).
- **Dependency:** logo monograma **R4 firm** (BRIEF-LOGO-001 v2 cerrado) antes de arrancar — coherencia visual stroke + grid.

---

## 1. Contexto + objetivo

SONAR usa **Lucide React** como familia primaria iconos (stroke 1.5px round, linejoin round, sizes 16/20/24/32px). Lucide cubre ~95% necesidades UI estándar. **Este brief define los 8 iconos custom** que Lucide no cubre — metáfora abstracta profundidad-themed (post-ADR-012, **NO submarino militar literal**).

**Principio (preserved v1→v2):** los 8 iconos custom deben ser **visualmente indistinguibles** de Lucide en contexto. Mismo stroke width, mismo corner radius, mismo nivel de detalle, mismo grid. Lucide-compatible extensions, NO un set distinto.

**Anti-objetivo (preserved):** NO pictogramas elaborados, NO 3D, NO color (monocromo stroke), NO mascots. Son **conceptos abstractos profundidad**, NO instrumentos militares.

---

## 2. Los 8 iconos esenciales (post-ADR-012)

### 2.1 Conservados de v1 scaffold-r5 (3/8)

| # | Nombre | Concepto v2 (refinado abstract) | Uso en producto |
|---|---|---|---|
| 1 | `depth-gauge` | Medidor profundidad **abstract** (dial circular con aguja apuntando descendente) — concept simbólico, NO instrumento militar | Loading progress, depth indicators, altimeter UI |
| 2 | `pressure-hull` | **RECONCEPTUALIZADO post-ADR-012**: NO casco submarino con remaches. Ahora = **3 capas profundidad concéntricas / contención abstract** (estilo geological strata cross-section, NOT metal hull). Concepto: privacy/security/encrypted como "capas de protección" | PIN screens, security settings, encrypted state, privacy |
| 3 | `bioluminescence` | **3-5 puntos luminosos agrupados orgánicamente** — concept simbólico "valor emergiendo de la profundidad" | Notification badges, real-time active indicators, new items |

### 2.2 Nuevos abstract post-ADR-012 (5/8)

| # | Nombre | Concepto | Uso en producto |
|---|---|---|---|
| 4 | `descent-layers` | 3-4 capas horizontales descendiendo con leve offset (sugiere "descender en capas") | Lineage trace, supply chain steps, drill-down navigation |
| 5 | `signal-clarity` | Patrón emergiendo de ruido — varias líneas paralelas con 1-2 destacadas/limpias entre ruido sutil | Audio/comms app (sustituye `hydrophone`), data clarity, filter results |
| 6 | `depth-grid` | Grid isométrico stripped-down — líneas paralelas perspective sugiriendo "profundidad medida" | Background subtle, premium tier surfaces, Tablet wallpaper accent |
| 7 | `observation-field` | Campo observación abstract — círculo con punto central + arcos parciales sugiriendo "área observada" (NO periscopio, NO radar concéntrico) | View, monitor, spectator mode (sustituye `periscope`) |
| 8 | `lineage-trace` | Línea conectando 3-4 nodos (puntos) con curva suave descendente — supply chain trace abstract (NO torpedo bay, NO logistic militar) | Logística futura Oleada 2+, supply chain UI, transaction lineage (sustituye `torpedo-bay`) |

### 2.3 Purgados de v1 (5/8 — NO usar, documenta como anti-patterns)

- ❌ `sonar-ping` (ondas concéntricas radio/frecuencia — purga ADR-012 D1).
- ❌ `submarine` (silueta literal militar).
- ❌ `hydrophone` (mic acústico militar) — sustituido por `signal-clarity`.
- ❌ `periscope` (equipo sub literal) — sustituido por `observation-field`.
- ❌ `torpedo-bay` (armamento militar) — sustituido por `lineage-trace`.

### 2.4 Stretch goals opcionales (2 extras si tiempo permite)

| # | Nombre | Concepto | Uso |
|---|---|---|---|
| 9 | `manifiesto` | Documento con ribbon/seal abstract (NO pergamino vintage) | Contratos, órdenes trabajo, documentos firmados |
| 10 | `bitacora` | Líneas horizontales apiladas (log entries) + indicador timestamp | Logs, journal, history |

---

## 3. Deliverables exactos

### 3.1 Archivos finales (por icono)

| # | Archivo | Formato | Nota |
|---|---|---|---|
| 1 | `{name}.svg` | SVG 24×24 viewBox, paths optimized | Canonical |
| 2 | `{name}_16.svg` | SVG 16×16 viewBox, paths ajustados pixel hinting | Favicon, dense UI |
| 3 | `{name}_20.svg` | SVG 20×20 viewBox | Dense UI |
| 4 | `{name}_32.svg` | SVG 32×32 viewBox | Headers, splash |

**Total SVGs:** 8 iconos × 4 sizes = **32 archivos** (40 si stretch goals).

### 3.2 Package entregables adicionales

| # | Archivo | Formato | Uso |
|---|---|---|---|
| 1 | `sonar_icons_react.tsx` | TypeScript React component library | `import { DepthGauge } from '@sonar/icons'` |
| 2 | `sonar_icons.fig` | Figma component library editable | Designers futuros |
| 3 | `sonar_icons_guidelines.pdf` | PDF 6-10 páginas | Grid + construction + do/don't |
| 4 | `sonar_icons_showcase_dark.png` | 1 imagen showcase grid sobre Abyss Black | Hybrid test dark surface |
| 5 | `sonar_icons_showcase_white.png` | 1 imagen showcase grid sobre Crew 100 | Hybrid test white surface |
| 6 | `package.json` + `README.md` | npm-publishable scaffolding | Futuro open source |

**Repo destino:** `art/icons/sonar_icons_v1/` + React library en `resources/sonar_tablet/nui/src/icons/` (Phase 8 code refactor).

### 3.3 Integración técnica

- **React component API:**
  ```tsx
  <DepthGauge size={24} strokeWidth={1.5} color="currentColor" />
  ```
- **Props Lucide-compatible:** `size`, `strokeWidth`, `color`, `className`.
- **Color default:** `currentColor` — permite usar Sonar Bright vía `.text-sonar-bright`.

---

## 4. Specs técnicos vinculantes

### 4.1 Grid de construcción (inmutable)

- **Canvas:** 24×24 unidades canonical.
- **Padding safe-area:** 2 unidades cada lado → área trabajo 20×20.
- **Grid base:** 1-unidad pixel-perfect @24px.
- **Alignment:** centered. Optical balance OK ±0.5 unidad.

### 4.2 Stroke

- **Stroke width canonical:** **1.5px** (igual Lucide default SONAR).
- **Stroke linecap:** `round`.
- **Stroke linejoin:** `round`.
- **Stroke color:** `currentColor` (NO hardcoded hex).
- **16px variant:** stroke 1.25-1.5px según legibilidad per-icon.
- **32px variant:** stroke mantenido 1.5px (no crecer).

### 4.3 Hybrid theme awareness (NEW v2)

- Iconos deben leerse **paridad** sobre **dos canvases**:
  - Dark: Abyss Black `#03070A` o Depth `#0B1D24` con stroke `currentColor` = Sonar Bright o Crew 100.
  - White: Crew 100 `#F0F4F4` con stroke `currentColor` = Abyss Black o Sonar Bright shifted `#1FB39E`.
- Designer entrega **2 showcase PNGs** (dark + white surfaces) para validación paridad.
- Si un icono no lee bien sobre uno de los dos surfaces, ajustar (típicamente añadir thin counter-shape o adjustar stroke proportional).

### 4.4 Curvas + paths

- **Curvas suaves preferidas** — anti-patterns puntas pixeladas.
- **Round corners implícitos** via `stroke-linejoin: round`.
- **Symmetry cuando concepto lo permite** (depth-gauge, depth-grid, observation-field).
- **Optical correction OK** — designer ajusta si matemático no lee visualmente correcto.
- **Paths optimized:** SVGO. No text embebido. No raster. No groups innecesarios. No IDs arbitrarios.

---

## 5. Specs icon-por-icon (guidance — designer refina)

### 5.1 `depth-gauge` (preserved v1)

- Dial circular (arco 270°, no completo) con aguja central apuntando ~abajo-derecha (hacia "depth").
- Marcas tick cada 45° (4-5 visibles).
- Aguja: línea desde centro hasta ~85% radio.
- NO números dentro (ilegibles a 24px).

### 5.2 `pressure-hull` (RECONCEPTUALIZADO v2)

- **NO casco submarino con remaches.** Ahora: **3 capas concéntricas/horizontales descendentes** sugiriendo "estratos profundidad" o "contención por capas".
- Estilo: geological strata cross-section minimalist.
- 3 líneas paralelas horizontales o 3 arcos concéntricos descendientes (designer evalúa).
- Concepto comunicado: "protected/sealed/contained" via "capas múltiples", NO "metal hull militar".

### 5.3 `bioluminescence` (preserved v1)

- 3-5 dots agrupados orgánicamente (NO grid regular).
- Sizes varied: 1 dot grande, 2 medios, 1-2 pequeños.
- Dots filled circles pequeños (excepción a stroke-only rule — documenta).
- Concepto: "valor emergiendo de la profundidad".

### 5.4 `descent-layers` (NEW v2)

- 3-4 líneas/barras horizontales apiladas con leve offset horizontal (cada capa shift ~1-2 unidades).
- Sugiere "capas descendiendo" o "drill-down".
- Anchas iguales o con leve degradación de width (top más ancha, bottom más estrecha = "perspective implícita").

### 5.5 `signal-clarity` (NEW v2 — sustituye `hydrophone`)

- 4-5 líneas verticales (o horizontales) paralelas, 1-2 destacadas en weight (más gruesas) entre el resto.
- Sugiere "señal clara emergiendo de ruido".
- NO ondas acústicas concéntricas (eso era `hydrophone` deprecated).
- Concepto: "filter results", "signal vs noise".

### 5.6 `depth-grid` (NEW v2)

- Grid isométrico stripped-down: 3-4 líneas paralelas + 2-3 transversales (suficiente para sugerir grid sin saturar).
- Perspective sutil (líneas convergiendo levemente hacia un vanishing point).
- Anchura grid leve (no saturar 24×24).
- Concepto: "profundidad medida", "background structure".

### 5.7 `observation-field` (NEW v2 — sustituye `periscope`)

- Círculo central + punto en el centro + 2-3 arcos parciales rodeando (NO concéntricos completos).
- Sugiere "área observada" sin ser radar/sonar concéntrico ni periscopio literal.
- Optical balance: centrado, simétrico.
- Concepto: "view/monitor/observe".

### 5.8 `lineage-trace` (NEW v2 — sustituye `torpedo-bay`)

- 3-4 puntos (nodos) conectados por línea curva descendente suave.
- Puntos: filled circles pequeños (excepción stroke-only — documenta).
- Curva: bezier suave, sugiere "trace" o "supply chain trail".
- NO armas, NO logistic militar.
- Concepto: "lineage track", "supply chain step", "transaction trace".

---

## 6. Do ✅ / Don't ❌

### 6.1 ✅ Hacer

- Construir TODOS los iconos en misma sesión/día para garantizar consistency.
- Testear cada icono a 16/20/24/32px ANTES de firmarlo.
- **Probar iconos sobre Abyss Black + sobre Crew 100** — deben leer paridad ambos (NEW v2 hybrid awareness).
- Entregar `sonar_icons_showcase_dark.png` + `sonar_icons_showcase_white.png` (NEW v2 — dos showcases).
- Documentar construction grid en guidelines PDF con 2-3 iconos ejemplares.
- Lucide icons abierto side-by-side mientras diseñas (consistency reference).
- SVGO optimizar final outputs.

### 6.2 ❌ No hacer

- ❌ Color en iconos (mono stroke `currentColor`).
- ❌ Gradientes, sombras, blur, filters en SVG.
- ❌ Decoración no-funcional.
- ❌ Stroke widths variables sin razón.
- ❌ Detalles invisibles a 16px.
- ❌ Asimetría arbitraria.
- ❌ Text/labels embedded.
- ❌ Raster embedded.
- ❌ Groups `<g>` innecesarios.
- ❌ IDs arbitrarios (`id="path_12"`).
- ❌ **Conceptos militares submarino: silhouette, periscope, torpedo, hydrophone, hatch, casco con remaches** (purga ADR-012).
- ❌ **Ondas concéntricas radio/sonar ping** (purga ADR-012).

---

## 7. Referencias visuales

### 7.1 Convergir (Lucide-compatible aesthetic)

- **Lucide icons full set** — [lucide.dev](https://lucide.dev). Estudiar stroke, grid, cornering, optical balance.
- **Phosphor icons** (regular weight).
- **Tabler icons** (modern minimalist stroke).

### 7.2 Inspiración profundidad abstracta (estudiar)

- Topographic maps (depth contour lines).
- Geological strata cross-sections.
- Architectural section drawings.
- Layer-based UI (Photoshop layers icon).
- Drill-down navigation visualizations.

### 7.3 Anti-referencias (NO copiar)

- ❌ Material icons — too filled.
- ❌ Font Awesome — too detailed.
- ❌ Emojis.
- ❌ Gaming icon packs (Diablo/WoW).
- ❌ Apple SF Symbols filled — too bold.
- ❌ **Submarine instrumentation packs** (literal militar).
- ❌ **Sonar/radar concentric ping packs**.

---

## 8. Proceso review (gates)

| Ronda | Deliverable | Founder review | Outcome |
|---|---|---|---|
| **R0 — Kickoff** | Moodboard 25 refs Lucide + depth-abstract + anti-refs | Sync 20 min | Green-light direction |
| **R1 — Sketches** | 8 iconos sketches B&W rough a 24px + 16px tests + 2 showcases dark/white | Async 48h | Ajustes concepto + lock direction per icon |
| **R2 — Refinamiento** | 8 iconos SVG clean a 24px + tests 16/20/32 + showcases finales | Async 48h | Ajustes optical balance |
| **R3 — System delivery** | Package completo (32 SVGs + React lib + Figma + guidelines PDF + 2 showcases) | Sync 30 min | Sign-off final |

---

## 9. Licensing + entrega

- **Cesión rights:** idéntica a BRIEF-LOGO-001 v2 §8 — full transfer.
- **Publicación open source futura:** founder puede decidir publicar como npm package MIT/Apache-2 post-launch.
- **Attribution opcional:** credits SONAR website.
- **NDA:** confidential hasta reveal oficial SONAR.

---

## 10. Presupuesto + timeline

- **Scope designer:** mid-senior icon designer, 25-40 horas totales 2 semanas. Mismo del logo preferible.
- **Presupuesto orientativo:** €1,200-€2,800 EUR freelance EU.
- **Alternativa AI:** Opus 4.7 MAX para R1 sketches + designer humano para R2-R3 SVG paths finales (AI SVG generation actualmente weak).

---

## 11. Checklist founder pre-kickoff

- [ ] BRIEF-LOGO-001 v2 R4 firm cerrado.
- [ ] Re-read ADR-012 + art_direction r6 NOTICE §Iconografía.
- [ ] Los 8 nombres locked: 3 conservados (depth-gauge + pressure-hull capas + bioluminescence) + 5 nuevos abstract (descent-layers/signal-clarity/depth-grid/observation-field/lineage-trace).
- [ ] Stretch goals decision (skip o incluir manifiesto + bitacora).
- [ ] Hybrid theme paridad test obligatorio (dark + white showcases).
- [ ] Presupuesto asignado.
- [ ] Designer contratado (mismo del logo preferible).
- [ ] Deadline R3 firm.

---

## 12. Changelog

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| v1.0 | 2026-05-03 | Cascade (Sonnet 4.5) | Initial brief — 8 iconos: sonar-ping/submarine/depth-gauge/hydrophone/bioluminescence/pressure-hull/periscope/torpedo-bay. **Descartado mismo día** post-ADR-012 (5 de 8 literal-militar). |
| v2.0 | 2026-05-03 | Cascade (Sonnet 4.5) | **Rewrite clean post-ADR-012**: 3 conservados (depth-gauge + pressure-hull RECONCEPTUALIZADO capas + bioluminescence) + 5 nuevos abstract (descent-layers/signal-clarity/depth-grid/observation-field/lineage-trace). Hybrid theme awareness obligatorio (showcases dark + white). Anti-patterns explícitos militar/sonar-radio. |

---

**FIN DEL BRIEF — ICONS SONAR v2 (post-ADR-012)**
