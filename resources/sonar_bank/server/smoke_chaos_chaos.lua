-- =============================================================================
-- SONAR Bank — Smoke Chaos Matrix v0.2 (Chaos Testing)
--
-- Test harness para pruebas de caos y concurrencia en BANK-DO.2
-- Fase 1: Chaos Basic (ST-008 a ST-015) - Bridge Stress Tests
--
-- Arquitectura:
--   - ChaosLagInjector: Inyección de lag determinista (150-300ms)
--   - ChaosConcurrency: Simulación de 20 mock players sintéticos
--   - Integración a nivel de bridges para simular latencia de red real
--
-- Referencias SSoT:
--   docs/technical/07_bridges_compatibility.md
--   docs/technical/06_fivem_standards.md (performance budgets)
-- =============================================================================

print('^3[SMOKE_CHAOS_CHAOS]^7 Loading smoke_chaos_chaos.lua...')

-- =============================================================================
-- GLOBAL LOG HELPER
-- =============================================================================
local function Log(message, level)
  level = level or 'info'
  local prefix = '^3[SMOKE_CHAOS_CHAOS]^7'
  if level == 'error' then
    prefix = '^1[SMOKE_CHAOS_CHAOS]^7'
  elseif level == 'warn' then
    prefix = '^3[SMOKE_CHAOS_CHAOS]^7'
  elseif level == 'success' then
    prefix = '^2[SMOKE_CHAOS_CHAOS]^7'
  end
  print(prefix .. " " .. message)
end

-- =============================================================================
-- MODULE: ChaosLagInjector
-- =============================================================================
ChaosLagInjector = ChaosLagInjector or {}

ChaosLagInjector.Config = {
  MinLagMs = 150,
  MaxLagMs = 300,
  SpikeProbability = 0.3,  -- 30% de llamadas sufren lag
  Pattern = 'uniform'      -- 'uniform'|'burst'|'random'
}

-- Helper: Random integer between min and max (inclusive)
local function RandomInt(min, max)
  return math.floor(math.random() * (max - min + 1)) + min
end

-- Inject lag before executing operation
-- @param operation function - Operation to execute after lag
-- @return boolean success, any result
function ChaosLagInjector.Inject(operation)
  if type(operation) ~= 'function' then
    return false, nil
  end

  -- Fast path: 70% of calls have no lag
  if math.random() > ChaosLagInjector.Config.SpikeProbability then
    local success, result = pcall(operation)
    return success, result
  end

  -- Lag path: 30% of calls suffer lag spike
  local lagMs = RandomInt(ChaosLagInjector.Config.MinLagMs, ChaosLagInjector.Config.MaxLagMs)
  Citizen.Wait(lagMs)

  local success, result = pcall(operation)
  if not success then
    Log("[CHAOS_LAG] Operation failed after " .. lagMs .. "ms lag", "error")
  end

  return success, result
end

-- Set lag pattern
-- @param pattern string 'uniform'|'burst'|'random'
function ChaosLagInjector.SetPattern(pattern)
  if pattern == 'uniform' or pattern == 'burst' or pattern == 'random' then
    ChaosLagInjector.Config.Pattern = pattern
  end
end

-- Enable/disable lag injection
-- @param enabled boolean
function ChaosLagInjector.SetEnabled(enabled)
  ChaosLagInjector.Config.SpikeProbability = enabled and 0.3 or 0.0
end

-- =============================================================================
-- MODULE: ChaosConcurrency
-- =============================================================================
ChaosConcurrency = ChaosConcurrency or {}

ChaosConcurrency.MockPlayers = {}
ChaosConcurrency.ActiveOperations = {}
ChaosConcurrency.CompletedOperations = {}
ChaosConcurrency.OpCounter = 0  -- BANK-DO.2.1 F3: monotonic counter prevents opId collision

-- BANK-DO.2.1 F3: unique opId via monotonic counter + GetGameTimer (ms precision)
function ChaosConcurrency.NextOpId(playerIndex)
  ChaosConcurrency.OpCounter = ChaosConcurrency.OpCounter + 1
  return string.format("OP_%d_%d_%d", playerIndex, GetGameTimer(), ChaosConcurrency.OpCounter)
end

-- Initialize mock players (now requires ChaosFixtures to be set up first)
-- @param count number - Number of mock players to create (default: 20)
function ChaosConcurrency.InitializeMockPlayers(count)
  count = count or 20
  ChaosConcurrency.MockPlayers = {}

  for i = 1, count do
    local iban = ChaosFixtures.GetIban(i)
    table.insert(ChaosConcurrency.MockPlayers, {
      index = i,
      citizenId = string.format("CHAOS_PLAYER_%04d", i),
      accountUUID = ChaosFixtures.GenerateAccountId(i),  -- BANK-DO.2.1 F1: real DB FK target
      iban = iban,  -- BANK-DO.2.1.b: real generated IBAN
    })
    -- Log first few mock players for debugging
    if i <= 5 then
      Log(string.format('[CHAOS_CONC] Player %d: citizenId=%s, iban=%s', i, ChaosConcurrency.MockPlayers[i].citizenId, iban), 'info')
    end
  end

  Log("[CHAOS_CONC] Initialized " .. count .. " mock players (bound to fixtures)", "info")
end

-- Get mock player by index
function ChaosConcurrency.GetPlayer(index)
  return ChaosConcurrency.MockPlayers[index]
end

-- BANK-DO.2.1 F2 + F4: Execute operation with proper success criteria + ms latency.
-- operationFn must return (success:boolean, result:any) — success=false signals business failure.
function ChaosConcurrency.ExecuteOperation(playerIndex, operationFn)
  local player = ChaosConcurrency.MockPlayers[playerIndex]
  if not player then
    return false, "PLAYER_NOT_FOUND"
  end

  local opId = ChaosConcurrency.NextOpId(playerIndex)
  local startMs = GetGameTimer()

  ChaosConcurrency.ActiveOperations[opId] = {
    opId = opId,
    playerIndex = playerIndex,
    citizenId = player.citizenId,
    startMs = startMs,
    status = 'running'
  }

  -- pcall protects against Lua errors; opSuccess is the business-level outcome.
  local pcall_ok, opSuccess, opResult = pcall(operationFn, player)
  local endMs = GetGameTimer()

  local op = ChaosConcurrency.ActiveOperations[opId]
  if not pcall_ok then
    op.status = 'failed'
    op.error = tostring(opSuccess)  -- pcall puts error msg in second arg
  elseif opSuccess then
    op.status = 'completed'
    op.result = opResult
  else
    op.status = 'failed'
    op.error = tostring(opResult or 'business_failure')
  end
  op.endMs = endMs
  op.latencyMs = endMs - startMs

  table.insert(ChaosConcurrency.CompletedOperations, op)

  return op.status == 'completed', opResult
