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
-- §3. Deployment surface config (commands, items, ACE, client events)
-- -----------------------------------------------------------------------------
C.Deployment = {
  TARGET_FRAMEWORK = 'qbcore',
  REQUIRED_RESOURCES = { 'oxmysql', 'sonar_core', 'sonar_bridges', 'sonar_bank' },
}

C.Permissions = {
  PLAYER_ACE          = 'sonar.bank.player',
  ADMIN_ACE           = 'sonar.bank.admin',
  BUSINESS_READ_ACE   = 'sonar.bank.business.read',
  GOVT_READ_ACE       = 'sonar.bank.govt.audit.full',
  GOVT_COMPLIANCE_ACE = 'sonar.bank.govt.compliance.admin',
  GOVT_LOAN_ACE       = 'sonar.bank.govt.loan.admin',
  GOVT_TAX_ACE        = 'sonar.bank.govt.tax.write',
  BUSINESS_AUDIT_PREFIX    = 'sonar.bank.empresas.',
  BUSINESS_PAYROLL_PREFIX  = 'sonar.bank.business.payroll.',
  BUSINESS_APPROVAL_PREFIX = 'sonar.bank.business.approval.',
}

C.Commands = {
  OPEN_BANK = {
    name        = 'bank',
    description = 'Open SONAR Bank',
    key_mapping = {
      mapper      = 'keyboard',
      default_key = 'F6',
    },
  },
  OPEN_ADMIN = {
    name        = 'bankadmin',
    description = 'Open SONAR Bank Admin Dashboard',
    key_mapping = {
      mapper      = 'keyboard',
      default_key = 'F7',
    },
  },
  OPEN_BANKER = {
    name        = 'bankerpanel',
    description = 'Open SONAR Bank Owner Panel (RP staff only)',
    key_mapping = {
      mapper      = 'keyboard',
      default_key = 'F8',
    },
  },
}

C.Items = {
  BANK_CARD       = 'sonar_bank_card',
  ATM_ACCESS_CARD = 'sonar_bank_atm_card',
}

C.FrameworkJobs = {
  QBCORE_JOB_ACE_BINDINGS = {
    GOVT_READ = {
      ace = C.Permissions.GOVT_READ_ACE,
      jobs = {},
    },
    GOVT_COMPLIANCE = {
      ace = C.Permissions.GOVT_COMPLIANCE_ACE,
      jobs = {},
    },
    GOVT_TAX = {
      ace = C.Permissions.GOVT_TAX_ACE,
      jobs = {},
    },
  },
}

C.ClientEvents = {
  OPEN_UI   = 'sonar:bank:client:open',
  CLOSE_UI  = 'sonar:bank:client:close',
  TOGGLE_UI = 'sonar:bank:client:toggle',
  -- F06 — physical ATM interaction. Fired by the target/proximity layer
  -- (`client/atm_interaction.lua`) when the player chooses "Use ATM" on a
  -- world prop. Payload: { entity_net_id?, model_hash?, coords? }.
  OPEN_ATM  = 'sonar:bank:client:open_atm',
}

-- -----------------------------------------------------------------------------
-- §3b. Physical ATM interaction (F06)
--
--   Multi-target abstraction: the client side auto-detects the running target
--   resource. Order: ox_target → qb-target → qtarget → fallback (proximity +
--   ox_lib showTextUI '[E] Use ATM').
--
--   prop_hashes lifted from qb-banking standard; covers all stock GTA ATM
--   variants (rural, Fleeca, branded). Add custom prop hashes here per server.
-- -----------------------------------------------------------------------------
C.Atm = {
  -- Master switch — when false, the physical layer registers nothing and the
  -- /atm route can only be reached via the in-app shortcut (or NUI dev URL).
  EnableInteraction = true,

  -- Prop list (model name strings; hashed at runtime via GetHashKey).
  PropModels = {
    'prop_atm_01',
    'prop_atm_02',
    'prop_atm_03',
    'prop_fleeca_atm',
  },

  -- Target system preference order. The first one available is used.
  -- Possible values: 'ox_target', 'qb-target', 'qtarget', 'fallback'.
  TargetPreferenceOrder = { 'ox_target', 'qb-target', 'qtarget', 'fallback' },

  -- Interaction prompt label / icon (target menus only — fallback uses ox_lib).
  Label = 'Use ATM',
  Icon  = 'fa-solid fa-credit-card',

  -- Fallback proximity settings (only used when no target system is detected).
  Fallback = {
    detection_radius = 1.6,    -- meters; player must be within this to see prompt
    polling_ms       = 500,    -- prop scan interval (cheaper when no ATM nearby)
    polling_ms_close = 16,     -- 60fps keypress interval when prop is nearby
    open_key         = 38,     -- E key (control id, see GTA controls reference)
    text_ui          = '[E] Use ATM',
  },

  -- Map blips for visibility (set Enabled=false to hide all ATM blips).
  Blips = {
    Enabled = true,
    sprite  = 277,           -- ATM blip sprite
    color   = 2,              -- green
    scale   = 0.7,
    label   = 'ATM',
    short_range = true,       -- hide when not close to keep map clean
  },
}

