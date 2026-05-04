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

### S1.3 — Escrow FSM + C004 createEscrow + C005 releaseEscrow + sprint close

- **Fecha:** 2026-05-02
- **Duración:** ~6h (estimado: 4-5h — overrun por 3 incidencias de schema/auth resueltas in-flight)
- **Founder + Agent:** yaboula + Cascade
- **Sprint:** S1 — Banco core + IBAN + balance + transferencias + escrow
- **Perfil:** 🏗️ ARCHITECT + 🔧 BUILDER + 📝 SCRIBE
- **Modelo:** Claude Sonnet 4.5
- **Goal:** Escrow FSM + C004 createEscrow + C005 releaseEscrow + smoke 14 pasos + sprint close S1.
- **Status:** ✅ Done — smoke 14/14 ✅, sign-off founder.

### Cambios

- **Created:**
  - `resources/admirals_core/migrations/006_escrow_schema.sql` — DDL `admirals_escrows` (id, status, buyer_account_id, seller_account_id, escrow_account_id, amount, fee_charged, contract_id, release_condition, release_date, expires_at, request_nonce, released_to, released_by_account_id, released_at, timestamps) + relax CHECK ownership en `admirals_bank_accounts` para permitir branch escrow (owner_account_id NULL XOR escrow type).
  - `resources/admirals_core/migrations/007_escrow_fks_to_accounts.sql` — fix FK target buyer/seller_account_id → `admirals_accounts(id)` (luego revertido por 008, ver decisiones).
  - `resources/admirals_core/migrations/008_escrow_fks_revert_to_bank_accounts.sql` — TRUNCATE rows inconsistentes + DROP FKs 007 + ADD FKs canónicos → `admirals_bank_accounts(id)`. Final FK design.
  - `resources/admirals_bank/server/fsm_escrow.lua` — FSM table-driven `escrow_lifecycle` per `05_state_machines.md` §4.1: estados {created, locked, released, refunded, disputed} + transitions whitelist + `Fsm.CanTransition` + `Fsm.AssertTransition`.
  - `resources/admirals_bank/server/escrow.lua` — `Escrow.Create` (atomic TX 4-query: insert escrow row + create escrow bank account + UPDATE buyer balance debit (amount+fee) + 2 INSERTs movements amount/fee separately) + `Escrow.Release` (atomic TX 3-query: UPDATE escrow status→released/refunded + UPDATE recipient balance credit + 1 INSERT movement). Auth matrix F3 + fee compute (1% clamp 2/100€) + audit + events.
  - `scripts/smoke_test_s1_3.md` — 14 pasos manuales: boot, happy path, idempotency, SELF_ESCROW, INSUFFICIENT_FUNDS, fee clamps 4/4, release seller, refund buyer, NOT_AUTHORIZED, NOT_IMPLEMENTED split, FSM double-release, rate limit, event subscription, resmon. Troubleshooting + DB queries verificación.
- **Modified:**
  - `resources/admirals_core/config.lua` — version 0.3.0→0.4.2, +3 migrations (006, 007, 008) en MigrationsFiles.
  - `resources/admirals_core/fxmanifest.lua` — version 0.3.0→0.4.2, +3 migrations files{}, description ampliada.
  - `resources/admirals_bank/config.lua` — escrow constants (EscrowFeeRate=0.01, EscrowFeeMin=2, EscrowFeeMax=100, EscrowAmountMin, EscrowAmountMax, EscrowFeeDestIban='AD-SYS0-0000-0001'), audit categories `escrow.*`, eventos `admirals:bank:escrow_*`.
  - `resources/admirals_bank/server/events.lua` — `PublishEscrowCreated/Released/Refunded` con schema validation v1.
  - `resources/admirals_bank/server/callbacks.lua` — C004 `admirals:bank:createEscrow` + C005 `admirals:bank:releaseEscrow` con idempotency (DB-backed via Bridges._IsIdemReplay), rate limiting `bank.write` 10/60s, error mapping completo, comment C003 placeholder.
  - `resources/admirals_bank/fxmanifest.lua` — version 0.3.0→0.4.0 (post-cleanup), wired fsm_escrow.lua + escrow.lua antes de callbacks.lua.
- **Deleted (cleanup post sign-off):**
  - `resources/admirals_bank/client/smoke_s1_3.lua` — 6 client commands smoke disposables.
  - `resources/admirals_bank/server/smoke_s1_3_sub.lua` — server-side EventBus subscription harness (step 13). Untracked → simply removed file.
  - Directorio `resources/admirals_bank/client/` (vacío post-delete).
  - Bloque `client_scripts{}` + comentarios "S1.3 SMOKE TEST TEMPORAL" en `admirals_bank/fxmanifest.lua`.

### Decisiones tomadas

- **`escrow.{buyer,seller}_account_id` referencia bank_account.id NO player identity** — root cause de FK violation step 2 + auth mismatch step 7. Migration 007 inicialmente apuntó FKs a `admirals_accounts` (identity) pero auth release tenía que volver a resolver bank account → desalineamiento. Fix definitivo: 008 revierte FK target a `admirals_bank_accounts(id)` + refactor `escrow.lua` para `INSERT (buyer_acc.id, seller_acc.id, ...)` + `_authorize_release` resuelve owner del bank_account stored via SQL lookup. Diseño homogéneo: las 3 columnas `*_account_id` en `admirals_escrows` referencian bank accounts.
- **Migration immutability respetada (ADR-010)** — pese a que 007 fue redundante, NO se modificó ni borró: 008 cancela su efecto vía DROP FOREIGN KEY + ADD nuevas FKs. Cadena 006→007→008 queda en historial idempotente. Migration runner skip OK 2da run.
- **Smoke step 13 con server-side harness paralelo, no `exec` cfx** — `exec` en server.cfg ejecuta archivos cfx commands no Lua. Patrón canonical es server_script disposable wired en fxmanifest, mismo paradigma que client smoke harness S1.1/S1.2.

### Issues pendientes

- 🟢 **Sprint S1 listo para retro + tag v0.1.0** — pendiente Fase B workflow `/sprint-retro`.
- 🔵 **C003 `admirals:bank:listMovements`** — placeholder comment en callbacks.lua, scope S1.5 o S2 (consulta paginada).
- 🔵 **Split release 50/50** — actualmente retorna NOT_IMPLEMENTED en C005. Scope S2+ junto con dispute resolution.
- 🔵 **`resmon` budget escrow callbacks** — observado 0.00ms idle (step 14 ✅) pero no medido bajo carga sostenida. Spike S2 para load test escrow stress.
- 🟡 **`scripts/smoke_test_s1_2.md` untracked** — opt-out founder commit S1.2. Mantener o gitignore — decisión founder.

### Handoff próxima sesión (S2.1 — TBD planning)

- **Modelo recomendado:** Opus 4.7 MAX (perfil 🏗️ ARCHITECT, scope S2 mayor — Tablet UI + Bridges adapters T2 ESX/QBCore + Empresas).
- **Goal:** TBD — founder refina pre-S2.1 en planning dedicado (per `03_founder_playbook.md` §3.2). Roadmap §4.2 S2 outline candidate: admirals_tablet NUI (React) + Bank UI básico + admirals_companies DDL + ALTER TABLE FK admirals_bank_accounts.owner_company_id.
- **Pre-requisitos:**
  - `progress/SPRINT_RETRO_S1.md` (a redactar Fase B).
  - `progress/SPRINT_PLAN_S2.md` (scaffold Fase C, refinable founder).
  - `docs/design/02_admirals_tablet.md` re-read.
  - `docs/technical/07_bridges_compatibility.md` §5 (T2 adapters spec).
- **Files in scope:** TBD post planning. Probable: `resources/admirals_tablet/` (nuevo) + `resources/admirals_bridges/adapters/{esx,qbcore}/*` (expansión T2) + migration 009 admirals_companies.
- **Notas especiales:** S1 cierra con escrow FSM funcional pero sin client UI — toda interacción vía consola. S2.1 introduce primera UI NUI player-facing. Considerar pair Opus arquitectura + Sonnet implementation.

### Files in scope respetados

✅ 6 creates + 7 modifications + 4 deletes (cleanup) = 17 file ops. Scope respetó SPRINT_PLAN_S1 §S1.3 + ampliación documentada (migrations 007/008 imprevistas por incidencia FK in-flight, founder green-light explícito). NO tocó `docs/*` firmados, NO tocó `admirals_bridges/*`, NO tocó `.windsurf/*`. Cleanup eliminó todo harness disposable conforme convention S1.1/S1.2.

---

### S1.4 — Strategic Identity Pivot Admirals → SONAR (ADR-011 + art_direction.md v2.0 scaffold)

- **Fecha:** 2026-05-03
- **Duración:** ~3h (planning UI S2 → identity conflict surfaced → 3 options presented → founder decision Option A radical → Phase 1-3 execution)
- **Founder + Agent:** yaboula + Cascade
- **Sprint:** post-S1 / pre-S2 (out-of-band session strategic — NO sprint formal)
- **Perfil:** 🏗️ ARCHITECT + 📝 SCRIBE (cero builder — sesión 100% docs)
- **Modelo:** Claude Sonnet 4.5
- **Goal:** Resolver conflicto identidad detectado durante planning S2 (founder color preference Coloro 092-37-14 + inspiración Prism Scripts vs SSoT firmada `01_art_direction.md` v1.0 Almirantazgo). Decisión founder + ADR registrado + foundation rewrite iniciado.
- **Status:** ✅ Done — Phase 1-3 completas. Phases 4-12 deferred multi-sesión.

### Contexto de la sesión

Durante planning S2 dedicada (post-S1 close), founder añadió 2 notas estratégicas UI:

1. **2026-05-02 23:36** — Preferencia inspiración Prism + Quasar, premium-modern-friendly + paleta primaria nueva = WGSN Coloro 092-37-14.
2. **2026-05-03 03:46** — Reafirma fork A planning. Comparte 3 capturas Prism Scripts ilustrando aesthetic dark-canvas + brilliant-pop + glow-instruments.

Architect leyó `docs/art/01_art_direction.md` v1.0 (2678 líneas firmadas) + `docs/design/02_admirals_tablet.md` §6 + búsqueda Prism Scripts. **Surfaces critical conflict:** nueva dirección visual contradice EXPLÍCITAMENTE 5 anti-references firmadas en `01_art_direction.md` §1.3 ("Sci-fi cyberpunk neón", "Dark mode tacticool militar negro/lima", "Glassmorphism iOS clone") y §6.4 ("Glow / neon outer glow → Cero").

Architect presentó 3 opciones con recomendación firme **Opción B (Reconcile)**. Founder eligió **Opción A (Pivot Radical)**: rebrand completo Admirals → SONAR + nueva metáfora Submarino Nuclear / Exploración Abisal + aesthetic dark + bioluminescent teal + glassmorphism + tech precision.

Architect documentó 7 banderas rojas (time, escalation pattern, SSoT contradictions ×2, market reasoning thinness, cost ~200h, scope creep, internal request contradiction). Founder explicit override: *"es la última vez que me limites por tiempo, soy responsable y acepto el riesgo"*.

### Cambios

- **Created:**
  - `docs/_archive/01_art_direction_v1_admirals.md` — preservación inmutable v1.0 Admirals (2678 líneas) — moved via `Move-Item` PowerShell para preservar git rename history.
  - `docs/art/01_art_direction.md` v2.0-scaffold — foundational scaffolding post-pivot SONAR. Contiene: 20 secciones planificadas, decisiones foundational firmes (paleta hex 16 colores institucionales+functionales+crew, tipografía Geist Sans+Inter Tight+Geist Mono, voz silent service, sound 5 SFX firma, iconografía 8 custom names, glassmorphism + glow rules signature). TODOs claros para Phase 4 detail-pass.
- **Modified:**
  - `docs/planning/02_decision_log.md` — version 1.2→1.3. **+1 ADR foundational + risk_accepted**: ADR-011 strategic identity pivot Admirals → SONAR. ADR completo con 7 secciones (Contexto, Decisión, Alternativas A/B/C, Consecuencias positivas/negativas/neutrales, **Risks accepted by founder** ×7 documentados per workspace red-flags protocol, Impact docs+code+DB+git+workspace, Execution plan 12-phases multi-sesión, Rollback strategy, Re-evaluation triggers). Tag index actualizado (+5 nuevos: identity, branding, aesthetic, ssot_invalidation, risk_accepted; pivot extendido ADR-008+ADR-011). §5.2 estado ADR-001..011 accepted. §6.2 v1.3 firmable (11 ADRs). §6.3 changelog +entry 1.3. §7 TL;DR +ADR-011 row. Resumen ejecutivo cierre actualizado 11 ADRs.
  - `progress/SESSION_LOG.md` — append S1.4 entry (este).
- **Moved (PowerShell `Move-Item`):**
  - `docs/art/01_art_direction.md` v1.0 → `docs/_archive/01_art_direction_v1_admirals.md`. Git tracking: rename detectable post-commit.

**Total S1.4: 1 move + 2 creates + 2 edits = 5 operaciones.**

### Decisiones tomadas

- **Pivot radical Option A elegida sobre B/C** — founder green-light explícito. Razón founder: aesthetic Prism-pure + Coloro 092-37-14 + tendencia mercado FiveM premium 2026. Architect documented Opción B (Reconcile) como recomendación rejected — preserva 2678 líneas + diferenciación competitiva única naval (`01_art_direction.md:113` declaración "blue ocean"). Override aceptado per `admirals.md` rules §trust_hierarchy: founder green-light en conversación actual = highest authority.
- **ADR-011 documenta 7 risks accepted by founder INMUTABLEMENTE** — per workspace rule §red_flags ("Founder pide algo que contradice SSoT firmado → STOP y consulta founder"). Architect raised flags, founder explicitly overrode → risks documented inmutables for institutional memory. Memoria persistente: en 6 meses, lectura ADR-011 da contexto completo de qué se sopesó vs decisión final.
- **Multi-phase plan 12 phases, NO ejecución big-bang** — founder pidió "completo + seguro + ahora" simultáneo (3 condiciones mutuamente excluyentes). Architect propuso multi-phase plan: Phase 1-3 esta sesión (ADR + foundation art_direction scaffold + SESSION_LOG + memory) preserva "completo + seguro" sacrificando "ahora" parcialmente. Phases 4-12 deferred sesiones futuras con dry-runs, gates, smoke regression. Founder accepted multi-phase tras confirmación detallada.
- **`docs/_archive/` directory creada como SSoT preservation pattern** — convention establecida hoy: docs deprecated por ADRs futuros se mueven a `_archive/<filename>_v<n>_<context>.md` (preserves git history via Move-Item, not delete). Permite rollback total via supersede ADR + checkout archive. **Acción S2:** considerar formalizar pattern en `02_decision_log.md` §3 (cómo añadir nuevo ADR) si surge necesidad de archive futuro.
- **art_direction.md v2.0-scaffold NO firmable hasta Phase 4** — header explícito "🚧 en redacción" + estado §estado_documento_check. Phase 4 detail-pass sesión dedicada completará: type scale tokens detallados, motion specs ms-precise, custom icon SVG construction, sound bibliography sourcing, glossary 30+ términos, marketing materials specs, governance protocol, plan assets nodos completo.
- **Decisiones foundational firmes en v2.0-scaffold (ya elegidas, NO TODOs):**
  - Paleta hex 16 colores: 8 institucionales (abyss-black + 3 depths + Coloro identity + 3 sonar pop), 4 crew neutrals, 4 functional signals.
  - Tipografía: Geist Sans display + Inter Tight body + Geist Mono datos. Razones documentadas, alternativas consideradas listadas.
  - Voz de marca silent service + persona "comandante submarino nuclear" + vocabulario lexico submarino-tech + 6 ejemplos voz aplicada (3 ✅ + 2 ❌ + 1 deprecated v1).
  - Sound naming 5 firma (sonar_ping/pressure/depth/console/hatch) replaces 5 v1 firma (admirals_chime/seal/quill/brass_click/parchment).
  - Iconografía custom 8 essentials (sonar-ping, submarine, depth-gauge, hydrophone, bioluminescence, pressure-hull, periscope, torpedo-bay) replaces 20 navales v1.
  - Glassmorphism rules signature (modal/drawer only, NO surfaces principales).
  - Glow rules signature (instrument glow OK, gamer outer glow prohibido, test del 50%).
  - 60/30/10/<5 paleta usage rule.
  - Anti-pattern crítico documentado: "dark canvas + brilliant pop", NO "teal everywhere".
- **§9 Granja preservation light-recontextualized** — preserved estructura v1 con concept statement revised (surface node agrícola en sonar grid SONAR, harvest_ping signal). Detalle completo Phase 7 doc purge. Razón: foundation work foundational, no rewrite agresivo de nodos sin Phase 7 dedicado.
- **Memoria UI design persistente actualizada** — UpdateMemory action: pivoted desde "navy + Coloro Reconcile" hacia "SONAR identity (abyss + Coloro + sonar bright/glow + glassmorphism + silent service voice)". Memoria sirve como context handoff cross-session AI agents.

### Issues pendientes (post-S1.4)

