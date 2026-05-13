# SONAR Bank QBCore Advanced Migration Patterns

## Purpose

This document covers QBCore migration patterns that are possible to migrate, but are not safe for simple operator-level replacement.

Use this document only after the main guide classifies a flow as:

```text
ROUTE 3 — Blocker / Advanced Pattern
```

The goal is to reduce confusion and protect the customer's economy. A `BLOCKER` is not always impossible. It means the flow needs a dedicated design before code changes.

## Rule For Advanced Patterns

Do not start coding until these questions are answered:

1. Who pays?
2. Who receives?
3. Can the receiver be offline?
4. Does the flow change ownership, inventory, vehicle state, or database state?
5. What happens if money succeeds but the side effect fails?
6. What happens if the side effect succeeds but notification/mail fails?
7. Is there an audit reason and idempotency/correlation strategy?
8. Is rollback manual, automatic, or admin-mediated?

If any answer is unknown, keep the flow blocked.

## Advanced Pattern A — Online Player-To-Player Transfer

Use when both players are online and the flow is only a money transfer.

Preferred API:

```lua
local ok, err, data = exports.sonar_bank_app:TransferBySource(from_src, to_src, amount_minor, reason, opts)
if not ok then
    TriggerClientEvent('QBCore:Notify', from_src, Lang:t('error.notenoughmoney'), 'error')
    return
end
```

Safe only when:

- both sources are known and online
- no direct SQL money writes remain
- no separate debit and credit remain
- side effects happen only after `ok == true`

Stop if:

- receiver can be offline
- receiver is identified only by IBAN/citizenid
- transfer also grants ownership or deletes a marketplace listing

## Advanced Pattern B — Offline-Capable Marketplace Sale

Example: used vehicle sale where buyer is online and seller may be offline.

Typical legacy signs:

```lua
Player.Functions.RemoveMoney('bank', price, reason)
SellerData.Functions.AddMoney('bank', payout, reason)
BuyerMoney.bank = BuyerMoney.bank + payout
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
4. Validate buyer citizen ID and seller citizen ID.
5. Execute `TransferByCitizen`.
6. If transfer fails, stop and do not change ownership.
7. Insert new ownership row.
8. Delete marketplace listing.
9. Send mail/notifications.
10. Record evidence.

Important risk:

```text
TransferByCitizen OK, but ownership insert fails.
```

Choose one strategy before migration:

| Strategy | Meaning | When Acceptable |
|---|---|---|
| Manual recovery | Log critical error and let admin resolve. | Small servers or low-volume migration. |
| Compensation | Attempt reverse transfer/refund on side-effect failure. | Only if refund failure handling is also designed. |
| Escrow | Hold funds until ownership succeeds, then release. | Best long-term design, but requires escrow support. |

If no strategy is chosen, keep the flow blocked.

## Advanced Pattern C — Purchase With Seller Commission

Example: dealership sale where buyer pays and salesperson receives commission.

This is not a simple buyer debit.

Classify each money movement separately:

| Money Movement | Phase A Action |
|---|---|
| Buyer player debit | Migrate to `RemoveMoney` or transfer recipe. |
| Salesperson player commission | Possible player `AddMoney`, but only after buyer payment succeeds. |
| Job/society/business deposit | Out of scope unless business account migration exists. |

Do not convert a society account payout into a player payout.

## Advanced Pattern D — Job/Society/Business Account Payout

Legacy examples:

```lua
exports['qb-banking']:AddMoney('realestate', amount, reason)
exports['qb-management']:AddMoney(job, amount)
```

Phase A decision:

```text
DEFERRED unless a dedicated SONAR business/society account contract exists.
```

Required design before migration:

- account owner model
- account identifier format
- permissions/ACE model
- audit reason
- who can view balance
- whether the account can be frozen
- whether payouts are reversible

## Advanced Pattern E — Direct SQL Money Write

Legacy examples:

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

Possible replacements depend on intent:

| Intent | Candidate API |
|---|---|
| Offline player credit | `AddMoneyByCitizen` |
| Offline player debit | `RemoveMoneyByCitizen` |
| Offline player-to-player transfer | `TransferByCitizen` |
| Admin balance correction | Admin API with actor and reason |
| Business/society account | Dedicated business/society contract required |

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

## Evidence Required For Advanced Patterns

For every advanced migration, record:

```text
Resource:
File:
Flow:
Pattern:
Why it was BLOCKER:
Chosen recipe:
Chosen failure strategy:
Positive test:
Insufficient funds test:
Frozen account test:
Offline recipient test:
Audit/movement evidence:
DB side-effect evidence:
Rollback notes:
```

## Customer-Facing Rule

If the operator cannot explain the full money path in one sentence, do not migrate the flow yet.

Examples:

```text
Good: Player sells vehicle to server; server credits player; vehicle is deleted after credit succeeds.
Blocked: Buyer buys marketplace vehicle; seller may be offline; ownership changes; listing is deleted; seller gets paid.
```
