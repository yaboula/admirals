# SONAR Bank QBCore Safe Integration Guide

## Purpose

This guide is for customers who want to integrate SONAR Bank into a QBCore server safely without redesigning the whole economy.

The goal is:

```text
Install SONAR Bank.
Migrate safe player-bank flows.
Avoid breaking custom economy logic.
Document dangerous flows instead of patching them blindly.
```

This path is the recommended default for most servers.

## What This Path Is

Safe Integration means SONAR Bank becomes authoritative for migrated player bank balances while the operator avoids high-risk economy redesign.

This path focuses on:

- simple player bank credits
- simple player bank debits
- purchases where one player pays the server
- refunds where one player receives money from the server
- manual reorder of one-player flows where side effects happen before payment
- clear evidence and rollback

## What This Path Is Not

This path does not migrate:

- cash
- crypto
- inventory currency
- job metadata
- society accounts
- business accounts
- framework internals
- direct SQL money systems
- multi-party marketplaces
- offline seller payouts
- full economy redesign

If one of those appears inside a migrated flow, mark it `DEFERRED` or escalate to Economy Hardening.

## Core Principle

After a flow is migrated, SONAR Bank is the authority for that bank operation.

Do not keep QBCore bank balance as a decision gate.

Wrong after migration:

```lua
if Player.PlayerData.money['bank'] >= price then
    exports.sonar_bank_app:RemoveMoney(src, price * 100, reason, nil)
end
```

Correct after migration:

```lua
local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, price * 100, reason, nil)
if not ok then
    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    return
end
```

## Mandatory Safety Rules

- **Work in sandbox first:** Never migrate directly on production.
- **Back up every changed file:** Keep original files or `.bak` backups.
- **Player bank only:** Do not migrate cash, crypto, inventory, jobs, society/business accounts, or framework internals in this path.
- **Do not patch `qb-core`:** Patch downstream resources only.
- **Do not duplicate money operations:** Never call both SONAR `RemoveMoney` and QBCore `RemoveMoney('bank')` for the same operation.
- **Check `ok`:** Never ignore SONAR export return values.
- **Money before side effects:** Debit/credit must succeed before item, vehicle, house, ownership, or destructive DB changes.
- **Treat HUD separately:** Do not re-add QBCore bank mutation just to update legacy HUD.

## Simple End-To-End Process

Use this process for every resource.

1. Prepare sandbox and backup.
2. Pick one resource.
3. Search bank patterns.
4. Classify each match.
5. Apply safe replacements only when safe.
6. Manually reorder risky one-player flows.
7. Add `sonar_bank_app` dependency if needed.
8. Restart the resource.
9. Run positive and negative tests.
10. Record evidence before moving to the next resource.

Do not migrate ten resources and then debug all failures at once.

## Four Routes In Safe Integration

Every bank-money pattern must be assigned to one route before changing code.

| Route | Use When | Action |
|---|---|---|
| `ROUTE 1 — Simple Replacement` | One player bank debit/credit, no ownership, no DB side effects, no second party. | Replace with SONAR API and check `ok`. |
| `ROUTE 2 — Manual Reorder` | One player bank debit/credit controls item, vehicle, house, inventory, or DB side effect. | Move SONAR money operation before irreversible effects. Continue only when `ok == true`. |
| `ROUTE 3 — Escalate To Economy Hardening` | Multi-party transfer, offline recipient, direct SQL money write, society/job/business payout, admin set balance, unknown account model. | Stop Safe Integration for this flow. Use `SONAR_BANK_QBCORE_ECONOMY_HARDENING.md`. |
| `ROUTE 4 — Out Of Scope` | Cash, crypto, inventory, jobs, society/business balances, framework internals. | Do not migrate in Safe Integration. Mark as `DEFERRED` if it appears inside a migrated flow. |

A blocker is not a failure. It is a boundary between Safe Integration and Economy Hardening.

## Pattern Decision Matrix

