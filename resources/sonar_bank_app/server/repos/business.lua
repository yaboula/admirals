BankApp.repos.business = {}
local R = BankApp.repos.business

local DB = BankApp.lib.db

local SQL_LIST_COMPANIES = [[
SELECT c.id AS companyId,
       c.name,
       c.status,
       c.sector,
       c.founded_at * 1000 AS foundedAt,
       COALESCE(c.employee_count_cached, members.employee_count, 0) AS employeeCount,
       CAST(ROUND(COALESCE(treasury.balance, 0) * 100) AS SIGNED) AS treasury,
       COALESCE(rs.risk_level, 'low') AS riskLevel,
       COALESCE(rs.score, 12) AS riskScore,
       COALESCE(flags.flag_count, 0) AS flagCount,
       COALESCE(latest.last_activity_ms, c.updated_at * 1000) AS lastActivityAt
FROM sonar_companies c
LEFT JOIN sonar_bank_business_treasuries bt ON bt.company_id = c.id
LEFT JOIN sonar_bank_accounts treasury ON treasury.id = bt.bank_account_id
LEFT JOIN sonar_bank_govt_risk_scores rs ON rs.subject_type = 'company' AND rs.subject_id = c.id
LEFT JOIN (
  SELECT company_id, COUNT(*) AS employee_count
  FROM sonar_company_members
  WHERE active = 1
  GROUP BY company_id
) members ON members.company_id = c.id
LEFT JOIN (
  SELECT ba.owner_company_id, MAX(m.occurred_at) * 1000 AS last_activity_ms
  FROM sonar_bank_accounts ba
  INNER JOIN sonar_bank_movements m ON m.bank_account_id = ba.id
  WHERE ba.owner_company_id IS NOT NULL
  GROUP BY ba.owner_company_id
) latest ON latest.owner_company_id = c.id
LEFT JOIN (
  SELECT bank.owner_company_id, COUNT(*) AS flag_count
  FROM sonar_bank_compliance_flags cf
  INNER JOIN sonar_bank_accounts bank ON bank.id = cf.bank_account_id
  WHERE bank.owner_company_id IS NOT NULL AND cf.status IN ('open','investigating')
  GROUP BY bank.owner_company_id
) flags ON flags.owner_company_id = c.id
ORDER BY COALESCE(rs.score, 12) DESC, c.status ASC, c.name ASC
LIMIT ?
]]

local SQL_GET_COMPANY = [[
SELECT c.id AS companyId,
       c.name,
       c.status,
       c.sector,
       c.founded_at * 1000 AS foundedAt,
       COALESCE(c.employee_count_cached, members.employee_count, 0) AS employeeCount,
       CAST(ROUND(COALESCE(treasury.balance, 0) * 100) AS SIGNED) AS treasury,
       COALESCE(rs.risk_level, 'low') AS riskLevel,
       COALESCE(rs.score, 12) AS riskScore,
       COALESCE(flags.flag_count, 0) AS flagCount,
       COALESCE(latest.last_activity_ms, c.updated_at * 1000) AS lastActivityAt,
       treasury.iban AS ibanPrimary,
       bt.id AS treasuryId,
       bt.signing_threshold AS signingThreshold,
       CAST(ROUND(bt.amount_threshold * 100) AS SIGNED) AS amountThreshold,
       COALESCE(payroll.total_payroll_month_minor, 0) AS payrollMonthly
FROM sonar_companies c
LEFT JOIN sonar_bank_business_treasuries bt ON bt.company_id = c.id
LEFT JOIN sonar_bank_accounts treasury ON treasury.id = bt.bank_account_id
LEFT JOIN sonar_bank_govt_risk_scores rs ON rs.subject_type = 'company' AND rs.subject_id = c.id
LEFT JOIN (
  SELECT company_id, COUNT(*) AS employee_count
  FROM sonar_company_members
  WHERE active = 1
  GROUP BY company_id
) members ON members.company_id = c.id
LEFT JOIN (
  SELECT ba.owner_company_id, MAX(m.occurred_at) * 1000 AS last_activity_ms
  FROM sonar_bank_accounts ba
  INNER JOIN sonar_bank_movements m ON m.bank_account_id = ba.id
  WHERE ba.owner_company_id IS NOT NULL
  GROUP BY ba.owner_company_id
) latest ON latest.owner_company_id = c.id
LEFT JOIN (
  SELECT bank.owner_company_id, COUNT(*) AS flag_count
  FROM sonar_bank_compliance_flags cf
  INNER JOIN sonar_bank_accounts bank ON bank.id = cf.bank_account_id
  WHERE bank.owner_company_id IS NOT NULL AND cf.status IN ('open','investigating')
  GROUP BY bank.owner_company_id
) flags ON flags.owner_company_id = c.id
LEFT JOIN (
  SELECT company_id, CAST(ROUND(SUM(COALESCE(salary_amount, 0)) * 100) AS SIGNED) AS total_payroll_month_minor
  FROM sonar_company_members
  WHERE active = 1
  GROUP BY company_id
) payroll ON payroll.company_id = c.id
WHERE c.id = ?
LIMIT 1
]]

