-- =============================================================================
-- SONAR Bank App — lib/economy.lua
-- =============================================================================
-- Single source of truth for "effective" economic parameters (rates, fees,
-- limits). Resolves the value the same way every customer-facing service
-- should: config default → optional banker override → clamp to band.
--
--   Public API:
--     - Economy.GetEffective(key)           — number (clamped)
--     - Economy.GetBand(key)                — { default, min, max, step }
--     - Economy.ApplyFeeBps(amount, bps)    — integer minor fee
--     - Economy.FeeForTransfer(amount)      — convenience (uses transfer_fee_bps)
--     - Economy.FeeForAtm(amount)           — convenience (atm_fee_minor_flat)
--     - Economy.DailyTransferCap()          — convenience (daily_transfer_limit_minor)
--     - Economy.CardIssueExtraFee()         — convenience (card_issue_fee_minor)
--
--   Architectural notes:
--     - All values clamp defensively to [min, max] even if an override is
--       stale or corrupt. Customer flows can trust the returned number.
--     - Reads have a tiny in-memory cache (5s TTL) to avoid hammering the
--       overrides table on hot paths. Cache is invalidated implicitly by
--       TTL expiration; banker write paths can call FlushCache() to refresh
--       immediately if desired.
--     - If `Config.Banker.Enabled == false`, overrides are NEVER consulted
--       (defaults only). This makes the bank fully usable without the panel.
-- =============================================================================

BankApp.lib = BankApp.lib or {}
BankApp.lib.economy = {}
local E = BankApp.lib.economy

local Config = BankApp.Config

local CACHE_TTL_MS = 5000          -- 5s in-memory cache
local cache = {}                   -- key → { value, expires_at_ms }

local function _now_ms() return os.time() * 1000 end

local function _band(key)
  return ((Config.Banker or {}).Limits or {})[key]
end

local function _clamp(value, band)
  if value < band.min then return band.min end
  if value > band.max then return band.max end
  return value
end

local function _decode_override(value_json)
  if type(value_json) ~= 'string' or value_json == '' then return nil end
  local ok, decoded = pcall(json.decode, value_json)
  if not ok or type(decoded) ~= 'table' then return nil end
  if type(decoded.value) ~= 'number' then return nil end
  return decoded.value
end

-- ---------------------------------------------------------------------------
-- §1. GetBand / GetEffective
-- ---------------------------------------------------------------------------
function E.GetBand(key)
  return _band(key)
end

function E.GetEffective(key)
  local band = _band(key)
  if not band then return nil end

  -- Fast path: cache hit
  local entry = cache[key]
  if entry and entry.expires_at_ms > _now_ms() then
    return entry.value
  end

  local value = band.default

  -- Banker override lookup is conditional: only if the panel is enabled
  -- AND the repo is loaded (banker dependency soft).
  local banker_enabled = (Config.Banker and Config.Banker.Enabled) ~= false
  if banker_enabled and BankApp.repos and BankApp.repos.banker
     and BankApp.repos.banker.GetConfigOverride then
    local ok, row = pcall(BankApp.repos.banker.GetConfigOverride, key)
    if ok and row then
      local override_value = _decode_override(row.value_json)
      if override_value ~= nil then value = override_value end
    end
  end

  value = _clamp(value, band)

  cache[key] = { value = value, expires_at_ms = _now_ms() + CACHE_TTL_MS }
  return value
end

function E.FlushCache(key)
  if key then cache[key] = nil else cache = {} end
end

-- ---------------------------------------------------------------------------
-- §2. Convenience helpers (used by customer services to avoid string keys)
-- ---------------------------------------------------------------------------

--- ApplyFeeBps: returns the minor-unit fee for a given amount and bps rate.
---   Rounding: ceiling — the bank never under-charges (defensive).
function E.ApplyFeeBps(amount_minor, fee_bps)
  if not amount_minor or amount_minor <= 0 or not fee_bps or fee_bps <= 0 then
    return 0
  end
  -- fee = ceil(amount * bps / 10000)
  local num = amount_minor * fee_bps
  local fee = math.floor(num / 10000)
  if (num % 10000) ~= 0 then fee = fee + 1 end
  return fee
end

function E.FeeForTransfer(amount_minor)
  local bps = E.GetEffective('transfer_fee_bps') or 0
  return E.ApplyFeeBps(amount_minor, bps), bps
end

function E.FeeForAtm(_amount_minor)
  -- ATM fee is a flat amount (not bps).
  return E.GetEffective('atm_fee_minor_flat') or 0
end

function E.DailyTransferCap()
  return E.GetEffective('daily_transfer_limit_minor') or 0
end

function E.CardIssueExtraFee()
  return E.GetEffective('card_issue_fee_minor') or 0
end

function E.SavingsInterestBps()
  return E.GetEffective('savings_interest_rate_bps') or 0
end

function E.SharedAccountMinBalance()
  return E.GetEffective('shared_account_min_minor') or 0
end

function E.LoanRateSpreadBps()
  return E.GetEffective('loan_rate_spread_bps') or 0
end
