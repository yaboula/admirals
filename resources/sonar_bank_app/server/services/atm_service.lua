-- =============================================================================
-- SONAR Bank App — services/atm_service.lua
-- =============================================================================
-- F06 — In-game NUI ATM flow.
--
--   The legacy `admin_service.AtmWithdraw` (C031) keeps the HMAC-signed contract
--   intended for OUT-OF-BAND atm hardware. The NUI flow served from React
--   cannot keep an HMAC secret, so this service introduces an alternative
--   authorization path:
--
--     1. Session(ctx)        → returns terminal info (online, cash, daily limit)
--     2. VerifyPin(ctx)      → validates per-card PIN, grants a 5-min token
--     3. NuiWithdraw(ctx)    → debits balance using a valid grant token
--
--   The grant token replaces the HMAC: it is bound to (citizen_id, card_id,
--   terminal_id) and expires after `GRANT_TTL_MS` of inactivity. Failed PIN
--   attempts increment `pin_attempts_failed`; reaching `PIN_FAIL_THRESHOLD`
--   freezes the card (state='frozen', frozen_reason='atm_pin_attempts').
--
--   Audit events emitted:
--     ATM_PIN_VERIFY_OK
--     ATM_PIN_VERIFY_FAIL
--     ATM_CARD_AUTOFREEZE
--     ATM_NUI_WITHDRAW
--     ATM_FAILED            (insufficient funds / over-limit)
-- =============================================================================

BankApp.services.atm = {}
local S = BankApp.services.atm

local Validators = BankApp.lib.validators
local Errors     = BankApp.lib.errors
local DB         = BankApp.lib.db
local Audit      = BankApp.lib.audit
local Auth       = BankApp.lib.auth
local Publish    = BankApp.lib.publish
local Enums      = BankApp.lib.enums
local Perf       = BankApp.lib.perf
local Economy    = BankApp.lib.economy
local UUID       = BankApp.lib.uuid
local Config     = BankApp.Config

local CardsRepo        = BankApp.repos.cards
local AccountsRepo     = BankApp.repos.accounts
local TransactionsRepo = BankApp.repos.transactions

local CardService = BankApp.services.card  -- for HashPin

local function now_ms() return os.time() * 1000 end

-- -----------------------------------------------------------------------------
-- §1. Constants + grant store
-- -----------------------------------------------------------------------------

local GRANT_TTL_MS         = 5 * 60 * 1000   -- 5 minutes
local PIN_FAIL_THRESHOLD   = 3                -- auto-freeze at this many fails
local DEFAULT_TERMINAL_CASH_MINOR    = 5000000  -- $50,000 — terminal cash float
local DEFAULT_DAILY_LIMIT_FALLBACK   = 200000   -- $2,000 default if card has none

-- In-memory grant store. Keyed by `<citizen_id>|<card_id>` so the same player
-- can have separate grants for different cards. Single grant per pair (latest
-- wins). Lives only for the resource lifetime — server restart drops all.
--
--   _grants[key] = {
--     grant_id      = string,   -- random UUID, returned to FE
--     terminal_id   = string,   -- bound terminal (informational)
--     expires_at_ms = integer,
--   }
local _grants = {}

local function _grant_key(citizen_id, card_id)
  return tostring(citizen_id) .. '|' .. tostring(card_id)
end

local function _store_grant(citizen_id, card_id, terminal_id)
  local grant_id = UUID.V4()
  local now_ts   = now_ms()
  _grants[_grant_key(citizen_id, card_id)] = {
    grant_id      = grant_id,
    terminal_id   = terminal_id,
    expires_at_ms = now_ts + GRANT_TTL_MS,
  }
  return grant_id, now_ts + GRANT_TTL_MS
end

local function _consume_grant(citizen_id, card_id, grant_id)
  local key = _grant_key(citizen_id, card_id)
  local g   = _grants[key]
  if not g then return nil end
  if g.grant_id ~= grant_id then return nil end
  if g.expires_at_ms <= now_ms() then
    _grants[key] = nil
    return nil
  end
  -- Refresh TTL on use (sliding window) so a long withdraw doesn't expire mid-flow.
  g.expires_at_ms = now_ms() + GRANT_TTL_MS
  return g
