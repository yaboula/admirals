# 🏁 Sprint 1 — Retro

> **Sprint:** S1 — Banco core: IBAN + Accounts + Transfer + Escrow FSM + Callbacks C001/C002/C004/C005.
> **Duración real:** 1 día (2026-05-02). Estimado: 2 semanas. **Velocity factor: ~15×.**
> **Sessions:** 3 (S1.1, S1.2, S1.3 con phase1+phase2).
> **Founder + Agents:** yaboula + Cascade (Opus 4.7 MAX para S1.1/S1.2/S1.3 phase1 ARCHITECT + Sonnet 4.5 para S1.3 phase2 finalize + scribe).
> **Fecha cierre:** 2026-05-02.

---

## 0. Resumen ejecutivo

**🏆 Sprint 1 cerrado con éxito — todos done criteria cumplidos + smokes 30/30 pasados cumulative.**

- **3 sessions** (S1.1 skeleton + IBAN + C001, S1.2 transfer + idempotency DB promote, S1.3 escrow FSM + C004/C005) ejecutadas en 1 día.
- **1 checkpoint phase2** en S1.3 para resolver 3 incidencias in-flight (FK violation schema + auth mismatch + `owner_account_id` Player B corrupto).
- **Total líneas código añadidas:** ~3.800 Lua (`admirals_bank` completo) + ~600 SQL (migrations 003-008) + ~450 docs (smoke tests + SESSION_LOG entries + esta retro).
- **`admirals_bank` v0.4.0** operativo end-to-end: IBAN auto-asignado on first connect, transfer player→player atomic, escrow lock/release/refund con FSM + auth matrix + fee clamps, idempotency DB-backed, rate limiter `bank.write` 10/60s, events schema v1.

---

## 1. Done criteria Sprint (per SPRINT_PLAN_S1.md §Done criteria SPRINT)

- [x] 3 sessions S1.1-S1.3 completadas con done criteria individuales ✅.
- [x] Smoke test S1 → **30/30 pass cumulative** (S1.1 6/6 + S1.2 10/10 + S1.3 14/14).
- [x] `git tag sprint-1-complete` aplicado (`v0.1.0` previamente usado en S1.1 commit `1c9426b`, evitando collision).
- [x] `progress/SPRINT_RETRO_S1.md` escrito (este doc).
- [x] `docs/planning/01_roadmap.md` §4.2 S1 marked ✅ con fecha + deliverables detallados (v1.3→v1.4).
- [x] `docs/agents/00_BOOTSTRAP.md` v1.3→v1.4 reflejando estado post-S1.

---

## 2. Qué fue bien

### 2.1 Pair programming Opus 4.7 MAX — calidad arquitectónica sostenida
- S1.1 (IBAN + accounts + C001), S1.2 (transfer + idempotency DB promote), S1.3 phase1 (escrow FSM + C004/C005) entregadas en 1 pasada cada una por Opus.
- 0 re-scope, 0 contradicciones cross-session. Trust hierarchy respetada.
- Pattern arquitectónicos sólidos: double-entry ledger, atomic TX (`Admirals.DB.Transaction`), FSM table-driven con `Fsm.AssertTransition`, auth matrix F3 per `04_api_contracts.md` §3.1.

### 2.2 Protocolo SESSION_LOG append-only + handoff bullets funcionó cross-session
- S1.1 handoff → S1.2 pudo arrancar con 10 min onboarding.
- S1.2 handoff → S1.3 idem. Cada entry tiene "Handoff próxima sesión" con pre-requisitos + files in scope + notas especiales.
- 0 trabajo duplicado cross-session. ADR-010 aplicado consistentemente (audit DB persistence).

### 2.3 Docs Oleada 0 + SSoTs siguieron pagando dividendos
- `03_db_schema.md` §4 (bank DDL) + `04_api_contracts.md` §3.1 (C001-C005) + `05_state_machines.md` §4.1 (escrow FSM) = spec directa cero ambigüedad.
- `economy/01_economic_model.md` §10.4.2 fee escrow 1% clamp 2/100€ aplicado sin hallucination.
- `07_bridges_compatibility.md` Bridges.Bank contract expandido sin reescribir interface (additive).

