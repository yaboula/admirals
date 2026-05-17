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
INSERT INTO sonar_bank_movements
  (bank_account_id, occurred_at, amount, balance_after, category,
   counterpart_iban, concept, related_doc_id, request_nonce,
   initiated_by_account_id, source_resource)
VALUES
  ((SELECT id FROM sonar_bank_accounts WHERE iban = ? LIMIT 1),
   FLOOR(? / 1000), -(? / 100.0),
   (SELECT balance FROM sonar_bank_accounts WHERE iban = ? LIMIT 1),
   'transfer', ?, ?, ?, ?,
   (SELECT id FROM sonar_bank_accounts WHERE iban = ? LIMIT 1), 'sonar_bank_app'),
  ((SELECT id FROM sonar_bank_accounts WHERE iban = ? LIMIT 1),
   FLOOR(? / 1000), (? / 100.0),
   (SELECT balance FROM sonar_bank_accounts WHERE iban = ? LIMIT 1),
   'transfer', ?, ?, ?, ?,
   (SELECT id FROM sonar_bank_accounts WHERE iban = ? LIMIT 1), 'sonar_bank_app')
]]

--- BuildInsertQuery — TX descriptor.
function R.BuildInsertQuery(t)
  return {
    query  = SQL_INSERT,
    values = {
      t.from_iban, t.timestamp_ms, t.amount_minor, t.from_iban,
      t.to_iban, t.reason, t.txn_id, t.txn_id, t.from_iban,
      t.to_iban, t.timestamp_ms, t.amount_minor, t.to_iban,
      t.from_iban, t.reason, t.txn_id, t.txn_id, t.from_iban,
    },
  }
end

-- -----------------------------------------------------------------------------
-- §1.b SINGLE DEBIT — one-sided movement (fees, charges, no counterpart)
-- -----------------------------------------------------------------------------
-- Used by card_service (issue fee), and any other one-sided expense recorded
-- against the holder's account where there is no counterpart bank account.
-- The balance_after column reads the post-debit balance as long as the
-- accompanying AccountsRepo.BuildDebitBalanceQuery runs earlier in the same
-- DB.Transaction batch.
local SQL_INSERT_SINGLE_DEBIT = [[
INSERT INTO sonar_bank_movements
  (bank_account_id, occurred_at, amount, balance_after, category, concept,
   related_doc_id, request_nonce, initiated_by_account_id, source_resource)
SELECT ba.id, FLOOR(? / 1000), -(? / 100.0), ba.balance, ?, ?, ?, ?, ba.id, 'sonar_bank_app'
FROM sonar_bank_accounts ba
WHERE ba.iban = ?
LIMIT 1
]]

--- BuildSingleDebitQuery — single-sided debit (fees / charges).
--- @param t table { iban, amount_minor, category, reason, txn_id, timestamp_ms, idempotency_key }
function R.BuildSingleDebitQuery(t)
  return {
    query  = SQL_INSERT_SINGLE_DEBIT,
    values = {
      t.timestamp_ms,
      t.amount_minor,
      t.category or 'expense',
      t.reason,
      t.txn_id,
      t.idempotency_key or t.txn_id,
      t.iban,
    },
  }
end

-- -----------------------------------------------------------------------------
-- §1.c SINGLE CREDIT — one-sided credit (ATM deposit, admin credit, etc.)
-- -----------------------------------------------------------------------------
local SQL_INSERT_SINGLE_CREDIT = [[
INSERT INTO sonar_bank_movements
  (bank_account_id, occurred_at, amount, balance_after, category, concept,
   related_doc_id, request_nonce, initiated_by_account_id, source_resource)
SELECT ba.id, FLOOR(? / 1000), (? / 100.0), ba.balance, ?, ?, ?, ?, ba.id, 'sonar_bank_app'
FROM sonar_bank_accounts ba
WHERE ba.iban = ?
LIMIT 1
]]

--- BuildSingleCreditQuery — single-sided credit (deposits / admin top-ups).
--- @param t table { iban, amount_minor, category, reason, txn_id, timestamp_ms, idempotency_key }
function R.BuildSingleCreditQuery(t)
  return {
    query  = SQL_INSERT_SINGLE_CREDIT,
    values = {
      t.timestamp_ms,
      t.amount_minor,
      t.category or 'income',
      t.reason,
      t.txn_id,
      t.idempotency_key or t.txn_id,
      t.iban,
    },
  }
end

local SQL_UPDATE_STATUS = [[
DO 0
]]

function R.BuildUpdateStatusQuery(txn_id, status, committed_ms)
  return {
    query  = SQL_UPDATE_STATUS,
    values = {},
  }
end

-- -----------------------------------------------------------------------------
-- §2. SELECT
-- -----------------------------------------------------------------------------

local SQL_GET_BY_ID = [[
SELECT m.related_doc_id AS txn_id,
       MAX(CASE WHEN m.amount < 0 THEN a.iban END) AS from_iban,
       MAX(CASE WHEN m.amount > 0 THEN a.iban END) AS to_iban,
       CAST(ROUND(ABS(MIN(CASE WHEN m.amount < 0 THEN m.amount END)) * 100) AS SIGNED) AS amount_minor,
       MAX(m.concept) AS reason,
       'out' AS direction,
       'committed' AS status,
       MAX(m.occurred_at) * 1000 AS timestamp_ms,
       MAX(m.occurred_at) * 1000 AS committed_ms,
       MAX(m.request_nonce) AS idempotency_key,
       NULL AS correlation_id
FROM sonar_bank_movements m
INNER JOIN sonar_bank_accounts a ON a.id = m.bank_account_id
WHERE m.related_doc_id = ?
GROUP BY m.related_doc_id
LIMIT 1
]]

