-- =============================================================================
-- SONAR Bank App — repos/audit_query.lua
-- =============================================================================
-- Read-side queries against bank_audit_ledger.
-- Writes go through lib/audit.lua (append-only batched). NEVER write here.
--
-- Indexes (sonar_core migration 020):
--   IDX (actor_citizen_id, timestamp_ms DESC)
--   IDX (target_citizen_id, timestamp_ms DESC)
--   IDX (event_type, timestamp_ms DESC)
-- =============================================================================

BankApp.repos.audit_query = {}
local R = BankApp.repos.audit_query

local DB = BankApp.lib.db

local SQL_LIST_BY_CITIZEN = [[
SELECT audit_id, timestamp_ms, event_type, actor_citizen_id, target_citizen_id,
       target_account_id, target_iban, previous_flag_snapshot, event_data,
       cross_ref_audit_id, correlation_id
FROM bank_audit_ledger
WHERE (actor_citizen_id = ? OR target_citizen_id = ?)
ORDER BY timestamp_ms DESC
LIMIT ? OFFSET ?
]]

local SQL_LIST_BY_TARGET = [[
SELECT audit_id, timestamp_ms, event_type, actor_citizen_id, target_citizen_id,
       target_account_id, target_iban, previous_flag_snapshot, event_data,
       cross_ref_audit_id, correlation_id
FROM bank_audit_ledger
WHERE target_citizen_id = ?
ORDER BY timestamp_ms DESC
LIMIT ? OFFSET ?
]]

local SQL_LIST_BY_EVENT_TYPE = [[
SELECT audit_id, timestamp_ms, event_type, actor_citizen_id, target_citizen_id,
       target_iban, event_data
FROM bank_audit_ledger
WHERE event_type = ?
  AND timestamp_ms >= ?
ORDER BY timestamp_ms DESC
LIMIT ? OFFSET ?
]]

local SQL_GET_BY_ID = [[
SELECT audit_id, timestamp_ms, event_type, actor_citizen_id, actor_src,
       target_citizen_id, target_account_id, target_iban,
       previous_flag_snapshot, event_data, cross_ref_audit_id, correlation_id
FROM bank_audit_ledger
WHERE audit_id = ?
LIMIT 1
]]

local SQL_COUNT_BY_TARGET = [[
SELECT COUNT(*) AS cnt
FROM bank_audit_ledger
WHERE target_citizen_id = ? AND timestamp_ms >= ?
]]

local SQL_OUTSTANDING_FOR_CITIZEN = [[
SELECT audit_id, event_type, timestamp_ms, event_data
FROM bank_audit_ledger
WHERE target_citizen_id = ?
  AND event_type IN ('govt_audit_request', 'fraud_review_open', 'flag_set')
  AND timestamp_ms >= ?
ORDER BY timestamp_ms DESC
LIMIT ?
]]

--- ListByCitizen — actor OR target. Used by C035 audit query (scope=self/other).
function R.ListByCitizen(citizen_id, limit, offset)
  return DB.Query(SQL_LIST_BY_CITIZEN, {
    citizen_id, citizen_id, limit or 50, offset or 0,
  })
end

--- ListByTarget — admin scope (audit BY admin OF target).
function R.ListByTarget(target_citizen_id, limit, offset)
  return DB.Query(SQL_LIST_BY_TARGET, {
    target_citizen_id, limit or 50, offset or 0,
  })
end

--- ListByEventType — admin filter (e.g. all 'flag_set' last 7d).
function R.ListByEventType(event_type, since_ms, limit, offset)
  return DB.Query(SQL_LIST_BY_EVENT_TYPE, {
    event_type, since_ms, limit or 50, offset or 0,
  })
end

--- GetById — single entry lookup (for cross_ref chain reconstruction).
function R.GetById(audit_id)
  return DB.QuerySingle(SQL_GET_BY_ID, { audit_id })
end

--- CountByTarget — quick metric.
function R.CountByTarget(target_citizen_id, since_ms)
  return DB.QueryScalar(SQL_COUNT_BY_TARGET, { target_citizen_id, since_ms })
end

-- -----------------------------------------------------------------------------
-- REQ-FE-001 bootstrap — outstanding compliance / fraud review notices
-- -----------------------------------------------------------------------------

local DEFAULT_OUTSTANDING_WINDOW_DAYS = 30

--- BuildOutstandingNoticesQuery — bootstrap parallel descriptor.
function R.BuildOutstandingNoticesQuery(citizen_id, limit)
  local since_ms = math.floor((os.time() - (DEFAULT_OUTSTANDING_WINDOW_DAYS * 86400)) * 1000)
  return {
    sql    = SQL_OUTSTANDING_FOR_CITIZEN,
    params = { citizen_id, since_ms, limit or 16 },
    kind   = 'query',
  }
end

return R
