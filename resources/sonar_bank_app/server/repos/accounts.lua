-- =============================================================================
-- SONAR Bank App — repos/accounts.lua
-- =============================================================================
-- Account DAO. Pure SQL — no business logic, no FSM transitions, no audit emit.
-- Services orchestrate transitions + side effects.
--
-- Schema (sonar_core migration 010 bank_accounts):
--   account_id        BIGINT PK AUTO_INCREMENT
--   iban              VARCHAR(34) UNIQUE NOT NULL
--   owner_citizen_id  VARCHAR(64) NOT NULL
--   joint_owners      JSON NULL  (array of citizen_id)
--   balance_minor     BIGINT DEFAULT 0
--   savings_minor     BIGINT DEFAULT 0
--   status            ENUM('pending','active','frozen','closed','archived')
--   frozen_flag       TINYINT(1) DEFAULT 0
--   created_at, updated_at TIMESTAMP(6)
-- =============================================================================

BankApp.repos.accounts = {}
local R = BankApp.repos.accounts

local DB = BankApp.lib.db
local Errors = BankApp.lib.errors
local UUID = BankApp.lib.uuid

-- -----------------------------------------------------------------------------
-- §1. SELECT
-- -----------------------------------------------------------------------------

local SQL_SELECT_BY_IBAN = [[
SELECT a.id AS account_id, a.iban, a.owner_type, a.account_class, sa.char_id AS owner_citizen_id,
       COALESCE(
         (SELECT JSON_ARRAYAGG(j.joint_citizen_id)
          FROM sonar_bank_account_joints j
          WHERE j.account_id = a.id),
         JSON_ARRAY()
       ) AS joint_owners,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       CAST(ROUND(COALESCE(a.savings, 0) * 100) AS SIGNED) AS savings_minor,
       CASE
         WHEN a.closed_at IS NOT NULL THEN 'closed'
         WHEN a.is_frozen = 1 THEN 'frozen'
         ELSE 'active'
       END AS status,
       a.is_frozen AS frozen_flag,
       a.created_at * 1000 AS created_ms,
       a.updated_at * 1000 AS updated_ms
FROM sonar_bank_accounts a
LEFT JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE a.iban = ?
LIMIT 1
]]

local SQL_SELECT_BY_ID = [[
SELECT a.id AS account_id, a.iban, a.owner_type, a.account_class, sa.char_id AS owner_citizen_id,
       COALESCE(
         (SELECT JSON_ARRAYAGG(j.joint_citizen_id)
          FROM sonar_bank_account_joints j
          WHERE j.account_id = a.id),
         JSON_ARRAY()
       ) AS joint_owners,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       CAST(ROUND(COALESCE(a.savings, 0) * 100) AS SIGNED) AS savings_minor,
       CASE
         WHEN a.closed_at IS NOT NULL THEN 'closed'
         WHEN a.is_frozen = 1 THEN 'frozen'
         ELSE 'active'
       END AS status,
       a.is_frozen AS frozen_flag,
       a.created_at * 1000 AS created_ms,
       a.updated_at * 1000 AS updated_ms
FROM sonar_bank_accounts a
LEFT JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE a.id = ?
LIMIT 1
]]

local SQL_LIST_BY_CITIZEN = [[
SELECT a.id AS account_id, a.iban, a.owner_type, a.account_class, sa.char_id AS owner_citizen_id,
       COALESCE(
         (SELECT JSON_ARRAYAGG(j.joint_citizen_id)
          FROM sonar_bank_account_joints j
          WHERE j.account_id = a.id),
         JSON_ARRAY()
       ) AS joint_owners,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       CAST(ROUND(COALESCE(a.savings, 0) * 100) AS SIGNED) AS savings_minor,
       CASE WHEN a.is_frozen = 1 THEN 'frozen' ELSE 'active' END AS status,
       a.is_frozen AS frozen_flag,
       a.created_at * 1000 AS created_ms
FROM sonar_bank_accounts a
INNER JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE sa.char_id = ?
  AND a.closed_at IS NULL
ORDER BY a.created_at ASC
LIMIT ?
]]

local SQL_GET_BALANCE = [[
SELECT CAST(ROUND(balance * 100) AS SIGNED) AS balance_minor, CAST(ROUND(COALESCE(savings, 0) * 100) AS SIGNED) AS savings_minor
FROM sonar_bank_accounts
WHERE iban = ?
LIMIT 1
]]

