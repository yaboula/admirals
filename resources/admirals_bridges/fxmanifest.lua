fx_version 'cerulean'
game      'gta5'
lua54     'yes'

author      'Admirals'
version     '0.1.0'
description 'Admirals Bridges Layer — multi-framework compatibility (Bank / Inventory / Phone / Identity / Target / Notify)'

-- =============================================================================
-- Load order rationale (per docs/technical/07_bridges_compatibility.md §2.3):
--
--   1. config.lua              — constants + convars + priority maps.
--   2. server/logger.lua       — Logger.{Info,Warn,Error,Audit,Boundary}.
--   3. server/registry.lua     — Bridges.{RegisterAdapter,GetAdapter,...}.
--   4. server/dispatcher.lua   — Bridges.Dispatcher.Call + idem helpers
--                                (Bridges._IsIdemReplay / _StoreIdem).
--   5. bridges/*.lua           — declare Bridges.Bank/Inventory/... public
--                                API + _required_methods (validated by
--                                RegisterAdapter when adapters load).
--   6. adapters/*/native.lua   — call Bridges.RegisterAdapter() at load.
--                                MUST load AFTER bridges/*.lua.
--   7. server/detect.lua       — auto-detection + overrides logic.
--   8. server/init.lua         — boot orchestration (LAST). Validates all,
--                                runs detection, activates, prints report.
-- =============================================================================

shared_scripts {
  'config.lua',
}

server_scripts {
  -- Foundation
  'server/logger.lua',
  'server/registry.lua',
  'server/dispatcher.lua',

  -- Bridge interfaces (declare Bridges.<Module> + _required_methods)
  'bridges/bank.lua',
  'bridges/inventory.lua',
  'bridges/phone.lua',
  'bridges/identity.lua',
  'bridges/target.lua',
  'bridges/notify.lua',

  -- Native adapters (register via Bridges.RegisterAdapter())
  'adapters/bank/native.lua',
  'adapters/inventory/native.lua',
  'adapters/phone/native.lua',
  'adapters/identity/native.lua',
  'adapters/target/native.lua',
  'adapters/notify/native.lua',

  -- Detection + boot orchestration (LAST)
  'server/detect.lua',
  'server/init.lua',
}
