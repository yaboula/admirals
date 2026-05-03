# SONAR — Specialist Briefs (v2 post-ADR-012)

Paquetes de encargo estructurados para roles creativos especializados (designers, sound designers, motion designers, marketing). Cada brief es **deliverable autocontenido**: contexto + specs + do/don't + referencias + licensing + review gates.

> **Versión carpeta:** v2 (2026-05-03 post-ADR-012 refinement). Briefs v1 (locked en metáfora literal-submarino-militar) descartados — ver `progress/SESSION_LOG.md` S1.5 entry.

**Origen:** Phase 4.5 v2 ADR-011 (rebrand foundational SONAR) + **ADR-012 (refinement: abstract metaphor + hybrid theme + neutral voice)**. Scaffold `01_art_direction.md` v2.0-scaffold-r6 NOTICE define el QUÉ canonical post-refinement; cada brief aquí define el CÓMO ejecutar para una especialidad.

**Precedencia jerárquica:**
1. ADR-012 (refinement amendment) — top.
2. ADR-011 (rebrand foundational).
3. `01_art_direction.md` v2.0-scaffold-r6 NOTICE.
4. `00_PRODUCT_BIBLE.md` v1.4 §1 identidad.
5. Estos briefs (deliverable operacional).

En cualquier conflicto, gana la fuente más alta de la jerarquía.

## Briefs disponibles (5/5 v2)

| ID | Brief | Status | Owner | Dependency |
|---|---|---|---|---|
| BRIEF-LOGO-001 v2 | [Logo SONAR](./01_brief_logo.md) | 🟡 Draft firmable | Designer TBD | — |
| BRIEF-ICONS-001 v2 | [Iconografía custom (8 abstract)](./02_brief_icons.md) | 🟡 Draft firmable | Designer TBD | LOGO R4 cerrado |
| BRIEF-SOUND-001 | [SFX firma (5 abstract)](./03_brief_sound.md) | 🟡 Draft firmable | Sound designer TBD | — |
| BRIEF-MOTION-001 | [Motion patterns](./04_brief_motion.md) | 🟡 Draft firmable | Motion designer TBD | LOGO + ICONS R3 cerrado |
| BRIEF-MARKETING-001 | [Marketing launch package](./05_brief_marketing.md) | 🟡 Draft firmable | Marketing director / copywriter TBD | LOGO R4 + ICONS R3 + voz samples |

## Lo que cambia en v2 vs v1 descartado

| Aspecto | v1 (descartado) | v2 (canonical post-ADR-012) |
|---|---|---|
| **Metáfora logo** | "S-como-onda sonar concéntrica" (radio/freq) | Exploración 4-5 conceptos abstract: descent-layers, prisma profundidad, gradient depth, geometric depth-grid, S-descending geometric |
| **Iconografía** | 8 literales: sonar-ping/submarine/depth-gauge/hydrophone/bioluminescence/pressure-hull/periscope/torpedo-bay | 3 conservados (depth-gauge + pressure-hull capas reconceptualizado + bioluminescence) + 5 abstract nuevos (descent-layers/signal-clarity/depth-grid/observation-field/lineage-trace) |
| **Sound names** | sonar_ping/pressure/depth/console/hatch | signal_emerge/depth_press/layer_dive/console_tap/panel_open |
| **Voz copy** | "Silent service capitán submarino nuclear" | Neutral premium-tech (Vercel/Linear/Stripe style) |
| **Theme** | Dark-extremo 60% canvas | Hybrid dark+white (~30-40% dark + ~30-40% white surfaces + ~10-15% Sonar Bright + ~10% structural + <5% signals) |

## Cómo usar un brief

1. **Founder review** — pre-kickoff checklist al final de cada brief.
2. **Asignar owner** — designer humano freelance, sound designer, motion designer, copywriter, o sesión Opus 4.7 MAX como ejecutor creativo.
3. **Kickoff R0** — moodboard alignment + dudas.
4. **Iteraciones R1-R3 (o R4)** — async + sync según brief.
5. **Delivery final** — package repo-ready + sign-off founder.
6. **Locked ✅** — brief archived, output integrado en `art/` repo.

## Changelog

| Fecha | Cambio |
|---|---|
| 2026-05-03 | v1 creación (logo + icons) — luego descartada post-ADR-012. |
| 2026-05-03 | **v2 creación completa: 5 briefs alineados ADR-012 (logo + icons + sound + motion + marketing).** |
