# 🎯 Admirals — Founder Operations Playbook

> **Versión:** 1.0 (firmado — living document).
> **Tipo:** Meta-organizacional. **Para el founder.**
> **Audiencia:** Founder Admirals (tú). Escrito en segunda persona porque es **tu** manual operativo.
> **Estado:** firmado.
> **Documento padre:** `agents/00_BOOTSTRAP.md` v1.2.

> ⚠️ **Este doc te dice cómo supervisar AI sostenidamente durante meses sin que el contexto se degrade entre sesiones, sin que pierdas el control, sin que el proyecto deriva hacia el caos.** Léelo entero **antes** de empezar Sprint 0.

---

## 0. Por qué existe este documento

### 0.1 El problema real

Has invertido ~1 mes redactando 29 docs / 27.260 líneas con cuidado quirúrgico. Llega Sprint 0 y empiezas a programar con AI agents. **Tres semanas después tienes:**

- 12 conversaciones AI distintas, cada una con contexto fragmentado.
- Código con 4 estilos diferentes porque cada AI improvisó.
- 2 features re-implementadas porque la AI no sabía que ya existían.
- Tú agotado intentando recordar qué hizo cada AI cuándo.
- El proyecto derivando porque nadie tiene visión global.

**Esto pasa al 95% de los proyectos solo-founder + AI.** No por falta de docs — los tienes — sino por **falta de protocolo operacional**.

### 0.2 La solución

Este playbook define:

1. **Modelo mental jerárquico:** Oleada → Sprint → Session.
2. **Anatomía exacta** de cada nivel (duración, scope, ceremonias, artefactos).
3. **Protocolo SESSION_LOG** — la AI nueva siempre puede recuperar contexto en 5 min leyendo logs.
4. **Plantilla prompt copy-paste** para iniciar cada sesión nueva en 30 segundos.
5. **Workspace config** Cascade/Windsurf (rules + memorias + workflows).
6. **Tu checklist supervisor** pre/during/post sesión.
7. **Criterios sign-off** sprint y oleada.
8. **Anti-patterns** del founder (lo que tú haces mal).
9. **FAQ** real basada en problemas que ocurrirán.
10. **Sprint 0 ejemplo aplicado** — 6 sessions con prompts listos.

> **Tu objetivo no es codear todo. Es supervisar bien para que la AI codee bien.** Este doc es la diferencia entre "founder que ship producto" y "founder que abandona en mes 4".

---

## 1. Modelo mental jerárquico

### 1.1 Niveles

```
┌──────────────────────────────────────────────────────────┐
│  OLEADA                  3-8 meses    Big milestone      │
│  └─ 9-12 sprints                                          │
│       └─ SPRINT          2-3 semanas  Feature shippable  │
│            └─ 5-8 sessions                                │
│                 └─ SESSION  1-3 horas Outcome concreto    │
│                      └─ ~50-150 mensajes AI              │
└──────────────────────────────────────────────────────────┘
```

### 1.2 Definiciones operacionales

| Nivel | Pregunta clave | Owner | Output |
|---|---|---|---|
| **Oleada** | "¿Qué demo le enseño al mercado?" | Founder | Producto funcional vendible |
| **Sprint** | "¿Qué feature/módulo cierro en 2-3 semanas?" | Founder | Feature shippable + tested |
| **Session** | "¿Qué outcome concreto consigo en 1-3h con AI?" | Founder + AI | Código funcional + commit + log |

### 1.3 Por qué esta jerarquía

- **Oleada** previene scope creep (4 nodos en MVP = muerte). Ya cerrada en Roadmap v1.2.
- **Sprint** previene scope creep mensual (¿añadimos esta feature? → no, sprint scoped).
- **Session** previene scope creep diario (AI propone 5 cosas → no, session scoped).

> **Si no tienes scope claro a 3 niveles, la AI lo decidirá por ti. Y la AI no sabe tu negocio.**

---

## 2. Estructura Oleada 1 (mapping a sessions)

### 2.1 Vista general

| Sprint | Goal | Duración | Sessions | Perfiles dominantes |
|---|---|---|---|---|
| **S0** | Setup + Bridges Layer + admirals_core | 3 sem | **4** | ARCHITECT + BUILDER |
| **S1** | Banco core + IBAN | 2 sem | **3** | ARCHITECT + BUILDER |
| **S2** | Banco UI + Tablet shell | 2 sem | **3** | UI/UX + BUILDER |
| **S3** | Item físico + quality + lineage origin | 2 sem | **3** | ARCHITECT + BUILDER |
| **S4** | Granja NPC: plot/plant/irrigate/harvest | 3 sem | **4** | ARCHITECT + BUILDER + UI/UX |
| **S5** | Empresas + salaries automation | 2 sem | **3** | BUILDER + ARCHITECT |
| **S6** | Workplace app (job postings + apply) | 2 sem | **2** | UI/UX + BUILDER |
| **S7** | Granja player-foundable + sell NPC Mill | 3 sem | **4** | ARCHITECT + BUILDER + UI/UX |
| **S8** | Polish + closed beta + bug fixes | 3 sem | **3** | SPRINTER + UI/UX + SCRIBE |
| **TOTAL** | MVP playable | **22 sem** (~5 meses) | **29 sessions** | — |

> **29 sessions en 22 semanas = ~1.3 sessions/semana promedio.** Sessions más grandes (2-5h) pero menos frecuentes. Métrica clave: **velocity por sprint**, no per día.
>
> **Dinamismo:** si al planear un sprint detectas que un módulo pesa más de lo estimado → split en 2 sessions. Si pesa menos → merge. El número de la tabla es **guidance, no contrato**.

### 2.2 Critical path Oleada 1

```
S0 (Bridges + core)
  ↓
S1+S2 (Banco — bloquea TODO lo demás)
  ↓
S3 (Item — bloquea Granja, Inventory, Quality)
  ↓
S4 (Granja NPC)
  ↓
S5 (Empresa — necesario para Granja player-foundable)
  ↓
S6 (Workplace app)
  ↓
S7 (Granja player-foundable)
  ↓
S8 (Polish + Beta)
```

**No saltes sprints.** Sprint X depende de X-1. Si te tienta empezar S4 sin S3 done → STOP.

### 2.3 Session Type Taxonomy + Model Allocation

> **Principio fundamental:** cada session se etiqueta con **1 perfil** que determina qué modelo AI usar. Matching correcto = +30% velocity, -50% bugs.

#### 2.3.1 Los 6 perfiles de session

