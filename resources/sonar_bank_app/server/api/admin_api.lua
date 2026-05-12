BankApp.api = BankApp.api or {}
BankApp.api.admin = {}
local API = BankApp.api.admin

local DB = BankApp.lib.db
local Units = BankApp.lib.units
local Validators = BankApp.lib.validators
local UUID = BankApp.lib.uuid
local Idempotency = BankApp.lib.idempotency
local Publish = BankApp.lib.publish
local Public = BankApp.api.public
local ApiAuth = BankApp.api.auth

local RESOURCE = 'sonar_bank_app'
local IDEM_TTL_SECONDS = 86400

local function tuple(ok, err, data) return ok, err, data end
local function now_sec() return os.time() end
local function json_encode(value) if json and json.encode then return json.encode(value) end return '{}' end
local function invoker() local r = GetInvokingResource(); return type(r) == 'string' and r ~= '' and r or 'console' end
local function sanitize_reason(reason)
  local clean = Validators.SanitizeString(reason or 'admin action', 255) or 'admin action'
  clean = clean:gsub('%s+', ' '):match('^%s*(.-)%s*$')
  return clean ~= '' and clean or 'admin action'
end
local function valid_minor(value, allow_zero)
  local amount, err = Units.normalize_minor(value)
  if err then return nil, 'INVALID_AMOUNT' end
  if not allow_zero and amount <= 0 then return nil, 'INVALID_AMOUNT' end
  return amount, nil
end
local function ensure_uuid(value)
  if value ~= nil and not Validators.IsValidUUID(value) then return nil, 'INVALID_UUID' end
  return value or UUID.V4(), nil
end
local function require_admin(actor_src)
  local ok, err, context = ApiAuth.RequireAdmin(actor_src, { ace = BankApp.Config.Permissions.GOVT_COMPLIANCE_ACE })
  return ok, err, context and context.invoker_resource or invoker()
end
local function cid_from_source(src)
  src = tonumber(src)
  if not src or src <= 0 then return nil, 'PLAYER_NOT_FOUND' end
  if not GetPlayerName(src) then return nil, 'PLAYER_NOT_FOUND' end
  local loaded_ok, loaded = pcall(function() return exports.sonar_bridges:IsIdentityLoaded(src) end)
  if loaded_ok and loaded == false then return nil, 'PLAYER_NOT_LOADED' end
  local ok, cid = pcall(function() return exports.sonar_bridges:GetCitizenId(src) end)
  if not ok then return nil, 'INTERNAL_ERROR' end
  if type(cid) ~= 'string' or cid == '' then return nil, 'PLAYER_NOT_LOADED' end
  return cid, nil
end
local function resolve_target(target)
  if type(target) == 'number' then
    local cid, err = cid_from_source(target)
    if err then return nil, err end
    return Public.ResolvePrimaryAccount(cid)
  end
  if type(target) == 'string' then
    local by_iban = Public.ResolveIban(target)
    if by_iban then return by_iban, nil end
    if Validators.IsValidCitizenId(target) then return Public.ResolvePrimaryAccount(target) end
  end
  return nil, 'INVALID_ARGUMENT'
end
local function publish(account, balance_minor, correlation_id, reason)
  local src = BankApp.lib.auth and BankApp.lib.auth.ResolveCitizenSrc and BankApp.lib.auth.ResolveCitizenSrc(account.citizen_id) or nil
  if src then Publish.PublishBalanceUpdate(src, account.citizen_id, balance_minor, 0, { reason = reason, correlation = correlation_id }) end
end
local function hash_payload(value) return Idempotency.HashPayload(value) end
local function check_replay(idem_key, payload)
  local row, err = DB.QuerySingle('SELECT state, payload_hash, result_json FROM sonar_bank_idem WHERE idem_key = ? LIMIT 1', { idem_key })
  if err then return nil, 'INTERNAL_ERROR' end
  if not row then return nil, nil end
  if row.payload_hash ~= hash_payload(payload) then return nil, 'IDEMPOTENCY_KEY_REUSED' end
  if row.state == 'completed' then
    local decoded = row.result_json
    if type(decoded) == 'string' and json and json.decode then local ok, data = pcall(json.decode, decoded); if ok then decoded = data end end
    return decoded or {}, 'IDEMPOTENCY_REPLAY'
  end
  return nil, 'IDEMPOTENCY_INFLIGHT'
