-- =============================================================================
-- SONAR Bank App — services/transfer_service.lua
-- =============================================================================
-- Core money-movement service. FSM #2 (transaction_lifecycle) orchestrator.
--
-- Operations:
--   Execute(ctx)             — main P2P transfer with idempotency + audit + publish
--   ExecuteToSavings(ctx)    — internal balance → savings move (own account)
--   ExecuteFromSavings(ctx)  — internal savings → balance move
--
-- Pipeline:
--   1. Validation (amount > 0, IBAN format, citizen owns from_iban)
--   2. Idempotency.Acquire (replay → return cached, in_flight → reject)
--   3. Pre-checks (balance ≥ amount, recipient exists, frozen flags)
--   4. Compose TX batch:
--      - debit from_iban
--      - credit to_iban
--      - insert tx row (status='committed')
--   5. DB.Transaction (atomic, retries on deadlock)
--   6. Idempotency.Commit (cache result)
--   7. Audit.Write (transfer_committed for from_iban + transfer_init initial entry)
--   8. Publish.PublishBalanceUpdate (sender + receiver if online)
--   9. recipients_service.InvalidateCitizen (sender — list changed)
--   10. bootstrap_service.InvalidateCitizen (sender + receiver)
--
-- Returned tuple: { ok=true, data=...} OR { ok=false, error={...} }
-- =============================================================================

BankApp.services.transfer = {}
local S = BankApp.services.transfer

local Validators  = BankApp.lib.validators
local Errors      = BankApp.lib.errors
local UUID        = BankApp.lib.uuid
local DB          = BankApp.lib.db
local Audit       = BankApp.lib.audit
local Publish     = BankApp.lib.publish
local Idempotency = BankApp.lib.idempotency
local Auth        = BankApp.lib.auth
local Perf        = BankApp.lib.perf
local Enums       = BankApp.lib.enums

local AccountsRepo     = BankApp.repos.accounts
local TransactionsRepo = BankApp.repos.transactions

-- -----------------------------------------------------------------------------
-- §1. Internal helpers
-- -----------------------------------------------------------------------------

local function now_ms()
  return os.time() * 1000 + math.floor((os.clock() % 1) * 1000)
end

local function resolve_src_for_citizen(citizen_id)
  return Auth.ResolveCitizenSrc(citizen_id)
end

local function invalidate_caches(sender_cid, receiver_cid)
  if BankApp.services.bootstrap and BankApp.services.bootstrap.InvalidateCitizen then
    BankApp.services.bootstrap.InvalidateCitizen(sender_cid)
    if receiver_cid and receiver_cid ~= sender_cid then
      BankApp.services.bootstrap.InvalidateCitizen(receiver_cid)
    end
  end
  if BankApp.services.recipients and BankApp.services.recipients.InvalidateCitizen then
    BankApp.services.recipients.InvalidateCitizen(sender_cid)
  end
end

-- -----------------------------------------------------------------------------
-- §2. Execute — main P2P transfer
-- -----------------------------------------------------------------------------

