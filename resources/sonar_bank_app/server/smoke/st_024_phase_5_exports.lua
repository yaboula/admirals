BankApp.smoke = BankApp.smoke or {}
BankApp.smoke.st_024_phase_5_exports = {}
local S = BankApp.smoke.st_024_phase_5_exports

local DB = BankApp.lib.db
local Units = BankApp.lib.units
local UUID = BankApp.lib.uuid
local Public = BankApp.api.public
local Admin = BankApp.api.admin
local Auth = BankApp.api.auth
local Wrappers = BankApp.api.wrappers
local LegacyScan = BankApp.api.legacy_scan
local Publish = BankApp.lib.publish

local PREFIX = '[sonar_bank_app][ST-024]'
local FIXTURE_PREFIX = 'ST024_'

local function log(message)
  print(('%s %s'):format(PREFIX, message))
end

local function uuid_tail(n)
  return ('%012d'):format(n)
end

local function fixture_uuid(group, n)
  return ('024%05d-%04d-4000-8000-%s'):format(group, n % 10000, uuid_tail(n))
end

local function new_uuid()
  return UUID.V4()
end

local function fixture_iban(n)
  return ('AD24ST024%07d'):format(n)
end

local function record(results, id, name, passed, detail)
  results[#results + 1] = { id = id, name = name, passed = passed == true, detail = tostring(detail or '') }
  log(('%s %s %s — %s'):format(passed and 'PASS' or 'FAIL', id, name, tostring(detail or '')))
end

local function first_player_source()
  for _, src_str in ipairs(GetPlayers()) do
    local src = tonumber(src_str)
    if src and src > 0 and GetPlayerName(src) then return src end
  end
  return nil
end

local function db_one(sql, params)
  local row, err = DB.QuerySingle(sql, params or {})
  if err then return nil, err.code or 'DB_ERROR' end
  return row, nil
end

local function db_scalar(sql, params)
  local value, err = DB.QueryScalar(sql, params or {})
  if err then return nil, err.code or 'DB_ERROR' end
  return value, nil
end

local function db_exec(sql, params)
  local affected, err = DB.Execute(sql, params or {})
  if err then return nil, err.code or 'DB_ERROR' end
  return affected, nil
end

local function ensure_schema()
  local idem = db_scalar([[SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sonar_bank_idem']], {})
  local owner_type = db_scalar([[SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sonar_bank_accounts' AND COLUMN_NAME = 'owner_type']], {})
  local audit_col = db_scalar([[SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sonar_audit_log' AND COLUMN_NAME = 'request_nonce']], {})
  return tonumber(idem or 0) > 0 and tonumber(owner_type or 0) > 0 and tonumber(audit_col or 0) > 0
end

local function ensure_account(citizen_id, slot, balance_minor)
  local account_id = fixture_uuid(2400, slot)
  local bank_id = fixture_uuid(2401, slot)
  local iban = fixture_iban(slot)
  local now = os.time()
  local balance = (balance_minor or 0) / 100.0
  local ok1, err1 = db_exec([[INSERT INTO sonar_accounts (id, char_id, framework_source, alias, created_at, updated_at)
VALUES (?, ?, 'native', ?, ?, ?)
ON DUPLICATE KEY UPDATE alias = VALUES(alias), updated_at = VALUES(updated_at)]],
    { account_id, citizen_id, 'ST024 Fixture', now, now })
  if not ok1 then return nil, err1 end
  local ok2, err2 = db_exec([[INSERT INTO sonar_bank_accounts
  (id, iban, owner_type, account_class, owner_account_id, balance, is_frozen, created_at, updated_at, closed_at)
VALUES (?, ?, 'personal', 'checking', ?, ?, 0, ?, ?, NULL)
ON DUPLICATE KEY UPDATE
  iban = VALUES(iban), owner_type = VALUES(owner_type), account_class = VALUES(account_class), owner_account_id = VALUES(owner_account_id),
  balance = VALUES(balance), is_frozen = 0, updated_at = VALUES(updated_at), closed_at = NULL]],
    { bank_id, iban, account_id, balance, now, now })
  if not ok2 then return nil, err2 end
  return Public.ResolveIban(iban)
end

local function set_account_balance(account, balance_minor)
  return db_exec([[UPDATE sonar_bank_accounts SET balance = (? / 100.0), is_frozen = 0, closed_at = NULL, updated_at = UNIX_TIMESTAMP() WHERE id = ?]], { balance_minor, account.account_id })
end

local function ensure_source_account(src, balance_minor)
  if not src then return nil, 'source argument required' end
  local ok, cid = pcall(function() return exports.sonar_bridges:GetCitizenId(src) end)
  if not ok or type(cid) ~= 'string' or cid == '' then return nil, 'source citizen_id unavailable' end
  local account, err = Public.ResolvePrimaryAccount(cid)
  if not account then
    account, err = ensure_account(cid, 900001, balance_minor)
    if not account then return nil, err end
  end
  local original = { account_id = account.account_id, citizen_id = account.citizen_id, balance_minor = tonumber(account.balance_minor) or 0 }
  local changed, update_err = set_account_balance(account, balance_minor)
  if not changed then return nil, update_err end
  account.balance_minor = balance_minor
  return account, nil, original
end

local function restore_original(original, src)
  if original and original.account_id then
    db_exec([[UPDATE sonar_bank_accounts SET balance = (? / 100.0), updated_at = UNIX_TIMESTAMP() WHERE id = ?]], { original.balance_minor or 0, original.account_id })
    if src and original.citizen_id then
      pcall(Publish.PublishBalanceUpdate, src, original.citizen_id, original.balance_minor or 0, 0, { reason = 'ST-024 restore', emit_event = false })
    end
  end
end

local function audit_count(request_nonce, event_type)
  local value = db_scalar([[SELECT COUNT(*) FROM sonar_audit_log WHERE request_nonce = ? AND event_type = ?]], { request_nonce, event_type })
  return tonumber(value or 0)
end

local function audit_shape_ok(request_nonce, event_type, delta_minor)
  local row = db_one([[SELECT event_type, target_account_id, amount, delta_minor, request_nonce, correlation_id, invoker_resource, reason, created_at, currency
FROM sonar_audit_log
WHERE request_nonce = ? AND event_type = ?
ORDER BY id DESC
LIMIT 1]], { request_nonce, event_type })
  if not row then return false, 'audit row missing' end
  local ok = row.event_type == event_type
    and row.target_account_id ~= nil
    and tonumber(row.delta_minor or 0) == delta_minor
    and row.request_nonce == request_nonce
    and row.correlation_id ~= nil
    and row.invoker_resource ~= nil
    and row.reason ~= nil
    and row.created_at ~= nil
    and row.currency == 'EUR'
    and row.amount ~= nil
  return ok, ok and '10-field audit row present' or '10-field audit row incomplete'
end

local function statebag_balance(src)
  if not src then return nil end
  local ok, payload = pcall(function() return Player(src).state.bank_balance end)
  if ok then return payload end
  return nil
end

local function test_024_1(results)
  local version = Public.GetApiVersion and Public.GetApiVersion() or nil
  local passed = type(version) == 'table' and version.major == 1 and version.api_lock == 'C-BE-02 v1.0.2 R2'
  record(results, 'ST-024.1', 'GetApiVersion smoke', passed, passed and version.api_lock or 'bad version response')
end

local function test_024_2(results, src)
  local account, setup_err, original = ensure_source_account(src, 100000)
  if not account then return record(results, 'ST-024.2', 'AddMoney idempotency audit publish', false, setup_err) end
  local idem, corr = new_uuid(), new_uuid()
  local ok, err, data = Public.AddMoney(src, 1250, 'ST-024.2 AddMoney', { idempotency_key = idem, correlation_id = corr })
  local replay_ok, replay_err = Public.AddMoney(src, 1250, 'ST-024.2 AddMoney', { idempotency_key = idem, correlation_id = corr })
  local audit_ok, audit_detail = audit_shape_ok(idem, 'bank_credit', 1250)
  local bag = statebag_balance(src)
  local publish_ok = type(bag) == 'table' and data and bag.balance_minor == data.new_balance_minor and bag.correlation == corr
  restore_original(original, src)
  record(results, 'ST-024.2', 'AddMoney happy path + replay + audit + StateBag', ok == true and not err and replay_ok == true and replay_err == 'IDEMPOTENCY_REPLAY' and audit_ok and publish_ok, audit_detail)
end

local function test_024_3(results, src)
  local account, setup_err, original = ensure_source_account(src, 3000)
  if not account then return record(results, 'ST-024.3', 'RemoveMoney insufficient overdraft audit', false, setup_err) end
  local idem_ok, corr_ok = new_uuid(), new_uuid()
  local ok, err = Public.RemoveMoney(src, 500, 'ST-024.3 RemoveMoney', { idempotency_key = idem_ok, correlation_id = corr_ok })
  local idem_fail, corr_fail = new_uuid(), new_uuid()
  local fail_ok, fail_err = Public.RemoveMoney(src, 999999, 'ST-024.3 overdraft', { idempotency_key = idem_fail, correlation_id = corr_fail })
  local overdraft_ok = audit_count(idem_fail, 'bank_overdraft') >= 1
  restore_original(original, src)
  record(results, 'ST-024.3', 'RemoveMoney happy path + INSUFFICIENT_FUNDS + bank_overdraft', ok == true and not err and fail_ok == false and fail_err == 'INSUFFICIENT_FUNDS' and overdraft_ok, ('overdraft_audit=%s'):format(tostring(overdraft_ok)))
end

local function test_024_4(results)
  local from_account = ensure_account(FIXTURE_PREFIX .. 'TRANSFER_A', 1001, 100000)
  local to_account = ensure_account(FIXTURE_PREFIX .. 'TRANSFER_B', 1002, 10000)
  if not from_account or not to_account then return record(results, 'ST-024.4', 'Transfer atomic audit double publish', false, 'fixture setup failed') end
  local idem, corr = new_uuid(), new_uuid()
  local publishes = {}
  Wrappers.SetSmokeObserver(function(citizen_id, balance_major_decimal, account_class, opts)
    if opts and opts.correlation_id == corr then publishes[#publishes + 1] = { citizen_id = citizen_id, balance = balance_major_decimal, class = account_class } end
  end)
  local ok, err = Public.TransferByIban(from_account.iban, to_account.iban, 2500, 'ST-024.4 transfer', { idempotency_key = idem, correlation_id = corr })
  Wrappers.SetSmokeObserver(nil)
  local audit_ok = audit_count(idem, 'bank_transfer') == 2
  local from_after = Public.ResolveIban(from_account.iban)
  local to_after = Public.ResolveIban(to_account.iban)
  local balances_ok = from_after and to_after and tonumber(from_after.balance_minor) == 97500 and tonumber(to_after.balance_minor) == 12500
  record(results, 'ST-024.4', 'Transfer atomic 2-row audit + double publish post-COMMIT', ok == true and not err and audit_ok and #publishes == 2 and balances_ok, ('audit_rows=%d publishes=%d'):format(audit_count(idem, 'bank_transfer'), #publishes))
end

local function test_024_5(results, src)
  local citizen_id = FIXTURE_PREFIX .. 'OFFLINE'
  local account = ensure_account(citizen_id, 1003, 50000)
  if not account then return record(results, 'ST-024.5', 'ByCitizen offline-safe + PLAYER_NOT_LOADED simulation', false, 'fixture setup failed') end
  local idem, corr = new_uuid(), new_uuid()
  local by_ok, by_err = Public.AddMoneyByCitizen(citizen_id, 100, 'ST-024.5 ByCitizen offline', { idempotency_key = idem, correlation_id = corr })
  local source_loaded_ok = false
  local source_err = 'source unavailable'
  if src then
    Public.SetSmokeIdentityLoadedOverride(src, false)
    local source_ok, err = Public.GetBalance(src)
    Public.SetSmokeIdentityLoadedOverride(src, nil)
    source_loaded_ok = source_ok == false and err == 'PLAYER_NOT_LOADED'
    source_err = tostring(err)
  end
  record(results, 'ST-024.5', 'ByCitizen siblings + PLAYER_NOT_LOADED simulation', by_ok == true and not by_err and source_loaded_ok, ('source_probe=%s'):format(source_err))
end

local function test_024_6(results)
  local account = ensure_account(FIXTURE_PREFIX .. 'AFFORD', 1004, 1000)
  if not account then return record(results, 'ST-024.6', 'CanAfford boundary', false, 'fixture setup failed') end
  local ok1, err1, data1 = Public.CanAffordByCitizen(FIXTURE_PREFIX .. 'AFFORD', 1000)
  local ok2, err2, data2 = Public.CanAffordByCitizen(FIXTURE_PREFIX .. 'AFFORD', 1001)
  record(results, 'ST-024.6', 'CanAfford sufficient/insufficient boundary', ok1 and not err1 and data1 and data1.sufficient == true and ok2 and not err2 and data2 and data2.sufficient == false, '1000=true 1001=false')
end

local function test_024_7(results)
  local before = audit_count('st024_external:auth_denied', 'auth_denied')
  Auth.SetSmokeTestContext({ invoker_resource = 'sonar_bank_app' })
  local allow_ok, _, allow_ctx = Auth.RequireAdmin(4242)
  Auth.SetSmokeTestContext({ invoker_resource = 'st024_external', ace_allowed = { [BankApp.Config.Permissions.ADMIN_ACE] = true } })
  local ace_ok, _, ace_ctx = Auth.RequireAdmin(4243)
  Auth.SetSmokeTestContext({ invoker_resource = 'st024_external', ace_allowed = { ['sonar.bank.role.bank_admin'] = true } })
  local role_ok, _, role_ctx = Auth.RequireAdmin(4244)
  Auth.SetSmokeTestContext({ invoker_resource = 'st024_external', ace_allowed = {} })
  local deny_ok, deny_err = Auth.RequireAdmin(4245)
  Auth.SetSmokeTestContext(nil)
  local after = audit_count('st024_external:auth_denied', 'auth_denied')
  local passed = allow_ok and allow_ctx and allow_ctx.auth_path == 'resource_allowlist'
    and ace_ok and ace_ctx and ace_ctx.auth_path == 'ace'
    and role_ok and role_ctx and role_ctx.auth_path == 'role'
    and deny_ok == false and deny_err == 'AUTH_ACE_DENIED'
    and after > before
  record(results, 'ST-024.7', 'Auth.RequireAdmin 4-tier', passed, ('allow=%s ace=%s role=%s denied_audit_delta=%d'):format(tostring(allow_ctx and allow_ctx.auth_path), tostring(ace_ctx and ace_ctx.auth_path), tostring(role_ctx and role_ctx.auth_path), after - before))
end

local function test_024_8(results)
  local citizen_id = FIXTURE_PREFIX .. 'IDEMP'
  local account = ensure_account(citizen_id, 1005, 10000)
  if not account then return record(results, 'ST-024.8', 'Idempotency replay and collision', false, 'fixture setup failed') end
  local idem, corr = new_uuid(), new_uuid()
  local ok1, err1 = Public.AddMoneyByCitizen(citizen_id, 321, 'ST-024.8 idem', { idempotency_key = idem, correlation_id = corr })
  local ok2, err2 = Public.AddMoneyByCitizen(citizen_id, 321, 'ST-024.8 idem', { idempotency_key = idem, correlation_id = corr })
  local ok3, err3 = Public.AddMoneyByCitizen(citizen_id, 322, 'ST-024.8 idem changed', { idempotency_key = idem, correlation_id = corr })
  record(results, 'ST-024.8', 'Idempotency replay + key reused', ok1 == true and not err1 and ok2 == true and err2 == 'IDEMPOTENCY_REPLAY' and ok3 == false and err3 == 'IDEMPOTENCY_KEY_REUSED', ('replay=%s reused=%s'):format(tostring(err2), tostring(err3)))
end

local function test_024_9(results)
  local citizen_id = FIXTURE_PREFIX .. 'UNITS'
  local account = ensure_account(citizen_id, 1006, 0)
  if not account then return record(results, 'ST-024.9', 'INTEGER minor and DECIMAL DB coherence', false, 'fixture setup failed') end
  local minor = Units.to_minor('12.34')
  local decimal = Units.from_minor(minor)
  local ok, err = Admin.AdminSetBalanceByCitizen(0, citizen_id, minor, 'ST-024.9 units', { idempotency_key = new_uuid(), correlation_id = new_uuid() })
  local row = db_one([[SELECT CAST(ROUND(balance * 100) AS SIGNED) AS balance_minor, balance FROM sonar_bank_accounts WHERE iban = ? LIMIT 1]], { account.iban })
  local db_ok = row and tonumber(row.balance_minor) == minor and string.format('%.2f', tonumber(row.balance or 0)) == decimal
  record(results, 'ST-024.9', 'INTEGER minor input + DECIMAL major DB round-trip', ok == true and not err and minor == 1234 and decimal == '12.34' and db_ok, ('minor=%s decimal=%s db=%s'):format(tostring(minor), tostring(decimal), row and tostring(row.balance) or 'nil'))
end

local function test_024_10(results)
  local manifest = "fx_version 'cerulean'\nserver_scripts { 'server.lua' }\nPlayer.Functions.AddMoney('bank', 100)"
  local hits = LegacyScan and LegacyScan.ScanManifest and LegacyScan.ScanManifest(manifest) or nil
  local found = false
  if hits then
    for _, hit in ipairs(hits) do if hit == 'Player.Functions.AddMoney' then found = true end end
  end
  record(results, 'ST-024.10', '/sonar_scan_legacy fake resource detection', found, hits and table.concat(hits, ',') or 'no hits')
end

function S.Run(opts)
  opts = opts or {}
  local src = tonumber(opts.source) or first_player_source()
  local results = {}
  log(('starting Phase 5 exports smoke source=%s'):format(tostring(src or 'none')))
  if not ensure_schema() then
    record(results, 'ST-024.PREFLIGHT', 'migration 036 schema preflight', false, 'sonar_bank_idem/audit columns/account columns missing')
  end
  test_024_1(results)
  test_024_2(results, src)
  test_024_3(results, src)
  test_024_4(results)
  test_024_5(results, src)
  test_024_6(results)
  test_024_7(results)
  test_024_8(results)
  test_024_9(results)
  test_024_10(results)
  local passed = 0
  for _, result in ipairs(results) do if result.passed then passed = passed + 1 end end
  local ok = passed == #results
  log(('complete ok=%s passed=%d total=%d'):format(tostring(ok), passed, #results))
  return { ok = ok, passed = passed, total = #results, results = results }
end

RegisterCommand('sonar_smoke_phase_5', function(source, args)
  if source ~= 0 then return end
  local src = args and args[1] and tonumber(args[1]) or nil
  CreateThread(function()
    S.Run({ source = src })
  end)
end, true)

return S
