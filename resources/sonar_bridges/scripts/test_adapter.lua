-- =============================================================================
-- SONAR Bridges — scripts/test_adapter.lua
--
-- Test harness skeleton per doc §12.5.
--
-- USO (en consola FiveM server):
--   exec resources/sonar_bridges/scripts/test_adapter.lua
--   sonar_test_adapter bank qbox
--   sonar_test_adapter inventory ox_inventory
--   sonar_test_adapter phone lb_phone
--   sonar_test_adapter identity qbox
--   sonar_test_adapter target ox_target
--   sonar_test_adapter notify ox_lib
--
-- ESTADO S0.3:
--   Skeleton estructural únicamente. Los tests son placeholders con TODO.
--   Tests reales (contra adapters vivos) se implementan S0.4+ cuando
--   sonar_core provee ciudadanos de test y mocks de DB.
--
-- ESTRUCTURA per módulo:
--   _tests_bank(adapter)      — 5 placeholders
--   _tests_inventory(adapter) — 5 placeholders
--   _tests_phone(adapter)     — 4 placeholders
--   _tests_identity(adapter)  — 5 placeholders
--   _tests_target(adapter)    — 4 placeholders
--   _tests_notify(adapter)    — 3 placeholders
--   RunTests(module, name)    — función pública per doc §12.5
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md §12.5 test harness, §4.5/§5.6/
--     §6.5/§7.4/§8.3/§9.3 expectativas testing por módulo.
-- =============================================================================

-- =============================================================================
-- Helpers internos
-- =============================================================================

local TEST_CITIZEN  = 'TEST_CID_SONAR'  -- citizenId de jugador de prueba (setup manual)
local TEST_SOURCE   = 1                    -- source del jugador de prueba (setup manual)

-- Contador de resultados per run.
local _passed = 0
local _failed = 0

local function _pass(name)
  _passed = _passed + 1
  print(string.format('^2[PASS]^7 %s', name))
end

local function _fail(name, reason)
  _failed = _failed + 1
  print(string.format('^1[FAIL]^7 %s — %s', name, tostring(reason)))
end

local function _skip(name, reason)
  print(string.format('^3[SKIP]^7 %s — %s', name, tostring(reason)))
end

--- Ejecuta un test individual con pcall.
---@param name string nombre del test
---@param fn function test function — debe lanzar error() si falla assertion
local function _run(name, fn)
  local ok, err = pcall(fn)
  if ok then
    _pass(name)
  else
    _fail(name, err)
  end
end

--- Imprime encabezado de módulo.
local function _header(module, adapter_name)
  print('^6═══════════════════════════════════════════════^7')
  print(string.format('^6  SONAR Test Harness — %s / %s^7', module, adapter_name))
  print('^6═══════════════════════════════════════════════^7')
  _passed = 0
  _failed = 0
end

--- Imprime resumen final.
local function _summary()
  local total = _passed + _failed
  local color = _failed == 0 and '^2' or '^1'
  print('^6───────────────────────────────────────────────^7')
  print(string.format('%s  PASS: %d / %d   FAIL: %d^7', color, _passed, total, _failed))
  print('^6═══════════════════════════════════════════════^7')
end

-- =============================================================================
-- Tests por módulo (S0.3: placeholders estructurales)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Bank tests (per doc §4.5 expectativas testing)
-- -----------------------------------------------------------------------------
local function _tests_bank(adapter)
  _run('GetBalance — invalid citizenId returns NOT_FOUND', function()
    -- TODO S0.4: local bal, err = adapter.GetBalance('INVALID_000', 'bank')
    -- TODO S0.4: assert(err == 'NOT_FOUND', 'expected NOT_FOUND, got '..tostring(err))
    _skip('GetBalance invalid citizen', 'TODO S0.4 — requires live adapter + test player')
    error('skip')  -- provoca _fail para visibilidad como pendiente
  end)

  _run('GetBalance — valid citizenId returns number', function()
    -- TODO S0.4: local bal, err = adapter.GetBalance(TEST_CITIZEN, 'bank')
    -- TODO S0.4: assert(type(bal) == 'number', 'expected number balance')
    _skip('GetBalance valid citizen', 'TODO S0.4')
    error('skip')
  end)

  _run('AddMoney — idempotency (same key = 1 change)', function()
    -- TODO S0.4: local key = 'idem_test_'..GetGameTimer()
    -- TODO S0.4: adapter.AddMoney(TEST_CITIZEN, 100, 'test', key)
    -- TODO S0.4: adapter.AddMoney(TEST_CITIZEN, 100, 'test', key) -- replay
    -- TODO S0.4: balance should only increase by 100, not 200
    _skip('AddMoney idempotency', 'TODO S0.4')
    error('skip')
  end)

  _run('RemoveMoney — INSUFFICIENT_FUNDS error', function()
    -- TODO S0.4: local ok, err = adapter.RemoveMoney(TEST_CITIZEN, 9999999, 'test', nil)
    -- TODO S0.4: assert(not ok and err == 'INSUFFICIENT_FUNDS')
    _skip('RemoveMoney insufficient funds', 'TODO S0.4')
    error('skip')
  end)

  _run('Transfer — atomic (from loses, to gains)', function()
    -- TODO S0.4: atomic transfer test between 2 test players
    _skip('Transfer atomic', 'TODO S0.4')
    error('skip')
  end)
