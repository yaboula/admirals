-- =============================================================================
-- SONAR Bank App — services/cron/savings_interest.lua
-- =============================================================================
-- Daily savings interest accrual (config-driven, banker-overridable).
--
--   Inputs (no banker required):
--     - Annual rate (bps): Economy.SavingsInterestBps()
--                          → reads C.Banker.Limits.savings_interest_rate_bps
--                          → fallback to default (300 bps = 3% APR)
--     - Period: C.Cron.SavingsInterest.period_seconds (default 24h)
--     - Basis : C.Cron.SavingsInterest.accrual_basis_days (default 365)
--
--   Per-eligible-account formula (per run):
--       delta_minor = balance_minor * rate_bps * elapsed_seconds
--                     ───────────────────────────────────────────
--                     10000 * accrual_basis_days * 86400
--
--   Eligibility: `account_class = 'savings'` AND `closed_at IS NULL`
--                AND `balance_minor >= min_balance_minor`.
--
--   Persistence: each run writes its UNIX timestamp to
--   sonar_bank_config_overrides[savings_interest_last_run_at]. On restart
--   the next heartbeat detects if a period elapsed.
--
--   Per-account effect: balance += delta (single row UPDATE in a TX with a
--   matching movement row category='interest', audit ledger entry).
-- =============================================================================

BankApp.services.cron = BankApp.services.cron or {}
BankApp.services.cron.savings_interest = {}
local S = BankApp.services.cron.savings_interest

local Config       = BankApp.Config
local DB           = BankApp.lib.db
local Audit        = BankApp.lib.audit
local Enums        = BankApp.lib.enums
local Economy      = BankApp.lib.economy
local Logger       = BankApp.lib.logger
local UUID         = BankApp.lib.uuid
local AccountsRepo = BankApp.repos.accounts
local TransactionsRepo = BankApp.repos.transactions
local BankerRepo   = BankApp.repos.banker

local function _cfg()
  return (Config.Cron and Config.Cron.SavingsInterest) or {}
end

local PREFIX = (Config.Logging and Config.Logging.PREFIX) or '[sonar_bank_app]'

local function _log(level, msg)
  if Logger and Logger[level] then
    Logger[level](msg)
  else
    print(PREFIX .. ' ' .. msg)
  end
end

local function _decode_override_value(value_json)
  if type(value_json) ~= 'string' or value_json == '' then return nil end
  local ok, decoded = pcall(json.decode, value_json)
  if not ok or type(decoded) ~= 'table' then return nil end
  return decoded.value
end

local function _read_last_run_unix()
  local key = _cfg().last_run_key or 'savings_interest_last_run_at'
  if not BankerRepo or not BankerRepo.GetConfigOverride then return 0 end
  local row = BankerRepo.GetConfigOverride(key)
  if not row then return 0 end
  return tonumber(_decode_override_value(row.value_json)) or 0
end

local function _write_last_run_unix(ts)
  local key = _cfg().last_run_key or 'savings_interest_last_run_at'
  if not BankerRepo or not BankerRepo.UpsertConfigOverride then return end
  BankerRepo.UpsertConfigOverride({
    config_key            = key,
    value_json            = json.encode({ value = ts }),
    updated_by_citizen_id = 'system',
    updated_by_role       = 'cron',
  })
end

-- ---------------------------------------------------------------------------
-- §1. Eligible accounts query
-- ---------------------------------------------------------------------------
local SQL_ELIGIBLE_SAVINGS = [[
SELECT a.id   AS account_id,
       a.iban AS iban,
       sa.char_id AS owner_citizen_id,
       CAST(ROUND(a.balance * 100) AS SIGNED) AS balance_minor
FROM sonar_bank_accounts a
LEFT JOIN sonar_accounts sa ON sa.id = a.owner_account_id
WHERE a.account_class = 'savings'
  AND a.closed_at IS NULL
  AND a.is_frozen = 0
  AND a.balance >= (? / 100.0)
]]

