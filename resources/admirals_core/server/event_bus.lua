-- =============================================================================
-- Admirals Core — server/event_bus.lua
--
-- Pub/sub interno Admirals. Implementa el patrón canonical definido en
-- docs/technical/01_architecture.md §5.5.
--
-- API pública:
--   Admirals.Bus.Subscribe(event_name, handler, opts?)  → sub_id (string)
--   Admirals.Bus.Unsubscribe(sub_id)                    → boolean
--   Admirals.Bus.Publish(event_name, payload, opts?)    → boolean
--   Admirals.Bus.RegisterSchema(event_name, validator)  — opcional.
--   Admirals.Bus.Stats()                                → { events, subs, ... }
--
-- Publish comportamiento:
--   1. Validate payload tipo table (no string/nil).
--   2. Auto-decorar meta: _event_name, _event_id (UUID v4),
--      _emitted_at (unix ms), _schema_version (default 1).
--      Per docs/technical/02_events_catalog.md §1.4.
--   3. Schema validation si RegisterSchema previo — reject si fail.
--   4. Distribuir a subs sync por default; async si opts.async ó handler
--      flagged slow (>BusAsyncThresholdMs previo).
--   5. pcall per handler — 1 handler crashing no afecta a otros.
--   6. Metrics: publishes_total{event}, subscribers_lag_ms{event,p99}.
--   7. Audit log (Log.Audit) si BusAuditMode = 'always' o event marked.
--
-- Opts:
--   opts.async = true               — forzar handler en thread separado.
--   opts.broadcast_client = src|-1  — TriggerClientEvent post-publish.
--   opts.audit = true|false         — override BusAuditMode per-publish.
--
-- Subscribe opts:
--   opts.async = true               — handler siempre async.
--   opts.once = true                — auto-unsubscribe tras primer call.
--   opts.label = string             — debug label.
--
-- Referencias SSoT:
--   docs/technical/01_architecture.md §5 (EventBus completo).
--   docs/technical/02_events_catalog.md §1.4 (payload shape).
--   docs/technical/06_fivem_standards.md §3.3 (throttling).
-- =============================================================================

Admirals = Admirals or {}
Admirals.Bus = Admirals.Bus or {}

local Config = Admirals.Config
local Log = Admirals.Log
local Metrics = Admirals.Metrics
local Bus = Admirals.Bus

-- -----------------------------------------------------------------------------
-- Storage — subscribers indexados por event_name + id secuencial global.
-- -----------------------------------------------------------------------------
local _subscribers = {}  -- [event_name] = { [sub_id] = { fn, opts, slow } }
local _sub_index = {}    -- [sub_id] = event_name  (para unsubscribe O(1))
local _next_sub_id = 1

-- -----------------------------------------------------------------------------
-- Schemas registrados (opcional por evento).
-- -----------------------------------------------------------------------------
local _schemas = {}  -- [event_name] = validator_fn(payload) -> ok, err

-- -----------------------------------------------------------------------------
-- Internal — UUID v4 generator (RFC 4122 §4.4).
-- Usado para _event_id. No criptográficamente seguro pero suficiente para
-- tracing (colisión probabilidad ≈ 2^-122 per emission).
-- -----------------------------------------------------------------------------
local function _uuid_v4()
  -- Pattern: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx  (y ∈ [8,b])
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return (template:gsub('[xy]', function(c)
    local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
    return string.format('%x', v)
  end))
end

-- Seed math.random con high-resolution timer + os.time para evitar colisiones
-- en server restarts rápidos.
math.randomseed((os.time() * 1000 + (GetGameTimer() or 0)) % 2147483647)

-- -----------------------------------------------------------------------------
-- Internal — validate event name format.
-- Canonical: 'admirals:domain:action' per §01 §5.4.
-- -----------------------------------------------------------------------------
local function _validate_event_name(name)
  if type(name) ~= 'string' or name == '' then
    return false, 'event_name must be non-empty string'
  end
  -- No hard-enforce del triple-colon en S0.4 (permite eventos simples para tests),
  -- pero validamos chars: lowercase alphanumeric + underscore + colon.
  if not name:match('^[a-z0-9_:]+$') then
    return false, 'event_name must match ^[a-z0-9_:]+$'
  end
  return true
end

-- -----------------------------------------------------------------------------
-- Public — Subscribe.
-- -----------------------------------------------------------------------------
function Bus.Subscribe(event_name, handler, opts)
  local ok, err = _validate_event_name(event_name)
  if not ok then
    error('[Admirals.Bus.Subscribe] ' .. err, 2)
  end
  if type(handler) ~= 'function' then
    error('[Admirals.Bus.Subscribe] handler must be function', 2)
  end
  opts = opts or {}

  local sub_id = 'sub_' .. _next_sub_id
  _next_sub_id = _next_sub_id + 1

  _subscribers[event_name] = _subscribers[event_name] or {}
  _subscribers[event_name][sub_id] = {
    fn = handler,
    opts = opts,
    slow = false,  -- flagged si pcall tarda >BusAsyncThresholdMs.
  }
  _sub_index[sub_id] = event_name

  Metrics.Counter('bus.subscriptions_total')
  Metrics.Gauge('bus.active_subscriptions', _next_sub_id - 1)

  if opts.label then
    Log.Debug('Bus.Subscribe %s → %s [%s]', event_name, sub_id, opts.label)
  else
    Log.Debug('Bus.Subscribe %s → %s', event_name, sub_id)
  end

  return sub_id
end

