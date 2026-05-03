# SONAR — Logo v2 (concept A "S-curl open")

**Source:** `sonar_logo_concept_explorations.svg` (archivado en `source_exploration_sheet.svg`, cleaned a solo variante A).

Variante **A** del concept exploration sheet. 3 arcos que trazan una S con eco a la derecha.

## Aclaración importante — NO es pivote de marca

**Esto NO es un cambio de dirección de marca vs logo v1.** Metáfora canonical, voz, paleta Tier A/B/C, tipografía wordmark Geist SemiBold — todo intacto per `01_brief_logo.md` v2 + ADR-011 + ADR-012.

**Único cambio vs v1:** preferencia VISUAL por forma **arc-based** en vez de **letter-based** (v1 era letra S geométrica chamfered con counter octagonal + petals). La identidad de marca permanece idéntica — solo la forma del glyph cambia.

## Anatomía

| Elemento | Construcción |
|---|---|
| **Wave 3** (main S) | M 41 128 Q 71 86 113 86 Q 155 86 155 128 Q 155 170 113 170 Q 65 170 41 212 · opacity 1.0 |
| **Wave 2** (mid echo) | M 113 86 Q 185 86 185 128 Q 185 170 113 170 · opacity 0.65 |
| **Wave 1** (outer echo) | M 113 44 Q 215 44 215 116 Q 215 188 113 188 · opacity 0.35 |
| Stroke | width 13.5 · linecap round · linejoin round |
| Color | `#2DD4BF` Sonar Bright |
| Canvas | `#03070A` Abyss Black |

## Metáfora (canonical per founder · 2026-05-03)

**Lectura canonical:** los 3 arcos representan **profundidad / trabajar a fondo** — capas de descenso que revelan valor oculto. Alineado con `01_brief_logo.md` v2 §1 ("profundidad simbólica + exploración paciente · valor oculto bajo capas · calma metódica al descender · patterns que emergen al observar con atención").

**Lectura explícitamente descartada:** ❌ NO son "ondas sonar / ping radio / frecuencia acústica". El brief v2 purgó esa interpretación literal (ADR-012 D1). Los arcos aquí son **capas de profundidad** (metáfora C1 Descent-layers del brief §3.1), NO emanaciones acústicas.

**Por qué la geometría es la misma pero la semántica diverge:** concentric arcs + S-shape es un objeto polisémico. El viewer puede leerlo como (a) ondas radio o (b) capas de profundidad. Founder firma lectura (b) como canonical.

> **Nota para designer profesional futuro** (si se contrata per brief §7 R0-R4): si la legibilidad semántica es un issue (viewer lee "sonar ping" antes que "depth layers"), considera ajustar — reemplazar arcs por capas horizontales offset, diferencial visual entre layers más pronunciado, o añadir cue visual de "descenso" (top-heavy vs bottom-heavy weight).

## Wordmark

- **Font:** Geist SemiBold (600), fallback Inter Tight → Inter → system-ui
- **Tracking:** −3.5% (letter-spacing −0.035em)
- **Color:** Crew 100 `#F0F4F4`
- **Contraste:** #2DD4BF / #03070A → 9.8:1 ✓ AAA

## Paleta canónica (verified vs brief §4.1)

| Token | Hex | Uso logo | Status |
|---|---|---|---|
| `--sonar-bright` | `#2DD4BF` | monograma dark canvas (canonical primary) | ✅ aplicado |
| `--sonar-bright-shifted` | `#1FB39E` | monograma light canvas (Crew 100) | ✅ aplicado (`monogram_s_light.svg`) |
| `--sonar-pulse` | `#14E5DD` | ONLY if C3 gradient | ⬜ no usado |
| `--abyss-black` | `#03070A` | canvas primario dark | ✅ aplicado |
| `--crew-100` | `#F0F4F4` | wordmark + canvas light | ✅ aplicado |
| `--coloro-support` | `#175A5F` | **✗ PROHIBIDO en logo** | ✅ respetado (no usado) |

## Archivos

### Sources (SVG)

| File | Descripción |
|---|---|
| `source_exploration_sheet.svg` | Source sheet cleaned — solo variante A con aclaración canonical |
| `monogram_s.svg` | **Canonical primary** — concept A con opacity fade (echo effect) |
| `monogram_s_solid.svg` | Variante stamp — 3 arcos a opacity 1 (tamaños pequeños / favicon) |
| `monogram_s_light.svg` | Variante inverse canvas — `#1FB39E` sobre Crew 100 `#F0F4F4` |
| `wordmark_sonar.svg` | SONAR Geist SemiBold text |
| `lockup_horizontal.svg` | Monograma + SONAR side-by-side |
| `lockup_vertical.svg` | Monograma stacked sobre SONAR |
| `preview.html` | Showcase visual |

### Exports (PNG raster · `exports/` · 27 archivos)

