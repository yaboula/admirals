-- =============================================================================
-- SONAR Bank App — lib/rate_limit.lua
-- =============================================================================
-- Token-bucket rate limiter per (player, tier) en memory.
-- M003 — Dual rate-limit recursive guard for C035 audit query (per-citizen +
-- global + bypass exception scope=self single).
--
-- Algorithm: Token bucket
--   - Each (subject_key, tier) pair has a bucket { tokens, last_refill_ms }.
--   - On Check(): refill tokens proportionally to elapsed time, consume 1, deny if 0.
--   - Refill rate: capacity / 60s (steady state allows `refill_per_min` per minute).
--
-- Subject keys:
--   - 'player:<src>:<tier>'  (per-player per-tier bucket)
--   - 'audit_query:citizen:<cid>' (M003 per-citizen audit query)
--   - 'audit_query:global'   (M003 global audit query)
--
-- Recursive guard (M003): when audit_service queries audit ledger en el course
-- de processing C035, we must NOT trigger rate-limit recursion. Use coroutine-
-- local guard `_recursion_depth`.
--
-- Deps: lib/enums.lua + lib/errors.lua.
-- =============================================================================

BankApp.lib.rate_limit = {}
local M = BankApp.lib.rate_limit

local Enums  = BankApp.lib.enums
local Errors = BankApp.lib.errors
local Config = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. Bucket storage (in-memory)
-- -----------------------------------------------------------------------------

-- Buckets indexed by string key. Each bucket: { tokens=number, last_refill_ms=number, capacity=number, refill_per_min=number }
local _buckets = {}

-- Recursive guard depth counter (M003)
local _recursion_depth = 0

-- Get current ms timestamp (server uptime)
local function now_ms()
  return GetGameTimer()
end

-- Get tier config from Config.RateLimits.
local function tier_config(tier)
  if tier == Enums.TIER.TIER_1_READ then return Config.RateLimits.TIER_1_READ
  elseif tier == Enums.TIER.TIER_2_WRITE then return Config.RateLimits.TIER_2_WRITE
  elseif tier == Enums.TIER.TIER_3_ADMIN then return Config.RateLimits.TIER_3_ADMIN
  else return Config.RateLimits.DEFAULT end
end

-- Get audit-query specific config (M003 dual rate-limit overridable via convars)
local function audit_query_config()
  local per_citizen = GetConvarInt(
    Config.Convars.AUDIT_QUERY_PER_CITIZEN_PER_MIN.name,
    Config.RateLimits.AUDIT_QUERY.per_citizen_per_min
  )
  local global = GetConvarInt(
    Config.Convars.AUDIT_QUERY_GLOBAL_PER_MIN.name,
    Config.RateLimits.AUDIT_QUERY.global_per_min
  )
  return per_citizen, global, Config.RateLimits.AUDIT_QUERY.bypass_self_single
end

-- Get-or-create bucket for given key with capacity/refill config.
local function get_bucket(key, capacity, refill_per_min)
  local b = _buckets[key]
  if not b then
    b = {
      tokens         = capacity,
      last_refill_ms = now_ms(),
      capacity       = capacity,
      refill_per_min = refill_per_min,
    }
    _buckets[key] = b
  end
  return b
end

-- Refill bucket proportional to elapsed time.
local function refill(bucket)
  local now = now_ms()
  local elapsed_ms = now - bucket.last_refill_ms
  if elapsed_ms <= 0 then return end

  -- tokens_to_add = elapsed_ms * (refill_per_min / 60000)
  local tokens_to_add = elapsed_ms * bucket.refill_per_min / 60000.0

  if tokens_to_add > 0 then
    bucket.tokens = math.min(bucket.capacity, bucket.tokens + tokens_to_add)
    bucket.last_refill_ms = now
  end
end

-- Compute retry_after_ms estimation given empty bucket.
local function compute_retry_after(bucket)
  if bucket.refill_per_min <= 0 then return 60000 end  -- pessimistic 1 minute
  -- Time to get 1 token = (60000 ms / refill_per_min) ms
  return math.ceil(60000 / bucket.refill_per_min)
end

-- -----------------------------------------------------------------------------
-- §2. Core Check primitives
-- -----------------------------------------------------------------------------

--- Check: per-player-per-tier rate limit.
---@param src integer player source id
---@param tier string Enums.TIER value
---@return boolean ok
---@return table|nil err standardized error con retry_after_ms en details
function M.Check(src, tier)
  if type(src) ~= 'number' or src <= 0 then
    return false, Errors.New('VALIDATION_FAILED', { reason = 'invalid src' })
  end
  if not Enums.IsValid(Enums.TIER, tier) then
    return false, Errors.New('VALIDATION_FAILED', { reason = 'invalid tier', tier = tostring(tier) })
  end

  local cfg = tier_config(tier)
  local key = ('player:%d:%s'):format(src, tier)
  local b = get_bucket(key, cfg.capacity, cfg.refill_per_min)

  refill(b)

  if b.tokens < 1 then
    return false, Errors.New('RATE_LIMIT_EXCEEDED', {
      tier            = tier,
      src             = src,
      retry_after_ms  = compute_retry_after(b),
      capacity        = b.capacity,
    })
  end

  b.tokens = b.tokens - 1
  return true, nil
