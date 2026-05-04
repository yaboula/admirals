# 📜 Admirals — Decision Log (ADRs)

> **Versión:** 1.0 (firmado — living document, 7 ADRs iniciales).
> **Tipo:** Planning/Governance. **Registro inmutable de decisiones arquitectónicas y estratégicas** del proyecto.
> **Documento padre:** `planning/01_roadmap.md` v1.0 (firmado).
> **Documento hermano:** `agents/00_BOOTSTRAP.md` v1.0 (firmado).
> **Estado:** firmado (living document — añadir ADR por cada decisión importante futura).

> **Lectura previa obligatoria:** `planning/01_roadmap.md` completo.

---

## 0. Resumen ejecutivo

Este documento es el **Decision Log del proyecto Admirals** — un registro cronológico e inmutable de **decisiones importantes** tomadas, con contexto + alternativas consideradas + consecuencias.

> **Filosofía:** **Decisiones sin registro son decisiones perdidas.** Meses después nadie recordará por qué elegimos X sobre Y, y repetiremos el análisis (o peor, revertiremos sin saber por qué). Este log previene amnesia institucional.

Define:

- **Formato ADR** (Architecture Decision Record) estándar Admirals.
- **Lifecycle** de un ADR (proposed → accepted → deprecated → superseded).
- **Catálogo ADRs actuales** (ADR-001 en adelante).
- **Cómo añadir nuevo ADR.**
- **Anti-patterns ADR.**

> **Por qué este doc importa:** cuando llegue un dev nuevo en 6 meses y pregunte "¿por qué usamos ESX en lugar de QBCore?", la respuesta está aquí con razonamiento original.

---

## 1. Formato ADR estándar

### 1.1 Template

````md
## ADR-XXX — [Título corto decisión]

- **Fecha:** YYYY-MM-DD
- **Autor:** [Founder / Founder + Cascade / etc.]
- **Estado:** [proposed / accepted / deprecated / superseded by ADR-YYY]
- **Tags:** [fivem, economy, ai, planning, etc.]

### Contexto

[2-4 frases describiendo el problema / situation que llevó a esta decisión. Incluye restricciones relevantes.]

### Decisión

[1-3 frases stating la decisión tomada, de forma imperativa. "Elegimos X." "Usaremos Y." "Archivamos Z."]

### Alternativas consideradas

- **Opción A (elegida):** descripción + pros/cons.
- **Opción B:** descripción + pros/cons + razón descartada.
- **Opción C:** (si aplica).

### Consecuencias

**Positivas:**
- [Beneficio 1]
- [Beneficio 2]

**Negativas / trade-offs:**
- [Coste 1]
- [Coste 2]

**Neutrales:**
- [Cambio 1 sin valencia clara]

### Impact

- **Docs afectados:** [lista + versión a actualizar]
- **Código afectado:** [si aplica]
- **Features bloqueadas/desbloqueadas:** [si aplica]
- **Re-evaluation trigger:** [condición futura que nos haría revisar esta decisión]
````

### 1.2 Numeración

- **ADR-001, ADR-002, …** monotónica creciente.
- **Nunca reusar números** — incluso si deprecated o superseded.

### 1.3 Lifecycle

- **proposed** — borrador, pendiente aprobación founder.
- **accepted** — aprobada, aplicada.
- **deprecated** — ya no relevante pero no reemplazada.
- **superseded by ADR-YYY** — reemplazada por decisión posterior.

> **Importante:** ADRs **inmutables una vez accepted**. Si cambia la decisión, se crea **nuevo ADR** con `superseded by` en el viejo. No se edita contenido histórico.

---

## 2. Catálogo ADRs

---

## ADR-001 — Archivar subagents AI paralelos, adoptar workflow secuencial

- **Fecha:** 2026-05-01
- **Autor:** Founder + Cascade
- **Estado:** accepted
- **Tags:** ai, meta, subagents

### Contexto

El proyecto creó `agents/01_subagents_catalog.md` v1.0 definiendo 10 subagents AI especializados (economy_validator, cross_ref_checker, doc_writer, etc.) con invocation protocol ("Activando rol X…") y chaining workflows.

Founder evaluó que **con la tooling AI actual (mayo 2026), la ejecución de subagents en paralelo o con ceremonia invocation no es fiable en la práctica**. Los AI agents no mantienen separación real de contexto entre "roles" y la ceremonia genera overhead sin beneficio real.

### Decisión

**Archivamos los subagents como entidades invocables paralelas.** Los checks que definen (verificación económica, cross-refs, auditoría SSoT, etc.) **siguen siendo valiosos como checklists mentales secuenciales** que el AI ejecuta cuando aplica, **sin ceremonia invocation**.

### Alternativas consideradas

- **A (elegida) — Archivar subagents, trabajar secuencial con checklists implícitos.**
  - Pros: robust, sin overhead, alineado con capacidades AI reales hoy.
  - Cons: pierde la "jerga común" subagent-speak; founder debe confiar en que AI ejecuta checks.

- **B — Mantener subagents pero simplificar invocation.**
  - Pros: conserva framework conceptual.
  - Cons: ceremonia residual sigue siendo overhead; confuso para futuros devs/AI.

- **C — Deprecar completamente, borrar doc.**
  - Pros: limpieza total.
  - Cons: perdemos reference de checks válidos que siguen siendo útiles.

### Consecuencias

**Positivas:**
- AI trabaja de forma más natural y eficiente (secuencial, sin ceremonia).
- Reduce confusión en sesiones AI nuevas.
- Alinea con principio founder "organización + planificación e2e > mecánicas AI exóticas".

**Negativas / trade-offs:**
- Perdemos la visibility explícita de "cuándo AI está haciendo validación económica vs redacción vs audit".
- Founder depende de que AI ejecute checks sin anunciarlos (requiere confianza + verificación founder).

**Neutrales:**
- `agents/01_subagents_catalog.md` conservado como archived reference — no borrado.

### Impact

- **Docs afectados:**
  - `agents/01_subagents_catalog.md` → marcado ARCHIVADO v1.0.
  - `agents/00_BOOTSTRAP.md` §11 → actualizado con política secuencial.
  - Memoria persistente AI → updated.
- **Código afectado:** ninguno (pre-code phase).
- **Features bloqueadas/desbloqueadas:** ninguna.
- **Re-evaluation trigger:** si aparece tooling AI multi-agent verdaderamente confiable (e.g., Claude multi-agent APIs maduras, framework tipo AutoGen/CrewAI robustos para codebases complejos), revisitar.

---

## ADR-002 — Usar FiveM como plataforma

- **Fecha:** 2026-04 (retroactivo — decisión tomada antes de documentar)
- **Autor:** Founder
- **Estado:** accepted
- **Tags:** platform, foundational

### Contexto

Admirals requiere un engine multiplayer con capacidad de mundo persistente, mecánicas físicas, NUI para Tablet HUD, y una comunidad gamer activa para atracción orgánica.

### Decisión

**Usamos FiveM** (servidor privado GTA V multiplayer) como plataforma.

### Alternativas consideradas

- **A (elegida) — FiveM.**
  - Pros: comunidad grande, NUI Chromium embebido, scripting Lua maduro, MLOs custom disponibles, monetización Tebex.
  - Cons: dependencia de Rockstar / Take-Two (riesgo legal), limitaciones performance resmon, platform lock-in.

- **B — Unreal Engine custom.**
  - Pros: control total, mejores gráficos, portable.
  - Cons: desarrollo 10× más costoso, sin comunidad inicial, no hay base player instalada.

- **C — Unity multiplayer.**
  - Pros: más accesible que Unreal.
  - Cons: similar a B, sin comunidad player, mucho dev infrastructure (backend, matchmaking, etc.).

- **D — Roblox.**
  - Pros: plataforma distribuida.
  - Cons: audience demasiado joven, monetización propia limitante, no es el feel "serio RP".

### Consecuencias

**Positivas:**
- Time-to-market acelerado (usamos infra existente).
- Comunidad FiveM da organic growth path.
- Tooling maduro (state bags, events, NUI).

**Negativas:**
- Resmon constraints estrictos.
- Dependencia Rockstar/T2 (aceptada — riesgo conocido).
- Tablet UI en NUI con performance implications.

### Impact

- **Docs afectados:** toda la documentación asume FiveM.
- **Código afectado:** toda la implementación.
- **Re-evaluation trigger:** cambio drástico policy Take-Two, o adopción masiva alternativa (GTA VI modding, RedM, etc.).

---

## ADR-003 — Economía con tax retention 8% como sink principal

- **Fecha:** 2026-04 (retroactivo)
- **Autor:** Founder + Cascade
- **Estado:** accepted
- **Tags:** economy, foundational

### Contexto

Todo MMO económico sufre inflación sin sinks robustos. Necesitamos mecanismo primario de extracción dinero circulación que sea **transparente, predecible, y sentido en el contexto (impuestos son realistas en empresa simulada)**.

### Decisión

**Tax retention 8% sobre todos los dividendos empresa + escrow fees 0.3-1%** como sinks principales. Ver detalle `economy/01_economic_model.md` §7 + §9.

### Alternativas consideradas

- **A (elegida) — Tax 8% fixed + escrow fees escalonados.**
  - Pros: simple, predecible, realista (taxes reales), player no se enfada "es un impuesto".
  - Cons: si inflation severa, 8% puede no ser suficiente.

- **B — Tax progressive (higher tax for higher earners).**
  - Pros: más realista, frena top earners dominio.
  - Cons: complejo de comunicar, unfair-feel para top players.

- **C — Item decay + maintenance fees como sinks.**
  - Pros: contextual (maquinaria se rompe).
  - Cons: frustrating para player, castigo sin claro beneficio.

- **D — Wealth tax periódico.**
  - Pros: fuerte anti-inflation.
  - Cons: muy impopular, fuerza players a "mover" money artificially.

### Consecuencias

**Positivas:**
- Sink constante y predecible.
- Player acepta porque "es impuesto normal".
- Equipment depreciation (secondary sink) complementa.

**Negativas:**
- Si inflation severa, requerirá admin intervention (raise rate, event sinks).

### Impact

- **Docs afectados:** `economy/01_economic_model.md` §7, `economy/02_bakery_economy.md`, `economy/03_retail_economy.md`.
- **Re-evaluation trigger:** inflation YoY >15% sostenida.

---

## ADR-004 — No XP genérico, progresión por métricas reales

- **Fecha:** 2026-04 (retroactivo)
- **Autor:** Founder + Cascade
- **Estado:** accepted
- **Tags:** gameplay, progression, philosophy

### Contexto

MMOs tradicionales usan XP genérico ("do task → +50 XP → level up"). Esto es **abstracto, grindy, desconectado de realidad del trabajo simulado**.

### Decisión

**Admirals NO usa XP genérico.** Progresión por **métricas reales** (Quality A rate, transactions count, hours operativos, revenue generated). Ver `gameplay/02_progression_systems.md`.

### Alternativas consideradas

- **A (elegida) — Métricas reales tier-gated.**
  - Pros: alineado con filosofía "trabajo real, no skill check", transparente, hard to cheese.
  - Cons: más complejo de implementar (tracking múltiple), curve tuning delicado.

- **B — XP genérico standard.**
  - Pros: simple, familiar, gamified intuition.
  - Cons: contradice filosofía "trabajo real", invita grinding.

- **C — Dual-system (XP + métricas).**
  - Pros: best of both worlds.
  - Cons: complejo, doble esfuerzo balance.

### Consecuencias

**Positivas:**
- Alineado con pilares Admirals.
- Player visibly mejora en su oficio (Quality A rate sube).
- Anti-grind: quality matters más que cantidad.

**Negativas:**
- Implementación más compleja (tracking disgregado).
- Player familiarizado con MMOs standard puede confundirse.

### Impact

- **Docs afectados:** `gameplay/02_progression_systems.md` (entire doc), `00_PRODUCT_BIBLE.md` §10.
- **Re-evaluation trigger:** player feedback Oleada 1 beta overwhelming demandando XP familiar.

---

## ADR-005 — Oleada 1 MVP con Bakery-only (no 4 nodos)

- **Fecha:** 2026-05-01
- **Autor:** Founder + Cascade
- **Estado:** 🔴 **SUPERSEDED by ADR-008 (2026-05-01)** — pivot a Granja como MVP node. Mantenido en el log por valor histórico.
- **Tags:** roadmap, scope, mvp, superseded

### Contexto

Admirals design completo cubre 4 nodos (Granja + Molino + Bakery + Retail) + logística. Tentación: shippear todos en MVP para "demo completa".

Founder + AI reconocieron que con 1 solo dev Oleada 1, 4 nodos = 12+ meses minimum = alto riesgo burnout + slip launch.

### Decisión

**Oleada 1 MVP ships con solo Bakery** (+ Banco + Tablet 3 apps + Empresas básicas). Granja, Molino, Retail, Logística vienen en Oleada 2.

### Alternativas consideradas

