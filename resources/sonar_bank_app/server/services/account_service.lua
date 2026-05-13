-- =============================================================================
-- SONAR Bank App — services/account_service.lua
-- =============================================================================
-- Account lifecycle FSM (#1) orchestrator + KYC flow.
--
-- Operations:
--   GetSelfAccounts(citizen_id)        — list (read)
--   OpenAccount(ctx)                   — pending → active (Q-DB-A: IBAN gen via sonar_bank.IBAN.Generate)
--   FreezeAccount(ctx)                 — H006-compliant (snapshot + audit)
--   UnfreezeAccount(ctx)
--   CloseAccount(ctx)                  — only if balance == 0 AND savings == 0
--   AddJointOwner / RemoveJointOwner   — joint flow
--   SubmitKyc / ApproveKyc / RejectKyc — H006 flag-changing events
-- =============================================================================

BankApp.services.account = {}
local S = BankApp.services.account

local Validators = BankApp.lib.validators
local Errors     = BankApp.lib.errors
local DB         = BankApp.lib.db
local Audit      = BankApp.lib.audit
local Auth       = BankApp.lib.auth
local Enums      = BankApp.lib.enums
local Perf       = BankApp.lib.perf

local AccountsRepo = BankApp.repos.accounts

local function now_ms() return os.time() * 1000 end

local function invalidate_bootstrap(citizen_id)
  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(citizen_id)
  end
end

-- -----------------------------------------------------------------------------
-- §1. Read
-- -----------------------------------------------------------------------------

function S.GetSelfAccounts(citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then
    return nil, Errors.New('INVALID_CITIZEN_ID')
  end
  return AccountsRepo.ListByCitizen(citizen_id, 32)
end

-- -----------------------------------------------------------------------------
-- §2. OpenAccount (pending → active)
-- -----------------------------------------------------------------------------

local function generate_iban_via_bridge()
  -- Bridges.Bank.IBAN.Generate canonical (sonar_bank exports IBAN module).
  -- Defensive fallback inline: random AD-XXXX-XXXX-XXXX (NOT checksum-verified, dev only).
  if _G.Bridges and _G.Bridges.Bank and _G.Bridges.Bank.IBAN
     and type(_G.Bridges.Bank.IBAN.Generate) == 'function' then
    local ok, iban = pcall(_G.Bridges.Bank.IBAN.Generate)
    if ok and Validators.IsValidIBANFormat(iban) then return iban end
  end
  -- Defensive fallback (dev only — production REQUIRES sonar_bank IBAN module)
  local digits = {}
  local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  for _ = 1, 12 do
    local i = math.random(1, #charset)
    digits[#digits + 1] = charset:sub(i, i)
  end
  local s = table.concat(digits)
  return 'AD-' .. s:sub(1, 4) .. '-' .. s:sub(5, 8) .. '-' .. s:sub(9, 12)
end

--- OpenAccount.
---@param ctx { src, citizen_id, initial_balance, initial_savings }
function S.OpenAccount(ctx)
  local timer = Perf.StartTimer()
  local cid = ctx.citizen_id
  if not Validators.IsValidCitizenId(cid) then
    Perf.EndTimer(timer, 'C002', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end

  -- Defensive: cap initial balances
  local initial_balance = math.max(0, math.min(ctx.initial_balance or 0, 1000000))
  local initial_savings = math.max(0, math.min(ctx.initial_savings or 0, 1000000))

  local iban = generate_iban_via_bridge()
  local account_id, err = AccountsRepo.Insert(iban, cid, {
    initial_balance = initial_balance,
    initial_savings = initial_savings,
  })
  if err then
    Perf.EndTimer(timer, 'C002', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = err }
  end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.ACCOUNT_CREATE,
    actor_citizen_id = cid,
    actor_src        = ctx.src,
    target_account_id= account_id,
    target_iban      = iban,
    event_data       = {
      initial_balance = initial_balance,
      initial_savings = initial_savings,
    },
  })

  invalidate_bootstrap(cid)
  Perf.EndTimer(timer, 'C002', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = { account_id = account_id, iban = iban, citizen_id = cid } }
end

-- -----------------------------------------------------------------------------
-- §3. Freeze / Unfreeze (H006 — previous_flag_snapshot mandatory)
-- -----------------------------------------------------------------------------

local function freeze_helper(ctx, freeze_bool, event_type)
  local timer = Perf.StartTimer()
  local norm_iban = Validators.NormalizeIBAN(ctx.iban)
  if not norm_iban then
    Perf.EndTimer(timer, 'C015', { tier = Enums.TIER.TIER_3_ADMIN })
    return { ok = false, error = Errors.New('INVALID_IBAN') }
  end

  local row, fetch_err = AccountsRepo.GetByIban(norm_iban)
  if fetch_err then
    Perf.EndTimer(timer, 'C015', { tier = Enums.TIER.TIER_3_ADMIN })
    return { ok = false, error = fetch_err }
  end
  if not row then
    Perf.EndTimer(timer, 'C015', { tier = Enums.TIER.TIER_3_ADMIN })
    return { ok = false, error = Errors.New('ACCOUNT_NOT_FOUND', { iban = norm_iban }) }
  end

  -- H006 — snapshot BEFORE flag flip
  local previous_snapshot = {
    iban         = norm_iban,
    frozen_flag  = DB.ToBool(row.frozen_flag),
    status       = row.status,
    snapshot_ms  = now_ms(),
  }

  local _, set_err = AccountsRepo.SetFrozenFlag(norm_iban, freeze_bool)
  if set_err then
    Perf.EndTimer(timer, 'C015', { tier = Enums.TIER.TIER_3_ADMIN })
    return { ok = false, error = set_err }
  end

  Audit.Write({
    event_type             = event_type,
    actor_citizen_id       = ctx.actor_citizen_id,
    actor_src              = ctx.src,
    target_account_id      = row.account_id,
    target_iban            = norm_iban,
    target_citizen_id      = row.owner_citizen_id,
    previous_flag_snapshot = previous_snapshot,
    event_data             = {
      new_frozen_flag = freeze_bool,
      reason          = Validators.SanitizeReason(ctx.reason),
    },
    correlation_id         = ctx.correlation_id,
  })

  invalidate_bootstrap(row.owner_citizen_id)

  Perf.EndTimer(timer, 'C015', { tier = Enums.TIER.TIER_3_ADMIN })
  return { ok = true, data = { iban = norm_iban, frozen = freeze_bool } }
end

function S.FreezeAccount(ctx)
  return freeze_helper(ctx, true, Enums.AUDIT_EVENT_TYPE.ACCOUNT_FREEZE)
end

function S.UnfreezeAccount(ctx)
  return freeze_helper(ctx, false, Enums.AUDIT_EVENT_TYPE.ACCOUNT_UNFREEZE)
end

-- -----------------------------------------------------------------------------
-- §4. CloseAccount (only if balance == 0 AND savings == 0)
-- -----------------------------------------------------------------------------

function S.CloseAccount(ctx)
  local timer = Perf.StartTimer()
  local norm_iban = Validators.NormalizeIBAN(ctx.iban)
  if not norm_iban then
    Perf.EndTimer(timer, 'C019', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_IBAN') }
  end

  local owner_cid, row, own_err = Auth.RequireOwnership(ctx.src, norm_iban, { allow_joint = false })
  if own_err then
    Perf.EndTimer(timer, 'C019', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = own_err }
  end

  local balance = tonumber(row.balance_minor) or 0
  local savings = tonumber(row.savings_minor) or 0
  if balance > 0 or savings > 0 then
    Perf.EndTimer(timer, 'C019', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', {
      reason  = 'account must be zero-balance to close',
      balance = balance,
      savings = savings,
    }) }
  end

  local _, set_err = AccountsRepo.SetStatus(norm_iban, 'closed')
  if set_err then
    Perf.EndTimer(timer, 'C019', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = set_err }
  end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.ACCOUNT_CLOSE,
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_iban      = norm_iban,
    target_account_id= row.account_id,
    event_data       = { reason = Validators.SanitizeReason(ctx.reason) },
  })

  invalidate_bootstrap(owner_cid)
  Perf.EndTimer(timer, 'C019', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = { iban = norm_iban, status = 'closed' } }