C.RiskScore = {
  FORMULA_VERSION = 'govt-risk-mvp-v1',
  HIGH_SINGLE_OUTGOING_MINOR = 50000,
  MEDIUM_WINDOW_COUNT = 3,
  MEDIUM_WINDOW_SECONDS = 300,
  DAILY_WINDOW_SECONDS = 86400,
  MATERIALIZED_TTL_SECONDS = 300,
  LEVELS = {
    MEDIUM = 25,
    HIGH = 55,
    CRITICAL = 80,
  },
}

-- -----------------------------------------------------------------------------
-- §4. Performance budgets per tier (milliseconds threshold p50/p95/p99)
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
-- §5. Rate-limit token bucket configs (per tier)
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
-- §6. Idempotency key TTL config (M005 orphan TTL purge)
-- -----------------------------------------------------------------------------
C.Idempotency = {
  DEFAULT_TTL_SECONDS    = 86400,           -- 24h baseline
  IN_FLIGHT_GRACE_MS     = 30000,           -- 30s grace before marking orphan
  ORPHAN_PURGE_AGE_MIN   = 30,              -- purge orphans > 30min old
  CACHE_LRU_SIZE         = 1000,            -- in-memory LRU entries
  CRON_PURGE_INTERVAL_MS = 5 * 60 * 1000,   -- 5min sweep (M005)
}

-- -----------------------------------------------------------------------------
-- §7. Audit ledger config (C-SEC-01 §1.2 — append-only batched writes)
-- -----------------------------------------------------------------------------
C.Audit = {
  BATCH_FLUSH_INTERVAL_MS = 1000,   -- flush queue every 1s
  BATCH_MAX_SIZE          = 100,    -- flush early at 100 entries
  WRITE_TIMEOUT_MS        = 5000,   -- DB insert timeout per batch
  QUEUE_OVERFLOW_LIMIT    = 10000,  -- max queue size before drop+alert
}

-- -----------------------------------------------------------------------------
-- §8. Cache TTLs (in-memory LRU caches for bootstrap snapshot REQ-FE-001)
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
-- §9. Bootstrap snapshot config (REQ-FE-001 mandate p99 < 80ms)
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
-- §10. Recent recipients config (REQ-FE-002 — Transfer Express Mode)
-- -----------------------------------------------------------------------------
C.RecentRecipients = {
  WINDOW_DAYS               = 30,
  LIMIT                     = 8,
  PRESET_AMOUNTS            = 3,    -- top-N preset amounts per recipient
  MIN_TRANSFERS_FOR_PRESETS = 3,
}

-- -----------------------------------------------------------------------------
-- §11. DB query helpers (defaults — overridable per-call)
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
-- §12. Logging
-- -----------------------------------------------------------------------------
C.Logging = {
  LEVEL  = 'INFO',                  -- DEBUG | INFO | WARN | ERROR
  PREFIX = '[sonar_bank_app]',
}

-- -----------------------------------------------------------------------------
-- §13. Feature flags (gradual rollout per founder discretion)
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

C.Accounts = {
  Professional = {
    RequireApproval = true,
    AutoApprove = false,
  },
}

-- ---------------------------------------------------------------------------
-- §13b. Card products catalog (formerly hard-coded in card_service.lua)
--
--   Each product declares its tier (debit/credit), default visual design,
--   spending limits (initial — overridable per-card by C035 setLimits),
--   issuance fee, and the whitelist of design IDs available to that tier.
--
--   The banker panel can OVERRIDE `issue_fee_minor` per-product via the
--   global `card_issue_fee_minor` band in C.Banker.Limits — that override
--   is added on top of the product fee at issuance time (Phase 2 wiring).
-- ---------------------------------------------------------------------------
C.Cards = {
  -- Products catalog (id → spec).
  Products = {
    classic = {
      label              = 'SONAR Classic',
      description        = 'Debit card with everyday spending limits',
      card_kind          = 'debit',
      default_design_id  = 'noir',
      daily_limit_minor  = 200000,    -- $2,000
      monthly_limit_minor = 2500000,  -- $25,000
      issue_fee_minor    = 2500,      -- $25
      designs            = { 'noir', 'sonar_signature' },
    },
    premium = {
      label              = 'SONAR Premium',
      description        = 'Credit card with extended limits and exclusive designs',
      card_kind          = 'credit',
      default_design_id  = 'sonar_signature',
      daily_limit_minor  = 1000000,   -- $10,000
      monthly_limit_minor = 10000000, -- $100,000
      issue_fee_minor    = 15000,     -- $150
      designs            = {
        'noir', 'sonar_signature', 'aurora', 'sunset',
        'titanium', 'deep_space', 'emerald_vault',
      },
    },
  },

  -- PIN validation policy
  PIN = {
    min_length = 4,
    max_length = 8,
    digits_only = true,
  },

  -- Per-citizen card cap (defensive)
  MAX_CARDS_PER_CITIZEN = 8,
}

