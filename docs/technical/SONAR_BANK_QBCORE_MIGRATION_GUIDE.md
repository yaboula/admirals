# SONAR Bank QBCore Migration Guide

## Migration Paths

SONAR Bank QBCore migration now has two independent paths.

Use one of these complete documents:

| Path | Document | Use When |
|---|---|---|
| Safe Integration | `SONAR_BANK_QBCORE_SAFE_INTEGRATION.md` | The customer wants to integrate SONAR Bank safely without redesigning the whole economy. |
| Economy Hardening | `SONAR_BANK_QBCORE_ECONOMY_HARDENING.md` | The customer wants to improve economy security, remove unsafe legacy patterns, and redesign advanced money flows. |

Use this AI prompt when the customer wants an IDE assistant to follow the two-path strategy:

```text
SONAR_BANK_QBCORE_AI_MIGRATION_PROMPT.md
```

This file remains as the historical combined migration guide. For customer delivery, prefer the path-specific documents above.

## Purpose

This guide explains how to migrate QBCore bank-money code to SONAR Bank safely.

It is designed for operators, developers, and AI-assisted IDE workflows. The goal is not blind automation. The goal is controlled migration with clear rules, review points, rollback, and live validation.

## Core Principle

After migration, SONAR Bank is the authoritative source for bank balances.

Do not keep QBCore bank balance as a decision gate for migrated bank flows.

```lua
-- Wrong after migration: QBCore legacy bank gate
if Player.PlayerData.money['bank'] >= price then
    exports.sonar_bank_app:RemoveMoney(src, price * 100, reason, nil)
end
```

```lua
-- Correct after migration: SONAR is the gate
local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, price * 100, reason, nil)
if not ok then
    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    return
end
```

## Mandatory Safety Rules

- **Work on a sandbox first:** Never migrate directly on the production server.
- **Back up every changed file:** Keep original files or `.bak` backups.
- **Player bank only in Phase A:** Do not migrate cash, crypto, inventory, jobs, society/business accounts, or framework internals as part of this phase.
- **Do not patch `qb-core`:** Patch downstream resources that call QBCore money APIs.
- **Do not duplicate debits:** Never call both SONAR `RemoveMoney` and QBCore `RemoveMoney('bank')` for the same bank operation.
- **Debit before irreversible effects:** For purchases, transfers, ownership changes, item grants, vehicle grants, and DB inserts, perform SONAR debit first and continue only if `ok == true`.
- **Treat HUD/UI separately:** A successful SONAR debit may require an additional UI refresh or StateBag consumer. Do not re-add QBCore bank mutation just to update HUD.

## Simple End-To-End Process

Use the same process for every resource.

1. Prepare sandbox and backup.
2. Pick one resource.
3. Search bank patterns.
4. Classify each match by risk.
5. Apply simple replacements only when safe.
6. Manually rewrite risky flows.
7. Add `sonar_bank_app` dependency if needed.
8. Restart the resource.
9. Run positive and negative tests.
10. Record evidence before moving to the next resource.

## Four Migration Routes

Every bank-money pattern must be assigned to one route before changing code.

| Route | Use When | Action |
|---|---|---|
| `ROUTE 1 — Simple Replacement` | One player bank debit/credit, no ownership, no DB side effects, no second party. | Replace with SONAR API and check `ok`. |
| `ROUTE 2 — Manual Reorder` | One player bank debit/credit controls an item, vehicle, house, inventory, or DB side effect. | Move SONAR money operation before irreversible effects. Continue only when `ok == true`. |
| `ROUTE 3 — Blocker / Advanced Pattern` | Multi-party transfer, offline recipient, direct SQL money write, society/job/business payout, admin set balance, or unknown account model. | Stop simple migration. Escalate or follow `SONAR_BANK_QBCORE_ADVANCED_PATTERNS.md`. |
| `ROUTE 4 — Out Of Scope` | Cash, crypto, inventory, jobs, society/business balances, framework internals. | Do not migrate in Phase A. Mark as `DEFERRED` if it appears inside a migrated flow. |

