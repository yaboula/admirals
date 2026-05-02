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
| `foundational` | ADR-002, ADR-003, ADR-009, ADR-010 |

### 5.2 Por estado

| Estado | ADRs |
|---|---|
| accepted | ADR-001 a ADR-004, ADR-006 a ADR-010 |
| proposed | — |
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

- **Versión:** 1.2 (firmado — completo, 6 secciones, 10 ADRs).
- **Próxima revisión:** al añadir ADR-011 (próxima decisión importante Sprint 1+).
- **Documento padre:** `planning/01_roadmap.md`.
- **Documento hermano:** `agents/00_BOOTSTRAP.md`.

### 6.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-01 | Founder + Cascade | Primera redacción. Formato ADR + 7 ADRs iniciales (subagents archived, FiveM platform, tax 8%, no XP genérico, Oleada 1 Bakery-only, discard ops/minimize qa, doc signing system). **Firmable, living document.** |
| 1.1 | 2026-05-01 | Founder + Cascade | **+2 ADRs** cerrando Oleada 0: ADR-008 (pivot MVP Granja, supersedes ADR-005) y ADR-009 (Bridges Layer compat multi-framework, foundational). Tag index actualizado (`pivot`, `architecture`, `compat`, `bridges`). ADR-005 marcado superseded. |
| 1.2 | 2026-05-02 | Founder + Cascade | **+1 ADR** cerrando Sprint 0: ADR-010 (hybrid `admirals_audit_log` + `admirals_event_log` — resuelve inconsistencia SSoT §03 ↔ §04 firmada Oleada 0). Tag index actualizado (`db`, `audit`, `ssot_consistency`). Tracked acción S1 en SPRINT_RETRO §4.3 para añadir DDL canónico en `03_db_schema.md`. |

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

---

## Resumen ejecutivo (cierre)

El **Decision Log** es la memoria institucional de Admirals:

- **Formato ADR estándar** con contexto + decisión + alternativas + consecuencias + impact + re-evaluation trigger.
- **Lifecycle:** proposed → accepted → deprecated / superseded.
- **Inmutables** tras accepted — cambios = nuevo ADR con superseded link.
- **10 ADRs** capturan decisiones clave: platform FiveM, economía tax 8%, no XP, **MVP Granja (pivot de Bakery per ADR-008)**, lean docs FiveM-native, firma system, subagents archived, **Bridges Layer foundational (ADR-009)**, **hybrid audit_log vs event_log (ADR-010)**.
- **Protocol claro** para añadir nuevos + anti-patterns.
- **Tag index** facilita búsqueda por tema.

> **Cuando un dev/AI pregunte "¿por qué X?" en 6 meses, la respuesta está aquí.** Sin amnesia institucional.

---

*"Decisiones sin registro son decisiones perdidas. El log es memoria permanente."*

**FIN DEL DOCUMENTO `planning/02_decision_log.md` v1.2**
