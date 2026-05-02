# 🤖 Admirals — AI Agent Bootstrap (READ THIS FIRST)

> **Versión:** 1.4 (firmado — living document, 13 secciones). 1.4 update: **SPRINT 1 CERRADO** (2026-05-02). `admirals_bank` v0.4.0 (escrow FSM + C001/C002/C004/C005) + `admirals_core` v0.4.2 + migrations 003-008 + smokes 30/30 cumulative pasados. Tag `sprint-1-complete`. **Next: Sprint 2 — Tablet shell + Bank app (planning session dedicada pendiente).**
> **Tipo:** Documento meta-organizacional. **Este es el primer fichero que debe leer cualquier AI agent que trabaje en el proyecto Admirals.**
> **Audiencia:** AI agents (Cascade, Claude, GPT, otros). También útil para humanos onboarding.
> **Estado:** firmado (living document — actualizar al firmar cada nuevo doc).

> ⚠️ **STOP.** Si eres un AI y acabas de unirte a este proyecto: **NO empieces a escribir código ni docs todavía**. Lee este fichero entero primero. Luego sigue el reading order de §3. Solo después podrás contribuir efectivamente.

---

## 0. Por qué existe este documento

> **El proyecto Admirals tiene 17.800+ líneas de documentación profesional firmada.** Sin este fichero, un AI agent nuevo se ahoga en el mar de docs y pierde días reorientándose.

Este BOOTSTRAP es la **única fuente de verdad** sobre:

- **Qué es Admirals** (resumen 1-página).
- **Estado actual del proyecto** (dónde estamos).
- **Cómo está organizada la documentación** (mapa completo).
- **Orden de lectura recomendado** (no leer todo, leer lo correcto).
- **Principios de trabajo** (quality bar + estilo + ética).
- **Qué decide el AI vs qué decide el founder** (escalation matrix).
- **Anti-patterns** (errores comunes que cometen los AI).
- **Common workflows** (firmar doc, validar números, añadir feature).

**Sin esto, cada nueva sesión AI empieza desde 0.** Con esto, la cadena de trabajo NO se rompe.

---

## 1. Qué es Admirals (1 página)

### 1.1 El producto

**Admirals** es un servidor FiveM de roleplay con una mecánica core única: **economía profunda con cadenas de producción reales**.

- No es un script genérico de RP.
- No es shooter PvP.
- Es un **simulador económico multiplayer** donde el player es **literalmente** un panadero, granjero, cajero, manager — porque amasa, hornea, vende, y los números reales suben.

### 1.2 Los 4 pilares

1. **Cadenas de producción físicas** — Granja → Molino → Bakery → Retail. Cada nodo es trabajo real, ítems físicos con quality A/B/C/D y lineage trazable.
2. **Banco Admirals** — IBANs reales, escrows, tax retention 8%, ledger inmutable. Sin "economía mágica".
3. **Tablet (HUD operacional)** — 12 apps que el player abre con `TAB`. UI principal del producto.
4. **Empresas player-driven** — founders, co-founders, employees, contracts B2B, governance.

### 1.3 Principios irreductibles

- **Trabajo real, no skill check.** No QTEs, no minigames abstractos.
- **Economía es social.** Lineage chains requieren múltiples players cooperando.
- **No PvP combat.** Disputas → governance, no violence.
- **No pay-to-win.** No microtransactions que afecten balance.
- **Cap superior generoso, no infinito.** Mastery alcanzable en 100-300h.

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

**Fase: 🏆 SPRINT 1 CERRADO (2026-05-02). OLEADA 1 EN PROGRESO — 2/9 sprints cerrados.**

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

**Next: Sprint 2** — Tablet shell + Bank app (NUI React + keybind TAB + Bank UI balance/transactions/transfer + Map app GPS). **Planning session dedicada pendiente** (founder + architect, cross-sprint + decisiones stack UI).

### 2.2 Inventario de documentación firmada

| Categoría | Docs firmados | Líneas | Estado |
|---|---|---|---|
| `design/` | 6 | ~5.500 | ✅ CERRADA |
| `technical/` foundational | 3 (architecture, events_catalog, db_schema) | ~3.200 | ✅ CERRADA |
| `art/` | 4 | ~3.800 | ✅ CERRADA |
| `economy/` | 3 | ~2.600 | ✅ CERRADA |
| `gameplay/` | 3 | ~2.700 | ✅ CERRADA |
| `agents/` | 3 (00_BOOTSTRAP v1.2, 02_working_conventions; 01_subagents_catalog archivado) | ~2.000 | ✅ CERRADA |
| `planning/` | 2 (01_roadmap v1.1, 02_decision_log v1.1 con 9 ADRs) | ~3.100 | ✅ CERRADA |
| `technical/` implementation | 4 / 4 (api_contracts, state_machines, fivem_standards, **bridges_compatibility v1.0**) | ~3.700 | ✅ CERRADA |
| `qa/` | 1 (testing_protocol) | ~760 | ✅ CERRADA |

**Total firmado:** 29 docs / ~27.260 líneas. **Pendiente:** 0 docs. 🏆 **OLEADA 0 COMPLETA.**

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
| 1 | `agents/00_BOOTSTRAP.md` | 15min | **Este fichero.** Identidad + estado proyecto. |
| 2 | `agents/02_working_conventions.md` | 10min | Cómo interactuar con founder. |
| 3 | `agents/01_subagents_catalog.md` | 10min | Roles AI especializados disponibles. |
| 4 | `planning/01_roadmap.md` v1.1 | 10min | Qué se construye cuándo (Granja MVP pivot). |
| 5 | `00_PRODUCT_BIBLE.md` | 30min | Filosofía completa del producto. |