local SQL_LIST_COMPANY_DIRECTORS = [[
SELECT sa.char_id AS cid,
       COALESCE(sa.alias, sa.char_id) AS alias,
       CASE
         WHEN cm.role = 'co-founder' THEN 'co-founder'
         WHEN cm.role = 'founder' THEN 'founder'
         ELSE 'director'
       END AS role,
       cm.joined_at * 1000 AS joinedAt
FROM sonar_company_members cm
INNER JOIN sonar_accounts sa ON sa.id = cm.account_id
WHERE cm.company_id = ? AND cm.active = 1 AND cm.role IN ('founder','co-founder','director','manager')
ORDER BY FIELD(cm.role, 'founder', 'co-founder', 'director', 'manager'), cm.joined_at ASC
LIMIT ?
]]

local SQL_LIST_COMPANY_FLAGS = [[
SELECT CAST(cf.id AS CHAR) AS id,
       cf.raised_at * 1000 AS raisedAt,
       cf.severity,
       cf.status,
       cf.flag_type,
       cf.evidence,
       cf.threshold_value,
       cf.observed_value
FROM sonar_bank_compliance_flags cf
INNER JOIN sonar_bank_accounts ba ON ba.id = cf.bank_account_id
WHERE ba.owner_company_id = ?
ORDER BY cf.raised_at DESC
LIMIT ?
]]

local SQL_LIST_COMPANY_ACTIVITY = [[
SELECT CAST(m.id AS CHAR) AS id,
       m.occurred_at * 1000 AS timestamp,
       CASE
         WHEN m.category = 'salary' THEN 'payroll_processed'
         WHEN m.category = 'tax' THEN 'tax_payment'
         WHEN m.amount < 0 THEN 'transfer_out'
         ELSE 'transfer_in'
       END AS type,
       CAST(ROUND(ABS(m.amount) * 100) AS SIGNED) AS amount,
       COALESCE(m.concept, m.category) AS description
FROM sonar_bank_movements m
INNER JOIN sonar_bank_accounts ba ON ba.id = m.bank_account_id
WHERE ba.owner_company_id = ?
ORDER BY m.occurred_at DESC
LIMIT ?
]]

