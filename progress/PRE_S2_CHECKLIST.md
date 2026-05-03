# 🚦 Pre-S2 Checklist — Obligatorios antes de empezar Sprint 2

> **Autor:** Founder + Cascade (S1.6 close, 2026-05-03).
> **Propósito:** lista exhaustiva de lo que **TIENE que estar hecho** antes de abrir `/start-session` S2.0.
> **Estado total (post-S1.9 EXTENDED):** � **B1 8/8 docs refreshed 100% (NOTICE r1 pattern)** + 🔴 **Phase 8+9 execution pending next session founder-available** + � **D1 + D3 resolved** (ADR-013 + ADR-015 firmed) + 🔴 B2 + B4 + B5 pending + � D2 (icons) + �🟢 5 soft-opcionales.
> **ETA mínimo pre-S2 ejecutando todo:** ~3-4 sessions AI (~12-18h founder time).
> **Documento living:** se actualiza cuando cualquier checkbox cambia de estado. Append-only al changelog footer.

---

## 🔴 HARD BLOCKERS (S2 NO puede empezar sin esto)

### B1. Phase 6 — Mass-purge operational docs post-pivot SONAR 🏆 **CERRADO S1.9 EXTENDED**

Docs operacionales siguen en lenguaje Admirals/literal-militar pre-pivot → **8/8 docs refreshed con NOTICE r1 pattern post-S1.9 EXTENDED**. Cada doc tiene header rebrand + NOTICE r1 top-level + changelog entry v1.1 + FIN bump. Legacy `admirals_*` inline preserved hasta Phase 8+9 execution per ADR-011 §5.5.8 excepciones. **S2 planning session puede leer estos docs como SSoT coherente post-pivot.**

