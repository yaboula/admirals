# R1 — Rationale (BRIEF-LOGO-001 v2)

> **Ronda:** R1 Conceptos · **Designer:** Opus 4.7 MAX (AI executor path §9 brief) · **Fecha:** 2026-05-03
> **Brief:** `docs/art/briefs/01_brief_logo.md` v2 · **Pre-requisito:** R0 moodboard + cuestionario delivered (defaults asumidos si founder no respondió antes de R1).
> **Propósito:** rationale escrito 1-pager por concepto (per brief §7 "cada ronda incluye rationale escrito del designer, NO solo imágenes"). Founder elige 2 conceptos para R2 refinamiento (color + favicon/app-icon/hero dark+white tests).

---

## Defaults R0 asumidos para esta ejecución R1

Si founder no respondió `r0_kickoff/cuestionario_founder.md` antes de esta ronda, R1 procede con los defaults razonados:

- **Q1 (lectura S):** C híbrido — 4/5 conceptos leen S, 1/5 explora abstract puro como sondeo. **Aplicado: C1 es el más abstract; C2-C5 leen S claramente.**
- **Q2 (glow R1?):** A reservar R3. **Aplicado: R1 = puro B&W silueta.**
- **Q3 (tagline lockup):** A R3 entrega ambos. **Aplicado: R1 = monogramas only sin wordmark.**
- **Q4 (app-icon Tablet):** A monograma plano sobre Abyss square. **Aplicado: R2 mostrará monograma sobre `#03070A` rounded square 88px.**
- **Q5 (Geist Bold/SemiBold):** A SemiBold 600 tracking -3%. **Aplicado: R2 wordmark = Geist SemiBold.**
- **Q8 (logo R4 antes de iconos R0):** A canonical README jerarquía. **Aplicado: paquete logo NO bloqueado por iconos.**
- **Q9 (sync R3):** A full async. **Aplicado: R3 será documento async profundo con preguntas batched, no llamada.**

> Si founder difiere de cualquier default → responder cuestionario + rerun R1 sobre concepto afectado. Costo rerun: ~30min Opus.

---

## Test framework R1 (cómo evaluar los 5 concepts)

Cada concepto se mide contra 5 criterios brief §1 + reglas §4 + anti-patterns §5.2 + ADR-012 D1:

| # | Criterio | Peso | Test concreto |
|---|---|---|---|
| 1 | **Profundidad simbólica** (no literal submarino) | 🟢 critical | ¿Sugiere capas/dimensión/algo "más allá de la superficie"? ¿Sin literal submarino? |
| 2 | **Precisión técnica** (geometric purity) | 🟢 critical | ¿Construction es modular grid 16×16 sin "freehand"? ¿Proportional rigor visible? |
| 3 | **Calma autoridad** (confidence sin gritar) | 🟡 high | ¿Reads premium-tech (Vercel/Linear/Stripe class)? ¿O reads gaming/ornate/loud? |
| 4 | **Atemporal 5+ años** | 🟡 high | ¿Sobrevive sin refresh? ¿O contiene trend 2026 (gradient holo, neón, AI-render flat 3D)? |
| 5 | **Recognizable @16px favicon** | 🟢 critical | ¿La silueta lee a 16px? Test en `contact_sheet.html` (recargado en /r1_concepts/). |

**Anti-pattern auto-blockers (si toca cualquiera, descartado sin defenderlo):**
- ❌ Concentric waves (sonar ping radio/freq) — explicit purga ADR-012 D1.
- ❌ Submarine silhouette literal.
- ❌ Periscope / hydrophone / torpedo / anchor / wheel / compass.
- ❌ Eye-with-rays "ver escuchando" literal.
- ❌ Cyberpunk neón / military tacticool / gaming RGB / cartoon mascot / vintage retro.
- ❌ Gradient holográfico mercurio rainbow.
- ❌ Bevel / drop-shadow gamer / outline stroke decorative / emboss.
- ❌ Concepto requires color para ser identificable (silueta B&W debe funcionar sin color).

---

## C1 — Descent-layers

**Archivo:** `c1_descent_layers.svg`

**Concepto:** la "S" implícita emerge de **4 bandas horizontales rectangulares** stacked descendentemente con offset zigzag. Top wide-derecha (+24 cells right-extended), upper-narrow-left, lower-narrow-right, bottom wide-izquierda (+24 cells left-extended). Vocabulario: **geological strata cross-sections** (Column 2 P1 moodboard) + **layered UI patterns** (P5).