### 2.4 Smoke harness disposable pattern consolidado S1.1 → S1.2 → S1.3
- 3 iteraciones de smoke client commands disposable (S1.1 `smoke.lua` 4 commands + S1.2 `smoke.lua` 5 commands + S1.3 `smoke_s1_3.lua` 6 commands + server-side `smoke_s1_3_sub.lua` para event subscription step 13).
- Mismo workflow end-to-end: create harness → founder ejecuta N pasos manuales → sign-off → cleanup commit que borra harness + bloque `client_scripts` + bumpa version resource post-cleanup.
- 0 smoke harness leftover en rama `main` post-sprint. Reproducibilidad vía `git checkout <commit_pre_cleanup> -- path/harness` documentada en SESSION_LOG entries.

### 2.5 Migration immutability respetada (ADR-010 principle)
- 006 (escrow_schema), 007 (FK fix transitional), 008 (FK revert canonical a bank_accounts) — cadena aditiva sin modificar ni borrar ninguna.
- 007 fue redundante en retrospectiva pero NO se reescribió: 008 cancela su efecto vía `DROP FOREIGN KEY` + `ADD CONSTRAINT` con target correcto.
- Migration runner idempotente skip OK en re-runs. Historial auditable.

### 2.6 Velocity extrema sostenida
- Sprint 0 = 1 día / 4 sessions vs 3 sem / 4 sessions → factor 15×.
- Sprint 1 = 1 día / 3 sessions vs 2 sem / 3 sessions → factor ~10-15×.
- Patrón consistente: docs Oleada 0 + Opus 4.7 MAX + SESSION_LOG rigor = velocity 10×+ sobre planning conservador.

---

## 3. Qué fue mal / friction points

### 3.1 3 incidencias in-flight S1.3 que requirieron phase2 finalize (~6h overrun vs 4-5h estimado)

**Incidencia A — FK violation on escrow INSERT (step 2 smoke):**
- Causa: `admirals_escrows.buyer_account_id` + `seller_account_id` definidas con FK → `admirals_bank_accounts(id)` en 006, pero `escrow.lua` insertaba `buyer_acc.owner_account_id` (identity) → FK violation.
- Fix transitional: migration 007 cambió FK target a `admirals_accounts(id)`. Resolvió INSERT pero rompió auth release.

**Incidencia B — Auth mismatch on release (step 7 smoke):**
- Causa: `_authorize_release` comparaba `caller_identity == escrow.seller_account_id`, que post-007 era identity → OK, pero recipient lookup usaba `WHERE owner_account_id = ? AND type='personal'` requiriendo hop extra. Desalineamiento semántico.
- Fix definitivo: migration 008 revierte FK target a `admirals_bank_accounts(id)` (canonical 006 design) + refactor `escrow.lua` para INSERT `(buyer_acc.id, seller_acc.id)` + `_authorize_release` resuelve owner del bank_account via SQL lookup. Diseño homogéneo: 3 columnas `*_account_id` en escrows referencian bank accounts.

**Incidencia C — `owner_account_id` Player B NULL (step 7 smoke):**
- Causa: char Player B fue borrado manualmente en DB durante troubleshooting, dejó FK dangling.
- Fix: UPDATE manual `admirals_bank_accounts SET owner_account_id = ? WHERE iban = ?` para re-asignar bank account al nuevo identity.

**Lesson learned:** incidencia A+B pudieron evitarse si el pre-action de escrow.lua hubiera validado que `buyer_acc.id` (bank_account.id) se usaba como target del FK, no `owner_account_id` (identity). Workspace rule "no hallucinate APIs" se cumplió (grep SSoT respetado) pero hubo gap en verificación cross-tabla FK semantics. **Acción S2:** al tocar schema con FKs nuevas, grep cross-check de tipo target antes de implementar lógica inserción.

