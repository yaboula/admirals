-- =============================================================================
-- SONAR Bank App — services/admin_service.lua
-- =============================================================================
-- Tier 3 admin/govt operations + ATM withdraw (M006 HMAC) + watchdog + fraud
-- review + reconciliation.
--
-- Operations:
--   QueryAuditLedger(ctx)      — C035 dual rate-limit recursive guard
--   FreezeByGovt(ctx)          — H006 mandatory previous_flag_snapshot
--   UnfreezeByGovt(ctx)
--   AdjustBalance(ctx)         — admin balance adjust ±delta
--   GovtAudit(ctx)             — admin requests on-demand snapshot of target citizen
--   AtmWithdraw(ctx)           — M006 HMAC-signed payload mandatory
--   OpenFraudReview(ctx)
--   ResolveFraudReview(ctx)
--   WatchdogReport()           — M007 metric C health snapshot
--   ReconcilePipeline(opts)    — admin-triggered reconciliation pass
-- =============================================================================

BankApp.services.admin = {}
local S = BankApp.services.admin

local Validators = BankApp.lib.validators
local Errors     = BankApp.lib.errors
local DB         = BankApp.lib.db
local Audit      = BankApp.lib.audit
local Auth       = BankApp.lib.auth
local Publish    = BankApp.lib.publish
local Enums      = BankApp.lib.enums
local HMAC       = BankApp.lib.hmac
local RateLimit  = BankApp.lib.rate_limit
local Perf       = BankApp.lib.perf
local Config     = BankApp.Config

local AccountsRepo   = BankApp.repos.accounts
local AuditQueryRepo = BankApp.repos.audit_query

local function now_ms() return os.time() * 1000 end

-- -----------------------------------------------------------------------------
-- §1. C035 — QueryAuditLedger (M003 dual rate-limit recursive guard)
-- -----------------------------------------------------------------------------

--- QueryAuditLedger.
---@param ctx { actor_citizen_id, scope='self'|'other'|'event_type', target_citizen_id, event_type, limit, offset, since_ms }
function S.QueryAuditLedger(ctx)
  local timer = Perf.StartTimer()

  if not Validators.IsValidCitizenId(ctx.actor_citizen_id) then
    Perf.EndTimer(timer, 'C035', { tier = Enums.TIER.TIER_3_ADMIN })
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end

  local scope = ctx.scope or 'self'
  local limit = Validators.IsInRange(ctx.limit, 1, 200) and ctx.limit or 50

  -- M003 dual rate-limit + bypass + recursive guard
  local rl_ok, rl_err = RateLimit.CheckAuditQuery(
    ctx.actor_citizen_id,
    ctx.target_citizen_id,
    scope,
    limit
  )
  if not rl_ok then
    Perf.EndTimer(timer, 'C035', { tier = Enums.TIER.TIER_3_ADMIN })
    return { ok = false, error = rl_err }
  end

  local rows, q_err
  -- Wrap actual repo call in recursion guard so any internal audit reads
  -- (e.g. sub-aggregations) skip rate-limit recursion.
  RateLimit.WithRecursionGuard(function()
    if scope == 'self' then
      rows, q_err = AuditQueryRepo.ListByCitizen(ctx.actor_citizen_id, limit, ctx.offset or 0)
    elseif scope == 'other' and Validators.IsValidCitizenId(ctx.target_citizen_id) then
      rows, q_err = AuditQueryRepo.ListByTarget(ctx.target_citizen_id, limit, ctx.offset or 0)
    elseif scope == 'event_type' and type(ctx.event_type) == 'string' then
      rows, q_err = AuditQueryRepo.ListByEventType(
        ctx.event_type,
        ctx.since_ms or (now_ms() - 7 * 86400 * 1000),
        limit, ctx.offset or 0
      )
    else
      q_err = Errors.New('VALIDATION_FAILED', { reason = 'invalid scope or missing target' })
    end
  end)

  Perf.EndTimer(timer, 'C035', { tier = Enums.TIER.TIER_3_ADMIN })
  if q_err then return { ok = false, error = q_err } end
  return { ok = true, data = { rows = rows or {}, scope = scope, limit = limit } }
end

-- -----------------------------------------------------------------------------
-- §2. Govt freeze / unfreeze (H006 — flag snapshot mandatory)
-- -----------------------------------------------------------------------------