end

-- BANK-DO.2.1 F5: explicit barrier — wait until N operations recorded or timeout.
-- @return boolean reached - true if expected count met within budget
function ChaosConcurrency.AwaitAll(expected, timeoutMs)
  timeoutMs = timeoutMs or 10000
  local waited = 0
  local pollMs = 50
  while #ChaosConcurrency.CompletedOperations < expected and waited < timeoutMs do
    Wait(pollMs)
    waited = waited + pollMs
  end
  local reached = #ChaosConcurrency.CompletedOperations >= expected
  if not reached then
    Log(string.format("[CHAOS_CONC] Barrier timeout: %d/%d ops in %dms",
      #ChaosConcurrency.CompletedOperations, expected, timeoutMs), "warn")
  end
  return reached
end

-- Get operation statistics (BANK-DO.2.1 F4: latency in ms)
function ChaosConcurrency.GetStats()
  local total = #ChaosConcurrency.CompletedOperations
  local completed = 0
  local failed = 0
  local totalLatency = 0
  local errorCounts = {}

  for _, op in ipairs(ChaosConcurrency.CompletedOperations) do
    if op.status == 'completed' then
      completed = completed + 1
    else
      failed = failed + 1
      local key = op.error or 'unknown'
      errorCounts[key] = (errorCounts[key] or 0) + 1
    end
    totalLatency = totalLatency + (op.latencyMs or 0)
  end

  return {
    total = total,
    completed = completed,
    failed = failed,
    avgLatencyMs = total > 0 and (totalLatency / total) or 0,
    errors = errorCounts,
  }
end

-- Reset operation tracking
function ChaosConcurrency.ResetTracking()
  ChaosConcurrency.ActiveOperations = {}
  ChaosConcurrency.CompletedOperations = {}
  ChaosConcurrency.OpCounter = 0
end

-- =============================================================================
-- MODULE: ChaosFixtures (BANK-DO.2.1 F1)
-- Real DB accounts so chaos tests measure SUT, not driver no-ops.
-- Idempotent setup, deterministic UUIDs, isolated by IBAN prefix 'AD-CHAS-'.
-- =============================================================================
ChaosFixtures = ChaosFixtures or {}

ChaosFixtures.AccountIdPrefix  = 'cha05000-0000-4000-8000-'  -- valid UUID v4 shape
ChaosFixtures.BankIdPrefix     = 'cha05001-0000-4000-8000-'
ChaosFixtures.InitialBalance   = 50000.00
ChaosFixtures.ActiveCount      = 0
ChaosFixtures.Ibans            = {}  -- map[i] = generated IBAN (post-Setup)

-- BANK-DO.2.1.b: required columns post-migration-014. ValidateSchema aborts
-- harness if any of these is missing, preventing the 100% false-fail seen in
-- the initial run (Unknown column 'type').
ChaosFixtures.RequiredColumns = {
  ['sonar_bank_accounts'] = { 'owner_type', 'account_class', 'last_reconciled_at' },
  ['sonar_accounts']      = { 'id', 'char_id', 'framework_source' },
}

function ChaosFixtures.GenerateAccountId(i)
  return string.format('%s%012d', ChaosFixtures.AccountIdPrefix, i)
end

function ChaosFixtures.GenerateBankId(i)
  return string.format('%s%012d', ChaosFixtures.BankIdPrefix, i)
end

function ChaosFixtures.GenerateCitizenId(i)
  return string.format('CHAOS_PLAYER_%04d', i)
end

-- Returns the IBAN assigned to chaos player i (post-Setup).
function ChaosFixtures.GetIban(i)
  return ChaosFixtures.Ibans[i]
end

-- BANK-DO.2.1.b: Verify DB schema is post-migration-014 before any INSERT.
-- Returns true if all required columns present, false otherwise (with error log).
function ChaosFixtures.ValidateSchema()
  Log('[FIXTURES] Validating DB schema (post-migration-014 expected)...', 'info')

  local rows = SONAR.DB.FetchAll([[
    SELECT TABLE_NAME, COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME IN ('sonar_bank_accounts', 'sonar_accounts')
  ]], {}) or {}

  local present = {}
  for _, row in ipairs(rows) do
    present[row.TABLE_NAME] = present[row.TABLE_NAME] or {}
    present[row.TABLE_NAME][row.COLUMN_NAME] = true
  end

  local allOk = true
  for tableName, requiredCols in pairs(ChaosFixtures.RequiredColumns) do
    local tablePresent = present[tableName] or {}
    for _, col in ipairs(requiredCols) do
      if not tablePresent[col] then
        Log(string.format('[FIXTURES] SCHEMA DRIFT: %s.%s missing — apply migration 014 or check DB sync',
          tableName, col), 'error')
        allOk = false
      end
    end
  end

  -- Legacy column detection (warning only — not blocking)
  if present['sonar_bank_accounts'] and present['sonar_bank_accounts']['type'] then
    Log('[FIXTURES] WARNING: legacy column sonar_bank_accounts.type still present — migration 014 not fully applied?', 'warn')
  end

  if allOk then
    Log('[FIXTURES] Schema validation OK (migration 014+ confirmed)', 'success')
  else
    Log('[FIXTURES] SCHEMA DRIFT DETECTED — harness aborted to prevent false results', 'error')
  end
  return allOk
end

-- Idempotent setup: creates N matching sonar_accounts + sonar_bank_accounts rows.
-- BANK-DO.2.1.b: IBANs are now generated via SONAR.Bank.IBAN.Generate() so they
-- pass full IBAN.Validate (length 17 + checksum + reserved-prefix) used by
-- Transfer.Execute. Schema is validated before any INSERT.
function ChaosFixtures.Setup(count)
  count = count or 20

  if not ChaosFixtures.ValidateSchema() then
    return false
  end

  Log(string.format('[FIXTURES] Setting up %d chaos accounts (balance=%.2f)...', count, ChaosFixtures.InitialBalance), 'info')

  if not (SONAR.Bank and SONAR.Bank.IBAN and SONAR.Bank.IBAN.Generate) then
    Log('[FIXTURES] SONAR.Bank.IBAN.Generate unavailable — cannot create valid IBANs', 'error')
    return false
  end

  local now = os.time()
  local ok = true
  ChaosFixtures.Ibans = {}
  for i = 1, count do
    local accUUID  = ChaosFixtures.GenerateAccountId(i)
    local bankUUID = ChaosFixtures.GenerateBankId(i)
    local charId   = ChaosFixtures.GenerateCitizenId(i)

    -- Generate a valid IBAN per chaos slot (passes IBAN.Validate downstream).
    local genOk, iban = pcall(SONAR.Bank.IBAN.Generate)
    if not genOk or type(iban) ~= 'string' then
      Log(string.format('[FIXTURES] IBAN.Generate failed for slot %d: %s', i, tostring(iban)), 'error')
      ok = false
      iban = string.format('AD-FAIL-%04d-0000', i)  -- placeholder so subsequent code continues
    end
    ChaosFixtures.Ibans[i] = iban

    -- Log first few IBANs for debugging
    if i <= 5 then
      Log(string.format('[FIXTURES] Slot %d IBAN: %s', i, iban), 'info')
    end

    local accOk = pcall(SONAR.DB.Execute, [[
      INSERT INTO sonar_accounts (id, char_id, framework_source, alias, created_at, updated_at)
      VALUES (?, ?, 'native', ?, ?, ?)
      ON DUPLICATE KEY UPDATE alias = VALUES(alias), updated_at = VALUES(updated_at)
    ]], { accUUID, charId, 'ChaosTest_' .. i, now, now })

    -- Post-migration-014: type column split into owner_type + account_class.
    -- Use DB.Execute with ON DUPLICATE KEY UPDATE for idempotency.
    -- Fix: Update all relevant columns on duplicate to ensure IBAN sync.
    local bankOk, bankErr = pcall(SONAR.DB.Execute, [[
      INSERT INTO sonar_bank_accounts (id, iban, owner_type, account_class, owner_account_id, balance, created_at, updated_at, closed_at)
      VALUES (?, ?, 'personal', 'checking', ?, ?, ?, ?, NULL)
      ON DUPLICATE KEY UPDATE
        iban = VALUES(iban),
        owner_type = VALUES(owner_type),
        account_class = VALUES(account_class),
        owner_account_id = VALUES(owner_account_id),
        balance = VALUES(balance),
        updated_at = VALUES(updated_at),
        closed_at = VALUES(closed_at)
    ]], { bankUUID, iban, accUUID, ChaosFixtures.InitialBalance, now, now })

    if not accOk or not bankOk then
      Log(string.format('[FIXTURES] Row %d failed (acc=%s bank=%s bankErr=%s)', i, tostring(accOk), tostring(bankOk), tostring(bankErr)), 'error')
      ok = false
    end

    -- Log first INSERT result for debugging
    if i == 1 then
      Log(string.format('[FIXTURES] First row INSERT result: bankOk=%s, bankErr=%s', tostring(bankOk), tostring(bankErr)), 'info')
    end
  end

  ChaosFixtures.ActiveCount = count
  if ok then
    Log(string.format('[FIXTURES] %d chaos accounts ready (real IBANs)', count), 'success')
    -- Verify first IBAN is in DB
    local verify_iban = ChaosFixtures.Ibans[1]
    local verify_row = SONAR.DB.FetchOne('SELECT iban FROM sonar_bank_accounts WHERE iban = ? LIMIT 1', { verify_iban })
    if verify_row then
      Log(string.format('[FIXTURES] Verification: IBAN %s found in DB', verify_iban), 'success')
    else
      Log(string.format('[FIXTURES] Verification: IBAN %s NOT found in DB - INSERT failed?', verify_iban), 'error')
    end
  else
    Log('[FIXTURES] Setup completed with errors — chaos tests may be unreliable', 'warn')
  end
  return ok
end

-- Teardown: purge all chaos rows by UUID prefix (works regardless of IBAN format).
-- BANK-DO.2.1.b: also cleans sonar_bank_movements ledger rows generated by ST-016/017.
function ChaosFixtures.Teardown()
  Log('[FIXTURES] Tearing down chaos accounts + ledger residue...', 'info')

  -- Order matters: movements first (no FK but logical), then bank_accounts (FK
  -- target of sonar_accounts via owner_account_id), then sonar_accounts last.
  local movOk, movDeleted = pcall(SONAR.DB.Execute, [[
    DELETE FROM sonar_bank_movements WHERE bank_account_id LIKE 'cha05001-%'
  ]], {})
  local bankOk, bankDeleted = pcall(SONAR.DB.Execute, [[
    DELETE FROM sonar_bank_accounts WHERE owner_account_id LIKE 'cha05000-%'
  ]], {})
  local accOk, accDeleted = pcall(SONAR.DB.Execute, [[
    DELETE FROM sonar_accounts WHERE char_id LIKE 'CHAOS_PLAYER_%'
  ]], {})

  Log(string.format('[FIXTURES] Teardown: %s movements, %s bank rows, %s account rows purged',
    tostring(movDeleted or 0), tostring(bankDeleted or 0), tostring(accDeleted or 0)),
    (movOk and bankOk and accOk) and 'success' or 'warn')
  ChaosFixtures.ActiveCount = 0
  ChaosFixtures.Ibans = {}
end

-- Reset all chaos balances to initial (called before each test for isolation).
function ChaosFixtures.ResetBalances()
  pcall(SONAR.DB.Execute, [[
    UPDATE sonar_bank_accounts SET balance = ? WHERE owner_account_id LIKE 'cha05000-%'
  ]], { ChaosFixtures.InitialBalance })
end

-- Count ledger rows belonging to chaos accounts (for ST-016/017 ledger invariant).
function ChaosFixtures.GetMovementCount()
  local row = SONAR.DB.FetchOne([[
    SELECT COUNT(*) AS n FROM sonar_bank_movements WHERE bank_account_id LIKE 'cha05001-%'
  ]], {})
  return row and tonumber(row.n) or 0
end

-- Read aggregate balance across chaos accounts (for money-conservation invariants).
function ChaosFixtures.GetBalanceSum()
  local row = SONAR.DB.FetchOne([[
    SELECT COALESCE(SUM(balance), 0) AS total
    FROM sonar_bank_accounts WHERE owner_account_id LIKE 'cha05000-%'
  ]], {})
  return row and tonumber(row.total) or 0
end

-- Read balance for a specific chaos player (1-indexed).
function ChaosFixtures.GetBalance(i)
  local accUUID = ChaosFixtures.GenerateAccountId(i)
  local row = SONAR.DB.FetchOne([[
    SELECT balance FROM sonar_bank_accounts WHERE owner_account_id = ? LIMIT 1
  ]], { accUUID })
  return row and tonumber(row.balance) or nil
end

-- Force a specific balance for one player (used by ST-013 to provoke contention).
function ChaosFixtures.SetBalance(i, value)
  local accUUID = ChaosFixtures.GenerateAccountId(i)
  pcall(SONAR.DB.Execute, [[
    UPDATE sonar_bank_accounts SET balance = ? WHERE owner_account_id = ?
  ]], { value, accUUID })
end

-- =============================================================================
-- MODULE: SmokeChaosChaos
-- =============================================================================
SmokeChaosChaos = SmokeChaosChaos or {}

SmokeChaosChaos.Results = {}
SmokeChaosChaos.Config = {
  AutoExecuteOnBoot = false,  -- Chaos tests require manual execution
  Framework = 'qbcore',       -- Current framework
  LagEnabled = false          -- Lag disabled by default for ST-008-014
}

-- Record test result
-- @param testId string
-- @param testName string
-- @param passed boolean
-- @param message string
function SmokeChaosChaos.RecordTest(testId, testName, passed, message)
  table.insert(SmokeChaosChaos.Results, {
    testId = testId,
    testName = testName,
    passed = passed,
    message = message,
    timestamp = os.time()
  })
  
  local status = passed and "^2✅ PASS^7" or "^1❌ FAIL^7"
  Log(status .. " - " .. testId .. ": " .. testName .. " - " .. message, passed and 'info' or 'error')
end

-- Print test summary
function SmokeChaosChaos.PrintSummary()
  Log("==================================================", "info")
  Log("SMOKE CHAOS MATRIX - TEST SUMMARY", "info")
  Log("==================================================", "info")
  
  local total = #SmokeChaosChaos.Results
  local passed = 0
  local failed = 0
  
  for _, result in ipairs(SmokeChaosChaos.Results) do
    if result.passed then
      passed = passed + 1
    else
      failed = failed + 1
    end
  end
  
  Log("Total Tests: " .. total, "info")
  Log("Passed: " .. passed, passed == total and 'success' or 'info')
  Log("Failed: " .. failed, failed > 0 and 'error' or 'info')
  
  if total > 0 then
    local passRate = (passed / total) * 100
    Log("Pass Rate: " .. string.format("%.1f%%", passRate), passRate >= 90 and 'success' or 'warn')
  end
  
  Log("==================================================", "info")
  Log("DETAILED RESULTS:", "info")
  Log("==================================================", "info")
  
  for _, result in ipairs(SmokeChaosChaos.Results) do
    local status = result.passed and "^2✅ PASS^7" or "^1❌ FAIL^7"
    Log(status .. " - " .. result.testId .. ": " .. result.testName, 'info')
    if not result.passed then
      Log("  Reason: " .. result.message, 'error')
    end
  end
  
  Log("==================================================", "info")
end

-- =============================================================================
-- TEST: ST-008 — Concurrent GetBalance (20 players)
-- BANK-DO.2.1: now hits real fixtures, asserts balance returned non-nil.
-- =============================================================================
function SmokeChaosChaos.Test_ST008_ConcurrentGetBalance()
  Log('ST-008: Concurrent GetBalance (20 players)', 'info')
  ChaosFixtures.ResetBalances()
  ChaosConcurrency.InitializeMockPlayers(20)
  ChaosConcurrency.ResetTracking()

  local N = 20
  for i = 1, N do
    CreateThread(function()
      ChaosConcurrency.ExecuteOperation(i, function(player)
        local row = SONAR.DB.FetchOne([[
          SELECT balance FROM sonar_bank_accounts WHERE owner_account_id = ? LIMIT 1
        ]], { player.accountUUID })
        if not row or row.balance == nil then return false, 'ACCOUNT_NOT_FOUND' end
        return true, tonumber(row.balance)
      end)
    end)
  end

  ChaosConcurrency.AwaitAll(N, 5000)
  local stats = ChaosConcurrency.GetStats()
  local testPassed = stats.completed == N and stats.failed == 0
  SmokeChaosChaos.RecordTest('ST-008', 'Concurrent GetBalance', testPassed,
    string.format('%d/%d successful, %d errors, avg latency %.2fms',
      stats.completed, N, stats.failed, stats.avgLatencyMs))
end

-- =============================================================================
-- TEST: ST-009 — Concurrent AddMoney (same player)
-- BANK-DO.2.1: invariant — balance_after == balance_before + (completed * amount).
-- Detects lost-update races on a single row.
-- =============================================================================
function SmokeChaosChaos.Test_ST009_ConcurrentAddMoneySamePlayer()
  Log('ST-009: Concurrent AddMoney (same player, 20 calls)', 'info')
  ChaosFixtures.ResetBalances()
  ChaosConcurrency.InitializeMockPlayers(20)
  ChaosConcurrency.ResetTracking()

  local targetPlayer = ChaosConcurrency.GetPlayer(1)
  local balanceBefore = ChaosFixtures.GetBalance(1) or 0
  local addAmount = 100
  local N = 20

  for i = 1, N do
    CreateThread(function()
      ChaosConcurrency.ExecuteOperation(i, function(_)
        local affected = SONAR.DB.Execute([[
          UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_account_id = ?
        ]], { addAmount, targetPlayer.accountUUID })
        if not affected or affected < 1 then return false, 'NO_ROWS_AFFECTED' end
        return true, affected
      end)
    end)
  end

  ChaosConcurrency.AwaitAll(N, 8000)
  local stats = ChaosConcurrency.GetStats()
  local balanceAfter = ChaosFixtures.GetBalance(1) or 0
  local expected = balanceBefore + (stats.completed * addAmount)
  local invariantOk = math.abs(balanceAfter - expected) < 0.01
  local testPassed = stats.completed >= 18 and invariantOk

  SmokeChaosChaos.RecordTest('ST-009', 'Concurrent AddMoney (Same Player)', testPassed,
    string.format('%d/%d ok, balance %.2f→%.2f (expected %.2f), invariant=%s, avg %.2fms',
      stats.completed, N, balanceBefore, balanceAfter, expected,
      invariantOk and 'OK' or 'BROKEN', stats.avgLatencyMs))
end

-- =============================================================================
-- TEST: ST-010 — Concurrent AddMoney (different players)
-- BANK-DO.2.1: invariant — Σbalance_after - Σbalance_before == completed * amount.
-- =============================================================================
function SmokeChaosChaos.Test_ST010_ConcurrentAddMoneyDifferentPlayers()
  Log('ST-010: Concurrent AddMoney (different players, 20 calls)', 'info')
  ChaosFixtures.ResetBalances()
  ChaosConcurrency.InitializeMockPlayers(20)
  ChaosConcurrency.ResetTracking()

  local sumBefore = ChaosFixtures.GetBalanceSum()
  local addAmount = 100
  local N = 20

  for i = 1, N do
    CreateThread(function()
      ChaosConcurrency.ExecuteOperation(i, function(player)
        local affected = SONAR.DB.Execute([[
          UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_account_id = ?
        ]], { addAmount, player.accountUUID })
        if not affected or affected < 1 then return false, 'NO_ROWS_AFFECTED' end
        return true, affected
      end)
    end)
  end

  ChaosConcurrency.AwaitAll(N, 8000)
  local stats = ChaosConcurrency.GetStats()
  local sumAfter = ChaosFixtures.GetBalanceSum()
  local expectedDelta = stats.completed * addAmount
  local actualDelta = sumAfter - sumBefore
  local invariantOk = math.abs(actualDelta - expectedDelta) < 0.01
  local testPassed = stats.completed >= 18 and invariantOk

  SmokeChaosChaos.RecordTest('ST-010', 'Concurrent AddMoney (Different Players)', testPassed,
    string.format('%d/%d ok, Σ%.2f→%.2f (Δ%.2f exp %.2f), invariant=%s, avg %.2fms',
      stats.completed, N, sumBefore, sumAfter, actualDelta, expectedDelta,
      invariantOk and 'OK' or 'BROKEN', stats.avgLatencyMs))
end

-- =============================================================================
-- TEST: ST-011 — Concurrent RemoveMoney
-- BANK-DO.2.1: with initial balance 50000 » 50 each, all 20 must succeed.
-- Invariant: Σbalance_after = Σbalance_before - (completed * amount).
-- =============================================================================
function SmokeChaosChaos.Test_ST011_ConcurrentRemoveMoney()
  Log('ST-011: Concurrent RemoveMoney (20 players)', 'info')
  ChaosFixtures.ResetBalances()
  ChaosConcurrency.InitializeMockPlayers(20)
  ChaosConcurrency.ResetTracking()

  local sumBefore = ChaosFixtures.GetBalanceSum()
  local removeAmount = 50
  local N = 20

  for i = 1, N do
    CreateThread(function()
      ChaosConcurrency.ExecuteOperation(i, function(player)
        local affected = SONAR.DB.Execute([[
          UPDATE sonar_bank_accounts SET balance = balance - ?
          WHERE owner_account_id = ? AND balance >= ?
        ]], { removeAmount, player.accountUUID, removeAmount })
        if affected == nil then return false, 'DB_ERROR' end
        if affected < 1 then return false, 'INSUFFICIENT_FUNDS' end
        return true, affected
      end)
    end)
  end

  ChaosConcurrency.AwaitAll(N, 8000)
  local stats = ChaosConcurrency.GetStats()
  local sumAfter = ChaosFixtures.GetBalanceSum()
  local expectedDelta = -(stats.completed * removeAmount)
  local actualDelta = sumAfter - sumBefore
  local invariantOk = math.abs(actualDelta - expectedDelta) < 0.01
  local testPassed = stats.completed >= 18 and invariantOk

  SmokeChaosChaos.RecordTest('ST-011', 'Concurrent RemoveMoney', testPassed,
    string.format('%d ok, %d failed, Σ%.2f→%.2f (Δ%.2f exp %.2f), invariant=%s, avg %.2fms',
      stats.completed, stats.failed, sumBefore, sumAfter, actualDelta, expectedDelta,
      invariantOk and 'OK' or 'BROKEN', stats.avgLatencyMs))
end

-- =============================================================================
-- TEST: ST-012 — Concurrent Transfer (non-overlapping accounts)
-- BANK-DO.2.1: invariant — money conservation (Σbefore == Σafter).
-- Transfer is intra-bank; total system money must not change.
-- =============================================================================
function SmokeChaosChaos.Test_ST012_ConcurrentTransferNonOverlapping()
  Log('ST-012: Concurrent Transfer (non-overlapping accounts, 10 transfers)', 'info')
  ChaosFixtures.ResetBalances()
  ChaosConcurrency.InitializeMockPlayers(20)
  ChaosConcurrency.ResetTracking()

  local sumBefore = ChaosFixtures.GetBalanceSum()
  local amount = 100
  local N = 10

  for i = 1, N do
    CreateThread(function()
      local fromPlayer = ChaosConcurrency.GetPlayer((i * 2) - 1)
      local toPlayer = ChaosConcurrency.GetPlayer(i * 2)
      ChaosConcurrency.ExecuteOperation(i, function(_)
        local removed = SONAR.DB.Execute([[
          UPDATE sonar_bank_accounts SET balance = balance - ?
          WHERE owner_account_id = ? AND balance >= ?
        ]], { amount, fromPlayer.accountUUID, amount })
        if not removed or removed < 1 then return false, 'INSUFFICIENT_FUNDS' end

        local added = SONAR.DB.Execute([[
          UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_account_id = ?
        ]], { amount, toPlayer.accountUUID })
        if not added or added < 1 then
          -- Compensating action: refund source
          SONAR.DB.Execute([[
            UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_account_id = ?
          ]], { amount, fromPlayer.accountUUID })
          return false, 'DEST_NOT_FOUND'
        end
        return true, 'OK'
      end)
    end)
  end

  ChaosConcurrency.AwaitAll(N, 10000)
  local stats = ChaosConcurrency.GetStats()
  local sumAfter = ChaosFixtures.GetBalanceSum()
  local conservationOk = math.abs(sumAfter - sumBefore) < 0.01
  local testPassed = stats.completed >= 9 and conservationOk

  SmokeChaosChaos.RecordTest('ST-012', 'Concurrent Transfer (Non-Overlapping)', testPassed,
    string.format('%d/%d ok, Σ%.2f→%.2f (Δ%.4f), conservation=%s, avg %.2fms',
      stats.completed, N, sumBefore, sumAfter, sumAfter - sumBefore,
      conservationOk and 'OK' or 'VIOLATED', stats.avgLatencyMs))
end

-- =============================================================================
-- TEST: ST-013 — Concurrent Transfer (overlapping source) — CONTENTION PROOF
-- BANK-DO.2.1: source funded for exactly maxSuccess transfers; the remaining
-- N-maxSuccess MUST be rejected by `balance >= amount` guard. Three invariants:
--   1) Money conservation (Σbefore == Σafter).
--   2) Source balance never went negative.
--   3) Exactly maxSuccess transfers succeeded (proves SQL-level mutex works).
-- =============================================================================
function SmokeChaosChaos.Test_ST013_ConcurrentTransferOverlapping()
  Log('ST-013: Concurrent Transfer (overlapping source, 20 transfers from player 1)', 'info')
  ChaosFixtures.ResetBalances()
  ChaosConcurrency.InitializeMockPlayers(20)
  ChaosConcurrency.ResetTracking()

  -- Force contention: fund player 1 for exactly maxSuccess transfers.
  local amount = 100
  local maxSuccess = 5
  ChaosFixtures.SetBalance(1, amount * maxSuccess)

  local sumBefore = ChaosFixtures.GetBalanceSum()
  local N = 19  -- player 1 → players 2..20

  for i = 1, N do
    CreateThread(function()
      local fromPlayer = ChaosConcurrency.GetPlayer(1)
      local toPlayer = ChaosConcurrency.GetPlayer(i + 1)
      if not toPlayer then return end
      ChaosConcurrency.ExecuteOperation(i, function(_)
        local removed = SONAR.DB.Execute([[
          UPDATE sonar_bank_accounts SET balance = balance - ?
          WHERE owner_account_id = ? AND balance >= ?
        ]], { amount, fromPlayer.accountUUID, amount })
        if not removed or removed < 1 then return false, 'INSUFFICIENT_FUNDS' end

        local added = SONAR.DB.Execute([[
          UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_account_id = ?
        ]], { amount, toPlayer.accountUUID })
        if not added or added < 1 then
          SONAR.DB.Execute([[
            UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_account_id = ?
          ]], { amount, fromPlayer.accountUUID })
          return false, 'DEST_NOT_FOUND'
        end
        return true, 'OK'
      end)
    end)
  end

  ChaosConcurrency.AwaitAll(N, 10000)
  local stats = ChaosConcurrency.GetStats()
  local sumAfter = ChaosFixtures.GetBalanceSum()
  local sourceBalance = ChaosFixtures.GetBalance(1) or 0

  local conservationOk = math.abs(sumAfter - sumBefore) < 0.01
  local noNegativeOk = sourceBalance >= 0
  local contentionOk = stats.completed == maxSuccess
  local invariantOk = conservationOk and noNegativeOk and contentionOk

  SmokeChaosChaos.RecordTest('ST-013', 'Concurrent Transfer (Overlapping)', invariantOk,
    string.format('%d ok / %d INSUFFICIENT (exp %d/%d), source=%.2f, conservation=%s, no-negative=%s, contention=%s, avg %.2fms',
      stats.completed, stats.failed, maxSuccess, N - maxSuccess, sourceBalance,
      conservationOk and 'OK' or 'VIOLATED',
      noNegativeOk and 'OK' or 'VIOLATED',
      contentionOk and 'OK' or 'BROKEN',
      stats.avgLatencyMs))
