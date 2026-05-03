# 🗺️ SONAR — Master Roadmap

> **Versión:** 1.5 (refinement post-pivot SONAR — NOTICE r1 top-level establece interpretación canonical post-ADR-011/012; §1-§15 legacy v1.4 inline preserved con surgical surface rename + Sprint 2 bump DIFERIDO + pivot phase status).
> 🏆 **SPRINT 1 CERRADO** (2026-05-02, Admirals heritage preserved). 🔄 **PIVOT IDENTITY Admirals → SONAR en ejecución multi-phase** (2026-05-03 ongoing — ADR-011 foundational + ADR-012 refinement). **Sprint 2 DIFERIDO** hasta Phase 10 smoke regression complete. Tablet shell + Bank app + Map app bloqueados por Phases 4-12.
> **Tipo:** Planning operacional. **Roadmap maestro del proyecto SONAR (ex-Admirals).** SSoT para fases, milestones, dependencias y criterios de "done".
> **Documento padre:** `agents/00_BOOTSTRAP.md` v1.5 (firmado post-pivot).
> **Documento hermano:** `planning/02_decision_log.md` v1.4 (12 ADRs incl. ADR-011 + ADR-012).
> **Documentos referenciados:** todos los docs `design/`, `art/`, `economy/`, `gameplay/`, `technical/` ya firmados + briefs v2 `art/briefs/` (5/5 delivered).
> **Estado:** firmado (living document — actualizar tras cada sprint + al completar cada Phase pivot 4-12).

> **Lectura previa obligatoria:** `agents/00_BOOTSTRAP.md` v1.5 completo, `00_PRODUCT_BIBLE.md` v1.4 §1 identidad (post-pivot), **`docs/planning/02_decision_log.md` ADR-011 + ADR-012 (pivot foundational + refinement)**, **`docs/art/01_art_direction.md` v2.0-scaffold-r7 NOTICE r6** (canonical visual direction), **`progress/PRE_S2_CHECKLIST.md` v1.3+** (hard blockers + decisiones founder pendientes pre-S2).

---

## 🔄 REFINEMENT NOTICE r1 (post ADR-011 + ADR-012, 2026-05-03)

**Este documento fue firmado v1.4 pre-pivot SONAR — naming "Admirals" + Sprint 2 "Next" immediate + criteria Tablet/Banco pre-pivot.** ADR-011 + ADR-012 refinan identity canonical foundational. **NOTICE r1 establece la interpretación vigente post-pivot**; en cualquier conflicto entre lo siguiente y §1-§15 abajo, **gana este NOTICE + ADR-011/012 + PRE_S2_CHECKLIST.md**.

### NEW CANONICAL — vigente desde 2026-05-03

#### Naming canonical (DEPRECATED heritage "Admirals" producto)
- **Producto:** SONAR (no Admirals).
- **Tablet:** SONAR Tablet (no Admirals Tablet).
- **Sistema operativo:** SonarOS (no AdmiralsOS).
- **App Banca:** SONAR Bank app (no Banca Admirals).
- **Marketplace global Oleada 3+:** Marketplace SONAR.
- **Code namespace legacy:** `admirals_bank`, `admirals_core`, `admirals_bridges`, tablas SQL `admirals_*`, eventos `admirals:*` — preservados legacy hasta **Phase 8 code refactor + Phase 9 DB migration 009** per ADR-011 §5.5.8 excepciones permitidas. Schedule Phase 8+9 pending D3 founder decision (ver `PRE_S2_CHECKLIST.md` §D3).

#### Estado Sprint 2 — DIFERIDO (DEPRECATED "Next immediate")
- Sprint 2 (Tablet shell + Bank app) **NO arranca** hasta completar Phases 4-12 pivot execution.
- Hard blockers pre-S2 en `progress/PRE_S2_CHECKLIST.md` v1.3+ (5 blockers B1-B5 + 3 decisiones founder D1-D3 + 5 soft-opcionales S1-S5).
- SPRINT_PLAN_S2.md redacción pending D1 (scope UI-heavy vs tech-balanced) + D3 (namespace migration timing) founder decisions.
- B1 Phase 6 mass-purge operational docs 1/8 complete (`02_sonar_tablet.md` v1.2 done S1.8). Este doc 8/8 cierra con v1.5 surgical bump.

#### Pivot phases roadmap resumido
- **Phase 1 ADR-011** ✅ accepted 2026-05-03 (rebrand foundational Admirals→SONAR).
- **Phase 1.5 ADR-012** ✅ accepted 2026-05-03 (refinement metáfora abstract + hybrid theme + voz neutral).
- **Phase 2-4 art_direction scaffold + r6 NOTICE + r7 surgical** ✅.
- **Phase 4.5 v2 specialist briefs (5/5)** ✅ (logo + icons + sound + motion + marketing).
- **Phase 5 light Bible v1.4 + BOOTSTRAP v1.5** ✅.
- **Phase 6 mass-purge operational docs** 🟡 1/8 done (`02_sonar_tablet.md`), 7/8 pending.
- **Phase 7 full design/gameplay/economy docs rewrite** 🔴 pendiente.
- **Phase 8 code refactor `admirals_*` → `sonar_*` namespace** 🔴 pendiente (depende D3).
- **Phase 9 DB migration 009** 🔴 pendiente (depende D3).
- **Phase 10 smoke regression** 🔴 pendiente (gate pre-S2).
- **Phase 11 workspace migration** 🔴 pendiente.
- **Phase 12 Sprint 2 arranque** 🔴 bloqueado por Phases 6-10.

#### Cómo leer el resto del documento (§1-§15)

1. **Lee primero este NOTICE r1 + ADR-011 + ADR-012 + `00_BOOTSTRAP.md` v1.5.**
2. **Filosofía planning + principios + dependencies + risk register + sprint structure + estimation + KPIs (§1, §7-§13) siguen válidos** — pivot-agnostic completo.
3. **§3 Oleada 0 + §4.2 Sprint 0 + §4.2 Sprint 1 = HISTÓRICO inmutable** — Admirals heritage preservado (ADRs 008-010, commits, tags `v0.0.0`/`v0.1.0`/`sprint-1-complete`, entries SESSION_LOG) per ADR-011 §5.5.8 excepciones.
4. **§4.2 Sprint 2 rewrite inline** refleja Sprint 2 DIFERIDO + scope options founder D1.
5. **§4.2 Sprints 3-8 mantienen gameplay mechanics pivot-agnostic** (Granja / Empresa / Workplace / etc.). Refs "Tablet" = SONAR Tablet implícito. Refs code `admirals_*` = legacy namespace hasta Phase 8+9.
6. **§5-§6 Oleadas 2+ mantienen visión pivot-agnostic.** Refs producto "Admirals" superseded → SONAR.
7. **§14.3 changelog + §15 TL;DR actualizados v1.5** surgical.
8. **Si duda → ADR-011 + ADR-012 + `PRE_S2_CHECKLIST.md` + NOTICE r1 mandan.**

---

## 0. Resumen ejecutivo

Este documento es **el roadmap maestro del proyecto SONAR (ex-Admirals)**. Consolida todos los roadmaps dispersos en otros docs y los organiza en **fases coherentes con dependencias claras**.

> **Filosofía:** **iterar en oleadas**, no waterfall. Cada oleada es **playable y vendible**, no solo "demo técnica". El founder puede pausar/parar tras cualquier oleada y tener un producto funcional.