local function govt_freeze_helper(ctx, freeze_bool, event_type)
  local timer = Perf.StartTimer()
  local norm_iban = Validators.NormalizeIBAN(ctx.iban)
  if not norm_iban then
    Perf.EndTimer(timer, 'C036', { tier = Enums.TIER.TIER_3_ADMIN })
    return { ok = false, error = Errors.New('INVALID_IBAN') }
  end

  local row = AccountsRepo.GetByIban(norm_iban)
  if not row then
    Perf.EndTimer(timer, 'C036', { tier = Enums.TIER.TIER_3_ADMIN })
    return { ok = false, error = Errors.New('ACCOUNT_NOT_FOUND', { iban = norm_iban }) }
  end

  local previous_snapshot = {
    iban         = norm_iban,
    frozen_flag  = DB.ToBool(row.frozen_flag),
    status       = row.status,
    snapshot_ms  = now_ms(),
    govt_action  = true,
  }

  local _, set_err = AccountsRepo.SetFrozenFlag(norm_iban, freeze_bool)
  if set_err then
    Perf.EndTimer(timer, 'C036', { tier = Enums.TIER.TIER_3_ADMIN })
    return { ok = false, error = set_err }
  end

  Audit.Write({
    event_type             = event_type,
    actor_citizen_id       = ctx.actor_citizen_id,
    actor_src              = ctx.src,
    target_citizen_id      = row.owner_citizen_id,
    target_iban            = norm_iban,
    target_account_id      = row.account_id,
    previous_flag_snapshot = previous_snapshot,
    event_data             = {
      reason          = Validators.SanitizeReason(ctx.reason),
      new_frozen_flag = freeze_bool,
      govt_authority  = ctx.authority,
    },
    correlation_id         = ctx.correlation_id,
  })

  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(row.owner_citizen_id)
  end

  Perf.EndTimer(timer, 'C036', { tier = Enums.TIER.TIER_3_ADMIN })
  return { ok = true, data = { iban = norm_iban, frozen = freeze_bool } }
end

function S.FreezeByGovt(ctx)
  return govt_freeze_helper(ctx, true, Enums.AUDIT_EVENT_TYPE.GOVT_FREEZE)
end

function S.UnfreezeByGovt(ctx)
  return govt_freeze_helper(ctx, false, Enums.AUDIT_EVENT_TYPE.GOVT_UNFREEZE)
end

-- -----------------------------------------------------------------------------
-- §3. AdjustBalance (admin)
-- -----------------------------------------------------------------------------

--- AdjustBalance — ±delta to balance (admin-only).
function S.AdjustBalance(ctx)
  local norm_iban = Validators.NormalizeIBAN(ctx.iban)
  if not norm_iban then return { ok = false, error = Errors.New('INVALID_IBAN') } end

  if type(ctx.delta_minor) ~= 'number' or ctx.delta_minor == 0 then
    return { ok = false, error = Errors.New('INVALID_AMOUNT', { reason = 'delta must be non-zero integer' }) }
  end

  local row = AccountsRepo.GetByIban(norm_iban)
  if not row then return { ok = false, error = Errors.New('ACCOUNT_NOT_FOUND', { iban = norm_iban }) } end

  local q
  if ctx.delta_minor > 0 then
    q = AccountsRepo.BuildCreditBalanceQuery(norm_iban, ctx.delta_minor)
  else
    q = AccountsRepo.BuildDebitBalanceQuery(norm_iban, math.abs(ctx.delta_minor))
  end
  local ok, tx_err = DB.Transaction({ q })
  if not ok then return { ok = false, error = tx_err } end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.BALANCE_ADJUST_ADMIN,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src        = ctx.src,
    target_citizen_id= row.owner_citizen_id,
    target_iban      = norm_iban,
    target_account_id= row.account_id,
    event_data       = {
      delta_minor = ctx.delta_minor,
      reason      = Validators.SanitizeReason(ctx.reason),
    },
    correlation_id   = ctx.correlation_id,
  })

  -- Publish balance to recipient if online
  local fresh = AccountsRepo.GetBalance(norm_iban)
  if fresh then
    local recv_src = Auth.ResolveCitizenSrc(row.owner_citizen_id)
    if recv_src then
      Publish.PublishBalanceUpdate(
        recv_src, row.owner_citizen_id,
        tonumber(fresh.balance_minor) or 0,
        tonumber(fresh.savings_minor) or 0,
        { reason = 'admin_adjust', correlation = ctx.correlation_id }
      )
    end
  end

  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(row.owner_citizen_id)
  end

  return { ok = true, data = {
    iban        = norm_iban,
    delta_minor = ctx.delta_minor,
    new_balance = fresh and tonumber(fresh.balance_minor),
  } }
end

