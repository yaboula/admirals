# 📋 Admirals — Session Log

> **Append-only log de todas las sessions AI del proyecto.**
> Formato per entry: ver `docs/agents/03_founder_playbook.md` §5.3.
> Más recientes **abajo** (append natural).

---

## Protocolo

- **Cada session AI escribe 1 entry obligatoria al cierre.**
- **Founder valida** entry antes de commit.
- **Nunca editar entries antiguas** — corrección = nueva entry con referencia (`Correction of S{N}.{M}`).
- **AI al iniciar sesión nueva lee últimas 3 entries** como mínimo para recuperar contexto.

---

## Entries

### S0.0 — Checkpoint inicial Oleada 0 cerrada

- **Fecha:** 2026-05-01
- **Duración:** ~5h sesión marathón (escrita retrospectivamente, no session ejecutiva normal)
- **Founder + Agent:** yaboula + Cascade (Claude)
- **Sprint:** — (pre-Sprint 0, cierre Oleada 0)
- **Perfil:** 🏗️ ARCHITECT + 📝 SCRIBE
- **Modelo:** Claude (Cascade)
- **Goal:** Cerrar Oleada 0 con último doc pendiente + ADRs + actualizar estado proyecto + preparar Sprint 0 operacional.
- **Status:** ✅ Done

### Cambios
- **Firmado:** `docs/technical/07_bridges_compatibility.md` v1.0 (~900 líneas, 18 secciones) — Bridges Layer foundational multi-framework + Custom Adapter SDK.
- **Registrado:** ADR-008 (Pivot MVP Bakery→Granja, supersedes ADR-005) + ADR-009 (Bridges Layer foundational) en `docs/planning/02_decision_log.md` v1.1.
- **Actualizado:** `docs/agents/00_BOOTSTRAP.md` v1.2 (Oleada 0 CERRADA 100%, 29/29 docs, 27.260 líneas).
- **Actualizado:** `docs/planning/01_roadmap.md` v1.2 (Oleada 0 ✅, done criteria cumplidos).
- **Creado:** `docs/agents/03_founder_playbook.md` v1.0 (operaciones founder + AI por session).
- **Creado:** `progress/SESSION_LOG.md` (este file).
- **Pendiente S0.1:** `progress/SPRINT_PLAN_S0.md`, `.windsurf/rules/admirals.md`, `.windsurf/workflows/*`, `README.md` repo, repo scaffolding, initial git push.

### Decisiones tomadas
- **ADR-008 Granja pivot:** MVP Oleada 1 = Granja (cross-vertical root per Product Bible §13.4), no Bakery. Oleada 2 construye Molino→Bakery→Retail sobre wheat real de player-founded Granjas.
- **ADR-009 Bridges Layer:** QBox primary + compat multi-framework + custom scripts vía Bridges + 6 bridges (Bank/Inventory/Phone/Identity/Target/Notify) + Tier system T1/T2/T3 + Custom Adapter SDK.
- **Model allocation strategy (playbook §2.3):** Opus 4.7 = primary backend Y frontend. Sonnet 4.6 para patterns repetitivos (ahorro capacidad). Gemini 3.1 Pro para contexto masivo/multimodal. GPT-5.3 Codex para iteraciones rápidas de tests.
- **Sprint 0 = 4 sessions** (no 6): S0.1 (Sonnet, BUILDER+SCRIBE scaffolding), S0.2 (Opus, ARCHITECT Bridges Layer completo), S0.3 (Sonnet, BUILDER T1 adapters), S0.4 (Opus, ARCHITECT+SPRINTER admirals_core + migrations + sign-off).
- **Oleada 1 total = 29 sessions en 22 semanas** (revisado desde 48 previas).

### Issues pendientes
- Ninguno bloqueante. S0.1 listo para iniciar con session AI fresca.

