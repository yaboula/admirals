-- =============================================================================
-- SONAR Bank App — callbacks/_wrap.lua
-- =============================================================================
-- Canonical wrapper for ALL ox_lib server callbacks. Enforces:
--   1. Auth gate            (Auth.RequireCitizen / Auth.RequireAdmin)
--   2. Rate-limit gate      (RateLimit.Check per tier; M003 special for C035)
--   3. Perf timer wrap      (Perf.StartTimer + Perf.EndTimer with budget check)
--   4. Defensive payload sanitization (must be table)
--   5. Standardized response shape:
--        success: { ok = true,  data = ... }
--        failure: { ok = false, error = { code, category, message, details } }
--   6. Exception catch (pcall handler — never crashes ox_lib worker)
--
-- API:
--   Wrap.Register(name, opts, handler)
--     where opts = {
--       tier            = Enums.TIER value (TIER_1_READ | TIER_2_WRITE | TIER_3_ADMIN)
--       require_admin   = boolean (default false — uses RequireAdmin instead of RequireCitizen)
--       skip_rate_limit = boolean (default false — only used for C001 fallback paths)
--       cb_id           = string identifier para perf bucket (e.g. 'C001', 'C006')
--     }
--     handler signature: function(src, citizen_id, payload) → result_table
--                                                          OR  { ok=false, error=... }
--
-- The wrapper is responsible for ALL cross-cutting concerns. Callback files
-- ONLY express domain logic — no auth/rate-limit/perf boilerplate copy-paste.
-- =============================================================================

BankApp.callbacks = BankApp.callbacks or {}
BankApp.callbacks._wrap = {}
local W = BankApp.callbacks._wrap

local Auth      = BankApp.lib.auth
local RateLimit = BankApp.lib.rate_limit
local Perf      = BankApp.lib.perf
local Errors    = BankApp.lib.errors
local Enums     = BankApp.lib.enums
local Config    = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. ox_lib accessor (defensive — fxmanifest pulls @ox_lib/init.lua)
-- -----------------------------------------------------------------------------

local function ox_callback_register(name, fn)
  print(('[%s][WRAP] Registering callback: %s'):format(Config.Logging.PREFIX, name))
  if _G.lib and _G.lib.callback and type(_G.lib.callback.register) == 'function' then
    print(('[%s][WRAP] Using ox_lib.callback.register for: %s'):format(Config.Logging.PREFIX, name))
    _G.lib.callback.register(name, fn)
    print(('[%s][WRAP] Successfully registered with ox_lib: %s'):format(Config.Logging.PREFIX, name))
    return true
  end
  -- Fallback: vanilla FiveM callback bus (registers as net event-based callback)
  -- ox_lib should always be present per fxmanifest dependencies — this branch
  -- is purely defensive against load-order surprises.
  print(('[%s][WRAP][WARN] ox_lib not loaded — callback %s falling back to event bus'):format(
    Config.Logging.PREFIX, name))
  RegisterNetEvent(name, function(payload, response_event)
    local src = source
    local result = fn(src, payload)
    if response_event then
      TriggerClientEvent(response_event, src, result)
    end
  end)
  return false
end

-- -----------------------------------------------------------------------------
-- §2. Standardized error → callback response converter
-- -----------------------------------------------------------------------------

local function err_to_response(err)
  if type(err) ~= 'table' then
    err = Errors.New('INTERNAL_ERROR', { reason = tostring(err):sub(1, 200) })
  end
  return {
    ok    = false,
    error = {
      code      = err.code,
      category  = err.category,
      message   = err.message,
      details   = err.details,
      retryable = err.retryable,
    },
  }
end

local function ok_to_response(data)
  -- If handler already returned a {ok=true|false} envelope, pass through.
  if type(data) == 'table' and data.ok ~= nil then
    if data.ok and data.data == nil and not data.error then
      -- Service returned just { ok = true } — wrap with empty data
      return { ok = true, data = {} }
    end
    return data
  end
  return { ok = true, data = data or {} }
end

-- -----------------------------------------------------------------------------
-- §3. Wrap.Register — main public API
-- -----------------------------------------------------------------------------

local _registered = {}  -- name → opts (debug introspection)

--- Register: register a callback with full middleware stack applied.
---@param name string canonical event name (e.g. 'sonar:bank:transfer:execute')
---@param opts table { tier, require_admin?, skip_rate_limit?, cb_id }
---@param handler function(src, citizen_id, payload) → result | error
function W.Register(name, opts, handler)
  opts = opts or {}
  local tier            = opts.tier or Enums.TIER.TIER_1_READ
  local require_admin   = opts.require_admin == true
  local admin_ace       = opts.admin_ace
  local skip_rate_limit = opts.skip_rate_limit == true
  local cb_id           = opts.cb_id or name

  if not Enums.IsValid(Enums.TIER, tier) then
    error(('[wrap.Register] invalid tier for callback %s: %s'):format(name, tostring(tier)))
  end
  if type(handler) ~= 'function' then
    error(('[wrap.Register] handler must be function for callback %s'):format(name))
  end

  _registered[name] = { tier = tier, require_admin = require_admin, cb_id = cb_id }

  ox_callback_register(name, function(src, payload)
    local timer = Perf.StartTimer()

    -- Defensive: payload must be table or nil
    if payload ~= nil and type(payload) ~= 'table' then
      Perf.EndTimer(timer, cb_id, { tier = tier })
      return err_to_response(Errors.New('VALIDATION_FAILED', {
        reason = 'payload must be a table',
        got    = type(payload),
      }))
    end
    payload = payload or {}

    -- §3.1 Auth gate
    local citizen_id, auth_err
    if require_admin then
      citizen_id, auth_err = Auth.RequireAdmin(src, admin_ace)
    else
      citizen_id, auth_err = Auth.RequireCitizen(src)
    end
    if auth_err then
      Perf.EndTimer(timer, cb_id, { tier = tier })
      return err_to_response(auth_err)
    end

    -- §3.2 Rate-limit gate (token bucket per (src, tier))
    if not skip_rate_limit then
      local rl_ok, rl_err = RateLimit.Check(src, tier)
      if not rl_ok then
        Perf.EndTimer(timer, cb_id, { tier = tier })
        return err_to_response(rl_err)
      end
    end

    -- §3.3 Invoke handler under pcall
    local ok, result = pcall(handler, src, citizen_id, payload)
    if not ok then
      Perf.EndTimer(timer, cb_id, { tier = tier })
      print(('[%s][CB][ERROR] %s raised: %s'):format(
        Config.Logging.PREFIX, name, tostring(result):sub(1, 300)))
      return err_to_response(Errors.New('INTERNAL_ERROR', {
        reason   = 'handler raised',
        callback = name,
        raw      = tostring(result):sub(1, 200),
      }))
    end

    -- §3.4 Normalize response
    local response
    if type(result) == 'table' and result.ok == false then
      response = err_to_response(result.error)
    else
      response = ok_to_response(result)
    end

    Perf.EndTimer(timer, cb_id, { tier = tier })
    return response
  end)
end

-- -----------------------------------------------------------------------------
-- §4. Diagnostics
-- -----------------------------------------------------------------------------

--- ListRegistered — introspect all wrapped callbacks (debug).
---@return table { name → { tier, require_admin, cb_id } }
function W.ListRegistered()
  return _registered
end

return W