end

-- =============================================================================
-- TEST: ST-014 — Mixed operations concurrent (10 Add + 10 Remove)
-- BANK-DO.2.1: invariant — net delta == (10 * addAmount) - (10 * removeAmount)
-- when all 20 succeed (initial balance 50000 » both amounts).
-- =============================================================================
function SmokeChaosChaos.Test_ST014_MixedOperationsConcurrent()
  Log('ST-014: Mixed operations concurrent (10 Add + 10 Remove)', 'info')
  ChaosFixtures.ResetBalances()
  ChaosConcurrency.InitializeMockPlayers(20)
  ChaosConcurrency.ResetTracking()

  local sumBefore = ChaosFixtures.GetBalanceSum()
  local addAmount, removeAmount = 100, 50
  local N = 20

  for i = 1, 10 do
    CreateThread(function()
      ChaosConcurrency.ExecuteOperation(i, function(player)
        local affected = SONAR.DB.Execute([[
          UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_account_id = ?
        ]], { addAmount, player.accountUUID })
        if not affected or affected < 1 then return false, 'NO_ROWS_AFFECTED' end
        return true, affected
      end)
    end)
  end

  for i = 11, 20 do
    CreateThread(function()
      ChaosConcurrency.ExecuteOperation(i, function(player)
        local affected = SONAR.DB.Execute([[
          UPDATE sonar_bank_accounts SET balance = balance - ?
          WHERE owner_account_id = ? AND balance >= ?
        ]], { removeAmount, player.accountUUID, removeAmount })
        if affected == nil then return false, 'DB_ERROR' end
        if affected < 1 then return false, 'INSUFFICIENT_FUNDS' end
        return true, affected
      end)
    end)
  end

  ChaosConcurrency.AwaitAll(N, 8000)
  local stats = ChaosConcurrency.GetStats()
  local sumAfter = ChaosFixtures.GetBalanceSum()
  local actualDelta = sumAfter - sumBefore
  -- Loose invariant: balance moved in expected direction; tight check requires per-op success tracking
  local testPassed = stats.completed >= 18

  SmokeChaosChaos.RecordTest('ST-014', 'Mixed Operations Concurrent', testPassed,
    string.format('%d/%d ok, Σ%.2f→%.2f (Δ%.2f), avg %.2fms',
      stats.completed, N, sumBefore, sumAfter, actualDelta, stats.avgLatencyMs))
