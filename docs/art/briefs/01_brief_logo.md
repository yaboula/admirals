# Brief — Logo SONAR (design package v2)

- **ID:** BRIEF-LOGO-001 v2 (post-ADR-012)
- **Versión:** v2.0 (2026-05-03)
- **Status:** 🟡 Draft firmable — pending founder green-light + designer assignment
- **Owner:** Founder yaboula · Designer TBD
- **Reviewer:** Founder (final sign-off)
- **Source SSoT:** ADR-011 + **ADR-012** + `docs/art/01_art_direction.md` v2.0-scaffold-r6 NOTICE + `docs/design/00_PRODUCT_BIBLE.md` v1.4 §1
- **Reemplaza:** BRIEF-LOGO-001 v1 (descartado — concepto "S-como-onda sonar concéntrica" era radio/freq literal, contradice ADR-012 D1).
- **Deadline sugerido:** ~2 semanas post-kickoff (4 rondas review).
- **Precedencia:** este brief es SSoT operacional. Si conflicto con `01_art_direction.md` r6 NOTICE → gana NOTICE + ADR-012.

---

## 1. Contexto proyecto (para designer que no conoce SONAR)

**SONAR** es un servidor **FiveM premium** (GTA V roleplay). Nombre = acrónimo *SOund Navigation And Ranging* — instrumento que **simbólicamente** "ve escuchando". No es servidor RP típico: es infraestructura económica profunda con cadenas de producción, Tablet empresarial transversal y diseño obsesivo detail-first.

**Metáfora visual/narrativa (canonical post-ADR-012):** **profundidad simbólica + exploración paciente**. Valor oculto bajo capas. Calma metódica al descender. Patterns que emergen al observar con atención. Claridad bajo presión.

**Lo que SONAR NO ES (purga explícita per ADR-012):**
- ❌ NO submarino militar literal (silhouettes/perfiles).
- ❌ NO hardware señal acústica (hydrophones, sonar pings radio/frecuencia, waveforms, oscilloscope).
- ❌ NO armamento submarino (torpedos, depth charges, missile bays).
- ❌ NO equipo de cubierta literal (periscopios, bridge command center militar, hatches, casco con remaches).
- ❌ NO referencias militares en general.

**Referencias estéticas convergentes (estudiar obsesivamente):**
- **Apple Pro apps** (Final Cut, Logic Pro) — premium minimalism + tech precision.
- **Linear** — geometric purity + confident silence.
- **Vercel** — modern geometric + tech confidence + dark+light hybrid.
- **Stripe Dashboard** — enterprise-grade professionalism + hybrid dark+light.
- **Arc Browser** — modern distinctive + hybrid theme balanced.
- **Notion** — content-first + hybrid surfaces.

**Voz de marca (canonical post-ADR-012):** **neutral premium-tech**. Estilo Vercel/Linear/Stripe copy. Preciso, terse, calmo, professional, atemporal. Cero arquetipo (no "silent service", no "capitán", no "a bordo", no "tactical"). Cero gen-Z/exclamaciones/vibes/emojis-en-producto.

**Qué debe transmitir el logo:**
1. **Profundidad simbólica** — sugerir capas/dimensión/algo "más allá de la superficie" sin literal.
2. **Precisión técnica** — geometric purity, proportional rigor.
3. **Calma autoridad** — confidence sin gritar.
4. **Atemporal** — debe sobrevivir 5+ años sin refresh. Nada de trends 2026.
5. **Bioluminescent identity** — el color Sonar Bright `#2DD4BF` es la firma marketing en mercado FiveM.

**Qué NUNCA debe transmitir:**
- ❌ Submarino, periscopio, casco, torpedo, hydrophone, sonar ping radio.
- ❌ Anime/manga, militar/warfare, cyberpunk neón.
- ❌ Cartoon gaming, mascot, RGB rainbow, gradient holográfico.
- ❌ Vintage/retro, motivational corporate.
- ❌ Tactical operator masculino agresivo (CoD UI style).

---

## 2. Deliverables exactos

### 2.1 Archivos finales (formato entrega)

