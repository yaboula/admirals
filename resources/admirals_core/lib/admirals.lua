-- =============================================================================
-- Admirals Core — lib/admirals.lua
--
-- Helper library para CONSUMERS (admirals_bank, admirals_empresa, etc.).
--
-- Patrón de uso:
--   En fxmanifest.lua del resource consumer:
--     server_scripts {
--       '@admirals_core/lib/admirals.lua',  -- carga ESTE file en la VM del consumer.
--       'server/...lua',                     -- tu código.
--     }
--
-- Por qué un lib file y no _G compartido:
--   FiveM crea una Lua VM aislada por resource → _G.Admirals de admirals_core
--   NO es visible en admirals_bank. Este file se INCLUYE en la VM del consumer
--   y proporciona una fachada thin que delega via exports.admirals_core a la
--   VM real donde viven Logger/DB/Bus/Rate/Metrics/Migrations.
--
-- API expuesta (todas thin wrappers — ver exports admirals_core/server/init.lua):
--
--   Admirals.Core.{IsReady,WaitReady,Version,GetMigrationReport}
--   Admirals.DB.{FetchOne,FetchAll,Execute,Insert,Scalar,Transaction}
--   Admirals.Bus.{Subscribe,Unsubscribe,Publish,RegisterSchema,Stats}
--   Admirals.Rate.{Check,RegisterBucket,Reset,Stats}
--   Admirals.Log.{Debug,Info,Warn,Error,Audit,SetLevel,GetLevel,Size}
--   Admirals.Metrics.{Counter,Gauge,Observe,Get,Snapshot,Reset}
--   Admirals.Identity.{OnPlayerLoaded,OnPlayerDropped}
--
-- Decisiones diseño:
--   1. Wrappers SON funciones en la VM consumer — NO closures cross-resource.
--      Cada llamada hace dispatch fresh via exports.admirals_core.
--   2. Subscribe handlers se almacenan localmente en _local_subs y se invoca
--      desde admirals_core via TriggerEvent fan-out (evita pasar function refs
--      cross-resource — fragile per FiveM Lua VM model).
--   3. Identity hooks se hacen via AddEventHandler nativo FiveM al evento
--      admirals_bridges interno 'admirals:bridge:_identityPlayerLoaded' —
--      future-proof: si Bridges promociona a evento public, este lib lo
--      abstrae sin breaking callers.
--   4. WaitReady SIEMPRE debe llamarse antes de uso real. La lib NO bloquea
--      su propia load — solo registra namespace y deja que el consumer
--      sincronice contra core ready en su propio init thread.
--
-- Referencias SSoT:
--   docs/technical/01_architecture.md §1 (resource isolation FiveM Lua VMs).
--   docs/technical/04_api_contracts.md §6 (DB) + §8 (Rate) + §10.3 (Audit).
--   docs/technical/02_events_catalog.md §1.4 (event payload shape).
--   docs/planning/02_decision_log.md ADR-010 (audit_log usage).
-- =============================================================================

Admirals = Admirals or {}
Admirals.Core = Admirals.Core or {}
Admirals.DB = Admirals.DB or {}
Admirals.Bus = Admirals.Bus or {}
Admirals.Rate = Admirals.Rate or {}
Admirals.Log = Admirals.Log or {}
Admirals.Metrics = Admirals.Metrics or {}
Admirals.Identity = Admirals.Identity or {}

-- Resource name del consumer que carga esta lib (admirals_bank, admirals_empresa, ...).
local _consumer_resource = GetCurrentResourceName() or 'unknown'

-- Subscriptions locales del consumer (handlers en SU VM, no cross-resource).
-- _local_subs[event_name] = { [local_id] = handler_fn }
local _local_subs = {}
local _next_local_sub_id = 1

-- Cache rate buckets registered por este consumer (para introspection).
local _registered_buckets = {}

-- =============================================================================
-- Helper interno — pcall wrapping de llamadas a exports.admirals_core.
-- Si el export no existe (admirals_core no cargado), error claro.
-- =============================================================================
local function _safe_export(method, ...)
  local ok, result = pcall(function(...)
    return exports.admirals_core[method](exports.admirals_core, ...)
  end, ...)
  if not ok then
    error(string.format('[admirals_lib] exports.admirals_core:%s failed: %s',
      method, tostring(result)), 3)
  end
  return result
end

-- =============================================================================
-- Admirals.Core — boot orchestration helpers.
-- =============================================================================

function Admirals.Core.IsReady()
  return _safe_export('IsReady') == true
end

function Admirals.Core.WaitReady(timeout_ms)
  return _safe_export('WaitReady', timeout_ms or 30000) == true
end

function Admirals.Core.Version()
  return _safe_export('Version')
end

function Admirals.Core.GetMigrationReport()
  return _safe_export('GetMigrationReport')
end

-- =============================================================================
-- Admirals.DB — wrappers prepared-statement (delegan a admirals_core/server/db.lua).
-- =============================================================================

function Admirals.DB.FetchOne(query, params)
  return _safe_export('DBFetchOne', query, params or {})
