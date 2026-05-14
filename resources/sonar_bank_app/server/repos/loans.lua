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
local UUID = BankApp.lib.uuid

local SQL_LIST_BY_CITIZEN = [[
SELECT l.id AS loan_id, sa.char_id AS borrower_citizen_id,
       CAST(ROUND(l.amount_principal * 100) AS SIGNED) AS principal_minor,
       CAST(ROUND(l.interest_rate_pct * 100) AS SIGNED) AS interest_bps,
       l.term_months * 30 AS term_days,
       CASE
         WHEN l.state = 'defaulted' AND l.reason_note = 'rejected' THEN 'rejected'
         ELSE l.state
       END AS status,
       COALESCE(l.disbursed_at, l.approved_at) * 1000 AS issued_ms,
       l.next_payment_due_at * 1000 AS due_ms,
       CAST(ROUND(l.amount_outstanding * 100) AS SIGNED) AS outstanding_minor,
       l.created_at * 1000 AS created_ms
FROM sonar_bank_loans l
INNER JOIN sonar_accounts sa ON sa.id = l.borrower_account_id
WHERE sa.char_id = ?
  AND l.state IN ('requested','approved','active')
ORDER BY l.created_at DESC
LIMIT ?
]]

local SQL_GET = [[
SELECT l.id AS loan_id, sa.char_id AS borrower_citizen_id,
       CAST(ROUND(l.amount_principal * 100) AS SIGNED) AS principal_minor,
       CAST(ROUND(l.interest_rate_pct * 100) AS SIGNED) AS interest_bps,
       l.term_months * 30 AS term_days,
       CASE
         WHEN l.state = 'defaulted' AND l.reason_note = 'rejected' THEN 'rejected'
         ELSE l.state
       END AS status,
       COALESCE(l.disbursed_at, l.approved_at) * 1000 AS issued_ms,
       l.next_payment_due_at * 1000 AS due_ms,
       CAST(ROUND(l.amount_outstanding * 100) AS SIGNED) AS outstanding_minor,
       l.created_at * 1000 AS created_ms
FROM sonar_bank_loans l
INNER JOIN sonar_accounts sa ON sa.id = l.borrower_account_id
WHERE l.id = ?
LIMIT 1
]]

local SQL_INSERT = [[
INSERT INTO sonar_bank_loans
  (id, borrower_account_id, bank_account_id, state, loan_kind,
   amount_principal, amount_outstanding, interest_rate_pct, term_months)
VALUES (
  ?,
  (SELECT id FROM sonar_accounts WHERE char_id = ? LIMIT 1),
  (SELECT ba.id
   FROM sonar_bank_accounts ba
   INNER JOIN sonar_accounts sa ON sa.id = ba.owner_account_id
   WHERE sa.char_id = ? AND ba.closed_at IS NULL
   ORDER BY ba.created_at ASC
   LIMIT 1),
  'requested', 'personal', (? / 100.0), (? / 100.0), (? / 100.0),
  GREATEST(1, CEIL(? / 30))
)
]]

local SQL_SET_STATUS = [[
UPDATE sonar_bank_loans
SET state = CASE
      WHEN ? = 'rejected' THEN 'defaulted'
      WHEN ? = 'disbursed' THEN 'active'
      ELSE ?
    END,
    reason_note = CASE WHEN ? = 'rejected' THEN 'rejected' ELSE reason_note END,
    disbursed_at = CASE WHEN ? = 'active' THEN FLOOR(? / 1000) ELSE disbursed_at END,
    next_payment_due_at = CASE WHEN ? = 'active' THEN FLOOR(? / 1000) ELSE next_payment_due_at END,
    updated_at = UNIX_TIMESTAMP()
WHERE id = ?
]]