Do not skip route classification. Most migration mistakes happen when a `ROUTE 2` or `ROUTE 3` flow is treated like `ROUTE 1`.

Advanced patterns are still migrable, but not by this simple operator guide alone. Use `SONAR_BANK_QBCORE_ADVANCED_PATTERNS.md` only when a developer can define the full money path and failure strategy.

## Pattern Decision Matrix For Custom Scripts

Use this matrix for custom or heavily modified resources.

| Pattern Found | Route | Risk | What To Do | Stop Condition |
|---|---|---|---|---|
| Simple player reward to bank | `ROUTE 1` | `LOW` | Use `AddMoney(src, amount_minor, reason, opts)` and check `ok`. | Reward is part of a split payout or commission. |
| Simple player bank purchase | `ROUTE 1` or `ROUTE 2` | `MEDIUM` | Use `RemoveMoney` as the gate. | Purchase grants item/vehicle/house or writes DB rows. |
| Purchase grants item, vehicle, house, weapon, or access | `ROUTE 2` | `CRITICAL` | Debit first, then grant only if `ok == true`. | More than one player/account receives money. |
| Refund after cancellation | `ROUTE 2` | `HIGH` | Confirm cancellation state first, credit with `AddMoney`, then update state. | Refund is part of a larger transfer reversal. |
| Sale to server/NPC | `ROUTE 2` | `CRITICAL` | Credit player first, then remove item/vehicle only if credit succeeds. | Sale also pays another player/business. |
| Online player-to-player transfer | `ROUTE 3` | `BLOCKER` | Use a dedicated transfer recipe with `TransferBySource`. | Either player can be offline. |
| Offline-capable player sale or marketplace | `ROUTE 3` | `BLOCKER` | Use a dedicated transfer recipe with citizen/account APIs. | Flow also changes ownership and cannot tolerate partial failure. |
| Job/society/business commission | `ROUTE 4` or `ROUTE 3` | `BLOCKER` | Defer in Phase A unless a business-account migration exists. | Legacy `qb-banking` export is missing or semantics are unclear. |
| Direct SQL write to `players.money` | `ROUTE 3` | `BLOCKER` | Stop and escalate. Replace only through a dedicated SONAR account migration. | Any write bypasses SONAR audit, freeze, idempotency, or movements. |
| `SetMoney('bank')` | `ROUTE 3` | `BLOCKER` | Manual admin/set-balance review. | No admin actor, ACE context, or audit reason. |
| Balance display only | `ROUTE 1` | `LOW` | Use `GetBalance` and convert minor units for display. | Display value is used to approve a purchase. |
| Cash, crypto, inventory, job metadata | `ROUTE 4` | `OUT OF SCOPE` | Do not migrate in Phase A. | It is mixed into the same branch as player bank money. |

## Pre-Flight Checklist

Complete this before changing code.

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

## Migration Workflow

### Step 1 — Prepare a sandbox

Copy the server or target resources to a sandbox path.

Checklist:

- Server starts before migration.
- Database is isolated or snapshotted.
- You know which `.cfg` is used.
- `sonar_bank_app`, `sonar_bank`, `sonar_core`, and `sonar_bridges` start cleanly.
- You can run QA commands such as `qa_get_balance` if the QA probe is installed.

### Step 2 — Scan one resource at a time

Start with one resource. Do not migrate the whole server at once.

Recommended order:

1. Simple shops or rewards.
2. Sale/payout scripts.
3. Vehicle sales.
4. Houses.
5. Vehicle shop.
6. Any custom resource with inventory, ownership, or commission logic.

Search patterns:

```text
AddMoney('bank'
RemoveMoney('bank'
GetMoney('bank'
PlayerData.money['bank']
money['bank']
SetMoney('bank'
```