| # | Archivo | Formato | Uso destino |
|---|---|---|---|
| 1 | `sonar_logo_full.svg` | SVG vector (paths only, no raster) | Web hero, Tebex page, trailer |
| 2 | `sonar_logo_monogram.svg` | SVG vector | Favicon, app icon Tablet, watermark |
| 3 | `sonar_wordmark.svg` | SVG vector | Footer, créditos |
| 4 | `sonar_logo_lockup_horizontal.svg` | SVG vector | Banners horizontales, signatures |
| 5 | `sonar_logo_lockup_vertical.svg` | SVG vector | Avatar cuadrado, packaging vertical |
| 6 | `sonar_logo_dark_canvas.svg` | SVG vector | Sonar Bright sobre Abyss Black `#03070A` (canonical primary) |
| 7 | `sonar_logo_white_canvas.svg` | SVG vector | Sonar Bright sobre Crew 100 `#F0F4F4` (hybrid theme white surfaces) |
| 8 | `sonar_logo_reverse.svg` | SVG vector | Abyss Black sobre Crew 100 (B&W print contexts) |
| 9 | Raster exports PNG @1x/@2x/@3x en 64/128/256/512/1024px + 16/32 favicons | PNG con alpha | Multi-density |
| 10 | `sonar_logo_guidelines.pdf` | PDF 10-14 páginas | Normativa do/don't + specs + misuse + hybrid theme application |
| 11 | `sonar_logo_source.fig` | Figma community file | Editable source + variantes + color tokens |
| 12 | `sonar_logo_splash_hero.mp4` o `.webm` | Vídeo 4s loop 1080p60 | Marketing hero + Tablet splash (stretch goal) |

**Repo destino:** `art/branding/logo_v1/` + `docs/art/branding/` (normativa).

### 2.2 Estados requeridos del logo (hybrid theme aware — ADR-012 D2)

> **Importante v2:** SONAR usa **hybrid theme** (~30-40% dark + ~30-40% white surfaces). El logo debe funcionar primario en **ambos canvases con paridad visual**.

- **Canonical Primary A — Sonar Bright sobre Abyss Black** `#2DD4BF` sobre `#03070A`. Contraste AAA 9.8:1 ✅. Uso: dark surfaces (sidebar, hero dark mode, splash).
- **Canonical Primary B — Sonar Bright sobre Crew 100 off-white** `#2DD4BF` sobre `#F0F4F4`. Contraste 2.7:1. **Designer debe verificar y posiblemente añadir thin abyss-black border 1px o slight darkening del teal a `#1FB39E` para AA compliance** sobre white surfaces. Uso: white panels, content areas, light hero, docs pages.
- **Reverse contrast-forced** — Abyss Black `#03070A` sobre Crew 100 `#F0F4F4` (o viceversa) — SOLO para print docs formales B&W obligatorios.
- **Monochrome Crew** — Crew 100 `#F0F4F4` solid (uso raro — overlay sobre video dark).
- **Monochrome Abyss** — Abyss Black `#03070A` solid (uso raro — print 1-tinta).
- ❌ **Coloro Support `#175A5F` PROHIBIDO en logo** — Coloro es Tier C estructural, NO identity. Documenta explícitamente como misuse.

### 2.3 Variantes glow (marketing only, preserved)

- **Glow signature OPCIONAL** para hero marketing / reveal trailer:
  - Radial Sonar Bright `#2DD4BF` 12% opacity behind logo, radius ~1.5× logo width, soft falloff.
  - Test del 50%: si reduces glow 50% y jerarquía visual sigue clara → OK.
- ❌ NO glow en favicon, UI in-app, packaging físico.

---

## 3. Concepto base — DESIGN SPACE EXPLORATION (NOT locked)

> **Crítico v2:** founder NO especifica concepto base único. Designer **debe explorar 4-5 direcciones distintas** en R1, todas alineadas con metáfora abstracta de profundidad. **CERO ondas concéntricas** (radio/frecuencia literal — purga ADR-012).

### 3.1 Candidatos preliminares (no-exhaustivos — designer puede proponer alternativas)

| # | Concepto | Idea formal |
|---|---|---|
| **C1** | **Descent-layers** | Letra "S" formada por 3-4 capas horizontales descendiendo, cada capa con leve offset. Sugiere "descender en capas". |
| **C2** | **Prisma profundidad** | "S" estructurada como prisma geométrico con profundidad isométrica leve (3D minimalist), sugiriendo dimensión oculta. |
| **C3** | **Gradient depth** | "S" sólida con gradient muy sutil de Sonar Bright a Sonar Pulse (top→bottom), sugiriendo "descenso de luz". Riesgo: debe pasar test favicon 16px sin perder identidad. |
| **C4** | **Geometric depth-grid** | "S" construida como grid isométrico stripped-down — líneas paralelas perspective sugiriendo "profundidad medida". |
| **C5** | **Geometric S-descent** | "S" con curvas tradicionales pero las 2 curvas claramente diferenciadas en weight/style sugiriendo "superficie + profundidad". Más simple y atemporal. |

**Designer puede:**
- Combinar elementos (ej. C1 descent + C5 weight differentiation).
- Proponer C6+ alternativas siempre que respeten anti-patterns ADR-012.
- Descartar candidatos preliminares completamente si trae propuesta más fuerte.

