-- =============================================================================
-- Admirals Bank — server/iban.lua
--
-- IBAN generation + validation + checksum.
--
-- Format canónico (SSoT docs/economy/01_economic_model.md §2.5 reconciliado
-- con docs/technical/03_db_schema.md §4.1:498):
--
--   AD-XXXX-XXXX-XXXX  (17 chars total)
--    │   │    │    │
--    │   │    │    └── 4 chars: 3 random + 1 checksum
--    │   │    └─────── 4 chars random uppercase alphanumeric
--    │   └──────────── 4 chars random uppercase alphanumeric
--    └──────────────── 'AD-' prefijo fijo Admirals
--
-- Checksum algorithm (Admirals canonical):
--   1. Tomar los 11 chars random (sin prefix ni dashes).
--   2. SHA-256(payload) → hex string.
--   3. Tomar primer byte (2 hex chars) → number 0..255.
--   4. Map number mod 36 → char en Charset (A-Z 0-9).
--   5. Char resultante reemplaza el 12º char (último del último grupo).
--
-- Esto provee:
--   - Detección errores de typo (reorder, char swap) con probabilidad ~97%.
--   - NO criptográficamente seguro (no objetivo — IBAN ≠ secreto).
--   - Verifiable cliente o server con SHA-256 estándar.
--
-- API pública:
--   IBAN.Generate()           → string IBAN nuevo (con checksum), garantizado
--                               unique vs admirals_bank_accounts.iban en DB.
--   IBAN.Validate(iban)       → ok, err_code | true
--                               err_codes: INVALID_FORMAT | INVALID_CHECKSUM |
--                                          RESERVED_PREFIX
--   IBAN.ComputeChecksum(s11) → checksum char (1 char) para 11 chars input.
--   IBAN.IsReserved(iban)     → boolean (matches Config.IbanReservedPrefixes).
--
-- Performance:
--   - Generate: ~5ms (1 SHA-256 via MySQL + 1 SELECT WHERE iban=? para uniqueness).
--   - Validate: ~5ms (1 SHA-256 via MySQL).
--   - Para hot paths Tablet (mostrar IBAN), Validate NO es necesario en cada
--     read — solo en INSERT y user-facing input.
--
-- Referencias SSoT:
--   docs/economy/01_economic_model.md §2.5.
--   docs/technical/03_db_schema.md §4.1:498.
-- =============================================================================

Admirals = Admirals or {}
Admirals.Bank = Admirals.Bank or {}
Admirals.Bank.IBAN = Admirals.Bank.IBAN or {}

local Config = Admirals.Bank.Config
local IBAN = Admirals.Bank.IBAN

-- Seed math.random con high-resolution timer + os.time + pid-ish entropy para
-- evitar colisiones server restart inmediatos. (Mismo patrón event_bus.lua:78).
math.randomseed((os.time() * 1000 + (GetGameTimer() or 0)) % 2147483647)
-- Burn first random — algunos PRNGs Lua dan resultado degenerado en el primer call.
for _ = 1, 5 do math.random() end

-- =============================================================================
-- Internal — pure functions sin DB deps.
-- =============================================================================

-- Generar 11 chars random uppercase alphanumeric (sin prefix ni dashes).
local function _gen_random_11()
  local charset = Config.IbanCharset
  local n = #charset
  local buf = {}
  for i = 1, 11 do
    local r = math.random(1, n)
    buf[i] = charset:sub(r, r)
  end
  return table.concat(buf)
end

