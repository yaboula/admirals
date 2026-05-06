-- =============================================================================
-- SONAR Bank App — repos/cards.lua
-- =============================================================================
-- Virtual cards DAO.
--
-- Schema (sonar_core migration 018 bank_cards):
--   card_id          BIGINT PK AUTO_INCREMENT
--   owner_citizen_id VARCHAR(64) NOT NULL
--   account_iban     VARCHAR(34) NOT NULL  (FK bank_accounts)
--   masked_number    VARCHAR(19) NOT NULL  (e.g. '**** **** **** 4242')
--   pin_hash         VARCHAR(64) NULL  (HMAC-SHA256 of PIN — never plaintext)
--   status           ENUM('active','frozen','expired','revoked')
--   spend_limit_minor BIGINT NULL  (per-day cap)
--   created_at, updated_at TIMESTAMP(6)
-- =============================================================================

BankApp.repos.cards = {}
local R = BankApp.repos.cards

local DB = BankApp.lib.db

local SQL_LIST = [[
SELECT card_id, account_iban, masked_number, status, spend_limit_minor,
       UNIX_TIMESTAMP(created_at)*1000 AS created_ms
FROM bank_cards
WHERE owner_citizen_id = ? AND status IN ('active','frozen')
ORDER BY created_at DESC
LIMIT ?
]]

local SQL_GET = [[
SELECT card_id, owner_citizen_id, account_iban, masked_number, pin_hash,
       status, spend_limit_minor
FROM bank_cards
WHERE card_id = ?
LIMIT 1
]]

local SQL_INSERT = [[
INSERT INTO bank_cards
  (owner_citizen_id, account_iban, masked_number, pin_hash, status, spend_limit_minor)
VALUES (?, ?, ?, ?, 'active', ?)
]]

local SQL_SET_STATUS = [[
UPDATE bank_cards
SET status = ?, updated_at = CURRENT_TIMESTAMP(6)
WHERE card_id = ? AND owner_citizen_id = ?
]]

local SQL_SET_PIN = [[
UPDATE bank_cards
SET pin_hash = ?, updated_at = CURRENT_TIMESTAMP(6)
WHERE card_id = ? AND owner_citizen_id = ?
]]

function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST, { citizen_id, limit or 8 })
end

function R.GetById(card_id)
  return DB.QuerySingle(SQL_GET, { card_id })
end

function R.Insert(t)
  return DB.Insert(SQL_INSERT, {
    t.owner_citizen_id, t.account_iban, t.masked_number,
    t.pin_hash, t.spend_limit_minor,
  })
end

function R.SetStatus(card_id, owner_citizen_id, status)
  return DB.Execute(SQL_SET_STATUS, { status, card_id, owner_citizen_id })
end

function R.SetPinHash(card_id, owner_citizen_id, pin_hash)
  return DB.Execute(SQL_SET_PIN, { pin_hash, card_id, owner_citizen_id })
end

--- BuildSnapshotQuery — REQ-FE-001 bootstrap parallel.
function R.BuildSnapshotQuery(citizen_id, limit)
  return {
    sql    = SQL_LIST,
    params = { citizen_id, limit or 8 },
    kind   = 'query',
  }
end

return R
