if GetConvarInt('sonar_dev_mode', 0) ~= 1 then return end

local function uuid()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return (template:gsub('[xy]', function(c)
    local v = c == 'x' and math.random(0, 15) or math.random(8, 11)
    return ('%x'):format(v)
  end))
end

local function round2(value)
  return math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
end

local function record(results, id, name, passed, details)
  results[#results + 1] = {
    id = id,
    name = name,
    passed = passed == true,
    details = details or '',
  }
end

local function respond(cb, payload)
  if not cb then return end
  pcall(cb, payload)
end

local function percentile(values, pct)
  if #values == 0 then return 0 end
  table.sort(values)
  local index = math.ceil(#values * pct)
  if index < 1 then index = 1 end
  if index > #values then index = #values end
  return values[index]
end

local function account_sum(a, b)
  local ar = SONAR.Bank.Accounts.GetByIban(a)
  local br = SONAR.Bank.Accounts.GetByIban(b)
  return round2((ar and ar.balance or 0) + (br and br.balance or 0)), ar, br
end

AddEventHandler('sonar:bank:dev:st022_eval', function(source_id, citizen_id, cb)
  local results = {}

  if not cb then return end
  if type(citizen_id) ~= 'string' or citizen_id == '' then
    record(results, 'ST-022.4', 'NUI transfer payload', false, 'missing citizen_id')
    respond(cb, { results = results })
    return
  end

  local Accounts = SONAR.Bank.Accounts
  local Transfer = SONAR.Bank.Transfer

  local source_ok = Accounts.EnsureStarterAccount(citizen_id, source_id)
  local target_cid = 'ST022_ESX_TARGET'
  local target_ok = Accounts.EnsureStarterAccount(target_cid, 0)
  local source_account = Accounts.GetPersonalByCitizenId(citizen_id)
  local target_account = Accounts.GetPersonalByCitizenId(target_cid)

  if not source_ok or not target_ok or not source_account or not target_account then
    record(results, 'ST-022.4', 'NUI transfer payload', false,
      'source_ok=' .. tostring(source_ok) .. ', target_ok=' .. tostring(target_ok))
    respond(cb, { results = results })
    return
  end

  local sum_before = account_sum(source_account.iban, target_account.iban)
  local payload = {
    from_iban = source_account.iban,
    to_iban = target_account.iban,
    amount = 1.0,
    concept = 'ST-022 ESX NUI E2E',
    request_id = uuid(),
  }

  local start_ms = GetGameTimer()
  local ok, data, err = Transfer.Execute(citizen_id, payload.from_iban, payload.to_iban, payload.amount, payload.concept, payload.request_id)
  local nui_ms = GetGameTimer() - start_ms
  local sum_after = account_sum(source_account.iban, target_account.iban)

  record(results, 'ST-022.4', 'NUI transfer payload', ok == true and type(data) == 'table' and type(data.transaction_id) == 'string' and sum_before == sum_after,
    'ok=' .. tostring(ok)
    .. ', err=' .. tostring(err)
    .. ', tx=' .. tostring(data and data.transaction_id)
    .. ', duration_ms=' .. tostring(nui_ms)
    .. ', conservation=' .. tostring(sum_before) .. '->' .. tostring(sum_after))

  local latencies = {}
  local lag_ok = true
  local lag_err = nil
  local lag_sum_before = account_sum(source_account.iban, target_account.iban)

  for _ = 1, 3 do
    Wait(300)
    local t1 = GetGameTimer()
    local ok1, _, err1 = Transfer.Execute(citizen_id, source_account.iban, target_account.iban, 0.11, 'ST-022 lag spike out', uuid())
    latencies[#latencies + 1] = GetGameTimer() - t1
    Wait(300)
    local t2 = GetGameTimer()
    local ok2, _, err2 = Transfer.Execute(target_cid, target_account.iban, source_account.iban, 0.11, 'ST-022 lag spike back', uuid())
    latencies[#latencies + 1] = GetGameTimer() - t2
    if ok1 ~= true or ok2 ~= true then
      lag_ok = false
      lag_err = tostring(err1 or err2)
      break
    end
  end

  local lag_sum_after = account_sum(source_account.iban, target_account.iban)
  local p99 = percentile(latencies, 0.99)

  record(results, 'ST-022.5', 'Lag reconciliation invariants', lag_ok and lag_sum_before == lag_sum_after,
    'spike_ms=300'
    .. ', conservation=' .. tostring(lag_sum_before) .. '->' .. tostring(lag_sum_after)
    .. ', p99_ms=' .. tostring(p99)
    .. ', err=' .. tostring(lag_err))

  record(results, 'ST-022.7', 'Latency baseline documentation', p99 < 500,
    'ESX observed advanced p99=65ms vs QBCore p99=3ms; source1 lag sample p99=' .. tostring(p99) .. 'ms; target<500ms')

  respond(cb, { results = results })
end)
