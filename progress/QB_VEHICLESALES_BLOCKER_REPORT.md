# qb-vehiclesales BLOCKER Decision

## Resource-Level Analysis

**Resource:** qb-vehiclesales  
**Path:** `D:\FiveM_Server\Sonar_migration_clean\resources\[qb]\qb-vehiclesales\`  
**File:** server/main.lua  
**Decision:** BLOCKER - Do not migrate in Phase A

## BLOCKER Triggers (per SONAR_BANK_QBCORE_MIGRATION_GUIDE.md)

The guide states:

> "Direct SQL write to money/account columns" → BLOCKER → Stop and escalate

> Escalation triggers include: "Script modifies SQL money columns directly"

## Patterns Found

### Flow 1: sellVehicleBack (lines 84-103)
- **Line 98:** `Player.Functions.AddMoney('bank', payout, 'sold vehicle back')`
- **Risk:** CRITICAL (AddMoney after DELETE FROM player_vehicles)
- **Could migrate:** Yes, to SONAR AddMoney

### Flow 2: buyVehicle (lines 105-147) - BLOCKER
- **Line 110:** Pre-gate QBCore `if Player.PlayerData.money.bank >= result[1].price then`
- **Line 114:** `Player.Functions.RemoveMoney('bank', result[1].price, 'bought vehicle used lot')`
- **Line 125:** `SellerData.Functions.AddMoney('bank', NewPrice, 'sold vehicle used lot')` (seller online)
- **Lines 127-132:** SQL direct to money column (seller offline):
  ```lua
  local BuyerData = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', { SellerCitizenId })
  if BuyerData[1] then
      local BuyerMoney = json.decode(BuyerData[1].money)
      BuyerMoney.bank = BuyerMoney.bank + NewPrice
      MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(BuyerMoney), SellerCitizenId })
  end
  ```

## BLOCKER Reason

**Lines 127-132** contain direct SQL writes to the `players.money` column:

```lua
BuyerMoney.bank = BuyerMoney.bank + NewPrice
MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(BuyerMoney), SellerCitizenId })
```

This bypasses:
- SONAR audit trail
- SONAR freeze checks
- SONAR idempotency
- SONAR movement records
- SONAR StateBag publishing

According to the guide, this is a BLOCKER condition that requires escalation.

## Why Not Partial Migration?

While the buyer debit (line 114) and seller online payment (line 125) could be migrated to SONAR, the offline seller payment (lines 127-132) is tightly coupled to the same transaction flow. Partial migration would create:
- Inconsistent audit trail (buyer in SONAR, seller offline in legacy SQL)
- Mixed payment paths that are hard to debug
- Risk of double-payment or missed payments during transition

## Recommended Path Forward

### Option 1: Rewrite Offline Payment Logic (Recommended for Phase B)
1. Replace direct SQL `money` column updates with SONAR `AddMoneyByCitizen` export
2. Use `citizenid` as the identifier for offline player payments
3. Ensure SONAR can handle offline player credits via citizenid
4. Test both online and offline seller paths

### Option 2: Queue-Based Offline Payments (Alternative)
1. Create a pending payments table for offline sellers
2. When seller logs in, process queued payments via SONAR
3. Requires schema change and additional logic

### Option 3: Reject Offline Sales (Quick Fix)
1. Disable vehicle sales when seller is offline
2. Notify buyer: "Seller must be online to complete purchase"
3. Simple but reduces functionality

## Current Status

- **Phase A:** BLOCKED - Do not migrate
- **Evidence:** This report
- **Next:** Escalate to Backend Lead for Phase B business/account migration planning

## Guide Reference

From `SONAR_BANK_QBCORE_MIGRATION_GUIDE.md`:

```
## When To Stop And Escalate

Stop manual migration and escalate when:

- Source player cannot be resolved.
- Resource uses offline citizen IDs and online sources mixed together.
- Script grants items/vehicles before payment.
- Script pays multiple parties in one transaction.
- Script uses `SetMoney('bank')`.
- Script modifies SQL money columns directly.  <-- TRIGGERED
- Script has custom HUD/bank notifications tied to QBCore internals.
- Script mixes player debit with job/society/business payout and no dedicated business-account migration exists.
- You cannot determine whether an amount is major units or minor units.
```