local SQL_REDUCE_OUTSTANDING = [[
UPDATE sonar_bank_loans
SET state = CASE WHEN amount_outstanding <= (? / 100.0) THEN 'paid_off' ELSE state END,
    paid_off_at = CASE WHEN amount_outstanding <= (? / 100.0) THEN UNIX_TIMESTAMP() ELSE paid_off_at END,
    amount_outstanding = GREATEST(amount_outstanding - (? / 100.0), 0),
    updated_at = UNIX_TIMESTAMP()
WHERE id = ? AND state = 'active'
]]

local SQL_INSERT_PAYMENT = [[
INSERT INTO sonar_bank_movements
  (bank_account_id, occurred_at, amount, balance_after, category,
   concept, related_doc_id, source_resource)
SELECT ba.id, FLOOR(? / 1000), -(? / 100.0), ba.balance,
       'loan_repayment', 'loan repayment', l.id, 'sonar_bank_app'
FROM sonar_bank_loans l
INNER JOIN sonar_bank_accounts ba ON ba.iban = ?
WHERE l.id = ?
LIMIT 1
]]

local SQL_LIST_PAYMENTS = [[
SELECT m.id AS payment_id, m.related_doc_id AS loan_id,
       CAST(ROUND(ABS(m.amount) * 100) AS SIGNED) AS amount_minor,
       m.occurred_at * 1000 AS timestamp_ms
FROM sonar_bank_movements m
WHERE m.related_doc_id = ? AND m.category = 'loan_repayment'
ORDER BY m.occurred_at DESC
LIMIT ?
]]

local SQL_ACTIVATE = [[
UPDATE sonar_bank_loans
SET state = 'active',
    bank_account_id = (SELECT id FROM sonar_bank_accounts WHERE iban = ? LIMIT 1),
    disbursed_at = FLOOR(? / 1000),
    next_payment_due_at = FLOOR(? / 1000),
    updated_at = UNIX_TIMESTAMP()
WHERE id = ? AND state = 'requested'
]]

local SQL_INSERT_DISBURSEMENT = [[
INSERT INTO sonar_bank_movements
  (bank_account_id, occurred_at, amount, balance_after, category,
   concept, related_doc_id, source_resource)
SELECT ba.id, FLOOR(? / 1000), (? / 100.0), ba.balance,
       'loan_disbursement', 'loan disbursement', ?, 'sonar_bank_app'
FROM sonar_bank_accounts ba
WHERE ba.iban = ?
LIMIT 1
]]

function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST_BY_CITIZEN, { citizen_id, limit or 16 })
end

function R.GetById(loan_id)
  return DB.QuerySingle(SQL_GET, { loan_id })
end

function R.Insert(t)
  local loan_id = UUID.V4()
  local _, err = DB.Execute(SQL_INSERT, {
    loan_id, t.borrower_citizen_id, t.borrower_citizen_id,
    t.principal_minor, t.principal_minor, t.interest_bps, t.term_days,
  })
  if err then return nil, err end
  return loan_id, nil
end

function R.SetStatus(loan_id, status, issued_ms, due_ms)
  return DB.Execute(SQL_SET_STATUS, {
    status, status, status, status, status, issued_ms, status, due_ms, loan_id,
  })
end

function R.BuildReduceOutstandingQuery(loan_id, amount_minor)
  return {
    query  = SQL_REDUCE_OUTSTANDING,
    values = { amount_minor, amount_minor, amount_minor, loan_id },
  }
end

function R.BuildInsertPaymentQuery(loan_id, from_iban, amount_minor, timestamp_ms)
  return {
    query  = SQL_INSERT_PAYMENT,
    values = { timestamp_ms, amount_minor, from_iban, loan_id },
  }
end

function R.BuildActivateQuery(loan_id, deposit_iban, issued_ms, due_ms)
  return {
    query  = SQL_ACTIVATE,
    values = { deposit_iban, issued_ms, due_ms, loan_id },
  }
end

function R.BuildInsertDisbursementQuery(loan_id, deposit_iban, amount_minor, timestamp_ms)
  return {
    query  = SQL_INSERT_DISBURSEMENT,
    values = { timestamp_ms, amount_minor, loan_id, deposit_iban },
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
