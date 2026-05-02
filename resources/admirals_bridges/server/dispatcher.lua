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
-- Idempotency store — in-memory con TTL (S0.2 impl).
-- Promovido a DB-backed `admirals_bridge_idempotency` table en S0.4.
-- =============================================================================

local _idem_store = {}  -- [key] = { result = any, expires = unix_ts }

-- Cleanup thread: cada 5 min purga entradas expiradas.
-- Overhead negligible (O(n) sobre store, típicamente <100 keys activas).
CreateThread(function()
  while true do
    Wait(5 * 60 * 1000)  -- 5 min
    local now = os.time()
    local purged = 0
    for key, entry in pairs(_idem_store) do
      if entry.expires < now then
        _idem_store[key] = nil
        purged = purged + 1
      end
    end
    if purged > 0 then
      Logger.Debug('Idempotency GC: purged %d expired keys', purged)
    end
  end
end)

-- -----------------------------------------------------------------------------
-- Bridges._IsIdemReplay — check si key fue usada recientemente con éxito.
--
-- @param key string|nil — idempotency key (nil = no idempotency check).
-- @return boolean is_replay, any cached_result
-- -----------------------------------------------------------------------------
function Bridges._IsIdemReplay(key)
  if type(key) ~= 'string' or key == '' then return false, nil end
  local entry = _idem_store[key]
  if not entry then return false, nil end
  if entry.expires < os.time() then
    _idem_store[key] = nil
    return false, nil
  end
  return true, entry.result
end

-- -----------------------------------------------------------------------------
-- Bridges._StoreIdem — persiste result asociado a key con TTL.
--
-- @param key string — idempotency key.
-- @param result any — resultado a devolver en replays.
-- -----------------------------------------------------------------------------
function Bridges._StoreIdem(key, result)
  if type(key) ~= 'string' or key == '' then return end
  _idem_store[key] = {
    result = result,
    expires = os.time() + (Config.IdempotencyTTLSec or 3600),
  }
end

-- -----------------------------------------------------------------------------
-- Bridges._IdemStoreSize — útil para tests / metrics.
-- -----------------------------------------------------------------------------
function Bridges._IdemStoreSize()
  local n = 0
  for _ in pairs(_idem_store) do n = n + 1 end
  return n
end

-- -----------------------------------------------------------------------------
-- Bridges._IdemStoreClear — útil para tests.
-- -----------------------------------------------------------------------------
function Bridges._IdemStoreClear()
  _idem_store = {}
end

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