- **A (elegida) — Bakery-only MVP.**
  - Pros: 4-6 meses realistic, 1 cosa pulida > 4 mediocres, launch temprano = feedback real.
  - Cons: lineage chain no existe Oleada 1 (players trabajan con harina NPC), feature clave diferida.

- **B — 2 nodos (Bakery + Retail).**
  - Pros: permite flujo producción→venta player↔player.
  - Cons: +2-3 meses, dos mecánicas complejas sin haber probado una.

- **C — 4 nodos MVP completo.**
  - Pros: vision completa Day 1.
  - Cons: 12+ meses, burnout risk crítico, feedback tardío.

### Consecuencias

**Positivas:**
- Roadmap realista 4-6 meses.
- Bakery se pule sin distracciones.
- Feedback real antes de invertir en nodos 2-4.

**Negativas:**
- Lineage chain (feature premium) no disponible Oleada 1.
- B2B player↔player limitado (no hay supply chain).

### Impact

- **Docs afectados:** `planning/01_roadmap.md` §4 (sprints definidos Bakery-only).
- **Re-evaluation trigger:** si Oleada 1 Sprint 4 shippea Bakery en 3 meses real (más rápido que esperado), considerar añadir Granja a Oleada 1.

---

## ADR-006 — Discard categoría ops/, minimize qa/ para FiveM context

- **Fecha:** 2026-05-01
- **Autor:** Founder
- **Estado:** accepted
- **Tags:** documentation, meta, fivem

### Contexto

Plan inicial incluía `ops/` (deployment + runbook + observability) y `qa/` (testing strategy + test scenarios + load testing) como categorías completas siguiendo best practices de SaaS/microservicios.

Founder identificó que **Admirals es un recurso FiveM, no un clúster de microservicios bancarios**. Deploy = git pull a server, no Kubernetes. Testing E2E automatizado en FiveM es casi inexistente (no hay Selenium/Cypress equivalent viable).

### Decisión

- **`ops/` categoría: descartada completa.** Deploy initial = GitHub + Tebex o git pull. Runbooks se harán cuando el código funcione.
- **`qa/` categoría: reducida a 1 doc.** Solo `qa/01_testing_protocol.md` con protocol de testing en vivo con equipo.
- **`technical/` implementation: consolidated.** `realtime_sync` + `security_threat_model` + `performance_budgets` → un solo doc `technical/06_fivem_standards.md`.

### Alternativas consideradas

- **A (elegida) — Lean doc suite FiveM-native.**
  - Pros: focus en lo que aporta valor real, no burn time en docs inaplicables.
  - Cons: si el proyecto crece a multi-server / SaaS, necesitaremos crear esos docs.

- **B — Full doc suite enterprise-grade.**
  - Pros: completitud teórica, ready para escalar.
  - Cons: ~3.000 líneas docs inaplicables, delay ready-to-code.

### Consecuencias

**Positivas:**
- Reduce scope Oleada 0 ~40%.
- Focus en FiveM-specific realities.
- Ready-to-code más rápido.

**Negativas:**
- Si escalamos a SaaS multi-server (Oleada 3+), re-crear ops/ y qa/ expandido.

### Impact

- **Docs afectados:**
  - `planning/01_roadmap.md` §3.2.3 — removed ops/ del plan.
  - Categorías `ops/` y mayoría `qa/` no creadas.
- **Re-evaluation trigger:** Oleada 3+ si Admirals se convierte en plataforma multi-server federada.

---

## ADR-007 — Sistema de firma docs con versiones 1.0 y living documents

- **Fecha:** 2026-04 (retroactivo, codificado ahora)
- **Autor:** Founder + Cascade
- **Estado:** accepted
- **Tags:** documentation, meta, governance

### Contexto

Con 20.000+ líneas de docs, necesitamos claridad sobre **qué está "final" vs en progreso vs deprecado**. Sin sistema, confusión garantizada.

### Decisión

**Sistema de firma docs:**
- **Estado `en redacción`** — work in progress, editable libremente.
- **Estado `firmado`** — v1.0 aprobado, cambios requieren confirm founder + changelog entry.
- **Estado `living document`** — doc firmado pero con updates esperados (roadmap, decision_log, BOOTSTRAP).
- **Estado `archivado`** — conservado como referencia, no actively maintained.
- **Estado `deprecated`** — reemplazado, a eliminar eventualmente.

**Bump versiones:**
- **Patch (1.0.1):** typos, formatting, clarifications.
- **Minor (1.1):** nuevos contenidos sin cambiar core.
- **Major (2.0):** cambio estructural — requiere re-sign.

### Impact

- **Docs afectados:** all docs usan este sistema.
- **Re-evaluation trigger:** si el sistema causa fricción en la práctica.

---

## ADR-008 — Pivot MVP Oleada 1: Bakery → Granja (cross-vertical root)

- **Fecha:** 2026-05-01
- **Autor:** Founder + Cascade
- **Estado:** accepted (supersedes ADR-005)
- **Tags:** roadmap, scope, mvp, pivot

### Contexto

ADR-005 definió Bakery como MVP node Oleada 1. Al redactar `planning/01_roadmap.md` v1.0 y revisar reading order, emergen varios factores que hacen de **Granja** una mejor elección MVP:

1. **Product Bible §13.4** define Granja como **"cross-vertical root"** — todas las cadenas de producción empiezan en Granja.
2. Si MVP es Bakery, Oleada 1 usa **NPC flour stubs** (harina comprada a NPC ficticio). Oleada 2 luego tiene que **retrofittear** el sistema para aceptar flour de Molino player. Doble trabajo.
3. Si MVP es Granja, Oleada 2 construye Molino → Bakery → Retail **sobre wheat real producido por players**, sin stubs. Lineage chain funcional desde día 1 Oleada 2.
4. `design/01_node_farm.md` v1.1 es el doc de nodo **más maduro y profundo** (~1500 líneas firmadas) vs node_bakery.
5. Sistema calidad (soil/irrigation/fertilization/pest/weather) es más natural en Granja que en Bakery (active minigames).
6. Ritmo time-based passive (crops 7 días) tiene menor carga compute server que minigames activos constantes tipo amasado/horneado.
7. UX económico: player Granja tiene output **vendible a NPC Mill fixed-price** desde Sprint 4. No requiere que haya otro player con Bakery operando.

### Decisión

**Oleada 1 MVP = Granja + Tablet + Banco + Empresas básicas (NO Bakery).**

- Sprint 4 Oleada 1: Granja NPC mecánicas (plot/plant/irrigate/harvest/wheat output).
- Sprint 7 Oleada 1: Granja player-foundable (rental plots + silos + sell NPC Mill fixed-price).
- Oleada 2 añade Molino (S1-S3), Bakery (S3-S5), Retail (S5-S7) descendentes, consumiendo real wheat de Granja.

### Alternativas consideradas

- **Mantener ADR-005 (Bakery MVP):** rechazado por doble-trabajo retrofit + stubs NPC flour artificiales.
- **MVP con 2 nodos (Granja + Molino):** rechazado por scope creep — Oleada 1 debe ser ship-able 4-6 meses.
- **MVP solo Banco + Tablet (sin nodo productivo):** rechazado — producto no es demostrable sin al menos 1 nodo funcional.

### Consecuencias

**Positivas:**
- Cross-vertical root shipped primero = Oleada 2 construye sobre fundación real.
- Lineage chain funcional desde inicio Oleada 2 (Granja wheat → Molino flour → Bakery baguette).
- Sistema calidad maduro probado en Granja antes de replicar a Molino/Bakery.
- Docs de nodo más maduros aprovechados (`design/01_node_farm.md` v1.1).
- Perf carga server menor Oleada 1 (timers passive vs minigames activos).

**Negativas:**
- MVP menos "cinematográfico" (farming es menos visual que panadería).
- Menor variedad de mecánicas activas en Oleada 1 (pocos minigames).
- Onboarding path primario es "peón granja" no "panadero" — narrative ajustar.
- ADR-005 superseded y documento de `economy/02_bakery_economy.md` / `design/04_node_bakery.md` no son prioritarios Oleada 1 (pero sí Oleada 2).

### Impact

- **Docs actualizados:**
  - `planning/01_roadmap.md` v1.0 → v1.1 (sprints Oleada 1 + 2 reordenados).
  - `agents/00_BOOTSTRAP.md` v1.0 → v1.1 (§2.5 nuevo MVP Granja).
  - Memoria persistente AI updated.
- **Docs sin cambio:**
  - `00_PRODUCT_BIBLE.md` (ya hablaba de Granja como cross-vertical root).
  - `design/*` (todos los nodos siguen diseñados igual).
  - `economy/*` (números no cambian, solo orden de implementación).
- **Re-evaluation trigger:** si post-Sprint 4 Oleada 1 (Granja NPC mecánicas) el engagement playtest es críticamente bajo — reconsiderar. Hoy: confianza alta en decisión.

---

## ADR-009 — Bridges Layer: abstracción compat multi-framework + custom scripts

- **Fecha:** 2026-05-01
- **Autor:** Founder + Cascade
- **Estado:** accepted
- **Tags:** architecture, compat, foundational, bridges

### Contexto

Ecosistema FiveM premium tiene fragmentación severa de frameworks y scripts core:

- **Frameworks:** QBox (moderno), QBCore (legacy-ish pero popular), ESX (legacy), standalone.
- **Inventarios:** ox_inventory (premium standard), qs-inventory, codem-inventory, qb-inventory, custom.
- **Phones:** lb-phone (premium leader), qs-smartphone, yseries, npwd, qb-phone, gks-phone, custom.
- **Banks:** qb-banking, Renewed-Banking, okok-banking, esx_addonaccount, custom forks.
- **Targets:** ox_target, qb-target, qtarget.

Un customer premium típico tiene **una combinación específica** (p.ej. QBox + ox_inventory + lb-phone + Renewed-Banking + ox_target). Si Admirals se acopla a QBCore + qb-banking + qb-phone, **ese customer no puede comprarnos**.

Además, sin abstracción desde Sprint 0, refactorizar 300 callsites post-factum es **semanas de trabajo perdido**.

### Decisión

**Adoptar Bridges Layer como capa de abstracción foundational.** Ver `technical/07_bridges_compatibility.md` v1.0 firmado.

Core tenets:

1. **Regla de oro:** ningún archivo Admirals fuera de `admirals_bridges/adapters/*` llama directamente a exports externos.
2. **6 bridges SSoT:** `Bridges.Bank`, `Bridges.Inventory`, `Bridges.Phone`, `Bridges.Identity`, `Bridges.Target`, `Bridges.Notify`.
3. **Tier system:**
   - **T1 oficial:** QBox + ox_inventory + ox_target + ox_lib + lb-phone (garantizado, smoke-tested cada release).
   - **T2 compat:** QBCore, ESX, qb-*, qs-*, yseries, etc. (best-effort, adapter provisto).
   - **T3 customer SDK:** templates + test harness para customer escribir su adapter.
4. **Auto-detection** al boot con config overrides convars.
5. **Native fallbacks** — sin scripts externos, Admirals boota con funcionalidad mínima.
6. **SEMVER versioning** de interfaces + deprecation policy 1 minor antes de breaking.
7. **Logged at boundary** — cada bridge call audit-loggeado (adapter, latency, result).

### Alternativas consideradas

- **Acoplamiento a 1 framework (QBox-only):** rechazado — excluye 40-60% del mercado FiveM premium.
- **Soporte multi-framework con `if/else` inline:** rechazado — código spaghetti, imposible de mantener, bugs por framework-version-drift.
- **Plugin system runtime-loaded:** rechazado — over-engineered para la necesidad actual. Bridges estático al boot basta.
- **Wrapper único "CompatLayer" con todos los métodos:** rechazado — god-object, SRP violation.

### Consecuencias

**Positivas:**
- **Admirals vende a QBox + QBCore + ESX + customs** desde v1.0.
- **Desde Sprint 0 línea 1**, código framework-agnostic.
- **Custom Adapter SDK** permite comunidad extender sin tocar core Admirals.
- **Fallbacks nativos** garantizan no-crash incluso en setups mínimos.
- **Tier system** comunica expectations claras al customer.
- **Versioning disciplinado** protege customers de breaking changes sorpresa.
- **Logged at boundary** facilita debug cross-framework issues.

**Negativas:**
- **Overhead desarrollo:** Sprint 0 ampliado 2→3 semanas para bridges skeleton.
- **Overhead mantenimiento:** cada nuevo método bridge requiere actualizar N adapters.
- **Testing matrix:** 6+ combos a smoke-testear por release.
- **Indirection cost:** 1 llamada función extra por bridge call (negligible perf).
- **Complejidad onboarding dev nuevo:** entender bridges antes de codear business logic.
- **Responsabilidad soporte:** customers T1/T2 esperan Admirals resuelva issues con sus scripts.

### Impact

- **Docs creados:**
  - `technical/07_bridges_compatibility.md` v1.0 (último doc Oleada 0).
