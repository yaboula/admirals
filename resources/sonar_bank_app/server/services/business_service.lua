BankApp.services.business = {}
local S = BankApp.services.business

local Repo       = BankApp.repos.business
local Validators = BankApp.lib.validators
local Errors     = BankApp.lib.errors
local UUID       = BankApp.lib.uuid
local Idempotency = BankApp.lib.idempotency
local Audit      = BankApp.lib.audit
local Enums      = BankApp.lib.enums

local function now_ms() return os.time() * 1000 end

local function encode_json(t)
  if json and json.encode then return json.encode(t) end
  return tostring(t)
end

local function is_valid_company_id(company_id)
  return Validators.IsValidUUID(company_id) or Validators.IsNonEmptyString(company_id)
end

local function map_member_role(role)
  if role == 'founder' or role == 'co-founder' or role == 'owner' then return 'owner' end
  if role == 'director' or role == 'manager' or role == 'employee_authorized' then return 'manager' end
  return 'employee'
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

local function flag_summary(row)
  local observed = tonumber(row.observed_value) or 0
  if row.flag_type == 'large_transfer' then
    return ('Large business movement detected: %.2f'):format(observed)
  end
  if row.flag_type == 'velocity' then
    return ('Business velocity rule triggered: %.0f movements in window'):format(observed)
  end
  return row.flag_type or 'Business compliance flag'
end

local function tax_status_for(treasury)
  local obligation = math.floor((tonumber(treasury) or 0) * 0.03)
  return {
    bracketCode = 'BUS-MVP',
    periodObligation = obligation,
    paid = 0,
    outstanding = obligation,
  }
end

local function summary_from_row(row)
  local founded_at = tonumber(row.foundedAt) or now_ms()
  return {
    companyId = row.companyId,
    name = row.name or row.companyId,
    status = row.status or 'active',
    sector = row.sector or 'other',
    foundedAt = founded_at,
    employeeCount = tonumber(row.employeeCount) or 0,
    treasury = tonumber(row.treasury) or 0,
    taxCompliance = 'current',
    riskLevel = row.riskLevel or 'low',
    riskScore = tonumber(row.riskScore) or 12,
    flagCount = tonumber(row.flagCount) or 0,
    lastActivityAt = tonumber(row.lastActivityAt) or founded_at,
  }
end

local function flag_from_row(row)
  return {
    id = tostring(row.id),
    raisedAt = tonumber(row.raisedAt) or now_ms(),
    severity = map_flag_severity(row.severity),
    status = map_flag_status(row.status),
    summary = flag_summary(row),
  }
end

local function mask_iban(iban)
  if type(iban) ~= 'string' or #iban < 8 then return iban or '' end
  return ('%s ···· %s'):format(iban:sub(1, 4), iban:sub(-4))
end

local function decode_json_array(raw)
  if type(raw) == 'table' then return raw end
  if type(raw) ~= 'string' or raw == '' then return {} end
  if json and json.decode then
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == 'table' then return decoded end
  end
  return {}
end

local function has_decision(decisions, account_id)
  for _, decision in ipairs(decisions or {}) do
    if decision.signer_account_id == account_id then return decision end
  end
  return nil
end

local function count_approved(decisions)
  local approved_count = 0
  for _, decision in ipairs(decisions or {}) do
    if decision.decision == 'approved' then approved_count = approved_count + 1 end
  end
  return approved_count
end