local SQL_GET_TREASURY_SNAPSHOT = [[
SELECT c.id AS company_id,
       c.name AS company_name,
       c.employee_count_cached AS employee_count,
       bt.id AS treasury_id,
       bt.signing_threshold,
       ba.id AS bank_account_id,
       ba.iban,
       CAST(ROUND(ba.balance * 100) AS SIGNED) AS balance_minor,
       COALESCE(cm.role, signer.signer_role, 'employee') AS member_role,
       COALESCE(avg_tenure.average_tenure_days, 0) AS average_tenure_days,
       COALESCE(payroll.total_payroll_month_minor, 0) AS total_payroll_month_minor
FROM sonar_companies c
INNER JOIN sonar_bank_business_treasuries bt ON bt.company_id = c.id
INNER JOIN sonar_bank_accounts ba ON ba.id = bt.bank_account_id
INNER JOIN sonar_accounts actor ON actor.char_id = ?
LEFT JOIN sonar_company_members cm ON cm.company_id = c.id AND cm.account_id = actor.id AND cm.active = 1
LEFT JOIN sonar_bank_business_treasury_signers signer ON signer.treasury_id = bt.id AND signer.signer_account_id = actor.id AND signer.active = 1
LEFT JOIN (
  SELECT company_id, FLOOR(AVG((UNIX_TIMESTAMP() - joined_at) / 86400)) AS average_tenure_days
  FROM sonar_company_members
  WHERE active = 1
  GROUP BY company_id
) avg_tenure ON avg_tenure.company_id = c.id
LEFT JOIN (
  SELECT company_id, CAST(ROUND(SUM(COALESCE(salary_amount, 0)) * 100) AS SIGNED) AS total_payroll_month_minor
  FROM sonar_company_members
  WHERE active = 1
  GROUP BY company_id
) payroll ON payroll.company_id = c.id
WHERE c.id = ? AND (cm.id IS NOT NULL OR signer.id IS NOT NULL)
LIMIT 1
]]

local SQL_LIST_BUSINESS_MOVEMENTS = [[
SELECT CAST(m.id AS CHAR) AS movement_id,
       m.category AS event_type,
       CAST(ROUND(ABS(m.amount) * 100) AS SIGNED) AS amount_minor,
       'USD' AS currency,
       CASE WHEN m.amount < 0 THEN 'out' ELSE 'in' END AS direction,
       COALESCE(m.counterpart_iban, 'system') AS counterparty_masked,
       m.concept AS reason,
       'committed' AS status,
       m.occurred_at * 1000 AS timestamp_ms
FROM sonar_bank_movements m
INNER JOIN sonar_bank_accounts ba ON ba.id = m.bank_account_id
WHERE ba.owner_company_id = ?
ORDER BY m.occurred_at DESC
LIMIT ?
]]

local SQL_LIST_PENDING_APPROVALS = [[
SELECT a.id AS approval_id,
       CASE
         WHEN a.operation_kind = 'large_withdraw' THEN 'withdrawal'
         WHEN a.operation_kind = 'recurring_setup' THEN 'recurring'
         ELSE 'payroll'
       END AS type,
       COALESCE(sa.alias, sa.char_id, 'system') AS requested_by_alias,
       CAST(ROUND(a.operation_amount * 100) AS SIGNED) AS amount_minor,
       'USD' AS currency,
       a.initiated_at * 1000 AS created_at_ms,
       'sonar.bank.business.approve' AS required_perm,
       a.state AS status
FROM sonar_bank_business_treasury_approvals a
INNER JOIN sonar_bank_business_treasuries bt ON bt.id = a.treasury_id
LEFT JOIN sonar_accounts sa ON sa.id = a.initiated_by_account_id
WHERE bt.company_id = ? AND a.state IN ('pending','approved','rejected')
ORDER BY a.initiated_at DESC
LIMIT ?
]]

