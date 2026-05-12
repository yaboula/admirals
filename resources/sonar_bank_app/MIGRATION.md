# SONAR Bank Phase 5 Server-to-Server API Migration

## Replace direct framework money mutations

Use `exports.sonar_bank_app:*` from server-side resources only.

## Tier 1 day-to-day exports

- `AddMoney(source, amount_minor, reason, opts)`
- `RemoveMoney(source, amount_minor, reason, opts)`
- `CanAfford(source, amount_minor)`
- `GetBalance(source)`
- `TransferBySource(from_src, to_src, amount_minor, reason, opts)`
- `TransferByIban(from_iban, to_iban, amount_minor, reason, opts)`
- `AddMoneyByCitizen(citizen_id, amount_minor, reason, opts)`
- `RemoveMoneyByCitizen(citizen_id, amount_minor, reason, opts)`
- `CanAffordByCitizen(citizen_id, amount_minor)`
- `GetBalanceByCitizen(citizen_id)`
- `TransferByCitizen(from_cid, to_cid, amount_minor, reason, opts)`

## Tier 2 admin exports

- `AdminCredit(actor_src, target, amount_minor, reason, opts)`
- `AdminDebit(actor_src, target, amount_minor, reason, opts)`
- `AdminSetBalance(actor_src, target, new_balance_minor, reason, opts)`
- `Freeze(actor_src, target_iban, reason)`
- `Unfreeze(actor_src, target_iban, reason)`
- `AdminCreditByCitizen(actor_src, citizen_id, amount_minor, reason, opts)`
- `AdminDebitByCitizen(actor_src, citizen_id, amount_minor, reason, opts)`
- `AdminSetBalanceByCitizen(actor_src, citizen_id, new_balance_minor, reason, opts)`
- `FreezeByCitizen(actor_src, citizen_id, reason)`
- `UnfreezeByCitizen(actor_src, citizen_id, reason)`

## Required `opts`

For mutations, pass UUID v4 values when possible:

```lua
local ok, err, data = exports.sonar_bank_app:AddMoney(src, 12500, 'shop payout', {
  idempotency_key = '00000000-0000-4000-8000-000000000001',
  correlation_id = '00000000-0000-4000-8000-000000000002',
})
```

## Units

All exports use integer minor units. `12500` means `125.00`.

## Legacy scanner

Run `/sonar_scan_legacy` from server console to scan loaded resource manifests and print resources that likely still mutate framework bank money directly.