Define:

- **Filosofía de planificación** SONAR (5 principios).
- **Vista global de fases:**
  - **Oleada 0** — Documentación (casi cerrada).
  - **Oleada 1** — MVP playable (4-6 meses).
  - **Oleada 2** — Profundidad + social (6 meses adicionales).
  - **Oleada 3+** — Federación + avanzado (ongoing).
- **Detalle por oleada** — features, deliverables, criterios "done".
- **Dependencias** entre features (qué bloquea qué).
- **Critical path** — el camino mínimo a MVP.
- **Done criteria** — definición concreta de "completado".
- **Risk register** — riesgos identificados + mitigaciones.
- **Sprint structure** recomendada para solo-dev / small team.
- **Estimation guide** — cómo estimar tareas SONAR.
- **Anti-patterns planning** — errores que evitamos.
- **KPIs roadmap** — métricas de progreso.

> **Por qué este doc importa:** sin roadmap maestro, cada oleada se construye en aislamiento. Con este doc, todo el equipo (founder, AI agents, futuros devs) **sabe qué viene cuándo y por qué**.

---

## 1. Filosofía de planificación

### 1.1 Los 5 principios

#### Principio 1 — Iterar en oleadas, no waterfall
> **Cada oleada es un producto vendible.** No "fase 1 de 5" → "fase 5 finalmente jugable". Oleada 1 = playable + monetizable + cerrable.

#### Principio 2 — MVP scope, no scope creep
> **Oleada 1 ships con 1 nodo (Granja — raíz cross-vertical), no los 4.** Molino + Bakery + Retail vienen en Oleada 2 construyendo sobre wheat real producido por players. Granja primero porque es el nodo raíz del producto (Bible §13.4) y permite que Oleada 2 construya cadenas reales en lugar de NPC stubs.

#### Principio 3 — Documentación firmada antes de codear
> **Oleada 0 docs es prerrequisito.** No empezar Oleada 1 hasta que SSoTs estén firmados (economy, design, technical foundational).

#### Principio 4 — Critical path > everything
> **Identificar dependencias, atacar bottlenecks primero.** Si Banco bloquea Empresa que bloquea Bakery, Banco va antes que Bakery.

#### Principio 5 — Live testing > automated testing
> **FiveM hace E2E automation casi imposible.** Aceptamos esto. QA real = playtest sessions con el equipo, manual smoke checks, feedback loops semanales.

### 1.2 Anti-principios

- ❌ **Waterfall** — "diseño 6 meses → codeo 12 meses → testeo 3 meses".
- ❌ **Big bang launch** — "abrimos servidor con 4 nodos perfectos día 1".
- ❌ **Feature-completeness obsesiva** — "no shippeo hasta que tenga todo".
- ❌ **Estimaciones precisas a corto plazo** — "esto toma 3.5 días" → invariablemente falso.
- ❌ **Roadmap sagrado** — el plan se ajusta según learnings, no se ejecuta ciegamente.

---

## 2. Vista global de fases

### 2.1 Tabla resumen

| Oleada | Estado | Duración estim. | Output |
|---|---|---|---|
| **Oleada 0** — Documentación | 🏆 CERRADA 100% (29 firmados + briefs v2) | ~1 mes total | 29 docs / ~27.260 líneas + 5 briefs v2 SONAR, **ready-to-code** (Admirals heritage) |
| **Oleada 1** — MVP **Granja** + SONAR Tablet + SONAR Bank | 🟡 EN PROGRESO (Sprint 0+1 ✅, Sprint 2 🟡 DIFERIDO pending Phases 4-12 pivot) | 4-6 meses | Servidor playable: nodo raíz Granja + SONAR Tablet + economía core + bridges multi-framework |
| **Oleada 2** — Multi-nodo (Molino + Bakery + Retail) + social | 🔴 Pendiente | 6-8 meses | 4 nodos completos end-to-end + features sociales avanzadas |
| **Oleada 3+** — Federation + avanzado | 🔴 Pendiente | Ongoing | Cross-server, advanced governance, Marketplace SONAR |

### 2.2 Critical path resumido

```
Oleada 0 docs (firmar planning + technical impl + testing protocol + bridges)
   ↓
Oleada 1 Sprint 0: Setup repo + framework decision (QBox primary, QBCore compat) + Bridges layer skeleton
   ↓
Oleada 1 Sprint 1: Banco básico + IBAN + balance + transferencias (vía Bridges.Bank o nativo)
   ↓
Oleada 1 Sprint 2: Tablet shell + Bank app + Map app (vía Bridges.Phone si script externo)
   ↓
Oleada 1 Sprint 3: Ítem físico básico + quality system + lineage origin (vía Bridges.Inventory)
   ↓
Oleada 1 Sprint 4: Granja NPC mecánicas (plot, plant, irrigate, harvest, output wheat)
   ↓
Oleada 1 Sprint 5: Empresa básica + employee/founder + salaries
   ↓
Oleada 1 Sprint 6: Workplace app + apply for job + first paycheck
   ↓
Oleada 1 Sprint 7: Granja player-foundable + sell wheat NPC Mill (B2C-NPC)
   ↓
Oleada 1 Sprint 8: Polish + balance + bridges testing matrix + closed beta
   ↓
🚀 OLEADA 1 LAUNCH (private beta)
```

---

## 3. Oleada 0 — Documentación (estado actual)

### 3.1 Goals

- **Toda la documentación design + technical foundational + art + economy + gameplay firmada.**
- **Meta-layer (agents/ + planning/) completo.**
- **Implementation docs (technical 04-06 + qa) firmados.**

### 3.2 Estado detallado

#### 3.2.1 Categorías ✅ CERRADAS

| Categoría | Docs | Estado |
|---|---|---|
| `design/` | 6 | ✅ Firmados |
| `technical/` foundational | 3 | ✅ Firmados |
| `art/` | 4 | ✅ Firmados |
| `economy/` | 3 | ✅ Firmados |
| `gameplay/` | 3 | ✅ Firmados |

**Subtotal:** 19 docs firmados, ~17.800 líneas.

#### 3.2.2 Categorías 🟡 EN PROGRESO

| Doc | Estado |
|---|---|
| `agents/00_BOOTSTRAP.md` | ✅ Firmado |
| `planning/01_roadmap.md` | 🟡 Este doc en redacción |

#### 3.2.3 Categorías ✅ COMPLETAS Oleada 0 (firmados 2026-05-01)

| Doc | Estado |
|---|---|
| `agents/01_subagents_catalog.md` | ✅ Archivado per ADR-001 |
| `agents/02_working_conventions.md` | ✅ Firmado |
| `planning/02_decision_log.md` | ✅ Firmado |
| `technical/04_api_contracts.md` | ✅ Firmado |
| `technical/05_state_machines.md` | ✅ Firmado |
| `technical/06_fivem_standards.md` | ✅ Firmado |
| `qa/01_testing_protocol.md` | ✅ Firmado |

#### 3.2.4 Categorías 🏆 COMPLETAS

| Doc | Estado | Líneas |
|---|---|---|
| `technical/07_bridges_compatibility.md` v1.0 | ✅ Firmado (cerró Oleada 0) | ~900 |

**Total pendiente Oleada 0:** 0 docs. 🏆 **OLEADA 0 CERRADA.**

### 3.3 Done criteria Oleada 0 🏆

