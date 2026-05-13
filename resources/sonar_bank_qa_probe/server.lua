local RESOURCE = GetCurrentResourceName()
local PREFIX = '[' .. RESOURCE .. ']'
local BANK = 'sonar_bank_app'
local DB_NAME = tostring(GetConvar('sonar_db_database', 'sonar')):match('^[%w_]+$') or 'sonar'

local export_commands = {}

local function encode(value)
  if json and json.encode then
    local ok, result = pcall(json.encode, value)
    if ok then return result end
  end
  if value == nil then return 'null' end
  return tostring(value)
end

local function out(command, ok, err, data)
  print(('%s %s ok=%s err=%s data=%s'):format(PREFIX, command, encode(ok), encode(err), encode(data)))
end

local function parse_value(raw)
  if raw == nil then return nil end
  if raw == 'nil' then return nil end
  if raw == 'true' then return true end
  if raw == 'false' then return false end
  if raw:sub(1, 4) == 'str:' then return raw:sub(5) end
  if raw:sub(1, 4) == 'num:' then return tonumber(raw:sub(5)) end
  local numeric = tonumber(raw)
  if numeric ~= nil then return numeric end
  return raw
end

local function parse_source(raw)
  return tonumber(parse_value(raw))
end

local function parse_target(raw)
  local numeric = tonumber(raw)
  if numeric then return numeric end
  return raw
end