### 3.2 Anti-patterns concepto (PROHIBIDOS — ADR-012 D1)

- ❌ Ondas concéntricas (sonar ping radio/frecuencia).
- ❌ Submarino silhouette literal.
- ❌ Periscopio, hydrophone, torpedo, depth charge, hatch.
- ❌ Anchor/wheel marítimo (Admirals heritage deprecated).
- ❌ Acoustic waveform/oscilloscope.
- ❌ Compass/navigation symbols literales.
- ❌ "Eye that sees" eye-with-rays (literal "ver escuchando").

---

## 4. Specs técnicos vinculantes

### 4.1 Color tokens

| Token | Hex | Uso logo |
|---|---|---|
| `--sonar-bright` | `#2DD4BF` | **PRIMARY IDENTITY** del logo siempre |
| `--sonar-bright-shifted` | `#1FB39E` | Variant para white canvases si AA contrast falla |
| `--sonar-pulse` | `#14E5DD` | ONLY si C3 gradient depth concept elegido (top of gradient) |
| `--abyss-black` | `#03070A` | Canvas primario detrás del logo (dark surfaces) |
| `--crew-100` | `#F0F4F4` | Canvas hybrid white surfaces |
| `--coloro-support` | `#175A5F` | ❌ **PROHIBIDO en logo** |

Contraste mínimo logo-sobre-canvas: **AAA ≥7:1 dark canvas, AA ≥4.5:1 white canvas**.

### 4.2 Tipografía wordmark

- **Familia:** Geist Sans (Vercel — free, variable font, OFL 1.1 SIL).
- **Peso base wordmark:** SemiBold 600 o Bold 700 según proporción final.
- **Tracking wordmark SONAR:** tight (-2% a -4%) para compactness técnica.
- **Caja:** all-caps "SONAR". Nunca lowercase. Nunca mixed case.
- **Fallback:** Inter Tight Bold (si Geist no embeddable en medio físico).

### 4.3 Geometría + construction

- **Grid:** designer entrega construction diagram en grid 12×12 o 16×16 modular.
- **Stroke linecap/linejoin:** round (coherente con iconografía Lucide round usada en SONAR).
- **Espacio libre alrededor del logo:** mínimo = ancho de la "S" del monograma. Documentar visualmente.
- **Tamaño mínimo pantalla:** 24px alto. Por debajo, usar solo monogram (favicon 16px).
- **Tamaño mínimo print:** 8mm alto.

### 4.4 Lockups

| Lockup | Composición | Espaciado |
|---|---|---|
| **Horizontal** | Monograma · gap · wordmark "SONAR" | Gap = 0.5× altura monograma |
| **Vertical** | Monograma encima · gap · wordmark "SONAR" | Gap = 0.3× altura monograma |
| **Tagline (opcional)** | Lockup + línea debajo wordmark: *"Hear the depth."* en Inter Tight Medium 14px tracking +4% | Solo hero marketing |

---

## 5. Do ✅ / Don't ❌

### 5.1 ✅ Hacer

- Explorar 4-5 conceptos divergentes en R1 (no quedarse en variantes minor de uno).
- Mantener simplicidad geométrica: el logo debe leerse a 16px favicon sin perder identidad.
- Validar AAA dark canvas + AA white canvas ANTES de presentar.
- Probar el logo en 4 contextos: favicon Chrome tab, app-icon Tablet, Tebex store hero 1920px, **white panel surface** (hybrid theme test).
- Documentar grid + clear-space + misuse en PDF guidelines (10-14 páginas).
- Entregar SVG con paths optimizados (SVGO), nunca embedded raster, nunca text not-outlined.

### 5.2 ❌ No hacer (misuse documentar en PDF)

- ❌ Stretch horizontal/vertical.
- ❌ Rotar el logo (ni 2º).
- ❌ Drop-shadow gaming.
- ❌ Outline stroke alrededor del logo.
- ❌ Gradient rainbow / holográfico / mercurio.
- ❌ Versiones rojas/amarillas/verdes/moradas.
- ❌ Logo sobre fondo fotográfico caótico sin backplate.
- ❌ Logo con bevel/emboss.
- ❌ Wordmark en script/cursiva/serif.
- ❌ **Concepto ondas concéntricas** (radio/freq — explicit purga ADR-012).
- ❌ **Concepto submarino silhouette** (literal militar — explicit purga ADR-012).

---

## 6. Referencias visuales

### 6.1 Convergir (estudiar obsesivamente)