end

-- -----------------------------------------------------------------------------
-- §5. Joint owners
-- -----------------------------------------------------------------------------

function S.AddJointOwner(ctx)
  local norm_iban = Validators.NormalizeIBAN(ctx.iban)
  if not norm_iban then return { ok = false, error = Errors.New('INVALID_IBAN') } end
  if not Validators.IsValidCitizenId(ctx.joint_citizen_id) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end

  local owner_cid, _, own_err = Auth.RequireOwnership(ctx.src, norm_iban, { allow_joint = false })
  if own_err then return { ok = false, error = own_err } end

  local _, err = AccountsRepo.AddJointOwner(norm_iban, ctx.joint_citizen_id, owner_cid)
  if err then return { ok = false, error = err } end

  Audit.Write({
    event_type       = 'joint_owner_added',
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_iban      = norm_iban,
    target_citizen_id= ctx.joint_citizen_id,
    event_data       = { reason = Validators.SanitizeReason(ctx.reason) },
  })

  invalidate_bootstrap(owner_cid)
  invalidate_bootstrap(ctx.joint_citizen_id)
  return { ok = true, data = { iban = norm_iban, joint_added = ctx.joint_citizen_id } }
end

function S.RemoveJointOwner(ctx)
  local norm_iban = Validators.NormalizeIBAN(ctx.iban)
  if not norm_iban then return { ok = false, error = Errors.New('INVALID_IBAN') } end

  local owner_cid, _, own_err = Auth.RequireOwnership(ctx.src, norm_iban, { allow_joint = false })
  if own_err then return { ok = false, error = own_err } end

  local _, err = AccountsRepo.RemoveJointOwner(norm_iban, ctx.joint_citizen_id)
  if err then return { ok = false, error = err } end

  Audit.Write({
    event_type       = 'joint_owner_removed',
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_iban      = norm_iban,
    target_citizen_id= ctx.joint_citizen_id,
  })

  invalidate_bootstrap(owner_cid)
  invalidate_bootstrap(ctx.joint_citizen_id)
  return { ok = true, data = { iban = norm_iban, joint_removed = ctx.joint_citizen_id } }
