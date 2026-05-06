-- =============================================================================
-- SONAR Bank App — repos/loans.lua
-- =============================================================================
-- Loans DAO.
--
-- Schema (sonar_core migration 016 bank_loans):
--   loan_id            BIGINT PK AUTO_INCREMENT
--   borrower_citizen_id VARCHAR(64) NOT NULL
--   principal_minor    BIGINT NOT NULL
--   interest_bps       INT NOT NULL  (basis points: 100 = 1%)
--   term_days          INT NOT NULL
--   status             ENUM('requested','approved','active','rejected','paid_off','defaulted')
--   issued_ms          BIGINT NULL
--   due_ms             BIGINT NULL
--   outstanding_minor  BIGINT NOT NULL
--   created_at, updated_at TIMESTAMP(6)
--
-- bank_loan_payments:
--   payment_id  BIGINT PK
--   loan_id     BIGINT FK
--   amount_minor BIGINT
--   timestamp_ms BIGINT
-- =============================================================================

BankApp.repos.loans = {}
local R = BankApp.repos.loans

local DB = BankApp.lib.db

local SQL_LIST_BY_CITIZEN = [[
SELECT loan_id, borrower_citizen_id, principal_minor, interest_bps, term_days,
       status, issued_ms, due_ms, outstanding_minor,
       UNIX_TIMESTAMP(created_at)*1000 AS created_ms
FROM bank_loans
WHERE borrower_citizen_id = ?
  AND status IN ('requested','approved','active')
ORDER BY created_at DESC
LIMIT ?
]]

local SQL_GET = [[
SELECT loan_id, borrower_citizen_id, principal_minor, interest_bps, term_days,
       status, issued_ms, due_ms, outstanding_minor
FROM bank_loans
WHERE loan_id = ?
LIMIT 1
]]

local SQL_INSERT = [[
INSERT INTO bank_loans
  (borrower_citizen_id, principal_minor, interest_bps, term_days,
   status, outstanding_minor)
VALUES (?, ?, ?, ?, 'requested', ?)
]]

local SQL_SET_STATUS = [[
UPDATE bank_loans
SET status = ?,
    issued_ms = CASE WHEN ? = 'active' THEN ? ELSE issued_ms END,
    due_ms = CASE WHEN ? = 'active' THEN ? ELSE due_ms END,
    updated_at = CURRENT_TIMESTAMP(6)
WHERE loan_id = ?
]]

local SQL_REDUCE_OUTSTANDING = [[
UPDATE bank_loans
SET outstanding_minor = GREATEST(outstanding_minor - ?, 0),
    status = CASE WHEN outstanding_minor - ? <= 0 THEN 'paid_off' ELSE status END,
    updated_at = CURRENT_TIMESTAMP(6)
WHERE loan_id = ? AND status = 'active'
]]

local SQL_INSERT_PAYMENT = [[
INSERT INTO bank_loan_payments (loan_id, amount_minor, timestamp_ms)
VALUES (?, ?, ?)
]]

local SQL_LIST_PAYMENTS = [[
SELECT payment_id, loan_id, amount_minor, timestamp_ms
FROM bank_loan_payments
WHERE loan_id = ?
ORDER BY timestamp_ms DESC
LIMIT ?
]]

function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST_BY_CITIZEN, { citizen_id, limit or 16 })
end

function R.GetById(loan_id)
  return DB.QuerySingle(SQL_GET, { loan_id })
end

function R.Insert(t)
  return DB.Insert(SQL_INSERT, {
    t.borrower_citizen_id, t.principal_minor, t.interest_bps,
    t.term_days, t.principal_minor,  -- outstanding starts at principal
  })
end

function R.SetStatus(loan_id, status, issued_ms, due_ms)
  return DB.Execute(SQL_SET_STATUS, {
    status, status, issued_ms, status, due_ms, loan_id,
  })
end

function R.BuildReduceOutstandingQuery(loan_id, amount_minor)
  return {
    query  = SQL_REDUCE_OUTSTANDING,
    values = { amount_minor, amount_minor, loan_id },
  }
end

function R.BuildInsertPaymentQuery(loan_id, amount_minor, timestamp_ms)
  return {
    query  = SQL_INSERT_PAYMENT,
    values = { loan_id, amount_minor, timestamp_ms },
  }
end

function R.ListPayments(loan_id, limit)
  return DB.Query(SQL_LIST_PAYMENTS, { loan_id, limit or 50 })
end

--- BuildSnapshotQuery — REQ-FE-001 bootstrap parallel.
function R.BuildSnapshotQuery(citizen_id, limit)
  return {
    sql    = SQL_LIST_BY_CITIZEN,
    params = { citizen_id, limit or 16 },
    kind   = 'query',
  }
end

return R