### Handoff próxima sesión (S0.1)
- **Modelo recomendado:** Sonnet 4.6 (tarea estructural, no amerita Opus).
- **Goal:** Repo scaffolding + operacionales `.windsurf/` + `.gitignore` + `server.cfg.example` + fxmanifest scaffolds + `README.md` + `progress/SPRINT_PLAN_S0.md` + git init + first commit + push `https://github.com/yaboula/admirals.git`.
- **Pre-requisitos:** Leer `docs/agents/00_BOOTSTRAP.md` v1.2 + `docs/agents/03_founder_playbook.md` §4-§6 + este entry.
- **Prompt de inicio:** usar template `docs/agents/03_founder_playbook.md` §6.1 con variables rellenadas per S0.1 spec en §10.2.
- **Files in scope:** ver playbook §10.2 S0.1.
- **Files OUT of scope:** todo `docs/*` (firmados) + cualquier `.lua` con lógica real.
- **Done criteria:** 9 bullets per playbook §10.2 S0.1.

### Files in scope respetados
✅ Solo modificó docs firmados con founder approval explícito (bridges.md, bootstrap, roadmap, decision_log, playbook new).

---

## S0.1 — Repo code scaffolding + first push

- **Fecha:** 2026-05-01
- **Duración:** ~1h
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6)
- **Sprint:** S0 — Setup + Bridges Layer + admirals_core
- **Perfil:** 🔧 BUILDER + 📝 SCRIBE
- **Modelo:** Sonnet 4.6
- **Goal:** Code scaffolding (`.gitignore` + `server.cfg.example` + 2 fxmanifest scaffolds) + commit + push GitHub.
- **Status:** ✅ Done

### Cambios
- **Creado:** `.gitignore` — cubre Lua/FiveM artifacts, Node (node_modules/dist/build/.next), IDE (.vscode/.idea/.cursor), OS (.DS_Store/Thumbs.db), logs (*.log/logs/), cache (.cache/), .env* + server.cfg. `.windsurf/` excluido intencionalmente (va al repo).
- **Creado:** `server.cfg.example` — endpoints, sv_hostname/licenseKey/maxclients/scriptHookAllowed, mysql_connection_string, convars `admirals_db_*` (host/user/password/database), convars `admirals_bridge_*` (6 módulos bank/inventory/phone/identity/target/notify) + `admirals_bridge_bank_mode`, convar `admirals_env`, resources block ordenado (oxmysql→ox_lib→ox_inventory→ox_target→qbx_core→lb-phone→admirals_bridges→admirals_core).
- **Creado:** `resources/admirals_bridges/fxmanifest.lua` — scaffold válido: fx_version cerulean, game gta5, lua54 yes, author/version/description. server_scripts vacío comentado (S0.2).
- **Creado:** `resources/admirals_core/fxmanifest.lua` — scaffold válido: mismo header + dependencies { 'oxmysql', 'admirals_bridges' }. server_scripts vacío comentado (S0.4).

### Decisiones tomadas
- `server.cfg` añadido al `.gitignore` (contiene secrets — solo `server.cfg.example` va al repo).
- Convars bridges con `setr` (readable client+server) per `07_bridges_compatibility.md` §10.2. Overrides comentados por defecto — auto-detection es el flujo normal.
- Resources block: `admirals_bridges` antes de `admirals_core` (core depende de bridges per fxmanifest dependency declaration).

### Issues pendientes
- Ninguno.

### Handoff próxima sesión (S0.2)
- **Modelo recomendado:** Opus 4.7 (ARCHITECT — Bridges Layer completo es arquitectura crítica, afecta todo downstream).
- **Goal:** `admirals_bridges` resource 100% funcional: Registry + Dispatcher + Logger + Detect + 6 bridge interfaces + 6 native fallback adapters + auto-detection + config overrides + boot report.
- **Docs a leer obligatorio:**
  - `docs/technical/07_bridges_compatibility.md` §2-§12 completo.
  - `docs/technical/06_fivem_standards.md` (perf budgets — resmon <0.3ms idle).
  - `docs/technical/01_architecture.md` §Bridges Layer.
  - `progress/SESSION_LOG.md` últimas 2 entries (S0.0 + S0.1).
  - `progress/SPRINT_PLAN_S0.md` §S0.2.
