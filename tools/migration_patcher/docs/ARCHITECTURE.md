# Architecture

The patcher is intentionally conservative:

- `patterns.py` defines S1-S4 and U1-U9 detection metadata.
- `binding_resolver.py` resolves local QBCore player bindings within the current function scope.
- `transformer.py` performs S1/S2/S3 rewrites and emits manual review entries for unresolved or unsafe sites.
- `fxmanifest_injector.py` injects `sonar_bank_app` dependency only for resources with generated patches.
- `safety.py` owns idempotency markers, double-shift guards, and real-server apply guard helpers.
- `report.py` emits markdown and JSON artifacts.
- `cli.py` orchestrates scan, dry-run/apply, filter, output, and rollback.