end

-- -----------------------------------------------------------------------------
-- §6. KYC flow (H006 — flag-changing events)
-- -----------------------------------------------------------------------------

--- SubmitKyc — caller submits documents (stored as event_data; service-of-record
--- decides storage strategy — for now: audit ledger only).
function S.SubmitKyc(ctx)
  if not Validators.IsValidCitizenId(ctx.citizen_id) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end

  Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.KYC_SUBMIT,
    actor_citizen_id = ctx.citizen_id,
    actor_src        = ctx.src,
    target_citizen_id= ctx.citizen_id,
    event_data       = {
      doc_count = ctx.doc_count or 0,
      submitted_ms = now_ms(),
    },
  })
  return { ok = true, data = { submitted_ms = now_ms() } }
end

local function kyc_decision(ctx, event_type, decision)
  local cid = ctx.target_citizen_id
  if not Validators.IsValidCitizenId(cid) then
    return { ok = false, error = Errors.New('INVALID_CITIZEN_ID') }
  end

  -- H006 — snapshot pre-decision compliance state (best-effort: query last KYC outcome).
  -- For now we capture decision context; deeper KYC flag table would live in compliance schema.
  local previous_snapshot = {
    target_citizen_id = cid,
    snapshot_ms       = now_ms(),
    last_decision     = 'unknown',
  }

  Audit.Write({
    event_type             = event_type,
    actor_citizen_id       = ctx.actor_citizen_id,
    actor_src              = ctx.src,
    target_citizen_id      = cid,
    previous_flag_snapshot = previous_snapshot,
    event_data             = {
      decision  = decision,
      reason    = Validators.SanitizeReason(ctx.reason),
    },
  })
  return { ok = true, data = { citizen_id = cid, decision = decision } }
end

function S.ApproveKyc(ctx)
  return kyc_decision(ctx, Enums.AUDIT_EVENT_TYPE.KYC_APPROVE, 'approved')
end

function S.RejectKyc(ctx)
  return kyc_decision(ctx, Enums.AUDIT_EVENT_TYPE.KYC_REJECT, 'rejected')
end

return S
