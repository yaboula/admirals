BankApp.api = BankApp.api or {}
BankApp.api.public = {}
local API = BankApp.api.public

local DB = BankApp.lib.db
local Units = BankApp.lib.units
local Validators = BankApp.lib.validators
local UUID = BankApp.lib.uuid
local Idempotency = BankApp.lib.idempotency
local Publish = BankApp.lib.publish
local Wrappers = BankApp.api.wrappers

local RESOURCE = 'sonar_bank_app'
local IDEM_TTL_SECONDS = 86400

local function now_sec() return os.time() end
local function now_ms() return os.time() * 1000 end
local function tuple(ok, err, data) return ok, err, data end
local function sanitize_reason(reason)
  local clean = Validators.SanitizeString(reason or 'unspecified', 255) or 'unspecified'
  clean = clean:gsub('%s+', ' '):match('^%s*(.-)%s*$')
  if clean == '' then clean = 'unspecified' end
  return clean
end
local function invoker()
  local r = GetInvokingResource()
  if type(r) == 'string' and r ~= '' then return r end
  return 'unknown'
end
local function json_encode(value)
  if json and json.encode then return json.encode(value) end
  return '{}'
end
local function hash_payload(value)
  return Idempotency.HashPayload(value)
end
local function valid_minor(amount, allow_zero)
  local value, err = Units.normalize_minor(amount)
  if err then return nil, 'INVALID_AMOUNT' end
  if not allow_zero and value <= 0 then return nil, 'INVALID_AMOUNT' end
  return value, nil
end
local function ensure_uuid(value)
  if value ~= nil and not Validators.IsValidUUID(value) then return nil, 'INVALID_UUID' end
  return value or UUID.V4(), nil
end
local function source_to_citizen(src)
  src = tonumber(src)
  if not src or src <= 0 then return nil, 'INVALID_ARGUMENT' end
  if not GetPlayerName(src) then return nil, 'PLAYER_NOT_FOUND' end
  local loaded_ok, loaded = pcall(function() return exports.sonar_bridges:IsIdentityLoaded(src) end)
  if loaded_ok and loaded == false then return nil, 'PLAYER_NOT_LOADED' end
  local ok, cid = pcall(function() return exports.sonar_bridges:GetCitizenId(src) end)
  if not ok then return nil, 'INTERNAL_ERROR' end
  if type(cid) ~= 'string' or cid == '' then return nil, 'PLAYER_NOT_LOADED' end
  return cid, nil
end
local function source_to_account(src)
  local cid, err = source_to_citizen(src)
  if err then return nil, err end
  return API.ResolvePrimaryAccount(cid)
end

local SQL_PRIMARY = [[
SELECT a.id AS account_id, a.iban, a.owner_account_id, sa.char_id AS citizen_id,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       a.is_frozen AS frozen_flag, a.closed_at,
       CASE WHEN a.closed_at IS NOT NULL THEN 'closed' WHEN a.is_frozen = 1 THEN 'frozen' ELSE 'active' END AS status
FROM sonar_bank_accounts a
INNER JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE sa.char_id = ? AND a.closed_at IS NULL
ORDER BY a.created_at ASC
LIMIT 1
]]
local SQL_BY_IBAN = [[
SELECT a.id AS account_id, a.iban, a.owner_account_id, sa.char_id AS citizen_id,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor,
       a.is_frozen AS frozen_flag, a.closed_at,
       CASE WHEN a.closed_at IS NOT NULL THEN 'closed' WHEN a.is_frozen = 1 THEN 'frozen' ELSE 'active' END AS status
FROM sonar_bank_accounts a
INNER JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE a.iban = ?
LIMIT 1
]]

