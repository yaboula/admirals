-- =============================================================================
-- Admirals Bridges — server/dispatcher.lua
--
-- Core runtime utilities:
--   1. Bridges.Dispatcher.Call(module, method, args) — invoca método del
--      adapter activo con pcall wrapping + boundary logging + latency metric.
--   2. Bridges._IsIdemReplay / Bridges._StoreIdem — idempotency helpers
--      usados por adapters (Bank principalmente) per doc §4.3.
--
-- Decisión arquitectónica (per plan ARCHITECT S0.2):
--   Dispatch con funciones explícitas per bridge, NO metatable magic. Esto
--   facilita debug (stack traces nominados), LuaCATS annotations, y mantiene
--   contratos visibles en cada bridge file.
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §2.1 (stack), §1.1 B5
--     (async-by-default), §1.1 B6 (idempotent), §1.1 B7 (logged at boundary).
-- =============================================================================

Bridges = Bridges or {}
Bridges.Dispatcher = {}

local Logger = Bridges.Logger

-- =============================================================================
-- Idempotency store — pluggable backend (S1.2).
--
-- Default: in-memory store (compat S0.2 — se pierde en reboot, fine para
-- single-server transient idem). admirals_core en su boot post-DB-ready llama
-- `Bridges.SetIdempotencyBackend({ resource='admirals_core', getExport='IdempotencyGet',
-- setExport='IdempotencySet', gcExport='IdempotencyGC' })` que swappea a DB-backed
-- (`admirals_bridge_idempotency` table — survives reboots).
--
-- Cross-VM constraint:
--   admirals_bridges no depende de admirals_core (jerarquía bridges → core).
--   Las VMs Lua FiveM son aisladas — `_G.Admirals` no es visible aquí.
--   Solución: el backend se exposes via exports (strings de resource+export
--   name, NO function refs cross-VM que son fragility-prone).
--
-- Backend interface (3 exports en el resource provider):
--   getExport(key) → nil | { result = any_lua_table, expires = unix_ts }
--   setExport(key, result_table, ttl_sec) → boolean
--   gcExport()      → number_purged | nil  (opcional, ejecutado en GC thread)
-- =============================================================================

local _idem_memory = {}  -- [key] = { result = any, expires = unix_ts }

-- Spec del backend activo. resource=nil → memory mode (default).
local _idem_backend = {
  resource = nil,
  getExport = nil,
  setExport = nil,
  gcExport = nil,
}

-- ----------------------------------------------------------------------------
-- Helpers internos para invocar backend remote-aware.
-- En memory mode son lookups locales O(1). En db mode son exports cross-VM.
-- ----------------------------------------------------------------------------
local function _backend_get(key)
  if _idem_backend.resource then
    local ok, ret = pcall(function()
      return exports[_idem_backend.resource][_idem_backend.getExport](nil, key)
    end)
    if not ok then
      Logger.Warn('Idempotency backend Get failed: %s — falling back to no-replay',
        tostring(ret))
      return nil
    end
    return ret  -- nil | { result, expires }
  end
  return _idem_memory[key]  -- { result, expires } | nil
end

local function _backend_set(key, result, ttl_sec)
  if _idem_backend.resource then
    local ok, err = pcall(function()
      return exports[_idem_backend.resource][_idem_backend.setExport](nil, key, result, ttl_sec)
    end)
    if not ok then
      Logger.Warn('Idempotency backend Set failed: %s — entry NOT persisted', tostring(err))
    end
    return
  end
  _idem_memory[key] = { result = result, expires = os.time() + ttl_sec }
end

local function _backend_gc()
  if _idem_backend.resource and _idem_backend.gcExport then
    local ok, ret = pcall(function()
      return exports[_idem_backend.resource][_idem_backend.gcExport](nil)
    end)
    if not ok then
      Logger.Warn('Idempotency backend GC failed: %s', tostring(ret))
      return 0
    end
    return tonumber(ret) or 0
  end
  -- Memory GC.
  local now = os.time()
  local purged = 0
  for key, entry in pairs(_idem_memory) do
    if entry.expires < now then
      _idem_memory[key] = nil
      purged = purged + 1
    end
  end
  return purged