| # | Doc | Estado actual | Trabajo pendiente |
|---|---|---|---|
| 1 | ~~`docs/design/02_admirals_tablet.md`~~ → `docs/design/02_sonar_tablet.md` v1.2 | 🟢 **PASS 1 + PASS 2 DONE S1.8** (100%) | ✅ Rename + NOTICE r1.1 + bulk identity purge + key sections Pass 1. ✅ Pass 2: §5.2 + §6.4/§6.5 + §10.5 + §11.4/§11.6 + §15.2 notif table canonical SFX mapping + §21.4 + §22.4 + §26 sounds tables canonical + §27.2 anti-patrones NEW post-pivot (9 items). **Ready-to-read para S2.0 planning** — Tablet shell + Bank app + Map app leen spec identidad SONAR canonical coherente. |
| 2 | `docs/technical/02_events_catalog.md` v1.1 | � **DONE S1.9 EXTENDED** (NOTICE r1) | ✅ Title dual prefix `sonar:*` / `admirals:*`. NOTICE r1 top-level (~70 líneas): naming canonical events mapping 1:1, 88 eventos shipped S1 affected, C003 DEFERRED S3 per ADR-015, voz neutral ADR-012 §D3, Phase 8 schedule, reading guide §1-§17. Schema fields INVARIANTES. Post-Phase-8 v1.2 rewrite inline 88 eventos 1:1. |
| 3 | `docs/technical/03_db_schema.md` v1.1 | � **DONE S1.9 EXTENDED** (NOTICE r1) | ✅ Title dual prefix `sonar_*` / `admirals_*`. NOTICE r1 top-level (~110 líneas): naming canonical 28 tablas mapping completo + migration 009 SQL target (UP + DOWN rollback) + índices + FKs 1:1 + ADR-010 hybrid audit/event log semantics preserved + reference data seeds preserved (system treasury IBAN unchanged) + reading guide §1-§20. DDL INVARIANTES. Post-migration-009 v1.2 rewrite inline 28 tablas 1:1. |
| 4 | `docs/technical/04_api_contracts.md` v1.1 | � **DONE S1.9 EXTENDED** (NOTICE r1) | ✅ Title rebrand SONAR. NOTICE r1 top-level (~80 líneas): naming canonical callbacks/exports/NUI bridges (mapping 1:1 5 callbacks shipped S1 + 35+ planned) + **C003 `getTransactions` DEFERRED S3 per ADR-015 (D1=B UI-heavy pivot)** + request/response schemas INVARIANTES pre/post Phase-8 + voz neutral error messages + Phase 8 schedule. |
| 5 | `docs/technical/05_state_machines.md` v1.1 | � **DONE S1.9 EXTENDED** (NOTICE r1) | ✅ Title rebrand SONAR. NOTICE r1 top-level (~70 líneas): naming canonical FSM audit table (`sonar_fsm_transitions`) + 16 FSMs entity tables mapping + event triggers canonical + state strings + transitions + guards + cascade rules INVARIANTES + escrow FSM S1 shipped reference (5 estados probado 14/14 smoke S1.3) + tx atomicity unchanged + voz neutral + Phase 8+9 schedule. |
| 6 | `docs/technical/06_fivem_standards.md` v1.1 | � **DONE S1.9 EXTENDED** (NOTICE r1) | ✅ Title rebrand SONAR. NOTICE r1 top-level (~45 líneas): naming canonical state bag namespace post-Phase-8 (`sonar_*`) + event prefixes + DB tables post-migration-009 + voz + copy-in-production alineada ADR-012 §D3 + performance budgets pivot-agnostic invariantes + §6.1 sync checklist dual pre/post-Phase-8 + reading guide. |
| 7 | `docs/technical/07_bridges_compatibility.md` v1.1 | � **DONE S1.9 EXTENDED** (NOTICE r1) | ✅ Title rebrand SONAR. NOTICE r1 top-level (~50 líneas): naming canonical producto + code namespace target state post-Phase-8 (`sonar_bridges`/`sonar_core`/`sonar_bank` + exports + event prefixes) + Phase 8+9 execution schedule + §12 SDK customer-facing rename guidance + reading guide §1-§18. Anti-pattern grep Regla 1 dual pre/post Phase-8. |
| 8 | `docs/planning/01_roadmap.md` v1.4 → v1.5 | � **DONE S1.9** (100%) | ✅ Title rebrand SONAR. ✅ NOTICE r1 top-level (~80 líneas) naming canonical + Sprint 2 DIFERIDO + pivot phases 1-12 status + reading guide. ✅ §0 + §2.1 tabla Oleada 1 row bumped (🟡 EN PROGRESO Sprint 0+1 ✅ + Sprint 2 DIFERIDO). ✅ §4.1 Visión MVP SONAR + §4.2 Sprint 2 full rewrite (3 scope options D1 + 8 done criteria propuestos + blockers B1-B5 + D1-D3). ✅ §5.1 + §6.1 + §14.2 + §14.3 changelog entry + §15 TL;DR 10→12 pts pivot-aware + §FIN bump. **NO touched:** §3 Oleada 0 histórico inmutable, Sprint 0+1 entries histórico, Sprints 3-8 gameplay pivot-agnostic, §7-§13 risk/KPIs/structure preserved. Code namespace legacy `admirals_*` preservado per ADR-011 §5.5.8 (pending D3). |

**Ownership:** Sonnet 4.6 surgical por doc (1 doc/session, 3-4h cada) o Opus 4.7 si founder quiere batch completo en 1 session grande.

**Done criterion:** grep `Admirals|Almirantazgo|capitán|silent service` en `docs/` retorna solo: `_archive/`, ADRs históricos, SESSION_LOG, NOTICE blocks, DEPRECATED tags, code namespace legacy (`admirals_bank`/`admirals_core`/`admirals_bridges`/`admirals_*` tables/`admirals:*` events) pending Phase 8+9.