function API.ResolvePrimaryAccount(citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then return nil, 'INVALID_CITIZEN_ID' end
  local row, err = DB.QuerySingle(SQL_PRIMARY, { citizen_id })
  if err then return nil, 'INTERNAL_ERROR' end
  if not row then return nil, 'ACCOUNT_NOT_FOUND' end
  if row.closed_at ~= nil then return nil, 'ACCOUNT_CLOSED' end
  return row, nil
end
function API.ResolveIban(iban)
  local norm = Validators.NormalizeIBAN(iban)
  if not norm then return nil, 'IBAN_INVALID' end
  local row, err = DB.QuerySingle(SQL_BY_IBAN, { norm })
  if err then return nil, 'INTERNAL_ERROR' end
  if not row then return nil, 'ACCOUNT_NOT_FOUND' end
  if row.closed_at ~= nil then return nil, 'ACCOUNT_CLOSED' end
  return row, nil
end
local function ensure_mutable(account)
  if tonumber(account.frozen_flag) == 1 then return 'ACCOUNT_FROZEN' end
  if account.status == 'closed' then return 'ACCOUNT_CLOSED' end
  return nil
end

local function check_replay(idem_key, payload)
  local row, err = DB.QuerySingle('SELECT state, payload_hash, result_json FROM sonar_bank_idem WHERE idem_key = ? LIMIT 1', { idem_key })
  if err then return nil, 'INTERNAL_ERROR' end
  if not row then return nil, nil end
  if row.payload_hash ~= hash_payload(payload) then return nil, 'IDEMPOTENCY_KEY_REUSED' end
  if row.state == 'completed' then
    local decoded = row.result_json
    if type(decoded) == 'string' and json and json.decode then
      local ok, data = pcall(json.decode, decoded)
      if ok then decoded = data end
    end
    return decoded or {}, 'IDEMPOTENCY_REPLAY'
  end
  if row.state == 'locked' then return nil, 'IDEMPOTENCY_INFLIGHT' end
  return nil, nil
end
local function idem_query(idem_key, payload, result, event_type, target_account_id, correlation_id, invoker_resource, created_at)
  return { query = [[
INSERT INTO sonar_bank_idem
  (idem_key, payload_hash, state, result_json, invoker_resource, event_type, target_account_id, correlation_id, created_at, completed_at, expires_at)
VALUES (?, ?, 'completed', ?, ?, ?, ?, ?, ?, ?, ?)
]], values = { idem_key, hash_payload(payload), json_encode(result), invoker_resource, event_type, target_account_id, correlation_id, created_at, created_at, created_at + IDEM_TTL_SECONDS } }
end
local function movement_query(account_id, amount_minor, balance_after_minor, category, counterpart_iban, reason, tx_id, request_nonce, actor_account_id)
  return { query = [[
INSERT INTO sonar_bank_movements
  (bank_account_id, occurred_at, amount, balance_after, category, counterpart_iban, concept, related_doc_id, request_nonce, initiated_by_account_id, source_resource)
VALUES (?, UNIX_TIMESTAMP(), (? / 100.0), (? / 100.0), ?, ?, ?, ?, ?, ?, ?)
]], values = { account_id, amount_minor, balance_after_minor, category, counterpart_iban, reason, tx_id, request_nonce, actor_account_id, RESOURCE } }
end
local function audit_query(actor_account_id, actor_src, target_account_id, target_iban, event_type, delta_minor, previous_flag_snapshot, request_nonce, correlation_id, invoker_resource, reason, created_at)
  local decimal = Units.from_minor(delta_minor) or '0.00'
  return { query = [[
INSERT INTO sonar_audit_log
  (category, action, event_type, actor_account_id, actor_source, target_type, target_id, target_account_id, amount, delta_minor, currency, request_id, request_nonce, correlation_id, resource, invoker_resource, reason, created_at, metadata, previous_flag_snapshot)
VALUES ('bank_exports', ?, ?, ?, ?, 'bank_account', ?, ?, ?, ?, 'EUR', ?, ?, ?, ?, ?, ?, ?, ?, ?)
]], values = { event_type, event_type, actor_account_id, actor_src, target_iban, target_account_id, decimal, delta_minor, request_nonce, request_nonce, correlation_id, RESOURCE, invoker_resource, reason, created_at, json_encode({ invoker_resource = invoker_resource }), previous_flag_snapshot and json_encode(previous_flag_snapshot) or nil } }
end
local function publish_account(account, new_balance_minor, correlation_id, reason)
  Wrappers.publish_account_balance(account, new_balance_minor, { account_class = 'main', correlation_id = correlation_id, reason = reason })
end
local function audit_overdraft_attempt(account, amount_minor, request_nonce, correlation_id, reason, invoker_resource)
  local created_at = now_sec()
  DB.Execute([[INSERT INTO sonar_audit_log
    (category, action, event_type, actor_account_id, target_type, target_id, target_account_id, amount, delta_minor, currency, request_id, request_nonce, correlation_id, resource, invoker_resource, reason, created_at, metadata, previous_flag_snapshot)
    VALUES ('bank_exports', 'bank_overdraft', 'bank_overdraft', ?, 'bank_account', ?, ?, ?, ?, 'EUR', ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
    { account.owner_account_id, account.iban, account.account_id, Units.from_minor(-amount_minor) or '0.00', -amount_minor, request_nonce, request_nonce, correlation_id, RESOURCE, invoker_resource, reason, created_at, json_encode({ balance_before_minor = tonumber(account.balance_minor) or 0 }), json_encode({ balance_before_minor = tonumber(account.balance_minor) or 0 }) })
end

local function mutate_balance(account, delta_minor, reason, opts, event_type, actor_src)
  opts = opts or {}
  local mutable_err = ensure_mutable(account)
  if mutable_err then return tuple(false, mutable_err) end
  local idem_key, uuid_err = ensure_uuid(opts.idempotency_key)
  if uuid_err then return tuple(false, uuid_err) end
  local correlation_id, corr_err = ensure_uuid(opts.correlation_id or idem_key)
  if corr_err then return tuple(false, corr_err) end
  local inv = invoker()
  reason = sanitize_reason(reason)
  local before = tonumber(account.balance_minor) or 0
  local after = before + delta_minor
  local payload = { op = event_type, iban = account.iban, delta_minor = delta_minor, reason = reason }
  local replay, replay_status = check_replay(idem_key, payload)
  if replay_status == 'IDEMPOTENCY_REPLAY' then return tuple(true, 'IDEMPOTENCY_REPLAY', replay) end
  if replay_status then return tuple(false, replay_status) end
  if after < 0 then
    audit_overdraft_attempt(account, math.abs(delta_minor), idem_key, correlation_id, reason, inv)
    return tuple(false, 'INSUFFICIENT_FUNDS')
  end
  local tx_id = UUID.V4()
  local created_at = now_sec()
  local result = { new_balance_minor = after, iban = account.iban, tx_id = tx_id }
  local update_query = delta_minor >= 0
    and { query = 'UPDATE sonar_bank_accounts SET balance = balance + (? / 100.0), updated_at = UNIX_TIMESTAMP() WHERE id = ? AND closed_at IS NULL AND is_frozen = 0', values = { delta_minor, account.account_id } }
    or { query = 'UPDATE sonar_bank_accounts SET balance = balance - (? / 100.0), updated_at = UNIX_TIMESTAMP() WHERE id = ? AND balance >= (? / 100.0) AND closed_at IS NULL AND is_frozen = 0', values = { math.abs(delta_minor), account.account_id, math.abs(delta_minor) } }
  local ok, tx_err = DB.Transaction({
    update_query,
    movement_query(account.account_id, delta_minor, after, event_type == 'bank_credit' and 'credit' or 'debit', nil, reason, tx_id, idem_key, account.owner_account_id),
    audit_query(account.owner_account_id, actor_src, account.account_id, account.iban, event_type, delta_minor, nil, idem_key, correlation_id, inv, reason, created_at),
    idem_query(idem_key, payload, result, event_type, account.account_id, correlation_id, inv, created_at),
  })
  if not ok then return tuple(false, tx_err and tx_err.code or 'INTERNAL_ERROR') end
  publish_account(account, after, correlation_id, reason)
  return tuple(true, nil, result)
end

function API.AddMoney(src, amount_minor, reason, opts)
  local amount, amount_err = valid_minor(amount_minor)
  if amount_err then return tuple(false, amount_err) end
  local account, err = source_to_account(src)
  if err then return tuple(false, err) end
  return mutate_balance(account, amount, reason, opts, 'bank_credit', tonumber(src))
end
function API.RemoveMoney(src, amount_minor, reason, opts)
  local amount, amount_err = valid_minor(amount_minor)
  if amount_err then return tuple(false, amount_err) end
  local account, err = source_to_account(src)
  if err then return tuple(false, err) end
  return mutate_balance(account, -amount, reason, opts, 'bank_debit', tonumber(src))
end
function API.GetBalance(src)
  local account, err = source_to_account(src)
  if err then return tuple(false, err) end
  return tuple(true, nil, { balance_minor = tonumber(account.balance_minor) or 0, savings_minor = 0, iban = account.iban })
end
function API.CanAfford(src, amount_minor)
  local amount, amount_err = valid_minor(amount_minor)
  if amount_err then return tuple(false, amount_err) end
  local account, err = source_to_account(src)
  if err then return tuple(false, err) end
  local balance = tonumber(account.balance_minor) or 0
  return tuple(true, nil, { balance_minor = balance, sufficient = balance >= amount })
end
function API.AddMoneyByCitizen(citizen_id, amount_minor, reason, opts)
  local amount, amount_err = valid_minor(amount_minor)
  if amount_err then return tuple(false, amount_err) end
  local account, err = API.ResolvePrimaryAccount(citizen_id)
  if err then return tuple(false, err == 'INVALID_CITIZEN_ID' and err or 'ACCOUNT_NOT_FOUND') end
  return mutate_balance(account, amount, reason, opts, 'bank_credit', nil)
end
function API.RemoveMoneyByCitizen(citizen_id, amount_minor, reason, opts)
  local amount, amount_err = valid_minor(amount_minor)
  if amount_err then return tuple(false, amount_err) end
  local account, err = API.ResolvePrimaryAccount(citizen_id)
  if err then return tuple(false, err == 'INVALID_CITIZEN_ID' and err or 'ACCOUNT_NOT_FOUND') end
  return mutate_balance(account, -amount, reason, opts, 'bank_debit', nil)
end
function API.GetBalanceByCitizen(citizen_id)
  local account, err = API.ResolvePrimaryAccount(citizen_id)
  if err then return tuple(false, err == 'INVALID_CITIZEN_ID' and err or 'ACCOUNT_NOT_FOUND') end
  return tuple(true, nil, { balance_minor = tonumber(account.balance_minor) or 0, savings_minor = 0, iban = account.iban })
end
function API.CanAffordByCitizen(citizen_id, amount_minor)
  local amount, amount_err = valid_minor(amount_minor)
  if amount_err then return tuple(false, amount_err) end
  local account, err = API.ResolvePrimaryAccount(citizen_id)
  if err then return tuple(false, err == 'INVALID_CITIZEN_ID' and err or 'ACCOUNT_NOT_FOUND') end
  local balance = tonumber(account.balance_minor) or 0
  return tuple(true, nil, { balance_minor = balance, sufficient = balance >= amount })
end

local function transfer_accounts(from_account, to_account, amount_minor, reason, opts, actor_src)
  opts = opts or {}
  local amount, amount_err = valid_minor(amount_minor)
  if amount_err then return tuple(false, amount_err) end
  if from_account.iban == to_account.iban then return tuple(false, 'VALIDATION_FAIL') end
  local mutable_err = ensure_mutable(from_account) or ensure_mutable(to_account)
  if mutable_err then return tuple(false, mutable_err) end
  local idem_key, uuid_err = ensure_uuid(opts.idempotency_key)
  if uuid_err then return tuple(false, uuid_err) end
  local correlation_id, corr_err = ensure_uuid(opts.correlation_id or idem_key)
  if corr_err then return tuple(false, corr_err) end
  local inv = invoker()
  reason = sanitize_reason(reason)
  local from_before = tonumber(from_account.balance_minor) or 0
  local to_before = tonumber(to_account.balance_minor) or 0
  if from_before < amount then
    audit_overdraft_attempt(from_account, amount, idem_key, correlation_id, reason, inv)
    return tuple(false, 'INSUFFICIENT_FUNDS')
  end
  local from_after, to_after = from_before - amount, to_before + amount
  local tx_id = UUID.V4()
  local created_at = now_sec()
  local payload = { op = 'bank_transfer', from_iban = from_account.iban, to_iban = to_account.iban, amount_minor = amount, reason = reason }
  local replay, replay_status = check_replay(idem_key, payload)
  if replay_status == 'IDEMPOTENCY_REPLAY' then return tuple(true, 'IDEMPOTENCY_REPLAY', replay) end
  if replay_status then return tuple(false, replay_status) end
  local result = { from_iban = from_account.iban, to_iban = to_account.iban, amount_minor = amount, fee_minor = 0, tx_id = tx_id }
  local ok, tx_err = DB.Transaction({
    { query = 'UPDATE sonar_bank_accounts SET balance = balance - (? / 100.0), updated_at = UNIX_TIMESTAMP() WHERE id = ? AND balance >= (? / 100.0) AND closed_at IS NULL AND is_frozen = 0', values = { amount, from_account.account_id, amount } },
    { query = 'UPDATE sonar_bank_accounts SET balance = balance + (? / 100.0), updated_at = UNIX_TIMESTAMP() WHERE id = ? AND closed_at IS NULL AND is_frozen = 0', values = { amount, to_account.account_id } },
    movement_query(from_account.account_id, -amount, from_after, 'transfer', to_account.iban, reason, tx_id, idem_key, from_account.owner_account_id),
    movement_query(to_account.account_id, amount, to_after, 'transfer', from_account.iban, reason, tx_id, idem_key, from_account.owner_account_id),
    audit_query(from_account.owner_account_id, actor_src, from_account.account_id, from_account.iban, 'bank_transfer', -amount, nil, idem_key, correlation_id, inv, reason, created_at),
    audit_query(from_account.owner_account_id, actor_src, to_account.account_id, to_account.iban, 'bank_transfer', amount, nil, idem_key, correlation_id, inv, reason, created_at),
    idem_query(idem_key, payload, result, 'bank_transfer', from_account.account_id, correlation_id, inv, created_at),
  })
  if not ok then return tuple(false, tx_err and tx_err.code or 'INTERNAL_ERROR') end
  publish_account(from_account, from_after, correlation_id, reason)
  publish_account(to_account, to_after, correlation_id, reason)
  return tuple(true, nil, result)
end
function API.TransferBySource(from_src, to_src, amount_minor, reason, opts)
  local from_account, from_err = source_to_account(from_src)
  if from_err then return tuple(false, from_err) end
  local to_account, to_err = source_to_account(to_src)
  if to_err then return tuple(false, to_err) end
  return transfer_accounts(from_account, to_account, amount_minor, reason, opts, tonumber(from_src))
end
function API.TransferByIban(from_iban, to_iban, amount_minor, reason, opts)
  local from_account, from_err = API.ResolveIban(from_iban)
  if from_err then return tuple(false, from_err) end
  local to_account, to_err = API.ResolveIban(to_iban)
  if to_err then return tuple(false, to_err) end
  return transfer_accounts(from_account, to_account, amount_minor, reason, opts, nil)
end
function API.TransferByCitizen(from_cid, to_cid, amount_minor, reason, opts)
  local from_account, from_err = API.ResolvePrimaryAccount(from_cid)
  if from_err then return tuple(false, from_err == 'INVALID_CITIZEN_ID' and from_err or 'ACCOUNT_NOT_FOUND') end
  local to_account, to_err = API.ResolvePrimaryAccount(to_cid)
  if to_err then return tuple(false, to_err == 'INVALID_CITIZEN_ID' and to_err or 'ACCOUNT_NOT_FOUND') end
  return transfer_accounts(from_account, to_account, amount_minor, reason, opts, nil)
end

exports('AddMoney', API.AddMoney)
exports('RemoveMoney', API.RemoveMoney)
exports('CanAfford', API.CanAfford)
exports('GetBalance', API.GetBalance)
exports('TransferBySource', API.TransferBySource)
exports('TransferByIban', API.TransferByIban)
exports('AddMoneyByCitizen', API.AddMoneyByCitizen)
exports('RemoveMoneyByCitizen', API.RemoveMoneyByCitizen)
exports('CanAffordByCitizen', API.CanAffordByCitizen)
exports('GetBalanceByCitizen', API.GetBalanceByCitizen)
exports('TransferByCitizen', API.TransferByCitizen)
exports('GetApiVersion', function()
  return { major = 1, minor = 0, patch = 2, phase = 'Phase 5', api_lock = 'C-BE-02 v1.0.2 R2' }
end)

return API
