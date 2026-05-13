# Phase 5.5 Manual Adversarial Validation Report

## Session metadata

- Date: 2026-05-13 00:28 UTC
- Server: `D:\FiveM_Server\Sonar` (QBCore)
- Branch HEAD: `9f42ca7`
- Dev: Cascade / Backend Lead | Founder: yaboula
- Duration: PENDING
- Runtime DB: Laragon MySQL local, active oxmysql database `QBCore_FFAED3`; `sonar_db_database=qbcore_ffaed3`
- Bridge mode: `sonar_bridge_bank=qbcore`, `sonar_bridge_identity=qbcore`, `sonar_bridge_bank_mode=standalone`
- QA resource: `resources/sonar_bank_qa_probe` temporary, server-only, not permanently registered in cfg

## Pre-flight

| Check | Status | Evidence |
|---|---|---|
| Pull `feature/bank-security-phase-a` | ✅ | `git pull --ff-only` -> already up to date |
| HEAD | ✅ | `9f42ca7` |
| QBCore cfg active | ✅ | `qbcore.cfg` shows QBCore bridge convars and SONAR isolated DB |
| QA probe resource created | ✅ | `resources/sonar_bank_qa_probe/fxmanifest.lua`, `server.lua` |
| Runtime resource available in FXServer | ✅ | Temporary junction created: `D:\FiveM_Server\Sonar\resources\[sonar]\sonar_bank_qa_probe` -> `D:\theBigProject\resources\sonar_bank_qa_probe` |
| `qa_help` lists 22 wrappers | ✅ | Live console: `22 export wrappers registered`, commands 01-22 listed |
| `sonar:admin_allowlist` includes `sonar_bank_qa_probe` | ✅ | `qa_context` returned `admin_allowlist="sonar_bank_app,sonar_bank,sonar_core,sonar_bank_qa_probe"` |
| `/sonar_scan_legacy` baseline | ✅ | Live console: `complete: 0 resource(s) flagged` |

## QA probe operation notes

Start/refresh commands for live session:

```text
set sonar:admin_allowlist "sonar_bank_app,sonar_bank,sonar_core,sonar_bank_qa_probe"
ensure sonar_bank_qa_probe
qa_context
qa_help
```

If the resource is not visible to FXServer, create a temporary runtime junction from `D:\FiveM_Server\Sonar\resources\[sonar]\sonar_bank_qa_probe` to `D:\theBigProject\resources\sonar_bank_qa_probe`, then run `refresh` and `ensure sonar_bank_qa_probe`.

Live console executes one command per line. Do not paste multiple `qa_*` commands into one line.

Mutation command conventions:

- `idem=<uuid>` sets `opts.idempotency_key`.
- `corr=<uuid>` sets `opts.correlation_id`.
- `overdraft=1` sets `opts.allow_overdraft=true` for Tier 2 admin exports.
- `str:<value>` forces a string argument for fuzzing amount fields.
- `num:<value>` forces numeric parsing.
- `nil` passes Lua `nil` for fuzzing.

Read-only SQL helper commands:

```text
qa_account_by_src <src>
qa_account_by_citizen <citizen_id>
qa_account_by_iban <iban>
qa_audit <request_nonce_or_correlation_id>
qa_audit_shape <request_nonce_or_correlation_id>
qa_movement <request_nonce_or_tx_id>
```

## Coverage matrix dev (5.1 + 5.2)

