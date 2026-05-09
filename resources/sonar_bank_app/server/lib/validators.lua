-- =============================================================================
-- SONAR Bank App — lib/validators.lua
-- =============================================================================
-- Input sanitization + shape validation (defense-in-depth before DB / business).
--
--   §1  Primitive validators (string, integer, positive, range)
--   §2  Domain validators (citizen_id, IBAN, UUID, amount minor units)
--   §3  String sanitization (control char strip, max length)
--   §4  Composite validators (payload schema check)
--
-- Deps: lib/errors.lua.
-- Sin DB deps. Pure functions.
-- =============================================================================

BankApp.lib.validators = {}
local M = BankApp.lib.validators

local Errors = BankApp.lib.errors

-- -----------------------------------------------------------------------------
-- §1. Primitive validators
-- -----------------------------------------------------------------------------

--- IsNonEmptyString: type==string AND #s > 0.
---@param v any
---@return boolean
function M.IsNonEmptyString(v)
  return type(v) == 'string' and #v > 0
end

--- IsInteger: math.type(v) == 'integer' OR (number AND not has-fraction).
--- Lua 5.4 integer-aware.
---@param v any
---@return boolean
function M.IsInteger(v)
  if type(v) ~= 'number' then return false end
  return math.type(v) == 'integer' or (v == math.floor(v) and v >= -9007199254740992 and v <= 9007199254740992)
end

--- IsPositiveInteger: integer AND > 0.
---@param v any
---@return boolean
function M.IsPositiveInteger(v)
  return M.IsInteger(v) and v > 0
end

--- IsNonNegativeInteger: integer AND >= 0.
---@param v any
---@return boolean
function M.IsNonNegativeInteger(v)
  return M.IsInteger(v) and v >= 0
end

--- IsInRange: integer AND lo <= v <= hi.
---@param v any
---@param lo integer
---@param hi integer
---@return boolean
function M.IsInRange(v, lo, hi)
  return M.IsInteger(v) and v >= lo and v <= hi
end

--- IsBoolean: type==boolean.
---@param v any
---@return boolean
function M.IsBoolean(v)
  return type(v) == 'boolean'
end

--- IsTable: type==table (does not check shape).
---@param v any
---@return boolean
function M.IsTable(v)
  return type(v) == 'table'
end

-- -----------------------------------------------------------------------------
-- §2. Domain validators
-- -----------------------------------------------------------------------------

-- citizen_id: 1-32 chars, [A-Za-z0-9_-]. Permissive enough for QBox/QBCore/ESX
-- (e.g. "QBX12345", "char1:abc-def", "esx_1234abcd").
local CITIZEN_ID_PATTERN = '^[%w_%-:]+$'
local CITIZEN_ID_MIN_LEN = 1
local CITIZEN_ID_MAX_LEN = 64  -- generous upper bound (real-world IDs ≤ 32)

--- IsValidCitizenId: format check.
---@param v any
---@return boolean
function M.IsValidCitizenId(v)
  if type(v) ~= 'string' then return false end
  if #v < CITIZEN_ID_MIN_LEN or #v > CITIZEN_ID_MAX_LEN then return false end
  return v:match(CITIZEN_ID_PATTERN) ~= nil
end

-- IBAN: country code (2 letters) + check digits (2) + BBAN (variable, max 30).
-- For SONAR generated IBANs (per sonar_bank/iban.lua) the full length is fixed.
-- Total length 15-34 chars. Format alphanumeric uppercase + spaces stripped.
local IBAN_PATTERN = '^%u%u%d%d[%u%d]+$'
local SONAR_IBAN_PATTERN = '^%u%u%-[%u%d][%u%d][%u%d][%u%d]%-[%u%d][%u%d][%u%d][%u%d]%-[%u%d][%u%d][%u%d][%u%d]$'
local IBAN_MIN_LEN = 15
local IBAN_MAX_LEN = 34

--- IsValidIBANFormat: format-only check (does NOT verify checksum mod-97).
--- For full validation use sonar_bank IBAN.Validate (requires sonar_bank loaded).
---@param v any
---@return boolean
function M.IsValidIBANFormat(v)
  if type(v) ~= 'string' then return false end
  -- Strip spaces (some users paste "ES12 1234 ...")
  local clean = v:gsub('%s', ''):upper()
  if #clean < IBAN_MIN_LEN or #clean > IBAN_MAX_LEN then return false end
  return clean:match(IBAN_PATTERN) ~= nil or clean:match(SONAR_IBAN_PATTERN) ~= nil
end

--- NormalizeIBAN: strip spaces + uppercase. Returns nil if invalid format.
---@param v any
---@return string|nil
function M.NormalizeIBAN(v)
  if type(v) ~= 'string' then return nil end
  local clean = v:gsub('%s', ''):upper()
  if M.IsValidIBANFormat(clean) then return clean end
  return nil
end

-- UUID v4 canonical: 8-4-4-4-12 hex lowercase, version digit = 4, variant = 8/9/a/b.
local UUID_V4_PATTERN = '^[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]%-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]%-4[0-9a-f][0-9a-f][0-9a-f]%-[89ab][0-9a-f][0-9a-f][0-9a-f]%-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]$'

--- IsValidUUID: strict v4 canonical format (matches M008 anchored regex).
---@param v any
---@return boolean
function M.IsValidUUID(v)
  if type(v) ~= 'string' then return false end
  return v:match(UUID_V4_PATTERN) ~= nil
end

