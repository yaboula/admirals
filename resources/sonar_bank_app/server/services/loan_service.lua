-- =============================================================================
-- SONAR Bank App — services/loan_service.lua
-- =============================================================================
-- Loans FSM (#3) orchestrator: requested → approved/rejected → active → paid_off.
--
-- Operations:
--   ListSelf(citizen_id)
--   Request(ctx)             — creates loan_id (status='requested')
--   Approve(ctx)              — admin Tier 3 (status→active, credits balance)
--   Reject(ctx)               — admin Tier 3 (status→rejected)
--   MakePayment(ctx)         — borrower pays installment (debits balance, reduces outstanding)
-- =============================================================================

BankApp.services.loan = {}
local S = BankApp.services.loan

local Validators = BankApp.lib.validators
local Errors     = BankApp.lib.errors
local DB         = BankApp.lib.db
local UUID       = BankApp.lib.uuid
local Audit      = BankApp.lib.audit
local Publish    = BankApp.lib.publish
local Auth       = BankApp.lib.auth
local Enums      = BankApp.lib.enums
local Idempotency= BankApp.lib.idempotency
local Perf       = BankApp.lib.perf

local LoansRepo    = BankApp.repos.loans
local AccountsRepo = BankApp.repos.accounts
local Config       = BankApp.Config

local function now_ms() return os.time() * 1000 end

-- ---------------------------------------------------------------------------
-- Risk Engine — computes grade from existing loans + payment history
-- ---------------------------------------------------------------------------
local function compute_risk_grade(citizen_id)
  local existing, _ = LoansRepo.ListByCitizen(citizen_id, 100)
  local active_count = 0
  local has_defaulted = false
  for _, row in ipairs(existing or {}) do
    local s = row.state or row.status or ''
    if s == 'active' then active_count = active_count + 1 end
    if s == 'defaulted' then has_defaulted = true end
  end
  if has_defaulted then return 'D' end
  if active_count >= 3 then return 'C' end
  if active_count == 0 then return 'A' end
  return 'B'
end

local function resolve_product(product_id)
  for _, p in ipairs(Config.LoanProducts or {}) do
    if p.id == product_id then return p end
  end
  return nil
end

local function compute_interest_rate(product_id, grade)
  local product = resolve_product(product_id)
  if not product then return nil, nil end
  local mod_key = 'grade_' .. string.lower(grade or 'b')
  local modifier = (Config.LoanRiskModifiers or {})[mod_key] or 0
  local raw = product.base_rate_bps + modifier
  local rate = math.max(
    (Config.LoanLimits or {}).MIN_RATE_BPS or 100,
    math.min((Config.LoanLimits or {}).MAX_RATE_BPS or 1500, raw)
  )
  return rate, product
end

local function normalize_status(status)
  if status == 'requested' or status == 'approved' then return 'pending' end
  if status == 'paid_off' then return 'paid' end
  return status
end

local function decorate_loan(row)
  if not row then return nil end
  local term_days = tonumber(row.term_days) or 30
  local total_installments = math.max(1, math.ceil(term_days / 30))
  local outstanding_minor = tonumber(row.outstanding_minor) or 0
  local principal_minor = tonumber(row.principal_minor) or 0
  local product = resolve_product(row.product_id)
  row.product_name = product and product.name or 'Personal Credit Line'
  row.purpose = row.purpose or 'Personal financing'
  row.status = normalize_status(row.status)
  row.next_payment_minor = row.next_payment_minor or (outstanding_minor > 0 and math.max(1, math.ceil(outstanding_minor / total_installments)) or 0)
  row.next_payment_due_ms = row.due_ms
  row.total_installments = total_installments
  row.paid_installments = row.paid_installments or math.max(0, math.min(total_installments, total_installments - math.ceil(outstanding_minor / math.max(1, math.ceil(principal_minor / total_installments)))))
  row.risk_grade = row.risk_grade or compute_risk_grade(row.borrower_citizen_id)
  row.collateral_label = row.collateral_label or (product and product.collateral_required and 'Collateral required' or nil)
  return row
end

local function invalidate_bootstrap(citizen_id)
  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(citizen_id)
  end
end

-- §1. List
function S.ListSelf(citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then
    return nil, Errors.New('INVALID_CITIZEN_ID')
  end
  local rows, err = LoansRepo.ListByCitizen(citizen_id, 16)
  if err then return nil, err end
  for _, row in ipairs(rows or {}) do decorate_loan(row) end
  return rows
end

function S.ListSelfResponse(citizen_id)
  local rows, err = S.ListSelf(citizen_id)
  if err then return { ok = false, error = err } end
  return { ok = true, data = { items = rows or {}, fetched_at_ms = now_ms() } }
end

function S.GetInstallments(ctx)
  local loan = LoansRepo.GetById(ctx.loan_id)
  if not loan or loan.borrower_citizen_id ~= ctx.citizen_id then
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH', { reason = 'loan not owned' }) }
  end
  decorate_loan(loan)
  local payments, err = LoansRepo.ListPayments(ctx.loan_id, 100)
  if err then return { ok = false, error = err } end
  local paid_minor = 0
  for _, payment in ipairs(payments or {}) do
    paid_minor = paid_minor + (tonumber(payment.amount_minor) or 0)
  end
  local total = math.max(1, tonumber(loan.total_installments) or 1)
  local principal_minor = tonumber(loan.principal_minor) or 0
  local interest_minor_total = math.max(0, math.floor(principal_minor * ((tonumber(loan.interest_bps) or 0) / 10000)))
  local amount_minor = math.max(1, math.ceil((principal_minor + interest_minor_total) / total))
  local principal_part = math.max(0, math.ceil(principal_minor / total))
  local interest_part = math.max(0, amount_minor - principal_part)
  local issued_ms = tonumber(loan.issued_ms) or tonumber(loan.created_ms) or now_ms()
  local current_ms = now_ms()
  local remaining_paid = paid_minor
  local items = {}
  for sequence = 1, total do
    local covered = remaining_paid >= amount_minor
    local due_ms = issued_ms + sequence * 30 * 86400 * 1000
    items[#items + 1] = {
      installment_id = tostring(ctx.loan_id) .. '-inst-' .. tostring(sequence),
      loan_id = ctx.loan_id,
      sequence = sequence,
      due_ms = due_ms,
      amount_minor = amount_minor,
      principal_minor = principal_part,
      interest_minor = interest_part,
      status = covered and 'paid' or (due_ms < current_ms and 'late' or 'scheduled'),
      paid_ms = covered and due_ms or nil,
    }
    remaining_paid = math.max(0, remaining_paid - amount_minor)
  end
  return { ok = true, data = { loan_id = ctx.loan_id, items = items, fetched_at_ms = current_ms } }
end

-- §2. Request — product-driven, server-computed rate
function S.Request(ctx)
  local timer = Perf.StartTimer()
  -- Feature gate: loans module toggleable at server level.
  local Features = BankApp.lib.features
  if Features and Features.Require then
    local feat_err = Features.Require('loans')
    if feat_err then
      Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
      return { ok = false, error = feat_err }
    end
  end
  if not Validators.IsValidCitizenId(ctx.citizen_id) then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  if not ctx.product_id or type(ctx.product_id) ~= 'string' or #ctx.product_id == 0 then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'product_id', reason = 'missing' }) }
  end

  local product = resolve_product(ctx.product_id)
  if not product then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'product_id', reason = 'unknown product' }) }
  end

  if not Validators.IsValidAmountMinor(ctx.principal_minor) then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_AMOUNT') }
  end
  if ctx.principal_minor < product.min_principal then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'principal_minor', reason = 'below product minimum', min = product.min_principal }) }
  end
  if ctx.principal_minor > product.max_principal then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'principal_minor', reason = 'above product maximum', max = product.max_principal }) }
  end
  if not Validators.IsInRange(ctx.term_days, 1, product.max_term_days) then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'term_days', reason = 'outside product range', max = product.max_term_days }) }
  end
  if not Validators.IsValidUUID(ctx.idempotency_key) then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'idempotency_key' }) }
  end

  local norm_deposit_iban = Validators.NormalizeIBAN(ctx.deposit_iban)
  if not norm_deposit_iban then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_IBAN', { field = 'deposit_iban' }) }
  end
  local deposit_account, deposit_err = AccountsRepo.GetByIban(norm_deposit_iban)
  if deposit_err then return { ok = false, error = deposit_err } end
  if not deposit_account or deposit_account.owner_citizen_id ~= ctx.citizen_id then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH', { reason = 'deposit iban not owned by borrower' }) }
  end
  if deposit_account.account_class ~= 'checking' and deposit_account.account_class ~= 'business_treasury' then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_ACCOUNT_CLASS', { reason = 'loan deposit account must be personal or professional', account_class = deposit_account.account_class }) }
  end

  -- Compute rate server-side (player never chooses their own rate)
  local grade = compute_risk_grade(ctx.citizen_id)
  local rate_bps, _ = compute_interest_rate(ctx.product_id, grade)
  if not rate_bps then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INTERNAL_ERROR', { reason = 'rate computation failed' }) }
  end

  local idem_status, cached, idem_err = Idempotency.Acquire(
    ctx.idempotency_key,
    { principal_minor = ctx.principal_minor, product_id = ctx.product_id, term_days = ctx.term_days, deposit_iban = norm_deposit_iban },
    { actor_citizen_id = ctx.citizen_id, callback_id = 'C022' }
  )
  if idem_status == 'replay' then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = true, data = cached, replayed = true }
  elseif idem_status ~= 'acquired' then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') }
  end

  local loan_id, err = LoansRepo.Insert({
    borrower_citizen_id = ctx.citizen_id,
    product_id          = ctx.product_id,
    principal_minor     = ctx.principal_minor,
    interest_bps        = rate_bps,
    term_days           = ctx.term_days,
    deposit_iban        = norm_deposit_iban,
  })
  if err then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = err }
  end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.LOAN_REQUEST,
    actor_citizen_id = ctx.citizen_id,
    actor_src        = ctx.src,
    target_citizen_id= ctx.citizen_id,
    event_data       = {
      loan_id          = loan_id,
      product_id       = ctx.product_id,
      principal_minor  = ctx.principal_minor,
      interest_bps     = rate_bps,
      term_days        = ctx.term_days,
      risk_grade       = grade,
      deposit_iban      = norm_deposit_iban,
    },
  })

  invalidate_bootstrap(ctx.citizen_id)
  local result = { loan_id = loan_id, status = 'requested', rate_bps = rate_bps, grade = grade, deposit_iban = norm_deposit_iban }
  Idempotency.Commit(ctx.idempotency_key, result)
  Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = result }
