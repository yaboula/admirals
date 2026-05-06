-- =============================================================================
-- SONAR Bank App — repos/transactions.lua
-- =============================================================================
-- Transactions DAO + REQ-FE-002 source query for recent recipients aggregation.
--
-- Schema (sonar_core migration 011 bank_transactions):
--   txn_id           VARCHAR(36) PK   (UUID v4)
--   from_iban        VARCHAR(34) NOT NULL
--   to_iban          VARCHAR(34) NOT NULL
--   amount_minor     BIGINT NOT NULL
--   reason           VARCHAR(500) NULL
--   direction        ENUM('out','in','internal')
--   status           ENUM('pending','reconciling','committed','reverted','failed')
--   timestamp_ms     BIGINT NOT NULL
--   committed_ms     BIGINT NULL
--   idempotency_key  VARCHAR(128) NULL
--   correlation_id   VARCHAR(64) NULL
--
-- Index recommendation (DB Lead Phase B):
--   IDX (from_iban, status, timestamp_ms) DESC  -- REQ-FE-002 hot path
--   IDX (to_iban, status, timestamp_ms) DESC
-- =============================================================================

BankApp.repos.transactions = {}
local R = BankApp.repos.transactions

local DB = BankApp.lib.db

-- -----------------------------------------------------------------------------
-- §1. INSERT (single + TX descriptor)
-- -----------------------------------------------------------------------------

local SQL_INSERT = [[
INSERT INTO bank_transactions
  (txn_id, from_iban, to_iban, amount_minor, reason, direction, status,
   timestamp_ms, idempotency_key, correlation_id)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]]

--- BuildInsertQuery — TX descriptor.
function R.BuildInsertQuery(t)
  return {
    query  = SQL_INSERT,
    values = {
      t.txn_id, t.from_iban, t.to_iban, t.amount_minor, t.reason,
      t.direction or 'out', t.status or 'pending', t.timestamp_ms,
      t.idempotency_key, t.correlation_id,
    },
  }
end

local SQL_UPDATE_STATUS = [[
UPDATE bank_transactions
SET status = ?,
    committed_ms = CASE WHEN ? = 'committed' THEN ? ELSE committed_ms END
WHERE txn_id = ?
]]

function R.BuildUpdateStatusQuery(txn_id, status, committed_ms)
  return {
    query  = SQL_UPDATE_STATUS,
    values = { status, status, committed_ms or 0, txn_id },
  }
end

-- -----------------------------------------------------------------------------
-- §2. SELECT
-- -----------------------------------------------------------------------------

local SQL_GET_BY_ID = [[
SELECT txn_id, from_iban, to_iban, amount_minor, reason, direction,
       status, timestamp_ms, committed_ms, idempotency_key, correlation_id
FROM bank_transactions
WHERE txn_id = ?
LIMIT 1
]]

local SQL_LIST_BY_IBAN = [[
SELECT txn_id, from_iban, to_iban, amount_minor, reason, direction,
       status, timestamp_ms, committed_ms
FROM bank_transactions
WHERE (from_iban = ? OR to_iban = ?)
  AND status IN ('committed','reconciling')
ORDER BY timestamp_ms DESC
LIMIT ?
OFFSET ?
]]

function R.GetById(txn_id)
  return DB.QuerySingle(SQL_GET_BY_ID, { txn_id })
end

--- ListByIban — paginated history.
function R.ListByIban(iban, limit, offset)
  return DB.Query(SQL_LIST_BY_IBAN, { iban, iban, limit or 50, offset or 0 })
end

-- -----------------------------------------------------------------------------
-- §3. REQ-FE-002 — Recent recipients aggregation
--
--   Goal: for given player citizen_id, return the top-N counterpart IBANs
--   they sent money TO during the last `window_days`, with last_ts +
--   transfer_count + recent amount samples for the Express Mode preset.
--
--   Indexed plan:
--     1. SELECT iban FROM bank_accounts WHERE owner_citizen_id = ?  (small set)
--     2. SELECT to_iban, amount_minor, timestamp_ms FROM bank_transactions
--        WHERE from_iban IN (...) AND status='committed' AND direction='out'
--        AND timestamp_ms >= ? ORDER BY timestamp_ms DESC LIMIT 500
--        → uses IDX (from_iban, status, timestamp_ms)
--     3. Aggregate in MySQL: GROUP BY to_iban, MAX(timestamp_ms), COUNT, GROUP_CONCAT(amount)
--     4. ORDER BY last_ts DESC LIMIT N
--
--   Single round-trip via inner subquery + outer GROUP BY.
-- -----------------------------------------------------------------------------

