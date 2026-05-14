BankApp.repos.govt = {}
local R = BankApp.repos.govt

local DB = BankApp.lib.db
local Config = BankApp.Config

local SQL_GET_ACCOUNT_BY_CID = [[
SELECT id, char_id, alias
FROM sonar_accounts
WHERE char_id = ?
LIMIT 1
]]

local SQL_LIST_CITIZENS = [[
SELECT sa.id AS account_uuid,
       sa.char_id AS cid,
       sa.alias,
       sa.created_at * 1000 AS created_ms,
       COALESCE(acc.total_holdings_minor, 0) AS totalHoldings,
       COALESCE(acc.account_count, 0) AS accountCount,
       acc.primary_iban AS primaryIban,
       COALESCE(acc.any_frozen, 0) AS anyFrozen,
       COALESCE(flags.flag_count, 0) AS flagCount,
       COALESCE(rs.score, 12) AS riskScore,
       COALESCE(rs.risk_level, 'low') AS riskLevel,
       COALESCE(latest.last_activity_ms, sa.updated_at * 1000) AS lastActivityAt
FROM sonar_accounts sa
LEFT JOIN (
  SELECT owner_account_id,
         CAST(ROUND(SUM(balance) * 100) AS SIGNED) AS total_holdings_minor,
         COUNT(*) AS account_count,
         MIN(iban) AS primary_iban,
         MAX(is_frozen) AS any_frozen
  FROM sonar_bank_accounts
  WHERE closed_at IS NULL
  GROUP BY owner_account_id
) acc ON acc.owner_account_id = sa.id
LEFT JOIN (
  SELECT citizen_account_id, COUNT(*) AS flag_count
  FROM sonar_bank_compliance_flags
  WHERE status IN ('open','investigating')
  GROUP BY citizen_account_id
) flags ON flags.citizen_account_id = sa.id
LEFT JOIN sonar_bank_govt_risk_scores rs ON rs.subject_type = 'citizen' AND rs.subject_id = sa.id
LEFT JOIN (
  SELECT ba.owner_account_id, MAX(m.occurred_at) * 1000 AS last_activity_ms
  FROM sonar_bank_accounts ba
  INNER JOIN sonar_bank_movements m ON m.bank_account_id = ba.id
  GROUP BY ba.owner_account_id
) latest ON latest.owner_account_id = sa.id
ORDER BY COALESCE(rs.score, 12) DESC, flags.flag_count DESC, sa.created_at DESC
LIMIT ?
]]

local SQL_GET_CITIZEN = [[
SELECT sa.id AS account_uuid,
       sa.char_id AS cid,
       sa.alias,
       sa.created_at * 1000 AS created_ms,
       COALESCE(acc.total_holdings_minor, 0) AS totalHoldings,
       COALESCE(acc.account_count, 0) AS accountCount,
       acc.primary_iban AS primaryIban,
       COALESCE(acc.any_frozen, 0) AS anyFrozen,
       COALESCE(flags.flag_count, 0) AS flagCount,
       COALESCE(rs.score, 12) AS riskScore,
       COALESCE(rs.risk_level, 'low') AS riskLevel,
       COALESCE(latest.last_activity_ms, sa.updated_at * 1000) AS lastActivityAt
FROM sonar_accounts sa
LEFT JOIN (
  SELECT owner_account_id,
         CAST(ROUND(SUM(balance) * 100) AS SIGNED) AS total_holdings_minor,
         COUNT(*) AS account_count,
         MIN(iban) AS primary_iban,
         MAX(is_frozen) AS any_frozen
  FROM sonar_bank_accounts
  WHERE closed_at IS NULL
  GROUP BY owner_account_id
) acc ON acc.owner_account_id = sa.id
LEFT JOIN (
  SELECT citizen_account_id, COUNT(*) AS flag_count
  FROM sonar_bank_compliance_flags
  WHERE status IN ('open','investigating')
  GROUP BY citizen_account_id
) flags ON flags.citizen_account_id = sa.id
LEFT JOIN sonar_bank_govt_risk_scores rs ON rs.subject_type = 'citizen' AND rs.subject_id = sa.id
LEFT JOIN (
  SELECT ba.owner_account_id, MAX(m.occurred_at) * 1000 AS last_activity_ms
  FROM sonar_bank_accounts ba
  INNER JOIN sonar_bank_movements m ON m.bank_account_id = ba.id
  GROUP BY ba.owner_account_id
) latest ON latest.owner_account_id = sa.id
WHERE sa.char_id = ?
LIMIT 1
]]