end

-- Periodic GC — clean expired grants every 60s. Cheap (table iteration).
CreateThread(function()
  while true do
    Wait(60 * 1000)
    local cutoff = now_ms()
    for k, g in pairs(_grants) do
      if g.expires_at_ms <= cutoff then _grants[k] = nil end
    end
  end
end)

-- -----------------------------------------------------------------------------
-- §2. Helpers
-- -----------------------------------------------------------------------------

local function _terminal_id_from_ctx(ctx)
  -- Caller (NUI bridge) may pass entity_net_id + model_hash + coords.
  -- Build a stable string for audit + grant binding.
  local t = ctx.terminal
  if type(t) == 'table' then
    if t.entity_net_id then return ('atm:net:%d'):format(tonumber(t.entity_net_id) or 0) end
    if t.coords then
      return ('atm:xyz:%.1f,%.1f,%.1f'):format(t.coords.x or 0, t.coords.y or 0, t.coords.z or 0)
    end
  end
  if type(ctx.terminal_id) == 'string' and #ctx.terminal_id > 0 then
    return ctx.terminal_id
  end
  return 'atm:unknown'
end

local function _card_daily_limit_minor(card_row)
  -- daily_limit is DECIMAL(14,2); convert major→minor. NULL means no per-card cap.
  local dl = card_row.daily_limit
  if dl == nil or tostring(dl) == '' then return DEFAULT_DAILY_LIMIT_FALLBACK end
  return math.floor((tonumber(dl) or 0) * 100 + 0.5)
end

local function _card_daily_used_minor(card_row)
  local du = card_row.daily_used_today
  return math.floor((tonumber(du) or 0) * 100 + 0.5)
end

-- -----------------------------------------------------------------------------
-- §2bis. Cash give-out (framework bridge)
--
--   The SONAR ledger debit is purely accounting — to actually hand the player
--   physical cash we must talk to the active framework (qbx_core / qb-core /
--   ESX). This is the missing link that made withdrawals "succeed but give no
--   cash" before this revision.
--
--   We try frameworks in priority order. Returns:
--     ok        boolean
--     framework string ('qbx'|'qb'|'esx'|'noop')
--     err       string|nil
-- -----------------------------------------------------------------------------

local function _give_cash_qbx(src, amount_major, reason)
  if GetResourceState('qbx_core') ~= 'started' then return nil end
  local ok, Player = pcall(function() return exports.qbx_core:GetPlayer(src) end)
  if not ok or not Player or not Player.Functions then return false, 'qbx_no_player' end
  local added = Player.Functions.AddMoney('cash', amount_major, reason)
  return added == true, added == true and nil or 'qbx_addmoney_failed'
end

local function _give_cash_qbcore(src, amount_major, reason)
  if GetResourceState('qb-core') ~= 'started' then return nil end
  local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
  if not ok or type(core) ~= 'table' then return false, 'qb_no_core' end
  local Player = core.Functions.GetPlayer(tonumber(src))
  if not Player or not Player.Functions then return false, 'qb_no_player' end
  local added = Player.Functions.AddMoney('cash', amount_major, reason)
  return added == true, added == true and nil or 'qb_addmoney_failed'
end

local function _give_cash_esx(src, amount_major)
  if GetResourceState('es_extended') ~= 'started' then return nil end
  local ok, esx = pcall(function() return exports['es_extended']:getSharedObject() end)
  if not ok or type(esx) ~= 'table' then return false, 'esx_no_core' end
  local xPlayer = esx.GetPlayerFromId(tonumber(src))
  if not xPlayer then return false, 'esx_no_player' end
  if type(xPlayer.addMoney) == 'function' then
    xPlayer.addMoney(amount_major)
    return true, nil
  elseif type(xPlayer.addAccountMoney) == 'function' then
    xPlayer.addAccountMoney('money', amount_major)
    return true, nil
  end
  return false, 'esx_no_addmoney'
