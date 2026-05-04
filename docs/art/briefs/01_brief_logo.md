# Brief — Logo SONAR (identity v3 firmado)

- **ID:** BRIEF-LOGO-001 v3 (post-ADR-016)
- **Versión:** v3.0 (2026-05-04)
- **Status:** � **FIRMADO / LOCKED** — logo v3 entregado en `@art/branding/logo_v3/` (4 monogramas SVG + wordmark + 2 lockups + preview.html + exports pipeline)
- **Owner:** Founder yaboula
- **Reviewer:** Founder (sign-off ejecutado 2026-05-04 S1.10 EXTENDED post-commit)
- **Source SSoT:** ADR-011 + ADR-012 + **ADR-016** (`@docs/planning/02_decision_log_part2.md` v1.0 D1+D2+D3) + `@docs/art/01_art_direction.md` (post v3.0 bump)
- **Reemplaza:** BRIEF-LOGO-001 v2 (descartado — paleta teal Sonar Bright + hybrid theme dark+white obsoleta post-ADR-016 D1+D2).
- **Precedencia:** este brief es **SSoT operacional canónico** para palette tokens (D1) + dark-only doctrine product (D2) + 3-color strict (D3). Si conflicto con `01_art_direction.md` → gana ADR-016.

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

**Qué debe transmitir el logo (firmado v3):**
1. **Profundidad simbólica** — sugerir capas/dimensión/algo "más allá de la superficie" sin literal.
2. **Precisión técnica** — geometric purity, proportional rigor.
3. **Calma autoridad** — confidence sin gritar.
4. **Atemporal** — debe sobrevivir 5+ años sin refresh.
5. **Signal identity** — Orange `#FF5100` es la firma marketing 2026+ (post ADR-016 D1, replaces Sonar Bright teal v2).
6. **Dark-only product** — logo product UI siempre sobre Black `#060607` canvas (post ADR-016 D2).

**Qué NUNCA debe transmitir:**
- ❌ Submarino, periscopio, casco, torpedo, hydrophone, sonar ping radio.
- ❌ Anime/manga, militar/warfare, cyberpunk neón.
- ❌ Cartoon gaming, mascot, RGB rainbow, gradient holográfico.
- ❌ Vintage/retro, motivational corporate.
- ❌ Tactical operator masculino agresivo (CoD UI style).
- ❌ **Light variant del logo en product UI** (post ADR-016 D2 — excepción única `monogram_s_black.svg` print/external, NO product).

---

## 2. Deliverables firmados (inventario real `@art/branding/logo_v3/`)

### 2.1 Archivos finales entregados

> **Status:** ✅ Todos los SVG sources firmables. Pipeline export automatizado vía `@art/tools/logo_export/export.mjs` (Puppeteer SVG→PNG multi-density).

| # | Archivo SVG (sources) | Variante | Uso destino canónico |
|---|---|---|---|
| 1 | `monogram_s.svg` | Solid Orange `#FF5100` sobre transparente | Favicon, app icon Tablet (D2 dark canvas baseline), watermark product UI |
| 2 | `monogram_s_solid.svg` | Solid Orange filled stroke variant | Marketing hero, social avatars |
| 3 | `monogram_s_white.svg` | Pure white `#FAFAFA` | Overlay sobre fondos foto/video dark uniformes |
| 4 | `monogram_s_light.svg` | White light variant para hover/active states | Tablet UI interactivos focus rings |
| 5 | `monogram_s_black.svg` | Black `#060607` solid | **EXCEPCIÓN ÚNICA print/external** (papelería, fondos blancos third-party donde dark monogram es ilegible). **NO uso product UI** (per ADR-016 D2 + D-S1.10E-A) |
| 6 | `wordmark_sonar.svg` | Wordmark "SONAR" Geist Sans Orange | Footer, créditos, signatures, banners horizontales |
| 7 | `lockup_horizontal.svg` | Monograma + gap + wordmark horizontal | Hero banners, web headers, signatures email |
| 8 | `lockup_vertical.svg` | Monograma encima + wordmark debajo | Avatar cuadrado, packaging vertical, social profile |
| 9 | `preview.html` | Preview interactiva all variants | QA visual + handoff |
| 10 | `exports/` (folder) | PNG @1x/@2x/@3x multi-density (16/32/64/128/256/512/1024) | Multi-density product + marketing |
| 11 | `README.md` | Inventario + uso + ADR refs | Onboarding nuevos contributors |