end

function Admirals.DB.FetchAll(query, params)
  return _safe_export('DBFetchAll', query, params or {})
end

function Admirals.DB.Execute(query, params)
  return _safe_export('DBExecute', query, params or {})
end

function Admirals.DB.Insert(query, params)
  return _safe_export('DBInsert', query, params or {})
end

function Admirals.DB.Scalar(query, params)
  return _safe_export('DBScalar', query, params or {})
end

function Admirals.DB.Transaction(queries)
  return _safe_export('DBTransaction', queries)
end

-- =============================================================================
-- Admirals.Bus — pub/sub canónico (delegan a admirals_core/server/event_bus.lua).
--
-- Subscribe pattern:
--   El handler vive en la VM del consumer (no cross-VM). admirals_core mantiene
--   un registro de "este resource quiere notificación de event X" y, cuando
--   Publish dispara, hace TriggerEvent('admirals_lib:dispatch:'..event_name)
--   con el payload — y todos los resources que tengan AddEventHandler sobre ese
--   evento server-wide reciben el dispatch.
--
-- Esto evita pasar function refs cross-resource (no soportado fiable en FiveM).
-- =============================================================================

-- Internal — listener server-wide para dispatch fan-out desde admirals_core.
-- Cada Publish en admirals_core dispara este TriggerEvent server-wide; cada
-- consumer filtra por sus suscripciones locales.
AddEventHandler('admirals_lib:dispatch', function(event_name, payload)
  local subs = _local_subs[event_name]
  if not subs then return end
  for local_id, handler in pairs(subs) do
    local ok, err = pcall(handler, payload)
    if not ok then
      print(string.format(
        '^1[admirals_lib] handler %s for %s crashed in %s: %s^7',
        local_id, event_name, _consumer_resource, tostring(err)))
    end
    -- Auto-unsubscribe si once (encoded en local_id prefix).
    if type(local_id) == 'string' and local_id:sub(1, 5) == 'once_' then
      subs[local_id] = nil
    end
  end
end)

function Admirals.Bus.Subscribe(event_name, handler, opts)
  if type(event_name) ~= 'string' or event_name == '' then
    error('[Admirals.Bus.Subscribe] event_name must be non-empty string', 2)
  end
  if type(handler) ~= 'function' then
    error('[Admirals.Bus.Subscribe] handler must be function', 2)
  end
  opts = opts or {}

  -- Registrar globally con admirals_core (idempotente — core trackea por resource).
  -- El método BusRegisterConsumerInterest no consume function ref, solo registra
  -- el evento name + resource origen para enrutar dispatch.
  _safe_export('BusRegisterConsumerInterest', event_name, _consumer_resource)

  -- Storage local del handler.
  local prefix = opts.once and 'once_' or 'sub_'
  local local_id = prefix .. _next_local_sub_id
  _next_local_sub_id = _next_local_sub_id + 1

  _local_subs[event_name] = _local_subs[event_name] or {}
  _local_subs[event_name][local_id] = handler

  return local_id
end

function Admirals.Bus.Unsubscribe(local_id)
  for event_name, subs in pairs(_local_subs) do
    if subs[local_id] then
      subs[local_id] = nil
      return true
    end
  end
  return false
end

function Admirals.Bus.Publish(event_name, payload, opts)
  return _safe_export('BusPublish', event_name, payload or {}, opts or {})
end

function Admirals.Bus.RegisterSchema(event_name, validator_name)
  -- Validators son function refs — no cross-resource. Solo se permite registrar
  -- por nombre de validator pre-registrado en admirals_core. Phase 1: no-op
  -- (schemas se hardcodean en admirals_core S1+ cuando haya catalog real).
  -- Mantenemos la firma para compatibilidad future.
  return _safe_export('BusRegisterSchemaByName', event_name, validator_name)
end

function Admirals.Bus.Stats()
  return _safe_export('BusStats')
end

-- =============================================================================
-- Admirals.Rate — sliding window rate limiter.
-- =============================================================================

function Admirals.Rate.Check(identity, bucket_key)
  return _safe_export('RateCheck', identity, bucket_key) == true
end

function Admirals.Rate.RegisterBucket(key, def)
  if type(key) ~= 'string' or key == '' then
    error('[Admirals.Rate.RegisterBucket] key must be non-empty string', 2)
  end
  if type(def) ~= 'table' or type(def.max) ~= 'number' or type(def.window_sec) ~= 'number' then
    error('[Admirals.Rate.RegisterBucket] def must be { max=number, window_sec=number }', 2)
  end
  _registered_buckets[key] = def
  return _safe_export('RateRegisterBucket', key, def)
end

function Admirals.Rate.Reset(identity, bucket_key)
  return _safe_export('RateReset', identity, bucket_key)
end

function Admirals.Rate.Stats()
  return _safe_export('RateStats')
end

-- =============================================================================
-- Admirals.Log — logger estructurado.
--
-- NOTA: format string + varargs no se serializan bien cross-resource. Lo
-- formateamos local primero y mandamos string final a admirals_core.
-- =============================================================================