-- ---------------------------------------------------------------------------
-- §13bb. Customer-facing app — branding + feature flags
--
--   This block is consumed by the bootstrap snapshot and exposed to the
--   web-app under `bootstrap.app.branding` and `bootstrap.app.features`.
--   The banker panel can override values via sonar_bank_config_overrides
--   (keys prefixed `branding_*`), but the customer app NEVER fails if the
--   banker is disabled — these defaults are always in effect.
-- ---------------------------------------------------------------------------
C.CustomerApp = {
  -- Visual identity — defaults shown when no banker override exists.
  Branding = {
    bank_name        = 'SONAR Bank',
    short_name       = 'SONAR',
    primary_color    = '#FF6413',
    accent_color     = '#FFB047',
    welcome_message  = 'Welcome to SONAR Bank — your money, your rules.',
    logo_url         = '',
    support_email    = 'support@sonar.bank',
    support_url      = '',
  },

  -- Feature flags — toggle entire modules without code changes.
  -- The bootstrap snapshot returns these so the FE can hide UI entries
  -- and the BE callbacks return FEATURE_DISABLED if hit anyway.
  Features = {
    accounts_open         = true,   -- C002 — allow opening new personal accounts
    accounts_close        = true,   -- C019 — allow closing accounts
    accounts_freeze_self  = true,   -- C015/C016 — self freeze/unfreeze
    accounts_joint_owners = true,   -- C020/C021 — add/remove joint owners
    savings               = true,   -- C007/C008 — savings deposits/withdrawals
    cards_issue           = true,   -- C032 — issue new cards
    cards_freeze          = true,   -- C033/C034
    cards_set_limits      = true,   -- C035
    cards_change_pin      = true,   -- C040
    transfers_p2p         = true,   -- C006
    transfers_express     = true,   -- 2-step Express Mode
    recurring             = true,   -- C014/C017/C018 — subscriptions
    loans                 = true,   -- C022/C024
    investments           = true,   -- portfolio buy/sell
    kyc                   = true,   -- C037
    business_treasury     = true,   -- REQ-FE-011
    notifications         = true,   -- F40
    onboarding_first_run  = true,   -- 3-step intro
  },

  -- Hard customer-side caps (UX-friendly guardrails). The banker bands
  -- in C.Banker.Limits define the dynamic policy; these are constants
  -- enforced at validation time regardless of overrides.
  Limits = {
    transfer_min_minor        = 1,            -- $0.01
    transfer_max_minor        = 999999999900, -- $9,999,999,999 (defensive ceiling)
    max_recipients_saved      = 50,
    max_recurring_per_account = 16,
    pin_attempts_max          = 5,
    pin_attempts_window_sec   = 300,
  },
}

-- ---------------------------------------------------------------------------
-- §13c. Cron schedules — periodic background tasks
--
--   All cron tasks are guarded by `enabled` and persist their `last_run_at`
--   via sonar_bank_config_overrides so a restart does not double-accrue.
-- ---------------------------------------------------------------------------
C.Cron = {
  -- Savings interest accrual (uses C.Banker.Limits.savings_interest_rate_bps
  -- as the annual rate; cron credits the prorated daily portion).
  SavingsInterest = {
    enabled            = true,
    period_seconds     = 24 * 3600,   -- 24h (recommended)
    accrual_basis_days = 365,         -- APR convention
    min_balance_minor  = 100,         -- skip accounts < $1 to avoid spam rows
    heartbeat_ms       = 5 * 60 * 1000, -- check every 5min whether to run
    last_run_key       = 'savings_interest_last_run_at',
    log_summary        = true,        -- one log line with totals per run
  },
}