end

-- -----------------------------------------------------------------------------
-- Inventory tests (per doc §5.6 edge cases)
-- -----------------------------------------------------------------------------
local function _tests_inventory(adapter)
  _run('RegisterItem — valid spec returns true', function()
    -- TODO S0.4: local ok = adapter.RegisterItem({name='sonar_test_wheat', label='Test Wheat', weight=100})
    -- TODO S0.4: assert(ok == true)
    _skip('RegisterItem valid spec', 'TODO S0.4')
    error('skip')
  end)

  _run('GiveItem — PLAYER_OFFLINE for unknown citizenId', function()
    -- TODO S0.4: local ok, err = adapter.GiveItem('OFFLINE_CID', 'sonar_test_wheat', 1, nil)
    -- TODO S0.4: assert(not ok and err == 'PLAYER_OFFLINE')
    _skip('GiveItem PLAYER_OFFLINE', 'TODO S0.4')
    error('skip')
  end)

  _run('HasItem — returns false 0 for item not in inventory', function()
    -- TODO S0.4: local has, count = adapter.HasItem(TEST_CITIZEN, 'sonar_test_wheat', 1)
    -- TODO S0.4: assert(not has and count == 0)
    _skip('HasItem not found', 'TODO S0.4')
    error('skip')
  end)

  _run('GiveItem → HasItem → RemoveItem round-trip', function()
    -- TODO S0.4: full round-trip test
    _skip('GiveItem→HasItem→RemoveItem round-trip', 'TODO S0.4')
    error('skip')
  end)

  _run('IsMetadataSupported — ox_inventory returns true', function()
    -- TODO S0.4: assert(adapter.IsMetadataSupported() == true)
    _skip('IsMetadataSupported', 'TODO S0.4')
    error('skip')
  end)
end

-- -----------------------------------------------------------------------------
-- Phone tests
-- -----------------------------------------------------------------------------
local function _tests_phone(adapter)
  _run('SendNotification — returns true for online player', function()
    -- TODO S0.4: local ok = adapter.SendNotification(TEST_CITIZEN, {title='Test', message='Hello'})
    -- TODO S0.4: assert(ok == true)
    _skip('SendNotification online', 'TODO S0.4')
    error('skip')
  end)

  _run('SendNotification — returns false for offline citizenId', function()
    -- TODO S0.4: local ok = adapter.SendNotification('OFFLINE_CID', {title='Test', message='Hi'})
    -- TODO S0.4: assert(ok == false)
    _skip('SendNotification offline', 'TODO S0.4')
    error('skip')
  end)

  _run('GetPhoneNumber — returns string or nil (no error)', function()
    -- TODO S0.4: local num = adapter.GetPhoneNumber(TEST_CITIZEN)
    -- TODO S0.4: assert(num == nil or type(num) == 'string')
    _skip('GetPhoneNumber', 'TODO S0.4')
    error('skip')
  end)

  _run('StartCall — lb_phone returns UNSUPPORTED (expected S0.3)', function()
    -- TODO S0.4: local ok, err = adapter.StartCall(TEST_CITIZEN, TEST_CITIZEN, nil)
    -- TODO S0.4: assert(not ok and err == 'UNSUPPORTED')
    _skip('StartCall UNSUPPORTED', 'TODO S0.4')
    error('skip')
  end)
end

-- -----------------------------------------------------------------------------
-- Identity tests
-- -----------------------------------------------------------------------------
local function _tests_identity(adapter)
  _run('GetCitizenId — returns nil for invalid source 0', function()
    -- TODO S0.4: local cid = adapter.GetCitizenId(0)
    -- TODO S0.4: assert(cid == nil)
    _skip('GetCitizenId invalid source', 'TODO S0.4')
    error('skip')
  end)

  _run('GetCitizenId — returns string for valid online source', function()
    -- TODO S0.4: local cid = adapter.GetCitizenId(TEST_SOURCE)
    -- TODO S0.4: assert(type(cid) == 'string' and cid ~= '')
    _skip('GetCitizenId valid source', 'TODO S0.4')
    error('skip')
  end)

  _run('GetSource — returns nil for offline citizenId', function()
    -- TODO S0.4: local src = adapter.GetSource('OFFLINE_CID_000')
    -- TODO S0.4: assert(src == nil)
    _skip('GetSource offline', 'TODO S0.4')
    error('skip')
  end)

  _run('GetPlayerData — returns shape {citizenId, source, firstname, lastname}', function()
    -- TODO S0.4: local pd = adapter.GetPlayerData(TEST_CITIZEN)
    -- TODO S0.4: assert(pd and pd.citizenId and pd.source and pd.firstname ~= nil)
    _skip('GetPlayerData shape', 'TODO S0.4')
    error('skip')
  end)

  _run('IsOnline — returns false for unknown citizenId', function()
    -- TODO S0.4: assert(adapter.IsOnline('UNKNOWN_CID') == false)
    _skip('IsOnline false', 'TODO S0.4')
    error('skip')
  end)
