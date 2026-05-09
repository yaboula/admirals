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

local function now_ms() return os.time() * 1000 end

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
  return LoansRepo.ListByCitizen(citizen_id, 16)
end

-- §2. Request
function S.Request(ctx)
  local timer = Perf.StartTimer()
  if not Validators.IsValidCitizenId(ctx.citizen_id) then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  if not Validators.IsValidAmountMinor(ctx.principal_minor) then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_AMOUNT') }
  end
  if not Validators.IsInRange(ctx.interest_bps, 0, 50000) then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'interest_bps' }) }
  end
  if not Validators.IsInRange(ctx.term_days, 1, 3650) then
    Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'term_days' }) }
  end

  local loan_id, err = LoansRepo.Insert({
    borrower_citizen_id = ctx.citizen_id,
    principal_minor     = ctx.principal_minor,
    interest_bps        = ctx.interest_bps,
    term_days           = ctx.term_days,
  })
  if err then
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
      principal_minor  = ctx.principal_minor,
      interest_bps     = ctx.interest_bps,
      term_days        = ctx.term_days,
    },
  })

  invalidate_bootstrap(ctx.citizen_id)
  Perf.EndTimer(timer, 'C022', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = { loan_id = loan_id, status = 'requested' } }
end

-- §3. Approve (admin) — credits balance to deposit_iban (chosen by admin/borrower)
function S.Approve(ctx)
  local loan, err = LoansRepo.GetById(ctx.loan_id)
  if err then return { ok = false, error = err } end
  if not loan then return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'loan not found' }) } end
  if loan.status ~= 'requested' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'loan not in requested state', got = loan.status }) }
  end

  local norm_iban = Validators.NormalizeIBAN(ctx.deposit_iban)
  if not norm_iban then return { ok = false, error = Errors.New('INVALID_IBAN') } end

  local deposit_account, deposit_err = AccountsRepo.GetByIban(norm_iban)
  if deposit_err then return { ok = false, error = deposit_err } end
  if not deposit_account or deposit_account.owner_citizen_id ~= loan.borrower_citizen_id then
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH', { reason = 'deposit iban not owned by borrower' }) }
  end

  local issued_ms = now_ms()
  local due_ms    = issued_ms + (tonumber(loan.term_days) or 0) * 86400 * 1000

  local tx_queries = {
    AccountsRepo.BuildCreditBalanceQuery(norm_iban, tonumber(loan.principal_minor) or 0),
    LoansRepo.BuildActivateQuery(ctx.loan_id, norm_iban, issued_ms, due_ms),
    LoansRepo.BuildInsertDisbursementQuery(ctx.loan_id, norm_iban, tonumber(loan.principal_minor) or 0, issued_ms),
  }
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
