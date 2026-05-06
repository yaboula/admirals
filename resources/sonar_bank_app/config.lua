-- =============================================================================
-- SONAR Bank App — config.lua
-- =============================================================================
-- Convars + tier perf budgets + R1 hardening config + cache TTLs + rate-limit
-- buckets + idempotency TTL + audit batch + bootstrap snapshot config.
--
-- Loaded FIRST (shared scope: ambos client+server VMs ven Config). Sin DB deps,
-- sin SONAR.* deps. Pure configuration.
-- =============================================================================

BankApp = BankApp or { lib = {}, services = {}, repos = {}, callbacks = {}, state = {}, events = {} }
BankApp.Config = {}

local C = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. Resource metadata
-- -----------------------------------------------------------------------------
C.RESOURCE_NAME    = 'sonar_bank_app'
C.RESOURCE_VERSION = '1.0.1-r1'
C.PHASE            = 'A'

-- -----------------------------------------------------------------------------
-- §2. R1 hardening convars (DevOps H4 obligation per BANK-BE.LOCK.R1)
--
--   Read at boot via GetConvar — defaults documented here, must be set en
--   server.cfg / runtime convars para producción. Validation enforced en
--   lib/hmac.lua + lib/rate_limit.lua + boot/validators.lua.
-- -----------------------------------------------------------------------------
C.Convars = {
  -- M006 — ATM HMAC secret (mandatory en producción, min 64 hex chars).
  -- Server WILL refuse to boot if missing or invalid (defensive_abort).
  ATM_HMAC_SECRET = {
    name     = 'sonar_bank_atm_hmac_secret',
    default  = '',                -- empty default = abort at boot (intentional dev signal)
    required = true,
    min_len  = 64,
    pattern  = '^[%x]+$',          -- hex only (lowercase or upper)
  },

  -- M007 — Watchdog metric C threshold (compromise ratio for COMPROMISED action)
  WATCHDOG_COMPROMISE_RATIO_THRESHOLD = {
    name     = 'sonar_bank_watchdog_compromise_ratio_threshold',
    default  = '0.1',
    required = false,
    parse    = tonumber,
  },

  -- M007 — Watchdog minimum sample size (below threshold → INSUFFICIENT_SAMPLE skip)
  WATCHDOG_MIN_SAMPLE_SIZE = {
    name     = 'sonar_bank_watchdog_min_sample_size',
    default  = '10',
    required = false,
    parse    = tonumber,
  },

  -- H002 — Bridges.BankStatus.Transition whitelist (CSV de allowed source identifiers)
  STATUS_TRANSITION_WHITELIST = {
    name     = 'sonar_status_transition_whitelist',
    default  = 'sonar_bank,sonar_bank_app,sonar_core',
    required = false,
  },

  -- M003 — Audit query rate-limits (C035 dual rate-limit recursive guard)
  AUDIT_QUERY_PER_CITIZEN_PER_MIN = {
    name     = 'sonar_bank_audit_query_per_citizen_per_min',
    default  = '1',
    required = false,
    parse    = tonumber,
  },

  AUDIT_QUERY_GLOBAL_PER_MIN = {
    name     = 'sonar_bank_audit_query_global_per_min',
    default  = '10',
    required = false,
    parse    = tonumber,
  },

  -- M001 — Rate-limit reset grace seconds (legacy convar accepted Phase A)
  RATE_LIMIT_RESET_GRACE_SECONDS = {
    name     = 'sv_maxRateLimitResetGraceSeconds',
    default  = '300',
    required = false,
    parse    = tonumber,
  },

  -- Dev mode (gates strict AP-SQL-1 abort, verbose audit logging, smoke tests)
  DEV_MODE = {
    name     = 'sonar_dev_mode',
    default  = '0',
    required = false,
    parse    = function(v) return v == '1' or v == 'true' end,
  },
}