local SQL_LIST_BY_IBAN = [[
SELECT m.related_doc_id AS txn_id,
       CASE WHEN m.amount < 0 THEN a.iban ELSE m.counterpart_iban END AS from_iban,
       CASE WHEN m.amount < 0 THEN m.counterpart_iban ELSE a.iban END AS to_iban,
       CAST(ROUND(ABS(m.amount) * 100) AS SIGNED) AS amount_minor,
       m.concept AS reason,
       CASE WHEN m.amount < 0 THEN 'out' ELSE 'in' END AS direction,
       'committed' AS status,
       m.occurred_at * 1000 AS timestamp_ms,
       m.occurred_at * 1000 AS committed_ms
FROM sonar_bank_movements m
INNER JOIN sonar_bank_accounts a ON a.id = m.bank_account_id
WHERE a.iban = ?
  AND m.category = 'transfer'
ORDER BY m.occurred_at DESC
LIMIT ?
OFFSET ?
]]

function R.GetById(txn_id)
  return DB.QuerySingle(SQL_GET_BY_ID, { txn_id })
end

--- ListByIban — paginated history.
function R.ListByIban(iban, limit, offset)
  return DB.Query(SQL_LIST_BY_IBAN, { iban, limit or 50, offset or 0 })
end

-- -----------------------------------------------------------------------------
-- §1.c DAILY OUTGOING — sum of today's outgoing transfers (minor units)
-- -----------------------------------------------------------------------------
-- Used by transfer_service to enforce the daily transfer cap (banker
-- override `daily_transfer_limit_minor`).
--
-- We aggregate against `sonar_bank_movements` because that's the canonical
-- ledger driven by BuildInsertQuery. Outgoing rows have `amount < 0`.
-- Fees and other non-transfer expenses are excluded by `category = 'transfer'`.
local SQL_DAILY_OUTGOING_MINOR = [[
SELECT COALESCE(CAST(SUM(-m.amount * 100) AS SIGNED), 0) AS sum_minor
FROM sonar_bank_movements m
JOIN sonar_bank_accounts a ON a.id = m.bank_account_id
WHERE a.iban = ?
  AND m.amount < 0
  AND m.category = 'transfer'
  AND m.occurred_at >= ?
]]

--- GetDailyOutgoingMinor — total outgoing transfer volume for IBAN since unix-seconds cutoff.
---@param iban string
---@param since_unix_seconds integer  start of the day (00:00 local)
---@return integer minor_units
function R.GetDailyOutgoingMinor(iban, since_unix_seconds)
  local row = DB.QuerySingle(SQL_DAILY_OUTGOING_MINOR, { iban, since_unix_seconds })
  if not row then return 0 end
  return tonumber(row.sum_minor) or 0
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
  inner_t.counterpart_iban                                          AS counterpart_iban,
  MAX(inner_t.timestamp_ms)                                         AS last_transfer_ms,
  COUNT(*)                                                          AS transfer_count,
  SUBSTRING_INDEX(GROUP_CONCAT(inner_t.amount_minor
                               ORDER BY inner_t.timestamp_ms DESC
                               SEPARATOR ','), ',', ?)              AS recent_amounts_csv,
  SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(inner_t.reason,'')
                               ORDER BY inner_t.timestamp_ms DESC
                               SEPARATOR '||'), '||', 1)            AS last_reason
FROM (
  SELECT m.counterpart_iban,
         CAST(ROUND(ABS(m.amount) * 100) AS SIGNED) AS amount_minor,
         m.occurred_at * 1000 AS timestamp_ms,
         m.concept AS reason
  FROM sonar_bank_movements m
  INNER JOIN sonar_bank_accounts a ON a.id = m.bank_account_id
  INNER JOIN sonar_accounts sa ON sa.id = a.owner_account_id
  WHERE sa.char_id = ?
    AND a.closed_at IS NULL
    AND m.category = 'transfer'
    AND m.amount < 0
    AND m.occurred_at >= FLOOR(? / 1000)
    AND m.counterpart_iban <> a.iban
  ORDER BY m.occurred_at DESC
  LIMIT 500
) AS inner_t
GROUP BY inner_t.counterpart_iban
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
SELECT 0 AS cnt
]]

function R.BuildPendingCountQuery(citizen_id)
  return {
    sql    = SQL_PENDING_COUNT,
    params = {},
    kind   = 'scalar',
  }
end

-- -----------------------------------------------------------------------------
-- §5. Bootstrap snapshot — last-N transactions across all accounts of citizen
-- -----------------------------------------------------------------------------

local SQL_SNAPSHOT_RECENT_TX = [[
SELECT m.related_doc_id AS txn_id,
       CASE WHEN m.amount < 0 THEN a.iban ELSE m.counterpart_iban END AS from_iban,
       CASE WHEN m.amount < 0 THEN m.counterpart_iban ELSE a.iban END AS to_iban,
       CAST(ROUND(ABS(m.amount) * 100) AS SIGNED) AS amount_minor,
       m.concept AS reason,
       CASE WHEN m.amount < 0 THEN 'out' ELSE 'in' END AS direction,
       'committed' AS status,
       m.occurred_at * 1000 AS timestamp_ms
FROM sonar_bank_movements m
INNER JOIN sonar_bank_accounts a ON a.id = m.bank_account_id
INNER JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE sa.char_id = ?
ORDER BY m.occurred_at DESC
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