-- -----------------------------------------------------------------------------
-- §4. GovtAudit — admin requests target citizen's balance snapshot
-- -----------------------------------------------------------------------------

function S.GovtAudit(ctx)
  if not Validators.IsValidCitizenId(ctx.target_citizen_id) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end

  -- Fetch all accounts of target
  local accounts, err = AccountsRepo.ListByCitizen(ctx.target_citizen_id, 32)
  if err then return { ok = false, error = err } end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.GOVT_AUDIT_REQUEST,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src        = ctx.src,
    target_citizen_id= ctx.target_citizen_id,
    event_data       = {
      reason         = Validators.SanitizeReason(ctx.reason),
      account_count  = #accounts,
      requested_ms   = now_ms(),
    },
    correlation_id   = ctx.correlation_id,
  })

  -- Emit admin-only NetEvent (M004 sonar:bank:balance:adminAudit)
  local total_balance, total_savings = 0, 0
  for _, a in ipairs(accounts) do
    total_balance = total_balance + (tonumber(a.balance_minor) or 0)
    total_savings = total_savings + (tonumber(a.savings_minor) or 0)
  end

  if ctx.src then
    Publish.EmitAdminAudit(ctx.src, ctx.target_citizen_id, total_balance, total_savings, {
      audit_id        = nil,
      requested_at_ms = now_ms(),
      reason          = ctx.reason,
    })
  end

  return { ok = true, data = {
    target_citizen_id = ctx.target_citizen_id,
    accounts          = accounts,
    total_balance     = total_balance,
    total_savings     = total_savings,
  } }
end

-- -----------------------------------------------------------------------------
-- §5. AtmWithdraw — M006 HMAC mandatory
--
--   Payload format: ATM hardware signs `iban|amount|nonce|ts` con shared secret.
--   Server verifies HMAC. If valid → debit balance + audit + publish.
-- -----------------------------------------------------------------------------

function S.AtmWithdraw(ctx)
  local timer = Perf.StartTimer()

  if not HMAC.IsLoaded() then
    Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('HMAC_CONFIG_MISSING') }
  end

  local norm_iban = Validators.NormalizeIBAN(ctx.iban)
  if not norm_iban then
    Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_IBAN') }
  end
  if not Validators.IsValidAmountMinor(ctx.amount_minor) then
    Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_AMOUNT') }
  end
  if type(ctx.nonce) ~= 'string' or #ctx.nonce < 8 or #ctx.nonce > 64 then
    Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'nonce' }) }
  end
  if type(ctx.ts_ms) ~= 'number' then
    Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { field = 'ts_ms' }) }
  end

  -- Replay window: 60s
  local age_ms = now_ms() - ctx.ts_ms
  if age_ms < -5000 or age_ms > 60000 then
    Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('HMAC_VERIFICATION_FAILED', {
      reason = 'timestamp out of replay window', age_ms = age_ms,
    }) }
  end

  local payload = ('%s|%d|%s|%d'):format(norm_iban, ctx.amount_minor, ctx.nonce, ctx.ts_ms)
  local sig_ok, sig_err = HMAC.VerifyPayload(payload, ctx.signature_hex or '')
  if not sig_ok then
    Audit.Write({
      event_type       = Enums.AUDIT_EVENT_TYPE.ATM_FAILED,
      actor_citizen_id = ctx.actor_citizen_id,
      actor_src        = ctx.src,
      target_iban      = norm_iban,
      event_data       = {
        amount_minor = ctx.amount_minor,
        reason       = 'hmac_verify_failed',
      },
    })
    Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = sig_err }
  end

  -- Ownership + funds check
  local row = AccountsRepo.GetByIban(norm_iban)
  if not row then
    Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ACCOUNT_NOT_FOUND', { iban = norm_iban }) }
  end
  if (tonumber(row.balance_minor) or 0) < ctx.amount_minor then
    Audit.Write({
      event_type       = Enums.AUDIT_EVENT_TYPE.ATM_FAILED,
      actor_citizen_id = row.owner_citizen_id,
      target_iban      = norm_iban,
      event_data       = { reason = 'insufficient_funds', amount_minor = ctx.amount_minor },
    })
    Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS') }
  end

  local q = AccountsRepo.BuildDebitBalanceQuery(norm_iban, ctx.amount_minor)
  local ok, tx_err = DB.Transaction({ q })
  if not ok then
    Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = tx_err }
  end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.ATM_WITHDRAW,
    actor_citizen_id = row.owner_citizen_id,
    actor_src        = ctx.src,
    target_iban      = norm_iban,
    event_data       = {
      amount_minor = ctx.amount_minor,
      nonce        = ctx.nonce,
      ts_ms        = ctx.ts_ms,
      atm_id       = ctx.atm_id,
    },
  })

  -- Publish balance
  local fresh = AccountsRepo.GetBalance(norm_iban)
  if fresh then
    local recv_src = Auth.ResolveCitizenSrc(row.owner_citizen_id)
    if recv_src then
      Publish.PublishBalanceUpdate(
        recv_src, row.owner_citizen_id,
        tonumber(fresh.balance_minor) or 0,
        tonumber(fresh.savings_minor) or 0,
        { reason = 'atm_withdraw' }
      )
    end
  end

  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(row.owner_citizen_id)
  end

  Perf.EndTimer(timer, 'C031', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = {
    iban         = norm_iban,
    amount_minor = ctx.amount_minor,
    new_balance  = fresh and tonumber(fresh.balance_minor),
  } }
