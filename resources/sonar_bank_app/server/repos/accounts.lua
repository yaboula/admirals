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
SELECT a.id AS account_id, a.iban, sa.char_id AS owner_citizen_id,
       JSON_ARRAY() AS joint_owners,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       0 AS savings_minor,
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
SELECT a.id AS account_id, a.iban, sa.char_id AS owner_citizen_id,
       JSON_ARRAY() AS joint_owners,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       0 AS savings_minor,
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
SELECT a.id AS account_id, a.iban, sa.char_id AS owner_citizen_id,
       JSON_ARRAY() AS joint_owners,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       0 AS savings_minor,
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
SELECT CAST(ROUND(balance * 100) AS SIGNED) AS balance_minor, 0 AS savings_minor
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
   balance, is_frozen, created_at, updated_at)
VALUES (?, ?, ?, ?, ?, NULL, (? / 100.0), 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
]]

local SQL_SELECT_OWNER_ACCOUNT_ID = [[
SELECT id
FROM sonar_accounts
WHERE char_id = ?
ORDER BY updated_at DESC
LIMIT 1
]]

--- Insert — returns insert_id.
---@param iban string
---@param owner_citizen_id string
---@param opts table|nil { joint_owners=table, initial_balance=integer, initial_savings=integer }
---@return integer|nil account_id, table|nil err
function R.Insert(iban, owner_citizen_id, opts)
  opts = opts or {}
  if (tonumber(opts.initial_savings) or 0) > 0 then
    return nil, Errors.New('VALIDATION_FAILED', { reason = 'canonical savings account not available' })
  end
  local owner, owner_err = DB.QuerySingle(SQL_SELECT_OWNER_ACCOUNT_ID, { owner_citizen_id })
  if owner_err then return nil, owner_err end
  if not owner or not owner.id then
    return nil, Errors.New('ACCOUNT_NOT_FOUND', { reason = 'owner sonar account not found', citizen_id = owner_citizen_id })
  end
  local account_id = UUID.V4()
  local _, err = DB.Execute(SQL_INSERT, {
    account_id,
    iban,
    opts.owner_type or 'personal',
    opts.account_class or 'checking',
    owner.id,
    opts.initial_balance or 0,
  })
  if err then return nil, err end
  return account_id, nil
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
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'canonical savings account unavailable'
]]

local SQL_CREDIT_SAVINGS = [[
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'canonical savings account unavailable'
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
  return { query = SQL_DEBIT_SAVINGS, values = {} }
end

--- BuildCreditSavingsQuery
function R.BuildCreditSavingsQuery(iban, amount_minor)
  return { query = SQL_CREDIT_SAVINGS, values = {} }
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

function R.AddJointOwner(iban, citizen_id, primary_owner_citizen_id)
  return nil, Errors.New('VALIDATION_FAILED', { reason = 'canonical joint owner table not available' })
end

function R.RemoveJointOwner(iban, citizen_id)
  return nil, Errors.New('VALIDATION_FAILED', { reason = 'canonical joint owner table not available' })
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
