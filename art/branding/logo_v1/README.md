# SONAR Logo — Design Package v1 (BRIEF-LOGO-001 v2)

> **Brief:** `docs/art/briefs/01_brief_logo.md` v2 (BRIEF-LOGO-001 v2 post-ADR-012)
> **Estado actual:** R0 Kickoff + R1 Conceptos + **R1b Chamfered direction (post-founder feedback)** delivered. Pendiente founder approval (Opción A/B/C en `r1b_chamfered/contact_sheet_v2.html` decision block) → R2.
> **Designer:** Opus 4.7 MAX (AI executor path §9 brief).
> **Founder reviewer:** yaboula (final sign-off R4).
> **Fecha entrega R0+R1+R1b:** 2026-05-03.
> **Repo destino final lock R4:** `art/branding/logo_v1/` (este folder) + normativa en `docs/art/branding/`.

> **🔄 Update 2026-05-03 (R1b):** founder revisó R1 + compartió fotos referencia (chat 19:11) seleccionando estilo "chamfered geometric slab" como dirección base. **C6 (chamfered) reemplaza C1-C5 como dirección canonical**. Bug rendering v1 (`<object>` no carga en file://) corregido en ambos contact sheets (v1 y v2 ahora usan `<img>`). Amendment custom logotype + Geist Sans preservado UI/body documentado en `r1b_chamfered/amendment_logotype.md` esperando aprobación founder.

---

## Estructura del paquete

```
art/branding/logo_v1/
├── README.md                          ← este archivo (handoff founder)
├── r0_kickoff/                        ← R0 Kickoff deliverables
│   ├── moodboard.md                   ← Moodboard 4-columnas (Formal / Profundidad abstracta / Hybrid theme / Anti)
│   └── cuestionario_founder.md        ← 10 preguntas bloqueantes con defaults razonados
├── r1_concepts/                       ← R1 Conceptos originales (pre-founder feedback)
│   ├── c1_descent_layers.svg          ← Concept C1 — 4 bandas horizontales zigzag offset
│   ├── c2_prisma_profundidad.svg      ← Concept C2 — S con extrusión isométrica minimal
│   ├── c3_gradient_depth.svg          ← Concept C3 — S con gradient lineal vertical
│   ├── c4_geometric_depth_grid.svg    ← Concept C4 — S filled con horizontal contour lines
│   ├── c5_geometric_s_descent.svg     ← Concept C5 — S con curvas top/bottom weight-differentiated
│   ├── rationale.md                   ← Rationale 1-pager por concepto + recomendación inicial
│   └── contact_sheet.html             ← v1 contact sheet (BUG FIXED: object→img, ahora renderiza)
└── r1b_chamfered/                     ← 🌟 R1b Chamfered direction (POST-FOUNDER FEEDBACK)
    ├── c6a_monogram_solid.svg         ← C6a — solid filled chamfered S letterform (12 corners)
    ├── c6b_monogram_petals.svg        ← C6b — outlined chamfered petals (más fiel foto founder)
    ├── wordmark_sonar.svg             ← Wordmark "SONAR" custom chamfered slab (5 letterforms)
    ├── lockup_horizontal.svg          ← Lockup H: monogram + wordmark (gap 0.5× letter)
    ├── lockup_vertical.svg            ← Lockup V: monogram top + wordmark bottom (gap 0.3×)
    ├── construction_diagram.svg       ← Modular grid 16×16 + chamfer specs + clear-space
    ├── amendment_logotype.md          ← Amendment doc: custom logotype + Geist Sans preservado UI
    └── contact_sheet_v2.html          ← 🌟 Contact sheet canonical post-feedback (decision block)
```

---

## Estado del brief — qué está hecho

| Ronda | Brief §7 deliverable | Status | Path |
|---|---|---|---|
| **R0 Kickoff** | Moodboard PDF + cuestionario dudas | ✅ delivered | `r0_kickoff/moodboard.md` + `r0_kickoff/cuestionario_founder.md` |
| **R1 Conceptos** | 4-5 direcciones monograma thumbnails B&W | ✅ delivered (5/5 candidatos cubiertos) | `r1_concepts/c1..c5_*.svg` + `rationale.md` + `contact_sheet.html` |
| **R1b Chamfered direction** | C6 monogram (a/b) + wordmark + lockups + construction (post-founder feedback 2026-05-03) | ✅ delivered | `r1b_chamfered/*` |
| **R2 Refinamiento** | C6a/b refined + color real + favicon ICO + app-icon Tablet + hybrid theme white panel test | 🟡 pending founder approval (Opción A/B/C) | TBD post-approval |
| **R3 Sistema completo** | Logo final + lockups refined + reverse + glow + guidelines PDF draft | 🟡 pending R2 | TBD |
| **R4 Delivery** | Package completo repo-ready + source files + guidelines PDF final | 🟡 pending R3 | TBD |

**Notas formato:**
- Moodboard se entrega en **markdown** en lugar de PDF — el contenido es identical (refs + 4 columnas + tesis), formato docs-friendly + version-controlled. Si founder requiere PDF físico para impresión/handoff externo, se puede generar export desde markdown trivialmente (e.g. `pandoc moodboard.md -o moodboard.pdf`).
- `contact_sheet_v2.html` reemplaza render-en-PDF — abrir en browser para tests live multi-size, hybrid theme dark+white parity, lockups, construction diagram. Más útil que un PDF estático.

**Bug fix v1→v2 (2026-05-03):**
- v1 contact sheet usaba `<object data="...svg">` que falla en file:// por restricciones CORS (esto causaba el error "This page contains the error..." que founder vio).
- v2 contact sheet (y v1 retroactivamente) ahora usa `<img src="...svg">` que funciona en file:// sin issues.
- Validado: ambos contact sheets renderizan correctamente al abrir directamente en browser.

---

## Cómo revisar (founder yaboula)

### Paso 1 — Abre el contact sheet v2 (3-5 min)

Abre **`r1b_chamfered/contact_sheet_v2.html`** en tu browser (Chrome/Arc/Firefox). Verás:

1. **C6a + C6b monograms** — solid letterform vs outlined petals — comparados side-by-side.
2. **Multi-size validation** — 256/128/64/32/24/16 px × dark + light canvas (hybrid theme ADR-012 D2).
3. **Wordmark "SONAR"** custom chamfered slab — 5 letterforms (S/O/N/A/R) en native + scaled.
4. **Lockups** horizontal + vertical en hybrid theme.
5. **Construction diagram** — modular grid 16×16, chamfer 8px @ 45°, clear-space ≥ 112px.
6. **Reference C1-C5** preservados (de-emphasized) al final para historial.
7. **Decision block** — Opción A/B/C para founder.

### Paso 2 — Lee el amendment doc (8-10 min)

Abre **`r1b_chamfered/amendment_logotype.md`**. Encontrarás:

- Por qué el wordmark del founder NO es Geist Sans (no tiene chamfers nativos).
- Resolución industria-estándar: custom logotype institucional + Geist Sans preservado UI/body.
- Refs Vercel/Linear/Stripe/Apple/Notion/Figma todos siguen este patrón.
- Cambios SSoT requeridos (`brief §4.2 → v2.1`, `art_direction r6 → r7`, `bible v1.4 → v1.5`) post-approval.
- 3 opciones founder (A approve / B reject / C híbrido).

### Paso 3 — Responde decisión (2 min)

Tres formas equivalentes:

- **Confirmación rápida:** responder `OK C6a + amendment` (recomendado) o `OK C6b + amendment` o `Modificar: ...`.
- **Edit cuestionario R0:** abre `r0_kickoff/cuestionario_founder.md` y marca tus preferencias.
- **Inline annotations:** comentarios directos sobre los SVG/HTML en chat next session.

### Paso 4 — Próxima ronda (R2) tras tu approval

Una vez recibida tu decisión, R2 entregará en ~48h async (per brief §7):

1. **Polish C6a o C6b refinement** según elección.
2. **Color real**: Sonar Bright `#2DD4BF` sobre Abyss `#03070A` (canonical primary A) + sobre Crew 100 `#F0F4F4` (canonical primary B con shifted `#1FB39E` si AA falla).
3. **Aplicaciones reales**:
   - Favicon Chrome tab (16px + 32px ICO multi-density).
   - App-icon Tablet (88px rounded square sobre Abyss canvas — per Q4 default).
   - Tebex hero 1920×1080 mock con glow signature opcional.
   - **White panel surface test** (hybrid theme requirement crítico ADR-012 D2).
4. **Construction diagram refined** — wordmark letterforms también con grid documentation.
5. **Rationale R2** explicando refinements + decisiones color shift.
6. **(Si amendment approved)** — surgical edits propagados a SSoT (`brief v2.1` + `art_direction r7` + `bible v1.5`) post-LOGO R4 lock.

### Reference: cómo revisar las exploraciones originales C1-C5 (opcional)

Si quieres ver los 5 candidates originales pre-feedback (preserved como historial):
- `r1_concepts/contact_sheet.html` — bug FIXED, ahora renderiza correctamente.
- `r1_concepts/rationale.md` — rationale R1 1-pager por C1-C5.

Estos son referencia histórica; la dirección activa post-feedback es C6 (chamfered).

---

## Anti-patterns guardrail (todos los conceptos pasan ✅)

Todos los 5 conceptos R1 fueron auto-checked contra anti-patterns explícitos brief §5.2 + ADR-012 D1:

- ✅ NO concentric waves / sonar ping radio-freq.
- ✅ NO submarine silhouette literal.
- ✅ NO periscope / hydrophone / torpedo / anchor / wheel / compass / hatches / casco-remaches.
- ✅ NO eye-with-rays "ver escuchando" literal.
- ✅ NO cyberpunk neón / military tacticool / gaming RGB / cartoon mascot / vintage retro.
- ✅ NO gradient holográfico mercurio rainbow (C3 es pure 2-stop tonal Sonar Bright→Sonar Pulse).
- ✅ NO bevel / emboss / drop-shadow gamer / outline stroke decorative.
- ✅ Coloro Support `#175A5F` NO usado en logo (Tier C, prohibido brief §2.2).

> **Excepción supervisada:** C2 isometric extrusion (10px offset solid same-shape) NO es bevel/emboss/drop-shadow blur. Pero requiere supervisión R2 pixel-perfect para no degenerar visual.

---

## Decisión sin fricción founder (R1b post-feedback)

> **A · Aprobar C6a + amendment (RECOMENDADO):** responde `OK C6a + amendment`. R2 procede con C6a (solid chamfered letterform) + custom logotype + Geist Sans preservado UI/body. Mejor favicon @16px, coherence sistema máxima.

> **B · C6b outlined petals + amendment:** responde `OK C6b + amendment`. R2 procede con C6b (outlined petals — más fiel a tu foto monogram). Mayor distintividad, ligeramente mayor riesgo favicon @16px.

> **C · Híbrido / modificar:** responde `Modificar: ...` con qué quieres ajustar. E.g.: monogram chamfered pero wordmark Geist Sans (rechazar amendment), chamfers más pequeños/grandes, weight más ligero, etc.

> **Reject completo:** si la dirección chamfered no te convence post-renderizado, responde `Volver a C1-C5` y revisamos pair de los 5 originales para R2.

---

## Compliance brief §7 R1 + R1b rows

### R1 (originales pre-feedback)

- [x] **Deliverable:** 4-5 direcciones monograma thumbnails B&W (delivered: 5/5).
- [x] **Cobertura candidatos preliminares §3.1:** ≥3 (delivered: 5/5 = todos los candidates preliminares brief §3.1).
- [x] **Bug fix retroactivo:** `<object>` → `<img>` en contact sheet v1.

### R1b (post-feedback chamfered direction)

- [x] **Founder feedback ingested:** fotos de referencia interpretadas + estilo "chamfered geometric slab" adoptado como base.
- [x] **C6 entregado:** dual variant (C6a solid + C6b outlined) cubriendo dos interpretaciones del feedback.
- [x] **Wordmark custom delivered:** "SONAR" 5 letterforms chamfered slab (~100 vertices total, modular grid 16×16).
- [x] **Lockups delivered:** horizontal + vertical per brief §4.4 spec.
- [x] **Construction diagram delivered:** modular grid + chamfer specs + clear-space documentation.
- [x] **Amendment doc delivered:** custom logotype + Geist Sans preservado UI rationale.
- [x] **Multi-size validation:** 256/128/64/32/24/16 px × dark + light canvas (hybrid theme ADR-012 D2).
- [x] **Anti-patterns auto-check:** ✅ NO concentric waves, NO submarino, NO compass, NO bevel/emboss, NO gradient holográfico, NO Coloro `#175A5F` en logo.

---

## Compliance ADR-012 + r6 NOTICE

- [x] **Metáfora abstracta pura, NO submarino militar literal** (ADR-012 D1).
- [x] **Hybrid theme aware** — todos conceptos validados sobre Abyss + Crew 100 (ADR-012 D2).
- [x] **Voz neutral premium-tech** — todos los textos rationale/moodboard/cuestionario son neutros (Vercel/Linear/Stripe class), cero arquetipo militar (ADR-012 D3).
- [x] **Anti-patterns ondas concéntricas + submarino literal** explícitamente verificados (ADR-012 D1).

---

**Fin handoff R0+R1 — esperando founder selection 2/5 para iniciar R2.**