local SQL_LIST_CITIZEN_ACTIVITY = [[
SELECT CAST(m.id AS CHAR) AS id,
       m.occurred_at * 1000 AS timestamp,
       CASE
         WHEN m.category = 'tax' THEN 'tax_payment'
         WHEN m.category = 'tax_subsidy' THEN 'subsidy_received'
         WHEN m.amount < 0 THEN 'transfer_out'
         ELSE 'transfer_in'
       END AS type,
       CAST(ROUND(ABS(m.amount) * 100) AS SIGNED) AS amount,
       COALESCE(m.concept, m.category) AS description,
       m.counterpart_iban AS counterparty
FROM sonar_bank_movements m
INNER JOIN sonar_bank_accounts ba ON ba.id = m.bank_account_id
INNER JOIN sonar_accounts sa ON sa.id = ba.owner_account_id
WHERE sa.char_id = ?
ORDER BY m.occurred_at DESC
LIMIT ?
]]

local SQL_LIST_CITIZEN_FLAGS = [[
SELECT CAST(cf.id AS CHAR) AS id,
       cf.raised_at * 1000 AS raisedAt,
       cf.severity,
       cf.status,
       cf.flag_type,
       cf.evidence,
       cf.threshold_value,
       cf.observed_value
FROM sonar_bank_compliance_flags cf
INNER JOIN sonar_accounts sa ON sa.id = cf.citizen_account_id
WHERE sa.char_id = ?
ORDER BY cf.raised_at DESC
LIMIT ?
]]

local SQL_RISK_METRICS = [[
SELECT sa.id AS account_uuid,
       sa.char_id AS cid,
       COALESCE(MAX(CASE WHEN m.amount < 0 THEN ABS(m.amount) ELSE 0 END), 0) AS max_outgoing_amount,
       COALESCE(SUM(CASE WHEN m.amount < 0 AND m.occurred_at >= UNIX_TIMESTAMP() - ? THEN 1 ELSE 0 END), 0) AS outgoing_5m_count,
       COALESCE(SUM(CASE WHEN m.amount < 0 AND dst.is_frozen = 1 THEN 1 ELSE 0 END), 0) AS frozen_destination_count,
       MIN(ba.id) AS primary_bank_account_id
FROM sonar_accounts sa
LEFT JOIN sonar_bank_accounts ba ON ba.owner_account_id = sa.id AND ba.closed_at IS NULL
LEFT JOIN sonar_bank_movements m ON m.bank_account_id = ba.id AND m.occurred_at >= UNIX_TIMESTAMP() - ?
LEFT JOIN sonar_bank_accounts dst ON dst.iban = m.counterpart_iban
WHERE sa.char_id = ?
GROUP BY sa.id, sa.char_id
LIMIT 1
]]

local SQL_UPSERT_RISK = [[
INSERT INTO sonar_bank_govt_risk_scores
  (subject_type, subject_id, score, risk_level, velocity_score, compliance_score,
   exposure_score, flag_score, dormancy_score, components_json, formula_version,
   computed_by, computed_at, expires_at)
VALUES ('citizen', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + ?)
ON DUPLICATE KEY UPDATE
  score = VALUES(score),
  risk_level = VALUES(risk_level),
  velocity_score = VALUES(velocity_score),
  compliance_score = VALUES(compliance_score),
  exposure_score = VALUES(exposure_score),
  flag_score = VALUES(flag_score),
  dormancy_score = VALUES(dormancy_score),
  components_json = VALUES(components_json),
  formula_version = VALUES(formula_version),
  computed_by = VALUES(computed_by),
  computed_at = VALUES(computed_at),
  expires_at = VALUES(expires_at)
]]

local SQL_INSERT_FLAG_IF_MISSING = [[
INSERT INTO sonar_bank_compliance_flags
  (flag_type, severity, status, citizen_account_id, bank_account_id, raised_by,
   threshold_value, observed_value, time_window_seconds, evidence, related_movement_ids)
SELECT ?, ?, 'open', ?, ?, 'system', ?, ?, ?, ?, JSON_ARRAY()
WHERE NOT EXISTS (
  SELECT 1 FROM sonar_bank_compliance_flags
  WHERE citizen_account_id = ? AND flag_type = ? AND status IN ('open','investigating')
  LIMIT 1
)
]]