local SQL_LIST_PAYROLL_LINES = [[
SELECT cm.id AS line_id,
       COALESCE(sa.alias, sa.char_id) AS employee_alias,
       COALESCE(cm.department, 'Operations') AS department,
       CAST(ROUND(COALESCE(cm.salary_amount, 0) * 100) AS SIGNED) AS net_amount_minor,
       'USD' AS currency,
       CASE WHEN dest.id IS NULL OR dest.is_frozen = 1 THEN 'held' ELSE 'ready' END AS status
FROM sonar_company_members cm
INNER JOIN sonar_accounts sa ON sa.id = cm.account_id
LEFT JOIN sonar_bank_accounts dest ON dest.owner_account_id = sa.id AND dest.closed_at IS NULL AND dest.owner_type = 'personal' AND dest.account_class = 'checking'
WHERE cm.company_id = ? AND cm.active = 1 AND COALESCE(cm.salary_amount, 0) > 0
ORDER BY cm.salary_amount DESC, cm.joined_at ASC
LIMIT ?
]]

function R.ListCompanies(limit)
  return DB.Query(SQL_LIST_COMPANIES, { limit or 100 })
end

function R.GetCompany(company_id)
  return DB.QuerySingle(SQL_GET_COMPANY, { company_id })
end

function R.ListCompanyDirectors(company_id, limit)
  return DB.Query(SQL_LIST_COMPANY_DIRECTORS, { company_id, limit or 8 })
end

function R.ListCompanyFlags(company_id, limit)
  return DB.Query(SQL_LIST_COMPANY_FLAGS, { company_id, limit or 20 })
end

function R.ListCompanyActivity(company_id, limit)
  return DB.Query(SQL_LIST_COMPANY_ACTIVITY, { company_id, limit or 20 })
end

function R.GetTreasurySnapshot(company_id, actor_cid)
  return DB.QuerySingle(SQL_GET_TREASURY_SNAPSHOT, { actor_cid, company_id })
end

function R.ListBusinessMovements(company_id, limit)
  return DB.Query(SQL_LIST_BUSINESS_MOVEMENTS, { company_id, limit or 12 })
end

function R.ListPendingApprovals(company_id, limit)
  return DB.Query(SQL_LIST_PENDING_APPROVALS, { company_id, limit or 8 })
end

function R.ListPayrollLines(company_id, limit)
  return DB.Query(SQL_LIST_PAYROLL_LINES, { company_id, limit or 24 })
end

function R.GetPayrollExecutionContext(company_id, actor_cid)
  return DB.QuerySingle([[
SELECT c.id AS company_id,
       c.name AS company_name,
       actor.id AS actor_account_id,
       actor.char_id AS actor_cid,
       bt.id AS treasury_id,
       bt.signing_threshold,
       bt.amount_threshold,
       ba.id AS treasury_account_id,
       ba.iban AS treasury_iban,
       ba.balance AS treasury_balance,
       COALESCE(cm.role, signer.signer_role, 'employee') AS actor_role
FROM sonar_companies c
INNER JOIN sonar_bank_business_treasuries bt ON bt.company_id = c.id
INNER JOIN sonar_bank_accounts ba ON ba.id = bt.bank_account_id
INNER JOIN sonar_accounts actor ON actor.char_id = ?
LEFT JOIN sonar_company_members cm ON cm.company_id = c.id AND cm.account_id = actor.id AND cm.active = 1
LEFT JOIN sonar_bank_business_treasury_signers signer ON signer.treasury_id = bt.id AND signer.signer_account_id = actor.id AND signer.active = 1
WHERE c.id = ? AND ba.closed_at IS NULL AND ba.is_frozen = 0 AND (cm.id IS NOT NULL OR signer.id IS NOT NULL)
LIMIT 1
]], { actor_cid, company_id })
end