| Perfil | Emoji | Descripción | Ejemplos concretos |
|---|---|---|---|
| **ARCHITECT** | 🏗️ | Diseño arquitectónico, FSMs complejas, API contracts, refactor profundo, ADRs | Bridges Layer completo, FSM plot_state Granja, EventBus core, migrations schema |
| **BUILDER** | 🔧 | Implementación estándar, CRUD, patrones repetitivos, adapters | 6 T1 adapters, endpoints bank API, repeated DB queries |
| **ANALYZER** | 🔍 | Audit cross-file, cross-reference masivo, research libs | Auditar coherencia 29 docs, research compat ox_inventory v2.45 |
| **UI/UX** | 🎨 | Frontend React NUI, implementación diseño, polish visual | Tablet shell, banco UI, target zones granja, screenshots a código |
| **SPRINTER** | ⚡ | Tests, bug fixes, refactor mecánico, polish rápido | Smoke test script, fix latency leak, rename variable set, test harness |
| **SCRIBE** | 📝 | Docs updates, retros, ADR drafting, SESSION_LOG cleanup | Sprint retro, ADR-010 draft, update roadmap post-sprint |

#### 2.3.2 Model allocation matrix — Admirals (Opus-first strategy)

> **Decisión founder:** **Opus 4.7 = modelo principal** para backend Y frontend. Otros modelos son **auxiliares específicos** — usar solo cuando tiene sentido claro (ahorro capacidad, contexto masivo multimodal, iteración rápida pura).

| Perfil | **Modelo primary** | Modelo alternativa | Cuándo usar alternativa |
|---|---|---|---|
| 🏗️ ARCHITECT | **Opus 4.7** | Sonnet 4.6 | Opus rate-limited o tarea arquitectónica estándar (no crítica) |
| 🔧 BUILDER | **Opus 4.7** | Sonnet 4.6 / GPT-5.3 Codex | Patrón super repetitivo (6 adapters casi idénticos) → Sonnet/Codex ahorra Opus |
| 🔍 ANALYZER | **Gemini 3.1 Pro** | Opus 4.7 | Default Gemini por **contexto 2M+** para audit masivo. Opus si análisis requiere razonamiento profundo |
| 🎨 UI/UX | **Opus 4.7** | Gemini (multimodal) + Opus | Screenshots/videos de diseño → Gemini extrae specs → Opus implementa |
| ⚡ SPRINTER | **GPT-5.3 Codex** | Opus / Sonnet | Codex para iteraciones tests + refactor mecánico. Opus si bug misterioso requiere reasoning |
| 📝 SCRIBE | **Sonnet 4.6** | Opus | Sonnet ahorra Opus capacity para lo crítico. Opus solo si doc es foundational (ADR nuevo) |

#### 2.3.3 Reglas de decisión rápida

- **Si la session determina arquitectura del proyecto** (bridges, FSMs, API contracts) → **Opus, sin excepción.**
- **Si la session es backend Lua/business logic** → **Opus.**
- **Si la session es frontend React/NUI** → **Opus.**
- **Si la session es patrón repetitivo puro** (6 adapters clones) → Sonnet/Codex ahorra Opus para próximas sessions críticas.
- **Si la session requiere leer >20 archivos simultáneamente** → Gemini Pro (contexto).
- **Si la session es tests/bugs/refactor mecánico** → Codex.
- **Si la session es SCRIBE puro** → Sonnet.

#### 2.3.4 Handoff entre modelos (crítico)

Cuando un sprint usa 2+ modelos diferentes (normal), el **SESSION_LOG.md es el puente**. Modelo B al abrir session nueva:

1. Lee las **últimas 2-3 entries** del SESSION_LOG.
2. Lee específicamente la entry de **la session previa en este sprint** (handoff section).
3. Lee docs específicos listed en prompt.
4. NUNCA improvisa context — si falta algo → pregunta founder.

> **Ejemplo real:** S4.1 (Opus, ARCHITECT) diseña FSM plot_state + math engine. S4.2 (Sonnet, BUILDER si quieres ahorrar Opus) implementa callbacks. Sonnet lee entry S4.1 → conoce decisiones de Opus → implementa sin reinventar.

#### 2.3.5 Dinamismo por peso — cuándo split/merge

| Situación | Acción |
|---|---|
| Módulo estimado <300 LoC → resulta 150 LoC | Merge con próxima session (1 session en lugar de 2) |
| Módulo estimado 500 LoC → resulta 1200 LoC | Split: 1 ARCHITECT (diseño+núcleo) + 1 BUILDER (resto) |
| Session >3h sin progreso | STOP, cerrar, re-split, nueva session |
| Módulo mixing backend pesado + frontend pesado | Split: 1 session backend (Opus) + 1 session frontend (Opus) |
| Módulo trivial (migrations + 1 config file) | Merge con sprint siguiente inicial |

> **Regla oro:** **Calidad > velocidad.** Mejor 1 session que cierra limpio que 2 sessions apresuradas.

---

## 3. Anatomía de un Sprint

### 3.1 Ciclo completo

```
DÍA 1 (founder solo)         DÍA 1-15 (founder + AI)         DÍA 15 (founder solo)
┌──────────────────┐         ┌──────────────────────┐         ┌──────────────────┐
│  PLANNING        │   →     │  SESSIONS EJECUTIVAS │   →     │  RETRO + SIGN-OFF│
│  (30-60 min)     │         │  (5-8 sessions)      │         │  (30 min)        │
└──────────────────┘         └──────────────────────┘         └──────────────────┘
```

### 3.2 Planning (Día 1, founder solo, 30-60 min)

**Tu trabajo:**

1. Re-leer la spec del sprint en `planning/01_roadmap.md` §4.2 sub-sección correspondiente.
2. **Descomponer el sprint en 4-8 sessions concretas.** Cada session = 1 outcome.
3. Para cada session, escribir en una nota:
   - Goal (1 frase)
   - Files in scope (whitelist 5-15 archivos)
   - Files out of scope (no tocar)
   - Done criteria (3-5 bullets)
   - Estimated time (1-3h)
4. Crear entry en `progress/SPRINT_PLAN_S{N}.md` con el plan completo.

**Output:** un doc `SPRINT_PLAN_S{N}.md` que será el GPS del sprint.

> **Si no puedes descomponer el sprint en sessions, el sprint está mal-scopeado.** Un sprint que necesita "todo a la vez" es indicador de scope monstruoso.

### 3.3 Sessions ejecutivas (Días 2-14)

