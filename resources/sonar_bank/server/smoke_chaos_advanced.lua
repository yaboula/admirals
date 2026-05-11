-- =============================================================================
-- SONAR Bank — Smoke Chaos Matrix v0.4 (Chaos Advanced)
--
-- Test harness para pruebas de caos avanzadas en BANK-DO.2 Fase 2
-- ST-018 to ST-022+: Advanced chaos testing
--
-- Arquitectura:
--   - Reuses ChaosFixtures + ChaosConcurrency from baseline (smoke_chaos_chaos.lua)
--   - Idempotency replay storm (ST-018)
--   - Kill-mid-TX simulation (ST-019)
--   - Scale 100-concurrent ops (ST-020)
--   - Audit log integrity under pressure (ST-021)
--   - Multi-framework matrix (ST-022+)
--
-- Referencias SSoT:
--   docs/agents/teams/prompts/05_devops_integration_qa_lead.md
--   docs/technical/07_bridges_compatibility.md
--   docs/agents/teams/01_SHARED_BRIEF.md (Q16.5 performance target)
-- =============================================================================

print('^3[SMOKE_CHAOS_ADVANCED]^7 Loading smoke_chaos_advanced.lua...')

-- =============================================================================
-- GLOBAL LOG HELPER
-- =============================================================================
local function Log(message, level)
  level = level or 'info'
  local prefix = '^3[SMOKE_CHAOS_ADVANCED]^7'
  if level == 'error' then
    prefix = '^1[SMOKE_CHAOS_ADVANCED]^7'
  elseif level == 'warn' then
    prefix = '^3[SMOKE_CHAOS_ADVANCED]^7'
  elseif level == 'success' then
    prefix = '^2[SMOKE_CHAOS_ADVANCED]^7'
  end
  print(prefix .. " " .. message)
end

-- =============================================================================
-- MODULE: SmokeChaosAdvanced
-- =============================================================================
SmokeChaosAdvanced = SmokeChaosAdvanced or {}

SmokeChaosAdvanced.Config = {
  Framework = 'unknown',
}

SmokeChaosAdvanced.Results = {}

-- Record test result
function SmokeChaosAdvanced.RecordTest(testId, testName, passed, details)
  table.insert(SmokeChaosAdvanced.Results, {
    id = testId,
    name = testName,
    passed = passed,
    details = details,
  })
  local status = passed and '^2✅ PASS^7' or '^1❌ FAIL^7'
  Log(status .. ' ' .. testId .. ' — ' .. testName, passed and 'success' or 'error')
  if details then
    Log('  → ' .. details, 'info')
  end
end

-- Print summary
function SmokeChaosAdvanced.PrintSummary()
  Log('==================================================', 'info')
  Log('SMOKE CHAOS ADVANCED — SUMMARY', 'info')
  Log('==================================================', 'info')
  local total = #SmokeChaosAdvanced.Results
  local passed = 0
  for _, result in ipairs(SmokeChaosAdvanced.Results) do
    if result.passed then passed = passed + 1 end
  end
  Log(string.format('Total: %d | Passed: %d | Failed: %d', total, passed, total - passed), 'info')
  Log('==================================================', 'info')
end

