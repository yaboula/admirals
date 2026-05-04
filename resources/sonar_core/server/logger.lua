-- =============================================================================
-- SONAR Core — server/logger.lua
--
-- Logger estructurado para sonar_core + resto de resources sonar_*.
--
-- API pública:
--   SONAR.Log.Debug(fmt, ...)
--   SONAR.Log.Info(fmt, ...)
--   SONAR.Log.Warn(fmt, ...)
--   SONAR.Log.Error(fmt, ...)
--   SONAR.Log.Audit(entry_table)       — escribe a ring buffer siempre +
--                                           console si level permite.
--   SONAR.Log.GetRingBuffer([n])       — oldest-first; opcional últimas n.
--   SONAR.Log.Clear()                  — vacía ring buffer.
--   SONAR.Log.SetLevel(level_string)   — runtime override.
--
-- Admin commands (ACE-gated):
--   /sonar_log_dump [n]   — imprime últimas n entries (default 50).
--   /sonar_log_level <lv> — cambia LogLevel runtime.
--   /sonar_log_clear      — vacía ring buffer.
--
-- Formato console:
--   [HH:MM:SS.mmm] [LEVEL] [resource] message
--
-- Ring buffer:
--   Circular array, O(1) append, O(n) dump. Tamaño Config.LogRingBufferSize.
--   Cada entry: { ts, ts_ms, level, resource, msg, ctx? }.
--
-- Referencias SSoT:
--   docs/technical/04_api_contracts.md §6.4 (audit logging).
--   docs/technical/06_fivem_standards.md §2 (performance budgets — log
--     calls deben ser <50μs en path crítico).
-- =============================================================================

SONAR = SONAR or {}
SONAR.Log = SONAR.Log or {}

local Config = SONAR.Config
local Log = SONAR.Log

-- -----------------------------------------------------------------------------
-- Ring buffer — circular array + head pointer para O(1) append.
-- -----------------------------------------------------------------------------
local _ring = {}
local _ring_head = 1
local _ring_size = 0
local _ring_max = Config.LogRingBufferSize or 1000

-- -----------------------------------------------------------------------------
-- Mutable level (SetLevel runtime override lo modifica sin tocar Config).
-- -----------------------------------------------------------------------------
local _current_level = Config.LogLevel or 'info'

-- -----------------------------------------------------------------------------
-- Resource name detection — útil cuando sonar_bank / sonar_tablet
-- requieran el logger más adelante (S1+). Por ahora "sonar_core".
-- -----------------------------------------------------------------------------
local _resource_name = GetCurrentResourceName() or 'sonar_core'

-- -----------------------------------------------------------------------------
-- Internal — format timestamp HH:MM:SS.mmm.
-- -----------------------------------------------------------------------------
local function _timestamp()
  local ms = math.floor((GetGameTimer() % 1000))
  return string.format('%s.%03d', os.date('%H:%M:%S'), ms)
end

-- -----------------------------------------------------------------------------
-- Internal — nivel numérico actual para filtering.
-- -----------------------------------------------------------------------------
local function _should_emit(level)
  local target = Config.LogLevelNumeric[level] or 99
  local current = Config.LogLevelNumeric[_current_level] or 3
  return target <= current
end

-- -----------------------------------------------------------------------------
-- Internal — write raw line to FiveM console with ANSI colors (^1-^9).
-- -----------------------------------------------------------------------------
local function _emit_console(level, msg)
  local color = Config.LogColors[level] or Config.LogColors.reset
  local reset = Config.LogColors.reset
  local line = string.format('%s[%s]%s %s[%s]%s %s[%s]%s %s',
    '^7', _timestamp(), reset,
    color, level:upper(), reset,
    '^6', _resource_name, reset,
    msg
  )
  print(line)
end

-- -----------------------------------------------------------------------------
-- Internal — append entry a ring buffer (siempre, sea cual sea level).
-- -----------------------------------------------------------------------------
local function _ring_append(level, msg, ctx)
  _ring[_ring_head] = {
    ts = os.time(),
    ts_ms = GetGameTimer(),
    level = level,
    resource = _resource_name,
    msg = msg,
    ctx = ctx,
  }
  _ring_head = (_ring_head % _ring_max) + 1
  if _ring_size < _ring_max then _ring_size = _ring_size + 1 end