--- GetByIban
---@param iban string
---@return table|nil row, table|nil err
function R.GetByIban(iban)
  return DB.QuerySingle(SQL_SELECT_BY_IBAN, { iban })
end

--- GetById
function R.GetById(account_id)
  return DB.QuerySingle(SQL_SELECT_BY_ID, { account_id })
end

--- ListByCitizen — owner OR joint owner of active/frozen accounts.
---@param citizen_id string
---@param limit integer max rows (defensive)
---@return table|nil rows, table|nil err
function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST_BY_CITIZEN, { citizen_id, limit or 32 })
end

--- GetBalance — fast path (REQ-FE-001 fallback C001b).
---@param iban string
---@return table|nil { balance_minor, savings_minor }, table|nil err
function R.GetBalance(iban)
  return DB.QuerySingle(SQL_GET_BALANCE, { iban })
end

-- -----------------------------------------------------------------------------
-- §2. INSERT
-- -----------------------------------------------------------------------------

local SQL_INSERT = [[
INSERT INTO sonar_bank_accounts
  (id, iban, owner_type, account_class, owner_account_id, owner_company_id,
   balance, savings, is_frozen, created_at, updated_at)
VALUES (?, ?, ?, ?, ?, NULL, (? / 100.0), (? / 100.0), 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
]]

local SQL_SELECT_OWNER_ACCOUNT_ID = [[
SELECT id
FROM sonar_accounts
WHERE char_id = ?
ORDER BY updated_at DESC
LIMIT 1
]]

local SQL_SELECT_EXISTING_BY_CLASS = [[
SELECT a.id, a.iban
FROM sonar_bank_accounts a
INNER JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE sa.char_id = ?
  AND a.owner_type = ?
  AND a.account_class = ?
  AND a.closed_at IS NULL
LIMIT 1
]]

local SQL_SELECT_PENDING_PROFESSIONAL_APPROVAL = [[
SELECT id AS approval_id, citizen_id, account_class, state, note, requested_at * 1000 AS requested_ms
FROM sonar_bank_account_approvals
WHERE citizen_id = ? AND account_class = 'business_treasury' AND state = 'pending'
ORDER BY requested_at DESC
LIMIT 1
]]

local SQL_LIST_PROFESSIONAL_APPROVALS = [[
SELECT id AS approval_id, citizen_id, account_class, state, note, decision_note, decided_by_citizen_id,
       created_account_id, created_iban, requested_at * 1000 AS requested_ms, decided_at * 1000 AS decided_ms
FROM sonar_bank_account_approvals
WHERE state = 'pending'
ORDER BY requested_at ASC
LIMIT ?
]]

local SQL_GET_PROFESSIONAL_APPROVAL = [[
SELECT id AS approval_id, citizen_id, account_class, state, note, decision_note, decided_by_citizen_id,
       created_account_id, created_iban, requested_at * 1000 AS requested_ms, decided_at * 1000 AS decided_ms
FROM sonar_bank_account_approvals
WHERE id = ?
LIMIT 1
]]

local SQL_INSERT_PROFESSIONAL_APPROVAL = [[
INSERT INTO sonar_bank_account_approvals
  (id, citizen_id, account_class, state, note, requested_at)
VALUES (?, ?, 'business_treasury', 'pending', ?, UNIX_TIMESTAMP())
]]

local SQL_DECIDE_PROFESSIONAL_APPROVAL = [[
UPDATE sonar_bank_account_approvals
SET state = ?, decision_note = ?, decided_by_citizen_id = ?, created_account_id = ?, created_iban = ?, decided_at = UNIX_TIMESTAMP()
WHERE id = ? AND state = 'pending'
]]

--- Insert — returns insert_id.
---@param iban string
---@param owner_citizen_id string
---@param opts table|nil { joint_owners=table, initial_balance=integer, initial_savings=integer }
---@return integer|nil account_id, table|nil err
function R.Insert(iban, owner_citizen_id, opts)
  opts = opts or {}
  local owner, owner_err = DB.QuerySingle(SQL_SELECT_OWNER_ACCOUNT_ID, { owner_citizen_id })
  if owner_err then return nil, owner_err end
  if not owner or not owner.id then
    return nil, Errors.New('ACCOUNT_NOT_FOUND', { reason = 'owner sonar account not found', citizen_id = owner_citizen_id })
  end
  local owner_type = opts.owner_type or 'personal'
  local account_class = opts.account_class or 'checking'
  local existing, existing_err = DB.QuerySingle(SQL_SELECT_EXISTING_BY_CLASS, { owner_citizen_id, owner_type, account_class })
  if existing_err then return nil, existing_err end
  if existing and existing.id then
    return nil, Errors.New('VALIDATION_FAILED', { reason = 'account class already exists for citizen', owner_type = owner_type, account_class = account_class, iban = existing.iban })
  end
  local account_id = UUID.V4()
  local _, err = DB.Execute(SQL_INSERT, {
    account_id,
    iban,
    owner_type,
    account_class,
    owner.id,
    opts.initial_balance or 0,
    opts.initial_savings or 0,
  })
  if err then return nil, err end
  return account_id, nil
end

function R.GetActiveByClass(owner_citizen_id, owner_type, account_class)
  return DB.QuerySingle(SQL_SELECT_EXISTING_BY_CLASS, { owner_citizen_id, owner_type or 'personal', account_class })
end

function R.GetPendingProfessionalApproval(citizen_id)
  return DB.QuerySingle(SQL_SELECT_PENDING_PROFESSIONAL_APPROVAL, { citizen_id })
end

function R.ListProfessionalApprovals(limit)
  return DB.Query(SQL_LIST_PROFESSIONAL_APPROVALS, { limit or 50 })
end

function R.GetProfessionalApproval(approval_id)
  return DB.QuerySingle(SQL_GET_PROFESSIONAL_APPROVAL, { approval_id })
end

function R.CreateProfessionalApproval(citizen_id, note)
  local approval_id = UUID.V4()
  local _, err = DB.Execute(SQL_INSERT_PROFESSIONAL_APPROVAL, { approval_id, citizen_id, note })
  if err then return nil, err end
  return approval_id, nil
end

function R.DecideProfessionalApproval(params)
  return DB.Execute(SQL_DECIDE_PROFESSIONAL_APPROVAL, {
    params.state,
    params.decision_note,
    params.decided_by_citizen_id,
    params.created_account_id,
    params.created_iban,
    params.approval_id,
  })
end

-- -----------------------------------------------------------------------------
-- §3. UPDATE — balance / savings (TX context)
--
--   These return TX query descriptors for use within DB.Transaction batch —
--   service layer composes the batch atomically.
-- -----------------------------------------------------------------------------

local SQL_DEBIT_BALANCE = [[
UPDATE sonar_bank_accounts
SET balance = balance - (? / 100.0), updated_at = UNIX_TIMESTAMP()
WHERE iban = ? AND balance >= (? / 100.0) AND closed_at IS NULL AND is_frozen = 0
]]

local SQL_CREDIT_BALANCE = [[
UPDATE sonar_bank_accounts
SET balance = balance + (? / 100.0), updated_at = UNIX_TIMESTAMP()
WHERE iban = ? AND closed_at IS NULL
]]

local SQL_DEBIT_SAVINGS = [[
UPDATE sonar_bank_accounts
SET savings = savings - (? / 100.0), updated_at = UNIX_TIMESTAMP()
WHERE iban = ? AND savings >= (? / 100.0) AND closed_at IS NULL AND is_frozen = 0
]]

local SQL_CREDIT_SAVINGS = [[
UPDATE sonar_bank_accounts
SET savings = savings + (? / 100.0), updated_at = UNIX_TIMESTAMP()
WHERE iban = ? AND closed_at IS NULL AND is_frozen = 0
]]

--- BuildDebitBalanceQuery — TX descriptor (caller composes batch).
---@param iban string
---@param amount_minor integer
---@return table { query, values }
function R.BuildDebitBalanceQuery(iban, amount_minor)
  return { query = SQL_DEBIT_BALANCE, values = { amount_minor, iban, amount_minor } }
end

--- BuildCreditBalanceQuery
function R.BuildCreditBalanceQuery(iban, amount_minor)
  return { query = SQL_CREDIT_BALANCE, values = { amount_minor, iban } }
end

--- BuildDebitSavingsQuery
function R.BuildDebitSavingsQuery(iban, amount_minor)
  return { query = SQL_DEBIT_SAVINGS, values = { amount_minor, iban, amount_minor } }
end

--- BuildCreditSavingsQuery
function R.BuildCreditSavingsQuery(iban, amount_minor)
  return { query = SQL_CREDIT_SAVINGS, values = { amount_minor, iban } }
end

-- -----------------------------------------------------------------------------
-- §4. UPDATE — status / freeze (single statements, used outside TX)
-- -----------------------------------------------------------------------------

local SQL_SET_STATUS = [[
UPDATE sonar_bank_accounts
SET closed_at = CASE WHEN ? = 'closed' THEN UNIX_TIMESTAMP() ELSE NULL END,
    is_frozen = CASE WHEN ? = 'frozen' THEN 1 WHEN ? = 'active' THEN 0 ELSE is_frozen END,
    updated_at = UNIX_TIMESTAMP()
WHERE iban = ?
]]

local SQL_SET_FROZEN = [[
UPDATE sonar_bank_accounts
SET is_frozen = ?, updated_at = UNIX_TIMESTAMP()
WHERE iban = ?
]]

function R.SetStatus(iban, status)
  return DB.Execute(SQL_SET_STATUS, { status, status, status, iban })
end

function R.SetFrozenFlag(iban, frozen_bool)
  return DB.Execute(SQL_SET_FROZEN, { frozen_bool and 1 or 0, iban })
end

-- Joint owners (canonical table sonar_bank_account_joints, mig 039)

local SQL_INSERT_JOINT = [[
INSERT INTO sonar_bank_account_joints
  (account_id, joint_citizen_id, added_by_citizen_id, added_at)
SELECT a.id, ?, ?, UNIX_TIMESTAMP()
FROM sonar_bank_accounts a
WHERE a.iban = ?
LIMIT 1
]]

local SQL_DELETE_JOINT = [[
DELETE j
FROM sonar_bank_account_joints j
INNER JOIN sonar_bank_accounts a ON a.id = j.account_id
WHERE a.iban = ? AND j.joint_citizen_id = ?
]]

local SQL_LIST_JOINTS_FOR_IBAN = [[
SELECT j.joint_citizen_id, j.added_by_citizen_id, j.added_at
FROM sonar_bank_account_joints j
INNER JOIN sonar_bank_accounts a ON a.id = j.account_id
WHERE a.iban = ?
ORDER BY j.added_at ASC
]]

local SQL_COUNT_JOINTS_FOR_IBAN = [[
SELECT COUNT(*) AS n
FROM sonar_bank_account_joints j
INNER JOIN sonar_bank_accounts a ON a.id = j.account_id
WHERE a.iban = ?
]]

local SQL_CITIZEN_EXISTS = [[
SELECT 1 AS ok FROM sonar_accounts WHERE char_id = ? LIMIT 1
]]

function R.AddJointOwner(iban, joint_citizen_id, primary_owner_citizen_id)
  return DB.Execute(SQL_INSERT_JOINT, { joint_citizen_id, primary_owner_citizen_id, iban })
end

function R.RemoveJointOwner(iban, joint_citizen_id)
  return DB.Execute(SQL_DELETE_JOINT, { iban, joint_citizen_id })
end

function R.ListJointOwners(iban)
  return DB.Query(SQL_LIST_JOINTS_FOR_IBAN, { iban })
end

function R.CountJointOwners(iban)
  local row, err = DB.QuerySingle(SQL_COUNT_JOINTS_FOR_IBAN, { iban })
  if err then return nil, err end
  return tonumber(row and row.n) or 0, nil
end

function R.CitizenExists(citizen_id)
  local row, err = DB.QuerySingle(SQL_CITIZEN_EXISTS, { citizen_id })
  if err then return false, err end
  return row ~= nil and row.ok == 1, nil
end

-- -----------------------------------------------------------------------------
-- §5. Snapshot helpers (REQ-FE-001 bootstrap parallel reads)
-- -----------------------------------------------------------------------------

--- BuildSnapshotQuery — returns { sql, params, kind } shape para DB.Parallel.
---@param citizen_id string
---@return table
function R.BuildSnapshotQuery(citizen_id)
  return {
    sql    = SQL_LIST_BY_CITIZEN,
    params = { citizen_id, 32 },
    kind   = 'query',
  }
end

return R
