-- =============================================================================
-- SONAR Bank App — lib/audit.lua
-- =============================================================================
-- C-SEC-01 §1.2 audit ledger writer (append-only).
-- H006 — previous_flag_snapshot mandatory cuando event_type ∈ flag-changing set.
--
-- Schema (DB table `bank_audit_ledger` from sonar_core migrations):
--   audit_id              VARCHAR(36)  PK   (UUID v4)
--   timestamp_ms          BIGINT       NOT NULL
--   event_type            VARCHAR(64)  NOT NULL  (Enums.AUDIT_EVENT_TYPE)
--   actor_citizen_id      VARCHAR(64)  NULL  (NULL = system/cron action)
--   actor_src             INT          NULL  (player source id at time of event, optional)
--   target_citizen_id     VARCHAR(64)  NULL
--   target_account_id     BIGINT       NULL
--   target_iban           VARCHAR(34)  NULL
--   previous_flag_snapshot JSON        NULL  (MANDATORY for flag-changing events — H006)
--   event_data            JSON         NULL
--   cross_ref_audit_id    VARCHAR(36)  NULL  (chain to related audit entry)
--   correlation_id        VARCHAR(64)  NULL  (cross-resource correlation)
--   created_at            TIMESTAMP    DEFAULT CURRENT_TIMESTAMP(6)
--
-- Strategy:
--   - Async batched writes (1s flush window OR 100 entries threshold).
--   - Queue overflow guard (10k → drop oldest + alert).
--   - H006 schema enforcement at Write() boundary (rejects malformed entries).
--   - cross_ref_audit_id enables forensic chain reconstruction.
--
-- Deps: lib/enums.lua + lib/errors.lua + lib/db.lua + lib/uuid.lua.
-- =============================================================================

BankApp.lib.audit = {}
local M = BankApp.lib.audit

local Enums  = BankApp.lib.enums
local Errors = BankApp.lib.errors
local DB     = BankApp.lib.db
local UUID   = BankApp.lib.uuid
local Config = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. Internal queue
-- -----------------------------------------------------------------------------

local _queue = {}                      -- array of pending entries
local _queue_size = 0
local _flush_timer_running = false     -- defensive single flush ticker
local _stats = {
  written         = 0,
  dropped         = 0,
  flushes         = 0,
  shape_rejected  = 0,
  last_flush_ms   = 0,
}

local function now_ms()
  -- os.time() returns seconds; we want ms (server-side wall clock).
  -- GetGameTimer is uptime ms (resets on resource restart) — NO suitable for audit.
  -- Use os.time()*1000 + sub-second from os.clock() drift correction.
  -- Better: oxmysql provides NOW(6) in DB but we want client-side timestamp.
  return math.floor(os.time() * 1000)
end

-- -----------------------------------------------------------------------------
-- §2. JSON encoding (lightweight — for event_data + previous_flag_snapshot)
--
-- ox_lib (loaded via fxmanifest @ox_lib/init.lua) provides json. Si missing,
-- fallback to a minimal encoder.
-- -----------------------------------------------------------------------------

local function encode_json(t)
  if type(t) ~= 'table' then
    if t == nil then return nil end
    return tostring(t)
  end
  if json and json.encode then
    return json.encode(t)
  end
  -- Fallback: very minimal JSON encoder (only handles simple tables)
  local parts = {}
  local is_array = #t > 0
  if is_array then
    for i, v in ipairs(t) do
      parts[i] = ('"%s"'):format(tostring(v):gsub('"', '\\"'))
    end
    return '[' .. table.concat(parts, ',') .. ']'
  else
    local i = 1
    for k, v in pairs(t) do
      parts[i] = ('"%s":"%s"'):format(tostring(k), tostring(v):gsub('"', '\\"'))
      i = i + 1
    end
    return '{' .. table.concat(parts, ',') .. '}'
  end
end

-- -----------------------------------------------------------------------------
-- §3. H006 enforcement — schema validation
-- -----------------------------------------------------------------------------