local function prepare_execution_lines(lines, treasury_balance)
  local executable_lines = {}
  local total_ready = 0
  local running_treasury = tonumber(treasury_balance) or 0
  for _, line in ipairs(lines or {}) do
    line.net_amount = tonumber(line.net_amount) or 0
    line.destination_balance = tonumber(line.destination_balance) or 0
    if line.state == 'ready' then
      total_ready = total_ready + line.net_amount
      running_treasury = running_treasury - line.net_amount
      line.destination_balance_after = line.destination_balance + line.net_amount
      executable_lines[#executable_lines + 1] = line
    end
  end
  return executable_lines, total_ready, running_treasury
end

local function acquire_idempotency(ctx, callback_id, payload, actor_account_id, bank_account_id)
  local status, cached, err = Idempotency.Acquire(ctx.idempotency_key, payload, {
    actor_citizen_id = ctx.actor_citizen_id,
    actor_account_id = actor_account_id,
    bank_account_id = bank_account_id,
    callback_id = callback_id,
    domain = 'business',
    correlation_id = ctx.correlation_id or ctx.idempotency_key,
  })
  if status == 'replay' then return false, { ok = true, data = cached, replayed = true } end
  if status ~= 'acquired' then return false, { ok = false, error = err } end
  return true, nil
end

function S.ListGovtBusinesses(ctx)
  local rows, err = Repo.ListCompanies(200)
  if err then return { ok = false, error = err } end
  local filters = ctx.filters or {}
  local search = type(filters.search) == 'string' and filters.search:lower() or ''
  local out = {}
  for _, row in ipairs(rows or {}) do
    local item = summary_from_row(row)
    local include = true
    if search ~= '' then
      include = item.companyId:lower():find(search, 1, true) ~= nil or item.name:lower():find(search, 1, true) ~= nil
    end
    if include and filters.status and filters.status ~= 'all' then include = item.status == filters.status end
    if include and filters.sector and filters.sector ~= 'all' then include = item.sector == filters.sector end
    if include and filters.compliance and filters.compliance ~= 'all' then include = item.taxCompliance == filters.compliance end
    if include then out[#out + 1] = item end
  end
  return { ok = true, data = out }
end

function S.GetGovtBusinessDetail(ctx)
  if not is_valid_company_id(ctx.company_id) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'companyId' }) }
  end
  local row, err = Repo.GetCompany(ctx.company_id)
  if err then return { ok = false, error = err } end
  if not row then return { ok = true, data = nil } end

  local directors, directors_err = Repo.ListCompanyDirectors(ctx.company_id, 8)
  if directors_err then return { ok = false, error = directors_err } end
  local activity, activity_err = Repo.ListCompanyActivity(ctx.company_id, 20)
  if activity_err then return { ok = false, error = activity_err } end
  local flags, flags_err = Repo.ListCompanyFlags(ctx.company_id, 20)
  if flags_err then return { ok = false, error = flags_err } end

  local data = summary_from_row(row)
  data.ibanPrimary = row.ibanPrimary or ''
  data.directors = directors or {}
  data.recentActivity = activity or {}
  data.flags = {}
  for _, flag in ipairs(flags or {}) do data.flags[#data.flags + 1] = flag_from_row(flag) end
  data.payrollMonthly = tonumber(row.payrollMonthly) or 0
  data.taxStatus = tax_status_for(data.treasury)
  data.operatingDays = math.max(0, math.floor((now_ms() - data.foundedAt) / 86400000))
  return { ok = true, data = data }
end

function S.GetTreasurySnapshot(ctx)
  if not is_valid_company_id(ctx.company_id) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'company_id' }) }
  end
  local row, err = Repo.GetTreasurySnapshot(ctx.company_id, ctx.actor_citizen_id)
  if err then return { ok = false, error = err } end
  if not row then return { ok = false, error = Errors.New('RESOURCE_NOT_FOUND', { field = 'company_id' }) } end

  local movements, movements_err = Repo.ListBusinessMovements(ctx.company_id, 12)
  if movements_err then return { ok = false, error = movements_err } end
  local approvals, approvals_err = Repo.ListPendingApprovals(ctx.company_id, 8)
  if approvals_err then return { ok = false, error = approvals_err } end

  local balance = tonumber(row.balance_minor) or 0
  local inflow, outflow = 0, 0
  for _, movement in ipairs(movements or {}) do
    if movement.direction == 'in' then inflow = inflow + (tonumber(movement.amount_minor) or 0) end
    if movement.direction == 'out' then outflow = outflow + (tonumber(movement.amount_minor) or 0) end
  end
  local basis = balance ~= 0 and math.abs(balance) or 1
  local delta = ((inflow - outflow) / basis) * 100

  return { ok = true, data = {
    company_id = row.company_id,
    company_name = row.company_name,
    role = map_member_role(row.member_role),
    treasury_iban_masked = mask_iban(row.iban),
    balance_minor = balance,
    currency = 'USD',
    delta_4w_pct = delta,
    employee_count = tonumber(row.employee_count) or 0,
    average_tenure_days = tonumber(row.average_tenure_days) or 0,
    total_payroll_month_minor = tonumber(row.total_payroll_month_minor) or 0,
    recent_movements = movements or {},
    pending_approvals = approvals or {},
    fetched_at_ms = now_ms(),
  } }
