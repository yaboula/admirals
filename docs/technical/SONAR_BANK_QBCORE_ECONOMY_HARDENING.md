# SONAR Bank QBCore Economy Hardening Guide

## Purpose

This guide is for customers who want to use SONAR Bank not only as a bank UI/integration, but as a security and reliability upgrade for their server economy.

The goal is:

```text
Replace unsafe legacy economy patterns.
Remove direct SQL money writes.
Use audited SONAR account operations.
Support offline-capable transfers safely.
Design business/society flows explicitly.
Protect the economy from partial failures and silent desync.
```

This path is for developer-led migrations. It is not the default operator path.

## Relationship To Safe Integration

Safe Integration handles simple player bank flows and stops before dangerous economy logic.

Economy Hardening starts where Safe Integration stops.

A blocker in Safe Integration means:

```text
This flow needs Economy Hardening design.
```

It does not mean the flow is impossible.

## When To Use This Guide

Use this guide when a resource contains:

- player-to-player transfers
- marketplace sales
- offline seller payouts
- direct SQL writes to `players.money`
- admin set-balance flows
- society/job/business account balances
- commissions split between player and business
- escrow-like flows
- loans, finance, debt, or recurring payment logic
- custom economy frameworks
- multi-step flows where money and ownership must stay consistent

## What This Guide Is Not

This guide is not:

- blind search-and-replace
- an operator-only checklist
- a guarantee that every legacy economy design is safe
- a reason to mutate QBCore money and SONAR money at the same time
- a license to ignore partial failure handling

## Core Hardening Principles

### SONAR is authoritative

Migrated bank money must go through SONAR APIs.

Do not write bank balances directly to legacy `players.money`.

### Use atomic APIs when money moves between parties

Do not implement transfers as separate debit and credit when a transfer API exists.

Preferred examples:

```lua
exports.sonar_bank_app:TransferBySource(from_src, to_src, amount_minor, reason, opts)
exports.sonar_bank_app:TransferByCitizen(from_cid, to_cid, amount_minor, reason, opts)
```

### Side effects need failure strategy

If money succeeds but ownership fails, the migration must define what happens.

Valid strategies:

- manual recovery
- compensation/refund
- escrow/hold-and-release
- blocking migration until support exists

### Every operation needs evidence

Hardening must produce audit/movement/DB evidence, not only successful gameplay behavior.

## Pre-Flight Checklist

Complete before changing code.

- [ ] Safe Integration document was applied first or the flow was explicitly classified as hardening scope.
- [ ] Sandbox or disposable database is available.
- [ ] Original files and relevant DB tables are backed up.
- [ ] You know every payer and receiver.
- [ ] You know whether receivers can be offline.
- [ ] You know whether ownership/inventory/vehicle state changes.
- [ ] You know the intended rollback or compensation strategy.
- [ ] You know the SONAR API required.
- [ ] You have QA commands available for balances, audit, movements, and account state.
- [ ] You can test frozen account, insufficient funds, and offline recipient behavior.

## Hardening Classification Matrix

| Pattern | Hardening Type | Primary API | Required Strategy |
|---|---|---|---|
| Online player-to-player transfer | Transfer hardening | `TransferBySource` | Stop on failed transfer. Side effects after `ok`. |
| Offline-capable player transfer | Transfer hardening | `TransferByCitizen` | Validate both citizens and offline account existence. |
| Marketplace sale with offline seller | Marketplace hardening | `TransferByCitizen` | Manual recovery, compensation, or escrow for ownership failure. |
| Direct SQL credit/debit to `players.money` | SQL hardening | Intent-specific API | Replace SQL with SONAR operation. No legacy write remains. |
| Society/job/business payout | Business account hardening | Dedicated business/society contract | Define account model and permissions. |
| Player commission + society deposit | Split payout hardening | Player API + business contract | Classify each money movement separately. |
| Admin set balance | Admin hardening | Admin API | Actor, ACE, reason, audit, target identity. |
| Loan/finance/debt | Ledger hardening | Dedicated contract | State machine and idempotency strategy. |
| Escrow-like flow | Escrow hardening | Escrow/hold contract if available | Hold, release, refund, expiry states. |

## Rule For Advanced Patterns

Do not start coding until these questions are answered:

1. Who pays?
2. Who receives?
3. Can the receiver be offline?
4. Does the flow change ownership, inventory, vehicle state, access, or database state?
5. What happens if money succeeds but the side effect fails?
6. What happens if the side effect succeeds but notification/mail fails?
7. Is there an audit reason?
8. Is there an idempotency or correlation strategy?
9. Is rollback manual, automatic, or admin-mediated?
10. What exact evidence proves the flow is safe?

If any answer is unknown, keep the flow blocked.

## SONAR API Selection

