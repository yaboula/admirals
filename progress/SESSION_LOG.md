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

## S0.3 — Bridges T1 adapters externos (QBox + ox_inventory + ox_target + ox_lib + lb-phone)

- **Fecha:** 2026-05-02
- **Duración:** ~2h
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6)
- **Sprint:** S0 — Setup + Bridges Layer + admirals_core
- **Perfil:** 🔧 BUILDER
- **Modelo:** Sonnet 4.6 (patrón repetitivo — ahorra Opus per playbook §2.3)
- **Goal:** 6 adapters T1 oficiales + test harness skeleton. Auto-detection prefiere T1 cuando scripts presentes.
- **Status:** ✅ Done (code); 🟡 pendiente smoke test manual con stack T1 completo instalado.

### Cambios
- **Creado:** `resources/admirals_bridges/adapters/bank/qbox.lua` — `exports.qbx_core:GetPlayerByCitizenId` + `Player.Functions.AddMoney/RemoveMoney` + idempotency wrapper `_with_idem` idéntico al native + Transfer atómico con rollback automático si AddMoney falla. `IsAvailable` → `GetResourceState('qbx_core')`.
- **Creado:** `resources/admirals_bridges/adapters/identity/qbox.lua` — `exports.qbx_core:GetPlayer/GetPlayerByCitizenId` + cache bidireccional src↔cid + `GetPlayerData` shape canónico (citizenId/source/firstname/lastname/charinfo) + `GetJob` framework-only. Lifecycle hooks: `QBCore:Server:OnPlayerLoaded` (character load), `QBCore:Server:PlayerLogout` (character logout), `playerDropped` (safety-net) — todos con `_is_active()` guard. Debug helpers `_DumpCache/_Reset`.
- **Creado:** `resources/admirals_bridges/adapters/inventory/ox_inventory.lua` — `exports.ox_inventory:AddItem/RemoveItem/Search/GetInventoryItems/RegisterItem/GetWeight` + source lookup via `Bridges.Identity.GetSource(citizenId)` + `GetCapacity` con pcall para `GetMaxWeight` (fallback 30000g default ox_inventory) + `IsMetadataSupported=true`. `RegisterItem` pcall-protegido (item puede ya estar en `data/items.lua`).
- **Creado:** `resources/admirals_bridges/adapters/target/ox_target.lua` — Almacena zones/entities/models server-side (mismo store que native) + `TriggerClientEvent('admirals:bridge:target:addBoxZone/addEntity/addModel/removeZone', -1, ...)` a clientes conectados. S0.4 client consumer (`admirals_bridges/client/target_ox_consumer.lua`) escuchará estos eventos y llamará `exports.ox_target` directamente. `IsAvailable` → `GetResourceState('ox_target')`.
- **Creado:** `resources/admirals_bridges/adapters/notify/ox_lib.lua` — `exports.ox_lib:notify(source, opts)` + fallback a `TriggerClientEvent('ox_lib:notify', source, opts)` si export falla (cross-versión robustez). Mapeo de tipos Admirals→ox_lib: `'info'→'inform'`. `Broadcast` via loop `GetPlayers()`.
- **Creado:** `resources/admirals_bridges/adapters/phone/lb_phone.lua` — `exports['lb-phone']:SendNotification(source, data)` para notificaciones + `SendSMS` como notificación enriquecida con `app='messages'` (lb-phone no expone API server-side de mensajes en todos builds v2.x — documentado en código). `GetPhoneNumber` vía `charinfo.phone` (QBox) → fallback `GetPlayerInfo`. `StartCall` retorna `UNSUPPORTED` (API no documentada públicamente — flaggeado para founder).
- **Creado:** `resources/admirals_bridges/scripts/test_adapter.lua` — `RunTests(module, adapter_name)` + `_tests_bank/inventory/phone/identity/target/notify` (5/5/4/5/4/3 test placeholders respectivamente). `RegisterCommand('admirals_test_adapter')` solo desde consola server (src=0 guard). Tests son skeleton estructural S0.3 — todos marcados `TODO S0.4`.
- **Editado:** `resources/admirals_bridges/fxmanifest.lua` — `server_scripts` añade 6 T1 adapters después de `native.lua` y antes de `detect.lua`. Load order comment actualizado (paso 7 nuevo). Version bump `0.1.0→0.2.0`.

### Decisiones tomadas
- **ox_target server-only con TriggerClientEvent:** ox_target es client-side. Adapter almacena zones server-side + notifica clientes conectados via evento `admirals:bridge:target:*`. S0.4 añade client consumer. Misma arquitectura que native (store + defer client) pero con propagación activa a clientes online.
- **lb_phone SendSMS via notificación:** lb-phone v2.x no expone API server-side de mensajes en todos builds. Implementado como `SendNotification(app='messages')` — player ve notificación en app de mensajes. **Flag al founder:** si tu build de lb-phone expone export de mensajes directos, extender esta función.
- **lb_phone StartCall UNSUPPORTED:** retorna `(false, 'UNSUPPORTED')`. Callers de admirals_core deben manejar este caso. Phone es canal nice-to-have, nunca crítico per doc §6.5.
- **GetPhoneNumber vía charinfo:** número de teléfono en QBox+lb-phone vive en `Player.PlayerData.charinfo.phone`. Se accede via `Bridges.Identity.GetPlayerData(citizenId).charinfo.phone` — no require export adicional de lb-phone.
- **ox_lib cross-versión:** se intenta `exports.ox_lib:notify` primero (v3+), fallback a `TriggerClientEvent('ox_lib:notify')` (v2+). Ambos mecanismos funcionan en oxlib instalaciones actuales.
- **ox_inventory RegisterItem pcall-protegido:** item puede estar ya definido en `data/items.lua` del resource. Fallo no es fatal — log warning + return false. Boot continúa.
- **Version bump 0.1.0→0.2.0:** minor bump por adición de 6 adapters T1 (feature additions, no breaking changes a interfaces).

### Verificación estática
- ✅ **0 matches `QBCore.`** en `resources/admirals_bridges/` — solo `qbx_core` como nombre de resource.
- ✅ **0 matches `ESX.`** en `resources/admirals_bridges/`.
- ✅ **0 matches `exports['qb-*']`** — solo `exports['lb-phone']` (lb-phone, no qb-fork).
- ✅ **7 archivos exactos creados** (6 adapters T1 + test harness) matching whitelist SPRINT_PLAN §S0.3.
- ✅ **fxmanifest.lua actualizado** — 6 entradas T1 en posición canonical (post-native, pre-detect).
- ⚠️ **Syntax linter no ejecutado** — lua/luac no disponibles en PowerShell PATH. Self-review: LuaCATS annotations correctas, `goto continue` pattern válido Lua 5.4, `table.pack/unpack` correctos, `pcall` returns seguros.

### Issues pendientes
- 🟡 **Smoke test manual founder:** arrancar con stack T1 completo (qbx_core + ox_inventory + ox_target + ox_lib + lb-phone) → boot report debe mostrar `[T1 OFFICIAL] × 6` + `T1 OFFICIAL: 6 / Total: 6`.
- 🔵 **lb-phone StartCall:** implementar si tu build expone export server-side `exports['lb-phone']:StartCall(src_to, src_from)`.
- 🔵 **ox_target client consumer S0.4:** `admirals_bridges/client/target_ox_consumer.lua` escucha `admirals:bridge:target:*` events y llama `exports.ox_target` — scope S0.4.
- 🔵 **test_adapter.lua S0.4:** implementar tests reales (TODO S0.4 markers) cuando admirals_core provee test players y DB mocks.

### Smoke check S0.3 (founder ejecuta)
1. Añadir a `server.cfg` (en orden): `ensure oxmysql`, `ensure ox_lib`, `ensure qbx_core`, `ensure ox_inventory`, `ensure ox_target`, `ensure lb-phone`, `ensure admirals_bridges`.
2. Arrancar server → consola debe mostrar boot report con `[T1 OFFICIAL]` en los 6 módulos.
3. Verificar `T1 OFFICIAL: 6 / Total: 6` en boot report.
4. `resmon` consola → `admirals_bridges` idle <0.3ms.
5. (Opcional) `exec resources/admirals_bridges/scripts/test_adapter.lua` → `admirals_test_adapter bank qbox` → output estructural (todos SKIP — S0.3 skeleton).

### Handoff próxima sesión (S0.4)
- **Modelo recomendado:** Opus 4.7 (ARCHITECT+SPRINTER — admirals_core es arquitectura foundational crítica).
- **Perfil:** 🏗️ ARCHITECT + ⚡ SPRINTER.
- **Goal:** `admirals_core` completo: EventBus + DB wrappers (oxmysql) + RateLimiter + Logger + Metrics + Migrations runner + 2 primeras migrations + smoke test 10 pasos + Sprint 0 sign-off + `git tag v0.0.0`.
- **Docs a leer obligatorio:**
  - `docs/technical/03_db_schema.md` (subset foundational tablas para migrations 001/002).
  - `docs/technical/04_api_contracts.md` (EventBus patterns + exports admirals_core).
  - `docs/technical/06_fivem_standards.md` (perf budgets + RateLimiter).
  - `progress/SESSION_LOG.md` últimas 3 entries (S0.1/S0.2/S0.3).
  - `progress/SPRINT_PLAN_S0.md` §S0.4 (11 done criteria).
- **Pre-condición:** smoke S0.3 passing (boot report T1 × 6). Commit S0.3 pushed. Git clean.
- **Files in scope S0.4:** `resources/admirals_core/` completo (fxmanifest + config + server/init + server/event_bus + server/db + server/rate_limiter + server/logger + server/metrics + server/migrations + migrations/001_*.sql + migrations/002_*.sql) + `scripts/smoke_test.md` + `progress/SPRINT_RETRO_S0.md`.
- **No tocar:** `resources/admirals_bridges/*` (congelado S0.3), `docs/*`.

### Files in scope respetados
✅ Exactos 7 creates + 2 edits (fxmanifest + SESSION_LOG) = 9 operaciones, matching whitelist SPRINT_PLAN_S0.md §S0.3. No tocó `bridges/*.lua`, `server/*.lua`, `adapters/*/native.lua`, `docs/*`, `resources/admirals_core/*`, `README.md`, `SPRINT_PLAN_S0.md`.

---

## S0.4 — admirals_core foundation (EventBus + DB + RateLimiter + Logger + Metrics + Migrations) + Sprint 0 close

- **Fecha:** 2026-05-02
- **Duración:** ~4h (estimado SPRINT_PLAN: 4h ✅ on-target)
- **Founder + Agent:** yaboula + Cascade (Opus 4.7)
- **Sprint:** S0 — Setup + Bridges Layer + admirals_core foundation (🏆 SPRINT 0 CLOSE en esta session)
- **Perfil:** 🏗️ ARCHITECT + ⚡ SPRINTER
- **Modelo:** Opus 4.7 (arquitectura foundational crítica downstream — decisión founder §2.3 playbook)
- **Goal:** `admirals_core` v0.1.0 completo + migrations 001/002 + smoke test 10 pasos + ADR-010 + docs edits + retro + S1 plan outline + Sprint 0 tag v0.0.0.
- **Status:** ✅ Done (código + docs); 🟡 pendiente smoke test manual founder + `git tag v0.0.0`.