Una session por día (típico) o varias spread durante días. Cada una sigue **§4. Anatomía de una Session**.

### 3.4 Retro + Sign-off (Día 15, founder solo o + AI corta sesión)

**Tu trabajo:**

1. **Verificar done criteria del sprint** (de `roadmap.md`). Cada bullet ✅ o 🔴.
2. **Smoke test manual** del feature shipped (sigue `qa/01_testing_protocol.md`).
3. **Si todo ✅:** sign-off → bump version → commit + tag `git tag v0.{sprint}.0`.
4. **Si algo 🔴:** decidir entre:
   - (a) Slip sprint 1 semana extra para cerrarlo,
   - (b) Mover el item al siguiente sprint (si no es bloqueante).
5. **Retro escrita** en `progress/SPRINT_RETRO_S{N}.md` (~15 líneas):
   - Qué fue bien
   - Qué fue mal
   - Qué cambio para próximo sprint
   - Velocity actual (sessions usadas / estimadas)
6. **Update `progress/SESSION_LOG.md`** con marcador de cierre sprint.
7. **Bump `planning/01_roadmap.md`** con sprint completado checkmarks.

**Output:** sprint cerrado, codebase taggeada, retro escrita.

### 3.5 Done criteria SPRINT (genéricos)

- [ ] Todos los done criteria del sprint en `roadmap.md` cumplidos.
- [ ] Smoke test manual ✅.
- [ ] Sin tests skipped o disabled.
- [ ] Performance budgets `technical/06_fivem_standards.md` respetados (resmon <0.5ms idle, <2ms peak).
- [ ] Cero `TODO:` críticos sin owner asignado.
- [ ] Commits + tag aplicados.
- [ ] Retro escrita.

---

## 4. Anatomía de una Session

### 4.1 Pre-session (founder, 5 min)

1. **Abre `progress/SESSION_LOG.md`** y lee la última entry.
2. **Verifica el repo está limpio:** `git status` clean o solo WIP intencional.
3. **Localiza el siguiente session goal** en `progress/SPRINT_PLAN_S{N}.md`.
4. **Copia el prompt template** (§6) y rellena variables.
5. **Abre nueva conversación AI** (Cascade/Claude/etc.) en el workspace `d:\theBigProject\`.

### 4.2 Inicio de sesión (founder + AI, 5 min)

1. **Pega el prompt inicial** (template §6).
2. AI responde con un plan de la sesión (4-8 pasos).
3. **Tu validas el plan.** Si difiere de tu plan founder → corregir AHORA, no después.
4. AI procede.

### 4.3 During-session (founder + AI, 1-3h efectivos)

**Tu rol:**
- **Review decisiones clave.** Cuando AI propone algo no-trivial → leer + aprobar/rechazar.
- **Validar diffs.** No aceptes diffs que no entiendes — pide explicación.
- **Mantén scope.** Si AI propone "ya que estamos, también..." → STOP. Anotar para después, no expandir.
- **Confirma done criteria.** AI debe confirmar al final que cada bullet está cumplido.

**No hagas:**
- Cambios mid-session de scope (rompe el plan).
- Aceptar código sin leer summary AI.
- Ir cocinar dejando AI ejecutar 2h sin supervisión (NO).

### 4.4 Cierre de sesión (founder + AI, 10-15 min)

1. **AI escribe resumen sesión:**
   - Goal cumplido?
   - Done criteria checklist con ✅/🔴.
   - Files cambiados (lista breve).
   - Decisiones tomadas (≤3 bullets).
   - Issues pendientes / known limitations.
2. **AI escribe entry en `progress/SESSION_LOG.md`** (formato §5).
3. **Tu validas summary.** Si algo discrepa con tu observación → corregir entry log.
4. **Commit + push:**
   ```
   git add .
   git commit -m "S{N}.{M} {short description}"
   git push
   ```
5. **Si applicable, marcar todo en `SPRINT_PLAN_S{N}.md` como ✅.**
6. **Cierra la conversación AI.** No continúes 2h después en la misma — se degrada.

### 4.5 Post-session (founder solo, 0-30 min)

- Si hay algo unclear, anotar en `progress/QUESTIONS.md`.
- Si surge una decisión arquitectónica importante → considerar nuevo ADR (`planning/02_decision_log.md`).
- Brain off, descanso. La AI puede 8h. Tú no.

### 4.6 Done criteria SESSION (genéricos)

- [ ] Goal específico de la session cumplido.
- [ ] Code commits granulares + commit message descriptivo.
- [ ] Tests/smoke check pass localmente.
- [ ] `progress/SESSION_LOG.md` updated con entry.
- [ ] Files dentro del scope whitelist (no fuera).
- [ ] Sin `TODO:` críticos sin nombre + ticket.
- [ ] Founder ha leído summary AI.

---

## 5. Protocolo SESSION_LOG

### 5.1 Por qué SESSION_LOG existe

- AI agent **nuevo** llega → lee últimas 3-5 entries → recupera contexto en 5 min.
- Founder retoma proyecto **2 semanas después de pausa** → mismo, recupera contexto.
- Auditoría: "¿quién tomó la decisión X y cuándo?" → grep el log.
- Velocity tracking: "¿cuántas sessions este sprint? ¿estamos atrás?"

### 5.2 Ubicación

`d:\theBigProject\progress\SESSION_LOG.md` (en repo, committed).

### 5.3 Formato entry

```md
## S0.1 — Repo bootstrap + scaffolding

- **Fecha:** 2026-05-02
- **Duración:** 1h 45m
- **Founder + Agent:** yaboula + Cascade
- **Sprint:** S0 — Setup
- **Goal:** Repo skeleton + estructura carpetas + .gitignore + fxmanifest base + server.cfg dev.
- **Status:** ✅ Done

### Cambios
- Created: `resources/admirals_core/fxmanifest.lua`, `resources/admirals_bridges/fxmanifest.lua`, `.gitignore`, `server.cfg.example`, repo dir tree.
- Modified: —
- Deleted: —

### Decisiones tomadas
- Naming convention recursos: `admirals_*` (snake_case, prefix admirals_).
- Carpeta `resources/` en root, no `[admirals]/` (más simple, ningún reason para encapsular subdir cuando solo Admirals usa el server).

### Issues pendientes
- (ninguno)

### Handoff próxima sesión
- S0.2 puede empezar con `resources/admirals_bridges/` ya creado vacío.
- Lee `technical/07_bridges_compatibility.md` §2.2 antes para estructura interna.