local function parse_opts(args, start_index, default_reason)
  local opts = {}
  local reason = {}
  for i = start_index, #args do
    local token = tostring(args[i] or '')
    if token:sub(1, 5) == 'idem=' then
      opts.idempotency_key = token:sub(6)
    elseif token:sub(1, 5) == 'corr=' then
      opts.correlation_id = token:sub(6)
    elseif token:sub(1, 10) == 'overdraft=' then
      local value = token:sub(11)
      opts.allow_overdraft = value == '1' or value == 'true' or value == 'yes'
    elseif token ~= '' then
      reason[#reason + 1] = token
    end
  end
  local text = #reason > 0 and table.concat(reason, ' ') or default_reason
  return text, opts
end

local function invoke(command, fn)
  local ok, a, b, c = pcall(fn)
  if not ok then
    out(command, false, 'QA_PROBE_EXCEPTION', { raw = tostring(a) })
    return
  end
  out(command, a, b, c)
end

local function register_export_command(name, usage, fn)
  export_commands[#export_commands + 1] = { name = name, usage = usage }
  RegisterCommand(name, function(source, args)
    invoke(name, function() return fn(source, args) end)
  end, false)
end

local function query(command, sql, params)
  local ok, rows = pcall(function() return MySQL.query.await(sql, params or {}) end)
  if not ok then
    out(command, false, 'DB_QUERY_FAILED', { raw = tostring(rows) })
    return
  end
  out(command, true, nil, rows or {})
end

local function citizen_from_source(src)
  local ok, cid = pcall(function() return exports.sonar_bridges:GetCitizenId(src) end)
  if ok and type(cid) == 'string' and cid ~= '' then return cid end
  return nil
end

local function table_ref(name)
  return ('`%s`.`%s`'):format(DB_NAME, name)
end

local function account_select_by_citizen(command, citizen_id)
  query(command, ([[
SELECT a.id, a.iban, sa.char_id, a.balance, CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor, a.is_frozen, a.closed_at, a.updated_at
FROM %s a
INNER JOIN %s sa ON sa.id = a.owner_account_id
WHERE sa.char_id = ?
ORDER BY a.created_at ASC
LIMIT 5
]]):format(table_ref('sonar_bank_accounts'), table_ref('sonar_accounts')), { citizen_id })
end

register_export_command('qa_get_balance', 'qa_get_balance <src>', function(_, args)
  return exports[BANK]:GetBalance(parse_source(args[1]))
end)

register_export_command('qa_get_balance_by_citizen', 'qa_get_balance_by_citizen <citizen_id>', function(_, args)
  return exports[BANK]:GetBalanceByCitizen(args[1])
end)

register_export_command('qa_can_afford', 'qa_can_afford <src> <amount_minor>', function(_, args)
  return exports[BANK]:CanAfford(parse_source(args[1]), parse_value(args[2]))
end)

register_export_command('qa_can_afford_by_citizen', 'qa_can_afford_by_citizen <citizen_id> <amount_minor>', function(_, args)
  return exports[BANK]:CanAffordByCitizen(args[1], parse_value(args[2]))
end)

register_export_command('qa_add_money', 'qa_add_money <src> <amount_minor> [reason...] [idem=uuid] [corr=uuid]', function(_, args)
  local reason, opts = parse_opts(args, 3, 'qa_add_money')
  return exports[BANK]:AddMoney(parse_source(args[1]), parse_value(args[2]), reason, opts)
end)

register_export_command('qa_add_money_by_citizen', 'qa_add_money_by_citizen <citizen_id> <amount_minor> [reason...] [idem=uuid] [corr=uuid]', function(_, args)
  local reason, opts = parse_opts(args, 3, 'qa_add_money_by_citizen')
  return exports[BANK]:AddMoneyByCitizen(args[1], parse_value(args[2]), reason, opts)
end)

register_export_command('qa_remove_money', 'qa_remove_money <src> <amount_minor> [reason...] [idem=uuid] [corr=uuid]', function(_, args)
  local reason, opts = parse_opts(args, 3, 'qa_remove_money')
  return exports[BANK]:RemoveMoney(parse_source(args[1]), parse_value(args[2]), reason, opts)
end)

register_export_command('qa_remove_money_by_citizen', 'qa_remove_money_by_citizen <citizen_id> <amount_minor> [reason...] [idem=uuid] [corr=uuid]', function(_, args)
  local reason, opts = parse_opts(args, 3, 'qa_remove_money_by_citizen')
  return exports[BANK]:RemoveMoneyByCitizen(args[1], parse_value(args[2]), reason, opts)
end)

register_export_command('qa_transfer_by_source', 'qa_transfer_by_source <from_src> <to_src> <amount_minor> [reason...] [idem=uuid] [corr=uuid]', function(_, args)
  local reason, opts = parse_opts(args, 4, 'qa_transfer_by_source')
  return exports[BANK]:TransferBySource(parse_source(args[1]), parse_source(args[2]), parse_value(args[3]), reason, opts)
end)

register_export_command('qa_transfer_by_iban', 'qa_transfer_by_iban <from_iban> <to_iban> <amount_minor> [reason...] [idem=uuid] [corr=uuid]', function(_, args)
  local reason, opts = parse_opts(args, 4, 'qa_transfer_by_iban')
  return exports[BANK]:TransferByIban(args[1], args[2], parse_value(args[3]), reason, opts)
end)

register_export_command('qa_transfer_by_citizen', 'qa_transfer_by_citizen <from_cid> <to_cid> <amount_minor> [reason...] [idem=uuid] [corr=uuid]', function(_, args)
  local reason, opts = parse_opts(args, 4, 'qa_transfer_by_citizen')
  return exports[BANK]:TransferByCitizen(args[1], args[2], parse_value(args[3]), reason, opts)
end)

register_export_command('qa_get_api_version', 'qa_get_api_version', function()
  return true, nil, exports[BANK]:GetApiVersion()
end)

register_export_command('qa_admin_credit', 'qa_admin_credit <actor_src> <target_src|iban|cid> <amount_minor> [reason...] [idem=uuid] [corr=uuid] [overdraft=1]', function(_, args)
  local reason, opts = parse_opts(args, 4, 'qa_admin_credit')
  return exports[BANK]:AdminCredit(parse_source(args[1]), parse_target(args[2]), parse_value(args[3]), reason, opts)
end)

register_export_command('qa_admin_debit', 'qa_admin_debit <actor_src> <target_src|iban|cid> <amount_minor> [reason...] [idem=uuid] [corr=uuid] [overdraft=1]', function(_, args)
  local reason, opts = parse_opts(args, 4, 'qa_admin_debit')
  return exports[BANK]:AdminDebit(parse_source(args[1]), parse_target(args[2]), parse_value(args[3]), reason, opts)
end)

register_export_command('qa_admin_set_balance', 'qa_admin_set_balance <actor_src> <target_src|iban|cid> <new_balance_minor> [reason...] [idem=uuid] [corr=uuid] [overdraft=1]', function(_, args)
  local reason, opts = parse_opts(args, 4, 'qa_admin_set_balance')
  return exports[BANK]:AdminSetBalance(parse_source(args[1]), parse_target(args[2]), parse_value(args[3]), reason, opts)
end)

register_export_command('qa_freeze', 'qa_freeze <actor_src> <target_iban> [reason...]', function(_, args)
  local reason = select(1, parse_opts(args, 3, 'qa_freeze'))
  return exports[BANK]:Freeze(parse_source(args[1]), args[2], reason)
end)

register_export_command('qa_unfreeze', 'qa_unfreeze <actor_src> <target_iban> [reason...]', function(_, args)
  local reason = select(1, parse_opts(args, 3, 'qa_unfreeze'))
  return exports[BANK]:Unfreeze(parse_source(args[1]), args[2], reason)
end)

register_export_command('qa_admin_credit_by_citizen', 'qa_admin_credit_by_citizen <actor_src> <citizen_id> <amount_minor> [reason...] [idem=uuid] [corr=uuid] [overdraft=1]', function(_, args)
  local reason, opts = parse_opts(args, 4, 'qa_admin_credit_by_citizen')
  return exports[BANK]:AdminCreditByCitizen(parse_source(args[1]), args[2], parse_value(args[3]), reason, opts)
end)

register_export_command('qa_admin_debit_by_citizen', 'qa_admin_debit_by_citizen <actor_src> <citizen_id> <amount_minor> [reason...] [idem=uuid] [corr=uuid] [overdraft=1]', function(_, args)
  local reason, opts = parse_opts(args, 4, 'qa_admin_debit_by_citizen')
  return exports[BANK]:AdminDebitByCitizen(parse_source(args[1]), args[2], parse_value(args[3]), reason, opts)
end)

register_export_command('qa_admin_set_balance_by_citizen', 'qa_admin_set_balance_by_citizen <actor_src> <citizen_id> <new_balance_minor> [reason...] [idem=uuid] [corr=uuid] [overdraft=1]', function(_, args)
  local reason, opts = parse_opts(args, 4, 'qa_admin_set_balance_by_citizen')
  return exports[BANK]:AdminSetBalanceByCitizen(parse_source(args[1]), args[2], parse_value(args[3]), reason, opts)
end)

register_export_command('qa_freeze_by_citizen', 'qa_freeze_by_citizen <actor_src> <citizen_id> [reason...]', function(_, args)
  local reason = select(1, parse_opts(args, 3, 'qa_freeze_by_citizen'))
  return exports[BANK]:FreezeByCitizen(parse_source(args[1]), args[2], reason)
end)

register_export_command('qa_unfreeze_by_citizen', 'qa_unfreeze_by_citizen <actor_src> <citizen_id> [reason...]', function(_, args)
  local reason = select(1, parse_opts(args, 3, 'qa_unfreeze_by_citizen'))
  return exports[BANK]:UnfreezeByCitizen(parse_source(args[1]), args[2], reason)
end)

RegisterCommand('qa_help', function()
  print(('%s 22 export wrappers registered'):format(PREFIX))
  for i, command in ipairs(export_commands) do
    print(('%s %02d %s'):format(PREFIX, i, command.usage))
  end
  print(('%s helper qa_context'):format(PREFIX))
  print(('%s helper qa_account_by_src <src>'):format(PREFIX))
  print(('%s helper qa_account_by_citizen <citizen_id>'):format(PREFIX))
  print(('%s helper qa_account_by_iban <iban>'):format(PREFIX))
  print(('%s helper qa_audit <request_nonce>'):format(PREFIX))
  print(('%s helper qa_audit_shape <request_nonce>'):format(PREFIX))
  print(('%s helper qa_movement <request_nonce>'):format(PREFIX))
end, false)

RegisterCommand('qa_context', function()
  out('qa_context', true, nil, {
    resource = RESOURCE,
    bank = BANK,
    export_count = #export_commands,
    sonar_db_database = DB_NAME,
    admin_allowlist = GetConvar('sonar:admin_allowlist', ''),
    bridge_bank = GetConvar('sonar_bridge_bank', ''),
    bridge_identity = GetConvar('sonar_bridge_identity', ''),
    bridge_bank_mode = GetConvar('sonar_bridge_bank_mode', ''),
  })
end, false)

RegisterCommand('qa_account_by_src', function(_, args)
  local src = parse_source(args[1])
  local cid = src and citizen_from_source(src) or nil
  if not cid then
    out('qa_account_by_src', false, 'CITIZEN_NOT_FOUND', { src = src })
    return
  end
  account_select_by_citizen('qa_account_by_src', cid)
end, false)

RegisterCommand('qa_account_by_citizen', function(_, args)
  account_select_by_citizen('qa_account_by_citizen', args[1])
end, false)

RegisterCommand('qa_account_by_iban', function(_, args)
  query('qa_account_by_iban', ([[
SELECT a.id, a.iban, sa.char_id, a.balance, CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor, a.is_frozen, a.closed_at, a.updated_at
FROM %s a
INNER JOIN %s sa ON sa.id = a.owner_account_id
WHERE a.iban = ?
LIMIT 1
]]):format(table_ref('sonar_bank_accounts'), table_ref('sonar_accounts')), { args[1] })
end, false)

RegisterCommand('qa_audit', function(_, args)
  query('qa_audit', ([[
SELECT id, category, action, event_type, actor_account_id, actor_source, target_id, target_account_id, amount, delta_minor, request_nonce, correlation_id, invoker_resource, reason, created_at, previous_flag_snapshot
FROM %s
WHERE request_nonce = ? OR correlation_id = ?
ORDER BY id DESC
LIMIT 10
]]):format(table_ref('sonar_audit_log')), { args[1], args[1] })
end, false)

RegisterCommand('qa_audit_shape', function(_, args)
  query('qa_audit_shape', ([[
SELECT id, event_type,
  actor_account_id IS NOT NULL AS has_actor_account_id,
  target_account_id IS NOT NULL AS has_target_account_id,
  event_type IS NOT NULL AS has_event_type,
  delta_minor IS NOT NULL AS has_delta_minor,
  request_nonce IS NOT NULL AS has_request_nonce,
  correlation_id IS NOT NULL AS has_correlation_id,
  invoker_resource IS NOT NULL AS has_invoker_resource,
  reason IS NOT NULL AND reason <> '' AS has_reason,
  created_at IS NOT NULL AS has_created_at,
  previous_flag_snapshot IS NOT NULL AS has_previous_flag_snapshot
FROM %s
WHERE request_nonce = ? OR correlation_id = ?
ORDER BY id DESC
LIMIT 10
]]):format(table_ref('sonar_audit_log')), { args[1], args[1] })
end, false)

RegisterCommand('qa_movement', function(_, args)
  query('qa_movement', ([[
SELECT id, bank_account_id, occurred_at, amount, balance_after, category, counterpart_iban, concept, related_doc_id, request_nonce, initiated_by_account_id, source_resource
FROM %s
WHERE request_nonce = ? OR related_doc_id = ?
ORDER BY id DESC
LIMIT 10
]]):format(table_ref('sonar_bank_movements')), { args[1], args[1] })
end, false)

AddEventHandler('onResourceStart', function(resource)
  if resource ~= RESOURCE then return end
  print(('%s ready: 22 export wrappers + read-only SQL helpers. Run qa_help.'):format(PREFIX))
end)