end

--- Hand `amount_minor` cents in physical cash to the player at `src`.
--- Tries QBox → QBCore → ESX. Returns ok, framework_name, err.
local function _give_cash_to_player(src, amount_minor, reason)
  -- ATMs only dispense whole units; we pass MAJOR (dollars) to the framework.
  local amount_major = math.floor((tonumber(amount_minor) or 0) / 100)
  if amount_major <= 0 then return false, 'noop', 'amount_zero' end

  for _, fn in ipairs({
    { name = 'qbx',    fn = function() return _give_cash_qbx(src, amount_major, reason) end },
    { name = 'qb',     fn = function() return _give_cash_qbcore(src, amount_major, reason) end },
    { name = 'esx',    fn = function() return _give_cash_esx(src, amount_major) end },
  }) do
    local ok, err = fn.fn()
    -- nil = framework not present, try next
    if ok == true then return true, fn.name, nil end
    if ok == false then return false, fn.name, err end
  end
  return false, 'noop', 'no_framework_detected'
end

--- Take physical cash FROM the player. Mirror of _give_cash_to_player used
--- during ATM deposits (cash in pocket → bank balance).
--- Returns ok, framework_name, err. Returns false 'insufficient_cash' if the
--- player doesn't have enough cash so we can abort cleanly before debit.
local function _take_cash_from_player(src, amount_minor, reason)
  local amount_major = math.floor((tonumber(amount_minor) or 0) / 100)
  if amount_major <= 0 then return false, 'noop', 'amount_zero' end

  -- QBox first
  if GetResourceState('qbx_core') == 'started' then
    local ok, Player = pcall(function() return exports.qbx_core:GetPlayer(src) end)
    if ok and Player and Player.PlayerData and Player.Functions then
      local cash = (Player.PlayerData.money or {}).cash or 0
      if cash < amount_major then return false, 'qbx', 'insufficient_cash' end
      local removed = Player.Functions.RemoveMoney('cash', amount_major, reason)
      return removed == true, 'qbx', removed == true and nil or 'qbx_removemoney_failed'
    end
  end
  -- QBCore
  if GetResourceState('qb-core') == 'started' then
    local cok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if cok and type(core) == 'table' then
      local Player = core.Functions.GetPlayer(tonumber(src))
      if Player and Player.PlayerData and Player.Functions then
        local cash = (Player.PlayerData.money or {}).cash or 0
        if cash < amount_major then return false, 'qb', 'insufficient_cash' end
        local removed = Player.Functions.RemoveMoney('cash', amount_major, reason)
        return removed == true, 'qb', removed == true and nil or 'qb_removemoney_failed'
      end
    end
  end
  -- ESX
  if GetResourceState('es_extended') == 'started' then
    local cok, esx = pcall(function() return exports['es_extended']:getSharedObject() end)
    if cok and type(esx) == 'table' then
      local xPlayer = esx.GetPlayerFromId(tonumber(src))
      if xPlayer then
        local cash = type(xPlayer.getMoney) == 'function' and xPlayer.getMoney() or 0
        if cash < amount_major then return false, 'esx', 'insufficient_cash' end
        if type(xPlayer.removeMoney) == 'function' then
          xPlayer.removeMoney(amount_major)
          return true, 'esx', nil
        end
        return false, 'esx', 'esx_no_removemoney'
      end
    end
  end
  return false, 'noop', 'no_framework_detected'
end

