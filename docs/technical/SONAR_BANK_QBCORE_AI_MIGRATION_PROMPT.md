# SONAR Bank QBCore AI Migration Prompt

## Purpose

This document provides a customer-facing AI prompt for migrating QBCore bank-money flows to SONAR Bank using the two-path migration strategy.

The prompt is designed for AI coding assistants inside an IDE.

It forces the assistant to:

- read the Safe Integration guide first
- classify every bank-money pattern before editing
- stop simple migration when a flow belongs to Economy Hardening
- avoid blind automation
- preserve the customer's economy
- generate evidence for every changed flow

## Required Documents

Before using the prompt, place these files in the project or provide them to the AI assistant:

```text
docs/technical/SONAR_BANK_QBCORE_SAFE_INTEGRATION.md
docs/technical/SONAR_BANK_QBCORE_ECONOMY_HARDENING.md
```

Optional historical reference:

```text
docs/technical/SONAR_BANK_QBCORE_MIGRATION_GUIDE.md
```

## Recommended Use

Use this prompt in a fresh AI chat for each resource.

Recommended order:

1. Start with one small resource.
2. Ask the AI to scan and classify only.
3. Review the classification.
4. Allow edits only for `ROUTE 1` and approved `ROUTE 2` flows.
5. Keep `ROUTE 3` flows blocked unless intentionally entering Economy Hardening.
6. Record evidence before moving to another resource.

Do not ask the AI to migrate the whole server in one request.

## Master Prompt

Copy and paste the following prompt into the AI coding assistant.

```text
You are assisting with a SONAR Bank QBCore migration.

Your job is to migrate QBCore bank-money flows safely, following the official SONAR two-path migration strategy.

You must read and follow these documents before changing code:

1. docs/technical/SONAR_BANK_QBCORE_SAFE_INTEGRATION.md
2. docs/technical/SONAR_BANK_QBCORE_ECONOMY_HARDENING.md

If either document is missing, stop and ask me to provide it.

Primary objective:
- Integrate SONAR Bank safely.
- Preserve the customer's economy.
- Do not perform blind automation.
- Do not convert dangerous flows without classification and approval.

Scope for the default migration:
- Use Safe Integration by default.
- Player bank only.
- One resource at a time.
- One flow at a time when possible.

Strict prohibitions:
- Do not edit qb-core.
- Do not migrate cash, crypto, inventory currency, job metadata, society accounts, business accounts, or framework internals under Safe Integration.
- Do not write directly to players.money for bank balances.
- Do not keep QBCore bank balance as the decision gate after migration.
- Do not call both QBCore bank mutation and SONAR bank mutation for the same operation.
- Do not ignore SONAR export return values.
- Do not grant items, vehicles, houses, ownership, or DB side effects before successful SONAR money operation.
- Do not guess business/society account semantics.
- Do not convert a society/business payout into a player payout.
- Do not silently delete legacy payouts.

Mandatory workflow:

Step 1 — Preparation
- Confirm the target resource path.
- Confirm this is a sandbox or backed-up environment.
- Read the Safe Integration guide.
- Read the Economy Hardening guide.
- Inspect the resource files before editing.
- Identify whether fxmanifest.lua needs sonar_bank_app dependency.

Step 2 — Search
Search the target resource for these patterns:
- AddMoney('bank'
- RemoveMoney('bank'
- GetMoney('bank'
- SetMoney('bank'
- PlayerData.money['bank']
- money['bank']
- money.bank
- players.money
- qb-banking
- qb-management

Step 3 — Classification
Before editing, produce a classification table with:
- file
- line/function/event
- original pattern
- route
- risk
- reason
- recommended action

Routes:
- ROUTE 1 — Simple Replacement
- ROUTE 2 — Manual Reorder
- ROUTE 3 — Economy Hardening
- ROUTE 4 — Out Of Scope

Rules:
- ROUTE 1 can be changed after classification.
- ROUTE 2 can be changed only if the side-effect order is clear and can be made safe.
- ROUTE 3 must remain blocked unless I explicitly approve Economy Hardening for that flow.
- ROUTE 4 must not be migrated under Safe Integration.

Step 4 — Safe Integration edits
For ROUTE 1 and approved ROUTE 2:
- Replace QBCore bank mutation with SONAR export.
- Convert major units to minor units with math.floor(tonumber(amount) * 100).
- Capture return values as local ok, err, data.
- Continue only when ok == true.
- Return or fail cleanly when ok is false.
- Keep existing success behavior only after successful SONAR operation.
- Add diagnostic logging only if useful for validation.
- Do not add noisy permanent logs unless requested.

Canonical examples:

Remove bank money:
local amountMinor = math.floor(tonumber(amount) * 100)
local ok, err, data = exports.sonar_bank_app:RemoveMoney(src, amountMinor, reason, nil)
if not ok then
    TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    return
end

Add bank money:
local amountMinor = math.floor(tonumber(amount) * 100)
local ok, err, data = exports.sonar_bank_app:AddMoney(src, amountMinor, reason, nil)
if not ok then
    print(('[sonar_migration] AddMoney failed src=%s amount_minor=%s err=%s'):format(tostring(src), tostring(amountMinor), tostring(err)))
    return
end

Balance display:
local ok, err, data = exports.sonar_bank_app:GetBalance(src)
local bank = ok and data and math.floor((data.balance_minor or 0) / 100) or 0

Step 5 — Economy Hardening boundary
If a flow contains any of these, stop Safe Integration for that flow:
- player-to-player transfer
- offline recipient or seller
- direct SQL update to players.money
- admin SetMoney('bank') or balance correction
- society/job/business payout
- commission split with business account
- marketplace ownership transfer with seller payout
- finance/debt/loan/recurring payment
- escrow-like behavior
- unclear account model
- unclear failure strategy

For these flows:
- Do not edit the flow by default.
- Mark it as ROUTE 3.
- Explain why Safe Integration stops.
- Reference the relevant Economy Hardening section.
- Ask me whether to continue with Economy Hardening.

Step 6 — fxmanifest.lua
If the resource now calls exports.sonar_bank_app, ensure fxmanifest.lua depends on sonar_bank_app.

Valid form:
dependencies {
    'qb-core',
    'sonar_bank_app',
}

If a dependencies block already exists, preserve valid Lua syntax and add a comma to the previous final dependency if needed.

Step 7 — Validation plan
After edits, provide a validation plan with:
- positive path
- insufficient funds path
- frozen account path if possible
- resource restart check
- audit/movement evidence
- DB/ownership evidence if relevant
- HUD/UI observation if relevant

Step 8 — Evidence
Create or update a migration evidence note for the resource with:
- resource
- file
- flow/event
- route
- risk
- before pattern
- after pattern
- SONAR API used
- validation status
- deferred ROUTE 3 or ROUTE 4 items
- rollback notes

Step 9 — Final response
End every migration response with:
- changed files
- migrated flows
- deferred flows
- validation still required
- rollback location or backup reminder

Important behavior:
- If uncertain, stop and ask instead of guessing.
- Prefer smaller edits over large rewrites.
- Preserve existing game behavior unless the guide requires changing order for safety.
- Do not claim success until validation evidence exists.
```