- ✅ Todos los docs ⭐⭐⭐⭐ firmados.
- ✅ Cero contradicciones entre SSoTs.
- ✅ Cross-references todas válidas (no broken links).
- ✅ BOOTSTRAP v1.2 actualizado con state final Oleada 0 cerrada.
- ✅ Founder ha leído y validado roadmap (este doc).
- ✅ `technical/07_bridges_compatibility.md` v1.0 firmado.
- ✅ ADR-008 (Granja pivot) + ADR-009 (Bridges Layer) registrados en decision_log.

🏆 **Todos los done criteria cumplidos. Sprint 0 Oleada 1 puede empezar.**

### 3.4 Salida esperada

> **Tras Oleada 0:** cualquier dev/AI agent puede abrir el repo, leer BOOTSTRAP, leer roadmap, y **empezar a codear con confianza**.

---

## 4. Oleada 1 — MVP playable (4-6 meses)

### 4.1 Visión MVP

> **El MVP de SONAR es:**
>
> Un servidor FiveM donde un player puede:
> 1. Conectarse, recibir IBAN inicial 2.500 €.
> 2. Abrir SONAR Tablet (TAB), navegar 3 apps (SONAR Bank, Map, Workplace).
> 3. Aplicar a un job en Granja NPC.
> 4. Trabajar shifts: preparar suelo, plantar trigo, regar, cosechar, ensacar.
> 5. Recibir salary quincenal automático.
> 6. Ahorrar hasta poder rentar parcelas y fundar su propia Granja.
> 7. Fundar empresa, contratar peones, gestionar plots, vender wheat al Molino NPC.
> 8. Cerrar el server con sentido de progreso + saldo creciente.

**Por qué Granja primero (no Bakery):**
- Granja es **el nodo raíz cross-vertical** (Product Bible §13.4) — todas las cadenas empiezan aquí.
- Calidad sistema (soil/irrigation/fertilization/pest/weather scores) es más natural en Granja que mecánicas activas Bakery.
- Ritmo time-based (crops 7 días) reduce carga compute server (passive vs active minigames).
- Oleada 2 construye Molino → Bakery → Retail **sobre wheat real de players**, no sobre NPC stubs (lineage real desde día 1 Oleada 2).
- `design/01_node_farm.md` v1.1 es el doc de nodo más maduro y profundo (~1500 líneas firmadas).

**NO incluye Oleada 1:**
- ❌ Molino, Bakery, Retail (vienen Oleada 2).
- ❌ Lineage chain completa (Granja produce wheat con lineage `origin`, pero no se procesa todavía — wheat se vende a NPC Mill fixed-price).
- ❌ B2B contracts entre players (solo NPC Mill ↔ player Granja).
- ❌ Tractor avanzado / múltiples crops (solo wheat, herramientas básicas).
- ❌ Pest events random (Oleada 1.5).
- ❌ Reviews/ratings (oleada 2+).
- ❌ Achievements completos (subset básico ok).
- ❌ Mentor system (oleada 2+).

### 4.2 Sprints Oleada 1

> **Recomendación:** sprints de 2 semanas, retros simples al final.

#### Sprint 0 — Setup + Bridges Layer + admirals_core foundation (✅ CERRADO 2026-05-02)

**Goals:**
- Repo Git inicializado + estructura básica (`server/`, `resources/`, `web/`, `migrations/`, `scripts/`).
- Framework FiveM decidido (QBox primary, QBCore compat declared) + base instalada.
- DB MySQL setup + migrations runner + primeras migrations (schema_versions + foundation tables).
- `admirals_core` resource skeleton (Event Bus + DB wrappers + RateLimiter + Logger + Metrics + Migrations).
- **Bridges layer completo** — 6 bridges (Bank / Inventory / Phone / Identity / Target / Notify) + 6 T1 adapters externos (qbox bank+identity, ox_inventory, ox_target, ox_lib notify, lb-phone) + 6 native fallbacks + auto-detection + convar overrides + boot report.
- Auto-detection de scripts instalados al boot.
- Smoke test 10 pasos (`scripts/smoke_test_s0.md`).
- Resource scaffolding + fxmanifest load order + first push GitHub.

**Done criteria (todos ✅):**
- ✅ `git clone` + 1 comando ejecuta server local. (S0.1)
- ✅ Bridges layer detecta framework instalado y elige adapter correcto. (S0.2 + S0.3)
- ✅ `admirals_core` boots limpio: Logger + Metrics + DB + EventBus + RateLimiter + Migrations + init orchestration. (S0.4)
- ✅ Migrations runner aplica 001_schema_versions + 002_foundation_tables idempotente con checksum SHA-256. (S0.4)
- ✅ 3 tablas foundation creadas: `admirals_accounts` (minimal 7 cols), `admirals_audit_log` (wrapper operational), `admirals_bridge_idempotency` (DB-backed replacement S0.2 in-memory). Ver ADR-010 para rationale. (S0.4)
- ✅ Smoke test 10 pasos manual (`scripts/smoke_test_s0.md`) redactado — ejecución founder.
- ✅ `admirals_bridges` v0.2.0 + `admirals_core` v0.1.0 resmon idle < 0.3ms cada uno.

**Sessions ejecutadas (5):** S0.0 checkpoint (operacionales) + S0.1 scaffolding + S0.2 Bridges Layer (Opus) + S0.3 T1 adapters (Sonnet) + S0.4 admirals_core foundation (Opus).

**ADRs añadidos:** ADR-010 (hybrid audit_log).

**Retro:** `progress/SPRINT_RETRO_S0.md`.

**Risk original:** scope bridges skeleton puede inflarse. Resultado: **mitigado exitosamente** — bridges skeleton completo con 6 T1 adapters en 1 sprint, no escaló.

#### Sprint 1 — Banco básico (✅ CERRADO 2026-05-02)

**Duración real:** 1 día intensivo (vs estimado 2 semanas).
**Sessions ejecutadas:** 3 (S1.1, S1.2, S1.3) + phase2 finalize en S1.3.

**Deliverables:**
- `admirals_bank` v0.4.0 — resource completo con IBAN generator (`AD-XXXX-XXXX-XXXX` 17 chars checksum) + Accounts + Movements + Transfer + Events + Escrow FSM + Callbacks C001/C002/C004/C005.
- Migrations 003 (bank_schema) + 004 (system treasury seed `AD-SYS0-0000-0001`) + 005 (balance NON-NEG check S005) + 006 (escrow schema) + 007 (FK fix transitional) + 008 (FK revert canonical a bank_accounts).
- `admirals_core` v0.4.2 — bumped con 6 migrations nuevas + idempotency DB-backed promoted (`admirals_bridge_idempotency` table).
- `admirals_bridges` v0.2.0 (mantenido) — Bridges.Bank expandido con escrow contracts, IdempotencyBackend='db'.
- FSM `escrow_lifecycle` per `05_state_machines.md` §4.1 (5 estados + transitions whitelist + guards).
- Smoke tests: S1.1 (6/6 ✅) + S1.2 (10/10 ✅) + S1.3 (14/14 ✅). Total: 30/30 pasos manuales verificados founder.
- Audit DB persistence operativa (ADR-010 hybrid). Rate limiter `bank.write` 10/60s. Event bus schema v1.