### Files in scope respetados
✅ Solo tocó files dentro whitelist sesión.

---
```

### 5.4 Reglas log

- **Cada session escribe 1 entry.** No saltarse, no consolidar.
- **AI escribe el draft, founder valida.** No al revés.
- **Commit el log junto con el code change.** Atomicidad.
- **Append-only.** No editar entries antiguas (correcciones = entry nueva referenciando).
- **Ordenado cronológicamente.** Más recientes arriba o abajo (decide al inicio, mantén consistente).

> **Decisión Admirals:** entries más recientes **abajo** (append-only natural). Para leer las últimas, scroll bottom.

### 5.5 Reading protocol next session

Inicio de cada session, AI **debe** leer:
1. Últimas 3 entries SESSION_LOG (5 min).
2. `SPRINT_PLAN_S{N}.md` actual (3 min).
3. Docs relevantes a la session (variable, listed in prompt).

Total: ~15 min context recovery.

---

## 6. Plantilla prompt inicial nueva sesión

### 6.1 El template universal

Copy-paste, rellena `{VARIABLES}`, pega como primer mensaje en nueva conversación AI:

```md
# Admirals — Session {SESSION_ID}

## 0. Onboarding obligatorio

Antes de cualquier acción, lee EN ESTE ORDEN:

1. `docs/agents/00_BOOTSTRAP.md` v1.2 (15 min) — identidad proyecto + estado.
2. `docs/agents/02_working_conventions.md` (10 min) — cómo trabajamos.
3. `docs/agents/03_founder_playbook.md` §4-§5 (5 min) — anatomía session + log protocol.
4. `progress/SESSION_LOG.md` últimas 3 entries (5 min) — qué se hizo recientemente.
5. `progress/SPRINT_PLAN_S{N}.md` (3 min) — el plan del sprint actual.
6. Docs específicos de esta session: {DOCS_RELEVANTES}

Confirma que has leído todo antes de proceder.

---

## 1. Sesión actual

- **Session ID:** {SESSION_ID} (ej. S0.1, S2.3, S5.4)
- **Sprint:** {SPRINT_NAME}
- **Goal:** {GOAL_1_FRASE}
- **Duración estimada:** {1h-3h}
- **Founder:** yaboula

## 2. Scope

### Files IN scope (puedes editar):
{LISTA_FILES_WHITELIST}

### Files OUT of scope (NO tocar bajo ninguna circunstancia):
- Cualquier `docs/*` (firmados — solo founder los modifica).
- Cualquier file no listado arriba en "IN scope".
- `progress/SESSION_LOG.md` — solo append entry al final, no modificar entries anteriores.

## 3. Done criteria session

- [ ] {DONE_1}
- [ ] {DONE_2}
- [ ] {DONE_3}
- [ ] {DONE_4}
- [ ] Code compila / FiveM resource carga sin errores.
- [ ] Smoke check manual descrito en §4.
- [ ] Entry en `progress/SESSION_LOG.md` añadida (formato playbook §5.3).
- [ ] Resumen final con ✅/🔴 per criterio.

## 4. Smoke check

{INSTRUCCIONES_VERIFICACIÓN_MANUAL}

## 5. Protocolo

- Sigue todos los principios `agents/02_working_conventions.md`.
- NO inventes números — usa SSoTs (`economy/*`, `technical/*`).
- NO toques files OUT of scope.
- NO empieces nuevo trabajo si done criteria no claros — pregúntame primero.
- Si propones algo no-trivial, espera mi green-light antes de implementar.
- Si encuentras un bug en docs firmados → reporta, NO arregles unilateralmente.

## 6. Comienza

1. Lee onboarding.
2. Confirma con un summary breve (≤200 palabras): "He leído X, Y, Z. La session es Z. Plan: 1) A 2) B 3) C. ¿Procedo?"
3. Espera mi "Procede" antes de tocar código.
```

### 6.2 Por qué este formato funciona

- **Onboarding obligatorio reduce hallucinations 80%.** AI con contexto de los 27k líneas docs ≠ AI improvisando.
- **Files in/out of scope previene scope creep.** AI literal no toca lo que no está en lista.
- **Done criteria explícitos = sign-off objetivo.** No "creo que está bien".
- **Espera green-light antes de codear** = founder catches el plan errado en 30s en lugar de 2h después.
- **Summary final con ✅/🔴** = retrospección honest.

### 6.3 Variantes del prompt

#### Variante "session corta de bug fix" (<30 min)
Skip `progress/SPRINT_PLAN_S{N}.md` reading. Lee solo última entry log + el doc del bug. Use el formato compacto.

#### Variante "session de exploración / research"
Output: doc en `progress/RESEARCH_*.md`, NO código. Goal = entender opciones, no implementar.

#### Variante "session de refactor"
ADD: "Lee primero el código existente en {paths}. Refactor PRESERVA behavior. Tests pasan idénticos antes/después."

---

## 7. Workspace config Cascade/Windsurf

### 7.1 Workspace rules (auto-aplicadas cada session)

Crea `.windsurf/rules/admirals.md` con:

```md
---
trigger: always_on
description: Admirals project core rules
---

# Admirals — Workspace Rules (auto-applied)

## Identity
- Proyecto: Admirals (FiveM premium server, economía profunda).
- Founder: yaboula. Comunicación directa español + tecnicismos inglés OK.
- AI role: pair programmer experto, no junior.

## SSoTs canónicos (si conflicto, prevalecen)
- `docs/00_PRODUCT_BIBLE.md` — filosofía
- `docs/economy/01_economic_model.md` — números económicos
- `docs/technical/02_events_catalog.md` — eventos
- `docs/technical/03_db_schema.md` — DB
- `docs/technical/04_api_contracts.md` — APIs
- `docs/technical/05_state_machines.md` — FSMs
- `docs/technical/06_fivem_standards.md` — perf+sec+sync
- `docs/technical/07_bridges_compatibility.md` — bridges layer

## Stack
- FiveM Lua server + JS/TS React Tablet (NUI) + MySQL + State Bags.
- QBox primary, QBCore compat, ESX limited — TODO via Bridges layer.
- NUNCA llamar `exports['qb-*']` ni `ESX.*` fuera de `resources/admirals_bridges/adapters/*`.

