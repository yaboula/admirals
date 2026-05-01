# 📋 Sprint 0 — Plan detallado

> **Sprint:** S0 — Setup + Bridges Layer + admirals_core.
> **Duración:** 3 semanas (2026-05-02 → 2026-05-22 aprox.).
> **Sessions:** 4.
> **Goal global:** Founder puede `git clone`, configurar `server.cfg`, iniciar server FiveM, conectar client, ver migrations aplicadas + bridges boot report + resmon <0.5ms idle.

---

## Done criteria SPRINT

- [ ] 4 sessions S0.1-S0.4 completadas con done criteria individuales ✅.
- [ ] Smoke test final (`scripts/smoke_test.md`, 10 pasos) → 10/10 ✅.
- [ ] `git tag v0.0.0` aplicado + pushed.
- [ ] `progress/SPRINT_RETRO_S0.md` escrito.
- [ ] `docs/planning/01_roadmap.md` §4.2 S0 marked ✅ con fecha.
- [ ] `docs/agents/00_BOOTSTRAP.md` actualizado si estado significativo cambió (probablemente v1.3).

---

## Sessions

### S0.1 — Repo code scaffolding + first push

> **Nota:** Operacionales (`.windsurf/rules/`, `.windsurf/workflows/`, `SESSION_LOG.md`, `SPRINT_PLAN_S0.md`, `README.md`, `progress/`) **ya creados en sesión checkpoint S0.0** (2026-05-01). S0.1 scope reducido a code scaffolding + git init/push.

| Campo | Valor |
|---|---|
| **Perfil** | 🔧 BUILDER + 📝 SCRIBE |
| **Modelo recomendado** | **Sonnet 4.6** |
| **Alternativa** | Opus si Sonnet no disponible |
| **Duración estimada** | **~1h** (reducida de 2h — operacionales pre-hechos) |
| **Dependencias** | Ninguna (primera session sprint) |

**Goal:** Code scaffolding (`.gitignore` + `server.cfg.example` + 2 fxmanifest scaffolds) + git init + commit + push GitHub repo `yaboula/admirals`.

**Files in scope:**
- `.gitignore`
- `server.cfg.example`
- `resources/admirals_bridges/fxmanifest.lua` (scaffold vacío)
- `resources/admirals_core/fxmanifest.lua` (scaffold vacío)
- `progress/SESSION_LOG.md` (append entry S0.1)

**Files OUT of scope:**
- `docs/*` (todos firmados — no tocar)
- Cualquier `.lua` con lógica real (solo scaffolds fxmanifest)
- Operacionales `.windsurf/`, `README.md`, `progress/SPRINT_PLAN_S0.md` → ya creados S0.0

**Done criteria:**
- [ ] `.gitignore` cubre: Lua/FiveM artifacts, Node (node_modules, dist, build), IDE (.vscode, .idea), OS (.DS_Store, Thumbs.db), logs, cache, `.env` local.
- [ ] `server.cfg.example` boots server FiveM válido con secciones: endpoints, resources (QBox + ox_* + lb-phone + oxmysql placeholders + admirals_*), sv_hostname, convars `admirals_bridge_*` + `admirals_db_*`, sv_licenseKey placeholder.
- [ ] 2 fxmanifest scaffolds válidos: fx_version 'cerulean', game 'gta5', lua54 'yes', author 'Admirals', version '0.0.1', dependencies declaradas.
- [ ] Entry `progress/SESSION_LOG.md` con handoff section para S0.2.
- [ ] `git init` (si no existe) + primer commit all files + `git remote add origin https://github.com/yaboula/admirals.git` + push `main`.
- [ ] Verificar GitHub muestra todos files del repo.

---

### S0.2 — Bridges Layer completo 🏗️

| Campo | Valor |
|---|---|
| **Perfil** | 🏗️ ARCHITECT |
| **Modelo recomendado** | **Opus 4.7** |
| **Alternativa** | Sonnet 4.6 (degraded quality — NO recomendado para esta session) |
| **Duración estimada** | 4-5h |
| **Dependencias** | S0.1 completa (repo scaffolding presente) |