## Scan-Only Prompt

Use this when you want the AI to inspect a resource without changing anything.

```text
Scan this QBCore resource for SONAR Bank migration.

Do not edit files.

Read:
- docs/technical/SONAR_BANK_QBCORE_SAFE_INTEGRATION.md
- docs/technical/SONAR_BANK_QBCORE_ECONOMY_HARDENING.md

Search for QBCore bank-money patterns and produce a classification table:
- file
- line/function/event
- original pattern
- route
- risk
- reason
- recommended action

Classify using:
- ROUTE 1 — Simple Replacement
- ROUTE 2 — Manual Reorder
- ROUTE 3 — Economy Hardening
- ROUTE 4 — Out Of Scope

Do not migrate anything until I approve the classification.
```

## Safe Integration Prompt For One Approved Resource

Use this after reviewing the scan-only output.

```text
Apply Safe Integration only to approved ROUTE 1 and ROUTE 2 flows in this resource.

Do not touch ROUTE 3 or ROUTE 4 flows.

Follow:
- docs/technical/SONAR_BANK_QBCORE_SAFE_INTEGRATION.md
- docs/technical/SONAR_BANK_QBCORE_ECONOMY_HARDENING.md only for boundary checks

Rules:
- Do not edit qb-core.
- Player bank only.
- SONAR money operation must be authoritative.
- Remove legacy QBCore bank gates from migrated flows.
- Check ok from every SONAR export.
- Side effects happen only after ok == true.
- Add sonar_bank_app dependency to fxmanifest.lua if needed.
- Create/update evidence note after changes.

Before editing, list exactly which flows you will change and which flows remain deferred.
```

## Economy Hardening Prompt For One Approved Flow

Use this only when intentionally migrating a `ROUTE 3` flow.

```text
We are intentionally entering Economy Hardening for one approved flow.

Read and follow:
- docs/technical/SONAR_BANK_QBCORE_ECONOMY_HARDENING.md
- docs/technical/SONAR_BANK_QBCORE_SAFE_INTEGRATION.md for boundary context

Do not edit until you answer these questions:
1. Who pays?
2. Who receives?
3. Can the receiver be offline?
4. Does the flow change ownership, inventory, vehicle state, access, or database state?
5. What happens if money succeeds but the side effect fails?
6. What happens if side effect succeeds but notification/mail fails?
7. Which SONAR API should be used?
8. What audit reason will be used?
9. What idempotency/correlation strategy is needed?
10. What evidence proves the migration is safe?

After answering, propose a migration design.

Do not implement until I approve the design.
```

## PM Summary Prompt

Use this when asking the AI to summarize the work for a PM.

```text
Prepare a PM-facing summary of the SONAR Bank QBCore migration plan evolution.

Explain:
- initial goal
- what was tested
- what worked
- what gaps were discovered
- why blind automation became risky
- why the plan changed to two paths
- what Safe Integration covers
- what Economy Hardening covers
- why blockers are escalation boundaries, not failures
- what documents now exist
- what customers should do next

Keep it concise, clear, and non-technical enough for PM review, but include concrete examples such as qb-houses society payout ambiguity and qb-vehiclesales offline seller/direct SQL blocker.
```

## Recommended Customer Instruction

Tell the customer:

```text
Start with the Scan-Only Prompt.
Do not let the AI edit code until it has classified every bank-money pattern in the resource.
Use Safe Integration for simple player-bank flows.
Use Economy Hardening only when the flow needs transfer, offline seller, society/business, admin, SQL money, finance, or escrow design.
```