end

-- §3. Approve (admin) — credits balance to deposit_iban (chosen by admin/borrower)
function S.Approve(ctx)
  local loan, err = LoansRepo.GetById(ctx.loan_id)
  if err then return { ok = false, error = err } end
  if not loan then return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'loan not found' }) } end
  if loan.status ~= 'requested' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'loan not in requested state', got = loan.status }) }
  end

  local norm_iban = Validators.NormalizeIBAN(ctx.deposit_iban or loan.deposit_iban)
  if not norm_iban then return { ok = false, error = Errors.New('INVALID_IBAN') } end

  local deposit_account, deposit_err = AccountsRepo.GetByIban(norm_iban)
  if deposit_err then return { ok = false, error = deposit_err } end
  if not deposit_account or deposit_account.owner_citizen_id ~= loan.borrower_citizen_id then
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH', { reason = 'deposit iban not owned by borrower' }) }
  end
  if deposit_account.account_class ~= 'checking' and deposit_account.account_class ~= 'business_treasury' then
    return { ok = false, error = Errors.New('INVALID_ACCOUNT_CLASS', { reason = 'loan deposit account must be personal or professional', account_class = deposit_account.account_class }) }
  end

  local issued_ms = now_ms()
  local due_ms    = issued_ms + (tonumber(loan.term_days) or 0) * 86400 * 1000

  local tx_queries = {}

  tx_queries[#tx_queries + 1] = AccountsRepo.BuildCreditBalanceQuery(norm_iban, tonumber(loan.principal_minor) or 0)
  tx_queries[#tx_queries + 1] = LoansRepo.BuildActivateQuery(ctx.loan_id, norm_iban, issued_ms, due_ms)
  tx_queries[#tx_queries + 1] = LoansRepo.BuildInsertDisbursementQuery(ctx.loan_id, norm_iban, tonumber(loan.principal_minor) or 0, issued_ms)

  local ok, tx_err = DB.Transaction(tx_queries)
  if not ok then return { ok = false, error = tx_err } end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.LOAN_APPROVE,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src        = ctx.src,
    target_citizen_id= loan.borrower_citizen_id,
    target_iban      = norm_iban,
    event_data       = {
      loan_id   = ctx.loan_id,
      principal = tonumber(loan.principal_minor),
      issued_ms = issued_ms,
      due_ms    = due_ms,
    },
  })

  -- Publish updated balance (M004)
  local fresh = AccountsRepo.GetBalance(norm_iban)
  if fresh then
    local recv_src = Auth.ResolveCitizenSrc(loan.borrower_citizen_id)
    if recv_src then
      Publish.PublishBalanceUpdate(
        recv_src, loan.borrower_citizen_id,
        tonumber(fresh.balance_minor) or 0,
        tonumber(fresh.savings_minor) or 0,
        { reason = 'loan_disbursed' }
      )
    end
  end

  invalidate_bootstrap(loan.borrower_citizen_id)
  return { ok = true, data = { loan_id = ctx.loan_id, status = 'active' } }
end

-- §4. Reject (admin)
function S.Reject(ctx)
  local _, err = LoansRepo.SetStatus(ctx.loan_id, 'rejected', nil, nil)
  if err then return { ok = false, error = err } end

  local loan = LoansRepo.GetById(ctx.loan_id)
  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.LOAN_REJECT,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src        = ctx.src,
    target_citizen_id= loan and loan.borrower_citizen_id,
    event_data       = { loan_id = ctx.loan_id, reason = Validators.SanitizeReason(ctx.reason) },
  })
  return { ok = true, data = { loan_id = ctx.loan_id, status = 'rejected' } }
