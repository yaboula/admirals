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
local UUID = BankApp.lib.uuid

local function token64()
  return (UUID.V4():gsub('%-', '') .. UUID.V4():gsub('%-', '')):sub(1, 64)
end

local SQL_LIST = [[
SELECT c.id AS card_id, sa.char_id AS owner_citizen_id, ba.iban AS iban,
       c.last_4_digits AS pan_last_four,
       CASE WHEN c.state = 'frozen' THEN 'locked' WHEN c.state = 'lost' THEN 'revoked' ELSE c.state END AS status,
       c.issued_at * 1000 AS created_ms,
       (c.issued_at + 4 * 365 * 24 * 3600) * 1000 AS expiry_ms,
       c.card_kind AS card_type,
       'sonar_signature' AS design_id,
       'SONAR Cardholder' AS holder_name,
       CAST(ROUND(COALESCE(c.daily_limit, 0) * 100) AS SIGNED) AS daily_limit_minor,
       CAST(ROUND(COALESCE(c.daily_used_today, 0) * 100) AS SIGNED) AS daily_spent_minor,
       CAST(ROUND(COALESCE(c.monthly_limit, 0) * 100) AS SIGNED) AS monthly_limit_minor,
       CAST(ROUND(COALESCE(c.monthly_used, 0) * 100) AS SIGNED) AS monthly_spent_minor
FROM sonar_bank_physical_cards c
INNER JOIN sonar_accounts sa ON sa.id = c.holder_account_id
INNER JOIN sonar_bank_accounts ba ON ba.id = c.bank_account_id
WHERE sa.char_id = ? AND c.state IN ('active','frozen')
ORDER BY c.issued_at DESC
LIMIT ?
]]

local SQL_GET = [[
SELECT c.id AS card_id, sa.char_id AS owner_citizen_id, ba.iban AS account_iban,
       CONCAT('**** **** **** ', c.last_4_digits) AS masked_number,
       c.pin_hash, CASE WHEN c.state = 'frozen' THEN 'locked' WHEN c.state = 'lost' THEN 'revoked' ELSE c.state END AS status,
       CAST(ROUND(COALESCE(c.daily_limit, 0) * 100) AS SIGNED) AS spend_limit_minor
FROM sonar_bank_physical_cards c
INNER JOIN sonar_accounts sa ON sa.id = c.holder_account_id
INNER JOIN sonar_bank_accounts ba ON ba.id = c.bank_account_id
WHERE c.id = ?
LIMIT 1
]]

local SQL_INSERT = [[
INSERT INTO sonar_bank_physical_cards
  (id, bank_account_id, holder_account_id, card_token, last_4_digits,
   card_kind, state, pin_hash, pin_salt, daily_limit)
VALUES (
  ?, (SELECT id FROM sonar_bank_accounts WHERE iban = ? LIMIT 1),
  (SELECT id FROM sonar_accounts WHERE char_id = ? LIMIT 1),
  ?, ?, ?, 'active', ?, ?, (? / 100.0)
)
]]

local SQL_SET_STATUS = [[
UPDATE sonar_bank_physical_cards c
INNER JOIN sonar_accounts sa ON sa.id = c.holder_account_id
SET c.state = CASE WHEN ? = 'revoked' THEN 'lost' ELSE ? END,
    c.frozen_at = CASE WHEN ? = 'frozen' THEN UNIX_TIMESTAMP() ELSE c.frozen_at END
WHERE c.id = ? AND sa.char_id = ?
]]

local SQL_SET_PIN = [[
UPDATE sonar_bank_physical_cards c
INNER JOIN sonar_accounts sa ON sa.id = c.holder_account_id
SET c.pin_hash = ?
WHERE c.id = ? AND sa.char_id = ?
]]

local SQL_SET_LIMITS = [[
UPDATE sonar_bank_physical_cards c
INNER JOIN sonar_accounts sa ON sa.id = c.holder_account_id
SET c.daily_limit = (? / 100.0),
    c.monthly_limit = (? / 100.0)
WHERE c.id = ? AND sa.char_id = ?
]]

function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST, { citizen_id, limit or 8 })
end

function R.GetById(card_id)
  return DB.QuerySingle(SQL_GET, { card_id })
end

function R.Insert(t)
  local card_id = UUID.V4()
  local card_token = token64()
  local last4 = tostring(t.masked_number or ''):match('(%d%d%d%d)$') or card_token:sub(-4)
  local _, err = DB.Execute(SQL_INSERT, {
    card_id, t.account_iban, t.owner_citizen_id,
    card_token, last4, t.card_kind or 'debit', t.pin_hash, card_token:sub(1, 32), t.spend_limit_minor,
  })
  if err then return nil, err end
  return card_id, nil
end

function R.SetStatus(card_id, owner_citizen_id, status)
  return DB.Execute(SQL_SET_STATUS, { status, status, status, card_id, owner_citizen_id })
end

function R.SetPinHash(card_id, owner_citizen_id, pin_hash)
  return DB.Execute(SQL_SET_PIN, { pin_hash, card_id, owner_citizen_id })
end

function R.SetLimits(card_id, owner_citizen_id, daily_limit_minor, monthly_limit_minor)
  return DB.Execute(SQL_SET_LIMITS, {
    daily_limit_minor or 0,
    monthly_limit_minor or 0,
    card_id,
    owner_citizen_id,
  })
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