### Step 3 — Classify each call site

Use the risk table and buckets below.

### Risk Classification Table

| Risk | Meaning | Examples | Action |
|---|---|---|---|
| `LOW` | Single simple bank credit/debit with no nearby side effects. | Simple reward, simple payout. | Replace with SONAR export and `ok` check. |
| `MEDIUM` | Bank debit is already the condition for a small local flow. | `if RemoveMoney('bank') then give simple reward`. | Rewrite condition carefully and test. |
| `HIGH` | Cash fallback, bank fallback, UI notifications, or multiple branches. | `cash else bank`, conditional callbacks. | Manual review. Test positive and negative paths. |
| `CRITICAL` | Debit happens after DB write, vehicle/item/house grant, or success notification. | Vehicle purchase, house purchase, inventory grant. | Rewrite flow: SONAR debit first, side effects only after `ok == true`. |
| `BLOCKER` | Source/account cannot be resolved, direct SQL money writes, job/society/business payouts, `SetMoney('bank')`, or unknown units. | Admin set balance, realestate commission, custom SQL economy. | Stop and escalate or explicitly defer. |

Use three buckets.

#### Bucket A — Safe simple mutation

A bank mutation with no nearby irreversible side effect.

Example:

```lua
Player.Functions.AddMoney('bank', payout, 'sold item')
```

Migration:

```lua
local ok, err, data = exports.sonar_bank_app:AddMoney(src, math.floor(payout * 100), 'sold item', nil)
if not ok then
    print(('[sonar_migration] AddMoney failed src=%s err=%s'):format(tostring(src), tostring(err)))
    return
end
```

#### Bucket B — Conditional debit

A QBCore debit used as the condition.

Example:

```lua
if Player.Functions.RemoveMoney('bank', price, 'shop purchase') then
    giveItem()
else
    notifyNoMoney()
end
```

Migration:

```lua
local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, math.floor(price * 100), 'shop purchase', nil)
if ok then
    giveItem()
else
    notifyNoMoney()
    return
end
```

#### Bucket C — Manual review required

Any flow where money is near irreversible side effects.

Manual review is required when the same branch contains:

- `MySQL.insert`
- `MySQL.update`
- `MySQL.query` that writes or deletes
- `TriggerClientEvent` success notification
- vehicle grant
- house ownership update
- inventory/item grant
- weapon grant
- commission payout
- job/society/business payout
- `qb-banking` job account mutation
- player-to-player transfer
- ownership transfer

Do not patch these by simple replacement. Rewrite the flow.

## Replacement Rules

### Quick Replacement Table

Use this table as the first pass while reviewing each script.