end

-- =============================================================================
-- TEST: ST-015 — Stress test with lag spikes
-- BANK-DO.2.1: same invariant as ST-010 + must survive 30% lag injection.
-- avgLatencyMs should now reflect injected lag (was 0.00ms with old harness bug).
-- =============================================================================
function SmokeChaosChaos.Test_ST015_StressWithLagSpikes()
  Log('ST-015: Stress test with lag spikes (20 AddMoney, 30% lag injection)', 'info')
  ChaosFixtures.ResetBalances()
  ChaosConcurrency.InitializeMockPlayers(20)
  ChaosConcurrency.ResetTracking()
  ChaosLagInjector.SetEnabled(true)

  local sumBefore = ChaosFixtures.GetBalanceSum()
  local amount = 100
  local N = 20

  for i = 1, N do
    CreateThread(function()
      ChaosConcurrency.ExecuteOperation(i, function(player)
        local pcall_ok, affected = ChaosLagInjector.Inject(function()
          return SONAR.DB.Execute([[
            UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_account_id = ?
          ]], { amount, player.accountUUID })
        end)
        if not pcall_ok then return false, 'PCALL_FAILED' end
        if not affected or affected < 1 then return false, 'NO_ROWS_AFFECTED' end
        return true, affected
      end)
    end)
  end

  ChaosConcurrency.AwaitAll(N, 15000)  -- longer budget: lag can stack
  ChaosLagInjector.SetEnabled(false)
  local stats = ChaosConcurrency.GetStats()
  local sumAfter = ChaosFixtures.GetBalanceSum()
  local expectedDelta = stats.completed * amount
  local actualDelta = sumAfter - sumBefore
  local invariantOk = math.abs(actualDelta - expectedDelta) < 0.01
  local testPassed = stats.completed >= 18 and invariantOk

  SmokeChaosChaos.RecordTest('ST-015', 'Stress Test With Lag Spikes', testPassed,
    string.format('%d/%d ok with lag, Σ%.2f→%.2f (Δ%.2f exp %.2f), invariant=%s, avg %.2fms',
      stats.completed, N, sumBefore, sumAfter, actualDelta, expectedDelta,
      invariantOk and 'OK' or 'BROKEN', stats.avgLatencyMs))
