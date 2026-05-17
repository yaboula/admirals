-- =============================================================================
-- SONAR Bank App — services/banker/rates.lua
-- =============================================================================
-- Rates / fees / limits editor (F3).
--
--   Architectural contract:
--     - config.lua C.Banker.Limits declares { default, min, max, step } per key.
--     - The banker can SET an override that lives in sonar_bank_config_overrides.
--     - The "effective" value at any moment is:
--           override.value if exists else config.default
--       and is ALWAYS clamped server-side to [min, max].
--     - RESET deletes the override row, reverting to config.default.
--
--   Public API (used by callbacks/banker.lua + by other services that read
--   the live banker-tunable economy parameters):
--     - GetCatalog(ctx)         — list of { key, default, min, max, step,
--                                          override, effective, last_updater }
--     - SetOverride(ctx)        — banker writes a new override (with band check)
--     - ResetOverride(ctx)      — banker drops an override (revert to default)
--     - GetEffectiveValue(key)  — internal helper for other services
-- =============================================================================

BankApp.services.banker = BankApp.services.banker or {}
BankApp.services.banker.rates = {}
local S = BankApp.services.banker.rates

local Config      = BankApp.Config
local Errors      = BankApp.lib.errors
local Audit       = BankApp.lib.audit
local Enums       = BankApp.lib.enums
local BankerAuth  = BankApp.lib.banker_auth
local BankerRepo  = BankApp.repos.banker
local Logger      = BankApp.lib.logger

local function _config()
  return Config.Banker or {}
end

local function _band(key)
  local lim = _config().Limits or {}
  return lim[key]
end

local function _decode(s)
  if type(s) ~= 'string' or s == '' then return nil end
  local ok, v = pcall(json.decode, s)
  if not ok then return nil end
  return v
end

local function _encode(v)
  return json.encode({ value = v })
end

-- ---------------------------------------------------------------------------
-- §1. Public — GetCatalog
-- ---------------------------------------------------------------------------
function S.GetCatalog(ctx)
  local _, role, auth_err = BankerAuth.RequireBanker(ctx.src, 'rates_view')
  if auth_err then return { ok = false, error = auth_err } end

  local rows, err = BankerRepo.ListConfigOverrides()
  if err then return { ok = false, error = err } end

  -- Index overrides by config_key
  local override_map = {}
  for _, r in ipairs(rows or {}) do
    local decoded = _decode(r.value_json)
    override_map[r.config_key] = {
      raw            = decoded and decoded.value,
      updated_at_ms  = (tonumber(r.updated_at) or 0) * 1000,
      updated_by     = r.updated_by_citizen_id,
      updated_by_role = r.updated_by_role,
    }
  end

  local items = {}
  for key, band in pairs(_config().Limits or {}) do
    local ov = override_map[key]
    local raw = ov and ov.raw
    local effective = raw
    if effective == nil then
      effective = band.default
    end
    -- Defensive clamp
    if effective < band.min then effective = band.min end
    if effective > band.max then effective = band.max end

    items[#items + 1] = {
      key             = key,
      default         = band.default,
      min             = band.min,
      max             = band.max,
      step            = band.step or 1,
      effective       = effective,
      override_raw    = raw,
      has_override    = raw ~= nil,
      updated_at_ms   = ov and ov.updated_at_ms or nil,
      updated_by      = ov and ov.updated_by or nil,
      updated_by_role = ov and ov.updated_by_role or nil,
    }
  end

  -- Stable order — alphabetical so the FE list is consistent
  table.sort(items, function(a, b) return a.key < b.key end)

  return {
    ok = true,
    data = {
      items     = items,
      role      = role,
      can_edit  = BankerAuth.HasCapability(role, 'rates_edit'),
      fetched_at_ms = os.time() * 1000,
    },
  }
end

