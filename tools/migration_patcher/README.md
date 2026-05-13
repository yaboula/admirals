# SONAR Migration Patcher v1.0

Operator-side migration tool for BANK-BE.PHASE_5.6.A. It rewrites safe QBCore `Player.Functions.AddMoney/RemoveMoney('bank', ...)` call sites in downstream qb-* resources to SONAR Bank exports.

## Boundary

- Phase A supports `--money-types=bank` only.
- `qb-core` is excluded.
- `--apply` and `--rollback` refuse `D:\FiveM_Server\Sonar` paths in Phase 5.6.A.
- No runtime listeners, hooks, shims, or contract changes.

## Usage

```powershell
python -m patcher --dry-run --output-dir D:\theBigProject\sandbox_migration_output D:\theBigProject\sandbox_qb_snapshot
python -m patcher --dry-run --filter-resource qb-vehicleshop D:\theBigProject\sandbox_qb_snapshot
```

Sandbox-only apply/rollback:

```powershell
python -m patcher --apply --output-dir D:\theBigProject\sandbox_migration_output D:\theBigProject\sandbox_qb_snapshot
python -m patcher --rollback --output-dir D:\theBigProject\sandbox_migration_output D:\theBigProject\sandbox_qb_snapshot
```

## Reports

- `auto_patched.md`
- `manual_review.md`
- `summary.json`
- per-resource unified diffs