## Hard constraints
- NO XP genérico. NO PvP combat. NO pay-to-win. NO QTEs.
- NO crear files en docs/* sin instrucción explícita founder.
- NO modificar `progress/SESSION_LOG.md` entries antiguas (append-only).
- NO ejecutar comandos destructivos sin aprobación founder.
- NO push código que rompa boot del server (smoke check primero).

## Code style
- Lua: 2 spaces indent, snake_case functions/vars, PascalCase modules.
- JS/TS: Prettier defaults, 2 spaces, single quotes, no semicolons opcional consistente per file.
- SQL: UPPERCASE keywords, snake_case tables/columns, prefijo `admirals_*` toda tabla.
- Commits: `S{N}.{M} {imperative present}` ej. "S0.1 add fxmanifest scaffolding".

## Anti-patterns prohibidos
- "¡Tienes razón!" / "Excelente pregunta!" / preámbulos de validación → JUMP STRAIGHT a la respuesta.
- Recreate file when modify suffices.
- Hallucinated numbers (siempre cita SSoT con line citation).
- Hallucinated APIs (verifica grep antes de inventar).
- Workarounds downstream sin atacar root cause.
- Eliminar tests sin justificación firmada.
- Anunciar "subagents" o roles paralelos (ADR-001 archivado — workflow secuencial siempre).

## Workflow
- Pre-action: confirmar plan con founder antes de >2 file edits.
- Cada session escribe 1 entry en `progress/SESSION_LOG.md` al final (formato `agents/03_founder_playbook.md` §5.3).
- Termina sesión con summary ✅/🔴 per done criterion.

## Trust hierarchy
1. Founder green-light (highest)
2. SSoTs docs firmados
3. ADRs accepted
4. Code existente
5. AI training knowledge (lowest — verify)
```

### 7.2 Memorias persistentes

Las memorias creadas durante este checkpoint (BOOTSTRAP + estado) ya cubren lo principal. Cuando empieces sesión nueva con nuevo agent (otro modelo o conversación fresh), si las memorias no aparecen, **pega manualmente al inicio del prompt:**

```
**Memoria del proyecto** (paste si AI no tiene contexto):
- 29 docs firmados (~27.260 líneas), Oleada 0 cerrada 100%.
- MVP Oleada 1 = Granja (no Bakery) per ADR-008.
- Bridges Layer foundational per ADR-009.
- Subagents archivados per ADR-001 — workflow secuencial.
- QBox primary, ox_inventory, ox_target, lb-phone — T1 oficial.
```

### 7.3 Workflows / slash commands sugeridos

Crea en `.windsurf/workflows/`:

#### `.windsurf/workflows/start-session.md`
```md
---
description: Iniciar nueva session AI con onboarding completo
---
1. Verifica `git status` clean.
2. Read `progress/SESSION_LOG.md` últimas 3 entries.
3. Read `progress/SPRINT_PLAN_S<N>.md` actual.
4. Pregunta al founder: "¿Cuál session ID y goal?"
5. Espera respuesta antes de proceder.
```

#### `.windsurf/workflows/close-session.md`
```md
---
description: Cerrar session con sign-off + log + commit
---
1. Verifica done criteria todos ✅.
2. Smoke check passed.
3. AI escribe entry SESSION_LOG.md.
4. Founder valida entry.
// turbo
5. `git add .`
// turbo
6. `git commit -m "S<N>.<M> <descripción>"`
7. Pregunta founder si push o seguir local.
```

#### `.windsurf/workflows/sprint-retro.md`
```md
---
description: Cerrar sprint con retro + tag + bump roadmap
---
1. Verifica todos session done este sprint.
2. Smoke test sprint completo manual.
3. AI escribe `progress/SPRINT_RETRO_S<N>.md`.
4. Founder valida retro.
5. Update `docs/planning/01_roadmap.md` con sprint ✅.
6. `git tag v0.<sprint>.0`
7. Push tag + commits.
```

### 7.4 MCP tools opcionales (futuro)

No necesarios Sprint 0-2. Considerar Oleada 2:
- **GitHub MCP** para issues/PRs automation.
- **Database MCP** para query MySQL desde AI.
- **Linear/Jira MCP** si scaling team.

---

## 8. Tu checklist como supervisor

### 8.1 Pre-session (5 min)

- [ ] `git status` limpio.
- [ ] Última entry `SESSION_LOG.md` leída.
- [ ] Goal session claro en mi cabeza.
- [ ] Files in/out scope decididos.
- [ ] Prompt template rellenado.
- [ ] Café preparado. ☕

### 8.2 During-session

- [ ] AI compartió plan inicial → validé.
- [ ] Cada decisión no-trivial → leí + aprobé.
- [ ] Cada diff >50 líneas → leí summary.
- [ ] Scope creep detectado → corté inmediatamente.
- [ ] Si AI confused → reset con context fresco, no insistir.

### 8.3 Post-session (15 min)

- [ ] Done criteria todos validados ✅.
- [ ] Smoke check ejecutado.
- [ ] Entry SESSION_LOG.md añadida + revisada.
- [ ] Commit + push hecho.
- [ ] Conversación AI cerrada (no reuse 2h después).

### 8.4 Bandera roja indicators

🚩 Si **alguno de estos** ocurre, **PARA Y DEBUG:**

| Síntoma | Causa probable | Acción |
|---|---|---|
| AI propone cambios fuera scope | Prompt no claro | Reset session con scope estricto |
| AI re-implementa algo existente | No leyó SESSION_LOG | Restart con onboarding completo |
| Diff incomprehensible | Code style off OR AI confundió | Reject, pedir explicación step-by-step |
| AI se contradice con doc firmado | Hallucination | Cite specific line SSoT, force re-read |
| Done criteria todos ✅ pero algo no funciona | False completion | Re-run smoke check, force fix |
| Session >3h sin progreso | Scope demasiado grande | Cerrar session, re-split en 2 sessions |

---

## 9. Cuándo cerrar sprint y pasar al siguiente

### 9.1 Decision tree

```
¿Done criteria sprint todos ✅?
├─ SÍ
│   └─ ¿Smoke test pass end-to-end?
│       ├─ SÍ → Sign-off + tag + retro + next sprint
│       └─ NO → Fix smoke issues (1-3 días), re-evaluar
└─ NO
    └─ ¿Cuántos 🔴 hay?
        ├─ 1-2 menores → Mover a próximo sprint, sign-off resto
        ├─ 1-2 críticos → Slip 1 semana, fix
        └─ >2 críticos → Slip 2 semanas o re-scope sprint
```

### 9.2 Sign-off ceremony (30 min, founder solo)

1. **Open `roadmap.md` §4.2 sprint actual.** Check each done criterion.
2. **Smoke test sprint feature** según `qa/01_testing_protocol.md`.
3. **Si ✅ all:**
   ```bash
   git tag v0.{sprint_num}.0
   git push --tags
   ```
4. **Update `roadmap.md`:** sprint marked ✅ con date.
5. **Write `progress/SPRINT_RETRO_S{N}.md`** (15 min).
6. **Update `agents/00_BOOTSTRAP.md`** si state significantly changed.
7. **Close sprint**, descansa 1-2 días antes de empezar próximo.

### 9.3 Anti-pattern: "perpetual sprint"

🚩 Sprint que lleva 5 semanas y "casi cerrado" → **STOP.** Indicators:
- Founder burnout creciente.
- 30%+ items 🔴 al "cierre".
- Slipping cada review.

**Acción correctiva:**
1. Cancelar sprint actual oficialmente.
2. Re-split en 2 sprints más pequeños.
3. Lo done = sprint cerrado parcial, lo restante = nuevo sprint.
4. Aceptar slip 1-2 semanas total y mover.

> **Mejor cerrar parcial que perfeccionismo paralizante.**

---

## 10. Sprint 0 detallado — Ejemplo aplicado

### 10.1 Vista general Sprint 0

- **Goal:** Setup repo + Bridges Layer funcional + admirals_core skeleton + first migration + smoke test pass.
- **Duración:** 3 semanas (~21 días).
- **Sessions:** **4** (no 6 — reducción per §2.3 estrategia dinámica).
- **Done criteria:** founder ejecuta server local, FiveM client conecta, migraciones aplican, boot report bridges correcto, resmon <0.5ms idle.

### 10.2 Sessions plan

#### S0.1 — Repo scaffolding + operacionales 🔧 BUILDER + 📝 SCRIBE

- **Modelo:** **Sonnet 4.6** (no amerita Opus — tarea estructural estándar).
- **Duración:** 2h.
- **Goal:** Repo estructura + `.gitignore` + `server.cfg.example` + fxmanifest scaffolds + `README.md` + `progress/SESSION_LOG.md` con primera entry + `progress/SPRINT_PLAN_S0.md` + commit + push GitHub.

**Files in scope:**
- `README.md` (nuevo, root repo)
- `.gitignore`
- `server.cfg.example`
- `resources/admirals_bridges/fxmanifest.lua` (scaffold vacío)
- `resources/admirals_core/fxmanifest.lua` (scaffold vacío)
- `progress/SESSION_LOG.md` (con entry S0.1)
- `progress/SPRINT_PLAN_S0.md` (con 4 sessions detail)
- `.windsurf/rules/admirals.md` (workspace rule)
- `.windsurf/workflows/start-session.md`, `close-session.md`, `sprint-retro.md`

**Files OUT of scope:**
- `docs/*` (todos firmados, no tocar)
- Cualquier archivo `.lua` con lógica real (scaffolds fxmanifest únicamente)

**Done criteria:**
- [ ] Repo structure creada exactamente como spec.
- [ ] `.gitignore` cubre Lua/Node/IDE/OS artifacts.
- [ ] `server.cfg.example` tiene sections: endpoints + resources + sv_hostname + convars + sv_licenseKey.
- [ ] 2 fxmanifest válidos (fx_version, game, author, version, dependencies placeholder).
- [ ] README root con: quick start + repo structure + links a docs clave.
- [ ] `progress/SESSION_LOG.md` con primera entry formato playbook §5.3.
- [ ] `progress/SPRINT_PLAN_S0.md` con las 4 sessions documentadas.
- [ ] Workspace rules Cascade funcionando.
- [ ] Git init + first commit + push a `https://github.com/yaboula/admirals.git`.

#### S0.2 — Bridges Layer completo 🏗️ ARCHITECT

- **Modelo:** **Opus 4.7** (crítico — arquitectura que afecta TODO downstream).
- **Duración:** 4-5h.
- **Goal:** `admirals_bridges` resource completo: Registry + Dispatcher + Logger + 6 bridge interfaces + 6 native fallbacks + auto-detection + config overrides + boot report.

**Files in scope:**
- `resources/admirals_bridges/fxmanifest.lua` (full)
- `resources/admirals_bridges/config.lua`
- `resources/admirals_bridges/server/init.lua` (boot + auto-detection)
- `resources/admirals_bridges/server/registry.lua`
- `resources/admirals_bridges/server/dispatcher.lua`
- `resources/admirals_bridges/server/logger.lua`
- `resources/admirals_bridges/server/detect.lua` (auto-detection resource presence)
- `resources/admirals_bridges/bridges/bank.lua`
- `resources/admirals_bridges/bridges/inventory.lua`
- `resources/admirals_bridges/bridges/phone.lua`
- `resources/admirals_bridges/bridges/identity.lua`
- `resources/admirals_bridges/bridges/target.lua`
- `resources/admirals_bridges/bridges/notify.lua`
- `resources/admirals_bridges/adapters/bank/native.lua`
- `resources/admirals_bridges/adapters/inventory/native.lua`
- `resources/admirals_bridges/adapters/phone/native.lua`
- `resources/admirals_bridges/adapters/identity/native.lua`
- `resources/admirals_bridges/adapters/target/native.lua`
- `resources/admirals_bridges/adapters/notify/native.lua`

**Files OUT of scope:**
- `resources/admirals_bridges/adapters/*/qbox.lua` y T1 externos (S0.3)
- `resources/admirals_core/*` (S0.4)

**Done criteria:**
- [ ] Registry API: `Bridges.RegisterAdapter`, `Bridges.GetAdapter`, `Bridges.ListAdapters`.
- [ ] Dispatcher API: `Bridges.Bank`, `Bridges.Inventory`, etc. routing a adapter activo.
- [ ] Logger con niveles Info/Warn/Error/Audit + boundary logging toggle.
- [ ] Auto-detection scan `GetResourceState()` per adapter conocido + priority order.
- [ ] Config overrides vía convars (`admirals_bridge_bank=native|qbox|...`).
- [ ] Cada bridge tiene interfaz Lua completa según `technical/07_bridges_compatibility.md` §4-§9.
- [ ] Cada native adapter implementa **todos** los métodos de su bridge (con stub o lógica mínima — no errores runtime).
- [ ] Boot report visible console al start con tier count + active adapter per module.
- [ ] Resource carga sin errores en FiveM server vacío (solo oxmysql + mysql-async).
- [ ] Smoke: con server vacío → 6 modules → native. Con ox_inventory presente → inventory → ox_inventory (pendiente S0.3, aquí solo auto-detection logs intent).

#### S0.3 — Bridges T1 adapters externos 🔧 BUILDER

- **Modelo:** **Sonnet 4.6** (patrón repetitivo — 6 adapters similares — Sonnet ahorra Opus capacity).
- **Duración:** 3h.
- **Goal:** 6 adapters Tier 1 completos: QBox bank + identity, ox_inventory, ox_target, ox_lib notify, lb-phone.

**Files in scope:**
- `resources/admirals_bridges/adapters/bank/qbox.lua`
- `resources/admirals_bridges/adapters/identity/qbox.lua`
- `resources/admirals_bridges/adapters/inventory/ox_inventory.lua`
- `resources/admirals_bridges/adapters/target/ox_target.lua`
- `resources/admirals_bridges/adapters/notify/ox_lib.lua`
- `resources/admirals_bridges/adapters/phone/lb_phone.lua`
- `resources/admirals_bridges/fxmanifest.lua` (update server_scripts list)
- `scripts/test_adapter.lua` (harness skeleton)

**Files OUT of scope:**
- `resources/admirals_core/*` (S0.4)
- T2 adapters (QBCore, ESX) — fuera MVP

**Done criteria:**
- [ ] 6 T1 adapters implementan interfaces completas (mapping a exports reales QBox/ox_*/lb-phone).
- [ ] Auto-detection los elige cuando scripts presentes.
- [ ] Fallback a native si script ausente.
- [ ] `scripts/test_adapter.lua` con harness básico (no full tests, solo skeleton ejecutable).
- [ ] Smoke: server con QBox + ox_inventory + ox_target + ox_lib + lb-phone → boot report muestra "T1 official" per module.