### 3.2 Smoke step 13 (event subscription) bloqueado por ruta incorrecta
- Founder intentó `exec subscribe_test.lua` en `server.cfg` — `exec` en FiveM ejecuta archivos cfx commands no Lua. No hay REPL Lua server-side en consola.
- Resolución: server_script disposable `smoke_s1_3_sub.lua` wired en fxmanifest, mismo paradigma que client harness. **Patrón canonical FiveM consolidado** para futuros smoke steps que requieran código server-side disposable.

### 3.3 `v0.1.0` tag collision (previsto)
- Tag `v0.1.0` ya usado en commit `1c9426b` (S1.1) al cierre de la session con smoke 6/6. Si hubiéramos reutilizado en sprint close, tag-move non-trivial + ambiguedad historial.
- Resolución: tag sprint close con nombre semántico `sprint-1-complete` (pattern propuesto para futuras closes: `sprint-N-complete` stable + `vX.Y.Z` para releases binary-stable separately).

### 3.4 `scripts/smoke_test_s1_2.md` untracked (carry-over S1.2)
- Founder opt-out commit en S1.2 close; archivo sigue untracked hoy.
- No bloqueante pero working tree nunca está 100% clean entre sprints. **Acción S2:** decisión binaria pre-close — commit o gitignore. No tercer estado.

---

## 4. Learnings clave S1

### 4.1 SSoT divergence protocol validation ⭐
**Workspace rule "hard constraint: no hallucinate numbers, cita SSoT con `@path:LINE`" funciona.** En múltiples puntos durante S1.3, AI flaggeó pre-action errores implícitos en prompts founder (ej. fee escrow "2€ min" en vs spec §10.4.2 confirmado, IBAN format 17 chars AD-XXXX-XXXX-XXXX vs variaciones). Protocolo F1-F6 (flag-first, ask-founder, await-green-light) previno escribir código sobre spec errónea.

**Confirma:** workspace rule + red flags policy en `admirals.md` es net-positive — overhead ~5 min por session pero evita re-work de horas. Mantener intacto S2+.

### 4.2 Migration immutability respetada end-to-end ⭐
**Cadena 006 → 007 → 008 sobre 003/004/005 sin modificar ninguna previa.** ADR-010 principle operativo incluso cuando 007 resultó redundante en retrospectiva. Runner idempotente + SHA-256 checksum + `admirals_schema_versions` tracking funcionó sin regresiones.

**Confirma:** migration path es aditivo-only, cancel-via-new-migration vs revert-via-edit. Pattern transferible Oleada 2+. S2 debe seguir este paradigma al tocar schema (probable: `admirals_companies` + ALTER TABLE `admirals_bank_accounts` ADD FK `owner_company_id`).

### 4.3 Smoke harness disposable pattern consolidado ⭐
**S1.1 → S1.2 → S1.3 mismo workflow 3×.** Harness = último server_script/client_script + bloque dedicado en fxmanifest + comentario `S1.X SMOKE TEST TEMPORAL — DELETE POST SIGN-OFF`. Cleanup = delete files + remove bloque fxmanifest + bump version resource + SESSION_LOG entry cleanup. Commit message convention `S{N}.{M} cleanup remove temporal smoke harness post sign-off`.

**Confirma:** pattern reproducible sin re-inventar workflow cada sprint. Aplica S2+. Para NUI smoke tests (S2 Tablet), mismo pattern adaptado a fake commands triggering NUI events.

### 4.4 Velocity factor ~15× docs-first
- Sprint 0 + Sprint 1 ambos ejecutados en 1 día vs estimación conservadora 3+2 semanas.
- Factor determinante: docs Oleada 0 (29 docs firmados) eliminaron ~90% design on-the-fly.
- **NO es sostenible Oleada 2 sin mismo nivel docs preview.** Planning S2+ debe incluir spike doc prep si nuevos sistemas no tienen SSoT equivalente (ej. Tablet NUI UI spec podría necesitar doc firmado pre-code).

---

## 5. Velocity + métricas