-- ---------------------------------------------------------------------------
-- §2. Public — SetOverride
-- ---------------------------------------------------------------------------
function S.SetOverride(ctx)
  local actor_id, role, auth_err = BankerAuth.RequireBanker(ctx.src, 'rates_edit')
  if auth_err then return { ok = false, error = auth_err } end

  local key = type(ctx.key) == 'string' and ctx.key or nil
  if not key then return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'key' }) } end

  local band = _band(key)
  if not band then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'key', reason = 'unknown_key' }) }
  end

  local value = tonumber(ctx.value)
  if value == nil then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'value' }) }
  end
  if value < band.min or value > band.max then
    return {
      ok = false,
      error = Errors.New('AMOUNT_OUT_OF_RANGE', {
        field = key, value = value, min = band.min, max = band.max,
      }),
    }
  end

  -- Snapshot previous value for audit
  local prev_row = BankerRepo.GetConfigOverride(key)
  local prev_value = prev_row and (_decode(prev_row.value_json) or {}).value or band.default

  local _, ins_err = BankerRepo.UpsertConfigOverride({
    config_key            = key,
    value_json            = _encode(value),
    updated_by_citizen_id = actor_id,
    updated_by_role       = role,
  })
  if ins_err then return { ok = false, error = ins_err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_CONFIG_CHANGE
                       or 'banker_config_change',
    actor_citizen_id  = actor_id,
    actor_src         = ctx.src,
    actor_role        = role,
    event_data        = {
      config_key   = key,
      new_value    = value,
      prev_value   = prev_value,
      band_min     = band.min,
      band_max     = band.max,
      via          = 'banker',
    },
  })

  if Logger and Logger.Info then
    Logger.Info(('[banker.rates] override %s = %s by %s (%s)'):format(
      key, tostring(value), actor_id, role))
  end

  -- Drop downstream caches so the new rate takes effect immediately.
  local Economy = BankApp.lib and BankApp.lib.economy
  if Economy and Economy.FlushCache then Economy.FlushCache(key) end
  local Bootstrap = BankApp.services and BankApp.services.bootstrap
  if Bootstrap and Bootstrap.InvalidateAppMeta then Bootstrap.InvalidateAppMeta() end

  return { ok = true, data = { key = key, value = value, applied_at_ms = os.time() * 1000 } }
end

-- ---------------------------------------------------------------------------
-- §3. Public — ResetOverride (revert to default)
-- ---------------------------------------------------------------------------
function S.ResetOverride(ctx)
  local actor_id, role, auth_err = BankerAuth.RequireBanker(ctx.src, 'rates_edit')
  if auth_err then return { ok = false, error = auth_err } end

  local key = type(ctx.key) == 'string' and ctx.key or nil
  if not key or not _band(key) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'key' }) }
  end

  local prev_row = BankerRepo.GetConfigOverride(key)
  if not prev_row then
    -- Already at default — no-op
    return { ok = true, data = { key = key, no_op = true } }
  end
  local prev_value = (_decode(prev_row.value_json) or {}).value

  local _, del_err = BankerRepo.DeleteConfigOverride(key)
  if del_err then return { ok = false, error = del_err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_CONFIG_CHANGE
                       or 'banker_config_change',
    actor_citizen_id  = actor_id,
    actor_src         = ctx.src,
    actor_role        = role,
    event_data        = {
      config_key  = key,
      reset       = true,
      prev_value  = prev_value,
      via         = 'banker',
    },
  })

  local Economy = BankApp.lib and BankApp.lib.economy
  if Economy and Economy.FlushCache then Economy.FlushCache(key) end
  local Bootstrap = BankApp.services and BankApp.services.bootstrap
  if Bootstrap and Bootstrap.InvalidateAppMeta then Bootstrap.InvalidateAppMeta() end

  return { ok = true, data = { key = key, reset = true } }
end

-- ---------------------------------------------------------------------------
-- §4. Internal — GetEffectiveValue (used by other services / risk engine)
-- ---------------------------------------------------------------------------
function S.GetEffectiveValue(key)
  local band = _band(key)
  if not band then return nil end
  local row = BankerRepo.GetConfigOverride(key)
  local value = band.default
  if row then
    local decoded = _decode(row.value_json)
    if decoded and type(decoded.value) == 'number' then
      value = decoded.value
    end
  end
  -- Defensive clamp regardless of stored value
  if value < band.min then value = band.min end
  if value > band.max then value = band.max end
  return value
end
