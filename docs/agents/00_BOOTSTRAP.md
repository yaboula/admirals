# 🤖 SONAR — AI Agent Bootstrap (READ THIS FIRST)

> **Versión:** 1.6 (firmado — living document). **PIVOT IDENTITY Admirals → SONAR** (2026-05-03): ADR-011 + ADR-012 + **ADR-013/014/015** (`planning/02_decision_log.md` v1.5) + **ADR-016** (`planning/02_decision_log_part2.md` v1.0) accepted. **Identity v3 lock post-ADR-016**: palette 3-color canonical `--sonar-black`/`--sonar-orange`/`--sonar-white` + dark-only doctrine + Tablet UI stack FROZEN S2-S8. SSoTs: Bible **v1.5** + art_direction **v3.0-locked** + brief_logo **v3** + `02_decision_log_part2.md` v1.0. B1 Phase 6 mass-purge 8/8 ✅ CERRADO. Sprint 1 cerrado (sprint-1-complete tag).
> **Tipo:** Documento meta-organizacional. **Este es el primer fichero que debe leer cualquier AI agent que trabaje en el proyecto SONAR (ex-Admirals).**
> **Audiencia:** AI agents (Cascade, Claude, GPT, otros). También útil para humanos onboarding.
> **Estado:** firmado (living document — actualizar al firmar cada nuevo doc).

> ⚠️ **STOP.** Si eres un AI y acabas de unirte a este proyecto: **NO empieces a escribir código ni docs todavía**. Lee este fichero entero primero. Luego sigue el reading order de §3 — **OBLIGATORIO ADR-011 + ADR-012 + ADR-016 (`docs/planning/02_decision_log_part2.md` v1.0) + art_direction v3.0-locked IDENTITY V3 LOCK NOTICE + Bible v1.5 §1** ANTES de cualquier work post-2026-05-04. Sin esos 5, riesgo alto re-confundir identity deprecated.

---

## 0. Por qué existe este documento

> **El proyecto SONAR (ex-Admirals) tiene 27.260+ líneas de documentación profesional firmada + 1.500+ líneas briefs v2 specialist deliverables.** Sin este fichero, un AI agent nuevo se ahoga en el mar de docs y pierde días reorientándose. **Adicionalmente post-2026-05-03 pivot identity (ADR-011 + ADR-012):** sin onboarding correcto AI agent puede re-confundir metáfora literal-militar deprecated y romper coherencia visual/voice canonical hybrid-theme + neutral premium-tech.

Este BOOTSTRAP es la **única fuente de verdad** sobre:

- **Qué es SONAR (ex-Admirals)** (resumen 1-página + identity post-pivot).
- **Estado actual del proyecto** (dónde estamos).
- **Cómo está organizada la documentación** (mapa completo).
- **Orden de lectura recomendado** (no leer todo, leer lo correcto).
- **Principios de trabajo** (quality bar + estilo + ética).
- **Qué decide el AI vs qué decide el founder** (escalation matrix).
- **Anti-patterns** (errores comunes que cometen los AI).
- **Common workflows** (firmar doc, validar números, añadir feature).

**Sin esto, cada nueva sesión AI empieza desde 0.** Con esto, la cadena de trabajo NO se rompe.

---

## 1. Qué es SONAR (1 página) — ex-Admirals post-pivot 2026-05-03

> **Identity status:** marca **SONAR** (ADR-011 + ADR-012). Heritage Admirals deprecated en NEW work. Code namespace `admirals_*` pendiente Phase 8 refactor.

### 1.1 El producto

**SONAR** es un servidor FiveM de roleplay con una mecánica core única: **economía profunda con cadenas de producción reales**.

- No es un script genérico de RP.
- No es shooter PvP.
- Es un **simulador económico multiplayer** donde el player es **literalmente** un panadero, granjero, cajero, manager — porque amasa, hornea, vende, y los números reales suben.

### 1.2 Los 4 pilares

1. **Cadenas de producción físicas** — Granja → Molino → Bakery → Retail. Cada nodo es trabajo real, ítems físicos con quality A/B/C/D y lineage trazable.
2. **Banca SONAR** (code namespace `admirals_bank` hasta Phase 8 refactor) — IBANs reales, escrows, tax retention 8%, ledger inmutable. Sin "economía mágica".
3. **Tablet (HUD operacional)** — 12 apps que el player abre con `TAB`. UI principal del producto.
4. **Empresas player-driven** — founders, co-founders, employees, contracts B2B, governance.

### 1.3 Principios irreductibles (gameplay/economía — pivot-agnostic)

- **Trabajo real, no skill check.** No QTEs, no minigames abstractos.
- **Economía es social.** Lineage chains requieren múltiples players cooperando.
- **No PvP combat.** Disputas → governance, no violence.
- **No pay-to-win.** No microtransactions que afecten balance.
- **Cap superior generoso, no infinito.** Mastery alcanzable en 100-300h.

### 1.3.1 Identity hard rules (post-ADR-012 — NEW work obligatorio)

> Detalle completo en §5.5 + memoria persistente `SONAR Identity Direction r2`.

- **Metáfora abstract pure.** Profundidad simbólica, exploración paciente, claridad bajo presión. **NO submarino militar literal**, NO radios/freq, NO periscopio/torpedo/hydrophone/sonar-ping concentric.
- **Dark-only doctrine v3 (post-ADR-016 D2).** 100% dark canvas `--sonar-black` `#060607` + `--sonar-orange` `#FF5100` brand signal + `--sonar-white` `#FAFAFA` foreground. **DEPRECATED v1.4 hybrid dark+white** surfaces + Sonar Bright teal product surfaces.
- **Voz neutral premium-tech.** Estilo Vercel/Linear/Stripe/Apple Pro apps copy. **NO arquetipo militar**: cero "silent service", cero "capitán", cero "a bordo", cero "tactical".
- **3-color canonical (post-ADR-016 D1):** `--sonar-black` `#060607` + `--sonar-orange` `#FF5100` + `--sonar-white` `#FAFAFA`. SSoT `docs/art/branding/01_brief_logo.md` v3 §4.1. DEPRECATED Sonar Bright `#2DD4BF` / Coloro `#175A5F` en product UI.
- **Sound naming canonical**: `signal_emerge`/`depth_press`/`layer_dive`/`console_tap`/`panel_open`. NO `sonar_ping/pressure/depth/console/hatch` (deprecated).

### 1.4 Stack técnico

- **Plataforma:** FiveM (servidor GTA V multiplayer).
- **Lenguajes:** Lua (server scripts), JS/TS + React (Tablet UI), SQL (MySQL/MariaDB).
- **Framework:** **QBox primary, QBCore compat, ESX limited** (decisión cerrada). Compatibilidad cross-framework vía **Bridges layer** (`technical/07_bridges_compatibility.md`).
- **Renderizado UI:** NUI (Chromium embebido FiveM) para Tablet.
- **Sync:** State Bags + events FiveM nativos.
- **Compat scripts custom:** vía Bridges adapters (lb-phone, qs-inventory, ox_inventory, custom banks tipo Renewed-Banking, etc.). Customer puede escribir su propio adapter siguiendo SDK.

> Para el detalle técnico completo, ver `technical/01_architecture.md`.

---

## 2. Estado actual del proyecto

### 2.1 Fase actual

