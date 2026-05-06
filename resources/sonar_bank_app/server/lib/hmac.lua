-- =============================================================================
-- SONAR Bank App — lib/hmac.lua
-- =============================================================================
-- M006 — ATM HMAC convar enforcer + HMAC-SHA256 implementation.
--
-- Boot-time:
--   1. Read convar `sonar_bank_atm_hmac_secret`.
--   2. Assert #secret >= 64 AND secret matches `^[%x]+$` (hex only).
--   3. Si invalid → defensive_abort() (abort resource boot vía error()).
--
-- Runtime:
--   - hmac.SignPayload(payload_str) → 64-char hex signature
--   - hmac.VerifyPayload(payload_str, signature_hex) → boolean
--
-- AP-HMAC-1 prohibido: nunca usar custom MAC sin convar secret. Nunca aceptar
-- short secrets (< 64 hex chars = 256 bits). Nunca skip verification.
--
-- Implementation: pure-Lua SHA-256 + HMAC construction (RFC 2104). Lua 5.4
-- bitwise operators (`&`, `|`, `~`, `<<`, `>>`) + string.pack/unpack para
-- big-endian I/O. ~1ms per call (acceptable Phase A; FFI native crypto Phase B).
--
-- Deps: lib/errors.lua + lib/validators.lua.
-- =============================================================================

BankApp.lib.hmac = {}
local M = BankApp.lib.hmac

local Errors     = BankApp.lib.errors
local Validators = BankApp.lib.validators
local Config     = BankApp.Config

-- -----------------------------------------------------------------------------
-- §1. SHA-256 implementation (RFC 6234)
--
--   Reference: FIPS 180-4 § 6.2.
--   Optimized para Lua 5.4 con string.pack/unpack + bitwise ops nativos.
-- -----------------------------------------------------------------------------

-- Initial hash values (FIPS 180-4 §5.3.3 — first 32 bits of fractional parts
-- of square roots of first 8 primes 2..19).
local H0 = {
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
}