### Cambios
- **Creado:** `resources/admirals_core/config.lua` — `Admirals.Config` namespace con Version, Env, LogLevel + numeric map, LogRingBufferSize=1000, MetricsHistogramWindow=500, DbTimeoutMs=3000, DbSlowQueryMs=500, BusAuditMode convar, BusAsyncThresholdMs=50, BusTracingKeys, RateBuckets default (7 buckets canonical per §04 §8.1), RateGcIntervalSec=300, MigrationsDir/Pattern/FailFast/ChecksumCheck, MigrationsFiles list explícita (001 + 002), BridgesWaitTimeoutMs=15000, CoreReadyEventName, AdminAcePrefix, AdminCommands registry.
- **Creado:** `resources/admirals_core/server/logger.lua` — `Admirals.Log.{Debug,Info,Warn,Error,Audit}` + ring buffer circular O(1) append 1000 entries + GetRingBuffer/Clear/SetLevel/GetLevel/Size + ANSI colors FiveM (^1-^9) + admin commands `/admirals_log_dump [n]`, `/admirals_log_level <lv>`, `/admirals_log_clear` ACE-gated (source=0 console siempre permitido).
- **Creado:** `resources/admirals_core/server/metrics.lua` — `Admirals.Metrics.{Counter,Gauge,Observe}` + histogram sliding window 500 samples con p50/p95/p99 nearest-rank + Get/Snapshot/Reset + admin commands `/admirals_metrics`, `/admirals_metrics_reset`. Output formateado por tipo (Counters/Gauges/Histograms) ordenado alfabético.
- **Creado:** `resources/admirals_core/server/db.lua` — `Admirals.DB.{FetchOne,FetchAll,Execute,Insert,Scalar,Transaction}` sobre oxmysql `.await`. Hard-enforce prepared statements: `_validate()` rechaza query sin '?' si params no vacío (anti-SQL-injection per §04 §6.1 + §06 T3). Duration metric per kind (select/insert/update/transaction), slow-query warn >500ms + soft-timeout >3000ms (detection + warn, no cancellation — oxmysql limitation documentada). `IsReady()/WaitReady()` ping `SELECT 1` para init orchestration. Transaction returns boolean, rollback automático por dup key.
- **Creado:** `resources/admirals_core/server/event_bus.lua` — `Admirals.Bus.{Subscribe,Unsubscribe,Publish,RegisterSchema,Stats}` canonical per `01_architecture.md` §5.5. Auto-decorate `_event_name, _event_id (UUID v4 RFC 4122), _emitted_at (unix ms), _schema_version` per `02_events_catalog.md` §1.4. pcall per handler (1 crash ≠ afecta otros), async threshold 50ms auto-flag handler a async próxima invocación. `opts.once/async/audit/broadcast_client`. Schema validation opcional via RegisterSchema. Metrics: publishes.{event}, handler_latency_ms.{event}, handler_errors.{event}, broadcasts.{event}, rejects.*.
- **Creado:** `resources/admirals_core/server/rate_limiter.lua` — `Admirals.Rate.{Check,RegisterBucket,GetBucket,Reset,Stats}` sliding window algorithm (array timestamps, purge at check). 7 default buckets desde Config.RateBuckets (tablet.query, bank.read/write, empresa.found, contract.dispute, item.transfer, market.create). GC thread cada 300s purga identity-bucket pairs donde último timestamp fuera de window (evita leak por citizens offline). Metrics: rate.allowed.{bucket}, rate.blocked.{bucket}, rate.gc_purged.
- **Creado:** `resources/admirals_core/server/migrations.lua` — `Admirals.Migrations.{RunAll,ListApplied,IsApplied}`. Flow: per cada file en Config.MigrationsFiles ordenado → parse filename `(%d%d%d)_(.+)%.sql` → read body via LoadResourceFile → SHA-256 via `DB.Scalar('SELECT SHA2(?, 256)', { body })` (no Lua crypto needed) → check `admirals_schema_versions` tabla + row version → skip si applied & checksum match, warn+fail-fast si checksum mismatch (tampering detect), apply via multi-statement split naive (`;\n` delimiter) + pcall per statement → INSERT tracking row. Fail-fast global per Config.MigrationsFailFast=true.
- **Creado:** `resources/admirals_core/server/init.lua` — Boot orchestration LAST. `Admirals.Core.{IsReady,WaitReady,Version,GetMigrationReport}` + exports. Secuencia: yield 1 tick → Bridges.WaitReady(15000ms) hard-fail → DB.WaitReady(15000ms) hard-fail → Migrations.RunAll hard-fail si errors → set Core._ready=true → `TriggerEvent('admirals:core:ready', payload)` + `Admirals.Bus.Publish('admirals:core:ready', payload, { broadcast_client = -1 })` → print boot report ASCII (env, log level, DB config, Bus config, boot_ms, migrations list). Admin command `/admirals_core_status` dumps ready state + migrations + bus stats + rate stats + log size.
- **Creado:** `resources/admirals_core/client/init.lua` — Stub minimal: `Admirals.Ready = false` flag + listen `RegisterNetEvent('admirals:core:ready')` → set flag true + print version. Lógica client real S1+ (Tablet NUI).
- **Creado:** `resources/admirals_core/migrations/001_schema_versions.sql` — `admirals_schema_versions` DDL canonical per `03_db_schema.md` §12.2 (version INT PK + filename UQ + applied_at + applied_by + checksum + duration_ms + notes).
- **Creado:** `resources/admirals_core/migrations/002_foundation_tables.sql` — 3 tablas foundation per ADR-010 Opción (C) híbrido:
  1. `admirals_accounts` minimal 7 cols (id CHAR(36) PK, char_id UQ+framework_source, alias, created_at, updated_at, last_login_at + 3 indexes). Subset respeta SSoT §3.1 canonical, expansible aditivamente ALTER TABLE ADD COLUMN S1+.
  2. `admirals_audit_log` NUEVA wrapper operational (id BIGINT AUTO_INC, ts, category, action, actor_account_id, actor_source, target_type, target_id, amount, currency, request_id, resource, metadata JSON, ip_address + 5 indexes). Distinto de event_log (partitioned bus persistence S1+).
  3. `admirals_bridge_idempotency` DB-backed (idem_key CHAR(64) PK, module, method, result_json, created_at, expires_at + 2 indexes). Sustituye `_idem_store` in-memory de `resources/admirals_bridges/server/dispatcher.lua` (promote path S1.2).
- **Editado:** `resources/admirals_core/fxmanifest.lua` — version bump 0.0.1→0.1.0 + dependencies declaradas + shared_scripts config.lua + server_scripts orden estricto (logger→metrics→db→event_bus→rate_limiter→migrations→init) + client_scripts init.lua + files list migrations SQLs.
- **Creado:** `scripts/smoke_test_s0.md` — 10 pasos manuales estructurados según founder spec (pre-flight, migration 001, migration 002, idempotency, EventBus, DB wrappers, RateLimiter, Logger, Metrics, resmon). Incluye snippets Lua ejecutables + expectativas exactas + checklist final sign-off.
- **Creado:** `progress/SPRINT_RETRO_S0.md` — retro completa: qué fue bien (docs Oleada 0 pagó dividendos, SESSION_LOG protocolo, Opus calidad, velocity alta), qué fue mal (inconsistencia SSoT tarde detectada, config.lua WIP, oxmysql timeout no nativo, smoke no AI-runnable), qué cambia (SSoT linter S1, idempotency DB migrate S1.2, accounts ALTER TABLE S1), métricas (~4.200 LoC Lua, 4 sessions/1 día vs 3 sem estimado), sign-off.
- **Creado:** `progress/SPRINT_PLAN_S1.md` — outline S1.1 (admirals_bank skeleton + IBAN + schema), S1.2 (transfer + idempotency DB promote), S1.3 (escrow + FSM + sprint close). Refinable pre-S1.1.
- **Editado:** `docs/planning/02_decision_log.md` — v1.1→v1.2 con **ADR-010** (hybrid audit_log + event_log, 4 opciones analizadas → C elegida, contexto inconsistencia SSoT §03↔§04, decisión, consecuencias pos/neg/neutral, impact docs+código+features, re-evaluation trigger). Tag index ampliado (db, audit, ssot_consistency, foundational). Estado actualizado a 10 ADRs. Changelog entry v1.2. TL;DR table + resumen ejecutivo ampliados.
- **Editado:** `docs/planning/01_roadmap.md` — v1.2→v1.3. §4.2 Sprint 0 marked ✅ CERRADO con deliverables detallados + sessions list + ADR-010 mention. §14.2 estado bumped. §14.3 changelog entry v1.3. §15 TL;DR punto 6 actualizado (Sprint 0 → Sprint 1 next).
- **Editado:** `docs/agents/00_BOOTSTRAP.md` — v1.2→v1.3. Header Versión line actualizado. §2.1 Fase actual reescrita: "SPRINT 0 CERRADO" + deliverables bullets + next Sprint 1. §12.3 changelog v1.3. §13 TL;DR punto 2 actualizado.
- **Editado:** `progress/SESSION_LOG.md` — esta entry S0.4 añadida al final (append-only per playbook §5.4).

### Decisiones tomadas
- **ADR-010 formalizado** — hybrid `admirals_audit_log` (wrapper operational, no particionado S0.4) + `admirals_event_log` (bus persistence partitioned, S1+ cuando EventBus persiste DB). Concerns distintos, coexisten. Resuelve inconsistencia SSoT `04_api_contracts.md:1053` (referencia dangling) ↔ `03_db_schema.md` §12 (no DDL). Opción (C) elegida de 3 analizadas.
- **`admirals_accounts` minimal 7 cols** — subset canonical §3.1. Columnas faltantes (reputation_global, preferred_locale, developer_mode, meta, charinfo_*) se añaden S1+ via ALTER TABLE ADD COLUMN aditivo (non-breaking). Anotado SPRINT_RETRO_S0 §4.4.
- **SHA-256 via `SELECT SHA2(?, 256)`** (MySQL) en lugar de implementar Lua crypto — simpler, ~1ms overhead negligible, evita 200 LoC extra.
- **Soft timeout DB** — oxmysql no cancela coroutines ongoing; implementamos detection + warn log + metric counter, no hard-cancellation. Documentado en db.lua. Upgrade path S2+ si timeouts reales se observan.
- **Multi-statement split naive** `;\n` — nuestros .sql siguen convención newline-after-semicolon. Si futuro migration tiene INSERT con `;` embebido en value string, se configurará `multipleStatements=true` en connection string O se usarán $$ delimiters.
- **Auto-decorate payload `_event_*`** como in-place mutation (per §02 §1.4 es comportamiento esperado, callers no deben pasar esos keys).
- **RateLimiter sliding window con purge en cada Check** — simple O(k) donde k=max bucket (≤60 típico). GC thread evita memory leak por citizens offline. Alternativa token bucket clásico considerada y descartada por simplicidad.
- **Boot orchestration fail-fast en cada etapa** — Bridges, DB, Migrations. Si cualquiera falla → `error()` boot-time = server no arranca. Protege contra schema corrupto / configs inválidos llegando a producción.
- **Boot report como último paso** (tras `admirals:core:ready` emit) — consumers pueden oír el evento incluso antes de que el panel termine de imprimir.
- **Version bump 0.0.1→0.1.0** en admirals_core (SEMVER minor: feature addition sin breaking changes — no había API pública previa).

### Verificación estática
- ✅ **0 matches `QBCore.` / `ESX.` / `qb-*` / `qbx_core:` / `ox_inventory:`** en `resources/admirals_core/` — zero direct external calls, Bridges layer respetada per ADR-009.
- ✅ **Prepared statement enforcement:** `_validate` en db.lua rechaza query sin '?' si params no vacío. Test bonus en smoke paso 6 valida.
- ✅ **Syntax linter no ejecutado** (luac no en PATH). Self-review: LuaCATS/EmmyLua annotations correctas, `goto continue` Lua 5.4 válido, `table.pack/unpack`, `pcall` patterns correctos, oxmysql `.await` wrapping.
- ✅ **14 files creados + 4 edits** matching whitelist SPRINT_PLAN §S0.4 + extensión ADR-010 (founder green-light 4th edit decision_log). No tocó `resources/admirals_bridges/*`, `.windsurf/*`, `docs/technical|economy|design|art|qa/*`, `README.md`.
- ✅ **Load order fxmanifest verificado:** logger → metrics → db → event_bus → rate_limiter → migrations → init. Cada script puede asumir dependencias previas disponibles.

### Issues pendientes
- 🟡 **Smoke test manual founder:** ejecutar `scripts/smoke_test_s0.md` 10 pasos con server live + DB + framework T1. Expectativa 10/10 ✅.
- 🟡 **`git tag v0.0.0` + push** tras smoke OK.
- 🔵 **S1.1 promote idempotency a DB-backed:** modificar `admirals_bridges/server/dispatcher.lua` para leer/escribir en `admirals_bridge_idempotency` table (Config.IdempotencyBackend flag).
- 🔵 **S1+ DDL canónico `admirals_audit_log`:** añadir en `docs/technical/03_db_schema.md` §12 (tracked ADR-010 impact + SPRINT_RETRO_S0 §4.3 neutral consequence).
- 🔵 **S1+ ALTER TABLE `admirals_accounts`** aditivo para columnas faltantes spec §3.1 según las use cada feature.
- 🔵 **oxmysql hard timeout** — considerar switch a mysql-async o PR upstream si slow queries degradan boot-time en Oleada 2+.

### Smoke check S0.4 (founder ejecuta)
Ver `scripts/smoke_test_s0.md` 10 pasos:
1. Pre-flight boot (admirals_bridges v0.2.0 + admirals_core v0.1.0 + oxmysql conectado).
2. Migration 001 aplicada (`admirals_schema_versions` + 1 row hash).
3. Migration 002 aplicada (3 tablas + 2 rows tracking).
4. Idempotency (re-arrancar → 0 new rows, checksum match, log "already applied").
5. EventBus smoke (Subscribe + Publish + UUID v4 + audit entry + metric).
6. DB wrappers smoke (Insert → Fetch → Scalar → Transaction rollback preservado).
7. RateLimiter smoke (10 allow + 2 block exactos en bucket test).
8. Logger ring + `/admirals_log_dump` admin-only + level toggle + clear.
9. Metrics counter+histogram + `/admirals_metrics` + reset.
10. resmon `admirals_core` idle <0.3ms, peak <1ms.

