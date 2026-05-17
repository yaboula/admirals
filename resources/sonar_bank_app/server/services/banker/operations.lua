-- =============================================================================
-- SONAR Bank App — services/banker/operations.lua
-- =============================================================================
-- Approvals queues for the Bank Owner Panel (F2):
--   - Pending Loans                 (calls LoanService.Approve / Reject)
--   - Pending Professional Accounts (calls AccountService.DecideProfessionalApproval)
--   - Pending KYC                   (calls AccountService.ApproveKyc / RejectKyc)
--
-- Auth: BankerAuth.RequireBanker with a per-action capability gate. The
-- underlying core services already audit, so we don't double-emit. We DO
-- emit a banker-side "operations action" trace (audit event_data.via='banker')
-- so the audit log distinguishes admin-cooperation from banker decisions.
-- =============================================================================

BankApp.services.banker = BankApp.services.banker or {}
BankApp.services.banker.operations = {}
local S = BankApp.services.banker.operations

local Errors      = BankApp.lib.errors
local BankerAuth  = BankApp.lib.banker_auth
local BankerAggr  = BankApp.repos.banker_aggregate

local AccountService = BankApp.services.account
local LoanService    = BankApp.services.loan

local AccountsRepo   = BankApp.repos.accounts

local function now_ms() return os.time() * 1000 end

-- ---------------------------------------------------------------------------
-- §1. Combined queues snapshot — single round-trip for the Operations tab
-- ---------------------------------------------------------------------------
function S.ListQueues(ctx)
  local _, _, auth_err = BankerAuth.RequireBanker(ctx.src, 'panel_open')
  if auth_err then return { ok = false, error = auth_err } end

  local limit = math.max(1, math.min(100, tonumber(ctx.limit) or 25))

  local loans, loans_err = BankerAggr.ListPendingLoans(limit)
  local pro_accounts, pa_err = AccountsRepo.ListProfessionalApprovals(limit)
  local kyc, kyc_err = BankerAggr.ListPendingKyc(limit)

  return {
    ok = true,
    data = {
      loans_pending        = loans or {},
      pro_accounts_pending = pro_accounts or {},
      kyc_pending          = kyc or {},
      partial_errors = {
        loans        = loans_err and (loans_err.message or loans_err.code) or nil,
        pro_accounts = pa_err and (pa_err.message or pa_err.code) or nil,
        kyc          = kyc_err and (kyc_err.message or kyc_err.code) or nil,
      },
      fetched_at_ms = now_ms(),
    },
  }
end

-- ---------------------------------------------------------------------------
-- §2. Loan decision (approve / reject)
-- ---------------------------------------------------------------------------
function S.DecideLoan(ctx)
  local actor_id, _, auth_err = BankerAuth.RequireBanker(ctx.src, 'loans_approve')
  if auth_err then return { ok = false, error = auth_err } end
  if type(ctx.loan_id) ~= 'string' or ctx.loan_id == '' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'loan_id' }) }
  end
  if ctx.decision ~= 'approve' and ctx.decision ~= 'reject' then
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'decision' }) }
  end

  if ctx.decision == 'approve' then
    return LoanService.Approve({
      src              = ctx.src,
      actor_citizen_id = actor_id,
      loan_id          = ctx.loan_id,
      deposit_iban     = ctx.deposit_iban,
    })
  end
  return LoanService.Reject({
    src              = ctx.src,
    actor_citizen_id = actor_id,
    loan_id          = ctx.loan_id,
    reason           = ctx.reason,
  })
end

-- ---------------------------------------------------------------------------
-- §3. Professional account decision
-- ---------------------------------------------------------------------------
function S.DecideProfessionalAccount(ctx)
  local actor_id, _, auth_err = BankerAuth.RequireBanker(ctx.src, 'pro_account_approve')
  if auth_err then return { ok = false, error = auth_err } end
  return AccountService.DecideProfessionalApproval({
    src              = ctx.src,
    actor_citizen_id = actor_id,
    approval_id      = ctx.approval_id,
    decision         = ctx.decision,
    note             = ctx.note,
  })
end

-- ---------------------------------------------------------------------------
-- §4. KYC decision
-- ---------------------------------------------------------------------------
function S.DecideKyc(ctx)
  local actor_id, _, auth_err = BankerAuth.RequireBanker(ctx.src, 'kyc_approve')
  if auth_err then return { ok = false, error = auth_err } end

  if ctx.decision == 'approve' then
    return AccountService.ApproveKyc({
      src               = ctx.src,
      actor_citizen_id  = actor_id,
      target_citizen_id = ctx.target_citizen_id,
      reason            = ctx.reason,
    })
  end
  if ctx.decision == 'reject' then
    return AccountService.RejectKyc({
      src               = ctx.src,
      actor_citizen_id  = actor_id,
      target_citizen_id = ctx.target_citizen_id,
      reason            = ctx.reason,
    })
  end
  return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'decision' }) }
end