-- Amount in minor units (cents). Bounds:
--   min: 1 cent (positive only — zero amounts not allowed in transfers)
--   max: 1 trillion cents = €10,000,000,000.00 (defensive upper bound)
local AMOUNT_MIN = 1
local AMOUNT_MAX = 1000000000000  -- 1e12 cents

--- IsValidAmountMinor: positive integer in defensive bounds.
---@param v any
---@return boolean
function M.IsValidAmountMinor(v)
  return M.IsInRange(v, AMOUNT_MIN, AMOUNT_MAX)
end

-- Idempotency key: 16-128 chars, alphanumeric + hyphen + underscore.
-- Permissive enough for UUID v4 (36 chars) + custom client schemes.
local IDEMPOTENCY_KEY_PATTERN = '^[%w_%-]+$'
local IDEMPOTENCY_KEY_MIN = 16
local IDEMPOTENCY_KEY_MAX = 128

--- IsValidIdempotencyKey: format check.
---@param v any
---@return boolean
function M.IsValidIdempotencyKey(v)
  if type(v) ~= 'string' then return false end
  if #v < IDEMPOTENCY_KEY_MIN or #v > IDEMPOTENCY_KEY_MAX then return false end
  return v:match(IDEMPOTENCY_KEY_PATTERN) ~= nil
end

-- -----------------------------------------------------------------------------
-- §3. String sanitization
-- -----------------------------------------------------------------------------

--- SanitizeString: strip control chars (< 0x20 except \t) + truncate to max_len.
--- Returns sanitized string OR nil if input invalid.
---@param v any
---@param max_len integer maximum output length (chars)
---@return string|nil
function M.SanitizeString(v, max_len)
  if type(v) ~= 'string' then return nil end
  if type(max_len) ~= 'number' or max_len < 1 then max_len = 256 end
  -- Strip control chars except tab (0x09), LF (0x0A), CR (0x0D)
  -- Then truncate. Note: this is byte-level (Lua strings are byte arrays),
  -- so multi-byte UTF-8 chars are preserved as long as max_len ≥ bytes.
  local clean = v:gsub('[%c]', function(c)
    local b = string.byte(c)
    if b == 0x09 or b == 0x0A or b == 0x0D then return c end
    return ''
  end)
  if #clean > max_len then
    clean = clean:sub(1, max_len)
  end
  return clean
end

--- SanitizeReason: business-reason field (transfer reason, audit reason).
--- Max 500 bytes, control chars stripped.
---@param v any
---@return string|nil
function M.SanitizeReason(v)
  return M.SanitizeString(v, 500)
end

-- -----------------------------------------------------------------------------
-- §4. Composite validators (payload schema check)
-- -----------------------------------------------------------------------------

--- ValidateSchema: lightweight shape check.
---   schema example:
---     { from_iban = 'iban', amount_minor = 'amount', reason = { type='string', max=500 } }
--- Returns ok, err
---@param payload table
---@param schema table
---@return boolean ok
---@return table|nil err standardized error tuple if not ok
function M.ValidateSchema(payload, schema)
  if type(payload) ~= 'table' then
    return false, Errors.New('VALIDATION_FAILED', { reason = 'payload not a table' })
  end
  if type(schema) ~= 'table' then
    return false, Errors.New('VALIDATION_FAILED', { reason = 'schema not a table (internal)' })
  end

  for field, spec in pairs(schema) do
    local value = payload[field]
    local kind = type(spec) == 'string' and spec or (type(spec) == 'table' and spec.type)

    if kind == 'string' then
      local max = type(spec) == 'table' and spec.max or 256
      if not M.IsNonEmptyString(value) then
        return false, Errors.New('VALIDATION_FAILED', { field = field, expected = 'string' })
      end
      if #value > max then
        return false, Errors.New('VALIDATION_FAILED', { field = field, reason = 'too long', max = max })
      end
    elseif kind == 'integer' then
      if not M.IsInteger(value) then
        return false, Errors.New('VALIDATION_FAILED', { field = field, expected = 'integer' })
      end
    elseif kind == 'positive_integer' then
      if not M.IsPositiveInteger(value) then
        return false, Errors.New('VALIDATION_FAILED', { field = field, expected = 'positive_integer' })
      end
    elseif kind == 'amount' then
      if not M.IsValidAmountMinor(value) then
        return false, Errors.New('INVALID_AMOUNT', { field = field })
      end
    elseif kind == 'iban' then
      if not M.IsValidIBANFormat(value) then
        return false, Errors.New('INVALID_IBAN', { field = field })
      end
    elseif kind == 'citizen_id' then
      if not M.IsValidCitizenId(value) then
        return false, Errors.New('INVALID_CITIZEN_ID', { field = field })
      end
    elseif kind == 'uuid' then
      if not M.IsValidUUID(value) then
        return false, Errors.New('INVALID_UUID', { field = field })
      end
    elseif kind == 'idempotency_key' then
      if not M.IsValidIdempotencyKey(value) then
        return false, Errors.New('VALIDATION_FAILED', { field = field, expected = 'idempotency_key' })
      end
    elseif kind == 'boolean' then
      if not M.IsBoolean(value) then
        return false, Errors.New('VALIDATION_FAILED', { field = field, expected = 'boolean' })
      end
    elseif kind == 'table' then
      if not M.IsTable(value) then
        return false, Errors.New('VALIDATION_FAILED', { field = field, expected = 'table' })
      end
    elseif kind == 'optional' then
      -- nil is ok, no further validation
    else
      return false, Errors.New('INTERNAL_ERROR', { reason = 'unknown schema kind', field = field, kind = tostring(kind) })
    end
  end

  return true, nil
end

return M
