-- =============================================================================
-- SONAR Bank App — lib/uuid.lua
-- =============================================================================
-- M002 — UUID v4 generator with multi-entropy PRNG mix per C-BE-04 §3.3.1.
--
-- Strategy:
--   1. Si Bridges.UUID.v4 está disponible (sonar_bridges loaded), DELEGAMOS.
--      Esto asegura que ALL UUID generation en el server pasa por la canonical
--      primitive en sonar_bridges (single source of truth).
--   2. Si Bridges.UUID.v4 NO disponible (boot order edge case, dev test),
--      fallback inline implementation con multi-entropy seed.
--
-- AP-UUID-1 prohibido: nunca usar `math.random()` solo, nunca usar
-- `os.time()` solo como seed, nunca formato non-canonical (must be v4 lowercase
-- 8-4-4-4-12 con version digit = 4 y variant = 8/9/a/b).
--
-- Deps: lib/errors.lua + lib/validators.lua.
-- =============================================================================

BankApp.lib.uuid = {}
local M = BankApp.lib.uuid

local Errors     = BankApp.lib.errors
local Validators = BankApp.lib.validators

-- -----------------------------------------------------------------------------
-- §1. Multi-entropy seeding (M002 §3.3.1)
-- -----------------------------------------------------------------------------

local _seed_initialized = false

--- entropy_mix: produce 64-bit-ish integer mixing multiple entropy sources.
---   sources: os.time() (sec), os.clock() (CPU time fractional), GetGameTimer()
---            (server uptime ms), math.random (seeded recursively), #GetPlayers()
---            (player count flux), debug.gethash of resource state (varies).
---@return integer
local function entropy_mix()
  local t_sec     = os.time()
  local t_clock   = os.clock() * 1e6           -- microseconds
  local t_game    = GetGameTimer()              -- ms since server start
  local n_players = #GetPlayers()
  local rand      = math.random(0, 0x7fffffff) -- prior random state
  -- mix via XOR + multiplications (cheap diffusion):
  local mix = (t_sec * 1000003)
            ~ (math.floor(t_clock) * 17)
            ~ (t_game * 31)
            ~ (n_players * 1000007)
            ~ rand
  -- ensure positive 53-bit (Lua double safe int range)
  mix = mix & 0x1fffffffffffff
  if mix < 0 then mix = -mix end
  return mix
end

--- ensure_seeded: re-seed math.random with multi-entropy on first call AND
--- periodically refresh state (every UUID generation re-seeds — defense vs
--- predictable PRNG sequences in long-running servers).
local function ensure_seeded()
  math.randomseed(entropy_mix())
  -- consume a few values to mix the internal state
  for _ = 1, 4 do math.random() end
  _seed_initialized = true
end

-- -----------------------------------------------------------------------------
-- §2. v4 generator (inline fallback)
-- -----------------------------------------------------------------------------

--- generate_inline: pure Lua v4 UUID with per-call re-seeding (M002 §3.3.1).
---@return string canonical 36-char v4 UUID lowercase
local function generate_inline()
  ensure_seeded()
  -- Layout: time_low(4) - time_mid(2) - time_hi_and_version(2, hi nibble=4)
  --         - clock_seq_and_reserved(2, top 2 bits=10) - node(6)
  -- All bytes random per v4 spec.
  return string.format(
    '%08x-%04x-4%03x-%01x%03x-%012x',
    math.random(0, 0xffffffff),                     -- time_low
    math.random(0, 0xffff),                          -- time_mid
    math.random(0, 0xfff),                           -- time_hi (12 bits, prefixed by '4')
    math.random(0x8, 0xb),                           -- clock_seq_hi (variant 10xx → 8/9/a/b)
    math.random(0, 0xfff),                           -- clock_seq_low
    math.random(0, 0xffffffffffff)                   -- node (48 bits)
  )
end

-- -----------------------------------------------------------------------------
-- §3. Public API
-- -----------------------------------------------------------------------------

--- V4: generate canonical v4 UUID. Delegates to Bridges.UUID.v4 if available,
--- else fallback inline implementation.
---@return string
function M.V4()
  if _G.Bridges and _G.Bridges.UUID and type(_G.Bridges.UUID.v4) == 'function' then
    local ok, result = pcall(_G.Bridges.UUID.v4)
    if ok and Validators.IsValidUUID(result) then
      return result
    end
    -- Bridges UUID failed validation — fall through to inline (defensive)
  end
  return generate_inline()
end

--- IsValid: format check (delegates to validators).
---@param v any
---@return boolean
function M.IsValid(v)
  return Validators.IsValidUUID(v)
end

--- ParseOrError: validate + return canonical string OR throw standardized error.
---@param v any
---@return string canonical_uuid
---@return table|nil err
function M.ParseOrError(v)
  if not Validators.IsValidUUID(v) then
    return nil, Errors.New('INVALID_UUID', { value = tostring(v):sub(1, 64) })
  end
  return v, nil
end

--- Short: 8-char prefix of v4 UUID (for display / correlation labels).
--- NOT cryptographically secure — only for human-readable IDs.
---@return string
function M.Short()
  return M.V4():sub(1, 8)
end

return M