**Goal:** `admirals_bridges` resource 100% funcional: Registry + Dispatcher + Logger + Detect + 6 bridge interfaces + 6 native fallback adapters + auto-detection + config overrides + boot report. Server arranca con resource cargando sin errores, boot report en consola correcto.

**Files in scope:** (19 archivos)
- `resources/admirals_bridges/fxmanifest.lua` (full)
- `resources/admirals_bridges/config.lua`
- `resources/admirals_bridges/server/init.lua`
- `resources/admirals_bridges/server/registry.lua`
- `resources/admirals_bridges/server/dispatcher.lua`
- `resources/admirals_bridges/server/logger.lua`
- `resources/admirals_bridges/server/detect.lua`
- `resources/admirals_bridges/bridges/{bank,inventory,phone,identity,target,notify}.lua` (6)
- `resources/admirals_bridges/adapters/{bank,inventory,phone,identity,target,notify}/native.lua` (6)

**Files OUT of scope:**
- Adapters externos (qbox, ox_*, lb-phone) → S0.3
- `resources/admirals_core/*` → S0.4

**Reference docs obligatorios:**
- `docs/technical/07_bridges_compatibility.md` §2 (arquitectura), §3 (registry+dispatcher+logger), §4-§9 (bridge interfaces), §10 (auto-detection), §11 (config), §12 (boot report).
- `docs/technical/06_fivem_standards.md` (performance budgets).
- `docs/technical/01_architecture.md` (Bridges Layer §).

**Done criteria:**
- [ ] Registry API funcional: `Bridges.RegisterAdapter(module, name, impl)`, `Bridges.GetAdapter`, `Bridges.ListAdapters`.
- [ ] Dispatcher API: `Bridges.Bank.*`, `Bridges.Inventory.*`, etc. routing correcto a adapter activo.
- [ ] Logger niveles Info/Warn/Error/Audit + boundary logging toggle per module.
- [ ] Detect scan `GetResourceState()` con priority order per spec bridges doc §10.
- [ ] Config overrides convars: `admirals_bridge_bank`, `admirals_bridge_inventory`, etc.
- [ ] 6 bridges con TODOS los métodos de interfaz per spec §4-§9 (signatures exactas).
- [ ] 6 native adapters implementan 100% sus interfaces (stub/lógica mínima, no errors runtime).
- [ ] Boot report en consola al start: "Admirals Bridges v0.1.0 | Bank→native | Inventory→native | ..." con tier count.
- [ ] Resource carga sin errores FiveM server vacío.
- [ ] Smoke: resmon <0.3ms idle.

---

### S0.3 — Bridges T1 adapters externos 🔧

| Campo | Valor |
|---|---|
| **Perfil** | 🔧 BUILDER |
| **Modelo recomendado** | **Sonnet 4.6** |
| **Alternativa** | GPT-5.3 Codex (si patrón super mecánico) / Opus si Sonnet confused |
| **Duración estimada** | 3h |
| **Dependencias** | S0.2 completa (interfaces + native fallbacks listos) |

**Goal:** 6 adapters Tier 1 oficiales: QBox bank + identity, ox_inventory, ox_target, ox_lib notify, lb-phone. Auto-detection los prefiere cuando scripts externos presentes.

**Files in scope:**
- `resources/admirals_bridges/adapters/bank/qbox.lua`
- `resources/admirals_bridges/adapters/identity/qbox.lua`
- `resources/admirals_bridges/adapters/inventory/ox_inventory.lua`
- `resources/admirals_bridges/adapters/target/ox_target.lua`
- `resources/admirals_bridges/adapters/notify/ox_lib.lua`
- `resources/admirals_bridges/adapters/phone/lb_phone.lua`
- `resources/admirals_bridges/fxmanifest.lua` (update server_scripts)
- `scripts/test_adapter.lua` (harness skeleton)

**Files OUT of scope:**
- `resources/admirals_core/*` → S0.4
- T2 adapters (QBCore, ESX, qb-*, qs-*) → fuera Sprint 0 (post-MVP)