**Fase: 🏆 SPRINT 1 CERRADO (2026-05-02) + 🔄 PIVOT IDENTITY Admirals→SONAR EN EJECUCIÓN MULTI-PHASE (2026-05-03 ongoing). Sprint 2 diferido hasta Phase 10 smoke regression complete.**

#### 2.1.1 Pivot identity status (NEW v1.5)

- **Phase 1 ADR-011** (rebrand foundational Admirals→SONAR) ✅ accepted 2026-05-03.
- **Phase 1.5 ADR-012** (refinement: abstract metaphor + hybrid theme + neutral voice, AMENDS no supersede) ✅ accepted 2026-05-03.
- **Phase 2-4 art_direction scaffold + r6 NOTICE** ✅ commits `6d3d96c`…`d0712cc`…`27de1b6`.
- **Phase 5 light Bible v1.3 + v1.4** ✅ commits `b480af5` + `7cf29f0`.
- **Phase 4.5 v2 specialist briefs (5/5)** ✅ commit `5838a79` — logo + icons + sound + motion + marketing alineados ADR-012.
- **Phase 4 surgical full §1-§20 art_direction inline** 🟡 pendiente (NOTICE r6 supersedes pero contenido inline sigue v1.0-r5).
- **Phase 5 full Tablet rename + rewrite** 🟡 pendiente.
- **Phase 6 B1 mass-purge docs operacionales** ✅ CERRADO 8/8 (100%) — Tablet v1.2 + events v1.1 + db_schema v1.1 + api_contracts v1.1 + state_machines v1.1 + fivem_standards v1.1 + bridges_compat v1.1 + roadmap v1.5. Phase 6 B2 (art/02-04 inline surgical) 🔴 pendiente.
- **Phase 8 code refactor `admirals_*` → `sonar_*` namespace** ✅ DONE — `sonar_bridges` + `sonar_bank` + `sonar_core` + fxmanifest + exports + event prefixes renamed.
- **Phase 9 DB migration 009** (`009_rename_admirals_to_sonar.sql`) ✅ DONE — 6 tablas + FKs + índices renamed `sonar_*`.
- **Phase 10 smoke regression** ✅ DONE — 30/30 cumulative S0+S1 pass post-Phase-8+9.
- **Phase 11 workspace migration** 🔴 pendiente.

#### 2.1.2 Sprint 1 cerrado (preserved historical)

- **Oleada 0 docs:** 29/29 firmados (~27.260 líneas).
- **Sprint 0:** cerrado con `git tag v0.0.0`. `admirals_bridges` v0.2.0 + `admirals_core` v0.1.0 + migrations 001/002 + ADR-010.
- **Sprint 1 (Oleada 1):** 3 sessions (S1.1, S1.2, S1.3), cerrado con `git tag sprint-1-complete`. Deliverables:
  - `admirals_bank` v0.4.0 — IBAN generator (`AD-XXXX-XXXX-XXXX` checksum) + Accounts + Movements (double-entry) + Transfer atomic + Events schema v1 + Escrow FSM (5 estados) + Callbacks C001 getBalance, C002 transfer, C004 createEscrow, C005 releaseEscrow.
  - `admirals_core` v0.4.2 — +6 migrations (003 bank_schema, 004 system treasury seed `AD-SYS0-0000-0001` 10M€, 005 balance NON-NEG CHECK, 006 escrow_schema, 007 FK fix transitional, 008 FK revert canonical a bank_accounts).
  - `admirals_bridges` — idempotency promoted memoria → DB-backed (`admirals_bridge_idempotency` table).
  - FSM `escrow_lifecycle` per `05_state_machines.md` §4.1 (transitions whitelist + guards + FSM_INVALID_TRANSITION).
  - Rate limiter `bank.write` 10/60s operativo.
  - Smoke tests: S1.1 (6/6) + S1.2 (10/10) + S1.3 (14/14) = **30/30 ✅ cumulative**.
  - Retro: `progress/SPRINT_RETRO_S1.md`. Velocity real 15× (1 día vs 2 semanas estimado).

**Next: Sprint 2 DIFERIDO** — Tablet shell + Bank app dependen Phase 10 smoke regression complete (post pivot Phases 4-12). Originalmente Tablet shell + Bank app (NUI React + keybind TAB + Bank UI balance/transactions/transfer + Map app GPS). Planning session dedicada pendiente post-pivot complete.

### 2.2 Inventario de documentación firmada

| Categoría | Docs firmados | Líneas | Estado |
|---|---|---|---|
| `design/` | 6 (00_PRODUCT_BIBLE **v1.5 post-ADR-016**, 01-05 nodos, 06_tablet_app_suite; sonar_tablet **v1.3** IDENTITY V3 LOCK NOTICE) | ~5.500 | ✅ CERRADA (refresh v1.5) |
| `technical/` foundational | 3 (architecture, events_catalog, db_schema) | ~3.200 | ✅ CERRADA (Phase 6 mass-purge pendiente) |
| `art/` | 4 (01_art_direction **v3.0-locked IDENTITY V3 LOCK NOTICE post-ADR-016**, 02-04; brief_logo **v3** SSoT canonical palette) | ~3.800 + scaffold | ✅ CERRADA (refresh v3.0-locked; §1-§20 Phase 4 surgical full pendiente) |
| `art/briefs/` | 6 (README + 5 specialist briefs v2: logo + icons + sound + motion + marketing) | ~1.500 | 🏆 NEW v1.5 firmable |
| `economy/` | 3 | ~2.600 | ✅ CERRADA (Phase 6 pendiente) |
| `gameplay/` | 3 | ~2.700 | ✅ CERRADA (Phase 5 full pendiente) |
| `agents/` | 3 (00_BOOTSTRAP **v1.6 post-ADR-016**, 02_working_conventions; 01_subagents_catalog archivado) | ~2.000 | ✅ CERRADA |
| `planning/` | 3 (01_roadmap v1.5, 02_decision_log **v1.5 15 ADRs** ADR-001–015, **02_decision_log_part2.md v1.0** ADR-016) | ~3.100+ | ✅ CERRADA |
| `technical/` implementation | 4 / 4 (api_contracts, state_machines, fivem_standards, bridges_compatibility v1.0) | ~3.700 | ✅ CERRADA (Phase 6 pendiente) |
| `qa/` | 1 (testing_protocol) | ~760 | ✅ CERRADA |
| `_archive/` | 1 (01_art_direction_v1_admirals.md — deprecated v1.0 preserved per ADR-011) | ~2.700 | 📖 ARCHIVE NO TOCAR |

**Total firmado:** 29 + briefs v2 (5) / ~28.760 líneas. **Pendiente:** 0 docs nuevos firmables. 🏆 **OLEADA 0 COMPLETA. PIVOT EN EJECUCIÓN MULTI-PHASE.**

### 2.3 Qué hay pendiente para empezar a programar

> **Roadmap docs hasta "ready to code":**