-- Componer IBAN final con dashes a partir de 12 chars (11 random + 1 checksum).
-- Layout: AD-<4>-<4>-<4>  donde <4>+<4>+<4> = 12 chars input.
local function _layout_with_dashes(s12)
  if #s12 ~= 12 then
    error('[IBAN._layout_with_dashes] expected 12 chars, got ' .. #s12, 2)
  end
  return Config.IbanPrefix
    .. s12:sub(1, 4) .. '-'
    .. s12:sub(5, 8) .. '-'
    .. s12:sub(9, 12)
end

-- Extraer los 11 chars random + 1 checksum de un IBAN formato AD-XXXX-XXXX-XXXX.
-- Retorna nil si formato inválido.
local function _extract_payload_and_checksum(iban)
  -- Pattern Lua: AD-(4 chars)-(4 chars)-(3 chars)(1 char checksum)
  -- Total esperado: 17 chars.
  local g1, g2, g3 = iban:match('^AD%-([A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9])%-([A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9])%-([A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9])$')
  if not (g1 and g2 and g3) then return nil end
  local s12 = g1 .. g2 .. g3
  -- Los primeros 11 chars son payload random; el 12º es checksum.
  return s12:sub(1, 11), s12:sub(12, 12)
end

-- =============================================================================
-- Public — ComputeChecksum.
--
-- @param payload string — 11 chars uppercase alphanumeric (sin prefix ni dashes).
-- @return string — 1 char checksum.
--
-- Algorithm: SHA-256(payload) via MySQL → primer byte → mod 36 → charset[idx].
-- =============================================================================
function IBAN.ComputeChecksum(payload)
  if type(payload) ~= 'string' or #payload ~= 11 then
    error('[IBAN.ComputeChecksum] payload must be 11-char string', 2)
  end

  -- SHA-256 via MySQL (consistente con admirals_core/server/migrations.lua:82).
  local hex = Admirals.DB.Scalar('SELECT SHA2(?, 256)', { payload })
  if type(hex) ~= 'string' or #hex < 2 then
    error('[IBAN.ComputeChecksum] SHA2 returned invalid result: ' .. tostring(hex), 2)
  end

  -- Primer byte hex → number.
  local first_byte = tonumber(hex:sub(1, 2), 16)
  if not first_byte then
    error('[IBAN.ComputeChecksum] could not parse first hex byte: ' .. hex:sub(1, 2), 2)
  end

  -- Map a charset (mod 36).
  local charset = Config.IbanCharset
  local idx = (first_byte % #charset) + 1
  return charset:sub(idx, idx)
end

-- =============================================================================
-- Public — IsReserved.
-- =============================================================================
function IBAN.IsReserved(iban)
  if type(iban) ~= 'string' then return false end
  for _, prefix in ipairs(Config.IbanReservedPrefixes or {}) do
    if iban:sub(1, #prefix) == prefix then return true end
  end
  return false
end

-- =============================================================================
-- Public — Validate.
--
-- @param iban string
-- @return ok:boolean, err_code:string|nil
-- =============================================================================
function IBAN.Validate(iban)
  if type(iban) ~= 'string' then
    return false, 'INVALID_FORMAT'
  end

  -- Length check rápido antes del regex.
  if #iban ~= 17 then
    return false, 'INVALID_FORMAT'
  end

  local payload, checksum = _extract_payload_and_checksum(iban)
  if not payload then
    return false, 'INVALID_FORMAT'
  end

  -- Reserved prefix check — IBAN sintácticamente válido pero no asignable a player.
  -- (Si IBAN reserved llega via input usuario → reject; si es system real → bypass este check
  --  upstream antes de llamar Validate).
  if IBAN.IsReserved(iban) then
    return false, 'RESERVED_PREFIX'
  end

  -- Checksum verify.
  local expected = IBAN.ComputeChecksum(payload)
  if expected ~= checksum then
    return false, 'INVALID_CHECKSUM'
  end

  return true
end

-- =============================================================================
-- Public — Generate.
--
-- Genera nuevo IBAN garantizado:
--   1. Formato válido (regex + checksum).
--   2. NO reserved prefix.
--   3. NO colisión con admirals_bank_accounts.iban existente.
--
-- Retries hasta Config.IbanGenerateMaxRetries; si no puede → error fatal
-- (probabilidad ~0 con 36^11 space).
--
-- @return string — IBAN nuevo unique en DB.
-- =============================================================================
function IBAN.Generate()
  for attempt = 1, Config.IbanGenerateMaxRetries do
    local payload = _gen_random_11()
    local checksum = IBAN.ComputeChecksum(payload)
    local iban = _layout_with_dashes(payload .. checksum)

    -- Skip si reserved (random raro pero posible).
    if IBAN.IsReserved(iban) then
      Admirals.Log.Debug('IBAN.Generate attempt %d hit reserved prefix, retry: %s',
        attempt, iban)
      goto continue
    end

    -- Uniqueness check vs DB.
    local existing = Admirals.DB.Scalar(
      'SELECT 1 FROM admirals_bank_accounts WHERE iban = ? LIMIT 1',
      { iban })
    if existing == nil then
      Admirals.Metrics.Counter('bank.iban.generated')
      Admirals.Metrics.Counter('bank.iban.generate_attempts', attempt)
      return iban
    end

    Admirals.Log.Warn('IBAN.Generate collision attempt %d: %s', attempt, iban)
    Admirals.Metrics.Counter('bank.iban.collisions')
    ::continue::
  end

  Admirals.Metrics.Counter('bank.iban.generate_failures')
  error(string.format(
    '[IBAN.Generate] could not generate unique IBAN after %d retries — improbable, investigate PRNG seed',
    Config.IbanGenerateMaxRetries), 2)
end

-- =============================================================================
-- Boot announce.
-- =============================================================================
Admirals.Log.Info('IBAN module ready (prefix=%s, charset_size=%d, max_retries=%d)',
  Config.IbanPrefix, #Config.IbanCharset, Config.IbanGenerateMaxRetries)
