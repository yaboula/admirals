BankApp.services.tax = {}
local S = BankApp.services.tax

local Repo        = BankApp.repos.tax
local Validators  = BankApp.lib.validators
local Errors      = BankApp.lib.errors
local Enums       = BankApp.lib.enums
local Audit       = BankApp.lib.audit
local Idempotency = BankApp.lib.idempotency

local BRACKET_DEFINITIONS = {
  basic = { id = 'basic', code = 'T-I', label = 'BASIC', name = 'basic', income_min = 0, income_max = 1500000, default_rate = 8, population_share = 0.35 },
  standard = { id = 'standard', code = 'T-II', label = 'STANDARD', name = 'standard', income_min = 1500000, income_max = 5000000, default_rate = 18, population_share = 0.45 },
  premium = { id = 'premium', code = 'T-III', label = 'PREMIUM', name = 'premium', income_min = 5000000, income_max = 15000000, default_rate = 28, population_share = 0.15 },
  elite = { id = 'elite', code = 'T-IV', label = 'ELITE', name = 'elite', income_min = 15000000, income_max = nil, default_rate = 38, population_share = 0.05 },
}

local BRACKET_ORDER = { 'basic', 'standard', 'premium', 'elite' }
local CYCLE_DAYS = 14

local function now_ms() return os.time() * 1000 end

local function terminal_context(src)
  local endpoint = nil
  if type(GetPlayerEndpoint) == 'function' and src then
    endpoint = GetPlayerEndpoint(src)
  end
  return {
    terminal_id = ('fivem-src-%s'):format(tostring(src or 0)),
    ip = endpoint,
  }
end

local function acquire_mutation(ctx, callback_id, payload)
  if not Validators.IsValidUUID(ctx.idempotency_key) then
    return nil, nil, Errors.New('VALIDATION_FAILED', { field = 'idempotencyKey' })
  end
  local status, cached, err = Idempotency.Acquire(ctx.idempotency_key, payload, {
    actor_citizen_id = ctx.actor_citizen_id,
    callback_id = callback_id,
    ttl_seconds = BankApp.Config.Idempotency.DEFAULT_TTL_SECONDS,
    domain = 'custom',
    correlation_id = ctx.idempotency_key,
  })
  return status, cached, err
end

local function definition_for_name(name)
  if type(name) ~= 'string' then return nil end
  local normalized = name:lower():gsub('tax_', ''):gsub('income_', '')
  if normalized == 'low' or normalized == 'low_income' then return BRACKET_DEFINITIONS.basic end
  if normalized == 'middle' or normalized == 'middle_class' then return BRACKET_DEFINITIONS.standard end
  if normalized == 'high' or normalized == 'high_income' then return BRACKET_DEFINITIONS.premium end
  if normalized == 'wealth_high' or normalized == 'wealth_tax_high' then return BRACKET_DEFINITIONS.elite end
  return BRACKET_DEFINITIONS[normalized]
end

local function bracket_from_row(row, total_population)
  local def = definition_for_name(row.bracket_name) or BRACKET_DEFINITIONS.basic
  return {
    id = def.id,
    code = def.code,
    label = def.label,
    incomeMin = tonumber(row.incomeMin) or def.income_min,
    incomeMax = row.incomeMax ~= nil and tonumber(row.incomeMax) or def.income_max,
    rate = tonumber(row.rate) or def.default_rate,
    populationShare = def.population_share,
    affectedCount = math.max(0, math.floor((total_population or 0) * def.population_share)),
  }
end

local function default_brackets(total_population)
  local out = {}
  for _, id in ipairs(BRACKET_ORDER) do
    local def = BRACKET_DEFINITIONS[id]
    out[#out + 1] = {
      id = def.id,
      code = def.code,
      label = def.label,
      incomeMin = def.income_min,
      incomeMax = def.income_max,
      rate = def.default_rate,
      populationShare = def.population_share,
      affectedCount = math.max(0, math.floor((total_population or 0) * def.population_share)),
    }
  end
  return out
end

local function total_population()
  local rows = nil
  if BankApp.repos.govt and BankApp.repos.govt.ListCitizens then
    rows = BankApp.repos.govt.ListCitizens(10000)
  end
  if type(rows) == 'table' then return #rows end
  return 0
end

local function actor_account(ctx)
  local actor, err = Repo.GetActorAccount(ctx.actor_citizen_id)
  if err then return nil, err end
  return actor, nil
end

