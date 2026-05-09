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
local UUID = BankApp.lib.uuid

local SQL_LIST = [[
SELECT r.id AS recipient_id, r.counterpart_iban, r.alias, r.is_favorite,
       r.created_at * 1000 AS created_ms
FROM sonar_bank_saved_recipients r
INNER JOIN sonar_accounts sa ON sa.id = r.owner_account_id
WHERE sa.char_id = ?
ORDER BY r.is_favorite DESC, r.created_at DESC
LIMIT ?
]]

local SQL_GET = [[
SELECT r.id AS recipient_id, r.counterpart_iban, r.alias, r.is_favorite,
       r.created_at * 1000 AS created_ms
FROM sonar_bank_saved_recipients r
INNER JOIN sonar_accounts sa ON sa.id = r.owner_account_id
WHERE sa.char_id = ? AND r.counterpart_iban = ?
LIMIT 1
]]

local SQL_INSERT = [[
INSERT INTO sonar_bank_saved_recipients
  (id, owner_account_id, counterpart_iban, alias, is_favorite)
VALUES (?, (SELECT id FROM sonar_accounts WHERE char_id = ? LIMIT 1), ?, ?, ?)
ON DUPLICATE KEY UPDATE
  alias = VALUES(alias), is_favorite = VALUES(is_favorite), updated_at = UNIX_TIMESTAMP()
]]

local SQL_DELETE = [[
DELETE r FROM sonar_bank_saved_recipients r
INNER JOIN sonar_accounts sa ON sa.id = r.owner_account_id
WHERE sa.char_id = ? AND r.counterpart_iban = ?
]]

local SQL_SET_FAVORITE = [[
UPDATE sonar_bank_saved_recipients r
INNER JOIN sonar_accounts sa ON sa.id = r.owner_account_id
SET r.is_favorite = ?, r.updated_at = UNIX_TIMESTAMP()
WHERE sa.char_id = ? AND r.counterpart_iban = ?
]]

--- ListByCitizen
function R.ListByCitizen(citizen_id, limit)
  return DB.Query(SQL_LIST, { citizen_id, limit or 50 })
end

function R.Get(citizen_id, counterpart_iban)
  return DB.QuerySingle(SQL_GET, { citizen_id, counterpart_iban })
end

function R.Upsert(citizen_id, counterpart_iban, alias, is_favorite)
  local recipient_id = UUID.V4()
  local _, err = DB.Execute(SQL_INSERT, {
    recipient_id, citizen_id, counterpart_iban, alias, is_favorite and 1 or 0,
  })
  if err then return nil, err end
  return recipient_id, nil
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