**Done criteria cumplidos:**
- ✅ Player conecta primera vez → IBAN único asignado + saldo starter per `economy/01_economic_model.md`.
- ✅ Player A puede transferir X € a player B vía console command (smoke S1.2 step 1). UI llega S2.
- ✅ Transactions inmutables (admirals_bank_movements + audit log). Double-entry ledger (debit+credit rows).
- ✅ Escrow lock/release funcional — Create con 2 movements (amount+fee separately) + Release atomic TX + auth matrix F3.
- ✅ Idempotency DB-backed (promoted de memoria a `admirals_bridge_idempotency` en S1.2).
- ✅ FSM double-release guard + FSM_INVALID_TRANSITION error mapping.
- ✅ Tag `sprint-1-complete` + SPRINT_RETRO_S1.md redactado.

**Risk retro:** 3 incidencias in-flight S1.3 (FK violation target identity vs bank_account, auth mismatch, `owner_account_id` Player B corrupto) — todas resueltas con migrations aditivas respetando ADR-010 immutability. Duración session S1.3 overrun ~6h vs 4-5h estimado. Velocity real S1 = 15× estimación inicial (1 día vs 2 semanas).

**Bloquea S2.**

#### Sprint 2 — SONAR Tablet shell + SONAR Bank app (🟡 DIFERIDO pending Phases 4-12 pivot complete)

**Status post-S1.8:** planning pendiente. Hard blockers detallados en `progress/PRE_S2_CHECKLIST.md` v1.3+ (B1-B5) + decisiones founder pendientes (D1-D3). NO arranca hasta Phase 10 smoke regression complete.

**Goals propuestos (sujetos a founder D1 scope decision):**
- NUI shell SONAR Tablet (React + TailwindCSS + shadcn/ui base) alineado `docs/design/02_sonar_tablet.md` v1.2 + `docs/art/01_art_direction.md` v2.0-scaffold-r7 NOTICE r6.
- Apertura/cierre con `TAB` keybind (SonarOS boot + lock/home/app states).
- SONAR Bank app: balance + transactions list + transfer UI (consume callbacks C001/C002 ya shipped S1 + C003 `getTransactions` pending scope D1).
- Map app: GPS + markers básicos.
- Scope balance options founder D1:
  - **(A) tech-balanced:** Tablet shell minimal + SONAR Bank básico + T2 adapters ESX/QBCore + `admirals_companies`/`sonar_companies` DDL (naming per D3) + C003. ~3 semanas.
  - **(B) UI-heavy:** Tablet shell refinado + SONAR Bank polished + Map app + motion signature + sound signature canonical 5 SFX. Deferir T2/C003 a S3. ~4 semanas.
  - **(C) híbrido:** Tablet shell + SONAR Bank + T2 read-only. Defer DDL+C003 a S3. ~3 semanas.

**Done criteria propuestos:**
- ✅ Player presiona `TAB` → SONAR Tablet aparece con motion canonical (ver `art/briefs/04_brief_motion.md` v1).
- ✅ SONAR Bank app muestra IBAN + balance + 10 últimas transactions.
- ✅ Player puede transferir a otro IBAN desde Tablet UI.
- ✅ Map app muestra ubicación player + markers admin-defined.
- ✅ 5 SFX canonical integrados (`signal_emerge`/`depth_press`/`layer_dive`/`console_tap`/`panel_open`).
- ✅ Paleta hybrid Tier A/B/C aplicada (NO dark-extremo 60% canvas; ~30-40% dark + ~30-40% white surfaces per ADR-012 §D2).
- ✅ Voz neutral premium-tech en copy UI (NO militar/capitán/tactical per ADR-012 §D3).
- ✅ Logo v2 working canonical integrado (boot splash + lock screen + dock per `02_sonar_tablet.md` §3/§4.2/§21).

**Blockers hard pre-S2 (ver `PRE_S2_CHECKLIST.md` v1.3+):**
- 🔴 **B1** Phase 6 mass-purge operational docs: 1/8 done (`02_sonar_tablet.md` v1.2), 7/8 pendientes (`02_events_catalog.md`, `03_db_schema.md`, `04_api_contracts.md`, `05_state_machines.md`, `06_fivem_standards.md` light, `07_bridges_compatibility.md` light, `01_roadmap.md` v1.5 ← este doc).
- 🔴 **B2** SPRINT_PLAN_S2.md redactado (requiere D1+D3 founder decisions + B1 complete).
- 🟡 **B3** Memoria `SONAR Identity r2` confirmed al boot S2.0.
- 🟡 **B4** Smoke regression `admirals_bank` 30/30 pre-S2 (verifica base sólida post-pivot antes de nuevo code).
- 🟡 **B5** Tag `sonar-identity-canonical` marks identity lock.
- 🟡 **D1** scope decision founder (A/B/C).
- 🟡 **D2** creative outsourcing SÍ/NO icons (logo v2 resuelto in-house S1.7).
- 🟡 **D3** namespace migration timing (Phase 8+9 AHORA vs DEFERIDA vs parcial).

**Bloquea:** Workplace app, Comm app, etc. (todo Tablet downstream) + Phase 12 Sprint 2 arranque.

#### Sprint 3 — Ítem físico + quality (2 semanas)

**Goals:**
- Estructura ítem físico (ver `technical/03_db_schema.md` §7).
- Quality system A/B/C/D (atributos ítem).
- Lineage tracking básico (origin, owner history).
- Inventario player simple (carry items).
- Carry mechanic (drag-drop sacos NUI ↔ world).

**Done criteria:**
- ✅ Player puede pick up un saco harina del world.
- ✅ Saco tiene atributos: quality, lineage origin, owner.
- ✅ Player puede drop saco en otro lugar.
- ✅ Saco persiste en DB cuando server restart.

#### Sprint 4 — Granja NPC mecánicas (3 semanas)

**Goals:**
- Área Granja NPC en mapa (terreno existente o custom asset).
- Plot system (parcelas pequeñas inicialmente — 4×4m).
- Mecánica plant seeds (drag-drop semillas en plot vía ox_target o equivalent vía `Bridges.Target`).
- Growth timer (configurable: dev=accelerated 5min/stage, prod=hours/days per `gameplay/01_gameplay_loops.md`).
- Mecánica irrigation (water bucket o sprinkler toggle, contribuye `irrigation_score`).
- Mecánica harvest (manual con tool, output wheat sacks).
- Output wheat (ítem físico con quality A/B/C/D + lineage `origin`).
- Quality calc: `soil_quality_score` + `irrigation_score` + base random (skill viene Sprint 5).
- NPC Mill buyer fixed-price (player vende wheat → IBAN credit).

**Done criteria:**
- ✅ Player puede ejecutar full proceso: prepare soil → plant → irrigate → harvest → ensacar.
- ✅ Wheat output tiene quality calculada + lineage origin set (granja_id + plot_id + harvest_timestamp).
- ✅ Tiempo proceso completo (acelerado dev): ~10-15 min full cycle.
- ✅ Player puede vender wheat a NPC Mill y recibir money en IBAN.
- ✅ Resmon Granja resource <1ms idle (timers passive, no per-frame loops).

**Bloquea:** Empresa Granja (Sprint 5+).

#### Sprint 5 — Empresa básica + roles + salaries (3 semanas)

**Goals:**
- Tabla `admirals_empresas`.
- Roles: founder, employee.
- Hire/fire básico.
- Salary auto-pago quincenal (cron job o tick).
- IBAN empresa + transfer interno empresa↔founder.

