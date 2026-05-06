-- =============================================================================
-- SONAR Bank App — lib/idempotency.lua
-- =============================================================================
-- Persistent idempotency keys (DB) + LRU in-memory cache + M005 orphan TTL purge.
--
-- Schema (DB table `bank_idempotency_keys` from sonar_core migrations):
--   key                VARCHAR(128) PK   (caller-provided unique key)
--   status             ENUM('in_flight', 'committed', 'orphan', 'orphan_purged')
--   payload_hash       VARCHAR(64)  NOT NULL  (SHA256 of canonical request payload)
--   result_payload     JSON         NULL  (cached result on commit)
--   actor_citizen_id   VARCHAR(64)  NULL
--   callback_id        VARCHAR(32)  NULL  (e.g. 'C006' transfer:execute)
--   created_at         TIMESTAMP    DEFAULT CURRENT_TIMESTAMP(6)
--   committed_at       TIMESTAMP    NULL
--   ttl_expires_at     TIMESTAMP    NOT NULL  (M005 orphan purge target column)
--   cross_ref_audit_id VARCHAR(36)  NULL
--
-- Lifecycle:
--   1. Acquire(key, payload_hash, ttl) → INSERT in_flight, returns 'acquired' OR
--      'replay' (if key+hash matches committed) OR 'collision' (key+different_hash)
--      OR 'in_flight' (concurrent caller). H006 cross_ref_audit_id stored.
--   2. Commit(key, result) → UPDATE status='committed', result_payload=result
--   3. Orphan(key) → UPDATE status='orphan' (called on caller failure / timeout)
--   4. Replay(key) → SELECT result_payload WHERE status='committed' AND key=?
--   5. PurgeOrphans() (M005 cron) → DELETE WHERE status='orphan' AND
--      ttl_expires_at < NOW() — emits audit event_type='idempotency_orphan_purged'.
--
-- LRU cache (1000 entries) avoids redundant DB reads para hot keys.
--
-- Deps: lib/enums + errors + db + uuid + audit + hmac (for payload_hash via SHA256).
-- =============================================================================

BankApp.lib.idempotency = {}
local M = BankApp.lib.idempotency

local Enums  = BankApp.lib.enums
local Errors = BankApp.lib.errors
local DB     = BankApp.lib.db
local UUID   = BankApp.lib.uuid
local Audit  = BankApp.lib.audit
local HMAC   = BankApp.lib.hmac
local Config = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. LRU cache (in-memory, 1k entries)
--
--   Implementation: ordered linked list via array + index map. Evict oldest on
--   capacity overflow. Access bumps to head.
-- -----------------------------------------------------------------------------

local _cache = {
  -- key → { key, status, payload_hash, result_payload, ttl_expires_ms, prev, next }
  nodes        = {},
  head         = nil,    -- most recently used
  tail         = nil,    -- least recently used
  size         = 0,
  capacity     = Config.Idempotency.CACHE_LRU_SIZE,
}

local function lru_remove(node)
  if node.prev then node.prev.next = node.next else _cache.head = node.next end
  if node.next then node.next.prev = node.prev else _cache.tail = node.prev end
  node.prev = nil
  node.next = nil
end

local function lru_push_head(node)
  node.prev = nil
  node.next = _cache.head
  if _cache.head then _cache.head.prev = node end
  _cache.head = node
  if not _cache.tail then _cache.tail = node end
end

local function lru_get(key)
  local node = _cache.nodes[key]
  if not node then return nil end
  -- bump to head
  lru_remove(node)
  lru_push_head(node)
  return node
end

local function lru_set(key, data)
  local existing = _cache.nodes[key]
  if existing then
    -- update in place + bump
    for k, v in pairs(data) do existing[k] = v end
    lru_remove(existing)
    lru_push_head(existing)
    return
  end

  local node = {
    key            = key,
    status         = data.status,
    payload_hash   = data.payload_hash,
    result_payload = data.result_payload,
    ttl_expires_ms = data.ttl_expires_ms,
    prev = nil, next = nil,
  }
  _cache.nodes[key] = node
  lru_push_head(node)
  _cache.size = _cache.size + 1

  -- Evict if over capacity
  if _cache.size > _cache.capacity and _cache.tail then
    local evict = _cache.tail
    _cache.nodes[evict.key] = nil
    lru_remove(evict)
    _cache.size = _cache.size - 1
  end
end

local function lru_invalidate(key)
  local node = _cache.nodes[key]
  if node then
    _cache.nodes[key] = nil
    lru_remove(node)
    _cache.size = _cache.size - 1
  end
end

-- -----------------------------------------------------------------------------
-- §2. Hash payload helper (canonicalize → SHA256)
--
--   payload tables hashed deterministically: keys sorted, primitive values only.
--   Provides collision resistance per M006 SHA256 implementation.
-- -----------------------------------------------------------------------------