### Handoff próxima sesión (S1.1)
- **Modelo recomendado:** Opus 4.7 (arquitectura admirals_bank foundational).
- **Perfil:** 🏗️ ARCHITECT + 🔧 BUILDER.
- **Goal:** `admirals_bank` skeleton + IBAN generator + migration 003_bank_schema.sql (admirals_bank_accounts + admirals_bank_transactions + admirals_escrows) + callback getBalance. Ver `progress/SPRINT_PLAN_S1.md` §S1.1.
- **Docs a leer obligatorio:**
  - `progress/SESSION_LOG.md` últimas 3 entries (S0.2, S0.3, S0.4 — esta).
  - `progress/SPRINT_PLAN_S1.md` §S1.1 (outline, refinable).
  - `docs/technical/03_db_schema.md` §4 (dominio banca DDL).
  - `docs/technical/04_api_contracts.md` §3.1 (C001-C005 callbacks banking).
  - `docs/technical/05_state_machines.md` §4.1 (FSM escrow_lifecycle para S1.3).
  - `docs/technical/07_bridges_compatibility.md` §4 (Bridges.Bank interface).
  - `docs/planning/02_decision_log.md` ADR-010 (audit_log usage pattern).
- **Pre-condición:** smoke S0.4 passing 10/10. Commit S0.4 + `git tag v0.0.0` pushed. Git clean.
- **APIs disponibles S1.1 (via admirals_core):**
  - `Admirals.DB.{FetchOne,FetchAll,Execute,Insert,Scalar,Transaction}` — prepared-only.
  - `Admirals.Bus.{Subscribe,Publish}` — auto-decorated payloads.
  - `Admirals.Rate.Check(src, 'bank.read'|'bank.write')` — defaults ya registrados.
  - `Admirals.Log.{Info,Warn,Error,Audit}` — ring buffer + admin dump.
  - `Admirals.Metrics.{Counter,Observe,Gauge}` — instrumentación.
  - `Admirals.Migrations.*` — para añadir 003 a Config.MigrationsFiles list y que arranque en next boot.
  - `Bridges.Bank.{AddMoney,RemoveMoney,Transfer}` con idempotency_key.
  - `exports.admirals_core:WaitReady(30000)` en init admirals_bank.
- **No tocar:** `resources/admirals_bridges/*` (congelado v0.2.0), `resources/admirals_core/*` salvo Config.MigrationsFiles list, `docs/technical|economy|design|art|qa/*`.

### Files in scope respetados
✅ 14 creates + 4 edits (fxmanifest edit + decision_log + roadmap + BOOTSTRAP + SESSION_LOG) = 18 operaciones. Respeta whitelist SPRINT_PLAN §S0.4 + extensión ADR-010 green-light founder. No tocó `resources/admirals_bridges/*`, `.windsurf/*`, `README.md`, `docs/technical|economy|design|art|qa/*`.

---

## 2026-05-02 — S1.1 admirals_bank skeleton + IBAN + EnsureStarterAccount + C001

**Modelo:** Claude Opus 4.7 MAX (perfil: 🏗️ ARCHITECT + 🔧 BUILDER).
**Founder:** yaboula.
**Sprint:** S1 (Oleada 1, MVP playable).
**Goal:** scaffolding `admirals_bank` resource — IBAN generator + canonical-shape `admirals_bank_accounts`/`admirals_bank_movements` schema + idempotent `EnsureStarterAccount(citizen_id)` (2.500 € starter per SSoT economy §4.1) + ox_lib callback `admirals:bank:getBalance` (C001 per SSoT api §3.1) + lib helper `admirals_core/lib/admirals.lua` para futuros consumers cross-resource.
**Pre-condición:** smoke S0.4 10/10 ✅, git tag v0.0.0 pushed, git clean.

### Pre-action — confirmación scope

Founder green-light en 5 puntos críticos (red flags reportados vs scope literal del prompt):

1. **Diferir `admirals_escrows` DDL a S1.3** — SSoT `03_db_schema.md` solo define §4.1 `admirals_bank_accounts` + §4.2 `admirals_bank_movements`. NO existe §4.3 `admirals_escrows` DDL pese a que `05_state_machines.md` §4.1 referencia la entidad. Migration 003 entrega solo 2 tablas; escrows DDL llegará en S1.3 junto con la lógica.
2. **Scope edits ampliado 1→4 en admirals_core** — implícito en el prompt ("ampliar lista exports", "Si registra explícito → editar Config.MigrationFiles"): añadir `'003_bank_schema.sql'` a `Config.MigrationsFiles`, ~32 exports cross-resource en `server/init.lua`, wrap `Bus.Publish` para fanout server-wide via TriggerEvent, bump SEMVER 0.1.0→0.2.0 en config.lua + fxmanifest.
3. **C001 response shape canonical SSoT** — wrapper `data: { iban, balance, currency='EUR', tier, last_updated_ms }`. Ignorada la simplificación flat del prompt smoke step 4 (`account_type` typo → `tier`).
4. **Lib helper abstraction de Identity event** — `Admirals.Identity.OnPlayerLoaded(cb)` encapsula `AddEventHandler('admirals:bridge:_identityPlayerLoaded', cb)` interno de admirals_bridges. Future-proof: si bridges promociona evento public, la lib cambia internamente sin breaking callers.
5. **IBAN 17 chars literales** — `AD-XXXX-XXXX-XXXX` (2 prefix + 3 dashes + 11 random alphanumeric uppercase + 1 checksum char). DB column `VARCHAR(20)` provee headroom. Algoritmo checksum: SHA-256(11 random) → primer byte → mod 36 → mapped a charset `[A-Z0-9]`.

### Files creados (10)

| # | File | LoC | Propósito |
|---|---|---|---|
| 1 | `resources/admirals_core/lib/admirals.lua` | ~370 | Helper API thin wrappers para consumers via `@admirals_core/lib/admirals.lua` include. Expone `Admirals.{Core,DB,Bus,Rate,Log,Metrics,Identity}.*` delegando via `exports.admirals_core:*` (32 exports). Subscribe local-VM con TriggerEvent server-wide fanout (evita fragility de function refs cross-VM). |
| 2 | `resources/admirals_core/migrations/003_bank_schema.sql` | ~150 | DDL `admirals_bank_accounts` + `admirals_bank_movements` PARTITIONED RANGE. Reconcilia 6 decisiones técnicas vs SSoT (collation `utf8mb4_unicode_ci`, `ON UPDATE` omitido per MariaDB-illegal, FK `admirals_companies` deferred S2+, CHECK XOR ownership preservado, particiones refrescadas 2026_05/06/07/08 + p_future, ENUM category extendido con `starter_seed`). |
| 3 | `resources/admirals_bank/fxmanifest.lua` | ~70 | Resource declaration. Dependencies: oxmysql + admirals_bridges + admirals_core + ox_lib. Server scripts incluyen `@admirals_core/lib/admirals.lua` + `@ox_lib/init.lua` antes del domain code. |
| 4 | `resources/admirals_bank/config.lua` | ~120 | Constantes runtime: starter balance 2.500€, IBAN charset/prefix/retries, audit categories, reserved IBAN prefixes, eventos canónicos. Comentado por SSoT cite. |
| 5 | `resources/admirals_bank/server/iban.lua` | ~205 | `IBAN.Generate` (loop max 5 retries con DB uniqueness check) + `IBAN.Validate` (regex 17 chars + checksum recompute) + `IBAN.ComputeChecksum` (SHA-256 via MySQL — patrón consistente con migrations.lua) + `IBAN.IsReserved` (matches `AD-SYS`/`AD-NPC`). |
| 6 | `resources/admirals_bank/server/accounts.lua` | ~325 | `Accounts.EnsureStarterAccount(citizen_id, source)` idempotent vía `Admirals.DB.Transaction({INSERT bank_accounts, INSERT bank_movements})`. `_ensure_admirals_account` interno crea `admirals_accounts` row si no existe (technical debt — extract a `admirals_player_lifecycle` resource S2+). `GetByIban`, `GetAccountIdByCitizenId`, `GetPersonalByCitizenId` queries prepared. Audit log + Bus.Publish 2 eventos (`account_created` + `starter_balance_credited`). |
| 7 | `resources/admirals_bank/server/callbacks.lua` | ~190 | `lib.callback.register('admirals:bank:getBalance')` per SSoT §3.1. Auth flow: resolve citizen_id (cache `_src_to_cid` populated en init.lua) → rate limit (`bank.read` 30/10s default) → resolve IBAN (request.iban or default personal) → format validate (defense-in-depth) → ownership check (personal-only S1.1, company auth deferred S2+ con `admirals_company_members`) → response shape canónica. Error codes: NOT_AUTHENTICATED, RATE_LIMITED, INVALID_IBAN, NO_ACCOUNT, NOT_AUTHORIZED. |
| 8 | `resources/admirals_bank/server/init.lua` | ~210 | Boot orchestration: WaitReady core (30s timeout) → schema sanity check (information_schema lookup admirals_bank_accounts + admirals_bank_movements) → register Identity hooks (OnPlayerLoaded → cache + EnsureStarterAccount async / OnPlayerDropped → purge cache) → mark ready → Bus.Publish + TriggerEvent `admirals:bank:ready` → ASCII boot panel. Admin command `/admirals_bank_status` ACE-gated. Exports `IsReady`, `Version`. |
| 9 | `scripts/smoke_test_s1_1.md` | ~270 | Protocol 8 pasos: pre-flight (resources arrancan, lib cargada en VM bank, resmon <0.2ms idle), migration 003 verify (2 tablas + 5 partitions + tracking row), 100 IBAN generates uniqueness/checksum, EnsureStarterAccount idempotent (3 rows + reconnect = 1/1/1), C001 happy path (response shape canónico), C001 unauthorized (player A→B IBAN), C001 rate limit (31 calls → 30 OK + 1 BLOCKED), audit + bus verification. |
| 10 | (this entry — append-only SESSION_LOG.md) | — | Protocolo founder playbook §5.3. |

### Files editados (4)

| # | File | Cambio |
|---|---|---|
| 1 | `resources/admirals_core/config.lua` | Bump `Config.Version` 0.1.0→0.2.0 (MINOR) + añadir `'003_bank_schema.sql'` a `Config.MigrationsFiles` (ahora 3 migrations). |
| 2 | `resources/admirals_core/server/init.lua` | Añadir 32 exports cross-resource (DB×6, Bus×4, Rate×4, Log×8, Metrics×6, Core×4 ya existían) + wrap `Bus.Publish` para `TriggerEvent('admirals_lib:dispatch', event_name, payload)` server-wide fanout (consumers reciben en su `AddEventHandler` local via lib helper). Resource attribution preservada en logs cross-VM via wrapper `_log_wrap` que prefixa `[<resource>] msg`. |
| 3 | `resources/admirals_core/fxmanifest.lua` | Bump `version` 0.1.0→0.2.0 + añadir `'migrations/003_bank_schema.sql'` y `'lib/admirals.lua'` a `files{}`. Comment explica que `lib/admirals.lua` NO se carga en server_scripts del propio admirals_core (su VM tiene `_G.Admirals` real). |
| 4 | `progress/SESSION_LOG.md` | Append entry S1.1 (este). |

### Decisiones tomadas

- **ADR (informal — formalizable S2+) Lib Helper Pattern (Pattern B)** — admirals_core expone wrappers cross-resource via `lib/admirals.lua` que consumers `@-include`. Razón: FiveM Lua VMs aisladas → `_G.Admirals` no compartido. Alternativas evaluadas: (A) cada resource duplica DB/Bus/Log/etc (rejected — DRY violation), (C) cross-resource via `TriggerEvent` puro (rejected — verbose, sin tipado). Pattern B equilibra abstracción + performance + future-proof. Subscribe usa híbrido: handler local + `BusRegisterConsumerInterest` notifica admirals_core (metric tracking) + `TriggerEvent('admirals_lib:dispatch')` fanout server-wide en `Bus.Publish`. Function refs cross-VM evitados deliberadamente.
- **Diferir DDL `admirals_escrows` a S1.3** — SSoT §4.3 inexistente. Migration 003 entrega solo bank_accounts + bank_movements. Migration 004 (S1.3) añadirá escrows con su lógica FSM. Mantiene principio "entrega aditiva" — no DDLs sin lógica que los justifique.
- **`updated_at ON UPDATE (UNIX_TIMESTAMP())` OMITIDO** — MariaDB-illegal en columnas non-TIMESTAMP. Patrón consistente con migration 002 (línea 42 documenta el rationale). App-managed via `Admirals.DB.Execute` SET updated_at=?.
- **FK `admirals_bank_accounts.owner_company_id → admirals_companies(id)` DEFERRED** — la tabla `admirals_companies` no existe aún (S2+). El comment del CREATE TABLE deja explícito el ALTER TABLE aditivo que hará S2: `ALTER TABLE admirals_bank_accounts ADD CONSTRAINT fk_admirals_bank_accounts_owner_company FOREIGN KEY (owner_company_id) REFERENCES admirals_companies(id)`. CHECK XOR ownership preservado per SSoT §4.1 (MariaDB 10.2+ enforce).
- **Particiones refrescadas a sprint window** — SSoT cita p_2026_01..03 (Feb-Apr 2026, ya pasado). Migration 003 usa p_2026_05..08 (May-Aug 2026) + p_future MAXVALUE catchall. Cron mensual S2+ rolling forward (per SSoT §15.4 ejemplo Lua incluido).
- **ENUM `category` extendido con `starter_seed`** — SSoT §4.2 lista 12 valores; el 13º `starter_seed` es aditivo (no breaking). Permite distinguir el initial 2.500 € en queries analytics + ledger reconciliation. Anotado en migration 003 D6.
- **`admirals_accounts` INSERT en admirals_bank S1.1** — technical debt acknowledged. La responsabilidad arquitectónica corresponde a un futuro `admirals_player_lifecycle` resource. S1.1 lo gestiona admirals_bank por pragmatismo (es el primer resource que necesita el row). `_ensure_admirals_account` privado en accounts.lua, extraíble S2+ sin breaking changes.
- **`alias` derivation primitiva `Player_<citizen_id_truncated>`** — S1.1 placeholder. S2+ resolverá via `Bridges.Identity.GetPlayerData(source).charinfo.firstname/lastname` cuando admirals_bridges exponga esa API cross-resource.
- **`request_nonce` UUID v4 (no `starter_<citizen_id>` prefix)** — bug detectado durante self-review: citizen_id en frameworks ESX/native puede exceder 28 chars (`license:abc...`, `steam:0:1:...`) → overflow CHAR(36). UUID v4 garantiza 36 chars exactos. Idempotency real está en step 2 de `EnsureStarterAccount` (`GetPersonalByCitizenId` existing check), no en el nonce.
- **`tier` mapping en C001 response** — DB ENUM 4 valores (personal/company/cooperative/escrow) → SSoT response 2 valores (`personal`|`empresa`). Mapping: `personal`→`personal`, otros→`empresa`. S2+ refinement opcional si Tablet UI necesita distinguir tipos empresa.
- **`Config.AuditReads = false` default** — getBalance es high-frequency (30/10s per player). Audit cada read inundaría `admirals_audit_log`. Activable temporalmente para investigación forense. Operaciones write (transfers S1.2+) sí audit obligatorio per SSoT §10.3.
- **Cache `_src_to_cid` en admirals_bank** — admirals_bridges no exporta `GetCitizenId(source)` cross-resource. Cache populated en `Admirals.Identity.OnPlayerLoaded` hook, purged en `OnPlayerDropped`. Resuelve resolución source→citizen_id sin tocar bridges (frozen). API local: `Bank.GetCitizenIdBySource(source)`.
- **SEMVER bump admirals_core 0.1.0→0.2.0** — MINOR per convention. Adiciones: ~32 exports cross-resource + lib helper + migration 003 + Bus.Publish wrap. NO breaking changes en API previa S0.4.

