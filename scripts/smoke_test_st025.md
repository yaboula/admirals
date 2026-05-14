# ST-025 Smoke Harness — 150ms Callback Lag

## Objective

Validate that a delayed `sonar:bank:transfer:execute` callback response still reaches NUI without timeout, duplicate submit, or UI deadlock.

## Scope

- **Test ID:** ST-025
- **Matrix reference:** `progress/SMOKE_BANK_PHASE_A_v1.md`
- **Injection point:** callback response path for `sonar:bank:transfer:execute`
- **Lag target:** 150ms
- **Expected result:** NUI receives response, transaction UI resolves, no timeout, no duplicate transfer

## Preconditions

- Server is running in dev/test environment only.
- `sonar_bank_app`, `sonar_bank`, `sonar_core`, `sonar_bridges`, and `ox_lib` are started.
- Two test citizens/accounts exist with known IBANs and sufficient balance.
- Browser/NUI dev console is available.
- Server console logs are visible.
- Do not run against production balances.

## Test data template

Replace placeholders before running:

```text
FROM_CITIZEN=<source citizen id>
FROM_IBAN=<source IBAN>
TO_IBAN=<destination IBAN>
AMOUNT_MINOR=100
MEMO=ST-025 callback lag smoke
IDEMPOTENCY_KEY=<uuid-v4>
CORRELATION_ID=<uuid-v4>
```

## Harness procedure

### 1. Establish baseline

- Open Bank app transfer flow.
- Execute a low-value transfer without artificial lag.
- Capture:
  - Server callback log.
  - NUI network/console success.
  - Source and destination balances before/after.
  - Audit/movement IDs if available.

### 2. Inject 150ms callback delay

Use one of these environment-safe methods:

- **Preferred:** temporary local instrumentation around the callback wrapper for `sonar:bank:transfer:execute`, adding `Wait(150)` immediately before returning the callback response.
- **Alternative:** use existing smoke chaos lag tooling if it can target callback response delay without touching SQL mutation order.

Do not inject delay before validation or before the DB transaction. ST-025 validates delayed response delivery, not race behavior inside the money mutation.

### 3. Execute lagged transfer

Run exactly one low-value transfer with a new UUID v4 idempotency key:

```text
sonar:bank:transfer:execute
from_iban=<FROM_IBAN>
to_iban=<TO_IBAN>
amount_minor=<AMOUNT_MINOR>
memo=<MEMO>
idempotency_key=<IDEMPOTENCY_KEY>
correlation_id=<CORRELATION_ID>
```

### 4. Observe UI behavior

Pass criteria:

- Submit button enters loading state.
- UI resolves after the delayed response.
- No timeout toast/error is shown.
- Submit button is not re-enabled early enough to cause duplicate click.
- Receipt/success state appears exactly once.

Fail criteria:

- NUI times out.
- UI remains stuck loading.
- Duplicate receipt appears.
- Duplicate movement appears for one idempotency key.
- Console logs unhandled Promise rejection or callback error.

### 5. Verify backend idempotency and ledger

Check:

- Exactly one movement debit for source account.
- Exactly one movement credit for destination account.
- Exactly one audit/correlation trail for `<CORRELATION_ID>`.
- Idempotency key is committed/cached, not orphaned.

### 6. Replay idempotency key

Submit the same payload again with the same `IDEMPOTENCY_KEY`.

Pass criteria:

- Response is returned from idempotency replay/cache.
- No second debit or credit is written.
- UI resolves without duplicate state.

## Evidence capture

Paste evidence into a progress/session log:

```text
ST-025 RESULT: PASS|FAIL
Date/time:
Branch/commit:
Server profile:
Lag method:
Source account before:
Source account after:
Destination account before:
Destination account after:
Movement IDs:
Audit/correlation ID:
Idempotency key:
NUI console result:
Server console result:
Notes:
```

## Rollback

- Remove temporary `Wait(150)` instrumentation if used.
- Restart affected resource.
- Confirm `git diff --check` and `git status --short` are clean before sign-off.

## Sign-off gate

ST-025 is complete only when live runtime evidence shows:

- Callback delay tolerated.
- No duplicate money movement.
- No UI deadlock.
- Idempotency replay is safe.