**Done criteria:**
- ✅ Player puede fundar empresa (paga 5.000-15.000 € fee).
- ✅ Player founder puede hire otro player (offer + accept flow).
- ✅ Quincenalmente salary auto-paga IBAN employee.
- ✅ Empresa tiene IBAN propio (separate from founder personal).

#### Sprint 6 — Workplace app + apply for jobs (2 semanas)

**Goals:**
- Workplace app Tablet.
- List active job postings (NPC + player empresas).
- Apply mechanic.
- Founder accept/reject UI.

**Done criteria:**
- ✅ Player abre Workplace app, ve lista jobs.
- ✅ Apply → Tablet notif al founder.
- ✅ Founder accept → player es employee.
- ✅ NPC Granja siempre tiene 2-3 slots peón abiertos (tutorial path).

#### Sprint 7 — Granja player-foundable + sell to NPC Mill (3 semanas)

**Goals:**
- Plot rental / ownership system (founder rents X plots monthly).
- Multiple plots manageable per empresa.
- Storage silo on-site (físical container con capacity limit).
- B2C-NPC: NPC Mill buys wheat at fixed-price (premium per quality grade).
- Pricing differential per quality A/B/C/D (recap `economy/01_economic_model.md`).
- Manager Panel basic Tablet app: ver plots status + employees + cash flow.

**Done criteria:**
- ✅ Player founder rents 3-5 plots iniciales.
- ✅ Plots persisten en DB across server restarts.
- ✅ Empleados pueden trabajar plots de empresa founder.
- ✅ Wheat producido se almacena en silo empresa.
- ✅ Founder/employee vende silo wheat a NPC Mill.
- ✅ Revenue ingresa IBAN empresa (no IBAN personal founder).

#### Sprint 8 — Polish + balance + closed beta (3 semanas)

**Goals:**
- Bug fixing.
- Numbers tuning vs `economy/01_economic_model.md`.
- UI polish + sounds (using `art/03_sound_bible.md` SFX).
- Onboarding flow tested.
- Closed beta con 5-10 testers.

**Done criteria:**
- ✅ 5 testers play 1h sin major bugs.
- ✅ Onboarding tutorial complete-able < 30min.
- ✅ Founder satisfied: "esto es jugable".

### 4.3 Total Oleada 1

- **Duración:** 19-22 semanas (~4-5 meses).
- **Sprints:** 9 (incluye Sprint 0).
- **Output:** servidor playable + 1 nodo (Granja — cross-vertical root) + Tablet 3 apps + Banco + Empresas básicas + Bridges layer multi-framework.

### 4.4 Done criteria Oleada 1

#### 4.4.1 Funcional
- ✅ Player puede completar onboarding.
- ✅ Player puede earn money working Granja NPC (peón).
- ✅ Player puede save 20-30k €, rent plots y fundar Granja propia.
- ✅ Player puede hire 1-2 peones.
- ✅ Player puede gestionar múltiples plots y vender wheat a NPC Mill.
- ✅ Bridges layer permite swap framework (probado QBox + QBCore minimum).

#### 4.4.2 Técnico
- ✅ Server stable 4h+ sin crashes.
- ✅ Resmon de cada resource <1ms idle, <5ms peak.
- ✅ DB queries <50ms p99.
- ✅ NUI Tablet <100ms abrir/cerrar.

#### 4.4.3 Negocio
- ✅ Founder satisfecho con quality.
- ✅ 5+ closed beta testers feedback positivo.
- ✅ Decisión: ¿abrir public beta o más polish?

---

## 5. Oleada 2 — Multi-nodo + social (6-8 meses)

### 5.1 Visión

> **Tras Oleada 1 (Granja shipped), SONAR añade los otros 3 nodos descendentes + features sociales avanzadas + economía completa.** Oleada 2 construye cadenas reales sobre wheat producido por players Oleada 1 (no NPC stubs).

### 5.2 Features Oleada 2

#### 5.2.1 Nodos restantes

- **Molino** (Sprint 1-3 Oleada 2) — primer downstream consumer del wheat de Granja.
- **Bakery** (Sprint 3-5 Oleada 2) — consume harina de Molino.
- **Retail** (Sprint 5-7 Oleada 2) — vende baguettes + wheat raw a B2C/B2B.
- **Logística** cross-node (Sprint 4-6).

#### 5.2.2 Lineage chain completa

- Granja → Molino → Bakery → Retail trazable.
- Premium pricing × 1.20 lineage complete.
- Visualization Tablet "lineage chain history".

#### 5.2.3 B2B contracts player↔player

- Mercado app completo.
- Contract negotiation Tablet.
- Subscriptions B2B (recap economy §9.4).
- Escrow management.

#### 5.2.4 Social features avanzadas

- Comm app: empresa channels + DMs + market public.
- Friends list + public reputation profiles.
- Reviews/ratings (PED + B2B).
- Mentor system formal.

#### 5.2.5 Apps Tablet adicionales

- Comm app.
- Manager Panel (full).
- Mercado app.
- Profile app.
- Calendar app.
- Settings app.

#### 5.2.6 Achievements + leaderboards

- Catálogo achievements completo.
- Leaderboards servidor.
- Title/badge system.

#### 5.2.7 Eventos servidor

- Bread Day, Founder's Day, Quality Week.
- Holidays + decoraciones.
- Server-wide quests.

### 5.3 Sprints Oleada 2 (estructura)

| Sprint | Foco | Duración |
|---|---|---|
| O2-S1 | Molino básico (recibe wheat real de Granja Oleada 1) | 3 semanas |
| O2-S2 | Granja avanzada (tractor + multi-crop + pest events) | 2 semanas |
| O2-S3 | Bakery básica (mix + knead + bake usando harina Molino) | 3 semanas |
| O2-S4 | Logística (drivers + delivery + escrow) | 3 semanas |
| O2-S5 | Retail básico (lineales + POS multi-categoría) | 3 semanas |
| O2-S6 | Retail dynamic pricing + multi-supplier | 2 semanas |
| O2-S7 | Lineage chain end-to-end (Granja→Molino→Bakery→Retail visible Tablet) | 2 semanas |
| O2-S8 | B2B contracts + Mercado app | 3 semanas |
| O2-S9 | Comm app + social features | 3 semanas |
| O2-S10 | Reviews + mentor system | 2 semanas |
| O2-S11 | Achievements + leaderboards | 2 semanas |
| O2-S12 | Eventos servidor + bridges expansion (lb-phone, qs-inventory adapters) + polish | 3 semanas |

**Total:** ~31 semanas (~7-8 meses).

### 5.4 Done criteria Oleada 2

- ✅ 4 nodos operacionales end-to-end.
- ✅ Lineage chain trazable + premium pricing aplicado.
- ✅ B2B player↔player workflows funcionales.
- ✅ Social features (Comm, friends, reviews) usadas activamente.
- ✅ Achievements + leaderboards visibles.
- ✅ 50+ players activos servidor (target).

---

## 6. Oleada 3+ — Federation + avanzado (ongoing)

### 6.1 Features futuras

- 🔮 **Cross-server federation** — players move between servers.
- 🔮 **Marketplace global SONAR** — cross-server trade.
- 🔮 **Multi-empresa player groups** — conglomerates.
- 🔮 **Hipermercado economics** + verticals nuevas (Lácteos, Carnicería).
- 🔮 **Bonds / financial instruments**.
- 🔮 **Player governance servidor** (community moderators).
- 🔮 **Hunger system** (consumo real B2C).
- 🔮 **Procedural quests AI-generated**.
- 🔮 **Custom branding empresa**.