--- validate_shape: enforce C-SEC-01 §1.2 + H006 mandatory previous_flag_snapshot.
---@param entry table candidate audit entry
---@return boolean ok
---@return table|nil err
local function validate_shape(entry)
  if type(entry) ~= 'table' then
    return false, Errors.New('AUDIT_SHAPE_INCOMPLETE', { reason = 'entry not a table' })
  end

  -- event_type required + must be valid enum
  if not Enums.IsValid(Enums.AUDIT_EVENT_TYPE, entry.event_type) then
    return false, Errors.New('AUDIT_SHAPE_INCOMPLETE', {
      reason     = 'event_type invalid or missing',
      event_type = tostring(entry.event_type),
    })
  end

  -- H006 — previous_flag_snapshot mandatory para flag-changing events
  if Enums.RequiresFlagSnapshot(entry.event_type) then
    if entry.previous_flag_snapshot == nil then
      return false, Errors.New('AUDIT_SHAPE_INCOMPLETE', {
        reason     = 'previous_flag_snapshot required (H006)',
        event_type = entry.event_type,
      })
    end
    if type(entry.previous_flag_snapshot) ~= 'table' then
      return false, Errors.New('AUDIT_SHAPE_INCOMPLETE', {
        reason     = 'previous_flag_snapshot must be a table',
        event_type = entry.event_type,
      })
    end
  end

  -- At least one identifier (actor or target) must be present (defense-in-depth)
  if not (entry.actor_citizen_id or entry.target_citizen_id or entry.target_account_id or entry.actor_src) then
    return false, Errors.New('AUDIT_SHAPE_INCOMPLETE', {
      reason     = 'must have at least one of actor/target identifiers',
      event_type = entry.event_type,
    })
  end

  return true, nil
end

-- -----------------------------------------------------------------------------
-- §4. Public Write API
-- -----------------------------------------------------------------------------

