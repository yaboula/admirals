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

-- -----------------------------------------------------------------------------
-- §1. SELECT
-- -----------------------------------------------------------------------------

local SQL_SELECT_BY_IBAN = [[
SELECT account_id, iban, owner_citizen_id, joint_owners,
       balance_minor, savings_minor, status, frozen_flag,
       UNIX_TIMESTAMP(created_at)*1000 AS created_ms,
       UNIX_TIMESTAMP(updated_at)*1000 AS updated_ms
FROM bank_accounts
WHERE iban = ?
LIMIT 1
]]

local SQL_SELECT_BY_ID = [[
SELECT account_id, iban, owner_citizen_id, joint_owners,
       balance_minor, savings_minor, status, frozen_flag,
       UNIX_TIMESTAMP(created_at)*1000 AS created_ms,
       UNIX_TIMESTAMP(updated_at)*1000 AS updated_ms
FROM bank_accounts
WHERE account_id = ?
LIMIT 1
]]

local SQL_LIST_BY_CITIZEN = [[
SELECT account_id, iban, owner_citizen_id, joint_owners,
       balance_minor, savings_minor, status, frozen_flag,
       UNIX_TIMESTAMP(created_at)*1000 AS created_ms
FROM bank_accounts
WHERE (owner_citizen_id = ?
       OR JSON_CONTAINS(IFNULL(joint_owners, JSON_ARRAY()), JSON_QUOTE(?), '$'))
  AND status IN ('active','frozen')
ORDER BY created_at ASC
LIMIT ?
]]

local SQL_GET_BALANCE = [[
SELECT balance_minor, savings_minor FROM bank_accounts WHERE iban = ? LIMIT 1
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
  return DB.Query(SQL_LIST_BY_CITIZEN, { citizen_id, citizen_id, limit or 32 })
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
INSERT INTO bank_accounts
  (iban, owner_citizen_id, joint_owners, balance_minor, savings_minor, status, frozen_flag)
VALUES (?, ?, ?, ?, ?, 'active', 0)
]]

--- Insert — returns insert_id.
---@param iban string
---@param owner_citizen_id string
---@param opts table|nil { joint_owners=table, initial_balance=integer, initial_savings=integer }
---@return integer|nil account_id, table|nil err
function R.Insert(iban, owner_citizen_id, opts)
  opts = opts or {}
  local joint_json = nil
  if opts.joint_owners and #opts.joint_owners > 0 and json and json.encode then
    joint_json = json.encode(opts.joint_owners)
  end
  return DB.Insert(SQL_INSERT, {
    iban,
    owner_citizen_id,
    joint_json,
    opts.initial_balance or 0,
    opts.initial_savings or 0,
  })
end

-- -----------------------------------------------------------------------------
-- §3. UPDATE — balance / savings (TX context)
--
--   These return TX query descriptors for use within DB.Transaction batch —
--   service layer composes the batch atomically.
-- -----------------------------------------------------------------------------

local SQL_DEBIT_BALANCE = [[
UPDATE bank_accounts
SET balance_minor = balance_minor - ?, updated_at = CURRENT_TIMESTAMP(6)
WHERE iban = ? AND balance_minor >= ? AND status = 'active' AND frozen_flag = 0
]]

local SQL_CREDIT_BALANCE = [[
UPDATE bank_accounts
SET balance_minor = balance_minor + ?, updated_at = CURRENT_TIMESTAMP(6)
WHERE iban = ? AND status IN ('active','frozen')
]]

local SQL_DEBIT_SAVINGS = [[
UPDATE bank_accounts
SET savings_minor = savings_minor - ?, updated_at = CURRENT_TIMESTAMP(6)
WHERE iban = ? AND savings_minor >= ? AND status = 'active' AND frozen_flag = 0
]]

local SQL_CREDIT_SAVINGS = [[
UPDATE bank_accounts
SET savings_minor = savings_minor + ?, updated_at = CURRENT_TIMESTAMP(6)
WHERE iban = ? AND status IN ('active','frozen')
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
UPDATE bank_accounts SET status = ?, updated_at = CURRENT_TIMESTAMP(6) WHERE iban = ?
]]

local SQL_SET_FROZEN = [[
UPDATE bank_accounts SET frozen_flag = ?, updated_at = CURRENT_TIMESTAMP(6) WHERE iban = ?
]]

local SQL_ADD_JOINT = [[
UPDATE bank_accounts
SET joint_owners = JSON_ARRAY_APPEND(IFNULL(joint_owners, JSON_ARRAY()), '$', JSON_QUOTE(?)),
    updated_at = CURRENT_TIMESTAMP(6)
WHERE iban = ? AND owner_citizen_id <> ?
]]

local SQL_REMOVE_JOINT = [[
UPDATE bank_accounts
SET joint_owners = JSON_REMOVE(joint_owners,
       JSON_UNQUOTE(JSON_SEARCH(IFNULL(joint_owners, JSON_ARRAY()), 'one', ?))),
    updated_at = CURRENT_TIMESTAMP(6)
WHERE iban = ?
]]

function R.SetStatus(iban, status)
  return DB.Execute(SQL_SET_STATUS, { status, iban })
end

function R.SetFrozenFlag(iban, frozen_bool)
  return DB.Execute(SQL_SET_FROZEN, { frozen_bool and 1 or 0, iban })
end

function R.AddJointOwner(iban, citizen_id, primary_owner_citizen_id)
  return DB.Execute(SQL_ADD_JOINT, { citizen_id, iban, primary_owner_citizen_id })
end

function R.RemoveJointOwner(iban, citizen_id)
  return DB.Execute(SQL_REMOVE_JOINT, { citizen_id, iban })
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
    params = { citizen_id, citizen_id, 32 },
    kind   = 'query',
  }
end

return R