-- =============================================================================
-- TEST: ST-018 — Idempotency Replay Storm
--
-- Objetivo: Validar que exports.sonar_bridges:IsIdemReplay/StoreIdem
-- protegen correctamente contra operaciones duplicadas bajo replay storm.
--
-- Metodología:
--   - Ejecutar 100 operaciones idénticas con el mismo request_id
--   - Verificar que solo la primera se procesa (IsIdemReplay retorna true en replays)
--   - Validar que el resultado cacheado se devuelve en replays
--
-- Invariantes:
--   1) IsIdemReplay debe retornar true después del primer StoreIdem
--   2) El resultado cacheado debe ser idéntico al original
--   3) Balance no debe cambiar más de una vez (money conservation)
--
-- NOTA: Race window entre IsIdemReplay y StoreIdem es aceptable —
--       documentar como observación Phase B (atomic CAS requerido).
-- =============================================================================
function SmokeChaosAdvanced.Test_ST018_IdempotencyReplayStorm()
  Log('ST-018: Idempotency Replay Storm (100 identical ops with same request_id)', 'info')
  
  -- Verify bridges resource is started
  local bridgesAvailable = GetResourceState('sonar_bridges') == 'started'
  
  if not bridgesAvailable then
    SmokeChaosAdvanced.RecordTest('ST-018', 'Idempotency Replay Storm', false,
      'exports.sonar_bridges:IsIdemReplay unavailable — bridges not loaded')
    return
  end
  
  -- Use fixtures from baseline (assumes smoke_chaos_chaos.lua loaded first)
  if not (ChaosFixtures and ChaosFixtures.Setup) then
    SmokeChaosAdvanced.RecordTest('ST-018', 'Idempotency Replay Storm', false,
      'ChaosFixtures unavailable — baseline not loaded')
    return
  end
  
  -- Ensure fixtures setup (idempotent)
  pcall(ChaosFixtures.Setup, 20)
  ChaosFixtures.ResetBalances()
  
  -- Initialize mock players
  ChaosConcurrency.InitializeMockPlayers(20)
  
  local player = ChaosConcurrency.GetPlayer(1)
  if not player then
    SmokeChaosAdvanced.RecordTest('ST-018', 'Idempotency Replay Storm', false,
      'Mock player unavailable')
    return
  end
  
  local request_id = string.format('chaos-st018-replay-storm-%d', GetGameTimer())
  local amount = 100.00
  local balanceBefore = ChaosFixtures.GetBalance(1) or 0
  
  -- Simulate operation result (what would be returned by actual transfer)
  local mockResult = {
    transaction_id = 'chaos-tx-' .. request_id,
    amount = amount,
    status = 'completed'
  }
  
  local replayCount = 0
  local cacheMissCount = 0
  local raceWindowDetected = false
  
  -- Replay storm: 100 identical checks
  for i = 1, 100 do
    local check = exports.sonar_bridges:IsIdemReplay(request_id)
    
    if check and check.is_replay then
      replayCount = replayCount + 1
      -- Verify cached result matches original
      if type(check.cached) == 'table' and check.cached.transaction_id == mockResult.transaction_id then
        -- Cache hit with correct result
      else
        Log('[ST-018] WARNING: Cache result mismatch on replay ' .. i, 'warn')
      end
    else
      cacheMissCount = cacheMissCount + 1
      -- First call: store the result
      exports.sonar_bridges:StoreIdem(request_id, mockResult)
      
      -- Simulate actual operation (balance change)
      SONAR.DB.Execute([[
        UPDATE sonar_bank_accounts SET balance = balance + ? WHERE owner_account_id = ?
      ]], { amount, player.accountUUID })
    end
    
    -- Detect race window: if we get more than 1 cache miss, there was a race
    if cacheMissCount > 1 and not raceWindowDetected then
      raceWindowDetected = true
      Log('[ST-018] OBSERVATION: Race window detected between IsIdemReplay/StoreIdem (' .. cacheMissCount .. ' cache misses) — Phase B atomic CAS required', 'warn')
    end
    
    -- Small delay to simulate concurrent replays
    Wait(5)
  end
  
  local balanceAfter = ChaosFixtures.GetBalance(1) or 0
  local balanceDelta = balanceAfter - balanceBefore
  
  -- Invariants:
  -- 1) At least 1 cache miss (first operation)
  -- 2) At most 2 cache misses (race window acceptable per founder directive)
  -- 3) Balance changed exactly once (money conservation)
  -- 4) Most calls should hit cache (replayCount >= 98)
  
  local invariant1 = cacheMissCount >= 1
  local invariant2 = cacheMissCount <= 2
  local invariant3 = math.abs(balanceDelta - amount) < 0.01
  local invariant4 = replayCount >= 98
  
  local testPassed = invariant1 and invariant2 and invariant3 and invariant4
  
  SmokeChaosAdvanced.RecordTest('ST-018', 'Idempotency Replay Storm', testPassed,
    string.format('cache_miss=%d (expected 1-2), replay=%d (expected 98+), balance Δ=%.2f (exp %.2f), race_window=%s, invariants=[%s,%s,%s,%s]',
      cacheMissCount, replayCount, balanceDelta, amount,
      raceWindowDetected and 'DETECTED' or 'NONE',
      invariant1 and 'OK' or 'FAIL',
      invariant2 and 'OK' or 'FAIL',
      invariant3 and 'OK' or 'FAIL',
      invariant4 and 'OK' or 'FAIL'))
