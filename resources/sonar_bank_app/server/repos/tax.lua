BankApp.repos.tax = {}
local R = BankApp.repos.tax

local DB = BankApp.lib.db

local SQL_GET_ACTOR_ACCOUNT = [[
SELECT id, char_id, alias
FROM sonar_accounts
WHERE char_id = ?
LIMIT 1
]]

local SQL_LIST_ACTIVE_BRACKETS = [[
SELECT id,
       bracket_name,
       bracket_kind,
       CAST(ROUND(income_min * 100) AS SIGNED) AS incomeMin,
       CASE WHEN income_max IS NULL THEN NULL ELSE CAST(ROUND(income_max * 100) AS SIGNED) END AS incomeMax,
       rate_pct AS rate,
       effective_from,
       effective_until
FROM sonar_bank_tax_brackets
WHERE bracket_kind = 'income_personal' AND effective_until IS NULL
ORDER BY income_min ASC, id ASC
]]

local SQL_LIST_HISTORY = [[
SELECT h.id,
       h.bracket_id,
       h.actor_account_id,
       COALESCE(sa.alias, sa.char_id, 'government') AS operatorAlias,
       h.changed_at * 1000 AS changedAt,
       h.before_bracket_name,
       h.before_rate_pct,
       h.after_bracket_name,
       h.after_rate_pct,
       h.reason_note
FROM sonar_bank_tax_history h
LEFT JOIN sonar_accounts sa ON sa.id = h.actor_account_id
ORDER BY h.changed_at DESC, h.id DESC
LIMIT ?
]]

local SQL_CYCLE_DAILY = [[
SELECT day_index AS dayIndex,
       CAST(ROUND(SUM(collected_major) * 100) AS SIGNED) AS collectedCents
FROM (
  SELECT FLOOR((UNIX_TIMESTAMP() - occurred_at) / 86400) AS day_index,
         ABS(amount) AS collected_major
  FROM sonar_bank_movements
  WHERE category = 'tax' AND occurred_at >= UNIX_TIMESTAMP() - (? * 86400)
) t
GROUP BY day_index
ORDER BY day_index ASC
]]

local SQL_UPDATE_BRACKET = [[
UPDATE sonar_bank_tax_brackets
SET rate_pct = ?, updated_by_account_id = ?, updated_at = UNIX_TIMESTAMP()
WHERE id = ? AND effective_until IS NULL
]]

local SQL_INSERT_BRACKET = [[
INSERT INTO sonar_bank_tax_brackets (
  bracket_name, bracket_kind, income_min, income_max, rate_pct, created_by_account_id, updated_by_account_id
) VALUES (?, 'income_personal', ?, ?, ?, ?, ?)
]]

local SQL_INSERT_HISTORY_VALUES = [[
INSERT INTO sonar_bank_tax_history (
  bracket_id, change_type, actor_account_id, actor_role,
  before_bracket_name, before_bracket_kind, before_income_min, before_income_max, before_rate_pct,
  after_bracket_name, after_bracket_kind, after_income_min, after_income_max, after_rate_pct,
  reason_note
) VALUES (?, ?, ?, 'government', ?, 'income_personal', ?, ?, ?, ?, 'income_personal', ?, ?, ?, ?)
]]

local SQL_INSERT_HISTORY_FOR_NEW = [[
INSERT INTO sonar_bank_tax_history (
  bracket_id, change_type, actor_account_id, actor_role,
  after_bracket_name, after_bracket_kind, after_income_min, after_income_max, after_rate_pct,
  reason_note
)
SELECT id, 'create', ?, 'government', bracket_name, bracket_kind, income_min, income_max, rate_pct, ?
FROM sonar_bank_tax_brackets
WHERE bracket_name = ? AND bracket_kind = 'income_personal' AND effective_until IS NULL
ORDER BY id DESC
LIMIT 1
]]

function R.GetActorAccount(citizen_id)
  return DB.QuerySingle(SQL_GET_ACTOR_ACCOUNT, { citizen_id })
end

function R.ListActiveBrackets()
  return DB.Query(SQL_LIST_ACTIVE_BRACKETS, {})
end

function R.ListPolicyHistory(limit)
  return DB.Query(SQL_LIST_HISTORY, { limit or 25 })
end

function R.GetCycleDaily(duration_days)
  return DB.Query(SQL_CYCLE_DAILY, { duration_days or 14 })
end

function R.BuildUpdateBracketQuery(row, new_rate, actor_account_id, reason)
  return {
    { query = SQL_INSERT_HISTORY_VALUES, values = {
      row.id,
      'update',
      actor_account_id,
      row.bracket_name,
      (tonumber(row.incomeMin) or 0) / 100,
      row.incomeMax and ((tonumber(row.incomeMax) or 0) / 100) or nil,
      tonumber(row.rate) or 0,
      row.bracket_name,
      (tonumber(row.incomeMin) or 0) / 100,
      row.incomeMax and ((tonumber(row.incomeMax) or 0) / 100) or nil,
      new_rate,
      reason,
    } },
    { query = SQL_UPDATE_BRACKET, values = { new_rate, actor_account_id, row.id } },
  }
end

function R.BuildInsertBracketQueries(definition, new_rate, actor_account_id, reason)
  return {
    { query = SQL_INSERT_BRACKET, values = {
      definition.name,
      definition.income_min / 100,
      definition.income_max and (definition.income_max / 100) or nil,
      new_rate,
      actor_account_id,
      actor_account_id,
    } },
    { query = SQL_INSERT_HISTORY_FOR_NEW, values = { actor_account_id, reason, definition.name } },
  }
end

function R.ApplyBracketQueries(queries)
  return DB.Transaction(queries)
end

return R