1. ✅ BOOTSTRAP (este) v1.2.
2. ✅ `planning/01_roadmap.md` v1.1 (Granja MVP pivot).
3. ✅ `agents/01_subagents_catalog.md` (archivado per ADR-001).
4. ✅ `agents/02_working_conventions.md`.
5. ✅ `planning/02_decision_log.md` v1.1 (9 ADRs: 001-009).
6. ✅ `technical/04_api_contracts.md`.
7. ✅ `technical/05_state_machines.md`.
8. ✅ `technical/06_fivem_standards.md` (consolidado realtime + security + perf).
9. ✅ `qa/01_testing_protocol.md` (FiveM live testing protocol).
10. ✅ **`technical/07_bridges_compatibility.md` v1.0** (Bridges Layer + 6 bridges + tier system + SDK).

**Pendiente: 0 docs.** 🏆 **READY TO CODE.**

### 2.4 Equipo

- **Founder:** 1 persona, technical-leaning, prefiere comunicación directa, valora estructura profesional.
- **AI agent:** se ha usado Cascade. Otros agents pueden continuar.
- **Devs/Artistas/Otros:** aún no contratados. Estos docs son el "package onboarding" para cuando lleguen.

### 2.5 MVP Oleada 1 — Granja (pivot v1.1)

> **MVP node = Granja (NO Bakery).** Pivot per roadmap v1.1 (2026-05-01).

**Justificación:**
- Granja es **nodo raíz cross-vertical** (Product Bible §13.4) — todas las cadenas empiezan aquí.
- Sistema calidad (soil/irrigation/fertilization/pest/weather scores) es más natural en Granja.
- Ritmo passive timer-based (crops 7 días) reduce carga compute server vs minigames activos Bakery.
- Oleada 2 construye Molino → Bakery → Retail **sobre wheat real producido por players**, no NPC stubs.
- `design/01_node_farm.md` v1.1 es el doc nodo más maduro (~1500 líneas).

**Sprints clave Oleada 1 (ver `planning/01_roadmap.md` §4.2):**
- S0: Setup + Bridges skeleton
- S1-S2: Banco + Tablet shell
- S3: Item físico + quality + lineage origin
- S4: Granja NPC mecánicas (plot/plant/irrigate/harvest/wheat)
- S5: Empresa + salaries
- S6: Workplace app
- S7: Granja player-foundable + sell wheat NPC Mill
- S8: Polish + closed beta

---

## 3. Orden de lectura recomendado para AI agents

> **NO leas todo en orden numérico.** Sigue este orden por importancia + contexto.

### 3.1 Round 1 — Identidad y meta (obligatorio antes de cualquier acción)

| # | Doc | Tiempo lectura | Por qué |
|---|---|---|---|
| 1 | `agents/00_BOOTSTRAP.md` v1.6 | 20min | **Este fichero.** Identidad post-pivot + estado proyecto + ADR-016 identity v3 lock. |
| 2 | **`planning/02_decision_log.md` ADR-011 + ADR-012 + ADR-013/014/015 + `02_decision_log_part2.md` v1.0 ADR-016** | 20min | **CRÍTICO post-2026-05-04 — pivot identity + refinement + namespace migration + UI pivot + identity v3 lock.** Sin esto AI re-confunde identity deprecated. |
| 3 | **`art/01_art_direction.md` v3.0-locked IDENTITY V3 LOCK NOTICE** (top-level NOTICE solo, NO leer §1-§20 todavía hasta Phase 4 surgical full) | 15min | **CRÍTICO** — canonical visual direction post-ADR-016: 3-color strict + dark-only doctrine + Tablet stack frozen. NOTICE supersedes §1-§20 inline en cualquier conflicto. |
| 4 | **`design/00_PRODUCT_BIBLE.md` v1.5 §1 identidad** | 10min | **CRÍTICO** — voz + posicionamiento canonical post-ADR-016: palette 3-color strict + dark-only + Tablet stack row. |
| 5 | `agents/02_working_conventions.md` | 10min | Cómo interactuar con founder. |
| 6 | `planning/01_roadmap.md` v1.4 | 10min | Qué se construye cuándo (Granja MVP + pivot phases pendientes). |
| 7 | `design/00_PRODUCT_BIBLE.md` v1.5 §2-§16 (resto Bible) | 30min | Filosofía completa del producto (preserved gameplay/economía/técnico/comercial pivot-agnostic). |

**Total Round 1: ~110 min.** Después de esto el AI **entiende el proyecto post-pivot**.

**⚠️ NO LEER:**
- `docs/_archive/01_art_direction_v1_admirals.md` (deprecated v1.0 — confunde con identity vieja).
- `docs/art/01_art_direction.md` §1-§20 inline sin haber leído NOTICE r6 antes (riesgo confusión con scaffold-r1..r5 legacy hasta Phase 4 surgical full).
- Briefs v1 (eliminados) — ya no existen, NO buscar.

### 3.2 Round 2 — Foundational technical (si tarea técnica)

> **Nota post-pivot:** estos docs siguen válidos foundational, pero contienen refs `admirals_*` que serán purged Phase 6 + 8 + 9. AI debe distinguir: code refactor activo (Phase 8) vs nuevo código nuevo (debe usar `sonar_*` directamente desde S2 post-pivot complete).

| # | Doc | Por qué |
|---|---|---|
| 1 | `technical/01_architecture.md` | Cómo está estructurado el sistema. |
| 2 | `technical/02_events_catalog.md` | Catálogo eventos sistema (cliente↔server). 333 refs `admirals:*` Phase 6 mass-purge pendiente. |
| 3 | `technical/03_db_schema.md` | Esquema base de datos. 463 refs `admirals_*` Phase 6 + Phase 9 migration 009 pendientes. |
| 4 | `technical/04_api_contracts.md` | Callbacks, exports, NUI bridges, DB access. |
| 5 | `technical/05_state_machines.md` | FSMs (status columnas DB). |
| 6 | `technical/06_fivem_standards.md` | Reglas FiveM (State Bags, resmon, security). |
| 7 | `technical/07_bridges_compatibility.md` | Compat layer multi-framework + custom scripts. |
| 8 | `qa/01_testing_protocol.md` | Smoke + integration + release gates. |

### 3.3 Round 3 — Specific to task

> **Lee solo los docs relevantes a tu tarea actual.**

| Si tarea es… | Lee… |
|---|---|
| Mecánica de un nodo | `design/0X_node_*.md` correspondiente |
| Economía / pricing / balance | `economy/01_economic_model.md` + `economy/02_bakery_economy.md` o `03_retail_economy.md` |
| UI Tablet / HUD | `design/06_tablet_app_suite.md` + `art/04_storybook_guide.md` (Phase 5 full pendiente: rename `02_admirals_tablet.md`→`02_sonar_tablet.md`) |
| Audio | `art/03_sound_bible.md` (legacy refs `sonar_ping/etc` deprecated; ver `art/briefs/03_brief_sound.md` v1 para nombres canonical post-ADR-012) |
| Estilo visual / branding / iconografía / motion | **`art/01_art_direction.md` v2.0-scaffold-r6 NOTICE OBLIGATORIO PRIMERO** + briefs v2 específicos en `art/briefs/` + `art/02_shader_contracts.md` |
| Gameplay loops / onboarding | `gameplay/01_gameplay_loops.md` |
| Progresión / achievements | `gameplay/02_progression_systems.md` |
| Empresa / chat / disputas | `gameplay/03_social_features.md` |
| API endpoints | `technical/04_api_contracts.md` |
| Estados / FSM | `technical/05_state_machines.md` |
| Specialist creative deliverable (logo/icons/sound/motion/marketing) | `art/briefs/0X_brief_*.md` v2 correspondiente + ADR-012 + r6 NOTICE |

