# PHASE_5_6_C_LIVE_VALIDATION

## Session metadata

- Phase: `BANK-BE.PHASE_5.6.C`
- Branch: `feature/bank-security-phase-a`
- HEAD: `79f5c62`
- Workspace: `d:\theBigProject`
- Source reference: `D:\FiveM_Server\Sonar\` read-only
- Live validation sandbox: `D:\FiveM_Server\Sonar_phase5c\`
- Patcher output: `D:\FiveM_Server\Sonar_phase5c\migration_output\`

## Boundary confirmation

| Boundary | Status | Evidence |
|---|---:|---|
| Original `D:\FiveM_Server\Sonar\` not patched | PASS | Apply target was `D:\FiveM_Server\Sonar_phase5c\resources\[qb]`; original `[qb]` `.bak` count = `0` |
| Contracts / 22 SONAR exports untouched | PASS | No source edits under `resources/sonar_bank_app` or contract docs in this phase |
| Phase A bank-only scope | PASS | `summary.json` scope_money_types = `["bank"]` |
| No cash/crypto scope creep | PASS | `U1` remains manual review |

## Step 1 — Sandbox setup and apply

| Check | Status | Evidence |
|---|---:|---|
| Copy source server to phase sandbox | PASS | `D:\FiveM_Server\Sonar_phase5c\` created from `D:\FiveM_Server\Sonar\` |
| `[qb]` resource tree exists in sandbox | PASS | `D:\FiveM_Server\Sonar_phase5c\resources\[qb]` exists; 56 directories detected |
| Patcher apply against sandbox only | PASS | Initial apply used `migration_output`; after `F-PH5.6C-001`, sandbox was rolled back and reapplied to `migration_output_v1_1` |
| Apply totals | PASS | `45 auto`, `93 manual` |
| Patched markers | PASS | `45` `SONAR_PATCHED v1` markers detected |
| Backup files generated | PASS | `27` `.bak` files under `D:\FiveM_Server\Sonar_phase5c\migration_output` |
| Diff files generated | PASS | `27` `.diff` files under `D:\FiveM_Server\Sonar_phase5c\migration_output` |
| txAdmin boot | PASS_AFTER_FIX | First boot failed on `qb-houses`; reboot after `F-PH5.6C-001` fix completed with resource scan warning-only state |
| Zero Lua startup errors | PASS_AFTER_FIX | Reboot after fix showed no `qb-houses` metadata parse error and no blocking Lua startup error in provided console |
| All patched qb-* resources start clean | PASS_AFTER_FIX | `qb-houses`, `qb-ambulancejob`, `qb-crypto`, `qb-garbagejob`, `qb-hotdogjob`, `qb-pawnshop`, `qb-phone`, `qb-policejob`, `qb-shops`, `qb-towjob`, `qb-truckrobbery`, `qb-vehiclesales`, and `qb-vehicleshop` started |
| Sandbox rollback after startup fail | PASS | `python -m patcher --rollback --filter-resource="qb-*" --output-dir D:\FiveM_Server\Sonar_phase5c\migration_output ...`; markers after rollback = `0` |
| Reapply with patcher fix | PASS | `45 auto`, `93 manual`, `27` backups, `45` markers, output `D:\FiveM_Server\Sonar_phase5c\migration_output_v1_1` |
| `qb-houses` manifest syntax after fix | PASS | final dependency normalized as `'qb-weathersync',` before `'sonar_bank_app',` |
| Reboot after patcher fix | PASS | FXServer `[47352]` startup at `2026-05-13 07:00:31`; `qb-houses` started successfully; `sonar_bank_app` smoke `8/8`; SONAR chaos smoke `7/7` |
| Non-blocking warnings | NOTED | `bkp` missing manifest, `pma-voice` recommendation, and `Couldn't find resource category [scripts]`; unrelated to patcher apply |

## Artifact mismatch note

The mission prompt referenced `auto_patched.md` as 70 entries. Current authoritative `summary.json` and `auto_patched.md` from HEAD `79f5c62` report:

- `45` auto-patched call sites.
- `13` fxmanifest dependency injections.
- `27` touched files / backup files.
- `93` manual-review call sites.

## Step 2 — S1-S12 adversarial live matrix