| Find this pattern | Replace with | Safe to apply automatically? | Stop/manual review when |
|---|---|---|---|
| `Player.Functions.AddMoney('bank', amount, reason)` | `exports.sonar_bank_app:AddMoney(src, math.floor(amount * 100), reason, nil)` with `ok` check | Usually yes | The credit is part of a multi-party transaction, commission split, refund after failed purchase, or admin action. |
| `Player.Functions.RemoveMoney('bank', amount, reason)` | `exports.sonar_bank_app:RemoveMoney(src, math.floor(amount * 100), reason, nil)` with `ok` check | Only if no side effects happen before or after it | Same branch contains DB writes, item grant, vehicle grant, house ownership, success notification, commission payout, or transfer. |
| `if Player.Functions.RemoveMoney('bank', amount, reason) then` | `local ok = exports.sonar_bank_app:RemoveMoney(...); if ok then` | Sometimes | The `then` block grants ownership/items/vehicles or mutates multiple systems. |
| `elseif Player.Functions.RemoveMoney('bank', amount, reason) then` | `else` + SONAR debit inside the fallback branch | Sometimes | There is a legacy `bank` pre-gate or duplicated success flow that may create broken `else/end` structure. |
| `Player.PlayerData.money['bank']` | `exports.sonar_bank_app:GetBalance(src)` and convert `balance_minor / 100` | Display only | The value is used to approve a purchase. Use `RemoveMoney` or `CanAfford` instead. |
| `Player.Functions.GetMoney('bank')` | `exports.sonar_bank_app:GetBalance(src)` and convert `balance_minor / 100` | Display only | The value controls access, purchase, or ownership flow. |
| `if bank >= price then` | Prefer direct `RemoveMoney(src, price * 100, ...)` as the gate | No for purchases | Any migrated bank purchase still depends on QBCore `bank` value. |
| `Player.Functions.SetMoney('bank', amount, reason)` | Admin or explicit set-balance SONAR API after review | No | Always manual. Requires actor/admin context and audit reason. |
| Separate debit + credit for player transfer | `exports.sonar_bank_app:TransferBySource(from_src, to_src, amount_minor, reason, nil)` | No | Any transfer between two players or accounts. Use atomic transfer export. |
| `exports['qb-banking']:AddMoney(job, amount, reason)` | No Phase A replacement | No | Job/society/business account payout. Defer or migrate through a dedicated business/society contract. |
| Commission payout inside purchase flow | Do not migrate as player bank money | No | Mixed player debit + business/job credit flow. Debit player safely, then explicitly defer or separately design the commission path. |
| Direct SQL write to money/account columns | SONAR API or dedicated migration script | No | Always manual. Direct SQL can bypass audit, freeze, idempotency, and movement records. |

### Rule 1 — Add bank money

QBCore:

```lua
Player.Functions.AddMoney('bank', amount, reason)
```

SONAR:

```lua
local ok, err, data = exports.sonar_bank_app:AddMoney(src, math.floor(amount * 100), reason, nil)
if not ok then
    print(('[sonar_migration] AddMoney failed src=%s amount=%s err=%s'):format(tostring(src), tostring(amount), tostring(err)))
    return
end
```

### Rule 2 — Remove bank money

QBCore:

```lua
Player.Functions.RemoveMoney('bank', amount, reason)
```

SONAR:

```lua
local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, math.floor(amount * 100), reason, nil)
if not ok then
    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    return
end
```

### Rule 3 — Read bank balance

QBCore:

```lua
local bank = Player.PlayerData.money['bank']
```

SONAR:

```lua
local ok, err, data = exports.sonar_bank_app:GetBalance(src)
local bank = ok and data and math.floor((data.balance_minor or 0) / 100) or 0
```

Important: use this only for display or non-authoritative information. For purchase approval, use `RemoveMoney` or `CanAfford`.

### Rule 4 — Check if player can afford

QBCore:

```lua
if Player.PlayerData.money['bank'] >= price then
```

SONAR:

```lua
local ok, err, data = exports.sonar_bank_app:CanAfford(src, math.floor(price * 100))
if ok and data and data.sufficient then
```

For purchases, prefer direct `RemoveMoney` as the gate so the balance cannot change between check and debit.

### Rule 5 — Player-to-player bank transfer

Do not implement transfer as separate debit and credit unless there is no other option.

Preferred:

```lua
local ok, err, data = exports.sonar_bank_app:TransferBySource(from_src, to_src, math.floor(amount * 100), reason, nil)
if not ok then
    TriggerClientEvent('QBCore:Notify', from_src, Lang:t('error.notenoughmoney'), 'error')
    return
end
```

## Which SONAR API To Use

Choose the API from the context you really have.