end

function S.GetPayrollPreview(ctx)
  if not is_valid_company_id(ctx.company_id) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'company_id' }) }
  end
  local row, err = Repo.GetTreasurySnapshot(ctx.company_id, ctx.actor_citizen_id)
  if err then return { ok = false, error = err } end
  if not row then return { ok = false, error = Errors.New('RESOURCE_NOT_FOUND', { field = 'company_id' }) } end

  local lines, lines_err = Repo.ListPayrollLines(ctx.company_id, 24)
  if lines_err then return { ok = false, error = lines_err } end
  local total = 0
  for _, line in ipairs(lines or {}) do total = total + (tonumber(line.net_amount_minor) or 0) end

  return { ok = true, data = {
    company_id = ctx.company_id,
    batch_id = ('payroll-preview-%s'):format(ctx.company_id),
    employee_count = #(lines or {}),
    total_net_minor = total,
    currency = 'USD',
    requires_approvals = tonumber(row.signing_threshold) or 1,
    scheduled_for_ms = now_ms() + 86400000,
    lines = lines or {},
    fetched_at_ms = now_ms(),
  } }
end

function S.RequestPayrollExecution(ctx)
  if not is_valid_company_id(ctx.company_id) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'company_id' }) }
  end
  if not Validators.IsValidUUID(ctx.idempotency_key) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'idempotency_key', reason = 'must be UUID v4' }) }
  end

  local exec, exec_err = Repo.GetPayrollExecutionContext(ctx.company_id, ctx.actor_citizen_id)
  if exec_err then return { ok = false, error = exec_err } end
  if not exec then return { ok = false, error = Errors.New('RESOURCE_NOT_FOUND', { field = 'company_id' }) } end

  local acquired, replay = acquire_idempotency(ctx, 'REQ-FE-015E', { company_id = ctx.company_id, operation = 'payroll_execute' }, exec.actor_account_id, exec.treasury_account_id)
  if not acquired then return replay end

  local lines, lines_err = Repo.ListPayrollExecutionLines(ctx.company_id)
  if lines_err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = lines_err } end

  local batch_lines, total, held = {}, 0, 0
  for _, line in ipairs(lines or {}) do
    local amount = tonumber(line.net_amount) or 0
    if amount > 0 and line.destination_bank_account_id then
      local state = line.state == 'ready' and 'ready' or 'held'
      if state == 'ready' then total = total + amount else held = held + 1 end
      batch_lines[#batch_lines + 1] = {
        id = UUID.V4(),
        employee_account_id = line.employee_account_id,
        employee_cid = line.employee_cid,
        destination_bank_account_id = line.destination_bank_account_id,
        destination_iban = line.destination_iban,
        destination_balance = tonumber(line.destination_balance) or 0,
        net_amount = amount,
        state = state,
      }
    end
  end

  if total <= 0 or #batch_lines == 0 then
    Idempotency.Orphan(ctx.idempotency_key)
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'no payable payroll lines' }) }
  end
  if tonumber(exec.treasury_balance) < total then
    Idempotency.Orphan(ctx.idempotency_key)
    return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS', { company_id = ctx.company_id }) }
  end

  local threshold = tonumber(exec.signing_threshold) or 1
  local requires_approval = threshold > 1
  local batch_id = UUID.V4()
  local approval_id = requires_approval and UUID.V4() or nil
  local decision = { signer_account_id = exec.actor_account_id, decision = 'approved', decided_at = os.time(), note = 'payroll request' }
  local approval = requires_approval and {
    approval_id = approval_id,
    signers_required = threshold,
    approvals_json = encode_json({ decision }),
    operation_description = 'Payroll execution',
    operation_payload = encode_json({ kind = 'payroll', batch_id = batch_id, company_id = ctx.company_id }),
  } or nil

  local ok, tx_err = Repo.CreatePayrollBatchWithLines({
    batch_id = batch_id,
    company_id = ctx.company_id,
    treasury_id = exec.treasury_id,
    state = requires_approval and 'pending_approval' or 'queued',
    total_net_amount = total,
    line_count = #batch_lines,
    held_line_count = held,
    requested_by_account_id = exec.actor_account_id,
    scheduled_for = os.time() + 86400,
    idempotency_key = ctx.idempotency_key,
  }, batch_lines, approval)
  if not ok then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = tx_err } end

  local status = requires_approval and 'pending_approval' or 'queued'
  local paid_total_minor = 0
  if not requires_approval then
    local executable_lines, total_ready, treasury_after = prepare_execution_lines(batch_lines, exec.treasury_balance)
    if total_ready <= 0 or tonumber(exec.treasury_balance) < total_ready then
      Idempotency.Orphan(ctx.idempotency_key)
      return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS', { company_id = ctx.company_id }) }
    end
    local exec_ok, exec_tx_err = Repo.MarkPayrollBatchExecutedTx({
      batch_id = batch_id,
      actor_account_id = exec.actor_account_id,
      treasury_account_id = exec.treasury_account_id,
      treasury_iban = exec.treasury_iban,
      treasury_balance_after = treasury_after,
      total_ready_amount = total_ready,
      reason = 'Business payroll',
      idempotency_key = ctx.idempotency_key,
    }, executable_lines)
    if not exec_ok then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = exec_tx_err } end
    status = 'executed'
    paid_total_minor = math.floor(total_ready * 100)
  end

  local audit_id = Audit.Write({
    event_type = status == 'executed' and Enums.AUDIT_EVENT_TYPE.BUSINESS_PAYROLL_EXECUTED or Enums.AUDIT_EVENT_TYPE.BUSINESS_PAYROLL_REQUEST,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_account_id = exec.actor_account_id,
    actor_src = ctx.src,
    actor_role = 'business',
    target_account_id = exec.treasury_account_id,
    target_iban = exec.treasury_iban,
    event_data = { company_id = ctx.company_id, batch_id = batch_id, approval_id = approval_id, total_net_minor = math.floor(total * 100), paid_total_minor = paid_total_minor, requires_approval = requires_approval, status = status },
    correlation_id = ctx.correlation_id or ctx.idempotency_key,
    request_nonce = ctx.idempotency_key,
  })

  local result = {
    company_id = ctx.company_id,
    batch_id = batch_id,
    approval_id = approval_id,
    status = status,
    total_net_minor = math.floor(total * 100),
    employee_count = #batch_lines,
    requires_approvals = requires_approval and threshold or 0,
    cross_ref_audit_id = audit_id,
    committed_at_ms = now_ms(),
  }
  Idempotency.Commit(ctx.idempotency_key, result)
  return { ok = true, data = result }
