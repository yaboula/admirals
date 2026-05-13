# Extended Discovery Triage

Source research input: `D:\theBigProject\sandbox_migration_output\descovery_extra.md`.

This document records how the extra custom/escrow/open-source QB server discovery feeds the migration book and patcher roadmap.

## Safe auto-expansion admitted in Phase 5.6.A

The patcher may auto-transform these additional shapes only when the player binding resolves, the money type is literal `bank`, the amount has no minor-unit hint, and the call is not embedded in unsafe control flow:

- Bare 2-argument calls: `Player.Functions.AddMoney('bank', amount)` / `RemoveMoney('bank', amount)`.
- Simple assignment calls: `local ok = Player.Functions.AddMoney('bank', amount)` / `RemoveMoney('bank', amount)`.

For 2-argument calls without a QBCore reason, the patcher emits a stable synthetic reason:

```lua
'sonar-migration:<resource>:<file>:<line>'
```

## Manual-only categories

These discovery categories stay in manual review/book documentation until a later explicit phase decision:

- Raw SQL money mutations (`UPDATE players SET money`, `JSON_SET(money, '$.bank', ...)`).
- Direct memory mutations (`PlayerData.money.bank = ...`).
- Generic account bridge layers (`account`, `accountType`, config-derived money type).
- ESX `addAccountMoney` / `removeAccountMoney` patterns.
- `return Player.Functions.*Money(...)` wrappers.
- Negated or branch-chain control flow (`if not`, `elseif`).
- Function-call amount expressions such as `Round(amount, 0)` or `math.floor(amount + 0.5)` until unit semantics are verified.
- Inactive `_replaced/` and `remplazados/` resources.

## Book impact

The discovery should become a migration-book chapter covering:

- QBCore direct bank calls.
- QBCore framework wrappers.
- Generic account bridges and config resolution.
- SQL/offline money mutation risks.
- Direct memory mutation risks.
- ESX compatibility mapping.
- Inactive resource policy.