--- Execute — P2P transfer.
---@param ctx table {
---   src              = integer,         -- caller player source
---   citizen_id       = string,          -- caller citizen_id (verified upstream)
---   from_iban        = string,
---   to_iban          = string,
---   amount_minor     = integer,
---   reason           = string|nil,
---   idempotency_key  = string,
---   correlation_id   = string|nil,
--- }
---@return table { ok=bool, data|error }
function S.Execute(ctx)
  local timer = Perf.StartTimer()

  -- §2.1 Validation
  local schema_ok, schema_err = Validators.ValidateSchema(ctx, {
    citizen_id      = 'citizen_id',
    from_iban       = 'iban',
    to_iban         = 'iban',
    amount_minor    = 'amount',
    idempotency_key = 'idempotency_key',
  })
  if not schema_ok then
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = schema_err }
  end

  ctx.from_iban = Validators.NormalizeIBAN(ctx.from_iban)
  ctx.to_iban   = Validators.NormalizeIBAN(ctx.to_iban)
  if ctx.from_iban == ctx.to_iban then
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'from_iban == to_iban' }) }
  end

  -- §2.2 Ownership check
  local owner_cid, from_account, own_err = Auth.RequireOwnership(ctx.src, ctx.from_iban)
  if own_err then
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = own_err }
  end

  -- §2.3 Idempotency acquire
  local idem_status, cached, idem_err = Idempotency.Acquire(
    ctx.idempotency_key,
    { from_iban = ctx.from_iban, to_iban = ctx.to_iban, amount_minor = ctx.amount_minor },
    {
      actor_citizen_id = owner_cid,
      callback_id      = 'C006',
      ttl_seconds      = BankApp.Config.Idempotency.DEFAULT_TTL_SECONDS,
    }
  )
  if idem_status == 'replay' then
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = true, data = cached, replayed = true }
  elseif idem_status == 'collision' or idem_status == 'in_flight' then
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = idem_err }
  elseif idem_status ~= 'acquired' then
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = idem_err or Errors.New('INTERNAL_ERROR', { reason = 'idempotency unknown status' }) }
  end

  -- §2.4 Recipient existence check
  local to_account, to_err = AccountsRepo.GetByIban(ctx.to_iban)
  if to_err then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = to_err }
  end
  if not to_account then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('RECIPIENT_NOT_FOUND', { iban = ctx.to_iban }) }
  end
  if DB.ToBool(to_account.frozen_flag) then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ACCOUNT_FROZEN', { iban = ctx.to_iban, role = 'recipient' }) }
  end

  -- §2.5 Pre-check funds
  local from_balance = tonumber(from_account.balance_minor) or 0
  if from_balance < ctx.amount_minor then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS', {
      requested = ctx.amount_minor, available = from_balance,
    }) }
  end

  -- §2.6 Compose TX batch
  local txn_id = UUID.V4()
  local ts = now_ms()
  local tx_queries = {
    AccountsRepo.BuildDebitBalanceQuery(ctx.from_iban, ctx.amount_minor),
    AccountsRepo.BuildCreditBalanceQuery(ctx.to_iban, ctx.amount_minor),
    TransactionsRepo.BuildInsertQuery({
      txn_id          = txn_id,
      from_iban       = ctx.from_iban,
      to_iban         = ctx.to_iban,
      amount_minor    = ctx.amount_minor,
      reason          = Validators.SanitizeReason(ctx.reason),
      direction       = 'out',
      status          = 'committed',
      timestamp_ms    = ts,
      idempotency_key = ctx.idempotency_key,
      correlation_id  = ctx.correlation_id,
    }),
    TransactionsRepo.BuildUpdateStatusQuery(txn_id, 'committed', ts),
  }

  -- §2.7 Execute atomic batch
  local ok, tx_err = DB.Transaction(tx_queries)
  if not ok then
    Idempotency.Orphan(ctx.idempotency_key)
    Audit.Write({
      event_type       = Enums.AUDIT_EVENT_TYPE.TRANSFER_FAILED,
      actor_citizen_id = owner_cid,
      actor_src        = ctx.src,
      target_iban      = ctx.to_iban,
      event_data       = {
        from_iban    = ctx.from_iban,
        amount_minor = ctx.amount_minor,
        txn_id       = txn_id,
        reason       = 'tx_batch_failed',
        raw_err      = tx_err and tx_err.code,
      },
      correlation_id   = ctx.correlation_id,
    })
    Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = tx_err }
  end

  -- §2.8 Audit
  local audit_id = Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.TRANSFER_COMMITTED,
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_iban      = ctx.to_iban,
    target_citizen_id= to_account.owner_citizen_id,
    target_account_id= to_account.account_id,
    event_data       = {
      from_iban     = ctx.from_iban,
      to_iban       = ctx.to_iban,
      amount_minor  = ctx.amount_minor,
      txn_id        = txn_id,
      reason        = Validators.SanitizeReason(ctx.reason),
      committed_ms  = ts,
    },
    correlation_id   = ctx.correlation_id,
  })

  -- §2.9 Build result + commit idempotency
  local result = {
    txn_id              = txn_id,
    from_iban           = ctx.from_iban,
    to_iban             = ctx.to_iban,
    amount_minor        = ctx.amount_minor,
    committed_ms        = ts,
    cross_ref_audit_id  = audit_id,
  }
  Idempotency.Commit(ctx.idempotency_key, result)

  -- §2.10 Publish balance updates (M004 CP1-B)
  local sender_new_balance = from_balance - ctx.amount_minor
  Publish.PublishBalanceUpdate(
    ctx.src, owner_cid, sender_new_balance,
    tonumber(from_account.savings_minor) or 0,
    { reason = 'transfer_committed', correlation = ctx.correlation_id }
  )

  local recv_src = resolve_src_for_citizen(to_account.owner_citizen_id)
  if recv_src then
    local recv_new_balance = (tonumber(to_account.balance_minor) or 0) + ctx.amount_minor
    Publish.PublishBalanceUpdate(
      recv_src, to_account.owner_citizen_id, recv_new_balance,
      tonumber(to_account.savings_minor) or 0,
      { reason = 'transfer_received', correlation = ctx.correlation_id }
    )
  end

  -- §2.11 Invalidate caches
  invalidate_caches(owner_cid, to_account.owner_citizen_id)

  Perf.EndTimer(timer, 'C006', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = result }
