# Amendment — Custom logotype "SONAR" (post-founder feedback R1)

> **Origen:** founder feedback R1 (2026-05-03 chat) seleccionando estilo "chamfered geometric slab" basado en fotos de referencia.
> **Estado:** 🟡 Amendment propuesto — pendiente confirmación founder antes de propagarse a SSoT (`docs/art/01_art_direction.md` + `docs/design/00_PRODUCT_BIBLE.md`).
> **Aplica a:** BRIEF-LOGO-001 v2 §4.2 (typography wordmark) + `01_art_direction.md` v2.0-scaffold-r6 §3.3 + §4.

---

## 1. Contexto del amendment

El brief BRIEF-LOGO-001 v2 §4.2 establece:

> *"Familia: Geist Sans (Vercel — free, variable font, OFL 1.1 SIL). Peso base wordmark: SemiBold 600 o Bold 700 según proporción final. Tracking wordmark SONAR: tight (-2% a -4%) para compactness técnica."*

Founder R1 review (2026-05-03 chat) compartió foto de referencia del wordmark "SONAR" en estilo **chamfered geometric slab** — letras condensadas pesadas con esquinas biseladas a 45° en cada terminal y junction. Este estilo NO es Geist Sans:

- **Geist Sans** es un humanist geometric sans con curvas suaves, terminals rectos y NO chamfers.
- **El estilo de las fotos** es chamfered slab industrial — toda esquina cortada diagonalmente, weight muy pesado, condensado.

> **Tensión:** o se preserva Geist Sans para wordmark (brief inmutable per §10 founder pre-kickoff checklist) y se descartan las fotos del founder, o se permite una excepción del brief a favor del estilo del founder.

---

## 2. Resolución propuesta — práctica industria estándar

> **Decisión:** **custom logotype "SONAR" chamfered slab solo para LOGO institucional** + **Geist Sans preservado para todo el resto** (body, UI, headlines, dashboards, docs, marketing copy, code blocks).

### 2.1 Justificación: separación logotype vs typography

Esta separación **es práctica industria estándar premium-tech**:

| Marca | Custom logotype | Typography sistema (body/UI) |
|---|---|---|
| **Vercel** | Custom triangle + chamfered "Vercel" wordmark | Geist Sans (mismo Geist!) — for body, dashboards, docs |
| **Linear** | Custom "L" monogram + custom "Linear" wordmark | Inter (NOT same as wordmark) — for app/UI/docs |
| **Stripe** | Custom "Stripe" wordmark slab | Söhne — for body/dashboards |
| **Notion** | Custom "N" + custom "Notion" wordmark | Inter — for body/UI/docs |
| **Apple** | Custom Apple logotype | SF Pro — for everything else |
| **Figma** | Custom "Figma" wordmark + F monogram | Whyte — for UI |

**Patrón:** logotype = identity (custom, atemporal, distintivo). Typography sistema = funcionalidad (system font, legibility, multi-context). **NO son la misma cosa.**

### 2.2 Aplicación al ecosistema SONAR

**Custom logotype "SONAR" chamfered slab** se usa SOLO en:
- Logo institucional (lockup completo, monogram, wordmark standalone).
- Hero marketing (Tebex, web, trailer reveal, splash screens).
- Packaging / merchandise (si aplica).
- Watermarks de documentos legales / contratos firmados.
- App-icon Tablet (monogram).

**Geist Sans preservado canonical** para:
- Body text dashboards Tablet (per `01_art_direction.md` §4.1.1 + §4.2.1).
- Headers Tablet h1/h2 (display tokens — `display-xl/lg/md/sm`).
- Headlines website / docs (post `display-xl` 64px).
- UI controls + labels + buttons.
- Marketing copy (taglines, paragraphs, descripciones).
- Code blocks → Geist Mono.
- Audit trails, IBANs, batch IDs → Geist Mono.

**Inter Tight preservado canonical** para body/UI granular per `01_art_direction.md` §4.1.2 — sin cambios.

> **Net diff:** la única excepción del brief §4.2 es que el wordmark "SONAR" del logo institucional NO usa Geist Sans — usa logotype custom chamfered. Geist Sans sigue siendo SSoT para todo lo demás (≥95% del ecosistema visible).

### 2.3 Riesgo accepted

