-- =============================================================================
-- Admirals Bridges — config.lua
--
-- Constantes, convars parseados al boot, y mapas estáticos consumidos por
-- todos los server scripts del resource. NO contiene lógica runtime — solo
-- datos leídos por registry / dispatcher / detect / init.
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §2 (arquitectura),
--     §3 (tier system), §10 (auto-detection), §12 (Custom Adapter SDK).
--   docs/planning/02_decision_log.md ADR-009.
-- =============================================================================

Config = Config or {}

-- -----------------------------------------------------------------------------
-- Version — SEMVER de la interfaz Bridges (per doc §15).
-- Bump MAJOR si breaking change en firma. MINOR si añade método.
-- -----------------------------------------------------------------------------
Config.Version = '0.1.0'

-- -----------------------------------------------------------------------------
-- Módulos canónicos. ORDEN importa para boot report.
-- -----------------------------------------------------------------------------
Config.Modules = { 'bank', 'inventory', 'phone', 'identity', 'target', 'notify' }

-- -----------------------------------------------------------------------------
-- Log level — convar `admirals_bridge_log_level` (debug|info|warn|error).
-- Default: info en dev, warn en production (controlado por `admirals_env`).
-- -----------------------------------------------------------------------------
local _env = GetConvar('admirals_env', 'development')
local _default_log = _env == 'production' and 'warn' or 'info'
Config.LogLevel = GetConvar('admirals_bridge_log_level', _default_log)

-- -----------------------------------------------------------------------------
-- Boundary logging — audit log de CADA bridge call (adapter, method, latency).
--
-- Global toggle:         `admirals_bridge_log_boundary` (0|1)
-- Per-module override:   `admirals_bridge_log_boundary_<module>` (0|1)
--
-- En production, global=0 (overhead negligible pero ruidoso). En dev/debug
-- activar global=1 o per-module según necesidad.
-- -----------------------------------------------------------------------------
Config.LogBoundaryGlobal = GetConvarInt('admirals_bridge_log_boundary', 0) == 1
Config.LogBoundaryPerModule = {}
for _, module in ipairs(Config.Modules) do
  Config.LogBoundaryPerModule[module] =
    GetConvarInt('admirals_bridge_log_boundary_' .. module, 0) == 1
end

-- -----------------------------------------------------------------------------
-- Bank mode (per doc §4.1):
--   standalone — Admirals ledger es SSoT único. Bridges.Bank adapters externos
--                son no-op. Recomendado. Default.
--   synced     — Admirals ledger SSoT + bidirectional sync con framework bank.
--                Complejidad adicional, reconciliation cron requerido.
-- -----------------------------------------------------------------------------
Config.BankMode = GetConvar('admirals_bridge_bank_mode', 'standalone')

-- -----------------------------------------------------------------------------
-- Idempotency TTL — cuánto tiempo mantiene `Bridges._StoreIdem` un key antes
-- de expirar. Per doc §4.3: 1h. S0.2 impl es in-memory (se pierde en reboot),
-- promovido a DB-backed en S0.4 junto con admirals_bridge_idempotency table.
-- -----------------------------------------------------------------------------
Config.IdempotencyTTLSec = 3600

-- -----------------------------------------------------------------------------
-- Detection priority (per doc §10.1, líneas 688-695).
-- PRIMER match (resource started + adapter IsAvailable) wins.
-- Native es fallback implícito si nada matchea.
-- -----------------------------------------------------------------------------
Config.DetectionPriority = {
  bank     = { 'qbox', 'qbcore', 'esx', 'renewed_banking', 'okok_banking' },
  inventory= { 'ox_inventory', 'qs_inventory', 'codem_inventory', 'qb_inventory' },
  phone    = { 'lb_phone', 'qs_smartphone', 'yseries', 'qb_phone', 'npwd' },
  identity = { 'qbox', 'qbcore', 'esx' },
  target   = { 'ox_target', 'qb_target', 'qtarget' },
  notify   = { 'ox_lib', 'qb', 'esx' },
}