end

function S.RequestWithdrawal(ctx)
  if not is_valid_company_id(ctx.company_id) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'company_id' }) }
  end
  if not Validators.IsValidAmountMinor(ctx.amount_minor) then
    return { ok = false, error = Errors.New('INVALID_AMOUNT', { field = 'amount_minor' }) }
  end
  if not Validators.IsValidUUID(ctx.idempotency_key) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'idempotency_key', reason = 'must be UUID v4' }) }
  end

  local exec, exec_err = Repo.GetPayrollExecutionContext(ctx.company_id, ctx.actor_citizen_id)
  if exec_err then return { ok = false, error = exec_err } end
  if not exec then return { ok = false, error = Errors.New('RESOURCE_NOT_FOUND', { field = 'company_id' }) } end
  if (tonumber(exec.treasury_balance) or 0) * 100 < ctx.amount_minor then
    return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS', { company_id = ctx.company_id }) }
  end

  local note = Validators.SanitizeReason(ctx.note) or 'Business withdrawal request'
  local acquired, replay = acquire_idempotency(ctx, 'REQ-FE-015W', { company_id = ctx.company_id, operation = 'withdrawal_request', amount_minor = ctx.amount_minor, note = note }, exec.actor_account_id, exec.treasury_account_id)
  if not acquired then return replay end

  local approval_id = UUID.V4()
  local threshold = math.max(1, tonumber(exec.signing_threshold) or 1)
  local ok, tx_err = Repo.CreateWithdrawalApproval({
    approval_id = approval_id,
    treasury_id = exec.treasury_id,
    actor_account_id = exec.actor_account_id,
    amount_minor = ctx.amount_minor,
    signers_required = threshold,
    approvals_json = encode_json({}),
    description = note,
    operation_payload = encode_json({ kind = 'withdrawal', company_id = ctx.company_id, amount_minor = ctx.amount_minor, note = note, request_id = ctx.idempotency_key }),
  })
  if not ok then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = tx_err } end

  local audit_id = Audit.Write({
    event_type = Enums.AUDIT_EVENT_TYPE.BUSINESS_WITHDRAWAL_REQUEST,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_account_id = exec.actor_account_id,
    actor_src = ctx.src,
    actor_role = 'business',
    target_account_id = exec.treasury_account_id,
    target_iban = exec.treasury_iban,
    event_data = { company_id = ctx.company_id, approval_id = approval_id, amount_minor = ctx.amount_minor, note = note },
    correlation_id = ctx.correlation_id or ctx.idempotency_key,
    request_nonce = ctx.idempotency_key,
  })

  local result = {
    company_id = ctx.company_id,
    approval_id = approval_id,
    status = 'pending',
    amount_minor = ctx.amount_minor,
    requires_approvals = threshold,
    cross_ref_audit_id = audit_id,
    committed_at_ms = now_ms(),
  }
  Idempotency.Commit(ctx.idempotency_key, result)
  return { ok = true, data = result }