local SQL_RECENT_RECIPIENTS = [[
SELECT
  inner_t.to_iban                                                   AS counterpart_iban,
  MAX(inner_t.timestamp_ms)                                         AS last_transfer_ms,
  COUNT(*)                                                          AS transfer_count,
  SUBSTRING_INDEX(GROUP_CONCAT(inner_t.amount_minor
                               ORDER BY inner_t.timestamp_ms DESC
                               SEPARATOR ','), ',', ?)              AS recent_amounts_csv,
  SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(inner_t.reason,'')
                               ORDER BY inner_t.timestamp_ms DESC
                               SEPARATOR '||'), '||', 1)            AS last_reason
FROM (
  SELECT t.to_iban, t.amount_minor, t.timestamp_ms, t.reason
  FROM bank_transactions t
  INNER JOIN bank_accounts a
    ON a.iban = t.from_iban
  WHERE a.owner_citizen_id = ?
    AND a.status = 'active'
    AND t.status = 'committed'
    AND t.direction = 'out'
    AND t.timestamp_ms >= ?
    AND t.to_iban <> t.from_iban
  ORDER BY t.timestamp_ms DESC
  LIMIT 500
) AS inner_t
GROUP BY inner_t.to_iban
ORDER BY last_transfer_ms DESC
LIMIT ?
]]

--- GetRecentRecipients — REQ-FE-002 indexed aggregation.
---@param citizen_id string
---@param window_days integer
---@param limit integer max recipients to return
---@param preset_amounts_count integer how many recent amounts to expose per recipient (CSV)
---@return table|nil rows, table|nil err
function R.GetRecentRecipients(citizen_id, window_days, limit, preset_amounts_count)
  local cutoff_ms = math.floor((os.time() - (window_days * 86400)) * 1000)
  return DB.Query(SQL_RECENT_RECIPIENTS, {
    preset_amounts_count or 3,
    citizen_id,
    cutoff_ms,
    limit or 8,
  })
end

--- BuildRecentRecipientsQuery — REQ-FE-001 bootstrap parallel descriptor.
function R.BuildRecentRecipientsQuery(citizen_id, window_days, limit, preset_amounts_count)
  local cutoff_ms = math.floor((os.time() - (window_days * 86400)) * 1000)
  return {
    sql    = SQL_RECENT_RECIPIENTS,
    params = { preset_amounts_count or 3, citizen_id, cutoff_ms, limit or 8 },
    kind   = 'query',
  }
end

-- -----------------------------------------------------------------------------
-- §4. Bootstrap snapshot — outstanding pending tx count (REQ-FE-001)
-- -----------------------------------------------------------------------------

local SQL_PENDING_COUNT = [[
SELECT COUNT(*) AS cnt
FROM bank_transactions t
INNER JOIN bank_accounts a
  ON a.iban IN (t.from_iban, t.to_iban)
WHERE a.owner_citizen_id = ?
  AND t.status IN ('pending','reconciling')
]]

function R.BuildPendingCountQuery(citizen_id)
  return {
    sql    = SQL_PENDING_COUNT,
    params = { citizen_id },
    kind   = 'scalar',
  }
end

-- -----------------------------------------------------------------------------
-- §5. Bootstrap snapshot — last-N transactions across all accounts of citizen
-- -----------------------------------------------------------------------------

local SQL_SNAPSHOT_RECENT_TX = [[
SELECT t.txn_id, t.from_iban, t.to_iban, t.amount_minor, t.reason,
       t.direction, t.status, t.timestamp_ms
FROM bank_transactions t
INNER JOIN bank_accounts a
  ON a.iban IN (t.from_iban, t.to_iban)
WHERE a.owner_citizen_id = ?
  AND t.status IN ('committed','pending','reconciling')
ORDER BY t.timestamp_ms DESC
LIMIT ?
]]

function R.BuildRecentTransactionsQuery(citizen_id, limit)
  return {
    sql    = SQL_SNAPSHOT_RECENT_TX,
    params = { citizen_id, limit or 20 },
    kind   = 'query',
  }
end

--- ListByCitizen — direct execution variant of BuildRecentTransactionsQuery.
--- Used by C005 sonar:bank:transfer:listRecent (when caller does not need the
--- bootstrap parallel descriptor pattern).
---@param citizen_id string
---@param limit integer
---@return table|nil rows, table|nil err
function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_SNAPSHOT_RECENT_TX, { citizen_id, limit or 50 })
end

return R