**Reasoning principal:**
- Es **el más distintivo conceptualmente** de los 5 candidatos. No imita ningún logomark conocido (ni Linear ni Vercel ni Stripe). Reads como "stack of layers" antes que "letter S" — premium-tech con identity propia.
- **Construction modular puro:** todo en grid 16×16 (gaps 24=1.5 cells, h=30 ≈ 2 cells, widths múltiplos de 78/164). Construction diagram trivial documentar.
- **Atemporal extremo:** rectangulares simples, no usa stroke complex, no usa gradient, no usa effects. Sobrevive 50 años sin refresh (test Apple).
- **Hybrid theme paridad:** silueta sólida funciona AAA en Abyss + AA+ en Crew 100 sin shift de color.

**Trade-offs y riesgos:**
- 🟡 **Lectura "S" implícita NO explícita**: a 16px favicon, el zigzag puede leerse como "barras random" sin reconocer letra S. Mitigación: ajustar offset (más pronunciado) o reducir bandas a 3 si test favicon falla.
- 🟢 **Memorability cross-locale**: si la S no es lectura primaria, el monograma debe ganar memorability por forma propia. Linear lo logra con su "L estilizada" — C1 puede lograrlo con "stack distintivo".
- 🟡 Posible riesgo "I" / "Z" misreading si offset mal calibrado. Test R2 con humanos no-context.

**Tests favicon esperados (R2 entregará HTML real):**
- @256px: ✅ silueta clara, S implícita reconocible.
- @64px (Tebex): ✅ legible.
- @24px (Tablet small icon): 🟡 borderline — depende de offset.
- @16px (favicon Chrome tab): 🟡 alto riesgo. Si falla, simplificar a 3 bandas o aumentar offset.

**Convergencia moodboard:** F1+F2+F4 (geometric purity Linear/Vercel/Apple) ⊕ P1+P3+P5 (capas geological/architectural/UI layers).

**Adecuación brief §3.1 candidate C1:** ✅ exacta. "S formada por 3-4 capas horizontales descendiendo, cada capa con leve offset" → 4 bandas con offset zigzag = ✓.

**Recomendación Opus:** **fuerte candidato R2** si founder valora distinctivenes alta. Si founder prefiere "S clara explicit", saltarse a C5.

---

## C2 — Prisma profundidad

**Archivo:** `c2_prisma_profundidad.svg`

**Concepto:** S clásica como **slab tridimensional minimal** sugerido por **back-face offset (10,10) en mid-gray** + front-face Abyss Black solid encima. Vocabulario: **isometric infographics** (P6) + **architectural section drawings** (P3) — sugiere dimensión sin gritar 3D.

**Reasoning principal:**
- Profundidad **sugerida explícitamente** por extrusión visible — el concepto literal "depth" se materializa formalmente.
- **S clara explicit**: reads como letra S sin esfuerzo. Memorability cross-locale alta.
- **Stroke round canonical**: linecap/linejoin round alinea con sistema iconográfico Lucide round (brief §4.3) → coherence cross-touchpoint.
- Notion-class minimalist 3D (refs F6+P6) — aporta personalidad sin cyberpunk.

