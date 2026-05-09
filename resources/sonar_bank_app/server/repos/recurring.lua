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
local UUID = BankApp.lib.uuid

local SQL_LIST_BY_CITIZEN = [[
SELECT r.id AS recurring_id, sa.char_id AS owner_citizen_id, ba.iban AS from_iban,
       r.payee_iban AS to_iban, CAST(ROUND(r.amount * 100) AS SIGNED) AS amount_minor,
       r.description AS reason,
       CASE r.interval_kind
         WHEN 'daily' THEN r.interval_count
         WHEN 'weekly' THEN r.interval_count * 7
         WHEN 'monthly' THEN r.interval_count * 30
         WHEN 'yearly' THEN r.interval_count * 365
       END AS interval_days,
       r.state AS status, r.next_charge_at * 1000 AS next_charge_ms,
       r.last_charged_at * 1000 AS last_charge_ms,
       r.created_at * 1000 AS created_ms
FROM sonar_bank_recurring_payments r
INNER JOIN sonar_accounts sa ON sa.id = r.payer_account_id
INNER JOIN sonar_bank_accounts ba ON ba.id = r.payer_bank_account_id
WHERE sa.char_id = ? AND r.state IN ('active','paused')
ORDER BY r.next_charge_at ASC
LIMIT ?
]]

local SQL_GET = [[
SELECT r.id AS recurring_id, sa.char_id AS owner_citizen_id, ba.iban AS from_iban,
       r.payee_iban AS to_iban, CAST(ROUND(r.amount * 100) AS SIGNED) AS amount_minor,
       r.description AS reason,
       CASE r.interval_kind
         WHEN 'daily' THEN r.interval_count
         WHEN 'weekly' THEN r.interval_count * 7
         WHEN 'monthly' THEN r.interval_count * 30
         WHEN 'yearly' THEN r.interval_count * 365
       END AS interval_days,
       r.state AS status, r.next_charge_at * 1000 AS next_charge_ms,
       r.last_charged_at * 1000 AS last_charge_ms
FROM sonar_bank_recurring_payments r
INNER JOIN sonar_accounts sa ON sa.id = r.payer_account_id
INNER JOIN sonar_bank_accounts ba ON ba.id = r.payer_bank_account_id
WHERE r.id = ?
LIMIT 1
]]

local SQL_INSERT = [[
INSERT INTO sonar_bank_recurring_payments
  (id, payer_account_id, payer_bank_account_id, payee_kind, payee_iban,
   state, payment_kind, amount, interval_kind, interval_count, description, next_charge_at)
VALUES (
  ?,
  (SELECT id FROM sonar_accounts WHERE char_id = ? LIMIT 1),
  (SELECT id FROM sonar_bank_accounts WHERE iban = ? LIMIT 1),
  'citizen', ?, 'active', 'subscription', (? / 100.0), 'daily',
  GREATEST(1, ?), ?, FLOOR(? / 1000)
)
]]

local SQL_SET_STATUS = [[
UPDATE sonar_bank_recurring_payments r
INNER JOIN sonar_accounts sa ON sa.id = r.payer_account_id
SET r.state = ?, r.cancelled_at = CASE WHEN ? = 'cancelled' THEN UNIX_TIMESTAMP() ELSE r.cancelled_at END,
    r.updated_at = UNIX_TIMESTAMP()
WHERE r.id = ? AND sa.char_id = ?
]]

local SQL_BUMP_NEXT_CHARGE = [[
UPDATE sonar_bank_recurring_payments
SET last_charged_at = FLOOR(? / 1000),
    next_charge_at = FLOOR(? / 1000),
    updated_at = UNIX_TIMESTAMP()
WHERE id = ?
]]

local SQL_GET_DUE = [[
SELECT r.id AS recurring_id, sa.char_id AS owner_citizen_id, ba.iban AS from_iban,
       r.payee_iban AS to_iban, CAST(ROUND(r.amount * 100) AS SIGNED) AS amount_minor,
       r.description AS reason,
       CASE r.interval_kind
         WHEN 'daily' THEN r.interval_count
         WHEN 'weekly' THEN r.interval_count * 7
         WHEN 'monthly' THEN r.interval_count * 30
         WHEN 'yearly' THEN r.interval_count * 365
       END AS interval_days,
       r.next_charge_at * 1000 AS next_charge_ms
FROM sonar_bank_recurring_payments r
INNER JOIN sonar_accounts sa ON sa.id = r.payer_account_id
INNER JOIN sonar_bank_accounts ba ON ba.id = r.payer_bank_account_id
WHERE r.state = 'active' AND r.next_charge_at <= FLOOR(? / 1000)
ORDER BY r.next_charge_at ASC
LIMIT ?
]]

function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST_BY_CITIZEN, { citizen_id, limit or 32 })
end

function R.GetById(recurring_id)
  return DB.QuerySingle(SQL_GET, { recurring_id })
end

function R.Insert(t)
  local recurring_id = UUID.V4()
  local _, err = DB.Execute(SQL_INSERT, {
    recurring_id, t.owner_citizen_id, t.from_iban, t.to_iban, t.amount_minor,
    t.interval_days, t.reason, t.next_charge_ms,
  })
  if err then return nil, err end
  return recurring_id, nil
end

function R.SetStatus(recurring_id, owner_citizen_id, status)
  return DB.Execute(SQL_SET_STATUS, { status, status, recurring_id, owner_citizen_id })
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
