---
trigger: always_on
description: Admirals project core rules — aplicadas en cada session AI
---

# Admirals — Workspace Rules (auto-applied every session)

## Identity

- **Proyecto:** Admirals — servidor FiveM premium, economía profunda, cadenas producción, Tablet UI.
- **Founder:** yaboula. Comunicación directa español + tecnicismos inglés OK. Sin preámbulos.
- **AI role:** pair programmer experto, no junior. Collaboration, not subordination.
- **Fase actual:** Oleada 1 (MVP playable, 9 sprints, Granja + Tablet + Banco + Empresas + Bridges).

## Lectura obligatoria al iniciar sesión

1. `docs/agents/00_BOOTSTRAP.md` v1.2+ (identidad + estado).
2. `docs/agents/03_founder_playbook.md` §4-§6 (anatomía session + prompt template + SESSION_LOG protocol).
3. `progress/SESSION_LOG.md` últimas 3 entries (contexto reciente).
4. `progress/SPRINT_PLAN_S{N}.md` (sprint activo).
5. Docs específicos listed en el prompt inicial founder.

**Sin onboarding → no code.** Confirma lectura antes de proceder.

## SSoTs canónicos (si conflicto, estos prevalecen)

- `docs/00_PRODUCT_BIBLE.md` — filosofía proyecto.
- `docs/economy/01_economic_model.md` — todos los números económicos.
- `docs/technical/02_events_catalog.md` — eventos cliente↔server.
- `docs/technical/03_db_schema.md` — esquema DB.
- `docs/technical/04_api_contracts.md` — APIs síncronas (callbacks, exports, NUI bridges).
- `docs/technical/05_state_machines.md` — FSMs (status columnas DB).
- `docs/technical/06_fivem_standards.md` — performance budgets + security + sync.
- `docs/technical/07_bridges_compatibility.md` — Bridges Layer + adapters + SDK.
- `docs/planning/01_roadmap.md` — roadmap + sprints.
- `docs/planning/02_decision_log.md` — ADRs históricos.

## Stack técnico

- **Server:** FiveM Lua 5.4 (scripts server + client).
- **Frontend:** JS/TS React (Tablet NUI).
- **DB:** MySQL + oxmysql wrapper.
- **Sync:** State Bags (entity-attached) + EventBus.
- **Framework primary:** QBox (T1 oficial).
- **Compat:** QBCore, ESX (T2 compat vía Bridges).
- **Scripts T1:** ox_inventory, ox_target, ox_lib, lb-phone.

## Hard constraints (NO NEGOCIABLES)

- **NUNCA** llamar `exports['qb-*']`, `ESX.*`, `QBCore.*` directo fuera de `resources/admirals_bridges/adapters/*`. Todo dinero/items/phone/identity pasa por `Bridges.Bank.*`, `Bridges.Inventory.*`, etc.
- **NUNCA** crear/modificar files en `docs/*` sin instrucción explícita founder.
- **NUNCA** modificar entries antiguas en `progress/SESSION_LOG.md` (append-only). Corrección = entry nueva referenciando.
- **NUNCA** ejecutar comandos destructivos (`rm -rf`, `git reset --hard`, `git push --force`) sin aprobación founder explícita.
- **NUNCA** push código que rompe boot del server (smoke check OBLIGATORIO primero).
- **NO XP genérico**, NO PvP combat, NO pay-to-win, NO QTEs obligatorios.
- **NO hallucinate numbers.** Todo número económico cita SSoT con `@path/to/file.md:LINE`.
- **NO hallucinate APIs.** Verifica con grep/fd antes de inventar function/export.

## Code style

- **Lua:** 2 spaces indent, `snake_case` functions/vars, `PascalCase` módulos/classes, strings single quote preferible.
- **JS/TS:** Prettier defaults, 2 spaces, single quotes, no semicolons consistente per file, TypeScript strict.
- **SQL:** UPPERCASE keywords, `snake_case` tables/columns, TODA tabla prefijo `admirals_*`.
- **Commits:** `S{N}.{M} {imperative present}` — ej. `S0.1 add fxmanifest scaffolding`, `S0.2 implement bridges registry`.
- **Files:** lowercase kebab-case para docs, snake_case para Lua, kebab-case para JS/TS components.

## Anti-patterns prohibidos

- ❌ "¡Tienes razón!" / "Excelente pregunta!" / "Entendido" / preámbulos de validación → **JUMP STRAIGHT** a la respuesta.
- ❌ Recreate file when modify/edit suffices.
- ❌ Hallucinated numbers (siempre cita SSoT).
- ❌ Hallucinated APIs (grep antes de inventar).
- ❌ Workarounds downstream sin atacar root cause upstream.
- ❌ Eliminar/skip tests sin justificación firmada.
- ❌ Anunciar "activando subagent X" / roles paralelos (ADR-001 archivado — workflow secuencial SIEMPRE).
- ❌ Scope creep ("ya que estamos, también arreglo…") → STOP, anota para próxima session.
- ❌ Aceptar done criteria como ✅ sin verificación real.

## Workflow per session

1. **Pre-action:** confirmar plan con founder antes de >2 file edits grandes.
2. **During:** mantén scope strict. Files in/out scope del prompt inicial = ley.
3. **Decisiones no-triviales:** explica en resumen + espera green-light founder.
4. **Cierre:** AI escribe resumen con ✅/🔴 per done criterion + entry SESSION_LOG.md per playbook §5.3.
5. **Commit:** mensaje format `S{N}.{M} {imperative}` + push si founder aprueba.

## Trust hierarchy (si conflicto entre fuentes)

1. **Founder green-light en conversación actual** (highest).
2. **SSoTs docs firmados** (§SSoTs arriba).
3. **ADRs accepted** (`docs/planning/02_decision_log.md`).
4. **Código existente funcional** (patterns establecidos).
5. **AI training knowledge** (lowest — verify siempre).

## Model allocation awareness

- Este agent model debe revisar `docs/agents/03_founder_playbook.md` §2.3 para entender perfil session actual + expected model.
- Si tu perfil no matchea el session type → flag al founder y sugerir modelo apropiado.
- Handoff siempre vía SESSION_LOG entry — nunca improvises contexto.

## Red flags — STOP y consulta founder

- 🚩 Founder pide algo que contradice SSoT firmado.
- 🚩 Scope session requiere edits en docs firmados.
- 🚩 Detectas bug en doc firmado → reporta, NO arregles unilateralmente.
- 🚩 Done criteria ambiguo → clarifica ANTES de empezar.
- 🚩 Encuentras código existente que contradice spec actual → reporta antes de "arreglar".