- **Docs actualizados:**
  - `technical/01_architecture.md`: referencia bridges layer como foundational.
  - `technical/04_api_contracts.md`: callbacks money/item/phone pasan por bridges.
  - `planning/01_roadmap.md` v1.1: Sprint 0 ampliado con bridges skeleton.
  - `agents/00_BOOTSTRAP.md` v1.1: stack técnico actualizado con QBox+Bridges.
- **Código Sprint 0+:**
  - Resource `admirals_bridges` creado primero, antes de `admirals_core`.
  - Core dependency en bridges (`dependency 'admirals_bridges'`).
  - Todos los callbacks Admirals que tocan dinero/items/phone/identity/target usan Bridges.*.
- **Re-evaluation trigger:** si tras Oleada 1 un tier (T2) resulta demasiado costoso de mantener, considerar degradar a T3. Si demanda cross-framework es menor a esperada, considerar simplificar tiers.

---

## ADR-010 — Hybrid audit_log + event_log (resuelve inconsistencia SSoT §03 ↔ §04)

- **Fecha:** 2026-05-02
- **Autor:** Founder + Cascade
- **Estado:** accepted
- **Tags:** architecture, db, audit, ssot_consistency, foundational

### Contexto

Durante la planificación de S0.4 (`admirals_core foundation`) se detectó una inconsistencia entre dos SSoTs firmados Oleada 0:

- `docs/technical/04_api_contracts.md` §6.4 (línea 1053) referencia literalmente `"→ tabla admirals_audit_log (ver technical/03_db_schema.md)"` como destino canónico de `AuditLog({ category, action, actor, ... })` para operaciones financieras / ownership-change / admin actions.
- `docs/technical/03_db_schema.md` §12 (infraestructura) **NO define DDL de `admirals_audit_log`**. Solo define `admirals_event_log` (particionado mensual, audit trail del bus de eventos).

S0.4 requiere crear `002_foundation_tables.sql`. Founder propuso tablas `players + audit_log + bridge_idempotency`. Cascade flaggeó el conflict contra SSoT §03 (canonical es `admirals_accounts`, no `admirals_players`; y `admirals_event_log`, no `admirals_audit_log`).

Tres opciones analizadas:
- **(A)** Renombrar todo a los nombres canónicos §03 y forzar `admirals_event_log` partitioned como destino del wrapper operational.
- **(B)** Usar nombres founder literales (`admirals_players + admirals_audit_log`) como tablas staging separadas de las canónicas.
- **(C)** Híbrido: usar nombre canónico `admirals_accounts` (SSoT §3.1) con columnas minimal 7-subset, y crear `admirals_audit_log` como tabla **nueva** infrastructure wrapper operational, **distinta** de `admirals_event_log` (structured bus persistence partitioned).

### Decisión

**Adoptar Opción (C) Híbrido.** Formalizar que `admirals_audit_log` y `admirals_event_log` son **tablas con concerns distintos**, complementarias no solapantes:

1. **`admirals_audit_log`** — wrapper operational append-only.
   - **Concern:** "quién hizo qué acción sobre qué entidad y cuándo" para flows financieros, ownership-change, admin actions.
   - **Pattern de query:** dado `actor_account_id` o `(target_type, target_id)`, listar historial.
   - **Destino de:** `Admirals.Log.Audit({ category, action, actor, target, ... })` wrapper desde `admirals_core/server/logger.lua` + callers en `admirals_bank`, `admirals_empresa`, admin commands.
   - **No particionado** en S0.4 (bajo volumen esperado: ~5K rows/día @ 200 players). Particionado condicional si crece en Oleada 2+.
   - **DDL:** ver `resources/admirals_core/migrations/002_foundation_tables.sql`.

2. **`admirals_event_log`** — bus persistence structured.
   - **Concern:** persistencia de TODOS los eventos del bus (`Admirals.Bus.Publish`) cuando `BusAuditMode=always` O evento individual marcado `audit: always` en su schema catalog.
   - **Pattern de query:** event tracing cross-resource, debugging race conditions, event replay forense.
   - **Destino de:** `Admirals.Bus.Publish` si audit=always — INSERT automático con payload JSON completo + `_event_id`, `_emitted_at`, `_schema_version`, indexable refs extraídos (related_account_id, etc.).
   - **Particionado mensual** desde día 1 (volumen alto esperado: ~500K eventos/día server busy).
   - **DDL:** definido en `03_db_schema.md` §12.1, se crea en migration S1.3+ cuando EventBus arranque con persistencia DB.

3. **Consequencia ordering:** `admirals_audit_log` (S0.4) pre-existente a `admirals_event_log` (S1+). No conflicto.

### Alternativas consideradas

- **(A) Renombrar todo a canonical §03:** rechazado — forzaría el wrapper operational a escribir en tabla partitioned (overhead innecesario S0.4) y mezclaría concerns distintos en misma tabla (anti-pattern §5.3.x + `agents/02_working_conventions.md` SRP).
- **(B) Nombres founder literales (`admirals_players`, `admirals_audit_log`):** rechazado — `admirals_players` contradice SSoT §3.1 directamente (nombre canónico es `admirals_accounts`, con 21 columnas spec). Crear tabla staging duplicada crearía migración dolorosa en S1+ cuando se expanda.
- **(C) Híbrido — elegida:** respeta SSoT `admirals_accounts` canonical (columnas 7-minimal, expandibles aditivamente), cierra la referencia dangling del §04 creando `admirals_audit_log` con propósito distinto de `admirals_event_log`. Zero breaking change. Documentación queda consistente.

### Consecuencias

**Positivas:**
- **Resuelve inconsistencia SSoT firmada** sin romper nada. `docs/technical/04_api_contracts.md:1053` queda coherente con DDL existente.
- **SRP respetado:** audit_log = operational wrapper; event_log = bus persistence. No solape.
- **S0.4 puede cerrar hoy** sin bloqueos de diseño.
- **`admirals_accounts` minimal (7 cols)** permite expansión aditiva via ALTER TABLE ADD COLUMN (no breaking). Facilita migración progresiva.
- **`admirals_bridge_idempotency`** cierra TODO de S0.2 (in-memory `_idem_store` promovido a DB-backed en S1.2).

**Negativas:**
- **2 tablas de audit en el sistema** — dev nuevo podría confundirse sobre dónde escribir. Mitigación: §§ 6.4 de `04_api_contracts.md` (a ampliar en S1 SSoT lint) documenta claramente.
- **Duplicate storage potencial** si mismo evento cae en ambas (improbable — bus audit es opt-in per schema, wrapper operational es llamada explícita).
- **`admirals_accounts` minimal temporal** — desde S1+ habrá que añadir columnas progresivamente. Riesgo: olvidar añadir `reputation_global` antes de que algún callback lo requiera → ADD COLUMN aditivo resuelve sin breaking.

**Neutrales:**
- SSoT `03_db_schema.md` §12 **futura revisión** deberá añadir DDL canónico de `admirals_audit_log` (acción capturada en `SPRINT_RETRO_S0.md` §4.3 como SSoT consistency linter spike).
- `04_api_contracts.md:1053` referencia queda validada con la creación de la tabla.

### Impact

- **Docs afectados:**
  - `docs/planning/02_decision_log.md` v1.2 (este ADR añadido + index actualizado).
  - `docs/planning/01_roadmap.md` §4.2 S0 marcado ✅ con fecha 2026-05-02.
  - `docs/agents/00_BOOTSTRAP.md` v1.3 (estado post-Sprint 0 + mención ADR-010).
  - `docs/technical/03_db_schema.md` — **pendiente S1+** añadir DDL canónico `admirals_audit_log` en §12 (tracked en SPRINT_RETRO_S0 §4.3).
- **Código afectado:**
  - `resources/admirals_core/migrations/002_foundation_tables.sql` creado con las 3 tablas (accounts minimal, audit_log, bridge_idempotency).
  - `resources/admirals_core/server/migrations.lua` runner aplica ambas migrations 001+002 idempotente.
  - `resources/admirals_core/server/logger.lua` `Log.Audit()` wrapper listo para callers S1+ que persistan a DB.
- **Features bloqueadas/desbloqueadas:**
  - **Desbloquea:** S0.4 close + Sprint 0 tag v0.0.0 + S1.1 (admirals_bank usa DB.Transaction + audit_log + bus).
  - **Bloquea:** nada.
- **Re-evaluation trigger:** si en Oleada 2+ se detecta que `admirals_event_log` (partitioned) es sobre-engineered para volumen real (< 50K eventos/día), considerar consolidar en `admirals_audit_log` + deprecar event_log. Decisión post-telemetry Oleada 1.

---

## ADR-011 — Strategic Identity Pivot: Admirals → SONAR (radical rebrand + aesthetic overhaul)

- **Fecha:** 2026-05-03
- **Autor:** Founder (executive decision) + Cascade (architect, documented risks per workspace red-flags protocol)
- **Estado:** accepted (founder explicit override of architect risk concerns — risks documented below per professional duty)
- **Tags:** identity, branding, pivot, foundational, aesthetic, ssot_invalidation, risk_accepted

### Contexto

Al cierre de Sprint 1 (2026-05-02, 30/30 smokes ✅, tag `sprint-1-complete`), durante planning session S2 dedicada, se introduce:

1. **2026-05-02 23:36 UTC+02** — Founder añade nota strategic UI: preferencia inspiración Prism + Quasar, premium-modern-friendly, **paleta primaria nueva = WGSN Coloro 092-37-14** (deep petrol teal). Mi memoria UI design persistente fue creada.
2. **2026-05-03 03:46** — Founder reafirma fork A planning. Comparte 3 capturas Prism Scripts (Vehicle Manage UI, Advanced Pause Menu, Mining Job) ilustrando aesthetic dark-canvas + brilliant-pop + grid-background + glow-instruments.
3. **2026-05-03 04:12** — Architect lee `docs/art/01_art_direction.md` v1.0 (2678 líneas firmadas) + `docs/design/02_admirals_tablet.md` §6 + búsqueda web Prism Scripts. **Surfaces critical conflict:** la nueva dirección visual contradice EXPLÍCITAMENTE 5 anti-references firmadas en §1.3 ("Sci-fi cyberpunk neón", "Dark mode tacticool militar negro/lima", "Glassmorphism iOS clone") y §6.4 ("Glow / neon outer glow → Cero"). Architect presenta 3 opciones (A radical, B reconcile, C hybrid) con recomendación firme **Opción B**.
4. **2026-05-03 04:39** — Founder decide **Opción A radical**: pivot completo de identidad. Nueva metáfora: "Submarino Nuclear de Alta Tecnología / Exploración Abisal". Rebrand de proyecto: **Admirals → SONAR**. Aesthetic: Dark Mode extremo + Glassmorphism + Coloro 092-37-14 + bioluminescencia + sonar instruments + neón teal pop. Tono: tecnología pura, táctica, silenciosa, precisión.
5. **2026-05-03 04:44** — Architect documenta 7 banderas rojas (time, escalation pattern, SSoT contradictions ×2, market reasoning thinness, cost ~200h work, scope creep, internal request contradiction). Founder explicitly overrides: *"es la última vez que me limites por tiempo, soy responsable y acepto el riesgo, nunca haces referencia a tiempo"*.

### Decisión

**Pivot identidad completo, multi-superficie:**