function R.ListPayrollExecutionLines(company_id)
  return DB.Query([[
SELECT cm.id AS member_id,
       sa.id AS employee_account_id,
       COALESCE(sa.alias, sa.char_id) AS employee_alias,
       dest.id AS destination_bank_account_id,
       dest.iban AS destination_iban,
       dest.balance AS destination_balance,
       CAST(COALESCE(cm.salary_amount, 0) AS DECIMAL(14,2)) AS net_amount,
       CASE WHEN dest.id IS NULL OR dest.is_frozen = 1 THEN 'held' ELSE 'ready' END AS state
FROM sonar_company_members cm
INNER JOIN sonar_accounts sa ON sa.id = cm.account_id
LEFT JOIN sonar_bank_accounts dest ON dest.owner_account_id = sa.id AND dest.closed_at IS NULL AND dest.owner_type = 'personal' AND dest.account_class = 'checking'
WHERE cm.company_id = ? AND cm.active = 1 AND COALESCE(cm.salary_amount, 0) > 0 AND dest.id IS NOT NULL
ORDER BY cm.salary_amount DESC, cm.joined_at ASC
]], { company_id })
end

function R.CreatePayrollBatchWithLines(params, lines, approval)
  local queries = {
    {
      query = [[
INSERT INTO sonar_bank_business_payroll_batches
  (id, company_id, treasury_id, state, total_net_amount, line_count, held_line_count, requested_by_account_id, scheduled_for, related_approval_id, idempotency_key)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]],
      values = {
        params.batch_id,
        params.company_id,
        params.treasury_id,
        params.state,
        params.total_net_amount,
        params.line_count,
        params.held_line_count,
        params.requested_by_account_id,
        params.scheduled_for,
        approval and approval.approval_id or nil,
        params.idempotency_key,
      },
    },
  }

  if approval then
    queries[#queries + 1] = {
      query = [[
INSERT INTO sonar_bank_business_treasury_approvals
  (id, treasury_id, operation_kind, operation_payload, operation_amount, operation_description, state, signers_required, signers_approved, approvals_json, initiated_by_account_id, expires_at)
VALUES (?, ?, 'custom', ?, ?, ?, 'pending', ?, 1, ?, ?, UNIX_TIMESTAMP() + 259200)
]],
      values = {
        approval.approval_id,
        params.treasury_id,
        approval.operation_payload,
        params.total_net_amount,
        approval.operation_description,
        approval.signers_required,
        approval.approvals_json,
        params.requested_by_account_id,
      },
    }
  end

  for _, line in ipairs(lines or {}) do
    queries[#queries + 1] = {
      query = [[
INSERT INTO sonar_bank_business_payroll_lines
  (id, batch_id, company_id, employee_account_id, destination_bank_account_id, net_amount, state)
VALUES (?, ?, ?, ?, ?, ?, ?)
]],
      values = { line.id, params.batch_id, params.company_id, line.employee_account_id, line.destination_bank_account_id, line.net_amount, line.state },
    }
  end

  return DB.Transaction(queries)
end

function R.GetApprovalForDecision(approval_id, actor_cid)
  return DB.QuerySingle([[
SELECT a.id AS approval_id,
       a.state,
       a.signers_required,
       a.signers_approved,
       a.approvals_json,
       a.operation_payload,
       a.treasury_id,
       bt.company_id,
       bt.bank_account_id AS treasury_account_id,
       actor.id AS actor_account_id,
       actor.char_id AS actor_cid,
       signer.signer_role,
       ba.iban AS treasury_iban,
       ba.balance AS treasury_balance
FROM sonar_bank_business_treasury_approvals a
INNER JOIN sonar_bank_business_treasuries bt ON bt.id = a.treasury_id
INNER JOIN sonar_bank_accounts ba ON ba.id = bt.bank_account_id
INNER JOIN sonar_accounts actor ON actor.char_id = ?
INNER JOIN sonar_bank_business_treasury_signers signer ON signer.treasury_id = bt.id AND signer.signer_account_id = actor.id AND signer.active = 1
WHERE a.id = ? AND a.expires_at > UNIX_TIMESTAMP()
LIMIT 1
]], { actor_cid, approval_id })
end

function R.GetPayrollBatchForApproval(approval_id)
  return DB.QuerySingle([[
SELECT id AS batch_id, company_id, treasury_id, state, total_net_amount, line_count, held_line_count
FROM sonar_bank_business_payroll_batches
WHERE related_approval_id = ?
LIMIT 1
]], { approval_id })
end