Generados con `art/tools/logo_export/` (Node + sharp + png-to-ico). Regenerar con `npm run build`.

| Serie | Sizes | Uso |
|---|---|---|
| `monogram_*.png` | 16/32/64/128/256/512/1024 | multi-density primary |
| `monogram_solid_*.png` | 16/32/64/128/256 | small sizes / stamp |
| `monogram_light_*.png` | 64/128/256/512 | light canvas hybrid |
| `wordmark_*.png` | 256/512/1024/2048 | marketing / footer |
| `lockup_horizontal_*.png` | 512/1024/2048 | banners horizontales |
| `lockup_vertical_*.png` | 256/512/1024 | avatar cuadrado / packaging vertical |
| `favicon.ico` | multi-res 16+32+48 | Chrome tab / OS favicon |

## Specs relaciones lockup

- **Gap horizontal:** 0.5× monogram height
- **Gap vertical:** 0.25× monogram height
- **Wordmark size:** 72pt (font-size 72) en lockups
- **Monogram:** scale 0.625 en horizontal (160 tall), scale 1.0 en vertical (256 tall)

## Status

**WORKING CANONICAL** — adoptado por founder `2026-05-03` como logo operacional. Cubre todos los contextos de desarrollo (Tablet UI, favicon, fxmanifest thumbnails, docs internos, marketing pre-launch).

**NO firmado como ADR** todavía — founder puede contratar designer profesional en fase posterior (per `01_brief_logo.md` v2 §7 proceso R0-R4) que pueda refinar o reemplazar. Hasta entonces, **este logo es el que se usa**.

## Audit vs `01_brief_logo.md` v2 §2.1 deliverables

| # | Deliverable brief | Status | Nota |
|---|---|---|---|
| 1 | `sonar_logo_full.svg` | ✅ | = `lockup_horizontal.svg` (full lockup) |
| 2 | `sonar_logo_monogram.svg` | ✅ | = `monogram_s.svg` |
| 3 | `sonar_wordmark.svg` | ✅ | = `wordmark_sonar.svg` |
| 4 | `sonar_logo_lockup_horizontal.svg` | ✅ | = `lockup_horizontal.svg` |
| 5 | `sonar_logo_lockup_vertical.svg` | ✅ | = `lockup_vertical.svg` |
| 6 | `sonar_logo_dark_canvas.svg` | ✅ | = `monogram_s.svg` (Sonar Bright on Abyss) |
| 7 | `sonar_logo_white_canvas.svg` | ✅ | = `monogram_s_light.svg` (shifted on Crew 100) |
| 8 | `sonar_logo_reverse.svg` | ⬜ | Abyss on Crew (B&W print) — genera on-demand si se necesita |
| 9 | Raster PNG 16/32/64/128/256/512/1024 + favicons | ✅ | 27 archivos en `exports/` |
| 10 | `sonar_logo_guidelines.pdf` (10-14 págs) | ⬜ | SKIP — requiere designer pro per brief §7 |
| 11 | `sonar_logo_source.fig` (Figma) | ⬜ | SKIP — SVGs son source canonical here |
| 12 | Splash video 4s loop `.mp4` | ⬜ | SKIP — stretch goal marketing |

### Specs verification vs brief §4

- ✅ **§4.1 Color tokens** — paleta completa respetada, Coloro prohibido respetado
- ✅ **§4.2 Tipografía** — Geist SemiBold 600, tracking −3.5%, all-caps, fallback Inter Tight
- ✅ **§4.3 Geometría** — stroke linecap/linejoin round, scalable SVG vector
- ✅ **§4.4 Lockups** — horizontal gap 0.5× height, vertical gap 0.3× height
- ✅ **Contraste AAA dark canvas** — 9.8:1 #2DD4BF on #03070A ≥ 7:1 ✓
- ⚠️  **Contraste light canvas** — 3.2:1 #1FB39E on #F0F4F4, AA Large only (pasa por el stroke grueso ≥ 13.5px). Brief §2.2 sugiere possible thin border para AA normal — pendiente designer pro.

### Anti-patterns §5.2 respetados

- ✅ No stretch, no rotate, no drop-shadow
- ✅ No outline, no gradient rainbow, no bevel
- ✅ No wordmark cursive/serif
- ⚠️  Ondas concéntricas / radio-freq → reinterpretadas semánticamente como **capas de profundidad** por founder sign-off (ver §Metáfora arriba)

## Docs NO tocados (per instrucción founder 2026-05-03)

- ⬜ `docs/art/01_art_direction.md` — NO se actualiza
- ⬜ `docs/art/briefs/01_brief_logo.md` — v2 se mantiene vigente
- ⬜ `docs/planning/02_decision_log.md` — sin ADR-013 por ahora

## Regenerar exports

```bash
cd art/tools/logo_export
npm install    # primera vez
npm run build  # regenera 27 archivos en art/branding/logo_v2/exports/
```