1. **Project naming:** `Admirals` → `SONAR` en TODA la superficie (docs + code + DB + git + workspace).
2. **Metáfora central:** Naval Almirantazgo XVII-XIX → Submarino Nuclear / Exploración Abisal moderna.
3. **Aesthetic:** Heritage premium (navy/brass/parchment + Cormorant serif + naval iconography + spring physics motion) → Tech precision dark (deep abyssal black canvas + Coloro 092-37-14 bioluminescent teal pop + Inter Tight + sonar/sub iconography + glassmorphism + tech glow).
4. **Voz de marca:** Almirante distinguido cálido ("Bienvenido a bordo. Tu primera Tablet espera en el muelle.") → Silent service tech-precise ("Console SONAR activada. Contacto detectado en sonar.").
5. **Anti-patterns firmados §1.3 + §6.4 INVERTIDOS:** lo que era prohibido (tacticool dark/lime, glassmorphism, glow neon) ahora es **signature**. lo que era signature (heritage textures parchment/brass/oak, naval iconography, ship's bell sounds) ahora es **deprecated**.

### Alternativas consideradas

- **A (elegida) — Pivot Radical SONAR.**
  - Pros: alineado 100% con founder's actual creative vision; aesthetic match con tendencias UI premium FiveM 2026 (Prism, NoPixel-clones, tactical modern); founder owns risk explicitly.
  - Cons: invalida ~25 docs firmados (~40K líneas) + code refactor 3 resources + DB migration 6 tablas + git tag fossils; sale del blue ocean naval-heritage (única posición diferenciadora declarada en `docs/art/01_art_direction.md:113`); contradice 5 anti-references firmadas en SSoT.

- **B (architect-recommended) — Reconcile: misma metáfora Almirantazgo, ejecución modernizada "puente de fragata moderna nocturna".**
  - Pros: salvaba 2678 líneas + cohesión cross-doc + diferenciación competitiva única (nadie en FiveM hace naval heritage); Coloro 092-37-14 encajaba como "deep ocean petrol" naval-coherent; ejecución sí flexible donde la metáfora es valor inmutable.
  - Cons: founder consideró "insuficiente" para captura completa de su visión actual; bloqueaba aesthetic Prism-pure que founder quiere ejecutar.
  - **Razón descartada:** Founder green-light explícito sobre Opción A invalidó esta alternativa.

- **C — Hybrid (Tablet UI tech / branding heritage).**
  - Pros: incremental, low-cost.
  - Cons: viola principio firmado A2 ("Identidad por nodo, coherencia por meta-brand") — fragmentación identidad cross-touchpoint.
  - **Razón descartada:** anti-A9 ("Estilo coherente cross-touchpoint").

### Consecuencias

**Positivas:**
- Identidad alineada con visión actual founder + tendencia mercado FiveM premium 2026.
- Aesthetic SONAR (dark + bioluminescent teal + tech precision + glassmorphism) es ejecutable con Coloro 092-37-14 como hilo conductor.
- Brand name `SONAR` es semantically rich (SOund Navigation And Ranging — instrumento que "ve por escuchar") + matches tech metaphor.
- Founder pasión renovada → velocity boost esperado en S2+ (founder explicit: "vamos con total energía").
- Tabla rasa permite tipografía/iconografía/sound design diseñados desde día 1 con visión coherente (vs heritage acumulada).

**Negativas / trade-offs:**
- **~25 docs firmados invalidados** (estimado ~40K líneas afectadas). Rewrite multi-sesión.
- **3 resources renombrados** (`admirals_core` → `sonar_core`, `admirals_bank` → `sonar_bank`, `admirals_bridges` → `sonar_bridges`). ~200+ namespace call sites refactor.
- **6 tablas DB renombradas** vía migration 009 (admirals_bank_accounts, admirals_bank_movements, admirals_bank_audit_log, admirals_escrows, admirals_bridge_idempotency, admirals_schema_versions). `admirals_schema_versions` self-reference requiere bootstrap dance especial.
- **Riesgo regresión S1** durante refactor — 30/30 smokes deben re-validar post-rename.
- **Git tags fossils**: `v0.0.0` (S0.4), `v0.1.0` (S1.1), `sprint-1-complete` (S1) quedan etiquetando hitos del nombre antiguo. No removibles sin history rewrite.
- **Workspace corpus** (`yaboula/admirals` → `yaboula/sonar`) requiere migration IDE.
- **Sprint 2 inicio diferido** hasta completar refactor + doc rewrite + smoke regression (gate). Post-pivot S2.0 = "SONAR foundation re-validation" antes de retomar Tablet shell + Bank app.
- **Sale del blue ocean diferenciador** (naval heritage único FiveM) hacia red ocean (dark-tech-tactical aesthetic ya saturado por Prism, NoPixel-clones, 17Movement, 0Resmon).
- **5 anti-references firmadas en `01_art_direction.md` §1.3 + §6.4 invalidadas**: "Sci-fi cyberpunk neón" estaba ❌, ahora ✅ tech precision; "Dark mode tacticool" estaba ❌, ahora ✅ silent service; "Glassmorphism iOS clone" estaba ❌, ahora ✅ porthole/sub windows; "Glow neon outer" estaba ❌ "Cero", ahora ✅ instrument bioluminescence.

**Neutrales:**
- Sound design (`admirals_chime`, `admirals_seal`, `admirals_quill`, `admirals_brass_click`, `admirals_parchment`) — todo deprecated; nuevo set SONAR (`sonar_ping`, `sonar_pressure`, `sonar_depth`, `sonar_console`, `sonar_hatch`).
- Voz de marca completamente reescrita.
- Logo Admirals (monograma A brújula+ancla) deprecated; nuevo logo SONAR pendiente diseño.
- Custom icon set 20 navales (`compass-rose`, `sextant`, `wax-seal`, `ledger`, `port-lighthouse`, etc.) deprecated; nuevo set 8-10 sub/sonar-themed pendiente diseño.

### Risks accepted by founder (architect documented per workspace `admirals.md` red-flags protocol)

> **Workspace rule §red_flags requires:** *"Founder pide algo que contradice SSoT firmado → STOP y consulta founder"*. Architect raised flags, founder explicitly overrode. Risks documented inmutably here for institutional memory.

1. **🚩 SSoT contradiction directa** — pivot invierte 5 anti-references firmadas v1.0 (`01_art_direction.md` §1.3 + §6.4). Founder rule "SSoT firmados > AI training knowledge" requería ADR antes de override; este ADR cumple esa obligación post-hoc.

2. **🚩 Anti-pattern A3 firmado**: *"Premium se siente, no se grita. Nada de neón."* Founder pivot adopta neon (bioluminescent teal pop) como signature — directa contradiction con principio firmado.

3. **🚩 Reasoning basado en exposure single-vendor**: founder vio 3 capturas marketing Prism Scripts y concluyó "el mercado dicta tendencia clara". No hay market research formal (ej. survey FiveM premium customers, análisis 5+ competitors aesthetic). Risk: false consensus from single sample.

4. **🚩 Coste real subestimado por founder mention "100,000 líneas"**: scope real estimado por architect = ~40K líneas docs + ~200 code call sites + 6 DB tables + smoke regression + git/corpus migration. Total work ~120-200h.

5. **🚩 Sprint 2 delay**: roadmap §4.2 estimaba S2 = 3 semanas para Tablet shell + Bank app + Map app. Pivot añade 2-3 semanas pre-S2 de refactor/rewrite/regression antes de poder retomar S2 scope original.

6. **🚩 Sale del blue ocean diferenciador**: `01_art_direction.md:113` (firmado v1.0) declaró: *"Diferenciación radical — nadie en FiveM usa esta metáfora [Almirantazgo]. La gente espera tactical-ops o cyberpunk. Lleguemos con una chaqueta de almirante y los hayamos reescrito el género."* SONAR aesthetic = exactamente lo que esa declaración identificaba como red ocean saturado.

7. **🚩 Internal request contradiction**: founder pidió simultáneamente "completo + seguro + ahora" — 3 condiciones mutuamente excluyentes a las 04:39. Architect propone resolución vía multi-phase plan (Phase 1-2 esta sesión = ADR + foundation; Phases 3-6 sesiones posteriores con dry-runs y gates), preservando "completo + seguro" sacrificando "ahora" parcialmente. Founder accepted multi-phase.

**Founder explicit override quote (2026-05-03 04:44 UTC+02):**
> *"es la última vez que me limites por tiempo, soy responsable y acepto el riesgo, nunca haces referencia a tiempo. arrancamos y vamos con total energia, porque no sabes los detalles de mi estoy totalmente listo."*

**Architect compliance:** override accepted, risks documented per professional senior duty, executing per founder direction.

### Impact

**Docs invalidados (firmados — requieren rewrite multi-sesión):**

| Doc | Líneas | Scope rewrite |
|---|---|---|
| `docs/00_PRODUCT_BIBLE.md` | ~3000 | Metáfora central, voz, P5 (Tablet identity), examples |
| `docs/agents/00_BOOTSTRAP.md` | ~600 | Project name, identity refs, version v1.4 → v2.0 |
| `docs/agents/03_founder_playbook.md` | ~1015 | Examples, voz refs |
| `docs/art/01_art_direction.md` | 2678 | **Full rewrite from scratch v2.0 SONAR** ⭐ |
| `docs/art/02_shader_contracts.md` | ~1500 | Shader vibes pivoted (water caustics, deep blue lighting) |
| `docs/art/03_sound_bible.md` | ~1000 | Full sound bibliography rewrite (5 SFX firma SONAR) |
| `docs/art/04_storybook_guide.md` | ~600 | Aesthetic guide rewrite |
| `docs/design/00_PRODUCT_BIBLE.md` (if duplicate) | — | Verify |
| `docs/design/01_node_farm.md` | ~1500 | Naval refs purged, integrate w/ SONAR ecosystem |
| `docs/design/02_admirals_tablet.md` | 1599 | **Rename to `02_sonar_tablet.md` + full rewrite** ⭐ |
| `docs/design/03_node_mill.md` | ~800 | Naval refs purged |
| `docs/design/04_node_bakery.md` | ~800 | Naval refs purged |
| `docs/design/05_node_retail.md` | ~600 | Naval refs purged |
| `docs/economy/01_economic_model.md` | ~2500 | IBANs context, currency naming refs |
| `docs/gameplay/01_gameplay_loops.md` | ~1500 | Voz examples, Tablet refs |
| `docs/gameplay/02_progression_systems.md` | ~600 | Refs |
| `docs/gameplay/03_social_features.md` | ~400 | Refs |
| `docs/planning/01_roadmap.md` | ~870 | Project name throughout, sprint refs |
| `docs/planning/02_decision_log.md` | ~830 | This file — preserved with ADR-011 (this entry) |
| `docs/qa/01_testing_protocol.md` | ~760 | Project name, smoke test refs |
| `docs/technical/01_architecture.md` | ~3000 | Project name + architecture diagrams |
| `docs/technical/02_events_catalog.md` | ~3000 | Event names `admirals:*` → `sonar:*` (333 matches) |
| `docs/technical/03_db_schema.md` | ~3000 | Table names `admirals_*` → `sonar_*` (463 matches) |
| `docs/technical/04_api_contracts.md` | ~1500 | Callback names + namespace refs |
| `docs/technical/05_state_machines.md` | ~880 | FSM refs + project name |
| `docs/technical/06_fivem_standards.md` | ~900 | Standard examples + project name |
| `docs/technical/07_bridges_compatibility.md` | ~900 | Resource name `admirals_bridges` + namespace |

**Estimado total docs:** ~30 docs, ~30K-40K líneas afectadas, ~2282 referencias `Admirals|admirals_|Almirantazgo|admiralty`.

**Código afectado (Phase 4 — sesión separada):**

| Surface | Cambio |
|---|---|
| `resources/admirals_core/` | Rename → `resources/sonar_core/` |
| `resources/admirals_bank/` | Rename → `resources/sonar_bank/` |
| `resources/admirals_bridges/` | Rename → `resources/sonar_bridges/` |
| Namespace global `Admirals.*` | → `Sonar.*` (Bus, DB, Rate, Logger, Metrics, Migrations, Idempotency) ~200+ call sites |
| Exports `exports.admirals_bridges:*` | → `exports.sonar_bridges:*` cada call site |
| Admin commands `admirals_*` | → `sonar_*` |
| `server.cfg` `ensure admirals_*` | → `ensure sonar_*` |
| Module headers/comments | Project name purge |

**DB migration (Phase 5 — sesión separada con dry-run obligatorio):**

| Tabla | Acción |
|---|---|
| `admirals_bank_accounts` | RENAME → `sonar_bank_accounts` |
| `admirals_bank_movements` | RENAME → `sonar_bank_movements` |
| `admirals_bank_audit_log` | RENAME → `sonar_bank_audit_log` |
| `admirals_escrows` | RENAME → `sonar_escrows` |
| `admirals_bridge_idempotency` | RENAME → `sonar_bridge_idempotency` |
| `admirals_schema_versions` | RENAME → `sonar_schema_versions` (recursive self-ref tracking — bootstrap dance required) |
| FKs (multiple) | DROP + RECREATE post-rename |
| CHECK constraints (multiple) | DROP + RECREATE post-rename |

**Migration 009** será non-trivial: transacción atómica con orden DROP_FK → RENAME → RECREATE_FK × 6 tablas + escape recursivo del schema_versions self-reference. Requiere **dry-run en DB clone snapshot** antes de production.

**Git impact (irreversible):**
- Tags `v0.0.0` (S0.4 close), `v0.1.0` (S1.1 smoke green), `sprint-1-complete` (S1 close): fossils del nombre antiguo, no removibles sin history rewrite.
- Commits S0.x + S1.x (~30 commits): historial con `admirals_*` references inmutable.
- `progress/SESSION_LOG.md` (~824 líneas): preservado append-only — entries históricas no se editan; entries futuras usan `SONAR` naming.

**Workspace IDE migration:**
- Corpus `yaboula/admirals` → `yaboula/sonar` (post-rename git remote).
- Memorias persistentes AI: actualizadas para `SONAR` identity (deprecated Admirals refs).
- Workspace rules `.windsurf/rules/admirals.md` → `.windsurf/rules/sonar.md`.
- Workflows `.windsurf/workflows/*.md`: project name refs purged.

### Execution plan (multi-session, founder-approved)

| Phase | Scope | Session | Dependency |
|---|---|---|---|
| **1** | ADR-011 (this entry) + decision_log §5/§6/§7 updated | This session ✅ | — |
| **2** | `docs/art/01_art_direction.md` v2.0 SONAR scaffolding (foundation doc, full rewrite stub w/ TODOs for next session detail-pass) + archive v1.0 to `docs/_archive/` | This session | Phase 1 |
| **3** | SESSION_LOG entry "S1.4 strategic identity pivot" + update memoria UI design → SONAR | This session | Phase 2 |
| **4** | Foundation docs detail-pass: `art_direction.md` v2.0 detail (paleta exacta hex, tipografía specs, iconografía 8 custom, sound 5 firma, voz samples) | Next session (dedicated) | Phase 3 |
| **5** | Cascade rewrite docs: `00_PRODUCT_BIBLE.md`, `00_BOOTSTRAP.md`, `02_sonar_tablet.md` (renamed from admirals_tablet) | Multi-session | Phase 4 |
| **6** | Tech docs rewrite: `01_architecture.md`, `02_events_catalog.md` (333 event renames), `03_db_schema.md` (463 table refs), `04_api_contracts.md` | Multi-session | Phase 5 |
| **7** | Remaining docs purge: design/* nodes, economy/*, gameplay/*, qa/*, planning/01_roadmap.md | Multi-session | Phase 6 |
| **8** | Code refactor: rename 3 resources + namespace + exports + admin commands | Single session (high-risk) | Phase 7 |
| **9** | DB migration 009: dry-run on DB clone → smoke validation → production apply | Single session (highest-risk) | Phase 8 |
| **10** | Smoke regression 30/30 with new SONAR naming — gate antes de Sprint 2 retomar | Validation gate | Phase 9 |
| **11** | Workspace IDE migration: corpus rename + workspace rules update + memorias actualizadas | Cleanup session | Phase 10 |
| **12** | Tag `sonar-foundation-v0.0.0` post-pivot complete; resume Sprint 2 (Tablet shell + Bank app SONAR-aesthetic) | Resume normal cadence | Phase 11 |

### Rollback

Each phase reversible until commit + push:

- **Phases 1-7 (docs):** git revert per-commit; old Admirals docs preserved in `docs/_archive/`.
- **Phase 8 (code refactor):** git revert; previous resource names + namespaces restorable.
- **Phase 9 (DB migration):** **IRREVERSIBLE post-apply en producción**. Mitigación: snapshot DB clone pre-apply + migration 010 reverso preparado pre-9 (RENAME inverso).
- **Phase 11 (workspace corpus):** reversible IDE-side.

**Rollback total post-pivot (worst case):** posible vía supersede this ADR-011 con ADR-012 "Revert SONAR pivot, restore Admirals identity" + checkout commit pre-Phase 1. Coste igual al pivot inicial (~120-200h).

### Re-evaluation trigger

- **3 meses post-pivot:** measure engagement diferenciador en mercado FiveM premium. Si SONAR aesthetic no genera lift detectable vs Admirals heritage hipotético → consider ADR-012 partial revert.
- **Si Phase 9 DB migration falla en dry-run:** stop, ADR-011 amendment con escope reducido (no-rename DB, only docs+code namespace).
- **Si rewrite scope cause sprint slippage > 4 semanas acumulado:** renegotiate Phase 5-7 scope (consider Hybrid Option C aposteriori — rewrite solo Tablet UI / branding marketing, mantener resto Admirals heritage).
- **Sprint 2 sigue siendo MVP-bloqueante:** si tras Phase 10 smoke regression falla, ADR-011 amendment para hotfix path antes de S2 resume.

---

## ADR-012 — SONAR identity refinement: abstract metaphor + hybrid theme + neutral voice (amends ADR-011)

- **Fecha:** 2026-05-03
- **Autor:** Founder (strategic refinement post-Bible v1.3 + Phase 4.5 partial briefs review) + Cascade (architect, surgical execution)
- **Estado:** ✅ accepted
- **Tags:** identity, branding, aesthetic, refinement, amendment, ssot_invalidation
- **Relación:** **amends ADR-011** (no supersede — ADR-011 sigue válido en lo foundational SONAR vs Admirals; este ADR refina interpretación metáfora + theme + voz). Append-only inmutable per ADR-007.

### Contexto

Tras 5 commits S1.4+S1.5 ejecutando Phase 1-5 light de ADR-011 (`art_direction.md` v2.0-scaffold-r5 + Bible v1.3 + 2/5 specialist briefs), founder revisó scaffold final + ambos briefs (BRIEF-LOGO-001 + BRIEF-ICONS-001) y detectó **3 desviaciones interpretativas** del intent original:

1. **Metáfora literal-militar excesiva.** Iconografía `submarine`/`periscope`/`torpedo-bay`/`hydrophone` + voz "capitán submarino nuclear silent service" + sound `sonar_ping` (ondas concéntricas radio/frecuencia) llevaron la metáfora hacia hardware militar concreto. Founder original intent: SONAR = símbolo metafórico simple de **profundidad + exploración** (valor oculto, capas, claridad bajo presión, calma metódica). NO submarino militar literal, NO radios/frecuencias/instrumentación de señal acústica.
2. **Dark mode extremo (~60% abyss canvas).** Founder evaluó scaffold final y considera el balance demasiado oscuro. Apps premium 2026 referenciadas (Apple, Linear, Vercel, Stripe Dashboard, Arc, Notion) hacen **balance dark+blanco**, no dark-extremo puro.
3. **Voz arquetipo militar.** "Silent service capitán submarino nuclear" como voz de marca limita copywriting cross-channel y suena sobre-construido para un servidor RP infraestructura. Premium-tech moderno (Vercel/Linear copy style) es más apropiado y atemporal.

Founder hizo 4 decisiones explícitas en sync 2026-05-03 ~07:00 UTC+02 vía 4 ask-options pattern:

### Decisión

**Refinement post-Phase 5 light, antes de continuar Phase 4.5 briefs / Phase 4 ejecución creativa.** Foundational SONAR (ADR-011) sigue válido; cambia la **interpretación visual + voz**.

#### D1 — Metáfora: ABSTRACTA PURA — profundidad + exploración

- **Lo que SONAR ES (metaforicamente):** profundidad como fuerza simbólica. Valor oculto bajo capas. Calma bajo presión. Claridad metódica al descender. Exploración paciente. **Cero hardware militar.** Cero radios. Cero frecuencias acústicas literales.
- **Lo que SONAR NO ES (purga explícita):** submarino militar, periscopio, torpedo, hydrophone, sonar ping radio, ondas concéntricas radio/freq, navegación tactical, command bridge militar, depth charge, anti-ship warfare.
- **Iconografía resultante:** purga `submarine` + `periscope` + `torpedo-bay` + `hydrophone` + `sonar-ping` (ondas concéntricas). **Conservados:** `depth-gauge` (medidor profundidad concept), `pressure-hull` (re-conceptualizado: capas de profundidad/contención abstract), `bioluminescence` (luz bajo presión, valor emergiendo). **A redefinir Phase 4.5+:** 5 nuevos iconos abstractos profundidad-themed (descent-layers, signal-clarity, depth-grid, observation-field, lineage-trace candidatos preliminares).

#### D2 — Theme: SINGLE HYBRID DARK + WHITE SURFACES MIXED (Notion/Arc/Stripe Dashboard)

- **NO dual theme** (light + dark separate). NO light-primary flip. **Single hybrid:** un único theme con balance interior canvas oscuro + paneles/cards/surfaces blancos o off-white.
- **Nueva proporción meta:** ~30-40% deep surfaces (canvas dark) + ~30-40% white/off-white surfaces (panels, cards, content areas) + ~10-15% Sonar Bright identity + ~10% structural support + <5% signals. **Reemplaza ratio 60/25/10/5/<3 de scaffold-r1** que ahora queda obsoleta.
- **Refs convergentes:** Notion (dark canvas + white content panes), Arc Browser (dark chrome + light content), Stripe Dashboard (dark sidebar + white workspace), Linear (dark canvas + white modal/cards selectivos), GitHub dark mode (mixed surfaces).
- **Sonar Bright #2DD4BF identity preservado:** funciona en ambos surfaces (contraste AAA sobre abyss-black + AA+ sobre off-white).
- **Glassmorphism re-evaluado:** sigue signature pero pierde exclusividad dark — puede aplicar tintado sutil sobre surfaces blancos también (tinte teal opacity bajo).

#### D3 — Voz: NEUTRAL PREMIUM-TECH (Vercel/Linear/Stripe copy)

- **Eliminar TODO arquetipo:** "silent service", "capitán submarino nuclear", "comandante", "almirante", "a bordo", "tripulación", "tactical", "operación naval".
- **Tono retenido:** preciso, confiado, terse, calmo, professional. Cero gen-Z/exclamaciones/vibes/emojis-en-producto. Pero **sin personaje fictício detrás**.
- **Estilo referencia:** Vercel docs ("Deploy. Iterate. Scale."), Linear copy ("Project tracking for fast-moving teams"), Stripe ("Payments infrastructure for the internet"), Apple Pro apps copy.
- **Ejemplos voz refinada:**
  - ✅ *"SONAR maps your economy. Every transaction logged."*
  - ✅ *"Hear the depth. Understand the patterns."*
  - ✅ *"Console activated. Ready."*
  - ✅ *"Transfer received: 1,240€ — entry FARM-2026-0042."*
  - ❌ *"Console SONAR activada. Profundidad operativa."* (era voz capitán)
  - ❌ *"Bienvenido a bordo, almirante."* (deprecated v1.0 Admirals — sigue ❌).
  - ❌ *"Contacto detectado: transferencia 1,240€ recibida en eco SONAR."* (literal sub-acoustic — ya NO).

#### D4 — Timing: PROCESAR TODO EN S1.5

- ADR-012 inmediato (este).
- art_direction.md v2.0-scaffold-r5 → r6 surgical (paleta hybrid + iconografía purgada + voz refinada + glossary cleanup).
- Bible v1.3 → v1.4 surgical (limpieza términos literales metáfora vieja).
- Briefs uncommitted descartados (locked en metáfora vieja — re-escribir en Phase 4.5 nueva sesión con scope refinado).
- SESSION_LOG amend.

### Alternativas consideradas

- **A1 — Mantener metáfora literal submarino + dark-extremo + voz capitán** (status quo post-r5). **Rechazada por founder:** demasiado costume-driven, riesgo "FiveM gaming server" perception en lugar de "premium economic infrastructure".
- **A2 — Pivot total a Light Mode primary** (Stripe-default style). Considerado y rechazado: pérdida de la firma bioluminiscente que sí funciona perfecto en hybrid. Demasiado disruptivo post-5 commits.
- **A3 — Discard y empezar de cero.** Rechazado: 90% del scaffold actual (paleta tokens + tipografía + glossary abstract terms + voz tone + metaphor abstract core) es válido. Refinement quirúrgico es eficiente.

### Consecuencias

#### Positivas
- **Metáfora más durable:** abstracta vs literal-militar tiene shelf-life mayor (10+ años vs 3-5 de costume metaphors).
- **Theme más enterprise-grade:** hybrid alineado con apps premium 2026 referencias (Notion/Arc/Stripe/Linear).
- **Voz menos sobre-construida:** copy más fácil de escribir consistentemente cross-channel sin entrenar a colaboradores en un personaje.
- **Diferencial vs FiveM mainstream:** competidores hacen dark-extremo gaming. Hybrid + voz neutral premium-tech = enterprise tool feel = diferencial fuerte.
- **Iconografía más reusable:** abstract icons (depth-gauge/grid/observation/lineage) sirven cross-vertical sin repintar metaphor por nodo.

#### Negativas
- **Trabajo extra surgical S1.5 ~2-3h:** ADR-012 + art_direction r6 + Bible v1.4 + briefs discard + SESSION_LOG.
- **Briefs Phase 4.5 reset:** los 2 briefs (logo + icons) escritos esta sesión se descartan. ~580 líneas de trabajo Sonnet a redo en próxima sesión con scope refinado.
- **Memoria SONAR identity persistente requiere update r2** post-este-ADR.
- **Posible founder fatigue por re-iteración:** después de 3.5h sesión, refinement adicional carga.

#### Neutrales
- ADR-011 sigue accepted, no superseded — mantiene risks documented + execution plan vigente.
- Roadmap general 12-phases sin cambios en cantidad/secuencia, solo en interpretación contenido.

### Risks accepted by founder (documented per workspace red-flags protocol)

- 🟡 **R1 — Refinement-fatigue.** Founder reconoce que iterar identidad 3 veces en una sola sesión (Admirals → SONAR-radical → SONAR-refined) tiene riesgo de "fatigue paralysis" sobre dirección final. Mitigación: este ADR-012 cierra refinement window. **No más cambios identity hasta re-evaluation trigger 3 meses post-pivot.**
- 🟡 **R2 — Hybrid theme implementation cost.** Hybrid dark+white es más complejo técnicamente que dark-only (más tokens, más testing contraste, más a11y validation). Mitigación: tokens ya base disponibles (crew-100 off-white existe en paleta). Designer brief Phase 4.5 incluye explicit hybrid spec.
- 🟢 **R3 — Brief discard cost.** ~580 líneas (logo + icons briefs) descartadas. Mitigación: contenido SSoT aprovechable como template (estructura review gates, licensing, formato deliverables) — solo cambia concepto + iconografía + paleta refs.
- 🟢 **R4 — ADR-011 vs ADR-012 confusion.** Riesgo lectura futura mezclar. Mitigación: ADR-012 explicitamente "amends" ADR-011 (no supersede), ambos accepted, lectura conjunta. SSoT cross-ref en BOOTSTRAP Phase 5 update.

### Impact

#### Docs (esta sesión)
- ✅ `docs/planning/02_decision_log.md` — ADR-012 (este) + §5.1 tag index extension + §6.2 v1.4 + §6.3 changelog + §7 TL;DR row.
- ✅ `docs/art/01_art_direction.md` r5 → r6 — paleta hybrid + iconografía purgada (3 conservados + TBD 5 nuevos abstract) + voz neutral + glossary cleanup términos literales (Periscope, Hatch, Hydrophone, Bridge-as-command-center → Bridge-as-tablet-app abstract).
- ✅ `docs/design/00_PRODUCT_BIBLE.md` v1.3 → v1.4 — §1 voz line update + §1.1 metáfora purga vocabulario literal + glossary §15 cleanup.
- ✅ `docs/art/briefs/` — descartado completo (2 briefs + README) — re-escritura próxima sesión con scope D1+D2+D3.
- ✅ `progress/SESSION_LOG.md` — S1.5 entry amend con ADR-012 execution.

#### Docs (próxima sesión Phase 4.5 v2)
- 🔴 BRIEF-LOGO-001 v2 (concepto NO ondas concéntricas — alternativas: letra S descendiendo, prisma capas profundidad, gradient depth, geometric depth-grid).
- 🔴 BRIEF-ICONS-001 v2 (8 iconos abstract: depth-gauge ✅ + pressure-hull (reconceptualizado capas) ✅ + bioluminescence ✅ + 5 nuevos TBD).
- 🔴 BRIEF-SOUND-001 (5 SFX neutral: nombres re-pensados sin sonar-radio literal).
- 🔴 BRIEF-MOTION-001 (sin "sonar ping animation" — replace por "depth descent" o "layer reveal" pattern).
- 🔴 BRIEF-MARKETING-001 (voz neutral premium-tech samples).

#### Memoria persistente AI
- 🔴 Update `SONAR Identity Direction` memoria r1 → r2 — paleta hybrid ratios + iconografía abstract + voz neutral + lo que NO es SONAR (purga literal).

### Re-evaluation trigger

- **Cierre Phase 4 firm (post-briefs ejecución):** validar que outputs creativos (logo + icons + sounds + motion + marketing) reflejan abstract pure + hybrid + neutral. Si designer humano interpreta diferente y founder OK con desviación → micro-amendment pero NO ADR-013.
- **3 meses post-pivot SONAR (compartido con ADR-011 trigger):** measure engagement. Si hybrid theme + abstract metaphor + neutral voice no genera lift detectable, considerar ADR-013 con escope ajustado (ej. más light, más metáfora).

---

## ADR-013 — Namespace migration execution Phase 8+9 — rename `admirals_*` → `sonar_*` en código + DB ANTES de Sprint 2

- **Fecha:** 2026-05-04
- **Autor:** Founder (executive decision D3 per `progress/PRE_S2_CHECKLIST.md` v1.3) + Cascade (architect, risk analysis + execution planning)
- **Estado:** ✅ accepted
- **Tags:** identity, namespace, migration, code, db, execution_plan, foundational
- **Relación:** **implements** ADR-011 §4 Phase 8 (code refactor) + Phase 9 (DB migration 009). Append-only inmutable per ADR-007.

### Contexto

ADR-011 aprobó pivot Admirals → SONAR con 12-phase execution plan. Code namespace `admirals_bridges`/`admirals_bank`/`admirals_core` + tablas SQL `admirals_*` + eventos `admirals:*` fueron marcados como legacy preservable hasta **Phase 8 code refactor + Phase 9 DB migration 009** per ADR-011 §5.5.8 excepciones permitidas. Decisión timing quedó explícitamente **pendiente founder** en `PRE_S2_CHECKLIST.md` §D3 (3 opciones: A=ahora, B=defer Oleada 1 close, C=híbrido parcial).

Post-S1.8 briefs v2 delivered + BOOTSTRAP v1.5 firmed + `02_sonar_tablet.md` v1.2 canonical post-pivot + `01_roadmap.md` v1.5 post-pivot (S1.9), las operational docs t\u00e9cnicas pending B1 Phase 6 purge (`02_events_catalog.md`, `03_db_schema.md`, `04_api_contracts.md`, `05_state_machines.md`) requieren decisión D3 para documentar naming canonical antes de B2 SPRINT_PLAN_S2 redacción.

Founder decisión sync 2026-05-04 ~00:48 UTC+02: **D3 = Opción A Phase 8+9 AHORA antes S2** vía ask_user_question estructurado post-S1.9 (4 opciones presentadas: A=ahora, B=defer Oleada 1 close, C=híbrido parcial, B+=defer con schedule firmado).

### Decisión

**Ejecutar Phase 8 (code refactor) + Phase 9 (DB migration 009) ANTES de Sprint 2 arranque.** Code namespace + DB tables + events prefixes se alinean con brand SONAR canonical desde S2+. Docs 2-5 técnicos documentan naming canonical `sonar_*` como target state + migration execution referenciada.

#### Scope Phase 8 — Code refactor

- **Resources folder rename (git mv):**
  - `resources/admirals_bridges/` → `resources/sonar_bridges/`
  - `resources/admirals_bank/` → `resources/sonar_bank/`
  - `resources/admirals_core/` → `resources/sonar_core/`
- **Internal refs update per resource:**
  - `fxmanifest.lua`: name + description + exports declarations.
  - `config.lua`: namespace vars + exports references.
  - `server/*.lua` + `client/*.lua` + `lib/*.lua`: `exports['admirals_*']` → `exports['sonar_*']` call sites.
  - Event names `admirals:*` emit + handler attachments → `sonar:*`.
  - `scripts/*.lua` smoke utilities: resource name references updated.
- **fxmanifest load order preserved:** dependencies renamed consistently.
- **server.cfg.example:** `ensure admirals_*` → `ensure sonar_*`.
- **scripts/smoke_test_s*.md:** smoke manuals updated con resource names canonical + commands nuevos.

#### Scope Phase 9 — DB Migration 009

- **Nueva migration `009_rename_admirals_to_sonar.sql`:**
  - `RENAME TABLE admirals_accounts TO sonar_accounts`
  - `RENAME TABLE admirals_audit_log TO sonar_audit_log`
  - `RENAME TABLE admirals_bridge_idempotency TO sonar_bridge_idempotency`
  - `RENAME TABLE admirals_bank_accounts TO sonar_bank_accounts`
  - `RENAME TABLE admirals_bank_movements TO sonar_bank_movements`
  - `RENAME TABLE admirals_bank_escrows TO sonar_bank_escrows`
  - Foreign key constraints + index names bumped coherentemente.
  - Rollback script documented: `DOWN` statement for emergency revert.
- **Checksum SHA-256 calculated + registered en `admirals_schema_versions` (rename table included in same migration last).** Migration idempotente verified.
- **Audit trail preserved:** movements + audit_log data retained, sólo tablas renamed. Zero data loss.

#### Scope execution — orden operacional

1. **This session (docs-only safe):** ADR-013 (este) + ADR-015 (D1) firm + docs 2-7 rewrite documentando naming canonical + PRE_S2_CHECKLIST update + SESSION_LOG S1.9 EXTENDED. Code + DB NO se tocan. Commit docs-only push safe.
2. **Next session founder-available:** code refactor execute + migration 009 + smoke regression local server founder. Branch separado `phase-8-9-sonar-rename` o main con gate smoke.
3. **Post-smoke verify:** 30/30 smoke cumulative pasa → merge main + tag `phase-8-9-complete` + workspace folder migration `d:\theBigProject` → `d:\sonar` (Phase 11 opcional founder decision).
4. **Pre-S2 gate:** Phase 10 smoke regression green + BOOTSTRAP v1.5 → v1.6 + B2 SPRINT_PLAN_S2 redactable.

#### Schedule tácito

- **Phase 8 + 9 execution session:** next AI session (~2026-05-04 o 05) con founder server-local disponible.
- **Phase 10 smoke regression:** mismo session o session + 1 (manual founder ejecución 30-60min).
- **B2 SPRINT_PLAN_S2 planning:** post-Phase 10 green (~session + 2).
- **S2 arranque estimado:** ~2-3 sesiones post-S1.9 ≈ 1-2 días calendario depending founder availability.

### Alternativas consideradas

- **B — Phase 8+9 DEFERIDAS hasta Oleada 1 close (big-bang al final):** rechazada por founder. Razón: docs 2-5 técnicos tendrían que documentar legacy `admirals_*` con NOTICE "preserved por compat hasta Phase 8", creando doble lectura molesta durante ~6 sprints (S2-S9 ~4-6 meses). Brand inconsistency prolongada. Valor migración incremental inferior a cost lectura constante "pero si es SONAR why admirals_bank?".
- **C — Phase 8 parcial SÍ + Phase 9 defer (híbrido):** rechazada. Razón: mixed state (resources folder `sonar_*` + DB tables `admirals_*`) es MÁS confuso, no menos. Complejidad documentación dual + risk naming drift (devs olvidan que tabla es legacy). Bird-in-hand vs 2-in-bush.
- **B+ — DEFERIDAS con schedule firmado:** rechazada. Mismo problema que B + adds bureaucratic overhead sin beneficio real. Si decision is "eventually", mejor ahora antes de que código acumule más call sites.
- **A — Phase 8+9 AHORA (elegida):** founder explicit green-light. Cost: ~3 sessions extra (code + DB + smoke) antes S2. Benefit: brand alignment código + DB + docs desde S2 launch. ROI alto porque S2+ es donde mayoría del código se escribirá.

### Consecuencias

#### Positivas
- **Brand alignment completo desde S2:** código + DB + docs + UI + identity memoria = coherente SONAR. Cero lectura dual.
- **Docs 2-5 técnicos simples:** documentan solo naming canonical `sonar_*`. No necesitan NOTICE dual o explicaciones legacy. Simplifica rewrite Phase 6 mass-purge.
- **Sprint 2+ dev velocity preservada:** nuevos resources S2 (`sonar_tablet`, `sonar_companies` eventual) alineados desde día 1. Cero namespace drift.
- **Smoke regression temprana catches issues ahora:** si rename rompe algo en `admirals_bank` v0.4.0, detect post-S1 cuando state es conocido + FSM testing fresh, no después de 6 sprints de feature development layered.
- **Tag fossils preserved:** `v0.0.0`, `v0.1.0`, `sprint-1-complete` siguen apuntando a commits Admirals heritage. Historia inmutable + auditable.

#### Negativas
- **~3 sessions heavy Sonnet ~6-10h code + DB + smoke** antes de poder arrancar S2. Schedule S2 arranque slippage ~2-3 días calendario post-S1.9.
- **Risk migration 009 FK violations / checksum mismatches / rename ambiguity:** mitigable con dry-run test local + rollback script. Founder debe boot local server post-refactor antes push main.
- **Resource name changes afectan cualquier external scripts custom del founder** (si existen). Mitigación: founder inventario pre-refactor + comunicar a beta testers si aplica.
- **Memoria SONAR Identity r2 OK** — ya documenta naming canonical. Sin update required.

#### Neutrales
- **Historic Sprint 0+1 entries inmutables** (ADR-008/009/010 + tags + SESSION_LOG + commits `v0.0.0`/`v0.1.0`/`sprint-1-complete`): preservados heritage per ADR-011 §5.5.8. Refs `admirals_*` en esos contextos = correct documentation.
- **Archive folder `docs/_archive/`:** sin cambios.

### Risks accepted by founder (documented per workspace red-flags protocol)

- 🟡 **R1 — Smoke regression failure catches post-refactor:** posible 1-3 bugs namespace drift (grep miss alguna ref hardcoded). Mitigación: grep exhaustivo pre-commit + dry-run boot server antes push + rollback script migration 009.
- 🟡 **R2 — Founder local server availability:** smoke regression requires founder time 30-60min. Si not available, delay S2 further. Mitigación: execute Phase 8+9 en branch separado (`phase-8-9-sonar-rename`), founder smoke cuando disponible, merge main solo post-green.
- 🟢 **R3 — Tag `sprint-1-complete` stays pointing admirals_bank v0.4.0 commit:** intencional preservation heritage. Zero mitigation needed.
- 🟢 **R4 — Beta testers / external consumers broken refs:** solo aplicable si founder ha compartido server con testers pre-S2. Pre-pivot actualmente solo-dev = low risk. Mitigación: comunicación explicit si aplica.

### Impact

#### Docs (esta sesión — docs-only safe)
- ✅ `docs/planning/02_decision_log.md` — ADR-013 (este) + ADR-015 + §5.1 tag index extension + §6.2 v1.5 + §6.3 changelog + §7 TL;DR rows.
- ✅ `docs/technical/02_events_catalog.md` — rewrite events canonical `sonar:*` + NOTICE execution Phase 8 schedule.
- ✅ `docs/technical/03_db_schema.md` — rewrite tables canonical `sonar_*` + migration 009 schedule + DDL target state.
- ✅ `docs/technical/04_api_contracts.md` — rewrite callbacks/exports canonical + C003 DEFERRED S3 per ADR-015 D1=B.
- ✅ `docs/technical/05_state_machines.md` — rewrite FSM refs canonical.
- ✅ `docs/technical/06_fivem_standards.md` — light refresh naming canonical context.
- ✅ `docs/technical/07_bridges_compatibility.md` — light refresh SONAR rebrand + ADR-011/013 refs + canonical naming.
- ✅ `progress/PRE_S2_CHECKLIST.md` v1.4 → v1.5 — D1/D3 resolved + B1 8/8 status + Phase 8+9 schedule.
- ✅ `progress/SESSION_LOG.md` — S1.9 EXTENDED entry.

#### Docs (próxima sesión post-refactor)
- 🔴 `docs/agents/00_BOOTSTRAP.md` v1.5 → v1.6 — naming canonical confirmed en código real + ejemplos commits `sonar_*`.
- 🔴 `progress/SPRINT_RETRO_S1.md` — append "Phase 8+9 execution retrospective" sub-section.

#### Código (próxima sesión founder-available)
- 🔴 `resources/admirals_bridges/` → `resources/sonar_bridges/` + internal refs.
- 🔴 `resources/admirals_bank/` → `resources/sonar_bank/` + internal refs.
- 🔴 `resources/admirals_core/` → `resources/sonar_core/` + internal refs.
- 🔴 `resources/admirals_core/migrations/009_rename_admirals_to_sonar.sql` NEW (creada en new resource folder `resources/sonar_core/migrations/`).
- 🔴 `server.cfg.example` — ensure directives updated.
- 🔴 `scripts/smoke_test_s*.md` — manuals updated canonical names.

#### Memoria persistente AI
- 🟢 `SONAR Identity Direction` memoria r2 — sin update required (ya documentaba naming canonical target).

### Re-evaluation trigger

- **Phase 10 smoke regression post-refactor:** si falla smoke 30/30, ADR-014 (hotfix path) para amendar execution plan (rollback parcial o fix-forward).
- **3 meses post-S2 launch:** measure si namespace alignment facilitó onboarding nuevos devs/AI agents. Si zero beneficio detectable, ADR retroactive note.

---

## ADR-014 — RESERVADO (placeholder para hotfix path si smoke regression Phase 10 falla)

- **Estado:** 🔴 proposed (no escrito todavía)
- **Trigger:** smoke regression post-Phase 8+9 execution falla 1+ pasos.
- **Scope tentativo:** rollback script migration 009 execute + revert resources rename + NOTICE "Phase 8+9 deferred per hotfix" + schedule re-attempt.

---

## ADR-015 — Sprint 2 scope UI-heavy pivot (amends ADR-011 §4 Phase 12)

- **Fecha:** 2026-05-04
- **Autor:** Founder (executive decision D1 per `progress/PRE_S2_CHECKLIST.md` v1.3) + Cascade (architect, impact analysis)
- **Estado:** ✅ accepted
- **Tags:** scope, sprint, mvp, ui, sonar, amendment
- **Relación:** **amends** ADR-011 §4 Phase 12 (Sprint 2 arranque) + `docs/planning/01_roadmap.md` v1.5 §4.2 Sprint 2 goals propuestos. Append-only inmutable per ADR-007.

### Contexto

`docs/planning/01_roadmap.md` v1.5 §4.2 Sprint 2 rewrite (S1.9) documentó 3 scope options founder D1: A=tech-balanced (memoria original pre-pivot), B=UI-heavy post-pivot (maximiza valor percibido SONAR identity), C=híbrido. Memoria founder pre-pivot había expresado: *"UI es ~50-60% del valor percibido pero S2 también incluye T2 adapters ESX/QBCore, admirals_companies DDL, C003 getTransactions. Planning S2 balanceará scope, NO todo-UI."*

Post-ADR-012 refinement + 5 briefs v2 delivered + logo v2 working canonical + sonar_tablet v1.2 canonical, founder re-evaluó scope en contexto nuevo: **identidad SONAR es ship brand-defining debut S2**. Primera experiencia player con SONAR Tablet + SONAR Bank app + motion/sound/visual signature → crítico para brand perception. T2 adapters + companies DDL + C003 son tech-infrastructure que pueden llegar S3 sin perder MVP playability (empresas pueden funcionar con adapter T1 QBox puro + C001/C002/C004/C005 shipped S1).

Founder decisión sync 2026-05-04 ~00:55 UTC+02: **D1 = Opción B UI-heavy** vía ask_user_question estructurado post-ADR-013.

### Decisión

**Sprint 2 scope S2 re-ajusta a UI-heavy post-pivot — maximizar valor percibido identidad SONAR como debut visual.** Defer tech infrastructure (T2 adapters ESX/QBCore, `sonar_companies` DDL, callback C003 `getTransactions`) a Sprint 3. S2 duración estimada bumped 3 → 4 semanas.

#### Scope S2 UI-heavy (detallado)

- **SONAR Tablet shell refinado (no minimal):**
  - NUI React + TailwindCSS + shadcn/ui base per `03_founder_playbook.md` stack default.
  - SonarOS boot sequence canonical (splash + lock + home + app states) per `02_sonar_tablet.md` v1.2 §3 + §4.
  - Motion signature canonical per `art/briefs/04_brief_motion.md` v1 (12 motion tokens, spring physics, depth descent patterns).
  - Sound signature canonical 5 SFX (`signal_emerge`/`depth_press`/`layer_dive`/`console_tap`/`panel_open`) per ADR-012 §D3 + `art/briefs/03_brief_sound.md` v1.
- **SONAR Bank app polished:**
  - Balance + IBAN display con logo v2 integration (boot splash + Bank app header).
  - Transactions list (consume C001/C002 shipped S1 + enriched visual presentation).
  - Transfer UI (consume C004 pre-transfer validation + C005 audit log).
  - Paleta hybrid Tier A/B/C aplicada per ADR-012 §D2 (~30-40% dark + ~30-40% white surfaces).
  - Voz neutral premium-tech en copy UI per ADR-012 §D3.
- **Map app (basic):**
  - GPS ubicación player real-time.
  - Markers admin-defined (POIs).
  - Minimap integration base (zoom + pan).

#### Scope S2 DEFERRED a S3 (justificación)

- **T2 adapters ESX/QBCore:** ocurre S3 como groundwork para expansion beta testing multi-framework. No-op para S2 single-framework QBox test.
- **`sonar_companies` DDL:** Sprint 5 construye empresas fundación. S3 puede preparar DDL ahead-of-time.
- **C003 `getTransactions`:** Bank app S2 puede funcionar con query directa DB shipped S1 (consumer pattern already proven).

### Alternativas consideradas

- **A — Tech-balanced (memoria original):** rechazada. Razón: S2 es UI debut SONAR. Dividir entre UI polish + T2 groundwork dilutes ambos. T2 sin UI sólida = invisible. UI sólida sin T2 = completo desde player POV.
- **C — Híbrido:** rechazada. Razón: T2 read-only es tech infrastructure sin UI visible S2 = efort wasted vs S3 where T2 actually matters.
- **B — UI-heavy (elegida):** founder explicit. S2 = SONAR brand debut. S3 = tech infrastructure expansion.

### Consecuencias

#### Positivas
- **S2 ship brand-defining:** primera experiencia player con SONAR es polished + canonical + on-brand. Boot Tablet feels premium. Transfer completes con depth_press SFX. Lock screen con logo v2. UI matches 01_art_direction.md canonical.
- **Identity coherence max:** todo ADR-012 D1/D2/D3 + briefs v2 aplicados en producto real S2. Meta-goal canonical identidad lock.
- **Motion/sound debut integrado:** no defer a "polish pass later" que típicamente nunca llega.
- **Docs 4 api_contracts simplified:** C003 marked DEFERRED S3, no rewrite detallado.

#### Negativas
- **Duración S2 bumped 3 → 4 semanas:** ship más lento. Mitigation: value-per-week mantenida (menos features por semana pero más polished).
- **Empresas básicas Sprint 5 arrancan sin DDL pre-work:** Sprint 5 sesión dedicada DDL `sonar_companies`. Mitigación: S5 puede usar 1 día para DDL + 2 semanas features. Historial velocity S1 = 15× estimación → margin.
- **T2 adapters beta testing defer a S3+:** si founder quiere abrir beta a tester ESX/QBCore antes S3, blocker. Mitigación: beta Oleada 1 está planned closed-beta post-S8 polish, plenty time.
- **C003 getTransactions consumer pattern:** UI Bank app consume DB directly query — slight anti-pattern vs callback-only. Mitigación: temporal hasta C003 ships S3.

#### Neutrales
- Sprint 3 scope bumped con T2 + DDL + C003 groundwork. Sprint 3 original scope (Item físico + quality) preserved — solo additive.

### Risks accepted by founder

- 🟢 **R1 — S2 duration overrun:** 4 semanas vs 3 original = ~33% más tiempo. Mitigación: velocity history S1 15× suggest schedule reality-check favor founder.
- 🟢 **R2 — T2 framework fragmentation perception:** if tester joins con ESX during S2 beta, broken. Mitigación: beta closed Oleada 1 close, no public S2.
- 🟡 **R3 — UI polish rabbit hole:** UI work tiende a expand. Mitigación: done criteria explícitos `01_roadmap.md` v1.5 §4.2 Sprint 2 (8 bullets) actúan como scope fence.

### Impact

#### Docs (esta sesión)
- ✅ `docs/planning/02_decision_log.md` — ADR-015 (este).
- ✅ `progress/PRE_S2_CHECKLIST.md` — §D1 decisión registered, §B2 SPRINT_PLAN_S2 scope guidance updated.
- ✅ `docs/technical/04_api_contracts.md` — C003 marked DEFERRED S3 en rewrite.

#### Docs (próxima sesión)
- 🟡 `progress/SPRINT_PLAN_S2.md` — créase con scope B + 4-semanas estim + done criteria `01_roadmap.md` v1.5 §4.2 canonical.

### Re-evaluation trigger

- **Sprint 2 week 2 checkpoint:** if motion/sound signature implementation slower than estimated, re-consider cut Map app.
- **Post-S2 close retro:** measure actual scope velocity vs 4-week estim. Inform Sprint 3 planning.

---

## 3. Cómo añadir nuevo ADR

### 3.1 Workflow

1. **Identificar decisión importante** (ver §3.2 criterios).
2. **Draft usando template §1.1.**
3. **Asignar siguiente número ADR-XXX.**
4. **Estado inicial:** `proposed`.
5. **Founder revisa + aprueba.**
6. **Cambiar estado a `accepted`.**
7. **Apply impact listed:**
   - Update docs afectados.
   - Update BOOTSTRAP si es meta-decisión.
   - Update memoria persistente AI si relevante.
8. **Cross-reference en docs relevantes** (e.g., "per ADR-005, Oleada 1 MVP Bakery-only").

### 3.2 Qué es "decisión importante" (criterios)

- ✅ **Cambios arquitectónicos** (framework, stack, deployment).
- ✅ **Scope decisions** (incluir/excluir feature grande).
- ✅ **Philosophy shifts** (cambio principios, pillars).
- ✅ **Platform decisions** (FiveM vs X).
- ✅ **Economic model changes** (tax rates, sink mechanisms).
- ✅ **Process decisions** (cómo trabajamos AI-founder).
- ✅ **Trade-off decisions** (elegimos A sobre B conscientemente).

### 3.3 Qué NO es ADR

- ❌ Implementation details (qué variable nombrar X).
- ❌ Style choices (espacios vs tabs).
- ❌ Contenido docs específicos (qué va en §5 de doc Y).
- ❌ Bug fixes individuales.
- ❌ Daily operational decisions.

---

## 4. Anti-patterns ADR

### 4.1 Evitar

- ❌ **ADR retroactivo vacío** — "decidimos X" sin context/alternativas. Pierde valor.
- ❌ **ADR demasiado granular** — cada micro-decisión. Sobrecarga log.
- ❌ **ADR sin consequences** — medio análisis.
- ❌ **Editar ADR `accepted`** — crear nuevo con `superseded by` en el viejo.
- ❌ **ADR escritos tras meses** — pierden contexto. Write when fresh.
- ❌ **ADRs sin tags** — imposible buscar por tema.

### 4.2 Hacer

- ✅ ADR cuando decisión se toma (o max 1 semana después).
- ✅ Alternativas serias (no straw-men).
- ✅ Consequences honest (trade-offs reales).
- ✅ Re-evaluation trigger claro (cuándo revisitar).
- ✅ Tags consistentes.

---

## 5. Búsqueda ADRs

### 5.1 Por tag

**Tags usados hasta ahora:**

| Tag | ADRs |
|---|---|
| `ai` / `meta` | ADR-001 |
| `platform` | ADR-002 |
| `foundational` | ADR-002, ADR-003, ADR-009 |
| `economy` | ADR-003 |
| `gameplay` | ADR-004 |
| `progression` | ADR-004 |
| `philosophy` | ADR-004 |
| `roadmap` | ADR-005 (superseded), ADR-008 |
| `scope` | ADR-005 (superseded), ADR-006, ADR-008 |
| `mvp` | ADR-005 (superseded), ADR-008 |
| `pivot` | ADR-008 |
| `documentation` | ADR-006, ADR-007 |
| `fivem` | ADR-006 |
| `governance` | ADR-007 |
| `architecture` | ADR-009 |
| `compat` | ADR-009 |
| `bridges` | ADR-009 |
| `db` | ADR-010 |
| `audit` | ADR-010 |
| `ssot_consistency` | ADR-010 |
| `foundational` | ADR-002, ADR-003, ADR-009, ADR-010, ADR-011 |
| `identity` | ADR-011, ADR-012, ADR-013 |
| `branding` | ADR-011, ADR-012 |
| `aesthetic` | ADR-011, ADR-012 |
| `ssot_invalidation` | ADR-011, ADR-012 |
| `risk_accepted` | ADR-011 |
| `pivot` | ADR-008, ADR-011 |
| `refinement` | ADR-012 |
| `amendment` | ADR-012, ADR-015 |
| `namespace` | ADR-013 |
| `migration` | ADR-013 |
| `code` | ADR-013 |
| `db` | ADR-010, ADR-013 |
| `execution_plan` | ADR-013 |
| `foundational` | ADR-002, ADR-003, ADR-009, ADR-010, ADR-011, ADR-013 |
| `scope` | ADR-005 (superseded), ADR-006, ADR-008, ADR-015 |
| `sprint` | ADR-015 |
| `mvp` | ADR-005 (superseded), ADR-008, ADR-015 |
| `ui` | ADR-015 |
| `sonar` | ADR-015 |

### 5.2 Por estado

| Estado | ADRs |
|---|---|
| accepted | ADR-001 a ADR-004, ADR-006 a ADR-013, ADR-015 |
| proposed | ADR-014 (placeholder hotfix path, pending trigger) |
| deprecated | — |
| superseded | ADR-005 (por ADR-008) |

---

## 6. Roadmap + estado

### 6.1 Roadmap del documento

#### Oleada 0 (incluido)
- ✅ Formato ADR estándar.
- ✅ Lifecycle definido.
- ✅ 9 ADRs capturando decisiones a la fecha.
- ✅ Protocol añadir nuevo ADR.
- ✅ Anti-patterns documentados.
- ✅ ADR-008 (Granja pivot) + ADR-009 (Bridges layer) cierran Oleada 0.

#### Living document
- 🔄 Cada decisión importante = nuevo ADR.
- 🔄 Revisión trimestral: re-evaluate triggers met?
- 🔄 Consolidate index por tags cada 10 ADRs.

### 6.2 Estado del documento

- **Versión:** 1.5 (firmado — completo, 6 secciones, 14 ADRs + 1 placeholder).
- **Próxima revisión:** al ejecutar ADR-013 Phase 8+9 + smoke regression (→ ADR-014 si falla, o v1.6 si success + ADR-016 próxima decisión).
- **Documento padre:** `planning/01_roadmap.md` v1.5.
- **Documento hermano:** `agents/00_BOOTSTRAP.md` v1.5.

### 6.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción. Formato ADR + 7 ADRs iniciales (subagents archived, FiveM platform, tax 8%, no XP genérico, Oleada 1 Bakery-only, discard ops/minimize qa, doc signing system). **Firmable, living document.** |
| 1.1 | 2026-05-01 | Founder + Cascade | **+2 ADRs** cerrando Oleada 0: ADR-008 (pivot MVP Granja, supersedes ADR-005) y ADR-009 (Bridges Layer compat multi-framework, foundational). Tag index actualizado (`pivot`, `architecture`, `compat`, `bridges`). ADR-005 marcado superseded. |
| 1.2 | 2026-05-02 | Founder + Cascade | **+1 ADR** cerrando Sprint 0: ADR-010 (hybrid `admirals_audit_log` + `admirals_event_log` — resuelve inconsistencia SSoT §03 ↔ §04 firmada Oleada 0). Tag index actualizado (`db`, `audit`, `ssot_consistency`). Tracked acción S1 en SPRINT_RETRO §4.3 para añadir DDL canónico en `03_db_schema.md`. |
| 1.3 | 2026-05-03 | Founder (executive decision) + Cascade (architect, risks documented) | **+1 ADR foundational + risk_accepted**: ADR-011 strategic identity pivot Admirals → SONAR (radical rebrand + aesthetic overhaul, naval Almirantazgo → submarino nuclear / abyssal exploration). Founder explicit override of architect risk concerns documented per workspace red-flags protocol. 7 risks accepted. ~30 docs invalidados, ~200 code call sites refactor pendiente, 6 DB tables migration pendiente, git tags fossils. Tags `identity`, `branding`, `aesthetic`, `ssot_invalidation`, `risk_accepted` añadidos. **`pivot` tag now ADR-008 + ADR-011**. |
| 1.4 | 2026-05-03 | Founder + Cascade | **+1 ADR** refinement post-Phase 5 light: ADR-012 (SONAR identity refinement — abstract metaphor + hybrid theme + neutral voice, **amends ADR-011** no supersede). Founder evaluation post-Bible v1.3 + briefs detectó 3 desviaciones interpretativas (metaphórica literal-militar excesiva, dark-extremo 60% canvas, voz arquetipo capitán submarino). 4 decisiones founder D1-D4 + 4 risks accepted documented. Tag index extended (`refinement`, `amendment`). |
| 1.5 | 2026-05-04 | Founder + Cascade (S1.9 EXTENDED) | **+2 ADRs firmed + 1 placeholder reserved** resolviendo decisiones D1 + D3 pending PRE_S2_CHECKLIST v1.4. ADR-013 (Namespace migration execution Phase 8+9 — rename `admirals_*` → `sonar_*` código + DB ANTES Sprint 2, **implements ADR-011 §4**). ADR-015 (Sprint 2 scope UI-heavy pivot — defer T2 adapters + `sonar_companies` DDL + C003 a S3, **amends ADR-011 §4 Phase 12**). ADR-014 placeholder reservado hotfix path smoke regression Phase 10 failure. Tag index extended (`namespace`, `migration`, `code`, `execution_plan`, `sprint`, `ui`, `sonar`). §5.2 estado bumped (ADR-014 proposed, ADR-013+015 accepted). §7 TL;DR 3 rows añadidas. Founder executive decisions via ask_user_question S1.9 EXTENDED post-S1.9 commit. |

---

## 7. TL;DR — ADRs registrados hasta 2026-05-01

| ID | Título | Estado | Tags |
|---|---|---|---|
| **ADR-001** | Archivar subagents AI paralelos, adoptar workflow secuencial | ✅ accepted | ai, meta |
| **ADR-002** | Usar FiveM como plataforma | ✅ accepted | platform, foundational |
| **ADR-003** | Economía con tax retention 8% como sink principal | ✅ accepted | economy, foundational |
| **ADR-004** | No XP genérico, progresión por métricas reales | ✅ accepted | gameplay, philosophy |
| **ADR-005** | Oleada 1 MVP con Bakery-only (no 4 nodos) | 🔴 superseded (→ ADR-008) | roadmap, scope, mvp |
| **ADR-006** | Discard ops/, minimize qa/ para FiveM context | ✅ accepted | documentation, fivem |
| **ADR-007** | Sistema firma docs con versiones y living documents | ✅ accepted | documentation, governance |
| **ADR-008** | Pivot MVP Oleada 1: Bakery → Granja (cross-vertical root) | ✅ accepted | roadmap, scope, mvp, pivot |
| **ADR-009** | Bridges Layer: abstracción compat multi-framework + custom scripts | ✅ accepted | architecture, compat, foundational, bridges |
| **ADR-010** | Hybrid `admirals_audit_log` + `admirals_event_log` (resuelve inconsistencia SSoT §03 ↔ §04) | ✅ accepted | architecture, db, audit, ssot_consistency, foundational |
| **ADR-011** | Strategic Identity Pivot: Admirals → SONAR (radical rebrand + aesthetic overhaul, naval → nuclear submarine) | ✅ accepted (founder override + risks documented) | identity, branding, pivot, foundational, aesthetic, ssot_invalidation, risk_accepted |
| **ADR-012** | SONAR identity refinement: abstract metaphor + hybrid theme + neutral voice (amends ADR-011) | ✅ accepted | identity, branding, aesthetic, refinement, amendment, ssot_invalidation |
| **ADR-013** | Namespace migration execution Phase 8+9 — rename `admirals_*` → `sonar_*` en código + DB ANTES Sprint 2 (implements ADR-011 §4) | ✅ accepted | identity, namespace, migration, code, db, execution_plan, foundational |
| **ADR-014** | Hotfix path si smoke regression Phase 10 falla (placeholder reservado, no-escrito) | 🔴 proposed (pending trigger) | hotfix, contingency, placeholder |
| **ADR-015** | Sprint 2 scope UI-heavy pivot — defer T2 adapters + DDL + C003 a S3 (amends ADR-011 §4 Phase 12) | ✅ accepted | scope, sprint, mvp, ui, sonar, amendment |

---

## Resumen ejecutivo (cierre)

El **Decision Log** es la memoria institucional de SONAR (ex-Admirals):

- **Formato ADR estándar** con contexto + decisión + alternativas + consecuencias + impact + re-evaluation trigger.
- **Lifecycle:** proposed → accepted → deprecated / superseded.
- **Inmutables** tras accepted — cambios = nuevo ADR con superseded link.
- **14 ADRs accepted + 1 reservado placeholder** capturan decisiones clave: platform FiveM, economía tax 8%, no XP, **MVP Granja (pivot de Bakery per ADR-008)**, lean docs FiveM-native, firma system, subagents archived, **Bridges Layer foundational (ADR-009)**, **hybrid audit_log vs event_log (ADR-010)**, **🚨 strategic identity pivot Admirals → SONAR (ADR-011, founder override + risks documented)**, **🔄 SONAR identity refinement abstract+hybrid+neutral (ADR-012, amends ADR-011)**, **🔧 namespace migration execution Phase 8+9 (ADR-013, implements ADR-011 §4)**, **🎨 Sprint 2 scope UI-heavy pivot (ADR-015, amends ADR-011 §4 Phase 12)**, ADR-014 reservado placeholder hotfix smoke regression.
- **Protocol claro** para añadir nuevos + anti-patterns.
- **Tag index** facilita búsqueda por tema.

> **Cuando un dev/AI pregunte "¿por qué X?" en 6 meses, la respuesta está aquí.** Sin amnesia institucional.

---

*"Decisiones sin registro son decisiones perdidas. El log es memoria permanente."*

---

## 8. Continuación del documento

> **🔗 Continúa en:** `@docs/planning/02_decision_log_part2.md` v1.0+
>
> **Razón split:** este documento alcanzó ~1404 líneas tras ADR-015 + meta secciones. Para mantener navegabilidad, diff-friendly edits y reducir tiempo de búsqueda en sesiones AI, **toda decisión nueva (ADR-016 en adelante) vive en `02_decision_log_part2.md`**.
>
> **Reglas split:**
> - Numeración ADR continua sin reset (ADR-016 sigue inmediatamente a ADR-015).
> - Filosofía ADR (formato §1, workflow §3, anti-patterns §4) heredada del padre — NO duplicar en part2.
> - `02_decision_log.md` (este file) queda **append-only inviolable** — NO editar entries antiguas, NO añadir ADRs nuevos aquí.
> - Cuando `part2` supere ~1000 líneas, splittear `part3` análogamente.
>
> **Bump:** v1.5 → v1.5.1 (este pointer + changelog row §6.3).

### 8.1 Changelog v1.5.1

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.5.1 | 2026-05-04 | Founder + Cascade (S1.10 EXTENDED post-commit) | **Split documento.** Añadido §8 Continuación + pointer cruzado a `@docs/planning/02_decision_log_part2.md` v1.0. ADR-016 (SONAR Identity v3 firmable + doctrine palette/dark/stack/perf locked) registrado en `part2`. NO modificación entries v1.5 — append-only respetado. |

---

**FIN DEL DOCUMENTO `planning/02_decision_log.md` v1.5.1** (split → continúa en `02_decision_log_part2.md`)
