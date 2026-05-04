-- =============================================================================
-- SONAR Bridges — server/logger.lua
--
-- Logger estructurado con niveles Debug / Info / Warn / Error / Audit.
--
-- Convenciones:
--   Info   — eventos normales (boot, adapter registered, detection result).
--   Warn   — anomalías recuperables (override inválido, conflict scripts).
--   Error  — fallos (adapter threw, method not implemented).
--   Audit  — boundary log de cada bridge call (adapter, method, latency).
--   Debug  — verbose trace (sólo si LogLevel=debug).
--
-- Formato:
--   [HH:MM:SS] [LEVEL] [sonar_bridges] message
--
-- Boundary logging (Audit):
--   Controlado por Config.LogBoundaryGlobal + Config.LogBoundaryPerModule[m].
--   Además escribe a ring buffer en memoria consultable via GetAuditTrail().
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §1.1 principio B7 (logged at
--     boundary), §4.3 (logging spec Bank).
-- =============================================================================

Bridges = Bridges or {}
Bridges.Logger = {}

local Logger = Bridges.Logger

-- Ring buffer para audit trail — último N entries en memoria.
-- Implementación: tabla indexada + head pointer, O(1) append.
local _audit_buffer = {}
local _audit_head = 1
local _audit_size = 0
local _audit_max = Config.AuditTrailMaxEntries or 500

-- -----------------------------------------------------------------------------
-- Internal — nivel numérico actual para filtering.
-- -----------------------------------------------------------------------------
local function _current_level_numeric()
  return Config.LogLevelNumeric[Config.LogLevel] or 3  -- default info
end

-- -----------------------------------------------------------------------------
-- Internal — format timestamp HH:MM:SS.
-- -----------------------------------------------------------------------------
local function _timestamp()
  return os.date('%H:%M:%S')
end

-- -----------------------------------------------------------------------------
-- Internal — write raw line to console with ANSI colors.
-- FiveM console acepta `^N` color codes (0-9).
-- -----------------------------------------------------------------------------
local function _emit(level, msg)
  local color = Config.LogColors[level] or Config.LogColors.reset
  local reset = Config.LogColors.reset
  local line = string.format('%s[%s]%s %s[%s]%s %s[sonar_bridges]%s %s',
    '^7', _timestamp(), reset,
    color, level:upper(), reset,
    '^6', reset,
    msg
  )
  print(line)
end

-- -----------------------------------------------------------------------------
-- Internal — check if level should be emitted per current LogLevel config.
-- -----------------------------------------------------------------------------
local function _should_emit(level)
  local target = Config.LogLevelNumeric[level] or 99
  return target <= _current_level_numeric()
end

-- -----------------------------------------------------------------------------
-- Public — basic level methods.
-- Signature: Logger.<Level>(fmt, ...args)  → uses string.format if varargs.
-- -----------------------------------------------------------------------------
local function _log(level, fmt, ...)
  if not _should_emit(level) then return end
  local msg = select('#', ...) > 0 and string.format(fmt, ...) or tostring(fmt)
  _emit(level, msg)
end

function Logger.Debug(fmt, ...) _log('debug', fmt, ...) end
function Logger.Info(fmt, ...)  _log('info',  fmt, ...) end
function Logger.Warn(fmt, ...)  _log('warn',  fmt, ...) end
function Logger.Error(fmt, ...) _log('error', fmt, ...) end

-- -----------------------------------------------------------------------------
-- Audit — always persisted to ring buffer. Emitted to console only if
-- boundary logging is enabled (global or per-module).
--
-- @param entry table { module, method, adapter, latency_ms, args, result, ts }
-- -----------------------------------------------------------------------------
function Logger.Audit(entry)
  entry.ts = entry.ts or os.time()

  -- Ring buffer insert
  _audit_buffer[_audit_head] = entry
  _audit_head = (_audit_head % _audit_max) + 1
  if _audit_size < _audit_max then _audit_size = _audit_size + 1 end

  -- Emit to console if boundary enabled for this module
  local module = entry.module
  local should_log = Config.LogBoundaryGlobal
    or (module and Config.LogBoundaryPerModule[module])
  if should_log then
    local msg = string.format('%s/%s via "%s" (%dms)',
      entry.module or '?', entry.method or '?',
      entry.adapter or '?', entry.latency_ms or 0)
    if entry.result and entry.result.error then
      msg = msg .. ' ERROR: ' .. tostring(entry.result.error)
    end
    _emit('audit', msg)
  end
end

-- -----------------------------------------------------------------------------
-- Boundary — conveniencia sobre Audit con shape canónico.
-- Usado por Dispatcher.Call per cada invocación.
-- -----------------------------------------------------------------------------
function Logger.Boundary(module, method, args, result, latency_ms, adapter)
  Logger.Audit({
    module = module,
    method = method,
    adapter = adapter,
    args = args,
    result = result,
    latency_ms = latency_ms or 0,
  })
end

-- -----------------------------------------------------------------------------
-- GetAuditTrail — devuelve copia del ring buffer en orden cronológico.
--
-- @return table[] entries (oldest first)
-- -----------------------------------------------------------------------------
function Logger.GetAuditTrail()
  if _audit_size == 0 then return {} end
  local result = {}
  -- Ring buffer: oldest es head - size (+ max si negativo).
  local start = _audit_head - _audit_size
  if start <= 0 then start = start + _audit_max end
  for i = 0, _audit_size - 1 do
    local idx = ((start + i - 1) % _audit_max) + 1
    result[#result + 1] = _audit_buffer[idx]
  end
  return result
end

-- -----------------------------------------------------------------------------
-- ClearAuditTrail — útil para tests.
-- -----------------------------------------------------------------------------
function Logger.ClearAuditTrail()
  _audit_buffer = {}
  _audit_head = 1
  _audit_size = 0
end

-- -----------------------------------------------------------------------------
-- SetLogLevel — runtime override (test hook).
-- -----------------------------------------------------------------------------
function Logger.SetLogLevel(level)
  if Config.LogLevelNumeric[level] then
    Config.LogLevel = level
    Logger.Info('Log level set to %s', level)
  else
    Logger.Warn('Unknown log level: %s', tostring(level))
  end
end