end

-- -----------------------------------------------------------------------------
-- §3. ExecuteToSavings / ExecuteFromSavings (internal moves on own account)
-- -----------------------------------------------------------------------------

local function execute_internal_move(ctx, direction)
  local timer = Perf.StartTimer()

  local schema_ok, schema_err = Validators.ValidateSchema(ctx, {
    citizen_id      = 'citizen_id',
    from_iban       = 'iban',
    savings_iban    = 'iban',
    amount_minor    = 'amount',
    idempotency_key = 'idempotency_key',
  })
  if not schema_ok then
    Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = schema_err }
  end
  ctx.from_iban    = Validators.NormalizeIBAN(ctx.from_iban)
  ctx.savings_iban = Validators.NormalizeIBAN(ctx.savings_iban)

  if ctx.from_iban == ctx.savings_iban then
    Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'same_iban' }) }
  end

  local owner_cid, checking_account, own_err = Auth.RequireOwnership(ctx.src, ctx.from_iban, { allow_joint = false })
  if own_err then
    Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = own_err }
  end

  local savings_account, sav_err = AccountsRepo.GetByIban(ctx.savings_iban)
  if sav_err or not savings_account then
    Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ACCOUNT_NOT_FOUND', { iban = ctx.savings_iban }) }
  end
  if savings_account.owner_citizen_id ~= owner_cid then
    Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('FORBIDDEN', { reason = 'savings_not_owned' }) }
  end
  if savings_account.account_class ~= 'savings' then
    Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INVALID_ACCOUNT_CLASS', { account_class = savings_account.account_class }) }
  end
  if savings_account.status == 'closed' then
    Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ACCOUNT_CLOSED', { iban = ctx.savings_iban }) }
  end

  local idem_status, cached, idem_err = Idempotency.Acquire(
    ctx.idempotency_key,
    { iban = ctx.from_iban, savings_iban = ctx.savings_iban, amount_minor = ctx.amount_minor, dir = direction },
    { actor_citizen_id = owner_cid, callback_id = 'C007' }
  )
  if idem_status == 'replay' then
    Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = true, data = cached, replayed = true }
  elseif idem_status ~= 'acquired' then
    Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = idem_err or Errors.New('IDEMPOTENCY_IN_FLIGHT') }
  end

  -- Build TX batch: checking_account.balance ↔ savings_account.balance (separate rows)
  local tx_queries
  if direction == 'to_savings' then
    if (tonumber(checking_account.balance_minor) or 0) < ctx.amount_minor then
      Idempotency.Orphan(ctx.idempotency_key)
      Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
      return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS') }
    end
    tx_queries = {
      AccountsRepo.BuildDebitBalanceQuery(ctx.from_iban, ctx.amount_minor),
      AccountsRepo.BuildCreditBalanceQuery(ctx.savings_iban, ctx.amount_minor),
    }
  else -- from_savings
    if (tonumber(savings_account.balance_minor) or 0) < ctx.amount_minor then
      Idempotency.Orphan(ctx.idempotency_key)
      Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
      return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS', { account = 'savings' }) }
    end
    tx_queries = {
      AccountsRepo.BuildDebitBalanceQuery(ctx.savings_iban, ctx.amount_minor),
      AccountsRepo.BuildCreditBalanceQuery(ctx.from_iban, ctx.amount_minor),
    }
  end

  local ok, tx_err = DB.Transaction(tx_queries)
  if not ok then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = tx_err }
  end

  -- Re-fetch updated balances for publish
  local fresh_checking, _ = AccountsRepo.GetBalance(ctx.from_iban)
  local fresh_savings, _   = AccountsRepo.GetBalance(ctx.savings_iban)
  if fresh_checking then
    Publish.PublishBalanceUpdate(
      ctx.src, owner_cid,
      tonumber(fresh_checking.balance_minor) or 0,
      tonumber((fresh_savings or {}).balance_minor) or 0,
      { reason = direction == 'to_savings' and 'savings_deposit' or 'savings_withdraw', correlation = ctx.correlation_id }
    )
  end

  Audit.Write({
    event_type       = direction == 'to_savings' and 'savings_deposit' or 'savings_withdraw',
    actor_citizen_id = owner_cid,
    actor_src        = ctx.src,
    target_iban      = ctx.from_iban,
    event_data       = { amount_minor = ctx.amount_minor, direction = direction, savings_iban = ctx.savings_iban, correlation_id = ctx.correlation_id },
  })

  local result = {
    iban         = ctx.from_iban,
    savings_iban = ctx.savings_iban,
    amount_minor = ctx.amount_minor,
    direction    = direction,
    committed_ms = now_ms(),
    correlation_id = ctx.correlation_id,
  }
  Idempotency.Commit(ctx.idempotency_key, result)

  invalidate_caches(owner_cid, nil)

  Perf.EndTimer(timer, 'C007', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = result }