**Reference docs:**
- `docs/technical/07_bridges_compatibility.md` §13 (T1 adapters spec exacta) + §4-§9 (interfaces).
- QBox/ox_inventory/ox_target/lb-phone documentation (exports reales).

**Done criteria:**
- [ ] 6 T1 adapters implementan completas interfaces (mapping exports reales).
- [ ] Auto-detection detecta scripts presentes y los activa.
- [ ] Fallback a native cuando script ausente.
- [ ] `scripts/test_adapter.lua` harness ejecutable (framework test, no tests completos).
- [ ] Smoke: server con stack T1 completa → boot report "all 6 T1 official".

---

### S0.4 — admirals_core + migrations + smoke test + sign-off 🏗️⚡

| Campo | Valor |
|---|---|
| **Perfil** | 🏗️ ARCHITECT + ⚡ SPRINTER |
| **Modelo recomendado** | **Opus 4.7** |
| **Alternativa** | Sonnet 4.6 si Opus no disp. (degraded para core, aceptable para migrations) |
| **Duración estimada** | 4h |
| **Dependencias** | S0.3 completa (bridges funcional end-to-end) |

**Goal:** `admirals_core` resource completo + migrations runner + 2 primeras migrations + smoke test 10 pasos + Sprint 0 sign-off.

**Files in scope:**
- `resources/admirals_core/fxmanifest.lua` (full, dependency `admirals_bridges`, `oxmysql`)
- `resources/admirals_core/config.lua`
- `resources/admirals_core/server/init.lua`
- `resources/admirals_core/server/event_bus.lua`
- `resources/admirals_core/server/db.lua`
- `resources/admirals_core/server/rate_limiter.lua`
- `resources/admirals_core/server/logger.lua`
- `resources/admirals_core/server/metrics.lua`
- `resources/admirals_core/server/migrations.lua`
- `resources/admirals_core/migrations/001_schema_versions.sql`
- `resources/admirals_core/migrations/002_core_tables.sql`
- `scripts/smoke_test.md`
- `progress/SPRINT_RETRO_S0.md`

**Files OUT of scope:**
- Tablas completas todos módulos (solo subset foundational).
- Frontend/NUI.

**Reference docs:**
- `docs/technical/03_db_schema.md` (subset foundational tablas).
- `docs/technical/04_api_contracts.md` (EventBus patterns).
- `docs/technical/06_fivem_standards.md` (perf + security).

**Done criteria:**
- [ ] EventBus: publish/subscribe wrapper + rate limiting integrado.
- [ ] DB wrappers oxmysql: FetchOne/FetchAll/Execute/Transaction.
- [ ] RateLimiter: token bucket per citizenId, configurable per endpoint.
- [ ] Logger estructurado + rotación básica.
- [ ] Metrics counters: events_emitted, db_queries, bridge_calls, errors_total.
- [ ] Migrations runner: idempotente, checksum SHA-256, aplica `NNN_*.sql` en orden, tracking `admirals_schema_versions`.
- [ ] Migration 001: crea `admirals_schema_versions`.
- [ ] Migration 002: crea tablas foundational (accounts, bank_accounts, audit_log — subset mínimo para boot).
- [ ] `scripts/smoke_test.md` 10 pasos manuales.
- [ ] Founder ejecuta smoke test → 10/10 ✅.
- [ ] `git tag v0.0.0` + push.
- [ ] `progress/SPRINT_RETRO_S0.md` escrito.
- [ ] `docs/planning/01_roadmap.md` §4.2 S0 ✅.

---

## Notas founder

- Descanso entre S0.2 (Opus intensivo) y S0.3 (Sonnet workhorse) recomendado 1-2 días.
- Si detectas scope balloon en S0.2 (>5h) → STOP, split en S0.2a (core infra) + S0.2b (bridges + adapters native).
- Retro S0 capturará si estimados fueron realistas — ajustaremos S1 planning.

---

**FIN SPRINT_PLAN_S0**
