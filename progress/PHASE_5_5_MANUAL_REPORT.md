# Phase 5.5 Manual Adversarial Validation Report

## Session metadata

- Date: 2026-05-13 00:28 UTC
- Server: `D:\FiveM_Server\Sonar` (QBCore)
- Branch HEAD: `9f42ca7`
- Dev: Cascade / Backend Lead | Founder: yaboula
- Duration: PENDING
- Runtime DB: Laragon MySQL local, SONAR database `sonar`
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
| `qa_help` lists 22 wrappers | PENDING | Await live console |
| `sonar:admin_allowlist` includes `sonar_bank_qa_probe` | PENDING | Use `qa_context` live output |
| `/sonar_scan_legacy` baseline | PENDING | Await live console |

## QA probe operation notes

Start/refresh commands for live session:

```text
set sonar:admin_allowlist "sonar_bank_app,sonar_bank,sonar_core,sonar_bank_qa_probe"
ensure sonar_bank_qa_probe
qa_context
qa_help
```

If the resource is not visible to FXServer, create a temporary runtime junction from `D:\FiveM_Server\Sonar\resources\[sonar]\sonar_bank_qa_probe` to `D:\theBigProject\resources\sonar_bank_qa_probe`, then run `refresh` and `ensure sonar_bank_qa_probe`.

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
| 1 | `GetBalance` | `qa_get_balance <src>` | PENDING | n/a | n/a | n/a | PENDING |  |
| 2 | `GetBalanceByCitizen` | `qa_get_balance_by_citizen <cid>` | PENDING | n/a | n/a | n/a | PENDING |  |
| 3 | `CanAfford` | `qa_can_afford <src> <amount_minor>` | PENDING | n/a | n/a | n/a | PENDING |  |
| 4 | `CanAffordByCitizen` | `qa_can_afford_by_citizen <cid> <amount_minor>` | PENDING | n/a | n/a | n/a | PENDING |  |
| 5 | `AddMoney` | `qa_add_money <src> 1250 qa_credit idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 6 | `AddMoneyByCitizen` | `qa_add_money_by_citizen <cid> 500 qa_credit_offline idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 7 | `RemoveMoney` | `qa_remove_money <src> 500 qa_debit idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 8 | `RemoveMoneyByCitizen` | `qa_remove_money_by_citizen <cid> 200 qa_debit_offline idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 9 | `TransferBySource` | `qa_transfer_by_source <src1> <src2> 1000 qa_xfer idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING | Requires two online players or controlled second source |
| 10 | `TransferByIban` | `qa_transfer_by_iban <iban1> <iban2> 1000 qa_xfer_iban idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 11 | `TransferByCitizen` | `qa_transfer_by_citizen <cid1> <cid2> 1000 qa_xfer_cid idem=<uuid>` | PENDING | PENDING | PENDING | PENDING | PENDING |  |
| 12 | `GetApiVersion` | `qa_get_api_version` | PENDING | n/a | n/a | n/a | n/a |  |
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

- No findings recorded yet.

## Bugs filed + status

| ID | Severity | Status | Fix commit | Re-test |
|---|---|---|---|---|
| n/a | n/a | n/a | n/a | n/a |

## GATE 5.5 to H5 criteria

| Criterion | Status | Evidence |
|---|---|---|
| 22/22 cobertura PASS dev | PENDING |  |
| 0 BLOCKER findings | PENDING |  |
| HIGH/MEDIUM RESOLVED + re-test PASS | PENDING |  |
| LOW/COSMETIC documented/deferred | PENDING |  |
| Founder 🟢 GO MANUAL formal | PENDING |  |

## Sign-off

- Backend Lead: PENDING self-attested coverage 22/22 + cross-checks PASS post-fix
- Founder yaboula: PENDING GO MANUAL / BLOCKED
- PM Cascade: PENDING promote ceremony close post Founder GO