end

-- -----------------------------------------------------------------------------
-- Target tests
-- -----------------------------------------------------------------------------
local function _tests_target(adapter)
  _run('AddBoxZone — returns true for valid params', function()
    -- TODO S0.4: local ok = adapter.AddBoxZone('test_zone_1', {x=0,y=0,z=0}, {x=1,y=1,z=1}, 0, {})
    -- TODO S0.4: assert(ok == true)
    _skip('AddBoxZone valid', 'TODO S0.4')
    error('skip')
  end)

  _run('RemoveZone — returns true for existing zone', function()
    -- TODO S0.4: adapter.AddBoxZone('test_zone_remove', ...)
    -- TODO S0.4: local ok = adapter.RemoveZone('test_zone_remove')
    -- TODO S0.4: assert(ok == true)
    _skip('RemoveZone existing', 'TODO S0.4')
    error('skip')
  end)

  _run('RemoveZone — returns false for unknown zone', function()
    -- TODO S0.4: local ok = adapter.RemoveZone('NONEXISTENT_ZONE')
    -- TODO S0.4: assert(ok == false)
    _skip('RemoveZone unknown', 'TODO S0.4')
    error('skip')
  end)

  _run('AddBoxZone — returns false for empty id', function()
    -- TODO S0.4: local ok = adapter.AddBoxZone('', {}, {}, 0, {})
    -- TODO S0.4: assert(ok == false)
    _skip('AddBoxZone empty id', 'TODO S0.4')
    error('skip')
  end)
end

-- -----------------------------------------------------------------------------
-- Notify tests
-- -----------------------------------------------------------------------------
local function _tests_notify(adapter)
  _run('Show — returns true for valid source', function()
    -- TODO S0.4: local ok = adapter.Show(TEST_SOURCE, {type='info', message='Test notification'})
    -- TODO S0.4: assert(ok == true)
    _skip('Show valid source', 'TODO S0.4')
    error('skip')
  end)

  _run('Show — returns false for non-numeric source', function()
    -- TODO S0.4: local ok = adapter.Show('not_a_number', {type='info', message='Test'})
    -- TODO S0.4: assert(ok == false)
    _skip('Show invalid source', 'TODO S0.4')
    error('skip')
  end)

  _run('Broadcast — returns true (no error)', function()
    -- TODO S0.4: local ok = adapter.Broadcast({type='success', message='Broadcast test'})
    -- TODO S0.4: assert(ok == true)
    _skip('Broadcast returns true', 'TODO S0.4')
    error('skip')
  end)
end

-- =============================================================================
-- Dispatch table módulo → función de tests
-- =============================================================================

local _module_tests = {
  bank      = _tests_bank,
  inventory = _tests_inventory,
  phone     = _tests_phone,
  identity  = _tests_identity,
  target    = _tests_target,
  notify    = _tests_notify,
}

-- =============================================================================
-- RunTests — función pública per doc §12.5
-- =============================================================================

--- Ejecuta suite de tests para un módulo + adapter específico.
---@param module string 'bank'|'inventory'|'phone'|'identity'|'target'|'notify'
---@param adapter_name string nombre del adapter registrado
function RunTests(module, adapter_name)
  local adapter = Bridges.GetAdapter(module, adapter_name)
  if not adapter then
    print(string.format('^1[ERROR]^7 Adapter "%s/%s" not found. '
      .. 'Asegura que el resource está cargado.', module, adapter_name))
    return
  end

  local test_fn = _module_tests[module]
  if not test_fn then
    print(string.format('^1[ERROR]^7 No tests defined for module "%s".', module))
    return
  end

  _header(module, adapter_name)
  test_fn(adapter)
  _summary()
end

-- =============================================================================
-- Console command: sonar_test_adapter <module> <adapter_name>
-- =============================================================================

RegisterCommand('sonar_test_adapter', function(src, args)
  if src ~= 0 then return end  -- solo consola server
  local module       = args[1]
  local adapter_name = args[2]
  if not module or not adapter_name then
    print('^3[USAGE]^7 sonar_test_adapter <module> <adapter_name>')
    print('  Modules:  bank | inventory | phone | identity | target | notify')
    print('  Example:  sonar_test_adapter bank qbox')
    return
  end
  RunTests(module, adapter_name)
end, true)

print('^6[sonar_bridges]^7 test_adapter harness loaded — use: sonar_test_adapter <module> <name>')