end

-- Cleanup thread: cada 5 min purga entradas expiradas.
CreateThread(function()
  while true do
    Wait(5 * 60 * 1000)
    local purged = _backend_gc()
    if (purged or 0) > 0 then
      Logger.Debug('Idempotency GC: purged %d expired keys', purged)
    end
  end
end)

-- -----------------------------------------------------------------------------
-- Bridges.SetIdempotencyBackend — swap backend implementation runtime.
--
-- @param spec table | string
--   Si table: { resource = string, getExport = string, setExport = string,
--              gcExport? = string }
--   Si string == 'memory': revert a in-memory backend.
--
-- Llamado por admirals_core en boot post-DB-ready para promover a DB-backed.
-- Idempotente: si swap a backend equivalente ya activo, no-op.
-- -----------------------------------------------------------------------------
function Bridges.SetIdempotencyBackend(spec)
  if spec == 'memory' or spec == nil then
    _idem_backend.resource = nil
    _idem_backend.getExport = nil
    _idem_backend.setExport = nil
    _idem_backend.gcExport = nil
    Logger.Info('Idempotency backend: memory (in-process, lost on reboot)')
    return true
  end

  if type(spec) ~= 'table'
     or type(spec.resource) ~= 'string' or spec.resource == ''
     or type(spec.getExport) ~= 'string' or spec.getExport == ''
     or type(spec.setExport) ~= 'string' or spec.setExport == '' then
    Logger.Error('SetIdempotencyBackend: invalid spec — must be table with resource/getExport/setExport strings')
    return false
  end

  _idem_backend.resource = spec.resource
  _idem_backend.getExport = spec.getExport
  _idem_backend.setExport = spec.setExport
  _idem_backend.gcExport = spec.gcExport  -- opcional

  Logger.Info('Idempotency backend swapped: resource=%s (get=%s set=%s gc=%s)',
    spec.resource, spec.getExport, spec.setExport, spec.gcExport or 'none')
  return true
end

-- -----------------------------------------------------------------------------
-- Bridges._IsIdemReplay — check si key fue usada recientemente con éxito.
--
-- Firma estable (S0.2 contract per founder green-light S1.2): NO cambia
-- aunque el backend interno haya pivotado a DB.
--
-- @param key string|nil — idempotency key (nil = no idempotency check).
-- @return boolean is_replay, any cached_result
-- -----------------------------------------------------------------------------
function Bridges._IsIdemReplay(key)
  if type(key) ~= 'string' or key == '' then return false, nil end
  local entry = _backend_get(key)
  if not entry then return false, nil end
  if (entry.expires or 0) < os.time() then
    -- Memory backend lazy-purge; DB backend tiene WHERE expires_at > NOW filter.
    if not _idem_backend.resource then _idem_memory[key] = nil end
    return false, nil
  end
  return true, entry.result
end

-- -----------------------------------------------------------------------------
-- Bridges._StoreIdem — persiste result asociado a key con TTL.
--
-- Firma estable (S0.2 contract).
--
-- @param key string — idempotency key.
-- @param result any — resultado a devolver en replays (lua table).
-- -----------------------------------------------------------------------------
function Bridges._StoreIdem(key, result)
  if type(key) ~= 'string' or key == '' then return end
  local ttl = Config.IdempotencyTTLSec or 3600
  _backend_set(key, result, ttl)
end

-- -----------------------------------------------------------------------------
-- Bridges._IdemStoreSize — útil para tests / metrics.
-- (Memory only — DB backend no expone count cheap; admin command consulta DB
-- directamente vía SQL en admirals_core.)
-- -----------------------------------------------------------------------------
function Bridges._IdemStoreSize()
  if _idem_backend.resource then return -1 end  -- N/A en DB mode
  local n = 0
  for _ in pairs(_idem_memory) do n = n + 1 end
  return n
end