- 🟡 **Riesgo:** custom logotype = más coste production (refinement R3 letterforms + posiblemente commission designer humano para polish R3-R4).
- 🟢 **Mitigación R1b:** Opus 4.7 MAX entrega versión funcional pre-R3 (5 letterformas custom suficientes para evaluation R2). R3 polish puede ser AI iterativo o handoff a designer humano si founder lo prefiere.
- 🟢 **Beneficio:** distintividad mercado FiveM extrema. Logo institucional con custom logotype chamfered = nadie más en mercado lo tiene. Refs Vercel/Linear/Stripe class.

---

## 3. Cambios SSoT requeridos (post-confirmación founder)

### 3.1 `docs/art/briefs/01_brief_logo.md` v2 → v2.1 (surgical)

- **§4.2 Tipografía wordmark** rewrite:
  - Wordmark del logo institucional: **custom chamfered geometric slab** (no Geist Sans).
  - Geist Sans preservado para todo lo demás (referencia cruzada `01_art_direction.md` §4.1.1).
  - Custom logotype delivered en `art/branding/logo_v1/r1b_chamfered/wordmark_sonar.svg` (R1b iteration; R3 polish pending).

### 3.2 `docs/art/01_art_direction.md` v2.0-scaffold-r6 → r7 (surgical)

- **§3.3 Logo SONAR** add row:
  - "Wordmark logotype: **custom chamfered geometric slab** (NO Geist Sans). Aplica solo a logo institucional. Geist Sans preservado canonical para body/UI/headlines/docs/marketing per §4.1."
- **§4.1.1 Display Geist Sans**: add note:
  - "*Excepción:* wordmark logotype institucional usa custom chamfered slab (no Geist Sans). Ver `art/branding/logo_v1/`."

### 3.3 `docs/design/00_PRODUCT_BIBLE.md` v1.4 → v1.5 (surgical, §1)

- **§1 Identidad → row Tipografía** add:
  - "Logo wordmark: custom chamfered geometric slab (institucional). Geist Sans preservado para body/UI/dashboards/docs per `01_art_direction.md` §4."

### 3.4 New ADR (optional)

- Si founder considera la decisión foundational suficientemente impactante: open ADR-013 (Custom logotype + Geist Sans separation). Si no, surgical edits a SSoT bastan.

---

## 4. Lo que founder debe confirmar

Antes de R2 (refinement de C6 con color + favicon + hybrid theme tests), founder debe responder UNA de:

### 4.1 Opción A — Aprobar amendment (default sugerido)

> **Respuesta:** *"OK amendment custom logotype + Geist Sans body/UI"*

Resultado: R2 procede con C6a / C6b refinement. Post-LOGO R4 lock, surgical edits a SSoT propagated (brief v2.1 + art_direction r7 + bible v1.5).

### 4.2 Opción B — Rechazar amendment, preservar Geist Sans

> **Respuesta:** *"NO amendment, wordmark must be Geist Sans per brief §4.2"*

Resultado: R1b iteration discarded. R2 vuelve a candidates C1-C5 (R1 originales) o re-explora con Geist Sans wordmark + monograma chamfered standalone. C6 monogram (chamfered) puede preservarse pero wordmark debe ser Geist.

### 4.3 Opción C — Híbrido

> **Respuesta:** *"Amendment OK pero modificar wordmark X / Y / Z"*

E.g., founder podría querer:
- Solo monogram chamfered, wordmark Geist Sans (compromiso visual).
- Custom logotype con menos chamfers (sutil en lugar de chunky).
- Custom logotype solo para hero marketing, dashboards/UI mantienen Geist Sans wordmark visible.

R2 procede con la modificación específica.

---

## 5. Ejemplos comparativos (para founder visualizar)

**Geist Sans "SONAR" Bold (brief original §4.2):**
- Letras curvas suaves, sin chamfers, weight 700.
- Pro: brief compliance, font ya licenciada (OFL), legible UI.
- Con: NO matches founder feedback photo. Menos distintivo (Vercel ya lo usa idénticamente).

**Custom chamfered slab "SONAR" (este amendment):**
- Letras condensadas pesadas, chamfers 8px en cada esquina, weight extra-bold custom.
- Pro: matches founder feedback photo. Distintivo extremo. Coherente con monogram C6.
- Con: requiere refinement R3, no licenciable como font para body usage (solo logo).

**Render comparativo en `contact_sheet_v2.html`** — abrir y comparar lado a lado.

---

## 6. Changelog amendment

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| v1.0 | 2026-05-03 | Cascade Opus 4.7 MAX | Initial amendment proposal — custom logotype "SONAR" chamfered slab + Geist Sans preservado UI/body. Triggered by founder photo feedback R1. |

---

**Fin amendment — esperando founder approval/reject/modify para propagar a SSoT.**