**Progreso post-S1.9 EXTENDED:** 🏆 **8/8 done** (100%): 1=`02_sonar_tablet.md` v1.2 (S1.8 Pass 1+2), 2=`02_events_catalog.md` v1.1 (S1.9 EXT), 3=`03_db_schema.md` v1.1 (S1.9 EXT), 4=`04_api_contracts.md` v1.1 (S1.9 EXT), 5=`05_state_machines.md` v1.1 (S1.9 EXT), 6=`06_fivem_standards.md` v1.1 (S1.9 EXT), 7=`07_bridges_compatibility.md` v1.1 (S1.9 EXT), 8=`01_roadmap.md` v1.5 (S1.9). Todos con NOTICE r1 top-level estableciendo naming canonical post-ADR-011/012/013/015 + mapping 1:1 events/tables/callbacks/exports + reading guide + Phase 8+9 schedule. **Post-Phase-8+9 execution:** docs 2-7 v1.1 → v1.2 rewrite inline 88 eventos + 28 tablas + 40+ callbacks + exports + 16 FSMs 1:1 con nuevos nombres canonical. **B1 Phase 6 mass-purge operational docs COMPLETE.**

---

### B2. SPRINT_PLAN_S2.md — creación

- **Estado:** 🔴 **No existe** (`progress/SPRINT_PLAN_S2.md` ausente).
- **Trabajo:** planning session dedicada (founder + architect agent) → redactar plan siguiendo template del playbook.
- **Contenido mínimo:**
  - Goals S2 post-pivot (probablemente: Tablet shell NUI + Bank app básico + Map app placeholder + T2 adapters ESX/QBCore + `admirals_companies` DDL + C003 `getTransactions`).
  - Scope balance: UI-heavy vs tech-balanced (ver D1 abajo).
  - Done criteria explícitos ×10-12.
  - Smoke check steps ×15-20.
  - Session breakdown (probablemente S2.0 planning + S2.1-S2.4 ejecución + S2.5 close).
  - Model allocation per session (Opus design, Sonnet/GPT-5.3 code, Gemini refactor).
  - Risk register top 5.
- **Ownership:** Opus 4.7 o Gemini 3.1 Pro (density analítica).
- **Duración estimada:** 1 session completa ~4-5h.
- **Dependencia:** debe venir **después** de B1 (docs purged) para que planning lea SSoTs coherentes.

---

### B3. Memoria persistente SONAR Identity — Update r2 confirmation

- **Estado:** 🟢 **r2 ya actualizada** (retrieved en sesión, versión ADR-012). Verifica al boot S2.0.
- **Acción:** AI agent S2.0 debe confirmar al inicio que retrieval muestra r2 (no r1). Si muestra r1, founder pide update vía `create_memory update`.
- **Riesgo:** si memoria r1 persiste, AI puede escribir código/UI con metáfora literal-militar ya deprecated.

---

### B4. Smoke check regression `admirals_bank` post-pivot

- **Estado:** 🟡 **Pendiente ejecutar** (13/13 smoke S1.3 pasaron pre-pivot; si Phase 8 NO rename code/DB, smoke debería seguir 13/13 post-pivot).
- **Trabajo:** boot server local + ejecutar smoke `admirals_bank` cumulative 30 pasos pre-S2.
- **Done criterion:** 30/30 ✅ sin regression.
- **Si falla:** hot-fix antes S2 (S1.7 hotfix session).
- **Ownership:** founder local + Sonnet 4.6 debug si rompe.
- **Duración:** ~30-60min.

---

### B5. Commit + push + tag `sonar-identity-canonical`

- **Estado:** 🟡 Commits S1.6 pushed (`611a4f9` head), tag pendiente.
- **Trabajo:** `git tag sonar-identity-canonical 611a4f9 && git push --tags` → marca identity lock post-ADR-012.
- **Razón:** permite rollback clean si S2 rompe algo + bookmark pre-code-phase.
- **Ownership:** founder aprueba, Cascade ejecuta.
- **Duración:** 2 min.

---

## 🟡 DECISIONES FOUNDER REQUIRED (bloquean B1-B2)

### D1. Scope S2 — UI-heavy vs tech-balanced