### 3.4 Anti-pattern: leer TODO

❌ **No intentes leer las 17.800 líneas en una sesión.** Es ineficiente y lleva a context overload. Usa el orden anterior.

✅ **Usa búsqueda direccional:** si necesitas algo específico, `grep`/`find` antes de leer.

---

## 4. Mapa completo de documentación

```
docs/
├── 00_PRODUCT_BIBLE.md          ⭐ La biblia. Filosofía + 4 pilares.
│
├── _archive/                      📖 ARCHIVE NO TOCAR (preserved per ADR-011)
│   └── 01_art_direction_v1_admirals.md  Deprecated v1.0 Admirals (preserved trazabilidad)
│
├── art/briefs/                    🎨 NEW v1.5 — Specialist deliverables v2 post-ADR-012
│   ├── README.md                  Index + status table 5/5 + v1→v2 diff
│   ├── 01_brief_logo.md           BRIEF-LOGO-001 v2 (concept exploration NO ondas concéntricas)
│   ├── 02_brief_icons.md          BRIEF-ICONS-001 v2 (3 conservados + 5 abstract nuevos)
│   ├── 03_brief_sound.md          BRIEF-SOUND-001 v1 (5 SFX neutral signal_emerge etc)
│   ├── 04_brief_motion.md         BRIEF-MOTION-001 v1 (12 tokens + 5 signature animations)
│   └── 05_brief_marketing.md      BRIEF-MARKETING-001 v1 (voz neutral + Tebex + trailer + moodboard)
│
├── agents/                       🤖 META — AI infrastructure
│   ├── 00_BOOTSTRAP.md           ← TÚ ESTÁS AQUÍ
│   ├── 01_subagents_catalog.md   Roles AI especializados
│   └── 02_working_conventions.md Cómo trabajar con el founder
│
├── planning/                     📋 META — Roadmap (NEW)
│   ├── 01_roadmap.md             Fases + milestones + dependencias
│   └── 02_decision_log.md        ADRs (decisiones de arquitectura)
│
├── design/                       ✅ CERRADA — qué construir (mecánicas)
│   ├── 01_node_granja.md         Granja: plant + harvest + quality
│   ├── 02_node_molino.md         Molino: process + quality
│   ├── 03_node_logistics.md      Drivers + delivery + escrow
│   ├── 04_node_bakery.md         Bakery: recetas + B2B/B2C
│   ├── 05_node_retail.md         Retail: lineales + dynamic pricing
│   └── 06_tablet_app_suite.md    Tablet 12 apps spec
│
├── art/                          ✅ CERRADA — cómo se ve/suena
│   ├── 01_visual_pillars.md      Estilo visual + paleta + tono
│   ├── 02_shader_contracts.md    Shaders Tablet + ítems
│   ├── 03_sound_bible.md         Audio + brass-jazz + a11y
│   └── 04_storybook_guide.md     UI components + motion + tokens
│
├── economy/                      ✅ CERRADA — números canónicos
│   ├── 01_economic_model.md      Master económico (1386 líneas) ⭐⭐⭐
│   ├── 02_bakery_economy.md      Detalle Bakery
│   └── 03_retail_economy.md      Detalle Retail
│
├── gameplay/                     ✅ CERRADA — feel + experiencia
│   ├── 01_gameplay_loops.md      Loops temporales + onboarding
│   ├── 02_progression_systems.md Skill mastery + achievements
│   └── 03_social_features.md     Empresa + chat + disputas
│
├── technical/                    ✅ CERRADA
│   ├── 01_architecture.md        ✅ Foundational
│   ├── 02_events_catalog.md      ✅ Foundational
│   ├── 03_db_schema.md           ✅ Foundational
│   ├── 04_api_contracts.md       ✅ Implementation
│   ├── 05_state_machines.md      ✅ Implementation (16 FSMs)
│   ├── 06_fivem_standards.md     ✅ Implementation (sync+sec+perf)
│   └── 07_bridges_compatibility.md ✅ Implementation (Bridges Layer + SDK)
│
└── qa/                           ✅ CERRADA
    └── 01_testing_protocol.md    ✅ Firmado (smoke+integration+release gates)
```

### 4.1 Single Sources of Truth (SSoT)

> **Si hay conflicto entre docs, ESTOS prevalecen** (orden jerarquía v1.5 post-ADR-012):

| # | Tema | SSoT |
|---|---|---|
| 1 | **Identity post-pivot (foundational + refinement)** | **ADR-011 + ADR-012 en `planning/02_decision_log.md` v1.4** — top de jerarquía en cualquier conflicto identity |
| 2 | **Visual direction canonical post-ADR-016** | **`art/01_art_direction.md` v3.0-locked IDENTITY V3 LOCK NOTICE** (top-level supersedes §1-§20 inline hasta Phase 4 surgical full) |
| 3 | **Filosofía + identity producto** | **`design/00_PRODUCT_BIBLE.md` v1.5** (post-ADR-016 identity v3 lock: palette 3-color + dark-only + Tablet stack) |
| 4 | Números económicos (precios, salaries, markups) | `economy/01_economic_model.md` |
| 5 | Eventos cliente↔server | `technical/02_events_catalog.md` (refs `admirals:*` Phase 6 purge pendiente) |
| 6 | Esquema DB | `technical/03_db_schema.md` (refs `admirals_*` Phase 6 + Phase 9 migration pendientes) |
| 7 | APIs síncronas (callbacks, exports, NUI bridges) | `technical/04_api_contracts.md` |
| 8 | FSMs (status entidades) | `technical/05_state_machines.md` |
| 9 | Performance budgets + security + sync | `technical/06_fivem_standards.md` |
| 10 | Compat scripts (bank/inventory/phone/etc.) | `technical/07_bridges_compatibility.md` v1.0 |
| 11 | Mecánicas nodo X | `design/0X_node_*.md` |
| 12 | Tokens visuales (color, spacing, motion) | `art/04_storybook_guide.md` (refresh pendiente alineado r6 NOTICE) |
| 13 | Sonidos | `art/03_sound_bible.md` (refresh pendiente; nombres canonical post-ADR-012 ver `art/briefs/03_brief_sound.md` v1) |
| 14 | Loops gameplay | `gameplay/01_gameplay_loops.md` |
| 15 | Roadmap + planning | `planning/01_roadmap.md` v1.4 |
| 16 | Decisiones arquitectónicas (ADRs) | `planning/02_decision_log.md` v1.5 (15 ADRs, ADR-001–015) + `planning/02_decision_log_part2.md` v1.0 (ADR-016+) |
| 17 | Testing protocol | `qa/01_testing_protocol.md` |
| 18 | **Specialist creative deliverable specs** | `art/briefs/0X_brief_*.md` v2 correspondientes |
| 19 | **Canonical palette tokens (3-color strict)** | `docs/art/branding/01_brief_logo.md` v3 §4.1 (SSoT post-ADR-016 D1) |
| 20 | **Tablet UI implementation stack (FROZEN S2-S8)** | `resources/sonar_tablet/web-src/package.json` (SSoT post-ADR-016 D5) |

---

## 5. Principios de trabajo (NON-NEGOTIABLE)

### 5.1 Quality bar SONAR

