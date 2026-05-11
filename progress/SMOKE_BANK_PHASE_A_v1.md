# SMOKE BANK PHASE A v1.0

> **Owner:** DevOps, Integration & QA Lead
> **Status:** 🟡 v0.1 DRAFT
> **Fecha:** 2026-05-11
> **Baseline:** BANK-IT.1 (7 bugs resueltos Round 1)

---

## 0. Resumen Ejecutivo

Matriz de caos de 55 tests (ST-001 a ST-055) para validar SONAR Bank Phase A antes de shipping. Cubre regresión, multi-framework, lag spike injection, reconciliación concurrente, watchdog metrics y validación de producción.

**Framework target priority:** QBox → QBCore → ESX 1.10+ (intentional failure ESX legacy <1.10)

---

## 1. ST-001 a ST-007: Regression Tests (BANK-IT.1 Baseline)

**Objetivo:** Validar que los 7 bugs de Round 1 no regresan.

| ID | Test | Bug Reference | Framework | Pas/Fail Criteria |
|---|---|---|---|---|
| **ST-001** | Database Collation Validation | Bug #1 (collation mismatch) | All | `sonar_bank_*` tables use `utf8mb4_unicode_ci` |
| **ST-002** | IBAN Regex Robustness | Bug #2 (IBAN validation) | All | Malicious formats rejected, valid formats accepted |
| **ST-003** | ox_lib Client Handshake | Bug #3 (missing ox_lib client) | All | `ox_lib` loaded before sonar_bank_app client |
| **ST-004** | Mock-Only Transfer Rejection | Bug #4 (mock-only transfer) | All | Real callback `sonar:bank:transfer:execute` required |
| **ST-005** | ox_lib Server Handshake | Bug #3 (missing ox_lib server) | All | `ox_lib` loaded before sonar_bank server |
| **ST-006** | NUI Bridge Real Flow | Bug #5 (NUI bridge issues) | All | `sendNUIMessage` reaches React app |
| **ST-007** | Transfer Idempotency | Bug #6 (duplicate transfers) | All | Same `correlation_id` = no-op |

---

## 2. ST-008 a ST-020: Multi-Framework Compatibility Matrix

**Objetivo:** Validar QBox → QBCore → ESX 1.10+ (intentional failure ESX legacy <1.10)

| ID | Test | Framework | Pas/Fail Criteria |
|---|---|---|---|
| **ST-008** | QBox Bridge Detection | QBox | `Bridges.Bank.AddMoney` uses `qbx_core` exports |
| **ST-009** | QBCore Bridge Detection | QBCore | `Bridges.Bank.AddMoney` uses `qb-core` exports |
| **ST-010** | ESX 1.10+ Bridge Detection | ESX 1.10+ | `Bridges.Bank.AddMoney` uses `es_extended` exports |
| **ST-011** | ESX Legacy Intentional Failure | ESX <1.10 | Assert/fatal error on boot, resource does not start |
| **ST-012** | QBox Transfer Execute | QBox | `sonar:bank:transfer:execute` completes |
| **ST-013** | QBCore Transfer Execute | QBCore | `sonar:bank:transfer:execute` completes |
| **ST-014** | ESX 1.10+ Transfer Execute | ESX 1.10+ | `sonar:bank:transfer:execute` completes |
| **ST-015** | QBox Bootstrap Snapshot | QBox | `sonar:bank:bootstrap:snapshot` returns valid payload |
| **ST-016** | QBCore Bootstrap Snapshot | QBCore | `sonar:bank:bootstrap:snapshot` returns valid payload |
| **ST-017** | ESX 1.10+ Bootstrap Snapshot | ESX 1.10+ | `sonar:bank:bootstrap:snapshot` returns valid payload |
| **ST-018** | QBox StateBag Publish | QBox | `bank.balance.<cid>` and `bank.savings.<cid>` publish |
| **ST-019** | QBCore StateBag Publish | QBCore | `bank.balance.<cid>` and `bank.savings.<cid>` publish |
| **ST-020** | ESX 1.10+ StateBag Publish | ESX 1.10+ | `bank.balance.<cid>` and `bank.savings.<cid>` publish |

---

## 3. ST-021 a ST-030: Lag Spike Injection Tests

**Objetivo:** Validar robustez ante hitches 150-300ms en SQL queries y callback responses.