-- -----------------------------------------------------------------------------
-- Bridges._IdemStoreClear — útil para tests (memory only).
-- -----------------------------------------------------------------------------
function Bridges._IdemStoreClear()
  _idem_memory = {}
end

-- -----------------------------------------------------------------------------
-- Bridges._IdemBackendName — introspection helper para tests + boot report.
-- -----------------------------------------------------------------------------
function Bridges._IdemBackendName()
  return _idem_backend.resource and ('db@' .. _idem_backend.resource) or 'memory'
end

-- =============================================================================
-- Cross-resource exports — Lua VMs aisladas; consumers (admirals_bank etc.)
-- consumen idempotency vía estos exports en lugar de _G.Bridges directo.
-- =============================================================================

exports('SetIdempotencyBackend', Bridges.SetIdempotencyBackend)

-- IsIdemReplay export — firmando para uso desde admirals_bank/server/callbacks.lua
-- C002 transfer flow.
--
-- Returns: { is_replay = boolean, cached = any | nil }
-- (Wrapping en table porque exports cross-VM no preservan multi-return ideally.)
exports('IsIdemReplay', function(key)
  local is_replay, cached = Bridges._IsIdemReplay(key)
  return { is_replay = is_replay == true, cached = cached }
end)

exports('StoreIdem', function(key, result)
  Bridges._StoreIdem(key, result)
  return true
end)

exports('IdemBackendName', Bridges._IdemBackendName)

-- =============================================================================
-- Dispatcher.Call — invocador canónico para todos los bridge methods.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Bridges.Dispatcher.Call — routes call al adapter activo.
--
-- @param module string — 'bank'|'inventory'|'phone'|'identity'|'target'|'notify'
-- @param method string — método del adapter a invocar.
-- @param args table — array-like de argumentos posicionales.
--
-- @return ...  — todos los valores retornados por impl[method].
--                En caso de error: nil, 'BRIDGE_UNAVAILABLE'|'METHOD_NOT_IMPLEMENTED'|'FAILED'.
--
-- Behavior:
--   1. Resuelve adapter activo via Bridges.GetActive(module).
--   2. Valida método existe en impl.
--   3. Invoca con pcall wrapping (previene adapter crashes colapsar caller).
--   4. Mide latency (ms via GetGameTimer).
--   5. Emite Logger.Boundary(...) con audit entry completa.
-- -----------------------------------------------------------------------------
function Bridges.Dispatcher.Call(module, method, args)
  local adapter_name, impl = Bridges.GetActive(module)

  if not adapter_name or not impl then
    Logger.Error('Dispatcher.Call: no active adapter for module "%s"', module)
    return nil, 'BRIDGE_UNAVAILABLE'
  end

  if type(impl[method]) ~= 'function' then
    Logger.Error('Dispatcher.Call: adapter %s/%s has no method "%s"',
      module, adapter_name, method)
    return nil, 'METHOD_NOT_IMPLEMENTED'
  end

  args = args or {}
  local start_ms = GetGameTimer()

  -- pcall wrapping: captura tanto multiple return values como errors.
  -- table.pack / table.unpack para preservar múltiples valores.
  local packed = table.pack(pcall(impl[method], table.unpack(args, 1, args.n or #args)))
  local latency_ms = GetGameTimer() - start_ms

  local ok = packed[1]

  if not ok then
    local err = packed[2]
    Logger.Error('Dispatcher.Call: %s/%s threw error: %s',
      module, adapter_name, tostring(err))
    Logger.Boundary(module, method, args,
      { error = tostring(err) }, latency_ms, adapter_name)
    return nil, 'FAILED'
  end

  -- Boundary audit log (siempre persistido, emitido a console si enabled).
  -- Nota: no serializamos args/result completo para evitar overhead — sólo ref.
  Logger.Boundary(module, method, args,
    { ok = true, nargs_returned = packed.n - 1 }, latency_ms, adapter_name)

  -- Devolver todos los valores después del pcall ok flag.
  return table.unpack(packed, 2, packed.n)
end