end
local function idem_query(idem_key, payload, result, event_type, target_account_id, correlation_id, invoker_resource, created_at)
  return { query = [[INSERT INTO sonar_bank_idem
    (idem_key, payload_hash, state, result_json, invoker_resource, event_type, target_account_id, correlation_id, created_at, completed_at, expires_at)
    VALUES (?, ?, 'completed', ?, ?, ?, ?, ?, ?, ?, ?)]],
    values = { idem_key, hash_payload(payload), json_encode(result), invoker_resource, event_type, target_account_id, correlation_id, created_at, created_at, created_at + IDEM_TTL_SECONDS } }
end
local function movement_query(account_id, delta_minor, balance_after_minor, category, reason, tx_id, request_nonce, actor_account_id)
  return { query = [[INSERT INTO sonar_bank_movements
    (bank_account_id, occurred_at, amount, balance_after, category, concept, related_doc_id, request_nonce, initiated_by_account_id, source_resource)
    VALUES (?, UNIX_TIMESTAMP(), (? / 100.0), (? / 100.0), ?, ?, ?, ?, ?, ?)]],
    values = { account_id, delta_minor, balance_after_minor, category, reason, tx_id, request_nonce, actor_account_id, RESOURCE } }
end
local function audit_query(actor_account_id, actor_src, target_account_id, target_iban, event_type, delta_minor, previous_flag_snapshot, request_nonce, correlation_id, invoker_resource, reason, created_at)
  return { query = [[INSERT INTO sonar_audit_log
    (category, action, event_type, actor_account_id, actor_source, target_type, target_id, target_account_id, amount, delta_minor, currency, request_id, request_nonce, correlation_id, resource, invoker_resource, reason, created_at, metadata, previous_flag_snapshot)
    VALUES ('bank_exports', ?, ?, ?, ?, 'bank_account', ?, ?, ?, ?, 'EUR', ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
    values = { event_type, event_type, actor_account_id, actor_src, target_iban, target_account_id, Units.from_minor(delta_minor) or '0.00', delta_minor, request_nonce, request_nonce, correlation_id, RESOURCE, invoker_resource, reason, created_at, json_encode({ invoker_resource = invoker_resource }), previous_flag_snapshot and json_encode(previous_flag_snapshot) or nil } }
end
local function actor_account_id(actor_src)
  if (tonumber(actor_src) or 0) <= 0 then return 'system' end
  local cid = cid_from_source(actor_src)
  if type(cid) ~= 'string' then return nil end
  local row = Public.ResolvePrimaryAccount(cid)
  return row and row.owner_account_id or nil
end

local function admin_delta(actor_src, account, amount_minor, reason, opts, event_type)
  opts = opts or {}
  local ok_auth, auth_err, inv = require_admin(actor_src)
  if not ok_auth then return tuple(false, auth_err) end
  local amount, amount_err = valid_minor(amount_minor)
  if amount_err then return tuple(false, amount_err) end
  if account.status == 'closed' then return tuple(false, 'ACCOUNT_CLOSED') end
  local idem_key, uuid_err = ensure_uuid(opts.idempotency_key)
  if uuid_err then return tuple(false, uuid_err) end
  local correlation_id, corr_err = ensure_uuid(opts.correlation_id or idem_key)
  if corr_err then return tuple(false, corr_err) end
  reason = sanitize_reason(reason)
  local sign = (event_type == 'admin_credit') and 1 or -1
  local delta = amount * sign
  local before = tonumber(account.balance_minor) or 0
  local after = before + delta
  local overdraft = after < 0
  if overdraft and opts.allow_overdraft ~= true then return tuple(false, 'INSUFFICIENT_FUNDS') end
  local audit_event = overdraft and 'bank_overdraft' or event_type
  local previous = overdraft and { balance_before_minor = before, overdraft_authorized_by = tostring(actor_src or 0) } or nil
  local payload = { op = event_type, iban = account.iban, amount_minor = amount, allow_overdraft = opts.allow_overdraft == true, reason = reason }
  local replay, replay_status = check_replay(idem_key, payload)
  if replay_status == 'IDEMPOTENCY_REPLAY' then return tuple(true, 'IDEMPOTENCY_REPLAY', replay) end
  if replay_status then return tuple(false, replay_status) end
  local tx_id = UUID.V4()
  local created_at = now_sec()
  local result = { iban = account.iban, new_balance_minor = after, tx_id = tx_id }
  local actor_id = actor_account_id(actor_src)
  local ok, tx_err = DB.Transaction({
    { query = 'UPDATE sonar_bank_accounts SET balance = balance + (? / 100.0), updated_at = UNIX_TIMESTAMP() WHERE id = ? AND closed_at IS NULL', values = { delta, account.account_id } },
    movement_query(account.account_id, delta, after, event_type, reason, tx_id, idem_key, actor_id),
    audit_query(actor_id, actor_src, account.account_id, account.iban, audit_event, delta, previous, idem_key, correlation_id, inv, reason, created_at),
    idem_query(idem_key, payload, result, audit_event, account.account_id, correlation_id, inv, created_at),
  })
  if not ok then return tuple(false, tx_err and tx_err.code or 'INTERNAL_ERROR') end
  publish(account, after, correlation_id, reason)
  return tuple(true, nil, result)
end
local function admin_set(actor_src, account, new_balance_minor, reason, opts)
  opts = opts or {}
  local ok_auth, auth_err, inv = require_admin(actor_src)
  if not ok_auth then return tuple(false, auth_err) end
  local new_balance, amount_err = valid_minor(new_balance_minor, true)
  if amount_err then return tuple(false, amount_err) end
  if account.status == 'closed' then return tuple(false, 'ACCOUNT_CLOSED') end
  if new_balance < 0 and opts.allow_overdraft ~= true then return tuple(false, 'INSUFFICIENT_FUNDS') end
  local idem_key, uuid_err = ensure_uuid(opts.idempotency_key)
  if uuid_err then return tuple(false, uuid_err) end
  local correlation_id, corr_err = ensure_uuid(opts.correlation_id or idem_key)
  if corr_err then return tuple(false, corr_err) end
  reason = sanitize_reason(reason)
  local before = tonumber(account.balance_minor) or 0
  local delta = new_balance - before
  local audit_event = new_balance < 0 and 'bank_overdraft' or 'admin_set_balance'
  local previous = { balance_before_minor = before, frozen = tonumber(account.frozen_flag) == 1, overdraft_authorized_by = tostring(actor_src or 0) }
  local payload = { op = 'admin_set_balance', iban = account.iban, new_balance_minor = new_balance, allow_overdraft = opts.allow_overdraft == true, reason = reason }
  local replay, replay_status = check_replay(idem_key, payload)
  if replay_status == 'IDEMPOTENCY_REPLAY' then return tuple(true, 'IDEMPOTENCY_REPLAY', replay) end
  if replay_status then return tuple(false, replay_status) end
  local tx_id = UUID.V4()
  local created_at = now_sec()
  local result = { iban = account.iban, prev_balance_minor = before, new_balance_minor = new_balance, delta_minor = delta, tx_id = tx_id }
  local actor_id = actor_account_id(actor_src)
  local ok, tx_err = DB.Transaction({
    { query = 'UPDATE sonar_bank_accounts SET balance = (? / 100.0), updated_at = UNIX_TIMESTAMP() WHERE id = ? AND closed_at IS NULL', values = { new_balance, account.account_id } },
    movement_query(account.account_id, delta, new_balance, 'admin_set_balance', reason, tx_id, idem_key, actor_id),
    audit_query(actor_id, actor_src, account.account_id, account.iban, audit_event, delta, previous, idem_key, correlation_id, inv, reason, created_at),
    idem_query(idem_key, payload, result, audit_event, account.account_id, correlation_id, inv, created_at),
  })
  if not ok then return tuple(false, tx_err and tx_err.code or 'INTERNAL_ERROR') end
  publish(account, new_balance, correlation_id, reason)
  return tuple(true, nil, result)
end
local function set_frozen(actor_src, account, frozen, reason)
  local ok_auth, auth_err, inv = require_admin(actor_src)
  if not ok_auth then return tuple(false, auth_err) end
  if account.status == 'closed' then return tuple(false, 'ACCOUNT_CLOSED') end
  local currently = tonumber(account.frozen_flag) == 1
  if frozen and currently then return tuple(false, 'ACCOUNT_ALREADY_FROZEN') end
  if not frozen and not currently then return tuple(false, 'ACCOUNT_NOT_FROZEN') end
  reason = sanitize_reason(reason)
  local request_nonce = UUID.V4()
  local correlation_id = request_nonce
  local created_at = now_sec()
  local event_type = frozen and 'account_freeze' or 'account_unfreeze'
  local previous = { frozen = currently, frozen_reason = nil, frozen_at = nil }
  local actor_id = actor_account_id(actor_src)
  local ok, tx_err = DB.Transaction({
    { query = 'UPDATE sonar_bank_accounts SET is_frozen = ?, updated_at = UNIX_TIMESTAMP() WHERE id = ? AND closed_at IS NULL', values = { frozen and 1 or 0, account.account_id } },
    audit_query(actor_id, actor_src, account.account_id, account.iban, event_type, 0, previous, request_nonce, correlation_id, inv, reason, created_at),
  })
  if not ok then return tuple(false, tx_err and tx_err.code or 'INTERNAL_ERROR') end
  return tuple(true, nil, { iban = account.iban, previous_flag_snapshot = previous })
end

function API.AdminCredit(actor_src, target, amount_minor, reason, opts) local account, err = resolve_target(target); if err then return tuple(false, err) end; return admin_delta(actor_src, account, amount_minor, reason, opts, 'admin_credit') end
function API.AdminDebit(actor_src, target, amount_minor, reason, opts) local account, err = resolve_target(target); if err then return tuple(false, err) end; return admin_delta(actor_src, account, amount_minor, reason, opts, 'admin_debit') end
function API.AdminSetBalance(actor_src, target, new_balance_minor, reason, opts) local account, err = resolve_target(target); if err then return tuple(false, err) end; return admin_set(actor_src, account, new_balance_minor, reason, opts) end
function API.Freeze(actor_src, target_iban, reason) local account, err = Public.ResolveIban(target_iban); if err then return tuple(false, err) end; return set_frozen(actor_src, account, true, reason) end
function API.Unfreeze(actor_src, target_iban, reason) local account, err = Public.ResolveIban(target_iban); if err then return tuple(false, err) end; return set_frozen(actor_src, account, false, reason) end
function API.AdminCreditByCitizen(actor_src, citizen_id, amount_minor, reason, opts) local account, err = Public.ResolvePrimaryAccount(citizen_id); if err then return tuple(false, err) end; return admin_delta(actor_src, account, amount_minor, reason, opts, 'admin_credit') end
function API.AdminDebitByCitizen(actor_src, citizen_id, amount_minor, reason, opts) local account, err = Public.ResolvePrimaryAccount(citizen_id); if err then return tuple(false, err) end; return admin_delta(actor_src, account, amount_minor, reason, opts, 'admin_debit') end
function API.AdminSetBalanceByCitizen(actor_src, citizen_id, new_balance_minor, reason, opts) local account, err = Public.ResolvePrimaryAccount(citizen_id); if err then return tuple(false, err) end; return admin_set(actor_src, account, new_balance_minor, reason, opts) end
function API.FreezeByCitizen(actor_src, citizen_id, reason) local account, err = Public.ResolvePrimaryAccount(citizen_id); if err then return tuple(false, err) end; return set_frozen(actor_src, account, true, reason) end
function API.UnfreezeByCitizen(actor_src, citizen_id, reason) local account, err = Public.ResolvePrimaryAccount(citizen_id); if err then return tuple(false, err) end; return set_frozen(actor_src, account, false, reason) end

exports('AdminCredit', API.AdminCredit)
exports('AdminDebit', API.AdminDebit)
exports('AdminSetBalance', API.AdminSetBalance)
exports('Freeze', API.Freeze)
exports('Unfreeze', API.Unfreeze)
exports('AdminCreditByCitizen', API.AdminCreditByCitizen)
exports('AdminDebitByCitizen', API.AdminDebitByCitizen)
exports('AdminSetBalanceByCitizen', API.AdminSetBalanceByCitizen)
exports('FreezeByCitizen', API.FreezeByCitizen)
exports('UnfreezeByCitizen', API.UnfreezeByCitizen)

return API