#### S0.4 — admirals_core skeleton + migrations + smoke test 🏗️ ARCHITECT + ⚡ SPRINTER

- **Modelo:** **Opus 4.7** (core FSM + migrations = arquitectura foundational).
- **Duración:** 4h.
- **Goal:** `admirals_core` resource completo: EventBus + DB wrappers + RateLimiter + Logger + Metrics + Migrations runner + 2 primeras migrations + smoke test manual checklist + sprint sign-off.

**Files in scope:**
- `resources/admirals_core/fxmanifest.lua` (full, dependency `admirals_bridges`)
- `resources/admirals_core/config.lua`
- `resources/admirals_core/server/init.lua` (boot order)
- `resources/admirals_core/server/event_bus.lua`
- `resources/admirals_core/server/db.lua` (oxmysql wrapper)
- `resources/admirals_core/server/rate_limiter.lua`
- `resources/admirals_core/server/logger.lua`
- `resources/admirals_core/server/metrics.lua`
- `resources/admirals_core/server/migrations.lua` (runner)
- `resources/admirals_core/migrations/001_schema_versions.sql`
- `resources/admirals_core/migrations/002_core_tables.sql` (subset foundational de `technical/03_db_schema.md`)
- `scripts/smoke_test.md` (manual checklist 10 puntos)
- `progress/SPRINT_RETRO_S0.md` (al cierre)

