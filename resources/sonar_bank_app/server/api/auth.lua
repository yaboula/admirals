BankApp.api = BankApp.api or {}
BankApp.api.auth = {}
local M = BankApp.api.auth

local DB = BankApp.lib.db
local Config = BankApp.Config

local function invoker_resource()
  local resource = GetInvokingResource()
  if type(resource) == 'string' and resource ~= '' then return resource end
  return 'console'
end
local function split_csv(raw)
  local values = {}
  for item in tostring(raw or ''):gmatch('[^,]+') do
    local clean = item:match('^%s*(.-)%s*$')
    if clean ~= '' then values[#values + 1] = clean end
  end
  return values
end
local function contains_csv(raw, value)
  for _, item in ipairs(split_csv(raw)) do
    if item == value then return true end
  end
  return false
end
local function actor_account_id(actor_src)
  actor_src = tonumber(actor_src) or 0
  if actor_src <= 0 then return 'system' end
  local ok, cid = pcall(function() return exports.sonar_bridges:GetCitizenId(actor_src) end)
  if not ok or type(cid) ~= 'string' or cid == '' then return nil end
  local row = DB.QuerySingle('SELECT id FROM sonar_accounts WHERE char_id = ? ORDER BY updated_at DESC LIMIT 1', { cid })
  return row and row.id or nil
end
local function audit_auth(actor_src, invoker, reason)
  DB.Execute([[INSERT INTO sonar_audit_log
    (category, action, event_type, actor_account_id, actor_source, target_type, target_id, amount, currency, request_id, request_nonce, correlation_id, resource, invoker_resource, reason, created_at, metadata)
    VALUES ('bank_exports', 'auth_denied', 'auth_denied', ?, ?, 'resource', ?, NULL, 'EUR', ?, ?, ?, 'sonar_bank_app', ?, ?, UNIX_TIMESTAMP(), ?)]],
    { actor_account_id(actor_src), tonumber(actor_src) or 0, invoker, invoker .. ':auth_denied', invoker .. ':auth_denied', invoker .. ':auth_denied', invoker, reason, json and json.encode and json.encode({ invoker_resource = invoker, reason = reason }) or '{}' })
end

function M.RequireAdmin(actor_src, opts)
  opts = opts or {}
  actor_src = tonumber(actor_src) or 0
  local invoker = invoker_resource()
  local context = { actor_src = actor_src, invoker_resource = invoker, actor_account_id = actor_account_id(actor_src), auth_path = nil }

  if actor_src == 0 then
    context.auth_path = 'console'
    return true, nil, context
  end

  local allowlist = GetConvar('sonar:admin_allowlist', 'sonar_bank_app,sonar_bank,sonar_core')
  if contains_csv(allowlist, invoker) then
    context.auth_path = 'resource_allowlist'
    return true, nil, context
  end

  local ace = opts.ace or Config.Permissions.ADMIN_ACE
  if IsPlayerAceAllowed(actor_src, ace) or IsPlayerAceAllowed(actor_src, Config.Permissions.ADMIN_ACE) then
    context.auth_path = 'ace'
    return true, nil, context
  end

  local role_prefix = GetConvar('sonar:admin_role_ace_prefix', 'sonar.bank.role.')
  local roles = split_csv(GetConvar('sonar:admin_roles', 'bank_admin,government'))
  for _, role in ipairs(roles) do
    if IsPlayerAceAllowed(actor_src, role_prefix .. role) then
      context.auth_path = 'role'
      return true, nil, context
    end
  end

  audit_auth(actor_src, invoker, 'admin export denied')
  return false, 'AUTH_ACE_DENIED', context
end

return M
