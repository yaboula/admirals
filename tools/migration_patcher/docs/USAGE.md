# Usage

Dry-run against sandbox snapshot:

```powershell
python -m patcher --dry-run --output-dir D:\theBigProject\sandbox_migration_output D:\theBigProject\sandbox_qb_snapshot
```

Filter one resource:

```powershell
python -m patcher --dry-run --filter-resource qb-shops D:\theBigProject\sandbox_qb_snapshot
```

Apply and rollback are sandbox-only in Phase 5.6.A:

```powershell
python -m patcher --apply D:\theBigProject\sandbox_qb_snapshot
python -m patcher --rollback D:\theBigProject\sandbox_qb_snapshot
```