**Files OUT of scope:**
- Tablas completas de todos módulos (solo foundational core: accounts, bank_accounts, schema_versions, audit_log — lo mínimo para boot).
- Frontend / NUI (S1+).

**Done criteria:**
- [ ] EventBus: publish/subscribe wrapper + rate limiting integration.
- [ ] DB wrappers: `DB.FetchOne`, `DB.FetchAll`, `DB.Execute`, `DB.Transaction` (oxmysql).
- [ ] RateLimiter: token bucket per citizenId, config per endpoint.
- [ ] Logger estructurado + rotación básica.
- [ ] Metrics counters: events_emitted, db_queries, bridge_calls, errors_total.
- [ ] Migrations runner: idempotente, SHA-256 checksum verification, aplica en orden `NNN_*.sql`, tracking en `admirals_schema_versions`.
- [ ] Migration 001 crea tabla `admirals_schema_versions`.
- [ ] Migration 002 crea tablas foundational (ver doc `technical/03_db_schema.md` para subset exacto).
- [ ] `scripts/smoke_test.md` con 10 pasos manuales completos (según playbook §10.3).
- [ ] Founder ejecuta smoke test → 10/10 ✅.
- [ ] Tag `v0.0.0` aplicado + push.
- [ ] Retro `progress/SPRINT_RETRO_S0.md` escrita.
- [ ] Roadmap `docs/planning/01_roadmap.md` §4.2 S0 marked ✅.

### 10.3 Smoke test final Sprint 0 (tras S0.4)

```
SMOKE TEST — Sprint 0 (manual, 15 min)

[ ]  1. `git clone <repo>` desde cero.
[ ]  2. Configura `server.cfg.example` → `server.cfg` con DB credentials.
[ ]  3. Inicia server FiveM (`run.sh` o `run.cmd`).
[ ]  4. No errors en console.
[ ]  5. Boot report Bridges aparece.
[ ]  6. Migrations aplican (mensaje "002_core_tables.sql applied").
[ ]  7. DB tiene tablas creadas (verifica MySQL Workbench).
[ ]  8. Conecta player FiveM → joins server.
[ ]  9. Player ve mensaje "Welcome to Admirals dev" (chat o notify).
[ ] 10. `resmon` muestra `admirals_core` <0.5ms idle.
```

Si los 10 ✅ → **Sprint 0 done**, tag, retro, descanso, prep S1.

---

## 11. Anti-patterns founder

### 11.1 Los 7 errores fatales

| # | Error | Por qué fatal | Antídoto |
|---|---|---|---|
| 1 | **Dejar AI ir libre sin scope** | Entropy after 2h. Codebase becomes Frankenstein. | Files in/out scope SIEMPRE. |
| 2 | **Aceptar diff sin leer** | "Looks fine" → bug latente meses. | Read summary AI obligatorio. Si >100 líneas, leer diff. |
| 3 | **Cambiar requerements mid-session** | Scope creep dinámico = AI confundida. | Anota cambios para próxima session. |
| 4 | **No commit per session** | Imposible reverse cherry-picking. | Commit obligatorio cierre session. |
| 5 | **Olvidar SESSION_LOG entry** | Próxima session AI parte de cero. | AI escribe entry obligatoria. |
| 6 | **Tratar AI como junior subordinada** | AI es pair experto en prompt fluency, no junior. Confronta cuando estás errado. | Pair programming relación, no jefe-empleado. |
| 7 | **Trabajar 8h seguidas con AI** | Founder fatigue → decisions terribles. | Max 3 sessions/día. Descanso obligatorio. |