| Context | You have | Use |
|---|---|---|
| Online player debit | `src` or `Player.PlayerData.source` | `RemoveMoney(src, amount_minor, reason, opts)` |
| Online player credit | `src` or `Player.PlayerData.source` | `AddMoney(src, amount_minor, reason, opts)` |
| Online balance display | `src` | `GetBalance(src)` |
| Online affordability check | `src` | `CanAfford(src, amount_minor)` |
| Online player-to-player transfer | `from_src` and `to_src` | `TransferBySource(from_src, to_src, amount_minor, reason, opts)` |
| Offline citizen debit | `citizenid` only | `RemoveMoneyByCitizen(citizenid, amount_minor, reason, opts)` |
| Offline citizen credit | `citizenid` only | `AddMoneyByCitizen(citizenid, amount_minor, reason, opts)` |
| Offline citizen balance | `citizenid` only | `GetBalanceByCitizen(citizenid)` |
| Offline citizen transfer | two citizen IDs | `TransferByCitizen(from_cid, to_cid, amount_minor, reason, opts)` |
| Admin credit/debit/set | admin actor + target | Admin API after manual review |

Do not guess a `src` from a `citizenid`. If the player is offline, use the citizen-based API.

## Admin And Set-Balance Flows

Treat admin money operations as manual.

Do not blindly replace:

```lua
Player.Functions.SetMoney('bank', amount, reason)
```

Admin flows need:

- actor/admin source
- ACE permission context
- explicit audit reason
- clear target identity
- confirmation that this is not normal gameplay economy logic

If you cannot identify the admin actor, stop and escalate.

## Job, Society, Business, And Commission Payouts

Phase A migrates player bank money only.

Do not treat these as player `AddMoney` calls:

```lua
exports['qb-banking']:AddMoney('realestate', amount, 'House purchase')
```

This is a job/society/business account payout, not a player bank balance mutation.

When a migrated purchase flow also contains job or business payouts:

1. Migrate the player debit with SONAR.
2. Do not guess a SONAR replacement for the job/business payout.
3. Do not silently delete the payout.
4. If the legacy export does not exist in the target server, comment or disable it only with an explicit `DEFERRED` note.
5. Record the deferred payout in the evidence file.
6. Revisit it in a separate business/society migration phase.

Example deferred note:

```lua
-- DEFERRED Phase B: legacy qb-banking society payout unavailable in this server.
-- Original intent: credit realestate commission after successful house purchase.
-- exports['qb-banking']:AddMoney('realestate', commission, 'House purchase')
```

Do not replace a job/society payout with `exports.sonar_bank_app:AddMoney(src, ...)` unless the recipient is truly the player.

## fxmanifest Dependency

Any resource that calls `exports.sonar_bank_app:*` must depend on `sonar_bank_app`.

Example:

```lua
dependencies {
    'qb-core',
    'sonar_bank_app',
}
```

If the dependencies block already exists, keep valid Lua table syntax.

Correct:

```lua
dependencies {
    'qb-core',
    'oxmysql',
    'sonar_bank_app',
}
```

Wrong:

```lua
dependencies {
    'qb-core'
    'sonar_bank_app',
}
```

The previous last dependency needs a comma before adding `sonar_bank_app`.

## Manual Rewrite Template For Purchases

Use this for vehicles, houses, items, weapons, and any ownership-granting purchase.

```lua
local price = tonumber(vehiclePrice)
local amountMinor = price and math.floor(price * 100) or nil
local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, amountMinor, 'purchase reason', nil)
if not ok then
    print(('[sonar_migration] purchase debit failed src=%s price=%s amount_minor=%s err=%s'):format(
        tostring(src), tostring(price), tostring(amountMinor), tostring(err)
    ))
    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    return
end

-- Only after ok == true:
-- 1. Insert DB ownership row
-- 2. Grant vehicle/item/house
-- 3. Send success notification
-- 4. Pay commissions if needed
```

## Manual Rewrite Template For Cash Fallback + Bank Fallback

Some QBCore scripts try cash first, then bank.

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

Do not use legacy QBCore bank as a pre-gate:

```lua
-- Do not keep this after migration
elseif bank >= price then
```

## Complete Example — Vehicle Purchase

Use this pattern for `qb-vehicleshop`-style flows.

### Before

Risky structure:

```lua
MySQL.insert('INSERT INTO player_vehicles ...')
TriggerClientEvent('QBCore:Notify', src, Lang:t('success.purchased'), 'success')
TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', src, vehicle, plate)
Player.Functions.RemoveMoney('bank', vehiclePrice, 'vehicle-bought-in-showroom')
```

Problem:

- vehicle is granted before debit
- DB ownership row is created before debit
- failure of bank debit does not block success
- simple replacement would still ignore `ok`

### After

Safe structure:

```lua
local price = tonumber(vehiclePrice)
local amountMinor = price and math.floor(price * 100) or nil
local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, amountMinor, 'vehicle-bought-in-showroom', nil)
if not ok then
    print(('[sonar_migration] vehicle debit failed src=%s vehicle=%s amount_minor=%s err=%s data=%s'):format(
        tostring(src), tostring(vehicle), tostring(amountMinor), tostring(err), json.encode(data)
    ))
    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    return
end

MySQL.insert('INSERT INTO player_vehicles ...')
TriggerClientEvent('QBCore:Notify', src, Lang:t('success.purchased'), 'success')
TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', src, vehicle, plate)
```

Validation:

- enough SONAR balance: vehicle is granted and balance decreases once
- insufficient SONAR balance: no vehicle, no DB row, error notification
- frozen SONAR account: no vehicle, no DB row, diagnostic shows `ACCOUNT_FROZEN`
- QBCore legacy bank value must not decide the purchase

## Error Handling

Always capture `err` while validating migration.

Common errors:

- `INSUFFICIENT_FUNDS`: SONAR account balance is too low.
- `ACCOUNT_FROZEN`: account exists but is frozen.
- `ACCOUNT_NOT_FOUND`: no SONAR account exists for the citizen.
- `PLAYER_NOT_FOUND`: source is invalid or disconnected.
- `PLAYER_NOT_LOADED`: identity bridge is not ready.
- `INVALID_AMOUNT`: amount is not an integer minor-unit number.
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

Examples:

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

Do not solve HUD issues by re-running QBCore bank mutation, because that can duplicate debits or reintroduce inconsistent balances.

Validate these separately:

- SONAR balance changed.
- SONAR audit row exists.
- SONAR movement row exists.
- StateBag balance publish occurred if required.
- HUD refresh event or UI consumer updates display.
- Bank notification appears if the server expects one.

If HUD does not update, add a display-only refresh or migrate the HUD to consume SONAR StateBag/events. Do not make QBCore bank authoritative again.

## Resource-Level Checklist

For each resource:

- [ ] Make backup.
- [ ] Search all bank call sites.
- [ ] Classify each call site as Bucket A, B, or C.
- [ ] Identify any job/society/business payout in the same flow and mark it `DEFERRED` unless a dedicated migration exists.
- [ ] Apply safe replacements.
- [ ] Manually rewrite Bucket C flows.
- [ ] Ensure `fxmanifest.lua` depends on `sonar_bank_app` if the resource calls SONAR exports.
- [ ] Restart only the changed resource if possible.
- [ ] Check server console for Lua parse errors.
- [ ] Run one positive test.
- [ ] Run one negative test with insufficient funds or frozen account.
- [ ] Confirm no item/vehicle/house is granted when debit fails.
- [ ] Confirm audit/movement rows.
- [ ] Confirm HUD/UI behavior or document compatibility gap.

## QA Evidence Template

Record one evidence block per migrated flow.