Memoria founder (pre-pivot) dice: *"UI es ~50-60% del valor percibido pero S2 también incluye T2 adapters ESX/QBCore, admirals_companies DDL, C003 getTransactions. Planning S2 balanceará scope, NO todo-UI."*

**Opciones:**
- **A) Tech-balanced (memoria original):** Tablet shell minimal + Bank app básico + T2 adapters + `admirals_companies` DDL + C003. ~3 semanas.
- **B) UI-heavy post-pivot (maximiza valor percibido SONAR identity):** Tablet shell refinado + Bank app polished + Map app + motion signature + sound signature. Deferir T2/C003 a S3. ~4 semanas.
- **C) Híbrido:** Tablet shell + Bank app + T2 adapters (solo lectura). DDL `admirals_companies` + C003 defer. ~3 semanas.

**🏆 DECISIÓN FIRMED S1.9 EXTENDED: Opción B UI-heavy post-pivot (ADR-015 accepted).** Sprint 2 scope: SONAR Tablet shell refinado + SONAR Bank app polished + Map app + motion signature + sound signature 5 SFX canonical. Deferir T2 adapters + `sonar_companies` DDL + C003 `getTransactions` a S3. ~4 semanas. Ver `docs/planning/02_decision_log.md` ADR-015. **B2 SPRINT_PLAN_S2 redactable post-Phase-8+9+10 complete.**

---

### D2. Diseño creativo — designer externo SÍ/NO ANTES de S2

5 briefs v2 en `docs/art/briefs/` post-ADR-012. **Status update post-S1.7 (2026-05-03):**

| Brief | Budget estimado | Delivery time | Status / Bloquea S2? |
|---|---|---|---|
| `01_brief_logo.md` v2 | €1.5-3.5k | 3-6 semanas | � **RESUELTO IN-HOUSE S1.7** — logo v2 concept A "S-curl open" working canonical en `art/branding/logo_v2/` (8 SVGs + 27 PNG exports + favicon). Adopted founder 2026-05-03. **NO firmado ADR** — período uso real ~2-4 semanas, después decisión: hold (formalizar ADR-013 + sync docs) o re-iterar (designer pro per brief §7 R0-R4, budget €1.5-3.5k). |
| `02_brief_icons.md` v2 | €1.2-2.5k | 2-4 semanas | 🟡 Suave — S2 usa Lucide puro para Tablet UI. Custom 8 icons pueden llegar S3 Storybook. **Decisión pendiente:** in-house (founder Figma) vs externo. |
| `03_brief_sound.md` v1 | €500-1.5k | 1-2 semanas | 🟢 Defer S3 sin problema. |
| `04_brief_motion.md` v1 | €500-2k (si externo; si in-house `framer-motion` gratis) | 1-2 semanas | 🟢 Defer S3 sin problema. |
| `05_brief_marketing.md` v1 | €2-5k trailer | Pre-launch only | 🟢 Defer Oleada 1 close. |

**Opciones residuales (post-logo-resuelto):**
- **A) Contratar icons AHORA (paralelo a B1-B2 ~2-4 semanas):** Tablet S2 nace con identidad icon completa. Budget ~€1.2-2.5k.
- **B) S2 con Lucide puro → custom icons post-S2 (default):** velocity dev preservada, alineado con resolución logo in-house. Refactor S3 cuando custom icons delivered.
- **C) Híbrido in-house:** founder intenta 3-5 icons custom críticos in-house (Figma) + Lucide resto. €0 coste.

**Decisión pendiente founder (icons only).** Logo ya resuelto S1.7.

**Hard constraint S1.7 founder decision:** durante período uso real ~2-4 semanas del logo v2 working canonical, **NO se firma ADR-013 ni se sync `01_art_direction.md` §3.3 / `01_brief_logo.md` v2 § status**. Si AI agent futura detecta conflict entre `art/branding/logo_v2/` realidad y `docs/*` firmados, debe leer `art/branding/logo_v2/README.md` §"NO es pivot" + SESSION_LOG S1.7 entry primero — founder override está documentado, NO arreglar unilateralmente.