local SQL_LIST_FLAG_QUEUE = [[
SELECT CAST(cf.id AS CHAR) AS flagId,
       sa.char_id AS citizenCid,
       sa.alias AS citizenAlias,
       CASE WHEN acc.any_frozen = 1 THEN 'sanctioned' ELSE 'flagged' END AS citizenStatus,
       COALESCE(rs.risk_level, 'low') AS citizenRiskLevel,
       cf.raised_at * 1000 AS raisedAt,
       cf.severity,
       cf.status,
       cf.flag_type,
       cf.evidence,
       cf.threshold_value,
       cf.observed_value
FROM sonar_bank_compliance_flags cf
INNER JOIN sonar_accounts sa ON sa.id = cf.citizen_account_id
LEFT JOIN sonar_bank_govt_risk_scores rs ON rs.subject_type = 'citizen' AND rs.subject_id = sa.id
LEFT JOIN (
  SELECT owner_account_id, MAX(is_frozen) AS any_frozen
  FROM sonar_bank_accounts
  WHERE closed_at IS NULL
  GROUP BY owner_account_id
) acc ON acc.owner_account_id = sa.id
WHERE cf.status IN ('open','investigating')
ORDER BY cf.raised_at DESC
LIMIT ?
]]

local SQL_LIST_COMPLIANCE_FLAGS = [[
SELECT CAST(cf.id AS CHAR) AS flag_id,
       CONCAT('compliance.', cf.flag_type) AS event_type,
       sa.char_id AS subject_cid,
       COALESCE(ba.iban, '') AS account_iban,
       NULL AS counterparty_iban,
       CASE WHEN cf.observed_value IS NULL THEN NULL ELSE CAST(ROUND(cf.observed_value * 100) AS SIGNED) END AS amount_minor,
       'USD' AS currency,
       cf.severity,
       cf.status,
       cf.raised_at * 1000 AS created_at_ms,
       cf.updated_at * 1000 AS updated_at_ms,
       COALESCE(rs.score, 0) AS risk_score,
       cf.flag_type,
       cf.evidence AS details_json,
       COALESCE(JSON_LENGTH(cf.related_movement_ids), 0) AS evidence_count
FROM sonar_bank_compliance_flags cf
INNER JOIN sonar_accounts sa ON sa.id = cf.citizen_account_id
LEFT JOIN sonar_bank_accounts ba ON ba.id = cf.bank_account_id
LEFT JOIN sonar_bank_govt_risk_scores rs ON rs.subject_type = 'citizen' AND rs.subject_id = sa.id
WHERE (? IS NULL OR cf.status = ?)
  AND (? IS NULL OR cf.severity = ?)
  AND (? = '' OR sa.char_id LIKE ? OR cf.flag_type LIKE ? OR CAST(cf.id AS CHAR) LIKE ?)
ORDER BY cf.raised_at DESC, cf.id DESC
LIMIT ?
]]
local SQL_GET_FLAG = [[
SELECT cf.*, sa.char_id AS citizenCid, sa.alias AS citizenAlias
FROM sonar_bank_compliance_flags cf
INNER JOIN sonar_accounts sa ON sa.id = cf.citizen_account_id
WHERE cf.id = ?
LIMIT 1
]]

local SQL_CLOSE_FLAG = [[
UPDATE sonar_bank_compliance_flags
SET status = ?, resolved_by_account_id = (SELECT id FROM sonar_accounts WHERE char_id = ? LIMIT 1),
    action_taken = ?, resolution_note = ?, resolved_at = UNIX_TIMESTAMP(), updated_at = UNIX_TIMESTAMP()
WHERE id = ? AND status IN ('open','investigating')
]]

local SQL_LIST_ACCOUNTS_BY_CITIZEN = [[
SELECT ba.id AS account_id, ba.iban, ba.is_frozen, ba.balance,
       CAST(ROUND(ba.balance * 100) AS SIGNED) AS balance_minor,
       sa.id AS owner_account_id, sa.char_id AS owner_citizen_id
FROM sonar_bank_accounts ba
INNER JOIN sonar_accounts sa ON sa.id = ba.owner_account_id
WHERE sa.char_id = ? AND ba.closed_at IS NULL
ORDER BY ba.created_at ASC
]]

local SQL_SET_CITIZEN_FROZEN = [[
UPDATE sonar_bank_accounts ba
INNER JOIN sonar_accounts sa ON sa.id = ba.owner_account_id
SET ba.is_frozen = ?, ba.updated_at = UNIX_TIMESTAMP()
WHERE sa.char_id = ? AND ba.closed_at IS NULL
]]

