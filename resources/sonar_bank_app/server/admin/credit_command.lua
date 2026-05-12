-- =============================================================================
-- SONAR Bank App — admin/credit_command.lua
-- =============================================================================
-- Framework-agnostic admin balance-credit command. Replaces the now-blocked
-- `/givemoney 1 bank N` flow with one that goes through the Sonar ledger as
-- the single source of truth, then mirrors the new balance to the active
-- framework (qb-core / qbox / esx) via sonar_bridges.MirrorSyncBalance.
--
-- Why this command is needed:
--   The OnMoneyPreHook in sonar_bridges vetoes any direct framework-side
--   AddMoney/SetMoney/RemoveMoney on the `bank` slot that lacks a valid Sonar
--   capability token. That includes qb-core's own `/givemoney`. Admins still
--   need a way to grant/seize bank funds — this command is that way.
--
-- Usage:
--   /sonarcredit <target> <amount_minor> [reason]
--     target       : player server id (number)  OR  citizen_id (string)
--     amount_minor : signed integer in MINOR units (1 USD = 100 minor).
--                    Positive = credit, negative = debit.
--     reason       : free text (default 'admin_credit')
--
--   Examples (server console OR in-game with ACE `sonar.bank.admin`):
--     sonarcredit 1 50000              → +500 USD to player src=1's primary IBAN
--     sonarcredit FXD56242 -2500       → -25 USD from FXD56242's primary IBAN
--     sonarcredit 2 100000 "Event prize"
--
-- ACL:
--   - Server console (src=0)          → always allowed.
--   - In-game caller (src>0)          → must have ACE `sonar.bank.admin`.
--
-- Audit trail:
--   AdminService.AdjustBalance writes a BALANCE_ADJUST_ADMIN audit row with
--   actor_citizen_id, target_citizen_id, delta, reason, correlation_id.
-- =============================================================================

local AdminService = BankApp.services.admin
local AccountsRepo = BankApp.repos.accounts
local Auth         = BankApp.lib.auth
local Errors       = BankApp.lib.errors
local Logger       = BankApp.lib.logger or { Info = print, Warn = print, Error = print }

local DEFAULT_ADMIN_ACE = 'sonar.bank.admin'

-- ---------------------------------------------------------------------------
-- Resolve target arg → citizen_id.
--   Numeric input  → treat as server id, query sonar_bridges identity.
--   Non-numeric    → treat as citizen_id directly.
-- ---------------------------------------------------------------------------
local function resolve_target(target_arg)
  if not target_arg or target_arg == '' then
    return nil, 'target required'
  end
  local as_src = tonumber(target_arg)
  if as_src then
    -- Try sonar_bridges identity adapter first; fall back to qb-core / qbox.
    local ok, citizen = pcall(function()
      return exports.sonar_bridges:GetCitizenId(as_src)
    end)
    if ok and type(citizen) == 'string' and #citizen > 0 then
      return citizen, nil
    end
    -- Fallback to QBCore direct (in case bridge identity is unavailable).
    local ok2, qb_player = pcall(function()
      return exports['qb-core']:GetCoreObject().Functions.GetPlayer(as_src)
    end)
    if ok2 and qb_player and qb_player.PlayerData and qb_player.PlayerData.citizenid then
      return qb_player.PlayerData.citizenid, nil
    end
    return nil, ('cannot resolve citizen_id for src=%s'):format(as_src)
  end
  -- Treat as citizen_id directly.
  return tostring(target_arg), nil
end

-- ---------------------------------------------------------------------------
-- Resolve citizen_id → primary IBAN (oldest active account).
-- ---------------------------------------------------------------------------
local function resolve_primary_iban(citizen_id)
  local rows, err = AccountsRepo.ListByCitizen(citizen_id, 32)
  if err then return nil, err end
  if not rows or #rows == 0 then
    return nil, ('no active accounts for citizen_id=%s'):format(citizen_id)
  end
  -- ListByCitizen orders by created_at ASC; first row = primary.
  for _, row in ipairs(rows) do
    if row.status == 'active' then return row.iban, nil end
  end
  return nil, ('no ACTIVE accounts (only frozen/closed) for citizen_id=%s'):format(citizen_id)
end

-- ---------------------------------------------------------------------------
-- Sum every active account balance for a citizen_id (in minor units).
-- Used to feed MirrorSyncBalance with the canonical aggregate, matching what
-- the framework's `bank` slot is supposed to represent post-credit.
-- ---------------------------------------------------------------------------
local function sum_active_balance_minor(citizen_id)
  local rows = AccountsRepo.ListByCitizen(citizen_id, 32) or {}
  local total = 0
  for _, row in ipairs(rows) do
    if row.status == 'active' then
      total = total + (tonumber(row.balance_minor) or 0)
    end
  end
  return total