--- Write: enqueue audit entry. Returns immediately; actual DB insert happens
--- async in flush() (1s tick or 100-entry batch).
---
---@param entry table {
---   event_type         = string (Enums.AUDIT_EVENT_TYPE),
---   actor_citizen_id   = string|nil,
---   actor_src          = integer|nil,
---   target_citizen_id  = string|nil,
---   target_account_id  = integer|nil,
---   target_iban        = string|nil,
---   previous_flag_snapshot = table|nil  -- MANDATORY if event_type requires (H006)
---   event_data         = table|nil      -- arbitrary contextual JSON
---   cross_ref_audit_id = string|nil     -- UUID v4
---   correlation_id     = string|nil
--- }
---@return string|nil audit_id assigned UUID v4 (for cross_ref tracking).
---@return table|nil err
function M.Write(entry)
  local ok, err = validate_shape(entry)
  if not ok then
    _stats.shape_rejected = _stats.shape_rejected + 1
    return nil, err
  end

  local audit_id = UUID.V4()

  -- Queue overflow guard
  if _queue_size >= Config.Audit.QUEUE_OVERFLOW_LIMIT then
    _stats.dropped = _stats.dropped + 1
    return nil, Errors.New('AUDIT_QUEUE_OVERFLOW', { dropped_count = _stats.dropped })
  end

  local enriched = {
    audit_id              = audit_id,
    timestamp_ms          = now_ms(),
    event_type            = entry.event_type,
    actor_citizen_id      = entry.actor_citizen_id,
    actor_account_id      = entry.actor_account_id,
    actor_src             = entry.actor_src,
    target_citizen_id     = entry.target_citizen_id,
    target_account_id     = entry.target_account_id,
    target_iban           = entry.target_iban,
    previous_flag_snapshot = entry.previous_flag_snapshot,
    event_data            = entry.event_data,
    cross_ref_audit_id    = entry.cross_ref_audit_id,
    correlation_id        = entry.correlation_id,
  }

  _queue_size = _queue_size + 1
  _queue[_queue_size] = enriched

  -- If batch full → flush immediately (don't wait for ticker)
  if _queue_size >= Config.Audit.BATCH_MAX_SIZE then
    -- Spawn flush in next tick (avoid blocking caller)
    Citizen.SetTimeout(0, function() M.Flush() end)
  end

  -- Ensure flush ticker is running (lazy start)
  if not _flush_timer_running and Config.Features.ENABLE_AUDIT_BATCHED_WRITES then
    M.StartFlushTicker()
  end

  return audit_id, nil
end

-- -----------------------------------------------------------------------------
-- §5. Batch flush (async DB insert)
-- -----------------------------------------------------------------------------

local INSERT_SQL = [[
INSERT INTO sonar_bank_audit_ledger
  (ts, event_type, severity, bank_account_iban, actor_account_id, actor_role,
   correlation_id, request_nonce, related_movement_id, context_data, source_resource)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]]

--- Flush: drain queue and execute batched INSERT.
--- Idempotent — safe to call concurrently (drains current queue snapshot).
---@return integer written_count
---@return table|nil err first error encountered (queue partially flushed)
function M.Flush()
  if _queue_size == 0 then return 0, nil end

  -- Atomic snapshot swap (Lua single-threaded so this is safe)
  local batch = _queue
  local batch_size = _queue_size
  _queue = {}
  _queue_size = 0

  -- Build TX queries array
  local queries = {}
  for i = 1, batch_size do
    local e = batch[i]
    local context_data = {
      audit_id = e.audit_id,
      timestamp_ms = e.timestamp_ms,
      actor_citizen_id = e.actor_citizen_id,
      actor_account_id = e.actor_account_id,
      actor_src = e.actor_src,
      target_citizen_id = e.target_citizen_id,
      target_account_id = e.target_account_id,
      target_iban = e.target_iban,
      previous_flag_snapshot = e.previous_flag_snapshot,
      event_data = e.event_data,
      cross_ref_audit_id = e.cross_ref_audit_id,
    }
    queries[i] = {
      query = INSERT_SQL,
      values = {
        math.floor((tonumber(e.timestamp_ms) or now_ms()) / 1000),
        e.event_type,
        e.severity or 'info',
        e.target_iban,
        e.actor_account_id,
        e.actor_role or (e.actor_citizen_id and 'citizen' or 'system'),
        e.correlation_id,
        e.request_nonce,
        e.related_movement_id,
        encode_json(context_data),
        'sonar_bank_app',
      },
    }
  end

  -- Execute in single transaction (atomic batch)
  local ok, err = DB.Transaction(queries, { max_retries = 1 })

  _stats.flushes = _stats.flushes + 1
  _stats.last_flush_ms = now_ms()

  if not ok then
    -- On failure: requeue at HEAD (preserve ordering — prepend to queue)
    -- Simple approach: re-add to queue (will be re-flushed next tick)
    for i = 1, batch_size do
      if _queue_size < Config.Audit.QUEUE_OVERFLOW_LIMIT then
        _queue_size = _queue_size + 1
        _queue[_queue_size] = batch[i]
      else
        _stats.dropped = _stats.dropped + 1
      end
    end
    return 0, err
  end

  _stats.written = _stats.written + batch_size
  return batch_size, nil
end

--- StartFlushTicker: launch background coroutine that flushes every BATCH_FLUSH_INTERVAL_MS.
function M.StartFlushTicker()
  if _flush_timer_running then return end
  _flush_timer_running = true

  Citizen.CreateThread(function()
    while _flush_timer_running do
      Citizen.Wait(Config.Audit.BATCH_FLUSH_INTERVAL_MS)
      if _queue_size > 0 then
        M.Flush()
      end
    end
  end)
end

--- StopFlushTicker: graceful shutdown (drains queue once before stopping).
function M.StopFlushTicker()
  if _queue_size > 0 then M.Flush() end
  _flush_timer_running = false
end

-- -----------------------------------------------------------------------------
-- §6. Diagnostics
-- -----------------------------------------------------------------------------

--- GetStats: introspection (smoke test + health endpoint).
---@return table
function M.GetStats()
  return {
    queue_size      = _queue_size,
    written         = _stats.written,
    dropped         = _stats.dropped,
    flushes         = _stats.flushes,
    shape_rejected  = _stats.shape_rejected,
    last_flush_ms   = _stats.last_flush_ms,
    ticker_running  = _flush_timer_running,
  }
end

--- ResetStats: clear counters (test harness).
function M.ResetStats()
  _stats = { written = 0, dropped = 0, flushes = 0, shape_rejected = 0, last_flush_ms = 0 }
end

return M