local function canonical_serialize(t)
  if type(t) ~= 'table' then
    return tostring(t)
  end
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = tostring(k) end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do
    local v = t[k]
    if type(v) == 'table' then
      parts[#parts + 1] = k .. ':{' .. canonical_serialize(v) .. '}'
    else
      parts[#parts + 1] = k .. ':' .. tostring(v)
    end
  end
  return table.concat(parts, '|')
end

--- HashPayload: SHA256 of canonical serialization. Returns 64 hex chars.
---@param payload table|string
---@return string hex_64
function M.HashPayload(payload)
  local serialized = type(payload) == 'string' and payload or canonical_serialize(payload)
  return HMAC.SHA256(serialized)
end

-- -----------------------------------------------------------------------------
-- §3. Acquire / Commit / Orphan / Replay
-- -----------------------------------------------------------------------------

local SQL_INSERT_IN_FLIGHT = [[
INSERT INTO bank_idempotency_keys
  (`key`, status, payload_hash, actor_citizen_id, callback_id, ttl_expires_at, cross_ref_audit_id)
VALUES
  (?, 'in_flight', ?, ?, ?, FROM_UNIXTIME(?/1000), ?)
ON DUPLICATE KEY UPDATE `key` = `key`
]]

local SQL_SELECT_KEY = [[
SELECT
  `key`, status, payload_hash, result_payload,
  UNIX_TIMESTAMP(ttl_expires_at)*1000 AS ttl_expires_ms,
  cross_ref_audit_id
FROM bank_idempotency_keys
WHERE `key` = ?
LIMIT 1
]]

local SQL_UPDATE_COMMIT = [[
UPDATE bank_idempotency_keys
SET status = 'committed',
    result_payload = ?,
    committed_at = CURRENT_TIMESTAMP(6)
WHERE `key` = ? AND status = 'in_flight'
]]

local SQL_UPDATE_ORPHAN = [[
UPDATE bank_idempotency_keys
SET status = 'orphan'
WHERE `key` = ? AND status = 'in_flight'
]]

local SQL_PURGE_ORPHANS = [[
DELETE FROM bank_idempotency_keys
WHERE status IN ('orphan', 'in_flight')
  AND ttl_expires_at < (NOW(6) - INTERVAL ? MINUTE)
LIMIT 500
]]

--- Acquire: claim key for in-flight processing.
---
---   Returns ('acquired', nil, nil) → caller proceeds with operation
---   Returns ('replay', cached_result, nil) → caller returns cached result
---   Returns ('collision', nil, err) → key exists with different payload (REUSED)
---   Returns ('in_flight', nil, err) → concurrent caller still processing
---
---@param key string idempotency key
---@param payload table|string request payload (será hashed)
---@param opts table|nil { actor_citizen_id, callback_id, ttl_seconds, cross_ref_audit_id }
---@return string status ('acquired'|'replay'|'collision'|'in_flight')
---@return any cached_result (nil except status='replay')
---@return table|nil err
function M.Acquire(key, payload, opts)
  opts = opts or {}

  if type(key) ~= 'string' or #key < 16 then
    return nil, nil, Errors.New('VALIDATION_FAILED', { reason = 'idempotency key invalid' })
  end

  local payload_hash = M.HashPayload(payload)
  local ttl_seconds = opts.ttl_seconds or Config.Idempotency.DEFAULT_TTL_SECONDS
  local ttl_expires_ms = math.floor(os.time() * 1000) + (ttl_seconds * 1000)

  -- Check LRU cache first
  local cached = lru_get(key)
  if cached then
    if cached.status == Enums.IDEMPOTENCY_STATUS.COMMITTED then
      if cached.payload_hash == payload_hash then
        return 'replay', cached.result_payload, nil
      else
        return 'collision', nil, Errors.New('IDEMPOTENCY_KEY_REUSED', { key = key })
      end
    elseif cached.status == Enums.IDEMPOTENCY_STATUS.IN_FLIGHT then
      -- Check grace period
      if cached.ttl_expires_ms and cached.ttl_expires_ms < math.floor(os.time() * 1000) then
        -- TTL expired — fall through to DB lookup (orphan candidate)
      else
        return 'in_flight', nil, Errors.New('IDEMPOTENCY_IN_FLIGHT', { key = key })
      end
    end
    -- ORPHAN / ORPHAN_PURGED → fall through to DB (re-attempt allowed)
    lru_invalidate(key)
  end

  -- DB lookup
  local row, err = DB.QuerySingle(SQL_SELECT_KEY, { key })
  if err then return nil, nil, err end

  if row then
    -- Existing entry
    if row.status == Enums.IDEMPOTENCY_STATUS.COMMITTED then
      if row.payload_hash == payload_hash then
        -- Cache + return replay
        lru_set(key, {
          status         = row.status,
          payload_hash   = row.payload_hash,
          result_payload = row.result_payload,
          ttl_expires_ms = row.ttl_expires_ms,
        })
        return 'replay', row.result_payload, nil
      else
        return 'collision', nil, Errors.New('IDEMPOTENCY_KEY_REUSED', { key = key })
      end
    elseif row.status == Enums.IDEMPOTENCY_STATUS.IN_FLIGHT then
      return 'in_flight', nil, Errors.New('IDEMPOTENCY_IN_FLIGHT', { key = key })
    end
    -- ORPHAN / ORPHAN_PURGED → re-claim allowed
  end

  -- INSERT in_flight (idempotent via ON DUPLICATE KEY)
  local _, ins_err = DB.Execute(SQL_INSERT_IN_FLIGHT, {
    key,
    payload_hash,
    opts.actor_citizen_id,
    opts.callback_id,
    ttl_expires_ms,
    opts.cross_ref_audit_id,
  })
  if ins_err then return nil, nil, ins_err end

  lru_set(key, {
    status         = Enums.IDEMPOTENCY_STATUS.IN_FLIGHT,
    payload_hash   = payload_hash,
    ttl_expires_ms = ttl_expires_ms,
  })

  return 'acquired', nil, nil
end

--- Commit: mark key committed + cache result.
---@param key string
---@param result_payload table|nil result a cachear (será JSON-encoded)
---@return boolean ok
---@return table|nil err
function M.Commit(key, result_payload)
  if type(key) ~= 'string' then
    return false, Errors.New('VALIDATION_FAILED', { reason = 'invalid key' })
  end

  -- Encode result as JSON
  local json_result = nil
  if result_payload ~= nil then
    if json and json.encode then
      json_result = json.encode(result_payload)
    else
      json_result = tostring(result_payload)
    end
  end

  local affected, err = DB.Execute(SQL_UPDATE_COMMIT, { json_result, key })
  if err then return false, err end
  if affected == 0 then
    return false, Errors.New('IDEMPOTENCY_KEY_EXPIRED', {
      key    = key,
      reason = 'commit failed: row not in_flight (TTL expired or never acquired)',
    })
  end

  -- Update LRU cache
  local cached = _cache.nodes[key]
  if cached then
    cached.status         = Enums.IDEMPOTENCY_STATUS.COMMITTED
    cached.result_payload = result_payload
  end

  return true, nil
end

--- Orphan: mark key orphan (caller failed mid-processing).
---@param key string
---@return boolean ok
---@return table|nil err
function M.Orphan(key)
  if type(key) ~= 'string' then
    return false, Errors.New('VALIDATION_FAILED', { reason = 'invalid key' })
  end

  local _, err = DB.Execute(SQL_UPDATE_ORPHAN, { key })
  if err then return false, err end

  local cached = _cache.nodes[key]
  if cached then
    cached.status = Enums.IDEMPOTENCY_STATUS.ORPHAN
  end
  return true, nil
end

--- Replay: lookup committed result. Returns result OR nil.
---@param key string
---@return any result
---@return table|nil err
function M.Replay(key)
  if type(key) ~= 'string' then
    return nil, Errors.New('VALIDATION_FAILED', { reason = 'invalid key' })
  end

  local cached = lru_get(key)
  if cached and cached.status == Enums.IDEMPOTENCY_STATUS.COMMITTED then
    return cached.result_payload, nil
  end

  local row, err = DB.QuerySingle(SQL_SELECT_KEY, { key })
  if err then return nil, err end
  if not row or row.status ~= Enums.IDEMPOTENCY_STATUS.COMMITTED then
    return nil, nil
  end

  -- Cache + return
  lru_set(key, {
    status         = row.status,
    payload_hash   = row.payload_hash,
    result_payload = row.result_payload,
    ttl_expires_ms = row.ttl_expires_ms,
  })
  return row.result_payload, nil
end

-- -----------------------------------------------------------------------------
-- §4. M005 — PurgeOrphans cron
--
--   Deletes orphans + in_flight TTL-expired entries.
--   Emits audit event_type='idempotency_orphan_purged' con count.
--   Called every 5min by boot/cron.lua.
-- -----------------------------------------------------------------------------

--- PurgeOrphans: cron task. Emits audit + returns purged_count.
---@return integer purged_count
---@return table|nil err
function M.PurgeOrphans()
  local age_min = Config.Idempotency.ORPHAN_PURGE_AGE_MIN

  local affected, err = DB.Execute(SQL_PURGE_ORPHANS, { age_min })
  if err then return 0, err end

  if affected and affected > 0 then
    -- Emit audit entry (M005)
    Audit.Write({
      event_type   = Enums.AUDIT_EVENT_TYPE.IDEMPOTENCY_ORPHAN_PURGED,
      actor_citizen_id = nil,  -- system action
      target_citizen_id = nil,
      event_data = {
        purged_count = affected,
        age_min      = age_min,
        ts_ms        = math.floor(os.time() * 1000),
      },
    })
  end

  return affected or 0, nil
end

-- -----------------------------------------------------------------------------
-- §5. Diagnostics
-- -----------------------------------------------------------------------------

--- GetCacheStats
---@return table
function M.GetCacheStats()
  return {
    size     = _cache.size,
    capacity = _cache.capacity,
  }
end

--- ClearCache: testing helper.
function M.ClearCache()
  _cache.nodes = {}
  _cache.head = nil
  _cache.tail = nil
  _cache.size = 0
end

return M