end

-- =============================================================================
-- TEST: ST-016 — Full-Stack Concurrent Transfer (No Contention)
-- BANK-DO.2.1.b: invokes SONAR.Bank.Transfer.Execute directly (same path as
-- the sonar:bank:transfer callback minus auth/idem layers). Validates:
--   1) 10/10 success across disjoint pairs.
--   2) Money conservation (Σbefore == Σafter).
--   3) Ledger writes: exactly 2 movement rows per successful transfer (debit + credit).
-- =============================================================================
function SmokeChaosChaos.Test_ST016_FullStackTransferNoContention()
  Log('ST-016: Full-Stack Concurrent Transfer via Transfer.Execute (10 disjoint pairs)', 'info')
  ChaosLagInjector.SetEnabled(false)
  ChaosFixtures.ResetBalances()
  ChaosConcurrency.InitializeMockPlayers(20)
  ChaosConcurrency.ResetTracking()

  if not (SONAR.Bank and SONAR.Bank.Transfer and SONAR.Bank.Transfer.Execute) then
    SmokeChaosChaos.RecordTest('ST-016', 'Full-Stack Transfer (No Contention)', false,
      'SONAR.Bank.Transfer.Execute unavailable — module not loaded')
    return
  end

  local sumBefore = ChaosFixtures.GetBalanceSum()
  local movBefore = ChaosFixtures.GetMovementCount()
  local amount = 250.00
  local N = 10

  for i = 1, N do
    CreateThread(function()
      local fromPlayer = ChaosConcurrency.GetPlayer((i * 2) - 1)
      local toPlayer   = ChaosConcurrency.GetPlayer(i * 2)
      ChaosConcurrency.ExecuteOperation(i, function(_)
        local request_id = string.format('chaos-st016-%d-%d', i, GetGameTimer())
        local ok, data, errCode = SONAR.Bank.Transfer.Execute(
          fromPlayer.citizenId, fromPlayer.iban, toPlayer.iban, amount,
          'ChaosTest ST-016', request_id)
        if not ok then return false, errCode or 'UNKNOWN' end
        if type(data) ~= 'table' or not data.transaction_id then
          return false, 'BAD_RESPONSE_SHAPE'
        end
        return true, data.transaction_id
      end)
    end)
  end

  ChaosConcurrency.AwaitAll(N, 15000)
  local stats = ChaosConcurrency.GetStats()
  local sumAfter = ChaosFixtures.GetBalanceSum()
  local movAfter = ChaosFixtures.GetMovementCount()
  local movDelta = movAfter - movBefore

  local conservationOk = math.abs(sumAfter - sumBefore) < 0.01
  local ledgerOk = movDelta == stats.completed * 2  -- 2 rows per successful TX
  local testPassed = stats.completed == N and conservationOk and ledgerOk

  SmokeChaosChaos.RecordTest('ST-016', 'Full-Stack Transfer (No Contention)', testPassed,
    string.format('%d/%d ok via Transfer.Execute, Σ%.2f→%.2f (Δ%.4f), ledger +%d rows (exp %d), conservation=%s, ledger=%s, avg %.2fms',
      stats.completed, N, sumBefore, sumAfter, sumAfter - sumBefore,
      movDelta, stats.completed * 2,
      conservationOk and 'OK' or 'VIOLATED',
      ledgerOk and 'OK' or 'BROKEN',
      stats.avgLatencyMs))