- **Files in scope S0.2:** 19 archivos en `resources/admirals_bridges/` — ver `SPRINT_PLAN_S0.md` §S0.2 lista exacta.
- **Pre-condición:** repo limpio con commit S0.1 presente.

### Files in scope respetados
✅ Solo tocó los 4 files whitelist (`.gitignore`, `server.cfg.example`, 2 `fxmanifest.lua`) + append SESSION_LOG. No tocó `docs/*`, `.windsurf/*`, `README.md`, `SPRINT_PLAN_S0.md`.

---

## S0.2 — Bridges Layer completo (Registry + Dispatcher + 6 interfaces + 6 native adapters + auto-detection + boot report)

- **Fecha:** 2026-05-01
- **Duración:** ~2h (escritura + self-review)
- **Founder + Agent:** yaboula + Cascade (Opus 4.7)
- **Sprint:** S0 — Setup + Bridges Layer + admirals_core
- **Perfil:** 🏗️ ARCHITECT
- **Modelo:** Opus 4.7 (recomendado por playbook §10.2 — arquitectura foundational)
- **Goal:** `admirals_bridges` resource 100% funcional: Registry + Dispatcher + Logger + Detect + 6 bridge interfaces + 6 native fallback adapters + auto-detection + config overrides + boot report ASCII.
- **Status:** ✅ Done (code); 🟡 pendiente smoke test manual founder con FiveM server real.