local SQL_LIST_SANCTION_ACTIONS = [[
SELECT CAST(l.id AS CHAR) AS id,
       l.event_type,
       l.ts * 1000 AS performedAt,
       l.request_nonce AS idempotencyKey,
       l.context_data,
       COALESCE(actor.alias, actor.char_id, l.actor_account_id, 'government') AS operatorAlias
FROM sonar_bank_audit_ledger l
LEFT JOIN sonar_accounts actor ON actor.id = l.actor_account_id
WHERE l.event_type IN ('govt_flag_close','govt_freeze','govt_unfreeze','govt_fine_apply')
  AND (? IS NULL OR JSON_UNQUOTE(JSON_EXTRACT(l.context_data, '$.target_citizen_id')) = ?)
ORDER BY l.ts DESC, l.id DESC
LIMIT ?
]]

local SQL_DEBIT_FINE = [[
UPDATE sonar_bank_accounts
SET balance = balance - (? / 100.0), updated_at = UNIX_TIMESTAMP()
WHERE id = ? AND balance >= (? / 100.0) AND closed_at IS NULL AND is_frozen = 0
]]

local SQL_INSERT_FINE_MOVEMENT = [[
INSERT INTO sonar_bank_movements
  (bank_account_id, occurred_at, amount, balance_after, category, concept,
   related_doc_id, request_nonce, initiated_by_account_id, source_resource)
SELECT ba.id, UNIX_TIMESTAMP(), -(? / 100.0), ba.balance, 'fine_collected', ?, ?, ?, ?, 'sonar_bank_app'
FROM sonar_bank_accounts ba
WHERE ba.id = ?
LIMIT 1
]]

local SQL_TREASURY_MOVEMENTS = [[
SELECT CAST(m.id AS CHAR) AS id,
       COALESCE(m.related_doc_id, CONCAT('MOV-', m.id)) AS referenceCode,
       m.occurred_at * 1000 AS timestamp,
       CASE
         WHEN m.category = 'tax' THEN 'tax_collection'
         WHEN m.category = 'tax_subsidy' THEN 'subsidy_issued'
         WHEN m.category = 'fine_collected' THEN 'fine_collected'
         WHEN m.category = 'payroll_disbursement' THEN 'payroll_disbursement'
         WHEN m.category = 'reconciliation' THEN 'reconciliation'
         WHEN m.category = 'interest_accrued' THEN 'interest_accrued'
         WHEN m.amount < 0 THEN 'transfer_out'
         ELSE 'transfer_in'
       END AS type,
       'settled' AS status,
       CASE WHEN ba.owner_company_id IS NOT NULL THEN 'company' WHEN sa.char_id IS NOT NULL THEN 'citizen' ELSE 'system' END AS entityKind,
       COALESCE(ba.owner_company_id, sa.char_id, 'system') AS entityId,
       COALESCE(sa.alias, ba.owner_company_id, 'Sistema') AS entityLabel,
       COALESCE(m.concept, m.category) AS description,
       CAST(ROUND(ABS(m.amount) * 100) AS SIGNED) AS amount,
       CASE WHEN m.amount >= 0 THEN 'inflow' ELSE 'outflow' END AS direction
FROM sonar_bank_movements m
INNER JOIN sonar_bank_accounts ba ON ba.id = m.bank_account_id
LEFT JOIN sonar_accounts sa ON sa.id = ba.owner_account_id
WHERE m.category IN ('tax','tax_subsidy','fine_collected','payroll_disbursement','reconciliation','interest_accrued','transfer')
ORDER BY m.occurred_at DESC
LIMIT ? OFFSET ?
]]

local SQL_TREASURY_STATS = [[
SELECT CAST(ROUND(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) * 100) AS SIGNED) AS totalInflow,
       CAST(ROUND(SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) * 100) AS SIGNED) AS totalOutflow,
       COUNT(*) AS movementCount,
       CAST(ROUND(SUM(CASE WHEN category = 'tax' THEN ABS(amount) ELSE 0 END) * 100) AS SIGNED) AS taxCollected,
       CAST(ROUND(SUM(CASE WHEN category = 'fine_collected' THEN ABS(amount) ELSE 0 END) * 100) AS SIGNED) AS finesCollected,
       CAST(ROUND(SUM(CASE WHEN category = 'tax_subsidy' THEN ABS(amount) ELSE 0 END) * 100) AS SIGNED) AS subsidiesIssued
FROM sonar_bank_movements
WHERE occurred_at >= UNIX_TIMESTAMP() - ?
]]

local SQL_LIST_SUBSIDY_PROGRAMS = [[
SELECT id AS programId, code, name, program_type AS type, status,
       CAST(ROUND(budget_amount * 100) AS SIGNED) AS budget,
       CAST(ROUND(disbursed_amount * 100) AS SIGNED) AS disbursed,
       beneficiary_count_cached AS beneficiaryCount,
       starts_at * 1000 AS startDate,
       ends_at * 1000 AS endDate,
       description
FROM sonar_bank_subsidy_programs
ORDER BY status ASC, starts_at DESC
LIMIT ?
]]

