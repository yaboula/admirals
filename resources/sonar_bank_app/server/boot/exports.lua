-- =============================================================================
-- SONAR Bank App — boot/exports.lua
-- =============================================================================
-- Public FiveM resource exports for cross-resource queries.
--
-- Consumers:
--   - sonar_bridges (core_override.lua) — reads SONAR balance on PlayerLoaded
--     to push SONAR → framework (QB players.money.bank) when bank_mode=mirror.
--   - Third-party resources that want to query the canonical SONAR balance
--     without touching the DB directly.
--
-- Deps: server/repos/accounts.lua (AccountsRepo.ListByCitizen).
--
-- Contract stability: EXPORT_STABLE_V1 — do not break signatures without
-- coordinated handoff to consumers.
-- =============================================================================

local AccountsRepo = BankApp.repos.accounts
local Validators   = BankApp.lib.validators

--- GetPrimaryBalanceMinor — returns the primary checking account balance
--- (in minor units / cents) for the given citizen. Picks the first active
--- checking account found (ordered by created_at ASC — oldest = primary).
---
---@param citizen_id string
---@return integer|nil balance_minor  nil if citizen has no checking account
---@return string|nil  error          'INVALID_CITIZEN_ID' | 'NOT_FOUND' | 'DB_ERROR'
exports('GetPrimaryBalanceMinor', function(citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then
    return nil, 'INVALID_CITIZEN_ID'
  end
  local rows, err = AccountsRepo.ListByCitizen(citizen_id, 8)
  if err then return nil, 'DB_ERROR' end
  if type(rows) ~= 'table' or #rows == 0 then return nil, 'NOT_FOUND' end
  -- Pick first active checking account (ListByCitizen returns oldest first,
  -- and status='active' means not frozen + not closed).
  for _, row in ipairs(rows) do
    if row.status == 'active' then
      local bal = tonumber(row.balance_minor)
      if bal then return bal, nil end
    end
  end
  -- Fallback: first row even if frozen (mirror still makes sense for frozen
  -- accounts — HUD should reflect current balance, frozen ≠ zeroed).
  local bal = tonumber(rows[1].balance_minor)
  if bal then return bal, nil end
  return nil, 'NOT_FOUND'
end)
