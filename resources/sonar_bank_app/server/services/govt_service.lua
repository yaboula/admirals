BankApp.services.govt = {}
local S = BankApp.services.govt

local Repo        = BankApp.repos.govt
local RiskEngine  = BankApp.services.risk_engine
local Validators  = BankApp.lib.validators
local Errors      = BankApp.lib.errors
local Enums       = BankApp.lib.enums
local Audit       = BankApp.lib.audit
local Idempotency = BankApp.lib.idempotency
local DB          = BankApp.lib.db

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

local function map_flag_severity(severity)
  if severity == 'critical' then return 'high' end
  if severity == 'warning' then return 'medium' end
  if severity == 'notice' then return 'low' end
  return 'info'
end

local function map_flag_status(status)
  if status == 'investigating' then return 'reviewing' end
  if status == 'false_positive' then return 'dismissed' end
  return status or 'open'
end

local function citizen_status(row)
  if DB.ToBool(row.anyFrozen) then return 'sanctioned' end
  if (tonumber(row.flagCount) or 0) > 0 then return 'flagged' end
  return 'active'
end

local function tax_status_for(total_holdings)
  local obligation = math.floor((tonumber(total_holdings) or 0) * 0.05)
  return {
    bracketCode = 'MVP',
    periodObligation = obligation,
    paid = 0,
    outstanding = obligation,
  }
end

local function summary_from_row(row)
  local created_ms = tonumber(row.created_ms) or now_ms()
  return {
    cid = row.cid,
    alias = row.alias or row.cid,
    status = citizen_status(row),
    taxCompliance = 'current',
    riskScore = tonumber(row.riskScore) or 12,
    riskLevel = row.riskLevel or 'low',
    totalHoldings = tonumber(row.totalHoldings) or 0,
    accountCount = tonumber(row.accountCount) or 0,
    flagCount = tonumber(row.flagCount) or 0,
    lastActivityAt = tonumber(row.lastActivityAt) or created_ms,
    residencyDays = math.max(0, math.floor((now_ms() - created_ms) / 86400000)),
  }
end

local function flag_summary(row)
  local observed = tonumber(row.observed_value) or 0
  if row.flag_type == 'large_transfer' then
    return ('Large outgoing transfer detected: %.2f'):format(observed)
  end
  if row.flag_type == 'velocity' then
    return ('Velocity rule triggered: %.0f movements in window'):format(observed)
  end
  if row.flag_type == 'structuring' then
    return 'Transfer pattern toward frozen or suspicious account'
  end
  return row.flag_type or 'Compliance flag'
end

local function flag_from_row(row)
  return {
    id = tostring(row.id or row.flagId),
    raisedAt = tonumber(row.raisedAt) or now_ms(),
    severity = map_flag_severity(row.severity),
    status = map_flag_status(row.status),
    summary = flag_summary(row),
  }
end

local function queue_item_from_row(row)
  return {
    flagId = tostring(row.flagId),
    citizenCid = row.citizenCid,
    citizenAlias = row.citizenAlias or row.citizenCid,
    citizenStatus = row.citizenStatus or 'flagged',
    citizenRiskLevel = row.citizenRiskLevel or 'low',
    raisedAt = tonumber(row.raisedAt) or now_ms(),
    severity = map_flag_severity(row.severity),
    status = map_flag_status(row.status),
    summary = flag_summary(row),
  }
end

local function action_result(action_type, ctx, target_alias, extra)
  extra = extra or {}
  return {
    id = extra.id or ctx.idempotency_key,
    type = action_type,
    targetCid = ctx.target_cid,
    targetAlias = target_alias or ctx.target_cid,
    relatedFlagId = ctx.related_flag_id,
    amount = extra.amount,
    verdict = extra.verdict,
    reason = Validators.SanitizeReason(ctx.reason) or '',
    operator = ctx.actor_citizen_id,
    performedAt = now_ms(),
    idempotencyKey = ctx.idempotency_key,
  }
end

local function decode_json_object(value)
  if type(value) == 'table' then return value end
  if type(value) ~= 'string' or value == '' then return {} end
  if json and json.decode then
    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then return decoded end
  end
  return {}
end