end

function S.DecideApproval(ctx)
  if type(ctx.approval_id) ~= 'string' or ctx.approval_id == '' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'approval_id' }) }
  end
  if ctx.decision ~= 'approve' and ctx.decision ~= 'reject' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'decision' }) }
  end
  if not Validators.IsValidUUID(ctx.idempotency_key) then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'idempotency_key', reason = 'must be UUID v4' }) }
  end

  local approval, approval_err = Repo.GetApprovalForDecision(ctx.approval_id, ctx.actor_citizen_id)
  if approval_err then return { ok = false, error = approval_err } end
  if not approval or approval.state ~= 'pending' then return { ok = false, error = Errors.New('RESOURCE_NOT_FOUND', { field = 'approval_id' }) } end

  local batch, batch_err = Repo.GetPayrollBatchForApproval(ctx.approval_id)
  if batch_err then return { ok = false, error = batch_err } end
  if not batch or batch.state ~= 'pending_approval' then return { ok = false, error = Errors.New('RESOURCE_NOT_FOUND', { field = 'batch_id' }) } end

  local acquired, replay = acquire_idempotency(ctx, 'REQ-FE-015A', { approval_id = ctx.approval_id, decision = ctx.decision }, approval.actor_account_id, approval.treasury_account_id)
  if not acquired then return replay end

  local decisions = decode_json_array(approval.approvals_json)
  if has_decision(decisions, approval.actor_account_id) then
    local approved_count = count_approved(decisions)
    local result = {
      company_id = approval.company_id,
      approval_id = ctx.approval_id,
      batch_id = batch.batch_id,
      status = batch.state,
      signers_approved = approved_count,
      signers_required = tonumber(approval.signers_required) or 1,
      paid_total_minor = batch.state == 'executed' and math.floor((tonumber(batch.total_net_amount) or 0) * 100) or 0,
      committed_at_ms = now_ms(),
    }
    Idempotency.Commit(ctx.idempotency_key, result)
    return { ok = true, data = result, replayed = true }
  end

  decisions[#decisions + 1] = { signer_account_id = approval.actor_account_id, decision = ctx.decision == 'approve' and 'approved' or 'rejected', decided_at = os.time(), note = ctx.note or '' }

  local approved_count = count_approved(decisions)

  local finalized = ctx.decision == 'reject' or approved_count >= (tonumber(approval.signers_required) or 1)
  local approval_state = ctx.decision == 'reject' and 'rejected' or (finalized and 'executed' or 'pending')
  local batch_state = ctx.decision == 'reject' and 'cancelled' or (finalized and 'executed' or 'pending_approval')
  local executable_lines = {}
  local total_ready = 0

  if batch_state == 'executed' then
    local lines, lines_err = Repo.GetPayrollBatchLines(batch.batch_id)
    if lines_err then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = lines_err } end
    executable_lines, total_ready = prepare_execution_lines(lines, approval.treasury_balance)
    if total_ready <= 0 or tonumber(approval.treasury_balance) < total_ready then
      Idempotency.Orphan(ctx.idempotency_key)
      return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS', { approval_id = ctx.approval_id }) }
    end
  end

  local ok, tx_err = Repo.DecidePayrollApprovalTx({
    approval_id = ctx.approval_id,
    approval_state = approval_state,
    signers_approved = approved_count,
    approvals_json = encode_json(decisions),
    finalized = finalized,
    batch_id = batch.batch_id,
    batch_state = batch_state,
    actor_account_id = approval.actor_account_id,
    treasury_account_id = approval.treasury_account_id,
    treasury_iban = approval.treasury_iban,
    treasury_balance_after = (tonumber(approval.treasury_balance) or 0) - total_ready,
    total_ready_amount = total_ready,
    reason = 'Business payroll',
    idempotency_key = ctx.idempotency_key,
  }, executable_lines)
  if not ok then Idempotency.Orphan(ctx.idempotency_key); return { ok = false, error = tx_err } end

  local vote_audit_id = Audit.Write({
    event_type = Enums.AUDIT_EVENT_TYPE.BUSINESS_APPROVAL_VOTED,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_account_id = approval.actor_account_id,
    actor_src = ctx.src,
    actor_role = 'business',
    target_account_id = approval.treasury_account_id,
    target_iban = approval.treasury_iban,
    event_data = { company_id = approval.company_id, approval_id = ctx.approval_id, batch_id = batch.batch_id, decision = ctx.decision, signers_approved = approved_count, status = batch_state, total_net_minor = math.floor(total_ready * 100) },
    correlation_id = ctx.correlation_id or ctx.idempotency_key,
    request_nonce = ctx.idempotency_key,
  })
  local execution_audit_id = nil
  if batch_state == 'executed' then
    execution_audit_id = Audit.Write({
      event_type = Enums.AUDIT_EVENT_TYPE.BUSINESS_PAYROLL_EXECUTED,
      actor_citizen_id = ctx.actor_citizen_id,
      actor_account_id = approval.actor_account_id,
      actor_src = ctx.src,
      actor_role = 'business',
      target_account_id = approval.treasury_account_id,
      target_iban = approval.treasury_iban,
      event_data = { company_id = approval.company_id, approval_id = ctx.approval_id, batch_id = batch.batch_id, total_net_minor = math.floor(total_ready * 100), status = batch_state },
      cross_ref_audit_id = vote_audit_id,
      correlation_id = ctx.correlation_id or ctx.idempotency_key,
      request_nonce = ctx.idempotency_key,
    })
  end

  local result = {
    company_id = approval.company_id,
    approval_id = ctx.approval_id,
    batch_id = batch.batch_id,
    status = batch_state,
    signers_approved = approved_count,
    signers_required = tonumber(approval.signers_required) or 1,
    paid_total_minor = math.floor(total_ready * 100),
    cross_ref_audit_id = execution_audit_id or vote_audit_id,
    committed_at_ms = now_ms(),
  }
  Idempotency.Commit(ctx.idempotency_key, result)
  return { ok = true, data = result }
end

return S
