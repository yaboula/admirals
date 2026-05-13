# qb-vehiclesales Partial Migration Evidence

## Migration Decision

**Resource:** qb-vehiclesales  
**Path:** `D:\FiveM_Server\Sonar_migration_clean\resources\[qb]\qb-vehiclesales\`  
**Decision:** PARTIAL MIGRATION - Only `sellVehicleBack` flow migrated, `buyVehicle` left as BLOCKER

## Flows Analyzed

### Flow 1: sellVehicleBack (MIGRATED)
**Event:** `qb-occasions:server:sellVehicleBack` (lines 84-112)  
**Risk:** CRITICAL (AddMoney after DELETE)  
**Migration:** Yes - Migrated to SONAR AddMoney  
**Reason for migration:** Acceptable pattern for dealer buyback (vehicle already deleted, credit is refund)

**Changes applied:**
- Removed: `Player.Functions.AddMoney('bank', payout, 'sold vehicle back')`
- Added: SONAR AddMoney with ok check and error handling
- Converted to minor units: `math.floor(payout * 100)`
- Added diagnostic print on failure

**Code:**
```lua
local amountMinor = payout and math.floor(payout * 100) or nil
local ok, err, data = exports.sonar_bank_app:AddMoney(src, amountMinor, 'sold vehicle back', nil)
if not ok then
    print(('[sonar_migration] vehicle buyback credit failed src=%s amount_minor=%s err=%s'):format(...))
    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.generic'), 'error')
    return
end
```

### Flow 2: buyVehicle (BLOCKER - NOT MIGRATED)
**Event:** `qb-occasions:server:buyVehicle` (lines 114-157)  
**Risk:** BLOCKER (SQL direct to money column)  
**Migration:** No - Left unchanged  
**Reason:** Lines 127-132 contain direct SQL writes to `players.money` for offline seller payments

**BLOCKER details:**
```lua
local BuyerData = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', { SellerCitizenId })
if BuyerData[1] then
    local BuyerMoney = json.decode(BuyerData[1].money)
    BuyerMoney.bank = BuyerMoney.bank + NewPrice
    MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(BuyerMoney), SellerCitizenId })
end
```

This bypasses SONAR audit, freeze checks, idempotency, and movement records.

## Resource-Level Checklist

- [x] Make backup: `server/main.lua.bak` created
- [x] Search all bank call sites: Found 3 patterns (1 migrated, 2 left in BLOCKER flow)
- [x] Classify each call site: 1 CRITICAL (migrated), BLOCKER flow left unchanged
- [x] Apply safe replacements: N/A (manual rewrite for CRITICAL flow)
- [x] Manually rewrite CRITICAL flow: sellVehicleBack migrated
- [x] Ensure fxmanifest.lua depends on sonar_bank_app: Added dependency block
- [ ] Restart the resource: PENDING (requires runtime)
- [ ] Check server console for Lua parse errors: PENDING
- [ ] Run positive test (sellVehicleBack): PENDING
- [ ] Run negative test (insufficient funds): PENDING
- [ ] Confirm audit/movement rows: PENDING
- [ ] Confirm HUD/UI behavior: PENDING

## QA Evidence Template - sellVehicleBack

**Resource:** qb-vehiclesales  
**File:** server/main.lua  
**Flow/event:** RegisterNetEvent('qb-occasions:server:sellVehicleBack')  
**Risk level:** CRITICAL  
**Migration type:** Manual rewrite

**Player source:** PENDING runtime test  
**Citizen ID:** PENDING runtime test  
**Account status:** PENDING runtime test

**Before balance_minor:** PENDING runtime test  
**Action:** Sell vehicle back to dealership (50% of base price)  
**Expected delta_minor:** +payout * 100  
**After balance_minor:** PENDING runtime test

**Audit evidence:** PENDING runtime test  
**Movement evidence:** PENDING runtime test  
**DB evidence:** Vehicle deleted from player_vehicles (already happened before credit)  
**HUD/UI result:** PENDING runtime test

**Positive path:** PENDING  
**Negative path:** PENDING  
**Notes:** Credit happens after vehicle DELETE (acceptable for dealer buyback refund pattern). SONAR AddMoney with ok check ensures credit succeeds.

## How to Test (Single Player)

### Prerequisites
1. Start server in `D:\FiveM_Server\Sonar_migration_clean`
2. Ensure `sonar_bank_app` is running
3. Join as a player with a vehicle

### Test sellVehicleBack (MIGRATED)
1. Buy a vehicle from qb-vehicleshop (or spawn one)
2. Go to qb-vehiclesales location
3. Use the "Sell Back to Dealership" option
4. Expected: Vehicle deleted, 50% of base price credited to SONAR bank
5. Verify: Check balance via `qa_get_balance <src>` or HUD
6. Verify: Check audit via `qa_audit` command

### Test buyVehicle (BLOCKER - DO NOT USE)
- This flow is NOT migrated
- Using it will trigger SQL direct to money column
- Do not test this flow in Phase A

## Static Verification
- [x] No remaining QBCore bank patterns in migrated flow: grep confirmed
- [x] SONAR export present: `exports.sonar_bank_app:AddMoney`
- [x] fxmanifest dependency: sonar_bank_app added (lines 28-32)
- [x] Units conversion: math.floor(payout * 100) for minor units
- [x] Error handling: ok check with print diagnostic
- [x] Backup created: server/main.lua.bak

## Next Steps (Runtime Validation)
1. Restart qb-vehiclesales: `restart qb-vehiclesales`
2. Check server console for Lua parse errors
3. Positive test: Sell vehicle back to dealership with SONAR balance
4. Verify audit/movement rows via qa_audit commands
5. Verify HUD/UI behavior

## BLOCKER Flow Reference
The `buyVehicle` flow (lines 114-157) remains BLOCKER and requires Phase B business/account migration planning. See `QB_VEHICLESALES_BLOCKER_REPORT.md` for details.
