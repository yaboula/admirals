-- =============================================================================
-- SONAR Bank App — repos/recipients.lua
-- =============================================================================
-- Saved recipients (favorites/contacts) DAO.
--
-- Schema (sonar_core migration 014 bank_saved_recipients):
--   recipient_id     BIGINT PK AUTO_INCREMENT
--   owner_citizen_id VARCHAR(64) NOT NULL
--   counterpart_iban VARCHAR(34) NOT NULL
--   alias            VARCHAR(64) NULL  (display name)
--   is_favorite      TINYINT(1) DEFAULT 0
--   created_at       TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6)
--   UNIQUE KEY (owner_citizen_id, counterpart_iban)
-- =============================================================================

BankApp.repos.recipients = {}
local R = BankApp.repos.recipients

local DB = BankApp.lib.db

local SQL_LIST = [[
SELECT recipient_id, counterpart_iban, alias, is_favorite,
       UNIX_TIMESTAMP(created_at)*1000 AS created_ms
FROM bank_saved_recipients
WHERE owner_citizen_id = ?
ORDER BY is_favorite DESC, created_at DESC
LIMIT ?
]]

local SQL_GET = [[
SELECT recipient_id, counterpart_iban, alias, is_favorite,
       UNIX_TIMESTAMP(created_at)*1000 AS created_ms
FROM bank_saved_recipients
WHERE owner_citizen_id = ? AND counterpart_iban = ?
LIMIT 1
]]

local SQL_INSERT = [[
INSERT INTO bank_saved_recipients
  (owner_citizen_id, counterpart_iban, alias, is_favorite)
VALUES (?, ?, ?, ?)
ON DUPLICATE KEY UPDATE
  alias = VALUES(alias), is_favorite = VALUES(is_favorite)
]]

local SQL_DELETE = [[
DELETE FROM bank_saved_recipients
WHERE owner_citizen_id = ? AND counterpart_iban = ?
]]

local SQL_SET_FAVORITE = [[
UPDATE bank_saved_recipients
SET is_favorite = ?
WHERE owner_citizen_id = ? AND counterpart_iban = ?
]]

--- ListByCitizen
function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST, { citizen_id, limit or 50 })
end

function R.Get(citizen_id, counterpart_iban)
  return DB.QuerySingle(SQL_GET, { citizen_id, counterpart_iban })
end

function R.Upsert(citizen_id, counterpart_iban, alias, is_favorite)
  return DB.Insert(SQL_INSERT, {
    citizen_id, counterpart_iban, alias, is_favorite and 1 or 0,
  })
end

function R.Delete(citizen_id, counterpart_iban)
  return DB.Execute(SQL_DELETE, { citizen_id, counterpart_iban })
end

function R.SetFavorite(citizen_id, counterpart_iban, is_favorite)
  return DB.Execute(SQL_SET_FAVORITE, {
    is_favorite and 1 or 0, citizen_id, counterpart_iban,
  })
end

--- BuildSavedListQuery — REQ-FE-001 bootstrap parallel descriptor.
function R.BuildSavedListQuery(citizen_id, limit)
  return {
    sql    = SQL_LIST,
    params = { citizen_id, limit or 50 },
    kind   = 'query',
  }
end

return R