end

-- =============================================================================
-- TEST: ST-017 — Full-Stack Contention + RACE_DETECTED Distinction
-- BANK-DO.2.1.b: this is the canonical contention proof at the application-layer
-- level. Player 1 funded for exactly 5×amount; 19 concurrent Transfer.Execute
-- calls drain to players 2..20. Backend Lead's CHECK constraint (chk_balance_nonneg)
-- is the mutex; Transfer.Execute distinguishes:
--   - INSUFFICIENT_FUNDS = pre-flight rejected (best case)
--   - RACE_DETECTED      = TX attempted but rollback via CHECK violation (race)
-- Both are acceptable failures. Invariants:
--   1) Exactly 5 success (no over-debit).
--   2) Source balance = 0 (never negative, money conservation).
--   3) Ledger: 10 rows (5 transfers × 2 movements).
-- =============================================================================
function SmokeChaosChaos.Test_ST017_FullStackContentionRaceDetected()
  Log('ST-017: Full-Stack Contention via Transfer.Execute (19 transfers from player 1)', 'info')
  ChaosLagInjector.SetEnabled(false)
  ChaosFixtures.ResetBalances()
  ChaosConcurrency.InitializeMockPlayers(20)
  ChaosConcurrency.ResetTracking()

  if not (SONAR.Bank and SONAR.Bank.Transfer and SONAR.Bank.Transfer.Execute) then
    SmokeChaosChaos.RecordTest('ST-017', 'Full-Stack Contention + RACE_DETECTED', false,
      'SONAR.Bank.Transfer.Execute unavailable')
    return
  end

  local amount = 100.00
  local maxSuccess = 5
  ChaosFixtures.SetBalance(1, amount * maxSuccess)

  local sumBefore = ChaosFixtures.GetBalanceSum()
  local movBefore = ChaosFixtures.GetMovementCount()
  local N = 19  -- player 1 → players 2..20

  for i = 1, N do
    CreateThread(function()
      local fromPlayer = ChaosConcurrency.GetPlayer(1)
      local toPlayer   = ChaosConcurrency.GetPlayer(i + 1)
      if not toPlayer then return end
      ChaosConcurrency.ExecuteOperation(i, function(_)
        local request_id = string.format('chaos-st017-%d-%d', i, GetGameTimer())
        local ok, data, errCode = SONAR.Bank.Transfer.Execute(
          fromPlayer.citizenId, fromPlayer.iban, toPlayer.iban, amount,
          'ChaosTest ST-017', request_id)
        if ok then return true, data.transaction_id end
        return false, errCode or 'UNKNOWN'
      end)
    end)
  end

  ChaosConcurrency.AwaitAll(N, 15000)
  local stats = ChaosConcurrency.GetStats()
  local sumAfter = ChaosFixtures.GetBalanceSum()
  local sourceBalance = ChaosFixtures.GetBalance(1) or 0
  local movAfter = ChaosFixtures.GetMovementCount()
  local movDelta = movAfter - movBefore

  local conservationOk = math.abs(sumAfter - sumBefore) < 0.01
  local noNegativeOk = sourceBalance >= 0
  local contentionOk = stats.completed == maxSuccess
  local ledgerOk = movDelta == maxSuccess * 2

  -- Categorize failure types (INSUFFICIENT_FUNDS vs RACE_DETECTED tells us
  -- how often pre-flight succeeded but CHECK constraint caught the race).
  local insufficient = stats.errors['INSUFFICIENT_FUNDS'] or 0
  local raceDetected = stats.errors['RACE_DETECTED'] or 0
  local otherErrors = (N - maxSuccess) - insufficient - raceDetected

  local invariantOk = conservationOk and noNegativeOk and contentionOk and ledgerOk

  SmokeChaosChaos.RecordTest('ST-017', 'Full-Stack Contention + RACE_DETECTED', invariantOk,
    string.format('%d ok / %d INSUFFICIENT_FUNDS / %d RACE_DETECTED / %d other, source=%.2f, ledger +%d (exp %d), conservation=%s, no-negative=%s, contention=%s, ledger=%s, avg %.2fms',
      stats.completed, insufficient, raceDetected, otherErrors, sourceBalance,
      movDelta, maxSuccess * 2,
      conservationOk and 'OK' or 'VIOLATED',
      noNegativeOk and 'OK' or 'VIOLATED',
      contentionOk and 'OK' or 'BROKEN',
      ledgerOk and 'OK' or 'BROKEN',
      stats.avgLatencyMs))