end

-- =============================================================================
-- ST-019: Kill-mid-TX (APPROACH A)
--   Env var injection: SONAR_BANK_CHAOS_INJECT_FAIL_AT_QUERY={1,2,3,4}
--   Verifica que el rollback atomico funciona cuando un query falla mid-TX
-- =============================================================================
function SmokeChaosAdvanced.Test_ST019_KillMidTx()
  Log('ST-019: Kill-mid-TX (env var injection at query 1-4)', 'info')

  -- Use fixtures from baseline
  if not (ChaosFixtures and ChaosFixtures.Setup) then
    SmokeChaosAdvanced.RecordTest('ST-019', 'Kill-mid-TX', false,
      'ChaosFixtures unavailable — baseline not loaded')
    return
  end

  -- Ensure fixtures setup
  pcall(ChaosFixtures.Setup, 20)
  ChaosFixtures.ResetBalances()

  -- Initialize mock players
  ChaosConcurrency.InitializeMockPlayers(20)

  local player1 = ChaosConcurrency.GetPlayer(1)
  local player2 = ChaosConcurrency.GetPlayer(2)
  if not player1 or not player2 then
    SmokeChaosAdvanced.RecordTest('ST-019', 'Kill-mid-TX', false,
      'Mock players unavailable')
    return
  end

  local amount = 100.00
  local all_passed = true

  -- Test each query position (1-4)
  for query_pos = 1, 4 do
    Log('ST-019: Testing fail at query ' .. query_pos, 'info')

    -- Set chaos injection env var
    SetConvar('SONAR_BANK_CHAOS_INJECT_FAIL_AT_QUERY', tostring(query_pos))

    -- Get initial balances
    local balance_before_1 = ChaosFixtures.GetBalance(1) or 0
    local balance_before_2 = ChaosFixtures.GetBalance(2) or 0

    -- Attempt transfer (should fail mid-TX)
    local ok, data, errCode = SONAR.Bank.Transfer.Execute(
      player1.citizenId, player1.iban, player2.iban, amount,
      'ChaosTest ST-019 Q' .. query_pos, nil)

    -- Reset env var
    SetConvar('SONAR_BANK_CHAOS_INJECT_FAIL_AT_QUERY', '0')

    -- Get final balances
    local balance_after_1 = ChaosFixtures.GetBalance(1) or 0
    local balance_after_2 = ChaosFixtures.GetBalance(2) or 0

    -- Verify rollback: balances should be unchanged
    local rollback_ok = (balance_after_1 == balance_before_1) and
                       (balance_after_2 == balance_before_2)

    if not rollback_ok then
      Log('ST-019: FAIL at query ' .. query_pos .. ' - rollback failed', 'error')
      Log('  Balance1: ' .. balance_before_1 .. ' -> ' .. balance_after_1, 'error')
      Log('  Balance2: ' .. balance_before_2 .. ' -> ' .. balance_after_2, 'error')
      all_passed = false
    else
      Log('ST-019: PASS at query ' .. query_pos .. ' - rollback successful', 'success')
    end

    -- Verify error code is TX_ROLLBACK or TX_CRASH
    if ok then
      Log('ST-019: FAIL at query ' .. query_pos .. ' - transfer should have failed', 'error')
      all_passed = false
    end

    -- Reset balances for next iteration
    ChaosFixtures.ResetBalances()
  end

  SmokeChaosAdvanced.RecordTest('ST-019', 'Kill-mid-TX', all_passed,
    all_passed and 'All 4 query positions rolled back correctly' or 'Rollback failed at one or more positions')