function S.GetBrackets(ctx)
  local population = total_population()
  local rows, err = Repo.ListActiveBrackets()
  if err then return { ok = false, error = err } end
  if not rows or #rows == 0 then return { ok = true, data = default_brackets(population) } end

  local by_id = {}
  for _, row in ipairs(rows) do
    local item = bracket_from_row(row, population)
    by_id[item.id] = item
  end

  local out = {}
  local fallback = default_brackets(population)
  for _, id in ipairs(BRACKET_ORDER) do
    out[#out + 1] = by_id[id] or fallback[#out + 1]
  end
  return { ok = true, data = out }
end

function S.GetCycleStats(ctx)
  local rows, err = Repo.GetCycleDaily(CYCLE_DAYS)
  if err then return { ok = false, error = err } end

  local by_day = {}
  for _, row in ipairs(rows or {}) do
    local age = tonumber(row.dayIndex) or 0
    local day_index = CYCLE_DAYS - 1 - age
    if day_index >= 0 and day_index < CYCLE_DAYS then
      by_day[day_index] = tonumber(row.collectedCents) or 0
    end
  end

  local daily = {}
  local total_collected = 0
  local total_obligation = 0
  for i = 0, CYCLE_DAYS - 1 do
    local collected = by_day[i] or 0
    local obligation = math.max(collected, 8400000 + ((i * 1237 + 3) % 7) * 200000)
    total_collected = total_collected + collected
    total_obligation = total_obligation + obligation
    daily[#daily + 1] = { dayIndex = i, collectedCents = collected, obligationCents = obligation }
  end

  return { ok = true, data = {
    cycleId = os.date('CYC-%Y-%m'),
    cycleStartMs = (os.time() - ((CYCLE_DAYS - 1) * 86400)) * 1000,
    cycleDurationDays = CYCLE_DAYS,
    totalObligationCents = total_obligation,
    totalCollectedCents = total_collected,
    collectedTodayCents = by_day[CYCLE_DAYS - 1] or 0,
    dailySeries = daily,
  } }
end

function S.GetPolicyLog(ctx)
  local rows, err = Repo.ListPolicyHistory(50)
  if err then return { ok = false, error = err } end
  local out = {}
  for _, row in ipairs(rows or {}) do
    local before_def = definition_for_name(row.before_bracket_name or row.after_bracket_name) or BRACKET_DEFINITIONS.basic
    out[#out + 1] = {
      id = tostring(row.id),
      operatorAlias = row.operatorAlias or 'government',
      changedAt = tonumber(row.changedAt) or now_ms(),
      delta = row.before_rate_pct and row.after_rate_pct and {
        { tierId = before_def.id, oldRate = tonumber(row.before_rate_pct) or 0, newRate = tonumber(row.after_rate_pct) or 0 },
      } or {},
      reason = row.reason_note or '',
    }
  end
  return { ok = true, data = out }
end

function S.SaveBrackets(ctx)
  local updates = type(ctx.brackets) == 'table' and ctx.brackets or nil
  if not updates or #updates == 0 then return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'brackets' }) } end

  local status, cached, idem_err = acquire_mutation(ctx, 'GOVT_TAX_BRACKETS_SAVE', { brackets = updates, reason = ctx.reason })
  if status == 'replay' then return { ok = true, data = cached, replayed = true } end
  if status ~= 'acquired' then return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') } end

  local actor, actor_err = actor_account(ctx)
  if actor_err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = actor_err } end
  local rows, list_err = Repo.ListActiveBrackets()
  if list_err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = list_err } end

  local existing = {}
  for _, row in ipairs(rows or {}) do
    local def = definition_for_name(row.bracket_name)
    if def then existing[def.id] = row end
  end

  local reason = Validators.SanitizeReason(ctx.reason) or ''
  local queries = {}
  local delta = {}
  for _, update in ipairs(updates) do
    local def = BRACKET_DEFINITIONS[update.id]
    local new_rate = tonumber(update.rate)
    if not def or not new_rate or new_rate < 0 or new_rate > 100 then
      Idempotency.Orphan(ctx.idempotency_key)
      return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'brackets.rate' }) }
    end

    local row = existing[def.id]
    local old_rate = row and (tonumber(row.rate) or def.default_rate) or def.default_rate
    if old_rate ~= new_rate then
      local next_queries = row
        and Repo.BuildUpdateBracketQuery(row, new_rate, actor and actor.id or nil, reason)
        or Repo.BuildInsertBracketQueries(def, new_rate, actor and actor.id or nil, reason)
      for _, q in ipairs(next_queries) do queries[#queries + 1] = q end
      delta[#delta + 1] = { tierId = def.id, oldRate = old_rate, newRate = new_rate }
    end
  end

  if #queries > 0 then
    local ok, tx_err = Repo.ApplyBracketQueries(queries)
    if not ok then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = tx_err } end
  end

  local terminal = terminal_context(ctx.src)
  Audit.Write({
    event_type = Enums.AUDIT_EVENT_TYPE.GOVT_TAX_BRACKETS_SAVE,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src = ctx.src,
    actor_role = 'government',
    actor_account_id = actor and actor.id or nil,
    request_nonce = ctx.idempotency_key,
    severity = 'notice',
    event_data = {
      reason = reason,
      terminal_id = terminal.terminal_id,
      ip = terminal.ip,
      delta = delta,
      idempotency_key = ctx.idempotency_key,
    },
    correlation_id = ctx.idempotency_key,
  })

  local result = { changed = #delta, delta = delta, committedAt = now_ms(), correlationId = ctx.idempotency_key }
  Idempotency.Commit(ctx.idempotency_key, result)
  return { ok = true, data = result }
end

function S.ForceCollection(ctx)
  local status, cached, idem_err = acquire_mutation(ctx, 'GOVT_TAX_FORCE_COLLECTION', { reason = ctx.reason })
  if status == 'replay' then return { ok = true, data = cached, replayed = true } end
  if status ~= 'acquired' then return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') } end

  local actor, actor_err = actor_account(ctx)
  if actor_err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = actor_err } end
  local reason = Validators.SanitizeReason(ctx.reason) or ''
  local terminal = terminal_context(ctx.src)
  Audit.Write({
    event_type = Enums.AUDIT_EVENT_TYPE.GOVT_TAX_FORCE_COLLECTION,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src = ctx.src,
    actor_role = 'government',
    actor_account_id = actor and actor.id or nil,
    request_nonce = ctx.idempotency_key,
    severity = 'warning',
    event_data = {
      reason = reason,
      terminal_id = terminal.terminal_id,
      ip = terminal.ip,
      mode = 'manual_force_collection',
      idempotency_key = ctx.idempotency_key,
    },
    correlation_id = ctx.idempotency_key,
  })

  local result = { forced = true, committedAt = now_ms(), correlationId = ctx.idempotency_key }
  Idempotency.Commit(ctx.idempotency_key, result)
  return { ok = true, data = result }
end

return S