| Pattern Found | Route | Risk | What To Do | Stop Condition |
|---|---|---|---|---|
| Simple player reward to bank | `ROUTE 1` | `LOW` | Use `AddMoney(src, amount_minor, reason, opts)` and check `ok`. | Reward is part of a split payout or commission. |
| Simple player bank purchase | `ROUTE 1` or `ROUTE 2` | `MEDIUM` | Use `RemoveMoney` as the gate. | Purchase grants item/vehicle/house or writes DB rows. |
| Purchase grants item, vehicle, house, weapon, or access | `ROUTE 2` | `CRITICAL` | Debit first, then grant only if `ok == true`. | More than one player/account receives money. |
| Refund after cancellation | `ROUTE 2` | `HIGH` | Confirm cancellation state first, credit with `AddMoney`, then update state. | Refund is part of a larger transfer reversal. |
| Sale to server/NPC | `ROUTE 2` | `CRITICAL` | Credit player first, then remove item/vehicle only if credit succeeds. | Sale also pays another player/business. |
| Online player-to-player transfer | `ROUTE 3` | `BLOCKER` | Stop Safe Integration. | Any direct debit+credit pair exists. |
| Offline-capable marketplace | `ROUTE 3` | `BLOCKER` | Stop Safe Integration. | Seller/receiver may be offline. |
| Job/society/business commission | `ROUTE 3` or `ROUTE 4` | `BLOCKER` | Defer unless business migration exists. | Legacy `qb-banking` semantics are unclear or export missing. |
| Direct SQL write to `players.money` | `ROUTE 3` | `BLOCKER` | Stop Safe Integration. | Any SQL write bypasses SONAR. |
| `SetMoney('bank')` | `ROUTE 3` | `BLOCKER` | Admin/set-balance review required. | No admin actor, ACE context, or audit reason. |
| Balance display only | `ROUTE 1` | `LOW` | Use `GetBalance` and convert minor units for display. | Display value is used to approve purchase. |
| Cash, crypto, inventory, job metadata | `ROUTE 4` | `OUT OF SCOPE` | Do not migrate. | It is mixed with player bank money in same branch. |

## Pre-Flight Checklist

Complete before changing code.

- [ ] You are working on sandbox, not production.
- [ ] Database is backed up or disposable.
- [ ] Original resource files are backed up.
- [ ] `sonar_bank_app` starts without errors.
- [ ] The target player has a SONAR account.
- [ ] The target account is not frozen unless testing frozen behavior.
- [ ] You know the player's starting SONAR balance.
- [ ] You know which resource and flow you are testing.
- [ ] You have server console open for Lua parse errors and SONAR errors.
- [ ] You can restart one resource at a time.

## Search Patterns

Search one resource at a time.

```text
AddMoney('bank'
RemoveMoney('bank'
GetMoney('bank'
PlayerData.money['bank']
money['bank']
money.bank
SetMoney('bank'
players.money
qb-banking
qb-management
```

## Risk Classification

| Risk | Meaning | Action |
|---|---|---|
| `LOW` | Simple one-player bank credit/debit with no side effects. | Replace with SONAR export and `ok` check. |
| `MEDIUM` | Debit already gates a small local flow. | Rewrite condition carefully and test. |
| `HIGH` | Cash fallback, callbacks, notifications, or multiple local branches. | Manual review. |
| `CRITICAL` | Money happens after DB write, vehicle/item/house grant, or success notification. | Reorder flow: money first, side effects only after `ok`. |
| `BLOCKER` | Multi-party, offline recipient, direct SQL money, society/business, admin set, unknown units. | Stop Safe Integration and escalate. |

## Replacement Rules

### Add bank money

QBCore:

```lua
Player.Functions.AddMoney('bank', amount, reason)
```

SONAR:

```lua
local amountMinor = math.floor(tonumber(amount) * 100)
local ok, err, data = exports.sonar_bank_app:AddMoney(src, amountMinor, reason, nil)
if not ok then
    print(('[sonar_migration] AddMoney failed src=%s amount_minor=%s err=%s'):format(tostring(src), tostring(amountMinor), tostring(err)))
    return
end
```