---

### D3. Namespace migration — rename `admirals_*` → `sonar_*` en código + DB

ADR-011 §4 execution plan listó Phase 8 (code refactor) + Phase 9 (DB migration) como parte del plan, pero **founder puede decidir deferirlas** hasta cierre Oleada 1 (minimizar riesgo + prolongar compat).

**Opciones:**
- **A) Phase 8+9 AHORA (antes S2):** rename `admirals_bridges` → `sonar_bridges`, `admirals_bank` → `sonar_bank`, `admirals_core` → `sonar_core`, tablas SQL renamed vía migration 009, events re-prefixed. Costo: ~1 session rewrite + 1 session DB migration + 1 session smoke regression. Beneficio: código y DB alineados con brand desde S2+.
- **B) Phase 8+9 DEFERIDAS (después Sprint 9 fin Oleada 1):** código sigue `admirals_*` prefixed, docs rewritten usan legacy namespace con NOTICE "legacy naming preserved por compat hasta Phase 8". Costo: docs B1 contienen legacy mentions — molesto pero claro. Beneficio: velocity S2-S9 preservada, migration big-bang al final cuando código estable.
- **C) Phase 8 parcial SÍ, Phase 9 defer:** rename resources folder + exports/events pero mantener DB tables legacy hasta Oleada 1 close. Hybrid compromiso.

**🏆 DECISIÓN FIRMED S1.9 EXTENDED: Opción A Phase 8+9 AHORA antes S2 (ADR-013 accepted).** Scope:
- Phase 8 code refactor: `resources/admirals_bridges/` → `resources/sonar_bridges/`, `admirals_bank` → `sonar_bank`, `admirals_core` → `sonar_core` + fxmanifest + config.lua + exports + event prefixes + smoke manuals.
- Phase 9 DB migration: `009_rename_admirals_to_sonar.sql` rename 6 tablas SQL + FKs + index names coherentemente.
- Execution session próxima founder-available (branch `phase-8-9-sonar-rename` o main con gate smoke).
- Cost ~3 sessions: code (~2-3h) + DB (~45min) + smoke regression founder local (~30-60min).
- Post-execution: docs 2-5 v1.1 → v1.2 rewrite inline naming canonical.

Ver `docs/planning/02_decision_log.md` ADR-013 para plan detallado. **B1 docs técnicos 2-5 ya pre-drafted con canonical mapping NOTICE r1 S1.9 EXTENDED; post-execution bump a v1.2 rewrites inline.**

---

## 🟢 SOFT-OPCIONALES (no bloquean S2 técnicamente pero suman)

### S1. SESSION_LOG S1.6 close entry appended

- **Estado:** 🟢 **Pendiente en esta close-session** (se añade ahora).

### S2. ADR nuevos si decisiones D1/D2/D3 no-triviales

- Si D3 = opción A o C → nuevo ADR-013 "Namespace migration execution" (Phase 8+9 schedule).
- Si D2 = opción A → nuevo ADR-014 "Creative outsourcing agreement" (contracts + budget + licensing).
- Si D1 = opción B (UI-heavy) → nuevo ADR-015 "S2 scope pivot UI-heavy" (razón + trade-offs).

### S3. Figma starter file creado

- Setup workspace Figma con paleta Tier A/B/C + Crew + Signal tokens (ya en `01_art_direction.md` §3.4) como swatches + Geist Sans/Inter Tight/Geist Mono type styles + 12 motion tokens (`01_art_direction.md` §16.2). Permite S2 diseñador/Sonnet componer mockups Tablet rápido.
- Ownership: founder o designer externo si D2=A.
- Duración: 2-4h setup.

### S4. PROGRESS.md dashboard created

- Dashboard markdown living `progress/PROGRESS.md` con tabla oleadas + sprints + % progreso + links SESSION_LOGs + ADRs. Quality-of-life, no bloquea.

