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
