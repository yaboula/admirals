# Patterns

Canonical source: `progress/MIGRATION_PATTERNS.md`.

Phase 5.6.A auto-patches only:

- S1 online `AddMoney/RemoveMoney('bank', ...)`
- S2 online `if RemoveMoney('bank', ...) then`
- S3 offline `GetOfflinePlayer(citizenid)` `AddMoney/RemoveMoney('bank', ...)`

S4 is detected but skipped in Phase A. U1-U9 are reported for manual review and never auto-patched.