PASS criterion per scenario:

- QBCore `PlayerData.money.bank` before/after captured.
- SONAR `exports.sonar_bank_app:GetBalance` immediate captured.
- Zero drift QBCore ↔ SONAR.
- Audit row present by scenario correlation id.
- `event_type` canonical: `bank_credit` or `bank_debit`.
- `invoker_resource` is the real patched resource, not heuristic/fallback.
- `actor_account_id` present where applicable.
- StateBag `bank.balance.<cid>` publish observed.
- UI Bank App refresh observed real-time.

| Scenario | Resource / flow | Expected event | QBCore pre | SONAR pre | QBCore post | SONAR post | Audit correlation_id | invoker_resource | StateBag | UI | Status | Notes |
|---|---|---|---:|---:|---:|---:|---|---|---|---|---:|---|
| S1 | Vehicle purchase showroom | `bank_debit` | PENDING | `5000000` | PENDING | `5000000` | PENDING | PENDING | PENDING | PENDING | FAIL | Vehicle purchase succeeded but neither SONAR nor QBCore bank balance decreased; infinite purchase path observed. |
| S2 | Vehicle sale commission | `bank_credit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| S3 | Pawnshop sell items | `bank_credit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| S4 | Paycheck / job payout | `bank_credit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| S5 | `/givemoney` or equivalent direct player payment | `bank_credit`/`bank_debit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| S6 | Police fine payment | `bank_debit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| S7 | Ambulance bill / respawn bill | `bank_debit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| S8 | Phone invoice payment / commission | `bank_debit`/`bank_credit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| S9 | Phone transfer online recipient | `bank_debit`/`bank_credit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| S10 | Tow / trucker payout or bail | `bank_credit`/`bank_debit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| S11 | Crypto buy/sell bank path | `bank_debit`/`bank_credit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| S12 | Used vehicle sale / transfer | `bank_credit`/`bank_debit` | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |  |

## Step 3 — Rollback drill

| Check | Status | Evidence |
|---|---:|---|
| `python -m patcher --rollback ...` | PENDING | Must run after Step 2 evidence capture |
| `.bak` restored | PENDING | Compare patched markers after rollback |
| Idempotency confirmed | PENDING | Re-run patcher dry/apply after rollback if required |

## Bug intake

### F-PH5.6C-001 — fxmanifest dependency injection missing comma

- Severity: `BLOCKER`
- Status: `FIXED_VALIDATED_ON_REBOOT`
- Detected during: txAdmin startup validation
- Affected resource: `qb-houses`
- Symptom: `Could not parse resource metadata file ... qb-houses/fxmanifest.lua:43: '}' expected (to close '{' at line 38) near 'sonar_bank_app'`
- Root cause: `fxmanifest_injector.py` appended `'sonar_bank_app',` to an existing `dependencies {}` block without first adding a comma to the prior final dependency when that block had no trailing comma.
- Fix: Added dependency-block insertion logic that normalizes the previous final dependency with a comma before appending `sonar_bank_app`.
- Regression test: `test_fxmanifest_existing_deps_without_trailing_comma`
- Test result: `27 passed`, coverage `93.58%`
- Sandbox remediation: rolled back first apply, reapplied corrected patcher to `migration_output_v1_1`; `qb-houses/fxmanifest.lua` now parses structurally with trailing comma before injected dependency.
- Reboot validation: FXServer `[47352]` started `qb-houses` successfully after fix; no repeated metadata parse error.

### F-PH5.6C-002 — bare RemoveMoney after irreversible vehicle grant ignores SONAR result

