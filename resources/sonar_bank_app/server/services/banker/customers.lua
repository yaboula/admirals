-- =============================================================================
-- SONAR Bank App — services/banker/customers.lua
-- =============================================================================
-- Customers search + detail + freeze for the Bank Owner Panel (F2).
--
--   Search:   citizen_id LIKE %query%      (capability: customers_view)
--   Detail:   accounts list of citizen      (capability: customers_view)
--   Freeze:   set is_frozen on IBAN          (capability: customers_freeze)
--             — emits H006-compliant audit (previous_flag_snapshot mandatory)
-- =============================================================================

BankApp.services.banker = BankApp.services.banker or {}
BankApp.services.banker.customers = {}
local S = BankApp.services.banker.customers

local Validators  = BankApp.lib.validators
local Errors      = BankApp.lib.errors
local Audit       = BankApp.lib.audit
local Enums       = BankApp.lib.enums
local BankerAuth  = BankApp.lib.banker_auth
local BankerAggr  = BankApp.repos.banker_aggregate

local function now_ms() return os.time() * 1000 end

-- ---------------------------------------------------------------------------
-- §1. Search by citizen_id (substring)
-- ---------------------------------------------------------------------------
function S.Search(ctx)
  local _, _, auth_err = BankerAuth.RequireBanker(ctx.src, 'customers_view')
  if auth_err then return { ok = false, error = auth_err } end

  local query = type(ctx.query) == 'string' and ctx.query or ''
  -- Defensive: at least 2 chars to avoid scanning whole table on stray "" search.
  if #query < 2 then
    return { ok = true, data = { items = {}, query = query, fetched_at_ms = now_ms() } }
  end
  if #query > 64 then query = query:sub(1, 64) end

  local rows, err = BankerAggr.SearchCustomers(query, ctx.limit or 25)
  if err then return { ok = false, error = err } end

  for _, row in ipairs(rows or {}) do
    row.account_count       = tonumber(row.account_count) or 0
    row.total_balance_minor = tonumber(row.total_balance_minor) or 0
    row.total_savings_minor = tonumber(row.total_savings_minor) or 0
    row.last_activity_ms    = tonumber(row.last_activity_ms)
    row.frozen_count        = tonumber(row.frozen_count) or 0
  end

  return { ok = true, data = { items = rows or {}, query = query, fetched_at_ms = now_ms() } }
end

-- ---------------------------------------------------------------------------
-- §2. Detail (accounts of one citizen)
-- ---------------------------------------------------------------------------
function S.Detail(ctx)
  local _, _, auth_err = BankerAuth.RequireBanker(ctx.src, 'customers_view')
  if auth_err then return { ok = false, error = auth_err } end

  if not Validators.IsValidCitizenId(ctx.citizen_id) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end

  local accounts, err = BankerAggr.GetCustomerAccounts(ctx.citizen_id)
  if err then return { ok = false, error = err } end

  local total_balance, total_savings, frozen = 0, 0, 0
  for _, a in ipairs(accounts or {}) do
    a.balance_minor = tonumber(a.balance_minor) or 0
    a.savings_minor = tonumber(a.savings_minor) or 0
    a.is_frozen     = tonumber(a.is_frozen) == 1
    a.created_ms    = tonumber(a.created_ms)
    a.updated_ms    = tonumber(a.updated_ms)
    total_balance = total_balance + a.balance_minor
    total_savings = total_savings + a.savings_minor
    if a.is_frozen then frozen = frozen + 1 end
  end

  return {
    ok = true,
    data = {
      citizen_id           = ctx.citizen_id,
      accounts             = accounts or {},
      account_count        = #(accounts or {}),
      frozen_count         = frozen,
      total_balance_minor  = total_balance,
      total_savings_minor  = total_savings,
      fetched_at_ms        = now_ms(),
    },
  }
end

-- ---------------------------------------------------------------------------
-- §3. Set frozen flag (banker-driven)
-- ---------------------------------------------------------------------------
local function _set_frozen(ctx, frozen_bool, audit_event_type)
  local actor_id, _, auth_err = BankerAuth.RequireBanker(ctx.src, 'customers_freeze')
  if auth_err then return { ok = false, error = auth_err } end

  local norm_iban = Validators.NormalizeIBAN(ctx.iban)
  if not norm_iban then return { ok = false, error = Errors.New('INVALID_IBAN') } end

  local row, get_err = BankerAggr.GetAccountByIban(norm_iban)
  if get_err then return { ok = false, error = get_err } end
  if not row then return { ok = false, error = Errors.New('ACCOUNT_NOT_FOUND', { iban = norm_iban }) } end

  local was_frozen = tonumber(row.is_frozen) == 1
  if was_frozen == frozen_bool then
    return { ok = true, data = { iban = norm_iban, frozen = frozen_bool, no_op = true } }
  end

  local previous_snapshot = {
    iban         = norm_iban,
    frozen_flag  = was_frozen,
    snapshot_ms  = now_ms(),
    via          = 'banker',
  }

  local _, set_err = BankerAggr.SetFrozenByIban(norm_iban, frozen_bool)
  if set_err then return { ok = false, error = set_err } end

  Audit.Write({
    event_type             = audit_event_type,
    actor_citizen_id       = actor_id,
    actor_src              = ctx.src,
    target_citizen_id      = row.owner_citizen_id,
    target_iban            = norm_iban,
    target_account_id      = row.account_id,
    previous_flag_snapshot = previous_snapshot,
    event_data             = {
      reason          = Validators.SanitizeReason(ctx.reason),
      new_frozen_flag = frozen_bool,
      via             = 'banker',
    },
  })

  return { ok = true, data = { iban = norm_iban, frozen = frozen_bool, committed_at_ms = now_ms() } }
end

function S.Freeze(ctx)
  return _set_frozen(ctx, true, Enums.AUDIT_EVENT_TYPE.ACCOUNT_FREEZE)
end

function S.Unfreeze(ctx)
  return _set_frozen(ctx, false, Enums.AUDIT_EVENT_TYPE.ACCOUNT_UNFREEZE)
end