end

-- -----------------------------------------------------------------------------
-- Internal — core log function.
-- -----------------------------------------------------------------------------
local function _log(level, fmt, ...)
  local msg
  if select('#', ...) > 0 then
    local ok, formatted = pcall(string.format, fmt, ...)
    msg = ok and formatted or tostring(fmt)
  else
    msg = tostring(fmt)
  end

  -- Ring buffer: siempre append (permite dumps forense incluso sin console emit).
  _ring_append(level, msg, nil)

  -- Console: solo si level permite.
  if _should_emit(level) then
    _emit_console(level, msg)
  end
end

-- -----------------------------------------------------------------------------
-- Public — niveles básicos.
-- -----------------------------------------------------------------------------
function Log.Debug(fmt, ...) _log('debug', fmt, ...) end
function Log.Info(fmt, ...)  _log('info',  fmt, ...) end
function Log.Warn(fmt, ...)  _log('warn',  fmt, ...) end
function Log.Error(fmt, ...) _log('error', fmt, ...) end

-- -----------------------------------------------------------------------------
-- Public — Audit entry structurado.
-- Siempre persiste a ring buffer + console si LogLevel >= info.
-- Adicional (S1.1+): persiste async a tabla sonar_audit_log via oxmysql
-- — fire-and-forget, errores se loguean pero no propagan (audit nunca debe
-- bloquear el path crítico per SSoT §10.3).
--
-- @param entry table {
--   category    string   — REQUIRED — e.g. 'bank.starter_seed'.
--   action      string   — REQUIRED — e.g. 'credit', 'debit', 'create'.
--   actor       string?  — citizen_id o account UUID del actor.
--   actor_source number? — FiveM source id snapshot (debug).
--   target_type string?  — 'account', 'bank_account', 'company', etc.
--   target      string?  — id de la entity afectada.
--   amount      number?  — si operación financiera.
--   currency    string?  — default omitido (NULL en DB).
--   request_id  string?  — idempotency key asociada.
--   resource    string?  — origen (default GetCurrentResourceName).
--   payload     table?   — metadata extra → JSON columna.
-- }
-- -----------------------------------------------------------------------------

-- Async DB persistence — fire-and-forget. NUNCA bloquea caller.
-- DB no-ready o INSERT fail → solo log Warn (NO Audit recursivo para evitar loop).
local function _persist_audit_to_db(entry)
  -- Cargado lazy — SONAR.DB puede no estar listo en boot temprano.
  local DB = SONAR.DB
  if not DB or type(DB.Insert) ~= 'function' then
    return  -- DB layer no inicializado todavía; skip silently.
  end

  local payload_json = nil
  if type(entry.payload) == 'table' then
    local ok_enc, encoded = pcall(json.encode, entry.payload)
    if ok_enc then payload_json = encoded end
  end

  local ok, err = pcall(DB.Insert, [[
    INSERT INTO sonar_audit_log
      (category, action, actor_account_id, actor_source,
       target_type, target_id, amount, currency,
       request_id, resource, metadata)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ]], {
    entry.category or 'unknown',
    entry.action   or 'unknown',
    entry.actor,                -- nil → NULL OK
    entry.actor_source,
    entry.target_type,
    entry.target,
    entry.amount,
    entry.currency,
    entry.request_id,
    entry.resource or _resource_name,
    payload_json,
  })

  if not ok then
    -- NO usar Log.Audit aquí (evitar loop). Direct console + ring.
    _ring_append('warn', 'audit DB persist failed: ' .. tostring(err), nil)
    if _should_emit('warn') then
      _emit_console('warn', 'audit DB persist failed: ' .. tostring(err))
    end
  end
end

function Log.Audit(entry)
  if type(entry) ~= 'table' then
    Log.Warn('Log.Audit called with non-table arg: %s', tostring(entry))
    return
  end

  -- Ring buffer con entry completo como ctx.
  _ring_append('audit', string.format('%s/%s',
    entry.category or '?', entry.action or '?'), entry)

  -- Console solo si info habilitado (audit ≈ info semántica).
  if _should_emit('info') then
    local actor = entry.actor or '-'
    local target = entry.target or '-'
    _emit_console('audit', string.format('%s/%s actor=%s target=%s',
      entry.category or '?', entry.action or '?', actor, target))
  end

  -- Async DB persist — Citizen.CreateThread para no bloquear caller.
  Citizen.CreateThread(function()
    _persist_audit_to_db(entry)
  end)