-- ---------------------------------------------------------------------------
-- §2. RunOnce — execute a single accrual pass
-- ---------------------------------------------------------------------------
function S.RunOnce(opts)
  opts = opts or {}
  local cfg = _cfg()
  if cfg.enabled == false then
    return { ok = true, data = { skipped = 'disabled' } }
  end

  local now_unix = os.time()
  local last_run = _read_last_run_unix()
  local elapsed  = (last_run > 0) and (now_unix - last_run) or (cfg.period_seconds or 86400)
  local period   = cfg.period_seconds or 86400
  if not opts.force and last_run > 0 and elapsed < period then
    return { ok = true, data = { skipped = 'too_soon', elapsed_seconds = elapsed, period_seconds = period } }
  end

  local rate_bps = Economy.SavingsInterestBps() or 0
  if rate_bps <= 0 then
    _write_last_run_unix(now_unix)
    return { ok = true, data = { skipped = 'zero_rate', rate_bps = rate_bps } }
  end

  local min_balance = cfg.min_balance_minor or 100
  local basis_days  = cfg.accrual_basis_days or 365
  local basis_secs  = basis_days * 86400

  -- Cap elapsed at one period to avoid a single huge accrual if the server
  -- was down for days. Operators can `force = true` to override.
  local accrual_seconds = math.min(elapsed, period)

  local rows, q_err = DB.Query(SQL_ELIGIBLE_SAVINGS, { min_balance })
  if q_err then
    _log('Error', ('[savings_interest] query failed: %s'):format(q_err.code or 'unknown'))
    return { ok = false, error = q_err }
  end

  local credits = {}      -- queued account credits
  local total_minor = 0
  local skipped_zero = 0
  for _, r in ipairs(rows or {}) do
    local bal = tonumber(r.balance_minor) or 0
    -- delta_minor = balance * rate_bps * accrual_seconds / (10000 * basis_secs)
    local raw = bal * rate_bps * accrual_seconds
    local denom = 10000 * basis_secs
    local delta = math.floor(raw / denom)
    if delta > 0 then
      credits[#credits + 1] = {
        iban         = r.iban,
        owner_cid    = r.owner_citizen_id,
        delta_minor  = delta,
        balance_pre  = bal,
      }
      total_minor = total_minor + delta
    else
      skipped_zero = skipped_zero + 1
    end
  end

  local ts_ms = now_unix * 1000
  local processed = 0
  for _, c in ipairs(credits) do
    local txn_id = UUID.V4()
    local ok = DB.Transaction({
      AccountsRepo.BuildCreditBalanceQuery(c.iban, c.delta_minor),
      TransactionsRepo.BuildSingleDebitQuery({
        iban            = c.iban,
        amount_minor    = -c.delta_minor,   -- negative debit = credit
        category        = 'interest',
        reason          = ('Savings interest %.2f%% APR'):format(rate_bps / 100),
        txn_id          = txn_id,
        timestamp_ms    = ts_ms,
        idempotency_key = ('interest:%s:%d'):format(c.iban, now_unix),
      }),
    })
    if ok then
      processed = processed + 1
      Audit.Write({
        event_type        = Enums.AUDIT_EVENT_TYPE.INTEREST_ACCRUED or 'interest_accrued',
        actor_citizen_id  = 'system',
        target_citizen_id = c.owner_cid,
        target_iban       = c.iban,
        event_data        = {
          delta_minor    = c.delta_minor,
          rate_bps       = rate_bps,
          balance_pre    = c.balance_pre,
          accrual_secs   = accrual_seconds,
          basis_days     = basis_days,
          via            = 'cron',
        },
      })
    end
  end

  _write_last_run_unix(now_unix)

  if cfg.log_summary then
    _log('Info', ('[savings_interest] processed=%d/%d total_minor=%d rate_bps=%d accrual_secs=%d'):format(
      processed, #credits, total_minor, rate_bps, accrual_seconds))
  end

  return {
    ok = true,
    data = {
      processed      = processed,
      attempted      = #credits,
      skipped_zero   = skipped_zero,
      total_minor    = total_minor,
      rate_bps       = rate_bps,
      accrual_seconds = accrual_seconds,
      last_run_unix  = now_unix,
    },
  }
end

-- ---------------------------------------------------------------------------
-- §3. Scheduler — periodic heartbeat (started by boot/cron_boot.lua)
-- ---------------------------------------------------------------------------
function S.StartHeartbeat()
  local cfg = _cfg()
  if cfg.enabled == false then return end
  local interval = cfg.heartbeat_ms or (5 * 60 * 1000)
  Citizen.CreateThread(function()
    -- Wait a few seconds after boot so other resources finish loading.
    Citizen.Wait(15000)
    while true do
      local ok, val = pcall(S.RunOnce)
      if not ok then
        -- val is the runtime error string when pcall fails.
        _log('Error', ('[savings_interest] heartbeat crash: %s'):format(tostring(val)))
      elseif type(val) == 'table' and val.ok == false and val.error then
        -- RunOnce returned a structured error envelope.
        _log('Error', ('[savings_interest] heartbeat error: %s'):format(
          tostring(val.error.code or val.error.message or 'unknown')))
      end
      Citizen.Wait(interval)
    end
  end)
end
