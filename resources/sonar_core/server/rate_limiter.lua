-- =============================================================================
-- SONAR Core — server/rate_limiter.lua
--
-- Sliding-window rate limiter per (citizenId, bucket). Memory-only S0.4;
-- distributed version (Redis/DB) considerada Oleada 2+ si multi-server.
--
-- API pública:
--   SONAR.Rate.Check(identity, bucket_key) → true (allowed) | false (blocked)
--   SONAR.Rate.RegisterBucket(key, { max, window_sec })
--   SONAR.Rate.GetBucket(key)                → def | nil
--   SONAR.Rate.Reset(identity?, bucket?)     — reset all, identity, o par.
--   SONAR.Rate.Stats()                       → { tracked_identities, ... }
--
-- Identity:
--   Puede ser citizenId ('ABC123') o source (number) — el caller decide.
--   Internamente se stringify.
--
-- Algorithm — sliding window con array de timestamps:
--   _state[bucket][identity] = { [i] = unix_ms }
--   Check:
--     1. Purge timestamps < now - window_ms.
--     2. Si count >= max → block.
--     3. Else → append now, allow.
--
-- Complejidad: O(k) per check donde k = samples en ventana (max).
-- Memory: ~16 bytes/sample × max × active_identities. Ej. max=60, 200 active
-- citizenIds → ~200 KB. Safe per §06 §2.1.
--
-- GC thread:
--   Cada Config.RateGcIntervalSec purga entries vacíos (identities sin
--   timestamps activos). Evita memory leak por citizens ya offline.
--
-- Referencias SSoT:
--   docs/technical/04_api_contracts.md §8.1-§8.2 (rate limits catalog).
--   docs/technical/06_fivem_standards.md §4 T6 (rate abuse mitigation).
-- =============================================================================

SONAR = SONAR or {}
SONAR.Rate = SONAR.Rate or {}

local Config = SONAR.Config
local Log = SONAR.Log
local Metrics = SONAR.Metrics
local Rate = SONAR.Rate

-- -----------------------------------------------------------------------------
-- Storage — dos tablas separadas:
--   _buckets: definiciones { max, window_sec, window_ms }.
--   _state:   runtime [bucket][identity] = timestamps_ms[].
-- -----------------------------------------------------------------------------
local _buckets = {}
local _state = {}  -- [bucket_key] = { [identity_str] = { ts1, ts2, ... } }

-- -----------------------------------------------------------------------------
-- Internal — bootstrap default buckets desde Config.
-- -----------------------------------------------------------------------------
local function _init_default_buckets()
  for key, def in pairs(Config.RateBuckets or {}) do
    _buckets[key] = {
      max = def.max,
      window_sec = def.window_sec,
      window_ms = def.window_sec * 1000,
    }
    _state[key] = {}
  end
end

-- -----------------------------------------------------------------------------
-- Public — RegisterBucket — callers pueden registrar buckets runtime.
-- -----------------------------------------------------------------------------
function Rate.RegisterBucket(key, def)
  if type(key) ~= 'string' or key == '' then
    error('[SONAR.Rate.RegisterBucket] key must be non-empty string', 2)
  end
  if type(def) ~= 'table' or type(def.max) ~= 'number' or type(def.window_sec) ~= 'number' then
    error('[SONAR.Rate.RegisterBucket] def must be { max=number, window_sec=number }', 2)
  end
  if def.max < 1 or def.window_sec < 1 then
    error('[SONAR.Rate.RegisterBucket] max and window_sec must be >= 1', 2)
  end

  _buckets[key] = {
    max = def.max,
    window_sec = def.window_sec,
    window_ms = def.window_sec * 1000,
  }
  _state[key] = _state[key] or {}
  Log.Debug('Rate bucket registered: %s (max=%d, window=%ds)',
    key, def.max, def.window_sec)
end

-- -----------------------------------------------------------------------------
-- Public — GetBucket.
-- -----------------------------------------------------------------------------
function Rate.GetBucket(key)
  local def = _buckets[key]
  if not def then return nil end
  return { max = def.max, window_sec = def.window_sec }
end