local function sanction_action_type(event_type)
  if event_type == Enums.AUDIT_EVENT_TYPE.GOVT_FLAG_CLOSE then return 'close_flag' end
  if event_type == Enums.AUDIT_EVENT_TYPE.GOVT_FREEZE then return 'freeze_accounts' end
  if event_type == Enums.AUDIT_EVENT_TYPE.GOVT_UNFREEZE then return 'lift_freeze' end
  if event_type == Enums.AUDIT_EVENT_TYPE.GOVT_FINE_APPLY then return 'apply_fine' end
  return 'close_flag'
end

local function sanction_action_from_row(row)
  local context = decode_json_object(row.context_data)
  local event_data = decode_json_object(context.event_data)
  local target_cid = context.target_citizen_id or event_data.target_citizen_id or ''
  return {
    id = tostring(context.audit_id or row.id),
    type = sanction_action_type(row.event_type),
    targetCid = target_cid,
    targetAlias = event_data.target_alias or target_cid,
    relatedFlagId = event_data.related_flag_id,
    amount = event_data.amount and tonumber(event_data.amount) or nil,
    verdict = event_data.verdict,
    reason = event_data.reason or '',
    operator = row.operatorAlias or 'government',
    performedAt = tonumber(row.performedAt) or now_ms(),
    idempotencyKey = row.idempotencyKey or context.request_nonce or event_data.idempotency_key or '',
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

function S.ListCensus(ctx)
  local rows, err = Repo.ListCitizens(200)
  if err then return { ok = false, error = err } end
  local out = {}
  local filters = ctx.filters or {}
  local search = type(filters.search) == 'string' and filters.search:lower() or ''
  for _, row in ipairs(rows or {}) do
    local computed = RiskEngine.RecomputeCitizen(row.cid, 'government')
    if computed then
      row.riskScore = computed.score
      row.riskLevel = computed.riskLevel
    end
    local item = summary_from_row(row)
    local include = true
    if search ~= '' then
      include = item.cid:lower():find(search, 1, true) ~= nil or item.alias:lower():find(search, 1, true) ~= nil
    end
    if include and filters.status and filters.status ~= 'all' then include = item.status == filters.status end
    if include and filters.riskLevel and filters.riskLevel ~= 'all' then include = item.riskLevel == filters.riskLevel end
    if include and filters.compliance and filters.compliance ~= 'all' then include = item.taxCompliance == filters.compliance end
    if include then out[#out + 1] = item end
  end
  return { ok = true, data = out }
end

function S.GetCitizenDetail(ctx)
  if not Validators.IsValidCitizenId(ctx.cid) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  RiskEngine.RecomputeCitizen(ctx.cid, 'government')
  local row, err = Repo.GetCitizen(ctx.cid)
  if err then return { ok = false, error = err } end
  if not row then return { ok = true, data = nil } end
  local activity, activity_err = Repo.ListCitizenActivity(ctx.cid, 20)
  if activity_err then return { ok = false, error = activity_err } end
  local flags, flags_err = Repo.ListCitizenFlags(ctx.cid, 20)
  if flags_err then return { ok = false, error = flags_err } end
  local data = summary_from_row(row)
  data.primaryIban = row.primaryIban
  data.recentActivity = activity or {}
  data.flags = {}
  for _, flag in ipairs(flags or {}) do data.flags[#data.flags + 1] = flag_from_row(flag) end
  data.taxStatus = tax_status_for(data.totalHoldings)
  return { ok = true, data = data }
end

function S.ListFlagQueue(ctx)
  local rows, err = Repo.ListFlagQueue(200)
  if err then return { ok = false, error = err } end
  local out = {}
  local filters = ctx.filters or {}
  local search = type(filters.search) == 'string' and filters.search:lower() or ''
  for _, row in ipairs(rows or {}) do
    local item = queue_item_from_row(row)
    local include = true
    if search ~= '' then
      include = item.flagId:lower():find(search, 1, true) ~= nil or item.citizenCid:lower():find(search, 1, true) ~= nil or item.citizenAlias:lower():find(search, 1, true) ~= nil
    end
    if include and filters.severity and filters.severity ~= 'all' then include = item.severity == filters.severity end
    if include and filters.status and filters.status ~= 'all' then include = item.status == filters.status end
    if include then out[#out + 1] = item end
  end
  return { ok = true, data = out }
end

function S.GetFlagDetail(ctx)
  local row, err = Repo.GetFlag(ctx.flag_id)
  if err then return { ok = false, error = err } end
  if not row then return { ok = true, data = nil } end
  return { ok = true, data = queue_item_from_row({
    flagId = tostring(row.id),
    citizenCid = row.citizenCid,
    citizenAlias = row.citizenAlias,
    citizenStatus = 'flagged',
    citizenRiskLevel = 'medium',
    raisedAt = (tonumber(row.raised_at) or os.time()) * 1000,
    severity = row.severity,
    status = row.status,
    flag_type = row.flag_type,
    observed_value = row.observed_value,
  }) }
end

function S.IsCitizenFrozen(ctx)
  if not Validators.IsValidCitizenId(ctx.target_cid) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  local accounts, err = Repo.ListAccountsByCitizen(ctx.target_cid)
  if err then return { ok = false, error = err } end
  for _, account in ipairs(accounts or {}) do
    if DB.ToBool(account.is_frozen) then return { ok = true, data = true } end
  end
  return { ok = true, data = false }
end

function S.ListSanctionActions(ctx)
  if ctx.target_cid and not Validators.IsValidCitizenId(ctx.target_cid) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  local rows, err = Repo.ListSanctionActions(ctx.target_cid, 50)
  if err then return { ok = false, error = err } end
  local out = {}
  for _, row in ipairs(rows or {}) do
    out[#out + 1] = sanction_action_from_row(row)
  end
  return { ok = true, data = out }
end

function S.GetSanctionKpis(ctx)
  local queue = S.ListFlagQueue({ filters = {} })
  if not queue.ok then return queue end
  local open, critical = 0, 0
  for _, item in ipairs(queue.data or {}) do
    if item.status == 'open' then open = open + 1 end
    if (item.severity == 'high' or item.severity == 'critical') and item.status ~= 'resolved' and item.status ~= 'dismissed' then
      critical = critical + 1
    end
  end
  return { ok = true, data = { open = open, critical = critical, today = 0, total = #(queue.data or {}) } }
end

function S.CloseFlag(ctx)
  local status, cached, idem_err = acquire_mutation(ctx, 'GOVT_CLOSE_FLAG', {
    flag_id = ctx.flag_id,
    verdict = ctx.verdict,
    reason = ctx.reason,
  })
  if status == 'replay' then return { ok = true, data = cached, replayed = true } end
  if status ~= 'acquired' then return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') } end

  local flag, flag_err = Repo.GetFlag(ctx.flag_id)
  if flag_err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = flag_err } end
  if not flag then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'flagId' }) } end

  local action_taken = ctx.verdict == 'dismissed' and 'dismissed_by_government' or 'resolved_by_government'
  local _, close_err = Repo.CloseFlag(ctx.flag_id, ctx.actor_citizen_id, ctx.verdict, action_taken, Validators.SanitizeReason(ctx.reason))
  if close_err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = close_err } end

  local target_cid = flag.citizenCid
  local terminal = terminal_context(ctx.src)
  Audit.Write({
    event_type = Enums.AUDIT_EVENT_TYPE.GOVT_FLAG_CLOSE,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src = ctx.src,
    actor_role = 'government',
    target_citizen_id = target_cid,
    previous_flag_snapshot = {
      flag_id = tostring(flag.id),
      status = flag.status,
      severity = flag.severity,
      flag_type = flag.flag_type,
    },
    request_nonce = ctx.idempotency_key,
    severity = 'notice',
    event_data = {
      reason = Validators.SanitizeReason(ctx.reason),
      terminal_id = terminal.terminal_id,
      ip = terminal.ip,
      idempotency_key = ctx.idempotency_key,
      verdict = ctx.verdict,
    },
    correlation_id = ctx.idempotency_key,
  })

  ctx.target_cid = target_cid
  ctx.related_flag_id = tostring(flag.id)
  local result = action_result('close_flag', ctx, flag.citizenAlias, { verdict = ctx.verdict })
  Idempotency.Commit(ctx.idempotency_key, result)
  return { ok = true, data = result }
end

local function freeze_helper(ctx, frozen)
  local action_type = frozen and 'freeze_accounts' or 'lift_freeze'
  local callback_id = frozen and 'GOVT_FREEZE_ACCOUNTS' or 'GOVT_LIFT_FREEZE'
  if not Validators.IsValidCitizenId(ctx.target_cid) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end

  local status, cached, idem_err = acquire_mutation(ctx, callback_id, {
    target_cid = ctx.target_cid,
    frozen = frozen,
    reason = ctx.reason,
    related_flag_id = ctx.related_flag_id,
  })
  if status == 'replay' then return { ok = true, data = cached, replayed = true } end
  if status ~= 'acquired' then return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') } end

  local accounts, acc_err = Repo.ListAccountsByCitizen(ctx.target_cid)
  if acc_err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = acc_err } end
  if #accounts == 0 then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = Errors.New('ACCOUNT_NOT_FOUND') } end

  local _, set_err = Repo.SetCitizenFrozen(ctx.target_cid, frozen)
  if set_err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = set_err } end

  local target = Repo.GetAccountByCitizen(ctx.target_cid)
  local terminal = terminal_context(ctx.src)
  Audit.Write({
    event_type = frozen and Enums.AUDIT_EVENT_TYPE.GOVT_FREEZE or Enums.AUDIT_EVENT_TYPE.GOVT_UNFREEZE,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src = ctx.src,
    actor_role = 'government',
    target_citizen_id = ctx.target_cid,
    previous_flag_snapshot = {
      target_cid = ctx.target_cid,
      accounts = accounts,
    },
    request_nonce = ctx.idempotency_key,
    severity = frozen and 'critical' or 'notice',
    event_data = {
      reason = Validators.SanitizeReason(ctx.reason),
      terminal_id = terminal.terminal_id,
      ip = terminal.ip,
      idempotency_key = ctx.idempotency_key,
      related_flag_id = ctx.related_flag_id,
      frozen = frozen,
    },
    correlation_id = ctx.idempotency_key,
  })

  RiskEngine.RecomputeCitizen(ctx.target_cid, 'government')
  local result = action_result(action_type, ctx, target and target.alias or ctx.target_cid)
  Idempotency.Commit(ctx.idempotency_key, result)
  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(ctx.target_cid)
  end
  return { ok = true, data = result }
