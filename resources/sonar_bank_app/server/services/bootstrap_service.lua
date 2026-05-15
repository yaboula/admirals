-- =============================================================================
-- SONAR Bank App — services/bootstrap_service.lua
-- =============================================================================
-- REQ-FE-001 — Consolidated bootstrap snapshot.
--
-- Performance contract:
--   - p99 latency < 80 ms (Frontend mandate).
--   - Single round-trip from FE perspective: one callback returning everything.
--   - Implementation: parallel DB queries via DB.Parallel + per-call LRU cache.
--
-- Returned payload shape (matches `sonar:bank:bootstrap:snapshot` callback):
--   {
--     citizen_id        = string,
--     accounts          = [...],
--     recent_transactions = [...],
--     recent_recipients = [...],   -- REQ-FE-002 piggyback
--     saved_recipients  = [...],
--     loans             = [...],
--     recurring         = [...],
--     portfolio         = [...],
--     cards             = [...],
--     outstanding_notices = [...], -- audit-driven (compliance reviews etc)
--     pending_tx_count  = integer,
--     server_now_ms     = integer,
--     bootstrap_id      = string,  -- UUID v4 for FE deduplication
--     duration_ms       = number,  -- self-reported
--   }
--
-- Cache strategy:
--   - Per-citizen LRU cache (TTL = Config.Cache.SESSION_META_TTL_MS = 30s).
--   - Invalidated on any write touching that citizen's accounts (transfer
--     service / admin service publish via `Bootstrap.InvalidateCitizen`).
-- =============================================================================

BankApp.services.bootstrap = {}
local S = BankApp.services.bootstrap

local DB         = BankApp.lib.db
local UUID       = BankApp.lib.uuid
local Validators = BankApp.lib.validators
local Errors     = BankApp.lib.errors
local Perf       = BankApp.lib.perf
local Enums      = BankApp.lib.enums
local Config     = BankApp.Config

local Accounts     = BankApp.repos.accounts
local Transactions = BankApp.repos.transactions
local Recipients   = BankApp.repos.recipients
local Loans        = BankApp.repos.loans
local Recurring    = BankApp.repos.recurring
local Portfolio    = BankApp.repos.portfolio
local Cards        = BankApp.repos.cards
local AuditQuery   = BankApp.repos.audit_query

-- -----------------------------------------------------------------------------
-- §1. Per-citizen LRU cache (small + short TTL — staleness budget tight)
-- -----------------------------------------------------------------------------

local _cache = {}  -- citizen_id → { payload, expires_ms }

local function now_ms()
  return os.time() * 1000 + math.floor((os.clock() % 1) * 1000)
end

local function cache_get(citizen_id)
  if not Config.Features.ENABLE_BOOTSTRAP_CACHE_LRU then return nil end
  local entry = _cache[citizen_id]
  if not entry then return nil end
  if entry.expires_ms < now_ms() then
    _cache[citizen_id] = nil
    return nil
  end
  return entry.payload
end

local function cache_set(citizen_id, payload)
  if not Config.Features.ENABLE_BOOTSTRAP_CACHE_LRU then return end
  _cache[citizen_id] = {
    payload     = payload,
    expires_ms  = now_ms() + Config.Cache.SESSION_META_TTL_MS,
  }
end

--- InvalidateCitizen — called by transfer/admin services on write.
function S.InvalidateCitizen(citizen_id)
  _cache[citizen_id] = nil
end

--- InvalidateAll — defensive (e.g. on schema migration / admin reset).
function S.InvalidateAll()
  _cache = {}
end

-- -----------------------------------------------------------------------------
-- §2. Build snapshot — parallel reads
-- -----------------------------------------------------------------------------

local QUERY_INDEX = {
  ACCOUNTS            = 1,
  RECENT_TX           = 2,
  RECENT_RECIPIENTS   = 3,
  SAVED_RECIPIENTS    = 4,
  LOANS               = 5,
  RECURRING           = 6,
  PORTFOLIO           = 7,
  CARDS               = 8,
  OUTSTANDING_NOTICES = 9,
  PENDING_TX_COUNT    = 10,
}