- Linear logomark — minimalist geometric purista.
- Stripe logomark — simplicity + geometric precision.
- Vercel logomark — triangular minimal + tech confidence + dark+light parity.
- Apple logo — timeless silhouette recognizable 16px.
- Arc browser — modern geometric + distinctive.
- Notion logomark — content-first simplicity.

### 6.2 Inspiración profundidad abstracta (NO copiar)

- Geological strata cross-sections (capas tierra).
- Topographic depth maps (curvas nivel).
- Architectural section drawings (descenso edificios).
- Scientific diagrams "depth profile" (oceanografía, batimetría).
- Layer-based UI patterns (Photoshop layers icon).

### 6.3 Anti-referencias (hacer lo OPUESTO)

- ❌ Logos cyberpunk neón (Cyberpunk 2077).
- ❌ Logos military tacticool (CoD, Rainbow Six).
- ❌ Logos gaming RGB (Razer, MSI, Alienware).
- ❌ Logos mascot/cartoon (Twitch chibi, server RP meme).
- ❌ Logos nautical/military submarines literal.
- ❌ Logos sonar/radar instrument literal (waveforms, scopes, ping concentric).

**Moodboard assembly:** designer compila PDF 1-pager con 25-30 refs clasificadas en 4 columnas: `✅ Formal · ✅ Profundidad abstracta · ✅ Hybrid theme · ❌ Anti`. Enviado en kickoff.

---

## 7. Proceso review (gates)

| Ronda | Deliverable | Founder review | Outcome |
|---|---|---|---|
| **R0 — Kickoff** | Moodboard PDF + cuestionario dudas | Sync 30 min | Green-light dirección |
| **R1 — Conceptos** | 4-5 direcciones monograma thumbnails B&W (incluyendo ≥3 candidatos preliminares §3.1) | Async 48h | Elige 2 para R2 |
| **R2 — Refinamiento** | 2 direcciones refined + aplicadas en favicon/app-icon/hero dark/hero white (hybrid test) | Async 48h | Elige 1 final + lockups |
| **R3 — Sistema completo** | Logo final + lockups + reverse + glow + variants dark/white canvas + guidelines PDF draft | Sync 45 min | Ajustes menores + sign-off |
| **R4 — Delivery** | Package completo repo-ready + source files + guidelines PDF final | Founder firma | ✅ Locked |

**Cada ronda incluye:** rationale escrito del designer (1 página max), NO solo imágenes.

---

## 8. Licensing + entrega legal

- **Cesión rights:** full transfer of all IP rights + copyrights to yaboula / SONAR. Unlimited perpetual worldwide commercial use.
- **Source files:** Figma community file editable + SVG sources + fonts licenses (Geist = SIL OFL 1.1).
- **NDA:** Logo confidential hasta reveal oficial SONAR.
- **Attribution:** designer accreditable en credits SONAR website + trailer (opcional).
- **Fonts embedding:** Geist preferencia fuerte (free commercial OK).

---

## 9. Presupuesto + timeline

- **Scope designer:** senior brand designer, 30-50 horas totales 2 semanas.
- **Presupuesto orientativo:** €1,500-€3,500 EUR freelance EU. 2-3 quotes antes contratar.
- **Alternativa AI:** Opus 4.7 MAX + Midjourney/Ideogram para R1-R2 generation, humano para R3+ construction diagram + guidelines PDF.

---

## 10. Checklist founder pre-kickoff

- [ ] Re-read ADR-011 + ADR-012 + art_direction r6 NOTICE.
- [ ] Concepto base **NO locked** — designer explora 4-5 direcciones en R1.
- [ ] Paleta Tier A/B/C inmutable (Sonar Bright = identity, Coloro = prohibido logo, hybrid theme dark+white parity).
- [ ] Geist Sans wordmark inmutable.
- [ ] Presupuesto asignado.
- [ ] Deadline R4 firm.
- [ ] Si designer AI: founder ejecuta R1-R2 personal con este brief como prompt maestro.

---

## 11. Changelog

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| v1.0 | 2026-05-03 | Cascade (Sonnet 4.5) | Initial brief — concepto "S-onda concéntrica" locked. **Descartado mismo día** post-ADR-012 (radio/freq literal). |
| v2.0 | 2026-05-03 | Cascade (Sonnet 4.5) | **Rewrite clean post-ADR-012**: concepto NO-locked (5 candidatos preliminares + design space exploration), hybrid theme dark+white parity tests, anti-patterns explícitos ondas concéntricas + submarino literal, refs convergentes Apple/Linear/Vercel/Stripe/Arc/Notion + profundidad abstracta (NO submarinos), 4 review gates R0-R4. |

---

**FIN DEL BRIEF — LOGO SONAR v2 (post-ADR-012)**