### Cambios
- **Actualizado:** `resources/admirals_bridges/fxmanifest.lua` — scaffold → full manifest con `shared_scripts { config.lua }` + `server_scripts { ... 18 archivos en orden canonical § 2.3 de `07_bridges_compatibility.md` }` + comentario explicando load-order rationale. Version bump 0.0.1→0.1.0.
- **Creado:** `resources/admirals_bridges/config.lua` — constantes (Version, Modules, LogLevel, LogBoundaryGlobal + per-module, BankMode, IdempotencyTTLSec), `DetectionPriority` map literal per doc §10.1, `AdapterResourceMap` (20 entries adapter→resource), `AdapterTiers` (T1/T2/Native clasificación), `CustomAdapters = {}` hook SDK, `LogColors` ANSI, `LogLevelNumeric` filtering.
- **Creado:** `resources/admirals_bridges/server/logger.lua` — niveles Debug/Info/Warn/Error/Audit, `Logger.Boundary(module, method, args, result, latency, adapter)` canónico, ring buffer 500 entries (config-driven) con `GetAuditTrail()`/`ClearAuditTrail()`, ANSI color codes, filtering por `LogLevel`, `SetLogLevel()` runtime hook para tests.
- **Creado:** `resources/admirals_bridges/server/registry.lua` — `Bridges.RegisterAdapter/GetAdapter/ListAdapters/SetActive/GetActive` + validación estricta: module debe ser canónico (Config.Modules), name único per módulo, impl debe implementar TODOS los `_required_methods` declarados por su bridge (boot-time hard fail si falla). Exposición read-only `Bridges._registry`, `Bridges._active`.
- **Creado:** `resources/admirals_bridges/server/dispatcher.lua` — `Bridges.Dispatcher.Call(module, method, args)` con pcall wrapping + latency measurement via `GetGameTimer()` + boundary logging automático + error codes canónicos (`BRIDGE_UNAVAILABLE`/`METHOD_NOT_IMPLEMENTED`/`FAILED`). Idempotency helpers `Bridges._IsIdemReplay`/`_StoreIdem` con TTL in-memory (S0.2) + GC thread cada 5min (promovido DB S0.4 per §4.3).
- **Creado:** `resources/admirals_bridges/bridges/{bank,inventory,phone,identity,target,notify}.lua` (6 archivos) — firmas literales per doc §4.2/§5.2/§6.2/§7.2/§8.2/§9.2 con LuaCATS annotations completas + `_required_methods` declarado per bridge + `IsAvailable()` bridge-level ("is non-native adapter active") distinto del adapter-level ("is my resource started"). `identity.lua` incluye fan-out bridge-level para `OnPlayerLoaded/OnPlayerDropped` via eventos internos `admirals:bridge:_identityPlayerLoaded/_identityPlayerDropped` (adapters disparan, bridge multiplexa a callbacks registered).
- **Creado:** `resources/admirals_bridges/adapters/{bank,inventory,phone,identity,target,notify}/native.lua` (6 archivos) — todos implementan `_required_methods` + `RegisterAdapter` al load:
  - **bank/native:** Modo A no-op (ledger SSoT vive en admirals_core S0.4+). Idempotency honorada (`_with_idem` wrapper).
  - **inventory/native:** in-memory carry map `{ [citizenId] = { [item_name] = { count, metadata } } }` + capacity check (50.0 peso max) + metadata rica soportada. Dump/Reset helpers para tests.
  - **phone/native:** `SendNotification`/`SendSMS` → Logger.Info + `GlobalState['admirals:phone:lastNotification:<cid>']` (consumible por Tablet S1+). `StartCall` → `UNSUPPORTED`. `GetPhoneNumber` → sintético determinístico 555-XXXX hash.
  - **identity/native:** `GetCitizenId` via `GetPlayerIdentifiers` + prefer `license2:` sobre `license:`, caches bidireccionales src↔cid. Lifecycle: `playerJoining` (500ms settling) → fire evento interno `_identityPlayerLoaded`. `playerDropped` → fire `_identityPlayerDropped`. Solo fire si native es adapter activo (`Bridges._active.identity == 'native'` check en runtime).
  - **target/native:** stub server-only (warn-once) + registry zones/entities/models expuesto para S0.4+ client script distance-check.
  - **notify/native:** `chat:addMessage` con color RGB + prefix per type (info/success/warning/error). `Broadcast` = source -1.
- **Creado:** `resources/admirals_bridges/server/detect.lua` — `Detect.Run()` (priority scan + IsAvailable check), `Detect.ApplyOverrides(detected)` (convars `admirals_bridge_<module>` + `Config.CustomAdapters` T3 SDK), `Detect.ConflictScan()` (warn si >1 resource del mismo módulo started).
- **Creado:** `resources/admirals_bridges/server/init.lua` — boot orchestration deferred 1 tick (Wait(0) para que adapter RegisterAdapter calls completen) → `_ValidateBridges` (assert cada módulo tiene bridge + native) → ConflictScan → Run → ApplyOverrides → SetActive → `PrintBootReport` ASCII con borders `═` + tags `[T1 OFFICIAL]`/`[T2 COMPAT]`/`[NATIVE]` color-coded → dispara evento `admirals:bridge:ready`. `Bridges.IsReady()` + `Bridges.WaitReady(timeout_ms)` helpers para admirals_core.