| ID | Test | Lag Magnitude | Injection Point | Pas/Fail Criteria |
|---|---|---|---|---|
| **ST-021** | 150ms SQL Query Lag | 150ms | `SELECT balance` query | No button hang, no double-submit |
| **ST-022** | 200ms SQL Query Lag | 200ms | `INSERT movement` query | Idempotency prevents duplicate |
| **ST-023** | 250ms SQL Query Lag | 250ms | `UPDATE account` query | Watchdog does not trigger false alarm |
| **ST-024** | 300ms SQL Query Lag | 300ms | Complex reconciliation query | Frontend shows loading state, not stuck |
| **ST-025** | 150ms Callback Lag | 150ms | `sonar:bank:transfer:execute` response | NUI receives response, no timeout |
| **ST-026** | 200ms Callback Lag | 200ms | `sonar:bank:bootstrap:snapshot` response | React app renders skeleton, not crash |
| **ST-027** | 250ms Callback Lag | 250ms | `sonar:bank:recipients:list` response | Pagination still works |
| **ST-028** | 300ms Callback Lag | 300ms | `sonar:bank:transactions:list` response | Cursor-based pagination survives |
| **ST-029** | Random Lag Spikes (150-300ms) | Random | Mixed SQL + callbacks | System remains stable |
| **ST-030** | Sustained Lag 10s | 200ms avg | Continuous for 10s | Graceful degradation, no crash |

---

## 4. ST-031 a ST-040: Concurrent Reconciliation Tests (20 Sessions)

**Objetivo:** Validar que 20 sesiones simultáneas no colisionan bajo lag.

| ID | Test | Concurrent Sessions | Lag Condition | Pas/Fail Criteria |
|---|---|---|---|---|
| **ST-031** | 5 Concurrent Transfers | 5 | No lag | All idempotency keys unique |
| **ST-032** | 10 Concurrent Transfers | 10 | No lag | No balance corruption |
| **ST-033** | 20 Concurrent Transfers | 20 | No lag | All receipts generated correctly |
| **ST-034** | 20 Concurrent Transfers + 150ms | 20 | 150ms lag | No race conditions |
| **ST-035** | 20 Concurrent Transfers + 200ms | 20 | 200ms lag | Idempotency prevents duplicates |
| **ST-036** | 20 Concurrent Bootstrap Snapshots | 20 | No lag | All snapshots return valid data |
| **ST-037** | 20 Concurrent Bootstrap + 150ms | 20 | 150ms lag | No NUI bridge drops |
| **ST-038** | 20 Concurrent Balance Queries | 20 | No lag | Audit hooks fire correctly |
| **ST-039** | 20 Concurrent Balance Queries + 200ms | 20 | 200ms lag | Rate limiting enforced |
| **ST-040** | 20 Mixed Operations (Transfer/Query/Bootstrap) | 20 | Random lag | No deadlock, all complete |

---

## 5. ST-041 a ST-050: Watchdog Metrics & Threshold Tests

**Objetivo:** Validar watchdog con `compromise_ratio_threshold=0.10` (10%).

| ID | Test | Threshold | Scenario | Pas/Fail Criteria |
|---|---|---|---|---|
| **ST-041** | Watchdog Below Threshold | 0.10 | 5% compromise delta | No alarm, system healthy |
| **ST-042** | Watchdog At Threshold | 0.10 | 10% compromise delta | Alarm triggers, graceful degradation |
| **ST-043** | Watchdog Above Threshold | 0.10 | 15% compromise delta | Critical alarm, admin notification |
| **ST-044** | Watchdog Min Sample Size | 10 | 9 samples | Watchdog does not evaluate (insufficient data) |
| **ST-045** | Watchdog Min Sample Size Valid | 10 | 10 samples | Watchdog evaluates correctly |
| **ST-046** | Status Transition Whitelist | H002 | Unauthorized resource attempts transition | Transition rejected, audit hook fires |
| **ST-047** | Status Transition Authorized | H002 | Whitelisted resource transitions | Transition allowed |
| **ST-048** | Watchdog Recovery | 0.10 | Compromise delta drops below threshold | System auto-recovers to healthy |
| **ST-049** | Watchdog Manual Override | 0.10 | Admin forces status transition | Audit hook `admin_force_action` fires |
| **ST-050** | Watchdog Persistence | 0.10 | Server restart with compromised state | State restored, alarm persists |

