-- =============================================================================
-- SONAR Bank App — lib/auth.lua
-- =============================================================================
-- H001 — Auth helpers canonical lib (per C-BE-02 §2.3.1).
-- AP-AUTH-1 prohibido: ningún callback handler debe inline `exports.sonar_bridges:GetCitizenId`
-- + manual checks. TODOS deben pasar por `auth.RequireCitizen` / `auth.RequireAdmin`
-- / `auth.RequireOwnership`.
--
-- Helpers:
--   RequireCitizen(src)        → (citizen_id, nil) | (nil, AUTH_REQUIRED err)
--   RequireAdmin(src, ace)     → (citizen_id, nil) | (nil, AUTH_FORBIDDEN err)
--   RequireOwnership(src, target_iban)
--                              → (citizen_id, account_row, nil) | (nil, nil, err)
--   ResolveCitizenSrc(citizen_id)
--                              → (src, nil) | (nil, err)  [for admin DM patterns]
--
-- ACE name canonical: 'sonar.bank.admin' (defined per DevOps convar policy).
--
-- Deps: lib/errors + sonar_bridges exports.
-- =============================================================================

BankApp.lib.auth = {}
local M = BankApp.lib.auth

local Errors = BankApp.lib.errors
local Config = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. Bridges accessor (defensive)
-- -----------------------------------------------------------------------------

local function bridge_get_citizen_id(src)
  return exports.sonar_bridges:GetCitizenId(src)
end

-- -----------------------------------------------------------------------------
-- §2. Core: RequireCitizen
-- -----------------------------------------------------------------------------

--- RequireCitizen: validate src is a connected player AND has a citizen_id.
---   First-line auth gate for ALL Tier 1 callbacks (read-only).
---@param src integer player source id
---@return string|nil citizen_id
---@return table|nil err standardized AUTH_REQUIRED
function M.RequireCitizen(src)
  if type(src) ~= 'number' or src <= 0 then
    return nil, Errors.New('AUTH_REQUIRED', { reason = 'invalid src' })
  end

  -- Player online check
  local name = GetPlayerName(src)
  if not name or name == '' then
    return nil, Errors.New('AUTH_REQUIRED', { reason = 'player offline', src = src })
  end

  local ok, citizen_id = pcall(bridge_get_citizen_id, src)
  if not ok then
    return nil, Errors.New('INTERNAL_ERROR', { reason = 'GetCitizenId raised', raw = tostring(citizen_id) })
  end

  if type(citizen_id) ~= 'string' or #citizen_id == 0 then
    return nil, Errors.New('AUTH_REQUIRED', { reason = 'no citizen_id bound', src = src })
  end

  return citizen_id, nil
end

-- -----------------------------------------------------------------------------
-- §3. RequireAdmin (ACE check)
-- -----------------------------------------------------------------------------

local DEFAULT_ADMIN_ACE = Config.Permissions.ADMIN_ACE

--- RequireAdmin: validate citizen + ACE permission. Used for Tier 3 admin
--- callbacks (govt audit, forced operations, etc.).
---@param src integer
---@param ace_override string|nil custom ACE (defaults to 'sonar.bank.admin')
---@return string|nil citizen_id
---@return table|nil err
function M.RequireAdmin(src, ace_override)
  local citizen_id, err = M.RequireCitizen(src)
  if err then return nil, err end

  local ace = ace_override or DEFAULT_ADMIN_ACE
  -- IsPlayerAceAllowed: native FiveM
  if not IsPlayerAceAllowed(src, ace) and (ace == DEFAULT_ADMIN_ACE or not IsPlayerAceAllowed(src, DEFAULT_ADMIN_ACE)) then
    return nil, Errors.New('AUTH_ACE_DENIED', {
      reason = 'ACE permission denied',
      ace    = ace,
      src    = src,
    })
  end

  return citizen_id, nil
end

-- -----------------------------------------------------------------------------
-- §4. RequireOwnership
--
--   Validates that citizen owns or has joint access to the given IBAN.
--   Returns the account row para downstream business logic.
--
--   NOTE: Schema lookup hits sonar_bank_accounts (or whatever table sonar_core
--   exposes). Owner check via owner_citizen_id + joint_owners JSON array.
-- -----------------------------------------------------------------------------