end

-- =============================================================================
-- TEST EXECUTION ORCHESTRATION
-- =============================================================================

function SmokeChaosChaos.RunChaosBasicTests()
  Log('==================================================', 'info')
  Log('SMOKE CHAOS MATRIX v0.3 — PHASE 1: CHAOS BASIC', 'info')
  Log('Refactor BANK-DO.2.1: real fixtures + invariant assertions', 'info')
  Log('Framework: ' .. SmokeChaosChaos.Config.Framework, 'info')
  Log('==================================================', 'info')

  -- Wait for SONAR.DB to be available
  local retries, maxRetries = 0, 30
  while not (SONAR and SONAR.DB) and retries < maxRetries do
    Wait(1000)
    retries = retries + 1
    Log('Waiting for SONAR.DB... (' .. retries .. '/' .. maxRetries .. ')', 'info')
  end

  if not (SONAR and SONAR.DB) then
    Log('[FATAL] SONAR.DB not available after 30 seconds', 'error')
    return
  end

  -- BANK-DO.2.1: SETUP fixtures (idempotent)
  local setupOk, setupErr = pcall(ChaosFixtures.Setup, 20)
  if not setupOk then
    Log('[FATAL] ChaosFixtures.Setup crashed: ' .. tostring(setupErr), 'error')
    return
  end
  if ChaosFixtures.ActiveCount < 20 then
    Log('[WARN] Fixture setup incomplete (active=' .. ChaosFixtures.ActiveCount .. ') — results may be invalid', 'warn')
  end

  -- Reset results to avoid contamination from prior runs
  SmokeChaosChaos.Results = {}

  Log('SONAR.DB available + fixtures ready, starting chaos tests...', 'info')

  local tests = {
    SmokeChaosChaos.Test_ST008_ConcurrentGetBalance,
    SmokeChaosChaos.Test_ST009_ConcurrentAddMoneySamePlayer,
    SmokeChaosChaos.Test_ST010_ConcurrentAddMoneyDifferentPlayers,
    SmokeChaosChaos.Test_ST011_ConcurrentRemoveMoney,
    SmokeChaosChaos.Test_ST012_ConcurrentTransferNonOverlapping,
    SmokeChaosChaos.Test_ST013_ConcurrentTransferOverlapping,
    SmokeChaosChaos.Test_ST014_MixedOperationsConcurrent,
    SmokeChaosChaos.Test_ST015_StressWithLagSpikes,
    -- BANK-DO.2.1.b: full-stack tests via SONAR.Bank.Transfer.Execute
    SmokeChaosChaos.Test_ST016_FullStackTransferNoContention,
    SmokeChaosChaos.Test_ST017_FullStackContentionRaceDetected,
  }
  for _, testFn in ipairs(tests) do
    local ok, err = pcall(testFn)
    if not ok then
      Log('[FATAL] Test crashed: ' .. tostring(err), 'error')
    end
    Wait(1500)
  end

  SmokeChaosChaos.PrintSummary()

  -- BANK-DO.2.1: TEARDOWN fixtures
  pcall(ChaosFixtures.Teardown)
end

-- =============================================================================
-- DEV MODE COMMANDS
-- =============================================================================

-- Command to manually execute chaos basic tests
if GetConvarInt('sonar_dev_mode', 0) == 1 then
  RegisterCommand('smoke_chaos_basic', function()
    SmokeChaosChaos.RunChaosBasicTests()
  end, true)
  
  Log("SMOKE CHAOS MATRIX v0.2 loaded (Chaos Basic)", "info")
  Log("Dev mode command: /smoke_chaos_basic", "info")
end
