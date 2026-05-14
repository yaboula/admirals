-- =============================================================================
-- SONAR Bank App — services/recipients_service.lua
-- =============================================================================
-- REQ-FE-002 — Recent recipients + saved recipients service.
--
-- Performance contract:
--   - p99 latency < 30 ms.
--   - Per-citizen LRU cache TTL = 60 s (Config.Cache.RECENT_RECIPIENTS_TTL_MS).
--   - Cache invalidated by transfer commit (calls InvalidateCitizen).
--
-- Returned shape (recent recipients):
--   {
--     recipients = [
--       {
--         counterpart_iban    = string,
--         alias               = string|nil,  (joined from saved_recipients)
--         is_favorite         = boolean,
--         last_transfer_ms    = integer,
--         transfer_count      = integer,
--         preset_amounts      = [integer, ...],  -- top-N most recent amounts (in minor units)
--         last_reason         = string|nil,
--       }, ...
--     ],
--     fetched_at_ms = integer,
--     cached        = boolean,
--   }
-- =============================================================================

BankApp.services.recipients = {}
local S = BankApp.services.recipients

local Validators = BankApp.lib.validators
local Errors     = BankApp.lib.errors
local Perf       = BankApp.lib.perf
local Enums      = BankApp.lib.enums
local Config     = BankApp.Config

local TransactionsRepo = BankApp.repos.transactions
local RecipientsRepo   = BankApp.repos.recipients

-- -----------------------------------------------------------------------------
-- §1. LRU cache
-- -----------------------------------------------------------------------------

local _cache = {}  -- citizen_id → { recipients = [...], expires_ms }

local function now_ms()
  return os.time() * 1000 + math.floor((os.clock() % 1) * 1000)
end

local function cache_get(citizen_id)
  if not Config.Features.ENABLE_RECENT_RECIPIENTS_CACHE then return nil end
  local entry = _cache[citizen_id]
  if not entry then return nil end
  if entry.expires_ms < now_ms() then
    _cache[citizen_id] = nil
    return nil
  end
  return entry.recipients
end

local function cache_set(citizen_id, recipients)
  if not Config.Features.ENABLE_RECENT_RECIPIENTS_CACHE then return end
  _cache[citizen_id] = {
    recipients = recipients,
    expires_ms = now_ms() + Config.Cache.RECENT_RECIPIENTS_TTL_MS,
  }
end

--- InvalidateCitizen — transfer service calls este on commit.
function S.InvalidateCitizen(citizen_id)
  _cache[citizen_id] = nil
end

-- -----------------------------------------------------------------------------
-- §2. CSV → array helper
-- -----------------------------------------------------------------------------