-- ---------------------------------------------------------------------------
-- §14. Loan products & interest tiers (config-driven pricing)
--
--   Players select a product; server computes final rate from product base +
--   risk modifier. Interest rate is NEVER free-form player input.
-- ---------------------------------------------------------------------------
C.LoanProducts = {
  {
    id                = 'micro',
    name              = 'Micro Credit',
    min_principal     = 50000,   -- $500
    max_principal     = 500000, -- $5,000
    base_rate_bps     = 850,     -- 8.50% APR
    max_rate_bps      = 1200,    -- 12.00% APR (risk ceiling)
    max_term_days     = 180,
    collateral_required = false,
  },
  {
    id                = 'personal',
    name              = 'Personal Credit',
    min_principal     = 500000,  -- $5,000
    max_principal     = 5000000, -- $50,000
    base_rate_bps     = 650,     -- 6.50% APR
    max_rate_bps      = 950,     -- 9.50% APR
    max_term_days     = 360,
    collateral_required = false,
  },
  {
    id                = 'prime',
    name              = 'Prime Financing',
    min_principal     = 5000000,  -- $50,000
    max_principal     = 50000000, -- $500,000
    base_rate_bps     = 420,      -- 4.20% APR
    max_rate_bps      = 650,      -- 6.50% APR
    max_term_days     = 720,
    collateral_required = true,
  },
}

-- Risk modifiers (added to product base_rate_bps)
-- Computed by RiskEngine in services/loan_service.lua
C.LoanRiskModifiers = {
  grade_a = -50,  -- Excellent history / high balance → -0.50%
  grade_b = 0,    -- Average → no change
  grade_c = 100,  -- Below average / thin history → +1.00%
  grade_d = 300,  -- High risk / defaults → +3.00%
}

-- ---------------------------------------------------------------------------
-- §15. Loan validation hard limits (safety caps)
-- ---------------------------------------------------------------------------
C.LoanLimits = {
  MIN_PRINCIPAL_MINOR  = 50000,   -- $500
  MAX_PRINCIPAL_MINOR  = 50000000, -- $500,000
  MIN_TERM_DAYS        = 30,
  MAX_TERM_DAYS        = 720,
  MAX_RATE_BPS         = 1500,    -- 15.00% absolute ceiling
  MIN_RATE_BPS         = 100,     -- 1.00% absolute floor
}