end

-- ---------------------------------------------------------------------------
-- Core command handler. Exposed as a Lua function so it can be invoked from
-- the RegisterCommand wrapper OR programmatically by future REST/integration.
-- ---------------------------------------------------------------------------
local function exec_credit(actor_src, target_arg, amount_minor, reason)
  -- ACL
  local actor_citizen_id
  if actor_src and actor_src > 0 then
    local cid, err = Auth.RequireAdmin(actor_src, DEFAULT_ADMIN_ACE)
    if err then
      return { ok = false, error = err }
    end
    actor_citizen_id = cid
  else
    actor_citizen_id = 'console'
  end

  -- Validate amount
  amount_minor = tonumber(amount_minor)
  if not amount_minor or amount_minor == 0 then
    return { ok = false, error = Errors.New('INVALID_AMOUNT', { reason = 'amount_minor must be non-zero integer' }) }
  end

  -- Resolve target
  local target_cid, terr = resolve_target(target_arg)
  if terr then return { ok = false, error = terr } end

  -- Resolve primary IBAN
  local iban, ierr = resolve_primary_iban(target_cid)
  if ierr then return { ok = false, error = ierr } end

  -- Idempotency / correlation
  local correlation_id = ('admin_credit|%s|%s|%s'):format(
    actor_citizen_id, target_cid, tostring(GetGameTimer()))

  -- Authoritative write: AdminService.AdjustBalance against Sonar ledger.
  local result = AdminService.AdjustBalance({
    src              = actor_src,
    actor_citizen_id = actor_citizen_id,
    iban             = iban,
    delta_minor      = amount_minor,
    reason           = reason or 'admin_credit',
    correlation_id   = correlation_id,
  })
  if not result or not result.ok then
    return result or { ok = false, error = 'unknown_failure' }
  end

  -- Mirror aggregate balance to active framework (qb-core/qbox/esx).
  local total_minor = sum_active_balance_minor(target_cid)
  local mirror_res
  pcall(function()
    mirror_res = exports.sonar_bridges:MirrorSyncBalance(target_cid, total_minor, {
      reason         = 'admin_credit',
      correlation_id = correlation_id,
      citizen_id     = target_cid,
      op             = 'set',
      amount         = total_minor,
    })
  end)

  Logger.Info(('[admin_credit] actor=%s target=%s iban=%s delta_minor=%s total_minor=%s mirror=%s'):format(
    actor_citizen_id, target_cid, iban, tostring(amount_minor),
    tostring(total_minor), tostring(mirror_res and mirror_res.ok)))

  return {
    ok       = true,
    iban     = iban,
    citizen  = target_cid,
    delta    = amount_minor,
    new_iban_balance_minor   = result.data and result.data.new_balance,
    new_total_balance_minor  = total_minor,
    mirror_ok                = mirror_res and mirror_res.ok or false,
  }
end

-- ---------------------------------------------------------------------------
-- Command registration.
-- `restricted=true` ensures the in-game chat command requires an ACE; we
-- enforce `sonar.bank.admin` explicitly inside the handler via Auth.RequireAdmin
-- so the same code path works for any ace_override.
-- ---------------------------------------------------------------------------
RegisterCommand('sonarcredit', function(src, args)
  if not args[1] or not args[2] then
    local out = '[sonarcredit] usage: sonarcredit <src|citizen_id> <amount_minor> [reason]'
    if src and src > 0 then
      TriggerClientEvent('chat:addMessage', src, { args = { '^1[sonarcredit]', out } })
    else
      print(out)
    end
    return
  end
  local reason = nil
  if args[3] then
    -- Join trailing args as reason (chat splits by space).
    reason = table.concat(args, ' ', 3)
  end
  local res = exec_credit(src or 0, args[1], args[2], reason)
  local pretty = json and json.encode and json.encode(res) or tostring(res.ok)
  if src and src > 0 then
    local color = res.ok and '^2' or '^1'
    TriggerClientEvent('chat:addMessage', src, { args = { color .. '[sonarcredit]', pretty } })
  else
    print('[sonarcredit] ' .. pretty)
  end
end, true)

-- Expose programmatic API for future automation.
BankApp.services.admin._exec_credit_cli = exec_credit

if Logger and Logger.Info then
  Logger.Info('[admin_credit] /sonarcredit registered (ACE: ' .. DEFAULT_ADMIN_ACE .. ')')
end