-- Round constants (FIPS 180-4 §4.2.2 — first 32 bits of fractional parts
-- of cube roots of first 64 primes 2..311).
local K = {
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

-- Right rotate within 32-bit word.
local function rotr(x, n)
  return ((x >> n) | (x << (32 - n))) & 0xffffffff
end

-- Process one 512-bit chunk (64 bytes), updating hash state.
local function sha256_block(state, chunk_bytes)
  local w = {}
  -- Big-endian unpack 16 × uint32
  for i = 0, 15 do
    w[i + 1] = string.unpack('>I4', chunk_bytes, i * 4 + 1)
  end
  -- Extend message schedule
  for i = 17, 64 do
    local s0 = rotr(w[i-15], 7) ~ rotr(w[i-15], 18) ~ (w[i-15] >> 3)
    local s1 = rotr(w[i-2], 17) ~ rotr(w[i-2], 19) ~ (w[i-2] >> 10)
    w[i] = (w[i-16] + s0 + w[i-7] + s1) & 0xffffffff
  end

  local a, b, c, d, e, f, g, h =
    state[1], state[2], state[3], state[4], state[5], state[6], state[7], state[8]

  for i = 1, 64 do
    local S1 = rotr(e, 6) ~ rotr(e, 11) ~ rotr(e, 25)
    local ch = (e & f) ~ ((~e) & g)
    local temp1 = (h + S1 + ch + K[i] + w[i]) & 0xffffffff
    local S0 = rotr(a, 2) ~ rotr(a, 13) ~ rotr(a, 22)
    local maj = (a & b) ~ (a & c) ~ (b & c)
    local temp2 = (S0 + maj) & 0xffffffff

    h = g
    g = f
    f = e
    e = (d + temp1) & 0xffffffff
    d = c
    c = b
    b = a
    a = (temp1 + temp2) & 0xffffffff
  end

  state[1] = (state[1] + a) & 0xffffffff
  state[2] = (state[2] + b) & 0xffffffff
  state[3] = (state[3] + c) & 0xffffffff
  state[4] = (state[4] + d) & 0xffffffff
  state[5] = (state[5] + e) & 0xffffffff
  state[6] = (state[6] + f) & 0xffffffff
  state[7] = (state[7] + g) & 0xffffffff
  state[8] = (state[8] + h) & 0xffffffff
end

--- sha256: compute SHA-256 digest of input bytes.
---@param data string raw bytes
---@return string 32-byte raw digest
local function sha256(data)
  if type(data) ~= 'string' then
    error('sha256: data must be string', 2)
  end

  local state = { table.unpack(H0) }

  -- Padding: append 0x80, then zeros until length ≡ 56 (mod 64), then 8-byte big-endian bit length
  local msg_len = #data
  local bit_len = msg_len * 8
  local padding = '\x80'
  local pad_zeros_count = (56 - (msg_len + 1) % 64) % 64
  padding = padding .. string.rep('\0', pad_zeros_count) .. string.pack('>I8', bit_len)
  local padded = data .. padding

  -- Process each 64-byte chunk
  for i = 1, #padded, 64 do
    sha256_block(state, padded:sub(i, i + 63))
  end

  -- Big-endian pack result
  return string.pack('>I4I4I4I4I4I4I4I4',
    state[1], state[2], state[3], state[4],
    state[5], state[6], state[7], state[8])
end

--- bytes_to_hex: 32 bytes → 64 lowercase hex chars.
local function bytes_to_hex(bytes)
  return (bytes:gsub('.', function(c) return string.format('%02x', string.byte(c)) end))
end

--- hex_to_bytes: 64 hex chars → 32 bytes. Returns nil if not valid hex.
local function hex_to_bytes(hex)
  if type(hex) ~= 'string' then return nil end
  if #hex % 2 ~= 0 then return nil end
  if not hex:match('^[%x]+$') then return nil end
  return (hex:gsub('..', function(cc) return string.char(tonumber(cc, 16)) end))
end

-- -----------------------------------------------------------------------------
-- §2. HMAC-SHA256 (RFC 2104)
--
--   HMAC(K, m) = H((K' XOR opad) || H((K' XOR ipad) || m))
--   where K' is K padded to block size (64 bytes for SHA-256), and ipad=0x36
--   repeated, opad=0x5c repeated.
-- -----------------------------------------------------------------------------

local BLOCK_SIZE = 64  -- SHA-256 block size in bytes
local IPAD = string.rep('\x36', BLOCK_SIZE)
local OPAD = string.rep('\x5c', BLOCK_SIZE)

local function xor_strings(a, b)
  local result = {}
  for i = 1, #a do
    result[i] = string.char(string.byte(a, i) ~ string.byte(b, i))
  end
  return table.concat(result)
end