### 11.2 Señales que estás en mal camino

- Lleva 3 días sin cerrar 1 session. → Scope wrong, re-split.
- 5 sessions seguidas con bugs cruzados. → Sprint scope demasiado grande, slip.
- AI sugiere "X" y tú dudas → siempre. → Falta sleep, descansa.
- Te emociona añadir feature no en roadmap. → SCOPE CREEP, anótalo Oleada 2.
- Olvidaste cuál es S{N} actual. → Lee playbook + SESSION_LOG, nunca improvises.

---

## 12. FAQ

### 12.1 ¿Qué hago si AI se confunde mid-session?

1. **No insistas.** Repetir el mismo prompt = mismos errores.
2. **Reset:** cierra conversación actual, abre nueva, paste prompt template fresh.
3. **Reduce scope:** quizás la session era demasiado grande. Re-split.
4. **Si persiste:** cambia modelo AI (Cascade → Claude → GPT-5).

### 12.2 ¿Cómo recupero contexto si AI nuevo (días/semanas después)?

1. AI nueva lee onboarding (BOOTSTRAP + working_conventions + playbook).
2. AI lee últimas 5 entries SESSION_LOG.
3. AI lee SPRINT_PLAN actual.
4. AI lee últimos 3 commits (`git log -3`).
5. Total: 20 min context recovery. Ready.

### 12.3 ¿Y si necesito cambiar scope mid-session?

- **Ideal:** no lo cambies. Anota en `progress/QUESTIONS.md` para próxima session.
- **Si urgente:** explícito al AI "PIVOT: cambio scope a X. Confirma plan revisado antes de continuar."

### 12.4 ¿Cuántas sessions/día son sostenibles?

- **1 session/día:** rítmico, sostenible meses. ✅ Recomendado solo founder.
- **2-3 sessions/día:** sprint intenso, sostenible 2-3 semanas. OK.
- **4+ sessions/día:** burnout en 1 semana. ❌ Evita.

### 12.5 ¿Qué hacer cuando un sprint slips?

1. **Aceptar slip de 1 semana sin drama.** Pasa.
2. **Si slip >2 semanas:** retro emergency. Re-scope.
3. **Si slip 4+ semanas:** considera pause + re-plan. Posible decisión arquitectónica errada upstream.

### 12.6 ¿Y si AI propone una idea que contradice un doc firmado?

- **Defaults:** SSoT firmado gana siempre.
- **Excepción:** si la idea AI es objetivamente mejor + tú estás de acuerdo → nuevo ADR superseding old SSoT, NO cambio silencioso.

### 12.7 ¿Cuándo crear nuevo ADR vs solo session log entry?

- Decisión que afecta >1 sprint o cambia arquitectura → ADR.
- Decisión session-local (qué nombre dar a variable) → session log.
- Si dudas → ADR (mejor over-document que under-).

### 12.8 ¿Y si AI rompe code firmado por error?

1. `git diff` para ver qué.
2. `git checkout HEAD -- {file}` para revertir.
3. Anota en QUESTIONS.md el incidente.
4. Si recurrente → review .windsurf/rules/ y prompts.

### 12.9 ¿Founder puede saltar sessions de planning?

- **NO.** Planning es 30 min. Si lo saltas, las sessions ejecutivas te tomarán 3x más. False economy.

### 12.10 ¿Y si quiero parar el proyecto 1 mes (vacaciones)?

- Cierra sprint actual o pausa explícita.
- Escribe entry "PAUSE — back YYYY-MM-DD" en SESSION_LOG.
- Cuando vuelvas: AI nueva onboarding completo (no shortcut), 1 session de "rampup" antes de productiva.

---

## 13. Cierre + estado del documento

### 13.1 Estado

- **Versión:** 1.0 (firmado, living document).
- **Próxima revisión:** post Sprint 0 con learnings reales (qué del playbook funcionó, qué no).

### 13.2 Maintenance

Update este doc cuando:
- Patrones de session emergent (ej. "session de hotfix" frecuente → añadir variante template).
- Workflow nuevo descubierto (ej. AI tool pattern X funciona mejor).
- Anti-pattern identificado en práctica.
- Founder cambia preferencias de trabajo.

### 13.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción completa. 13 secciones cubriendo modelo mental jerárquico Oleada→Sprint→Session, anatomía cada nivel, SESSION_LOG protocol, plantilla prompt universal, workspace config Cascade/Windsurf, checklist supervisor, sign-off ceremony, Sprint 0 detallado con 6 sessions, anti-patterns founder, FAQ. **Living document.** |

---

## 14. TL;DR — Para el founder

Si por alguna razón solo lees 5 minutos, **esto es lo crítico:**

1. **Jerarquía:** Oleada → Sprint (2-3 sem) → Session (1-3h).
2. **Cada session:** prompt template §6 + scope strict + done criteria + log entry.
3. **Cada sprint:** planning Día 1 + sessions Días 2-14 + retro Día 15.
4. **SESSION_LOG.md** es la memoria del proyecto. Append-only. Cada session escribe.
5. **Workspace rules** `.windsurf/rules/admirals.md` aplicada always_on.
6. **Anti-patterns founder #1-7:** scope creep, no leer diffs, no commit, no retros, AI 8h sin descanso.
7. **Cuándo cerrar sprint:** todos done criteria ✅ + smoke test pass + retro escrita.
8. **Cuándo pausa:** si 5 sessions seguidas con bugs → algo upstream wrong.
9. **29 sessions estim Oleada 1** en 22 semanas. Velocity = 1.3/semana.
10. **Sprint 0 = 4 sessions** detalladas en §10 (S0.1 Sonnet, S0.2 Opus ARCHITECT, S0.3 Sonnet BUILDER, S0.4 Opus ARCHITECT+SPRINTER).
11. **Model allocation §2.3:** Opus 4.7 = primary backend+frontend. Otros auxiliares (Sonnet patterns repetitivos, Gemini contexto masivo/multimodal, Codex iteraciones rápidas tests).

> **Tu objetivo es supervisar bien. La AI codeará bien si tú dictas bien el qué. El playbook te asegura que dictas bien.**

---

*"El founder no escala su tiempo escribiendo más código. Escala su tiempo supervisando mejor a quien sí lo escribe."*

**FIN DEL DOCUMENTO `agents/03_founder_playbook.md` v1.0**