local SQL_GET_SUBSIDY_PROGRAM = [[
SELECT id AS programId, code, name, program_type AS type, status,
       CAST(ROUND(budget_amount * 100) AS SIGNED) AS budget,
       CAST(ROUND(disbursed_amount * 100) AS SIGNED) AS disbursed,
       beneficiary_count_cached AS beneficiaryCount,
       starts_at * 1000 AS startDate,
       ends_at * 1000 AS endDate,
       description
FROM sonar_bank_subsidy_programs
WHERE id = ? OR code = ?
LIMIT 1
]]

local SQL_LIST_SUBSIDY_DISBURSEMENTS = [[
SELECT CAST(s.id AS CHAR) AS id,
       p.code AS programCode,
       COALESCE(sa.char_id, s.company_id) AS recipientId,
       COALESCE(sa.alias, c.name, s.company_id) AS recipientLabel,
       CASE WHEN s.company_id IS NULL THEN 'citizen' ELSE 'company' END AS recipientKind,
       CAST(ROUND(s.amount * 100) AS SIGNED) AS amount,
       s.issued_at * 1000 AS disbursedAt,
       COALESCE(s.reason_note, '') AS note,
       'confirmed' AS status
FROM sonar_bank_subsidies s
LEFT JOIN sonar_bank_subsidy_programs p ON p.id = s.program_id
LEFT JOIN sonar_accounts sa ON sa.id = s.beneficiary_account_id
LEFT JOIN sonar_companies c ON c.id = s.company_id
WHERE s.program_id = ?
ORDER BY s.issued_at DESC
LIMIT ?
]]

local SQL_SUBSIDY_STATS = [[
SELECT CAST(ROUND(COALESCE(SUM(disbursed_amount), 0) * 100) AS SIGNED) AS totalDisbursed,
       CAST(ROUND(COALESCE(SUM(budget_amount), 0) * 100) AS SIGNED) AS totalBudget,
       SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) AS activeProgramCount,
       COALESCE(SUM(beneficiary_count_cached), 0) AS totalBeneficiaries,
       0 AS pendingDisbursements
FROM sonar_bank_subsidy_programs
]]

local SQL_GET_SUBSIDY_CITIZEN_RECIPIENT = [[
SELECT sa.id AS beneficiary_account_id,
       sa.char_id AS recipientId,
       COALESCE(sa.alias, sa.char_id) AS recipientLabel,
       ba.id AS bank_account_id,
       ba.iban,
       CAST(ROUND(ba.balance * 100) AS SIGNED) AS balance_minor
FROM sonar_accounts sa
INNER JOIN sonar_bank_accounts ba ON ba.owner_account_id = sa.id
WHERE sa.char_id = ? AND ba.closed_at IS NULL AND ba.is_frozen = 0
ORDER BY ba.created_at ASC
LIMIT 1
]]

local SQL_GET_SUBSIDY_COMPANY_RECIPIENT = [[
SELECT COALESCE(c.created_by_account_id, actor.id) AS beneficiary_account_id,
       c.id AS recipientId,
       c.name AS recipientLabel,
       ba.id AS bank_account_id,
       ba.iban,
       CAST(ROUND(ba.balance * 100) AS SIGNED) AS balance_minor
FROM sonar_companies c
INNER JOIN sonar_bank_business_treasuries bt ON bt.company_id = c.id
INNER JOIN sonar_bank_accounts ba ON ba.id = bt.bank_account_id
LEFT JOIN sonar_accounts actor ON actor.char_id = ?
WHERE c.id = ? AND c.status = 'active' AND ba.closed_at IS NULL AND ba.is_frozen = 0
LIMIT 1
]]

local SQL_CREDIT_SUBSIDY_ACCOUNT = [[
UPDATE sonar_bank_accounts
SET balance = balance + (? / 100.0), updated_at = UNIX_TIMESTAMP()
WHERE id = ? AND closed_at IS NULL AND is_frozen = 0
  AND EXISTS (
    SELECT 1 FROM sonar_bank_subsidy_programs
    WHERE id = ? AND status = 'active' AND disbursed_amount + (? / 100.0) <= budget_amount
  )
]]

local SQL_INSERT_SUBSIDY_MOVEMENT = [[
INSERT INTO sonar_bank_movements
  (bank_account_id, occurred_at, amount, balance_after, category, concept,
   related_doc_id, request_nonce, initiated_by_account_id, source_resource)
SELECT ba.id, UNIX_TIMESTAMP(), (? / 100.0), ba.balance, 'tax_subsidy', ?, ?, ?, ?, 'sonar_bank_app'
FROM sonar_bank_accounts ba
WHERE ba.id = ?
LIMIT 1
]]

