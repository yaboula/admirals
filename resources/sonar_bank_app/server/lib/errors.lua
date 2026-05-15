-- =============================================================================
-- SONAR Bank App — lib/errors.lua
-- =============================================================================
-- Error codes registry per C-BE-02 §3 (~30 codes categorized).
--
-- Categorías:
--   AUTH        — autenticación / autorización (H001 + H002)
--   VALIDATION  — input shape / schema validation
--   BUSINESS    — business rules (insufficient funds, frozen, etc.)
--   IDEMPOTENCY — keys reused / expired / replay
--   RATE_LIMIT  — token bucket exceeded
--   COMPLIANCE  — KYC / fraud / govt
--   DB          — transaction / timeout / deadlock
--   BRIDGE      — sonar_bridges unavailable / timeout
--   SYSTEM      — internal / not implemented / maintenance
--   AUDIT       — audit shape incomplete (H006)
--
-- Cada error tiene:
--   code              — string identifier (UPPER_SNAKE)
--   category          — one of above
--   message           — voice-neutral user-facing message (ADR-012 §D3)
--   retryable         — client hint (true = transient, can retry)
--   audit_event_type  — optional audit ledger event_type al fallar (forensics)
--
-- Deps: lib/enums.lua (audit event types).
-- =============================================================================

BankApp.lib.errors = {}
local M = BankApp.lib.errors

local E = BankApp.lib.enums.AUDIT_EVENT_TYPE