| Intent | Candidate API |
|---|---|
| Online player credit | `AddMoney(src, amount_minor, reason, opts)` |
| Online player debit | `RemoveMoney(src, amount_minor, reason, opts)` |
| Offline player credit | `AddMoneyByCitizen(citizenid, amount_minor, reason, opts)` |
| Offline player debit | `RemoveMoneyByCitizen(citizenid, amount_minor, reason, opts)` |
| Online player-to-player transfer | `TransferBySource(from_src, to_src, amount_minor, reason, opts)` |
| Offline-capable player transfer | `TransferByCitizen(from_cid, to_cid, amount_minor, reason, opts)` |
| IBAN transfer | `TransferByIban` if available and appropriate |
| Admin correction | Admin API with actor and reason |
| Business/society account | Dedicated business/society API or contract required |

Do not guess API usage. If the target account model does not exist, design it first.

## Advanced Pattern A — Online Player-To-Player Transfer

Use when both players are online and the flow is only a money transfer.

Legacy risky pattern:

```lua
sender.Functions.RemoveMoney('bank', amount, reason)
receiver.Functions.AddMoney('bank', amount, reason)
```

Preferred migration:

```lua
local ok, err, data = exports.sonar_bank_app:TransferBySource(from_src, to_src, amount_minor, reason, opts)
if not ok then
    TriggerClientEvent('QBCore:Notify', from_src, Lang:t('error.notenoughmoney'), 'error')
    return
end
```

Rules:

- Remove separate debit and credit.
- Side effects happen only after `ok == true`.
- Validate both players are online before calling.
- Do not use this if receiver can be offline.

Required tests:

- enough funds
- insufficient funds
- sender frozen
- receiver frozen if supported
- invalid receiver
- duplicate request/idempotency if applicable

## Advanced Pattern B — Offline-Capable Marketplace Sale

Use when buyer is online but seller may be offline.

Typical legacy signs:

```lua
Player.Functions.RemoveMoney('bank', price, reason)
SellerData.Functions.AddMoney('bank', payout, reason)
local money = json.decode(row.money)
money.bank = money.bank + payout
MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', ...)
```

Preferred money API when buyer and seller citizen IDs are known:

```lua
local ok, err, data = exports.sonar_bank_app:TransferByCitizen(buyer_cid, seller_cid, amount_minor, reason, opts)
if not ok then
    TriggerClientEvent('QBCore:Notify', buyer_src, Lang:t('error.not_enough_money'), 'error')
    return
end
```

Recommended order:

1. Load listing by immutable ID.
2. Validate listing still exists.
3. Validate buyer is not seller.
4. Validate buyer citizen ID.
5. Validate seller citizen ID.
6. Validate amount and fee/payout rules.
7. Execute `TransferByCitizen`.
8. If transfer fails, stop and do not change ownership.
9. Insert new ownership row.
10. Delete marketplace listing.
11. Send mail/notifications.
12. Record evidence.

Critical risk:

```text
TransferByCitizen OK, but ownership insert fails.
```

Choose one failure strategy before migration:

| Strategy | Meaning | When Acceptable |
|---|---|---|
| Manual recovery | Log critical error and let admin resolve. | Small servers, low-volume flow, strong audit evidence. |
| Compensation | Attempt reverse transfer/refund on side-effect failure. | Only if refund failure handling is also designed. |
| Escrow | Hold funds until ownership succeeds, then release. | Best long-term model, requires escrow support. |
| Keep blocked | Do not migrate until safe primitive exists. | High-value assets or no recovery plan. |

If no strategy is chosen, keep the flow blocked.

## Advanced Pattern C — Direct SQL Money Write

Legacy example:

```lua
local money = json.decode(row.money)
money.bank = money.bank + amount
MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(money), citizenid })
```

Never keep this in a migrated bank flow.

Why it is blocked:

- bypasses SONAR balance authority
- bypasses audit ledger
- bypasses frozen account checks
- bypasses idempotency
- bypasses movement history
- can desync HUD and account state

Replacement depends on intent:

| Intent | Candidate API |
|---|---|
| Offline player credit | `AddMoneyByCitizen` |
| Offline player debit | `RemoveMoneyByCitizen` |
| Offline player-to-player transfer | `TransferByCitizen` |
| Admin balance correction | Admin API with actor and reason |
| Business/society account | Dedicated business/society contract required |

Rules:

- Remove the SQL money write.
- Do not update `players.money` for bank balance after SONAR migration.
- Record audit/movement evidence.
- Validate account frozen behavior.

## Advanced Pattern D — Purchase With Seller Commission

Example: dealership sale where buyer pays and salesperson receives commission.

Classify each money movement separately:

| Money Movement | Action |
|---|---|
| Buyer player debit | Use `RemoveMoney` or transfer recipe. |
| Salesperson player commission | Player `AddMoney` may be valid after buyer payment succeeds. |
| Job/society/business deposit | Requires business/society account design. |