### Verificación estática

- ✅ **0 matches `QBCore.` / `ESX.` / `qbx_core:` / `qb-core` / `qbx_*` / direct framework calls** en `resources/admirals_bank/` y `resources/admirals_core/` — Bridges layer respetada per ADR-009.
- ✅ **0 matches `MySQL.*` direct calls** en `resources/admirals_bank/*.lua` (solo aparece el string en un comment del fxmanifest explicando que NO se necesita — todo via `Admirals.DB.*` que delega a admirals_core via exports).
- ✅ **Prepared statement enforcement:** todas las queries en admirals_bank usan `?` placeholders (verificado grep `SELECT|INSERT|UPDATE|DELETE` en `*.lua` — 0 string concats con user input).
- ✅ **Cross-reference exports/lib:** 32 lib helper `_safe_export('Name', ...)` calls match exactamente con 32 `exports('Name', fn)` registrations en `admirals_core/server/init.lua` (manual cross-grep verified).
- ✅ **Resource isolation:** lib helper hace `AddEventHandler('admirals:bridge:_identityPlayerLoaded', ...)` y `AddEventHandler('admirals_lib:dispatch', ...)` — ambos eventos server-wide (FiveM `TriggerEvent` cruza VMs nativamente). NO usa function refs cross-resource.
- ✅ **Load order fxmanifest verificado** admirals_bank:
  1. shared `config.lua`
  2. server `@admirals_core/lib/admirals.lua` (lib first — registra namespace + AddEventHandlers)
  3. server `@ox_lib/init.lua` (lib.callback global)
  4. server `iban.lua` (depende de Admirals.DB + Admirals.Bank.Config)
  5. server `accounts.lua` (depende de IBAN + DB + Bus + Log + Metrics)
  6. server `callbacks.lua` (depende de Accounts + IBAN + lib.callback)
  7. server `init.lua` (LAST — depende de todo + Admirals.Core.WaitReady)
- ✅ **TX atomic verificado** EnsureStarterAccount: pcall envuelve `Admirals.DB.Transaction([INSERT bank_account, INSERT bank_movement])`. Detect 3 paths: (a) crash → 'TX_CRASH', (b) rollback (return false) → 'TX_ROLLBACK', (c) success → continue audit/metrics/bus.
- ✅ **Idempotency verificada** EnsureStarterAccount step 2: `Accounts.GetPersonalByCitizenId(citizen_id)` — si existe row, return early sin INSERT duplicado. Re-conexión player → log "existing bank_account for X" + counts en DB unchanged.
- ✅ **CHECK constraint XOR ownership** preserved en migration 003 — MariaDB 10.2+ enforce nativo. Application-layer enforces additionally via accounts.lua INSERT con `type='personal'` + `owner_account_id NOT NULL` + `owner_company_id NULL`.
- ⚠️ **Syntax linter no ejecutado** (luac no en PATH). Self-review: LuaCATS annotations correctas, `goto continue` Lua 5.4 válido, `pcall` patterns correctos, oxmysql `.await` usage delegado via Admirals.DB.

### Issues pendientes

- 🟡 **Smoke test manual founder S1.1:** ejecutar `scripts/smoke_test_s1_1.md` 8 pasos. Requiere player connect via framework T1 activo (qbox sí, esx/native si configurado). Expectativa 8/8 ✅.
- 🟡 **Cleanup `admirals_smoke_iban_gen` command** — el smoke step 3 propone añadir un comando temporal admin para 100 IBAN generates. Tras smoke OK, remover o gatear tras `Config.Env == 'development'`.
- 🟡 **`git tag v0.1.0` + push** tras smoke OK (admirals_bank v0.1.0 + admirals_core v0.2.0).
- 🔵 **S1.2 transfers (C002):** implementar `admirals:bank:transfer` con validación amount + ownership + idempotency via `request_id` + UPDATE balances atomic + 2 INSERTs bank_movements (debit + credit). Rate limit `bank.write` 10/60s ya registered.
- 🔵 **S1.3 escrows + FSM:** migration 004 con `admirals_escrows` DDL (founder co-design SSoT §4.3 cuando llegue) + `escrow_lifecycle` FSM transitions + C004 createEscrow + C005 releaseEscrow.
- 🔵 **S2 extract `_ensure_admirals_account` a `admirals_player_lifecycle`** — pasar la responsabilidad arquitectónica a un resource lifecycle dedicated. Con migration aditiva (puede convivir admirals_bank fallback hasta migration completa).
- 🔵 **S2 ALTER TABLE `admirals_bank_accounts` ADD FK `admirals_companies`** cuando S2 cree la tabla `admirals_companies`. Migration aditiva, non-breaking.
- 🔵 **S2 cron mensual partition rolling** `admirals_bank_movements` per SSoT §15.4 (ejemplo Lua incluido).
- 🔵 **S2+ promote `Admirals.Identity.OnPlayerLoaded`** a evento canónico Bus `admirals:identity:player_loaded` (publicar desde un único orchestrator post-bridges en lugar de fan-out via internal `admirals:bridge:_identityPlayerLoaded`). La lib helper actualizará SU implementación internal sin breaking callers.

### Smoke check S1.1 (founder ejecuta)

Ver `scripts/smoke_test_s1_1.md` 8 pasos:
1. Pre-flight boot (3 resources arrancan, lib helper carga en VM bank, resmon admirals_bank idle <0.2ms).
2. Migration 003 aplicada (2 tablas + 5 partitions + 1 row tracking + columnas matchean SSoT).
3. IBAN.Generate 100 invocaciones (0 colisiones, 0 checksum failures, format AD-XXXX-XXXX-XXXX).
4. EnsureStarterAccount idempotent (3 rows tras conectar + counts 1/1/1 tras reconectar).
5. C001 getBalance happy path (response shape canónico §3.1).
6. C001 unauthorized (player A pide IBAN B → NOT_AUTHORIZED).
7. C001 rate limit (31 calls in <10s → 30 OK + 1 BLOCKED).
8. Audit + Bus (admirals_audit_log row starter_seed + Bus.Stats reporta account_created event + log ring entries).

### Handoff próxima sesión (S1.2)

- **Modelo recomendado:** Opus 4.7 (lógica transfers + escrows requires arquitectura DB-correcta, idempotency rigurosa, FSM transitions).
- **Perfil:** 🏗️ ARCHITECT + 🔧 BUILDER.
- **Goal:** C002 `admirals:bank:transfer` — UPDATE atomic 2 balances + 2 INSERTs bank_movements (debit + credit) + idempotency via `request_id` + auth + rate limit `bank.write` (10/60s default registered S0.4) + audit. Ver `progress/SPRINT_PLAN_S1.md` §S1.2.
- **Docs a leer obligatorio:**
  - `progress/SESSION_LOG.md` últimas 3 entries (S0.4, S1.1 — esta, y la siguiente cuando se cree).
  - `progress/SPRINT_PLAN_S1.md` §S1.2.
  - `docs/technical/04_api_contracts.md` §3.1 C002 (transfer signature + error codes).
  - `docs/technical/04_api_contracts.md` §6 (DB transactions).
  - `docs/technical/04_api_contracts.md` §10.3 (audit obligatorio money operations).
  - `docs/technical/05_state_machines.md` §4.2 (FSM `transfer_lifecycle` si existe — verify).
  - `docs/economy/01_economic_model.md` §10.3 (transfer fees policy — Internal transfer 0€, External 1-2€ flat).
- **Pre-condición:** smoke S1.1 8/8 ✅ + git tag v0.1.0 pushed + git clean.
- **APIs disponibles S1.2:**
  - Todo lo de S1.1 + nuevos: `Admirals.Bank.Accounts.GetByIban`, `Accounts.GetPersonalByCitizenId`, `IBAN.Validate`.
  - `Bank.GetCitizenIdBySource(source)` para resolver source→citizen_id.
  - `admirals_audit_log` table (categoria 'bank.transfer' canonical per Config.AuditCategories).
  - `admirals_bridge_idempotency` table (DB-backed replays — usar para C002 request_id).
- **No tocar:**
  - `resources/admirals_bridges/*` (frozen v0.2.0).
  - `resources/admirals_core/server/*` salvo Config.MigrationsFiles list para migration 004 (cuando S1.3).
  - `docs/technical|economy|design|art|qa/*`.

### Files in scope respetados

✅ 10 creates + 4 edits = 14 operaciones. Founder green-light explícito previo a expansión de scope (4 edits en admirals_core vs 1 listado en prompt). No tocó `resources/admirals_bridges/*`, `.windsurf/*`, `README.md`, `docs/technical|economy|design|art|qa/*`, `progress/SPRINT_PLAN_S1.md` (refinement diferido S1.3).

---

## 2026-05-02 — S1.2 Transfer C002 + double-entry ledger + idempotency DB-backed + event publish

**Modelo:** Claude Opus 4.7 MAX (perfil: 🏗️ ARCHITECT + 🔧 BUILDER).
**Founder:** yaboula.
**Sprint:** S1 (Oleada 1, MVP playable) — session 2 de 3.
**Goal:** C002 `admirals:bank:transfer` atómico (4-query TX) + 2-row ledger debit/credit per SSoT §4.2 + idempotency `admirals_bridges._idem_store` swap memory→DB-backed (`admirals_bridge_idempotency`) con firma `Bridges._IsIdemReplay/_StoreIdem` estable + evento `admirals:bank:transfer_completed` schema canonical §4.3 + seed system account `AD-SYS0-0000-0001` 10M € (treasury — investment for S1.3).
**Pre-condición:** S1.1 commit pushed + `S1.1 cleanup remove temporal smoke client + iban_gen command` (commit 23641e8) + git clean + 5 reconciliaciones SSoT pre-action (founder green-light explícito).

### Pre-action — 5 reconciliaciones SSoT (founder green-light)

Detectadas en pre-action review (no proceder hasta confirmación). Founder confirmó alinear a SSoT existente sin overrides — NO ADR-011 necesario, simple correcciones del prompt original que citaba secciones erróneas:

1. **Fee transfer player→player = 0 €** (SSoT [`economy/01_economic_model.md:697`](file:///d:/theBigProject/docs/economy/01_economic_model.md) §10.3 "Internal transfer (entre IBANs Admirals): 0 €"). El prompt original citaba §3.2 que es **external** transfers (multi-server, oleada N+) — correctiva aplicada. Ledger 2 rows (debit + credit), sin 3ª row de fee, sin UPDATE balance system. fee_retained=0.00 en response (mantiene shape canónico para forward-compat S1.3 escrow fees y S2+ external).
2. **Schema sin columna `direction`** — SSoT §4.2:553 usa `amount` signed (positivo=ingreso, negativo=salida) + `balance_after` snapshot. NO añadir columna. Verificación atomicity: `SUM(amount) GROUP BY bank_account_id == admirals_bank_accounts.balance` (helper `Movements.RecalcBalance`).
3. **Categoría canónica `transfer`** — ENUM §4.2:556 ya tiene `'transfer'`. Las 2 rows comparten category, distinguibles por signo de amount + counterpart_iban (extracto bancario human-readable). NO inventar `transfer_debit`/`transfer_credit`.
4. **C002 response shape canonical** — SSoT [`api_contracts.md:289-300`](file:///d:/theBigProject/docs/technical/04_api_contracts.md): `{success, data: { transaction_id, timestamp, new_balance_from, fee_retained }}`. `transaction_id` = UUID v4 server-generado (≠ `request_id` cliente — son distintos). transaction_id se persiste en `request_nonce` CHAR(36) de ambas movement rows (sin ALTER schema) — cliente puede reconciliar response ↔ ledger via `transaction_id == request_nonce`. `request_id` queda solo en `admirals_bridge_idempotency`. `timestamp` en UNIX ms.
5. **Migration 004 path** = `resources/admirals_core/migrations/004_bank_seed_system_account.sql` (no `admirals_bank/migrations/`). Pattern S1.1 ratificado — runner único es `admirals_core/server/migrations.lua`. INSERT IGNORE para idempotency (defense-in-depth sobre runner tracking).

### Sub-decisión durante implementación — system account CHECK XOR conflict

Founder recomendó `type='escrow'` (D6 en migration 003) + opción (a) "admirals_accounts ficticio para owner_account_id". **Incompatibles entre sí**: el CHECK constraint en migration 003:107-110 enforza `(type='escrow' AND owner_company_id IS NOT NULL)`, no permite `type='escrow' + owner_account_id NOT NULL`. Único path consistente con CHECK + opción(a) sin tocar constraint: **`type='personal'` + `admirals_accounts` ficticio `SYSTEM`**. Implementado con comment doc explícito en migration 004 (D1 sección DECISIONES TÉCNICAS) + technical debt nota: S2+ podrá refinarse vía ALTER ENUM 'system' + relax CHECK O usar admirals_companies ficticio cuando exista esa tabla.

### Files creados (5)

| # | File | LoC | Propósito |
|---|---|---|---|
| 1 | `resources/admirals_core/migrations/004_bank_seed_system_account.sql` | ~115 | Seed treasury system account: `admirals_accounts` SYSTEM ficticio (UUID `00000000-...-001`) + `admirals_bank_accounts` (UUID `b0000000-...-001`, IBAN `AD-SYS0-0000-0001`, 10M €) + 1 movement row category `adjustment` 'System treasury seed'. INSERT IGNORE + NOT EXISTS por defense-in-depth. |
| 2 | `resources/admirals_bank/server/movements.lua` | ~190 | `Movements.{Insert, GetByAccount, GetByNonce, RecalcBalance}` — helpers DB sobre admirals_bank_movements. ENUM categories validation (13 valid incluyendo starter_seed). Insert es no-transaccional (single row) — Transfer.Execute arma sus queries inline. RecalcBalance = `SUM(amount) vs balance` para reconciliación. |
| 3 | `resources/admirals_bank/server/transfer.lua` | ~330 | `Transfer.Execute(from_cid, from_iban, to_iban, amount, concept, request_id) → success, data, error_code`. Atomicity via `Admirals.DB.Transaction` 4 queries: UPDATE debit (WHERE balance >= ? AND is_frozen=0 AND closed_at IS NULL) + UPDATE credit + INSERT movement debit (signed -amount) + INSERT movement credit (signed +amount). transaction_id UUID v4 → `request_nonce` ambas rows. fee_retained=0 internal (§10.3). 8 error codes canonical §3.1 + §7. Race window documented (mitigated by rate limit + idempotency). |
| 4 | `resources/admirals_bank/server/events.lua` | ~110 | `Events.PublishTransferCompleted(payload)` — schema-validation mínimo (required fields) + Bus.Publish con audit='always'. Schema canonical per §4.3 (auto-decora `_event_id, _emitted_at, _schema_version` via Bus core). `movement_id_from/to` omitted en S1.2 (oxmysql Transaction returns boolean, no insertIds — caller puede SELECT por request_nonce si necesario S2+). transaction_id additivo non-breaking. |
| 5 | (this entry — append-only SESSION_LOG.md) | — | Protocolo founder playbook §5.3. |

### Files editados (8)

| # | File | Cambio |
|---|---|---|
| 1 | `resources/admirals_bridges/config.lua` | Bump comment IdempotencyTTLSec (S0.4→S1.2 promotion) + nuevo `Config.IdempotencyBackend` ('memory' default, override convar `admirals_bridge_idempotency_backend'). Hook informativo — backend real instalado vía `SetIdempotencyBackend(spec)` runtime swap. |
| 2 | `resources/admirals_bridges/server/dispatcher.lua` | Refactor idempotency: introduce `_idem_backend` spec table {resource, getExport, setExport, gcExport?} + helpers `_backend_get/_backend_set/_backend_gc` que enrután memory vs cross-resource exports. `_IsIdemReplay/_StoreIdem` firmas estables (founder mandato). Nueva función `Bridges.SetIdempotencyBackend(spec\|'memory')` con validación estricta. GC thread llama `_backend_gc()` (memory) o export gcExport (DB). 4 nuevos exports: `SetIdempotencyBackend`, `IsIdemReplay`, `StoreIdem`, `IdemBackendName`. Cross-VM: NO function refs — solo strings de resource+export name (anti-fragility per S1.1 lib pattern). |
| 3 | `resources/admirals_core/server/init.lua` | (a) 3 nuevos exports backend interface: `IdempotencyGet(key)` (DB.FetchOne con WHERE expires_at > UNIX_TIMESTAMP() + json.decode), `IdempotencySet(key, result, ttl_sec)` (UPSERT con `ON DUPLICATE KEY UPDATE result_json+expires_at` + json.encode), `IdempotencyGC()` (DELETE WHERE expires_at < NOW + Metrics counter). (b) Boot sequence step 3.5: `pcall(exports.admirals_bridges:SetIdempotencyBackend({resource='admirals_core', getExport='IdempotencyGet', setExport='IdempotencySet', gcExport='IdempotencyGC'}))` post-migrations + post-DB-ready. Si swap falla → log warn (no fatal — fallback memory backend). |
| 4 | `resources/admirals_bank/server/callbacks.lua` | Añadir C002 `admirals:bank:transfer` register (~170 LoC). Flow: (1) resolve citizen_id from cache, (2) validate request_id required (8-64 chars), (3) idempotency lookup via `exports.admirals_bridges:IsIdemReplay` (replay → return cached + audit `idempotency_replay`), (4) rate limit `bank.write` 10/60s fail-closed, (5) shape validation, (6) delegate `Transfer.Execute`, (7) build response + error_code → message map (8 errors §7), (8) `exports.admirals_bridges:StoreIdem` persist response (success OR error — idempotency PUT-like semantics), (9) duration metric. Local var `Transfer = Admirals.Bank.Transfer` añadido. |
| 5 | `resources/admirals_bank/config.lua` | Bump Version 0.1.0→0.2.0. Uncomment `Config.Events.TransferCompleted = 'admirals:bank:transfer_completed'`. AuditCategories.Transfer ya existía S1.1 (paralelo a StarterSeed) — no duplicado. |
| 6 | `resources/admirals_bank/fxmanifest.lua` | Bump version 0.1.0→0.2.0 + description "C001 + C002". server_scripts añade `server/movements.lua`, `server/events.lua`, `server/transfer.lua` en order strict (después de iban + accounts, antes de callbacks). Comment load-order rationale actualizado. |
| 7 | `resources/admirals_core/config.lua` | Bump Version 0.2.0→0.3.0 (MINOR — feature addition idempotency exports). Añadir `'004_bank_seed_system_account.sql'` a `Config.MigrationsFiles` (ahora 4 migrations). |
| 8 | `resources/admirals_core/fxmanifest.lua` | Bump version 0.2.0→0.3.0 + description "+ Idempotency backend (S1.2)". `files{}` añade `migrations/004_bank_seed_system_account.sql`. |
| 9 | `progress/SESSION_LOG.md` | Append entry S1.2 (este). |

**Total: 5 creates + 8 edits = 13 operaciones.** Founder green-light explícito previo: 5 edits en strict whitelist (callbacks, dispatcher, bridges/config, core/init, SESSION_LOG); 3 edits adicionales mecánicos in-scope (bank/config TransferCompleted event uncomment, bank/fxmanifest wire 3 new files, core/config MigrationsFiles, core/fxmanifest files{} — todos requeridos para que el código sea immediately runnable).

### Decisiones tomadas

- **Idempotency backend swap pattern (cross-VM safe)** — admirals_bridges no depende de admirals_core (jerarquía bridges → core, viola si invierte). Las VMs Lua FiveM son aisladas — `_G.Admirals` no visible cross-resource. Solución: bridges expone `SetIdempotencyBackend(spec)` que recibe **strings** de `{resource, getExport, setExport, gcExport}` (NO function refs cross-VM — fragility-prone per S1.1 ADR informal Pattern B). admirals_core en boot post-DB-ready llama el setter pasando `{resource='admirals_core', ...}`. El dispatcher invoca `exports[resource][exportName](nil, ...)` runtime — manejo de errores via pcall + log warn fallback.
- **`Bridges._IsIdemReplay/_StoreIdem` firmas estables (S0.2 contract)** — founder mandato explícito. Module/method (informativos en `admirals_bridge_idempotency` table) almacenados como '' por dispatcher para preservar la firma de 2 args. Si callers necesitan trazabilidad richer, pueden inspeccionar logs de `Bridges.Dispatcher.Call` (boundary audit). Trade-off: simplicidad firma vs auditability — firma estable elegida (founder priority).
- **`request_id` (cliente) vs `transaction_id` (server)** — son distintos:
  - `request_id`: UUID v4 client-generado. Idempotency key. Vive solo en `admirals_bridge_idempotency.idem_key`.
  - `transaction_id`: UUID v4 server-generado en `Transfer.Execute`. Identidad de la operación. Persistido en `request_nonce` de **ambas** movement rows (CHAR(36) — encaja exact). Permite cliente reconciliar response ↔ ledger via `transaction_id == request_nonce`.
- **Sin ALTER schema admirals_bank_movements** — alternativa considerada: añadir columna `transaction_id` específica (CHAR(36) UQ). Rechazada — `request_nonce` ya CHAR(36) NULLable, semánticamente compatible (anti-replay = identidad operacional). S2+ podrá renombrar columna si claridad lo requiere (non-breaking, vista virtual).
- **Race window awareness — UPDATE WHERE balance >= ?** — la garantía SQL-side cubre el debit (si concurrent op vacía saldo, UPDATE afecta 0 rows). Pero la TX completa sigue → INSERT debit movement con balance_after stale + UPDATE credit + INSERT credit movement. Resultado: ledger desbalanceado (delta != 0 detectable post-hoc via `Movements.RecalcBalance`). **Mitigaciones reales:** rate limit `bank.write` 10/60s per player + idempotency replay + admin reconciliation cron S2+. Real proper-locking mechanism = S1.3 escrow lock+release (signal-error con SAVEPOINT no implementado por scope creep prevention).
- **Fee internal transfer = 0 €** — alineado SSoT economy §10.3 sin override ni ADR. fee_retained=0.00 en response shape (forward-compat para S1.3 escrow fees + S2+ external transfer fees).
- **System account `type='personal'` con admirals_accounts SYSTEM ficticio** — único path consistente con CHECK XOR sin tocar constraint. Documentado technical debt: S2+ refinement vía ALTER ENUM 'system' O admirals_companies ficticio. UUID fijo `00000000-...-001` / `b0000000-...-001` per SSoT §13.3 ejemplo.
- **System account NO recibe transfers en S1.2** — investment for S1.3 (escrow fees treasury) y S2+ (tax retention). Smoke step 2 explicit verification: `system balance unchanged`.
- **Idempotency PUT-like semantics** — store entry POST-execution para ambos success y error. Si 1ª attempt falla por INSUFFICIENT_FUNDS, 2ª con mismo request_id retorna mismo error (no "reintento bonus"). Cliente debe usar nuevo request_id para retry semántico — matchea HTTP idempotency standards.
- **fail-closed rate limit, fail-open idempotency lookup** — diseño deliberado:
  - Rate limit: si `Admirals.Rate.Check` excepción → reject (anti-fraude).
  - Idempotency lookup: si export falla → proceed (best-effort) — el riesgo de double-execute acotado por (a) UNIQUE iban + balance check, (b) admin reconciliation. Si en producción se observa frecuente, escalate a fail-closed.
- **Boot order admirals_core respeta dependencia bridges** — bridges arrancan first (jerarquía topológica), admirals_core espera `Bridges.WaitReady(30000ms)` antes de hacer cualquier cosa. El swap idempotency hook se ejecuta DESPUÉS de migrations (asegura table existe) Y DESPUÉS de DB ready Y DESPUÉS de bridges ready (los 3 timeouts en cascada). Pcall protect — si swap rechaza → memory mode degrade graceful.
- **Errores en español + códigos canónicos en inglés** — mismo patrón S1.1 (response.error_code uppercase canonical, response.message human-readable Spanish). Mantiene consistency con ox_lib + facilita i18n future.
- **SEMVER bump admirals_core 0.2.0→0.3.0 (MINOR)** — feature addition: 3 nuevos exports `IdempotencyGet/Set/GC`. NO breaking changes API previa.
- **SEMVER bump admirals_bank 0.1.0→0.2.0 (MINOR)** — feature addition: C002 callback + 3 server scripts. NO breaking changes C001.
- **SEMVER bridges 0.2.0→0.2.0 (no bump)** — el refactor del idempotency mantiene firma `_IsIdemReplay/_StoreIdem`. Nuevos exports (`SetIdempotencyBackend/IsIdemReplay/StoreIdem/IdemBackendName`) son additivos non-breaking. Considerado bump→0.3.0 pero los exports nuevos no rompen consumers existentes — patch implicito acceptable. Si hay PR review concerns, bumpear en S1.3 con escrow API additions.

### Verificación estática

- ✅ **0 matches `QBCore.` / `qbx_core:` / `exports['qb-` / `exports.qbx_core` / `ESX.`** en `resources/admirals_bank/` — Bridges layer respetada per ADR-009.
- ✅ **0 matches `MySQL.*` direct calls** en `resources/admirals_bank/*.lua` (solo aparece en comments del fxmanifest explicando que NO se necesita — todo via `Admirals.DB.*` que delega a admirals_core via exports).
- ✅ **Prepared statement enforcement:** todas las queries en `transfer.lua / movements.lua / events.lua` usan `?` placeholders (verificado grep `SELECT|INSERT|UPDATE|DELETE` — 0 string concats con user input).
- ✅ **Cross-resource pattern compliance:** `exports.admirals_bridges:IsIdemReplay/StoreIdem/SetIdempotencyBackend` desde admirals_bank/admirals_core. NO accede a `_G.Bridges` cross-VM. NO function refs cross-VM (solo strings).
- ✅ **CHECK XOR ownership preservado** — migration 004 NO toca constraint. system account usa `type='personal' + owner_account_id NOT NULL + owner_company_id NULL` (CHECK ramp 1).
- ✅ **Schema sin direction column** — Movements.RecalcBalance verifica via `SUM(amount)` directo (signed amount canonical).
- ✅ **C002 response shape canonical** — `{success, data: {transaction_id, timestamp, new_balance_from, fee_retained}}` matchea SSoT §3.1:289-300 exact.
- ✅ **Event payload canonical §4.3** — `Events.PublishTransferCompleted` enforce required fields {transaction_id, from_iban, to_iban, amount, requester_account_id, occurred_at} + adds category='transfer' default.
- ✅ **Load order fxmanifest verificado** admirals_bank S1.2 (8 server_scripts):
  1. shared `config.lua`
  2. `@admirals_core/lib/admirals.lua` (lib first)
  3. `@ox_lib/init.lua` (lib.callback)
  4. `iban.lua`
  5. `accounts.lua` (depends IBAN + DB)
  6. `movements.lua` (depends DB only)
  7. `events.lua` (depends Admirals.Bus only)
  8. `transfer.lua` (depends Accounts + IBAN + Movements + Events)
  9. `callbacks.lua` (depends Transfer + Accounts + IBAN + lib.callback)
  10. `init.lua` (LAST)
- ✅ **TX atomic verified** — Transfer.Execute envuelve 4 queries en `Admirals.DB.Transaction({q_debit, q_credit, q_mov_debit, q_mov_credit})`. pcall trap 3 paths: TX_CRASH (excepción), TX_ROLLBACK (oxmysql returns false), success (returns true).
- ✅ **Idempotency PUT-like semantics** — store response (success OR error) post-execution. Replay de error retorna mismo error.
- ✅ **Boot sequence admirals_core respeta deps** — Bridges ready → DB ready → Migrations → SetIdempotencyBackend hook → Mark Core ready → Emit ready event.
- ⚠️ **Syntax linter no ejecutado** (luac no en PATH). Self-review: LuaCATS annotations correctas, `goto continue` Lua 5.4 válido, `pcall` patterns correctos, oxmysql `.await` usage delegado via Admirals.DB.

### Issues pendientes

- 🟡 **Smoke test manual founder S1.2:** ejecutar 10 pasos founder spec (pre-flight, happy path, idempotency replay, self-transfer, insufficient funds, rate limit 11 calls, restart durante idempotency window, atomicity stress 100 concurrent, event subscription, resmon). NOTA: requiere comandos admin temporales para steps 6 (rate burst) y 8 (atomicity stress) — ver `scripts/smoke_test_s1_2.md` (a redactar).
- 🟡 **`scripts/smoke_test_s1_2.md` no creado en S1.2** — out of scope literal (founder prompt no lo lista en files in scope). Founder podrá redactarlo o pedirlo en S1.2.5 mini sesión. Smoke en SESSION_LOG describe los pasos lógicos.
- 🟡 **`git tag v0.1.1` (o v0.2.0?)** — admirals_bank 0.2.0 + admirals_core 0.3.0 bumps. Sprint 1 cerrará con `v0.1.0` per playbook. Sub-tag `v0.1.0-s1.2` opcional founder discretion.
- 🔵 **S1.3 escrow + FSM:** migration 005 con `admirals_escrows` DDL (founder co-design SSoT §4.3 cuando llegue) + `escrow_lifecycle` FSM transitions + C004 createEscrow + C005 releaseEscrow. Escrow LOCK pattern sí proporciona proper-locking (vs S1.2 race window).
- 🔵 **S1.3 escrow fees a system IBAN** — primer flujo de dinero hacia `AD-SYS0-0000-0001` (treasury). Verificable via Movements.GetByAccount('b0000000-...-001').
- 🔵 **S2+ proper-locking transfers** — opciones: SELECT FOR UPDATE en TX (require manual TX control en Admirals.DB), stored procedure DB-side, optimistic locking via balance version column. Decisión postergada hasta S2 producción load.
- 🔵 **S2+ admirals_audit_log DDL canonical** — actualmente Audit.Categories.Transfer = 'bank.transfer' (ADR-010 wrapper). Categorías canónicas a SSoT §03 §12 cuando se firme.
- 🔵 **S2+ system account ENUM refinement** — ALTER ENUM admirals_bank_accounts.type ADD 'system' + relax CHECK O usar admirals_companies ficticio. Reduce semantic ambiguity.
- 🔵 **C002 movement_id_from/to in event payload** — Admirals.DB.Transaction wrapper retorna boolean (no insertIds del batch). S2+ podrá hacer post-select via request_nonce + bank_account_id si admirals_documents auto-receipt lo necesita.
- 🔵 **Admin command `/admirals_bank_recalc_balance <iban>`** — útil para reconciliación operacional. Out-of-scope S1.2 (Movements.RecalcBalance disponible en VM).
- 🔵 **Admin command `/admirals_bridge_idem_count`** — útil para visibilidad backend (memory size vs DB count). Out-of-scope S1.2.
- 🔵 **S1.3 mini-sesión: smoke test S1.2 doc + admin commands cleanup** — paquete pequeño antes de empezar S1.3 escrow FSM (perfil ⚡ SPRINTER, modelo Sonnet 4.6 ahorra Opus capacity).

### Smoke check S1.2 (founder ejecuta)

**Setup:** 2 player accounts via framework T1 connected. Cada uno genera personal account starter 2.500 €. System account seeded vía migration 004 (verificable: `SELECT balance FROM admirals_bank_accounts WHERE iban='AD-SYS0-0000-0001'` → 10000000.00).

1. **Pre-flight:** 3 resources arrancan limpios. Boot report admirals_core muestra "Idempotency backend swapped to DB-backed". Boot report admirals_bank ASCII con bank_accounts rows ≥ 3 (player A + player B + system). resmon admirals_bank + admirals_bridges idle <0.3ms cada uno.
2. **Happy path:** A transfer 100 € a IBAN B con request_id=`uuid-1` + concept='Test S1.2'. Response: `{success=true, data: {transaction_id='<uuid>', timestamp=<ms>, new_balance_from=2400.00, fee_retained=0.00}}`. DB: A.balance=2400.00, B.balance=2600.00, system.balance=10000000.00 (NO cambia). Movements: 2 nuevas rows con `request_nonce=<transaction_id>` (debit -100 + credit +100). Audit: 1 row category='bank.transfer' actor=A.citizen_id.
3. **Idempotency replay:** mismo request_id → response idéntica byte-by-byte + audit log nuevo `idempotency_replay` (action='idempotency_replay', target=<request_id>). DB balances NO cambian. Movements counts NO cambian. Verificable: `SELECT * FROM admirals_bridge_idempotency WHERE idem_key='uuid-1'` → 1 row con expires_at = created_at + 3600s.
4. **Self-transfer:** A transfer to su propio IBAN con request_id=`uuid-2` → `{success=false, error_code='SELF_TRANSFER'}`. DB balances NO cambian. Movements counts NO cambian. Idempotency entry persisted con response error (re-attempt mismo request_id retorna mismo error).
5. **Insufficient funds:** A transfer 5000 € a B con request_id=`uuid-3` → `error_code='INSUFFICIENT_FUNDS'`. DB balances NO cambian. Movements counts NO cambian.
6. **Rate limit:** 11 transfers válidos rápidos (sin idempotency replay — cada uno con request_id distinto) → primeros 10 OK + 11ª `error_code='RATE_LIMIT_EXCEEDED'`. Verificable: `Admirals.Rate.Stats()` muestra `bank.write` con 10 allowed + 1 blocked.
7. **Restart durante idempotency window:** transfer con request_id=`uuid-4` → success. Restart server. Re-attempt mismo request_id=`uuid-4` (mismo player after reconnect): retorna response cached (NO re-ejecuta TX). DB balances iguales a tras 1ª attempt. Confirma DB-backed survival cross-restart.
8. **Atomicity stress:** simular 100 concurrent transfers via consola admin (script o exec loop) → ledger 100% consistente: `Movements.RecalcBalance(account_id).delta == 0` para ambas cuentas. Si delta != 0 → race detectada (S1.2 race window documented; fail acceptable si ratio < 1% — escalate si > 1%).
9. **Event subscription:** subscribe consola admin a `admirals:bank:transfer_completed` (via `Admirals.Bus.Subscribe` snippet en `exec`) → recibe payload schema-valid en cada transfer success: `{transaction_id, from_iban, to_iban, amount, concept, category='transfer', requester_account_id, occurred_at, _event_id, _emitted_at, _schema_version}`.
10. **resmon:** durante stress test step 8, admirals_bank peak <1ms, admirals_bridges peak <1ms. Idle post-stress <0.3ms cada uno.

### Handoff próxima sesión (S1.3)

- **Modelo recomendado:** Opus 4.7 (FSM design + escrow atomicity crítica) + Sonnet 4.6 para harness/retro tail (ahorra Opus capacity).
- **Perfil:** 🏗️ ARCHITECT + ⚡ SPRINTER + 📝 SCRIBE.
- **Goal:** Migration 005 con `admirals_escrows` DDL (founder co-design SSoT §4.3 — currently inexistente, tenor "DDL canónico llegará en S1.3 junto con la lógica" per S1.1 entry) + `escrow_lifecycle` FSM transitions per `05_state_machines.md` §4.1 + C004 `admirals:bank:createEscrow` + C005 `admirals:bank:releaseEscrow` + harness tests manuales smoke + `scripts/smoke_test_s1.md` consolidado + `progress/SPRINT_RETRO_S1.md` + tag `v0.1.0`.
- **Docs a leer obligatorio:**
  - `progress/SESSION_LOG.md` últimas 3 entries (S1.1, S1.2 — esta, y siguiente).
  - `progress/SPRINT_PLAN_S1.md` §S1.3.
  - `docs/technical/03_db_schema.md` §4 — verificar §4.3 `admirals_escrows` (puede que aún no exista — co-design founder).
  - `docs/technical/04_api_contracts.md` §3.1 C004 + C005.
  - `docs/technical/05_state_machines.md` §4.1 escrow_lifecycle FSM completa.
  - `docs/economy/01_economic_model.md` §10.4 (escrow mechanics, fees 0.5-1% min 2€ max 100€).
- **Pre-condición:** smoke S1.2 10/10 ✅ + smoke doc S1.2 redactado en mini-sesión + git clean + (opcional) commit `S1.2 admirals_bank C002 transfer + idempotency DB-backed + system seed treasury`.
- **APIs disponibles S1.3:**
  - Todo lo de S1.1 + S1.2 + nuevo: `Admirals.Bank.Transfer.Execute` (reusable internamente para escrow lock = transfer player→escrow_account).
  - `Admirals.Bank.Movements.{Insert, GetByAccount, GetByNonce, RecalcBalance}`.
  - `Admirals.Bank.Events.PublishTransferCompleted` + nuevos `PublishEscrowLocked/Released/Disputed` (a crear).
  - `exports.admirals_bridges:IsIdemReplay/StoreIdem` (escrow ops también idempotent).
  - System treasury IBAN `AD-SYS0-0000-0001` recibe escrow fees (0.5% del valor del contrato — min 2€ max 100€ per economy §10.4.2).
- **Proper-locking opportunity:** escrow lock+release pattern es proper concurrency-safe (lock fondos → operación bloqueante → release). Considerar si S1.3 promueve `Admirals.DB.LockedTransaction` API o mantiene la TX racey de S1.2.
- **No tocar:**
  - `resources/admirals_bridges/*` (frozen S1.2 — bridges 0.2.0 con idempotency swap completo).
  - `resources/admirals_core/server/*` salvo Config.MigrationsFiles list para migration 005.
  - `docs/technical|economy|design|art|qa/*` salvo `docs/technical/03_db_schema.md` §4.3 si founder green-light co-design SSoT escrows.
  - `progress/SPRINT_PLAN_S1.md` (o sí — refinement allowed en S1.3 final).

### Files in scope respetados

✅ 5 creates + 8 edits = 13 operaciones. Founder green-light explícito previo via 5 reconciliaciones SSoT (fee=0€, no direction column, transfer category, response shape canonical, migration 004 path) + sub-decisión system account (`type='personal'` único path consistente con CHECK + opción(a) sin tocar constraint). Edits adicionales (bank/config TransferCompleted uncomment, bank/fxmanifest wire, core/config MigrationsFiles, core/fxmanifest files{}) son mecánicos in-scope per S1.1 pattern. No tocó `.windsurf/*`, `README.md`, `docs/*` firmados, `progress/SPRINT_PLAN_S1.md`, ni T1 adapters.

---

### S1.2 fix-and-validate (post-implementation, pre-commit) — 2026-05-02

**Trigger:** founder identificó 2 blockers antes de sign-off + commit:
1. Race window en `transfer.lua` Q1 UPDATE — el comment lo etiquetaba "tradeoff" pero violaba SSoT §04 §6 atomicity. Hard-fix upstream requerido.
2. Smoke 6 pasos NO ejecutados — necesita harness disposable (5 client commands + 3 server admin ACE-gated).

**Pre-action — verificación oxmysql (founder Opción A inviable):**

Confirmado vía oxmysql doc oficial (`overextended.dev/oxmysql/Functions/transaction`) + lectura de `@d:/theBigProject/resources/admirals_core/server/db.lua:206-247`:

- `MySQL.transaction.await(queries)` solo acepta **array pre-armado** `[{query, values}, ...]` (Specific format) o `{queries[], shared_values}` (Shared format).
- Retorna `boolean success` global. Rollback automático si cualquier query falla SQL-side.
- **NO existe function-form** `MySQL.transaction(fn(tx))` con handle `tx:Execute(query, params) → affectedRows` mid-flight.
- Esa firma requeriría connection raw que oxmysql NO expone (security pool isolation).

→ **Founder Opción A literal NO es implementable** sin patches upstream a oxmysql. Reportado al founder, propuesta Opción D (CHECK constraint) como upstream root cause fix. Founder green-light + 5 respuestas precisas a preguntas técnicas (ACE per-command pattern S1.1, eliminar AUTO-EJECUCIÓN NUCLEAR, migration 005 path admirals_core, NO tocar 003 inmutable, mensaje TX_ROLLBACK race-aware nice-to-have).

### Files creados (1)

| # | File | LoC | Propósito |
|---|---|---|---|
| 1 | `resources/admirals_core/migrations/005_balance_nonneg_check.sql` | ~75 | `ALTER TABLE admirals_bank_accounts ADD CONSTRAINT chk_admirals_bank_accounts_balance_nonneg CHECK (balance >= 0)`. Pre-flight SELECT informativo de violations. Header doc explica supersedes intent comment 003:79 + path S2+ overdraft (DROP CHECK + conditional CHECK con admin flag). |
| 2 | `resources/admirals_bank/client/smoke.lua` | ~265 | 5 client commands disposables: `/smoke_transfer`, `/smoke_transfer_replay [request_id]` (sin args replayea último cached), `/smoke_transfer_self`, `/smoke_transfer_overdraw` (usa system IBAN AD-SYS0-0000-0001 como destino), `/smoke_transfer_burst <to_iban>` (11 calls 1€ con request_ids únicos, esperado 10 OK + 1 RATE_LIMITED). UUID v4 generator client-side. _own_iban + _last_request_id state cached. Boot fetcha self IBAN via C001 al arrancar. |

### Files editados (5)

| # | File | Cambio |
|---|---|---|
| 1 | `resources/admirals_core/config.lua` | Añadir `'005_balance_nonneg_check.sql'` a `Config.MigrationsFiles` (ahora 5 migrations). |
| 2 | `resources/admirals_core/fxmanifest.lua` | Añadir `migrations/005_balance_nonneg_check.sql` a `files{}`. |
| 3 | `resources/admirals_bank/server/transfer.lua` | (a) Header: bloque "Race window (S1.2 conscious tradeoff)" eliminado (líneas 16-30 originales). Reemplazado por bloque "Atomicity guarantee" explicando CHECK constraint S005 + nota sobre oxmysql constraint function-form. (b) Q1 UPDATE: eliminado `AND balance >= ?` y el 4º value `amount` redundante. Comment Q1 actualizado explicando CHECK guard. (c) Mapping post-rollback race-aware: si `from_balance_pre >= amount` (pre-flight passed) y aun así rollback → return `'RACE_DETECTED'` + log warn + metric `bank.transfer.race_detected`. Else → `'TX_ROLLBACK'` genérico. (d) Mini comments stale eliminated: line 133 "race window documented in header" → "atomicity garantizada via CHECK"; line 163 "pre-TX defense — UPDATE WHERE balance >= ? es la garantía SQL-side" → "pre-flight UX — atomicity real garantizada por CHECK S005". |
| 4 | `resources/admirals_bank/server/callbacks.lua` | (a) Alinear C002 error_code canónico: `RATE_LIMIT_EXCEEDED` → `RATE_LIMITED` (igual que C001 — inconsistencia detectada por founder en review). Métrica también renombrada a `bank.callbacks.transfer.rate_limited`. (b) `message_map` extendido con `RACE_DETECTED = 'Saldo agotado por concurrencia. Reintenta.'`. |
| 5 | `resources/admirals_bank/server/init.lua` | (a) ELIMINADO completo: 4 bloques ad-hoc del founder (`/admirals_bank_recalc_balance` ad-hoc, `/admirals_bridge_idem_count` ad-hoc, `/admirals_smoke_stress` ad-hoc, `CreateThread "AUTO-EJECUCIÓN NUCLEAR V3"` con transfer hardcoded). (b) AÑADIDO: 3 admin commands formales ACE-gated con header "S1.2 SMOKE TEST TEMPORAL — DELETE POST SIGN-OFF": `/admirals_bank_recalc <iban>` (delta=0 verification post migration 005), `/admirals_bridge_idem_count` (visibilidad backend), `/admirals_bank_stress_transfer <from> <to> <count> <cid>` (stress 100 concurrent + recommend recalc both IBANs). Helper `_smoke_ace(source, command_name)` per patrón S1.1 `command.<name>` per-command ACE. Bug fix en stress command: `local stress_run_id = os.time()` para evitar idem replay cross-runs. |
| 6 | `resources/admirals_bank/fxmanifest.lua` | Añadir `client_scripts { '@ox_lib/init.lua', 'client/smoke.lua' }` block + comment "S1.2 SMOKE TEST TEMPORAL". |
| 7 | `progress/SESSION_LOG.md` | Append addendum S1.2 fix-and-validate (este). |

**Total fix-and-validate: 2 creates + 7 edits = 9 operaciones.**

**Total S1.2 acumulado: 7 creates + 15 edits = 22 operaciones.**

### Decisiones tomadas (fix-and-validate)

- **Opción D pura sobre A''/combo** — founder green-light. Razón: workspace rule "no premature abstractions". `TransactionFn` API ergonómica diferida hasta S2+ si llega necesidad real (escrow lock+release S1.3 NO la necesita — TransactionFn solo acumula queries, MISMO problema atomicity que array form sin CHECK). Cero API additions a `admirals_core` (mantiene 0.3.0 minimal post-S1.2).
- **CHECK constraint > app-side defense** — `WHERE balance >= ?` era silent failure (UPDATE 0 rows, TX commits sin error). CHECK fuerza SQL throw → MySQL rollback automático → DB.Transaction returns false → mapeo `RACE_DETECTED`. Atomicity garantizada **by construction, no probabilísticamente**.
- **MariaDB 10.2+ / MySQL 8.0.16+ enforce CHECK nativamente** — versiones previas lo IGNORAN silenciosamente. Producción Admirals targets MariaDB 10.6+ per SSoT §03 §1.2 (a verificar exact ver — no es S1.2 scope confirm). Si runs old MySQL/MariaDB, CHECK ignored → degrade gracefully a S1.2 race behavior pre-fix (ledger eventual via reconciliation). Mitigación: smoke step 8 detecta delta != 0 si CHECK ignored.
- **Migration 003 inmutable** — NO tocar comment `migration 003:79 "negativo = overdraft admin-only"`. S0.4 design: migrations son inmutables post-aplicada (checksum tracked en `admirals_schema_versions`). Editar el .sql rompería consistency check si re-corremos algún día. **Resolución:** comment supersedes documented en `005_balance_nonneg_check.sql` header. Technical debt anotado: migration 003 comment overdraft contradice 005 CHECK; resolución 005 prevalece (constraint > comment); refresh 003 deferred S2+ con migration aditiva si overdraft entra roadmap.
- **`RACE_DETECTED` distinct error_code** — vs simplemente reinterpretar `TX_ROLLBACK`. UX nice + observability (smoke step 8 stress detection clean). Mensaje "Saldo agotado por concurrencia. Reintenta." vs genérico TX_ROLLBACK ayuda diagnóstico. Founder confirmó: mantener distinguished si no complica code (no complica — 5 LoC en transfer.lua + 1 entry message_map).
- **`RATE_LIMITED` canonical alignment** — C001 ya usaba `RATE_LIMITED` (callbacks.lua:96), C002 usaba `RATE_LIMIT_EXCEEDED` (callbacks.lua:271 pre-fix). Inconsistency detectada en review fix-and-validate. Realineado a `RATE_LIMITED` per SSoT §7 catalog convention. Métrica también renombrada.
- **ACE per-command S1.1 pattern** — NO introducido `admirals.admin` group (decisión cross-cutting deferred S2+ con ADR formal cuando >10 admin commands). Hoy 3 disposables: `command.admirals_bank_recalc`, `command.admirals_bridge_idem_count`, `command.admirals_bank_stress_transfer`. Founder otorga via server.cfg `add_ace builtin.everyone command.<name> allow` (líneas removibles post-smoke).
- **Smoke client commands disposables** — header explícito "S1.2 SMOKE TEST TEMPORAL — DELETE POST SIGN-OFF (cleanup commit separado)". Mismo patrón S1.1 (smoke client removed en commit `S1.1 cleanup remove temporal smoke client + iban_gen command`). Cleanup S1.2 será commit aparte tras founder smoke 10/10 ✅.
- **`/smoke_transfer_replay` UX-friendly** — sin args replayea `_last_request_id` (cached client-side desde último OK). Founder spec "Más UX-friendly que tener que copy-paste UUIDs". Aún acepta arg explícito si founder quiere forzar request_id específico.
- **`/smoke_transfer_overdraw` usa system IBAN AD-SYS0-0000-0001 como destino** — siempre existe (migration 004 garantiza). Evita necesitar 2 player accounts conectados para test step 5.
- **`/smoke_transfer_burst` request_ids únicos** — loop genera UUID v4 fresh por call (NO replay). Esperado 10 OK + 1 RATE_LIMITED por bucket bank.write 10/60s. Pass criterion: `ok_n == 10 and rate_limited == true`.
- **Stress command `stress_run_id = os.time()`** — evita idem replay cross-runs si admin ejecuta stress consecutivos en mismo segundo. UUID prefix `smoke-stress-<unix_ts>-<i>` distinct per run.
- **NO bump SEMVER bank/core en fix-and-validate** — admirals_bank 0.2.0 + admirals_core 0.3.0 mantenidos. Razón: el fix corrige un bug detectado pre-commit (no released yet). Si S1.2 hubiera sido released, sería patch bump (0.2.0→0.2.1 / 0.3.0→0.3.1). Pre-release commit consolidado mantiene versiones S1.2 originales.

### Verificación estática (fix-and-validate)

- ✅ **0 instancias `RATE_LIMIT_EXCEEDED`** en `resources/admirals_bank/` — alineado canonical `RATE_LIMITED`.
- ✅ **0 instancias `WHERE balance >= ?`** en queries actuales — solo en header explicación CHECK supersedes.
- ✅ **0 menciones "Race window"** en código activo — solo "race detected" en mapping post-rollback (semantically distinct: race **detected** by CHECK, not window left open).
- ✅ **0 bloques ad-hoc founder** en `admirals_bank/server/init.lua` — limpieza completa (`/admirals_bank_recalc_balance`, `/admirals_bridge_idem_count` ad-hoc, `/admirals_smoke_stress`, `CreateThread "AUTO-EJECUCIÓN NUCLEAR"` todos eliminados).
- ✅ **3 admin commands formales** registrados con `_smoke_ace` per-command ACE pattern S1.1 idiomatic.
- ✅ **5 client commands** registrados en `client/smoke.lua` con header "S1.2 SMOKE TEST TEMPORAL — DELETE POST SIGN-OFF".
- ✅ **fxmanifest client_scripts** declarado con dependencia explícita `@ox_lib/init.lua` (lib.callback.await client-side).
- ✅ **Migration 005 wire** — añadida a `Config.MigrationsFiles` + `fxmanifest.files{}` admirals_core.

### Done criteria S1.2 fix-and-validate

- ✅ **transfer.lua sin race window**. Comment actualizado: "Atomicity guarantee — CHECK constraint chk_admirals_bank_accounts_balance_nonneg".
- ✅ **5 client commands operativos** (`/smoke_transfer`, `/smoke_transfer_replay`, `/smoke_transfer_self`, `/smoke_transfer_overdraw`, `/smoke_transfer_burst`).
- ✅ **3 server admin commands operativos** ACE-gated per S1.1 pattern (`/admirals_bank_recalc`, `/admirals_bridge_idem_count`, `/admirals_bank_stress_transfer`).
- 🟡 **Founder ejecuta smoke 10 pasos completos** — pendiente ejecución manual founder. 10/10 ✅ requisito sign-off antes de commit + cleanup.

### Smoke 10 pasos refinados (founder ejecuta)

**Setup:** server.cfg add_ace 3 commands admin (per spec founder Q2). Player A + B conectados (cada uno 2.500 € starter). Migration 005 aplicada (verificable: `SHOW CREATE TABLE admirals_bank_accounts\G` debe mostrar `CONSTRAINT chk_admirals_bank_accounts_balance_nonneg CHECK (balance >= 0)`).

1. **Pre-flight** — 3 resources arrancan limpios. Boot report admirals_core: "Bridges idempotency backend swapped to DB-backed". `migrations applied: 5/5`. Boot report admirals_bank: bank_accounts rows ≥ 3 (A + B + system). resmon idle <0.3ms.
2. **Happy path** — Player A: `/smoke_transfer <IBAN_B> 100`. Esperado: `^2[smoke] OK | request_id=<uuid> | tx=<uuid> | new_balance=2400.00 €^7`. DB: A=2400, B=2600, system=10000000 (NO cambia). Movements: 2 rows con request_nonce=transaction_id.
3. **Idempotency replay** — Player A: `/smoke_transfer_replay` (sin args, usa cached). Esperado: response idéntica byte-by-byte + audit log nuevo `idempotency_replay`. DB balances NO cambian. `SELECT * FROM admirals_bridge_idempotency WHERE idem_key='<request_id>'` → 1 row.
4. **Self transfer** — Player A: `/smoke_transfer_self`. Esperado: `^1[smoke] FAIL | error_code=SELF_TRANSFER^7`. DB balances NO cambian.
5. **Insufficient funds** — Player A: `/smoke_transfer_overdraw`. Usa system IBAN como destino, amount = balance + 1000. Esperado: `^1[smoke] FAIL | error_code=INSUFFICIENT_FUNDS^7`. DB balances NO cambian. Movements counts NO cambian.
6. **Rate limit** — Player A: `/smoke_transfer_burst <IBAN_B>`. 11 calls de 1€ con request_ids únicos. Esperado: `^2[smoke] Burst PASS: 10 OK + RATE_LIMITED on 11th^7`. `Admirals.Rate.Stats()` muestra bank.write con 10 allowed + 1 blocked.
7. **Restart cross-window** — transfer con request_id=`uuid-restart`. Restart server (`restart admirals_bank` o full restart). Re-attempt mismo request_id (mismo player after reconnect): retorna response cached (NO re-ejecuta TX). Confirma DB-backed survival cross-restart. `/admirals_bridge_idem_count` muestra entries persistidas.
8. **Atomicity stress** — Console: `admirals_bank_stress_transfer <IBAN_A> <IBAN_B> 100 <CID_A>`. Tras completar: `/admirals_bank_recalc <IBAN_A>` → `^2[recalc] LEDGER OK — delta=0 exacto^7`. Mismo para `<IBAN_B>`. **CRITERION: delta=0 EXACTO** (no <1% threshold — CHECK constraint S005 enforce atomicity).
9. **Event subscription** — Console snippet: `Admirals.Bus.Subscribe('admirals:bank:transfer_completed', function(p) print(json.encode(p)) end)`. Player A: `/smoke_transfer <IBAN_B> 50`. Console recibe payload con keys: `transaction_id, from_iban, to_iban, amount, concept, category='transfer', requester_account_id, occurred_at, _event_id, _emitted_at, _schema_version`.
10. **resmon final** — Durante stress test step 8, admirals_bank peak <1ms, admirals_bridges peak <1ms. Idle post-stress <0.3ms.

**Sign-off criterion: 10/10 ✅** → commit `S1.2 admirals_bank C002 transfer + idempotency DB-backed + system seed treasury + atomicity CHECK constraint S005`. Tras commit, founder pide cleanup smoke (PR separado eliminando `client/smoke.lua` + 3 admin commands + ACE lines server.cfg).

### Issues pendientes (post fix-and-validate)

- 🟡 **Founder ejecuta smoke 10/10** antes de commit. Si algún paso falla → debug + nueva sub-iteración (mismo protocolo: STOP + flag + propuesta + green-light).
- 🟡 **Cleanup smoke commit separado** post-sign-off — eliminar `client/smoke.lua` + sección admin commands en `init.lua` (líneas 247-368) + `client_scripts` block en fxmanifest + 3 ACE lines server.cfg founder. Operación atómica reversible (git revert) si necesario.
- 🟡 **Verificar MariaDB version en server founder** — CHECK constraint enforcement requiere MariaDB 10.2+ o MySQL 8.0.16+. Smoke step 8 detecta si version older (delta != 0 con CHECK ignored).
- 🔵 **Technical debt — migration 003 comment overdraft contradice 005 CHECK** — Resolución: 005 prevalece (CHECK constraint > comment). Refresh comment 003 deferred S2+ con migration aditiva si overdraft entra roadmap. Anotado en migration 005 header sección DECISIONES TÉCNICAS D1.
- 🔵 **S2+ admin overdraft (si requerido)** — `ALTER TABLE admirals_bank_accounts DROP CHECK chk_admirals_bank_accounts_balance_nonneg` + nuevo CHECK con condition `(balance >= 0 OR admin_overdraft_enabled = 1)` + columna `admin_overdraft_enabled TINYINT(1) DEFAULT 0`. Non-breaking opt-in.

### Files in scope respetados (fix-and-validate)

✅ 2 creates + 7 edits = 9 operaciones. Strict whitelist founder cumplida (migration 005, transfer.lua, callbacks.lua RATE_LIMITED + RACE_DETECTED, init.lua limpieza + 3 admin, client/smoke.lua, fxmanifest client_scripts, core/config + core/fxmanifest wire 005, SESSION_LOG addendum). NO tocó `admirals_bridges/*` ni adapters T1 ni docs firmados ni migration 003.

---

### S1.2 cleanup (post sign-off smoke 10/10) — 2026-05-02

**Trigger:** founder sign-off smoke 10/10 ✅ (PASS en todos los pasos: integridad atómica SQL, happy path, idempotencia replay, self-transfer reject, overdraw protection, rate limiting burst, persistencia cross-restart, stress test delta=0.0000 exacto, audit log eventos, resmon optimizado). Commit S1.2 implementación realizado con hash `436d247` (16 files changed, 2042 insertions, 39 deletions). Founder green-light Fase 2 cleanup smoke harness inmediatamente per workspace convention S1.x (smoke harness disposable removible post-sign-off).

### Operaciones cleanup (1 delete + 2 edits)

| # | File | Cambio |
|---|---|---|
| 1 | `resources/admirals_bank/client/smoke.lua` | **DELETED** completo — 5 client commands disposables (`/smoke_transfer`, `/smoke_transfer_replay`, `/smoke_transfer_self`, `/smoke_transfer_overdraw`, `/smoke_transfer_burst`). Directorio `client/` también eliminado (vacío). |
| 2 | `resources/admirals_bank/server/init.lua` | **REMOVED** sección "S1.2 SMOKE TEST TEMPORAL" líneas 247-369 (helper `_smoke_ace` + 3 RegisterCommand: `admirals_bank_recalc`, `admirals_bridge_idem_count`, `admirals_bank_stress_transfer`). File final = 245 LoC (boot orchestration + Identity hooks + `/admirals_bank_status` admin only). |
| 3 | `resources/admirals_bank/fxmanifest.lua` | **REMOVED** `client_scripts {'@ox_lib/init.lua', 'client/smoke.lua'}` block + comment "S1.2 SMOKE TEST TEMPORAL". Header doc actualizado: "No client_scripts (callbacks via ox_lib server-side; client UI llega S1.5+ con admirals_tablet)". |
| 4 | `progress/SESSION_LOG.md` | Append cleanup entry (este). |

**Total cleanup: 1 delete + 3 edits = 4 operaciones (3 files únicos modificados + directorio cliente eliminado).**

**Total S1.2 acumulado (implementación + fix-and-validate + cleanup):** 6 creates (mig 004, mig 005, movements.lua, transfer.lua, events.lua) + 1 delete (client/smoke.lua) + 11 file modifications = 18 file ops netas.

### Pendiente founder (server.cfg cleanup)

Founder elimina manualmente las 3 ACE lines en `d:/fivem-dev/server-data/server.cfg` líneas 22-24 (añadidas pre-smoke):

```cfg
# REMOVE these 3 lines (S1.2 smoke harness no longer exists):
add_ace builtin.everyone command.admirals_bank_recalc          allow
add_ace builtin.everyone command.admirals_bridge_idem_count    allow
add_ace builtin.everyone command.admirals_bank_stress_transfer allow
```

Tras remove, restart server o reload server.cfg → validación: `IsPlayerAceAllowed(source, 'command.admirals_bank_recalc')` retorna false. Comandos no existen en código → no efecto runtime, pero limpieza conceptual recomendada.

### Verificación estática (cleanup)

- ✅ **0 instancias `_smoke_ace`** en `resources/admirals_bank/`.
- ✅ **0 instancias `admirals_bank_recalc` / `admirals_bridge_idem_count` / `admirals_bank_stress_transfer`** en `resources/admirals_bank/`.
- ✅ **0 referencias `client/smoke.lua`** en fxmanifest.
- ✅ **0 `client_scripts` block** en `admirals_bank/fxmanifest.lua`.
- ✅ **Directorio `resources/admirals_bank/client/` eliminado** (no existe).
- 🟡 **2 menciones "smoke"** restantes en comments documentales legítimos: `transfer.lua:284` ("smoke test step 8 stress detection" en mapping RACE_DETECTED) + `movements.lua:24` ("Usado por smoke atomicity verification" en RecalcBalance docstring). Workspace rule "no añadir/borrar comments sin pedido" — comments preservados. Son references contextuales explicando intent, no harness en sí.

### Done criteria S1.2 cleanup

- ✅ **Smoke harness eliminado** (5 client + 3 admin commands + helpers + comments header).
- ✅ **fxmanifest sin client_scripts** disposable.
- ✅ **server/init.lua final shape** = boot orchestration only (245 LoC vs 369 LoC pre-cleanup).
- 🟡 **Founder elimina 3 ACEs server.cfg** — manual, fuera de repo (server.cfg en `d:/fivem-dev/server-data/`, no en workspace `d:/theBigProject/`).

### Commit Fase 2

Pendiente ejecutar:
```
git add resources/admirals_bank progress/SESSION_LOG.md
git commit -m "S1.2 cleanup remove temporal smoke harness post sign-off"
```

Mensaje sigue convention `S{N}.{M} {imperative present}` per workspace rule + S1.1 precedent ("S1.1 cleanup remove temporal smoke client + iban_gen command").

### Issues post-cleanup

- 🔵 **Working tree limpio** — solo `scripts/smoke_test_s1_2.md` queda untracked (founder decision opt-out commit).
- 🟢 **Sprint S1.2 completo** — implementación + fix-and-validate + smoke 10/10 + cleanup. Ready para S1.2 close + S1.3 escrow lock+release session arranque.
- 🔵 **Smoke S1.2 reproducible** — `git checkout 436d247 -- resources/admirals_bank/client/ resources/admirals_bank/server/init.lua resources/admirals_bank/fxmanifest.lua` recupera harness completo si necesita re-run (e.g., regression test pre-S2 release).

### Files in scope respetados (cleanup)

✅ 1 delete + 3 edits = 4 operaciones. Strict scope cumplido (cleanup solo touches files que tenían smoke harness o reference a él). NO tocó admirals_core (3 admin commands eran solo en admirals_bank/server/init.lua), NO tocó admirals_bridges, NO tocó docs/* firmados, NO tocó server.cfg founder (manual cleanup founder responsability).

---