--- Best-effort cash refund — used to roll back on debit failure after cash give.
local function _refund_cash_from_player(src, amount_minor, framework, reason)
  local amount_major = math.floor((tonumber(amount_minor) or 0) / 100)
  if amount_major <= 0 then return end
  local ok, _Player
  if framework == 'qbx' and GetResourceState('qbx_core') == 'started' then
    ok, _Player = pcall(function() return exports.qbx_core:GetPlayer(src) end)
    if ok and _Player and _Player.Functions then
      _Player.Functions.RemoveMoney('cash', amount_major, reason)
    end
  elseif framework == 'qb' and GetResourceState('qb-core') == 'started' then
    local cok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if cok and type(core) == 'table' then
      local Player = core.Functions.GetPlayer(tonumber(src))
      if Player and Player.Functions then
        Player.Functions.RemoveMoney('cash', amount_major, reason)
      end
    end
  elseif framework == 'esx' and GetResourceState('es_extended') == 'started' then
    local cok, esx = pcall(function() return exports['es_extended']:getSharedObject() end)
    if cok and type(esx) == 'table' then
      local xPlayer = esx.GetPlayerFromId(tonumber(src))
      if xPlayer and type(xPlayer.removeMoney) == 'function' then
        xPlayer.removeMoney(amount_major)
      end
    end
  end
end

-- -----------------------------------------------------------------------------
-- §3. Session — returns terminal info for the FE
-- -----------------------------------------------------------------------------

--- Session(ctx) — non-mutating. Designed to feed the FE `useAtmSessionQuery`.
---@param ctx { src, actor_citizen_id, terminal? }
function S.Session(ctx)
  local timer = Perf.StartTimer()

  if not Validators.IsValidCitizenId(ctx.actor_citizen_id) then
    Perf.EndTimer(timer, 'C_ATM_SESSION', { tier = Enums.TIER.TIER_1_READ })
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end

  local terminal_id    = _terminal_id_from_ctx(ctx)
  local location_label = (ctx.terminal and type(ctx.terminal.location_label) == 'string')
                          and ctx.terminal.location_label
                          or 'Los Santos ATM'

  -- Pull the player's first checking account to populate balance hints.
  -- The FE already has the bootstrap snapshot for the source of truth, so this
  -- is purely a UX pre-fill / terminal context payload.
  local accounts = AccountsRepo.ListByCitizen(ctx.actor_citizen_id, 1) or {}
  local primary  = accounts[1] or {}

  -- Per-card daily limit isn't known until card selection (FE picks) — at this
  -- stage we return the bank-level default from Economy or a fallback.
  local default_daily = Economy.DailyTransferCap and Economy.DailyTransferCap() or DEFAULT_DAILY_LIMIT_FALLBACK

  Perf.EndTimer(timer, 'C_ATM_SESSION', { tier = Enums.TIER.TIER_1_READ })

  return { ok = true, data = {
    terminal_id          = terminal_id,
    location_label       = location_label,
    mode                 = 'simulation',  -- legacy field retained for FE contract
    online               = true,
    hmac_ready           = false,         -- NUI flow doesn't use HMAC
    camera_check         = 'clear',
    cash_available_minor = DEFAULT_TERMINAL_CASH_MINOR,
    daily_limit_minor    = default_daily,
    remaining_limit_minor = default_daily,
    denominations        = {
      { value_minor = 2000,  available_count = 200 },
      { value_minor = 5000,  available_count = 120 },
      { value_minor = 10000, available_count = 80  },
      { value_minor = 20000, available_count = 40  },
    },
    account = {
      iban_masked    = (type(primary.iban) == 'string' and primary.iban:sub(-4)) or '----',
      balance_minor  = math.floor((tonumber(primary.balance_minor) or 0)),
      savings_minor  = math.floor((tonumber(primary.savings_minor) or 0)),
      status         = primary.is_frozen == 1 and 'frozen' or 'active',
    },
    card    = {
      card_id        = '',
      label          = 'Pending selection',
      pan_masked     = '**** **** **** ----',
      status         = 'active',
    },
    events  = {},
    fetched_at_ms = now_ms(),
  } }
end

-- -----------------------------------------------------------------------------
-- §4. VerifyPin — per-card PIN check, grants ATM token on success
-- -----------------------------------------------------------------------------

