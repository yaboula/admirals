-- =============================================================================
-- SONAR Core — server/migrations.lua
--
-- Idempotent migrations runner. Aplica NNN_description.sql files listed
-- en Config.MigrationsFiles (orden explícito) contra MySQL vía oxmysql.
--
-- API pública:
--   SONAR.Migrations.RunAll()              → { applied, skipped, errors }
--   SONAR.Migrations.ListApplied()         → { { version, filename, applied_at, checksum } }
--   SONAR.Migrations.IsApplied(version)    → boolean
--
-- Protocolo (per docs/technical/03_db_schema.md §16):
--   1. Bootstrap: ensure `sonar_schema_versions` table exists (first-run).
--      Se logra aplicando 001_schema_versions.sql fuera del tracking
--      (since la tabla aún no existe para tracking).
--   2. Para cada file en orden:
--      a. Compute SHA-256 del body.
--      b. SELECT sonar_schema_versions WHERE version = N.
--      c. Si aplicada:
--         - Si checksum match → SKIP + Log.Debug.
--         - Si checksum mismatch → Log.Warn (tampering suspect). Per
--           Config.MigrationsFailFast=true → hard-stop boot.
--      d. Si no aplicada:
--         - Execute body en oxmysql (puede contener multi-statement SQL).
--         - Si exitoso → INSERT en sonar_schema_versions.
--         - Si fail → Log.Error + hard-stop (fail-fast).
--
-- Nota técnica oxmysql multi-statement:
--   oxmysql soporta múltiples statements separados por ';' SI el connection
--   string incluye `multipleStatements=true`. Si no, hay que parse/split.
--   Aquí implementamos split naive pero robusto para nuestro DDL:
--   separar por ';\n' (newline obligatorio tras ';' para evitar falsos positivos
--   dentro de strings). Los .sql files SONAR siguen esta convención.
--
-- SHA-256:
--   oxmysql no expose hash. FiveM tampoco tiene crypto native directo.
--   Implementamos SHA-256 Lua puro (~200 líneas) OR usamos el checksum vía
--   MySQL: SELECT SHA2(?, 256). Esto último es más simple y correcto.
--
-- Referencias SSoT:
--   docs/technical/03_db_schema.md §12.2 (sonar_schema_versions DDL) +
--     §16 (migrations strategy).
-- =============================================================================

SONAR = SONAR or {}
SONAR.Migrations = SONAR.Migrations or {}

local Config = SONAR.Config
local Log = SONAR.Log
local Metrics = SONAR.Metrics
local DB = SONAR.DB
local M = SONAR.Migrations

local _resource = GetCurrentResourceName()

-- -----------------------------------------------------------------------------
-- Internal — parse filename → { version:int, name:string } per pattern.
-- -----------------------------------------------------------------------------
local function _parse_filename(filename)
  local version_str, name = filename:match(Config.MigrationsFilenamePattern)
  if not version_str then return nil end
  return { version = tonumber(version_str), name = name, filename = filename }
end

-- -----------------------------------------------------------------------------
-- Internal — read migration body from resource files.
-- -----------------------------------------------------------------------------
local function _read_body(filename)
  local path = Config.MigrationsDir .. '/' .. filename
  local body = LoadResourceFile(_resource, path)
  if not body or body == '' then
    error(('[Migrations] Cannot read %s'):format(path), 2)
  end
  return body
end

-- -----------------------------------------------------------------------------
-- Internal — SHA-256 hash via MySQL SHA2() function.
-- Simple y correcto, overhead ~1ms per migration (negligible).
-- -----------------------------------------------------------------------------
local function _sha256(body)
  return DB.Scalar('SELECT SHA2(?, 256)', { body })
end