### S5. FiveM server local boot smoke

- Boot `fxserver.exe` local + verify `admirals_bridges` + `admirals_bank` + `admirals_core` cargan sin errors + smoke bank 30 pasos (ver B4). **Merge-able con B4.**

---

## 📋 Orden de ejecución recomendado (crítico → opcional)

1. **Founder decide D1 + D2 + D3** (~30 min reflexión, puede mientras café).
2. **Tag `sonar-identity-canonical`** (B5, 2 min).
3. **Smoke regression `admirals_bank`** (B4, 30-60 min — verifica base sólida).
4. **Phase 6 docs purge** (B1, ~4 sessions distribuidas — priorizar `02_sonar_tablet.md` + `01_roadmap.md` v1.5 primero; resto después).
5. **SPRINT_PLAN_S2.md planning session** (B2, 1 session 4-5h — después docs coherentes).
6. **Verificación memoria r2** (B3, 2 min al boot S2.0).
7. **Soft-opcionales paralelos:** Figma setup, Progress dashboard, ADRs nuevos si aplica.

---

## ⏱️ ETA total pre-S2

**Ruta mínima (B1 surgical rápida + B2 + B4 + B5):** ~12-18h founder time distribuidos en 3-5 sessions AI. Aproximadamente 1 semana calendario si 1 session/día + descansos.

**Ruta completa (incluyendo D2=A creative outsourcing):** +3-6 semanas calendar overlap (delivery logo + icons externo), pero sin bloquear dev tracks S2 si S2 arranca con placeholders.

---

## 🔐 Red flags pre-S2

- 🚩 Si founder abre `/start-session` S2.0 sin B1 done → AI agent leerá SSoTs con mix Admirals/SONAR → **confusion guaranteed**.
- 🚩 Si D3 no decidido antes B1 → docs purge tendrá que ambiguate "legacy vs canonical naming" → doble trabajo si se decide después.
- 🚩 Si B4 smoke falla → indica algo roto desde sprint-1-complete tag → hot-fix S1.7 obligatorio antes S2.
- 🚩 Si memoria r2 no persistida correctamente → founder debe force-update vía comando explícito AI.

---