local SQL_INSERT_SUBSIDY_CITIZEN = [[
INSERT INTO sonar_bank_subsidies
  (subsidy_kind, program_id, beneficiary_account_id, bank_account_id, company_id,
   amount, currency, issued_by_account_id, issued_by_role, reason_note, reference_period, issued_at)
VALUES (?, ?, ?, ?, NULL, (? / 100.0), 'EUR', ?, 'government', ?, ?, UNIX_TIMESTAMP())
]]

local SQL_INSERT_SUBSIDY_COMPANY = [[
INSERT INTO sonar_bank_subsidies
  (subsidy_kind, program_id, beneficiary_account_id, bank_account_id, company_id,
   amount, currency, issued_by_account_id, issued_by_role, reason_note, reference_period, issued_at)
VALUES (?, ?, ?, ?, ?, (? / 100.0), 'EUR', ?, 'government', ?, ?, UNIX_TIMESTAMP())
]]

local SQL_UPDATE_SUBSIDY_PROGRAM_DISBURSED = [[
UPDATE sonar_bank_subsidy_programs
SET disbursed_amount = disbursed_amount + (? / 100.0),
    beneficiary_count_cached = beneficiary_count_cached + 1,
    updated_at = UNIX_TIMESTAMP()
WHERE id = ? AND status = 'active' AND disbursed_amount + (? / 100.0) <= budget_amount
]]

local SQL_REPORT_REVENUE_HISTORY = [[
SELECT DATE_FORMAT(FROM_UNIXTIME(m.occurred_at), '%Y-%m') AS label,
       CAST(ROUND(SUM(CASE WHEN m.category IN ('tax','fine_collected') THEN ABS(m.amount) ELSE 0 END) * 100) AS SIGNED) AS collected,
       CAST(ROUND(SUM(CASE WHEN m.category = 'tax' THEN ABS(m.amount) ELSE 0 END) * 125) AS SIGNED) AS obligation
FROM sonar_bank_movements m
WHERE m.occurred_at >= UNIX_TIMESTAMP() - ?
  AND m.category IN ('tax','fine_collected')
GROUP BY DATE_FORMAT(FROM_UNIXTIME(m.occurred_at), '%Y-%m')
ORDER BY MIN(m.occurred_at) ASC
LIMIT ?
]]

local SQL_REPORT_REVENUE_PRIOR = [[
SELECT CAST(ROUND(SUM(CASE WHEN m.occurred_at >= UNIX_TIMESTAMP() - ? THEN ABS(m.amount) ELSE 0 END) * 100) AS SIGNED) AS currentRevenue,
       CAST(ROUND(SUM(CASE WHEN m.occurred_at < UNIX_TIMESTAMP() - ? AND m.occurred_at >= UNIX_TIMESTAMP() - (? * 2) THEN ABS(m.amount) ELSE 0 END) * 100) AS SIGNED) AS priorRevenue
FROM sonar_bank_movements m
WHERE m.occurred_at >= UNIX_TIMESTAMP() - (? * 2)
  AND m.category IN ('tax','fine_collected')
]]

local SQL_REPORT_SECTOR_REVENUE = [[
SELECT c.sector,
       CAST(ROUND(SUM(ABS(m.amount)) * 100) AS SIGNED) AS collected,
       COUNT(DISTINCT c.id) AS entityCount
FROM sonar_bank_movements m
INNER JOIN sonar_bank_accounts ba ON ba.id = m.bank_account_id
LEFT JOIN sonar_bank_business_treasuries bt ON bt.bank_account_id = ba.id
INNER JOIN sonar_companies c ON c.id = COALESCE(ba.owner_company_id, bt.company_id)
WHERE m.occurred_at >= UNIX_TIMESTAMP() - ?
  AND m.category = 'tax'
GROUP BY c.sector
ORDER BY collected DESC
LIMIT 12
]]