-- -----------------------------------------------------------------------------
-- Public — Unsubscribe.
-- -----------------------------------------------------------------------------
function Bus.Unsubscribe(sub_id)
  local event_name = _sub_index[sub_id]
  if not event_name then return false end

  _sub_index[sub_id] = nil
  if _subscribers[event_name] then
    _subscribers[event_name][sub_id] = nil
    -- Limpiar tabla vacía.
    if next(_subscribers[event_name]) == nil then
      _subscribers[event_name] = nil
    end
  end
  Log.Debug('Bus.Unsubscribe %s (was %s)', sub_id, event_name)
  return true
end

-- -----------------------------------------------------------------------------
-- Public — RegisterSchema — validator opcional por evento.
--
-- @param validator function(payload) -> true | false, err_string.
-- -----------------------------------------------------------------------------
function Bus.RegisterSchema(event_name, validator)
  if type(validator) ~= 'function' then
    error('[Admirals.Bus.RegisterSchema] validator must be function', 2)
  end
  _schemas[event_name] = validator
  Log.Debug('Bus.RegisterSchema registered for %s', event_name)
end

-- -----------------------------------------------------------------------------
-- Internal — decorate payload con tracing fields (§02 §1.4).
-- -----------------------------------------------------------------------------
local function _decorate(event_name, payload)
  payload._event_name = event_name
  payload._event_id = _uuid_v4()
  payload._emitted_at = os.time() * 1000 + (GetGameTimer() % 1000)
  payload._schema_version = payload._schema_version or 1
end

-- -----------------------------------------------------------------------------
-- Internal — dispatch handler with pcall + latency metric + slow flag.
-- -----------------------------------------------------------------------------
local function _dispatch(event_name, sub_id, sub, payload)
  local start = GetGameTimer()
  local ok, err = pcall(sub.fn, payload)
  local latency = GetGameTimer() - start

  Metrics.Observe('bus.handler_latency_ms.' .. event_name, latency)

  if not ok then
    Metrics.Counter('bus.handler_errors.' .. event_name)
    Log.Error('Bus handler %s for %s crashed after %dms: %s',
      sub_id, event_name, latency, tostring(err))
  end

  -- Slow flag — próxima invocación irá async.
  if latency > Config.BusAsyncThresholdMs and not sub.slow then
    sub.slow = true
    Log.Warn('Bus handler %s for %s flagged async (took %dms > %dms threshold)',
      sub_id, event_name, latency, Config.BusAsyncThresholdMs)
  end

  -- Auto-unsubscribe si once.
  if sub.opts.once then
    Bus.Unsubscribe(sub_id)
  end
end

-- -----------------------------------------------------------------------------
-- Public — Publish.
-- -----------------------------------------------------------------------------
function Bus.Publish(event_name, payload, opts)
  opts = opts or {}

  local ok, err = _validate_event_name(event_name)
  if not ok then
    Log.Error('Bus.Publish rejected: %s', err)
    Metrics.Counter('bus.rejects.invalid_name')
    return false
  end

  if type(payload) ~= 'table' then
    Log.Error('Bus.Publish %s rejected: payload must be table, got %s',
      event_name, type(payload))
    Metrics.Counter('bus.rejects.invalid_payload')
    return false
  end

  -- Schema validation si registered.
  local schema = _schemas[event_name]
  if schema then
    local s_ok, s_err = schema(payload)
    if not s_ok then
      Log.Error('Bus.Publish %s schema validation failed: %s',
        event_name, tostring(s_err))
      Metrics.Counter('bus.rejects.schema.' .. event_name)
      return false
    end
  end

  -- Decorate (muta el payload — per §02 §1.4 es comportamiento esperado).
  _decorate(event_name, payload)

  Metrics.Counter('bus.publishes.' .. event_name)

  -- Audit log — según BusAuditMode + opts override.
  local should_audit = (opts.audit == true)
    or (opts.audit ~= false and Config.BusAuditMode == 'always')
  if should_audit then
    Log.Audit({
      category = 'bus.publish',
      action = event_name,
      actor = opts.actor,
      target = opts.target,
      payload = {
        event_id = payload._event_id,
        emitted_at = payload._emitted_at,
      },
    })
  end

  -- Dispatch a suscriptores.
  local subs = _subscribers[event_name]
  if subs then
    for sub_id, sub in pairs(subs) do
      local force_async = opts.async or sub.opts.async or sub.slow
      if force_async then
        Citizen.CreateThread(function()
          _dispatch(event_name, sub_id, sub, payload)
        end)
      else
        _dispatch(event_name, sub_id, sub, payload)
      end
    end
  end

  -- Broadcast a clientes si solicitado (per §01 §5.5 opts.broadcast_to_clients).
  if opts.broadcast_client ~= nil then
    local target = opts.broadcast_client
    TriggerClientEvent(event_name, target, payload)
    Metrics.Counter('bus.broadcasts.' .. event_name)
  end

  return true
end

-- -----------------------------------------------------------------------------
-- Public — Stats — útil para tests + admin status.
-- -----------------------------------------------------------------------------
function Bus.Stats()
  local event_count = 0
  local sub_count = 0
  local by_event = {}

  for ev, subs in pairs(_subscribers) do
    event_count = event_count + 1
    local n = 0
    for _ in pairs(subs) do n = n + 1 end
    sub_count = sub_count + n
    by_event[ev] = n
  end

  return {
    distinct_events = event_count,
    total_subscribers = sub_count,
    registered_schemas = (function()
      local n = 0
      for _ in pairs(_schemas) do n = n + 1 end
      return n
    end)(),
    subscribers_by_event = by_event,
  }
end

-- -----------------------------------------------------------------------------
-- Boot announce.
-- -----------------------------------------------------------------------------
Log.Info('EventBus ready (audit_mode=%s, async_threshold=%dms, wildcard=%s)',
  Config.BusAuditMode, Config.BusAsyncThresholdMs,
  Config.BusWildcardEnabled and 'on' or 'off')