end

function S.ExecuteToSavings(ctx)   return execute_internal_move(ctx, 'to_savings') end
function S.ExecuteFromSavings(ctx) return execute_internal_move(ctx, 'from_savings') end

-- -----------------------------------------------------------------------------
-- §4. ExecuteAsSystem — privileged path for cron-initiated transfers
--
--   Bug fix per Founder directive (recurring charges must work even when
--   borrower is offline). Sentinel src=0 means "system actor — no player
--   source binding, no Auth.RequireOwnership". Still enforces:
--     - schema validation
--     - idempotency Acquire/Commit/Orphan
--     - account existence + frozen flag check
--     - funds pre-check
--     - atomic TX batch (debit + credit + insert tx row)
--     - audit (actor_citizen_id = ctx.actor_citizen_id, actor_src = 0,
--             event_data.system_initiated = true)
--     - publish balance to receiver if online (sender may be offline)
--
--   ONLY callable from server-side code (services/cron). Never exposed via
--   callback or NetEvent — there is no path from client to this fn.
-- -----------------------------------------------------------------------------

--- ExecuteAsSystem — privileged cron-initiated transfer.
---@param ctx table {
---   actor_citizen_id = string,        -- the citizen on whose behalf system acts
---   from_iban        = string,
---   to_iban          = string,
---   amount_minor     = integer,
---   reason           = string,
---   idempotency_key  = string,
---   correlation_id   = string|nil,
---   system_origin    = string,         -- 'recurring' | 'reconcile' | 'admin_cron' (audit tag)
--- }
---@return table { ok=bool, data|error, replayed? }
function S.ExecuteAsSystem(ctx)
  local timer = Perf.StartTimer()

  -- §4.1 Validation
  local schema_ok, schema_err = Validators.ValidateSchema(ctx, {
    actor_citizen_id = 'citizen_id',
    from_iban        = 'iban',
    to_iban          = 'iban',
    amount_minor     = 'amount',
    idempotency_key  = 'idempotency_key',
  })
  if not schema_ok then
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = schema_err }
  end

  ctx.from_iban = Validators.NormalizeIBAN(ctx.from_iban)
  ctx.to_iban   = Validators.NormalizeIBAN(ctx.to_iban)
  if ctx.from_iban == ctx.to_iban then
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('VALIDATION_FAILED', { reason = 'from_iban == to_iban' }) }
  end

  -- §4.2 NO Auth.RequireOwnership — system actor. Instead, lookup from_account
  -- directly and verify it exists + belongs to claimed actor_citizen_id.
  local from_account, fetch_err = AccountsRepo.GetByIban(ctx.from_iban)
  if fetch_err then
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = fetch_err }
  end
  if not from_account then
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ACCOUNT_NOT_FOUND', { iban = ctx.from_iban }) }
  end
  if from_account.owner_citizen_id ~= ctx.actor_citizen_id then
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('AUTH_OWNER_MISMATCH', {
      reason = 'from_iban not owned by claimed actor',
      iban   = ctx.from_iban,
    }) }
  end
  if DB.ToBool(from_account.frozen_flag) then
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ACCOUNT_FROZEN', { iban = ctx.from_iban, role = 'sender' }) }
  end

  -- §4.3 Idempotency acquire
  local idem_status, cached, idem_err = Idempotency.Acquire(
    ctx.idempotency_key,
    {
      from_iban    = ctx.from_iban,
      to_iban      = ctx.to_iban,
      amount_minor = ctx.amount_minor,
      system       = true,
    },
    {
      actor_citizen_id = ctx.actor_citizen_id,
      callback_id      = 'C006_system',
      ttl_seconds      = BankApp.Config.Idempotency.DEFAULT_TTL_SECONDS,
    }
  )
  if idem_status == 'replay' then
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = true, data = cached, replayed = true }
  elseif idem_status == 'collision' or idem_status == 'in_flight' then
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = idem_err }
  elseif idem_status ~= 'acquired' then
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = idem_err or Errors.New('INTERNAL_ERROR', { reason = 'idempotency unknown status' }) }
  end

  -- §4.4 Recipient existence + frozen check
  local to_account, to_err = AccountsRepo.GetByIban(ctx.to_iban)
  if to_err then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = to_err }
  end
  if not to_account then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('RECIPIENT_NOT_FOUND', { iban = ctx.to_iban }) }
  end
  if DB.ToBool(to_account.frozen_flag) then
    Idempotency.Orphan(ctx.idempotency_key)
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('ACCOUNT_FROZEN', { iban = ctx.to_iban, role = 'recipient' }) }
  end

  -- §4.5 Pre-check funds
  local from_balance = tonumber(from_account.balance_minor) or 0
  if from_balance < ctx.amount_minor then
    Idempotency.Orphan(ctx.idempotency_key)
    Audit.Write({
      event_type       = Enums.AUDIT_EVENT_TYPE.TRANSFER_FAILED,
      actor_citizen_id = ctx.actor_citizen_id,
      actor_src        = 0,  -- system sentinel
      target_iban      = ctx.to_iban,
      target_citizen_id= to_account.owner_citizen_id,
      event_data       = {
        from_iban        = ctx.from_iban,
        amount_minor     = ctx.amount_minor,
        reason           = 'insufficient_funds',
        system_initiated = true,
        system_origin    = ctx.system_origin or 'unknown',
      },
      correlation_id   = ctx.correlation_id,
    })
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = Errors.New('INSUFFICIENT_FUNDS', {
      requested = ctx.amount_minor, available = from_balance,
    }) }
  end

  -- §4.6 Compose TX batch
  local txn_id = UUID.V4()
  local ts = now_ms()
  local tx_queries = {
    AccountsRepo.BuildDebitBalanceQuery(ctx.from_iban, ctx.amount_minor),
    AccountsRepo.BuildCreditBalanceQuery(ctx.to_iban, ctx.amount_minor),
    TransactionsRepo.BuildInsertQuery({
      txn_id          = txn_id,
      from_iban       = ctx.from_iban,
      to_iban         = ctx.to_iban,
      amount_minor    = ctx.amount_minor,
      reason          = Validators.SanitizeReason(ctx.reason),
      direction       = 'out',
      status          = 'committed',
      timestamp_ms    = ts,
      idempotency_key = ctx.idempotency_key,
      correlation_id  = ctx.correlation_id,
    }),
    TransactionsRepo.BuildUpdateStatusQuery(txn_id, 'committed', ts),
  }

  -- §4.7 Atomic batch
  local ok, tx_err = DB.Transaction(tx_queries)
  if not ok then
    Idempotency.Orphan(ctx.idempotency_key)
    Audit.Write({
      event_type       = Enums.AUDIT_EVENT_TYPE.TRANSFER_FAILED,
      actor_citizen_id = ctx.actor_citizen_id,
      actor_src        = 0,
      target_iban      = ctx.to_iban,
      event_data       = {
        from_iban        = ctx.from_iban,
        amount_minor     = ctx.amount_minor,
        txn_id           = txn_id,
        reason           = 'tx_batch_failed',
        raw_err          = tx_err and tx_err.code,
        system_initiated = true,
        system_origin    = ctx.system_origin or 'unknown',
      },
      correlation_id   = ctx.correlation_id,
    })
    Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
    return { ok = false, error = tx_err }
  end

  -- §4.8 Audit (system tag)
  local audit_id = Audit.Write({
    event_type       = Enums.AUDIT_EVENT_TYPE.TRANSFER_COMMITTED,
    actor_citizen_id = ctx.actor_citizen_id,
    actor_src        = 0,  -- system sentinel
    target_iban      = ctx.to_iban,
    target_citizen_id= to_account.owner_citizen_id,
    target_account_id= to_account.account_id,
    event_data       = {
      from_iban        = ctx.from_iban,
      to_iban          = ctx.to_iban,
      amount_minor     = ctx.amount_minor,
      txn_id           = txn_id,
      reason           = Validators.SanitizeReason(ctx.reason),
      committed_ms     = ts,
      system_initiated = true,
      system_origin    = ctx.system_origin or 'unknown',
    },
    correlation_id   = ctx.correlation_id,
  })

  -- §4.9 Idempotency commit
  local result = {
    txn_id              = txn_id,
    from_iban           = ctx.from_iban,
    to_iban             = ctx.to_iban,
    amount_minor        = ctx.amount_minor,
    committed_ms        = ts,
    cross_ref_audit_id  = audit_id,
    system_initiated    = true,
  }
  Idempotency.Commit(ctx.idempotency_key, result)

  -- §4.10 Publish balance updates (M004)
  --   Sender side: only if currently online (system actor has no src binding).
  local sender_src = Auth.ResolveCitizenSrc(ctx.actor_citizen_id)
  if sender_src then
    local sender_new_balance = from_balance - ctx.amount_minor
    Publish.PublishBalanceUpdate(
      sender_src, ctx.actor_citizen_id, sender_new_balance,
      tonumber(from_account.savings_minor) or 0,
      { reason = 'system_' .. (ctx.system_origin or 'transfer'), correlation = ctx.correlation_id }
    )
  end

  --   Receiver side: publish if online.
  local recv_src = Auth.ResolveCitizenSrc(to_account.owner_citizen_id)
  if recv_src then
    local recv_new_balance = (tonumber(to_account.balance_minor) or 0) + ctx.amount_minor
    Publish.PublishBalanceUpdate(
      recv_src, to_account.owner_citizen_id, recv_new_balance,
      tonumber(to_account.savings_minor) or 0,
      { reason = 'system_received', correlation = ctx.correlation_id }
    )
  end

  -- §4.11 Cache invalidation
  invalidate_caches(ctx.actor_citizen_id, to_account.owner_citizen_id)

  Perf.EndTimer(timer, 'C006_system', { tier = Enums.TIER.TIER_2_WRITE })
  return { ok = true, data = result }
end

return S