**Total Round 1: ~75 min.** Después de esto el AI **entiende el proyecto**.

### 3.2 Round 2 — Foundational technical (si tarea técnica)

| # | Doc | Por qué |
|---|---|---|
| 1 | `technical/01_architecture.md` | Cómo está estructurado el sistema. |
| 2 | `technical/02_events_catalog.md` | Catálogo eventos sistema (cliente↔server). |
| 3 | `technical/03_db_schema.md` | Esquema base de datos. |
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
| UI Tablet / HUD | `design/06_tablet_app_suite.md` + `art/04_storybook_guide.md` |
| Audio | `art/03_sound_bible.md` |
| Estilo visual / shaders | `art/01_visual_pillars.md` + `art/02_shader_contracts.md` |
| Gameplay loops / onboarding | `gameplay/01_gameplay_loops.md` |
| Progresión / achievements | `gameplay/02_progression_systems.md` |
| Empresa / chat / disputas | `gameplay/03_social_features.md` |
| API endpoints | `technical/04_api_contracts.md` |
| Estados / FSM | `technical/05_state_machines.md` |

### 3.4 Anti-pattern: leer TODO

❌ **No intentes leer las 17.800 líneas en una sesión.** Es ineficiente y lleva a context overload. Usa el orden anterior.

✅ **Usa búsqueda direccional:** si necesitas algo específico, `grep`/`find` antes de leer.

---

## 4. Mapa completo de documentación

```
docs/
├── 00_PRODUCT_BIBLE.md          ⭐ La biblia. Filosofía + 4 pilares.
│
├── agents/                       🤖 META — AI infrastructure (NEW)
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

> **Si hay conflicto entre docs, ESTOS prevalecen:**

| Tema | SSoT |
|---|---|
| Filosofía proyecto | `00_PRODUCT_BIBLE.md` |
| Números económicos (precios, salaries, markups) | `economy/01_economic_model.md` |
| Eventos cliente↔server | `technical/02_events_catalog.md` |
| Esquema DB | `technical/03_db_schema.md` |
| APIs síncronas (callbacks, exports, NUI bridges) | `technical/04_api_contracts.md` |
| FSMs (status entidades) | `technical/05_state_machines.md` |
| Performance budgets + security + sync | `technical/06_fivem_standards.md` |
| Compat scripts (bank/inventory/phone/etc.) | `technical/07_bridges_compatibility.md` v1.0 |
| Mecánicas nodo X | `design/0X_node_*.md` |
| Tokens visuales (color, spacing, motion) | `art/04_storybook_guide.md` |
| Sonidos | `art/03_sound_bible.md` |
| Loops gameplay | `gameplay/01_gameplay_loops.md` |
| Roadmap + planning | `planning/01_roadmap.md` v1.1 |
| Decisiones arquitectónicas (ADRs) | `planning/02_decision_log.md` |
| Testing protocol | `qa/01_testing_protocol.md` |

---

## 5. Principios de trabajo (NON-NEGOTIABLE)

### 5.1 Quality bar Admirals

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

- **Versión:** 1.2 (firmado, living document). **Oleada 0 CERRADA 100% (29/29 docs).**
- **Próxima revisión:** post Sprint 0 Oleada 1 (bridges skeleton + admirals_core boot) con learnings reales + v1.3 incorporando path refinements.

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

---

## 13. TL;DR — para AI agents en hurry

Si por alguna razón solo puedes leer 5 minutos de este doc, lee **esto**:

1. **Admirals** = servidor FiveM con economía profunda + cadenas producción + Tablet UI.
2. **27.260 líneas docs firmados** (29 docs Oleada 0 CERRADA). **🏆 Sprint 0 + Sprint 1 Oleada 1 CERRADOS** (ambos 2026-05-02): `admirals_bridges` v0.2.0 + `admirals_core` v0.4.2 + `admirals_bank` v0.4.0 (IBAN + Accounts + Transfer + Escrow FSM + C001/C002/C004/C005) operativos. No reescribas docs firmados — léelos.
3. **SSoTs canónicos** (§4.1 tabla completa): `00_PRODUCT_BIBLE.md`, `economy/01_economic_model.md`, `technical/02_events_catalog.md`, `technical/03_db_schema.md`, `technical/04_api_contracts.md`, `technical/05_state_machines.md`, `technical/06_fivem_standards.md`. **Si conflicto, ellos ganan.**
4. **MVP Oleada 1 = Granja** (pivot v1.1). NO Bakery. Granja es nodo raíz cross-vertical (Bible §13.4).
5. **NO XP genérico, NO PvP, NO pay-to-win, NO QTEs.**
6. **Stack:** FiveM Lua + JS/TS React Tablet + MySQL + State Bags sync. **QBox primary + Bridges layer** para compat custom scripts (lb-phone, qs-inventory, custom banks).
7. **Quality bar:** concreto > abstracto, operacional > teórico, cross-referenced.
8. **Estilo respuesta:** directo, sin preámbulo, español + tecnicismos inglés OK.
9. **Anti-patterns:** hallucinaciones, sobre-ingeniería, "¡Tienes razón!", recreate sobre modify, anunciar subagents (ADR-001 archivados).
10. **Cuando dudes:** busca SSoT, lee doc relevante, pregunta founder solo en escalation matrix §6.4.

> **Tu objetivo:** mantener la cadena de calidad establecida. Cada AI agent posterior debe poder continuar donde lo dejaste sin que se note diferencia.

---

*"Documentación sin meta-organización es ruido. Este BOOTSTRAP es la señal."*

**FIN DEL DOCUMENTO `agents/00_BOOTSTRAP.md` v1.4**