end

function S.FreezeAccounts(ctx)
  return freeze_helper(ctx, true)
end

function S.LiftFreeze(ctx)
  return freeze_helper(ctx, false)
end

function S.ApplyFine(ctx)
  if not Validators.IsValidCitizenId(ctx.target_cid) then return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') } end
  if not Validators.IsValidAmountMinor(ctx.amount) then return { ok = false, error = Errors.New('INVALID_AMOUNT') } end

  local status, cached, idem_err = acquire_mutation(ctx, 'GOVT_APPLY_FINE', {
    target_cid = ctx.target_cid,
    amount = ctx.amount,
    reason = ctx.reason,
    related_flag_id = ctx.related_flag_id,
  })
  if status == 'replay' then return { ok = true, data = cached, replayed = true } end
  if status ~= 'acquired' then return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') } end

  local accounts, acc_err = Repo.ListAccountsByCitizen(ctx.target_cid)
  if acc_err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = acc_err } end
  local payer = nil
  for _, account in ipairs(accounts or {}) do
    if not DB.ToBool(account.is_frozen) and (tonumber(account.balance_minor) or 0) >= ctx.amount then
      payer = account
      break
    end
  end
  if not payer then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS') } end

  local actor = Repo.GetAccountByCitizen(ctx.actor_citizen_id)
  local concept = Validators.SanitizeReason(ctx.reason) or 'government fine'
  local ok, tx_err = DB.Transaction({
    Repo.BuildDebitFineQuery(payer.account_id, ctx.amount),
    Repo.BuildInsertFineMovementQuery(payer.account_id, ctx.amount, concept, ctx.related_flag_id or ctx.idempotency_key, ctx.idempotency_key, actor and actor.id or nil),
  })
  if not ok then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = tx_err } end

  local target = Repo.GetAccountByCitizen(ctx.target_cid)
  local terminal = terminal_context(ctx.src)
  Audit.Write({
    event_type = Enums.AUDIT_EVENT_TYPE.GOVT_FINE_APPLY,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src = ctx.src,
    actor_role = 'government',
    actor_account_id = actor and actor.id or nil,
    target_citizen_id = ctx.target_cid,
    target_account_id = payer.account_id,
    target_iban = payer.iban,
    request_nonce = ctx.idempotency_key,
    severity = 'warning',
    event_data = {
      reason = concept,
      terminal_id = terminal.terminal_id,
      ip = terminal.ip,
      idempotency_key = ctx.idempotency_key,
      related_flag_id = ctx.related_flag_id,
      amount = ctx.amount,
    },
    correlation_id = ctx.idempotency_key,
  })

  RiskEngine.RecomputeCitizen(ctx.target_cid, 'government')
  local result = action_result('apply_fine', ctx, target and target.alias or ctx.target_cid, { amount = ctx.amount })
  Idempotency.Commit(ctx.idempotency_key, result)
  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(ctx.target_cid)
  end
  return { ok = true, data = result }