**Repo source canónico:** `@art/branding/logo_v3/`. **Pipeline export:** `@art/tools/logo_export/export.mjs` (Node.js + Puppeteer headless rendering).

### 2.2 Estados canónicos del logo (post ADR-016 D2 dark-only)

> **Cambio v2 → v3:** SONAR product UI es **dark-only** post ADR-016 D2. El logo NO necesita "hybrid theme parity" porque NO existe light variant del producto. Excepción única: `monogram_s_black.svg` para contextos print/external NON-product.

- **Canonical Primary — Orange sobre Black** `#FF5100` sobre `#060607`. Contraste AAA ~6.5:1 ✅ (Orange large text + non-text graphic). Uso: TODA UI product (Tablet NUI, marketing web dark, splash, hero).
- **White variant — White sobre Black** `#FAFAFA` sobre `#060607`. Contraste AAA 19.5:1 ✅. Uso: contextos donde Orange compite con otros signals (e.g., critical alerts overlay).
- **Light hover variant** — `monogram_s_light.svg` (white tonal shift). Uso: focus rings + hover states Tablet UI per D5 stack.
- **Print/external EXCEPCIÓN ÚNICA** — `monogram_s_black.svg` Black sobre fondos blancos third-party (papelería formal, presentaciones partners, impresión). **PROHIBIDO product UI**.
- ❌ **Light canvas product UI PROHIBIDO** post ADR-016 D2 — NO existe light variant Tablet/marketing-web.
- ❌ **Colores no-canónicos PROHIBIDOS** — solo Black/Orange/White (post ADR-016 D3 3-color strict). NO teal, NO Coloro support, NO accent colors.

### 2.3 Variantes glow (marketing hero only, preserved)

- **Glow signature OPCIONAL** para hero marketing / reveal trailer:
  - Radial Orange `#FF5100` 12% opacity behind logo, radius ~1.5× logo width, soft falloff.
  - Test del 50%: si reduces glow 50% y jerarquía visual sigue clara → OK.
- ❌ NO glow en favicon, UI in-app product, packaging físico.

---

## 3. Concepto base — FIRMADO LOCKED v3

> **Status:** ✅ Concepto cerrado. Logo v3 entregado en `@art/branding/logo_v3/`. Esta sección documenta el concepto firmado; NO es exploration brief.

### 3.1 Concepto firmado

**Monograma "S" geométrico minimalista** + wordmark "SONAR" Geist Sans Orange.

- **Construcción:** "S" formada por curvas geométricas precisas (proportional rigor + depth simbólica abstracta — NO ondas, NO sub-militar).
- **Variantes:** 4 monogramas firmables (`monogram_s.svg` solid + `_solid` filled stroke + `_white` pure + `_light` hover variant) + 1 excepción print/external (`_black`).
- **Wordmark:** "SONAR" all-caps Geist Sans Bold tracking tight (-2% a -4%).
- **Lockups:** horizontal (banners) + vertical (avatares cuadrados).

### 3.2 Tests pasados (firmable)

- ✅ Favicon 16px legible — monograma `S` reconocible a tamaño mínimo.
- ✅ Contraste AAA Orange `#FF5100` sobre Black `#060607`.
- ✅ Contraste AAA White `#FAFAFA` sobre Black `#060607`.
- ✅ Atemporal — geometry-only, NO trends 2026 (no glassmorphism logo, no gradient holográfico, no aurora wash).
- ✅ Voz neutral premium-tech preservada — NO arquetipo militar/submarino literal.
- ✅ Versatility — funciona desde 16px favicon hasta 1024px+ marketing hero sin perder identity.

### 3.3 Anti-patterns concepto (PROHIBIDOS — ADR-012 D1 + ADR-016 D3)

