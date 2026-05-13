# SONAR Migration Patcher v1.0 — ⛔ DEPRECATED (Phase 5.6.C founder annulment)

> **🚫 ANULADO 2026-05-14 — Founder yaboula directive:** "la automatizacion de migracion con script como python esta totalmente anulado".
>
> **Motivo:** Phase 5.6.C live validation reveló que blind script automation no maneja correctamente flows multi-party / society / offline-seller / ownership-coupled. Doctrina post-pivote: **migration es AI-guided per-resource manual classification**, no script-automated.
>
> **Reemplazo canónico:**
> - `docs/technical/SONAR_BANK_QBCORE_SAFE_INTEGRATION.md` (vía 1 default)
> - `docs/technical/SONAR_BANK_QBCORE_ECONOMY_HARDENING.md` (vía 2 advanced)
> - `docs/technical/SONAR_BANK_QBCORE_AI_MIGRATION_PROMPT.md` (operative tool)
> - `docs/technical/SONAR_BANK_QBCORE_MIGRATION_GUIDE.md` (router/index)
>
> **Status repo:** Este package se preserva como **historical artifact** del Phase 5.6.A research. **NO usar en producción ni client delivery.** No será mantenido. Tests pueden quedar verde como referencia histórica de lo que el approach automated alcanzó (S1+S2+S3+S4 patterns + 70 auto-patched dry-run sandbox) antes del pivote estratégico.
>
> ---

Operator-side migration tool for BANK-BE.PHASE_5.6.A (historical). It rewrites safe QBCore `Player.Functions.AddMoney/RemoveMoney('bank', ...)` call sites in downstream qb-* resources to SONAR Bank exports.

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