local function csv_to_int_array(csv)
  if type(csv) ~= 'string' or #csv == 0 then return {} end
  local out = {}
  for v in csv:gmatch('([^,]+)') do
    local n = tonumber(v)
    if n then out[#out + 1] = math.floor(n) end
  end
  return out
end

-- -----------------------------------------------------------------------------
-- §3. Public — GetRecent
-- -----------------------------------------------------------------------------

--- GetRecent — REQ-FE-002 main entry point.
---@param citizen_id string
---@return table|nil { recipients=[...], fetched_at_ms, cached }
---@return table|nil err
function S.GetRecent(citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then
    return nil, Errors.New('INVALID_CITIZEN_ID')
  end

  local cached = cache_get(citizen_id)
  if cached then
    return {
      recipients    = cached,
      fetched_at_ms = now_ms(),
      cached        = true,
    }, nil
  end

  local timer = Perf.StartTimer()

  -- Fetch raw recent recipients (aggregated counterpart_iban rows)
  local rows, err = TransactionsRepo.GetRecentRecipients(
    citizen_id,
    Config.RecentRecipients.WINDOW_DAYS,
    Config.RecentRecipients.LIMIT,
    Config.RecentRecipients.PRESET_AMOUNTS
  )
  if err then
    Perf.EndTimer(timer, 'sonar:bank:transfer:recentRecipients', { tier = Enums.TIER.TIER_1_READ })
    return nil, err
  end

  -- Fetch saved recipients (alias + favorite flag) — small list
  local saved, saved_err = RecipientsRepo.ListByCitizen(citizen_id, 200)
  if saved_err then
    -- Non-fatal: continue without aliases
    saved = {}
  end

  -- Build alias lookup
  local alias_lookup = {}
  for _, sr in ipairs(saved) do
    alias_lookup[sr.counterpart_iban] = {
      alias       = sr.alias,
      is_favorite = sr.is_favorite == 1 or sr.is_favorite == true,
    }
  end

  -- Compose final shape
  local recipients = {}
  local seen_recipients = {}
  for i, row in ipairs(rows) do
    local meta = alias_lookup[row.counterpart_iban] or {}
    recipients[i] = {
      counterpart_iban    = row.counterpart_iban,
      alias               = meta.alias,
      is_favorite         = meta.is_favorite or false,
      last_transfer_ms    = tonumber(row.last_transfer_ms) or 0,
      transfer_count      = tonumber(row.transfer_count) or 0,
      preset_amounts      = csv_to_int_array(row.recent_amounts_csv),
      last_reason         = row.last_reason and row.last_reason ~= '' and row.last_reason or nil,
    }
    seen_recipients[row.counterpart_iban] = true
  end


  for _, sr in ipairs(saved) do
    if not seen_recipients[sr.counterpart_iban] then
      recipients[#recipients + 1] = {
        counterpart_iban    = sr.counterpart_iban,
        alias               = sr.alias,
        is_favorite         = sr.is_favorite == 1 or sr.is_favorite == true,
        last_transfer_ms    = tonumber(sr.created_ms) or 0,
        transfer_count      = 0,
        preset_amounts      = {},
        last_reason         = nil,
      }
    end
  end

  cache_set(citizen_id, recipients)

  local elapsed = Perf.EndTimer(timer, 'sonar:bank:transfer:recentRecipients', { tier = Enums.TIER.TIER_1_READ })

  return {
    recipients    = recipients,
    fetched_at_ms = now_ms(),
    cached        = false,
    duration_ms   = elapsed,
  }, nil
end

-- -----------------------------------------------------------------------------
-- §4. Saved recipients management (CRUD)
-- -----------------------------------------------------------------------------

--- SaveRecipient — upsert (favorite flag optional).
---@param citizen_id string
---@param counterpart_iban string
---@param alias string|nil
---@param is_favorite boolean|nil
---@return boolean ok, table|nil err
function S.SaveRecipient(citizen_id, counterpart_iban, alias, is_favorite)
  if not Validators.IsValidCitizenId(citizen_id) then
    return false, Errors.New('INVALID_CITIZEN_ID')
  end
  local norm_iban = Validators.NormalizeIBAN(counterpart_iban)
  if not norm_iban then
    return false, Errors.New('INVALID_IBAN')
  end
  if alias ~= nil then
    alias = Validators.SanitizeString(alias, 64)
  end

  local _, err = RecipientsRepo.Upsert(citizen_id, norm_iban, alias, is_favorite)
  if err then return false, err end

  S.InvalidateCitizen(citizen_id)
  return true, nil
end

--- DeleteRecipient
function S.DeleteRecipient(citizen_id, counterpart_iban)
  if not Validators.IsValidCitizenId(citizen_id) then
    return false, Errors.New('INVALID_CITIZEN_ID')
  end
  local norm_iban = Validators.NormalizeIBAN(counterpart_iban)
  if not norm_iban then
    return false, Errors.New('INVALID_IBAN')
  end
  local _, err = RecipientsRepo.Delete(citizen_id, norm_iban)
  if err then return false, err end
  S.InvalidateCitizen(citizen_id)
  return true, nil
end

--- ToggleFavorite
function S.ToggleFavorite(citizen_id, counterpart_iban, is_favorite)
  if not Validators.IsValidCitizenId(citizen_id) then
    return false, Errors.New('INVALID_CITIZEN_ID')
  end
  local norm_iban = Validators.NormalizeIBAN(counterpart_iban)
  if not norm_iban then
    return false, Errors.New('INVALID_IBAN')
  end
  local _, err = RecipientsRepo.SetFavorite(citizen_id, norm_iban, is_favorite and true or false)
  if err then return false, err end
  S.InvalidateCitizen(citizen_id)
  return true, nil
end

return S
