-- =============================================================================
-- SONAR Bank App — services/banker/branding.lua
-- =============================================================================
-- Branding editor (F4). Stores per-field overrides in sonar_bank_config_overrides
-- using the prefix `branding_*`. The bootstrap snapshot already exposes the
-- effective branding; this service only writes / clears overrides.
--
--   Editable fields:
--     - bank_name        (string, 1..32)
--     - primary_color    (hex `#RRGGBB`)
--     - accent_color     (hex `#RRGGBB`)
--     - welcome_message  (string, 0..160)
--     - logo_url         (https://... or '' to clear)
-- =============================================================================

BankApp.services.banker = BankApp.services.banker or {}
BankApp.services.banker.branding = {}
local S = BankApp.services.banker.branding

local Config      = BankApp.Config
local Errors      = BankApp.lib.errors
local Audit       = BankApp.lib.audit
local Enums       = BankApp.lib.enums
local BankerAuth  = BankApp.lib.banker_auth
local BankerRepo  = BankApp.repos.banker
local Validators  = BankApp.lib.validators

local function _config()
  return (Config.Banker and Config.Banker.Branding) or {}
end

local function _decode(s)
  if type(s) ~= 'string' or s == '' then return nil end
  local ok, v = pcall(json.decode, s)
  if not ok then return nil end
  return v
end

local function _encode(v) return json.encode({ value = v }) end

local KEY_PREFIX = 'branding_'
local FIELDS = { 'bank_name', 'primary_color', 'accent_color', 'welcome_message', 'logo_url' }

local function _hex_color_ok(v)
  if type(v) ~= 'string' then return false end
  return v:match('^#%x%x%x%x%x%x$') ~= nil
end

local function _validate(field, value)
  if field == 'bank_name' then
    if type(value) ~= 'string' or #value < 1 or #value > 32 then
      return false, 'bank_name must be 1..32 chars'
    end
  elseif field == 'primary_color' or field == 'accent_color' then
    if not _hex_color_ok(value) then
      return false, field .. ' must be #RRGGBB'
    end
  elseif field == 'welcome_message' then
    if type(value) ~= 'string' or #value > 160 then
      return false, 'welcome_message must be ≤ 160 chars'
    end
  elseif field == 'logo_url' then
    if type(value) ~= 'string' or #value > 256 then
      return false, 'logo_url too long'
    end
    if value ~= '' and not value:match('^https?://') then
      return false, 'logo_url must be empty or start with http(s)://'
    end
  else
    return false, 'unknown field'
  end
  return true
end

-- ---------------------------------------------------------------------------
-- §1. GetSnapshot — current effective + per-field override status
-- ---------------------------------------------------------------------------
function S.GetSnapshot(ctx)
  local _, role, auth_err = BankerAuth.RequireBanker(ctx.src, 'branding_view')
  if auth_err then return { ok = false, error = auth_err } end

  local cfg = _config()
  local rows = BankerRepo.ListConfigOverrides() or {}
  local override_map = {}
  for _, r in ipairs(rows) do
    if r.config_key:sub(1, #KEY_PREFIX) == KEY_PREFIX then
      local decoded = _decode(r.value_json)
      override_map[r.config_key:sub(#KEY_PREFIX + 1)] = {
        value           = decoded and decoded.value,
        updated_at_ms   = (tonumber(r.updated_at) or 0) * 1000,
        updated_by      = r.updated_by_citizen_id,
        updated_by_role = r.updated_by_role,
      }
    end
  end

  local fields = {}
  for _, field in ipairs(FIELDS) do
    local default = cfg[field .. '_default']
    local ov = override_map[field]
    local effective = (ov and ov.value) or default or ''
    fields[field] = {
      effective       = effective,
      default         = default or '',
      override_raw    = ov and ov.value or nil,
      has_override    = ov ~= nil,
      updated_at_ms   = ov and ov.updated_at_ms or nil,
      updated_by      = ov and ov.updated_by or nil,
      updated_by_role = ov and ov.updated_by_role or nil,
    }
  end

  return {
    ok = true,
    data = {
      fields    = fields,
      can_edit  = BankerAuth.HasCapability(role, 'branding_edit'),
      role      = role,
      fetched_at_ms = os.time() * 1000,
    },
  }
end

-- ---------------------------------------------------------------------------
-- §2. Set — write override for a single field
-- ---------------------------------------------------------------------------
function S.Set(ctx)
  local actor_id, role, auth_err = BankerAuth.RequireBanker(ctx.src, 'branding_edit')
  if auth_err then return { ok = false, error = auth_err } end

  local field = ctx.field
  local value = ctx.value
  local ok, why = _validate(field, value)
  if not ok then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = field, reason = why }) }
  end

  -- Sanitize strings to strip control chars (we already length-checked)
  if type(value) == 'string' then
    value = Validators.SanitizeString(value, 256) or value
  end

  local _, ins_err = BankerRepo.UpsertConfigOverride({
    config_key            = KEY_PREFIX .. field,
    value_json            = _encode(value),
    updated_by_citizen_id = actor_id,
    updated_by_role       = role,
  })
  if ins_err then return { ok = false, error = ins_err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_BRANDING_CHANGE,
    actor_citizen_id  = actor_id,
    actor_src         = ctx.src,
    actor_role        = role,
    event_data        = { field = field, new_value = value, via = 'banker' },
  })

  -- Drop the customer bootstrap meta memo so the next snapshot reflects the
  -- new branding immediately (otherwise customers would wait up to 30s).
  local Bootstrap = BankApp.services and BankApp.services.bootstrap
  if Bootstrap and Bootstrap.InvalidateAppMeta then Bootstrap.InvalidateAppMeta() end

  return { ok = true, data = { field = field, value = value, applied_at_ms = os.time() * 1000 } }
end

-- ---------------------------------------------------------------------------
-- §3. Reset — drop override for a single field (revert to default)
-- ---------------------------------------------------------------------------
function S.Reset(ctx)
  local actor_id, role, auth_err = BankerAuth.RequireBanker(ctx.src, 'branding_edit')
  if auth_err then return { ok = false, error = auth_err } end

  local field = ctx.field
  if type(field) ~= 'string' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'field' }) }
  end

  local _, del_err = BankerRepo.DeleteConfigOverride(KEY_PREFIX .. field)
  if del_err then return { ok = false, error = del_err } end

  Audit.Write({
    event_type        = Enums.AUDIT_EVENT_TYPE.BANKER_BRANDING_CHANGE,
    actor_citizen_id  = actor_id,
    actor_src         = ctx.src,
    actor_role        = role,
    event_data        = { field = field, reset = true, via = 'banker' },
  })

  local Bootstrap = BankApp.services and BankApp.services.bootstrap
  if Bootstrap and Bootstrap.InvalidateAppMeta then Bootstrap.InvalidateAppMeta() end

  return { ok = true, data = { field = field, reset = true } }
end
