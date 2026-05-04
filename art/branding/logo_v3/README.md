# SONAR — Logo v3 (proposal)

> **STATUS:** 🟡 Proposal / unsigned. Contradice ADR-011/012 + `docs/art/01_art_direction.md` v2.0-scaffold-r6.
> Adoptar requiere **ADR-016** amending ADR-011/012 + bump art_direction → v3 + rewrite briefs.

---

## Brief

Brand v3 founder-driven (2026-05-04): pivot identidad cromática del teal (Sonar Bright `#2DD4BF` + Coloro `#175A5F`) a un sistema **Black / Orange / White** alto contraste, manteniendo la metáfora abstracta de profundidad de ADR-012 (NO regresar a literal-militar).

## Paleta v3

| Token             | HEX        | RGB              | CMYK             | Uso                                        |
|-------------------|------------|------------------|------------------|--------------------------------------------|
| `--brand-black`   | `#060607`  | `6 \| 6 \| 7`       | `14\|14\|0\|97`     | Canvas dark, ink primario                  |
| `--brand-orange`  | `#FF5100`  | `255 \| 81 \| 0`    | `0\|68\|100\|0`     | Identity primary (logo, CTA, focus, hero)  |
| `--brand-white`   | `#FAFAFA`  | `250 \| 250 \| 250` | `0\|0\|0\|2`        | Canvas light, ink sobre dark               |

## Isotipo — sonar waves

Mark abstracto: 3 arcos concéntricos en orange #FF5100 con opacidad descendente (1.0 / 0.65 / 0.35) — eco visual de "señal emergiendo desde profundidad" (ADR-012 metáfora abstracta). Funciona como `S` estilizada + signature wave-emission.

Variantes generadas:
- `monogram_s.svg` — orange (sobre black/white)
- `monogram_s_white.svg` — sobre orange/black
- `monogram_s_black.svg` — sobre white

Implementación inline en `preview.html` vía `<symbol id="isotipo">` con `currentColor` → herencia automática del color del parent.

## Tipografía — split estratégico

**Decisión founder:** dos stacks tipográficos según superficie. NO mezclar.

### A) Marketing / commercial / web store / hero

**Canonical (SVGs):** **Syncopate Bold 700** (Google Fonts, OFL) — usado en `wordmark_sonar.svg`, `lockup_horizontal.svg`, `lockup_vertical.svg`, `sonar_logo_orange.svg`. Cortes stencil añadidos via SVG `<mask>` overlays.

```css
font-family: 'Syncopate', sans-serif;
font-weight: 700;
letter-spacing: 0.05em-0.15em;
text-transform: uppercase;
```

**Preview HTML actual** usa Big Shoulders Stencil Display Black como display alternativo más cercano a la referencia GC Epic Pro Sans (font founder). Para alinear marketing al 100%, swap del HTML hero a Syncopate (matching los SVGs canonical).

Para producción 1:1 con GC Epic Pro Sans original: licenciar a Glyphonic (~$30-50). Syncopate (free) queda como canonical operativo de v3.

### B) Product UI / scripts / Tablet

Stack **Geist Sans + Inter Tight + Geist Mono** (canonical ADR-012, preserved):

```css
/* Display + UI body */
font-family: 'Geist', 'Inter Tight', -apple-system, BlinkMacSystemFont, sans-serif;
/* Mono / IDs / amounts / code */
font-family: 'Geist Mono', 'JetBrains Mono', monospace;
```

Uso: `resources/sonar_tablet/web-src` (Tablet NUI), futura admin UI, server logs/console output con formato, dashboards in-game. Limpio, neutral premium-tech, NO stencil.

**Razón del split:** stencil display fonts comunican identidad/personalidad fuerte → ideal para hero/marketing pero ruido visual en producto. Geist + Inter Tight = legibilidad y neutralidad para densidad UI alta (transactions, listings, balance amounts).

## Deliverables presentes

### Showcase
| Archivo          | Uso                                              |
|------------------|--------------------------------------------------|
| `preview.html`   | **Showcase commercial** — abrir en browser       |

### Monogramas (isotipo sonar-waves, 200×200)
| Archivo                    | Stroke | Color   | Uso                                |
|----------------------------|--------|---------|------------------------------------|
| `monogram_s.svg`           | 6px    | Orange  | Default, sobre black/white         |
| `monogram_s_white.svg`     | 6px    | White   | Sobre orange/black                 |
| `monogram_s_black.svg`     | 6px    | Black   | Sobre white                        |
| `monogram_s_solid.svg`     | 12px   | Orange  | Variant pesada (favicon ≤32px)     |
| `monogram_s_light.svg`     | 3px    | Orange  | Variant ligera (large hero, marketing fondo) |

### Wordmark + Lockups
| Archivo                          | Dims     | Uso                                   |
|----------------------------------|----------|---------------------------------------|
| `wordmark_sonar.svg`             | 400×100  | Wordmark "SONAR" Syncopate + stencil masks |
| `lockup_horizontal.svg`          | 600×150  | Isotipo + wordmark inline (header, signatures) |
| `lockup_vertical.svg`            | 400×400  | Isotipo arriba + wordmark abajo (square contexts) |

### Exploration / archive
| Archivo                          | Uso                                    |
|----------------------------------|----------------------------------------|
| `sonar_logo_orange.svg`          | Sheet exploration v1.0 (3 variantes A/B/C, lockup, swatches) — referencia/archive |
| `source_exploration_sheet.svg`   | Exploración inicial founder — archive  |

## Próximos pasos si founder aprueba

1. **ADR-016** — sign brand pivot v3 (palette + dual typography), amend ADR-011/012.
2. **Bump** `docs/art/01_art_direction.md` v2.0-r6 → v3.0:
   - Paleta tokens → Black/Orange/White.
   - Typography split: marketing stack (Syncopate canonical / GC Epic Pro premium) + product stack (Geist + Inter Tight, preserved).
   - Glow rules → `rgba(255,81,0,...)`.
3. **Bump** `docs/design/00_PRODUCT_BIBLE.md` v1.4 → v1.5.
4. **Rewrite briefs** `01_brief_logo.md` v2 → v3 con nuevo isotipo + paleta.
5. **Decisión font marketing:** Syncopate canonical (default actual) vs licenciar GC Epic Pro Sans (premium 1:1 con referencia founder original).
6. **Adaptar `resources/sonar_tablet/web-src` tokens CSS:**
   - `--primary-500: #2DD4BF` → `#FF5100`.
   - Mantener Geist + Inter Tight (sin cambio).
7. **PNG export pipeline:** adaptar `art/tools/logo_export/export.mjs` apuntando a `logo_v3/` con monogram SVGs como sources.

## Anti-patterns v3

- ❌ Stencil font en producto (Tablet, dashboards) — solo marketing.
- ❌ Geist/Inter Tight en hero marketing — falta personalidad.
- ❌ Mezclar teal Sonar Bright/Coloro con orange v3.
- ❌ Glow teal sobre orange.
- ❌ Roboto/Poppins/system fonts default.
- ❌ Naranja saturado puro `#FF6600` — el ref es `#FF5100` (más rojizo).