-- -----------------------------------------------------------------------------
-- Internal — split multi-statement SQL body por ';' seguido de newline.
-- Ignora lines que son pure comment ('-- ...') o empty.
-- Nuestros .sql files siguen convención: cada statement termina con ';\n'.
--
-- Edge cases manejados:
--   - Trailing whitespace tras ';' → ok.
--   - Comments '--' en medio de query → split no rompe (el split es solo
--     en ';' seguido de newline, y los comments terminan en newline propio).
--   - Strings con ';' embebidos no esperados en DDL — si aparecen futuros
--     INSERTs con ';' en values, usar $$ delimiters o multipleStatements=true.
-- -----------------------------------------------------------------------------
local function _split_statements(body)
  local statements = {}
  local current = {}

  for line in body:gmatch('([^\n]*)\n?') do
    -- Strip full-line comments y whitespace.
    local stripped = line:gsub('^%s+', ''):gsub('%s+$', '')
    if stripped ~= '' and not stripped:match('^%-%-') then
      current[#current + 1] = line

      -- Si la línea termina en ';' (tras trim) → fin de statement.
      if line:match(';%s*$') then
        local stmt = table.concat(current, '\n')
        stmt = stmt:gsub('%s+$', '')
        -- Strip trailing ';' — oxmysql añade implícito y algunos drivers fallan con doble ';'.
        stmt = stmt:gsub(';%s*$', '')
        if stmt ~= '' then
          statements[#statements + 1] = stmt
        end
        current = {}
      end
    end
  end

  -- Último statement sin ';' trailing (edge case).
  if #current > 0 then
    local stmt = table.concat(current, '\n'):gsub('%s+$', ''):gsub(';%s*$', '')
    if stmt ~= '' then statements[#statements + 1] = stmt end
  end

  return statements
end

-- -----------------------------------------------------------------------------
-- Internal — bootstrap sonar_schema_versions table (first-run special case).
--
-- Llamado solo si la tabla NO existe todavía. Después todo va por el flow
-- normal de registered migrations.
-- -----------------------------------------------------------------------------
local function _ensure_schema_versions_table()
  -- Detectar existencia.
  local exists = DB.Scalar([[
    SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = 'sonar_schema_versions'
  ]], {})

  return (tonumber(exists) or 0) > 0
end

-- -----------------------------------------------------------------------------
-- Internal — get applied row per version (or nil).
-- -----------------------------------------------------------------------------
local function _get_applied(version)
  return DB.FetchOne([[
    SELECT version, filename, applied_at, applied_by, checksum, duration_ms
    FROM sonar_schema_versions
    WHERE version = ?
  ]], { version })
end

-- -----------------------------------------------------------------------------
-- Internal — apply single migration (multi-statement aware).
-- -----------------------------------------------------------------------------
local function _apply_single(mig, body)
  local statements = _split_statements(body)
  if #statements == 0 then
    error(('[Migrations] No statements parsed from %s'):format(mig.filename))
  end

  Log.Debug('Applying migration %s (%d statements)', mig.filename, #statements)

  local start_ms = GetGameTimer()

  -- Cada statement individual (oxmysql.query.await ejecuta 1 statement).
  for i, stmt in ipairs(statements) do
    local ok, err = pcall(function()
      MySQL.query.await(stmt, {})
    end)
    if not ok then
      error(('[Migrations] %s statement %d/%d failed: %s\n  SQL: %s'):format(
        mig.filename, i, #statements, tostring(err), stmt:sub(1, 300)), 2)
    end
  end

  return GetGameTimer() - start_ms
end

-- -----------------------------------------------------------------------------
-- Public — IsApplied.
-- -----------------------------------------------------------------------------
function M.IsApplied(version)
  -- Si la tabla aún no existe → falso.
  if not _ensure_schema_versions_table() then return false end
  return _get_applied(version) ~= nil
end

-- -----------------------------------------------------------------------------
-- Public — ListApplied.
-- -----------------------------------------------------------------------------
function M.ListApplied()
  if not _ensure_schema_versions_table() then return {} end
  return DB.FetchAll([[
    SELECT version, filename, applied_at, applied_by, checksum, duration_ms
    FROM sonar_schema_versions
    ORDER BY version ASC
  ]], {})
end

-- -----------------------------------------------------------------------------
-- Public — RunAll — applies todas las migrations en Config.MigrationsFiles.
--
-- @return { applied_count, skipped_count, errors[] }
-- -----------------------------------------------------------------------------
function M.RunAll()
  local report = { applied = {}, skipped = {}, errors = {}, started_at = os.time() }

  Log.Info('Migrations: starting run (%d files registered)',
    #Config.MigrationsFiles)

  -- Flag: ¿la tabla schema_versions existía al principio?
  local had_table = _ensure_schema_versions_table()
  Log.Debug('sonar_schema_versions exists pre-run: %s', tostring(had_table))

  for _, filename in ipairs(Config.MigrationsFiles) do
    local mig = _parse_filename(filename)
    if not mig then
      local err = ('[Migrations] Invalid filename pattern: %s'):format(filename)
      Log.Error(err)
      report.errors[#report.errors + 1] = err
      if Config.MigrationsFailFast then
        error(err, 2)
      else
        goto continue
      end
    end

    local ok_read, body = pcall(_read_body, filename)
    if not ok_read then
      Log.Error('%s', tostring(body))
      report.errors[#report.errors + 1] = tostring(body)
      if Config.MigrationsFailFast then error(body, 2) end
      goto continue
    end

    local checksum = _sha256(body)

    -- Special case para primera migration si la tabla schema_versions aún
    -- no existe: aplicar sin tracking previo (la migration la crea), después
    -- registrar la fila ella misma.
    local applied_row = nil
    if had_table then
      applied_row = _get_applied(mig.version)
    end

    if applied_row then
      -- Ya aplicada — verify checksum.
      if Config.MigrationsChecksumCheck and applied_row.checksum ~= checksum then
        local msg = ('[Migrations] %s checksum mismatch: stored=%s current=%s (TAMPERING SUSPECT)')
          :format(filename, applied_row.checksum, checksum)
        Log.Warn(msg)
        if Config.MigrationsFailFast then
          error(msg, 2)
        end
      else
        Log.Info('Migration %s already applied (skip)', filename)
        report.skipped[#report.skipped + 1] = filename
      end
      goto continue
    end

    -- No aplicada — execute.
    local ok_apply, duration = pcall(_apply_single, mig, body)
    if not ok_apply then
      Log.Error('%s', tostring(duration))
      report.errors[#report.errors + 1] = tostring(duration)
      Metrics.Counter('migrations.failed')
      if Config.MigrationsFailFast then
        error(duration, 2)
      end
      goto continue
    end

    -- Re-check: la tabla schema_versions debería existir AHORA si era la
    -- primera migration (001 crea la tabla). Si sigue no existiendo → error.
    if not _ensure_schema_versions_table() then
      local msg = ('[Migrations] %s applied but sonar_schema_versions still missing'):format(filename)
      Log.Error(msg)
      report.errors[#report.errors + 1] = msg
      if Config.MigrationsFailFast then error(msg, 2) end
      goto continue
    end

    -- Insert tracking row.
    local ok_track, track_err = pcall(function()
      DB.Insert([[
        INSERT INTO sonar_schema_versions
          (version, filename, applied_at, applied_by, checksum, duration_ms)
        VALUES (?, ?, ?, ?, ?, ?)
      ]], {
        mig.version, filename, os.time(), 'migrations_runner', checksum, duration,
      })
    end)
    if not ok_track then
      local msg = ('[Migrations] %s applied OK but tracking insert failed: %s'):format(
        filename, tostring(track_err))
      Log.Error(msg)
      report.errors[#report.errors + 1] = msg
      if Config.MigrationsFailFast then error(track_err, 2) end
      goto continue
    end

    Log.Info('Migration %s applied OK (%dms)', filename, duration)
    Metrics.Counter('migrations.applied')
    Metrics.Observe('migrations.duration_ms', duration)
    report.applied[#report.applied + 1] = {
      filename = filename, version = mig.version, duration_ms = duration,
    }

    ::continue::
  end

  report.finished_at = os.time()
  report.duration_sec = report.finished_at - report.started_at

  Log.Info('Migrations done: %d applied, %d skipped, %d errors (%ds)',
    #report.applied, #report.skipped, #report.errors, report.duration_sec)

  return report
end

-- -----------------------------------------------------------------------------
-- Boot announce.
-- -----------------------------------------------------------------------------
Log.Info('Migrations runner ready (%d files registered, fail_fast=%s, checksum_check=%s)',
  #Config.MigrationsFiles,
  Config.MigrationsFailFast and 'on' or 'off',
  Config.MigrationsChecksumCheck and 'on' or 'off')