- ❌ Ondas concéntricas (sonar ping radio/frecuencia).
- ❌ Submarino silhouette literal.
- ❌ Periscopio, hydrophone, torpedo, depth charge, hatch.
- ❌ Anchor/wheel marítimo (Admirals heritage deprecated).
- ❌ Acoustic waveform/oscilloscope.
- ❌ Compass/navigation symbols literales.
- ❌ "Eye that sees" eye-with-rays (literal "ver escuchando").
- ❌ **Multi-color variants logo** (post ADR-016 D3 — solo Black/Orange/White existen).
- ❌ **Gradient holográfico/mercurio** logo (timeless principle preserved).

---

## 4. Specs técnicos vinculantes (firmados v3)

### 4.1 Color tokens canónicos (ADR-016 D1 — SSoT canonical)

> **Esta tabla ES el SSoT de palette tokens product SONAR.** Todos los demás docs (`01_art_direction.md` v3.0, `02_sonar_tablet.md` v1.3, Bible v1.5, Tablet UI Tailwind `@theme`) referencian aquí.

| Token | Hex | Rol | Uso |
|---|---|---|---|
| `--sonar-black` | `#060607` | **CANVAS BASE** dark-only product | Background Tablet UI, marketing web, hero, splash. Default canvas TODA superficie product. |
| `--sonar-orange` | `#FF5100` | **SIGNAL / BRAND PRIMARY** | Logo identity, CTAs primary, focus rings, alerts críticos, signal active states, marketing accent único. |
| `--sonar-white` | `#FAFAFA` | **FOREGROUND / PURE** | Texto primario sobre Black, iconografía Lucide neutral, surfaces alpha layers high-emphasis. |

**Implementación stack (post ADR-016 D5):**
- **Tailwind v4 `@theme` directive** — definir 3 tokens en `tailwind.config.ts` Tablet UI.
- **CSS custom properties** — fallback for non-Tailwind contexts (marketing static HTML, NUI bridges raw).
- **NUNCA hardcodear hex** en componentes — siempre via token (`bg-sonar-black`, `text-sonar-orange`, `text-sonar-white`).

**Contraste mínimos firmable:**
- AAA `text-sonar-white` sobre `bg-sonar-black`: **19.5:1** ✅
- AAA `text-sonar-orange` sobre `bg-sonar-black` (large text + non-text graphic): **~6.5:1** ✅ (suficiente per WCAG 2.2 AAA non-text + AA large text)
- ❌ `text-sonar-orange` body small (<18px) sobre Black: usar Orange solo CTAs/headings/icons, NO body copy small.