### 6.2 Filosofía Oleada 3+

> **No timeline fijo.** Se planifica cuando Oleada 2 esté madura + datos reales de 50+ players activos para informar prioridades.

---

## 7. Dependencias entre features

### 7.1 Grafo dependencias críticas

```
Bridges layer (Bank/Inventory/Phone/Identity/Target adapters)
   │
   └─→ Banco (IBAN + transfers — wraps Bridges.Bank o nativo)
         │
         ├─→ Tablet shell + Bank app (vía Bridges.Phone si script externo)
         │      │
         │      └─→ Otras apps (Workplace, Map, Comm, ...)
         │
         ├─→ Empresa (IBAN empresa + salaries)
         │      │
         │      ├─→ Hiring + roles
         │      └─→ B2B contracts (Oleada 2)
         │
         └─→ Item physical (vía Bridges.Inventory)
                │
                ├─→ Granja mecánicas (Oleada 1) ⭐
                ├─→ Molino mecánicas (Oleada 2)
                ├─→ Bakery mecánicas (Oleada 2)
                ├─→ Retail mecánicas (Oleada 2)
                │
                └─→ Lineage chain (req: 2+ nodos = Oleada 2)
                      │
                      └─→ Premium pricing
```

### 7.2 Tabla dependencias

| Feature | Bloquea | Bloqueado por |
|---|---|---|
| **Bridges layer** | Banco, Inventario, Tablet, todo | Nada (foundational, nuevo Oleada 0) |
| **Banco** | Empresa, Tablet, Item, todo | Bridges (si bank script externo) |
| **Tablet shell** | Apps Tablet | Banco + Bridges (si phone script externo) |
| **Item físico** | Mecánicas nodos | Banco + Bridges.Inventory |
| **Granja mecánicas** | Granja empresa, Oleada 2 nodos (Molino consume wheat) | Item |
| **Empresa básica** | Hiring, salaries | Banco |
| **Workplace app** | Job board flow | Tablet shell + Empresa |
| **Molino mecánicas** | Bakery (Oleada 2) | Granja shipped + lineage |
| **B2B contracts** | Mercado app | Empresa + Item + Comm |
| **Lineage chain** | Premium pricing | 2+ nodos operacionales (Oleada 2) |
| **Reviews** | Reputation public | Social features baseline |

### 7.3 Critical path Oleada 1

```
Bridges layer → Banco → Tablet shell → Item físico → Granja NPC → Empresa básica → Workplace → Granja player → Polish → MVP
```

**Cualquier delay en Bridges/Banco/Tablet/Item es catastrófico.** Front-load risk.

---

## 8. Done criteria — definiciones formales

### 8.1 Done criteria por feature

#### "Done" significa:
1. ✅ Codeado funcionalmente.
2. ✅ Tested smoke (manual playtest).
3. ✅ Sin bugs críticos conocidos.
4. ✅ Documentado (al menos comments + README update).
5. ✅ Coherente con SSoTs (numbers/events/schema).
6. ✅ Founder ha visto y aprobado.

#### "Done" NO significa:
- ❌ Perfecto.
- ❌ Cubierto 100% test cases.
- ❌ Optimizado al máximo.
- ❌ Cubre edge cases obscuros.

### 8.2 Done criteria por sprint

- ✅ Goals sprint cumplidos (>80% de tasks completed).
- ✅ Demo playable de lo construido.
- ✅ Retro corta (qué fue bien, qué no).
- ✅ Sprint siguiente planificado (top 3 tasks).

### 8.3 Done criteria por oleada

- Detallados en cada §3.3 / §4.4 / §5.4.
- Founder firma "Oleada N done" → siguiente oleada inicia.

---

## 9. Risk register

### 9.1 Riesgos Oleada 0 (docs)

| Risk | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Founder se cansa redactando | Mid | Mid | AI agents + chunking + sesiones cortas |
| SSoTs contradicen entre sí | Low | High | Cross-ref reviews per doc + economy_validator subagent |
| Scope creep docs | High | Mid | Roadmap docs explícito, no añadir docs no-esenciales |

### 9.2 Riesgos Oleada 1 (MVP)

| Risk | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Framework decisión paralysis (QBox/QBCore/ESX) | Low | Mid | **Resuelto:** QBox primary, QBCore compat vía bridges, ESX limited |
| Bridges abstracción incorrecta (acopla a 1 framework de facto) | Mid | Critical | Spec interfaces antes de code en `technical/07_bridges_compatibility.md`, test 2 frameworks Sprint 0 |
| Customer usa script bank/inventory/phone no soportado | High | High | Adapter SDK público + at least 1 customer-written adapter early |
| NUI Tablet performance (resmon) | Mid | High | Benchmarking continuo, simplificar si peso |
| Banco bugs (transfers wrong amounts) | Low | Critical | Unit tests Lua para Banco crit functions + integrity cron |
| Item físico save/load corrupted | Mid | Critical | Schema migrations + backup strategy |
| Granja crops growth ticks scaling badly con N plots | Mid | High | Passive timers (no per-frame), batch updates, perf test 100 plots |
| Founder solo dev burnout | High | Critical | Sprint cortos, milestone celebrations, AI agents productividad |
| FiveM platform changes (e.g., breaking update) | Low | Mid | Pin FiveM version dev, update controlado |

### 9.3 Riesgos Oleada 2 (multi-nodo)

| Risk | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Lineage chain bugs cross-empresa | Mid | High | Integration tests live + audit logs robust |
| B2B contracts disputes overflowing admin | Mid | Mid | Mentor + arbitration system formal early |
| Server load 50+ players | Mid | High | Load testing live antes 50, optimize iterative |
| Economy imbalance (inflation/deflation) | High | High | KPIs monitoring active + admin tooling |

### 9.4 Riesgos cross-fase

| Risk | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| AI agent quality degradation (sesión nueva pierde contexto) | High | Mid | BOOTSTRAP + memory + planning docs robustos |
| Bus factor 1 (only founder knows everything) | High | Critical | Documentar todo en code + decision_log |
| Pivot needed (fundamental design issue) | Low | Critical | Beta testing temprano + feedback loops |

---

## 10. Sprint structure recomendada

### 10.1 Para solo dev / 1-2 person team

#### Sprint length
**2 semanas** óptimo:
- Suficiente para entregar feature meaningful.
- Corto enough para corregir rumbo.

#### Estructura sprint

**Día 1 (Lunes semana 1):**
- Sprint planning: revisar goals + breakdown tasks.
- Decisión top 3-5 tasks.

**Día 2-9 (resto semana 1 + semana 2):**
- Trabajo focused sin meetings (solo dev: alta concentración).
- Quick syncs daily si team > 1.

**Día 10 (Viernes semana 2):**
- Sprint demo (incluso solo demo a sí mismo + AI agent).
- Sprint retro: qué fue bien, qué cambiar.
- Sprint planning siguiente.

### 10.2 Tooling recomendado

- **Issue tracking:** GitHub Issues o Linear.
- **Sprint board:** Kanban simple (Backlog / In Progress / Done).
- **Decisions:** logged en `planning/02_decision_log.md`.
- **Communication:** Discord canales dev.

### 10.3 Anti-patterns sprints