-- =============================================================================
-- §16. Banker (Bank Owner Panel) — RP job + dual-stack independent config
-- =============================================================================
-- Architectural contract:
--   - config.lua defines DEFAULTS and HARD LIMITS (min/max bands).
--   - The banker (CEO) operates inside those bands via the panel.
--   - Anything mutated lives in DB table sonar_bank_config_overrides; reset
--     wipes the row and the system falls back to the default below.
--   - Server admins remain in control of the economy: a banker can never
--     push a value outside the [min, max] band declared here.
-- ============================================================================
C.Banker = {
  -- ----- Roles hierarchy (numeric weight; higher = more privileges) ---------
  Roles = {
    ceo                 = { weight = 100, label = 'CEO' },
    manager             = { weight = 80,  label = 'Manager' },
    compliance_officer  = { weight = 60,  label = 'Compliance Officer' },
    advisor             = { weight = 40,  label = 'Advisor' },
    teller              = { weight = 20,  label = 'Teller' },
  },

  -- Capability matrix (feature → minimum role weight required)
  Capabilities = {
    panel_open                = 20,  -- any active employee can open the panel
    employees_view            = 40,
    employees_hire            = 80,
    employees_fire            = 80,
    employees_set_role        = 100, -- only CEO can promote to CEO
    rates_view                = 40,
    rates_edit                = 80,
    branding_view             = 40,
    branding_edit             = 100,
    customers_view            = 40,
    customers_freeze          = 60,
    loans_approve             = 40,
    kyc_approve               = 60,
    pro_account_approve       = 40,
    fraud_review              = 60,
    audit_query               = 60,
    marketing_create          = 80,
    missions_dispatch         = 60,
    missions_accept           = 20,
  },

  -- ----- Initial CEO bootstrap ----------------------------------------------
  -- If the employees table is empty at boot, the citizen_id below is auto-
  -- promoted to CEO. The convar overrides the static value.
  InitialCEO = {
    citizen_id_default = '',  -- e.g. 'HMC53829'
    convar_name        = 'sonar_bank_initial_ceo',
  },

  -- ----- Mode: how the banker panel coexists with config-driven economy -----
  -- Always available (Hybrid: config = bands, banker = operations within).
  -- Set to false to fully disable the panel feature (panel + callbacks 410).
  Enabled = true,

  -- ----- Mutable parameter bands (rate / fee editor in F3) -------------------
  -- Every entry has shape: { default, min, max, step }. Servers tune the
  -- band; banker picks within. Values are basis points (bps) for rates and
  -- minor units for monetary amounts.
  Limits = {
    -- Savings interest rate (annual APR in basis points)
    savings_interest_rate_bps   = { default = 300,  min = 0,    max = 800,    step = 25 },

    -- Loan interest rate ceiling adjustment (ADDED to product base_rate_bps).
    -- Banker can raise/lower the spread within bands; per-product config
    -- enforces hard ceilings.
    loan_rate_spread_bps        = { default = 0,    min = -200, max = 300,    step = 25 },

    -- Transfer fee in basis points of amount (0.10% default = 10 bps)
    transfer_fee_bps            = { default = 10,   min = 0,    max = 200,    step = 5 },

    -- Flat ATM withdrawal fee in minor units (cents) — additive to bps
    atm_fee_minor_flat          = { default = 0,    min = 0,    max = 500,    step = 25 },

    -- Card issuance fee in minor units
    card_issue_fee_minor        = { default = 1500, min = 0,    max = 10000,  step = 100 },

    -- Daily transfer limit (per account) in minor units
    daily_transfer_limit_minor  = { default = 5000000, min = 100000, max = 100000000, step = 100000 },

    -- Required minimum balance for "shared" account class
    shared_account_min_minor    = { default = 0,       min = 0,    max = 1000000, step = 1000 },
  },

  -- ----- Branding (F4 — controlled by CEO/manager) ---------------------------
  Branding = {
    -- Defaults; overrides go to sonar_bank_config_overrides under
    -- 'branding_*' keys.
    bank_name_default       = 'SONAR Bank',
    primary_color_default   = '#FF6413',  -- SONAR signature orange
    accent_color_default    = '#FFB047',
    welcome_message_default = 'Welcome to SONAR Bank — your money, your rules.',
    logo_url_default        = '',
  },

  -- ----- Payroll (F4 — bank pays its employees from the bank's treasury) ---
  Payroll = {
    Enabled              = true,
    PeriodSeconds        = 7 * 86400,  -- weekly
    DefaultSalaryMinor = {
      ceo                = 500000,  -- $5,000 / week default
      manager            = 250000,
      compliance_officer = 200000,
      advisor            = 150000,
      teller             = 80000,
    },
    -- Hard caps prevent CEO self-pay abuse
    SalaryCapsMinor = {
      ceo                = 2000000, -- $20,000 / week max
      manager            = 1000000,
      compliance_officer = 800000,
      advisor            = 500000,
      teller             = 300000,
    },
  },

  -- ----- Missions (gameplay loop F6 — defaults, fully implemented in F6) ----
  Missions = {
    AtmRefill = {
      enabled               = true,
      base_reward_minor     = 5000,    -- $50 per refill
      threshold_pct         = 0.20,    -- auto-dispatch when ATM cash < 20%
      auto_dispatch_cron_ms = 5 * 60 * 1000,
    },
    CardProduction = {
      enabled              = true,
      base_reward_minor    = 2000,
      skillcheck_difficulty = 'medium',
    },
    VaultAudit = {
      enabled           = true,
      base_reward_minor = 8000,
      cooldown_seconds  = 3600,
    },
    LoanCollection = {
      enabled                  = true,
      base_reward_minor        = 10000,
      overdue_threshold_days   = 30,
    },
    CashTransportB2B = {
      enabled           = true,
      base_reward_minor = 6000,
    },
    DocumentDelivery = {
      enabled           = true,
      base_reward_minor = 1500,
    },
  },

  -- ----- Audit event types specific to banker operations -------------------
  -- These are added to lib/enums.lua AUDIT_EVENT_TYPE in F1.
  AuditEventTypes = {
    EMPLOYEE_HIRE        = 'banker_employee_hire',
    EMPLOYEE_FIRE        = 'banker_employee_fire',
    EMPLOYEE_SET_ROLE    = 'banker_employee_set_role',
    CONFIG_CHANGE        = 'banker_config_change',
    BRANDING_CHANGE      = 'banker_branding_change',
    MISSION_DISPATCH     = 'banker_mission_dispatch',
    MISSION_COMPLETE     = 'banker_mission_complete',
    MARKETING_CAMPAIGN   = 'banker_marketing_campaign',
  },

  -- ----- ACE for emergency override (server admin can promote any citizen) -
  ADMIN_ACE_OVERRIDE = 'sonar.bank.admin',
}

-- =============================================================================
-- END config.lua
-- =============================================================================