| Métrica | Planeado | Real |
|---|---|---|
| Sessions S1 | 3 | 3 + 1 phase2 finalize |
| Duración total | 2 sem | 1 día |
| Files creados (code) | ~15 | 14 (iban.lua, accounts.lua, movements.lua, events.lua, transfer.lua, escrow.lua, fsm_escrow.lua, callbacks.lua, init.lua, config.lua, fxmanifest.lua, migrations 003-008) |
| Files creados (docs) | ~3 | 4 (smoke_test_s1_1.md, smoke_test_s1_2.md opt-out, smoke_test_s1_3.md, SPRINT_RETRO_S1.md) |
| LoC Lua | — | ~3.800 |
| LoC SQL | — | ~600 |
| LoC Markdown nuevo | — | ~1.800 (smokes + SESSION_LOG entries + retro) |
| Commits | 3-4 | 5 (S1.1 impl, S1.1 cleanup, S1.2 impl, S1.2 cleanup, S1.3 phase1, S1.3 phase2 + cleanup consolidado, más commit retro en curso) |
| Migrations añadidas | 1-2 | 6 (003-008) |
| Smoke steps cumulative | ~20 | 30 (6+10+14) |

---

## 6. Issues encontrados durante smoke test S1

- ✅ **S1.1 smoke 6/6** — IBAN unique, starter account auto-create, C001 getBalance response shape canonical, identity event hook funcional, audit DB persistence OK, resmon idle < 0.3ms.
- ✅ **S1.2 smoke 10/10** — Transfer player→player atomic, idempotency DB replay returns cached response, SELF_TRANSFER + INSUFFICIENT_FUNDS + RATE_LIMITED + ACCOUNT_FROZEN guards, 2-row ledger debit+credit, event emit admirals:bank:transfer_completed schema v1, CHECK constraint S005 balance NON-NEG enforced, stress test 50 transfers no race, resmon idle < 0.3ms.
- ✅ **S1.3 smoke 14/14** — Happy path escrow create, idempotency replay, SELF_ESCROW + INSUFFICIENT_FUNDS + NOT_AUTHORIZED + NOT_IMPLEMENTED split + FSM double-release guards, fee clamps 4/4 (amount 100→fee 2 min, 500→fee 5, 10000→fee 100 max, 20000→fee 100 clamped), release to seller, refund to buyer, rate limit 10/60s, event subscription 3 eventos schema v1, resmon 0.00ms idle.

**Total:** 30/30 ✅ cumulative S1.1 + S1.2 + S1.3.

---

## 7. Sign-off

- **Founder sign-off:** ✅ smoke S1.1 6/6 + smoke S1.2 10/10 + smoke S1.3 14/14 confirmados en SESSION_LOG entries respectivas.
- **Agent sign-off:** ✅ Cascade (Opus 4.7 MAX para implementación arquitectura + Sonnet 4.5 para finalize FK fix + scribe). 3 done criteria sprint + all files whitelist + docs updated (roadmap v1.4 + BOOTSTRAP v1.4).

---

## 8. Next sprint — S2 high-level candidates

> **⚠️ No detailed planning aqui.** Esto es scope para sesión planning dedicada separada (founder + architect, cross-sprint + decisiones stack UI).

Candidatos high-level:

- **`admirals_tablet` NUI shell** — React + TAB keybind open/close + shell routing + 3 apps stub (Bank, Map, Comm/placeholder).
- **`admirals_tablet` Bank app MVP** — consumir C001 getBalance + C002 transfer + C003 listMovements (pending) via NUI bridges. Transfer form con validación IBAN + amount + confirm dialog.
- **T2 adapters Bridges** — QBCore bank/identity + ESX bank/identity adapters (`resources/admirals_bridges/adapters/{qbcore,esx}/*`) para compat cross-framework per `07_bridges_compatibility.md` §5.
- **`admirals_companies` foundation** — migration 009 DDL (`admirals_companies` + `admirals_company_members` + `admirals_company_bank_accounts` FK link). ALTER TABLE `admirals_bank_accounts` ADD FK `owner_company_id`.
- **C003 `admirals:bank:listMovements`** — callback paginado consultando `admirals_bank_movements` WHERE account_id = ? con cursor-based pagination. Feed a Bank app UI transactions list.

---

**FIN SPRINT_RETRO_S1**