-- -----------------------------------------------------------------------------
-- §1. Error registry
-- -----------------------------------------------------------------------------
M.REGISTRY = {
  -- AUTH (H001 + H002)
  AUTH_REQUIRED = {
    category = 'AUTH', code = 'AUTH_REQUIRED', retryable = false,
    message  = 'Authentication required.',
    audit_event_type = E.AUTH_DENIED,
  },
  AUTH_INSUFFICIENT = {
    category = 'AUTH', code = 'AUTH_INSUFFICIENT', retryable = false,
    message  = 'Insufficient authorization for this action.',
    audit_event_type = E.AUTH_DENIED,
  },
  AUTH_OWNER_MISMATCH = {
    category = 'AUTH', code = 'AUTH_OWNER_MISMATCH', retryable = false,
    message  = 'Account ownership verification failed.',
    audit_event_type = E.AUTH_DENIED,
  },
  AUTH_ACE_DENIED = {
    category = 'AUTH', code = 'AUTH_ACE_DENIED', retryable = false,
    message  = 'Administrative permission denied.',
    audit_event_type = E.AUTH_DENIED,
  },
  AUTH_BRIDGE_DENIED = {
    category = 'AUTH', code = 'AUTH_BRIDGE_DENIED', retryable = false,
    message  = 'Bridge transition not authorized.',
    audit_event_type = E.AUTH_BRIDGE_DENIED,
  },

  -- VALIDATION
  VALIDATION_FAILED = {
    category = 'VALIDATION', code = 'VALIDATION_FAILED', retryable = false,
    message  = 'Request validation failed.',
  },
  INVALID_AMOUNT = {
    category = 'VALIDATION', code = 'INVALID_AMOUNT', retryable = false,
    message  = 'Amount must be a positive integer in minor units.',
  },
  AMOUNT_OUT_OF_RANGE = {
    category = 'VALIDATION', code = 'AMOUNT_OUT_OF_RANGE', retryable = false,
    message  = 'Amount exceeds allowed bounds.',
  },
  INVALID_IBAN = {
    category = 'VALIDATION', code = 'INVALID_IBAN', retryable = false,
    message  = 'IBAN format or checksum invalid.',
  },
  INVALID_CITIZEN_ID = {
    category = 'VALIDATION', code = 'INVALID_CITIZEN_ID', retryable = false,
    message  = 'Citizen identifier format invalid.',
  },
  INVALID_UUID = {
    category = 'VALIDATION', code = 'INVALID_UUID', retryable = false,
    message  = 'UUID format invalid (expected v4 lowercase canonical).',
  },
  INVALID_ENUM = {
    category = 'VALIDATION', code = 'INVALID_ENUM', retryable = false,
    message  = 'Value does not match any allowed option.',
  },

  -- BUSINESS
  INSUFFICIENT_FUNDS = {
    category = 'BUSINESS', code = 'INSUFFICIENT_FUNDS', retryable = false,
    message  = 'Insufficient funds for requested operation.',
  },
  ACCOUNT_NOT_FOUND = {
    category = 'BUSINESS', code = 'ACCOUNT_NOT_FOUND', retryable = false,
    message  = 'Account not found.',
  },
  ACCOUNT_FROZEN = {
    category = 'BUSINESS', code = 'ACCOUNT_FROZEN', retryable = false,
    message  = 'Account is currently frozen.',
  },
  ACCOUNT_CLOSED = {
    category = 'BUSINESS', code = 'ACCOUNT_CLOSED', retryable = false,
    message  = 'Account has been closed.',
  },
  RECIPIENT_NOT_FOUND = {
    category = 'BUSINESS', code = 'RECIPIENT_NOT_FOUND', retryable = false,
    message  = 'Recipient account not found.',
  },
  AMOUNT_EXCEEDS_LIMIT = {
    category = 'BUSINESS', code = 'AMOUNT_EXCEEDS_LIMIT', retryable = false,
    message  = 'Amount exceeds tier limit.',
  },
  ESCROW_RELEASE_INVALID = {
    category = 'BUSINESS', code = 'ESCROW_RELEASE_INVALID', retryable = false,
    message  = 'Escrow release amount invalid (must be > 0 and ≤ held balance).',  -- H005
  },
  CARD_NOT_FOUND = {
    category = 'BUSINESS', code = 'CARD_NOT_FOUND', retryable = false,
    message  = 'Card not found.',
  },
  INVALID_LIMITS = {
    category = 'VALIDATION', code = 'INVALID_LIMITS', retryable = false,
    message  = 'Card limits invalid (monthly cannot be lower than daily).',
  },
  INVALID_DESIGN = {
    category = 'VALIDATION', code = 'INVALID_DESIGN', retryable = false,
    message  = 'Unknown card design.',
  },
  JOINT_SELF = {
    category = 'VALIDATION', code = 'JOINT_SELF', retryable = false,
    message  = 'Cannot add yourself as joint owner.',
  },
  JOINT_CITIZEN_NOT_FOUND = {
    category = 'BUSINESS', code = 'JOINT_CITIZEN_NOT_FOUND', retryable = false,
    message  = 'Citizen does not exist or is not registered.',
  },
  JOINT_LIMIT_EXCEEDED = {
    category = 'BUSINESS', code = 'JOINT_LIMIT_EXCEEDED', retryable = false,
    message  = 'Maximum joint owners reached for this account.',
  },
  JOINT_ALREADY_EXISTS = {
    category = 'BUSINESS', code = 'JOINT_ALREADY_EXISTS', retryable = false,
    message  = 'Citizen is already a joint owner of this account.',
  },

  -- IDEMPOTENCY
  IDEMPOTENCY_KEY_REUSED = {
    category = 'IDEMPOTENCY', code = 'IDEMPOTENCY_KEY_REUSED', retryable = false,
    message  = 'Idempotency key already used with different payload.',
  },
  IDEMPOTENCY_KEY_EXPIRED = {
    category = 'IDEMPOTENCY', code = 'IDEMPOTENCY_KEY_EXPIRED', retryable = true,
    message  = 'Idempotency key TTL expired.',
  },
  IDEMPOTENCY_REPLAY_RESULT = {
    category = 'IDEMPOTENCY', code = 'IDEMPOTENCY_REPLAY_RESULT', retryable = false,
    -- Not a true error — used to signal cached result replay (success path)
    message  = 'Returning cached idempotent result.',
  },
  IDEMPOTENCY_IN_FLIGHT = {
    category = 'IDEMPOTENCY', code = 'IDEMPOTENCY_IN_FLIGHT', retryable = true,
    message  = 'Operation in flight, retry after grace period.',
  },

  -- RATE_LIMIT
  RATE_LIMIT_EXCEEDED = {
    category = 'RATE_LIMIT', code = 'RATE_LIMIT_EXCEEDED', retryable = true,
    message  = 'Too many requests. Please wait before retrying.',
  },
  RATE_LIMIT_RESET_FAILED = {
    category = 'RATE_LIMIT', code = 'RATE_LIMIT_RESET_FAILED', retryable = true,
    message  = 'Rate limit reset failed; please retry shortly.',
  },

  -- COMPLIANCE
  KYC_REQUIRED = {
    category = 'COMPLIANCE', code = 'KYC_REQUIRED', retryable = false,
    message  = 'KYC verification required for this operation.',
  },
  KYC_PENDING = {
    category = 'COMPLIANCE', code = 'KYC_PENDING', retryable = true,
    message  = 'KYC verification pending review.',
  },
  KYC_REJECTED = {
    category = 'COMPLIANCE', code = 'KYC_REJECTED', retryable = false,
    message  = 'KYC verification was rejected.',
  },
  COMPLIANCE_FROZEN = {
    category = 'COMPLIANCE', code = 'COMPLIANCE_FROZEN', retryable = false,
    message  = 'Account frozen pending compliance review.',
  },

  -- DB
  DB_TRANSACTION_FAILED = {
    category = 'DB', code = 'DB_TRANSACTION_FAILED', retryable = true,
    message  = 'Transaction failed; please retry.',
  },
  DB_TIMEOUT = {
    category = 'DB', code = 'DB_TIMEOUT', retryable = true,
    message  = 'Database query timeout; please retry.',
  },
  DB_DEADLOCK = {
    category = 'DB', code = 'DB_DEADLOCK', retryable = true,
    message  = 'Database deadlock detected; retry will resolve.',
  },
  DB_AP_SQL_1_VIOLATION = {
    category = 'DB', code = 'DB_AP_SQL_1_VIOLATION', retryable = false,
    message  = 'Internal SQL safety violation (string concat in SQL prohibited).',  -- H004
  },

  -- BRIDGE
  BRIDGE_UNAVAILABLE = {
    category = 'BRIDGE', code = 'BRIDGE_UNAVAILABLE', retryable = true,
    message  = 'External bridge currently unavailable.',
  },
  BRIDGE_TIMEOUT = {
    category = 'BRIDGE', code = 'BRIDGE_TIMEOUT', retryable = true,
    message  = 'Bridge call timeout.',
  },

  -- SYSTEM
  INTERNAL_ERROR = {
    category = 'SYSTEM', code = 'INTERNAL_ERROR', retryable = true,
    message  = 'An internal error occurred.',
  },
  NOT_IMPLEMENTED = {
    category = 'SYSTEM', code = 'NOT_IMPLEMENTED', retryable = false,
    message  = 'Feature not yet implemented.',
  },
  MAINTENANCE_MODE = {
    category = 'SYSTEM', code = 'MAINTENANCE_MODE', retryable = true,
    message  = 'System in maintenance mode.',
  },
  HMAC_CONFIG_MISSING = {
    category = 'SYSTEM', code = 'HMAC_CONFIG_MISSING', retryable = false,
    message  = 'HMAC secret not configured (operation cannot be signed).',  -- M006
  },
  HMAC_VERIFICATION_FAILED = {
    category = 'SYSTEM', code = 'HMAC_VERIFICATION_FAILED', retryable = false,
    message  = 'HMAC signature verification failed.',  -- M006
  },

  -- AUDIT (H006)
  AUDIT_SHAPE_INCOMPLETE = {
    category = 'AUDIT', code = 'AUDIT_SHAPE_INCOMPLETE', retryable = false,
    message  = 'Audit entry missing mandatory fields (e.g. previous_flag_snapshot).',
  },
  AUDIT_QUEUE_OVERFLOW = {
    category = 'AUDIT', code = 'AUDIT_QUEUE_OVERFLOW', retryable = true,
    message  = 'Audit queue overflow; entry dropped.',
  },
}