--- hmac_sha256: compute HMAC-SHA256.
---@param key string raw bytes (will be hashed if > BLOCK_SIZE, padded if shorter)
---@param message string raw bytes
---@return string 32-byte raw HMAC
local function hmac_sha256(key, message)
  -- Normalize key length to BLOCK_SIZE bytes
  if #key > BLOCK_SIZE then
    key = sha256(key)
  end
  if #key < BLOCK_SIZE then
    key = key .. string.rep('\0', BLOCK_SIZE - #key)
  end

  local inner_key = xor_strings(key, IPAD)
  local outer_key = xor_strings(key, OPAD)

  local inner_hash = sha256(inner_key .. message)
  return sha256(outer_key .. inner_hash)
end

-- -----------------------------------------------------------------------------
-- §3. Convar enforcement (M006 — boot-time defensive_abort)
-- -----------------------------------------------------------------------------

local _secret_bytes = nil    -- raw bytes of secret (decoded from hex convar)
local _secret_loaded = false

--- LoadSecret: read convar + validate + decode hex → raw bytes. Called at boot.
---   Throws error() if convar missing or invalid (defensive_abort intent).
---@return boolean ok
---@return table|nil err
function M.LoadSecret()
  local convar_spec = Config.Convars.ATM_HMAC_SECRET
  local raw = GetConvar(convar_spec.name, convar_spec.default)

  if raw == nil or raw == '' then
    return false, Errors.New('HMAC_CONFIG_MISSING', {
      reason = 'convar not set',
      convar = convar_spec.name,
    })
  end

  if #raw < convar_spec.min_len then
    return false, Errors.New('HMAC_CONFIG_MISSING', {
      reason = 'secret too short',
      convar = convar_spec.name,
      required_min_len = convar_spec.min_len,
      got_len = #raw,
    })
  end

  if not raw:match(convar_spec.pattern) then
    return false, Errors.New('HMAC_CONFIG_MISSING', {
      reason = 'secret not hex',
      convar = convar_spec.name,
    })
  end

  local bytes = hex_to_bytes(raw)
  if not bytes then
    return false, Errors.New('HMAC_CONFIG_MISSING', {
      reason = 'hex decode failed',
      convar = convar_spec.name,
    })
  end

  _secret_bytes = bytes
  _secret_loaded = true
  return true, nil
end

--- IsLoaded: query state.
---@return boolean
function M.IsLoaded()
  return _secret_loaded
end

-- -----------------------------------------------------------------------------
-- §4. Public sign/verify API
-- -----------------------------------------------------------------------------

--- SignPayload: HMAC-SHA256 of payload with loaded secret. Returns 64-char hex.
---@param payload string
---@return string|nil signature_hex
---@return table|nil err
function M.SignPayload(payload)
  if not _secret_loaded then
    return nil, Errors.New('HMAC_CONFIG_MISSING', { reason = 'secret not loaded — call LoadSecret first' })
  end
  if type(payload) ~= 'string' then
    return nil, Errors.New('VALIDATION_FAILED', { reason = 'payload must be string' })
  end
  local mac = hmac_sha256(_secret_bytes, payload)
  return bytes_to_hex(mac), nil
end

--- VerifyPayload: constant-time compare of HMAC.
---@param payload string
---@param signature_hex string 64-char hex
---@return boolean ok
---@return table|nil err
function M.VerifyPayload(payload, signature_hex)
  if not _secret_loaded then
    return false, Errors.New('HMAC_CONFIG_MISSING', { reason = 'secret not loaded' })
  end
  if type(payload) ~= 'string' then
    return false, Errors.New('VALIDATION_FAILED', { reason = 'payload must be string' })
  end
  if type(signature_hex) ~= 'string' or #signature_hex ~= 64 or not signature_hex:match('^[%x]+$') then
    return false, Errors.New('HMAC_VERIFICATION_FAILED', { reason = 'signature format invalid' })
  end

  local expected = hmac_sha256(_secret_bytes, payload)
  local provided = hex_to_bytes(signature_hex:lower())

  if not provided or #provided ~= #expected then
    return false, Errors.New('HMAC_VERIFICATION_FAILED', { reason = 'length mismatch' })
  end

  -- Constant-time compare (avoid timing oracle)
  local diff = 0
  for i = 1, #expected do
    diff = diff | (string.byte(expected, i) ~ string.byte(provided, i))
  end

  if diff ~= 0 then
    return false, Errors.New('HMAC_VERIFICATION_FAILED', { reason = 'signature mismatch' })
  end
  return true, nil
end

-- -----------------------------------------------------------------------------
-- §5. Test vector helper (RFC 4231 Test Case 1)
--
--   key = 0x0b * 20 (20 bytes), data = "Hi There"
--   expected HMAC-SHA256:
--     b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7
-- -----------------------------------------------------------------------------

--- SelfTest: run RFC 4231 Test Case 1 to verify SHA-256 + HMAC implementation.
--- Useful para boot-time sanity check antes de enable C031 ATM withdraw.
---@return boolean ok
---@return string|nil err
function M.SelfTest()
  local key = string.rep('\x0b', 20)
  local data = 'Hi There'
  local expected = 'b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7'
  local mac = hmac_sha256(key, data)
  local got = bytes_to_hex(mac)
  if got == expected then
    return true, nil
  end
  return false, ('HMAC self-test failed: expected=%s got=%s'):format(expected, got)
end

-- Expose internal sha256 (read-only) para usar en otros lugares (ej audit
-- ledger checksum si necesitamos).
M.SHA256 = function(data) return bytes_to_hex(sha256(data)) end

return M