-- -----------------------------------------------------------------------------
-- Public — Check — returns true si permitido (y consume 1 token), false si bloqueado.
--
-- @param identity string|number  — citizenId canónico o source.
-- @param bucket_key string        — bucket previamente registered.
-- @return boolean allowed.
-- -----------------------------------------------------------------------------
function Rate.Check(identity, bucket_key)
  local def = _buckets[bucket_key]
  if not def then
    Log.Warn('Rate.Check on unknown bucket: %s — allowing (fail-open)', tostring(bucket_key))
    Metrics.Counter('rate.unknown_bucket')
    return true
  end

  if identity == nil then
    Log.Warn('Rate.Check with nil identity on bucket %s — allowing', bucket_key)
    return true
  end

  local id_str = tostring(identity)
  local now_ms = os.time() * 1000 + (GetGameTimer() % 1000)
  local cutoff = now_ms - def.window_ms

  _state[bucket_key] = _state[bucket_key] or {}
  local timestamps = _state[bucket_key][id_str]
  if not timestamps then
    timestamps = {}
    _state[bucket_key][id_str] = timestamps
  end

  -- Purge expired (array shift via rebuild — eficiente para small windows).
  local kept = {}
  for i = 1, #timestamps do
    if timestamps[i] >= cutoff then
      kept[#kept + 1] = timestamps[i]
    end
  end
  _state[bucket_key][id_str] = kept

  -- Check.
  if #kept >= def.max then
    Metrics.Counter('rate.blocked.' .. bucket_key)
    return false
  end

  kept[#kept + 1] = now_ms
  Metrics.Counter('rate.allowed.' .. bucket_key)
  return true
end

-- -----------------------------------------------------------------------------
-- Public — Reset — all, per identity, o per (bucket, identity).
--
-- @param identity string|nil
-- @param bucket_key string|nil
-- -----------------------------------------------------------------------------
function Rate.Reset(identity, bucket_key)
  if identity == nil and bucket_key == nil then
    for key in pairs(_state) do _state[key] = {} end
    Log.Debug('Rate.Reset full')
    return
  end

  local id_str = identity ~= nil and tostring(identity) or nil

  if bucket_key then
    _state[bucket_key] = _state[bucket_key] or {}
    if id_str then
      _state[bucket_key][id_str] = nil
    else
      _state[bucket_key] = {}
    end
  else
    -- identity sin bucket → purge en todos los buckets.
    for key, t in pairs(_state) do
      if id_str then t[id_str] = nil end
    end
  end
end

-- -----------------------------------------------------------------------------
-- Public — Stats — para tests + admin.
-- -----------------------------------------------------------------------------
function Rate.Stats()
  local tracked = 0
  local buckets_count = 0
  local by_bucket = {}

  for key, t in pairs(_state) do
    buckets_count = buckets_count + 1
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    by_bucket[key] = n
    tracked = tracked + n
  end

  local defs = {}
  for k, d in pairs(_buckets) do
    defs[k] = { max = d.max, window_sec = d.window_sec }
  end

  return {
    tracked_identity_bucket_pairs = tracked,
    registered_buckets = buckets_count,
    active_identities_by_bucket = by_bucket,
    bucket_defs = defs,
  }
end

-- =============================================================================
-- GC thread — purga identities sin timestamps activos (citizens offline).
-- =============================================================================
CreateThread(function()
  local interval_ms = (Config.RateGcIntervalSec or 300) * 1000
  while true do
    Wait(interval_ms)
    local now_ms = os.time() * 1000
    local purged = 0
    for bucket_key, def in pairs(_buckets) do
      local bucket_state = _state[bucket_key]
      if bucket_state then
        for id_str, timestamps in pairs(bucket_state) do
          -- Si el último timestamp está fuera del window, purge.
          local last = timestamps[#timestamps] or 0
          if last < (now_ms - def.window_ms) then
            bucket_state[id_str] = nil
            purged = purged + 1
          end
        end
      end
    end
    if purged > 0 then
      Log.Debug('Rate GC: purged %d inactive identity-bucket pairs', purged)
      Metrics.Counter('rate.gc_purged', purged)
    end
  end
end)

-- -----------------------------------------------------------------------------
-- Boot — init defaults + announce.
-- -----------------------------------------------------------------------------
_init_default_buckets()
local _bucket_count = 0
for _ in pairs(_buckets) do _bucket_count = _bucket_count + 1 end
Log.Info('RateLimiter ready (%d default buckets, gc_interval=%ds)',
  _bucket_count, Config.RateGcIntervalSec or 300)