## 📝 Changelog pre-S2 checklist

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026-05-03 | Founder + Cascade (S1.6 close) | Documento creado. 5 hard blockers + 3 decisiones founder + 5 soft-opcionales. Ruta mínima estimada 12-18h founder time / ~1 semana calendario. |
| 1.1 | 2026-05-03 | Founder + Cascade (S1.7 close partial → S1.8 hygiene) | **D2 status update fact-only post logo v2 working canonical S1.7.** Logo `01_brief_logo.md` v2 🟢 RESUELTO IN-HOUSE (concept A "S-curl open" en `art/branding/logo_v2/` 8 SVGs + 27 PNG + favicon). Decisión founder S1.7: NO firma ADR-013 ni sync `01_art_direction.md` §3.3 / brief status durante período uso real ~2-4 semanas. Hard constraint añadido para futuras AI agents (NO arreglar unilateralmente conflict logo realidad vs docs firmados). Icons/sound/motion/marketing pendientes. Resto blockers B1-B5 + D1 + D3 + soft-opcionales sin cambio. |
| 1.2 | 2026-05-03 | Founder + Cascade (S1.8 B1 attack partial) | **B1 status update: doc 1/8 Pass 1 done.** `02_admirals_tablet.md` renamed → `02_sonar_tablet.md` v1.1 (git mv). NOTICE r1.1 top-level (~70 líneas) + bulk identity purge 126 instances + surgical inline §2.4+§3+§3.2+§4.1+§4.2+§29. Pass 2 pendiente ~2h próxima sesión (§6-§19 apps detail-pass + §26 sounds + §27 anti-patterns). Resto 7 docs B1 sin cambio. |
| 1.3 | 2026-05-03 | Founder + Cascade (S1.8 Pass 2 complete) | **B1 status update: doc 1/8 Pass 2 complete = 100%.** `02_sonar_tablet.md` v1.1 → v1.2 (Pass 1 + Pass 2 surgical completos). Pass 2 adicional: §5.2 lenguaje visual Geist Sans + §6.4/§6.5 Empresa depth_press + §10.5 stickers abstract + §11.4/§11.6 Banca canonical + §15.2 tipología notif table 12-row canonical SFX mapping + §21.4 docking canonical + §22.4 Costa Naval flag + §26 sounds 4 tablas canonical full rewrite + §27 split §27.1 v1.0 preserved + §27.2 NEW 9 anti-patrones identidad SONAR post-pivot. **Doc ready-to-read para S2.0 planning.** Resto 7 docs B1 pendientes. |
| 1.4 | 2026-05-03 | Founder + Cascade (S1.9) | **B1 status update: doc 8/8 done = 2/8 total (25%).** `01_roadmap.md` v1.4 → v1.5 surgical post-pivot SONAR. NOTICE r1 top-level (~80 líneas) + Sprint 2 full rewrite DIFERIDO + scope options D1 + 8 done criteria propuestos + blockers B1-B5/D1-D3 + pivot phases 1-12 status + §14.3 changelog + §15 TL;DR pivot-aware. B1 docs dependency breakdown: **independientes D3** (docs 6+7 light ejecutables Sonnet ~2h cada) + **dependientes D3** (docs 2-5 técnicos, naming `admirals_*` vs `sonar_*` resolución namespace). Ruta recomendada post-S1.9: (a) founder resuelve D1+D3 conversación ~30min desbloquea docs 2-5 + B2 SPRINT_PLAN_S2; o (b) Sonnet ataca docs 6+7 light mientras founder reflexiona. Resto blockers B2-B5 + D2 sin cambio post-S1.9. |
| 1.5 | 2026-05-04 | Founder + Cascade (S1.9 EXTENDED) | 🏆 **B1 PHASE 6 MASS-PURGE CERRADO 8/8 (100%).** Session S1.9 EXTENDED ejecutó heavy docs-only work post decisiones founder D1+D3 resueltas. **Decisiones firmed:** D3=A Phase 8+9 AHORA antes S2 (ADR-013 firmed), D1=B Sprint 2 UI-heavy (ADR-015 firmed). `02_decision_log.md` v1.4 → v1.5 (ADR-013 + ADR-014 placeholder + ADR-015). **Docs 2-7 NOTICE r1 pattern applied:** `02_events_catalog.md` v1.1 + `03_db_schema.md` v1.1 + `04_api_contracts.md` v1.1 (C003 DEFERRED S3) + `05_state_machines.md` v1.1 + `06_fivem_standards.md` v1.1 + `07_bridges_compatibility.md` v1.1. Cada doc con header rebrand + NOTICE r1 top-level (~45-110 líneas per doc) estableciendo naming canonical mapping 1:1 (88 eventos + 28 tablas + 40+ callbacks + 16 FSMs) + schedule Phase 8+9 + reading guide + voz neutral ADR-012 §D3 + ADRs refs + changelog entry v1.1 + FIN bump. Legacy `admirals_*` inline preserved hasta Phase 8+9 execution per ADR-011 §5.5.8 excepciones. **Blockers pendientes post-S1.9 EXTENDED:** B2 SPRINT_PLAN_S2 (bloqueado por Phase 8+9+10 execution) + B4 smoke regression (requires founder server-local) + B5 tag + Phase 8 code refactor + Phase 9 migration 009 + D2 icons opcional. **Pre-Sprint 2 gate proper:** Phase 10 smoke regression green. **S2 arranque estimado ~2-3 sesiones calendario post-S1.9 EXTENDED** depending founder server availability. |

---

*"Antes de zarpar, verifica el casco."* — meta-regla S1 → S2.

**FIN DEL DOCUMENTO `progress/PRE_S2_CHECKLIST.md` v1.5.**
