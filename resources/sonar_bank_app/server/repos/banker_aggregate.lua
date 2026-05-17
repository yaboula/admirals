-- =============================================================================
-- SONAR Bank App — repos/banker_aggregate.lua
-- =============================================================================
-- Aggregate / read-only DAO used by the Bank Owner Panel (F2+).
--
--   Pure-SQL aggregations for KPI cards and queue listings. No business
--   logic — services/banker/* compose these to produce panel responses.
--
--   Performance note: every aggregate query has a hard LIMIT or is grouped on
--   indexed columns. Queries here are designed to run in < 50ms on a server
--   with ~10k accounts / ~1k loans.
-- =============================================================================

BankApp.repos.banker_aggregate = {}
local R = BankApp.repos.banker_aggregate

local DB = BankApp.lib.db

-- ---------------------------------------------------------------------------
-- §1. Dashboard KPIs
-- ---------------------------------------------------------------------------
local SQL_DASHBOARD_KPIS = [[
SELECT
  (SELECT COUNT(*) FROM sonar_bank_accounts WHERE closed_at IS NULL) AS total_accounts,
  (SELECT COUNT(DISTINCT sa.char_id)
     FROM sonar_bank_accounts a
     INNER JOIN sonar_accounts sa ON sa.id = a.owner_account_id
     WHERE a.closed_at IS NULL) AS total_customers,
  (SELECT CAST(ROUND(COALESCE(SUM(balance), 0) * 100) AS SIGNED)
     FROM sonar_bank_accounts WHERE closed_at IS NULL) AS total_balance_minor,
  (SELECT CAST(ROUND(COALESCE(SUM(savings), 0) * 100) AS SIGNED)
     FROM sonar_bank_accounts WHERE closed_at IS NULL) AS total_savings_minor,
  (SELECT COUNT(*) FROM sonar_bank_accounts WHERE is_frozen = 1 AND closed_at IS NULL) AS frozen_accounts,
  (SELECT COUNT(*) FROM sonar_bank_loans WHERE state = 'active') AS loans_active,
  (SELECT CAST(ROUND(COALESCE(SUM(amount_outstanding), 0) * 100) AS SIGNED)
     FROM sonar_bank_loans WHERE state IN ('active','disbursed','approved')) AS loans_outstanding_minor,
  (SELECT COUNT(*) FROM sonar_bank_loans WHERE state = 'requested') AS loans_pending,
  (SELECT COUNT(*) FROM sonar_bank_account_approvals
    WHERE state = 'pending') AS pro_accounts_pending,
  (SELECT COUNT(*) FROM sonar_bank_employees WHERE status = 'active') AS employees_active
]]

function R.GetDashboardKpis()
  local row, err = DB.QuerySingle(SQL_DASHBOARD_KPIS, {})
  if err then return nil, err end
  if not row then return nil, nil end
  -- Ensure every numeric is a Lua number (oxmysql can return strings on BIGINT)
  return {
    total_accounts          = tonumber(row.total_accounts) or 0,
    total_customers         = tonumber(row.total_customers) or 0,
    total_balance_minor     = tonumber(row.total_balance_minor) or 0,
    total_savings_minor     = tonumber(row.total_savings_minor) or 0,
    frozen_accounts         = tonumber(row.frozen_accounts) or 0,
    loans_active            = tonumber(row.loans_active) or 0,
    loans_outstanding_minor = tonumber(row.loans_outstanding_minor) or 0,
    loans_pending           = tonumber(row.loans_pending) or 0,
    pro_accounts_pending    = tonumber(row.pro_accounts_pending) or 0,
    employees_active        = tonumber(row.employees_active) or 0,
  }, nil
end

-- ---------------------------------------------------------------------------
-- §2. Account class breakdown (for pie chart F2)
-- ---------------------------------------------------------------------------
local SQL_ACCOUNTS_BY_CLASS = [[
SELECT account_class,
       COUNT(*) AS n,
       CAST(ROUND(COALESCE(SUM(balance), 0) * 100) AS SIGNED) AS sum_balance_minor
FROM sonar_bank_accounts
WHERE closed_at IS NULL
GROUP BY account_class
ORDER BY n DESC
]]

function R.AccountsByClass()
  return DB.Query(SQL_ACCOUNTS_BY_CLASS, {})
end

-- ---------------------------------------------------------------------------
-- §3. Recent transfers timeseries (last N days, grouped by day)
-- ---------------------------------------------------------------------------
local SQL_TRANSFERS_TIMESERIES = [[
SELECT
  FROM_UNIXTIME(occurred_at, '%Y-%m-%d') AS day,
  COUNT(*) AS n,
  CAST(ROUND(COALESCE(SUM(ABS(amount)), 0) * 100) AS SIGNED) AS volume_minor
FROM sonar_bank_movements
WHERE occurred_at >= UNIX_TIMESTAMP() - ?
  AND category = 'transfer'
GROUP BY day
ORDER BY day ASC
LIMIT 60
]]

function R.TransfersTimeseries(window_days)
  local seconds = math.max(1, math.min(60, tonumber(window_days) or 14)) * 86400
  return DB.Query(SQL_TRANSFERS_TIMESERIES, { seconds })
end

-- ---------------------------------------------------------------------------
-- §4. Loan portfolio breakdown (active loans by product)
-- ---------------------------------------------------------------------------
local SQL_LOAN_PORTFOLIO = [[
SELECT loan_kind AS product_id,
       COUNT(*) AS n,
       CAST(ROUND(COALESCE(SUM(amount_outstanding), 0) * 100) AS SIGNED) AS outstanding_minor
FROM sonar_bank_loans
WHERE state IN ('active','disbursed','approved')
GROUP BY loan_kind
ORDER BY outstanding_minor DESC
]]

function R.LoanPortfolio()
  return DB.Query(SQL_LOAN_PORTFOLIO, {})
end

-- ---------------------------------------------------------------------------
-- §5. Pending loans queue (for Operations module)
-- ---------------------------------------------------------------------------
local SQL_LOANS_PENDING = [[
SELECT l.id AS loan_id,
       sa.char_id AS borrower_citizen_id,
       l.loan_kind AS product_id,
       CAST(ROUND(l.amount_principal * 100) AS SIGNED) AS principal_minor,
       CAST(ROUND(l.interest_rate_pct * 100) AS SIGNED) AS interest_bps,
       (l.term_months * 30) AS term_days,
       loan_ba.iban AS deposit_iban,
       l.created_at * 1000 AS requested_ms
FROM sonar_bank_loans l
INNER JOIN sonar_accounts sa ON sa.id = l.borrower_account_id
LEFT JOIN sonar_bank_accounts loan_ba ON loan_ba.id = l.bank_account_id
WHERE l.state = 'requested'
ORDER BY l.created_at ASC
LIMIT ?
]]

function R.ListPendingLoans(limit)
  return DB.Query(SQL_LOANS_PENDING, { tonumber(limit) or 50 })
end

-- ---------------------------------------------------------------------------
-- §6. Pending KYC submissions (derived from audit ledger)
--   A citizen has pending KYC if:
--     (a) latest event for them with event_type='kyc_submit' exists, AND
--     (b) no later 'kyc_approve' or 'kyc_reject' event for the same citizen.
-- ---------------------------------------------------------------------------
-- KYC submission/decision data lives inside the JSON `context_data` column
-- (the canonical audit ledger only persists `actor_account_id` as a top-level
-- column — for citizen-driven events that field is NULL). We extract
-- `actor_citizen_id` from JSON to identify the submitter and use a NOT EXISTS
-- subquery on later kyc_approve/kyc_reject events for the same citizen.
local SQL_KYC_PENDING = [[
SELECT JSON_UNQUOTE(JSON_EXTRACT(submit.context_data, '$.actor_citizen_id')) AS citizen_id,
       MAX(submit.ts) * 1000 AS submitted_ms,
       JSON_UNQUOTE(JSON_EXTRACT(MAX(submit.context_data), '$.event_data.doc_count')) AS doc_count
FROM sonar_bank_audit_ledger submit
WHERE submit.event_type = 'kyc_submit'
  AND JSON_EXTRACT(submit.context_data, '$.actor_citizen_id') IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sonar_bank_audit_ledger decided
    WHERE decided.event_type IN ('kyc_approve','kyc_reject')
      AND JSON_UNQUOTE(JSON_EXTRACT(decided.context_data, '$.target_citizen_id'))
        = JSON_UNQUOTE(JSON_EXTRACT(submit.context_data, '$.actor_citizen_id'))
      AND decided.ts >= submit.ts
  )
GROUP BY citizen_id
ORDER BY submitted_ms ASC
LIMIT ?
]]

function R.ListPendingKyc(limit)
  return DB.Query(SQL_KYC_PENDING, { tonumber(limit) or 50 })
end

-- ---------------------------------------------------------------------------
-- §7. Customers search (citizen_id LIKE, with account count)
-- ---------------------------------------------------------------------------
local SQL_CUSTOMERS_SEARCH = [[
SELECT sa.char_id AS citizen_id,
       COUNT(a.id) AS account_count,
       CAST(ROUND(COALESCE(SUM(a.balance), 0) * 100) AS SIGNED) AS total_balance_minor,
       CAST(ROUND(COALESCE(SUM(a.savings), 0) * 100) AS SIGNED) AS total_savings_minor,
       MAX(a.updated_at) * 1000 AS last_activity_ms,
       SUM(CASE WHEN a.is_frozen = 1 THEN 1 ELSE 0 END) AS frozen_count
FROM sonar_accounts sa
INNER JOIN sonar_bank_accounts a ON a.owner_account_id = sa.id
WHERE sa.char_id LIKE ?
  AND a.closed_at IS NULL
GROUP BY sa.char_id
ORDER BY last_activity_ms DESC
LIMIT ?
]]

function R.SearchCustomers(query, limit)
  local q = '%' .. (tostring(query or '')):gsub('%%', '\\%%'):gsub('_', '\\_') .. '%'
  return DB.Query(SQL_CUSTOMERS_SEARCH, { q, tonumber(limit) or 25 })
end

-- ---------------------------------------------------------------------------
-- §8. Customer detail (accounts list of a single citizen, for banker view)
-- ---------------------------------------------------------------------------
local SQL_CUSTOMER_ACCOUNTS = [[
SELECT a.id AS account_id, a.iban,
       a.owner_type, a.account_class,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       CAST(ROUND(a.savings * 100) AS SIGNED) AS savings_minor,
       a.is_frozen, a.created_at * 1000 AS created_ms,
       a.updated_at * 1000 AS updated_ms
FROM sonar_bank_accounts a
INNER JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE sa.char_id = ? AND a.closed_at IS NULL
ORDER BY a.created_at ASC
LIMIT 32
]]

function R.GetCustomerAccounts(citizen_id)
  return DB.Query(SQL_CUSTOMER_ACCOUNTS, { citizen_id })
end

-- ---------------------------------------------------------------------------
-- §9. Account freeze (banker — direct, no ownership check)
--   Mirrors AccountsRepo.SetFrozenFlag but kept here so the banker path is
--   independent of the customer-facing repo for audit clarity.
-- ---------------------------------------------------------------------------
local SQL_GET_ACCOUNT_BY_IBAN = [[
SELECT a.id AS account_id, a.iban, a.owner_type, a.account_class,
       a.is_frozen,
       sa.char_id AS owner_citizen_id,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       CAST(ROUND(a.savings * 100) AS SIGNED) AS savings_minor
FROM sonar_bank_accounts a
INNER JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE a.iban = ? AND a.closed_at IS NULL
LIMIT 1
]]

local SQL_SET_FROZEN = [[
UPDATE sonar_bank_accounts SET is_frozen = ?, updated_at = UNIX_TIMESTAMP()
WHERE iban = ? AND closed_at IS NULL
]]

function R.GetAccountByIban(iban)
  return DB.QuerySingle(SQL_GET_ACCOUNT_BY_IBAN, { iban })
end

function R.SetFrozenByIban(iban, frozen_bool)
  return DB.Execute(SQL_SET_FROZEN, { frozen_bool and 1 or 0, iban })
end
