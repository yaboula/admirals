-- =============================================================================
-- SONAR Bank App — repos/recurring.lua
-- =============================================================================
-- Recurring debits (subscriptions / scheduled payments) DAO.
--
-- Schema (sonar_core migration 015 bank_recurring):
--   recurring_id     BIGINT PK AUTO_INCREMENT
--   owner_citizen_id VARCHAR(64) NOT NULL
--   from_iban        VARCHAR(34) NOT NULL
--   to_iban          VARCHAR(34) NOT NULL
--   amount_minor     BIGINT NOT NULL
--   reason           VARCHAR(255) NULL
--   interval_days    INT NOT NULL
--   status           ENUM('active','paused','cancelled')
--   next_charge_ms   BIGINT NOT NULL
--   last_charge_ms   BIGINT NULL
--   created_at, updated_at TIMESTAMP(6)
-- =============================================================================

BankApp.repos.recurring = {}
local R = BankApp.repos.recurring

local DB = BankApp.lib.db

local SQL_LIST_BY_CITIZEN = [[
SELECT recurring_id, owner_citizen_id, from_iban, to_iban, amount_minor, reason,
       interval_days, status, next_charge_ms, last_charge_ms,
       UNIX_TIMESTAMP(created_at)*1000 AS created_ms
FROM bank_recurring
WHERE owner_citizen_id = ? AND status IN ('active','paused')
ORDER BY next_charge_ms ASC
LIMIT ?
]]

local SQL_GET = [[
SELECT recurring_id, owner_citizen_id, from_iban, to_iban, amount_minor, reason,
       interval_days, status, next_charge_ms, last_charge_ms
FROM bank_recurring
WHERE recurring_id = ?
LIMIT 1
]]

local SQL_INSERT = [[
INSERT INTO bank_recurring
  (owner_citizen_id, from_iban, to_iban, amount_minor, reason,
   interval_days, status, next_charge_ms)
VALUES (?, ?, ?, ?, ?, ?, 'active', ?)
]]

local SQL_SET_STATUS = [[
UPDATE bank_recurring
SET status = ?, updated_at = CURRENT_TIMESTAMP(6)
WHERE recurring_id = ? AND owner_citizen_id = ?
]]

local SQL_BUMP_NEXT_CHARGE = [[
UPDATE bank_recurring
SET last_charge_ms = ?,
    next_charge_ms = ?,
    updated_at = CURRENT_TIMESTAMP(6)
WHERE recurring_id = ?
]]

local SQL_GET_DUE = [[
SELECT recurring_id, owner_citizen_id, from_iban, to_iban, amount_minor, reason,
       interval_days, next_charge_ms
FROM bank_recurring
WHERE status = 'active' AND next_charge_ms <= ?
ORDER BY next_charge_ms ASC
LIMIT ?
]]

function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST_BY_CITIZEN, { citizen_id, limit or 32 })
end

function R.GetById(recurring_id)
  return DB.QuerySingle(SQL_GET, { recurring_id })
end

function R.Insert(t)
  return DB.Insert(SQL_INSERT, {
    t.owner_citizen_id, t.from_iban, t.to_iban, t.amount_minor, t.reason,
    t.interval_days, t.next_charge_ms,
  })
end

function R.SetStatus(recurring_id, owner_citizen_id, status)
  return DB.Execute(SQL_SET_STATUS, { status, recurring_id, owner_citizen_id })
end

function R.BumpNextCharge(recurring_id, last_charge_ms, next_charge_ms)
  return DB.Execute(SQL_BUMP_NEXT_CHARGE, {
    last_charge_ms, next_charge_ms, recurring_id,
  })
end

--- BuildBumpNextChargeQuery — TX descriptor (used inside transfer commit batch).
function R.BuildBumpNextChargeQuery(recurring_id, last_charge_ms, next_charge_ms)
  return {
    query  = SQL_BUMP_NEXT_CHARGE,
    values = { last_charge_ms, next_charge_ms, recurring_id },
  }
end

--- GetDueForCharge — cron pickup. Limit prevents runaway batches.
function R.GetDueForCharge(now_ms, limit)
  return DB.Query(SQL_GET_DUE, { now_ms, limit or 100 })
end

--- BuildSnapshotQuery — REQ-FE-001 bootstrap parallel.
function R.BuildSnapshotQuery(citizen_id, limit)
  return {
    sql    = SQL_LIST_BY_CITIZEN,
    params = { citizen_id, limit or 32 },
    kind   = 'query',
  }
end

return R