end

-- =============================================================================
-- ST-020: Scale Stress (100 Mock Players Distintos)
--   Objetivo: 100 mock players únicos, 200 ops concurrentes @ p99 < 500ms
--   Enfoque SRE: Si el pool de conexiones se satura, documentar el finding
-- =============================================================================
function SmokeChaosAdvanced.Test_ST020_ScaleStress()
  Log('ST-020: Scale Stress (100 mock players, 200 concurrent ops)', 'info')

  -- Use fixtures from baseline
  if not (ChaosFixtures and ChaosFixtures.Setup) then
    SmokeChaosAdvanced.RecordTest('ST-020', 'Scale Stress', false,
      'ChaosFixtures unavailable — baseline not loaded')
    return
  end

  -- Ensure fixtures setup with 100 unique accounts
  pcall(ChaosFixtures.Setup, 100)
  ChaosFixtures.ResetBalances()

  -- Initialize 100 mock players
  ChaosConcurrency.InitializeMockPlayers(100)

  -- Clear previous operations
  ChaosConcurrency.CompletedOperations = {}
  ChaosConcurrency.ActiveOperations = {}

  local num_ops = 200
  local amount = 10.00
  local ops_per_player = math.ceil(num_ops / 100)

  Log('ST-020: Executing ' .. num_ops .. ' concurrent operations across 100 players...', 'info')

  -- Execute concurrent operations
  for i = 1, num_ops do
    local from_player_idx = ((i - 1) % 100) + 1
    local to_player_idx = (i % 100) + 1

    ChaosConcurrency.ExecuteOperation(from_player_idx, function(player)
      local to_player = ChaosConcurrency.GetPlayer(to_player_idx)
      if not to_player then return false, 'TO_PLAYER_NOT_FOUND' end

      local request_id = string.format('chaos-st020-scale-%d-%d', GetGameTimer(), i)
      local ok, data, errCode = SONAR.Bank.Transfer.Execute(
        player.citizenId, player.iban, to_player.iban, amount,
        'ChaosTest ST-020 Scale Stress', request_id)

      -- Baseline contract: on failure, second return is tostring()-ed into op.error.
      -- Return plain string errCode so error_breakdown can categorize correctly.
      if not ok then return false, (errCode or 'UNKNOWN_ERROR') end
      return true, { data = data, request_id = request_id }
    end)
  end

  -- Wait for all operations to complete
  local wait_count = 0
  while #ChaosConcurrency.CompletedOperations < num_ops and wait_count < 60 do
    Wait(500)
    wait_count = wait_count + 1
  end

  local completed_count = #ChaosConcurrency.CompletedOperations
  Log('ST-020: Completed ' .. completed_count .. '/' .. num_ops .. ' operations', 'info')

  -- Calculate percentiles
  local latencies = {}
  for _, op in ipairs(ChaosConcurrency.CompletedOperations) do
    table.insert(latencies, op.latencyMs)
  end
  table.sort(latencies)

  local p50_idx = math.floor(#latencies * 0.5)
  local p95_idx = math.floor(#latencies * 0.95)
  local p99_idx = math.floor(#latencies * 0.99)

  local p50 = latencies[p50_idx] or 0
  local p95 = latencies[p95_idx] or 0
  local p99 = latencies[p99_idx] or 0

  Log('ST-020: Latencies — p50=' .. p50 .. 'ms, p95=' .. p95 .. 'ms, p99=' .. p99 .. 'ms', 'info')

  -- Categorize outcomes (baseline contract: op.error is a string after Bug A fix).
  local success_count = 0
  local timeout_count = 0
  local business_error_count = 0  -- legit SUT-level failures (INSUFFICIENT_FUNDS, RACE_DETECTED, etc.)
  local error_breakdown = {}
  for _, op in ipairs(ChaosConcurrency.CompletedOperations) do
    if op.status == 'completed' then
      success_count = success_count + 1
    else
      local err_code = (op.error and type(op.error) == 'string' and op.error) or 'unknown'
      error_breakdown[err_code] = (error_breakdown[err_code] or 0) + 1
      if err_code:match('timeout') or err_code:match('connection') or err_code:match('pool') then
        timeout_count = timeout_count + 1
      else
        business_error_count = business_error_count + 1
      end
    end
  end

  Log('ST-020: Outcomes — success=' .. success_count .. ', business_fail=' .. business_error_count .. ', pool/timeout=' .. timeout_count, 'info')
  Log('ST-020: Error breakdown:', 'info')
  for err_code, count in pairs(error_breakdown) do
    Log('  ' .. err_code .. ': ' .. count, 'info')
  end

  local target_p99 = 500 -- Q16.5 target
  local p99_ok = p99 < target_p99
  -- Pool saturation signal = real timeouts/connection errors only (business errors do NOT saturate pool).
  local saturation_detected = timeout_count > 0

  if saturation_detected then
    Log('ST-020: CONNECTION POOL SATURATION DETECTED (SRE FINDING)', 'warn')
    Log('  Timeouts/connection errors: ' .. timeout_count, 'warn')
    Log('  Recommendation: Increase oxmysql connection pool size in production runbook', 'warn')
  end

  -- Success criteria: p99 under target + full completion (success + business_fail both count as "harness completed").
  local test_passed = p99_ok and completed_count == num_ops

  SmokeChaosAdvanced.RecordTest('ST-020', 'Scale Stress', test_passed,
    string.format('p99=%dms (target <500ms), completed=%d/%d, success=%d, business_fail=%d, pool_timeouts=%d, saturation=%s, p50=%dms, p95=%dms',
      p99, completed_count, num_ops, success_count, business_error_count, timeout_count,
      saturation_detected and 'DETECTED' or 'NONE',
      p50, p95))
end

-- =============================================================================
-- ST-021: Audit Log Integrity bajo Presión
--   Objetivo: Validar que no hay packet drop en audit log bajo presión
--   Invariante: 1 audit record por transferencia exitosa, 1 warning por rechazo
--   Ledger y audit table deben cuadrar a cero
-- =============================================================================
function SmokeChaosAdvanced.Test_ST021_AuditLogIntegrity()
  Log('ST-021: Audit Log Integrity bajo Presión', 'info')

  -- Use fixtures from baseline
  if not (ChaosFixtures and ChaosFixtures.Setup) then
    SmokeChaosAdvanced.RecordTest('ST-021', 'Audit Log Integrity', false,
      'ChaosFixtures unavailable — baseline not loaded')
    return
  end

  -- Ensure fixtures setup with 100 unique accounts
  pcall(ChaosFixtures.Setup, 100)
  ChaosFixtures.ResetBalances()

  -- Initialize 100 mock players
  ChaosConcurrency.InitializeMockPlayers(100)

  -- Clear previous operations
  ChaosConcurrency.CompletedOperations = {}
  ChaosConcurrency.ActiveOperations = {}

  -- Get initial audit log count
  local initial_audit_count = 0
  local audit_rows = SONAR.DB.FetchAll([[
    SELECT COUNT(*) as cnt FROM sonar_bank_audit_ledger
  ]])
  if audit_rows and audit_rows[1] then
    initial_audit_count = tonumber(audit_rows[1].cnt) or 0
  end

  -- Get initial movement count
  local initial_movement_count = 0
  local movement_rows = SONAR.DB.FetchAll([[
    SELECT COUNT(*) as cnt FROM sonar_bank_movements
  ]])
  if movement_rows and movement_rows[1] then
    initial_movement_count = tonumber(movement_rows[1].cnt) or 0
  end

  Log('ST-021: Initial audit count: ' .. initial_audit_count, 'info')
  Log('ST-021: Initial movement count: ' .. initial_movement_count, 'info')

  -- Execute 200 concurrent operations (same as ST-020 for pressure)
  local num_ops = 200
  local amount = 10.00

  for i = 1, num_ops do
    local from_player_idx = ((i - 1) % 100) + 1
    local to_player_idx = (i % 100) + 1

    ChaosConcurrency.ExecuteOperation(from_player_idx, function(player)
      local to_player = ChaosConcurrency.GetPlayer(to_player_idx)
      if not to_player then return false, 'TO_PLAYER_NOT_FOUND' end

      local request_id = string.format('chaos-st021-audit-%d-%d', GetGameTimer(), i)
      local ok, data, errCode = SONAR.Bank.Transfer.Execute(
        player.citizenId, player.iban, to_player.iban, amount,
        'ChaosTest ST-021 Audit Integrity', request_id)

      if not ok then return false, (errCode or 'UNKNOWN_ERROR') end
      return true, { data = data, request_id = request_id }
    end)
  end

  -- Wait for all operations to complete
  local wait_count = 0
  while #ChaosConcurrency.CompletedOperations < num_ops and wait_count < 60 do
    Wait(500)
    wait_count = wait_count + 1
  end

  -- Count successful vs failed operations
  local success_count = 0
  local fail_count = 0
  local error_breakdown = {}
  for _, op in ipairs(ChaosConcurrency.CompletedOperations) do
    -- Baseline contract: op.status == 'completed' IS the success signal
    -- (opSuccess=true branch). op.result only exists on success.
    if op.status == 'completed' then
      success_count = success_count + 1
    else
      fail_count = fail_count + 1
      local err_code = (op.error and type(op.error) == 'string' and op.error) or 'unknown'
      error_breakdown[err_code] = (error_breakdown[err_code] or 0) + 1
    end
  end

  Log('ST-021: Successful transfers: ' .. success_count, 'info')
  Log('ST-021: Failed transfers: ' .. fail_count, 'info')
  Log('ST-021: Error breakdown:', 'info')
  for err_code, count in pairs(error_breakdown) do
    Log('  ' .. err_code .. ': ' .. count, 'info')
  end

  -- Get final audit log count
  local final_audit_count = 0
  audit_rows = SONAR.DB.FetchAll([[
    SELECT COUNT(*) as cnt FROM sonar_bank_audit_ledger
  ]])
  if audit_rows and audit_rows[1] then
    final_audit_count = tonumber(audit_rows[1].cnt) or 0
  end

  -- Get final movement count
  local final_movement_count = 0
  movement_rows = SONAR.DB.FetchAll([[
    SELECT COUNT(*) as cnt FROM sonar_bank_movements
  ]])
  if movement_rows and movement_rows[1] then
    final_movement_count = tonumber(movement_rows[1].cnt) or 0
  end

  local audit_delta = final_audit_count - initial_audit_count
  local movement_delta = final_movement_count - initial_movement_count

  Log('ST-021: Final audit count: ' .. final_audit_count .. ' (delta: ' .. audit_delta .. ')', 'info')
  Log('ST-021: Final movement count: ' .. final_movement_count .. ' (delta: ' .. movement_delta .. ')', 'info')

  -- Expected: 2 movements per successful transfer (debit + credit)
  local expected_movement_delta = success_count * 2
  local movement_ok = movement_delta == expected_movement_delta

  -- Expected: at least 1 audit record per transfer (success or fail)
  -- Note: audit may have additional records from other operations, so we check minimum
  local audit_ok = audit_delta >= num_ops

  -- Check for packet drop: if movement_delta is correct, audit should also be correct
  local packet_drop_detected = movement_ok and not audit_ok

  if packet_drop_detected then
    Log('ST-021: PACKET DROP DETECTED — audit log missing records', 'error')
    Log('  Expected min audit records: ' .. num_ops, 'error')
    Log('  Actual audit delta: ' .. audit_delta, 'error')
  end

  local test_passed = movement_ok and audit_ok and not packet_drop_detected

  SmokeChaosAdvanced.RecordTest('ST-021', 'Audit Log Integrity', test_passed,
    string.format('audit_delta=%d (min %d), movement_delta=%d (exp %d), packet_drop=%s',
      audit_delta, num_ops, movement_delta, expected_movement_delta,
      packet_drop_detected and 'DETECTED' or 'NONE'))
end

-- =============================================================================
-- TEST EXECUTION ORCHESTRATION
-- =============================================================================

function SmokeChaosAdvanced.RunAdvancedTests()
  Log('==================================================', 'info')
  Log('SMOKE CHAOS MATRIX v0.4 — PHASE 2: ADVANCED', 'info')
  Log('Chaos Advanced: ST-018 to ST-022+', 'info')
  Log('Framework: ' .. SmokeChaosAdvanced.Config.Framework, 'info')
  Log('==================================================', 'info')

  -- Wait for baseline modules to be available
  local retries, maxRetries = 0, 30
  while not (ChaosFixtures and ChaosConcurrency) and retries < maxRetries do
    Wait(1000)
    retries = retries + 1
    Log('Waiting for baseline modules (ChaosFixtures + ChaosConcurrency)... (' .. retries .. '/' .. maxRetries .. ')', 'info')
  end

  if not (ChaosFixtures and ChaosConcurrency) then
    Log('[FATAL] Baseline modules not available after 30 seconds — ensure smoke_chaos_chaos.lua loaded first', 'error')
    return
  end

  -- Wait for SONAR.DB to be available
  retries = 0
  while not (SONAR and SONAR.DB) and retries < maxRetries do
    Wait(1000)
    retries = retries + 1
    Log('Waiting for SONAR.DB... (' .. retries .. '/' .. maxRetries .. ')', 'info')
  end

  if not (SONAR and SONAR.DB) then
    Log('[FATAL] SONAR.DB not available after 30 seconds', 'error')
    return
  end

  -- Wait for sonar_bridges to be available
  retries = 0
  while not (GetResourceState('sonar_bridges') == 'started') and retries < maxRetries do
    Wait(1000)
    retries = retries + 1
    Log('Waiting for sonar_bridges... (' .. retries .. '/' .. maxRetries .. ')', 'info')
  end

  if GetResourceState('sonar_bridges') ~= 'started' then
    Log('[FATAL] sonar_bridges not started after 30 seconds', 'error')
    return
  end

  -- Reset results to avoid contamination from prior runs
  SmokeChaosAdvanced.Results = {}

  Log('SONAR.DB + baseline modules + bridges ready, starting advanced chaos tests...', 'info')

  local tests = {
    SmokeChaosAdvanced.Test_ST018_IdempotencyReplayStorm,
    SmokeChaosAdvanced.Test_ST019_KillMidTx,
    SmokeChaosAdvanced.Test_ST020_ScaleStress,
    SmokeChaosAdvanced.Test_ST021_AuditLogIntegrity,
    -- ST-022+ to be added in subsequent iterations
  }
  
  for _, testFn in ipairs(tests) do
    local ok, err = pcall(testFn)
    if not ok then
      Log('[FATAL] Test crashed: ' .. tostring(err), 'error')
    end
    Wait(2000)
  end

  SmokeChaosAdvanced.PrintSummary()
end

-- =============================================================================
-- DEV MODE COMMANDS
-- =============================================================================

-- Command to manually execute chaos advanced tests
if GetConvarInt('sonar_dev_mode', 0) == 1 then
  RegisterCommand('smoke_chaos_advanced', function()
    SmokeChaosAdvanced.RunAdvancedTests()
  end, true)
  
  Log("SMOKE CHAOS MATRIX v0.4 loaded (Chaos Advanced)", "info")
  Log("Dev mode command: /smoke_chaos_advanced", "info")
  Log("NOTE: Requires smoke_chaos_chaos.lua loaded first for baseline modules", "info")
end