end

function S.GetTreasuryPage(ctx)
  local page = tonumber(ctx.page) or 1
  if page < 1 then page = 1 end
  local per_page = tonumber(ctx.per_page) or 15
  if per_page < 1 or per_page > 50 then per_page = 15 end
  local rows, err = Repo.ListTreasuryMovements(per_page, (page - 1) * per_page)
  if err then return { ok = false, error = err } end
  local stats, stats_err = Repo.GetTreasuryStats(2592000)
  if stats_err then return { ok = false, error = stats_err } end
  stats = stats or {}
  stats.totalInflow = tonumber(stats.totalInflow) or 0
  stats.totalOutflow = tonumber(stats.totalOutflow) or 0
  stats.netBalance = stats.totalInflow - stats.totalOutflow
  stats.movementCount = tonumber(stats.movementCount) or #(rows or {})
  stats.taxCollected = tonumber(stats.taxCollected) or 0
  stats.finesCollected = tonumber(stats.finesCollected) or 0
  stats.subsidiesIssued = tonumber(stats.subsidiesIssued) or 0
  return { ok = true, data = { items = rows or {}, totalCount = stats.movementCount, stats = stats } }
end

function S.GetSubsidyStats(ctx)
  local stats, err = Repo.GetSubsidyStats()
  if err then return { ok = false, error = err } end
  return { ok = true, data = stats or { totalDisbursed = 0, totalBudget = 0, activeProgramCount = 0, totalBeneficiaries = 0, pendingDisbursements = 0 } }