```text
Resource:
File:
Flow/event:
Risk level:
Migration type: simple replacement / manual rewrite

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

Minimum scenarios after migration:

### Positive path

- Player has enough SONAR balance.
- Purchase succeeds.
- SONAR balance decreases exactly once.
- DB/ownership row is created exactly once.
- Audit row exists.
- Movement row exists.
- HUD/UI is correct or documented.

### Negative path: insufficient funds

- Player does not have enough SONAR balance.
- Purchase fails.
- No DB/ownership row is created.
- No item/vehicle/house is granted.
- Player receives error notification.
- Audit shows overdraft/failed attempt if supported.

### Negative path: frozen account

- Account is frozen.
- Purchase fails.
- No side effect occurs.
- Error logs show `ACCOUNT_FROZEN`.

### Idempotency/rollback path

- Restart resource.
- Re-run same scenario.
- Confirm no duplicate grants or duplicate debits.
- Confirm rollback backup restores original file.

## Rollback Procedure

Use rollback immediately if the resource fails to parse or starts producing uncontrolled side effects.

1. Stop or restart only the affected resource.
2. Restore the original file from backup.
3. Restore `fxmanifest.lua` if dependency injection broke syntax.
4. Restart the resource.
5. Confirm the server console is clean.
6. Re-apply the migration to one function only.
7. Re-test before touching another function.

Do not continue migrating other resources while one resource is broken.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `ACCOUNT_FROZEN` | SONAR account is frozen. | Unfreeze for normal purchase tests or keep frozen for negative validation. |
| `INSUFFICIENT_FUNDS` | SONAR balance is lower than amount. | Check `qa_get_balance`; remember SONAR uses minor units. |
| `INVALID_AMOUNT` | Amount is `nil`, decimal, string, negative, or not minor units. | Use `tonumber`, validate, then `math.floor(amount * 100)`. |
| `ACCOUNT_NOT_FOUND` | Player has no SONAR account. | Ensure account creation/bootstrap ran for that identity. |
| Vehicle/item granted but balance unchanged | Debit happens after side effects or `ok` is ignored. | Move SONAR debit before grant and return on failure. |
| Enough SONAR balance but purchase says no money | Legacy QBCore bank pre-gate remains. | Remove `bank >= price` as authority; use SONAR debit as gate. |
| Lua parse error near `else` | `elseif bank` was converted incorrectly or duplicate `else` remains. | Inspect the full `if/else/end` block and simplify structure. |
| HUD or bank notification does not update | UI still listens to QBCore money changes. | Add display refresh or migrate HUD to SONAR StateBag/events; do not duplicate debit. |
| Resource cannot find `sonar_bank_app` export | Missing dependency or resource start order. | Add `sonar_bank_app` to `fxmanifest.lua` dependencies and ensure it starts first. |
| `qb-banking:AddMoney` export missing | Legacy society/job banking is unavailable or out of scope. | Do not convert to player `AddMoney`; mark payout `DEFERRED` and record evidence. |

## When To Stop And Escalate

Stop manual migration and escalate when:

- Source player cannot be resolved.
- Resource uses offline citizen IDs and online sources mixed together.
- Script grants items/vehicles before payment.
- Script pays multiple parties in one transaction.
- Script uses `SetMoney('bank')`.
- Script modifies SQL money columns directly.
- Script has custom HUD/bank notifications tied to QBCore internals.
- Script mixes player debit with job/society/business payout and no dedicated business-account migration exists.
- You cannot determine whether an amount is major units or minor units.

Some escalated flows are migrable with a developer-led recipe. For those, use `SONAR_BANK_QBCORE_ADVANCED_PATTERNS.md` instead of improvising inside this guide.

## Recommended Operator Flow

1. Migrate one resource.
2. Restart that resource.
3. Fix Lua parse errors immediately.
4. Validate positive and negative paths.
5. Record evidence.
6. Move to next resource.

Do not migrate ten resources and then debug all failures at once.

## Customer-Facing Positioning

This migration is not a blind search-and-replace.

A safe migration has two parts:

1. Mechanical replacements for simple money calls.
2. Manual review for business flows where money controls ownership, inventory, vehicles, houses, commissions, or transfers.

The manual review reduces risk. It does not mean the migration is unsupported. It means the customer keeps control over critical economy logic.

For advanced economy flows, the next step is not guessing. The next step is selecting a documented recipe, defining the failure strategy, and recording evidence.
