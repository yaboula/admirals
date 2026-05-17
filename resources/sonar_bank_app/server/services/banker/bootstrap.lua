-- =============================================================================
-- SONAR Bank App — services/banker/bootstrap.lua
-- =============================================================================
-- Bank Owner Panel bootstrap response (F1).
--
--   Returns a single shape consumed by the FE on /banker open:
--     {
--       employee:        { id, citizen_id, role, status, salary_minor,
--                          hired_at, synthetic_admin? },
--       capabilities:    { panel_open=true, employees_hire=false, ... },
--       roles_catalog:   { ceo={weight,label}, ... },
--       limits_catalog:  { savings_interest_rate_bps={default,min,max,step}, ... },
--       branding:        { bank_name, primary_color, accent_color,
--                          welcome_message, logo_url },
--       overrides:       { config_key -> { value, updated_at,
--                                          updated_by_citizen_id } },
--       counts:          { ceo, manager, compliance_officer, advisor, teller },
--       fetched_at_ms,
--     }
--
--   Designed to be the only call needed when the panel mounts. Subsequent
--   queries hit per-feature endpoints.
-- =============================================================================

BankApp.services.banker = BankApp.services.banker or {}
BankApp.services.banker.bootstrap = {}
local S = BankApp.services.banker.bootstrap

local Config       = BankApp.Config
local BankerAuth   = BankApp.lib.banker_auth
local BankerRepo   = BankApp.repos.banker
local Errors       = BankApp.lib.errors

local function now_ms() return os.time() * 1000 end

local function _decode(json_str)
  if type(json_str) ~= 'string' or json_str == '' then return nil end
  if not _G.json or type(_G.json.decode) ~= 'function' then return json_str end
  local ok, decoded = pcall(_G.json.decode, json_str)
  if not ok then return json_str end
  return decoded
end

local function _build_branding(overrides_map)
  local b = (Config.Banker and Config.Banker.Branding) or {}
  local function pick(key, default)
    local row = overrides_map and overrides_map[key]
    if row and row.value ~= nil then return row.value end
    return default
  end
  return {
    bank_name        = pick('branding_bank_name',       b.bank_name_default),
    primary_color    = pick('branding_primary_color',   b.primary_color_default),
    accent_color     = pick('branding_accent_color',    b.accent_color_default),
    welcome_message  = pick('branding_welcome_message', b.welcome_message_default),
    logo_url         = pick('branding_logo_url',        b.logo_url_default),
  }
end

local function _index_overrides(rows)
  local map = {}
  for _, row in ipairs(rows or {}) do
    map[row.config_key] = {
      value                 = _decode(row.value_json),
      updated_at            = tonumber(row.updated_at),
      updated_by_citizen_id = row.updated_by_citizen_id,
      updated_by_role       = row.updated_by_role,
    }
  end
  return map
end

function S.GetSnapshot(ctx)
  local citizen_id, employee, err = BankerAuth.RequireBanker(ctx.src, 'panel_open')
  if err then return { ok = false, error = err } end

  local capabilities = BankerAuth.ListCapabilitiesForRole(employee.role)

  local overrides_rows, ov_err = BankerRepo.ListConfigOverrides()
  if ov_err then return { ok = false, error = ov_err } end
  local overrides_map = _index_overrides(overrides_rows)

  local counts, count_err = BankerRepo.CountActiveByRole()
  if count_err then return { ok = false, error = count_err } end

  return {
    ok = true,
    data = {
      employee = {
        id                = employee.id,
        citizen_id        = citizen_id,
        role              = employee.role,
        role_label        = (Config.Banker.Roles[employee.role] or {}).label,
        role_weight       = (Config.Banker.Roles[employee.role] or {}).weight or 0,
        status            = employee.status,
        salary_minor      = tonumber(employee.salary_minor) or 0,
        hired_at          = tonumber(employee.hired_at),
        synthetic_admin   = employee.synthetic_admin == true,
      },
      capabilities    = capabilities,
      roles_catalog   = Config.Banker.Roles,
      limits_catalog  = Config.Banker.Limits,
      missions_catalog= Config.Banker.Missions,
      branding        = _build_branding(overrides_map),
      overrides       = overrides_map,
      counts          = counts,
      fetched_at_ms   = now_ms(),
    },
  }
end