- ❌ **Daily standups** para solo dev (overhead).
- ❌ **Sprint > 4 semanas** (pierdes feedback rápido).
- ❌ **Estimaciones precision** (lo que sea, cabrá en 2 semanas o no).
- ❌ **Sprint 0 demos elaborados** (ship working code).
- ❌ **Skip retros** (1-1 conmigo cuenta).

---

## 11. Estimation guide

### 11.1 Tamaños T-shirt

| Size | Duration | Ejemplo |
|---|---|---|
| **XS** | <2 horas | Ajustar 1 número, fix typo, refactor menor |
| **S** | <1 día | Add new field schema, simple UI tweak, 1 endpoint |
| **M** | 2-4 días | New Tablet app simple, mecánica básica nodo |
| **L** | 1-2 semanas | Sprint goal típico (mecánica completa nodo) |
| **XL** | 2-4 semanas | Multi-feature integration (lineage chain, B2B contracts) |
| **XXL** | >1 mes | DEBE descomponerse en sub-tasks |

### 11.2 Heurística estimación

> **Si crees que algo toma X, estima X * 1.5.** El "1.5" cubre:
- Bugs unforeseen.
- Integration con sistemas existentes.
- Polish + testing.

### 11.3 Estimaciones Admirals-specific

#### Banco features
- Simple endpoint (getBalance): S.
- Transfer between IBANs: M.
- Escrow lifecycle: L.

#### Tablet apps
- App simple (Profile, Settings): S-M.
- App complex (Mercado, Manager Panel): L-XL.

#### Mecánica nodo
- Single mechanic (knead, bake): M.
- Full nodo end-to-end: L-XL.

#### Multi-system integration
- Lineage chain: XL.
- B2B contracts: XL.
- Reviews + reputation: L.

---

## 12. Anti-patterns planning

- ❌ **Detalle excesivo a 6 meses vista** — solo planeas detalle 1-2 sprints adelante.
- ❌ **Plan inflexible** — el plan se ajusta cada sprint a learnings.
- ❌ **Estimaciones absolutas** — siempre rangos (e.g., "4-6 meses Oleada 1").
- ❌ **Skip retros** — sin retros, los mismos errores se repiten.
- ❌ **Feature freeze prematuro** — Oleada 1 puede shippear con bugs menores, Oleada 2 puede pivot.
- ❌ **Roadmap visible público sin disclaimer** — managing player expectations es crítico.
- ❌ **Confundir output con outcome** — "shippé feature X" ≠ "feature X resuelve problema Y".

---

## 13. KPIs roadmap

### 13.1 Velocity KPIs

| Metric | Target |
|---|---|
| **Sprints completed on-time** | >70% |
| **Sprint goals hit** | >75% |
| **Tasks per sprint completed** | >80% of planned |
| **Sprint slippage avg** | <30% |

### 13.2 Quality KPIs

| Metric | Target |
|---|---|
| **Bugs introduced per sprint** | Decreasing trend |
| **Critical bugs in production** | <2 per Oleada |
| **Rollbacks** | <1 per sprint |
| **Tech debt items added** | Tracked + scheduled |

### 13.3 Scope KPIs

| Metric | Target |
|---|---|
| **Features dropped from Oleada** | <20% of planned |
| **Features added mid-Oleada** | <10% (scope creep watch) |
| **Founder approval rate** | >85% |

### 13.4 Retention KPIs (post-launch)

| Metric | Target Oleada 1 closed beta | Target Oleada 2 public |
|---|---|---|
| Day 1 retention | >70% | >60% |
| Day 7 retention | >40% | >30% |
| Day 30 retention | >25% | >15% |

---

## 14. Roadmap del documento + estado

### 14.1 Roadmap del propio documento

#### Oleada 0 (incluido)
- ✅ Filosofía planning + 5 principios.
- ✅ Vista global fases (0/1/2/3+).
- ✅ Detalle Oleada 0 (estado docs).
- ✅ Detalle Oleada 1 (sprints + done criteria).
- ✅ Detalle Oleada 2 (high-level).
- ✅ Visión Oleada 3+.
- ✅ Dependencias entre features.
- ✅ Done criteria por nivel.
- ✅ Risk register completo.
- ✅ Sprint structure recommendation.
- ✅ Estimation guide.
- ✅ Anti-patterns + KPIs.

#### Maintenance ongoing
- 🔄 Actualizar §3 estado al firmar cada nuevo doc Oleada 0.
- 🔄 Detallar Oleada 2 sprints cuando Oleada 1 acabe.
- 🔄 Risk register: añadir riesgos descubiertos en runtime.
- 🔄 KPIs: medir + reportar mensualmente Oleada 1+.

### 14.2 Estado del documento

- **Versión:** 1.5 (refinement post-pivot SONAR — NOTICE r1 top-level + surgical inline §2.1 + §4.1 + §4.2 Sprint 2 + §5.1 + §6.1 + §14.3 changelog + §15 TL;DR + §FIN bump).
- **Próxima revisión:** al completar B1 Phase 6 mass-purge docs 2-7 + Phase 8/9/10 (smoke regression) → v1.6 con pivot phases complete + SPRINT_PLAN_S2 redacted + Sprint 2 arranque + retro learnings.
- **Documento padre:** `agents/00_BOOTSTRAP.md` v1.5 (post-pivot).
- **Documento hermano:** `planning/02_decision_log.md` v1.4 (12 ADRs incl. ADR-011 + ADR-012).
- **Documentos relacionados:**
  - Todos los `design/`, `art/`, `economy/`, `gameplay/`, `technical/` (input — Phase 6/7 mass-purge en progreso).
  - `art/briefs/` 5 briefs v2 (logo + icons + sound + motion + marketing delivered).
  - `agents/00_BOOTSTRAP.md` v1.5 (referencia obligatoria).
  - `progress/PRE_S2_CHECKLIST.md` v1.3+ (operational blockers SSoT pre-S2).