- Severity: `CRITICAL`
- Status: `OPEN_BLOCKS_S1_S12_CONTINUATION`
- Detected during: S1 vehicle purchase showroom live validation
- Affected resource: `qb-vehicleshop`
- Affected flow: `qb-vehicleshop:server:buyShowroomVehicle`
- Pre balance evidence: `qa_get_balance 1` returned `balance_minor=5000000`, `iban=AD-WKRB-ZVE8-9A1D`.
- Post balance evidence: after purchase, `qa_get_balance 1` still returned `balance_minor=5000000`.
- Symptom: player can buy vehicles repeatedly; vehicle purchase succeeds but neither SONAR nor QBCore bank is debited.
- Root cause hypothesis: patcher treated a bare `pData.Functions.RemoveMoney('bank', vehiclePrice, ...)` call as S1 safe even though it appears after irreversible side effects (`INSERT INTO player_vehicles`, success notify, client vehicle grant). The generated `exports.sonar_bank_app:RemoveMoney(...)` call ignores `(ok, err, data)`, so failed/async/non-mutating debit does not gate the vehicle grant.
- Required fix direction: patcher v1.1 must not auto-patch bank `RemoveMoney` calls that occur after irreversible side effects in the same branch unless it can safely rewrite control flow to debit first and gate subsequent side effects on `ok == true`. Otherwise route to manual review.
- Immediate gate: stop S1-S12 continuation until patcher v1.1 or a manual sandbox-only hotfix is applied and S1 is revalidated.
- Decision: `A` accepted. Keep risky vehicle-shop flows as manual review in the patcher and apply a sandbox-only manual hotfix to `qb-vehicleshop` that debits SONAR before vehicle grant/DB mutation and gates downstream side effects on `ok == true`.
- Patcher mitigation: v1.1.0 routes bare `RemoveMoney('bank')` after irreversible side effects to manual review; regression test `test_remove_money_after_irreversible_side_effect_is_manual`; test result `28 passed`, coverage `93.78%`.
- Sandbox code remediation:
  - Rolled back previous apply from `D:\FiveM_Server\Sonar_phase5c\migration_output_v1_1`.
  - Reapplied patcher v1.1.0 to `D:\FiveM_Server\Sonar_phase5c\resources\[qb]` with output `migration_output_v1_1_0`.
  - Result changed from `45 auto / 93 manual` to `32 auto / 106 manual`; `qb-vehicleshop` changed from `12 auto / 12 manual` to `7 auto / 17 manual`.
  - Applied sandbox-only manual hotfix to `qb-vehicleshop/server.lua`: PDM bank purchase, finance down payment, finance payment, payoff, seller-assisted sale, seller-assisted finance, and transfervehicle bank paths now debit/transfer through SONAR before irreversible DB/vehicle side effects.
  - Updated sandbox `sonar_bank_qa_probe` with temporary controlled vehicle cleanup helpers: `qa_vehicle_recent_by_src`, `qa_vehicle_recent`, and `qa_vehicle_delete <citizen_id> <plate> CONFIRM_DELETE`.
- DB cleanup required before S1 retest:
  - Run `restart sonar_bank_qa_probe`.
  - Run `qa_vehicle_recent_by_src 1 10`.
  - Identify the free vehicle plate created during failed S1.
  - Run `qa_vehicle_delete <citizen_id> <plate> CONFIRM_DELETE`.
  - Confirm `affected=1`, then rerun `qa_vehicle_recent_by_src 1 10`.
- Retest diagnostic after hotfix:
  - `qa_get_balance 2` returned `balance_minor=5000000`, `iban=AD-WKRB-ZVE8-9A1D`.
  - Purchase attempt for `rhapsody` (`vehicle_price=10000`, `amount_minor=1000000`) was blocked before vehicle grant with `err=ACCOUNT_FROZEN`.
  - Interpretation: hotfix gate is working; current blocker is account state, not insufficient funds or amount conversion.
- Follow-up hotfix correction:
  - Observed inconsistent behavior: vehicles near `$10,000` could be purchased, while vehicles around `$24,000` failed despite sufficient SONAR balance.
  - Root cause: manual hotfix still used legacy QBCore `bank` balance as a pre-gate before calling SONAR in some branches. Example prior evidence showed `qb_bank=18260`, so `$10,000` passed the pre-gate but `$24,000` failed before SONAR could authorize against the real SONAR balance.
  - Correction: removed legacy QBCore bank pre-gates from bank fallback paths in `qb-vehicleshop`; after cash fallback fails, SONAR `RemoveMoney` / `TransferBySource` is now the authoritative gate.
  - Syntax remediation: fixed two leftover duplicated `else` branches introduced during manual hotfix correction in `buyShowroomVehicle` and `financeVehicle`; `qb-vehicleshop/server.lua` no longer contains `elseif bank` or `GetMoney('bank')` bank pre-gates.