local function _format_safe(fmt, ...)
  if select('#', ...) == 0 then return tostring(fmt) end
  local ok, result = pcall(string.format, fmt, ...)
  return ok and result or tostring(fmt)
end

function Admirals.Log.Debug(fmt, ...)
  _safe_export('LogDebug', _consumer_resource, _format_safe(fmt, ...))
end

function Admirals.Log.Info(fmt, ...)
  _safe_export('LogInfo', _consumer_resource, _format_safe(fmt, ...))
end

function Admirals.Log.Warn(fmt, ...)
  _safe_export('LogWarn', _consumer_resource, _format_safe(fmt, ...))
end

function Admirals.Log.Error(fmt, ...)
  _safe_export('LogError', _consumer_resource, _format_safe(fmt, ...))
end

function Admirals.Log.Audit(entry)
  if type(entry) ~= 'table' then
    error('[Admirals.Log.Audit] entry must be table', 2)
  end
  -- Decoramos con resource origen automáticamente.
  entry.resource = entry.resource or _consumer_resource
  return _safe_export('LogAudit', entry)
end

function Admirals.Log.SetLevel(level)
  return _safe_export('LogSetLevel', level)
end

function Admirals.Log.GetLevel()
  return _safe_export('LogGetLevel')
end

function Admirals.Log.Size()
  return _safe_export('LogSize')
end

-- =============================================================================
-- Admirals.Metrics — counters + gauges + histograms.
-- =============================================================================

function Admirals.Metrics.Counter(key, delta)
  return _safe_export('MetricsCounter', key, delta or 1)
end

function Admirals.Metrics.Gauge(key, value)
  return _safe_export('MetricsGauge', key, value)
end

function Admirals.Metrics.Observe(key, value)
  return _safe_export('MetricsObserve', key, value)
end

function Admirals.Metrics.Get(key)
  return _safe_export('MetricsGet', key)
end

function Admirals.Metrics.Snapshot()
  return _safe_export('MetricsSnapshot')
end

function Admirals.Metrics.Reset()
  return _safe_export('MetricsReset')
end

-- =============================================================================
-- Admirals.Identity — lifecycle hooks player loaded / dropped.
--
-- ABSTRACCIÓN sobre el evento internal `admirals:bridge:_identityPlayerLoaded`
-- emitido por admirals_bridges adapters (qbox/qbcore/esx/native).
--
-- FUTURE-PROOF: si admirals_bridges promociona a evento public canónico
-- 'admirals:identity:player_loaded' (S2+), esta lib actualizará SU implementación
-- internal sin breaking a callers. La firma del callback se mantiene estable:
--   callback(citizenId: string, source: number)
--
-- Limitación actual: el adapter framework activo (qbox/qbcore/esx/native) DEBE
-- emitir el evento `admirals:bridge:_identityPlayerLoaded`. Verificado para los
-- 4 adapters en S0.3.
-- =============================================================================

local _loaded_handlers = {}
local _dropped_handlers = {}

-- Single AddEventHandler registered en la VM consumer — invoca a todos los
-- handlers registrados via OnPlayerLoaded.
AddEventHandler('admirals:bridge:_identityPlayerLoaded', function(citizenId, source)
  for _, fn in ipairs(_loaded_handlers) do
    local ok, err = pcall(fn, citizenId, source)
    if not ok then
      print(string.format(
        '^1[admirals_lib/Identity] OnPlayerLoaded handler in %s threw: %s^7',
        _consumer_resource, tostring(err)))
    end
  end
end)

AddEventHandler('admirals:bridge:_identityPlayerDropped', function(citizenId, source, reason)
  for _, fn in ipairs(_dropped_handlers) do
    local ok, err = pcall(fn, citizenId, source, reason)
    if not ok then
      print(string.format(
        '^1[admirals_lib/Identity] OnPlayerDropped handler in %s threw: %s^7',
        _consumer_resource, tostring(err)))
    end
  end
end)

--- Admirals.Identity.OnPlayerLoaded — registra callback para player loaded.
---@param callback fun(citizenId: string, source: number)
function Admirals.Identity.OnPlayerLoaded(callback)
  if type(callback) ~= 'function' then
    error('[Admirals.Identity.OnPlayerLoaded] callback must be function', 2)
  end
  _loaded_handlers[#_loaded_handlers + 1] = callback
end

--- Admirals.Identity.OnPlayerDropped — registra callback para player dropped.
---@param callback fun(citizenId: string, source: number, reason: string)
function Admirals.Identity.OnPlayerDropped(callback)
  if type(callback) ~= 'function' then
    error('[Admirals.Identity.OnPlayerDropped] callback must be function', 2)
  end
  _dropped_handlers[#_dropped_handlers + 1] = callback
end

-- =============================================================================
-- Boot announce (lib loaded en la VM consumer).
-- =============================================================================
print(string.format('^5[admirals_lib] loaded in %s — Admirals namespace ready^7',
  _consumer_resource))