### Remove bank money

QBCore:

```lua
Player.Functions.RemoveMoney('bank', amount, reason)
```

SONAR:

```lua
local amountMinor = math.floor(tonumber(amount) * 100)
local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, amountMinor, reason, nil)
if not ok then
    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    return
end
```

### Read bank balance for display

QBCore:

```lua
local bank = Player.PlayerData.money['bank']
```

SONAR:

```lua
local ok, err, data = exports.sonar_bank_app:GetBalance(src)
local bank = ok and data and math.floor((data.balance_minor or 0) / 100) or 0
```

Use this only for display. For purchase approval, use `RemoveMoney` or `CanAfford`.

### Check affordability

For purchases, prefer direct `RemoveMoney` as the gate.

If a non-mutating check is required:

```lua
local ok, err, data = exports.sonar_bank_app:CanAfford(src, amountMinor)
if ok and data and data.sufficient then
    -- display or non-mutating decision only
end
```

Do not use QBCore `bank >= price` for migrated purchases.

## Which SONAR API To Use

| Context | You have | Use |
|---|---|---|
| Online player debit | `src` | `RemoveMoney(src, amount_minor, reason, opts)` |
| Online player credit | `src` | `AddMoney(src, amount_minor, reason, opts)` |
| Online balance display | `src` | `GetBalance(src)` |
| Online affordability check | `src` | `CanAfford(src, amount_minor)` |
| Offline citizen debit | `citizenid` only | Stop Safe Integration unless the flow is simple and approved. |
| Offline citizen credit | `citizenid` only | Stop Safe Integration unless the flow is simple and approved. |
| Player-to-player transfer | two players/accounts | Economy Hardening path. |
| Admin credit/debit/set | admin actor + target | Economy Hardening path. |
| Business/society account | job/business account | Economy Hardening path. |

Do not guess a `src` from a `citizenid`.

## fxmanifest Dependency

Any resource that calls `exports.sonar_bank_app:*` must depend on `sonar_bank_app`.

Correct:

```lua
dependencies {
    'qb-core',
    'sonar_bank_app',
}
```

If the dependencies block already exists, keep valid Lua table syntax.

Wrong:

```lua
dependencies {
    'qb-core'
    'sonar_bank_app',
}
```

The previous last dependency needs a comma before adding `sonar_bank_app`.

## Manual Rewrite Template For Purchases

Use this for one-player purchases that grant vehicles, houses, items, weapons, or access.

```lua
local price = tonumber(vehiclePrice)
local amountMinor = price and math.floor(price * 100) or nil
local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, amountMinor, 'purchase reason', nil)
if not ok then
    print(('[sonar_migration] purchase debit failed src=%s amount_minor=%s err=%s'):format(tostring(src), tostring(amountMinor), tostring(err)))
    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    return
end

-- Only after ok == true:
-- insert DB ownership row
-- grant vehicle/item/house
-- send success notification
```

## Manual Rewrite Template For Sale To Server/NPC

Use this when a player sells an item or vehicle to the server.

Wrong order:

```lua
MySQL.query.await('DELETE FROM player_vehicles WHERE plate = ?', { plate })
Player.Functions.AddMoney('bank', payout, 'sold vehicle back')
```

Safe order:

```lua
-- confirm ownership first with SELECT or equivalent
local amountMinor = math.floor(tonumber(payout) * 100)
local ok, err, data = exports.sonar_bank_app:AddMoney(src, amountMinor, 'sold vehicle back', nil)
if not ok then
    print(('[sonar_migration] sale credit failed src=%s amount_minor=%s err=%s'):format(tostring(src), tostring(amountMinor), tostring(err)))
    return
end

-- only after credit succeeds:
-- delete vehicle/item from owned state
-- notify success
```

## Cash Fallback + Bank Fallback

Some scripts try cash first, then bank.

Safe structure:

```lua
if cash >= price then
    Player.Functions.RemoveMoney('cash', price, reason)
    -- continue success flow
else
    local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, math.floor(price * 100), reason, nil)
    if not ok then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
        return
    end
    -- continue same success flow
end
```

Do not keep this after migration:

```lua
elseif bank >= price then
```

## Job, Society, Business, And Commission Payouts

Safe Integration migrates player bank money only.

Do not treat this as player `AddMoney`:

```lua
exports['qb-banking']:AddMoney('realestate', amount, 'House purchase')
```

This is a job/society/business account payout.

If found inside a migrated flow:

1. Migrate only the player bank operation if safe.
2. Do not guess a SONAR replacement for the job/business payout.
3. Do not silently delete it.
4. If the legacy export is missing, comment or disable only with an explicit `DEFERRED` note.
5. Record the deferred payout in evidence.
6. Revisit under Economy Hardening.

Example:

```lua
-- DEFERRED Economy Hardening: legacy qb-banking society payout unavailable in this server.
-- Original intent: credit realestate commission after successful purchase.
-- exports['qb-banking']:AddMoney('realestate', commission, 'House purchase')
```

## Error Handling

Common SONAR errors:

- `INSUFFICIENT_FUNDS`: balance too low.
- `ACCOUNT_FROZEN`: account exists but is frozen.
- `ACCOUNT_NOT_FOUND`: no SONAR account exists for this identity.
- `PLAYER_NOT_FOUND`: invalid or disconnected source.
- `PLAYER_NOT_LOADED`: identity bridge is not ready.
- `INVALID_AMOUNT`: amount is not valid integer minor units.
- `ACCOUNT_CLOSED`: account is closed.

Temporary diagnostic log:

```lua
print(('[sonar_migration] debit failed src=%s amount_minor=%s err=%s data=%s'):format(
    tostring(src), tostring(amountMinor), tostring(err), json.encode(data)
))
```

Remove or reduce noisy logs after validation.

## Units

SONAR uses integer minor units.

| Display amount | SONAR amount_minor |
|---|---:|
| `10.00` | `1000` |
| `100.00` | `10000` |
| `10000.00` | `1000000` |
| `50000.00` | `5000000` |

Use:

```lua
local amountMinor = math.floor(tonumber(amount) * 100)
```

Never pass decimal major units directly into SONAR exports.

## HUD And Bank Notification Compatibility

A correct SONAR debit does not automatically mean every legacy HUD or bank notification updates.

Validate separately:

- SONAR balance changed.
- SONAR audit row exists.
- SONAR movement row exists.
- StateBag balance publish occurred if required.
- HUD refresh event or UI consumer updates display.
- Bank notification appears if expected.

Do not solve HUD issues by re-running QBCore bank mutation.

## Resource-Level Checklist

For each resource:

- [ ] Make backup.
- [ ] Search all bank call sites.
- [ ] Assign each pattern to Route 1, 2, 3, or 4.
- [ ] Apply safe Route 1 replacements.
- [ ] Manually reorder Route 2 flows.
- [ ] Mark Route 3 flows for Economy Hardening.
- [ ] Mark Route 4 flows as `DEFERRED`.
- [ ] Ensure `fxmanifest.lua` depends on `sonar_bank_app` if needed.
- [ ] Restart only the changed resource if possible.
- [ ] Check server console for Lua parse errors.
- [ ] Run positive test.
- [ ] Run insufficient funds test.
- [ ] Run frozen account test where possible.
- [ ] Confirm no item/vehicle/house is granted when debit fails.
- [ ] Confirm audit/movement rows.
- [ ] Confirm HUD/UI behavior or document compatibility gap.

## QA Evidence Template

Record one evidence block per migrated flow.

```text
Migration path: Safe Integration
Resource:
File:
Flow/event:
Route:
Risk level:
Migration type: simple replacement / manual reorder / deferred

Player source:
Citizen ID:
Account status:

Before balance_minor:
Action:
Expected delta_minor:
After balance_minor:

Audit evidence:
Movement evidence:
DB/ownership evidence:
HUD/UI result:

Positive path: PASS/FAIL
Negative insufficient funds path: PASS/FAIL
Negative frozen account path: PASS/FAIL
Deferred items:
Notes:
```