function R.GetPayrollBatchLines(batch_id)
  return DB.Query([[
SELECT l.id,
       l.employee_account_id,
       l.destination_bank_account_id,
       l.net_amount,
       l.state,
       dest.iban AS destination_iban,
       dest.balance AS destination_balance
FROM sonar_bank_business_payroll_lines l
INNER JOIN sonar_bank_accounts dest ON dest.id = l.destination_bank_account_id
WHERE l.batch_id = ?
ORDER BY l.created_at ASC
]], { batch_id })
end

function R.DecidePayrollApprovalTx(params, lines)
  local queries = {
    {
      query = [[
UPDATE sonar_bank_business_treasury_approvals
SET state = ?, signers_approved = ?, approvals_json = ?, finalized_at = CASE WHEN ? = 1 THEN UNIX_TIMESTAMP() ELSE finalized_at END
WHERE id = ? AND state = 'pending'
]],
      values = { params.approval_state, params.signers_approved, params.approvals_json, params.finalized and 1 or 0, params.approval_id },
    },
    {
      query = [[
UPDATE sonar_bank_business_payroll_batches
SET state = ?, executed_by_account_id = ?, executed_at = CASE WHEN ? = 'executed' THEN UNIX_TIMESTAMP() ELSE executed_at END, updated_at = UNIX_TIMESTAMP()
WHERE id = ?
]],
      values = { params.batch_state, params.actor_account_id, params.batch_state, params.batch_id },
    },
  }

  if params.batch_state == 'executed' then
    queries[#queries + 1] = {
      query = [[
UPDATE sonar_bank_accounts
SET balance = balance - ?, updated_at = UNIX_TIMESTAMP()
WHERE id = ? AND balance >= ? AND is_frozen = 0 AND closed_at IS NULL
]],
      values = { params.total_ready_amount, params.treasury_account_id, params.total_ready_amount },
    }

    for _, line in ipairs(lines or {}) do
      if line.state == 'ready' then
        queries[#queries + 1] = {
          query = [[
UPDATE sonar_bank_accounts
SET balance = balance + ?, updated_at = UNIX_TIMESTAMP()
WHERE id = ? AND is_frozen = 0 AND closed_at IS NULL
]],
          values = { line.net_amount, line.destination_bank_account_id },
        }
        queries[#queries + 1] = {
          query = [[
INSERT INTO sonar_bank_movements
  (bank_account_id, amount, balance_after, category, counterpart_iban, concept, related_job_id, request_nonce, initiated_by_account_id, source_resource)
VALUES (?, ?, ?, 'salary', ?, ?, ?, ?, ?, 'sonar_bank_app')
]],
          values = { params.treasury_account_id, -line.net_amount, params.treasury_balance_after, line.destination_iban, params.reason, params.batch_id, params.idempotency_key, params.actor_account_id },
        }
        queries[#queries + 1] = {
          query = [[
INSERT INTO sonar_bank_movements
  (bank_account_id, amount, balance_after, category, counterpart_iban, concept, related_job_id, request_nonce, initiated_by_account_id, source_resource)
VALUES (?, ?, ?, 'salary', ?, ?, ?, ?, ?, 'sonar_bank_app')
]],
          values = { line.destination_bank_account_id, line.net_amount, line.destination_balance_after, params.treasury_iban, params.reason, params.batch_id, params.idempotency_key, params.actor_account_id },
        }
        queries[#queries + 1] = {
          query = [[
UPDATE sonar_bank_business_payroll_lines
SET state = 'paid', paid_at = UNIX_TIMESTAMP(), updated_at = UNIX_TIMESTAMP()
WHERE id = ? AND state = 'ready'
]],
          values = { line.id },
        }
      end
    end
  end

  return DB.Transaction(queries)
end

return R