| # | Export | Command | Status | Audit OK | StateBag OK | Movement OK | Balance OK | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | `GetBalance` | `qa_get_balance <src>` | PASS | n/a | n/a | n/a | PASS | P55-001 re-test PASS: returned `balance_minor=5001250`, `iban=AD-WKRB-ZVE8-9A1D` |
| 2 | `GetBalanceByCitizen` | `qa_get_balance_by_citizen <cid>` | PASS | n/a | n/a | n/a | PASS | Returned `balance_minor=5002500`, `iban=AD-WKRB-ZVE8-9A1D` |
| 3 | `CanAfford` | `qa_can_afford <src> <amount_minor>` | PASS | n/a | n/a | n/a | PASS | P55-001 re-test PASS: returned `sufficient=true`, `balance_minor=5001250` |
| 4 | `CanAffordByCitizen` | `qa_can_afford_by_citizen <cid> <amount_minor>` | PASS | n/a | n/a | n/a | PASS | Returned `sufficient=true`, `balance_minor=5002500` |
| 5 | `AddMoney` | `qa_add_money <src> 1250 qa_credit idem=<uuid>` | PASS | PASS | PENDING | PASS | PASS | P55-001 re-test PASS: returned `new_balance_minor=5002500`, audit row id=1392, movement row id=2786 |
| 6 | `AddMoneyByCitizen` | `qa_add_money_by_citizen <cid> 500 qa_credit_offline idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 7 | `RemoveMoney` | `qa_remove_money <src> 500 qa_debit idem=<uuid>` | PASS | PASS | PENDING | PASS | PASS | Returned `new_balance_minor=5002000`, audit row id=1393, movement row id=2787 |
| 8 | `RemoveMoneyByCitizen` | `qa_remove_money_by_citizen <cid> 200 qa_debit_offline idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 9 | `TransferBySource` | `qa_transfer_by_source <src1> <src2> 1000 qa_xfer idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING | Requires two online players or controlled second source |
| 10 | `TransferByIban` | `qa_transfer_by_iban <iban1> <iban2> 1000 qa_xfer_iban idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 11 | `TransferByCitizen` | `qa_transfer_by_citizen <cid1> <cid2> 1000 qa_xfer_cid idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 12 | `GetApiVersion` | `qa_get_api_version` | PASS | n/a | n/a | n/a | n/a | Returned `{major=1, minor=0, patch=2, phase="Phase 5", api_lock="C-BE-02 v1.0.2 R2"}` |
| 13 | `AdminCredit` | `qa_admin_credit <actor_src> <target> 5000 qa_admin_credit idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING | Contract signature is `(actor_src, target, amount, reason, opts)` |
| 14 | `AdminDebit` | `qa_admin_debit <actor_src> <target> 5000 qa_admin_debit idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 15 | `AdminSetBalance` | `qa_admin_set_balance <actor_src> <target> 100000 qa_admin_set idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 16 | `Freeze` | `qa_freeze <actor_src> <iban> qa_freeze` | PENDING | PENDING | n/a | n/a | PENDING |  |
| 17 | `Unfreeze` | `qa_unfreeze <actor_src> <iban> qa_unfreeze` | PENDING | PENDING | n/a | n/a | PENDING |  |
| 18 | `AdminCreditByCitizen` | `qa_admin_credit_by_citizen <actor_src> <cid> 5000 qa_admin_credit_cid idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 19 | `AdminDebitByCitizen` | `qa_admin_debit_by_citizen <actor_src> <cid> 5000 qa_admin_debit_cid idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 20 | `AdminSetBalanceByCitizen` | `qa_admin_set_balance_by_citizen <actor_src> <cid> 100000 qa_admin_set_cid idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 21 | `FreezeByCitizen` | `qa_freeze_by_citizen <actor_src> <cid> qa_freeze_cid` | PENDING | PENDING | n/a | n/a | PENDING |  |
| 22 | `UnfreezeByCitizen` | `qa_unfreeze_by_citizen <actor_src> <cid> qa_unfreeze_cid` | PENDING | PENDING | n/a | n/a | PENDING |  |

## Per-export evidence log

Paste each command block in this format:

```text
[EXPORT]
Pre snapshot: <qa_account... output or HeidiSQL row>
Invoke: <qa_... output>
Post snapshot: <qa_account... output or HeidiSQL row>
Audit: <qa_audit ... output>
Audit shape: <qa_audit_shape ... output>
Movement: <qa_movement ... output>
StateBag/NetEvent/UI: <observed evidence or n/a>
Result: PASS / FAIL
```

```text
[Pre-flight runtime]
refresh: Found new resource and warning only for unrelated bkp missing manifest.
set sonar:admin_allowlist "sonar_bank_app,sonar_bank,sonar_core,sonar_bank_qa_probe"
restart/ensure sonar_bank_qa_probe: ready: 22 export wrappers + read-only SQL helpers.
qa_context: ok=true export_count=22 bridge_bank=qbcore bridge_identity=qbcore bridge_bank_mode=standalone sonar_db_database=qbcore_ffaed3 allowlist includes sonar_bank_qa_probe.
qa_help: 22 export wrappers registered, commands 01-22 listed.
sonar_scan_legacy: complete: 0 resource(s) flagged.
Result: PASS
```

```text
[GetBalance / CanAfford / GetApiVersion / AddMoney probe batch]
Pre snapshot: qa_account_by_src 1 -> ok=true data=[{iban="AD-WKRB-ZVE8-9A1D", id="15f14368-6a82-4ad7-a646-933c5b3b49e4", balance_minor=5000000, balance="50000.00", char_id="FXD56242", is_frozen=false}]
Invoke read: qa_can_afford 1 1 -> ok=true err=null data=null
Invoke info: qa_get_api_version -> ok=true err=null data={major=1, minor=0, patch=2, phase="Phase 5", api_lock="C-BE-02 v1.0.2 R2"}
Invoke read: qa_get_balance 1 -> ok=true err=null data=null
Invoke mutation: qa_add_money 1 1250 QA_valid_uuid idem=11111111-1111-4111-8111-111111111111 -> ok=true err=null data=null
Audit: qa_audit 11111111-1111-4111-8111-111111111111 -> row id=1391 category=bank_exports action=bank_credit event_type=bank_credit actor_source=1 target_id=AD-WKRB-ZVE8-9A1D amount=12.50 delta_minor=1250 request_nonce=11111111-1111-4111-8111-111111111111 correlation_id=11111111-1111-4111-8111-111111111111 invoker_resource=oxmysql reason=QA_valid_uuid
Audit shape: qa_audit_shape 11111111-1111-4111-8111-111111111111 -> request_nonce/correlation_id/actor_account_id/target_account_id/event_type/delta_minor/invoker_resource/reason/created_at present; previous_flag_snapshot absent for bank_credit.
Movement: qa_movement 11111111-1111-4111-8111-111111111111 -> row id=2785 category=deposit amount=12.50 balance_after=50012.50 request_nonce=11111111-1111-4111-8111-111111111111 source_resource=sonar_bank_app.
StateBag/NetEvent/UI: PENDING.
Result: FAIL for contract return data on GetBalance, CanAfford, AddMoney; PASS for DB mutation, audit, movement side effects.
```

```text
[P55-001 re-test after boundary fix]
Load: ensure sonar_bank_qa_probe -> ready: 22 export wrappers + read-only SQL helpers.
Invoke read: qa_can_afford 1 1 -> ok=true err=null data={sufficient=true,balance_minor=5001250}
Invoke read: qa_get_balance 1 -> ok=true err=null data={savings_minor=0,iban="AD-WKRB-ZVE8-9A1D",balance_minor=5001250}
Invoke mutation: qa_add_money 1 1250 QA_p55_001_retest idem=22222222-2222-4222-8222-222222222222 -> ok=true err=null data={new_balance_minor=5002500,iban="AD-WKRB-ZVE8-9A1D",tx_id="78ecbf96-be6e-4192-9e8c-e739a2399fb2"}
Audit: qa_audit 22222222-2222-4222-8222-222222222222 -> row id=1392 category=bank_exports action=bank_credit event_type=bank_credit actor_source=1 target_id=AD-WKRB-ZVE8-9A1D amount=12.50 delta_minor=1250 request_nonce=22222222-2222-4222-8222-222222222222 correlation_id=22222222-2222-4222-8222-222222222222 invoker_resource=oxmysql reason=QA_p55_001_retest
Movement: qa_movement 22222222-2222-4222-8222-222222222222 -> row id=2786 category=deposit amount=12.50 balance_after=50025.00 request_nonce=22222222-2222-4222-8222-222222222222 related_doc_id=78ecbf96-be6e-4192-9e8c-e739a2399fb2 source_resource=sonar_bank_app.
Result: PASS — success tuple data preserved across FiveM export boundary.
```

```text
[GetBalanceByCitizen / CanAffordByCitizen / RemoveMoney]
Invoke read: qa_get_balance_by_citizen FXD56242 -> ok=true err=null data={savings_minor=0,iban="AD-WKRB-ZVE8-9A1D",balance_minor=5002500}
Invoke read: qa_can_afford_by_citizen FXD56242 1 -> ok=true err=null data={sufficient=true,balance_minor=5002500}
Invoke mutation: qa_remove_money 1 500 QA_remove_happy idem=33333333-3333-4333-8333-333333333333 -> ok=true err=null data={new_balance_minor=5002000,iban="AD-WKRB-ZVE8-9A1D",tx_id="e3cff744-4ae6-409e-a277-28d203afeb26"}
Audit: qa_audit 33333333-3333-4333-8333-333333333333 -> row id=1393 category=bank_exports action=bank_debit event_type=bank_debit actor_source=1 target_id=AD-WKRB-ZVE8-9A1D amount=-5.00 delta_minor=-500 request_nonce=33333333-3333-4333-8333-333333333333 correlation_id=33333333-3333-4333-8333-333333333333 invoker_resource=oxmysql reason=QA_remove_happy
Movement: qa_movement 33333333-3333-4333-8333-333333333333 -> row id=2787 category=withdrawal amount=-5.00 balance_after=50020.00 request_nonce=33333333-3333-4333-8333-333333333333 related_doc_id=e3cff744-4ae6-409e-a277-28d203afeb26 source_resource=sonar_bank_app.
StateBag/NetEvent/UI: PENDING.
Result: PASS
```

## Cross-checks (5.3)

| Cross-check | Status | Evidence |
|---|---|---|
| AH4 atomic rollback | PENDING |  |
| 10-field canonical audit shape | PENDING | `qa_audit_shape <request_nonce>` for every mutation event type |
| CP1-B owner-only balance publish | PENDING | UI/client event evidence post-COMMIT |
| `bank_overdraft` insufficient funds path | PENDING | `qa_remove_money <src> <over_balance_amount> ...` + `qa_audit` + no movement |
| INTEGER↔DECIMAL boundary | PENDING | Amounts: `1`, `99`, `100`, `12345`, `999999`, max int32 |
| PLAYER_NOT_LOADED | PENDING | Invoke during QBCore load window or `/qb logout` transition |

## Founder adversarial findings (6.1-6.7)

- `qa_add_money 1 50000 Ingreso_Manual_Founder idem=TESTKEY123` returned `ok=false err="INVALID_UUID" data=null`. Expected reject because `idem` must be UUID v4.
- `qa_remove_money 1 9999999999 Intento_Exploit idem=TESTKEY456` returned `ok=false err="INVALID_UUID" data=null`. Expected reject because UUID validation occurs before overdraft path.

## Bugs filed + status

| ID | Severity | Status | Fix commit | Re-test |
|---|---|---|---|---|
| P55-001 | HIGH | RESOLVED + RE-TEST PASS | n/a | Boundary wrapper added around Tier 1/2 `exports(...)` to return `false` as the internal FiveM sentinel only when `ok=true` and `err=nil`, preserving third return `data`; QA probe normalizes this sentinel back to `err=null`. Re-test confirmed `qa_can_afford`, `qa_get_balance`, and `qa_add_money` now return contract data. |
| P55-002 | LOW | RESOLVED in probe + RE-TEST PASS | n/a | `qa_account_by_src 1` after `restart sonar_bank_qa_probe` returned account row from `qbcore_ffaed3`: IBAN `AD-WKRB-ZVE8-9A1D`, balance `50000.00`, citizen `FXD56242`. |

## GATE 5.5 to H5 criteria

| Criterion | Status | Evidence |
|---|---|---|
| 22/22 cobertura PASS dev | PENDING | P55-001 resolved; continue remaining matrix |
| 0 BLOCKER findings | PENDING | No BLOCKER filed so far |
| HIGH/MEDIUM RESOLVED + re-test PASS | ✅ | P55-001 HIGH resolved + re-test PASS |
| LOW/COSMETIC documented/deferred | PENDING |  |
| Founder 🟢 GO MANUAL formal | PENDING |  |

## Sign-off

- Backend Lead: PENDING self-attested coverage 22/22 + cross-checks PASS post-fix
- Founder yaboula: PENDING GO MANUAL / BLOCKED
- PM Cascade: PENDING promote ceremony close post Founder GO