--- VerifyPin(ctx).
---@param ctx { src, actor_citizen_id, card_id, pin, terminal? }
function S.VerifyPin(ctx)
  local timer = Perf.StartTimer()

  local citizen_id = ctx.actor_citizen_id
  if not Validators.IsValidCitizenId(citizen_id) then
    Perf.EndTimer(timer, 'C_ATM_VERIFY_PIN', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  if type(ctx.card_id) ~= 'string' or #ctx.card_id == 0 then
    Perf.EndTimer(timer, 'C_ATM_VERIFY_PIN', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'card_id' }) }
  end
  if type(ctx.pin) ~= 'string' or #ctx.pin ~= 4 or not ctx.pin:match('^%d%d%d%d$') then
    Perf.EndTimer(timer, 'C_ATM_VERIFY_PIN', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'pin' }) }
  end

  local card = CardsRepo.GetForAuth(ctx.card_id)
  if not card then
    Perf.EndTimer(timer, 'C_ATM_VERIFY_PIN', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('CARD_NOT_FOUND') }
  end
  if card.owner_citizen_id ~= citizen_id then
    -- Audit potential card-theft attempt
    Audit.Write({
      event_type        = Enums.AUDIT_EVENT_TYPE.ATM_PIN_VERIFY_FAIL,
      actor_citizen_id  = citizen_id,
      actor_src         = ctx.src,
      event_data        = {
        card_id     = ctx.card_id,
        reason      = 'owner_mismatch',
        terminal_id = _terminal_id_from_ctx(ctx),
      },
    })
    Perf.EndTimer(timer, 'C_ATM_VERIFY_PIN', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH') }
  end
  if card.state ~= 'active' then
    Perf.EndTimer(timer, 'C_ATM_VERIFY_PIN', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ATM_PIN_LOCKED', { state = card.state }) }
  end

  local supplied_hash = CardService.HashPin(ctx.pin, citizen_id, ctx.card_id)
  if supplied_hash ~= card.pin_hash then
    -- Failed attempt: increment counter, optionally freeze.
    CardsRepo.IncrementPinFailCount(ctx.card_id)
    local new_count = (tonumber(card.pin_attempts_failed) or 0) + 1

    Audit.Write({
      event_type        = Enums.AUDIT_EVENT_TYPE.ATM_PIN_VERIFY_FAIL,
      actor_citizen_id  = citizen_id,
      actor_src         = ctx.src,
      event_data        = {
        card_id            = ctx.card_id,
        attempts_total     = new_count,
        terminal_id        = _terminal_id_from_ctx(ctx),
      },
    })

    if new_count >= PIN_FAIL_THRESHOLD then
      CardsRepo.FreezeWithReason(ctx.card_id, 'atm_pin_attempts')
      Audit.Write({
        event_type        = Enums.AUDIT_EVENT_TYPE.ATM_CARD_AUTOFREEZE,
        actor_citizen_id  = citizen_id,
        actor_src         = ctx.src,
        event_data        = {
          card_id     = ctx.card_id,
          reason      = 'atm_pin_attempts',
          attempts    = new_count,
          terminal_id = _terminal_id_from_ctx(ctx),
        },
      })
      -- Drop bootstrap so the FE picks up the new card state immediately.
      if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
        BankApp.services.bootstrap.InvalidateCitizen(citizen_id)
      end
      Perf.EndTimer(timer, 'C_ATM_VERIFY_PIN', { tier = Enums.TIER.TIER_2_WRITE })
      return { ok = false, error = Errors.New('ATM_PIN_LOCKED', { attempts = new_count }) }
    end

    Perf.EndTimer(timer, 'C_ATM_VERIFY_PIN', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ATM_PIN_INVALID', {
      attempts_remaining = math.max(0, PIN_FAIL_THRESHOLD - new_count),
    }) }
  end

  -- Successful verification.
  CardsRepo.ResetPinFailCount(ctx.card_id)
  local terminal_id = _terminal_id_from_ctx(ctx)
  local grant_id, expires_at_ms = _store_grant(citizen_id, ctx.card_id, terminal_id)

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.ATM_PIN_VERIFY_OK,
    actor_citizen_id  = citizen_id,
    actor_src         = ctx.src,
    event_data        = {
      card_id     = ctx.card_id,
      terminal_id = terminal_id,
    },
  })

  Perf.EndTimer(timer, 'C_ATM_VERIFY_PIN', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = {
    grant_id      = grant_id,
    expires_at_ms = expires_at_ms,
    card_id       = ctx.card_id,
  } }