end

-- §5. MakePayment — borrower repays from chosen IBAN.
function S.MakePayment(ctx)
  local timer = Perf.StartTimer()
  if not Validators.IsValidAmountMinor(ctx.amount_minor) then
    Perf.EndTimer(timer, 'C024', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_AMOUNT') }
  end
  local norm_iban = Validators.NormalizeIBAN(ctx.from_iban)
  if not norm_iban then
    Perf.EndTimer(timer, 'C024', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_IBAN') }
  end

  local owner_cid, account, own_err = Auth.RequireOwnership(ctx.src, norm_iban)
  if own_err then
    Perf.EndTimer(timer, 'C024', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = own_err }
  end

  local loan = LoansRepo.GetById(ctx.loan_id)
  if not loan or loan.borrower_citizen_id ~= owner_cid then
    Perf.EndTimer(timer, 'C024', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH', { reason = 'loan not owned' }) }
  end
  if loan.status ~= 'active' then
    Perf.EndTimer(timer, 'C024', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'loan not active' }) }
  end
  if (tonumber(account.balance_minor) or 0) < ctx.amount_minor then
    Perf.EndTimer(timer, 'C024', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS') }
  end

  local idem_status, cached, idem_err = Idempotency.Acquire(
    ctx.idempotency_key,
    { loan_id = ctx.loan_id, from_iban = norm_iban, amount_minor = ctx.amount_minor },
    { actor_citizen_id = owner_cid, callback_id = 'C024' }
  )
  if idem_status == 'replay' then
    Perf.EndTimer(timer, 'C024', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = true, data = cached, replayed = true }
  elseif idem_status ~= 'acquired' then
    Perf.EndTimer(timer, 'C024', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') }
  end

  local payment_ms = now_ms()
  local tx_queries = {
    AccountsRepo.BuildDebitBalanceQuery(norm_iban, ctx.amount_minor),
    LoansRepo.BuildReduceOutstandingQuery(ctx.loan_id, ctx.amount_minor),
    LoansRepo.BuildInsertPaymentQuery(ctx.loan_id, norm_iban, ctx.amount_minor, payment_ms),
  }
  local ok, tx_err = DB.Transaction(tx_queries)
  if not ok then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C024', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = tx_err }
  end

  -- Determine if loan was paid off
  local fresh_loan = LoansRepo.GetById(ctx.loan_id)
  local event_type = (fresh_loan and tonumber(fresh_loan.outstanding_minor) == 0)
                       and Enums.AUDIT_EVENT_TYPE.LOAN_PAYOFF
                       or Enums.AUDIT_EVENT_TYPE.LOAN_PAYMENT

  Audit.Write({
    event_type       = event_type,
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_citizen_id= owner_cid,
    target_iban      = norm_iban,
    event_data       = {
      loan_id          = ctx.loan_id,
      amount_minor     = ctx.amount_minor,
      payment_ms       = payment_ms,
      outstanding_after= fresh_loan and tonumber(fresh_loan.outstanding_minor),
    },
  })

  -- Publish balance
  local fresh = AccountsRepo.GetBalance(norm_iban)
  if fresh then
    Publish.PublishBalanceUpdate(
      ctx.src, owner_cid,
      tonumber(fresh.balance_minor) or 0,
      tonumber(fresh.savings_minor) or 0,
      { reason = 'loan_payment' }
    )
  end

  local result = {
    loan_id      = ctx.loan_id,
    amount_minor = ctx.amount_minor,
    payment_ms   = payment_ms,
    paid_off     = event_type == Enums.AUDIT_EVENT_TYPE.LOAN_PAYOFF,
  }
  Idempotency.Commit(ctx.idempotency_key, result)
  invalidate_bootstrap(owner_cid)
  Perf.EndTimer(timer, 'C024', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = result }
end

return S