end

function S.ListSubsidyPrograms(ctx)
  local rows, err = Repo.ListSubsidyPrograms(100)
  if err then return { ok = false, error = err } end
  return { ok = true, data = rows or {} }
end

function S.GetSubsidyDetail(ctx)
  local program, err = Repo.GetSubsidyProgram(ctx.program_id)
  if err then return { ok = false, error = err } end
  if not program then return { ok = true, data = nil } end
  local disbursements, disb_err = Repo.ListSubsidyDisbursements(program.programId, 20)
  if disb_err then return { ok = false, error = disb_err } end
  program.recentDisbursements = disbursements or {}
  return { ok = true, data = program }
end

function S.GetReports(ctx)
  local treasury = S.GetTreasuryPage({ page = 1, per_page = 50 })
  if not treasury.ok then return treasury end
  local census = S.ListCensus({ filters = {} })
  if not census.ok then return census end
  local risk = { low = 0, medium = 0, high = 0, critical = 0 }
  for _, citizen in ipairs(census.data or {}) do
    risk[citizen.riskLevel] = (risk[citizen.riskLevel] or 0) + 1
  end
  local stats = treasury.data.stats
  local total_obligation = math.floor((stats.taxCollected or 0) * 1.25)
  return { ok = true, data = {
    range = ctx.range or 'month',
    kpis = {
      totalRevenue = stats.totalInflow or 0,
      totalObligation = total_obligation,
      complianceRate = total_obligation > 0 and math.floor(((stats.taxCollected or 0) / total_obligation) * 100) or 100,
      activeTaxpayers = #(census.data or {}),
      revenueVsPriorPct = 0,
    },
    revenueHistory = {
      { label = 'MVP', collected = stats.taxCollected or 0, obligation = total_obligation },
    },
    sectorRevenue = {},
    topContributors = {},
    complianceBreakdown = { current = #(census.data or {}), overdue = 0, pending = 0, exempt = 0 },
    riskBreakdown = risk,
  } }
end

return S