-- -----------------------------------------------------------------------------
-- Adapter name → FiveM resource name para GetResourceState() check.
-- Source-of-truth único para nombres de resource externos.
-- -----------------------------------------------------------------------------
Config.AdapterResourceMap = {
  -- Frameworks
  qbox             = 'qbx_core',
  qbcore           = 'qb-core',
  esx              = 'es_extended',
  -- Banking
  renewed_banking  = 'Renewed-Banking',
  okok_banking     = 'okokBanking',
  -- Inventory
  ox_inventory     = 'ox_inventory',
  qs_inventory     = 'qs-inventory',
  codem_inventory  = 'codem-inventory',
  qb_inventory     = 'qb-inventory',
  -- Phone
  lb_phone         = 'lb-phone',
  qs_smartphone    = 'qs-smartphone',
  yseries          = 'yseries',
  qb_phone         = 'qb-phone',
  npwd             = 'npwd',
  -- Target
  ox_target        = 'ox_target',
  qb_target        = 'qb-target',
  qtarget          = 'qtarget',
  -- Notify / lib
  ox_lib           = 'ox_lib',
}

-- -----------------------------------------------------------------------------
-- Tier classification per adapter (per doc §3.1 / §3.2).
-- Usado por boot report para mostrar T1/T2/Native count.
-- -----------------------------------------------------------------------------
Config.AdapterTiers = {
  bank = {
    qbox            = 'T1',
    qbcore          = 'T2', esx = 'T2',
    renewed_banking = 'T2', okok_banking = 'T2',
    native          = 'Native',
  },
  inventory = {
    ox_inventory    = 'T1',
    qs_inventory    = 'T2', codem_inventory = 'T2', qb_inventory = 'T2',
    native          = 'Native',
  },
  phone = {
    lb_phone        = 'T1',
    qs_smartphone   = 'T2', yseries = 'T2', qb_phone = 'T2', npwd = 'T2',
    native          = 'Native',
  },
  identity = {
    qbox            = 'T1',
    qbcore          = 'T2', esx = 'T2',
    native          = 'Native',
  },
  target = {
    ox_target       = 'T1',
    qb_target       = 'T2', qtarget = 'T2',
    native          = 'Native',
  },
  notify = {
    ox_lib          = 'T1',
    qb              = 'T2', esx = 'T2',
    native          = 'Native',
  },
}

-- -----------------------------------------------------------------------------
-- Custom adapters (T3 SDK, per doc §12.4).
-- Customer añade aquí { module = 'adapter_name' } tras registrar su adapter
-- via Bridges.RegisterAdapter(). Sobrescribe auto-detection.
--
-- Ejemplo:
--   Config.CustomAdapters = { bank = 'my_bank', inventory = 'my_inv' }
-- -----------------------------------------------------------------------------
Config.CustomAdapters = {}

-- -----------------------------------------------------------------------------
-- Audit trail ring buffer size — Logger.Audit escribe también a buffer en
-- memoria, consultable via Bridges.Logger.GetAuditTrail() para debug.
-- -----------------------------------------------------------------------------
Config.AuditTrailMaxEntries = 500

-- -----------------------------------------------------------------------------
-- ANSI color codes para console server (FiveM built-in: ^1-^9, ^0).
-- Usado por Logger para niveles visuales.
-- -----------------------------------------------------------------------------
Config.LogColors = {
  debug = '^8',  -- gris
  info  = '^7',  -- blanco
  warn  = '^3',  -- amarillo
  error = '^1',  -- rojo
  audit = '^5',  -- cyan
  reset = '^7',
}

-- -----------------------------------------------------------------------------
-- Numeric log level para filtering (higher = more verbose).
-- -----------------------------------------------------------------------------
Config.LogLevelNumeric = {
  error = 1, warn = 2, info = 3, debug = 4,
}