local SQL_REPORT_TOP_CONTRIBUTORS = [[
SELECT id, label, kind, CAST(ROUND(SUM(tax_major) * 100) AS SIGNED) AS taxPaid, bracketCode, compliance
FROM (
  SELECT sa.char_id AS id,
         COALESCE(sa.alias, sa.char_id) AS label,
         'citizen' AS kind,
         ABS(m.amount) AS tax_major,
         'P' AS bracketCode,
         CASE WHEN COUNT(cf.id) > 0 THEN 'pending' ELSE 'current' END AS compliance
  FROM sonar_bank_movements m
  INNER JOIN sonar_bank_accounts ba ON ba.id = m.bank_account_id
  INNER JOIN sonar_accounts sa ON sa.id = ba.owner_account_id
  LEFT JOIN sonar_bank_compliance_flags cf ON cf.citizen_account_id = sa.id AND cf.status IN ('open','investigating')
  WHERE m.occurred_at >= UNIX_TIMESTAMP() - ? AND m.category = 'tax'
  GROUP BY sa.char_id, sa.alias, m.id, m.amount
  UNION ALL
  SELECT c.id AS id,
         c.name AS label,
         'company' AS kind,
         ABS(m.amount) AS tax_major,
         'C' AS bracketCode,
         CASE WHEN c.status = 'active' THEN 'current' ELSE 'overdue' END AS compliance
  FROM sonar_bank_movements m
  INNER JOIN sonar_bank_accounts ba ON ba.id = m.bank_account_id
  LEFT JOIN sonar_bank_business_treasuries bt ON bt.bank_account_id = ba.id
  INNER JOIN sonar_companies c ON c.id = COALESCE(ba.owner_company_id, bt.company_id)
  WHERE m.occurred_at >= UNIX_TIMESTAMP() - ? AND m.category = 'tax'
) x
GROUP BY id, label, kind, bracketCode, compliance
ORDER BY taxPaid DESC
LIMIT 10
]]

function R.ListCitizens(limit)
  return DB.Query(SQL_LIST_CITIZENS, { limit or 100 })
end

function R.GetAccountByCitizen(cid)
  return DB.QuerySingle(SQL_GET_ACCOUNT_BY_CID, { cid })
end

function R.GetCitizen(cid)
  return DB.QuerySingle(SQL_GET_CITIZEN, { cid })
end

function R.ListCitizenActivity(cid, limit)
  return DB.Query(SQL_LIST_CITIZEN_ACTIVITY, { cid, limit or 20 })
end

function R.ListCitizenFlags(cid, limit)
  return DB.Query(SQL_LIST_CITIZEN_FLAGS, { cid, limit or 20 })
end

function R.GetRiskMetrics(cid)
  local risk = Config.RiskScore
  return DB.QuerySingle(SQL_RISK_METRICS, {
    risk.MEDIUM_WINDOW_SECONDS,
    risk.DAILY_WINDOW_SECONDS,
    cid,
  })
end

function R.UpsertRiskScore(row)
  local risk = Config.RiskScore
  return DB.Execute(SQL_UPSERT_RISK, {
    row.account_uuid, row.score, row.risk_level, row.velocity_score,
    row.compliance_score, row.exposure_score, row.flag_score,
    row.dormancy_score, row.components_json, risk.FORMULA_VERSION,
    row.computed_by or 'system', risk.MATERIALIZED_TTL_SECONDS,
  })
end

function R.InsertFlagIfMissing(row)
  return DB.Execute(SQL_INSERT_FLAG_IF_MISSING, {
    row.flag_type, row.severity, row.account_uuid, row.bank_account_id,
    row.threshold_value, row.observed_value, row.time_window_seconds,
    row.evidence, row.account_uuid, row.flag_type,
  })
end

function R.ListFlagQueue(limit)
  return DB.Query(SQL_LIST_FLAG_QUEUE, { limit or 100 })
end

function R.ListComplianceFlags(filters)
  filters = filters or {}
  local status = filters.status
  if status == 'reviewing' then status = 'investigating' end
  if status == 'dismissed' then status = 'false_positive' end
  if status == 'all' then status = nil end
  local severity = filters.severity
  if severity == 'medium' then severity = 'warning' end
  if severity == 'low' then severity = 'notice' end
  if severity == 'high' or severity == 'critical' then severity = 'critical' end
  if severity == 'all' then severity = nil end
  local query = type(filters.query) == 'string' and filters.query or ''
  local like = ('%%%s%%'):format(query)
  local limit = math.max(1, math.min(tonumber(filters.limit) or 24, 50))
  return DB.Query(SQL_LIST_COMPLIANCE_FLAGS, {
    status, status,
    severity, severity,
    query, like, like, like,
    limit + 1,
  })
end
function R.GetFlag(flag_id)
  return DB.QuerySingle(SQL_GET_FLAG, { tonumber(flag_id) or flag_id })
end

function R.CloseFlag(flag_id, actor_cid, verdict, action_taken, note)
  local status = verdict == 'dismissed' and 'false_positive' or 'resolved'
  return DB.Execute(SQL_CLOSE_FLAG, { status, actor_cid, action_taken, note, tonumber(flag_id) or flag_id })