--- BuildSnapshot — REQ-FE-001 main entry point.
---@param citizen_id string
---@return table|nil snapshot
---@return table|nil err
function S.BuildSnapshot(citizen_id)
  if not Validators.IsValidCitizenId(citizen_id) then
    return nil, Errors.New('INVALID_CITIZEN_ID', { citizen_id = tostring(citizen_id) })
  end

  -- Cache hit fast path
  local cached = cache_get(citizen_id)
  if cached then
    -- Refresh the bootstrap_id + server_now_ms but keep payload data
    return {
      citizen_id          = cached.citizen_id,
      accounts            = cached.accounts,
      recent_transactions = cached.recent_transactions,
      recent_recipients   = cached.recent_recipients,
      saved_recipients    = cached.saved_recipients,
      loans               = cached.loans,
      recurring           = cached.recurring,
      portfolio           = cached.portfolio,
      cards               = cached.cards,
      outstanding_notices = cached.outstanding_notices,
      pending_tx_count    = cached.pending_tx_count,
      server_now_ms       = now_ms(),
      bootstrap_id        = UUID.V4(),
      cached              = true,
      duration_ms         = 0,
    }, nil
  end

  local timer = Perf.StartTimer()

  -- Build parallel query plan
  local queries = {
    [QUERY_INDEX.ACCOUNTS]            = Accounts.BuildSnapshotQuery(citizen_id),
    [QUERY_INDEX.RECENT_TX]           = Transactions.BuildRecentTransactionsQuery(citizen_id, 20),
    [QUERY_INDEX.RECENT_RECIPIENTS]   = Transactions.BuildRecentRecipientsQuery(
                                          citizen_id,
                                          Config.RecentRecipients.WINDOW_DAYS,
                                          Config.RecentRecipients.LIMIT,
                                          Config.RecentRecipients.PRESET_AMOUNTS),
    [QUERY_INDEX.SAVED_RECIPIENTS]    = Recipients.BuildSavedListQuery(citizen_id, 50),
    [QUERY_INDEX.LOANS]               = Loans.BuildSnapshotQuery(citizen_id, Config.Bootstrap.MAX_LOANS),
    [QUERY_INDEX.RECURRING]           = Recurring.BuildSnapshotQuery(citizen_id, Config.Bootstrap.MAX_RECURRING),
    [QUERY_INDEX.PORTFOLIO]           = Portfolio.BuildSnapshotQuery(citizen_id, Config.Bootstrap.MAX_PORTFOLIO_HOLDINGS),
    [QUERY_INDEX.CARDS]               = Cards.BuildSnapshotQuery(citizen_id, 8),
    [QUERY_INDEX.OUTSTANDING_NOTICES] = AuditQuery.BuildOutstandingNoticesQuery(citizen_id, Config.Bootstrap.MAX_OUTSTANDING_AUDITS),
    [QUERY_INDEX.PENDING_TX_COUNT]    = Transactions.BuildPendingCountQuery(citizen_id),
  }

  local results, err = DB.Parallel(queries, {
    timeout_ms = Config.Bootstrap.TOTAL_TIMEOUT_MS,
    allow_partial = true,
  })
  if err then
    Perf.EndTimer(timer, 'C001', { tier = Enums.TIER.TIER_1_READ })
    return nil, err
  end
  if results._errors and results._errors[QUERY_INDEX.ACCOUNTS] then
    Perf.EndTimer(timer, 'C001', { tier = Enums.TIER.TIER_1_READ })
    return nil, Errors.New('DB_TRANSACTION_FAILED', {
      i = QUERY_INDEX.ACCOUNTS,
      raw = results._errors[QUERY_INDEX.ACCOUNTS],
    })
  end

  -- Decode joint_owners JSON string → Lua array per account row.
  -- MySQL JSON_ARRAYAGG returns a JSON-encoded string; FE contract expects
  -- string[] | null so we normalise here once before payload composition.
  local raw_accounts = results[QUERY_INDEX.ACCOUNTS] or {}
  for _, account in ipairs(raw_accounts) do
    local raw = account.joint_owners
    if type(raw) == 'string' then
      if raw == '' or raw == '[]' then
        account.joint_owners = nil
      elseif json and json.decode then
        local ok_decode, decoded = pcall(json.decode, raw)
        if ok_decode and type(decoded) == 'table' and #decoded > 0 then
          account.joint_owners = decoded
        else
          account.joint_owners = nil
        end
      else
        account.joint_owners = nil
      end
    elseif type(raw) == 'table' then
      if #raw == 0 then account.joint_owners = nil end
    else
      account.joint_owners = nil
    end
  end

  -- Compose payload
  local payload = {
    citizen_id          = citizen_id,
    accounts            = raw_accounts,
    recent_transactions = results[QUERY_INDEX.RECENT_TX] or {},
    recent_recipients   = results[QUERY_INDEX.RECENT_RECIPIENTS] or {},
    saved_recipients    = results[QUERY_INDEX.SAVED_RECIPIENTS] or {},
    loans               = results[QUERY_INDEX.LOANS] or {},
    recurring           = results[QUERY_INDEX.RECURRING] or {},
    portfolio           = results[QUERY_INDEX.PORTFOLIO] or {},
    cards               = results[QUERY_INDEX.CARDS] or {},
    outstanding_notices = results[QUERY_INDEX.OUTSTANDING_NOTICES] or {},
    pending_tx_count    = tonumber(results[QUERY_INDEX.PENDING_TX_COUNT]) or 0,
  }

  -- Cache (without the per-call fields)
  cache_set(citizen_id, payload)

  -- Stamp per-call fields
  local elapsed_ms = Perf.EndTimer(timer, 'C001', { tier = Enums.TIER.TIER_1_READ })
  payload.server_now_ms = now_ms()
  payload.bootstrap_id  = UUID.V4()
  payload.cached        = false
  payload.duration_ms   = elapsed_ms

  return payload, nil
end

-- -----------------------------------------------------------------------------
-- §3. C001b fallback (deprecated CP1-A consumer migration helper)
--
--   Per M004 cross-cutting refactor: clients still using deprecated
--   `bank.balance.<cid>` GlobalState pattern can call this lightweight callback
--   to retrieve current balance/savings WITHOUT triggering full bootstrap.
-- -----------------------------------------------------------------------------

--- GetBalanceSnapshot — C001b fallback callback support.
---@param citizen_id string
---@param iban string
---@return table|nil { balance_minor, savings_minor }, table|nil err
function S.GetBalanceSnapshot(citizen_id, iban)
  if not Validators.IsValidCitizenId(citizen_id) then
    return nil, Errors.New('INVALID_CITIZEN_ID')
  end
  if not Validators.IsValidIBANFormat(iban) then
    return nil, Errors.New('INVALID_IBAN')
  end
  local row, err = Accounts.GetBalance(iban)
  if err then return nil, err end
  if not row then
    return nil, Errors.New('ACCOUNT_NOT_FOUND', { iban = iban })
  end
  return {
    balance_minor = tonumber(row.balance_minor) or 0,
    savings_minor = tonumber(row.savings_minor) or 0,
    iban          = iban,
    citizen_id    = citizen_id,
    server_now_ms = now_ms(),
  }, nil
end

return S