Cada doc producido debe cumplir:

- ✅ **Concreto, no abstracto.** Números reales, nombres reales, ejemplos específicos.
- ✅ **Operacional, no teórico.** Si lo lee un dev, sabe qué codear. Si lo lee un artist, sabe qué crear.
- ✅ **Cross-referenced.** Links a docs hermanos donde aplica.
- ✅ **Versionado + estado claro.** Header con versión + estado (en redacción / firmado).
- ✅ **Bus-factor proof.** Cualquier persona/AI nueva puede entender sin contexto previo.
- ✅ **Coherente con SSoTs.** No contradice docs ya firmados.

### 5.2 Estilo de redacción

- **Formato:** Markdown con headings claros, bullet lists, tablas cuando aplica.
- **Voz:** profesional, directa, sin excesos. Español + términos técnicos en inglés OK (ej: "lineage", "escrow", "subscription").
- **Estructura recurrente** docs:
  ```
  Header (versión, padre, hermanos, estado)
  §0 Resumen ejecutivo
  §1-§N Contenido
  §último Roadmap + estado + changelog
  Resumen ejecutivo final
  Quote final
  "FIN DEL DOCUMENTO X v1.0"
  ```
- **Tablas:** preferidas sobre listas largas para datos estructurados.
- **Code blocks:** con language hint cuando aplica.
- **Citaciones internas:** backticks para `nombres_de_archivo.md` y `funciones()`.
- **Énfasis:** **bold** para términos críticos, *italic* para énfasis contextual.
- **Quotes:** > para insights clave o reglas absolutas.

### 5.3 Sin emojis decorativos en código

- En **markdown docs:** emojis OK como section markers (✅ 🔴 ⭐) y title icons.
- En **código fuente:** NO emojis salvo que el founder lo pida explícito.

### 5.4 Anti-patterns AI agents

> **Errores comunes que cometen los AI. EVÍTALOS.**

#### 5.4.1 Hallucinaciones
- ❌ Inventar números económicos sin verificar contra `economy/01_economic_model.md`.
- ❌ Inventar nombres de eventos sin verificar contra `technical/02_events_catalog.md`.
- ❌ Inventar tablas DB que no están en `technical/03_db_schema.md`.

✅ **Solución:** **siempre busca en los SSoTs antes de afirmar un número/evento/tabla.** Si no existe, declara "necesito verificar este dato con el founder" o créalo explícitamente con justificación.

#### 5.4.2 Contradecir SSoTs
- ❌ Escribir "el markup Bakery B2B es 1.30" cuando economy dice 1.29.
- ❌ Cambiar mecánica firmada sin discusión explícita.

✅ **Solución:** si necesitas cambiar un SSoT, **propón el cambio explícitamente** + actualiza changelog + notifica founder.

#### 5.4.3 Sobre-ingeniería
- ❌ Añadir abstracciones "por si acaso" futuras.
- ❌ Crear N capas de indirección para flexibilidad imaginaria.