end

-- -----------------------------------------------------------------------------
-- §5. NuiWithdraw — debit balance using a valid grant
-- -----------------------------------------------------------------------------

--- Per-card daily ATM withdrawal cap. We DO honour `card.daily_limit` for
--- ATM ops too (interpretation: "max spent per day via this card, regardless
--- of channel"). This is conservative — easy to relax later if banker policy
--- prefers separate ATM caps.
local function _enforce_daily_limit(card)
  local limit = _card_daily_limit_minor(card)
  local used  = _card_daily_used_minor(card)
  return limit, used, math.max(0, limit - used)
end

--- Atomic: debit account balance + bump card.daily_used_today by amount/100.
--- Both must succeed in one transaction or neither.
local SQL_BUMP_CARD_DAILY = [[
UPDATE sonar_bank_physical_cards
SET daily_used_today  = daily_used_today + (? / 100.0),
    monthly_used      = COALESCE(monthly_used, 0) + (? / 100.0)
WHERE id = ?
]]

--- NuiWithdraw(ctx).
---@param ctx { src, actor_citizen_id, card_id, grant_id, amount_minor, terminal? }
function S.NuiWithdraw(ctx)
  local timer = Perf.StartTimer()

  local citizen_id = ctx.actor_citizen_id
  if not Validators.IsValidCitizenId(citizen_id) then
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  if type(ctx.card_id) ~= 'string' or #ctx.card_id == 0 then
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'card_id' }) }
  end
  if not Validators.IsValidAmountMinor(ctx.amount_minor) then
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_AMOUNT') }
  end
  if type(ctx.grant_id) ~= 'string' or #ctx.grant_id == 0 then
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ATM_GRANT_INVALID') }
  end

  local grant = _consume_grant(citizen_id, ctx.card_id, ctx.grant_id)
  if not grant then
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ATM_GRANT_INVALID') }
  end

  local card = CardsRepo.GetForAuth(ctx.card_id)
  if not card then
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('CARD_NOT_FOUND') }
  end
  if card.owner_citizen_id ~= citizen_id then
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH') }
  end
  if card.state ~= 'active' then
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ATM_PIN_LOCKED', { state = card.state }) }
  end

  -- Daily card limit check
  local _, _, daily_remaining = _enforce_daily_limit(card)
  if ctx.amount_minor > daily_remaining then
    Audit.Write({
      event_type        = Enums.AUDIT_EVENT_TYPE.ATM_FAILED,
      actor_citizen_id  = citizen_id,
      actor_src         = ctx.src,
      target_iban       = card.account_iban,
      event_data        = {
        reason             = 'daily_limit_exceeded',
        amount_minor       = ctx.amount_minor,
        daily_remaining    = daily_remaining,
        card_id            = ctx.card_id,
        terminal_id        = _terminal_id_from_ctx(ctx),
      },
    })
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('LIMIT_EXCEEDED', {
      remaining_minor = daily_remaining,
    }) }
  end

  -- Funds check
  local row = AccountsRepo.GetByIban(card.account_iban)
  if not row then
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ACCOUNT_NOT_FOUND', { iban = card.account_iban }) }
  end
  if (tonumber(row.balance_minor) or 0) < ctx.amount_minor then
    Audit.Write({
      event_type        = Enums.AUDIT_EVENT_TYPE.ATM_FAILED,
      actor_citizen_id  = citizen_id,
      actor_src         = ctx.src,
      target_iban       = card.account_iban,
      event_data        = {
        reason       = 'insufficient_funds',
        amount_minor = ctx.amount_minor,
        card_id      = ctx.card_id,
        terminal_id  = _terminal_id_from_ctx(ctx),
      },
    })
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS') }
  end

  -- Atomic: debit balance + bump card daily/monthly counters + insert txn row.
  local debit_q = AccountsRepo.BuildDebitBalanceQuery(card.account_iban, ctx.amount_minor)
  local card_q  = {
    query  = SQL_BUMP_CARD_DAILY,
    values = { ctx.amount_minor, ctx.amount_minor, ctx.card_id },
  }
  local ts = os.time() * 1000
  local txn_id = UUID.V4()
  local txn_q = TransactionsRepo.BuildSingleDebitQuery({
    iban            = card.account_iban,
    amount_minor    = ctx.amount_minor,
    category        = 'withdrawal',
    reason          = ('ATM withdrawal — %s'):format(_terminal_id_from_ctx(ctx)),
    txn_id          = txn_id,
    timestamp_ms    = ts,
    idempotency_key = txn_id,
  })
  local ok, tx_err = DB.Transaction({ debit_q, card_q, txn_q })
  if not ok then
    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = tx_err }
  end

  local terminal_id = _terminal_id_from_ctx(ctx)

  -- Hand the player physical cash. If this fails we MUST roll back the debit
  -- so the customer doesn't lose money to a framework outage.
  local cash_ok, framework, cash_err = _give_cash_to_player(
    ctx.src, ctx.amount_minor, ('atm_withdraw:%s'):format(terminal_id)
  )
  if not cash_ok then
    -- Re-credit the account: cancel the debit by transferring the same amount back.
    local credit_q = AccountsRepo.BuildCreditBalanceQuery(card.account_iban, ctx.amount_minor)
    local card_undo_q = {
      query  = [[UPDATE sonar_bank_physical_cards
                 SET daily_used_today = GREATEST(0, daily_used_today - (? / 100.0)),
                     monthly_used     = GREATEST(0, COALESCE(monthly_used,0) - (? / 100.0))
                 WHERE id = ?]],
      values = { ctx.amount_minor, ctx.amount_minor, ctx.card_id },
    }
    DB.Transaction({ credit_q, card_undo_q })

    Audit.Write({
      event_type        = Enums.AUDIT_EVENT_TYPE.ATM_FAILED,
      actor_citizen_id  = citizen_id,
      actor_src         = ctx.src,
      target_iban       = card.account_iban,
      event_data        = {
        reason       = 'cash_give_failed',
        framework    = framework,
        framework_err= cash_err,
        amount_minor = ctx.amount_minor,
        card_id      = ctx.card_id,
        terminal_id  = terminal_id,
      },
    })

    Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ATM_TERMINAL_OFFLINE', {
      reason = cash_err or 'cash_dispenser_unavailable',
    }) }
  end

  -- Audit success
  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.ATM_NUI_WITHDRAW,
    actor_citizen_id  = citizen_id,
    actor_src         = ctx.src,
    target_iban       = card.account_iban,
    event_data        = {
      amount_minor = ctx.amount_minor,
      card_id      = ctx.card_id,
      terminal_id  = terminal_id,
      grant_id     = ctx.grant_id,
      framework    = framework,
    },
  })

  -- Publish balance update (StateBag + NUI net event)
  local fresh = AccountsRepo.GetBalance(card.account_iban)
  if fresh then
    Publish.PublishBalanceUpdate(
      ctx.src, citizen_id,
      tonumber(fresh.balance_minor) or 0,
      tonumber(fresh.savings_minor) or 0,
      { reason = 'atm_nui_withdraw', terminal_id = terminal_id }
    )
  end

  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(citizen_id)
  end

  Perf.EndTimer(timer, 'C_ATM_NUI_WITHDRAW', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = {
    iban         = card.account_iban,
    amount_minor = ctx.amount_minor,
    new_balance  = fresh and tonumber(fresh.balance_minor) or nil,
    terminal_id  = terminal_id,
  } }