### Decisiones tomadas
- **Dispatch explícito (no metatable):** cada bridge/*.lua declara funciones nominadas que llaman `Bridges.Dispatcher.Call('module', 'Method', { args, n = N })`. Trade-off: 6 archivos algo repetitivos pero stack traces nominados + LuaCATS-friendly + contratos visibles per-file. Rechazado metatable `__index` magic porque dificulta debug.
- **Boundary logging dual toggle:** convar global `admirals_bridge_log_boundary` (0|1) + per-módulo `admirals_bridge_log_boundary_<module>` (permite debug quirúrgico por módulo en production sin ruido global). Leído 1x al boot — restart para re-configurar.
- **Native Bank Modo A puro (sin storage):** doc §4.1 define Modo A como "Admirals usa SOLO su ledger propio" — native no crea ledger paralelo. Returns `(true, nil, {noop=true, mode=Config.BankMode})`. Idempotency honorada vía `_with_idem` wrapper para que comportamiento sea idéntico cuando adapter externo reemplace native.
- **Native Target como stub server-only:** client-side distance-check (doc §11.2) requiere `resources/admirals_bridges/client/*.lua` que NO está en scope S0.2 whitelist. Adapter registra zones/entities/models en tabla consumible S0.4+ por `admirals_core/client/target_native_consumer.lua`. Warn-once al primer call.
- **Idempotency helpers en `server/dispatcher.lua`:** decidido ahí en lugar de `bridges/bank.lua` porque son infrastructure genérica (cualquier bridge puede usarlas). Internal API stable — swap a DB-backed (`admirals_bridge_idempotency` table per §4.3) transparente en S0.4.
- **Validation estricta en `RegisterAdapter`:** fallo = `error(..., 2)` (boot-time hard fail). Mejor que warn-log silencioso: si un adapter no implementa un método, quiero que el server NO arranque antes que runtime-failure 2 semanas después.
- **`OnPlayerLoaded/OnPlayerDropped` pattern no-Dispatcher:** bridge-level mantiene `_loaded_callbacks` + `_dropped_callbacks` arrays. Adapters disparan eventos internos FiveM (`admirals:bridge:_identityPlayerLoaded`), bridge layer fans-out a callbacks registered. Más limpio que wrappear callback registration por Dispatcher.Call (que no fit con pattern request/response).
- **Deferred boot 1 tick en init.lua:** `CreateThread + Wait(0)` para garantizar que todos los adapter `RegisterAdapter` calls en load time completen antes de validación + detection.

### Verificación estática
- ✅ **Regla de oro bridges:** 0 matches de `exports[...]` dentro de `admirals_bridges/` (solo referenciado en strings de `config.lua` como nombres de resources, no como calls). Verified vía `grep_search`.
- ✅ **No `QBCore.` / `ESX.` calls:** 0 matches en código. Solo `qbcore`/`esx` strings en `Config.DetectionPriority` / `Config.AdapterResourceMap` / `Config.AdapterTiers` (nombres identificadores).
- ✅ **19 archivos exactos creados** matching whitelist playbook §10.2 S0.2 + SPRINT_PLAN_S0 §S0.2.
- ⚠️ **Syntax linter no ejecutado:** lua/luac/luac54/luajit no disponibles en PowerShell PATH. Self-review manual confirmado: load order garantiza `Bridges`/`Logger`/`Config` disponibles cuando referenciados, idempotency helpers definidos antes de adapter que las usa, `_required_methods` declarado antes de `RegisterAdapter` call, event handlers registered antes de cualquier posible fire.

### Issues pendientes
- 🟡 **Smoke test manual pendiente founder:** arrancar FiveM server con `ensure admirals_bridges` (solo) + verificar boot report `Native: 6 / Total: 6` sin errores. Ver §Smoke check abajo.
- 🔵 **S0.3 siguiente:** 6 adapters T1 externos (qbox bank+identity, ox_inventory, ox_target, ox_lib notify, lb_phone phone) + `scripts/test_adapter.lua` harness skeleton.
- 🔵 **Tabla `admirals_bridge_idempotency` en migrations S0.4:** swap in-memory store a DB-backed per doc §4.3 (TTL 1h preserved, persistencia cross-restart).
- 🔵 **Target client-side consumer S0.4:** `admirals_core/client/target_native_consumer.lua` lee `Bridges._GetAdapter('target', 'native')._GetZones()` (etc.) + distance-check + marker + keypress E. Scope excluido S0.2 intencionalmente.

### Smoke check (founder ejecuta antes sign-off S0.2)
1. **Setup:** en `server.cfg` dejar solo `ensure oxmysql` + `ensure admirals_bridges` (comentar core + frameworks).
2. **Arrancar server:** `FXServer.exe +exec server.cfg`.
3. **Verificar consola:**
   - `^7[HH:MM:SS] ^7[INFO]^7 ^6[admirals_bridges]^7 Admirals Bridges v0.1.0 booting...`
   - Boot report ASCII con 6 módulos → `native` + `[NATIVE]` tag gris.
   - Línea `Native: 6 / Total: 6`.
   - `Bridges ready. Modules active: bank=native, inventory=native, phone=native, identity=native, target=native, notify=native`.
4. **Verificar sin errors:** grep `^1[ERROR]` o `error:` en consola → 0 matches.
5. **Verificar NativeTarget warn-once:** al primer (fake) call `Bridges.Target.AddBoxZone(...)` debe aparecer warn "NativeTarget is a stub...".
6. **Verificar resmon:** comando `resmon` consola → `admirals_bridges` idle <0.3ms (budget doc `06_fivem_standards.md` §2.2).
7. **Verificar convar override:** añadir `setr admirals_bridge_bank "native"` explícito → re-arrancar → no cambio (mismo detected). Set `setr admirals_bridge_bank "qbox"` sin qbx_core started → warn "adapter not registered, keeping native" + report sigue `native`.
8. **(Opcional) test programático:** `exec` un snippet `local ok, err = Bridges.Bank.AddMoney('TEST_CID', 100, 'test', 'idem_001')` → returns `true, nil, {mode='standalone', noop=true}`. Segunda llamada con mismo idem key → replay cached.

### Handoff próxima sesión (S0.3)
- **Modelo recomendado:** Sonnet 4.6 (pattern repetitivo — 6 adapters externos similares — ahorra Opus capacity per playbook §2.3).
- **Perfil:** 🔧 BUILDER.
- **Goal:** 6 T1 adapters completos: `adapters/bank/qbox.lua`, `adapters/identity/qbox.lua`, `adapters/inventory/ox_inventory.lua`, `adapters/target/ox_target.lua`, `adapters/notify/ox_lib.lua`, `adapters/phone/lb_phone.lua`. Update fxmanifest server_scripts list. Crear `scripts/test_adapter.lua` harness skeleton. Smoke: con QBox + ox_inventory + ox_target + ox_lib + lb-phone installed → boot report muestra `T1 OFFICIAL` para 6 módulos.
- **Docs a leer obligatorio:**
  - `docs/technical/07_bridges_compatibility.md` §4.4 (QBox bank), §5.5 (ox_inventory), §6.4 (lb_phone), §7.4 (QBox identity), §8.3 (ox_target), §9.3 (ox_lib), §12.5 (test harness).
  - Este entry S0.2 (arquitectura bridges + pattern registro adapter).
  - `progress/SPRINT_PLAN_S0.md` §S0.3 (19 done criteria, files in/out scope, duración 3h).
- **Pre-condición:** smoke S0.2 passing. Commit S0.2 pushed. Git clean.
- **Pattern replicar per adapter externo:** copia shape `adapters/<module>/native.lua` → reemplaza lógica con calls a `exports.<resource>` apropiados → mantener idempotency wrapper si bank → `Bridges.RegisterAdapter(module, name, impl)` al final. Validación `_required_methods` automática en boot-time.
- **No tocar:** bridges/*.lua (interfaces congeladas S0.2), server/*.lua (foundation congelada), nuevos bridges (requiere ADR).

### Files in scope respetados
✅ Exactos 19 archivos dentro `resources/admirals_bridges/` matching SPRINT_PLAN_S0.md §S0.2 whitelist literal. 1 edit (`fxmanifest.lua`) + 18 creates. No tocó `docs/*`, ni otros resources, ni `.windsurf/*`, ni `progress/SPRINT_PLAN_S0.md`.

---