-- -----------------------------------------------------------------------------
-- §3. Performance budgets per tier (milliseconds threshold p50/p95/p99)
--
--   Used by lib/perf.lua para alerting + bootstrap REQ-FE-001 guarantee.
--   Alert triggered si observed p99 > budget × C.PerfBudgets.ALERT_MULTIPLIER.
-- -----------------------------------------------------------------------------
C.PerfBudgets = {
  -- Tier 1: read-heavy (fastest)
  TIER_1_READ_P99_MS    = 120,
  TIER_1_READ_P95_MS    = 80,
  TIER_1_READ_P50_MS    = 30,

  -- Tier 2: write (transactions, FSM transitions, side effects)
  TIER_2_WRITE_P99_MS   = 250,
  TIER_2_WRITE_P95_MS   = 150,
  TIER_2_WRITE_P50_MS   = 80,

  -- Tier 3: admin (audit queries, govt actions)
  TIER_3_ADMIN_P99_MS   = 500,
  TIER_3_ADMIN_P95_MS   = 300,
  TIER_3_ADMIN_P50_MS   = 150,

  -- Special: REQ-FE-001 bootstrap snapshot (Frontend mandate)
  BOOTSTRAP_P99_MS      = 80,
  BOOTSTRAP_P95_MS      = 60,
  BOOTSTRAP_P50_MS      = 30,

  -- Special: REQ-FE-002 recent recipients (cacheable)
  RECENT_RECIPIENTS_P99_MS = 60,
  RECENT_RECIPIENTS_P95_MS = 40,
  RECENT_RECIPIENTS_P50_MS = 15,

  -- Alert multiplier (p99 × this = alert level → emit sonar:metrics:perf_alert)
  ALERT_MULTIPLIER         = 1.5,

  -- Histogram retention (rolling window — older samples dropped)
  HISTOGRAM_WINDOW_SAMPLES = 1000,
}

-- -----------------------------------------------------------------------------
-- §4. Rate-limit token bucket configs (per tier)
--
--   Enforced by lib/rate_limit.lua. Per-player buckets refill linearly.
--   M003 special: C035 audit query has dual rate-limit (per-citizen + global).
-- -----------------------------------------------------------------------------
C.RateLimits = {
  TIER_1_READ = {
    capacity        = 10,
    refill_per_min  = 10,
  },
  TIER_2_WRITE = {
    capacity        = 5,
    refill_per_min  = 5,
  },
  TIER_3_ADMIN = {
    capacity        = 3,
    refill_per_min  = 3,
  },

  -- M003 special: C035 audit query dual rate-limit
  AUDIT_QUERY = {
    per_citizen_per_min  = 1,    -- overridable via convar AUDIT_QUERY_PER_CITIZEN_PER_MIN
    global_per_min       = 10,   -- overridable via convar AUDIT_QUERY_GLOBAL_PER_MIN
    bypass_self_single   = true, -- scope=self AND limit=1 bypass (recursive guard)
  },

  -- Default bucket for unclassified callbacks (defensive)
  DEFAULT = {
    capacity        = 5,
    refill_per_min  = 5,
  },
}

-- -----------------------------------------------------------------------------
-- §5. Idempotency key TTL config (M005 orphan TTL purge)
-- -----------------------------------------------------------------------------
C.Idempotency = {
  DEFAULT_TTL_SECONDS    = 86400,           -- 24h baseline
  IN_FLIGHT_GRACE_MS     = 30000,           -- 30s grace before marking orphan
  ORPHAN_PURGE_AGE_MIN   = 30,              -- purge orphans > 30min old
  CACHE_LRU_SIZE         = 1000,            -- in-memory LRU entries
  CRON_PURGE_INTERVAL_MS = 5 * 60 * 1000,   -- 5min sweep (M005)
}

-- -----------------------------------------------------------------------------
-- §6. Audit ledger config (C-SEC-01 §1.2 — append-only batched writes)
-- -----------------------------------------------------------------------------
C.Audit = {
  BATCH_FLUSH_INTERVAL_MS = 1000,   -- flush queue every 1s
  BATCH_MAX_SIZE          = 100,    -- flush early at 100 entries
  WRITE_TIMEOUT_MS        = 5000,   -- DB insert timeout per batch
  QUEUE_OVERFLOW_LIMIT    = 10000,  -- max queue size before drop+alert
}