end

-- -----------------------------------------------------------------------------
-- §3. M003 — Audit query dual rate-limit recursive guard
--
--   Rules:
--     - Per-citizen: 1/min (default, convar overridable)
--     - Global:      10/min (default, convar overridable)
--     - Bypass exception: scope='self' AND limit=1 (single-row read of own audit)
--     - Recursive guard: si _recursion_depth > 0, skip rate-limit (internal call)
--
--   Caller pattern:
--     local ok, err = rate_limit.CheckAuditQuery(actor_cid, target_cid, scope, limit)
--     if not ok then return err end
--     ...
--
--   Para internal queries (e.g. audit writer dedupe check), wrap with:
--     rate_limit.WithRecursionGuard(function() ... end)
-- -----------------------------------------------------------------------------

--- CheckAuditQuery: M003 dual rate-limit + bypass + recursive guard.
---@param actor_citizen_id string id del solicitante
---@param target_citizen_id string|nil id objetivo (nil = global query)
---@param scope string|nil 'self' | 'other' | 'global'
---@param limit integer|nil rows requested (afecta bypass)
---@return boolean ok
---@return table|nil err
function M.CheckAuditQuery(actor_citizen_id, target_citizen_id, scope, limit)
  -- Recursive guard — internal queries durante audit processing skip rate-limit
  if _recursion_depth > 0 then
    return true, nil
  end

  if type(actor_citizen_id) ~= 'string' or #actor_citizen_id == 0 then
    return false, Errors.New('VALIDATION_FAILED', { reason = 'invalid actor_citizen_id' })
  end

  local per_citizen_limit, global_limit, bypass_self_single = audit_query_config()

  -- Bypass exception (M003 §9.35.5.1): scope=self AND limit=1
  if bypass_self_single and scope == 'self' and limit == 1 then
    return true, nil
  end

  -- Per-citizen check (key based on actor)
  local citizen_key = 'audit_query:citizen:' .. actor_citizen_id
  local cb = get_bucket(citizen_key, per_citizen_limit, per_citizen_limit)
  refill(cb)
  if cb.tokens < 1 then
    return false, Errors.New('RATE_LIMIT_EXCEEDED', {
      scope          = 'audit_query_per_citizen',
      actor          = actor_citizen_id,
      retry_after_ms = compute_retry_after(cb),
    })
  end

  -- Global check (single shared bucket)
  local global_key = 'audit_query:global'
  local gb = get_bucket(global_key, global_limit, global_limit)
  refill(gb)
  if gb.tokens < 1 then
    return false, Errors.New('RATE_LIMIT_EXCEEDED', {
      scope          = 'audit_query_global',
      retry_after_ms = compute_retry_after(gb),
    })
  end

  -- Both buckets passed → consume both
  cb.tokens = cb.tokens - 1
  gb.tokens = gb.tokens - 1
  return true, nil
end

--- WithRecursionGuard: execute fn with _recursion_depth incremented.
---   Use cuando audit_service must query audit table internally during
---   processing of an audit-related callback to avoid recursive rate-limit.
---@param fn function
---@param ... any args para fn
---@return any ... resultados de fn
function M.WithRecursionGuard(fn, ...)
  _recursion_depth = _recursion_depth + 1
  local results = { pcall(fn, ...) }
  _recursion_depth = _recursion_depth - 1

  if not results[1] then
    error(results[2], 2)  -- re-raise pcall error
  end
  return table.unpack(results, 2)
end

-- -----------------------------------------------------------------------------
-- §4. Diagnostic / admin helpers
-- -----------------------------------------------------------------------------

--- Reset: reset bucket(s). Useful para grace period (M001).
---@param key_pattern string|nil if nil, reset all. Else string match (Lua patterns).
---@return integer reset_count
function M.Reset(key_pattern)
  local count = 0
  if not key_pattern then
    count = 0
    for k in pairs(_buckets) do
      _buckets[k] = nil
      count = count + 1
    end
    return count
  end
  for k in pairs(_buckets) do
    if k:match(key_pattern) then
      _buckets[k] = nil
      count = count + 1
    end
  end
  return count
end

--- ResetPlayer: clear all buckets para a specific src.
---@param src integer
---@return integer reset_count
function M.ResetPlayer(src)
  return M.Reset('^player:' .. tostring(src) .. ':')
end

--- GetState: introspect bucket (debug).
---@param key string
---@return table|nil
function M.GetState(key)
  return _buckets[key]
end

--- ListAllKeys: para debugging.
---@return table array of bucket keys
function M.ListAllKeys()
  local keys = {}
  for k in pairs(_buckets) do
    keys[#keys + 1] = k
  end
  return keys
end

--- GetRecursionDepth: introspection (test harness).
---@return integer
function M.GetRecursionDepth()
  return _recursion_depth
end

return M