### 14.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción completa. 14 secciones cubriendo filosofía, fases, sprints detallados Oleada 0+1, dependencias, risk register, estimation guide, KPIs. **Firmable.** |
| 1.1 | 2026-05-01 | Founder + Cascade | **Pivot crítico MVP node:** Bakery → Granja (cross-vertical root, Bible §13.4). Justificación: Granja es nodo raíz, sistema calidad más natural, ritmo passive timer-friendly perf, Oleada 2 construye sobre wheat real. Reorganización Sprint 4+7 (Bakery → Granja). Oleada 2 reordenada (Molino → Bakery → Retail). **Añadido `technical/07_bridges_compatibility.md`** como último doc Oleada 0 (compat scripts custom: lb-phone, qs-inventory, custom banks, etc.). Sprint 0 ampliado con bridges skeleton. Risk register actualizado (bridges + scaling Granja). Critical path actualizado. Dependencies graph muestra bridges como foundational. |
| 1.2 | 2026-05-01 | Founder + Cascade | 🏆 **OLEADA 0 CERRADA 100%.** `technical/07_bridges_compatibility.md` v1.0 firmado + ADR-008 (Granja pivot) + ADR-009 (Bridges Layer) registrados en decision_log. §2.1 tabla + §3.2 completadas. Done criteria Oleada 0 todos cumplidos. Estado "ready-to-code" confirmado. |
| 1.3 | 2026-05-02 | Founder + Cascade | 🏆 **SPRINT 0 CERRADO.** §4.2 Sprint 0 marcado ✅ con fecha + sessions ejecutadas (S0.0-S0.4) + ADR-010 (hybrid audit_log) añadido. `admirals_bridges` v0.2.0 + `admirals_core` v0.1.0 + migrations 001/002 operativos. Smoke test 10 pasos listo. Next: Sprint 1 — Banco core. |
| 1.4 | 2026-05-02 | Founder + Cascade | 🏆 **SPRINT 1 CERRADO** (mismo día — velocity 15×). §4.2 Sprint 1 marcado ✅ con deliverables detallados: `admirals_bank` v0.4.0 + escrow FSM + C001/C002/C004/C005 + migrations 003-008 + smokes 30/30 pasos cumulative. Tag `sprint-1-complete`. §15 TL;DR punto 6 bumped. Next: Sprint 2 — Tablet shell + Bank app (planning session dedicada pendiente). |
| 1.5 | 2026-05-03 | Founder + Cascade (S1.9) | 🔄 **SURGICAL POST-PIVOT SONAR** (ADR-011 + ADR-012). Title rebrand Admirals → SONAR. NOTICE r1 top-level (~80 líneas) establece: naming canonical (producto/Tablet/OS/Bank app), Sprint 2 DIFERIDO pending Phases 4-12, pivot phases roadmap 1-12 status, reading guide §1-§15 legacy vs canonical. §0 + §2.1 tabla Oleada 1 row bumped (🟡 EN PROGRESO Sprint 0+1 ✅ + Sprint 2 DIFERIDO). §4.1 Visión "El MVP de Admirals" → "El MVP de SONAR" + "Tablet" → "SONAR Tablet". §4.2 Sprint 2 full rewrite — DIFERIDO status + goals propuestos + 3 scope options D1 + done criteria propuestos 8 bullets (include 5 SFX canonical + paleta hybrid + voz neutral + logo v2) + blockers B1-B5 + D1-D3. §5.1 "Admirals" → "SONAR". §6.1 Marketplace global Admirals → SONAR. §14.2 estado bumped próxima revisión v1.6 post-Phase-6+8+9+10. §14.3 este entry. §15 TL;DR 10 puntos rewritten pivot-aware. §FIN versión bumped. **NO touched:** §3 Oleada 0 (histórico inmutable per ADR-011 §5.5.8), §4.2 Sprint 0+1 entries (histórico inmutable), §4.2 Sprints 3-8 gameplay mechanics (pivot-agnostic), §5.2-§5.4 Oleada 2 features, §7-§13 dependencies/done-criteria/risks/sprint-structure/estimation/KPIs, ADR refs 008-010 histórico. Code namespace `admirals_bank`/`admirals_core`/`admirals_bridges` preservado legacy hasta Phase 8+9 per ADR-011 §5.5.8. Cierra B1 doc 8/8 Phase 6 mass-purge (fase parcial — docs 2-5 técnicos requieren D3 founder decision; 6+7 light pendientes sesión futura). |

---

## 15. TL;DR — para AI agents

Si lees solo este resumen:

1. **Iteramos en oleadas, no waterfall.** Oleada 1 = MVP playable + monetizable.
2. **Oleada 0 (docs) 🏆 CERRADA 100%** (29 docs / ~27.260 líneas + 5 briefs v2 SONAR). READY TO CODE (Admirals heritage preserved).
3. **🔄 PIVOT IDENTITY Admirals → SONAR en ejecución multi-phase** (2026-05-03 ongoing — ADR-011 foundational + ADR-012 refinement). 12 phases, 1-5 completas + 4.5 briefs v2 delivered, 6-12 pendientes. Ver NOTICE r1 top-level + `progress/PRE_S2_CHECKLIST.md` v1.3+.
4. **Oleada 1 (MVP) = 4-6 meses, 9 sprints.** **Granja-only** (no Bakery — pivot v1.1) + SONAR Tablet 3 apps + SONAR Bank + Empresas básicas + Bridges layer.
5. **Oleada 2 (multi-nodo) = 6-8 meses, 12 sprints.** Molino + Bakery + Retail construidos sobre wheat real de Granja + social.
6. **Critical path Oleada 1:** Bridges → SONAR Bank → SONAR Tablet → Item → Granja NPC → Empresa → Workplace → Granja player → Polish.
7. **Sprint 0+1 🏆 CERRADOS** (2026-05-02, Admirals heritage — velocity 15× S1). `admirals_bank` v0.4.0 + escrow FSM + C001/C002/C004/C005 + migrations 003-008 + smokes 30/30. Tags `v0.0.0`/`v0.1.0`/`sprint-1-complete` preserved histórico. **Sprint 2 🟡 DIFERIDO** pending Phases 4-12 pivot complete (hard blockers B1-B5 + decisiones founder D1-D3 per `PRE_S2_CHECKLIST.md`).
8. **Code namespace legacy** `admirals_bank`/`admirals_core`/`admirals_bridges` + tablas SQL `admirals_*` + eventos `admirals:*` preservados hasta **Phase 8 code refactor + Phase 9 DB migration 009** per ADR-011 §5.5.8 excepciones. Rename timing pending D3 founder decision.
9. **Done criteria explícitos** por feature/sprint/oleada.
10. **Sprint length:** 2 semanas. Solo dev: ✅ skip dailies, do retros.
11. **Risk top 5 actualizado post-pivot:** (1) founder burnout multi-phase pivot, (2) bridges abstracción incorrecta, (3) AI agent quality drop re-confundiendo metáfora literal-militar deprecated, (4) smoke regression post-pivot fallos, (5) D1/D3 decisiones retrasan B1-B2 execution.
12. **Roadmap = living document.** Update al completar cada Phase pivot 4-12 + tras cada sprint Oleada 1+.

---

## Resumen ejecutivo del documento (cierre)

El **Master Roadmap** consolida toda la planificación dispersa:

- **Filosofía:** 5 principios — oleadas, MVP, docs primero, critical path, live testing.
- **Oleada 0 (docs):** 🏆 CERRADA 100% (29 docs / ~27.260 líneas). Ready to code.
- **Oleada 1 (MVP playable):** 9 sprints, 4-6 meses, **Granja** (cross-vertical root) + Tablet 3 apps + Banco + Bridges layer.
- **Oleada 2 (multi-nodo + social):** 12 sprints, 6-8 meses, Molino+Bakery+Retail construidos sobre wheat real.
- **Oleada 3+:** federation, marketplaces globales, governance avanzada.
- **Dependencies graph claro** — Banco bloquea todo, item bloquea mecánicas.
- **Done criteria explícitos** por feature/sprint/oleada — sin ambigüedad.
- **Risk register completo** Oleada 0/1/2 con mitigaciones.
- **Sprint structure** 2 semanas + anti-patterns documentados.
- **Estimation T-shirt** + heurística × 1.5 + ejemplos SONAR.
- **KPIs roadmap** velocity + quality + scope + retention.

> **Si en Oleada 1, founder + AI ship MVP en 4-6 meses con 5+ closed beta testers feedback positivo, server stable 4h+, bugs críticos <2, sprint goals hit >75%, bridges layer compatible con QBox+QBCore minimum, y pivot SONAR Phases 4-12 complete sin regresiones funcionales — el modelo planning SONAR (ex-Admirals) habrá funcionado.**

> El roadmap no es un contrato. Es un mapa. El terreno cambia, el mapa se actualiza.

---

*"Plan B siempre listo. Plan A es solo lo más probable hoy."*

**FIN DEL DOCUMENTO `planning/01_roadmap.md` v1.5**
