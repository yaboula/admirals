# SONAR · Proyecto C6 · Identity Sheet (R2)

Hoja de identidad visual completa siguiendo la especificación founder 2026-05-03.

## Cómo revisar

Abre `preview.html` en el browser. Verás:

1. **Hoja completa** (`identity_sheet_c6.svg`) — fila A (diseño base) + fila B (construcción técnica), encabezado y pie.
2. **Deliverables individuales** — monograma, wordmark, lockups H y V.
3. **Brand color** — Sonar Bright `#2DD4BF` sobre Abyss Black `#03070A`.
4. **Density test** — monograma a 128/64/32/24/16 px.

## Estructura de la hoja (matchea spec founder)

### Header
- Izquierda: `SISTEMA DE IDENTIDAD VISUAL — SONAR`
- Derecha: `PROYECTO C6`

### Fila A — Diseño base
- **A1** Monograma S petals chamfered (trazo continuo + 2 pétalos internos + esquinas chaflán 45°).
- **A2** Wordmark SONAR chamfered geometric slab (chaflán 45° en esquinas exteriores de S y R, anotado).
- **A3** Lockup horizontal (monograma + wordmark, gap 0.5x, área de respeto 1x).
- **A4** Diagrama de construcción · octágono regular inscrito en cuadrícula · ángulo de chaflán de referencia 45°.

### Fila B — Geometría y construcción
- **B1** Construcción del monograma · puntos de anclaje en cada vértice · zoom pétalo a 45°.
- **B2** Construcción del wordmark · "O" octagonal · espaciado uniforme · marca TM alineada al grid.
- **B3** Lockup vertical (monograma apilado y centrado · gap 0.3x · margen 1x).
- **B4** Espacio libre · fórmula `1x = altura de la S del wordmark` (no del monograma superior).

## Decisiones aplicadas

- Wordmark: `SONAR` (proyecto canonical post-ADR-011). El `SONOR` que aparecía en la referencia founder era typo del designer anterior.
- Color: light canvas (Crew 100 `#F0F4F4`) con elementos Abyss Black `#03070A`, accents Sonar Bright `#2DD4BF` para anotaciones técnicas (puntos de anclaje, círculos chamfer 45°, espacio libre dashed).
- Coloro Support `#175A5F` solo para texto secundario / labels / callouts (Tier C estructural, prohibido en logo).
- Grid 16×16 modular, chamfer 8px (50% celda) @ 45°.
- Stroke uniforme 32 (monograma) / 16 (wordmark cell-grid).
- "O" del wordmark = octágono estricto (8 vértices interior + 8 exterior, fill-rule evenodd).

## Compliance

- ✅ ADR-011 — wordmark `SONAR`, no `Admirals`.
- ✅ ADR-012 D1 — metáfora abstracta, sin sonar-ping concéntrico, sin submarino, sin militar literal.
- ✅ ADR-012 D2 — hybrid theme aware: monograma renderiza correctamente sobre Abyss Black y Crew 100.
- ✅ Brief §4.1 — Sonar Bright = identity, Coloro `#175A5F` prohibido en logo (solo accent textual aquí).
- ✅ Brief §4.4 — lockups gap H=0.5x, V=0.3x; clear-space 1x = altura S wordmark.

## Archivos

```
r2_identity_sheet/
├── README.md                  ← este doc
├── preview.html               ← visor browser-ready
├── identity_sheet_c6.svg      ← HOJA COMPLETA (1600×1100)
├── monogram_s.svg             ← monograma standalone (negro sobre transparente, 256×256)
├── monogram_s_brand.svg       ← monograma brand color (Sonar Bright sobre Abyss, 256×256)
├── wordmark_sonar.svg         ← wordmark standalone (496×176)
├── lockup_horizontal.svg      ← lockup H (720×200)
└── lockup_vertical.svg        ← lockup V (480×480)
```

## Próximos pasos sugeridos (R3)

1. Founder review hoja completa y aprueba/itera proporciones.
2. Conversión a brand color final (Sonar Bright sobre Abyss y sobre Crew 100, validar AA/AAA).
3. Glow signature opcional para hero marketing.
4. Raster exports PNG @1x/@2x/@3x en 64/128/256/512/1024 + favicons 16/32 ICO.
5. Guidelines PDF 10-14 páginas (brief §2.1 deliverable #10).