**Tokens DEPRECATED v2 (purgados v3):**
- ❌ `--sonar-bright` `#2DD4BF` (teal v2) — eliminado post ADR-016 D1.
- ❌ `--sonar-pulse` `#14E5DD` — eliminado.
- ❌ `--abyss-black` `#03070A` — replaced by `--sonar-black` `#060607`.
- ❌ `--crew-100` `#F0F4F4` — eliminado (no light canvas product).
- ❌ `--coloro-support` `#175A5F` — eliminado.
- ❌ Crew neutrals tier (#B8C5C5 / #6B7878 / #2A3438) — eliminado.

### 4.2 Tipografía wordmark (preserved v3)

- **Familia:** Geist Sans (Vercel — free, variable font, OFL 1.1 SIL).
- **Peso base wordmark:** Bold 700 (firmado v3).
- **Tracking wordmark SONAR:** tight (-2% a -4%) para compactness técnica.
- **Caja:** all-caps "SONAR". Nunca lowercase. Nunca mixed case.
- **Fallback:** Inter Tight Bold (si Geist no embeddable en medio físico).
- **Marketing-only display alternativa:** Syncopate (Google Fonts) considerada para hero marketing pages — evaluable post-Sprint 2 close (NO product UI).

### 4.3 Geometría + construction (firmable)

- **Grid:** monograma `S` construido sobre grid modular preservado en `wordmark_sonar.svg` + `monogram_s*.svg` SVG sources.
- **Stroke linecap/linejoin:** round (coherente con iconografía Lucide round usada en SONAR Tablet UI per D5).
- **Espacio libre alrededor del logo:** mínimo = ancho de la "S" del monograma. Documentar visualmente en future guidelines PDF.
- **Tamaño mínimo pantalla:** 24px alto. Por debajo, usar solo monograma (favicon 16px).
- **Tamaño mínimo print:** 8mm alto.

### 4.4 Lockups (firmados — files reales)

| Lockup | File | Composición | Espaciado |
|---|---|---|---|
| **Horizontal** | `lockup_horizontal.svg` | Monograma · gap · wordmark "SONAR" | Gap = 0.5× altura monograma |
| **Vertical** | `lockup_vertical.svg` | Monograma encima · gap · wordmark "SONAR" | Gap = 0.3× altura monograma |
| **Tagline (opcional)** | TBD post-S2 | Lockup + línea debajo wordmark: *"Hear the depth."* en Inter Tight Medium 14px tracking +4% | Solo hero marketing |

---

## 5. Do ✅ / Don't ❌ (uso post-firmable)

### 5.1 ✅ Hacer (operacional product + marketing)

- **Product UI:** usar `monogram_s.svg` solid Orange para favicon Chrome tab + app-icon Tablet + watermarks (D2 dark-only baseline).
- **Marketing hero:** usar `lockup_horizontal.svg` o `lockup_vertical.svg` según composición.
- **Focus rings + hover states Tablet UI:** `monogram_s_light.svg` o `text-sonar-orange` ring-2 per D5 stack patterns.
- **Multi-density product:** rasterizar via `@art/tools/logo_export/export.mjs` pipeline (PNG @1x/@2x/@3x 16-1024px).
- **Print/external NON-product:** `monogram_s_black.svg` Black sobre fondos blancos third-party (única excepción D2 + D-S1.10E-A).
- **Tokens canónicos:** referenciar siempre `--sonar-black` / `--sonar-orange` / `--sonar-white` via Tailwind v4 `@theme` o CSS custom properties.

### 5.2 ❌ No hacer (misuse explícito)

- ❌ Stretch horizontal/vertical del monograma o lockup.
- ❌ Rotar el logo (ni 2°).
- ❌ Drop-shadow gaming / glow excessive.
- ❌ Outline stroke alrededor del logo.
- ❌ Gradient rainbow / holográfico / mercurio.
- ❌ **Versiones colored fuera de Black/Orange/White** (post ADR-016 D3 — no rojas/amarillas/verdes/moradas/teal/etc).
- ❌ Logo sobre fondo fotográfico caótico sin backplate Black.
- ❌ Logo con bevel/emboss.
- ❌ Wordmark en script/cursiva/serif.
- ❌ **Concepto ondas concéntricas** (radio/freq — explicit purga ADR-012).
- ❌ **Concepto submarino silhouette** (literal militar — explicit purga ADR-012).
- ❌ **`monogram_s_black.svg` en product UI** (post ADR-016 D2 — solo print/external NON-product).
- ❌ **Light variant fondo product** — Tablet UI + marketing web siempre Black canvas (post ADR-016 D2).
- ❌ **Hardcodear hex** en componentes Tablet UI — siempre via Tailwind tokens.

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

## 7. Proceso review (gates) — TODAS CERRADAS

| Ronda | Deliverable | Founder review | Outcome |
|---|---|---|---|
| **R0 — Kickoff** | Moodboard refs + dirección abstracta | Founder confirmed | ✅ Green-light dirección post-ADR-012 |
| **R1 — Conceptos** | Direcciones monograma thumbnails | Founder review | ✅ Elegida dirección geométrica abstracta |
| **R2 — Refinamiento** | Iteraciones aplicadas favicon/Tablet/hero | Founder review | ✅ Elegido monograma `S` final + lockups |
| **R3 — Sistema completo** | 4 monogramas + wordmark + 2 lockups + preview.html + export pipeline | Founder review S1.10 EXTENDED | ✅ Sign-off ejecutado 2026-05-04 |
| **R4 — Delivery** | Package commiteado `@art/branding/logo_v3/` + tooling `@art/tools/logo_export/` | Founder firmable | ✅ **LOCKED** post ADR-016 |

**Status global:** 🟢 Logo system v3 firmable. Pendiente solo guidelines PDF formal (low priority — defer post-MVP S2).

---

## 8. Licensing + entrega legal

- **Cesión rights:** logo v3 propiedad yaboula / SONAR. Unlimited perpetual worldwide commercial use.
- **Source files:** SVG sources + export pipeline Node/Puppeteer + fonts licenses (Geist Sans = SIL OFL 1.1, Inter Tight = SIL OFL 1.1).
- **NDA:** Logo confidential pre-reveal oficial SONAR (Sprint 2 close marketing launch).
- **Attribution:** Cascade (Sonnet 4.5) + founder yaboula accreditable en credits SONAR website + trailer.
- **Fonts embedding:** Geist Sans + Inter Tight + Geist Mono (todos SIL OFL 1.1, free commercial OK).

---

## 9. Histórico delivery v3 (firmable)

- **Designer:** Founder yaboula + Cascade (AI iteración Sonnet 4.5).
- **Effort real:** ~18h cumulative durante S1.10 EXTENDED.
- **Tooling:** Node.js + Puppeteer headless rendering pipeline (`@art/tools/logo_export/export.mjs`).
- **Pipeline output:** PNG @1x/@2x/@3x multi-density (16/32/64/128/256/512/1024) automated.

---

## 10. Checklist founder firmable v3 (closed)

- [x] ADR-011 + ADR-012 + ADR-016 D1+D2+D3 firmados.
- [x] Concepto base **LOCKED v3** — monograma `S` geométrico + wordmark Geist Bold.
- [x] Paleta canonical 3-color strict (Black `#060607` + Orange `#FF5100` + White `#FAFAFA`).
- [x] Geist Sans wordmark firmable.
- [x] Logo SVGs sources commiteados `@art/branding/logo_v3/`.
- [x] Pipeline export commiteable `@art/tools/logo_export/export.mjs`.
- [x] Excepción única `monogram_s_black.svg` print/external preservada (D-S1.10E-A).
- [ ] Guidelines PDF formal (10-14 páginas) — defer post-MVP S2.

---

## 11. Changelog

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| v1.0 | 2026-05-03 | Cascade (Sonnet 4.5) | Initial brief — concepto "S-onda concéntrica" locked. **Descartado mismo día** post-ADR-012 (radio/freq literal). |
| v2.0 | 2026-05-03 | Cascade (Sonnet 4.5) | **Rewrite clean post-ADR-012**: concepto NO-locked (5 candidatos preliminares + design space exploration), hybrid theme dark+white parity tests, anti-patterns explícitos ondas concéntricas + submarino literal, refs convergentes Apple/Linear/Vercel/Stripe/Arc/Notion + profundidad abstracta (NO submarinos), 4 review gates R0-R4. |
| v3.0 | 2026-05-04 | Founder + Cascade (Sonnet 4.5, S1.10.5) | **Document genre shift v2 → v3:** exploration brief → registro logo firmado + SSoT canonical palette tokens. Concepto LOCKED (monograma `S` geométrico + wordmark Geist Bold + 4 monogramas + wordmark + 2 lockups + preview + export pipeline). **Paleta v3 canonical (post-ADR-016 D1):** Black `#060607` + Orange `#FF5100` + White `#FAFAFA` (REPLACES Sonar Bright teal `#2DD4BF` + hybrid theme v2). **Dark-only doctrine (post-ADR-016 D2)** — light variant product PROHIBIDO. **3-color strict (post-ADR-016 D3)** — sin accent colors. **Excepción única `monogram_s_black.svg`** print/external NON-product (D-S1.10E-A). Review gates R0-R4 marcadas closed. Tokens deprecated v2 (sonar-bright/pulse/abyss-black/crew-100/coloro) explícitamente purgados. |

---

**FIN DEL BRIEF — LOGO SONAR v3 (post-ADR-016 firmable)**