end

-- -----------------------------------------------------------------------------
-- §6. Fraud review (open + resolve)
-- -----------------------------------------------------------------------------

function S.OpenFraudReview(ctx)
  if not Validators.IsValidCitizenId(ctx.target_citizen_id) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end
  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.FRAUD_REVIEW_OPEN,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src        = ctx.src,
    target_citizen_id= ctx.target_citizen_id,
    event_data       = {
      reason  = Validators.SanitizeReason(ctx.reason),
      txn_id  = ctx.txn_id,
      opened_ms = now_ms(),
    },
    correlation_id   = ctx.correlation_id,
  })
  return { ok = true, data = { target_citizen_id = ctx.target_citizen_id, opened_ms = now_ms() } }
end

function S.ResolveFraudReview(ctx)
  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.FRAUD_REVIEW_RESOLVE,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src        = ctx.src,
    target_citizen_id= ctx.target_citizen_id,
    cross_ref_audit_id = ctx.original_audit_id,
    event_data       = {
      resolution = ctx.resolution,
      reason     = Validators.SanitizeReason(ctx.reason),
      resolved_ms= now_ms(),
    },
    correlation_id   = ctx.correlation_id,
  })
  return { ok = true, data = { resolved_ms = now_ms(), resolution = ctx.resolution } }
end

-- -----------------------------------------------------------------------------
-- §7. WatchdogReport (M007 — metric C health snapshot)
-- -----------------------------------------------------------------------------

function S.WatchdogReport()
  local snapshot = Perf.CheckBootstrapHealth()
  local audit_stats = Audit.GetStats()
  local idem_cache  = BankApp.lib.idempotency and BankApp.lib.idempotency.GetCacheStats() or {}

  local threshold = tonumber(GetConvar(Config.Convars.WATCHDOG_COMPROMISE_RATIO_THRESHOLD.name, '0.1')) or 0.1
  local min_sample = GetConvarInt(Config.Convars.WATCHDOG_MIN_SAMPLE_SIZE.name, 10)

  return {
    ok = true,
    data = {
      bootstrap        = snapshot,
      audit            = audit_stats,
      idempotency_cache= idem_cache,
      thresholds       = { compromise_ratio = threshold, min_sample = min_sample },
      reported_ms      = now_ms(),
    },
  }
end

-- -----------------------------------------------------------------------------
-- §8. ReconcilePipeline (admin-triggered defensive pass)
--
--   This is a placeholder hook — full reconciliation lives in sonar_bank
--   (legacy) + Bridges layer. For sonar_bank_app we expose an entry point that
--   calls the Bridges reconciliation primitive if available.
-- -----------------------------------------------------------------------------

function S.ReconcilePipeline(opts)
  opts = opts or {}
  if _G.Bridges and _G.Bridges.Reconcile and type(_G.Bridges.Reconcile.Run) == 'function' then
    local ok, result = pcall(_G.Bridges.Reconcile.Run, opts)
    if ok then
      Audit.Write({
        event_type       = Enums.AUDIT_EVENT_TYPE.BALANCE_RECONCILE,
        actor_citizen_id = opts.actor_citizen_id,
        event_data       = {
          mode          = opts.mode or 'admin_triggered',
          ran_at_ms     = now_ms(),
          summary       = result and result.summary,
        },
      })
      return { ok = true, data = result or { summary = 'no result' } }
    end
    return { ok = false, error = Errors.New('INTERNAL_ERROR', { reason = 'reconcile call raised' }) }
  end
  return { ok = false, error = Errors.New('INTERNAL_ERROR', { reason = 'Bridges.Reconcile.Run not available' }) }
end

return S