Recommended QA commands if available:

```text
qa_get_balance <src>
qa_audit_recent bank_debit 5
qa_audit_recent bank_credit 5
qa_vehicle_recent_by_src <src> 10
```

## Live Validation Matrix

### Positive path

- Player has enough SONAR balance.
- Action succeeds.
- SONAR balance changes exactly once.
- DB/ownership side effect occurs exactly once.
- Audit row exists.
- Movement row exists.
- HUD/UI is correct or documented.

### Negative path: insufficient funds

- Player does not have enough SONAR balance.
- Action fails.
- No DB/ownership row is created.
- No item/vehicle/house is granted.
- Player receives error notification.

### Negative path: frozen account

- Account is frozen.
- Action fails.
- No side effect occurs.
- Error logs show `ACCOUNT_FROZEN`.

### Restart/rollback path

- Restart resource.
- Re-run same scenario.
- Confirm no duplicate grants or duplicate debits.
- Confirm backup restores original file.

## Rollback Procedure

Use rollback immediately if the resource fails to parse or starts producing uncontrolled side effects.

1. Stop or restart only the affected resource.
2. Restore original file from backup.
3. Restore `fxmanifest.lua` if dependency syntax broke.
4. Restart the resource.
5. Confirm server console is clean.
6. Re-apply migration to one function only.
7. Re-test before touching another function.

Do not continue migrating other resources while one resource is broken.

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `ACCOUNT_FROZEN` | SONAR account is frozen. | Unfreeze for normal tests or keep frozen for negative validation. |
| `INSUFFICIENT_FUNDS` | SONAR balance is lower than amount. | Check `qa_get_balance`; remember minor units. |
| `INVALID_AMOUNT` | Amount is nil, decimal, string, negative, or not minor units. | Use `tonumber`, validate, then `math.floor(amount * 100)`. |
| `ACCOUNT_NOT_FOUND` | Player has no SONAR account. | Ensure account creation/bootstrap ran. |
| Item/vehicle/house granted but balance unchanged | Money operation happens after side effect or `ok` is ignored. | Move SONAR operation before grant and return on failure. |
| Enough SONAR balance but purchase says no money | Legacy QBCore bank pre-gate remains. | Remove `bank >= price`; use SONAR debit as gate. |
| Lua parse error near `else` | Converted `elseif bank` incorrectly or duplicate `else` remains. | Inspect full `if/else/end` block and simplify. |
| HUD or bank notification does not update | UI still listens to QBCore money changes. | Add display refresh or migrate HUD to SONAR StateBag/events; do not duplicate money operation. |
| Resource cannot find `sonar_bank_app` export | Missing dependency or resource start order. | Add `sonar_bank_app` to dependencies and ensure start order. |
| `qb-banking:AddMoney` export missing | Legacy society/job banking is unavailable or out of scope. | Do not convert to player `AddMoney`; mark `DEFERRED`. |

## When To Stop Safe Integration

Stop Safe Integration for the flow and move it to Economy Hardening when:

- Source player cannot be resolved.
- Offline citizen IDs and online sources are mixed.
- Script pays multiple parties in one transaction.
- Script modifies SQL money columns directly.
- Script uses `SetMoney('bank')`.
- Script has job/society/business payout.
- Script uses a marketplace seller who can be offline.
- Script needs compensation, escrow, or rollback design.
- You cannot determine whether amount is major units or minor units.

## Customer-Facing Positioning

Safe Integration is not a blind search-and-replace.

It is a controlled integration path that gets SONAR Bank working without forcing a full economy redesign.

The customer keeps control over critical economy logic because dangerous flows are documented, deferred, or escalated instead of patched blindly.

A blocker is not a failed migration. It means the flow belongs to Economy Hardening.