**Trade-offs y riesgos:**
- 🔴 **Riesgo bevel/emboss anti-pattern (brief §5.2 misuse #8)**: si la extrusión se ve "decorative" en lugar de "structural", cae en gamer drop-shadow. Mitigación: el back-face NO es shadow blur, es offset solid de same-shape — distinto formal de drop-shadow. Pero requiere supervisión pixel-perfect R2/R3 para no degenerar.
- 🟡 **Atemporalidad media**: 3D minimalist es trend 2024-2026 (Notion 3D logo, Vercel triangle 3D treatment). Riesgo desactualizarse 2030. Mitigación: extrusión MUY sutil (10px en 256 = 4% del canvas, casi imperceptible) → reads más como "ambidextro depth hint" que como "logo 3D".
- 🟡 **Hybrid theme**: el back-face mid-gray funciona AAA dark canvas. Sobre white canvas, mid-gray contra blanco puede perder definición. Mitigación R2: en white canvas, back-face shifts a Coloro Support `#175A5F` o se elimina (logo collapses a flat).
- 🟢 **Favicon test**: a 16px la extrusión 10px se reduce a ~0.6px — visible solo como "fuzz" sutil. Logo debería leerse como flat S a 16px (graceful degradation).

**Tests favicon esperados:**
- @256px: ✅ extrusión clara, depth visible.
- @64px: ✅ S + extrusión sutil.
- @24px: 🟡 extrusión casi imperceptible, reads como flat S.
- @16px: 🟡 extrusión invisible. Logo se reduce a "C2 sin extrusión" = básicamente C5 simplificado. Acceptable graceful degradation.

**Convergencia moodboard:** F2+F4+F5 (Vercel + Apple + Arc geometric distinctive) ⊕ P3+P6 (architectural sections + isometric infographics).

**Adecuación brief §3.1 candidate C2:** ✅ exacta. "S estructurada como prisma geométrico con profundidad isométrica leve (3D minimalist)" → ✓.

**Recomendación Opus:** **candidato medio R2**. Si founder valora "depth literal explicit" alto, R2 vale. Si founder valora "atemporalidad pura" alto, prefiere C1 o C5.

---

## C3 — Gradient depth

**Archivo:** `c3_gradient_depth.svg`

**Concepto:** S sólida (mismo path canonical) con **gradient lineal vertical** Crew 300 light-gray top → Abyss Black bottom. Sugiere "**descenso de luz al abismo**" — vocabulario oceanographic depth profile (P4+P7). R2 swap: Sonar Bright `#2DD4BF` top → Sonar Pulse `#14E5DD` bottom.

**Reasoning principal:**
- **Más visualmente comercial** de los 5: gradient sutil aporta richness sin saturación.
- Vocabulario "ocean depth zones" (P7) directo: el gradient ES el descenso de luz que define la metáfora.
- Single S-path simple → construction documenta facilísimo.
- En color (R2): Sonar Bright→Pulse leverages Tier B identity-pop al máximo. Marketing-friendly.

**Trade-offs y riesgos:**
- 🔴 **Riesgo CRITICAL favicon @16px**: gradient se pierde completamente. Logo se reduce a "S monocrome" = básicamente C5 simplificado. ¿Es ese el comportamiento deseado o degeneración inaceptable?
- 🔴 **Riesgo monochrome fallback**: cualquier contexto print 1-tinta, B&W obligatorio, monochrome export → pierde identity. Mitigación: definir claramente monochrome fallback es C5-equivalent thick stroke. PERO eso significa C3 y C5 colapsan al mismo logo en B&W = founder está pagando por 2 conceptos que son 1.
- 🟡 **Trend dependency**: gradient logos volvieron 2020s (Stripe, Notion variations) tras déjà-vu Web 2.0 era. Atemporalidad MEDIA — depende de evolución trend.
- 🟢 **Hybrid theme paridad**: en Abyss canvas, gradient top→bottom aporta separación visual elegante. En Crew 100 white canvas, **gradient bottom Sonar Bright→top Crew 100** se vuelve casi invisible top half — high risk de fallar AA.

**Tests favicon esperados:**
- @256px: ✅ gradient elegante visible.
- @64px: ✅ gradient sutil pero presente.
- @24px: 🟡 gradient casi indistinguible, reads como solid teal.
- @16px: 🔴 gradient invisible. Reduces a flat color.

**Convergencia moodboard:** F1+F4 (silhouette + simplicity) ⊕ P7 (gradient ocean depth).

**Adecuación brief §3.1 candidate C3:** ✅ exacta. Y brief específicamente avisa: "Riesgo: debe pasar test favicon 16px sin perder identidad." → confirmed.

**Recomendación Opus:** **candidato medio-bajo R2**. Si founder valora "marketing visual richness" extrema, vale para Tebex hero exclusivo + monochrome fallback documentado. Si favicon es prioridad, descartar C3 y reservar gradient para "glow signature" (brief §2.3) que sí es ya marketing-only.

---

## C4 — Geometric depth-grid

**Archivo:** `c4_geometric_depth_grid.svg`

**Concepto:** S-shape mask **filled with horizontal contour-style lines** (20 lines, spacing 10px, stroke 2.5px) evocando **bathymetric/topographic depth maps** (P2+P4). Vocabulario: "S filled with depth contour lines como un topo map".

**Reasoning principal:**
- **Vocabulario más distintivo**: nadie en FiveM (ni en general SaaS B2B) tiene logo con esta construcción. Rapid memorability.
- Conexión literal-pero-abstracta a la metáfora: el sonar lee profundidad → el logo ES un mapa de profundidad embedded en la letra. Conceptualmente magnífico.
- **Geometric purity extrema**: 20 líneas paralelas matemáticamente exactas. Construction trivial.

**Trade-offs y riesgos:**
- 🔴 **Riesgo CRITICAL favicon @16px**: 20 líneas en 16px = línea cada 0.8px. **Imposible renderizar legible**. Logo colapsa a "borrón sólido". Mitigación: variant simplificada @16px que es solid S-shape (= colapsa a C5 idéntico).
- 🟡 **Riesgo 24px Tablet small icon**: 20 líneas en 24px = línea cada 1.2px = anti-aliasing extremo, líneas se mezclan. Pierde identidad parcialmente.
- 🟡 **Print 1-tinta**: las líneas funcionan B&W. ✓
- 🟡 **Hybrid theme**: en Abyss canvas las líneas Sonar Bright sobre Abyss = AAA. En Crew 100 white surface, las líneas Sonar Bright sobre blanco = solo 2.7:1 — fallaría AA. Mitigación: white canvas usa shifted #1FB39E + considera grosor 3px en lugar de 2.5px.
- 🟡 **Atemporalidad alta**: depth maps son atemporal (cartografía es ciencia, no trend). Pero trend 2020s incluye logos "lined" (Apple Watch series face). Mitigación pasable.

**Tests favicon esperados:**
- @256px: ✅ líneas claras, contour evocativo.
- @64px: ✅ líneas visibles, identidad preservada.
- @24px: 🟡 líneas se difuminan, alto riesgo.
- @16px: 🔴 invisible, requiere variant simplificada (= C5-equivalent).

**Convergencia moodboard:** F2+F6 (geometric tech) ⊕ P2+P6+P8 (topo curves + isometric + tessellation).

**Adecuación brief §3.1 candidate C4:** ✅ exacta. "S construida como grid isométrico stripped-down — líneas paralelas perspective sugiriendo 'profundidad medida'" → ajustado a horizontal contour (más cleanly readable que isometric 30°). Si founder prefiere strict isometric, R2 puede explorar variante diagonal +30°.

**Recomendación Opus:** **candidato bajo R2** salvo founder valore "vocabulario único FiveM" extremo. Riesgo favicon gravitante. Si founder lo elige R2, OBLIGATORIO entregar variant simplificada @16/24px con menos líneas (4-6) o solid fallback.

---

## C5 — Geometric S-descent

**Archivo:** `c5_geometric_s_descent.svg`

**Concepto:** S-path canonical SPLIT en midpoint (128,128). **Top half (surface)** = thin stroke 12px sugiriendo "superficie ligera". **Bottom half (depth)** = thick stroke 40px sugiriendo "masa descendente / profundidad". Vocabulario: dualidad surface vs depth, simplest baseline minimal.

**Reasoning principal:**
- **Más timeless de los 5**: stroked S simple, no effects, no gradient, no extrusión. Like Stripe, like Linear logomarks. **Sobrevive 50 años sin refresh**.
- **Lectura "S" más clara**: traditional letterform, immediate cross-locale memorability.
- **Test favicon @16px**: ✅ alta probabilidad de pasar — silueta limpia incluso a tamaños extremos.
- **Construction más simple**: 2 paths, 2 stroke widths, done. Trivially documenta.
- **Concepto "surface + depth" implícito**: thin top vs thick bottom = cualidad simbólica embedded en geometry, no en effects.
- **Hybrid theme paridad nativa**: stroked outline funciona AAA dark + AA white sin shift dramático.

**Trade-offs y riesgos:**
- 🟡 **Menos distintivo conceptualmente**: parece "S común". Es la opción más segura pero también la menos memorable de las 5. Mitigación: la diferencia thin/thick top/bottom es señal sutil de identidad — en hover/focus state de UI, puede animarse para subrayar el binario.
- 🟢 **Posible "ya hecho antes"**: existen S-monogrames con weight differences (cuestión investigar legal pre-R3 trademarks). Mitigación: la combinación específica thin-top + thick-bottom para sugerir "depth" concept es propia.
- 🟢 **Glow signature compatible**: si R3 añade glow Sonar Bright behind, C5 reads glorioso. C1 también pero menos icónico.

**Tests favicon esperados:**
- @256px: ✅ elegante, claro, professional.
- @64px: ✅ excelente.
- @24px: ✅ bien, weight differential visible.
- @16px: ✅ S clara, weight differential apenas visible — graceful degradation sin pérdida total.

**Convergencia moodboard:** F1+F3+F4 (purest minimalism Linear/Stripe/Apple) ⊕ P5 (layer differentiation surface vs depth).

**Adecuación brief §3.1 candidate C5:** ✅ exacta. "S con curvas tradicionales pero las 2 curvas claramente diferenciadas en weight/style sugiriendo 'superficie + profundidad'. Más simple y atemporal" → ✓.

**Recomendación Opus:** **fuerte candidato R2** como **baseline conservador high-confidence**. Si founder valora "low-risk + maximum atemporalidad", C5 es la opción dominante.

---

## Recomendación final Opus 4.7 MAX para founder

> **Selección sugerida 2/5 para R2:** **C1 (descent-layers)** + **C5 (geometric S-descent)**.

**Razonamiento:**

- **C1 vs C5** son las **dos direcciones más opuestas/complementarias** del espacio de exploración:
  - **C1** = máxima distintividad conceptual + atemporalidad alta + lectura "S" implícita riesgosa @16px.
  - **C5** = máxima atemporalidad + lectura "S" explícita robusta + distintividad media.
- Si founder elige C1 R2, el founder gana **logomark único FiveM mercado** (nadie tiene esto) — aceptando riesgo favicon que se valida en R2 tests reales.
- Si founder elige C5 R2, el founder gana **logomark Linear/Stripe-class confidence** — aceptando ser "uno más" del cohort premium-tech minimal.
- **R2 puede iterar ambos** con color + favicon + hero dark + hero white tests, founder elige 1 final R3.

**Conceptos descartables sin fricción:**

- **C3 (gradient depth)**: riesgo favicon + colapsa a C5 en monochrome. Reservar gradient para "glow signature" R3 (brief §2.3) que ya es marketing-only.
- **C4 (geometric depth-grid)**: riesgo favicon CRITICAL + requiere variant @16px simplificada que colapsa a C5. Vocabulario único PERO el coste favicon no compensa.
- **C2 (prisma profundidad)**: riesgo bevel/emboss + atemporalidad media + hybrid theme white canvas problemático. Concepto "depth literal" mejor servido por C5 weight-binary.

> **Si founder difiere:** founder es decision-maker final per brief §1 + R0-Q7. Si elige otro pair (e.g. C1+C2, o C3+C5), R2 procede con la elección del founder. Opus 4.7 MAX entrega la pair elegida.

---

## Anti-patterns auto-check (los 5 conceptos pasan ✅)

| Anti-pattern | C1 | C2 | C3 | C4 | C5 |
|---|:-:|:-:|:-:|:-:|:-:|
| Concentric waves (radio/freq purga ADR-012 D1) | ✅ NO | ✅ NO | ✅ NO | ✅ NO | ✅ NO |
| Submarine silhouette literal | ✅ NO | ✅ NO | ✅ NO | ✅ NO | ✅ NO |
| Acoustic waveform / oscilloscope | ✅ NO | ✅ NO | ✅ NO | ✅ NO | ✅ NO |
| Periscope / hydrophone / torpedo / anchor / wheel / compass | ✅ NO | ✅ NO | ✅ NO | ✅ NO | ✅ NO |
| Eye-with-rays "ver escuchando" literal | ✅ NO | ✅ NO | ✅ NO | ✅ NO | ✅ NO |
| Cyberpunk neón / military tacticool | ✅ NO | ✅ NO | ✅ NO | ✅ NO | ✅ NO |
| Gradient holográfico mercurio rainbow | ✅ NO | ✅ NO | ✅ NO (pure 2-stop tonal) | ✅ NO | ✅ NO |
| Bevel / drop-shadow gamer / emboss | ✅ NO | 🟡 SUTIL** | ✅ NO | ✅ NO | ✅ NO |
| Outline stroke decorative | ✅ NO | ✅ NO | ✅ NO | ✅ NO | ✅ NO |

**\*\*** C2 isometric extrusion = formalmente offset solid same-shape, NO blur drop-shadow (anti-pattern). Pero requiere supervisión R2 pixel-perfect para no degenerar a bevel.

---

## Próximos pasos

1. **Founder revisa los 5 SVGs** en `r1_concepts/` (ver también `contact_sheet.html` con tests multi-size renderizados).
2. **Founder elige 2 conceptos** para R2 (default sugerido por Opus: C1 + C5; founder libre de elegir otro pair).
3. **Founder responde dudas R0** si no respondió antes (especialmente Q1 si la elección altera lectura "S").
4. **R2 entrega:** 2 conceptos refined + aplicados en favicon Chrome + app-icon Tablet + hero dark canvas + **hybrid white panel surface test** (brief §7 R2 row).
5. **R2 deadline sugerido:** 48h async post-elección founder (per brief §7).

---

**Fin rationale R1 — handoff a founder para selección 2/5 → R2 refinamiento.**