end

function R.ListAccountsByCitizen(cid)
  return DB.Query(SQL_LIST_ACCOUNTS_BY_CITIZEN, { cid })
end

function R.SetCitizenFrozen(cid, frozen)
  return DB.Execute(SQL_SET_CITIZEN_FROZEN, { frozen and 1 or 0, cid })
end

function R.ListSanctionActions(target_cid, limit)
  return DB.Query(SQL_LIST_SANCTION_ACTIONS, { target_cid, target_cid, limit or 50 })
end

function R.BuildDebitFineQuery(account_id, amount_minor)
  return { query = SQL_DEBIT_FINE, values = { amount_minor, account_id, amount_minor } }
end

function R.BuildInsertFineMovementQuery(account_id, amount_minor, concept, related_doc_id, idempotency_key, actor_account_id)
  return { query = SQL_INSERT_FINE_MOVEMENT, values = { amount_minor, concept, related_doc_id, idempotency_key, actor_account_id, account_id } }
end

function R.ListTreasuryMovements(limit, offset)
  return DB.Query(SQL_TREASURY_MOVEMENTS, { limit or 15, offset or 0 })
end

function R.GetTreasuryStats(range_seconds)
  return DB.QuerySingle(SQL_TREASURY_STATS, { range_seconds or 2592000 })
end

function R.ListSubsidyPrograms(limit)
  return DB.Query(SQL_LIST_SUBSIDY_PROGRAMS, { limit or 100 })
end

function R.GetSubsidyProgram(program_id)
  return DB.QuerySingle(SQL_GET_SUBSIDY_PROGRAM, { program_id, program_id })
end

function R.ListSubsidyDisbursements(program_id, limit)
  return DB.Query(SQL_LIST_SUBSIDY_DISBURSEMENTS, { program_id, limit or 20 })
end

function R.GetSubsidyStats()
  return DB.QuerySingle(SQL_SUBSIDY_STATS, {})
end

function R.GetSubsidyCitizenRecipient(cid)
  return DB.QuerySingle(SQL_GET_SUBSIDY_CITIZEN_RECIPIENT, { cid })
end

function R.GetSubsidyCompanyRecipient(actor_cid, company_id)
  return DB.QuerySingle(SQL_GET_SUBSIDY_COMPANY_RECIPIENT, { actor_cid, company_id })
end

function R.BuildGrantSubsidyQueries(params)
  local insert_subsidy
  if params.company_id then
    insert_subsidy = {
      query = SQL_INSERT_SUBSIDY_COMPANY,
      values = {
        params.subsidy_kind,
        params.program_id,
        params.beneficiary_account_id,
        params.bank_account_id,
        params.company_id,
        params.amount_minor,
        params.actor_account_id,
        params.note,
        params.reference_period,
      },
    }
  else
    insert_subsidy = {
      query = SQL_INSERT_SUBSIDY_CITIZEN,
      values = {
        params.subsidy_kind,
        params.program_id,
        params.beneficiary_account_id,
        params.bank_account_id,
        params.amount_minor,
        params.actor_account_id,
        params.note,
        params.reference_period,
      },
    }
  end
  return {
    { query = SQL_CREDIT_SUBSIDY_ACCOUNT, values = { params.amount_minor, params.bank_account_id, params.program_id, params.amount_minor } },
    { query = SQL_UPDATE_SUBSIDY_PROGRAM_DISBURSED, values = { params.amount_minor, params.program_id, params.amount_minor } },
    { query = SQL_INSERT_SUBSIDY_MOVEMENT, values = {
      params.amount_minor,
      params.note,
      params.idempotency_key,
      params.idempotency_key,
      params.actor_account_id,
      params.bank_account_id,
    } },
    insert_subsidy,
  }
end

function R.GetReportRevenueHistory(range_seconds, limit)
  return DB.Query(SQL_REPORT_REVENUE_HISTORY, { range_seconds, limit or 12 })
end

function R.GetReportRevenuePrior(range_seconds)
  return DB.QuerySingle(SQL_REPORT_REVENUE_PRIOR, { range_seconds, range_seconds, range_seconds, range_seconds })
end

function R.GetReportSectorRevenue(range_seconds)
  return DB.Query(SQL_REPORT_SECTOR_REVENUE, { range_seconds })
end

function R.GetReportTopContributors(range_seconds)
  return DB.Query(SQL_REPORT_TOP_CONTRIBUTORS, { range_seconds, range_seconds })
end

return R