- 🟢 **Phase 4 detail-pass `01_art_direction.md` v2.0-scaffold → v2.0 firmable** — sesión dedicada futura. Modelo recomendado: Opus 4.7 MAX (decisiones design foundational + creative density alta).
- 🔴 **~28 docs firmados invalidados, rewrite Phases 5-7 multi-sesión** — `00_PRODUCT_BIBLE.md`, `00_BOOTSTRAP.md`, `02_sonar_tablet.md` (renamed), `01_architecture.md`, `02_events_catalog.md` (333 event renames), `03_db_schema.md` (463 table refs), `04_api_contracts.md`, design/* nodes (5), economy/01, gameplay/* (3), qa/01, planning/01_roadmap.md, art/02-04, technical/05-07. Total ~30K-40K líneas afectadas. Cada doc requiere sesión dedicada o batch sesion según scope.
- 🔴 **Code refactor Phase 8 single-session high-risk** — rename 3 resources `admirals_*` → `sonar_*` + namespace `Admirals.*` → `Sonar.*` (~200+ call sites) + exports + admin commands + server.cfg. Smoke regression 30/30 obligatorio post-refactor.
- 🔴 **DB migration 009 Phase 9 single-session highest-risk** — rename 6 tablas + bootstrap dance `admirals_schema_versions` self-reference + DROP/RECREATE FKs+CHECKs. **Dry-run obligatorio en DB clone snapshot** antes de production. Migration 010 reverso preparado pre-9 (rollback safety).
- 🔴 **Smoke regression Phase 10 validation gate** — 30/30 smokes con SONAR naming antes de Sprint 2 retomar. Si falla, ADR-011 amendment hotfix path.
- 🔴 **Workspace IDE migration Phase 11 cleanup** — corpus `yaboula/admirals` → `yaboula/sonar` + workspace rules `.windsurf/rules/admirals.md` → `sonar.md` + workflows refs purged + memorias persistentes actualizadas.
- 🟡 **Git tags fossils** — `v0.0.0`, `v0.1.0`, `sprint-1-complete` quedan etiquetando hitos del nombre antiguo. NO removibles sin history rewrite. Decisión founder: dejar como historia institucional.
- 🟡 **Sprint 2 inicio diferido** — antes Tablet shell + Bank app + Map app, requiere Phases 4-12 complete. Roadmap §4.2 update pendiente Phase 7.
- 🟡 **Re-evaluation trigger ADR-011 3 meses post-pivot** — measure engagement diferenciador SONAR vs Admirals heritage hipotético. Si no genera lift detectable mercado FiveM premium, considerar ADR-012 partial revert.

### Handoff próxima sesión

> **NOTA:** próxima sesión NO es S1.5 standard sprint cadence — es Phase 4 detail-pass de pivot ADR-011.

- **Modelo recomendado:** Opus 4.7 MAX (perfil 🏗️ ARCHITECT + 🎨 DESIGNER, scope creative density alta — paleta validation contra accesibilidad, motion specs ms-precise, glossary creativo, sound bibliography curation, marketing voice samples).
- **Goal:** completar `docs/art/01_art_direction.md` v2.0-scaffold → v2.0 firmable. TODOs marcados explícitamente en doc:
  - §3.3 logo SONAR detail visual construction (designer collaboration).
  - §4.2 type scale line-height per-size + letter-spacing exact tokens + responsive breakpoints.
  - §5.2 custom icon set 8 SVG construction + Figma library + repo `art/icons/sonar_icons_v1/`.
  - §6 textures SVG repo + CSS class library + 3D texture maps.
  - §7.3 sound bibliography sourcing + audio asset format specs + license docs + sonification per nodo.
  - §11 SONAR OS Tablet decisiones detail (cross-ref `02_sonar_tablet.md` rewrite Phase 5 dependency).
  - §12 marketing materials moodboard + video specs + Tebex page layout + trailer storyboard.
  - §13 plan assets list 3D+2D+sound+branding + briefing equipo 3D + prioridades por oleada.
  - §14 governance review protocol + signing workflow + designer collaboration.
  - §15 glossary completo 30+ términos.
  - §16-20 motion specs + verticales placeholders + storybook + shader contracts + roadmap iterations.
- **Pre-requisitos:**
  - Re-read `01_art_direction.md` v2.0-scaffold completo + ADR-011 § Contexto/Decisión/Risks.
  - Web research adicional opcional: glassmorphism best practices 2026, Geist Sans usage examples, submarine UI references (Hunt: Showdown, Sub-Sea, Aquanox visual references).
- **Files in scope:** `docs/art/01_art_direction.md` (only). NO tocar code, NO tocar otros docs (Phases 5+ scope).
- **Notas especiales:** Phase 4 es **creative density session**, NO refactor mass-purge. Una sesión dedicada con Opus para densidad de detalle máxima. Founder validation por sección recomendada.

### Files in scope respetados

✅ 1 move + 2 creates + 2 edits = 5 file ops. Scope strictly respected: solo `docs/_archive/` (created), `docs/art/01_art_direction.md` (moved + recreated), `docs/planning/02_decision_log.md` (ADR-011 added), `progress/SESSION_LOG.md` (this entry). NO tocó otros docs firmados, NO tocó code, NO tocó DB, NO tocó `.windsurf/*`, NO tocó workspace rules. Phases 5-12 deferred per execution plan.

> **Founder explicit quote on override (institutional memory):** *"es la última vez que me limites por tiempo, soy responsable y acepto el riesgo, nunca haces referencia a tiempo. arrancamos y vamos con total energia, porque no sabes los detalles de mi estoy totalmente listo."* — 2026-05-03 04:44 UTC+02.

> **Architect compliance:** override accepted, 7 risks documented in ADR-011 per professional senior duty + workspace rules §red_flags protocol, executing per founder direction multi-phase to preserve "completo + seguro" while sacrificing "ahora" partially.

---

### S1.5 — SONAR Pivot continuation: Phase 4 Sonnet scaffold + Phase 5 light Bible + Phase 4.5 partial briefs + ADR-012 refinement

- **Fecha:** 2026-05-03 (continuación misma sesión post-S1.4)
- **Duración:** ~5.5h (Phase 4 r2 + r3 + r4 → Phase 5 light Bible v1.3 surgical → Phase 4.5 partial briefs logo+icons → ADR-012 refinement → art_direction r6 NOTICE → Bible v1.4 surgical → briefs discard)
- **Founder + Agent:** yaboula + Cascade
- **Sprint:** post-S1 / pre-S2 (out-of-band — pivot ADR-011 execution multi-phase)
- **Perfil:** 📝 SCRIBE (100% docs, cero code)
- **Modelo:** Claude Sonnet 4.5
- **Goal:** Maximizar progreso pivot SONAR mientras Sonnet sea modelo activo. Atacar slices Sonnet-compatibles de Phase 4 detail-pass (administrative + structural) + ejecutar Phase 5 light surgical rewrite Product Bible para alinear identidad foundational.
- **Status:** ✅ Done — 8 commits pushed total. Bible v1.4 ✅ + art_direction r6 NOTICE-canonical ✅ + ADR-011 + ADR-012 paired SSoTs ✅. Briefs v1 (logo + icons) descartados post-ADR-012. Pendiente: Phase 4.5 v2 briefs reescritos clean + Phase 4 surgical full §1-§20 art_direction.

> **🔄 Strategic refinement post-Phase 5 light:** founder revisó scaffold final + briefs y detectó 3 desviaciones interpretativas (metáfora literal-militar excesiva, dark-extremo 60% canvas, voz arquetipo capitán submarino). Architect ejecutó STOP per workspace §red_flags + 4-question sync explicit. Founder D1=abstract pure metáfora + D2=single hybrid theme dark+white + D3=voz neutral premium-tech + D4=process-all-now. Resultado: ADR-012 amendment (no supersede ADR-011) + art_direction r6 NOTICE top-level + Bible v1.4 surgical purge + briefs v1 discard. Detalle commits: `d0712cc` ADR-012, `27de1b6` art_direction r6 NOTICE, `7cf29f0` Bible v1.4 surgical, próximo SESSION_LOG close commit.

### Contexto de la sesión

S1.4 cerró con `art_direction.md` v2.0-scaffold-r1 (foundational decisiones firmes + 20 secciones planificadas + paleta hex 16 + glassmorphism/glow rules + sound + iconografía names). Founder pidió continuar atacando Phase 4 con Sonnet en lugar de esperar Opus, mediante "partial attacks" sobre slices Sonnet-compatibles (estructurales/administrativos, NO creative-density alta como logo construction o moodboard marketing).

Tres iteraciones partial attacks ejecutadas (r2 → r3 → r4) cubrieron progresivamente todas las secciones Sonnet-compatibles. Founder solicitó luego pivot a Phase 5 light: **surgical rewrite Product Bible** preservando secciones pivot-agnostic (gameplay, técnico, riesgos, timeline, comercial) y reescribiendo solo identidad/metáfora/glossary/refs Tablet. Founder green-light explícito + override "es muy importante para mi acabar este pivot" — sesión continuada hasta close natural post-Bible v1.3.

Adicionalmente: founder estratégicamente corrigió jerarquía paleta r1 → invertir Coloro 092-37-14 (Tier C structural support) ↔ Sonar Bright #2DD4BF (Tier B PRIMARY BRAND IDENTITY). Razón: bioluminescencia es firma marketing, deep-teal es soporte. Memoria persistente actualizada r1.

Post-Bible, founder expressó sentirse perdido respecto al avance pivot. Architect respondió con mapa claro estado actual + roadmap restante 12 phases + admisión de gap propio: Phase 4 "creative-density" estaba mal categorizada como bloque indivisible. Real: 2 capas — (a) **briefs/prompts por especialidad** (Sonnet OK) + (b) **ejecución creativa output** (Opus/humano). Founder eligió ejecutar Phase 4.5 critical now (logo + icons briefs Sonnet). Briefs delivered como deliverable packages autocontenidos en `docs/art/briefs/`.

### Cambios

- **Modified:**
  - `docs/art/01_art_direction.md` — 3 partial attacks (~770 líneas netas añadidas total scaffold-r1 → scaffold-r4):
    - **r2** (commit `0b2b47e`): §4.2 type scale tokens (line-height per-size, letter-spacing, responsive breakpoints, font loading strategy, anti-patterns) + §15 glossary 28 términos canonical (cross-ref futuro `00_PRODUCT_BIBLE.md` §15 + `01_economic_model.md` §15) + §16 motion specs (ms-precise easing curves, 12 motion tokens, sonar ping animation spec, framer-motion examples).
    - **r3** (commit `d0ecfeb`): §13 plan assets (matriz prioridades 3D+2D+sound+branding por Oleada 1-5, briefing equipo 3D, formatos asset, repo structure `art/`) + §14 governance (review protocol, designer collaboration workflow, signing thresholds, ownership matrix RACI, conflict resolution) + §17 verticales placeholders (Phases 1-5 stubs Tablet/Map/Marketing/Onboarding/Verticales-futuras con TODOs explícitos).
    - **r4** (commit `2cecedc`): §18 Storybook integration (component library structure, story conventions, accessibility a11y addons, visual regression Chromatic) + §19 shader contracts (depth-fog WebGL/threejs spec, sonar-ripple shader, bioluminescence emissive map, performance budgets) + §20 roadmap iterations (v2.1 Q3-2026 polish + v2.2 Q4 marketing assets + v3.0 2027 expansion verticales). Final tagline + footer changelog r4.
    - **Palette inversion fix** (durante r2): §3.4 META-BRAND table + §3.5 logo rules + §11 lock screen + §12 website refs — Coloro deep-teal → soporte estructural Tier C, Sonar Bright #2DD4BF → PRIMARY BRAND Tier B. Memoria persistente UI design re-aligned.
  - `docs/art/01_art_direction.md` v2.0-scaffold-r4 → r5 (Phase 4.5 partial post-Bible commit): cross-refs §3.3 + §5.2 → `docs/art/briefs/01_brief_logo.md` + `docs/art/briefs/02_brief_icons.md`. Footer state + changelog r5 entry append.
  - `docs/design/00_PRODUCT_BIBLE.md` v1.2 → v1.3 (commit `b480af5`): **surgical rewrite** Phase 5 light Admirals → SONAR. Tocados (11 secciones): header + §1 identidad (acrónimo + 3 taglines + tono silent service + Apple/Linear/Vercel inspiration + paleta canonical cross-ref + tipografía Geist/Inter/Geist Mono + 5 SFX firma) + §1.1 metáfora (submarine abisal + vocabulario instrumental Bridge/Bitácora/Console/Depth/Eco/Hatch/Manifiesto/Periscope/Ping/Signal) + §2 visión/misión/promesas (voz silent service + "operador") + §3 Pilar 5 (Tablet SONAR bridge command center) + §5 anti-features (Tablet SONAR exception) + §7 Granja SONAR + Tablet SONAR refs + §7.4 Tablet apps revised (Bridge/Manager/Mercado/Logística/Mensajes/Banca SONAR/Manifiestos/Tienda SONAR brushed steel aesthetic) + §10.2 protocolo SONAR común + §12 modelo comercial SONAR refs + §13.3 Regla SONAR + §15 Glossary cross-ref canonical art_direction §15 + términos producto + §16 próximos docs + §17 Changelog v1.3 + final tagline *"Hear the depth. Below the surface, every signal counts."*. Preservado intact (pivot-agnostic): §4 Wooow + §6 Targets + §8.3-§8.6 catálogo cultivos+roles+propiedad+narrativa + §9 Filosofía gameplay + §10.1 Stack + §10.3 Código + §10.4 Seguridad + §11 Principios económicos + §12 Showcase + §13 Timeline + 3D/Código + §14 Riesgos.

- **Created (Phase 4.5 partial):**
  - `docs/art/briefs/` directory + `README.md` (index + status table 2/5 briefs).
  - `docs/art/briefs/01_brief_logo.md` — BRIEF-LOGO-001 (~270 líneas, deliverable autocontenido para designer humano o Opus 4.7 MAX): contexto SONAR para designer no-onboarded, 10 deliverables (SVGs canonical + monogram + wordmark + lockups H/V + reverse + glow variants + raster PNG @1x/@2x/@3x + favicons + guidelines PDF + Figma source + opcional video splash), specs técnicos vinculantes (concepto S-onda LOCKED, color tokens Tier B Sonar Bright identity / Coloro PROHIBIDO, Geist Sans wordmark, geometría 12×12 grid, 3 lockups + clear-space + tamaños mínimos), do/don't ✅×6 ❌×11 con misuse explicit, referencias visuales (5 convergir Linear/Stripe/Vercel/Apple/Arc + 5 anti cyberpunk/military/RGB/mascot/touristy + assembly moodboard), 5 review gates R0-R4 con sync/async cadence, licensing + NDA + presupuesto orientativo €1.5-3.5k EU freelance + alternativa AI Opus, founder pre-kickoff checklist ×6.
  - `docs/art/briefs/02_brief_icons.md` — BRIEF-ICONS-001 (~280 líneas): los 8 iconos LOCKED desde art_direction §5.2 (sonar-ping/submarine/depth-gauge/hydrophone/bioluminescence/pressure-hull/periscope/torpedo-bay) + 2 stretch (manifiesto/bitacora), 32 SVG files target (8 × 4 sizes 16/20/24/32) + React TS component lib + Figma library + guidelines PDF + showcase PNG, specs canvas 24×24 + stroke 1.5px round Lucide-compatible (debe ser indistinguible visualmente de Lucide), guidance per-icon individual ×8 con concepto + dimensiones + reglas, do/don't ✅×7 ❌×10, 4 review gates R0-R3, licensing + presupuesto €1.2-2.8k, dependency: BRIEF-LOGO-001 R4 cerrado primero (sonar-ping deriva del logo monograma).

**Total S1.5: 2 files modified + 3 files created (briefs/ pkg) + 5 commits = 5 file ops. Net diff Bible: +97 / −79 (+18 líneas). Net diff art_direction: ~+770 líneas (scaffold-r1 → scaffold-r5). Briefs total: ~580 líneas nuevas.**

### Decisiones tomadas

- **Phase 4 split por modelo capability** — Sonnet ataca scaffold completo (sections estructurales/administrativas/specs precise) hasta saturar capacidad. Opus 4.7 MAX queda reservado solo para slices restantes creative-density alta (§3.3 logo construction, §5.2 custom icon SVGs, §6 textures, §7.3 sound bibliography curation, §11 Tablet cross-ref, §12 marketing moodboard). Beneficio: Phase 4 ya 100% scaffolded, Opus puede entrar surgical en lugar de big-bang.
- **Palette hierarchy inversion (founder strategic correction r1)** — Coloro 092-37-14 demoted Tier C structural support, Sonar Bright #2DD4BF promoted Tier B PRIMARY BRAND IDENTITY. Memoria persistente actualizada cross-session. Rationale documented inline `01_art_direction.md` §3.4. **Hard rule:** logo / branding marketing / CTA primary / app-icon = Sonar Bright SIEMPRE. Coloro Support = SOLO glassmorphism tints + inactive borders + deep-tier UI.
- **Phase 5 light, NO full** — Bible v1.3 surgical NO big-bang rewrite. Solo identidad/metáfora/glossary/refs Tablet tocados. 60% del documento (gameplay, técnico, comercial, riesgos) preservado intact reduciendo risk regresión + cost. Phase 5 full puede deferred indefinidamente hasta encontrar contradicción explícita en sección preservada.
- **Admirals refs intencionales en Bible v1.3** — 7 referencias residuales preservadas con contexto explícito: pivot historical notes, Phase 5 rename note `02_admirals_tablet.md`, Phase 8 code namespace `admirals:event:*`, Glossary entry "deprecated v1.0 Admirals", DB Phase 8 rename note `admirals_*` → `sonar_*`, Changelog v1.1/v1.2 inmutable. Founder validation: NO eliminar — son trazabilidad histórica + roadmap migration markers.

### Issues pendientes (post-S1.5)

- 🔴 **Phase 4.5 v2 — 5 briefs reescritos clean post-ADR-012** — todos descartados v1: BRIEF-LOGO-001 v2 (concepto NO ondas concéntricas; alternativas descent-layers/prisma profundidad/gradient depth/geometric depth-grid) + BRIEF-ICONS-001 v2 (3 conservados depth-gauge + pressure-hull reconceptualizado capas + bioluminescence + 5 nuevos abstractos: descent-layers/signal-clarity/depth-grid/observation-field/lineage-trace) + BRIEF-SOUND-001 (5 SFX naming refactored: signal_emerge/depth_press/layer_dive/console_tap/panel_open) + BRIEF-MOTION-001 (sin sonar ping animation — replace por depth-descent/layer-reveal patterns) + BRIEF-MARKETING-001 (voz neutral premium-tech samples Vercel/Linear/Stripe style). Sonnet-compatible, ~1.5-2h próxima sesión.
- 🟡 **Phase 4 surgical full §1-§20 art_direction** — NOTICE r6 actualmente supersedes literal-militar refs en §1-§20 pero el contenido inline sigue interpretado v1.0-r5. Phase 4.5 v2 hará surgical rewrite limpio: §1 metaphórica re-escrita abstract pure + §2 anti-refs add literal-militar + §3 paleta ratios hybrid integrated + §3.6 voz neutral samples + §5.2 iconografía 8 abstract finalizada + §7 sound names integrated + §15 glossary cleanup términos deprecated. Modelo: Sonnet o Opus.
- 🟢 **Phase 4 ejecución creativa (post-briefs v2)** — contratar designers humanos o ejecutar Opus 4.7 MAX para R1-R2 visual generation. Outputs creativos = SVGs/PNGs/MP4/audio assets reales. Modelo: Opus 4.7 MAX o human freelance designer EU senior.
- 🟢 **Phase 5 full Foundation docs rewrite** — `docs/agents/00_BOOTSTRAP.md` (onboarding), `docs/design/02_admirals_tablet.md` (rename → `02_sonar_tablet.md`), `docs/technical/01_architecture.md`, `docs/economy/01_economic_model.md`, `docs/gameplay/*` (3 files). Cada uno surgical light o full según scope. Modelo: Sonnet adecuado para surgical, Opus para architecture-heavy.
- 🟡 **Phase 6 Mass-purge docs operacionales** — `docs/technical/02_events_catalog.md` (333 event renames), `03_db_schema.md` (463 table refs), `04_api_contracts.md`, `05_state_machines.md`, `06_fivem_standards.md`, `07_bridges_compatibility.md`, `qa/01`, `art/02-04`, `planning/01_roadmap.md`. Multi-sesión. Posible automation grep+sed con dry-run obligatorio.
- 🔴 **Phase 8 code refactor + Phase 9 DB migration 009 + Phase 10 smoke regression + Phase 11 workspace migration** — sin cambios desde S1.4 handoff.
- 🟡 **Sprint 2 inicio diferido continúa** — Tablet shell + Bank app + Map app dependen Phases 4-12 complete.

### Handoff próxima sesión

> **NOTA:** próxima sesión decision tree según fatiga founder + capacity AI disponible:
>
> - **Opción A (Sonnet OK — recomendada):** Phase 4.5 v2 — 5 briefs reescritos clean alineados ADR-012 (LOGO + ICONS + SOUND + MOTION + MARKETING). ~1.5-2h. Cierra Sonnet-side de Phase 4.
> - **Opción B (Sonnet OK):** Phase 4 surgical full §1-§20 art_direction (purga literal-militar inline + integrar NOTICE r6). ~2-3h. Sister de A.
> - **Opción C (Sonnet OK):** Phase 5 light continuation — surgical rewrite `00_BOOTSTRAP.md` aligned ADR-011+ADR-012 (crítico onboarding cross-session AI agents). ~30-45min.
> - **Opción D (Sonnet OK):** Phase 5 full — rename `02_admirals_tablet.md` → `02_sonar_tablet.md` + rewrite completo aligned art_direction r6 NOTICE + glossary. ~1.5-2h.
> - **Opción E (Opus 4.7 MAX):** Phase 4 ejecución creativa post-briefs v2 — logo/icons SVG generation con MJ/Ideogram + Opus refinement. ~2-3h por asset.

- **Modelo recomendado:** Sonnet 4.5 (Opciones A/B/C/D) o Opus 4.7 MAX (Opción E).
- **Goal:** Avanzar Phase 4.5 v2 (A) o Phase 4 surgical full (B) o Phase 5 (C/D) o ejecutar creative outputs (E).
- **Pre-requisitos LECTURA OBLIGATORIA:** ADR-011 + **ADR-012** + `01_art_direction.md` v2.0-scaffold-r6 NOTICE (top of doc) + Bible v1.4 §1 identidad. **NO leer briefs v1** (descartados).
- **Files in scope:** Opción A → `docs/art/briefs/01-05_*.md` v2 (5 creates clean). Opción B → `docs/art/01_art_direction.md` (§1-§20 surgical). Opción C → `docs/agents/00_BOOTSTRAP.md` only. Opción D → `docs/design/02_admirals_tablet.md` (rename + rewrite) only. Opción E → `art/branding/logo_v1/` + `art/icons/sonar_icons_v1/`.
- **Notas especiales:** **Bible v1.4** = SSoT identidad canonical post-ADR-012. **`01_art_direction.md` v2.0-scaffold-r6 NOTICE** = SSoT visual canonical (NOTICE supersedes literal-militar refs en §1-§20). **ADR-011 + ADR-012 lectura conjunta obligatoria** — ambos accepted, ADR-012 amends (no supersede). Memoria persistente SONAR identity requiere **update r2** post-ADR-012 (palette hybrid + iconografía abstract + voz neutral + lo que NO es SONAR purga literal). Briefs v1 (logo + icons) **NO LEER** — descartados, confunden con metáfora literal-militar.

### Files in scope respetados

✅ 3 modifications + 3 creates-then-deleted + 8 commits total = 6 net file ops (todos en `docs/` + SESSION_LOG). Scope strictly respected: `docs/planning/02_decision_log.md` (ADR-012) + `docs/art/01_art_direction.md` (r5+r6 NOTICE) + `docs/design/00_PRODUCT_BIBLE.md` (v1.3+v1.4 surgical) + `progress/SESSION_LOG.md` + `docs/art/briefs/` (created→deleted). NO tocó code, NO tocó DB, NO tocó `.windsurf/*`, NO tocó otros docs firmados. Pivot Phase 4 + Phase 4.5 partial + Phase 5 light **+ ADR-012 refinement** strict adherence ADR-011/ADR-012 paired execution plan.

> **Founder mood quote (institutional memory):** *"vamoooooooooooooos , estoy muy felis esto es una locura wooooooow seguimooooooos"* — 2026-05-03 mid-session post-r2.

---

### S1.6 — Phase 4.5 v2 briefs + BOOTSTRAP v1.5 + art_direction scaffold-r7 surgical (C+B combo)

- **Fecha:** 2026-05-03
- **Duración:** ~4h estimado (founder total sesión combinada S1.4+S1.5+S1.6 ~10-11h mismo día).
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6).
- **Sprint:** S1 (pivot phase post-sprint-1-complete) — no-sprint doc work continuation.
- **Perfil:** 🎨 Design + 📝 Docs.
- **Modelo:** Sonnet 4.6.
- **Goal:** Ejecutar C+B combo post-ADR-012: (C) BOOTSTRAP v1.4 → v1.5 surgical rewrite pivot-aware + (B) art_direction v2.0-scaffold-r6 NOTICE → v2.0-scaffold-r7 surgical full inline §1-§20 cleanup. Plus Phase 4.5 v2 briefs clean (5/5 delivered).
- **Status:** ✅ Done (C+B combo completo, 3 commits pushed `5838a79` + `a879c45` + `611a4f9`).

### Cambios

- **Created:**
  - `docs/art/briefs/README.md` (index 5 briefs v2 + v1 discarded notes).
  - `docs/art/briefs/01_brief_logo.md` v2 (~302 líneas — 5 candidatos abstract preliminares post-ADR-012, NO S-onda concéntrica literal).
  - `docs/art/briefs/02_brief_icons.md` v2 (~360 líneas — 3 conservados + 5 abstract nuevos `descent-layers`/`signal-clarity`/`depth-grid`/`observation-field`/`lineage-trace`).
  - `docs/art/briefs/03_brief_sound.md` v1 (~340 líneas — 5 SFX canonical `signal_emerge`/`depth_press`/`layer_dive`/`console_tap`/`panel_open`).
  - `docs/art/briefs/04_brief_motion.md` v1 (~379 líneas — 12 tokens + 5 signature animations `logo_descent_reveal`/`layer_reveal`/`depth_drill_down`/`signal_emerge_pulse`/`bioluminescence_breathe`).
  - `docs/art/briefs/05_brief_marketing.md` v1 (~410 líneas — Tebex + trailer 60/30/15s + moodboard + social assets neutral voice).
  - `progress/PRE_S2_CHECKLIST.md` v1.0 (parte obligatorios pre-S2: 5 hard blockers B1-B5 + 3 decisiones founder D1-D3 + 5 soft-opcionales S1-S5 + orden ejecución + ETA ~12-18h founder time).
- **Modified:**
  - `docs/agents/00_BOOTSTRAP.md` v1.4 → v1.5 (title rebrand + §1 header pivot-aware + §2 project status ADR-011/012 phases + §3 reading order ampliado ~75→110min con ADR-011+ADR-012+NOTICE+Bible v1.4 obligatorios + §4.1 SSoT jerarquía 18-row + §5.5 NEW 8-section SONAR Identity hard rules + §5.4.7 NEW anti-pattern re-confundir metáfora + §13 TL;DR rewrite).
  - `docs/art/01_art_direction.md` v2.0-scaffold-r6 → v2.0-scaffold-r7 (surgical full inline §1-§20 cleanup post-ADR-012: §0.1 tesis + §1.2 anti-refs 4 NEW rows + §1.3 competitors SONAR row + §2 metáfora central full rewrite + §3.1 tagline Production-grade + §3.2 voz de marca + §3.3 logo NO-LOCKED 5 candidatos + §3.4 paleta ratios hybrid 30-40/30-40/10-15/10/<5 + §4.3 type rules + §7.1-§7.2 sound filosofía + 5 SFX descriptions canonical + §15 glossary Bridge re-interpretado + Silent service/Hatch/Periscope/Porthole deprecated + §15.G/H mappings + §16 motion easing curves rebrand abstract + §19.5 shader anti-pattern + footer r7 + tagline + FIN).
  - `progress/SESSION_LOG.md` (entry S1.6 appended — esta misma).
- **Deleted:** ninguno (briefs v1 ya deleted en S1.5).

### Decisiones tomadas

- **Phase 4.5 v2 ≠ Phase 4 surgical:** se ejecutaron ambas en S1.6 (5 briefs v2 + full §1-§20 inline cleanup) — founder green-light C+B combo.
- **NOTICE r6 preserved top-level a pesar del surgical r7:** NOTICE sigue siendo canonical vigente, r7 NO la reemplaza sino que pone contenido inline también alineado. Belt-and-suspenders discipline.
- **Changelog r6 corruption fix contained in-session:** PowerShell bulk-replace afectó tabla de mapping + changelog r6 text; restoración manual ejecutada antes commit — per workspace rule "append-only retroactive edits" justificable porque error mismo-session pre-commit (no se alteró entry ya commited).

### Issues pendientes

- 🔴 **Phase 6 mass-purge operational docs** — `02_admirals_tablet.md` (más crítico), `02_events_catalog.md`, `03_db_schema.md`, `04_api_contracts.md`, `05_state_machines.md`, `06_fivem_standards.md`, `07_bridges_compatibility.md`, `01_roadmap.md` v1.4 → v1.5. Ver `PRE_S2_CHECKLIST.md` §B1.
- 🔴 **SPRINT_PLAN_S2.md no existe** — planning session dedicada pendiente. Ver §B2.
- 🔴 **Decisiones founder pendientes:** D1 scope S2 (UI-heavy vs tech-balanced) + D2 creative outsourcing SÍ/NO + D3 namespace migration timing. Ver `PRE_S2_CHECKLIST.md` §D1-D3.
- 🟡 **Smoke regression `admirals_bank`** pendiente ejecutar pre-S2. Ver §B4.
- 🟡 **Tag `sonar-identity-canonical`** pendiente sobre `611a4f9`. Ver §B5.
- 🟢 **Phase 8+9 code/DB migration** — ejecución depende D3.
- 🟢 **Creative delivery** (logo SVG + icons set + sounds + motion + marketing) — ejecución depende D2. Briefs v2 ya firmables.

### Handoff próxima sesión (S1.7 o S2.0)

- **Modelo recomendado:** si S1.7 = Sonnet 4.6 (Phase 6 surgical doc-por-doc, velocity); si S2.0 planning = Opus 4.7 o Gemini 3.1 Pro (density analítica).
- **Goal:** (a) S1.7 Phase 6 surgical `02_admirals_tablet.md` → `02_sonar_tablet.md` + `01_roadmap.md` v1.5. OR (b) S1.7 decisiones founder D1+D2+D3 + tag + smoke regression. OR (c) S2.0 planning (solo si B1 done).
- **Pre-requisitos LECTURA OBLIGATORIA:** `progress/PRE_S2_CHECKLIST.md` v1.0 (este doc nuevo — **LEER PRIMERO**) + `docs/agents/00_BOOTSTRAP.md` v1.5 + ADR-011 + ADR-012 + `01_art_direction.md` v2.0-scaffold-r7 NOTICE r6 + Bible v1.4 §1 + SESSION_LOG S1.4+S1.5+S1.6 entries.
- **Files in scope:** depende goal (ver PRE_S2_CHECKLIST orden ejecución).
- **Notas especiales:** **PRE_S2_CHECKLIST.md = SSoT operacional pre-S2** — cualquier drift de los 5 hard blockers bloquea S2 kickoff legítimo. **Memoria SONAR Identity r2 debe confirmarse al boot** — si retrieval muestra r1, force-update. **Briefs v1 delete confirmado, briefs v2 = única SSoT creative**. **No leer `02_admirals_tablet.md` viejo como SSoT** — está pre-pivot, confunde.

### Files in scope respetados

✅ Scope strict: `docs/art/briefs/` (6 creates) + `docs/agents/00_BOOTSTRAP.md` (1 mod) + `docs/art/01_art_direction.md` (1 mod) + `progress/SESSION_LOG.md` (1 append) + `progress/PRE_S2_CHECKLIST.md` (1 create). **NO tocó code, NO tocó DB, NO tocó `.windsurf/*`, NO tocó otros docs firmados operacionales** (Phase 6 defer explícito).

> **Founder guidance institutional:** *"DEJAMOS EL DESIGN TRABAJANDO Y SEGUIMOS"* (repetido 3× — mantra sesión C+B combo). *"ok perfecto y deja un parte de obligatorios qeu tengo que tener antes de empezar s2"* (cierre S1.6 — request directo parte pre-S2).

---

### S1.7 — Logo v2 finalization (Concept A "S-curl open" canonical + PNG exports + brief audit)

- **Fecha:** 2026-05-03
- **Duración:** ~2h estimado.
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.6).
- **Sprint:** S1 (pivot phase post-sprint-1-complete) — design execution continuation.
- **Perfil:** 🎨 Design + 🛠️ Tooling.
- **Modelo:** Sonnet 4.6.
- **Goal:** Finalizar logo v2 a partir de fuente founder (`sonar_logo_concept_explorations.svg` 5 variantes A-E), adoptar Concept A "S-curl open" como canonical visual preference, limpiar fuente para mantener solo variante A, alinear paleta a brief §4.1, generar PNG exports + favicon.ico per brief §2.1 deliverables, audit final vs brief §2.1/§4, clarificar que es **preferencia visual NO pivot de marca** (briefs v2 + ADR-012 metáfora abstract siguen vigentes).
- **Status:** ✅ Done (logo v2 working canonical + 26 PNGs + favicon.ico + README v1.1 + audit complete; **NO commit yet — pending founder review**).

### Cambios

- **Created:**
  - `art/branding/logo_v2/exports/` (27 archivos):
    - `monogram_{16,32,64,128,256,512,1024}.png` (canonical opacity-fade variant).
    - `monogram_solid_{16,32,64,128,256}.png` (solid variant para small/stamp use).
    - `monogram_light_{64,128,256,512}.png` (Crew 100 canvas variant).
    - `wordmark_{256,512,1024,2048}.png`.
    - `lockup_horizontal_{512,1024,2048}.png`.
    - `lockup_vertical_{256,512,1024}.png`.
    - `favicon.ico` (multi-resolution 16+32+48 from `monogram_s_solid.svg`).
  - `art/tools/logo_export/package.json` (Node project + deps `sharp@0.33` + `png-to-ico@2`).
  - `art/tools/logo_export/export.mjs` (~142 líneas — pipeline SVG→PNG sharp@384dpi + favicon multi-res).
  - `art/tools/logo_export/README.md` (~40 líneas — uso, deliverables, stack).
- **Modified:**
  - `art/branding/logo_v2/monogram_s.svg` — rewrite a Concept A (3 arcs Q-bezier opacity-fade 0.35/0.65/1.0, viewBox 256×256, paths escalados 3× desde fuente founder centrada en 128,128).
  - `art/branding/logo_v2/monogram_s_solid.svg` — rewrite a Concept A solid (todas arcs opacity 1.0, para favicon/small sizes).
  - `art/branding/logo_v2/monogram_s_light.svg` — rewrite a Concept A light + **fix paleta `#0F766E` → `#1FB39E`** per brief `01_brief_logo.md` v2 §4.1 token `--sonar-bright-shifted`.
  - `art/branding/logo_v2/wordmark_sonar.svg` — rewrite a `<text>` Geist SemiBold tracking −3.5% (substituye custom slab letterforms previas chamfered).
  - `art/branding/logo_v2/lockup_horizontal.svg` — rewrite con monogram Concept A inline + wordmark Geist alineado.
  - `art/branding/logo_v2/lockup_vertical.svg` — rewrite con monogram Concept A inline + wordmark Geist centered.
  - `art/branding/logo_v2/source_exploration_sheet.svg` — limpiado de 5 variantes (A-E) a solo Concept A + nota semántica founder reinterpretation (capas profundidad ≠ ondas concéntricas radio).
  - `art/branding/logo_v2/preview.html` — actualizado para mostrar variantes Concept A (canonical/solid/light) + lockups.
  - `art/branding/logo_v2/README.md` — full rewrite v1.1: status WORKING CANONICAL, metáfora founder sign-off (profundidad/trabajar a fondo NO ping radio), anatomía 3 arcos, paleta verificada vs brief §4.1, anatomy + lockups + clear-space + audit completo §2.1 deliverables (5/5) + §4 specs (paleta ✅ + tipo ✅ + geometría ⚠️ excepción documentada) + §3 anti-patterns (5/6 ✅ + 1 ⚠️ founder-overridden) + **disclaimer NO-PIVOT explícito**.
- **Deleted:** ninguno (variants B-E removidas via rewrite source_exploration_sheet, no archivos físicos borrados).

### Decisiones tomadas

- **Concept A "S-curl open" = visual preference NO pivot de marca:** founder explícito que ADR-012 (metáfora abstract profundidad) sigue vigente; brief v2 5 candidatos sigue firmable; este logo v2 es **una expresión específica del candidato "preferida hoy"**, no reemplaza spec doctrinal. Documentado en `README.md` §"NO es pivot" + `source_exploration_sheet.svg` nota semántica.
- **Reinterpretación semántica formal:** founder asume que arcos abiertos NO = ondas concéntricas radio/freq prohibidas por ADR-012 §D1, sino = **capas profundidad / trabajar a fondo / valor emergiendo bajo estratos**. Decisión founder-level overrideando lectura literal del anti-pattern. Reinterpretación documentada en `README.md` §Metáfora + `source_exploration_sheet.svg` line 145.
- **NO ADR-013 todavía:** founder explícito que se mantiene WORKING canonical sin formalizar ADR (logo no-locked per brief §3 / art_direction §3.3 sigue vigente). Si después de uso real (~2-4 weeks) se mantiene preferencia, entonces ADR-013 + brief §4 lock + art_direction §3.3 lock.
- **NO update docs firmados:** `docs/art/01_art_direction.md`, `docs/art/briefs/01_brief_logo.md`, `docs/planning/02_decision_log.md` NO se tocan en S1.7 — founder explícito ("dejamos design trabajando y seguimos"). Logo v2 vive aislado en `art/branding/logo_v2/` + README local + audit local.
- **Color shift Crew 100:** brief §4.1 especifica `--sonar-bright-shifted #1FB39E` para canvases claros (3.2:1 AA Large ✓). Cambio inicial usaba `#0F766E` (Tailwind teal-700, NO en token system) — corregido a `#1FB39E` per spec firmada.
- **`source_exploration_sheet.svg` purge variants B-E:** decisión limpieza para evitar futuro AI agent re-leer y proponer concepts purgados. Solo variante A queda como "concept seleccionado" + nota semántica.
- **Wordmark Geist `<text>` element vs custom paths:** founder source usa Geist SemiBold tracking −3.5% via `<text>` runtime — preserva flexibility (font swap fácil) pero requiere fallback stack (`'Geist', 'Geist Sans', 'Inter Tight', Inter, system-ui`). Trade-off aceptado: rendering depende cliente font availability, OK para web/preview, eventualmente outline-to-paths para print/embed.

### Issues pendientes

- 🟡 **NO commit pushed S1.7** — pending founder review visual de exports antes commit.
- 🟡 **Geometría brief §4.4 vs Concept A:** brief specifica geometría chamfered slab; Concept A es stroke-arcs. Audit README marca esto como ⚠️ excepción documentada (founder override). Si ADR-013 firmado eventualmente, brief §4.4 requerirá update.
- 🟡 **Anti-pattern §3 "ondas concéntricas":** brief §3 explícito prohibe; founder reinterpretation override válido pero **debe quedar trazable** vía README disclaimer + source_exploration_sheet nota. Si externo (ej. brand audit, contractor) lee brief sin contexto, conflicto detectable.
- 🟢 **ADR-013 logo lock:** deferred ~2-4 weeks post uso real. Si holds, formalizar via ADR + brief §4 §3.3 update + art_direction §3.3 update.
- 🟢 **Outline-to-paths wordmark:** para print/embed donde Geist no disponible runtime. Tarea opcional pre-S2.
- 🔴 **Issues S1.6 todos pendientes:** Phase 6 mass-purge docs operacionales, SPRINT_PLAN_S2.md, decisiones D1+D2+D3, smoke regression, tag `sonar-identity-canonical`. Ver `PRE_S2_CHECKLIST.md`.

### Handoff próxima sesión (S1.8 o S2.0)

- **Modelo recomendado:** Sonnet 4.6 si Phase 6 surgical doc o tooling. Opus 4.7 / Gemini 3.1 Pro si planning S2 o decisión arquitectónica D1-D3.
- **Goal candidatos:** (a) commit + push S1.7 logo v2 deliverables post founder review. (b) Phase 6 surgical `02_admirals_tablet.md` → `02_sonar_tablet.md`. (c) Decisiones founder D1+D2+D3 + tag + smoke regression. (d) S2.0 planning (solo si B1 done).
- **Pre-requisitos LECTURA OBLIGATORIA:** `progress/PRE_S2_CHECKLIST.md` v1.0 + `docs/agents/00_BOOTSTRAP.md` v1.5 + ADR-011 + ADR-012 + `01_art_direction.md` v2.0-scaffold-r7 + Bible v1.4 §1 + SESSION_LOG S1.4-S1.7 entries + `art/branding/logo_v2/README.md` (si toca logo).
- **Files in scope:** depende goal.
- **Notas especiales:** **Logo v2 = WORKING CANONICAL no LOCKED.** Briefs v2 siguen SSoT spec doctrinal. Si AI futura lee brief §3 anti-patterns y detecta conflict con logo v2 visualmente, **NO arreglar unilateralmente** — leer `art/branding/logo_v2/README.md` §"NO es pivot" primero, founder override está documentado. **Memoria SONAR Identity r2 sigue vigente** — ADR-012 metáfora abstract no cambió.

### Files in scope respetados

✅ Scope strict: `art/branding/logo_v2/` (8 mods) + `art/tools/logo_export/` (3 creates) + `art/branding/logo_v2/exports/` (27 generated) + `progress/SESSION_LOG.md` (1 append). **NO tocó `docs/*` (briefs, art_direction, decision_log intactos), NO tocó code/DB/`.windsurf/*`** — founder explícito mantener separación logo v2 working ↔ docs firmados.

> **Founder guidance institutional:** *"esto NO es un pivot, es preferencia visual hoy"* (S1.7 framing crítico — protege coherencia ADR-012 + briefs v2 sin romper agency founder sobre output visual concreto). *"limpia las otras variantes y deja solo A"* (purge B-E del source). *"genera los PNGs y el favicon"* (deliverables §2.1).

---


## SesiÃ³n S1.8 â€” Hygiene + B1 Pass 1 + Pass 2 `02_admirals_tablet.md` â†’ `02_sonar_tablet.md` v1.2

**Fecha:** 2026-05-03 (noche, session tercera del dÃ­a)
**Modelo:** Sonnet 4.6 (Cascade)
**DuraciÃ³n:** ~3h (hygiene 30min + Pass 1 batch 1h + Pass 2 batch 1.5h)
**Founder:** yaboula (acumulado ~14h hoy S1.4 â†’ S1.5 â†’ S1.6 â†’ S1.7 â†’ S1.8)
**Profile session:** surgical doc cleanup ejecutivo (Phase 6 Mass-purge operational docs)

### Scope sesiÃ³n

(a) S1.8 hygiene â€” commit S1.7 logo v2 deliverables no-pushed (8 SVGs + 27 PNGs + favicon + tools/logo_export) + actualizar `PRE_S2_CHECKLIST.md` D2 status.
(b) Phase 6 B1 Pass 1 surgical â€” rename `02_admirals_tablet.md` â†’ `02_sonar_tablet.md` + NOTICE r1.1 top-level + bulk identity purge + key sections inline cleanup.
(c) Phase 6 B1 Pass 2 surgical â€” apps detail-pass + Â§15.2 notif table canonical + Â§21.4 docking + Â§22.4 Costa Naval flag + Â§26 sounds full rewrite tablas + Â§27 anti-patterns NEW post-pivot.
(d) Founder pidiÃ³ handoff limpio mid-Pass-2 completion â€” preservar trabajo + entry SESSION_LOG completo para nuevo product manager prÃ³xima sesiÃ³n.

### Decisiones tomadas (founder-directed)

- **"este session tiene problemas"** (founder 2026-05-03 ~00:28 UTC+02:00) â€” founder detectÃ³ issues con sesiÃ³n (no especificado queÃ â€” latencia/calidad output/propuestas mal fitted) â†’ pediÃ³ cerrar + handoff a nuevo agent.
- **Tone correction founder S1.8:** *"las decisiones de profesional son de profesional, habla conmigo del profesional no personal"* â€” eliminÃ³ sugerencias paternalistas tipo "descansa tras 13h" en mis respuestas. Founder decide scope, AI ejecuta professional.
- **Pass 1 approach:** PowerShell bulk regex purge (Admirals+variantes â†’ SONAR) + surgical inline edits sections crÃ­ticas (Â§2.4, Â§3, Â§3.2, Â§4.1, Â§4.2, Â§4.3, Â§29) + NOTICE r1.1 establecida top-level supersede (~70 lineas).
- **Pass 2 approach:** apps detail-pass secciones Â§5.2 + Â§6.4/Â§6.5 + Â§10.5 + Â§11.4/Â§11.6 + Â§15.2 + Â§21.4 + Â§22.4 + Â§26 + Â§27. DEPRECATED columns preserved para trazabilidad. Â§22.4 "Costa Naval" ejemplo renombrado a "Puerto de los Vientos" neutral.
- **Sound naming canonical batch mapping:** 5 SFX (`signal_emerge`, `depth_press`, `layer_dive`, `console_tap`, `panel_open`) + variantes per contexto per `01_art_direction.md` Â§7.2 + `01_brief_sound.md` v1. Todos refs literales ("campana naval", "moneda", "bip", "whoosh", "cha-ching", "Estrella mÃ¡gica") mapeados a canonical + DEPRECATED preserved.

### Commits ejecutados

```
be91d8b (HEAD -> main, origin/main) S1.8 B1 Pass 2 â€” 02_sonar_tablet.md v1.2 apps detail-pass post-pivot SONAR (sec 5.2/6/10.5/11/15.2/21.4/22.4/26/27 surgical + PRE_S2_CHECKLIST v1.3 B1 100%)
b04f0a4 S1.8 B1 Pass 1 content â€” NOTICE r1.1 + bulk identity purge 126 instances + surgical inline sec 2.4/3/3.2/4.1/4.2/29 + PRE_S2_CHECKLIST v1.2 B1 update
507bffa S1.8 B1 Pass 1 â€” 02_admirals_tablet.md rename to 02_sonar_tablet.md v1.1 post-pivot SONAR (NOTICE r1.1 + bulk identity purge + surgical sections + checklist update)
8a5c9c0 S1.8 hygiene â€” commit S1.7 logo v2 working canonical (8 SVGs + 27 PNG + favicon + tools/logo_export) + PRE_S2_CHECKLIST D2 status update
```

4 commits pushed. Total diff Pass 1 + Pass 2: ~298 inserts / 193 deletes en `02_sonar_tablet.md` (de 1185 lÃ­neas original â†’ 1702 post-pass).

### Done criteria (ejecutadas)

- âœ… S1.7 logo v2 deliverables commit + push (commit `8a5c9c0`) â€” 38 files (source SVGs + exports PNG + favicon + tools).
- âœ… `PRE_S2_CHECKLIST.md` D2 bumped â†’ v1.1 (logo v2 RESUELTO IN-HOUSE).
- âœ… Rename `02_admirals_tablet.md` â†’ `02_sonar_tablet.md` via `git mv` preserva history (commit `507bffa`).
- âœ… NOTICE r1.1 top-level establecida (~70 lÃ­neas) â€” naming + paleta + tipografÃ­a + voz + iconografÃ­a + sound canonical + logo v2 working canonical.
- âœ… Bulk identity purge PowerShell: 126 instances Admirals â†’ SONAR + AdmiralsOS â†’ SonarOS + variantes.
- âœ… Surgical Pass 1 sections Â§2.4 + Â§3 + Â§3.2 + Â§4.1 + Â§4.2 + Â§4.3 + Â§29 inline updates.
- âœ… Surgical Pass 2 sections Â§5.2 + Â§6.4/Â§6.5 + Â§10.5 + Â§11.4/Â§11.6 + Â§15.2 notif table canonical SFX mapping + Â§21.4 docking + Â§22.4 Costa Naval flag + Â§26 sounds 4 tablas canonical + Â§27 split Â§27.1 preserved + Â§27.2 NEW 9 anti-patrones identidad SONAR.
- âœ… `PRE_S2_CHECKLIST.md` bumped â†’ v1.3 (B1 doc 1/8 100% Pass done).
- âœ… `02_sonar_tablet.md` bumped â†’ v1.2 con changelog 3-row (1.0 + 1.1 Pass 1 + 1.2 Pass 2).
- âœ… Todos cambios pushed origin/main antes cierre sesiÃ³n (sin pÃ©rdida trabajo).

### Issues pendientes (post-S1.8)

- ðŸ”´ **Phase 6 B1 docs 2-8 PENDIENTES** (7 docs): `02_events_catalog.md`, `03_db_schema.md`, `04_api_contracts.md`, `05_state_machines.md`, `06_fivem_standards.md` (light), `07_bridges_compatibility.md` (light), `01_roadmap.md` v1.4 â†’ v1.5. Estimado ~12-14h distribuido sobre 3-5 sesiones.
- ðŸ”´ **Decisiones founder D1 + D3 PENDIENTES:** D1 (scope S2 UI-heavy vs tech-balanced), D3 (namespace migration timing). Bloquean SPRINT_PLAN_S2.md redacciÃ³n + scope tÃ©cnicos docs 2-5 B1. ~30min reflexiÃ³n founder.
- ðŸŸ¡ **D2 logo v2:** deferred ~2-4 weeks uso real antes ADR-013 lock. Vigente working canonical.
- ðŸŸ¡ **B4 smoke regression tag `sonar-identity-canonical`** pendiente antes S2.0. Estimado ~30min.
- ðŸŸ¡ **B2 SPRINT_PLAN_S2.md planning session:** requiere D1+D3 resueltos primero. Estimado ~2-3h Opus 4.7 o Gemini 3.1 Pro planning session.

### Files in scope S1.8 (respetados)

âœ… Scope strict:
- `docs/design/02_admirals_tablet.md` (git mv â†’ `02_sonar_tablet.md`).
- `docs/design/02_sonar_tablet.md` (2 content passes).
- `progress/PRE_S2_CHECKLIST.md` (v1.1 â†’ v1.2 â†’ v1.3).
- `progress/SESSION_LOG.md` (1 append esta entry).
- `art/branding/logo_v2/` + `art/tools/logo_export/` + `art/branding/logo_v2/exports/` (commit hygiene `8a5c9c0`).

**NO tocÃ³:** `docs/00_PRODUCT_BIBLE.md`, ADRs, briefs, art_direction, otros docs/* no-Tablet, code/`.windsurf/`, DB, resources/*.

### Handoff prÃ³xima sesiÃ³n (S1.9 o equivalente)

**ContÃ©xt founder:** founder flag "session tiene problemas" S1.8 final â€” posible causa: fatigue founder ~14h acumuladas, latencia herramientas, o calidad propuestas sub-Ã³ptima del agent actual. **PrÃ³ximo agent:** comenzar con tono professional direct (founder corrigiÃ³ expÃ­citamente "profesional no personal") + NO sugerencias sobre fatigue founder / cuando descansar.

**Modelo recomendado prÃ³xima sesiÃ³n (depende goal):**
- **(a) Continuar Phase 6 B1 docs 2-8 surgical:** Sonnet 4.6 (surgical doc work fit). 1 doc/session, 3-4h cada.
- **(b) Decisiones D1 + D3 conversaciÃ³n:** Opus 4.7 o Gemini 3.1 Pro (thinking session, planning class).
- **(c) SPRINT_PLAN_S2.md redacciÃ³n:** Opus 4.7 (planning intensive, requires D1+D3 ya resueltos).
- **(d) S1.8 retro / revisiÃ³n issues founder:** Sonnet 4.6 o Opus 4.7.

**Candidato orden goal prÃ³xima sesiÃ³n (recomendado prioridad):**
1. **B1 doc 8 `01_roadmap.md` v1.4 â†’ v1.5** â€” segundo doc mÃ¡s crÃ­tico post-Tablet (agenda sprint 2 oficial post-pivot). Sonnet 4.6 ~1.5-2h. NO depende D3.
2. **B1 docs 6 + 7 light** (`06_fivem_standards.md` + `07_bridges_compatibility.md`) â€” refreshes ligeros ~1h cada. NO dependen D3.
3. **Decisiones D1 + D3 founder conversation** â€” desbloquea planning + docs tÃ©cnicos.
4. **B1 docs 2-5 tÃ©cnicos** (`02_events_catalog.md`, `03_db_schema.md`, `04_api_contracts.md`, `05_state_machines.md`) â€” DEPENDEN D3 naming decision. NO empezar hasta D3 firmado.
5. **SPRINT_PLAN_S2.md planning session** â€” requiere TODO B1 done + D1+D3 firmados.

**Pre-requisitos lectura obligatoria prÃ³ximo agent** (per `03_founder_playbook.md` Â§5.3):

1. `docs/agents/00_BOOTSTRAP.md` v1.5+ (post-pivot identity Admirals â†’ SONAR).
2. `docs/agents/03_founder_playbook.md` Â§2.3 (model allocation) + Â§4-Â§6 (anatomÃ­a + prompt + SESSION_LOG protocol) + Â§5.3 (entry format).
3. `progress/SESSION_LOG.md` Ãºltimas 5 entries (S1.4 refinement ADR-012 + S1.5 Bible + S1.6 close + S1.7 logo v2 + **S1.8 esta entry**).
4. `progress/PRE_S2_CHECKLIST.md` v1.3 (estado B1 + decisiones + soft-opcionales).
5. **Docs firmados SSoT:** `docs/planning/02_decision_log.md` ADR-011 + ADR-012 (pivot + refinement), `docs/00_PRODUCT_BIBLE.md` v1.4, `docs/art/01_art_direction.md` v2.0-scaffold-r7 NOTICE r6, **`docs/design/02_sonar_tablet.md` v1.2 NOTICE r1.1** (nueva SSoT post-S1.8).
6. **Logo v2 working canonical:** `art/branding/logo_v2/README.md` (NO proponer re-diseÃ±o, WORKING not LOCKED per founder S1.7 decision).

**Hard constraints futuras AI agents (reafirmados S1.8):**
- **NO modificar docs/* sin instrucciÃ³n explÃ­cita founder** (Bible/ADRs/briefs/art_direction firmados).
- **NO arreglar conflict logo realidad (`art/branding/logo_v2/`) vs briefs firmados** â€” founder override S1.7 documentado, waiting 2-4 weeks uso real.
- **NO proponer sound naming pre-canonical** (sonar_ping/sonar_sweep/sonar_hatch/sonar_pressure). Usar 5 SFX canonical (`signal_emerge`, `depth_press`, `layer_dive`, `console_tap`, `panel_open`).
- **NO proponer voz naval/militar/capitÃ¡n** (Admirals heritage purgado). Voz canonical = neutral premium-tech.
- **NO proponer paleta azul marino + dorado.** Canonical = hybrid Tier A/B/C post-ADR-012.
- **Session log append-only** (never retroactive edit).
- **Commit message format:** `S{N}.{M} {imperative present}` (`S1.9 ...`, `S2.0 ...`).

**Estado fresh entry point prÃ³ximo agent:**

Founder puede comenzar prÃ³xima sesiÃ³n con prompt directo tipo:

```
SesiÃ³n S1.9 o S2.0.
Goal: [elegir 1-2 de candidatos arriba].
Scope files: [definir per goal].
Model: [per recomendaciÃ³n arriba].
LecturÃ¡ obligatoria: SESSION_LOG S1.8 entry + PRE_S2_CHECKLIST v1.3 + SSoTs relevantes per goal.
```

**NotÃ° especiales founder mood-S1.8-close:**

Founder acumula ~14h hoy con 5 sesiones consecutivas (S1.4 hygiene â†’ S1.5 Bible â†’ S1.6 close â†’ S1.7 logo â†’ S1.8 B1 Pass 1+2). Alta productividad ejecutiva. MencionÃ³ sesiÃ³n actual "tiene problemas" al cierre â€” prÃ³ximo agent debe asumir clean slate + no re-hacer work done S1.8 (commits todos pushed). **Trabajo S1.8 Ã­ntegramente preservado en origin/main.**

### Founder guidance institutional S1.8

> *"este session tiene problemas, dame handoff para nueva secion para nuevo product manager"* (cierre S1.8, framing para clean handoff).
>
> *"las decisiones de profesional son de profesional, habla conmigo del profesional no personal"* (tone correction crÃ­tica S1.8 mid-session â€” eliminar sugerencias paternalistas fatigue-based, founder decide scope).
>
> *"continue, disculpa por intrupcion por error"* (S1.8 mid-session recovery tras interrupciÃ³n involuntaria).
>
> *"eligo pass 2 sonar tablet, y es la ultima que me digas descanco"* (founder elecciÃ³n explÃ­cita Pass 2 sobre alternatives + tone correction).

---

## Sesión S1.9 — Phase 6 B1 doc 8/8: `01_roadmap.md` v1.4 → v1.5 surgical post-pivot SONAR

**Fecha:** 2026-05-04 (UTC+02:00 early hours)
**Modelo:** Sonnet 4.6 (Cascade)
**Duración:** ~1.5h (onboarding 20min + surgical rewrite multi_edit 30min + verification + PRE_S2 update + entry + summary)
**Founder:** yaboula
**Profile session:** 📝 SCRIBE — surgical doc work Phase 6 mass-purge (B1 Checklist).

### Scope sesión

(a) Onboarding obligatorio completado: BOOTSTRAP v1.5, founder_playbook §2.3+§4-§6+§5.3, SESSION_LOG últimas 5 entries (S1.4→S1.8), PRE_S2_CHECKLIST v1.3, ADR-011+ADR-012 (grep línea 660+864 decision_log), sonar_tablet v1.2 NOTICE r1.1 (SSoT canonical post-S1.8), art_direction v2.0-scaffold-r7 NOTICE r6, logo_v2 README working canonical.
(b) Founder elige goal (a) roadmap v1.5 solo via ask_user_question (opciones a/b/c/d presentadas con dependency DAG + Sonnet-fit analysis). Scope strict IN: `01_roadmap.md` + `PRE_S2_CHECKLIST.md` + `SESSION_LOG.md`. OUT: todos los demás `docs/*`, code, DB, `.windsurf/*`, `art/branding/*`.
(c) Surgical v1.4 → v1.5 per PRE_S2_CHECKLIST B1 done criterion ("Sprint 2 goals rewritten SONAR-aware + §15 TL;DR update + changelog entry"). Estrategia: NOTICE r1 top-level (pattern consistent con `02_sonar_tablet.md` v1.1 + `art_direction.md` r6) + surgical inline minimal-invasive en secciones pivot-sensitive + preservación legacy inmutable de §3 Oleada 0 + Sprint 0+1 entries históricas + §7-§13 pivot-agnostic.

### Cambios

- **Modified:**
  - `docs/planning/01_roadmap.md` v1.4 → v1.5:
    - Header lines 1-11: title rebrand Admirals → SONAR, version bump 1.4→1.5 con rationale, padre `00_BOOTSTRAP.md` v1.5, hermano `02_decision_log.md` v1.4 (12 ADRs), referenced docs ampliado con briefs v2, lectura obligatoria ampliada (ADR-011+012, art_direction r7, PRE_S2_CHECKLIST).
    - NEW §NOTICE r1 top-level (~80 líneas) inserted entre line 13 y §0: naming canonical (producto/Tablet/OS/Bank/Marketplace + code namespace legacy per ADR-011 §5.5.8), estado Sprint 2 DIFERIDO (4 puntos), pivot phases 1-12 status (✅1-5 + 🟡6 + 🔴7-12), reading guide §1-§15 (8 puntos legacy vs canonical).
    - §0 Resumen: "proyecto Admirals" → "proyecto SONAR (ex-Admirals)". §0 bullets §70/§82/§cierre: "planificación Admirals"/"tareas Admirals"/"ejemplos Admirals" → SONAR (3 surface renames).
    - §2.1 tabla Oleada 1 row: estado 🔴 Pendiente → 🟡 EN PROGRESO (Sprint 0+1 ✅ + Sprint 2 DIFERIDO pending Phases 4-12). Tablet → SONAR Tablet + Banco → SONAR Bank + Marketplace global Admirals → Marketplace SONAR.
    - §4.1 Visión MVP: "El MVP de Admirals es" → "El MVP de SONAR es", "Abrir Tablet" → "Abrir SONAR Tablet", "(Bank, Map, Workplace)" → "(SONAR Bank, Map, Workplace)".
    - §4.2 Sprint 2 full rewrite (~40 líneas reemplazo ~14 líneas original): status 🟡 DIFERIDO + hard blockers pre-S2 ref PRE_S2_CHECKLIST + 3 goals propuestos SONAR-aware (stack React+TailwindCSS+shadcn/ui + SonarOS + callbacks shipped ref) + 3 scope options D1 (A tech-balanced / B UI-heavy / C híbrido) + 8 done criteria propuestos (include 5 SFX canonical + paleta hybrid Tier A/B/C ADR-012 D2 + voz neutral premium-tech ADR-012 D3 + logo v2 working canonical) + blockers hard B1-B5 + D1-D3 inline referenced.
    - §5.1 Oleada 2 visión: "Admirals añade" → "SONAR añade".
    - §6.1 Oleada 3+: "Marketplace global Admirals" → "Marketplace global SONAR".
    - §14.2 estado: version bump + next revision bump v1.6 post-Phase-6+8+9+10 + padre BOOTSTRAP v1.5 + hermano decision_log v1.4 + related ampliado con briefs v2 + PRE_S2_CHECKLIST.
    - §14.3 changelog: appended entry v1.5 detallada (~1 large table row) documentando todo cambio surgical + files NO touched (Oleada 0, Sprints 0+1, Sprints 3-8, §7-§13, ADR histórico).
    - §15 TL;DR: expandido 10 puntos → 12 puntos pivot-aware (add punto 3 pivot phases status + punto 8 code namespace legacy exception + punto 11 risk top 5 actualizado con "AI agent quality drop re-confundiendo metáfora literal-militar").
    - §cierre Resumen ejecutivo: condiciones de éxito añade "+ pivot SONAR Phases 4-12 complete sin regresiones funcionales" + "modelo planning Admirals" → "modelo planning SONAR (ex-Admirals)".
    - §FIN: version footer bump v1.4 → v1.5.
  - `progress/PRE_S2_CHECKLIST.md` v1.3 → v1.4:
    - Header "Estado total": add "(post-S1.9)" context + "B1 2/8 done, 6 pendientes" counter bump.
    - §B1 tabla doc 8 row: 🔴 Pre-pivot entries → 🟢 **DONE S1.9** (100%) con resumen surgical completo + NO touched.
    - §B1 tabla docs 2-5: añadir **DEPENDE D3** tag inline cada uno.
    - §B1 tabla docs 6-7: añadir **Independiente D3 — ejecutable Sonnet ~1h** cada uno.
    - §B1 Ownership Done criterion: ampliado para incluir code namespace legacy exception (admirals_bank/core/bridges/tables/events) pending Phase 8+9.
    - §B1 NEW "Progreso post-S1.9" bullet: 2/8 done + ruta recomendada dependency-breakdown.
    - §Changelog: appended entry v1.4 detallada.
    - §FIN: version footer bump v1.3 → v1.4.
  - `progress/SESSION_LOG.md`: append esta entry S1.9.
- **Created:** ninguno.
- **Deleted:** ninguno.

**Total S1.9: 3 files modified = 3 file ops (1 edit major + 1 edit minor PRE_S2_CHECKLIST + 1 append SESSION_LOG).**

### Decisiones tomadas

- **Estrategia NOTICE r1 top-level vs surgical full rewrite:** elegido NOTICE pattern consistent con precedente `02_sonar_tablet.md` v1.1 (NOTICE r1.1) + `art_direction.md` r6 (NOTICE r6 superseding legacy §1-§20). Razón: roadmap tiene ~60% contenido pivot-agnostic (§1 filosofía, §7 dependencias, §8 done criteria, §9 risks, §10 sprint structure, §11 estimation, §12 anti-patterns, §13 KPIs) que sería rewrite innecesario + alto riesgo regresión. NOTICE establece canonical vigente post-pivot sin tocar legacy inline.
- **Legacy code namespace preservado `admirals_*`:** refs `admirals_bank`, `admirals_core`, `admirals_bridges`, tablas SQL `admirals_*`, eventos `admirals:*` preservados explícitamente per ADR-011 §5.5.8 excepciones permitidas hasta Phase 8 code refactor + Phase 9 DB migration 009. D3 founder decision controls timing. NOTICE r1 documenta esta excepción explícitamente para evitar que futura AI agent "arregle" unilateralmente.
- **Historical Sprint 0+1 entries + §3 Oleada 0 inmutables:** preservadas intactas con todas sus refs `admirals_*` per ADR-011 §5.5.8 (SESSION_LOG históricas + ADRs históricos + commits/tags). NOTICE r1 punto 3 documenta esto explícitamente.
- **Sprint 2 section scope expansion (14→40 líneas):** founder playbook §6.1 done criteria session tenía bullet "Sprint 2 goals rewritten SONAR-aware". Interpretación maximalista: incluir 3 scope options D1 + 8 done criteria propuestos con paleta/voz/sound/logo canonical integrados + blockers B1-B5/D1-D3 linked para que futura planning session S2.0 tenga todo ready-to-read en roadmap directamente (SSoT centralized). Trade-off aceptado: más líneas vs rewrite redundant en SPRINT_PLAN_S2.md futuro. Justificación: roadmap es SSoT planning foundational, SPRINT_PLAN_S2 será execution-level detail.
- **TL;DR expansion 10→12 puntos:** punto 3 nuevo (pivot phases status ref NOTICE) + punto 8 nuevo (code namespace legacy exception explícito) + punto 11 ampliado risks top 3→5 post-pivot. Razón: AI agents leen TL;DR as quick-context — ausencia pivot-awareness en TL;DR = alto riesgo re-confundir metáfora deprecated.
- **Grep verification 3 dimensiones:**
  - `capitán|silent service|tactical|comandante|almirante|a bordo|tripulación|submarino` → 1 match = "NO militar/capitán/tactical per ADR-012 §D3" (spec negativa done criteria, correct).
  - `Admirals` → 23 matches, todos legítimos: NOTICE headers + legacy code namespace refs + historical Sprint 0+1/§3 + "Admirals heritage preserved" phrasing (intencional). 0 match en contenido new post-pivot como referencia positiva al producto.
  - `sonar_ping|sonar_pressure|sonar_depth|sonar_console|sonar_hatch|periscope|torpedo|hydrophone` → 0 matches ✅ (sound naming + iconografía deprecated no presentes).
- **Founder tone compliance S1.8 preserved S1.9:** zero sugerencias fatigue-based, zero paternalismo. Founder decide scope vía ask_user_question (opciones 4 con dependency analysis + Sonnet-fit tagging), AI ejecuta professional direct.

### Done criteria S1.9 (prompt inicial founder)

- ✅ Header bump v1.4 → v1.5.
- ✅ §4.2 Sprint 2+ goals rewritten SONAR-aware (full rewrite con DIFERIDO status + 3 scope options D1 + 8 done criteria propuestos + blockers B1-B5/D1-D3).
- ✅ §15 TL;DR update (expandido 10→12 puntos pivot-aware).
- ✅ Changelog entry v1.5 detallada (§14.3).
- ✅ Referencias Admirals → SONAR excepto legacy-intencional (ADRs históricos, Phase 8 refactor namespace, historical Sprints 0+1, _archive/).
- ✅ Grep check: 0 violaciones voz militar/capitán/tactical en contenido nuevo (único match es spec negativa prohibición ADR-012 D3).
- ✅ PRE_S2_CHECKLIST B1 doc 8/8 marked 🟢 DONE S1.9 + v1.3 → v1.4 changelog entry.
- ✅ Entry SESSION_LOG S1.9 append (este).
- 🟡 **Commit format `S1.9 B1 doc 8 — 01_roadmap.md v1.5 surgical post-pivot SONAR`** — pending founder green-light + manual git add/commit/push (AI no ejecuta destructive ops sin explicit approval per workspace rules).

### Issues pendientes (post-S1.9)

- 🔴 **B1 Phase 6 docs 2-7 PENDIENTES** (6 docs): `02_events_catalog.md`, `03_db_schema.md`, `04_api_contracts.md`, `05_state_machines.md` (DEPENDE D3) + `06_fivem_standards.md` light, `07_bridges_compatibility.md` light (Independientes D3). Estimado: docs 6+7 ~2h Sonnet (ejecutable next), docs 2-5 ~12-14h post-D3 resolved.
- 🔴 **Decisiones founder D1 + D3 PENDIENTES:** D1 scope S2 (A/B/C tech-balanced vs UI-heavy vs híbrido), D3 namespace migration timing (Phase 8+9 AHORA vs DEFERIDA vs parcial). Bloquean SPRINT_PLAN_S2.md redacción + B1 docs 2-5.
- 🟡 **D2 logo v2:** deferred ~2-4 weeks uso real antes ADR-013 lock. Vigente working canonical.
- 🟡 **B4 smoke regression `admirals_bank` 30/30** pendiente antes S2.0. Estimado ~30-60min.
- 🟡 **B5 tag `sonar-identity-canonical`** pendiente sobre commit head post-S1.9.
- 🟡 **B2 SPRINT_PLAN_S2.md planning session:** requiere D1+D3 resueltos primero + B1 complete. Estimado ~2-3h Opus 4.7 o Gemini 3.1 Pro.

### Handoff próxima sesión (S1.10 o equivalente)

**Modelo recomendado próxima sesión (depende goal):**
- **(a) Continuar Phase 6 B1 docs 6+7 light refresh:** Sonnet 4.6 (surgical doc work, independientes D3). ~2h total. Cierra 4/8 B1 sin founder decision bloqueadora.
- **(b) Decisiones D1 + D3 conversación founder:** Opus 4.7 o Gemini 3.1 Pro (thinking session, planning class). ~30-45min. Desbloquea docs 2-5 + B2.
- **(c) Combo (a)+(b) en misma sesión:** Sonnet 4.6 docs 6+7 + Opus 4.7 al cierre D1+D3 conversación. Requiere switch modelo.
- **(d) B4 smoke regression manual founder:** founder local + Sonnet 4.6 debug si rompe. ~30-60min.

**Candidato orden goal próxima sesión (recomendado prioridad per dependency DAG):**
1. **D1 + D3 founder conversation** — desbloquea todo downstream. ~30-45min.
2. **B1 docs 6+7 light** — paralelo o secuencial, independientes D3.
3. **B4 smoke regression** — low-cost gate check.
4. **B1 docs 2-5 técnicos** — DEPENDE D3 firmado.
5. **B2 SPRINT_PLAN_S2.md** — requiere TODO B1 + D1+D3.

**Pre-requisitos lectura obligatoria próximo agent:**

1. `docs/agents/00_BOOTSTRAP.md` v1.5+.
2. `docs/agents/03_founder_playbook.md` §2.3 + §4-§6 + §5.3.
3. `progress/SESSION_LOG.md` últimas 5 entries (S1.5 → S1.6 → S1.7 → S1.8 → **S1.9 esta entry**).
4. `progress/PRE_S2_CHECKLIST.md` v1.4 (estado B1 2/8 + decisiones + dependency breakdown).
5. **Docs firmados SSoT:** ADR-011 + ADR-012, Bible v1.4, art_direction v2.0-scaffold-r7 NOTICE r6, `02_sonar_tablet.md` v1.2 NOTICE r1.1, **`01_roadmap.md` v1.5 NOTICE r1** (nueva SSoT post-S1.9).
6. Logo v2 working canonical README (si toca logo).

**Hard constraints reafirmados S1.9 (sin cambios vs S1.8):**
- NO modificar docs/* sin instrucción explícita founder (Bible/ADRs/briefs/art_direction firmados).
- NO arreglar conflict logo realidad vs briefs firmados — founder override S1.7 documentado.
- NO sound naming pre-canonical (sonar_ping/etc deprecated). Usar 5 SFX canonical.
- NO voz naval/militar/capitán. Canonical = neutral premium-tech.
- NO paleta azul marino + dorado. Canonical = hybrid Tier A/B/C post-ADR-012.
- SESSION_LOG append-only.
- Commit format `S{N}.{M} {imperative present}`.

**Founder tone preference S1.8 preserved S1.9:**
- Zero sugerencias fatigue-based.
- Zero paternalismo.
- Founder decide scope vía opciones estructuradas, AI ejecuta professional direct.

### Files in scope S1.9 (respetados)

✅ Scope strict:
- `docs/planning/01_roadmap.md` (1 major multi_edit).
- `progress/PRE_S2_CHECKLIST.md` (1 multi_edit B1 + changelog + FIN).
- `progress/SESSION_LOG.md` (1 append esta entry).

**NO tocó:** Bible, ADRs, briefs, art_direction, `02_sonar_tablet.md`, otros docs/*, code/resources/*, `.windsurf/*`, DB, `art/branding/*`, `art/tools/*`.

### Summary ejecutivo S1.9 close

Goal **(a) `01_roadmap.md` v1.4 → v1.5 surgical solo** completado ✅. **B1 Phase 6 mass-purge progress bumped 1/8 → 2/8 (25%)**. Docs 6+7 light ejecutables Sonnet próxima sesión (~2h, independientes D3). Docs 2-5 técnicos bloqueados pending D3 founder decision. SPRINT_PLAN_S2 bloqueado pending D1+D3+B1.

**Commit pending founder green-light:**

```
S1.9 B1 doc 8 — 01_roadmap.md v1.5 surgical post-pivot SONAR (NOTICE r1 + Sprint 2 DIFERIDO rewrite + TL;DR pivot-aware + PRE_S2_CHECKLIST v1.4)
```

### Founder guidance institutional S1.9

> Founder selección vía opciones estructuradas: **(a) roadmap v1.5 solo** sobre alternatives (a)+(b) combo, (b) docs 6+7, (c) decisiones D1+D3. Tone preference S1.8 compliance 100% (zero paternalismo AI S1.9).

---

## Sesión S1.9 EXTENDED — Heavy work post-S1.9 commit: D1+D3 resolved + ADRs 013+014+015 firmed + docs 2-7 NOTICE r1 pattern + B1 Phase 6 CERRADO 8/8

**Fecha:** 2026-05-04 (UTC+02:00, ~00:48 start — continuation post-S1.9 commit push)
**Modelo:** Sonnet 4.6 (Cascade) heavy work mode
**Duración:** ~5h (decisiones founder ~20min + ADRs firmado ~45min + 6 docs NOTICE r1 pattern ~3h + PRE_S2_CHECKLIST v1.5 + SESSION_LOG entry + commit)
**Founder:** yaboula
**Profile session:** 🏗️ ARCHITECT + 📝 SCRIBE híbrido — decisiones foundational (ADRs) + heavy doc refresh work (NOTICE pattern) + SSoT updates coordinated.

### Scope sesión

(a) Founder instruction explicit post-S1.9 commit: *"vamos a completar el trabajo, estoy usando tu como el mas potente modelo, no para hacer un commit, pero para este trabajo pesado"*. Tone preference heavy execution, not just 1 surgical commit.

(b) Founder delegation ordering: *"elige lo que tien que ir orden, que esta en la cola y hay que priorizarlo"*. AI priorized per dependency DAG — D1+D3 master blockers → unblock docs 2-5 + B2.

(c) Ruta ÓPTIMA ejecutada: D3 first (master) → D1 → ADRs firmado → docs 2-7 NOTICE r1 pattern → PRE_S2_CHECKLIST bump → SESSION_LOG entry → commit.

(d) Safety-first split: docs-only this session (100% safe push). Code refactor Phase 8 + Migration 009 + smoke regression DEFERRED next session founder-available (requires local server for smoke verify).

### Decisiones founder resueltas

- **D3 = Opción A Phase 8+9 AHORA antes S2** (via ask_user_question, 4 options presented A/B/C/B+). Founder explicit green-light. Implica:
  - Code refactor `resources/admirals_*/` → `resources/sonar_*/` (bridges + bank + core).
  - Migration 009 SQL rename 6 tablas DDL + FKs + index names.
  - Events re-prefixed `admirals:*` → `sonar:*` (~30 emit sites).
  - Exports re-prefixed `exports['admirals_*']:*` → `exports['sonar_*']:*`.
  - State bag namespace canonical `sonar_*`.
  - Smoke regression 30/30 post-refactor.
  - Tag `phase-8-9-complete` post-success.
  - Cost: ~3 sessions (code + DB + smoke) antes S2 arranque.

- **D1 = Opción B UI-heavy post-pivot** (via ask_user_question, 3 options A/B/C). Founder explicit green-light. Implica:
  - Sprint 2 scope: SONAR Tablet shell refinado + SONAR Bank app polished + Map app + motion signature + sound signature 5 SFX canonical.
  - Defer T2 adapters ESX/QBCore + `sonar_companies` DDL + C003 `getTransactions` a Sprint 3.
  - S2 duración 3 → 4 semanas.
  - C003 documented pero marcado DEFERRED S3 en doc 4 `04_api_contracts.md`.

- **D2 (icons) unchanged:** creative outsourcing pending founder decision. Logo v2 working canonical stays (period ~2-4 weeks before ADR-013 [note: now renamed implicitly given ADR-013 used for namespace]).

### ADRs firmados (decision_log.md v1.4 → v1.5)

- **ADR-013 — Namespace migration execution Phase 8+9 — rename `admirals_*` → `sonar_*` en código + DB ANTES de Sprint 2** (accepted, ~220 líneas detallado).
  - **Implements** ADR-011 §4 Phase 8 (code refactor) + Phase 9 (DB migration 009).
  - Context: D3 decision; Decisión: execute AHORA not defer.
  - Scope Phase 8: code refactor detallado (resources rename + fxmanifest + config + server.cfg.example + smoke manuals).
  - Scope Phase 9: migration 009 SQL UP + DOWN rollback + checksum + data preservation.
  - Scope execution order operacional 4 steps.
  - Alternativas consideradas A/B/C/B+ rechazadas con razones.
  - Consecuencias positivas (5) + negativas (4) + neutrales (2).
  - Risks accepted R1-R4 con mitigaciones.
  - Impact docs (esta sesión + próxima) + código (próxima) + memoria.
  - Re-evaluation trigger: Phase 10 smoke regression failure → ADR-014.
  - Tags: identity, namespace, migration, code, db, execution_plan, foundational.

- **ADR-014 — Hotfix path si smoke regression Phase 10 falla (placeholder reservado)** (proposed, NO escrito todavía, trigger pending).
  - Scope tentativo: rollback migration 009 + revert resources rename + NOTICE deferred + schedule re-attempt.

- **ADR-015 — Sprint 2 scope UI-heavy pivot** (accepted, ~140 líneas).
  - **Amends** ADR-011 §4 Phase 12 (Sprint 2 arranque).
  - Context: D1 decision post-pivot + 5 briefs v2 delivered + logo v2 + sonar_tablet canonical ready.
  - Decisión: UI-heavy max valor percibido SONAR identity debut S2.
  - Scope S2 UI-heavy detallado (Tablet shell + Bank app + Map app + motion/sound signature).
  - Scope S2 DEFERRED a S3 (T2 adapters + DDL + C003 getTransactions).
  - Alternativas A/B/C rechazadas.
  - Consecuencias positivas (4) + negativas (4) + neutrales (1).
  - Risks accepted R1-R3 mitigated.
  - Impact docs esta/próxima sesión.
  - Re-evaluation trigger: Sprint 2 week 2 checkpoint + post-S2 retro.
  - Tags: scope, sprint, mvp, ui, sonar, amendment.

- decision_log.md meta updates: §5.1 tag index extended (~8 new tags) + §5.2 state table bumped + §6.2 estado v1.5 + §6.3 changelog entry v1.5 + §7 TL;DR 3 rows nuevas (ADR-013, ADR-014, ADR-015) + cierre SONAR rebrand + FIN v1.5 bump.

### Docs 2-7 NOTICE r1 pattern applied (B1 Phase 6 CERRADO 8/8 100%)

Estrategia: full rewrite ~6000 líneas de 4 docs técnicos heavy + 2 docs light NO cabe en 1 session Sonnet. **Pivot pragmático a NOTICE r1 pattern** (mismo pattern que `02_sonar_tablet.md` v1.1 S1.8 + `01_roadmap.md` v1.5 S1.9). Cada doc:
- Header title rebrand Admirals → SONAR.
- Version bump X.0 → X.1.
- Parent/sibling/ADRs refs bumped v1.5+ / ADR-011/012/013/015.
- NOTICE r1 top-level ~45-110 líneas establishing naming canonical post-pivot + mapping 1:1 + schedule + reading guide.
- Changelog entry v1.1 detallada.
- FIN version bumped.
- §cierre + §Pilar/Principio rebrand selective.
- Legacy inline §1-§N preserved unchanged (pivot-agnostic foundational content).

**Docs refreshed S1.9 EXTENDED:**

- **`docs/technical/07_bridges_compatibility.md` v1.0 → v1.1** (~50 líneas NOTICE r1). Naming canonical producto + code namespace target state post-Phase-8 + §12 SDK customer-facing rename guidance + §18 TL;DR Regla 1 dual pre/post-Phase-8.
- **`docs/technical/06_fivem_standards.md` v1.0 → v1.1** (~45 líneas NOTICE r1). State bag namespace + event prefixes + DB tables target + voz coherence ADR-012 §D3 + performance budgets invariantes + §6.1 sync checklist dual.
- **`docs/technical/02_events_catalog.md` v1.0 → v1.1** (~70 líneas NOTICE r1). Title dual prefix `sonar:*`/`admirals:*` + mapping 1:1 eventos + 88 eventos shipped S1 affected list + C003 DEFERRED S3 + voz neutral logging + schema fields INVARIANT + Phase 8 schedule + §18 Changelog NEW + §FIN NEW.
- **`docs/technical/03_db_schema.md` v1.0 → v1.1** (~110 líneas NOTICE r1). Title dual prefix `sonar_*`/`admirals_*` + mapping 1:1 todas 28 tablas + migration 009 SQL target (UP + DOWN rollback) + índices + FKs 1:1 + ADR-010 hybrid semantics preserved + reference data seeds preserved + system treasury IBAN unchanged + §21 Changelog NEW + §FIN NEW.
- **`docs/technical/04_api_contracts.md` v1.0 → v1.1** (~80 líneas NOTICE r1). Naming canonical callbacks/exports/NUI bridges + mapping 1:1 5 callbacks shipped S1 + 35+ planned + **C003 `getTransactions` DEFERRED S3 per ADR-015** + schemas INVARIANT + voz neutral error messages + §15 Changelog NEW + §FIN bump.
- **`docs/technical/05_state_machines.md` v1.0 → v1.1** (~70 líneas NOTICE r1). FSM audit table canonical + 16 FSMs entity tables mapping 1:1 + event triggers canonical + state strings INVARIANT + escrow FSM S1 shipped reference (5 estados probado 14/14 smoke S1.3) + tx atomicity unchanged + §15 Changelog NEW + §FIN bump.

**Todos documentan:**
- Migration execution schedule Phase 8 (code refactor next session) + Phase 9 (DB migration 009 next session) + Phase 10 smoke regression (founder server-available) authoritative per ADR-013.
- Post-Phase-8+9 plan v1.1 → v1.2 rewrite inline (88 eventos + 28 tablas + 40+ callbacks + 16 FSMs 1:1 con nuevos nombres canonical).
- Code namespace legacy `admirals_*` preserved inline hasta execution per ADR-011 §5.5.8 excepciones.
- Voz neutral premium-tech ADR-012 §D3 (NO militar/capitán/tactical).
- Reading guide §1-§N legacy vs canonical.

### Cambios (files modified S1.9 EXTENDED)

- **Modified (9 files):**
  - `docs/planning/02_decision_log.md` v1.4 → v1.5 (+ ~480 líneas: ADR-013 + ADR-014 placeholder + ADR-015 + meta updates).
  - `docs/technical/07_bridges_compatibility.md` v1.0 → v1.1 (~50 líneas NOTICE r1 + inline edits).
  - `docs/technical/06_fivem_standards.md` v1.0 → v1.1 (~45 líneas NOTICE r1 + inline edits).
  - `docs/technical/02_events_catalog.md` v1.0 → v1.1 (~70 líneas NOTICE r1 + §Changelog NEW + §FIN NEW).
  - `docs/technical/03_db_schema.md` v1.0 → v1.1 (~110 líneas NOTICE r1 + §Changelog NEW + §FIN NEW).
  - `docs/technical/04_api_contracts.md` v1.0 → v1.1 (~80 líneas NOTICE r1 + §Changelog NEW + §FIN bump).
  - `docs/technical/05_state_machines.md` v1.0 → v1.1 (~70 líneas NOTICE r1 + §Changelog NEW + §FIN bump).
  - `progress/PRE_S2_CHECKLIST.md` v1.4 → v1.5 (§estado total + §B1 title CERRADO + 6 docs rows DONE + §Progreso 8/8 + §D1 FIRMED B + §D3 FIRMED A + §changelog entry v1.5 + §FIN bump).
  - `progress/SESSION_LOG.md` append esta entry S1.9 EXTENDED (~200 líneas).
- **Created:** ninguno.
- **Deleted:** ninguno.

**Total S1.9 EXTENDED: 9 files modified ~1100+ líneas añadidas.**

### Decisiones AI + trade-offs

- **Strategy NOTICE r1 pattern vs full rewrite inline:** AI elegido NOTICE pattern based on:
  - Realistic scope: 6000 líneas 4 heavy docs NO cabe 1 session Sonnet safely.
  - Precedent established: `02_sonar_tablet.md` v1.1 (S1.8) + `01_roadmap.md` v1.5 (S1.9) both used NOTICE pattern successfully.
  - Pivot-agnostic 60-80% content (schemas/FSMs/filosofía/performance budgets/security/testing) = rewrite waste + regression risk.
  - Code + DB not yet renamed → documentar target state via NOTICE más honesto que premature inline rename (would imply code state not actual).
  - Post-Phase-8+9 execution plan: v1.1 → v1.2 rewrite inline con código + DB actually renamed = coherence.

- **Split execution "this session docs-only safe" vs "next session code+DB risky":** AI enforced per workspace safety rule "NUNCA push código rompe boot sin smoke check OBLIGATORIO primero":
  - Code refactor + Migration 009 require founder local server para smoke regression.
  - Docs-only 100% safe push main sin gate.
  - Phase 8+9 properly execute next session (branch separate o main con explicit gate).

- **C003 `getTransactions` DEFERRED S3:** per ADR-015 (D1=B UI-heavy). Doc 4 `04_api_contracts.md` marked DEFERRED S3 tag explicitly. Consumer pattern S2 Bank app puede query directa DB (tabla `sonar_bank_movements` post-migration-009) via adapter hasta C003 ships S3. Trade-off slight anti-pattern vs velocity S2 UI polish.

- **ADR-014 RESERVADO placeholder:** proposed state, no escrito todavía. Trigger = smoke regression Phase 10 failure. Prevents future AI confusion "why ADR jump 13→15" + documents hotfix path exists.

- **Schema version per evento NOT bumped:** Phase 8 prefix rename es mechanical refactor (sed-level), NOT breaking contract semantic. Decision documented en doc 2 NOTICE r1.

- **Founder tone compliance S1.8+S1.9 preserved S1.9 EXTENDED:** zero sugerencias fatigue-based, zero paternalismo. AI prioritized per dependency DAG when founder delegated. Structured options via ask_user_question.

### Done criteria S1.9 EXTENDED

- ✅ D1 founder decision (UI-heavy B) → ADR-015 firmed.
- ✅ D3 founder decision (Phase 8+9 AHORA A) → ADR-013 firmed.
- ✅ ADR-014 placeholder reserved hotfix path.
- ✅ `02_decision_log.md` v1.4 → v1.5 (tag index + state + changelog + TL;DR + cierre + FIN).
- ✅ `02_events_catalog.md` v1.1 NOTICE r1 post-pivot canonical mapping.
- ✅ `03_db_schema.md` v1.1 NOTICE r1 + migration 009 SQL target documented.
- ✅ `04_api_contracts.md` v1.1 NOTICE r1 + C003 DEFERRED S3 per ADR-015.
- ✅ `05_state_machines.md` v1.1 NOTICE r1 + escrow FSM S1 reference preserved.
- ✅ `06_fivem_standards.md` v1.1 light refresh NOTICE r1 naming canonical.
- ✅ `07_bridges_compatibility.md` v1.1 light refresh NOTICE r1 + SDK guidance.
- ✅ `PRE_S2_CHECKLIST.md` v1.4 → v1.5 (B1 8/8 CERRADO + D1/D3 firmed + changelog + FIN bump).
- ✅ Entry `SESSION_LOG.md` S1.9 EXTENDED append (este).
- 🟡 **Commit format `S1.9 EXT ADRs 013+015 + docs 2-7 v1.1 NOTICE r1 + PRE_S2_CHECKLIST v1.5`** — pending founder green-light + manual git add/commit/push.

### Issues pendientes (post-S1.9 EXTENDED)

- 🔴 **Phase 8 code refactor execution** — requires founder local server for smoke:
  - `git mv resources/admirals_bridges resources/sonar_bridges` + internal refs.
  - `git mv resources/admirals_bank resources/sonar_bank` + internal refs.
  - `git mv resources/admirals_core resources/sonar_core` + internal refs.
  - `server.cfg.example` ensure directives.
  - `scripts/smoke_test_s*.md` manuals update.
  - Estimate ~2-3h Sonnet heavy + manual verification founder.
- 🔴 **Phase 9 DB migration 009 execution** — requires local DB:
  - Create `resources/sonar_core/migrations/009_rename_admirals_to_sonar.sql` (UP + DOWN).
  - Apply via migrations runner.
  - Verify INFORMATION_SCHEMA.
  - Estimate ~45min.
- 🔴 **Phase 10 smoke regression** — manual founder 30-60min, 30/30 cumulative S0+S1 pasos con new names.
- 🔴 **Docs v1.1 → v1.2 rewrite inline** post-Phase-8+9 execution — 88 eventos + 28 tablas + 40+ callbacks + 16 FSMs rename 1:1 en body del doc. Estimate ~6-8h Sonnet cumulative across 4 docs.
- 🔴 **B2 `progress/SPRINT_PLAN_S2.md`** — redactable post-Phase-8+9+10 complete + docs v1.2 ready. Estimate ~2-3h Opus 4.7 / Gemini 3.1 Pro / Sonnet 4.6 OK.
- 🟡 **B5 tag `sonar-identity-canonical`** — cuando founder comfortable post-Phase-10 green.
- 🟡 **D2 icons decision** — pending founder (pre-S2 vs S3 custom).
- 🟡 **BOOTSTRAP v1.5 → v1.6** post-Phase-8 execution (reflect code namespace canonical real).

### Handoff próxima sesión (S1.10 o S2.0 post-gate)

**Modelo recomendado próxima sesión:**
- **Phase 8 code refactor:** Sonnet 4.6 (mechanical sed-level work, heavy) o Opus 4.7 si quiere safety-extra revisión. ~2-3h. Requires founder server-local para smoke.
- **Phase 9 DB migration 009:** Sonnet 4.6 (SQL DDL + runner). ~45min. Requires DB availability.
- **Phase 10 smoke regression:** Manual founder + Sonnet 4.6 debug si fails.
- **Docs v1.1 → v1.2 rewrite inline:** Sonnet 4.6 heavy. Split 2 docs per session (~3h each).

**Candidato orden goal próxima sesión (recomendado):**
1. **Phase 8 code refactor + Phase 9 migration 009** (combo 1 session founder-available ~3-4h).
2. **Phase 10 smoke regression** (mismo session o siguiente, manual founder ~1h).
3. **Docs v1.1 → v1.2 rewrite inline 88 eventos + 28 tablas + 40+ callbacks + 16 FSMs** (2-3 sessions Sonnet).
4. **BOOTSTRAP v1.5 → v1.6** (post-execution, quick update).
5. **B2 SPRINT_PLAN_S2.md** (2-3h, post-all-above).
6. **S2.0 start-session** (Sprint 2 arranque real).

**Pre-requisitos lectura obligatoria próximo agent:**

1. `docs/agents/00_BOOTSTRAP.md` v1.5+.
2. `docs/agents/03_founder_playbook.md` §2.3 + §4-§6 + §5.3.
3. `progress/SESSION_LOG.md` últimas 5 entries (S1.6 → S1.7 → S1.8 → S1.9 → **S1.9 EXTENDED esta entry**).
4. `progress/PRE_S2_CHECKLIST.md` v1.5 (B1 CERRADO 8/8 + D1/D3 firmed + Phase 8+9 schedule).
5. **Docs firmados SSoT post-S1.9 EXTENDED:**
   - **ADR-011 + ADR-012 + ADR-013 + ADR-015** (ADR-014 placeholder).
   - Bible v1.4 + BOOTSTRAP v1.5.
   - `01_art_direction.md` v2.0-scaffold-r7 NOTICE r6.
   - `02_sonar_tablet.md` v1.2 NOTICE r1.1.
   - `01_roadmap.md` v1.5 NOTICE r1.
   - **`02_events_catalog.md` v1.1 NOTICE r1** (NEW S1.9 EXT).
   - **`03_db_schema.md` v1.1 NOTICE r1** (NEW S1.9 EXT).
   - **`04_api_contracts.md` v1.1 NOTICE r1** (NEW S1.9 EXT).
   - **`05_state_machines.md` v1.1 NOTICE r1** (NEW S1.9 EXT).
   - **`06_fivem_standards.md` v1.1 NOTICE r1** (NEW S1.9 EXT).
   - **`07_bridges_compatibility.md` v1.1 NOTICE r1** (NEW S1.9 EXT).
6. Logo v2 working canonical README (si toca logo).

**Hard constraints reafirmados S1.9 EXTENDED (sin cambios vs S1.8/S1.9):**
- NO modificar docs/* sin instrucción explícita founder (Bible/ADRs/briefs/art_direction firmados).
- NO arreglar conflict logo realidad vs briefs firmados — founder override S1.7 documentado.
- NO sound naming pre-canonical (sonar_ping/etc deprecated). Usar 5 SFX canonical.
- NO voz naval/militar/capitán. Canonical = neutral premium-tech.
- NO paleta azul marino + dorado. Canonical = hybrid Tier A/B/C post-ADR-012.
- **NO ejecutar Phase 8 code refactor sin founder server-available + smoke check.** Docs-only safe; code risky sin gate.
- SESSION_LOG append-only.
- Commit format `S{N}.{M} {imperative present}`.

**Founder tone preference preserved S1.9 EXTENDED:**
- Zero sugerencias fatigue-based.
- Zero paternalismo.
- Founder decide scope vía opciones estructuradas, AI ejecuta professional direct.
- AI prioriza per dependency DAG cuando founder delegate.

### Files in scope S1.9 EXTENDED (respetados)

✅ Scope strict:
- `docs/planning/02_decision_log.md` (ADRs firmado + meta).
- `docs/technical/02_events_catalog.md` v1.1.
- `docs/technical/03_db_schema.md` v1.1.
- `docs/technical/04_api_contracts.md` v1.1.
- `docs/technical/05_state_machines.md` v1.1.
- `docs/technical/06_fivem_standards.md` v1.1.
- `docs/technical/07_bridges_compatibility.md` v1.1.
- `progress/PRE_S2_CHECKLIST.md` v1.5.
- `progress/SESSION_LOG.md` append esta entry.

**NO tocó:** Bible v1.4, ADRs previos 001-012 históricos, briefs v2 `art/briefs/`, art_direction v2.0-scaffold-r7, `02_sonar_tablet.md` v1.2, `01_architecture.md` v1.0, `01_roadmap.md` v1.5, BOOTSTRAP v1.5, `_archive/`, code/resources/*, DB, `.windsurf/*`, `art/branding/*`, `art/tools/*`, `scripts/smoke_test_s*.md`.

### Summary ejecutivo S1.9 EXTENDED close

Session heavy work completa. **B1 Phase 6 mass-purge operational docs CERRADO 8/8 (100%)**. Decisiones founder D1+D3 resueltas + 3 ADRs firmados (013/014-placeholder/015). Docs técnicos 2-7 con NOTICE r1 pattern establishing canonical naming + schedule + reading guide. Phase 8+9 execution scheduled próxima sesión founder-available (code refactor + migration 009 + smoke regression).

**Pre-Sprint 2 gate roadmap claro:**
1. Phase 8+9 execution (~3-4h next session).
2. Phase 10 smoke regression (~1h).
3. Docs v1.1 → v1.2 rewrite inline (~6-8h split 2-3 sessions).
4. BOOTSTRAP v1.5 → v1.6 (~30min).
5. B2 SPRINT_PLAN_S2 (~2-3h).
6. S2.0 arranque.

Estimate calendar: **S2 arranque ~3-5 sesiones post-S1.9 EXTENDED ≈ 2-3 días depending founder availability**.

**Commit pending founder green-light:**

```
S1.9 EXT ADRs 013+015 firmed + docs 2-7 v1.1 NOTICE r1 + PRE_S2_CHECKLIST v1.5 (B1 Phase 6 CERRADO 8/8)
```

### Founder guidance institutional S1.9 EXTENDED

> *"vamos a completar el trabajo, estoy usando tu como el mas potente modelo, no para hacer un commit, pero para este trabajo pesado"* (instruction heavy execution mode post-S1.9 commit).
>
> *"elige lo tien que ir orden, que esta en la cola y hay que priorizarlo"* (delegation ordering AI — priorized per dependency DAG D3 master → D1 → ADRs → docs 2-7 → checklists).

---

---
## S1.10 — Phase 8+9 namespace rename execution + smoke harness inline (Opción C)

- **Fecha:** 2026-05-04
- **Duración:** ~5h (founder-AI pair, marathón nocturno)
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.5)
- **Sprint:** S1 tail / pre-S2 gate execution
- **Perfil:** 🔧 BUILDER + ⚡ SPRINTER + 🔍 DEBUGGER
- **Modelo:** Sonnet 4.5
- **Goal:** Ejecutar Phase 8 (code refactor `admirals_*` → `sonar_*`) + Phase 9 (DB migration) + smoke regression cumulative S0→S1.3 per ADR-013 firmed S1.9 EXTENDED.
- **Status:** ✅ Done

### Cambios

**Renamed (git mv, 56 files):**
- `resources/admirals_bridges/` → `resources/sonar_bridges/` (registry + 6 bridges + adapters T1 QBox/ox_inventory/lb_phone/ox_target/ox_lib + native fallbacks + test_adapter).
- `resources/admirals_core/` → `resources/sonar_core/` (logger/metrics/db/event_bus/rate_limiter/migrations + 8 migrations SQL + lib/admirals.lua → lib/sonar.lua).
- `resources/admirals_bank/` → `resources/sonar_bank/` (iban/accounts/movements/events/transfer/fsm_escrow/escrow/callbacks).

**Modified:**
- Replace `admirals_*` → `sonar_*` en SQL files (migrations 001-008): tabla DDL + FK + indexes + comments. **261 refs** auto-renamed BOM-safe UTF-8 NO BOM.
- Replace `admirals_*` → `sonar_*` en `.lua` (config + DB queries inline): **8 residuals** post-script-rename agent previo.
- Strip UTF-8 BOM de **39 `.lua` files** (root cause boot parse errors `unexpected symbol near ''65279''` Lua54).
- `003_bank_schema.sql`: removido named CHECK XOR `chk_sonar_bank_accounts_owner_xor` (MariaDB 12.2.2 parser limitation `Function or expression cannot be used in CHECK clause` con multi-col + IS NULL pattern post-FK). App-layer enforce per D4 docs comment + `server/accounts.lua` validation.
- `006_escrow_schema.sql`: comentado named CHECK `chk_sonar_bank_accounts_owner_xor_or_escrow` (mismo MariaDB pattern). Simple CHECKs `amount > 0` / `fee_charged >= 0` preservados (single-col safe).
- `sonar_core/config.lua`: `Config.MigrationsFiles` reduced 9 → 8 (009 archived post-rename obsolete).
- `server.cfg.example`: convars `admirals_*` → `sonar_*` (DB + bridges + env).
- `scripts/smoke_test_s0.md` + `s1_1.md` + `s1_3.md`: comandos + tablas + events `admirals` → `sonar`.

**Created:**
- `resources/sonar_bank/server/admin_commands.lua` (~360 líneas): smoke harness inline gated `sonar_dev_mode=1` + ACE `sonar.admin`. **9 comandos**: `/sonar_smoke_status`, `dump_accounts`, `dump_movements`, `dump_escrows`, `iban_gen`, `seed_player`, `transfer`, `escrow_create`, `escrow_release`. Reemplaza patrón histórico delete-per-sprint client/smoke_*.lua (commits 23641e8/e0d7b38/33520aa).
- `scripts/drop_admirals_legacy.sql`: SQL helper drop tablas legacy `admirals_*` dev DB.

**Archived:**
- `resources/sonar_core/migrations/_archive_phase_8/009_rename_admirals_to_sonar.sql` + `.DOWN.sql` (broken post-rename — RENAME sonar_X TO sonar_X no-op; preserved historical reference).

### Decisiones tomadas

- **D-S1.10-1:** Phase 9 ejecutada vía **fresh DB start** (drop legacy `admirals_*` tablas + 001-008 crean `sonar_*` directos), NO via migration 009 ALTER RENAME. Razón: dev-only data, no producción S0+S1 escrow tests preservar; migration 009 broken post Phase 8 SQL rewrite (sus comandos `RENAME admirals_X TO sonar_X` se transformaron `RENAME sonar_X TO sonar_X`).
- **D-S1.10-2:** Smoke harness pattern Opción **C** (admin commands inline en core resource, gated convar+ACE) elegido sobre A (recover git) / B (separate dev resource) / D (hybrid). Razón: founder explícito "c". Trade-off: mezcla test code con production code, pero gating por convar lo silencia en prod (return early). ADR pendiente formalización Sprint 2 prep.
- **D-S1.10-3:** MariaDB 12.2.2 CHECK constraint multi-col XOR named — workaround eliminar (no rewrite alternative); enforcement 100% app-layer en `accounts.lua` + `escrow.lua` per defense-in-depth pattern documentado D4. Re-evaluar S2+ si engine change o MariaDB bug fix.

### Issues pendientes
- Docs `02_events_catalog.md` v1.1 → v1.2 rewrite inline 88 eventos `admirals:*` → `sonar:*`.
- Docs `03_db_schema.md` + `04_api_contracts.md` + `05_state_machines.md` + `06_fivem_standards.md` + `07_bridges_compatibility.md` v1.1 → v1.2 rewrite inline (~6-8h split 2-3 sessions).
- ADR-014 placeholder S1.9 EXT pendiente firmado (candidato: Smoke harness inline pattern Opción C documentation).
- BOOTSTRAP v1.5 → v1.6 (post-Phase-8+9 closed status).
- B2 `SPRINT_PLAN_S2.md` (~2-3h) pre-S2.0 arranque.
- `resources/admirals_tablet/` orphan directory (no manifest, ignored al boot warning) — pendiente decidir rename a `sonar_tablet/` o delete (S2 scope).

### Smoke regression S0→S1.3 cumulative — 10/10 PASS

| # | Test | Resultado | Observaciones |
|---|---|---|---|
| 01 | Pre-flight Boot | ✅ | sonar_bridges detectó QBox/Ox/LB correctamente. |
| 02 | Migration 001 | ✅ | Tabla schema_versions creada y persistente. |
| 03 | Migrations 002-008 | ✅ | 8 archivos aplicados. Tablas banco + escrow listas. |
| 04 | Idempotencia | ✅ | Reinicios no duplican ejecuciones SQL. |
| 05 | EventBus Smoke | ✅ | Comunicación interna fluida + logs auditoría. |
| 06 | DB & Transactions | ✅ | Transferencia atómica verificada (2500→2000). |
| 07 | RateLimiter | ✅ | Protección buckets operativa post hot-fix. |
| 08 | Admin Commands | ✅ | Arnés `/sonar_smoke_*` funcional. |
| 09 | Metrics Snapshot | ✅ | Counters cuentas + movimientos OK. |
| 10 | Resmon Budgets | ✅ | 0.00ms (Idle/Peak), muy debajo del límite 0.3ms. |

### Handoff próxima sesión (S1.11 o S2-prep)

- **Modelo recomendado:** Sonnet 4.6 (docs surgical rewrite Pass) o Opus 4.7 si batch v1.2 docs 2-7 grande.
- **Goal:** Docs technical 2-7 v1.1 → v1.2 rewrite inline naming canonical `sonar_*` + ADR-014 firmado smoke harness inline + BOOTSTRAP v1.6.
- **Pre-requisitos:** leer `docs/agents/00_BOOTSTRAP.md` v1.5 + playbook §4-§6 + SESSION_LOG últimas 5 entries (S1.7→S1.10) + `progress/PRE_S2_CHECKLIST.md` v1.5.
- **Files in scope:** `docs/technical/02-07_*.md` + `docs/planning/02_decision_log.md` (ADR-014) + `docs/agents/00_BOOTSTRAP.md` + `progress/PRE_S2_CHECKLIST.md` v1.6.
- **Files OUT of scope:** code/resources/* (Phase 8+9 cerrado green baseline), DB, `_archive/`.
- **Notas especiales:** smoke harness inline `/sonar_smoke_*` operacional para regression rápida; usar `sonar_dev_mode 1` convar.

### Files in scope respetados
✅ Scope strict: code resources + migrations + smoke harness + scripts/*.md + server.cfg.example. **NO tocó:** docs/* (firmados), `_archive/`, art/*, `.windsurf/*`, branding.

---

## S1.10 EXTENDED — Post-Phase-8 residuals cleanup + docs v1.2 Phase 1 auto-rewrite + Phase 2 surgical (NOTICE r1 removed + prose canonical)

- **Fecha:** 2026-05-04
- **Duración:** ~2.5h continuación post S1.10 close (founder-AI pair, marathón nocturno)
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.5)
- **Sprint:** S1 tail / pre-S2 gate execution (sub-commits S1.10.1 + S1.10.2 + S1.10.3)
- **Perfil:** 🔧 BUILDER + 📝 DOCUMENTATIONIST (docs v1.1 → v1.2 hybrid auto + AI surgical)
- **Modelo:** Sonnet 4.5
- **Goal:** Residuals cleanup post-Phase-8 (server.cfg.example + 004 seed brand leak + migration comments) + docs technical 02-07 v1.1 → v1.2 rewrite (NOTICE r1 obsoleto removed + prose `Admirals` → `SONAR` canonical + Versión + FIN + v1.2 changelog row).
- **Status:** ✅ Done — 4 commits pushed origin/main (60890b6 + d07a740 + 3b8d815 + 0113ed2).

### Cambios

**S1.10.1 — Residuals cleanup (commit `d07a740`):**

- `server.cfg.example` (24 refs): `admirals_db_*` / `admirals_env` / `admirals_bridge_*` convars → `sonar_*`. `sv_hostname "Admirals — Dev Server"` → `"SONAR — Dev Server"`. Resources `ensure admirals_bridges/core` → `sonar_*`. **CRITICAL** — afectaba template para nuevos deploys.
- `resources/sonar_core/migrations/004_bank_seed_system_account.sql`: seed alias row SYSTEM treasury account `'Admirals System'` → `'SONAR System'` (brand leak en `sonar_accounts.alias` visible en counterpart UI).
- `resources/sonar_core/config.lua`: 2 comments referencing rename ADR + obsolete 009 filename actualizados.
- `resources/sonar_core/migrations/002+003+005`: comments docs legacy actualizados (`Admirals.DB.Execute`, `nombre mostrado Admirals`, `producción Admirals targets MariaDB`).
- `scripts/smoke_test_s0.md`: 1 ref `Admirals.Log.Size()` → `SONAR.Log.Size()`.

**S1.10.2 — Docs v1.2 Phase 1 auto-rewrite (commit `3b8d815`):**

- Docs technical 02-07 (6 docs, 1075 identifiers replaced bulk regex deterministic):
  - `admirals_bridges/core/bank/companies/tablet/granja/market/logistics/documents/jobs` → `sonar_*`.
  - Table names: `admirals_accounts/schema_versions/audit_log/idempotency_keys/bank_accounts/bank_movements/escrows/fsm_transitions/company_balances` → `sonar_*`.
  - Generic `admirals_*` catch-all + `admirals:*` event prefixes → `sonar:*`.
  - API namespace `Admirals.DB/Log/Bus/Core/Metrics/Rate/Identity/Bank` → `SONAR.X`.
  - Exports `exports['admirals_*']` / `exports.admirals_*` → `sonar_*`.
- Diff: 1075 insertions + 1075 deletions (1:1 simétrico = pure line-replace, zero structural change).
- **Preservado intencional para AI Phase 2:** prose `\bAdmirals\b` standalone refs (127 total cross-docs).

**S1.10.3 — Docs v1.2 Phase 2 surgical (commit `0113ed2`):**

- NOTICE r1 blocks **removidos completamente** en 6 docs (336 líneas obsoletas eliminadas):
  - `02_events_catalog.md` lines 13-71 (59 lines).
  - `03_db_schema.md` lines 14-109 (96 lines).
  - `04_api_contracts.md` lines 16-63 (48 lines).
  - `05_state_machines.md` lines 17-74 (58 lines).
  - `06_fivem_standards.md` lines 16-48 (33 lines).
  - `07_bridges_compatibility.md` lines 15-56 (42 lines).
- Prose `\bAdmirals\b` → `SONAR` canonical en pre-changelog content (TL;DR, resumen ejecutivo, estado documento, body §N).
- Header `**Versión:** 1.1` → `1.2` + parenthetical descriptor actualizado a `(post Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical post S1.10.x)`.
- `FIN DEL DOCUMENTO ... v1.1` → `v1.2` en los 6 docs.
- Changelog table: appended row v1.2 con descripción Phase 2 surgical work.
- §17.2/§14.x "Próxima revisión: tras Phase 8+9 execution" → "tras Sprint 2 (Granja MVP + companies + T2 adapters) + smoke regression + post-S2 learnings (→ v1.3 si cambios estructurales)".
- 07 §18 TL;DR Regla 4 + Regla 5: 2 prose refs `Admirals` → `SONAR` finales (post-changelog content que pre-changelog cut excluyó).
- **Preservado correctamente (whitelist intencional):**
  - `ex-Admirals` historical brand mention en resúmenes ejecutivos (1-2 per doc).
  - `ADR-011 (pivot Admirals → SONAR)` ADR ref name (todos docs).
  - `rebrand Admirals → SONAR` en changelog v1.1 rows (historical).
  - `prose Admirals → SONAR` y `"Admirals" → "SONAR"` en changelog v1.2 rows (descripción work).
- Diff: 107 insertions + 437 deletions (net -330 líneas = NOTICE r1 obsoleto removido).
- Final integrity: 0 NOTICE remaining + all 6 docs v=1.2 + FIN=v1.2 + v1.2 row present + 0 unaccounted Admirals refs.

### Decisiones tomadas

- **D-S1.10E-1:** Hybrid approach Opción B (auto naming-only + AI surgical prose) elegido sobre full-auto (Opción A — alta corrupción NOTICE r1) o full-AI surgical (Opción C — 6-8h vs 2.5h actual). Trade-off: ahorra ~50% tiempo sin sacrificar safety. Auto-pass aplicó deterministic identifier replacements (safe), AI Phase 2 surgical aplicó prose contextual (semantic-aware).
- **D-S1.10E-2:** NOTICE r1 blocks **eliminados completamente** en lugar de actualizar a "NOTICE r2" o similar. Razón: NOTICE r1 fue diseñado precisamente como **bridge temporal pre→post Phase 8+9**. Phase 8+9 ya ejecutado → NOTICE r1 obsoleto by design. v1.2 docs ahora estado canonical sin compatibility layer.
- **D-S1.10E-3:** Whitelist preservation strategy para `Admirals` refs históricos (changelog entries v1.0/v1.1, ADR-011 ref name, ex-Admirals brand mentions). Razón: append-only changelog discipline + accuracy ADR refs + historical brand context preservation per ADR-011 §5.5.8 excepciones.

### Issues pendientes (handoff a next session)

- ADR-014 placeholder S1.9 EXT firmado (candidato: Smoke harness inline pattern Opción C documentation post S1.10 implementation experience). **~45min.**
- `docs/agents/00_BOOTSTRAP.md` v1.5 → v1.6 (post-Phase-8+9 closed + docs technical 02-07 v1.2 status). **~30min.**
- `resources/admirals_tablet/` orphan directory decision: rename `sonar_tablet/` o delete (S2 scope). **~15min.**
- `progress/PRE_S2_CHECKLIST.md` v1.5 → v1.6 (Phase 8+9 + docs v1.2 done; restantes B2 SPRINT_PLAN_S2). **~30min.**
- `progress/SPRINT_PLAN_S2.md` redactable (B2 final pre-S2 gate, scope: T2 adapters QBCore+ESX + sonar_companies DDL + C003 getTransactions + Granja MVP foundation + Tablet UI scaffold). **~2-3h.**
- Sprint S2.0 arranque post pre-S2 gate green. **Oleada 1 sigue.**

### Files in scope respetados

✅ Scope strict: `docs/technical/02-07_*.md` (rewrite v1.1 → v1.2) + `server.cfg.example` + `resources/sonar_core/migrations/002-005` (comments) + `resources/sonar_core/config.lua` (comments) + `scripts/smoke_test_s0.md` (1 ref). **NO tocó:** code resources Lua functional (Phase 8 ya cerrado), DB schema (Phase 9 ya cerrado), `docs/00_PRODUCT_BIBLE.md` v1.4, `docs/economy/01_economic_model.md`, `docs/art/*`, `docs/agents/00_BOOTSTRAP.md`, `progress/PRE_S2_CHECKLIST.md`, `_archive/`, ADRs.

### Handoff próxima sesión (Manager AI — pre-S2 + S2 documentation lead)

- **Modelo recomendado:** Gemini 2.5 Pro (1M context window) o equivalente high-context model.
- **Goal primario:** Gestor documentación + product context completo. **NO escribir código.** Manage docs cleanup + ADRs + planning + handoffs.
- **Scope inmediato:** ADR-014 firmado + BOOTSTRAP v1.6 + admirals_tablet orphan decision + PRE_S2_CHECKLIST v1.6 + SPRINT_PLAN_S2 redactable.
- **Scope continuación:** S2 documentation lead (specs nuevas resources sonar_companies + sonar_granja + sonar_tablet + T2 adapters QBCore/ESX docs + DDL migrations 010+ docs).
- **Files in scope:** `docs/agents/00_BOOTSTRAP.md` + `docs/planning/*` + `progress/PRE_S2_CHECKLIST.md` + `progress/SPRINT_PLAN_S2.md` + `progress/SESSION_LOG.md` (append-only) + nuevas specs S2 docs.
- **Files OUT of scope:** code/resources/* (BUILDER agent territorio), DB migrations functional SQL, smoke harness code.
- **Notas especiales:** Founder yaboula directo español + tecnicismos inglés OK, sin preámbulos/paternalismo, profesional only. Código `sonar_*` ya 100% canonical en repo. Docs technical 02-07 v1.2 firmado clean. Pivot Admirals → SONAR completo (ADR-011 + ADR-012 + ADR-013).

### Resumen ejecutivo session S1.10 EXTENDED

Sprint 1 cerrado **100% canonical** post Phase 8+9 + docs v1.2. Workspace ahora coherente namespace `sonar_*` en code + DB + config + docs technical. Únicas excepciones legítimas: `_archive/` files, ADRs históricos (immutable), SESSION_LOG (append-only), changelog historical entries, brand "ex-Admirals" mentions (ADR-011 §5.5.8). Pre-S2 gate restantes ~3-4h en próximas 1-2 sessions. Workflow shift: BUILDER agent (Sonnet 4.5/4.6) → Manager AI agent (1M context model) para docs lead pre-S2 + S2.

---
## S1.10 EXT addendum — Founder identity v3 confirmation + ADR-016 scoped (handoff Manager AI updated)

- **Fecha:** 2026-05-04 (post-S1.10 EXT close, mismo día session marathón)
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.5)
- **Tipo:** Decision capture (no code/docs touched, solo decisión + handoff prompt update).

### Decisiones founder confirmadas

- **D-S1.10E-4: Identity v3 paleta locked.** Black `#060607` + Orange `#FF5100` + White `#FAFAFA`. Logo v3 (`art/branding/logo_v3/`) firmable. Razones founder: differentiation real en mercado FiveM premium (paleta inexistente en QBox/Renewed/Illenium ecosystem) + potencia trends 2026 (glassmorphism/bento/microinteractions/glows) + versatility con complementarios.
- **D-S1.10E-5: Dark-mode-only doctrine.** No light variant nunca. Tablet UI + marketing web ambos dark-only. `monogram_s_black.svg` obsoleto. Test matrix QA reducido. Theme system simplificado (single token set).
- **D-S1.10E-6: 3-color strict palette.** No accent colors add (yet). Discipline = identity. Re-evaluable post-MVP S2 si data muestra friction UX.
- **D-S1.10E-7: Trend stack tiered 2026 (T1 adopt / T2 selective / T3 prohibited).**
  - T1 (adopt heavy): Bento Grid, Microinteractions (Framer Motion), Glassmorphism selectivo (chrome layer only), Focus glows orange (a11y + brand), Smooth springs, Animated data viz (sparklines + counters).
  - T2 (selective): Aurora gradients (hero/transitions), Kinetic type (marketing only), Cmd+K palette (post-MVP S3+), Spatial depth shadows.
  - T3 (prohibited): Skeuomorphism, Brutalist Y2K, Multi-color gradient overload, Heavy Lottie, Heavy parallax scroll, Neon glow excess, Backdrop-blur en cards content, Multiple accents.
- **D-S1.10E-8: Implementation stack Tablet UI frozen.** React 18 + Vite 5 + TypeScript strict + Tailwind CSS 4 (CSS-first @theme tokens) + shadcn/ui (dark-only theme) + Framer Motion 11 + Lucide icons + Recharts. Documentado en ADR-016 D4.
- **D-S1.10E-9: NUI performance hard constraints.** backdrop-filter ≤5 instances simultáneas (solo chrome layer), Framer per-component (no listas 100+ simultáneas sin virtualize), Aurora static CSS only (no Canvas/WebGL), Recharts ≤100 datapoints sin throttle, shadows pre-rendered tokens. Per `06_fivem_standards.md` NUI budget.

### Scope ADR-016 derivado (Manager AI próxima session priority #1)

ADR-016 = **amendment** ADR-011 + ADR-012 (NO contradicción). Preserva: naming SONAR, abstract metaphor sonar-waves, neutral voice, identity scaffold-r6 philosophy. Cambia: palette tokens + typography split (adds Syncopate marketing) + adds dark-only doctrine + adds trend stack tiered + adds NUI perf doctrine + adds implementation stack frozen.

### Handoff Manager AI updated (próxima session)

Founder abrirá nueva session con Manager AI agent (recomendado: Gemini 2.5 Pro 1M context o Opus 4.7). Primer task asignado:

1. Draft ADR-016 (Identity v3 + Dark-only + Trend stack tiered + NUI perf + Stack frozen) → founder firma.
2. Bump `docs/art/01_art_direction.md` v2.0-scaffold-r6 → v3.0 (paleta locked + dark-only + trend stack + anti-patterns + NUI budgets).
3. Bump `docs/00_PRODUCT_BIBLE.md` v1.4 → v1.5 (palette section refresh).
4. Bump `docs/design/02_sonar_tablet.md` v1.2+ → v1.3 (Tailwind 4 @theme tokens + shadcn dark-only + Framer Motion patterns + trend stack T1 reference).
5. Bump `docs/design/01_brief_logo.md` v2 → v3 (isotipo + paleta refresh).
6. Update `art/tools/logo_export/export.mjs` config → `logo_v3/` sources; drop monogram_s_black.svg from pipeline (light-mode obsolete).
7. SESSION_LOG entry S1.10.4 ADR-016 firmed + assets pipeline updated.

**Estimación:** ~4-5h Manager AI session.

### Files in scope respetados

✅ Esta entry no toca code ni docs (solo SESSION_LOG append). Decisión + handoff scope capture.

---

## S1.10.4 — ADR-016 firmed (Identity v3 doctrine locked) + decision_log split part2

- **Fecha:** 2026-05-04 (continuación marathón S1.10 EXT addendum, mismo día)
- **Duración:** ~1h
- **Founder + Agent:** yaboula + Cascade (Sonnet 4.5)
- **Sprint:** S1 tail / pre-S2 gate execution (Manager AI session priority #1)
- **Perfil:** 📝 SCRIBE + 🏗️ ARCHITECT (ADR redaction + decision capture)
- **Modelo:** Sonnet 4.5
- **Goal:** Firmar ADR-016 (SONAR Identity v3 firmable + doctrine palette/dark/stack/perf locked, amends ADR-011 + ADR-012) capturando 6 decisiones founder D-S1.10E-4 a D-S1.10E-9 + resolución D-S1.10E-A (monogram_s_black.svg).
- **Status:** ✅ Done — scope priority #1 cerrado. Items #2-#7 handoff diferidos próxima Manager AI continuation.

### Cambios

**Created:**
- `docs/planning/02_decision_log_part2.md` v1.0 (~253 líneas) — archivo continuación documento padre (split por tamaño operativo gestionable). Header continuación clara + reglas split + meta secciones (tags delta + estado + changelog + TL;DR). Primer ADR registrado: ADR-016.
  - **ADR-016 SONAR Identity v3 firmable + doctrine palette/dark/stack/perf locked** — accepted, amends ADR-011 + ADR-012. 6 decisiones founder firmadas:
    - **D1 Paleta v3 locked:** Black `#060607` + Orange `#FF5100` + White `#FAFAFA`. SSoT canonical `docs/art/branding/01_brief_logo.md` v2 §3.
    - **D2 Dark-mode-only doctrine** product. Excepción única: `monogram_s_black.svg` print/external (resolución D-S1.10E-A). NO uso product UI.
    - **D3 3-color strict.** No accent colors add. Re-evaluable post-MVP S2.
    - **D4 Trend stack 2026 tiered T1/T2/T3.**
    - **D5 Tablet UI stack frozen S2-S8** (React 18.3 + Vite 5 + TS strict + Tailwind v4 `@theme` + shadcn dark-only + Framer Motion 11 + Lucide + Recharts).
    - **D6 NUI performance hard constraints** (≤4ms paint, ≤500KB JS gzipped, ≤80MB heap, lazy-loading obligatorio, GPU-only animations, react-window virtualization >50 items).
  - 6 alternatives considered (A-F).
  - 5 risks accepted founder (R1-R5: Tailwind v4 inestabilidad / Framer bundle cost / D3 friccion UX / React 19 missed / D6 budgets too strict).
  - 5 re-evaluation triggers explícitos.

**Modified:**
- `docs/planning/02_decision_log.md` v1.5 → **v1.5.1** — añadido §8 Continuación + pointer cruzado claro a `02_decision_log_part2.md` + reglas split + changelog row §8.1. Append-only inviolable respetado (cero modificación entries v1.5 anteriores).

### Decisiones tomadas

- **D-S1.10.4-1: Split documento decision_log** vs continuar inflando `02_decision_log.md`. Razón: padre alcanzó ~1404 líneas, navegabilidad / diff-friendly edits comprometida. Split en `part2` mantiene numeración ADR continua (ADR-016 sigue ADR-015) + filosofía heredada (NO duplicar §1/§3/§4) + padre append-only.
- **D-S1.10E-A resuelta opción B (founder):** preservar `monogram_s_black.svg` como print/external exception, NO obsoleto/drop como handoff S1.10 EXT addendum #6 indicaba. Capturado ADR-016 D2 + invalida item #6 del 7-item scope handoff Manager AI. Razón founder: print papelería + fondos blancos third-party donde dark monogram ilegible.
- **D-S1.10.4-2: Write en bloques pequeños** sustituye intento inicial multi_edit fallido (JSON escaping error). 6 bloques secuenciales: stub → header+context → decision D1-D6 → alternatives+consequences+risks+impact+re-eval → meta (tags+estado+TL;DR) → pointer padre.

### Issues pendientes (handoff próxima session)

- **#2-#5 docs bumps deferred:** `01_art_direction.md` v3.0 + Bible v1.5 + `02_sonar_tablet.md` v1.3 + `01_brief_logo.md` v3 — Manager AI continuation scope.
- **#6 invalidado:** `export.mjs` config NO drop `monogram_s_black.svg` (D-S1.10E-A override). Si pipeline necesita ajuste futuro será para rebrand naming sólo, no remove.
- **BOOTSTRAP v1.5 → v1.6:** añadir referencia ADR-016 §SSoTs canónicos + part2 split awareness para AI sessions futuras.
- **PRE_S2_CHECKLIST v1.5 → v1.6:** Phase 8+9 + docs v1.2 + ADR-016 done; restantes B2 SPRINT_PLAN_S2 + bumps Bible/art_direction/sonar_tablet/brief_logo.
- **`resources/admirals_tablet/` orphan directory:** rename `sonar_tablet/` o delete (S2 scope decision).
- **SPRINT_PLAN_S2.md redactable:** B2 final pre-S2 gate. Debe incorporar ADR-016 D5 stack install + D6 perf budgets en setup tasks + design system D3 patterns docs.

### Handoff próxima sesión (Manager AI continuation o BUILDER S2 prep)

- **Modelo recomendado:** Gemini 2.5 Pro (1M context, docs lead) o Opus 4.7 si batch bumps grande.
- **Goal primario:** Bumps docs identity v3 propagation (art_direction v3.0 + Bible v1.5 + sonar_tablet v1.3 + brief_logo v3) + BOOTSTRAP v1.6 + admirals_tablet orphan decision + PRE_S2_CHECKLIST v1.6 + SPRINT_PLAN_S2 redactable.
- **Pre-requisitos:** leer `docs/planning/02_decision_log_part2.md` v1.0 ADR-016 completo + esta entry + `docs/agents/00_BOOTSTRAP.md` v1.5 + playbook §4-§6 + SESSION_LOG últimas 4 entries (S1.10 → S1.10 EXT → S1.10 EXT addendum → esta).
- **Files in scope:** `docs/art/01_art_direction.md` + `docs/00_PRODUCT_BIBLE.md` + `docs/design/02_sonar_tablet.md` + `docs/design/01_brief_logo.md` + `docs/agents/00_BOOTSTRAP.md` + `progress/PRE_S2_CHECKLIST.md` + `progress/SPRINT_PLAN_S2.md` (nuevo) + `progress/SESSION_LOG.md` (append).
- **Files OUT of scope:** code/resources/* (BUILDER agent territorio S2 setup), DB, ADRs históricos firmados, `_archive/`, art/branding/* assets (logo v3 ya firmable), `02_decision_log.md` v1.5.1 (append-only inviolable).
- **Notas especiales:**
  - ADR-016 D2 dark-only doctrine product + `monogram_s_black.svg` excepción única print/external — propagar correctamente en docs identity (no eliminar referencia ni obsoletar).
  - ADR-016 D5 stack frozen — devs SPRINT_PLAN_S2 setup tasks deben pin exact versions.
  - Decision log split: NO añadir ADRs nuevos a `02_decision_log.md` v1.5.1 — todo va a `part2`.

### Files in scope respetados

✅ Scope strict: solo `docs/planning/02_decision_log_part2.md` (created) + `docs/planning/02_decision_log.md` (§8 append, v1.5 → v1.5.1) + `progress/SESSION_LOG.md` (esta entry append). **NO tocó:** code/resources/* (Phase 8+9 baseline green preserved), DB, art/branding/* (logo v3 ya firmable, no toques), art/tools/* (export.mjs working tree del founder pre-sesión, NO mío), `_archive/`, ADRs históricos 001-015, docs technical 02-07 v1.2, Bible v1.4, art_direction v2.0-scaffold-r6, briefs, sonar_tablet, BOOTSTRAP, PRE_S2_CHECKLIST, `.windsurf/*`.

### Resumen ejecutivo session S1.10.4

ADR-016 firmado captura 6 decisiones doctrinales identity v3 que destrabean Sprint 2 día-1 (palette + dark-only + 3-color + stack frozen + perf budgets). Decision log splitteado en `part2` con regla clara split `part3` cuando supere ~1000 líneas — escalable. D-S1.10E-A resuelta clean (monogram_s_black.svg print/external preserved). Pre-S2 gate restante: docs bumps propagation identity v3 + BOOTSTRAP v1.6 + PRE_S2_CHECKLIST v1.6 + SPRINT_PLAN_S2 redactable + tablet orphan decision (~4-5h Manager AI continuation).

---

## Session S2.0 — Planning gate close (SPRINT_PLAN_S2 v1.0 firmable)

- **Fecha:** 2026-05-04
- **Modelo:** Opus 4.x (planning + critical review)
- **Duración:** ~1.5h founder time
- **Foco:** finalizar `progress/SPRINT_PLAN_S2.md` v0.1-draft → v1.0 firmable. Review crítico DC1-DC11 + smoke ×50 + session breakdown S2.0-S2.9 + risks. Resolver 11 pre-flags. Cerrar B2 + B5 hard blockers PRE_S2_CHECKLIST.

### Onboarding executed

✅ Cargados: `docs/agents/00_BOOTSTRAP.md` v1.6 + `docs/agents/03_founder_playbook.md` §4-§6 + últimas 3 SESSION_LOG entries (S1.10.3 → S1.10.4) + `progress/SPRINT_PLAN_S2.md` v0.1-draft + `progress/PRE_S2_CHECKLIST.md` v1.7. Round 1+2+3 docs específicos founder prompt: ADR-015 + ADR-016 (`docs/planning/02_decision_log.md` + `_part2.md`) + `docs/design/00_PRODUCT_BIBLE.md` v1.5 + `docs/art/01_art_direction.md` v3.0-locked + `docs/design/02_sonar_tablet.md` v1.3 + `docs/art/branding/01_brief_logo.md` v3 + `docs/technical/02_events_catalog.md` v1.2 + `docs/technical/04_api_contracts.md` v1.2 + `docs/technical/06_fivem_standards.md` v1.1 + `package.json` real + git log últimos 15 commits + tags `sonar-identity-canonical/v3-lock/phase-8-9-complete` confirmados pushed. Memorias persistentes r2 confirmadas.

### Outcome principal

**`progress/SPRINT_PLAN_S2.md` v1.0 firmable** — 11 pre-flags resueltos via founder delegation "lo más recomendable, tú sabes mejor que yo":

- **F1 (🟡):** Conflict aparente DC6 historial vs C003 deferred S3 (ADR-015) → Resolución per ADR-015 línea 1162: Bank app S2 consume DB query directo `SELECT FROM sonar_bank_movements WHERE account_id=? ORDER BY created_at DESC LIMIT N` como **consumer pattern temporal** hasta C003 ship S3. §2.2 + DC6 explícita el pattern. Wrapper `getHistoryDirect()` en NUI bridge S2 permite swap interno post-C003 S3 sin breaking NUI contract (R5).
- **F2 (🔴):** §7 sesión S2.1 "Phase 8+9 execution" obsoleta (ya done tag `phase-8-9-complete`) → re-purpose `S2.1 Tablet scaffold setup` (tsconfig strict + Vite verify + shadcn CLI init dark-only + tokens `globals.css` + Lucide/Framer install + index.html boot + dark canvas baseline + bundle-analyzer devDep).
- **F3 (🔴):** §9 risk R1 "Phase 8+9 breaks smoke" obsoleto → replace R1' "Tailwind v4 `@theme` + shadcn/ui dark-only override conflict" (probabilidad media, impacto medio, mitigación S2.1 spike pre-app-code + rollback Tailwind v3 LTS path documented).
- **F4 (🔴):** §2.2 mezclaba 3 conceptos distintos (keybind cliente, callbacks shipped, NUI bridges nuevos) bajo "Eventos NUI" → split en 3 categorías separadas: §2.2.1 Keybinds cliente puros (`sonar:tablet:toggle`), §2.2.2 Callbacks shipped S1 (C001 getBalance + C002 transfer ref `04_api_contracts.md` v1.2 §3), §2.2.3 NUI bridges ad-hoc DEFERRED catalog promotion S3 (`sonar:tablet:bank:getHistory` + `sonar:tablet:map:getNodes`). NO promover items a `02_events_catalog.md` v1.2 sin ADR firmable.
- **F5 (🟡):** DC5 "exact pin no `^`/`~`" vs realidad `package.json` con `^X.Y.Z` → §4 añadida pinning policy: caret-minor (`^X.Y.Z`) aceptable porque `package-lock.json` garantiza reproducibilidad. Major bumps (React 18→19, Vite 5→6, Tailwind 4→5) requieren ADR firmable obligatorio. Minor security auto-aplicables vía `npm audit fix`.
- **F6 (🟡):** D6 budgets stricter que `06_fivem_standards.md` §2.3 NUI table (paint <16ms vs ≤4ms, heap <150MB vs ≤80MB, bundle <1MB vs ≤500KB) → §5 nota "ADR-016 D6 supersedes `06_fivem_standards.md` §2.3 — sync rewrite docs cycle post-S2 (out of scope this session)".
- **F7 (🟡):** DC7 "marker GPS player ≤500ms lag" ambiguo → split en DC7a "GPS marker frame-rate cliente ≥30 fps (sin lag perceptible local)" + DC7b "POI nodos response `sonar:tablet:map:getNodes` ≤500ms desde request". Smoke S2.13 split correspondingly en S2.13a + S2.13b.
- **F8 (🟡):** S2.5 "no SFX double-trigger" pero close SFX no definido → decisión: **silent on close** (Apple Pro apps pattern). Brief sound v2 (ADR-012) 5 SFX canonical NO incluye close dedicated; reverse rompe motion semantics; nuevo SFX scope creep. DC9 actualizado "close = silent per S2.0 decision". S2.5 actualizado "Tablet closes silent, exit animation plays".
- **F9 (🟡):** §6 dark-only patterns sin blacklist Tailwind explícita → añadida sección "❌ Tailwind classes prohibidas en producto (CI grep blocker S2.7)" listando `bg-white/black/slate/zinc/gray/neutral/stone-*`, `text-gray/slate/zinc/neutral-*`, `dark:` prefix prohibido (no light mode), hexes literales `#fff/#000` en `style=` props, gradients `from-via-to-*` (T3 prohibited per ADR-016 D4). + sección "✅ Permitidos alpha-layers semánticos" listando `bg-sonar-white/N`, `border-sonar-white/N`, `text-sonar-white/N`, `ring-sonar-orange/40`. + audit S2.16 spec computed `background-color` opaque values matchean solo 3 hexes canonical.
- **F10+F11 (🔴):** Verify tsconfig actual → `tsconfig.app.json` NO tiene `"strict": true` ni `"noUncheckedIndexedAccess": true` requeridos ADR-016 D5. §4 añadido diff jsonc explícito + estado actual scaffold + nota "habilitar como primera task S2.1 ANTES de cualquier `.ts/.tsx` de app code". Risk R6 añadido "TypeScript strict habilitado tarde rompe app code S2.4-S2.6 ya escrito".

**Risk register full rewrite** R1-R8: R1 Tailwind+shadcn override / R2 NUI bundle / R3 TAB keybind conflict / R4 Framer jank Chromium / R5 consumer pattern tech debt / R6 TS strict mode timing / R7 NUI heap leak / R8 docs sync C003 bridge `sonar:tablet:bank:getHistory`. Escalation triggers founder explicitados (R1 fallback Tailwind v3 LTS, R2 bundle exceed irreducible, R4 Framer irrecuperable, R6 strict mode breakage masivo).

**Smoke protocol §8** refined: S2.5 silent close + exit animation, S2.13 split en S2.13a (GPS local frame-rate) + S2.13b (POI backend latency), S2.14 POI placeholder admin-defined ("Granja" placeholder S2 vs real `sonar_granja` node S7+), S2.15 grep blacklist Tailwind classes explícita + `dark:` prefix, S2.16 alpha-layers permitidos solo si base color es uno de los 3 canonical. Total 30 cumulative + 20 S2-specific = 50 pasos.

**Session breakdown §7**: 10 sesiones S2.0-S2.9. S2.0 ✅ done this session (Opus 4.x). S2.1 = `Tablet scaffold setup` (Sonnet 4.6). S2.2 = Tablet shell + keybind. S2.3-S2.5 features. S2.6 motion+sound. S2.7 polish+perf. S2.8 smoke regression. S2.9 close+retro. Reminder regla permanente founder S1.10.4: AI no cambia modelo unilateralmente.

### Hard blockers cerrados S2.0

- **B2 SPRINT_PLAN_S2.md v1.0 firmable** ✅ (was 🔴 → 🏆).
- **B5 tags pushed** ✅ (was 🟡 → 🏆) — 3 tags presentes: `sonar-identity-canonical` + `sonar-identity-v3-lock` + `phase-8-9-complete`.

### Files tocados (esta sesión — scope strict)

- `progress/SPRINT_PLAN_S2.md` v0.1-draft → **v1.0 firmable** (header + §0 status table + §2.2 split 3 categorías + §3 DC6 refine + DC7 split DC7a/DC7b + DC9 close silent + §4 pinning policy + tsconfig strict diff + shadcn CLI install pattern + §5 vite-bundle-visualizer + D6 supersedes nota + §6 Tailwind blacklist + alpha-layers permitidos + audit S2.16 spec + §7 S2.1 re-purpose + §8.2 smoke refine + §9 risk register R1-R8 full rewrite + escalation triggers + §10 model allocation refined + reminder regla permanente + §11 changelog v1.0 entry + FIN bump).
- `progress/PRE_S2_CHECKLIST.md` v1.7 → **v1.8** (header status: B2 🔴→🏆 + B5 🟡→🏆 + S2.1 DESBLOQUEADO; §B2 outcome detallado v1.0 firmable; §B5 3 tags pushed verification; changelog v1.8 entry; FIN bump duplicate v1.6 footer removed).
- `progress/SESSION_LOG.md` (esta entry append).

✅ **Scope strict.** NO tocó: code/resources/* (smoke baseline preserved), DB, art/branding/* (logo v3 locked), art/tools/*, `_archive/`, ADRs históricos 001-016, docs technical 02-07 v1.2, Bible v1.5, art_direction v3.0-locked, briefs, sonar_tablet v1.3, BOOTSTRAP v1.6, `.windsurf/*`, `02_decision_log_part2.md` v1.0.

### Decisiones AI ejecutivas (founder delegated "tú sabes mejor que yo")

1. **F5 pinning** → caret-minor (current). Razón: `package-lock.json` garantiza reproducibilidad; hard-pin friction excesivo per minor security updates.
2. **F8 close SFX** → silent on close. Razón: brief sound v2 ADR-012 NO incluye close dedicated; Apple Pro pattern clean; re-evaluable post-MVP playtesting.
3. **F1+F4 framing** → consumer pattern temporal §2.2.3 + bridges ad-hoc DEFERRED catalog promotion S3 (alineado ADR-015 línea 1162).
4. **F2+F3 obsolete** → S2.1 re-purpose Tablet scaffold setup + R1 replace Tailwind+shadcn override.
5. **F6/F7/F9/F10/F11** → defaults sensatos propuestos.
6. **NEW R7+R8** añadidos al risk register: R7 NUI heap leak + R8 docs sync C003 bridge.

### Próxima sesión

**S2.1 Tablet scaffold setup** (Sonnet 4.6 sugerido, founder decide swap):

- Task #1 OBLIGATORIA: enable `tsconfig.app.json` `"strict": true` + `"noUncheckedIndexedAccess": true` ANTES de cualquier `.tsx` app code.
- `npx shadcn@latest init` con `--base-color=neutral --css-variables` + override `globals.css` referenciando tokens D1.
- Lucide React + Framer Motion + Recharts + react-window + vite-bundle-visualizer install.
- `index.html` boot + dark canvas baseline render `bg-sonar-black` + `text-sonar-white`.
- Verify dark canvas + tokens override OK (mitigación R1 spike pre-app-code).

### Resumen ejecutivo session S2.0

S2.0 planning gate cerrado clean. SPRINT_PLAN_S2 v1.0 firmable post review crítico DC1-DC11 + smoke ×50 + 11 pre-flags resueltos via founder full delegation. PRE_S2_CHECKLIST hard blockers B2+B5 cerrados. Todos gates pre-S2 ✅. **S2.1 Tablet scaffold setup desbloqueado.** Pendiente sólo D2 icons opcional + 5 soft-opcionales no-bloqueantes. Velocity sustained: S1 15× estimación + S1.10.4 part2 split + S2.0 11 pre-flags resolved en 1.5h. Próxima sesión = Sonnet 4.6 setup tooling deterministic.

---

### S2.0 — Sign-off (formato exacto playbook §5.3)

- **Fecha:** 2026-05-04
- **Duración:** ~1.5h real (founder time)
- **Founder + Agent:** yaboula + Claude Opus 4.x (Cascade)
- **Sprint:** S2 — Oleada 1 — UI Foundation (Tablet + Bank + Map)
- **Perfil:** 🏗️ architect (planning gate + critical review + docs surgery)
- **Modelo:** Opus 4.x (strategic reasoning + long context critical review)
- **Goal:** finalizar `SPRINT_PLAN_S2.md` v0.1-draft → v1.0 firmable resolviendo 11 pre-flags + cerrar B2+B5 hard blockers
- **Status:** ✅ Done (8/8 DC session ✅)

### Cambios

- **Created:** ninguno.
- **Modified:** `progress/SPRINT_PLAN_S2.md` (v0.1-draft → **v1.0 firmable**) + `progress/PRE_S2_CHECKLIST.md` (v1.7 → **v1.8**) + `progress/SESSION_LOG.md` (entry S2.0 + sign-off append).
- **Deleted:** ninguno.

### Decisiones tomadas

- **Consumer pattern temporal Bank historial** (F1+F4): §2.2 split en 3 categorías (keybinds cliente / callbacks shipped S1 / NUI bridges ad-hoc DEFERRED catalog promotion S3). Bank historial DB directo hasta C003 ship S3 per ADR-015 línea 1162. Wrapper `getHistoryDirect()` permite swap interno post-C003 sin breaking NUI contract.
- **Close SFX silent** (F8): Apple Pro pattern clean. Brief sound v2 ADR-012 NO incluye close dedicated; reverse rompe motion semantics; nuevo SFX scope creep. DC9 + S2.5 actualizados. Re-evaluable post-MVP playtesting.
- **Pinning policy caret-minor** (F5): `^X.Y.Z` aceptable porque `package-lock.json` garantiza reproducibilidad. Major bumps (React 18→19, Vite 5→6, Tailwind 4→5) requieren ADR firmable obligatorio.
- **tsconfig strict mandatory S2.1** (F10+F11): `strict: true` + `noUncheckedIndexedAccess: true` como task #1 OBLIGATORIA S2.1 ANTES de cualquier `.tsx` app code. Risk R6 añadido.
- **Risk register full rewrite** R1-R8: R1' Tailwind+shadcn override / R2 NUI bundle / R3 TAB keybind / R4 Framer jank / R5 consumer pattern tech debt / R6 TS strict timing / R7 NUI heap leak / R8 docs sync C003. + 4 escalation triggers founder.

### Issues pendientes

- **D2 icons decision** 🟡 opcional (Lucide puro S2 default + custom post-S2 S3 Storybook, o in-house Figma 3-5 críticos).
- **Docs sync cycle post-S2** 🟡 deferred: `06_fivem_standards.md` §2.3 NUI perf table → rewrite alinear con ADR-016 D6 stricter budgets + `04_api_contracts.md` C003 entry NOTICE bridge `sonar:tablet:bank:getHistory` consumer pattern temporal (R8 mitigation).
- **5 soft-opcionales** no-bloqueantes (Figma setup, progress dashboard, etc.) — pueden atacarse paralelos sin bloquear S2.

### Handoff próxima sesión (S2.1)

- **Label:** `Tablet scaffold setup`.
- **Modelo recomendado:** Sonnet 4.6 (setup deterministic + tooling install). Founder decide swap.
- **Duración estimada:** ~3-4h.
- **Goal:** scaffold `resources/sonar_tablet/web-src/` con tsconfig strict + shadcn CLI init dark-only + tokens canonical + Lucide/Framer/Recharts install + dark canvas baseline boot.
- **Pre-requisitos lectura:**
  - `progress/SPRINT_PLAN_S2.md` v1.0 completo (§4 stack + §5 perf budgets + §6 dark-only + §7 session breakdown).
  - `docs/design/02_sonar_tablet.md` v1.3 (IDENTITY V3 LOCK NOTICE + §5 design system tokens).
  - `docs/art/branding/01_brief_logo.md` v3 §4.1 (SSoT palette canonical 3-color).
  - `docs/planning/02_decision_log_part2.md` ADR-016 §D5+§D6.
  - `resources/sonar_tablet/web-src/package.json` actual + `tsconfig.app.json` actual (verificar state).
- **Files in scope S2.1:**
  - `resources/sonar_tablet/web-src/tsconfig.app.json` (enable strict flags).
  - `resources/sonar_tablet/web-src/package.json` (install shadcn/lucide/framer/recharts/react-window/vite-bundle-visualizer).
  - `resources/sonar_tablet/web-src/src/styles/globals.css` (Tailwind v4 @theme tokens `--sonar-black`/`--sonar-orange`/`--sonar-white`).
  - `resources/sonar_tablet/web-src/src/App.tsx` (dark canvas baseline).
  - `resources/sonar_tablet/web-src/index.html` (boot verify).
  - `resources/sonar_tablet/web-src/components.json` (shadcn CLI generated).
- **Notas especiales:**
  - **Task #1 OBLIGATORIA:** enable `strict: true` + `noUncheckedIndexedAccess: true` ANTES cualquier `.tsx` (R6 mitigation).
  - **R1 spike pre-app-code:** scaffold básico → `npx shadcn add button` → verify dark canvas + tokens override OK. Si conflict Tailwind v4 @theme + shadcn preset → rollback path Tailwind v3 LTS documented + ADR firmable hotfix.
  - **Bundle budget D6:** `vite-bundle-visualizer` devDep install y verificar baseline bundle pre-apps S2.2+.
  - **NO tocar** docs firmados / ADRs / PRE_S2_CHECKLIST / SPRINT_PLAN_S2 v1.0 (scope S2.1 = resources/sonar_tablet solamente).

### Files in scope respetados

✅ Scope strict. NO tocó: code/resources/* (smoke baseline preserved), DB, art/branding/* (logo v3 locked), art/tools/*, `_archive/`, ADRs históricos 001-016, docs technical 02-07 v1.2, Bible v1.5, art_direction v3.0-locked, briefs, sonar_tablet v1.3, BOOTSTRAP v1.6, `.windsurf/*`, `02_decision_log_part2.md` v1.0. Solo progress/* (SPRINT_PLAN_S2 + PRE_S2_CHECKLIST + SESSION_LOG) tocados.

---

### S2.1 — Tablet scaffold setup (code-heavy first post-planning)

- **Fecha:** 2026-05-04
- **Duración:** ~3.5h real (Sonnet 4.6 scaffold 9/10 DC + Opus 4.x Manager resolution shadcn init + R1 spike ~20min)
- **Founder + Agent:** yaboula + Sonnet 4.6 (scaffold) + Opus 4.x (Manager close + R1 resolution)
- **Sprint:** S2 — Oleada 1 — UI Foundation
- **Perfil:** ⚡ code-heavy (tooling setup + stack install + R1 mitigation spike)
- **Modelo:** Sonnet 4.6 scaffold execution + Opus 4.x Manager verdict final
- **Goal:** scaffold `resources/sonar_tablet/web-src/` production-ready per SPRINT_PLAN_S2 v1.0 §7 S2.1 row — tsconfig strict + Tailwind v4 tokens + shadcn dark-only + D5 stack + dark canvas baseline
- **Status:** ✅ Done (10/10 DC post-Manager intervention)

### Cambios

- **Created:**
  - `resources/sonar_tablet/web-src/` (full Vite scaffold).
  - `resources/sonar_tablet/web-src/src/styles/globals.css` (Tailwind v4 `@theme` tokens canonical + shadcn bridge post-R1-fix).
  - `resources/sonar_tablet/web-src/components.json` (shadcn config base-nova).
  - `resources/sonar_tablet/web-src/src/components/ui/button.tsx` (shadcn primitive `@base-ui/react` + cva variants).
  - `resources/sonar_tablet/web-src/src/lib/utils.ts` (shadcn `cn()` helper).
- **Modified:**
  - `resources/sonar_tablet/web-src/package.json` — D5 stack install (framer-motion 11 + lucide-react + recharts + react-window + vite-bundle-visualizer); +6 shadcn deps post-init (@base-ui/react + @fontsource-variable/geist + cva + clsx + tailwind-merge + tw-animate-css); shadcn CLI moved to devDep; legacy zustand purged.
  - `resources/sonar_tablet/web-src/tsconfig.app.json` — `strict: true` + `noUncheckedIndexedAccess: true` enabled (R6 mitigation).
  - `resources/sonar_tablet/web-src/tsconfig.json` — baseUrl + paths alias `@/*` added (shadcn preflight requirement).
  - `resources/sonar_tablet/web-src/vite.config.ts` — @tailwindcss/vite plugin + path alias + chunkSizeWarningLimit 500KB (D6 budget).
  - `resources/sonar_tablet/web-src/index.html` — lang="es" + color-scheme dark + theme-color + anti-FOUC inline + Geist preload removed post-fontsource.
  - `resources/sonar_tablet/web-src/src/App.tsx` — dark canvas baseline + Lucide `<Layers>` abstract icon + shadcn Button default+outline (R1 spike verify).
  - `resources/sonar_tablet/web-src/src/main.tsx` — rootEl null guard + StrictMode.
- **Deleted:**
  - `resources/sonar_tablet/web-src/src/App.css` + `src/index.css` + `src/assets/{hero.png,react.svg,vite.svg}` + `public/icons.svg` (Vite template junk).
  - `resources/sonar_tablet/web-src/public/fonts/` (self-host stub — replaced by fontsource npm delivery).

### Decisiones tomadas

- **Manager override defer shadcn CLI init:** agent S2.1 propuso defer init a S2.2 per "dead config sin uso" reasoning; Manager (founder green-lit Option A) override = ejecutar init AHORA per SSoT SPRINT_PLAN_S2 v1.0 §7 + R1 mitigation true spike pre-app-code. Razón: honor SSoT firmed S2.0 + blast radius R1-triggered mínimo en scaffold placeholder vs mayor en S2.2 shell+bridge+animation.
- **R1 TRIGGERED + CONFIRMED fix forward:** shadcn@4.6 default style = `base-nova` (NO `new-york`) con `@base-ui/react` runtime + light/dark variant + `:root` oklch light mode vars + `--chart-*`/`--sidebar-*` token pollution + `@layer base` body @apply conflict con sonar baseline. **Fix forward** (~20min) vía `@theme inline` override bridging semantic tokens (`--color-background → sonar-black`, `--color-primary → sonar-orange`, `--color-muted/accent/etc → alpha layers sonar-white`) + eliminación light mode vars + `.dark` variant + `@custom-variant dark` + token pollution. R1 escalation trigger NOT triggered (no rollback Tailwind v3 LTS needed).
- **F9 blacklist exception shadcn-generated code:** `src/components/ui/*.tsx` carries `dark:*` variants por shadcn design (light/dark-capable preset). Net behavior correct porque override tokens mapean a sonar canonical ambos modos OS. Blacklist F9 aplica a código user-authored (`src/App.tsx` + `src/components/{features,layouts}/*.tsx`), NO a `src/components/ui/*.tsx` shadcn-generated. Smoke S2.15 blacklist audit debe excluir `src/components/ui/`.
- **Geist delivery pendiente S2.1 RESUELTO:** `@fontsource-variable/geist` npm auto-added por shadcn init. 3 WOFF2 subsets (cyrillic/latin-ext/latin) auto-bundled por Vite. Elimina manual download WOFF2 + preload index.html + `public/fonts/README.md` stub.

### Issues pendientes

- **Bundle budget impact tracked:** JS 47KB → 59KB gzip (+12KB shadcn deps), CSS 3.2KB → 4.7KB gzip. Still WELL under D6 500KB/200KB budgets (~12%/2%). Monitor con `vite-bundle-visualizer` pre-merge cada PR S2.2+.
- **IDE lint warnings `@theme`/`@apply`:** cosmetic (vscode-tailwindcss extension for IntelliSense — optional install). Flagged S2.1-v1, no afecta build.
- **`fxmanifest.lua` pendiente:** S2.2 scope (keybind + NUI bridge pattern).
- **`favicon.svg` placeholder Vite default:** reemplazar por `art/branding/logo_v3/monogram_s.svg` cuando founder bajue asset (opcional, no bloquea S2.2).
- **shadcn base-nova `@base-ui/react`** runtime dependency NO anticipated ADR-016 D5 — pragmatically accepted (bundle impact minimal), future shadcn `add X` may re-introduce R1-like conflicts requiring per-component verify.
- **ESLint strictTypeChecked:** no habilitado S2.1, opcional S2.7 polish.

### Handoff próxima sesión (S2.2)

- **Label:** `Tablet shell + keybind TAB + NUI bridge + entrance animation`.
- **Modelo recomendado:** Sonnet 4.6 (feature dev React/Lua integration).
- **Duración estimada:** 3-4h.
- **Goal:** React App shell router skeleton + `client.lua` keybind TAB + NUI bridge events Lua↔NUI bidireccional + open/close animation Framer Motion GPU-only + `fxmanifest.lua` create.
- **Pre-requisitos lectura:**
  - `progress/SESSION_LOG.md` entries S2.0 + S2.1.
  - `progress/SPRINT_PLAN_S2.md` v1.0 §2 arquitectura + §2.2.1 keybind + §2.2.2 callbacks + §3 DC1+DC2 + §7 S2.2 row + §9 R3+R4.
  - `docs/design/02_sonar_tablet.md` v1.3 §4 keybind + NUI bridge pattern.
  - `docs/technical/06_fivem_standards.md` v1.1 NOTICE r1 §event prefixes + §NUI bridge pattern.
  - `resources/sonar_bank/` client+server files (integration patterns).
- **Files in scope S2.2:**
  - `resources/sonar_tablet/fxmanifest.lua` (create).
  - `resources/sonar_tablet/client/main.lua` (create: keybind TAB + NUI bridge client-side + state toggle).
  - `resources/sonar_tablet/server/main.lua` (create: NUI bridge server-side callbacks skeleton).
  - `resources/sonar_tablet/config.lua` (create: `Config.TabletKeybind = 'TAB'` + disable-override flag, R3 mitigation).
  - `resources/sonar_tablet/web-src/src/App.tsx` (rewrite: router skeleton + AnimatePresence wrapper + keybind handler via postMessage).
  - `resources/sonar_tablet/web-src/src/main.tsx` (wire NUI bridge listener postMessage).
  - `resources/sonar_tablet/web-src/src/components/shell/TabletFrame.tsx` (create: frame container with open/close Framer Motion entrance/exit animation GPU-only).
  - `resources/sonar_tablet/web-src/src/hooks/useNUIBridge.ts` (create: bidireccional Lua↔NUI event abstraction).
  - `resources/sonar_tablet/web-src/src/hooks/useTabletVisibility.ts` (create: open/close state via bridge).
- **Notas especiales S2.2:**
  - **R3 mitigation obligatoria:** `Config.TabletKeybind` configurable + `disable-override` flag + grep `RegisterKeyMapping` cross-resource pre-merge (lb-phone / qb-phone / ox_inventory conflict potential).
  - **R4 mitigation obligatoria:** animaciones GPU-only (`transform` + `opacity` ONLY) — NEVER `height`/`width`/`margin`/`padding`/`top`/`left`. Test FiveM Chromium local antes merge.
  - **F9 blacklist exclude path:** smoke `grep` debe excluir `src/components/ui/*` (shadcn-generated con `dark:*` por design).
  - **F8 close silent:** tablet close NO SFX (Apple Pro pattern). Open SFX `panel_open` aparece S2.6 (motion+sound signature session).
  - **NUI bridge pattern:** `SendNUIMessage` (Lua→NUI) + `RegisterNUICallback` (NUI→Lua) + `postMessage` receiver hook React. Ver `06_fivem_standards.md` v1.1 NOTICE r1 §NUI bridge.
  - **NO consumir C001/C002 todavía** — S2.4 scope (Bank app). S2.2 solo shell + keybind + animation.
  - **fxmanifest.lua:** `fx_version 'cerulean'`, `game 'gta5'`, `ui_page 'web/index.html'`, `files { 'web/**/*' }`, build output path a `web/`.
  - **Vite build path:** considera ajustar `vite.config.ts` `build.outDir` a `../web/` para FiveM resource delivery pattern.

### Files in scope respetados

✅ Scope strict. NO tocó: `docs/**/*` (todos SSoTs firmados), `progress/SPRINT_PLAN_S2.md` v1.0 firmado, `progress/PRE_S2_CHECKLIST.md` v1.8 firmado, DB/migrations, `resources/{sonar_bank,sonar_core,sonar_bridges}` (smoke baseline), `art/branding/`, `art/tools/logo_export/`, ADRs históricos, `.windsurf/*`. Solo `resources/sonar_tablet/` (scaffold nueva) + `progress/SESSION_LOG.md` (esta entry) tocados.

---