✅ **Solución:** **YAGNI** (You Aren't Gonna Need It). Construye lo necesario. Refactoriza cuando aparezca el necesidad real.

#### 5.4.4 Acknowledgment phrases
- ❌ "¡Tienes toda la razón!" / "¡Excelente idea!" / "¡Perfecto!"
- ❌ "Voy a trabajar en eso ahora mismo!"
- ❌ Repetir el plan antes de ejecutar.

✅ **Solución:** **respuestas directas + acción.** Empieza con substance, no preámbulo.

#### 5.4.5 Recreate over modify
- ❌ Crear nuevo doc cuando ya existe uno relevante.
- ❌ Reescribir sección que solo necesita edit pequeño.

✅ **Solución:** **edita primero, crea solo si no existe.** Usa herramientas de búsqueda antes de escribir.

#### 5.4.6 Skip verification
- ❌ Decir "lo he completado" sin verificar.
- ❌ No leer respuesta de tool calls antes de continuar.

✅ **Solución:** **verifica siempre.** Read after write. Confirma cambios visibles.

### 5.4.7 Re-confundir metáfora literal-militar deprecated (NEW v1.5 — post-ADR-012)
- ❌ Usar términos `silent service`, `capitán submarino`, `tactical-grade`, `bridge command center` militar, `silent service interface` en NEW work.
- ❌ Proponer iconografía `sonar-ping`/`submarine`/`hydrophone`/`periscope`/`torpedo-bay` (deprecated).
- ❌ Proponer sound names `sonar_ping/pressure/depth/console/hatch` (deprecated).
- ❌ Proponer dark-extremo 60% canvas theme (deprecated scaffold-r1).
- ❌ Inventar concepto logo "S-onda concentric" radio/freq (deprecated BRIEF-LOGO-001 v1).

✅ **Solución:** **lectura obligatoria ADR-011 + ADR-012 + r6 NOTICE + Bible v1.4 §1** (Round 1 §3.1) ANTES de cualquier work post-2026-05-03. Memoria persistente `SONAR Identity Direction r2` debe estar cargada.

---

## 5.5 SONAR Identity hard rules (NEW v1.5 — post-ADR-012 obligatorio NEW work)

> **Estas reglas son inviolables en NEW work post-2026-05-03.** Excepciones permitidas: Phase 8 code refactor activo (renaming legacy), SESSION_LOG históricas (append-only), ADRs históricos (inmutables), Migration 009 (DB rename), `_archive/` files (preservation), changelog entries inmutables.

### 5.5.1 Metáfora obligatoria abstract pure (ADR-012 D1)

- ✅ SONAR ES: profundidad simbólica abstracta. Valor oculto bajo capas. Calma metódica. Patterns que emergen al observar con atención. Claridad bajo presión.
- ❌ SONAR NO ES: submarino militar literal, hardware señal acústica (hydrophones/sonar pings radio/waveforms/oscilloscope/instrument-panels), armamento (torpedos/depth charges), equipo cubierta literal (periscopios/bridge-as-command-center/hatches/casco remaches/crew submarino).

### 5.5.2 Theme hybrid dark+white obligatorio (ADR-012 D2)

- ✅ **Dark-only strict doctrine (post-ADR-016 D2):** 100% dark canvas `--sonar-black` `#060607` + `--sonar-orange` `#FF5100` brand signal + `--sonar-white` `#FAFAFA` foreground/texto/icons. NO white/off-white surfaces product.
- ❌ **DEPRECATED v1.4 hybrid** dark+white surfaces + Sonar Bright teal product surfaces + Coloro surfaces (deprecated post-ADR-016 D2). DEPRECATED scaffold-r1 dark-extremo 60%.
- ✅ Excepción única: `monogram_s_black.svg` print/external NON-product (D-S1.10E-A).

### 5.5.3 Voz neutral premium-tech obligatoria (ADR-012 D3)

- ✅ Estilo Vercel/Linear/Stripe/Apple Pro apps copy. Preciso, terse, calmo, professional, atemporal.
- ❌ CERO arquetipo militar/submarino: NO "silent service", NO "capitán", NO "comandante", NO "almirante", NO "a bordo", NO "tripulación", NO "tactical".
- ❌ CERO gen-Z/exclamaciones/emojis-en-producto/hyperbole/comparaciones competidores explícitas.

### 5.5.4 Color hierarchy inmutable

- ✅ **3-color strict canonical (post-ADR-016 D1):** `--sonar-black` `#060607` + `--sonar-orange` `#FF5100` + `--sonar-white` `#FAFAFA`. SSoT `docs/art/branding/01_brief_logo.md` v3 §4.1.
- ❌ **DEPRECATED product UI:** Sonar Bright `#2DD4BF` (reserved marketing/external only), Sonar Glow `#5EEAD4`, Sonar Pulse `#14E5DD`, Coloro `#175A5F` PROHIBIDO logo/branding.
- ❌ NUNCA gradientes rainbow/holográficos/RGB/cyberpunk neon.

### 5.5.5 Iconografía canonical post-ADR-012

- ✅ 8 iconos canonical: 3 conservados (depth-gauge, pressure-hull RECONCEPTUALIZADO capas concentricas, bioluminescence) + 5 abstract nuevos (descent-layers, signal-clarity, depth-grid, observation-field, lineage-trace).
- ❌ PURGADOS deprecated NO usar: sonar-ping (radio concentric), submarine (silhouette literal), hydrophone (mic acústico), periscope (literal), torpedo-bay (armamento).

### 5.5.6 Sound naming canonical post-ADR-012

- ✅ 5 SFX firma: `signal_emerge` (notif), `depth_press` (firma/confirm), `layer_dive` (escritura UI), `console_tap` (premium click), `panel_open` (modal).
- ❌ PURGADOS deprecated NO usar: `sonar_ping`, `sonar_pressure`, `sonar_depth`, `sonar_console`, `sonar_hatch`.

### 5.5.7 Vocabulario canonical post-ADR-012

- ✅ Console (UI activa) / Bitácora (audit trail) / Depth (tier/profundidad simbólica) / Eco (tx identifier) / Manifiesto (contrato firmado) / Signal (evento bus) / Lineage (cadena producción) / Patrón (anomalía emergiendo) / Bridge re-interpretado como "Tablet home view" abstract.
- ❌ DEPRECATED NO usar: Periscope, Hatch, Hydrophone, Ping (radio), Sweep, Sumersión, Bridge-as-command-center militar, "silent service", "tactical-grade".

### 5.5.8 Excepciones permitidas Admirals refs (per ADR-011)

- ✅ Phase 8 code refactor activo (renaming `admirals_*` → `sonar_*`).
- ✅ SESSION_LOG históricas (append-only).
- ✅ ADRs históricos (inmutables).
- ✅ Migration 009 (DB rename).
- ✅ `_archive/` files (preservation).
- ✅ Changelog entries inmutables.
- ✅ Code namespace existing `admirals_*` hasta Phase 8 refactor cumplido.

---

## 6. Decision boundaries — qué decide AI vs founder

### 6.1 AI puede decidir solo (sin preguntar)

- **Estructura interna de un doc** (qué secciones, en qué orden).
- **Estilo de redacción** (frasing específico, ejemplos).
- **Refactoring trivial** (formatting, typos, broken links).
- **Búsqueda/lectura** de docs/código existentes.
- **Cross-references** correctas entre docs ya firmados.
- **Numeración versiones** (1.0 → 1.0.1 patch, etc.).

### 6.2 AI propone, founder aprueba

- **Cambios a SSoTs firmados** (economic numbers, eventos, schema DB).
- **Nuevos docs** (categoría, nombre, estructura general).
- **Decisiones de arquitectura técnica** (qué framework, qué pattern).
- **Cambios a roadmap** (orden de phases, prioridades).
- **Eliminación de contenido** firmado.

**Formato propuesta:** "Propongo X porque Y. Impactos: Z. ¿Procedes?"

### 6.3 Founder decide siempre

- **Visión producto** (qué construir, para quién).
- **Filosofía core** (los 4 pilares, los principios irreductibles).
- **Trade-offs estratégicos** (oleada 1 vs 2, scope decisions).
- **Hiring** (qué devs/artistas contratar).
- **Plataforma + stack** decisions críticas.
- **Política de pago/monetización**.

### 6.4 Escalation matrix

| Situation | Action |
|---|---|
| Detecto inconsistencia entre dos docs firmados | **Notifica founder + propón resolución** |
| Encuentro número económico sin justificación | **Notifica + flag para verificación** |
| Tarea me requiere skill que no tengo confianza | **Declara incertidumbre + sugiere alternativa** |
| Founder pide algo que contradice SSoT | **Confirma intención + flag conflict + procede si confirma** |
| No encuentro doc relevante para tarea | **Busca primero + si confirmado missing, propón crear** |

---

## 7. Common workflows

### 7.1 Workflow: Crear nuevo doc

1. **Verificar no existe ya:** `find_by_name` + `grep_search`.
2. **Leer doc padre + hermanos** para mantener coherencia.
3. **Confirmar con founder** estructura + scope.
4. **Redactar** siguiendo §5.2 estilo.
5. **Cross-reference** SSoTs relevantes.
6. **Marcar estado** "primera redacción".
7. **Pedir review founder.**
8. **Marcar firmado** tras aprobación.
9. **Actualizar BOOTSTRAP §2.2 + §4** mapa.

### 7.2 Workflow: Firmar doc existente

1. **Verificar completitud** vs estructura definida.
2. **Buscar TODOs/inconsistencias.**
3. **Cross-check con SSoTs.**
4. **Cambiar header `> Estado:` a "firmado".**
5. **Actualizar `Versión:` a "1.0 (firmado — completo, N secciones)".**
6. **Actualizar changelog**.
7. **Notificar founder.**
8. **Actualizar BOOTSTRAP §2.2 contadores.**

### 7.3 Workflow: Validar número económico

1. **Localiza el número** en doc/code.
2. **Busca en `economy/01_economic_model.md`** la fuente canónica.
3. **Si match:** ✅ correcto.
4. **Si no match:**
   - ¿Es derivado de fuente canónica? → recalcula y verifica.
   - ¿Es número independiente? → flag para founder + economy_validator subagent.
5. **Si conflicto:** prefiere SSoT, propón corrección al doc divergente.

### 7.4 Workflow: Añadir feature al roadmap

1. **Localiza fase** apropiada en `planning/01_roadmap.md`.
2. **Verifica dependencias** (qué necesita esta feature).
3. **Estima esfuerzo** (low/mid/high).
4. **Confirma con founder** prioridad.
5. **Actualiza roadmap.**
6. **Actualiza decision_log si es decisión grande.**

### 7.5 Workflow: Onboarding nueva sesión AI

1. **Lee este BOOTSTRAP completo.**
2. **Lee `agents/02_working_conventions.md`.**
3. **Lee `planning/01_roadmap.md`.**
4. **Lee `00_PRODUCT_BIBLE.md`.**
5. **Pregunta founder:** "¿Cuál es la tarea actual?"
6. **Carga docs relevantes** según §3.3.
7. **Procede con la tarea.**

---

## 8. Tooling y herramientas

### 8.1 Tooling existente

- **Editor:** Windsurf (Cascade). User OS: Windows.
- **Repo:** `d:\theBigProject` (Windows path).
- **VCS:** asumir Git (configurar si no existe).
- **Workflows Windsurf:** `.windsurf/workflows/` (vacío actualmente).

### 8.2 Herramientas AI agent debe usar

| Tool | Uso |
|---|---|
| `find_by_name` | Localizar archivos por pattern |
| `grep_search` | Buscar texto dentro de archivos |
| `read_file` | Leer contenido archivo |
| `code_search` | Búsqueda semántica codebase |
| `edit` / `multi_edit` | Modificar archivos existentes (preferido) |
| `write_to_file` | Crear archivos nuevos (solo si no existen) |
| `list_dir` | Explorar estructura |

### 8.3 Herramientas que el AI NO debe usar gratuitamente

- `run_command` con efectos destructivos (rm, drop, force-push) — siempre confirma.
- `deploy_web_app` — N/A para FiveM.
- Network calls externos — confirmar con founder.

---

## 9. Comunicación con founder

### 9.1 Estilo respuesta

> Ver detalle completo en `agents/02_working_conventions.md`.

**Resumen:**
- **Directo, sin preámbulo** ("¡Excelente!" / "Tienes razón" → NO).
- **Conciso pero completo.** Markdown con headers + tablas.
- **Acción + verificación.** No prometas, ejecuta y reporta.
- **Honestidad sobre incertidumbre.** Si no estás seguro, dilo.
- **Español como default**, inglés OK para tecnicismos.

### 9.2 Cuándo preguntar founder

- **Decisiones que cambian SSoTs.**
- **Trade-offs estratégicos.**
- **Tarea ambigua sin contexto suficiente.**
- **Conflictos detectados entre docs.**

### 9.3 Cuándo NO preguntar (proceed)

- **Detalles formato/estilo.**
- **Verificaciones rutinarias.**
- **Estructura interna doc.**
- **Aplicación de SSoTs ya definidos.**

---

## 10. Métricas de éxito agente AI

> **Cómo saber si la sesión AI fue exitosa:**

| Metric | Target |
|---|---|
| **Docs producidos vs. firmados ratio** | >80% (most produced docs sign-able) |
| **SSoT contradictions introduced** | 0 (zero tolerance) |
| **Acknowledgment phrases en respuestas** | 0 |
| **Tareas completadas sin escalation innecesaria** | >70% |
| **Founder rework required post-AI** | <15% |
| **Cross-references válidos (no broken links)** | >95% |
| **Hallucinated facts** | 0 |

---

## 11. Subagents — ARCHIVADO (ver ADR-001)

> ⚠️ **Subagents en paralelo archivados** por decisión founder 2026-05-01 (ADR-001 en `planning/02_decision_log.md`). Razón: tooling multi-agent AI actual no es fiable — trabajamos **secuencial + planificación e2e robusta**.

### 11.1 Política actual

- ❌ **NO anunciar subagents** ("Activando rol X…").
- ❌ **NO ejecutar checks en paralelo.**
- ✅ **Sí ejecutar los checks secuencialmente** cuando aplican, sin ceremonia.
- ✅ **Sí usar los workflows** definidos en `agents/01_subagents_catalog.md` (archivado) **como checklists mentales**.

### 11.2 Checks disponibles (reinterpretados como checklists)

| Check | Cuándo ejecutar | Cómo |
|---|---|---|
| Verificar número económico | Antes de afirmar pricing/salary | Grep en `economy/01_economic_model.md` |
| Validar cross-refs | Antes de firmar doc | Read refs + confirmar archivos existen |
| Redactar doc nuevo | Crear .md | Seguir template + estilo Admirals |
| Auditar SSoT coherence | Antes firmar SSoT | Comparar claims internas |
| Proteger doc firmado | Antes editar firmado | Confirmar con founder |
| FiveM perf review | Code review Oleada 1+ | Contra `technical/06_fivem_standards.md` |

### 11.3 Referencia completa

Ver `agents/01_subagents_catalog.md` (archivado) para spec detallada de cada check — solo ignorar la ceremonia "activando rol".

---

## 12. Estado de este documento

### 12.1 Estado

- **Versión:** 1.6 (firmado, living document). **Oleada 0 CERRADA 100% (29/29 docs) + briefs v2 (5/5) + Sprint 0 + Sprint 1 cerrados + B1 Phase 6 mass-purge 8/8 CERRADO + IDENTITY V3 LOCK post-ADR-016 + PIVOT EN EJECUCIÓN MULTI-PHASE.**
- **Próxima revisión:** post Phase 8+9 execution + Phase 10 smoke regression complete, con learnings + v1.7 incorporando namespace migration complete.

### 12.2 Maintenance

> **Este documento DEBE actualizarse cuando:**

- Nuevo doc firmado → actualizar §2.2 + §4 mapa.
- Nuevo subagent definido → §11.
- Nuevo workflow descubierto → §7.
- Cambio política/principio → §5.
- Cambio plataforma/stack → §1.4.

### 12.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción completa. 12 secciones cubriendo identidad proyecto, estado, reading order, mapa docs, principios trabajo, decision boundaries, workflows, tooling, comunicación, métricas, subagents. **Living document.** |
| 1.1 | 2026-05-01 | Founder + Cascade | Sincronización estado tras Oleada 0 quasi-completa: 28 docs firmados, agents/planning/qa/technical-impl cerradas excepto bridges. **Pivot MVP node Bakery→Granja** (§2.5 nuevo). Stack técnico actualizado (QBox primary + Bridges layer). Reading order §3.2 expandido con todos los technical impl docs. Mapa §4 actualizado. SSoT table §4.1 expandido. Round 2 reading list completa. |
| 1.2 | 2026-05-01 | Founder + Cascade | **🏆 OLEADA 0 CERRADA 100%.** Firmado `technical/07_bridges_compatibility.md` v1.0 (último doc) + ADR-008 (Granja pivot) + ADR-009 (Bridges Layer). 29 docs / ~27.260 líneas. Fase actual cambiada a "READY TO CODE — Sprint 0 Oleada 1". Mapa §4 cierra technical/ categoría. SSoT table marca bridges_compatibility firmado. |
| 1.3 | 2026-05-02 | Founder + Cascade | **🏆 SPRINT 0 CERRADO.** `admirals_bridges` v0.2.0 + `admirals_core` v0.1.0 + migrations 001/002 + ADR-010 (hybrid audit_log resolviendo inconsistencia SSoT §03↔§04) + smoke test 10 pasos. 4 sessions S0.1-S0.4 + 1 checkpoint S0.0 ejecutadas en 1 día (vs estimado 3 sem). §2.1 actualizado con resumen deliverables. **Next: Sprint 1 — Banco core.** |
| 1.4 | 2026-05-02 | Founder + Cascade | **🏆 SPRINT 1 CERRADO** (mismo día — velocity 15× estimado). `admirals_bank` v0.4.0 (escrow FSM + C001/C002/C004/C005) + `admirals_core` v0.4.2 + migrations 003-008 + idempotency DB-backed promoted + smokes 30/30 cumulative. 3 sessions S1.1-S1.3 en 1 día (vs 2 sem estimado). Tag `sprint-1-complete`. §2.1 actualizado. **Next: Sprint 2 — Tablet shell (planning session dedicada pendiente).** |
| 1.5 | 2026-05-03 | Founder + Cascade | **🔄 PIVOT IDENTITY Admirals→SONAR EN EJECUCIÓN MULTI-PHASE** (post-S1.4+S1.5+S1.6 sessions). **Cambios:** (a) Title rebrand Admirals→SONAR. (b) Header pivot ref ADR-011 + ADR-012 + r6 NOTICE + Bible v1.4 lectura conjunta obligatoria. (c) STOP banner expandido obligatoriedad 4 docs identity ANTES NEW work. (d) §0 expandido razón pivot identity. (e) §1 reescrita: Heritage Admirals deprecated + nueva §1.3.1 Identity hard rules summary (metáfora abstract + theme hybrid + voz neutral + color hierarchy + sound names canonical). (f) §2.1 reescrita: estado pivot multi-phase tracker (Phase 1→Phase 11) + Sprint 1 cerrado preserved historical + Sprint 2 diferido. (g) §2.2 inventario expandido: Bible v1.4 + art_direction r6 + briefs v2 + _archive/ marcados. (h) §3.1 Round 1 reading order ampliado (~75min→110min): obligatorio ADR-011+ADR-012 (#2), r6 NOTICE (#3), Bible v1.4 §1 (#4) ANTES de gameplay/técnico. NO LEER list (deprecated _archive + scaffold-r1..r5 inline + briefs v1). (i) §3.2 Round 2 nota refs `admirals_*` Phase 6/8/9 pendientes. (j) §3.3 Round 3 task table actualizada con r6 NOTICE OBLIGATORIO + briefs v2. (k) §4 mapa expanded: _archive/ + art/briefs/ secciones. (l) §4.1 SSoT jerarquía 18-row con ADR-011/012 (#1) + r6 NOTICE (#2) + Bible v1.4 (#3) top. (m) **Nueva §5.5 SONAR Identity hard rules** (8 sub-secciones: metáfora abstract / theme hybrid / voz neutral / color hierarchy / iconografía / sound naming / vocabulario / excepciones permitidas). (n) Nueva §5.4.7 anti-pattern re-confundir metáfora literal-militar deprecated. (o) §13 TL;DR reescrito completo post-pivot. **Preservado intact:** §5 quality bar/estilo/anti-patterns (excepto add 5.4.7), §6 decision boundaries, §7 workflows, §8 tooling, §9 comunicación, §10 métricas, §11 subagents archivados ADR-001, §12 maintenance. **Próximas sesiones AI requieren** ADR-011 + ADR-012 + r6 NOTICE + Bible v1.4 §1 lectura ANTES de cualquier work nuevo + memoria persistente `SONAR Identity Direction r2` cargada. |

| **1.6** | 2026-05-04 | Founder + Cascade | **S1.10.5 Item F — BOOTSTRAP v1.5 → v1.6 post-ADR-016 identity v3 lock.** (a) Header: v1.6 + ADR-013/014/015 in `02_decision_log.md` v1.5 + ADR-016 in `02_decision_log_part2.md` v1.0 + B1 Phase 6 CERRADO. (b) STOP banner: 5 docs obligatorios (add ADR-016 + part2). (c) §1.3.1 Identity hard rules: hybrid → dark-only v3 + 3-color canonical SSoT brief_logo v3. (d) §2.1 Phase 6 B1 CERRADO 8/8. (e) §2.2 inventario: Bible v1.5 + art_direction v3.0-locked + brief_logo v3 + agents v1.6 + planning part2. (f) §3.1 reading order: v1.6 + part2 + v3.0-locked + v1.5. (g) §4.1 SSoT table: rows 2/3 updated + row 16 part2 + NEW rows 19 (canonical palette brief_logo v3) + 20 (Tablet stack package.json). (h) §5.5.2 theme hybrid → dark-only strict. (i) §5.5.4 Sonar Bright → 3-color strict. (j) §12.1 Estado v1.6 + próxima revisión Phase 8+9+10. |

---

## 13. TL;DR — para AI agents en hurry

Si por alguna razón solo puedes leer 5 minutos de este doc, lee **esto**:

1. **SONAR (ex-Admirals)** = servidor FiveM con economía profunda + cadenas producción + Tablet UI. **Pivot identity 2026-05-03** (ADR-011 + ADR-012). Code namespace `admirals_*` hasta Phase 8 refactor.
2. **🔴 PRIMERO LEE: ADR-011 + ADR-012 + art_direction r6 NOTICE + Bible v1.4 §1** ANTES de cualquier work nuevo. Sin esos 4 risk re-confundir metáfora literal-militar deprecated.
3. **SONAR identity hard rules (§5.5)**: metáfora abstract pure (NO submarino militar literal, NO radios/freq, NO periscopio/torpedo/hydrophone) + theme hybrid dark+white surfaces (~30-40% dark + ~30-40% white + ~10-15% Sonar Bright + ~10% Coloro + <5% signals) + voz neutral premium-tech (Vercel/Linear/Stripe class, NO "silent service"/"capitán"/"tactical") + Sonar Bright `#2DD4BF` PRIMARY identity + Coloro `#175A5F` PROHIBIDO logo + sound names canonical (`signal_emerge`/`depth_press`/`layer_dive`/`console_tap`/`panel_open`) + iconografía 8 canonical (3 conservados + 5 abstract nuevos).
4. **28.760+ líneas docs firmados** (29 + 5 briefs v2). **🏆 Sprint 0 + Sprint 1 Oleada 1 CERRADOS** (2026-05-02): `admirals_bridges` v0.2.0 + `admirals_core` v0.4.2 + `admirals_bank` v0.4.0. **Pivot multi-phase EN EJECUCIÓN** (Phase 4 surgical full + Phase 5 full + Phase 6 mass-purge + Phase 8 code refactor + Phase 9 migration + Phase 10 smoke + Phase 11 workspace pendientes). No reescribas docs firmados — léelos.
5. **SSoTs canónicos** (§4.1 jerarquía 18-row): top jerarquía = ADR-011/ADR-012 + art_direction r6 NOTICE + Bible v1.4. **Si conflicto, ellos ganan.**
6. **MVP Oleada 1 = Granja** (pivot v1.1). NO Bakery. Granja es nodo raíz cross-vertical.
7. **NO XP genérico, NO PvP, NO pay-to-win, NO QTEs.**
8. **Stack:** FiveM Lua + JS/TS React Tablet + MySQL + State Bags sync. **QBox primary + Bridges layer.**
9. **Quality bar + estilo:** concreto > abstracto, operacional > teórico, cross-referenced. Respuesta directa, sin preámbulo, español + tecnicismos inglés OK.
10. **Anti-patterns:** hallucinaciones, sobre-ingeniería, "¡Tienes razón!", recreate sobre modify, anunciar subagents (ADR-001 archivados), **re-confundir metáfora literal-militar deprecated post-ADR-012 (§5.4.7)**.
11. **Cuando dudes:** busca SSoT, lee doc relevante, pregunta founder solo en escalation matrix §6.4.

> **Tu objetivo:** mantener la cadena de calidad establecida + identity coherence post-ADR-012. Cada AI agent posterior debe poder continuar donde lo dejaste sin que se note diferencia, con identity SONAR (NOT Admirals, NOT submarino militar literal) consistently aplicada.

---

*"Documentación sin meta-organización es ruido. Este BOOTSTRAP es la señal."*

**FIN DEL DOCUMENTO `agents/00_BOOTSTRAP.md` v1.6 (post-ADR-016 identity v3 lock + 02_decision_log_part2.md awareness + SSoTs canónicos)**