---

## 6. ST-051 a ST-055: ATM HMAC Secret & Production Guard Tests

**Objetivo:** Validar ATM HMAC secret y guard de producción.

| ID | Test | Scenario | Pas/Fail Criteria |
|---|---|---|---|
| **ST-051** | ATM HMAC Secret Present | Convar set | `sonar_bank_atm_hmac_secret` has 64+ hex chars |
| **ST-052** | ATM HMAC Secret Length | Convar validation | Minimum 64 characters enforced |
| **ST-053** | ATM HMAC Secret Format | Convar validation | Hex characters only (0-9, a-f) |
| **ST-054** | Dev Mode Secret Allowed | `sonar_dev_mode=1` | Canonical secret accepted |
| **ST-055** | Production Secret Guard | `sonar_dev_mode=0` + canonical secret | Assert/fatal error, force rotation |

---

## 7. Execution Order

**Phase 1: Regression (ST-001 to ST-007)**
- Run on all frameworks (QBox, QBCore, ESX 1.10+)
- Baseline validation before chaos tests

**Phase 2: Framework Matrix (ST-008 to ST-020)**
- QBox first (priority)
- QBCore second
- ESX 1.10+ third
- ESX legacy intentional failure validation

**Phase 3: Lag Spike Injection (ST-021 to ST-030)**
- Incremental lag: 150ms → 200ms → 250ms → 300ms
- Mixed SQL + callback injection

**Phase 4: Concurrent Reconciliation (ST-031 to ST-040)**
- Scale up: 5 → 10 → 20 sessions
- Add lag conditions at scale

**Phase 5: Watchdog Metrics (ST-041 to ST-050)**
- Threshold validation
- Recovery scenarios
- Whitelist enforcement

**Phase 6: Production Guard (ST-051 to ST-055)**
- Secret validation
- Production guard enforcement

---

## 8. Pass/Fail Criteria

**Phase A Shipping Requirements:**
- ✅ All ST-001 to ST-007 regression tests PASS
- ✅ QBox + QBCore + ESX 1.10+ framework tests PASS
- ✅ ESX legacy intentional failure validated
- ✅ Lag spike tests PASS (no button hangs, no duplicate submissions)
- ✅ 20 concurrent sessions PASS (no race conditions)
- ✅ Watchdog threshold 0.10 validated
- ✅ Production guard enforced

**Blocking Failures:**
- ❌ Any regression test FAIL (ST-001 to ST-007)
- ❌ Framework detection fails on QBox/QBCore/ESX 1.10+
- ❌ ESX legacy does NOT fail intentionally
- ❌ Lag spike causes button hang or duplicate submission
- ❌ Concurrent sessions cause balance corruption
- ❌ Watchdog false positives (threshold too low)
- ❌ Production guard does NOT block canonical secret

---

## 9. Test Harness

**Tooling:**
- Lua test harness in `resources/sonar_bank/tests/smoke_chaos.lua`
- Automated framework detection
- Lag injection via `Wait()` mocks
- Concurrent session simulation via `Citizen.CreateThread`
- Watchdog metrics inspection via StateBag reads
- Production guard validation via convar inspection

**Execution:**
```lua
-- Run all tests
execute_smoke_chaos_matrix("all")

-- Run specific phase
execute_smoke_chaos_matrix("regression")  -- ST-001 to ST-007
execute_smoke_chaos_matrix("framework")   -- ST-008 to ST-020
execute_smoke_chaos_matrix("lag")         -- ST-021 to ST-030
execute_smoke_chaos_matrix("concurrent")  -- ST-031 to ST-040
execute_smoke_chaos_matrix("watchdog")    -- ST-041 to ST-050
execute_smoke_chaos_matrix("production")  -- ST-051 to ST-055
```

---

## 10. Reporting

**Output Format:**
- Markdown report in `progress/SMOKE_CHAOS_RESULTS.md`
- Per-test pass/fail status
- Framework-specific results
- Latency measurements
- Watchdog metric snapshots
- Blocking failure flag

**Sign-off Required:**
- DevOps Lead: ✅ Test execution validation
- Security Lead: ✅ Audit hooks verification
- Founder: ✅ Production guard validation