end

-- -----------------------------------------------------------------------------
-- Public — GetRingBuffer — devuelve copia del ring en orden cronológico.
--
-- @param n number|nil — si dado, últimas n entries (default all).
-- @return table[]
-- -----------------------------------------------------------------------------
function Log.GetRingBuffer(n)
  if _ring_size == 0 then return {} end
  local total = _ring_size
  local take = math.min(n or total, total)

  -- Oldest index = head - size (+ max si negativo).
  local oldest = _ring_head - total
  if oldest <= 0 then oldest = oldest + _ring_max end

  -- Start desde (total - take) entradas después de oldest.
  local start_offset = total - take

  local result = {}
  for i = 0, take - 1 do
    local idx = ((oldest + start_offset + i - 1) % _ring_max) + 1
    result[#result + 1] = _ring[idx]
  end
  return result
end

-- -----------------------------------------------------------------------------
-- Public — Clear — vacía ring buffer (util para tests + /sonar_log_clear).
-- -----------------------------------------------------------------------------
function Log.Clear()
  _ring = {}
  _ring_head = 1
  _ring_size = 0
end

-- -----------------------------------------------------------------------------
-- Public — SetLevel — runtime override.
-- -----------------------------------------------------------------------------
function Log.SetLevel(level)
  if Config.LogLevelNumeric[level] then
    _current_level = level
    Log.Info('Log level set to %s', level)
    return true
  end
  Log.Warn('Unknown log level: %s (valid: debug|info|warn|error)', tostring(level))
  return false
end

-- -----------------------------------------------------------------------------
-- Public — GetLevel — útil para tests + boot report.
-- -----------------------------------------------------------------------------
function Log.GetLevel()
  return _current_level
end

-- -----------------------------------------------------------------------------
-- Public — Size — útil para tests + /sonar_metrics.
-- -----------------------------------------------------------------------------
function Log.Size()
  return _ring_size
end

-- =============================================================================
-- Admin commands — ACE-gated.
-- =============================================================================

-- Helper: check source es admin.
local function _is_admin(source)
  if source == 0 then return true end  -- console siempre.
  return IsPlayerAceAllowed(source, Config.AdminAcePrefix .. 'log_dump')
end

-- /sonar_log_dump [n] — imprime últimas n entries.
RegisterCommand('sonar_log_dump', function(source, args)
  if not _is_admin(source) then
    if source ~= 0 then
      TriggerClientEvent('chat:addMessage', source,
        { args = { '^1[SONAR]', 'Access denied.' } })
    end
    return
  end

  local n = tonumber(args[1]) or 50
  local entries = Log.GetRingBuffer(n)

  print(string.format('^5=== SONAR Core — Log Dump (last %d of %d) ===^7',
    #entries, _ring_size))
  for _, e in ipairs(entries) do
    local ts_str = os.date('%Y-%m-%d %H:%M:%S', e.ts)
    local color = Config.LogColors[e.level] or Config.LogColors.reset
    print(string.format('%s[%s] [%s] [%s]^7 %s',
      color, ts_str, e.level:upper(), e.resource, e.msg))
  end
  print('^5===============================================^7')
end, true)  -- restricted = true

-- /sonar_log_level <debug|info|warn|error>
RegisterCommand('sonar_log_level', function(source, args)
  if not _is_admin(source) then return end
  local level = args[1]
  if not level then
    print(string.format('Usage: sonar_log_level <debug|info|warn|error>. Current: %s',
      _current_level))
    return
  end
  Log.SetLevel(level)
end, true)

-- /sonar_log_clear — vacía ring buffer.
RegisterCommand('sonar_log_clear', function(source)
  if not _is_admin(source) then return end
  Log.Clear()
  print('^2[SONAR] Log ring buffer cleared.^7')
end, true)

-- -----------------------------------------------------------------------------
-- Boot announce (loguea solo si level >= info).
-- -----------------------------------------------------------------------------
Log.Info('Logger ready (level=%s, ring_size=%d, env=%s)',
  _current_level, _ring_max, Config.Env or 'unknown')