end

-- -----------------------------------------------------------------------------
-- §6. NuiDeposit — physical cash → bank balance (mirror of NuiWithdraw)
-- -----------------------------------------------------------------------------

--- NuiDeposit(ctx).
---@param ctx { src, actor_citizen_id, card_id, grant_id, amount_minor, terminal? }
function S.NuiDeposit(ctx)
  local timer = Perf.StartTimer()

  local citizen_id = ctx.actor_citizen_id
  if not Validators.IsValidCitizenId(citizen_id) then
    Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  if type(ctx.card_id) ~= 'string' or #ctx.card_id == 0 then
    Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'card_id' }) }
  end
  if not Validators.IsValidAmountMinor(ctx.amount_minor) then
    Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_AMOUNT') }
  end
  if type(ctx.grant_id) ~= 'string' or #ctx.grant_id == 0 then
    Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ATM_GRANT_INVALID') }
  end

  local grant = _consume_grant(citizen_id, ctx.card_id, ctx.grant_id)
  if not grant then
    Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ATM_GRANT_INVALID') }
  end

  local card = CardsRepo.GetForAuth(ctx.card_id)
  if not card then
    Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('CARD_NOT_FOUND') }
  end
  if card.owner_citizen_id ~= citizen_id then
    Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH') }
  end
  if card.state ~= 'active' then
    Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ATM_PIN_LOCKED', { state = card.state }) }
  end

  local terminal_id = _terminal_id_from_ctx(ctx)

  -- §6.1 Pull cash from the player. If they don't have enough, abort BEFORE
  -- any DB mutation so the ledger is not affected.
  local cash_ok, framework, cash_err = _take_cash_from_player(
    ctx.src, ctx.amount_minor, ('atm_deposit:%s'):format(terminal_id)
  )
  if not cash_ok then
    Audit.Write({
      event_type        = Enums.AUDIT_EVENT_TYPE.ATM_FAILED,
      actor_citizen_id  = citizen_id,
      actor_src         = ctx.src,
      target_iban       = card.account_iban,
      event_data        = {
        reason       = 'cash_take_failed',
        framework    = framework,
        framework_err= cash_err,
        amount_minor = ctx.amount_minor,
        card_id      = ctx.card_id,
        terminal_id  = terminal_id,
      },
    })
    Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
    if cash_err == 'insufficient_cash' then
      return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS', { reason = 'insufficient_cash_on_hand' }) }
    end
    return { ok = false, error = Errors.New('ATM_TERMINAL_OFFLINE', { reason = cash_err or 'cash_collector_unavailable' }) }
  end

  -- §6.2 Credit the account + insert txn row. If this fails, refund the cash (rollback).
  local credit_q = AccountsRepo.BuildCreditBalanceQuery(card.account_iban, ctx.amount_minor)
  local ts = os.time() * 1000
  local txn_id = UUID.V4()
  local txn_q = TransactionsRepo.BuildSingleCreditQuery({
    iban            = card.account_iban,
    amount_minor    = ctx.amount_minor,
    category        = 'deposit',
    reason          = ('ATM deposit — %s'):format(terminal_id),
    txn_id          = txn_id,
    timestamp_ms    = ts,
    idempotency_key = txn_id,
  })
  local ok, tx_err = DB.Transaction({ credit_q, txn_q })
  if not ok then
    _refund_cash_from_player(ctx.src, ctx.amount_minor, framework, ('atm_deposit_rollback:%s'):format(terminal_id))
    Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = tx_err }
  end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.ATM_NUI_DEPOSIT,
    actor_citizen_id  = citizen_id,
    actor_src         = ctx.src,
    target_iban       = card.account_iban,
    event_data        = {
      amount_minor = ctx.amount_minor,
      card_id      = ctx.card_id,
      terminal_id  = terminal_id,
      framework    = framework,
      grant_id     = ctx.grant_id,
    },
  })

  local fresh = AccountsRepo.GetBalance(card.account_iban)
  if fresh then
    Publish.PublishBalanceUpdate(
      ctx.src, citizen_id,
      tonumber(fresh.balance_minor) or 0,
      tonumber(fresh.savings_minor) or 0,
      { reason = 'atm_nui_deposit', terminal_id = terminal_id }
    )
  end

  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(citizen_id)
  end

  Perf.EndTimer(timer, 'C_ATM_NUI_DEPOSIT', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = {
    iban         = card.account_iban,
    amount_minor = ctx.amount_minor,
    new_balance  = fresh and tonumber(fresh.balance_minor) or nil,
    terminal_id  = terminal_id,
  } }
end

return S