-- -----------------------------------------------------------------------------
-- §7. Cache TTLs (in-memory LRU caches for bootstrap snapshot REQ-FE-001)
-- -----------------------------------------------------------------------------
C.Cache = {
  STATUS_BRIDGES_TTL_MS    = 600 * 1000,  -- 10min (rare-changing — boot only)
  MEMBERSHIPS_TTL_MS       = 300 * 1000,  -- 5min
  COMPLIANCE_TTL_MS        = 60 * 1000,   -- 1min
  RECENT_RECIPIENTS_TTL_MS = 60 * 1000,   -- 1min (REQ-FE-002)
  SESSION_META_TTL_MS      = 30 * 1000,   -- 30s

  LRU_DEFAULT_SIZE         = 256,
}

-- -----------------------------------------------------------------------------
-- §8. Bootstrap snapshot config (REQ-FE-001 mandate p99 < 80ms)
-- -----------------------------------------------------------------------------
C.Bootstrap = {
  PARALLEL_QUERY_TIMEOUT_MS = 60,  -- per-query timeout (must finish under p99=80ms total)
  TOTAL_TIMEOUT_MS          = 80,  -- aborts if total > this
  MAX_ACCOUNTS              = 32,
  MAX_PORTFOLIO_HOLDINGS    = 64,
  MAX_LOANS                 = 16,
  MAX_RECURRING             = 32,
  MAX_OUTSTANDING_AUDITS    = 16,
}

-- -----------------------------------------------------------------------------
-- §9. Recent recipients config (REQ-FE-002 — Transfer Express Mode)
-- -----------------------------------------------------------------------------
C.RecentRecipients = {
  WINDOW_DAYS               = 30,
  LIMIT                     = 8,
  PRESET_AMOUNTS            = 3,    -- top-N preset amounts per recipient
  MIN_TRANSFERS_FOR_PRESETS = 3,
}

-- -----------------------------------------------------------------------------
-- §10. DB query helpers (defaults — overridable per-call)
-- -----------------------------------------------------------------------------
C.DB = {
  DEFAULT_TIMEOUT_MS        = 3000,
  TRANSACTION_RETRY_MAX     = 3,
  TRANSACTION_RETRY_BASE_MS = 50,   -- exponential backoff: 50, 100, 200

  -- AP-SQL-1 enforcement (H004 — runtime detection of string concat in SQL)
  AP_SQL_1_DETECT_PATTERN   = '%.%.%s*[%w_]+',  -- detects "..var" patterns
  AP_SQL_1_STRICT_DEV       = true, -- abort in dev_mode, warn-only in prod
}

-- -----------------------------------------------------------------------------
-- §11. Logging
-- -----------------------------------------------------------------------------
C.Logging = {
  LEVEL  = 'INFO',                  -- DEBUG | INFO | WARN | ERROR
  PREFIX = '[sonar_bank_app]',
}

-- -----------------------------------------------------------------------------
-- §12. Feature flags (gradual rollout per founder discretion)
-- -----------------------------------------------------------------------------
C.Features = {
  ENABLE_BOOTSTRAP_CACHE_LRU      = true,
  ENABLE_RECENT_RECIPIENTS_CACHE  = true,
  ENABLE_AUDIT_BATCHED_WRITES     = true,
  ENABLE_PERF_ALERTS              = true,
  ENABLE_AP_SQL_1_RUNTIME_DETECT  = true,  -- H004 runtime guard
  ENABLE_AP_AUTH_1_RUNTIME_DETECT = true,  -- H001 runtime guard
  ENABLE_AP_UUID_1_RUNTIME_DETECT = true,  -- M002 runtime guard
  ENABLE_AP_HMAC_1_RUNTIME_DETECT = true,  -- M006 runtime guard
  ENABLE_AP_CP1_1_RUNTIME_DETECT  = true,  -- M004 runtime guard
}

-- =============================================================================
-- END config.lua
-- =============================================================================