-- -----------------------------------------------------------------------------
-- §2. Helpers
-- -----------------------------------------------------------------------------

--- New: build standardized error tuple { ok=false, code, category, message, retryable, details, audit_event_type }
---@param code string registry key (e.g. 'INSUFFICIENT_FUNDS')
---@param details table|nil contextual data (NEVER include secrets/PII unless redacted)
---@return table standardized_error
function M.New(code, details)
  local e = M.REGISTRY[code]
  if not e then
    -- Defensive fallback — unknown error code becomes INTERNAL_ERROR
    e = M.REGISTRY.INTERNAL_ERROR
    return {
      ok               = false,
      code             = 'INTERNAL_ERROR',
      category         = 'SYSTEM',
      message          = ('Unknown error code: %s'):format(tostring(code)),
      retryable        = true,
      details          = details,
      audit_event_type = nil,
    }
  end
  return {
    ok               = false,
    code             = e.code,
    category         = e.category,
    message          = e.message,
    retryable        = e.retryable,
    details          = details,
    audit_event_type = e.audit_event_type,
  }
end

--- Ok: build standardized success tuple { ok=true, data }
---@param data any payload to return
---@return table
function M.Ok(data)
  return { ok = true, data = data }
end

--- IsRetryable: client hint helper
---@param err table standardized error tuple
---@return boolean
function M.IsRetryable(err)
  return type(err) == 'table' and err.retryable == true
end

--- IsAuthError: category check
---@param err table
---@return boolean
function M.IsAuthError(err)
  return type(err) == 'table' and err.category == 'AUTH'
end

--- ToString: human readable for logging
---@param err table
---@return string
function M.ToString(err)
  if type(err) ~= 'table' then return tostring(err) end
  if err.ok then return ('OK<%s>'):format(type(err.data)) end
  return ('ERR<%s/%s: %s>'):format(err.category or '?', err.code or '?', err.message or '?')
end

--- Wrap: convert raw lua error string into standardized error
---@param raw_err string|table
---@param fallback_code string|nil default 'INTERNAL_ERROR'
---@return table
function M.Wrap(raw_err, fallback_code)
  if type(raw_err) == 'table' and raw_err.code and raw_err.category then
    return raw_err  -- already standardized
  end
  local err = M.New(fallback_code or 'INTERNAL_ERROR', { raw = tostring(raw_err) })
  return err
end

return M