local SQL_LOOKUP_ACCOUNT = [[
SELECT a.id AS account_id, a.iban, sa.char_id AS owner_citizen_id,
       JSON_ARRAY() AS joint_owners,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       0 AS savings_minor,
       CASE
         WHEN a.closed_at IS NOT NULL THEN 'closed'
         WHEN a.is_frozen = 1 THEN 'frozen'
         ELSE 'active'
       END AS status,
       a.is_frozen AS frozen_flag
FROM sonar_bank_accounts a
LEFT JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE a.iban = ? AND a.closed_at IS NULL
LIMIT 1
]]

--- RequireOwnership: citizen + account ownership / joint access check.
---@param src integer
---@param target_iban string normalized IBAN
---@param opts table|nil { allow_joint=boolean (default true) }
---@return string|nil citizen_id
---@return table|nil account_row
---@return table|nil err
function M.RequireOwnership(src, target_iban, opts)
  opts = opts or {}
  local allow_joint = opts.allow_joint ~= false

  local citizen_id, err = M.RequireCitizen(src)
  if err then return nil, nil, err end

  local DB = BankApp.lib.db  -- lazy require (db loaded after auth en strict order)
  if not DB then
    return nil, nil, Errors.New('INTERNAL_ERROR', { reason = 'DB lib not loaded' })
  end

  local row, db_err = DB.QuerySingle(SQL_LOOKUP_ACCOUNT, { target_iban })
  if db_err then return nil, nil, db_err end
  if not row then
    return nil, nil, Errors.New('ACCOUNT_NOT_FOUND', { iban = target_iban })
  end

  -- Frozen flag check (precondition)
  if DB.ToBool(row.frozen_flag) then
    return nil, nil, Errors.New('ACCOUNT_FROZEN', { iban = target_iban })
  end

  -- Primary owner
  if row.owner_citizen_id == citizen_id then
    return citizen_id, row, nil
  end

  -- Joint owner check
  if allow_joint and row.joint_owners then
    -- joint_owners is JSON array — decode + scan
    local joint_str = row.joint_owners
    if type(joint_str) == 'string' and #joint_str > 0 and json and json.decode then
      local ok_decode, joint_arr = pcall(json.decode, joint_str)
      if ok_decode and type(joint_arr) == 'table' then
        for _, jcid in ipairs(joint_arr) do
          if jcid == citizen_id then
            return citizen_id, row, nil
          end
        end
      end
    end
  end

  return nil, nil, Errors.New('AUTH_OWNER_MISMATCH', {
    reason = 'not owner / not joint',
    iban   = target_iban,
  })
end

-- -----------------------------------------------------------------------------
-- §5. ResolveCitizenSrc (reverse lookup — citizen_id → online src)
--
--   Used cuando server initiates an event toward a player by citizen_id (e.g.
--   admin audit response triggered from cron).
--   Returns nil if citizen offline.
-- -----------------------------------------------------------------------------

--- ResolveCitizenSrc: scan all online players and find one with matching citizen_id.
---@param citizen_id string
---@return integer|nil src
function M.ResolveCitizenSrc(citizen_id)
  if type(citizen_id) ~= 'string' or #citizen_id == 0 then return nil end

  for _, src_str in ipairs(GetPlayers()) do
    local src = tonumber(src_str)
    if src then
      local ok, cid = pcall(bridge_get_citizen_id, src)
      if ok and cid == citizen_id then
        return src
      end
    end
  end
  return nil
end

-- -----------------------------------------------------------------------------
-- §6. Diagnostics
-- -----------------------------------------------------------------------------

--- WhoAmI: introspection helper (debug). Returns citizen_id + ACE flag.
---@param src integer
---@return table { src, citizen_id, is_admin, online }
function M.WhoAmI(src)
  local online = GetPlayerName(src) ~= nil
  local cid, _ = M.RequireCitizen(src)
  local is_admin = online and IsPlayerAceAllowed(src, DEFAULT_ADMIN_ACE) or false
  return {
    src        = src,
    citizen_id = cid,
    is_admin   = is_admin,
    online     = online,
  }
end

return M