Rules:

- Do not pay commission before buyer payment succeeds.
- Do not convert society payout into player payout.
- Do not silently remove legacy commission.
- If business deposit is unavailable, mark it `DEFERRED` and record evidence.

## Advanced Pattern E — Job/Society/Business Account Payout

Legacy examples:

```lua
exports['qb-banking']:AddMoney('realestate', amount, reason)
exports['qb-management']:AddMoney(job, amount)
```

This requires a business/society account model.

Required design:

- account owner model
- account identifier format
- account lifecycle
- permissions/ACE model
- who can view balance
- who can deposit/withdraw
- whether account can be frozen
- whether payouts are reversible
- audit reason format
- reconciliation strategy

Until this exists, the payout remains blocked or deferred.

## Advanced Pattern F — Admin Set Balance

Legacy example:

```lua
Player.Functions.SetMoney('bank', amount, reason)
```

Do not migrate this without admin context.

Required fields:

- admin actor source
- target identity
- reason
- ACE permission context
- audit trail
- confirmation that this is not normal economy logic

Required tests:

- admin allowed
- admin denied
- target online
- target offline if supported
- invalid amount
- audit row contains actor and reason

## Advanced Pattern G — Finance, Debt, Loan, Or Recurring Payment

These flows are not simple money operations.

They require a state model:

- principal
- paid amount
- remaining balance
- due date
- late state
- closed state
- failed payment state
- cancellation/refund rules
- idempotency key per payment

Do not migrate finance/debt by replacing only `RemoveMoney('bank')`.

Use a dedicated contract or keep blocked.

## Advanced Pattern H — Escrow-Like Flow

Use when money should be reserved before a side effect is finalized.

Examples:

- marketplace sale
- auction
- property transfer
- high-value item trade
- service deposit

Required states:

```text
created
funds_held
released
refunded
expired
failed
```

If no escrow primitive exists, choose manual recovery or compensation explicitly, or keep the flow blocked.

## Failure Strategy Guide

| Failure Point | Risk | Possible Strategy |
|---|---|---|
| Money fails before side effects | Safe failure. | Return error and do nothing. |
| Money succeeds, ownership insert fails | Buyer paid but did not receive asset. | Manual recovery, compensation, or escrow. |
| Ownership succeeds, seller credit fails | Asset moved but seller unpaid. | Avoid by transfer first or escrow. |
| Listing delete fails after ownership insert | Duplicate listing risk. | Retry delete, mark listing sold, or admin cleanup. |
| Notification/mail fails | Usually non-financial. | Log only; do not reverse money. |
| Audit lookup missing | Evidence gap. | Stop rollout until audit issue resolved. |

## Evidence Required

For every Economy Hardening migration, record:

```text
Migration path: Economy Hardening
Resource:
File:
Flow/event:
Pattern:
Why Safe Integration stopped:
Payer identity:
Receiver identity:
Can receiver be offline: yes/no
SONAR API used:
Chosen failure strategy:
Idempotency/correlation strategy:

Before payer balance_minor:
Before receiver balance_minor:
Action:
Expected payer delta_minor:
Expected receiver delta_minor:
After payer balance_minor:
After receiver balance_minor:

Audit evidence:
Movement evidence:
DB/ownership evidence:
Notification/mail evidence:
Rollback/compensation evidence:

Positive path: PASS/FAIL
Insufficient funds path: PASS/FAIL
Frozen payer path: PASS/FAIL
Frozen receiver path: PASS/FAIL
Offline recipient path: PASS/FAIL
Duplicate request path: PASS/FAIL
Notes:
```

Recommended QA commands if available:

```text
qa_get_balance <src>
qa_get_balance_by_citizen <citizenid>
qa_transfer_by_source <from_src> <to_src> <amount_minor> <reason>
qa_transfer_by_citizen <from_cid> <to_cid> <amount_minor> <reason>
qa_audit_recent bank_debit 10
qa_audit_recent bank_credit 10
qa_movement <account_or_iban>
```

## Rollback And Recovery

Before migration, define one rollback path.

Possible rollback scopes:

- restore code only
- restore code and manually compensate money
- restore code and DB snapshot
- admin correction with audit note
- replay failed side effect

Do not run advanced migration on production without a recovery path.

## Customer-Facing Positioning

Economy Hardening is for customers who want more than installation.

It improves security and correctness by replacing unsafe legacy economy behavior with audited, controlled, and recoverable SONAR flows.

This path may require developer time, server-specific decisions, and new business-account contracts.

The benefit is a stronger economy:

- fewer desyncs
- less direct SQL money mutation
- better audit trail
- better frozen account enforcement
- safer offline transfers
- clearer admin recovery
- stronger protection against accidental duplication or silent payout failure
